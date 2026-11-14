# Home

One-tap Home on the navy backdrop: ◆ score and 💀 deaths (the level top bar's chips) and the toolbox button on top; the name with a status chip (`✓ যাচাইকৃত`, `⏳ যাচাই চলছে` → verify sheet, guests `সাইন ইন করুন` → `/login`); the "continue" card (the next rung `L<n>`, `মডিউল <m>`, the module's progress bar and stars, a still `AnimatedSafetyShield`); one gold button `চলুন, L<n>`; the line "ঘরে আপনার জন্য কেউ অপেক্ষা করছে।"; and chips shown only when true (`🎁 <n>টি উপহার অপেক্ষা করছে`, `🏆 জেলায় #<k>`). When every open rung is cleared the card says "সব খোলা ধাপ শেষ! নতুন মডিউল শীঘ্রই আসছে". An idle Home draws no frames.

## Flow

Brand splash (cold start only, ≤ 1.5 s, tap to skip; `lib/features/startup/brand_intro.dart`) → Home → gold button → `DutySlipPage`, which opens on the ladder already scrolled to the current rung (a waiting gift chest nearby stays in view). The gift chip opens the ladder at the chest (`DutySlipPage(anchor:)`). The next rung comes from `ladder_focus.dart` (`lib/features/duty_slip/`), the same code the ladder uses for its current rung. Home reloads `gameSaveProvider` when the player comes back. The intro and skull pages were removed on purpose (owner, Nov 2026).

The toolbox (`home_toolbox.dart`) is Home's sheet. It opens `/rank`, `/identify`, `/emergency` and `/more`.

## Files

| File | Role |
|---|---|
| `home_screen.dart` | Home layout |
| `home_toolbox.dart` | Toolbox button and sheet |
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
