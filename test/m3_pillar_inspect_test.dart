// Lesson 3.7 (এলটি ফিডার পিলার), কাজ 2 "পিলারের তল্লাশি": the rules (ring
// every fault outside and inside, nothing else; then gloves → the docket's
// feeder OFF → its fuses out → the megger on its cable; the door locked), the
// deal, the reason libraries, and the level in the shell: idle perf, the guide
// first, a full clean play (the coworker refused), a missed fault's slip card,
// the deadly freeze (the megger on a live cable), three slips striking out,
// the coworker meeting a fast player, listening to him (a slip), English
// digits and the gesture hint.
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
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_pillar_inspect.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/order_steps.dart' show OrderTapKind;
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '3.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '3.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m3PillarInspectPacks['do_3_7_b']!;

typedef _Spot = M3PillarInspectSpot;
typedef _Fault = M3PillarInspectFault;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_pillar_inspect/')) {
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

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3PillarInspectGeo get _geo => M3PillarInspectGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _tapAt(WidgetTester t, Offset design, {int ms = 400}) async {
  await t.tapAt(design * _k);
  await _pump(t, ms);
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
    builder: (_) => M3PillarInspectPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

/// Rings [faults], reports, answers the reason right.
Future<void> _spotRight(WidgetTester t, Map<_Spot, _Fault> faults) async {
  for (final s in faults.keys) {
    await _tapAt(t, _geo.spot(s).center);
  }
  await t.tap(find.text(M3PillarInspectLines.report));
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, [for (final f in faults.values) M3PillarInspectLines.faultWhy[f]!]);
  await _pump(t, 4000);
}

/// Gloves → the docket's feeder OFF → its fuses out → the megger.
Future<void> _meggerRight(WidgetTester t, int k) async {
  await _tapAt(t, _geo.gloves.center);
  await _tapAt(t, _geo.handle(k).center);
  await _tapAt(t, _geo.fuses(k).center);
  await _tapAt(t, _geo.cable(k).center);
}

void main() {
  group('rules', () {
    test('deals: two outside and two inside faults, the docket feeder free of fuse faults, fresh every play', () {
      final seen = <String>{};
      final feeders = <int>{};
      final hotAt = <_Spot>{};
      for (var s = 0; s < 120; s++) {
        final d = dealM3PillarInspect(math.Random(s));
        expect(d.outside.length, 2);
        expect(d.inside.length, 2);
        expect(d.outside.values.toSet().length, 2);
        expect(d.inside.values.toSet().length, 2);
        for (final e in d.outside.entries) {
          expect(m3PillarInspectOutside, contains(e.key));
          expect(m3PillarInspectFixedSpot(e.value), e.key);
        }
        for (final e in d.inside.entries) {
          expect(m3PillarInspectInside, contains(e.key));
          expect([_Spot.neutral, _Spot.earth], isNot(contains(e.key)), reason: 'the neutral link and earth are decoys');
          if (e.value == _Fault.wireFuse) expect([_Spot.fuse1, _Spot.fuse2, _Spot.fuse3], contains(e.key));
          if (e.value == _Fault.hotspot) hotAt.add(e.key);
        }
        expect(d.inside.containsKey(m3PillarInspectFuseSpot(d.feeder)), isFalse);
        feeders.add(d.feeder);
        seen.add('${d.outside}${d.inside}${d.feeder}');
      }
      expect(seen.length, greaterThan(60));
      expect(feeders, {0, 1, 2});
      expect(hotAt, contains(_Spot.busbar));
    });

    const deal = M3PillarInspectDeal(
      outside: {_Spot.lock: _Fault.noLock, _Spot.entry: _Fault.entryGap},
      inside: {_Spot.fuse1: _Fault.hotspot, _Spot.top: _Fault.waterIn},
      feeder: 2,
    );

    test('a full right play: ring, report, ring, report, the megger in order, lock', () {
      final r = M3PillarInspectRun(deal);
      expect(r.toggle(_Spot.lock), isTrue);
      expect(r.toggle(_Spot.door), isTrue);
      expect(r.toggle(_Spot.door), isFalse, reason: 'a second tap takes the ring off');
      r.toggle(_Spot.entry);
      expect(r.toggle(_Spot.busbar), isNull, reason: 'not at this station');
      expect(r.report(), isNull);
      expect(r.shown, isTrue);
      r.next();
      expect(r.station, M3PillarInspectStation.inside);
      r
        ..toggle(_Spot.fuse1)
        ..toggle(_Spot.top);
      expect(r.report(), isNull);
      r.next();
      expect(r.tapGloves().kind, OrderTapKind.ok);
      expect(r.tapSwitch(2).kind, OrderTapKind.ok);
      expect(r.tapFuses(2).kind, OrderTapKind.ok);
      expect(r.tapCable(2).kind, OrderTapKind.ok);
      expect(r.tested, isTrue);
      expect(r.lock(), isTrue);
      r.next();
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.caught, containsAll([M3PillarInspectLines.caughtFault[_Fault.noLock], M3PillarInspectLines.caughtFault[_Fault.hotspot], M3PillarInspectLines.caughtMegger, M3PillarInspectLines.caughtLock]));
    });

    test('a missed fault is a slip (its own card, shown orange); a fine part rung is a slip', () {
      final r = M3PillarInspectRun(deal)..toggle(_Spot.lock);
      expect(r.report(), M3PillarInspectMistakes.missedEntry);
      expect(r.missed, {_Spot.entry});
      expect(r.slips, 1);
      final f = M3PillarInspectRun(deal)
        ..toggle(_Spot.lock)
        ..toggle(_Spot.entry)
        ..toggle(_Spot.roof);
      expect(f.report(), M3PillarInspectMistakes.falseFlag);
      final i = M3PillarInspectRun(deal)..next();
      i.toggle(_Spot.top);
      expect(i.report(), M3PillarInspectMistakes.missedHot);
    });

    test('the megger order: gloves first, the docket feeder only, OFF before fuses, fuses before the megger', () {
      M3PillarInspectRun at() => M3PillarInspectRun(deal)
        ..next()
        ..next();
      final a = at();
      expect(a.tapSwitch(2).mistake, M3PillarInspectMistakes.noGloves);
      expect(a.off, isEmpty);
      a.tapGloves();
      expect(a.tapSwitch(0).mistake, M3PillarInspectMistakes.wrongFeeder);
      expect(a.tapFuses(2).mistake, M3PillarInspectMistakes.fuseBeforeOff);
      a.tapSwitch(2);
      expect(a.tapCable(2).mistake, M3PillarInspectMistakes.fusesIn);
      expect(a.slips, 4);
      expect(a.deadly, isNull);
      a.tapFuses(2);
      expect(a.tapCable(2).kind, OrderTapKind.ok);
    });

    test('the megger on a cable whose SFU is ON is deadly (the docket feeder or another)', () {
      final a = M3PillarInspectRun(deal)
        ..next()
        ..next()
        ..tapGloves();
      expect(a.tapCable(2).mistake, M3PillarInspectMistakes.liveMegger);
      expect(a.ended, isTrue);
      final b = M3PillarInspectRun(deal)
        ..next()
        ..next()
        ..tapGloves()
        ..tapSwitch(2)
        ..tapFuses(2);
      expect(b.tapCable(0).mistake!.deadly, isTrue);
    });

    test('the door left open on his say-so is a slip and ends the station; locking needs the test first', () {
      final a = M3PillarInspectRun(deal)
        ..next()
        ..next();
      expect(a.lock(), isFalse);
      expect(a.leaveOpen(), M3PillarInspectMistakes.doorOpen);
      expect(a.shown, isTrue);
      expect(a.slips, 1);
    });

    test('three slips cost 15 each: 55 % (the page strikes out on the third, see the page test)', () {
      final r = M3PillarInspectRun(deal);
      r.report();
      r.next();
      r.report();
      r.next();
      r.leaveOpen();
      r.next();
      expect(r.done, isTrue);
      expect(r.percent, 55);
      expect(r.slips, 3);
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded; art; keys', () {
      final all = [...M3PillarInspectLines.faultWhy.values, ...M3PillarInspectLines.outsideWrong, ...M3PillarInspectLines.insideWrong, ...M3PillarInspectLines.meggerRight, ...M3PillarInspectLines.meggerWrong];
      expectSameLength('why', all);
      for (final s in M3PillarInspectStation.values) {
        final pool = s == M3PillarInspectStation.outside ? m3PillarInspectOutsideFaults : m3PillarInspectInsideFaults;
        for (var i = 0; i < pool.length; i++) {
          for (var j = i + 1; j < pool.length; j++) {
            final right = M3PillarInspectLines.whyRight(s, [pool[i], pool[j]]);
            final wrong = M3PillarInspectLines.whyWrong(s);
            expectLibrary('why ${s.name}', right, wrong);
            for (var n = 0; n < 6; n++) {
              final d = dealChoices(right, wrong, math.Random(n));
              expect(d.where((o) => o.correct).length, 1);
              expect(d.map((o) => o.textBn).toSet().length, 3);
            }
          }
        }
      }
      final cw = M3PillarInspectLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      final keys = <String>{};
      for (final m in M3PillarInspectMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.key.startsWith('3.7/m3_pillar_inspect/'), isTrue);
        expect(keys.add(m.key), isTrue, reason: m.key);
      }
      expect(M3PillarInspectMistakes.all.where((m) => m.deadly), [M3PillarInspectMistakes.liveMegger]);
      expect(M3PillarInspectMistakes.missedBy.keys.toSet(), M3PillarInspectFault.values.toSet());
      expect(m3PillarInspectPacks.keys, ['do_3_7_b']);
    });

    test('English digits on screen: no Bangla digit in any line, card or option', () {
      final cw = M3PillarInspectLines.coworker;
      final texts = <String>[
        ...M3PillarInspectLines.tasks,
        M3PillarInspectLines.intro,
        M3PillarInspectLines.report,
        M3PillarInspectLines.lock,
        M3PillarInspectLines.docketJob,
        for (var k = 0; k < 3; k++) M3PillarInspectLines.docketFeeder(k),
        ...M3PillarInspectLines.faultWhy.values,
        ...M3PillarInspectLines.outsideWrong,
        ...M3PillarInspectLines.insideWrong,
        ...M3PillarInspectLines.meggerRight,
        ...M3PillarInspectLines.meggerWrong,
        ...M3PillarInspectLines.caughtFault.values,
        cw.line,
        cw.exitLine,
        ...cw.right,
        ...cw.wrong,
        ...cw.asks,
        M3PillarInspectLines.callHeld,
        M3PillarInspectLines.allSet,
        M3PillarInspectLines.fail,
        for (final m in M3PillarInspectMistakes.all) m.textBn,
      ];
      final bn = RegExp('[০-৯]');
      for (final x in texts) {
        expect(bn.hasMatch(x), isFalse, reason: x);
      }
      expect(M3PillarInspectMistakes.liveMegger.textBn, contains('415'));
      expect(M3PillarInspectLines.docketFeeder(1), 'ফিডার 2');
    });

    test('no key word only on the right cards: the coworker refusals and every station\'s reasons', () {
      final cw = M3PillarInspectLines.coworker;
      for (final r in cw.right) {
        expect(r.contains('লক'), isFalse, reason: r);
      }
      expect(cw.right.any((r) => r.contains('তালা')) && cw.wrong.any((w) => w.contains('তালা')), isTrue);
      // Every key word a right reason uses is on a wrong one too (used wrongly),
      // so the word alone never picks the card.
      const keys = ['জল', 'দরজা', 'তালা', 'সিল', 'মরিচা', 'ইঁদুর', 'শর্ট', 'শর্ট সার্কিট', 'বৃষ্টি', 'কেবিল', 'ফাঁক', 'কালো দাগ', 'পোড়া গন্ধ', 'ফিউজ', 'মেগার', 'গ্লাভস', 'সুইচ', 'চালু', 'বন্ধ'];
      final sets = {
        M3PillarInspectStation.outside: [for (final f in m3PillarInspectOutsideFaults) M3PillarInspectLines.faultWhy[f]!],
        M3PillarInspectStation.inside: [for (final f in m3PillarInspectInsideFaults) M3PillarInspectLines.faultWhy[f]!],
        M3PillarInspectStation.megger: M3PillarInspectLines.meggerRight,
      };
      for (final e in sets.entries) {
        final wrong = M3PillarInspectLines.whyWrong(e.key);
        for (final word in keys) {
          final onRight = e.value.where((r) => r.contains(word)).length;
          if (onRight == 0) continue;
          expect(wrong.any((w) => w.contains(word)), isTrue, reason: '${e.key.name}: "$word" is on $onRight right reason(s) and no wrong one');
        }
      }
      // The words most right reasons share are on at least two wrong ones.
      expect(M3PillarInspectLines.outsideWrong.where((w) => w.contains('জল')).length, greaterThanOrEqualTo(2));
      expect(M3PillarInspectLines.outsideWrong.where((w) => w.contains('দরজা')).length, greaterThanOrEqualTo(2));
      expect(M3PillarInspectLines.insideWrong.where((w) => w.contains('শর্ট সার্কিট')).length, greaterThanOrEqualTo(2));
    });

    test('the গ hint sweep: every control of all three feeders, not in the procedure order', () {
      final g = _geo;
      final sweep = m3PillarInspectMeggerSweep(g);
      String kind(Rect r) {
        if (r == g.gloves) return 'gloves';
        for (var k = 0; k < 3; k++) {
          if (r == g.handle(k)) return 'handle$k';
          if (r == g.fuses(k)) return 'fuses$k';
          if (r == g.cable(k)) return 'cable$k';
        }
        return 'other';
      }

      final names = sweep.map(kind).toList();
      expect(names.toSet(), {'gloves', for (var k = 0; k < 3; k++) ...['handle$k', 'fuses$k', 'cable$k']});
      expect(names, hasLength(10));
      // The order the categories first show in: neither the procedure nor its reverse.
      final firsts = <String>[];
      for (final n in names) {
        final c = n.replaceAll(RegExp(r'\d'), '');
        if (!firsts.contains(c)) firsts.add(c);
      }
      expect(firsts, isNot(['gloves', 'handle', 'fuses', 'cable']));
      expect(firsts, isNot(['cable', 'fuses', 'handle', 'gloves']));
      expect(names.first, isNot('gloves'), reason: 'the hand does not start where the procedure starts');
      // No feeder is visited switch → fuses → cable.
      for (var k = 0; k < 3; k++) {
        final h = names.indexOf('handle$k'), f = names.indexOf('fuses$k'), c = names.indexOf('cable$k');
        expect(h < f && f < c, isFalse, reason: 'feeder $k in procedure order');
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M3PillarInspectPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
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
        debugPrint('PERF m3_pillar_inspect ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3PillarInspectPage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M3PillarInspectLines.report), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M3PillarInspectLines.report), findsOneWidget);
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
      expect(lines.every((l) => l.contains(M3PillarInspectLines.askOutside)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: outside, inside, the megger in order, the coworker refused, the door locked → pass', (t) async {
      const seed = 5;
      final deal = dealM3PillarInspect(math.Random(seed));
      final c = await _open(t, seed);
      await _spotRight(t, deal.outside);
      await _spotRight(t, deal.inside);
      expect(find.byKey(const ValueKey('docket-feeder')), findsOneWidget);
      expect(find.text(M3PillarInspectLines.docketFeeder(deal.feeder)), findsOneWidget);
      await _meggerRight(t, deal.feeder);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M3PillarInspectLines.coworker.right);
      expect(await _pumpUntil(t, find.text(M3PillarInspectLines.lock)), isTrue);
      await t.tap(find.text(M3PillarInspectLines.lock));
      await _pump(t, 1500);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, M3PillarInspectLines.meggerRight);
      await _pump(t, 6000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.7/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.7/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3PillarInspectLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
      await _close(t, c);
    });

    testWidgets('a fault missed outside: the slip card, then the next station', (t) async {
      const seed = 6;
      final deal = dealM3PillarInspect(math.Random(seed));
      final c = await _open(t, seed);
      await _tapAt(t, _geo.spot(deal.outside.keys.first).center);
      await t.tap(find.text(M3PillarInspectLines.report));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3PillarInspectMistakes.missedBy[deal.outside.values.last]!.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, M3PillarInspectLines.askInside);
      await _close(t, c);
    });

    testWidgets('the megger on a live cable: deadly — freeze first, then the card', (t) async {
      const seed = 7;
      final deal = dealM3PillarInspect(math.Random(seed));
      final c = await _open(t, seed);
      await _spotRight(t, deal.outside);
      await _spotRight(t, deal.inside);
      await _tapAt(t, _geo.gloves.center);
      await _tapAt(t, _geo.cable(deal.feeder).center, ms: 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3PillarInspectMistakes.liveMegger.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 8);
      // ক: report with nothing rung (a missed fault), then খ the same.
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(M3PillarInspectLines.report));
        await _pump(t, 800);
        expect(find.text(MistakeLines.slipHead), findsOneWidget);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 1500);
      }
      // গ: a switch without gloves, the third slip.
      await _tapAt(t, _geo.handle(0).center, ms: 800);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).rungProgress['3.7/do/1'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('a fast player still meets the coworker: the lock waits for him', (t) async {
      const seed = 5;
      final deal = dealM3PillarInspect(math.Random(seed));
      final c = await _open(t, seed);
      await _spotRight(t, deal.outside);
      await _spotRight(t, deal.inside);
      await _tapAt(t, _geo.gloves.center, ms: 100);
      await _tapAt(t, _geo.handle(deal.feeder).center, ms: 100);
      await _tapAt(t, _geo.fuses(deal.feeder).center, ms: 100);
      await _tapAt(t, _geo.cable(deal.feeder).center, ms: 100);
      // Straight to the lock, before his timer.
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(find.text(M3PillarInspectLines.lock), findsOneWidget);
      await t.tap(find.text(M3PillarInspectLines.lock));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the tap brings him in');
      expect(find.text(M3PillarInspectLines.stampLock), findsNothing, reason: 'the door is not locked yet');
      await _pickRight(t, M3PillarInspectLines.coworker.right);
      expect(await _pumpUntil(t, find.text(M3PillarInspectLines.lock)), isTrue);
      await t.tap(find.text(M3PillarInspectLines.lock));
      await _pump(t, 600);
      expect(find.text(M3PillarInspectLines.stampLock), findsOneWidget);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, M3PillarInspectLines.meggerRight);
      await _pump(t, 6000);
      expect(c.read(gameSaveProvider).rungProgress['3.7/do/1'], 'cleared');
      expect(find.text(M3PillarInspectLines.caughtCall), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('listening to him leaves the door open: a slip (not deadly), then the result', (t) async {
      const seed = 5;
      final deal = dealM3PillarInspect(math.Random(seed));
      final c = await _open(t, seed);
      await _spotRight(t, deal.outside);
      await _spotRight(t, deal.inside);
      await _meggerRight(t, deal.feeder);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M3PillarInspectLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1500);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3PillarInspectMistakes.doorOpen.key);
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 3000);
      expect(find.byType(LevelPassPanel), findsOneWidget, reason: 'one slip: 85 %');
      await _close(t, c);
    });

    testWidgets('gesture hint: after idle at ক the hand sweeps the spots', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 3);
      final hint = find.byType(IdleHint).first;
      IdleHintState state() => t.state<IdleHintState>(hint);
      await _pump(t, GestureHints.idle.inMilliseconds + 600);
      expect(state().showing, isTrue, reason: 'the hand shows after idle');
      GestureHints.debugEnableInTests = false;
      await _close(t, c);
    });

    testWidgets('gesture hint: off under a slip card, the reason deck and the coworker; গ sweeps all three feeders, then taps the lock', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      const seed = 5;
      final deal = dealM3PillarInspect(math.Random(seed));
      final c = await _open(t, seed);
      // The scene's hint (the decks have their own).
      final scene = find.byWidgetPredicate((w) => w is IdleHint && w.sceneToLocal != null);
      expect(scene, findsOneWidget);
      IdleHintState state() => t.state<IdleHintState>(scene);
      final idle = GestureHints.idle.inMilliseconds + 2000;

      // ক: report with nothing rung → the slip card; the hand stays off under it.
      await t.tap(find.text(M3PillarInspectLines.report));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      await _pump(t, idle);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(state().showing, isFalse, reason: 'no hand over the slip card');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);

      // খ: ring and report → the reason deck; the scene's hand stays off.
      for (final s in deal.inside.keys) {
        await _tapAt(t, _geo.spot(s).center);
      }
      await t.tap(find.text(M3PillarInspectLines.report));
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, idle);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      expect(state().showing, isFalse, reason: 'no scene hand over the reason deck');
      await _pickRight(t, [for (final f in deal.inside.values) M3PillarInspectLines.faultWhy[f]!]);
      await _pump(t, 4000);

      // গ before the test: a sweep over every control of all three feeders.
      expect(await _pumpUntil(t, find.byKey(const ValueKey('docket-feeder'))), isTrue);
      var shown = false;
      for (var ms = 0; ms < idle + 4000 && !shown; ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
        shown = state().showing;
      }
      expect(shown, isTrue, reason: 'the hand shows at গ');
      expect(state().debugOptions, hasLength(10), reason: 'the gloves and all three feeders\' switch, fuses and cable');
      // Its first stop is a cable, not the gloves (the procedure's first step).
      final box = t.renderObject<RenderBox>(scene);
      final first = state().debugOptions.first.center;
      final gloves = box.globalToLocal(_geo.gloves.center * _k);
      expect((first - gloves).distance, greaterThan(20));

      // The test, then the coworker: no hand while he is up.
      await _meggerRight(t, deal.feeder);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      expect(state().showing, isFalse);
      await waitChoiceDeck(t);
      await _pump(t, idle);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      expect(state().showing, isFalse, reason: 'no scene hand while he waits for an answer');
      await _pickRight(t, M3PillarInspectLines.coworker.right);
      expect(await _pumpUntil(t, find.text(M3PillarInspectLines.lock)), isTrue);

      // Once tested: a tap on the lock button.
      shown = false;
      for (var ms = 0; ms < idle + 4000 && !shown; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
        shown = state().showing;
      }
      expect(shown, isTrue, reason: 'the hand shows on the lock');
      expect(state().debugOptions, isEmpty, reason: 'a tap, not a sweep');
      HintFrame? pressed;
      for (var i = 0; i < 60 && pressed == null; i++) {
        final f = state().debugFrame;
        if (f != null && f.press > 0.5) pressed = f;
        if (pressed == null) await t.pump(const Duration(milliseconds: 20));
      }
      expect(pressed, isNotNull);
      final lock = box.globalToLocal(t.getCenter(find.text(M3PillarInspectLines.lock)));
      expect((pressed!.tip - lock).distance, lessThan(40), reason: 'the tap lands on the lock button');
      GestureHints.debugEnableInTests = false;
      await _close(t, c);
    });
  });
}
