# Home

Tab 0. Navy premium backdrop, name + verify tick + বাং / EN switch, the lineman hero carousel, then the **মৃত্যুহীন পথ** button. Premium rules: root [`README.md`](../../../README.md#premium-design-system-and-motion).

## Entry

`DutySlipPage.open(context, sourceRect:)` from `_PathPlayChip`. The button is `_PathBadge`: `AnimatedSafetyShield` + real text **মৃত্যুহীন পথ** + gold arrow, 270 px wide (narrower on small screens). Tap keeps the old charge pulse, haptic and `quiz_select.wav` cue.

## Learning flow

Hero card tap → `openLevelLessons` (card-expand flight) → `LevelZeroPage` for level 0, or `LevelLessonsPage` (lesson shelf) for 1–10 → `LessonReaderPage` → lesson quiz → snackbar + `+20 পয়েন্ট` toast, or `LevelCelebrationPage` when the level is cleared. All of it is in the navy design except the quiz and celebration pages. Reading text stays dark on an ivory sheet.

`HeroCard(premium: true)` is used by the carousel and the expand flight only.

## Files

| File | Role |
|---|---|
| `home_screen.dart` | Layout + মৃত্যুহীন card |
| `hero_card.dart` / `hero_card_carousel.dart` | Rank pages 0–10 |
| `lineman_figure.dart` | Draws `assets/lineman/lineman_NN_*.webp` |
| `lineman_progress.dart` | Rank names, reading-point thresholds, caution pins |
| `level_zero_page.dart` / `level_lessons_page.dart` / `level_lessons_sheet.dart` | Training lessons per rank |
| `level_celebration_page.dart` | Rank-up |
| `lesson_reader_page.dart` / `lesson_rich_text.dart` | Lesson body + media markup |
| `lesson_quiz_page.dart` / `quiz_turn_card.dart` / `lesson_quiz_sfx.dart` | End-of-lesson quiz cues |
| `lesson_progress_store.dart` | Local completed-lesson ids |
| `bangla_read_aloud.dart` | TTS; strips `((media\|label))` and `[[image\|caption]]` |

## Ranks

ট্রেইনি → জুনিয়র → টেকনিশিয়ান → স্কিলড → অ্যাডভান্সড → সিনিয়র → সুপারভাইজার → স্পেশালিস্ট → এক্সপার্ট → সেফটি প্রো.
