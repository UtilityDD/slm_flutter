// Module 6 lesson 6.3 picture board ("ফিউজ: নীরব প্রহরী ও তারের সঠিক হিসাব",
// rung 6.3/learn, pack learn_6_3): its content follows the board's rules, the
// live lesson and the Module 6 rulings (M6-2 HG renewal, X4 dead LT board, X6
// IS 9926 table), every picture exists and no colour or backdrop marks the
// safe card (in any hand the dealer can make), the rival's myth is the
// lesson's own and every new line is listed for recording, a clean play
// (picks, reasons, the rival's myth) clears the rung, a miss on every round
// fails it (the board's strike-out), a deadly-class trap teaches with the
// lesson's own words (boards have no freeze: kit design), the gesture hint
// sweeps without pressing, and the board waits quietly once dealt.
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

const pack = learnBoardPack63;
const _artDir = 'assets/game/art/m6_board63';
const _rung = '6.3/learn';

/// Live lesson 6.3 point 6 on HG wire renewal, word for word (ruling M6-2).
const _hgRule = 'হর্ন গ্যাপ ফিউজের তার বদলানোর আগে AB সুইচ খুলে তিনটি ব্লেডই খুলেছে কি না দেখুন, টেস্টারে ডেড প্রমাণ করুন এবং আর্থিং দিন।';

/// Has read lesson 6.3 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_3', '6.3']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.3', ladderIndex: 162, pack: pack, muted: true),
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

  test('the lesson 6.3 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '6.3');
    // Registered in learn_board_models.dart (learnBoardPackFor).
    expect(learnBoardPackFor('6.3'), same(learnBoardPack63));
    expect(pack.badgeBn, 'যন্ত্র গুরু', reason: 'the lesson\'s own badge');
    expect(pack.titleBn, 'ফিউজ: নীরব প্রহরী ও তারের সঠিক হিসাব');
    // Five rounds, as the Module 5 boards (ruling M5-11): the spare-wire
    // round left the board (owner 2026-11-15).
    expect(pack.slots.map((s) => s.id), ['hg', 'rating', 'hrc', 'gauge', 'blow']);
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

  test('the lesson\'s points: HG horns and rating, HRC dot and drawing, the gauge, discrimination', () {
    // HG: tinned copper taut between the horns; the arc dies in the air.
    expect(_safeIds('hg'), {'taut', 'arc'});
    expect(_reject('hg', 'gi'), contains('1535°'));
    expect(_reject('hg', 'slack'), contains('টানটান'));
    expect(_reject('hg', 'alu'), allOf(contains('অনেক মোটা'), contains('অক্সিডেশনে')));
    // HG rating by kVA: 25 → 2-3 A, 63 → 5 A, 100 → 8-10 A.
    expect(_safeIds('rating'), {'r25', 'r63', 'r100'});
    expect(_reject('rating', 't25'), contains('2 A বা 3 A'));
    expect(_reject('rating', 't63'), contains('63 kVA-তে 5 A'));
    expect(_reject('rating', 'tthick'), contains('8 A বা 10 A'));
    // HRC: the dot; the draw on a dead, locked board with PPE and the puller.
    expect(_safeIds('hrc'), {'dot', 'iso'});
    expect(_reject('hrc', 'strip'), allOf(contains('তামার পাত'), contains('আগুন')));
    expect(_reject('hrc', 'pliers'), contains('ইনসুলেটেড ফিউজ পুলার'));
    expect(_reject('hrc', 'live'), contains('আর্ক ফ্ল্যাশ'));
    expect(_reject('hrc', 'bare'), allOf(contains('গ্লাভস'), contains('গগলস')));
    expect(_slot('hrc').whyChips.any((w) => w.correct && w.textBn.contains('লাল ডট')), isTrue);
    // Gauge: 100 A = 2.00 mm (about 14 SWG); higher number = thinner; bare wire.
    expect(_safeIds('gauge'), {'slot', 'micro'});
    expect(_opt('gauge', 'slot').labelBn, contains('14'));
    expect(_opt('gauge', 'micro').labelBn, contains('2.00 মিমি'));
    expect(_reject('gauge', 'thin'), allOf(contains('যত বাড়ে'), contains('0.50 মিমি')));
    expect(_reject('gauge', 'insul'), contains('খালি কন্ডাক্টর'));
    expect(_reject('gauge', 'eye'), contains('আন্দাজে'));
    expect(_reject('gauge', 'm150'), allOf(contains('63 A'), contains('2.00 মিমি')));
    expect(_slot('gauge').whyChips.any((w) => w.correct && w.textBn.contains('HRC')), isTrue, reason: 'above 100 A: HRC');
    // Discrimination: the house fuse first; no re-charge before the cause.
    expect(_safeIds('blow'), {'house', 'find', 'iso'});
    expect(_reject('blow', 'recharge'), contains('আসল কারণ না খুঁজে'));
    expect(_reject('blow', 'tick'), contains('কো-অর্ডিনেশন'));
    expect(pack.earnedBn, allOf(contains('টিনড কপার'), contains('ডেড প্রমাণ')));
  });

  test('the Module 6 rulings: HG renewal (M6-2), a dead LT board (X4), the IS 9926 table (X6), no DO', () {
    // M6-2: the rod-in-a-puddle trap is gone; HG wire renewed with the AB
    // closed is the trap, its reason the live lesson word for word.
    expect(_reject('blow', 'live'), _hgRule);
    // X3 order: LT OFF first, then the AB opened (all three blades seen).
    expect(_opt('blow', 'iso').labelBn,
        allOf(startsWith('LT বন্ধ'), contains('AB খুলে'), contains('ডেড প্রমাণ'), contains('আর্থ')));
    // 'বন্ধ' means OFF — for an AB that is OPEN. The closed AB is 'না খুলে'.
    expect(_opt('blow', 'live').labelBn, contains('AB সুইচ না খুলেই'));
    expect(_slot('blow').whyChips.firstWhere((w) => w.id == 'w6').textBn, contains('AB না খুলেও'));
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": "AB বন্ধ" reads as the AB OFF (open)');
    }
    // X4: the HRC draw only after the DTR LT switch OFF, lock-tag, the tester,
    // gloves and goggles (the only thing that tells it from the 'bare' trap).
    expect(_opt('hrc', 'iso').labelBn,
        allOf(contains('LT বন্ধ'), contains('তালা-ট্যাগ'), contains('টেস্টারে 0'), contains('গ্লাভস-গগলস'), contains('পুলার')));
    expect(_reject('hrc', 'live'), allOf(contains('তালা-ট্যাগ'), contains('টেস্টারে ডেড প্রমাণ')));
    // X6: no old SWG ratings, no two-strand recipe, no 200/300 A wire.
    for (final l in _allText()) {
      for (final old in ['29 SWG', '22 SWG', '20 SWG', '18 SWG', '12 SWG', '200 A', '300 A', '1.219']) {
        expect(l, isNot(contains(old)), reason: '"$l": the old table ($old) left the lesson');
      }
      // M6-2: Module 6 has no DO; the mat and rod belong to DO practice.
      for (final no in ['ড্রপ আউট', 'ডিও', 'DO ফিউজ', 'ম্যাট', 'অপারেটিং রড']) {
        expect(l, isNot(contains(no)), reason: '"$l": no DO, mat or rod on this board');
      }
    }
    // Only the IS 9926 sizes the lesson gives.
    final sizes = RegExp(r'(\d+\.\d+) মিমি');
    for (final l in _allText()) {
      for (final m in sizes.allMatches(l)) {
        expect(['0.50', '0.85', '1.50', '2.00'], contains(m.group(1)), reason: '"$l": an IS 9926 size');
      }
    }
  });

  test('every picture exists (vector scenes from tool/m6_board63_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m6_board63 folder is a card on the board', () {
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

  // Rulings M6-2 and X4 in the pictures: hands on an HG or an HRC only once
  // it is proven dead; the traps show it is not.
  test('the pictures show the isolation on the safe cards and its absence on the traps', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const greenOff = 'fill="#3E9B4F"/>'; // the LT switch's OFF window
    const redOn = 'width="10" height="7" rx="1" fill="#D8402F"'; // the MCCB's ON window
    const padlockBody = 'width="10" height="8" rx="1.5" fill="#E5B92E"'; // the padlock
    const openBlade = 'stroke-width="3.2"'; // AB blades
    // HRC: OFF + padlock + tester at 0 on the safe draw and the slip traps;
    // the live trap's switch is ON and unlocked.
    for (final c in ['hrc_iso', 'hrc_pliers', 'hrc_bare']) {
      expect(svg(c), contains(padlockBody), reason: '$c: the LT switch locked and tagged');
    }
    expect(svg('hrc_live'), contains(redOn), reason: 'hrc_live: the switch is ON');
    expect(svg('hrc_live'), isNot(contains(padlockBody)), reason: 'hrc_live: not locked');
    expect(svg('hrc_iso'), contains('#3E9B4F'), reason: 'hrc_iso: the OFF window');
    // HG renewal: AB open (blades standing up), earth on, lane dark; the trap
    // has the AB closed and the earth set lying coiled on the ground.
    final iso = svg('blow_iso'), live = svg('blow_live');
    final upBlade = RegExp(r'<path d="M(\d+) 23 L(\d+) 5" stroke="url\(#steel\)" ' + openBlade);
    expect(upBlade.allMatches(iso).length, 3, reason: 'blow_iso: all three AB blades open');
    expect(upBlade.allMatches(live).length, 0, reason: 'blow_live: the AB is closed');
    expect(iso, contains('fill="#2E3A46"'), reason: 'blow_iso: the lane is dark (DTR off)');
    expect(iso, contains(greenOff), reason: 'blow_iso: the LT switch OFF first (ruling X3)');
    expect(live, contains('a14 5 0 1 0'), reason: 'blow_live: the earth set lies coiled, unused');
    expect(live, contains('fill="#FFE08A"'), reason: 'blow_live: the lane\'s windows are lit — it is live');
  });

  test('the careless lineman says the lesson\'s first myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'কিট-ক্যাট ফিউজে যত মোটা তার বাঁধা যাবে, ফিউজ তত মজবুত হবে এবং বারবার ফিউজ ওড়ার ঝামেলা থাকবে না।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'a thick wire does not blow and the DTR burns');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('নিজে গলে')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board63Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M6Board63Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 17 trap reasons, 17 right
    // chips, 3 myth chips, the closing line — pinned so none is forgotten.
    final g = M6Board63Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    expect(g, contains(_hgRule));
    for (final s in pack.slots) {
      expect(g, contains(s.promptBn));
    }
    expect(g.length, 1 + 5 + 17 + 17 + 3 + 1);
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

    testWidgets('a deadly-class trap (HG wire renewed with the AB closed) teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      // Every round before the last one (blow), played clean.
      for (final s in pack.slots.takeWhile((s) => s.id != 'blow')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is live point 6 word for word.
      final blow = _slot('blow');
      await _settleHand(t, 'pick', {'live'}, 'blow: the AB-closed trap (all three traps are in every hand)');
      await tapBoardCard(t, _dealt('pick', {'live'}));
      await _pumpUntil(t, () => find.text(_hgRule).evaluate().isNotEmpty, what: 'the lesson\'s HG rule');
      for (final w in blow.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.3', ladderIndex: 162, pack: pack, muted: true),
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
