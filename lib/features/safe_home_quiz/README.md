# SAFE HOME quiz

A **short** snapped-conductor quiz, not the 19-level duty-slip climb.

| File | Role |
|---|---|
| `safe_home_quiz_engine.dart` | Intro → quiz → optional disturbance → done; timed |
| `safe_home_quiz_models.dart` | Pack / site / step |
| `safe_home_quiz_page.dart` | UI + `ZlFx` cues |

Pack: `assets/data/safe_home_snapped.json`.

Duty slip reuses the SAFE HOME **letters** as levels 1–8; this folder is the standalone quiz with a countdown (`secondsLeft` can finish the run).
