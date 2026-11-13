# Android (the ship target)

Application id `com.smartlineman.app`. Launcher label **SmartLineman**.

- Gradle wrapper **9.3.1**, Android Gradle Plugin **9.1.0**, Kotlin **2.4.0** (`settings.gradle.kts`)
- Code targets Java 17 (`app/build.gradle.kts`). Run Gradle on JDK 17 or 21
- `flutter_tts` still applies its own Kotlin plugin, so Flutter prints a future-breakage warning

Manifest (`app/src/main/AndroidManifest.xml`):

- Permissions: `INTERNET`, `RECORD_AUDIO` (speech). No Bluetooth. `USE_BIOMETRIC`/`USE_FINGERPRINT` (pulled in by androidx.credentials) are removed with `tools:node="remove"`.
- Deep link `com.smartlineman.app://login-callback` for sign-in.
- `<queries>`: `DIAL` `tel` (emergency calls), `PROCESS_TEXT`, speech `RecognitionService`, `TTS_SERVICE` (flutter_tts on Android 11+), `VIEW` `https`.

Release: build with `tool/build_release.sh` (arm64 APK + AAB, `--obfuscate`, Dart symbols in
`build/symbols/<version>/` — keep them per shipped build). R8 + resource shrinking and
`localeFilters` (en, bn) are set in `app/build.gradle.kts`; keep rules in `app/proguard-rules.pro`.
Signing uses `android/key.properties` when present (never committed), else the debug key — see the
script header for the one-time `keytool` command and the Google sign-in SHA-1 step.

Android rejects any non-resource file under `app/src/main/res/`, so notes on that folder are in `app/src/main/README.md`.
