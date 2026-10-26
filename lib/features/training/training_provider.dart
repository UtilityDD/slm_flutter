import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import '../auth/auth_provider.dart';
import '../home/lesson_progress_store.dart';
import 'training_models.dart';

final staticChapterTitles = [
  'ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) ও সতর্কতা',
  'পোল ও লাইনে আরোহণ পদ্ধতি',
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

final trainingLadderProvider = FutureProvider<List<TrainingModuleItem>>((ref) async {
  final authState = ref.watch(authProvider);
  final local = ref.watch(localCompletedLessonsProvider).value ?? const <String>[];
  final completedLessons = <String>{
    ...authState.profile?.completedLessons ?? const <String>[],
    ...local,
  };
  final userLevel = authState.profile?.trainingLevel ?? 1;

  try {
    // Query Supabase training_chapters to get exact module counts
    final chaptersData = await SupabaseService.client
        .from('training_chapters')
        .select('id, module_number, chapter_number, title')
        .eq('language', 'bn')
        .eq('is_active', true)
        .order('module_number')
        .order('chapter_number');

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
      } else if (previousCompleted || mod <= userLevel) {
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
  } catch (e) {
    // Safe offline fallback
    return List.generate(10, (i) {
      final mod = i + 1;
      LadderStepStatus status = LadderStepStatus.locked;
      if (mod == 1) status = LadderStepStatus.completed;
      if (mod == 2) status = LadderStepStatus.active;

      return TrainingModuleItem(
        moduleNumber: mod,
        title: staticChapterTitles[i],
        badgeName: staticBadgeNames[i],
        totalLessons: 10,
        completedLessons: mod == 1 ? 10 : (mod == 2 ? 6 : 0),
        status: status,
      );
    });
  }
});

final moduleLessonsProvider = FutureProvider.family<List<LessonCardItem>, int>((ref, moduleNumber) async {
  final authState = ref.watch(authProvider);
  final local = ref.watch(localCompletedLessonsProvider).value ?? const <String>[];
  final completedLessons = <String>{
    ...authState.profile?.completedLessons ?? const <String>[],
    ...local,
  };

  try {
    final data = await SupabaseService.client
        .from('training_chapters')
        .select('*')
        .eq('module_number', moduleNumber)
        .eq('language', 'bn')
        .eq('is_active', true)
        .order('chapter_number', ascending: true);

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
