// "আমার পাঠ" (TrainingScreen): owner rule, training lessons open only through
// the game's level passes. Only lessons whose Learn rung is cleared in
// GameSave are listed; locked ones are not shown at all.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/training/training_models.dart';
import 'package:slm_flutter/features/training/training_provider.dart';
import 'package:slm_flutter/features/training/training_screen.dart';

class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1'));
}

List<LessonCardItem> _module(int m, int count) => [
      for (var c = 1; c <= count; c++)
        LessonCardItem(
          id: 'id-$m-$c',
          moduleNumber: m,
          chapterNumber: c,
          title: 'পাঠ শিরোনাম অনেক লম্বা হতে পারে, সুরক্ষা কবচ ও প্রথম দিনের ইউনিফর্ম $m-$c',
          isCompleted: c == 1,
        ),
    ];

Future<void> _pumpScreen(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = const Size(720, 1520);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith(_TestAuth.new),
      moduleLessonsProvider.overrideWith((ref, m) async => _module(m, 10)),
    ],
    child: const MaterialApp(home: TrainingScreen()),
  ));
  // GameSave hydrates from disk in a microtask.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.pump(const Duration(milliseconds: 600));
}

String _save(Map<String, String> progress) => jsonEncode(GameSave.empty.copyWith(rungProgress: progress).toJson());

void main() {
  test('passed lessons come from cleared Learn rungs only', () {
    final keys = passedLessonKeys({
      '1.1/learn': 'cleared',
      '1.2/learn': 'cleared',
      '1.3/learn': 'started',
      '1.4/do/1': 'cleared',
      '1.5/gate': 'cleared',
      '2.10/learn': 'cleared',
      '3.1/do/2': 'prove',
    });
    expect(keys, {'1.1', '1.2', '2.10'});
    expect(passedModules(keys), [1, 2]);
    expect(passedModules(const {}), isEmpty);
  });

  testWidgets('lists only the lessons passed in the game', (tester) async {
    await _pumpScreen(tester, prefs: {
      'game_save_v1': _save({
        '1.1/learn': 'cleared',
        '1.3/learn': 'cleared',
        '1.4/do/1': 'cleared',
        '2.2/learn': 'cleared',
      }),
      // Old reading progress never unlocks a lesson here.
      'local_completed_lessons': ['1.5', '1_5', 'id-1-5'],
    });

    expect(tester.takeException(), isNull);
    expect(find.text('আমার পাঠ'), findsOneWidget);
    // Module 2 (latest) opens by itself: only 2.2.
    expect(find.text('পাঠ 2.2'), findsOneWidget);
    expect(find.text('পাঠ 2.1'), findsNothing);
    // Modules with no passed lesson are not listed.
    expect(find.textContaining('টি পাঠ খোলা'), findsNWidgets(2));

    // Open module 1: lessons 1.1 and 1.3 only.
    await tester.tap(find.text('1'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('পাঠ 1.1'), findsOneWidget);
    expect(find.text('পাঠ 1.3'), findsOneWidget);
    for (final locked in ['1.2', '1.4', '1.5', '1.6', '1.10']) {
      expect(find.text('পাঠ $locked'), findsNothing, reason: 'lesson $locked is locked');
    }
  });

  testWidgets('nothing passed: a friendly empty state pointing to the path', (tester) async {
    await _pumpScreen(tester, prefs: {
      'local_completed_lessons': ['1.1', '1_1'],
    });

    expect(tester.takeException(), isNull);
    expect(find.text('এখনও কোনো পাঠ খোলেনি'), findsOneWidget);
    expect(find.text('পথে ফিরে যান'), findsOneWidget);
    expect(find.textContaining('পাঠ 1.'), findsNothing);
  });
}
