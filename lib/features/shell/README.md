# Shell

The running frame of the app.

## Files

| File | Role |
|---|---|
| `main_shell.dart` | Scaffold + nested Navigator + notched 4-tab dock + radio strip |
| `app_routes.dart` | Named route constants |
| `shell_providers.dart` | `shellTabProvider`, `languageProvider`, `tr()` |
| `shell_insets.dart` | Bottom padding so pages clear the dock (`ShellDockScope`) |
| `feature_page.dart` | Placeholder page used by several More routes |

## Tabs (index)

0 Home · 1 Identify · 2 Rank · 3 Life Skill

Selecting a tab pops to the first route then swaps `_TabHost`.

## Routes

`/`, `/training`, `/mantra`, `/ppe`, `/quiz`, `/hourly`, `/identify-play`, `/more`, `/emergency`, `/login`, plus More placeholders: story, prizes, guide, progress, faq, know-more, video, tools, tales, notices, forum.

The dock is an overlay, not `Scaffold.bottomNavigationBar`, so the notch stays transparent.
