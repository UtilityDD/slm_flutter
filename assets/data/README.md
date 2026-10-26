# `assets/data/`

Offline JSON. Prefer the Dart `Write` tool / editor for Bangla — PowerShell `Set-Content` corrupts it.

| File | Consumer |
|---|---|
| `duty_slip_job.json` | 23-step plan, 3 sites, PTW/PPE/tools/calls, story_bn with `{{feeder}}` `{{pole}}` |
| `safe_home_snapped.json` | Standalone SAFE HOME quiz |
| `hourly_quiz_pack.json` | Hourly questions (no correct keys) |
| `safety_library.json` | Identify catalog |
| `identify_chart_pages.json` | How-to / tables / compare charts |
| `identify_chart_facts.json` | Extra chart facts |
| `zero_loss_storm_feeder.json` | Storm-feeder jobs |
| `zero_loss_asset_plan.json` | Zero-loss asset plan |
| `districtEmergencyServices.json` | জরুরি directory |
| `supplementary_modules.json` | Extra training modules |

`life_skill/` — see that folder.

Duty-slip plan ids must stay unique. SAFE HOME letters are **code** in `duty_slip_engine.dart`, not this JSON.
