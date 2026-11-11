// Lesson 3.6 (DTR), কাজ 2 "অফ-লোড ট্যাপ": the rules (measure at the house
// first, read the voltmeter; change the off-load tap only with HT (AB + DO)
// and LT off, locked and tagged, proven dead and earthed; pin out → one
// notch → pin in; earth off before switching on; measure again; a hand on
// the tap of a live DTR or the earthing set on a live line = deadly), the
// deal, the reason libraries, and the level in the shell: idle perf, the
// guide first, a full clean play with the coworker refused, a slip card that
// keeps the site, three slips, the deadly freeze, listening to him.
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_dtr_tap.dart';
import 'package:slm_flutter/features/game/m3_dtr_tap_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '3.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '3.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m3DtrTapPacks['do_3_6_b']!;

/// The new art is not in pubspec yet (the director adds the folder): tests
/// read it from disk when the bundle does not have it.
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
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3DtrTapGeo get _geo => M3DtrTapGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
}

/// The dial card: 220 × 220, centred, 150 from the top.
const _dialSize = Size(220, 220);
const _dialAt = Offset((392 - 220) / 2, 150);
Future<void> _dialPin(WidgetTester t, int pos) async {
  await t.tapAt(_dialAt + M3DtrTapDialPainter.pinHit(_dialSize, pos).center);
  await _pump(t, 300);
}

Future<void> _dialTurn(WidgetTester t) async {
  await t.tapAt(_dialAt + M3DtrTapDialPainter.centreOf(_dialSize));
  await _pump(t, 300);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M3DtrTapPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1200);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// The voltmeter on the house's meter board; then reads it right.
Future<void> _measure(WidgetTester t, {required bool low}) async {
  await _tool(t, M3DtrTapLines.meter);
  await _tapAt(t, _geo.meterBoard.center);
  final say = low ? M3DtrTapLines.sayLow : M3DtrTapLines.sayOk;
  expect(find.text(say), findsOneWidget);
  await t.tap(find.text(say));
  await _pump(t, 600);
}

/// Plays site [i] right (the coworker refused on his site).
Future<void> _playRight(WidgetTester t, M3DtrTapDeal deal, int i) async {
  final s = deal.sites[i];
  final low = s.kind == M3DtrTapKind.low;
  await _measure(t, low: low);
  if (low) {
    if (i == deal.callAt) {
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on site $i');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M3DtrTapLines.coworker.right);
      await _pump(t, 2600);
    }
    await _tapAt(t, _geo.abPivot); // AB open
    await _tapAt(t, _geo.doHit.center); // DO dropped
    await _tapAt(t, _geo.ltBox.center); // LT off
    await _tool(t, M3DtrTapLines.lock);
    await _tool(t, M3DtrTapLines.tester);
    expect(find.text(M3DtrTapLines.testerDead), findsOneWidget);
    await _tool(t, M3DtrTapLines.earth);
    await _tapAt(t, _geo.dial);
    expect(_label(M3DtrTapLines.dialLabel), findsOneWidget);
    await _dialPin(t, s.startPos);
    await _dialTurn(t);
    await _dialPin(t, s.startPos + 1);
    expect(_label(M3DtrTapLines.dialLabel), findsNothing);
    await _tool(t, M3DtrTapLines.earth); // off
    await _tool(t, M3DtrTapLines.lock); // off
    await _tapAt(t, _geo.doHit.center);
    await _tapAt(t, _geo.abPivot);
    await _tapAt(t, _geo.ltBox.center);
    await _measure(t, low: false);
  }
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'site $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, M3DtrTapLines.whyRight(s));
  await _pump(t, 6000);
}

void main() {
  group('rules', () {
    test('deals: three sites, two low and one right; he comes to a low one; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m3DtrTapDeal(math.Random(s));
        expect(d.sites, hasLength(3));
        expect(d.sites.where((x) => x.kind == M3DtrTapKind.low), hasLength(2));
        expect(d.sites[d.callAt].kind, M3DtrTapKind.low);
        expect(d.sites.map((x) => x.why).toSet(), hasLength(3), reason: 'each site asks its own reason');
        for (final x in d.sites) {
          expect(x.why == M3DtrTapWhy.keep, x.kind == M3DtrTapKind.ok);
          expect(x.startPos, inInclusiveRange(2, 4));
          expect(x.lowVolts, lessThan(220));
          expect(x.okVolts, greaterThan(220));
        }
        seen.add(d.sites.map((x) => '${x.kind.name}${x.job.name}${x.why.name}${x.startPos}${x.lowVolts}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(40));
    });

    M3DtrTapRun run1(M3DtrTapKind k) => M3DtrTapRun(M3DtrTapDeal(sites: [
          M3DtrTapSite(id: 'x', kind: k, lowVolts: 200, okVolts: 236, startPos: 3, job: M3DtrTapJob.para, why: k == M3DtrTapKind.ok ? M3DtrTapWhy.keep : M3DtrTapWhy.isolate),
        ], callAt: 0));

    void read(M3DtrTapRun r, bool low) {
      r.holdMeter();
      r.tapHouse();
      expect(r.readingUp, isTrue);
      expect(r.answer(low), isNull);
    }

    /// HT (AB + DO) and LT off, lock-tag, tester, earth.
    void isolate(M3DtrTapRun r) {
      expect(r.toggleAb().$1, isTrue);
      expect(r.toggleDo().$1, isTrue);
      expect(r.toggleLt(), isTrue);
      expect(r.toggleLock(), isTrue);
      expect(r.test(), isFalse);
      expect(r.toggleEarth(), (true, null));
    }

    test('the voltmeter: a misread is a slip; a right reading on a right site ends it', () {
      final r = run1(M3DtrTapKind.ok)
        ..holdMeter()
        ..tapHouse();
      expect(r.volts, 236);
      expect(r.answer(true), M3DtrTapMistakes.misread);
      expect(r.readingUp, isTrue, reason: 'still to read');
      expect(r.answer(false), isNull);
      expect(r.over, isTrue);
      expect(r.caught, containsAll([M3DtrTapLines.caughtRead, M3DtrTapLines.caughtOk]));
      final l = run1(M3DtrTapKind.low);
      read(l, true);
      expect(l.fixing, isTrue);
      expect(l.over, isFalse);
      expect(l.lamp, M3DtrTapLamp.dim);
    });

    test('a hand on the tap changer of a live DTR is deadly (also before any reading)', () {
      for (final k in M3DtrTapKind.values) {
        final r = run1(k);
        final m = r.openDial();
        expect(m, M3DtrTapMistakes.tapLive);
        expect(m!.deadly, isTrue);
        expect(r.ended, isTrue);
      }
      // AB open but DO in, or DO dropped but AB closed: HT is off, but half.
      final a = run1(M3DtrTapKind.low);
      read(a, true);
      a.toggleAb();
      expect(a.openDial(), M3DtrTapMistakes.htHalf);
      expect(a.ended, isFalse);
    });

    test('the earthing set on a live line is deadly; before the dead test it is a slip', () {
      final r = run1(M3DtrTapKind.low);
      final (moved, m) = r.toggleEarth();
      expect(moved, isFalse);
      expect(m, M3DtrTapMistakes.earthLive);
      expect(m!.deadly, isTrue);
      final s = run1(M3DtrTapKind.low)
        ..toggleAb()
        ..toggleDo();
      expect(s.toggleEarth().$2, M3DtrTapMistakes.earthUnproved);
      expect(s.earthed, isFalse);
      expect(s.test(), isFalse);
      expect(s.toggleEarth(), (true, null));
    });

    test('before the tap: a reading, LT off, lock-tag, proven dead, earthed — each a slip', () {
      final r = run1(M3DtrTapKind.low)
        ..toggleAb()
        ..toggleDo();
      expect(r.openDial(), M3DtrTapMistakes.unread);
      r
        ..toggleAb()
        ..toggleDo();
      read(r, true);
      r
        ..toggleAb()
        ..toggleDo();
      expect(r.openDial(), M3DtrTapMistakes.ltOn);
      r.toggleLt();
      expect(r.openDial(), M3DtrTapMistakes.noLock);
      expect(r.toggleLock(), isTrue);
      expect(r.toggleAb().$1, isFalse, reason: 'locked');
      expect(r.openDial(), M3DtrTapMistakes.noProve);
      r.test();
      expect(r.openDial(), M3DtrTapMistakes.noEarth);
      r.toggleEarth();
      expect(r.openDial(), isNull);
      expect(r.dialOpen, isTrue);
      expect(r.slips, 5);
    });

    test('no tap when the meter showed right', () {
      final r = run1(M3DtrTapKind.ok)
        ..holdMeter()
        ..tapHouse();
      expect(r.answer(false), isNull);
      expect(r.over, isTrue, reason: 'a right reading ends the site');
      // The rule itself: the last reading said right, then a hand on the tap.
      final f = run1(M3DtrTapKind.low);
      f.readLow = false;
      f.everRead = true;
      isolate(f);
      expect(f.openDial(), M3DtrTapMistakes.needless);
    });

    test('the dial: pin out, one notch, pin in; turning with the pin in or twice is a slip', () {
      final r = run1(M3DtrTapKind.low);
      read(r, true);
      isolate(r);
      expect(r.openDial(), isNull);
      expect(r.turn(), M3DtrTapMistakes.pinIn);
      expect(r.pos, 3);
      r.pin();
      expect(r.pinOut, isTrue);
      expect(r.turn(), isNull);
      expect(r.pos, 4);
      expect(r.turn(), M3DtrTapMistakes.oneNotch);
      expect(r.pos, 4);
      r.pin();
      expect(r.dialOpen, isFalse);
      expect(r.caught, containsAll([M3DtrTapLines.caughtIsolate, M3DtrTapLines.caughtSafe, M3DtrTapLines.caughtNotch]));
      expect(r.openDial(), isNull, reason: 'done with the dial');
      expect(r.dialOpen, isFalse);
      expect(r.slips, 2);
    });

    test('back on: never with the earth on; then measure again; the house reads right', () {
      final r = run1(M3DtrTapKind.low);
      read(r, true);
      isolate(r);
      r
        ..openDial()
        ..pin()
        ..turn()
        ..pin();
      expect(r.toggleLock(), isTrue, reason: 'unlocked');
      expect(r.toggleAb(), (false, M3DtrTapMistakes.energiseEarthed));
      expect(r.toggleDo().$2, M3DtrTapMistakes.energiseEarthed);
      expect(r.abClosed, isFalse);
      r.toggleEarth();
      expect(r.earthed, isFalse);
      r
        ..toggleDo()
        ..toggleAb();
      expect(r.proved, isFalse, reason: 'live again');
      r.holdMeter();
      r.tapHouse();
      expect(r.blank, isTrue, reason: 'LT still off: 0 V');
      expect(r.readingUp, isFalse);
      r.toggleLt();
      expect(r.lamp, M3DtrTapLamp.bright);
      r.tapHouse();
      expect(r.volts, 236);
      expect(r.answer(false), isNull);
      expect(r.over, isTrue);
      expect(r.caught, contains(M3DtrTapLines.caughtRetest));
      expect(r.slips, 2);
    });

    test('English digits only; every mistake has its picture and key; the deadly ones', () {
      final all = <String>[
        M3DtrTapLines.intro,
        ...M3DtrTapLines.tasks,
        ...M3DtrTapLines.allRight,
        ...M3DtrTapLines.myths,
        ...M3DtrTapLines.coworker.recordedLines,
        ...M3DtrTapLines.coworker.right,
        ...M3DtrTapLines.coworker.wrong,
        ...M3DtrTapLines.coworker.asks,
        for (final m in M3DtrTapMistakes.all) m.textBn,
        M3DtrTapLines.allSet,
        M3DtrTapLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M3DtrTapMistakes.all.where((m) => m.deadly), [M3DtrTapMistakes.tapLive, M3DtrTapMistakes.earthLive]);
      expect(M3DtrTapMistakes.all.map((m) => m.key).toSet(), hasLength(M3DtrTapMistakes.all.length));
      for (final m in M3DtrTapMistakes.all) {
        expect(m.key, startsWith('3.6/m3_dtr_tap/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m3DtrTapPacks.keys, ['do_3_6_b']);
      expect(M3DtrTapLines.intro.length, lessThan(80), reason: 'short intro');
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [...M3DtrTapLines.allRight, ...M3DtrTapLines.myths]);
      for (final w in M3DtrTapWhy.values) {
        final s = M3DtrTapSite(id: 'x', kind: w == M3DtrTapWhy.keep ? M3DtrTapKind.ok : M3DtrTapKind.low, lowVolts: 200, okVolts: 236, startPos: 3, job: M3DtrTapJob.pump, why: w);
        final right = M3DtrTapLines.whyRight(s);
        expectLibrary('$w', right, M3DtrTapLines.myths);
        expect(M3DtrTapLines.myths.toSet().intersection(M3DtrTapLines.allRight.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, M3DtrTapLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = M3DtrTapLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3DtrTapPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m3_dtr_tap ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3DtrTapPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M3DtrTapLines.meter), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M3DtrTapLines.meter), findsOneWidget);
      expect(find.text(M3DtrTapLines.jobBn(m3DtrTapDeal(math.Random(3)).sites[0].job)), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M3DtrTapLines.askMeasure)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: measure, isolate, lock, prove, earth, one notch, restore, measure; refuse him → pass', (t) async {
      final deal = m3DtrTapDeal(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.6/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.6/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3DtrTapLines.caughtCall), findsOneWidget);
      expect(find.text(M3DtrTapLines.caughtRetest), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (the tap without a reading) shows its card; the same site goes on after it', (t) async {
      final c = await _open(t, 2);
      await _tapAt(t, _geo.abPivot);
      await _tapAt(t, _geo.dial);
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M3DtrTapMistakes.unread.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(M3DtrTapLines.meter), findsOneWidget, reason: 'the same transformer');
      expect(c.read(gameSaveProvider).mistakes.single.key, M3DtrTapMistakes.unread.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      await _tapAt(t, _geo.abPivot);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.dial);
        await _pump(t, 300);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a hand on the tap of a live DTR: the scene freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, 2);
      await _tapAt(t, _geo.dial);
      await _pump(t, 200);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3DtrTapMistakes.tapLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze, then the card', (t) async {
      final deal = m3DtrTapDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _measure(t, low: true);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(M3DtrTapLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('opening the AB switch while he talks refuses him', (t) async {
      final deal = m3DtrTapDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _measure(t, low: true);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 300);
      await _tapAt(t, _geo.abPivot);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });
  });
}
