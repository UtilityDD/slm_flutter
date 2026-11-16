// Module 7 lesson 7.7 picture board ("দুর্ঘটনার রিপোর্ট (Accident Reporting):
// আপনার দায়িত্ব", rung 7.7/learn, pack learn_7_7): its content follows the
// board's rules, the Module 7 rulings (M7-10: the lesson's myth word for
// word; X3: the live text wins, any injury or near-injury is reportable and
// there is no '24 hours off work' condition; X6: 5 rounds, the owner's term
// rules) and the lesson's points (what is reportable, the lineman's duty to
// tell at once, the note's contents, the scene kept as it was, the near
// miss), every picture exists and no colour, backdrop, prop or figure marks
// the safe card (in any hand the dealer can make), the rival's myth is the
// lesson's own and every spoken line is listed for recording, a clean play
// (picks, reasons, the rival's myth) clears the rung, a miss on every round
// fails it (the board's strike-out), a wrong picture teaches with the
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
import 'package:slm_flutter/features/game/learn_board_pack77.dart';
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

const pack = learnBoardPack77;
const _artDir = 'assets/game/art/m7_board77';
const _rung = '7.7/learn';
const _ladder = 192; // m7 starts at 183; 7.7/learn is its 10th rung (orderInModule 9)

/// Has read lesson 7.7 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_7', '7.7']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.7', ladderIndex: _ladder, pack: pack, muted: true),
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
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.7');
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

  test('the lesson 7.7 board: five rounds (ruling X6 trims the spec\'s six; the shock round folds into the duty round)', () {
    expect(pack.lessonId, '7.7');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.7 entry.
    final registered = learnBoardPackFor('7.7');
    if (registered != null) expect(registered, same(learnBoardPack77));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['must', 'duty', 'note', 'scene', 'near'], reason: '5 rounds');
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
      // «ডেড» for a proven-dead line; 'মৃত্যু' is the lesson's own word for a death.
      expect(l, isNot(matches(RegExp('মৃত(?!্যু)'))), reason: '"$l": «ডেড», never «মৃত»');
      expect(l, isNot(matches(RegExp('(?<![ঀ-৿])(অন|অফ)(?![ঀ-৿])'))), reason: '"$l": ON / OFF in English');
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": an AB is «লাগানো», never «বন্ধ»');
      expect(l, isNot(contains('DO ')), reason: '"$l": no DO in Module 7 (M7-9)');
      expect(l, isNot(contains('ঘন্টা')), reason: '"$l": the live spelling is ঘণ্টা');
      for (final single in _singles) {
        expect(l, isNot(contains(single)), reason: '"$l": য় ড় ঢ় as letter + nukta');
      }
      for (final bad in ['এলটি', 'এইচটি', 'কেভি']) {
        expect(l, isNot(contains(bad)), reason: '"$l": $bad in English letters');
      }
    }
  });

  test('no figures or legal terms the lesson does not give (X3): no 24-hour-off-work condition, no fine or prison term', () {
    for (final l in _allText()) {
      for (final no in ['জরিমানা', 'কারাদণ্ড', 'জেল', 'আদালত', 'অক্ষম', 'ছুটি নিয়ে', 'kV']) {
        expect(l, isNot(contains(no)), reason: '"$l": unsupported in the lesson');
      }
      expect(l, isNot(contains('24 ঘণ্টার বেশি')), reason: '"$l": the live 7.7 has no \'24 hours unable to work\' condition');
    }
    // The only numbers on the board: 3 days (a card), the lesson's 24-48
    // hours (one trap's reason) and section 161 (one reason).
    final nums = <String>{};
    for (final l in _allText()) {
      for (final m in RegExp(r'\d+(?:-\d+)?').allMatches(l)) {
        nums.add(m.group(0)!);
      }
    }
    expect(nums.difference({'3', '24-48', '161'}), isEmpty);
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

  test('the lesson\'s points: what is reportable, the lineman\'s duty, the note, the scene, the near miss', () {
    final text = _lessonText;
    String enDigits(String s) {
      const bn = '০১২৩৪৫৬৭৮৯';
      for (var i = 0; i < 10; i++) {
        s = s.replaceAll(bn[i], '$i');
      }
      return s;
    }

    final lesson = enDigits(text);
    // Point 1: a death (person or animal), any injury or an accident that
    // could have hurt someone, and big events (fire, explosion).
    expect(_safeIds('must'), {'cow', 'dtr', 'bed'});
    expect(_trapIds('must'), {'walk', 'gate', 'leave'});
    expect(text, allOf(contains('ইলেকট্রিসিটি অ্যাক্ট'), contains('১৬১ ধারা'), contains('ইলেকট্রিক্যাল ইন্সপেক্টরকে')));
    expect(text, contains('যেকোনো দুর্ঘটনা যার ফলে কোনো মানুষের বা পশুর মৃত্যু হয়েছে'));
    expect(_reject('must', 'walk'), contains('মানুষ হোক বা পশু'));
    expect(text, contains('আগুন লাগা বা বিস্ফোরণের মতো বড় ঘটনা'));
    expect(_reject('must', 'gate'), contains('আগুন লাগা বা বিস্ফোরণের মতো বড় ঘটনাও'));
    // X3: the live text has no '24 hours unable to work' condition; it says
    // any injury, or a death or injury that could have happened.
    expect(text, contains('যেকোনো দুর্ঘটনা যাতে কোনো মানুষ বা পশু আহত হয়েছে, বা মৃত্যু বা আঘাত হতে পারত'));
    expect(_reject('must', 'leave'), contains('যেকোনো দুর্ঘটনা যাতে কোনো মানুষ বা পশু আহত হয়েছে, বা মৃত্যু বা আঘাত হতে পারত'));
    expect(text, isNot(contains('২৪ ঘণ্টার বেশি')));
    expect(_opt('must', 'bed').labelBn, contains('3 দিন'));
    // Point 2: the owner reports formally; the lineman tells at once.
    expect(_safeIds('duty'), {'call', 'doc'});
    expect(_trapIds('duty'), {'home', 'comp', 'huddle', 'tea'});
    expect(lesson, contains('নির্ধারিত সময়ের মধ্যে (সাধারণত 24-48 ঘণ্টা) রিপোর্ট না করা একটি দণ্ডনীয় অপরাধ'));
    expect(_reject('duty', 'home'), contains('সাধারণত 24-48 ঘণ্টা'));
    expect(_reject('duty', 'home'), contains('খবর দিন সাথে সাথে'));
    expect(text, allOf(contains('সুপারভাইজার বা নিয়ন্ত্রণ কর্তৃপক্ষকে'), contains('সময়মতো আনুষ্ঠানিক রিপোর্ট করতে পারে')));
    expect(_reject('duty', 'comp'), allOf(contains('আনুষ্ঠানিক রিপোর্ট কোম্পানির দায়িত্ব'), contains('সাথে সাথে')));
    // Myth 1 (hiding) and myth 2 (the small shock) realities.
    expect(text, allOf(contains('লুকিয়ে রাখাটা একটি বড় আইনি অপরাধ'), contains('পরিস্থিতিকে আরও জটিল')));
    expect(_reject('duty', 'huddle'), allOf(contains('লুকিয়ে রাখা'), contains('বড় আইনি অপরাধ')));
    expect(text, allOf(contains('ভেতরের ক্ষতি'), contains('বাইরে থেকে বোঝা যায় না'), contains('ডাক্তারি পরীক্ষা')));
    expect(_reject('duty', 'tea'), allOf(contains('ভেতরের ক্ষতি'), contains('বাইরে থেকে বোঝা যায় না'), contains('ডাক্তার')));
    // The medical care at the scene and the rule on moving things (point 4)
    // do not clash: the doctor is a safe act.
    expect(_slot('duty').whyChips.where((w) => !w.correct && w.textBn.contains('ডাক্তার')), isNotEmpty);
    // Point 3 and pro tips 2-3: what a report holds; honest and exact.
    expect(_safeIds('note'), {'when', 'how'});
    expect(_trapIds('note'), {'vague', 'hide', 'over'});
    expect(text, allOf(contains('তারিখ, সময় এবং সঠিক স্থান'), contains('নাম, বয়স এবং ঠিকানা'), contains('কীভাবে ঘটল'), contains('প্রত্যক্ষদর্শী')));
    expect(_reject('note', 'vague'), allOf(contains('তারিখ, সময় আর সঠিক স্থান'), contains('তদন্ত চলে না')));
    expect(text, contains('সৎ এবং নির্ভুল তথ্যই সঠিক তদন্তের ভিত্তি'));
    expect(_reject('note', 'hide'), contains('সৎ এবং নির্ভুল তথ্যই সঠিক তদন্তের ভিত্তি'));
    expect(_reject('note', 'over'), contains('সৎ এবং নির্ভুল তথ্যই সঠিক তদন্তের ভিত্তি'));
    expect(text, contains('ছোট লিখিত নোট'));
    expect(_slot('note').whyChips.any((w) => w.correct && w.textBn.contains('লিখিত নোট')), isTrue);
    // Point 4: nothing moved or changed without permission, unless another
    // danger must be stopped.
    expect(_safeIds('scene'), {'asis', 'sand'});
    expect(_trapIds('scene'), {'ladder', 'fuse', 'sweep'});
    expect(text, allOf(contains('অনুমতি ছাড়া'), contains('অন্য কোনো বিপদ আটকানোর জন্য'), contains('ঘটনাস্থল পরিবর্তন করলে তদন্ত প্রক্রিয়া ব্যাহত হতে পারে')));
    expect(_reject('scene', 'ladder'), allOf(contains('ইন্সপেক্টর বা পুলিশের অনুমতি ছাড়া'), contains('সরানো বা পরিবর্তন')));
    expect(_reject('scene', 'fuse'), 'ঘটনাস্থল পরিবর্তন করলে তদন্ত প্রক্রিয়া ব্যাহত হতে পারে।');
    expect(_reject('scene', 'sweep'), allOf(contains('অত্যন্ত জরুরি'), contains('প্রমাণ নষ্ট')));
    expect(_slot('scene').whyChips.any((w) => w.correct && w.textBn.contains('বিপদ আটকাতে')), isTrue);
    // Pro tip 1 and the RCA fact: a near miss is told; 'why', not 'who'.
    expect(_safeIds('near'), {'tell', 'write'});
    expect(_trapIds('near'), {'laugh', 'sign', 'blame'});
    expect(text, allOf(contains('Near Miss'), contains('সেফটি ডিপার্টমেন্টকে জানানো উচিত'), contains('ভবিষ্যতের বড় দুর্ঘটনা প্রতিরোধ')));
    expect(_reject('near', 'laugh'), contains('ভবিষ্যতের বড় দুর্ঘটনা প্রতিরোধ'));
    expect(_reject('near', 'sign'), contains('সেফটি ডিপার্টমেন্টকে জানানো উচিত'));
    expect(text, allOf(contains('কে ভুল করেছে'), contains('কেন ভুলটি হলো')));
    expect(_reject('near', 'blame'), allOf(contains('কে ভুল করেছে'), contains('কেন ভুলটি হলো')));
    expect(pack.earnedBn, allOf(contains('সাথে সাথে'), contains('Near Miss'), contains('ঘটনাস্থল')));
  });

  test('rulings M7-3 / X2 / X7: no deadly act on a board; the Do level\'s wire and zone are not here', () {
    // The deadly acts of lesson 7.7 (letting the coworker coil a wire not
    // proven dead, entering a fallen wire's zone) belong to do_7_7_a. The
    // board teaches with the lesson's words: its traps are slips (R22), the
    // myth's listening is a slip (R30 / X2: myth 1 here pushes silence).
    expect(pack.myth.believeNoIsCorrect, isTrue);
    for (final l in _allText()) {
      expect(l, isNot(contains('কয়েল')), reason: '"$l": no coiling a wire on this board');
      expect(l, isNot(contains('জোন')), reason: '"$l": no zone on this board');
    }
    // X7: the cow lies by a fallen service wire; the lineman keeps back (the
    // fallen-wire zone is 10 m) and phones from a distance.
    expect(_opt('must', 'cow').labelBn, contains('দূর থেকে'));
    // No DO, no AB switch stroke here: the DTR is only scorched (M7-9).
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
      'must': ['গরু', 'DTR', 'হাসপাতাল', 'ছুটি'],
      'duty': ['ডাক্তার', 'ফোন', 'ক্লিনিক'],
      'note': ['পোল', 'ব্যান্ডেজ', 'প্রত্যক্ষদর্শী', 'নাম-বয়স'],
      'scene': ['বালি', 'ফুলকি', 'মই', 'ফিউজ', 'ভ্যান'],
      'near': ['স্প্যানার', 'নোট পাঠানো'],
    };
    for (final e in onlyOne.entries) {
      for (final t in right(e.key)) {
        for (final one in e.value) {
          expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
        }
      }
    }
  });

  test('every picture exists (vector scenes from tool/m7_board77_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board77 folder is a card on the board', () {
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
        // The note round is a desk (the note is the picture); every other
        // card has a worker in it.
        if (s.id != 'note') expect(of(o.asset).contains('lineman'), isTrue, reason: '${o.asset}: a worker on every card');
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

  // A trap drawn as a safe card with only a move or a turn (the first log
  // round had log_nocancel as log_issue with the permit tilted) leaves the
  // player guessing. What a card says is its props and figures and its
  // readable marks (the art script tags them <!--mark:name-->: the digits of
  // a number or time, a signature, the cancel cross, the clock), counted.
  test('no trap is a near-copy of a safe card of its round', () {
    final re = RegExp(r'<!--(?:prop|mark):(\w+)-->');
    List<String> says(String asset) => re.allMatches(File(asset).readAsStringSync()).map((m) => m.group(1)!).toList()..sort();
    for (final s in pack.slots) {
      for (final safe in s.options.where((o) => o.correct)) {
        final mine = says(safe.asset);
        expect(mine, isNotEmpty, reason: safe.asset);
        for (final trap in s.options.where((o) => !o.correct)) {
          expect(says(trap.asset), isNot(orderedEquals(mine)), reason: '${s.id}: ${trap.id} says just what ${safe.id} says');
        }
      }
    }
  });

  // What each card's label says is drawn: the dead cow beside a fallen
  // wire, the scorched DTR, the three crossed days, the clinic, the icons of
  // a full note, the sand and the shovel.
  test('the pictures show what the labels say', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync();
    Set<String> props(String card) => RegExp(r'<!--prop:(\w+)-->').allMatches(svg(card)).map((m) => m.group(1)!).toSet();
    int crossed(String card) => 'l8 8 M'.allMatches(svg(card)).length;
    // Must: the cow by the wire, the phone at a distance; the scorched DTR;
    // three days crossed off in a hospital bed (a trap shows the same bed).
    expect(props('must_cow'), containsAll(['cow', 'wire', 'phone']));
    expect(props('must_walk'), containsAll(['cow', 'wire']));
    expect(props('must_dtr'), containsAll(['dtr', 'phone']));
    expect(svg('must_dtr'), contains('fill="#3A3F45"'), reason: 'must_dtr: the DTR is sooty');
    expect(props('must_gate'), containsAll(['dtr', 'gate', 'padlock']));
    for (final c in ['must_bed', 'must_leave']) {
      expect(props(c), containsAll(['bed', 'calendar', 'clipboard']), reason: c);
      expect(crossed(c), 3, reason: '$c: three days crossed off');
    }
    expect(props('must_leave'), contains('umbrella'), reason: 'on leave');
    // The cow is drawn without gore: no red on the cow card's animal.
    expect(svg('must_cow'), isNot(contains('blood')));
    // Duty: the clinic and the bandaged hand on every card; the ladder only
    // where the colleague goes back up.
    for (final o in _slot('duty').options) {
      expect(props('duty_${o.id}'), containsAll(['clinic', 'bandage', 'phone']), reason: o.id);
    }
    expect(props('duty_tea'), containsAll(['cup', 'ladder']));
    expect(props('duty_home'), contains('bag'));
    // Note: the icons of a full note (date, time, pole, name, house) or
    // (fall, bandaged hand, witness); the vague one only a question mark.
    expect(props('note_when'), containsAll(['cal', 'clock', 'polei', 'personi', 'house', 'digits']));
    expect(props('note_how'), containsAll(['fall', 'handi', 'eye']));
    expect(props('note_vague'), containsAll(['qmark']));
    expect(props('note_hide'), containsAll(['tick', 'handi']), reason: '"nobody hurt" beside a bandaged hand');
    expect(props('note_over'), containsAll(['flame', 'glove']), reason: 'a blown-up account of one burnt glove');
    // Scene: nothing touched on the safe pictures; sand and a shovel on the
    // ember; a new fuse; a sack and a shovel for the sweep.
    expect(props('scene_asis'), containsAll(['ladder', 'spanner', 'van']));
    expect(props('scene_sand'), containsAll(['shovel', 'sand', 'oil']));
    expect(props('scene_ladder'), contains('ladder'));
    expect(props('scene_fuse'), contains('fuse'));
    expect(props('scene_sweep'), containsAll(['sack', 'shovel']));
    // Near: the spanner by the helper on every card.
    for (final o in _slot('near').options) {
      expect(props('near_${o.id}'), contains('spanner'), reason: o.id);
    }
    expect(props('near_tell'), contains('phone'));
    expect(props('near_write'), contains('paper'));
    expect(props('near_laugh'), contains('laugh'));
    expect(props('near_sign'), containsAll(['van', 'paper']));
    expect(props('near_blame'), contains('finger'));
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _norm(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1 (ruling M7-10)');
    expect(m.rivalLineBn, 'দুর্ঘটনা রিপোর্ট করলে আমার বা আমার সুপারভাইজারের চাকরি চলে যেতে পারে, তাই চুপ করে থাকাই ভালো।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'hiding an accident is a big legal offence');
    final reality = _norm(_myths[0]['reality'] as String);
    expect(reality, allOf(contains('লুকিয়ে রাখাটা একটি বড় আইনি অপরাধ'), contains('ভালো সুরক্ষা সংস্কৃতির'), contains('শাস্তি দিতে নয়')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('আইনি অপরাধ')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('সুরক্ষা সংস্কৃতি')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('শাস্তি দিতে নয়')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line and the sting are already recorded; the new ones wait
    // for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board77Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board77Lines.newRivalLines, M7Board77Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board77Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board77Lines.guideSpoken;
    expect(M7Board77Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 16 trap reasons + 18 right reasons (4+4+4+3+3) + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 16 + 18 + 3 + 1));
    expect(spoken, contains(pack.introBn));
    expect(spoken, contains(pack.earnedBn));
    // The sting is already recorded (the board 6.3 clip): not listed as new.
    expect(spoken, isNot(contains(pack.myth.stingBn)));
    final sting = LearnVoice.resolve(pack.myth.stingBn);
    expect(sting, isNotNull, reason: 'guide clip for "${pack.myth.stingBn}"');
    expect(File('assets/$sting').existsSync(), isTrue);
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

    testWidgets('a wrong picture (the crew walks away from the dead cow) teaches with the lesson\'s words; no reason deck, no freeze', (t) async {
      final c = await _open(t);
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is the lesson's point 1. The first round has three traps
      // and a hand of four, so every hand holds this one.
      final must = _slot('must');
      await _settleHand(t, 'pick', {'walk'}, 'must: the crew walking away from the cow');
      await tapBoardCard(t, _dealt('pick', {'walk'}));
      await _pumpUntil(t, () => find.text(_reject('must', 'walk')).evaluate().isNotEmpty, what: 'the trap\'s reason');
      expect(find.byType(FreezeFrame), findsNothing, reason: 'boards teach; they never freeze');
      for (final w in must.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the "কেন" deck');
      }
      expect(find.byType(LevelFailPanel), findsNothing, reason: 'one miss does not end the board');
      // The board goes on: past the feedback, a fresh hand with a safe card.
      await continueBoard(t);
      await _cleanRound(t, must);
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.7', ladderIndex: _ladder, pack: pack, muted: true),
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
