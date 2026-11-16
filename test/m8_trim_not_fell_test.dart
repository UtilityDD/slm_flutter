// Lesson 8.9 (পরিবেশগত নিয়মাবলী), কাজ "ছাঁটা, কাটা নয়": the rules (a right cut,
// a stub left in the line's path, the nest side, a harmless branch, the trunk,
// "ছাঁটা শেষ" with a danger left, the consumer deck; no deadly anywhere,
// ruling M8-1), the deal (two of four trees, 3–4 branches, 1–2 endangering,
// nests, pole length and sway, sides, light, the coworker's tree and seat), the
// libraries, every spoken line listed, the drawn geometry, and the level in the
// shell: the guide first, a full clean play (owner deck, hook seated, rope
// pulled, reasons, the coworker refused, "ছাঁটা শেষ") → pass, a slip card per
// mistake, three slips, listening = a slip (no freeze), the pull waits for him,
// the praise window takes no touch, and the gesture hand shows how (never what).
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
import 'package:slm_flutter/features/game/m8_trim_not_fell.dart';
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
  rungId: '8.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m8TrimPacks['do_8_9_a']!;
typedef L = M8TrimLines;
typedef Mk = M8TrimMistakes;

/// য় ড় ঢ় as base + nukta (the lesson file may hold single code points).
String _nk(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

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

Finder _card(String text) => find.byKey(ValueKey('deal-$text'));

/// The first of [texts] that is a card on the deck now.
String _onDeck(List<String> texts) {
  final on = [for (final x in texts) if (_card(x).evaluate().isNotEmpty) x];
  expect(on, hasLength(1), reason: 'one right card of ${texts.first}…');
  return on.single;
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M8TrimRun get _live => M8TrimProbe.run!;
M8TrimGeo get _geo => M8TrimGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0, mirror: _live.deal.mirror, poleLen: _live.deal.poleLen);
Offset _headAt = Offset.zero;

/// Drag the pruner head from where it is to [to] (design px) and let go.
Future<void> _dragHead(WidgetTester t, Offset to, {bool settle = true}) async {
  final from = _headAt;
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 8)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  final s = _live.seat;
  _headAt = s != null && s.kind == M8SeatKind.branch ? _geo.pointOn(_live.cur.deal, _live.cur.deal.branches[s.index], s.t) : _geo.headFor(to);
  await _pump(t, settle ? 300 : 60);
}

/// Seat the hook on branch [i] at part [tt].
Future<void> _seat(WidgetTester t, int i, double tt) async {
  final d = _live.cur.deal;
  await _dragHead(t, _geo.pointOn(d, d.branches[i], tt));
  expect(_live.seat?.kind, M8SeatKind.branch, reason: 'seated on branch $i');
  expect(_live.seat?.index, i);
}

/// Swipe down on the rope.
Future<void> _swipe(WidgetTester t) async {
  await t.dragFrom(_geo.ropeHit.center * _k, const Offset(0, 70) * _k);
  await _pump(t, 200);
}

/// The coworker came: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await waitChoiceDeck(t);
  await pickChoice(t, _onDeck(L.coworker.right));
  await _pump(t, 2800);
}

/// Pull; the pull waits for him if he is due (refuse him, pull again).
Future<void> _pull(WidgetTester t) async {
  final before = _live.cur.pieces.length;
  await _swipe(t);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    expect(_live.cur.pieces.length, before, reason: 'the pull waited for him');
    await _refuse(t);
    await _swipe(t);
  }
  await _pump(t, 1400);
}

/// The reason deck: pick the right card (any topic) and go on.
Future<void> _reason(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await waitChoiceDeck(t);
  await pickChoice(t, _onDeck(L.allWhyRight));
  await _pump(t, 1500);
}

Future<void> _tapDone(WidgetTester t) async {
  await t.tapAt(_geo.doneBtn.center * _k);
  await _pump(t, 300);
}

/// The owner's deck: the kind card, then its reason.
Future<void> _consumer(WidgetTester t) async {
  await waitChoiceDeck(t);
  await pickChoice(t, _onDeck(L.consumerRight), proceed: false);
  await _pump(t, 1200);
  await _reason(t);
}

/// One tree played clean: the owner, each endangering branch seated in the
/// right part and pulled (the coworker refused if he cuts in), "ছাঁটা শেষ".
Future<void> _playTree(WidgetTester t) async {
  final idx = _live.treeIdx;
  if (!_live.cur.consumerDone) await _consumer(t);
  final d = _live.cur.deal;
  for (var i = 0; i < d.branches.length; i++) {
    final b = d.branches[i];
    if (!b.endangers) continue;
    await _seat(t, i, (math.max(b.nestT != null ? b.nestSafeT : 0.14, 0.14) + b.lineT) / 2 + (b.nestT != null ? 0.0 : 0.04));
    await _pull(t);
    expect(_live.cur.done[i], isTrue, reason: 'branch $i cut');
    await _reason(t);
  }
  await _tapDone(t);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    expect(_live.treeIdx, idx, reason: 'finishing waited for him');
    await _refuse(t);
    await _tapDone(t);
  }
  await _pump(t, 2600);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8TrimPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1200);
  _headAt = _geo.headHome;
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M8TrimDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8TrimDeal(math.Random(s))));

/// A hand-made branch for the rules.
M8Branch _br(M8BranchKind k, {double? nest, int side = 1, double ay = -140, double tipY = -256}) =>
    M8Branch(side: side, ay: ay, tipDx: 40, tipY: k == M8BranchKind.harmless ? -180 : tipY, kind: k, nestT: nest);

M8TrimRun _runOf(List<M8Branch> a, {List<M8Branch>? b, M8TreeKind kind = M8TreeKind.roadside}) => M8TrimRun(M8TrimDeal(
      trees: [M8TreeDeal(kind: kind, cx: 0, branches: a), M8TreeDeal(kind: M8TreeKind.forest, cx: 0, branches: b ?? [_br(M8BranchKind.rests)])],
      coworkerTree: 0,
      coworkerSeat: 1,
      poleLen: 250,
      sway: 4,
      mirror: false,
      dusk: 0,
      whyRoll: 7,
      captionRoll: 0,
    ));

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.9');
}

void main() {
  group('rules', () {
    test('deals: two of four trees (one with an owner), 3–4 branches, 1–2 endangering, nests, sides, light, his tree and seat vary; plays differ', () {
      final seen = <String>{};
      final kinds = <M8TreeKind>{};
      final firstKinds = <M8TreeKind>{};
      final counts = <int>{};
      final dangers = <int>{};
      final him = <int>{};
      final seats = <int>{};
      final nestOn = <String>{};
      var mirrored = 0, tipsRests = 0, tipsOver = 0;
      for (var s = 0; s < 400; s++) {
        final d = m8TrimDeal(math.Random(s));
        expect(d.trees, hasLength(2));
        expect(d.trees[0].kind, isNot(d.trees[1].kind));
        expect(d.trees.any((t) => m8HasOwner(t.kind)), isTrue, reason: 'the consumer deck is always taught');
        him.add(d.coworkerTree);
        seats.add(d.coworkerSeat);
        expect(d.poleLen, inInclusiveRange(240, 265));
        expect(d.sway, inInclusiveRange(3, 8));
        if (d.mirror) mirrored++;
        firstKinds.add(d.trees.first.kind);
        for (final t in d.trees) {
          kinds.add(t.kind);
          counts.add(t.branches.length);
          dangers.add(t.endangering);
          expect(t.branches.length, inInclusiveRange(3, 4));
          expect(t.endangering, inInclusiveRange(1, 2));
          expect(t.endangering, lessThan(t.branches.length));
          expect(t.branches.where((b) => b.nestT != null).length, lessThanOrEqualTo(1));
          for (final b in t.branches) {
            if (b.endangers) {
              // It reaches the conductors; its corridor part is well inside it.
              expect(b.tipY, lessThanOrEqualTo(-246));
              expect(b.lineT, inInclusiveRange(0.44, 0.72), reason: 'line part ${b.lineT}');
              if (b.nestT != null) {
                expect(b.nestT, inInclusiveRange(0.12, 0.22));
                expect(b.lineT - b.nestSafeT, greaterThanOrEqualTo(0.15), reason: 'a fair window between nest and line');
                nestOn.add('danger');
              }
              b.kind == M8BranchKind.rests ? tipsRests++ : tipsOver++;
            } else {
              expect(b.tipY, greaterThan(m8RowY), reason: 'a harmless branch stays out of the corridor');
              if (b.nestT != null) nestOn.add('harmless');
            }
          }
          if (t.nestIndex == null) nestOn.add('none');
        }
        seen.add('${d.coworkerTree}${d.coworkerSeat}${d.mirror}${d.dusk}${d.poleLen.round()}|${d.trees.map((t) => '${t.kind.index}${t.branches.map((b) => '${b.side}${b.ay.round()}${b.kind.index}${b.nestT != null}').join()}').join('|')}');
      }
      expect(seen.length, greaterThan(390));
      expect(kinds, M8TreeKind.values.toSet());
      expect(firstKinds, M8TreeKind.values.toSet());
      expect(counts, {3, 4});
      expect(dangers, {1, 2});
      expect(him, {0, 1});
      expect(seats, {1, 2});
      expect(nestOn, {'none', 'danger', 'harmless'});
      expect(mirrored, inInclusiveRange(150, 250));
      expect(tipsRests, greaterThan(100));
      expect(tipsOver, greaterThan(100));
    });

    test('the consumer deck: a quarrelling card is a slip, the kind one pays; the hook waits for him', () {
      final r = _runOf([_br(M8BranchKind.rests)], kind: M8TreeKind.mango);
      expect(r.cur.consumerDone, isFalse);
      expect(r.seatHook(const M8SeatHit(M8SeatKind.branch, 0, 0.4)), isFalse, reason: 'not before the owner is answered');
      expect(r.consumerPick(false), Mk.quarrel);
      expect(r.consumerPick(false), Mk.quarrel);
      expect(r.slips, 2);
      expect(r.consumerPick(true), isNull);
      expect(r.cur.consumerDone, isTrue);
      expect(r.caught, [L.caughtOwner]);
      expect(r.consumerPick(true), isNull, reason: 'asked once');
      expect(r.seatHook(const M8SeatHit(M8SeatKind.branch, 0, 0.4)), isTrue);
      // A tree with no owner has nobody to talk to.
      expect(_runOf([_br(M8BranchKind.rests)]).cur.consumerDone, isTrue);
    });

    test('a pull on an endangering branch: between the line and the trunk is right; wood left in the line\'s path is a slip and can be cut again', () {
      final r = _runOf([_br(M8BranchKind.rests)]);
      final b = r.cur.deal.branches[0];
      expect(b.lineT, closeTo(0.62, 0.01));
      expect(r.pull().kind, M8PullKind.none, reason: 'nothing seated');
      r.seatHook(M8SeatHit(M8SeatKind.branch, 0, b.lineT + 0.2));
      final stub = r.pull();
      expect(stub.kind, M8PullKind.stub);
      expect(stub.mistake, Mk.stub);
      expect(stub.piece!.from, closeTo(b.lineT + 0.2, 1e-9));
      expect(stub.piece!.to, 1.0);
      expect(r.cur.done[0], isFalse, reason: 'the stub stands in the line\'s path');
      expect(r.cur.curT[0], closeTo(b.lineT + 0.2, 1e-9));
      expect(r.seat, isNull, reason: 'the hook comes off after a pull');
      // A seat beyond the stub is clamped to it: the same wood cannot be cut twice.
      r.seatHook(M8SeatHit(M8SeatKind.branch, 0, 0.95));
      expect(r.pull().piece!.from, closeTo(b.lineT + 0.2, 1e-9));
      r.slips = 0;
      r.seatHook(const M8SeatHit(M8SeatKind.branch, 0, 0.3));
      final ok = r.pull();
      expect(ok.kind, M8PullKind.right);
      expect(ok.mistake, isNull);
      expect(ok.hadNest, isFalse);
      expect(r.cur.done[0], isTrue);
      expect(r.slips, 0);
      expect(r.caught, [L.caughtCut]);
      expect(r.cur.dangerLeft, isFalse);
    });

    test('the nest: cut on the trunk side of it = a slip, the nest falls; beyond it the nest stays on the stub', () {
      final r = _runOf([_br(M8BranchKind.over, nest: 0.2, tipY: -280)]);
      final b = r.cur.deal.branches[0];
      expect(b.nestSafeT, closeTo(0.24, 1e-9));
      r.seatHook(const M8SeatHit(M8SeatKind.branch, 0, 0.22));
      final fall = r.pull();
      expect(fall.kind, M8PullKind.nestFall);
      expect(fall.mistake, Mk.nestFall);
      expect(r.cur.nestDown, isTrue);
      expect(r.cur.done[0], isTrue);
      final ok = _runOf([_br(M8BranchKind.over, nest: 0.2, tipY: -280)]);
      ok.seatHook(M8SeatHit(M8SeatKind.branch, 0, (0.25 + b.lineT) / 2));
      final res = ok.pull();
      expect(res.kind, M8PullKind.right);
      expect(res.hadNest, isTrue);
      expect(ok.cur.nestDown, isFalse);
      expect(ok.caught, [L.caughtCut, L.caughtNest]);
      // The nest reason is asked once, for a branch that kept its nest.
      expect(ok.whyFor(hadNest: true), M8TrimWhy.nest);
      expect(ok.whyFor(hadNest: true), isNot(M8TrimWhy.nest));
    });

    test('a harmless branch, the trunk, and "ছাঁটা শেষ" with a danger left are slips; the trunk never falls', () {
      final r = _runOf([_br(M8BranchKind.harmless, nest: 0.5), _br(M8BranchKind.rests, side: -1)]);
      r.seatHook(const M8SeatHit(M8SeatKind.branch, 0, 0.3));
      final n = r.pull();
      expect(n.kind, M8PullKind.needless);
      expect(n.mistake, Mk.needless);
      expect(r.cur.nestDown, isTrue, reason: 'it was on the piece that fell');
      expect(r.cur.done[0], isTrue);
      r.seatHook(const M8SeatHit(M8SeatKind.trunk, -1, 0));
      final t = r.pull();
      expect(t.kind, M8PullKind.trunk);
      expect(t.mistake, Mk.trunk);
      expect(t.piece, isNull, reason: 'the trunk never falls');
      expect(r.seat, isNull);
      expect(r.slips, 2);
      expect(r.finish(), Mk.leftOver);
      expect(r.slips, 3);
      expect(r.cur.finished, isTrue);
      expect(r.finish(), isNull, reason: 'a tree ends once');
      // A clean tree: nothing to leave.
      final c = _runOf([_br(M8BranchKind.harmless)]);
      expect(c.finish(), isNull);
      expect(c.slips, 0);
    });

    test('the run: two trees, the mark is 100 − 15 per slip, pass at 55 or more, listening is a slip', () {
      final r = _runOf([_br(M8BranchKind.harmless)]);
      expect(r.listen(), Mk.listenSaw);
      expect(r.slips, 1);
      expect(r.percent, 85);
      expect(r.finish(), isNull);
      r.next();
      expect(r.treeIdx, 1);
      expect(r.done, isFalse);
      expect(r.cur.deal.kind, M8TreeKind.forest);
      r.seatHook(const M8SeatHit(M8SeatKind.branch, 0, 0.3));
      expect(r.pull().kind, M8PullKind.right);
      expect(r.finish(), isNull);
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
      r.slips = 4;
      expect(r.percent, 40);
      expect(r.passed, isFalse);
    });

    test('no deadly in 8.9 (M8-1): every mistake a slip; keys, pictures, lesson points; every picture used', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      expect(Mk.all, hasLength(7));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.9/m8_trim_not_fell/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, anyOf(isNull, inInclusiveRange(0, 1)));
      }
      expect(Mk.quarrel.lessonPoint, isNull, reason: 'a pro tip, not a numbered point');
      const dir = 'assets/game/art/m8_trim_not_fell/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8TrimPacks.keys, ['do_8_9_a']);
    });

    test('the live lesson: the myth word for word, the rules and the pro tip quoted', () {
      final lesson = _lesson();
      final text = _nk(jsonEncode(lesson));
      final myths = ((lesson['content'] as Map)['myth_buster'] as Map)['myths'] as List;
      expect(_nk(L.coworker.line), _nk((myths[1] as Map)['myth'] as String));
      expect(text, contains(_nk('শুধু গাছের ডাল \'ছাঁটতে\' পারি যা লাইনের বিপদ ঘটাচ্ছে')));
      expect(text, contains(_nk('অধিকার আমাদের নেই')));
      expect(text, contains(_nk('ফরেস্ট ডিপার্টমেন্ট বা স্থানীয় পঞ্চায়েত/মিউনিসিপালিটির লিখিত অনুমতি লাগে')));
      expect(text, contains(_nk('গাছের ক্ষতি কম হয় এবং পাখির বাসা নষ্ট না হয়')));
      expect(text, contains(_nk('ঝগড়া নয়, সচেতনতাই সমাধান')));
      expect(text, contains(_nk('ঝড়ের সময় ডাল পড়ে তার ছেঁড়া বা আগুন লাগার ঘটনা এড়াতে বর্ষার আগেই')));
      expect(text, contains(_nk('গাছের ডাল তারে ঠেকলে শুধু কারেন্ট যাবে না, গাছে আগুনও লাগতে পারে')));
      expect(_nk(Mk.trunkBn), contains(_nk('অধিকার আমাদের নেই')));
      expect(_nk(Mk.listenSawBn), contains(_nk('লিখিত অনুমতি লাগে')));
      expect(_nk(Mk.leftOverBn), contains(_nk('বিপদের ডাল')));
      expect(L.whyRight[M8TrimWhy.fell]!.first, contains('লিখিত অনুমতি'));
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, base + nukta, no "AB বন্ধ", no unsupported legal detail; option groups within 1.3×', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.sceneLabel,
        L.done,
        ...L.stages,
        for (final l in L.ownerCaptions.values) ...l,
        ...L.consumerRight,
        ...L.consumerWrong,
        for (final q in L.whyQ.values) q,
        ...L.allWhyRight,
        ...L.myths,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtCut,
        L.caughtNest,
        L.caughtOwner,
        L.caughtCall,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(l.contains('Non-bailable'), isFalse, reason: 'the lesson names no more than "আইনি মামলা"');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
      }
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expectLibrary('why', L.allWhyRight, L.myths, minRight: 10);
      for (final w in M8TrimWhy.values) {
        expect(L.whyRight[w]!.length, greaterThanOrEqualTo(2), reason: '$w');
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 12; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('consumer', [...L.consumerRight, ...L.consumerWrong]);
      expectLibrary('consumer', L.consumerRight, L.consumerWrong);
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
      expect(L.whyQ[M8TrimWhy.only], 'কেন শুধু এই ডালটা ছাঁটলেন?');
    });

    test('spoken lines: his exit is recorded; his push and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.coworker.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, for (final q in L.whyQ.values) q, L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      final spoken = L.spokenLines.toSet();
      for (final l in [L.intro, ...L.tasks, ...L.tapWhy, L.callHeld, L.allSet, L.quick, L.fail, L.coworker.line, L.coworkerExit, ...L.coworker.asks, for (final q in L.whyQ.values) q, for (final m in Mk.all) m.textBn]) {
        expect(spoken, contains(l), reason: l);
      }
      // The owner's captions are silent figures (M8-10): never spoken.
      for (final l in L.ownerCaptions.values.expand((x) => x)) {
        expect(spoken, isNot(contains(l)));
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_trim_not_fell: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: the hook reaches every cut part and every part of a branch seats its own branch; the trunk and the air find their own', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        for (final mirror in [false, true]) {
          for (var s = 0; s < 60; s++) {
            final deal = m8TrimDeal(math.Random(s));
            final g = M8TrimGeo.forScene(h, 0, mirror: mirror, poleLen: deal.poleLen);
            expect(g.doneBtn.bottom, lessThanOrEqualTo(h));
            expect(g.doneBtn.height, greaterThanOrEqualTo(48));
            expect(g.headHome.dy, greaterThan(140), reason: 'the head starts below the header');
            expect(g.ropeHit.overlaps(g.headBox(g.headHome)), isFalse);
            for (final tree in deal.trees) {
              final cur = List.filled(tree.branches.length, 1.0);
              final done = List.filled(tree.branches.length, false);
              expect(g.seatAt(tree, cur, done, g.origin(tree) + const Offset(0, -20)).kind, M8SeatKind.trunk);
              expect(g.seatAt(tree, cur, done, const Offset(2, 2)).kind, M8SeatKind.none);
              expect(g.ropeHit.contains(g.tipOf(tree, tree.branches.first)), isFalse);
              for (var i = 0; i < tree.branches.length; i++) {
                final b = tree.branches[i];
                if (b.endangers) {
                  // The whole window between the nest (or the trunk) and the line is reachable.
                  for (final t in [math.max(0.14, b.nestSafeT) + 0.01, b.lineT - 0.02]) {
                    final p = g.pointOn(tree, b, t);
                    expect((p - g.hands).distance, lessThan(g.poleLen - 4), reason: 'branch $i at $t, seed $s h $h');
                  }
                }
                for (final t in [0.2, 0.4, 0.6, 0.8]) {
                  final hit = g.seatAt(tree, cur, done, g.pointOn(tree, b, t));
                  expect(hit.kind, M8SeatKind.branch, reason: 'seed $s branch $i at $t');
                  expect(hit.index, i, reason: 'seed $s branch $i at $t');
                  expect(hit.t, closeTo(t, 0.12));
                }
              }
            }
          }
        }
      }
      // The pole never gets longer than itself, and sways sideways only.
      final g = M8TrimGeo.forScene(780, 0, poleLen: 250);
      expect((g.headFor(const Offset(10, 10)) - g.hands).distance, closeTo(250, 1e-6));
      expect((g.headFor(g.hands + const Offset(100, -100)) - g.hands).distance, closeTo(141.42, 0.1));
      final sway = g.headFor(g.hands + const Offset(100, -100), swayPx: 6, ms: 500);
      expect((sway - g.hands).distance, closeTo(math.sqrt(141.42 * 141.42 + math.pow(6 * math.sin(500 / 330), 2)), 0.1));
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

    testWidgets('the guide comes first: a tap does not skip him; then the lane, the owner caption and the button', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final seed = _seedWhere((d) => m8HasOwner(d.trees.first.kind));
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M8TrimPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.text(L.done), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the owner waits at his gate');
      final caption = L.ownerCaptions[m8TrimDeal(math.Random(seed)).trees.first.kind]!;
      expect(caption.where((c) => find.text(c).evaluate().isNotEmpty), hasLength(1), reason: 'a caption bubble, not a voice');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives the task again in other words, never a branch or a place', (t) async {
      final seed = _seedWhere((d) => !m8HasOwner(d.trees.first.kind));
      final c = await _open(t, seed);
      expect(c.read(guideDirectorProvider).line, contains(L.askWork));
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.toSet().length, greaterThan(1), reason: 'a different way each time');
      for (final l in lines) {
        expect(l, contains(L.askWork));
      }
      await _close(t, c);
    });

    // His tree 1 after the first seat, his tree 2 after the second; an owner first and an owner second.
    final flowSeeds = [
      _seedWhere((d) => d.coworkerTree == 0 && d.coworkerSeat == 1 && m8HasOwner(d.trees[0].kind) && d.trees[0].endangering == 2),
      _seedWhere((d) => d.coworkerTree == 1 && d.coworkerSeat == 2 && !m8HasOwner(d.trees[0].kind) && d.trees[1].endangering == 1),
      _seedWhere((d) => d.coworkerTree == 0 && d.coworkerSeat == 2 && d.trees[0].endangering == 1 && d.trees[0].nestIndex != null && d.trees[0].branches[d.trees[0].nestIndex!].endangers),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): owner, hook seated, rope pulled, reasons, he is refused, "ছাঁটা শেষ" twice → pass', (t) async {
        final c = await _open(t, seed);
        for (var i = 0; i < 2; i++) {
          await _playTree(t);
          _headAt = _geo.headHome;
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.9/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.9/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCut), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final ownerFirst = _seedWhere((d) => m8HasOwner(d.trees[0].kind));
    testWidgets('the owner: a quarrelling card is a slip (the deck stays, the card dimmed); the kind one pays and its reason follows', (t) async {
      final c = await _open(t, ownerFirst);
      await waitChoiceDeck(t);
      final wrong = L.consumerWrong.firstWhere((w) => _card(w).evaluate().isNotEmpty);
      await t.tap(_card(wrong), warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.quarrel.textBn), findsOneWidget);
      expect(_live.slips, 1);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'he is still waiting');
      // The work does not begin while he waits.
      await _dragHead(t, _geo.pointOn(_live.cur.deal, _live.cur.deal.branches[0], 0.4));
      expect(_live.seat, isNull);
      await pickChoice(t, _onDeck(L.consumerRight), proceed: false);
      await _pump(t, 1200);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      await waitChoiceDeck(t);
      expect(_card(L.whyRight[M8TrimWhy.consumer]![0]).evaluate().isNotEmpty || _card(L.whyRight[M8TrimWhy.consumer]![1]).evaluate().isNotEmpty, isTrue);
      await pickChoice(t, _onDeck(L.whyRight[M8TrimWhy.consumer]!));
      await _pump(t, 1500);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(_live.cur.consumerDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), [Mk.quarrel.key]);
      await _close(t, c);
    });

    final plain = _seedWhere((d) => !m8HasOwner(d.trees[0].kind) && d.trees[0].branches.any((b) => !b.endangers) && d.trees[0].endangering == 1);
    testWidgets('slips with their cards: a harmless branch, the trunk, a stub left in the line, the nest side; the tree goes on; the stub can be cut again', (t) async {
      final c = await _open(t, plain);
      final d = _live.cur.deal;
      final harmless = d.branches.indexWhere((b) => !b.endangers);
      final bad = d.branches.indexWhere((b) => b.endangers);
      // A harmless branch: cut, the piece lands, the card.
      await _seat(t, harmless, 0.6);
      await _pull(t);
      if (find.byType(CoworkerPeek).evaluate().isNotEmpty) await _refuse(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.needless.textBn), findsOneWidget);
      expect(_live.cur.pieces, hasLength(1));
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // A stub left in the line's path: the card; the branch is still to cut.
      final b = d.branches[bad];
      await _seat(t, bad, math.min(b.lineT + 0.2, 0.9));
      await _pull(t);
      if (find.byType(CoworkerPeek).evaluate().isNotEmpty) await _refuse(t);
      if (find.byType(MistakeCard).evaluate().isEmpty) await _pull(t);
      expect(find.text(Mk.stub.textBn), findsOneWidget);
      expect(_live.cur.done[bad], isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), [Mk.needless.key, Mk.stub.key]);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (the hook on the trunk, pulled)', (t) async {
      final c = await _open(t, plain);
      for (var i = 0; i < 3; i++) {
        await _dragHead(t, _geo.origin(_live.cur.deal) + Offset(0, i.isEven ? -30.0 : -110.0));
        expect(_live.seat?.kind, M8SeatKind.trunk);
        await _swipe(t);
        if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
          await _refuse(t);
          await _swipe(t);
        }
        await _pump(t, 1500);
        if (i < 2) {
          expect(find.text(Mk.trunk.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 8.9');
      expect(_live.slips, 3);
      await _close(t, c);
    });

    final hisFirst = _seedWhere((d) => d.coworkerTree == 0 && d.coworkerSeat == 1 && !m8HasOwner(d.trees[0].kind) && d.trees[0].endangering >= 1);
    testWidgets('listening to him = a slip (the chainsaw bites, no freeze); the pull waited for him; he came once', (t) async {
      final c = await _open(t, hisFirst);
      final d = _live.cur.deal;
      final i = d.branches.indexWhere((b) => b.endangers);
      final b = d.branches[i];
      await _seat(t, i, (math.max(0.14, b.nestSafeT) + b.lineT) / 2 + 0.03);
      await _swipe(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the pull waits for him');
      expect(_live.cur.pieces, isEmpty);
      expect(_live.seat, isNotNull, reason: 'the hook stays seated');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = [for (final w in L.coworker.wrong) if (_card(w).evaluate().isNotEmpty) w];
      expect(wrong, isNotEmpty);
      await t.tap(_card(wrong.first), warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 700);
      expect(_live.slips, 1, reason: 'booked at once');
      await _pump(t, 1800);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.listenSaw.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.last.key, Mk.listenSaw.key);
      expect(c.read(gameSaveProvider).mistakes.last.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // He came once: the next pull cuts.
      await _pull(t);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(_live.cur.done[i], isTrue);
      await _close(t, c);
    });

    testWidgets('"ছাঁটা শেষ" with a danger left: a slip, then the next tree', (t) async {
      final seed = _seedWhere((d) => d.coworkerTree == 1 && !m8HasOwner(d.trees[0].kind));
      final c = await _open(t, seed);
      await _tapDone(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.leftOver.textBn), findsOneWidget);
      expect(_live.treeIdx, 0);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2600);
      expect(_live.treeIdx, 1);
      expect(_live.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), [Mk.leftOver.key]);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; the reason pays and the work goes on', (t) async {
      final seed = _seedWhere((d) => d.coworkerTree == 1 && !m8HasOwner(d.trees[0].kind) && d.trees[0].endangering == 2);
      final c = await _open(t, seed);
      final d = _live.cur.deal;
      final first = d.branches.indexWhere((b) => b.endangers);
      final second = d.branches.indexWhere((b) => b.endangers, first + 1);
      final b = d.branches[first];
      await _seat(t, first, (math.max(0.14, b.nestSafeT) + b.lineT) / 2 + 0.03);
      await _pull(t);
      expect(_live.cur.done[first], isTrue);
      // At once: drags on the scene do nothing (shielded, then the deck).
      await _dragHead(t, _geo.pointOn(d, d.branches[second], 0.4), settle: false);
      expect(_live.seat, isNull);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a lifted hook moves freely: seated, lifted again, put elsewhere; nothing falls until the rope is pulled', (t) async {
      final seed = _seedWhere((d) => d.coworkerTree == 1 && !m8HasOwner(d.trees[0].kind));
      final c = await _open(t, seed);
      final d = _live.cur.deal;
      await _seat(t, 0, 0.5);
      expect(_live.cur.seats, 1);
      await _seat(t, 1, 0.5);
      expect(_live.cur.seats, 2);
      expect(_live.seat?.index, 1);
      expect(_live.cur.pieces, isEmpty);
      expect(_live.slips, 0);
      expect(_live.cur.curT, everyElement(1.0));
      // A swipe on the rope with nothing seated does nothing.
      await _dragHead(t, const Offset(300, 200));
      expect(_live.seat, isNull);
      await _swipe(t);
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      expect(d.branches, isNotEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle with nothing seated → a drag nudge straight up; seated → a sweep over the rope, the head and the button', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.coworkerTree == 1 && !m8HasOwner(d.trees[0].kind));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with nothing seated');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a drag nudge presses nothing');
      final g = await t.startGesture(_headAt * _k);
      await _pump(t, 600);
      expect(scene().showing, isFalse, reason: 'a touch hides it');
      await g.up();
      await _pump(t, 300);
      await _seat(t, 0, 0.5);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'idle with the hook seated');
      expect(scene().debugOptions, hasLength(3), reason: 'the rope, the head and the button alike');
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _close(t, c);
    });
  });
}
