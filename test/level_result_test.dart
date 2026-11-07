import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';

void main() {
  test('mark counts first-try answers; 60% passes', () {
    final m = LessonMarks();
    m.settle(); // right first time
    m.miss();
    m.settle(); // right after a miss
    m.settle(right: false); // ended wrong
    m.settle();
    m.settle();
    expect(m.asked, 5);
    expect(m.clean, 3);
    expect(m.percent, 60);
    expect(m.passed, isTrue);
    m.settle(right: false);
    expect(m.passed, isFalse);
  });

  test('a level result keeps the best mark and counts plays', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final save = c.read(gameSaveProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    expect(await save.recordLevelResult('1.2/learn', 50), isNull);
    expect(await save.recordLevelResult('1.2/learn', 90), 50);
    expect(await save.recordLevelResult('1.2/learn', 70), 90);
    final s = c.read(gameSaveProvider);
    expect(s.bestMarkByRung['1.2/learn'], 90);
    expect(s.playsByRung['1.2/learn'], 3);
    final again = GameSave.fromJson(s.toJson());
    expect(again.bestMarkByRung['1.2/learn'], 90);
    expect(again.playsByRung['1.2/learn'], 3);
  });

  testWidgets('end nudge card shows its own words and buttons', (tester) async {
    const nudge = (title: 'জেনে রাখা ভালো', message: 'দুই মিনিটের পাঠ।');
    await tester.pumpWidget(MaterialApp(
      theme: SlmTheme.night(),
      home: Scaffold(
        body: Center(
          child: ReadLessonCard(
            atStart: false,
            nudge: nudge,
            lessonLine: 'পাঠ 1.2',
            onStart: () {},
            onLater: () {},
          ),
        ),
      ),
    ));
    expect(find.text('জেনে রাখা ভালো'), findsOneWidget);
    expect(find.text('পরে পড়ব'), findsOneWidget);
    expect(find.text('পাঠ পড়ুন'), findsOneWidget);
  });
}
