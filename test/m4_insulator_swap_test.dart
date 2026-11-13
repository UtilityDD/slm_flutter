// Lesson 4.1 (পিন বা ডিস্ক ইনসুলেটর বদলানো), কাজ 2 "পোলের ওপর বদল": the rules
// (the faulty one only; pin: unbind, rope support, spanner, a sound spare on
// a sound pin, bind tight; disc: come-along + turnbuckle take the load, then
// pliers, a sound disc, the split pin, then the load back — pliers under
// load = deadly), the deal, the reason libraries, and the level in the
// shell: idle perf, the guide first, a full clean play with the coworker
// refused, a slip card that keeps the pole, three slips, the deadly freeze,
// listening to him = a slip, he comes even on a fast play (the binding waits
// for him), the tool rows are shuffled, the wrong-flag card stays neutral,
// and the gesture hints sweep over the choices.
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
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_insulator_swap.dart';
import 'package:slm_flutter/features/game/m4_insulator_swap_world.dart';
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
  rungId: '4.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '4.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m4InsulatorSwapPacks['do_4_1_b']!;

typedef _L = M4InsulatorSwapLines;
typedef _M = M4InsulatorSwapMistakes;
typedef _T = M4InsulatorSwapTool;

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
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M4InsulatorSwapGeo get _geo => M4InsulatorSwapGeo.forScene(850 / _k, 0);
Future<void> _tapPhase(WidgetTester t, M4InsulatorSwapKind kind, int i) async {
  await t.tapAt(_geo.phaseTap(kind, i) * _k);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M4InsulatorSwapPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// Picks the sound spare off the tray.
Future<void> _spare(WidgetTester t, M4InsulatorSwapPole p) async {
  await _tool(t, p.kind == M4InsulatorSwapKind.pin ? _L.spareIns : _L.spareDisc);
  final j = p.spares.indexOf(null);
  await t.tap(_label('${_L.spare} ${j + 1}'));
  await _pump(t, 300);
}

/// Plays pole [i] up to the binding (pin) / to the end (disc).
Future<void> _work(WidgetTester t, M4InsulatorSwapDeal deal, int i) async {
  final p = deal.poles[i];
  final k = p.kind;
  Future<void> use(String tool) async {
    await _tool(t, tool);
    await _tapPhase(t, k, p.bad);
  }

  if (k == M4InsulatorSwapKind.pin) {
    await use(_L.pliers);
    await use(_L.rope);
    await use(_L.spanner);
    if (p.rusty) await _tapPhase(t, k, p.bad);
    await _spare(t, p);
    await _tapPhase(t, k, p.bad);
  } else {
    await use(_L.comeAlong);
    await use(_L.turnbuckle);
    await use(_L.pliers);
    await _spare(t, p);
    await _tapPhase(t, k, p.bad);
    await use(_L.splitPin);
    await use(_L.turnbuckle);
  }
}

/// Plays pole [i] right (the coworker refused on his pole).
Future<void> _playRight(WidgetTester t, M4InsulatorSwapDeal deal, int i) async {
  final p = deal.poles[i];
  await _work(t, deal, i);
  if (p.kind == M4InsulatorSwapKind.pin) {
    if (i == deal.callAt) {
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on pole $i');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
    }
    await _tool(t, _L.bindWire);
    await _tapPhase(t, p.kind, p.bad);
  }
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pole $i');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'reason deck on pole $i');
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(p.why));
  await _pump(t, 6000);
}

int _seedWhere(bool Function(M4InsulatorSwapDeal d) ok) {
  for (var s = 1; s < 500; s++) {
    if (ok(m4InsulatorSwapDeal(math.Random(s)))) return s;
  }
  throw StateError('no seed');
}

void main() {
  group('rules', () {
    test('deals: three poles, pin and tension both; he comes to a pin pole; reasons differ and fit; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m4InsulatorSwapDeal(math.Random(s));
        expect(d.poles, hasLength(3));
        expect(d.poles.map((p) => p.kind).toSet(), hasLength(2));
        expect(d.poles[d.callAt].kind, M4InsulatorSwapKind.pin);
        expect(d.poles.map((p) => p.why).toSet(), hasLength(3), reason: 'each pole asks its own reason');
        for (final p in d.poles) {
          expect(p.spares.where((x) => x == null), hasLength(1));
          expect(p.spares.toSet(), hasLength(3));
          if (p.kind == M4InsulatorSwapKind.pin) {
            expect([M4InsulatorSwapWhy.support, M4InsulatorSwapWhy.bind, M4InsulatorSwapWhy.check, if (p.rusty) M4InsulatorSwapWhy.rust], contains(p.why));
          } else {
            expect(p.rusty, isFalse);
            expect([M4InsulatorSwapWhy.bypass, M4InsulatorSwapWhy.release, M4InsulatorSwapWhy.check], contains(p.why));
          }
        }
        seen.add('${d.poles.map((p) => '${p.kind.name}${p.bad}${p.damage.name}${p.rusty}${p.why.name}').join('|')}${d.callAt}');
      }
      expect(seen.length, greaterThan(60));
    });

    M4InsulatorSwapRun run1(M4InsulatorSwapKind k, {bool rusty = false, int bad = 1}) => M4InsulatorSwapRun(M4InsulatorSwapDeal(poles: [
          M4InsulatorSwapPole(
            id: 'x',
            kind: k,
            bad: bad,
            damage: M4InsulatorSwapDamage.crack,
            why: M4InsulatorSwapWhy.check,
            spares: const [M4InsulatorSwapDamage.crack, null, M4InsulatorSwapDamage.puncture],
            rusty: rusty,
          ),
        ], callAt: 0));

    DoMistake? use(M4InsulatorSwapRun r, M4InsulatorSwapTool t, [int? i]) {
      if (r.tool != t) r.hold(t);
      return r.tapPhase(i ?? r.pole.bad);
    }

    test('a tool on a sound insulator is a slip until the work has begun on the faulty one', () {
      final r = run1(M4InsulatorSwapKind.pin);
      expect(use(r, _T.pliers, 0), _M.wrongOne);
      expect(r.started, isFalse);
      expect(use(r, _T.pliers), isNull);
      expect(r.bound, isFalse);
      expect(r.caught, contains(_L.caughtFind));
      expect(use(r, _T.rope, 2), isNull, reason: 'the work is on: a stray tap is ignored');
      expect(r.slips, 1);
    });

    test('pin: the spanner needs the binding off and the rope on; the spare is inspected; bind finishes', () {
      final r = run1(M4InsulatorSwapKind.pin);
      expect(use(r, _T.spanner), _M.unbindFirst);
      expect(use(r, _T.pliers), isNull);
      expect(use(r, _T.spanner), _M.noRope);
      expect(r.oldOff, isFalse);
      expect(use(r, _T.rope), isNull);
      expect(use(r, _T.spanner), isNull);
      expect(r.oldOff, isTrue);
      expect(use(r, _T.bindWire), isNull);
      expect(r.newBound, isFalse, reason: 'nothing to bind on a bare pin');
      r.hold(_T.spare);
      expect(r.trayOpen, isTrue);
      expect(r.pickSpare(0), _M.badSpare);
      expect(r.pickSpare(0), isNull, reason: 'set aside');
      expect(r.pickSpare(2), _M.badSpare);
      expect(r.pickSpare(1), isNull);
      expect(r.tool, _T.spare);
      expect(r.tapPhase(1), isNull);
      expect(r.newOn, isTrue);
      expect(use(r, _T.bindWire), isNull);
      expect(r.fixed, isTrue);
      expect(r.roped, isFalse, reason: 'the rope comes off');
      expect(r.slips, 4);
      expect(r.caught, containsAll([_L.caughtSupport, _L.caughtCheck, _L.caughtBind]));
    });

    test('tool rows: shuffled per pole, never laid out in an order of use', () {
      final rows = <String>{};
      for (var s = 0; s < 120; s++) {
        final d = m4InsulatorSwapDeal(math.Random(s));
        for (var i = 0; i < d.poles.length; i++) {
          final row = d.toolsAt(i);
          final k = d.poles[i].kind;
          expect(row.toSet(), m4InsulatorSwapTools(k).toSet());
          expect(row, hasLength(5));
          for (final use in m4InsulatorSwapUseOrders(k)) {
            expect(row, isNot(orderedEquals(use)), reason: 'seed $s pole $i');
          }
          rows.add('${k.name}:${row.map((t) => t.name).join(',')}');
        }
      }
      expect(rows.length, greaterThan(40), reason: 'the rows vary');
    });

    test('tool row past the last pole (while the level finishes) does not throw', () {
      for (var s = 0; s < 10; s++) {
        final d = m4InsulatorSwapDeal(math.Random(s));
        final n = d.poles.length;
        expect(() => d.toolsAt(n), returnsNormally, reason: 'seed $s');
        expect(d.toolsAt(n), orderedEquals(d.toolsAt(n - 1)));
        expect(d.toolsAt(n + 2), orderedEquals(d.toolsAt(n - 1)));
      }
      final plain = M4InsulatorSwapDeal(poles: m4InsulatorSwapDeal(math.Random(1)).poles, callAt: 0);
      expect(() => plain.toolsAt(plain.poles.length), returnsNormally);
    });

    test('the wrong-flag card stays neutral: it never says the tapped one is sound', () {
      expect(_M.wrongOne.textBn.contains('ভালো ইনসুলেটর!'), isFalse);
      expect(_M.wrongOne.textBn.contains('ঠিক আছে'), isFalse);
    });

    test('roping before unbinding is not a slip', () {
      final r = run1(M4InsulatorSwapKind.pin);
      expect(use(r, _T.rope), isNull);
      expect(use(r, _T.pliers), isNull);
      expect(use(r, _T.spanner), isNull);
      expect(r.oldOff, isTrue);
      expect(r.slips, 0);
    });

    test('pin: a rusted pin is changed (spanner again) before the new insulator goes on', () {
      final r = run1(M4InsulatorSwapKind.pin, rusty: true);
      use(r, _T.pliers);
      use(r, _T.rope);
      use(r, _T.spanner);
      expect(r.tool, _T.spanner, reason: 'still in hand for the pin');
      r.hold(_T.spare);
      r.pickSpare(1);
      expect(r.tapPhase(1), _M.rustyPin);
      expect(r.newOn, isFalse);
      expect(use(r, _T.spanner), isNull);
      expect(r.pinNew, isTrue);
      expect(r.caught, contains(_L.caughtRust));
      r.hold(_T.spare);
      expect(r.tapPhase(1), isNull);
      expect(r.newOn, isTrue);
    });

    test('disc: pliers before the load is on the tool is deadly (no rig, or rig not taken up)', () {
      final a = run1(M4InsulatorSwapKind.disc);
      final m = use(a, _T.pliers);
      expect(m, _M.noBypass);
      expect(m!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = run1(M4InsulatorSwapKind.disc);
      use(b, _T.comeAlong);
      expect(b.rigOn, isTrue);
      expect(use(b, _T.pliers), _M.noBypass);
    });

    test('disc: bypass, slack, out, a sound disc, split pin, the load back slowly', () {
      final r = run1(M4InsulatorSwapKind.disc);
      expect(use(r, _T.turnbuckle), isNull);
      expect(r.takenUp, isFalse, reason: 'nothing to turn without the come-along');
      use(r, _T.comeAlong);
      use(r, _T.turnbuckle);
      expect(r.takenUp, isTrue);
      expect(use(r, _T.pliers), isNull);
      expect(r.discOut, isTrue);
      expect(r.caught, contains(_L.caughtBypass));
      expect(use(r, _T.turnbuckle), _M.releaseGap);
      r.hold(_T.spare);
      r.pickSpare(1);
      expect(r.tapPhase(1), isNull);
      expect(r.newDisc, isTrue);
      expect(use(r, _T.turnbuckle), _M.noSplitPin);
      expect(use(r, _T.splitPin), isNull);
      expect(r.pinned, isTrue);
      expect(use(r, _T.turnbuckle), isNull);
      expect(r.released, isTrue);
      expect(r.fixed, isTrue);
      expect(r.slips, 2);
      expect(r.caught, contains(_L.caughtRelease));
    });

    test('listening to him is a slip; next() resets the pole', () {
      final r = M4InsulatorSwapRun(m4InsulatorSwapDeal(math.Random(3)));
      expect(r.listened(), _M.looseBind);
      expect(r.slips, 1);
      r.hold(_T.pliers);
      r.next();
      expect(r.index, 1);
      expect(r.poleSlips, 0);
      expect(r.tool, _T.none);
      expect(r.bound, isTrue);
    });

    test('English digits only; every mistake has its picture; one deadly; keys unique', () {
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
        _L.bindAgain,
        _L.callHeld,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), [_M.noBypass]);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('4.1/m4_insulator_swap/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m4InsulatorSwapPacks.keys, ['do_4_1_b']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
      for (final w in M4InsulatorSwapWhy.values) {
        final right = _L.whyRight(w);
        expectLibrary('$w', right, _L.myths);
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4InsulatorSwapPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_insulator_swap ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4InsulatorSwapPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.pliers), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(_L.pliers), findsOneWidget);
      expect(find.text(_L.jobBn(m4InsulatorSwapDeal(math.Random(3)).poles[0].kind)), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askFind)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: three poles changed in order; refuse him; right reasons → pass', (t) async {
      final deal = m4InsulatorSwapDeal(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.1/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['4.1/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtCheck), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (a tool on a sound insulator) shows its card; the same pole goes on after it', (t) async {
      final deal = m4InsulatorSwapDeal(math.Random(2));
      final p = deal.poles[0];
      final c = await _open(t, 2);
      await _tool(t, m4InsulatorSwapTools(p.kind).first == _T.pliers ? _L.pliers : _L.comeAlong);
      await _tapPhase(t, p.kind, (p.bad + 1) % 3);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.wrongOne.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(_L.jobBn(p.kind)), findsOneWidget, reason: 'the same pole');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.wrongOne.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final deal = m4InsulatorSwapDeal(math.Random(2));
      final p = deal.poles[0];
      final first = m4InsulatorSwapTools(p.kind).first == _T.pliers ? _L.pliers : _L.comeAlong;
      final c = await _open(t, 2);
      await _tool(t, first);
      for (var i = 0; i < 3; i++) {
        // The tool stays in hand after a slip card.
        await _tapPhase(t, p.kind, (p.bad + 1) % 3);
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

    testWidgets('pliers on a loaded strain string: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) => d.poles[0].kind == M4InsulatorSwapKind.disc);
      final p = m4InsulatorSwapDeal(math.Random(seed)).poles[0];
      final c = await _open(t, seed);
      await _tool(t, _L.pliers);
      await _tapPhase(t, p.kind, p.bad);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.noBypass.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = a slip card; then he binds it right and the pole is done', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0);
      final deal = m4InsulatorSwapDeal(math.Random(seed));
      final p = deal.poles[0];
      final c = await _open(t, seed);
      await _work(t, deal, 0);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.looseBind.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tool(t, _L.bindWire);
      await _tapPhase(t, p.kind, p.bad);
      await _pump(t, 1500);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _close(t, c);
    });

    testWidgets('a fast play still meets him: binding at once waits for him, then the deck', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0);
      final deal = m4InsulatorSwapDeal(math.Random(seed));
      final p = deal.poles[0];
      final c = await _open(t, seed);
      await _work(t, deal, 0);
      // Straight on to the binding, well before his 1.2 s timer.
      await t.tap(_label(_L.bindWire));
      await t.pump(const Duration(milliseconds: 50));
      await t.tapAt(_geo.phaseTap(p.kind, p.bad) * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the binding tap brings him in now');
      expect(find.text(_L.stampDone), findsNothing, reason: 'not bound past him');
      await waitChoiceDeck(t);
      expect(_onScreen(_L.coworker.right), hasLength(1));
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
      // The binding wire is still in hand.
      await _tapPhase(t, p.kind, p.bad);
      await _pump(t, 1500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'bound: the reason comes');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hints: a sweep over the tool row, then over the three phases with a tool in hand', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final deal = m4InsulatorSwapDeal(math.Random(5));
      final c = await _open(t, 5);
      IdleHintState frameHint() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(frameHint().showing, isTrue, reason: 'idle with the tools up');
      expect(frameHint().debugOptions, hasLength(deal.toolsAt(0).length));
      final first = deal.toolsAt(0).first;
      final firstLabel = switch (first) {
        _T.pliers => _L.pliers,
        _T.rope => _L.rope,
        _T.spanner => _L.spanner,
        _T.spare => deal.poles[0].kind == M4InsulatorSwapKind.pin ? _L.spareIns : _L.spareDisc,
        _T.bindWire => _L.bindWire,
        _T.comeAlong => _L.comeAlong,
        _T.turnbuckle => _L.turnbuckle,
        _T.splitPin => _L.splitPin,
        _T.none => '',
      };
      await t.tap(_label(firstLabel));
      await _pump(t, 9000);
      expect(frameHint().showing, isTrue);
      expect(frameHint().debugOptions, hasLength(3), reason: 'three phases (or the three spares on the tray)');
      await _close(t, c);
    });

    testWidgets('binding it tight while he talks refuses him', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0);
      final deal = m4InsulatorSwapDeal(math.Random(seed));
      final p = deal.poles[0];
      final c = await _open(t, seed);
      await _work(t, deal, 0);
      await _tool(t, _L.bindWire);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 300);
      await _tapPhase(t, p.kind, p.bad);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'bound: the reason comes');
      await _close(t, c);
    });
  });
}
