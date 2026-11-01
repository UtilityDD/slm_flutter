# Continue this app on another machine

Pull `master` from `https://github.com/UtilityDD/slm_flutter.git`. The Supabase URL, anon key, and Google web client id are already in `lib/core/config/app_config.dart`. No `.env` file is required.

## Sign in

- GitHub, with access to `UtilityDD/slm_flutter`
- Cursor, with the same account
- Supabase dashboard for project `wkunyvomogeazjwtenck`, only to run SQL. Do not put the service-role key in the app or in git
- Admin inside the app is only `dipnkr.das@gmail.com` and `roumak.das@gmail.com`

## Google sign-in

This repo has no keystore. Copy the old PC's debug keystore to the same place on the new PC:

`C:\Users\<you>\.android\debug.keystore`

That keeps the Android SHA-1 unchanged. If you skip the copy, Google sign-in fails until you add the new PC's SHA-1 in Google Cloud on the Android OAuth client for package `com.smartlineman.app.slm_flutter`.

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android
```

## Install and run

Install Flutter, the Android SDK (platform-tools), and JDK 17. Then:

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

## SQL already described in the repo

Run each file once in the Supabase SQL editor if it has not been run yet. The database is shared, so this is not per machine.

- `supabase/block_user.sql` — block and unblock
- `supabase/verify_toggle.sql` — verify and unverify, without changing points or web play
- `supabase/verify_lineman.sql` — only if the verified column is not there yet

## Voice work

Read `AUDIO_DEVELOPMENT_GUIDE.md`. The pipeline is:

1. `tool/slm_game_voice_library.py`
2. `python tool/slm_game_voice_library.py --generate`
3. `python tool/update_duty_slip_voice_dart.py`
4. Clips land in `assets/sounds/voice/` and the map in `lib/features/duty_slip/duty_slip_voice.dart`

Lessons and quizzes still use the phone's own Bangla voice. `lib/core/services/neural_tts_service.dart` is present and switched off.

The guide's link to `game_audio_level_by_level_audit.md` points at a file on the old PC only. It is not in this repo.

## Left on the old PC on purpose

Phone screenshots (`phone_*.png`), `temp_audio_batch/`, `temp_portrait_1_3/`, `temp_portrait_1_4/`, and `assets/video/` were not committed.
