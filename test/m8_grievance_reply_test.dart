// Lesson 8.6 (গ্রাহক অভিযোগ নিষ্পত্তি), কাজ "রাগ নয়, ঠিক রাস্তা": the rules (the
// complaint ladder: the case file dropped on a plank judged only on 'পাঠান';
// the right plank → he pushes back once and a three-card reply deck opens; a
// wrong plank = a leap ahead / a step back, a wrong card = its kind's slip),
// the deal (3 of 6 stages), the libraries, the coworker's two myth pushes
// (listening = a slip, never deadly), and the level in the shell: the guide
// first, a full clean play (file dragged, reply card, a reason each, the
// coworker refused → pass), a wrong plank, a wrong card, three slips,
// listening to him, 'পাঠান' waits for him on a fast play, the praise window
// takes no touch, and the gesture hand shows how (never what) only while the
// level waits.
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
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_grievance_reply.dart';
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
  rungId: '8.6/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m8GrievanceReplyPacks['do_8_6_a']!;
typedef L = M8GrievanceReplyLines;
typedef Mk = M8GrievanceReplyMistakes;

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

M8GrievanceRun get _live => M8GrievanceReplyProbe.run!;

/// Pumps until the run reaches [phase].
Future<void> _untilPhase(WidgetTester t, M8Phase phase, {int maxMs = 40000}) async {
  for (var ms = 0; ms < maxMs && _live.phase != phase; ms += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await _pump(t, 300);
}

/// Picks the card of [texts] that is on the open deck: its preview, ✓, and (a
/// reason) the zoomed card's এগিয়ে যান.
Future<void> _pickOne(WidgetTester t, List<String> texts, {bool proceed = true}) async {
  await waitChoiceDeck(t);
  final on = [for (final x in texts) if (find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty) x];
  expect(on, hasLength(1), reason: texts.first);
  await pickChoice(t, on.single, proceed: proceed);
}

/// The file dragged from where it is onto plank [i] (0 = lowest).
Future<void> _dragFile(WidgetTester t, int i) async {
  final from = t.getCenter(find.byKey(const ValueKey('file')));
  final to = t.getCenter(find.byKey(ValueKey('rung-$i')));
  final g = await t.startGesture(from);
  await g.moveBy(const Offset(0, -24));
  await t.pump(const Duration(milliseconds: 30));
  for (var k = 1; k <= 8; k++) {
    await g.moveTo(Offset.lerp(from + const Offset(0, -24), to, k / 8)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 250);
}

Future<void> _tapSend(WidgetTester t) async {
  await t.tap(_label(L.send), warnIfMissed: false);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8GrievanceReplyPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M8Deal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8Deal(math.Random(s))));

/// The coworker comes (the file on a plank, 'পাঠান' tapped): refuse him.
Future<void> _refuse(WidgetTester t, CoworkerScript s) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickOne(t, s.right, proceed: false);
  await _pump(t, 2600);
}

/// The right reply card of the open reply deck.
String _rightCard() => _live.replyOptions.firstWhere((o) => o.correct).textBn;

/// One consumer played right (the coworker refused if he is dealt on him).
Future<void> _playConsumer(WidgetTester t, M8Deal d, int i) async {
  await _untilPhase(t, M8Phase.route);
  expect(_live.index, i);
  await _dragFile(t, d.consumers[i].forum.index);
  expect(_live.pinned, d.consumers[i].forum);
  await _tapSend(t);
  if (d.coworkerAt == i) {
    await _refuse(t, d.script);
    await _tapSend(t);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'consumer $i');
  await _untilPhase(t, M8Phase.replying);
  expect(find.text(d.consumers[i].pushLine), findsOneWidget, reason: 'his push-back stays above the deck');
  await waitChoiceDeck(t);
  await pickChoice(t, _rightCard(), proceed: false);
  await _pump(t, 800);
  expect(_live.phase, M8Phase.said);
  expect(await _pumpUntil(t, find.byKey(const ValueKey('why-deck'))), isTrue, reason: 'the reason deck ($i)');
  await _pump(t, 500);
  await _pickOne(t, L.whyRight[_live.why]!);
  await _pump(t, 2500);
}

/// The lesson file writes য়/ড়/ঢ় as one letter; the game writes base + nukta (owner rule).
String _nukta(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

M8Consumer _cons(M8Stage s) => M8Consumer(stage: s, look: 0, right: false, wording: 0, pushWording: 0);

/// A run over the three given stages; the first is at the ladder.
M8GrievanceRun _runOf(M8Stage first, {M8Stage? second, int cw = 0}) => M8GrievanceRun(
      M8Deal(consumers: [_cons(first), _cons(second ?? M8Stage.hasDocket), _cons(M8Stage.threatCase)], coworkerAt: 1, coworker: cw),
      rng: math.Random(5),
    );

/// A run whose first consumer has said it all (the file may move).
M8GrievanceRun _routeRun(M8Stage s, {int cw = 0}) => _runOf(s, cw: cw)
  ..startSpeaking()
  ..stopSpeaking();

/// A run at the reply deck (the file went to the right plank).
M8GrievanceRun _replyRun(M8Stage s) {
  final r = _routeRun(s)..pin(s.forum);
  r.sendFile();
  return r..openReply();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('rules', () {
    test('the six stages map to the three planks (S1, S2 → ডকেট; S3, S5 → CGRF; S4, S6 → অম্বুডসম্যান)', () {
      expect({for (final s in M8Stage.values) s: s.forum}, {
        M8Stage.noDocket: M8Forum.docket,
        M8Stage.hasDocket: M8Forum.docket,
        M8Stage.unsolved: M8Forum.cgrf,
        M8Stage.threatLineman: M8Forum.cgrf,
        M8Stage.cgrfUnhappy: M8Forum.ombud,
        M8Stage.threatCase: M8Forum.ombud,
      });
      expect(M8Forum.values.map((f) => f.index), [0, 1, 2]);
    });

    test('the deal: three different stages of six, three looks, both sides, the coworker anywhere with either push', () {
      final cw = <int>{};
      final pushes = <int>{};
      final sides = <bool>{};
      final sets = <String>{};
      final stagesSeen = <M8Stage>{};
      for (var s = 0; s < 300; s++) {
        final d = m8Deal(math.Random(s));
        expect(d.consumers, hasLength(3));
        expect(d.consumers.map((c) => c.stage).toSet(), hasLength(3), reason: 'seed $s');
        expect(d.consumers.map((c) => c.look).toSet(), hasLength(3));
        cw.add(d.coworkerAt);
        pushes.add(d.coworker);
        for (final c in d.consumers) {
          sides.add(c.right);
          stagesSeen.add(c.stage);
          expect(c.firstLine, isNotEmpty);
          expect(c.pushLine, isNotEmpty);
        }
        sets.add(d.consumers.map((c) => c.stage.index).join());
      }
      expect(cw, {0, 1, 2});
      expect(pushes, {0, 1});
      expect(sides, {true, false});
      expect(stagesSeen, M8Stage.values.toSet());
      expect(sets.length, greaterThan(20));
    });

    test('nothing moves before he has spoken; the file goes on a plank and back, judged only on পাঠান', () {
      final r = _runOf(M8Stage.unsolved);
      expect(r.pin(M8Forum.docket), isFalse, reason: 'he is still walking up');
      r.startSpeaking();
      expect(r.pin(M8Forum.docket), isFalse, reason: 'still speaking');
      r.stopSpeaking();
      expect(r.phase, M8Phase.route);
      expect(r.sendFile().ready, isFalse, reason: 'no file on a plank yet');
      expect(r.pin(M8Forum.ombud), isTrue);
      expect(r.pin(M8Forum.docket), isTrue, reason: 'lifted to another plank, nothing judged');
      expect(r.pin(null), isTrue);
      expect(r.pinned, isNull);
      expect(r.slips, 0);
    });

    test('the right plank: he pushes back once, then the reply deck (one honest line, two wrong)', () {
      for (final s in M8Stage.values) {
        final r = _routeRun(s)..pin(s.forum);
        final send = r.sendFile();
        expect(send.ready, isTrue);
        expect(send.mistake, isNull);
        expect(r.phase, M8Phase.pushing);
        expect(r.slips, 0);
        expect(r.reply('x').ready, isFalse, reason: 'no card before the deck opens');
        r.openReply();
        expect(r.phase, M8Phase.replying);
        expect(r.replyOptions, hasLength(3));
        expect(r.replyOptions.where((o) => o.correct), hasLength(1));
        expect(L.right[s], contains(r.replyOptions.firstWhere((o) => o.correct).textBn));
      }
    });

    test('a wrong plank is a slip: a leap ahead, or a step back; the file goes home, the same consumer stays', () {
      for (final s in M8Stage.values) {
        for (final f in M8Forum.values) {
          if (f == s.forum) continue;
          final r = _routeRun(s)..pin(f);
          final send = r.sendFile();
          expect(send.mistake, f.index > s.forum.index ? Mk.skipAhead : Mk.stepBehind, reason: '$s → $f');
          expect(r.slips, 1);
          expect(r.pinned, isNull);
          expect(r.phase, M8Phase.route);
          expect(r.index, 0);
          expect(r.attempt, 1);
          expect(r.thorough, isFalse);
        }
      }
    });

    test('the honest card settles him (a reason follows); the ladder tags what was caught', () {
      final tags = <M8Stage, String>{
        M8Stage.noDocket: L.caughtDocket,
        M8Stage.hasDocket: L.caughtDocket,
        M8Stage.unsolved: L.caughtRights,
        M8Stage.threatLineman: L.caughtRights,
        M8Stage.cgrfUnhappy: L.caughtOmbud,
        M8Stage.threatCase: L.caughtOmbud,
      };
      for (final s in M8Stage.values) {
        final r = _replyRun(s);
        final rep = r.reply(r.replyOptions.firstWhere((o) => o.correct).textBn);
        expect(rep.right, isTrue);
        expect(rep.mistake, isNull);
        expect(r.phase, M8Phase.said);
        expect(r.roundDone, isTrue);
        expect(r.slips, 0);
        expect(r.caught, containsAll([tags[s], L.caughtHonest]));
      }
    });

    test('each wrong card is its kind\'s slip; the deck stays; the same consumer', () {
      for (final t in M8Trap.values) {
        // A stage where this wrong card can be dealt.
        final s = M8Stage.values.firstWhere((x) => L.wrongPool(x).any((l) => L.trapOf(l, x) == t));
        final r = _replyRun(s);
        final line = L.wrongPool(s).firstWhere((l) => L.trapOf(l, s) == t);
        // Make the deck hold it.
        r.replyOptions = [...r.replyOptions.take(2), ChoiceOption(line, false)];
        final rep = r.reply(line);
        expect(rep.right, isFalse);
        expect(rep.mistake, Mk.forTrap(t));
        expect(rep.trap, t);
        expect(r.slips, 1);
        expect(r.phase, M8Phase.replying);
        expect(r.trapped, {t});
        expect(r.thorough, isFalse);
      }
      expect(Mk.forTrap(M8Trap.verbal), Mk.verbal);
      expect(Mk.forTrap(M8Trap.promise), Mk.falsePromise);
      expect(Mk.forTrap(M8Trap.argue), Mk.arguing);
      expect(Mk.forTrap(M8Trap.caseMyth), Mk.caseMyth);
      expect(Mk.forTrap(M8Trap.finalWord), Mk.finalWord);
      expect(Mk.forTrap(M8Trap.noComplain), Mk.noComplain);
      expect(Mk.forTrap(M8Trap.wrongForum), Mk.wrongForum);
    });

    test('the reason fits what was done: S1 follows the line, a promise slip drops "why no promise"', () {
      final lib = L.right[M8Stage.noDocket]!;
      final c = _cons(M8Stage.noDocket);
      expect(m8WhyFor(c, lib[0], promised: false), M8Why.docket);
      expect(m8WhyFor(c, lib[1], promised: false), M8Why.centre);
      expect(m8WhyFor(_cons(M8Stage.hasDocket), L.right[M8Stage.hasDocket]!.first, promised: false), M8Why.docket);
      expect(m8WhyFor(_cons(M8Stage.cgrfUnhappy), '', promised: false), M8Why.ombud);
      expect(m8WhyFor(_cons(M8Stage.threatLineman), '', promised: false), M8Why.fear);
      final coin = M8Consumer(stage: M8Stage.unsolved, look: 0, right: false, wording: 0, pushWording: 0, promiseCoin: true);
      expect(m8WhyFor(coin, '', promised: false), M8Why.promise);
      expect(m8WhyFor(coin, '', promised: true), M8Why.cgrf);
      final coin6 = M8Consumer(stage: M8Stage.threatCase, look: 0, right: false, wording: 0, pushWording: 0, promiseCoin: true);
      expect(m8WhyFor(coin6, '', promised: false), M8Why.promise);
      expect(m8WhyFor(coin6, '', promised: true), M8Why.ombud);
    });

    test('listening to him is a slip here, never deadly (X2/B1); the mark falls 15 a slip', () {
      expect(Mk.listenCase.deadly, isFalse);
      expect(Mk.listenJob.deadly, isFalse);
      final a = _routeRun(M8Stage.noDocket);
      expect(a.pushSlip(), Mk.listenCase);
      final b = _routeRun(M8Stage.noDocket, cw: 1);
      expect(b.pushSlip(), Mk.listenJob);
      expect(b.slips, 1);
      expect(b.percent, 85);
      b
        ..pushSlip()
        ..pushSlip();
      expect(b.percent, 55);
      expect(b.passed, isFalse, reason: 'not finished');
    });

    test('a play of three consumers all right passes with 100', () {
      final r = _runOf(M8Stage.noDocket, second: M8Stage.unsolved);
      for (var i = 0; i < 3; i++) {
        r
          ..startSpeaking()
          ..stopSpeaking()
          ..pin(r.consumer.forum);
        expect(r.sendFile().mistake, isNull);
        r.openReply();
        expect(r.reply(r.replyOptions.firstWhere((o) => o.correct).textBn).right, isTrue);
        r.next();
      }
      expect(r.done, isTrue);
      expect(r.percent, 100);
      expect(r.passed, isTrue);
    });
  });

  group('content', () {
    test('libraries: the reply cards in one length band (1.3x); two honest lines per stage, eight wrong kinds of line, no duplicates', () {
      final all = [...L.allRightLines, ...L.allTrapLines];
      expect(all.toSet(), hasLength(all.length), reason: 'no line twice');
      for (final s in M8Stage.values) {
        expect(L.right[s], hasLength(2), reason: '$s');
        expect(L.first[s], hasLength(2));
        expect(L.push[s], hasLength(2));
      }
      expect(M8Trap.values.where((t) => t != M8Trap.wrongForum).every((t) => L.traps[t]!.isNotEmpty), isTrue);
      expect(L.allTrapLines.length, greaterThanOrEqualTo(6));
      expectSameLength('reply lines', all);
      for (final s in M8Stage.values) {
        final pool = L.wrongPool(s);
        expectLibrary('reply $s', L.right[s]!, pool);
        // Another consumer's line only, never this plank's own honest line.
        for (final line in pool) {
          final t = L.trapOf(line, s);
          expect(t, isNotNull, reason: line);
          if (t == M8Trap.wrongForum) {
            expect(M8Stage.values.where((x) => L.right[x]!.contains(line) && x.forum == s.forum), isEmpty, reason: '$s: $line');
          }
        }
        for (final line in L.right[s]!) {
          expect(L.trapOf(line, s), isNull, reason: 'an honest line is never a wrong card for its own stage');
        }
        for (var k = 0; k < 12; k++) {
          final deal = m8DealReply(s, math.Random(k));
          expect(deal, hasLength(3));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          expectSameLength('deal $s', [for (final o in deal) o.textBn]);
        }
      }
      // The deck varies over plays (wrong cards from all kinds, other steps' lines too).
      final seen = <String>{};
      for (var k = 0; k < 120; k++) {
        seen.addAll([for (final o in m8DealReply(M8Stage.noDocket, math.Random(k))) if (!o.correct) o.textBn]);
      }
      expect(seen.length, greaterThan(10));
    });

    test('libraries: the reasons — same length, big enough, never a rule marked wrong; six questions', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      expect(L.whyQ.keys.toSet(), M8Why.values.toSet());
      for (final w in M8Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(L.whyQ.values, [
        'কেন ডকেট নম্বর চাইলেন?',
        'কেন 1912 বা CCC-র কথা বললেন?',
        'কেন CGRF-এর কথা বললেন?',
        'কেন অম্বুডসম্যানের কথা বললেন?',
        'কেন “কালই হয়ে যাবে” বললেন না?',
        'কমপ্লেইনের কথায় ভয় পেলেন না কেন?',
      ]);
      for (final cw in L.allCoworkers) {
        expectSameLength('choice', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong, minRight: 3);
      }
    });

    test('English digits only; jol not pani; base + nukta; ON/OFF; ডেড not মৃত; every mistake has its picture; no deadly; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.needFile,
        ...L.tapWhy,
        L.send,
        L.fileLabel,
        ...L.rungNames,
        ...L.rungShown,
        for (var n = 1; n <= 3; n++) L.consumer(n),
        for (final v in L.first.values) ...v,
        for (final v in L.push.values) ...v,
        ...L.allRightLines,
        ...L.allTrapLines,
        ...L.calmReaction,
        L.routeReaction,
        ...L.trapReaction.values,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        L.callHeld,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtDocket,
        L.caughtRights,
        L.caughtOmbud,
        L.caughtHonest,
        L.caughtCall,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(RegExp('[Ѐ-ӿऀ-ॿ஀-௿؀-ۿ]').hasMatch(l), isFalse, reason: l);
        expect(RegExp('(^| )(অন|অফ)( |\$)').hasMatch(l), isFalse, reason: 'ON/OFF in English letters: $l');
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp('(এলটি|এইচটি|কেভি)').hasMatch(l), isFalse, reason: 'LT/HT/kV in English letters: $l');
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'M8-1: grievance = slips only');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.6/m8_grievance_reply/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m8_grievance_reply/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => n != '.gitkeep').toSet();
      expect(files, used);
      expect(m8GrievanceReplyPacks.keys, ['do_8_6_a']);
    });

    test('the slips are the spec\'s; the coworker\'s lines are the lesson\'s myths word for word', () {
      expect(Mk.all.map((m) => m.key.split('/').last).toSet(), {
        'skip-ahead',
        'step-behind',
        'verbal',
        'false-promise',
        'arguing',
        'case-myth',
        'final-word',
        'no-complain',
        'wrong-forum',
        'listen-case',
        'listen-job',
      });
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync(encoding: utf8)) as List<dynamic>;
      final l86 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.6');
      final myths = ((l86['content'] as Map)['myth_buster'] as Map)['myths'] as List<dynamic>;
      expect(_nukta((myths[0] as Map)['myth'] as String), L.coworkerCase.line);
      expect(L.coworkerJob.line, startsWith(_nukta((myths[1] as Map)['myth'] as String)), reason: 'myth 2 word for word, then the shortcut');
      expect(L.coworkerJob.line, contains('কালই হয়ে যাবে'));
    });

    test('rival lines: his exit is recorded; his two pushes and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.coworkerCase.line, L.coworkerJob.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll([
            L.intro,
            ...L.tasks,
            L.needFile,
            ...L.whyQ.values,
            'ওর কথা রাখবেন?',
            L.callHeld,
            L.allSet,
            L.fail,
            for (final m in Mk.all) m.textBn,
          ]));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_grievance_reply: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the world: the ladder, the file, the figures and the bubble leave the lane clear on every screen height', () {
      for (final h in [600.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M8Geo.forScene(h, 0);
        expect(g.bubble.top, greaterThan(115));
        for (final right in [false, true]) {
          final c = g.consumer(right);
          expect(c.right, lessThanOrEqualTo(253), reason: 'h $h: clear of the corner guide');
          expect(c.overlaps(g.trainee), isFalse);
          expect(c.overlaps(g.board), isFalse);
          expect(c.bottom, g.floorY);
          expect(g.cloud(right).top, greaterThanOrEqualTo(g.bubble.bottom + 4), reason: 'h $h: the cloud under the bubble');
        }
        expect(g.trainee.overlaps(g.board), isFalse);
        expect(g.van.top, greaterThanOrEqualTo(g.bubble.bottom), reason: 'h $h: the van under the bubble');
        for (var i = 0; i < 3; i++) {
          expect(g.board.contains(g.rung(i).topLeft) && g.board.contains(g.rung(i).bottomRight), isTrue, reason: 'plank $i on the board');
          expect(g.rung(i).contains(g.fileOnRung(i).topLeft) && g.rung(i).contains(g.fileOnRung(i).bottomRight), isTrue);
          if (i > 0) expect(g.rung(i).bottom, lessThan(g.rung(i - 1).top));
        }
        expect(g.floorY, lessThan(h - 180), reason: 'h $h: the deck stands below the lane');
      }
    });
  });

  group('page', () {
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    testWidgets('the guide comes first: a tap does not skip him; then the ladder, the file, and the consumer\'s words', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M8GrievanceReplyPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1500);
      for (var i = 0; i < 3; i++) {
        expect(_label(L.rungNames[i]), findsOneWidget);
        expect(find.byKey(ValueKey('rung-$i')), findsOneWidget);
      }
      expect(_label(L.fileLabel), findsOneWidget);
      expect(_label(L.send), findsNothing, reason: 'no পাঠান until the file is on a plank');
      final d = m8Deal(math.Random(3));
      expect(find.text(d.consumers.first.firstLine), findsOneWidget, reason: 'his words');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('he speaks first (held); the file does not move until he has said it; tapping the guide repeats the task, a different way', (t) async {
      final c = await _open(t, 5);
      await _pump(t, 1500);
      expect(_live.phase, M8Phase.speaking);
      await _dragFile(t, 0);
      expect(_live.pinned, isNull, reason: 'a drag while he speaks moves nothing');
      final guide = find.byKey(const ValueKey('hud-guide'));
      final said = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        said.add(c.read(guideDirectorProvider).line);
      }
      expect(said.every((l) => l.contains(L.askListen)), isTrue, reason: '$said');
      expect(said.first, isNot(said.last));
      await _untilPhase(t, M8Phase.route);
      expect(c.read(guideDirectorProvider).line, contains(L.askRoute));
      await _close(t, c);
    });

    // A play with the coworker on one consumer and one with him elsewhere, both pushes.
    final flowSeeds = [
      _seedWhere((d) => d.coworkerAt == 0 && d.coworker == 0),
      _seedWhere((d) => d.coworkerAt == 2 && d.coworker == 1),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three consumers, file to the right plank, the honest card, a reason each, the coworker refused → pass', (t) async {
        final d = m8Deal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playConsumer(t, d, i);
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.6/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.6/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtHonest), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final plain = _seedWhere((d) => d.coworkerAt != 0);
    testWidgets('a wrong plank: nothing before পাঠান; then the card, the file goes home, he shouts back, the same consumer goes on', (t) async {
      final c = await _open(t, plain);
      await _untilPhase(t, M8Phase.route);
      final right = _live.consumer.forum.index;
      final wrong = right == 0 ? 1 : 0;
      await _dragFile(t, wrong);
      expect(_live.pinned, M8Forum.values[wrong]);
      expect(find.byType(MistakeCard), findsNothing, reason: 'nothing is judged on the plank');
      expect(_label(L.send), findsOneWidget);
      await _tapSend(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(wrong > right ? Mk.skipAhead.textBn : Mk.stepBehind.textBn), findsOneWidget);
      expect(find.text(L.routeReaction), findsOneWidget);
      expect(_live.pinned, isNull, reason: 'the file went home');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.index, 0);
      expect(_live.phase, M8Phase.route);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      await _dragFile(t, right);
      expect(_live.pinned, M8Forum.values[right]);
      await _close(t, c);
    });

    testWidgets('the file can be lifted from one plank to another and back to the hand without a cost', (t) async {
      final c = await _open(t, plain);
      await _untilPhase(t, M8Phase.route);
      await _dragFile(t, 1);
      expect(_live.pinned, M8Forum.cgrf);
      await _dragFile(t, 2);
      expect(_live.pinned, M8Forum.ombud);
      await _dragFile(t, 0);
      expect(_live.pinned, M8Forum.docket);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a wrong card: the card, he flashes red, the deck stays with that card red; the honest card still settles him', (t) async {
      final c = await _open(t, plain);
      await _untilPhase(t, M8Phase.route);
      await _dragFile(t, _live.consumer.forum.index);
      await _tapSend(t);
      await _untilPhase(t, M8Phase.replying);
      await waitChoiceDeck(t);
      final wrong = _live.replyOptions.firstWhere((o) => !o.correct).textBn;
      final trap = L.trapOf(wrong, _live.consumer.stage)!;
      await pickChoice(t, wrong, proceed: false);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.forTrap(trap).textBn), findsOneWidget);
      expect(find.text(L.trapReaction[trap]!), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.phase, M8Phase.replying);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the deck stays');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.forTrap(trap).key);
      await pickChoice(t, _rightCard(), proceed: false);
      await _pump(t, 800);
      expect(_live.phase, M8Phase.said);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, plain);
      await _untilPhase(t, M8Phase.route);
      final right = _live.consumer.forum.index;
      final wrong = right == 0 ? 1 : 0;
      for (var i = 0; i < 3; i++) {
        await _dragFile(t, wrong);
        await _tapSend(t);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final cwFirst = _seedWhere((d) => d.coworkerAt == 0 && d.coworker == 1);
    testWidgets('listening to him is a slip (his myth), never a freeze; the play goes on', (t) async {
      final c = await _open(t, cwFirst);
      await _untilPhase(t, M8Phase.route);
      await _dragFile(t, _live.consumer.forum.index);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final script = _live.deal.script;
      final wrong = [for (final x in script.wrong) if (find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty) x];
      expect(wrong, isNotEmpty);
      await t.tap(find.byKey(ValueKey('deal-${wrong.first}')), warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(Mk.listenJob.textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.listenJob.key);
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapSend(t);
      expect(await _untilPhaseOrDeck(t), isTrue, reason: 'the file still goes on');
      await _close(t, c);
    });

    testWidgets('a fast play: পাঠান waits for the coworker; he cuts in at once; after him it works', (t) async {
      final c = await _open(t, cwFirst);
      await _untilPhase(t, M8Phase.route);
      await _dragFile(t, _live.consumer.forum.index);
      // At once, well inside his 1.2–2.4 s timer.
      await _tapSend(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.phase, M8Phase.route, reason: 'the file was not sent');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickOne(t, _live.deal.script.right, proceed: false);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _tapSend(t);
      expect(_live.phase.index, greaterThanOrEqualTo(M8Phase.pushing.index), reason: 'after him পাঠান works');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch: no file, no পাঠান, no slip', (t) async {
      final c = await _open(t, plain);
      await _untilPhase(t, M8Phase.route);
      await _dragFile(t, _live.consumer.forum.index);
      await _tapSend(t);
      await _untilPhase(t, M8Phase.replying);
      await waitChoiceDeck(t);
      await pickChoice(t, _rightCard(), proceed: false);
      await _pump(t, 800);
      expect(_live.phase, M8Phase.said);
      // The ◆ on the table, the deck open at once: the file and the planks are shielded.
      expect(_label(L.send), findsNothing);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(200, 300));
        await t.pump(const Duration(milliseconds: 150));
      }
      await _dragFile(t, 0);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(await _pumpUntil(t, find.byKey(const ValueKey('why-deck'))), isTrue);
      await _pump(t, 500);
      await _pickOne(t, L.whyRight[_live.why]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: none while he speaks; the file waiting a sweep over the three planks (no tap); on a plank a tap on পাঠান', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, plain);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 1500);
      expect(_live.phase, M8Phase.speaking);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(30, 400));
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isFalse, reason: 'while he speaks: no hand');
      await _untilPhase(t, M8Phase.route);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the file waiting');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep or a nudge presses nothing');
      expect(scene().debugOptions.length, 3, reason: 'a sweep over every plank alike');
      expect(find.byType(MistakeCard), findsNothing);
      await _dragFile(t, 1);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the file on a plank');
      expect(scene().debugOptions, isEmpty, reason: 'a tap on the one way on');
      await t.tapAt(const Offset(30, 400));
      await t.pump(const Duration(milliseconds: 200));
      expect(scene().showing, isFalse, reason: 'any touch hides it');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });
  });
}

/// True once the file has gone on (his push-back or the reply deck is up).
Future<bool> _untilPhaseOrDeck(WidgetTester t) async {
  for (var ms = 0; ms < 20000; ms += 100) {
    if (_live.phase.index >= M8Phase.pushing.index) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return _live.phase.index >= M8Phase.pushing.index;
}
