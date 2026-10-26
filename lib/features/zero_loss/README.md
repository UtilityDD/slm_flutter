# Zero Loss (জিরো লস)

Older “one storm-night as feeder in-charge” sim. Engine, TBT, crew, field canvas, stress calls, and FX still live here. **Home currently opens duty slip instead.** `ZeroLossPage.open` remains if something else routes to it.

## Files (high level)

| File | Role |
|---|---|
| `zero_loss_engine.dart` | Shift state, faults, crew assign, scoring |
| `zero_loss_models.dart` | Scenario, faults, gear, moods |
| `zero_loss_places.dart` | West Bengal district / town names |
| `zero_loss_page.dart` | Root UI |
| `zero_loss_opening.dart` / `zero_loss_rules.dart` | Brief + rules |
| `zero_loss_tbt.dart` / `zero_loss_tbt_preview.dart` | Toolbox talk |
| `zero_loss_crew.dart` | Anil, Bapi, Kartik, Rafiq, Subrata |
| `zero_loss_field.dart` / `zero_loss_scene.dart` / `zero_loss_work_site.dart` | Site canvas |
| `zero_loss_stress.dart` | Villager / customer / accident pressure |
| `zero_loss_fx.dart` | `ZlFx` cues (shuffle, tick, accident, complaint…) |
| `zero_loss_ui.dart` / `zero_loss_reveal.dart` | Shared chrome |

## Data

- `assets/data/zero_loss_storm_feeder.json` — jobs, gear, protocol
- `assets/data/zero_loss_asset_plan.json` — asset map
- `assets/zero_loss/crew/` and `scene/`

Tests: `test/zero_loss_engine_test.dart`.
