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
| 1 | **Guide first** | Full screen, the app's mascot says the task in **one short line**: what is wrong and how urgent ("সাবস্টেশনে আগুন! … এখনই নেভান!"). **No "শুরু" button, no skip, a tap does not skip** — the game starts when the voice and a fair reading time are done. | `LevelIntro` (`level_frame.dart`), or `GuideIntro` (`scene_kit.dart`) over a live scene |
| 2 | **The scene** | Full screen to the top and bottom (as level 1); the header floats on it. The scene is a **place**, not a page: layered background → midground → foreground, real equipment, the player's worker doing the work. | `LevelShellBar(bare: true)`, a world painter, `LinemanFigure` |
| 3 | **Guide in the corner** | Short lines with the **next task only** ("কী দিয়ে নেভাবেন?"). No hints, no answers, no pointing tours ("এটা? এটা? না এটা?"). | `AiLinemanGuide` in a corner, or `DoCoachStrip` |
| 4 | **Tap the guide** | He says the current task again, **a different way each time, never the answer**; tick sound; no cost. | `DoCoachStrip(tasks: XLines.tasks, muted: _muted)` + `TaskNudge`, or a level pool (`FireLines.tap*`) |
| 5 | **Hands-on** | Use the five moves (choose · inspect · spot · order · say no) and *do* the job where it fits: hold to spray, throw, drag, pull a switch. Equipment shows its real state (an isolator at **ON** that the player must switch **OFF**; a gauge to read). | level page + painters / Lottie |
| 6 | **Success like level 1** | Right action → right sound + animation + a short praise line (`LearnFeedbackLines.right`) + the ◆ **wait on the table** → "কেন এটা নিলেন?" with 3 cards → right reason pays the table into the score, wrong reason burns it, a right retry pays 5 → the level moves on **by itself** (no "পরেরটা" button). | `ChoiceDeck`, `whyPayout` |
| 7 | **Mistakes teach** | Hints appear **only after a mistake**: `MistakeCard` (picture + one line + **পাঠে দেখুন**). **3 slips** → the level fails with a fitting sound and the lesson card insists on reading before "আবার খেলি". Deadly → the scene freezes grey, the consequence plays in colour, then near-miss/death and the fall. | `DoStrikeOut`, `StruckOutCard`, `FailSound`, `DoDeathGuard`, `FreezeFrame` |
| 8 | **Pressure moment** | The careless coworker (level 1's rival) **peeps in from the left or right edge** at a random moment and pushes the shortcut in his own voice; then the **guide** puts the choice to the player (rotating phrasing) on a 3-card deck. Listening = the slip. | `CoworkerPeek` (now in `fire_choose.dart`; move it to a shared file when the second level uses it) |
| 9 | **Result** | Pass panel (rank, mark, time, ◆, "আজ যা ধরলেন", stars) or fail panel with পাঠ. | `LevelPassPanel`, `LevelFailPanel`, `starsFor` |

Every play is **dealt fresh** (order, traps, which tool is empty, who pushes and when) so it never repeats.

## 2. Screen rules

- Header = **ধাপ N · ◆ · 💀** (+ a clock only if the level is timed). Lesson numbers are internal — never on screen.
- **No description or hint text on the scene.** Only labels a real worker would read (tool names on a stand,
  "ON/OFF" on a switch, "ABC/CO2" on a cylinder).
- The scene is the hero: controls appear only when needed (a squeeze button while spraying, the deck while choosing).
- Bangla first, UTF-8, `enDigits` for digits, words ডকেট · শাটডাউন · জল · গ্লাভস (AGENTS.md §6).
- Touch targets ≥ 48 dp; no overflow at 360 dp width; test a tall phone (the world gets more sky, not stretched).

## 3. Characters and voice

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
| Header | `LevelShellBar(bare: true)` | `level_shell.dart` |
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
- **Libraries:** one right per deal, three different options, lengths within 1.3×, ≥ 5 wrong, plays differ.
- **Flow:** open the page, `waitIntro(t)` (`test/support/intro_wait.dart`), play to a pass; assert the save
  (cleared, no mistakes, stars) — not just the screen.
- **Mistakes:** a slip shows its card; a deadly move freezes first, then the card; 3 slips fail the level.
- **Guide:** no "শুরু", a tap does not skip; tapping the guide restates the task differently.
- **Coworker** (if any): appears once, from a random side; the guide asks; the right card refuses him.
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
