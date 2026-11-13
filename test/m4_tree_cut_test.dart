// Lesson 4.8 (গাছের ডালপালা ছাঁটা), কাজ 2 "ডাল নামাও, লাইন বাঁচিয়ে": the rules
// (small to big, the rope before the saw, out of the fall line, the 3-cut
// method with the limb lowered on the rope, the clearance check with
// directional pruning), the deal, the reason libraries, and the level in the
// shell: idle perf, the guide first, the guide's tap, a full clean play to a
// pass (with the coworker refused), a slip card, and the deadly freeze
// (standing in the fall line). Audit 2026-11-11: no false slip in the praise
// window, the coworker comes on a fast play (the tool waits for him) and
// listening is a slip, 3 slips strike out, the tray's order is dealt, no chalk
// ticks mark the cuts, and the gesture hint sweeps (never points at one).
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_tree_cut.dart';
import 'package:slm_flutter/features/game/m4_tree_cut_world.dart' show M4TreeCutTree, M4TreeCutWorldPainter;
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
  rungId: '4.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '4.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m4TreeCutPacks['do_4_8_b']!;

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

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M4TreeCutGeo get _geo => M4TreeCutGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
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
    builder: (_) => M4TreeCutPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

Future<void> _reason(WidgetTester t, M4TreeCutStation s) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: '$s deck');
  await _pump(t, 700);
  await _pickRight(t, M4TreeCutLines.whyRight(s));
  await _pump(t, 4500);
}

Future<void> _trim(WidgetTester t, M4TreeCutDeal d) async {
  for (final p in [...d.twigs, M4TreeCutPiece.side]) {
    await t.tapAt(_screen(_geo.pieceRect(p).center));
    await _pump(t, 400);
    expect(find.byType(MistakeCard), findsNothing, reason: '$p');
  }
  await _reason(t, M4TreeCutStation.trim);
}

Future<void> _hold(WidgetTester t, String label, int ms) async {
  final g = await t.startGesture(t.getCenter(find.text(label)));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

void main() {
  group('rules', () {
    test('deals: 2–3 twigs, the shoot at the line low or mid, 3–4 lengths; fresh every play', () {
      final seen = <String>{};
      final trays = <M4TreeCutTool>{};
      for (var s = 0; s < 80; s++) {
        final d = dealM4TreeCut(math.Random(s));
        expect(d.twigs.length, inInclusiveRange(2, 3));
        expect(d.twigs.contains(M4TreeCutPiece.side) || d.twigs.contains(M4TreeCutPiece.limb), isFalse);
        expect(d.toward, isNot(M4TreeCutShoot.back));
        expect(d.notches, inInclusiveRange(3, 4));
        expect(d.tray.toSet(), M4TreeCutTool.values.toSet());
        seen.add('${d.twigs}${d.toward}${d.notches}');
        trays.add(d.tray.first);
      }
      expect(seen.length, greaterThan(8));
      expect(trays, M4TreeCutTool.values.toSet(), reason: 'the tray order is dealt: never always the rope first');
    });

    const deal = M4TreeCutDeal(twigs: {M4TreeCutPiece.tipTwig, M4TreeCutPiece.twigA}, toward: M4TreeCutShoot.low, notches: 3);
    M4TreeCutRun run() => M4TreeCutRun(deal);

    test('trim: small to big — the side branch or the limb before a twig is a slip', () {
      final r = run();
      expect(r.trim(M4TreeCutPiece.limb), M4TreeCutMistakes.outerFirst);
      expect(r.trim(M4TreeCutPiece.side), M4TreeCutMistakes.outerFirst);
      expect(r.trim(M4TreeCutPiece.twigB), isNull, reason: 'not dealt');
      expect(r.gone, isEmpty);
      expect(r.trim(M4TreeCutPiece.twigA), isNull);
      expect(r.trim(M4TreeCutPiece.side), M4TreeCutMistakes.outerFirst, reason: 'the tip twig still there');
      expect(r.trim(M4TreeCutPiece.tipTwig), isNull);
      expect(r.trimDone, isFalse);
      expect(r.trim(M4TreeCutPiece.side), isNull);
      expect(r.trimDone, isTrue);
      expect(r.slips, 3);
      expect(r.caught, contains(M4TreeCutLines.caughtOrder));
    });

    test('trim done: the limb tap books no "small first" slip (the praise window bug)', () {
      final r = run();
      for (final p in deal.trimmed.toList()..sort((a, b) => m4TreeCutRank(a).compareTo(m4TreeCutRank(b)))) {
        expect(r.trim(p), isNull, reason: '$p');
      }
      expect(r.trimDone, isTrue);
      expect(r.trim(M4TreeCutPiece.limb), isNull);
      expect(r.slips, 0);
    });

    test('after a deadly no rule takes a move', () {
      final r = run()..station = M4TreeCutStation.spot;
      expect(r.stand(M4TreeCutSpot.below)!.deadly, isTrue);
      r.station = M4TreeCutStation.cut;
      expect(r.cut(M4TreeCutMark.under), isNull);
      expect(r.cuts, isEmpty);
      r.station = M4TreeCutStation.clear;
      expect(r.cutShoot(M4TreeCutShoot.back), isNull);
      expect(r.checkClear(), isNull);
      expect(r.listen(), isNull);
      expect(r.slips, 0);
    });

    test('rope: the saw before the rope is a slip; listening to him is a slip', () {
      final r = run()..station = M4TreeCutStation.rope;
      expect(r.useOnLimb(M4TreeCutTool.saw), M4TreeCutMistakes.noRope);
      expect(r.roped, isFalse);
      expect(r.useOnLimb(M4TreeCutTool.rope), isNull);
      expect(r.roped, isTrue);
      expect(r.caught, contains(M4TreeCutLines.caughtRope));
      expect(r.listen(), M4TreeCutMistakes.listened);
      expect(M4TreeCutMistakes.listened.deadly, isFalse, reason: 'listening is a slip (playbook row 8)');
      expect(r.slips, 2);
    });

    test('spot: below the limb or out on it is deadly; beside the trunk is right', () {
      for (final s in [M4TreeCutSpot.below, M4TreeCutSpot.out]) {
        final r = run()..station = M4TreeCutStation.spot;
        final m = r.stand(s);
        expect(m, M4TreeCutMistakes.fallLine);
        expect(m!.deadly, isTrue);
        expect(r.ended, isTrue);
      }
      final ok = run()..station = M4TreeCutStation.spot;
      expect(ok.stand(M4TreeCutSpot.beside), isNull);
      expect(ok.caught, contains(M4TreeCutLines.caughtSpot));
    });

    test('cut: under → top (free on the rope) → lowered length by length → collar; out of order or letting go is a slip', () {
      final r = run()..station = M4TreeCutStation.cut;
      expect(r.cut(M4TreeCutMark.top), M4TreeCutMistakes.threeCut);
      expect(r.cut(M4TreeCutMark.collar), M4TreeCutMistakes.threeCut);
      expect(r.cuts, isEmpty);
      expect(r.cut(M4TreeCutMark.under), isNull);
      expect(r.freed, isFalse);
      expect(r.cut(M4TreeCutMark.top), isNull);
      expect(r.freed, isTrue);
      expect(r.cut(M4TreeCutMark.collar), isNull, reason: 'still on the rope: ignored');
      expect(r.cutDone, isFalse);
      expect(r.letGo(), M4TreeCutMistakes.letGo);
      expect(r.lowerOne(), isFalse);
      expect(r.lowerOne(), isFalse);
      expect(r.lowerOne(), isTrue);
      expect(r.caught, contains(M4TreeCutLines.caughtLower));
      expect(r.letGo(), isNull);
      expect(r.cut(M4TreeCutMark.collar), isNull);
      expect(r.cutDone, isTrue);
      expect(r.caught, contains(M4TreeCutLines.caughtThreeCut));
      expect(r.slips, 3);
    });

    test('clear: a shoot growing away is a slip; "clear" with the shoot at the line left is a slip; then the play passes', () {
      final r = run();
      for (var i = 0; i < 4; i++) {
        r.next();
      }
      expect(r.station, M4TreeCutStation.clear);
      expect(r.cutShoot(M4TreeCutShoot.back), M4TreeCutMistakes.overCut);
      expect(r.cutShoot(M4TreeCutShoot.mid), M4TreeCutMistakes.overCut);
      expect(r.checkClear(), M4TreeCutMistakes.missed);
      expect(r.cutShoot(M4TreeCutShoot.low), isNull);
      expect(r.checkClear(), isNull);
      expect(r.cleared, isTrue);
      expect(r.caught, contains(M4TreeCutLines.caughtClear));
      expect(r.percent, 55);
      expect(r.passed, isTrue);
    });

    test('English digits only; every mistake has its picture, its key and its lesson point; one deadly', () {
      final all = <String>[
        M4TreeCutLines.intro,
        ...M4TreeCutLines.tasks,
        for (final s in M4TreeCutStation.values) ...[M4TreeCutLines.why(s), ...M4TreeCutLines.whyRight(s)],
        ...M4TreeCutLines.excuses,
        ...M4TreeCutLines.coworker.recordedLines,
        ...M4TreeCutLines.coworker.right,
        ...M4TreeCutLines.coworker.wrong,
        ...M4TreeCutLines.coworker.asks,
        for (final m in M4TreeCutMistakes.all) m.textBn,
        M4TreeCutLines.allSet,
        M4TreeCutLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M4TreeCutMistakes.all.where((m) => m.deadly), [M4TreeCutMistakes.fallLine]);
      expect(M4TreeCutMistakes.overCut.lessonPoint, isNull, reason: 'advanced section');
      expect(M4TreeCutMistakes.all.map((m) => m.key).toSet().length, M4TreeCutMistakes.all.length);
      for (final m in M4TreeCutMistakes.all) {
        if (m != M4TreeCutMistakes.overCut) expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
        expect(m.key, startsWith('4.8/m4_tree_cut/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m4TreeCutPacks.keys, ['do_4_8_b']);
      expect(_pack.quickMs, kM4TreeCutQuickMs);
    });

    test('reasons: same length, big enough, one right per deal; his exit line is recorded', () {
      final every = [for (final s in M4TreeCutStation.values) ...M4TreeCutLines.whyRight(s), ...M4TreeCutLines.excuses];
      expectSameLength('why', every);
      for (final s in M4TreeCutStation.values) {
        expectLibrary('$s', M4TreeCutLines.whyRight(s), M4TreeCutLines.excuses);
        for (var i = 0; i < 10; i++) {
          final d = dealChoices(M4TreeCutLines.whyRight(s), M4TreeCutLines.excuses, math.Random(i));
          expect(d.where((o) => o.correct).length, 1);
          expect(d.map((o) => o.textBn).toSet().length, 3);
        }
      }
      final cw = M4TreeCutLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
    });

    test('tap areas: every target lies on the 360-wide scene and the nearest one wins', () {
      final g = _geo;
      final scene = Rect.fromLTWH(0, 0, 360, g.height);
      for (final p in M4TreeCutPiece.values) {
        expect(scene.contains(g.pieceRect(p).center), isTrue, reason: '$p');
      }
      for (final m in M4TreeCutMark.values) {
        expect(scene.contains(g.markRect(m).center), isTrue, reason: '$m');
      }
      final centres = [for (final p in M4TreeCutPiece.values) g.pieceRect(p).center];
      for (var i = 0; i < centres.length; i++) {
        for (var j = i + 1; j < centres.length; j++) {
          expect((centres[i] - centres[j]).distance, greaterThan(20), reason: '${M4TreeCutPiece.values[i]} / ${M4TreeCutPiece.values[j]}');
        }
      }
    });
  });

  testWidgets('the cut station: no chalk ticks mark where a cut goes (bark only)', (t) async {
    final g = _geo;
    final w = 360, h = g.height.ceil();
    final pixels = await t.runAsync(() async {
      final rec = ui.PictureRecorder();
      M4TreeCutWorldPainter(
        geo: g,
        tree: const M4TreeCutTree(present: {M4TreeCutPiece.tipTwig, M4TreeCutPiece.side}, gone: {M4TreeCutPiece.tipTwig, M4TreeCutPiece.side}, roped: true),
      ).paint(Canvas(rec), Size(w.toDouble(), h.toDouble()));
      final img = await rec.endRecording().toImage(w, h);
      return (await img.toByteData())!;
    });
    final data = pixels!;
    bool white(Offset p) {
      final i = ((p.dy.round() * w) + p.dx.round()) * 4;
      return data.getUint8(i) > 215 && data.getUint8(i + 1) > 215 && data.getUint8(i + 2) > 215;
    }

    for (final m in M4TreeCutMark.values) {
      final k = M4TreeCutGeo.markK(m);
      final half = M4TreeCutGeo.limbW(k) * 0.55 / 2;
      final at = switch (m) {
        M4TreeCutMark.under => g.markAt(m).translate(0, -half),
        M4TreeCutMark.top => g.markAt(m).translate(0, half),
        M4TreeCutMark.collar => g.markAt(m),
      };
      expect(white(at), isFalse, reason: '$m: no chalk tick on the limb');
    }
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
        await t.pumpWidget(ProviderScope(child: _app(M4TreeCutPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_tree_cut ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: _app(M4TreeCutPage(ctx: _ctx, pack: _pack, muted: true, seed: 1))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M4TreeCutLines.permit), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M4TreeCutLines.permit), findsOneWidget);
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
      expect(lines.every((l) => l.contains(M4TreeCutLines.askTrim)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: trim small to big, refuse him, rope, stand beside, 3-cut and lower, clear the shoot → pass', (t) async {
      const seed = 3;
      final deal = dealM4TreeCut(math.Random(seed));
      final c = await _open(t, seed);
      await _trim(t, deal);
      // He comes as the rope station opens.
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M4TreeCutLines.coworker.right);
      await _pump(t, 2600);
      await t.tap(_label(M4TreeCutLines.rope));
      await _pump(t, 200);
      await t.tapAt(_screen(_geo.limbRect.center));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, M4TreeCutStation.rope);
      // Beside the trunk, out of the fall line.
      await t.tapAt(_screen(_geo.spotRect(M4TreeCutSpot.beside).center));
      await _pump(t, 1000);
      await _reason(t, M4TreeCutStation.spot);
      // The three cuts, the limb lowered on the rope between.
      await t.tapAt(_screen(_geo.markRect(M4TreeCutMark.under).center));
      await _pump(t, 300);
      await t.tapAt(_screen(_geo.markRect(M4TreeCutMark.top).center));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsNothing);
      for (var i = 0; i < deal.notches; i++) {
        expect(find.text(M4TreeCutLines.lower), findsOneWidget, reason: 'length ${i + 1}');
        await _hold(t, M4TreeCutLines.lower, 800);
      }
      expect(find.text(M4TreeCutLines.lower), findsNothing);
      await t.tapAt(_screen(_geo.markRect(M4TreeCutMark.collar).center));
      await _pump(t, 300);
      await _reason(t, M4TreeCutStation.cut);
      // The clearance: the shoot at the line, then "clear".
      await t.tapAt(_screen(_geo.shootRect(deal.toward, toward: true).center));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsNothing);
      await t.tap(find.text(M4TreeCutLines.clearOk));
      await _pump(t, 300);
      await _reason(t, M4TreeCutStation.clear);
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.8/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['4.8/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M4TreeCutLines.caughtCall), findsOneWidget);
      expect(find.text(M4TreeCutLines.caughtLower), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the limb before the twigs: the slip card, booked; the play goes on', (t) async {
      const seed = 5;
      final deal = dealM4TreeCut(math.Random(seed));
      final c = await _open(t, seed);
      await t.tapAt(_screen(_geo.pieceRect(M4TreeCutPiece.limb).center));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4TreeCutMistakes.outerFirst.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await _trim(t, deal);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      await _close(t, c);
    });

    testWidgets('a limb tap in the praise window after the last twig books nothing', (t) async {
      const seed = 7;
      final deal = dealM4TreeCut(math.Random(seed));
      final c = await _open(t, seed);
      for (final p in [...deal.twigs, M4TreeCutPiece.side]) {
        await t.tapAt(_screen(_geo.pieceRect(p).center));
        await _pump(t, p == M4TreeCutPiece.side ? 50 : 400);
      }
      // The ◆ waits on the table: the limb tap must not count as "small first".
      for (var i = 0; i < 3; i++) {
        await t.tapAt(_screen(_geo.pieceRect(M4TreeCutPiece.limb).center));
        await _pump(t, 150);
      }
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _reason(t, M4TreeCutStation.trim);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    /// Trims, answers the reason, and waits only until the rope tray shows.
    Future<void> trimFast(WidgetTester t, M4TreeCutDeal deal) async {
      for (final p in [...deal.twigs, M4TreeCutPiece.side]) {
        await t.tapAt(_screen(_geo.pieceRect(p).center));
        await _pump(t, 400);
      }
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pickRight(t, M4TreeCutLines.whyRight(M4TreeCutStation.trim));
      for (var ms = 0; ms < 4000 && _label(M4TreeCutLines.rope).evaluate().isEmpty; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(_label(M4TreeCutLines.rope), findsOneWidget);
    }

    testWidgets('a fast play still meets the coworker: the rope on the limb waits for him; refused → roped', (t) async {
      const seed = 8;
      final deal = dealM4TreeCut(math.Random(seed));
      final c = await _open(t, seed);
      await trimFast(t, deal);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not come yet');
      await t.tap(_label(M4TreeCutLines.rope));
      await t.pump(const Duration(milliseconds: 50));
      await t.tapAt(_screen(_geo.limbRect.center));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the tool waits: he comes now');
      expect(find.text(M4TreeCutLines.why(M4TreeCutStation.rope)), findsNothing, reason: 'the rope is not tied before he speaks');
      await _pickRight(t, M4TreeCutLines.coworker.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      // The rope is still in hand: now it goes on.
      await t.tapAt(_screen(_geo.limbRect.center));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, M4TreeCutStation.rope);
      // He never comes back once the rope is tied.
      await _pump(t, 4000);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('listening to him is a slip (booked), not deadly; the play goes on', (t) async {
      const seed = 9;
      final deal = dealM4TreeCut(math.Random(seed));
      final c = await _open(t, seed);
      await trimFast(t, deal);
      await t.tap(_label(M4TreeCutLines.saw));
      await t.pump(const Duration(milliseconds: 50));
      await t.tapAt(_screen(_geo.limbRect.center));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the saw on the limb waits for him too');
      expect(c.read(gameSaveProvider).mistakes, isEmpty, reason: 'the held saw did not cut');
      await waitChoiceDeck(t);
      final wrong = _onScreen(M4TreeCutLines.coworker.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4TreeCutMistakes.listened.key);
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await t.tap(_label(M4TreeCutLines.rope));
      await _pump(t, 200);
      await t.tapAt(_screen(_geo.limbRect.center));
      await _pump(t, 400);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _reason(t, M4TreeCutStation.rope);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (StruckOutCard)', (t) async {
      final c = await _open(t, 10);
      for (var i = 0; i < 3; i++) {
        await t.tapAt(_screen(_geo.pieceRect(M4TreeCutPiece.limb).center));
        await _pump(t, 800);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget, reason: 'slip ${i + 1}');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(LevelPassPanel), findsNothing);
      expect(c.read(gameSaveProvider).rungProgress['4.8/do/1'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hint: a sweep over every piece while stuck (never pressing one); none in a card', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      const seed = 11;
      final deal = dealM4TreeCut(math.Random(seed));
      final c = await _open(t, seed);
      IdleHintState hint() => t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
      await _pump(t, 9500);
      expect(hint().showing, isTrue, reason: 'stuck at the twigs: the hand shows');
      expect(hint().debugOptions, hasLength(deal.twigs.length + 2), reason: 'every twig, the side branch and the limb');
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 120));
        final f = hint().debugFrame;
        if (f != null) expect(f.press, 0, reason: 'a sweep never presses a piece');
      }
      // A slip card: no hand.
      await t.tapAt(_screen(_geo.pieceRect(M4TreeCutPiece.limb).center));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, 9500);
      expect(hint().showing, isFalse);
      await _close(t, c);
    });

    testWidgets('reduced motion: no still hand on a scene answer (trim, spot); the tool chips still get one', (t) async {
      GestureHints.debugEnableInTests = true;
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        GestureHints.debugEnableInTests = false;
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      const seed = 12;
      final deal = dealM4TreeCut(math.Random(seed));
      final c = await _open(t, seed);
      final hintFinder = find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first;
      IdleHintState hint() => t.state<IdleHintState>(hintFinder);
      /// The still fingertip in global pixels, or null while no hand shows.
      Offset? tip() {
        final f = hint().debugFrame;
        return f == null ? null : f.tip + t.getTopLeft(hintFinder);
      }

      /// Idles [ms]; every still tip seen must be outside each of [rects].
      Future<bool> idle(int ms, List<Rect> rects, String what) async {
        var shown = false;
        for (var i = 0; i < ms; i += 100) {
          await t.pump(const Duration(milliseconds: 100));
          final p = tip();
          if (p == null) continue;
          shown = true;
          for (final r in rects) {
            expect(r.contains(p), isFalse, reason: '$what: the still hand sits on one answer at $p');
          }
        }
        return shown;
      }

      final pieces = [for (final p in M4TreeCutPiece.values) _screen(_geo.pieceRect(p).topLeft) & (_geo.pieceRect(p).size * _k)];
      expect(await idle(12000, pieces, 'trim'), isFalse, reason: 'no still hand over the scattered pieces');
      await _trim(t, deal);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M4TreeCutLines.coworker.right);
      await _pump(t, 2600);
      // The two tool chips side by side: the still hand rests between them.
      final chips = [t.getRect(_label(M4TreeCutLines.rope)), t.getRect(_label(M4TreeCutLines.saw))];
      expect(await idle(12000, chips, 'tray'), isTrue, reason: 'the chip row still gets its hint');
      await t.tap(_label(M4TreeCutLines.rope));
      await _pump(t, 200);
      await t.tapAt(_screen(_geo.limbRect.center));
      await _pump(t, 400);
      await _reason(t, M4TreeCutStation.rope);
      final spots = [for (final s in M4TreeCutSpot.values) _screen(_geo.spotRect(s).topLeft) & (_geo.spotRect(s).size * _k)];
      expect(await idle(12000, spots, 'spot'), isFalse, reason: 'no still hand over the standing spots (beside is the one safe answer)');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('below the limb: the scene freezes first, then the card (near-miss)', (t) async {
      const seed = 6;
      final deal = dealM4TreeCut(math.Random(seed));
      final c = await _open(t, seed);
      await _trim(t, deal);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M4TreeCutLines.coworker.right);
      await _pump(t, 2600);
      await t.tap(_label(M4TreeCutLines.rope));
      await _pump(t, 200);
      await t.tapAt(_screen(_geo.limbRect.center));
      await _pump(t, 400);
      await _reason(t, M4TreeCutStation.rope);
      await t.tapAt(_screen(_geo.spotRect(M4TreeCutSpot.below).center));
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4TreeCutMistakes.fallLine.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });
  });
}
