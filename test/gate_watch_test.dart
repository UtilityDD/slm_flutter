// Ladder step 30, the Module 1 rank gate "প্রথম ডকেট" (gate_watch): the
// hazard-spotting deal (10–12 moments in the job's order, about half wrong, ≥ 2
// deadly-class, mistakes from 4+ lessons, varied over seeds), every moment's
// cue / tap zone / reasons / card, the option libraries (lengths within 1.3×),
// the coworker's recorded lines, the wiring (catalog, doGameFor, mistakes
// book), and the page: the guide first, a full play that passes the gate
// (stopping every mistake, letting right moments pass, refusing the coworker)
// with the rank-up, a missed deadly mistake (freeze → near-miss), a needless
// stop (a slip), three slips (strike-out), and the stop button waiting for
// the coworker (holdForCoworker).
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
import 'package:slm_flutter/features/game/do_games.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gate_watch.dart';
import 'package:slm_flutter/features/game/gate_watch_world.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/mistakes_book.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: 'm1/gate',
  kind: CatalogRungKind.gate,
  lessonId: '1.10',
  lessonTitleBn: '',
  ladderStep: 30,
);

final _pack = gateWatchPacks['gate_m1']!;

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

Future<void> _until(WidgetTester t, bool Function() ok, {int maxMs = 30000, String? reason}) async {
  for (var ms = 0; ms < maxMs && !ok(); ms += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
  expect(ok(), isTrue, reason: reason);
}

/// Taps the one right card among [right] on the deck now up (and its proceed).
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await _until(t, () => right.any((r) => _label(r).hitTestable().evaluate().isNotEmpty), maxMs: 8000, reason: 'deck with ${right.first}');
  final r = [for (final x in right) if (_label(x).evaluate().isNotEmpty) _label(x)];
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await confirmChoice(t);
  await t.pump();
  for (var i = 0; i < 60 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty && find.byType(ChoiceDeck).evaluate().isNotEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

Future<ProviderContainer> _open(WidgetTester t, int seed, GateWatchProbe probe) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => GateWatchPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe),
  )));
  await _pump(t, 600);
  await waitIntro(t);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

final _stop = find.byKey(const ValueKey('gate-stop'));

/// Waits until moment [i] plays.
Future<void> _waitPlay(WidgetTester t, GateWatchProbe p, int i) =>
    _until(t, () => p.index == i && p.phase == 'play', reason: 'moment $i plays');

/// Catches the mistake of the moment now playing: stop (or refuse the
/// coworker), tap where, "কী ভুল?", the fix, then the crew redoes it.
Future<void> _catch(WidgetTester t, GateWatchProbe p) async {
  final f = p.moment!.fault!;
  final i = p.index;
  if (i == p.deal!.coworkerAt) {
    // His push comes once the mistake is in view (never before): refuse him.
    await _until(t, () => find.text(GateLines.coworker.line).evaluate().isNotEmpty, maxMs: 9000, reason: 'he comes');
    expect(p.t, greaterThanOrEqualTo(f.slot.stillT), reason: 'not before the mistake is in view');
    await waitChoiceDeckUp(t);
    await _pickRight(t, GateLines.coworker.right);
  } else {
    await _pump(t, 300);
    await t.tap(_stop, warnIfMissed: false);
    await t.pump();
  }
  await _until(t, () => p.phase == 'spot', maxMs: 8000, reason: 'stopped at $i');
  await _pump(t, 200);
  await t.tapAt(p.zoneGlobal()!);
  await t.pump();
  expect(p.phase, 'what', reason: 'found ${f.name}');
  expect(find.byKey(const ValueKey('lens')), findsOneWidget);
  await _pickRight(t, f.what);
  await _until(t, () => p.phase == 'fix', maxMs: 4000);
  await _pickRight(t, f.fix);
  await _until(t, () => p.index > i || p.phase == 'done', maxMs: 12000, reason: 'the job goes on after $i');
}

Future<void> waitChoiceDeckUp(WidgetTester t) async {
  final cards = find.descendant(of: find.byType(ChoiceDeck), matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.button ?? false)));
  await _until(t, () => cards.hitTestable().evaluate().length == 3, maxMs: 10000, reason: 'deck up');
}

/// A seed whose deal meets [ok].
int _seedWhere(bool Function(GateDeal d) ok) {
  for (var s = 1; s < 4000; s++) {
    if (ok(dealGate(math.Random(s)))) return s;
  }
  throw StateError('no seed');
}

void main() {
  group('rules', () {
    test('the deal: 10–12 moments in the job order, about half wrong, ≥ 2 deadly, mistakes from 4+ lessons, varied', () {
      final sigs = <String>{};
      final faultsSeen = <GateFault>{};
      final slotsSeen = <GateSlot>{};
      for (var s = 0; s < 200; s++) {
        final d = dealGate(math.Random(s));
        final n = d.moments.length;
        expect(n, inInclusiveRange(10, 12));
        for (var i = 1; i < n; i++) {
          expect(d.moments[i].slot.index, greaterThan(d.moments[i - 1].slot.index), reason: 'job order');
        }
        final faults = [for (final m in d.moments) ?m.fault];
        expect(faults.length, inInclusiveRange(n ~/ 2 - 1, n ~/ 2 + 1), reason: 'about half wrong');
        expect(faults.where((f) => f.deadly).length, greaterThanOrEqualTo(2));
        expect({for (final f in faults) f.lessonId}.length, greaterThanOrEqualTo(4));
        expect(d.coworkerAt, greaterThanOrEqualTo(1));
        expect(d.moments[d.coworkerAt].right, isFalse, reason: 'he pushes on a mistake');
        for (final f in faults) {
          expect(f.slot, isIn([for (final m in d.moments) m.slot]));
        }
        if (faults.contains(GateFault.wrongRating)) expect(d.docket.kv, 33, reason: 'an 11 kV rod on a 33 kV docket');
        expect(d.docket.permitFeeder != d.docket.feeder, faults.contains(GateFault.wrongFeeder));
        sigs.add([for (final m in d.moments) '${m.slot.name}:${m.fault?.name}'].join(','));
        faultsSeen.addAll(faults);
        slotsSeen.addAll([for (final m in d.moments) m.slot]);
      }
      expect(sigs.length, greaterThan(190), reason: 'every play dealt fresh');
      expect(faultsSeen, GateFault.values.toSet(), reason: 'the whole library comes up');
      expect(slotsSeen, GateSlot.values.toSet());
    });

    test('every moment: a lesson 1.1–1.9, a cue zone at its still, a card; done right has no zone', () {
      final g = GateGeo(780, 0);
      final keys = <String>{};
      for (final f in GateFault.values) {
        expect(['1.1', '1.2', '1.3', '1.4', '1.5', '1.6', '1.8', '1.9'], contains(f.lessonId));
        final m = f.mistake;
        expect(m.deadly, f.deadly, reason: f.name);
        expect(m.lessonPoint, isNotNull, reason: f.name);
        expect(keys.add(m.key), isTrue, reason: 'unique key ${m.key}');
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(GateLines.caught(f), isNotEmpty);
        final s = GateShot(slot: f.slot, fault: f, t: f.slot.stillT, kv: 33, feeder: 'ক ফিডার', permitFeeder: 'খ ফিডার', poleNo: 17);
        final zones = gateZones(s, g);
        expect(zones, isNotEmpty, reason: f.name);
        final cam = gateCamFor(f.slot, g);
        for (final z in zones) {
          final c = cam.rectToScreen(z, g.h).center;
          expect(c.dx, inInclusiveRange(0, 360), reason: '${f.name} zone on screen');
          expect(c.dy, inInclusiveRange(0, g.h), reason: '${f.name} zone on screen');
        }
      }
      for (final slot in GateSlot.values) {
        expect(gateFaultsOf(slot), isNotEmpty);
        final s = GateShot(slot: slot, fault: null, t: slot.stillT, kv: 11, feeder: 'ক', permitFeeder: 'ক', poleNo: 12);
        expect(gateZones(s, g), isEmpty);
        expect(gateLookAreas(slot.spot, g), hasLength(greaterThanOrEqualTo(3)));
      }
      expect(File(GateMistakes.falseStop.art).existsSync(), isTrue);
      // The owner-approved deadly lists (Module 1).
      for (final f in [GateFault.polyester, GateFault.nail, GateFault.pinhole, GateFault.cotton, GateFault.bamboo, GateFault.phonePermit, GateFault.wrongFeeder, GateFault.wrongRating, GateFault.jugaadRod, GateFault.waistBelt, GateFault.hollow, GateFault.lineFirst, GateFault.skipDischarge, GateFault.brokenArm, GateFault.lightning, GateFault.waterFire]) {
        expect(f.deadly, isTrue, reason: f.name);
      }
      for (final f in [GateFault.vented, GateFault.strapOpen, GateFault.sleeves, GateFault.chestHigh, GateFault.skipCheck, GateFault.hive, GateFault.keptPermit]) {
        expect(f.deadly, isFalse, reason: f.name);
      }
    });

    test('the run: a needless stop and a missed slip are slips, a missed deadly ends it, 100 − 15 per slip', () {
      final d = dealGate(math.Random(3));
      final r = GateRun(d);
      final right = d.moments.indexWhere((m) => m.right);
      r.index = right;
      expect(r.stop(), GateMistakes.falseStop);
      expect(r.slips, 1);
      expect(r.letPass(), isNull);
      final slipAt = d.moments.indexWhere((m) => !m.right && !m.deadly);
      if (slipAt >= 0) {
        r.index = slipAt;
        expect(r.stop(), isNull, reason: 'a real catch');
        expect(r.letPass(), d.moments[slipAt].fault!.mistake);
        expect(r.slips, 2);
      }
      final deadAt = d.moments.indexWhere((m) => m.deadly);
      // Listening to the coworker = the slip, even on a deadly-class mistake
      // (booked as a slip: it must not use a near-miss).
      final pushed = GateRun(d)..index = deadAt;
      final ps = pushed.letPass(pushed: true)!;
      expect(ps.deadly, isFalse);
      expect(ps.key, d.moments[deadAt].fault!.mistake.key);
      expect(pushed.slips, 1);
      expect(pushed.ended, isFalse);
      r.index = deadAt;
      expect(r.letPass()!.deadly, isTrue);
      expect(r.ended, isTrue);
      expect(r.passed, isFalse);
      final ok = GateRun(d)..index = d.moments.length;
      expect(ok.passed, isTrue);
      expect(ok.percent, 100);
      ok.slips = 3;
      expect(ok.percent, 55);
      expect(ok.passed, isTrue);
    });

    test('option libraries: 1 right of ≥ 2, wrong from ≥ 5, all within 1.3×; no English-word giveaways', () {
      final allWhat = <String>[];
      final allFix = <String>[...GateLines.excuses];
      for (final f in GateFault.values) {
        for (final kv in [11, 33]) {
          if (kv == 11 && f == GateFault.wrongRating) continue;
          final ww = gateWhatWrong(f, kv: kv);
          final fw = gateFixWrong(f, kv: kv);
          expectLibrary('what ${f.name} $kv', f.what, ww);
          expectLibrary('fix ${f.name} $kv', f.fix, fw);
          for (final r in f.what) {
            expect(ww, isNot(contains(r)));
          }
        }
        allWhat.addAll(f.what);
        allFix.addAll(f.fix);
      }
      expectSameLength('what', allWhat);
      expectSameLength('fix', allFix);
      final cw = GateLines.coworker;
      expectLibrary('coworker', cw.right, cw.wrong);
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      // An 11 kV docket never deals the 33 kV rod line as a wrong card.
      expect(gateWhatWrong(GateFault.jugaadRod, kv: 11).any((l) => l.contains('33 kV')), isFalse);
    });

    test('English digits on screen; the fixed words', () {
      final bnDigit = RegExp('[০-৯]');
      final lines = [
        GateLines.intro, GateLines.watch, GateLines.where, GateLines.allFine, ...GateLines.excuses,
        for (final f in GateFault.values) ...[...f.what, ...f.fix, f.mistake.textBn, GateLines.caught(f)],
        GateMistakes.falseStop.textBn, ...GateLines.coworker.right, ...GateLines.coworker.wrong,
        GateSceneWords.fiveMin, GateSceneWords.permitIn, GateSceneWords.phoneSays,
      ];
      for (final l in lines) {
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
      }
      final d = dealGate(math.Random(9)).docket;
      expect(GateLines.docketLine(d), contains('${d.kv} kV'));
      expect(GateLines.docketLine(d), contains('পোল ${d.poleNo}'));
    });

    test("the coworker's lines are in his recorded voice", () {
      for (final l in GateLines.coworker.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
    });

    test('wiring: the catalog, doGameFor and the mistakes book', () {
      final cat = jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map;
      final pack = (cat['gamePacks'] as List).cast<Map>().firstWhere((p) => p['id'] == 'gate_m1');
      expect(pack['engineType'], 'gate_watch');
      expect(pack['status'], 'playable');
      final rung = (cat['rungDefs'] as List).cast<Map>().firstWhere((r) => r['id'] == 'm1/gate');
      expect(rung['status'], 'playable');
      final b = doGameFor(const CatalogGamePack(
        id: 'gate_m1',
        engineType: 'gate_watch',
        lessonId: null,
        moduleId: 'm1',
        slot: null,
        status: CatalogRungStatus.playable,
        legacyHint: null,
        deadlyRules: [],
      ));
      expect(b, isNotNull);
      expect(b!(_ctx, true), isA<GateWatchPage>());
      for (final m in GateMistakes.all) {
        expect(knownMistakes[m.key], same(m), reason: m.key);
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

    testWidgets('the guide comes first with the docket: no start button, a tap does not skip', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final p = GateWatchProbe();
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: GateWatchPage(ctx: _ctx, pack: _pack, muted: true, seed: 4, probe: p))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      expect(find.text(GateLines.docketLine(p.deal!.docket)), findsOneWidget);
      expect(find.text(p.deal!.docket.job), findsOneWidget);
      await t.tapAt(const Offset(200, 500));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget, reason: 'a tap does not skip');
      await waitIntro(t);
      expect(p.phase, isIn(['travel', 'play']));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('a full play passes the gate: every mistake stopped, right moments let pass, the coworker refused → rank-up', (t) async {
      final seed = _seedWhere((d) => d.moments.length == 10);
      final p = GateWatchProbe();
      final c = await _open(t, seed, p);
      final d = p.deal!;
      for (var i = 0; i < d.moments.length; i++) {
        await _waitPlay(t, p, i);
        if (d.moments[i].right) {
          expect(_stop, findsOneWidget, reason: 'the stop is there while a moment plays');
          await _until(t, () => p.index > i || p.phase == 'done', maxMs: 12000, reason: 'right moment $i passes');
        } else {
          await _catch(t, p);
        }
      }
      await _until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 8000);
      expect(find.text(GateLines.rankTo), findsOneWidget);
      expect(find.text(GateLines.caughtCall), findsOneWidget);
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress['m1/gate'], 'cleared');
      expect(save.rankIndex, 2, reason: 'ট্রেইনি → জুনিয়র');
      expect(save.starsByRung['m1/gate'] ?? 0, greaterThanOrEqualTo(2));
      expect(save.mistakes, isEmpty);
      // The pass panel waits quietly.
      await _pump(t, 14000);
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (t.binding.hasScheduledFrame) frames++;
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(frames, lessThan(12), reason: 'idle on the pass panel');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a missed deadly mistake plays out: freeze, then the near-miss card', (t) async {
      final seed = _seedWhere((d) {
        final first = d.moments.indexWhere((m) => !m.right);
        return first >= 0 && d.moments[first].deadly && first != d.coworkerAt;
      });
      final p = GateWatchProbe();
      final c = await _open(t, seed, p);
      final d = p.deal!;
      final first = d.moments.indexWhere((m) => !m.right);
      await _waitPlay(t, p, first);
      await _until(t, () => p.phase == 'freeze', maxMs: 9000, reason: 'it plays out');
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('harm')), findsOneWidget);
      expect(_stop, findsNothing);
      await _until(t, () => find.text(MistakeLines.nearMissHead).evaluate().isNotEmpty, maxMs: 6000);
      expect(find.text(d.moments[first].fault!.mistake.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['m1/gate'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('a needless stop is a slip ("সব তো ঠিক ছিল!"); three slips strike the gate out', (t) async {
      final seed = _seedWhere((d) => d.moments.take(5).where((m) => m.right).length >= 3);
      final p = GateWatchProbe();
      final c = await _open(t, seed, p);
      final d = p.deal!;
      var slips = 0;
      for (var i = 0; slips < 3; i++) {
        await _waitPlay(t, p, i);
        if (d.moments[i].right) {
          await _pump(t, 300);
          await t.tap(_stop, warnIfMissed: false);
          await t.pump();
          await _pump(t, 200);
          expect(find.text(GateLines.allFine), findsOneWidget);
          slips++;
          if (slips < 3) {
            await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 4000);
            expect(find.text(GateMistakes.falseStop.textBn), findsOneWidget);
            await t.tap(find.text(MistakeLines.gotIt));
            await t.pump();
          }
        } else {
          await _catch(t, p);
        }
      }
      await _until(t, () => find.byType(StruckOutCard).evaluate().isNotEmpty, maxMs: 4000);
      expect(c.read(gameSaveProvider).rungProgress['m1/gate'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('a missed slip-class mistake shows its card; the stop waits for the coworker on his moment', (t) async {
      final seed = _seedWhere((d) {
        final first = d.moments.indexWhere((m) => !m.right);
        return first >= 0 && !d.moments[first].deadly && first != d.coworkerAt;
      });
      final p = GateWatchProbe();
      final c = await _open(t, seed, p);
      final d = p.deal!;
      for (var i = 0; i < d.coworkerAt; i++) {
        await _waitPlay(t, p, i);
        final mo = d.moments[i];
        if (mo.right) {
          await _until(t, () => p.index > i, maxMs: 12000);
        } else if (i == d.moments.indexWhere((m) => !m.right)) {
          // Let the first (slip-class) mistake pass.
          await _until(t, () => find.text(MistakeLines.slipHead).evaluate().isNotEmpty, maxMs: 9000);
          expect(find.text(mo.fault!.mistake.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await t.pump();
        } else {
          await _catch(t, p);
        }
      }
      // His moment: a stop at once waits for him (he comes now).
      await _waitPlay(t, p, d.coworkerAt);
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(_stop, warnIfMissed: false);
      await t.pump();
      await _pump(t, 100);
      expect(find.text(GateLines.coworker.line), findsWidgets, reason: 'he comes now');
      expect(p.phase, 'play', reason: 'the stop waited for him');
      await waitChoiceDeckUp(t);
      // Listening = the slip: the mistake plays out, then its card (a slip
      // card even for a deadly-class mistake — no freeze, no near-miss).
      await _pickRight(t, GateLines.coworker.wrong.where((w) => _label(w).evaluate().isNotEmpty).take(1).toList());
      final f = d.moments[d.coworkerAt].fault!;
      await _until(t, () => find.text(f.mistake.textBn).evaluate().isNotEmpty, maxMs: 9000);
      expect(p.phase, 'card');
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });
    testWidgets('gesture hint in a stop: a sweep over the same broad areas whatever the mistake; it presses nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      const hand = ValueKey('gesture-hint');
      final seed = _seedWhere((d) => d.moments.indexWhere((m) => !m.right) != d.coworkerAt);
      final p = GateWatchProbe();
      final c = await _open(t, seed, p);
      final first = p.deal!.moments.indexWhere((m) => !m.right);
      await _waitPlay(t, p, first);
      await _pump(t, 200);
      await t.tap(_stop, warnIfMissed: false);
      await t.pump();
      expect(p.phase, 'spot');
      IdleHintState hint() => t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(hint().widget.waiting, isTrue, reason: 'the stop waits for a tap');
      await _pump(t, 9500);
      expect(find.byKey(hand), findsOneWidget, reason: 'idle in a stop');
      final slot = p.moment!.slot;
      expect(hint().debugOptions, hasLength(gateLookAreas(slot.spot, GateGeo(780, 0)).length), reason: 'the broad areas, not the zone');
      expect(p.phase, 'spot', reason: 'a hint presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
