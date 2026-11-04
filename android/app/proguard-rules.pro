# R8 rules for the SmartLineman release build (added on top of proguard-android-optimize.txt,
# Flutter's flutter_proguard_rules.pro and each library's own consumer rules).
#
# Plugins checked (Nov 2026): audioplayers, flutter_tts, speech_to_text, url_launcher,
# shared_preferences, path_provider (jni), sqflite (via cached_network_image), app_links +
# supabase_flutter, google_sign_in. All talk to Dart through Pigeon / MethodChannel classes that
# Flutter keeps (every FlutterPlugin implementation is kept by flutter_proguard_rules.pro) and
# jni ships its own consumer rules, so no plugin needs extra keeps today.

# google_sign_in 7.x -> androidx.credentials 1.6. CredentialManager loads the Play-services
# provider by class name; credentials-play-services-auth 1.6 ships that keep rule itself
# (`-keep class androidx.credentials.playservices.CredentialProviderPlayServicesImpl`).
# Older guides say to keep all of androidx.credentials.playservices.** — that keeps 106 classes
# (+150 KB dex) and is only needed if Google sign-in fails in a release build. If it does, add:
#   -if class androidx.credentials.CredentialManager
#   -keep class androidx.credentials.playservices.** { *; }

# The Flutter engine references Play Core (deferred components) which this app does not use.
-dontwarn com.google.android.play.core.**
