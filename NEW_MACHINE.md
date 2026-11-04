# Continue this app on another machine

Pull `master` from `https://github.com/UtilityDD/slm_flutter.git`. The Supabase URL, anon key, and Google web client id are already in `lib/core/config/app_config.dart`. No `.env` file is required.

## Sign in

- GitHub, with access to `UtilityDD/slm_flutter`
- Supabase dashboard for project `wkunyvomogeazjwtenck`, only to run SQL. Do not put the service-role key in the app or in git
- Admin inside the app is only `dipnkr.das@gmail.com` and `roumak.das@gmail.com`

## Google sign-in

This repo has no keystore. Copy the old machine's debug keystore to the same place on the new one:

- Windows: `C:\Users\<you>\.android\debug.keystore`
- macOS: `~/.android/debug.keystore`

That keeps the Android SHA-1 unchanged. If you skip the copy, Google sign-in fails until you add the new PC's SHA-1 in Google Cloud on the Android OAuth client for package `com.smartlineman.app.slm_flutter`.

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android
```

## Install and run

Install Flutter, the Android SDK (platform-tools), and JDK 17 or 21. Then:

```powershell
git clone https://github.com/UtilityDD/slm_flutter.git
cd slm_flutter
flutter pub get
flutter build apk --debug
```

Use the normal user Gradle folder. Do not set `GRADLE_USER_HOME` to a temporary cache.

Plug the phone in and tap Allow on the USB debugging prompt. A new computer shows the phone as `unauthorized` until you do.

```powershell
adb install -r -t -d build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n com.smartlineman.app.slm_flutter/.MainActivity
```

If install says `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, ask before uninstalling. Uninstall wipes progress stored on that phone.

Do not edit Bangla files with PowerShell `Set-Content`. It corrupts the text.

## macOS

- Flutter in `~/development/flutter`. Android SDK in `~/Library/Android/sdk` (Android Studio puts it there). JDK 21 (`brew install --cask temurin@21`, or Android Studio's bundled JBR).
- Add to `~/.zshrc`:

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Library/Android/sdk/platform-tools:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
```

- Then `flutter doctor --android-licenses`, `flutter pub get`, `flutter build apk --debug`, and install with `adb install -r -t -d build/app/outputs/flutter-apk/app-debug.apk`.
- SHA-1 check: `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android`.
- The voice scripts need Python 3 (`python3`, not `python`).

## SQL already described in the repo

Run each file once in the Supabase SQL editor if it has not been run yet. The database is shared, so this is not per machine.

- `supabase/block_user.sql` — block and unblock
- `supabase/verify_toggle.sql` — verify and unverify, without changing points or web play
- `supabase/verify_lineman.sql` — only if the verified column is not there yet
- `supabase/submit_flutter_hourly_quiz.sql`, `admin_access.sql`, `fix_new_google_signup.sql` — see `supabase/README.md`

## Voice work

Read `AUDIO_DEVELOPMENT_GUIDE.md`. The pipeline is:

1. `tool/slm_game_voice_library.py`
2. `python tool/slm_game_voice_library.py --generate`
3. `python tool/update_duty_slip_voice_dart.py`
4. Clips land in `assets/sounds/voice/` and the map in `lib/features/duty_slip/duty_slip_voice.dart`

Lessons and quizzes still use the phone's own Bangla voice. `lib/core/services/neural_tts_service.dart` is present and switched off.


## Left on the old PC on purpose

`temp_audio_batch/`, `temp_portrait_1_3/`, `temp_portrait_1_4/` and `assets/video/` were not committed. Two old screenshots (`phone_screen.png`, `phone_screen_updated.png`) are tracked; do not add more.
