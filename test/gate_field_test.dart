import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/do_games.dart';
import 'package:slm_flutter/features/game/gate_field.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistakes_book.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _rung = 'm1/gate';
final _pack = gateFieldPacks['gate_m1']!;

LevelContext _ctx() => const LevelContext(
      rungId: _rung,
      kind: CatalogRungKind.gate,
      lessonId: '1.10',
      lessonTitleBn: 'প্রথম ডকেট · র‍্যাঙ্ক গেট',
      ladderStep: 30,
      doIndex: 0,
      doCount: 0,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Catalog & Engine Registration', () {
    test('content_catalog has m1/gate as playable', () {
      final raw = File('assets/game/catalog/content_catalog.json').readAsStringSync();
      final catalog = ContentCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final rung = catalog.rungDefs.firstWhere((r) => r.id == 'm1/gate');
      expect(rung.status, CatalogRungStatus.playable);
      expect(rung.packId, 'gate_m1');
      expect(rung.kind, CatalogRungKind.gate);
    });

    test('doGameFor returns GateFieldPage builder for gate_m1', () {
      final raw = File('assets/game/catalog/content_catalog.json').readAsStringSync();
      final catalog = ContentCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final pack = catalog.packsById['gate_m1']!;
      expect(pack.engineType, 'gate_field');
      expect(pack.status, CatalogRungStatus.playable);

      final builder = doGameFor(pack);
      expect(builder, isNotNull);
      final widget = builder!(_ctx(), true);
      expect(widget, isA<GateFieldPage>());
    });

    test('knownMistakes registers GateMistakes', () {
      for (final m in GateMistakes.all) {
        expect(knownMistakes[m.key], equals(m), reason: m.key);
      }
    });
  });

  group('GateRun Pure Logic', () {
    test('Station 1: Rod selection rules', () {
      final run = GateRun(42);
      expect(run.station, GateStation.van);

      // Jugaad is deadly
      final deadly = run.chooseRod(RodChoice.pvcJugaad);
      expect(deadly, equals(GateMistakes.jugaadRod));
      expect(run.deadly, equals(GateMistakes.jugaadRod));

      // Correct choice
      final cleanRun = GateRun(42);
      final good = cleanRun.chooseRod(RodChoice.kv11Ok);
      expect(good, isNull);
      expect(cleanRun.caught, contains('১১ কেভি সঠিক রড বাছাই'));
    });

    test('Station 2: PTW verbal phone rules', () {
      final run = GateRun(42);
      run.station = GateStation.ptw;

      // Starting on phone is deadly
      final bad = run.answerPtw(stopWork: false);
      expect(bad, equals(GateMistakes.verbalPtw));

      // Stopping work is correct
      final clean = GateRun(42);
      clean.station = GateStation.ptw;
      final ok = clean.answerPtw(stopWork: true);
      expect(ok, isNull);
      expect(clean.caught, contains('মৌখিক নির্দেশে কাজ বন্ধ'));
    });

    test('Station 3: 360 Pole scan and acoustic tap', () {
      final run = GateRun(42);
      run.station = GateStation.pole;

      // Climbing without checking is slip
      final uninspected = run.decidePole(climb: true);
      expect(uninspected, equals(GateMistakes.condemnedPole));
      expect(run.slips, equals(1));

      // After walk & knock
      run.poleWalked = true;
      run.poleKnocked = true;
      final ok = run.decidePole(climb: true);
      expect(ok, isNull);
      expect(run.caught, contains('পোলের নিরেট শব্দ যাচাই'));
    });

    test('Station 4: Earth before line sequence', () {
      final run = GateRun(42);
      run.station = GateStation.discharge;

      // Touching wire before earth clamp is deadly
      final earlyLine = run.touchDischargeElement('R');
      expect(earlyLine, equals(GateMistakes.lineBeforeEarth));

      // Earth clamp first is safe
      final clean = GateRun(42);
      clean.station = GateStation.discharge;
      final clamp = clean.touchDischargeElement('earth');
      expect(clamp, isNull);
      expect(clean.earthClamped, isTrue);

      // Then phases R, Y, B
      expect(clean.touchDischargeElement('R'), isNull);
      expect(clean.touchDischargeElement('Y'), isNull);
      expect(clean.touchDischargeElement('B'), isNull);
      expect(clean.phasesTouched.length, 3);
      expect(clean.caught, contains('৩ ফেজ ডিসচার্জ সম্পন্ন'));
    });

    test('Station 5: Storm shelter selection', () {
      final run = GateRun(42);
      run.station = GateStation.storm;

      // Sheltering under lone tree is deadly
      final tree = run.chooseShelter(vanChosen: false);
      expect(tree, equals(GateMistakes.shelterTree));

      // Van is safe
      final clean = GateRun(42);
      clean.station = GateStation.storm;
      final van = clean.chooseShelter(vanChosen: true);
      expect(van, isNull);
      expect(clean.caught, contains('গাড়িতে নিরাপদ আশ্রয়'));
    });

    test('Station 5: Storm hazards (ladder slip and lightning backfeed)', () {
      expect(GateMistakes.stormLadderSlip.deadly, isTrue);
      expect(GateMistakes.stormLadderSlip.key, 'm1/gate/storm-ladder-slip');
      expect(GateMistakes.lightningBackfeed.deadly, isTrue);
      expect(GateMistakes.lightningBackfeed.key, 'm1/gate/lightning-backfeed');
    });
  });

  group('Option Lengths Balance (GAME_LEVEL_PLAYBOOK §4)', () {
    test('Station 1: Van rod why lengths', () {
      expectSameLength('van rod', [...GateLines.whyRodRight, ...GateLines.whyRodWrong]);
    });

    test('Station 2: PTW why lengths', () {
      expectSameLength('ptw', [...GateLines.whyPtwRight, ...GateLines.whyPtwWrong]);
    });

    test('Station 3: Pole why lengths', () {
      expectSameLength('pole', [...GateLines.whyPoleRight, ...GateLines.whyPoleWrong]);
    });

    test('Station 4: Discharge why lengths', () {
      expectSameLength('discharge', [...GateLines.whyDischargeRight, ...GateLines.whyDischargeWrong]);
    });

    test('Station 5: Storm why lengths', () {
      expectSameLength('storm', [...GateLines.whyStormRight, ...GateLines.whyStormWrong]);
    });

    test('Coworker script options length', () {
      expectSameLength('coworker', [...GateLines.coworker.right, ...GateLines.coworker.wrong]);
    });
  });

  group('Page Flow Smoke Test', () {
    testWidgets('GateFieldPage loads, waits intro, and enters Station 1', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;

      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: GateFieldPage(
              ctx: _ctx(),
              pack: _pack,
              muted: true,
              seed: 42,
            ),
          ),
        ),
      );

      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(GuideIntro), findsOneWidget);

      await waitIntro(t);
      await _pump(t, 400);

      expect(find.byType(GuideIntro), findsNothing);
      expect(find.textContaining('স্টেশন ১ · ভ্যানে রড বাছাই'), findsOneWidget);
      expect(find.byKey(const ValueKey('docket-modal')), findsOneWidget);

      // Accept docket
      await t.tap(find.text('ডকেট বুঝে নিলাম · কাজ শুরু করুন'));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('docket-modal')), findsNothing);
    });

    testWidgets('Docket modal can be reopened via header chip', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;

      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: GateFieldPage(
              ctx: _ctx(),
              pack: _pack,
              muted: true,
              seed: 42,
            ),
          ),
        ),
      );

      await waitIntro(t);
      await _pump(t, 400);

      // Dismiss initial modal
      await t.tap(find.text('ডকেট বুঝে নিলাম · কাজ শুরু করুন'));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('docket-modal')), findsNothing);

      // Tap header chip to reopen
      await t.tap(find.text('ডকেট DKT-11K'));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('docket-modal')), findsOneWidget);
      expect(find.textContaining('DKT-11K-0842'), findsOneWidget);
    });
  });
}
