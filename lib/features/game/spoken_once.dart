import 'package:shared_preferences/shared_preferences.dart';

/// Full spoken explanations play only the first time a player meets them;
/// after that the coach reacts with one short word and the reason stays as
/// text (the পাঠ card covers repeated mistakes). Saved by stable key, e.g.
/// `pick/1.1/poly`, `kit/flaw/grease`.
abstract final class SpokenOnce {
  static const _key = 'spoken_once_v1';
  static Set<String>? _heard;

  /// True the first time [id] is asked about (and remembers it).
  static Future<bool> first(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final heard = _heard ??= {...?prefs.getStringList(_key)};
    if (!heard.add(id)) return false;
    await prefs.setStringList(_key, heard.toList());
    return true;
  }

  /// Tests: forget the in-memory copy (prefs mocks are reset per test).
  static void resetForTest() => _heard = null;
}
