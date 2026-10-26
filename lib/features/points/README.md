# Points

`score_panel.dart` — “breaker” metaphor for whether a source can still award points this month.

Sources: hourly quiz, lesson, life skill, gift.

States: **on** (কারেন্ট আছে), **charging** (cooldown), **full** (এই মাসে ফুল), **soon** (not wired yet).

Talks to Supabase + `hourly_pack` + training provider. Not a tab of its own; embed where a score box is needed.
