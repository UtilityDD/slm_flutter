-- মাসিক লাইনম্যান লিগ (monthly league) + সর্বকালের সেরা (all-time best)
-- + cloud progress backup. Schema slm_app (Android app only). See docs/LEAGUE.md.
--
-- OWNER-APPROVED MODEL (2026-11-14): "two rows per player, replaced on every play".
--   slm_app.league_month  ONE row per player: this month's stars, points, ...
--   slm_app.league_all    ONE row per player: best stars ever + the cloud save.
-- Stars are packed into a text, one character '0'..'3' per rung, at the rung's
-- position slm_app.league_rungs.idx. That registry is APPEND-ONLY: a rung keeps
-- its idx forever, new rungs are only ever added at the end
-- (slm_app_11_league_rungs_seed.sql), so packed stars never move.
--
-- Points = 10 x (sum of stars) - 5 x deaths, never below 0. A play's deaths can
-- only take back what that play added (at most 2 deaths per new star are
-- counted), so a rung never goes below 0 and an improving play never lowers
-- the total. Ties: points desc, then reached_at asc (who got there first), then
-- deaths asc. Monthly boards need at least 3 rungs cleared.
--
-- Months follow India time (Asia/Kolkata). There is no cron: the first submit
-- or board call of a new month runs slm_app.league_rollover() once (advisory
-- lock), which writes last month's top 3 (state + every district) into
-- slm_app.league_winners, stores each player's last-month points and ranks in
-- their own row and resets the month.
--
-- Only verified linemen count and appear: public.profiles verified = true,
-- role not 'pending', not blocked; not hidden in slm_app.league_settings; not an
-- admin account. Anyone, guests too, may read the boards.
--
-- RUN ORDER: after slm_app_00_schema.sql; then slm_app_11_league_rungs_seed.sql.
-- Safe to run again. Changes nothing in public: it only reads public.profiles
-- and auth.users inside SECURITY DEFINER functions. Phones never touch the
-- tables (RLS on, no grants); everything goes through the functions below.

-- 0. Objects of the first draft (never run on the live database) -------------

-- Views first (they may depend on the old functions). league_people is
-- recreated below with a different column list, which CREATE OR REPLACE
-- VIEW cannot do; nothing depends on it (the functions are plpgsql).
DROP VIEW IF EXISTS slm_app.league_monthly_winners;
DROP VIEW IF EXISTS slm_app.league_people;
DROP FUNCTION IF EXISTS slm_app.submit_level_result(text, int, int);
DROP FUNCTION IF EXISTS slm_app.league_board(date, text);
DROP FUNCTION IF EXISTS slm_app.league_board_all(text);
DROP FUNCTION IF EXISTS slm_app.league_my_wins();
DROP FUNCTION IF EXISTS slm_app.my_league_settings();
DROP FUNCTION IF EXISTS slm_app.league_month(timestamptz);
DROP TABLE IF EXISTS slm_app.league_level_best;
DROP TABLE IF EXISTS slm_app.league_level_best_all;

-- 1. Tables ------------------------------------------------------------------

-- The rung registry. APPEND-ONLY: never change idx or rung_id, never delete a
-- row (a trigger refuses it). min_ms is the fastest believable play and may be
-- tuned with UPDATE.
CREATE TABLE IF NOT EXISTS slm_app.league_rungs (
  rung_id text PRIMARY KEY,
  idx int NOT NULL UNIQUE CHECK (idx >= 0),
  min_ms int NOT NULL DEFAULT 0 CHECK (min_ms >= 0),
  added_at timestamptz NOT NULL DEFAULT now()
);

-- A first-draft league_rungs had only rung_id (never run live; kept safe).
ALTER TABLE slm_app.league_rungs ADD COLUMN IF NOT EXISTS idx int;
ALTER TABLE slm_app.league_rungs ADD COLUMN IF NOT EXISTS min_ms int NOT NULL DEFAULT 0;
ALTER TABLE slm_app.league_rungs ADD COLUMN IF NOT EXISTS added_at timestamptz NOT NULL DEFAULT now();

CREATE OR REPLACE FUNCTION slm_app.league_rungs_append_only()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $fn$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'slm_app.league_rungs is append-only: rows are never deleted';
  END IF;
  IF NEW.rung_id IS DISTINCT FROM OLD.rung_id OR NEW.idx IS DISTINCT FROM OLD.idx THEN
    RAISE EXCEPTION 'slm_app.league_rungs is append-only: rung_id and idx never change';
  END IF;
  RETURN NEW;
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.league_rungs_append_only() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS league_rungs_append_only ON slm_app.league_rungs;
CREATE TRIGGER league_rungs_append_only
  BEFORE UPDATE OR DELETE ON slm_app.league_rungs
  FOR EACH ROW EXECUTE FUNCTION slm_app.league_rungs_append_only();

-- West Bengal districts (assets/data/wb_locations.json) with the spellings
-- seen in profiles, so every variant maps to one key.
CREATE TABLE IF NOT EXISTS slm_app.districts (
  key text PRIMARY KEY,
  name_bn text NOT NULL,
  name_en text NOT NULL,
  aliases text[] NOT NULL DEFAULT '{}'
);

-- This month, exactly ONE row per player.
CREATE TABLE IF NOT EXISTS slm_app.league_month (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  month date NOT NULL,
  stars text NOT NULL DEFAULT '' CHECK (stars ~ '^[0-3]*$'),
  points int NOT NULL DEFAULT 0 CHECK (points >= 0),
  rungs_cleared int NOT NULL DEFAULT 0 CHECK (rungs_cleared >= 0),
  deaths int NOT NULL DEFAULT 0 CHECK (deaths >= 0),
  district_key text,
  last_month date,
  last_month_points int,
  last_month_rank_district int,
  last_month_rank_state int,
  plays int NOT NULL DEFAULT 0,
  -- Burst limit window (about 40 clears per hour), inside the row.
  burst_start timestamptz,
  burst_count int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  -- When the current points were first reached (tie-break).
  reached_at timestamptz NOT NULL DEFAULT now()
);

-- All time, exactly ONE row per player. The cloud save lives here and is
-- written only by save_progress().
CREATE TABLE IF NOT EXISTS slm_app.league_all (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  stars text NOT NULL DEFAULT '' CHECK (stars ~ '^[0-3]*$'),
  points int NOT NULL DEFAULT 0 CHECK (points >= 0),
  rungs_cleared int NOT NULL DEFAULT 0 CHECK (rungs_cleared >= 0),
  deaths int NOT NULL DEFAULT 0 CHECK (deaths >= 0),
  district_key text,
  plays int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  reached_at timestamptz NOT NULL DEFAULT now(),
  cloud_save text CHECK (cloud_save IS NULL OR octet_length(cloud_save) <= 16384),
  cloud_save_version int,
  cloud_save_at timestamptz,
  -- ladder position x 10000 + total stars: the more advanced save wins.
  cloud_progress_rank int
);

-- Top 3 of every finished month, state-wide (scope 'state') and per district
-- (scope = district key). Kept 24 months.
CREATE TABLE IF NOT EXISTS slm_app.league_winners (
  month date NOT NULL,
  scope text NOT NULL,
  rank int NOT NULL CHECK (rank BETWEEN 1 AND 3),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name text NOT NULL,
  points int NOT NULL,
  PRIMARY KEY (month, scope, rank)
);

CREATE INDEX IF NOT EXISTS league_winners_user_idx ON slm_app.league_winners (user_id);

-- Clears per rung per month, for the admin's analytics.
CREATE TABLE IF NOT EXISTS slm_app.league_rung_counts (
  month date NOT NULL,
  idx int NOT NULL,
  clears int NOT NULL DEFAULT 0,
  PRIMARY KEY (month, idx)
);

-- Per-member league settings (instead of new columns on public.profiles).
--   show_name      the member's own choice (set_league_show_name)
--   name_asked     the app asked "বোর্ডে আপনার নাম দেখাবেন?" once
--   hidden         off every board; admin / dashboard only (Play reviewer account)
--   approved_name  board name an admin approved; NULL = use profiles.full_name
-- No row = defaults (name shown, not asked, not hidden, full_name).
CREATE TABLE IF NOT EXISTS slm_app.league_settings (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  show_name boolean NOT NULL DEFAULT true,
  name_asked boolean NOT NULL DEFAULT false,
  hidden boolean NOT NULL DEFAULT false,
  approved_name text CHECK (approved_name IS NULL OR char_length(approved_name) <= 80),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE slm_app.league_settings ADD COLUMN IF NOT EXISTS name_asked boolean NOT NULL DEFAULT false;

-- Which month the lazy rollover last finished (one row, id = 1).
CREATE TABLE IF NOT EXISTS slm_app.league_meta (
  id int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  rolled_month date
);

INSERT INTO slm_app.league_meta (id, rolled_month) VALUES (1, NULL) ON CONFLICT (id) DO NOTHING;

-- Board indexes.
CREATE INDEX IF NOT EXISTS league_month_board_idx
  ON slm_app.league_month (month, district_key, points DESC, reached_at);
CREATE INDEX IF NOT EXISTS league_month_state_idx
  ON slm_app.league_month (month, points DESC, reached_at);
CREATE INDEX IF NOT EXISTS league_all_board_idx
  ON slm_app.league_all (district_key, points DESC, reached_at);
CREATE INDEX IF NOT EXISTS league_all_state_idx
  ON slm_app.league_all (points DESC, reached_at);

-- RLS on and no policies: phones can neither read nor write these tables.
ALTER TABLE slm_app.league_rungs ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.league_month ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.league_all ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.league_winners ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.league_rung_counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.league_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE slm_app.league_meta ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE slm_app.league_rungs FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.districts FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.league_month FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.league_all FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.league_winners FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.league_rung_counts FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.league_settings FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE slm_app.league_meta FROM PUBLIC, anon, authenticated;

-- 2. Districts ---------------------------------------------------------------

INSERT INTO slm_app.districts (key, name_bn, name_en, aliases) VALUES
  ('alipurduar', 'আলিপুরদুয়ার', 'Alipurduar', ARRAY['Alipur Duar', 'Alipurduars', 'আলিপুর দুয়ার']),
  ('bankura', 'বাঁকুড়া', 'Bankura', ARRAY['Bankoora', 'বাকুড়া']),
  ('birbhum', 'বীরভূম', 'Birbhum', ARRAY['Birbhoom', 'Beerbhum', 'বীরভুম']),
  ('cooch_behar', 'কোচবিহার', 'Cooch Behar', ARRAY['Coochbehar', 'Cooch Bihar', 'Koch Bihar', 'Kochbihar', 'Coach Behar', 'কুচবিহার']),
  ('dakshin_dinajpur', 'দক্ষিণ দিনাজপুর', 'Dakshin Dinajpur', ARRAY['South Dinajpur', 'D Dinajpur', 'Dinajpur South', 'Dakhin Dinajpur']),
  ('darjeeling', 'দার্জিলিং', 'Darjeeling', ARRAY['Darjiling', 'Darjeling']),
  ('hooghly', 'হুগলি', 'Hooghly', ARRAY['Hugli', 'Hoogly', 'Hooghli', 'Hugly', 'হুগলী']),
  ('howrah', 'হাওড়া', 'Howrah', ARRAY['Haora', 'Howra', 'Hawrah', 'হাওড়া']),
  ('jalpaiguri', 'জলপাইগুড়ি', 'Jalpaiguri', ARRAY['Jalpaigudi', 'জলপাইগুড়ি']),
  ('jhargram', 'ঝাড়গ্রাম', 'Jhargram', ARRAY['Jhargam', 'ঝাড়গ্রাম']),
  ('kalimpong', 'কালিম্পং', 'Kalimpong', ARRAY['Kalimpang']),
  ('kolkata', 'কলকাতা', 'Kolkata', ARRAY['Calcutta', 'Kolkatta', 'Kolkota', 'কোলকাতা']),
  ('malda', 'মালদা', 'Malda', ARRAY['Maldah', 'Maldaha', 'মালদহ']),
  ('murshidabad', 'মুর্শিদাবাদ', 'Murshidabad', ARRAY['Murshidabaad', 'Murshidbad']),
  ('nadia', 'নদিয়া', 'Nadia', ARRAY['Nadiya', 'Nodia', 'নদীয়া', 'নদীয়া']),
  ('north_24_parganas', 'উত্তর 24 পরগনা', 'North 24 Parganas',
    ARRAY['North 24 Pargana', 'North 24 Pgs', 'N 24 Parganas', 'N 24 Pgs', '24 Parganas North', '24 Pgs North',
          '24 Parganas (N)', 'Uttar 24 Parganas', 'Uttar 24 Pargana', 'North Twenty Four Parganas',
          'উত্তর ২৪ পরগনা', 'উত্তর ২৪ পরগণা', 'উত্তর 24 পরগণা']),
  ('paschim_bardhaman', 'পশ্চিম বর্ধমান', 'Paschim Bardhaman',
    ARRAY['West Bardhaman', 'West Burdwan', 'Paschim Burdwan', 'Bardhaman West', 'Burdwan West', 'Paschim Barddhaman']),
  ('paschim_medinipur', 'পশ্চিম মেদিনীপুর', 'Paschim Medinipur',
    ARRAY['West Medinipur', 'West Midnapore', 'Paschim Midnapore', 'Midnapore West', 'Medinipur West', 'Paschim Mednipur']),
  ('purba_bardhaman', 'পূর্ব বর্ধমান', 'Purba Bardhaman',
    ARRAY['East Bardhaman', 'East Burdwan', 'Purba Burdwan', 'Bardhaman East', 'Burdwan East', 'Bardhaman', 'Burdwan',
          'Barddhaman', 'Purba Barddhaman', 'বর্ধমান']),
  ('purba_medinipur', 'পূর্ব মেদিনীপুর', 'Purba Medinipur',
    ARRAY['East Medinipur', 'East Midnapore', 'Purba Midnapore', 'Midnapore East', 'Medinipur East', 'Purba Mednipur']),
  ('purulia', 'পুরুলিয়া', 'Purulia', ARRAY['Puruliya', 'Puruliā', 'পুরুলিয়া']),
  ('south_24_parganas', 'দক্ষিণ 24 পরগনা', 'South 24 Parganas',
    ARRAY['South 24 Pargana', 'South 24 Pgs', 'S 24 Parganas', 'S 24 Pgs', '24 Parganas South', '24 Pgs South',
          '24 Parganas (S)', 'Dakshin 24 Parganas', 'Dakshin 24 Pargana', 'South Twenty Four Parganas',
          'দক্ষিণ ২৪ পরগনা', 'দক্ষিণ ২৪ পরগণা', 'দক্ষিণ 24 পরগণা']),
  ('uttar_dinajpur', 'উত্তর দিনাজপুর', 'Uttar Dinajpur', ARRAY['North Dinajpur', 'U Dinajpur', 'Dinajpur North'])
ON CONFLICT (key) DO UPDATE
  SET name_bn = EXCLUDED.name_bn,
      name_en = EXCLUDED.name_en,
      aliases = EXCLUDED.aliases;

-- 3. Helpers -----------------------------------------------------------------

-- First day of the league month of [p_at] in India time.
CREATE OR REPLACE FUNCTION slm_app.league_month_of(p_at timestamptz DEFAULT now())
RETURNS date
LANGUAGE sql
STABLE
SET search_path = ''
AS $fn$
  SELECT date_trunc('month', p_at AT TIME ZONE 'Asia/Kolkata')::date
$fn$;

REVOKE ALL ON FUNCTION slm_app.league_month_of(timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION slm_app.league_month_of(timestamptz) TO anon, authenticated, service_role;

-- Lower case, no spaces or punctuation, "district" / "জেলা" dropped.
CREATE OR REPLACE FUNCTION slm_app.district_norm(p text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $fn$
  SELECT NULLIF(
    regexp_replace(
      regexp_replace(lower(btrim(COALESCE(p, ''))), '(district|dist\.?|জেলা)', '', 'g'),
      '[[:space:][:punct:]]+', '', 'g'
    ),
    ''
  )
$fn$;

REVOKE ALL ON FUNCTION slm_app.district_norm(text) FROM PUBLIC, anon, authenticated;

-- The district key of a profile's district text. A spelling that matches no
-- district still gets a stable key ('other:' + the normalised text), so
-- people who typed it the same way are on one board. NULL when blank.
CREATE OR REPLACE FUNCTION slm_app.district_key(p_district text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
  SELECT COALESCE(
    (
      SELECT d.key
      FROM slm_app.districts d
      WHERE slm_app.district_norm(p_district) IN (
        SELECT slm_app.district_norm(a)
        FROM unnest(d.aliases || ARRAY[d.key, d.name_en, d.name_bn]) AS a
      )
      ORDER BY d.key
      LIMIT 1
    ),
    'other:' || slm_app.district_norm(p_district)
  )
$fn$;

REVOKE ALL ON FUNCTION slm_app.district_key(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION slm_app.district_key(text) TO service_role;

-- Sum of the packed stars and the number of rungs with at least one star.
CREATE OR REPLACE FUNCTION slm_app.stars_sum(p text)
RETURNS int
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $fn$
  SELECT (length(p) - length(replace(p, '1', '')))
       + 2 * (length(p) - length(replace(p, '2', '')))
       + 3 * (length(p) - length(replace(p, '3', '')))
$fn$;

CREATE OR REPLACE FUNCTION slm_app.stars_cleared(p text)
RETURNS int
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $fn$
  SELECT length(p) - length(replace(p, '0', ''))
$fn$;

REVOKE ALL ON FUNCTION slm_app.stars_sum(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION slm_app.stars_cleared(text) FROM PUBLIC, anon, authenticated;

-- Everyone who may appear on a board, with the name the board shows.
-- Internal (owner rights, read only by the functions below). Columns that the
-- web side may or may not have (verified, blocked, slm_id) are read through
-- to_jsonb, with the web side's defaults.
-- Name: when the member shows it, the admin-approved name, else full_name;
-- otherwise "লাইনম্যান #" and the last 4 of the SLM id (or of the account id).
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
  END AS display_name
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

-- Why [p_uid] may not score (NULL = may score).
CREATE OR REPLACE FUNCTION slm_app.league_refusal(p_uid uuid)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_row jsonb;
  v_hidden boolean;
  v_email text;
BEGIN
  IF p_uid IS NULL THEN
    RETURN 'not_signed_in';
  END IF;
  SELECT to_jsonb(p) INTO v_row FROM public.profiles p WHERE p.id = p_uid;
  IF v_row IS NULL THEN
    RETURN 'no_profile';
  END IF;
  IF COALESCE((v_row ->> 'blocked')::boolean, false) THEN
    RETURN 'blocked';
  END IF;
  SELECT s.hidden INTO v_hidden FROM slm_app.league_settings s WHERE s.user_id = p_uid;
  SELECT lower(u.email::text) INTO v_email FROM auth.users u WHERE u.id = p_uid;
  IF COALESCE(v_hidden, false) OR v_email IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RETURN 'hidden';
  END IF;
  IF NOT slm_app.is_verified(p_uid) THEN
    RETURN 'not_verified';
  END IF;
  RETURN NULL;
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.league_refusal(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION slm_app.league_refusal(uuid) TO service_role;

-- The caller's district key from their profile (NULL when none).
CREATE OR REPLACE FUNCTION slm_app.my_district_key(p_uid uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
  SELECT CASE
    WHEN NULLIF(btrim(COALESCE(p.district, '')), '') IS NULL THEN NULL
    ELSE slm_app.district_key(p.district)
  END
  FROM public.profiles p
  WHERE p.id = p_uid
$fn$;

REVOKE ALL ON FUNCTION slm_app.my_district_key(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION slm_app.my_district_key(uuid) TO service_role;

-- 4. Monthly rollover (lazy, no cron) ----------------------------------------

-- Runs once per new month: the first caller takes an advisory lock, everyone
-- else waits and then finds the work done. Idempotent.
--   1. for every league_month row of an older month: store its points as
--      last_month_points and its district and state rank (eligible people
--      with points > 0 and at least 3 rungs cleared, same order as the board);
--   2. write that month's top 3 (state + each district) into league_winners;
--   3. reset stars, points, rungs_cleared, deaths and plays, month = now;
--   4. drop winners and rung counts older than 24 months.
CREATE OR REPLACE FUNCTION slm_app.league_rollover()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_now date := slm_app.league_month_of();
  v_done date;
  v_m date;
BEGIN
  SELECT m.rolled_month INTO v_done FROM slm_app.league_meta m WHERE m.id = 1;
  IF v_done IS NOT NULL AND v_done >= v_now THEN
    RETURN;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext('slm_app.league_rollover'));

  SELECT m.rolled_month INTO v_done FROM slm_app.league_meta m WHERE m.id = 1 FOR UPDATE;
  IF v_done IS NOT NULL AND v_done >= v_now THEN
    RETURN;
  END IF;

  FOR v_m IN
    SELECT DISTINCT lm.month FROM slm_app.league_month lm WHERE lm.month < v_now ORDER BY 1
  LOOP
    UPDATE slm_app.league_month lm
       SET last_month = v_m,
           last_month_points = lm.points,
           last_month_rank_district = NULL,
           last_month_rank_state = NULL
     WHERE lm.month = v_m;

    WITH ranked AS (
      SELECT
        lm.user_id,
        row_number() OVER (ORDER BY lm.points DESC, lm.reached_at ASC, lm.deaths ASC, lm.user_id) AS rs,
        CASE WHEN lm.district_key IS NULL THEN NULL ELSE
          row_number() OVER (PARTITION BY lm.district_key
                             ORDER BY lm.points DESC, lm.reached_at ASC, lm.deaths ASC, lm.user_id)
        END AS rd
      FROM slm_app.league_month lm
      JOIN slm_app.league_people lp ON lp.user_id = lm.user_id
      WHERE lm.month = v_m AND lm.points > 0 AND lm.rungs_cleared >= 3
    )
    UPDATE slm_app.league_month lm
       SET last_month_rank_state = r.rs,
           last_month_rank_district = r.rd
      FROM ranked r
     WHERE lm.user_id = r.user_id;

    INSERT INTO slm_app.league_winners (month, scope, rank, user_id, display_name, points)
    SELECT v_m, 'state', lm.last_month_rank_state, lm.user_id, lp.display_name, lm.points
    FROM slm_app.league_month lm
    JOIN slm_app.league_people lp ON lp.user_id = lm.user_id
    WHERE lm.month = v_m AND lm.last_month_rank_state BETWEEN 1 AND 3
    UNION ALL
    SELECT v_m, lm.district_key, lm.last_month_rank_district, lm.user_id, lp.display_name, lm.points
    FROM slm_app.league_month lm
    JOIN slm_app.league_people lp ON lp.user_id = lm.user_id
    WHERE lm.month = v_m AND lm.district_key IS NOT NULL AND lm.last_month_rank_district BETWEEN 1 AND 3
    ON CONFLICT (month, scope, rank) DO NOTHING;

    UPDATE slm_app.league_month lm
       SET month = v_now,
           stars = '',
           points = 0,
           rungs_cleared = 0,
           deaths = 0,
           plays = 0,
           reached_at = now(),
           updated_at = now()
     WHERE lm.month = v_m;
  END LOOP;

  DELETE FROM slm_app.league_winners w WHERE w.month < (v_now - interval '24 months')::date;
  DELETE FROM slm_app.league_rung_counts c WHERE c.month < (v_now - interval '24 months')::date;

  UPDATE slm_app.league_meta SET rolled_month = v_now WHERE id = 1;
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.league_rollover() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION slm_app.league_rollover() TO service_role;

-- 5. Submit a batch of level results ------------------------------------------

-- p_items: [{"rung_id": "1.1/do/0", "stars": 3, "deaths": 0, "ms": 41000}, ...]
-- (at most 50 per call). Per item: the rung must be in league_rungs, stars
-- 1..3, ms at least the rung's min_ms, and at most 40 accepted clears per
-- rolling hour. Stars merge with a per-rung max into both rows; points,
-- rungs_cleared are recomputed; reached_at moves only when points go up.
-- Returns {success, accepted, rejected: [{rung_id, reason}], month,
-- month_points, month_rungs, all_points, all_rungs}.
CREATE OR REPLACE FUNCTION slm_app.submit_level_results(p_items jsonb)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_refusal text;
  v_now date;
  v_dkey text;
  v_m slm_app.league_month%ROWTYPE;
  v_a slm_app.league_all%ROWTYPE;
  v_item jsonb;
  v_rung text;
  v_stars int;
  v_deaths int;
  v_ms int;
  v_idx int;
  v_min int;
  v_old int;
  v_ms_stars text;
  v_all_stars text;
  v_m_deaths int;
  v_a_deaths int;
  v_burst_start timestamptz;
  v_burst int;
  v_accepted int := 0;
  v_rejected jsonb := '[]'::jsonb;
  v_m_points int;
  v_a_points int;
BEGIN
  v_refusal := slm_app.league_refusal(v_uid);
  IF v_refusal IS NOT NULL THEN
    RETURN json_build_object('success', false, 'reason', v_refusal);
  END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' THEN
    RETURN json_build_object('success', false, 'reason', 'bad_items');
  END IF;
  IF jsonb_array_length(p_items) > 50 THEN
    RETURN json_build_object('success', false, 'reason', 'too_many_items');
  END IF;

  PERFORM slm_app.league_rollover();
  v_now := slm_app.league_month_of();
  v_dkey := slm_app.my_district_key(v_uid);

  INSERT INTO slm_app.league_month (user_id, month, district_key) VALUES (v_uid, v_now, v_dkey)
  ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO slm_app.league_all (user_id, district_key) VALUES (v_uid, v_dkey)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT * INTO v_m FROM slm_app.league_month WHERE user_id = v_uid FOR UPDATE;
  SELECT * INTO v_a FROM slm_app.league_all WHERE user_id = v_uid FOR UPDATE;

  -- A row the rollover did not see (should not happen): roll it here, no ranks.
  IF v_m.month < v_now THEN
    v_m.last_month := v_m.month;
    v_m.last_month_points := v_m.points;
    v_m.last_month_rank_district := NULL;
    v_m.last_month_rank_state := NULL;
    v_m.month := v_now;
    v_m.stars := '';
    v_m.points := 0;
    v_m.rungs_cleared := 0;
    v_m.deaths := 0;
    v_m.plays := 0;
    v_m.reached_at := now();
  END IF;

  v_burst_start := v_m.burst_start;
  v_burst := v_m.burst_count;
  IF v_burst_start IS NULL OR now() - v_burst_start > interval '1 hour' THEN
    v_burst_start := now();
    v_burst := 0;
  END IF;

  v_ms_stars := v_m.stars;
  v_all_stars := v_a.stars;
  v_m_deaths := v_m.deaths;
  v_a_deaths := v_a.deaths;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    v_rung := btrim(COALESCE(v_item ->> 'rung_id', ''));
    v_stars := CASE WHEN (v_item ->> 'stars') ~ '^[0-9]{1,2}$' THEN (v_item ->> 'stars')::int ELSE 0 END;
    v_deaths := CASE WHEN (v_item ->> 'deaths') ~ '^[0-9]{1,3}$' THEN LEAST(10, (v_item ->> 'deaths')::int) ELSE 0 END;
    v_ms := CASE WHEN (v_item ->> 'ms') ~ '^[0-9]{1,9}$' THEN (v_item ->> 'ms')::int ELSE 0 END;

    SELECT r.idx, r.min_ms INTO v_idx, v_min FROM slm_app.league_rungs r WHERE r.rung_id = v_rung;
    IF NOT FOUND OR v_idx IS NULL THEN
      v_rejected := v_rejected || jsonb_build_object('rung_id', v_rung, 'reason', 'unknown_rung');
      CONTINUE;
    END IF;
    IF v_stars < 1 OR v_stars > 3 THEN
      v_rejected := v_rejected || jsonb_build_object('rung_id', v_rung, 'reason', 'not_cleared');
      CONTINUE;
    END IF;
    IF v_ms < v_min THEN
      v_rejected := v_rejected || jsonb_build_object('rung_id', v_rung, 'reason', 'too_fast');
      CONTINUE;
    END IF;
    IF v_burst >= 40 THEN
      v_rejected := v_rejected || jsonb_build_object('rung_id', v_rung, 'reason', 'too_many');
      CONTINUE;
    END IF;

    v_burst := v_burst + 1;
    v_accepted := v_accepted + 1;

    -- This month.
    IF length(v_ms_stars) <= v_idx THEN
      v_ms_stars := rpad(v_ms_stars, v_idx + 1, '0');
    END IF;
    v_old := substr(v_ms_stars, v_idx + 1, 1)::int;
    IF v_stars > v_old THEN
      v_ms_stars := overlay(v_ms_stars PLACING v_stars::text FROM v_idx + 1 FOR 1);
      v_m_deaths := v_m_deaths + LEAST(v_deaths, 2 * (v_stars - v_old));
    END IF;

    -- All time.
    IF length(v_all_stars) <= v_idx THEN
      v_all_stars := rpad(v_all_stars, v_idx + 1, '0');
    END IF;
    v_old := substr(v_all_stars, v_idx + 1, 1)::int;
    IF v_stars > v_old THEN
      v_all_stars := overlay(v_all_stars PLACING v_stars::text FROM v_idx + 1 FOR 1);
      v_a_deaths := v_a_deaths + LEAST(v_deaths, 2 * (v_stars - v_old));
    END IF;

    INSERT INTO slm_app.league_rung_counts AS c (month, idx, clears) VALUES (v_now, v_idx, 1)
    ON CONFLICT (month, idx) DO UPDATE SET clears = c.clears + 1;
  END LOOP;

  v_m_points := GREATEST(0, 10 * slm_app.stars_sum(v_ms_stars) - 5 * v_m_deaths);
  v_a_points := GREATEST(0, 10 * slm_app.stars_sum(v_all_stars) - 5 * v_a_deaths);

  UPDATE slm_app.league_month
     SET month = v_m.month,
         stars = v_ms_stars,
         points = v_m_points,
         rungs_cleared = slm_app.stars_cleared(v_ms_stars),
         deaths = v_m_deaths,
         district_key = v_dkey,
         last_month = v_m.last_month,
         last_month_points = v_m.last_month_points,
         last_month_rank_district = v_m.last_month_rank_district,
         last_month_rank_state = v_m.last_month_rank_state,
         plays = v_m.plays + v_accepted,
         burst_start = v_burst_start,
         burst_count = v_burst,
         updated_at = now(),
         reached_at = CASE WHEN v_m_points > v_m.points THEN now() ELSE v_m.reached_at END
   WHERE user_id = v_uid;

  UPDATE slm_app.league_all
     SET stars = v_all_stars,
         points = v_a_points,
         rungs_cleared = slm_app.stars_cleared(v_all_stars),
         deaths = v_a_deaths,
         district_key = v_dkey,
         plays = v_a.plays + v_accepted,
         updated_at = now(),
         reached_at = CASE WHEN v_a_points > v_a.points THEN now() ELSE v_a.reached_at END
   WHERE user_id = v_uid;

  RETURN json_build_object(
    'success', true,
    'accepted', v_accepted,
    'rejected', v_rejected,
    'month', v_now,
    'month_points', v_m_points,
    'month_rungs', slm_app.stars_cleared(v_ms_stars),
    'all_points', v_a_points,
    'all_rungs', slm_app.stars_cleared(v_all_stars)
  );
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.submit_level_results(jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.submit_level_results(jsonb) TO authenticated, service_role;

-- 6. Boards (top 50, plus the caller's own row if lower) ----------------------

DROP FUNCTION IF EXISTS slm_app.league_board(text, date);

-- p_scope 'district' (the caller's own district) or 'state'. The current month
-- is ranked live (points > 0, at least 3 rungs cleared); a finished month
-- shows its saved top 3 from league_winners. Order: points desc, reached_at
-- asc, deaths asc. gap_to_next = points to the row above.
CREATE FUNCTION slm_app.league_board(p_scope text DEFAULT 'state', p_month date DEFAULT NULL)
RETURNS TABLE (
  rank int,
  display_name text,
  district text,
  district_bn text,
  points int,
  rungs int,
  deaths int,
  reached_at timestamptz,
  gap_to_next int,
  is_me boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_now date;
  v_month date;
  v_scope text := lower(btrim(COALESCE(p_scope, 'state')));
  v_dkey text;
BEGIN
  PERFORM slm_app.league_rollover();
  v_now := slm_app.league_month_of();
  v_month := COALESCE(date_trunc('month', p_month)::date, v_now);

  IF v_scope = 'district' THEN
    v_dkey := slm_app.my_district_key(v_uid);
    IF v_dkey IS NULL THEN
      RETURN;
    END IF;
  ELSIF v_scope <> 'state' THEN
    RETURN;
  END IF;

  IF v_month <> v_now THEN
    RETURN QUERY
      SELECT w.rank, w.display_name, d.name_en, d.name_bn, w.points, 0, 0, NULL::timestamptz,
             COALESCE(lag(w.points) OVER (ORDER BY w.rank) - w.points, 0)::int,
             COALESCE(w.user_id = v_uid, false)
      FROM slm_app.league_winners w
      LEFT JOIN slm_app.districts d ON d.key = w.scope
      WHERE w.month = v_month AND w.scope = COALESCE(v_dkey, 'state')
      ORDER BY w.rank;
    RETURN;
  END IF;

  RETURN QUERY
    WITH ranked AS (
      SELECT
        lm.user_id,
        lp.display_name AS name,
        lm.district_key,
        lm.points AS pts,
        lm.rungs_cleared AS cleared,
        lm.deaths AS dead,
        lm.reached_at AS reached,
        row_number() OVER w AS rnk,
        COALESCE(lag(lm.points) OVER w - lm.points, 0) AS gap
      FROM slm_app.league_month lm
      JOIN slm_app.league_people lp ON lp.user_id = lm.user_id
      WHERE lm.month = v_now
        AND lm.points > 0
        AND lm.rungs_cleared >= 3
        AND (v_dkey IS NULL OR lm.district_key = v_dkey)
      WINDOW w AS (ORDER BY lm.points DESC, lm.reached_at ASC, lm.deaths ASC, lm.user_id)
    )
    SELECT r.rnk::int, r.name, COALESCE(d.name_en, ''), COALESCE(d.name_bn, ''), r.pts, r.cleared, r.dead,
           r.reached, r.gap::int, COALESCE(r.user_id = v_uid, false)
    FROM ranked r
    LEFT JOIN slm_app.districts d ON d.key = r.district_key
    WHERE r.rnk <= 50 OR r.user_id = v_uid
    ORDER BY r.rnk;
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.league_board(text, date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION slm_app.league_board(text, date) TO anon, authenticated, service_role;

DROP FUNCTION IF EXISTS slm_app.league_board_all(text);

-- The same over league_all (best stars ever, never reset, no minimum rungs).
CREATE FUNCTION slm_app.league_board_all(p_scope text DEFAULT 'state')
RETURNS TABLE (
  rank int,
  display_name text,
  district text,
  district_bn text,
  points int,
  rungs int,
  deaths int,
  reached_at timestamptz,
  gap_to_next int,
  is_me boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_scope text := lower(btrim(COALESCE(p_scope, 'state')));
  v_dkey text;
BEGIN
  IF v_scope = 'district' THEN
    v_dkey := slm_app.my_district_key(v_uid);
    IF v_dkey IS NULL THEN
      RETURN;
    END IF;
  ELSIF v_scope <> 'state' THEN
    RETURN;
  END IF;

  RETURN QUERY
    WITH ranked AS (
      SELECT
        la.user_id,
        lp.display_name AS name,
        la.district_key,
        la.points AS pts,
        la.rungs_cleared AS cleared,
        la.deaths AS dead,
        la.reached_at AS reached,
        row_number() OVER w AS rnk,
        COALESCE(lag(la.points) OVER w - la.points, 0) AS gap
      FROM slm_app.league_all la
      JOIN slm_app.league_people lp ON lp.user_id = la.user_id
      WHERE la.points > 0
        AND (v_dkey IS NULL OR la.district_key = v_dkey)
      WINDOW w AS (ORDER BY la.points DESC, la.reached_at ASC, la.deaths ASC, la.user_id)
    )
    SELECT r.rnk::int, r.name, COALESCE(d.name_en, ''), COALESCE(d.name_bn, ''), r.pts, r.cleared, r.dead,
           r.reached, r.gap::int, COALESCE(r.user_id = v_uid, false)
    FROM ranked r
    LEFT JOIN slm_app.districts d ON d.key = r.district_key
    WHERE r.rnk <= 50 OR r.user_id = v_uid
    ORDER BY r.rnk;
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.league_board_all(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION slm_app.league_board_all(text) TO anon, authenticated, service_role;

-- 7. The member's own league --------------------------------------------------

-- {success, verified, show_name, name_asked, hidden, board_name, district_key,
--  district, district_bn, month, points, rungs_cleared, deaths, plays,
--  last_month, last_month_points, last_month_rank_district,
--  last_month_rank_state, all_points, all_rungs}. Also refreshes the stored
-- district key when the profile's district changed.
CREATE OR REPLACE FUNCTION slm_app.my_league()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_now date;
  v_dkey text;
  v_s slm_app.league_settings%ROWTYPE;
  v_m slm_app.league_month%ROWTYPE;
  v_a slm_app.league_all%ROWTYPE;
  v_full text;
  v_d slm_app.districts%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'not_signed_in');
  END IF;

  PERFORM slm_app.league_rollover();
  v_now := slm_app.league_month_of();
  v_dkey := slm_app.my_district_key(v_uid);

  UPDATE slm_app.league_month SET district_key = v_dkey
   WHERE user_id = v_uid AND district_key IS DISTINCT FROM v_dkey;
  UPDATE slm_app.league_all SET district_key = v_dkey
   WHERE user_id = v_uid AND district_key IS DISTINCT FROM v_dkey;

  SELECT * INTO v_s FROM slm_app.league_settings WHERE user_id = v_uid;
  SELECT * INTO v_m FROM slm_app.league_month WHERE user_id = v_uid;
  SELECT * INTO v_a FROM slm_app.league_all WHERE user_id = v_uid;
  SELECT * INTO v_d FROM slm_app.districts WHERE key = v_dkey;
  SELECT p.full_name INTO v_full FROM public.profiles p WHERE p.id = v_uid;

  RETURN json_build_object(
    'success', true,
    'verified', slm_app.is_verified(v_uid),
    'show_name', COALESCE(v_s.show_name, true),
    'name_asked', COALESCE(v_s.name_asked, false),
    'hidden', COALESCE(v_s.hidden, false),
    'board_name', COALESCE(NULLIF(btrim(COALESCE(v_s.approved_name, '')), ''), NULLIF(btrim(COALESCE(v_full, '')), '')),
    'district_key', v_dkey,
    'district', v_d.name_en,
    'district_bn', v_d.name_bn,
    'month', v_now,
    'points', CASE WHEN v_m.month = v_now THEN v_m.points ELSE 0 END,
    'rungs_cleared', CASE WHEN v_m.month = v_now THEN v_m.rungs_cleared ELSE 0 END,
    'deaths', CASE WHEN v_m.month = v_now THEN v_m.deaths ELSE 0 END,
    'plays', CASE WHEN v_m.month = v_now THEN v_m.plays ELSE 0 END,
    'last_month', v_m.last_month,
    'last_month_points', v_m.last_month_points,
    'last_month_rank_district', v_m.last_month_rank_district,
    'last_month_rank_state', v_m.last_month_rank_state,
    'all_points', COALESCE(v_a.points, 0),
    'all_rungs', COALESCE(v_a.rungs_cleared, 0)
  );
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.my_league() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.my_league() TO authenticated, service_role;

-- "বোর্ডে আমার নাম দেখান". Any signed-in member may set it (it only matters
-- once they are verified). Also marks the one-time question as asked.
-- Returns {success, show_name}.
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

  INSERT INTO slm_app.league_settings AS s (user_id, show_name, name_asked, updated_at)
  VALUES (v_uid, v_show, true, now())
  ON CONFLICT (user_id) DO UPDATE
    SET show_name = EXCLUDED.show_name,
        name_asked = true,
        updated_at = EXCLUDED.updated_at;

  RETURN json_build_object('success', true, 'show_name', v_show);
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.set_league_show_name(boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.set_league_show_name(boolean) TO authenticated, service_role;

DROP FUNCTION IF EXISTS slm_app.my_wins();

-- The signed-in member's monthly top-3 finishes (profile badges), newest
-- first. scope 'state' or 'district' (district = its name).
CREATE FUNCTION slm_app.my_wins()
RETURNS TABLE (
  month date,
  scope text,
  district text,
  district_bn text,
  place int,
  points int
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
  SELECT w.month,
         CASE WHEN w.scope = 'state' THEN 'state' ELSE 'district' END,
         CASE WHEN w.scope = 'state' THEN NULL ELSE COALESCE(d.name_en, w.scope) END,
         CASE WHEN w.scope = 'state' THEN NULL ELSE d.name_bn END,
         w.rank,
         w.points
  FROM slm_app.league_winners w
  LEFT JOIN slm_app.districts d ON d.key = w.scope
  WHERE auth.uid() IS NOT NULL AND w.user_id = auth.uid()
  ORDER BY w.month DESC, (w.scope = 'state') DESC
  LIMIT 48
$fn$;

REVOKE ALL ON FUNCTION slm_app.my_wins() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.my_wins() TO authenticated, service_role;

-- 8. Cloud progress backup ---------------------------------------------------

-- p_blob: the app's gzip + base64 save (at most 16 KB). Written only when
-- p_progress_rank >= the stored rank (the more advanced progress wins).
-- Returns {success, saved, rank} or {success: false, reason, rank}.
CREATE OR REPLACE FUNCTION slm_app.save_progress(p_blob text, p_version int, p_progress_rank int)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_rank int;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'not_signed_in');
  END IF;
  IF p_blob IS NULL OR btrim(p_blob) = '' THEN
    RETURN json_build_object('success', false, 'reason', 'empty');
  END IF;
  IF octet_length(p_blob) > 16384 THEN
    RETURN json_build_object('success', false, 'reason', 'too_big');
  END IF;

  INSERT INTO slm_app.league_all (user_id, district_key) VALUES (v_uid, slm_app.my_district_key(v_uid))
  ON CONFLICT (user_id) DO NOTHING;

  SELECT a.cloud_progress_rank INTO v_rank FROM slm_app.league_all a WHERE a.user_id = v_uid FOR UPDATE;
  IF v_rank IS NOT NULL AND COALESCE(p_progress_rank, 0) < v_rank THEN
    RETURN json_build_object('success', false, 'reason', 'behind', 'rank', v_rank);
  END IF;

  UPDATE slm_app.league_all
     SET cloud_save = p_blob,
         cloud_save_version = COALESCE(p_version, 1),
         cloud_save_at = now(),
         cloud_progress_rank = GREATEST(0, COALESCE(p_progress_rank, 0))
   WHERE user_id = v_uid;

  RETURN json_build_object('success', true, 'saved', true, 'rank', GREATEST(0, COALESCE(p_progress_rank, 0)));
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.save_progress(text, int, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.save_progress(text, int, int) TO authenticated, service_role;

-- {success, blob, version, rank, saved_at}; blob is NULL when nothing is saved.
CREATE OR REPLACE FUNCTION slm_app.load_progress()
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
DECLARE
  v_uid uuid := auth.uid();
  v_a slm_app.league_all%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'not_signed_in');
  END IF;
  SELECT * INTO v_a FROM slm_app.league_all WHERE user_id = v_uid;
  RETURN json_build_object(
    'success', true,
    'blob', v_a.cloud_save,
    'version', v_a.cloud_save_version,
    'rank', v_a.cloud_progress_rank,
    'saved_at', v_a.cloud_save_at
  );
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.load_progress() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.load_progress() TO authenticated, service_role;

-- 9. Admin only --------------------------------------------------------------

-- Take a person off every board (true) or put them back (false).
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

-- Pin the board name. NULL or blank clears it (full_name is used again).
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

DROP FUNCTION IF EXISTS slm_app.admin_rung_counts(date);

-- Clears per rung in [p_month] (default: this month), in ladder order.
CREATE FUNCTION slm_app.admin_rung_counts(p_month date DEFAULT NULL)
RETURNS TABLE (
  idx int,
  rung_id text,
  clears int
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = slm_app, public
AS $fn$
BEGIN
  IF NOT slm_app.is_admin() THEN
    RAISE EXCEPTION 'not admin';
  END IF;
  RETURN QUERY
    SELECT r.idx, r.rung_id, COALESCE(c.clears, 0)
    FROM slm_app.league_rungs r
    LEFT JOIN slm_app.league_rung_counts c
      ON c.idx = r.idx AND c.month = COALESCE(date_trunc('month', p_month)::date, slm_app.league_month_of())
    ORDER BY r.idx;
END;
$fn$;

REVOKE ALL ON FUNCTION slm_app.admin_rung_counts(date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION slm_app.admin_rung_counts(date) TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
