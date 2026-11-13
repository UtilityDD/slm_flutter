// Gesture hints (GAME_LEVEL_PLAYBOOK.md §1): a hand shows HOW to interact
// after idle or confusion — never WHAT the answer is. It appears after the
// idle wait, hides on any touch, plays twice then draws nothing, comes at most
// three times per waiting state, never presses an option while sweeping, and
// stays still under reduced motion. Off in widget tests unless opted in.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';

final _hand = find.byKey(const ValueKey('gesture-hint'));

const _opts = [Rect.fromLTWH(20, 100, 320, 60), Rect.fromLTWH(20, 180, 320, 60), Rect.fromLTWH(20, 260, 320, 60)];

class _Host extends StatelessWidget {
  const _Host({required this.spec, this.waiting = true, this.waitKey, this.taps, this.reduce = false, this.controller});
  final HintSpec? spec;
  final bool waiting;
  final Object? waitKey;
  final List<int>? taps;
  final bool reduce;
  final IdleHintController? controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(360, 640), disableAnimations: reduce),
        child: Scaffold(
          body: IdleHint(
            waiting: waiting,
            waitKey: waitKey,
            controller: controller,
            spec: (_) => spec,
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Color(0xFF0B1630))),
                for (var i = 0; i < _opts.length; i++)
                  Positioned.fromRect(
                    rect: _opts[i],
                    child: GestureDetector(
                      key: ValueKey('opt-$i'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => taps?.add(i),
                      child: const ColoredBox(color: Color(0xFF223355)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IdleHintState _state(WidgetTester t) => t.state<IdleHintState>(find.byType(IdleHint));

Future<void> _pumpFor(WidgetTester t, Duration d, {Duration step = const Duration(milliseconds: 100)}) async {
  var left = d;
  while (left > Duration.zero) {
    final s = left < step ? left : step;
    await t.pump(s);
    left -= s;
  }
}

/// Pumps [d] and counts how often the hand came up.
Future<int> _countShows(WidgetTester t, Duration d) async {
  var shows = 0;
  var was = false;
  var left = d;
  while (left > Duration.zero) {
    await t.pump(const Duration(milliseconds: 200));
    left -= const Duration(milliseconds: 200);
    final now = _hand.evaluate().isNotEmpty;
    if (now && !was) shows++;
    was = now;
  }
  return shows;
}

void main() {
  setUp(() => GestureHints.debugEnableInTests = true);
  tearDown(() => GestureHints.debugEnableInTests = false);

  testWidgets('off in widget tests unless a test opts in', (t) async {
    GestureHints.debugEnableInTests = false;
    await t.pumpWidget(const _Host(spec: HintSpec.tap(Offset(180, 400))));
    await _pumpFor(t, const Duration(seconds: 40), step: const Duration(seconds: 1));
    expect(_hand, findsNothing);
    expect(t.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('appears after the idle wait, only while the level waits', (t) async {
    await t.pumpWidget(const _Host(spec: HintSpec.tap(Offset(180, 400))));
    await _pumpFor(t, const Duration(milliseconds: 7800));
    expect(_hand, findsNothing, reason: 'not before ~8 s');
    await _pumpFor(t, const Duration(milliseconds: 400));
    expect(_hand, findsOneWidget);

    await t.pumpWidget(const _Host(spec: HintSpec.tap(Offset(180, 400)), waiting: false));
    await t.pump();
    expect(_hand, findsNothing, reason: 'hidden when the level stops waiting');
    await _pumpFor(t, const Duration(seconds: 40), step: const Duration(seconds: 1));
    expect(_hand, findsNothing);
  });

  testWidgets('any touch hides it and restarts the wait', (t) async {
    await t.pumpWidget(const _Host(spec: HintSpec.tap(Offset(180, 400))));
    await _pumpFor(t, const Duration(milliseconds: 8300));
    expect(_hand, findsOneWidget);
    await t.tapAt(const Offset(30, 600));
    await t.pump();
    expect(_hand, findsNothing);
    await _pumpFor(t, const Duration(milliseconds: 7500));
    expect(_hand, findsNothing, reason: 'the wait starts again from the touch');
    await _pumpFor(t, const Duration(milliseconds: 800));
    expect(_hand, findsOneWidget);
  });

  testWidgets('plays twice, then zero frames', (t) async {
    await t.pumpWidget(const _Host(spec: HintSpec.tap(Offset(180, 400))));
    await _pumpFor(t, const Duration(milliseconds: 8100));
    expect(_hand, findsOneWidget);
    // One tap lap is 1.6 s; two laps 3.2 s.
    await _pumpFor(t, const Duration(milliseconds: 2400));
    expect(_hand, findsOneWidget, reason: 'second lap still playing');
    await _pumpFor(t, const Duration(milliseconds: 1200));
    expect(_hand, findsNothing);
    expect(_state(t).shows, 1);
    await t.pump(const Duration(milliseconds: 16));
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'idle again: no frames');
    var frames = 0;
    for (var i = 0; i < 60; i++) {
      if (t.binding.hasScheduledFrame) frames++;
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(frames, 0);
  });

  testWidgets('never more than three times per waiting state; a new state re-arms', (t) async {
    await t.pumpWidget(const _Host(spec: HintSpec.tap(Offset(180, 400)), waitKey: 1));
    final shows = await _countShows(t, const Duration(seconds: 150));
    expect(shows, 3);
    expect(_state(t).shows, 3);

    await t.pumpWidget(const _Host(spec: HintSpec.tap(Offset(180, 400)), waitKey: 2));
    expect(await _countShows(t, const Duration(seconds: 10)), 1, reason: 'next round: hints again');
  });

  testWidgets('comes back after the longer gap, not the short one', (t) async {
    await t.pumpWidget(const _Host(spec: HintSpec.tap(Offset(180, 400))));
    await _pumpFor(t, const Duration(milliseconds: 8100));
    await _pumpFor(t, const Duration(milliseconds: 3400));
    expect(_hand, findsNothing);
    await _pumpFor(t, const Duration(seconds: 20));
    expect(_hand, findsNothing, reason: 'waits ~25 s after an untouched hint');
    await _pumpFor(t, const Duration(seconds: 6));
    expect(_hand, findsOneWidget);
  });

  testWidgets('three taps on nothing within 4 s bring the hand at once', (t) async {
    final taps = <int>[];
    await t.pumpWidget(_Host(spec: const HintSpec.sweep(_opts), taps: taps));
    await t.pump(const Duration(seconds: 1));
    await t.tapAt(const Offset(180, 500));
    await t.pump(const Duration(milliseconds: 400));
    await t.tapAt(const Offset(180, 520));
    await t.pump(const Duration(milliseconds: 400));
    expect(_hand, findsNothing);
    await t.tapAt(const Offset(180, 540));
    await t.pump();
    expect(_hand, findsOneWidget);
    expect(taps, isEmpty);
  });

  testWidgets('taps on a real control are not misses', (t) async {
    final taps = <int>[];
    await t.pumpWidget(_Host(spec: const HintSpec.sweep(_opts), taps: taps));
    await t.pump(const Duration(seconds: 1));
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(const ValueKey('opt-1')));
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(_hand, findsNothing);
    expect(taps, [1, 1, 1]);
  });

  testWidgets('a level can report misses through the controller', (t) async {
    final c = IdleHintController();
    await t.pumpWidget(_Host(spec: const HintSpec.tap(Offset(180, 400)), controller: c));
    await t.pump(const Duration(seconds: 1));
    c
      ..missTap()
      ..missTap();
    await t.pump();
    expect(c.showing, isFalse);
    c.missTap();
    await t.pump();
    expect(c.showing, isTrue);
    c.hide();
    await t.pump();
    expect(_hand, findsNothing);
  });

  testWidgets('a sweep passes over every option and never presses one', (t) async {
    final taps = <int>[];
    await t.pumpWidget(_Host(spec: const HintSpec.sweep(_opts), taps: taps));
    await _pumpFor(t, const Duration(milliseconds: 8050));
    expect(_hand, findsOneWidget);
    final visited = <int>{};
    var maxPress = 0.0;
    var rippled = false;
    while (_hand.evaluate().isNotEmpty) {
      final f = _state(t).debugFrame;
      if (f != null) {
        maxPress = f.press > maxPress ? f.press : maxPress;
        rippled = rippled || f.ripple != null || f.ring != null;
        for (var i = 0; i < _opts.length; i++) {
          if (f.opacity > 0.5 && _opts[i].contains(f.tip)) visited.add(i);
        }
      }
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(visited, {0, 1, 2}, reason: 'the hand passes over all the choices');
    expect(maxPress, 0, reason: 'never presses');
    expect(rippled, isFalse, reason: 'no tap ripple on a choice');
    expect(taps, isEmpty, reason: 'the hand never sends a touch');
  });

  testWidgets('tap shows a press and a ripple; hold shows the filling ring', (t) async {
    Future<(double, bool, bool)> lap(HintSpec spec) async {
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(_Host(spec: spec, waitKey: spec.kind));
      await _pumpFor(t, const Duration(milliseconds: 8050));
      var press = 0.0;
      var ripple = false;
      var ring = false;
      while (_hand.evaluate().isNotEmpty) {
        final f = _state(t).debugFrame;
        if (f != null) {
          press = f.press > press ? f.press : press;
          ripple = ripple || f.ripple != null;
          ring = ring || f.ring != null;
        }
        await t.pump(const Duration(milliseconds: 16));
      }
      return (press, ripple, ring);
    }

    final tap = await lap(const HintSpec.tap(Offset(180, 400)));
    expect(tap.$1, greaterThan(0.9));
    expect(tap.$2, isTrue);
    final hold = await lap(const HintSpec.hold(Offset(180, 400)));
    expect(hold.$1, greaterThan(0.9));
    expect(hold.$3, isTrue);
  });

  testWidgets('a drag only nudges a short way in its direction', (t) async {
    await t.pumpWidget(const _Host(spec: HintSpec.drag(Offset(180, 400), toward: Offset(1, 0), travel: 400)));
    await _pumpFor(t, const Duration(milliseconds: 8050));
    var far = 0.0;
    while (_hand.evaluate().isNotEmpty) {
      final f = _state(t).debugFrame;
      if (f != null && f.press > 0.5) {
        final d = f.tip - const Offset(180, 400);
        far = d.dx > far ? d.dx : far;
        expect(d.dy.abs(), lessThan(1));
      }
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(far, greaterThan(40));
    expect(far, lessThanOrEqualTo(HintSpec.maxDragTravel + 0.5));
  });

  testWidgets('reduced motion: a still hand with a soft fade only', (t) async {
    await t.pumpWidget(const _Host(spec: HintSpec.sweep(_opts), reduce: true));
    await _pumpFor(t, const Duration(milliseconds: 8050));
    expect(_hand, findsOneWidget);
    final tips = <Offset>{};
    final opacities = <double>[];
    while (_hand.evaluate().isNotEmpty) {
      final f = _state(t).debugFrame;
      if (f != null) {
        tips.add(f.tip);
        opacities.add(f.opacity);
        expect(f.press, 0);
        expect(f.ripple, isNull);
        expect(f.trailFrom, isNull);
      }
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(tips, hasLength(1), reason: 'the hand does not move');
    expect(opacities.reduce((a, b) => a > b ? a : b), greaterThan(0.5), reason: 'it fades in');
    expect(opacities.first, lessThan(0.3), reason: 'softly');
    // A still sweep hand points between the choices, not on one of them.
    expect(_opts.any((r) => r.deflate(4).contains(tips.single)), isFalse);
  });

  testWidgets('ChoiceDeck sweeps its open cards and picks nothing', (t) async {
    final picked = <String>[];
    const options = [ChoiceOption('এক নম্বর কারণ', false), ChoiceOption('দুই নম্বর কারণ', true), ChoiceOption('তিন নম্বর কারণ', false)];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ChoiceDeck(options: options, quiet: false, muted: true, wrong: const {'এক নম্বর কারণ'}, onPick: (o, _) => picked.add(o.textBn)),
        ),
      ),
    ));
    await _pumpFor(t, const Duration(milliseconds: 8300));
    expect(_hand, findsOneWidget);
    final st = _state(t);
    expect(st.debugOptions, hasLength(2), reason: 'only the cards still open');
    while (_hand.evaluate().isNotEmpty) {
      expect(st.debugFrame?.press ?? 0, 0);
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(picked, isEmpty);

    // Picked: the deck no longer waits.
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ChoiceDeck(options: options, quiet: false, muted: true, picked: 'দুই নম্বর কারণ', onPick: (o, _) => picked.add(o.textBn)),
        ),
      ),
    ));
    await _pumpFor(t, const Duration(seconds: 40), step: const Duration(seconds: 1));
    expect(_hand, findsNothing);
  });

  testWidgets('ChoiceDeck with one open card left shows no hand (never points at the answer)', (t) async {
    const options = [ChoiceOption('এক নম্বর কারণ', false), ChoiceOption('দুই নম্বর কারণ', true), ChoiceOption('তিন নম্বর কারণ', false)];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ChoiceDeck(options: options, quiet: false, muted: true, wrong: const {'এক নম্বর কারণ', 'তিন নম্বর কারণ'}, onPick: (_, _) {}),
        ),
      ),
    ));
    await _pumpFor(t, const Duration(seconds: 40), step: const Duration(seconds: 1));
    expect(_hand, findsNothing);
  });

  testWidgets('ChoiceDeck preview: the hand sweeps over ✕ and ✓ as a pair, pressing neither', (t) async {
    final picked = <String>[];
    const options = [ChoiceOption('এক নম্বর কারণ', false), ChoiceOption('দুই নম্বর কারণ', true), ChoiceOption('তিন নম্বর কারণ', false)];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ChoiceDeck(options: options, quiet: true, muted: true, onPick: (o, _) => picked.add(o.textBn)),
        ),
      ),
    ));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('deal-দুই নম্বর কারণ')));
    await _pumpFor(t, ChoiceDeck.armDelay + const Duration(milliseconds: 8300));
    expect(_hand, findsOneWidget);
    final st = _state(t);
    expect(st.debugOptions, hasLength(2), reason: 'both buttons, never one alone');
    final ok = t.getRect(find.byKey(const ValueKey('choice-confirm')));
    final no = t.getRect(find.byKey(const ValueKey('choice-reject')));
    final box = t.getTopLeft(find.byType(IdleHint));
    final rects = st.debugOptions.map((r) => r.shift(box)).toList();
    expect(rects.any((r) => (r.center - ok.center).distance < 2), isTrue);
    expect(rects.any((r) => (r.center - no.center).distance < 2), isTrue);
    while (_hand.evaluate().isNotEmpty) {
      expect(st.debugFrame?.press ?? 0, 0);
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(picked, isEmpty);
    expect(find.byKey(const ValueKey('choice-confirm')), findsOneWidget, reason: 'the preview is still open');
  });

  testWidgets('a sweep leaves out options outside its box', (t) async {
    await t.pumpWidget(const _Host(spec: HintSpec.sweep([..._opts, Rect.fromLTWH(20, 900, 320, 60)], space: HintSpace.local)));
    await _pumpFor(t, const Duration(milliseconds: 8300));
    expect(_hand, findsOneWidget);
    expect(_state(t).debugOptions, hasLength(3));
  });

  testWidgets('covered by another route: no hand offstage, and it blocks no other hint', (t) async {
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: Scaffold(body: IdleHint(waiting: true, spec: (_) => const HintSpec.tap(Offset(180, 300)), child: const SizedBox.expand())),
    ));
    unawaited(nav.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: IdleHint(key: const ValueKey('top'), waiting: true, idle: const Duration(seconds: 10), spec: (_) => const HintSpec.tap(Offset(180, 300)), child: const SizedBox.expand()),
      ),
    )));
    await t.pumpAndSettle();
    final below = t.state<IdleHintState>(find.byType(IdleHint, skipOffstage: false).first);
    await _pumpFor(t, const Duration(milliseconds: 8300));
    expect(below.showing, isFalse, reason: 'the covered level shows no hand');
    await _pumpFor(t, const Duration(seconds: 2));
    expect(t.state<IdleHintState>(find.byKey(const ValueKey('top'))).showing, isTrue, reason: 'the visible page still gets its hint');
  });

  test('grid cells follow the board layout', () {
    final cells = HintSpec.gridCells(size: const Size(314, 600), count: 5, aspect: 0.9);
    expect(cells, hasLength(5));
    expect(cells[0].left, 0);
    expect(cells[1].left, closeTo(164, 0.01));
    expect(cells[2].top, closeTo(150 / 0.9 + 14, 0.01));
  });
}
