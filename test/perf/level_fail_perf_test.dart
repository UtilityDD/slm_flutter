// The below-pass panel drops, shakes and fills its meter once, then must go
// idle: no loops, no frames once settled (target phones are 3–4 GB Android).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/game/level_result_parts.dart';

void main() {
  testWidgets('fail panel animates once, then draws no frames', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      theme: SlmTheme.night(),
      home: Scaffold(
        body: Center(
          child: LevelFailPanel(
            percent: 40,
            muted: true,
            history: const LevelHistoryChip(plays: 2, bestMark: 80, bestMs: 72000),
            onRetry: () => retried = true,
            onRead: () {},
            onLeave: () {},
          ),
        ),
      ),
    ));

    var frames = 0;
    while (tester.binding.hasScheduledFrame && frames < 400) {
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    await tester.pump(const Duration(seconds: 2));
    final idle = tester.binding.hasScheduledFrame;
    debugPrint('PERF level fail: $frames frames to settle, idle after settle: ${!idle}');

    expect(frames, lessThan(160), reason: 'the fail sequence must end');
    expect(idle, isFalse, reason: 'a settled fail panel draws zero frames');
    expect(tester.takeException(), isNull);
    expect(find.text('এবার পাস হলো না'), findsOneWidget);
    expect(find.textContaining('40%'), findsOneWidget);
    expect(find.textContaining('সেরা 80%'), findsOneWidget);
    await tester.tap(find.text('আবার খেলুন'));
    expect(retried, isTrue);
  });
}
