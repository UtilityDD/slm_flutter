# `lib/core/`

App-wide, feature-agnostic code.

| Folder | What |
|---|---|
| `config/` | `AppConfig` — name, site URLs, Supabase URL / anon key from `--dart-define` with baked defaults |
| `constants/` | `AppConstants` — display name SmartLineman, version `1.0.0`, `https://smartlineman.in`, support mail, remote asset origin |
| `models/` | `LinemanProfile` (Supabase row + guest factory) |
| `network/` | `SupabaseService.initialize()` |
| `theme/` | `AppColors`, `AppTheme` light/dark (app forces light in `main.dart`) |

Do not put feature engines here. Duty slip, zero loss, quizzes stay under `lib/features/`.
