# Supabase (Flutter hourly only)

`submit_flutter_hourly_quiz.sql`

- Table `flutter_hourly_answer_keys (question_id, correct_choice)` — RLS on, **no** grants to `anon` / `authenticated`
- Function `submit_flutter_hourly_quiz(p_quiz_id, p_answers jsonb, p_user_id uuid)` `SECURITY DEFINER`
- Phone sends `{question id, chosen option text}`; function counts right/wrong, applies the same hour window / one-play / points path as the existing web submit
- Does **not** replace `submit_quiz_result_v2`. The website must not call this

Project URL is configured in `lib/core/config/app_config.dart` (override with dart-defines). Do not put service-role keys in this repo.
