// Module 6 lesson 6.9 picture board ("এলটি ডিস্ট্রিবিউশন পিলার: শেষ প্রবেশদ্বার",
// rung 6.9/learn, pack learn_6_9): its content follows the board's rules, the
// Module 6 rulings (M6-8: one recap round + the new material, the 415 V myth;
// X4: pillar fuses, lugs and joints handled only on a dead board; the owner's
// term rules) and the lesson's points, every picture exists and no colour or
// backdrop marks the safe card (in any hand the dealer can make), the
// pictures show the isolation where the ruling asks for it, the rival's myth
// is the lesson's own and every spoken line is listed for recording, a clean
// play (picks, reasons, the rival's myth) clears the rung, a miss on every
// round with a wrong myth reason fails it (the board's strike-out), a wrong
// pick says the trap's own reason and opens no reason deck, the gesture hint
// sweeps without pressing, and the board waits quietly once dealt.
//
// Boards have no deadly freeze (kit design, GAME_DEVELOPER_GUIDE §10c): the
// deadly-class traps (a fuse pulled with the supply on, a bare hand because
// "it is only 415 V", water on a live joint) cost a ◆ and say the lesson's own
// words; the tests below pin those words.
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

const pack = learnBoardPack69;
const _artDir = 'assets/game/art/m6_board69';
const _rung = '6.9/learn';
const _ladder = 174;

/// Has read lesson 6.9 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_9', '6.9']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.9', ladderIndex: _ladder, pack: pack, muted: true),
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

/// The owner's term rules applied to a lesson quote: LT in English letters,
/// English digits, «ডেড» for a proven-dead line.
String _terms(String s) {
  const bn = '০১২৩৪৫৬৭৮৯';
  var out = _norm(s).replaceAll('এলটি', 'LT').replaceAll('মৃত', 'ডেড');
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(bn[i], '$i');
  }
  return out;
}

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '6.9');
}

Map<String, dynamic> get _content => _lesson()['content'] as Map<String, dynamic>;

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

  test('the lesson 6.9 board: one recap round plus the new material (ruling M6-8)', () {
    expect(pack.lessonId, '6.9');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 6.9 entry.
    final registered = learnBoardPackFor('6.9');
    if (registered != null) expect(registered, same(learnBoardPack69));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'যন্ত্র গুরু');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['pillar', 'thermal', 'fix', 'dead'], reason: 'M6-8: 4 rounds');
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
    }
    // LT / HT / kV in English letters; only the lesson's own title keeps «এলটি».
    for (final l in _allText().where((l) => l != pack.titleBn)) {
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

  test('the lesson\'s points: the pillar recap, the thermal scan, the fixes, the dead board', () {
    final pts = _points;
    final tips = [for (final t in _proTips) _norm(t)];
    final spec2 = _norm(pts[1]['specifications'] as String);
    final spec3 = _norm(pts[2]['specifications'] as String);
    final todo3 = _norm(pts[2].entries.firstWhere((e) => _norm(e.key) == _norm('করণীয়')).value as String);
    // Recap (M6-8 from spec rounds 0, 1, 4): own fuse per way, the bars, the
    // neutral link, armour and body on the earth terminal, R-Y-B, the door.
    // Every M6-8 idea kept, merged into 6 cards (owner answers after Wave A:
    // 4–6 picture cards a round): R-Y-B joins the inside picture, the neutral
    // through a fuse unit and the hanging armour are one 'wired wrong' trap.
    expect(_safeIds('pillar'), {'lane', 'inside', 'locked'});
    expect(_trapIds('pillar'), {'alldark', 'wiring', 'door'});
    expect(_opt('pillar', 'inside').labelBn, allOf(contains('R, Y, B'), contains('নিউট্রাল'), contains('আর্মার')));
    expect(_opt('pillar', 'locked').labelBn, contains('তালা'));
    expect(_opt('pillar', 'wiring').labelBn, allOf(contains('নিউট্রাল ফিউজ ইউনিটে'), contains('আর্মার ঝুলছে')));
    expect(spec2, contains('কমন নিউট্রাল লিঙ্কে'));
    expect(_reject('pillar', 'wiring'), contains('কমন নিউট্রাল লিঙ্কে'));
    expect(spec2, contains('কেবিলের আর্মারকে আর্থ'));
    expect(_reject('pillar', 'wiring'), contains('আর্থিং টার্মিনাল'));
    expect(_reject('pillar', 'alldark'), contains('শুধু সেই লাইনটাই বন্ধ'));
    expect(tips[0], contains('বাচ্চাদের'));
    expect(_reject('pillar', 'door'), allOf(contains('লক করা অত্যন্ত জরুরি'), contains('বাচ্চাদের')));
    // Thermal (spec round 2): pro tip 3 word for word on the eye-only trap.
    expect(_safeIds('thermal'), {'scan', 'black'});
    const early = 'চোখে দেখার আগেই লুজ কানেকশন বা হটস্পট';
    expect(tips[2], contains(early));
    expect(_reject('thermal', 'eye'), contains(early));
    expect(spec3, contains('কালো হয়ে যাওয়া'));
    expect(_reject('thermal', 'water'), allOf(contains('শর্ট সার্কিট'), contains('আর্ক ফ্ল্যাশ')));
    expect(_reject('thermal', 'touch'), contains('লাইভ প্যানেলের মতোই বিপজ্জনক'));
    // Fix (spec round 3; X4 on the lug): seal, nest, lug on a dead board.
    expect(_safeIds('fix'), {'seal', 'nest', 'lug'});
    expect(_reject('fix', 'fuse3'), allOf(contains('বারবার উড়ে যায়'), contains('লোড ব্যালেন্স করুন')));
    expect(todo3, allOf(contains('লোড ব্যালেন্স করুন'), contains('জল ঢোকার পথ বন্ধ করুন')));
    expect(_reject('fix', 'wipe'), contains('সিল'));
    expect(_reject('fix', 'gnaw'), contains('ইনসুলেশন কেটে'));
    // Dead (new, M6-8): lock + tag, the tester at 0, the HRC's quartz sand.
    expect(_safeIds('dead'), {'lock', 'test', 'sand'});
    expect(_opt('dead', 'sand').labelBn, contains('কোয়ার্টজ বালু'));
    final hrcFact = _norm(((_content['advanced_section'] as Map<String, dynamic>)['facts'] as List<dynamic>).first['content'] as String);
    expect(hrcFact, allOf(contains('কোয়ার্টজ বালু'), contains('শোষণ করে এবং নিভিয়ে দেয়')));
    expect(pack.earnedBn, allOf(contains('নিজের ফিউজে'), contains('LT OFF'), contains('ডেড প্রমাণ')));
  });

  test('the deadly-class traps say the lesson\'s own words (no freeze on a board)', () {
    final tip = _terms(_points[1]['safety_tip'] as String);
    // A fuse pulled on a live supply: the safety tip's last sentence word for word.
    expect(tip, contains('চালু সাপ্লাইয়ে ফিউজ ছোঁবেন না, টানবেনও না'));
    expect(_reject('dead', 'livepull'), startsWith('চালু সাপ্লাইয়ে ফিউজ ছোঁবেন না, টানবেনও না'));
    // Switch OFF but no lock, tag or test (N4): the tip's isolation sentence.
    expect(tip, contains(_reject('dead', 'nolock')));
    // "Only 415 V" bare hand: myth 1's reality (term rules applied).
    final reality = _terms(_myths[0]['reality'] as String);
    expect(reality, contains('415 ভোল্ট মারাত্মক শক দেওয়ার জন্য যথেষ্ট।'));
    expect(_reject('dead', 'bare'), startsWith('415 ভোল্ট মারাত্মক শক দেওয়ার জন্য যথেষ্ট।'));
    expect(_reject('dead', 'bare'), contains('আর্ক ফ্ল্যাশ'));
    // The live joint: a live panel (the safety tip's first sentence).
    expect(tip, contains('লাইভ প্যানেলের মতোই বিপজ্জনক'));
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's or one trap's.
  test('right reasons fit every safe pick of their round', () {
    final pillar = [for (final w in _slot('pillar').whyChips) if (w.correct) w.textBn];
    for (final t in pillar) {
      for (final one in ['দরজা', 'আর্মার', 'নিউট্রাল', 'R-Y-B', 'ফিউজে']) {
        expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
      }
    }
    final fix = [for (final w in _slot('fix').whyChips) if (w.correct) w.textBn];
    for (final t in fix) {
      expect(t, isNot(contains('সিল')), reason: '"$t": names one safe card only');
      expect(t, isNot(contains('ইঁদুর')), reason: '"$t": names one safe card only');
    }
    // Dead: lock, test and sand all answer the lesson's fault current and arc
    // (myth 1's reality), so every right chip says আর্ক and names no card.
    final dead = [for (final w in _slot('dead').whyChips) if (w.correct) w.textBn];
    for (final t in dead) {
      expect(t, contains('আর্ক'), reason: '"$t": the shared idea (fault current, arc) fits lock, test and sand');
      for (final one in ['বালু', 'তালা', 'ট্যাগ', 'টেস্টার', 'সুইচ']) {
        expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
      }
    }
    // Wrong chips stay general too: none is about one card's picture only.
    for (final w in _slot('dead').whyChips.where((w) => !w.correct)) {
      for (final one in ['বালু', 'তালা']) {
        expect(w.textBn, isNot(contains(one)), reason: '"${w.textBn}": a wrong reason for one card only ($one)');
      }
    }
    // One wording per idea across the decks (one clip each).
    final all = [
      for (final s in pack.slots) for (final w in s.whyChips) w.textBn,
      for (final w in pack.myth.whyChips) w.textBn,
    ];
    expect(all.toSet().length, all.length);
  });

  test('the Module 6 rulings: the dead board (X4), the 415 V myth (M6-8), no thick-wire myth', () {
    // X4: a lug is tightened only after the DTR LT switch OFF, lock-tag, tester.
    expect(_opt('fix', 'lug').labelBn, allOf(contains('LT OFF'), contains('তালা-ট্যাগ'), contains('টেস্টারে 0 V')));
    expect(_slot('fix').whyChips.any((w) => !w.correct && w.textBn.contains('চালু অবস্থাতেই')), isTrue,
        reason: 'the live-tightening idea is a wrong reason');
    expect(_opt('dead', 'lock').labelBn, allOf(contains('LT সুইচ OFF'), contains('তালা আর ট্যাগ')));
    expect(_opt('dead', 'test').labelBn, allOf(contains('লাইভ-ডেড-লাইভ'), contains('0 V')));
    // M6-8: the thick-wire myth lives only on board 6.3.
    for (final l in _allText()) {
      expect(l, isNot(contains('মোটা তার')), reason: '"$l": the thick-wire myth is board 6.3\'s');
    }
  });

  test('every picture exists (vector scenes from tool/m6_board69_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m6_board69 folder is a card on the board', () {
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

  // Ruling X4 in the pictures: hands on a pillar fuse, lug or joint only once
  // the DTR LT switch is OFF, padlocked and proved dead; the traps show it is
  // not. Pro tip 1: the finished pillar is padlocked.
  test('the pictures show the isolation on the safe cards and its absence on the traps', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const redOn = 'width="10" height="7" rx="1" fill="#D8402F"'; // the MCCB's ON window
    const greenOff = 'width="10" height="7" rx="1" fill="#3E9B4F"'; // its OFF window
    const padlockBody = 'width="10" height="8" rx="1.5" fill="#E5B92E"';
    const lcd = 'fill="url(#lcd)"';
    for (final c in ['dead_lock', 'dead_test']) {
      expect(svg(c), allOf(contains(greenOff), contains(padlockBody)), reason: '$c: OFF, padlocked and tagged');
    }
    expect(svg('dead_test'), contains(lcd), reason: 'dead_test: the tester');
    for (final c in ['dead_bare', 'dead_livepull']) {
      expect(svg(c), contains(redOn), reason: '$c: the supply is ON');
      expect(svg(c), isNot(contains(padlockBody)), reason: '$c: nothing locked');
    }
    expect(svg('dead_livepull'), contains('fill="url(#glow)"'), reason: 'dead_livepull: the arc');
    expect(svg('dead_nolock'), contains(greenOff), reason: 'dead_nolock: switched OFF…');
    expect(svg('dead_nolock'), isNot(contains(padlockBody)), reason: '…but no padlock or tag');
    // Fix round: every card is on a dead, locked board, so only the fix differs.
    for (final o in _slot('fix').options) {
      final c = 'fix_${o.id}';
      expect(svg(c), allOf(contains(greenOff), contains(padlockBody)), reason: '$c: the DTR LT switch OFF and padlocked');
    }
    expect(svg('fix_lug'), contains(lcd), reason: 'fix_lug: proved dead with the tester');
    // The finished pillar: padlocked on the safe card, wide open on the trap.
    expect(svg('pillar_locked'), contains(padlockBody));
    expect(svg('pillar_door'), isNot(contains(padlockBody)));
  });

  test('the careless lineman says the lesson\'s first myth (ruling M6-8); his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _terms(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1, term rules applied');
    expect(m.rivalLineBn, 'LT বক্সের ভেতরে তো শুধু 415 ভোল্ট থাকে, এটা তেমন বিপজ্জনক নয়।');
    expect(m.believeNoIsCorrect, isTrue, reason: '415 V is enough to kill; the fault current burns');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('আর্ক ফ্ল্যাশ')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board69Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M6Board69Lines.newRivalLines, M6Board69Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M6Board69Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M6Board69Lines.guideSpoken;
    expect(M6Board69Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 4 prompts + 13 trap reasons + 4×3 right reasons + sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 4 + 13 + 12 + 1 + 3 + 1));
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
      expect(save.rungProgress[_rung], isNot('cleared'), reason: '5 of 10 clean = 50% < 60%');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a deadly-class trap (a fuse pulled on a live supply) teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      for (final s in pack.slots.takeWhile((s) => s.id != 'dead')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is the safety tip word for word. The dead round has three
      // traps and a hand of four, so every hand holds it.
      final dead = _slot('dead');
      await _settleHand(t, 'pick', {'livepull'}, 'dead: the live-pull trap');
      await tapBoardCard(t, _dealt('pick', {'livepull'}));
      await _pumpUntil(t, () => find.text(_reject('dead', 'livepull')).evaluate().isNotEmpty, what: 'the safety tip');
      for (final w in dead.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.9', ladderIndex: _ladder, pack: pack, muted: true),
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
