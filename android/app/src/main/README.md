# `android/app/src/main`

- `AndroidManifest.xml` — permissions, `MainActivity`, Flutter embedding v2
- `kotlin/com/smartlineman/app/slm_flutter/MainActivity.kt` — empty `FlutterActivity`
- `res/` — launcher mipmaps, launch/normal themes, drawables
- `java/io/flutter/plugins/` — generated plugin registrant (do not edit)

## `res/`

Android rejects any non-resource file under `res/` (the build fails with "The file name must end with .xml or .png"), so these notes live here, not in per-folder READMEs.

| Folder | Contents |
|---|---|
| `mipmap-mdpi` … `mipmap-xxxhdpi` | `ic_launcher` at each density (same art, different sizes; hdpi ≈ 160 dpi) |
| `drawable` | Launch background drawable used by `LaunchTheme` |
| `drawable-v21` | Launch background for Lollipop+ (API 21+) |
| `values` | `styles.xml`: `LaunchTheme` (splash while Flutter boots) and `NormalTheme` (window background behind Flutter) |
| `values-night` | Night variants of the launch/normal themes. Flutter UI is still forced light in `main.dart` |
