# SmartLineman (`slm_flutter`)

Flutter app for West Bengal distribution linemen. Bangla-first. Sister of the web site [smartlineman.in](https://smartlineman.in). Package name `slm_flutter`; Android application id `com.smartlineman.app.slm_flutter`; on-device label is still `slm_flutter` until the launcher string is renamed.

This is **not** `slm-web`. Game loops, duty-slip levels, and copy live here.

## What the app is

A field-training companion: SAFE HOME mantras, PPE, identify-the-gear library, hourly quizzes, life-skill lessons, ranks, emergency numbers, and the core field breakdown & maintenance duty path called **মৃত্যুহীন** (duty slip). Home also still has the older **জিরো লস** storm-feeder sim in code.

Audience: linemen on Android phones, often offline-ish. Large posters and some lesson media stream from `https://www.smartlineman.in` so the APK stays smaller.

## Stack

| Piece | Choice |
|---|---|
| UI | Flutter, Material 3. Premium night look (Midnight Navy + Emerald + Antique Gold) from `lib/design/` on Home and the learning screens; other tabs still use the older cream/amber look |
| Motion | Own motion engine in `lib/design/motion/` (no animation packages) |
| State | Riverpod 3 |
| Auth / points / leaderboards | Supabase (`wkunyvomogeazjwtenck`) |
| Local persistence | `shared_preferences` |
| TTS | `flutter_tts` (Bangla lesson read-aloud) |
| STT | `speech_to_text` (login / speech) |
| Audio | `audioplayers` (cues + SLM Radio stream) |
| Navigation | Named routes inside `MainShell` (not go_router at runtime; the package is in pubspec) |
| Fonts | Noto Sans Bengali 400–700 bundled |

## Run

Primary device now: Oppo CPH2487, adb id `8012f054` (earlier: Oppo CPH2467, `f6650cdf`).

Debug APK, install and launch (used for every check in the premium work):

```powershell
$env:GRADLE_USER_HOME = "$env:LOCALAPPDATA\Temp\cursor-sandbox-cache\c3a692ac3dd2c7cf96edcb758878463a\gradle"
& "$env:USERPROFILE\flutter\bin\flutter.bat" build apk --debug
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb -s 8012f054 install -r -t -d build\app\outputs\flutter-apk\app-debug.apk
& $adb -s 8012f054 shell am start -n com.smartlineman.app.slm_flutter/.MainActivity
```

If install says `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, ask before uninstalling: it wipes local progress.

Gradle wrapper is **9.3.1**. Wrapper download often times out; use a populated `GRADLE_USER_HOME` and offline:

```powershell
$env:Path = "C:\Users\rouma\flutter\bin;" + $env:Path
$env:GRADLE_USER_HOME = "$env:USERPROFILE\.gradle"
$env:GRADLE_OPTS = "-Dorg.gradle.offline=true"
flutter run -d f6650cdf --no-pub
```

Do not use PowerShell `Set-Content` for Bangla JSON or Dart — it mojibakes. Edit those files in the editor.

## Bottom tabs

1. **হোম / Home** — header, lineman hero carousel, **মৃত্যুহীন পথ** shield button
2. **পরিচিতি / Identify** — safety library + charts
3. **র‍্যাঙ্ক / Rank** — monthly boards (Champion / New / Improved / Learner)
4. **লাইফ স্কিল / Life Skill** — 13 local lessons

A notched emerald dock with a gold-rimmed bubble floats over pages. **SLM Radio** can sit above it.

## Premium design system and motion

The app is being upgraded screen by screen to one visual identity: **Midnight Navy** surfaces, **Emerald** for progress and success, **Antique Gold** for edges, highlights and rewards. Done so far: Home (phase 3) and the learning screens (phase 4). Next: quizzes, only after approval.

**The rule for every phase: same layout, same functionality, premium visuals.** An upgrade may restyle and animate; it may not move sections, rename labels, change routes, or touch Supabase, progress, points, XP, ranks or game logic. Each phase is shown on the phone and approved before the next starts.

### Where things live

| Path | What |
|---|---|
| `lib/design/slm_design.dart` | Barrel. Import this one file |
| `lib/design/tokens/` | Colours (`SlmColors`), palette (`SlmPalette`, night / day), spacing and radii (`SlmSpace`, `SlmRadius`), motion timings (`SlmMotion`), gradients and shadows (`SlmGradients`, `SlmShadows`), Bangla-safe type (`SlmType`) |
| `lib/design/theme/slm_theme.dart` | `SlmTheme.night()` / `day()`; read tokens with `context.slm` |
| `lib/design/components/` | `SlmButton`, `SlmCard`, `SlmIconBadge`, `SlmSegmented`, `SlmProgressBar`, `SlmBackground`, `SlmTopBar`, … |
| `lib/design/motion/` | Motion engine. Widget list and shield asset notes: [`lib/design/MOTION.md`](lib/design/MOTION.md) |
| `assets/brand/shield_*.webp` | The three layers of the animated মৃত্যুহীন পথ shield |
| `lib/features/design_preview/` | Debug-only **প্রিমিয়াম প্রিভিউ** and **মোশন শোকেস** (More menu, `kDebugMode` only) |

### How to apply it to a screen

- **Theme only the backdrop.** Paint the navy background as its own layer: `Positioned.fill(Theme(data: SlmTheme.night(), child: SlmBackground(constrain: false, child: SizedBox.expand())))`, with the page on top. Do not wrap the whole page in the night theme: bottom sheets and dialogs capture the caller's theme and would change their look. Wrap only design-system widgets that read the theme (for example `SlmButton`) in `Theme(data: SlmTheme.night())`.
- **Status bar.** Navy pages set `AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light)`. `MainShell` sets `dark` for the cream tabs; the inner region wins.
- **Shared widgets get an opt-in flag.** `HeroCard(premium: true, press: …)` is the Home finish; the login and celebration cards keep the old finish because they don't pass it.
- **Reading stays dark on paper.** Lesson text is dark ink (`SlmColors.ink`) on a warm ivory sheet with a gold edge; only the chrome around it is navy. Keep font sizes and line heights; no effects behind reading text. Field staff read this in sunlight.
- **Contrast on navy.** Titles `SlmColors.ivory`, secondary text `SlmColors.mist`, labels `gold300`, success `emerald300`, locked `slate`.
- **Motion is meaningful and light.** Use `SlmPressable` / `SlmTactile` for press feedback, `SlmReveal` (with `index`) for staggered entrances, `SlmShimmer` for one slow highlight, `TweenAnimationBuilder` + `SlmMotion.emphasized` for progress. No GIFs or videos. The phone's "remove animations" setting turns loops and entrances off.
- **Rewards are display only.** `showSlmXpToast`, `showSlmBadgeUnlock`, `showSlmLevelUp` run after the existing code has saved the result, and must show the same number the existing code awards (the reader shows `+20 পয়েন্ট` only on a first-time completion).

### What each upgraded screen got

- **Home** (`home_screen.dart`, `hero_card*.dart`, `main_shell.dart`): navy backdrop; ivory name, shimmering gold verify tick, gold sliding বাং / EN switch; bevelled metal card frame with ambient scene light (the lineman is never dimmed or re-animated); metal nameplate with moving light and press depth; **মৃত্যুহীন পথ** is now `AnimatedSafetyShield` + real Bangla text + gold arrow on an emerald pill in the old 270 px footprint; emerald dock, gold bubble rim, gold active bar, press feedback, labels capped at 1.15× text scale.
- **Lesson shelf** (`level_lessons_page.dart`): navy header and pinned progress bar (gold, emerald when complete, fills from zero); navy book cards with a metal spine — bronze not started, gold next, emerald done, slate locked; shimmering gold **এখান থেকে শুরু** pill; press feedback; the existing staggered entrance.
- **Level 0 map** (`level_zero_page.dart`): same night treatment, staggered intro cards and step tiles, emerald `SlmButton` with loading.
- **Lesson reader** (`lesson_reader_page.dart`): navy chrome, gliding gold progress bar, ivory reading sheet, fade-and-slide between pages, animated step segments, gold point badge, gold **পরের পাতা** / emerald quiz button, navy-gold **শুনুন**, completion medal with spark burst, `+20 পয়েন্ট` toast on first completion.

Not upgraded yet: quizzes, celebration page, Identify, Rank, Life Skill, More, login. `TrainingScreen` (`/training`) is registered but nothing opens it.

## মৃত্যুহীন (duty slip) — core field duty path (day / night)

Home button text is **মৃত্যুহীন পথ** (real text beside the animated shield). Cover title **কাজের ধাপ**. Ladder header **মৃত্যুহীন পথ**. Next-level button **পরের লেভেল** (returns to the wooden ladder). No সহজ/কঠিন.

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
- **Safe commit and push:** stage files by name, never `git add -A`. Leave out files from other work in progress, root `phone_*.png` screenshots, keystores, `key.properties` and answer keys. Scan the staged diff for keys and tokens before committing. Pushing to `master` needs the owner's approval.
- **Phone privacy:** take a phone screenshot only after `dumpsys window` shows `com.smartlineman.app.slm_flutter` in focus. If the owner is using the phone, stop and ask.
- `flutter analyze` / `dart analyze` can crash with a RangeError or access violation in its cache. Rename `%LOCALAPPDATA%\.dartServer\.analysis-driver` and run it again. The baseline is 107 old notes and warnings, 0 errors; new code should add none.
- For a visual check without the phone, render a temporary widget test with `matchesGoldenFile` and `--update-goldens`, then delete the test. Bangla shows as boxes in tests.
- Impeller opt-out may still be in the Android manifest; Flutter warns it is going away.
- Hourly answer keys: never add `tool/hourly_answer_keys.json` or `.sql` to git (see `.gitignore`).
