// Module 6 lesson 6.10 picture board ("এনার্জি মিটার: ক্যাশ রেজিস্টার",
// rung 6.10/learn, pack learn_6_10): its content follows the board's rules, the
// Module 6 rulings (X5: a meter box is made dead at the pole fuse or incoming
// cut-out, then proved dead with the tester; the owner's term rules; 5 rounds)
// and the lesson's points, every picture exists and no colour or backdrop
// marks the safe card (in any hand the dealer can make), the pictures show the
// isolation and the report where the lesson asks for them, the rival's myth is
// the lesson's own and every spoken line is listed for recording, a clean play
// (picks, reasons, the rival's myth) clears the rung, a miss on every round
// fails it (the board's strike-out), a wrong pick says the trap's own reason
// and opens no reason deck, the gesture hint sweeps without pressing, and the
// board waits quietly once dealt.
//
// Boards have no deadly freeze (kit design, GAME_DEVELOPER_GUIDE §10c): the
// deadly-class traps (a screwdriver on a live meter's terminals, a bypass wire
// pulled bare-handed) cost a ◆ and say the lesson's own words; the tests below
// pin those words.
import 'dart:async';
import 'dart:convert';
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
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/board_pick.dart';
import 'support/option_lengths.dart';

const pack = learnBoardPack610;
const _artDir = 'assets/game/art/m6_board610';
const _rung = '6.10/learn';
const _ladder = 177;

/// Has read lesson 6.10 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_10', '6.10']));
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

/// A dealt card or chip ([prefix] pick / why) whose option id is in [ids].
Finder _dealt(String prefix, Set<String> ids) => find.byWidgetPredicate((w) {
      final k = w.key;
      return w.runtimeType.toString() == '_AnimatedChoiceCard' &&
          k is ValueKey<String> &&
          k.value.startsWith('$prefix-') &&
          ids.contains(k.value.split('-').skip(2).join('-'));
    });

Set<String> _ids(Iterable<LearnPick> picks, {required bool correct}) => {
      for (final p in picks)
        if (p.correct == correct) p.id,
    };

Future<void> _pumpUntil(WidgetTester t, bool Function() done, {int maxMs = 60000, String what = ''}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (done()) return;
    await t.pump(const Duration(milliseconds: 100));
  }
  fail('timed out waiting for $what');
}

Future<void> _settleHand(WidgetTester t, String prefix, Set<String> ids, String what) async {
  await _pumpUntil(t, () => _dealt(prefix, ids).evaluate().isNotEmpty, what: what);
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Waits until a card of [ids] is dealt and has landed, then picks it.
Future<void> _tapDealt(WidgetTester t, String prefix, Set<String> ids, String what) async {
  await _settleHand(t, prefix, ids, what);
  await pickBoardCard(t, _dealt(prefix, ids));
}

Future<ProviderContainer> _open(WidgetTester t) async {
  t.view.physicalSize = const Size(720, 1600);
  t.view.devicePixelRatio = 2.0;
  SharedPreferences.setMockInitialValues({});
  final c = ProviderContainer(overrides: [authProvider.overrideWith(_TestAuth.new)]);
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(theme: SlmTheme.night(), navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.10', ladderIndex: _ladder, pack: pack, muted: true),
  )));
  await t.pump();
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  c.dispose();
  MascotTalk.reset();
  t.view.reset();
}

/// One round played clean: a safe picture, then a right reason.
Future<void> _cleanRound(WidgetTester t, LearnBoardSlot s) async {
  await _tapDealt(t, 'pick', _ids(s.options, correct: true), '${s.id}: a safe picture');
  await _tapDealt(t, 'why', _ids(s.whyChips, correct: true), '${s.id}: a right reason');
}

/// The rival scene (the board's coworker moment, two beats): he says the
/// lesson's myth, and only then does the guide ask (না to "বিশ্বাস করেন?",
/// হ্যাঁ to "সেটা কি ভুল?"); then a right reason.
Future<void> _beatTheRival(WidgetTester t) async {
  final myth = pack.myth;
  bool asked() => find.text('বিশ্বাস করেন?').evaluate().isNotEmpty || find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  await _pumpUntil(t, () => find.text(myth.rivalLineBn).evaluate().isNotEmpty || asked(), what: 'the rival\'s myth');
  expect(find.text(myth.rivalLineBn), findsWidgets, reason: 'the rival speaks before the guide asks');
  await _pumpUntil(t, asked, what: 'the believe question');
  await t.pump(const Duration(milliseconds: 800));
  final flipped = find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  await t.tap(find.text(flipped ? 'হ্যাঁ' : 'না').last);
  await t.pump();
  await _tapDealt(t, 'why', _ids(myth.whyChips, correct: true), 'a right myth reason');
}

/// Every on-screen string of the board.
List<String> _allText() {
  final m = pack.myth;
  return [
    pack.titleBn, pack.badgeBn, pack.introBn, pack.earnedBn,
    for (final s in pack.slots) ...[
      s.promptBn,
      for (final o in s.options) ...[o.labelBn, o.rejectBn],
      for (final w in s.whyChips) w.textBn,
    ],
    m.tauntBn, m.rivalLineBn, m.exitBn, m.stingBn, ...m.dangerHints,
    for (final w in m.whyChips) w.textBn,
  ];
}

/// The lesson file writes য় ড় ঢ় as single code points; the app's strings use
/// the letter + nukta. Compare the two in one form.
final _singles = [0x09DF, 0x09DC, 0x09DD].map(String.fromCharCode).toList();
final _nukta = [[0x09AF, 0x09BC], [0x09A1, 0x09BC], [0x09A2, 0x09BC]].map(String.fromCharCodes).toList();

String _norm(String s) {
  for (var i = 0; i < 3; i++) {
    s = s.replaceAll(_singles[i], _nukta[i]);
  }
  return s;
}

/// The owner's term rules applied to a lesson quote: English digits, «ডেড»
/// for a proven-dead line.
String _terms(String s) {
  const bn = '০১২৩৪৫৬৭৮৯';
  var out = _norm(s).replaceAll('মৃত', 'ডেড');
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(bn[i], '$i');
  }
  return out;
}

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '6.10');
}

Map<String, dynamic> get _content => _lesson()['content'] as Map<String, dynamic>;

/// All the lesson's text in one string (sections, myths, pro tips), term
/// rules applied, for "this line is the lesson's own" checks.
String get _lessonText => _terms(jsonEncode(_content).replaceAll(r'\n', ' '));

List<Map<String, dynamic>> get _points => [
      for (final s in (_content['sections'] as List<dynamic>).cast<Map<String, dynamic>>())
        ...(s['points'] as List<dynamic>).cast<Map<String, dynamic>>(),
    ];

List<Map<String, dynamic>> get _myths =>
    ((_content['myth_buster'] as Map<String, dynamic>)['myths'] as List<dynamic>).cast<Map<String, dynamic>>();

List<String> get _proTips => ((_content['pro_tip'] as Map<String, dynamic>)['content'] as List<dynamic>).cast<String>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
    SpokenOnce.resetForTest();
  });

  test('the lesson 6.10 board: five rounds (owner answers after Wave A)', () {
    expect(pack.lessonId, '6.10');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 6.10 entry.
    final registered = learnBoardPackFor('6.10');
    if (registered != null) expect(registered, same(learnBoardPack610));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'যন্ত্র গুরু');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['modern', 'fast', 'blank', 'theft', 'swap'], reason: '5 rounds');
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
      expect(s.promptBn, isNot('সঠিক জিনিস বেছে নিন'), reason: '${s.id}: specific prompt');
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
  });

  test('every round: safe pictures and enough traps, each trap says why', () {
    for (final s in pack.slots) {
      // Owner answers after Wave A: 4–6 picture cards a round.
      expect(s.options.length, inInclusiveRange(4, 6), reason: s.id);
      expect(s.cards, inInclusiveRange(4, 6), reason: '${s.id}: 4–6 cards in a hand');
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

  test('every on-screen string: English digits, the house words and the owner\'s term rules', () {
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp('[০-৯]'))), reason: '"$l": English digits on screen');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        expect(l, isNot(matches(RegExp('(?<![ঀ-৿])$bad'))), reason: '"$l": house word for "$bad"');
      }
      expect(l, isNot(contains('মৃত')), reason: '"$l": «ডেড», never «মৃত»');
      expect(l, isNot(matches(RegExp('(?<![ঀ-৿])(অন|অফ)(?![ঀ-৿])'))), reason: '"$l": ON / OFF in English');
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": an AB is «লাগানো», never «বন্ধ»');
      for (final single in _singles) {
        expect(l, isNot(contains(single)), reason: '"$l": য় ড় ঢ় as letter + nukta');
      }
      for (final bad in ['এলটি', 'এইচটি', 'কেভি']) {
        expect(l, isNot(contains(bad)), reason: '"$l": $bad in English letters');
      }
    }
  });

  test('option libraries: reasons and picture names all about the same length', () {
    for (final s in pack.slots) {
      final right = [for (final w in s.whyChips) if (w.correct) w.textBn];
      final wrong = [for (final w in s.whyChips) if (!w.correct) w.textBn];
      expectLibrary('${s.id} why', right, wrong);
      expectSameLength('${s.id} why', [...right, ...wrong]);
      expect(s.whyChips.map((w) => w.id).toSet().length, s.whyChips.length, reason: '${s.id}: unique chip ids');
      // The tapped card's name shows in its preview: no name stands out.
      expectSameLength('${s.id} labels', [for (final o in s.options) o.labelBn]);
    }
    final m = pack.myth;
    final right = [for (final w in m.whyChips) if (w.correct) w.textBn];
    final wrong = [for (final w in m.whyChips) if (!w.correct) w.textBn];
    expectLibrary('myth why', right, wrong);
    expectSameLength('myth why', [...right, ...wrong]);
    // One wording per idea across the decks (one clip each).
    final all = [
      for (final s in pack.slots) for (final w in s.whyChips) w.textBn,
      for (final w in m.whyChips) w.textBn,
    ];
    expect(all.toSet().length, all.length);
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
      final whys = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal('${s.id}/why', s.whyChips, count: s.whyCards);
        expect(hand.where((p) => p.correct), hasLength(1), reason: '${s.id} why');
        whys.add((hand.map((o) => o.id).toList()..sort()).join(','));
      }
      expect(whys.length, greaterThan(1), reason: '${s.id}: fresh reason deals');
      // After a miss the hand still holds one safe card (a different picture).
      for (var run = 0; run < 12; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        final trap = hand.firstWhere((o) => !o.correct);
        final next = d.afterMiss(hand, trap, s.options, {for (final o in hand) o.id});
        expect(next, hasLength(s.cards), reason: '${s.id}: a full re-deal');
        expect(next.where((o) => o.correct), hasLength(1), reason: '${s.id}: one safe card after a miss');
        expect(next.firstWhere((o) => o.correct).id, isNot(hand.firstWhere((o) => o.correct).id), reason: s.id);
      }
    }
  });

  test('the lesson\'s points: modern meters, the fast-meter check, the blank meter, theft, the swap', () {
    final text = _lessonText;
    // Section 1: disc vs electronic, the readings, the smart meter.
    expect(_safeIds('modern'), {'lcd', 'button', 'smart'});
    expect(_trapIds('modern'), {'disc', 'kwh', 'putback'});
    expect(text, allOf(contains('অ্যালুমিনিয়ামের চাকতি'), contains('কোনো চলমান অংশ নেই'), contains('ট্যাম্পার-প্রুফ')));
    expect(_reject('modern', 'disc'), allOf(contains('চাকতি'), contains('কোনো চলমান অংশ নেই')));
    expect(_reject('modern', 'kwh'), allOf(contains('পাওয়ার ফ্যাক্টর'), contains('ফল্ট নির্ণয়ে')));
    expect(_reject('modern', 'putback'), allOf(contains('মাইক্রোপ্রসেসর'), contains('ট্যাম্পার-প্রুফ')));
    expect(text, contains('পুশ-বাটন'));
    expect(text, contains('স্বয়ংক্রিয়ভাবে বিদ্যুৎ অফিসে রিডিং পাঠাতে পারে'));
    // Section 3, complaint 1 (with the CAL LED of section 2), pro tip 1, myth 2.
    expect(_safeIds('fast'), {'off', 'bulb', 'explain'});
    expect(_trapIds('fast'), {'leak', 'fan', 'weather'});
    expect(text, contains(_reject('fast', 'leak')), reason: 'section 2\'s own words');
    expect(text, contains(_reject('fast', 'fan')), reason: 'complaint 1\'s own words');
    expect(_reject('fast', 'weather'), _terms(_myths[1]['reality'] as String), reason: 'myth 2\'s reality word for word');
    expect(_opt('fast', 'bulb').labelBn, contains('100 ওয়াট'));
    expect(_norm(_proTips[0]), allOf(contains('ফ্রিজ'), contains('পাম্প')));
    expect(_opt('fast', 'explain').labelBn, allOf(contains('ফ্রিজ'), contains('পাম্প')));
    // Section 3, complaints 2 and 3.
    expect(_safeIds('blank'), {'tester', 'cable', 'neutral'});
    expect(_trapIds('blank'), {'newmeter', 'pole', 'bad'});
    expect(text, contains(_reject('blank', 'newmeter').split('। ').first), reason: 'complaint 2: test the incoming first');
    expect(text, contains(_reject('blank', 'newmeter').split('। ').last.replaceAll('।', '')));
    expect(text, contains(_reject('blank', 'pole')), reason: 'complaint 2: voltage present → the meter\'s inside');
    expect(_reject('blank', 'bad'), contains('নিউট্রাল কেটে যাওয়ার লক্ষণ'));
    // Section 4 and its safety tip: seal, bypass, magnet — reported.
    expect(_safeIds('theft'), {'seal', 'bypass', 'magnet'});
    expect(_trapIds('theft'), {'walk', 'pull', 'pocket'});
    for (final id in _safeIds('theft')) {
      expect(_opt('theft', id).labelBn, contains('রিপোর্ট'), reason: 'theft/$id: reported');
    }
    expect(text, contains('সিল ভাঙা বা না থাকাটা ট্যাম্পারিং-এর প্রথম এবং প্রধান লক্ষণ'));
    expect(_reject('theft', 'walk'), contains('সিল ভাঙা বা না থাকাটা ট্যাম্পারিং-এর প্রথম এবং প্রধান লক্ষণ'));
    expect(_reject('theft', 'pocket'), allOf(contains('দণ্ডনীয় অপরাধ'), contains('কর্তৃপক্ষকে রিপোর্ট')));
    // Pro tip 3: both readings photographed.
    expect(_safeIds('swap'), {'cutout', 'oldphoto', 'newphoto'});
    expect(_trapIds('swap'), {'live', 'bag', 'notest'});
    expect(text, contains(_reject('swap', 'bag')), reason: 'pro tip 3 word for word');
    expect(pack.earnedBn, allOf(contains('রিপোর্ট'), contains('কাটআউট'), contains('ডেড প্রমাণ')));
  });

  test('the deadly-class traps and ruling X5 say the lesson\'s own words (no freeze on a board)', () {
    // X5: the swap trap's reason is pro tip 2 word for word («মৃত» → «ডেড»).
    final tip2 = _terms(_proTips[1]);
    expect(tip2, contains('কাটআউট খুলে লাইনটিকে সম্পূর্ণ বিচ্ছিন্ন করুন, তারপর টেস্টারে ডেড প্রমাণ করুন।'));
    expect(tip2, endsWith(_reject('swap', 'live')));
    // The safe card: the cut-out out with gloves, then proved dead.
    expect(_opt('swap', 'cutout').labelBn, allOf(contains('গ্লাভস'), contains('কাটআউট খোলা'), contains('টেস্টারে ডেড প্রমাণ')));
    // N4 / N9: cut-out out but not proved dead (and the tester proved live first).
    expect(_reject('swap', 'notest'), allOf(contains('টেস্টার যাচাই'), contains('টেস্টারে ডেড প্রমাণ')));
    // The bare-hand bypass pull (R30): the safety tip's words, then hands off.
    final tip = _norm(_points[3]['safety_tip'] as String);
    expect(tip, startsWith(_reject('theft', 'pull').split('। ').first));
    expect(_reject('theft', 'pull'), contains('খালি হাতে ছোঁবেন না'));
    // Wrong reasons carry the shortcuts, never a right chip.
    expect(_slot('swap').whyChips.any((w) => !w.correct && w.textBn.contains('ইনসুলেটেড স্ক্রু-ড্রাইভারে')), isTrue);
    expect(_slot('swap').whyChips.any((w) => !w.correct && w.textBn.contains('টেস্টার লাগে না')), isTrue);
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's or one trap's.
  test('right reasons fit every safe pick of their round', () {
    List<String> right(String slot) => [for (final w in _slot(slot).whyChips) if (w.correct) w.textBn];
    for (final t in right('modern')) {
      for (final one in ['পুশ-বাটন', 'স্মার্ট', 'LCD']) {
        expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
      }
    }
    for (final t in right('fast')) {
      for (final one in ['বাল্ব', 'ফ্রিজ', 'পাম্প', 'LED']) {
        expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
      }
    }
    for (final t in right('blank')) {
      for (final one in ['নিউট্রাল', 'কেবিল', 'ইনকামিং']) {
        expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
      }
    }
    for (final t in right('theft')) {
      for (final one in ['সিল', 'বাইপাস', 'চুম্বক']) {
        expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
      }
    }
    // Swap: the cut-out card is about safety, the photo cards about the
    // billing proof — every right chip names both.
    for (final t in right('swap')) {
      expect(t, matches(RegExp('ডেড|শক|নিরাপত্তা')), reason: '"$t": fits the cut-out card');
      expect(t, matches(RegExp('ছবি|বিল|হিসাব')), reason: '"$t": fits the photo cards');
    }
  });

  test('every picture exists (vector scenes from tool/m6_board610_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m6_board610 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => '$_artDir/${f.uri.pathSegments.last}')
        .toSet();
    expect(onDisk, used, reason: 'no unused art (no .gitkeep), no missing art');
  });

  // The playbook (section 4): the right option must not stand out. Every
  // gradient and colour drawn on a safe card must also be drawn on a trap.
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

  // Every hand the dealer can make (one safe card + any cards-1 traps):
  // the safe card's backdrop and colours are on a trap in that hand too.
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

  // Props and figures (the art script tags each with <!--prop:name-->): a
  // worker, a clipboard, a phone, a tester... In every hand, nothing sits
  // only on the safe card, and nothing sits on every trap but not the safe
  // card (the odd one out would be the answer).
  test('in every possible hand, no prop or figure marks the safe card', () {
    final tagRe = RegExp(r'<!--prop:(\w+)-->');
    final props = <String, Set<String>>{};
    Set<String> of(String asset) => props.putIfAbsent(
        asset, () => tagRe.allMatches(File(asset).readAsStringSync()).map((m) => m.group(1)!).toSet());

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
      for (final o in s.options) {
        expect(of(o.asset), contains('worker'), reason: '${o.asset}: a lineman on every card');
      }
      for (final safe in s.options.where((o) => o.correct)) {
        for (final hand in combos(traps, s.cards - 1)) {
          final ids = '${s.id}: ${safe.id} with ${hand.map((o) => o.id).join(', ')}';
          final trapSets = hand.map((o) => of(o.asset)).toList();
          final onTraps = trapSets.expand((p) => p).toSet();
          final onEveryTrap = trapSets.reduce((a, b) => a.intersection(b));
          expect(of(safe.asset).difference(onTraps), isEmpty, reason: '$ids — a prop only on the safe card');
          expect(onEveryTrap.difference(of(safe.asset)), isEmpty, reason: '$ids — a prop on every trap but the safe card');
        }
      }
    }
  });

  // Ruling X5 and the lesson in the pictures: the swap's safe card has the
  // cut-out out and the tester at 0; the live trap has the carrier still in
  // and the tester glowing; theft is reported by phone, never handled.
  test('the pictures show the isolation and the report where the lesson asks for them', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const carrierIn = 'x="78" y="26" width="44" height="20"'; // the cut-out's carrier pushed home
    const testerLive = 'fill="url(#redglow)"'; // the tester's lamp glowing
    const testerDark = 'fill="#6A3A34"'; // its lamp dark
    const phone = 'width="5" height="9" rx="1"'; // a phone at his ear
    const gloves = 'fill="#2A2D33"'; // rubber gloves
    expect(svg('swap_cutout'), isNot(contains(carrierIn)), reason: 'swap_cutout: the cut-out is out');
    expect(svg('swap_cutout'), allOf(contains(testerDark), isNot(contains(testerLive))), reason: 'swap_cutout: the tester reads dead');
    expect(svg('swap_cutout'), contains(gloves), reason: 'swap_cutout: gloves on');
    expect(svg('swap_live'), allOf(contains(carrierIn), contains(testerLive)), reason: 'swap_live: the cut-out in, the line live');
    expect(svg('swap_live'), contains('fill="url(#glow)"'), reason: 'swap_live: a flash at the terminal');
    expect(svg('swap_notest'), isNot(contains(carrierIn)), reason: 'swap_notest: the cut-out is out…');
    expect(svg('swap_notest'), isNot(contains('stroke="#D8402F" stroke-width="1.3"')), reason: '…but no tester lead on the terminals');
    for (final c in ['theft_seal', 'theft_bypass', 'theft_magnet']) {
      expect(svg(c), contains(phone), reason: '$c: reported by phone');
    }
    for (final c in ['theft_walk', 'theft_pocket']) {
      expect(svg(c), isNot(contains(phone)), reason: '$c: nobody is told');
    }
    // The pull trap phones it in too (so the phone is no giveaway), but his
    // other hand is bare on the bypass wire, with a flash.
    expect(svg('theft_pull'), contains(phone), reason: 'theft_pull: on the phone…');
    expect(svg('theft_pull'), isNot(contains(gloves)), reason: '…with bare hands');
    expect(svg('theft_pull'), contains('fill="url(#glow)"'), reason: 'theft_pull: a flash at the wire');
    expect(_opt('theft', 'pull').labelBn, contains('খালি হাতে'));
    // The blank meter: tester on the incoming first; the LCD dark.
    expect(svg('blank_tester'), contains(testerLive), reason: 'blank_tester: the tester on the incoming terminals');
    expect(svg('blank_tester'), contains('fill="#34413A"'), reason: 'blank_tester: the LCD is blank');
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _terms(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1');
    expect(m.rivalLineBn, 'মিটারের ওপর চুম্বক রাখলে মিটার স্লো হয়ে যায়।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'modern meters resist magnets and record the attempt');
    final reality = _terms(_myths[0]['reality'] as String);
    expect(reality, allOf(contains('Tamper-proof'), contains('রেকর্ড করে রাখে')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('রেকর্ড')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board610Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M6Board610Lines.newRivalLines, M6Board610Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M6Board610Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M6Board610Lines.guideSpoken;
    expect(M6Board610Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 15 trap reasons + 5×3 right reasons + sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 15 + 15 + 1 + 3 + 1));
    expect(spoken, contains(pack.introBn));
    expect(spoken, contains(pack.earnedBn));
    expect(spoken, contains(pack.myth.stingBn));
    for (final s in pack.slots) {
      expect(spoken, contains(s.promptBn));
      for (final o in s.options) {
        if (!o.correct) expect(spoken, contains(o.rejectBn), reason: '${s.id}/${o.id}');
      }
      for (final w in s.whyChips) {
        expect(spoken.contains(w.textBn), w.correct, reason: '${s.id}/${w.id}: only right reasons are said');
      }
    }
    for (final w in pack.myth.whyChips) {
      expect(spoken.contains(w.textBn), w.correct, reason: 'myth/${w.id}');
    }
    expect(spoken.toSet().length, spoken.length, reason: 'no line twice');
  });

  group('board on screen', () {
    setUpAll(() async {
      final loader = FontLoader('Noto Sans Bengali');
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        final bytes = File('assets/fonts/NotoSansBengali-$w.ttf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    });

    testWidgets('a clean play: every safe pick and its reason, then the rival\'s myth — the rung is cleared', (t) async {
      final c = await _open(t);
      for (final s in pack.slots) {
        await _cleanRound(t, s);
      }
      await _beatTheRival(t);
      await _pumpUntil(t, () => c.read(gameSaveProvider).rungProgress[_rung] == 'cleared', what: 'the clear');
      expect(c.read(gameSaveProvider).bestMarkByRung[_rung], 100, reason: 'no mistakes: a full mark');
      expect(find.byType(LevelFailPanel), findsNothing);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a miss on every round (the board\'s strike-out): below the pass line, nothing cleared', (t) async {
      final c = await _open(t);
      for (final s in pack.slots) {
        await _tapDealt(t, 'pick', _ids(s.options, correct: false), '${s.id}: a trap');
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await _cleanRound(t, s);
      }
      await _beatTheRival(t);
      await _pumpUntil(t, () => find.byType(LevelFailPanel).evaluate().isNotEmpty, what: 'the fail panel');
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress[_rung], isNot('cleared'), reason: '7 of 12 clean = 58% < 60%');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a deadly-class trap (a screwdriver on a live meter) teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      for (final s in pack.slots.takeWhile((s) => s.id != 'swap')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is pro tip 2 word for word. The swap round has three
      // traps and a hand of four, so every hand holds it.
      final swap = _slot('swap');
      await _settleHand(t, 'pick', {'live'}, 'swap: the live-meter trap');
      await tapBoardCard(t, _dealt('pick', {'live'}));
      await _pumpUntil(t, () => find.text(_reject('swap', 'live')).evaluate().isNotEmpty, what: 'pro tip 2');
      for (final w in swap.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the "কেন" deck');
      }
      expect(find.byType(LevelFailPanel), findsNothing, reason: 'one miss does not end the board');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    group('gesture hint', () {
      tearDown(() => GestureHints.debugEnableInTests = false);

      testWidgets('stuck on the pick: a sweep over every dealt card, pressing none', (t) async {
        GestureHints.debugEnableInTests = true;
        final c = await _open(t);
        await _pumpUntil(t, () => _cards.evaluate().length == pack.slots.first.cards, what: 'the first hand');
        IdleHintState hint() => t.state<IdleHintState>(find.byType(IdleHint).first);
        var seen = false;
        for (var ms = 0; ms < 20000 && !seen; ms += 100) {
          await t.pump(const Duration(milliseconds: 100));
          seen = hint().showing;
        }
        expect(seen, isTrue, reason: 'idle at the pick: the hand shows how to choose');
        expect(hint().debugOptions, hasLength(pack.slots.first.cards), reason: 'a sweep over all the pictures, never one');
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 120));
          final f = hint().debugFrame;
          if (f != null) expect(f.press, 0, reason: 'a sweep never presses a card');
        }
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    });

    group('idle', () {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.10', ladderIndex: _ladder, pack: pack, muted: true),
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
    });
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

LearnBoardOption _opt(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option);

String _reject(String slot, String option) => _opt(slot, option).rejectBn;

Set<String> _safeIds(String slot) => {for (final o in _slot(slot).options) if (o.correct) o.id};

Set<String> _trapIds(String slot) => {for (final o in _slot(slot).options) if (!o.correct) o.id};
