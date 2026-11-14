# Supabase SQL

Run each file once in the Supabase SQL editor. **The database is shared with the live website**
(repo `slm_web`).

## The rule (owner decision "Option B", 2026-11-13)

- Every database object that only the Android app needs lives in the schema **`slm_app`**
  (files `slm_app_*.sql`).
- The website's tables and functions in `public` are **never modified** by this repo: no new columns,
  triggers, policies or replaced functions on public objects.
- The app only **reads** shared data (`auth.users` through `auth.uid()`, `public.profiles`,
  `public.hourly_questions`), and only inside `SECURITY DEFINER` functions in `slm_app`
  (`SET search_path = slm_app, public`), so it does not depend on the website's RLS. The one write
  into shared data is account deletion (the caller's own rows, profile and auth user).
- Phones never touch `slm_app` tables directly (RLS on, no grants); everything goes through RPCs,
  called from Dart as `SupabaseService.client.schema('slm_app').rpc(...)`.
- `test/slm_app_schema_guard_test.dart` checks both sides.

## Run order for the app (nothing run yet as of 2026-11-13)

| # | File | What |
|---|---|---|
| 00 | `slm_app_00_schema.sql` | Schema `slm_app`, grants, default privileges, `slm_app.is_admin()`, `slm_app.me_verified()` |
| 10 | `slm_app_10_league.sql` | League: one `league_month` and one `league_all` row per player (packed stars), `league_rungs` (append-only), `districts`, `league_winners`, `league_rung_counts`, `league_settings`; lazy monthly rollover; the cloud progress backup (`save_progress` / `load_progress`). See `docs/LEAGUE.md` |
| 11 | `slm_app_11_league_rungs_seed.sql` | The rung registry (id, idx, min_ms). **Append-only**: when new levels ship, add their ids at the end with the next idx and run it again. Without it every play is refused |
| 20 | `slm_app_20_toolbox_quiz.sql` | Lucky toolbox quiz: reads `hourly_questions`, awards nothing |
| 30 | `slm_app_30_delete_account.sql` | `delete_my_account()` (app) and `delete_user_data(uuid)` (dashboard only): also clears `league_month`, `league_all` (cloud save), `league_winners`, `league_settings`. **Run its CHECK query first** |

**Then, once, in the dashboard:** Project Settings → API (Data API) → **Exposed schemas**: add
`slm_app` (keep `public` and `graphql_public`) and save. Without it every app call fails with
"The schema must be one of the following", and the app shows its offline state.

Every file is safe to run again. Each ends with `NOTIFY pgrst, 'reload schema'`.

## On hold: `HOLD_profiles_privacy.sql`

**Do not run it.** It would replace the SELECT/UPDATE policies on the website's `public.profiles` (each
person reads only their own row) and create `public.is_admin()` and the view `public.profiles_public`.
That breaks Option B and would break any website page that reads other people's profiles directly.
Run it only after the website reads other users' profiles through safe functions or views, and the
web owner agrees. It is also out of date (it reads the old `league_*` profile columns, which are never
created now) and must be rewritten against `slm_app.league_settings` first. The app does not depend on it.

## Web / older files (already run, web-owned)

| File | What |
|---|---|
| `submit_flutter_hourly_quiz.sql` | Hourly scoring for the old app (below). Left as is |
| `admin_access.sql`, `admin_people_page.sql` | Admin-only functions for the in-app admin panel |
| `block_user.sql` | Block and unblock (`profiles.blocked`) |
| `verify_toggle.sql`, `verify_lineman.sql` | Verify / unverify a lineman (`profiles.verified`) |
| `fix_new_google_signup.sql` | Profile row for a brand-new Google sign-up |

These were written before Option B and change `public`. Do not extend them; new app objects go into
a new `slm_app_*.sql` file.

## `submit_flutter_hourly_quiz.sql`

- Table `flutter_hourly_answer_keys (question_id, correct_choice)` — RLS on, **no** grants to `anon` / `authenticated`
- Function `submit_flutter_hourly_quiz(p_quiz_id, p_answers jsonb, p_user_id uuid)` `SECURITY DEFINER`
- Phone sends `{question id, chosen option text}`; function counts right/wrong, applies the same hour window / one-play / points path as the existing web submit
- Does **not** replace `submit_quiz_result_v2`. The website must not call this

Project URL is configured in `lib/core/config/app_config.dart` (override with dart-defines). Do not put service-role keys in this repo.
