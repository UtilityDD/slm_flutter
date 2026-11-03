import 'package:shared_preferences/shared_preferences.dart';

/// Skull / fear beat cadence: show on the day's first open, or again after 4 hours.
abstract final class PathFearGate {
  static const _key = 'path_fear_last_shown_ms_v1';
  static const cooldown = Duration(hours: 4);

  static bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_key);
    if (raw == null || raw <= 0) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(raw);
    final now = DateTime.now();
    if (now.difference(last) >= cooldown) return true;
    if (!_sameCalendarDay(last, now)) return true;
    return false;
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, DateTime.now().millisecondsSinceEpoch);
  }
}
