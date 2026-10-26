-- Flutter-only hourly scoring.
-- Does not replace submit_quiz_result_v2. The web app never calls this.
-- The phone sends question ids and the chosen option text. This function
-- compares them with flutter_hourly_answer_keys, then writes points through
-- the existing submit function (same hour window, one play, same points row).

CREATE TABLE IF NOT EXISTS public.flutter_hourly_answer_keys (
  question_id text PRIMARY KEY,
  correct_choice text NOT NULL
);

ALTER TABLE public.flutter_hourly_answer_keys ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.flutter_hourly_answer_keys FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.submit_flutter_hourly_quiz(
  p_quiz_id text,
  p_answers jsonb,
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := COALESCE(p_user_id, auth.uid());
  v_item jsonb;
  v_id text;
  v_choice text;
  v_key text;
  v_seen text[] := ARRAY[]::text[];
  v_correct int := 0;
  v_wrong int := 0;
  v_count int := 0;
  v_points int;
  v_tier int;
  v_per_wrong int;
  v_penalty int;
  v_score int;
  v_result json;
BEGIN
  IF auth.uid() IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  IF p_quiz_id IS NULL OR p_quiz_id !~ '^hourly-challenge-\d{4}-\d{2}-\d{2}-\d{2}$' THEN
    RETURN json_build_object('success', false, 'error', 'hourly_time_mismatch');
  END IF;

  IF p_answers IS NULL OR jsonb_typeof(p_answers) <> 'array' OR jsonb_array_length(p_answers) <> 5 THEN
    RETURN json_build_object('success', false, 'error', 'bad_answers');
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_answers)
  LOOP
    v_id := btrim(COALESCE(v_item->>'id', ''));
    v_choice := btrim(COALESCE(v_item->>'choice', ''));
    IF v_id = '' OR v_id = ANY (v_seen) THEN
      RETURN json_build_object('success', false, 'error', 'bad_answers');
    END IF;
    v_seen := array_append(v_seen, v_id);

    SELECT correct_choice INTO v_key
    FROM public.flutter_hourly_answer_keys
    WHERE question_id = v_id;

    IF NOT FOUND THEN
      RETURN json_build_object('success', false, 'error', 'answer_key_missing');
    END IF;

    v_count := v_count + 1;
    IF v_choice <> '' AND v_choice = btrim(v_key) THEN
      v_correct := v_correct + 1;
    ELSE
      v_wrong := v_wrong + 1;
    END IF;
  END LOOP;

  IF v_count <> 5 THEN
    RETURN json_build_object('success', false, 'error', 'bad_answers');
  END IF;

  SELECT COALESCE(points, 0) INTO v_points
  FROM public.profiles
  WHERE id = v_user_id;

  v_tier := CASE
    WHEN COALESCE(v_points, 0) < 10000 THEN 0
    WHEN COALESCE(v_points, 0) < 30000 THEN 1
    WHEN COALESCE(v_points, 0) < 50000 THEN 2
    ELSE 3
  END;
  v_per_wrong := (ARRAY[0, 6, 8, 10])[v_tier + 1];
  v_penalty := LEAST(50, v_wrong * v_per_wrong);
  v_score := LEAST(50, v_correct * 10);

  v_result := public.submit_quiz_result_v2(p_quiz_id, v_score, v_penalty, v_user_id);
  IF COALESCE((v_result->>'success')::boolean, false) IS NOT TRUE THEN
    RETURN v_result;
  END IF;

  RETURN v_result || json_build_object(
    'correct', v_correct,
    'score', v_score,
    'penalty', v_penalty
  );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_flutter_hourly_quiz(text, jsonb, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_flutter_hourly_quiz(text, jsonb, uuid) TO authenticated, service_role;
