# Home

Tab 0. Cream backdrop, name + Bangla/English pill, **মৃত্যুহীন** card, then the lineman hero carousel.

## Entry

`DutySlipPage.open(context)` from `_ZeroLossCard`. Button copy is **মৃত্যুহীন** only — no extra subtitle.

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
