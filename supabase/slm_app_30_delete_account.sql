-- Account deletion (Google Play "Data deletion" requirement). Schema slm_app.
--
--   slm_app.delete_my_account()      -- the app calls this (signed-in member deletes self)
--   slm_app.delete_user_data(uuid)   -- dashboard only: handles email / web-form requests
--
-- ONE SHARED ACCOUNT: the app and smartlineman.in use the same Supabase
-- account. Deleting it here removes the account for the WEB APP TOO (profile,
-- login, results). The privacy policy and the in-app dialog say so
-- ("একই অ্যাকাউন্ট smartlineman.in ওয়েবসাইটেও মুছে যাবে").
--
-- What it deletes for one user, in this order, in ONE transaction:
--   1. the user's rows in the Android app's own tables (slm_app.league_month,
--      slm_app.league_all (which also holds the cloud progress backup),
--      slm_app.league_winners, slm_app.league_settings; they also cascade from
--      auth.users, deleted here so the counts are visible). The per-rung clear
--      counters (slm_app.league_rung_counts) hold no user id;
--   2. the user's own rows in the website's history tables listed in
--      delete_user_data() (quiz and lesson history, only the ones that exist and
--      have that column). This is the only write into public tables outside the
--      profile, and only of rows that belong to the user being deleted; the
--      public deletion page promises "quiz results" are deleted too. Nothing in
--      public is created, altered or replaced;
--   3. the public.profiles row (id = user);
--   4. the auth.users row. Supabase then removes the user's identities, sessions
--      and refresh tokens itself, and any table with an ON DELETE CASCADE foreign
--      key to auth.users loses that user's rows too.
-- If any step fails (for example a website table still references the user without
-- ON DELETE CASCADE), nothing is deleted and the error goes back to the caller. The
-- app then shows "could not delete, write to us".
--
-- Boards are worked out on every read from league_month / league_all, and the
-- user's league_winners rows go too, so the user disappears from every board
-- and every past winners list at once. No anonymised copy is kept.
--
-- RUN ORDER (Supabase dashboard -> SQL editor). Safe to run again.
--   0. Already run: slm_app_00_schema.sql (needed), slm_app_10_league.sql (optional;
--      missing tables are skipped).
--   1. FIRST run the CHECK query at the bottom of this file (read-only). It lists every
--      table that points at a user. If it shows a table that is not in the lists in
--      delete_user_data() below and whose rule is not CASCADE / SET NULL, add it to
--      the website list before step 2 (ask the web app owner first).
--   2. Run this whole file.
--   3. Test with a throwaway Google account: sign in on a phone, then in the SQL editor
--        SELECT slm_app.delete_user_data((SELECT id FROM auth.users WHERE email = 'throwaway@gmail.com'));
--      and check that the auth user, profile, league rows and cloud save are gone.
--   4. Ship the app build with the "Delete account" button (docs/playstore/account-deletion-app.md).
--
-- Admin accounts (the two emails in AppConfig.adminEmails / slm_app.is_admin()) cannot
-- delete themselves from the phone, so an accidental tap cannot remove an admin.
-- Delete those in the dashboard.

-- 1. Core: delete one user's data (dashboard / service role only) -------------

CREATE OR REPLACE FUNCTION slm_app.delete_user_data(p_uid uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_schema text;
  v_tbl text;
  v_col text;
  v_n int;
  v_counts jsonb := '{}'::jsonb;
BEGIN
  IF p_uid IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_user');
  END IF;

  -- Child tables first. (schema, table, user column). Missing tables and columns are
  -- skipped, so names used only by the website, or not created yet, are harmless here.
  -- Compared as text so a website table that stores the id as text also matches.
  FOR v_schema, v_tbl, v_col IN
    SELECT t.sch, t.tbl, t.col
    FROM (VALUES
      -- the Android app's own tables (slm_app_10_league.sql); league_all
      -- holds the cloud progress backup (save_progress)
      ('slm_app', 'league_month', 'user_id'),
      ('slm_app', 'league_all', 'user_id'),
      ('slm_app', 'league_winners', 'user_id'),
      ('slm_app', 'league_settings', 'user_id'),
      -- the website's quiz and lesson history (submit_quiz_result_v2 etc.):
      -- only this user's rows (names guessed from common use; whichever exist are cleaned)
      ('public', 'quiz_attempts', 'user_id'),
      ('public', 'quiz_results', 'user_id'),
      ('public', 'quiz_submissions', 'user_id'),
      ('public', 'user_quiz_attempts', 'user_id'),
      ('public', 'user_quiz_results', 'user_id'),
      ('public', 'hourly_quiz_attempts', 'user_id'),
      ('public', 'hourly_quiz_results', 'user_id'),
      ('public', 'lesson_progress', 'user_id'),
      ('public', 'user_progress', 'user_id'),
      ('public', 'user_lessons', 'user_id'),
      ('public', 'reading_progress', 'user_id'),
      ('public', 'notifications', 'user_id'),
      ('public', 'feedback', 'user_id'),
      -- found by the CHECK query on the live project (2026-11-14): these point at
      -- auth.users / profiles with NO ACTION, so they must go before the profile
      ('public', 'safety_hero_entries', 'user_id'),
      ('public', 'safety_reports', 'user_id'),
      -- old admin backup copies that still hold the member's rows
      ('public', 'backup_profiles_progress', 'user_id'),
      ('public', 'backup_quiz_attempts', 'user_id'),
      ('public', '_trash_backup_hourly_cheat_20260620', 'user_id'),
      ('public', '_trash_score_repair_backup_attempts', 'user_id'),
      ('public', '_trash_score_repair_backup_profiles', 'user_id')
    ) AS t(sch, tbl, col)
  LOOP
    -- Real tables only (r = table, p = partitioned); a view of the same name is skipped.
    IF to_regclass(format('%I.%I', v_schema, v_tbl)) IS NOT NULL
       AND (SELECT k.relkind FROM pg_class k WHERE k.oid = to_regclass(format('%I.%I', v_schema, v_tbl))) IN ('r', 'p')
       AND EXISTS (
         SELECT 1
         FROM information_schema.columns c
         WHERE c.table_schema = v_schema
           AND c.table_name = v_tbl
           AND c.column_name = v_col
       ) THEN
      EXECUTE format('DELETE FROM %I.%I WHERE %I::text = $1', v_schema, v_tbl, v_col)
        USING p_uid::text;
      GET DIAGNOSTICS v_n = ROW_COUNT;
      v_counts := v_counts || jsonb_build_object(v_schema || '.' || v_tbl, v_n);
    END IF;
  END LOOP;

  IF to_regclass('public.profiles') IS NOT NULL THEN
    DELETE FROM public.profiles WHERE id = p_uid;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    v_counts := v_counts || jsonb_build_object('public.profiles', v_n);
  END IF;

  DELETE FROM auth.users WHERE id = p_uid;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_counts := v_counts || jsonb_build_object('auth.users', v_n);

  RETURN json_build_object('success', true, 'deleted', v_counts);
END;
$fn$;

-- Dashboard-only: never callable from a phone.
REVOKE ALL ON FUNCTION slm_app.delete_user_data(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION slm_app.delete_user_data(uuid) TO service_role;

-- 2. The app's RPC: the signed-in member deletes their own account ------------

CREATE OR REPLACE FUNCTION slm_app.delete_my_account()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
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

  IF v_email IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') OR slm_app.is_admin() THEN
    RETURN json_build_object('success', false, 'reason', 'admin_account');
  END IF;

  RETURN slm_app.delete_user_data(v_uid);
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.delete_my_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.delete_my_account() TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';

-- 3. CHECK query (read-only; run before step 2 of the run order) --------------
-- Lists every foreign key that points at auth.users or public.profiles, with its
-- ON DELETE rule, plus every public / slm_app table that has a user-id column. Any
-- table here that is not in the lists above and whose rule is not CASCADE / SET NULL
-- would make deletion fail: add it to the VALUES list in delete_user_data().
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
--   AND con.connamespace IN ('public'::regnamespace, 'slm_app'::regnamespace)
-- UNION ALL
-- SELECT 'user_id column', c.table_schema || '.' || c.table_name, c.column_name, NULL, NULL
-- FROM information_schema.columns c
-- WHERE c.table_schema IN ('public', 'slm_app') AND c.column_name IN ('user_id', 'profile_id', 'lineman_id')
-- ORDER BY 1, 2;
