// "ভাগ্যের টুলবক্স" (lucky toolbox on the ladder): a chest opens once (keys
// are paused behind ToolboxFlags.keysEnabled; their rules are still tested
// with the flag on), the quick task lifts the tier, odds shift with the tier,
// pity, the shield and ×2 boosts, the quiz sources (Supabase → cached passed
// lessons → none), the overlay flow, the quiet pick screen, and stage 2
// "হঠাৎ উপহার": seeded chest drops after first clears, the gate chest, life
// skills as prizes, and a ladder with no side stations.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/duty_slip/adventure_map.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_engine.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_models.dart';
import 'package:slm_flutter/features/duty_slip/lucky_toolbox_overlay.dart';
import 'package:slm_flutter/features/game/beat_fx.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/ladder_builder.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/lucky_toolbox.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/mistakes_book.dart';
import 'package:slm_flutter/features/game/ten_sec_scan.dart';
import 'package:slm_flutter/features/game/toolbox_quiz_sources.dart';
import 'package:slm_flutter/features/game/toolbox_shield.dart';
import 'package:slm_flutter/features/life_skills/life_skills_data.dart';
import 'package:slm_flutter/features/home/lesson_quiz_page.dart';
import 'package:slm_flutter/features/home/lesson_quiz_store.dart';
import 'package:slm_flutter/features/training/training_models.dart';
import 'package:slm_flutter/features/training/training_provider.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

/// Always the first choice: nextInt → 0, nextBool → true.
class _FirstRandom implements math.Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0;
}

Future<(ProviderContainer, GameSaveController)> _boot() async {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  final save = c.read(gameSaveProvider.notifier);
  await Future<void>.delayed(Duration.zero);
  return (c, save);
}

MistakeEntry _ownMistake() {
  final m = knownMistakes.values.first;
  return MistakeEntry(key: m.key, lessonId: '1.1', rungId: '1.1/do/0', textBn: m.textBn, deadly: m.deadly, atMs: 1);
}

/// The save as already loaded (the ladder has hydrated it long before a chest tap).
class _SeededSave extends GameSaveController {
  _SeededSave(this.seed);

  final GameSave seed;

  @override
  GameSave build() => seed;
}

Override _seed(GameSave s) => gameSaveProvider.overrideWith(() => _SeededSave(s));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final ch in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    messenger.setMockMethodCallHandler(MethodChannel(ch), (_) async => 1);
  }
  ZlFx.setMuted(true);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Life-skill files straight from disk: on the test clock, never shared across tests.
    LifeSkillsRepo.instance = LifeSkillsRepo(bundle: _DiskBundle());
  });

  group('keys (paused: behind ToolboxFlags.keysEnabled)', () {
    setUp(() => ToolboxFlags.keysEnabled = true);
    tearDown(() => ToolboxFlags.keysEnabled = false);

    test('star mapping: 1–2 stars = 1 key, 3 stars = 2; a Learn pass 1, a clean 100 % 2', () {
      expect(toolboxKeysForStars(0), 0);
      expect(toolboxKeysForStars(1), 1);
      expect(toolboxKeysForStars(2), 1);
      expect(toolboxKeysForStars(3), 2);
      expect(toolboxKeysForLearnMark(60), 1);
      expect(toolboxKeysForLearnMark(100), 2);
    });

    test('a rung pays once for its best result', () async {
      final (c, save) = await _boot();
      await save.markRungCleared('1.1/do/0');
      await save.recordStars('1.1/do/0', 2);
      expect(c.read(gameSaveProvider).toolbox.keys, 1);
      // Replays at the same or a lower result pay nothing more.
      await save.markRungCleared('1.1/do/0');
      await save.recordStars('1.1/do/0', 1);
      expect(c.read(gameSaveProvider).toolbox.keys, 1);
      // A better replay pays only the difference.
      await save.recordStars('1.1/do/0', 3);
      expect(c.read(gameSaveProvider).toolbox.keys, 2);
      await save.recordStars('1.1/do/0', 3);
      expect(c.read(gameSaveProvider).toolbox.keys, 2);
      // A Learn board: pass = 1, then a clean 100 % lifts it to 2.
      await save.recordLevelResult('1.2/learn', 80);
      await save.markRungCleared('1.2/learn');
      expect(c.read(gameSaveProvider).toolbox.keys, 3);
      await save.recordLevelResult('1.2/learn', 100);
      await save.markRungCleared('1.2/learn');
      expect(c.read(gameSaveProvider).toolbox.keys, 4);
      expect(c.read(gameSaveProvider).toolbox.keysByRung, {'1.1/do/0': 2, '1.2/learn': 2});
      // A failed play (no clear, no stars) earns nothing.
      await save.recordLevelResult('1.3/do/0', 40);
      await save.commitLevelScore('1.3/do/0', 20);
      expect(c.read(gameSaveProvider).toolbox.keys, 4);
    });

    test('old save JSON loads with 0 keys; the toolbox round-trips', () {
      final old = GameSave.fromJson({'points': 120, 'giftsClaimed': ['station_gift@1.2/do/1']});
      expect(old.toolbox.keys, 0);
      expect(old.toolbox.shields, 0);
      expect(old.toolbox.doubleNext, isFalse);
      expect(old.toolbox.sinceRare, 0);
      const t = ToolboxSave(keys: 3, keysByRung: {'1.1/do/0': 2}, opens: 4, sinceRare: 2, shields: 1, doubleNext: true, badge: true);
      final back = GameSave.fromJson(jsonDecode(jsonEncode(GameSave.empty.copyWith(toolbox: t).toJson())) as Map<String, dynamic>);
      expect(back.toolbox.keys, 3);
      expect(back.toolbox.keysByRung, {'1.1/do/0': 2});
      expect(back.toolbox.opens, 4);
      expect(back.toolbox.sinceRare, 2);
      expect(back.toolbox.shields, 1);
      expect(back.toolbox.doubleNext, isTrue);
      expect(back.toolbox.badge, isTrue);
    });
  });

  group('chest', () {
    test('keys off (default): no level earns keys and a chest opens once without one', () async {
      expect(ToolboxFlags.keysEnabled, isFalse);
      final (c, save) = await _boot();
      await save.markRungCleared('1.1/do/0');
      await save.recordStars('1.1/do/0', 3);
      expect(c.read(gameSaveProvider).toolbox.keys, 0);
      expect(c.read(gameSaveProvider).toolbox.keysByRung, isEmpty);
      final both = await Future.wait([
        save.openToolbox('station_gift@1.2/do/1', rareOrBetter: false, coins: 15),
        save.openToolbox('station_gift@1.2/do/1', rareOrBetter: false, coins: 15),
      ]);
      expect(both.where((b) => b).length, 1);
      expect(c.read(gameSaveProvider).points, 15);
      expect(c.read(gameSaveProvider).toolbox.keys, 0);
      expect(await save.openToolbox('station_gift@1.2/do/1', rareOrBetter: true, coins: 50), isFalse);
      expect(c.read(gameSaveProvider).points, 15);
    });

    test('keys on: a chest costs a key and opens once', () async {
      ToolboxFlags.keysEnabled = true;
      addTearDown(() => ToolboxFlags.keysEnabled = false);
      final (c, save) = await _boot();
      expect(await save.openToolbox('station_gift@1.2/do/1', rareOrBetter: false, coins: 10), isFalse);
      expect(c.read(gameSaveProvider).points, 0);
      await save.markRungCleared('1.1/do/0');
      await save.markRungCleared('1.1/do/1');
      expect(c.read(gameSaveProvider).toolbox.keys, 2);
      // Two taps in the same frame: only one opens.
      final both = await Future.wait([
        save.openToolbox('station_gift@1.2/do/1', rareOrBetter: false, coins: 15),
        save.openToolbox('station_gift@1.2/do/1', rareOrBetter: false, coins: 15),
      ]);
      expect(both.where((b) => b).length, 1);
      final s = c.read(gameSaveProvider);
      expect(s.toolbox.keys, 1);
      expect(s.points, 15);
      expect(s.giftsClaimed, contains('station_gift@1.2/do/1'));
      expect(await save.openToolbox('station_gift@1.2/do/1', rareOrBetter: true, coins: 50), isFalse);
      expect(c.read(gameSaveProvider).toolbox.keys, 1);
      expect(c.read(gameSaveProvider).points, 15);
    });

    test('a right task lifts the tier one step; wrong or skipped does not', () {
      expect(tierAfterTask(ChestTier.wood, right: true), ChestTier.silver);
      expect(tierAfterTask(ChestTier.silver, right: true), ChestTier.gold);
      expect(tierAfterTask(ChestTier.gold, right: true), ChestTier.gold);
      expect(tierAfterTask(ChestTier.wood, right: false), ChestTier.wood);
      expect(tierAfterTask(ChestTier.silver, right: null), ChestTier.silver);
    });

    test('odds shift with the tier (seeded)', () {
      final rare = <ChestTier, int>{};
      final legend = <ChestTier, int>{};
      for (final tier in ChestTier.values) {
        final rng = math.Random(42);
        for (var i = 0; i < 6000; i++) {
          final r = rollToolboxRarity(tier, rng);
          if (r.index >= ToolboxRarity.rare.index) rare[tier] = (rare[tier] ?? 0) + 1;
          if (r == ToolboxRarity.legendary) legend[tier] = (legend[tier] ?? 0) + 1;
        }
      }
      expect(rare[ChestTier.wood]!, lessThan(rare[ChestTier.silver]!));
      expect(rare[ChestTier.silver]!, lessThan(rare[ChestTier.gold]!));
      expect(legend[ChestTier.wood]!, lessThan(legend[ChestTier.gold]!));
      // Close to the table (30 % / 50 % / 70 % Rare-or-better).
      expect(rare[ChestTier.wood]! / 6000, closeTo(0.30, 0.03));
      expect(rare[ChestTier.gold]! / 6000, closeTo(0.70, 0.03));
    });

    test('prizes: common 10–20 ◆, rare 50 ◆, epic shield / ×2, legendary 200 ◆ / badge; duplicates turn into ◆', () {
      final rng = math.Random(7);
      for (var i = 0; i < 3000; i++) {
        final r = rollToolboxReward(ChestTier.gold, rng);
        switch (r.rarity) {
          case ToolboxRarity.common:
            expect(r.coins, inInclusiveRange(10, 20));
          case ToolboxRarity.rare:
            expect(r.coins, kToolboxRareCoins);
          case ToolboxRarity.epic:
            expect(r.prize, anyOf(ToolboxPrize.shield, ToolboxPrize.doubleNext));
          case ToolboxRarity.legendary:
            expect(r.prize == ToolboxPrize.badge || r.coins == kToolboxLegendCoins, isTrue);
        }
      }
      for (var i = 0; i < 500; i++) {
        final r = rollToolboxReward(ChestTier.gold, rng, hasBadge: true, doublePending: true);
        expect(r.prize, isNot(ToolboxPrize.badge));
        expect(r.prize, isNot(ToolboxPrize.doubleNext));
      }
    });

    test('pity: Rare-or-better at least once every 5 opens', () async {
      // A Random that would always roll Common.
      final rng = _FirstRandom();
      final (c, save) = await _boot();
      for (var i = 0; i < 5; i++) {
        await save.markRungCleared('1.$i/do/0');
      }
      var sinceRare = 0;
      for (var open = 1; open <= 5; open++) {
        final deal = dealToolbox(ChestTier.wood, rng, c.read(gameSaveProvider).toolbox);
        if (open < 5) {
          expect(deal.every((r) => r.rarity == ToolboxRarity.common), isTrue, reason: 'open $open');
        } else {
          expect(deal.every((r) => r.rareOrBetter), isTrue, reason: 'the 5th open is guaranteed');
        }
        await save.openToolbox('station_gift@x$open', rareOrBetter: deal.first.rareOrBetter, coins: deal.first.coins);
        sinceRare = c.read(gameSaveProvider).toolbox.sinceRare;
      }
      expect(sinceRare, 0);
      expect(c.read(gameSaveProvider).toolbox.opens, 5);
      // Also with real randomness: never 5 opens in a row without Rare+.
      final r2 = math.Random(3);
      var t = const ToolboxSave();
      var dry = 0;
      for (var i = 0; i < 400; i++) {
        final pick = dealToolbox(ChestTier.wood, r2, t)[r2.nextInt(3)];
        dry = pick.rareOrBetter ? 0 : dry + 1;
        expect(dry, lessThan(kToolboxPityEvery));
        t = t.copyWith(sinceRare: pick.rareOrBetter ? 0 : t.sinceRare + 1);
      }
    });
  });

  group('boosts', () {
    test('×2 doubles one completed level once', () async {
      final (c, save) = await _boot();
      await save.markRungCleared('1.1/do/0');
      await save.openToolbox('station_gift@1.2/do/1', rareOrBetter: true, doubleNext: true);
      expect(c.read(gameSaveProvider).toolbox.doubleNext, isTrue);
      // A play that cleared nothing does not use it.
      await save.commitLevelScore('1.3/do/0', 30);
      expect(c.read(gameSaveProvider).toolbox.doubleNext, isTrue);
      final before = c.read(gameSaveProvider).points;
      await save.markRungCleared('1.2/do/0');
      final delta = await save.commitLevelScore('1.2/do/0', 40);
      expect(delta, 80);
      expect(c.read(gameSaveProvider).levelScoreByRung['1.2/do/0'], 80);
      expect(c.read(gameSaveProvider).points, before + 80);
      expect(c.read(gameSaveProvider).toolbox.doubleNext, isFalse);
      await save.markRungCleared('1.2/do/1');
      expect(await save.commitLevelScore('1.2/do/1', 40), 40);
    });

    testWidgets('a shield forgives one strike, with its toast; the next strike counts', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [_seed(GameSave.empty.copyWith(toolbox: const ToolboxSave(shields: 1)))],
        child: const MaterialApp(home: Scaffold(body: _StrikeHost())),
      ));
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(find.byKey(const ValueKey('strike')));
      await t.pump();
      expect(find.text('strikes 0'), findsOneWidget);
      expect(find.byKey(const ValueKey('toolbox-shield-toast')), findsOneWidget);
      expect(find.text(ToolboxShieldLines.saved), findsOneWidget);
      final c = ProviderScope.containerOf(t.element(find.byType(_StrikeHost)));
      expect(c.read(gameSaveProvider).toolbox.shields, 0);
      await t.pump(const Duration(seconds: 2));
      expect(find.byKey(const ValueKey('toolbox-shield-toast')), findsNothing);
      await t.tap(find.byKey(const ValueKey('strike')));
      await t.pump();
      expect(find.text('strikes 1'), findsOneWidget);
      expect(find.byKey(const ValueKey('toolbox-shield-toast')), findsNothing);
    });
  });

  group('quick task', () {
    test('offline with nothing cached: the quiz type is skipped and the network is never asked', () async {
      final root = Directory.systemTemp.createTempSync('toolbox_quiz');
      addTearDown(() => root.deleteSync(recursive: true));
      var calls = 0;
      final store = LessonQuizStore(
        httpGet: (_) async {
          calls++;
          throw const SocketException('offline');
        },
        cacheRoot: () async => root,
      );
      expect(await store.cachedOnly(1, 1), isNull);
      final old = LessonQuizStore.instance;
      LessonQuizStore.instance = store;
      addTearDown(() => LessonQuizStore.instance = old);
      final save = GameSave.empty.copyWith(rungProgress: {'1.1/learn': 'cleared'}, mistakes: [_ownMistake()]);
      expect(await const CachedLessonQuizSource().questionsFor(save), isEmpty);
      expect(await CachedLessonQuizSource(store: store).questionsFor(save), isEmpty);
      expect(calls, 0);
      for (var seed = 0; seed < 60; seed++) {
        final task = pickToolboxTask(
          save: save,
          known: knownMistakes,
          eyeChecks: TenSecChecks.all,
          quiz: await const CachedLessonQuizSource().next(save, math.Random(seed)),
          rng: math.Random(seed),
        );
        expect(task, isNotNull);
        expect(task!.kind, isNot(ToolboxTaskKind.quiz));
      }
      // A quiz saved on this phone is used (still without the network).
      final dir = Directory('${root.path}/lesson_quiz_v1')..createSync(recursive: true);
      File('${dir.path}/${lessonQuizFileName(1, 1)}').writeAsStringSync(jsonEncode([
        {'questionText': 'প্রশ্ন?', 'options': ['ক', 'খ', 'গ'], 'correctAnswerIndex': 1},
      ]));
      final fresh = LessonQuizStore(httpGet: (_) async => throw const SocketException('offline'), cacheRoot: () async => root);
      LessonQuizStore.instance = fresh;
      final cached = await const CachedLessonQuizSource().questionsFor(save);
      expect(cached.single.correctIndex, 1);
      final q = pickQuizQuestion(cached, math.Random(1))!;
      expect(quizTask(q).kind, ToolboxTaskKind.quiz);
      expect(quizTask(q).serverChecked, isFalse);
    });

    test('own mistakes come first; the decoy is another mistake; ten-sec cards only from met lessons', () {
      final save = GameSave.empty.copyWith(mistakes: [_ownMistake()]);
      final own = ownMistakeTask(save, knownMistakes, math.Random(2))!;
      expect(own.options, contains(_ownMistake().textBn));
      expect(own.options[own.correctIndex], _ownMistake().textBn);
      expect(own.options.toSet().length, 2);
      expect(own.promptBn, ToolboxLines.whichMistake);
      expect(own.art, knownMistakes[_ownMistake().key]!.art);
      // No Learn rung cleared: no ten-sec card.
      expect(eyeTask(GameSave.empty, TenSecChecks.all, math.Random(1)), isNull);
      final met = GameSave.empty.copyWith(rungProgress: {'1.1/learn': 'cleared'});
      for (var seed = 0; seed < 30; seed++) {
        final eye = eyeTask(met, TenSecChecks.all, math.Random(seed))!;
        final check = TenSecChecks.all.firstWhere((c) => c.art == eye.art);
        expect(check.topic, ScanTopic.ppe);
        expect(eye.options, [ToolboxLines.eyeOk, ToolboxLines.eyeFault]);
        expect(eye.correctIndex, check.isSafe ? 0 : 1);
      }
      // Weighted 3 : 1 : 1 toward the player's own mistakes.
      final both = met.copyWith(mistakes: [_ownMistake()]);
      var mine = 0;
      for (var seed = 0; seed < 400; seed++) {
        final task = pickToolboxTask(
          save: both,
          known: knownMistakes,
          eyeChecks: TenSecChecks.all,
          quiz: const ToolboxQuizQuestion(text: 'প্রশ্ন?', options: ['ক', 'খ'], correctIndex: 0),
          rng: math.Random(seed),
        )!;
        if (task.kind == ToolboxTaskKind.ownMistake) mine++;
      }
      expect(mine / 400, closeTo(0.6, 0.08));
    });
  });

  group('overlay', () {
    Future<ProviderContainer> pumpOverlay(
      WidgetTester t,
      GameSave save, {
      bool reduceMotion = false,
      bool gate = false,
      ToolboxQuizSource quiz = const _NoQuiz(),
    }) async {
      t.view.physicalSize = const Size(720, 1520);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduceMotion);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final scoreKey = GlobalKey();
      await t.pumpWidget(
        ProviderScope(
          overrides: [_seed(save)],
          child: MaterialApp(
            home: Scaffold(
              body: ScoreFlyHost(
                scoreKey: scoreKey,
                child: Stack(
                  children: [
                    Positioned(top: 30, right: 30, child: SizedBox(key: scoreKey, width: 40, height: 20)),
                    Positioned.fill(
                      child: _OverlayHarness(gate: gate, quiz: quiz),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 100));
      return ProviderScope.containerOf(t.element(find.byType(LuckyToolboxOverlay)));
    }

    // Keys are off: the chest opens without one.
    final withKey = GameSave.empty.copyWith(mistakes: [_ownMistake()]);

    testWidgets('tap → task → pick → reveal → ◆ added (right answer lifts the tier)', (t) async {
      final c = await pumpOverlay(t, withKey);
      expect(find.text(ToolboxLines.taskTitle(ToolboxTaskKind.ownMistake)), findsOneWidget);
      expect(find.text(ToolboxLines.whichMistake), findsOneWidget);
      expect(find.text(ToolboxLines.tierName(ChestTier.wood)), findsOneWidget);
      // _FirstRandom puts the player's own mistake first.
      await t.tap(find.byKey(const ValueKey('toolbox-opt-0')));
      await t.pump();
      expect(find.text(ToolboxLines.tierName(ChestTier.silver)), findsOneWidget);
      await t.pump(const Duration(milliseconds: 1100));
      expect(find.text(ToolboxLines.pick), findsOneWidget);
      await t.pump(const Duration(milliseconds: 1200));
      final before = c.read(gameSaveProvider).points;
      await t.tap(find.byKey(const ValueKey('toolbox-box-0')));
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final s = c.read(gameSaveProvider);
      expect(s.points, before + 10);
      expect(s.toolbox.opens, 1);
      expect(s.toolbox.sinceRare, 1);
      expect(find.byKey(const ValueKey('toolbox-keys')), findsNothing);
      expect(s.giftsClaimed, contains('station_gift@1.2/do/1'));
      expect(find.text(ToolboxLines.missed), findsOneWidget);
      expect(find.text('+10 ◆'), findsWidgets);
      await t.tap(find.byKey(const ValueKey('toolbox-back')));
      await t.pump();
      expect(find.byType(LuckyToolboxOverlay), findsNothing);
    });

    testWidgets('a wrong answer shows the right one ~2 s, no tier boost', (t) async {
      await pumpOverlay(t, withKey);
      await t.tap(find.byKey(const ValueKey('toolbox-opt-1')));
      await t.pump();
      expect(find.text(ToolboxLines.tierName(ChestTier.wood)), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await t.pump(const Duration(milliseconds: 1500));
      expect(find.text(ToolboxLines.pick), findsNothing);
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text(ToolboxLines.pick), findsOneWidget);
      expect(find.text(ToolboxLines.tierName(ChestTier.wood)), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
    });

    testWidgets('a gate chest gives a new life skill beside the pick', (t) async {
      final c = await pumpOverlay(t, withKey, gate: true);
      await t.tap(find.byKey(const ValueKey('toolbox-skip')));
      await t.pump(const Duration(milliseconds: 1300));
      await t.tap(find.byKey(const ValueKey('toolbox-box-0')));
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final s = c.read(gameSaveProvider);
      expect(s.toolbox.lifeSkills, hasLength(1));
      expect(kLifeSkillIds, contains(s.toolbox.lifeSkills.single));
      expect(find.byKey(const ValueKey('toolbox-gate-extra')), findsOneWidget);
      expect(find.text(ToolboxLines.gateExtra), findsOneWidget);
    });

    testWidgets('a server-checked question: the server marks it right and the tier goes up', (t) async {
      final c = await pumpOverlay(
        t,
        GameSave.empty,
        quiz: ToolboxQuizChain([SupabaseToolboxQuizSource(rpc: _FakeRpc().call)]),
      );
      expect(find.text('সার্ভারের প্রশ্ন?'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('toolbox-opt-1')));
      await t.pump();
      await t.pump();
      expect(find.text(ToolboxLines.tierName(ChestTier.silver)), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
      expect(find.text(ToolboxLines.pick), findsOneWidget);
      // Checking a quiz awards nothing by itself.
      expect(c.read(gameSaveProvider).points, 0);
      await t.pump(const Duration(seconds: 2));
    });

    testWidgets('skip goes straight to the pick with no boost; the gate chest starts at silver', (t) async {
      final c = await pumpOverlay(t, withKey, gate: true);
      expect(find.text(ToolboxLines.tierName(ChestTier.silver)), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('toolbox-skip')));
      await t.pump();
      expect(find.text(ToolboxLines.pick), findsOneWidget);
      expect(find.text(ToolboxLines.tierName(ChestTier.silver)), findsOneWidget);
      // Leaving before the pick spends nothing.
      await t.tap(find.byKey(const ValueKey('toolbox-close')));
      await t.pump();
      expect(c.read(gameSaveProvider).toolbox.opens, 0);
      expect(c.read(gameSaveProvider).giftsClaimed, isEmpty);
    });

    for (final reduce in [false, true]) {
      testWidgets('the pick screen waits quietly (zero frames) ${reduce ? '(reduce motion)' : ''}', (t) async {
        await pumpOverlay(t, withKey, reduceMotion: reduce);
        await t.tap(find.byKey(const ValueKey('toolbox-skip')));
        for (var i = 0; i < 30; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.text(ToolboxLines.pick), findsOneWidget);
        var rebuilds = 0;
        debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugOnRebuildDirtyWidget = null;
        expect(frames, 0);
        expect(rebuilds, 0);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('sudden chests (হঠাৎ উপহার)', () {
    List<String> catalogIds() {
      final cat = jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map<String, dynamic>;
      return [for (final r in cat['rungDefs'] as List) (r as Map)['id'] as String];
    }

    test('drops about 1 in 3 first clears, at least every 4th, seeded (same save = same chests)', () {
      final ids = [for (final id in catalogIds()) if (!id.endsWith('/gate')) id];
      List<bool> run() {
        var since = 0;
        final out = <bool>[];
        for (var i = 0; i < ids.length; i++) {
          final d = toolboxChestDrop(rungId: ids[i], clearNo: i, sinceDrop: since, waiting: 0);
          out.add(d != null);
          since = d == null ? since + 1 : 0;
          if (d != null) {
            expect(d.gate, isFalse);
            expect(d.tier, 'wood');
          }
        }
        return out;
      }

      final a = run();
      expect(run(), a, reason: 'deterministic');
      var dry = 0;
      for (final dropped in a) {
        dry = dropped ? 0 : dry + 1;
        expect(dry, lessThan(kToolboxDropEvery), reason: 'never 4 first clears in a row without a chest');
      }
      final rate = a.where((d) => d).length / a.length;
      // ~1/3 plus the guarantee.
      expect(rate, inInclusiveRange(0.30, 0.50));
      // The seed alone (no guarantee) is close to 1 in 3.
      final raw = [for (var i = 0; i < ids.length; i++) toolboxSeed('${ids[i]}#$i') % kToolboxDropOneIn == 0];
      expect(raw.where((d) => d).length / raw.length, closeTo(1 / 3, 0.08));
      // A full ladder of waiting chests: no ordinary drop, a gate still drops.
      expect(toolboxChestDrop(rungId: ids.first, clearNo: 0, sinceDrop: 9, waiting: kToolboxMaxWaiting), isNull);
      expect(toolboxChestDrop(rungId: 'm2/gate', clearNo: 0, sinceDrop: 0, waiting: kToolboxMaxWaiting), isNotNull);
    });

    test('a gate always drops a silver chest; only the first clear drops; the chest persists in the save JSON', () async {
      final (c, save) = await _boot();
      await save.markRungCleared('m1/gate');
      var s = c.read(gameSaveProvider);
      final gate = s.toolbox.chests.single;
      expect(gate.rungId, 'm1/gate');
      expect(gate.gate, isTrue);
      expect(gate.tier, 'silver');
      expect(chestTierNamed(gate.tier), ChestTier.silver);
      expect(save.lastChestDrop?.claimId, toolboxChestClaimId('m1/gate'));
      expect(s.toolbox.firstClears, 1);
      // Re-clearing (and proving again after a fall) never drops another.
      await save.markRungCleared('m1/gate');
      await save.recordLethalDeath(cause: 'x', lessonId: '1.1', rungId: '1.1/do/0', moduleFirstRungId: '1.1/learn');
      await save.markRungCleared('m1/gate');
      s = c.read(gameSaveProvider);
      expect(s.toolbox.chests, hasLength(1));
      expect(s.toolbox.firstClears, 1);
      // Four ordinary first clears: at least one chest.
      for (final id in ['1.1/do/0', '1.1/do/1', '1.2/do/0', '1.2/do/1']) {
        await save.markRungCleared(id);
      }
      s = c.read(gameSaveProvider);
      expect(s.toolbox.chests.where((x) => !x.gate), isNotEmpty);
      // Saved to disk and read back.
      final prefs = await SharedPreferences.getInstance();
      final back = GameSave.fromJson(jsonDecode(prefs.getString('game_save_v1')!) as Map<String, dynamic>);
      expect([for (final x in back.toolbox.chests) x.claimId], [for (final x in s.toolbox.chests) x.claimId]);
      expect(back.toolbox.chests.first.gate, isTrue);
      expect(back.toolbox.chests.first.tier, 'silver');
      expect(back.toolbox.sinceDrop, s.toolbox.sinceDrop);
      expect(back.toolbox.firstClears, 5);
      // Old saves load with no chests.
      expect(GameSave.fromJson({'points': 1}).toolbox.chests, isEmpty);
    });

    test('a chest opens once and leaves the ladder; old station claims are kept', () async {
      final (c, save) = await _boot();
      c.read(gameSaveProvider.notifier).state = c.read(gameSaveProvider).copyWith(giftsClaimed: ['station_gift@1.2/do/1']);
      await save.markRungCleared('m1/gate');
      final id = toolboxChestClaimId('m1/gate');
      final both = await Future.wait([
        save.openToolbox(id, rareOrBetter: false, coins: 15),
        save.openToolbox(id, rareOrBetter: false, coins: 15),
      ]);
      expect(both.where((b) => b).length, 1);
      final s = c.read(gameSaveProvider);
      expect(s.toolbox.chests, isEmpty);
      expect(s.points, 15);
      expect(s.giftsClaimed, containsAll(['station_gift@1.2/do/1', id]));
      expect(await save.openToolbox(id, rareOrBetter: true, coins: 50), isFalse);
      expect(c.read(gameSaveProvider).points, 15);
    });
  });

  group('quiz sources', () {
    const lessonQ = LessonQuizQuestion(questionText: 'পাঠের প্রশ্ন?', options: ['ক', 'খ'], correctIndex: 1);
    final save = GameSave.empty.copyWith(rungProgress: {'1.1/learn': 'cleared'});

    test('Supabase first; its answer is checked by the server (and awards nothing)', () async {
      final rpc = _FakeRpc();
      final local = _ListQuiz(const [lessonQ]);
      final chain = ToolboxQuizChain([SupabaseToolboxQuizSource(rpc: rpc.call), local]);
      final q = (await chain.next(save, math.Random(1)))!;
      expect(q.text, 'সার্ভারের প্রশ্ন?');
      expect(q.correctIndex, isNull);
      expect(local.asked, 0);
      final task = quizTask(q);
      expect(task.serverChecked, isTrue);
      final right = (await chain.check(q, 1))!;
      expect(right.correct, isTrue);
      expect(right.correctIndex, 1);
      final wrong = (await chain.check(q, 0))!;
      expect(wrong.correct, isFalse);
      expect(wrong.correctIndex, 1);
      // Time up: no choice, but the right one is shown.
      expect((await chain.check(q, null))!.correct, isFalse);
      expect(rpc.calls.where((f) => f == 'toolbox_quiz_check'), hasLength(3));
      // Server gone mid-way: no verdict (the tier stays).
      rpc.online = false;
      expect(await chain.check(q, 1), isNull);
    });

    test('offline or slow Supabase → cached passed-lesson quiz → no quiz task', () async {
      final local = _ListQuiz(const [lessonQ]);
      final offline = ToolboxQuizChain([SupabaseToolboxQuizSource(rpc: _FakeRpc(online: false).call), local]);
      final q = (await offline.next(save, math.Random(1)))!;
      expect(q.text, 'পাঠের প্রশ্ন?');
      expect(q.correctIndex, 1);
      expect((await offline.check(q, 1))!.correct, isTrue);

      final none = ToolboxQuizChain([SupabaseToolboxQuizSource(rpc: _FakeRpc(online: false).call), _ListQuiz(const [])]);
      final nothing = await none.next(save, math.Random(1));
      expect(nothing, isNull);
      for (var seed = 0; seed < 30; seed++) {
        final task = pickToolboxTask(
          save: save.copyWith(mistakes: [_ownMistake()]),
          known: knownMistakes,
          eyeChecks: TenSecChecks.all,
          quiz: nothing,
          rng: math.Random(seed),
        );
        expect(task!.kind, isNot(ToolboxTaskKind.quiz));
      }
      // No Supabase client in tests: the default source fails fast, quietly.
      expect(await SupabaseToolboxQuizSource().next(save, math.Random(1)), isNull);
    });

    testWidgets('a slow server times out to the next source', (t) async {
      await t.runAsync(() async {
        final chain = ToolboxQuizChain([
          SupabaseToolboxQuizSource(rpc: _FakeRpc(slow: true).call, timeout: const Duration(milliseconds: 50)),
          _ListQuiz(const [lessonQ]),
        ]);
        expect((await chain.next(save, math.Random(1)))!.text, 'পাঠের প্রশ্ন?');
      });
    });

    test('only passed lessons and won life skills feed the local quiz', () async {
      // Nothing passed, nothing won: no local question at all.
      expect(clearedLessons(GameSave.empty), isEmpty);
      expect(await const LifeSkillQuizSource().next(GameSave.empty, math.Random(1)), isNull);
      // A won life skill's questions join (answers ship with the app).
      final won = GameSave.empty.copyWith(toolbox: const ToolboxSave(lifeSkills: ['supp_10_3']));
      final pool = await const LifeSkillQuizSource().questionsFor(won);
      expect(pool, isNotEmpty);
      final q = (await const LifeSkillQuizSource().next(won, math.Random(2)))!;
      expect(q.correctIndex, isNotNull);
      expect(pool.map((p) => p.questionText), contains(q.text));
    });
  });

  group('life skill prizes', () {
    test('an Epic box sometimes holds a not-yet-won life skill; never a won one; boxes never repeat one', () {
      final rng = math.Random(11);
      var skills = 0;
      const t = ToolboxSave(lifeSkills: ['supp_10_1', 'supp_10_2']);
      for (var i = 0; i < 4000; i++) {
        final deal = dealToolbox(ChestTier.gold, rng, t);
        final ids = [for (final r in deal) ?r.lifeSkillId];
        expect(ids.toSet().length, ids.length);
        for (final r in deal) {
          if (r.prize == ToolboxPrize.lifeSkill) {
            skills++;
            expect(r.rarity, ToolboxRarity.epic);
            expect(t.lifeSkills, isNot(contains(r.lifeSkillId)));
            expect(kLifeSkillIds, contains(r.lifeSkillId));
          }
        }
      }
      // Gold: 22 % Epic × 25 % ≈ 5.5 % of boxes.
      expect(skills / 12000, closeTo(0.055, 0.015));
      // All won: no life-skill box at all.
      const all = ToolboxSave(lifeSkills: kLifeSkillIds);
      for (var i = 0; i < 500; i++) {
        expect(dealToolbox(ChestTier.gold, rng, all).where((r) => r.prize == ToolboxPrize.lifeSkill), isEmpty);
      }
    });

    test('the gate extra is always a new life skill; once all 13 are won it is ◆', () {
      final rng = math.Random(5);
      var t = const ToolboxSave();
      for (var i = 0; i < kLifeSkillIds.length; i++) {
        final extra = gateLifeSkillExtra(t, rng);
        expect(extra.prize, ToolboxPrize.lifeSkill);
        expect(t.lifeSkills, isNot(contains(extra.lifeSkillId)));
        t = t.copyWith(lifeSkills: [...t.lifeSkills, extra.lifeSkillId!]);
      }
      expect(t.lifeSkills.toSet(), kLifeSkillIds.toSet());
      final dup = gateLifeSkillExtra(t, rng);
      expect(dup.prize, ToolboxPrize.coins);
      expect(dup.coins, kToolboxRareCoins);
      // Never the same skill the pick itself just gave.
      const one = ToolboxSave(lifeSkills: ['supp_10_1']);
      for (var i = 0; i < 200; i++) {
        expect(gateLifeSkillExtra(one, rng, alsoWon: 'supp_10_2').lifeSkillId, isNot(anyOf('supp_10_1', 'supp_10_2')));
      }
      expect(gateLifeSkillExtra(const ToolboxSave(lifeSkills: ['a']), rng, alsoWon: 'b', all: const ['a', 'b']).prize, ToolboxPrize.coins);
    });

    test('openToolbox keeps won life skills once (a duplicate is not added twice)', () async {
      final (c, save) = await _boot();
      await save.openToolbox('chest@x', rareOrBetter: true, lifeSkills: ['supp_10_4']);
      await save.openToolbox('chest@y', rareOrBetter: true, lifeSkills: ['supp_10_4', 'supp_10_5']);
      expect(c.read(gameSaveProvider).toolbox.lifeSkills, ['supp_10_4', 'supp_10_5']);
      final back = GameSave.fromJson(jsonDecode(jsonEncode(c.read(gameSaveProvider).toJson())) as Map<String, dynamic>);
      expect(back.toolbox.lifeSkills, ['supp_10_4', 'supp_10_5']);
    });
  });

  group('ladder', () {
    ContentCatalog catalog() => ContentCatalog.fromJson(
          jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map<String, dynamic>,
        );

    Future<void> pumpLadder(WidgetTester t, GameSave save) async {
      final old = LessonQuizStore.instance;
      LessonQuizStore.instance = LessonQuizStore(
        httpGet: (_) async => throw const SocketException('offline'),
        cacheRoot: () async => throw const FileSystemException('none'),
      );
      addTearDown(() => LessonQuizStore.instance = old);
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      final pack = await DsPack.load();
      final engine = DutySlipEngine(pack, seed: 7);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            _seed(save),
            // The real catalog, parsed from the file (rootBundle decodes it off the test clock).
            contentCatalogProvider.overrideWith((ref) async => catalog()),
            trainingLadderProvider.overrideWith((ref) async => <TrainingModuleItem>[]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AdventureMap(engine: engine, onOpen: (_) {}, scrollOut: ValueNotifier<double>(0), muted: true),
            ),
          ),
        ),
      );
      final c = ProviderScope.containerOf(t.element(find.byType(AdventureMap)));
      expect(c.read(builtLadderProvider).hasValue, isTrue, reason: 'catalog loaded');
      for (var i = 0; i < 120; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }

    List<String> rungIds() {
      final cat = jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map<String, dynamic>;
      return [for (final r in cat['rungDefs'] as List) (r as Map)['id'] as String];
    }

    GameSave clearedTo(int n) => GameSave.empty.copyWith(
          rungProgress: {for (final id in rungIds().take(n)) id: 'cleared'},
        );

    /// Cleared up to rung [n] with a chest dropped by rung n-1 (it stands beside rung n).
    GameSave withChest(int n, {List<String> claimed = const []}) => clearedTo(n).copyWith(
          giftsClaimed: claimed,
          toolbox: ToolboxSave(chests: [PendingChest(rungId: rungIds()[n - 1])]),
        );

    testWidgets('a waiting chest opens the toolbox (keys off: no key, no key count)', (t) async {
      await pumpLadder(t, withChest(5));
      final chest = find.byKey(const ValueKey('toolbox-chest-5'));
      expect(chest, findsOneWidget);
      expect(find.descendant(of: chest, matching: find.byIcon(Icons.vpn_key_rounded)), findsNothing);
      await t.tap(chest);
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(LuckyToolboxOverlay), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('toolbox-close')));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(LuckyToolboxOverlay), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('keys on and none in hand: a short note, never the overlay', (t) async {
      ToolboxFlags.keysEnabled = true;
      addTearDown(() => ToolboxFlags.keysEnabled = false);
      await pumpLadder(t, withChest(5));
      final chest = find.byKey(const ValueKey('toolbox-chest-5'));
      expect(find.descendant(of: chest, matching: find.byIcon(Icons.vpn_key_rounded)), findsOneWidget);
      await t.tap(chest);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(LuckyToolboxOverlay), findsNothing);
      // The kinetic note animates word by word.
      expect(find.text(ToolboxLines.noKeyTitle.split(' ').last), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('an opened chest is gone from the ladder (never paid twice)', (t) async {
      final id = toolboxChestClaimId(rungIds()[4]);
      await pumpLadder(t, withChest(5, claimed: [id]));
      expect(find.byKey(const ValueKey('toolbox-chest-5')), findsNothing);
      await t.pump(const Duration(seconds: 5));
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('the ladder has no side stations: only waiting chests stand beside rungs', (t) async {
      // Old station claims stay in the save and change nothing.
      await pumpLadder(t, clearedTo(9).copyWith(giftsClaimed: ['station_gift@1.2/do/1', 'station_tips_1']));
      expect(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('toolbox-chest-')), findsNothing);
      final images = t.widgetList<Image>(find.byType(Image)).map((i) => i.image).whereType<AssetImage>().map((a) => a.assetName);
      for (final gone in ['prop_clock', 'prop_identify', 'prop_books', 'prop_tools', 'prop_ppe_', 'prop_chest']) {
        expect(images.where((n) => n.contains(gone)), isEmpty, reason: gone);
      }
      await t.pump(const Duration(seconds: 5));
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a first clear that drops a chest shows it beside the next rung, once, with a one-shot drop', (t) async {
      final ids = rungIds();
      final gate = ids.indexOf('m1/gate');
      await pumpLadder(t, GameSave.empty.copyWith(rungProgress: {for (final id in ids.take(gate)) id: 'cleared'}));
      final c = ProviderScope.containerOf(t.element(find.byType(AdventureMap)));
      await c.read(gameSaveProvider.notifier).markRungCleared('m1/gate');
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(c.read(gameSaveProvider).toolbox.chests.single.gate, isTrue);
      // The drop settles; the chest then waits still.
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(c.read(gameSaveProvider.notifier).lastChestDrop, isNull, reason: 'the drop played');
      await t.drag(find.byType(ListView), const Offset(0, 200));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final chest = find.byKey(ValueKey('toolbox-chest-${gate + 1}'));
      expect(chest, findsOneWidget);
      await t.tap(chest);
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final overlay = t.widget<LuckyToolboxOverlay>(find.byType(LuckyToolboxOverlay));
      expect(overlay.gateChest, isTrue);
      expect(overlay.startTier, ChestTier.silver);
      expect(overlay.claimId, toolboxChestClaimId('m1/gate'));
      await t.tap(find.byKey(const ValueKey('toolbox-close')));
      await t.pump(const Duration(milliseconds: 200));
      // Closed before the pick: the chest keeps waiting.
      expect(c.read(gameSaveProvider).toolbox.chests, hasLength(1));
      await t.pump(const Duration(seconds: 5));
      await t.pumpWidget(const SizedBox());
    });
  });
}

class _OverlayHarness extends StatefulWidget {
  const _OverlayHarness({required this.gate, required this.quiz});

  final bool gate;
  final ToolboxQuizSource quiz;

  @override
  State<_OverlayHarness> createState() => _OverlayHarnessState();
}

class _OverlayHarnessState extends State<_OverlayHarness> {
  var _open = true;

  @override
  Widget build(BuildContext context) => _open
      ? LuckyToolboxOverlay(
          claimId: 'station_gift@1.2/do/1',
          gateChest: widget.gate,
          muted: true,
          rng: _FirstRandom(),
          quizSource: widget.quiz,
          onClose: () => setState(() => _open = false),
        )
      : const SizedBox();
}

/// Reads bundled files from disk at once (rootBundle's real I/O would run off
/// the fake test clock).
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(File(key).readAsBytesSync());

  @override
  Future<String> loadString(String key, {bool cache = true}) async => File(key).readAsStringSync();
}

class _NoQuiz implements ToolboxQuizSource {
  const _NoQuiz();

  @override
  Future<ToolboxQuizQuestion?> next(GameSave save, math.Random rng) async => null;

  @override
  Future<ToolboxQuizVerdict?> check(ToolboxQuizQuestion q, int? choice) async => null;
}

/// A fixed list of questions (a stand-in for cached passed lessons).
class _ListQuiz implements ToolboxQuizSource {
  _ListQuiz(this.questions);

  final List<LessonQuizQuestion> questions;
  var asked = 0;

  @override
  Future<ToolboxQuizQuestion?> next(GameSave save, math.Random rng) async {
    asked++;
    return pickQuizQuestion(questions, rng);
  }

  @override
  Future<ToolboxQuizVerdict?> check(ToolboxQuizQuestion q, int? choice) async => localQuizVerdict(q, choice);
}

/// A fake Supabase: answers the two toolbox RPCs from memory (or fails).
class _FakeRpc {
  _FakeRpc({this.online = true, this.slow = false});

  bool online;
  final bool slow;
  final calls = <String>[];

  Future<Object?> call(String fn, Map<String, dynamic> params) async {
    calls.add(fn);
    if (slow) await Future<void>.delayed(const Duration(seconds: 10));
    if (!online) throw const SocketException('offline');
    if (fn == 'toolbox_quiz_question') {
      return {'id': 'q-1', 'text': 'সার্ভারের প্রশ্ন?', 'options': ['ক', 'খ', 'গ']};
    }
    if (fn == 'toolbox_quiz_check') {
      return {'correct': params['p_choice'] == 'খ', 'correct_choice': 'খ'};
    }
    return null;
  }
}

class _StrikeHost extends ConsumerStatefulWidget {
  const _StrikeHost();

  @override
  ConsumerState<_StrikeHost> createState() => _StrikeHostState();
}

class _StrikeHostState extends ConsumerState<_StrikeHost> with DoStrikeOut<_StrikeHost> {
  static const _m = DoMistake(key: 'test/slip', textBn: 'ছোট ভুল', art: 'assets/duty_slip/world3d/prop_shield.webp');

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('strikes $strikes'),
          ElevatedButton(
            key: const ValueKey('strike'),
            onPressed: () => setState(() => strike(_m)),
            child: const Text('slip'),
          ),
        ],
      );
}
