// Lesson 2.8 (ফেজ সিকোয়েন্স মিটার), কাজ 1 "ঘূর্ণন পড়ুন": the reading rules
// (leads on their own phases read the truth, two crossed read it reversed, no
// reading with the switch OFF or a lead missing), the deal, the run's rules
// (bare hand on live = deadly, a damaged lead, wrong clips, misreads, the
// coworker), reason libraries that fit the meter and the reading, and the
// level in the shell: idle perf, the guide first, a full clean play (gloves,
// leads, switch, clips, read, call, reasons, the fix, the coworker refused),
// the deadly freeze, and three slips striking the level out.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_phase_meter.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '2.8/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '2.8',
  lessonTitleBn: '',
  ladderStep: 1,
  doIndex: 1,
  doCount: 2,
);

final _pack = m2PhaseMeterPacks['do_2_8_a']!;

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
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await t.pump();
  // Wait for reason zoom (coworker decks have no proceed).
  for (var i = 0; i < 40 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
}

/// Design px → screen px on the 392 × 850 test screen (the scene fits it).
const _k = 392 / 360;
PmGeo get _geo => PmGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _screen(Offset design) => design * _k;

/// The mistake pictures live in a new folder the director adds to pubspec;
/// until then the test serves them from the repo (everything else from the
/// test bundle, as flutter_test does).
void _serveAssets() {
  final dir = Platform.environment['UNIT_TEST_ASSETS'] ?? 'build/unit_test_assets';
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (ByteData? message) {
    final key = Uri.decodeFull(utf8.decode(message!.buffer.asUint8List()));
    for (final f in [File('$dir/$key'), File(key)]) {
      if (f.existsSync()) return SynchronousFuture<ByteData>(Uint8List.fromList(f.readAsBytesSync()).buffer.asByteData());
    }
    return null;
  });
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
    builder: (_) => M2PhaseMeterPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

Future<void> _clip(WidgetTester t, PmPhase lead, int slot) async {
  await t.tapAt(_screen(pmParkRect(_geo, lead).center));
  await _pump(t, 200);
  await t.tapAt(_screen(pmTerminalRect(_geo, slot).center));
  await _pump(t, 300);
}

/// Plays pump house [i] right: (his push refused), gloves, leads (another
/// meter when one is cracked), the switch ON, R-Y-B on their own tags, the
/// call, the reason, the motor run (and the fix when reversed).
Future<void> _playRight(WidgetTester t, PmDeal deal, int i) async {
  final c = deal.cases[i];
  final his = i == deal.callAt;
  if (his && deal.push == PmPush.skipTest) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on pump $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, PmLines.skipScript.right);
    await _pump(t, 1600);
  }
  await t.tap(_label(PmLines.gloves));
  await _pump(t, 300);
  await t.tap(_label(PmLines.inspect));
  await _pump(t, 500);
  await t.tap(_label(c.badLead != null ? PmLines.leadsSwap : PmLines.leadsOk));
  await _pump(t, 400);
  if (!c.liveAtStart) {
    await t.tapAt(_screen(_geo.mainSwitch.center));
    await _pump(t, 300);
  }
  for (final (n, lead) in PmPhase.values.indexed) {
    await _clip(t, lead, c.order.indexOf(lead));
    if (n == 0 && his && deal.push == PmPush.anyClip) {
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he cuts in on pump $i');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, PmLines.clipScript.right);
      await _pump(t, 1600);
    }
  }
  await t.tap(find.text(c.fwd ? PmLines.fwd : PmLines.rev));
  await _pump(t, 300);
  expect(find.byType(MistakeCard), findsNothing, reason: 'pump $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, PmLines.whyRight(c));
  await _pump(t, c.fwd ? 6000 : 9500);
}

void main() {
  group('rules', () {
    test('the reading: own phases read the truth, a cyclic shift too, two crossed reverse it, blank when off or a lead missing', () {
      const r = PmPhase.r, y = PmPhase.y, b = PmPhase.b;
      final own = {r: r, y: y, b: b};
      expect(pmRead(live: true, clips: own, fwd: true), PmReading.fwd);
      expect(pmRead(live: true, clips: own, fwd: false), PmReading.rev);
      expect(pmRead(live: true, clips: {r: y, y: b, b: r}, fwd: true), PmReading.fwd, reason: 'a cyclic shift keeps the order');
      expect(pmRead(live: true, clips: {r: r, y: b, b: y}, fwd: true), PmReading.rev, reason: 'Y and B crossed');
      expect(pmRead(live: true, clips: {r: y, y: r, b: b}, fwd: false), PmReading.fwd);
      expect(pmRead(live: false, clips: own, fwd: true), PmReading.blank);
      expect(pmRead(live: true, clips: {r: r, y: y}, fwd: true), PmReading.blank);
    });

    test('deals: three pumps, one right and one reversed at least, both meters; plays differ', () {
      final seen = <String>{};
      final pushes = <PmPush>{};
      var bad = 0, off = 0, shuffled = 0;
      final cables = <PmCables>{};
      for (var s = 0; s < 100; s++) {
        final d = dealPhase(math.Random(s));
        expect(d.cases.length, 3);
        expect(d.cases.where((c) => c.fwd), isNotEmpty);
        expect(d.cases.where((c) => !c.fwd), isNotEmpty, reason: 'always calling right must not win');
        expect(d.cases.map((c) => c.meter).toSet(), PmMeter.values.toSet());
        expect(d.cases.where((c) => c.badLead != null).length, lessThanOrEqualTo(1));
        expect(d.cases.where((c) => !c.liveAtStart).length, lessThanOrEqualTo(1));
        expect(d.callAt, inInclusiveRange(0, 2));
        pushes.add(d.push);
        for (final c in d.cases) {
          expect(c.order.toSet().length, 3);
          if (c.order.join() != PmPhase.values.join()) shuffled++;
          cables.add(c.cables);
        }
        if (d.cases.any((c) => c.badLead != null)) bad++;
        if (d.cases.any((c) => !c.liveAtStart)) off++;
        final key = d.cases.map((c) => '${c.fwd}${c.meter.name}${c.liveAtStart}${c.order.map((p) => p.name).join()}${c.cables.name}${c.badLead}').join('|');
        seen.add('$key${d.callAt}${d.push}');
      }
      expect(seen.length, greaterThan(90), reason: 'every play is dealt fresh');
      expect(pushes, PmPush.values.toSet());
      expect(cables, PmCables.values.toSet());
      expect(bad, inInclusiveRange(40, 80));
      expect(off, inInclusiveRange(40, 80));
      expect(shuffled, greaterThan(40));
    });

    PmCase pump({bool fwd = true, bool live = true, PmPhase? bad, PmMeter meter = PmMeter.disc}) => PmCase(
          id: 'x',
          fwd: fwd,
          meter: meter,
          liveAtStart: live,
          order: PmPhase.values,
          cables: PmCables.standard,
          job: PmJob.newConnection,
          badLead: bad,
        );
    PmRun run1(PmCase c) => PmRun(PmDeal(cases: [c], callAt: 0, push: PmPush.skipTest));
    void clipAll(PmRun r) {
      for (final l in PmPhase.values) {
        expect(r.clip(l, l), isNull);
      }
    }

    test('bare hand on a live terminal is deadly; on a dead box a slip', () {
      final a = run1(pump());
      final m = a.clip(PmPhase.r, PmPhase.r);
      expect(m, PmMistakes.bareLive);
      expect(m!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = run1(pump(live: false));
      expect(b.clip(PmPhase.r, PmPhase.r), PmMistakes.bareDead);
      expect(b.slips, 1);
      expect(b.deadly, isNull);
      expect(b.shown, isTrue);
    });

    test('a cracked lead: using that meter is a slip; another meter is fine (and caught)', () {
      final a = run1(pump(bad: PmPhase.y))..putGloves();
      expect(a.inspect(), isTrue);
      expect(a.clip(PmPhase.r, PmPhase.r), PmMistakes.badLead, reason: 'the meter itself is not fit');
      final b = run1(pump(bad: PmPhase.y))
        ..putGloves()
        ..inspect()
        ..takeSpare();
      expect(b.badNow, isNull);
      clipAll(b);
      expect(b.decide(fwd: true), isNull);
      expect(b.caught, contains(PmLines.caughtLead));
      expect(b.thorough, isTrue);
      // Another meter when the leads were fine: harmless.
      final c = run1(pump())
        ..putGloves()
        ..takeSpare();
      clipAll(c);
      expect(c.decide(fwd: true), isNull);
      expect(c.thorough, isFalse, reason: 'not looked at');
    });

    test('the call: blank, wrong clips, misreads are slips; right calls are caught', () {
      final off = run1(pump(live: false))..putGloves();
      clipAll(off);
      expect(off.reading, PmReading.blank);
      expect(off.decide(fwd: true), PmMistakes.blank);
      final on = run1(pump(live: false))..putGloves();
      clipAll(on);
      on.toggleSwitch();
      expect(on.reading, PmReading.fwd);
      expect(on.decide(fwd: true), isNull);
      expect(on.caught, containsAll([PmLines.caughtFwd, PmLines.caughtLive]));
      final crossed = run1(pump())..putGloves();
      crossed
        ..clip(PmPhase.r, PmPhase.r)
        ..clip(PmPhase.y, PmPhase.b)
        ..clip(PmPhase.b, PmPhase.y);
      expect(crossed.reading, PmReading.rev);
      expect(crossed.decide(fwd: false), PmMistakes.wrongClip, reason: 'the reading is not this line');
      final cyc = run1(pump())..putGloves();
      cyc
        ..clip(PmPhase.r, PmPhase.y)
        ..clip(PmPhase.y, PmPhase.b)
        ..clip(PmPhase.b, PmPhase.r);
      expect(cyc.decide(fwd: true), PmMistakes.wrongClip, reason: 'right by luck is still wrong clips');
      final rev = run1(pump(fwd: false))..putGloves();
      clipAll(rev);
      expect(rev.reading, PmReading.rev);
      expect(rev.decide(fwd: true), PmMistakes.missedReverse);
      final fw = run1(pump())..putGloves();
      clipAll(fw);
      expect(fw.decide(fwd: false), PmMistakes.falseReverse);
      final ok = run1(pump(fwd: false))..putGloves();
      clipAll(ok);
      expect(ok.decide(fwd: false), isNull);
      ok.fix();
      expect(ok.reading, PmReading.fwd, reason: 'Y and B swapped');
      expect(ok.caught, containsAll([PmLines.caughtRev, PmLines.caughtSwap]));
      expect(ok.slips, 0);
    });

    test('a lead clipped onto a taken terminal moves the other back to the meter', () {
      final r = run1(pump())..putGloves();
      r.clip(PmPhase.r, PmPhase.y);
      r.clip(PmPhase.y, PmPhase.y);
      expect(r.clips, {PmPhase.y: PmPhase.y});
      r.unclip(PmPhase.y);
      expect(r.clips, isEmpty);
    });

    test('listening to him is a slip (untested start, any clip)', () {
      final a = run1(pump());
      expect(a.listen(PmPush.skipTest), PmMistakes.untested);
      expect(a.slips, 1);
      final b = run1(pump());
      expect(b.listen(PmPush.anyClip), PmMistakes.anyClip);
    });

    test('the lesson only: English digits, every mistake has its picture and a lesson point (0–2); one deadly', () {
      final all = <String>[
        PmLines.intro,
        ...PmLines.tasks,
        PmLines.fixLine,
        PmLines.runLine,
        ...PmLines.whyRight(pump()),
        ...PmLines.whyRight(pump(fwd: false, meter: PmMeter.digital)),
        ...PmLines.fwdMyths,
        ...PmLines.revMyths,
        for (final s in [PmLines.skipScript, PmLines.clipScript]) ...[...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        for (final m in PmMistakes.all) m.textBn,
        PmLines.allSet,
        PmLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
      }
      expect(PmMistakes.all.where((m) => m.deadly), [PmMistakes.bareLive]);
      for (final m in PmMistakes.all) {
        expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
        expect(m.key, startsWith('2.8/phase/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m2PhaseMeterPacks.keys, ['do_2_8_a']);
      expect(_pack.quickMs, 80000);
    });

    test('reasons fit the meter and the reading, same length, big enough; his choices too', () {
      final every = <String>{
        PmLines.fwdDisc,
        PmLines.fwdDigital,
        PmLines.fwdMatched,
        PmLines.revDisc,
        PmLines.revDigital,
        ...PmLines.revSwap,
        ...PmLines.fwdMyths,
        ...PmLines.revMyths,
      }.toList();
      expectSameLength('why', every);
      final rules = {PmLines.fwdDisc, PmLines.fwdDigital, PmLines.fwdMatched, PmLines.revDisc, PmLines.revDigital, ...PmLines.revSwap};
      for (final fwd in [true, false]) {
        for (final meter in PmMeter.values) {
          final c = pump(fwd: fwd, meter: meter);
          final right = PmLines.whyRight(c);
          final wrong = PmLines.whyWrong(c);
          expectLibrary('$fwd$meter', right, wrong);
          expect(wrong.toSet().intersection(rules), isEmpty);
          expect(right.any((x) => x.contains(meter == PmMeter.disc ? 'ডিস্ক' : (fwd ? 'FWD' : 'REV'))), isTrue);
          expect(right.any((x) => x.contains(fwd ? 'R-Y-B' : 'R-B-Y')), isTrue);
          for (var s = 0; s < 10; s++) {
            final deal = dealChoices(right, wrong, math.Random(s));
            expect(deal.where((o) => o.correct).length, 1);
            expect(deal.map((o) => o.textBn).toSet().length, 3);
          }
        }
      }
      for (final s in [PmLines.skipScript, PmLines.clipScript]) {
        expectSameLength('choice', [...s.right, ...s.wrong]);
        expectLibrary('choice', s.right, s.wrong);
        // His exit line is recorded; his pushes go by TTS until recorded.
        expect(LearnVoice.resolve(s.exitLine, rival: true), isNotNull);
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
      _serveAssets();
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        var seed = 0;
        while (dealPhase(math.Random(seed)).callAt == 0) {
          seed++;
        }
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M2PhaseMeterPage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
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
        debugPrint('PERF m2_phase_meter ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the buttons', (t) async {
      const seed = 3;
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M2PhaseMeterPage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(PmLines.fwd), findsNothing);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.text(PmLines.fwd), findsOneWidget);
      expect(find.text(PmLines.jobBn(dealPhase(math.Random(seed)).cases[0].job)), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      var seed = 0;
      while (dealPhase(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(PmLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final push in PmPush.values) {
      testWidgets('flow (${push.name}): gloves, leads, switch, clips, read, call, reason, fix; he is refused → pass', (t) async {
        // A deal with a cracked lead and a switch found OFF.
        var seed = 0;
        late PmDeal deal;
        while (true) {
          deal = dealPhase(math.Random(seed));
          if (deal.push == push && deal.cases.any((c) => c.badLead != null) && deal.cases.any((c) => !c.liveAtStart)) break;
          seed++;
        }
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playRight(t, deal, i);
        }
        await _pump(t, 1500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['2.8/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['2.8/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(PmLines.caughtCall), findsOneWidget);
        expect(find.text(PmLines.caughtSwap), findsOneWidget);
        expect(find.text(PmLines.caughtLead), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a bare hand on a live terminal: the room freezes first, then the card (near-miss)', (t) async {
      var seed = 0;
      while (true) {
        final d = dealPhase(math.Random(seed));
        if (d.callAt != 0 && d.cases[0].liveAtStart) break;
        seed++;
      }
      final c = await _open(t, seed);
      await _clip(t, PmPhase.r, dealPhase(math.Random(seed)).cases[0].order.indexOf(PmPhase.r));
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, PmMistakes.bareLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips (a call with no reading; listening to him) strike the level out', (t) async {
      final deal = dealPhase(math.Random(5));
      final c = await _open(t, 5);
      for (var i = 0; i < 3; i++) {
        if (i == deal.callAt && deal.push == PmPush.skipTest) {
          expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
        } else {
          await t.tap(find.text(PmLines.fwd));
          await _pump(t, 300);
        }
        if (i == deal.callAt) {
          // He cuts in on the call; listen to him.
          expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
          await _pumpUntil(t, find.byType(ChoiceDeck));
          await _pump(t, 600);
          await _pickWrong(t, PmLines.script(deal.push).wrong);
          await _pump(t, 900);
        }
        if (i < 2) {
          expect(await _pumpUntil(t, find.byType(MistakeCard), maxMs: 3000), isTrue, reason: 'slip $i');
          expect(find.text(MistakeLines.slipHead), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 900);
        }
      }
      expect(await _pumpUntil(t, find.byType(StruckOutCard), maxMs: 3000), isTrue);
      final s = c.read(gameSaveProvider);
      // The book keeps one entry per mistake (two blank calls are one entry).
      expect(s.mistakes.map((x) => x.key), containsAll([PmMistakes.blank.key, PmLines.script(deal.push) == PmLines.skipScript ? PmMistakes.untested.key : PmMistakes.anyClip.key]));
      expect(s.rungProgress['2.8/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
