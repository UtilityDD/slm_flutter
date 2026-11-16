// Module 8 lesson 8.1 picture board ("WBERC পরিচিতি: রাজ্যের পাওয়ার বস",
// rung 8.1/learn, pack learn_8_1): its content follows the board's rules, the
// live lesson 8.1 (version 5) and the Module 8 rulings (M8-1 slip-only, M8-8
// reason cards, M8-14 spoken lines listed, M8-21 five rounds, X3 live
// wording, X6 term rules), every picture exists and no colour or backdrop
// marks the safe card (in any hand the dealer can make), the rival's myth is
// the lesson's own and every new line is listed for recording, a clean play
// (picks, reasons, the rival's myth) clears the rung, a miss on every round
// fails it (the board's strike-out), a wrong card teaches with the lesson's
// own words and opens no reason deck (a board has no freeze: kit design, and
// 8.1 has no deadly class), the gesture hint sweeps without pressing, and the
// board waits quietly once dealt.
//
// The lookup learnBoardPackFor('8.1') is wired by the director in
// learn_board_models.dart; this test hands the pack to the runner directly.
import 'dart:async';
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
import 'package:slm_flutter/features/game/learn_board_pack81.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack81;
const _artDir = 'assets/game/art/m8_board81';
const _rung = '8.1/learn';

/// Has read lesson 8.1 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['8_1', '8.1']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.1', ladderIndex: 170, pack: pack, muted: true),
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

/// The rival scene (the board's coworker moment): he says the lesson's myth,
/// then the guide asks; the right answer (না to "বিশ্বাস করেন?", হ্যাঁ to "সেটা
/// কি ভুল?") and a right reason.
Future<void> _beatTheRival(WidgetTester t) async {
  final myth = pack.myth;
  await _pumpUntil(t, () => find.text(myth.rivalLineBn).evaluate().isNotEmpty, what: 'the rival\'s myth');
  await _pumpUntil(
    t,
    () => find.text('বিশ্বাস করেন?').evaluate().isNotEmpty || find.text('সেটা কি ভুল?').evaluate().isNotEmpty,
    what: 'the believe question',
  );
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
    SpokenOnce.resetForTest();
  });

  test('the lesson 8.1 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '8.1');
    expect(pack.badgeBn, 'জরুরী রেগুলেশন (WBERC ফোকাস)', reason: 'the lesson\'s own badge');
    expect(pack.titleBn, 'WBERC পরিচিতি: রাজ্যের পাওয়ার বস');
    // Five rounds (ruling M8-21): the new-rate round (rounds[3] of the spec)
    // left the board; do_8_1_b plays it.
    expect(pack.slots.map((s) => s.id), ['ref', 'bal', 'bill', 'sop', 'lic']);
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
      expect(s.promptBn, isNot('সঠিক জিনিস বেছে নিন'), reason: '${s.id}: specific prompt');
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
  });

  test('every round: 4–6 pictures, safe ones and enough traps, each trap says why', () {
    for (final s in pack.slots) {
      expect(s.options.length, inInclusiveRange(4, 6), reason: s.id);
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

  test('every on-screen string uses English digits and the house words', () {
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp('[০-৯]'))), reason: '"$l": English digits on screen');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        expect(l, isNot(matches(RegExp('(?<![ঀ-৿])$bad'))), reason: '"$l": house word for "$bad"');
      }
    }
  });

  test('the Module 8 term rules: ডেড not মৃত, LT/kV in English, AB লাগানো, ON/OFF', () {
    for (final l in _allText()) {
      // Whole words only: "আমরা" is not "মরা".
      for (final bad in ['মৃত', 'মরা', 'এলটি', 'কেভি', 'অন', 'অফ']) {
        expect(l, isNot(matches(RegExp('(?<![ঀ-৿])$bad(?![ঀ-৿])'))), reason: '"$l": the owner\'s term rule (no "$bad")');
      }
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": closing an AB is «AB লাগানো»');
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
    }
  });

  test('the lesson\'s points: referee, balance, bill, time limits, licence', () {
    // Referee: WBERC stands alone or in the middle; the plate, the company
    // colours, the boardroom and the two counters are the traps.
    expect(_safeIds('ref'), {'sep', 'mid'});
    expect(_reject('ref', 'plate'), contains('স্বাধীন সংস্থা'));
    expect(_reject('ref', 'tilt'), contains('দুই দিক দেখে'));
    expect(_reject('ref', 'board'), contains('মাথার ওপর রেফারি WBERC'));
    expect(_reject('ref', 'counter'), contains('2003-এর আইনে'));
    // Balance: both interests, not the company's money and not the homes alone.
    expect(_safeIds('bal'), {'scale', 'files'});
    expect(_reject('bal', 'tipco'), contains('গ্রাহক ঠকিয়ে'));
    expect(_reject('bal', 'tiphome'), contains('ক্ষতিগ্রস্ত'));
    expect(_reject('bal', 'one'), contains('দুটোই মাপে WBERC'));
    // The bill: talk with facts, the tariff is the commission's order.
    expect(_safeIds('bill'), {'door', 'chart'});
    expect(_reject('bill', 'shout'), contains('তর্ক নয়, তথ্য দিন'));
    expect(_reject('bill', 'shrug'), contains('কমিশনের অর্ডার'));
    expect(_reject('bill', 'strike'), contains('ফিক্সড চার্জ'));
    // Time limits: a late fuse costs the company, the limit is WBERC's.
    expect(_safeIds('sop'), {'leave', 'file'});
    expect(_reject('sop', 'tea'), contains('জরিমানার কেস'));
    expect(_reject('sop', 'dark'), contains('জরিমানা বা ক্ষতিপূরণ'));
    expect(_reject('sop', 'cob'), contains('সময়সীমাও WBERC বেঁধে দেয়'));
    // Licences: WBERC grants and can revoke; APTEL is the appeal court.
    expect(_safeIds('lic'), {'wall', 'three'});
    expect(_reject('lic', 'self'), contains('সেই লাইসেন্স দেয় WBERC'));
    expect(_reject('lic', 'torn'), contains('লাইসেন্স বাতিলও'));
    expect(_reject('lic', 'apt'), contains('APTEL'));
    expect(pack.earnedBn, contains('WBERC'));
  });

  test('the myth: the lesson\'s second myth, and the live reality (ruling X3)', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'WBERC শুধুমাত্র বড় অফিসারদের ব্যাপার, লাইনম্যানদের এতে কোনো ভূমিকা নেই।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the lineman has a part: "না" is right');
    // The live reality: the supply code and CEA's regulation, every day.
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('সাপ্লাই কোড')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('CEA')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M8Board81Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M8Board81Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 16 trap reasons, 15 right
    // chips, 3 myth chips, the closing line — pinned so none is forgotten.
    final g = M8Board81Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    for (final s in pack.slots) {
      expect(g, contains(s.promptBn));
    }
    expect(g.length, 1 + 5 + 16 + 15 + 3 + 1);
  });

  test('every picture exists (vector scenes from tool/m8_board81_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m8_board81 folder is a card on the board', () {
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

  test('the referee and the figures stand on the ground; the WBERC building stands alone', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    // The safe referee picture: a building with a WBERC colour and no company
    // building linked to it; the mid picture has the referee's whistle.
    expect(svg('ref_sep'), contains('#1F5F8F'), reason: 'ref_sep: the WBERC building');
    expect(svg('ref_mid'), contains('#E5B92E'), reason: 'ref_mid: the referee\'s armband');
    // The bill's back shows the tariff grid, the trainee's bill (safe only).
    expect(svg('bill_door'), contains('#F4F1E6'), reason: 'bill_door: the bill in hand');
    // The licence: the WBERC seal on the wall (safe) has a gold seal.
    expect(svg('lic_wall'), contains('#E5B92E'), reason: 'lic_wall: the seal');
  });

  test('the careless lineman says the lesson\'s second myth, word for word; the guide asks; every new line is listed', () {
    expect(pack.myth.rivalLineBn, M8Board81Lines.rivalMyth);
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

    testWidgets('a wrong card (the bill\'s "shouting") teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      // Every round before the last one (lic), played clean.
      for (final s in pack.slots.takeWhile((s) => s.id != 'lic')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design) and 8.1 has no deadly class: the
      // trap costs the round's ◆ only. Its reason is the lesson's own words.
      final lic = _slot('lic');
      await _settleHand(t, 'pick', {'self'}, 'lic: the company-signed licence (all three traps are in every hand)');
      await tapBoardCard(t, _dealt('pick', {'self'}));
      await _pumpUntil(t, () => find.text(_reject('lic', 'self')).evaluate().isNotEmpty, what: 'the lesson\'s reason');
      for (final w in lic.whyChips) {
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
        expect(hint().debugOptions.length, greaterThanOrEqualTo(2), reason: 'a sweep over the cards, never one');
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.1', ladderIndex: 170, pack: pack, muted: true),
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
