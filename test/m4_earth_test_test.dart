// Lesson 4.6 (সঠিক আর্থিং পরীক্ষা ও রক্ষণাবেক্ষণ), কাজ 1 "মাটির পরীক্ষা": the
// rules (the visual check, two spikes before the leads, the leads before
// TEST, the reading marked against the lesson's value, the coworker's two
// pushes), the deal, the reason libraries, and the level in the shell: idle
// perf, the guide first, the guide's tap, a full clean play to a pass (with
// the coworker refused), slip cards, the 3-slip strike-out, the coworker on a
// fast play (TEST and the mark wait for him), the over-call, no ring on the
// spike place, and the gesture hint (a sweep over every option).
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
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
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_earth_test.dart';
import 'package:slm_flutter/features/game/m4_earth_test_world.dart' show M4EarthTestView, M4EarthTestWorldPainter;
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '4.6/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '4.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m4EarthTestPacks['do_4_6_a']!;

/// The art folder is listed in pubspec.yaml; this falls back to the repo copy
/// only so a freshly added svg draws before the next `pub get` bundles it.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

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

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M4EarthTestGeo get _geo => M4EarthTestGeo.forScene(360 * 850 / 392, 0);
Offset _screen(Offset design) => design * _k;

Widget _app(Widget home, {GlobalKey<NavigatorState>? nav}) =>
    DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(navigatorKey: nav, home: home));

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(const Scaffold(body: SizedBox()), nav: nav)));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M4EarthTestPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1500);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: right.first);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 4500);
}

Future<void> _refuse(WidgetTester t, CoworkerScript s) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, s.right);
  await _pump(t, 2600);
}

Future<void> _look(WidgetTester t, M4EarthTestDeal d) async {
  for (final i in d.faults.keys) {
    await t.tapAt(_screen(_geo.earthRect(i).center));
    await _pump(t, 300);
  }
  await t.tap(find.text(M4EarthTestLines.lookDone));
  await _pump(t, 300);
  expect(find.byType(MistakeCard), findsNothing);
  await _reason(t, M4EarthTestLines.lookRight);
}

Future<void> _rig(WidgetTester t) async {
  for (var k = 0; k < 2; k++) {
    await t.tapAt(_screen(_geo.spikeRect(k).center));
    await _pump(t, 300);
  }
  await t.tap(_label(M4EarthTestLines.leads));
  await _pump(t, 300);
  await t.tap(_label(M4EarthTestLines.test));
  await _pump(t, 2200);
}

int _seedWhere(bool Function(M4EarthTestDeal d) ok) {
  for (var s = 1;; s++) {
    if (ok(m4EarthTestDeal(math.Random(s)))) return s;
  }
}

int _seedFor({required bool runs}) => _seedWhere((d) => d.runsPush == runs);

/// Taps a scene point.
Future<void> _tapEarth(WidgetTester t, int i) async {
  await t.tapAt(_screen(_geo.earthRect(i).center));
  await _pump(t, 300);
}

/// What the yard painter shows right now (tags, spikes, leads, marks).
M4EarthTestView _yard(WidgetTester t) {
  final p = t.widget<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is M4EarthTestWorldPainter));
  return (p.painter! as M4EarthTestWorldPainter).view;
}

/// Pumps until the station's rig controls are live (the leads chip shows).
Future<void> _waitRig(WidgetTester t) async {
  expect(await _pumpUntil(t, _label(M4EarthTestLines.leads)), isTrue, reason: 'the rig is up');
}

void main() {
  group('rules', () {
    test('deals: 1–2 faults, one neutral and one body pit, one good and one high reading; fresh every play', () {
      final seen = <String>{};
      final pushOnHigh = <bool>{};
      for (var s = 0; s < 80; s++) {
        final d = m4EarthTestDeal(math.Random(s));
        expect(d.faults.length, inInclusiveRange(1, 2));
        expect(d.faults.values.toSet().length, d.faults.length);
        expect(d.pits.where((p) => p < 2).length, 1);
        expect(d.pits.where((p) => p >= 2).length, 1);
        expect(d.ohms.where(m4EarthTestIsHigh).length, 1);
        for (final o in d.ohms) {
          expect(o < 5 || o > 8, isTrue, reason: 'never inside the lesson range');
        }
        expect(m4EarthTestIsHigh(d.ohms[d.highAt]), isTrue);
        expect(d.pushAt, inInclusiveRange(0, 1));
        if (d.runsPush) pushOnHigh.add(d.pushAt == d.highAt);
        seen.add('${d.faults}${d.pits}${d.ohms}${d.runsPush}');
      }
      expect(seen.length, greaterThan(30));
      expect(pushOnHigh, {true, false}, reason: 'the "line runs" push comes on a good reading too (his arrival never tells)');
    });

    const deal = M4EarthTestDeal(faults: {1: M4EarthTestFault.rust, 3: M4EarthTestFault.cut}, pits: [2, 0], ohms: [18, 2.5], runsPush: true);

    test('look: any point takes a tag (a tap again takes it off) and nothing tells; a missed fault or a tagged sound point is a slip', () {
      final r = M4EarthTestRun(deal);
      expect(r.tapEarth(0), isTrue, reason: 'a sound point takes a tag too — the tap gives nothing away');
      expect(r.slips, 0);
      expect(r.tapEarth(1), isTrue);
      expect(r.spotted, {0, 1});
      expect(r.lookDone(), M4EarthTestMistakes.missedCut);
      expect(r.slips, 1);
      expect(r.tapEarth(3), isTrue);
      expect(r.lookDone(), M4EarthTestMistakes.flaggedSound, reason: 'an over-call costs a slip');
      expect(r.slips, 2);
      expect(r.tapEarth(0), isFalse, reason: 'tapped again: the tag comes off');
      expect(r.spotted, {1, 3});
      expect(r.lookDone(), isNull);
      expect(r.caught, contains(M4EarthTestLines.caughtLook));
      for (final f in M4EarthTestFault.values) {
        expect(M4EarthTestMistakes.all, contains(M4EarthTestMistakes.missed(f)));
      }
    });

    test('test: the leads before two spikes, TEST before the leads are slips; then it reads', () {
      final r = M4EarthTestRun(deal)..next();
      expect(r.station, M4EarthTestStation.pitA);
      expect(r.testPit, 2);
      expect(r.pressTest(), M4EarthTestMistakes.testEarly);
      expect(r.driveSpike(), isTrue);
      expect(r.connectLeads(), M4EarthTestMistakes.leadsFirst);
      expect(r.driveSpike(), isTrue);
      expect(r.driveSpike(), isFalse, reason: 'two spikes');
      final any = M4EarthTestRun(deal)..next();
      expect(any.driveSpike(1), isTrue, reason: 'either place first');
      expect(any.driveSpike(1), isFalse);
      expect(any.driveSpike(), isTrue);
      expect(any.spikeAt, {0, 1});
      expect(r.connectLeads(), isNull);
      expect(r.pressTest(), isNull);
      expect(r.slips, 2);
      expect(r.caught, contains(M4EarthTestLines.caughtRig));
    });

    test('read: a high reading marked OK and a good one marked high are slips; the right mark records it', () {
      final r = M4EarthTestRun(deal)..next();
      r
        ..driveSpike()
        ..driveSpike()
        ..connectLeads()
        ..pressTest();
      expect(r.readingHigh, isTrue);
      expect(r.mark(high: false), M4EarthTestMistakes.passedHigh);
      expect(r.mark(high: true), isNull);
      expect(r.marks[2]!.high, isTrue);
      expect(r.caught, contains(M4EarthTestLines.caughtHigh));
      r.next();
      expect(r.testPit, 0);
      expect(r.spikes, 0, reason: 'the spikes go in again for the next pit');
      r
        ..driveSpike()
        ..driveSpike()
        ..connectLeads()
        ..pressTest();
      expect(r.mark(high: true), M4EarthTestMistakes.flaggedGood);
      expect(r.mark(high: false), isNull);
      expect(r.caught, contains(M4EarthTestLines.caughtOk));
      r.next();
      expect(r.finished, isTrue);
      expect(r.percent, 70);
      expect(r.passed, isTrue);
    });

    test('listening to him: the myth (line runs) or eyes only', () {
      expect(M4EarthTestRun(deal).listen(), M4EarthTestMistakes.lineRuns);
      const eyes = M4EarthTestDeal(faults: {0: M4EarthTestFault.cover}, pits: [0, 2], ohms: [2.5, 18], runsPush: false);
      expect(M4EarthTestRun(eyes).listen(), M4EarthTestMistakes.eyesOnly);
    });

    test('English digits only; every mistake has its picture, its key and its lesson point; none deadly', () {
      final all = <String>[
        M4EarthTestLines.intro,
        ...M4EarthTestLines.tasks,
        for (var p = 0; p < 4; p++) M4EarthTestLines.askRig(p),
        ...M4EarthTestLines.lookRight,
        ...M4EarthTestLines.okRight,
        ...M4EarthTestLines.highRight,
        ...M4EarthTestLines.excuses,
        for (final s in [M4EarthTestLines.coworkerSkip, M4EarthTestLines.coworkerRuns]) ...[...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        for (final m in M4EarthTestMistakes.all) m.textBn,
        M4EarthTestLines.allSet,
        M4EarthTestLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      final keys = <String>{};
      for (final m in M4EarthTestMistakes.all) {
        expect(m.deadly, isFalse);
        expect(m.key, startsWith('4.6/m4_earth_test/'));
        expect(keys.add(m.key), isTrue, reason: m.key);
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m != M4EarthTestMistakes.lineRuns) expect(m.lessonPoint, inInclusiveRange(1, 2), reason: m.key);
      }
      expect(M4EarthTestMistakes.lineRuns.lessonPoint, isNull, reason: 'myth buster');
      expect(m4EarthTestPacks.keys, ['do_4_6_a']);
    });

    test('reasons: same length, big enough, one right per deal; his exit line is recorded', () {
      final rights = [M4EarthTestLines.lookRight, M4EarthTestLines.okRight, M4EarthTestLines.highRight];
      expectSameLength('why', [for (final r in rights) ...r, ...M4EarthTestLines.excuses]);
      for (final r in rights) {
        expectLibrary(r.first, r, M4EarthTestLines.excuses);
        for (var i = 0; i < 10; i++) {
          final d = dealChoices(r, M4EarthTestLines.excuses, math.Random(i));
          expect(d.where((o) => o.correct).length, 1);
          expect(d.map((o) => o.textBn).toSet().length, 3);
        }
      }
      // The audit: "high Ω → the breaker won't trip" is beyond the lesson's
      // point 3 (it gives the value, not that consequence) — no right card
      // or refusal claims it.
      for (final l in [
        for (final r in rights) ...r,
        ...M4EarthTestLines.coworkerSkip.right,
        ...M4EarthTestLines.coworkerRuns.right,
      ]) {
        expect(l.contains('ট্রিপ'), isFalse, reason: l);
        expect(l.contains('ফল্টের সময়'), isFalse, reason: l);
      }
      for (final cw in [M4EarthTestLines.coworkerSkip, M4EarthTestLines.coworkerRuns]) {
        expectSameLength('choice', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong);
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      }
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: _app(M4EarthTestPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_earth_test ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the look and the docket', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: _app(M4EarthTestPage(ctx: _ctx, pack: _pack, muted: true, seed: 1))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M4EarthTestLines.lookDone), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M4EarthTestLines.lookDone), findsOneWidget);
      expect(find.text(M4EarthTestLines.job), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 2);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M4EarthTestLines.askLook)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final seed in [
      _seedWhere((d) => d.runsPush && d.pushAt == d.highAt),
      _seedWhere((d) => d.runsPush && d.pushAt != d.highAt),
      _seedFor(runs: false),
    ]) {
      testWidgets('flow (seed $seed): look, test two pits, refuse him, mark right → pass', (t) async {
        final deal = m4EarthTestDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _look(t, deal);
        for (var k = 0; k < 2; k++) {
          if (k == 0 && !deal.runsPush) await _refuse(t, M4EarthTestLines.coworkerSkip);
          await _rig(t);
          expect(find.byType(MistakeCard), findsNothing);
          final high = m4EarthTestIsHigh(deal.ohms[k]);
          expect(find.text('${m4EarthTestOhms(deal.ohms[k])} Ω'), findsOneWidget);
          if (deal.runsPush && k == deal.pushAt) await _refuse(t, M4EarthTestLines.coworkerRuns);
          expect(await _pumpUntil(t, find.text(M4EarthTestLines.markHigh)), isTrue);
          await t.tap(find.text(high ? M4EarthTestLines.markHigh : M4EarthTestLines.markOk));
          await _pump(t, 300);
          await _reason(t, high ? M4EarthTestLines.highRight : M4EarthTestLines.okRight);
        }
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.6/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.6/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M4EarthTestLines.caughtCall), findsOneWidget);
        expect(find.text(M4EarthTestLines.caughtHigh), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a missed fault and TEST before the circuit: slip cards, booked', (t) async {
      const seed = 5;
      final deal = m4EarthTestDeal(math.Random(seed));
      final c = await _open(t, seed);
      await t.tap(find.text(M4EarthTestLines.lookDone));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4EarthTestMistakes.missed(deal.faults.values.first).key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await _look(t, deal);
      if (!deal.runsPush) await _refuse(t, M4EarthTestLines.coworkerSkip);
      await t.tap(_label(M4EarthTestLines.test));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), contains(M4EarthTestMistakes.testEarly.key));
      await _close(t, c);
    });

    testWidgets('three slips: the StruckOutCard, the level not cleared', (t) async {
      final c = await _open(t, 5);
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text(M4EarthTestLines.lookDone));
        await _pump(t, 600);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget, reason: 'slip ${i + 1}');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['4.6/do/0'], isNot('cleared'));
      expect(find.byType(LevelPassPanel), findsNothing);
      await _close(t, c);
    });

    testWidgets('a tag on a sound point costs a slip with a neutral card; off again, the look passes; no input in the praise window', (t) async {
      const seed = 5;
      final deal = m4EarthTestDeal(math.Random(seed));
      final sound = [for (var i = 0; i < 4; i++) if (!deal.faults.containsKey(i)) i].first;
      final c = await _open(t, seed);
      await _tapEarth(t, sound);
      expect(find.byType(MistakeCard), findsNothing, reason: 'a tag tells nothing when it is hung');
      for (final i in deal.faults.keys) {
        await _tapEarth(t, i);
      }
      await t.tap(find.text(M4EarthTestLines.lookDone));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4EarthTestMistakes.flaggedSound.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapEarth(t, sound);
      await t.tap(find.text(M4EarthTestLines.lookDone));
      await t.pump();
      expect(find.byType(MistakeCard), findsNothing);
      // The praise window: the controls are gone and a tap does nothing. The
      // station is still the look here (it moves on after the reason), so
      // without the tableBusy guard this tap would hang a tag on the point.
      expect(find.text(M4EarthTestLines.lookDone), findsNothing);
      final before = {..._yard(t).spotted};
      expect(before, deal.faults.keys.toSet());
      await t.tapAt(_screen(_geo.earthRect(sound).center));
      await t.pump(const Duration(milliseconds: 100));
      expect(_yard(t).spotted, before, reason: 'no tag hung in the praise window');
      await t.tapAt(_screen(_geo.earthRect(deal.faults.keys.first).center));
      await t.pump(const Duration(milliseconds: 100));
      expect(_yard(t).spotted, before, reason: 'no tag taken off in the praise window');
      // FullSceneFrame shields the scene by itself in this window, so a real
      // tap never reaches the level; call the scene's own tap handler past the
      // shield to prove the level's guard (`!tableBusy` in _canPlay) too.
      final touch = t.widget<GestureDetector>(find.descendant(of: find.byKey(const ValueKey('touch')), matching: find.byType(GestureDetector)));
      final at = _geo.earthRect(sound).center;
      touch.onTapUp!(TapUpDetails(kind: PointerDeviceKind.touch, localPosition: at, globalPosition: _screen(at)));
      await t.pump(const Duration(milliseconds: 100));
      expect(_yard(t).spotted, before, reason: "the level's own guard: no tag in the praise window");
      await _reason(t, M4EarthTestLines.lookRight);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      await _close(t, c);
    });

    testWidgets('"no tester needed": a fast rig, TEST waits for him; no ring marks the spike place; either place first', (t) async {
      final seed = _seedFor(runs: false);
      final deal = m4EarthTestDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (final i in deal.faults.keys) {
        await _tapEarth(t, i);
      }
      await t.tap(find.text(M4EarthTestLines.lookDone));
      await _pump(t, 300);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, M4EarthTestLines.lookRight);
      await _waitRig(t);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not come yet');
      expect(find.byKey(const ValueKey('spike-0')), findsNothing, reason: 'no ring on the spike place');
      expect(
        find.byWidgetPredicate((w) => w is Positioned && w.key is ValueKey && RegExp('spike|ring|next').hasMatch('${(w.key! as ValueKey).value}')),
        findsNothing,
        reason: 'no layer marks a spike place under any key',
      );
      expect(_yard(t).spikeAt, isEmpty);
      await t.tapAt(_screen(_geo.spikeRect(1).center));
      await t.pump(const Duration(milliseconds: 16));
      await t.tapAt(_screen(_geo.spikeRect(0).center));
      await t.pump(const Duration(milliseconds: 16));
      await t.tap(_label(M4EarthTestLines.leads));
      await t.pump(const Duration(milliseconds: 16));
      expect(find.byType(MistakeCard), findsNothing, reason: 'both spikes in, either order');
      await t.tap(_label(M4EarthTestLines.test));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'TEST waited for him');
      await _pump(t, 2000);
      expect(find.text('${m4EarthTestOhms(deal.ohms[0])} Ω'), findsNothing, reason: 'no reading before him');
      await _refuse(t, M4EarthTestLines.coworkerSkip);
      await t.tap(_label(M4EarthTestLines.test));
      await _pump(t, 2200);
      expect(find.text('${m4EarthTestOhms(deal.ohms[0])} Ω'), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('"line runs": a fast mark waits for him (he comes on whichever pit is dealt)', (t) async {
      final seed = _seedWhere((d) => d.runsPush && d.pushAt == 0);
      final deal = m4EarthTestDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _look(t, deal);
      await _waitRig(t);
      await _rig(t);
      expect(await _pumpUntil(t, find.text(M4EarthTestLines.markHigh), maxMs: 3000), isTrue);
      expect(find.byType(CoworkerPeek), findsNothing);
      final high = m4EarthTestIsHigh(deal.ohms[0]);
      await t.tap(find.text(high ? M4EarthTestLines.markHigh : M4EarthTestLines.markOk));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the mark waited for him');
      await _refuse(t, M4EarthTestLines.coworkerRuns);
      expect(find.byKey(const ValueKey('why-deck')), findsNothing, reason: 'nothing was marked');
      await t.tap(find.text(high ? M4EarthTestLines.markHigh : M4EarthTestLines.markOk));
      await _pump(t, 300);
      await _reason(t, high ? M4EarthTestLines.highRight : M4EarthTestLines.okRight);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('listening to him is a slip (booked), and the play goes on', (t) async {
      final seed = _seedFor(runs: false);
      final deal = m4EarthTestDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _look(t, deal);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final w = _onScreen(M4EarthTestLines.coworkerSkip.wrong);
      expect(w, isNotEmpty);
      await t.tap(w.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4EarthTestMistakes.eyesOnly.key);
      expect(M4EarthTestMistakes.eyesOnly.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _rig(t);
      expect(find.text('${m4EarthTestOhms(deal.ohms[0])} Ω'), findsOneWidget);
      await _close(t, c);
    });

    group('gesture hint', () {
      setUp(() => GestureHints.debugEnableInTests = true);
      tearDown(() => GestureHints.debugEnableInTests = false);

      testWidgets('a sweep over every option of the look and of the rig, never a tap', (t) async {
        final seed = _seedFor(runs: true);
        final deal = m4EarthTestDeal(math.Random(seed));
        final c = await _open(t, seed);
        IdleHintState hint() => t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
        expect(hint().showing, isFalse);
        await _pump(t, 9000);
        expect(hint().showing, isTrue, reason: 'idle at the look');
        expect(hint().debugOptions, hasLength(5), reason: 'the four earth points and দেখা শেষ');
        expect(hint().debugFrame!.ripple, isNull, reason: 'a sweep, not a tap');
        await _tapEarth(t, deal.faults.keys.first);
        expect(hint().showing, isFalse, reason: 'a touch hides it');
        for (final i in deal.faults.keys.skip(1)) {
          await _tapEarth(t, i);
        }
        await t.tap(find.text(M4EarthTestLines.lookDone));
        await _pump(t, 300);
        expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
        await _pump(t, 700);
        await _pickRight(t, M4EarthTestLines.lookRight);
        await _waitRig(t);
        await _pump(t, 9000);
        expect(hint().showing, isTrue, reason: 'idle at the rig');
        expect(hint().debugOptions, hasLength(4), reason: 'two spike places, the leads, TEST');
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        c.dispose();
        t.view.reset();
      });
    });
  });
}
