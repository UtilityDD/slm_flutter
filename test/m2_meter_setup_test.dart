// Lesson 2.2, কাজ 1 (ডায়াল আর সকেট): the rules of the case and the three
// jobs (dial, sockets, isolator, the fuse's reading), deal variety, the close
// look (a lead's flaw shows only where the hand has been), fair reason
// libraries, and the level in the shell (idle perf; guide first; a full clean
// flow with the coworker refused; a slip card; a deadly freeze; 3 slips fail;
// the coworker can't be skipped by a fast play; a tap that does nothing never
// refuses him; gesture hints show how, never what).
import 'dart:async';
import 'dart:math' as math;

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
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart' show FreezeFrame;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_meter_setup.dart';
import 'package:slm_flutter/features/game/m2_meter_setup_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '2.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '2.2',
  lessonTitleBn: '',
  ladderStep: 34,
  doIndex: 1,
  doCount: 2,
);

MeterItem _fit(MeterDeal d) => d.meters.firstWhere((m) => m.fit);
MeterItem _cat2(MeterDeal d) => d.meters.firstWhere((m) => m.cat == MeterCat.cat2);
MeterItem _flawed(MeterDeal d) => d.meters.firstWhere((m) => m.flaw != MeterFlaw.none);

/// The right set-up for the run's current job (pure).
void _setRight(MeterRun r) {
  r.plug(MeterLead.black, MeterSock.com);
  r.plug(MeterLead.red, MeterSock.vohm);
  switch (r.job!) {
    case MeterJob.acLt:
      r.setDial(MeterDial.vac);
    case MeterJob.dcBattery:
      r.setDial(MeterDial.vdc);
    case MeterJob.fuse:
      r.setIsolator(false);
      r.setDial(MeterDial.cont);
  }
}

/// Runs to the job [j] (the meter taken, earlier jobs done right).
MeterRun _runTo(int seed, MeterJob j) {
  final r = MeterRun(dealMeter(math.Random(seed)));
  r.take(_fit(r.deal));
  r.next();
  while (r.job != j) {
    _setRight(r);
    r.probe();
    if (r.judging) r.judge(r.deal.fuseGood);
    r.next();
  }
  return r;
}

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

int _seedWhere(bool Function(MeterDeal d) ok) {
  for (var s = 0;; s++) {
    if (ok(dealMeter(math.Random(s)))) return s;
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// Waits for the deck, taps the one right card on it, then the reason's
/// এগিয়ে যান (a coworker deck closes by itself).
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

IdleHintState _sceneHint(WidgetTester t) =>
    t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);

/// No word may sit only on the right cards (it would give the answer away).
void _noTellWords(String name, List<String> right, List<String> wrong, List<String> words) {
  for (final w in words) {
    if (!right.any((r) => r.contains(w))) continue;
    expect(wrong.any((x) => x.contains(w)), isTrue, reason: '$name: "$w" is only on the right cards');
  }
}

void main() {
  group('rules', () {
    test('every deal: one fit meter, one CAT II, one flawed; three jobs; the coworker is dealt', () {
      for (var s = 0; s < 60; s++) {
        final d = dealMeter(math.Random(s));
        expect(d.meters.where((m) => m.fit).length, 1);
        expect(d.meters.where((m) => m.cat == MeterCat.cat2).single.flaw, MeterFlaw.none);
        expect(_flawed(d).cat, isNot(MeterCat.cat2), reason: 'the flaw is found by hand, never by the label');
        expect(d.meters.map((m) => m.body).toSet().length, 3);
        expect(d.jobs.toSet(), MeterJob.values.toSet());
        expect(d.leftover, inInclusiveRange(0, 2));
        expect(d.callRound, d.push == MeterPush.anyMeter ? 0 : d.jobs.indexOf(MeterJob.acLt) + 1);
      }
    });

    test('a clean play: meter, then each job set right — each waits for its reason', () {
      final r = MeterRun(dealMeter(math.Random(3)));
      expect(r.take(_fit(r.deal)).verdict, MeterVerdict.right);
      expect(r.shown, isTrue);
      expect(r.round, 0);
      r.next();
      for (var i = 0; i < 3; i++) {
        _setRight(r);
        final o = r.probe();
        expect(o.verdict, MeterVerdict.right, reason: '${r.job}');
        if (r.job == MeterJob.fuse) {
          expect(r.judging, isTrue);
          expect(r.shown, isFalse, reason: 'the fuse is decided only once read');
          expect(r.reading, r.deal.fuseGood ? '000' : 'OL');
          expect(r.beeps, r.deal.fuseGood);
          expect(r.judge(r.deal.fuseGood).verdict, MeterVerdict.right);
        }
        expect(r.shown, isTrue);
        r.next();
      }
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.caught, containsAll([M2MeterLines.caughtCat, M2MeterLines.caughtAc, M2MeterLines.caughtDc, M2MeterLines.caughtFuse, M2MeterLines.caughtLeftover]));
    });

    test('deadly: the CAT II meter; the red lead in 10A on the live terminals', () {
      final a = MeterRun(dealMeter(math.Random(1)));
      expect(a.take(_cat2(a.deal)).mistake, M2MeterMistakes.catTwo);
      expect(a.ended, isTrue);

      final b = _runTo(1, MeterJob.acLt);
      _setRight(b);
      b.plug(MeterLead.red, MeterSock.a10);
      expect(b.probe().mistake, M2MeterMistakes.tenALive);
      expect(b.deadly, M2MeterMistakes.tenALive);
    });

    test('the leads left in 10A from a current job: dial at A, red in 10A', () {
      final d = dealMeter(math.Random(4));
      final r = _runTo(4, d.jobs[d.leftover]);
      expect(r.leftHere, isTrue);
      expect(r.dial, MeterDial.amp);
      expect(r.red, MeterSock.a10);
      expect(r.black, MeterSock.com);
      final other = _runTo(4, d.jobs[(d.leftover + 1) % 3]);
      expect(other.red, isNull);
      expect(other.dial, MeterDial.off);
    });

    test('slips on the jobs, each with its card; nudges cost nothing', () {
      DoMistake? slip(MeterJob j, void Function(MeterRun r) wrong) {
        final r = _runTo(2, j);
        _setRight(r);
        wrong(r);
        final o = r.probe();
        expect(r.deadly, isNull);
        return o.verdict == MeterVerdict.slip ? o.mistake : null;
      }

      expect(slip(MeterJob.acLt, (r) => r.setDial(MeterDial.vdc)), M2MeterMistakes.acNeedsVac);
      expect(slip(MeterJob.acLt, (r) => r.setDial(MeterDial.ohm)), M2MeterMistakes.ohmOnLive);
      expect(slip(MeterJob.acLt, (r) => r.setDial(MeterDial.cont)), M2MeterMistakes.ohmOnLive);
      expect(slip(MeterJob.acLt, (r) => r.setDial(MeterDial.amp)), M2MeterMistakes.ampOnLive);
      expect(slip(MeterJob.acLt, (r) {
        r.plug(MeterLead.red, MeterSock.com);
        r.plug(MeterLead.black, MeterSock.vohm);
      }), M2MeterMistakes.swapped);
      expect(slip(MeterJob.dcBattery, (r) => r.setDial(MeterDial.vac)), M2MeterMistakes.dcNeedsVdc);
      expect(slip(MeterJob.dcBattery, (r) => r.plug(MeterLead.red, MeterSock.a10)), M2MeterMistakes.tenAOther);
      expect(slip(MeterJob.fuse, (r) => r.setIsolator(true)), M2MeterMistakes.liveContinuity);
      expect(slip(MeterJob.fuse, (r) => r.setDial(MeterDial.vac)), M2MeterMistakes.fuseMode);
      expect(slip(MeterJob.fuse, (r) => r.setDial(MeterDial.ohm)), isNull, reason: 'Ω reads a fuse too');

      final n = _runTo(2, MeterJob.acLt);
      n.unplug(MeterLead.red);
      n.unplug(MeterLead.black);
      expect(n.probe().nudge, M2MeterLines.needLeads);
      _setRight(n);
      n.setDial(MeterDial.off);
      expect(n.probe().nudge, M2MeterLines.needOn);
      expect(n.slips, 0);

      final f = _runTo(2, MeterJob.fuse);
      _setRight(f);
      f.probe();
      expect(f.judge(!f.deal.fuseGood).mistake, M2MeterMistakes.fuseJudge);
      expect(f.judging, isTrue, reason: 'read again and say');
      expect(f.judge(f.deal.fuseGood).verdict, MeterVerdict.right);
    });

    test('the case: a flawed meter taken is a slip and goes aside; putting back gives nothing away', () {
      final r = MeterRun(dealMeter(math.Random(5)));
      final bad = _flawed(r.deal);
      expect(r.putBack(_fit(r.deal)), isFalse);
      expect(r.putBack(bad), isFalse, reason: 'not looked for');
      expect(r.putBack(_cat2(r.deal)), isTrue, reason: 'the label is read up close');
      r.spot(_fit(r.deal));
      expect(r.spotted, isEmpty);
      r.spot(bad);
      expect(r.putBack(bad), isTrue);
      expect(r.caught, containsAll([M2MeterLines.caughtCatAside, M2MeterLines.caughtFlaw]));
      expect(r.slips, 0);

      final s = MeterRun(dealMeter(math.Random(5)));
      final o = s.take(_flawed(s.deal));
      expect(o.verdict, MeterVerdict.slip);
      expect(o.mistake, switch (_flawed(s.deal).flaw) {
        MeterFlaw.cutLead => M2MeterMistakes.cutLead,
        MeterFlaw.rustyTip => M2MeterMistakes.rustyTip,
        _ => M2MeterMistakes.lowBattery,
      });
      expect(s.rejected, contains(_flawed(s.deal).id));
    });

    test('the coworker pushes only what is still there (his line fits the moment)', () {
      final a = MeterRun(dealMeter(math.Random(_seedWhere((d) => d.push == MeterPush.anyMeter))));
      expect(meterPushOpen(a), isTrue);
      a.putBack(_cat2(a.deal));
      expect(meterPushOpen(a), isFalse, reason: 'the CAT II meter lies aside');
      final s = _seedWhere((d) => d.push == MeterPush.socket && d.jobs[d.leftover] != MeterJob.acLt);
      final b = _runTo(s, MeterJob.acLt);
      expect(meterPushOpen(b), isTrue);
      b.plug(MeterLead.red, MeterSock.vohm);
      expect(meterPushOpen(b), isTrue, reason: 'the black lead is still loose');
      b.plug(MeterLead.black, MeterSock.com);
      expect(meterPushOpen(b), isFalse, reason: '"যেকোনো সকেটে লাগাও" after both leads went in right would not fit');
      b.plug(MeterLead.red, MeterSock.a10);
      expect(meterPushOpen(b), isTrue);
      _setRight(b);
      b.probe();
      expect(meterPushOpen(b), isFalse);
    });

    test('after a deadly move the run takes nothing more (no next round, no spot)', () {
      final r = MeterRun(dealMeter(math.Random(6)));
      r.take(_cat2(r.deal));
      expect(r.ended, isTrue);
      r.next();
      expect(r.round, 0);
      r.spot(_flawed(r.deal));
      expect(r.spotted, isEmpty);
      expect(r.take(_fit(r.deal)).verdict, MeterVerdict.nudge);
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 40; s++) dealMeter(math.Random(s))];
      expect(deals.map((d) => d.jobs.first).toSet().length, 3);
      expect(deals.map((d) => _flawed(d).flaw).toSet().length, 3);
      expect(deals.map((d) => _fit(d).cat).toSet(), {MeterCat.cat3, MeterCat.cat4});
      expect(deals.map((d) => d.meters.indexWhere((m) => m.fit)).toSet().length, 3);
      expect(deals.map((d) => d.push).toSet().length, 2);
      expect(deals.map((d) => d.fuseGood).toSet().length, 2);
      expect(deals.map((d) => d.leftover).toSet().length, 3);
    });

    test('the close look: a lead flaw shows only where the hand has been', () {
      final all = {for (var i = 0; i < kLeadBins; i++) i};
      expect(LeadsPainter.flawSeen(cutOn: true, rustOn: null, red: {}, black: all), isFalse);
      expect(LeadsPainter.flawSeen(cutOn: true, rustOn: null, red: {leadBin(0.46)}, black: {}), isTrue);
      expect(LeadsPainter.flawSeen(cutOn: false, rustOn: null, red: all, black: {0, 1}), isFalse);
      expect(LeadsPainter.flawSeen(cutOn: null, rustOn: false, red: {}, black: {kLeadBins - 1}), isTrue);
      expect(LeadsPainter.flawSeen(cutOn: null, rustOn: true, red: {leadBin(0.5)}, black: all), isFalse);
      expect(LeadsPainter.flawSeen(cutOn: null, rustOn: null, red: all, black: all), isFalse);
      const s = Size(300, 100);
      expect(LeadsPainter.uOf(s, LeadsPainter.at(s, true, 0.4).dx), closeTo(0.4, 0.01));
    });

    test('reason and choice libraries: same length, big enough, fit what was done', () {
      expectSameLength('meter', [for (final c in [MeterCat.cat3, MeterCat.cat4]) ...M2MeterLines.meterRight(c), ...M2MeterLines.meterMyths]);
      for (final c in [MeterCat.cat3, MeterCat.cat4]) {
        expectLibrary('meter ${c.name}', M2MeterLines.meterRight(c), M2MeterLines.meterMyths);
      }
      expectSameLength('ac', [...M2MeterLines.acRight, ...M2MeterLines.acWrong]);
      expectLibrary('ac', M2MeterLines.acRight, M2MeterLines.acWrong);
      expectSameLength('dc', [...M2MeterLines.dcRight, ...M2MeterLines.dcWrong]);
      expectLibrary('dc', M2MeterLines.dcRight, M2MeterLines.dcWrong);
      for (final g in [true, false]) {
        expectSameLength('fuse $g', [...M2MeterLines.fuseRight(g), ...M2MeterLines.fuseWrong(g)]);
        expectLibrary('fuse $g', M2MeterLines.fuseRight(g), M2MeterLines.fuseWrong(g));
        expect(M2MeterLines.fuseRight(g), contains(M2MeterLines.fuseResult(g)));
        expect(M2MeterLines.fuseWrong(g), contains(M2MeterLines.fuseResult(!g)));
      }
      for (final p in MeterPush.values) {
        final c = M2MeterLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        expect(LearnVoice.resolve(c.exitLine, rival: true), isNotNull, reason: 'his exit line is a recorded clip');
        expect(M2MeterLines.toRecord, contains(c.line));
      }
      // No answer giveaways: the right cards' key words are on wrong cards too.
      for (final c in [MeterCat.cat3, MeterCat.cat4]) {
        _noTellWords('meter', M2MeterLines.meterRight(c), M2MeterLines.meterMyths, ['CAT', 'III', 'IV', 'রেটিং', 'প্রোব', 'লিড', 'লিডও', 'ব্যাটারি', 'ব্যাটারিও', 'অক্ষত', 'লাইনের কাজে']);
      }
      _noTellWords('ac', M2MeterLines.acRight, M2MeterLines.acWrong, ['AC', 'V~', 'COM', 'VΩmA', 'ডায়াল', 'লাল', 'লাইনে', 'তাই', 'রেখেছি']);
      _noTellWords('dc', M2MeterLines.dcRight, M2MeterLines.dcWrong, ['DC', 'COM', 'VΩmA', 'ডায়াল', 'লাল', 'ব্যাটারিতে', 'তাই', 'ভোল্টে']);
      for (final g in [true, false]) {
        _noTellWords('fuse $g', M2MeterLines.fuseRight(g), M2MeterLines.fuseWrong(g),
            ['বন্ধ', 'কন্টিনিউটি', 'ফিউজ', 'ফিউজে', 'সুইচ', 'প্রোব', 'পাওয়ার', 'আগে', 'তারপর', 'তবেই', 'করে']);
      }
      // His deck: the socket and meter words on a refuse card are on a listen card too
      // (only the refusal itself — না / নয় — may differ).
      for (final p in MeterPush.values) {
        final c = M2MeterLines.coworker(p);
        _noTellWords('choice ${p.name}', c.right, c.wrong,
            ['VΩmA', '10A', 'লাল', 'লিড', 'সকেট', 'ভোল্টে', 'আন্দাজে', 'দেখে', 'থাকবে', 'লাগাব', 'কখনো', 'CAT', 'III', 'IV', 'রেটিং', 'মিটার', 'লাইনে', 'নেব']);
      }
      expect(M2MeterMistakes.all.map((m) => m.key).toSet().length, M2MeterMistakes.all.length);
      expect(M2MeterMistakes.all.where((m) => m.deadly), [M2MeterMistakes.catTwo, M2MeterMistakes.tenALive]);
      expect(m2MeterSetupPacks['do_2_2_a'], m2MeterPack22a);
    });

    test('English digits only: no Bangla digit in any line, card or label', () {
      final bnDigit = RegExp('[০-৯]');
      final texts = [
        M2MeterLines.title,
        M2MeterLines.intro,
        M2MeterLines.askMeter,
        M2MeterLines.inspectAsk,
        for (final j in MeterJob.values) ...[M2MeterLines.askJob(j), j.docketBn, j.dot],
        for (final c in MeterCat.values) ...[c.label, c.short],
        for (final s in MeterSock.values) s.label,
        M2MeterLines.batteryTag,
        ...M2MeterLines.meterMyths,
        ...M2MeterLines.acRight,
        ...M2MeterLines.acWrong,
        ...M2MeterLines.dcRight,
        ...M2MeterLines.dcWrong,
        for (final g in [true, false]) ...[...M2MeterLines.fuseRight(g), ...M2MeterLines.fuseWrong(g)],
        for (final p in MeterPush.values) ...[
          M2MeterLines.coworker(p).line,
          ...M2MeterLines.coworker(p).right,
          ...M2MeterLines.coworker(p).wrong,
          ...M2MeterLines.coworker(p).asks,
        ],
        for (final m in M2MeterMistakes.all) m.textBn,
        M2MeterLines.allSet,
        M2MeterLines.fail,
      ];
      for (final x in texts) {
        expect(bnDigit.hasMatch(x), isFalse, reason: x);
      }
      for (var s = 0; s < 20; s++) {
        final d = dealMeter(math.Random(s));
        expect(bnDigit.hasMatch(d.acVolts) || bnDigit.hasMatch(d.dcVolts), isFalse);
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
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    Future<(ProviderContainer, MeterDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = dealMeter(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M2MeterSetupPage(ctx: _ctx, pack: m2MeterPack22a, muted: true, seed: seed),
      )));
      await _pump(t, 1500);
      await waitIntro(t);
      return (c, deal);
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    final meters = _label(M2MeterLines.meterLabel);

    Future<void> lift(WidgetTester t, MeterDeal d, MeterItem it) async {
      await t.tap(meters.at(d.meters.indexOf(it)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(M2MeterLines.take), findsOneWidget);
    }

    Future<void> slide(WidgetTester t) async {
      final box = t.getRect(_label(M2MeterLines.handLabel));
      for (final y in [0.3, 0.72]) {
        final g = await t.startGesture(Offset(box.left + 4, box.top + box.height * y));
        for (var i = 1; i <= 20; i++) {
          await g.moveTo(Offset(box.left + 4 + (box.width - 8) * i / 20, box.top + box.height * y));
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tapL(WidgetTester t, String l) async {
      await t.tap(_label(l).last, warnIfMissed: false);
      await _pump(t, 200);
    }

    /// Plugs a lead into a socket by hand (pulls it out first if it sits elsewhere).
    Future<void> plug(WidgetTester t, String lead, String socket, String? from) async {
      if (from == socket) return;
      if (from != null) {
        await tapL(t, from);
      } else {
        await tapL(t, lead);
      }
      await tapL(t, socket);
    }

    /// Sets the meter right for [j]; [left] = the leads were left in 10A.
    Future<void> setJob(WidgetTester t, MeterJob j, bool left) async {
      await plug(t, M2MeterLines.blackLead, 'COM', left ? 'COM' : null);
      await plug(t, M2MeterLines.redLead, 'VΩmA', left ? '10A' : null);
      if (j == MeterJob.fuse) await tapL(t, M2MeterLines.isolatorLabel);
      await tapL(t, 'dial-${switch (j) {
        MeterJob.acLt => 'vac',
        MeterJob.dcBattery => 'vdc',
        MeterJob.fuse => 'cont',
      }}');
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the case (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(
            home: M2MeterSetupPage(ctx: _ctx, pack: m2MeterPack22a, muted: true, seed: _seedWhere((d) => d.push == MeterPush.socket)),
          ),
        ));
        await t.pump(const Duration(milliseconds: 100));
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
        debugPrint('PERF meter setup ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(find.text(M2MeterLines.docket), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('guide first: no start button, a tap does not skip; tapping him restates the task differently', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: M2MeterSetupPage(ctx: _ctx, pack: m2MeterPack22a, muted: true, seed: _seedWhere((d) => d.push == MeterPush.socket))),
      ));
      await _pump(t, 400);
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(360, 800));
      await _pump(t, 600);
      expect(find.byType(GuideIntro), findsOneWidget, reason: 'a tap does not skip');
      await waitIntro(t);
      final guide = t.getRect(find.byType(AiLinemanGuide).last);
      final heard = <String>{};
      for (var i = 0; i < 3; i++) {
        await t.tapAt(guide.bottomRight - const Offset(50, 50));
        await _pump(t, 200);
        final line = c.read(guideDirectorProvider).line;
        expect(line, contains(M2MeterLines.askMeter));
        heard.add(line);
      }
      expect(heard.length, 3);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: refuse the coworker, CAT II aside, inspect and take, three jobs by hand, reasons → pass', (t) async {
      final seed = _seedWhere((d) => d.push == MeterPush.anyMeter);
      final (c, deal) = await open(t, seed);

      // He peeps in at the case; refuse him.
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, M2MeterLines.coworkerAnyMeter.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      // The docket, read close.
      await t.tap(find.text(M2MeterLines.docket));
      await _pump(t, 500);
      expect(find.textContaining(deal.jobs.first.docketBn), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);

      // The CAT II meter: its label read up close, put back → aside.
      await lift(t, deal, _cat2(deal));
      expect(find.text(MeterCat.cat2.label), findsOneWidget);
      await t.tap(find.text(M2MeterLines.putBack));
      await _pump(t, 800);
      expect(find.text(M2MeterLines.rejected), findsOneWidget);

      // The fit meter: switch on, slide both leads, take it, say why.
      await lift(t, deal, _fit(deal));
      await tapL(t, M2MeterLines.knobLabel);
      await slide(t);
      await t.tap(find.text(M2MeterLines.take));
      await _pump(t, 3500);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _pickRight(t, M2MeterLines.meterRight(_fit(deal).cat));
      await _pump(t, 3500);

      for (var i = 0; i < 3; i++) {
        final j = deal.jobs[i];
        expect(find.text(M2MeterLines.probe), findsOneWidget, reason: 'the meter is in hand for ${j.name}');
        await setJob(t, j, deal.leftover == i);
        await t.tap(find.text(M2MeterLines.probe));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: j.name);
        if (j == MeterJob.fuse) {
          await t.tap(find.text(deal.fuseGood ? M2MeterLines.fuseOk : M2MeterLines.fuseBlown));
          await _pump(t, 3500);
          await _pickRight(t, M2MeterLines.fuseRight(deal.fuseGood));
        } else {
          await _pump(t, 3000);
          await _pickRight(t, j == MeterJob.acLt ? M2MeterLines.acRight : M2MeterLines.dcRight);
        }
        await _pump(t, i == 2 ? 6000 : 3500);
      }

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.2/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.2/do/0'], greaterThan(0));
      expect(find.text(M2MeterLines.caughtCall), findsOneWidget);
      expect(find.text(M2MeterLines.caughtLeftover), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to him at the case is the deadly CAT II meter (freeze, then the card)', (t) async {
      final (c, _) = await open(t, _seedWhere((d) => d.push == MeterPush.anyMeter));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(M2MeterLines.coworkerAnyMeter.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 700);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3000);
      expect(find.text(M2MeterMistakes.catTwo.textBn), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: a flawed meter is a slip card; red in 10A on the terminals freezes first, then the card', (t) async {
      // He comes on the terminal job (socket push), and the terminal job is first.
      final seed = _seedWhere((d) => d.push == MeterPush.socket && d.jobs.indexOf(MeterJob.acLt) == 2);
      final (c, deal) = await open(t, seed);
      await lift(t, deal, _flawed(deal));
      await t.tap(find.text(M2MeterLines.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(M2MeterLines.rejected), findsOneWidget);

      await lift(t, deal, _fit(deal));
      await t.tap(find.text(M2MeterLines.take));
      await _pump(t, 3500);
      await _pickRight(t, M2MeterLines.meterRight(_fit(deal).cat));
      await _pump(t, 3500);

      // Job 1 (not the terminals): the red lead in 10A — a slip there.
      final j1 = deal.jobs[0];
      await setJob(t, j1, deal.leftover == 0);
      await plug(t, M2MeterLines.redLead, '10A', 'VΩmA');
      await t.tap(find.text(M2MeterLines.probe));
      await _pump(t, 600);
      expect(find.text(M2MeterMistakes.tenAOther.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.length, greaterThanOrEqualTo(2));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('deadly: the leads in 10A on the live terminals freeze the scene first, then the card', (t) async {
      final seed = _seedWhere((d) => d.push == MeterPush.anyMeter && d.jobs.first == MeterJob.acLt && d.leftover == 0);
      final (c, deal) = await open(t, seed);
      // Refuse him first.
      await _pump(t, 3500);
      await _pickRight(t, M2MeterLines.coworkerAnyMeter.right);
      await _pump(t, 2500);
      await lift(t, deal, _fit(deal));
      await t.tap(find.text(M2MeterLines.take));
      await _pump(t, 3500);
      await _pickRight(t, M2MeterLines.meterRight(_fit(deal).cat));
      await _pump(t, 3500);
      // The leads were left in 10A: probing as they are is the short.
      await tapL(t, 'dial-vac');
      await t.tap(find.text(M2MeterLines.probe));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'the scene freezes first');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.text(M2MeterMistakes.tenALive.textBn), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('a fast play cannot skip him at the case: the first pick waits for him, then works', (t) async {
      final (c, deal) = await open(t, _seedWhere((d) => d.push == MeterPush.anyMeter));
      // Straight after the guide's line (before his 1.2–2.4 s timer): pick a meter.
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(meters.at(0), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the pick waits for him; he comes now');
      expect(find.text(M2MeterLines.take), findsNothing, reason: 'nothing lifted while he cuts in');
      await _pickRight(t, M2MeterLines.coworkerAnyMeter.right);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await lift(t, deal, _fit(deal));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('a fast play cannot skip him on the terminals: the first lead touch waits for him', (t) async {
      final seed = _seedWhere((d) => d.push == MeterPush.socket && d.jobs.first == MeterJob.acLt && d.leftover != 0);
      final (c, deal) = await open(t, seed);
      await lift(t, deal, _fit(deal));
      await t.tap(find.text(M2MeterLines.take));
      await _pump(t, 3500);
      await _pickRight(t, M2MeterLines.meterRight(_fit(deal).cat));
      // The terminal job is up; at once (well before his timer) lift the red lead.
      expect(find.byType(CoworkerPeek), findsNothing);
      await tapL(t, M2MeterLines.redLead);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'touching a lead waits for him; he comes now');
      await _pickRight(t, M2MeterLines.coworkerSocket.right);
      await _pump(t, 2500);
      // Then the job goes on as usual, and the probe is not held again.
      await setJob(t, MeterJob.acLt, false);
      await t.tap(find.text(M2MeterLines.probe));
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _pickRight(t, M2MeterLines.acRight);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('while he talks, a tap that does nothing (the isolator at the case) never refuses him; a real move does', (t) async {
      CoworkerTiming.debugReadHoldInTests = true;
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final (c, deal) = await open(t, _seedWhere((d) => d.push == MeterPush.anyMeter));
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'beat 1: his caption is held for reading');
      await tapL(t, M2MeterLines.isolatorLabel);
      await _pump(t, 1200);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the isolator is no part of the case: not a refusal');
      expect(find.text(M2MeterLines.take), findsNothing);
      // A real move: pick a meter up to read its label — refuses him, and the close look opens.
      await t.tap(meters.at(deal.meters.indexOf(_cat2(deal))), warnIfMissed: false);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(find.text(M2MeterLines.take), findsOneWidget, reason: 'any meter (even the CAT II) lifts: his leaving tells nothing');
      expect(find.byType(FreezeFrame), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    group('gesture hint', () {
      setUp(() => GestureHints.debugEnableInTests = true);
      tearDown(() => GestureHints.debugEnableInTests = false);

      testWidgets('the case gets a sweep over every meter; the close look a drag along the leads, then a sweep over put back / take', (t) async {
        final (c, deal) = await open(t, _seedWhere((d) => d.push == MeterPush.socket));
        expect(_sceneHint(t).showing, isFalse);
        await _pump(t, 9000);
        var h = _sceneHint(t);
        expect(h.showing, isTrue, reason: 'idle 8 s at the case');
        expect(h.debugOptions, hasLength(3), reason: 'all three meters, none singled out');
        expect(h.debugFrame!.ripple, isNull, reason: 'a sweep presses nothing');
        await lift(t, deal, _fit(deal));
        await _pump(t, 9000);
        h = _sceneHint(t);
        expect(h.showing, isTrue, reason: 'idle in the close look');
        expect(h.debugOptions, isEmpty, reason: 'a drag along the lead — not a sweep, never a tap on take or put back');
        await slide(t);
        await _pump(t, 9000);
        h = _sceneHint(t);
        expect(h.showing, isTrue);
        expect(h.debugOptions, hasLength(2), reason: 'put back and take, swept alike');
        expect(t.takeException(), isNull);
        await close(t, c);
      });

      testWidgets('three taps on nothing (the isolator at the case) show the hand at once; none under a card', (t) async {
        final (c, deal) = await open(t, _seedWhere((d) => d.push == MeterPush.socket));
        expect(_sceneHint(t).showing, isFalse);
        for (var i = 0; i < 3; i++) {
          await tapL(t, M2MeterLines.isolatorLabel);
        }
        expect(_sceneHint(t).showing, isTrue);
        await _pump(t, 6000);
        // A slip card: the level no longer waits, so no hand.
        await lift(t, deal, _flawed(deal));
        await t.tap(find.text(M2MeterLines.take));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget);
        await _pump(t, 10000);
        expect(_sceneHint(t).showing, isFalse, reason: 'no hand under a card');
        expect(t.takeException(), isNull);
        await close(t, c);
      });

      testWidgets('no hand while he talks, under his deck, or under the reason deck', (t) async {
        final (c, deal) = await open(t, _seedWhere((d) => d.push == MeterPush.anyMeter));
        // He peeps in and his deck comes up; idle well past the hint delay.
        var sawDeck = false;
        for (var i = 0; i < 26; i++) {
          await _pump(t, 500);
          final up = find.byType(CoworkerPeek).evaluate().isNotEmpty || find.byType(ChoiceDeck).evaluate().isNotEmpty;
          if (find.byType(ChoiceDeck).evaluate().isNotEmpty) sawDeck = true;
          if (up) expect(_sceneHint(t).showing, isFalse, reason: 'no hand while he is on screen (${i * 500} ms)');
        }
        expect(sawDeck, isTrue, reason: 'his deck came up');
        await _pickRight(t, M2MeterLines.coworkerAnyMeter.right);
        await _pump(t, 2500);
        // The meter taken: the reason deck comes up; idle under it.
        await lift(t, deal, _fit(deal));
        await t.tap(find.text(M2MeterLines.take));
        await waitChoiceDeck(t);
        for (var i = 0; i < 24; i++) {
          await _pump(t, 500);
          expect(find.byType(ChoiceDeck), findsOneWidget);
          expect(_sceneHint(t).showing, isFalse, reason: 'no hand under the reason deck (${i * 500} ms)');
        }
        expect(t.takeException(), isNull);
        await close(t, c);
      });
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, deal) = await open(t, _seedWhere((d) => d.push == MeterPush.socket && d.jobs.first != MeterJob.acLt));
      await lift(t, deal, _fit(deal));
      await t.tap(find.text(M2MeterLines.take));
      await _pump(t, 3500);
      await _pickRight(t, M2MeterLines.meterRight(_fit(deal).cat));
      await _pump(t, 3500);
      // Swapped leads on job 1, three times.
      await plug(t, M2MeterLines.redLead, 'COM', deal.leftover == 0 ? '10A' : null);
      await plug(t, M2MeterLines.blackLead, 'VΩmA', null);
      await tapL(t, 'dial-vdc');
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(M2MeterLines.probe));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1}');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await t.tap(find.text(M2MeterLines.probe));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.2/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
