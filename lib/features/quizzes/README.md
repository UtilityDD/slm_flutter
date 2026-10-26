# Quizzes

Hub plus two play modes.

| File | Role |
|---|---|
| `quiz_hub_screen.dart` | Hourly card + Identify-match card |
| `quiz_play_screen.dart` | Hourly run |
| `hourly_pack.dart` | Loads `assets/data/hourly_quiz_pack.json` |
| `identify_quiz_screen.dart` | “What is this photo?” from the library |
| `quizzes_screen.dart` | Older / extra quiz list if still routed |
| `leaderboard_provider.dart` | Rank boards from Supabase |

Hourly questions may be visual (`assets/quizzes/…`). Correct answers are **not** in the APK. The phone sends question id + chosen text; Postgres function `submit_flutter_hourly_quiz` marks them (see `/supabase`). Keys on disk: `tool/hourly_answer_keys.*` — gitignored.

IST hour label is shown on the hub card. One play per hour window is enforced server-side.
