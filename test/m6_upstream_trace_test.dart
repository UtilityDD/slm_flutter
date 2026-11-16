// Lesson 6.8 (অটো-রিক্লোজার ও সেকশনালাইজার), কাজ 2 "তার ধরে সোর্সের দিকে":
// the rules (the chalk follows the finger only on the wire, takes a fork by
// the drag's direction, rubs out backwards, stops at a dead end, waits at the
// sectionalizer for the coworker; a flag only after the trace — our recloser
// right, the sectionalizer / a fuse / the neighbour's recloser slips; the
// first reply dealt, a second ask answered full, asking again after a full
// reply a slip; climbing on an incomplete reply deadly), the deal (at least
// one incomplete reply a play; the neighbour's recloser nearest the work pole
// and never wired to it), the libraries, the lines listed for recording, and
// the level in the shell: the guide first, a full clean play of both jobs
// (trace by drag, a reason each, the coworker refused at the sectionalizer),
// listening to him, three slips, the deadly freeze, the praise window, and
// the gesture hand.
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
import 'package:slm_flutter/features/game/m6_upstream_trace.dart';
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
  rungId: '6.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6UpstreamTracePacks['do_6_8_b']!;
typedef L = M6UpstreamTraceLines;
typedef Mk = M6UpstreamTraceMistakes;

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
M6UtRun get _live => M6UpstreamTraceProbe.run!;
M6UtGeo get _g => M6UpstreamTraceProbe.geo!;
double get _cam => M6UpstreamTraceProbe.cam!.value;
Offset _screen(Offset world) => (world - Offset(_cam, 0)) * _k;

/// A geometry for the rules (the test screen's scene height).
final _geo = M6UtGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

/// Drags the chalk from its head along [nodes] (poles in order). Stops (and
/// returns false) where the chalk stops following.
Future<bool> _drag(WidgetTester t, List<int> nodes) async {
  final m = _live.map;
  final gesture = await t.startGesture(_screen(_live.head(_g)));
  await t.pump(const Duration(milliseconds: 16));
  var ok = true;
  var from = _live.path.last;
  for (final to in nodes) {
    final a = _g.node(m, from);
    final b = _g.node(m, to);
    final n = math.max(4, ((b - a).distance / 6).ceil());
    for (var i = 1; i <= n; i++) {
      await gesture.moveTo(_screen(M6UtGeo.span(a, b, i / n)));
      await t.pump(const Duration(milliseconds: 16));
    }
    if (_live.path.last != to && !_live.traced) {
      ok = false;
      break;
    }
    from = to;
  }
  await gesture.up();
  await _pump(t, 250);
  return ok;
}

/// The rest of the right trace from where the chalk is now.
List<int> _rest() {
  final path = _live.map.upstreamPath();
  return path.sublist(path.indexOf(_live.path.last) + 1);
}

/// Pans the view (drags on the sky) so world x [x] is near the middle.
Future<void> _lookAt(WidgetTester t, double x) async {
  for (var k = 0; k < 8; k++) {
    final want = (x - 180).clamp(0.0, M6UtGeo.camMax);
    final d = _cam - want;
    if (d.abs() < 4) return;
    final step = d.clamp(-140.0, 140.0);
    final from = Offset(180 - step / 2, _g.height * 0.2) * _k;
    await t.dragFrom(from, Offset(step * _k, 0));
    await _pump(t, 200);
  }
}

Future<void> _tapDevice(WidgetTester t, M6UtDevKind kind) async {
  final m = _live.map;
  final d = m.devices.firstWhere((d) => d.kind == kind);
  final r = _g.deviceRect(m, d);
  await _lookAt(t, r.center.dx);
  await t.tapAt(_screen(r.center));
  await _pump(t, 400);
}

Future<void> _docket(WidgetTester t) async {
  await t.tapAt(M6UtGeo.docket.center * _k);
  await _pump(t, 300);
}

/// PTT held to the end of its ring, then let go.
Future<void> _ptt(WidgetTester t, {int ms = 1200}) async {
  final g = await t.startGesture(t.getCenter(_label(L.pttLabel)));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

/// The boot dragged onto the pole step.
Future<void> _climb(WidgetTester t) async {
  final m = _live.map;
  await _lookAt(t, _g.node(m, m.work).dx - 20);
  final from = _g.bootHome(m);
  final to = _g.step(m);
  final gesture = await t.startGesture(_screen(from));
  for (var i = 1; i <= 10; i++) {
    await gesture.moveTo(_screen(Offset.lerp(from, to, i / 10)!));
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await _pump(t, 400);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6UpstreamTracePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6UtDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m6UtDeal(math.Random(s))));

/// The coworker comes: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// The full trace (the coworker refused where he stops it).
Future<void> _traceAll(WidgetTester t, {required bool him}) async {
  final ok = await _drag(t, _rest());
  if (him) {
    expect(ok, isFalse, reason: 'the chalk waits at the sectionalizer');
    expect(_live.path.last, _live.map.sNode);
    await _refuse(t);
    expect(await _drag(t, _rest()), isTrue, reason: 'after him the chalk goes on');
  } else {
    expect(ok, isTrue);
  }
  expect(_live.traced, isTrue);
}

/// One job played right.
Future<void> _playJob(WidgetTester t, M6UtDeal d, int i) async {
  final j = d.jobs[i];
  await _docket(t);
  await _traceAll(t, him: d.coworkerJob == i);
  await _tapDevice(t, M6UtDevKind.recloser);
  expect(find.byType(MistakeCard), findsNothing);
  expect(_live.flagged, isTrue);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 500);
  await _pickRight(t, L.whyFlag[j.flagWhy]!);
  await _pump(t, 1500);
  await _ptt(t);
  await _pump(t, 1200);
  expect(_live.reply, j.firstReply);
  expect(find.textContaining(L.reply(j.firstReply, j.plates, j.ptw)), findsOneWidget, reason: 'the reply in the radio log');
  if (j.firstReply != M6UtReply.full) {
    await _ptt(t);
    expect(find.byType(MistakeCard), findsNothing);
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
    await _pump(t, 500);
    await _pickRight(t, L.whyWait[j.firstReply]!);
    await _pump(t, 1500);
    expect(_live.reply, M6UtReply.full);
  }
  await _climb(t);
  expect(find.byType(FreezeFrame), findsNothing);
  expect(_live.climbed, isTrue);
  // Ruling X1: the crew's isolation, tester (0 V, ডেড) and earths show.
  expect(find.byKey(ValueKey('crew-$i')), findsOneWidget);
  for (final l in [L.crewOpen, L.crewDead, L.crewEarth]) {
    expect(find.text(l), findsOneWidget, reason: l);
  }
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 500);
  await _pickRight(t, L.whyClimb);
  await _pump(t, 3000);
}

/// A run whose first job's map is [map]; the docket read.
M6UtRun _runOf({M6UtMap? map, M6UtReply reply = M6UtReply.full, bool read = true}) {
  final m = map ?? m6UtBuildMap(mirrored: false, nbrAbove: true, rNearSource: false, junctionAt: 3, decoySpur: true, decoyFuse: true, workFar: true);
  const plates = M6UtPlates(feeder: 2, recloser: 12, nbrFeeder: 5, nbrRecloser: 7, pole: 37);
  final job = M6UtJob(map: m, plates: plates, kind: M6UtJobKind.insulator, firstReply: reply, flagWhy: M6UtWhy.thisRecloser, ptw: 418);
  final r = M6UtRun(M6UtDeal(jobs: [job, job], coworkerJob: 1, nudgeSign: 1));
  if (read) r.readDocket();
  return r;
}

/// Feeds the finger along [nodes] from the chalk's pole (world px, small steps).
M6UtStep _feed(M6UtRun r, List<int> nodes) {
  var last = M6UtStep.none;
  var from = r.path.last;
  for (final to in nodes) {
    final a = _geo.node(r.map, from);
    final b = _geo.node(r.map, to);
    for (var i = 1; i <= 20; i++) {
      final s = r.trace(M6UtGeo.span(a, b, i / 20), _geo);
      if (s != M6UtStep.none) last = s;
      if (s == M6UtStep.held) return s;
    }
    from = to;
  }
  return last;
}

M6UtRun _traced({M6UtReply reply = M6UtReply.full}) {
  final r = _runOf(reply: reply);
  _feed(r, r.map.upstreamPath().skip(1).toList());
  expect(r.traced, isTrue);
  return r;
}

M6UtDevice _dev(M6UtRun r, M6UtDevKind k) => r.map.devices.firstWhere((d) => d.kind == k);

void main() {
  group('rules', () {
    test('X1 crew spots: the line opened between the cut-out and the work pole; earths on both sides of the work pole', () {
      for (final mirrored in [false, true]) {
        for (final far in [false, true]) {
          final m = m6UtBuildMap(mirrored: mirrored, nbrAbove: true, rNearSource: false, junctionAt: 2, decoySpur: false, decoyFuse: false, workFar: far);
          final sp = _geo.crew(m);
          final w = _geo.node(m, m.work).dx;
          final fuse = _geo.node(m, m.fuseNode).dx;
          final away = mirrored ? -1 : 1;
          expect((sp.isolate.dx - fuse) * away, greaterThan(0), reason: 'past the cut-out');
          expect((w - sp.isolate.dx) * away, greaterThan(0), reason: 'before the work pole');
          expect((w - sp.earthA.dx) * away, greaterThan(0), reason: 'one earth on the source side');
          expect((sp.earthB.dx - w) * away, greaterThan(0), reason: 'one on the far side');
          expect(sp.testerFoot.dy, lessThanOrEqualTo(_geo.groundY));
        }
      }
    });

    test('deals: two jobs, mirrored apart; at least one incomplete reply; the neighbour never wired, his recloser nearest; plays differ', () {
      final seen = <String>{};
      final replies = <M6UtReply>{};
      final whys = <M6UtWhy>{};
      final cw = <int>{};
      final sets = <String, Set<bool>>{};
      for (var s = 0; s < 150; s++) {
        final d = m6UtDeal(math.Random(s));
        expect(d.jobs, hasLength(kM6UtJobs));
        expect(d.jobs.any((j) => j.firstReply != M6UtReply.full), isTrue, reason: 'seed $s: one incomplete reply a play');
        expect(d.jobs[0].map.mirrored, isNot(d.jobs[1].map.mirrored));
        for (final j in d.jobs) {
          final m = j.map;
          final p = j.plates;
          expect({p.feeder, p.nbrFeeder}, hasLength(2));
          expect({p.recloser, p.nbrRecloser}, hasLength(2));
          final path = m.upstreamPath();
          expect(path.first, m.work);
          expect(path.last, m.source);
          // From the work pole: the fuse, the sectionalizer, our recloser, the source.
          final at = [m.fuseNode, m.sNode, m.rNode, m.source].map(path.indexOf).toList();
          expect(at.every((i) => i > 0), isTrue, reason: '$at');
          expect([...at]..sort(), at, reason: 'upstream order: fuse, sectionalizer, recloser');
          expect(path.where((n) => m.nodes[n].feeder == 1), isEmpty, reason: 'the neighbour feeder is not wired to ours');
          for (final (a, b) in m.edges) {
            expect(m.nodes[a].feeder, m.nodes[b].feeder);
          }
          final wx = m.nodes[m.work].x;
          expect((m.nodes[m.nbrRNode].x - wx).abs(), lessThan((m.nodes[m.rNode].x - wx).abs()), reason: 'his recloser is the nearer one');
          replies.add(j.firstReply);
          whys.add(j.flagWhy);
          for (final (k, v) in [('near', m.rNearSource), ('spur', m.decoySpur), ('fuse', m.decoySpur && m.decoyFuse), ('far', m.workFar), ('above', m.nbrAbove), ('j3', m.junctionAt == 3)]) {
            (sets[k] ??= {}).add(v);
          }
        }
        cw.add(d.coworkerJob);
        final key = [for (final j in d.jobs) '${j.map.mirrored}${j.map.rNearSource}${j.map.junctionAt}${j.map.decoySpur}${j.map.decoyFuse}${j.map.workFar}${j.map.nbrAbove}${j.firstReply.index}${j.plates.pole}'].join('|');
        seen.add('$key/${d.coworkerJob}');
      }
      expect(seen.length, greaterThan(140));
      expect(replies, M6UtReply.values.toSet());
      expect(whys, {M6UtWhy.thisRecloser, M6UtWhy.notSectionalizer});
      expect(cw, {0, 1});
      for (final e in sets.entries) {
        expect(e.value, {true, false}, reason: e.key);
      }
    });

    test('the trace: nothing before the docket; along the wire to the source; off the wire nothing; a dead end; back along the chalk rubs out', () {
      final unread = _runOf(read: false);
      expect(_feed(unread, unread.map.upstreamPath().skip(1).toList()), M6UtStep.none);
      expect(unread.path, [unread.map.work]);
      final r = _runOf();
      final m = r.map;
      final path = m.upstreamPath();
      // Off the wire: the chalk does not move.
      expect(r.trace(_geo.node(m, m.work) + const Offset(0, -60), _geo), M6UtStep.none);
      expect(r.edgeTo, isNull);
      // To the tap pole; then down the branch away from the source (a dead end).
      _feed(r, path.sublist(1, path.indexOf(m.fuseNode) + 1));
      expect(r.path.last, m.fuseNode);
      final downstream = m.neighbours(m.fuseNode).firstWhere((c) => !path.contains(c));
      _feed(r, [downstream]);
      expect(r.path.last, downstream, reason: 'a fork is taken by the drag\'s direction');
      final end = m.neighbours(downstream).firstWhere((c) => c != m.fuseNode);
      _feed(r, [end]);
      expect(m.neighbours(end), hasLength(1), reason: 'the end of the branch');
      expect(r.trace(_geo.node(m, end) + const Offset(40, 0), _geo), M6UtStep.none, reason: 'nothing beyond a dead end');
      // Back along the chalk to the tap pole: it rubs out.
      _feed(r, [downstream, m.fuseNode]);
      expect(r.path.last, m.fuseNode);
      expect(r.path, path.sublist(0, path.indexOf(m.fuseNode) + 1));
      // On to the source.
      expect(_feed(r, path.sublist(path.indexOf(m.fuseNode) + 1)), M6UtStep.done);
      expect(r.traced, isTrue);
      expect(r.sawS, isTrue);
      expect(r.caught, contains(L.caughtTrace));
      expect(r.chalk(_geo).length, greaterThan(path.length));
    });

    test('the chalk waits at the sectionalizer while the page holds it there', () {
      final r = _runOf();
      final m = r.map;
      final path = m.upstreamPath();
      r.holdAt = m.sNode;
      expect(_feed(r, path.skip(1).toList()), M6UtStep.held);
      expect(r.path.last, m.sNode);
      expect(r.sawS, isTrue);
      r.holdAt = null;
      expect(_feed(r, path.sublist(path.indexOf(m.sNode) + 1)), M6UtStep.done);
    });

    test('forks: at the tap pole, the junction and the main line\'s junction pole more than one wire goes on', () {
      final r = _runOf();
      final m = r.map;
      final path = m.upstreamPath();
      expect(r.forkWires(), isEmpty, reason: 'the work pole');
      var forks = 0;
      for (final n in path.skip(1)) {
        _feed(r, [n]);
        if (r.forkWires().isNotEmpty) forks++;
        if (r.traced) break;
      }
      expect(forks, greaterThanOrEqualTo(3));
    });

    test('flags: only after the trace; our recloser right; the sectionalizer, a fuse, the neighbour\'s recloser slips', () {
      final early = _runOf();
      expect(early.canFlag, isFalse);
      expect(early.flag(_dev(early, M6UtDevKind.sectionalizer)), isNull);
      expect(early.slips, 0);
      final r = _traced();
      expect(r.flag(_dev(r, M6UtDevKind.sectionalizer)), Mk.flagSectionalizer);
      expect(r.flag(_dev(r, M6UtDevKind.fuse)), Mk.flagFuse);
      expect(r.flag(_dev(r, M6UtDevKind.nbrRecloser)), Mk.flagNeighbour);
      expect(r.slips, 3);
      expect(r.flagged, isFalse);
      expect(r.flag(_dev(r, M6UtDevKind.recloser)), isNull);
      expect(r.flagged, isTrue);
      expect(r.caught, contains(L.caughtFlag));
      expect(r.flag(_dev(r, M6UtDevKind.sectionalizer)), isNull, reason: 'the flag is up');
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.thorough, isFalse);
    });

    test('the radio: nothing before the flag; the first reply dealt; asking again: right on an incomplete one (then full), a slip on a full one', () {
      final r = _traced(reply: M6UtReply.wrongRecloser);
      expect(r.ask(), M6UtAsk.early);
      expect(r.reply, isNull);
      r.flag(_dev(r, M6UtDevKind.recloser));
      expect(r.ask(), M6UtAsk.first);
      expect(r.reply, M6UtReply.wrongRecloser);
      expect(r.ask(), M6UtAsk.againRight);
      expect(r.waitedOn, M6UtReply.wrongRecloser);
      expect(r.reply, M6UtReply.full);
      expect(r.caught, contains(L.caughtWait));
      expect(r.slips, 0);
      expect(r.ask(), M6UtAsk.needless);
      expect(r.slips, 1);
      expect(r.reply, M6UtReply.full);
    });

    test('the climb: nothing before a reply; on a full reply up the pole; on an incomplete one deadly (R3)', () {
      for (final reply in M6UtReply.values) {
        final r = _traced(reply: reply);
        expect(r.climb(), isNull);
        expect(r.climbed, isFalse, reason: 'no reply yet: no boot');
        r.flag(_dev(r, M6UtDevKind.recloser));
        r.ask();
        final m = r.climb();
        if (reply == M6UtReply.full) {
          expect(m, isNull);
          expect(r.climbed, isTrue);
          expect(r.caught, contains(L.caughtClimb));
        } else {
          expect(m, Mk.climb(reply));
          expect(m!.deadly, isTrue);
          expect(r.ended, isTrue);
        }
      }
      expect(Mk.climb(M6UtReply.noNonReclose), Mk.climbNoNonReclose);
      expect(Mk.climb(M6UtReply.wrongRecloser), Mk.climbWrongRecloser);
      expect(Mk.climb(M6UtReply.noPermit), Mk.climbNoPermit);
    });

    test('a job ends with the climb; the next starts fresh; two jobs and the play is done', () {
      final r = _traced();
      r
        ..flag(_dev(r, M6UtDevKind.recloser))
        ..ask()
        ..climb()
        ..next();
      expect(r.index, 1);
      expect((r.docketRead, r.traced, r.flagged, r.reply, r.climbed), (false, false, false, null, false));
      expect(r.path, [r.map.work]);
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
    });

    test('listening to him is a flag on the sectionalizer (X2/B1: a slip)', () {
      expect(Mk.push, Mk.flagSectionalizer);
      expect(Mk.push.deadly, isFalse);
      final r = _runOf();
      expect(r.pushSlip(), Mk.flagSectionalizer);
      expect(r.slips, 1);
    });

    test('English digits only; jol not pani; mistakes: pictures, the deadly set, keys, lesson points; every art file used', () {
      const plates = M6UtPlates(feeder: 2, recloser: 12, nbrFeeder: 5, nbrRecloser: 7, pole: 37);
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.docketFirst,
        L.traceFirst,
        L.flagFirst,
        L.holdLonger,
        for (final k in M6UtJobKind.values) L.job(k),
        L.pole(37),
        L.crewOpen,
        L.crewDead,
        L.crewEarth,
        L.request(2, 12),
        for (final r in M6UtReply.values) L.reply(r, plates, 418),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.allWhyWrong,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(l.contains('অন ') || l.contains('অফ '), isFalse, reason: 'ON/OFF in English: $l');
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.climbNoNonReclose, Mk.climbWrongRecloser, Mk.climbNoPermit});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.8/m6_upstream_trace/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      const dir = 'assets/game/art/m6_upstream_trace/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6UpstreamTracePacks.keys, ['do_6_8_b']);
      // The coworker's push is lesson 6.8 myth 2 word for word + the shortcut.
      expect(L.coworker.line, startsWith('সেকশনালাইজার একটি ফিউজের মতোই কাজ করে।'));
    });

    test('libraries: same length, big enough, never a rule marked wrong; the replies alike in length', () {
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      expect(L.wrongFor.keys.toSet(), M6UtWhy.values.toSet(), reason: 'each question its own wrong pool');
      final sets = <String, (List<String>, List<String>)>{
        for (final e in L.whyFlag.entries) 'flag ${e.key}': (e.value, L.wrongFor[e.key]!),
        for (final e in L.whyWait.entries) 'wait ${e.key}': (e.value, L.wrongFor[M6UtWhy.wait]!),
        'climb': (L.whyClimb, L.wrongFor[M6UtWhy.climb]!),
      };
      for (final e in sets.entries) {
        final (right, wrong) = e.value;
        expectSameLength('why ${e.key}', [...right, ...wrong]);
        expectLibrary(e.key, right, wrong);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      // X1: one right climb card names the tester proof and the earths.
      expect(L.whyClimb.any((c) => c.contains('ডেড প্রমাণ') && c.contains('আর্থ')), isTrue);
      expect(L.whyWait.keys.toSet(), {M6UtReply.noNonReclose, M6UtReply.wrongRecloser, M6UtReply.noPermit});
      expect(L.whyQ.keys.toSet(), M6UtWhy.values.toSet());
      expectSameLength('choice', [...L.coworker.right, ...L.coworker.wrong]);
      expectLibrary('choice', L.coworker.right, L.coworker.wrong, minRight: 3);
      expect(L.coworker.asks, contains('কী করবেন?'));
      for (final p in const [
        M6UtPlates(feeder: 1, recloser: 3, nbrFeeder: 9, nbrRecloser: 40, pole: 11),
        M6UtPlates(feeder: 9, recloser: 40, nbrFeeder: 1, nbrRecloser: 3, pole: 89),
      ]) {
        expectSameLength('replies', [for (final r in M6UtReply.values) L.reply(r, p, 100 + p.recloser * 20)]);
      }
    });

    test('rival lines: his exit is recorded; his new push and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['সেকশনালাইজার একটি ফিউজের মতোই কাজ করে। ওটাতেই ফ্ল্যাগ দাও, আর এগোনোর দরকার নেই।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
        L.newGuideLines,
        containsAll([L.intro, ...L.tasks, L.docketFirst, L.traceFirst, L.flagFirst, L.holdLonger, ...L.whyQ.values, L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]),
      );
      expect(L.newGuideLines, contains('ও বলছে সেকশনালাইজারেই ফ্ল্যাগ দিতে। কী করবেন?'));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_upstream_trace: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the drawn places: devices apart and in reach of the camera, clear of the docket and the guide; the boot and step', () {
      for (final h in [560.0, 640.0, 780.0, 900.0]) {
        final g = M6UtGeo.forScene(h, 0);
        for (var s = 0; s < 40; s++) {
          for (final j in m6UtDeal(math.Random(s)).jobs) {
            final m = j.map;
            final rects = [for (final d in m.devices) g.deviceRect(m, d)];
            final guide = Rect.fromLTRB(253, h - 184, 360, h);
            for (final (i, a) in rects.indexed) {
              expect(a.left, greaterThanOrEqualTo(30), reason: 'h $h: $a');
              expect(a.right, lessThanOrEqualTo(kM6UtWorldW - 30), reason: 'h $h: $a');
              expect(a.top, greaterThan(125), reason: 'h $h: $a below the header');
              // Panned as near the middle as the camera goes: clear of the
              // docket and the corner guide.
              final cam = (a.center.dx - 180).clamp(0.0, M6UtGeo.camMax);
              final onScreen = a.shift(Offset(-cam, 0));
              expect(onScreen.overlaps(M6UtGeo.docket), isFalse, reason: 'h $h: $onScreen under the docket');
              expect(onScreen.overlaps(guide), isFalse, reason: 'h $h: $onScreen under the guide');
              for (final b in rects.skip(i + 1)) {
                expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
              }
            }
            // The boot stays clear of the corner guide with the work pole in view.
            final cam = m6UtCamForWork(m);
            final boot = M6UtGeo.bootRect(g.bootHome(m)).shift(Offset(-cam, 0));
            expect(boot.right, lessThan(285 / (392 / 360)), reason: 'h $h: $boot');
            expect(boot.left, greaterThan(84), reason: 'h $h: $boot right of the PTT');
            expect(g.step(m).dy, lessThan(boot.top), reason: 'the step above the boot');
          }
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket (folded) and PTT', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6UpstreamTracePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.docket), findsOneWidget);
      expect(_label(L.pttLabel), findsOneWidget);
      final d = m6UtDeal(math.Random(3));
      expect(find.text(L.job(d.jobs.first.kind)), findsNothing, reason: 'the docket is folded until read');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task a different way; the docket read: job and pole, then the trace task', (t) async {
      final c = await _open(t, 5);
      final d = m6UtDeal(math.Random(5));
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askDocket)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _docket(t);
      expect(find.text(L.job(d.jobs.first.kind)), findsOneWidget);
      expect(find.text(L.pole(d.jobs.first.plates.pole)), findsOneWidget);
      expect(c.read(guideDirectorProvider).line, contains(L.askTrace));
      await _close(t, c);
    });

    // One play with the coworker in the first job and an incomplete first
    // reply; one with him in the second job.
    final flowSeeds = [
      _seedWhere((d) => d.coworkerJob == 0 && d.jobs[0].firstReply != M6UtReply.full && d.jobs[1].firstReply == M6UtReply.full),
      _seedWhere((d) => d.coworkerJob == 1 && d.jobs[0].firstReply == M6UtReply.full && d.jobs[0].map.mirrored),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): two jobs — trace, flag, radio, boot, reasons; he is refused → pass', (t) async {
        final d = m6UtDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < kM6UtJobs; i++) {
          await _playJob(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.8/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.8/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final alone = _seedWhere((d) => d.coworkerJob == 1 && d.jobs[0].firstReply != M6UtReply.full);
    testWidgets('a device tap before the trace only brings "trace first"; a slip flag shows its card and drops; the job goes on', (t) async {
      final c = await _open(t, alone);
      await _docket(t);
      await _tapDevice(t, M6UtDevKind.nbrRecloser);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.traceFirst));
      await _lookAt(t, _g.node(_live.map, _live.map.work).dx - 20);
      await _traceAll(t, him: false);
      await _tapDevice(t, M6UtDevKind.fuse);
      expect(find.text(Mk.flagFuse.textBn), findsOneWidget);
      expect(find.byKey(const ValueKey('drop-1')), findsOneWidget, reason: 'the flag drops');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.index, 0);
      expect(_live.traced, isTrue, reason: 'the chalk stays');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.flagFuse.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, alone);
      await _docket(t);
      await _traceAll(t, him: false);
      for (var i = 0; i < 3; i++) {
        await _tapDevice(t, M6UtDevKind.sectionalizer);
        if (i < 2) {
          expect(find.text(Mk.flagSectionalizer.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('climbing on an incomplete reply: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final d = m6UtDeal(math.Random(alone));
      final c = await _open(t, alone);
      await _docket(t);
      await _traceAll(t, him: false);
      await _tapDevice(t, M6UtDevKind.recloser);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 500);
      await _pickRight(t, L.whyFlag[d.jobs[0].flagWhy]!);
      await _pump(t, 1500);
      await _ptt(t);
      await _pump(t, 1200);
      await _climb(t);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.text(L.crewDead), findsNothing, reason: 'no crew isolation on a deadly climb');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.climb(d.jobs[0].firstReply)!.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final himFirst = _seedWhere((d) => d.coworkerJob == 0 && d.jobs[0].firstReply == M6UtReply.full);
    testWidgets('a device tap brings him at once; listening = a flag on the sectionalizer (a slip), then the job goes on', (t) async {
      final c = await _open(t, himFirst);
      await _docket(t);
      // A tap on a device, well before the sectionalizer: he cuts in.
      await _tapDevice(t, M6UtDevKind.fuse);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(find.byType(MistakeCard), findsNothing);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.flagSectionalizer.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.flagSectionalizer.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      // He has gone: the chalk passes the sectionalizer.
      await _lookAt(t, _g.node(_live.map, _live.map.work).dx - 20);
      expect(await _drag(t, _rest()), isTrue);
      expect(_live.traced, isTrue);
      await _close(t, c);
    });

    testWidgets('asking again after a full reply is a needless stop (a slip); the praise window takes no touch', (t) async {
      final c = await _open(t, himFirst);
      await _docket(t);
      await _traceAll(t, him: true);
      await _tapDevice(t, M6UtDevKind.recloser);
      // The ◆ on the table, the deck at once: the scene and PTT take nothing.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(M6UtGeo.docket.center * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.reply, isNull);
      expect(find.byType(MistakeCard), findsNothing);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 500);
      await _pickRight(t, L.whyFlag[_live.job.flagWhy]!);
      await _pump(t, 1500);
      await _ptt(t);
      await _pump(t, 1200);
      expect(_live.reply, M6UtReply.full);
      await _ptt(t);
      expect(find.text(Mk.askAgain.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.askAgain.key);
      await _close(t, c);
    });

    testWidgets('PTT let go early: nothing is asked; the guide says to hold it', (t) async {
      final c = await _open(t, alone);
      await _docket(t);
      await _traceAll(t, him: false);
      await _tapDevice(t, M6UtDevKind.recloser);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 500);
      await _pickRight(t, L.whyFlag[_live.job.flagWhy]!);
      await _pump(t, 1500);
      await _ptt(t, ms: 300);
      expect(_live.reply, isNull);
      expect(c.read(guideDirectorProvider).line, contains(L.holdLonger));
      await _close(t, c);
    });

    testWidgets('gesture hand: a tap on the docket first; then a nudge on the chalk head that presses nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, alone);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle: the docket not read');
      expect(scene().debugOptions, isEmpty, reason: 'a tap on the one way on, not a pick');
      await _docket(t);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the trace');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.path, [_live.map.work], reason: 'the hand moves no chalk');
      await _close(t, c);
    });
  });
}
