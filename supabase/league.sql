-- মাসিক লাইনম্যান লিগ (monthly league) + সর্বকালের সেরা (all-time best).
--
-- Only level clears count. Per person and per rung the best play is kept:
--   * monthly: per calendar month in Asia/Kolkata, points = stars x 10,
--     minus 5 for each deadly death in that play, never below 0;
--   * all-time: never reset, points = best stars x 10.
-- The hourly quiz, lucky-toolbox coins and guest play never count.
-- Only verified linemen appear (verified, not 'pending', not blocked, not
-- league_hidden, not an admin account). Anyone, guests too, may read the board.
--
-- Run once in the Supabase SQL editor, AFTER verify_lineman.sql and
-- block_user.sql. Safe to run again. Then run league_rungs_seed.sql.
-- Does not change points, roles, lessons or anything the website uses.

-- 1. Profile columns -------------------------------------------------------

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS verified boolean NOT NULL DEFAULT true;
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS blocked boolean NOT NULL DEFAULT false;

-- The Play reviewer test account and any other account the owner wants off
-- the board. Only an admin (or the dashboard) can change it.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS league_hidden boolean NOT NULL DEFAULT false;

-- The member's own choice: show the name on the board, or "লাইনম্যান #1234".
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS league_show_name boolean NOT NULL DEFAULT true;

-- The name the admin approved. Copied from full_name when the admin verifies
-- the person; a later name edit by the member does not reach the board until
-- the admin approves it again. Only an admin (or the dashboard) can change it.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS league_name text;

CREATE OR REPLACE FUNCTION public.protect_league_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
DECLARE
  -- The dashboard, service jobs and SECURITY DEFINER admin functions run as
  -- postgres/service_role; phones run as anon/authenticated.
  v_trusted boolean := current_user NOT IN ('anon', 'authenticated')
    OR lower(COALESCE(auth.jwt() ->> 'email', '')) IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com');
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NOT v_trusted THEN
      NEW.league_name := NULL;
      NEW.league_hidden := false;
    END IF;
    RETURN NEW;
  END IF;

  IF NOT v_trusted THEN
    NEW.league_name := OLD.league_name;
    NEW.league_hidden := OLD.league_hidden;
    RETURN NEW;
  END IF;

  -- Just approved (verified on and out of 'pending'): the name the admin saw
  -- becomes the board name, unless the admin set league_name in this update.
  IF NEW.league_name IS NOT DISTINCT FROM OLD.league_name
     AND NEW.verified = true
     AND COALESCE(NEW.role, 'pending') NOT IN ('pending', 'guest')
     AND NOT (OLD.verified = true AND COALESCE(OLD.role, 'pending') NOT IN ('pending', 'guest')) THEN
    NEW.league_name := NULLIF(btrim(COALESCE(NEW.full_name, '')), '');
  END IF;
  RETURN NEW;
END;
$fn$;

-- "zz" so it runs after profiles_protect_verified / profiles_protect_blocked
-- (BEFORE triggers fire in name order) and sees their final values.
DROP TRIGGER IF EXISTS profiles_zz_protect_league ON public.profiles;
CREATE TRIGGER profiles_zz_protect_league
BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_league_fields();

-- People already verified before the league: their current name counts as
-- approved. Only fills empty league_name, so running again changes nothing.
UPDATE public.profiles
SET league_name = btrim(full_name)
WHERE league_name IS NULL
  AND verified = true
  AND COALESCE(role, 'pending') NOT IN ('pending', 'guest')
  AND btrim(COALESCE(full_name, '')) <> '';

-- 2. Tables ------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.league_level_best (
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  month date NOT NULL,
  rung_id text NOT NULL,
  stars int NOT NULL CHECK (stars BETWEEN 0 AND 3),
  points int NOT NULL CHECK (points >= 0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, month, rung_id)
);

CREATE INDEX IF NOT EXISTS league_level_best_month_idx
  ON public.league_level_best (month);

CREATE TABLE IF NOT EXISTS public.league_level_best_all (
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  rung_id text NOT NULL,
  stars int NOT NULL CHECK (stars BETWEEN 0 AND 3),
  points int NOT NULL CHECK (points >= 0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, rung_id)
);

-- Known rung ids (filled by league_rungs_seed.sql). While it is empty, any id
-- matching the rung pattern is accepted.
CREATE TABLE IF NOT EXISTS public.league_rungs (
  rung_id text PRIMARY KEY
);

-- No direct reads or writes from phones: only the functions below.
ALTER TABLE public.league_level_best ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.league_level_best_all ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.league_rungs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.league_level_best FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.league_level_best_all FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.league_rungs FROM PUBLIC, anon, authenticated;

-- 3. Helpers -----------------------------------------------------------------

-- First day of the league month of [p_at] in India time.
CREATE OR REPLACE FUNCTION public.league_month(p_at timestamptz DEFAULT now())
RETURNS date
LANGUAGE sql
STABLE
AS $fn$
  SELECT date_trunc('month', p_at AT TIME ZONE 'Asia/Kolkata')::date
$fn$;

-- Everyone who may appear on the board, with the name the board shows.
-- Internal: phones cannot read it.
CREATE OR REPLACE VIEW public.league_people AS
SELECT
  p.id AS user_id,
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
  NULLIF(btrim(COALESCE(p.district, '')), '') AS district
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
WHERE p.verified = true
  AND COALESCE(p.role, 'pending') NOT IN ('pending', 'guest')
  AND COALESCE(p.blocked, false) = false
  AND COALESCE(p.league_hidden, false) = false
  AND lower(COALESCE(u.email::text, '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com');

REVOKE ALL ON public.league_people FROM PUBLIC, anon, authenticated;

-- 4. Submit one level result ------------------------------------------------

CREATE OR REPLACE FUNCTION public.submit_level_result(
  p_rung_id text,
  p_stars int,
  p_deaths int DEFAULT 0
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_rung text := btrim(COALESCE(p_rung_id, ''));
  v_stars int := LEAST(3, GREATEST(0, COALESCE(p_stars, 0)));
  v_deaths int := LEAST(10, GREATEST(0, COALESCE(p_deaths, 0)));
  v_month date := public.league_month();
  v_points int;
  v_verified boolean;
  v_role text;
  v_blocked boolean;
  v_hidden boolean;
  v_email text;
  v_month_saved boolean;
  v_all_saved boolean;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'not_signed_in');
  END IF;

  IF v_rung !~ '^[0-9]+\.[0-9]+/(learn|do/[0-9])$|^m[0-9]+/gate$' THEN
    RETURN json_build_object('success', false, 'reason', 'bad_rung');
  END IF;

  IF EXISTS (SELECT 1 FROM public.league_rungs)
     AND NOT EXISTS (SELECT 1 FROM public.league_rungs r WHERE r.rung_id = v_rung) THEN
    RETURN json_build_object('success', false, 'reason', 'unknown_rung');
  END IF;

  SELECT p.verified, p.role, p.blocked, p.league_hidden
  INTO v_verified, v_role, v_blocked, v_hidden
  FROM public.profiles p
  WHERE p.id = v_uid;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'reason', 'no_profile');
  END IF;

  IF COALESCE(v_blocked, false) THEN
    RETURN json_build_object('success', false, 'reason', 'blocked');
  END IF;

  SELECT lower(u.email::text) INTO v_email FROM auth.users u WHERE u.id = v_uid;
  IF COALESCE(v_hidden, false) OR v_email IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RETURN json_build_object('success', false, 'reason', 'hidden');
  END IF;

  IF v_verified IS DISTINCT FROM true OR COALESCE(v_role, 'pending') IN ('pending', 'guest') THEN
    RETURN json_build_object('success', false, 'reason', 'not_verified');
  END IF;

  IF v_stars = 0 THEN
    RETURN json_build_object('success', false, 'reason', 'not_cleared');
  END IF;

  v_points := GREATEST(0, v_stars * 10 - v_deaths * 5);

  INSERT INTO public.league_level_best AS b (user_id, month, rung_id, stars, points, updated_at)
  VALUES (v_uid, v_month, v_rung, v_stars, v_points, now())
  ON CONFLICT (user_id, month, rung_id) DO UPDATE
    SET stars = EXCLUDED.stars,
        points = EXCLUDED.points,
        updated_at = EXCLUDED.updated_at
    WHERE EXCLUDED.points > b.points
       OR (EXCLUDED.points = b.points AND EXCLUDED.stars > b.stars)
  RETURNING true INTO v_month_saved;

  INSERT INTO public.league_level_best_all AS a (user_id, rung_id, stars, points, updated_at)
  VALUES (v_uid, v_rung, v_stars, v_stars * 10, now())
  ON CONFLICT (user_id, rung_id) DO UPDATE
    SET stars = EXCLUDED.stars,
        points = EXCLUDED.points,
        updated_at = EXCLUDED.updated_at
    WHERE EXCLUDED.stars > a.stars
  RETURNING true INTO v_all_saved;

  RETURN json_build_object(
    'success', true,
    'month', v_month,
    'points', v_points,
    'month_best', COALESCE(v_month_saved, false),
    'all_time_best', COALESCE(v_all_saved, false)
  );
END;
$fn$;

REVOKE ALL ON FUNCTION public.submit_level_result(text, int, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_level_result(text, int, int) TO authenticated;

-- 5. Boards (top 100 per scope, plus the caller's own row if lower) ----------

DROP FUNCTION IF EXISTS public.league_board(date, text);

CREATE FUNCTION public.league_board(p_month date DEFAULT NULL, p_district text DEFAULT NULL)
RETURNS TABLE (
  rank int,
  display_name text,
  district text,
  points int,
  rungs int,
  gap_to_next int,
  is_me boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $fn$
  WITH totals AS (
    SELECT
      b.user_id,
      lp.display_name,
      lp.district,
      sum(b.points)::int AS pts,
      count(*) FILTER (WHERE b.stars > 0)::int AS cleared,
      max(b.updated_at) AS last_at
    FROM public.league_level_best b
    JOIN public.league_people lp ON lp.user_id = b.user_id
    WHERE b.month = COALESCE(date_trunc('month', p_month)::date, public.league_month())
      AND (NULLIF(btrim(COALESCE(p_district, '')), '') IS NULL OR lp.district = btrim(p_district))
    GROUP BY b.user_id, lp.display_name, lp.district
    HAVING sum(b.points) > 0
  ),
  ranked AS (
    SELECT
      t.*,
      row_number() OVER w AS rnk,
      COALESCE(lag(t.pts) OVER w - t.pts, 0) AS gap
    FROM totals t
    WINDOW w AS (ORDER BY t.pts DESC, t.cleared DESC, t.last_at ASC, t.user_id)
  )
  SELECT
    r.rnk::int,
    r.display_name,
    r.district,
    r.pts,
    r.cleared,
    r.gap::int,
    COALESCE(r.user_id = auth.uid(), false)
  FROM ranked r
  WHERE r.rnk <= 100 OR r.user_id = auth.uid()
  ORDER BY r.rnk
$fn$;

REVOKE ALL ON FUNCTION public.league_board(date, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.league_board(date, text) TO anon, authenticated;

DROP FUNCTION IF EXISTS public.league_board_all(text);

CREATE FUNCTION public.league_board_all(p_district text DEFAULT NULL)
RETURNS TABLE (
  rank int,
  display_name text,
  district text,
  points int,
  rungs int,
  gap_to_next int,
  is_me boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $fn$
  WITH totals AS (
    SELECT
      a.user_id,
      lp.display_name,
      lp.district,
      sum(a.points)::int AS pts,
      count(*) FILTER (WHERE a.stars > 0)::int AS cleared,
      max(a.updated_at) AS last_at
    FROM public.league_level_best_all a
    JOIN public.league_people lp ON lp.user_id = a.user_id
    WHERE NULLIF(btrim(COALESCE(p_district, '')), '') IS NULL OR lp.district = btrim(p_district)
    GROUP BY a.user_id, lp.display_name, lp.district
    HAVING sum(a.points) > 0
  ),
  ranked AS (
    SELECT
      t.*,
      row_number() OVER w AS rnk,
      COALESCE(lag(t.pts) OVER w - t.pts, 0) AS gap
    FROM totals t
    WINDOW w AS (ORDER BY t.pts DESC, t.cleared DESC, t.last_at ASC, t.user_id)
  )
  SELECT
    r.rnk::int,
    r.display_name,
    r.district,
    r.pts,
    r.cleared,
    r.gap::int,
    COALESCE(r.user_id = auth.uid(), false)
  FROM ranked r
  WHERE r.rnk <= 100 OR r.user_id = auth.uid()
  ORDER BY r.rnk
$fn$;

REVOKE ALL ON FUNCTION public.league_board_all(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.league_board_all(text) TO anon, authenticated;

-- 6. Monthly winners (computed on read, no cron) ------------------------------

-- Top 3 of every finished month, state-wide and per district. Internal.
CREATE OR REPLACE VIEW public.league_monthly_winners AS
WITH totals AS (
  SELECT
    b.month,
    b.user_id,
    lp.display_name,
    lp.district,
    sum(b.points)::int AS points,
    count(*) FILTER (WHERE b.stars > 0)::int AS rungs,
    max(b.updated_at) AS last_at
  FROM public.league_level_best b
  JOIN public.league_people lp ON lp.user_id = b.user_id
  WHERE b.month < public.league_month()
  GROUP BY b.month, b.user_id, lp.display_name, lp.district
  HAVING sum(b.points) > 0
),
placed AS (
  SELECT
    t.month, 'state'::text AS scope, t.district, t.user_id, t.display_name, t.points,
    row_number() OVER (PARTITION BY t.month ORDER BY t.points DESC, t.rungs DESC, t.last_at ASC, t.user_id) AS place
  FROM totals t
  UNION ALL
  SELECT
    t.month, 'district'::text AS scope, t.district, t.user_id, t.display_name, t.points,
    row_number() OVER (PARTITION BY t.month, t.district ORDER BY t.points DESC, t.rungs DESC, t.last_at ASC, t.user_id) AS place
  FROM totals t
  WHERE t.district IS NOT NULL
)
SELECT month, scope, district, place::int AS place, user_id, display_name, points
FROM placed
WHERE place <= 3;

REVOKE ALL ON public.league_monthly_winners FROM PUBLIC, anon, authenticated;

-- The signed-in member's own wins (read by the app for the profile badges).
-- Runs with the owner's rights on purpose and returns only auth.uid()'s rows.
CREATE OR REPLACE VIEW public.league_my_wins AS
SELECT w.month, w.scope, w.district, w.place, w.points
FROM public.league_monthly_winners w
WHERE w.user_id = auth.uid();

REVOKE ALL ON public.league_my_wins FROM PUBLIC, anon;
GRANT SELECT ON public.league_my_wins TO authenticated;
