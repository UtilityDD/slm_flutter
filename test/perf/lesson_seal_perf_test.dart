// The lesson win screen plays one stamp sequence and then must go idle:
// no loops, no frames once settled (target phones are 3–4 GB Android).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/home/lesson_seal_page.dart';
import 'package:slm_flutter/features/training/training_models.dart';

void main() {
  testWidgets('seal page stamps once, then draws no frames', (tester) async {
    const lesson = LessonCardItem(id: 'l2', moduleNumber: 1, chapterNumber: 2, title: 'পাঠ দুই');
    const next = LessonCardItem(id: 'l3', moduleNumber: 1, chapterNumber: 3, title: 'পাঠ তিন');
    await tester.pumpWidget(MaterialApp(
      theme: SlmTheme.night(),
      home: LessonSealPage(
        lesson: lesson,
        seals: const [true, true, false, false],
        mine: 1,
        revision: false,
        bn: true,
        next: next,
        onOpenNext: () {},
      ),
    ));

    var frames = 0;
    final sw = Stopwatch()..start();
    while (tester.binding.hasScheduledFrame && frames < 400) {
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    await tester.pump(const Duration(seconds: 2));
    final idle = tester.binding.hasScheduledFrame;
    debugPrint('PERF lesson seal: $frames frames to settle (${sw.elapsedMilliseconds} ms host), '
        'idle after settle: ${!idle}');

    expect(frames, lessThan(240), reason: 'the stamp sequence must end');
    expect(idle, isFalse, reason: 'a settled win screen draws zero frames');
    expect(find.text('পাঠ সম্পন্ন!'), findsOneWidget);
    expect(find.text('পরের পাঠ খুলে গেছে'), findsOneWidget);
    expect(find.textContaining('2/4'), findsOneWidget);
  });
}
