// Lesson 5.4 (ফিউজ বারবার উড়ে যাওয়া), কাজ 1 "একে একে ফিডার — ফল্ট কোথায়?":
// the rules (all LT out → HT holds → ways back one by one → the faulty way
// blows the HT → pull it, red tag; DTR/HT: blows with all out → patrol or
// megger; deadly: shut the DO with no way open / again with the blower in /
// again after it blew with all out; slips: shut with only some ways open,
// listening to the coworker, the tag on the wrong way), the deal, the
// libraries, the rival lines, and the level in the shell: the guide first, a
// full clean play (an LT round and a DTR/HT round, both orders of the coworker
// trigger) with the reasons and the coworker refused, the next carrier waiting
// for him, three slips, the deadly freeze, and the gesture hand (how, never
// what). Idle perf: test/perf/m5_feeder_sectionalize_perf_test.dart.
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
import 'package:slm_flutter/features/game/m5_feeder_sectionalize.dart';
import 'package:slm_flutter/features/game/m5_feeder_sectionalize_world.dart';
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
  rungId: '5.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m5FeederPacks['do_5_4_a']!;

/// The art folder may not be in the bundle yet: read it from disk then.
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5FeederSectionalizePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

Finder _carrier(M5FeederSite s, int i) => _label(M5FeederLines.carrier(s.roads[i]));
bool _seated(WidgetTester t, M5FeederSite s, int i) => t.widget<Semantics>(_carrier(s, i)).properties.value == M5FeederLines.seated;

Future<void> _door(WidgetTester t) async {
  await t.tap(_label(M5FeederLines.door));
  await _pump(t, 400);
}

Future<void> _pull(WidgetTester t, M5FeederSite s, int i) async {
  await t.drag(_carrier(s, i), const Offset(0, 40));
  await _pump(t, 300);
}

Future<void> _restore(WidgetTester t, M5FeederSite s, int i) async {
  await t.drag(_carrier(s, i), const Offset(0, -40));
  await _pump(t, 300);
}

/// Hold the DO 1 s; the rod shuts it.
Future<void> _holdDo(WidgetTester t) async {
  final g = await t.startGesture(t.getCenter(_label(M5FeederLines.doLabel)));
  await _pump(t, 1150);
  await g.up();
  await _pump(t, 1000);
}

Future<void> _reason(WidgetTester t, M5FeederWhy w) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: '$w deck');
  await _pump(t, 700);
  await _pickRight(t, M5FeederLines.whyRight[w]!);
  await _pump(t, 1500);
}

Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, M5FeederLines.coworker.right);
  await _pump(t, 2600);
}

/// One transformer played right (the coworker refused on his round).
Future<void> _playRound(WidgetTester t, M5FeederDeal d, int k) async {
  final s = d.sites[k];
  final his = d.coworkerRound == k;
  await _door(t);
  if (his && !d.coworkerOnPull) await _refuse(t);
  for (var i = 0; i < s.ways; i++) {
    await _pull(t, s, i);
    if (his && d.coworkerOnPull && i == 0) await _refuse(t);
  }
  for (var i = 0; i < s.ways; i++) {
    expect(_seated(t, s, i), isFalse, reason: 'way $i out');
  }
  await _holdDo(t);
  if (s.ht) {
    await _reason(t, M5FeederWhy.ht);
    await t.tap(_label(M5FeederLines.patrol));
    await _pump(t, 2500);
    return;
  }
  await _reason(t, M5FeederWhy.held);
  for (var i = 0; i < s.ways; i++) {
    await _restore(t, s, i);
    if (i == s.faulty) break;
  }
  await _reason(t, M5FeederWhy.identified);
  await _pull(t, s, s.faulty);
  await t.tap(_label(M5FeederLines.tag));
  await _pump(t, 200);
  await t.tap(_carrier(s, s.faulty), warnIfMissed: false);
  await _pump(t, 2500);
}

int _seedWhere(bool Function(M5FeederDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5FeederDeal(math.Random(s))));

const _lt3 = M5FeederSite(dtr: 7, blownToday: 2, roads: ['বাজার', 'স্কুল', 'হাট'], faulty: 1, phase: 0, place: 'রামপুর মোড়', time: 'সন্ধ্যা 6:15');
const _lt4 = M5FeederSite(dtr: 9, blownToday: 3, roads: ['ঘাট', 'মসজিদ', 'মন্দির', 'কলেজ'], faulty: 3, phase: 2, place: 'বটতলা মোড়', time: 'সন্ধ্যা 7:05');
const _ht = M5FeederSite(dtr: 12, blownToday: 2, roads: ['পুকুর', 'মাঠ', 'স্টেশন'], faulty: -1, phase: 1, place: 'শিবপুর মোড়', time: 'সন্ধ্যা 5:50');
M5FeederRun _runOf(M5FeederSite a, [M5FeederSite b = _ht]) => M5FeederRun(M5FeederDeal(sites: [a, b], coworkerRound: 0, coworkerOnPull: false))..openDoor();

void main() {
  group('rules', () {
    test('deals: two transformers, the 1st an LT fault, the 2nd DTR/HT about 40 %; 3–4 ways; he never comes on a DTR/HT round; plays differ', () {
      final seen = <String>{};
      var ht = 0;
      final ways = <int>{};
      final triggers = <bool>{};
      for (var s = 0; s < 300; s++) {
        final d = m5FeederDeal(math.Random(s));
        expect(d.sites, hasLength(2));
        expect(d.sites.first.ht, isFalse);
        if (d.sites[1].ht) ht++;
        expect(d.sites[d.coworkerRound].ht, isFalse);
        triggers.add(d.coworkerOnPull);
        expect(d.sites[0].dtr, isNot(d.sites[1].dtr));
        expect({...d.sites[0].roads, ...d.sites[1].roads}, hasLength(d.sites[0].ways + d.sites[1].ways), reason: 'road names differ');
        for (final site in d.sites) {
          ways.add(site.ways);
          expect(site.ways, inInclusiveRange(3, 4));
          expect(site.faulty, inInclusiveRange(-1, site.ways - 1));
          expect(site.phase, inInclusiveRange(0, 2));
          expect(site.blownToday, inInclusiveRange(2, 3));
          expect(M5FeederLines.times, contains(site.time));
          expect(site.dusk, inInclusiveRange(0.0, 1.0));
        }
        seen.add('${d.sites.map((x) => '${x.roads.join()}/${x.faulty}/${x.phase}').join('|')}|${d.coworkerRound}|${d.coworkerOnPull}');
      }
      expect(ht, inInclusiveRange(90, 150), reason: '40 % of 300');
      expect(ways, {3, 4});
      expect(triggers, {true, false});
      expect(seen.length, greaterThan(250));
      // The faulty way is spread over every position.
      final pos = <int>{for (var s = 0; s < 300; s++) m5FeederDeal(math.Random(s)).sites.first.faulty};
      expect(pos, {0, 1, 2, 3});
    });

    test('LT fault: all out → HT holds (proof) → ways back one by one → the faulty one blows the HT → pull → tag', () {
      final r = _runOf(_lt3);
      expect(r.inWays, {0, 1, 2});
      for (final i in [0, 1, 2]) {
        expect(r.pull(i).event, M5FeederEvent.pulled);
      }
      expect(r.closeDo().event, M5FeederEvent.heldProof);
      expect(r.held, isTrue);
      expect(r.proof, isTrue);
      expect(r.restore(0).event, M5FeederEvent.restored);
      expect(r.held, isTrue, reason: 'a sound way holds');
      final s = r.restore(1);
      expect(s.event, M5FeederEvent.identified);
      expect(r.held, isFalse);
      expect(r.blower, 1);
      expect(r.tag(1).event, M5FeederEvent.pullFirst, reason: 'still in: no cost');
      expect(r.tag(0).mistake, M5FeederMistakes.wrongTag);
      expect(r.slips, 1);
      r.pull(1);
      expect(r.tag(1).event, M5FeederEvent.tagged);
      expect(r.roundDone, isTrue);
      expect(r.caught, containsAll([M5FeederLines.caughtAllOut, M5FeederLines.caughtOneByOne]));
      expect(r.caught, isNot(contains(M5FeederLines.caughtTag)), reason: 'the round had a slip');
    });

    test('deadly: the DO shut with no way open; again with the blower in; the blower pushed into a live board', () {
      final a = _runOf(_lt3);
      expect(a.closeDo().mistake, M5FeederMistakes.noOpen);
      expect(a.ended, isTrue);
      expect(M5FeederMistakes.noOpen.deadly, isTrue);

      final b = _runOf(_lt3);
      for (final i in [0, 1, 2]) {
        b.pull(i);
      }
      b.closeDo();
      b.restore(1);
      expect(b.closeDo().mistake, M5FeederMistakes.rechargeFaulty, reason: 'shut again with the blower in');

      final c = _runOf(_lt3);
      for (final i in [0, 1, 2]) {
        c.pull(i);
      }
      c.closeDo();
      c.restore(1);
      c.pull(1);
      c.pull(0);
      expect(c.closeDo().event, M5FeederEvent.held, reason: 'the blower out: the rest may hold');
      expect(c.slips, 0);
      expect(c.restore(1).mistake, M5FeederMistakes.rechargeFaulty, reason: 'a proved fault into a live board');
      expect(c.ended, isTrue);
    });

    test('a tag before any feeder is proved costs a slip, the same on every carrier (never singles out the faulty way)', () {
      for (final i in [0, 1, 2]) {
        final r = _runOf(_lt3);
        final s = r.tag(i);
        expect(s.mistake, M5FeederMistakes.wrongTag, reason: 'carrier $i, nothing proved');
        expect(s.event, M5FeederEvent.none);
        expect(r.slips, 1);
        expect(r.tagged, isNull);
      }
      // After the LT proof but before the blower is found: still a wrong flag.
      for (final i in [0, 1, 2]) {
        final r = _runOf(_lt3);
        for (final k in [0, 1, 2]) {
          r.pull(k);
        }
        expect(r.closeDo().event, M5FeederEvent.heldProof);
        expect(r.tag(i).mistake, M5FeederMistakes.wrongTag, reason: 'carrier $i, LT proved, no feeder yet');
        expect(r.slips, 1);
      }
    });

    test('deadly: shut again after a partial-open blast in a DTR/HT round blames the re-charge, not a feeder', () {
      final r = M5FeederRun(const M5FeederDeal(sites: [_ht, _lt3], coworkerRound: 1, coworkerOnPull: false))..openDoor();
      r.pull(0);
      final s = r.closeDo();
      expect(s.event, M5FeederEvent.blast);
      expect(s.mistake, M5FeederMistakes.partialOpen);
      expect(r.closeDo().mistake, M5FeederMistakes.rechargeSame);
      expect(r.ended, isTrue);
    });

    test('DTR/HT fault: blows with every way out → patrol or megger; shutting it again is deadly', () {
      final r = M5FeederRun(const M5FeederDeal(sites: [_lt3, _ht], coworkerRound: 0, coworkerOnPull: false))..next();
      expect(r.site.ht, isTrue);
      r.openDoor();
      for (final i in [0, 1, 2]) {
        r.pull(i);
      }
      expect(r.choose().event, M5FeederEvent.none, reason: 'not proved yet');
      expect(r.closeDo().event, M5FeederEvent.htProof);
      expect(r.htProved, isTrue);
      expect(r.caught, contains(M5FeederLines.caughtHt));
      final again = M5FeederRun(const M5FeederDeal(sites: [_ht, _lt3], coworkerRound: 1, coworkerOnPull: false))..openDoor();
      for (final i in [0, 1, 2]) {
        again.pull(i);
      }
      again.closeDo();
      again.restore(0);
      expect(again.closeDo().mistake, M5FeederMistakes.rechargeHt);
      expect(r.tag(0).mistake, M5FeederMistakes.wrongTag, reason: 'no LT way is faulty here');
      expect(r.choose().event, M5FeederEvent.chosen);
      expect(r.roundDone, isTrue);
    });

    test('slip: shut with only some ways open — it plays honestly (blows with the fault in, holds without); no dead end', () {
      final r = _runOf(_lt4);
      r.pull(0);
      final s = r.closeDo();
      expect(s.mistake, M5FeederMistakes.partialOpen);
      expect(s.event, M5FeederEvent.blast);
      expect(r.held, isFalse);
      expect(r.closeDo().mistake, M5FeederMistakes.rechargeSame, reason: 'nothing changed since it blew; no feeder proved yet');

      final q = _runOf(_lt4);
      q.pull(0);
      q.closeDo();
      q.pull(1);
      q.pull(2);
      q.pull(3);
      expect(q.closeDo().event, M5FeederEvent.heldProof, reason: 'all out after the slip: the proof');
      expect(q.slips, 1);

      final h = _runOf(_lt4);
      h.pull(3);
      final hs = h.closeDo();
      expect(hs.event, M5FeederEvent.held, reason: 'the fault was out: it holds');
      expect(hs.mistake, M5FeederMistakes.partialOpen);
      expect(h.restore(3).event, M5FeederEvent.identified);
      h.pull(3);
      h.pull(0);
      expect(h.closeDo().mistake, isNull, reason: 'the fault is found: no second slip');
      expect(M5FeederMistakes.partialOpen.deadly, isFalse);
    });

    test('three slips, the listen slip, next round, percent', () {
      final r = _runOf(_lt4);
      r.pull(0);
      r.closeDo();
      r.pull(1);
      r.closeDo();
      r.pull(2);
      expect(r.closeDo().mistake, M5FeederMistakes.partialOpen);
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.listen(), M5FeederMistakes.listened);
      expect(r.percent, 40);
      final n = _runOf(_lt3);
      for (final i in [0, 1, 2]) {
        n.pull(i);
      }
      n.closeDo();
      n.restore(1);
      n.pull(1);
      n.tag(1);
      n.next();
      expect(n.index, 1);
      expect(n.doorOpen, isFalse);
      expect(n.inWays, {0, 1, 2}, reason: 'the new board starts all in');
      expect(n.roundDone, isFalse);
    });

    test('English digits; locked words; every mistake has its picture and a lesson point; keys unique; three deadly', () {
      final d = m5FeederDeal(math.Random(3));
      final all = <String>[
        M5FeederLines.intro,
        ...M5FeederLines.tasks,
        ...M5FeederLines.allWhyRight,
        ...M5FeederLines.allWhyWrong,
        ...M5FeederLines.whyQ.values,
        ...M5FeederLines.coworker.recordedLines,
        ...M5FeederLines.coworker.right,
        ...M5FeederLines.coworker.wrong,
        ...M5FeederLines.coworker.asks,
        for (final m in M5FeederMistakes.all) m.textBn,
        for (final s in d.sites) ...[M5FeederLines.docketLine1(s), M5FeederLines.docketLine2(s), M5FeederLines.docketSpoken(s), s.time],
        M5FeederLines.allSet,
        M5FeederLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5FeederLines.docketLine1(d.sites.first), startsWith('ডকেট'));
      expect(M5FeederMistakes.all.where((m) => m.deadly).toSet(), {M5FeederMistakes.noOpen, M5FeederMistakes.rechargeFaulty, M5FeederMistakes.rechargeSame, M5FeederMistakes.rechargeHt});
      expect(M5FeederMistakes.all.map((m) => m.key).toSet(), hasLength(M5FeederMistakes.all.length));
      for (final m in M5FeederMistakes.all) {
        expect(m.key, startsWith('5.4/m5_feeder_sectionalize/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      // No unused pictures in the folder.
      final used = {for (final m in M5FeederMistakes.all) m.art.split('/').last};
      final files = Directory('assets/game/art/m5_feeder_sectionalize').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m5FeederPacks.keys, ['do_5_4_a']);
    });

    test('libraries: same length, big enough, one right a deal, never a rule marked wrong', () {
      expectSameLength('why', [...M5FeederLines.allWhyRight, ...M5FeederLines.allWhyWrong]);
      expect(M5FeederLines.allWhyWrong.toSet().intersection(M5FeederLines.allWhyRight.toSet()), isEmpty);
      for (final w in M5FeederWhy.values) {
        final right = M5FeederLines.whyRight[w]!;
        final wrong = M5FeederLines.mythsFor[w]!;
        expectLibrary('$w', right, wrong);
        final seen = <String>{};
        for (var k = 0; k < 20; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          seen.add(deal.map((o) => o.textBn).join('|'));
        }
        expect(seen.length, greaterThan(5), reason: '$w deals differ');
      }
      final cw = M5FeederLines.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong);
      expect(cw.line, contains('এইচটি ফিউজ উড়েছে, তার মানে সমস্যাটা এইচটি লাইনেই'), reason: 'lesson 5.4 myth 2');
    });

    test('rival lines: his exit line has its clip; his push is listed for recording', () {
      final cw = M5FeederLines.coworker;
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      expect(cw.recordedLines, [cw.line, cw.exitLine]);
    });

    test('tap areas stay on the 360-wide scene, under the header, above the tool row, and never overlap', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M5FeederGeo.forScene(h, 0);
        final rects = <String, Rect>{
          'door': g.doorHit,
          for (var p = 0; p < 3; p++) 'do$p': g.doRing(p),
          for (var i = 0; i < 4; i++) 'c$i': g.carrierHit(i),
        };
        for (final e in rects.entries) {
          expect(e.value.left, greaterThanOrEqualTo(0), reason: '$h ${e.key}');
          expect(e.value.right, lessThanOrEqualTo(360), reason: '$h ${e.key}');
          expect(e.value.top, greaterThan(120), reason: '$h ${e.key}: below the header');
          expect(e.value.bottom, lessThan(g.groundY), reason: '$h ${e.key}: above the tool row');
          expect(e.value.width, greaterThanOrEqualTo(44), reason: '$h ${e.key}: a finger');
        }
        final list = [g.doorHit, g.doRing(0), for (var i = 0; i < 4; i++) g.carrierHit(i)];
        for (var i = 0; i < list.length; i++) {
          for (var j = i + 1; j < list.length; j++) {
            final x = list[i].intersect(list[j]);
            expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h: $i/$j');
          }
        }
        for (var i = 0; i < 4; i++) {
          expect(g.panel.contains(g.carrierOut(i).bottomCenter.translate(0, -1)), isTrue, reason: 'a pulled carrier stays on the board');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the LT box', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5FeederSectionalizePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5FeederLines.door), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5FeederLines.door), findsOneWidget);
      expect(_label(M5FeederLines.docketHead), findsOneWidget);
      final d = m5FeederDeal(math.Random(3));
      expect(find.text(M5FeederLines.docketLine2(d.sites.first)), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, _seedWhere((d) => d.coworkerRound == 1));
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M5FeederLines.askFind)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    final flows = <String, bool Function(M5FeederDeal)>{
      'LT + DTR/HT, he comes on the door': (d) => d.sites[1].ht && !d.coworkerOnPull,
      'LT + LT, he comes on the first pull in round 2': (d) => !d.sites[1].ht && d.coworkerOnPull && d.coworkerRound == 1,
    };
    for (final e in flows.entries) {
      testWidgets('flow (${e.key}): sectionalize both transformers, refuse him, right reasons → pass', (t) async {
        final seed = _seedWhere(e.value);
        final deal = m5FeederDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _playRound(t, deal, 0);
        await _playRound(t, deal, 1);
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.4/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.4/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5FeederLines.caughtCall), findsOneWidget);
        expect(find.text(M5FeederLines.caughtAllOut), findsOneWidget);
        if (deal.sites[1].ht) expect(find.text(M5FeederLines.caughtHt), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a fast play: the next carrier waits for the coworker (it stays in); he comes at once', (t) async {
      final seed = _seedWhere((d) => d.coworkerRound == 0 && !d.coworkerOnPull);
      final deal = m5FeederDeal(math.Random(seed));
      final s = deal.sites.first;
      final c = await _open(t, seed);
      await t.tap(_label(M5FeederLines.door));
      await t.pump(const Duration(milliseconds: 100));
      // At once: well inside his 1.2–2.4 s timer.
      await t.drag(_carrier(s, 0), const Offset(0, 40));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_seated(t, s, 0), isTrue, reason: 'the carrier waits for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, M5FeederLines.coworker.right);
      await _pump(t, 2600);
      await _pull(t, s, 0);
      expect(_seated(t, s, 0), isFalse, reason: 'after him it moves');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('listening to him is a slip: its card; the round goes on', (t) async {
      final seed = _seedWhere((d) => d.coworkerRound == 0 && !d.coworkerOnPull);
      final c = await _open(t, seed);
      await _door(t);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5FeederLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5FeederMistakes.listened.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5FeederMistakes.listened.key);
      await _close(t, c);
    });

    testWidgets('three slips (the DO shut with only some ways open) strike the level out', (t) async {
      final seed = _seedWhere((d) => d.coworkerRound == 1 && d.sites.first.ways == 4);
      final s = m5FeederDeal(math.Random(seed)).sites.first;
      final c = await _open(t, seed);
      await _door(t);
      final sound = [for (var i = 0; i < 4; i++) if (i != s.faulty) i];
      for (var k = 0; k < 3; k++) {
        await _pull(t, s, sound[k]);
        await _holdDo(t);
        await _pump(t, 600);
        if (k < 2) {
          expect(find.text(M5FeederMistakes.partialOpen.textBn), findsOneWidget, reason: 'slip ${k + 1}');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    testWidgets('the DO shut with every way in: the scene freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, _seedWhere((d) => d.coworkerRound == 1));
      await _door(t);
      final g = await t.startGesture(t.getCenter(_label(M5FeederLines.doLabel)));
      await _pump(t, 1150);
      await g.up();
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5FeederMistakes.noOpen.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a short tap on the DO does nothing (it must be held)', (t) async {
      final c = await _open(t, _seedWhere((d) => d.coworkerRound == 1));
      await _door(t);
      await t.tap(_label(M5FeederLines.doLabel));
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle → a sweep over docket, LT box and DO; inside, over every control; a confused tap → that carrier only', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.coworkerRound == 1);
      final s = m5FeederDeal(math.Random(seed)).sites.first;
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the door shut');
      expect(scene().debugOptions, hasLength(3), reason: 'docket, LT box, DO');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _door(t);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the open board');
      expect(scene().debugOptions, hasLength(3 + s.ways), reason: 'docket, DO, every carrier, the tag');
      // Three plain taps on one carrier: the hand shows how a carrier moves, there.
      for (var k = 0; k < 3; k++) {
        await t.tap(_carrier(s, 0), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three confused taps');
      expect(scene().debugOptions, isEmpty, reason: 'a swipe on that carrier, not a sweep');
      expect(scene().debugFrame?.ripple, isNull);
      expect(find.byType(MistakeCard), findsNothing);
      // A deck up: the scene's hand stays away.
      for (var i = 0; i < s.ways; i++) {
        await _pull(t, s, i);
      }
      await _holdDo(t);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the reason deck has its own sweep');
      await _close(t, c);
    });
  });
}
