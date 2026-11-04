# Tooling (not in the APK)

| Script | Job |
|---|---|
| `slm_game_voice_library.py`, `update_duty_slip_voice_dart.py` | Voice clips and the `duty_slip_voice.dart` map (see `AUDIO_DEVELOPMENT_GUIDE.md`) |
| `game_voice_catalog.json` | Master voice line list |
| `generate_*.py`, `write_quiz_cues.py` | Other audio and quiz cue helpers |
| `export_hourly_pack.mjs`, `slim_hourly_pack.mjs` | Build / slim `assets/data/hourly_quiz_pack.json` |
| `write_answer_key_sql.mjs` | SQL for `flutter_hourly_answer_keys` |
| `remove_lineman_bg.py` | Cut backgrounds from rank figures |
| `cut_*.py`, `clean_dress_gaps.py`, `clear_*.py` | Dress-up and scene art cleanup |
| `build_lesson_*.py` | Lesson 1.x media and portraits |
| `cut_scene_assets.py`, `expand_zero_loss_jobs.py` | Old Zero Loss scene and job data (the game screens are gone) |
| `world3d_production/` | Ladder world renders. Register: `world3d_production/ASSET_REGISTER.md` |
| `media_src/` | Source and tool-only art and data kept out of the APK (mirrors `assets/`) |
| `all_training_chapters_bn.json`, `inspect_*.py`, `dump_curriculum_details.py`, `fetch_chapters.py` | Training chapter source and inspectors |

Never commit (gitignored): `tool/hourly_answer_keys.json`, `tool/hourly_answer_keys.sql`.
