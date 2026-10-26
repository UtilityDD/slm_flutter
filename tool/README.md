# Tooling (not in the APK)

| Script | Job |
|---|---|
| `write_quiz_cues.py` | Quiz wav helpers |
| `cut_scene_assets.py` | Crop/export zero-loss scene layers |
| `expand_zero_loss_jobs.py` | Rebuild `zero_loss_storm_feeder.json` + copy gear webp |
| `remove_lineman_bg.py` | Knock out hero backgrounds |
| `export_hourly_pack.mjs` / `slim_hourly_pack.mjs` | Build/slim `hourly_quiz_pack.json` |
| `write_answer_key_sql.mjs` | Emit SQL for `flutter_hourly_answer_keys` |

Gitignored (never ship):

- `tool/hourly_answer_keys.json`
- `tool/hourly_answer_keys.sql`
