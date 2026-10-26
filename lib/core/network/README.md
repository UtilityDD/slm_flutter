# `lib/core/network/`

`SupabaseService` wraps `Supabase.initialize` with auto-refresh auth.

`main.dart` catches init failures so a dead network still opens the app as guest.

Used by:

- `features/auth` session + profile fetch
- `features/quizzes/leaderboard_provider.dart`
- `features/training/training_provider.dart`
- hourly submit (`submit_flutter_hourly_quiz` — see `/supabase`)
- `features/points/score_panel.dart`
