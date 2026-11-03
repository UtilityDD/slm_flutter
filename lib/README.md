# `lib/`

All Dart for SmartLineman.

| Path | Role |
|---|---|
| `main.dart` | Best-effort Supabase init, `ProviderScope`, `MaterialApp(home: MainShell())`. Theme is locked to light |
| `core/` | Config, constants, digits, profile model, Supabase client, old cream theme. See [`core/README.md`](core/README.md) |
| `design/` | Navy / emerald / gold design system and motion. Import `design/slm_design.dart`. Motion rules: [`design/MOTION.md`](design/MOTION.md) |
| `features/` | One folder per product area. See [`features/README.md`](features/README.md) |
| `shared/widgets/slm_backdrop.dart` | Cream paper backdrop. Only the quiz hub uses it |

Navigation is a nested `Navigator` inside `MainShell` with named routes from `features/shell/app_routes.dart`. There is no tab bar and no `go_router`.

Language (Bangla / English) is `languageProvider` in `features/shell/shell_providers.dart`. Copy goes through `tr(bn, bangla, english)`. Numbers are always Western digits `0–9`: use `enDigits` (`core/en_digits.dart`).
