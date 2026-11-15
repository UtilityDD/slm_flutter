// Birds and butterflies on Home and the ladder (owner, 2026-11-15): they come
// after a wait and leave, never more than two at once, taps pass through,
// nothing with "remove animations", no visitor while covered (TickerMode off),
// while the app is in the background or while the ladder's calm pauses loops.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/design/slm_design.dart';

Widget _host(Widget life, {bool reduce = false, bool ticker = true, VoidCallback? onTap}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: child!,
    ),
    home: TickerMode(
      enabled: ticker,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: GestureDetector(
              onTap: onTap,
              child: Container(key: const ValueKey('under'), width: 160, height: 160, color: const Color(0xFF223A6B)),
            ),
          ),
          // On top here, to prove taps go through it.
          Positioned.fill(child: life),
        ],
      ),
    ),
  );
}

/// Pumps [d] in 100 ms steps; returns the most visitors seen at once.
Future<int> _run(WidgetTester t, Duration d, List<int> seen) async {
  var most = 0;
  for (var i = 0; i < d.inMilliseconds ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
    if (seen.isNotEmpty && seen.last > most) most = seen.last;
  }
  return most;
}

int _now(List<int> seen) => seen.isEmpty ? 0 : seen.last;

bool _quiet(WidgetTester t) => !t.binding.hasScheduledFrame && SchedulerBinding.instance.transientCallbackCount == 0;

void main() {
  testWidgets('a visitor comes after the wait, flies away, and the sky goes quiet', (t) async {
    final seen = <int>[];
    await t.pumpWidget(_host(SlmAmbientLife(
      seed: 1,
      firstDelay: const Duration(seconds: 2),
      minGap: const Duration(seconds: 200),
      maxGap: const Duration(seconds: 200),
      onVisitors: seen.add,
    )));
    await t.pump(const Duration(milliseconds: 1900));
    expect(_now(seen), 0);
    expect(_quiet(t), isTrue, reason: 'no ticker while waiting');
    await t.pump(const Duration(milliseconds: 200));
    expect(_now(seen), 1);
    await t.pump(const Duration(milliseconds: 16));
    expect(t.binding.hasScheduledFrame, isTrue, reason: 'it flies');
    await _run(t, const Duration(seconds: 16), seen);
    expect(_now(seen), 0, reason: 'it flew far away');
    await t.pump(const Duration(milliseconds: 16));
    expect(_quiet(t), isTrue, reason: 'ticker stops between visitors');
    expect(t.takeException(), isNull);
  });

  testWidgets('never more than two at once', (t) async {
    final seen = <int>[];
    await t.pumpWidget(_host(SlmAmbientLife(
      seed: 3,
      firstDelay: const Duration(milliseconds: 100),
      minGap: const Duration(milliseconds: 500),
      maxGap: const Duration(milliseconds: 500),
      onVisitors: seen.add,
    )));
    final most = await _run(t, const Duration(seconds: 120), seen);
    expect(most, SlmAmbientLife.maxVisitors);
    expect(seen.every((n) => n <= SlmAmbientLife.maxVisitors), isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets('taps pass through to what is underneath', (t) async {
    final seen = <int>[];
    var taps = 0;
    await t.pumpWidget(_host(
      SlmAmbientLife(seed: 2, firstDelay: const Duration(milliseconds: 100), onVisitors: seen.add),
      onTap: () => taps++,
    ));
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(seconds: 2));
    expect(_now(seen), 1);
    expect(find.descendant(of: find.byType(SlmAmbientLife), matching: find.byType(IgnorePointer)), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('under')));
    expect(taps, 1);
  });

  testWidgets('remove animations: nothing at all, no frames', (t) async {
    final seen = <int>[];
    await t.pumpWidget(_host(
      SlmAmbientLife(seed: 1, firstDelay: const Duration(milliseconds: 100), onVisitors: seen.add),
      reduce: true,
    ));
    var frames = 0;
    for (var i = 0; i < 600; i++) {
      await t.pump(const Duration(milliseconds: 100));
      if (t.binding.hasScheduledFrame) frames++;
    }
    expect(seen, isEmpty);
    expect(frames, 0);
    expect(find.descendant(of: find.byType(SlmAmbientLife), matching: find.byType(CustomPaint)), findsNothing);
  });

  testWidgets('TickerMode off (covered): no visitor; back in view, they come again', (t) async {
    final seen = <int>[];
    Widget life() => SlmAmbientLife(seed: 1, firstDelay: const Duration(seconds: 1), onVisitors: seen.add);
    await t.pumpWidget(_host(life(), ticker: false));
    await _run(t, const Duration(seconds: 60), seen);
    expect(seen, isEmpty);
    expect(_quiet(t), isTrue);
    await t.pumpWidget(_host(life()));
    await _run(t, const Duration(milliseconds: 1500), seen);
    expect(_now(seen), 1);
  });

  testWidgets('app in the background: no visitor; resumed, they come again', (t) async {
    final seen = <int>[];
    addTearDown(() => t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    await t.pumpWidget(_host(SlmAmbientLife(seed: 1, firstDelay: const Duration(seconds: 1), onVisitors: seen.add)));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _run(t, const Duration(seconds: 60), seen);
    expect(seen, isEmpty);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _run(t, const Duration(milliseconds: 1500), seen);
    expect(_now(seen), 1);
  });

  testWidgets('the ladder\'s idle calm (loops paused): no new visitor', (t) async {
    final seen = <int>[];
    final calm = SlmMotionSettings()..pause();
    addTearDown(calm.dispose);
    await t.pumpWidget(_host(SlmMotionScope(
      settings: calm,
      child: SlmAmbientLife(seed: 1, firstDelay: const Duration(seconds: 1), onVisitors: seen.add),
    )));
    await _run(t, const Duration(seconds: 60), seen);
    expect(seen, isEmpty);
    calm.play();
    await _run(t, const Duration(milliseconds: 1500), seen);
    expect(_now(seen), 1);
  });
}
