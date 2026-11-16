// Lesson 6.6 (এবি কেবিল), কাজ 2 "কাটা আবরণ সিল করো": the rules (the chalk
// only while finding; a repair started off the nick = a slip and the mark is
// wiped; tape turns must cover the whole nick; a tube must hold the nick inside
// its sealing length when it shrinks, off-centre = a slip and a new tube; 'শেষ'
// with a part open = a slip; three jobs; listening to the coworker = deadly),
// the deal (3 of 6 places, the nick smaller and the decoys more each job, tape
// and tube both dealt, the coworker's job, three different reasons), the
// libraries, every spoken line listed, the gesture hands never pointing at the
// nick, and the level in the shell: the guide first, a clean play (zoom, chalk,
// the coworker refused on his job, tape and tube, three reasons → pass), a
// wrong-spot slip card, three slips strike out, an open part at 'শেষ', a tube
// shrunk off-centre, the deadly freeze, and the gesture hand only while the
// level waits.
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
import 'package:slm_flutter/features/game/m6_abc_nick_seal.dart';
import 'package:slm_flutter/features/game/m6_abc_nick_seal_world.dart';
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
  rungId: '6.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6NickSealPacks['do_6_6_b']!;
typedef L = M6NickSealLines;
typedef Mk = M6NickSealMistakes;

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
    builder: (_) => M6NickSealPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

int _seedWhere(bool Function(M6NickDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6NickDeal(math.Random(s))));

// --- hands on ----------------------------------------------------------------
Finder get _touch => find.byWidgetPredicate((w) => w is GestureDetector && w.onDoubleTap != null && w.onScaleStart != null);

/// A layer point (design px) on screen.
Offset _g(WidgetTester t, Offset layer) => t.renderObject<RenderBox>(_touch).localToGlobal(layer);

/// A span place on the bundle, on screen, with a layer offset.
Offset _at(WidgetTester t, double spanT, [Offset d = Offset.zero]) => _g(t, M6NickSealProbe.layerOf!(spanT) + d);

Future<void> _doubleTap(WidgetTester t, Offset global) async {
  await t.tapAt(global);
  await t.pump(const Duration(milliseconds: 80));
  await t.tapAt(global);
  await _pump(t, 500);
}

/// From the whole span: zoom to 3× at [spanT].
Future<void> _zoomAt(WidgetTester t, double spanT) async {
  if (M6NickSealProbe.view!.z > 1.01) {
    await t.tap(_label(L.zoomOutLabel));
    await _pump(t, 500);
  }
  await _doubleTap(t, _at(t, spanT));
  expect(M6NickSealProbe.view!.detail, isTrue);
}

Future<void> _chalk(WidgetTester t, double spanT) async {
  await _zoomAt(t, spanT);
  await _doubleTap(t, _at(t, spanT));
  expect(M6NickSealProbe.run!.mark, closeTo(spanT, 0.006));
}

Future<void> _material(WidgetTester t, M6NickMat m) async {
  await t.tap(_label(L.mat(m)));
  await _pump(t, 400);
}

/// Circles round the bundle from [from] to [to] (zig-zag passes across it).
Future<void> _wrap(WidgetTester t, double from, double to, {double step = 0.004}) async {
  final g = await t.startGesture(_at(t, from, const Offset(0, -26)));
  await g.moveTo(_at(t, from, const Offset(0, -50)));
  await t.pump(const Duration(milliseconds: 30));
  var up = true;
  for (var x = from; x <= to + 1e-9; x += step) {
    await g.moveTo(_at(t, x, Offset(0, up ? 30 : -30)));
    await t.pump(const Duration(milliseconds: 30));
    up = !up;
  }
  await g.up();
  await _pump(t, 300);
}

/// Slide the tube until it sits over [spanT].
Future<void> _slideTube(WidgetTester t, double spanT) async {
  for (var k = 0; k < 5; k++) {
    final r = M6NickSealProbe.run!;
    if ((r.tubeT! - spanT).abs() < 0.003) return;
    // Past the touch slop straight down first (that does not move the tube),
    // then across by exactly the gap.
    final from = _at(t, r.tubeT!);
    final dx = _at(t, spanT).dx - from.dx;
    final g = await t.startGesture(from);
    await g.moveBy(const Offset(0, 24));
    await t.pump(const Duration(milliseconds: 30));
    await g.moveBy(const Offset(0, 1));
    await t.pump(const Duration(milliseconds: 30));
    const steps = 8;
    for (var i = 1; i <= steps; i++) {
      await g.moveBy(Offset(dx / steps, 0));
      await t.pump(const Duration(milliseconds: 30));
    }
    await g.up();
    await _pump(t, 300);
  }
}

Future<void> _heat(WidgetTester t) async {
  final g = await t.startGesture(t.getCenter(_label(L.heat)));
  await _pump(t, m6NickHeatMs + 300);
  await g.up();
  await _pump(t, 300);
}

Future<void> _done(WidgetTester t) async {
  await t.tap(_label(L.done));
  await _pump(t, 1900);
}

Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// One job done cleanly (the coworker refused on his job).
Future<void> _cleanJob(WidgetTester t, M6NickDeal d, int j) async {
  final job = d.jobs[j];
  await _chalk(t, job.nickT);
  await _material(t, job.mat);
  if (j == d.coworkerJob) {
    await _refuse(t);
    await _material(t, job.mat);
  }
  final r = M6NickSealProbe.run!;
  expect(r.stage, M6NickStage.seal, reason: 'job $j started');
  if (job.mat == M6NickMat.tape) {
    await _wrap(t, job.nickT - job.nickLen / 2 - 0.008, job.nickT + job.nickLen / 2 + 0.008);
  } else {
    await _slideTube(t, job.nickT);
    await _heat(t);
    expect(r.shrunk, isTrue);
  }
  expect(r.covered, isTrue, reason: 'job $j: turns ${r.turns} tube ${r.tubeT}');
  await _done(t);
  expect(find.byType(MistakeCard), findsNothing);
  await _pickRight(t, L.whyRight[d.whys[j]]!);
  await _pump(t, 1500);
}

// --- pure helpers --------------------------------------------------------------
M6NickJob _job({M6NickMat mat = M6NickMat.tape, double nick = 0.5, double len = 0.02, double off = 0.04}) => M6NickJob(
      span: M6NickSpan.shop,
      poles: (7, 8),
      nickT: nick,
      nickLen: len,
      nickCore: 1,
      decoys: const [M6NickMark(M6NickDecoy.dust, 0.3, 0), M6NickMark(M6NickDecoy.print, 0.7, 2)],
      mat: mat,
      tubeOffset: off,
    );

M6NickDeal _deal({List<M6NickMat> mats = const [M6NickMat.tape, M6NickMat.tube, M6NickMat.tape], int cw = 1}) => M6NickDeal(
      jobs: [for (final m in mats) _job(mat: m)],
      coworkerJob: cw,
      whys: const [M6NickWhy.cover, M6NickWhy.live, M6NickWhy.patrol],
    );

/// Seal the current job right (pure).
void _sealRight(M6NickRun r) {
  final j = r.now;
  r.chalk(j.nickT);
  expect(r.startRepair(), isNull);
  if (j.mat == M6NickMat.tape) {
    for (var x = j.nickT - j.nickLen / 2; x <= j.nickT + j.nickLen / 2 + 0.006; x += 0.006) {
      r.wrap(x);
    }
  } else {
    r.moveTube(j.nickT - r.tubeT!);
    expect(r.shrink(), isNull);
  }
  expect(r.finish(), isNull);
  r.nextJob();
}

void main() {
  group('rules', () {
    test('deals: 3 different places of 6, nick smaller and decoys more each job, tape and tube both, the coworker on any job, three different reasons; plays differ', () {
      final seen = <String>{};
      final cw = <int>{};
      final spans = <M6NickSpan>{};
      final whys = <M6NickWhy>{};
      for (var s = 0; s < 300; s++) {
        final d = m6NickDeal(math.Random(s));
        expect(d.jobs, hasLength(3));
        expect(d.jobs.map((j) => j.span).toSet(), hasLength(3));
        expect(d.jobs.map((j) => j.mat).toSet(), M6NickMat.values.toSet(), reason: 'tape and tube both every play');
        expect(d.whys.toSet(), hasLength(3));
        for (var j = 0; j < 3; j++) {
          final job = d.jobs[j];
          expect(job.nickLen, m6NickLens[j]);
          expect(job.decoys, hasLength(m6NickDecoyCounts[j]));
          expect(job.nickT, inInclusiveRange(0.12, 0.88));
          expect(job.decoys.map((x) => x.kind).toSet(), hasLength(job.decoys.length), reason: 'different decoys');
          for (final x in job.decoys) {
            expect((x.t - job.nickT).abs(), greaterThanOrEqualTo(0.07), reason: 'a decoy never sits on the nick');
          }
          expect(job.tubeOffset.abs(), inInclusiveRange(0.052, 0.066));
          // A tube put on at any accepted mark never holds the nick yet: it
          // always has to be slid over it.
          final worst = job.nickLen / 2 + m6NickMarkSlack;
          expect(job.tubeOffset.abs() - worst + job.nickLen / 2, greaterThan(m6NickTubeLen / 2 - m6NickTubeEdge));
          // A tube centred on any accepted mark holds the whole nick.
          expect(worst + job.nickLen / 2, lessThanOrEqualTo(m6NickTubeLen / 2 - m6NickTubeEdge + 1e-9));
          if (j > 0) expect(job.poles.$1, greaterThan(d.jobs[j - 1].poles.$2));
          spans.add(job.span);
        }
        expect(m6NickLens[0], greaterThan(m6NickLens[1]));
        expect(m6NickLens[1], greaterThan(m6NickLens[2]));
        cw.add(d.coworkerJob);
        whys.addAll(d.whys);
        seen.add('${d.jobs.map((j) => '${j.span.index}${j.mat.index}${(j.nickT * 100).round()}').join()}|${d.coworkerJob}');
      }
      expect(cw, {0, 1, 2});
      expect(spans, M6NickSpan.values.toSet());
      expect(whys, M6NickWhy.values.toSet());
      expect(seen.length, greaterThan(280));
    });

    test('find: the chalk moves while finding; the material with no mark does nothing; off the nick = a slip and the mark is wiped', () {
      final r = M6NickRun(_deal());
      expect(r.startRepair(), isNull, reason: 'no mark: nothing');
      expect(r.slips, 0);
      expect(r.chalk(0.3), isTrue);
      expect(r.chalk(0.32), isTrue, reason: 'again = move it');
      expect(r.mark, 0.32);
      expect(r.startRepair(), Mk.wrongSpot);
      expect(r.mark, isNull);
      expect(r.stage, M6NickStage.find);
      expect(r.slips, 1);
      r.chalk(0.5 + 0.02 / 2 + m6NickMarkSlack - 0.001);
      expect(r.markOnNick, isTrue, reason: 'a little past the end still counts');
      r.chalk(0.5 + 0.02 / 2 + m6NickMarkSlack + 0.002);
      expect(r.markOnNick, isFalse);
      r.chalk(0.505);
      expect(r.startRepair(), isNull);
      expect(r.stage, M6NickStage.seal);
      expect(r.chalk(0.2), isFalse, reason: 'no chalk once the repair began');
    });

    test('tape: every part of the nick under a turn; part open at শেষ = a slip, add turns, শেষ again', () {
      final r = M6NickRun(_deal());
      r.chalk(0.5);
      r.startRepair();
      r.wrap(0.495);
      expect(r.covered, isFalse);
      expect(r.finish(), Mk.uncovered);
      expect(r.stage, M6NickStage.seal, reason: 'add turns');
      expect(r.slips, 1);
      r.wrap(0.505);
      expect(r.covered, isTrue);
      expect(r.finish(), isNull);
      expect(r.stage, M6NickStage.done);
      expect(r.wrap(0.6), isFalse, reason: 'done: no more turns');
    });

    test('tube: it goes on beside the mark; shrunk off-centre = a slip and a new tube on the other side; slid over the nick and shrunk → শেষ', () {
      final r = M6NickRun(_deal(mats: const [M6NickMat.tube, M6NickMat.tape, M6NickMat.tape]));
      r.chalk(0.5);
      expect(r.startRepair(), isNull);
      expect(r.tubeT, closeTo(0.54, 1e-9));
      expect(r.wrap(0.5), isFalse, reason: 'no tape on a tube job');
      expect(r.finish(), Mk.uncovered, reason: 'not shrunk: open');
      expect(r.shrink(), Mk.tubeOff);
      expect(r.shrunk, isFalse);
      expect(r.tubeT, closeTo(0.46, 1e-9), reason: 'a new tube');
      expect(r.tubesUsed, 2);
      expect(r.slips, 2);
      r.moveTube(0.5 - r.tubeT!);
      expect(r.tubeHoldsNick, isTrue);
      expect(r.shrink(), isNull);
      expect(r.shrunk, isTrue);
      r.moveTube(0.2);
      expect(r.tubeT, closeTo(0.5, 1e-9), reason: 'a shrunk tube does not move');
      expect(r.finish(), isNull);
      // The sealing length: the ends do not seal.
      final s = M6NickRun(_deal(mats: const [M6NickMat.tube, M6NickMat.tape, M6NickMat.tape]))..chalk(0.5);
      s.startRepair();
      s.moveTube(0.5 + m6NickTubeLen / 2 - m6NickTubeEdge - 0.01 - 0.0001 - s.tubeT!);
      expect(s.tubeHoldsNick, isTrue);
      s.moveTube(0.002);
      expect(s.tubeHoldsNick, isFalse);
    });

    test('three jobs → complete and passed with the "caught" lines; a slip drops the matching line; percent 100 − 15 × slips', () {
      final r = M6NickRun(_deal());
      for (var j = 0; j < 3; j++) {
        expect(r.job, j);
        _sealRight(r);
      }
      expect(r.complete, isTrue);
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.caught, containsAll([L.caughtFind, L.caughtSeal]));
      final s = M6NickRun(_deal());
      s.chalk(0.2);
      s.startRepair();
      for (var j = 0; j < 3; j++) {
        _sealRight(s);
      }
      expect(s.percent, 85);
      expect(s.passed, isTrue);
      expect(s.caught, isNot(contains(L.caughtFind)));
      expect(s.caught, contains(L.caughtSeal));
    });

    test('the coworker: his job only, before the repair begins; listening = deadly (bare hands)', () {
      final r = M6NickRun(_deal(cw: 1));
      expect(r.coworkerFits, isFalse);
      _sealRight(r);
      expect(r.coworkerFits, isTrue);
      r.chalk(0.5);
      r.startRepair();
      expect(r.coworkerFits, isFalse, reason: 'the repair began');
      final m = r.listen();
      expect(m, Mk.bareHands);
      expect(m.deadly, isTrue);
      expect(r.ended, isTrue);
      expect(r.passed, isFalse);
    });

    test('content: English digits, জল not পানি, nukta letters as base + nukta, mistakes and art, the docket', () {
      final all = <String>[
        ...L.newGuideLines,
        ...L.newRivalLines,
        ...L.allWhyRight,
        ...L.myths,
        ...L.whyQ.values,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.docket,
        L.patrol(12, 13),
        L.heat,
        L.done,
        L.zoomOut,
        L.zoomOutLabel,
        for (final m in M6NickMat.values) L.mat(m),
        L.caughtFind,
        L.caughtSeal,
        L.caughtCall,
        L.title,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect([0x09DC, 0x09DD, 0x09DF].any((c) => l.contains(String.fromCharCode(c))), isFalse, reason: 'precomposed nukta letter in: $l');
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp(r'(^|\s)(অন|অফ)($|\s|।)').hasMatch(l), isFalse, reason: l);
      }
      expect(L.docket, contains('শাটডাউন'));
      expect(L.docket, contains('PTW'));
      expect(L.myths.any((m) => m.contains('জল')) || L.allWhyRight.any((m) => m.contains('জল')), isTrue);
      expect(Mk.all.where((m) => m.deadly).toList(), [Mk.bareHands]);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.6/m6_abc_nick_seal/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
      }
      const dir = 'assets/game/art/m6_abc_nick_seal/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory('assets/game/art/m6_abc_nick_seal').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6NickSealPacks.keys, ['do_6_6_b']);
    });

    test('the deadly card quotes lesson 6.6 myth 1 (normalised to base + nukta)', () {
      String norm(String s) => s
          .replaceAll(String.fromCharCode(0x09DF), String.fromCharCodes([0x09AF, 0x09BC]))
          .replaceAll(String.fromCharCode(0x09DC), String.fromCharCodes([0x09A1, 0x09BC]))
          .replaceAll(String.fromCharCode(0x09DD), String.fromCharCodes([0x09A2, 0x09BC]));
      final lesson = norm(File('tool/all_training_chapters_bn.json').readAsStringSync());
      expect(lesson.contains(norm('অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে, যা মারাত্মক শক দেওয়ার জন্য যথেষ্ট')), isTrue);
      expect(Mk.bareHands.textBn, contains('অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে, যা মারাত্মক শক দেওয়ার জন্য যথেষ্ট'));
      expect(Mk.bareHands.textBn, startsWith('মারাত্মক ভুল এবং বিপজ্জনক!'));
      expect(lesson.contains(norm('এটি লাইভ লাইন কাজের জন্য ডিজাইন করা হয়নি')), isTrue);
      expect(norm(Mk.bareHands.textBn), contains(norm('লাইভ লাইন কাজের জন্য ডিজাইন করা হয়নি')));
      expect(lesson.contains(norm('জল ঢুকে ফল্ট হতে পারে')), isTrue);
      expect(lesson.contains(norm('ওয়াটারপ্রুফ ইনসুলেটিং টেপ বা হিট-স্রিঙ্ক টিউব')), isTrue);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6NickWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('choice', [...L.coworker.right, ...L.coworker.wrong]);
      expectLibrary('choice', L.coworker.right, L.coworker.wrong, minRight: 3);
      expect(L.coworker.asks, contains('কী করবেন?'));
    });

    test('every spoken line is listed: his push; the guide lines, the why-questions, his asks, the mistake texts', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull, reason: 'his exit is recorded');
      expect(L.newRivalLines, [L.coworker.line]);
      expect(L.coworker.line, 'এবি কেবিল তো ইনসুলেটেড — গ্লাভস খুলে খালি হাতে পেঁচাও, তাড়াতাড়ি হবে।');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, ...L.tapWhy, ...L.whyQ.values, ...L.coworker.asks]));
      expect(L.newGuideLines, containsAll([L.callHeld, L.allSet, L.quick, L.fail, L.deadlyWord, L.nearMissWord]));
      expect(L.newGuideLines, containsAll([for (final m in Mk.all) m.textBn]));
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_abc_nick_seal: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the gesture hands never look at the nick or the decoys, and show the real touch', () {
      final geo = M6NickGeo.forScene(780, 0);
      Offset layerOf(M6NickView v, double t) => v.toLayer(geo.cable(t), geo);
      String spec(HintSpec? h) => h == null ? 'none' : '${h.kind} ${h.at} ${h.toward} ${h.options}';
      final a = M6NickRun(_deal());
      final b = M6NickRun(M6NickDeal(
        jobs: [
          M6NickJob(span: M6NickSpan.plot, poles: (3, 4), nickT: 0.21, nickLen: 0.03, nickCore: 0, decoys: const [M6NickMark(M6NickDecoy.twig, 0.8, 1)], mat: M6NickMat.tape, tubeOffset: 0.04),
          _job(),
          _job(),
        ],
        coworkerJob: 0,
        whys: const [M6NickWhy.material, M6NickWhy.cover, M6NickWhy.patrol],
      ));
      for (final v in [M6NickView.whole(geo), const M6NickView(3, Offset(150, 360)).clamped(geo)]) {
        for (var n = 0; n < 12; n++) {
          final ha = m6NickHint(n: n, run: a, view: v, geo: geo, layerOf: (t) => layerOf(v, t));
          final hb = m6NickHint(n: n, run: b, view: v, geo: geo, layerOf: (t) => layerOf(v, t));
          expect(spec(ha), spec(hb), reason: 'z ${v.z} n $n: the same hand whatever the nick');
          if (!v.detail) expect(ha!.kind, n.isEven ? HintKind.sweep : HintKind.tap);
        }
      }
      // Tape: the arc is on the player's own mark.
      final r = M6NickRun(_deal())..chalk(0.45);
      expect(r.startRepair(), Mk.wrongSpot, reason: '0.45 is off the nick at 0.5');
      r.chalk(0.506);
      r.startRepair();
      const v = M6NickView(3, Offset(180, 360));
      for (var n = 0; n < 4; n++) {
        final h = m6NickHint(n: n, run: r, view: v, geo: geo, layerOf: (t) => layerOf(v, t))!;
        expect(h.kind, HintKind.swipe);
        expect(h.at.dx, closeTo(layerOf(v, 0.506).dx, 0.01));
        expect(h.toward.dx, 0, reason: 'across the bundle');
      }
      // Tube: a nudge both ways, then the heat; none once shrunk ('শেষ' has no hand).
      final tb = M6NickRun(_deal(mats: const [M6NickMat.tube, M6NickMat.tape, M6NickMat.tape]))..chalk(0.5);
      tb.startRepair();
      const heat = HintSpec.hold(Offset(1, 1));
      final kinds = [for (var n = 0; n < 3; n++) m6NickHint(n: n, run: tb, view: v, geo: geo, layerOf: (t) => layerOf(v, t), heat: () => heat)];
      expect(kinds[0]!.kind, HintKind.drag);
      expect(kinds[1]!.kind, HintKind.drag);
      expect(kinds[0]!.toward.dx, -kinds[1]!.toward.dx);
      expect(kinds[0]!.travel, lessThanOrEqualTo(HintSpec.maxDragTravel));
      expect(kinds[2], heat);
      tb.moveTube(0.5 - tb.tubeT!);
      tb.shrink();
      expect(m6NickHint(n: 0, run: tb, view: v, geo: geo, layerOf: (t) => layerOf(v, t), heat: () => heat), isNull);
    });

    test('the view: zoom stays 1–3, the view stays on the world; the bundle under a layer point', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M6NickGeo.forScene(h, 0);
        final w = M6NickView.whole(g);
        expect(w.toLayer(g.cable(0.5), g), g.cable(0.5));
        final z = const M6NickView(9, Offset(-50, -50)).clamped(g);
        expect(z.z, m6NickMaxZoom);
        expect(z.toWorld(Offset.zero, g).dx, greaterThanOrEqualTo(-1e-9));
        expect(z.toWorld(Offset.zero, g).dy, greaterThanOrEqualTo(-1e-9));
        expect(const M6NickView(0.2, Offset(180, 300)).clamped(g).z, 1);
        // The bundle sits between the header and the tray at 1×.
        for (final t in [0.0, 0.5, 1.0]) {
          expect(g.cable(t).dy, inInclusiveRange(150, h - 140), reason: 'h $h t $t');
        }
        expect(g.tAt(g.cable(0.37).dx), closeTo(0.37, 1e-9));
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

    testWidgets('the guide comes first: a tap does not skip him; then the dockets and the material', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final d = m6NickDeal(math.Random(3));
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6NickSealPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.text(L.docket), findsOneWidget);
      expect(find.text(L.patrol(d.jobs[0].poles.$1, d.jobs[0].poles.$2)), findsOneWidget);
      expect(_label(L.mat(d.jobs[0].mat)), findsOneWidget);
      expect(_label(L.done), findsNothing, reason: 'no শেষ before the repair begins');
      expect(_label(L.heat), findsNothing);
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
      expect(lines.every((l) => l.contains(L.askFind)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('a clean play: zoom, chalk, the coworker refused on his job, tape and tube, three reasons → pass', (t) async {
      const seed = 11;
      final d = m6NickDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var j = 0; j < 3; j++) {
        await _cleanJob(t, d, j);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['6.6/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['6.6/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtCall), findsOneWidget);
      expect(find.text(L.caughtFind), findsOneWidget);
      expect(find.text(L.caughtSeal), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('at 1× the nick cannot be chalked: a double-tap zooms; the material on a decoy = the slip card, the mark wiped', (t) async {
      final seed = _seedWhere((d) => d.coworkerJob != 0);
      final d = m6NickDeal(math.Random(seed));
      final c = await _open(t, seed);
      final r = M6NickSealProbe.run!;
      await _doubleTap(t, _at(t, d.jobs[0].nickT));
      expect(r.mark, isNull, reason: 'the first double-tap only zooms');
      expect(M6NickSealProbe.view!.z, closeTo(m6NickMaxZoom, 0.01));
      await _chalk(t, d.jobs[0].decoys.first.t);
      await _material(t, d.jobs[0].mat);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.wrongSpot.textBn), findsOneWidget);
      expect(r.mark, isNull);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.wrongSpot.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _seedWhere((d) => d.coworkerJob != 0);
      final d = m6NickDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _chalk(t, d.jobs[0].decoys[i % d.jobs[0].decoys.length].t);
        await _material(t, d.jobs[0].mat);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('tape: শেষ with part of the nick open — the drizzle, then the slip card; more turns, শেষ → the reason', (t) async {
      final seed = _seedWhere((d) => d.coworkerJob != 0 && d.jobs[0].mat == M6NickMat.tape);
      final d = m6NickDeal(math.Random(seed));
      final job = d.jobs[0];
      final c = await _open(t, seed);
      await _chalk(t, job.nickT);
      await _material(t, job.mat);
      await _wrap(t, job.nickT - job.nickLen / 2 - 0.006, job.nickT - 0.002);
      final r = M6NickSealProbe.run!;
      expect(r.covered, isFalse);
      await t.tap(_label(L.done));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the drizzle first');
      await _pump(t, 1500);
      expect(find.text(Mk.uncovered.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _wrap(t, job.nickT - 0.004, job.nickT + job.nickLen / 2 + 0.008);
      expect(r.covered, isTrue);
      await _done(t);
      await _pickRight(t, L.whyRight[d.whys[0]]!);
      await _pump(t, 1500);
      expect(r.job, 1);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.uncovered.key);
      await _close(t, c);
    });

    testWidgets('tube: shrunk where it went on (off-centre) = the slip card; a new tube slid over and shrunk → no slip', (t) async {
      final seed = _seedWhere((d) => d.coworkerJob != 0 && d.jobs[0].mat == M6NickMat.tube);
      final d = m6NickDeal(math.Random(seed));
      final job = d.jobs[0];
      final c = await _open(t, seed);
      await _chalk(t, job.nickT);
      await _material(t, job.mat);
      expect(_label(L.heat), findsOneWidget);
      expect(_label(L.done), findsOneWidget);
      // Let go early: nothing.
      final g = await t.startGesture(t.getCenter(_label(L.heat)));
      await _pump(t, 500);
      await g.up();
      await _pump(t, 300);
      final r = M6NickSealProbe.run!;
      expect(r.shrunk, isFalse);
      expect(r.slips, 0);
      await _heat(t);
      expect(find.text(Mk.tubeOff.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(r.tubesUsed, 2);
      await _slideTube(t, job.nickT);
      await _heat(t);
      expect(r.shrunk, isTrue);
      expect(find.byType(MistakeCard), findsNothing);
      await _done(t);
      await _pickRight(t, L.whyRight[d.whys[0]]!);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.tubeOff.key);
      await _close(t, c);
    });

    testWidgets('the material waits for the coworker on his job; listening = deadly: freeze, then the card', (t) async {
      final seed = _seedWhere((d) => d.coworkerJob == 0);
      final d = m6NickDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _chalk(t, d.jobs[0].nickT);
      await _pump(t, 4000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he comes at the first touch of the material, not before');
      await _material(t, d.jobs[0].mat);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in at the touch');
      expect(M6NickSealProbe.run!.stage, M6NickStage.find, reason: 'the touch waited for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.bareHands.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the ◆ on the table and its reason deck: the scene takes no touch', (t) async {
      final seed = _seedWhere((d) => d.coworkerJob != 0 && d.jobs[0].mat == M6NickMat.tape);
      final d = m6NickDeal(math.Random(seed));
      final job = d.jobs[0];
      final c = await _open(t, seed);
      await _chalk(t, job.nickT);
      await _material(t, job.mat);
      await _wrap(t, job.nickT - job.nickLen / 2 - 0.008, job.nickT + job.nickLen / 2 + 0.008);
      await _done(t);
      await waitChoiceDeck(t);
      final before = M6NickSealProbe.view!;
      expect(_label(L.zoomOutLabel), findsNothing, reason: 'the tray is away under the deck');
      await _doubleTap(t, _at(t, 0.3));
      expect(M6NickSealProbe.view, before, reason: 'no zoom under the deck');
      expect(find.byType(MistakeCard), findsNothing);
      await _pickRight(t, L.whyRight[d.whys[0]]!);
      await _pump(t, 1500);
      expect(M6NickSealProbe.view!.z, 1, reason: 'the next span from the whole view');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: shows while the span waits, none while the reason deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.coworkerJob != 0 && d.jobs[0].mat == M6NickMat.tape);
      final d = m6NickDeal(math.Random(seed));
      final job = d.jobs[0];
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the span');
      await _chalk(t, job.nickT);
      await _material(t, job.mat);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the tape');
      await _wrap(t, job.nickT - job.nickLen / 2 - 0.008, job.nickT + job.nickLen / 2 + 0.008);
      await _done(t);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own hand');
      await _close(t, c);
    });
  });
}
