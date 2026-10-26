# `lib/core/theme/`

Brand colours (`AppColors`): amber `F59E0B`, safety orange, electric blue, alert red, safe green, slate scale, cream `#FFFAF4` / stone ink to match the web home.

`AppTheme` builds light and dark `ThemeData`. `SmartLinemanApp` currently locks `themeMode: ThemeMode.light`.

Duty-slip / zero-loss screens often use their own night palettes (`ZlColors` in those features) on top of this theme.
