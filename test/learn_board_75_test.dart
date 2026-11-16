// Module 7 lesson 7.5 picture board ("বিদ্যুৎ চুরি: একটি অপরাধ এবং তার বিপদ",
// rung 7.5/learn, pack learn_7_5): its content follows the board's rules, the
// live lesson and the Module 7 rulings (M7-8: tester live-dead-live and the
// earth before the hook; M7-9: the lane DTR is an AB switch + HG fuses, no DO;
// X6: five rounds; the owner's term rules), every picture exists and no
// colour, backdrop or prop marks the safe card (in any hand the dealer can
// make), the pictures show the isolation where the lesson asks for it, the
// rival's myth is the lesson's own and every spoken line is listed for
// recording, a clean play (picks, reasons, the rival's myth) clears the rung,
// a miss on every round fails it (the board's strike-out), a wrong pick says
// the trap's own reason and opens no reason deck, the gesture hint sweeps
// without pressing, and the board waits quietly once dealt.
//
// Boards have no deadly freeze (kit design, GAME_DEVELOPER_GUIDE §10c): the
// deadly-class traps (a hook taken off a live line, a hand on the hook before
// the tester's 0 V, no earth — rows R13, N1, N2) cost a ◆ and say the lesson's
// own words; the tests below pin those words.
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
import 'package:slm_flutter/features/game/learn_board_pack75.dart';
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

const pack = learnBoardPack75;
const _artDir = 'assets/game/art/m7_board75';
const _rung = '7.5/learn';
const _ladder = 195;

/// Has read lesson 7.5 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_5', '7.5']));
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

/// The option ids of the dealt [prefix] cards.
Set<String> _dealtIds(String prefix) => {
      for (final e in find.byWidgetPredicate((w) {
        final k = w.key;
        return w.runtimeType.toString() == '_AnimatedChoiceCard' && k is ValueKey<String> && k.value.startsWith('$prefix-');
      }).evaluate())
        (e.widget.key! as ValueKey<String>).value.split('-').skip(2).join('-'),
    };

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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.5', ladderIndex: _ladder, pack: pack, muted: true),
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
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.5');
}

Map<String, dynamic> get _content => _lesson()['content'] as Map<String, dynamic>;

/// All the lesson's text in one string (sections, myths, pro tips), term
/// rules applied, for "this line is the lesson's own" checks.
String get _lessonText => _terms(jsonEncode(_content).replaceAll(r'\n', ' '));

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

  test('the lesson 7.5 board: five rounds (ruling X6)', () {
    expect(pack.lessonId, '7.5');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.5 entry.
    final registered = learnBoardPackFor('7.5');
    if (registered != null) expect(registered, same(learnBoardPack75));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    // The item spec's six rounds trimmed to five: its evidence round left the
    // board (do_7_5_b plays the evidence shot).
    expect(pack.slots.map((s) => s.id), ['legal', 'danger', 'signs', 'act', 'remove'], reason: '5 rounds');
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
      // Ruling M7-9: no DO anywhere in Module 7.
      for (final no in ['ড্রপ আউট', 'ডিও', 'DO ফিউজ']) {
        expect(l, isNot(matches(RegExp('(?<![ঀ-৿])$no'))), reason: '"$l": no DO in Module 7');
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

  test('the lesson\'s points: s.135 theft, its dangers, the signs, what to do on seeing it', () {
    final text = _lessonText;
    // Section 1: the four kinds of theft under s.135.
    expect(_safeIds('legal'), {'sealed', 'ab'});
    expect(_trapIds('legal'), {'hook', 'magnet', 'upstream', 'bypass'});
    expect(text, allOf(contains('135'), contains('হুকিং করে বিদ্যুৎ ব্যবহার করা')));
    expect(_reject('legal', 'hook'), allOf(contains('অবৈধভাবে হুকিং করে বিদ্যুৎ ব্যবহার করা'), contains('135')));
    expect(text, contains('মিটারের আগে থেকে (Upstream) সংযোগ নিয়ে বিদ্যুৎ ব্যবহার করা'));
    expect(_reject('legal', 'upstream'), contains('মিটারের আগে থেকে (Upstream) সংযোগ নিয়ে বিদ্যুৎ ব্যবহার করা'));
    expect(_reject('legal', 'magnet'), allOf(contains('রিডিং-কে প্রভাবিত'), contains('ট্যাম্পারিং')));
    expect(_reject('legal', 'bypass'), allOf(contains('সিল ভেঙে'), contains('বাইপাস')));
    for (final id in _safeIds('legal')) {
      expect(_opt('legal', id).labelBn, contains('সিল করা মিটার'), reason: 'legal/$id: through a sealed meter (pro tip 2)');
    }
    // Section 2: dangers (lesson words) and myth 1's reality. The round asks
    // which picture shows harm happening now; each trap shows none yet, and
    // its reason says so (DRAFT) and then the lesson's own words.
    expect(_safeIds('danger'), {'fire', 'hg'});
    expect(_trapIds('danger'), {'tape', 'bright', 'calm'});
    expect(_slot('danger').promptBn, contains('এখনই ক্ষতি'), reason: 'harm happening now, readable from the picture');
    for (final id in _trapIds('danger')) {
      expect(_reject('danger', id).split(' — '), hasLength(2), reason: 'danger/$id: "not yet" — then the lesson');
    }
    expect(text, contains(_reject('danger', 'tape').split(' — ').last), reason: 'section 2 word for word');
    expect(text, contains(_reject('danger', 'calm').split(' — ').last), reason: 'section 2 word for word');
    expect(_terms(_myths[0]['reality'] as String), contains(_reject('danger', 'bright').split(' — ').last),
        reason: 'myth 1\'s reality');
    expect(_opt('danger', 'hg').labelBn, contains('HG ফিউজ'), reason: 'M7-9: a blown HG fuse wire, no DO');
    // Pro tip 1: few consumers, yet overload or low voltage.
    expect(_safeIds('signs'), {'fewhot', 'fewdim'});
    expect(_trapIds('signs'), {'crowdhot', 'crowdbright', 'fewbright'});
    expect(_norm(_proTips[0]), allOf(contains('ওভারলোডেড'), contains('লো-ভোল্টেজ'), contains('গ্রাহকের সংখ্যা সেই তুলনায় কম')));
    for (final id in _safeIds('signs')) {
      expect(_opt('signs', id).labelBn, contains('মাত্র 2টা বাড়ি'), reason: 'signs/$id: few houses');
    }
    expect(_reject('signs', 'crowdhot'), contains('গ্রাহক কম'));
    // Section 3: safety first, evidence from a distance, report; no confronting.
    expect(_safeIds('act'), {'photo', 'call'});
    expect(_trapIds('act'), {'argue', 'climb', 'walk', 'close'});
    expect(text, contains(_reject('act', 'argue')), reason: 'section 3 word for word');
    for (final sentence in _reject('act', 'climb').split('। ')) {
      expect(text, contains(sentence), reason: 'section 3 word for word');
    }
    expect(_terms(_myths[1]['reality'] as String), contains(_reject('act', 'walk')), reason: 'myth 2\'s reality');
    expect(text, contains(_reject('act', 'close').split(' — ').last), reason: 'section 3: from a distance');
    expect(text, contains(_reject('act', 'close').split(' — ').first), reason: 'section 3: the bullet\'s heading');
    expect(_opt('act', 'call').labelBn, allOf(contains('সুপারভাইজার'), contains('ভিজিল্যান্স')));
    expect(_opt('act', 'photo').labelBn, contains('দূরে'));
    expect(pack.earnedBn, allOf(contains('দূর থেকে'), contains('রিপোর্ট'), contains('নির্দেশে'), contains('ডেড প্রমাণ'), contains('আর্থ')));
  });

  test('ruling M7-8: tester and earth before the hook — the remove round says the lesson\'s own words', () {
    final tip4 = _terms(_proTips[3]);
    expect(tip4, contains('টেস্টার দিয়ে ডেড প্রমাণ করা, আর্থ লাগানো এবং সম্পূর্ণ PPE'));
    expect(tip4, endsWith(_reject('remove', 'live')), reason: 'pro tip 4 word for word');
    expect(_safeIds('remove'), {'safe', 'order'});
    expect(_trapIds('remove'), {'live', 'notest', 'noearth', 'alone'});
    // Both safe cards: the tester at 0 and the earth on (M7-8).
    for (final id in _safeIds('remove')) {
      expect(_opt('remove', id).labelBn, allOf(contains('টেস্টারে 0'), contains('আর্থ দিয়ে')), reason: 'remove/$id');
    }
    expect(_opt('remove', 'safe').labelBn, allOf(contains('AB খোলা'), contains('গ্লাভস')));
    // N1 (no 0 V yet; the tester proved on a live point first, A9) and N2 (no earth).
    expect(_reject('remove', 'notest'), allOf(contains('চালু লাইনে টেস্টার যাচাই'), contains('ডেড প্রমাণ')));
    expect(_reject('remove', 'noearth'), allOf(contains('আর্থ'), contains('অপরিহার্য')));
    // R13: the AB still closed — «লাগানো», never «AB বন্ধ».
    expect(_opt('remove', 'live').labelBn, contains('AB লাগানো'));
    // Only on the authority's order (section 3 word for word).
    expect(_lessonText, contains(_reject('remove', 'alone')));
    // Wrong reasons carry the shortcuts, never a right chip.
    expect(_slot('remove').whyChips.any((w) => !w.correct && w.textBn.contains('গ্লাভস পরা থাকলে চালু লাইনেও')), isTrue);
    expect(_slot('remove').whyChips.any((w) => !w.correct && w.textBn.contains('টেস্টার লাগে না')), isTrue);
    expect(_slot('remove').whyChips.any((w) => !w.correct && w.textBn.contains('আর্থের আর দরকার নেই')), isTrue);
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's or one trap's.
  test('right reasons fit every safe pick of their round', () {
    List<String> right(String slot) => [for (final w in _slot(slot).whyChips) if (w.correct) w.textBn];
    final oneCard = {
      'legal': ['AB', 'কানেক্টর', 'খুঁটি'],
      'danger': ['আগুন', 'খড়', 'HG', 'অন্ধকার'],
      'signs': ['বাল্ব', 'গরম', 'HG'],
      'act': ['ছবি', 'ফোন', 'গাড়ি', 'ভিজিল্যান্স'],
      'remove': ['অফিসার', 'পুলিশ', 'AB'],
    };
    for (final e in oneCard.entries) {
      for (final t in right(e.key)) {
        for (final one in e.value) {
          expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
        }
      }
    }
  });

  test('every picture exists (vector scenes from tool/m7_board75_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board75 folder is a card on the board', () {
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
  // worker, a phone, the van, the tester, the earth set, the officer... In
  // every hand, nothing sits only on the safe card, and nothing sits on every
  // trap but not the safe card (the odd one out would be the answer).
  //
  // One narrow exception (mirrors ANSWER_PROPS in tool/m7_board75_art.py):
  // the danger round asks which picture shows harm happening now, so the
  // spark and the fire are the answer itself and may sit on a safe card
  // alone. Their colours are still on the traps (the tests above).
  const answerProps = {
    'danger': {'spark', 'fire'},
  };
  test('in every possible hand, no prop or figure marks the safe card', () {
    final tagRe = RegExp(r'<!--prop:(\w+)-->');
    final props = <String, Set<String>>{};
    Set<String> of(String asset) => props.putIfAbsent(
        asset, () => tagRe.allMatches(File(asset).readAsStringSync()).map((m) => m.group(1)!).toSet());

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
          expect(of(safe.asset).difference(onTraps).difference(answerProps[s.id] ?? const <String>{}), isEmpty,
              reason: '$ids — a prop only on the safe card');
          expect(onEveryTrap.difference(of(safe.asset)), isEmpty, reason: '$ids — a prop on every trap but the safe card');
        }
      }
    }
  });

  // Rulings M7-8 / M7-9 in the pictures: the remove round's safe cards have
  // the DTR's AB open (all three blades up) and tagged OFF, the tester at 0
  // and the earth set clamped on the span; the traps show what is missing.
  test('the pictures show the isolation where the lesson asks for it', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    Set<String> props(String card) =>
        RegExp(r'<!--prop:(\w+)-->').allMatches(File('$_artDir/$card.svg').readAsStringSync()).map((m) => m.group(1)!).toSet();
    final upBlade = RegExp(r'<path d="M[\d.]+ 30 L[\d.]+ 14" stroke="url\(#steel\)" stroke-width="2.8"');
    const offTagGlyph = 'stroke="#D8402F" stroke-width="1.2"'; // the OFF letters on the tag
    const clampedEarth = 'L120 120'; // the earth lead down from the clamps to its rod
    const gloves = 'fill="#2A2D33"';
    for (final c in ['remove_safe', 'remove_order']) {
      expect(upBlade.allMatches(svg(c)).length, 3, reason: '$c: all three AB blades open');
      expect(svg(c), contains(offTagGlyph), reason: '$c: the OFF tag on the AB handle');
      expect(props(c), containsAll(['tester', 'earthset', 'offtag']), reason: c);
      expect(svg(c), contains(clampedEarth), reason: '$c: the earth set on the span');
      expect(svg(c), contains(gloves), reason: '$c: gloves on');
    }
    expect(props('remove_order'), containsAll(['officer', 'constable', 'order']), reason: 'the order and the police in view');
    expect(upBlade.allMatches(svg('remove_live')).length, 0, reason: 'remove_live: the AB is closed');
    expect(svg('remove_live'), contains('fill="url(#glow)"'), reason: 'remove_live: a flash at the hook');
    expect(upBlade.allMatches(svg('remove_alone')).length, 0, reason: 'remove_alone: the AB is closed');
    expect(props('remove_alone'), isNot(contains('offtag')));
    for (final c in ['remove_notest', 'remove_noearth']) {
      expect(upBlade.allMatches(svg(c)).length, 3, reason: '$c: the AB open…');
      expect(svg(c), isNot(contains(clampedEarth)), reason: '…but the earth set lies coiled on the ground');
    }
    // N1: the tester lies unused (blank screen) on the notest trap.
    expect(svg('remove_notest'), isNot(contains('stroke="#1D2B22"')), reason: 'remove_notest: no reading on the tester');
    // Act: the climb trap pulls the hook bare-handed (a flash); the call is by phone.
    expect(props('act_climb'), contains('ladder'));
    expect(svg('act_climb'), contains('fill="url(#glow)"'));
    expect(props('act_call'), containsAll(['phone', 'van']));
    // Danger: the lane DTR has an AB switch + HG fuses (no DO); on the hg
    // card one HG wire is blown.
    for (final c in ['danger_hg', 'danger_calm']) {
      expect(props(c), contains('dtr'), reason: c);
    }
    // Danger traps are wrong by what they show: no spark, no fire, no flash
    // anywhere on them (the harm sits only on the safe cards).
    for (final id in _trapIds('danger')) {
      final c = 'danger_$id';
      expect(props(c), isNot(contains('spark')), reason: '$c: no spark drawn');
      expect(props(c), isNot(contains('fire')), reason: '$c: no fire drawn');
      expect(svg(c), isNot(contains('Z" fill="#D8402F"')), reason: '$c: no flame shape');
    }
    expect(props('danger_fire'), containsAll(['spark', 'fire']));
    expect(svg('danger_fire'), contains('Z" fill="#D8402F"'), reason: 'danger_fire: the flames');
    // Act: the walk-off (his back to the house) still carries the phone and
    // the van, so the call card's props are never its own.
    expect(props('act_walk'), containsAll(['phone', 'van']));
  });

  test('the careless lineman says the lesson\'s second myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _terms(_myths[1]['myth'] as String), reason: 'the lesson\'s own myth 2 (the item spec\'s mythBn)');
    expect(m.rivalLineBn, 'বিদ্যুৎ চোরকে ধরা আমার কাজ নয়, ওটা পুলিশের কাজ।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'spotting and reporting theft is the company workers\' job');
    final reality = _terms(_myths[1]['reality'] as String);
    expect(reality, allOf(contains('পুলিশ আইন-শৃঙ্খলা রক্ষায় সাহায্য করে'), contains('সচেতনতাই এই অপরাধ কমাতে পারে')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('আইন-শৃঙ্খলা')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('সচেতনতাই')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line and the sting are already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board75Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board75Lines.newRivalLines, M7Board75Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board75Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board75Lines.guideSpoken;
    expect(M7Board75Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
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

    testWidgets('a deadly-class trap (hands on the hook before the isolation is complete) teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      for (final s in pack.slots.takeWhile((s) => s.id != 'remove')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // says its own reason. The remove round has four traps and a hand of
      // four, so every hand holds at least two of the three deadly-class ones
      // (R13 live, N1 no tester, N2 no earth).
      const deadly = {'live', 'notest', 'noearth'};
      final remove = _slot('remove');
      await _settleHand(t, 'pick', deadly, 'remove: a deadly-class trap');
      final picked = _dealtIds('pick').intersection(deadly).first;
      await tapBoardCard(t, _dealt('pick', {picked}));
      await _pumpUntil(t, () => find.text(_reject('remove', picked)).evaluate().isNotEmpty, what: 'the reason for $picked');
      for (final w in remove.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.5', ladderIndex: _ladder, pack: pack, muted: true),
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
