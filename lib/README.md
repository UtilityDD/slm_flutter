# `lib/`

All Dart for SmartLineman.

| Path | Role |
|---|---|
| `main.dart` | `WidgetsFlutterBinding`, best-effort Supabase init, `ProviderScope`, `SmartLinemanApp` |
| `core/` | Config, colours, profile model, Supabase client |
| `features/` | Screens and engines, one folder per product area |
| `shared/` | Backdrop, tiles, native top bar |

`main.dart` does **not** use `go_router` at runtime. `MaterialApp(home: MainShell())` owns a nested `Navigator` with named routes from `features/shell/app_routes.dart`.

Language toggle (Bangla / English) is a Riverpod provider in `features/shell/shell_providers.dart`. Most copy is Bangla-first via `tr(bn, bangla, english)`.
