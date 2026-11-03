# Identify — পরিচিতি

Photo library of field gear plus how-to / rating charts. Route `/identify`, opened from the Home toolbox.

| File | Role |
|---|---|
| `identify_screen.dart` | Category grid |
| `library_catalog.dart` | Loads `assets/data/safety_library.json`, categories, search index, stats |
| `identify_detail_page.dart` | One item: photos, function, guide, price INR, related |
| `identify_search.dart` | Search |
| `identify_charts.dart` / `identify_chart_view.dart` | Chart kinds: howto, compare, table, sections, cards |
| `identify_style.dart` | Local look |
| `fit_image.dart` | Decodes photos at display size (keep using it for new images) |

## Categories (order)

PPE → Tools → Insulators → AB Cable Items → Others → Charts.

Photos live under `assets/safety/library/<folder>/`. Chart bodies: `assets/data/identify_chart_pages.json` (+ facts file). Chart numerals are forced to Western digits.

Identify **play** (photo quiz) is `features/quizzes/identify_quiz_screen.dart`.
