// Lesson 3.1 (কন্ডাক্টর পরিচিতি: ACSR, AAAC), কাজ 2 "জোড় ঠিক তো?": a joint
// as a run (the magnet before the sleeve, the sleeve by type and code, the
// brush, both ends fully in, the pump until the valve clicks), the tray of
// finished joints to judge, the deal, the reason libraries, and the level in
// the shell: idle perf, the guide first, a full clean play with the coworker
// refused, a bad joint that glows before its card and starts the job again,
// listening to him, the coworker on a fast and on a slow play (only once both
// ends are fully in), the tray judged once (a good joint thrown out is a
// slip, no free probing), the praise window, gesture hints, 3 slips.
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_conductor_joint.dart';
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
  rungId: '3.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '3.1',
  lessonTitleBn: '',
  ladderStep: 60,
  doIndex: 2,
  doCount: 2,
);

final _pack = m3ConductorJointPacks['do_3_1_b']!;

typedef _T = M3ConductorJointType;
typedef _C = M3ConductorJointCode;
typedef _K = M3ConductorJointKind;
typedef _S = M3ConductorJointStep;
typedef _M = M3ConductorJointMistakes;
typedef _L = M3ConductorJointLines;

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
Finder _key(String k) => find.byKey(ValueKey(k));
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

Future<void> _step(WidgetTester t, M3ConductorJointStep s, {int ms = 500}) async {
  await t.tap(_key('step-${s.name}'));
  await _pump(t, ms);
}

Future<void> _hold(WidgetTester t, String mode, int ms) async {
  final pad = _key('hud-hold-$mode');
  expect(pad, findsOneWidget, reason: mode);
  final g = await t.startGesture(t.getCenter(pad));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M3ConductorJointPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

/// The joint up to the compressor on the sleeve (magnet, sleeve, brush,
/// insert, press → pump), refusing (or not) the coworker on his round.
Future<void> _prepare(WidgetTester t, M3ConductorJointDeal deal, int i, {bool refuse = true}) async {
  final job = deal.rounds[i].job!;
  await _step(t, _S.magnet, ms: 1400);
  await _step(t, _S.sleeve);
  await t.tap(_key('sleeve-${job.right}'));
  await _pump(t, 400);
  await _step(t, _S.brush, ms: 1400);
  await _step(t, _S.insert);
  await _hold(t, 'insert', 1500);
  await _step(t, _S.press);
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on round $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    if (!refuse) return;
    await _pickRight(t, _L.coworker.right);
    await _pump(t, 2600);
  }
}

Future<void> _playRight(WidgetTester t, M3ConductorJointDeal deal, int i) async {
  final r = deal.rounds[i];
  if (r.inspect) {
    for (final (k, s) in r.samples.indexed) {
      if (s.kind != _K.good) {
        await t.tap(_key('joint-$k'));
        await _pump(t, 300);
      }
    }
    await t.tap(find.text(_L.trayDone));
    await _pump(t, 2600);
  } else {
    await _prepare(t, deal, i);
    await _hold(t, 'press', 2000);
    await _pump(t, 2000);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(r));
  await _pump(t, 5000);
}

M3ConductorJointJob _job({_T type = _T.acsr, _C code = _C.dog}) => M3ConductorJointJob(
      type: type,
      code: code,
      sleeves: [M3ConductorJointSleeve(type, code), M3ConductorJointSleeve(type.other, code), M3ConductorJointSleeve(type, code == _C.dog ? _C.rabbit : _C.dog)],
    );
M3ConductorJointRun _make([M3ConductorJointJob? j]) =>
    M3ConductorJointRun(M3ConductorJointDeal(rounds: [M3ConductorJointRound.make(j ?? _job())], callAt: 0));

/// Everything right up to the press, with sleeve [s] (default the right one).
M3ConductorJointRun _ready({M3ConductorJointJob? j, M3ConductorJointSleeve? s}) {
  final job = j ?? _job();
  final r = _make(job);
  expect(r.magnet(), job.type == _T.acsr);
  expect(r.openKit(), isNull);
  r
    ..pickSleeve(s ?? job.right)
    ..brush();
  expect(r.startInsert(), isNull);
  r.setInserted(1);
  expect(r.startPress(), isNull);
  return r;
}

void main() {
  group('rules', () {
    test('deals: one ACSR and one AAAC joint (codes differ), one tray (2nd or 3rd); the kit holds the right sleeve and two near misses; he comes on a joint', () {
      final seen = <String>{};
      final at = <int>{};
      final kinds = <_K>{};
      for (var s = 0; s < 80; s++) {
        final d = m3ConductorJointDeal(math.Random(s));
        expect(d.rounds, hasLength(3));
        final trays = [
          for (final (i, r) in d.rounds.indexed)
            if (r.inspect) i,
        ];
        expect(trays, hasLength(1));
        expect(trays.single, inInclusiveRange(1, 2));
        at.add(trays.single);
        expect(d.rounds[d.callAt].inspect, isFalse);
        final jobs = [for (final r in d.rounds) ?r.job];
        expect(jobs.map((j) => j.type).toSet(), _T.values.toSet());
        expect(jobs.map((j) => j.code).toSet(), hasLength(2));
        for (final j in jobs) {
          expect(j.sleeves, hasLength(3));
          expect(j.sleeves.toSet(), hasLength(3));
          expect(j.sleeves, contains(j.right));
          expect(j.sleeves, contains(M3ConductorJointSleeve(j.type.other, j.code)), reason: 'the other type of the same code');
          expect(j.sleeves.where((x) => x.type == j.type && x.code != j.code), hasLength(1));
        }
        final tray = d.rounds[trays.single].samples;
        expect(tray, hasLength(4));
        final good = tray.where((x) => x.kind == _K.good).length;
        expect(good, inInclusiveRange(1, 2));
        expect(tray.where((x) => x.kind != _K.good).map((x) => x.kind).toSet(), hasLength(4 - good), reason: 'bad ones of different kinds');
        kinds.addAll(tray.map((x) => x.kind));
        seen.add('${jobs.map((j) => '${j.type.name}${j.code.name}${j.sleeves}').join()}$tray${d.callAt}');
      }
      expect(seen.length, greaterThan(70), reason: 'every play is dealt fresh');
      expect(at, {1, 2});
      expect(kinds, containsAll(_K.values));
    });

    test('the magnet sticks to ACSR only; the sleeve before the magnet is a guess (a slip, the job goes on)', () {
      final a = _make();
      expect(a.openKit(), _M.guess);
      expect(a.slips, 1);
      expect(a.shown, isFalse);
      a.pickSleeve(_job().right);
      expect(a.sleeve, isNull, reason: 'no sleeve without the test');
      expect(a.magnet(), isTrue);
      expect(a.magnet(), isNull, reason: 'once');
      expect(a.openKit(), isNull);
      expect(_make(_job(type: _T.aaac)).magnet(), isFalse);
    });

    test('order: the sleeve and the brush before the ends go in; fully in before the press', () {
      final r = _make()..magnet();
      expect(r.startInsert(), _M.noSleeve);
      expect(r.startPress(), _M.noSleeve);
      r.pickSleeve(_job().right);
      expect(r.startInsert(), _M.noClean);
      expect(r.shown, isFalse, reason: 'order slips do not end the job');
      expect(r.brush(), isTrue);
      expect(r.brush(), isFalse);
      expect(r.startInsert(), isNull);
      r.setInserted(0.6);
      expect(r.fullyIn, isFalse);
      expect(r.startPress(), _M.notIn);
      expect(r.shown, isTrue, reason: 'a bad joint: the job starts again');
      r.redo();
      expect(r.sleeve, isNull);
      expect(r.inserted, 0);
      expect(r.brushed, isFalse);
      expect(r.magnetDone, isTrue, reason: 'the magnet result stays known');
      expect(r.slips, 4);
    });

    test('the press: the valve must click; the sleeve must match the type, then the code', () {
      expect(_ready().press(0.7), _M.halfPress);
      expect(_ready(s: M3ConductorJointSleeve(_T.aaac, _C.dog)).press(1), _M.wrongType);
      expect(_ready(s: M3ConductorJointSleeve(_T.aaac, _C.rabbit)).press(1), _M.wrongType, reason: 'type first');
      expect(_ready(s: M3ConductorJointSleeve(_T.acsr, _C.rabbit)).press(1), _M.wrongCode);
      final aaac = _job(type: _T.aaac, code: _C.panther);
      expect(_ready(j: aaac, s: M3ConductorJointSleeve(_T.acsr, _C.panther)).press(1), _M.wrongType);
      final ok = _ready();
      expect(ok.press(1), isNull);
      expect(ok.pressed, isTrue);
      expect(ok.shown, isTrue);
      expect(ok.slips, 0);
      expect(ok.thorough, isTrue);
      expect(ok.caught, containsAll([_L.caughtMagnet, _L.caughtSleeve, _L.caughtPress]));
      for (final m in [_M.halfPress, _M.wrongType, _M.wrongCode, _M.notIn, _M.loose]) {
        expect(_M.ruins, contains(m));
      }
      for (final m in [_M.guess, _M.noSleeve, _M.noClean]) {
        expect(_M.ruins, isNot(contains(m)));
      }
    });

    test('a slip on the round costs the +5; letting off loose (the coworker) is a bad joint', () {
      final r = _make()..openKit();
      expect(r.thorough, isFalse);
      final l = _ready();
      expect(l.loose(), _M.loose);
      expect(l.shown, isTrue);
      final orders = {for (var s = 0; s < 20; s++) m3ConductorJointTray(math.Random(s)).join()};
      expect(orders.length, greaterThan(10), reason: 'the tray is shuffled');
      expect(m3ConductorJointTray(math.Random(1)).toSet(), _S.values.toSet());
    });

    test('the tray is judged once: every bad joint rejected passes; a bad one let through or a good one thrown out is one slip (no free probes)', () {
      M3ConductorJointRun tray(List<_K> k) =>
          M3ConductorJointRun(M3ConductorJointDeal(rounds: [M3ConductorJointRound.inspect([for (final x in k) M3ConductorJointSample(x, _T.acsr, _C.dog)])], callAt: 0));
      const kinds = [_K.good, _K.wrongSleeve, _K.cutStrand, _K.good];
      final a = tray(kinds)
        ..toggle(1)
        ..toggle(2);
      expect(a.falseRejects, isEmpty);
      expect(a.passTray(), isNull);
      expect(a.caught, containsAll([_L.caughtKind(_K.wrongSleeve), _L.caughtKind(_K.cutStrand)]));
      expect(a.thorough, isTrue);
      // A good one thrown out with every bad one caught: a slip, the round ends.
      final b = tray(kinds)
        ..toggle(1)
        ..toggle(2)
        ..toggle(0);
      expect(b.falseRejects, [0]);
      expect(b.passTray(), _M.rejectedGood);
      expect(b.slips, 1);
      expect(b.shown, isTrue, reason: 'judged once: no second try with a hint');
      expect(b.thorough, isFalse);
      expect(b.passTray(), isNull, reason: 'once');
      expect(b.slips, 1);
      // Marking everything (the probe) costs the same slip.
      final all = tray(kinds);
      for (var i = 0; i < 4; i++) {
        all.toggle(i);
      }
      expect(all.passTray(), _M.rejectedGood);
      expect(all.slips, 1);
      // A bad one let through outranks a good one thrown out; still one slip.
      final m = tray(kinds)
        ..toggle(1)
        ..toggle(3);
      expect(m.passTray(), _M.passCutStrand);
      expect(m.slips, 1);
      final c = tray(const [_K.halfPress, _K.wrongSleeve, _K.good, _K.cutStrand]);
      expect(c.passTray(), _M.passHalfPress);
      expect(c.slips, 1, reason: 'one slip however many');
      expect(_M.passed(_K.wrongSleeve), _M.passWrongSleeve);
    });

    test('mark: 100 − 15 × slips; pass ≥ 55', () {
      final r = _make();
      for (var i = 0; i < 3; i++) {
        r.openKit();
      }
      expect(r.percent, 55);
      r.openKit();
      expect(r.percent, 40);
    });

    test('English digits; every mistake has its picture and a unique 3.1 key; no deadly; prints', () {
      final all = [
        ..._L.guideLines,
        ..._L.acsrWhy,
        ..._L.aaacWhy,
        ..._L.makeWhy,
        ..._L.trayWhy,
        ..._L.myths,
        ..._L.acsrMyths,
        ..._L.aaacMyths,
        ..._L.trayMyths,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.toLowerCase().contains('galvanic') || l.contains('গ্যালভানিক'), isFalse, reason: 'the film fix: not galvanic');
      }
      expect(_L.sleevePrint(const M3ConductorJointSleeve(_T.aaac, _C.panther)), 'AAAC PANTHER');
      for (final m in _M.all) {
        expect(m.deadly, isFalse, reason: m.key);
        expect(m.key, startsWith('3.1/m3_conductor_joint/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3), reason: m.key);
      }
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final k in _K.values.where((k) => k != _K.good)) {
        expect(_M.all, contains(_M.passed(k)));
      }
      expect(m3ConductorJointPacks.keys, ['do_3_1_b']);
      expect(_pack.quickMs, 60000);
    });

    test('reasons: same length, big enough, the right ones fit the conductor; the coworker deck; his snarl is recorded', () {
      expectSameLength('why', [..._L.acsrWhy, ..._L.aaacWhy, ..._L.makeWhy, ..._L.trayWhy, ..._L.myths, ..._L.acsrMyths, ..._L.aaacMyths, ..._L.trayMyths]);
      const fullTray = M3ConductorJointRound.inspect([
        M3ConductorJointSample(_K.good, _T.acsr, _C.dog),
        M3ConductorJointSample(_K.wrongSleeve, _T.acsr, _C.dog),
        M3ConductorJointSample(_K.cutStrand, _T.aaac, _C.rabbit),
        M3ConductorJointSample(_K.halfPress, _T.acsr, _C.dog),
      ]);
      for (final r in [
        M3ConductorJointRound.make(_job()),
        M3ConductorJointRound.make(_job(type: _T.aaac)),
        fullTray,
      ]) {
        final right = _L.whyRight(r);
        expectLibrary('why', right, [..._L.whyWrongOwn(r), ..._L.myths]);
        for (var s = 0; s < 10; s++) {
          final deal = _L.dealWhy(r, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          expect(deal.where((o) => !o.correct && _L.whyWrongOwn(r).contains(o.textBn)), hasLength(1), reason: 'one wrong card in the round\'s own words');
        }
      }
      // No giveaway word: the job's type name is on a wrong card every time.
      for (final t in _T.values) {
        final r = M3ConductorJointRound.make(_job(type: t));
        for (var s = 0; s < 20; s++) {
          final wrong = _L.dealWhy(r, math.Random(s)).where((o) => !o.correct);
          expect(wrong.any((o) => o.textBn.contains(_L.typeEn(t))), isTrue, reason: t.name);
        }
      }
      // No giveaway word: every key word on the right card is also on a wrong
      // card in every deal (its mirror), for every right card of every round.
      const keys = ['স্ট্র্যান্ড', 'কোড', 'চুম্বক', 'ট্যাগ', 'হটস্পট', 'বাতিল', 'ACSR', 'AAAC'];
      for (final r in [M3ConductorJointRound.make(_job()), M3ConductorJointRound.make(_job(type: _T.aaac)), fullTray]) {
        final seen = <String>{};
        for (var s = 0; s < 200; s++) {
          final deal = _L.dealWhy(r, math.Random(s));
          final right = deal.singleWhere((o) => o.correct).textBn;
          seen.add(right);
          final wrong = deal.where((o) => !o.correct).map((o) => o.textBn).toList();
          for (final k in keys.where(right.contains)) {
            expect(wrong.any((w) => w.contains(k)), isTrue, reason: '"$k" only on the right card: $right');
          }
        }
        expect(seen, _L.whyRight(r).toSet(), reason: 'every right card is dealt');
      }
      // The tray's right cards only name flaws that are on the tray.
      Set<String> trayRight(List<_K> kinds) =>
          _L.whyRight(M3ConductorJointRound.inspect([for (final k in kinds) M3ConductorJointSample(k, _T.acsr, _C.dog)])).toSet();
      expect(trayRight([_K.good, _K.good, _K.halfPress, _K.cutStrand]), {_L.trayWhy[0], _L.trayWhy[1]});
      expect(trayRight([_K.good, _K.good, _K.wrongSleeve, _K.halfPress]), {_L.trayWhy[1], _L.trayWhy[2]});
      expect(trayRight([_K.good, _K.wrongSleeve, _K.cutStrand, _K.halfPress]), _L.trayWhy.toSet());
      expect(_L.whyRight(M3ConductorJointRound.make(_job())), isNot(contains(_L.aaacWhy.first)));
      expect(_L.whyRight(M3ConductorJointRound.make(_job(type: _T.aaac))), isNot(contains(_L.acsrWhy.first)));
      final cw = _L.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      // His push is recorded in his own voice.
      expect(LearnVoice.resolve(cw.line, rival: true), isNotNull);
      // No giveaway: the refusals do not share an opening word ("না, …").
      expect(cw.right.map((r) => r.split(' ').first).toSet(), hasLength(cw.right.length));
      for (final r in cw.right) {
        expect(r.startsWith('না'), isFalse, reason: r);
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3ConductorJointPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m3_conductor_joint ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; tapping him restates the task differently', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: M3ConductorJointPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_key('step-magnet'), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_key('step-magnet'), findsOneWidget);
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(_L.askMake)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: every round right, the coworker refused → pass, saved', (t) async {
      final deal = m3ConductorJointDeal(math.Random(5));
      final c = await _open(t, 5);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.1/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.1/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong-type sleeve: the joint glows first, then the card; then the job starts again', (t) async {
      var seed = 0;
      while (m3ConductorJointDeal(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final deal = m3ConductorJointDeal(math.Random(seed));
      final job = deal.rounds[0].job!;
      final c = await _open(t, seed);
      await _step(t, _S.magnet, ms: 1400);
      await _step(t, _S.sleeve);
      await t.tap(_key('sleeve-${M3ConductorJointSleeve(job.type.other, job.code)}'));
      await _pump(t, 400);
      await _step(t, _S.brush, ms: 1400);
      await _step(t, _S.insert);
      await _hold(t, 'insert', 1500);
      await _step(t, _S.press);
      await _hold(t, 'press', 2000);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the glow comes first');
      await _pump(t, 2600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.wrongType.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsNothing);
      // The same job again: a new sleeve from the kit (the magnet result kept).
      await _step(t, _S.sleeve);
      expect(_key('sleeve-${job.right}'), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the sleeve before the magnet: its card, the job goes on', (t) async {
      final c = await _open(t, 2);
      await _step(t, _S.sleeve);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.guess.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_key('step-magnet'), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('listening to him: let off loose, the glow, the card', (t) async {
      var seed = 0;
      while (m3ConductorJointDeal(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final deal = m3ConductorJointDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _prepare(t, deal, 0, refuse: false);
      await waitChoiceDeck(t);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 3200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.loose.key);
      await _close(t, c);
    });

    int trayAfterHisRound() {
      var seed = 0;
      while (!m3ConductorJointDeal(math.Random(seed)).rounds[1].inspect || m3ConductorJointDeal(math.Random(seed)).callAt != 0) {
        seed++;
      }
      return seed;
    }

    int hisRoundFirst() {
      var seed = 0;
      while (m3ConductorJointDeal(math.Random(seed)).callAt != 0) {
        seed++;
      }
      return seed;
    }

    testWidgets('the tray is judged once: marking every joint (a probe) is a slip with its card, no hint before it; then the next round', (t) async {
      final seed = trayAfterHisRound();
      final deal = m3ConductorJointDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _playRight(t, deal, 0);
      final samples = deal.rounds[1].samples;
      for (var i = 0; i < samples.length; i++) {
        await t.tap(_key('joint-$i'));
        await _pump(t, 200);
      }
      await t.tap(find.text(_L.trayDone));
      await t.pump();
      expect(find.byType(MistakeCard), findsOneWidget, reason: 'a good joint thrown out costs a slip at once');
      await _pump(t, 600);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.rejectedGood.key);
      expect(find.text(_L.trayDone), findsNothing, reason: 'no second try on the same tray');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(_key('step-magnet'), findsOneWidget, reason: 'the next round');
      await _close(t, c);
    });

    testWidgets('the tray: a bad joint let through is a slip (the glow first)', (t) async {
      final seed = trayAfterHisRound();
      final deal = m3ConductorJointDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _playRight(t, deal, 0);
      await t.tap(find.text(_L.trayDone));
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the glow comes first');
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      final samples = deal.rounds[1].samples;
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.passed(samples.firstWhere((s) => s.kind != _K.good).kind).key);
      await _close(t, c);
    });

    testWidgets('the praise window: taps on the tray after a right judgment do nothing', (t) async {
      final seed = trayAfterHisRound();
      final deal = m3ConductorJointDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _playRight(t, deal, 0);
      final samples = deal.rounds[1].samples;
      for (final (k, s) in samples.indexed) {
        if (s.kind != _K.good) {
          await t.tap(_key('joint-$k'));
          await _pump(t, 200);
        }
      }
      final done = t.getCenter(find.text(_L.trayDone));
      await t.tap(find.text(_L.trayDone));
      await _pump(t, 100);
      for (var i = 0; i < samples.length; i++) {
        await t.tap(_key('joint-$i'), warnIfMissed: false);
      }
      await t.tapAt(done);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 700);
      await _pickRight(t, _L.whyRight(deal.rounds[1]));
      await _pump(t, 3000);
      expect(_key('step-magnet'), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('he comes even on a fast play: the press waits for him; refused, the pump opens', (t) async {
      final seed = hisRoundFirst();
      final job = m3ConductorJointDeal(math.Random(seed)).rounds[0].job!;
      final c = await _open(t, seed);
      await _step(t, _S.magnet, ms: 1200);
      await _step(t, _S.sleeve, ms: 100);
      await t.tap(_key('sleeve-${job.right}'));
      await _pump(t, 100);
      await _step(t, _S.brush, ms: 1200);
      await _step(t, _S.insert, ms: 100);
      final g = await t.startGesture(t.getCenter(_key('hud-hold-insert')));
      await _pump(t, 1400);
      await g.up();
      await t.pump();
      // Straight to the press, well inside his 1.2 s delay.
      await t.tap(_key('step-press'));
      await t.pump();
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the fast press calls him in now');
      expect(_key('hud-hold-press'), findsNothing, reason: 'no pumping past him');
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
      expect(_key('hud-hold-press'), findsOneWidget);
      await _hold(t, 'press', 2000);
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the right joint: its reason');
      await _close(t, c);
    });

    testWidgets('his push fits the moment: not before both ends are fully in; then he comes on a slow play too', (t) async {
      final seed = hisRoundFirst();
      final job = m3ConductorJointDeal(math.Random(seed)).rounds[0].job!;
      final c = await _open(t, seed);
      await _pump(t, 5000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'nothing to let off yet');
      await _step(t, _S.magnet, ms: 1400);
      await _step(t, _S.sleeve);
      await t.tap(_key('sleeve-${job.right}'));
      await _pump(t, 400);
      await _step(t, _S.brush, ms: 1400);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'the ends are not in yet');
      await _step(t, _S.insert);
      await _hold(t, 'insert', 1500);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue, reason: 'he comes on his own');
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _step(t, _S.press);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'once per play');
      await _hold(t, 'press', 2000);
      await _pump(t, 1500);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hint: a sweep over every step, over the kit, a hold on the pad; none during the intro', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      var seed = 0;
      while (m3ConductorJointDeal(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final job = m3ConductorJointDeal(math.Random(seed)).rounds[0].job!;
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: M3ConductorJointPage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      IdleHintState hint() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 300);
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(hint().showing, isFalse);
      await _pump(t, 9000);
      expect(hint().showing, isTrue, reason: 'idle on the steps');
      expect(hint().debugOptions, hasLength(5), reason: 'a sweep over every step, none singled out');
      await _step(t, _S.magnet, ms: 1400);
      await _step(t, _S.sleeve);
      expect(hint().showing, isFalse, reason: 'a touch hides it');
      await _pump(t, 9000);
      expect(hint().showing, isTrue);
      expect(hint().debugOptions, hasLength(3), reason: 'a sweep over the whole kit');
      await t.tap(_key('sleeve-${job.right}'));
      await _pump(t, 400);
      await _step(t, _S.brush, ms: 1400);
      await _step(t, _S.insert);
      await _pump(t, 9000);
      expect(hint().showing, isTrue);
      expect(hint().debugFrame?.ring, isNotNull, reason: 'hold the pad');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 30));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });

    testWidgets('three slips fail the level', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _step(t, _S.sleeve);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });
  });
}
