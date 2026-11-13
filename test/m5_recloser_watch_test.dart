// Lesson 5.1, কাজ 2 "ট্রিপ মানে ডেড নয়" (m5_recloser_watch): the rules (count
// the recloser's shots against decoys → report the count and the flash's span;
// a PTW before any climb; the tester on every phase, the spike, then the
// clamp; climbing early = deadly; driving off before the PTW, the clamp before
// the tester, a wrong report = slips), the deal, the libraries, and the level
// in the shell: the guide first, a full clean play with a reason pick and the
// coworker refused (the radio waits for him), a wrong report (the operator
// reads his record), three slips, the deadly freeze (climbing in the watch;
// listening to him; the clamp before the spike), and the gesture hand (how,
// never what; none during the watch).
import 'dart:async';
import 'dart:convert';
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
import 'package:slm_flutter/features/game/m5_recloser_watch.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro, LinemanFigure;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '5.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m5RecloserPacks['do_5_1_b']!;

/// The new art is not bundled in tests until the director wires it: read it
/// from disk when the bundle does not have it.
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

Future<void> _pump(WidgetTester t, int ms, {int step = 50}) async {
  for (var i = 0; i < ms; i += step) {
    await t.pump(Duration(milliseconds: step));
  }
}

Future<bool> _pumpUntil(WidgetTester t, bool Function() ok, {int maxMs = 8000, int step = 100}) async {
  for (var ms = 0; ms < maxMs; ms += step) {
    if (ok()) return true;
    await t.pump(Duration(milliseconds: step));
  }
  return ok();
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
M5RecloserGeo get _geo => M5RecloserGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tap(WidgetTester t, String label) async {
  await t.tap(_label(label), warnIfMissed: false);
  await _pump(t, 300);
}

Future<void> _hold(WidgetTester t, String label, {int ms = 1200}) async {
  final g = await t.startGesture(t.getCenter(_label(label)));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

Future<void> _dragTo(WidgetTester t, Offset from, Offset to) async {
  final g = await t.startGesture(from);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 8)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

Future<(ProviderContainer, M5RecloserProbe)> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final p = M5RecloserProbe();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5RecloserPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: p)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  return (c, p);
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue, reason: 'the reason deck');
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 3000);
}

/// Watches until the lock-out (tapping the notepad on every reclose).
Future<void> _watch(WidgetTester t, M5RecloserProbe p) async {
  expect(await _pumpUntil(t, () => p.watching, maxMs: 12000), isTrue, reason: 'the watch begins');
  expect(await _pumpUntil(t, () => p.stage == M5RecloserStage.report, maxMs: 70000, step: 200), isTrue, reason: 'the lock-out');
  await _pump(t, 3500);
}

/// Sets the count and the span, and reports.
Future<void> _report(WidgetTester t, int count, int span) async {
  for (var i = 0; i < count; i++) {
    await _tap(t, M5RecloserLines.countUp);
  }
  await _tapAt(t, _geo.spanHit(span).center);
  await _tap(t, M5RecloserLines.report);
}

/// The PTW: the first press brings him (refused), then the permit, then the
/// slip to the trainee; the reason.
Future<void> _ptw(WidgetTester t) async {
  await _hold(t, M5RecloserLines.radio, ms: 300);
  expect(await _pumpUntil(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 3000), isTrue, reason: 'he comes on the first press');
  expect(_label(M5RecloserLines.ptwSlip), findsNothing, reason: 'the radio waits for him');
  await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
  await _pump(t, 600);
  await _pickRight(t, M5RecloserLines.coworker.right);
  await _pump(t, 3000);
  await _hold(t, M5RecloserLines.radio);
  expect(await _pumpUntil(t, () => _label(M5RecloserLines.ptwSlip).evaluate().isNotEmpty, maxMs: 6000), isTrue, reason: 'the permit');
  await _pump(t, 600);
  await _dragTo(t, t.getCenter(_label(M5RecloserLines.ptwSlip)), t.getCenter(find.byType(LinemanFigure)));
  await _reason(t, M5RecloserLines.whyRight[M5RecloserWhy.ptw]!);
}

Offset _vanAt(M5RecloserProbe p, int? span) => _geo.vanRect(_geo.vanX(span)).center * _k;

/// The van to the flash's span; then the tester ×3, the spike, the clamp; the reason.
Future<void> _span(WidgetTester t, M5RecloserProbe p) async {
  final d = p.deal!;
  await _dragTo(t, _vanAt(p, null), _vanAt(p, d.faultSpan));
  await _pump(t, 1000);
  expect(p.stage, M5RecloserStage.span);
  for (var i = 0; i < 3; i++) {
    await _hold(t, M5RecloserLines.toolLabel(M5RecloserTool.tester));
  }
  expect(find.text('C ${M5RecloserLines.dead}'), findsOneWidget);
  await _hold(t, M5RecloserLines.toolLabel(M5RecloserTool.spike));
  await _dragTo(t, t.getCenter(_label(M5RecloserLines.toolLabel(M5RecloserTool.clamp))), _geo.spanHit(d.faultSpan).center * _k);
  await _reason(t, M5RecloserLines.whyRight[M5RecloserWhy.earth]!);
}

int _seedWhere(bool Function(M5RecloserDeal d) ok) {
  for (var s = 0; s < 400; s++) {
    if (ok(m5RecloserDeal(math.Random(s)))) return s;
  }
  throw StateError('no seed');
}

const _deal1 = M5RecloserDeal(
  weather: M5Weather.storm,
  fault: M5Fault.branch,
  faultSpan: 2,
  events: [
    M5Event(atMs: 3000, kind: M5EventKind.shot),
    M5Event(atMs: 10000, kind: M5EventKind.lightning),
    M5Event(atMs: 17000, kind: M5EventKind.shot),
  ],
  lockAtMs: 26000,
  feeder: 4,
  ptw: 472,
);

M5RecloserRun _toPtw() {
  final r = M5RecloserRun(_deal1)..lockOut();
  expect(r.report(2, 2), isNull);
  r.next();
  return r;
}

M5RecloserRun _toSpan() {
  final r = _toPtw();
  expect(r.radio(), isTrue);
  expect(r.takePtw(), isTrue);
  r.next();
  expect(r.drive(2), isNull);
  expect(r.stage, M5RecloserStage.span);
  return r;
}

void main() {
  group('rules', () {
    test('deals: 2–3 shots, 1–2 decoys (lightning only in a storm), in time order, apart; lock-out 25–60 s; the fault fits the weather; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 120; s++) {
        final d = m5RecloserDeal(math.Random(s));
        expect(d.shots, inInclusiveRange(2, 3));
        expect(d.decoys, inInclusiveRange(1, 2));
        if (d.weather != M5Weather.storm) expect(d.events.any((e) => e.kind == M5EventKind.lightning), isFalse);
        expect(switch (d.weather) {
          M5Weather.storm => d.fault == M5Fault.branch,
          M5Weather.windy => d.fault == M5Fault.clash,
          M5Weather.clear => d.fault == M5Fault.bird || d.fault == M5Fault.jumper,
        }, isTrue);
        for (var i = 1; i < d.events.length; i++) {
          expect(d.events[i].atMs - (d.events[i - 1].atMs + d.events[i - 1].ms), greaterThanOrEqualTo(3000));
        }
        expect(d.lockAtMs, inInclusiveRange(25000, 60000));
        expect(d.lockAtMs, greaterThan(d.events.last.atMs + d.events.last.ms + 2000), reason: 'a silence before the lock-out');
        expect(d.faultSpan, inInclusiveRange(0, 3));
        expect(d.feeder, inInclusiveRange(1, 9));
        expect(d.ptw, inInclusiveRange(100, 999));
        seen.add('${d.weather.name}|${d.events.map((e) => '${e.kind.name}@${e.atMs ~/ 1000}').join(',')}|${d.faultSpan}');
      }
      expect(seen.length, greaterThan(100));
    });

    test('the report: right → its reason; a wrong count, a wrong span or both = one slip each report', () {
      final r = M5RecloserRun(_deal1);
      expect(r.report(2, 2), isNull, reason: 'not before the lock-out');
      expect(r.reported, isFalse);
      r.stroke();
      r.stroke();
      r.stroke();
      expect(r.strokes, 3, reason: 'every tap a stroke, decoys too');
      r.lockOut();
      expect(r.stage, M5RecloserStage.report);
      expect(r.report(2, 2), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(M5RecloserLines.caughtCount));
      expect((M5RecloserRun(_deal1)..lockOut()).report(3, 2), M5RecloserMistakes.countWrong, reason: 'the lightning counted');
      expect((M5RecloserRun(_deal1)..lockOut()).report(2, 1), M5RecloserMistakes.spanWrong);
      final b = M5RecloserRun(_deal1)..lockOut();
      expect(b.report(1, 0), M5RecloserMistakes.bothWrong);
      expect(b.slips, 1);
      expect(b.report(2, 2), isNull, reason: 'one report');
      expect(b.slips, 1);
    });

    test('the PTW: climbing before it is deadly (in the watch too); driving off before it is a slip; the slip needs the permit', () {
      final w = M5RecloserRun(_deal1);
      final m = w.climb();
      expect(m, M5RecloserMistakes.noPtw);
      expect(m!.deadly, isTrue);
      expect(w.ended, isTrue);
      final r = M5RecloserRun(_deal1)..lockOut();
      expect(r.drive(2), M5RecloserMistakes.patrolEarly, reason: 'patrol before the permit');
      expect(r.vanSpan, isNull, reason: 'the van stays');
      final p = _toPtw();
      expect(p.takePtw(), isFalse, reason: 'not issued yet');
      expect(p.drive(2), M5RecloserMistakes.patrolEarly);
      expect(p.radio(), isTrue);
      expect(p.climb(), M5RecloserMistakes.noPtw, reason: 'issued but not in hand');
      final q = _toPtw()..radio();
      expect(q.takePtw(), isTrue);
      expect(q.roundDone, isTrue);
      expect(q.caught, containsAll([M5RecloserLines.caughtLive, M5RecloserLines.caughtPtw]));
    });

    test('the drive: a span without the flash keeps the drive; the flash span starts the span step', () {
      final r = _toPtw()
        ..radio()
        ..takePtw()
        ..next();
      expect(r.stage, M5RecloserStage.drive);
      expect(r.drive(0), isNull);
      expect(r.stage, M5RecloserStage.drive);
      expect(r.atFault, isFalse);
      expect(r.drive(2), isNull);
      expect(r.stage, M5RecloserStage.span);
      expect(r.atFault, isTrue);
    });

    test('the span: clamp before the spike = deadly; clamp before the tester = a slip (no clamp); climbing untested / unearthed = deadly', () {
      final a = _toSpan();
      expect(a.clamp(), M5RecloserMistakes.clampFirst);
      expect(a.deadly, M5RecloserMistakes.clampFirst);
      final b = _toSpan()..driveSpike();
      expect(b.clamp(), M5RecloserMistakes.testFirst);
      expect(b.clamped, isFalse);
      expect(b.slips, 1);
      final c = _toSpan()
        ..test()
        ..test();
      expect(c.climb(), M5RecloserMistakes.noTest, reason: 'two phases only');
      final d = _toSpan()
        ..test()
        ..test()
        ..test();
      expect(d.climb(), M5RecloserMistakes.noEarth);
      final e = _toSpan()
        ..test()
        ..test()
        ..test()
        ..test()
        ..driveSpike();
      expect(e.tested, 3);
      expect(e.clamp(), isNull);
      expect(e.roundDone, isTrue);
      expect(e.caught, contains(M5RecloserLines.caughtEarth));
      e.next();
      expect(e.stage, M5RecloserStage.climb);
      expect(e.climb(), isNull);
      expect(e.aloft, isTrue);
      expect(e.clearFault(), isTrue);
      expect(e.done, isTrue);
      expect(e.passed, isTrue);
      expect(e.percent, 100);
    });

    test('tool row: every tool, never laid out left to right in a working order; rows differ', () {
      expect(m5RecloserInWorkOrder(const [M5RecloserTool.tester, M5RecloserTool.spike, M5RecloserTool.clamp]), isTrue);
      expect(m5RecloserInWorkOrder(const [M5RecloserTool.spike, M5RecloserTool.tester, M5RecloserTool.clamp]), isTrue);
      final rows = <String>{};
      for (var s = 0; s < 40; s++) {
        final row = m5RecloserToolRow(math.Random(s));
        expect(row.toSet(), M5RecloserTool.values.toSet());
        expect(m5RecloserInWorkOrder(row), isFalse, reason: '$row');
        rows.add(row.map((x) => x.name).join(','));
      }
      expect(rows.length, 4);
    });

    test('English digits only; locked words; every mistake has its picture and source; the four deadly ones; keys unique', () {
      final all = <String>[
        M5RecloserLines.intro,
        ...M5RecloserLines.tasks,
        ...M5RecloserLines.allWhyRight,
        ...M5RecloserLines.myths,
        ...M5RecloserLines.whyQ.values,
        ...M5RecloserLines.coworker.recordedLines,
        ...M5RecloserLines.coworker.right,
        ...M5RecloserLines.coworker.wrong,
        ...M5RecloserLines.coworker.asks,
        ...M5RecloserLines.locals,
        ...M5RecloserLines.opCall(4),
        M5RecloserLines.opRecord(3, 1),
        M5RecloserLines.opIssue(4, 472),
        M5RecloserLines.opCharge(4),
        for (final m in M5RecloserMistakes.all) m.textBn,
        M5RecloserLines.allSet,
        M5RecloserLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5RecloserMistakes.all.where((m) => m.deadly).toSet(),
          {M5RecloserMistakes.noPtw, M5RecloserMistakes.noTest, M5RecloserMistakes.noEarth, M5RecloserMistakes.clampFirst});
      expect(M5RecloserMistakes.all.map((m) => m.key).toSet(), hasLength(M5RecloserMistakes.all.length));
      for (final m in M5RecloserMistakes.all) {
        expect(m.key, startsWith('5.1/m5_recloser_watch/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(M5RecloserMistakes.sources[m.key], isNotNull, reason: m.key);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      // Ruling texts (module5_rulings.md M5-2, M5-3).
      expect(M5RecloserMistakes.testFirst.textBn, contains('আগে টেস্টার দিয়ে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক'));
      expect(M5RecloserMistakes.patrolEarly.textBn, contains('টহলের আগে কন্ট্রোল রুমকে জানিয়ে ফিল্ড মেমো/ডকেট নিন'));
      expect(m5RecloserPacks.keys, ['do_5_1_b']);
      // M5-3: never a PTW as a must before setting off on patrol.
      for (final l in [M5RecloserLines.askPtw, M5RecloserLines.caughtPtw, ...M5RecloserLines.whyQ.values]) {
        expect(l.contains('রওনা') || l.contains('যাওয়ার আগে') || l.contains('ছাড়ার আগে'), isFalse, reason: l);
      }
      // The guide's span task never names climbing or its order (the climb sign is the trap).
      expect(M5RecloserLines.askSpan.contains('ওঠা'), isFalse);
      expect(M5RecloserLines.askSpan.contains('নিরাপদ'), isFalse);
    });

    test('art folder: only the pictures the mistakes use', () {
      final used = {for (final m in M5RecloserMistakes.all) m.art};
      final files = Directory('assets/game/art/m5_recloser_watch').listSync().whereType<File>().map((f) => f.path.replaceAll(r'\', '/')).toSet();
      expect(files, used);
    });

    test('libraries: same length, big enough, never a rule marked wrong; the coworker says lesson 5.1 myth 1 word for word', () {
      expectSameLength('why', [...M5RecloserLines.allWhyRight, ...M5RecloserLines.myths]);
      expect(M5RecloserLines.myths.toSet().intersection(M5RecloserLines.allWhyRight.toSet()), isEmpty);
      for (final w in M5RecloserWhy.values) {
        final right = M5RecloserLines.whyRight[w]!;
        expectLibrary('$w', right, M5RecloserLines.myths);
        expect(M5RecloserLines.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, M5RecloserLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = M5RecloserLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(cw.asks.toSet(), hasLength(3));
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      final l51 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '5.1');
      final myth1 = ((l51['content'] as Map)['myth_buster'] as Map)['myths'][0]['myth'] as String;
      expect(cw.line, myth1);
    });

    test('rival lines: every line of his resolves to a clip or is listed to record', () {
      final cw = M5RecloserLines.coworker;
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: 'his exit is recorded');
      for (final l in cw.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true) != null || M5RecloserLines.rivalToRecord.contains(l), isTrue, reason: l);
      }
      expect(M5RecloserLines.rivalToRecord, [cw.line]);
    });

    test('tap areas: the spans do not overlap, stay on the 360-wide scene under the header; the climb sign and the stall stand clear', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M5RecloserGeo.forScene(h, 0);
        final spans = [for (var i = 0; i < M5RecloserGeo.spans; i++) g.spanHit(i)];
        for (final r in spans) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.width, greaterThanOrEqualTo(48));
          expect(r.top, greaterThan(120), reason: 'below the header');
        }
        for (var i = 0; i < spans.length; i++) {
          for (var j = i + 1; j < spans.length; j++) {
            expect(spans[i].overlaps(spans[j]), isFalse, reason: 'h $h $i/$j');
          }
          for (var p = 0; p < 4; p++) {
            expect(spans[i].overlaps(g.climbSign(p)), isFalse, reason: 'h $h span $i sign $p');
          }
          expect(spans[i].overlaps(g.stall), isFalse);
        }
        expect(g.vanRect(g.vanX(3)).right, lessThanOrEqualTo(360));
        expect(g.groundY, lessThan(h - 100), reason: 'room for the notepad and radio');
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
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    testWidgets('the guide comes first: no start button, a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5RecloserPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 600);
      expect(_label(M5RecloserLines.notepad), findsOneWidget);
      expect(_label(M5RecloserLines.climb), findsOneWidget, reason: 'the plain sign is there from the start');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final (c, p) = await _open(t, 5);
      await _pumpUntil(t, () => p.watching, maxMs: 12000);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M5RecloserLines.askWatch)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final seed in [7, 12]) {
      testWidgets('flow (seed $seed): watch, report, refuse him, PTW, drive, test, spike, clamp, climb, clear → pass', (t) async {
        final (c, p) = await _open(t, seed);
        final d = p.deal!;
        await _watch(t, p);
        await _report(t, d.shots, d.faultSpan);
        await _reason(t, M5RecloserLines.whyRight[M5RecloserWhy.lockout]!);
        expect(p.stage, M5RecloserStage.ptw);
        await _ptw(t);
        expect(p.stage, M5RecloserStage.drive);
        await _span(t, p);
        expect(p.stage, M5RecloserStage.climb);
        await _tap(t, M5RecloserLines.climb);
        await _pump(t, 800);
        await _tapAt(t, _geo.spanHit(d.faultSpan).center);
        await _pump(t, 4000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.1/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.1/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5RecloserLines.caughtCall), findsOneWidget);
        expect(find.text(M5RecloserLines.caughtEarth), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a wrong report: its card, then the operator reads his record and the play goes on', (t) async {
      final (c, p) = await _open(t, 4);
      final d = p.deal!;
      await _watch(t, p);
      await _report(t, d.shots == 3 ? 2 : 3, d.faultSpan);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5RecloserMistakes.countWrong.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
      expect(find.textContaining('রেকর্ডে আছে'), findsOneWidget, reason: 'the operator reads his record');
      expect(await _pumpUntil(t, () => p.stage == M5RecloserStage.ptw, maxMs: 6000), isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5RecloserMistakes.countWrong.key);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'no reason after a wrong report');
      await _close(t, c);
    });

    testWidgets('three slips (driving off before the PTW) strike the level out', (t) async {
      final (c, p) = await _open(t, 2);
      await _watch(t, p);
      for (var i = 0; i < 3; i++) {
        await _dragTo(t, _vanAt(p, null), _vanAt(p, 2));
        await _pump(t, 600);
        if (i < 2) {
          expect(find.text(M5RecloserMistakes.patrolEarly.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('climbing in the watch (before any PTW): the scene freezes first, then the card (near-miss)', (t) async {
      final (c, p) = await _open(t, 2);
      expect(await _pumpUntil(t, () => p.watching, maxMs: 12000), isTrue);
      await _tap(t, M5RecloserLines.climb);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M5RecloserLines.recloseNow), findsOneWidget, reason: 'the next reclose');
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5RecloserMistakes.noPtw.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze, the charge, then the card', (t) async {
      final (c, p) = await _open(t, 11);
      final d = p.deal!;
      await _watch(t, p);
      await _report(t, d.shots, d.faultSpan);
      await _reason(t, M5RecloserLines.whyRight[M5RecloserWhy.lockout]!);
      await _hold(t, M5RecloserLines.radio, ms: 300);
      expect(await _pumpUntil(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 3000), isTrue);
      await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5RecloserLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.text(M5RecloserLines.opCharge(d.feeder)), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5RecloserMistakes.noPtw.key);
      await _close(t, c);
    });

    testWidgets('the clamp before the spike: deadly freeze', (t) async {
      final (c, p) = await _open(t, 7);
      final d = p.deal!;
      await _watch(t, p);
      await _report(t, d.shots, d.faultSpan);
      await _reason(t, M5RecloserLines.whyRight[M5RecloserWhy.lockout]!);
      await _ptw(t);
      await _dragTo(t, _vanAt(p, null), _vanAt(p, d.faultSpan));
      await _pump(t, 1000);
      await _dragTo(t, t.getCenter(_label(M5RecloserLines.toolLabel(M5RecloserTool.clamp))), _geo.spanHit(d.faultSpan).center * _k);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5RecloserMistakes.clampFirst.key);
      await _close(t, c);
    });

    testWidgets('gesture hand: none in the watch; at the report a swipe on the wheel, then a sweep over all four spans; never a tap on a span', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.lockAtMs < 40000);
      final (c, p) = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(await _pumpUntil(t, () => p.watching, maxMs: 12000), isTrue);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the watch shows no hand');
      await _watch(t, p);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the report');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a swipe presses nothing');
      await _tap(t, M5RecloserLines.countUp);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions, hasLength(4), reason: 'every span alike');
      await _close(t, c);
    });

    testWidgets('gesture hand before the permit: a sweep over the radio and the van, never a hold on the radio', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final (c, p) = await _open(t, 7);
      final d = p.deal!;
      await _watch(t, p);
      await _report(t, d.shots, d.faultSpan);
      await _reason(t, M5RecloserLines.whyRight[M5RecloserWhy.lockout]!);
      expect(p.stage, M5RecloserStage.ptw);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle before the permit');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(scene().debugOptions, hasLength(2), reason: 'radio and van alike');
      await _close(t, c);
    });
  });
}
