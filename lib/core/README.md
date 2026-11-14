# `lib/core/`

App-wide code with no feature logic. Feature engines stay under `lib/features/`.

| Path | What |
|---|---|
| `config/app_config.dart` | `AppConfig`, the one config source: name, site URL, `remoteAssetOrigin` (`https://www.smartlineman.in`, where large posters, audio and quiz packs stream from), admin emails, auth redirect, Google web client id, Supabase URL and anon key |
| `en_digits.dart` | `enDigits`: turns `০–৯` into `0–9` |
| `models/lineman_profile.dart` | `LinemanProfile` (Supabase profile row) and `LinemanProfile.guest()` (`SLM-GUEST`) |
| `network/supabase_service.dart` | `SupabaseService.initialize()` / `.ready`. Needs no network (restores the saved session from the phone); `main.dart` starts it just after the first frame and never awaits it. A plugin/config failure is logged and the app runs as guest |
| `startup/app_memory.dart` | Image-cache budget by phone RAM (48 MB on 3–4 GB phones, never under 24 MB, which fits the heaviest screen) and a trim on OS memory pressure |
| `startup/startup_trace.dart` | Stopwatch log of startup steps; `test/perf/startup_perf_test.dart` guards that nothing is awaited before `runApp` |
| `theme/` | `AppColors`, `AppTheme`: the older cream / amber look (light only, built once) |

Supabase URL and anon key can be overridden at build time:

```
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Never put the service-role key in the app, in git or in a README.
