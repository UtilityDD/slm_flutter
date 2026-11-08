# মৃত্যুহীন পথ (The Zero-Death Path) — Unified Developer Guide

> **Single source of implementation truth for collaborators.**  
> Read this before adding or editing a **Learn level**, **Do field level**, **side item**, **mascot line**, or **score animation**.  
> Product intent lives in [`GAME_DESIGN.md`](GAME_DESIGN.md). **How to build any level: [`GAME_LEVEL_PLAYBOOK.md`](GAME_LEVEL_PLAYBOOK.md) — read it first.** Legacy `dsLevels` visual specs live in [`lib/features/duty_slip/GAME_LEVELS_GUIDE.md`](lib/features/duty_slip/GAME_LEVELS_GUIDE.md). Repo rules live in [`AGENTS.md`](AGENTS.md).  
> **Status (Nov 2026):** Learn **1.1** is a picture board (`LearnBoardRunnerPage`). Every other playable Learn rung, including 1.2, is the text deck (`LearnRunnerPage`). Do rungs open the dress-up and field games. Ladder step 2 (`1.1/do/0`) is still পোশাক: drag the shirt, trousers, and boots onto the figure.

---

## 1. Core Philosophy

The app is **one climb**, not a classroom with a textbook tab, a quiz tab and a game tab.

1. **Learn is a game, not a wall of text.** Players are West Bengal distribution linemen on a 1–2 minute break. A Learn rung is either a picture board (pick the kit, say why, beat the rival) or a short flash-card deck plus two field questions. The full lesson lives behind a **পাঠ** offer — never as the level itself.
2. **One score (`◆`) and one death count (`💀`).** Points go through `GameSave.addPoints` / `BeatFx.scoreDelta` only. There is no second level-score box, no `nightTotal` on Learn, and the clock **never closes a level**.
3. **Reading a lesson awards no `◆`.** [`LessonReaderPage`](lib/features/home/lesson_reader_page.dart) finishes with a **seal stamp** ([`LessonSealPage`](lib/features/home/lesson_seal_page.dart)), not points. The win feel is the seal, not a toast of `+20`.
4. **One mascot ("ওস্তাদ").** Ladder, Learn and Do all use [`AiLinemanGuide`](lib/features/guide/ai_lineman_guide.dart). Fixed lines go through [`MascotSpeechLibrary.speak`](lib/features/guide/mascot_speech_library.dart) so the mouth (`MascotTalk.active`) matches the voice.
5. **Field Bangla.** Everyday electrical words stay as the crew says them: PTW, Shutdown, Docket, Earthing, Jumper, LOTO, PPE, Gloves, Harness, Helmet, 11 kV. Locked words: **ডকেট**, **শাটডাউন**, **জল**, **গ্লাভস** (never দস্তানা / পানি). Digits always `0–9` via [`enDigits()`](lib/core/en_digits.dart). Animate Bangla **by word**, never by code point.

---

## 2. File Map

```
lib/features/
├── game/
│   ├── content_catalog.dart          # assets/game/catalog/content_catalog.json
│   ├── ladder_builder.dart           # Learn → Do → … → Gate
│   ├── game_save.dart                # ◆, 💀, rungProgress, bestTime, bestMark, plays
│   ├── beat_fx.dart                  # UnifiedGameTopHud + ScoreFlyHost + DeathMomentHost
│   ├── learn_board_models.dart       # LearnBoardPack / Slot / Option / WhyChip / Myth
│   ├── learn_board_deal.dart         # LearnDealer — deal + reshuffle after a miss
│   ├── learn_board_runner.dart       # Picture Learn (lesson 1.1)
│   ├── learn_runner.dart             # Text Learn (every other playable lesson)
│   ├── learn_feedback_lines.dart     # Wrong / right / why / fail pools + LearnCoachLines
│   ├── read_lesson_offer.dart        # 3-in-a-row tally, পাঠ pill, fly card, end nudges
│   ├── level_result_parts.dart       # 60% pass mark, history chip, fail panel
│   ├── learn_voice.dart              # Player for assets/sounds/learn_voice/
│   └── learn_voice_map.dart          # GENERATED — text → mp3 (do not hand-edit)
├── guide/
│   ├── mascot_speech_library.dart    # Cues + speak() router (DsVoice → LearnVoice → TTS)
│   ├── ai_lineman_guide.dart         # Coach sprites + mouth overlay
│   ├── guide_director.dart           # Mood / entrance / levelFocus / comeback
│   └── ladder_guide_host.dart        # Corner dock + first-open-of-day welcome
├── home/
│   ├── lesson_reader_page.dart       # Full lesson (no ◆). Offline snackbar if no points.
│   ├── lesson_seal_page.dart         # Stamp win after reading
│   └── lesson_progress_store.dart    # completed_lessons (stable ids, never list index)
├── training/
│   └── training_screen.dart          # Toolbox → প্রশিক্ষণ জোন (seals, no score)
└── duty_slip/
    ├── adventure_map.dart            # Ladder. _openLearn picks board vs text runner
    ├── duty_slip_page.dart           # Do host (swaps AdventureMap out while onRoad is false)
    ├── duty_slip_engine.dart         # dsLevels 1–33
    ├── duty_slip_voice.dart          # GENERATED Duty-Slip MP3 map (Bashkar)
    ├── ds_dress_up.dart              # Do 1–10
    ├── ds_pole_inspect.dart          # Do 11–13
    ├── ds_clearance.dart             # Do 14
    └── GAME_LEVELS_GUIDE.md          # Do visual + speech specs

assets/sounds/learn/                  # Board SFX (deal, stomp, fail sting, tick/tock)
assets/sounds/learn_voice/            # Coach + rival spoken lines (mono MP3 ≤ 48 kbps)
assets/duty_slip/dress/coach_*.webp   # One sprite per mood (see §7)
```

**Shared files — small diffs only** (several people edit them): `adventure_map.dart`, `ai_lineman_guide.dart`, `ladder_guide_host.dart`, `duty_slip_page.dart`, `ds_dress_up.dart`.

---

## 3. How a Learn Rung Opens

[`AdventureMap._openLearn`](lib/features/duty_slip/adventure_map.dart) is the only entry.

```
playable Learn rung
        │
        ▼
learnBoardPackFor(lessonId)   ← lib/features/game/learn_board_models.dart
        │
   ┌────┴────────────────────┐
   │ pack != null            │ pack == null
   ▼                         ▼
LearnBoardRunnerPage         LearnRunnerPage
(picture board, Learn 1.1) (cards + 2 quiz questions)
```

Both routes:

- Every exit goes through `_popOnce`. **After a pass the clear is saved first**; back / close then leaves with `pop(true)` (no exit sheet), and the ladder also unlocks when the save shows a new clear, whatever the route returned.
- **Level score, latest play counts.** Every ◆ won or lost in a Learn level flies into that level's score (the pill in the top bar, `BeatFx.levelDelta`; the main total sits small beside it). When the level ends — pass or fail — `GameSave.commitLevelScore(rungId, score)` replaces the level's previous score in the main ◆ (`levelScoreByRung`). Replays animate every time and can raise or lower the total, but can never farm it. Quitting mid-level commits nothing.
- A busy-lock ignores a second tap (double tap, হ্যাঁ then না) while an answer is handled.

1. Call `guideDirector.setLevelFocus(true)` so the ladder mascot stops talking.
2. `pop(true)` only when the player **passes** (≥ 60%, see §5). The ladder then `unlockThrough(index + 1)` and soft-scrolls to the next rung.
3. `pop(false)` on quit or fail-and-leave. Nothing unlocks.
4. Call `setLevelFocus(false)` on return. The next ladder entrance is a **comeback**, not a welcome (see §8).

`আবার খেলুন` on the fail panel **does not pop**. It remounts the run (`ValueKey(_round)`) so the ladder is still waiting for this route's result.

---

## 4. Learn Level Types

### 4.1 Picture board — `LearnBoardRunnerPage` (lesson 1.1)

Lesson 1.2 and every other Learn rung stay on the text deck. The first Do of lesson 1.1 is the dress-up game, not this board.

Beats, in order: `intro → pick → why` (repeat per slot) `→ mythSay → mythBelieve → mythWhy → award | fail`.

| Beat | What the player does |
|---|---|
| `intro` | Coach states the mission. Quiet history chip if they have played before. |
| `pick` | Choose the safe item from a dealt hand (usually 4 pictures). |
| `why` | Choose why that item is right (usually 3 chips). |
| `mythSay` | Scripted: coach warns, rival storms in, taunts, gets danger tags, leaves. Input locked. |
| `mythBelieve` | Yes / no: do you believe him? |
| `mythWhy` | Why his claim is wrong. |
| `award` | Pass: badge + time + mark, then optional end-of-level পাঠ card, then `pop(true)`. |
| fail | Below 60%: shared fail panel. No clear, no bonus, no lesson-complete. |

**Dealer** ([`LearnDealer`](lib/features/game/learn_board_deal.dart)):

- Each question key (`lessonId/slotId`, `…/why`, `myth/why`) deals **one correct + N−1 traps**.
- Prefers items not shown last time this session (`LearnDealer._recent`).
- After a miss: the tapped trap is replaced by an unseen trap; the **correct picture swaps to another correct picture of the same item** (so the player cannot memorise “the card on the left”); the hand reshuffles.
- A slot therefore needs **at least two correct pictures** of the same item (shirt / FR suit, helmet variants, …) plus enough traps.

Prototype pack: `learnBoardPack11` in `learn_board_models.dart`.

**Teaching rules** (keep them when adding packs):

- **No name on a picture until it is tapped.** The picture must show the cue (water drops, vent holes, shiny polyester); the label appears only on the tapped card. Art for a new trap must show its flaw.
- **The myth question is turned round on about half the runs** (`flipStingBn`: "সেটা কি ভুল?" — হ্যাঁ is right), so "always না" is never a free answer.
- **A right "why" is spoken back as the rule** (the chip text, recorded in the coach voice). A wrong myth-why says why not.
- **Weak spots are saved**: a question missed on the first try goes into `GameSave.weakByLesson[lessonId]` (keys: slot id, `<slot>/why`, `myth`, `myth/why`; text deck: question text). A clean answer later removes it. Recall side items should draw from here first.

```
shirt   3 correct pictures, 3 traps, 4 cards, 6 why chips (2 correct)
helmet  3 correct, 3 traps, 4 cards
boots   2 correct, 2 traps, 3 cards
gloves  3 correct, 5 traps, 4 cards
myth    6 why chips (2 correct)
```

To add the next picture lesson (e.g. 1.2):

1. Build a `const LearnBoardPack` in `learn_board_models.dart` (stable slot / option **ids**, never list indexes).
2. Return it from `learnBoardPackFor('1.2')`.
3. Put new trap art in `assets/` (decode at tile size; no READMEs/PSDs in `assets/`).
4. Add every new spoken line to `LearnFeedbackLines` / the pack (`rejectBn`, `tauntBn`, …).
5. Regenerate the voice pack (§7).
6. Add / extend `test/learn_board_deal_test.dart`. A new animated screen needs `test/perf/`.

### 4.1b Picture board — lesson 1.2 (ladder step 4, "লক্ষ্মণ রেখা")

`learnBoardPack12` (`learn_board_models.dart`), opened by `learnBoardPackFor('1.2')`. Four rounds, each saying its own situation (a slot's specific `promptBn` is spoken; a generic one rotates `LearnFeedbackLines.pickAsk`, as 1.1): **11 kV — where to stand** (≥ 2.5 m), **a long tool — its tip stays outside**, **rain on 11 kV** (10–12 ft, not the dry 8 ft), **which stick near a live wire** (fibreglass hot stick / operating rod; bamboo, PVC jugaad, wood, metal are traps). Then the rival's myth "আমি তো তারটা ছুঁচ্ছি না…" (না — arc flash; his line is a clip in his own voice). Art: vector scene cards from `tool/lakshman_art.py` → `assets/game/art/lakshman/` — the worker's height (≈ 1.7 m = 50 px) is the scale, so the gap is judged by eye with no numbers in the picture; `LearnBoardOption(scene: true)` shows a scene edge to edge (`_sceneTile`), objects stay on the pedestal; the board's cards accept `.svg`. Guide lines: device TTS for now. Tests: `test/learn_board_12_test.dart`, the deal test, the board perf test (1.1 and 1.2).

### 4.2 Text deck — `LearnRunnerPage` (every other playable lesson)

Phases: `load → cards → quiz → done`.

1. **Load.** `moduleLessonsProvider` + `LessonQuizStore.load`. No lesson points, or the quiz is `unavailable` (offline, never saved) → the Bangla offline dialog (retry / later → `pop(false)`). There is **no built-in deck** — never play or pass a lesson on made-up content. Quiz `noQuiz` (server has no file) → `learnQuizFromPoints`: two "which check belongs to this item?" questions from the lesson's own `daily_check` lines; with fewer than 3 checks the deck clears on its cards, as the reader does.
2. **Cards.** One swipe card per lesson point. Mascot reads a short field line (`conciseFieldRule`). Tap **কাজের আগে চেক করুন** → `+5 ◆` into the level score.
3. **Quiz.** `selectLearnExitQuestions` picks **2** questions. Right `+10 ◆`, wrong `−5 ◆` (level score, never below 0). The answer locks before any await, so a double tap counts once.
4. **Finish.** Mark = first-try-correct / 2. With only two questions, **one miss is 50% and fails**. First clear `+20 ◆`, replay clear `+5 ◆`. Then the end পাঠ card if it never appeared, then `pop(true)`.

Cards still award `◆`. The **lesson reader** (পাঠ) does not.

### 4.3 Shared Learn chrome

| | Picture board | Text deck |
|---|---|---|
| Top bar | `_LearnBoardChrome` | `UnifiedGameTopHud` + listen button |
| পাঠ pill | Yes (`ReadLessonPill`) | Yes |
| Clock | Counts **decision** time only; pause when the app is hidden; never ends the level | No level clock |
| Coach | Corner on the board; centre on intro / award / myth ask | Centre on cards / done |
| Retry after fail | Remount run | Remount run |

---

## 5. Pass Mark, History, Fail, পাঠ Offer

These apply to **both** Learn runners. Constant: `kLessonPassMark = 60` in [`level_result_parts.dart`](lib/features/game/level_result_parts.dart).

### 5.1 How the mark is counted

`LessonMarks`: share of **questions answered right on the first try**.

- Picture board: each pick, each why, the believe tap, and the myth-why are questions (`settle` when that question ends; `miss()` on a wrong tap).
- Text deck: each of the 2 quiz questions.
- A miss then a later right on the **same** question is **not** clean.

`GameSave.recordLevelResult(rungId, percent)` always runs (pass or fail): bumps `playsByRung`, keeps the best mark in `bestMarkByRung`. Progress ids are the **rung id** (`1.1/learn`), never a list index.

On a **pass** only: `markRungCleared`, clear bonus, `markLessonCompletedLocally` (board 1.1 writes both `'1_1'` and `'1.1'`).

### 5.2 History chip

`LevelHistoryChip` — one quiet line, only if `plays > 0`:

`আগে: সেরা 80% · 1:12 · 3 বার খেলেছেন`

Show it on the intro / first card, the award stage, and the fail panel. Do not add a second score box.

### 5.3 Fail panel

[`LevelFailPanel`](lib/features/game/level_result_parts.dart): drops, shakes, fills a meter that stops short of a green **পাস 60%** line, plays `sounds/learn/level_fail.wav`. Buttons:

- **আবার খেলুন** — remount the run.
- **পাঠটা পড়ুন** — open `LessonReaderPage`.
- **ফিরে যান** — `pop(false)`.

Must go **idle after one sequence** (`test/perf/level_fail_perf_test.dart`). No looping controller.

### 5.3b Day card ("প্রথম সপ্তাহ")

Lessons 1.1–1.5 are five workdays of a new helper (`lesson_day_card.dart`). Before a lesson's **first** play (rung not cleared), a scene card shows `দিন N · time · place` with one recorded coach line, for about 3 s or until tapped. Replays skip it. Add a day for a new lesson in `lessonDays`, then regenerate the voice pack. Ambient place sounds are planned once recordings exist (none in `assets/sounds/` yet).

### 5.3a Promise card (habit)

After a **pass**, `askLessonPromise` (`lesson_promise_card.dart`) shows the lesson's promise from `lesson_promises.dart` (one per lesson, written from that lesson's `daily_check`; lessons 1.1–1.5 so far) until it is made:

- **আমি করব** → saved in `GameSave.promises` by stable id, `+5 ◆` once ever (`promise_reward:<id>`).
- **এখনো না** → nothing lost; asked again on the next pass.
- When shown, it replaces the end-of-level পাঠ nudge (one end card at most).
- A later **death** in that lesson quotes it on the death screen: `আপনি কথা দিয়েছিলেন — “…”` (`DeathPulse.promiseBn`).

Add a promise for a new lesson in `lesson_promises.dart`, then regenerate the voice pack (§7). Never rename a shipped id.

### 5.4 Three wrong in a row → পাঠ card

[`LessonMissTally`](lib/features/game/read_lesson_offer.dart) is a **consecutive** streak per `lessonId`, kept across replays in this app session.

| Call | When |
|---|---|
| `miss(id)` | Every wrong pick / why / quiz tap. Returns `true` on the 3rd, 6th, … in a row. |
| `hit(id)` | Every right answer — **breaks the run**. |
| `read(id)` | Player opened the lesson — count restarts. |

The card flies out of the top-bar **পাঠ** pill and lands over the items (`ReadLessonFlyLayer`). **এখন না** tucks it back; the pill stays gold. Tapping the pill brings it out again.

If the card **never** appeared during the run, show it **after a passing result** and **before** `pop`, with a random [`ReadLessonNudges`](lib/features/game/read_lesson_offer.dart) title (আরও জানুন / জেনে রাখা ভালো / না জানলে বিপদ হতে পারে / …). The same title is not reused back-to-back for that lesson. Buttons then read **পরে পড়ব** / **পাঠ পড়ুন**.

The start-of-level offer (first play of 1.1, lesson not yet completed) still uses the original wording and **এখন না** / **শুরু করুন**.

---

## 6. Scoring Rules (Do Not Drift)

| Surface | Award | Never |
|---|---|---|
| Learn picture board | Level score: pending ◆ on a right pick, banked on a right why (`BeatFx.levelDelta`). Wrong: burn pending or `−5` (level score never below 0). Pass adds the pack `clearBonus` (20). At the end the level score replaces the last one in the main ◆ (`commitLevelScore`). | A fall. Closing on the clock. Adding to the main ◆ mid-level. |
| Learn text deck | Level score: card check `+5`, quiz `+10` / `−5`, pass `+20`; committed at the end like the board. | Same. |
| Lesson **reader** / seal | **No ◆.** Seal stamp + `completed_lessons` only. | Writing `profiles.points` or a second save key. |
| Do field drill | Habit `+5`, mistake `−5` into the play's score (`_flyDelta` → `_runScore`, never below 0). When the play ends (clear `+20`, lethal fall, or an unsafe field night) `_commitRun` → `commitLevelScore`: the latest play replaces the rung's last score. Leaving mid-level commits nothing. Ranks **দারুণ / মোটামুটি / আবার**. Clock never fails the level. | Adding to the main ◆ per action. `Offset.zero` as `originGlobal`. |
| Lethal Do / gate | `DeathMomentHost` → `💀 +1` → fall to the **module** checkpoint. | Fall to rung 0 of Module 1. Death on a Learn rung. |
| Side item | One reward per `station_<kind>@<rung id>` (old `station_<kind>_<index>` claims still honoured). | Pushing a legacy quiz / lesson shelf route. Keying by ladder index. |

`BeatFx.scoreDelta(ref, delta, rungId: …, originGlobal: tap, muted: …)` is the only animation entry. It updates `GameSave`, emits `ScorePulse`, and flies a chip into the HUD `◆`.

---

## 7. Voice, Lines, Mascot Sprites

### 7.1 Speak router

`MascotSpeechLibrary.speak(text, {voiceKey, muted, rival})`:

1. If `rival: false` and `DsVoice` has `voiceKey` or the exact text → play the Duty-Slip Bashkar MP3.
2. Else `LearnVoice.resolve(text, rival: …)` → play `assets/sounds/learn_voice/`.
3. Else `FlutterTts` `bn-IN` (device voice). **Avoid this for any fixed line** — it is a different person.

The rival must pass `rival: true` so he never borrows a coach clip. Live lesson-body text (server / neural read-aloud) still uses TTS / Edge; it cannot be pre-recorded.

### 7.2 Adding a spoken line

1. Put coach reactions in [`LearnFeedbackLines`](lib/features/game/learn_feedback_lines.dart) (pools are shuffle-bags; **ids are not saved**, so you may reorder).
2. Put one-off board lines in `LearnCoachLines`.
3. Pack-specific copy (`introBn`, `rejectBn`, `tauntBn`, `stingBn`, `exitBn`) lives on the pack.
4. Why / pick prompts already rotate (`whyAsk`, `mythWhyAsk`, `pickAsk`). Add there, do not hard-code a new prompt in the runner.
5. **Regenerate recordings** (coach = `bn-IN-BashkarNeural` rate `−1%` pitch `+0Hz`; rival = `bn-BD-PradeepNeural` rate `−6%` pitch `−14Hz`):

```bash
flutter test tool/dump_learn_voice_lines_test.dart   # writes tool/learn_voice_lines.json
python -I tool/make_learn_voice.py                   # fills assets/sounds/learn_voice/ + learn_voice_map.dart
python -I tool/check_asset_refs.py .                 # every new mp3 must be referenced
```

Do **not** hand-edit `learn_voice_map.dart` or `duty_slip_voice.dart`. Duty-Slip clips still come from `tool/update_duty_slip_voice_dart.py` / `tool/slm_game_voice_library.py`.

### 7.3 Coach sprites

`assets/duty_slip/dress/coach_*.webp` — same character, same scale, **no floor shadow, no white outline**.

| Mood | File |
|---|---|
| idle / listen / talk (quiet) | `coach_ready` |
| speaking | `coach_talk` (+ blink / glance overlays) |
| glad / celebrate | `coach_happy` (both arms up — must match the others) |
| warn / fright / fallen | `coach_oops` |
| sleep | `coach_blink` |

Celebrate **must not** use a mismatched raised-arm export. Source for a replacement: `tool/media_src/mascot/`. Mouth SVGs in `assets/guide/mascot/` overlay **only** on `coach_talk` while speaking.

Gate every looping controller with `slmSyncLoop`. Idle screens draw **zero frames**. Decode faces with `cacheHeight`.

---

## 8. Ladder Welcome vs Comeback

[`GuideDirector.beginLadderEntrance`](lib/features/guide/guide_director.dart):

| Situation | Kind | What the player sees |
|---|---|---|
| First open of this calendar day | `dailyWelcome` | Centre-stage welcome, then the dock. |
| First open of the **app session** later in the day | `hiPop` | Dock hi. |
| Return from a Learn / Do in the **same session** | `comeback` | Dock only. **No “স্বাগতম”.** |

Comeback copy ([`LadderComebackLines`](lib/features/guide/guide_director.dart)): if `rungProgress` gained a `cleared` since the last entrance → celebrate + spin-hop (“এক ধাপ উপরে! চলুন, পরেরটা।”). Else an encourage-retry line. `setLevelFocus` while a level is up stops idle nudges.

`DutySlipPage` **remounts** `AdventureMap` when a Do level ends (`onRoad` flips). That remount is why comeback must be session-aware — do not “fix” it by playing the daily welcome again.

---

## 8a. Level Shell and Do Games (new Do levels go here)

Every level is one rung of the catalog; a lesson has one Learn rung and **any number of Do rungs** (the catalog's `doSlotIds` decide: 1, 2, 4 …). The shell never assumes a count.

- **`LevelContext`** (`level_shell.dart`): `levelContextAt(ladder, index)` / `levelContextFor(ladder, rungId)` give lesson id and title, kind, ladder step, and for Do rungs `doIndex` / `doCount`. Its `chipBn` is the one header label: `পাঠ 1.1 · শেখা`, `পাঠ 1.1 · কাজ 1/2`, `র‍্যাঙ্ক গেট`. Never print the old `dsLevels` number.
- **`LevelShellBar`**: close · chip over title · level score pill (chips fly in) + `মোট` total · 💀 · mute. Same bar in Learn text levels and shell Do games; the legacy Do HUD shows the same chip and level score.
- **`LevelPassPanel`** (rank দারুণ / মোটামুটি / আবার, nম্বর, time, `এই কাজে ◆`, change to the total) and the shared `LevelFailPanel`.
- **Scoring**: `BeatFx.levelDelta` into the level score; at the end `commitLevelScore` (latest play counts). Pass mark 60 % first-try.
- **Do game registry** (`do_games.dart`): a game pack's `engineType` picks the game, its `id` the content. `doGameFor(pack)` returns a page builder, or null — then the ladder opens the old level from `legacyLevel`. The ladder's `_openRoute` opens Learn and shell Do games the same way (coach focus, unlock on a saved clear).

**Adding a Do level:** add content for an existing engine (e.g. a new `KitCheckPack` in `kitCheckPacks` keyed by the pack id), set the pack's `engineType` and `status: playable` in `content_catalog.json`, add its lines to the voice dump, run the voice pack, add tests. A new **engine** = a new page in the shell + a case in `doGameFor`.

**`kit_check`** (`kit_check.dart`, lesson 1.1 কাজ 1 — "কবচ যাচাই"): store-room scene ("সকাল 7টা · সাবস্টেশনের স্টোর রুম"), dress জামা → প্যান্ট → জুতো. **A fresh set every play** (`dealKit`): per slot one sound item, a damaged look-alike (always for shirt and boots, often trousers; flaws: grease, burn hole, torn sleeve, oil, nail in the sole, cracked sole — painted marks until photos exist, set `KitFlaw.inspectAsset`), and 1–2 wrong items from the pool; the pressure call (JE সাহেব on the phone, consumers outside, a co-worker) and its slot vary too. The tray shows pictures only, dealt like Level 1's cards. Tap → close-up → **পরে নিন** / **বাদ দিন**; the card **stays** with a stamp (ঠিক / বাতিল / ভুল) and the flaw pulsing while the coach reacts, then flies onto the body, out of the store, or shakes back. Reactions are one short word (shared `LearnFeedbackLines` pools); a reason is spoken only the first time (`SpokenOnce`), then shown as text in the coach strip. Result: rank, score, "আজ যা ধরলেন", and a "ঝটপট ও নির্ভুল" bonus for a clean run under `quickMs`. No deaths (yard). Placeholder scene: `bg_control_room.webp`.

**Mistakes, deaths and the fall (`mistake_kit.dart`, shared by every new Do level).** A mistake is a `DoMistake` (stable `key`, one Bangla line, a picture `art`, `deadly`, `lessonPoint`). `MistakeCard` shows the picture, the line and **পাঠে দেখুন** (`openLessonPoint` opens `LessonReaderPage(startPoint:)` at that lesson point; offline: a short note, never a spinner). `bookMistake` writes it into "আমার ভুলের খাতা" (`GameSave.mistakes`, one entry per key with a count, capped at 200). A deadly mistake ends the play: the game's **first** one is a near-miss (`GameSave.useNearMiss`: no death, no fall, "আবার চেষ্টা"); after that it is a death, recorded by `recordDoDeath` **when the level is left**, so the ladder's fall moment plays in view. **Fall option C:** `recordLethalDeath` turns every Do level/gate passed since the last death (`clearedSinceDeath`) from `cleared` to `prove`; Learn rungs stay done. The ladder's focus stops at the first `prove` rung and scrolls there after the death moment. A death play commits 0 to the level score; a near-miss keeps what was earned.

**`order_steps.dart` — the "order" move.** Steps come in `OrderGroup`s (any order inside a group, e.g. R/Y/B); touching a later step while a group is open is that group's `skipMistake` (or a target-specific one from `earlyBy`); `traps` are always wrong. `OrderRun` is pure logic (marks: 100 − 15 per slip, pass ≥ 55, no death).

**`discharge_order`** (`discharge_order.dart`, lesson 1.5 কাজ 2 — "আগে মাটি, পরে লাইন", rung `1.5/do/1`): a hand-drawn SVG pole scene (`assets/game/art/discharge/`, no text inside the art). Round 1 "লাগানো": clamp the rod's earth end to the sound earth point (a rusty one is the trap), touch R, Y, B with the hook (charged wires glow until a spark — `sounds/learn/spark.wav` — clears them), then throw the shorting chain. Round 2 "খোলা": chain and hook off in any order, earth clamp last. A pressure call ("লাইন তো ৫ মিনিট বন্ধ…") comes at a varying moment from a varying caller; "ঠিক আছে, সরাসরি উঠি" = skipping the discharge. Deadly: hook before earth, chain before earth (chain in place of the rod), giving in to the call. Slips: rusty earth, chain before all phases, earth off first. Each play varies the earth side, the call moment and the caller (`dealDischarge`). Voice: device TTS only.

**`DoDeathGuard`** (mixin in `mistake_kit.dart`): `bookDeadly(m, runScore:)` books near-miss or death and commits the level result; `dieAndLeave()` pops and records the pending death once; a page disposed any other way still records it. Every new Do page with deaths uses it.

**`rod_pick`** (`rod_pick.dart`, lesson 1.5 কাজ 1 — "সঠিক রড", rung `1.5/do/0`): a store rack (`assets/game/art/rod/store_rack.svg`) and a ডকেট slip (line voltage, feeder, শাটডাউন window). Rods are drawn in code (`RodPainter`: fibreglass stick, joints, red guard band, grip, copper cable, clamp — or the PVC jugaad with tape, thin wire and a crocodile clip), each with its printed label (`LT 440V` / `11 kV` / `33 kV`). Tap a rod → close look → **এটাই নিন** / **ফেরত রাখুন**. Three dockets: easy (11 kV or LT), 33 kV with a damaged twin, and a last one where nothing fits while the store-keeper says "নিয়ে যাও, চলবে" — the right move is **কোনোটাই ঠিক নয় — কাজ স্থগিত**. Deadly: a rod rated below the line, the jugaad. Slips: a cracked stick / cut cable / rusty clamp (the rod is stamped বাতিল), holding the job when the right rod was there. Never deals a rod rated above the line.

**`distance_spot`** (`distance_spot.dart`, lesson 1.2 কাজ 1 — "কতটা দূরে?", rung `1.2/do/0`): a street seen from the side (`assets/game/art/distance/street_side.svg`), the live wire 8.25 m up, drawn to scale (40 px per metre) with a man-height ruler (two 1.7 m men) hanging from the wire. People on a ladder, on a roof, with a long pole, a truck's boom — their highest point (hand or tool tip) at a dealt gap below the wire, never within 0.25 m of the edge. Tap everyone inside the লক্ষ্মণ রেখা, then **যাচাই করুন**: the danger band lights up with the rule (LT 1.2 m · 11 kV 2.5 m · 33 kV 3.0 m; in rain 11 kV 3.5 m) and each figure gets ✓/✗. Streets: LT dry; 11/33 kV dry with a long tool's tip inside; 11 kV in rain with one figure safe on a dry day but inside now. Deadly: someone left inside (reason: body / tool tip / rain). Slip: stopping someone outside. `StreetGeo`, `paintWireAndRuler`, `distanceFor` are shared.

**`tool_tip`** (`tool_tip.dart`, lesson 1.2 কাজ 2 — "লম্বা টুলের ডগা", rung `1.2/do/1`): a kite caught in a tree near the wire. Pick the tool from three picture cards (tested fibreglass hot stick; dry bamboo; PVC pipe with a metal hook — drawn in code), once under the helper's push "শুকনো বাঁশ তো, চলবে". Then **ডগা দিয়ে সরাই** or **শাটডাউন চাই**: the tip must stay outside the band, so a kite inside means shutdown. The band shows after the decision. Each voltage once; at least one kite inside and one outside. Deadly: bamboo, PVC, reaching a kite inside. Slip: a shutdown that was not needed.

**`pole_read`** (`pole_read.dart`, lesson 1.3 — packs `do_1_3_a` "৩৬০° পোল পাঠ" (PCC) and `do_1_3_b` "স্টিলের ক্যান্সার" (steel)): four poles a play on a village road (`assets/game/art/pole/village_road.svg`); the pole and its faults are drawn in code (`PolePainter`). Tools: **ঘুরে দেখুন** (front / back — side faults show on one side only), tap base / waist / top for a 2.6× magnifier, **ঠুকে দেখুন** (new knock sounds `sounds/learn/knock_solid|knock_hollow|ring_steel|dull_steel.wav`: PCC "ঠক্" vs hollow "দপ্"; steel "টন" vs dull). Habit chips চারপাশ · গোড়া · শব্দ · ওপর tick as done. Decide **উঠব** / **উঠব না — রিপোর্ট**; the fault is then ringed and named. PCC faults: hairline crack, spalling + rebar, eroded base with water, lean, hollow (heard only), broken insulator, bent cross-arm. Steel: rust at ground level, rust at the weld joint, bent, hardware. Deadly: climbing a condemned pole. Slips: climbing a sound pole without walking round, looking at the base and tapping; reporting a sound pole. Pressure on the headline-fault pole: "চুলের মতো ফাটল তো থাকেই" / "স্টিলের পোল শুধু বাঁকে, ভাঙে না".

**`harness_check`** (`harness_check.dart`, lesson 1.4 কাজ 1 — "তিন মিনিটের পরীক্ষা", rung `1.4/do/0`): four harnesses on a store hook (`assets/game/art/harness/store_wall.svg`; harness drawn in code): the waist belt, one sound full body harness, two damaged. Four checks: **ফিতে** (drag a fingertip along the webbing — the phone buzzes and the spot is ringed at a cut / burn / chemical stain; a fast swipe still finds it), **সেলাই**, **ধাতু** (D-ring and buckle), **লেবেল** (made / expiry month against "আজ" — real dates; `today:` is injectable for tests). Then **পরব** / **বাতিল**. Push on a damaged one: "পুরনো হলেও মজবুত লাগছে". Deadly: wearing the waist belt, damaged webbing, open stitching, cracked / rusted metal, an expired label. Slips: wearing the sound harness without all four checks; rejecting it.

**`harness_fit`** (`harness_fit.dart`, lesson 1.4 কাজ 2 — "ফিটিং আর অ্যাঙ্কর", rung `1.4/do/1`): three climbs. Fit: a lineman in his harness, front / back (**ঘুরিয়ে দেখুন**) — tap what is wrong (twisted shoulder strap, chest strap at the neck, loose leg strap with a hand showing more than four fingers, back D-ring low — back only), then **যাচাই করুন**; one round is clean, the D-ring fault comes once. Anchor: the pole top from the climber's eye — the sling around the pole body is the only strong point; cracked cross-arm, insulator pin and cable clamp are dealt as weak points. Push before one anchor: "২০ বছর কাজ করছি, হারনেস লাগে না". Deadly: a weak anchor, giving in (no tie-off). Slips: a fit fault missed, a strap marked that was fine. `DoBigButton(onDark: true)` is the outline button for dark pages.

**`ptw_match`** (`ptw_match.dart`, lesson 1.6 কাজ 1 — "কাগজ মেলাও", rung `1.6/do/0`): four rounds at a site strip (`assets/game/art/ptw/site_desk.svg` + chips: the pole's feeder tag, pole number, "আপনি", the time now and today). Three permit forms built from widgets (number, feeder, pole range, job, name, date, time window, control-room signature) — one valid, two with one fault each — and one phone call with no paper ("লাইন বন্ধ, কাজ শুরু করো — কাগজ পরে পাঠাচ্ছি"). Tap the field that does not match, then **মেলে না — বন্ধ**; or **মিলেছে — শুরু**. Deadly: starting on the phone's word, on another feeder's permit, on an unsigned or an expired permit. Slips: starting with the wrong pole range / another person's name; stopping a valid permit; flagging the wrong field.

**`ptw_steps`** (`ptw_steps.dart`, lesson 1.6 কাজ 2 — "সোনালি ধাপ", rung `1.6/do/1`): the "order" move (`OrderRun`) with step cards — numbered slots fill as the right next card is tapped; the tray order varies. Round 1: অনুরোধ → আইসোলেশন (LOTO) → অনুমোদন → গ্রহণ → যাচাই (discharge & test) → কাজ শুরু. Round 2 (line clear): দল গোনা → যন্ত্র সরানো → লাইন ক্লিয়ার → পারমিট বাতিল → LOTO খোলা. Deadly: "কাজ শুরু" before the permit is issued, or before the test. Slips: any other step out of order (line clear before counting the team has its own card).

**`shock_rescue`** (`shock_rescue.dart`, lesson 1.7 কাজ 1 — "ছোঁবেন না!", rung `1.7/do/0`): three scenes (house / pump room with a switch or starter at hand; field / roadside with none — `assets/game/art/shock/scene_*.svg`), a colleague stuck to a live wire drawn in code with a static spark, and a whole-second countdown (`ValueNotifier` — only the timer chip rebuilds). First action: switch the source off where it is at hand; otherwise **শুকনো কিছু দিয়ে আলাদা করি** → pick from four object pictures (dry bamboo / plastic chair / dry plank vs wet stick / iron rod / aluminium ladder) → tap the arm or leg. Deadly: grabbing his hand or shirt, a wet or metal object. Slips: separating when the switch was at hand, pushing the chest or head, the countdown running out.

**`golden_minute`** (`golden_minute.dart`, lesson 1.7 কাজ 2 — "গোল্ডেন মিনিট", rung `1.7/do/1`): step cards (shared `StepSlot` / `StepTrayCard` from `ptw_steps.dart`): সাড়া দেখা → শ্বাস দেখা → অ্যাম্বুলেন্স ডাকা → CPR শুরু → চালিয়ে যাওয়া; then three of four crowd myths, each answered "না…": bury in mud, ice on burns, "talking, no hospital", "LT shock is nothing". No deaths (owner's list: wrong order costs points); every slip has its card.

**`fire_choose`** (`fire_choose.dart`, lesson 1.8 কাজ 1 — "কোন আগুনে কী", rung `1.8/do/0`): three fires in the yard (`assets/game/art/fire/yard.svg`; `FireScenePainter` draws still flames): transformer oil (B), panel (C — first **নিরাপদ হলে আগে পাওয়ার বন্ধ**), dry grass (A). Tools (pictures + names): water bucket, DCP, CO2, sand bucket — oil: DCP / CO2 / sand; electrical: CO2 / DCP; grass: DCP / water. Picking an extinguisher shows its gauge; one per play is empty (red). Push once: "ছোট আগুন, নিজেই নিভবে". Deadly: water on oil or electrical. Slips: wrong tool, no power-off, using the empty one, waiting. Hands-on (Lottie, `fire_fx.dart`): the fire and smoke are Lottie loops sized by the fire left; after a full extinguisher, hold **চেপে ধরুন** to spray (DCP cloud / CO2 jet from the nozzle to the base) until the fire is gone — a short squeeze is not enough; sand and water are thrown from a tipped bucket; the empty one coughs a weak puff; out → rescue bloom; water on oil / the panel → the fire leaps up in colour over the frozen grey scene.

**Step 23 flow (2026-11-08, level 1 style)**: the guide is always the app's own mascot (`AiLinemanGuide`) — never a new character. `GuideIntro` first — the mascot full screen with the alarm bell (`assets/sounds/learn/fire_alarm.wav`) says only the fire and "now" (`FireLines.alarmFirst`); no pointing tour. The scene then fills the whole screen, top to bottom, under a floating header (`LevelShellBar(bare: true)`, no bar, as level 1) (design 360 wide, height from the screen; `lift` lowers the yard so a tall screen gets more sky). The mascot stays bottom-right with short lines in its own bubble (the next task only). Panel fire: an isolator shows ON (red lamp, arcing); tap or pull it down (`_power`); a tool grabbed while ON is a slip and the switch must still go off (`FireRun.grabLive`; water while live is deadly). Fire out → its ◆ wait on the table → "কেন এটা নিলেন?" (panel: "কেন আগে সুইচ বন্ধ করলেন?") with 3 reason cards (`FireLines.why`); right pays the table, wrong burns it, a right retry pays 5 (`whyPayout`, level 1's rule; not a strike); then the camera walks on by itself. The powder extinguisher is "ABC পাউডার" (IS 2190:2010 cl. 10.1 — Class A: water, foam, ABC powder; CO2 not suitable for A).

**Shared level kit (Phase A, 2026-11-08)** — every Do level builds on these, step 23 is the first user: `FullSceneFrame` (`full_scene_frame.dart`: edge-to-edge scene under the bar-less header, top shade, `SceneMetrics` height/lift/inset, page overlays; `cornerGuide` puts the mascot in a corner with tap-to-repeat); `ReasonTable` mixin (`reason_table.dart`: `putOnTable` → `askReason(deal:, question:)` → `reasonDeck` / `tableLayers`; hooks `reasonSay`, `reasonScore`, `onReasonPaid` …; `whyPayout`); `CoworkerMoment` mixin (`coworker_moment.dart`: `CoworkerScript` lines + option libraries, `scheduleCoworker`, hook `coworkerCanCome` (true / false = later / null = too late), `onCoworkerAnswer`, `coworkerDeck`, `coworkerPeek`, `coworkerSnarl`, `answerCoworker(direct:)` for refusing by going on working). Tests: `test/support/option_lengths.dart`.

**Answer deck — `ChoiceDeck` (`choice_deck.dart`, any level)**: level 1's card motion as a shared widget — a dark sheet rises, numbered cards slide in from the right one after another (card-deal sounds), press under the finger, a wrong one shakes red, the right one pops green. `dealChoices(right, wrong, rng)` deals one right and two wrong from option libraries so plays don't repeat. Step 23 uses it for the coworker choice (`FireLines.choiceRight` / `choiceWrong`) and the reason (`FireLines.whyRight(kind, toolUsed)` / `whyWrong(kind)`); a test keeps every set within 1.3× length so the right one can't be spotted by length. Key every child of a Stack that comes and goes (here the bottom layers): unkeyed `Positioned` siblings are matched by position and a removed one makes the next ones rebuild from scratch.

**Level 1's concept on every level (2026-11-08)**: the guide's opening (`LevelIntro`, `GuideIntro`, `GuidedTour`) has no "শুরু" button and cannot be skipped — the game begins once the guide has said the task (voice + reading time). Tap the guide: he says the current task again, a different way each time, never the answer — `DoCoachStrip(tasks: XLines.tasks, muted: …)` (each Do level's `static const tasks` = its ask lines; `TaskNudge` rotates the phrasing), and step 23's corner mascot (`FireLines.tap*` pools). Voice: device TTS for the guide's new lines (for now). Tests wait for the opening with `test/support/intro_wait.dart`.

**Step 23 pressure moment (2026-11-08)**: the shopkeeper's call card is gone. Once per play, at the push fire, 1.2–2.4 s after the fire is seen, the careless coworker — level 1's rival, same art (`assets/duty_slip/dress/myth_rival_bad.webp`) and puppet (`MythRivalPuppet`) — peeps round the left or right edge (random) — leaning in from behind the side, head and shoulders in view — and says `FireLines.coworkerLine` in his recorded voice (rival clips `r_a4b3e32d45.mp3`, `r_95012c7c49.mp3`, made with the level 1 rival voice settings of `tool/make_learn_voice.py`; the lines are in the voice dump so a regeneration keeps them). Then the guide mascot puts the choice to the player (`FireLines.choiceAsk`, rotating) and the answers show beside him. "এখনই নেভাই" — or simply taking a tool / pulling the switch — refuses him (+10, he flinches and leaves, "হুঁ! যা খুশি করুন।"); "ওর কথা শুনি" is the `waited` slip. Widget: `CoworkerPeek` in `fire_choose.dart`.

**Scene kit — pilot on step 23** (`scene_kit.dart`, `fire_world.dart`): the level is a place, not a page. `FireWorldPainter` draws layered scenery for a 1000-wide world seen through the 360 x 420 camera — sky with drifting clouds, far village / palms / tower (parallax 0.35), yard with fence, gantry, overhead line, transformer, feeder panel (breaker handle + lamp show power on/off; arc crackles while live), pole with dry grass (parallax 1). The camera pans (1.3 s, slight zoom-in) from fire to fire (`FireWorld.cameraFor`). `LinemanFigure` is an original rigged field worker (the trainee only: yellow helmet + gloves; the guide stays the mascot) with blended poses idle / talk / point / worried / cheer / walk / hold / spray (with sweep) / throwIt; `LinemanFigure.tipOf` gives the nozzle or bucket mouth for aiming effects. The tools hang on a red fire-point stand in the scene (`RackToolPainter`) instead of a tray. Every clock (`AwakeClock`, figures, `FxLoop`) runs only for a few seconds after a change, so idle screens draw nothing. Scoring, saves, mistakes and cards are untouched — only presentation.

**Lottie motion** (`fire_fx.dart`, `tool/lottie_gen.py` → `assets/game/anim/*.json`): the animations are generated vector JSON (gradient shapes, 24 fps) — run `python -I tool/lottie_gen.py .` after editing the script. `FxLoop` plays a loop at 24 fps from a timer only for `kFxAwake` (5 s) after each wake (bump `wake` on every move), then holds a still frame — idle screens draw nothing. `FxOnce` plays a one-shot; `FxBeam` lays a left→right stream between two scene points (`thick` widens short beams). Reduce-motion: still frames, one-shots end at once.

**`fire_pass`** (`fire_pass.dart`, lesson 1.8 কাজ 2 — "PASS", rung `1.8/do/1`; rebuilt 2026-11-08 on the shared kit): `GuideIntro` first; the step 23 yard full screen (`FullSceneFrame`, camera pans between the two fires; fires drawn smaller, `PassStage.fireAt`). The wind shows (`_WindPainter`: a windsock pointing downwind, streaks; the smoke drifts downwind) and a brick wall sits behind one upwind place. Where to stand: three places on the ground (`PassStage.spotX`: upwind open = right, upwind against the wall = cornered, downwind in the smoke). PASS with the hands (`_PassPanel`): drag the pin's ring out (P), tap the fire's base, not the flames (A), hold the handle (S) and slide side to side (S — only a moving jet puts it out); out of order (handle with the pin in, aim before the pin) is the `order` slip via `OrderRun`. Fire out → its ◆ on the table → reason deck (first fire: where you stood; second: the aim; `ReasonTable`). At the end the careless coworker peeps in: "অর্ধেকটা তো বাকি — রেখে দাও" (`CoworkerMoment`, clip in his voice); refill is right. Points unchanged (the fire-out +10 waits on the table). No deaths; slips only.

**"আমার ভুলের খাতা"** (`mistakes_book.dart`): opened by tapping the 💀 chip on the ladder. Newest first, lesson, day, count, picture (`knownMistakes`: add every new level's mistakes there), "পাঠে দেখুন", and a মারাত্মক filter. On the ladder, a rung to prove again (fall option C) shows as a silver coin with a ↻ badge.

## 9. Do Field Levels (summary)

Full visual / speech specs: [`GAME_LEVELS_GUIDE.md`](lib/features/duty_slip/GAME_LEVELS_GUIDE.md). Live code:

| Levels | File |
|---|---|
| 1–10 dress / van | `ds_dress_up.dart` |
| 11–13 pole language | `ds_pole_inspect.dart` |
| 14 clearance | `ds_clearance.dart` |
| 15–22 SAFE HOME cards | `duty_slip_page.dart` |
| 23–32 23-step job | `duty_slip_page.dart` |
| 33 field night | `duty_slip_page.dart` |

Do rules that Learn must not copy: picture-only trays, no back arrow on the work screen, `ZlFx.holdClock()` / `releaseClock()`, ranks দারুণ / মোটামুটি / আবার, lethal mistakes may kill.

---

## 10. Workflows

### A. New mascot cue

Add `MascotCueId` + pool entry in `mascot_speech_library.dart`. Speak with `guideDirector.sayCue(..., speakVoice: true, muted: …)` or `MascotSpeechLibrary.speak`. Then regenerate the Learn voice pack if the line is new.

### B. New picture Learn pack

See §4.1. Register in `learnBoardPackFor`. Stable ids. Two+ correct pictures per item. Voice dump + `make_learn_voice.py`. Perf test if you add a new animated overlay.

### C. New text-quiz lesson

No runner change. The catalog lesson + `questions_M_C.json` (or the offline fallback) is enough. If the quiz cannot load, **do not** mark complete.

### D. New Do level (15+)

Follow [`GAME_LEVEL_PLAYBOOK.md`](GAME_LEVEL_PLAYBOOK.md) — all of it, §0 first (the legacy `lib/features/duty_slip/GAME_LEVELS_GUIDE.md` is only for old `dsLevels` screens). New Do levels go in the level shell (§8a: a page + a case in `doGameFor`); the reference level is step 23 (`fire_choose.dart`). Do not resurrect deleted Zero-Loss screens.

### E. Side items

`_openStation` → `_SideChallengeOverlay` over the ladder. Content from `MascotSpeechLibrary.challengeForSideItem`. Never push `QuizPlayScreen` / `IdentifyQuizScreen` / a lesson shelf.

---

## 11. Tests You Must Keep Green

```bash
flutter analyze
flutter test
python -I tool/check_asset_refs.py .     # on Windows: python -I …
```

Learn-specific:

| File | Guards |
|---|---|
| `test/learn_board_deal_test.dart` | Deal + after-miss swap of the correct picture |
| `test/lesson_miss_tally_test.dart` | Consecutive-3 offer; `hit` breaks the run; nudges do not repeat |
| `test/level_result_test.dart` | 60% mark; `recordLevelResult`; end-card wording |
| `test/game_save_best_time_test.dart` | Best time |
| `test/perf/level_fail_perf_test.dart` | Fail panel settles, then **zero frames** |
| `test/perf/lesson_seal_perf_test.dart` | Seal stamps once, then idle |
| `test/perf/learn_board_perf_test.dart` | Board: day card first, no 60 fps loop while waiting, no item names before a tap (with and without remove-animations) |
| `test/learn_runner_offline_test.dart` | Text deck offline: honest dialog after the 12 s lesson timeout, no made-up deck, no clear, no ◆ |
| `test/learn_fixes_test.dart` | Latest-play scoring, weak spots, promises, Module 1 Do routing, questions built from lesson data |

If a perf guard fails, **fix the widget**, not the test, unless the design really changed — then say why in the same commit.

---

## 12. Roadmap

### Done
- [x] Catalog + ladder builder; unified HUD + flying `◆`.
- [x] One mascot + lip-sync + speech library.
- [x] Picture Learn 1.1 (dealer, myth rival, পাঠ offer, 60% pass, fail panel, history, voice pack).
- [x] Text Learn for the other playable lessons (same পাঠ / pass / fail / history).
- [x] Lesson reader without scoring; seal win; Training Zone in the toolbox.
- [x] Comeback line instead of re-welcoming after a level.
- [x] Do 1–14 live.

### Next
- [ ] JSON Learn packs per lesson + `tool/check_learn_packs.py` + a Learn-board perf test.
- [ ] More trap / correct-item art.
- [ ] Catalog `engineType` router for Do scenes.
- [ ] Rank-gate boss scenes; promise recall on the fall screen.
- [ ] Do 15–31 as specified in `GAME_LEVELS_GUIDE.md`.

---

## 13. Pre-commit Checklist

1. `git pull` first. Never force-push.
2. Bangla edited in the IDE / `Write` / `StrReplace` — **never** PowerShell `Set-Content`.
3. Visible numbers through `enDigits()`.
4. Points only via `BeatFx.scoreDelta` / `GameSave.addPoints`. Lesson reader still awards **zero** `◆`.
5. Save by stable id (`1.2/learn`, lesson id), never by list index.
6. One mascot; fixed lines recorded (dump + `make_learn_voice.py`); rival uses `rival: true`.
7. No whole-screen `AnimatedBuilder`, no ungated `..repeat()` (use `slmSyncLoop`). Images decoded at display size.
8. New animated screen → `test/perf/` that settles to zero frames.
9. `flutter analyze` (0 errors, no new warnings), `flutter test`, `python -I tool/check_asset_refs.py .`.
10. No secrets (`key.properties`, service-role keys, `tool/hourly_answer_keys*`).
