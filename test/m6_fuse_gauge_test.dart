// Lesson 6.3 (ফিউজ: নীরব প্রহরী), কাজ 1 "মেপে তবেই বাঁধো": the rules (a
// wire in a plate slot bounces / rattles / seats snug and only snug writes
// the chalk; the micrometer reads mm; a reel tied unmeasured or of the wrong
// diameter is a slip; an ACSR strand or GI wire tied in a fuse's place is
// deadly; listening to the ACSR push is deadly, to 'মোটাটাই বাঁধো' a slip),
// the deal, the libraries, the coworker's lines, the tap areas, and the
// level in the shell: the guide first, a full clean play (a reason pick each
// job, the coworker refused), a slip card that keeps the job, three slips,
// the deadly freeze (own pick; his push), the next control waits for him on a
// fast play, the praise window takes no touch, and the gesture hand shows how
// (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m6_fuse_gauge.dart';
import 'package:slm_flutter/features/game/m6_fuse_gauge_world.dart';
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
  rungId: '6.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6FuseGaugePacks['do_6_3_a']!;
typedef L = M6FuseGaugeLines;
typedef Mk = M6FuseGaugeMistakes;

/// The new art is not in pubspec's bundle in tests until the director wires
/// it: tests read it from disk when the bundle does not have it.
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
M6FuseGeo get _geo => M6FuseGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _drag(WidgetTester t, Offset from, Offset to) async {
  await t.dragFrom(from * _k, (to - from) * _k);
  await _pump(t, 400);
}

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Offset _src(M6FuseDeal d, int s) => _geo.source(s, acsrLeft: d.acsrLeft);

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6FuseGaugePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6FuseDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m6FuseDeal(math.Random(s))));

/// The coworker comes (the first wire taken up on his job): refuse him.
Future<void> _refuse(WidgetTester t, M6FusePush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// Measures the job's right reel (a decoy first on plate jobs: it does not
/// seat in the right slot), refusing the coworker if he comes on it.
Future<void> _measure(WidgetTester t, M6FuseDeal d, int i, {bool refuse = true}) async {
  final j = d.jobs[i];
  final g = _geo;
  final r = j.reels.indexOf(j.rightMm);
  final him = d.coworkerJob == i && refuse ? d.push : null;
  if (j.tool == M6FuseTool.plate) {
    final slot = m6PlateMm.indexOf(j.rightMm);
    final decoy = (r + 1) % 4;
    await _drag(t, g.reel(decoy), g.slot(slot));
    if (him != null) {
      await _refuse(t, him);
      await _drag(t, g.reel(decoy), g.slot(slot));
    }
    await _drag(t, g.reel(r), g.slot(slot));
  } else {
    await _drag(t, g.reel(r), g.jawsHit.center);
    if (him != null) {
      await _refuse(t, him);
      await _drag(t, g.reel(r), g.jawsHit.center);
    }
    await _drag(t, g.thimbleHit.center, g.thimbleHit.center.translate(0, -60));
  }
}

/// The right reel to the top screw, then a short drag down to the bottom one.
Future<void> _fit(WidgetTester t, M6FuseDeal d, int i, {int? src}) async {
  final j = d.jobs[i];
  final g = _geo;
  final s = src ?? j.reels.indexOf(j.rightMm);
  await _drag(t, _src(d, s), g.topScrew);
  await _drag(t, g.topScrew, g.bottomScrew);
}

List<String> _whyRight(M6FuseJob j) => j.tool == M6FuseTool.micrometer ? L.whyMicRight(j.amps) : L.whyRule;

/// One job played right (the coworker refused if he is dealt on it).
Future<void> _playJob(WidgetTester t, M6FuseDeal d, int i) async {
  await _measure(t, d, i);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i measured');
  await _fit(t, d, i);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i tied');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await _pump(t, 700);
  final j = d.jobs[i];
  if (j.tool == M6FuseTool.micrometer) {
    // The docket and the progress show this job's amps: no card may name them.
    expect(find.text(L.carrier(j.amps)), findsWidgets);
    for (final o in t.widget<ChoiceDeck>(find.byType(ChoiceDeck)).options) {
      expect(o.textBn.contains('${j.amps} A'), isFalse, reason: o.textBn);
      expect(o.textBn.contains(m6Mm(j.rightMm)), isFalse, reason: o.textBn);
    }
  }
  await _pickRight(t, _whyRight(j));
  await _pump(t, 2500);
}

M6FuseJob _job({int amps = 32, M6FuseTool tool = M6FuseTool.plate, List<int>? reels}) =>
    M6FuseJob(place: M6FusePlace.ruralDb, amps: amps, tool: tool, reels: reels ?? m6DealReels(m6RightMm(amps), math.Random(1)));

M6FuseRun _runOf(M6FuseJob first, {M6FusePush push = M6FusePush.thick, int at = 1}) => M6FuseRun(M6FuseDeal(
      jobs: [first, _job(amps: 63), _job(amps: 100, tool: M6FuseTool.micrometer)],
      coworkerJob: at,
      push: push,
      acsrLeft: true,
    ));

void main() {
  group('rules', () {
    test('deals: three places, three ratings from the lesson table, plate · plate · micrometer; trays bracket the answer; plays differ', () {
      final seen = <String>{};
      final pushes = <M6FusePush>{};
      final at = <int>{};
      var left = 0;
      for (var s = 0; s < 160; s++) {
        final d = m6FuseDeal(math.Random(s));
        expect(d.jobs.map((j) => j.place).toSet(), M6FusePlace.values.toSet());
        expect(d.jobs.map((j) => j.amps).toSet(), hasLength(3));
        expect([for (final j in d.jobs) j.tool], [M6FuseTool.plate, M6FuseTool.plate, M6FuseTool.micrometer]);
        for (final j in d.jobs) {
          expect(m6FuseAmps, contains(j.amps));
          expect(m6PlaceAmps[j.place], contains(j.amps));
          expect(j.reels, hasLength(4));
          expect(j.reels.toSet(), hasLength(4));
          expect(j.reels, contains(j.rightMm));
          for (final r in j.reels) {
            expect(m6PlateMm, contains(r));
          }
          final i = m6PlateMm.indexOf(j.rightMm);
          if (i + 1 < m6PlateMm.length) expect(j.reels, contains(m6PlateMm[i + 1]), reason: 'a size thicker');
          if (i > 0) expect(j.reels, contains(m6PlateMm[i - 1]), reason: 'a size thinner');
          expect(j.reels.any((r) => (m6PlateMm.indexOf(r) - i).abs() >= 2), isTrue, reason: 'one far off');
        }
        if (d.push == M6FusePush.thick) expect(d.coworkerJob, inInclusiveRange(1, 2), reason: '"মোটাটাই বাঁধো" on job 2 or 3');
        pushes.add(d.push);
        at.add(d.coworkerJob);
        if (d.acsrLeft) left++;
        seen.add('${d.jobs.map((j) => '${j.place.index}${j.amps}${j.reels.join(',')}').join('|')}|${d.coworkerJob}${d.push.name}${d.acsrLeft}');
      }
      expect(seen.length, greaterThan(140));
      expect(pushes, M6FusePush.values.toSet());
      expect(at, {0, 1, 2});
      expect(left, inInclusiveRange(50, 110));
      // The right reel moves around the tray.
      final spots = {for (var s = 0; s < 60; s++) m6FuseDeal(math.Random(s)).jobs.first.let((j) => j.reels.indexOf(j.rightMm))};
      expect(spots, {0, 1, 2, 3});
    });

    test('the plate: too narrow bounces, too wide rattles, snug writes the chalk; ACSR and GI never seat', () {
      final r = _runOf(_job(amps: 32, reels: const [85, 120, 70, 200]));
      expect(r.loaded, isFalse);
      expect(r.probe(0, m6PlateMm.indexOf(70)), M6Fit.narrow);
      expect(r.probe(0, m6PlateMm.indexOf(120)), M6Fit.loose);
      expect(r.chalk, isEmpty, reason: 'no chalk until it seats');
      expect(r.loaded, isTrue);
      expect(r.probe(0, m6PlateMm.indexOf(85)), M6Fit.snug);
      expect(r.chalk, {0: 85});
      expect(r.probe(3, 5), M6Fit.snug);
      expect(r.chalk, {0: 85, 3: 200});
      for (var k = 0; k < m6PlateMm.length; k++) {
        expect(r.probe(m6AcsrSrc, k), M6Fit.narrow, reason: 'an ACSR strand is far thicker than any fuse wire');
        expect(r.probe(m6GiSrc, k), isNot(M6Fit.snug));
      }
      expect(r.chalk.keys, {0, 3});
      expect(r.micLoad(0), isFalse, reason: 'no micrometer on a plate job');
      expect(r.slips, 0, reason: 'measuring is never a slip');
    });

    test('the micrometer job: wire in the jaws, roll the thimble → mm reading and chalk; no slot works', () {
      final r = _runOf(_job(amps: 16, tool: M6FuseTool.micrometer, reels: const [70, 50, 200, 85]));
      expect(r.probe(1, 0), isNull);
      expect(r.micSpin(), isNull, reason: 'nothing in the jaws');
      expect(r.micLoad(1), isTrue);
      expect(r.micReading, isNull);
      expect(r.micSpin(), 50);
      expect(r.micReading, 50);
      expect(r.chalk, {1: 50});
      r.micLoad(m6GiSrc);
      expect(r.micReading, isNull);
      r.micSpin();
      expect(r.chalk, {1: 50}, reason: 'chalk only goes under a reel');
    });

    test('tying: unmeasured = slip; wrong diameter (thicker / thinner) = slip; ACSR / GI = deadly; right = done', () {
      final reels = [85, 120, 70, 200];
      final r = _runOf(_job(amps: 32, reels: reels));
      expect(r.tie(), isNull, reason: 'nothing on the top screw');
      r.anchor(0);
      expect(r.tie(), Mk.unmeasured, reason: 'the right reel, but never measured');
      expect(r.anchored, isNull, reason: 'the wire comes off');
      r
        ..probe(1, m6PlateMm.indexOf(120))
        ..anchor(1);
      expect(r.tie(), Mk.tooThick);
      r
        ..probe(2, m6PlateMm.indexOf(70))
        ..anchor(2);
      expect(r.tie(), Mk.tooThin);
      expect(r.slips, 3);
      expect(r.percent, 55);
      r
        ..probe(0, m6PlateMm.indexOf(85))
        ..anchor(0);
      expect(r.tie(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.fitted, isTrue);
      expect(r.caught, contains(L.caughtJob(32)));
      expect(r.thorough, isFalse);
      for (final (src, m) in [(m6AcsrSrc, Mk.acsr), (m6GiSrc, Mk.gi)]) {
        final d = _runOf(_job())..anchor(src);
        final got = d.tie();
        expect(got, m);
        expect(got!.deadly, isTrue);
        expect(d.ended, isTrue);
        expect(d.slips, 0, reason: 'deadly, not a slip');
      }
    });

    test('a clean play passes with the measured-everything tag; a 4th slip drops below the pass', () {
      final d = m6FuseDeal(math.Random(7));
      final r = M6FuseRun(d);
      for (var i = 0; i < 3; i++) {
        final j = r.job;
        final at = j.reels.indexOf(j.rightMm);
        if (j.tool == M6FuseTool.plate) {
          r.probe(at, m6PlateMm.indexOf(j.rightMm));
        } else {
          r
            ..micLoad(at)
            ..micSpin();
        }
        r.anchor(at);
        expect(r.tie(), isNull);
        expect(r.thorough, isTrue);
        r.next();
      }
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.caught, containsAll([for (final j in d.jobs) L.caughtJob(j.amps)]));
      expect(r.caught, contains(L.caughtMeasured));
      final s = _runOf(_job());
      for (var k = 0; k < 4; k++) {
        s
          ..anchor(0)
          ..tie();
      }
      expect(s.slips, 4);
      expect(s.percent, 40);
    });

    test('the coworker: his gate is the first wire taken up on his job; listening takes the class of his push (B1)', () {
      final r = _runOf(_job());
      expect(r.loaded, isFalse);
      r.take(2);
      expect(r.loaded, isTrue);
      r.next();
      expect(r.loaded, isFalse, reason: 'each job starts fresh');
      expect(Mk.push(M6FusePush.acsr), Mk.acsr);
      expect(Mk.push(M6FusePush.acsr).deadly, isTrue);
      expect(Mk.push(M6FusePush.thick), Mk.thickPush);
      expect(Mk.push(M6FusePush.thick).deadly, isFalse);
      final s = _runOf(_job());
      expect(s.pushSlip(Mk.thickPush), Mk.thickPush);
      expect(s.slips, 1);
      s.failDeadly(Mk.acsr);
      expect(s.ended, isTrue);
    });

    test('English digits only; jol not pani; locked words; every mistake has its picture; the deadly set; keys; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.sceneLabel,
        L.docketHead,
        for (final p in M6FusePlace.values) ...[L.place(p), L.isolation(p)],
        for (final a in m6FuseAmps) ...[L.carrier(a), L.caughtJob(a), ...L.whyMicRight(a), ...L.whyMicWrong(a)],
        for (final f in M6Fit.values) L.fit(f),
        for (var s = 0; s < m6SourceCount; s++) L.source(s),
        for (var k = 0; k < m6PlateMm.length; k++) L.slot(k),
        L.whyQPlate,
        L.whyQMic,
        ...L.whyRule,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6FusePush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.caughtMeasured,
        ...L.newGuideLines,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('গ্লোভস'), isFalse, reason: l);
      }
      // SWG is named only where the live lesson does (~25, ~14; ruling X6).
      final swg = all.where((l) => l.contains('SWG')).toSet();
      expect(swg, {L.caughtJob(16), L.caughtJob(100)});
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.acsr, Mk.gi});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.3/m6_fuse_gauge/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 5), reason: m.key);
      }
      final used = {for (final m in Mk.all) m.art.split('/').last};
      final files = Directory('assets/game/art/m6_fuse_gauge').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used; no .gitkeep left');
      expect(m6FuseGaugePacks.keys, ['do_6_3_a']);
      // The live IS 9926 table (lesson 6.3 point 4).
      expect({for (final a in m6FuseAmps) a: m6RightMm(a)}, {16: 50, 32: 85, 63: 150, 100: 200});
    });

    test('libraries: same length, big enough, the right card fits the job, never a rule marked wrong', () {
      expectSameLength('why rule', [...L.whyRule, ...L.myths]);
      expectLibrary('why rule', L.whyRule, L.myths);
      expect(L.myths.toSet().intersection(L.whyRule.toSet()), isEmpty);
      for (final a in m6FuseAmps) {
        final right = L.whyMicRight(a);
        final wrong = L.whyMicWrong(a);
        expectSameLength('why mic $a', [...right, ...wrong]);
        expectLibrary('why mic $a', right, wrong);
        // No giveaway: the docket shows this job's amps and he just read its
        // size, so no card names either; the right cards are the table's
        // pairs for the other ratings, the wrong ones mismatch those.
        final table = {for (final y in m6FuseAmps) L.micPair(y, m6RightMm(y))};
        expect(right.toSet(), {for (final y in m6FuseAmps) if (y != a) L.micPair(y, m6RightMm(y))});
        for (final x in [...right, ...wrong]) {
          expect(x.contains('$a A'), isFalse, reason: 'docket amps: $x');
          expect(x.contains(L.carrier(a)), isFalse, reason: x);
          expect(x.contains(m6Mm(m6RightMm(a))), isFalse, reason: 'the size he measured: $x');
        }
        for (final x in wrong) {
          expect(table.contains(x), isFalse, reason: 'never a table pair marked wrong: $x');
        }
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (var k = 0; k < 10; k++) {
        final deal = dealChoices(L.whyRule, L.myths, math.Random(k));
        expect(deal.where((o) => o.correct), hasLength(1));
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: his exit is recorded; his two new pushes are listed for recording; the guide\'s new lines are listed', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines.toSet(), {for (final p in M6FusePush.values) L.coworker(p).line});
      expect(L.newRivalLines, [
        'মাপামাপি ছাড়ো! ACSR থেকে একটা অ্যালুমিনিয়াম সুতো খুলে বেঁধে দাও — সাময়িক!',
        'গেজ-টেজ লাগবে না, চোখেই বোঝা যায় — মোটাটাই বাঁধো, বারবার উড়বে না!',
      ]);
      expect(L.newGuideLines, containsAll([L.intro, L.askPlate, L.askMic, L.askTie, L.whyQPlate, L.whyQMic]));
      for (final l in L.newRivalLines) {
        // Not recorded yet (the director records them with tool/rival_clip.py
        // after the owner's wording): until then silent, caption held.
        debugPrint('RIVAL m6_fuse_gauge: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, below the header, clear of the guide and his bubble', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6FuseGeo.forScene(h, 0);
        for (final acsrLeft in [true, false]) {
          final rects = <String, Rect>{
            for (var s = 0; s < m6SourceCount; s++) 'src$s': g.sourceHit(s, acsrLeft: acsrLeft),
            for (var k = 0; k < m6PlateMm.length; k++) 'slot$k': g.slotHit(k).inflate(3),
            'top': g.topScrewHit,
            'bottom': g.bottomScrewHit,
          };
          final mic = <String, Rect>{'jaws': g.jawsHit, 'thimble': g.thimbleHit};
          final guide = Rect.fromLTRB(253, h - 116, 360, h);
          final bubble = Rect.fromLTRB(147, h - 186, 360, h - 116);
          for (final e in {...rects, ...mic}.entries) {
            final r = e.value;
            expect(r.left, greaterThanOrEqualTo(0), reason: '${e.key} h $h');
            expect(r.right, lessThanOrEqualTo(360), reason: '${e.key} h $h');
            expect(r.top, greaterThan(125), reason: '${e.key} below the header, h $h');
            expect(r.overlaps(guide), isFalse, reason: '${e.key} under the guide, h $h');
            expect(r.overlaps(bubble), isFalse, reason: '${e.key} under his bubble, h $h');
            expect(r.overlaps(M6FuseGeo.docket), isFalse, reason: '${e.key} under the docket, h $h');
          }
          for (final set in [rects, {...mic, for (final e in rects.entries) if (!e.key.startsWith('slot')) e.key: e.value}]) {
            final l = set.entries.toList();
            for (var i = 0; i < l.length; i++) {
              for (var j = i + 1; j < l.length; j++) {
                expect(l[i].value.overlaps(l[j].value), isFalse, reason: 'h $h: ${l[i].key}/${l[j].key}');
              }
            }
          }
          expect(g.carrier.bottom, lessThan(h - 186), reason: 'the carrier above the bubble');
        }
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket, the wires and the carrier', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6FuseGaugePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      final d = m6FuseDeal(math.Random(3));
      expect(find.text(L.docketHead), findsOneWidget);
      expect(find.text(L.place(d.jobs.first.place)), findsOneWidget);
      expect(find.text(L.isolation(d.jobs.first.place)), findsOneWidget, reason: 'every carrier comes off a dead board (X4)');
      expect(find.text(L.carrier(d.jobs.first.amps)), findsOneWidget);
      expect(find.textContaining('মিমি'), findsNothing, reason: 'the docket never gives the size');
      for (var s = 0; s < m6SourceCount; s++) {
        expect(_label(L.source(s)), findsOneWidget);
      }
      for (var k = 0; k < m6PlateMm.length; k++) {
        expect(_label(L.slot(k)), findsOneWidget);
      }
      expect(_label(L.topScrew), findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.askPlate)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play with the deadly-class push (refused), one with the slip-class push.
    final flowSeeds = [
      _seedWhere((d) => d.push == M6FusePush.acsr && d.coworkerJob == 2),
      _seedWhere((d) => d.push == M6FusePush.thick && d.coworkerJob == 1),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three carriers measured, tied, reasons; he is refused → pass', (t) async {
        final d = m6FuseDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playJob(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.3/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.3/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtMeasured), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final aloneFirst = _seedWhere((d) => d.coworkerJob != 0);
    testWidgets('a reel tied unmeasured is a slip: its card, then the same job goes on', (t) async {
      final d = m6FuseDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      final j = d.jobs.first;
      await _fit(t, d, 0);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.unmeasured.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(L.carrier(j.amps)), findsOneWidget, reason: 'the same job');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.unmeasured.key);
      // Measured now, the same reel ties right.
      await _measure(t, d, 0);
      await _fit(t, d, 0);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a measured wrong reel tied is a slip (thicker or thinner)', (t) async {
      final d = m6FuseDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      final j = d.jobs.first;
      final wrong = [for (var i = 0; i < 4; i++) if (j.reels[i] != j.rightMm) i].first;
      await _drag(t, _geo.reel(wrong), _geo.slot(m6PlateMm.indexOf(j.reels[wrong])));
      await _fit(t, d, 0, src: wrong);
      final want = j.reels[wrong] > j.rightMm ? Mk.tooThick : Mk.tooThin;
      expect(find.text(want.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, want.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final d = m6FuseDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      for (var i = 0; i < 3; i++) {
        await _fit(t, d, 0);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('an ACSR strand tied in the carrier: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final d = m6FuseDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      await _fit(t, d, 0, src: m6AcsrSrc);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      // The fire is the transformer burning (lesson 6.3 point 5), not the bench.
      final fire = t.widget<CustomPaint>(find.descendant(of: find.byKey(const ValueKey('fire')), matching: find.byType(CustomPaint)).first);
      expect((fire.painter! as M6FuseFirePainter).at, M6FuseGeo.dtrTank.center);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.acsr.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('GI binding wire tied: deadly freeze', (t) async {
      final d = m6FuseDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      await _fit(t, d, 0, src: m6GiSrc);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.gi.key);
      await _close(t, c);
    });

    final acsrFirst = _seedWhere((d) => d.push == M6FusePush.acsr && d.coworkerJob == 0);
    testWidgets('listening to the ACSR push = deadly: freeze, then the card', (t) async {
      final d = m6FuseDeal(math.Random(acsrFirst));
      final c = await _open(t, acsrFirst);
      final j = d.jobs.first;
      await _drag(t, _geo.reel(0), _geo.slot(m6PlateMm.indexOf(j.rightMm)));
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerAcsr.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.acsr.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final thickSecond = _seedWhere((d) => d.push == M6FusePush.thick && d.coworkerJob == 1);
    testWidgets('listening to "মোটাটাই বাঁধো" = a slip card; the job goes on', (t) async {
      final d = m6FuseDeal(math.Random(thickSecond));
      final c = await _open(t, thickSecond);
      await _playJob(t, d, 0);
      final j = d.jobs[1];
      await _drag(t, _geo.reel(0), _geo.slot(m6PlateMm.indexOf(j.rightMm)));
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerThick.wrong);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.thickPush.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.thickPush.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _measure(t, d, 1, refuse: false);
      await _fit(t, d, 1);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the job goes on to its reason');
      await _close(t, c);
    });

    testWidgets('a fast play: the measuring control waits for the coworker; he cuts in at once', (t) async {
      final d = m6FuseDeal(math.Random(acsrFirst));
      final c = await _open(t, acsrFirst);
      final j = d.jobs.first;
      final r = j.reels.indexOf(j.rightMm);
      // Take up the right reel and push it straight into its slot.
      await t.dragFrom(_geo.reel(r) * _k, (_geo.slot(m6PlateMm.indexOf(j.rightMm)) - _geo.reel(r)) * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerAcsr.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      // The probe that waited did nothing: the reel has no chalk, so tying it is the unmeasured slip.
      await _fit(t, d, 0);
      expect(find.text(Mk.unmeasured.textBn), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final d = m6FuseDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      await _measure(t, d, 0);
      await _fit(t, d, 0);
      // The ◆ wait on the table and the deck is up: the carrier takes nothing.
      await _tapAt(t, _geo.topScrew);
      await _drag(t, _geo.topScrew, _geo.bottomScrew);
      await _tapAt(t, _geo.bottomScrew);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, L.whyRule);
      await _pump(t, 3000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over every wire alike when idle; three taps on nothing show it; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final d = m6FuseDeal(math.Random(aloneFirst));
      final c = await _open(t, aloneFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle');
      expect(scene().debugOptions, hasLength(7), reason: 'six wires and the plate, alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      // A tap on nothing hides it; three taps on nothing (the sky between the
      // docket and the carrier) show it again at once.
      final empty = const Offset(196, 150) * _k;
      await t.tapAt(empty);
      await _pump(t, 4500);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(find.byType(MistakeCard), findsNothing);
      // The reason deck up: the scene's hand stays away (the deck has its own).
      await _measure(t, d, 0);
      await _fit(t, d, 0);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse);
      await _close(t, c);
    });
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
