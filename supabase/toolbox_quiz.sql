-- Lucky toolbox quiz ("ভাগ্যের টুলবক্স", Flutter app only). Safe to run again.
--
-- The phone asks for one random question from the hourly bank WITHOUT its
-- answer, shows it inside a toolbox chest, then sends the chosen option text
-- back for a check. Nothing is awarded here: no hourly points, no profile or
-- quiz_attempts write (the chest's prize is local to the game).
--
-- Source table: public.hourly_questions (slm_web/quiz_management/
-- create_hourly_questions_table.sql; the same table tool/export_hourly_pack.mjs
-- reads): id uuid, question_text, options jsonb, correct_answer_index, language.
-- Only Bangla text questions are served. Picture questions from the visual
-- sheet are not in this table; for their ids the check falls back to
-- public.flutter_hourly_answer_keys (supabase/submit_flutter_hourly_quiz.sql),
-- if that table exists.
--
-- ⚠ Note for the owner: hourly_questions has a public SELECT policy
-- ("Enable read access for all users"), so correct_answer_index is already
-- readable by anyone with the anon key. These functions do not make that
-- worse, but toolbox_quiz_check() returns the right option for any id, so a
-- player could look up an answer of the current hourly quiz through it.
-- If that matters, tighten hourly_questions' SELECT policy (the web app reads
-- it) and/or limit toolbox_quiz_check() to ids recently served.

CREATE OR REPLACE FUNCTION public.toolbox_quiz_question()
RETURNS json
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row record;
  v_opts jsonb;
BEGIN
  -- A few tries: skip rows whose options are not a usable list.
  FOR v_row IN
    SELECT q.id, q.question_text, q.options
    FROM public.hourly_questions q
    WHERE q.language = 'bn'
      AND btrim(COALESCE(q.question_text, '')) <> ''
    ORDER BY random()
    LIMIT 5
  LOOP
    v_opts := v_row.options;
    IF jsonb_typeof(v_opts) = 'string' THEN
      BEGIN
        v_opts := (v_row.options #>> '{}')::jsonb;
      EXCEPTION WHEN others THEN
        v_opts := NULL;
      END;
    END IF;
    IF v_opts IS NOT NULL AND jsonb_typeof(v_opts) = 'array' AND jsonb_array_length(v_opts) >= 2 THEN
      RETURN json_build_object(
        'id', v_row.id::text,
        'text', v_row.question_text,
        'options', v_opts
      );
    END IF;
  END LOOP;
  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.toolbox_quiz_check(p_question_id text, p_choice text)
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id text := btrim(COALESCE(p_question_id, ''));
  v_choice text := btrim(COALESCE(p_choice, ''));
  v_opts jsonb;
  v_index int;
  v_right text;
BEGIN
  IF v_id = '' THEN
    RETURN json_build_object('correct', NULL, 'correct_choice', NULL, 'error', 'bad_id');
  END IF;

  IF v_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    SELECT q.options, q.correct_answer_index INTO v_opts, v_index
    FROM public.hourly_questions q
    WHERE q.id = v_id::uuid;
    IF FOUND THEN
      IF jsonb_typeof(v_opts) = 'string' THEN
        BEGIN
          v_opts := (v_opts #>> '{}')::jsonb;
        EXCEPTION WHEN others THEN
          v_opts := NULL;
        END;
      END IF;
      IF v_opts IS NOT NULL AND jsonb_typeof(v_opts) = 'array' THEN
        v_right := btrim(v_opts ->> v_index);
      END IF;
    END IF;
  END IF;

  -- Picture questions (visual sheet ids) live only in the Flutter answer keys.
  IF v_right IS NULL AND to_regclass('public.flutter_hourly_answer_keys') IS NOT NULL THEN
    EXECUTE 'SELECT btrim(correct_choice) FROM public.flutter_hourly_answer_keys WHERE question_id = $1'
      INTO v_right
      USING v_id;
  END IF;

  IF v_right IS NULL OR v_right = '' THEN
    RETURN json_build_object('correct', NULL, 'correct_choice', NULL, 'error', 'not_found');
  END IF;

  RETURN json_build_object(
    'correct', v_choice <> '' AND v_choice = v_right,
    'correct_choice', v_right
  );
END;
$$;

REVOKE ALL ON FUNCTION public.toolbox_quiz_question() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.toolbox_quiz_check(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.toolbox_quiz_question() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.toolbox_quiz_check(text, text) TO anon, authenticated, service_role;
