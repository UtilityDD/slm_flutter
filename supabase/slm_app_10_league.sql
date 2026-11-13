-- মাসিক লাইনম্যান লিগ (monthly league) + সর্বকালের সেরা (all-time best).
-- Schema slm_app (Android app only). See docs/LEAGUE.md.
--
-- Only level clears count. Per person and per rung the best play is kept:
--   * monthly: per calendar month in Asia/Kolkata, points = stars x 10,
--     minus 5 for each deadly death in that play, never below 0;
--   * all-time: never reset, points = best stars x 10.
-- The hourly quiz, lucky-toolbox coins and guest play never count.
-- Only verified linemen appear: public.profiles verified = true, role not
-- 'pending', not blocked; not hidden in slm_app.league_settings; not an admin
-- account. Anyone, guests too, may read the board.
--
-- RUN ORDER: after slm_app_00_schema.sql; then slm_app_11_league_rungs_seed.sql.
-- Safe to run again. Changes nothing in public: it only reads public.profiles
-- and auth.users inside SECURITY DEFINER functions.
--
-- Board name: slm_app.league_settings.approved_name when an admin set one,
-- otherwise the profile's full_name (the name the admin saw when verifying).
-- The member can hide it ("লাইনম্যান #1234") with set_league_show_name(false).
-- Phones never touch the tables; everything goes through the functions below.

-- 1. Tables ------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS slm_app.league_level_best (
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  month date NOT NULL,
  rung_id text NOT NULL,
  stars int NOT NULL CHECK (stars BETWEEN 0 AND 3),
  points int NOT NULL CHECK (points >= 0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, month, rung_id)
);

CREATE INDEX IF NOT EXISTS league_level_best_month_idx
  ON slm_app.league_level_best (month);

CREATE TABLE IF NOT EXISTS slm_app.league_level_best_all (
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  rung_id text NOT NULL,
  stars int NOT NULL CHECK (stars BETWEEN 0 AND 3),
  points int NOT NULL CHECK (points >= 0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, rung_id)
);

-- Known rung ids (filled by slm_app_11_league_rungs_seed.sql). While it is
-- empty, any id matching the rung pattern is accepted.
CREATE TABLE IF NOT EXISTS slm_app.league_rungs (
  rung_id text PRIMARY KEY
);

-- Per-member league settings (instead of new columns on public.profiles).
--   show_name      the member's own choice (set_league_show_name)
--   hidden         off every board; admin / dashboard only (Play reviewer account)
--   approved_name  board name an admin approved; NULL = use profiles.full_name
-- No row = defaults (name shown, not hidden, full_name).
CREATE TABLE IF NOT EXISTS slm_app.league_settings (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  show_name boolean NOT NULL DEFAULT true,
  hidden boolean NOT NULL DEFAULT false,
  approved_name text CHECK (approved_name IS NULL OR char_length(approved_name) <= 80),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- RLS on and no policies: phones can neither read nor write these tables.
ALTER TABLE slm_app.league_level_best ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.league_level_best_all ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.league_rungs ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.league_settings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE slm_app.league_level_best FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.league_level_best_all FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.league_rungs FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.league_settings FROM PUBLIC, anon, authenticated;

-- 2. Helpers -----------------------------------------------------------------

-- First day of the league month of [p_at] in India time.
CREATE OR REPLACE FUNCTION slm_app.league_month(p_at timestamptz DEFAULT now())
RETURNS date
LANGUAGE sql
STABLE
SET search_path = ''
AS $fn$
  SELECT date_trunc('month', p_at AT TIME ZONE 'Asia/Kolkata')::date
$fn$;

REVOKE ALL ON FUNCTION slm_app.league_month(timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION slm_app.league_month(timestamptz) TO anon, authenticated, service_role;

-- Everyone who may appear on the board, with the name the board shows.
-- Internal (owner rights, read only by the functions below); phones cannot
-- select it. Columns that the web side may or may not have (verified,
-- blocked, slm_id) are read through to_jsonb, with the web side's defaults.
CREATE OR REPLACE VIEW slm_app.league_people AS
SELECT
  p.id AS user_id,
  CASE
    WHEN COALESCE(s.show_name, true)
         AND COALESCE(NULLIF(btrim(COALESCE(s.approved_name, '')), ''), NULLIF(btrim(COALESCE(p.full_name, '')), '')) IS NOT NULL
      THEN COALESCE(NULLIF(btrim(COALESCE(s.approved_name, '')), ''), btrim(p.full_name))
    ELSE 'লাইনম্যান #' || right(
      COALESCE(
        NULLIF(regexp_replace(COALESCE(j.prof ->> 'slm_id', ''), '\s', '', 'g'), ''),
        replace(p.id::text, '-', '')
      ),
      4
    )
  END AS display_name,
  NULLIF(btrim(COALESCE(p.district, '')), '') AS district
FROM public.profiles p
CROSS JOIN LATERAL (SELECT to_jsonb(p) AS prof) j
JOIN auth.users u ON u.id = p.id
LEFT JOIN slm_app.league_settings s ON s.user_id = p.id
WHERE COALESCE((j.prof ->> 'verified')::boolean, true)
  AND COALESCE(p.role, 'pending') NOT IN ('pending', 'guest')
  AND NOT COALESCE((j.prof ->> 'blocked')::boolean, false)
  AND NOT COALESCE(s.hidden, false)
  AND lower(COALESCE(u.email::text, '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com');

REVOKE ALL ON slm_app.league_people FROM PUBLIC, anon, authenticated;

-- 3. Submit one level result ------------------------------------------------

CREATE OR REPLACE FUNCTION slm_app.submit_level_result(
  p_rung_id text,
  p_stars int,
  p_deaths int DEFAULT 0
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_rung text := btrim(COALESCE(p_rung_id, ''));
  v_stars int := LEAST(3, GREATEST(0, COALESCE(p_stars, 0)));
  v_deaths int := LEAST(10, GREATEST(0, COALESCE(p_deaths, 0)));
  v_month date := slm_app.league_month();
  v_points int;
  v_row jsonb;
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

  IF EXISTS (SELECT 1 FROM slm_app.league_rungs)
     AND NOT EXISTS (SELECT 1 FROM slm_app.league_rungs r WHERE r.rung_id = v_rung) THEN
    RETURN json_build_object('success', false, 'reason', 'unknown_rung');
  END IF;

  SELECT to_jsonb(p) INTO v_row FROM public.profiles p WHERE p.id = v_uid;
  IF v_row IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_profile');
  END IF;

  IF COALESCE((v_row ->> 'blocked')::boolean, false) THEN
    RETURN json_build_object('success', false, 'reason', 'blocked');
  END IF;

  SELECT s.hidden INTO v_hidden FROM slm_app.league_settings s WHERE s.user_id = v_uid;
  SELECT lower(u.email::text) INTO v_email FROM auth.users u WHERE u.id = v_uid;
  IF COALESCE(v_hidden, false) OR v_email IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RETURN json_build_object('success', false, 'reason', 'hidden');
  END IF;

  IF NOT slm_app.is_verified(v_uid) THEN
    RETURN json_build_object('success', false, 'reason', 'not_verified');
  END IF;

  IF v_stars = 0 THEN
    RETURN json_build_object('success', false, 'reason', 'not_cleared');
  END IF;

  v_points := GREATEST(0, v_stars * 10 - v_deaths * 5);

  INSERT INTO slm_app.league_level_best AS b (user_id, month, rung_id, stars, points, updated_at)
  VALUES (v_uid, v_month, v_rung, v_stars, v_points, now())
  ON CONFLICT (user_id, month, rung_id) DO UPDATE
    SET stars = EXCLUDED.stars,
        points = EXCLUDED.points,
        updated_at = EXCLUDED.updated_at
    WHERE EXCLUDED.points > b.points
       OR (EXCLUDED.points = b.points AND EXCLUDED.stars > b.stars)
  RETURNING true INTO v_month_saved;

  INSERT INTO slm_app.league_level_best_all AS a (user_id, rung_id, stars, points, updated_at)
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

REVOKE ALL ON FUNCTION slm_app.submit_level_result(text, int, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.submit_level_result(text, int, int) TO authenticated, service_role;

-- 4. Boards (top 100 per scope, plus the caller's own row if lower) ----------

DROP FUNCTION IF EXISTS slm_app.league_board(date, text);

CREATE FUNCTION slm_app.league_board(p_month date DEFAULT NULL, p_district text DEFAULT NULL)
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
SET search_path = slm_app, public
AS $fn$
  WITH totals AS (
    SELECT
      b.user_id,
      lp.display_name,
      lp.district,
      sum(b.points)::int AS pts,
      count(*) FILTER (WHERE b.stars > 0)::int AS cleared,
      max(b.updated_at) AS last_at
    FROM slm_app.league_level_best b
    JOIN slm_app.league_people lp ON lp.user_id = b.user_id
    WHERE b.month = COALESCE(date_trunc('month', p_month)::date, slm_app.league_month())
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

REVOKE ALL ON FUNCTION slm_app.league_board(date, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION slm_app.league_board(date, text) TO anon, authenticated, service_role;

DROP FUNCTION IF EXISTS slm_app.league_board_all(text);

CREATE FUNCTION slm_app.league_board_all(p_district text DEFAULT NULL)
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
SET search_path = slm_app, public
AS $fn$
  WITH totals AS (
    SELECT
      a.user_id,
      lp.display_name,
      lp.district,
      sum(a.points)::int AS pts,
      count(*) FILTER (WHERE a.stars > 0)::int AS cleared,
      max(a.updated_at) AS last_at
    FROM slm_app.league_level_best_all a
    JOIN slm_app.league_people lp ON lp.user_id = a.user_id
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

REVOKE ALL ON FUNCTION slm_app.league_board_all(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION slm_app.league_board_all(text) TO anon, authenticated, service_role;

-- 5. The member's own settings ---------------------------------------------

-- "বোর্ডে আমার নাম দেখান". Any signed-in member may set it (it only matters
-- once they are verified). Returns {success, show_name}.
CREATE OR REPLACE FUNCTION slm_app.set_league_show_name(p_show boolean)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_show boolean := COALESCE(p_show, true);
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'not_signed_in');
  END IF;

  INSERT INTO slm_app.league_settings AS s (user_id, show_name, updated_at)
  VALUES (v_uid, v_show, now())
  ON CONFLICT (user_id) DO UPDATE
    SET show_name = EXCLUDED.show_name,
        updated_at = EXCLUDED.updated_at;

  RETURN json_build_object('success', true, 'show_name', v_show);
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.set_league_show_name(boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.set_league_show_name(boolean) TO authenticated, service_role;

-- The caller's settings: {success, show_name, hidden, verified, board_name}.
-- board_name is the name the board shows while show_name is on.
CREATE OR REPLACE FUNCTION slm_app.my_league_settings()
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_show boolean;
  v_hidden boolean;
  v_approved text;
  v_full text;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'not_signed_in');
  END IF;

  SELECT s.show_name, s.hidden, s.approved_name
  INTO v_show, v_hidden, v_approved
  FROM slm_app.league_settings s
  WHERE s.user_id = v_uid;

  SELECT p.full_name INTO v_full FROM public.profiles p WHERE p.id = v_uid;

  RETURN json_build_object(
    'success', true,
    'show_name', COALESCE(v_show, true),
    'hidden', COALESCE(v_hidden, false),
    'verified', slm_app.is_verified(v_uid),
    'board_name', COALESCE(NULLIF(btrim(COALESCE(v_approved, '')), ''), NULLIF(btrim(COALESCE(v_full, '')), ''))
  );
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.my_league_settings() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.my_league_settings() TO authenticated, service_role;

-- 6. Admin only --------------------------------------------------------------

-- Take a person off every board (true) or put them back (false). For the
-- Play reviewer test account and anyone the owner wants off the board.
CREATE OR REPLACE FUNCTION slm_app.admin_set_league_hidden(p_user_id uuid, p_hidden boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
BEGIN
  IF NOT slm_app.is_admin() THEN
    RAISE EXCEPTION 'not admin';
  END IF;
  IF p_user_id IS NULL OR NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p_user_id) THEN
    RAISE EXCEPTION 'no such user';
  END IF;

  INSERT INTO slm_app.league_settings AS s (user_id, hidden, updated_at)
  VALUES (p_user_id, COALESCE(p_hidden, false), now())
  ON CONFLICT (user_id) DO UPDATE
    SET hidden = EXCLUDED.hidden,
        updated_at = EXCLUDED.updated_at;
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.admin_set_league_hidden(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.admin_set_league_hidden(uuid, boolean) TO authenticated, service_role;

-- Pin the board name. NULL or blank clears it, so the board uses the
-- profile's full_name again.
CREATE OR REPLACE FUNCTION slm_app.admin_set_approved_name(p_user_id uuid, p_name text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_name text := NULLIF(btrim(COALESCE(p_name, '')), '');
BEGIN
  IF NOT slm_app.is_admin() THEN
    RAISE EXCEPTION 'not admin';
  END IF;
  IF p_user_id IS NULL OR NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p_user_id) THEN
    RAISE EXCEPTION 'no such user';
  END IF;
  IF v_name IS NOT NULL AND char_length(v_name) > 80 THEN
    RAISE EXCEPTION 'name too long';
  END IF;

  INSERT INTO slm_app.league_settings AS s (user_id, approved_name, updated_at)
  VALUES (p_user_id, v_name, now())
  ON CONFLICT (user_id) DO UPDATE
    SET approved_name = EXCLUDED.approved_name,
        updated_at = EXCLUDED.updated_at;
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.admin_set_approved_name(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.admin_set_approved_name(uuid, text) TO authenticated, service_role;

-- 7. Monthly winners (computed on read, no cron) ------------------------------

-- Top 3 of every finished month, state-wide and per district. Internal.
CREATE OR REPLACE VIEW slm_app.league_monthly_winners AS
WITH totals AS (
  SELECT
    b.month,
    b.user_id,
    lp.display_name,
    lp.district,
    sum(b.points)::int AS points,
    count(*) FILTER (WHERE b.stars > 0)::int AS rungs,
    max(b.updated_at) AS last_at
  FROM slm_app.league_level_best b
  JOIN slm_app.league_people lp ON lp.user_id = b.user_id
  WHERE b.month < slm_app.league_month()
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

REVOKE ALL ON slm_app.league_monthly_winners FROM PUBLIC, anon, authenticated;

-- The signed-in member's own wins (profile badges), newest first, last 24.
DROP FUNCTION IF EXISTS slm_app.league_my_wins();

CREATE FUNCTION slm_app.league_my_wins()
RETURNS TABLE (
  month date,
  scope text,
  district text,
  place int,
  points int
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
  SELECT w.month, w.scope, w.district, w.place, w.points
  FROM slm_app.league_monthly_winners w
  WHERE auth.uid() IS NOT NULL AND w.user_id = auth.uid()
  ORDER BY w.month DESC, w.scope DESC
  LIMIT 24
$fn$;

REVOKE ALL ON FUNCTION slm_app.league_my_wins() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.league_my_wins() TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
