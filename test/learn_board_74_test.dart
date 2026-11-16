// Module 7 lesson 7.4 picture board ("পারমিট-টু-ওয়ার্ক (PTW): একটি আইনি
// চুক্তি", rung 7.4/learn, pack learn_7_4): its content follows the board's
// rules, the Module 7 rulings (M7-2: the unsigned field copy is the module's
// deadly act; M7-10: the lesson's myth word for word; X3: PTW for any shutdown
// work, HT or LT; O1: the field memo only in the lesson's own words; X6: 5
// rounds, the owner's term rules) and the lesson's points (the two
// signatures, every copy filled and signed, the logbook, clear talk and asking
// again, every team member's part), every picture exists and no colour,
// backdrop, prop or figure marks the safe card (in any hand the dealer can
// make), the rival's myth is the lesson's own and every spoken line is listed
// for recording, a clean play (picks, reasons, the rival's myth) clears the
// rung, a miss on every round fails it (the board's strike-out), the
// deadly-class trap (the field copy with no issuer signature) teaches with the
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
import 'package:slm_flutter/features/game/learn_board_pack74.dart';
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

const pack = learnBoardPack74;
const _artDir = 'assets/game/art/m7_board74';
const _rung = '7.4/learn';
const _ladder = 192; // m7 starts at 183; 7.4/learn is its 10th rung (orderInModule 9)

/// Has read lesson 7.4 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_4', '7.4']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.4', ladderIndex: _ladder, pack: pack, muted: true),
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
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.4');
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

  test('the lesson 7.4 board: five rounds (ruling X6 drops the spec\'s round 6)', () {
    expect(pack.lessonId, '7.4');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.4 entry.
    final registered = learnBoardPackFor('7.4');
    if (registered != null) expect(registered, same(learnBoardPack74));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['sign', 'copies', 'log', 'talk', 'crew'], reason: '5 rounds');
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

  test('no figures or legal terms the lesson does not give: no 18 kV, no section, fine or prison term', () {
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp(r'\d'))), reason: '"$l": no numbers on this board (18 kV is obsolete, X3)');
      for (final no in ['ধারা', 'জরিমানা', 'কারাদণ্ড', 'জেল', 'আদালত', 'kV']) {
        expect(l, isNot(contains(no)), reason: '"$l": unsupported in the lesson');
      }
    }
    // Ruling O1: the field memo only in the lesson's own words (the LT
    // trap's reason, the live safety tip).
    final memo = [for (final l in _allText()) if (l.contains('ফিল্ড মেমো')) l];
    expect(memo, [_reject('crew', 'lt')]);
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

  test('the lesson\'s points: the signatures, the copies, the logbook, the talk, the crew', () {
    final text = _lessonText;
    // Point 2: the issuer (line isolated and locked); the receiver (knows the
    // danger, keeps the team safe, hands the line back safe).
    expect(_safeIds('sign'), {'issuer', 'receiver', 'ret'});
    expect(_trapIds('sign'), {'phone', 'tea', 'blank', 'early'});
    expect(text, contains(_reject('sign', 'phone')), reason: 'point 2 word for word');
    expect(text, allOf(contains('বিচ্ছিন্ন এবং লক করা হয়েছে'), contains('তার টিমের সুরক্ষা নিশ্চিত করবেন'), contains('নিরাপদ অবস্থায় ফেরত দেবেন')));
    expect(_reject('sign', 'blank'), contains('বিচ্ছিন্ন এবং লক করা হয়েছে'));
    expect(_reject('sign', 'tea'), contains('টিমের সুরক্ষা নিশ্চিত করবেন'));
    expect(_reject('sign', 'early'), contains('নিরাপদ অবস্থায় ফেরত'));
    // Pro tip 1: every copy filled and signed; the unsigned field copy
    // carries myth 1's reality (the module's deadly act, M7-2 / R1).
    expect(_safeIds('copies'), {'both', 'field'});
    expect(_trapIds('copies'), {'nosign', 'twonum', 'blank'});
    expect(text, contains(_reject('copies', 'blank')), reason: 'pro tip 1 word for word');
    expect(text, contains(_reject('copies', 'nosign')), reason: 'myth 1\'s reality word for word');
    expect(_reject('copies', 'twonum'), contains('প্রতিটি কপি সঠিকভাবে পূরণ'));
    // Pro tip 3: issue and cancellation, time and date, in the formal logbook.
    expect(_safeIds('log'), {'issue', 'cancel'});
    expect(_trapIds('log'), {'notime', 'nocancel', 'chit'});
    expect(text, allOf(contains('ইস্যু এবং বাতিলের সময় এবং তারিখ'), contains('আনুষ্ঠানিক লগবুকে'), contains('গুরুত্বপূর্ণ আইনি নথি')));
    for (final o in ['notime', 'nocancel', 'chit']) {
      expect(_reject('log', o), contains('আনুষ্ঠানিক লগবুকে'), reason: o);
    }
    expect(_reject('log', 'chit'), contains('গুরুত্বপূর্ণ আইনি নথি'));
    // Pro tips 2 and 4: clear talk, ask again; 'আমি ভেবেছিলাম...' has no
    // place; a condition not understood is explained before signing.
    expect(_safeIds('talk'), {'ask', 'learn'});
    expect(_trapIds('talk'), {'thought', 'blind', 'noisy'});
    expect(text, contains(_reject('talk', 'thought')), reason: 'pro tip 2 word for word');
    expect(text, allOf(contains('পরিষ্কার এবং দ্ব্যর্থহীন'), contains('বুঝতে পারছেন না'), contains('সুপারভাইজারের কাছ থেকে তা বুঝে নিন')));
    expect(_reject('talk', 'blind'), contains('সুপারভাইজারের কাছ থেকে তা বুঝে নিন'));
    expect(_reject('talk', 'noisy'), contains('দ্ব্যর্থহীন'));
    // Myth 2's reality and the live safety tip (X3: HT or LT).
    expect(_safeIds('crew'), {'read', 'stand'});
    expect(_trapIds('crew'), {'dontknow', 'ladder', 'lt'});
    expect(text, contains(_reject('crew', 'dontknow')), reason: 'myth 2\'s reality word for word');
    expect(text, allOf(contains('আপনিও সমানভাবে দায়ী হতে পারেন'), contains('শাটডাউন নিয়ে যেকোনো লাইনে কাজের আগে লিখিত অনুমতি')));
    expect(_reject('crew', 'ladder'), contains('আপনিও সমানভাবে দায়ী হতে পারেন'));
    // The safety tip with LT / HT in English letters (owner term rule).
    final tip = _reject('crew', 'lt').replaceFirst('HT', 'এইচটি').replaceFirst('LT', 'এলটি');
    expect(text, contains(tip), reason: 'the live safety tip, word for word but for the letters');
    expect(pack.earnedBn, allOf(contains('লিখিত, সই করা PTW'), contains('আইনি দায়িত্ব'), contains('আবার জিজ্ঞাসা')));
  });

  test('ruling M7-2: the unsigned field copy is the deadly-class trap; the rest are slips', () {
    // R1 is the only deadly act on this board (boards have no freeze: it
    // teaches). R3 slips: two numbers, a blank control-room copy, signing
    // a condition not understood. R6 slip: the time on a chit.
    expect(_opt('copies', 'nosign').correct, isFalse);
    expect(_opt('copies', 'nosign').labelBn, contains('ফিল্ড কপিতে ইস্যুকারীর সই নেই'));
    // The coworker's push (the myth: a spoken 'line off', no paper) is
    // rejected (believe = no).
    expect(pack.myth.believeNoIsCorrect, isTrue);
    // No DO, no AB stroke on this board: the isolation is drawn as a
    // padlocked, tagged switch panel (M7-9).
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
      // One signer's duty (the issuer's lock, the receiver's team) fits one
      // signature only; the round's right reasons speak of every signature.
      'sign': ['অপারেটর', 'নিচে', 'নামার', 'টেবিল', 'ইস্যুকারী', 'গ্রহণকারী', 'বিচ্ছিন্ন', 'টিম'],
      'copies': ['হাতে', 'এক নম্বর'],
      'log': ['ফেরত এসেছে'],
      'talk': ['ইস্যুকারীকে', 'ফোন'],
      // The LT tip and 'taking part makes you liable' fit only the standing
      // back, not the reading of the permit.
      'crew': ['নম্বর', 'হাত দিচ্ছেন', 'LT', 'HT', 'অংশ'],
    };
    for (final e in onlyOne.entries) {
      for (final t in right(e.key)) {
        for (final one in e.value) {
          expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
        }
      }
    }
  });

  test('every picture exists (vector scenes from tool/m7_board74_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board74 folder is a card on the board', () {
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

  // What each card's label says is drawn: the signatures in the boxes, the
  // padlocked panel, the two numbers, the empty cells, the chit, the bubbles,
  // the LT rack, the missing paper.
  test('the pictures show what the labels say', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync();
    Set<String> props(String card) => RegExp(r'<!--prop:(\w+)-->').allMatches(svg(card)).map((m) => m.group(1)!).toSet();
    int signatures(String card) => 'stroke="#2346A0"'.allMatches(svg(card)).length;
    Set<String> marks(String card) => RegExp(r'<!--mark:(\w+)-->').allMatches(svg(card)).map((m) => m.group(1)!).toSet();
    // Sign: both boxes signed on every card but the blank issuer box.
    for (final c in ['sign_issuer', 'sign_receiver', 'sign_ret', 'sign_phone', 'sign_tea', 'sign_early']) {
      expect(signatures(c), 2, reason: c);
    }
    expect(signatures('sign_blank'), 1, reason: 'sign_blank: the issuer box is empty');
    for (final c in ['sign_issuer', 'sign_phone', 'sign_blank']) {
      expect(props(c), containsAll(['panel', 'lock', 'officer']), reason: '$c: the feeder OFF, padlocked and tagged');
    }
    expect(props('sign_phone'), contains('phone'));
    expect(props('sign_tea'), containsAll(['cup', 'stall']));
    // Copies: two forms, four signatures; the field copy with one missing.
    for (final c in ['copies_both', 'copies_twonum', 'copies_blank']) {
      expect(signatures(c), 4, reason: c);
    }
    expect(signatures('copies_field'), 2);
    expect(signatures('copies_nosign'), 1, reason: 'copies_nosign: no issuer signature on the field copy');
    expect(svg('copies_twonum'), isNot(svg('copies_both')), reason: 'a second number');
    // Log: the chit; every card has the logbook, the permit and the clock.
    for (final o in _slot('log').options) {
      expect(props('log_${o.id}'), containsAll(['logbook', 'form', 'officer', 'clock']), reason: o.id);
    }
    expect(props('log_chit'), contains('chit'));
    // The permit came back: the return cards (one safe, one trap) show the
    // work over (the permit struck through, the crew back, the clock at
    // 2:20); the issue cards show none of it (the clock at 10:30). So the
    // empty cancellation cell on log_nocancel reads as a miss, never as
    // log_issue's row.
    for (final c in ['log_cancel', 'log_nocancel']) {
      expect(props(c), containsAll(['returned', 'lineman']), reason: '$c: the permit is back, the crew in the room');
      expect(marks(c), containsAll(['cancelled', 'clock0220']), reason: c);
    }
    for (final c in ['log_issue', 'log_notime', 'log_chit']) {
      expect(props(c), isNot(contains('returned')), reason: c);
      expect(marks(c), contains('clock1030'), reason: c);
    }
    expect(props('log_issue').difference(props('log_nocancel')).union(props('log_nocancel').difference(props('log_issue'))),
        contains('returned'), reason: 'log_issue and log_nocancel differ in a tagged prop');
    // Talk: a question bubble when asking, a thought cloud for 'I thought',
    // the phone's crackle; the pen held up (capped) while asking first.
    for (final c in ['talk_ask', 'talk_learn', 'talk_thought', 'talk_noisy']) {
      expect(props(c), contains('bubble'), reason: c);
    }
    expect(props('talk_noisy'), contains('phone'));
    // 'I thought...': the assumption is drawn (the switch handle down and a
    // tick in the cloud, no question mark), and he is walking off; the safe
    // cards ask (a question mark).
    const qmark = 'a3 3 0 1 1 4 3';
    expect(svg('talk_thought'), isNot(contains(qmark)), reason: 'talk_thought: no doubt, a settled assumption');
    expect(svg('talk_thought'), contains('l4 5 l8 -11'), reason: 'talk_thought: the tick in the cloud');
    for (final c in ['talk_ask', 'talk_learn']) {
      expect(svg(c), contains(qmark), reason: '$c: a question');
    }
    expect(svg('talk_learn'), contains('l2 -11'), reason: 'talk_learn: the pen held up, away from the paper');
    expect(props('talk_blind'), contains('pen'));
    // Crew: the permit read before the climb; no paper where there is none;
    // the LT rack only on the LT pole.
    expect(props('crew_read'), containsAll(['form', 'ladder']));
    // 'Why should I know the permit?': the supervisor holds the permit out,
    // the climber has his back to it and waves it off (the permit struck out
    // in his bubble).
    expect(props('crew_dontknow'), containsAll(['form', 'supervisor', 'aloft', 'bubble']));
    // A man aloft on a safe card and on a trap, none on another: being up the
    // pole gives nothing away.
    expect(props('crew_read'), contains('aloft'));
    expect(props('crew_lt'), isNot(contains('aloft')), reason: 'crew_lt: the ladder set up to start');
    for (final c in ['crew_stand', 'crew_ladder', 'crew_lt']) {
      expect(props(c), isNot(contains('form')), reason: '$c: no permit at the site');
    }
    expect(props('crew_lt'), contains('ltrack'));
    for (final c in ['crew_read', 'crew_stand', 'crew_dontknow', 'crew_ladder']) {
      expect(props(c), isNot(contains('ltrack')), reason: c);
    }
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _norm(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1 (ruling M7-10)');
    expect(m.rivalLineBn, 'সুপারভাইজার মুখে মুখে বলে দিয়েছেন লাইন বন্ধ আছে, তাই আর কাগজের পারমিটের দরকার নেই।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'a spoken order has no legal basis');
    final reality = _norm(_myths[0]['reality'] as String);
    expect(reality, allOf(contains('মৌখিক নির্দেশের কোনো আইনি ভিত্তি নেই'), contains('ভুল বোঝাবুঝির'), contains('লিখিত, স্বাক্ষরিত PTW ছাড়া')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('মৌখিক নির্দেশের কোনো আইনি ভিত্তি নেই')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('ভুল বোঝাবুঝি')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line and the sting are already recorded; the new ones wait
    // for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board74Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board74Lines.newRivalLines, M7Board74Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board74Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board74Lines.guideSpoken;
    expect(M7Board74Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 16 trap reasons + 5×3 right reasons + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 16 + 15 + 3 + 1));
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

    testWidgets('the deadly-class trap (field copy with no issuer signature) teaches with the lesson\'s words; no reason deck, no freeze', (t) async {
      final c = await _open(t);
      await _cleanRound(t, _slot('sign'));
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is myth 1's reality word for word. The copies round has
      // three traps and a hand of four, so every hand holds it.
      final copies = _slot('copies');
      await _settleHand(t, 'pick', {'nosign'}, 'copies: the unsigned field copy');
      await tapBoardCard(t, _dealt('pick', {'nosign'}));
      await _pumpUntil(t, () => find.text(_reject('copies', 'nosign')).evaluate().isNotEmpty, what: 'the trap\'s reason');
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.4', ladderIndex: _ladder, pack: pack, muted: true),
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
