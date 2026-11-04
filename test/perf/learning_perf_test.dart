// Perf regression guards for the learning area (quizzes, identify, lessons,
// emergency directory, training content). Numbers are printed with PERF so a
// run shows before/after; asserts keep the wins from slipping back.
//
// Baseline on c9ec1bd (macOS host, DPR 2.0):
//   42 dp option tile, 2217x1707 jpg ...... 15,137,676 B decoded
//   164 dp question panel, same jpg ........ 15,137,676 B decoded
//   hourly pack open #1 / #2 ............... 112 / 36 ms, UI isolate stall 67 / 36 ms
//   emergency directory open #1 / #2 ....... 28 / 2 ms, UI isolate stall 18 / 2 ms
//   safety library parse ................... 14 ms, UI isolate stall 10 ms
//   training_chapters fetches per lesson completion: one per dependency change
//   (auth x2, local progress x2, explicit invalidate x1) for ladder and module.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/emergency/emergency_directory_screen.dart';
import 'package:slm_flutter/features/home/lesson_progress_store.dart';
import 'package:slm_flutter/features/identify/fit_image.dart';
import 'package:slm_flutter/features/identify/library_catalog.dart';
import 'package:slm_flutter/features/quizzes/hourly_pack.dart';
import 'package:slm_flutter/features/training/training_provider.dart';

const _big = 'assets/quizzes/img_1eGaUNv_BadZ1bz_xaksCBIDXEZ2xQqJ4.jpg'; // 2217x1707

Future<int> _decodedBytes(WidgetTester tester, Widget Function(BuildContext) build) async {
  await tester.pumpWidget(const SizedBox());
  imageCache.clear();
  imageCache.clearLiveImages();
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(home: Center(child: Builder(builder: build))));
    for (var i = 0; i < 300 && imageCache.currentSizeBytes == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pump();
  return imageCache.currentSizeBytes;
}

/// Wall time of [work] and the longest gap the UI isolate could not run a 1 ms timer.
Future<(int ms, int stallMs)> _measure(Future<void> Function() work) async {
  final sw = Stopwatch()..start();
  var last = sw.elapsedMicroseconds;
  var worst = 0;
  final tick = Timer.periodic(const Duration(milliseconds: 1), (_) {
    final now = sw.elapsedMicroseconds;
    if (now - last > worst) worst = now - last;
    last = now;
  });
  await work();
  tick.cancel();
  final end = sw.elapsedMicroseconds;
  if (end - last > worst) worst = end - last;
  return (sw.elapsedMilliseconds, worst ~/ 1000);
}

class _CountingSource extends TrainingChaptersSource {
  int index = 0;
  int module = 0;

  @override
  Future<List<Map<String, dynamic>>> chapterIndex() async {
    index++;
    return [
      for (var ch = 1; ch <= 3; ch++) {'id': 'm1c$ch', 'module_number': 1, 'chapter_number': ch, 'title': 't$ch'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> moduleRows(int moduleNumber) async {
    module++;
    return [
      for (var ch = 1; ch <= 3; ch++)
        {'id': 'm1c$ch', 'module_number': moduleNumber, 'chapter_number': ch, 'title': 't$ch', 'content': <String, dynamic>{}},
    ];
  }
}

class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1'));

  void put(AuthState next) => state = next;
}

void main() {
  group('image decode size (DPR 2.0)', () {
    testWidgets('42 dp option tile decodes ~42 dp, not the 2217x1707 file', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      final before = await _decodedBytes(
        tester,
        (_) => SizedBox(width: 42, height: 42, child: Image.asset(_big, fit: BoxFit.contain)),
      );
      final after = await _decodedBytes(
        tester,
        (c) => SizedBox(
          width: 42,
          height: 42,
          child: Image(image: fitAsset(c, _big, width: 42, height: 42), fit: BoxFit.contain),
        ),
      );
      debugPrint('PERF option42 decoded bytes: full-size $before -> fitted $after');
      expect(before, greaterThan(10 * 1000 * 1000));
      expect(after, lessThan(60 * 1000));
    });

    testWidgets('question panel and quiz board tile decode to their box', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      final panel = await _decodedBytes(
        tester,
        (c) => SizedBox(
          width: 360,
          height: 164,
          child: Image(image: fitAsset(c, _big, width: 360, height: 164), fit: BoxFit.contain),
        ),
      );
      final tile = await _decodedBytes(
        tester,
        (_) => const SizedBox(width: 170, height: 170, child: FitAssetImage(_big)),
      );
      debugPrint('PERF question panel 360x164 decoded bytes: $panel; board tile 170x170: $tile');
      expect(panel, lessThan(1000 * 1000));
      expect(tile, lessThan(600 * 1000));
    });

    test('source guard: every image in the learning files has a decode limit', () {
      const files = [
        'lib/features/quizzes/quiz_play_screen.dart',
        'lib/features/quizzes/identify_quiz_screen.dart',
        'lib/features/home/lesson_reader_page.dart',
        'lib/features/home/lesson_rich_text.dart',
        'lib/features/home/lesson_quiz_page.dart',
        'lib/features/game/learn_runner.dart',
        'lib/features/identify/identify_detail_page.dart',
        'lib/features/identify/identify_screen.dart',
      ];
      final unbounded = <String>[];
      for (final path in files) {
        final src = File(path).readAsStringSync();
        for (final m in RegExp(r'(Image\.asset|CachedNetworkImage)\(').allMatches(src)) {
          final call = src.substring(m.start, (m.start + 420).clamp(0, src.length));
          final limited = RegExp(r'cacheWidth|cacheHeight|memCacheWidth|memCacheHeight').hasMatch(call);
          // Pinch-zoom viewer keeps full resolution on purpose.
          final zoom = src.substring((m.start - 200).clamp(0, src.length), m.start).contains('InteractiveViewer');
          if (!limited && !zoom) unbounded.add('$path:${'\n'.allMatches(src.substring(0, m.start)).length + 1}');
        }
      }
      expect(unbounded, isEmpty, reason: 'decode at display size (fitAsset / memCacheWidth)');
    });

    test('identify pages have no backdrop blur over scrolling content', () {
      for (final path in [
        'lib/features/identify/identify_screen.dart',
        'lib/features/identify/identify_detail_page.dart',
      ]) {
        expect(File(path).readAsStringSync().contains('BackdropFilter('), isFalse, reason: path);
      }
    });
  });

  group('bundled JSON parsed once, off the UI isolate', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('hourly pack (845 KB)', () async {
      late HourlyPack first;
      late HourlyPack second;
      final a = await _measure(() async => first = await HourlyPack.load());
      final b = await _measure(() async => second = await HourlyPack.load());
      debugPrint('PERF hourly pack open #1 ${a.$1} ms (UI stall ${a.$2} ms), #2 ${b.$1} ms (UI stall ${b.$2} ms), '
          '${first.questions.length} questions');
      expect(identical(first, second), isTrue);
      expect(first.questions.length, greaterThan(900));
      expect(b.$1, lessThan(5));
    });

    test('emergency directory (335 KB)', () async {
      late EmergencyDirectory first;
      late EmergencyDirectory second;
      final a = await _measure(() async => first = await loadEmergencyDirectory());
      final b = await _measure(() async => second = await loadEmergencyDirectory());
      debugPrint('PERF emergency open #1 ${a.$1} ms (UI stall ${a.$2} ms), #2 ${b.$1} ms (UI stall ${b.$2} ms), '
          '${first.items.length} rows');
      expect(identical(first, second), isTrue);
      expect(first.items.length, greaterThan(900));
      expect(first.items.first.searchKey, contains(first.items.first.name.toLowerCase()));
      expect(b.$1, lessThan(5));
    });

    test('safety library', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = await _measure(() => container.read(libraryCatalogProvider.future));
      final b = await _measure(() => container.read(libraryCatalogProvider.future));
      debugPrint('PERF safety library open #1 ${a.$1} ms (UI stall ${a.$2} ms), #2 ${b.$1} ms');
      expect((await container.read(libraryCatalogProvider.future)).isNotEmpty, isTrue);
      expect(b.$1, lessThan(5));
    });

    test('parsers match a direct parse', () async {
      final raw = await rootBundle.loadString('assets/data/hourly_quiz_pack.json', cache: false);
      final pack = await HourlyPack.load();
      expect(parseHourlyPack(raw).questions.map((q) => q.id).toList(), pack.questions.map((q) => q.id).toList());
    });
  });

  group('training_chapters content cached per session', () {
    test('one lesson completion refetches nothing; a new session refetches once', () async {
      SharedPreferences.setMockInitialValues({});
      final source = _CountingSource();
      final container = ProviderContainer(overrides: [
        trainingChaptersSourceProvider.overrideWithValue(source),
        authProvider.overrideWith(_TestAuth.new),
      ]);
      addTearDown(container.dispose);
      var ladderBuilds = 0;
      var moduleBuilds = 0;
      container.listen(trainingLadderProvider, (_, next) {
        if (next is AsyncData) ladderBuilds++;
      }, fireImmediately: true);
      container.listen(moduleLessonsProvider(1), (_, next) {
        if (next is AsyncData) moduleBuilds++;
      }, fireImmediately: true);
      await container.read(trainingLadderProvider.future);
      await container.read(moduleLessonsProvider(1).future);
      final auth = container.read(authProvider.notifier) as _TestAuth;

      Future<void> settle() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await container.read(trainingLadderProvider.future);
        await container.read(moduleLessonsProvider(1).future);
      }

      // What _completeLesson + refreshProfile do today, step by step.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_completed_lessons', ['m1c1']);
      container.invalidate(localCompletedLessonsProvider);
      await settle();
      await prefs.setStringList('local_completed_lessons', ['m1c1', '1_1']);
      container.invalidate(localCompletedLessonsProvider);
      await settle();
      auth.put(const AuthState(isLoading: true, profile: LinemanProfile(id: 'u1')));
      await settle();
      auth.put(const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['m1c1'], points: 20)));
      await settle();
      container.invalidate(trainingLadderProvider);
      container.invalidate(moduleLessonsProvider(1));
      await settle();

      final lessons = await container.read(moduleLessonsProvider(1).future);
      expect(lessons.firstWhere((l) => l.id == 'm1c1').isCompleted, isTrue);
      debugPrint('PERF lesson completion: ladder recomputed $ladderBuilds x, module list $moduleBuilds x '
          '(old code = one network fetch each); network fetches now index=${source.index} module=${source.module}');
      expect(ladderBuilds, greaterThan(3));
      expect(source.index, 1);
      expect(source.module, 1);

      // Sign-in as a different user is a new session: fetch again, once.
      auth.put(const AuthState(profile: LinemanProfile(id: 'u2')));
      await settle();
      expect(source.index, 2);
      expect(source.module, 2);
    });
  });
}
