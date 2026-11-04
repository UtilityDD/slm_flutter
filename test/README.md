# Tests

All tests are in `test/perf/`. Run `flutter test`.

| File | Guards |
|---|---|
| `audio_perf_test.dart` | Pooled SFX (`SlmSfx`), one shared TTS, lazy players, background pause |
| `duty_games_perf_test.dart` | Dress-up / tray / coach art sizes, idle loops, remove-animations |
| `duty_page_perf_test.dart` | Duty-slip page: quiet idle screens, scoped HUD rebuilds, 1 Hz clock that pauses in background |
| `ladder_perf_test.dart` | The ladder does not rebuild every frame |
| `learning_perf_test.dart` | Images decode at display size, JSON parsed once off the UI isolate |
| `motion_perf_test.dart` | No remounts or lost taps, rebuilds per frame, no frames with remove-animations on |

Game rules (levels, living options, scoring) have no tests yet. Check them on the phone.
