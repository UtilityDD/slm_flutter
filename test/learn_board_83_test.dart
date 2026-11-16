// Module 8 lesson 8.3 picture board ("স্ট্যান্ডার্ডস অফ পারফর্ম্যান্স (SoP): সময়ের মূল্য",
// rung 8.3/learn, pack learn_8_3): its content follows the board's rules, the
// live lesson (X3: fuse-off 3 h town / 6 h village (8 h June–September), DTR
// 12 h town / 48 h village, LT wire 4 h town, 11 kV pole 12 h town, shutdown
// over 6 h = 3 days' notice, the second myth word for word) and the Module 8
// rulings (M8-12, M8-19, M8-21: five rounds), every picture exists and no
// colour or backdrop marks the safe card (in any hand the dealer can make),
// every new line is listed for recording, a clean play (picks, reasons, the
// rival's myth) clears the rung, a miss on every round fails it, a slip-only
// trap teaches with the lesson's own words and costs no strike, the gesture
// hint sweeps without pressing, and the board waits quietly once dealt.
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
import 'package:slm_flutter/features/game/learn_board_pack83.dart';
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

const pack = learnBoardPack83;
const _artDir = 'assets/game/art/m8_board83';
const _rung = '8.3/learn';

/// Has read lesson 8.3 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['8_3', '8.3']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.3', ladderIndex: 0, pack: pack, muted: true),
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

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

LearnBoardOption _opt(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option);

String _reject(String slot, String option) => _opt(slot, option).rejectBn;

Set<String> _safeIds(String slot) => {for (final o in _slot(slot).options) if (o.correct) o.id};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
    SpokenOnce.resetForTest();
  });

  test('the lesson 8.3 board with the trimmed five rounds (M8-21)', () {
    expect(pack.lessonId, '8.3');
    // Registered in learn_board_models.dart (learnBoardPackFor).
    expect(learnBoardPackFor('8.3'), same(learnBoardPack83));
    expect(pack.badgeBn, 'জরুরী রেগুলেশন (WBERC ফোকাস)', reason: 'the lesson\'s own badge_name (M8-16)');
    expect(pack.titleBn, 'স্ট্যান্ডার্ডস অফ পারফর্ম্যান্স (SoP): সময়ের মূল্য');
    // The burnt-meter and voltage round (spec rounds[3]) left the board (M8-21).
    expect(pack.slots.map((s) => s.id), ['clock', 'fuse', 'dtr', 'plan', 'delay']);
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
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

  test('the lesson\'s numbers: fuse-off, DTR, LT wire, 11 kV pole, shutdown notice, the penalty', () {
    // Clock: from the complaint, never from the van, the arrival or the work.
    expect(_safeIds('clock'), {'call', 'sms'});
    expect(_reject('clock', 'van'), contains('কল সেন্টারে কমপ্লেইন নথিভুক্ত'));
    expect(_reject('clock', 'site'), contains('কাউন্টডাউন শুরু'));
    expect(_reject('clock', 'work'), contains('SoP-এর সময়'));
    // Fuse-off (live): town 3 h; village 6 h, 8 h June–September.
    expect(_safeIds('fuse'), {'urban_in_time', 'rural_in_time'});
    expect(_opt('fuse', 'urban_in_time').labelBn, contains('14:00 · আলো ফিরল 16:30'), reason: '2.5 h in town');
    expect(_opt('fuse', 'rural_in_time').labelBn, allOf(contains('জুলাই'), contains('16:00')), reason: '7 h in July (8 h limit)');
    expect(_opt('fuse', 'urban_late').labelBn, contains('19:00'), reason: '5 h in town: late');
    expect(_reject('fuse', 'urban_late'), contains('3 ঘন্টার'));
    expect(_reject('fuse', 'rural_late'), allOf(contains('বর্ষার বাইরে'), contains('6 ঘন্টার'), contains('7 ঘন্টা')));
    expect(_opt('fuse', 'rural_late').labelBn, contains('জানুয়ারি'), reason: 'January: the 6 h limit applies');
    // The docket check: a finished job with the docket open is a slip.
    expect(_reject('fuse', 'docket_open'), contains('ডকেট ক্লোজ করলেন না'));
    expect(_opt('fuse', 'docket_open').labelBn, endsWith('ডকেট খোলা'));
    expect(_opt('fuse', 'urban_in_time').labelBn, endsWith('ডকেট ক্লোজ'));
    // DTR (live): town 12 h, village 48 h; 11 kV pole town 12 h, village 24 h.
    expect(_safeIds('dtr'), {'call_now', 'urban_in_time'});
    expect(_opt('dtr', 'urban_in_time').labelBn, allOf(contains('20:00'), contains('06:00')), reason: '10 h in town');
    expect(_reject('dtr', 'rural_late'), contains('48 ঘন্টা'));
    expect(_opt('dtr', 'rural_late').labelBn, contains('বুধ 12:00'), reason: 'Mon 08:00 to Wed 12:00 = 52 h');
    expect(_reject('dtr', 'urban_late'), contains('12 ঘন্টার'));
    expect(_opt('dtr', 'breakdown_late').labelBn, allOf(contains('11 kV'), contains('শহরের')),
        reason: 'the fault and the place are named (live split)');
    expect(_reject('dtr', 'breakdown_late'), allOf(contains('11 kV'), contains('12 ঘন্টার'), contains('16 ঘন্টা')));
    expect(_reject('dtr', 'call_later'), contains('দেরি না করে'));
    // Shutdown (live): only a shutdown over 6 h needs 3 days' notice.
    expect(_safeIds('plan'), {'short_a', 'short_b'});
    expect(_opt('plan', 'short_a').labelBn, contains('10:00–13:00'), reason: 'a 3 h job, inside 06:00–17:00');
    expect(_opt('plan', 'short_b').labelBn, contains('11:00–15:00'), reason: 'a 4 h job, inside 06:00–17:00');
    expect(_reject('plan', 'evening_block'), allOf(contains('সন্ধ্যা 5টা'), contains('সকাল 6টার')));
    expect(_opt('plan', 'one_day').labelBn, contains('08:00–16:00'), reason: 'an 8 h job');
    expect(_reject('plan', 'one_day'), allOf(contains('6 ঘন্টার বেশি'), contains('3 দিন আগে')));
    expect(_reject('plan', 'no_miking'), contains('মাইকিং'));
    // Delay: photos and register for force majeure; tell the consumer; LT jumpering.
    expect(_safeIds('delay'), {'storm_photos', 'lt_jumper', 'sms_consumer'});
    expect(_reject('delay', 'storm_no_photos'), allOf(contains('পেনাল্টি লাগে না'), contains('ছবি')));
    expect(_reject('delay', 'silent_delay'), contains('SMS'));
    expect(_reject('delay', 'penalty_whim'), contains('কমিশনে'));
    expect(_opt('delay', 'lt_jumper').labelBn, contains('LT জাম্পারিং'), reason: 'LT in English letters');
    expect(pack.earnedBn, allOf(contains('ডকেট ক্লোজ'), contains('সময়সীমা')));
  });

  test('the Module 8 rulings: numbers, term rules, no DO, no obsolete figures', () {
    // The voltage round left the board (M8-21): no meter, no 15-day loose contact.
    for (final l in _allText()) {
      // Term rules (X6): «ডেড» not «মৃত»/«মরা»; LT, HT, 11 kV in English letters.
      for (final bad in ['মৃত', 'মরা', 'এলটি', 'এইচটি', 'কেভি', 'কেভিএ', 'অন ', 'অফ-লাইন']) {
        expect(l, isNot(contains(bad)), reason: '"$l": term rule (no "$bad")');
      }
      // Closing an AB is «AB লাগানো», never «AB বন্ধ» (M8-19).
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": "AB বন্ধ" is not the term');
      // Module 8 has no DO and no old figures from the spec's quotes.
      for (final no in ['ড্রপ আউট', 'ডিও', 'DO ফিউজ', '₹', 'লাখ', 'মফস্বল', 'বর্ষায় ৮']) {
        expect(l, isNot(contains(no)), reason: '"$l": no "$no" on this board');
      }
      expect(l, isNot(contains('24 ঘন্টার মধ্যে')), reason: '"$l": the spec\'s old 24 h fuse limit left the lesson');
      expect(l, isNot(contains('15 দিন')), reason: '"$l": the meter round was dropped (M8-21)');
    }
    expect(pack.slots.expand((s) => s.options).any((o) => o.labelBn.contains('ডকেট ক্লোজ')), isTrue);
    expect(_allText().any((l) => l.contains('ডকেট')), isTrue, reason: 'the locked word ডকেট');
    // The lesson's own myth, with English digits.
    expect(pack.myth.rivalLineBn, contains('24 ঘন্টা'));
  });

  test('every picture exists (vector scenes from tool/m8_board83_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
  });

  test('every file in the m8_board83 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => '$_artDir/${f.uri.pathSegments.last}')
        .toSet();
    expect(onDisk, used, reason: 'no unused art, no stray files (the APK ships the folder), no missing art');
  });

  test('every card is free of words; no colour or backdrop gives the safe card away', () {
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

  test('every round\'s cards share one body: the same block and backdrop fills; only the labels differ', () {
    // The scene only (the fixed key strip at x=6, y=204 is left out).
    String body(String asset) => File(asset).readAsStringSync().split('</defs>').last.split('<rect x="6" y="204"').first;
    Set<String> fills(String asset) => {for (final m in RegExp(r'fill="([^"]+)"').allMatches(body(asset))) m.group(1)!};
    for (final s in pack.slots.where((s) => const {'fuse', 'dtr', 'plan'}.contains(s.id))) {
      // The docket left open is the one picture that differs on purpose (its label says so).
      final cards = [for (final o in s.options) if (!(s.id == 'fuse' && o.id == 'docket_open')) o];
      final first = fills(cards.first.asset);
      for (final o in cards) {
        expect(fills(o.asset), first, reason: '${s.id}/${o.id}: the same block and backdrop fills as the rest of the round');
      }
    }
  });

  test('the careless lineman says the lesson\'s second myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'গ্রামে কারেন্ট না থাকলে কেউ দেখার নেই, 24 ঘন্টা কোনো ব্যাপার না।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the myth is false: the SoP clock runs in villages too');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('ঘড়ি')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M8Board83Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M8Board83Lines.newRivalLines, unorderedEquals([m.tauntBn, m.rivalLineBn]), reason: 'M8-14: every new rival line is listed');
    for (final l in M8Board83Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, every trap's reason, every
    // right reason chip, the myth's right chips, the closing line.
    final g = M8Board83Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    for (final s in pack.slots) {
      expect(g, contains(s.promptBn));
    }
    final expected = 1 +
        pack.slots.length +
        pack.slots.fold<int>(0, (n, s) => n + s.options.where((o) => !o.correct).length) +
        pack.slots.fold<int>(0, (n, s) => n + s.whyChips.where((w) => w.correct).length) +
        m.whyChips.where((w) => w.correct).length +
        1;
    expect(g.length, expected);
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
      expect(save.rungProgress[_rung], isNot('cleared'), reason: 'five misses of the picks are below the pass mark');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip-only trap (the storm with no photos) teaches with the lesson\'s words; no reason deck, no fail', (t) async {
      final c = await _open(t);
      // Every round before the last one (delay), played clean.
      for (final s in pack.slots.takeWhile((s) => s.id != 'delay')) {
        await _cleanRound(t, s);
      }
      final delay = _slot('delay');
      await _settleHand(t, 'pick', {'storm_no_photos'}, 'delay: the no-photos trap (all traps are in the hand)');
      await tapBoardCard(t, _dealt('pick', {'storm_no_photos'}));
      await _pumpUntil(t, () => find.text(_reject('delay', 'storm_no_photos')).evaluate().isNotEmpty,
          what: 'the lesson\'s storm rule');
      for (final w in delay.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.3', ladderIndex: 0, pack: pack, muted: true),
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
