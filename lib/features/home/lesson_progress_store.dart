import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';

/// Marker written when Level 0 (path orientation) is finished.
const pathOrientationId = '0-start';

const _localKey = 'local_completed_lessons';
const _celebratedKey = 'local_celebrated_modules';

final localCompletedLessonsProvider = FutureProvider<List<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_localKey) ?? const [];
});

final localCelebratedModulesProvider = FutureProvider<List<int>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getStringList(_celebratedKey) ?? const [])
      .map((e) => int.tryParse(e) ?? -1)
      .where((e) => e >= 0)
      .toList();
});

/// Profile + device completions (so guests and signed-in users both progress).
final allCompletedLessonsProvider = Provider<Set<String>>((ref) {
  final profile = ref.watch(authProvider).profile?.completedLessons ?? const <String>[];
  final local = ref.watch(localCompletedLessonsProvider).value ?? const <String>[];
  return {...profile, ...local};
});

bool isPathOrientationDone(Set<String> completed) {
  return completed.contains(pathOrientationId) ||
      completed.contains('0_start') ||
      completed.contains('0.start');
}

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
  ref.invalidate(localCelebratedModulesProvider);
}
