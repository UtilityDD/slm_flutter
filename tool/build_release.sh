#!/usr/bin/env bash
# Release build for SmartLineman (Android).
#
#   tool/build_release.sh            # arm64 APK (sideload) + Play App Bundle
#   tool/build_release.sh apk        # arm64 APK only
#   tool/build_release.sh aab        # App Bundle only
#   tool/build_release.sh apk-all    # one APK per ABI (arm64, armv7, x86_64) for old/odd phones
#
# What it does on top of a plain `flutter build`:
#   --obfuscate --split-debug-info  Dart symbols are stripped from libapp.so and written to
#                                   build/symbols/<version>/ (gitignored). KEEP that folder for
#                                   every build you ship: it is the only way to read a crash
#                                   stack trace:  flutter symbolize -i trace.txt -d build/symbols/<v>/app.android-arm64.symbols
#   --split-per-abi / arm64 only    Budget Android phones since ~2019 are arm64. One ABI per APK.
#   R8 + resource shrinking         Configured in android/app/build.gradle.kts (release).
#
# Optional:  SLM_COMPRESS_NATIVE=1 tool/build_release.sh apk
#   Stores the native .so files compressed: the APK file is ~10 MB smaller to send over
#   WhatsApp/mobile data, but the phone extracts them on install (uses more storage).
#
# ---------------------------------------------------------------------------------------------
# Release signing (one-time). Without android/key.properties, release builds are signed with the
# debug key (fine for testing, NOT for the Play Store / updates in the field).
#
#   keytool -genkeypair -v -keystore ~/smartlineman-upload.jks \
#           -keyalg RSA -keysize 2048 -validity 10000 -alias upload
#
# then create android/key.properties (gitignored — never commit it or the .jks):
#
#   storePassword=<password>
#   keyPassword=<password>
#   keyAlias=upload
#   storeFile=/Users/<you>/smartlineman-upload.jks
#
# (storeFile is resolved relative to android/ if not absolute.) Back the .jks + passwords up
# somewhere safe: losing it means you can never ship an update to installed apps.
#
# IMPORTANT: Google sign-in checks the signing certificate. After switching keys, add the new
# SHA-1 as an Android OAuth client in Google Cloud Console (and the Play App Signing SHA-1 if you
# use Play), or sign-in fails with a configuration error:
#   keytool -list -v -keystore ~/smartlineman-upload.jks -alias upload | grep SHA1
# ---------------------------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

mode="${1:-all}"
version="$(sed -n 's/^version:[[:space:]]*\([^[:space:]#]*\).*/\1/p' pubspec.yaml)"
symbols="build/symbols/${version}"
mkdir -p "$symbols"

common=(--release --obfuscate "--split-debug-info=${symbols}")
gradle_extra=()
if [[ "${SLM_COMPRESS_NATIVE:-0}" == "1" ]]; then
  gradle_extra=(--android-project-arg=slm.compressNativeLibs=true)
fi

if [[ ! -f android/key.properties ]]; then
  echo "NOTE: android/key.properties not found -> signing with the DEBUG key." >&2
fi

build_apk() {
  flutter build apk "${common[@]}" --split-per-abi "$@" ${gradle_extra[@]+"${gradle_extra[@]}"}
}

case "$mode" in
  apk) build_apk --target-platform android-arm64 ;;
  apk-all) build_apk --target-platform android-arm,android-arm64,android-x64 ;;
  aab) flutter build appbundle "${common[@]}" ;;
  all)
    build_apk --target-platform android-arm64
    flutter build appbundle "${common[@]}"
    ;;
  *) echo "usage: $0 [all|apk|apk-all|aab]" >&2; exit 2 ;;
esac

echo
echo "Outputs:"
ls -l build/app/outputs/flutter-apk/*-release.apk build/app/outputs/bundle/release/*.aab 2>/dev/null || true
echo "Dart symbols (keep for crash reports): ${symbols}/"
