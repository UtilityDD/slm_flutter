// Lesson 4.2 (জাম্পার কানেকশন ও টাইট করা), কাজ 1 "জাম্পার বানাও": the rules
// (a jumper as big as the line's conductor or bigger, brush → paste → the
// right connector by the metal → two spanners, a smooth U, no sharp strand),
// the deal, the reason libraries, and the level in the shell: idle perf, the
// guide first, the guide's tap, a full clean play to a pass (with the
// coworker refused, saved once), slip cards (a thin piece, a too-long bend),
// three slips striking the level out, the coworker coming before the brush
// even on a fast play (listening is a slip), the same four connectors on
// every tray, the tool and spanner rows in a dealt order with one look (no
// main-action button), the one-spanner hold slipping, and the gesture hint
// (a sweep over the choices; none under a slip card).
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
import 'package:slm_flutter/features/game/m4_jumper_make.dart';
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
  rungId: '4.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '4.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m4JumperMakePacks['do_4_2_a']!;

typedef _L = M4JumperMakeLines;
typedef _M = M4JumperMakeMistakes;
typedef _S = M4JumperMakeStation;

/// The level's new art folder is not in pubspec.yaml yet (the director adds
/// it): serve unbundled assets from the repo so the mistake cards draw.
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

Widget _app(Widget home, {GlobalKey<NavigatorState>? nav}) =>
    DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(navigatorKey: nav, home: home));

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(const Scaffold(body: SizedBox()), nav: nav)));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M4JumperMakePage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

Future<void> _reason(WidgetTester t, List<String> right, {int settleMs = 4500}) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'deck ${right.first}');
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, settleMs);
}

Future<void> _hold(WidgetTester t, String label, int ms) async {
  final g = await t.startGesture(t.getCenter(_label(label)));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

Future<void> _wire(WidgetTester t, M4JumperMakeDeal d) async {
  final i = d.pieces.indexWhere((p) => p >= 1);
  await t.tap(find.byKey(ValueKey('piece-$i')));
  await _pump(t, 400);
  await t.tap(find.text(_L.take));
  await _pump(t, 300);
  expect(find.byType(MistakeCard), findsNothing);
  await _reason(t, _L.wireWhy);
}

/// The panel a tool button draws (its look at rest).
Decoration? _face(WidgetTester t, String label) =>
    t.widget<Container>(find.descendant(of: _label(label), matching: find.byType(Container)).first).decoration;

/// Left of [b] on screen?
bool _leftOf(WidgetTester t, String a, String b) => t.getCenter(_label(a)).dx < t.getCenter(_label(b)).dx;

Future<void> _joint(WidgetTester t, M4JumperMakeConn right, List<String> why, {int settleMs = 4500, M4JumperMakeDeal? deal}) async {
  if (deal != null) {
    // The tool row: the dealt order, one look (no main-action button).
    expect(_leftOf(t, _L.brush, _L.paste), deal.brushFirst);
    expect(_face(t, _L.brush), _face(t, _L.paste));
  }
  await _hold(t, _L.brush, 1700);
  await t.tap(_label(_L.paste));
  await _pump(t, 300);
  await t.tap(_label(_L.conn(right)));
  await _pump(t, 400);
  expect(find.byType(MistakeCard), findsNothing);
  if (deal != null) {
    expect(_leftOf(t, _L.twoWrench, _L.oneWrench), deal.twoWrenchFirst);
    expect(_face(t, _L.oneWrench), _face(t, _L.twoWrench));
    // Both spanner buttons are the same hold button (held the same way).
    for (final l in [_L.oneWrench, _L.twoWrench]) {
      expect(find.ancestor(of: _label(l), matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_HoldButton')), findsOneWidget, reason: l);
    }
  }
  await _hold(t, _L.twoWrench, 1300);
  expect(find.byType(MistakeCard), findsNothing);
  await _reason(t, why, settleMs: settleMs);
}

void main() {
  group('rules', () {
    test('deals: 4 pieces with at least one big enough, the trays by the metal, three bends; fresh every play', () {
      final seen = <String>{};
      var copper = 0;
      var stray = 0;
      var brushFirst = 0;
      var twoFirst = 0;
      for (var s = 0; s < 120; s++) {
        final d = m4JumperMakeDeal(math.Random(s));
        // The tool rows are shuffled: the layout never reads out the order.
        if (d.brushFirst) brushFirst++;
        if (d.twoWrenchFirst) twoFirst++;
        expect(d.pieces, hasLength(4));
        expect(d.pieces.where((p) => p >= 1), isNotEmpty);
        expect(d.pieces.where((p) => p < 1), isNotEmpty);
        // The same four on every tray: the bi-metallic one never marks the copper joint.
        expect(d.tray1, hasLength(4));
        expect(d.tray2, hasLength(4));
        expect(d.tray1.toSet(), M4JumperMakeConn.values.toSet());
        expect(d.tray2.toSet(), M4JumperMakeConn.values.toSet());
        expect(d.shapes.toSet(), M4JumperMakeShape.values.toSet());
        if (d.copperRight) copper++;
        if (d.stray) stray++;
        seen.add('${d.pieces}${d.copperRight}${d.tray1}${d.tray2}${d.shapes}${d.stray}${d.acsr}');
      }
      expect(seen.length, greaterThan(80));
      expect(copper, inInclusiveRange(25, 75));
      expect(stray, inInclusiveRange(55, 105));
      expect(brushFirst, inInclusiveRange(35, 85));
      expect(twoFirst, inInclusiveRange(35, 85));
    });

    M4JumperMakeDeal deal({bool copper = false, bool stray = true}) => M4JumperMakeDeal(
          pieces: const [0.65, 1.0, 0.5, 1.3],
          acsr: true,
          copperRight: copper,
          tray1: const [M4JumperMakeConn.pgCu, M4JumperMakeConn.twist, M4JumperMakeConn.bimetal, M4JumperMakeConn.pgAl],
          tray2: const [M4JumperMakeConn.bimetal, M4JumperMakeConn.pgAl, M4JumperMakeConn.twist, M4JumperMakeConn.pgCu],
          shapes: M4JumperMakeShape.values,
          stray: stray,
        );

    test('wire: a thinner piece is a slip; the same size or bigger is right', () {
      for (final i in [0, 2]) {
        final r = M4JumperMakeRun(deal());
        expect(r.takePiece(i), _M.thinWire);
        expect(r.wire, isNull);
        expect(r.slips, 1);
      }
      for (final i in [1, 3]) {
        final r = M4JumperMakeRun(deal());
        expect(r.takePiece(i), isNull);
        expect(r.wire, i);
        expect(r.clean, isTrue);
        expect(r.caught, contains(_L.caughtWire));
      }
    });

    test('joint: brush → paste → the aluminium PG clamp → two spanners; out of order or the wrong metal is a slip', () {
      final r = M4JumperMakeRun(deal())..next();
      expect(r.station, _S.joint1);
      expect(r.fit(M4JumperMakeConn.pgAl), _M.noClean);
      expect(r.paste(), _M.noClean);
      r.brushDone();
      expect(r.fit(M4JumperMakeConn.pgAl), _M.noPaste);
      expect(r.paste(), isNull);
      expect(r.fit(M4JumperMakeConn.pgCu), _M.wrongMetal);
      expect(r.fit(M4JumperMakeConn.twist), _M.twist);
      expect(r.fit(M4JumperMakeConn.bimetal), _M.bimetalOnAl, reason: 'both sides aluminium');
      expect(r.conn, isNull);
      expect(r.slips, 6);
      expect(r.tighten(), isFalse, reason: 'nothing on yet');
      expect(r.fit(M4JumperMakeConn.pgAl), isNull);
      expect(r.caught, contains(_L.caughtClean));
      expect(r.oneWrench(), _M.oneWrench);
      expect(r.tighten(), isTrue);
      expect(r.caught, contains(_L.caughtWrench));
      expect(r.oneWrench(), isNull, reason: 'already tight');
      r.next();
      expect(r.station, _S.joint2);
      expect((r.brushed, r.pasted, r.conn, r.tight), (false, false, null, false));
    });

    test('the copper span: only the bi-metallic connector; the twist is still a slip', () {
      M4JumperMakeRun at() {
        final r = M4JumperMakeRun(deal(copper: true))
          ..next()
          ..next();
        return r
          ..brushDone()
          ..paste();
      }

      expect(at().copperJoint, isTrue);
      expect(at().rightConn, M4JumperMakeConn.bimetal);
      expect(at().fit(M4JumperMakeConn.pgAl), _M.noBimetal);
      expect(at().fit(M4JumperMakeConn.pgCu), _M.noBimetal);
      expect(at().fit(M4JumperMakeConn.twist), _M.twist);
      final ok = at();
      expect(ok.fit(M4JumperMakeConn.bimetal), isNull);
      expect(ok.caught, contains(_L.caughtBimetal));
      // On an aluminium right span the plain PG clamp is right.
      final al = M4JumperMakeRun(deal())
        ..next()
        ..next()
        ..brushDone()
        ..paste();
      expect(al.copperJoint, isFalse);
      expect(al.fit(M4JumperMakeConn.bimetal), _M.bimetalOnAl);
      expect(al.fit(M4JumperMakeConn.pgAl), isNull);
      expect(M4JumperMakeRun(deal()).listenNoBrush(), _M.noClean);
    });

    test('shape: straight or too long is a slip; a smooth U, then the strand trimmed, finishes; done with it out is a slip', () {
      final r = M4JumperMakeRun(deal())
        ..next()
        ..next()
        ..next();
      expect(r.station, _S.shape);
      expect(r.finish(), isNull, reason: 'not bent yet');
      expect(r.bend(M4JumperMakeShape.tight), _M.tightShape);
      expect(r.bend(M4JumperMakeShape.long), _M.longShape);
      expect(r.shape, isNull);
      expect(r.bend(M4JumperMakeShape.smooth), isNull);
      expect(r.caught, contains(_L.caughtShape));
      expect(r.finish(), _M.sharpEnd);
      expect(r.done, isFalse);
      r.trim(byHand: false);
      expect(r.caught, isNot(contains(_L.caughtEdge)));
      expect(r.finish(), isNull);
      expect(r.done, isTrue);
      expect(r.percent, 55);
      expect(r.passed, isTrue);
      final clean = M4JumperMakeRun(deal())
        ..next()
        ..next()
        ..next()
        ..bend(M4JumperMakeShape.smooth)
        ..trim();
      expect(clean.caught, contains(_L.caughtEdge));
      expect(clean.finish(), isNull);
      expect(clean.percent, 100);
      expect(M4JumperMakeGeo.sagOf(M4JumperMakeShape.long), greaterThan(M4JumperMakeGeo.sagOf(M4JumperMakeShape.smooth)));
    });

    test('English digits only; every mistake has its picture, a unique key and its lesson point; no deadly', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        for (final s in _S.values) ..._L.whyRight(s),
        ..._L.copperWhy,
        ..._L.excuses,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
        ..._L.coworker.asks,
        for (final m in _M.all) m.textBn,
        for (var i = 0; i < 4; i++) _L.piece(i),
        for (final s in M4JumperMakeShape.values) _L.shape(s),
        _L.allSet,
        _L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), isEmpty);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('4.2/m4_jumper_make/'));
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect([_M.noBimetal, _M.oneWrench, _M.sharpEnd].every((m) => m.lessonPoint == null), isTrue, reason: 'pro tips / film rule');
      // The reasons say what lesson 4.2 says (no "heats up" / "touches nothing" claims).
      expect(_L.jointWhy.first, 'ময়লা থাকলে ভালো কানেক্টরও ব্যর্থ হয়');
      expect(_L.shapeWhy.first, 'জাম্পারকে মসৃণ U বা C আকার দিতে হয়');
      for (final l in [..._L.jointWhy, ..._L.shapeWhy, ..._L.coworker.right]) {
        expect(l.contains('গরম হয়ে') || l.contains('কিছুতে ঠেকে না'), isFalse, reason: l);
      }
      expect(_L.coworker.right, contains('না, ময়লা থাকলে কানেক্টর ব্যর্থ হয়'));
      expect(m4JumperMakePacks.keys, ['do_4_2_a']);
      expect(_pack.quickMs, kM4JumperMakeQuickMs);
    });

    test('reasons: same length, big enough, one right per deal; his exit line is recorded', () {
      final every = [for (final s in _S.values) ..._L.whyRight(s), ..._L.copperWhy, ..._L.excuses];
      expectSameLength('why', every);
      for (final right in [_L.wireWhy, _L.jointWhy, _L.copperWhy, _L.shapeWhy]) {
        expectLibrary(right.first, right, _L.excuses);
        for (var i = 0; i < 10; i++) {
          final d = dealChoices(right, _L.excuses, math.Random(i));
          expect(d.where((o) => o.correct).length, 1);
          expect(d.map((o) => o.textBn).toSet().length, 3);
        }
      }
      expect(_L.whyRight(_S.joint2, copper: true), _L.copperWhy);
      expect(_L.whyRight(_S.joint1, copper: true), _L.jointWhy);
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
        await t.pumpWidget(ProviderScope(child: _app(M4JumperMakePage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_jumper_make ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the rack and the docket', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: _app(M4JumperMakePage(ctx: _ctx, pack: _pack, muted: true, seed: 1))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.byKey(const ValueKey('piece-0')), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.byKey(const ValueKey('piece-0')), findsOneWidget);
      expect(find.text(_L.permit), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askWire)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final seed in [3, 8]) {
      testWidgets('flow (seed $seed): the wire, two clean joints, refuse him, a smooth U, the strand → pass', (t) async {
        final d = m4JumperMakeDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _wire(t, d);
        expect(_label(_L.conn(M4JumperMakeConn.bimetal)), findsOneWidget, reason: 'every tray has the bi-metallic one');
        await _joint(t, M4JumperMakeConn.pgAl, _L.jointWhy, deal: d);
        // The right joint: he comes first.
        expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
        await _pumpUntil(t, find.byType(ChoiceDeck));
        await _pump(t, 600);
        await _pickRight(t, _L.coworker.right);
        await _pump(t, 2600);
        expect(find.byType(MistakeCard), findsNothing);
        expect(_label(_L.conn(M4JumperMakeConn.bimetal)), findsOneWidget);
        expect(_label(_L.conn(M4JumperMakeConn.pgCu)), findsOneWidget);
        await _joint(t, d.copperRight ? M4JumperMakeConn.bimetal : M4JumperMakeConn.pgAl, d.copperRight ? _L.copperWhy : _L.jointWhy, deal: d);
        // The bend and the strand.
        await t.tap(find.byKey(const ValueKey('shape-smooth')));
        await _pump(t, 400);
        if (d.stray) {
          await t.tap(_label(_L.strand));
          await _pump(t, 300);
        }
        await t.tap(find.text(_L.finish));
        await _pump(t, 300);
        expect(find.byType(MistakeCard), findsNothing);
        await _reason(t, _L.shapeWhy);
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.2/do/0'], 'cleared');
        expect(s.playsByRung['4.2/do/0'], 1, reason: 'the result is saved once');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.2/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(_L.caughtCall), findsOneWidget);
        if (d.copperRight) expect(find.text(_L.caughtBimetal), findsOneWidget);
        if (d.stray) expect(find.text(_L.caughtEdge), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a thin piece: the slip card, booked; then a too-long bend swings and slips', (t) async {
      const seed = 5;
      final d = m4JumperMakeDeal(math.Random(seed));
      final c = await _open(t, seed);
      await t.tap(find.byKey(ValueKey('piece-${d.pieces.indexWhere((p) => p < 1)}')));
      await _pump(t, 400);
      expect(find.text(_L.lineWire), findsOneWidget);
      await t.tap(find.text(_L.take));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.thinWire.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await _wire(t, d);
      await _joint(t, M4JumperMakeConn.pgAl, _L.jointWhy);
      await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
      await _joint(t, d.copperRight ? M4JumperMakeConn.bimetal : M4JumperMakeConn.pgAl, d.copperRight ? _L.copperWhy : _L.jointWhy);
      await t.tap(find.byKey(const ValueKey('shape-long')));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsNothing, reason: 'it swings first');
      await _pump(t, 1600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), containsAll([_M.thinWire.key, _M.longShape.key]));
      await _close(t, c);
    });

    testWidgets('three slips (paste before the brush) strike the level out', (t) async {
      const seed = 6;
      final d = m4JumperMakeDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _wire(t, d);
      for (var i = 0; i < 3; i++) {
        await t.tap(_label(_L.paste));
        await _pump(t, 700);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), contains(_M.noClean.key));
      await _close(t, c);
    });

    testWidgets('a fast play: a press on the brush at the right joint brings him first (no brush yet); listening is a slip; he never comes back', (t) async {
      const seed = 8;
      final d = m4JumperMakeDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _wire(t, d);
      // The left joint, then straight on: no waiting for his timer.
      await _joint(t, M4JumperMakeConn.pgAl, _L.jointWhy, settleMs: 0);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('hud-tray-joint2')), maxMs: 3000), isTrue);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'his timer has not run yet');
      final g = await t.startGesture(t.getCenter(_label(_L.brush)));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the brush waits for him');
      await _pump(t, 1500);
      await g.up();
      await waitChoiceDeck(t);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget, reason: 'listening is a slip');
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [_M.noClean.key]);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1200);
      // The joint is still to be brushed (his push did not brush it), and he is gone for good.
      await _joint(t, d.copperRight ? M4JumperMakeConn.bimetal : M4JumperMakeConn.pgAl, d.copperRight ? _L.copperWhy : _L.jointWhy);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      expect(find.byKey(const ValueKey('hud-shapes')), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('one spanner: its hold fills like the other, then slips (booked, still loose); the joint hint sweeps all six tools', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      const seed = 3;
      final d = m4JumperMakeDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _wire(t, d);
      // The left joint (he only comes at the right one): idle, then a sweep
      // over the brush, the paste and the four connectors.
      await _pump(t, 9000);
      final hand = find.byKey(const ValueKey('gesture-hint'));
      expect(hand, findsOneWidget);
      final st = t.state<IdleHintState>(find.ancestor(of: hand, matching: find.byType(IdleHint)).first);
      expect(st.debugOptions, hasLength(6), reason: 'every tool, not the next step');
      await _hold(t, _L.brush, 1700);
      await t.tap(_label(_L.paste));
      await _pump(t, 300);
      await t.tap(_label(_L.conn(M4JumperMakeConn.pgAl)));
      await _pump(t, 400);
      // A short press on one spanner: nothing yet.
      await _hold(t, _L.oneWrench, 300);
      expect(find.byType(MistakeCard), findsNothing);
      await _hold(t, _L.oneWrench, 1300);
      expect(find.byType(MistakeCard), findsOneWidget, reason: 'one spanner is a slip');
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [_M.oneWrench.key]);
      await _pump(t, 9000);
      expect(hand, findsNothing, reason: 'no scene hand while the slip card is up');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      // Still loose: the two spanners finish it.
      expect(_label(_L.twoWrench), findsOneWidget);
      await _hold(t, _L.twoWrench, 1300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _close(t, c);
    });

    testWidgets('gesture hint: after idle a sweep over all four pieces (none in the intro); a touch hides it', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(M4JumperMakePage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await _pump(t, 9000);
      final hand = find.byKey(const ValueKey('gesture-hint'));
      if (find.byType(GuideIntro).evaluate().isNotEmpty) expect(hand, findsNothing, reason: 'no hand while the guide talks');
      await waitIntro(t);
      await _pump(t, 9000);
      expect(hand, findsOneWidget);
      final st = t.state<IdleHintState>(find.ancestor(of: hand, matching: find.byType(IdleHint)).first);
      expect(st.debugOptions, hasLength(4), reason: 'every piece, not the right one');
      await t.tapAt(const Offset(200, 260));
      await t.pump(const Duration(milliseconds: 100));
      expect(hand, findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
