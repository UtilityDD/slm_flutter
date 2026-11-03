# Duty slip: মৃত্যুহীন পথ

The core game. Home → path intro → `DutySlipPage(startOnRoad: true)`, which opens straight on the ladder (`adventure_map.dart`). Target design: [`GAME_DESIGN.md`](../../../GAME_DESIGN.md). Level rules and level ideas: [`GAME_LEVELS_GUIDE.md`](GAME_LEVELS_GUIDE.md).

Edit Bangla here in the editor only. PowerShell `Set-Content` corrupts it.

## The ladder

- Rungs come from `assets/game/catalog/content_catalog.json` through `lib/features/game/ladder_builder.dart`: 10 modules, 327 rungs (Learn, Do, rank gate), soft cap 400. Today only 10 Learn rungs are `playable`; the rest are `comingSoon`.
- A playable Learn rung opens `LearnRunnerPage` (swipe cards + 2 questions, never a fall). Clearing it unlocks the next rung.
- Rung index `i < 33` is also bridged to the old fixed level `dsLevels[i]`, so those 33 levels stay playable.
- Side stations repeat every 8 rungs (only on rungs 1–33): tips, hourly quiz, identify quiz, gift, life tip, lesson (`TrainingScreen`).
- Locked rung: shake + mist, no text. Unlock is one at a time. `dsAllLevelsOpen` is `false`; admins can open everything with `devLevelsOpen` (Admin → developer mode).

## The 33 levels (`dsLevels` in `duty_slip_engine.dart`)

| Levels | Game | File |
|---|---|---|
| 1–10 | Dress-up and van jobs: drag the right kit onto the lineman or van | `ds_dress_up.dart` |
| 11–13 | Pole check before climbing (normal PCC, hollow PCC, steel pole) | `ds_pole_inspect.dart` |
| 14 | Safe clearance and crowd barrier | `ds_clearance.dart` |
| 15–22 | SAFE HOME 8-step cards: 2 / 4 / 6 / 8 choices, then the same living | `duty_slip_page.dart` |
| 23–32 | 23-step job: 2 / 4 / 6 / 10 / 23 choices, then the same living | `duty_slip_page.dart` |
| 33 | Field night: docket, PTW, PPE, tools, site calls | `duty_slip_page.dart` |

`dressLevel` is `level.isLetters && level.number <= 14`. Level 4 (হারনেস) is a tap-in-order checklist today.

**Living:** a wrong tap swaps in unused far decoys and reshuffles. All-option living levels only reshuffle.

## Files

| File | Role |
|---|---|
| `duty_slip_engine.dart` | Level specs, SAFE HOME deck (`dsSafeHome`), briefs (`dsBriefFor`), scoring, living rebuild, field night, unlock |
| `duty_slip_models.dart` | Plan items, sites, PTW / kit / match steps, loads `assets/data/duty_slip_job.json` |
| `duty_slip_page.dart` | Ladder host, briefing, card quiz, result medal, field docket, HUD, `DsMotionGate` (frame-time motion tier) |
| `adventure_map.dart`, `adventure_scenery.dart` | The ladder and its world layers |
| `ds_dress_up.dart`, `ds_pole_inspect.dart`, `ds_clearance.dart` | Interactive levels 1–14 |
| `duty_slip_voice.dart` | `DsVoice`: Bangla line → clip in `assets/sounds/voice/` (generated, see `AUDIO_DEVELOPMENT_GUIDE.md`) |

## SAFE HOME

| Letter | id | Bangla |
|---|---|---|
| S | stop | থামো ও বিপদ খুঁজো |
| A | armour | কবচ পরো |
| F | form | পারমিট নাও |
| E | end | দুদিক কাটো |
| H | hold | আর্থ করো |
| O | ok | ফিতে ঘেরো |
| M | mend | কাজ সারো |
| E | exit | গুনে ফিরো |

Letters S A F E H O M E appear only on the briefing list. Quiz cards are Bangla text only: no letters, no serials.

## 23-step job

Spine in `duty_slip_job.json`: ডকেট পড়ুন → PTW নিন → PPE দেখে নিন → টুল বেছে নিন → সাইটে চলে যান → সব PPE পরে নিন → নিজেদের মধ্যে আলোচনা → বিপদ খুঁজে দেখুন → PTW মিলিয়ে দেখুন → ব্যারিকেড করে নিন → শাটডাউন নিন → ডিসচার্জ করুন → দুই মাথায় আর্থ → LOTO → কাজ শুরু করুন → সঠিক টুল → কাজ শেষ → টুল ও PPE নামিয়ে নিন → সবাই এক জায়গায় আসুন → শাটডাউন তুলে নিন → বিদ্যুৎ ফিরল কিনা দেখুন → PTW ফেরত দিন → মিশন কমপ্লিট.

Sites: রাস্তায় / পুকুর পাড়ে / ধানক্ষেতে. Clock starts 20:10.

## Scoring and ranks

- Correct **+5**, wrong **−5**. Streak gift **+5** every 6 correct.
- The clock counts and never closes a level.
- HUD: time + this-level score large + night total small. The HUD clock ticks once a second and pauses in the background.
- Ranks come from wrong taps + time, not streak: **দারুণ / মোটামুটি / আবার**.
- 8-step deck: দারুণ ≤1 wrong and in time; মোটামুটি ≤2; আবার 3+. 23-step deck: দারুণ ≤3 wrong and in time; মোটামুটি ≤7; আবার 8+.
- আবার does not add the level score to the night total.
- Field night has its own grade: **সেফ / ঝুঁকি ছিল / আনসেফ**. A lethal miss plays `accident.wav`.

## Copy rules

- Western digits `0–9` everywhere (`enDigits`). Never Bangla digits on clocks or scores.
- **ডকেট**, **শাটডাউন**, **জল** (never পানি), **গ্লাভস** (never দস্তানা).
