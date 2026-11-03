# Zero Loss (জিরো লস): what is left

The storm-feeder game was never routed, and its screens were removed on branch `cleanup/audit-2026-11`. **Do not rebuild it.** Only these files remain:

| File | Why it stays |
|---|---|
| `zero_loss_fx.dart` | Shared audio for the whole app: `SlmSfx` (pooled SFX players), `ZlFx` (cues, `holdClock()` / `releaseClock()` for `clock_tick.wav`), `ZlMusic` |
| `zero_loss_ui.dart` | Only the night palette and text helper (`ZlColors`, `zlText`) used by duty slip |

The old engine, models and places files were deleted. `assets/data/zero_loss_storm_feeder.json` now has no reader.

Art in `assets/zero_loss/` is still bundled: duty slip uses many scene and crew files.
