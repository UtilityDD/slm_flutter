// Lesson 5.1 ('লাইন ট্রিপ করেছে'—প্রথম কাজ কী?), কাজ 1 "কন্ট্রোল রুমের
// ফোন": the rules (the four lesson questions asked and made clear before the
// hang-up; the suspect and the start section from the lesson's examples; the
// briefing), the deal (two of three examples, storm calls instant, clues never
// conflicting), the libraries, the coworker's line (lesson myth 2 word for
// word), and the level in the shell: the guide first, tapping the guide, a
// full clean play with the coworker refused (both calls he can come in), a
// hang-up slip that keeps the call, wrong pin / van slips, three slips, the
// deadly freeze (listening to him), the gesture hand (a nudge or a sweep,
// never an answer). Idle perf: test/perf/m5_trip_call_perf_test.dart.
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
import 'package:slm_flutter/features/game/m5_trip_call.dart';
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
  rungId: '5.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m5TripCallPacks['do_5_1_a']!;

/// The new art is not in the bundle until the director wires it: tests read
/// it from disk when the bundle does not have it.
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

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  await waitChoiceDeck(t);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M5TripGeo get _geo => M5TripGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0));
Offset _s(Offset design) => design * _k;

Future<void> _drag(WidgetTester t, Offset fromDesign, Offset toDesign) async {
  await t.dragFrom(_s(fromDesign), _s(toDesign) - _s(fromDesign));
  await _pump(t, 300);
}

Future<void> _pickUp(WidgetTester t) => _drag(t, _geo.handsetRest.center, _geo.handsetRest.center - const Offset(0, 64));
Future<void> _hangUpDrag(WidgetTester t) => _drag(t, _geo.handsetUp.center, _geo.handsetUp.center + const Offset(0, 64));

Future<void> _ask(WidgetTester t, M5TripTopic topic) async {
  await t.tap(_label(M5TripLines.tile[topic]!));
  await _pump(t, 250);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5TripCallPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 2500);
}

/// Asks every required question (probing only the vague ones).
Future<void> _askAll(WidgetTester t, M5TripCall call) async {
  for (final topic in m5TripRequired) {
    await _ask(t, topic);
    if (call.vague.contains(topic)) {
      expect(find.text(M5TripLines.vagueAnswer(call, topic)), findsWidgets, reason: 'the vague answer stands in the notes');
      await _ask(t, topic);
    }
  }
}

/// One call played clean (the coworker refused in his call).
Future<void> _playCall(WidgetTester t, M5TripDeal deal, int i) async {
  final call = deal.calls[i];
  if (i > 0) await _pump(t, 2600); // the time card
  await _pickUp(t);
  expect(_label(M5TripLines.tile[M5TripTopic.how]!), findsOneWidget, reason: 'call $i: the tiles are up');
  await _askAll(t, call);
  await _hangUpDrag(t);
  if (deal.coworkerCall == i) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue, reason: 'he comes on the hang-up');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 400);
    await _pickRight(t, M5TripLines.coworker.right);
    await _pump(t, 2600);
  }
  if (i == 0) {
    await _reason(t, M5TripLines.askWhy);
  } else {
    await _pump(t, 2200);
  }
  // The pin on the suspect.
  final card = call.cards.indexOf(call.suspect);
  await _drag(t, _geo.pinHome, _geo.card(card).center);
  await _reason(t, M5TripLines.pinWhy[call.kase]!);
  // The van on the start section.
  final at = call.map.indexOf(call.start);
  await _drag(t, _geo.vanHome, _geo.section(at).center);
  await _reason(t, M5TripLines.vanWhy(call));
}

int _seedWhere(bool Function(M5TripDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5TripDeal(math.Random(s))));

M5TripRun _talking(M5TripDeal d) => M5TripRun(d)..pickUp();

void main() {
  group('rules', () {
    test('deals: two of the three examples; storm calls instant from the trees; clues never conflict; plays differ', () {
      final seen = <String>{};
      final cases = <M5TripCase>{};
      for (var s = 0; s < 120; s++) {
        final d = m5TripDeal(math.Random(s));
        expect(d.calls, hasLength(2));
        expect(d.calls[0].kase, isNot(d.calls[1].kase));
        expect(d.calls[0].feeder, isNot(d.calls[1].feeder));
        expect(d.coworkerCall, inInclusiveRange(0, 1));
        for (final c in d.calls) {
          cases.add(c.kase);
          expect(c.feeder, inInclusiveRange(1, 9));
          expect(c.vague, hasLength(2));
          expect(m5TripRequired.containsAll(c.vague), isTrue);
          expect(c.tiles.toSet(), M5TripTopic.values.toSet());
          expect(c.map.toSet(), M5TripArea.values.toSet());
          expect(c.cards.toSet(), M5TripSuspect.values.toSet());
          if (c.kase == M5TripCase.storm) {
            expect(c.instant, isTrue, reason: 'a storm trip answers তৎক্ষণাৎ');
            expect(c.start, M5TripArea.trees);
            expect(c.clueArea, M5TripArea.trees, reason: 'a report in a storm never points away from the trees');
          } else {
            expect(c.clueArea, isNot(M5TripArea.trees));
            expect(c.clue, isNot(M5TripClue.none), reason: 'the start needs a report or the logbook');
            expect(c.start, c.clueArea);
          }
          expect(c.shots, c.kase == M5TripCase.recloses ? inInclusiveRange(2, 3) : 1);
          if (c.kase == M5TripCase.clear) expect(c.day, isTrue, reason: 'the lesson: a clear day');
        }
        final calls = [for (final c in d.calls) '${c.kase.name}${c.feeder}${c.clue.name}${c.clueArea.name}${c.vague.map((v) => v.name)}${c.map.first.name}${c.cards.first.name}'];
        seen.add('${calls.join('|')}${d.coworkerCall}');
      }
      expect(cases, M5TripCase.values.toSet());
      expect(seen.length, greaterThan(100));
    });

    test('answers: a vague first answer, a clear one on the probe; the clue names the same section in both places', () {
      for (var s = 0; s < 60; s++) {
        for (final c in m5TripDeal(math.Random(s)).calls) {
          final name = c.names[c.clueArea]!;
          final cust = M5TripLines.clearAnswer(c, M5TripTopic.customer);
          final log = M5TripLines.clearAnswer(c, M5TripTopic.logbook);
          final hasCust = c.clue == M5TripClue.customer || c.clue == M5TripClue.both;
          final hasLog = c.clue == M5TripClue.logbook || c.clue == M5TripClue.both;
          expect(cust.contains(name), hasCust, reason: cust);
          expect(log.contains(name), hasLog, reason: log);
          for (final other in M5TripArea.values.where((a) => a != c.clueArea)) {
            expect(cust.contains(c.names[other]!) || log.contains(c.names[other]!), isFalse, reason: 'no second section named');
          }
          if (c.kase == M5TripCase.storm) expect(M5TripLines.clearAnswer(c, M5TripTopic.how), contains('তৎক্ষণাৎ'));
          expect(M5TripLines.clearAnswer(c, M5TripTopic.relay), contains(c.kase == M5TripCase.storm ? 'আর্থ ফল্ট' : 'ওভারকারেন্ট'));
          for (final v in c.vague) {
            final vague = M5TripLines.vagueAnswer(c, v);
            expect(vague, isNot(M5TripLines.clearAnswer(c, v)));
            expect(M5TripLines.probe[v], isNotNull);
          }
        }
      }
    });

    test('the call: a vague topic answers vaguely, a second tap probes; hanging up unasked or vague is a slip and the call goes on', () {
      final d = m5TripDeal(math.Random(3));
      final call = d.calls[0];
      final r = _talking(d);
      expect(r.stage, M5TripStage.talk);
      expect(r.hangUp(), M5TripMistakes.unasked);
      expect(r.stage, M5TripStage.talk, reason: 'the call goes on');
      for (final topic in m5TripRequired) {
        expect(r.ask(topic), call.vague.contains(topic) ? M5TripReply.vague : M5TripReply.first);
      }
      expect(r.notesComplete, isFalse);
      expect(r.hangUp(), M5TripMistakes.vagueKept);
      final v = call.vague.first;
      expect(r.ask(v), M5TripReply.probe);
      expect(r.hangUp(), M5TripMistakes.vagueKept, reason: 'one still vague');
      r.ask(call.vague.last);
      expect(r.hangUp(), isNull);
      expect(r.stepDone, isTrue);
      expect(r.slips, 3);
      expect(r.caught, contains(M5TripLines.caughtProbe));
      expect(r.caught, isNot(contains(M5TripLines.caughtAsk)));
      expect(r.asked.toSet(), m5TripRequired);
    });

    test('the logbook is required in every deal (lesson pro tip 1); the five others alone are not enough', () {
      expect(m5TripRequired, contains(M5TripTopic.logbook));
      expect(m5TripRequired, isNot(contains(M5TripTopic.opinion)));
      for (var s = 0; s < 20; s++) {
        final d = m5TripDeal(math.Random(s));
        final r = _talking(d);
        for (final topic in m5TripRequired.where((x) => x != M5TripTopic.logbook)) {
          r.ask(topic);
          if (d.calls[0].vague.contains(topic)) r.ask(topic);
        }
        expect(r.hangUp(), M5TripMistakes.unasked, reason: 'seed $s: no logbook');
        r.ask(M5TripTopic.logbook);
        if (d.calls[0].vague.contains(M5TripTopic.logbook)) r.ask(M5TripTopic.logbook);
        expect(r.hangUp(), isNull);
      }
      expect(M5TripMistakes.unasked.textBn, contains('লগবুক'));
    });

    test('no free "ask everything twice": a needless re-ask costs the thorough bonus and the quick bonus; probing only the vague ones keeps it', () {
      for (var s = 0; s < 20; s++) {
        final d = m5TripDeal(math.Random(s));
        final call = d.calls[0];
        // Every tile twice.
        final lazy = _talking(d);
        for (final topic in m5TripRequired) {
          lazy.ask(topic);
          expect(lazy.ask(topic), call.vague.contains(topic) ? M5TripReply.probe : M5TripReply.again);
        }
        expect(lazy.stepWaste, m5TripRequired.length - 2);
        expect(lazy.hangUp(), isNull, reason: 'complete notes still pass the check');
        expect(lazy.thorough, isFalse);
        expect(lazy.wasted, greaterThan(0), reason: 'no quick bonus');
        expect(lazy.caught, isNot(contains(M5TripLines.caughtAsk)));
        expect(lazy.caught, isNot(contains(M5TripLines.caughtProbe)));
        lazy.next();
        expect(lazy.stepWaste, 0, reason: 'the next step starts clean');
        expect(lazy.wasted, greaterThan(0), reason: 'the play remembers');
        // Only the vague ones probed.
        final sharp = _talking(d);
        for (final topic in m5TripRequired) {
          expect(sharp.ask(topic), call.vague.contains(topic) ? M5TripReply.vague : M5TripReply.first);
          if (call.vague.contains(topic)) expect(sharp.ask(topic), M5TripReply.probe);
        }
        expect(sharp.hangUp(), isNull);
        expect(sharp.thorough, isTrue);
        expect(sharp.wasted, 0);
        expect(sharp.caught, containsAll([M5TripLines.caughtAsk, M5TripLines.caughtProbe]));
        // The optional tile once is not needless.
        final curious = _talking(d)..ask(M5TripTopic.opinion);
        expect(curious.stepWaste, 0);
      }
      final c0 = m5TripDeal(math.Random(1)).calls[0];
      final ans = M5TripLines.clearAnswer(c0, M5TripTopic.weather);
      expect(M5TripLines.again(ans), allOf(contains(ans), startsWith('আগেই তো বললাম')));
    });

    test('pin, van, next call, briefing: the wrong card / section is a slip of its own; the play passes', () {
      final d = m5TripDeal(math.Random(5));
      final r = _talking(d);
      for (var i = 0; i < 2; i++) {
        final call = d.calls[i];
        if (i == 1) {
          expect(r.stage, M5TripStage.ring);
          expect(r.heard, isEmpty, reason: 'a new page');
          r.pickUp();
        }
        for (final topic in m5TripRequired) {
          r.ask(topic);
          if (call.vague.contains(topic)) r.ask(topic);
        }
        expect(r.hangUp(), isNull);
        r.next();
        expect(r.stage, M5TripStage.pin);
        final wrong = M5TripSuspect.values.firstWhere((s) => s != call.suspect);
        expect(r.pin(wrong), M5TripMistakes.suspectFor(call.kase));
        expect(r.pin(call.suspect), isNull);
        r.next();
        expect(r.stage, M5TripStage.van);
        final off = M5TripArea.values.firstWhere((a) => a != call.start);
        expect(r.van(off), call.kase == M5TripCase.storm ? M5TripMistakes.startTrees : M5TripMistakes.startReport);
        expect(r.van(call.start), isNull);
        r.next();
      }
      expect(r.stage, M5TripStage.brief);
      expect(r.slips, 4);
      expect(r.brief(true), isNull);
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isFalse, reason: '4 slips = 40 %');
      final clean = _talking(d);
      for (var i = 0; i < 2; i++) {
        if (i == 1) clean.pickUp();
        for (final topic in m5TripRequired) {
          clean.ask(topic);
          if (d.calls[i].vague.contains(topic)) clean.ask(topic);
        }
        clean
          ..hangUp()
          ..next()
          ..pin(d.calls[i].suspect)
          ..next()
          ..van(d.calls[i].start)
          ..next();
      }
      expect(clean.brief(false), M5TripMistakes.brief);
      clean
        ..brief(true)
        ..next();
      expect(clean.passed, isTrue);
      expect(clean.percent, 85);
      expect(clean.caught, containsAll([M5TripLines.caughtAsk, M5TripLines.caughtSuspect, M5TripLines.caughtStart, M5TripLines.caughtBrief]));
    });

    test('the suspect and the start follow the lesson examples', () {
      M5TripCall of(M5TripCase k) => m5TripDeal(math.Random(_seedWhere((d) => d.calls.any((c) => c.kase == k)))).calls.firstWhere((c) => c.kase == k);
      expect(of(M5TripCase.storm).suspect, M5TripSuspect.branch);
      expect(of(M5TripCase.clear).suspect, M5TripSuspect.bird);
      expect(of(M5TripCase.recloses).suspect, M5TripSuspect.clash);
      expect(M5TripLines.vanWhy(of(M5TripCase.storm)), M5TripLines.vanTrees);
      for (var s = 0; s < 40; s++) {
        for (final c in m5TripDeal(math.Random(s)).calls.where((c) => c.kase != M5TripCase.storm)) {
          expect(M5TripLines.vanWhy(c), isNotEmpty);
          expect(M5TripLines.vanWhy(c).toSet().intersection(M5TripLines.vanTrees.toSet()), isEmpty);
        }
      }
    });

    test('English digits only; no পানি; every mistake has its picture; one deadly; keys unique', () {
      final calls = [for (var s = 0; s < 30; s++) ...m5TripDeal(math.Random(s)).calls];
      final all = <String>[
        M5TripLines.intro,
        ...M5TripLines.tasks,
        ...M5TripLines.tile.values,
        ...M5TripLines.probe.values,
        ...M5TripLines.allWhyRight,
        ...M5TripLines.myths,
        ...M5TripLines.briefRight,
        ...M5TripLines.briefWrong,
        ...M5TripLines.coworker.recordedLines,
        ...M5TripLines.coworker.right,
        ...M5TripLines.coworker.wrong,
        ...M5TripLines.coworker.asks,
        for (final m in M5TripMistakes.all) m.textBn,
        for (final c in calls) ...[
          M5TripLines.opening(c.feeder),
          c.clockText,
          for (final topic in M5TripTopic.values) M5TripLines.clearAnswer(c, topic),
          for (final v in c.vague) M5TripLines.vagueAnswer(c, v),
        ],
        M5TripLines.lost,
        M5TripLines.hello,
        M5TripLines.allSet,
        M5TripLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5TripMistakes.all.where((m) => m.deadly), [M5TripMistakes.recharge]);
      expect(M5TripMistakes.all.map((m) => m.key).toSet(), hasLength(M5TripMistakes.all.length));
      for (final m in M5TripMistakes.all) {
        expect(m.key, startsWith('5.1/m5_trip_call/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m5TripCallPacks.keys, ['do_5_1_a']);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...M5TripLines.allWhyRight, ...M5TripLines.myths]);
      expect(M5TripLines.myths.toSet().intersection(M5TripLines.allWhyRight.toSet()), isEmpty);
      final rights = <String, List<String>>{
        'ask': M5TripLines.askWhy,
        for (final k in M5TripCase.values) 'pin ${k.name}': M5TripLines.pinWhy[k]!,
        'van trees': M5TripLines.vanTrees,
        'van customer': M5TripLines.vanCustomer,
        'van logbook': M5TripLines.vanLogbook,
      };
      for (final e in rights.entries) {
        expectLibrary(e.key, e.value, M5TripLines.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(e.value, M5TripLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('brief', [...M5TripLines.briefRight, ...M5TripLines.briefWrong]);
      expectLibrary('brief', M5TripLines.briefRight, M5TripLines.briefWrong);
      final cw = M5TripLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      // The tiles: all alike in length class (no tile stands out as "the one").
      expect(M5TripLines.tile.values.toSet(), hasLength(7));
    });

    test('rival lines: his push is lesson 5.1 myth 2 word for word; his exit is recorded; the push is listed for recording', () {
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      final l51 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '5.1');
      final myths = ((l51['content'] as Map<String, dynamic>)['myth_buster'] as Map<String, dynamic>)['myths'] as List<dynamic>;
      // The lesson file spells য়/ড়/ঢ় precomposed; the app (and the clip map)
      // spells them decomposed — the same letters.
      String norm(String s) => s.replaceAll('য়', 'য়').replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়');
      expect(norm(M5TripLines.coworker.line), norm((myths[1] as Map<String, dynamic>)['myth'] as String));
      expect(M5TripLines.coworker.recordedLines, [M5TripLines.coworker.line, M5TripLines.coworkerExit]);
      expect(LearnVoice.resolve(M5TripLines.coworkerExit, rival: true), isNotNull);
    });

    test('board geometry: sections, cards and the token homes never overlap; the hint nudges reach no card or section', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M5TripGeo.forScene(h);
        final targets = [for (var i = 0; i < 4; i++) g.section(i), for (var i = 0; i < 3; i++) g.card(i)];
        for (final r in [...targets, g.pinHit, g.vanHit, g.handsetRest, g.notepad, g.window, g.clock]) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h $r');
        }
        for (final r in targets) {
          expect(r.top, greaterThan(90), reason: 'below the header');
          expect(r.overlaps(g.pinHit) || r.overlaps(g.vanHit), isFalse, reason: 'h $h: tokens clear of $r');
        }
        for (var i = 0; i < targets.length; i++) {
          for (var j = i + 1; j < targets.length; j++) {
            expect(targets[i].overlaps(targets[j]), isFalse, reason: 'h $h: $i/$j');
          }
        }
        Offset end(Offset from, Offset dir, double travel) => from + dir / dir.distance * travel;
        final pinEnd = end(g.pinHome, const Offset(-1, -0.2), 22);
        final vanEnd = end(g.vanHome, const Offset(0, -1), 26);
        for (final r in targets) {
          expect(r.contains(pinEnd) || r.contains(vanEnd), isFalse, reason: 'h $h: a hint nudge ends on $r');
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

    testWidgets('the guide comes first: a tap does not skip him; then the phone', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5TripCallPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5TripLines.handset), findsOneWidget);
      expect(_label(M5TripLines.tile[M5TripTopic.how]!), findsNothing, reason: 'no tiles before the handset is up');
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
      expect(lines.every((l) => l.contains(M5TripLines.askPhone)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final cw in [0, 1]) {
      testWidgets('flow (coworker in call ${cw + 1}): two calls asked clean, pin, van, refuse him, briefing → pass', (t) async {
        final seed = _seedWhere((d) => d.coworkerCall == cw);
        final deal = m5TripDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _playCall(t, deal, 0);
        await _playCall(t, deal, 1);
        // The briefing at the van.
        expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
        await _pump(t, 700);
        await _pickRight(t, M5TripLines.briefRight);
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.1/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.1/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5TripLines.caughtCall), findsOneWidget);
        expect(find.text(M5TripLines.caughtProbe), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('hanging up unasked is a slip: its card, then the operator asks on and the tiles stay', (t) async {
      final seed = _seedWhere((d) => d.coworkerCall == 1);
      final c = await _open(t, seed);
      await _pickUp(t);
      await _hangUpDrag(t);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5TripMistakes.unasked.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M5TripLines.hello), findsOneWidget);
      expect(_label(M5TripLines.tile[M5TripTopic.how]!), findsOneWidget, reason: 'the call goes on');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5TripMistakes.unasked.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong suspect and a wrong start are slips; the right ones go on', (t) async {
      final seed = _seedWhere((d) => d.coworkerCall == 1);
      final deal = m5TripDeal(math.Random(seed));
      final call = deal.calls[0];
      final c = await _open(t, seed);
      await _pickUp(t);
      await _askAll(t, call);
      await _hangUpDrag(t);
      await _reason(t, M5TripLines.askWhy);
      final wrongCard = [0, 1, 2].firstWhere((i) => call.cards[i] != call.suspect);
      await _drag(t, _geo.pinHome, _geo.card(wrongCard).center);
      await _pump(t, 500);
      expect(find.text(M5TripMistakes.suspectFor(call.kase).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _drag(t, _geo.pinHome, _geo.card(call.cards.indexOf(call.suspect)).center);
      await _reason(t, M5TripLines.pinWhy[call.kase]!);
      final wrongArea = [0, 1, 2, 3].firstWhere((i) => call.map[i] != call.start);
      await _drag(t, _geo.vanHome, _geo.section(wrongArea).center);
      await _pump(t, 500);
      expect(find.byType(MistakeCard), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _drag(t, _geo.vanHome, _geo.section(call.map.indexOf(call.start)).center);
      await _reason(t, M5TripLines.vanWhy(call));
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), hasLength(2));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _seedWhere((d) => d.coworkerCall == 1);
      final c = await _open(t, seed);
      await _pickUp(t);
      for (var i = 0; i < 3; i++) {
        await _hangUpDrag(t);
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

    testWidgets('a fast hang-up in his call waits for him; he comes before the check', (t) async {
      final seed = _seedWhere((d) => d.coworkerCall == 0);
      final c = await _open(t, seed);
      await _pickUp(t);
      final call = m5TripDeal(math.Random(seed)).calls[0];
      expect(find.text(M5TripLines.opening(call.feeder)), findsOneWidget);
      expect(find.text(M5TripLines.lost), findsNothing, reason: 'the cue comes at the hang-up');
      await _hangUpDrag(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in at once');
      expect(find.text(M5TripLines.lost), findsOneWidget, reason: "the operator's cue by the phone");
      expect(find.byType(MistakeCard), findsNothing, reason: 'no check before him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, M5TripLines.coworker.right);
      // A tile tapped while the hang-up waits to resume does nothing.
      await _pump(t, 300);
      final topic = M5TripTopic.values.firstWhere((x) => !call.vague.contains(x));
      if (_label(M5TripLines.tile[topic]!).evaluate().isNotEmpty) await t.tap(_label(M5TripLines.tile[topic]!), warnIfMissed: false);
      await _pump(t, 2600);
      // Refused: the hang-up goes on into the check (nothing asked = a slip).
      expect(find.text(M5TripMistakes.unasked.textBn), findsOneWidget);
      expect(find.textContaining(M5TripLines.clearAnswer(call, topic), findRichText: true), findsNothing, reason: 'the tap was not taken');
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze first, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) => d.coworkerCall == 0);
      final c = await _open(t, seed);
      await _pickUp(t);
      await _hangUpDrag(t);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 400);
      await _pickWrong(t, M5TripLines.coworker.wrong);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5TripMistakes.recharge.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('gesture hand: a nudge on the handset, then a sweep over all seven tiles; none while a card is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.coworkerCall == 1);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle while the phone rings');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a drag presses nothing');
      await _pickUp(t);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the call');
      expect(scene().debugOptions, hasLength(7), reason: 'every tile alike');
      await _hangUpDrag(t);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'no hand over a card');
      await _close(t, c);
    });
  });
}
