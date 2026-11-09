import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/do_games.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/learn_voice_map.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistakes_book.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/ten_sec_scan.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _rung = '1.10/do/0';
final _pack = tenSecPacks['do_1_10_a']!;

LevelContext _ctx() => const LevelContext(
      rungId: _rung,
      kind: CatalogRungKind.doKind,
      lessonId: '1.10',
      lessonTitleBn: '১০ সেকেন্ডের মেন্টাল চেকলিস্ট',
      ladderStep: 29,
      doIndex: 0,
      doCount: 1,
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

  group('Catalog & Engine registration', () {
    test('content_catalog has 1.10/do/0 as playable', () {
      final raw = File('assets/game/catalog/content_catalog.json').readAsStringSync();
      final catalog = ContentCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final rung = catalog.rungDefs.firstWhere((r) => r.id == '1.10/do/0');
      expect(rung.status, CatalogRungStatus.playable);
      expect(rung.packId, 'do_1_10_a');
      expect(rung.lessonId, '1.10');
    });

    test('doGameFor returns TenSecScanPage builder for do_1_10_a', () {
      final raw = File('assets/game/catalog/content_catalog.json').readAsStringSync();
      final catalog = ContentCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final pack = catalog.packsById['do_1_10_a']!;
      expect(pack.engineType, 'ten_sec_scan');
      expect(pack.status, CatalogRungStatus.playable);

      final builder = doGameFor(pack);
      expect(builder, isNotNull);
      final widget = builder!(_ctx(), true);
      expect(widget, isA<TenSecScanPage>());
    });

    test('knownMistakes registers TenSecMistakes', () {
      for (final m in TenSecMistakes.all) {
        expect(knownMistakes[m.key], equals(m), reason: m.key);
      }
    });
  });

  group('Deal generation & rules', () {
    test('dealTenSec gives exactly 10 checks covering 10 categories with a deadly check', () {
      for (var s = 0; s < 30; s++) {
        final deal = dealTenSec(math.Random(s));
        expect(deal.checks.length, 10, reason: 'seed $s');
        expect(deal.coworkerRound, isIn([4, 5]));

        final categories = deal.checks.map((c) => c.categoryBn).toSet();
        expect(categories.length, 10, reason: 'seed $s should cover 10 unique categories');

        final hasDeadly = deal.checks.any((c) => c.mistake.deadly);
        expect(hasDeadly, isTrue, reason: 'seed $s must have at least one deadly hazard');

        final safeCount = deal.checks.where((c) => c.isSafe).length;
        expect(safeCount, inInclusiveRange(3, 7), reason: 'balanced mix of Go/Stop');
      }
    });

    test('all reasons have fair option lengths', () {
      for (var s = 0; s < 10; s++) {
        final deal = dealTenSec(math.Random(s));
        for (final c in deal.checks) {
          expectSameLength(c.id, [...c.whyRight, ...c.whyWrong]);
        }
      }
    });

    test('coworker script lines have registered voice clips', () {
      final script = TenSecLines.coworker;
      for (final line in script.recordedLines) {
        expect(learnRivalVoice[line], isNotNull, reason: 'voice clip for "$line" must exist');
      }
      expectSameLength('coworker script', [...script.right, ...script.wrong]);
    });
  });

  group('TenSecRun logic', () {
    test('correct choices achieve 100% and pass', () {
      final deal = dealTenSec(math.Random(42));
      final run = TenSecRun(deal);

      for (var i = 0; i < 10; i++) {
        expect(run.index, i);
        final check = run.current;
        final mistake = run.evaluate(check.isSafe);
        expect(mistake, isNull);
        expect(run.caught.contains(check.caughtTag), isTrue);
        run.advance();
      }

      expect(run.done, isTrue);
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.slips, 0);
      expect(run.deadly, isNull);
    });

    test('stopping on safe item is a slip', () {
      final deal = dealTenSec(math.Random(42));
      final run = TenSecRun(deal);

      // find a safe check
      while (!run.current.isSafe && !run.done) {
        run.advance();
      }
      if (!run.done) {
        final m = run.evaluate(false); // choose STOP on safe
        expect(m, equals(TenSecMistakes.safeStopped));
        expect(run.slips, 1);
        expect(run.deadly, isNull);
      }
    });

    test('choosing GO on deadly hazard sets deadly', () {
      final deal = dealTenSec(math.Random(42));
      final run = TenSecRun(deal);

      while (!run.current.mistake.deadly && !run.done) {
        run.advance();
      }
      if (!run.done) {
        final m = run.evaluate(true); // choose GO on deadly hazard
        expect(m?.deadly, isTrue);
        expect(run.deadly, equals(m));
        expect(run.ended, isTrue);
        expect(run.passed, isFalse);
      }
    });
  });

  group('Widget & UX flow', () {
    testWidgets('renders intro, transitions into main scene with card and buttons', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      addTearDown(() {
        t.view.reset();
      });

      final c = ProviderContainer();
      addTearDown(c.dispose);

      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: TenSecScanPage(
              ctx: _ctx(),
              pack: _pack,
              muted: true,
              seed: 1234,
            ),
          ),
        ),
      );

      await _pump(t, 200);
      expect(find.byType(GuideIntro), findsOneWidget);

      // Wait for intro to finish
      await waitIntro(t);
      await _pump(t, 600);

      expect(find.byType(GuideIntro), findsNothing);
      expect(find.byType(FullSceneFrame), findsOneWidget);

      // Verify the GO and STOP buttons are on screen
      expect(find.text(TenSecLines.stopBtn), findsOneWidget);
      expect(find.text(TenSecLines.goBtn), findsOneWidget);
    });
  });
}
