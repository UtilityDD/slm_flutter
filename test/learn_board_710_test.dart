// Module 7 lesson 7.10 picture board ("একজন 'সার্টিফায়েড' লাইনম্যান: লাইসেন্স ও
// যোগ্যতার গুরুত্ব", rung 7.10/learn, pack learn_7_10): its content follows the
// board's rules, the live lesson (ruling X3: no age rule, the competent person
// needs a certificate or work permit, his name on the company register and
// training) and the Module 7 rulings (M7-5 an unfit man on line work breaks
// the law, M7-10 the myth word for word), every picture exists and no colour or
// backdrop marks the safe card (in any hand the dealer can make), the pictures
// show what each card claims, the rival's myth is the lesson's own and every
// spoken line is listed for recording, a clean play (picks, reasons, the
// rival's myth) clears the rung, a miss on every round with a wrong myth
// reason fails it (the board's strike-out), a wrong pick says the trap's own
// reason and opens no reason deck, the gesture hint sweeps without pressing,
// and the board waits quietly once dealt.
//
// Boards have no deadly freeze (kit design, GAME_DEVELOPER_GUIDE section 10c),
// and lesson 7.10's one deadly act (an uncertified man on energised live-line
// work) is do_7_10_a's (ruling M7-5), so no card here is deadly: a trap is a
// slip, worded as a breach of the law.
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
import 'package:slm_flutter/features/game/learn_board_pack710.dart';
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

const pack = learnBoardPack710;
const _artDir = 'assets/game/art/m7_board710';
const _rung = '7.10/learn';
const _ladder = 210; // m7 starts after the 183 rungs of Modules 1–6; 7.10/learn is its 28th (orderInModule 27)

/// Has read lesson 7.10 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_10', '7.10']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.10', ladderIndex: _ladder, pack: pack, muted: true),
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
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.10');
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


  test('the lesson 7.10 board: five rounds from the lesson (ruling X6)', () {
    expect(pack.lessonId, '7.10');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.10 entry.
    final registered = learnBoardPackFor('7.10');
    if (registered != null) expect(registered, same(learnBoardPack710));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm((lesson['content'] as Map)['level_title'] as String), reason: 'the live level title');
    expect(pack.slots.map((s) => s.id), ['comp', 'permit', 'paper', 'grow', 'habit'], reason: 'five rounds');
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

  test('the lesson\'s points: who is competent, the workman permit, the paper, training that never ends, the habits', () {
    final pts = _points;
    final spec1 = _screen(pts[0]['specifications'] as String);
    final imp1 = _screen(pts[0]['importance'] as String);
    final spec2 = _screen(pts[1]['specifications'] as String);
    final imp2 = _screen(pts[1]['importance'] as String);
    final spec3 = _screen(pts[2]['specifications'] as String);
    final tips = _proTips;
    final myth1 = _myths[0];
    final myth2 = _myths[1];
    // comp: point 1 — certificate or work permit, name on the register, training.
    expect(spec1, allOf(
      contains('সার্টিফিকেট অফ কম্পিটেন্সি বা ইলেকট্রিক্যাল ওয়ার্ক পারমিট'),
      contains('কোম্পানির রেজিস্টারে তার নাম থাকতে হবে'),
      contains('পর্যাপ্ত প্রশিক্ষণ ও অভিজ্ঞতা'),
      contains('বিপদগুলো চিনতে পারেন এবং তা এড়াতে পারেন'),
    ));
    expect(_slot('comp').promptBn, contains('উপযুক্ত'));
    expect(_safeIds('comp'), {'cert', 'aware'});
    expect(_opt('comp', 'cert').labelBn, allOf(contains('সার্টিফিকেট'), contains('রেজিস্টারে নাম')));
    expect(_opt('comp', 'noreg').labelBn, contains('রেজিস্টারে নামটাই নেই'));
    expect(imp1, endsWith(_reject('comp', 'new')), reason: 'point 1\'s importance line, word for word');
    expect(_reject('comp', 'strong'), allOf(contains('গায়ের জোর নয়'), contains('পর্যাপ্ত প্রশিক্ষণ ও অভিজ্ঞতা'), contains('বিপদ চিনে এড়াতে পারেন')));
    expect(imp1, contains('সঠিক প্রশিক্ষণ দিতে আইনত বাধ্য'));
    expect(_reject('comp', 'booklet'), allOf(contains('প্রশিক্ষণ দিতে'), contains('আইনত বাধ্য')));
    expect(_reject('comp', 'noreg'), allOf(contains('রেজিস্টারে নাম থাকতেই হবে'), contains('আইনের লঙ্ঘন')));
    // permit: point 2 — a state licensing board; ITI, years of work, an exam or interview.
    expect(spec2, allOf(
      contains('রাজ্য সরকারের লাইসেন্সিং বোর্ড'),
      contains('ওয়ার্কম্যান পারমিট'),
      contains('ITI'),
      contains('নির্দিষ্ট বছরের কাজের অভিজ্ঞতা'),
      contains('পরীক্ষা বা ইন্টারভিউ পাশ'),
    ));
    expect(spec2, contains('ভারতের অনেক রাজ্যে'), reason: 'the lesson hedges: many states, "সাধারণত" — so is the prompt');
    expect(_slot('permit').promptBn, contains('সাধারণ'));
    expect(_safeIds('permit'), {'path', 'board'});
    expect(_opt('permit', 'path').labelBn, allOf(contains('ITI'), contains('কাজের বছর'), contains('পরীক্ষা')));
    expect(_opt('permit', 'board').labelBn, allOf(contains('লাইসেন্সিং বোর্ড'), contains('ইন্টারভিউ')));
    expect(_reject('permit', 'expnoexam'), allOf(contains('অভিজ্ঞতার সাথে'), contains('পরীক্ষা বা ইন্টারভিউ পাশও লাগে')));
    expect(_reject('permit', 'examnoexp'), allOf(contains('নির্দিষ্ট বছরের কাজের অভিজ্ঞতাও লাগে'), contains('শুধু পরীক্ষায়')));
    expect(_reject('permit', 'compid'), allOf(contains('রাজ্য সরকারের লাইসেন্সিং বোর্ড'), contains('কোম্পানির পরিচয়পত্র নয়')));
    // paper: point 2's importance line — the permit is the proof, a must for many big contractors.
    expect(imp2, allOf(contains('আইনত যোগ্য এবং দক্ষ'), contains('আবশ্যক শর্ত'), contains('বিশ্বাসযোগ্যতা')));
    expect(_safeIds('paper'), {'permit', 'withiti'});
    expect(_opt('paper', 'permit').labelBn, contains('ওয়ার্কম্যান পারমিট'));
    expect(_reject('paper', 'firstaid'), allOf(contains('ফার্স্ট এইড'), contains('ওয়ার্কম্যান পারমিট')));
    expect(_reject('paper', 'word'), allOf(contains('মুখের কথা নয়'), contains('আইনত যোগ্য ও দক্ষ')));
    expect(_reject('paper', 'iti'), allOf(contains('একটা যোগ্যতা মাত্র'), contains('অভিজ্ঞতা আর পরীক্ষা')));
    expect(_slot('paper').whyChips.any((w) => w.correct && w.textBn.contains('আবশ্যক শর্ত')), isTrue);
    // grow: point 3's three examples and pro tip 2; myth 1's reality.
    expect(spec3, allOf(
      contains('লাইভ লাইন কাজের প্রশিক্ষণ'),
      contains('কেবিল জয়েন্টিং-এর সার্টিফিকেশন'),
      contains('ফার্স্ট এইড এবং ফায়ার সেফটি ট্রেনিং'),
      contains('নতুন সরঞ্জাম, নতুন সুরক্ষা নিয়ম'),
      contains('নিজের জ্ঞান এবং দক্ষতাকে আপডেট রাখা'),
    ));
    expect(_safeIds('grow'), {'live', 'hv', 'aid'});
    expect(_opt('grow', 'live').labelBn, contains('লাইভ লাইন'));
    expect(_opt('grow', 'hv').labelBn, allOf(contains('HV'), contains('জয়েন্টিং')));
    expect(_opt('grow', 'aid').labelBn, allOf(contains('CPR'), contains('ট্রেনিং')));
    expect(tips[1], contains('এই সুযোগগুলো কখনো হাতছাড়া করবেন না'));
    expect(_reject('grow', 'skip'), contains('সুযোগ কখনো হাতছাড়া করবেন না'));
    expect(_reject('grow', 'old'), allOf(contains('নতুন সরঞ্জাম'), contains('আপডেট না থাকলে'), contains('কাজের মান ও সুরক্ষা কমে')));
    expect(_screen(myth1['reality'] as String), contains('শেখার কোনো শেষ নেই'));
    expect(_reject('grow', 'knowall'), allOf(contains('শেখার কোনো শেষ নেই'), contains('পিছিয়ে পড়বেন')));
    // habit: pro tips 1–4 and myth 2's reality.
    expect(tips[0], contains('লক্ষ্য'));
    expect(tips[2], allOf(contains('লগবুক'), contains('ইন্টারভিউ')));
    expect(tips[3], contains('প্রশ্ন করতে কখনো লজ্জা পাবেন না'));
    expect(_safeIds('habit'), {'log', 'senior', 'goal'});
    expect(_opt('habit', 'log').labelBn, contains('লগবুক'));
    expect(_opt('habit', 'goal').labelBn, contains('কেবিল জয়েন্টিং'));
    expect(_reject('habit', 'norec'), allOf(contains('কী কাজ, কোন প্রকল্প, কোন প্রশিক্ষণ'), contains('লগবুকে লিখুন'), contains('ইন্টারভিউ')));
    expect(_reject('habit', 'shy'), allOf(contains('জ্ঞানের ভান্ডার'), contains('প্রশ্ন করতে কখনো লজ্জা পাবেন না')));
    final reality2 = _screen(myth2['reality'] as String);
    expect(reality2, allOf(contains('অভিজ্ঞতা অপরিহার্য'), contains('আইনগত স্বীকৃতি')));
    expect(_reject('habit', 'paper'), allOf(contains('অভিজ্ঞতা অপরিহার্য'), contains('আইনগত স্বীকৃতি')));
    expect(pack.earnedBn, allOf(contains('সার্টিফিকেট'), contains('রেজিস্টারে নাম'), contains('প্রশিক্ষণ'), contains('লগবুক')));
  });

  test('ruling X3 and M7-5: no age rule anywhere; an unfit man on line work breaks the law, never allowed', () {
    for (final l in _allText()) {
      for (final no in ['18', 'বয়স', 'নাবালক', 'কিশোর', 'স্কুল', 'বছরের বেশি']) {
        expect(l, isNot(contains(no)), reason: '"$l": the live lesson 7.10 has no age rule (X3, O2)');
      }
      for (final no in ['ডিও', 'DO ', 'ড্রপ আউট']) {
        expect(l, isNot(contains(no)), reason: '"$l": no DO anywhere in Module 7 (M7-9)');
      }
    }
    // The three mis-assignment traps say 'law' in the lesson's own words.
    for (final id in ['new', 'booklet', 'noreg']) {
      expect(_reject('comp', id), anyOf(contains('আইনের লঙ্ঘন'), contains('আইনত বাধ্য')), reason: id);
    }
    // No deadly on this board: the only deadly act of 7.10 (energised live-line
    // work by an uncertified man) is do_7_10_a's; here the live-line card is a
    // course the player may take, never an assignment.
    expect(_opt('grow', 'live').labelBn, contains('ক্লাস'));
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's.
  test('right reasons fit every safe pick of their round', () {
    String rights(String slot) => [for (final w in _slot(slot).whyChips) if (w.correct) w.textBn].join(' | ');
    for (final one in ['সিনিয়র', 'ডেঞ্জার প্লেট', 'সরানো']) {
      expect(rights('comp'), isNot(contains(one)), reason: 'comp: names one safe card only ($one)');
    }
    for (final one in ['ITI', 'টেবিল']) {
      expect(rights('permit'), isNot(contains(one)), reason: 'permit: names one safe card only ($one)');
    }
    for (final one in ['ITI', 'কার্ড']) {
      expect(rights('paper'), isNot(contains(one)), reason: 'paper: names one safe card only ($one)');
    }
    for (final one in ['লাইভ', 'HV', 'CPR', 'ফার্স্ট এইড']) {
      expect(rights('grow'), isNot(contains(one)), reason: 'grow: names one safe card only ($one)');
    }
    for (final one in ['লগবুক', 'সিনিয়র', 'কেবিল', 'কোর্স']) {
      expect(rights('habit'), isNot(contains(one)), reason: 'habit: names one safe card only ($one)');
    }
  });

  test('every picture exists (vector scenes from tool/m7_board710_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, '$_artDir/${s.id}_${o.id}.svg', reason: 'a card is named after its round and id');
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board710 folder is a card on the board', () {
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

  // What each card claims is drawn: the register row with and without his
  // photo, the stamp on the permit, the long record in the logbook, the ticks
  // on the exam sheet, the red ring round the course notice.
  test('the pictures show what each card claims', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const plate = 'fill="#FAFAF5" stroke="#D8402F"'; // the danger plate's enamel and red rim
    const emptyRow = 'stroke-dasharray="2 2"'; // his missing row on the register
    final photo = RegExp(r'<circle [^>]*r="4" fill="#A86E48"/>'); // a name row's photo
    final stamp = RegExp(r'<circle [^>]*fill="none" stroke="#6A4FA0"'); // the permit's office stamp
    final longRecord = RegExp('stroke="#4A5560" stroke-width="0.7"'); // a logbook's written lines
    final ticks = RegExp('stroke="#3E9B4F" stroke-width="1"'); // answer-sheet ticks
    final seal = RegExp(r'<circle [^>]*fill="#C9A43A"/>'); // the brass seal
    final ring = RegExp('<ellipse [^>]*stroke="#D8402F" stroke-width="2.4"'); // the red ring round a notice
    final frames = RegExp('stroke="#C9A43A" stroke-width="2.4"'); // a framed certificate
    final hotStick = RegExp('stroke="#FFD34E" stroke-width="3.2"'); // the insulated rod
    // comp: the danger plate is shared by the traps (it cannot mark the safe card).
    expect(svg('comp_aware'), contains(plate), reason: 'comp_aware: he points at the danger plate');
    expect(svg('comp_new'), contains(plate));
    expect(svg('comp_strong'), contains(plate));
    // comp: every register row of the safe card has a photo; the noreg card's row is empty.
    expect(photo.allMatches(svg('comp_cert')).length, 4, reason: 'comp_cert: his name is on the register');
    expect(photo.allMatches(svg('comp_noreg')).length, 3, reason: 'comp_noreg: one row is empty');
    expect(svg('comp_noreg'), contains(emptyRow), reason: 'comp_noreg: his row is a dashed empty box');
    expect(svg('comp_cert'), isNot(contains(emptyRow)));
    for (final c in ['comp_cert', 'comp_noreg']) {
      expect(seal.hasMatch(svg(c)), isTrue, reason: '$c: a certificate in hand (so it cannot mark the safe card)');
    }
    // permit: a long logbook on the path card and on the experience-only trap,
    // a blank one on the exam-only trap, ticks on the exam sheets that are done.
    expect(longRecord.hasMatch(svg('permit_path')), isTrue, reason: 'permit_path: years of work written down');
    expect(longRecord.hasMatch(svg('permit_expnoexam')), isTrue, reason: 'permit_expnoexam: a long record');
    expect(longRecord.hasMatch(svg('permit_examnoexp')), isFalse, reason: 'permit_examnoexp: an empty logbook');
    expect(ticks.hasMatch(svg('permit_path')), isTrue, reason: 'permit_path: the exam done');
    expect(ticks.hasMatch(svg('permit_expnoexam')), isFalse, reason: 'permit_expnoexam: a blank sheet pushed away');
    expect(ticks.hasMatch(svg('permit_examnoexp')), isTrue, reason: 'permit_examnoexp: the exam passed');
    // paper: the permit's stamp on the safe cards only; the ID card has none.
    for (final c in ['paper_permit', 'paper_withiti']) {
      expect(stamp.hasMatch(svg(c)), isTrue, reason: '$c: the permit card is stamped');
    }
    for (final c in ['paper_firstaid', 'paper_word', 'paper_iti', 'permit_compid']) {
      expect(stamp.hasMatch(svg(c)), isFalse, reason: '$c: no permit card');
    }
    // grow: the insulated rod on the live-line class; the course notice has no ring here.
    expect(hotStick.hasMatch(svg('grow_live')), isTrue, reason: 'grow_live: an insulated rod to the line');
    for (final c in ['grow_skip', 'grow_old', 'grow_knowall', 'grow_hv', 'grow_aid']) {
      expect(hotStick.hasMatch(svg(c)), isFalse, reason: c);
    }
    // habit: the circled course notice, a written logbook, a wall of six frames.
    expect(ring.hasMatch(svg('habit_goal')), isTrue, reason: 'habit_goal: the course notice circled in red');
    expect(longRecord.hasMatch(svg('habit_log')), isTrue, reason: 'habit_log: the day\'s work written down');
    expect(frames.allMatches(svg('habit_paper')).length, 6, reason: 'habit_paper: a wall of framed certificates');
    for (final c in ['habit_norec', 'habit_shy', 'habit_senior']) {
      expect(frames.hasMatch(svg(c)), isFalse, reason: c);
    }
  });

  test('the careless lineman says the lesson\'s first myth, word for word (ruling M7-10); his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _norm(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1');
    expect(m.rivalLineBn, 'একবার কাজ শিখে গেলে আর নতুন করে শেখার কিছু নেই।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the reality: ভুল');
    final reality = _screen(_myths[0]['reality'] as String);
    expect(reality, allOf(contains('প্রযুক্তি এবং সুরক্ষার নিয়ম প্রতিদিন পাল্টাচ্ছে'), contains('কাজের মান ও সুরক্ষার স্তরও কমে যায়')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('প্রতিদিনই পাল্টাচ্ছে')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('কাজের মান ও সুরক্ষা কমে')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board710Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board710Lines.newRivalLines, M7Board710Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board710Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board710Lines.guideSpoken;
    expect(M7Board710Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 16 trap reasons + 5×3 right reasons + sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 16 + 15 + 1 + 3 + 1));
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

    testWidgets('a trap (the company ID shown as a permit) is a slip, never a freeze (M7-5): the lesson words, no reason deck', (t) async {
      final c = await _open(t);
      for (final s in pack.slots.takeWhile((s) => s.id != 'permit')) {
        await _cleanRound(t, s);
      }
      // The permit round has three traps and a hand of four, so every hand
      // holds the company-ID trap.
      final permit = _slot('permit');
      await _settleHand(t, 'pick', {'compid'}, 'permit: the company-ID trap');
      await tapBoardCard(t, _dealt('pick', {'compid'}));
      await _pumpUntil(t, () => find.text(_reject('permit', 'compid')).evaluate().isNotEmpty, what: 'the trap\'s reason');
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly card on board 7.10 (M7-5)');
      for (final w in permit.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.10', ladderIndex: _ladder, pack: pack, muted: true),
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
