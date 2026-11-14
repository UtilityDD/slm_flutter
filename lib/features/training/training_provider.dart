import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/network/supabase_service.dart';
import '../admin/dev_unlock.dart';
import '../auth/auth_provider.dart';
import '../game/content_catalog.dart';
import '../home/lesson_progress_store.dart';
import 'training_models.dart';

final staticChapterTitles = [
  'ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) ও সতর্কতা',
  'পোলে ও লাইনে ওঠার নিরাপদ পদ্ধতি',
  'কন্ডাক্টর ও তারের নিরাপদ টান ও হ্যান্ডলিং',
  'ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR) পরিচালনা',
  'সঠিক আর্থিং ও ডিসচার্জ রড প্রয়োগ',
  'এলটি ও এইচটি লাইনে ফল্ট মেরামত',
  'জরুরি উদ্ধার ও বিদ্যুৎস্পৃষ্টে ফার্স্ট এইড',
  'ডব্লিউবিইআরসি ও বিদ্যুৎ সুরক্ষা বিধি',
  'স্মার্ট মিটার ও আধুনিক বিতরণ সরঞ্জাম',
  'ফিল্ড সেফটি ম্যানুয়াল ও চেকলিস্ট',
];

final staticBadgeNames = [
  'ট্রেইনি',
  'জুনিয়র',
  'টেকনিশিয়ান',
  'স্কিলড',
  'অ্যাডভান্সড',
  'সিনিয়র',
  'সুপারভাইজার',
  'স্পেশালিস্ট',
  'এক্সপার্ট',
  'সেফটি প্রো',
];

/// Network side of the training content. Swappable in tests.
class TrainingChaptersSource {
  const TrainingChaptersSource();

  Future<List<Map<String, dynamic>>> chapterIndex() {
    return SupabaseService.client
        .from('training_chapters')
        .select('id, module_number, chapter_number, title')
        .eq('language', 'bn')
        .eq('is_active', true)
        .order('module_number')
        .order('chapter_number');
  }

  Future<List<Map<String, dynamic>>> moduleRows(int moduleNumber) {
    return SupabaseService.client
        .from('training_chapters')
        .select('*')
        .eq('module_number', moduleNumber)
        .eq('language', 'bn')
        .eq('is_active', true)
        .order('chapter_number', ascending: true);
  }
}

final trainingChaptersSourceProvider = Provider<TrainingChaptersSource>((ref) => const TrainingChaptersSource());

/// Signed-in user id only, so a profile refresh (points, completions) does not
/// count as a new session.
final _sessionUserProvider = Provider<String?>((ref) => ref.watch(authProvider.select((s) => s.profile?.id)));

/// Chapter list, fetched once per session. Progress is applied on top in
/// [trainingLadderProvider], which is cheap to recompute.
final trainingChapterIndexProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(_sessionUserProvider);
  return _withDiskCopy('index', ref.read(trainingChaptersSourceProvider).chapterIndex);
});

/// Full lesson rows (100-200 KB per module), fetched once per module per session.
final trainingModuleRowsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, moduleNumber) async {
  ref.watch(_sessionUserProvider);
  final source = ref.read(trainingChaptersSourceProvider);
  return _withDiskCopy('module_$moduleNumber', () => source.moduleRows(moduleNumber));
});

/// Fetch rows and keep the last good copy on disk; offline, use that copy so
/// lessons read once stay readable. Rethrows when there is no copy.
Future<List<Map<String, dynamic>>> _withDiskCopy(
  String name,
  Future<List<Map<String, dynamic>>> Function() fetch,
) async {
  try {
    final rows = await fetch();
    unawaited(_writeRows(name, rows));
    return rows;
  } catch (_) {
    final saved = await _readRows(name);
    if (saved == null || saved.isEmpty) rethrow;
    return saved;
  }
}

Future<File?> _rowsFile(String name) async {
  try {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/training_v1');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return File('${dir.path}/$name.json');
  } catch (_) {
    return null;
  }
}

Future<void> _writeRows(String name, List<Map<String, dynamic>> rows) async {
  try {
    final f = await _rowsFile(name);
    if (f == null) return;
    final tmp = File('${f.path}.part');
    await tmp.writeAsString(jsonEncode(rows), flush: true);
    await tmp.rename(f.path);
  } catch (_) {}
}

Future<List<Map<String, dynamic>>?> _readRows(String name) async {
  try {
    final f = await _rowsFile(name);
    if (f == null || !f.existsSync()) return null;
    final decoded = jsonDecode(await f.readAsString());
    if (decoded is! List) return null;
    return [for (final r in decoded) if (r is Map) Map<String, dynamic>.from(r)];
  } catch (_) {
    return null;
  }
}

/// Offline stand-in for the chapter index: the bundled catalog lists every
/// lesson with its module, so module sizes stay real without the network.
List<Map<String, dynamic>> chapterIndexFromCatalog(ContentCatalog catalog) {
  return [
    for (final l in catalog.lessons)
      if (int.tryParse(l.moduleId.replaceFirst('m', '')) case final mod?)
        {
          'id': l.id,
          'module_number': mod,
          'chapter_number': int.tryParse(l.id.split('.').last) ?? l.order,
          'title': l.titleBn,
        },
  ];
}

/// Ladder from chapter rows plus real completions. Never invents progress.
List<TrainingModuleItem> buildTrainingLadder(
  List<Map<String, dynamic>> chaptersData, {
  required Set<String> completedLessons,
  required bool devOpen,
  required int userLevel,
}) {
  final Map<int, List<Map<String, dynamic>>> moduleMap = {};
  for (final row in chaptersData) {
    final modNum = (row['module_number'] as num?)?.toInt() ?? 1;
    moduleMap.putIfAbsent(modNum, () => []).add(row);
  }

  final List<TrainingModuleItem> items = [];
  var previousCompleted = true; // module 1 unlocks after Level 0 (checked at open)
  for (int mod = 1; mod <= 10; mod++) {
    final lessons = moduleMap[mod] ?? [];
    final total = lessons.isNotEmpty ? lessons.length : 10;

    // Count completed
    int doneCount = 0;
    for (final l in lessons) {
      final id = l['id']?.toString() ?? '';
      final chNum = l['chapter_number']?.toString() ?? '';
      if (completedLessons.contains(id) ||
          completedLessons.contains('${mod}_$chNum') ||
          completedLessons.contains('$mod.$chNum')) {
        doneCount++;
      }
    }

    final fullyDone = doneCount >= total && total > 0;
    LadderStepStatus status;
    if (fullyDone) {
      status = LadderStepStatus.completed;
    } else if (devOpen || previousCompleted || mod <= userLevel) {
      // Unlock when previous level is finished (local or profile), not only training_level.
      status = LadderStepStatus.active;
    } else {
      status = LadderStepStatus.locked;
    }

    items.add(TrainingModuleItem(
      moduleNumber: mod,
      title: mod <= staticChapterTitles.length ? staticChapterTitles[mod - 1] : 'অধ্যায় $mod',
      badgeName: mod <= staticBadgeNames.length ? staticBadgeNames[mod - 1] : 'লেভেল $mod ব্যাজ',
      totalLessons: total,
      completedLessons: doneCount,
      status: status,
    ));
    previousCompleted = fullyDone;
  }
  return items;
}

const _offlineWait = Duration(seconds: 8);

final trainingLadderProvider = FutureProvider<List<TrainingModuleItem>>((ref) async {
  final authState = ref.watch(authProvider);
  final devOpen = ref.watch(devUnlockProvider);
  final local = ref.watch(localCompletedLessonsProvider).value ?? const <String>[];
  final completedLessons = <String>{
    ...authState.profile?.completedLessons ?? const <String>[],
    ...local,
  };
  final userLevel = authState.profile?.trainingLevel ?? 1;

  List<Map<String, dynamic>> chaptersData;
  try {
    // training_chapters index (cached per session) gives exact module counts.
    // Riverpod retries a failed fetch for about 40 s; do not wait that long.
    // The watch still rebuilds the ladder when a retry succeeds.
    chaptersData = await ref.watch(trainingChapterIndexProvider.future).timeout(_offlineWait);
  } catch (_) {
    // Offline: same ladder from the bundled catalog and this phone's real
    // completions (no made-up progress).
    chaptersData = chapterIndexFromCatalog(await ref.watch(contentCatalogProvider.future));
  }
  return buildTrainingLadder(
    chaptersData,
    completedLessons: completedLessons,
    devOpen: devOpen,
    userLevel: userLevel,
  );
});

final moduleLessonsProvider = FutureProvider.family<List<LessonCardItem>, int>((ref, moduleNumber) async {
  final authState = ref.watch(authProvider);
  final local = ref.watch(localCompletedLessonsProvider).value ?? const <String>[];
  final completedLessons = <String>{
    ...authState.profile?.completedLessons ?? const <String>[],
    ...local,
  };

  try {
    final data = await ref.watch(trainingModuleRowsProvider(moduleNumber).future).timeout(_offlineWait);

    final lessons = data.map((row) {
      final id = row['id']?.toString() ?? '';
      final chNum = row['chapter_number']?.toString() ?? '';
      final isDone = completedLessons.contains(id) ||
          completedLessons.contains('${moduleNumber}_$chNum') ||
          completedLessons.contains('$moduleNumber.$chNum');

      return LessonCardItem.fromSupabase(row, isDone);
    }).toList();

    lessons.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    return lessons;
  } catch (e) {
    return [];
  }
});
