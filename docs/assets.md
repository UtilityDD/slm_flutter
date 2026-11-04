# Assets (`assets/`)

These notes live here, not in `assets/`. Flutter ships every file in a folder that `pubspec.yaml` lists, README files too. So **never put a `.md` (or any non-asset file) inside an asset folder.**

`pubspec.yaml` lists folders, so a new file in a listed folder ships with no pubspec edit. Sounds in `assets/sounds/` are listed one by one. Subfolders are not included: each one needs its own line.

Large posters and some lesson media are not bundled. They stream from `https://www.smartlineman.in` (`AppConstants.remoteAssetOrigin`).

## Folders

| Folder | What | Read by |
|---|---|---|
| `data/` | JSON packs (table below) | see table |
| `data/life_skill/` | 13 life-skill lessons, `lesson_10_1.json` … `lesson_10_13.json` | nothing now (the Life Skill UI was removed; content kept) |
| `game/catalog/content_catalog.json` | Modules, lessons, rungs, game packs, guide lines for the ladder | `lib/features/game/content_catalog.dart` |
| `duty_slip/` | Night-job photos (docket, PTW, brass plate, pole stencil, tool bag, van, callers) | duty slip |
| `duty_slip/dress/` | Dress-up and guide art | `ds_dress_up.dart`, `ai_lineman_guide.dart` |
| `duty_slip/world3d/` | Ladder world layers (see `tool/world3d_production/ASSET_REGISTER.md`) | `adventure_map.dart` |
| `brand/` | `shield_body/rim/glass.webp`, the three layers of the animated shield (see `lib/design/MOTION.md`) | `slm_safety_shield.dart` |
| `lineman/` | Rank figures `lineman_00_start` … `lineman_10_pro` (`.webp`). Cut from the JPGs in `tool/media_src/lineman/` with `tool/remove_lineman_bg.py` | `lineman_figure.dart` |
| `quizzes/` | Quiz stills (prefixes below) | hourly pack, identify quiz |
| `safety/library/<cat>/` | Identify photos: `ppe`, `tools`, `insulators`, `ab-cable-items`, `ug-cable`, `others`, `charts` | Identify, duty slip kit |
| `zero_loss/crew/`, `zero_loss/scene/` | Crew portraits; scene layers `bg_*`, `gear_*`, `acc_*`, `spr_*`, `cust_*` | duty slip reuses many (sites, gear, lineman sprites) |
| `sounds/` | Wav cues; `sounds/intro/*.ogg`; `sounds/voice/` voice clips | `SlmSfx` / `ZlFx` in `zero_loss_fx.dart`, `DsVoice` |
| `fonts/` | Noto Sans Bengali 400 / 500 / 600 / 700. Family name `Noto Sans Bengali` | theme |

Source and tool-only art lives in `tool/media_src/`, which mirrors the `assets/` layout and does not ship: brand JPEGs, lineman JPGs, unused world3d renders and `ASSET_REGISTER.json`, the dress `house*` / `tray_loose` cut-outs, Zero Loss `acc_*` / `gear_*` files the tool scripts read, 7 unlinked library photos, and the reader-less JSON packs.

## `data/` files

| File | Read by |
|---|---|
| `duty_slip_job.json` | `duty_slip_models.dart`: 23-step plan, 3 sites, PTW / PPE / tools / calls, `story_bn` with `{{feeder}}` `{{pole}}` |
| `hourly_quiz_pack.json` | `quizzes/hourly_pack.dart`. No answer keys |
| `safety_library.json`, `identify_chart_facts.json` | `identify/library_catalog.dart` |
| `identify_chart_pages.json` | `identify/identify_charts.dart` |
| `districtEmergencyServices.json` | `emergency/emergency_directory_screen.dart` |
| `wb_locations.json` | `more/profile_edit.dart` |

`zero_loss_storm_feeder.json` and `supplementary_modules.json` had no Dart reader and moved to `tool/media_src/data/`. `safe_home_snapped.json` and `zero_loss_asset_plan.json` were deleted.

Rules:

- Duty-slip plan ids must stay unique. SAFE HOME letters are code in `duty_slip_engine.dart` (`dsSafeHome`), not JSON.
- `safety_library.json` rows: `id`, `category`, `name_bn`, `function_bn`, `guide_bn`, `approx_price_inr`, `images[]`, `related_items`. Image file names are path tails in JSON, so keep them stable.
- Life-skill lesson shape: `level_id` (`supp_10_N`), `level_title`, `mission_briefing`, `sections[]` → `title`, `points[]` (`item_name`, `specifications`, `importance`, `daily_check`, optional `image_name` / `image_caption`).

## `quizzes/` name prefixes

`img_*` hourly photos (opaque ids) · `mat_*` materials and tools · `mistake_*` unsafe acts · `proc_*` procedure errors · `dtr_*` / `ptr_*` transformer parts · `vcb_*` / `swy33_*` breaker and 33 kV yard · `vq_*` visual questions. Keep paths in `hourly_quiz_pack.json` in step. Never store answer keys next to these images.

## Duty-slip sites

road → `zero_loss/scene/bg_market_wire_down.webp` · pond → `bg_pole_storm.webp` · paddy → `bg_span_two_poles.webp`.

## Editing Bangla JSON

Edit in the editor or with a UTF-8 tool. PowerShell `Set-Content` corrupts Bangla.
