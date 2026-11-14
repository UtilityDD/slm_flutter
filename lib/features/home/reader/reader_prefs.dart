import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reading text size in the lesson reader. Three steps, clamped at both ends.
enum ReaderTextSize {
  small,
  normal,
  large;

  /// Multiplier for the reader's body text.
  double get scale => switch (this) {
        ReaderTextSize.small => 0.9,
        ReaderTextSize.normal => 1.0,
        ReaderTextSize.large => 1.15,
      };
}

/// Page colours for the lesson reader.
enum ReaderTheme { day, night, system }

const _textSizeKey = 'reader.textSize';
const _themeKey = 'reader.theme';

/// Starts at [ReaderTextSize.normal] and reads the saved size in the
/// background, so the first frame never waits on SharedPreferences.
class ReaderTextSizeNotifier extends Notifier<ReaderTextSize> {
  bool _touched = false;

  @override
  ReaderTextSize build() {
    unawaited(_restore());
    return ReaderTextSize.normal;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = _byName(ReaderTextSize.values, prefs.getString(_textSizeKey));
      // A tap that came in while loading wins over the saved value.
      if (saved != null && !_touched && ref.mounted) state = saved;
    } catch (_) {}
  }

  void bigger() => _set(ReaderTextSize.values[(state.index + 1).clamp(0, ReaderTextSize.values.length - 1)]);

  void smaller() => _set(ReaderTextSize.values[(state.index - 1).clamp(0, ReaderTextSize.values.length - 1)]);

  void _set(ReaderTextSize next) {
    _touched = true;
    if (next == state) return;
    state = next;
    unawaited(_save(_textSizeKey, next.name));
  }
}

final readerTextSizeProvider = NotifierProvider<ReaderTextSizeNotifier, ReaderTextSize>(ReaderTextSizeNotifier.new);

/// Starts at [ReaderTheme.system] and reads the saved choice in the background.
class ReaderThemeNotifier extends Notifier<ReaderTheme> {
  bool _touched = false;

  @override
  ReaderTheme build() {
    unawaited(_restore());
    return ReaderTheme.system;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = _byName(ReaderTheme.values, prefs.getString(_themeKey));
      if (saved != null && !_touched && ref.mounted) state = saved;
    } catch (_) {}
  }

  void setTheme(ReaderTheme theme) {
    _touched = true;
    if (theme == state) return;
    state = theme;
    unawaited(_save(_themeKey, theme.name));
  }

  /// day → night → system → day.
  void cycle() => setTheme(ReaderTheme.values[(state.index + 1) % ReaderTheme.values.length]);
}

final readerThemeProvider = NotifierProvider<ReaderThemeNotifier, ReaderTheme>(ReaderThemeNotifier.new);

/// True when the reader should draw its night colours. [ReaderTheme.system]
/// follows the phone's own dark mode.
bool readerIsNight(BuildContext context, ReaderTheme theme) => switch (theme) {
      ReaderTheme.day => false,
      ReaderTheme.night => true,
      ReaderTheme.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

T? _byName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

Future<void> _save(String key, String value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  } catch (_) {}
}
