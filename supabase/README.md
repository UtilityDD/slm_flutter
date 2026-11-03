# Supabase SQL

Run each file once in the Supabase SQL editor. The database is shared with the website.

| File | What |
|---|---|
| `submit_flutter_hourly_quiz.sql` | Hourly scoring for the app (below) |
| `admin_access.sql` | Admin-only functions for the in-app admin panel |
| `block_user.sql` | Block and unblock |
| `verify_toggle.sql`, `verify_lineman.sql` | Verify / unverify a lineman |
| `fix_new_google_signup.sql` | Profile row for a brand-new Google sign-up |

## `submit_flutter_hourly_quiz.sql`

- Table `flutter_hourly_answer_keys (question_id, correct_choice)` — RLS on, **no** grants to `anon` / `authenticated`
- Function `submit_flutter_hourly_quiz(p_quiz_id, p_answers jsonb, p_user_id uuid)` `SECURITY DEFINER`
- Phone sends `{question id, chosen option text}`; function counts right/wrong, applies the same hour window / one-play / points path as the existing web submit
- Does **not** replace `submit_quiz_result_v2`. The website must not call this

Project URL is configured in `lib/core/config/app_config.dart` (override with dart-defines). Do not put service-role keys in this repo.
