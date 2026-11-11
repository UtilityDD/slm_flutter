// Lesson 4.3 (নতুন সার্ভিস কানেকশন), কাজ 2 "সংযোগ দাও": the rules (strap
// first, drip loop, L/N by the marks at the meter and on the LT line, the
// pole only with harness + shutdown + proven dead + earth, IPC tightened
// till the head shears, earth off before the line or the fuse, multimeter
// read right, offcuts cleared; a tool or the earth on the live LT line =
// deadly), the deal, the reason libraries, and the level in the shell: idle
// perf, the guide first, a full clean play with the coworker refused, a slip
// card that keeps the house, the deadly freeze, three slips.
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
import 'package:slm_flutter/features/game/m4_service_connect.dart';
import 'package:slm_flutter/features/game/m4_service_connect_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '4.3/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '4.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m4ServiceConnectPacks['do_4_3_b']!;
typedef _L = M4ServiceConnectLines;
typedef _M = M4ServiceConnectMistakes;
typedef _T = M4ServiceConnectTool;

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
M4ServiceConnectGeo get _geo => M4ServiceConnectGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M4ServiceConnectPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _row(M4ServiceConnectSite s, {required bool neutral}) => s.ltOrder.indexWhere((x) => (x == 3) == neutral);
int _term(M4ServiceConnectSite s, {required bool l}) => (l == s.meterLeftIsL) ? 0 : 1;

/// The span strapped, the drip loop, the two cores into the meter (refusing him on his house).
Future<void> _houseEnd(WidgetTester t, M4ServiceConnectDeal deal, int i) async {
  final s = deal.sites[i];
  await _tool(t, _L.strap);
  await _tapAt(t, _geo.spanHit.center);
  await _tapAt(t, _geo.entryHit.center);
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on house $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, _L.coworker.right);
    await _pump(t, 2600);
  }
  await _tapAt(t, _geo.houseCores[0]);
  await _tapAt(t, _geo.terminals[_term(s, l: true)]);
  await _tapAt(t, _geo.houseCores[1]);
  await _tapAt(t, _geo.terminals[_term(s, l: false)]);
}

/// Up the pole safely; both IPCs on and sheared; back down; supply on, read, clean.
Future<void> _poleEnd(WidgetTester t, M4ServiceConnectSite s) async {
  await _tool(t, _L.harness);
  await _tool(t, _L.shutdown);
  await _tool(t, _L.tester);
  expect(find.text(_L.testerDead), findsOneWidget);
  await _tool(t, _L.earth);
  await _tool(t, _L.ipc);
  final ph = _row(s, neutral: false);
  final n = _row(s, neutral: true);
  await _tapAt(t, _geo.poleCores[0]);
  await _tapAt(t, _geo.conductorHit(ph).center);
  await _tapAt(t, _geo.ipcHit(0, ph).center);
  await _tapAt(t, _geo.poleCores[1]);
  await _tapAt(t, _geo.conductorHit(n).center);
  await _tapAt(t, _geo.ipcHit(1, n).center);
  await _tool(t, _L.earth);
  await _tool(t, _L.shutdown);
  await _tool(t, _L.fuse);
  await _tool(t, _L.multimeter);
  expect(find.text('${s.volts} V'), findsOneWidget);
  await t.tap(find.text(_L.sayOk));
  await _pump(t, 600);
  for (final x in s.scraps) {
    await _tapAt(t, _geo.scrapHit(x).center);
  }
}

Future<void> _playRight(WidgetTester t, M4ServiceConnectDeal deal, int i) async {
  final s = deal.sites[i];
  await _houseEnd(t, deal, i);
  await _poleEnd(t, s);
  await _tool(t, _L.handover);
  await _pump(t, 1500);
  final cards = find.byType(MistakeCard).evaluate().map((e) => (e.widget as MistakeCard).mistake.key).toList();
  expect(cards, isEmpty, reason: 'house $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(s));
  await _pump(t, 6000);
}

void main() {
  group('rules', () {
    test('deals: three houses, three different reasons, both meter layouts, N marked once; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m4ServiceConnectDeal(math.Random(s));
        expect(d.sites, hasLength(3));
        expect(d.sites.map((x) => x.why).toSet(), hasLength(3));
        expect(d.sites.map((x) => x.meterLeftIsL).toSet(), hasLength(2));
        expect(d.callAt, inInclusiveRange(0, 2));
        for (final x in d.sites) {
          expect([...x.ltOrder]..sort(), [0, 1, 2, 3]);
          expect(x.volts, inInclusiveRange(230, 240));
          expect(x.scraps, hasLength(2));
        }
        seen.add(d.sites.map((x) => '${x.ltOrder.join()}${x.meterLeftIsL}${x.why.name}${x.scraps.join(',')}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(70));
    });

    M4ServiceConnectSite site({bool leftL = true, List<int> lt = const [3, 0, 1, 2]}) =>
        M4ServiceConnectSite(id: 'x', ltOrder: lt, meterLeftIsL: leftL, volts: 234, scraps: const [236, 292], why: M4ServiceConnectWhy.ipc);
    M4ServiceConnectRun run1({bool leftL = true}) => M4ServiceConnectRun(M4ServiceConnectDeal(sites: [site(leftL: leftL)], callAt: 0));

    /// The meter end done right.
    void houseEnd(M4ServiceConnectRun r) {
      r.hold(_T.strap);
      expect(r.tapSpan(), isTrue);
      expect(r.tapEntry(), isNull);
      for (final c in [0, 1]) {
        expect(r.tapHouseCore(c), isNull);
        expect(r.tapTerminal(r.terminalIsL(0) == (c == 0) ? 0 : 1), isNull);
      }
      expect(r.meterDone, isTrue);
    }

    /// Up, shutdown, proven dead, earthed; both IPCs on and sheared.
    void poleEnd(M4ServiceConnectRun r) {
      expect(r.toggleHarness(), isNull);
      expect(r.toggleShutdown(), isNull);
      expect(r.test(), (null, false));
      expect(r.toggleEarth(), isNull);
      r.hold(_T.ipc);
      expect(r.tapPoleCore(0), isNull);
      expect(r.tapConductor(1), isNull);
      expect(r.tighten(0), isTrue);
      expect(r.tapPoleCore(1), isNull);
      expect(r.tapConductor(0), isNull);
      expect(r.tighten(1), isTrue);
      expect(r.poleDone, isTrue);
    }

    test('the house end: strap first, then the drip loop, then L to L and N to N', () {
      final r = run1(leftL: false);
      expect(r.tapEntry(), _M.strapFirst);
      expect(r.tapHouseCore(0), _M.strapFirst);
      r.hold(_T.strap);
      expect(r.tapSpan(), isTrue);
      expect(r.tapHouseCore(0), _M.noDrip);
      expect(r.tapEntry(), isNull);
      expect(r.drip, isTrue);
      expect(r.tapHouseCore(0), isNull);
      expect(r.tapTerminal(0), _M.pnSwap, reason: 'left is N on this meter');
      expect(r.houseIn, isEmpty);
      r.tapHouseCore(0);
      expect(r.tapTerminal(1), isNull);
      r.tapHouseCore(1);
      expect(r.tapTerminal(0), isNull);
      expect(r.meterDone, isTrue);
      expect(r.scrapsShown, hasLength(2), reason: 'the offcuts once trimmed');
      expect(r.slips, 4);
      expect(r.caught, containsAll([_L.caughtStrap, _L.caughtDrip, _L.caughtPn]));
    });

    test('a tool or the earth on the LT line without the shutdown is deadly', () {
      for (final t in [_T.ipc, _T.pliers]) {
        final r = run1();
        houseEnd(r);
        r
          ..toggleHarness()
          ..hold(t);
        final m = r.tapConductor(0);
        expect(m, _M.liveLine);
        expect(m!.deadly, isTrue);
        expect(r.ended, isTrue);
      }
      final e = run1()..toggleHarness();
      expect(e.toggleEarth(), _M.liveLine);
      expect(e.ended, isTrue);
    });

    test('the pole: harness, then shutdown, proven dead, earth; meter end first; IPC not pliers; N to N', () {
      final r = run1();
      r.hold(_T.ipc);
      expect(r.tapConductor(1), _M.noHarness);
      expect(r.test().$1, _M.noHarness);
      r.toggleHarness();
      expect(r.test(), (null, true), reason: 'the line is live');
      r.toggleShutdown();
      expect(r.tapConductor(1), _M.noProve);
      expect(r.toggleEarth(), _M.noProve);
      expect(r.test(), (null, false));
      expect(r.tapConductor(1), _M.noEarth);
      expect(r.toggleEarth(), isNull);
      expect(r.tapConductor(1), _M.poleFirst);
      r.toggleHarness();
      houseEnd(r);
      r.toggleHarness();
      r.hold(_T.pliers);
      expect(r.tapConductor(1), _M.twistJoint);
      r.hold(_T.ipc);
      r.tapPoleCore(1);
      expect(r.tapConductor(1), _M.pnSwap, reason: 'row 1 is R');
      r.tapPoleCore(0);
      expect(r.tapConductor(0), _M.pnSwap, reason: 'row 0 is N');
      expect(r.ipcs, isEmpty);
      expect(r.slips, 9);
    });

    test('the IPC must shear before coming down, giving the line back or the fuse; the earth off first', () {
      final r = run1();
      houseEnd(r);
      r
        ..toggleHarness()
        ..toggleShutdown()
        ..test()
        ..toggleEarth()
        ..hold(_T.ipc)
        ..tapPoleCore(0);
      expect(r.tapConductor(2), isNull);
      expect(r.loose, isTrue);
      expect(r.toggleHarness(), _M.looseIpc);
      expect(r.harness, isTrue);
      expect(r.toggleShutdown(), _M.earthOn);
      expect(r.toggleFuse(), _M.earthOn);
      r.toggleEarth();
      expect(r.toggleShutdown(), _M.looseIpc);
      expect(r.toggleFuse(), _M.looseIpc);
      expect(r.measure(), _M.looseIpc);
      expect(r.shutdown, isTrue);
      expect(r.tighten(0), isTrue);
      expect(r.loose, isFalse);
      expect(r.slips, 6);
    });

    test('the supply: multimeter reads 0 V until the line and the fuse are on; a misread is a slip; hand over measured and clean', () {
      final r = run1();
      houseEnd(r);
      poleEnd(r);
      expect(r.caught, containsAll([_L.caughtDead, _L.caughtIpc]));
      expect(r.handOver(), _M.noTest);
      expect(r.toggleEarth(), isNull);
      expect(r.measure(), isNull);
      expect(r.reading, 0, reason: 'shutdown still on');
      expect(r.answer(true), _M.misread);
      expect(r.answer(false), isNull);
      expect(r.measured, isFalse);
      expect(r.toggleShutdown(), isNull);
      expect(r.toggleFuse(), _M.noHarness, reason: 'the fuse is on the pole');
      r.toggleHarness();
      expect(r.toggleFuse(), isNull);
      expect(r.measure(), isNull);
      expect(r.harness, isFalse, reason: 'he comes down to the meter');
      expect(r.reading, 234);
      expect(r.answer(false), _M.misread);
      expect(r.answer(true), isNull);
      expect(r.measured, isTrue);
      expect(r.handOver(), _M.mess);
      for (final x in [...r.scrapsShown]) {
        expect(r.pickScrap(x), isTrue);
      }
      expect(r.handOver(), isNull);
      expect(r.handedOver, isTrue);
      expect(r.caught, containsAll([_L.caughtTest, _L.caughtClean]));
      expect(r.slips, 5);
    });

    test('English digits only; every mistake has its picture and a unique key; one deadly', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        ..._L.allRight,
        ..._L.myths,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
        ..._L.coworker.asks,
        for (final m in _M.all) m.textBn,
        _L.allSet,
        _L.fail,
        _L.callHeld,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), [_M.liveLine]);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('4.3/m4_service_connect/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      expect(m4ServiceConnectPacks.keys, ['do_4_3_b']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      for (final w in M4ServiceConnectWhy.values) {
        final s = M4ServiceConnectSite(id: 'x', ltOrder: const [0, 1, 2, 3], meterLeftIsL: true, volts: 230, scraps: const [236, 262], why: w);
        final right = _L.whyRight(s);
        expectLibrary('$w', right, _L.myths);
        expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, _L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = _L.coworker;
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4ServiceConnectPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_service_connect ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4ServiceConnectPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.ipc), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(_L.ipc), findsOneWidget);
      expect(_label(_L.handover), findsOneWidget);
      expect(find.text(_L.docketJob), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askWork)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: strap, drip, L/N, pole safely, IPC sheared, supply read, clean; refuse him; right reasons → pass', (t) async {
      final deal = m4ServiceConnectDeal(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.3/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['4.3/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtIpc), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (the drip loop before strapping) shows its card; the same house goes on after it', (t) async {
      final c = await _open(t, 2);
      await _tapAt(t, _geo.entryHit.center);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.strapFirst.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(_L.strap), findsOneWidget, reason: 'the same house');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.strapFirst.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.entryHit.center);
        await _pump(t, 600);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('an IPC on the live LT line: the scene freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, 2);
      await _tool(t, _L.harness);
      await _tool(t, _L.ipc);
      await _tapAt(t, _geo.conductorHit(1).center);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.liveLine.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him: phase and neutral swapped — a slip card, the house goes on', (t) async {
      final deal = m4ServiceConnectDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _tool(t, _L.strap);
      await _tapAt(t, _geo.spanHit.center);
      await _tapAt(t, _geo.entryHit.center);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(_M.pnSwap.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.pnSwap.key);
      await _close(t, c);
    });
  });
}
