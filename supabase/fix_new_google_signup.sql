-- Same signup profile write the website already uses.
-- Runs only when a brand-new row is inserted into auth.users.
-- Does not read or update any existing user, profile, points, or session.
-- Run once in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name, points, training_level, total_penalties)
  VALUES (
    NEW.id,
    NEW.email,
    'lineman',
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    0,
    1,
    0
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    role = COALESCE(profiles.role, EXCLUDED.role);
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
