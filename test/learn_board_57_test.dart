// Module 5 lesson 5.7 picture board ("রাতের বেলা ফল্ট খোঁজার কৌশল",
// rung 5.7/learn, pack learn_5_7): its content follows the board's rules and
// the lesson's points, every picture exists and no colour or backdrop marks
// the safe card (in any hand the dealer can make), the rival's myth is the
// lesson's own and his new lines are listed for recording, the board waits
// quietly once the first hand is dealt, a clean play (picks, reasons, the
// rival's myth and its reason) clears the rung, a trap says the lesson's
// reason, three misses in a row bring the lesson card, a play below the pass
// mark fails without clearing, and a stuck player gets a sweep hint.
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack57;
const _artDir = 'assets/game/art/m5_board57';
const _rung = '5.7/learn';

/// Has read lesson 5.7 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['5_7', '5.7']));
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

  test('the lesson 5.7 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '5.7');
    // Registered by the director (learn_board_models.dart); until then null.
    expect(learnBoardPackFor('5.7'), same(learnBoardPack57));
    expect(pack.badgeBn, 'ফল্ট ফাইন্ডার', reason: 'the lesson\'s own badge name');
    expect(pack.titleBn, 'রাতের বেলা ফল্ট খোঁজার কৌশল');
    expect(pack.slots.map((s) => s.id), ['prep', 'drive', 'eyes', 'clue', 'sense']);
    expect(pack.slots.length, 5, reason: 'ruling M5-11: boards trimmed to 5 rounds');
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
      // Ruling M5-13: the source's stray Cyrillic / Hangul / Devanagari words never
      // reach the screen (the danda U+0964/0965 is shared with Bangla).
      expect(l, isNot(matches(RegExp('[\u0400-\u04FF\uAC00-\uD7AF\u0900-\u0963\u0966-\u097F]'))), reason: '"$l": clean Bangla');
    }
  });

  test('ground patrol only: no PTW is presented as a must for looking at a line (ruling M5-3)', () {
    final all = [
      for (final s in pack.slots) ...[
        s.promptBn,
        for (final o in s.options) ...[o.labelBn, o.rejectBn],
        for (final w in s.whyChips) w.textBn,
      ],
    ];
    for (final l in all) {
      expect(l, isNot(contains('PTW')), reason: '"$l"');
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
      final why = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal('${s.id}/why', s.whyChips, count: s.whyCards);
        expect(hand.where((p) => p.correct), hasLength(1), reason: '${s.id}: one right reason per deal');
        expect(hand.map((c) => c.id).toSet(), hasLength(s.whyCards), reason: '${s.id}: three different reasons');
        why.add((hand.map((c) => c.id).toList()..sort()).join(','));
      }
      expect(why.length, greaterThan(1), reason: '${s.id}: reasons dealt fresh');
    }
  });

  test('the lesson\'s points: prepare, drive slow in pairs, let the eyes adapt, read the clues, listen and ask', () {
    // Prep: charged lights, never alone, a reflective jacket at the roadside (pro tips 2–4).
    expect(_slot('prep').options.where((o) => o.correct).map((o) => o.id), ['charged', 'pair']);
    expect(_reject('prep', 'alone'), contains('একা নয়'));
    expect(_reject('prep', 'dark'), allOf(contains('প্রতিফলক জ্যাকেট'), contains('চালক')));
    expect(_reject('prep', 'flicker'), allOf(contains('টর্চ'), contains('হেডল্যাম্প'), contains('চার্জড')));
    // Drive: slow, one drives and one watches; a searchlight for the pole top (myth 2); known roads.
    expect(_slot('drive').options.where((o) => o.correct).map((o) => o.id), ['slow', 'binoc']);
    expect(_reject('drive', 'headlights'), allOf(contains('হেডলাইট শুধু রাস্তা'), contains('সার্চলাইট')));
    expect(_reject('drive', 'crane'), contains('একজন গাড়ি চালাবেন'));
    expect(_reject('drive', 'speed'), contains('গতি কম'));
    expect(_reject('drive', 'track'), contains('পরিচিত ও নিরাপদ রাস্তা'));
    // Eyes: lights off and wait — the eyes adapt (pro tip 1); corona is invisible by day.
    expect(_reject('eyes', 'beam'), allOf(contains('আলো নিভিয়ে'), contains('অভ্যস্ত')));
    expect(_reject('eyes', 'flick'), contains('আলো নিভিয়ে'));
    expect(_reject('eyes', 'midday'), contains('দিনের বেলায় অদৃশ্য'));
    // Clue: corona = faint blue/purple glow (not a torch glint); tracking = a bad insulator; a flash marks the place.
    expect(_slot('clue').options.where((o) => o.correct).map((o) => o.id), ['corona', 'tracking', 'flash']);
    expect(_reject('clue', 'glint'), allOf(contains('নীল বা বেগুনি'), contains('প্রতিফলন নয়')));
    expect(_reject('clue', 'fine'), contains('খারাপ হয়ে গেছে'));
    expect(_reject('clue', 'ignored'), contains('সঠিক অবস্থান'));
    // Sense: sounds carry in the night quiet; ask the residents; no hurry; holes and stumbles.
    expect(_reject('sense', 'pass'), contains('জিজ্ঞাসা করুন'));
    expect(_reject('sense', 'field'), allOf(contains('হোঁচট'), contains('গর্তে')));
    expect(_reject('sense', 'run'), allOf(contains('দ্বিগুণ'), contains('তাড়াহুড়ো')));
    expect(_slot('sense').whyChips.any((w) => w.correct && w.textBn.contains('হিসহিস')), isTrue);
    // The runner deals reasons whatever safe card was picked, so a right reason
    // must hold for every safe card of its round, never name just one of them
    // or explain only why a trap is wrong (the playbook, section 4).
    const oneCardOnly = {
      'drive': ['বাইনোকুলার', 'গতি কম'],
      'clue': ['করোনা', 'ট্র্যাকিং', 'ঝলকানি'],
      'sense': ['গর্ত', 'হোঁচট', 'তাড়াহুড়ো'],
    };
    oneCardOnly.forEach((slot, words) {
      for (final w in _slot(slot).whyChips.where((w) => w.correct)) {
        for (final word in words) {
          expect(w.textBn, isNot(contains(word)), reason: '$slot: "${w.textBn}" fits only one card');
        }
      }
    });
    expect(_slot('drive').whyChips.any((w) => w.correct && w.textBn.contains('সার্চলাইট')), isTrue,
        reason: 'both safe drive cards light the pole top with the searchlight');
    expect(pack.earnedBn, allOf(contains('সঙ্গী'), contains('প্রতিফলক')));
  });

  test('every picture exists (night scenes from tool/m5_board57_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m5_board57 folder is a card on the board', () {
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

  // The playbook (section 4): the right option must not stand out. A round
  // shares one backdrop and one palette; every gradient and colour drawn on a
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
  // afterMiss hands are of the same shape): the safe card is never the only
  // one on its backdrop or the only one with a colour.
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

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'রাতে কিছু দেখা যায় না, তাই পেট্রোলিং করে লাভ নেই। সকাল হওয়ার জন্য অপেক্ষা করাই ভালো।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'sparks and corona show best at night; restoring supply is urgent');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('রাতেই')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('জরুরি পরিষেবা')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    expect(m.flipStingBn, contains('ভুল'), reason: 'the turned-round question is a real yes/no ("is he wrong?")');
    // His parting line is already recorded; the new ones stay silent until the director records them.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M5Board57Lines.toRecord, containsAll([m.tauntBn, m.rivalLineBn]));
    for (final l in M5Board57Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: 'recorded clip for "$l" exists');
    }
  });

  group('board on screen', () {
    setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('board waits quietly at the first question (${reduce ? 'reduce' : 'anim'})', (tester) async {
        await _open(tester, reduce: reduce, font: false);
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
        await _close(tester);
      });
    }
  });

  testWidgets('a clean play: every pick, every reason, the rival\'s myth and its reason — the rung is cleared at 100',
      (tester) async {
    await _open(tester);
    for (final s in pack.slots) {
      await _pick(tester, s, right: true);
      await _why(tester, s.whyChips);
    }
    // Fast play cannot skip the coworker: taps while he talks change nothing.
    await _until(tester, () => find.text(pack.myth.tauntBn).evaluate().isNotEmpty, what: 'the rival\'s taunt');
    for (final at in const [Offset(180, 300), Offset(180, 520), Offset(180, 700)]) {
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 60));
    }
    for (final t in ['না', 'হ্যাঁ']) {
      expect(find.text(t), findsNothing, reason: 'no answer button while the rival talks');
    }
    expect(_onScreen('why'), isEmpty, reason: 'taps during the cutscene do not jump to the reason deck');
    await _until(tester, () => find.text(pack.myth.rivalLineBn).evaluate().isNotEmpty,
        what: 'the rival still says his myth after the taps');
    expect(find.text('বিশ্বাস করেন?'), findsNothing, reason: 'the guide has not asked yet');
    expect(find.text('সেটা কি ভুল?'), findsNothing, reason: 'the guide has not asked yet');
    await _refuseRival(tester);
    await _why(tester, pack.myth.whyChips);
    await _until(tester, () => _save(tester).rungProgress[_rung] == 'cleared', what: 'the clear saved');
    expect(_save(tester).bestMarkByRung[_rung], 100, reason: 'every question right on the first try');
    expect(find.byType(LevelFailPanel), findsNothing);
    // The award runs to its end (bonus, score saved, badge line), then the
    // end-of-level offer to read the lesson waits for the player.
    await _until(tester, () => find.text('পরে পড়ব').evaluate().isNotEmpty, what: 'the end-of-level lesson offer');
    expect(_save(tester).bestTimeMsByRung[_rung], isNotNull, reason: "the play's time is saved");
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets('a trap says the lesson\'s reason; three misses in a row bring the lesson card', (tester) async {
    await _open(tester);
    final s = pack.slots.first;
    final first = await _pick(tester, s, right: false, settle: false);
    final trap = s.options.firstWhere((o) => o.id == first);
    expect(find.text(trap.labelBn), findsWidgets, reason: 'the chosen card shows its name');
    await _until(tester, () => find.text(trap.rejectBn).evaluate().isNotEmpty, what: 'the trap\'s reason under the card');
    await continueBoard(tester);
    await _pick(tester, s, right: false);
    await _pick(tester, s, right: false);
    await _until(tester, () => find.text('এখন না').evaluate().isNotEmpty, what: 'the lesson card after three misses');
    // It flies out of the পাঠ pill first; "এখন না" tucks it back once it has landed.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('এখন না'), warnIfMissed: false);
    await _until(tester, () => find.text('এখন না').evaluate().isEmpty, what: 'the lesson card tucked away');
    // The board carries on: the safe card is still in the (re-dealt) hand.
    await _pick(tester, s, right: true);
    await _until(tester, () => _onScreen('why').isNotEmpty, what: 'the reason deck after the right pick');
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets('below the pass mark (5 of 12 missed first time) the play fails: fail panel, nothing cleared',
      (tester) async {
    await _open(tester);
    for (final s in pack.slots) {
      await _pick(tester, s, right: false);
      await _pick(tester, s, right: true);
      await _why(tester, s.whyChips);
    }
    await _refuseRival(tester);
    await _why(tester, pack.myth.whyChips);
    await _until(tester, () => find.byType(LevelFailPanel).evaluate().isNotEmpty, what: 'the fail panel');
    expect(_save(tester).rungProgress[_rung], isNot('cleared'));
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  group('gesture hint', () {
    setUp(() => GestureHints.debugEnableInTests = true);
    tearDown(() => GestureHints.debugEnableInTests = false);

    testWidgets('a stuck player gets a hand over the cards; a touch hides it', (tester) async {
      await _open(tester);
      await _waitPick(tester, pack.slots.first);
      expect(find.byKey(const ValueKey('gesture-hint')), findsNothing, reason: 'no hand before the player is idle');
      for (var i = 0; i < 95; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const ValueKey('gesture-hint')), findsOneWidget, reason: 'idle ~8 s at the pick: the sweep hint');
      await _pick(tester, pack.slots.first, right: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('gesture-hint')), findsNothing, reason: 'any touch hides it');
      await _close(tester);
    });
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;

var _fontLoaded = false;

/// The real Bangla font, so the rival's bubble and the cards are measured as
/// on a phone (the test font's square glyphs are far wider than Bangla).
Future<void> _loadBanglaFont(WidgetTester tester) async {
  if (_fontLoaded) return;
  await tester.runAsync(() async {
    final loader = FontLoader('Noto Sans Bengali');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/NotoSansBengali-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  });
  _fontLoaded = true;
}

Future<void> _open(WidgetTester tester, {bool reduce = false, bool font = true}) async {
  if (font) await _loadBanglaFont(tester);
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2.0;
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith(_TestAuth.new)],
    child: MaterialApp(
      // The sparkle splash needs a shader the test backend cannot load.
      theme: SlmTheme.night().copyWith(splashFactory: InkRipple.splashFactory),
      home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.7', ladderIndex: 140, pack: pack, muted: true),
    ),
  ));
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  tester.view.reset();
}

GameSave _save(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(LearnBoardRunnerPage))).read(gameSaveProvider);

Future<void> _until(WidgetTester tester, bool Function() ok, {required String what, int steps = 600}) async {
  for (var i = 0; i < steps; i++) {
    if (ok()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('timed out waiting for $what');
}

/// Keys of the cards on screen: `pick-<wave>-<id>` or `why-<wave>-<id>` → id.
List<String> _onScreen(String prefix) {
  final re = RegExp('^$prefix-\\d+-(\\w+)\$');
  return [
    for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String> && re.hasMatch((w.key! as ValueKey<String>).value)).evaluate())
      (e.widget.key! as ValueKey<String>).value,
  ];
}

String _idOf(String key) => key.substring(key.lastIndexOf('-') + 1);

/// Waits for slot [s]'s hand on the pick board (a full hand of its cards).
Future<void> _waitPick(WidgetTester tester, LearnBoardSlot s) async {
  final ids = {for (final o in s.options) o.id};
  await _until(tester, () {
    final on = _onScreen('pick');
    return on.length == s.cards && on.every((k) => ids.contains(_idOf(k))) && _onScreen('why').isEmpty;
  }, what: 'the ${s.id} hand');
  // Let the dealt cards land.
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Taps a safe ([right]) or trap card of slot [s]; returns its id. With
/// [settle] off it returns at once (the tapped card still shows its name).
Future<String> _pick(WidgetTester tester, LearnBoardSlot s, {required bool right, bool settle = true}) async {
  await _waitPick(tester, s);
  final byId = {for (final o in s.options) o.id: o};
  final key = _onScreen('pick').firstWhere((k) => byId[_idOf(k)]!.correct == right);
  await tapBoardCard(tester, find.byKey(ValueKey(key)));
  await tester.pump(const Duration(milliseconds: 100));
  if (!settle) return byId[_idOf(key)]!.id;
  await continueBoard(tester);
  // A wrong card shakes, then the hand is dealt again.
  for (var i = 0; i < (right ? 1 : 8); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return byId[_idOf(key)]!.id;
}

/// Taps the right reason on the why deck dealt from [pool].
Future<void> _why(WidgetTester tester, List<LearnWhyChip> pool) async {
  final byId = {for (final c in pool) c.id: c};
  await _until(tester, () {
    final on = _onScreen('why');
    return on.length == 3 && on.every((k) => byId.containsKey(_idOf(k))) && _onScreen('pick').isEmpty;
  }, what: 'the reason deck');
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final key = _onScreen('why').firstWhere((k) => byId[_idOf(k)]!.correct);
  await pickBoardCard(tester, find.byKey(ValueKey(key)));
}

/// The rival storms in (taunt, myth, exit — locked); once the guide asks,
/// the answer that refuses him: না to "বিশ্বাস করেন?", হ্যাঁ to "সেটা কি ভুল?".
Future<void> _refuseRival(WidgetTester tester) async {
  // The heading over হ্যাঁ / না appears only once the guide has asked.
  await _until(tester, () => find.text('বিশ্বাস করেন?').evaluate().isNotEmpty || find.text('সেটা কি ভুল?').evaluate().isNotEmpty,
      what: 'the guide\'s question after the rival leaves');
  final flipped = find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.tap(find.text(flipped ? 'হ্যাঁ' : 'না').last, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 100));
}
