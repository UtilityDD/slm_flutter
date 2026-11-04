# মৃত্যুহীন পথ (The Zero-Death Path) — Unified Developer Guide & Collaborator Roadmap

> **Single Source of Architectural & Implementation Truth for All Collaborators**  
> Read this guide before adding or editing any **Learn card**, **Do field level**, **Touchable side item**, **Mascot speech**, or **Scoring animation**.

---

## 1. Core Philosophy: One Seamless Game, Zero Textbook Reading

The **মৃত্যুহীন পথ** app is not a traditional classroom app with separate textbook tabs, quiz pages, and mini-game scores. Everything happens inside **one continuous vertical climb** toward the Emerald at the top of the ladder:

1. **No Textbook Reading**: Players are West Bengal distribution linemen and helpers playing outdoors in short 1–2 minute breaks. Long text walls are forbidden. Every `Learn` rung is an interactive deck of **Field Flash-Cards** (`1–2` punchy lines of natural field Bangla, spoken aloud by the Mascot, with a 1-tap pre-work habit check and 2 quick-fire field decisions).
2. **One Unified Score (`◆` Points & `💀` Deaths)**:
   - There are **no separate level scores**, no `nightTotal`, no `playClock` timers in the HUD, and no old `দারুণ / মোটামুটি / আবার` end-of-level result boards.
   - Every positive action across **Ladder Side Items**, **Learn Cards**, and **Do Field Drills** fires a glowing flying score chip (`ScoreFlyHost`) from the exact finger tap (`originGlobal`) along a parabolic arc straight into the top `◆` counter, accompanied by synthesized musical chords (`ZlFx.cue`) and tactile haptics.
3. **One Unified Mascot ("ওস্তাদ লাইনম্যান" — `AiLinemanGuide`)**:
   - The Ladder Mascot and the `Do` Field Coach are **the exact same character** (`AiLinemanGuide`) with real-time lip-sync (`MascotTalk.active`).
   - All spoken lines, pro-tips, riddles, praises, and lethal warnings live in **one central library**: [`lib/features/guide/mascot_speech_library.dart`](lib/features/guide/mascot_speech_library.dart).
4. **Natural West Bengal Field Bangla**:
   - Speak like a caring senior `ওস্তাদ` (Ustad) on the field.
   - Keep everyday English electrical/field terms natural in Bangla script or English: **PTW, Shutdown, Docket, Earthing, Jumper, LOTO, PPE, Gloves, Harness, Helmet, 11 kV, LT, HT, DTR, Clamp Meter, Fuse, Isolator**.
   - Never use artificial/bookish translations (use `গ্লাভস`, never `দস্তানা`; use `জল`, never `পানি`; use `ডকেট` and `শাটডাউন`).
   - Always render numbers in Western digits `0–9` via [`enDigits()`](lib/core/en_digits.dart).

---

## 2. System Architecture & Key File Map

```
lib/
├── core/
│   └── en_digits.dart                   # Enforces 0-9 Western digits across all Bangla UI
├── features/
│   ├── game/
│   │   ├── content_catalog.dart         # Loads assets/game/catalog/content_catalog.json (10 Modules, 109 Lessons, 327 Rungs)
│   │   ├── ladder_builder.dart          # Builds ordered LadderRung list (Learn -> Do -> Do -> ... -> Gate)
│   │   ├── game_save.dart               # Single source of truth for ◆ points, 💀 deaths, passedRungs, promises, ScorePulse
│   │   ├── beat_fx.dart                 # UnifiedGameTopHud + ScoreFlyHost (parabolic flying ◆ chips) + DeathMomentHost
│   │   └── learn_runner.dart            # Interactive Learn Flash-Card deck + 1-tap habit check (+5 ◆) + 2-Q Exit Drill (+10 ◆)
│   ├── guide/
│   │   ├── mascot_speech_library.dart   # CENTRAL SPEECH & CHALLENGE LIBRARY + MascotTalk lip-sync notifier + TTS/MP3 router
│   │   ├── ai_lineman_guide.dart        # Unified Mascot renderer (7 moods, animated lip-sync mouth, Midnight-Navy speech bubble)
│   │   ├── guide_director.dart          # State machine driving Mascot cues on Ladder, Learn, and Do screens
│   │   └── ladder_guide_host.dart       # Corner dock & centre hero-stage overlay for the Mascot on the Ladder
│   ├── duty_slip/
│   │   ├── adventure_map.dart           # Main 327-rung Ladder screen + In-Ladder Touchable Side Item overlay (_SideChallengeOverlay)
│   │   ├── duty_slip_page.dart          # Real-work Do engine host (Unified HUD, direct ◆ scoring, auto-return to Ladder on clear)
│   │   ├── duty_slip_engine.dart        # Do level definitions (dsLevels 1..14 active, 15..31 planned)
│   │   ├── duty_slip_voice.dart         # Pre-generated Edge-TTS neural MP3 lookup table (DsVoice)
│   │   ├── ds_dress_up.dart             # Shared flat-2D shelf widgets (DsFlatShelf, DsShelfToken) + DsCoach -> AiLinemanGuide adapter
│   │   └── GAME_LEVELS_GUIDE.md         # Detailed visual & pedagogical specs for Do Levels 1-31
│   └── zero_loss/
│       └── zero_loss_fx.dart            # Synthesized sound effects (ZlFx.cue: coin, win, warn, buzz, combo, fanfare)
└── assets/
    ├── game/catalog/content_catalog.json # Master 10-Module, 109-Lesson, 327-Rung curriculum definition
    └── audio/duty_slip/                 # Pre-generated Edge-TTS neural Bangla MP3 clips
```

---

## 3. Non-Negotiable UI & UX Standards

### 3.1. The Unified Top HUD (`UnifiedGameTopHud`)
Every game screen (**Ladder**, **Learn Runner**, and **Do Field Drill**) shows the exact same compact single-row top bar:
```
[ ← ]   [ 🛡 Rank / Rung Pill ]      [ ◆ 1,240 ]   [ 💀 3 ]   [ 🔊 ]
```
- **Never** add a second score box, level score counter, or countdown clock to the top bar.
- Wrap the screen body in [`ScoreFlyHost`](lib/features/game/beat_fx.dart) and pass `_scorePillKey` to both `ScoreFlyHost` and `UnifiedGameTopHud` so flying score chips land directly on the `◆` counter.

### 3.2. Awarding or Deducting Points (`BeatFx.scoreDelta`)
Whenever a player earns or loses points in **any** mode:
1. Capture the tap position (`details.globalPosition` or widget RenderBox center) as `Offset? originGlobal`.
2. Call:
   ```dart
   await BeatFx.scoreDelta(
     ref,
     delta, // e.g., +5, +10, +15, +20, or -5
     reason: 'learn_card_check',
     originGlobal: originGlobal,
   );
   ```
3. `BeatFx.scoreDelta` automatically:
   - Updates `GameSave.points` in `SharedPreferences`.
   - Emits a `ScorePulse` with `originGlobal`.
   - Triggers `ScoreFlyHost` to launch a glowing gold (`+◆`) or crimson (`-◆`) chip along a parabolic bezier curve into the top HUD `◆` pill, playing `ZlFx.cue('coin')` or `ZlFx.cue('warn')` and pulsing the `◆` counter on impact.

### 3.3. What Counts as a Death (`💀`) vs. Point Loss (`-◆`)
| Event | Consequence | Never Do This |
|---|---|---|
| Wrong answer on a `Learn` exit question | `-5 ◆` flying red chip + Mascot explains the rule | **Never** trigger a death (`💀`) or ladder fall in a `Learn` rung |
| Wrong answer on a Ladder Side Item riddle | Mascot gives a gentle hint (`+2 ◆` for trying) | **Never** deduct points or cause a death on side items |
| Non-lethal mistake in a `Do` level (e.g., wrong pocket item or minor order slip) | `-5 ◆` to `-15 ◆` flying red chip + Mascot warning | Do not kill the player for non-lethal slips |
| **Lethal mistake in a `Do` level or Rank Gate** (e.g., touching un-earthed HT line, climbing rotten pole without check, bare-handing live conductor) | `DeathMomentHost.trigger()` → screen crack + heartbeat + `💀 +1` + fall to current Module checkpoint | Never reset the player all the way to Rung 0 of Module 1 |

---

## 4. Collaborator Workflows (How to Build & Extend)

### Workflow A: Adding or Editing Mascot Speech & Voice (`mascot_speech_library.dart`)
All Mascot dialogue is centralized in [`lib/features/guide/mascot_speech_library.dart`](lib/features/guide/mascot_speech_library.dart).
1. **To add a new cue**:
   - Add an enum value to `MascotCueId` (if it's a fixed situational cue) and register its `MascotCue` in `MascotSpeechLibrary._cues`.
   - Write `voiceBn` (full natural spoken line, 1–2 sentences) and `bubbleBn` (short 1–2 line text for the Midnight-Navy bubble, max ~65 characters).
2. **To speak a cue with lip-sync**:
   - Call `MascotSpeechLibrary.speak(text, muted: isMuted)` or `guideDirector.sayCue(MascotCueId.xyz, speakVoice: !isMuted)`.
   - `MascotSpeechLibrary.speak()` first checks `DsVoice` for a pre-generated neural `.mp3` clip; if found, it plays the MP3 and drives `MascotTalk.active`. If no MP3 exists yet, it falls back seamlessly to `FlutterTts` (`bn-IN`) while still animating the Mascot's mouth!
3. **To generate offline neural `.mp3` clips for new Bangla lines**:
   - Run the Python Edge-TTS generator script:
     ```bash
     python tool/update_duty_slip_voice_dart.py
     ```

### Workflow B: How `Learn` Rungs Work & How to Improve Lesson Cards
[`LearnRunnerPage`](lib/features/game/learn_runner.dart) automatically transforms any lesson in `training_chapters` (or its offline fallback) into a 60-second interactive game:
1. **Card Phase**:
   - Each key point is converted via `MascotSpeechLibrary.conciseFieldRule()` and `toNaturalFieldBangla()` into a concise field card (max 2 short lines on front; full specifications hidden behind `"বিস্তারিত স্পেসিফিকেশন"`).
   - The Mascot automatically reads the card aloud with lip-sync.
   - The player taps **`"কাজের আগে চেক করুন (+5 ◆)"`** on each card to verify the field habit and launch a `+5 ◆` chip into the HUD before advancing.
2. **Exit Drill Phase**:
   - 2 multiple-choice field decision questions from `assets/quizzes/questions_{M}_{L}.json` (or synthesized from the lesson points if the JSON is empty).
   - Correct tap = `+10 ◆` flying chip + Mascot celebration. Wrong tap = `-5 ◆` chip + Mascot coaching note.
3. **Completion**:
   - Marks `{lessonId}/learn` passed in `GameSave`, awards `+20 ◆` completion burst, and climbs to the next rung on the Ladder.

### Workflow C: Adding or Customizing Touchable Side Items on the Ladder
Side items (`_Station` props alongside the ladder in [`adventure_map.dart`](lib/features/duty_slip/adventure_map.dart)) must **never** push separate legacy screens (`QuizPlayScreen`, `IdentifyQuizScreen`, `TrainingScreen`).
- When tapped, `_openStation` opens `_SideChallengeOverlay` right over the ladder.
- The content comes from `MascotSpeechLibrary.challengeForSideItem(kind, seed: rungIndex)`:
  - **PPE Props (`helmet`, `gloves`, `harness`, `boots`, `vest`, `lock`, `rope`, `cone`, `goggles`)**: Mascot speaks a pro-tip + player taps `"কথা দিলাম (+5 ◆)"` or answers a 2-option check (`+10 ◆`).
  - **Mystery Chest (`gift`)**: 2-option field safety riddle (`+15 ◆`).
  - **Quick Spotter (`identify`, `hourly`)**: Rapid hazard/equipment question (`+10 ◆`).
  - **Golden Rule (`life`, `lesson`)**: 1-sentence life-saving mantra + promise (`+10 ◆`).
- Station rewards are tracked via `passedRungs.contains('station_${st.rung}')` so each station awards points once.

### Workflow D: Building a New `Do` Real-Work Level (Levels 15–31+)
When building a new `Do` level in [`lib/features/duty_slip/`](lib/features/duty_slip/):
1. **Visual Layout (No-Overlap 3-Zone Rule)**:
   - **Top**: Unified HUD (`_Hud` in `duty_slip_page.dart`) + `AiLinemanGuide` coach row (`DsCoach`).
   - **Center (62%–68% height)**: Interactive work stage (real field photo with normalized `0.0..1.0` hotspots or 2D animated pole/DTR/kit scene). **Zero permanent text labels on objects.**
   - **Bottom (118–136 px)**: `DsFlatShelf` with `DsShelfToken` flat 2D icons (`showLabel: false` until tapped).
2. **Scoring & Voice Integration**:
   - Call `widget.onDelta(points, 'reason')` for every correct step (`+15` to `+25`) or non-lethal mistake (`-10` to `-15`). `DutySlipPage` routes this directly into `BeatFx.scoreDelta` and the top HUD `◆` counter.
   - Use `DsVoice.Line` (or `MascotSpeechLibrary.speak`) so `AiLinemanGuide` speaks with live lip-sync.
3. **Completion & Lethal Failures**:
   - On level clear, call `widget.onFinish(clean: mistakes == 0)`. `DutySlipPage` awards the `+20 ◆` clear bonus, marks the `Do` rung passed, and pops back to the Ladder so the lineman climbs up!
   - On a **lethal error** (e.g., touching live wire without earthing/shutdown), trigger `DeathMomentHost.trigger` so `💀` increments and the lineman falls to the Module checkpoint.

---

## 5. Master Collaborator Roadmap & Level Matrix

### Phase 1: Core Gamified UX & Unification (✅ COMPLETED)
- [x] **327-Rung Content Catalog & Ladder Builder** (`10 Modules`, `109 Lessons`, `Learn + 2 Do` per lesson + `10 Rank Gates`).
- [x] **Unified Top HUD (`UnifiedGameTopHud`) & Parabolic Flying Score FX (`ScoreFlyHost`)** across Ladder, Learn, and Do.
- [x] **Unified Mascot (`AiLinemanGuide`) + Lip-Sync (`MascotTalk`) + Speech Library (`mascot_speech_library.dart`)** replacing separate `DsCoach` and static corner avatars.
- [x] **Interactive `LearnRunnerPage`** with concise Bangla flash-cards, `+5 ◆` pre-work habit checks, offline fallback deck, and `+10 ◆ / -5 ◆` exit drill.
- [x] **In-Ladder Touchable Side Items (`_SideChallengeOverlay`)** keeping players inside the ladder climb.
- [x] **Unified `Do` Engine (`DutySlipPage`)** wired to live `◆` / `💀` HUD and auto-returning to the Ladder on clear.
- [x] **Active `Do` Levels 1–14** (`dsLevels` in `duty_slip_engine.dart`).

### Phase 2: Real-Photo Lesson `Do` Levels 15–31 (🚧 NEXT FOR COLLABORATORS)
Full visual specifications, hotspot coordinates, and voice scripts for Levels 15–31 are documented in [`lib/features/duty_slip/GAME_LEVELS_GUIDE.md`](lib/features/duty_slip/GAME_LEVELS_GUIDE.md). Collaborators can claim and build these levels in parallel:

| Level # | Code ID | Target Lesson | Game Archetype | Asset Folder (`assets/images/lesson_M_L/`) | Status |
|---|---|---|---|---|---|
| **1–14** | `L0`–`L8` | Core PPE, Pole, Shutdown, 8-Mantra, Crowd, Full Night | Dress-up, Pole Inspect, Sequence, Spot | Built-in custom painters + kit assets | ✅ Active |
| **15** | `L15_PPE_INSPECT` | Module 1 · Lesson 2 (`1.2`) | Photo Defect Spotter (Cracked Helmet, Torn Glove, Worn Boot) | `lesson_1_2/` | 📋 Spec Ready |
| **16** | `L16_VOLT_GLOVE` | Module 1 · Lesson 3 (`1.3`) | Voltage-to-Glove Rating Match + Air-Leak Roll Test | `lesson_1_3/` | 📋 Spec Ready |
| **17** | `L17_HARNESS_BELT` | Module 1 · Lesson 4 (`1.4`) | Full-Body Harness vs Waist Belt + Double Lanyard Anchor | `lesson_1_4/` | 📋 Spec Ready |
| **18** | `L18_EYE_FACE` | Module 1 · Lesson 5 (`1.5`) | Task-to-Visor/Goggle Match (DO Fuse Arc vs Tree Trimming) | `lesson_1_5/` | 📋 Spec Ready |
| **19** | `L19_BOOT_TEST` | Module 1 · Lesson 6 (`1.6`) | Footwear Nail/Crack/Oil X-Ray Scanner | `lesson_1_6/` | 📋 Spec Ready |
| **20** | `L20_POLE_360` | Module 2 · Lesson 1 (`2.1`) | Real Photo 360° Pole Hazard Hunt (Hornet, Earth Wire, Stay, Crack) | `lesson_2_1/` | 📋 Spec Ready |
| **21** | `L21_LADDER_SETUP` | Module 2 · Lesson 2 (`2.2`) | `4:1` Ladder Angle Slider + Base Soil + Top Lash Rope | `lesson_2_2/` | 📋 Spec Ready |
| **22** | `L22_CLIMB_TECH` | Module 2 · Lesson 3 (`2.3`) | 3-Point Contact Rhythm Climb + Obstacle Bypass Lanyard Transfer | `lesson_2_3/` | 📋 Spec Ready |
| **23** | `L23_POLE_TOP_POS` | Module 2 · Lesson 4 (`2.4`) | Minimum Approach Distance (MAD) Safe Work Zone Arc | `lesson_2_4/` | 📋 Spec Ready |
| **24** | `L24_TOOL_HOIST` | Module 2 · Lesson 5 (`2.5`) | Hand-Line Canvas Bucket Hoist (Never Throw Tools / Never Climb with Tools) | `lesson_2_5/` | 📋 Spec Ready |
| **25** | `L25_METER_ID` | Module 9 · Lesson 1 (`9.1`) | Smart Meter Terminal, Optical Port & Tamper Seal Inspector | `lesson_9_1/` | 📋 Spec Ready |
| **26** | `L26_METER_CHANGE` | Module 9 · Lesson 2 (`9.2`) | 7-Step Safe Smart Meter Replacement Sequence | `lesson_9_2/` | 📋 Spec Ready |
| **27** | `L27_CLAMP_METER` | Module 10 · Lesson 1 (`10.1`) | Clamp Meter Selector Dial (`A~`, `V~`) & Single-Wire Jaw Clamp | `lesson_10_1/` | 📋 Spec Ready |
| **28** | `L28_DTR_LOAD` | Module 10 · Lesson 2 (`10.2`) | 3-Phase (`R-Y-B-N`) Load Balancing Diagnostic | `lesson_10_2/` | 📋 Spec Ready |
| **29** | `L29_CABLE_JOINT` | Module 10 · Lesson 3 (`10.3`) | Insulation Resistance (Megger) & Crimping Sequence | `lesson_10_3/` | 📋 Spec Ready |
| **30** | `L30_HT_DO_FUSE` | Module 10 · Lesson 4 (`10.4`) | 11 kV DO Fuse Operating Rod + Arc Shield + Windward Stance | `lesson_10_4/` | 📋 Spec Ready |
| **31** | `L31_EMERGENCY_RESCUE` | Module 7 · Lesson 1 (`7.1`) | Pole-Top Shock Rescue + Golden 4-Minute CPR Rhythm | `lesson_7_1/` | 📋 Spec Ready |

### Phase 3: Catalog Engine Registry & Module 3–8 Expansion
- [ ] **Catalog `engineType` Router**: Map `CatalogGamePack.engineType` in `adventure_map.dart` directly to the modular scene builders (`dress_up`, `pole_inspect`, `photo_spot`, `sequence_8`, `meter_swap`, `clamp_test`, `rescue_cpr`) so adding a new level requires only a JSON entry in `content_catalog.json`.
- [ ] **Rank Gate Boss Scenes (`1.gate` – `10.gate`)**: Multi-stage night-storm duty scenarios combining all habits from the module, awarding the **মৃত্যুহীন** (Zero-Death) crest on the rank badge if cleared with `0` module deaths.
- [ ] **Promise Recall & Death Log (`কেন মারা গেলাম`)**: Surface broken promises on the fall screen and turn past lethal mistakes into targeted recall side items on the ladder.

---

## 6. Quick Pre-Commit Checklist for Collaborators

Before opening a PR or committing changes, verify:
1. **UTF-8 Integrity**: Did you edit Bangla files using an IDE / editor tool (never PowerShell `Set-Content`)?
2. **Western Digits**: Are all visible numbers wrapped in `enDigits()`?
3. **One HUD / One Score**: Does your screen or level use `UnifiedGameTopHud` / `BeatFx.scoreDelta` with `originGlobal` instead of local score counters?
4. **One Mascot**: Does your feature use `AiLinemanGuide` (or `DsCoach`) backed by `MascotSpeechLibrary` with live lip-sync (`MascotTalk.active`)?
5. **Zero Analyzer Errors**: Run `flutter analyze` and confirm zero errors in modified files.

