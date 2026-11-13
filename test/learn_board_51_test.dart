// Module 5 lesson 5.1 picture board ("'লাইন ট্রিপ করেছে'—প্রথম কাজ কী?",
// rung 5.1/learn, pack learn_5_1): its content follows the board's rules, the
// lesson's points and the Module 5 rulings; every picture exists and no
// colour or backdrop marks the safe card (in any hand the dealer can make);
// the rival's myth is the lesson's own; the board waits quietly once the
// first hand is dealt; a clean play (picks, reasons, the rival) clears the
// rung and a play with a miss on every round fails it.
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
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack51;
const _artDir = 'assets/game/art/m5_board51';
const _rung = '5.1/learn';

/// Has read lesson 5.1 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['5_1', '5.1']));
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

/// A dealt card (`pick-…` or `why-…`) whose id is one of [ids].
Finder _dealt(String kind, Set<String> ids) => find.byWidgetPredicate((w) {
      final k = w.key;
      return w.runtimeType.toString() == '_AnimatedChoiceCard' &&
          k is ValueKey<String> &&
          k.value.startsWith('$kind-') &&
          ids.contains(k.value.split('-').skip(2).join('-'));
    });

Future<void> _waitFor(WidgetTester tester, Finder f, {int seconds = 40, String what = ''}) async {
  for (var i = 0; i < seconds * 10; i++) {
    if (f.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('timed out waiting for $what');
}

Future<void> _pumpMs(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2.0;
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith(_TestAuth.new)],
    child: MaterialApp(
      theme: SlmTheme.night(),
      home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.1', ladderIndex: 121, pack: pack, muted: true),
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

String? _progress(WidgetTester tester) {
  final c = ProviderScope.containerOf(tester.element(find.byType(LearnBoardRunnerPage)));
  return c.read(gameSaveProvider).rungProgress[_rung];
}

/// Plays one round: optionally a trap first, then a safe picture and its
/// right reason.
Future<void> _playRound(WidgetTester tester, LearnBoardSlot s, {bool missFirst = false}) async {
  final safe = {for (final o in s.options) if (o.correct) o.id};
  final traps = {for (final o in s.options) if (!o.correct) o.id};
  await _waitFor(tester, _dealt('pick', safe), what: '${s.id}: the hand');
  await _pumpMs(tester, 900);
  if (missFirst) {
    final trap = _dealt('pick', traps);
    expect(trap, findsWidgets, reason: '${s.id}: a hand holds traps');
    await pickBoardCard(tester, trap);
    await _pumpMs(tester, 300);
    for (final w in s.whyChips) {
      expect(find.text(w.textBn), findsNothing, reason: '${s.id}: a wrong card never opens the reason deck');
    }
    await _waitFor(tester, _dealt('pick', safe), what: '${s.id}: the redealt hand');
    await _pumpMs(tester, 600);
  }
  await pickBoardCard(tester, _dealt('pick', safe));
  final right = {for (final w in s.whyChips) if (w.correct) w.id};
  await _waitFor(tester, _dealt('why', right), what: '${s.id}: the reason deck');
  await _pumpMs(tester, 700);
  await pickBoardCard(tester, _dealt('why', right));
  await _pumpMs(tester, 300);
}

/// The rival's myth: answer that he is wrong, then pick a right reason.
Future<void> _playMyth(WidgetTester tester) async {
  final ask = find.byWidgetPredicate((w) => w is Text && (w.data == 'বিশ্বাস করেন?' || w.data == 'সেটা কি ভুল?'));
  await _waitFor(tester, ask, seconds: 60, what: 'the believe question');
  await _pumpMs(tester, 600);
  final flipped = find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  await tester.tap(find.text(flipped ? 'হ্যাঁ' : 'না'));
  final right = {for (final w in pack.myth.whyChips) if (w.correct) w.id};
  await _waitFor(tester, _dealt('why', right), what: 'the myth reasons');
  await _pumpMs(tester, 700);
  await pickBoardCard(tester, _dealt('why', right));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
  });

  test('the lesson 5.1 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '5.1');
    // Registered by the director (learn_board_models.dart); until then null.
    expect(learnBoardPackFor('5.1'), same(learnBoardPack51));
    expect(pack.badgeBn, 'ফল্ট ফাইন্ডার', reason: 'the lesson\'s own badge');
    expect(pack.titleBn, "'লাইন ট্রিপ করেছে'—প্রথম কাজ কী?");
    expect(pack.slots.map((s) => s.id), ['call', 'treat', 'van', 'storm', 'lockout']);
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
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স', 'সেফটি বেল্ট']) {
        expect(l, isNot(contains(bad)), reason: '"$l": house word for "$bad"');
      }
      // Ruling M5-13: clean Bangla on screen (the lesson JSON has stray Hindi/Korean words);
      // the danda (U+0964/5) sits in the Devanagari block but is Bangla punctuation too.
      expect(l, isNot(matches(RegExp('[ऀ-ॣ०-ॿ가-힯؀-ۿЀ-ӿ]'))), reason: '"$l": clean Bangla');
    }
  });

  test('reason decks: a library of right and wrong, all about the same length', () {
    for (final s in pack.slots) {
      final right = [for (final w in s.whyChips) if (w.correct) w.textBn];
      final wrong = [for (final w in s.whyChips) if (!w.correct) w.textBn];
      expectLibrary('${s.id} why', right, wrong);
      expectSameLength('${s.id} why', [...right, ...wrong]);
      expect(s.whyChips.map((w) => w.id).toSet().length, s.whyChips.length, reason: '${s.id}: unique chip ids');
      // The right chips must not be the long ones on average either.
      double mean(List<String> xs) => xs.map((t) => t.length).reduce((a, b) => a + b) / xs.length;
      expect(mean(right) / mean(wrong), lessThan(1.1), reason: '${s.id}: right reasons not longer on average');
    }
    final m = pack.myth;
    final right = [for (final w in m.whyChips) if (w.correct) w.textBn];
    final wrong = [for (final w in m.whyChips) if (!w.correct) w.textBn];
    expectLibrary('myth why', right, wrong);
    expectSameLength('myth why', [...right, ...wrong]);
  });

  // An absolute or hedge word found on one side of a deck only would let a
  // player pick by the word instead of the reason.
  test('reason decks: no absolute or hedge word sits on one side only', () {
    const cues = ['কখনো', 'শুধু', 'সবচেয়ে', 'কোনো', 'সব', 'মানেই', 'সম্ভবত'];
    bool has(String text, String cue) => text.split(RegExp(r'[\s,।;—()\-]+')).contains(cue);
    final decks = <String, List<LearnWhyChip>>{
      for (final s in pack.slots) s.id: s.whyChips,
      'myth': pack.myth.whyChips,
    };
    decks.forEach((id, chips) {
      for (final cue in cues) {
        final onRight = chips.any((w) => w.correct && has(w.textBn, cue));
        final onWrong = chips.any((w) => !w.correct && has(w.textBn, cue));
        expect(onRight, onWrong, reason: '$id: "$cue" on ${onRight ? 'right' : 'wrong'} chips only');
      }
    });
  });

  test('a dealt hand has exactly one safe picture and one right reason, and plays differ', () {
    final d = LearnDealer(math.Random(7));
    for (final s in pack.slots) {
      final hands = <String>{};
      final whys = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        expect(hand, hasLength(s.cards), reason: s.id);
        expect(hand.where((p) => p.correct), hasLength(1), reason: s.id);
        hands.add((hand.map((o) => o.id).toList()..sort()).join(','));
        final why = d.deal('${s.id}/why', s.whyChips, count: s.whyCards);
        expect(why.where((c) => c.correct), hasLength(1), reason: '${s.id} why');
        whys.add((why.map((c) => c.id).toList()..sort()).join(','));
      }
      expect(hands.length, greaterThan(1), reason: '${s.id}: fresh deals');
      expect(whys.length, greaterThan(1), reason: '${s.id}: fresh reason decks');
    }
  });

  test('the lesson\'s points: ask first, trip ≠ dead, pack the van, read the storm, read the lockout', () {
    // Call: information before the field; the operator's experience; no charge after a failed hold (ruling M5-1).
    expect(_slot('call').options.where((o) => o.correct).map((o) => o.id), ['trip', 'weather', 'logbook']);
    expect(_reject('call', 'blind'), contains('প্রতিটি তথ্যই সূত্র'));
    expect(_reject('call', 'ignore'), contains('অভিজ্ঞতাকে বিশ্বাস করুন'));
    expect(_option('call', 'charge').labelBn, 'ব্রেকার না টেকার পরও আবার চার্জ করতে বলা');
    expect(_reject('call', 'charge'), 'একবার টেস্ট চার্জ সাবস্টেশন ইন-চার্জের সিদ্ধান্ত; ব্রেকার না টিকলে লাইন ব্রেকডাউন — ফল্ট না পেয়ে আর চার্জ নয়');
    // Treat: tripped is not dead; the recloser tries again; PTW + earthing; personal earth before a hand on it.
    expect(_reject('treat', 'bare'), allOf(contains("'ডেড' নয়"), contains('অটো-রিক্লোজার')));
    expect(_reject('treat', 'climb'), contains('কয়েকবার চেষ্টা'));
    expect(_reject('treat', 'guess'), contains("'লাইভ' হিসেবে গণ্য"));
    expect(_option('treat', 'ptw').labelBn, allOf(contains('PTW'), contains('আর্থিং')));
    expect(_option('treat', 'personal').labelBn, allOf(contains('PTW'), contains('ব্যক্তিগত আর্থিং')),
        reason: 'a hand on a tripped line needs the PTW and the personal earth (lesson myth reality, R1)');
    // Van: torch, binoculars, discharge rod, PPE; the team briefing.
    expect(_reject('van', 'torch_left'), allOf(contains('টর্চলাইট'), contains('বাইনোকুলার'), contains('ডিসচার্জ রড')));
    expect(_reject('van', 'rod_left'), allOf(contains('ডিসচার্জ রড'), contains('PPE')));
    expect(_reject('van', 'solo'), contains('টিম ব্রিফিং'));
    // Storm: wind + rain + earth fault = branch / punctured insulator, start in the wooded area.
    expect(_reject('storm', 'field'), allOf(contains('জঙ্গলযুক্ত'), contains('পাংচার')));
    expect(_reject('storm', 'jumper'), allOf(contains('পরিষ্কার দিনে'), contains('ওভারকারেন্ট')));
    expect(_reject('storm', 'walk'), contains('এলাকা ছোট'));
    // Lockout: several tries then lock-out = permanent; no touch without PTW + personal earth; no more charges.
    expect(_reject('lockout', 'touch'), allOf(contains('PTW'), contains('ব্যক্তিগত আর্থিং')));
    expect(_reject('lockout', 'tea'), contains('লক-আউট'));
    expect(_reject('lockout', 'charge'), contains('আগুন লাগতে পারে'));
    // The lesson: wind clash is only an example of a probable temporary fault; the prompt gives the wind.
    expect(_option('lockout', 'clash').labelBn, allOf(contains('সম্ভবত'), contains('টক্কর')));
    expect(_slot('lockout').promptBn, contains('বাতাস'));
    // Ruling M5-3: a PTW is never shown as the legal must for a ground-only patrol of an in-service line.
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect('${o.labelBn} ${o.rejectBn}', isNot(contains('টহলের আগে PTW')), reason: '${s.id}/${o.id}');
      }
    }
    // Where a safe text pairs a PTW with the search or the patrol, the PTW is tied to a hand on (or a
    // climb of) the line in its own clause, never to the search itself.
    final searchy = RegExp('খোঁজ|খুঁজ|টহল');
    final safeTexts = [
      pack.earnedBn,
      for (final s in pack.slots)
        for (final o in s.options)
          if (o.correct) o.labelBn,
    ];
    for (final t in safeTexts.where((t) => t.contains('PTW') && t.contains(searchy))) {
      for (final clause in t.split(RegExp('[—,;।]'))) {
        if (!clause.contains('PTW')) continue;
        expect(clause, anyOf(contains('হাত'), contains('ওঠ')), reason: '"$t": PTW only before a hand or a climb (M5-3)');
        expect(clause, isNot(contains(searchy)), reason: '"$t": PTW not tied to the search (M5-3)');
      }
    }
    expect(_option('lockout', 'ptw').labelBn, contains('কন্ট্রোলকে জানিয়ে'), reason: 'M5-3: inform control before the hunt');
    expect(pack.earnedBn, allOf(contains('PTW'), contains('লাইভ'), contains('হাত')));
  });

  test('every picture exists (vector scenes from tool/m5_board51_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m5_board51 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .map((n) => '$_artDir/$n')
        .toSet();
    expect(onDisk, used, reason: 'no unused art, no missing art, nothing but cards in the asset folder');
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

  // Every hand the dealer can make (one safe card + any cards-1 traps).
  test('in every possible hand, the safe card\'s backdrop and colours are on a trap too', () {
    final used = RegExp(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b');
    final backdrop = RegExp(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"');
    // Stage layouts the art script tags (van parked/leaving, figure on the pole/ground, earth coil, wire swing).
    final lookTag = RegExp(r'<!-- look:(\w+) -->');
    final svgs = <String, String>{};
    String body(String asset) => svgs.putIfAbsent(asset, () => File(asset).readAsStringSync());
    Set<String> looks(String asset) => lookTag.allMatches(body(asset)).map((m) => m.group(1)!).toSet();
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
          final trapLooks = {for (final o in hand) ...looks(o.asset)};
          expect(looks(safe.asset).difference(trapLooks), isEmpty, reason: '$ids — a stage layout only the safe card has');
        }
      }
      expect(hands, greaterThan(0), reason: s.id);
    }
    // The van round once drew every trap driving off and every safe card parked: both layouts are now on both sides.
    final van = _slot('van');
    for (final side in [true, false]) {
      final l = {for (final o in van.options.where((o) => o.correct == side)) ...looks(o.asset)};
      expect(l, containsAll(['parked', 'leaving']), reason: 'van: parked and leaving on ${side ? 'safe' : 'trap'} cards');
    }
    final treat = _slot('treat');
    final safeTreat = {for (final o in treat.options.where((o) => o.correct)) ...looks(o.asset)};
    final trapTreat = {for (final o in treat.options.where((o) => !o.correct)) ...looks(o.asset)};
    expect(safeTreat, containsAll(['coil', 'climber', 'ground']), reason: 'treat: earth coil, pole and ground figures on safe cards');
    expect(trapTreat, containsAll(['coil', 'climber', 'ground']), reason: 'treat: and on traps');
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his lines are recorded or listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'লাইন তো ট্রিপ করেই আছে, তার মানে ওটা ডেড। তাড়াতাড়ি কাজ সারার জন্য পারমিটের দরকার নেই।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'a tripped line can be switched on again at any moment');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('রিক্লোজার')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('ব্যক্তিগত আর্থিং')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    // The new ones wait for the director's voice session (silent + held caption until then).
    expect(M5Board51Lines.toRecord, [m.tauntBn, m.rivalLineBn]);
    for (final l in [m.tauntBn, m.rivalLineBn, m.exitBn]) {
      expect(LearnVoice.resolve(l, rival: true) != null || M5Board51Lines.toRecord.contains(l), isTrue,
          reason: '"$l": recorded, or listed for recording');
    }
  });

  group('board on screen', () {
    setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('board waits quietly at the first question (${reduce ? 'reduce' : 'anim'})', (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await _open(tester);
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

  group('playing the board', () {
    // The app's Bangla font, so text wraps on screen as it does on a phone
    // (the test font draws every Bangla code point a full em wide).
    setUpAll(() async {
      final loader = FontLoader('Noto Sans Bengali');
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        final bytes = File('assets/fonts/NotoSansBengali-$w.ttf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    });

    testWidgets('a clean play: every round\'s safe picture and reason, then the rival refused — the rung clears', (tester) async {
      await _open(tester);
      for (final s in pack.slots) {
        await _playRound(tester, s);
      }
      // The rival storms in with his taunt and the lesson's myth (caption held while unrecorded).
      await _waitFor(tester, find.textContaining('ট্রিপ করেই আছে'), seconds: 40, what: 'the rival\'s lines');
      await _playMyth(tester);
      for (var i = 0; i < 300 && _progress(tester) != 'cleared'; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_progress(tester), 'cleared', reason: 'a clean play clears 5.1/learn');
      // Let the award finish (clear bonus, score commit, best time) before leaving.
      await _pumpMs(tester, 9000);
      final c = ProviderScope.containerOf(tester.element(find.byType(LearnBoardRunnerPage)));
      expect(c.read(gameSaveProvider).bestMarkByRung[_rung], 100, reason: 'every question right first time');
      expect(c.read(gameSaveProvider).weakByLesson['5.1'] ?? const <String>[], isEmpty, reason: 'no weak spot after a clean play');
      expect(tester.takeException(), isNull);
      await _close(tester);
    });

    testWidgets('a trap first on every round: each miss teaches, and the play fails below the pass mark', (tester) async {
      await _open(tester);
      for (final s in pack.slots) {
        await _playRound(tester, s, missFirst: true);
      }
      await _playMyth(tester);
      final failPanel = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'LevelFailPanel');
      await _waitFor(tester, failPanel, seconds: 30, what: 'the fail panel');
      expect(_progress(tester), isNot('cleared'), reason: '7 of 12 first-try answers is below the 60 % pass mark');
      final c = ProviderScope.containerOf(tester.element(find.byType(LearnBoardRunnerPage)));
      expect(c.read(gameSaveProvider).weakByLesson['5.1'], containsAll(pack.slots.map((s) => s.id)),
          reason: 'every missed round is remembered as a weak spot');
      expect(tester.takeException(), isNull);
      await _close(tester);
    });

    testWidgets('a wrong picture names itself and says the lesson\'s reason (charge after a failed hold)', (tester) async {
      await _open(tester);
      final s = _slot('call');
      await _waitFor(tester, _dealt('pick', {for (final o in s.options) o.id}), what: 'the hand');
      await _pumpMs(tester, 900);
      // 3 traps and 4 cards: every hand holds the charge trap (ruling M5-1).
      const id = 'charge';
      final charge = _dealt('pick', {id});
      expect(charge, findsOneWidget, reason: 'the charge trap is in every hand');
      await tapBoardCard(tester, charge);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(_option('call', id).labelBn), findsWidgets, reason: 'the chosen card shows its name');
      // The reason is spoken / shown after the short "wrong" word.
      await _waitFor(tester, find.textContaining(_reject('call', id).substring(0, 20)), seconds: 12, what: 'the reject line');
      expect(find.textContaining('ব্রেকার না টিকলে লাইন ব্রেকডাউন'), findsWidgets, reason: 'the M5-1 reject text on screen');
      expect(tester.takeException(), isNull);
      await _close(tester);
    });
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

LearnBoardOption _option(String slot, String id) => _slot(slot).options.firstWhere((o) => o.id == id);

String _reject(String slot, String option) => _option(slot, option).rejectBn;
