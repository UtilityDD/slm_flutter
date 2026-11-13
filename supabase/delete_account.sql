-- Account deletion (Google Play "Data deletion" requirement).
--
--   public.delete_my_account()      -- the app calls this (signed-in member deletes self)
--   public.delete_user_data(uuid)   -- dashboard only: handles email / web-form requests
--
-- What it deletes for one user, in this order:
--   1. rows keyed by user_id in the app tables listed below (only the ones that exist,
--      and only if they have that column; every table is checked with to_regclass first);
--   2. the public.profiles row (id = user);
--   3. the auth.users row. Supabase then removes the user's identities, sessions and
--      refresh tokens itself, and any table with an ON DELETE CASCADE foreign key to
--      auth.users (league_level_best, league_level_best_all) loses that user's rows too.
-- Everything runs in one transaction: if any step fails (for example a website table
-- still references the user without ON DELETE CASCADE), nothing is deleted and the
-- error goes back to the caller. The app then shows "could not delete, write to us".
--
-- League boards and monthly winners are worked out on every read (league.sql), so the
-- user disappears from every board at once. No anonymised copy is kept.
--
-- RUN ORDER (Supabase dashboard -> SQL editor). Safe to run again.
--   0. Already run before: verify_lineman.sql, block_user.sql, league.sql,
--      league_rungs_seed.sql (this file works without them too).
--   1. FIRST run the CHECK query at the bottom of this file (read-only). It lists every
--      table that points at a user. If it shows a table that is not in the list in
--      delete_user_data() below, add it to that list before step 2.
--   2. Run this whole file.
--   3. Test with a throwaway Google account: sign in on a phone, then in the SQL editor
--        SELECT public.delete_user_data((SELECT id FROM auth.users WHERE email = 'throwaway@gmail.com'));
--      and check that the auth user, profile and league rows are gone.
--   4. Ship the app build with the "Delete account" button (docs/playstore/account-deletion-app.md).
--
-- Admin accounts (the two emails in AppConfig.adminEmails) cannot delete themselves from
-- the phone, so an accidental tap cannot remove an admin. Delete those in the dashboard.

-- 1. Core: delete one user's data (dashboard / service role only) -------------

CREATE OR REPLACE FUNCTION public.delete_user_data(p_uid uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_tbl text;
  v_col text;
  v_n int;
  v_counts jsonb := '{}'::jsonb;
BEGIN
  IF p_uid IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_user');
  END IF;

  -- Child tables first. (table, user column). Missing tables and columns are skipped,
  -- so names used only by the website, or not created yet, are harmless here.
  -- Compared as text so a website table that stores the id as text also matches.
  FOR v_tbl, v_col IN
    SELECT t.tbl, t.col
    FROM (VALUES
      -- league.sql (also cascade from auth.users; deleted here so the count is visible)
      ('league_level_best', 'user_id'),
      ('league_level_best_all', 'user_id'),
      -- quiz and lesson history written by the website / submit_quiz_result_v2
      -- (names guessed from common use; whichever exist are cleaned)
      ('quiz_attempts', 'user_id'),
      ('quiz_results', 'user_id'),
      ('quiz_submissions', 'user_id'),
      ('user_quiz_attempts', 'user_id'),
      ('user_quiz_results', 'user_id'),
      ('hourly_quiz_attempts', 'user_id'),
      ('hourly_quiz_results', 'user_id'),
      ('lesson_progress', 'user_id'),
      ('user_progress', 'user_id'),
      ('user_lessons', 'user_id'),
      ('reading_progress', 'user_id'),
      ('notifications', 'user_id'),
      ('feedback', 'user_id')
    ) AS t(tbl, col)
  LOOP
    -- Real tables only (r = table, p = partitioned); a view of the same name is skipped.
    IF to_regclass(format('public.%I', v_tbl)) IS NOT NULL
       AND (SELECT k.relkind FROM pg_class k WHERE k.oid = to_regclass(format('public.%I', v_tbl))) IN ('r', 'p')
       AND EXISTS (
         SELECT 1
         FROM information_schema.columns c
         WHERE c.table_schema = 'public'
           AND c.table_name = v_tbl
           AND c.column_name = v_col
       ) THEN
      EXECUTE format('DELETE FROM public.%I WHERE %I::text = $1', v_tbl, v_col)
        USING p_uid::text;
      GET DIAGNOSTICS v_n = ROW_COUNT;
      v_counts := v_counts || jsonb_build_object(v_tbl, v_n);
    END IF;
  END LOOP;

  IF to_regclass('public.profiles') IS NOT NULL THEN
    DELETE FROM public.profiles WHERE id = p_uid;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    v_counts := v_counts || jsonb_build_object('profiles', v_n);
  END IF;

  DELETE FROM auth.users WHERE id = p_uid;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_counts := v_counts || jsonb_build_object('auth_users', v_n);

  RETURN json_build_object('success', true, 'deleted', v_counts);
END;
$fn$;

-- Supabase grants EXECUTE on new public functions to anon and authenticated by default.
-- This one must stay dashboard-only.
REVOKE ALL ON FUNCTION public.delete_user_data(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_data(uuid) TO service_role;

-- 2. The app's RPC: the signed-in member deletes their own account ------------

CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_email text;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'not_signed_in');
  END IF;

  SELECT lower(u.email::text) INTO v_email FROM auth.users u WHERE u.id = v_uid;
  IF NOT FOUND THEN
    -- Already gone (a second tap, or a retry after a lost reply): treat as done.
    RETURN json_build_object('success', true, 'deleted', '{}'::json);
  END IF;

  IF v_email IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RETURN json_build_object('success', false, 'reason', 'admin_account');
  END IF;

  RETURN public.delete_user_data(v_uid);
END;
$fn$;

REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;

-- 3. CHECK query (read-only; run before step 2 of the run order) --------------
-- Lists every foreign key that points at auth.users or public.profiles, with its
-- ON DELETE rule, plus every public table that has a user_id column. Any table here
-- that is not in the list above and whose rule is not CASCADE / SET NULL would make
-- deletion fail: add it to the VALUES list in delete_user_data().
--
-- SELECT 'fk' AS kind,
--        con.conrelid::regclass::text AS table_name,
--        a.attname AS column_name,
--        con.confrelid::regclass::text AS points_to,
--        CASE con.confdeltype WHEN 'c' THEN 'CASCADE' WHEN 'n' THEN 'SET NULL'
--             WHEN 'd' THEN 'SET DEFAULT' WHEN 'r' THEN 'RESTRICT' ELSE 'NO ACTION' END AS on_delete
-- FROM pg_constraint con
-- JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = ANY (con.conkey)
-- WHERE con.contype = 'f'
--   AND con.confrelid IN ('auth.users'::regclass, 'public.profiles'::regclass)
--   AND con.connamespace = 'public'::regnamespace
-- UNION ALL
-- SELECT 'user_id column', c.table_name, c.column_name, NULL, NULL
-- FROM information_schema.columns c
-- WHERE c.table_schema = 'public' AND c.column_name IN ('user_id', 'profile_id', 'lineman_id')
-- ORDER BY 1, 2;
