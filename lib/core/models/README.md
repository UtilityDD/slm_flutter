# `lib/core/models/`

## `LinemanProfile`

Maps the Supabase profile row:

- `id`, `full_name`, `role`, `slm_id`, `avatar_url`
- `training_level`, `points`, `reading_points`, `quiz_points`, `total_penalties`
- `completed_lessons`
- `district`, `block`, `job`, `blood_group`

`LinemanProfile.guest()` is used when there is no session: name অতিথি লাইনম্যান, `SLM-GUEST`, Kolkata, 10 starter points.

`webBadgeLevel` in `features/home/lineman_progress.dart` lifts the hero rank from `training_level` and reading-point thresholds (180 … 1980 → levels 2 … 10).
