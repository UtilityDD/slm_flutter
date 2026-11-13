# GAME_LEVEL_PLAYBOOK.md — how to build a game level

**Every agent and every human: read this before you generate, rebuild or change any game level.**
It is the level-building playbook, written from what the owner approved on ladder step 1 (Learn 1.1,
`learn_board_runner.dart`) and step 23 (lesson 1.8 কাজ 1, `fire_choose.dart`, the reference Do level).
Project rules are in [AGENTS.md](AGENTS.md); product design in [GAME_DESIGN.md](GAME_DESIGN.md); code
details per level in [GAME_DEVELOPER_GUIDE.md](GAME_DEVELOPER_GUIDE.md); the ladder plan in
[MODULE1_LADDER.md](MODULE1_LADDER.md). When this guide and an older level disagree, this guide wins —
bring the old level in line when you touch it. The older
[`lib/features/duty_slip/GAME_LEVELS_GUIDE.md`](lib/features/duty_slip/GAME_LEVELS_GUIDE.md) covers only the
legacy `dsLevels` screens (photo scenes, title cards); for ladder levels in the level shell, this playbook wins.

---

## 0. Before you write any code

1. **Read** AGENTS.md, this guide, and the level's row in MODULE1_LADDER.md (moves, deadly list).
2. **Content comes from the lesson** (`tool/all_training_chapters_bn.json`, the lesson's mistake texts) and
   from standards where they apply (e.g. IS 2190 for extinguishers). **Never invent** a technical fact,
   distance, rating or procedure. If the source does not support a detail, flag it to the owner instead.
3. **Find the scoring functions you will call** (§6) and do not change point values, the pass mark or
   strike rules without the owner's explicit yes.
4. **Plan first, then build.** For a new level or a big change, tell the owner the plan in short
   numbered steps with the open decisions, and wait for "ok/proceed".
5. **Assets:** do not reuse an existing picture unless it matches exactly; make what the scene needs
   (code-drawn painter, gradient SVG, or Lottie from `tool/lottie_gen.py`).

## 1. The player's loop (level 1's concept — same on every level)

| # | Beat | What happens | Build with |
|---|---|---|---|
| 1 | **Guide first** | Full screen, the app's mascot says the task in **one short line**: what is wrong and how urgent ("সাবস্টেশনে আগুন! … এখনই নেভান!"). **No "শুরু" button, no skip, a tap does not skip** — the game starts when the voice and a fair reading time are done. **Learn with an explainer** (§1.1): guide → YouTube → portrait → guide → board. | `LevelIntro` (`level_frame.dart`), or `GuideIntro` (`scene_kit.dart`) over a live scene; Learn video: `learn_explainer_videos.dart`, `learn_video_gate.dart` |
| 2 | **The scene** | Full screen to the top and bottom (as level 1); the header floats on it. The scene is a **place**, not a page: layered background → midground → foreground, real equipment, the player's worker doing the work. | `FullSceneFrame` (`full_scene_frame.dart`, gives `SceneMetrics`), a world painter, `LinemanFigure` |
| 3 | **Guide in the corner** | Short lines with the **next task only** ("কী দিয়ে নেভাবেন?"). No answer hints, no answers, no pointing tours ("এটা? এটা? না এটা?"). A **gesture hint** (§1.3 — *how* to touch, never *what*) after idle or confused taps is allowed and expected. | `AiLinemanGuide` in a corner, or `DoCoachStrip`; `IdleHint` / `FullSceneFrame(hint:)` |
| 4 | **Tap the guide** | He says the current task again, **a different way each time, never the answer**; tick sound; no cost. The gesture hint is the visual twin: it shows the kind of touch (tap, hold, drag, swipe, a sweep over the choices). | `DoCoachStrip(tasks: XLines.tasks, muted: _muted)` + `TaskNudge`, or a level pool (`FireLines.tap*`) |
| 5 | **Hands-on** | Use the five moves (choose · inspect · spot · order · say no) and *do* the job where it fits: hold to spray, throw, drag, pull a switch. Equipment shows its real state (an isolator at **ON** that the player must switch **OFF**; a gauge to read). | level page + painters / Lottie |
| 6 | **Success like level 1** | Right action → right sound + animation + a short praise line (`LearnFeedbackLines.right`) + the ◆ **wait on the table** (the scene takes **no touch** from `putOnTable` until the deck opens — `FullSceneFrame` shields it, the header stays live; gate handlers on `tableBusy`) → "কেন এটা নিলেন?" with 3 cards → right reason pays the table into the score, wrong reason burns it, a right retry pays 5 → the **right card zooms with full text** and a single **এগিয়ে যান** button; the level moves only when the player taps **এগিয়ে যান**. Only **glad / celebrate** bubbles auto-clear after voice — task prompts (talk / think / inspire / warn) stay until the next `say`. | `ReasonTable` mixin (`reason_table.dart`: `putOnTable`, `askReason`, `reasonDeck`, `proceedReason`, `tableLayers`, `whyPayout`); praise dismiss in `GuideDirector.say` |
| 7 | **Mistakes teach** | **Answer** hints appear **only after a mistake** (gesture hints of §1.3 are not answer hints): `MistakeCard` (picture + one line + **পাঠে দেখুন**). **3 slips** → the level fails with a fitting sound and the lesson card insists on reading before "আবার খেলি". Deadly → the scene freezes grey (and takes no touch while frozen; the header's close and mute stay live), the consequence plays in colour, then near-miss/death and the fall. | `DoStrikeOut`, `StruckOutCard`, `FailSound`, `DoDeathGuard`, `FreezeFrame` |
| 8 | **Pressure moment (Do only)** | Two clean beats: (1) coworker peeps + **full caption under the HUD + his voice** (no guide ask, no deck; guide idle — rival voice must not drive mascot lips; muted or no clip yet → silent, caption held for a reading time); (2) caption **collapses to a thin chip by his peep** (never over the score line), then the **guide** asks and the 3-card refuse/listen deck rises. Listening = the slip. Learn myth cutscenes stay on their own board flow. | `CoworkerMoment` mixin + `CoworkerScript` (`coworker_moment.dart`); `RivalTalk` |
| 9 | **Result** | Pass panel (rank, mark, time, ◆, "আজ যা ধরলেন", stars) or fail panel with পাঠ. | `LevelPassPanel`, `LevelFailPanel`, `starsFor` |

Every play is **dealt fresh** (order, traps, which tool is empty, who pushes and when) so it never repeats.

### 1.1 Learn explainer video (next Learn levels)

When the player taps **শিখুন**, `AdventureMap._openLearn` checks `LearnExplainerVideos.youtubeIdFor(lessonId)`:

1. **Id present** → `LearnVideoGatePage`: guide ("মন দিয়ে শুনুন") → in-app YouTube → force **portrait** after landscape → guide ("সাবধানে খেলুন") → `LearnBoardRunnerPage`.
2. **Id null / missing** → open the board directly (unchanged).

**To wire the next lesson's video** (do not invent URLs):

1. Owner gives the YouTube link or 11-char id.
2. Set it in `lib/features/game/learn_explainer_videos.dart` → `youtubeIdByLesson['N.M'] = '…'` (Modules 1–4 slots already listed; null = not ready).
3. Full `youtu.be` / `watch?v=` URLs are OK — `parseVideoId` extracts the id.
4. No other wiring: `_openLearn` already routes through the gate.
5. Add/extend a unit check in `test/learn_explainer_videos_test.dart` for the new id.
6. Offline / failed load: Bangla retry + "এগিয়ে যান" (never raw exceptions).

### 1.2 Careless coworker (Do only) — layout & lips

- **Beat 1:** full caption **under** the score HUD (`belowHud`), rival voice only; guide bubble cleared + idle; **`RivalTalk`** drives his mouth — never `MascotTalk` (guide must not lip-sync with an empty bubble).
  Muted, the caption is held for `MascotSpeechLibrary.readHold(line)` before beat 2. A rival line with **no recorded clip**
  is **silent** (never the device voice, which is the guide's) and its caption is held for the same reading time — in Do
  levels and on the Learn boards alike.
- **Beat 2:** thin **chip by his peep** (not a top strip over ◆), then guide ask + 3-card deck.
- He never cuts into a praise window (`tableBusy`). If the player could finish the item he is dealt on before he comes,
  put `if (holdForCoworker()) return;` at the top of the decisive control (the kit lets him in now; see the developer guide §4).
- Learn myth cutscenes stay on the board; they also use `RivalTalk` for the rival puppet.

### 1.3 Gesture hints — how, never what (the goal: every Learn and Do level)

When the player seems stuck while the level waits for input — **~8 s with no touch**, or **3 taps on nothing within 4 s** —
an animated hand shows **how** to interact: **tap** (ripple), **hold** (a ring fills), **drag** (a short nudge with a trail),
**swipe**, or a **sweep** that glides over all the choices **without pressing any**. It never shows **what** the answer is:

- A sweep passes over every option the same way; a drag nudges the object a short way in a generic direction, never to the
  right target; a tap/hold hint goes only on a control that is the one way forward (a squeeze button, **এগিয়ে যান**), never on
  one of several answers.
- It plays twice, then the screen is idle again (zero frames); it may return after ~25 s, at most 3 times per waiting state.
  Any touch hides it at once. Reduced motion: a still hand with a soft fade. Not during the guide's intro (`GuideIntro`),
  voice-locked beats, cards, freezes or results.
- A sweep over a single card is no hint (it would point at the answer): with one open card left the deck shows none. Options
  outside the hint's box (a list's off-screen items) are left out. A page covered by another route shows no hand.
- **On a card preview** (§1.4) the hand sweeps over **both** buttons, ✕ বাদ দিন and ✓ বেছে নিন, as a pair — never over one
  alone, and not while the preview is still opening (its buttons are not armed yet). While a preview is open the level's own
  scene hint is off (`hintWaiting` false), so only one hand is ever on screen.
- **Wired now (2026-11-13):** every `ChoiceDeck` (reason and coworker decks) and its preview, every `CardPreviewOverlay`,
  the zoomed reason card's **এগিয়ে যান**, the Learn board's picture pick and reason chips (`_whyBoard`), and the Do levels'
  scenes (`FullSceneFrame(hint:, hintWaiting:, hintKey:, hintController:)` — all but `ten_sec_scan.dart`). **Not yet:** the
  text-deck `LearnRunnerPage`'s question list (its option preview has the pair sweep). A new Do level adds its scene hint
  and calls `missTap()` in its plain-tap branch (developer guide §4) before it ships.

### 1.4 Card picks — two steps, then Continue (every Learn and Do level)

Whenever the player chooses one card (or one of several buttons, chips or step cards) from options on screen, **a touch is
never an answer** (owner's brief 2026-11-12):

1. **Tap a card → it opens big** (a preview): its number or icon, its **full text** (scrolls inside if long), the deck's navy
   and gold, and two buttons — **✕ বাদ দিন** (key `choice-reject`) and **✓ বেছে নিন** (key `choice-confirm`). The buttons are
   the same for every card, so nothing about correctness shows. They take **no tap for 300 ms** (`ChoiceDeck.armDelay`), so a
   double tap on a card can't confirm it.
2. **✓ is the answer** — only ✓ evaluates, scores, strikes or lets the coworker in (`holdForCoworker()` runs on ✓, the
   committing move). **✕ sets the card aside:** dimmed (and struck on a `ChoiceDeck`), grey, not the red of a wrong card;
   nothing is answered and it can be opened and chosen later.
3. **Feedback waits for a Continue button.** The right reason zooms with **এগিয়ে যান**; a slip's `MistakeCard` waits for its
   button; the old Learn runner's result waits for **পরের প্রশ্ন**. Nothing a player must read closes by itself.

Use `ChoiceDeck` for text options; for a level's own pickers use `CardPreviewOverlay` + `CardAside` (`choice_deck.dart`,
developer guide §4). Scoring, strikes, coworker timing and progression stay exactly as they were for the single tap.

**Already two deliberate steps — leave as they are:** a free selection that a separate button commits (m4_service_plan's
papers, route and kit: select, then the board button "সব ঠিক, কাজ শুরু" / "এটা আনিয়ে নিই" / "এই পথেই টানব" / "গাড়িতে তুলি"; the culprit board's knob → card link,
judged only at "কেস বন্ধ"). **Not card picks — leave as they are:** physical "pick up this tool / do this" moves in the
scene (fire_choose tools, m2_comealong_pull, m2_crimp_steps, m3_conductor_joint, m3_meter_call, m3_service_drop,
m4_dtr_temp, m4_tree_cut).

## 2. Screen rules

- Header = **close · L<n> · ◆ · 💀 · 📖** (`LevelShellBar` / `UnifiedGameTopHud`: the ladder step, this level's score, the
  death count, the read-lesson book; + a clock only if the level is timed). **No speaker button** on the bar; the bar's
  fonts scale with the screen width (tests find the score from its ◆, never by font size). Lesson numbers are internal —
  never on screen.
- **No description or hint text on the scene.** Only labels a real worker would read (tool names on a stand,
  "ON/OFF" on a switch, "ABC/CO2" on a cylinder).
- The scene is the hero: controls appear only when needed (a squeeze button while spraying, the deck while choosing).
- Bangla first, UTF-8, `enDigits` for digits, words ডকেট · শাটডাউন · জল · গ্লাভস (AGENTS.md §6).
- Touch targets ≥ 48 dp; no overflow at 360 dp width; test a tall phone (the world gets more sky, not stretched).

## 3. Characters and voice

- **Master voice scripts & ledger:** All approved field-Bangla lines for the guide and the careless coworker are maintained in [LADDER_VOICE_SCRIPTS.md](LADDER_VOICE_SCRIPTS.md). Use it as the single source of truth for script reviews and voice generation.
- **The guide is always the existing mascot** (`AiLinemanGuide`). Never create another guide character.
- **The careless coworker** = level 1's rival: art `assets/duty_slip/dress/myth_rival_bad.webp`, puppet
  `MythRivalPuppet`, tag "অসাবধান লাইনম্যান", his lines in **his recorded voice** (`bn-BD-PradeepNeural`, −6 %,
  −14 Hz; clips `r_<sha1>.mp3` registered in `learnRivalVoice` and listed in `tool/dump_learn_voice_lines_test.dart`).
  Make only his clips directly; **never rerun `tool/make_learn_voice.py` wholesale** (it deletes clips missing
  from a fresh dump).
- **The guide's new lines use device TTS for now** (the owner records audio later). Keep every fixed line in
  the level's `*Lines` class so it can be recorded.
- The player's worker in the scene: `LinemanFigure(look: LinemanLook.trainee, …)` with its poses
  (idle, walk, hold, spray, throwIt, cheer, worried).

## 4. Questions and options

- Use **`ChoiceDeck`** (`choice_deck.dart`): level 1's cards — a sheet rises, numbered cards slide in one by one
  with card sounds, press under the finger, wrong shakes red, right pops green.
- **Every multi-card pick is two-step** (§1.4): tap → preview → ✓ `choice-confirm` answers / ✕ `choice-reject` sets
  aside; feedback stays until a Continue button. A level's own option buttons use `CardPreviewOverlay` the same way.
- **Deal 3 options: 1 right + 2 wrong** with `dealChoices(right, wrong, rng)` from **libraries**
  (≥ 2 right phrasings, ≥ 5 wrong) so plays don't repeat.
- **All options about the same length** (within 1.3×, enforced by a test) — the right one must not stand out.
- The right reason must **fit what the player actually did** (e.g. grass put out with ABC → an ABC reason).
- Wrong options are realistic field excuses or myths, never trick wording; right options state the lesson's rule.
- A wrong **reason** costs the table ◆, not a strike; strikes are for field mistakes.

## 5. Scene, motion and art

- Layers: sky/clouds → far (parallax ~0.35) → yard/equipment → effects → characters → controls.
  A camera may pan between spots (`AnimationController`, ease-in-out, a slight zoom-in, no dark edges).
- Effects: Lottie JSON generated by `tool/lottie_gen.py` → `assets/game/anim/`, played by `FxLoop` / `FxOnce` /
  `FxBeam` (`fire_fx.dart`). Drawn equipment in painters with gradients; SVG for static art.
- **An idle screen draws zero frames:** loops run only for a few seconds after a move (`AwakeClock`, `FxLoop`
  wake windows, `LinemanFigure` awake time), then hold a still frame. Reduce-motion → still frames, one-shots end at once.
- **Key every child of a Stack that comes and goes** (`ValueKey`): unkeyed `Positioned` siblings are matched by
  position, and removing one rebuilds the next ones from scratch (cards re-dealt, the mascot restarted).
- Sounds through `ZlFx.cue` only (AGENTS.md §1); reuse `sounds/learn/*`, `sounds/intro/*`; new short SFX may be
  synthesized as small mono WAVs.

## 6. Scoring and saving — call the existing functions, never invent

| What | Call |
|---|---|
| A move's points | `_levelDelta(n, origin)` → `BeatFx.levelDelta` (level score); combo via `Combo` |
| Mark | 100 − 15 × slips; pass ≥ 55 (Do levels) |
| End of play | `recordLevelResult` → `markRungCleared` (pass) → `commitLevelScore` → `recordBestTime` → `recordStars` (`game_save.dart`) |
| A slip | `strike(m)` (3rd → `recordStrikeOut` + `StruckOutCard`), `bookMistake` |
| Deadly | `bookDeadly` / `dieAndLeave` (`DoDeathGuard`), fall option C |
| The reason | `whyPayout(pending:, retried:)` — table pays; after a burn, a right retry pays 5 |

The UI shows only what was saved. A new kind of scoring event needs the owner's yes; otherwise keep it non-scoring.

## 7. Content accuracy and safety

- Show real PPE, real equipment, real procedures from the lesson. Equipment markings must be right
  (powder extinguishers say **ABC** where the rule needs ABC — IS 2190 cl. 10.1).
- Never reward an unsafe shortcut; never make a dangerous act look attractive.
- Flag anything the lesson does not support (write it in your report to the owner).

## 8. Building blocks

| Need | Use | File |
|---|---|---|
| Full-screen frame + header | `FullSceneFrame`, `SceneMetrics`, `cornerGuide` (or `LevelShellBar(bare: true)` alone) | `full_scene_frame.dart` / `level_shell.dart` |
| Success beat | `ReasonTable` mixin, `whyPayout`, `TablePill`, `tableBusy` (praise-window input gate) | `reason_table.dart` |
| Pressure moment | `CoworkerMoment` mixin, `CoworkerScript`, `CoworkerPeek`, `holdForCoworker`, `RivalTalk` | `coworker_moment.dart` / `mascot_speech_library.dart` |
| Gesture hint (how, not what) | `IdleHint`, `HintSpec` (tap/hold/drag/swipe/sweep), `FullSceneFrame(hint:, hintWaiting:)`, `IdleHintController` | `gesture_hint.dart` |
| Learn explainer | `LearnExplainerVideos`, `LearnVideoGatePage` | `learn_explainer_videos.dart` / `learn_video_gate.dart` |
| Guide first | `LevelIntro` / `GuideIntro` | `level_frame.dart` / `scene_kit.dart` |
| Guide strip + tap-to-repeat | `DoCoachStrip(tasks:, muted:)`, `TaskNudge` | `do_parts.dart` |
| Answers | `ChoiceDeck`, `ChoiceOption`, `dealChoices` | `choice_deck.dart` |
| Mistakes / deaths | `DoMistake`, `MistakeCard`, `openLessonPoint`, `bookMistake`, `DoDeathGuard` | `mistake_kit.dart` |
| 3 strikes | `DoStrikeOut`, `StruckOutCard`, `FailSound`, `kStrikesToFail` | `level_frame.dart` |
| Juice | `FreezeFrame`, `freezeFilter`, `RescueBurst`, `Combo`, `ComboPop`, `starsFor` | `level_juice.dart` |
| Order move | `OrderRun`, `OrderGroup` | `order_steps.dart` |
| Scene kit | `AwakeClock`, `LinemanFigure`, `LinemanLook.trainee` | `scene_kit.dart` |
| Effects | `FxLoop`, `FxOnce`, `FxBeam`, `FireAnim` | `fire_fx.dart` |
| Registry | `doGameFor(pack)` + `content_catalog.json` (`engineType`, `status: playable`) | `do_games.dart` |
| Result | `LevelPassPanel` / `LevelFailPanel` | `level_shell.dart` / `level_result_parts.dart` |

Keep the play logic pure (a `XRun` class with no widgets) so the rules are unit-tested.

## 9. Tests (every level)

- **Rules:** unit tests of the `XRun` logic — right/wrong/deadly per move, the deal, `whyPayout`.
- **Libraries:** one right per deal, three different options, plays differ; `expectSameLength` / `expectLibrary` (`test/support/option_lengths.dart`) for lengths within 1.3× and ≥ 2 right / ≥ 5 wrong.
- **Flow:** open the page, `waitIntro(t)` (`test/support/intro_wait.dart`), play to a pass; assert the save
  (cleared, no mistakes, stars) — not just the screen.
- **Mistakes:** a slip shows its card; a deadly move freezes first, then the card; 3 slips fail the level.
- **Guide:** no "শুরু", a tap does not skip; tapping the guide restates the task differently.
- **Coworker** (if any): appears once, from a random side; beat 1 caption alone, then guide ask + refuse/listen; the right card refuses him. `_pickRight` helpers must wait for `reason-proceed-btn` after a reason (coworker decks have no proceed).
- **Learn video** (if catalog id set): gate opens before the board; empty id skips the gate.
- **Card picks** (§1.4): pick through the preview with the helpers in `test/support/reason_proceed.dart` —
  `pickChoice(t, text)` (a `ChoiceDeck` card by its text, ✓, then **এগিয়ে যান** if a reason), `confirmChoice(t)` (taps
  ✓ on whatever preview is open, waiting out the 300 ms; returns false if none), `tapReasonProceed(t)` (✓ then the reason's
  proceed). Learn boards: `test/support/board_pick.dart`. Each converted picker has one test that a tap opens the preview
  and answers nothing, ✕ sets the card aside (`CardAside.aside`), and ✓ then scores as before.
- **Gesture hint** (if the level declares one): hints are off in widget tests (`FLUTTER_TEST`); a hint test sets
  `GestureHints.debugEnableInTests = true` (reset it in `tearDown`) and checks the hand appears only while the level
  waits, and a sweep/drag gives nothing away. Kit behaviour is covered by `test/gesture_hint_test.dart`.
- **Perf** (`test/perf` or in the level test): settle ~14 s (the mascot ends a breath lap after speaking), then
  < 20 rebuilds/s and < 12 frames in an idle second, with and without reduce-motion.
- Screenshots: a scratch test (`test/zz_*_test.dart`, `SHOT_DIR`, load Noto Sans Bengali) — look at every beat,
  then **delete the scratch test**.

## 10. Done means

1. `flutter analyze` clean · `flutter test` all green · `python -I tool/check_asset_refs.py .` exit 0.
2. Screenshots of every beat reviewed (intro, play, success + reason deck, slip, deadly, coworker, result).
3. Docs: the level's entry in GAME_DEVELOPER_GUIDE.md, its row in MODULE1_LADDER.md, new lines listed for recording.
4. Installed on the owner's phone when asked; **commit and push only when the owner asks** (on the feature branch).
5. Report: what changed, what was verified, what is not done, and any content you flagged.
