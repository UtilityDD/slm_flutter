// Module 7 lesson 7.1 picture board ("ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন:
// আপনার বাইবেল", rung 7.1/learn, pack learn_7_1): its content follows the
// board's rules, the live lesson (ruling X3: the CEA 2023 regulation numbers
// 3 / 20 / 43 ও 50, no age rule) and the Module 7 rulings (M7-5 Reg 3 worded
// as a breach of the law, M7-6 no deadly in 7.1, M7-10 the myth word for
// word), every picture exists and no colour or backdrop marks the safe card
// (in any hand the dealer can make), the pictures show what each card claims,
// the rival's myth is the lesson's own and every spoken line is listed for
// recording, a clean play (picks, reasons, the rival's myth) clears the rung,
// a miss on every round with a wrong myth reason fails it (the board's
// strike-out), a wrong pick says the trap's own reason and opens no reason
// deck, the gesture hint sweeps without pressing, and the board waits quietly
// once dealt.
//
// Boards have no deadly freeze (kit design, GAME_DEVELOPER_GUIDE §10c), and
// lesson 7.1 has no deadly act at all (ruling M7-6): a cut earth lead seen
// here is a slip — nothing is being charged.
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
import 'package:slm_flutter/features/game/learn_board_pack71.dart';
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

const pack = learnBoardPack71;
const _artDir = 'assets/game/art/m7_board71';
const _rung = '7.1/learn';
const _ladder = 183; // m7 starts after the 183 rungs of Modules 1–6; 7.1/learn is its first

/// Has read lesson 7.1 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_1', '7.1']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.1', ladderIndex: _ladder, pack: pack, muted: true),
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
/// হ্যাঁ to "সেটা কি ভুল?"); then a reason.
Future<void> _beatTheRival(WidgetTester t, {bool wrongReasonFirst = false}) async {
  final myth = pack.myth;
  bool asked() => find.text('বিশ্বাস করেন?').evaluate().isNotEmpty || find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  await _pumpUntil(t, () => find.text(myth.rivalLineBn).evaluate().isNotEmpty || asked(), what: 'the rival\'s myth');
  expect(find.text(myth.rivalLineBn), findsWidgets, reason: 'the rival speaks before the guide asks');
  await _pumpUntil(t, asked, what: 'the believe question');
  await t.pump(const Duration(milliseconds: 800));
  final flipped = find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  await t.tap(find.text(flipped ? 'হ্যাঁ' : 'না').last);
  await t.pump();
  if (wrongReasonFirst) {
    await _tapDealt(t, 'why', _ids(myth.whyChips, correct: false), 'a wrong myth reason');
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }
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

/// A lesson quote as it reads on screen: one nukta form, English digits, and
/// the lesson's quote marks around a term dropped.
String _screen(String s) {
  const bn = '০১২৩৪৫৬৭৮৯';
  var out = _norm(s).replaceAll("'", '');
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(bn[i], '$i');
  }
  return out;
}

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.1');
}

Map<String, dynamic> get _content => _lesson()['content'] as Map<String, dynamic>;

List<Map<String, dynamic>> get _points => [
      for (final s in (_content['sections'] as List<dynamic>).cast<Map<String, dynamic>>())
        ...(s['points'] as List<dynamic>).cast<Map<String, dynamic>>(),
    ];

List<Map<String, dynamic>> get _myths =>
    ((_content['myth_buster'] as Map<String, dynamic>)['myths'] as List<dynamic>).cast<Map<String, dynamic>>();

List<String> get _proTips =>
    [for (final t in ((_content['pro_tip'] as Map<String, dynamic>)['content'] as List<dynamic>).cast<String>()) _screen(t)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
    SpokenOnce.resetForTest();
  });

  test('the lesson 7.1 board: five rounds from the lesson (ruling X6)', () {
    expect(pack.lessonId, '7.1');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.1 entry.
    final registered = learnBoardPackFor('7.1');
    if (registered != null) expect(registered, same(learnBoardPack71));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm((lesson['content'] as Map)['level_title'] as String), reason: 'owner XL7.1-T1: the new live level title');
    expect(pack.titleBn, 'ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন: আপনার বাইবেল', reason: 'owner XL7.1-T1');
    expect(pack.titleBn, allOf(isNot(contains('ইন্ডিয়ান')), isNot(contains('রুলস'))), reason: 'no repealed names (XL7.1-T1)');
    expect(pack.slots.map((s) => s.id), ['book', 'plate', 'earth', 'person', 'ask'], reason: 'X6: 5 rounds');
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
      expect(s.promptBn, isNot('সঠিক জিনিস বেছে নিন'), reason: '${s.id}: specific prompt');
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
  });

  test('every round: safe pictures and enough traps, each trap says why', () {
    for (final s in pack.slots) {
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

  test('the lesson\'s points: the rulebook, Reg 20, Reg 43 ও 50, Reg 3, the right to question', () {
    final pts = _points;
    final briefing = _screen(_content['mission_briefing'] as String);
    final spec1 = _screen(pts[0]['specifications'] as String);
    final spec2 = _screen(pts[1]['specifications'] as String);
    final tip2 = _screen(pts[1]['safety_tip'] as String);
    final regs = _screen(pts[2]['specifications'] as String);
    final tips = _proTips;
    // Book: the rulebook's two parts (briefing); for every worker and
    // contractor (point 2's safety tip, word for word).
    expect(_safeIds('book'), {'act', 'cea'});
    // The traps show the right books mistreated (locked away, left in a
    // file), so the round asks how the rulebook is kept, never which document.
    expect(_slot('book').promptBn, allOf(contains('নিয়ম ঠিকভাবে মানা'), isNot(contains('কোন নথি'))));
    expect(briefing, allOf(contains('ইলেকট্রিসিটি অ্যাক্ট, 2003'), contains('এগুলো শুধু ইঞ্জিনিয়ার বা ম্যানেজারদের জন্য নয়')));
    expect(spec1, contains('ভারতের বিদ্যুৎ সংক্রান্ত মূল আইন'));
    expect(_opt('book', 'act').labelBn, contains('ইলেকট্রিসিটি অ্যাক্ট, 2003'));
    expect(_reject('book', 'locked'), allOf(contains('ইঞ্জিনিয়ার বা ম্যানেজারদের জন্য নয়'), contains('ফিল্ড কর্মীদের সুরক্ষার জন্যই তৈরি')));
    expect(_reject('book', 'contract'), tip2, reason: 'point 2\'s safety tip, word for word');
    expect(spec2, contains('আপনার কাজের জন্য সবচেয়ে গুরুত্বপূর্ণ নথি'));
    expect(_reject('book', 'dusty'), contains('আপনার কাজের জন্য সবচেয়ে গুরুত্বপূর্ণ নথি'));
    // Plate: Reg 20 — a danger plate on every installation.
    expect(regs, contains('রেগুলেশন 20 (বিপজ্জনক নোটিশ)'));
    expect(regs, contains('একটি বিপদ চিহ্ন বা ডেঞ্জার প্লেট লাগানো বাধ্যতামূলক'));
    expect(_safeIds('plate'), {'dtr', 'pillar'});
    expect(_reject('plate', 'dtrbare'), allOf(startsWith('রেগুলেশন 20'), contains('একটি বিপদ চিহ্ন বা ডেঞ্জার প্লেট লাগানো বাধ্যতামূলক')));
    expect(_reject('plate', 'pillarbare'), contains('বাধ্যতামূলক'));
    expect(_reject('plate', 'ground'), contains('গায়ে লাগানো'));
    // Earth: Reg 43 ও 50 — every metal body and the system's neutral.
    expect(regs, allOf(contains('রেগুলেশন 43 ও 50 (আর্থিং)'), contains('ধাতব বডি এবং সিস্টেমের নিউট্রালকে সঠিকভাবে আর্থিং করা বাধ্যতামূলক')));
    expect(_safeIds('earth'), {'dtr', 'pillar'});
    expect(_opt('earth', 'dtr').labelBn, allOf(contains('বডি'), contains('নিউট্রাল')));
    expect(_reject('earth', 'bodycut'), contains('রেগুলেশন 43 ও 50'));
    expect(_reject('earth', 'neutral'), contains('নিউট্রালকেও সঠিকভাবে আর্থিং করা বাধ্যতামূলক'));
    expect(_reject('earth', 'pillarnone'), contains('সমস্ত যন্ত্রপাতির ধাতব বডি'));
    // Person: Reg 3 — trained AND authorized.
    expect(regs, contains('শুধুমাত্র উপযুক্ত বা প্রশিক্ষিত এবং অনুমোদিত ব্যক্তিই বিদ্যুৎ লাইনে কাজ করতে পারবেন'));
    expect(_safeIds('person'), {'id', 'cert'});
    expect(_reject('person', 'son'), contains('প্রশিক্ষিত এবং অনুমোদিত ব্যক্তিই বিদ্যুৎ লাইনে কাজ করতে পারবেন'));
    expect(_reject('person', 'trained'), contains('প্রশিক্ষিত এবং অনুমোদিত'));
    expect(_opt('person', 'cert').labelBn, allOf(contains('সার্টিফিকেট'), contains('অনুমোদন')));
    expect(_opt('person', 'id').labelBn, allOf(contains('প্রশিক্ষিত'), contains('অনুমোদনপত্র')),
        reason: 'the safe ID card names both halves of Reg 3');
    expect(_opt('person', 'trained').labelBn, allOf(contains('সার্টিফিকেট'), contains('অনুমোদন নেই')));
    // Ask: pro tips 1–4.
    expect(_safeIds('ask'), {'super', 'store'});
    expect(tips[3], contains('প্রশ্ন করার অধিকার আছে'));
    expect(_reject('ask', 'silent'), allOf(contains('প্রশ্ন করার অধিকার আপনার আছে'), contains('সুপারভাইজারের সাথে কথা বলুন')));
    expect(tips[1], endsWith(_reject('ask', 'nokit')), reason: 'pro tip 2, word for word');
    expect(tips[2], allOf(contains('আমি আইনটি জানতাম না'), contains('অজুহাত হিসেবে গৃহীত হয় না'), contains('পেশাগত দায়িত্ব')));
    expect(_opt('ask', 'excuse').labelBn, isNot(contains('দুর্ঘটনার পর')), reason: 'a choice made now, not after an accident');
    expect(_reject('ask', 'excuse'), allOf(contains('আমি আইনটি জানতাম না'), contains('অজুহাত হিসেবে গৃহীত হয় না'), contains('পেশাগত দায়িত্ব')));
    expect(tips[0], contains('বোঝা চাপানোর জন্য নয়'));
    expect(_reject('ask', 'burden'), allOf(contains('বোঝা চাপানোর জন্য নয়'), contains('সাধারণ মানুষকে')));
    expect(pack.earnedBn, allOf(contains('ডেঞ্জার প্লেট'), contains('আর্থিং'), contains('উপযুক্ত ব্যক্তি'), contains('প্রশ্ন')));
  });

  test('ruling X3: the live CEA 2023 numbers, no old regulation numbers, no age rule', () {
    expect(_slot('plate').promptBn, contains('রেগুলেশন 20'));
    expect(_slot('earth').promptBn, contains('রেগুলেশন 43 ও 50'));
    expect(_slot('person').promptBn, contains('রেগুলেশন 3'));
    final reg = RegExp(r'রেগুলেশন (\d+)');
    for (final l in _allText()) {
      for (final m in reg.allMatches(l)) {
        expect(['3', '20', '43'], contains(m.group(1)), reason: '"$l": the live numbers only (3 / 20 / 43 ও 50), never 15 / 18 / 32');
      }
      for (final no in ['18 বছর', 'বয়স', 'নাবালক']) {
        expect(l, isNot(contains(_norm(no))), reason: '"$l": no age rule in the live lesson (X3)');
      }
    }
  });

  test('ruling M7-5: unfit-person traps say it breaks the law, never that it is allowed', () {
    for (final id in ['son', 'trained', 'helper', 'mistri']) {
      expect(_reject('person', id), anyOf(contains('আইন'), contains('রেগুলেশন 3')), reason: id);
    }
    expect(_reject('person', 'trained'), contains('আইনভঙ্গ'));
    expect(_reject('person', 'helper'), contains('আইনে নিষেধ'));
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's.
  test('right reasons fit every safe pick of their round', () {
    String rights(String slot) => [for (final w in _slot(slot).whyChips) if (w.correct) w.textBn].join(' | ');
    for (final one in ['তাকে', 'হাতে', 'খোলা']) {
      expect(rights('book'), isNot(contains(one)), reason: 'book: names one safe card only ($one)');
    }
    for (final one in ['দরজা']) {
      expect(rights('plate'), isNot(contains(one)), reason: 'plate: names one safe card only ($one)');
    }
    for (final one in ['ট্যাঙ্ক', 'পিলার']) {
      expect(rights('earth'), isNot(contains(one)), reason: 'earth: names one safe card only ($one)');
    }
    for (final one in ['ID', 'সার্টিফিকেট']) {
      expect(rights('person'), isNot(contains(one)), reason: 'person: names one safe card only ($one)');
    }
    for (final one in ['সুপারভাইজার', 'PPE', 'স্টোর']) {
      expect(rights('ask'), isNot(contains(one)), reason: 'ask: names one safe card only ($one)');
    }
    // Every right chip fits both safe picks: speaking up (pro tip 4) and
    // asking for what the job needs (pro tip 2), never questioning alone.
    for (final w in _slot('ask').whyChips.where((w) => w.correct)) {
      expect(w.textBn, isNot(contains('প্রশ্ন')), reason: 'ask/${w.id}: "question" fits the supervisor pick only');
    }
    expect(rights('ask'), allOf(contains('চেয়ে নিন'), contains('অধিকার')), reason: 'pro tip 2: the store pick has its right reason');
  });

  test('every picture exists (vector scenes from tool/m7_board71_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, '$_artDir/${s.id}_${o.id}.svg', reason: 'a card is named after its round and id');
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board71 folder is a card on the board', () {
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

  // What each card claims is drawn: the plate on the body (or on the ground),
  // the earth leads to their pits, the stamp on the authorization, the training
// seal on the trained man's papers.
  test('the pictures show what each card claims', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const plate = 'fill="#FAFAF5" stroke="#D8402F"'; // the danger plate's enamel and red rim
    const lead = 'stroke="#3E9B4F" stroke-width="2.6"'; // an earth lead
    const stamp = 'fill="none" stroke="#6A4FA0" stroke-width="1.3"'; // the office stamp
    const blankFoot = 'stroke-dasharray="1.5 1.5"'; // an unsigned letter's foot
    final seal = RegExp(r'<circle [^>]*fill="#C9A43A"/>'); // the brass training seal
    for (final c in ['plate_dtr', 'plate_pillar', 'plate_ground']) {
      expect(svg(c), contains(plate), reason: '$c: a danger plate');
    }
    for (final c in ['plate_dtrbare', 'plate_pillarbare']) {
      expect(svg(c), isNot(contains(plate)), reason: '$c: no plate');
    }
    expect(svg('plate_ground'), contains('rotate(12'), reason: 'plate_ground: the plate lies askew on the ground');
    expect(lead.allMatches(svg('earth_dtr')).length, 2, reason: 'earth_dtr: body and neutral leads');
    expect(lead.allMatches(svg('earth_pillar')).length, 1, reason: 'earth_pillar: the body lead');
    expect(lead.allMatches(svg('earth_bodycut')).length, 3, reason: 'earth_bodycut: the body lead in two pieces + the neutral');
    expect(lead.allMatches(svg('earth_neutral')).length, 2, reason: 'earth_neutral: the body lead + the loose neutral');
    expect(svg('earth_pillarnone'), isNot(contains(lead)), reason: 'earth_pillarnone: no lead');
    for (final c in ['person_id', 'person_cert']) {
      expect(svg(c), contains(stamp), reason: '$c: the authorization signed and stamped');
      expect(svg(c), contains(seal), reason: '$c: the training seal (trained AND authorized)');
    }
    expect(svg('person_trained'), contains(seal), reason: 'person_trained: trained');
    for (final c in ['person_son', 'person_helper', 'person_mistri']) {
      expect(svg(c), allOf(isNot(contains(seal)), isNot(contains(stamp))), reason: '$c: neither trained nor authorized');
    }
    expect(svg('person_trained'), allOf(isNot(contains(stamp)), contains(blankFoot)), reason: 'person_trained: authorization blank');
  });

  test('the careless lineman says the lesson\'s first myth, word for word (ruling M7-10); his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _norm(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1');
    expect(m.rivalLineBn, 'এসব আইনকানুন তো শুধু কাগজের জন্য, মাঠে কেউ মানে না।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the reality: ভুল');
    final reality = _screen(_myths[0]['reality'] as String);
    expect(reality, allOf(contains('CEA নিয়মাবলীকেই স্ট্যান্ডার্ড'), contains('জরিমানা থেকে শুরু করে জেল')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('জরিমানা থেকে জেল')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board71Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board71Lines.newRivalLines, M7Board71Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board71Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board71Lines.guideSpoken;
    expect(M7Board71Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 18 trap reasons + 5×3 right reasons + sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 18 + 15 + 1 + 3 + 1));
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

    testWidgets('a miss on every round and a wrong myth reason (the board\'s strike-out): below the pass line', (t) async {
      final c = await _open(t);
      for (final s in pack.slots) {
        await _tapDealt(t, 'pick', _ids(s.options, correct: false), '${s.id}: a trap');
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await _cleanRound(t, s);
      }
      await _beatTheRival(t, wrongReasonFirst: true);
      await _pumpUntil(t, () => find.byType(LevelFailPanel).evaluate().isNotEmpty, what: 'the fail panel');
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress[_rung], isNot('cleared'), reason: '6 of 12 clean = 50% < 60%');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a cut earth lead is a slip, never a freeze (ruling M7-6): the lesson\'s words, no reason deck', (t) async {
      final c = await _open(t);
      for (final s in pack.slots.takeWhile((s) => s.id != 'earth')) {
        await _cleanRound(t, s);
      }
      // The earth round has three traps and a hand of four, so every hand
      // holds the cut lead.
      final earth = _slot('earth');
      await _settleHand(t, 'pick', {'bodycut'}, 'earth: the cut-lead trap');
      await tapBoardCard(t, _dealt('pick', {'bodycut'}));
      await _pumpUntil(t, () => find.text(_reject('earth', 'bodycut')).evaluate().isNotEmpty, what: 'the trap\'s reason');
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in lesson 7.1 (M7-6)');
      for (final w in earth.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.1', ladderIndex: _ladder, pack: pack, muted: true),
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
