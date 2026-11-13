# GAME_DEVELOPER_GUIDE.md — মৃত্যুহীন পথ (the Zero-Death Path), developer guide

> **For every agent and developer who touches the game.** It says where things are, how a level is wired,
> and what must stay green. Read in this order:
> 1. [AGENTS.md](AGENTS.md) — repo rules (secrets, Bangla UTF-8, git, green before push).
> 2. [GAME_LEVEL_PLAYBOOK.md](GAME_LEVEL_PLAYBOOK.md) — **how a level must play** (the owner-approved level-1 concept). It wins over old code.
> 3. This guide — code, wiring, tests.
> 4. [GAME_PATH_CHECKLIST.md](GAME_PATH_CHECKLIST.md) — what is built, what is next (update it with every level).
> 5. [MODULE1_LADDER.md](MODULE1_LADDER.md) — Module 1's rung-by-rung design notes and deadly lists.
> 6. [LADDER_VOICE_SCRIPTS.md](LADDER_VOICE_SCRIPTS.md) — master speech scripts and ledger for guide & coworker voice generation.
>
> Product intent: [GAME_DESIGN.md](GAME_DESIGN.md). Motion and brand: [lib/design/MOTION.md](lib/design/MOTION.md).
> Legacy `dsLevels` screens only: [lib/features/duty_slip/GAME_LEVELS_GUIDE.md](lib/features/duty_slip/GAME_LEVELS_GUIDE.md).

---

## 1. Rules that never change

1. **One climb.** Learn (শেখা) and Do (কাজ) are rungs of one ladder per module, ending in a rank gate. The full lesson (পাঠ) is an offer, never the level itself, and reading it awards **no ◆**.
2. **One score (◆), one death count (💀).** Points only through `BeatFx.levelDelta` / `BeatFx.scoreDelta` and `GameSave`; at the end of a play `commitLevelScore` replaces the rung's last score (latest play counts). The clock never closes a level.
3. **Never change point values, the pass mark or strike rules** without the owner's explicit yes. Learn pass = 60 % first-try (`kLessonPassMark`); Do = 100 − 15 per slip, pass ≥ 55, 3 slips strike out.
4. **Content only from the lesson** (`tool/all_training_chapters_bn.json`) **and standards.** Never invent a fact, distance, rating or procedure; flag it to the owner instead.
5. **One guide (the existing mascot, `AiLinemanGuide`)** and **one antagonist (level 1's careless lineman / rival)**. No new characters.
6. **Field Bangla.** Locked words ডকেট · শাটডাউন · জল · গ্লাভস; digits always `0–9` via `enDigits()`; animate Bangla by word.
7. **Idle screens draw zero frames.** Every animated screen has a perf test.
8. **Save by stable id** (`1.3/do/0`, lesson id, mistake key), never by list index.

---

## 2. File map

```
lib/
├── main.dart                       # IntroGate(warmUp:) over MainShell; FLUTTER_TEST disables the intro
├── core/startup/startup_warmup.dart# warmUpDuringIntro: catalog, lessons, TTS, sound slots, coins
├── features/startup/brand_intro.dart # the vector brand intro (BrandIntroPainter, BrandLogo, IntroSound)
└── features/game/
    ├── content_catalog.dart / ladder_builder.dart   # catalog JSON → rungs → ladder
    ├── level_shell.dart            # LevelContext (levelContextAt/For), LevelShellBar, pass/fail panels
    ├── do_games.dart               # engineType → Do page (doGameFor); null = legacy level
    ├── game_save.dart              # ◆, 💀, rungProgress, bestTime/Mark, plays, mistakes, promises
    ├── beat_fx.dart                # HUD + flying ◆ (ScoreFlyHost) + DeathMomentHost
    │
    ├── # ---- the shared level kit (every level builds on these) ----
    ├── full_scene_frame.dart       # FullSceneFrame, SceneMetrics, cornerGuide, praise-window input shield, scene hint host
    ├── gesture_hint.dart           # IdleHint, HintSpec, GestureHints, IdleHintController (the "how to touch" hand)
    ├── scene_kit.dart              # GuideIntro, LinemanFigure (poses, tipOf), AwakeClock
    ├── reason_table.dart           # ReasonTable mixin: putOnTable → askReason → zoom + এগিয়ে যান → paid
    ├── coworker_moment.dart        # CoworkerMoment mixin, CoworkerScript, CoworkerPeek (two-beat UI)
    ├── choice_deck.dart            # ChoiceDeck + dealChoices; CardPreview, CardPreviewOverlay, CardAside (two-step pick)
    ├── do_parts.dart               # TaskNudge, DoCoachStrip, DoProgress, DoBigButton
    ├── mistake_kit.dart            # DoMistake, MistakeCard, bookMistake, DoDeathGuard
    ├── level_frame.dart            # DoStrikeOut, StruckOutCard, LevelIntro
    ├── level_juice.dart            # FreezeFrame, freezeFilter, Combo
    ├── order_steps.dart            # OrderRun / OrderGroup (the "order" move, pure logic)
    ├── fire_fx.dart                # Lottie FxLoop / FxOnce / FxBeam (tool/lottie_gen.py)
    │
    ├── # ---- picture boards (শেখা) ----
    ├── learn_explainer_videos.dart # YouTube id catalog per lessonId (null = skip gate)
    ├── learn_video_gate.dart       # guide → YouTube → portrait → guide → board
    ├── learn_board_models.dart     # LearnBoardPack types, learnBoardPackFor(), exports
    ├── learn_board_pack*.dart      # one file per lesson board (M1–M4)
    ├── learn_board_runner.dart     # LearnBoardRunnerPage (the board player)
    ├── learn_board_deal.dart       # LearnDealer (deal, swap after a miss)
    ├── learn_runner.dart           # LearnRunnerPage (text deck, lessons without a board)
    │
    ├── # ---- Do levels: one engine file (+ a scene painter file) per level ----
    ├── kit_check / glove_check / helmet_check / distance_spot / tool_tip / pole_read
    ├── harness_check / harness_fit / rod_pick / discharge_order / ptw_match / ptw_steps
    ├── shock_rescue / golden_minute / fire_choose / fire_pass / sky_read / storm_push
    ├── ten_sec_scan / gate_watch                         # step 29 Do · step 30 rank gate
    ├── store_room, van_yard, pole_yard, harness_store, rod_van, ptw_site, ptw_yard,
    │   shock_scene, golden_field, fire_world, sky_world   # drawn full-scene painters
    │
    ├── mistakes_book.dart          # "আমার ভুলের খাতা" (knownMistakes: add every level's mistakes)
    ├── learn_voice.dart / learn_voice_map.dart   # recorded clips (map is GENERATED, see §7)
    └── lesson_day_card.dart / lesson_promises.dart / read_lesson_offer.dart / level_result_parts.dart

assets/game/catalog/content_catalog.json   # modules, lessons, rungDefs, gamePacks (engineType, status)
assets/game/art/<topic>/                    # level art (SVG); boards: <topic>_board/
assets/sounds/learn/ · assets/sounds/learn_voice/   # SFX · recorded lines (r_*.mp3 = rival)
tool/*_board_art.py                         # SVG generators for the boards
tool/rival_clip.py                          # one clip in the rival's voice + registers it
tool/dump_learn_voice_lines_test.dart       # lists every recorded line (keeps clips alive)
tool/check_asset_refs.py                    # every asset referenced exists; no unused assets
```

Shared files — small diffs, one owner at a time: `learn_board_models.dart`, `do_games.dart`, `mistakes_book.dart`,
`content_catalog.json`, `learn_voice_map.dart`, `tool/dump_learn_voice_lines_test.dart`, `pubspec.yaml`, the `*.md` docs,
and the kit files above.

---

## 3. How a rung opens

- The catalog (`content_catalog.json`) defines every rung (`rungDefs`: id, kind learn/do/gate, lessonId, packId, **status**) and every pack (`gamePacks`: id, **engineType**, **status**, optional `legacyLevel`). A rung shows as playable only when **both** its rung and its pack are `playable`.
- **শেখা:** `AdventureMap._openLearn` → `learnBoardPackFor(lessonId)` + `LearnExplainerVideos.youtubeIdFor(lessonId)`:
  - pack + YouTube id → `LearnVideoGatePage` (guide → video → portrait → guide → board);
  - pack, no video → `LearnBoardRunnerPage`;
  - no pack → `LearnRunnerPage` (text deck).
  Fill the next lesson's id in `learn_explainer_videos.dart` only — no other open-path change.
- **কাজ / gate:** `doGameFor(pack)` (`do_games.dart`) switches on `engineType` and looks the content up by pack id (e.g. `poleReadPacks['do_1_3_a']`, `gateFieldPacks['gate_m1']`) → a page builder `(ctx, muted) => XxxPage(…)`. If the pack already names a real shell engine but the builder is missing, the ladder shows Coming Soon — it must **not** open `legacyLevel`. Only packs with `engineType: placeholder` (or no engine) may use the old `dsLevels` bridge.
- `LevelContext` gives lesson id/title, kind, ladder step, `doIndex/doCount`; `chipBn` is the only header label. Lesson numbers are never shown on screen in a level.
- After a pass the clear is saved first; the ladder unlocks on the saved clear. Retry remounts the run (`ValueKey(_round)`), never pops.

---

## 4. The shared level kit

| Need | Use |
|---|---|
| Guide first (one urgent line, no start button, tap does not skip) | `GuideIntro` (`scene_kit.dart`) |
| Edge-to-edge scene under a floating header; tall phones get more sky | `FullSceneFrame` + `SceneMetrics` (height, lift, inset) |
| Guide in a corner, tap = the task again in other words, never the answer | `cornerGuide` + `TaskNudge` (or `DoCoachStrip(tasks:)`) |
| The player's worker | `LinemanFigure(look: LinemanLook.trainee)` (idle, walk, hold, spray, throwIt, cheer, worried; `tipOf`) |
| Right action → ◆ waits on the table → "কেন …?" → zoom + **এগিয়ে যান** → paid → next | `ReasonTable` mixin: `putOnTable(n)`, `askReason(…)`, `reasonDeck`, `proceedReason`, `tableLayers`, `whyPayout` — tests must tap `reason-proceed-btn`. **Praise window:** from `putOnTable` until the deck opens, `tableHolding` is true and `FullSceneFrame` shields the scene and overlays by itself (header close/mute stay live); `tableBusy` = `tableHolding \|\| reasonOpen` — add `!tableBusy` to the level's `_canPlay` so no handler can score twice or slip in that window |
| Any 3-card choice | `ChoiceDeck` + `dealChoices(right, wrong, rng)` (libraries ≥ 2 right, ≥ 5 wrong, all within 1.3× length). **Two steps** (playbook §1.4): a tap opens the card big (`CardPreview`: full text, ✕ **বাদ দিন** key `choice-reject`, ✓ **বেছে নিন** key `choice-confirm`, the same for every card); the buttons ignore taps for `ChoiceDeck.armDelay` (300 ms); only ✓ calls `onPick`; ✕ sets the card aside (dimmed, struck, grey; reopenable). Words in `ChoiceDeckLines` |
| A level's own multi-option picker (chips, team buttons, knob positions, step cards, quiz rows — not a `ChoiceDeck`) | Same two steps with `CardPreviewOverlay(textBn:, icon: / index: / art:, quiet:, muted:, bottom: pad.bottom, onConfirm:, onReject:)` as a keyed `Positioned.fill` in `FullSceneFrame(overlays:)` — **after** `cornerGuide` and `coworkerPeek` so nothing covers its buttons. The picker's tap only stores the preview (`_xPreview`, tap origin); `onConfirm` clears it and calls the old evaluating handler with the stored origin (so scoring, strikes, `holdForCoworker()` and progression are unchanged); `onReject` adds it to an aside set drawn with `CardAside(aside:, child:)`. While a preview is open: `hintWaiting` false (the overlay sweeps its own two buttons) and `coworkerCanCome` returns false. Clear the aside set when the answer is confirmed or the round changes. Converted: m2_megger_prep (knob positions), m4_service_plan (work-order cards), m5_lv_street_read (scope chips), m5_workshop_referral (team buttons), learn_runner (quiz options, `top: 0`). Tests: `confirmChoice(t)` after the tap |
| The careless coworker peeps in once per play (two beats) | `CoworkerMoment` + `CoworkerScript`; beat 1 = caption under HUD + `RivalTalk` voice (guide idle; muted → caption held `MascotSpeechLibrary.readHold(line)`); beat 2 = chip by peep + guide ask + deck. Hooks `coworkerCanCome` / `onCoworkerAnswer`. He never comes during a praise window. **Hold a decisive control for him:** `coworkerDue` (scheduled, not come yet) and `if (holdForCoworker()) return;` at the top of the control that would finish his item — the control does nothing, the guide hushes, he comes now (even if `coworkerCanCome` says "not yet"; `coworkerHeld` is true meanwhile); after him, or when `coworkerCanCome` returns null, it returns false. Replaces hand-rolled `_holdForCoworker()` (m2_hydraulic_use, m3_service_drop) |
| A hand shows **how** to touch when the player is stuck (never what) | `gesture_hint.dart`. Scene: `FullSceneFrame(hint: () => HintSpec…, hintWaiting: <waiting for input>, hintKey: <round/station>, hintController: _hints)`; anywhere else wrap the waiting widget in `IdleHint(waiting:, spec: (size) => …, waitKey:, child:)`. Specs: `HintSpec.tap(at)`, `.hold(at)`, `.drag(from, toward:, travel:)` (≤ 96 dp nudge in a generic direction), `.swipe(from, toward:)`, `.sweep(rects)` (passes over all, presses none); `space: HintSpace.global` (default) / `.local` / `.scene` (design px, mapped by the frame). Helpers: `HintSpec.tapOn(key)`, `holdOn(key)`, `dragFrom(key, toward:)`, `sweepOver(keys)`, `gridCells(…)`, `globalRectOf(key)`. Misses: a scene with one big tap detector calls `_hints.missTap()` from its "tapped nothing" branch (or pass `hintAutoMiss: true`). Built in: `ChoiceDeck` (sweep over open cards; none when one card is left), every card preview (`ChoiceDeck`'s and `CardPreviewOverlay`: a sweep over ✕ and ✓ as a pair, once armed), the zoomed reason card (tap **এগিয়ে যান**), the Learn board pick and reason chips (sweep), and the Do level scenes (all but `ten_sec_scan.dart`). Not yet wired: `LearnRunnerPage`'s question list. A sweep drops options whose centre is outside the hint's box; a hint never shows on a route that is covered or with tickers muted |
| Mistakes | `DoMistake(key, textBn, art, deadly, lessonPoint)`, `MistakeCard` (+ পাঠে দেখুন → `openLessonPoint`), `bookMistake` |
| 3 slips | `DoStrikeOut` mixin (`strike(m)`), `StruckOutCard` (insists on reading) |
| Deadly | `FreezeFrame` + `freezeFilter` on the scene, the consequence in colour, then `DoDeathGuard.bookDeadly(m, runScore:)` (first death of the game = near-miss). While it runs `FreezeFrame` swallows every touch under it (layers after it in the Stack stay live) except, inside `FullSceneFrame`, the header band (status bar + `FullSceneFrame.headerBand`: close, mute) — `HeaderSafeShield`; it fills its Stack with or without a `Positioned` |
| Pass | `LevelPassPanel` (rank, mark, time, ◆, "আজ যা ধরলেন"), `starsFor` + `recordStars`, quick bonus under `quickMs` |
| Order move | `OrderRun` / `OrderGroup` (`order_steps.dart`) |
| Effects | Lottie via `tool/lottie_gen.py` → `assets/game/anim/`, `FxLoop` / `FxOnce` (awake 5 s after each wake) |

**Gotchas learnt the hard way**

- **Key every Stack child that comes and goes** (`ValueKey`). An unkeyed layer appearing mid-drag took a `GestureDetector`'s element and the gesture was lost (step 6).
- Clocks (`AwakeClock`, figures, `FxLoop`) run only for a few seconds after a change; never a free-running `repeat()` (use `slmSyncLoop` where a loop is unavoidable).
- Every `await` in a page is followed by a `mounted` / still-valid check (`stillValid:` on `askReason`).
- The coworker never comes on the item whose answer his arrival would give away (deal him on any item of the class).
- No hint or highlight before a mistake; nothing on the scene may mark the right answer (colour, size, order, backdrop).
  The gesture hint is the one exception and only shows *how* to touch: never `HintSpec.tap/hold` on one of several answers,
  never a drag toward the right target, and `hintWaiting` false during the intro, voice-locked beats, cards, decks
  (the deck has its own sweep), freezes and results.
- Hints are **off in widget tests** (`FLUTTER_TEST`, as main.dart turns off the intro) so idle-perf tests stay at zero
  frames; a test that checks a hint sets `GestureHints.debugEnableInTests = true` and resets it in `tearDown`.
  Likewise the two reading holds keep the old instant timing in widget tests unless opted in:
  `CoworkerTiming.debugReadHoldInTests` (muted beat 1) and `MascotSpeechLibrary.debugSilentHoldInTests` (unrecorded rival
  line); `test/level_kit_test.dart` opts in.
- The praise window is input-dead on purpose: a level that needs a tap between `putOnTable` and `askReason` (a
  tap-to-skip dwell) now just waits out the dwell. Do not add controls that must work in that window.
- `FullSceneFrame` finds the `ReasonTable` state above it (`findAncestorStateOfType`) — keep `FullSceneFrame` inside the
  level state's own build. Pass `inputBlocked:` to override.
- `ChoiceDeck` is stateful (it keeps a `GlobalKey` per card for the sweep); key it per question (`ValueKey('why-deck-…')`)
  as before.
- **No answer on touch.** Every multi-card pick is preview → ✓/✕ (above); any explanation after a pick (zoomed reason,
  `MistakeCard`, a quiz result) waits for its Continue button (**এগিয়ে যান**, the card's button, **পরের প্রশ্ন**) — never a
  timer. Tests pick with `pickChoice(t, text)` / `confirmChoice(t)` / `tapReasonProceed(t)` (`test/support/reason_proceed.dart`;
  Learn boards: `test/support/board_pick.dart`). A free selection committed by a separate button (m4_service_plan's papers,
  route, kit) and physical tool moves in a scene (fire_choose tools, m2_comealong_pull, m2_crimp_steps, m3_conductor_joint,
  m3_meter_call, m3_service_drop, m4_dtr_temp, m4_tree_cut) are not card picks.
- **Top bar:** `LevelShellBar` → close · **L<n>** (ladder step) · ◆ level score · 💀 · 📖 read-lesson book (+ an optional
  clock). No speaker button (`muted`/`onToggleMute` stay only so callers compile). Its sizes scale with the width
  (`UnifiedGameTopHud.scaleFor`), so a test finds the score from the ◆ in its pill, never by font size.

---

## 5. Building a picture board (শেখা)

Model: `learn_board_pack15.dart` … `learn_board_pack19.dart` with their tests and `tool/*_board_art.py`.

1. **Art generator** `tool/<topic>_board_art.py` writes gradient SVG cards (200 × 220) into `assets/game/art/<topic>_board/` (register the folder in `pubspec.yaml`). No text in the art except labels a worker reads. One backdrop per round; **every colour/gradient on a safe card also appears on a trap in every possible hand** (the generator asserts it, the test checks it). Deletes only its own stale files.
2. **Pack** `learn_board_packNN.dart`: `const learnBoardPackNN` (lessonId), 4–6 slots, each with a specific `promptBn`, 4–6 picture options (≥ 2 safe pictures, traps with a one-line `rejectBn` from the lesson), reason chips (libraries, 1.3×), and the myth beat: the rival's taunt + **the lesson's own myth word for word** (`XxxBoardLines.recorded`, clips via `tool/rival_clip.py`), exit line `'হুঁ! যা খুশি করুন।'` (already recorded). The myth question is flipped on about half the runs ("সেটা কি ভুল?").
3. **Wire** (§8): import + export + `learnBoardPackFor` line in `learn_board_models.dart`; rival lines in the dump test.
4. **Test** `test/learn_board_NN_test.dart`: registry, rounds, option rules, English digits, assets exist / none unused, the per-hand fairness check, rival lines resolve (`LearnVoice.resolve(l, rival: true)`), idle perf with and without reduce motion.

Runner rules (keep them): no name on a picture until it is tapped; after a miss the safe picture swaps to another safe picture and the hand reshuffles; weak spots go to `GameSave.weakByLesson`.

---

## 6. Building or retrofitting a Do level (কাজ)

Follow the playbook's 9 beats. Closest models: `pole_read.dart` (inspect + decide), `discharge_order.dart` (drag order), `ptw_steps.dart` (order done in a scene), `sky_read.dart` / `storm_push.dart` (new levels), `fire_choose.dart` (the reference level).

1. **Pure rules** in a run class (`XxxRun`): the deal (fresh every play, from a `Random`), decide/act methods returning a `DoMistake?`, `slips`, `ended`, `passed`. Unit-test it without widgets.
2. **Lines** in `abstract final class XxxLines`: intro, tasks (tap pool), reason libraries per case (`whyRight(case)` / `whyWrong(case)`), coworker script(s), pass/fail lines. Every fixed line lives here (device TTS now; the owner records later).
3. **Mistakes** in `abstract final class XxxMistakes` with `static const all` (stable keys `lesson/level/thing`, lesson-point index 0-based, an SVG picture in `assets/game/art/<topic>/`).
4. **Scene**: a painter file (`xxx_world.dart` / `xxx_yard.dart`) in design units, layered (sky → far → place → equipment → characters → controls); full screen top to bottom.
5. **Page** `XxxPage({required LevelContext ctx, required XxxPack pack, required bool muted})` with the kit mixins; `const xxxPacks = {'do_L_M_a': ...}`.
6. **Scoring**: copy the calls of `pole_read` / `tool_tip` (points per right action, the table, quick bonus, stars). Do not invent new values; a changed `quickMs` is an owner decision (say so in the report).
7. **Tests** `test/xxx_test.dart`: rules, deal varies over seeds, option libraries (`test/support/option_lengths.dart`), rival lines resolve, idle perf ("waits quietly", settle after the intro: `test/support/intro_wait.dart`), a full flow that clears the rung including a reason pick and the coworker, the 3-slip strike-out, the deadly freeze.
8. **Look at it**: render the screens to PNG in a scratch test (load `Noto Sans Bengali` with `FontLoader` inside `tester.runAsync`; Latin shows as boxes in tests) and delete the scratch test after.

---

## 7. Voice

- **Router** `MascotSpeechLibrary.speak(text, {voiceKey, muted, rival})`: Duty-Slip clip → `LearnVoice.resolve(text, rival:)` (recorded clip) → device TTS (**guide only**). Guide lines drive **`MascotTalk`**; `rival: true` drives **`RivalTalk` only** so `AiLinemanGuide` does not lip-sync during coworker/Learn-rival speech. A rival line with **no clip** never falls back to the device voice: it is silent, his lips stay still, and `speak` returns after `MascotSpeechLibrary.readHold(text)` (a new line or `stop()` ends it) so his caption/bubble stays up for reading — Do levels and Learn boards alike. Muted `speak` returns at once; callers hold captions themselves (`CoworkerMoment` does).
- **The guide's new lines: device TTS** (owner decision, 2026-11-06). Keep them in the level's `*Lines` class so they can be recorded later.
- **The rival / careless coworker speaks only in his recorded voice.** One clip per line:
  `python -I tool/rival_clip.py . say.txt` (line 1 = key text as in the code, line 2 = spoken form; voice bn-BD-PradeepNeural −6 % −14 Hz). It writes `assets/sounds/learn_voice/r_<sha1>.mp3` and registers it in `learnRivalVoice`. Then list the line in `tool/dump_learn_voice_lines_test.dart` (coworker scripts in the "Do levels on the kit" list; board lines via `XxxBoardLines.recorded`).
- **Never rerun `tool/make_learn_voice.py` wholesale** — it deletes clips missing from a fresh dump. Do not hand-edit `learn_voice_map.dart` except through `tool/rival_clip.py`.
- Coach sprites: `assets/duty_slip/dress/coach_*.webp` (ready, talk, happy, oops, blink); the mouth overlays only on `coach_talk`.

---

## 8. Wiring checklist (shared files — the lead does these after the level's own files are done)

| For | Edit |
|---|---|
| A board | `learn_board_models.dart`: `import 'learn_board_packNN.dart';`, `export … show learnBoardPackNN, XxxBoardLines;`, `if (lessonId == 'L.M') return learnBoardPackNN;` · the test asserts `learnBoardPackFor('L.M')` |
| A Do level | `do_games.dart`: import + `case 'engine_type':` · `content_catalog.json`: the pack's `engineType` + `"status": "playable"` **and** the rung's `"status": "playable"` |
| Mistakes | `mistakes_book.dart`: `...XxxMistakes.all` in `knownMistakes` |
| Rival lines | `tool/dump_learn_voice_lines_test.dart` (import the level; add its `CoworkerScript`s / `XxxBoardLines.recorded`) |
| Art folders | `pubspec.yaml` asset folder (non-recursive) |
| Docs | `GAME_PATH_CHECKLIST.md` row · `MODULE1_LADDER.md` row · the level's line in §10 below |

Then: `flutter analyze` (0 issues), `flutter test` (all), `python -I tool/check_asset_refs.py .`.

---

## 9. Learn runner details

- **Text deck** (`LearnRunnerPage`): load the lesson (offline → honest dialog, never a made-up deck) → one swipe card per lesson point (`+5`) → 2 quiz questions (`+10` / `−5`) → mark = first-try correct / 2 (one miss fails at 60 %). First clear `+20`, replay `+5`.
- **Board scoring**: pending ◆ on a right pick, banked on a right why; wrong burns it or `−5`; pass adds `clearBonus` (20).
- **History chip** (`LevelHistoryChip`, only if played before), **fail panel** (`LevelFailPanel`: retry remounts, পাঠটা পড়ুন, ফিরে যান; idle after one sequence), **day card** (`lessonDays`, lessons 1.1–1.5), **promise card** (`lesson_promises.dart`, 1.1–1.5; +5 once), **পাঠ offer** (`LessonMissTally`: 3 wrong in a row; or after a pass if it never showed).
- **Deaths and the fall**: a deadly mistake ends the play; the game's first is a near-miss; after that `recordDoDeath` when the level is left, and every Do/gate rung cleared since the last death turns to `prove` (fall option C). A death play commits 0.

---

## 10. Level reference (Module 1)

Status per rung: [GAME_PATH_CHECKLIST.md](GAME_PATH_CHECKLIST.md). Deadly lists: [MODULE1_LADDER.md](MODULE1_LADDER.md) and the owner decisions of 2026-11-08 (memory/ladder notes).

| Step | Rung · engineType · pack | Files | Notes |
|---:|---|---|---|
| 2 | `1.1/do/0` · `kit_check` · `do_1_1_a` | `kit_check.dart`, `store_room.dart` | dress জামা → প্যান্ট → জুতো; `KitMistakes` (synthetic, nail) deadly with `KitDeathView`; other wrong items `kitSlip` |
| 3 | `1.1/do/1` · `glove_check` · `do_1_1_b` | `glove_check.dart`, `helmet_check.dart`, `van_yard.dart` | air test; helmet station after the gloves (torch sweep, inside + stamp, chin strap); bad helmet = slip; quickMs 135 s |
| 5 | `1.2/do/0` · `distance_spot` | `distance_spot.dart` | drag the band (`StreetGeo`, 40 px/m); rule + 0.6 m accepted; rain rounds 11 kV only (`distanceFor` asserts) |
| 6 | `1.2/do/1` · `tool_tip` | `tool_tip.dart` | hot stick vs bamboo vs PVC; drag the tip; judged on release; `KiteRun.restTip` |
| 8–9 | `1.3/do/0`, `/1` · `pole_read` | `pole_read.dart`, `pole_yard.dart` | walk round, lens, knock (ঠক্ ঠক্ / দপ্ দপ্ / টন টন / ভোঁতা শব্দ); `SteelForm { tube, rail, hBeam }`; brown porcelain or grey polymer insulators; report-first items (hive, nest, cable tangle, hoarding = slip if climbed); false report = slip; `kPoleQuickMs` 150 s |
| 11 | `1.4/do/0` · `harness_check` | `harness_check.dart`, `harness_store.dart` | pegboard, four close-ups; expired label (no damage) = slip; belt / damage = deadly |
| 12 | `1.4/do/1` · `harness_fit` | `harness_fit.dart` | fit by hand; pole-top anchor lens; loose straps push = slip, pin / 20-years = deadly |
| 14 | `1.5/do/0` · `rod_pick` | `rod_pick.dart`, `rod_van.dart` | docket on the van door, slide inspection; `RodRating` / `RodRatingText` are public (used by steps 5–6) |
| 15 | `1.5/do/1` · `discharge_order` | `discharge_order.dart` | drag clamp → spike, hook → R/Y/B, chain; off in reverse; skip-discharge push = deadly |
| 17 | `1.6/do/0` · `ptw_match` | `ptw_match.dart`, `ptw_site.dart` | permit vs tag/plate/ID/phone clock; deadly: verbal, wrong feeder, unsigned, expired; a wrong stop = slip, the permit stays |
| 18 | `1.6/do/1` · `ptw_steps` | `ptw_steps.dart`, `ptw_yard.dart` | steps done in the scene (`PtwStepsRun`, `stepFor`); skip test / no paper = deadly; leaving with the permit = slip |
| 20 | `1.7/do/0` · `shock_rescue` | `shock_rescue.dart`, `shock_scene.dart` | switch off or drag a dry object onto the arm/leg; countdown; touch / wet / metal = deadly |
| 21 | `1.7/do/1` · `golden_minute` | `golden_minute.dart`, `golden_field.dart` | response → breathing → someone calls → CPR rhythm (AHA 100–120/min, `GoldenRhythm`) → keep going; no deadly |
| 23 | `1.8/do/0` · `fire_choose` | `fire_choose.dart`, `fire_world.dart`, `fire_fx.dart` | the reference level: class → extinguisher, power off first, gauge, hold to spray |
| 24 | `1.8/do/1` · `fire_pass` | `fire_pass.dart` | where to stand (wind), PASS by hand; refill push; no deadly |
| 26 | `1.9/do/0` · `sky_read` · `do_1_9_a` | `sky_read.dart`, `sky_world.dart` | turning weather, tap the signs, stop or work on; lightning push = deadly; a needless stop is not scored |
| 27 | `1.9/do/1` · `storm_push` · `do_1_9_b` | `storm_push.dart` | the supervisor (rival art/voice) per `StormCue`; hands-on refusal, shelter; climbing in a storm = deadly |
| 29 | `1.10/do/0` · `ten_sec_scan` · `do_1_10_a` | `ten_sec_scan.dart` | 10 rapid Go/Stop checks remixing Module 1; reason deck; coworker once |
| 30 | `m1/gate` · `gate_watch` · `gate_m1` | `gate_watch.dart` + `gate_watch_world.dart` | Hazard-spotting rank gate: dealt moments of one job, stop → tap where → lens → what → fix; see §10a |

Boards: `learnBoardPack11/12` (`learn_board_models.dart`), `learnBoardPack13…19` (`learn_board_pack13…19.dart`), `learnBoardPack110` (`learn_board_pack110.dart`, art `tool/scan_board_art.py`). The `storm_board/` folder is shared: `rain_/thunder_/wind_/step_/plan_` (board), `sky_` (step 26), `push_` (step 27).

Legacy (`lib/features/duty_slip/`): `dsLevels` 1–33 still exist for **unbuilt** packs only. If a catalog pack already names a shell `engineType` (anything except `placeholder` / `learn_cards`), `adventure_map.dart` must **not** fall through to a legacy screen — show Coming Soon instead. Never resurrect deleted Zero-Loss screens.

---

## 10a. Rank Gate (step 30) — hazard-spotting gate

**Status:** `m1/gate` / pack `gate_m1` / `engineType: gate_watch` is `playable` (rebuilt 2026-11-11 from the owner's
2026-11-10 concept; the earlier five-station medley was rejected and deleted). Pass calls
`markRungCleared('m1/gate')` + `unlockRank(2)` (ট্রেইনি → জুনিয়র: Module 2's `rankName`) and shows the rank-up on the pass panel.

**Files:** [`lib/features/game/gate_watch.dart`](lib/features/game/gate_watch.dart) (content, deal, pure `GateRun`, page) and
[`lib/features/game/gate_watch_world.dart`](lib/features/game/gate_watch_world.dart) (the crew, the moments' animation, tap
zones, cameras, the consequence painter; it reuses `VanYardPainter`, `PoleYardPainter` and `PolePainter`). Wire: `do_games.dart`
`case 'gate_watch'`; mistakes in `mistakes_book.dart` via `GateMistakes.all`; the coworker's lines in
`tool/dump_learn_voice_lines_test.dart` (`GateLines.coworker`); pictures in `assets/game/art/gate/`.

**How it plays:** GuideIntro with the dealt docket (kV · feeder · pole · job) → 10–12 moments of one job in its order
(`GateSlot`: helmet, shirt, boots, gloves, kite, permit, rod, harness, pole check, discharge, anchor, sky, fire, line clear),
dealt from 24 mistakes (`GateFault`, lessons 1.1–1.9) + 14 done right; about half wrong, ≥ 2 deadly-class, mistakes from
4+ lessons. While a moment plays the red **থামান!** button is up (reduced motion: a still for the same time). A stop holds
the scene → tap where (`gateZones`) → the lens → “কী ভুল?” (ChoiceDeck) → “এখন কী করবেন?” on the ◆ table (`ReasonTable`, 15,
or 10 after a wrong tap / wrong pick) → the crew redoes it right. Missed slip-class = its card (a slip); missed deadly-class
= freeze grey + the consequence in colour (`GateHarmPainter`) + `bookDeadly`; a needless stop = “সব তো ঠিক ছিল!” (a slip);
3 slips = `StruckOutCard`. The coworker once, as a mistake moment starts ("থামিও না, দেরি হয়ে যাচ্ছে!", clip `r_feab595cb8`);
the stop waits for him (`holdForCoworker`); listening = that mistake is missed. Gesture hint: a sweep over broad areas of
the scene (`gateLookAreas`), the same whatever the mistake. Test hook: `GateWatchProbe` (tests only).

**Do not:** reopen legacy Level 33 as the gate; add deadly rules without the owner; rerun `tool/make_learn_voice.py`.

**Tests:** `test/gate_watch_test.dart` (deal rules, every moment's zone/card, libraries, wiring, full pass, missed deadly,
needless stop + strike-out, coworker hold + listen, gesture hint), `test/perf/gate_watch_perf_test.dart` (idle in a stop).

---

## 10b. Voice / coach line convention (2026-11-11)

Keep guide, intro, task, and coworker-ask Bangla **short** (one breath, ~1 short sentence). Long lectures belong in the lesson reader, not on the scene. When you shorten a **recorded** Learn/rival line, the clip map key in `learn_voice_map.dart` must match the new UTF-8 string exactly (or register a new clip). Ladder welcome/idle/poke lines in `mascot_speech_library.dart` use device TTS for now — keep them short too.

Learn board: after a wrong pick, shake + redeal + speak the reject line. **Do not** re-add a full-screen inspect zoom overlay on miss (removed 2026-11-11).

---

## 10c. Level reference (Module 5, wired 2026-11-12 — pending owner review)

Deadly/slip table, per-rung owner questions: [MODULE5_LADDER.md](MODULE5_LADDER.md); rulings: `docs/module_specs/module5_rulings.md`.
Every Do pack's catalog `deadlyRules` lists that level's `deadly: true` mistake keys (`test/m5_wiring_test.dart` keeps them equal);
art in `assets/game/art/m5_<name>/`; mistakes via `...m5_<name>.<X>Mistakes.all` in `mistakes_book.dart`; coworker scripts in
`tool/dump_learn_voice_lines_test.dart`. Most levels expose a test-only `*Probe` hook.

| Step | Rung · engineType · pack | Files | Notes |
|---:|---|---|---|
| 2 | `5.1/do/0` · `m5_trip_call` · `do_5_1_a` | `m5_trip_call.dart`, `m5_trip_call_world.dart` | control-room call: drag handset up, 7 question tiles (6 required incl. the logbook; 2 dealt vague topics, a second tap probes; a needless re-ask loses the thorough and quick bonus), drag down; pin the suspect, van on the start section; briefing (PTW scoped to touching/climbing, M5-3); coworker = lesson myth 2 on the first hang-up of his call, listening = deadly (R8); operator on device TTS; quickMs 100 s |
| 3 | `5.1/do/1` · `m5_recloser_watch` · `do_5_1_b` | `m5_recloser_watch.dart`, `m5_recloser_watch_world.dart` | count recloser shots against decoys, report count + span; lock-out: docket → drive → PTW → tester → spike → clamp (no-PTW / no-test / no-earth / clamp-first deadly); PTW-stage hint is a sweep over the radio and the van, not a hold (playbook §1.3); quick clock from the lock-out (70 s) |
| 5 | `5.2/do/0` · `m5_fault_address` · `do_5_2_a` | `m5_fault_address.dart`, `m5_fault_address_world.dart` | radio the control room for the docket first (M5-3; not on the in-service call), drive the van, read FPIs (close-up), bracket with two flags; long feeder = van 2 to the far end; sectionalizer call; decoy groves + grove T-off on the map only; needless stop loses the clean +5; history note; no deadly; quickMs 120 s |
| 6 | `5.2/do/1` · `m5_sense_walk` · `do_5_2_b` | `m5_sense_walk.dart`, `m5_sense_walk_world.dart` | hold-walk / release-stop, swipe up to the pole top, ear/nose hold (nearest pole), tag; the hidden clue counts only after a positive ear/nose at that pole (M5-10, else slip blind-tag); decoy dirt layers and 1–2 DTRs every play; fallen wire AHEAD (stop ≥10 m, rope ring ≥10 m, then walk to the rope) or DROP (feet-together steps out, stride = deadly); coworker at the wire (listen = deadly) or mid-span 'look up while walking' (listen = slip); hook `SenseWalkProbe` |
| 8 | `5.3/do/0` · `m5_culprit_case` · `do_5_3_a` | `m5_culprit_case.dart`, `m5_culprit_case_world.dart` | photograph clues, thread to the culprit, type + remedy deck; 'charge and see' remedy = deadly (R8, builder-added); villager blast-sound clue at some spots; hook `M5CulpritProbe`; quickMs 100 s |
| 9 | `5.3/do/1` · `m5_anneal_cut` · `do_5_3_b` | `m5_anneal_cut.dart`, `m5_anneal_cut_world.dart` | earth both ends (climb with one missing = deadly R4), spanner off the old clamp/sleeve, judge softness by colour, cut out the soft length (too far = needless-cut slip, blocked), new joint; the snapped spot has no spanner step; the sleeve is a bolted joint sleeve; quickMs 70 s |
| 11 | `5.4/do/0` · `m5_feeder_sectionalize` · `do_5_4_a` | `m5_feeder_sectionalize.dart`, `m5_feeder_sectionalize_world.dart` | pull every LT way, shut the DO, restore one by one, tag the blower; DTR/HT case → patrol or megger; deadly: no LT open, faulty way re-pushed, re-charge with nothing changed, re-charge after HT proved; quickMs 75 s |
| 12 | `5.4/do/1` · `m5_reblow_clock` · `do_5_4_b` | `m5_reblow_clock.dart`, `m5_reblow_clock_world.dart` | read today's logbook page, look + hold the DO / hold the clock, drag one of two identical stamps; fuse-rating tag on the DO arm (M5-8); permanent → coworker (fault burning, deadly) → order deck; transient → 3-picture where-to-look deck; quickMs 60 s |
| 14 | `5.5/do/0` · `m5_lv_street_read` · `do_5_5_a` | `m5_lv_street_read.dart`, `m5_lv_street_read_world.dart` | ask the street → scope chip → route → LTDB R/Y/B (3 phases before 'fine'; live tap = deadly) → line probes → evidence-gated verdict → docket/span card; coworker myth 1 on probe 1–2 of one area complaint (probes wait); notebook 2 columns / no heading on short phones; 'রিডিং দেখে ঠিক রায়' not earned when 8+ houses are probed; quickMs 90 s |
| 15 | `5.5/do/1` · `m5_lv_load_test` · `do_5_5_b` | `m5_lv_load_test.dart`, `m5_lv_load_test_world.dart` | measure with the load on, N–E, evidence-gated verdict, method deck (R22 deadly), every joint, loaded re-measure / load-grew report; 4 coworker scripts (`M5LvLoadLines.coworkerScripts`); guide/customer lines for later recording: `M5LvLoadLines.spoken`; quickMs 90 s |
| 17 | `5.6/do/0` · `m5_fault_casebook` · `do_5_6_a` | `m5_fault_casebook.dart`, `m5_fault_casebook_world.dart` | 4 cases, 2 clues by gesture (tap/swipe-up/sweep/hold), close-up circle; slip locked until both clues are seen (M5-10), then dragged into short/open/trip-no-proof; noSign dealt only as a feeder trip (filed as open → trip-not-open card); coworker trip myth holds the first clue; no deadly; quickMs 70 s |
| 18 | `5.6/do/1` · `m5_live_wire_guard` · `do_5_6_b` | `m5_live_wire_guard.dart`, `m5_live_wire_guard_world.dart` | swipe to stop people reaching live metal, in waves; needless stop = 2 s busy + loses the wave's +5 + the quick bonus; from wave 2 a trap (needless people 300–600 ms before a live one); 2 dealt coworker lines (`M5LiveWireLines.coworkers`); import with `show` (the file re-exports world types); hook `M5LiveWireProbe`; quickMs 90 s |
| 20 | `5.7/do/0` · `m5_searchlight_patrol` · `do_5_7_a` | `m5_searchlight_patrol.dart`, `m5_searchlight_patrol_world.dart` | docket chip (M5-3), two-person van, steer the searchlight, call the speed, mark poles, phone the report; climbing to look = deadly; hook `M5SearchlightProbe`; quickMs 90 s |
| 21 | `5.7/do/1` · `m5_dark_eyes` · `do_5_7_b` | `m5_dark_eyes.dart`, `m5_dark_eyes_world.dart` | headlamp off, wait (~5 s adaptation), mark the corona/tracking glow or sound (mark before the clue = slip), report from the ground; final deck: right / climb-or-poke (deadly) / morning-or-put-off (slip); quickMs 75 s |
| 23 | `5.8/do/0` · `m5_cause_strike` · `do_5_8_a` | `m5_cause_strike.dart`, `m5_cause_strike_world.dart` | run a test (ear, tong, gauge, meter, bushing tester), strike ruled-out causes; deadly: untested spanner/hands, climbing live; 5 coworker scripts (hum, humLate, live, climb, small); hum WAVs live in the art folder (`ZlFx.cue('game/art/m5_cause_strike/hum_*.wav')`); quickMs 80 s |
| 24 | `5.8/do/1` · `m5_workshop_referral` · `do_5_8_b` | `m5_workshop_referral.dart`, `m5_workshop_referral_world.dart` | gather proof at 3 sites (bushing, IR card, oil colour/water/smell, record book), pin it on the workshop slip; re-charge DTR / LT with the blower in / no HT test = deadly; water push = slip (M5-6); quickMs 90 s |
| 26 | `5.9/do/0` · `m5_cable_fault_type` · `do_5_9_a` | `m5_cable_fault_type.dart`, `m5_cable_fault_type_world.dart` | isolate + lock/tag both ends, plan megger/multimeter tests core by core, discharge, deduce open/short/earth; deadly: live lead (R23), earthed rod on a live core, lifting a charged clip (R24); clean play ~4.6 min; quickMs 230 s |
| 27 | `5.9/do/1` · `m5_cable_route_locate` · `do_5_9_b` | `m5_cable_route_locate.dart`, `m5_cable_route_locate_world.dart` | read the TDR (blank → ARM), trace the route, phone the three underground owners before the peg (M5-7), sweep for the thump, chalk, peg labelled 'গোঁজ'; coworker B1/B2 dealt; no deadly; quickMs 80 s |
| 29 | `5.10/do/0` · `m5_pm_thermal_round` · `do_5_10_a` | `m5_pm_thermal_round.dart`, `m5_pm_thermal_round_world.dart` | sweep the thermal camera, snap hotspots (>15 °C over the same joint on the other two phases, M5-15b), shutdown order (phone → permit → tester → earth), torque click; deadly: no permit / no test / no earth; quickMs 80 s |
| 30 | `m5/gate` · `m5_gate_case` · `gate_m5` | `m5_gate_case.dart`, `m5_gate_case_world.dart` | one fault call as crew in-charge: phone menu, PTW clipboard, chip → map → order → hold radio dispatch (9 orders incl. rope-beside-wire R16 slip and bamboo poke R20 deadly), close view or UG sheet, report, line clear (PTW returned: hands-on after it deadly); 3 coworker scripts (chargeNight, chargeDay, waitMorning); quickMs 7 min; `unlockRank(5)` |

Boards: `learnBoardPack51 … 59`, `learnBoardPack510` (`learn_board_pack5<L>.dart`, art `assets/game/art/m5_board5<L>/`, generator
`tool/m5_board5<L>_art.py`), exported with their `M5Board5<L>Lines` from `learn_board_models.dart`. Boards have no deadly freeze
(kit design); the deadly-class traps cost a ◆ and show their lesson/ruling text.

---

## 11. Environment notes (Windows)

- Flutter: `C:\Users\rouma\flutter\bin\flutter.bat` (PowerShell: `& C:\Users\rouma\flutter\bin\flutter.bat …`); not on the bash PATH.
- Python: always `python -I`; with `-I` env vars are ignored, so call `sys.stdout.reconfigure(encoding='utf-8')` before printing Bangla.
- Write Bangla with the editor / `Write` / Python `io.open(..., encoding='utf-8', newline='\n')` — **never** PowerShell `Set-Content`.
- Several agents may run `flutter` at once: analyze and test only your own files while others work; the "another flutter command" lock is normal.
- Profile builds for the phone keep the debug signature (updates in place, keeps the player's progress): `flutter build apk --profile --target-platform android-arm64`, then `adb install -r`.

---

## 12. Before you commit

1. `git pull` first; never force-push; commit/push only when the owner asks; work on the feature branch, not `master`.
2. `flutter analyze` (no issues), `flutter test` (all green), `python -I tool/check_asset_refs.py .`.
3. No secrets (`android/key.properties`, keystores, service-role keys, `tool/hourly_answer_keys*`); no scratch tests (`test/zz_*`) or screenshots left in the repo.
4. New animated screen → its idle perf test. New spoken rival line → clip + dump-test entry. New asset → referenced, folder in `pubspec.yaml`.
5. Update `GAME_PATH_CHECKLIST.md` (and `MODULE1_LADDER.md` for Module 1).
