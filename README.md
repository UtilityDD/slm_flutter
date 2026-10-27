# SmartLineman (`slm_flutter`)

Flutter app for West Bengal distribution linemen. Bangla-first. Sister of the web site [smartlineman.in](https://smartlineman.in). Package name `slm_flutter`; Android application id `com.smartlineman.app.slm_flutter`; on-device label is still `slm_flutter` until the launcher string is renamed.

This is **not** `slm-web`. Game loops, duty-slip levels, and copy live here.

## What the app is

A field-training companion: SAFE HOME mantras, PPE, identify-the-gear library, hourly quizzes, life-skill lessons, ranks, emergency numbers, and the core field breakdown & maintenance duty path called **মৃত্যুহীন** (duty slip). Home also still has the older **জিরো লস** storm-feeder sim in code.

Audience: linemen on Android phones, often offline-ish. Large posters and some lesson media stream from `https://www.smartlineman.in` so the APK stays smaller.

## Stack

| Piece | Choice |
|---|---|
| UI | Flutter, Material 3, cream/amber brand |
| State | Riverpod 3 |
| Auth / points / leaderboards | Supabase (`wkunyvomogeazjwtenck`) |
| Local persistence | `shared_preferences` |
| TTS | `flutter_tts` (Bangla lesson read-aloud) |
| STT | `speech_to_text` (login / speech) |
| Audio | `audioplayers` (cues + SLM Radio stream) |
| Navigation | Named routes inside `MainShell` (not go_router at runtime; the package is in pubspec) |
| Fonts | Noto Sans Bengali 400–700 bundled |

## Run

Primary device in this project: Oppo CPH2467, adb id `f6650cdf`.

Gradle wrapper is **9.3.1**. Wrapper download often times out; use a populated `GRADLE_USER_HOME` and offline:

```powershell
$env:Path = "C:\Users\rouma\flutter\bin;" + $env:Path
$env:GRADLE_USER_HOME = "$env:USERPROFILE\.gradle"
$env:GRADLE_OPTS = "-Dorg.gradle.offline=true"
flutter run -d f6650cdf --no-pub
```

Do not use PowerShell `Set-Content` for Bangla JSON or Dart — it mojibakes. Edit those files in the editor.

## Bottom tabs

1. **হোম / Home** — header, **মৃত্যুহীন** card, lineman hero carousel
2. **পরিচিতি / Identify** — safety library + charts
3. **র‍্যাঙ্ক / Rank** — monthly boards (Champion / New / Improved / Learner)
4. **লাইফ স্কিল / Life Skill** — 13 local lessons

A notched dock floats over pages. **SLM Radio** can sit above it.

## মৃত্যুহীন (duty slip) — core field duty path (day / night)

Home button text is **মৃত্যুহীন** only. Cover title **কাজের ধাপ**. Ladder header **মৃত্যুহীন পথ**. Next-level button **পরের লেভেল** (returns to the wooden ladder). No সহজ/কঠিন.

### 19-level path

| Levels | What you play | দারুণ time |
|---|---|---|
| 1–5 | Dress the lineman (clothes, helmet, gloves, harness, full kit) | 150 / 80 / 100 / 180 / 200 s |
| 6–8 | SAFE HOME cards, 4 / 6 / 8 choices, living | 70 / 85 / 100 s |
| 9–13 | 23-step night job, 2 / 4 / 6 / 10 / all | 75 / 105 / 150 / 180 / 240 s |
| 14–18 | Same job, living (a miss reshuffles) | 70 / 95 / 135 / 160 / 210 s |
| 19 | field night | docket / PTW / PPE / tools / calls |

**Dress (1–5), latest.** Intro shows only the level name. The picture sits under the title. The character in the bottom-left says the sentence. Play is drag-onto-the-body: right +5, wrong −5, and a miss reshuffles the shelf. The clock counts and never closes the level. One miss can still be দারুণ inside the time above.

1. **পোশাক** — cotton full shirt, full pant, safety shoes.
2. **মাথায় হেলমেট** — electrical helmet. The গামছা starts on his head and comes off first.
3. **হাতে গ্লাভস** — rubber electrical gloves. Say **গ্লাভস**, never দস্তানা.
4. **হারনেস** — gloves come off, the harness is dragged once into the hand, then the checklist is tapped. Last step is the two-finger check. The brown belt is the trap.
5. **পুরো কিট** — shirt, pant, shoe, harness, helmet, face shield, gloves, in that order. The গামছা is refused.

On a pass the lineman stays and glows, then the character springs into his place. The score page waits until that line has finished.

**Living:** after a wrong tap, decoys change (prefer unused far distractors) and the set reshuffles. All-option living levels only reshuffle order.

**Review sheet** (before play): still docket, not a deal/shuffle. Header **কাজের ধাপগুলো দেখে নিন**. SAFE HOME letters (S A F E H O M E) only here. Quiz cards are Bangla text only — no letters, no serials.

**SAFE HOME** (Bangla on the gold plates; letters S A F E H O M E only on the 1–8 briefing list):

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

Full play/briefing notes: `lib/features/duty_slip/README.md`.

**23-step job spine** (`assets/data/duty_slip_job.json`): ডকেট পড়ুন → PTW নিন → PPE → টুল → সাইটে চলে যান → PPE পরুন → আলোচনা → বিপদ → PTW মিলান → ব্যারিকেড → শাটডাউন → ডিসচার্জ → দুই মাথায় আর্থ → LOTO → কাজ শুরু → সঠিক টুল → কাজ শেষ → টুল ও PPE নামান → সবাই এক জায়গায় → শাটডাউন তুলে নিন → বিদ্যুৎ ফিরল কিনা → PTW ফেরত → মিশন কমপ্লিট.

Sites: রাস্তায় / পুকুর পাড়ে / ধানক্ষেতে. Clock starts 20:10.

### Scoring and ranks (duty slip)

- Correct tap **+5**, wrong **−5**. Streak gift **+5** every 6 correct.
- Clock **counts** and **never closes** a level.
- HUD: header time + **this-level score large** + **night total small**.
- Ranks from wrong taps + time, not streak points: **দারুণ / মোটামুটি / আবার**.
- আবার does not bank into night total. Sequential unlock is off while **`dsAllLevelsOpen`** in `duty_slip_engine.dart` is `true` (all 19 plates playable for testing). Set `false` before release.
- Result medal shows the number only, centered in the well.
- Briefing is two pages: title + list, then body on its own page. Same floating next arrow.
- Two-choice never uses previous+next as the only wrong card (prefer far distractors).
- Field night (level 19) is the live docket / PTW / PPE / tools / phone-call job. Clock in drills is 1× play; job clock 20× is paused in drills.

### Bangla copy rules

- Docket / shutdown wording as **ডকেট** and **শাটডাউন**
- Water is **জল**, never পানি
- Rank words: **দারুণ / মোটামুটি / আবার** (not চলবে / রেডি)

## Other features

- **Identify** — PPE, tools, insulators, AB cable, UG cable photos, how-to charts (helmet, harness, fuse SWG, clearances, gloves, discharge rod, ACSR names, cable mm²).
- **Hourly quiz** — `hourly_quiz_pack.json`; answers scored on Supabase via `submit_flutter_hourly_quiz` (keys never ship in the APK).
- **Identify quiz** — photo pick from the library.
- **Training ladder** — modules from Supabase + `supplementary_modules.json`; hero figures `lineman_00`…`lineman_10`.
- **Life skill** — 13 Bangla lessons in `assets/data/life_skill/`.
- **জিরো লস** — older storm-feeder dispatch sim (`zero_loss_*`). Still in `lib/features/zero_loss`. Home now opens duty slip instead.
- **SAFE HOME quiz** — lighter snapped-conductor quiz (`safe_home_snapped.json`), separate from the 19-level climb.
- **SOPs** — PPE checklist + 8 মন্ত্র.
- **Emergency** — West Bengal district numbers.
- **More** — story, prizes, FAQ, radio, share, login. Several rows are still placeholder `FeaturePage`s.

## Lineman ranks (hero)

Trainee → Junior → Technician → Skilled → Advanced → Senior → Supervisor → Specialist → Expert → Safety Pro (`lineman_01`…`lineman_10`, plus `lineman_00_start`).

## Layout

```
lib/            Dart app
assets/         Bundled json, photos, fonts, wav
android/        Phone target (primary)
ios/ linux/ macos/ windows/ web/   Other Flutter shells
supabase/       Hourly scoring SQL
tool/           Asset / pack scripts (not shipped)
test/           Engine tests
```

Every meaningful folder has its own README.

## Product / engineering notes from current work

- Do not commit unless asked.
- `dart analyze` can throw RangeError in this tree; prefer `flutter run` on device.
- Impeller opt-out may still be in the Android manifest; Flutter warns it is going away.
- Hourly answer keys: never add `tool/hourly_answer_keys.json` or `.sql` to git (see `.gitignore`).
