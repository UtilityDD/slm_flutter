// Module 5 lesson 5.6 picture board ("শর্ট সার্কিট এবং ওপেন সার্কিট ফল্ট: দুই
// ভিন্ন শত্রু", rung 5.6/learn, pack learn_5_6): its content follows the
// board's rules and the lesson's points, every picture exists and no colour
// or backdrop marks the safe card (in any hand the dealer can make), the
// rival's myth is the lesson's own, the board waits quietly once the first
// hand is dealt, a clean play (picks, reasons, the rival's myth) clears it,
// and a play with too many first-try misses fails below the pass line.
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
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_board_deal.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack56;
const _artDir = 'assets/game/art/m5_board56';
const _rung = '5.6/learn';

/// Has read lesson 5.6 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['5_6', '5.6']));
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
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
  });

  test('the lesson 5.6 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '5.6');
    // Registered by the director (learn_board_models.dart); until then null.
    expect(learnBoardPackFor('5.6'), same(learnBoardPack56));
    expect(pack.badgeBn, 'ফল্ট ফাইন্ডার');
    expect(pack.titleBn, 'শর্ট সার্কিট এবং ওপেন সার্কিট ফল্ট: দুই ভিন্ন শত্রু');
    expect(pack.slots.map((s) => s.id), ['short', 'open', 'fallen', 'single', 'hidden']);
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

  test('every on-screen string uses English digits, the house words and clean Bangla', () {
    final m = pack.myth;
    final lines = <String>[
      pack.titleBn, pack.badgeBn, pack.introBn, pack.earnedBn,
      for (final s in pack.slots) ...[
        s.promptBn,
        for (final o in s.options) ...[o.labelBn, o.rejectBn],
        for (final w in s.whyChips) w.textBn,
      ],
      m.tauntBn, m.rivalLineBn, m.exitBn, m.stingBn, m.flipStingBn, ...m.dangerHints,
      for (final w in m.whyChips) w.textBn,
    ];
    for (final l in lines) {
      expect(l, isNot(matches(RegExp('[০-৯]'))), reason: '"$l": English digits on screen');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        expect(l, isNot(contains(bad)), reason: '"$l": house word for "$bad"');
      }
      // The source text has stray Devanagari/Arabic words (ruling M5-13): none on screen
      // (the danda । is shared by Bangla and Devanagari).
      expect(l, isNot(matches(RegExp('[ऀ-ॣ०-ॿ؀-ۿ]'))), reason: '"$l": clean Bangla');
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
      final safes = <String>{};
      for (var run = 0; run < 16; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        expect(hand, hasLength(s.cards), reason: s.id);
        expect(hand.where((p) => p.correct), hasLength(1), reason: s.id);
        hands.add((hand.map((o) => o.id).toList()..sort()).join(','));
        safes.add(hand.firstWhere((p) => p.correct).id);
      }
      expect(hands.length, greaterThan(1), reason: '${s.id}: fresh deals');
      expect(safes.length, greaterThan(1), reason: '${s.id}: the safe picture changes between plays');
    }
    // Reason chips: one right, three different, fresh deals.
    for (final s in pack.slots) {
      final seen = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal('${s.id}/why', s.whyChips, count: s.whyCards);
        expect(hand.where((c) => c.correct), hasLength(1), reason: '${s.id} why');
        expect(hand.map((c) => c.id).toSet(), hasLength(s.whyCards), reason: '${s.id} why');
        seen.add((hand.map((c) => c.id).toList()..sort()).join(','));
      }
      expect(seen.length, greaterThan(1), reason: '${s.id} why: fresh deals');
    }
  });

  test('the lesson\'s points: short, open, the fallen wire, single-phasing, the hidden short', () {
    // Short: flash, wires touching, branch or bird across two wires; the traps are open circuits.
    expect(_safe('short'), ['slap', 'branch', 'bird']);
    expect(_reject('short', 'jumper'), contains('ওপেন সার্কিট'));
    expect(_reject('short', 'connector'), contains('কানেক্টর'));
    expect(_reject('short', 'pump'), contains('সিঙ্গেল-ফেজিং'));
    expect(_slot('short').whyChips.any((w) => w.correct && w.textBn.contains('রেজিস্ট্যান্স')), isTrue);
    // Open: the path broken, the power stops, no flash.
    expect(_safe('open'), ['jumper', 'connector', 'fuse']);
    expect(_reject('open', 'touch'), contains('শর্ট সার্কিট'));
    expect(_reject('open', 'burnt'), allOf(contains('পোড়া'), contains('শব্দ')));
    expect(_slot('open').whyChips.any((w) => w.correct && w.textBn.contains('শূন্য')), isTrue);
    // Fallen: always live (pro tip 1); dry wood is a semi-conductor; full voltage across the gap.
    expect(_safe('fallen'), ['child', 'cyclist']);
    expect(_reject('fallen', 'bare'), contains('লাইভ'));
    expect(_reject('fallen', 'bamboo'), contains('অর্ধ-পরিবাহী'));
    expect(_reject('fallen', 'join'), allOf(contains('সিস্টেম ভোল্টেজ'), contains('শক')));
    expect(_reject('fallen', 'fence'), contains('বেড়া'));
    // No keep-away distance on this board (it comes from lesson 5.2).
    for (final o in _slot('fallen').options) {
      expect('${o.labelBn} ${o.rejectBn}', isNot(contains('মিটার')), reason: o.id);
    }
    // Single-phasing: one of three phases open; the motor groans or stalls.
    expect(_safe('single'), ['onewire', 'onejumper']);
    expect(_reject('single', 'allopen'), contains('একটি ফেজ'));
    expect(_slot('single').whyChips.any((w) => w.correct && w.textBn.contains('মোটর')), isTrue);
    // Hidden short (high resistance): the fuse does not operate; a fire risk.
    expect(_safe('hidden'), ['branch', 'awning']);
    expect(_reject('hidden', 'bigflash'), contains('সুরক্ষা কাজ করেছে'));
    expect(_slot('hidden').whyChips.any((w) => w.correct && w.textBn.contains('আগুন')), isTrue);
    expect(pack.earnedBn, allOf(contains('শর্ট'), contains('ওপেন'), contains('লাইভ')));
  });

  test('every picture exists (vector scenes from tool/m5_board56_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m5_board56 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .map((n) => '$_artDir/$n')
        .toSet();
    expect(onDisk, used, reason: 'no unused art, no missing art, nothing else in the bundled folder');
  });

  // The playbook (section 4): the right option must not stand out. A round
  // shares one backdrop and one stage; every gradient and colour drawn on a
  // safe card must also be drawn on at least one trap.
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

  // Every hand the dealer can make (one safe card + any cards-1 traps;
  // afterMiss hands are of the same shape).
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

  // Every person's head is one skin-coloured circle of radius 7 (the figure of
  // tool/m5_board56_art.py). A safe card must never be the only card in its
  // hand with that many people (both fallen-wire safe cards show two).
  test('in every possible hand, a trap shows as many people as the safe card', () {
    int people(String asset) => 'r="7" fill="#A86E48"'.allMatches(File(asset).readAsStringSync()).length;
    for (final s in pack.slots) {
      final traps = s.options.where((o) => !o.correct).toList();
      final counts = {for (final o in s.options) o.id: people(o.asset)};
      for (final safe in s.options.where((o) => o.correct)) {
        // A hand leaves out (traps - (cards - 1)) traps; it must still hold one with the safe card's count.
        final matching = traps.where((t) => counts[t.id] == counts[safe.id]).length;
        expect(matching, greaterThan(traps.length - (s.cards - 1)),
            reason: '${s.id}/${safe.id} (${counts[safe.id]} people): some hand would hold no trap with as many');
      }
    }
    expect(people('$_artDir/fallen_child.svg'), 2, reason: 'the counter sees the trainee and the child');
  });

  test('the careless lineman says the lesson\'s second myth, word for word', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'একটি ওপেন সার্কিটে কোনো বিপদ নেই কারণ বিদ্যুৎ তো বন্ধই আছে।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the full system voltage stands across an open circuit\'s two ends');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('সিস্টেম ভোল্টেজ')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // The tags point at the danger as questions; they never state the rebuttal.
    for (final h in m.dangerHints) {
      expect(h, endsWith('?'), reason: '"$h": a prompt, not the answer');
    }
    // Both questions are yes/no about his claim, and neither calls him names
    // (the kit's default flip line is an either/or question that gives it away).
    expect(m.stingBn, endsWith('বিশ্বাস করেন?'));
    expect(m.flipStingBn, endsWith('সেটা কি ভুল?'));
    expect(m.flipStingBn, isNot(contains('আলসেমি')));
    // His parting line is already recorded; the new ones wait for the director's voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M5Board56Lines.toRecord, containsAll([m.tauntBn, m.rivalLineBn]));
    for (final l in M5Board56Lines.toRecord) {
      // Until recorded he is silent (never the guide's device voice); once recorded the clip must exist.
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  group('board on screen', () {
    setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('board waits quietly at the first question (${reduce ? 'reduce' : 'anim'})', (tester) async {
        await _open(tester, reduce: reduce);
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
        await _close(tester);
      });
    }
  });

  group('a whole play', () {
    // The app's Bangla font, so text wraps on screen as it does on a phone
    // (the test font draws every Bangla code point a full em wide, which
    // overflows the rival's bubble lane).
    setUpAll(() async {
      final loader = FontLoader('Noto Sans Bengali');
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        final bytes = File('assets/fonts/NotoSansBengali-$w.ttf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    });

    testWidgets('clean play: every pick and reason right, the rival refused — the rung is cleared at 100', (tester) async {
      await _open(tester);
      for (final s in pack.slots) {
        final safe = {for (final o in s.options) if (o.correct) o.id};
        await _choose(tester, 'pick', safe.contains);
        final right = {for (final w in s.whyChips) if (w.correct) w.id};
        await _choose(tester, 'why', right.contains);
      }

      // The careless lineman storms in and says the lesson's myth; the
      // question waits until he has spoken and gone.
      await _pumpUntil(tester, () => find.text(M5Board56Lines.rivalMyth).evaluate().isNotEmpty, 'the rival says the myth');
      expect(find.text('হ্যাঁ'), findsNothing, reason: 'no answer while he speaks');
      expect(find.text('না'), findsNothing, reason: 'no answer while he speaks');
      await _refuseRival(tester);
      final mythRight = {for (final w in pack.myth.whyChips) if (w.correct) w.id};
      await _choose(tester, 'why', mythRight.contains);

      final save = _save(tester);
      await _pumpUntil(tester, () => save().rungProgress[_rung] == 'cleared', 'the clear is saved');
      expect(save().bestMarkByRung[_rung], 100, reason: 'no first-try miss');
      expect(find.byType(LevelFailPanel), findsNothing);
      // Let the award finish (bonus, score commit, best time) before leaving.
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      await _close(tester);
    });

    testWidgets('a play with a wrong first pick in every round fails below the pass line', (tester) async {
      await _open(tester);
      for (final s in pack.slots) {
        final traps = {for (final o in s.options) if (!o.correct) o.id};
        await _choose(tester, 'pick', traps.contains);
        // The trap's reason shows in the guide's bubble; the hand is dealt again.
        final safe = {for (final o in s.options) if (o.correct) o.id};
        await _choose(tester, 'pick', safe.contains);
        final right = {for (final w in s.whyChips) if (w.correct) w.id};
        await _choose(tester, 'why', right.contains);
      }
      await _pumpUntil(tester, () => find.text(M5Board56Lines.rivalMyth).evaluate().isNotEmpty, 'the rival says the myth');
      await _refuseRival(tester);
      final mythRight = {for (final w in pack.myth.whyChips) if (w.correct) w.id};
      await _choose(tester, 'why', mythRight.contains);

      // 5 of 12 questions missed on the first try: 58 % < the pass mark.
      await _pumpUntil(tester, () => find.byType(LevelFailPanel).evaluate().isNotEmpty, 'the fail panel');
      final save = _save(tester);
      expect(save().rungProgress[_rung], isNot('cleared'));
      expect(save().bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(tester.takeException(), isNull);
      await _close(tester);
    });
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

List<String> _safe(String id) => [for (final o in _slot(id).options) if (o.correct) o.id];

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;

Future<void> _open(WidgetTester tester, {bool reduce = false}) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2.0;
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith(_TestAuth.new)],
    child: MaterialApp(
      // Plain ripples: the sparkle splash needs a compiled shader that a
      // shared test build folder does not always hold.
      theme: SlmTheme.night().copyWith(splashFactory: InkRipple.splashFactory),
      home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.6', ladderIndex: 140, pack: pack, muted: true),
    ),
  ));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  tester.view.reset();
}

GameSave Function() _save(WidgetTester tester) {
  final container = ProviderScope.containerOf(tester.element(find.byType(LearnBoardRunnerPage)));
  return () => container.read(gameSaveProvider);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done, String what, {int max = 600}) async {
  for (var i = 0; i < max; i++) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  final keys = find.byWidgetPredicate((w) => w.key is ValueKey<String>).evaluate().map(_keyOf).toList();
  final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').where((t) => t.isNotEmpty).toList();
  fail('timed out waiting for $what (keys: $keys; texts: $texts)');
}

String _keyOf(Element e) => (e.widget.key! as ValueKey<String>).value;
int _waveOf(Element e) => int.parse(_keyOf(e).split('-')[1]);
String _idOf(Element e) => _keyOf(e).split('-').skip(2).join('-');

List<Element> _dealt(String kind) => find
    .byWidgetPredicate((w) =>
        w.runtimeType.toString() == '_AnimatedChoiceCard' &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('$kind-'))
    .evaluate()
    .toList();

int _topWave() {
  final all = [..._dealt('pick'), ..._dealt('why')];
  return all.isEmpty ? -1 : all.map(_waveOf).reduce(math.max);
}

/// The newest hand of [kind] ('pick' or 'why'): an outgoing hand may still be
/// fading in the stage switcher.
List<Element> _newest(String kind) {
  final els = _dealt(kind);
  if (els.isEmpty) return const [];
  final top = els.map(_waveOf).reduce(math.max);
  return els.where((e) => _waveOf(e) == top && _waveOf(e) == _topWave()).toList();
}

/// Taps a card of the newest hand whose id [want]s, and waits until the board
/// deals its next hand (a redeal after a miss, the reason deck, the next
/// round) or leaves the cards behind (the rival's scene). A tap during a scripted moment is ignored by the board, so it is
/// tried again.
Future<void> _choose(WidgetTester tester, String kind, bool Function(String id) want) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    await _pumpUntil(tester, () => _newest(kind).any((e) => want(_idOf(e))), 'a $kind card');
    // Let the hand land before touching it.
    await tester.pump(const Duration(milliseconds: 600));
    final hand = _newest(kind).where((e) => want(_idOf(e))).toList();
    if (hand.isEmpty) continue;
    final before = _topWave();
    final card = hand.first.widget;
    if (!await tryPickBoardCard(tester, find.byWidget(card))) continue;
    // Taken: a new hand is dealt, or the board moves on (the rival's scene).
    final tapped = find.byWidget(card);
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (_topWave() > before || tapped.evaluate().isEmpty) return;
    }
  }
  fail('the board never took a $kind tap');
}

/// Answers the myth question against him: "বিশ্বাস করেন?" → না, "সেটা কি ভুল?" → হ্যাঁ.
Future<void> _refuseRival(WidgetTester tester) async {
  await _pumpUntil(
    tester,
    () => find.text('বিশ্বাস করেন?').evaluate().isNotEmpty || find.text('সেটা কি ভুল?').evaluate().isNotEmpty,
    'the myth question',
  );
  await tester.pump(const Duration(milliseconds: 800));
  final flipped = find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  final before = _topWave();
  await tester.tap(find.text(flipped ? 'হ্যাঁ' : 'না').last, warnIfMissed: false);
  await tester.pump();
  await _pumpUntil(tester, () => _topWave() > before, 'the myth reason deck');
}
