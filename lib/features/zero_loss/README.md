# Zero Loss (জিরো লস): what is left

The storm-feeder game was never routed, and its screens were removed on branch `cleanup/audit-2026-11`. **Do not rebuild it.** Only these files remain:

| File | Why it stays |
|---|---|
| `zero_loss_fx.dart` | Shared audio for the whole app: `SlmSfx` (pooled SFX players), `ZlFx` (cues, `holdClock()` / `releaseClock()` for `clock_tick.wav`), `ZlMusic` |
| `zero_loss_ui.dart` | Night palette, text and small widgets (`ZlColors`, `zlText`, `ZlVoice`, `CrewFace`, `GearPicture`…) used by duty slip |
| `zero_loss_engine.dart`, `zero_loss_models.dart`, `zero_loss_places.dart` | Old engine and its types. `zero_loss_ui.dart` imports them; no screen runs the game. The engine reads `assets/data/zero_loss_storm_feeder.json` |

Art in `assets/zero_loss/` is still bundled: duty slip uses many scene and crew files.
