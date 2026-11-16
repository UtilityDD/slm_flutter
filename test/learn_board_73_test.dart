// Module 7 lesson 7.3 picture board ("ন্যূনতম ক্লিয়ারেন্স: আইনত কতটা দূরত্ব?",
// rung 7.3/learn, pack learn_7_3): its content follows the board's rules, the
// Module 7 rulings (M7-7: HT side cards on 33 kV only and every 2.0 m text
// names 33 kV; X3/X5: the live numbers — road LT 5.8 m, 11 kV and 33 kV
// 6.5 m, roof 2.5 / 3.7 m, side 1.2 / 2.0 m — and an old 6.1 m span is
// "report it"; M7-10: the lesson's myth word for word; X6: 5 rounds, the
// owner's term rules) and the lesson's points (ground, building, sectional
// clearance, the lineman's duty), the lesson's own table decides every
// measured card and each card's plate and tag match its name, every picture
// exists and no colour, backdrop or prop marks the safe card (in any hand the
// dealer can make), the rival's myth is the lesson's own and every spoken
// line is listed for recording, a clean play (picks, reasons, the rival's
// myth) clears the rung, a miss on every round fails it (the board's
// strike-out), a wrong pick says the trap's own reason, opens no reason deck
// and never ends the board (boards have no freeze: the passer-by's rod, R17,
// is do_7_3_b's), the gesture hint sweeps without pressing, and the board
// waits quietly once dealt.
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
import 'package:slm_flutter/features/game/learn_board_pack73.dart';
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

const pack = learnBoardPack73;
const _artDir = 'assets/game/art/m7_board73';
const _rung = '7.3/learn';
const _ladder = 189;

/// Has read lesson 7.3 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_3', '7.3']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.3', ladderIndex: _ladder, pack: pack, muted: true),
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
    m.tauntBn, m.rivalLineBn, m.exitBn, m.stingBn, m.flipStingBn, ...m.dangerHints,
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
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.3');
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

  test('the lesson 7.3 board: five rounds', () {
    expect(pack.lessonId, '7.3');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.3 entry.
    final registered = learnBoardPackFor('7.3');
    if (registered != null) expect(registered, same(learnBoardPack73));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['road', 'roof', 'side', 'section', 'duty'], reason: '5 rounds (X6)');
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
      for (final bad in ['এলটি', 'এইচটি', 'কেভি', 'ভোল্ট']) {
        expect(l, isNot(contains(bad)), reason: '"$l": $bad in English letters');
      }
      // Voltages as the pole plate writes them: "11 kV", "33 kV", "415 V".
      expect(l, isNot(matches(RegExp(r'\d(kV|V)\b'))), reason: '"$l": a space before kV / V');
    }
  });

  test('only the lesson\'s numbers (and the measured readings) on screen; no outside citation', () {
    // The rule values of the live lesson (X5) and the voltages; every other
    // number is a card's measured reading, below a rule value.
    const rules = {'1.2', '2.0', '2.5', '3.7', '5.8', '6.5'};
    const volts = {'11', '33', '415'};
    const readings = {'0.3', '0.6', '1.0', '5.0', '5.6', '6.1'};
    for (final l in _allText()) {
      for (final m in RegExp(r'\d+(\.\d+)?').allMatches(l)) {
        expect(rules.union(volts).union(readings), contains(m.group(0)), reason: '"$l": ${m.group(0)} is not a lesson figure');
      }
      for (final no in ['2010', '2023', 'Reg', 'রেগুলেশন', '4.6', '5.5', '5.2', 'ফুট', 'জরিমানা', 'টাকা']) {
        expect(l, isNot(contains(no)), reason: '"$l": $no stays off screen (no citation, no along-road figures, no fines)');
      }
    }
    // The spec's old HT road figure is never a rule on screen (X3/X5): 6.1
    // appears only as the old span's reading, with "report it".
    for (final l in _allText().where((l) => l.contains('6.1'))) {
      expect(l, anyOf(contains('পুরনো'), contains('রিপোর্ট')), reason: '"$l": 6.1 m only as an old span to report');
    }
    // Ruling M7-7: every 2.0 m text names 33 kV; no 11 kV card on the side round.
    for (final l in _allText().where((l) => l.contains('2.0'))) {
      expect(l, contains('33 kV'), reason: '"$l": the 2.0 m side figure is the 33 kV one (M7-7)');
    }
    for (final o in _slot('side').options) {
      expect(o.labelBn, isNot(contains('11 kV')), reason: 'side/${o.id}: HT side cards are 33 kV only (M7-7)');
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

  test('the lesson\'s numbers: the live 7.3 table (X3/X5) is what the board teaches', () {
    final text = _lessonText;
    // Section 1 (ground): across a road LT 5.8, 11 kV 6.5, 33 kV 6.5 m.
    expect(text, allOf(contains('রাস্তা পার হলে ৫.৮ মিটার'), contains('রাস্তা পার হলে ৬.৫ মিটার')));
    expect(text, isNot(contains('৬.১')), reason: 'the live text no longer has the old 6.1 m');
    // Section 2 (building): vertical LT 2.5 / HT 3.7; horizontal LT 1.2,
    // up to 11 kV 1.2, above 11 kV to 33 kV 2.0.
    expect(text, allOf(contains('LT লাইন: ২.৫ মিটার'), contains('HT লাইন: ৩.৭ মিটার'), contains('LT লাইন: ১.২ মিটার')));
    expect(text, allOf(contains('(১১ কেভি পর্যন্ত): ১.২ মিটার'), contains('৩৩ কেভি পর্যন্ত): ২.০ মিটার')));
  });

  // The lesson's table, as the board uses it: a measured card is safe exactly
  // when its reading meets the minimum for its voltage and place.
  test('the lesson\'s table decides every measured card; each picture\'s plate and tag match its name', () {
    const minimum = {
      'road': {'415V': 5.8, '11kV': 6.5, '33kV': 6.5},
      'roof': {'415V': 2.5, '11kV': 3.7, '33kV': 3.7},
      'side': {'415V': 1.2, '33kV': 2.0},
    };
    var measured = 0;
    for (final e in minimum.entries) {
      for (final o in _slot(e.key).options) {
        final svg = File(o.asset).readAsStringSync();
        final volts = RegExp(r'<!--plate:(\w+)-->').firstMatch(svg)?.group(1);
        final dim = RegExp(r'<!--dim:([\d.]+)-->').firstMatch(svg)?.group(1);
        expect(volts, isNotNull, reason: '${o.asset}: a pole plate');
        expect(dim, isNotNull, reason: '${o.asset}: a measured tag');
        measured++;
        final shown = volts!.replaceAll('kV', ' kV').replaceAll(RegExp(r'(?<=\d)V'), ' V');
        expect(o.labelBn, contains(shown), reason: '${e.key}/${o.id}: the label names the plate\'s voltage');
        if (o.labelBn.contains('মিটার')) expect(o.labelBn, contains(dim), reason: '${e.key}/${o.id}: the label reads the tag');
        final min = e.value[volts];
        expect(min, isNotNull, reason: '${e.key}/${o.id}: a voltage this round deals ($volts)');
        expect(o.correct, double.parse(dim!) >= min!, reason: '${e.key}/${o.id}: $dim m against the $min m minimum for $volts');
      }
    }
    expect(measured, 17);
    // The two other rounds have no figures (the lesson gives none).
    for (final id in ['section', 'duty']) {
      for (final o in _slot(id).options) {
        expect(File(o.asset).readAsStringSync(), isNot(contains('<!--dim:')), reason: '${o.asset}: no reading the lesson cannot back');
      }
    }
  });

  test('the lesson\'s points: each trap says the lesson\'s own reason', () {
    final text = _lessonText;
    // Section 1 importance + pro tip 3 (summer sag) + "report it".
    expect(_reject('road', 'low11'), allOf(contains('6.5 মিটার'), contains('LT')));
    expect(_reject('road', 'old33'), allOf(contains('6.5 মিটার'), contains('রিপোর্ট')), reason: 'X5: "report it", not "illegal"');
    expect(_reject('road', 'old33'), isNot(contains('বেআইনি')));
    // X5 / M7-7: the old 6.1 m span is a trap of this round, so the round asks
    // for today's rule, never "which is lawful" (an old span may be lawful).
    expect(_slot('road').promptBn, contains('আজকের নিয়ম'));
    expect(_slot('road').promptBn, isNot(contains('আইন')));
    expect(text, contains('গরমকালে তার প্রসারিত হয়ে ঝুলে পড়ে, ফলে গ্রাউন্ড ক্লিয়ারেন্স কমে যায়'));
    expect(_reject('road', 'sag'), allOf(contains('প্রসারিত হয়ে ঝুলে পড়ে'), contains('গ্রাউন্ড ক্লিয়ারেন্স কমে যায়'), contains('রিপোর্ট')));
    expect(_reject('road', 'lowlt'), contains('5.8 মিটার'));
    // Section 2 vertical + pro tip 2 (new construction to the supervisor).
    expect(_reject('roof', 'htlow'), allOf(contains('3.7 মিটার'), contains('LT')));
    expect(_reject('roof', 'stair'), allOf(contains('চিলেকোঠা'), contains('2.5 মিটার')));
    expect(text, contains('অবিলম্বে আপনার সুপারভাইজারকে জানান'));
    expect(_reject('roof', 'newfloor'), allOf(contains('নতুন নির্মাণ'), contains('অবিলম্বে সুপারভাইজারকে জানান')));
    // Section 2 horizontal (M7-7) and its importance, word for word.
    expect(_reject('side', 'close33'), allOf(contains('33 kV'), contains('2.0 মিটার')));
    expect(text, contains(_reject('side', 'grill')), reason: 'section 2\'s own words');
    expect(text, contains(_reject('side', 'slab')), reason: 'section 2\'s own words');
    // Section 3, the short circuit in the wind (word for word), the cable,
    // phase to phase.
    expect(text, contains(_reject('section', 'windtouch')));
    expect(text, allOf(contains('নির্দিষ্ট উল্লম্ব দূরত্ব বজায় রাখা বাধ্যতামূলক'), contains('ফেজ-টু-ফেজ')));
    expect(_reject('section', 'tied'), allOf(contains('ইন্টারনেট কেবিল'), contains('নির্দিষ্ট উল্লম্ব দূরত্ব')));
    expect(_reject('section', 'phases'), contains('ফেজ-টু-ফেজ'));
    // Section 4 (warn, report) and myth 1's reality (wet clothes, arcs).
    expect(text, allOf(contains('বাঁশ বা লোহার রড নিয়ে যান'), contains('সতর্ক করা উচিত'), contains('রিপোর্ট করা আপনার দায়িত্ব')));
    expect(_reject('duty', 'ignorebamboo'), allOf(contains('বাঁশ বা লোহার রড'), contains('সতর্ক করা উচিত')));
    expect(_reject('duty', 'walkpast'), allOf(contains('ঝুলে'), contains('রিপোর্ট করা আপনার দায়িত্ব')));
    expect(text, allOf(contains('বিদ্যুৎ পরিবহন করতে পারে'), contains('দূর থেকেও আর্ক তৈরি হতে পারে')));
    expect(_reject('duty', 'wetclothes'), contains('বিদ্যুৎ পরিবহন করতে পারে'));
    expect(_reject('duty', 'roofbamboo'), contains('দূর থেকেও আর্ক তৈরি হতে পারে'));
    expect(pack.earnedBn, allOf(contains('5.8'), contains('6.5'), contains('2.5'), contains('3.7'), contains('1.2'), contains('33 kV 2.0'), contains('রিপোর্ট')));
  });

  test('boards have no freeze: no trap is a deadly-class act; the passer-by\'s rod (R17) is do_7_3_b\'s', () {
    // The duty round's safe cards are the warning and the reports; its traps
    // are walking on — none shows a rod or bamboo touching the line.
    for (final o in _slot('duty').options) {
      expect(File(o.asset).readAsStringSync(), isNot(contains('<!--prop:spark-->')), reason: '${o.asset}: nobody touches the line on the board');
    }
    // Geometry, not just tags: the art script measures the smallest air gap
    // from every head, hand, rod or bamboo end, clothes line and vehicle top
    // to every conductor curve, and writes it as <!--gap:N--> (px, after the
    // strokes and radii). Every card with a person, a long prop or a vehicle
    // carries it, and nothing comes within 12 px (about 0.7 m) of a wire.
    final reach = RegExp(r'<!--prop:(lineman|public|mason|bamboo|bus|truck|clothes)-->');
    final gapRe = RegExp(r'<!--gap:(-?[\d.]+)-->');
    var gapped = 0;
    for (final s in pack.slots) {
      for (final o in s.options) {
        final svg = File(o.asset).readAsStringSync();
        final gap = gapRe.firstMatch(svg)?.group(1);
        if (reach.hasMatch(svg)) {
          expect(gap, isNotNull, reason: '${o.asset}: a figure or prop near a line is measured');
        }
        if (gap == null) continue;
        gapped++;
        expect(double.parse(gap), greaterThanOrEqualTo(12.0), reason: '${o.asset}: something is $gap px from a conductor (nobody touches the line on the board)');
      }
    }
    expect(gapped, greaterThanOrEqualTo(15), reason: 'the road, the new floor and every duty card are measured');
    for (final l in _allText()) {
      for (final no in ['টেস্টার', 'হারনেস', 'গ্লাভস', 'শাটডাউন', 'মৃত্যু']) {
        expect(l, isNot(contains(no)), reason: '"$l": a clearance board ($no belongs to the field levels)');
      }
    }
    // The coworker's push (the myth) is a slip-class belief (ruling X2).
    expect(pack.myth.believeNoIsCorrect, isTrue);
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's or one trap's.
  test('right reasons fit every safe pick of their round', () {
    List<String> right(String slot) => [for (final w in _slot(slot).whyChips) if (w.correct) w.textBn];
    const onlyOne = {
      'road': ['বাসের', 'গরম', '11 kV', '415 V'],
      'roof': ['415 V', '11 kV'],
      'side': ['415 V', 'গ্রিল'],
      'section': ['ইন্টারনেট', 'চওড়া'],
      'duty': ['ফোন', 'হাত তুলে', 'ঝুলে'],
    };
    for (final e in onlyOne.entries) {
      for (final t in right(e.key)) {
        for (final one in e.value) {
          expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
        }
      }
    }
  });

  test('every picture exists (vector scenes from tool/m7_board73_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board73 folder is a card on the board', () {
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
  // lineman, a passer-by, a bus, a truck, the sun, the wind, a phone, a house...
  // In every hand, nothing sits only on the safe card, and nothing sits on
  // every trap but not the safe card (the odd one out would be the answer).
  test('in every possible hand, no prop or figure marks the safe card', () {
    final tagRe = RegExp(r'<!--prop:(\w+)-->');
    final props = <String, Set<String>>{};
    Set<String> of(String asset) => props.putIfAbsent(
        asset, () => tagRe.allMatches(File(asset).readAsStringSync()).map((m) => m.group(1)!).toSet());

    for (final s in pack.slots) {
      final traps = s.options.where((o) => !o.correct).toList();
      if (s.id == 'duty') {
        for (final o in s.options) {
          expect(of(o.asset), contains('lineman'), reason: '${o.asset}: the lineman on every duty card');
        }
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

  // What each card's label says is drawn: the vehicle, the heat, the
  // চিলেকোঠা, the masons, the grill, the slab, the wind and the spark, the
  // cable, the phone call, the raised palm.
  test('the pictures show what the labels say', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync();
    Set<String> props(String card) => RegExp(r'<!--prop:(\w+)-->').allMatches(svg(card)).map((m) => m.group(1)!).toSet();
    const palm = 'width="7" height="9" rx="2.5"'; // the lineman's raised palm
    expect(props('road_ok33'), contains('sun'), reason: 'গরমের দুপুরে');
    expect(props('road_sag'), contains('sun'), reason: 'গরমে ঝুলে পড়া');
    expect(props('road_ok11'), contains('bus'));
    expect(props('road_oklt'), contains('truck'));
    expect(props('roof_ht'), contains('stairroom'));
    expect(props('roof_stair'), contains('stairroom'));
    expect(props('roof_newfloor'), containsAll(['mason', 'bricks']));
    expect(props('side_grill'), contains('grill'));
    expect(props('side_lt'), contains('grill'), reason: 'the grill is on a safe card too');
    expect(props('side_slab'), contains('bricks'));
    expect(props('section_windtouch'), containsAll(['wind', 'spark']));
    expect(props('section_twin'), contains('wind'), reason: 'wind on a safe card too: the gap holds');
    for (final c in ['section_cable', 'section_tied']) {
      expect(props(c), contains('cable'), reason: c);
    }
    expect(svg('duty_warnrod'), contains(palm), reason: 'duty_warnrod: the raised palm');
    for (final c in ['duty_callbuild', 'duty_reportsag']) {
      expect(props(c), contains('phone'), reason: '$c: the call');
    }
    for (final c in ['duty_ignorebamboo', 'duty_walkpast']) {
      expect(props(c), contains('phone'), reason: '$c: on the phone, but not warning or reporting');
      expect(svg(c), isNot(contains(palm)), reason: '$c: no warning');
    }
    expect(props('duty_wetclothes'), contains('clothes'));
    expect(props('duty_roofbamboo'), containsAll(['bamboo', 'wind']));
  });

  test('the careless lineman says the lesson\'s second myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _norm(_myths[1]['myth'] as String), reason: 'the lesson\'s own myth 2 (ruling M7-10; myth 1 is do_7_3_b\'s)');
    expect(m.rivalLineBn, 'ক্লিয়ারেন্স একটু কম হলে কিছু হয় না, কেউ তো আর মাপতে আসছে না।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'measurements are taken after an accident; the law punishes breaches');
    final reality = _norm(_myths[1]['reality'] as String);
    expect(reality, allOf(contains('তদন্তের সময় এই সমস্ত পরিমাপ করা হয়'), contains('কঠোর শাস্তির বিধান'), contains('আইন মানা আপনার কর্তব্য')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('তদন্তে')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('কঠোর শাস্তির বিধান')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line and the sting are already recorded; the new ones wait
    // for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board73Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board73Lines.newRivalLines, M7Board73Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board73Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board73Lines.guideSpoken;
    expect(M7Board73Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 17 trap reasons + 5×3 right reasons + sting + flipped sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 17 + 15 + 1 + 1 + 3 + 1));
    expect(spoken, contains(pack.introBn));
    expect(spoken, contains(pack.earnedBn));
    expect(spoken, contains(pack.myth.stingBn));
    // The runner flips the believe question on half the plays; this board's
    // turned-round line is the recorded yes/no one, never the kit's default
    // either/or "shortcut / save your life" line.
    expect(spoken, contains(pack.myth.flipStingBn));
    expect(pack.myth.flipStingBn, M7Board73Lines.flipSting);
    expect(pack.myth.flipStingBn, endsWith('সেটা কি ভুল?'));
    expect(pack.myth.flipStingBn, isNot(const LearnMythBeat(rivalLineBn: '', believeNoIsCorrect: true, whyChips: []).flipStingBn));
    expect(LearnVoice.resolve(pack.myth.flipStingBn), isNotNull, reason: 'the flipped sting has a clip');
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
      expect(save.rungProgress[_rung], isNot('cleared'), reason: 'a miss on every round: below the pass line');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a trap teaches with the lesson\'s numbers; no reason deck, no freeze (boards have none)', (t) async {
      final c = await _open(t);
      // Boards have no freeze: the trap costs the round's ◆ and says its own
      // reason. The roof round has three traps and a hand of four, so every
      // hand holds the 11 kV-at-2.5 m card.
      await _cleanRound(t, _slot('road'));
      final roof = _slot('roof');
      await _settleHand(t, 'pick', {'htlow'}, 'roof: the 11 kV at the LT height');
      await tapBoardCard(t, _dealt('pick', {'htlow'}));
      await _pumpUntil(t, () => find.text(_reject('roof', 'htlow')).evaluate().isNotEmpty, what: 'the 3.7 m reason');
      for (final w in roof.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the "কেন" deck');
      }
      expect(find.byType(LevelFailPanel), findsNothing, reason: 'one miss does not end the board');
      // The board goes on: past the feedback, a fresh hand with a safe card.
      await continueBoard(t);
      await _cleanRound(t, roof);
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.3', ladderIndex: _ladder, pack: pack, muted: true),
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
