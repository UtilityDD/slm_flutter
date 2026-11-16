// Lesson 7.3 (ন্যূনতম ক্লিয়ারেন্স), কাজ 2 "পাড়ার পাহারা": the deal (3–4
// hazards with ≥ 1 carrier and ≥ 1 report item, 2–3 decoys, a decoy on the
// move whenever a carrier is, a fair timed chance to warn, the roof item
// clear of every carrier's walk; varied over seeds), the rules (warn in time
// / late = slip / report a carrier = slip / contact = deadly; roof item warn
// vs report; the half-built house needs both; the sag needs a report; any
// warn or report on a decoy = slip; the end's slips; listening to the
// coworker = slip and the guide warns), the hold's hit test, the libraries
// and the spoken lines; and the level in the shell: the guide first,
// tap-the-guide, the two-step chip, a full clean play with both reasons and
// the coworker refused, a late warning's card (the clock waits), three
// needless holds strike out, the deadly freeze, and the gesture hands.
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
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_street_warn.dart';
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
  rungId: '7.3/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.3',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m7StreetWarnPacks['do_7_3_b']!;

/// The art folder may be newer than the test bundle: read from disk then.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      if (key == 'AssetManifest.bin') return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

List<M7WarnDeal> _deals([int n = 300]) => [for (var s = 0; s < n; s++) m7WarnDeal(math.Random(s))];

/// A run with the clock at [ms] (the roof item shows on the way); with
/// [clear] every carrier was turned away as he set off (no contact ends it).
M7WarnRun _runAt(M7WarnDeal d, double ms, {bool clear = true}) {
  final r = M7WarnRun(d);
  if (clear) {
    for (final c in d.carriers) {
      r.actors[c.id].turn(c.startMs.toDouble());
    }
  }
  r.tick(ms);
  return r;
}

M7WarnSpot _roofSpot(M7WarnDeal d) => d.roofSpot;

void main() {
  group('deal', () {
    test('3–4 hazards: 1–2 carriers, one roof item, ≥ 1 report item; 2–3 decoys', () {
      for (final d in _deals()) {
        expect(d.carriers.length, inInclusiveRange(1, 2));
        expect(d.build || d.sag, isTrue, reason: 'a report item');
        expect(d.hazardCount, inInclusiveRange(3, 4));
        expect(d.decoyCount, inInclusiveRange(2, 3));
        expect(d.actors.map((a) => a.id).toList(), [for (var i = 0; i < d.actors.length; i++) i], reason: 'ids are list positions');
      }
    });

    test('a decoy walks all the while a carrier does; every carrier has ≥ 4 s to be warned in time', () {
      for (final d in _deals()) {
        for (final c in d.carriers) {
          final covered = d.movingDecoys.any((x) => x.startMs <= c.startMs && x.endMs >= c.contactMs);
          expect(covered, isTrue, reason: 'carrier ${c.id} covered');
          expect(c.lateFromMs - c.startMs, greaterThanOrEqualTo(4000));
          expect(c.stopAt, inInclusiveRange(0.38, 1.0));
          final x = M7WarnGeo.laneXAt(c.stopAt, c.forward);
          if (c.lane == M7WarnLane.back) {
            expect(x, inInclusiveRange(M7WarnGeo.ltXs.first, M7WarnGeo.ltXs.last), reason: 'he stops under the LT line');
          } else {
            expect(c.lane, M7WarnLane.main);
            expect(x, inInclusiveRange(0, 360));
          }
          expect(c.contactMs < d.roofAt || c.startMs > d.roofAt, isTrue, reason: 'the coworker never comes mid-walk');
        }
        for (final x in d.movingDecoys) {
          expect(x.endMs, lessThanOrEqualTo(kM7WarnEndMs));
          if (x.kind == M7WarnKind.laneBamboo) expect(x.lane, M7WarnLane.free);
        }
        expect(d.roofAt, inInclusiveRange(32000, 40000));
      }
    });

    test('plays differ: roof kind and house, sag span, build, carrier lanes/sides/kinds, the free-lane bamboo', () {
      final ds = _deals(60);
      expect(ds.map((d) => d.roof).toSet(), hasLength(2));
      expect(ds.map((d) => d.roofHouse).toSet(), hasLength(2));
      expect(ds.map((d) => d.sagSpan).toSet(), {null, 0, 1});
      expect(ds.map((d) => d.build).toSet(), hasLength(2));
      expect(ds.map((d) => d.decoyRoof).toSet(), hasLength(2));
      final carriers = [for (final d in ds) ...d.carriers];
      expect(carriers.map((c) => c.lane).toSet(), {M7WarnLane.main, M7WarnLane.back});
      expect(carriers.map((c) => c.forward).toSet(), hasLength(2));
      expect(carriers.map((c) => c.kind).toSet(), {M7WarnKind.rod, M7WarnKind.bamboo});
      expect(ds.where((d) => d.movingDecoys.any((x) => x.kind == M7WarnKind.laneBamboo)).length, greaterThan(20));
      expect(ds.map((d) => d.carriers.length).toSet(), {1, 2});
      final starts = {for (final d in ds) d.carriers.first.startMs};
      expect(starts.length, greaterThan(30));
    });
  });

  group('rules', () {
    test('a carrier: in time → he turns, the first warning asks its reason; late → slip; report → slip', () {
      final d = _deals().firstWhere((d) => d.carriers.length == 2);
      final c1 = d.carriers[0];
      final c2 = d.carriers[1];
      final r = _runAt(d, c1.startMs + 1000, clear: false);
      final t1 = M7WarnTarget.person(c1.id);
      expect(r.holdable(t1), isTrue);
      final rep = r.act(t1, M7WarnAct.report);
      expect(rep.outcome, M7WarnOutcome.wrongType);
      expect(rep.mistake, M7StreetWarnMistakes.carrierReport);
      expect(r.actors[c1.id].turned, isFalse, reason: 'a report does not stop him');
      final w = r.act(t1, M7WarnAct.warn);
      expect(w.outcome, M7WarnOutcome.right);
      expect(w.why, M7WarnWhy.carrier);
      expect(w.line, M7StreetWarnLines.shoutCarrier);
      expect(r.actors[c1.id].turned, isTrue);
      expect(r.holdable(t1), isFalse, reason: 'walking away: no more holds');
      expect(r.caught, contains(M7StreetWarnLines.caughtCarrier));
      // He walks back out and is gone; never touches the line.
      expect(r.tick(c1.contactMs + 1.0).contact, isNull);
      // The second carrier, warned late: a slip, but he still turns.
      r.tick(c2.lateFromMs + 100.0);
      final l = r.act(M7WarnTarget.person(c2.id), M7WarnAct.warn);
      expect(l.outcome, M7WarnOutcome.late);
      expect(l.mistake, M7StreetWarnMistakes.lateWarn);
      expect(r.actors[c2.id].turned, isTrue);
      expect(r.tick(c2.contactMs + 10.0).contact, isNull);
      expect(r.slips, 2);
    });

    test('a carrier nobody warns: his load reaches the line → deadly (only then, never before)', () {
      final d = _deals().first;
      final c = d.carriers.first;
      final r = M7WarnRun(d);
      for (var ms = 0.0; ms < c.contactMs - 1; ms += 250) {
        expect(r.tick(ms).contact, isNull, reason: 'at $ms');
      }
      expect(r.actors[c.id].liftAt(c.contactMs - 1.0), greaterThan(0.9));
      final hit = r.tick(c.contactMs.toDouble());
      expect(hit.contact?.plan.id, c.id);
      expect(r.deadly, M7StreetWarnMistakes.contact);
      expect(r.ended, isTrue);
      expect(r.passed, isFalse);
    });

    test('a decoy (no long load, or the free lane): any warn or report = slip, then no more holds', () {
      for (final d in _deals(80)) {
        for (final x in d.movingDecoys) {
          for (final a in M7WarnAct.values) {
            final r = _runAt(d, x.startMs + 500.0);
            final t = M7WarnTarget.person(x.id);
            expect(r.holdable(t), isTrue);
            final res = r.act(t, a);
            expect(res.outcome, M7WarnOutcome.needless);
            expect(res.mistake, M7StreetWarnMistakes.needless);
            expect(r.holdable(t), isFalse);
            expect(r.needless, 1);
          }
        }
      }
    });

    test('the roof item: before it shows the roof is empty (slip, still holdable); then report = slip, warn = right', () {
      for (final roof in M7WarnRoof.values) {
        final d = _deals().firstWhere((d) => d.roof == roof);
        final t = M7WarnTarget.place(_roofSpot(d));
        final r = _runAt(d, 0);
        expect(r.act(t, M7WarnAct.warn).outcome, M7WarnOutcome.needless);
        expect(r.holdable(t), isTrue, reason: 'its item may come later');
        r.tick(d.roofAt.toDouble());
        expect(r.roofState, M7WarnRoofState.shown);
        expect(r.act(t, M7WarnAct.report).mistake, M7StreetWarnMistakes.roofReport);
        final w = r.act(t, M7WarnAct.warn);
        expect(w.outcome, M7WarnOutcome.right);
        expect(w.why, roof == M7WarnRoof.clothes ? M7WarnWhy.clothes : M7WarnWhy.bamboo);
        expect(w.line, M7StreetWarnLines.shoutRoof(roof));
        expect(r.roofState, M7WarnRoofState.cleared);
        expect(r.act(t, M7WarnAct.warn).outcome, M7WarnOutcome.already);
        // The other houses are decoys.
        final other = d.roofHouse == 0 ? M7WarnSpot.houseB : M7WarnSpot.houseA;
        expect(r.act(const M7WarnTarget.place(M7WarnSpot.houseD), M7WarnAct.warn).outcome, M7WarnOutcome.needless);
        expect(r.act(M7WarnTarget.place(other), M7WarnAct.report).outcome, M7WarnOutcome.needless);
        expect(r.holdable(const M7WarnTarget.place(M7WarnSpot.houseD)), isFalse);
      }
    });

    test('the half-built house: warn the masons AND report it; the first report asks its reason', () {
      final d = _deals().firstWhere((d) => d.build && !d.sag);
      final r = M7WarnRun(d);
      const plot = M7WarnTarget.place(M7WarnSpot.plot);
      final rep = r.act(plot, M7WarnAct.report);
      expect(rep.outcome, M7WarnOutcome.right);
      expect(rep.why, M7WarnWhy.build);
      expect(rep.line, M7StreetWarnLines.phoneBuild);
      expect(r.act(plot, M7WarnAct.report).outcome, M7WarnOutcome.already);
      final w = r.act(plot, M7WarnAct.warn);
      expect(w.outcome, M7WarnOutcome.right);
      expect(w.why, M7WarnWhy.masons, reason: 'the first warning of this play');
      expect(r.masonsWarned && r.buildReported, isTrue);
      expect(r.slips, 0);
      // Neither span sags here: holding one is a needless report.
      expect(r.act(const M7WarnTarget.place(M7WarnSpot.span0), M7WarnAct.report).outcome, M7WarnOutcome.needless);
    });

    test('the sagging span: report = right; warn = slip; the other span and a vacant plot are decoys', () {
      final d = _deals().firstWhere((d) => d.sag && !d.build);
      final r = M7WarnRun(d);
      final sag = M7WarnTarget.place(d.sagSpan == 0 ? M7WarnSpot.span0 : M7WarnSpot.span1);
      final other = M7WarnTarget.place(d.sagSpan == 0 ? M7WarnSpot.span1 : M7WarnSpot.span0);
      expect(r.act(sag, M7WarnAct.warn).mistake, M7StreetWarnMistakes.sagWarned);
      final rep = r.act(sag, M7WarnAct.report);
      expect(rep.outcome, M7WarnOutcome.right);
      expect(rep.why, M7WarnWhy.sag);
      expect(r.act(other, M7WarnAct.report).outcome, M7WarnOutcome.needless);
      expect(r.act(const M7WarnTarget.place(M7WarnSpot.plot), M7WarnAct.warn).outcome, M7WarnOutcome.needless);
      expect(r.slips, 3);
    });

    test('only the first right warning and the first right report ask a reason', () {
      final d = _deals().firstWhere((d) => d.build && d.sag);
      final r = _runAt(d, d.roofAt.toDouble());
      final sag = M7WarnTarget.place(d.sagSpan == 0 ? M7WarnSpot.span0 : M7WarnSpot.span1);
      expect(r.act(const M7WarnTarget.place(M7WarnSpot.plot), M7WarnAct.warn).why, M7WarnWhy.masons);
      expect(r.act(M7WarnTarget.place(d.roofSpot), M7WarnAct.warn).why, isNull);
      expect(r.act(sag, M7WarnAct.report).why, M7WarnWhy.sag);
      expect(r.act(const M7WarnTarget.place(M7WarnSpot.plot), M7WarnAct.report).why, isNull);
      expect(r.slips, 0);
    });

    test('the end: each static hazard left is a slip; listening to him clears the roof (the guide warns)', () {
      final d = _deals().firstWhere((d) => d.build && d.sag);
      final r = _runAt(d, d.roofAt.toDouble());
      final left = r.endSlips();
      expect(left, [M7StreetWarnMistakes.roofLeft(d.roof), M7StreetWarnMistakes.buildNoWarn, M7StreetWarnMistakes.buildNoReport, M7StreetWarnMistakes.sagLeft]);
      expect(r.slips, 4);
      expect(r.over, isTrue);
      expect(r.passed, isFalse);
      expect(r.endSlips(), isEmpty, reason: 'once');
      final r2 = _runAt(d, d.roofAt.toDouble());
      expect(r2.listen(), M7StreetWarnMistakes.listen(d.roof));
      expect(r2.roofByGuide, isTrue);
      expect(r2.roofState, M7WarnRoofState.cleared);
      expect(r2.endSlips(), isNot(contains(M7StreetWarnMistakes.roofLeft(d.roof))));
      // A clean watch: no slip at the end, a pass.
      final r3 = _runAt(d, d.roofAt.toDouble());
      r3.act(M7WarnTarget.place(d.roofSpot), M7WarnAct.warn);
      r3.act(const M7WarnTarget.place(M7WarnSpot.plot), M7WarnAct.warn);
      r3.act(const M7WarnTarget.place(M7WarnSpot.plot), M7WarnAct.report);
      r3.act(M7WarnTarget.place(d.sagSpan == 0 ? M7WarnSpot.span0 : M7WarnSpot.span1), M7WarnAct.report);
      r3.refuse();
      expect(r3.endSlips(), isEmpty);
      expect(r3.passed, isTrue);
      expect(r3.percent, 100);
      expect(r3.caught, contains(M7StreetWarnLines.caughtCall));
    });

    test('the clock: the next event with nobody on the move; the watch is over at 90 s once the lane is clear', () {
      final d = _deals().first;
      final r = _runAt(d, 0);
      final first = d.actors.map((a) => a.startMs).reduce(math.min);
      expect(r.nextEventMs(), first.toDouble());
      r.tick(kM7WarnEndMs - 1.0);
      expect(r.watchOver, isFalse);
      r.tick(kM7WarnEndMs.toDouble() + 30000);
      expect(r.anyVisible, isFalse, reason: 'every decoy has gone by then');
      expect(r.watchOver, isTrue);
    });

    test('the hold finds people first, then spans, houses, the plot; nothing on empty road', () {
      final geo = M7WarnGeo.forScene(780, 0);
      final d = _deals().firstWhere((d) => d.carriers.first.lane == M7WarnLane.back);
      final c = d.carriers.first;
      final r = _runAt(d, c.startMs + c.walkMs * 0.6, clear: false);
      final feet = r.feetOf(geo, r.actors[c.id]);
      expect(r.hitTest(geo, feet + const Offset(0, -16)), M7WarnTarget.person(c.id));
      expect(r.hitTest(geo, geo.house(2).center), const M7WarnTarget.place(M7WarnSpot.houseD));
      expect(r.hitTest(geo, geo.plot.center), const M7WarnTarget.place(M7WarnSpot.plot));
      final s0 = geo.span(0, sagSpan: d.sagSpan);
      expect(r.hitTest(geo, Offset(s0.center.dx, geo.ltWireY(s0.center.dx, sagSpan: d.sagSpan))), const M7WarnTarget.place(M7WarnSpot.span0));
      expect(r.hitTest(geo, geo.emptyRoad), isNull);
      for (final h in [560.0, 700.0, 900.0]) {
        final g = M7WarnGeo.forScene(h, 0);
        expect(g.ltY, lessThan(g.roofY));
        expect(g.backY, greaterThan(g.houseBase));
        expect(g.plot.bottom, lessThan(g.mainY));
        expect(g.htWireY(180, 2), greaterThan(g.backY), reason: 'the 11 kV line below the back lane on screen');
        expect(g.htWireY(180, 2), lessThan(g.plot.bottom));
      }
    });
  });

  group('content', () {
    test('libraries: same length, big enough, no rule marked wrong', () {
      expectSameLength('why', [...M7StreetWarnLines.allWhyRight, ...M7StreetWarnLines.myths]);
      expect(M7StreetWarnLines.myths.toSet().intersection(M7StreetWarnLines.allWhyRight.toSet()), isEmpty);
      for (final w in M7WarnWhy.values) {
        final right = M7StreetWarnLines.whyRight[w]!;
        expectLibrary('why $w', right, M7StreetWarnLines.myths);
        expect(M7StreetWarnLines.whyQ[w], isNotNull);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, M7StreetWarnLines.myths, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('chip', [M7StreetWarnLines.warn, M7StreetWarnLines.report]);
      for (final c in M7StreetWarnLines.allCoworkers) {
        expectSameLength('coworker', [...c.right, ...c.wrong]);
        expectLibrary('coworker', c.right, c.wrong);
        expect(c.asks.length, greaterThanOrEqualTo(2));
      }
    });

    test('English digits; clean Bangla; term rules; every mistake has its picture; one deadly key', () {
      final all = <String>[
        M7StreetWarnLines.title,
        ...M7StreetWarnLines.newGuideLines,
        ...M7StreetWarnLines.newRivalLines,
        M7StreetWarnLines.warn,
        M7StreetWarnLines.report,
        M7StreetWarnLines.letGo,
        ...M7StreetWarnLines.allWhyRight,
        ...M7StreetWarnLines.myths,
        for (final c in M7StreetWarnLines.allCoworkers) ...[...c.right, ...c.wrong],
        M7StreetWarnLines.caughtCarrier,
        M7StreetWarnLines.caughtClothes,
        M7StreetWarnLines.caughtBamboo,
        M7StreetWarnLines.caughtMasons,
        M7StreetWarnLines.caughtBuild,
        M7StreetWarnLines.caughtSag,
        M7StreetWarnLines.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp(r'(^|\s)(অন|অফ)(\s|$|।)').hasMatch(l), isFalse, reason: 'ON/OFF in English: $l');
        expect(l.contains('কেভি'), isFalse, reason: 'kV in English letters: $l');
        expect(RegExp('[ऀ-ॣ०-ॿ؀-ۿЀ-ӿ]').hasMatch(l), isFalse, reason: 'clean Bangla: $l');
        expect(RegExp('[\u09DC\u09DD\u09DF]').hasMatch(l), isFalse, reason: 'য়/ড়/ঢ় as base + nukta: $l');
      }
      expect(M7StreetWarnMistakes.deadlyKeys, [M7StreetWarnMistakes.contact.key]);
      expect(M7StreetWarnMistakes.all.map((m) => m.key).toSet(), hasLength(M7StreetWarnMistakes.all.length));
      for (final m in M7StreetWarnMistakes.all) {
        expect(m.key, startsWith('7.3/m7_street_warn/'));
        expect(m.art, startsWith('assets/game/art/m7_street_warn/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      final art = Directory('assets/game/art/m7_street_warn').listSync().map((f) => f.path.replaceAll(r'\', '/')).toSet();
      expect(art, M7StreetWarnMistakes.all.map((m) => m.art).toSet(), reason: 'no unused pictures, no .gitkeep');
      expect(m7StreetWarnPacks.keys, ['do_7_3_b']);
    });

    test('every spoken line is listed: the guide\'s and the coworker\'s', () {
      final guide = M7StreetWarnLines.newGuideLines.toSet();
      for (final l in [
        M7StreetWarnLines.intro,
        ...M7StreetWarnLines.tasks,
        ...M7StreetWarnLines.tapWhy,
        M7StreetWarnLines.shoutCarrier,
        M7StreetWarnLines.shoutClothes,
        M7StreetWarnLines.shoutBamboo,
        M7StreetWarnLines.shoutMasons,
        M7StreetWarnLines.phoneBuild,
        M7StreetWarnLines.phoneSag,
        M7StreetWarnLines.already,
        M7StreetWarnLines.endLine,
        M7StreetWarnLines.guideWarns,
        ...M7StreetWarnLines.whyQ.values,
        for (final c in M7StreetWarnLines.allCoworkers) ...c.asks,
        for (final r in M7WarnRoof.values) M7StreetWarnLines.callHeld(r),
        M7StreetWarnLines.allSet,
        M7StreetWarnLines.quick,
        M7StreetWarnLines.fail,
        M7StreetWarnLines.deadlyWord,
        M7StreetWarnLines.nearMissWord,
        for (final m in M7StreetWarnMistakes.all) m.textBn,
      ]) {
        expect(guide, contains(l));
      }
      expect(M7StreetWarnLines.newRivalLines, [M7StreetWarnLines.coworkerLine]);
      // The exit is recorded; his push is the one line still to record.
      expect(LearnVoice.resolve(M7StreetWarnLines.coworkerExit, rival: true), isNotNull);
      final lines = {for (final c in M7StreetWarnLines.allCoworkers) ...c.recordedLines};
      final missing = [for (final l in lines) if (LearnVoice.resolve(l, rival: true) == null) l];
      expect(missing.toSet().difference({M7StreetWarnLines.coworkerLine}), isEmpty);
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

    Future<void> pump(WidgetTester t, int ms) async {
      for (var i = 0; i < ms; i += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }

    Future<bool> until(WidgetTester t, bool Function() ok, {int maxMs = 10000}) async {
      for (var ms = 0; ms < maxMs; ms += 50) {
        if (ok()) return true;
        await t.pump(const Duration(milliseconds: 50));
      }
      return ok();
    }

    Finder label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
    List<Finder> onScreen(List<String> texts) => [
          for (final x in texts)
            if (label(x).evaluate().isNotEmpty) label(x),
        ];

    Future<void> pickRight(WidgetTester t, List<String> right) async {
      await waitChoiceDeck(t);
      final r = onScreen(right);
      expect(r, hasLength(1), reason: right.first);
      await t.tap(r.single, warnIfMissed: false);
      await tapReasonProceed(t);
    }

    Future<ProviderContainer> open(WidgetTester t, int seed, M7StreetWarnProbe probe) async {
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
        builder: (_) => DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: M7StreetWarnPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe),
        ),
      )));
      await pump(t, 1000);
      await waitIntro(t);
      await pump(t, 300);
      return c;
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    /// Holds a finger on [target] for the hold time: the chip opens.
    Future<bool> hold(WidgetTester t, M7StreetWarnProbe p, M7WarnTarget target) async {
      final at = p.targetGlobal(target);
      if (at == null) return false;
      final g = await t.startGesture(at);
      await t.pump(const Duration(milliseconds: 350));
      await t.pump(const Duration(milliseconds: 350));
      await g.up();
      await t.pump(const Duration(milliseconds: 50));
      return p.phase == 'chip';
    }

    /// The chip's answer through its preview (✓).
    Future<void> answer(WidgetTester t, M7WarnAct a) async {
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byKey(ValueKey('chip-${a.name}')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(await confirmChoice(t), isTrue, reason: 'the preview\'s ✓');
      await t.pump(const Duration(milliseconds: 100));
    }

    bool deckUp() => find.byType(ChoiceDeck).evaluate().isNotEmpty;

    /// The person is well inside the screen (a finger can reach him).
    bool reachable(M7StreetWarnProbe p, int id) {
      final g = p.targetGlobal(M7WarnTarget.person(id));
      return g != null && g.dx > 28 && g.dx < 364;
    }

    /// Plays the whole watch as a careful player: every static hazard at
    /// once, every carrier ~0.8 s after he sets off; the reasons and the
    /// coworker answered right. Returns when a result, a strike-out or a
    /// freeze is up.
    Future<void> playClean(WidgetTester t, M7StreetWarnProbe p) async {
      for (var ms = 0; ms < 400000; ms += 50) {
        if (find.byType(LevelPassPanel).evaluate().isNotEmpty ||
            find.byType(LevelFailPanel).evaluate().isNotEmpty ||
            find.byType(StruckOutCard).evaluate().isNotEmpty ||
            find.byType(FreezeFrame).evaluate().isNotEmpty) {
          return;
        }
        expect(find.byType(MistakeCard), findsNothing, reason: 'a clean play');
        if (deckUp()) {
          await waitChoiceDeck(t);
          if (find.byType(CoworkerPeek).evaluate().isNotEmpty && onScreen(M7StreetWarnLines.coworker(p.deal!.roof).right).isNotEmpty) {
            await pickRight(t, M7StreetWarnLines.coworker(p.deal!.roof).right);
          } else if (onScreen(M7StreetWarnLines.allWhyRight).isNotEmpty) {
            await pickRight(t, M7StreetWarnLines.allWhyRight);
          }
          await t.pump(const Duration(milliseconds: 50));
          continue;
        }
        final r = p.run!;
        if (p.canHold) {
          (M7WarnTarget, M7WarnAct)? job;
          for (final a in r.actors) {
            if (a.hazard && a.holdableAt(r.ms) && reachable(p, a.plan.id) && r.ms < a.plan.lateFromMs - 300) {
              job = (M7WarnTarget.person(a.plan.id), M7WarnAct.warn);
            }
          }
          if (job == null && r.roofState == M7WarnRoofState.shown && !p.waitingForHim) job = (M7WarnTarget.place(r.deal.roofSpot), M7WarnAct.warn);
          if (job == null && r.deal.build && !r.masonsWarned) job = (const M7WarnTarget.place(M7WarnSpot.plot), M7WarnAct.warn);
          if (job == null && r.deal.build && !r.buildReported) job = (const M7WarnTarget.place(M7WarnSpot.plot), M7WarnAct.report);
          if (job == null && r.deal.sag && !r.sagReported) {
            job = (M7WarnTarget.place(r.deal.sagSpan == 0 ? M7WarnSpot.span0 : M7WarnSpot.span1), M7WarnAct.report);
          }
          if (job != null) {
            expect(await hold(t, p, job.$1), isTrue, reason: 'the chip opens on ${job.$1}');
            await answer(t, job.$2);
            continue;
          }
        }
        await t.pump(const Duration(milliseconds: 50));
      }
      fail('the watch never ended');
    }

    testWidgets('the guide comes first: no start button, a tap does not skip him; then the clock runs', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final p = M7StreetWarnProbe();
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M7StreetWarnPage(ctx: _ctx, pack: _pack, muted: true, seed: 3, probe: p))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(p.phase, 'intro');
      expect(p.clockRunning, isFalse);
      await waitIntro(t);
      await pump(t, 300);
      expect(p.phase, 'watch');
      expect(p.clockRunning, isTrue);
      final before = p.gameMs;
      await pump(t, 3000);
      expect(p.gameMs, greaterThan(before), reason: 'the game clock runs');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final p = M7StreetWarnProbe();
      final c = await open(t, 5, p);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await t.pump(const Duration(milliseconds: 300));
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M7StreetWarnLines.askWatch)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await close(t, c);
    });

    testWidgets('a hold opens the chip (the clock stops); a tap opens a preview that answers nothing; ✕ sets it aside; ছেড়ে দিন lets go', (t) async {
      final p = M7StreetWarnProbe();
      final c = await open(t, 6, p);
      // A short tap does nothing.
      await t.tapAt(p.targetGlobal(const M7WarnTarget.place(M7WarnSpot.houseD))!);
      await t.pump(const Duration(milliseconds: 100));
      expect(p.phase, 'watch');
      expect(await hold(t, p, const M7WarnTarget.place(M7WarnSpot.houseD)), isTrue);
      expect(p.clockRunning, isFalse);
      final frozenAt = p.gameMs;
      await pump(t, 1500);
      expect(p.gameMs, frozenAt, reason: 'the clock waits while the chip is up');
      expect(label(M7StreetWarnLines.warn), findsOneWidget);
      expect(label(M7StreetWarnLines.report), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('chip-warn')));
      await t.pump(const Duration(milliseconds: 200));
      expect(p.phase, 'preview');
      expect(p.run!.slips, 0, reason: 'a tap is not an answer');
      await pump(t, 400);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await t.pump(const Duration(milliseconds: 200));
      expect(p.phase, 'chip');
      expect(find.byWidgetPredicate((w) => w is CardAside && w.aside), findsOneWidget);
      expect(p.run!.slips, 0);
      await t.tap(find.byKey(const ValueKey('chip-letgo')));
      await t.pump(const Duration(milliseconds: 200));
      expect(p.phase, 'watch');
      expect(p.clockRunning, isTrue);
      expect(find.byType(MistakeCard), findsNothing);
      // ✓ on a decoy roof: a needless warning is a slip.
      expect(await hold(t, p, const M7WarnTarget.place(M7WarnSpot.houseD)), isTrue);
      await answer(t, M7WarnAct.warn);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M7StreetWarnMistakes.needless.textBn), findsOneWidget);
      expect(p.clockRunning, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await t.pump(const Duration(milliseconds: 300));
      expect(p.clockRunning, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, M7StreetWarnMistakes.needless.key);
      await close(t, c);
    });

    for (final two in [false, true]) {
      testWidgets('flow (${two ? 'two carriers' : 'one carrier'}): every hazard handled, both reasons, the coworker refused → pass', (t) async {
        final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) {
          final d = m7WarnDeal(math.Random(s));
          return d.carriers.length == (two ? 2 : 1) && (two || (d.build && d.sag));
        });
        final p = M7StreetWarnProbe();
        final c = await open(t, seed, p);
        await playClean(t, p);
        expect(await until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 15000), isTrue);
        final r = p.run!;
        expect(r.slips, 0);
        expect(r.over, isTrue);
        expect(p.gameMs, greaterThanOrEqualTo(kM7WarnEndMs.toDouble()));
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.3/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.3/do/1'], greaterThan(0));
        expect(find.text(M7StreetWarnLines.caughtCall), findsOneWidget);
        expect(find.text(M7StreetWarnLines.caughtCarrier), findsOneWidget);
        expect(t.takeException(), isNull);
        await close(t, c);
      });
    }

    testWidgets('the coworker comes the moment the roof item shows: the clock waits for him; the item is locked till he goes', (t) async {
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) => m7WarnDeal(math.Random(s)).carriers.first.startMs > 45000);
      final p = M7StreetWarnProbe();
      final c = await open(t, seed, p);
      expect(await until(t, () => p.run!.roofState == M7WarnRoofState.shown, maxMs: 60000), isTrue);
      expect(p.waitingForHim, isTrue);
      expect(p.clockRunning, isFalse);
      expect(p.canHold, isFalse, reason: 'the item is locked');
      expect(await until(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 4000), isTrue);
      final at = p.gameMs;
      await until(t, deckUp);
      expect(p.gameMs, at, reason: 'the clock waits for him');
      await pickRight(t, M7StreetWarnLines.coworker(p.deal!.roof).right);
      expect(await until(t, () => p.canHold), isTrue, reason: 'the item is the player\'s again');
      expect(p.run!.roofState, M7WarnRoofState.shown, reason: 'refusing him is not warning the owner');
      expect(await hold(t, p, M7WarnTarget.place(p.deal!.roofSpot)), isTrue);
      await answer(t, M7WarnAct.warn);
      expect(p.run!.roofState, M7WarnRoofState.cleared);
      expect(await until(t, () => find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isNotEmpty || deckUp()), isTrue, reason: 'the first warning asks why');
      await close(t, c);
    });

    testWidgets('listening to him is a slip; the guide warns the owner', (t) async {
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) => m7WarnDeal(math.Random(s)).carriers.first.startMs > 45000);
      final p = M7StreetWarnProbe();
      final c = await open(t, seed, p);
      expect(await until(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 60000), isTrue);
      await until(t, deckUp);
      await waitChoiceDeck(t);
      final w = onScreen(M7StreetWarnLines.coworkerWrong);
      expect(w, isNotEmpty);
      await t.tap(w.first, warnIfMissed: false);
      await confirmChoice(t);
      await pump(t, 900);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a slip, not deadly (X2/B1)');
      expect(find.text(M7StreetWarnMistakes.listen(p.deal!.roof).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await pump(t, 300);
      expect(c.read(guideDirectorProvider).line, M7StreetWarnLines.guideWarns);
      expect(p.run!.roofState, M7WarnRoofState.cleared);
      expect(c.read(gameSaveProvider).mistakes.single.key, M7StreetWarnMistakes.listen(p.deal!.roof).key);
      await close(t, c);
    });

    testWidgets('a late warning is a slip: its card (the clock waits), he still turns away', (t) async {
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) => m7WarnDeal(math.Random(s)).carriers.first.startMs < 20000);
      final p = M7StreetWarnProbe();
      final c = await open(t, seed, p);
      final car = p.deal!.carriers.first;
      expect(await until(t, () => p.gameMs >= car.lateFromMs + 200, maxMs: 40000), isTrue);
      expect(await hold(t, p, M7WarnTarget.person(car.id)), isTrue);
      await answer(t, M7WarnAct.warn);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M7StreetWarnMistakes.lateWarn.textBn), findsOneWidget);
      expect(p.run!.actors[car.id].turned, isTrue);
      final at = p.gameMs;
      await pump(t, 1500);
      expect(p.gameMs, at);
      await t.tap(find.text(MistakeLines.gotIt));
      await pump(t, 3000);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'he never touches the line');
      expect(c.read(gameSaveProvider).mistakes.single.key, M7StreetWarnMistakes.lateWarn.key);
      await close(t, c);
    });

    testWidgets('three needless holds strike the level out', (t) async {
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) {
        final d = m7WarnDeal(math.Random(s));
        return !d.build && d.carriers.first.startMs > 9000;
      });
      final p = M7StreetWarnProbe();
      final c = await open(t, seed, p);
      final d = p.deal!;
      final targets = [
        const M7WarnTarget.place(M7WarnSpot.houseD),
        const M7WarnTarget.place(M7WarnSpot.plot),
        M7WarnTarget.place(d.sagSpan == 0 ? M7WarnSpot.span1 : M7WarnSpot.span0),
      ];
      for (final (i, target) in targets.indexed) {
        expect(await hold(t, p, target), isTrue, reason: '$target');
        await answer(t, i.isEven ? M7WarnAct.warn : M7WarnAct.report);
        await pump(t, 400);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await pump(t, 300);
        }
      }
      await pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(p.run!.slips, 3);
      await close(t, c);
    });

    testWidgets('nobody warns a carrier: the scene freezes as his load meets the line, then the card (near-miss)', (t) async {
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) => m7WarnDeal(math.Random(s)).carriers.first.startMs < 20000);
      final p = M7StreetWarnProbe();
      final c = await open(t, seed, p);
      expect(await until(t, () => find.byType(FreezeFrame).evaluate().isNotEmpty, maxMs: 45000), isTrue);
      expect(find.byType(MistakeCard), findsNothing);
      expect(p.run!.deadly, M7StreetWarnMistakes.contact);
      expect(p.gameMs, greaterThanOrEqualTo(p.deal!.carriers.first.contactMs.toDouble()));
      await pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M7StreetWarnMistakes.contact.key);
      expect(s.mistakes.single.deadly, isTrue);
      await close(t, c);
    });

    testWidgets('the end: the static hazards left come as slips one by one, then the result', (t) async {
      // Two hazards left (roof + build or sag) and no carrier warned would be
      // deadly: warn the carrier only, leave the rest.
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) {
        final d = m7WarnDeal(math.Random(s));
        return d.carriers.length == 1 && !(d.build && d.sag);
      });
      final p = M7StreetWarnProbe();
      final c = await open(t, seed, p);
      final car = p.deal!.carriers.first;
      for (var ms = 0; ms < 200000; ms += 50) {
        if (p.phase == 'end' || find.byType(LevelFailPanel).evaluate().isNotEmpty || find.byType(StruckOutCard).evaluate().isNotEmpty) break;
        if (deckUp()) {
          await waitChoiceDeck(t);
          if (onScreen(M7StreetWarnLines.coworker(p.deal!.roof).right).isNotEmpty) {
            await pickRight(t, M7StreetWarnLines.coworker(p.deal!.roof).right);
          } else {
            await pickRight(t, M7StreetWarnLines.allWhyRight);
          }
          continue;
        }
        final r = p.run!;
        final a = r.actors[car.id];
        if (p.canHold && a.holdableAt(r.ms) && reachable(p, car.id)) {
          expect(await hold(t, p, M7WarnTarget.person(car.id)), isTrue);
          await answer(t, M7WarnAct.warn);
          continue;
        }
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(await until(t, () => find.byType(MistakeCard).evaluate().isNotEmpty, maxMs: 20000), isTrue);
      expect(find.text(M7StreetWarnMistakes.roofLeft(p.deal!.roof).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget, reason: 'the report item left');
      await t.tap(find.text(MistakeLines.gotIt));
      expect(await until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 8000), isTrue, reason: '2 slips: 70 %, a pass');
      expect(p.run!.percent, 70);
      expect(c.read(gameSaveProvider).rungProgress['7.3/do/1'], 'cleared');
      await close(t, c);
    });

    testWidgets('gesture hands: watching, first a hold ring on empty road, then a sweep over every holdable; the chip sweeps its two answers', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) => m7WarnDeal(math.Random(s)).carriers.first.startMs > 45000);
      final p = M7StreetWarnProbe();
      final c = await open(t, seed, p);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle while watching');
      expect(scene().debugOptions, isEmpty, reason: 'the first hand is a hold, not a sweep');
      // Any touch hides it; the chip's hand sweeps over its two answers.
      expect(await hold(t, p, const M7WarnTarget.place(M7WarnSpot.houseD)), isTrue);
      expect(scene().showing, isFalse);
      await pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the chip');
      expect(scene().debugOptions, hasLength(2));
      await t.tap(find.byKey(const ValueKey('chip-letgo')));
      await t.pump(const Duration(milliseconds: 200));
      expect(scene().showing, isFalse);
      await pump(t, 9000);
      if (!p.waitingForHim && find.byType(MistakeCard).evaluate().isEmpty) {
        expect(scene().showing, isTrue);
        expect(scene().debugOptions.length, greaterThanOrEqualTo(2), reason: 'a sweep over every holdable alike');
      }
      expect(find.byType(MistakeCard), findsNothing);
      await close(t, c);
    });
  });
}
