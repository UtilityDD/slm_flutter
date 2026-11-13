-- ############################################################################
-- ##                                                                        ##
-- ##   ON HOLD.  DO NOT RUN THIS FILE.                                       ##
-- ##                                                                        ##
-- ##   It changes the WEB APP's table public.profiles (drops its SELECT /    ##
-- ##   UPDATE policies, adds own-row policies) and creates public objects    ##
-- ##   (public.is_admin, public.profiles_public). The owner's decision of    ##
-- ##   2026-11-13 ("Option B") is that the Android app never modifies       ##
-- ##   anything in public; its own objects live in schema slm_app.           ##
-- ##                                                                        ##
-- ##   Run it ONLY after the web app (repo slm_web) reads other users'       ##
-- ##   profiles through safe functions or views (no direct SELECT of other   ##
-- ##   people's rows in public.profiles), and the web owner agrees.          ##
-- ##   Otherwise the website's people lists, boards and admin pages break.   ##
-- ##                                                                        ##
-- ##   It is also out of date: it reads profiles.league_show_name /          ##
-- ##   league_name / league_hidden, columns from the old league.sql that     ##
-- ##   are never created now (league settings live in                        ##
-- ##   slm_app.league_settings). As written it fails at STEP 3. Rewrite      ##
-- ##   profiles_public against slm_app.league_settings before using it.     ##
-- ##   The app does not read profiles_public any more.                       ##
-- ##                                                                        ##
-- ############################################################################
--
-- profiles privacy: each person can read and change only their own row.
--
-- Why: the privacy policy (docs/playstore/) says phone numbers, email, block
-- and job are not public. Before this file, a SELECT policy on public.profiles
-- could let any signed-in user read every row (AGENTS.md §7).
--
-- After this file:
--   * a signed-in user reads and updates only their own row (id = auth.uid());
--   * an admin (the two emails in AppConfig.adminEmails, checked by
--     public.is_admin()) can also read every row; admin changes still go
--     through the SECURITY DEFINER admin_* functions;
--   * guests (anon) read nothing from profiles;
--   * everything other people may see goes through public.profiles_public
--     (id, board name, district, points, level, photo link only when the
--     member shows their name) or the SECURITY DEFINER league functions.
--     Never phone, email, block, job, role or flags.
--
-- What each app read needs (checked 2026-11-13):
--   auth_provider.dart _fetchProfile    own row, all columns         -> own-row policy
--   profile_edit.dart / lesson_reader / own row update                -> own-row policy
--     auth _markUnverified                (protect_* triggers still guard verified,
--                                          blocked, league_name, league_hidden)
--   leaderboard_provider.dart           id, display_name, district,  -> profiles_public
--     (_shownAmong + fallback board)    points, training_level, avatar_url
--   rank: league_board / league_board_all / submit_level_result / league_my_wins
--                                       SECURITY DEFINER / owner views -> unchanged
--   admin_screen.dart                   admin_people_page / admin_list_people
--                                       (DEFINER) + direct reads of
--                                       id, verified, blocked, full_name, slm_id,
--                                       role, district                -> is_admin() policy
--   delete_my_account / handle_new_user SECURITY DEFINER              -> unchanged
--
-- RUN ORDER (Supabase dashboard -> SQL editor). Safe to run again.
--   0. Already run before: verify_lineman.sql, block_user.sql, league.sql
--      (this file uses the blocked / league_* columns they add).
--   1. FIRST select and run only STEP 0 below (read-only). Save its output:
--      it lists the policies this file will drop, so they can be put back.
--      Check the "views/functions" part too: any website view on profiles with
--      security_invoker=true, or any SECURITY INVOKER function that reads other
--      people's profiles, will see only the caller's row after this file.
--      The website must then read profiles_public instead.
--   2. Run this whole file.
--   3. Run the CHECK AS A USER block at the bottom (separately; it is commented
--      out because it uses BEGIN/ROLLBACK). Expected: own_rows = 1.
--   4. Open the app: Rank board, profile, Settings save, admin people list.

-- STEP 0. Read-only: what is there now -------------------------------------

SELECT 'policy' AS kind, policyname AS name, cmd, roles::text AS roles,
       qual AS using_expr, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles'
UNION ALL
SELECT 'rls', 'profiles', CASE WHEN c.relrowsecurity THEN 'RLS ON' ELSE 'RLS OFF' END,
       CASE WHEN c.relforcerowsecurity THEN 'FORCE' ELSE '' END, NULL, NULL
FROM pg_class c
WHERE c.oid = 'public.profiles'::regclass
UNION ALL
SELECT 'view on profiles', v.oid::regclass::text, NULL,
       COALESCE(array_to_string(v.reloptions, ','), 'security_invoker=false (owner rights)'), NULL, NULL
FROM pg_class v
JOIN pg_depend d ON d.classid = 'pg_rewrite'::regclass
JOIN pg_rewrite r ON r.oid = d.objid AND r.ev_class = v.oid
WHERE v.relkind = 'v' AND d.refobjid = 'public.profiles'::regclass
GROUP BY v.oid, v.reloptions
UNION ALL
SELECT 'invoker function reading profiles', p.oid::regprocedure::text, NULL, NULL, NULL, NULL
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND NOT p.prosecdef AND p.prosrc ILIKE '%profiles%'
ORDER BY 1, 2;

-- STEP 1. Who is an admin ----------------------------------------------------
-- Same emails as AppConfig.adminEmails and every admin_* function.

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $fn$
  SELECT lower(COALESCE(auth.jwt() ->> 'email', '')) IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com')
$fn$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

-- STEP 2. Row level security on profiles -----------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop every policy that can read or update rows (SELECT, UPDATE or ALL),
-- whatever its name, so an old "viewable by everyone" policy cannot survive.
-- INSERT- and DELETE-only policies are left alone.
DO $do$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'profiles' AND cmd IN ('SELECT', 'UPDATE', 'ALL')
  LOOP
    RAISE NOTICE 'dropping policy on profiles: %', r.policyname;
    EXECUTE format('DROP POLICY %I ON public.profiles', r.policyname);
  END LOOP;
END
$do$;

DROP POLICY IF EXISTS profiles_own_select ON public.profiles;
DROP POLICY IF EXISTS profiles_own_update ON public.profiles;
DROP POLICY IF EXISTS profiles_own_insert ON public.profiles;

-- Own row, plus every row for an admin.
CREATE POLICY profiles_own_select ON public.profiles
  FOR SELECT TO authenticated
  USING (id = (SELECT auth.uid()) OR (SELECT public.is_admin()));

-- Own row only. Admins change other rows through the admin_* functions.
CREATE POLICY profiles_own_update ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

-- Own row only (normally the handle_new_user trigger makes it). Kept so a
-- dropped "ALL" policy cannot take away a website sign-up path.
CREATE POLICY profiles_own_insert ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));

-- STEP 3. The public, safe columns ------------------------------------------
-- Runs with the owner's rights on purpose (like league_people), so it can see
-- every row; it returns only these columns and never blocked or hidden people.
-- Board name: the admin-approved league_name when the member shows their
-- name, else "লাইনম্যান #1234" (same rule as league.sql). The Google photo
-- link only when the name is shown. avatar_url is read through to_jsonb so a
-- database without that column still works.

DROP VIEW IF EXISTS public.profiles_public;

CREATE VIEW public.profiles_public WITH (security_barrier = true) AS
SELECT
  p.id,
  CASE
    WHEN COALESCE(p.league_show_name, true) AND btrim(COALESCE(p.league_name, '')) <> ''
      THEN btrim(p.league_name)
    ELSE 'লাইনম্যান #' || right(
      COALESCE(
        NULLIF(regexp_replace(COALESCE(p.slm_id, ''), '\s', '', 'g'), ''),
        replace(p.id::text, '-', '')
      ),
      4
    )
  END AS display_name,
  NULLIF(btrim(COALESCE(p.district, '')), '') AS district,
  COALESCE(p.points, 0)::int AS points,
  COALESCE(p.training_level, 1)::int AS training_level,
  CASE WHEN COALESCE(p.league_show_name, true) THEN to_jsonb(p) ->> 'avatar_url' END AS avatar_url
FROM public.profiles p
WHERE COALESCE(p.blocked, false) = false
  AND COALESCE(p.league_hidden, false) = false;

REVOKE ALL ON public.profiles_public FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.profiles_public TO anon, authenticated;

-- STEP 4. Result: the policies now on profiles (read-only) -----------------

SELECT policyname, cmd, roles::text AS roles, qual AS using_expr, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles'
ORDER BY policyname;

-- CHECK AS A USER (run separately, after the file; changes nothing) ---------
-- Pretends to be one ordinary member and counts what they can read.
-- Expected: own_rows = 1, other_phones = 0, public_rows = number of shown people.
--
-- BEGIN;
-- SELECT set_config('request.jwt.claims', json_build_object(
--          'sub', p.id::text, 'role', 'authenticated', 'email', 'nobody@example.com')::text, true)
-- FROM public.profiles p
-- WHERE lower(COALESCE(p.email, '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com')
-- LIMIT 1;
-- SET LOCAL ROLE authenticated;
-- SELECT
--   (SELECT count(*) FROM public.profiles) AS own_rows,
--   (SELECT count(*) FROM public.profiles WHERE id <> auth.uid()) AS other_phones,
--   (SELECT count(*) FROM public.profiles_public) AS public_rows;
-- ROLLBACK;
