-- Lets the phone mark a brand-new Google signup as unverified, and lets the
-- admin turn that tick gold. Existing rows stay verified (default true).
-- Run once in the Supabase SQL editor. Does not change emails, points, or roles
-- of people already in the table.

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
  v_verified boolean;
BEGIN
  IF lower(COALESCE(auth.jwt() ->> 'email', '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RAISE EXCEPTION 'not admin';
  END IF;

  IF p_role NOT IN ('pending', 'lineman', 'supervisor') THEN
    RAISE EXCEPTION 'bad role';
  END IF;

  v_verified := p_role <> 'pending';

  UPDATE public.profiles
  SET role = p_role,
      verified = v_verified
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

    INSERT INTO public.profiles (id, role, full_name, verified)
    VALUES (p_user_id, p_role, COALESCE(v_name, 'লাইনম্যান'), v_verified);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_verified()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.verified IS DISTINCT FROM OLD.verified
     AND NEW.verified = true
     AND lower(COALESCE(auth.jwt() ->> 'email', '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    NEW.verified := OLD.verified;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_protect_verified ON public.profiles;
CREATE TRIGGER profiles_protect_verified
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_verified();

REVOKE ALL ON FUNCTION public.admin_set_verified(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_set_verified(uuid, boolean) TO authenticated;
