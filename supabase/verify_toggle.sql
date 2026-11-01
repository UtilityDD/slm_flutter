-- Admin can verify or unverify one person at a time.
-- Does not update existing rows, points, lessons, or web play.
-- A role change no longer writes the verified tick.
-- Run once in the Supabase SQL editor.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS verified boolean NOT NULL DEFAULT true;

CREATE OR REPLACE FUNCTION public.admin_set_verified(p_user_id uuid, p_verified boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF lower(COALESCE(auth.jwt() ->> 'email', '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RAISE EXCEPTION 'not admin';
  END IF;

  UPDATE public.profiles
  SET verified = p_verified
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'no profile';
  END IF;
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

REVOKE ALL ON FUNCTION public.admin_set_verified(uuid, boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_set_role(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_set_verified(uuid, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_role(uuid, text) TO authenticated;
