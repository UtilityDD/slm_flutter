# Home

One-button Home on the navy backdrop: name, verify tick, বাং / EN switch, score and death count in the corners, the toolbox button, and the **মৃত্যুহীন পথ** shield button (`AnimatedSafetyShield` + real Bangla text).

## Flow

Shield button → `PathIntroPage` → `PathFearPage` (first open of the day, or after 4 hours: `PathFearGate`) → `DutySlipPage(startOnRoad: true)`, which opens on the ladder. Home reloads `gameSaveProvider` when the player comes back.

The toolbox (`home_toolbox.dart`) is one sheet shared by Home, the intro and the fear page. It opens `/rank`, `/identify`, `/emergency` and `/more`.

## Files

| File | Role |
|---|---|
| `home_screen.dart` | Home layout |
| `home_toolbox.dart` | Toolbox button and sheet |
| `path_intro_page.dart`, `path_fear_page.dart`, `path_fear_gate.dart` | Pages before the ladder |
| `lesson_reader_page.dart`, `lesson_rich_text.dart` | Lesson body and media markup (opened from `TrainingScreen`) |
| `lesson_quiz_page.dart`, `quiz_turn_card.dart`, `lesson_quiz_sfx.dart` | End-of-lesson quiz |
| `lesson_quiz_store.dart` | Lesson quiz download with a disk copy (works offline once fetched). A lesson never clears without its quiz |
| `level_celebration_page.dart` | Level cleared. Pops back to the screen that opened the lesson |
| `lesson_progress_store.dart` | Local completed-lesson ids |
| `lineman_figure.dart`, `lineman_progress.dart` | Rank figures (`assets/lineman/`), rank names, `webBadgeLevel` |
| `bangla_read_aloud.dart` | The one shared device TTS. Strips `((media\|label))` and `[[image\|caption]]` |

## Ranks

ট্রেইনি → জুনিয়র → টেকনিশিয়ান → স্কিলড → অ্যাডভান্সড → সিনিয়র → সুপারভাইজার → স্পেশালিস্ট → এক্সপার্ট → সেফটি প্রো (`lineman_01` … `lineman_10`, plus `lineman_00_start`).

Reading text stays dark ink on an ivory sheet. Field staff read it in sunlight.
