// Lesson 4.4 (ডিও ফিউজ পরিচালনা), কাজ 2 "ফিউজ উড়েছে — কেন?": the rules
// (spot the dropped fuse; open all three and find the fault first; the
// docket's link, never thick wire; the link steps in order; stand aside, face
// aside, one push; a normal spark is left alone, a re-blow means stop), the
// deal, the option libraries, and the level in the shell: idle perf, the guide
// first, full clean plays with the coworker refused (at the tray / at the
// re-blow), he comes even on a fast play (the tray waits for him), a sound
// fuse called dropped costs a slip, slip cards, three strikes, the deadly
// freezes, the gesture hint (a sweep, never one fuse).
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_do_refuse.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/order_steps.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(rungId: '4.4/do/2', kind: CatalogRungKind.doKind, lessonId: '4.4', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);

final _pack = m4DoRefusePacks['do_4_4_b']!;

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (f.evaluate().isNotEmpty) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return f.evaluate().isNotEmpty;
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
  for (final x in texts)
    if (_label(x).evaluate().isNotEmpty) _label(x),
];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M4DoRefuseGeo get _geo => M4DoRefuseGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _screen(Offset design) => design * _k;
Future<void> _tapUnit(WidgetTester t, int p) => t.tapAt(_screen(_geo.unitOf(p).center + const Offset(0, 20)));

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: SizedBox()),
      ),
    ),
  );
  unawaited(
    nav.currentState!.push(
      MaterialPageRoute<bool>(
        builder: (_) => M4DoRefusePage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
      ),
    ),
  );
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _refuse(WidgetTester t, CoworkerScript s) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, s.right);
  await _pump(t, 2000);
}

Future<void> _reason(WidgetTester t, int round, M4DoRefuseDeal d) async {
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $round');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, M4DoRefuseLines.whyRight(round, d));
  await _pump(t, 6000);
}

Future<void> _roundFind(WidgetTester t, M4DoRefuseDeal d) async {
  await _tapUnit(t, d.phase);
  await _pump(t, 600);
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, M4DoRefuseLines.decideRight);
  await _pump(t, 1200);
  for (var i = 0; i < 3; i++) {
    if (i == d.phase) continue;
    await _tapUnit(t, i);
    await _pump(t, 500);
  }
  await _pump(t, 400);
  await _tapUnit(t, d.phase);
  await _pump(t, 600);
  await _reason(t, 0, d);
}

Future<void> _steps(WidgetTester t) async {
  for (final l in [M4DoRefuseLines.cloth, M4DoRefuseLines.topContact, M4DoRefuseLines.bottomContact, M4DoRefuseLines.port, M4DoRefuseLines.ready]) {
    await t.tap(_label(l), warnIfMissed: false);
    await _pump(t, 250);
  }
}

Future<void> _roundLink(WidgetTester t, M4DoRefuseDeal d) async {
  if (d.call == M4DoRefuseCall.link) await _refuse(t, M4DoRefuseLines.coworkerLink);
  expect(await _pumpUntil(t, _label(d.rating), maxMs: 3000), isTrue);
  await t.tap(_label(d.rating), warnIfMissed: false);
  await _pump(t, 500);
  await _steps(t);
  await _pump(t, 400);
  await _reason(t, 1, d);
}

Future<void> _push(WidgetTester t, M4DoRefuseDeal d) async {
  final g = _geo;
  await t.tapAt(_screen(Offset(M4DoRefuseGeo.phaseX[d.phase] - 70, g.groundY + 20)));
  await _pump(t, 800);
  await t.tapAt(_screen(g.hingeOf(d.phase)));
  await _pump(t, 500);
  await t.tap(_label(M4DoRefuseLines.faceAside), warnIfMissed: false);
  await _pump(t, 200);
  await t.dragFrom(_screen(const Offset(200, 400)), const Offset(0, -140));
  await _pump(t, 1500);
}

Future<void> _roundClose(WidgetTester t, M4DoRefuseDeal d) async {
  await _push(t, d);
  if (d.outcome == M4DoRefuseOutcome.reblows && d.call == M4DoRefuseCall.reblow) {
    await _refuse(t, M4DoRefuseLines.coworkerReblow);
  } else {
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, d.outcome == M4DoRefuseOutcome.settles ? M4DoRefuseLines.settleRight : M4DoRefuseLines.reblowRight);
    await _pump(t, 1200);
  }
  if (d.outcome == M4DoRefuseOutcome.settles) {
    for (var i = 0; i < 3; i++) {
      if (i == d.phase) continue;
      await _tapUnit(t, i);
      await _pump(t, 500);
    }
  }
  await _reason(t, 2, d);
}

void main() {
  group('rules', () {
    test('the deal: one dropped phase, the docket rating on the tray with thick wire; fresh each play', () {
      final seen = <String>{};
      final outcomes = <M4DoRefuseOutcome>{};
      final calls = <M4DoRefuseCall>{};
      for (var s = 0; s < 80; s++) {
        final d = m4DoRefuseDeal(math.Random(s));
        expect(d.phase, inInclusiveRange(0, 2));
        expect(d.tray, hasLength(4));
        expect(d.tray.where((x) => x == null), hasLength(1));
        expect(d.tray, contains(d.rating));
        expect(d.tray.whereType<String>().toSet().length, 3);
        if (d.call == M4DoRefuseCall.reblow) expect(d.outcome, M4DoRefuseOutcome.reblows);
        outcomes.add(d.outcome);
        calls.add(d.call);
        seen.add('${d.phase}${d.rating}${d.tray}${d.outcome.name}${d.call.name}${d.portBlocked}${d.linkTopic.name}');
      }
      expect(seen.length, greaterThan(60));
      expect(outcomes, M4DoRefuseOutcome.values.toSet());
      expect(calls, M4DoRefuseCall.values.toSet());
    });

    M4DoRefuseDeal deal({M4DoRefuseOutcome o = M4DoRefuseOutcome.settles}) => M4DoRefuseDeal(
      phase: 1,
      rating: '10A',
      tray: const ['6A', '10A', null, '20A'],
      outcome: o,
      call: M4DoRefuseCall.link,
      portBlocked: true,
      linkTopic: M4DoRefuseLinkTopic.rating,
    );

    M4DoRefuseRun toLink(M4DoRefuseRun r) {
      expect(r.spot(1).$1, isTrue);
      r.decide(right: true);
      r
        ..openOther(0)
        ..openOther(2)
        ..lower(1);
      r.next();
      return r;
    }

    test('ক: a sound fuse called dropped is a slip; refit at once is a slip; the others open; the barrel comes down', () {
      final r = M4DoRefuseRun(deal());
      expect(r.spot(0), (false, M4DoRefuseMistakes.wrongFuse));
      expect(r.slips, 1, reason: 'a wrong flag costs a slip');
      expect(r.phase, M4DoRefusePhase.spot);
      expect(r.spot(1), (true, null));
      expect(r.spot(0), (false, null), reason: 'spotted: further taps do nothing');
      expect(r.barrels, [M4DoRefuseBarrel.closed, M4DoRefuseBarrel.open, M4DoRefuseBarrel.closed]);
      expect(r.decide(right: false), M4DoRefuseMistakes.refitAtOnce);
      expect(r.slips, 2);
      expect(r.phase, M4DoRefusePhase.openOthers, reason: 'the guide put it right');
      expect(r.openOther(1), isFalse, reason: 'the blown one is already open');
      expect(r.lower(1), isFalse, reason: 'the others first');
      expect(r.openOther(0), isTrue);
      expect(r.openOther(2), isTrue);
      expect(r.phase, M4DoRefusePhase.lower);
      expect(r.barrels, [M4DoRefuseBarrel.open, M4DoRefuseBarrel.open, M4DoRefuseBarrel.open]);
      expect(r.lower(1), isTrue);
      expect(r.barrels[1], M4DoRefuseBarrel.gone);
      expect(r.clean, isFalse);
      final ok = M4DoRefuseRun(deal())..spot(1);
      expect(ok.decide(right: true), isNull);
      expect(ok.caught, contains(M4DoRefuseLines.caughtDecide));
    });

    test('খ: thick wire is deadly; a wrong rating is a slip (the docket link given); the steps in order', () {
      final a = toLink(M4DoRefuseRun(deal()));
      expect(a.phase, M4DoRefusePhase.pick);
      expect(a.pick(null), M4DoRefuseMistakes.thickWire);
      expect(a.deadly!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = toLink(M4DoRefuseRun(deal()));
      expect(b.pick('20A'), M4DoRefuseMistakes.wrongRating);
      expect(b.link, '10A');
      expect(b.phase, M4DoRefusePhase.fit);
      final c = toLink(M4DoRefuseRun(deal()));
      expect(c.pick('10A'), isNull);
      expect(c.caught, contains(M4DoRefuseLines.caughtRating));
      expect(c.fit('wrap').mistake, M4DoRefuseMistakes.noClean);
      expect(c.fit('clean').kind, OrderTapKind.ok);
      expect(c.fit('port').mistake, M4DoRefuseMistakes.noButton);
      expect(c.fit('button').kind, OrderTapKind.ok);
      expect(c.fit('ready').mistake, M4DoRefuseMistakes.noWrap);
      expect(c.fit('wrap').kind, OrderTapKind.ok);
      expect(c.fit('ready').mistake, M4DoRefuseMistakes.portUnchecked);
      expect(c.fit('port').kind, OrderTapKind.ok);
      expect(c.isFitted('port'), isTrue);
      expect(c.fit('ready').allDone, isTrue);
      expect(c.phase, M4DoRefusePhase.done);
      expect(c.slips, 4);
      expect(c.caught, isNot(contains(M4DoRefuseLines.caughtLink)));
      final d = toLink(M4DoRefuseRun(deal()))..pick('10A');
      for (final s in m4DoRefuseSteps) {
        expect(d.fit(s).kind, OrderTapKind.ok);
      }
      expect(d.caught, contains(M4DoRefuseLines.caughtLink));
    });

    M4DoRefuseRun toClose(M4DoRefuseOutcome o) {
      final r = toLink(M4DoRefuseRun(deal(o: o)))..pick('10A');
      for (final s in m4DoRefuseSteps) {
        r.fit(s);
      }
      r.next();
      expect(r.phase, M4DoRefusePhase.stand);
      return r;
    }

    test('গ: under the fuse is a slip, too far not scored; seat; face aside + one quick push', () {
      expect(m4DoRefuseStandOf(0), M4DoRefuseStand.under);
      expect(m4DoRefuseStandOf(-70), M4DoRefuseStand.side);
      expect(m4DoRefuseStandOf(160), M4DoRefuseStand.far);
      final a = toClose(M4DoRefuseOutcome.settles);
      expect(a.barrels[1], M4DoRefuseBarrel.gone, reason: 'on the rod');
      expect(a.stand(200).$2, isNull);
      expect(a.phase, M4DoRefusePhase.stand);
      expect(a.stand(5).$2, M4DoRefuseMistakes.underFuse);
      expect(a.seat(), isTrue);
      expect(a.barrels[1], M4DoRefuseBarrel.open);
      expect(a.push(30, 100).$1, M4DoRefusePush.short);
      expect(a.push(120, 2000).$1, M4DoRefusePush.slow);
      expect(a.slips, 1);
      expect(a.push(120, 300).$2, M4DoRefuseMistakes.faceIn);
      expect(a.phase, M4DoRefusePhase.watch);
      final b = toClose(M4DoRefuseOutcome.settles)
        ..stand(-70)
        ..seat()
        ..turnFace();
      expect(b.push(120, 300), (M4DoRefusePush.done, null));
      expect(b.caught, containsAll([M4DoRefuseLines.caughtStand, M4DoRefuseLines.caughtPush]));
    });

    test('গ: a normal spark — reopening is a slip, then the other two one by one; a re-blow — stop, reclosing is a slip', () {
      M4DoRefuseRun pushed(M4DoRefuseOutcome o) {
        final r = toClose(o)
          ..stand(-70)
          ..seat()
          ..turnFace();
        r.push(120, 300);
        return r;
      }

      final a = pushed(M4DoRefuseOutcome.settles);
      expect(a.barrels[1], M4DoRefuseBarrel.closed);
      expect(a.watch(right: false), M4DoRefuseMistakes.reopen);
      expect(a.phase, M4DoRefusePhase.closeOthers);
      expect(a.closeOther(1), isFalse);
      expect(a.closeOther(0), isTrue);
      expect(a.closeOther(2), isTrue);
      expect(a.phase, M4DoRefusePhase.done);
      expect(a.barrels, [M4DoRefuseBarrel.closed, M4DoRefuseBarrel.closed, M4DoRefuseBarrel.closed]);
      final b = pushed(M4DoRefuseOutcome.settles);
      expect(b.watch(right: true), isNull);
      expect(b.caught, contains(M4DoRefuseLines.caughtSettle));
      final c = pushed(M4DoRefuseOutcome.reblows);
      expect(c.barrels[1], M4DoRefuseBarrel.open, reason: 'it blew again');
      expect(c.watch(right: false), M4DoRefuseMistakes.reclose);
      expect(c.phase, M4DoRefusePhase.done);
      final d = pushed(M4DoRefuseOutcome.reblows);
      expect(d.watch(right: true), isNull);
      expect(d.phase, M4DoRefusePhase.done);
      expect(d.caught, contains(M4DoRefuseLines.caughtReblow));
      d.next();
      expect(d.done, isTrue);
      expect(d.passed, isTrue);
      expect(d.percent, 100);
    });

    test('English digits only; every mistake has its picture, a stable key; one deadly', () {
      final all = <String>[
        M4DoRefuseLines.intro,
        ...M4DoRefuseLines.tasks,
        ...M4DoRefuseLines.decideRight,
        ...M4DoRefuseLines.decideWrong,
        ...M4DoRefuseLines.settleRight,
        ...M4DoRefuseLines.settleWrong,
        ...M4DoRefuseLines.reblowRight,
        ...M4DoRefuseLines.reblowWrong,
        ...M4DoRefuseLines.othersWhy,
        ...M4DoRefuseLines.ratingWhy,
        ...M4DoRefuseLines.portWhy,
        ...M4DoRefuseLines.settleWhy,
        ...M4DoRefuseLines.reblowWhy,
        ...M4DoRefuseLines.whyWrong,
        for (final s in [M4DoRefuseLines.coworkerLink, M4DoRefuseLines.coworkerReblow]) ...[...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        for (final m in M4DoRefuseMistakes.all) m.textBn,
        for (final r in m4DoRefuseRatings) M4DoRefuseLines.docketBn(r),
        M4DoRefuseLines.allSet,
        M4DoRefuseLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M4DoRefuseMistakes.all.where((m) => m.deadly).toList(), [M4DoRefuseMistakes.thickWire]);
      for (final m in M4DoRefuseMistakes.all) {
        expect(m.key, startsWith('4.4/m4_do_refuse/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(M4DoRefuseMistakes.all.map((m) => m.key).toSet().length, M4DoRefuseMistakes.all.length);
      expect(m4DoRefusePacks.keys, ['do_4_4_b']);
      expect(_pack.quickMs, 65000);
    });

    test('options: same length, big enough; one right per deal; his choices too', () {
      expectSameLength('why', [
        ...M4DoRefuseLines.othersWhy,
        ...M4DoRefuseLines.ratingWhy,
        ...M4DoRefuseLines.portWhy,
        ...M4DoRefuseLines.settleWhy,
        ...M4DoRefuseLines.reblowWhy,
        ...M4DoRefuseLines.whyWrong,
      ]);
      for (final (r, w) in [
        (M4DoRefuseLines.decideRight, M4DoRefuseLines.decideWrong),
        (M4DoRefuseLines.settleRight, M4DoRefuseLines.settleWrong),
        (M4DoRefuseLines.reblowRight, M4DoRefuseLines.reblowWrong),
        (M4DoRefuseLines.othersWhy, M4DoRefuseLines.whyWrong),
        (M4DoRefuseLines.ratingWhy, M4DoRefuseLines.whyWrong),
        (M4DoRefuseLines.portWhy, M4DoRefuseLines.whyWrong),
        (M4DoRefuseLines.settleWhy, M4DoRefuseLines.whyWrong),
        (M4DoRefuseLines.reblowWhy, M4DoRefuseLines.whyWrong),
      ]) {
        expectSameLength(r.first, [...r, ...w]);
        expectLibrary(r.first, r, w);
        for (var s = 0; s < 10; s++) {
          final d = dealChoices(r, w, math.Random(s));
          expect(d.where((o) => o.correct).length, 1);
          expect(d.map((o) => o.textBn).toSet().length, 3);
        }
      }
      for (final s in [M4DoRefuseLines.coworkerLink, M4DoRefuseLines.coworkerReblow]) {
        expectSameLength('choice', [...s.right, ...s.wrong]);
        expectLibrary('choice', s.right, s.wrong);
      }
      expect(M4DoRefuseLines.recordLines, hasLength(2));
      // The free "too far" reply stays neutral: it never names the right spot.
      expect(M4DoRefuseLines.tooFar, isNot(contains('পাশে')));
      expect(M4DoRefuseLines.tooFar, isNot(contains('কাছে')));
    });
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    int seedWhere(bool Function(M4DoRefuseDeal d) ok) {
      var s = 0;
      while (!ok(m4DoRefuseDeal(math.Random(s)))) {
        s++;
      }
      return s;
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: M4DoRefusePage(ctx: _ctx, pack: _pack, muted: true, seed: 1),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
        await _pump(t, 14000);
        rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugPrint('PERF m4_do_refuse ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; then the docket', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      const seed = 2;
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: M4DoRefusePage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.text(M4DoRefuseLines.docketBn(m4DoRefuseDeal(math.Random(seed)).rating)), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 3);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M4DoRefuseLines.askSpot)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final (name, ok) in <(String, bool Function(M4DoRefuseDeal))>[
      ('spark, him at the tray', (d) => d.outcome == M4DoRefuseOutcome.settles),
      ('re-blow, him at the tray', (d) => d.outcome == M4DoRefuseOutcome.reblows && d.call == M4DoRefuseCall.link),
      ('re-blow, him at the re-blow', (d) => d.call == M4DoRefuseCall.reblow),
    ]) {
      testWidgets('flow: three rounds right ($name) → pass', (t) async {
        final seed = seedWhere(ok);
        final d = m4DoRefuseDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _roundFind(t, d);
        await _roundLink(t, d);
        await _roundClose(t, d);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.4/do/2'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.4/do/2'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M4DoRefuseLines.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('refit at once: the slip card, then the round goes on', (t) async {
      final seed = seedWhere((d) => d.call == M4DoRefuseCall.reblow);
      final d = m4DoRefuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _tapUnit(t, d.phase);
      await _pump(t, 600);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickWrong(t, M4DoRefuseLines.decideWrong);
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DoRefuseMistakes.refitAtOnce.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(c.read(guideDirectorProvider).line, M4DoRefuseLines.askOpenOthers);
      await _close(t, c);
    });

    testWidgets('a sound fuse called dropped: the slip card, booked; the spot stays', (t) async {
      final seed = seedWhere((d) => d.call == M4DoRefuseCall.reblow);
      final d = m4DoRefuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _tapUnit(t, (d.phase + 1) % 3);
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DoRefuseMistakes.wrongFuse.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(c.read(guideDirectorProvider).line, M4DoRefuseLines.askSpot);
      await _tapUnit(t, d.phase);
      await _pump(t, 600);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the decide deck');
      await _close(t, c);
    });

    testWidgets('three wrong flags: the StruckOutCard', (t) async {
      final seed = seedWhere((d) => d.call == M4DoRefuseCall.reblow);
      final d = m4DoRefuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _tapUnit(t, (d.phase + 1 + i % 2) % 3);
        await _pump(t, 800);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 800);
        }
      }
      await _pump(t, 600);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['4.4/do/2'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('he comes even on a fast play: a quick tray tap waits for him', (t) async {
      final seed = seedWhere((d) => d.call == M4DoRefuseCall.link);
      final d = m4DoRefuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _tapUnit(t, d.phase);
      await _pump(t, 600);
      await _pickRight(t, M4DoRefuseLines.decideRight);
      await _pump(t, 1200);
      for (var i = 0; i < 3; i++) {
        if (i == d.phase) continue;
        await _tapUnit(t, i);
        await _pump(t, 500);
      }
      await _pump(t, 400);
      await _tapUnit(t, d.phase);
      // Extra taps once the round is done change nothing.
      for (var i = 0; i < 3; i++) {
        await _tapUnit(t, i);
        await t.pump(const Duration(milliseconds: 60));
      }
      expect(find.byType(MistakeCard), findsNothing);
      await _pickRight(t, M4DoRefuseLines.whyRight(0, d));
      // Round খ: the docket's link tapped the moment the tray is up.
      for (var ms = 0; ms < 3000 && _label(d.rating).evaluate().isEmpty; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not yet: he is due 1.2 s on');
      await t.tap(_label(d.rating), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the pick waits for him: he cuts in now');
      expect(_label(M4DoRefuseLines.cloth), findsNothing, reason: 'no link taken yet');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M4DoRefuseLines.coworkerLink.right);
      await _pump(t, 2000);
      await t.tap(_label(d.rating), warnIfMissed: false);
      await _pump(t, 500);
      await _steps(t);
      await _pump(t, 400);
      await _reason(t, 1, d);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hint: after idle, a sweep over all three fuses (never one)', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 3);
      await _pump(t, 9000);
      final st = t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(st.showing, isTrue);
      expect(st.debugOptions, hasLength(3));
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = seedWhere((d) => d.call == M4DoRefuseCall.reblow);
      final d = m4DoRefuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _roundFind(t, d);
      final wrong = d.tray.firstWhere((x) => x != null && x != d.rating)!;
      await t.tap(_label(wrong), warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await t.tap(_label(M4DoRefuseLines.ready), warnIfMissed: false);
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await t.tap(_label(M4DoRefuseLines.bottomContact), warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), contains(M4DoRefuseMistakes.noClean.key));
      await _close(t, c);
    });

    testWidgets('thick wire from the tray: the yard freezes first, then the card (near-miss)', (t) async {
      final seed = seedWhere((d) => d.call == M4DoRefuseCall.reblow);
      final d = m4DoRefuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _roundFind(t, d);
      await t.tap(_label(M4DoRefuseLines.thickWire), warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4DoRefuseMistakes.thickWire.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him at the tray = the thick wire: freeze, then the deadly card', (t) async {
      final seed = seedWhere((d) => d.call == M4DoRefuseCall.link);
      final d = m4DoRefuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _roundFind(t, d);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickWrong(t, M4DoRefuseLines.coworkerLink.wrong);
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.last.key, M4DoRefuseMistakes.thickWire.key);
      await _close(t, c);
    });

    testWidgets('listening to him at the re-blow = reclosing on the fault: a slip, then the reason', (t) async {
      final seed = seedWhere((d) => d.call == M4DoRefuseCall.reblow);
      final d = m4DoRefuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _roundFind(t, d);
      await _roundLink(t, d);
      await _push(t, d);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickWrong(t, M4DoRefuseLines.coworkerReblow.wrong);
      await _pump(t, 1500);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.last.key, M4DoRefuseMistakes.reclose.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      await _close(t, c);
    });

    testWidgets('standing under the fuse: the slip card, then he steps aside and goes on', (t) async {
      final seed = seedWhere((d) => d.call == M4DoRefuseCall.reblow);
      final d = m4DoRefuseDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _roundFind(t, d);
      await _roundLink(t, d);
      await t.tapAt(_screen(Offset(M4DoRefuseGeo.phaseX[d.phase], _geo.groundY + 20)));
      await _pump(t, 900);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DoRefuseMistakes.underFuse.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(c.read(guideDirectorProvider).line, M4DoRefuseLines.askSeat);
      await _close(t, c);
    });
  });
}
