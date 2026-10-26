# `lib/core/config/`

`AppConfig` holds:

- App name **SmartLineman**, version **1.0.0**
- Sites: `https://smartlineman.in` and `https://www.smartlineman.in`
- Support: `support@smartlineman.in`
- Supabase URL and anon key via `String.fromEnvironment('SUPABASE_URL' | 'SUPABASE_ANON_KEY')` with project defaults

Override at build time:

```
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Do not paste keys into README files.
