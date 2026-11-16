// Module 7 lesson 7.8 picture board ("পরিবেশগত আইন: আমাদের দায়িত্ব", rung
// 7.8/learn, pack learn_7_8): its content follows the board's rules, the
// Module 7 rulings (M7-6: no deadly act in 7.8, every wrong card is a slip;
// M7-9: the DTR is drawn with its AB switch, never a DO; M7-10: the lesson's
// myth word for word; X3: the battery rule for batteries, the e-waste rule
// for circuit boards; X6: 5 rounds, the owner's term rules) and the lesson's
// points (old oil in a leak-proof drum to an authorised agency, a spill kit,
// batteries and boards to the collection centre, whole lamps to an authorised
// agency, hazardous waste apart), every picture exists and no colour,
// backdrop, prop or figure marks the safe card (in any hand the dealer can
// make), the rival's myth is the lesson's own and every spoken line is listed
// for recording, a clean play (picks, reasons, the rival's myth) clears the
// rung, a miss on every round fails it (the board's strike-out), a wrong card
// teaches with the lesson's words, opens no reason deck and never freezes the
// board (boards have no freeze: kit design, GAME_DEVELOPER_GUIDE §10c), the
// gesture hint sweeps without pressing, and the board waits quietly once
// dealt.
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
import 'package:slm_flutter/features/game/learn_board_pack78.dart';
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

const pack = learnBoardPack78;
const _artDir = 'assets/game/art/m7_board78';
const _rung = '7.8/learn';
const _ladder = 204; // m7 starts at 183; 7.8/learn is orderInModule 21 in the catalog

/// Has read lesson 7.8 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_8', '7.8']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.8', ladderIndex: _ladder, pack: pack, muted: true),
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
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.8');
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

  test('the lesson 7.8 board: five rounds', () {
    expect(pack.lessonId, '7.8');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.8 entry.
    final registered = learnBoardPackFor('7.8');
    if (registered != null) expect(registered, same(learnBoardPack78));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['oil', 'spill', 'ewaste', 'lamp', 'sep'], reason: '5 rounds');
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

  test('no figures or legal terms the lesson does not give: no fines, sections, prison terms or amounts', () {
    for (final l in _allText()) {
      // The only number on the board is the year of the two rules (2022).
      for (final m in RegExp(r'\d+').allMatches(l)) {
        expect(m.group(0), '2022', reason: '"$l": only the rules\' year');
      }
      for (final no in ['ধারা', 'কারাদণ্ড', 'জেল', 'আদালত', 'টাকা', 'kV']) {
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

  test('the lesson\'s points: the oil, the spill kit, the e-waste, the lamps, the bins', () {
    final text = _lessonText;
    // Point 1: old transformer oil is hazardous waste; not on the soil or in a
    // drain (punishable); a leak-proof drum; only an authorised recycling agency.
    expect(_safeIds('oil'), {'drum', 'agency'});
    expect(_trapIds('oil'), {'soil', 'drain', 'bucket', 'stranger'});
    expect(text, allOf(contains('Hazardous Waste Management Rules'), contains('মাটিতে বা ড্রেনে ফেলা একটি দণ্ডনীয় অপরাধ'),
        contains('লিক-প্রুফ ড্রামে সংগ্রহ করতে হবে'), contains('শুধুমাত্র অনুমোদিত রিসাইক্লিং এজেন্সির কাছে হস্তান্তর করতে হবে')));
    expect(_reject('oil', 'soil'), allOf(contains('Hazardous Waste Management Rules'), contains('মাটিতে ফেলা দণ্ডনীয় অপরাধ')));
    expect(text, contains(_reject('oil', 'drain').split(' — ').first), reason: 'point 1 importance word for word');
    expect(_reject('oil', 'drain'), contains('ড্রেনে ফেলাও দণ্ডনীয় অপরাধ'));
    expect(_reject('oil', 'bucket'), allOf(contains('বিপজ্জনক বর্জ্য'), contains('লিক-প্রুফ ড্রামে')));
    expect(_reject('oil', 'stranger'), contains('শুধুমাত্র অনুমোদিত রিসাইক্লিং এজেন্সির কাছে হস্তান্তর করতে হবে'), reason: 'only an authorised agency, word for word');
    // Pro tip 1 and myth 1's reality: a spill kit; soil soaks, groundwater is hit.
    expect(_safeIds('spill'), {'boom', 'pads'});
    expect(_trapIds('spill'), {'leave', 'wash', 'cover'});
    expect(text, allOf(contains('স্পিল কিট'), contains('তেল শোষণকারী প্যাড, বুম')));
    expect(_reject('spill', 'leave'), allOf(contains('ভূগর্ভস্থ জল'), contains('দীর্ঘস্থায়ী ক্ষতি')));
    expect(_reject('spill', 'wash'), allOf(contains('লক্ষ লক্ষ লিটার জল'), contains('স্পিল কিট ব্যবহার করুন')));
    expect(_reject('spill', 'cover'), allOf(contains('মাটিতেই থাকে'), contains('প্যাড দিয়ে শুষে নিন')));
    // Point 2: lead and acid; the battery rule for batteries, the e-waste
    // rule for boards (ruling X3); never with ordinary garbage; the
    // company's collection centre.
    expect(_safeIds('ewaste'), {'battery', 'board'});
    expect(_trapIds('ewaste'), {'vat', 'bury', 'acid'});
    expect(text, allOf(contains('Battery Waste Management Rules, 2022'), contains('E-Waste (Management) Rules, 2022'),
        contains('সাধারণ ময়লার সাথে ফেলা যাবে না'), contains('কোম্পানির নির্ধারিত সংগ্রহ কেন্দ্রে জমা দিতে হবে')));
    expect(_reject('ewaste', 'vat'), allOf(contains('Battery Waste Management Rules, 2022'), contains('E-Waste (Management) Rules, 2022'),
        contains('সাধারণ ময়লার সাথে ফেলা যাবে না')), reason: 'M7-L4: the battery rule for the battery');
    expect(_reject('ewaste', 'bury'), allOf(contains('ক্ষতিকারক রাসায়নিক'), contains('খাদ্য আর জলের মাধ্যমে')));
    expect(_reject('ewaste', 'acid'), allOf(contains('সীসা'), contains('অ্যাসিড'), contains('সংগ্রহ কেন্দ্রে জমা দিন')));
    // Point 3: mercury; hazardous waste; whole, to an authorised agency.
    expect(_safeIds('lamp'), {'box', 'agency'});
    expect(_trapIds('lamp'), {'snap', 'bin', 'toss'});
    expect(text, allOf(contains('মারাত্মক নিউরোটক্সিন'), contains('না ভেঙে সাবধানে সংগ্রহ করতে হবে'),
        contains('অনুমোদিত ডিসপোজাল এজেন্সির কাছে পাঠাতে হবে')));
    expect(_reject('lamp', 'snap'), allOf(contains('মারাত্মক নিউরোটক্সিন'), contains('না ভেঙে সাবধানে সংগ্রহ করতে হবে')));
    expect(_reject('lamp', 'bin'), allOf(contains('বিপজ্জনক বর্জ্য'), contains('অনুমোদিত ডিসপোজাল এজেন্সিতে')));
    expect(_reject('lamp', 'toss'), allOf(contains('পারদ'), contains('না ভেঙে সাবধানে সংগ্রহ করুন')));
    // Pro tip 2 and myth 2's reality: hazardous waste apart, in its own bin;
    // the law binds any person or body.
    expect(_safeIds('sep'), {'rag', 'two'});
    expect(_trapIds('sep'), {'mixed', 'pads', 'smallcrew'});
    expect(text, allOf(contains('সাধারণ বর্জ্য থেকে আলাদা করে নির্দিষ্ট ডাস্টবিনে ফেলুন'),
        contains('যে কোনো ব্যক্তি বা সংস্থার জন্য প্রযোজ্য')));
    expect(_reject('sep', 'mixed'), contains('সাধারণ বর্জ্য থেকে আলাদা করে নির্দিষ্ট ডাস্টবিনে ফেলুন'));
    expect(_reject('sep', 'pads'), allOf(contains('তেল-মাখা প্যাড'), contains('নির্দিষ্ট ডাস্টবিনে')));
    expect(_reject('sep', 'smallcrew'), allOf(contains('যে কোনো ব্যক্তি বা সংস্থার জন্য প্রযোজ্য'), contains('জরিমানা')));
    expect(pack.earnedBn, allOf(contains('ড্রামে'), contains('আলাদা জমা'), contains('ড্রেনে')));
  });

  test('rulings M7-6 and M7-9: no deadly act on this board, no DO, the DTR drawn with its AB switch opened', () {
    // M7-6: lesson 7.8 has slips only; boards have no freeze, so no card or
    // line here may say the level ends or a worker is in danger of death.
    for (final l in _allText()) {
      for (final no in ['ডিও', 'DO ', 'ড্রপ আউট']) {
        expect(l, isNot(contains(no)), reason: '"$l": no DO in Module 7');
      }
    }
    expect(pack.myth.believeNoIsCorrect, isTrue, reason: 'the soil does not just soak the oil in');
    // M7-9: the background DTR of the oil and spill frames is an AB switch
    // with its three blades standing up (opened), padlocked and tagged.
    final blades = RegExp(r'<path d="M\d+ 40 L\d+ 26" stroke="#4A5560"');
    for (final slot in ['oil', 'spill']) {
      for (final o in _slot(slot).options) {
        final svg = File(o.asset).readAsStringSync();
        expect(blades.allMatches(svg).length, 3, reason: '${o.asset}: all three AB blades up');
        expect(svg, contains('fill="#C9A23A"'), reason: '${o.asset}: the padlock');
        expect(svg, contains('<!--prop:dtr-->'), reason: o.asset);
      }
    }
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's or one trap's.
  test('right reasons fit every safe pick of their round', () {
    List<String> right(String slot) => [for (final w in _slot(slot).whyChips) if (w.correct) w.textBn];
    // Words that belong to one of the round's safe pictures only.
    const onlyOne = {
      'oil': ['পাইপে', 'গাড়িতে', 'ক্যান'],
      'spill': ['হোস', 'বেলচা'],
      'ewaste': ['ফাটা', 'ভ্যাট'],
      'lamp': ['বাক্সে', 'হাঁটু'],
      'sep': ['লাল', 'সবুজ', 'কাপ'],
    };
    for (final e in onlyOne.entries) {
      for (final t in right(e.key)) {
        for (final one in e.value) {
          expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
        }
      }
    }
    // The e-waste round deals a battery or a board: the first reason covers both.
    expect(right('ewaste').first, allOf(contains('ব্যাটারি'), contains('বোর্ড')));
  });

  test('every picture exists (vector scenes from tool/m7_board78_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board78 folder is a card on the board', () {
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

  // What each card's label says is drawn: the funnel and pipe, the agency's
  // board with its recycling mark, the boom and the pads, the crate, the acid,
  // the sealed box, the two bins, the crew and its thought of a factory.
  test('the pictures show what the labels say', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync();
    Set<String> props(String card) => RegExp(r'<!--prop:(\w+)-->').allMatches(svg(card)).map((m) => m.group(1)!).toSet();
    int rings(String card) => 'A6.5 6.5 0 0 1'.allMatches(svg(card)).length;
    // Oil: the agency's van carries the board with the recycling mark (3
    // arrows); no other van does. The stranger's driver is a helper in a cap.
    expect(rings('oil_agency'), 3);
    for (final c in ['oil_drum', 'oil_soil', 'oil_drain', 'oil_bucket', 'oil_stranger']) {
      expect(rings(c), 0, reason: '$c: no recycling mark on this van');
    }
    expect(props('oil_stranger'), contains('helper'));
    for (final c in ['oil_drum', 'oil_agency', 'oil_soil', 'oil_drain', 'oil_bucket']) {
      expect(props(c), contains('contract'), reason: '$c: the agency\'s own driver stands by his van');
    }
    expect(svg('oil_drum'), contains('l-4 8'), reason: 'oil_drum: the funnel on the drum');
    expect(svg('oil_bucket'), contains('fill="#2B2420"'), reason: 'oil_bucket: oil in the open bucket');
    for (final c in ['oil_drum', 'oil_agency', 'oil_soil', 'oil_drain', 'oil_bucket', 'oil_stranger']) {
      expect(props(c), containsAll(['dtr', 'container', 'van', 'drain', 'soil']), reason: '$c: the same frame on every card');
    }
    // Spill: the boom (a dashed orange ring) and the pads only on their cards;
    // the wash has the hose's water; the cover has the shovel and the heap.
    expect(svg('spill_boom'), contains('stroke-dasharray="3 6"'));
    expect(svg('spill_pads'), contains('fill="#C9CFD4"'));
    expect(svg('spill_wash'), contains('stroke="#5C9BC4"'), reason: 'spill_wash: water');
    expect(props('spill_cover'), contains('gear'));
    expect(props('spill_leave'), isNot(contains('gear')), reason: 'spill_leave: nothing done');
    for (final o in _slot('spill').options) {
      expect(props('spill_${o.id}'), containsAll(['dtr', 'puddle', 'drain']), reason: o.id);
    }
    // E-waste: the battery or the board, the centre with its crate and the
    // vat on every card; the acid green only where the battery cracked.
    for (final o in _slot('ewaste').options) {
      expect(props('ewaste_${o.id}'), containsAll(['ewaste', 'crate', 'centre', 'vat']), reason: o.id);
    }
    expect(svg('ewaste_acid'), contains('stroke="#C9CFD4" stroke-width="1.2"'), reason: 'ewaste_acid: the crack');
    expect(svg('ewaste_board'), contains('fill="#2F7D4F"'), reason: 'ewaste_board: the circuit board');
    // Lamps: the sealed box (taped) on the approved van; the dustbin and a
    // van on every card.
    expect(rings('lamp_agency'), 3);
    for (final o in _slot('lamp').options) {
      expect(props('lamp_${o.id}'), containsAll(['dustbin', 'van', 'lamp']), reason: o.id);
      if (o.id != 'agency') expect(rings('lamp_${o.id}'), 0, reason: o.id);
    }
    // Sep: both bins on every card; the crew (a vested man and a helper) and
    // the factory in a thought bubble on the small-crew card only.
    for (final o in _slot('sep').options) {
      expect(props('sep_${o.id}'), containsAll(['hazbin', 'genbin', 'waste']), reason: o.id);
    }
    expect(props('sep_smallcrew'), containsAll(['contract', 'helper', 'bubble']));
    expect(props('sep_mixed'), isNot(contains('bubble')));
    // The held item is over the bin the label names: the green bin (x 160-184)
    // for the safe tea cup and the wrong acts, the red bin (x 128-152) for the rag.
    double heldX(String c) {
      final m = RegExp(r'<!--held:(\d+)-->').firstMatch(svg(c));
      return double.parse(m!.group(1)!);
    }
    expect(heldX('sep_rag'), inInclusiveRange(128, 152));
    for (final c in ['sep_two', 'sep_mixed', 'sep_pads', 'sep_smallcrew']) {
      expect(heldX(c), inInclusiveRange(160, 184), reason: '$c: held over the green bin');
    }
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _norm(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1 (ruling M7-10)');
    expect(m.rivalLineBn, 'একটু তেল মাটিতে পড়লে কিছু হয় না, মাটি তো শুষে নেয়।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the oil reaches the groundwater');
    final reality = _norm(_myths[0]['reality'] as String);
    expect(reality, allOf(contains('ভূগর্ভস্থ জলকে'), contains('পানীয় জলের একটি প্রধান উৎস'), contains('দীর্ঘস্থায়ী ক্ষতি')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('ভূগর্ভস্থ জল')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('পানীয় জলের')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line and the sting are already recorded; the new ones wait
    // for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board78Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board78Lines.newRivalLines, M7Board78Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board78Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board78Lines.guideSpoken;
    expect(M7Board78Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 16 trap reasons + 5x3 right reasons + sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 16 + 15 + 2 + 3 + 1));
    expect(spoken, contains(pack.introBn));
    expect(spoken, contains(pack.earnedBn));
    expect(spoken, contains(pack.myth.stingBn));
    expect(spoken, contains(M7Board78Lines.flipSting));
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

    testWidgets('a wrong card (oil poured on the soil, a slip) teaches with the lesson\'s words; no reason deck, no freeze', (t) async {
      final c = await _open(t);
      // Boards have no freeze (kit design) and 7.8 has no deadly act (M7-6):
      // the trap costs the round\'s ◆ and its reason is the lesson\'s rule.
      // The oil round has four traps and a hand of four, so a hand holds one
      // safe card and three of them; the soil trap is among them on most
      // deals, so wait for whichever trap lands.
      final oil = _slot('oil');
      await _settleHand(t, 'pick', _ids(oil.options, correct: false), 'oil: a trap');
      final hand = <String>{
        for (final o in oil.options)
          if (!o.correct && _dealt('pick', {o.id}).evaluate().isNotEmpty) o.id,
      };
      final trap = hand.first;
      await tapBoardCard(t, _dealt('pick', {trap}));
      await _pumpUntil(t, () => find.text(_reject('oil', trap)).evaluate().isNotEmpty, what: 'the trap\'s reason');
      expect(find.byType(FreezeFrame), findsNothing, reason: 'boards teach; they never freeze');
      for (final w in oil.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the "কেন" deck');
      }
      expect(find.byType(LevelFailPanel), findsNothing, reason: 'one miss does not end the board');
      // The board goes on: past the feedback, a fresh hand with a safe card.
      await continueBoard(t);
      await _cleanRound(t, oil);
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.8', ladderIndex: _ladder, pack: pack, muted: true),
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

