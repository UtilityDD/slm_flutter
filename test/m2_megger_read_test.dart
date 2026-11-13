// Lesson 2.7 (মেগার), কাজ 2 "পড়ুন আর ছাড়ুন": the IR-test rules (daily check,
// discharge first, L on the core / E on the armour, 500 V for 415 V, the full
// minute, ≥ 1 MΩ good / < 1 MΩ weak, discharge again before the L clip comes
// off), the deal, the reason libraries, and the level in the shell: idle perf,
// the guide first, tap-the-guide, a full clean play with the coworker refused,
// a slip card, and the deadly freeze (the L clip off a charged core, also on
// the coworker's say-so).
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
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_megger_read.dart';
import 'package:slm_flutter/features/game/m2_megger_read_world.dart';
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
  rungId: '2.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '2.7',
  lessonTitleBn: '',
  ladderStep: 40,
  doIndex: 2,
  doCount: 2,
);

final _pack = m2MeggerPacks['do_2_7_b']!;

/// The level's art folder is not in pubspec yet (the director adds it): the
/// test reads assets from disk when the bundle does not have them.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final f = File(key);
    if (f.existsSync()) return ByteData.sublistView(f.readAsBytesSync());
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

/// Waits for a deck, picks its right card, and taps এগিয়ে যান on a reason
/// (a coworker deck closes by itself).
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// The first seed whose deal brings him on [round].
int _seedCalling(int round) {
  var seed = 0;
  while (dealMegger(math.Random(seed)).callAt != round) {
    seed++;
  }
  return seed;
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
MeggerGeo get _geo => MeggerGeo.forScene(360 * 850 / 392, 0);
Future<void> _tapD(WidgetTester t, Offset design, {int ms = 350}) async {
  await t.tapAt(design * _k);
  await _pump(t, ms);
}

Widget _app(Widget home) => DefaultAssetBundle(bundle: _DiskBundle(), child: home);

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
    builder: (_) => _app(M2MeggerPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

Future<void> _holdTest(WidgetTester t, {int ms = 3400}) async {
  final g = await t.startGesture(_geo.testButton * _k);
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

Future<void> _discharge(WidgetTester t, int core) async {
  await t.tap(_label(M2MeggerLines.rod));
  await _pump(t, 200);
  await _tapD(t, _geo.coreEnds[core], ms: 900);
}

/// Round 1's set-up: the tester checked and fixed, E on the armour, 500 V.
Future<void> _setUp(WidgetTester t, MeggerDeal deal) async {
  await t.tap(_label(M2MeggerLines.check));
  await _pump(t, 500);
  if (deal.fault == MeggerFault.lead) await t.tap(find.text(M2MeggerLines.newLead));
  if (deal.fault == MeggerFault.battery) await t.tap(find.text(M2MeggerLines.newBattery));
  await _pump(t, 200);
  await t.tap(find.text(M2MeggerLines.kitOk));
  await _pump(t, 400);
  await _tapD(t, _geo.ePark);
  await _tapD(t, _geo.armourAt);
  final turns = (4 - meggerVolts.indexOf(deal.startVolts)) % 4;
  for (var i = 0; i < turns; i++) {
    await _tapD(t, _geo.knob, ms: 200);
  }
}

/// Plays core [core] as round [round], right; refuses him on his round.
Future<void> _playCore(WidgetTester t, MeggerDeal deal, int core, int round) async {
  if (round == 0) await _setUp(t, deal);
  await _discharge(t, core);
  await _tapD(t, _geo.lPark);
  await _tapD(t, _geo.coreEnds[core]);
  await _holdTest(t);
  final his = round == deal.callAt;
  if (his) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on round $round');
    await _pickRight(t, M2MeggerLines.coworker.right);
    await _pump(t, 2000);
  } else {
    await _discharge(t, core);
  }
  final weak = deal.weak(core);
  await t.tap(find.text(weak ? M2MeggerLines.weak : M2MeggerLines.good));
  await _pump(t, 400);
  await _tapD(t, _geo.coreEnds[core], ms: 600);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $round');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'reason deck, round $round');
  await _pickRight(t, his ? M2MeggerLines.dischargeRight : (weak ? M2MeggerLines.weakRight : M2MeggerLines.goodRight));
  await _pump(t, round == 2 ? 7000 : 3500);
}

void main() {
  group('rules', () {
    test('deals: three readings well clear of 1 MΩ, one or two weak cores, him on round 2 or 3, fresh each play', () {
      final seen = <String>{};
      final faults = <MeggerFault>{};
      final volts = <int>{};
      for (var s = 0; s < 80; s++) {
        final d = dealMegger(math.Random(s));
        expect(d.readings, hasLength(3));
        for (final r in d.readings) {
          expect(r >= 250 || r <= 0.6, isTrue, reason: '$r');
        }
        final weak = [0, 1, 2].where(d.weak).length;
        expect(weak, inInclusiveRange(1, 2), reason: 'a good and a weak core every play');
        expect(d.callAt, inInclusiveRange(1, 2));
        expect(meggerVolts, contains(d.startVolts));
        faults.add(d.fault);
        volts.add(d.startVolts);
        seen.add('${d.readings}${d.fault}${d.startVolts}${d.callAt}');
      }
      expect(seen.length, greaterThan(50));
      expect(faults, containsAll(MeggerFault.values));
      expect(volts, containsAll(meggerVolts));
    });

    MeggerRun run({MeggerFault fault = MeggerFault.none, int volts = 500, List<double> r = const [500, 0.4, 850]}) =>
        MeggerRun(MeggerDeal(readings: r, fault: fault, startVolts: volts, callAt: 1));

    test('a clean core: check, discharge, clips, 500 V, a full minute, the verdict, discharge, the clip off', () {
      final a = run(fault: MeggerFault.lead, volts: 2500);
      a.openCheck();
      expect(a.leadCracked, isTrue);
      expect(a.kitOk, isFalse);
      expect(a.fix(MeggerFault.lead), isNull);
      expect(a.kitOk, isTrue);
      expect(a.fix(MeggerFault.lead), isNull, reason: 'the fixed part again: nothing');
      expect(a.discharge(0), isTrue, reason: 'just cut off the supply: a charge');
      expect(a.discharge(0), isFalse);
      expect(a.clipE(armour: true), isNull);
      expect(a.clipL(0), isNull);
      a
        ..turnKnob()
        ..turnKnob();
      expect(a.volts, 500);
      expect(a.startTest(), isNull);
      expect(a.charged, contains(0), reason: 'the test charges the core');
      expect(a.endTest(full: true), isNull);
      expect(a.verdictDue, isTrue);
      expect(a.verdict(good: true), isNull);
      expect(a.finishCore(), isNull, reason: 'the L clip is still on');
      expect(a.discharge(0), isTrue);
      expect(a.unclipL(), isNull);
      expect(a.finishCore(), 0);
      expect(a.slips, 0);
      expect(a.roundSlip, isFalse);
      expect(a.caught, containsAll([M2MeggerLines.caughtKit, M2MeggerLines.caughtFirst, M2MeggerLines.caughtVolts, M2MeggerLines.caughtMinute, M2MeggerLines.caughtGood, M2MeggerLines.caughtAfter]));
    });

    test('slips: unchecked, faulty kit, clip before discharge, swapped clips, wrong voltage, short test, misread', () {
      final a = run(fault: MeggerFault.battery, volts: 1000);
      expect(a.clipL(0), M2MeggerMistakes.dischargeFirst);
      a.discharge(0);
      expect(a.clipL(null), M2MeggerMistakes.wrongLead);
      expect(a.clipE(armour: false), M2MeggerMistakes.wrongLead);
      a
        ..clipE(armour: true)
        ..clipL(0);
      expect(a.startTest(), M2MeggerMistakes.unchecked);
      a.openCheck();
      expect(a.startTest(), M2MeggerMistakes.badKit);
      a.fix(MeggerFault.battery);
      expect(a.startTest(), M2MeggerMistakes.wrongVolts);
      while (a.volts != 500) {
        a.turnKnob();
      }
      expect(a.startTest(), isNull);
      expect(a.endTest(full: false), M2MeggerMistakes.shortTest);
      expect(a.readFor, isNull);
      expect(a.charged, contains(0), reason: 'a short test charges the core too');
      a.startTest();
      a.endTest(full: true);
      expect(a.verdict(good: false), M2MeggerMistakes.misread, reason: '500 MΩ is good');
      expect(a.slips, 8);
      expect(a.percent, 0);
      expect(a.deadly, isNull);
      expect(M2MeggerMistakes.all.where((m) => m.deadly), [M2MeggerMistakes.charged]);
    });

    test('a needless fix (a good lead or battery swapped) costs a slip, once per part; it fixes nothing', () {
      for (final fault in [MeggerFault.none, MeggerFault.lead, MeggerFault.battery]) {
        final a = run(fault: fault)..openCheck();
        final good = fault == MeggerFault.battery ? MeggerFault.lead : MeggerFault.battery;
        expect(a.fix(good), M2MeggerMistakes.needlessFix, reason: '$fault');
        expect(a.slips, 1);
        expect(a.roundSlip, isTrue);
        expect(a.fix(good), isNull, reason: 'the same part again is not booked twice');
        expect(a.slips, 1);
        expect(a.kitOk, fault == MeggerFault.none, reason: 'a needless fix leaves the real fault');
      }
      expect(M2MeggerMistakes.needlessFix.deadly, isFalse);
      expect(M2MeggerMistakes.needlessFix.textBn, isNot(contains('এটা তো ঠিক আছে')));
    });

    test('the L clip off a charged core is deadly (after a full or a short test); off a discharged one, fine', () {
      for (final full in [true, false]) {
        final a = run()
          ..openCheck()
          ..discharge(1)
          ..clipE(armour: true)
          ..clipL(1)
          ..startTest()
          ..endTest(full: full);
        final m = a.unclipL();
        expect(m, M2MeggerMistakes.charged);
        expect(m!.deadly, isTrue);
        expect(a.ended, isTrue);
      }
      final b = run()
        ..openCheck()
        ..discharge(1)
        ..clipE(armour: true)
        ..clipL(1)
        ..startTest()
        ..endTest(full: true);
      expect(b.verdict(good: false), isNull, reason: '0.4 MΩ is weak');
      expect(b.caught, contains(M2MeggerLines.caughtWeak));
      b.discharge(1);
      expect(b.unclipL(), isNull);
      expect(b.finishCore(), 1);
      expect(b.clipL(1), isNull, reason: 'a finished core takes no clip');
      expect(b.lOn, isNull);
    });

    test('the scale and the display: log scale, 1 MΩ a third of the way; readings as the tester shows them', () {
      expect(meggerScale(1), closeTo(1 / 3, 1e-9));
      expect(meggerScale(0.4), lessThan(1 / 3));
      expect(meggerScale(250), greaterThan(0.6));
      expect(M2MeggerLines.reading(850), '850 MΩ');
      expect(M2MeggerLines.reading(1200), '1.2 GΩ');
      expect(M2MeggerLines.reading(2000), '2 GΩ');
      expect(M2MeggerLines.reading(0.4), '0.4 MΩ');
      expect(M2MeggerLines.reading(0.05), '0.05 MΩ');
      expect(meggerVolts, [500, 1000, 2500, 5000]);
    });

    test('the lesson\'s numbers, English digits only; every mistake has its picture and a lesson point', () {
      final all = <String>[
        M2MeggerLines.intro,
        ...M2MeggerLines.tasks,
        ...M2MeggerLines.goodRight,
        ...M2MeggerLines.goodWrong,
        ...M2MeggerLines.weakRight,
        ...M2MeggerLines.weakWrong,
        ...M2MeggerLines.dischargeRight,
        ...M2MeggerLines.dischargeWrong,
        ...M2MeggerLines.coworker.recordedLines,
        ...M2MeggerLines.coworker.right,
        ...M2MeggerLines.coworker.wrong,
        ...M2MeggerLines.coworker.asks,
        for (final m in M2MeggerMistakes.all) m.textBn,
        M2MeggerLines.docketJob,
        M2MeggerLines.allSet,
        M2MeggerLines.fail,
        M2MeggerLines.caughtVolts,
        M2MeggerLines.caughtMinute,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
      }
      expect(M2MeggerMistakes.wrongVolts.textBn, contains('415 V'));
      expect(M2MeggerMistakes.wrongVolts.textBn, contains('500 V'));
      expect(M2MeggerMistakes.shortTest.textBn, contains('1 মিনিট'));
      expect(M2MeggerMistakes.misread.textBn, contains('1 MΩ'));
      for (final m in M2MeggerMistakes.all) {
        expect(m.key, startsWith('2.7/megger/'));
        expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m2MeggerPacks.keys, ['do_2_7_b']);
      expect(_pack.quickMs, 80000);
    });

    test('reasons: libraries big enough, same length; a wrong card is never a rule; his exit line is recorded', () {
      final rules = {...M2MeggerLines.goodRight, ...M2MeggerLines.weakRight, ...M2MeggerLines.dischargeRight};
      for (final (name, right, wrong) in [
        ('good', M2MeggerLines.goodRight, M2MeggerLines.goodWrong),
        ('weak', M2MeggerLines.weakRight, M2MeggerLines.weakWrong),
        ('discharge', M2MeggerLines.dischargeRight, M2MeggerLines.dischargeWrong),
      ]) {
        expectLibrary(name, right, wrong);
        expectSameLength(name, [...right, ...wrong]);
        expect(wrong.toSet().intersection(rules), isEmpty, reason: name);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      final cw = M2MeggerLines.coworker;
      expectLibrary('choice', cw.right, cw.wrong);
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
    });

    test('no giveaway: no word on two or more right cards is missing from all the wrong ones; the lengths overlap', () {
      Set<String> words(String l) => l.split(RegExp(r'[\s,।—!?]+')).where((w) => w.isNotEmpty).toSet();
      for (final (name, right, wrong) in [
        ('good', M2MeggerLines.goodRight, M2MeggerLines.goodWrong),
        ('weak', M2MeggerLines.weakRight, M2MeggerLines.weakWrong),
        ('discharge', M2MeggerLines.dischargeRight, M2MeggerLines.dischargeWrong),
        ('choice', M2MeggerLines.coworker.right, M2MeggerLines.coworker.wrong),
      ]) {
        final inWrong = wrong.expand(words).toSet();
        final counts = <String, int>{};
        for (final r in right) {
          for (final w in words(r)) {
            counts[w] = (counts[w] ?? 0) + 1;
          }
        }
        final tells = [for (final e in counts.entries) if (e.value >= 2 && !inWrong.contains(e.key)) e.key];
        expect(tells, isEmpty, reason: name);
        // Length is no tell: the right card is neither always the longest
        // nor always the shortest.
        final rl = right.map((s) => s.length).toList()..sort();
        final wl = wrong.map((s) => s.length).toList()..sort();
        expect(rl.first <= wl.last, isTrue, reason: '$name: every right card is longer than every wrong one ($rl vs $wl)');
        expect(rl.last >= wl.first, isTrue, reason: '$name: every right card is shorter than every wrong one ($rl vs $wl)');
      }
      // "1 MΩ" sits on wrong myths too, in both verdict decks.
      expect(M2MeggerLines.goodWrong.any((w) => w.contains('1 MΩ')), isTrue);
      expect(M2MeggerLines.weakWrong.any((w) => w.contains('1 MΩ')), isTrue);
      // The guide's ask never points at the answer.
      for (final a in M2MeggerLines.coworker.asks) {
        expect(a, isNot(contains('আগে')), reason: a);
      }
    });

    test('the free-play hint order is shuffled per waiting state and never opens check → rod', () {
      final seen = <String>{};
      for (var r = 0; r < 3; r++) {
        for (final n in [6, 8]) {
          for (final key in ['$r|none|false|false|null|false|false', '$r|none|false|true|$r|true|true', '$r|none|false|false|null|true|true']) {
            final o = meggerHintOrder(key, n);
            expect(o.toSet(), {for (var i = 0; i < n; i++) i}, reason: 'a permutation');
            expect(o[0] == 0 && o[1] == 1, isFalse, reason: 'never check then rod ($key)');
            expect(o, isNot(equals([for (var i = 0; i < n; i++) i])), reason: 'never the procedure order');
            expect(meggerHintOrder(key, n), o, reason: 'stable while the state lasts');
            seen.add(o.join(','));
          }
        }
      }
      expect(seen.length, greaterThan(6), reason: 'the order changes with the state');
      expect(meggerHintOrder('x', 2), isNot([0, 1]));
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
          child: MaterialApp(home: _app(M2MeggerPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.textContaining(RegExp('শুরু')), findsNothing, reason: 'no start button of any wording');
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
        debugPrint('PERF m2_megger_read ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: _app(M2MeggerPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M2MeggerLines.rod), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(_label(M2MeggerLines.rod), findsOneWidget);
      expect(_label(M2MeggerLines.check), findsOneWidget);
      expect(find.text(M2MeggerLines.docketJob), findsOneWidget);
      expect(find.text(M2MeggerLines.good), findsNothing, reason: 'no verdict before a reading');
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
      expect(lines.every((l) => l.contains(M2MeggerLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: three cores tested by the rules, him refused → pass, saved', (t) async {
      const seed = 7;
      final deal = dealMegger(math.Random(seed));
      final c = await _open(t, seed);
      for (final (round, core) in [2, 0, 1].indexed) {
        await _playCore(t, deal, core, round);
      }
      expect(await _pumpUntil(t, find.byType(LevelPassPanel), maxMs: 6000), isTrue);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.7/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.7/do/1'], greaterThan(0));
      expect(find.text(M2MeggerLines.caughtCall), findsOneWidget);
      expect(find.text(M2MeggerLines.caughtAfter), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('TEST before the daily check: a slip card (picture, line, পাঠে দেখুন); the core stays to test', (t) async {
      const seed = 2;
      final c = await _open(t, seed);
      await _discharge(t, 0);
      await _tapD(t, _geo.ePark);
      await _tapD(t, _geo.armourAt);
      await _tapD(t, _geo.lPark);
      await _tapD(t, _geo.coreEnds[0]);
      await _holdTest(t, ms: 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(M2MeggerMistakes.unchecked.textBn), findsOneWidget);
      expect(find.text(MistakeLines.readLesson), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M2MeggerMistakes.unchecked.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(M2MeggerLines.check), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the L clip off without discharging after the test: freeze first, then the card (near-miss)', (t) async {
      // A deal whose first round is not his.
      final deal = dealMegger(math.Random(11));
      final c = await _open(t, 11);
      await _setUp(t, deal);
      await _discharge(t, 2);
      await _tapD(t, _geo.lPark);
      await _tapD(t, _geo.coreEnds[2]);
      await _holdTest(t);
      await _tapD(t, _geo.coreEnds[2], ms: 600);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M2MeggerMistakes.charged.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him ("রিডিং হয়ে গেছে, তার খুলে নাও") = deadly (the act is on the module deadly list): freeze, then the card', (t) async {
      final seed = _seedCalling(1);
      final deal = dealMegger(math.Random(seed));
      final c = await _open(t, seed);
      await _playCore(t, deal, 0, 0);
      await _discharge(t, 1);
      await _tapD(t, _geo.lPark);
      await _tapD(t, _geo.coreEnds[1]);
      await _holdTest(t);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M2MeggerLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fast play cannot skip him: the rod reached for the moment the minute ends holds for him; refused, the rod discharges', (t) async {
      final seed = _seedCalling(1);
      final deal = dealMegger(math.Random(seed));
      final c = await _open(t, seed);
      await _playCore(t, deal, 1, 0);
      await _discharge(t, 0);
      await _tapD(t, _geo.lPark);
      await _tapD(t, _geo.coreEnds[0]);
      // Release right after the minute (his own timer is 1.2–2.4 s away).
      await _holdTest(t, ms: 3100);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not yet by his timer');
      await t.tap(_label(M2MeggerLines.rod));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the rod tap brings him in now');
      await _pickRight(t, M2MeggerLines.coworker.right);
      await _pump(t, 2000);
      // Now the clip comes off safely and the verdict closes the core.
      await t.tap(find.text(deal.weak(0) ? M2MeggerLines.weak : M2MeggerLines.good));
      await _pump(t, 400);
      await _tapD(t, _geo.coreEnds[0], ms: 600);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(await _pumpUntil(t, find.text(M2MeggerLines.whyDischarge)), isTrue);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final c = await _open(t, 2);
      await _discharge(t, 0);
      await _tapD(t, _geo.ePark);
      await _tapD(t, _geo.armourAt);
      await _tapD(t, _geo.lPark);
      await _tapD(t, _geo.coreEnds[0]);
      for (var i = 0; i < 2; i++) {
        await _holdTest(t, ms: 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 500);
      }
      await _holdTest(t, ms: 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.7/do/1'], isNot('cleared'));
      expect(s.mistakes.map((m) => m.key), contains(M2MeggerMistakes.unchecked.key));
      expect(find.byType(LevelPassPanel), findsNothing);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a needless fix in the kit close-up is a slip with a neutral card; the close-up stays open', (t) async {
      var seed = 0;
      while (dealMegger(math.Random(seed)).fault == MeggerFault.battery) {
        seed++;
      }
      final c = await _open(t, seed);
      await t.tap(_label(M2MeggerLines.check));
      await _pump(t, 500);
      await t.tap(find.text(M2MeggerLines.newBattery));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M2MeggerMistakes.needlessFix.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M2MeggerMistakes.needlessFix.key);
      expect(c.read(guideDirectorProvider).line, isNot(contains('এটা তো ঠিক আছে')));
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M2MeggerLines.kitOk), findsOneWidget);
      // The same swap again is not booked twice.
      await t.tap(find.text(M2MeggerLines.newBattery));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the praise window takes no input: the knob and the E clip tapped then change nothing', (t) async {
      final seed = _seedCalling(2);
      final deal = dealMegger(math.Random(seed));
      final c = await _open(t, seed);
      await _setUp(t, deal);
      await _discharge(t, 0);
      await _tapD(t, _geo.lPark);
      await _tapD(t, _geo.coreEnds[0]);
      await _holdTest(t);
      await _discharge(t, 0);
      await t.tap(find.text(deal.weak(0) ? M2MeggerLines.weak : M2MeggerLines.good));
      await _pump(t, 400);
      await _tapD(t, _geo.coreEnds[0], ms: 100);
      // ◆ on the table, praise playing: try the knob and the E clip.
      await _tapD(t, _geo.knob, ms: 100);
      await _tapD(t, _geo.armourAt, ms: 100);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pickRight(t, deal.weak(0) ? M2MeggerLines.weakRight : M2MeggerLines.goodRight);
      await _pump(t, 3500);
      // Round 2 runs on the same set-up: 500 V and the E clip still on.
      await _playCore(t, deal, 1, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hints: a sweep over every usable thing, over the places a clip can go, over the kit buttons', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 3);
      IdleHintState hint() => t.state<IdleHintState>(find.byWidgetPredicate((w) => w is IdleHint && w.controller != null));
      expect(hint().showing, isFalse);
      await _pump(t, 8600);
      expect(hint().showing, isTrue, reason: 'idle while the level waits');
      expect(hint().debugOptions.length, greaterThanOrEqualTo(6), reason: 'check, rod, both clips, selector, TEST');
      // Not acted out in procedure order: it never opens on check then rod.
      final hintAt = t.getTopLeft(find.byWidgetPredicate((w) => w is IdleHint && w.controller != null));
      final checkAt = t.getCenter(_label(M2MeggerLines.check)) - hintAt;
      final rodAt = t.getCenter(_label(M2MeggerLines.rod)) - hintAt;
      int indexOf(Offset c) => hint().debugOptions.indexWhere((r) => (r.center - c).distance < 1.5);
      final ci = indexOf(checkAt), ri = indexOf(rodAt);
      expect(ci, isNot(-1), reason: 'the check is swept');
      expect(ri, isNot(-1), reason: 'the rod is swept');
      expect(ci == 0 && ri == 1, isFalse, reason: 'never check → rod → … (the procedure order)');
      // The L clip in hand: a sweep over all three cores and the armour.
      await _tapD(t, _geo.lPark, ms: 100);
      expect(hint().showing, isFalse, reason: 'a touch hides it');
      await _pump(t, 8600);
      expect(hint().showing, isTrue);
      expect(hint().debugOptions, hasLength(4));
      await _tapD(t, _geo.lPark, ms: 100);
      // The kit close-up: its three buttons.
      await t.tap(_label(M2MeggerLines.check));
      await _pump(t, 8800);
      expect(hint().showing, isTrue);
      expect(hint().debugOptions, hasLength(3));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
