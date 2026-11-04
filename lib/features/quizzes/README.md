# Quizzes

| File | Role |
|---|---|
| `quiz_play_screen.dart` | Hourly quiz run (`/hourly`). Also the ladder's hourly station |
| `hourly_pack.dart` | Loads `assets/data/hourly_quiz_pack.json` |
| `identify_quiz_screen.dart` | "What is this photo?" from the library (`/identify-play`). Also a ladder station |
| `quiz_hub_screen.dart` | Hourly card + identify card (`/quiz`). Only the admin panel opens it now |
| `leaderboard_provider.dart` | Monthly boards from Supabase, used by `RankScreen` |

Hourly questions may be photos (`assets/quizzes/…`). Correct answers are **not** in the APK. The phone sends question id + chosen text. The Postgres function `submit_flutter_hourly_quiz` marks them (see `/supabase`). One play per hour window is enforced on the server.

Answer keys on disk (`tool/hourly_answer_keys.*`) are gitignored. Never commit them.
