-- Lets an admin block or unblock a member. A blocked account is signed out
-- and cannot sign back in. Admin accounts cannot be blocked.
-- Run once in the Supabase SQL editor.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS blocked boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.protect_blocked()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.blocked IS DISTINCT FROM OLD.blocked
     AND lower(COALESCE(auth.jwt() ->> 'email', '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    NEW.blocked := OLD.blocked;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_protect_blocked ON public.profiles;
CREATE TRIGGER profiles_protect_blocked
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_blocked();

DROP FUNCTION IF EXISTS public.admin_list_people();

CREATE OR REPLACE FUNCTION public.admin_list_people()
RETURNS TABLE (
  id uuid,
  email text,
  full_name text,
  role text,
  district text,
  blocked boolean
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
    p.district,
    COALESCE(p.blocked, false)
  FROM auth.users u
  LEFT JOIN public.profiles p ON p.id = u.id
  ORDER BY u.created_at DESC
  LIMIT 200;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_set_blocked(p_user_id uuid, p_blocked boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email text;
BEGIN
  IF lower(COALESCE(auth.jwt() ->> 'email', '')) NOT IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RAISE EXCEPTION 'not admin';
  END IF;

  SELECT lower(u.email::text) INTO v_email FROM auth.users u WHERE u.id = p_user_id;
  IF v_email IN ('dipnkr.das@gmail.com', 'roumak.das@gmail.com') THEN
    RAISE EXCEPTION 'cannot block admin';
  END IF;

  UPDATE public.profiles
  SET blocked = p_blocked
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'no profile';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_people() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_set_blocked(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_list_people() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_blocked(uuid, boolean) TO authenticated;
