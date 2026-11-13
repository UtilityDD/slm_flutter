# SmartLineman (`slm_flutter`)

> **Before you change anything, read [`AGENTS.md`](AGENTS.md).** It has the rules every agent and contributor must follow (performance, tests, assets, offline, scoring). `flutter analyze`, `flutter test` and `python3 -I tool/check_asset_refs.py .` must pass before every push.

Flutter app for West Bengal distribution linemen. Bangla first. Built for budget Android phones that are often offline. Sister of the web site [smartlineman.in](https://smartlineman.in), but this is **not** `slm-web`: game loops, levels and copy live here.

Package `slm_flutter`. Android application id `com.smartlineman.app`. Launcher label **SmartLineman**.

## What the app is

One game. Home has one button, **মৃত্যুহীন পথ**. It opens a ladder of Learn and Do rungs with rank gates, a death count, falls back to the module checkpoint, and the emerald at the top. The full design is in [`GAME_DESIGN.md`](GAME_DESIGN.md).

Around the game, from the Home toolbox or ladder stations: Identify (gear photo library and charts), Rank (monthly board), Emergency numbers, Settings, hourly quiz, identify quiz, Supabase lessons (`TrainingScreen`), PPE checklist and 8 মন্ত্র.

There is no tab bar. Large posters and some lesson media stream from `https://www.smartlineman.in` to keep the APK small.

## Stack

| Piece | Choice |
|---|---|
| UI | Flutter, Material 3. Navy / Emerald / Antique Gold design system in `lib/design/`. Some older pages still use the cream / amber `AppTheme` |
| Motion | Own engine in `lib/design/motion/`, no animation packages. Rules: [`lib/design/MOTION.md`](lib/design/MOTION.md) |
| State | Riverpod 3 |
| Auth, points, leaderboards | Supabase (`wkunyvomogeazjwtenck`), Google sign-in |
| Local save | `shared_preferences` (`GameSave`: points, deaths, current rung) |
| Audio | `audioplayers`: pooled SFX (`SlmSfx`), voice clips (`DsVoice`) |
| TTS | `flutter_tts`: one shared device voice (`bangla_read_aloud.dart`) |
| STT | `speech_to_text` |
| Navigation | Nested `Navigator` with named routes in `MainShell` |
| Fonts | Noto Sans Bengali 400–700, bundled |

## Run

Main phone: Oppo CPH2487, adb id `8012f054` (older: CPH2467, `f6650cdf`). Gradle wrapper **9.3.1**.

### macOS

Flutter at `~/development/flutter`, Android SDK at `~/Library/Android/sdk`, JDK 21.

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Library/Android/sdk/platform-tools:$PATH"
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
flutter pub get
flutter build apk --debug
adb -s 8012f054 install -r -t -d build/app/outputs/flutter-apk/app-debug.apk
adb -s 8012f054 shell am start -n com.smartlineman.app/com.smartlineman.app.slm_flutter.MainActivity
```

### Windows (PowerShell)

```powershell
$env:Path = "$env:USERPROFILE\flutter\bin;" + $env:Path
$env:GRADLE_USER_HOME = "$env:USERPROFILE\.gradle"
flutter build apk --debug
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb -s 8012f054 install -r -t -d build\app\outputs\flutter-apk\app-debug.apk
& $adb -s 8012f054 shell am start -n com.smartlineman.app/com.smartlineman.app.slm_flutter.MainActivity
```

If the wrapper download times out, set `GRADLE_OPTS=-Dorg.gradle.offline=true` with a filled Gradle folder.

If install says `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, ask before uninstalling. It wipes local progress.

New computer: see [`NEW_MACHINE.md`](NEW_MACHINE.md).

## Check before you commit

```bash
flutter analyze   # baseline: 96 old notes and warnings, 0 errors. New code adds none
flutter test      # tests live in test/perf/
```

If `flutter analyze` crashes with a RangeError or access violation, delete the analyzer cache (`~/.dartServer/.analysis-driver` on macOS, `%LOCALAPPDATA%\.dartServer\.analysis-driver` on Windows) and run it again.

For a visual check without the phone, render a temporary widget test with `matchesGoldenFile` and `--update-goldens`, then delete the test. Bangla shows as boxes in tests.

## Owner's rules

- Do not commit unless asked.
- **Stage files by name. Never `git add -A`.** Leave out other work in progress, root `phone_*.png` screenshots, keystores, `key.properties` and answer keys. Scan the staged diff for keys and tokens.
- **Pushing to `master` needs the owner's approval.**
- **Bangla editing:** edit Bangla Dart and JSON in the editor or with a UTF-8 tool. Never PowerShell `Set-Content`: it corrupts the text.
- **Phone privacy:** take a screenshot only after `dumpsys window` shows `com.smartlineman.app` in focus. If the owner is using the phone, stop and ask.
- Hourly answer keys (`tool/hourly_answer_keys.json` / `.sql`) never go in git (see `.gitignore`).

## Design rules

- **Theme only the backdrop.** Paint navy as its own layer (`Positioned.fill(Theme(data: SlmTheme.night(), child: SlmBackground(...)))`) with the page on top. Do not wrap a whole page in the night theme: sheets and dialogs take the caller's theme.
- **Reading stays dark on paper.** Lesson text is dark ink on an ivory sheet. No effects behind reading text. Field staff read in sunlight.
- **Contrast on navy.** Titles `SlmColors.ivory`, secondary `SlmColors.mist`, labels `gold300`, success `emerald300`, locked `slate`.
- **Motion is light and follows one policy** (`slmReduceMotion`, `slmSyncLoop`). See `lib/design/MOTION.md`.
- **Images decode at display size.** Use `fit_image.dart` / `DsBoxDecode` / `dsThumb`, not full-size decodes.
- **Rewards are display only.** `showSlmXpToast` and friends run after the real code has saved the result and show the same number.

## Bangla copy rules

- **ডকেট**, **শাটডাউন**. Water is **জল**, never পানি. **গ্লাভস**, never দস্তানা.
- Rank words: **দারুণ / মোটামুটি / আবার**.
- Numbers are Western digits `0–9`, even in Bangla (`enDigits`).

Level rules, SAFE HOME, the 23-step job and scoring: [`lib/features/duty_slip/README.md`](lib/features/duty_slip/README.md).

## Layout

```
lib/        Dart app (see lib/README.md)
assets/     Bundled JSON, photos, fonts, sounds (notes in docs/assets.md)
docs/       Notes that must not ship inside asset folders
android/    The ship target
ios/ linux/ macos/ windows/ web/   Stock Flutter shells, not shipped
supabase/   SQL for hourly scoring, verify, block, admin
tool/       Asset, voice and pack scripts (not shipped)
test/perf/  Performance and behaviour tests
```

Never put a README or any other non-asset file inside a folder that `pubspec.yaml` lists. It ships in the APK.
