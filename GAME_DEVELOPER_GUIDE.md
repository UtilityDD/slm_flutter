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
    ├── full_scene_frame.dart       # FullSceneFrame, SceneMetrics, cornerGuide
    ├── scene_kit.dart              # GuideIntro, LinemanFigure (poses, tipOf), AwakeClock
    ├── reason_table.dart           # ReasonTable mixin: putOnTable → askReason → zoom + এগিয়ে যান → paid
    ├── coworker_moment.dart        # CoworkerMoment mixin, CoworkerScript, CoworkerPeek (two-beat UI)
    ├── choice_deck.dart            # ChoiceDeck + dealChoices(right, wrong, rng)
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
    ├── ten_sec_scan / gate_field                         # step 29 Do · step 30 rank gate
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
| Right action → ◆ waits on the table → "কেন …?" → zoom + **এগিয়ে যান** → paid → next | `ReasonTable` mixin: `putOnTable(n)`, `askReason(…)`, `reasonDeck`, `proceedReason`, `tableLayers`, `whyPayout` — tests must tap `reason-proceed-btn` |
| Any 3-card choice | `ChoiceDeck` + `dealChoices(right, wrong, rng)` (libraries ≥ 2 right, ≥ 5 wrong, all within 1.3× length) |
| The careless coworker peeps in once per play (two beats) | `CoworkerMoment` + `CoworkerScript`; beat 1 = caption under HUD + `RivalTalk` voice (guide idle); beat 2 = chip by peep + guide ask + deck. Hooks `coworkerCanCome` / `onCoworkerAnswer` |
| Mistakes | `DoMistake(key, textBn, art, deadly, lessonPoint)`, `MistakeCard` (+ পাঠে দেখুন → `openLessonPoint`), `bookMistake` |
| 3 slips | `DoStrikeOut` mixin (`strike(m)`), `StruckOutCard` (insists on reading) |
| Deadly | `FreezeFrame` + `freezeFilter` on the scene, the consequence in colour, then `DoDeathGuard.bookDeadly(m, runScore:)` (first death of the game = near-miss) |
| Pass | `LevelPassPanel` (rank, mark, time, ◆, "আজ যা ধরলেন"), `starsFor` + `recordStars`, quick bonus under `quickMs` |
| Order move | `OrderRun` / `OrderGroup` (`order_steps.dart`) |
| Effects | Lottie via `tool/lottie_gen.py` → `assets/game/anim/`, `FxLoop` / `FxOnce` (awake 5 s after each wake) |

**Gotchas learnt the hard way**

- **Key every Stack child that comes and goes** (`ValueKey`). An unkeyed layer appearing mid-drag took a `GestureDetector`'s element and the gesture was lost (step 6).
- Clocks (`AwakeClock`, figures, `FxLoop`) run only for a few seconds after a change; never a free-running `repeat()` (use `slmSyncLoop` where a loop is unavoidable).
- Every `await` in a page is followed by a `mounted` / still-valid check (`stillValid:` on `askReason`).
- The coworker never comes on the item whose answer his arrival would give away (deal him on any item of the class).
- No hint or highlight before a mistake; nothing on the scene may mark the right answer (colour, size, order, backdrop).

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

- **Router** `MascotSpeechLibrary.speak(text, {voiceKey, muted, rival})`: Duty-Slip clip → `LearnVoice.resolve(text, rival:)` (recorded clip) → device TTS. Guide lines drive **`MascotTalk`**; `rival: true` drives **`RivalTalk` only** so `AiLinemanGuide` does not lip-sync during coworker/Learn-rival speech.
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
| 30 | `m1/gate` · `gate_field` · `gate_m1` | `gate_field.dart` | Rank gate — see §10a |

Boards: `learnBoardPack11/12` (`learn_board_models.dart`), `learnBoardPack13…19` (`learn_board_pack13…19.dart`), `learnBoardPack110` (`learn_board_pack110.dart`, art `tool/scan_board_art.py`). The `storm_board/` folder is shared: `rain_/thunder_/wind_/step_/plan_` (board), `sky_` (step 26), `push_` (step 27).

Legacy (`lib/features/duty_slip/`): `dsLevels` 1–33 still exist for **unbuilt** packs only. If a catalog pack already names a shell `engineType` (anything except `placeholder` / `learn_cards`), `adventure_map.dart` must **not** fall through to a legacy screen — show Coming Soon instead. Never resurrect deleted Zero-Loss screens.

---

## 10a. Rank Gate (step 30) — for the next agent

**Status:** Module 1 is complete. `m1/gate` / pack `gate_m1` / `engineType: gate_field` is `playable`. Pass calls `markRungCleared('m1/gate')` + `unlockRank(1)` (ট্রেইনি) and shows the সুরক্ষা কবচ badge copy in `GateLines.allSet`.

**File:** [`lib/features/game/gate_field.dart`](lib/features/game/gate_field.dart) — one host with pure `GateRun` + five stations on the shared kit (`GuideIntro`, `FullSceneFrame`, `ReasonTable`, `CoworkerMoment`, `DoDeathGuard`). Wire: `do_games.dart` `case 'gate_field'`; mistakes in `mistakes_book.dart` via `GateMistakes.all`. Guide clips already under `assets/sounds/guide_voice/gate_*.mp3`.

**Stations (fixed order, one 11 kV feeder job):**
1. **Van** — pick 11 kV rod; reject PVC jugaad (deadly) and damaged stick (slip).
2. **PTW** — refuse verbal phone "লাইন বন্ধ… কাগজ পরে" (start without written PTW = deadly).
3. **Pole** — 360° orbit + hammer knock; climb uninspected / condemned = deadly.
4. **Discharge** — earth clamp first, then R/Y/B with spark; line before earth = deadly.
5. **Storm** — coworker peeps once; refuse rush; van shelter (tree/pole climb/touch wire = deadly).

**Do not:** reopen legacy Level 33 as the gate; invent new deadly rules without owner yes; wholesale-rerun `tool/make_learn_voice.py` (it deletes clips missing from a fresh dump). New rival lines only via `tool/rival_clip.py` + `learnRivalVoice` + dump-test entry.

**Tests:** `test/gate_field_test.dart` (rules + option lengths + smoke), `test/perf/gate_field_perf_test.dart` (idle rebuild guard).

---

## 10b. Voice / coach line convention (2026-11-11)

Keep guide, intro, task, and coworker-ask Bangla **short** (one breath, ~1 short sentence). Long lectures belong in the lesson reader, not on the scene. When you shorten a **recorded** Learn/rival line, the clip map key in `learn_voice_map.dart` must match the new UTF-8 string exactly (or register a new clip). Ladder welcome/idle/poke lines in `mascot_speech_library.dart` use device TTS for now — keep them short too.

Learn board: after a wrong pick, shake + redeal + speak the reject line. **Do not** re-add a full-screen inspect zoom overlay on miss (removed 2026-11-11).

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
