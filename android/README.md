# Android (the ship target)

Application id `com.smartlineman.app.slm_flutter`. Launcher label **SmartLineman**.

- Gradle wrapper **9.3.1**, Android Gradle Plugin **9.1.0**, Kotlin **2.4.0** (`settings.gradle.kts`)
- Code targets Java 17 (`app/build.gradle.kts`). Run Gradle on JDK 17 or 21
- `flutter_tts` still applies its own Kotlin plugin, so Flutter prints a future-breakage warning

Manifest (`app/src/main/AndroidManifest.xml`):

- Permissions: `INTERNET`, `RECORD_AUDIO` (speech). No Bluetooth.
- Deep link `com.smartlineman.app://login-callback` for sign-in.
- `<queries>`: `DIAL` `tel` (emergency calls), `PROCESS_TEXT`, speech `RecognitionService`, `VIEW` `https`.

Release builds still sign with the debug config. Not store-ready.

Android rejects any non-resource file under `app/src/main/res/`, so notes on that folder are in `app/src/main/README.md`.
