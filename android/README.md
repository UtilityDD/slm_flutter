# Android (primary ship target)

Application id `com.smartlineman.app.slm_flutter`.

- Gradle **9.3.1** (`gradle/wrapper/gradle-wrapper.properties`)
- Android Gradle Plugin **9.1.0**, Kotlin **2.4.0** (`settings.gradle.kts`)
- Java 17
- `flutter_tts` still applies its own KGP; Flutter prints a future-breakage warning

Permissions (`app/src/main/AndroidManifest.xml`): INTERNET, RECORD_AUDIO (speech), Bluetooth trio (radio / audio routing). Queries: PROCESS_TEXT, speech RecognitionService.

Launcher label is still `slm_flutter`. Impeller may be opted out in the manifest; Flutter warns that flag is going away.

Offline Gradle (wrapper zip already in `%USERPROFILE%\.gradle`):

```
$env:GRADLE_USER_HOME = "$env:USERPROFILE\.gradle"
$env:GRADLE_OPTS = "-Dorg.gradle.offline=true"
flutter run -d f6650cdf --no-pub
```

Release signing still uses the debug config (`app/build.gradle.kts`) — not store-ready.
