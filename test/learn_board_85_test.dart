// Module 8 lesson 8.5 picture board ("সেফটি কোড (Safety Code): সুরক্ষার স্থানীয় আইন",
// rung 8.5/learn, pack learn_8_5): its content follows the board's rules, the
// live lesson 8.5 (version 7) and the Module 8 rulings (M8-1 deadly only for
// climb and earth acts, M8-5 the padlock and chain splits, M8-12 the road height
// 6.5 m, M8-17 the tester before any earth, M8-21 five rounds, M8-14 the myth
// word for word), every picture exists and no colour or backdrop marks the safe
// card (in any hand the dealer can make), the rival's myth is the lesson's own
// and every new line is listed for recording, a clean play (picks, reasons, the
// rival's myth) clears the rung, a miss on every round is below the pass line,
// a trap teaches with its own line and no reason deck opens, the gesture hint
// sweeps without pressing, and the board waits quietly once dealt.
// Boards have no freeze (kit design, as Module 6): the deadly and slip classes
// are kept in M8Board85Lines.trapClass for the reviewer and checked here.
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
import 'package:slm_flutter/features/game/learn_board_pack85.dart';
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

const pack = learnBoardPack85;
const _artDir = 'assets/game/art/m8_board85';
const _rung = '8.5/learn';

/// Live lesson 8.5 myth 1, word for word (ruling M8-14).
const _myth1 = 'এত বছর ধরে কাজ করছি, আমার পারমিট বা আর্থিং লাগে না, আমি হাত দিয়েই ভোল্টেজ বুঝি।';

/// Has read lesson 8.5 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['8_5', '8.5']));
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

/// The option ids of every card with [prefix] on screen right now.
Set<String> _shownIds(String prefix) => {
      for (final e in _cards.evaluate())
        if (e.widget.key is ValueKey<String> && (e.widget.key as ValueKey<String>).value.startsWith('$prefix-'))
          (e.widget.key as ValueKey<String>).value.split('-').skip(2).join('-'),
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.5', ladderIndex: 0, pack: pack, muted: true),
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

  test('the lesson 8.5 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '8.5');
    expect(pack.badgeBn, 'জরুরী রেগুলেশন (WBERC ফোকাস)', reason: 'the lesson\'s own badge');
    expect(pack.titleBn, 'সেফটি কোড (Safety Code): সুরক্ষার স্থানীয় আইন');
    // Five rounds (ruling M8-21): the LT house-gap round left the board.
    expect(pack.slots.map((s) => s.id), ['ptw', 'loto', 'road', 'earth', 'ppe']);
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
  });

  test('every round: 4–6 pictures, two safe ones, enough traps, each trap says why', () {
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

  test('every trap has its deadly or slip class, as the Module 8 rulings set', () {
    final traps = {
      for (final s in pack.slots)
        for (final o in s.options)
          if (!o.correct) '${s.id}/${o.id}',
    };
    expect(M8Board85Lines.trapClass.keys.toSet(), traps, reason: 'every trap classed, nothing extra');
    expect(M8Board85Lines.trapClass.values.toSet(), {'deadly', 'slip'});
    // Deadly: climb or start without a written PTW, a signed PTW never read,
    // one-sided or chain-only earth, a bare hand on an unearthed line, a
    // climb on a mate's word (M8-1, M1 step 17, R3, R4, N1).
    for (final k in ['ptw/phone', 'ptw/none', 'earth/oneside', 'earth/ball', 'earth/bare', 'ppe/mate']) {
      expect(M8Board85Lines.trapClass[k], 'deadly', reason: k);
    }
    // Slips: the padlock key and board (M8-5), the rusty chain (M8-5), the
    // road height (M8-12) and PPE worn torn (A5 family).
    for (final k in ['loto/keyin', 'loto/handkey', 'loto/nolock', 'loto/boardonly', 'earth/jugaad', 'road/low', 'road/covered', 'road/walk', 'ppe/torn', 'ppe/sole']) {
      expect(M8Board85Lines.trapClass[k], 'slip', reason: k);
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

  test('the term rules: ডেড not মৃত, LT / kV / ON / OFF in English, AB লাগানো, no অন/অফ', () {
    for (final l in _allText()) {
      expect(l, isNot(contains('মৃত')), reason: '"$l": ডেড, not মৃত');
      expect(l, isNot(contains('মরা')), reason: '"$l": ডেড, not মরা');
      expect(l, isNot(matches(RegExp('এলটি|কেভি|(?<![ঀ-৿])(অন|অফ)(?![ঀ-৿])'))), reason: '"$l": English ON/OFF, kV, LT');
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": "AB বন্ধ" is never used');
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

  test('the lesson\'s points: PTW, LOTO, the 6.5 m road span, the earth order, the PPE', () {
    // PTW: the written slip that matches the book, read before signing.
    expect(_safeIds('ptw'), {'slip', 'read'});
    expect(_reject('ptw', 'phone'), allOf(contains('ফোনে মুখের কথায়'), contains('লাইন OFF')));
    expect(_reject('ptw', 'sign'), contains('সই করার আগে পড়ে নিন'));
    expect(_reject('ptw', 'none'), allOf(contains('পারমিট ছাড়া'), contains('জেল')));
    expect(_reject('ptw', 'mismatch'), contains('নম্বর এবং সময়'));
    // LOTO: padlock and board on the OFF handle; the key in his own pocket.
    expect(_safeIds('loto'), {'lock', 'pocket'});
    expect(_opt('loto', 'lock').labelBn, allOf(contains('ব্রেকার OFF'), contains('তালা'), contains('কাজ চলছে')));
    expect(_reject('loto', 'keyin'), allOf(contains('নিজের পকেটে'), contains('আপনার জীবন')));
    expect(_reject('loto', 'handkey'), contains('অন্যের হাতে'));
    expect(_reject('loto', 'boardonly'), contains('বোর্ড একা'));
    expect(_reject('loto', 'nolock'), contains('ব্রেকার ON'));
    // Road: 11 kV across the road at 6.5 m (about 21 ft, live text, ruling A2).
    expect(_safeIds('road'), {'high', 'patrol'});
    expect(_reject('road', 'low'), allOf(contains('6.5 মিটার'), contains('21 ফুট')));
    expect(_reject('road', 'covered'), contains('বেয়ার ধরার আইন'));
    expect(_reject('road', 'walk'), contains('আইনি দায়িত্ব'));
    // Earth: both ends with rods and chains, or the tester first (M8-17).
    expect(_safeIds('earth'), {'both', 'tester'});
    expect(_opt('earth', 'tester').labelBn, contains('0 V'));
    expect(_reject('earth', 'oneside'), contains('দুই প্রান্তে'));
    expect(_reject('earth', 'ball'), contains('শর্ট সার্কিট ≠ আর্থিং'));
    expect(_reject('earth', 'jugaad'), contains('জুগাড়'));
    expect(_reject('earth', 'bare'), contains('আর্থ করা হচ্ছে'));
    // PPE: whole gloves and boots; the own rod and chain.
    expect(_safeIds('ppe'), {'full', 'rod'});
    expect(_reject('ppe', 'torn'), contains('ছেঁড়া গ্লাভস'));
    expect(_reject('ppe', 'sole'), contains('ছেঁড়া জুতো'));
    expect(_reject('ppe', 'veteran'), contains('অতি-আত্মবিশ্বাসী'));
    expect(_reject('ppe', 'mate'), contains('অন্যকে বিশ্বাস করবেন না'));
    expect(pack.earnedBn, allOf(contains('লিখিত পারমিট'), contains('রড আর্থ')));
    expect(M8Board85Lines.newGuideLines, contains(pack.introBn));
  });

  test('the Module 8 rulings in the words: the 6.5 m span (not 18–19 ft), no old numbers, no DO', () {
    for (final l in _allText()) {
      expect(l, isNot(contains('18–19 ফুট')), reason: '"$l": the old 18–19 ft (live text: 6.5 m)');
      expect(l, isNot(contains('1.2 মিটার')), reason: '"$l": the LT house gap left the board');
      for (final no in ['ড্রপ আউট', 'ডিও', 'DO ফিউজ', 'ম্যাট', 'অপারেটিং রড']) {
        expect(l, isNot(contains(no)), reason: '"$l": no DO, mat or rod on this board');
      }
    }
  });

  test('every picture exists (vector scenes from tool/m8_board85_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m8_board85 folder is a card on the board', () {
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

  test('the pictures: the tester on the earth-first card, the padlock and board on the locked breaker', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const lcd = '#A9C997'; // the tester's window
    const padlockBody = 'width="10" height="8" rx="1.5" fill="#E5B92E"';
    const greenOff = 'fill="#3E9B4F"'; // the breaker's OFF window
    // M8-17: the tester is in the picture of the tester-first card (and the
    // chain-only and bare-hand traps, where it lies unused).
    expect(svg('earth_tester'), contains(lcd), reason: 'earth_tester: the tester shows 0 V before the rod');
    // LOTO: the OFF window and the padlock on every breaker card; the no-lock trap has no padlock.
    for (final c in ['loto_lock', 'loto_pocket', 'loto_keyin', 'loto_handkey', 'loto_boardonly', 'loto_nolock']) {
      expect(svg(c), contains(greenOff), reason: '$c: the breaker is at OFF');
    }
    expect(svg('loto_nolock'), isNot(contains(padlockBody)), reason: 'loto_nolock: no padlock');
    expect(svg('loto_lock'), contains(padlockBody), reason: 'loto_lock: the padlock on the handle');
    expect(svg('road_covered'), contains('#4B5A4A'), reason: 'road_covered: the covered conductor');
  });

  test('the careless lineman says the lesson\'s first myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _myth1);
    expect(M8Board85Lines.rivalMyth, _myth1);
    expect(m.believeNoIsCorrect, isTrue, reason: 'a myth: the answer is না');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('চেনে না')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M8Board85Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M8Board85Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 19 trap reasons, 15 right
    // chips, 3 myth chips, the closing line — pinned so none is forgotten.
    final g = M8Board85Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    for (final s in pack.slots) {
      expect(g, contains(s.promptBn));
    }
    expect(g.length, 1 + 5 + 19 + 15 + 3 + 1);
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

    testWidgets('a miss on every round: below the pass line, nothing cleared', (t) async {
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
      expect(save.rungProgress[_rung], isNot('cleared'), reason: 'five misses: below the pass line');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a trap teaches with its own line; no reason deck opens and one miss does not end the board', (t) async {
      final c = await _open(t);
      final first = pack.slots.first;
      await _settleHand(t, 'pick', _ids(first.options, correct: false), 'the first hand has a trap');
      final shown = _shownIds('pick').intersection(_ids(first.options, correct: false));
      expect(shown, isNotEmpty);
      final id = shown.first;
      await tapBoardCard(t, _dealt('pick', {id}));
      final reject = first.options.firstWhere((o) => o.id == id).rejectBn;
      await _pumpUntil(t, () => find.text(reject).evaluate().isNotEmpty, what: 'the trap\'s line');
      for (final w in first.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.5', ladderIndex: 0, pack: pack, muted: true),
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
