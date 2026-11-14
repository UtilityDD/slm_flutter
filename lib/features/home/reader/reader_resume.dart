import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Where the reader left a lesson: which phase, which point, how far down.
class ReaderSpot {
  final int phaseIndex;
  final int pointIndex;

  /// 0 = top of the page, 1 = bottom. Always clamped to that range.
  final double scrollFraction;

  ReaderSpot({required this.phaseIndex, required this.pointIndex, double scrollFraction = 0})
      : scrollFraction = scrollFraction.isNaN ? 0 : scrollFraction.clamp(0.0, 1.0).toDouble();

  Map<String, dynamic> toJson() => {'phase': phaseIndex, 'point': pointIndex, 'scroll': scrollFraction};

  /// Throws [FormatException] when [json] is not a spot.
  factory ReaderSpot.fromJson(Map<String, dynamic> json) {
    final phase = json['phase'];
    final point = json['point'];
    final scroll = json['scroll'] ?? 0;
    if (phase is! int || point is! int || scroll is! num || phase < 0 || point < 0) {
      throw const FormatException('Not a reader spot');
    }
    return ReaderSpot(phaseIndex: phase, pointIndex: point, scrollFraction: scroll.toDouble());
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderSpot &&
      other.phaseIndex == phaseIndex &&
      other.pointIndex == pointIndex &&
      other.scrollFraction == scrollFraction;

  @override
  int get hashCode => Object.hash(phaseIndex, pointIndex, scrollFraction);

  @override
  String toString() => 'ReaderSpot($phaseIndex, $pointIndex, $scrollFraction)';
}

/// Saves the reader's place per lesson under `reader.resume.<lessonKey>`.
/// Use a stable lesson id as the key, never a list index.
class ReaderResume {
  ReaderResume._();

  static String _key(String lessonKey) => 'reader.resume.$lessonKey';

  /// The saved spot, or null when there is none or it is corrupt.
  static Future<ReaderSpot?> load(String lessonKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(lessonKey));
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return ReaderSpot.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String lessonKey, ReaderSpot spot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(lessonKey), jsonEncode(spot.toJson()));
    } catch (_) {}
  }

  static Future<void> clear(String lessonKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(lessonKey));
    } catch (_) {}
  }
}
