# Auth

| File | Role |
|---|---|
| `auth_provider.dart` | Session restore, profile fetch, guest fallback, sign out |
| `login_screen.dart` | Sign in (Supabase) |

No session → `LinemanProfile.guest()`. Init errors also become guest so Home still works.

Profile fields drive rank, points, district, completed lessons.
