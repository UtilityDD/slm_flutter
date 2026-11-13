// Lesson 3.6 (ডিস্ট্রিবিউশন ট্রান্সফরমার), কাজ 1 "ডাক্তারের চোখে DTR": the rules
// (the full check-up from the ground first; the call — OK / repair docket /
// urgent shutdown — fits the signs; an over-call is a slip; the coworker's
// two pushes), the deal, the reason libraries, the gel colours of the lesson
// (pink / whitish), and the level in the shell: idle perf, the guide first, a
// full clean play (coworker refused), an over-call slip card, a slip card,
// three slips strike out, the coworker on a fast call, his leak push (a slip),
// his climb push (deadly: freeze first, then the card), the gesture hint.
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
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_dtr_checkup.dart';
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
  rungId: '3.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '3.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m3DtrCheckupPacks['do_3_6_a']!;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_dtr_checkup/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(b.buffer);
    }
    return rootBundle.load(key);
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
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3DtrCheckupGeo get _geo => M3DtrCheckupGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

String _lensName() {
  final f = find.byKey(const ValueKey('lens-name'));
  return f.evaluate().isEmpty ? '' : (f.evaluate().first.widget as Text).data ?? '';
}

Future<void> _look(WidgetTester t, M3DtrCheckupSpot s) async {
  if (s == M3DtrCheckupSpot.sound) {
    await t.tap(_label(M3DtrCheckupLines.listen));
  } else {
    await t.tapAt(_geo.spotAt(s) * _k);
  }
  await _pump(t, 500);
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
    builder: (_) => M3DtrCheckupPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1500);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Plays DTR [i] right: every look, the coworker refused on his DTR, the
/// lesson's call, the right reason.
Future<void> _playRight(WidgetTester t, M3DtrCheckupDeal deal, int i) async {
  final c = deal.cases[i];
  var cwDone = false;
  for (final s in M3DtrCheckupSpot.values) {
    await _look(t, s);
    expect(_lensName(), M3DtrCheckupLines.spotName(s), reason: 'DTR $i looked at ${s.name}');
    if (i == deal.callAt && !cwDone && (deal.push == M3DtrCheckupPush.climb || s == M3DtrCheckupSpot.tank)) {
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 3500), isTrue, reason: 'he comes on DTR $i');
      cwDone = true;
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M3DtrCheckupLines.coworker(deal.push).right);
      await _pump(t, 1500);
    }
  }
  await t.tap(find.text(M3DtrCheckupLines.callLabel(c.verdict)));
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'DTR $i ${c.verdict}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'DTR $i');
  await _pump(t, 700);
  await _pickRight(t, M3DtrCheckupLines.whyRight(c, c.verdict));
  await _pump(t, 4000);
}

int _seedWhere(bool Function(M3DtrCheckupDeal d) ok) {
  var s = 0;
  while (!ok(m3DtrCheckupDeal(math.Random(s)))) {
    s++;
  }
  return s;
}

void main() {
  const healthy = M3DtrCheckupLook(gel: M3DtrCheckupGel.orange, oilLow: false, leak: M3DtrCheckupLeak.none, rattle: false, kva: 100);
  const pinkGel = M3DtrCheckupLook(gel: M3DtrCheckupGel.pink, oilLow: false, leak: M3DtrCheckupLeak.none, rattle: false, kva: 63);
  const leaky = M3DtrCheckupLook(gel: M3DtrCheckupGel.blue, oilLow: true, leak: M3DtrCheckupLeak.drain, rattle: false, kva: 250);
  const rattly = M3DtrCheckupLook(gel: M3DtrCheckupGel.white, oilLow: false, leak: M3DtrCheckupLeak.none, rattle: true, kva: 25);

  group('rules', () {
    M3DtrCheckupRun run1(M3DtrCheckupLook l, {M3DtrCheckupPush push = M3DtrCheckupPush.climb}) =>
        M3DtrCheckupRun(M3DtrCheckupDeal(cases: [M3DtrCheckupCase(id: 'x', look: l)], callAt: 0, push: push));
    void lookAll(M3DtrCheckupRun r) {
      for (final s in M3DtrCheckupSpot.values) {
        r.look(s);
      }
    }

    test('deals: one healthy, one repair, one urgent; fresh signs; the leak push lands on a leaking DTR', () {
      final seen = <String>{};
      final pushes = <M3DtrCheckupPush>{};
      for (var s = 0; s < 80; s++) {
        final d = m3DtrCheckupDeal(math.Random(s));
        expect(d.cases.length, 3);
        expect(d.cases.map((c) => c.verdict).toSet(), M3DtrCheckupCall.values.toSet());
        expect(d.cases.map((c) => c.look.kva).toSet().length, 3);
        for (final c in d.cases) {
          if (c.verdict == M3DtrCheckupCall.ok) {
            expect(c.findings, isEmpty);
            expect(m3DtrCheckupGelSpent(c.look.gel), isFalse);
          }
        }
        if (d.push == M3DtrCheckupPush.leak) {
          final c = d.cases[d.callAt];
          expect(c.verdict, M3DtrCheckupCall.repair);
          expect(c.look.leak, isNot(M3DtrCheckupLeak.none));
        }
        pushes.add(d.push);
        final key = d.cases.map((c) => '${c.look.gel}${c.look.oilLow}${c.look.leak}${c.look.rattle}').join('|');
        seen.add('$key${d.callAt}${d.push}');
      }
      expect(seen.length, greaterThan(50), reason: 'every play is dealt fresh');
      expect(pushes, M3DtrCheckupPush.values.toSet());
    });

    test('the full check-up, then the lesson\'s call: right', () {
      for (final (l, call, tag) in [
        (healthy, M3DtrCheckupCall.ok, M3DtrCheckupLines.caughtHealthy),
        (pinkGel, M3DtrCheckupCall.repair, M3DtrCheckupLines.caughtGel),
        (leaky, M3DtrCheckupCall.repair, M3DtrCheckupLines.caughtLeak),
        (rattly, M3DtrCheckupCall.urgent, M3DtrCheckupLines.caughtRattle),
      ]) {
        final r = run1(l);
        lookAll(r);
        expect(r.fullCheck, isTrue);
        expect(r.decide(call), isNull);
        expect(r.shown, isTrue);
        expect(r.caught, containsAll([M3DtrCheckupLines.caughtFull, tag]));
      }
      final l = run1(leaky);
      lookAll(l);
      expect(l.decide(M3DtrCheckupCall.urgent), isNull, reason: 'a leak with low oil may be called urgent');
      expect(l.shown, isTrue);
      expect(l.caught, contains(M3DtrCheckupLines.caughtOilLow));
    });

    test('a call before the full check-up is a slip', () {
      final r = run1(healthy)
        ..look(M3DtrCheckupSpot.breather)
        ..look(M3DtrCheckupSpot.gauge);
      expect(r.decide(M3DtrCheckupCall.ok), M3DtrCheckupMistakes.unchecked);
      expect(r.slips, 1);
      expect(r.look(M3DtrCheckupSpot.tank), isFalse, reason: 'the DTR is closed once called');
    });

    test('signing off a sick DTR: the slip names the missed sign; a rattle needs urgent', () {
      for (final (l, call, m) in [
        (pinkGel, M3DtrCheckupCall.ok, M3DtrCheckupMistakes.gelSpent),
        (leaky, M3DtrCheckupCall.ok, M3DtrCheckupMistakes.leakIgnored),
        (const M3DtrCheckupLook(gel: M3DtrCheckupGel.blue, oilLow: true, leak: M3DtrCheckupLeak.none, rattle: false, kva: 63), M3DtrCheckupCall.ok,
            M3DtrCheckupMistakes.oilLow),
        (rattly, M3DtrCheckupCall.ok, M3DtrCheckupMistakes.rattleIgnored),
        (rattly, M3DtrCheckupCall.repair, M3DtrCheckupMistakes.rattleIgnored),
      ]) {
        final r = run1(l);
        lookAll(r);
        expect(r.decide(call), m);
        expect(r.slips, 1);
        expect(r.shown, isTrue);
      }
    });

    test('an over-call is a slip (audit 2026-11-11): the DTR closes, the card teaches', () {
      for (final (l, call, m) in [
        (healthy, M3DtrCheckupCall.repair, M3DtrCheckupMistakes.overCall),
        (healthy, M3DtrCheckupCall.urgent, M3DtrCheckupMistakes.overCall),
        (pinkGel, M3DtrCheckupCall.urgent, M3DtrCheckupMistakes.overCallGel),
      ]) {
        final r = run1(l);
        lookAll(r);
        expect(r.decide(call), m, reason: '$call on $l');
        expect(r.shown, isTrue);
        expect(r.slips, 1);
        expect(r.decide(M3DtrCheckupCall.ok), isNull, reason: 'no second try on the same DTR');
        expect(r.slips, 1);
      }
    });

    test('gel colours are the lesson\'s: blue / orange good, pink / whitish spent (no green)', () {
      expect(M3DtrCheckupGel.values.map((g) => g.name).toSet(), {'blue', 'orange', 'pink', 'white'});
      expect(m3DtrCheckupGelSpent(M3DtrCheckupGel.blue), isFalse);
      expect(m3DtrCheckupGelSpent(M3DtrCheckupGel.orange), isFalse);
      expect(m3DtrCheckupGelSpent(M3DtrCheckupGel.pink), isTrue);
      expect(m3DtrCheckupGelSpent(M3DtrCheckupGel.white), isTrue);
      final all = [
        ...M3DtrCheckupLines.okWhy,
        ...M3DtrCheckupLines.okWrong,
        ...M3DtrCheckupLines.faultWrong,
        M3DtrCheckupLines.gelPinkWhy,
        M3DtrCheckupLines.gelWhiteWhy,
        M3DtrCheckupLines.gelWhy,
        ...M3DtrCheckupMistakes.all.map((m) => m.textBn),
      ];
      for (final t in all) {
        expect(t.contains('সবুজ'), isFalse, reason: t);
      }
      const whiteGel = M3DtrCheckupLook(gel: M3DtrCheckupGel.white, oilLow: false, leak: M3DtrCheckupLeak.none, rattle: false, kva: 63);
      expect(M3DtrCheckupLines.whyRight(const M3DtrCheckupCase(id: 'x', look: whiteGel), M3DtrCheckupCall.repair), contains(M3DtrCheckupLines.gelWhiteWhy));
      for (var s = 0; s < 60; s++) {
        for (final c in m3DtrCheckupDeal(math.Random(s)).cases) {
          if (m3DtrCheckupGelSpent(c.look.gel)) expect(c.findings, contains(M3DtrCheckupFinding.gel));
        }
      }
    });

    test('his pushes: the leak signed off on his word is the leak slip; the climb is deadly', () {
      final a = run1(leaky, push: M3DtrCheckupPush.leak)..look(M3DtrCheckupSpot.tank);
      expect(a.decide(M3DtrCheckupCall.ok, pushed: true), M3DtrCheckupMistakes.leakIgnored);
      final b = run1(healthy)..look(M3DtrCheckupSpot.breather);
      expect(b.climb(), M3DtrCheckupMistakes.climbLive);
      expect(b.climb(), isNull);
      expect(b.ended, isTrue);
      expect(M3DtrCheckupMistakes.climbLive.deadly, isTrue);
    });

    test('three slips: the mark drops to 55 (the page strikes out on the third — see the widget test)', () {
      final run = M3DtrCheckupRun(M3DtrCheckupDeal(
        cases: [for (var i = 0; i < 3; i++) const M3DtrCheckupCase(id: 'x', look: pinkGel)],
        callAt: 0,
        push: M3DtrCheckupPush.climb,
      ));
      for (var i = 0; i < 3; i++) {
        expect(run.decide(M3DtrCheckupCall.ok), M3DtrCheckupMistakes.unchecked);
        run.next();
      }
      expect(run.done, isTrue);
      expect(run.percent, 55);
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded; the mistakes', () {
      final looks = <M3DtrCheckupLook>[healthy, pinkGel, leaky, rattly];
      for (final gel in M3DtrCheckupGel.values) {
        for (final low in [false, true]) {
          for (final leak in M3DtrCheckupLeak.values) {
            for (final rattle in [false, true]) {
              looks.add(M3DtrCheckupLook(gel: gel, oilLow: low, leak: leak, rattle: rattle, kva: 100));
            }
          }
        }
      }
      for (final l in looks) {
        final c = M3DtrCheckupCase(id: 'x', look: l);
        for (final call in M3DtrCheckupCall.values.where(c.accepts)) {
          final right = M3DtrCheckupLines.whyRight(c, call);
          final wrong = M3DtrCheckupLines.whyWrong(call);
          expectLibrary('why ${call.name} $l', right, wrong);
          expectSameLength('why ${call.name}', [...right, ...wrong]);
          for (var s = 0; s < 6; s++) {
            final deal = dealChoices(right, wrong, math.Random(s));
            expect(deal.where((o) => o.correct).length, 1);
            expect(deal.map((o) => o.textBn).toSet().length, 3);
          }
        }
      }
      expect(M3DtrCheckupLines.whyRight(const M3DtrCheckupCase(id: 'x', look: pinkGel), M3DtrCheckupCall.repair), contains(M3DtrCheckupLines.gelPinkWhy));
      for (final p in M3DtrCheckupPush.values) {
        final cw = M3DtrCheckupLines.coworker(p);
        expectSameLength('choice ${p.name}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${p.name}', cw.right, cw.wrong);
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
        expect(M3DtrCheckupLines.recordLines, contains(cw.line));
      }
      final keys = M3DtrCheckupMistakes.all.map((m) => m.key).toList();
      expect(keys.toSet().length, keys.length);
      for (final m in M3DtrCheckupMistakes.all) {
        expect(m.key, startsWith('3.6/m3_dtr_checkup/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m3DtrCheckupPacks.keys, ['do_3_6_a']);
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M3DtrCheckupPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
        ));
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
        debugPrint('PERF m3_dtr_checkup ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3DtrCheckupPage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M3DtrCheckupLines.callOk), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      for (final call in M3DtrCheckupCall.values) {
        expect(find.text(M3DtrCheckupLines.callLabel(call)), findsOneWidget);
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 3);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M3DtrCheckupLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final push in M3DtrCheckupPush.values) {
      testWidgets('flow (${push.name} push): full check-up on all three, the right calls, coworker refused → pass', (t) async {
        final seed = _seedWhere((d) => d.push == push);
        final deal = m3DtrCheckupDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playRight(t, deal, i);
        }
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['3.6/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['3.6/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M3DtrCheckupLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
        await _close(t, c);
      });
    }

    testWidgets('an over-call on a healthy DTR costs a slip: the card, no reason deck, the next DTR', (t) async {
      final seed = _seedWhere((d) => d.cases[0].verdict == M3DtrCheckupCall.ok && d.push == M3DtrCheckupPush.leak && d.callAt != 0);
      final c = await _open(t, seed);
      for (final s in M3DtrCheckupSpot.values) {
        await _look(t, s);
      }
      await t.tap(find.text(M3DtrCheckupLines.callRepair));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3DtrCheckupMistakes.overCall.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M3DtrCheckupLines.callOk), findsOneWidget, reason: 'the next DTR is open');
      await _close(t, c);
    });

    testWidgets('three slips: the level strikes out (StruckOutCard)', (t) async {
      // The leak push: he comes only once the tank is seen — never here.
      final seed = _seedWhere((d) => d.push == M3DtrCheckupPush.leak);
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _look(t, M3DtrCheckupSpot.breather);
        await t.tap(find.text(M3DtrCheckupLines.callOk));
        await _pump(t, 800);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1}');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 1500);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(LevelPassPanel), findsNothing);
      expect(c.read(gameSaveProvider).rungProgress['3.6/do/1'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    for (final push in M3DtrCheckupPush.values) {
      testWidgets('a fast call can\'t skip the coworker (${push.name} push): the call waits, he comes', (t) async {
        final seed = _seedWhere((d) => d.push == push && d.callAt == 0);
        final deal = m3DtrCheckupDeal(math.Random(seed));
        final verdict = M3DtrCheckupLines.callLabel(deal.cases[0].verdict);
        final c = await _open(t, seed);
        // Every look in a rush (the tank last, so the leak push is set just
        // before the call), then the call at once.
        for (final s in [M3DtrCheckupSpot.breather, M3DtrCheckupSpot.gauge, M3DtrCheckupSpot.nameplate, M3DtrCheckupSpot.sound, M3DtrCheckupSpot.tank]) {
          if (s == M3DtrCheckupSpot.sound) {
            await t.tap(_label(M3DtrCheckupLines.listen));
          } else {
            await t.tapAt(_geo.spotAt(s) * _k);
          }
          await t.pump(const Duration(milliseconds: 60));
        }
        expect(find.byType(CoworkerPeek), findsNothing, reason: 'not yet (his timer is 1.2–2.4 s)');
        await t.tap(find.text(verdict));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he comes in on the call');
        expect(find.byType(MistakeCard), findsNothing);
        await _pumpUntil(t, find.byType(ChoiceDeck));
        await _pump(t, 600);
        await _pickRight(t, M3DtrCheckupLines.coworker(push).right);
        await _pump(t, 1500);
        // The call was held, not taken: the DTR is still open.
        expect(find.text(verdict), findsOneWidget);
        await t.tap(find.text(verdict));
        await _pump(t, 1500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck after the right call');
        await _pump(t, 700);
        await _pickRight(t, M3DtrCheckupLines.whyRight(deal.cases[0], deal.cases[0].verdict));
        await _pump(t, 3000);
        expect(c.read(gameSaveProvider).mistakes, isEmpty);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a call on his DTR before any look can\'t skip the climb push: he comes, the call waits', (t) async {
      final seed = _seedWhere((d) => d.push == M3DtrCheckupPush.climb && d.callAt == 0);
      final c = await _open(t, seed);
      await t.tap(find.text(M3DtrCheckupLines.callOk));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he comes in on the call');
      expect(find.byType(MistakeCard), findsNothing, reason: 'the call was held, not taken');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M3DtrCheckupLines.coworkerClimb.right);
      await _pump(t, 1500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      // Now the call is taken: unchecked (no look yet) — the usual slip.
      await t.tap(find.text(M3DtrCheckupLines.callOk));
      await _pump(t, 800);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3DtrCheckupMistakes.unchecked.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('praise window: taps on the DTR or where the calls were do nothing until the reason deck', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      final deal = m3DtrCheckupDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (final s in M3DtrCheckupSpot.values) {
        await _look(t, s);
      }
      final right = find.text(M3DtrCheckupLines.callLabel(deal.cases[0].verdict));
      final okAt = t.getCenter(find.text(M3DtrCheckupLines.callOk));
      final urgentAt = t.getCenter(find.text(M3DtrCheckupLines.callUrgent));
      await t.tap(right);
      await confirmChoice(t);
      await t.pump(const Duration(milliseconds: 120));
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'still the praise window');
      // Taps in the praise window: on a part of the DTR and where the calls were.
      await t.tapAt(_geo.spotAt(M3DtrCheckupSpot.breather) * _k);
      await t.tapAt(okAt);
      await t.tapAt(urgentAt);
      await t.pump(const Duration(milliseconds: 100));
      expect(_lensName(), '', reason: 'no look while the ◆ waits on the table');
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, M3DtrCheckupLines.whyRight(deal.cases[0], deal.cases[0].verdict));
      await _pump(t, 3000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(find.text(M3DtrCheckupLines.callOk), findsOneWidget, reason: 'the next DTR is open');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hint: a sweep while the DTR waits; taps on the sky show it sooner; none over a card', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final hand = find.byKey(const ValueKey('gesture-hint'));
      final seed = _seedWhere((d) => d.push == M3DtrCheckupPush.leak);
      final c = await _open(t, seed);
      expect(hand, findsNothing);
      await _pump(t, 9000);
      expect(hand, findsOneWidget, reason: 'idle while the DTR waits');
      final spec = t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(spec.showing, isTrue);
      await _look(t, M3DtrCheckupSpot.breather);
      expect(hand, findsNothing, reason: 'a touch hides it');
      for (var i = 0; i < 3; i++) {
        await t.tapAt(const Offset(40, 250) * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      await _pump(t, 600);
      expect(hand, findsOneWidget, reason: 'three taps on nothing');
      // Never over a card.
      await t.tap(find.text(M3DtrCheckupLines.callOk));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, 9000);
      expect(hand, findsNothing, reason: 'no hand over a card');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a call before the full check-up: the slip card', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      final c = await _open(t, seed);
      await _look(t, M3DtrCheckupSpot.breather);
      await t.tap(find.text(M3DtrCheckupLines.callOk));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3DtrCheckupMistakes.unchecked.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('his leak push, listened to: the leak slip', (t) async {
      final seed = _seedWhere((d) => d.push == M3DtrCheckupPush.leak && d.callAt == 0);
      final c = await _open(t, seed);
      await _look(t, M3DtrCheckupSpot.tank);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickWrong(t, M3DtrCheckupLines.coworkerLeak.wrong);
      await _pump(t, 1200);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3DtrCheckupMistakes.leakIgnored.key);
      await _close(t, c);
    });

    testWidgets('his climb push, listened to: deadly — freeze first, then the card', (t) async {
      final seed = _seedWhere((d) => d.push == M3DtrCheckupPush.climb && d.callAt == 0);
      final c = await _open(t, seed);
      await _look(t, M3DtrCheckupSpot.gauge);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickWrong(t, M3DtrCheckupLines.coworkerClimb.wrong);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3DtrCheckupMistakes.climbLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
