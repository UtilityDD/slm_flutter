import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_engine.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/ladder_builder.dart';
import 'package:slm_flutter/features/game/learn_runner.dart';
import 'package:slm_flutter/features/game/lesson_promises.dart';
import 'package:slm_flutter/features/training/training_models.dart';

void main() {
  group('GameSave.claimOnce', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('pays once, then never again (retry, replay, double tap)', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final save = c.read(gameSaveProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      // Two taps in the same frame: only the first one claims.
      final both = await Future.wait([save.claimOnce('learn_q:1.2/learn:Q1'), save.claimOnce('learn_q:1.2/learn:Q1')]);
      expect(both, [true, false]);
      expect(await save.claimOnce('learn_q:1.2/learn:Q1'), isFalse);
      expect(await save.claimOnce('learn_q:1.2/learn:Q2'), isTrue);

      final reloaded = GameSave.fromJson(c.read(gameSaveProvider).toJson());
      expect(reloaded.giftsClaimed, containsAll(['learn_q:1.2/learn:Q1', 'learn_q:1.2/learn:Q2']));
    });
  });

  group('GameSave.commitLevelScore (latest play counts)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a replay replaces the level\'s last score in the main total', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final save = c.read(gameSaveProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await save.addPoints(100); // ◆ from elsewhere stays untouched

      expect(await save.commitLevelScore('1.1/learn', 80), 80);
      expect(c.read(gameSaveProvider).points, 180);

      // Replay: same score → no change; better → only the difference; worse → total drops.
      expect(await save.commitLevelScore('1.1/learn', 80), 0);
      expect(await save.commitLevelScore('1.1/learn', 95), 15);
      expect(c.read(gameSaveProvider).points, 195);
      expect(await save.commitLevelScore('1.1/learn', 40), -55);
      expect(c.read(gameSaveProvider).points, 140);

      // Other levels add up on their own.
      await save.commitLevelScore('1.2/learn', 30);
      expect(c.read(gameSaveProvider).points, 170);

      final reloaded = GameSave.fromJson(c.read(gameSaveProvider).toJson());
      expect(reloaded.levelScoreByRung, {'1.1/learn': 40, '1.2/learn': 30});
    });

    test('replaying never farms: ten equal plays add the score once', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final save = c.read(gameSaveProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      for (var i = 0; i < 10; i++) {
        await save.commitLevelScore('1.1/learn', 75);
      }
      expect(c.read(gameSaveProvider).points, 75);
    });
  });

  group('GameSave.markWeak', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a first-try miss is remembered; a clean answer later forgets it', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final save = c.read(gameSaveProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await save.markWeak('1.1', 'gloves', weak: true);
      await save.markWeak('1.1', 'myth/why', weak: true);
      await save.markWeak('1.1', 'gloves', weak: true); // no duplicate
      expect(c.read(gameSaveProvider).weakByLesson['1.1'], ['gloves', 'myth/why']);

      final reloaded = GameSave.fromJson(c.read(gameSaveProvider).toJson());
      expect(reloaded.weakByLesson['1.1'], ['gloves', 'myth/why']);

      await save.markWeak('1.1', 'gloves', weak: false);
      await save.markWeak('1.1', 'myth/why', weak: false);
      expect(c.read(gameSaveProvider).weakByLesson.containsKey('1.1'), isFalse);
    });

    test('old saves without weak spots still load', () {
      expect(GameSave.fromJson({'points': 3}).weakByLesson, isEmpty);
    });
  });

  group('Lesson promises', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('lessons 1.1–1.5 each have one promise with a unique stable id', () {
      expect(lessonPromises.keys, containsAll(['1.1', '1.2', '1.3', '1.4', '1.5']));
      final ids = lessonPromises.values.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final e in lessonPromises.entries) {
        expect(e.value.lessonId, e.key);
        expect(e.value.textBn.trim(), isNotEmpty);
      }
    });

    test('a death quotes the promise only when the player made it', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final save = c.read(gameSaveProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      Future<void> die() => save.recordLethalDeath(
            cause: 'পচা পোলে উঠেছেন',
            lessonId: '1.3',
            rungId: '1.3/do/0',
            moduleFirstRungId: '1.1/learn',
          );

      await die();
      expect(save.lastDeathPulse!.promiseBn, isNull);

      await save.addPromise(lessonPromiseFor('1.3')!.id);
      await die();
      expect(save.lastDeathPulse!.promiseBn, lessonPromiseFor('1.3')!.textBn);
    });
  });

  group('learnQuizFromPoints (lesson with no quiz file)', () {
    const points = [
      LessonSectionPoint(itemName: 'গ্লাভস', dailyCheck: 'হাওয়া ভরে লিক চেক করুন।'),
      LessonSectionPoint(itemName: 'হেলমেট', dailyCheck: 'খোলসে ফাটল আছে কিনা দেখুন।'),
      LessonSectionPoint(itemName: 'বুট', dailyCheck: 'সোলে পেরেক গেঁথে আছে কিনা দেখুন।'),
      LessonSectionPoint(itemName: 'হারনেস', dailyCheck: 'ফিতেয় সুতো উঠেছে কিনা দেখুন।'),
    ];

    test('two questions, each item asked against its own check', () {
      final quiz = learnQuizFromPoints(points, math.Random(7));
      expect(quiz, hasLength(2));
      for (final q in quiz) {
        final item = points.firstWhere((p) => q.questionText.startsWith(p.itemName));
        expect(q.options[q.correctIndex], item.dailyCheck);
        expect(q.options.toSet(), hasLength(q.options.length));
        // Every option is a real check from this lesson: nothing invented.
        for (final o in q.options) {
          expect(points.map((p) => p.dailyCheck), contains(o));
        }
      }
    });

    test('too few checks: no made-up questions', () {
      expect(learnQuizFromPoints(points.take(2).toList()), isEmpty);
      expect(learnQuizFromPoints(const [LessonSectionPoint(itemName: 'গ্লাভস')]), isEmpty);
    });
  });

  group('Module 1 Do rungs open the game for their own lesson', () {
    late BuiltLadder ladder;

    setUpAll(() {
      final raw = File('assets/game/catalog/content_catalog.json').readAsStringSync();
      ladder = const LadderBuilder().build(ContentCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    });

    test('every Module 1 Do rung and the gate name a built level, each used once', () {
      final m1 = ladder.rungs.where((r) => r.def.moduleId == 'm1' && !r.isLearn).toList();
      expect(m1, isNotEmpty);
      final numbers = dsLevels.map((l) => l.number).toSet();
      final used = <int>{};
      for (final r in m1) {
        final level = r.pack.legacyLevel;
        expect(level, isNotNull, reason: '${r.id} has no legacyLevel');
        expect(numbers, contains(level), reason: '${r.id} → missing level $level');
        expect(used.add(level!), isTrue, reason: 'level $level used twice');
      }
    });

    test('lessons 1.1–1.5 get their topic games', () {
      int? levelOf(String rungId) => ladder.rungs.firstWhere((r) => r.id == rungId).pack.legacyLevel;
      expect(levelOf('1.1/do/0'), 1); // পোশাক
      expect(levelOf('1.2/do/0'), 14); // লক্ষ্মণ রেখা: clearance
      expect([levelOf('1.3/do/0'), levelOf('1.3/do/1')], [11, 12]); // pole language
      expect(levelOf('1.4/do/0'), 4); // harness
      expect(levelOf('m1/gate'), 33); // field night
    });
  });
}
