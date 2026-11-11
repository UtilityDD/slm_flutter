// Ladder step 28 — the lesson 1.10 picture board ("১০ সেকেন্ডের মেন্টাল চেকলিস্ট"):
// its content follows the board's rules and the lesson's points, every picture exists
// and no colour or backdrop marks the safe card (in any hand the dealer can make),
// the rival's myth is the lesson's own and in his recorded voice, and the board waits
// quietly once the first hand is dealt.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/game/learn_board_deal.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';

const pack = learnBoardPack110;
const _artDir = 'assets/game/art/scan_board';

/// Has read lesson 1.10 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['1_10', '1.10']));
}

void _muteAudio() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> ok(MethodCall _) async => 1;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), ok);
  }
}

var _rebuilds = 0;

Finder get _cards => find.byWidgetPredicate((w) => w.runtimeType.toString() == '_AnimatedChoiceCard');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(LearnDealer.resetMemory);

  test('step 28 is the lesson 1.10 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '1.10');
    expect(learnBoardPackFor('1.10'), same(learnBoardPack110), reason: 'the ladder opens this board for step 28');
    expect(pack.badgeBn, 'সুরক্ষা কবচ');
    expect(pack.slots.map((s) => s.id), ['ppe', 'harness_tool', 'ptw_mind', 'pole_distance', 'hazard_rescue']);
    expect(pack.slots.length, inInclusiveRange(4, 6));
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
      expect(s.promptBn, isNot('সঠিক জিনিস বেছে নিন'), reason: '${s.id}: specific prompt');
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
  });

  test('every round: 4–6 pictures, safe ones and enough traps, each trap says why', () {
    for (final s in pack.slots) {
      expect(s.options.length, inInclusiveRange(4, 6), reason: s.id);
      final safe = s.options.where((o) => o.correct).length;
      final traps = s.options.where((o) => !o.correct).length;
      expect(safe, greaterThanOrEqualTo(2), reason: '${s.id}: two pictures of the safe act, so its look cannot be learnt');
      expect(traps, greaterThanOrEqualTo(s.cards - 1), reason: '${s.id}: enough traps for a hand');
      expect(s.options.map((o) => o.id).toSet().length, s.options.length, reason: '${s.id}: unique ids');
      expect(s.options.map((o) => o.asset).toSet().length, s.options.length, reason: '${s.id}: one picture per card');
      for (final o in s.options) {
        expect(o.scene, isTrue, reason: '${s.id}/${o.id}: drawn scene, edge to edge');
        expect(o.labelBn, isNotEmpty, reason: '${s.id}/${o.id}: a name for the tapped card');
        if (!o.correct) expect(o.rejectBn, isNotEmpty, reason: '${s.id}/${o.id}: a trap says why');
      }
    }
  });

  test('every on-screen string uses English digits and the house words', () {
    final m = pack.myth;
    final lines = <String>[
      pack.titleBn, pack.badgeBn, pack.introBn, pack.earnedBn,
      for (final s in pack.slots) ...[
        s.promptBn,
        for (final o in s.options) ...[o.labelBn, o.rejectBn],
        for (final w in s.whyChips) w.textBn,
      ],
      m.tauntBn, m.rivalLineBn, m.exitBn, m.stingBn, ...m.dangerHints,
      for (final w in m.whyChips) w.textBn,
    ];
    for (final l in lines) {
      expect(l, isNot(matches(RegExp('[০-৯]'))), reason: '"$l": English digits on screen');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        expect(l, isNot(contains(bad)), reason: '"$l": house word for "$bad"');
      }
    }
  });

  test('reason decks: a library of right and wrong, all about the same length', () {
    for (final s in pack.slots) {
      final right = [for (final w in s.whyChips) if (w.correct) w.textBn];
      final wrong = [for (final w in s.whyChips) if (!w.correct) w.textBn];
      expectLibrary('${s.id} why', right, wrong);
      expectSameLength('${s.id} why', [...right, ...wrong]);
      expect(s.whyChips.map((w) => w.id).toSet().length, s.whyChips.length, reason: '${s.id}: unique chip ids');
    }
    final m = pack.myth;
    final right = [for (final w in m.whyChips) if (w.correct) w.textBn];
    final wrong = [for (final w in m.whyChips) if (!w.correct) w.textBn];
    expectLibrary('myth why', right, wrong);
    expectSameLength('myth why', [...right, ...wrong]);
  });

  test('a dealt hand has exactly one safe picture, and plays differ', () {
    final d = LearnDealer(math.Random(7));
    for (final s in pack.slots) {
      final hands = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        expect(hand, hasLength(s.cards), reason: s.id);
        expect(hand.where((p) => p.correct), hasLength(1), reason: s.id);
        hands.add((hand.map((o) => o.id).toList()..sort()).join(','));
      }
      expect(hands.length, greaterThan(1), reason: '${s.id}: fresh deals');
    }
  });

  test('the lesson\'s points: personal 5s, harness & tools, PTW & mind, pole & Lakshman Rekha, hazards & rescue', () {
    // PPE: chin strap, boot sole nail, full check
    expect(_reject('ppe', 'unstrapped'), contains('স্ট্র্যাপ'));
    expect(_reject('ppe', 'nail_sole'), contains('পেরেক'));
    expect(_reject('ppe', 'dirty_cut'), contains('আর্ক ফ্ল্যাশ'));
    expect(_reject('ppe', 'no_check'), contains('5 সেকেন্ড'));
    // Harness & Tools: snug 4 fingers, tool pouch vs dangling chest, hand climb
    expect(_reject('harness_tool', 'harness_loose_chest'), contains('বুকের স্ট্র্যাপ'));
    expect(_reject('harness_tool', 'tool_hand_climb'), contains('টুলস'));
    expect(_reject('harness_tool', 'tool_overload'), contains('ভারী টুলস'));
    expect(_reject('harness_tool', 'harness_expired'), contains('মেয়াদ'));
    expect(_slot('harness_tool').whyChips.any((w) => w.correct && w.textBn.contains('4 আঙুল')), isTrue);
    // PTW & Mind: written permit, calm focus vs phone, rushing, exhausted
    expect(_reject('ptw_mind', 'ptw_verbal_phone'), contains('ফোনের কথায়'));
    expect(_reject('ptw_mind', 'mind_rushed'), contains('তাড়াহুড়ো'));
    expect(_reject('ptw_mind', 'mind_tired'), contains('ক্লান্ত'));
    expect(_reject('ptw_mind', 'ptw_no_read'), contains('ফিডার'));
    // Pole & Clearance: sound test, Lakshman Rekha, lean, rust
    expect(_reject('pole_distance', 'pole_hug_lean'), contains('গোড়ায় ফাটল'));
    expect(_reject('pole_distance', 'clearance_inside'), contains('লক্ষ্মণ রেখা'));
    expect(_reject('pole_distance', 'pole_rusted_base'), contains('জং'));
    expect(_slot('pole_distance').whyChips.any((w) => w.correct && w.textBn.contains('সাউন্ড টেস্ট')), isTrue);
    // Hazards & Rescue: escape route, traffic cones, beehive, storm
    expect(_reject('hazard_rescue', 'hazard_beehive'), contains('মৌমাছি'));
    expect(_reject('hazard_rescue', 'hazard_traffic'), contains('ট্র্যাফিক'));
    expect(_reject('hazard_rescue', 'hazard_storm_sky'), contains('রেড লাইন'));
    expect(_reject('hazard_rescue', 'rescue_blocked'), contains('রেসকিউ'));
    expect(_slot('hazard_rescue').whyChips.any((w) => w.correct && w.textBn.contains('পালানোর ফাঁকা পথ')), isTrue);
  });

  test('every picture exists (vector scenes from tool/scan_board_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/'));
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test("every SVG in the scan_board folder is a card on the board", () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.svg'))
        .map((n) => '$_artDir/$n')
        .toSet();
    expect(onDisk, used, reason: 'no unused art and no missing art');
  });

  test('no colour or backdrop gives the safe card away', () {
    final used = RegExp(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b');
    Set<String> tokens(String asset) {
      final svg = File(asset).readAsStringSync();
      expect(svg, isNot(contains('<text')), reason: '$asset: no words in the art');
      return used.allMatches(svg.split('</defs>').last).map((m) => m.group(0)!).toSet();
    }

    for (final s in pack.slots) {
      final safe = <String>{}, traps = <String>{};
      for (final o in s.options) {
        (o.correct ? safe : traps).addAll(tokens(o.asset));
      }
      expect(safe.difference(traps), isEmpty, reason: '${s.id}: drawn only on safe cards');
    }
  });

  test('in every possible hand, the safe card\'s backdrop and colours are on a trap too', () {
    final used = RegExp(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b');
    final backdrop = RegExp(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"');
    final svgs = <String, String>{};
    String body(String asset) => svgs.putIfAbsent(asset, () => File(asset).readAsStringSync());
    Set<String> tokens(String asset) =>
        used.allMatches(body(asset).split('</defs>').last).map((m) => m.group(0)!).toSet();
    String back(String asset) {
      final m = backdrop.firstMatch(body(asset));
      expect(m, isNotNull, reason: '$asset: a full-card backdrop');
      return m!.group(1)!;
    }

    Iterable<List<T>> combos<T>(List<T> xs, int k) sync* {
      if (k == 0) {
        yield [];
        return;
      }
      for (var i = 0; i <= xs.length - k; i++) {
        for (final rest in combos(xs.sublist(i + 1), k - 1)) {
          yield [xs[i], ...rest];
        }
      }
    }

    for (final s in pack.slots) {
      final traps = s.options.where((o) => !o.correct).toList();
      var hands = 0;
      for (final safe in s.options.where((o) => o.correct)) {
        for (final hand in combos(traps, s.cards - 1)) {
          hands++;
          final ids = '${s.id}: ${safe.id} with ${hand.map((o) => o.id).join(', ')}';
          expect(hand.map((o) => back(o.asset)), contains(back(safe.asset)), reason: '$ids — the safe card alone on its backdrop');
          final trapTokens = {for (final o in hand) ...tokens(o.asset)};
          expect(tokens(safe.asset).difference(trapTokens), isEmpty, reason: '$ids — drawn only on the safe card');
        }
      }
      expect(hands, greaterThan(0), reason: s.id);
    }
  });

  test('the careless lineman says the lesson\'s myth in his own recorded voice', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'আমি 20 বছর ধরে এই কাজ করছি, আমার এসব চেকলিস্টের দরকার নেই। সবকিছু আমার মাথায় আছে।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'experience never replaces the checklist');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('চেকলিস্ট')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    for (final line in [m.tauntBn, m.rivalLineBn, m.exitBn, ...ScanBoardLines.recorded]) {
      final clip = LearnVoice.resolve(line, rival: true);
      expect(clip, isNotNull, reason: 'rival clip for "$line"');
      expect(File('assets/$clip').lengthSync(), greaterThan(4000), reason: '$clip is a real recording');
    }
  });

  group('board on screen', () {
    setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('board waits quietly at the first question (${reduce ? 'reduce' : 'anim'})', (tester) async {
        tester.view.physicalSize = const Size(720, 1600);
        tester.view.devicePixelRatio = 2.0;
        tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(ProviderScope(
          overrides: [authProvider.overrideWith(_TestAuth.new)],
          child: MaterialApp(
            theme: SlmTheme.night(),
            home: const LearnBoardRunnerPage(rungId: '1.10/learn', lessonId: '1.10', ladderIndex: 27, pack: pack, muted: true),
          ),
        ));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final day = lessonDays[pack.lessonId];
        if (day != null) expect(find.text('দিন ${day.day}'), findsOneWidget, reason: 'a first play opens on the day card');
        for (var i = 0; i < 160; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text(pack.slots.first.promptBn), findsWidgets, reason: 'the guide asks the round\'s own question');
        _rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        final perSec = _rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (tester.binding.hasScheduledFrame) frames++;
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(tester.takeException(), isNull);
        expect(_cards, findsNWidgets(pack.slots.first.cards), reason: 'the first hand is dealt');
        expect(perSec, lessThan(20), reason: 'nothing may rebuild every frame while the player thinks');
        expect(frames, lessThan(12), reason: 'no 60 fps loop while waiting for an answer');
        for (final o in pack.slots.first.options) {
          expect(find.text(o.labelBn), findsNothing, reason: '"${o.labelBn}" shown before any tap');
        }

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        tester.view.reset();
      });
    }

    // Design 2026-11-11: wrong picks shake + redeal + speak reject — no inspect zoom modal.
    testWidgets('tapping a wrong card redeals without an inspect zoom modal', (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: [authProvider.overrideWith(_TestAuth.new)],
        child: MaterialApp(
          theme: SlmTheme.night(),
          home: const LearnBoardRunnerPage(rungId: '1.10/learn', lessonId: '1.10', ladderIndex: 27, pack: pack, muted: true),
        ),
      ));
      for (var i = 0; i < 165; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(_cards, findsNWidgets(pack.slots.first.cards));
      await tester.tap(_cards.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // No inspect zoom sheet (wrong = redeal + speak; right = celebrate / why).
      expect(find.text('বুঝেছি, আবার চেষ্টা করি'), findsNothing);
      expect(find.text('ভুল নির্বাচন · বিপদের ঝুঁকি'), findsNothing);
      expect(find.text('সঠিক নির্বাচন! · নিরাপদ পদক্ষেপ'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      tester.view.reset();
    });
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;

