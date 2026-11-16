// Module 7 lesson 7.2 picture board ("ওয়ার্কম্যান কম্পেনসেশন অ্যাক্ট: দুর্ঘটনার
// পর আপনার অধিকার", rung 7.2/learn, pack learn_7_2): its content follows the
// board's rules, the Module 7 rulings (M7-6: no deadly in 7.2; M7-10: the
// lesson's myth word for word; X6: 5 rounds, the owner's term rules) and the
// lesson's points (who is covered, the disablement heads, the rights beside
// compensation, the first steps, the notice, the papers and the claim), every
// picture exists and no colour, backdrop, prop or figure marks the safe card
// (in any hand the dealer can make), the rival's myth is the lesson's own and
// every spoken line is listed for recording, a clean play (picks, reasons, the
// rival's myth) clears the rung, a miss on every round fails it (the board's
// strike-out), a wrong pick says the trap's own reason, opens no reason deck
// and never ends the board (no deadly in 7.2, and boards have no freeze), the
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
import 'package:slm_flutter/features/game/learn_board_pack72.dart';
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

const pack = learnBoardPack72;
const _artDir = 'assets/game/art/m7_board72';
const _rung = '7.2/learn';
const _ladder = 186;

/// Has read lesson 7.2 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['7_2', '7.2']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.2', ladderIndex: _ladder, pack: pack, muted: true),
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
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.2');
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

  test('the lesson 7.2 board: five rounds (ruling X6 trims the spec\'s six)', () {
    expect(pack.lessonId, '7.2');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 7.2 entry.
    final registered = learnBoardPackFor('7.2');
    if (registered != null) expect(registered, same(learnBoardPack72));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.badgeBn, 'আইন কি বলে?');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['who', 'partial', 'rights', 'steps', 'claim'], reason: '5 rounds');
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
      expect(l, isNot(contains('মৃত')), reason: '"$l": «ডেড», never «মৃত» (and no death head on this board)');
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

  test('no figures the lesson does not give: no amounts, no day counts, no Act name or year on screen', () {
    for (final l in _allText()) {
      // The only digit on the board is the pay slip's 0 for the hospital days.
      for (final m in RegExp(r'\d+').allMatches(l)) {
        expect(m.group(0), '0', reason: '"$l": no amounts, ages or day counts (unsupported in the lesson)');
      }
      for (final no in ['1923', '2020', '2025', 'সামাজিক সুরক্ষা কোড', 'ESI', 'আদালত', 'নেশা']) {
        expect(l, isNot(contains(no)), reason: '"$l": left out (L7.2-2 answered: the levels never name the Act; the lesson title is a lesson matter for the director; court and intoxication unsupported)');
      }
    }
    // The Act's name only in the lesson's own title.
    for (final l in _allText().skip(1)) {
      expect(l, isNot(contains('অ্যাক্ট')), reason: '"$l": the Act is not named on screen');
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

  test('the lesson\'s points: who is covered, the disablement heads, the rights, the first steps, the claim', () {
    final text = _lessonText;
    // Point 1: hazardous work incl. electrical; permanent, temporary, contract.
    expect(_safeIds('who'), {'perm', 'contract', 'temp'});
    expect(_trapIds('who'), {'clerk', 'tempno', 'notice'});
    expect(text, allOf(contains('বিদ্যুৎ-এর কাজও অন্তর্ভুক্ত'), contains('স্থায়ী, অস্থায়ী, চুক্তিভিত্তিক')));
    expect(_reject('who', 'clerk'), allOf(contains('স্থায়ী, অস্থায়ী, চুক্তিভিত্তিক'), contains('জন্যই প্রযোজ্য')));
    expect(_reject('who', 'tempno'), contains('অস্থায়ী কর্মীও'));
    expect(_reject('who', 'notice'), contains('বিদ্যুৎ-এর কাজও অন্তর্ভুক্ত'));
    // Point 2: permanent partial (a finger, hand or eye; other work) vs
    // temporary (weeks or months) and permanent total (no work at all).
    expect(_safeIds('partial'), {'finger', 'eye'});
    expect(_trapIds('partial'), {'plaster', 'bed', 'burn'});
    expect(text, allOf(contains('আঙুল, হাত, চোখ'), contains('অন্য কাজ করতে সক্ষম'), contains('কয়েক সপ্তাহ বা মাস')));
    expect(_opt('partial', 'finger').labelBn, contains('অন্য কাজ'));
    expect(_reject('partial', 'plaster'), contains('অস্থায়ী অক্ষমতা'));
    expect(_reject('partial', 'burn'), contains('অস্থায়ী অক্ষমতা'));
    expect(_reject('partial', 'bed'), contains('স্থায়ী সম্পূর্ণ অক্ষমতা'));
    // Point 3: treatment cost, allowance, occupational disease.
    expect(_safeIds('rights'), {'pay', 'allow', 'disease'});
    expect(_trapIds('rights'), {'wife', 'payslip', 'wave'});
    expect(text, contains(_reject('rights', 'wife')), reason: 'point 3\'s own words');
    expect(text, contains('নির্দিষ্ট হারে বেতন বা ভাতা'));
    expect(_reject('rights', 'payslip'), contains('নির্দিষ্ট হারে বেতন বা ভাতা'));
    expect(_reject('rights', 'wave'), allOf(contains('শুধু দুর্ঘটনা নয়'), contains('দীর্ঘস্থায়ী রোগ')));
    expect(_slot('rights').whyChips.firstWhere((w) => w.id == 'w1').textBn, contains('অধিকার, দয়া নয়'));
    expect(text, contains('ক্ষতিপূরণ আপনার অধিকার, দয়া নয়'));
    // Point 4, steps 1–2: tell at once; the government or company doctor.
    expect(_safeIds('steps'), {'call', 'govdoc', 'codoc'});
    expect(_trapIds('steps'), {'hide', 'late', 'shop'});
    expect(text, contains(_reject('steps', 'hide')), reason: 'step 1 word for word');
    expect(_reject('steps', 'late'), contains('অবিলম্বে'));
    expect(_reject('steps', 'shop'), allOf(contains('সরকারি বা কোম্পানির ডাক্তার'), contains('অত্যন্ত গুরুত্বপূর্ণ আইনি নথি')));
    // Point 4, steps 3–4, pro tips 2–4: the written notice, every paper, the
    // Labour Commissioner; the nominee and the union in the reason chips.
    expect(_safeIds('claim'), {'notice', 'file', 'labour'});
    expect(_trapIds('claim'), {'guard', 'bin', 'sign'});
    expect(_reject('claim', 'guard'), allOf(contains('নির্দিষ্ট সময়ের মধ্যে'), contains('লিখিতভাবে'), contains('দিতে হতে পারে')));
    expect(_reject('claim', 'bin'), allOf(contains('চিকিৎসার বিল'), contains('যত্ন করে')));
    expect(_reject('claim', 'sign'), allOf(contains('আইন দ্বারা নির্ধারিত'), contains('লেবার কমিশনারের কাছে আবেদন')));
    expect(text, contains('লেবার কমিশনারের কাছে আবেদন করতে পারেন'));
    expect(_slot('claim').whyChips.any((w) => !w.correct && w.textBn.contains('নমিনি')), isTrue, reason: 'pro tip 2');
    // Pro tip 4 (the union) lives in a wrong chip that contradicts it; the
    // right chips each say why the picked paper is right.
    expect(_slot('claim').whyChips.any((w) => !w.correct && w.textBn.contains('ইউনিয়ন')), isTrue, reason: 'pro tip 4');
    expect(_reject('rights', 'payslip'), startsWith('অস্থায়ী অক্ষমতায়'), reason: 'point 3 keeps its qualifier');
    expect(pack.earnedBn, allOf(contains('সাথে সাথে'), contains('সরকারি বা কোম্পানির ডাক্তার'), contains('অধিকার, দয়া নয়')));
  });

  test('ruling M7-6: no deadly on this lesson — every trap teaches, none is a deadly-class act', () {
    // Nothing on the board puts anyone near a live wire or a fall: no tester,
    // no isolation, no glove or harness words in any card or reason.
    for (final l in _allText()) {
      for (final no in ['টেস্টার', 'আর্থ', 'হারনেস', 'গ্লাভস', 'লাইভ', 'শাটডাউন']) {
        expect(l, isNot(contains(no)), reason: '"$l": a paperwork board ($no belongs to the field levels)');
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
      'who': ['লাইনম্যান', 'ক্রস-আর্ম', 'হেল্পার'],
      'partial': ['স্টোর', 'টেবিল', 'অফিস'],
      'rights': ['বিল', 'বেড', 'রাসায়নিক', 'অফিসার'],
      'steps': ['ফোন', 'সরকারি', 'কোম্পানির ডাক্তার'],
      'claim': ['বাক্স', 'ফাইল', 'কমিশনার'],
    };
    for (final e in onlyOne.entries) {
      for (final t in right(e.key)) {
        for (final one in e.value) {
          expect(t, isNot(contains(one)), reason: '"$t": names one safe card only ($one)');
        }
      }
    }
  });

  test('every picture exists (vector scenes from tool/m7_board72_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m7_board72 folder is a card on the board', () {
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
  // lineman, the officer, a paper, a bandage, a phone, a doctor... In every
  // hand, nothing sits only on the safe card, and nothing sits on every trap
  // but not the safe card (the odd one out would be the answer).
  test('in every possible hand, no prop or figure marks the safe card', () {
    final tagRe = RegExp(r'<!--prop:(\w+)-->');
    final props = <String, Set<String>>{};
    Set<String> of(String asset) => props.putIfAbsent(
        asset, () => tagRe.allMatches(File(asset).readAsStringSync()).map((m) => m.group(1)!).toSet());

    for (final s in pack.slots) {
      final traps = s.options.where((o) => !o.correct).toList();
      for (final o in s.options) {
        expect(of(o.asset).intersection({'lineman', 'contract', 'helper'}), isNotEmpty, reason: '${o.asset}: a worker on every card');
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

  // What each card's label says is drawn: the worker type, the refusal, the
  // red cross and the bolt, the 0 on the pay slip, the guard told by mouth.
  test('the pictures show what the labels say', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync();
    Set<String> props(String card) => RegExp(r'<!--prop:(\w+)-->').allMatches(svg(card)).map((m) => m.group(1)!).toSet();
    const palm = 'width="7" height="9" rx="2.5"'; // the officer's raised palm
    // Who: the contract worker wears the vest, the helper the cap and the
    // cross-arm; the refusals raise a palm, the notice crosses out the bolt.
    expect(props('who_contract'), contains('contract'));
    expect(props('who_clerk'), contains('contract'));
    expect(props('who_temp'), containsAll(['helper', 'crossarm']));
    expect(props('who_tempno'), containsAll(['helper', 'crossarm']));
    expect(props('who_perm'), contains('lineman'));
    for (final c in ['who_clerk', 'who_tempno']) {
      expect(svg(c), contains(palm), reason: '$c: turned away');
    }
    for (final c in ['who_perm', 'who_contract', 'who_temp']) {
      expect(svg(c), isNot(contains(palm)), reason: '$c: the claim is taken');
    }
    expect(props('who_notice'), contains('notice'));
    // Partial: the eye patch and the store counter; the bed with no work.
    expect(svg('partial_eye'), contains('rx="3.2" ry="2.8"'), reason: 'partial_eye: the eye patch');
    expect(props('partial_plaster'), contains('calendar'));
    expect(props('partial_burn'), contains('calendar'));
    // Rights: the wife pays herself; the pay slip reads 0; the cough and drum.
    expect(props('rights_wife'), containsAll(['wife', 'money']));
    expect(props('rights_pay'), containsAll(['officer', 'money']));
    expect(props('rights_pay'), isNot(contains('wife')));
    expect(svg('rights_payslip'), contains('stroke="#C8352B"'), reason: 'rights_payslip: the red 0');
    for (final c in ['rights_disease', 'rights_wave']) {
      expect(props(c), containsAll(['drum', 'cough']), reason: c);
    }
    expect(svg('rights_wave'), contains(palm), reason: 'rights_wave: waved away');
    // Steps: the phone at once vs after many calendar pages; the red cross
    // (government hospital), the bolt (company), the chemist's bottles.
    expect(props('steps_call'), contains('phone'));
    expect(props('steps_late'), containsAll(['phone', 'calendar']));
    expect(props('steps_hide'), contains('supervisor'));
    expect(svg('steps_govdoc'), contains('v12 M'), reason: 'steps_govdoc: the red cross');
    expect(svg('steps_codoc'), isNot(contains('v12 M')));
    for (final c in ['steps_govdoc', 'steps_codoc', 'steps_shop']) {
      expect(props(c), containsAll(['medic', 'paper']), reason: c);
    }
    // Claim: the guard is told by mouth (no paper); the notice goes in the box.
    expect(props('claim_guard'), containsAll(['guard', 'letterbox']));
    expect(props('claim_guard'), isNot(contains('paper')), reason: 'claim_guard: nothing in writing');
    expect(props('claim_notice'), containsAll(['letterbox', 'paper']));
    expect(props('claim_bin'), containsAll(['dustbin', 'folder']));
    expect(props('claim_labour'), containsAll(['officer', 'folder']));
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _norm(_myths[0]['myth'] as String), reason: 'the lesson\'s own myth 1 (ruling M7-10)');
    expect(m.rivalLineBn, 'দুর্ঘটনাটি আমার নিজের ভুলেই হয়েছে, তাই আমি কোনো ক্ষতিপূরণ পাব না।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'No-Fault: work-caused accidents are covered whoever was at fault');
    final reality = _norm(_myths[0]['reality'] as String);
    expect(reality, allOf(contains('No-Fault Liability'), contains('কাজের সময় এবং কাজের কারণে'), contains('যার দোষেই হোক')));
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('No-Fault')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('কাজের কারণে')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line and the sting are already recorded; the new ones wait
    // for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M7Board72Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M7Board72Lines.newRivalLines, M7Board72Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M7Board72Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M7Board72Lines.guideSpoken;
    expect(M7Board72Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 5 prompts + 15 trap reasons + 5×3 right reasons + sting + flipped sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 5 + 15 + 15 + 2 + 3 + 1));
    expect(spoken, contains(pack.introBn));
    expect(spoken, contains(pack.earnedBn));
    expect(spoken, contains(pack.myth.stingBn));
    // The runner flips the believe question on half of all plays: this board
    // sets its own flipped line (boards 5.6–5.8's, already recorded), never
    // the kit's default "shortcut / save your life" line.
    expect(spoken, contains(pack.myth.flipStingBn));
    expect(pack.myth.flipStingBn, M7Board72Lines.flipSting);
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
      expect(save.rungProgress[_rung], isNot('cleared'), reason: '7 of 12 clean = 58% < 60%');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a trap (the injury hidden) teaches with the lesson\'s words; no reason deck, no freeze (M7-6)', (t) async {
      final c = await _open(t);
      for (final s in pack.slots.takeWhile((s) => s.id != 'steps')) {
        await _cleanRound(t, s);
      }
      // No deadly in 7.2 and boards have no freeze: the trap costs the
      // round's ◆ and its reason is step 1 word for word. The steps round has
      // three traps and a hand of four, so every hand holds it.
      final steps = _slot('steps');
      await _settleHand(t, 'pick', {'hide'}, 'steps: the hidden-injury trap');
      await tapBoardCard(t, _dealt('pick', {'hide'}));
      await _pumpUntil(t, () => find.text(_reject('steps', 'hide')).evaluate().isNotEmpty, what: 'step 1');
      for (final w in steps.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the "কেন" deck');
      }
      expect(find.byType(LevelFailPanel), findsNothing, reason: 'one miss does not end the board');
      // The board goes on: past the feedback, a fresh hand with a safe card.
      await continueBoard(t);
      await _cleanRound(t, steps);
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '7.2', ladderIndex: _ladder, pack: pack, muted: true),
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
