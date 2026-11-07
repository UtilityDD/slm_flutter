// Lesson 1.5, কাজ 2 (আগে মাটি, পরে লাইন) in the level shell: the first deadly
// mistake is a near-miss; the next one is a death that is recorded when the
// level is left and sends passed Do levels back to 'prove'. A clean play with
// the pressure call refused passes and clears the rung.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/discharge_order.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

const _ctx = LevelContext(
  rungId: '1.5/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.5',
  lessonTitleBn: '',
  ladderStep: 15,
  doIndex: 2,
  doCount: 2,
);

Finder _onCard(String text) => find.descendant(of: find.byType(MistakeCard), matching: find.text(text));

Finder _spot(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

/// The two earth points: [good] picks the sound one for this deal.
Finder _earth(WidgetTester t, DischargeDeal d, {required bool good}) {
  final both = _spot('আর্থ পয়েন্ট');
  final a = t.getCenter(both.at(0)).dx < t.getCenter(both.at(1)).dx ? 0 : 1;
  final left = both.at(a);
  final right = both.at(1 - a);
  return good == d.goodLeft ? left : right;
}

/// A seed whose deal passes [ok]; [retry] also checks the next play (seed + 1).
int _seedWhere(bool Function(DischargeDeal d) ok, {bool Function(DischargeDeal d)? retry}) {
  for (var s = 0; s < 500; s++) {
    if (ok(dealDischarge(math.Random(s))) && (retry == null || retry(dealDischarge(math.Random(s + 1))))) return s;
  }
  throw StateError('no seed');
}

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _tap(WidgetTester t, Finder f, [int after = 400]) async {
  await t.tap(f, warnIfMissed: false);
  await _pump(t, after);
}

void main() {
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

  Future<(ProviderContainer, GlobalKey<NavigatorState>)> open(WidgetTester t, int seed) async {
    t.view.physicalSize = const Size(720, 1600);
    t.view.devicePixelRatio = 2.0;
    final c = ProviderContainer();
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ));
    await _pump(t, 100);
    unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
      builder: (_) => DischargeOrderPage(ctx: _ctx, pack: dischargePack15, muted: true, seed: seed),
    )));
    await _pump(t, 3000);
    return (c, nav);
  }

  Future<void> close(WidgetTester t, ProviderContainer c) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
    MascotTalk.reset();
    c.dispose();
    t.view.reset();
  }

  testWidgets('first deadly mistake is a near-miss; the next is a death and Do levels fall', (t) async {
    // The call comes late in both plays, so it never covers the first tap.
    final seed = _seedWhere((d) => d.callAfter == 2, retry: (d) => d.callAfter > 0);
    final (c, _) = await open(t, seed);
    final save = c.read(gameSaveProvider.notifier);
    await save.markRungCleared('1.1/learn');
    await save.markRungCleared('1.1/do/0');

    expect(find.text('পাঠ 1.5 · কাজ 2/2'), findsOneWidget);
    expect(find.text('আর্থ পয়েন্ট'), findsNothing, reason: 'no names on screen');

    // Hook on R before the earth: deadly, but the game's first is a near-miss.
    await _tap(t, _spot('R ফেজ'), 1500);
    expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
    expect(_onCard(DischargeMistakes.lineBeforeEarth.textBn), findsOneWidget);
    expect(find.text(MistakeLines.readLesson), findsOneWidget);
    expect(c.read(gameSaveProvider).deaths, 0);
    expect(c.read(gameSaveProvider).nearMissUsed, isTrue);
    expect(c.read(gameSaveProvider).mistakes.single.key, DischargeMistakes.lineBeforeEarth.key);

    // Try again; this time the chain before the earth: a real death.
    await _tap(t, find.text(MistakeLines.tryAgain), 3000);
    expect(find.text(MistakeLines.nearMissHead), findsNothing);
    await _tap(t, _spot('চেইন'), 1500);
    expect(find.text(MistakeLines.deadlyHead), findsOneWidget);
    expect(_onCard(DischargeMistakes.chainInsteadOfRod.textBn), findsOneWidget);
    expect(c.read(gameSaveProvider).deaths, 0, reason: 'recorded on leaving, so the ladder shows the fall');

    await _tap(t, find.text(MistakeLines.toLadder), 1200);
    expect(find.byType(DischargeOrderPage), findsNothing);
    final s = c.read(gameSaveProvider);
    expect(s.deaths, 1);
    expect(s.rungProgress['1.1/learn'], 'cleared');
    expect(s.rungProgress['1.1/do/0'], 'prove');
    expect(s.levelScoreByRung['1.5/do/1'] ?? 0, 0);
    expect(t.takeException(), isNull);
    await close(t, c);
  });

  testWidgets('a slip shows its card and the play goes on; a clean finish clears the rung', (t) async {
    final seed = _seedWhere((d) => d.callAfter == 1);
    final deal = dealDischarge(math.Random(seed));
    final (c, _) = await open(t, seed);

    // Rusty earth first: a slip with its picture card.
    await _tap(t, _earth(t, deal, good: false), 700);
    expect(find.text(MistakeLines.slipHead), findsOneWidget);
    expect(_onCard(DischargeMistakes.rustyEarth.textBn), findsOneWidget);
    await _tap(t, find.text(MistakeLines.gotIt), 500);
    expect(find.text(MistakeLines.slipHead), findsNothing);

    // Sound earth; then the pressure call: refuse it.
    await _tap(t, _earth(t, deal, good: true), 600);
    expect(find.text(DischargeLines.hold), findsOneWidget);
    await _tap(t, find.text(DischargeLines.hold), 600);
    for (final p in ['B ফেজ', 'R ফেজ', 'Y ফেজ']) {
      await _tap(t, _spot(p), 500);
    }
    await _tap(t, _spot('চেইন'), 1500);

    // Round 2: off in reverse, earth last.
    await _tap(t, _spot('রডের হুক'), 500);
    await _tap(t, _spot('চেইন'), 500);
    await _tap(t, _spot('আর্থ ক্ল্যাম্প'), 3000);

    final s = c.read(gameSaveProvider);
    expect(s.rungProgress['1.5/do/1'], 'cleared');
    expect(s.deaths, 0);
    expect(s.mistakes.single.key, DischargeMistakes.rustyEarth.key);
    expect(find.text(DischargeLines.caughtCall), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t, c);
  });
}
