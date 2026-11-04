-- One page of the admin people list, searched and filtered on the server.
-- Replaces the phone's old pattern: admin_list_people (newest 200 only) plus a
-- second query that downloaded id/verified/blocked for EVERY profile, then
-- searched on the phone. Run once in the Supabase SQL editor. Until it is run
-- the app falls back to admin_list_people.
--
-- p_query  : matches name, email, SLM id or district (case-insensitive)
-- p_filter : all | pending | verified | unverified | blocked
-- p_offset / p_limit : paging; p_limit is clamped to 1..100
-- Every row also carries the counts for the whole (searched) set, so the
-- phone's chips show real totals without another query.

CREATE OR REPLACE FUNCTION public.admin_people_page(
  p_query text DEFAULT '',
  p_filter text DEFAULT 'all',
  p_offset integer DEFAULT 0,
  p_limit integer DEFAULT 50
)
RETURNS TABLE (
  id uuid,
  email text,
  full_name text,
  slm_id text,
  role text,
  district text,
  verified boolean,
  blocked boolean,
  n_all bigint,
  n_pending bigint,
  n_verified bigint,
  n_unverified bigint,
  n_blocked bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_q text := '%' || replace(replace(replace(lower(trim(COALESCE(p_query, ''))), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  v_all boolean := trim(COALESCE(p_query, '')) = '';
BEGIN
  IF lower(COALESCE(auth.jwt() ->> 'email', '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RAISE EXCEPTION 'not admin';
  END IF;

  RETURN QUERY
  WITH base AS (
    SELECT
      u.id,
      u.email::text AS email,
      p.full_name,
      p.slm_id::text AS slm_id,
      COALESCE(NULLIF(trim(p.role), ''), 'pending') AS role,
      p.district,
      COALESCE(p.verified, false) AS verified,
      COALESCE(p.blocked, false) AS blocked,
      u.created_at
    FROM auth.users u
    LEFT JOIN public.profiles p ON p.id = u.id
    WHERE v_all
       OR lower(COALESCE(p.full_name, '')) LIKE v_q
       OR lower(COALESCE(u.email::text, '')) LIKE v_q
       OR lower(COALESCE(p.slm_id::text, '')) LIKE v_q
       OR lower(COALESCE(p.district, '')) LIKE v_q
  ),
  counted AS (
    SELECT
      b.*,
      count(*) OVER () AS n_all,
      count(*) FILTER (WHERE b.role = 'pending') OVER () AS n_pending,
      count(*) FILTER (WHERE b.verified) OVER () AS n_verified,
      count(*) FILTER (WHERE NOT b.verified) OVER () AS n_unverified,
      count(*) FILTER (WHERE b.blocked) OVER () AS n_blocked
    FROM base b
  )
  SELECT c.id, c.email, c.full_name, c.slm_id, c.role, c.district, c.verified, c.blocked,
         c.n_all, c.n_pending, c.n_verified, c.n_unverified, c.n_blocked
  FROM counted c
  WHERE CASE COALESCE(p_filter, 'all')
          WHEN 'pending' THEN c.role = 'pending'
          WHEN 'verified' THEN c.verified
          WHEN 'unverified' THEN NOT c.verified
          WHEN 'blocked' THEN c.blocked
          ELSE true
        END
  ORDER BY c.created_at DESC, c.id
  OFFSET GREATEST(COALESCE(p_offset, 0), 0)
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_people_page(text, text, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_people_page(text, text, integer, integer) TO authenticated;
