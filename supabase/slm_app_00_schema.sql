-- slm_app: the Android app's own schema (owner decision "Option B", 2026-11-13).
--
-- The Supabase project is shared with the live web app (smartlineman.in).
-- Every database object the Android app needs lives in the schema slm_app.
-- The web app's tables, functions, triggers and policies in public are NEVER
-- changed by these files: no new columns, triggers, policies or replaced
-- functions on public objects. The app only READS shared data (auth.users via
-- auth.uid(), public.profiles, public.hourly_questions), and only inside
-- SECURITY DEFINER functions here, so it does not depend on public RLS.
-- The one write into shared data is account deletion (slm_app_30): the
-- caller's own rows, then their profile and auth user.
--
-- RUN ORDER (Supabase dashboard -> SQL editor). Every file is safe to run again.
--   slm_app_00_schema.sql            this file: schema, grants, helpers
--   slm_app_10_league.sql            league tables and functions
--   slm_app_11_league_rungs_seed.sql known rung ids (run again when levels ship)
--   slm_app_20_toolbox_quiz.sql      lucky toolbox quiz (reads hourly_questions)
--   slm_app_30_delete_account.sql    delete my account (run its CHECK query first)
--
-- THEN, ONCE, IN THE DASHBOARD (the app cannot reach slm_app without it):
--   Supabase Dashboard -> Project Settings -> API (Data API) -> Exposed schemas:
--   add  slm_app  next to public (keep public and graphql_public), Save.
-- Without this every app call answers "The schema must be one of the following"
-- and the app shows its offline state.
--
-- Never put a service-role key in the app. Phones call only the functions that
-- these files GRANT to anon / authenticated.

CREATE SCHEMA IF NOT EXISTS slm_app;

-- The API roles may look up names in the schema; what they may run is granted
-- function by function in the later files.
GRANT USAGE ON SCHEMA slm_app TO anon, authenticated, service_role;

-- Default privileges for objects created later in slm_app (by the role running
-- these files, normally postgres): tables, views and sequences are closed to
-- phones; the dashboard's service_role keeps full access.
-- Note: PostgreSQL also gives EXECUTE on every new function to PUBLIC through
-- a global default that a per-schema rule cannot take away, so every function
-- in these files is followed by its own REVOKE ... FROM PUBLIC.
ALTER DEFAULT PRIVILEGES IN SCHEMA slm_app REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA slm_app REVOKE ALL ON SEQUENCES FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA slm_app REVOKE ALL ON FUNCTIONS FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA slm_app GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA slm_app GRANT ALL ON SEQUENCES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA slm_app GRANT EXECUTE ON FUNCTIONS TO service_role;

-- Helpers ------------------------------------------------------------------

-- The admin accounts. Same rule as every public.admin_* function and
-- AppConfig.adminEmails: the signed-in Google email.
CREATE OR REPLACE FUNCTION slm_app.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $fn$
  SELECT lower(COALESCE(auth.jwt() ->> 'email', '')) IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com')
$fn$;

REVOKE ALL ON FUNCTION slm_app.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION slm_app.is_admin() TO anon, authenticated, service_role;

-- Is [p_uid] a verified lineman: profile row exists, verified = true, role not
-- 'pending' (nor 'guest'), not blocked. Read-only on public.profiles.
-- The columns are read through to_jsonb so the function still works on a
-- database where verify_lineman.sql / block_user.sql (web side) never added
-- verified / blocked; the defaults are theirs (verified true, blocked false).
-- Internal: phones use me_verified().
CREATE OR REPLACE FUNCTION slm_app.is_verified(p_uid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
  SELECT COALESCE((
    SELECT COALESCE((to_jsonb(p) ->> 'verified')::boolean, true)
       AND COALESCE(p.role, 'pending') NOT IN ('pending', 'guest')
       AND NOT COALESCE((to_jsonb(p) ->> 'blocked')::boolean, false)
    FROM public.profiles p
    WHERE p.id = p_uid
  ), false)
$fn$;

REVOKE ALL ON FUNCTION slm_app.is_verified(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION slm_app.is_verified(uuid) TO service_role;

-- The caller is a verified lineman (false for guests and signed-out calls).
CREATE OR REPLACE FUNCTION slm_app.me_verified()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
  SELECT auth.uid() IS NOT NULL AND slm_app.is_verified(auth.uid())
$fn$;

REVOKE ALL ON FUNCTION slm_app.me_verified() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION slm_app.me_verified() TO anon, authenticated, service_role;

-- Tell the Data API (PostgREST) to pick up the new schema and functions.
NOTIFY pgrst, 'reload schema';
