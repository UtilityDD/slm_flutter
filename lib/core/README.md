# `lib/core/`

App-wide code with no feature logic. Feature engines stay under `lib/features/`.

| Path | What |
|---|---|
| `config/app_config.dart` | `AppConfig`: name, version `1.0.0`, site URLs, support mail, admin emails, auth redirect, Google web client id, Supabase URL and anon key |
| `constants/app_constants.dart` | `AppConstants`: branding and `remoteAssetOrigin` (`https://www.smartlineman.in`), where large posters and audio stream from |
| `en_digits.dart` | `enDigits`: turns `০–৯` into `0–9` |
| `models/lineman_profile.dart` | `LinemanProfile` (Supabase profile row) and `LinemanProfile.guest()` (`SLM-GUEST`) |
| `network/supabase_service.dart` | `SupabaseService.initialize()`. `main.dart` catches failures, so a dead network opens the app as guest |
| `services/neural_tts_service.dart` | Neural TTS. Present but switched off; lessons use the phone's Bangla voice |
| `theme/` | `AppColors`, `AppTheme`: the older cream / amber look |

Supabase URL and anon key can be overridden at build time:

```
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Never put the service-role key in the app, in git or in a README.
