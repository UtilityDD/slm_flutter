// Module 7 lesson 7.6 picture board ("ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) সংক্রান্ত
// আইন", rung 7.6/learn, pack learn_7_6): its content follows the board's
// rules, the Module 7 rulings (M7-2: torn or wrongly rated gloves are the
// module's deadly-class trap, boards teach and never freeze; M7-10: the
// lesson's myth word for word; X3 / O3: the 11 kV glove is IS 4770 type 4,
// never "11 kV gloves"; X6: 5 rounds, the owner's term rules) and the lesson's
// points (the employer supplies the PPE, the glove by the job's risk, the IS
// mark and codes, the worker's duties, size-training-record), every picture
// exists and no colour, backdrop, prop or figure marks the safe card (in any
// hand the dealer can make), the rival's myth is the lesson's own and every
// spoken line is listed for recording, a clean play (picks, reasons, the
// rival's myth) clears the rung, a miss on every round fails it (the board's
// strike-out), a trap teaches with the lesson's words, opens no reason deck and
// never freezes the board (boards have no freeze: kit design,
// GAME_DEVELOPER_GUIDE §10c), the gesture hint sweeps without pressing, and
// the board waits quietly once dealt.
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
import 'package:slm_flutter/features/game/learn_board_pack76.dart';
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

const pack = learnBoardPack76;
const _artDir = 'assets/game/art/m7_board76';
const _rung = '7.6/learn';
const _ladder = 198; // m7 starts at 183; 7.6/learn is its 16th rung (orderInModule 15)

/// Has read lesson 7.6 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_6', '7.6']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.6', ladderIndex: _ladder, pack: pack, muted: true),
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
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.6');
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


  test('the lesson 7.6 board: five rounds, as the item spec has them', () {
    expect(pack.lessonId, '7.6');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.6 entry.
    final registered = learnBoardPackFor('7.6');
    if (registered != null) expect(registered, same(learnBoardPack76));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['source', 'glove', 'mark', 'duty', 'size'], reason: '5 rounds');
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

  test('ruling X3 / O3: the 11 kV glove is IS 4770 type 4, never "11 kV gloves"; only the lesson\'s figures', () {
    for (final l in _allText()) {
      expect(l, isNot(contains('রেটেড')), reason: '"$l": no "rated glove" wording');
      expect(l, isNot(matches(RegExp(r'kV\s*(রেটেড\s*)?গ্লাভস'))), reason: '"$l": never "11 kV গ্লাভস"');
      expect(l, isNot(matches(RegExp(r'কেভি\s*(রেটেড\s*)?গ্লাভস'))), reason: l);
      // Every number on the board is one of the lesson's own.
      for (final n in RegExp(r'\d+(?:,\d{3})*').allMatches(l).map((m) => m.group(0)!)) {
        expect({'11', '4770', '4', '17,000', '2', '2925', '15298'}, contains(n), reason: '"$l": $n is not a figure of lesson 7.6 or ruling X3');
      }
      for (final no in ['ধারা', 'জরিমানা', 'কারাদণ্ড', 'জেল', 'আদালত', 'রেগুলেশন', 'Reg ']) {
        expect(l, isNot(contains(no)), reason: '"$l": no law figure the item does not play ($no)');
      }
    }
    // The glove answer is the type, in the chip and in the reasons.
    expect(_slot('glove').whyChips.any((w) => w.correct && w.textBn.contains('IS 4770 টাইপ 4')), isTrue);
    expect(_reject('glove', 'plain'), allOf(contains('IS 4770 টাইপ 4'), contains('17,000 ভোল্ট')));
    expect(_reject('glove', 'type2'), allOf(contains('IS 4770 টাইপ 4'), contains('টাইপ 2')));
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

  test('a card\'s name never gives the answer away: no IS code, type, mark or flaw in a label', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.labelBn, isNot(matches(RegExp(r'\d'))), reason: '${s.id}/${o.id}: no figures in a name');
        for (final tell in ['IS ', 'মার্ক', 'টাইপ', 'ছেঁড়া', 'ফাটা', 'কাদা', 'ঢিলা', 'ছোট', 'বড়', 'তারিখ']) {
          expect(o.labelBn, isNot(contains(tell)), reason: '${s.id}/${o.id}: "$tell" in the name');
        }
      }
    }
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

  test('the lesson\'s points: the source, the glove, the mark, the duties, size-training-record', () {
    final text = _lessonText;
    // Section 1 + myth 1 + pro tip 1: where the PPE comes from.
    expect(_safeIds('source'), {'store', 'van'});
    expect(_trapIds('source'), {'cash', 'market', 'empty'});
    expect(text, contains(_reject('source', 'cash')), reason: 'section 1 word for word');
    expect(text, contains(_reject('source', 'market')), reason: 'myth 1\'s reality word for word');
    expect(text, allOf(contains('কাজটি করতে অস্বীকার করার সম্পূর্ণ অধিকার আছে'), contains('আপনার জীবন সবচেয়ে মূল্যবান')));
    expect(_reject('source', 'empty'), allOf(contains('কাজটি করতে অস্বীকার করার সম্পূর্ণ অধিকার আছে'), contains('আপনার জীবন সবচেয়ে মূল্যবান')));
    // Section 1: PPE by the job's risk; 11 kV = IS 4770 type 4 (X3).
    expect(_safeIds('glove'), {'type4', 'store4'});
    expect(_trapIds('glove'), {'plain', 'type2', 'torn', 'shop'});
    expect(text, allOf(contains('কাজের ঝুঁকি অনুযায়ী সঠিক PPE সরবরাহ করা'), contains('যেমন ১১ কেভি লাইনের জন্য IS 4770 টাইপ ৪ গ্লাভস, যা ১৭,০০০ ভোল্ট পর্যন্ত কাজের জন্য তৈরি')));
    expect(_lessonForm(_reject('glove', 'plain')), allOf(contains('কাজের ঝুঁকি অনুযায়ী সঠিক PPE সরবরাহ করা'), contains('১১ কেভি লাইনের জন্য IS 4770 টাইপ ৪ গ্লাভস, যা ১৭,০০০ ভোল্ট পর্যন্ত কাজের জন্য তৈরি')));
    expect(text, contains(_lessonForm('IS 4770 টাইপ 4 গ্লাভস, যা 17,000 ভোল্ট পর্যন্ত কাজের জন্য তৈরি')));
    expect(_lessonForm(_reject('glove', 'type2')), contains('IS 4770 টাইপ ৪ গ্লাভস, যা ১৭,০০০ ভোল্ট পর্যন্ত কাজের জন্য তৈরি'));
    expect(text, contains('ক্ষতিগ্রস্ত বা মেয়াদ উত্তীর্ণ PPE বদলে দেওয়ার ব্যবস্থা করা'));
    expect(_reject('glove', 'torn'), contains('ক্ষতিগ্রস্ত বা মেয়াদ উত্তীর্ণ PPE বদলে দেওয়ার ব্যবস্থা করা'));
    expect(text, contains(_reject('glove', 'shop')), reason: 'section 3 word for word');
    // Section 3: the IS mark and the codes.
    expect(_safeIds('mark'), {'helmet', 'shoe'});
    expect(_trapIds('mark'), {'nomark', 'wrongcode', 'noshoe', 'shoecode'});
    expect(text, allOf(contains('IS মার্ক নিশ্চিত করে যে সরঞ্জামটি সুরক্ষার ন্যূনতম মানদণ্ড পূরণ করেছে'), contains('সেফটি হেলমেটের জন্য IS 2925 বা সেফটি জুতোর জন্য IS 15298'), contains('আপনার PPE-এর গায়ে এই IS মার্ক আছে কিনা তা দেখে নিন')));
    expect(_reject('mark', 'nomark'), contains('IS মার্ক নিশ্চিত করে যে সরঞ্জামটি সুরক্ষার ন্যূনতম মানদণ্ড পূরণ করেছে'));
    for (final o in ['wrongcode', 'shoecode']) {
      expect(_reject('mark', o), allOf(contains('সেফটি হেলমেটের জন্য IS 2925'), contains('সেফটি জুতোর জন্য IS 15298')), reason: o);
    }
    expect(_reject('mark', 'noshoe'), allOf(contains('সেফটি জুতোর জন্য IS 15298'), contains('আপনার PPE-এর গায়ে এই IS মার্ক আছে কিনা তা দেখে নিন')));
    // Section 2 + myth 2: the worker's duties.
    expect(_safeIds('duty'), {'clean', 'report', 'wear'});
    expect(_trapIds('duty'), {'mirror', 'crack', 'mud', 'senior'});
    expect(text, contains('কোম্পানি দ্বারা সরবরাহ করা PPE সঠিকভাবে এবং সবসময় ব্যবহার করা'));
    expect(_reject('duty', 'mirror'), contains('কোম্পানি দ্বারা সরবরাহ করা PPE সঠিকভাবে এবং সবসময় ব্যবহার করা'));
    expect(text, contains('PPE-তে কোনো ক্ষতি বা ত্রুটি দেখা গেলে অবিলম্বে সুপারভাইজারকে রিপোর্ট করা'));
    expect(_reject('duty', 'crack'), contains('PPE-তে কোনো ক্ষতি বা ত্রুটি দেখা গেলে অবিলম্বে সুপারভাইজারকে রিপোর্ট করা'));
    expect(text, contains('PPE-এর সঠিক যত্ন নেওয়া এবং সেটিকে পরিষ্কার রাখা'));
    expect(_reject('duty', 'mud'), contains('PPE-এর সঠিক যত্ন নেওয়া এবং সেটিকে পরিষ্কার রাখা'));
    expect(text, allOf(contains('আইন অনুযায়ী, ঝুঁকিপূর্ণ কাজে নিযুক্ত প্রত্যেক কর্মীর জন্য PPE বাধ্যতামূলক'), contains('অভিজ্ঞতা এবং নতুনত্বের মধ্যে কোনো পার্থক্য নেই')));
    expect(_reject('duty', 'senior'), allOf(contains('আইন অনুযায়ী, ঝুঁকিপূর্ণ কাজে নিযুক্ত প্রত্যেক কর্মীর জন্য PPE বাধ্যতামূলক'), contains('অভিজ্ঞতা এবং নতুনত্বের মধ্যে কোনো পার্থক্য নেই')));
    // Pro tips 2, 3, 4: size, record, training.
    expect(_safeIds('size'), {'fit', 'train', 'diary'});
    expect(_trapIds('size'), {'big', 'tight', 'newbox', 'blank'});
    expect(text, contains(_reject('size', 'big')), reason: 'pro tip 2 word for word');
    expect(text, contains(_reject('size', 'tight')), reason: 'pro tip 2 word for word');
    expect(text, allOf(contains('নতুন ধরনের PPE বা টুল'), contains('ব্যবহারের আগে সঠিক প্রশিক্ষণের দাবি জানান'), contains('এটিও আপনার অধিকার')));
    expect(_reject('size', 'newbox'), allOf(contains('নতুন ধরনের PPE বা টুল'), contains('ব্যবহারের আগে সঠিক প্রশিক্ষণের দাবি জানান'), contains('এটিও আপনার অধিকার')));
    expect(text, contains('তার একটি রেকর্ড (যেমন তারিখ এবং কাকে বলেছেন) নিজের কাছে রাখুন'));
    expect(_reject('size', 'blank'), allOf(contains('ক্ষতিগ্রস্ত PPE বদলানোর জন্য রিপোর্ট'), contains('তার একটি রেকর্ড (যেমন তারিখ এবং কাকে বলেছেন) নিজের কাছে রাখুন')));
    expect(pack.earnedBn, allOf(contains('কোম্পানির দায়িত্ব'), contains('IS মার্ক'), contains('ক্ষতি জানানো')));
  });

  test('ruling M7-2: torn or wrongly rated gloves are the board\'s deadly-class traps; the rest are slips', () {
    // R10: signing for, packing or keeping in use torn gloves, or gloves
    // with no 11 kV-grade type (IS 4770 type 4), is deadly in the levels;
    // boards have no freeze (kit design) so these teach. R12 slips: market
    // PPE, no mark, a wrong code, the wrong size, no training asked.
    for (final o in ['plain', 'type2', 'torn', 'shop']) {
      expect(_opt('glove', o).correct, isFalse, reason: o);
    }
    expect(_opt('source', 'market').correct, isFalse);
    // The coworker's push (the myth: buy cheap PPE yourself) is rejected.
    expect(pack.myth.believeNoIsCorrect, isTrue);
    // No DO and no AB stroke on this board (M7-9).
    for (final l in _allText()) {
      expect(l, isNot(contains('ডিও')), reason: l);
    }
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's or one trap's.
  test('right reasons fit every safe pick of their round', () {
    List<String> right(String slot) => [for (final w in _slot(slot).whyChips) if (w.correct) w.textBn];
    const onlyOne = {
      'source': ['স্টোর', 'ভ্যান', 'কাউন্টার', 'রেজিস্টার', 'জুতো'],
      'glove': ['স্টোরকিপার', 'ডকেট', 'ছেঁড়া'],
      'mark': ['হেলমেট নয়', 'শুধু জুতো', 'শুধু হেলমেট'],
      'duty': ['কিটব্যাগ', 'ধুয়ে', 'মুছে', 'ডায়েরি'],
      'size': ['ডায়েরি', 'হারনেস', 'ট্রেনার'],
    };
    for (final e in onlyOne.entries) {
      for (final t in right(e.key)) {
        for (final one in e.value) {
          expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
        }
      }
    }
  });

  test('every picture exists (vector scenes from tool/m7_board76_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board76 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => '$_artDir/${f.uri.pathSegments.last}')
        .toSet();
    expect(onDisk, used, reason: 'no unused art (delete the .gitkeep once art is in), no stray files (the APK ships the folder), no missing art');
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
  // lineman, the person who gives or checks (giver), the PPE itself, shelves,
  // the docket, the code plate, the IS mark... In every hand, nothing sits
  // only on the safe card, and nothing sits on every trap but not the safe
  // card (the odd one out would be the answer). What differs by design (a
  // tear, a diary's date) is drawn, not tagged.
  test('in every possible hand, no prop or figure marks the safe card', () {
    final tagRe = RegExp(r'<!--prop:(\w+)-->');
    final props = <String, Set<String>>{};
    Set<String> of(String asset) => props.putIfAbsent(
        asset, () => tagRe.allMatches(File(asset).readAsStringSync()).map((m) => m.group(1)!).toSet());

    for (final s in pack.slots) {
      final traps = s.options.where((o) => !o.correct).toList();
      for (final o in s.options) {
        expect(of(o.asset).intersection({'lineman', 'giver'}), isNotEmpty, reason: '${o.asset}: a worker on every card');
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

  // What each card's label says is drawn: the issue stock, the money, the
  // cuff label and type digit, the IS roundel, the plate codes, the tear, the
  // mud, the crack, the written diary.
  test('the pictures show what the labels say', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync();
    Set<String> props(String card) => RegExp(r'<!--prop:(\w+)-->').allMatches(svg(card)).map((m) => m.group(1)!).toSet();
    int count(String card, String s) => s.allMatches(svg(card)).length;
    // Source: the IS roundel on the issued and the bought-in-a-shop helmet
    // alike (the trap there is the money); none on the market helmet; an
    // empty shelf has no PPE at all; the note only on the cash card.
    for (final c in ['source_store', 'source_van', 'source_cash']) {
      expect(props(c), contains('ismark'), reason: c);
    }
    for (final c in ['source_market', 'source_empty']) {
      expect(props(c), isNot(contains('ismark')), reason: c);
    }
    expect(props('source_empty'), isNot(contains('ppe')), reason: 'source_empty: the shelf is bare');
    expect(svg('source_cash'), contains('#6FA36A'), reason: 'the bank note');
    for (final c in ['source_store', 'source_van', 'source_market', 'source_empty']) {
      expect(svg(c), isNot(contains('#6FA36A')), reason: '$c: no money');
    }
    // Glove: the docket (the number 11) on every card; the cuff label and the
    // IS roundel on the four marked pairs, none on the plain pair or the shop bag.
    for (final o in _slot('glove').options) {
      expect(props('glove_${o.id}'), contains('docket'), reason: o.id);
    }
    for (final c in ['glove_type4', 'glove_store4', 'glove_type2', 'glove_torn']) {
      expect(props(c), containsAll(['cuff', 'ismark']), reason: c);
    }
    for (final c in ['glove_plain', 'glove_shop']) {
      expect(props(c), isNot(contains('cuff')), reason: '$c: nothing written on the cuff');
      expect(props(c), isNot(contains('ismark')), reason: c);
    }
    expect(svg('glove_type2'), isNot(svg('glove_store4')), reason: 'the type digit differs (2 against 4)');
    expect(svg('glove_torn'), contains('M-9 -10 l4 -3'), reason: 'glove_torn: the tear across the palm');
    for (final c in ['glove_type4', 'glove_store4', 'glove_type2', 'glove_plain']) {
      expect(svg(c), isNot(contains('M-9 -10 l4 -3')), reason: '$c: whole gloves');
    }
    // Mark: the plate on every card, the roundel except on the two unmarked
    // items; helmets on the yard, shoes in the room.
    for (final o in _slot('mark').options) {
      expect(props('mark_${o.id}'), contains('plate'), reason: o.id);
    }
    for (final c in ['mark_helmet', 'mark_shoe', 'mark_wrongcode', 'mark_shoecode']) {
      expect(props(c), contains('ismark'), reason: c);
    }
    for (final c in ['mark_nomark', 'mark_noshoe']) {
      expect(props(c), isNot(contains('ismark')), reason: '$c: no IS mark on it');
    }
    for (final c in ['mark_shoe', 'mark_noshoe', 'mark_shoecode']) {
      expect(svg(c), contains('#5A3F2A'), reason: '$c: a shoe');
    }
    for (final c in ['mark_helmet', 'mark_nomark', 'mark_wrongcode']) {
      expect(svg(c), isNot(contains('#5A3F2A')), reason: '$c: a helmet');
    }
    expect(svg('mark_wrongcode'), isNot(svg('mark_shoe')));
    expect(svg('mark_shoecode'), isNot(svg('mark_helmet')));
    // Duty: gloved hands at the pole; the tear shown to the supervisor; the
    // crack; the mud; the grey-haired senior with a bare head.
    expect(count('duty_wear', 'r="4.6" fill="#D9622B"'), 2, reason: 'duty_wear: both hands gloved');
    for (final c in ['duty_mirror', 'duty_senior']) {
      expect(count(c, 'r="4.6" fill="#D9622B"'), 0, reason: '$c: bare hands');
    }
    expect(svg('duty_report'), contains('M-9 -10 l4 -3'), reason: 'duty_report: a torn glove');
    expect(svg('duty_crack'), contains('stroke-linejoin="round"/>'), reason: 'duty_crack: the crack line');
    expect(count('duty_mud', 'fill="#6B4A2E"/>'), greaterThanOrEqualTo(8), reason: 'duty_mud: mud on both gloves');
    expect(svg('duty_senior'), contains('#C9CCCF'), reason: 'duty_senior: grey hair');
    expect(props('duty_report'), contains('giver'));
    // Size: a snug and a loose glove, a snug and a tight boot, a trainer's
    // harness, the diary line with a date and a signature or with neither.
    expect(svg('size_big'), contains('opacity="0.95"'), reason: 'size_big: the empty finger ends flop over');
    expect(svg('size_fit'), isNot(contains('opacity="0.95"')));
    expect(svg('size_tight'), contains('M20 -5 q6 -1 7 -5'), reason: 'size_tight: toes poking out');
    expect(svg('size_fit'), isNot(contains('M20 -5 q6 -1 7 -5')));
    expect(props('size_train'), containsAll(['giver', 'ppe']));
    expect(svg('size_diary'), contains('q3 -7 6 0'), reason: 'size_diary: the signature');
    expect(svg('size_blank'), isNot(contains('q3 -7 6 0')), reason: 'size_blank: no name');
    expect(svg('size_diary').length, greaterThan(svg('size_blank').length), reason: 'size_diary: the date strokes too');
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _norm(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1 (ruling M7-10)');
    expect(m.rivalLineBn, 'কোম্পানি ভালো PPE দেয় না, তাই আমি বাজার থেকে সস্তার একটা কিনে ব্যবহার করি।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'cheap uncertified PPE is a false assurance');
    final reality = _norm(_myths[0]['reality'] as String);
    expect(reality, allOf(contains('কর্তৃপক্ষের কাছে রিপোর্ট করা উচিত'), contains('সুরক্ষার মিথ্যা আশ্বাস দেয় মাত্র')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('মিথ্যা আশ্বাস')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('রিপোর্ট')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line and the sting are already recorded; the new ones wait
    // for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board76Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board76Lines.newRivalLines, M7Board76Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board76Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board76Lines.guideSpoken;
    expect(M7Board76Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 19 trap reasons + 5×3 right reasons + sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 19 + 15 + 1 + 3 + 1));
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

    testWidgets('a trap (torn glove when dealt) teaches with the lesson words; no reason deck, no freeze', (t) async {
      final c = await _open(t);
      await _cleanRound(t, _slot('source'));
      // Boards have no freeze (kit design): a trap, even the deadly-class torn
      // glove (R10: signing for or packing it), costs the round's mark and
      // teaches with its reason. The glove round has four traps and a hand of
      // four, so a hand may not hold the torn glove; any trap shows the same.
      final glove = _slot('glove');
      final traps = _ids(glove.options, correct: false);
      await _settleHand(t, 'pick', traps, 'glove: a trap');
      final torn = _dealt('pick', {'torn'});
      final pick = torn.evaluate().isNotEmpty ? 'torn' : _dealtTrapId(glove);
      await tapBoardCard(t, _dealt('pick', {pick}));
      await _pumpUntil(t, () => find.text(_reject('glove', pick)).evaluate().isNotEmpty, what: 'the reason of the trap');
      expect(find.byType(FreezeFrame), findsNothing, reason: 'boards teach; they never freeze');
      for (final w in glove.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the "কেন" deck');
      }
      expect(find.byType(LevelFailPanel), findsNothing, reason: 'one miss does not end the board');
      // The board goes on: past the feedback, a fresh hand with a safe card.
      await continueBoard(t);
      await _cleanRound(t, glove);
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.6', ladderIndex: _ladder, pack: pack, muted: true),
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

/// The id of a trap card of [s] that is on the table right now.
String _dealtTrapId(LearnBoardSlot s) {
  for (final o in s.options) {
    if (!o.correct && _dealt('pick', {o.id}).evaluate().isNotEmpty) return o.id;
  }
  fail('no trap card dealt');
}

/// A board line in the lesson file's form: its figures as the lesson writes
/// them (11 kV = ১১ কেভি, type 4 = টাইপ ৪, 17,000 = ১৭,০০০).
String _lessonForm(String s) => s
    .replaceAll('11 kV', '১১ কেভি')
    .replaceAll('টাইপ 4', 'টাইপ ৪')
    .replaceAll('17,000', '১৭,০০০');
