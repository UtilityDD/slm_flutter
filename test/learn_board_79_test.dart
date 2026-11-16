// Module 7 lesson 7.9 picture board ("গ্রাহকের অধিকার এবং লাইনম্যানের
// দায়িত্ব", rung 7.9/learn, pack learn_7_9): its content follows the board's
// rules, the Module 7 rulings (M7-6: no deadly act in 7.9, every trap a slip;
// M7-10: the lesson's myth word for word; X6: 5 rounds, the owner's term
// rules) and the lesson's points (the ID card shown first, the work told in
// plain words, notice and consent before entry, the right of entry that stops
// at the work place, a calm answer to an angry customer, the clean-up and the
// signed job sheet), every picture exists and no colour, backdrop, prop or
// figure marks the safe card (in any hand the dealer can make), the rival's
// myth is the lesson's own and every spoken line is listed for recording, a
// clean play (picks, reasons, the rival's myth) clears the rung, a miss on
// every round fails it (the board's strike-out), a trap teaches with the
// lesson's words, opens no reason deck and never freezes the board (boards
// have no freeze: kit design, GAME_DEVELOPER_GUIDE §10c), the gesture hint
// sweeps without pressing, and the board waits quietly once dealt.
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
import 'package:slm_flutter/features/game/learn_board_pack79.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/board_pick.dart';
import 'support/option_lengths.dart';

const pack = learnBoardPack79;
const _artDir = 'assets/game/art/m7_board79';
const _rung = '7.9/learn';
const _ladder = 207; // m7 starts at 183; 7.9/learn is its 25th rung (orderInModule 24)

/// Has read lesson 7.9 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_9', '7.9']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.9', ladderIndex: _ladder, pack: pack, muted: true),
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

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.9');
}

Map<String, dynamic> get _content => _lesson()['content'] as Map<String, dynamic>;

/// All the lesson's text in one string (sections, myths, pro tips), for
/// "this line is the lesson's own" checks.
String get _lessonText => _norm(jsonEncode(_content).replaceAll(r'\n', ' '));

List<Map<String, dynamic>> get _myths =>
    ((_content['myth_buster'] as Map<String, dynamic>)['myths'] as List<dynamic>).cast<Map<String, dynamic>>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
    SpokenOnce.resetForTest();
  });

  test('the lesson 7.9 board: five rounds (ruling X6 trims the spec\'s six)', () {
    expect(pack.lessonId, '7.9');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.9 entry.
    final registered = learnBoardPackFor('7.9');
    if (registered != null) expect(registered, same(learnBoardPack79));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['arrive', 'entry', 'zone', 'talk', 'finish'], reason: '5 rounds');
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
      expect(s.promptBn, isNot('সঠিক জিনিস বেছে নিন'), reason: '${s.id}: specific prompt');
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
  });

  test('every round: safe pictures and enough traps, each trap says why', () {
    for (final s in pack.slots) {
      expect(s.options.length, inInclusiveRange(4, 7), reason: s.id);
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
      expect(l, isNot(contains('DO ')), reason: '"$l": no DO in Module 7 (M7-9)');
      for (final single in _singles) {
        expect(l, isNot(contains(single)), reason: '"$l": য় ড় ঢ় as letter + nukta');
      }
      for (final bad in ['এলটি', 'এইচটি', 'কেভি']) {
        expect(l, isNot(contains(bad)), reason: '"$l": $bad in English letters');
      }
    }
  });

  test('no figures or legal terms the lesson does not give: no number, no section, fine or prison term', () {
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp(r'\d'))), reason: '"$l": no numbers on this board (the lesson gives no figure for 7.9)');
      for (final no in ['ধারা', 'জরিমানা', 'কারাদণ্ড', 'জেল', 'আদালত', 'kV']) {
        expect(l, isNot(contains(no)), reason: '"$l": unsupported in the lesson');
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

  test('the lesson\'s points: the ID, the work told, notice and consent, the work place, the angry customer, the clean-up', () {
    final text = _lessonText;
    // Section 3: the company ID shown before the customer asks; the work
    // explained in plain words; section 1: her right to see the card.
    expect(_safeIds('arrive'), {'id', 'say'});
    expect(_trapIds('arrive'), {'walk', 'demand', 'uniform', 'silent', 'laugh'});
    expect(text, allOf(contains('গ্রাহক চাওয়ার আগেই আপনার কোম্পানির পরিচয়পত্র দেখান'), contains('পরিচয়পত্র (Identity Card) দেখার অধিকার')));
    expect(_reject('arrive', 'walk'), contains('গ্রাহক চাওয়ার আগেই পরিচয়পত্র দেখান'));
    expect(_reject('arrive', 'demand'), allOf(contains('চাওয়ার আগেই'), contains('অধিকার গ্রাহকের')));
    expect(_reject('arrive', 'uniform'), contains('ইউনিফর্ম পরিচয়পত্র নয়'));
    expect(text, contains('আপনি কী কাজ করতে এসেছেন এবং কেন, তা সহজ ভাষায় গ্রাহককে বোঝান'));
    expect(_reject('arrive', 'silent'), contains('কী কাজ করতে এসেছেন এবং কেন, তা সহজ ভাষায় গ্রাহককে বোঝান'));
    // Myth 2's reality: an unprofessional and wrong attitude.
    expect(text, allOf(contains('অপেশাদার এবং ভুল মনোভাব'), contains('সঠিক এবং স্বচ্ছ তথ্য')));
    expect(_reject('arrive', 'laugh'), allOf(contains('অপেশাদার'), contains('সঠিক তথ্য')));
    // Section 2: reasonable notice (an emergency apart); never by force or
    // without the customer's permission.
    expect(_safeIds('entry'), {'invited', 'slip'});
    expect(_trapIds('entry'), {'climb', 'push', 'unannounced'});
    expect(text, allOf(contains('যুক্তিসঙ্গত নোটিশ (Reasonable Notice)'), contains('জরুরি অবস্থা ছাড়া'), contains('জোর করে বা গ্রাহকের অনুমতি ছাড়া তার বাড়িতে প্রবেশ করতে পারেন না')));
    expect(_reject('entry', 'climb'), 'জোর করে বা গ্রাহকের অনুমতি ছাড়া কারও বাড়িতে প্রবেশ করা যায় না।');
    expect(_reject('entry', 'push'), allOf(contains('অনুমতি না দিলে'), contains('জোর করে')));
    expect(_reject('entry', 'unannounced'), allOf(contains('জরুরি অবস্থা ছাড়া'), contains('যুক্তিসঙ্গত নোটিশ')));
    // Myth 1's reality: the right of entry stops at the work place; privacy.
    expect(_safeIds('zone'), {'meter', 'route'});
    expect(_trapIds('zone'), {'bedroom', 'almirah', 'peek'});
    expect(text, allOf(contains('মিটার বক্স, ওয়্যারিং-এর রুট'), contains('গ্রাহকের ব্যক্তিগত গোপনীয়তাকে সম্মান করা আপনার দায়িত্ব')));
    expect(_reject('zone', 'bedroom'), allOf(contains('মিটার বক্স'), contains('ওয়্যারিং-এর রুট')));
    expect(_reject('zone', 'almirah'), contains('ব্যক্তিগত গোপনীয়তাকে সম্মান করা আপনার দায়িত্ব'));
    expect(_reject('zone', 'peek'), contains('গোপনীয়তা'));
    // Pro tips 1 and 2: no argument; no false promise; true facts, tell the
    // superior; show you came to solve the problem.
    expect(_safeIds('talk'), {'listen', 'report'});
    expect(_trapIds('talk'), {'argue', 'promise', 'wave'});
    expect(text, allOf(contains('তর্কে জড়াবেন না'), contains('শান্তভাবে'), contains('মিথ্যা প্রতিশ্রুতি দেবেন না'), contains('ঊর্ধ্বতন কর্তৃপক্ষকে জানাবেন'), contains('সমস্যা সমাধানের জন্যই এসেছেন')));
    expect(_reject('talk', 'argue'), allOf(contains('তর্কে জড়াবেন না'), contains('শান্তভাবে')));
    expect(_reject('talk', 'promise'), allOf(contains('ট্রান্সফরমার বদলানো আপনার হাতে নেই'), contains('মিথ্যা প্রতিশ্রুতি'), contains('সঠিক তথ্য')));
    expect(_reject('talk', 'wave'), contains('সমস্যা সমাধানের জন্যই এসেছেন'));
    // Section 3 and pro tip 4: a clean work place, no damage to her property,
    // the job sheet with her signature as the proof.
    expect(_safeIds('finish'), {'sweep', 'sheet'});
    expect(_trapIds('finish'), {'mess', 'pot', 'nosheet'});
    expect(text, allOf(contains('আপনার কাজের জায়গাটি পরিষ্কার করে দিন'), contains('সম্পত্তির কোনো ক্ষতি না হয়'), contains('জব শিট (Job Sheet)'), contains('এটি আপনার কাজের একটি প্রমাণ')));
    expect(_reject('finish', 'mess'), contains('কাজের জায়গাটি পরিষ্কার করে দিন'));
    expect(_reject('finish', 'pot'), contains('সম্পত্তির কোনো ক্ষতি না হয়'));
    expect(_reject('finish', 'nosheet'), allOf(contains('গ্রাহকের সই সহ জব শিট'), contains('কাজের প্রমাণ')));
    expect(pack.earnedBn, allOf(contains('পরিচয়'), contains('নোটিশ'), contains('অনুমতি'), contains('সই')));
  });

  test('ruling M7-6: no deadly act in 7.9; every trap is a slip (R26) and none says it is allowed', () {
    // The board has only slips: a trap never ends the board, it costs the
    // round's mark and teaches with the lesson's own words.
    for (final s in pack.slots) {
      for (final o in s.options.where((o) => !o.correct)) {
        for (final l in [o.labelBn, o.rejectBn]) {
          expect(l, isNot(contains('মারাত্মক')), reason: '${s.id}/${o.id}: no deadly wording on a slip-only board');
          expect(l, isNot(contains('প্রাণ')), reason: '${s.id}/${o.id}');
        }
      }
    }
    // The coworker's push (the myth) is rejected (believe = no).
    expect(pack.myth.believeNoIsCorrect, isTrue);
    // No AB, no DO, no live work on this board (M7-9).
    for (final l in _allText()) {
      expect(l, isNot(contains('ডিও')), reason: l);
      expect(l, isNot(contains('AB')), reason: l);
    }
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's or one trap's.
  test('right reasons fit every safe pick of their round', () {
    List<String> right(String slot) => [for (final w in _slot(slot).whyChips) if (w.correct) w.textBn];
    const onlyOne = {
      'arrive': ['কার্ড', 'ইউনিফর্ম'],
      'entry': ['গেট', 'পাঁচিল'],
      'zone': ['আলমারি', 'পর্দা'],
      'talk': ['ফোন', 'শুনছেন'],
      'finish': ['ঝাঁট', 'ঝাড়ু', 'টব'],
    };
    for (final e in onlyOne.entries) {
      for (final t in right(e.key)) {
        for (final one in e.value) {
          expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
        }
      }
    }
  });

  test('every picture exists (vector scenes from tool/m7_board79_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board79 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => '$_artDir/${f.uri.pathSegments.last}')
        .toSet();
    expect(onDisk, used, reason: 'no unused art, no stray files (the APK ships the folder), no missing art');
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

  // Props and figures (the art script tags each with <!--prop:name-->): the
  // lineman, the supervisor, the operator, the form, the switch panel, the
  // logbook, a bubble... In every hand, nothing sits only on the safe card,
  // and nothing sits on every trap but not the safe card (the odd one out
  // would be the answer).
  test('in every possible hand, no prop or figure marks the safe card', () {
    final tagRe = RegExp(r'<!--prop:(\w+)-->');
    final props = <String, Set<String>>{};
    Set<String> of(String asset) => props.putIfAbsent(
        asset, () => tagRe.allMatches(File(asset).readAsStringSync()).map((m) => m.group(1)!).toSet());

    for (final s in pack.slots) {
      final traps = s.options.where((o) => !o.correct).toList();
      for (final o in s.options) {
        expect(of(o.asset).intersection({'lineman', 'supervisor'}), isNotEmpty, reason: '${o.asset}: a worker on every card');
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

  // What each card's label says is drawn: the ID held up or only its edge in
  // the pocket, the bubbles, the gate and its lock, the curtain, the almirah,
  // the signature on the job sheet, the old meter in his hand.
  test('the pictures show what the labels say', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync();
    int signatures(String card) => 'stroke="#2346A0"'.allMatches(svg(card)).length;
    // Arrive: the ID card is held up on the two safe cards only; every trap
    // keeps it in the pocket (only the blue edge shows), so the card at a
    // size of 14 x 9 or more sits only on 'id' and 'say'.
    expect(svg('arrive_id'), contains('width="28" height="18"'), reason: 'arrive_id: the card held up large');
    expect(svg('arrive_say'), contains('width="14" height="9"'), reason: 'arrive_say: the card in his hand');
    for (final c in ['arrive_walk', 'arrive_demand', 'arrive_uniform', 'arrive_silent', 'arrive_laugh']) {
      expect(svg(c), isNot(anyOf(contains('width="28" height="18"'), contains('width="14" height="9"'))), reason: '$c: the card stays in the pocket');
      expect(svg(c), contains('width="8" height="4"'), reason: '$c: the blue edge in the pocket');
    }
    // Entry: a closed padlocked gate for the notice and the wall climb.
    for (final c in ['entry_slip', 'entry_climb']) {
      expect(svg(c), contains('<rect x="114.5" y="158"'), reason: '$c: the padlock shut on the gate');
    }
    for (final c in ['entry_invited', 'entry_push', 'entry_unannounced']) {
      expect(svg(c), contains('<rect x="136.5" y="154"'), reason: '$c: the lock hangs open');
    }
    // Zone: the curtain pushed aside only on the bedroom card; the almirah
    // standing open (its dark inside) only on the almirah card.
    expect(svg('zone_bedroom'), contains('q10 6 16 -2'), reason: 'zone_bedroom: the bed behind the curtain');
    for (final c in ['zone_meter', 'zone_route', 'zone_almirah', 'zone_peek']) {
      expect(svg(c), isNot(contains('q10 6 16 -2')), reason: '$c: the curtain stays shut');
    }
    expect(svg('zone_almirah'), contains('fill="#8C97A3"'));
    expect(svg('zone_almirah'), contains('<polygon points="126,72 116,78'), reason: 'zone_almirah: the door swung open');
    for (final c in ['zone_meter', 'zone_route', 'zone_bedroom', 'zone_peek']) {
      expect(svg(c), isNot(contains('<polygon points="126,72 116,78')), reason: '$c: the almirah stays shut');
    }
    // Talk: the angry customer's red burst on every card.
    for (final o in _slot('talk').options) {
      expect(svg('talk_${o.id}'), contains('fill="#D8402F"'), reason: '${o.id}: the customer is angry');
    }
    // Finish: the job sheet signed on every card but the one that leaves with
    // no sheet; the crushed pot and the scattered offcuts only on their cards.
    for (final c in ['finish_sweep', 'finish_mess', 'finish_pot', 'finish_sheet']) {
      expect(signatures(c), 1, reason: '$c: a signed job sheet');
    }
    expect(signatures('finish_nosheet'), 0, reason: 'finish_nosheet: no signature, he leaves with the old meter');
    expect(svg('finish_pot'), contains('rx="15" ry="3.5"'), reason: 'finish_pot: the crushed pot');
    for (final c in ['finish_sweep', 'finish_sheet', 'finish_mess', 'finish_nosheet']) {
      expect(svg(c), isNot(contains('rx="15" ry="3.5"')), reason: '$c: the pot stands whole');
    }
    expect('stroke="#2B3138" stroke-width="1.3"'.allMatches(svg('finish_mess')).length, greaterThan('stroke="#2B3138" stroke-width="1.3"'.allMatches(svg('finish_sweep')).length), reason: 'more offcuts on the ground in finish_mess');
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _norm(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1 (ruling M7-10)');
    expect(m.rivalLineBn, 'গ্রাহকের বাড়িতে কাজ করতে এসেছি, তার মানে আমি যেকোনো জায়গায় যেতে পারি এবং যেকোনো কিছু করতে পারি।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the right of entry stops at the work place');
    final reality = _norm(_myths[0]['reality'] as String);
    expect(reality, allOf(contains('কাজের সাথে সম্পর্কিত জায়গার'), contains('মিটার বক্স, ওয়্যারিং-এর রুট'), contains('ব্যক্তিগত গোপনীয়তাকে সম্মান করা আপনার দায়িত্ব')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('কাজের সাথে জড়ানো')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('গোপনীয়তাকে সম্মান')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line and the sting are already recorded; the new ones wait
    // for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board79Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board79Lines.newRivalLines, M7Board79Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board79Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board79Lines.guideSpoken;
    expect(M7Board79Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 17 trap reasons + 5×3 right reasons + sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 17 + 15 + 2 + 3 + 1));
    expect(spoken, contains(pack.introBn));
    expect(spoken, contains(pack.earnedBn));
    expect(spoken, contains(pack.myth.stingBn));
    expect(spoken, contains(pack.myth.flipStingBn));
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

    testWidgets('a slip trap (over the wall of a padlocked house) teaches with the lesson\'s words; no reason deck, no freeze (7.9 has no deadly act)', (t) async {
      final c = await _open(t);
      await _cleanRound(t, _slot('arrive'));
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is the lesson's own line. The entry round has three traps
      // and a hand of four, so every hand holds it.
      final copies = _slot('entry');
      await _settleHand(t, 'pick', {'climb'}, 'entry: the wall climb');
      await tapBoardCard(t, _dealt('pick', {'climb'}));
      await _pumpUntil(t, () => find.text(_reject('entry', 'climb')).evaluate().isNotEmpty, what: 'the trap\'s reason');
      expect(find.byType(FreezeFrame), findsNothing, reason: 'boards teach; they never freeze');
      for (final w in copies.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the "কেন" deck');
      }
      expect(find.byType(LevelFailPanel), findsNothing, reason: 'one miss does not end the board');
      // The board goes on: past the feedback, a fresh hand with a safe card.
      await continueBoard(t);
      await _cleanRound(t, copies);
      expect(find.byType(LevelFailPanel), findsNothing);
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.9', ladderIndex: _ladder, pack: pack, muted: true),
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
