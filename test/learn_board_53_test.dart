// Module 5 lesson 5.3 picture board ("সাধারণ ফল্ট: অপরাধীদের প্যারেড",
// rung 5.3/learn, pack learn_5_3): its content follows the board's rules and
// the lesson's points, every picture exists and no colour or backdrop marks the
// safe card in any hand the dealer can make (counting only shapes that can be
// seen), the rival's myth is the lesson's own, his new lines are listed for
// recording, the board waits quietly once the first hand is dealt, a full clean
// play passes (pictures, reasons, the rival and the myth reasons), the believe
// buttons wait until he has finished, three misses in a row bring the lesson
// card, a play with a miss on every picture fails, and the hint hand sweeps
// over the cards without pressing one.
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
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_board_deal.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/learn_feedback_lines.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack53;
const _artDir = 'assets/game/art/m5_board53';
const _rung = '5.3/learn';

/// Has read lesson 5.3 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['5_3', '5.3']));
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
    SpokenOnce.resetForTest();
  });

  test('the lesson 5.3 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '5.3');
    // Registered by the director (learn_board_models.dart); until then null.
    expect(learnBoardPackFor('5.3'), same(learnBoardPack53));
    expect(pack.badgeBn, 'ফল্ট ফাইন্ডার');
    expect(pack.titleBn, 'সাধারণ ফল্ট: অপরাধীদের প্যারেড');
    expect(pack.slots.map((s) => s.id), ['type', 'branch', 'insulator', 'clamp', 'evidence']);
    expect(pack.slots.length, 5, reason: 'ruling M5-11: boards trimmed to 5 rounds');
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
      expect(s.promptBn, isNot('সঠিক জিনিস বেছে নিন'), reason: '${s.id}: specific prompt');
      // One hand holds one safe card, so the prompt asks for one picture.
      expect(s.promptBn, isNot(contains('গুলো')), reason: '${s.id}: asks for one card, not several');
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
      m.tauntBn, m.rivalLineBn, m.exitBn, m.stingBn, m.flipStingBn, ...m.dangerHints,
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

  test('a dealt hand has exactly one safe picture and every trap, and plays differ', () {
    final d = LearnDealer(math.Random(7));
    for (final s in pack.slots) {
      final hands = <String>{};
      final safeSeen = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        expect(hand, hasLength(s.cards), reason: s.id);
        expect(hand.where((p) => p.correct), hasLength(1), reason: s.id);
        safeSeen.add(hand.firstWhere((p) => p.correct).id);
        hands.add((hand.map((o) => o.id).toList()..sort()).join(','));
      }
      expect(hands.length, greaterThan(1), reason: '${s.id}: fresh deals');
      expect(safeSeen, {for (final o in s.options) if (o.correct) o.id}, reason: '${s.id}: every safe picture comes round');
    }
    // A miss swaps in a different picture of the safe act.
    final s = pack.slots.first;
    final hand = d.deal(s.id, s.options, count: s.cards);
    final trap = hand.firstWhere((o) => !o.correct);
    final next = d.afterMiss(hand, trap, s.options, {for (final o in hand) o.id});
    expect(next.where((o) => o.correct).single.id, isNot(hand.firstWhere((o) => o.correct).id));
  });

  test('the lesson\'s points: fault type, branch removal, insulator, hotspot, evidence', () {
    // Type: two or three wires at once = phase-to-phase; ground = phase-to-earth; insulator = earth; snapped = open.
    expect(_safeIds('type'), {'two', 'three'});
    expect(_reject('type', 'ground'), contains('ফেজ-টু-আর্থ'));
    expect(_reject('type', 'track'), contains('আর্থ ফল্ট'));
    expect(_reject('type', 'snapped'), contains('ওপেন সার্কিট'));
    expect(_slot('type').whyChips.any((w) => w.correct && w.textBn.contains('দুটি বা তিনটি')), isTrue);
    // Branch: plan first (very risky), forest department / special team, then check conductor, insulators, pole.
    expect(_safeIds('branch'), {'plan', 'forest', 'check'});
    expect(_reject('branch', 'yank'), allOf(contains('ঝুঁকিপূর্ণ'), contains('পরিকল্পনা')));
    expect(_reject('branch', 'charge'), allOf(contains('কন্ডাক্টর'), contains('ইনসুলেটর'), contains('পোলের')));
    expect(_reject('branch', 'mark'), contains('আঘাতের চিহ্ন'));
    expect(_slot('branch').whyChips.any((w) => w.correct && w.textBn.contains('বন দপ্তর')), isTrue);
    // Insulator: replace by the rule, cross-arm first; a carbon track flashes over again.
    expect(_safeIds('insulator'), {'swap', 'arm'});
    expect(_reject('insulator', 'tape'), contains('নিয়ম অনুযায়ী বদলাতে'));
    expect(_reject('insulator', 'wipe'), allOf(contains('কার্বন ট্র্যাক'), contains('ফ্ল্যাশওভার')));
    expect(_reject('insulator', 'splitarm'), contains('ক্রস-আর্ম'));
    // Hotspot: new connector, check for softness, cut the damaged length away; joint snapped wire by the rule.
    expect(_safeIds('clamp'), {'fresh', 'soft', 'cut'});
    expect(_reject('clamp', 'retight'), contains('কানেক্টর বদলে'));
    expect(_reject('clamp', 'blackend'), allOf(contains('নরম ও ভঙ্গুর'), contains('কেটে বাদ')));
    expect(_reject('clamp', 'twist'), contains('জয়েন্ট'));
    // Ruling M5-15a: shown as discolouration and softness, never a bend-test claim.
    for (final o in _slot('clamp').options) {
      expect(o.labelBn, isNot(contains('বাঁকি')), reason: 'no bend-test claim');
    }
    // Evidence: burnt bird + blood, burst LA + hanging earth, metal manja across two wires.
    expect(_safeIds('evidence'), {'bird', 'la', 'manja'});
    expect(_reject('evidence', 'livebird'), allOf(contains('পোড়া পাখি'), contains('রক্তের দাগ')));
    expect(_reject('evidence', 'intactla'), allOf(contains('LA'), contains('আর্থিং')));
    expect(_reject('evidence', 'farkite'), contains('ধাতব মাঞ্জা'));
    expect(pack.earnedBn, allOf(contains('সূত্র'), contains('ক্ষতিগ্রস্ত')));
  });

  test('every picture exists (vector scenes from tool/m5_board53_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m5_board53 folder is a card on the board', () {
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

  test('the fairness check counts only what can be seen', () {
    const fake = '<svg viewBox="0 0 200 220"><defs><rect width="9" height="9" fill="#ABCDEF"/></defs>'
        '<rect width="0" height="0" fill="#123456"/>'
        '<g opacity="0"><rect width="4" height="4" fill="#111111"/></g>'
        '<g transform="translate(10 10) scale(0)"><rect width="40" height="40" fill="#444444"/></g>'
        '<rect x="300" y="10" width="20" height="20" fill="#555555"/>'
        '<rect width="4" height="4" fill="#445566" fill-opacity="0"/>'
        '<g fill="#696969"><rect x="20" y="20" width="4" height="4"/></g>'
        '<rect width="4" height="4" fill="#778899"/></svg>';
    expect(_visibleTokens(fake), {'#696969', '#778899'});
  });

  test('the cards use no paint the fairness check cannot follow, and no words', () {
    for (final f in Directory(_artDir).listSync().whereType<File>().where((f) => f.path.endsWith('.svg'))) {
      final svg = f.readAsStringSync();
      final clips = RegExp(r'clip-path="([^"]*)"').allMatches(svg).map((m) => m.group(1)).toSet()..remove('url(#card)');
      expect(clips, isEmpty, reason: '${f.path}: only the card\'s own clip');
      expect(RegExp(r'\b(mask|filter)="|<use\b|<image\b|<foreignObject\b').hasMatch(svg), isFalse,
          reason: '${f.path}: no mask, filter, reused shape or image');
      expect(svg, isNot(contains('<text')), reason: '${f.path}: no words in the art');
      expect(svg, isNot(contains('Glow')), reason: '${f.path}: no highlight glow');
    }
  });

  // The step-13 review: a round-wide check misses a hand where the safe card
  // is the only one on its backdrop or the only one with a colour. So go
  // through EVERY hand the dealer can make (one safe card + any cards-1 traps).
  test('in every possible hand, the safe card\'s backdrop and colours are on a trap too', () {
    final backdrop = RegExp(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"');
    final svgs = <String, String>{};
    String body(String asset) => svgs.putIfAbsent(asset, () => File(asset).readAsStringSync());
    Set<String> tokens(String asset) => _visibleTokens(body(asset));
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

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'ইনসুলেটরটা তো শুধু একটু কালো হয়েছে, ওটা পরিষ্কার করে দিলেই আবার চলবে।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'a carbon track flashes over again — replace the insulator');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('কার্বন ট্র্যাক')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('ফ্ল্যাশওভার')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // The sting and its flipped twin are both yes/no questions about his claim.
    expect(m.stingBn, contains('বিশ্বাস করেন?'));
    expect(m.flipStingBn, contains('ভুল?'));
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M5Board53Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final line in [m.tauntBn, m.rivalLineBn, m.exitBn]) {
      expect(LearnVoice.resolve(line, rival: true) != null || M5Board53Lines.toRecord.contains(line), isTrue,
          reason: '"$line": recorded, or listed for the voice session');
    }
  });

  group('board on screen', () {
    // The real Bangla font, so the rival's and the guide's bubbles measure as
    // on a phone (the test font draws every Bangla code point a full em wide).
    // Any overflow left then is real and fails the test.
    setUpAll(() async {
      final loader = FontLoader('Noto Sans Bengali');
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        final bytes = File('assets/fonts/NotoSansBengali-$w.ttf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    });
    setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
    tearDown(() {
      debugOnRebuildDirtyWidget = null;
      GestureHints.debugEnableInTests = false;
    });

    for (final reduce in [false, true]) {
      testWidgets('board waits quietly at the first question (${reduce ? 'reduce' : 'anim'})', (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        final c = await _open(tester);
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
        await _close(tester, c);
      });
    }

    testWidgets('a clean play: every picture and reason, the rival waits his turn, the myth reasons — passed and saved',
        (tester) async {
      final c = await _open(tester);
      for (final s in pack.slots) {
        await _pickSafe(tester, s);
        await _pickWhy(tester, {for (final w in s.whyChips) if (w.correct) w.id});
      }
      // The coworker's two beats: he storms in and says the lesson's myth in
      // his own voice; the believe buttons are not there until he has gone.
      var heardMyth = false;
      for (var i = 0; i < 600 && !heardMyth; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        heardMyth = find.text(M5Board53Lines.rivalMyth).evaluate().isNotEmpty;
      }
      expect(heardMyth, isTrue, reason: 'the rival says the lesson\'s myth');
      expect(find.text('হ্যাঁ'), findsNothing, reason: 'no answer while he is still talking');
      expect(find.text('না'), findsNothing, reason: 'no answer while he is still talking');
      await _answerMyth(tester, right: true);
      await _pickWhy(tester, {for (final w in pack.myth.whyChips) if (w.correct) w.id});
      for (var i = 0; i < 200 && c.read(gameSaveProvider).rungProgress[_rung] != 'cleared'; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress[_rung], 'cleared', reason: 'a clean play passes the board');
      expect(save.bestMarkByRung[_rung], 100, reason: 'every question right first time');
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });

    testWidgets('three misses in a row bring the lesson card', (tester) async {
      final c = await _open(tester);
      final s = pack.slots.first;
      for (var miss = 0; miss < 3; miss++) {
        await _tapPick(tester, {for (final o in s.options) if (!o.correct) o.id});
        await _settle(tester, 2500);
      }
      var offered = false;
      for (var i = 0; i < 200 && !offered; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        offered = find.text('এখন না').evaluate().isNotEmpty;
      }
      expect(offered, isTrue, reason: 'after three misses the lesson card flies out');
      expect(find.text(LearnCoachLines.threeMisses), findsWidgets, reason: 'the guide says why the card came');
      expect(c.read(gameSaveProvider).rungProgress[_rung], isNot('cleared'));
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });

    testWidgets('a miss on every picture fails the board: not cleared, the fail panel offers the lesson', (tester) async {
      final c = await _open(tester);
      for (final s in pack.slots) {
        await _tapPick(tester, {for (final o in s.options) if (!o.correct) o.id});
        await _settle(tester, 3000);
        await _pickSafe(tester, s);
        await _pickWhy(tester, {for (final w in s.whyChips) if (w.correct) w.id});
      }
      await _answerMyth(tester, right: true);
      await _pickWhy(tester, {for (final w in pack.myth.whyChips) if (w.correct) w.id});
      var failed = false;
      for (var i = 0; i < 200 && !failed; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        failed = find.text('আবার খেলুন').evaluate().isNotEmpty;
      }
      expect(failed, isTrue, reason: '7 of 12 first-try answers (58%) is under the pass mark');
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress[_rung], isNot('cleared'));
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });

    testWidgets('the hint hand sweeps the cards after a long pause and presses none', (tester) async {
      GestureHints.debugEnableInTests = true;
      final c = await _open(tester);
      await _waitPick(tester, pack.slots.first);
      final hand = find.byKey(const ValueKey('gesture-hint'));
      var shown = false;
      for (var i = 0; i < 200 && !shown; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        shown = hand.evaluate().isNotEmpty;
      }
      expect(shown, isTrue, reason: 'idle at the cards: the hand shows how to touch');
      for (final o in pack.slots.first.options) {
        expect(find.text(o.labelBn), findsNothing, reason: 'the sweep presses no card');
      }
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;

Set<String> _safeIds(String slot) => {for (final o in _slot(slot).options) if (o.correct) o.id};

// ---- Widget-flow helpers ----------------------------------------------------

Future<ProviderContainer> _open(WidgetTester t) async {
  t.view.physicalSize = const Size(720, 1600);
  t.view.devicePixelRatio = 2.0;
  SharedPreferences.setMockInitialValues({});
  final c = ProviderContainer(overrides: [authProvider.overrideWith(_TestAuth.new)]);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      theme: SlmTheme.night(),
      home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.3', ladderIndex: 130, pack: pack, muted: true),
    ),
  ));
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.platformDispatcher.clearAccessibilityFeaturesTestValue();
  t.view.reset();
}

Future<void> _settle(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Dealt cards with the given [prefix] (`pick` / `why`) whose id is in [ids],
/// newest deal (card wave) only.
Finder _dealt(String prefix, Set<String> ids) {
  // The newest wave is looked up each time the finder is evaluated.
  int newest() {
    var wave = -1;
    for (final e in find
        .byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('$prefix-'))
        .evaluate()) {
      wave = math.max(wave, int.tryParse((e.widget.key! as ValueKey<String>).value.split('-')[1]) ?? -1);
    }
    return wave;
  }

  return find.byWidgetPredicate((w) {
    final k = w.key;
    if (w.runtimeType.toString() != '_AnimatedChoiceCard' || k is! ValueKey<String>) return false;
    final parts = k.value.split('-');
    if (parts.first != prefix) return false;
    return int.tryParse(parts[1]) == newest() && ids.contains(parts.skip(2).join('-'));
  });
}

Future<void> _waitPick(WidgetTester t, LearnBoardSlot s) async {
  final all = {for (final o in s.options) o.id};
  for (var i = 0; i < 400 && _dealt('pick', all).evaluate().length < s.cards; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(_dealt('pick', all), findsNWidgets(s.cards), reason: '${s.id}: the hand is dealt');
  await _settle(t, 1200); // the deal animation lands
}

Future<void> _tapPick(WidgetTester t, Set<String> ids) async {
  final f = _dealt('pick', ids);
  for (var i = 0; i < 400 && f.evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await _settle(t, 1200);
  await pickBoardCard(t, f);
}

/// Taps the round's safe card (retrying while a voice line or deal holds the
/// board) until the reason deck is dealt.
Future<void> _pickSafe(WidgetTester t, LearnBoardSlot s) async {
  await _waitPick(t, s);
  final safe = {for (final o in s.options) if (o.correct) o.id};
  final whyIds = {for (final w in s.whyChips) w.id};
  for (var attempt = 0; attempt < 20; attempt++) {
    final f = _dealt('pick', safe);
    await tryPickBoardCard(t, f);
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
      if (_dealt('why', whyIds).evaluate().length >= s.whyCards && _dealt('pick', {for (final o in s.options) o.id}).evaluate().isEmpty) {
        await _settle(t, 1200);
        return;
      }
    }
  }
  fail('${s.id}: the reason deck never came up');
}

/// Taps a right reason (retrying while the board is busy) until the deck leaves.
Future<void> _pickWhy(WidgetTester t, Set<String> right) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    final f = _dealt('why', right);
    if (f.evaluate().isEmpty) {
      await _settle(t, 300);
      continue;
    }
    await tryPickBoardCard(t, f);
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 100));
      if (_dealt('why', right).evaluate().isEmpty) return;
    }
  }
  fail('the right reason was never taken');
}

/// Waits for the guide's yes/no question after the rival leaves and answers it
/// (the question is asked straight or turned round at random).
Future<void> _answerMyth(WidgetTester t, {required bool right}) async {
  final m = pack.myth;
  var flipped = false, asked = false;
  for (var i = 0; i < 900 && !asked; i++) {
    await t.pump(const Duration(milliseconds: 100));
    if (find.text(m.stingBn).evaluate().isNotEmpty) asked = true;
    if (find.text(m.flipStingBn).evaluate().isNotEmpty) asked = flipped = true;
  }
  expect(asked, isTrue, reason: 'the guide asks about his claim');
  // "বিশ্বাস করেন?" → না is right; "কি ভুল?" → হ্যাঁ is right.
  final yes = flipped == right;
  for (var attempt = 0; attempt < 40; attempt++) {
    await _settle(t, 300);
    final b = find.text(yes ? 'হ্যাঁ' : 'না');
    if (b.evaluate().isEmpty) continue;
    await t.tap(b.first, warnIfMissed: false);
    await t.pump();
    await _settle(t, 600);
    if (find.text(yes ? 'হ্যাঁ' : 'না').evaluate().isEmpty) return;
  }
  fail('the believe question was never answered');
}

// ---- The fairness check (mirrors tool/m5_board53_art.py / scan_board_art.py) ----
final _elem = RegExp(r'<(/?)([\w:]+)\b([^>]*?)(/?)>');
final _attr = RegExp(r'([\w:-]+)="([^"]*)"');
final _token = RegExp(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b');
final _numRe = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
final _xform = RegExp(r'(matrix|translate|scale|rotate|skewX|skewY)\s*\(([^)]*)\)');
final _pathTok = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
// Containers paint nothing themselves; definitions are never painted where they stand.
const _noPaint = {'g', 'svg', 'a', 'switch'};
const _defs = {'defs', 'clipPath', 'mask', 'pattern', 'symbol', 'marker', 'linearGradient', 'radialGradient', 'filter'};
const _inherit = ['fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width', 'visibility'];
const _identity = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0];

double _num(String? v, [double fallback = 1]) {
  if (v == null) return fallback;
  final s = v.trim();
  if (s.endsWith('%')) {
    final p = double.tryParse(s.substring(0, s.length - 1));
    return p == null ? fallback : p / 100;
  }
  return double.tryParse(s) ?? fallback;
}

List<double> _nums(String s) => [for (final m in _numRe.allMatches(s)) double.parse(m.group(0)!)];

Map<String, String> _attrs(String raw) {
  final a = {for (final x in _attr.allMatches(raw)) x.group(1)!: x.group(2)!};
  final style = a.remove('style');
  if (style != null) {
    for (final part in style.split(';')) {
      final i = part.indexOf(':');
      if (i > 0) a[part.substring(0, i).trim()] = part.substring(i + 1).trim();
    }
  }
  return a;
}

List<double> _mul(List<double> m, List<double> n) => [
      m[0] * n[0] + m[2] * n[1],
      m[1] * n[0] + m[3] * n[1],
      m[0] * n[2] + m[2] * n[3],
      m[1] * n[2] + m[3] * n[3],
      m[0] * n[4] + m[2] * n[5] + m[4],
      m[1] * n[4] + m[3] * n[5] + m[5],
    ];

List<double> _transform(String? text) {
  var m = _identity;
  for (final f in _xform.allMatches(text ?? '')) {
    final v = _nums(f.group(2)!);
    List<double>? t;
    switch (f.group(1)) {
      case 'matrix' when v.length == 6:
        t = v;
      case 'translate' when v.isNotEmpty:
        t = [1, 0, 0, 1, v[0], v.length > 1 ? v[1] : 0];
      case 'scale' when v.isNotEmpty:
        t = [v[0], 0, 0, v.length > 1 ? v[1] : v[0], 0, 0];
      case 'rotate' when v.isNotEmpty:
        final r = v[0] * math.pi / 180;
        t = [math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0];
        if (v.length >= 3) t = _mul(_mul([1, 0, 0, 1, v[1], v[2]], t), [1, 0, 0, 1, -v[1], -v[2]]);
      case 'skewX' when v.isNotEmpty:
        t = [1, 0, math.tan(v[0] * math.pi / 180), 1, 0, 0];
      case 'skewY' when v.isNotEmpty:
        t = [1, math.tan(v[0] * math.pi / 180), 0, 1, 0, 0];
    }
    if (t != null) m = _mul(m, t);
  }
  return m;
}

/// Points whose box holds the whole path (ends and control points; an arc adds a
/// box of its size around its ends), or null when the path can't be read.
List<(double, double)>? _pathPoints(String d) {
  const arity = {'m': 2, 'l': 2, 'h': 1, 'v': 1, 'c': 6, 's': 4, 'q': 4, 't': 2, 'a': 7, 'z': 0};
  final toks = [for (final m in _pathTok.allMatches(d)) m.group(0)!];
  final pts = <(double, double)>[];
  String? cmd;
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  (double, double)? lastC;
  var i = 0;
  while (i < toks.length) {
    if (RegExp(r'^[A-Za-z]$').hasMatch(toks[i])) {
      cmd = toks[i++];
      if (cmd == 'z' || cmd == 'Z') {
        x = sx;
        y = sy;
        pts.add((x, y));
        lastC = null;
        continue;
      }
    }
    if (cmd == null) return null;
    final c = cmd.toLowerCase();
    final n = arity[c]!;
    if (i + n > toks.length) return null;
    final v = <double>[];
    for (final t in toks.sublist(i, i + n)) {
      final p = double.tryParse(t);
      if (p == null) return null;
      v.add(p);
    }
    i += n;
    final rel = cmd != cmd.toUpperCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    if (c == 'h') {
      x = v[0] + ox;
      pts.add((x, y));
      lastC = null;
    } else if (c == 'v') {
      y = v[0] + oy;
      pts.add((x, y));
      lastC = null;
    } else if (c == 'a') {
      final ex = v[5] + ox, ey = v[6] + oy;
      final r = 2 * [v[0].abs(), v[1].abs(), math.sqrt((ex - x) * (ex - x) + (ey - y) * (ey - y))].reduce(math.max);
      pts.addAll([(x - r, y - r), (x + r, y + r), (ex, ey)]);
      x = ex;
      y = ey;
      lastC = null;
    } else {
      final ctrl = [for (var k = 0; k < n; k += 2) (v[k] + ox, v[k + 1] + oy)];
      if (c == 's' || c == 't') ctrl.insert(0, lastC == null ? (x, y) : (2 * x - lastC.$1, 2 * y - lastC.$2));
      pts.addAll(ctrl);
      lastC = ctrl.length > 1 ? ctrl[ctrl.length - 2] : null;
      (x, y) = ctrl.last;
      if (c == 'm') {
        sx = x;
        sy = y;
        cmd = rel ? 'l' : 'L';
      }
    }
  }
  return pts.isEmpty ? null : pts;
}

List<(double, double)>? _localPoints(String tag, Map<String, String> a) {
  double n(String k) => _num(a[k], 0);
  switch (tag) {
    case 'rect':
      return [(n('x'), n('y')), (n('x') + n('width'), n('y') + n('height'))];
    case 'circle':
      return [(n('cx') - n('r'), n('cy') - n('r')), (n('cx') + n('r'), n('cy') + n('r'))];
    case 'ellipse':
      return [(n('cx') - n('rx'), n('cy') - n('ry')), (n('cx') + n('rx'), n('cy') + n('ry'))];
    case 'line':
      return [(n('x1'), n('y1')), (n('x2'), n('y2'))];
    case 'polygon' || 'polyline':
      final v = _nums(a['points'] ?? '');
      return v.length < 2 ? null : [for (var k = 0; k + 1 < v.length; k += 2) (v[k], v[k + 1])];
    case 'path':
      return _pathPoints(a['d'] ?? '');
  }
  return null; // text and the rest: can't place it, so it counts
}

/// The colours and gradients an SVG card really paints on its 200 x 220 face
/// (mirrors `painted` / `tokens` in tool/scan_board_art.py). Skipped: definitions;
/// anything with display:none, visibility:hidden or opacity 0 on itself or on any
/// ancestor group; a transform that squashes it flat (scale(0)); zero-size shapes;
/// no fill and no stroke; a shape wholly off the card.
Set<String> _visibleTokens(String svg) {
  final vbMatch = RegExp(r'<svg\b[^>]*viewBox="([^"]*)"').firstMatch(svg);
  final vb = vbMatch == null ? <double>[] : _nums(vbMatch.group(1)!);
  final (x0, y0, cw, ch) = vb.length == 4 ? (vb[0], vb[1], vb[2], vb[3]) : (0.0, 0.0, 200.0, 220.0);
  final stack = <(String, bool, bool, Map<String, String>, List<double>)>[('#doc', false, false, {}, _identity)];
  final out = <String>{};
  for (final e in _elem.allMatches(svg)) {
    final tag = e.group(2)!;
    if (e.group(1)!.isNotEmpty) {
      for (var k = stack.length - 1; k > 0; k--) {
        if (stack[k].$1 == tag) {
          stack.removeRange(k, stack.length);
          break;
        }
      }
      continue;
    }
    final (_, pHidden, pDefs, pInh, pM) = stack.last;
    final own = _attrs(e.group(3)!);
    final inh = {...pInh, for (final k in _inherit) if (own.containsKey(k)) k: own[k]!};
    final m = _mul(pM, _transform(own['transform']));
    final inDefs = pDefs || _defs.contains(tag);
    final hidden = pHidden || own['display'] == 'none' || _num(own['opacity']) <= 0 || (m[0] * m[3] - m[1] * m[2]).abs() < 1e-9;
    if (e.group(4)!.isEmpty && !e.group(3)!.trimRight().endsWith('/')) stack.add((tag, hidden, inDefs, inh, m));
    if (inDefs || hidden || _noPaint.contains(tag) || inh['visibility'] == 'hidden' || inh['visibility'] == 'collapse') continue;
    final a = {...own, ...inh};
    var fillOn = a['fill'] != 'none' && _num(a['fill-opacity']) > 0;
    final strokeOn = a['stroke'] != null && a['stroke'] != 'none' && _num(a['stroke-opacity']) > 0 && _num(a['stroke-width']) > 0;
    if (tag == 'line') fillOn = false;
    if (!fillOn && !strokeOn) continue;
    if (tag == 'rect' && (_num(a['width'], 0) <= 0 || _num(a['height'], 0) <= 0)) continue;
    if (tag == 'circle' && _num(a['r'], 0) <= 0) continue;
    if (tag == 'ellipse' && (_num(a['rx'], 0) <= 0 || _num(a['ry'], 0) <= 0)) continue;
    if ((tag == 'path' || tag == 'polygon' || tag == 'polyline') && (a['d'] ?? a['points'] ?? '').isEmpty) continue;
    if (tag == 'line' && a['x1'] == a['x2'] && a['y1'] == a['y2']) continue;
    final pts = _localPoints(tag, a);
    if (pts != null) {
      final pad = strokeOn ? 2 * _num(a['stroke-width']) : 0.0; // miter joins reach 2 x width
      final xs = pts.map((p) => p.$1), ys = pts.map((p) => p.$2);
      final lx = xs.reduce(math.min) - pad, hx = xs.reduce(math.max) + pad;
      final ly = ys.reduce(math.min) - pad, hy = ys.reduce(math.max) + pad;
      final box = [(lx, ly), (hx, ly), (lx, hy), (hx, hy)];
      final tx = [for (final (px, py) in box) m[0] * px + m[2] * py + m[4]];
      final ty = [for (final (px, py) in box) m[1] * px + m[3] * py + m[5]];
      if (tx.reduce(math.max) <= x0 || tx.reduce(math.min) >= x0 + cw || ty.reduce(math.max) <= y0 || ty.reduce(math.min) >= y0 + ch) continue;
    }
    if (fillOn && a['fill'] != null) out.addAll(_token.allMatches(a['fill']!).map((t) => t.group(0)!));
    if (strokeOn) out.addAll(_token.allMatches(a['stroke']!).map((t) => t.group(0)!));
  }
  return out;
}
