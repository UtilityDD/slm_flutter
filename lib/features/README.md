# `lib/features/`

One folder per product area. The app is one game: Home → the মৃত্যুহীন পথ ladder. Everything else opens from the Home toolbox, a ladder station, or Settings. There is no tab bar. Target design: [`GAME_DESIGN.md`](../../GAME_DESIGN.md).

| Folder | What |
|---|---|
| `shell` | `MainShell`: nested `Navigator`, Android back via `NavigatorPopHandler`, Hero controller, named routes (`app_routes.dart`), `languageProvider` + `tr()`, `ShellDockScope` bottom inset |
| `home` | Home screen, toolbox sheet, path intro / fear pages, lesson reader + quiz, read-aloud TTS. See [`home/README.md`](home/README.md) |
| `duty_slip` | The ladder (`adventure_map.dart`) and the 33 duty levels. See [`duty_slip/README.md`](duty_slip/README.md) |
| `game` | Data-driven ladder: `content_catalog.dart` (reads `assets/game/catalog/content_catalog.json`), `ladder_builder.dart`, `game_save.dart` (local points, deaths, current rung), `learn_runner.dart` (Learn rungs), `beat_fx.dart` (score fly, death moment), `game_exit_sheet.dart` |
| `guide` | AI Line Man guide face and its director on the ladder |
| `identify` | Gear photo library and charts. See [`identify/README.md`](identify/README.md) |
| `quizzes` | Hourly quiz, identify quiz, quiz hub, leaderboard provider. See [`quizzes/README.md`](quizzes/README.md) |
| `training` | `TrainingScreen`: Supabase lesson modules. Opened from the ladder's lesson station |
| `rank` | `RankScreen`: monthly leaderboard (podium, top 25, your place). Data from `quizzes/leaderboard_provider.dart` |
| `sops` | `SopsScreen`: PPE checklist (`/ppe`) and 8 মন্ত্র (`/mantra`) |
| `emergency` | `EmergencyDirectoryScreen`: district numbers from `assets/data/districtEmergencyServices.json`. Tap dials (needs the `tel` `<queries>` entry in the manifest) |
| `more` | Settings (`/more`): profile edit, language, certificate, PPE, admin (admins only), log out |
| `auth` | `auth_provider.dart` (session, profile, guest fallback), Google sign-in mark, verify gate / sheet / tick |
| `admin` | Admin panel (`/admin`) and the developer unlock (`devLevelsOpen`) |
| `radio` | Mini player provider and widget. Nothing in the app turns it on |
| `zero_loss` | Engine, models, places, FX and shared UI only. Its screens were removed. See [`zero_loss/README.md`](zero_loss/README.md) |

## Routes (`shell/app_routes.dart`)

Opened with `pushNamed`: `/more`, `/emergency`, `/rank`, `/identify` (Home toolbox), `/ppe`, `/admin` (Settings), `/identify-play`, `/hourly`, `/quiz` (Identify, quiz hub, admin). Other pages are pushed directly with `MaterialPageRoute` or `SlmPageRoute`.

## Rules for every feature

- Bangla first. Water is **জল**, never পানি. Say **ডকেট**, **শাটডাউন**, **গ্লাভস**.
- Numbers are Western digits `0–9`, even in Bangla copy.
- Loops follow the one reduced-motion policy in [`lib/design/MOTION.md`](../design/MOTION.md).
