import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

const _localKey = 'local_completed_lessons';
const _celebratedKey = 'local_celebrated_modules';
const _readPositionKey = 'local_read_position';

/// Last scroll offset (px) and phase index per lesson id, so reopening a
/// lesson resumes exactly where the reader left off.
final readPositionProvider = FutureProvider<Map<String, int>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_readPositionKey);
  if (raw == null || raw.isEmpty) return const <String, int>{};
  final decoded = <String, int>{};
  for (final entry in raw.split(',')) {
    final parts = entry.split('|');
    if (parts.length == 2) {
      decoded[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
  }
  return decoded;
});

final localCompletedLessonsProvider = FutureProvider<List<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_localKey) ?? const [];
});

/// Profile + device completions (so guests and signed-in users both progress).
final allCompletedLessonsProvider = Provider<Set<String>>((ref) {
  final profile = ref.watch(authProvider).profile?.completedLessons ?? const <String>[];
  final local = ref.watch(localCompletedLessonsProvider).value ?? const <String>[];
  return {...profile, ...local};
});

Future<void> markLessonCompletedLocally(WidgetRef ref, String id) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getStringList(_localKey) ?? <String>[];
  if (current.contains(id)) return;
  current.add(id);
  await prefs.setStringList(_localKey, current);
  ref.invalidate(localCompletedLessonsProvider);
}

Future<bool> hasCelebratedModule(int module) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_celebratedKey) ?? const <String>[];
  return raw.contains('$module');
}

Future<void> markModuleCelebrated(WidgetRef ref, int module) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getStringList(_celebratedKey) ?? <String>[];
  final key = '$module';
  if (current.contains(key)) return;
  current.add(key);
  await prefs.setStringList(_celebratedKey, current);
}

/// Persists the last read offset (px) for [lessonId]. Called on every scroll
/// tick while reading so reopening resumes at the same line.
Future<void> saveReadPosition(String lessonId, int offsetPx) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_readPositionKey) ?? '';
  final map = <String, int>{};
  if (raw.isNotEmpty) {
    for (final entry in raw.split(',')) {
      final parts = entry.split('|');
      if (parts.length == 2) map[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
  }
  map[lessonId] = offsetPx.clamp(0, 1 << 24);
  await prefs.setString(_readPositionKey, map.entries.map((e) => '${e.key}|${e.value}').join(','));
}

/// Returns the last saved scroll offset for [lessonId], or 0 when none.
Future<int> getReadPosition(String lessonId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_readPositionKey);
  if (raw == null || raw.isEmpty) return 0;
  for (final entry in raw.split(',')) {
    final parts = entry.split('|');
    if (parts.length == 2 && parts[0] == lessonId) {
      return int.tryParse(parts[1]) ?? 0;
    }
  }
  return 0;
}
