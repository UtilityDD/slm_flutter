-- In-app admin tools. Only the admin Google accounts can call these.
-- Run once in the Supabase SQL editor. The phone never gets a service key.

CREATE OR REPLACE FUNCTION public.admin_list_people()
RETURNS TABLE (
  id uuid,
  email text,
  full_name text,
  role text,
  district text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF lower(COALESCE(auth.jwt() ->> 'email', '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RAISE EXCEPTION 'not admin';
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    u.email::text,
    p.full_name,
    COALESCE(p.role, 'pending'),
    p.district
  FROM auth.users u
  LEFT JOIN public.profiles p ON p.id = u.id
  ORDER BY u.created_at DESC
  LIMIT 200;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_set_role(p_user_id uuid, p_role text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_name text;
BEGIN
  IF lower(COALESCE(auth.jwt() ->> 'email', '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RAISE EXCEPTION 'not admin';
  END IF;

  IF p_role NOT IN ('pending', 'lineman', 'supervisor') THEN
    RAISE EXCEPTION 'bad role';
  END IF;

  UPDATE public.profiles
  SET role = p_role
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    SELECT COALESCE(
      u.raw_user_meta_data ->> 'full_name',
      u.raw_user_meta_data ->> 'name',
      u.email::text
    )
    INTO v_name
    FROM auth.users u
    WHERE u.id = p_user_id;

    INSERT INTO public.profiles (id, role, full_name)
    VALUES (p_user_id, p_role, COALESCE(v_name, 'লাইনম্যান'));
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_people() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_set_role(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_list_people() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_role(uuid, text) TO authenticated;
