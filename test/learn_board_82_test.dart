// Module 8 lesson 8.2 picture board ("সাপ্লাই কোড (Supply Code): গ্রাহক পরিষেবার
// নিয়মাবলী", rung 8.2/learn, pack learn_8_2): its content follows the live
// lesson 8.2 and the Module 8 rulings (M8-18 hook order, M8-21 five rounds,
// M8-11 no logos, X1/N4 the deadly hook-touch), every picture exists and no
// colour or backdrop gives the safe card away, the coworker's myth is the
// lesson's own and every new line is listed for recording, a clean play
// (picks, reasons, the myth) clears the rung, three misses offer the lesson
// again, a deadly-class trap teaches with the lesson's words (boards have no
// freeze: kit design), the gesture hint sweeps without pressing, and the board
// waits quietly once dealt.
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
import 'package:slm_flutter/features/game/learn_board_pack82.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/learn_feedback_lines.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack82;
const _artDir = 'assets/game/art/m8_board82';
const _rung = '8.2/learn';

/// Live lesson 8.2 (the notice rule, Sec 56) and the hook order (M8-18), word for word where quoted.
const _noticeRule = '15 দিনের ক্লিয়ার নোটিশ পিরিয়ড ছাড়া সাধারণ বকেয়ার জন্য লাইন কাটা যায় না।';
const _noticeEarly = '15 দিনের ক্লিয়ার নোটিশ পিরিয়ড শেষ হওয়ার আগে সাধারণ বকেয়ার জন্য লাইন কাটা যায় না।';

/// Has read lesson 8.2 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['8_2', '8.2']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.2', ladderIndex: 0, pack: pack, muted: true),
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

/// The coworker scene: he says the lesson's myth, then the guide asks; the
/// right answer (না to "বিশ্বাস করেন?", হ্যাঁ to "সেটা কি ভুল?") and a right reason.
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

  test('the lesson 8.2 board with five rounds (ruling M8-21)', () {
    expect(pack.lessonId, '8.2');
    expect(pack.titleBn, 'সাপ্লাই কোড (Supply Code): গ্রাহক পরিষেবার নিয়মাবলী', reason: 'the live title');
    expect(pack.badgeBn, 'জরুরী রেগুলেশন (WBERC ফোকাস)', reason: 'the lesson\'s own badge');
    // Round 4 of the spec (reconnection and dismantling) left the board.
    expect(pack.slots.map((s) => s.id), ['wayleave', 'meter', 'notice', 'hook', 'sec126']);
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
    expect(pack.myth.believeNoIsCorrect, isTrue, reason: 'a notice-free cut is never right');
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

  test('every on-screen string uses English digits, the house words and the term rules', () {
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp('[০-৯]'))), reason: '"$l": English digits on screen');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        expect(l, isNot(matches(RegExp('(?<![ঀ-৿])$bad'))), reason: '"$l": house word for "$bad"');
      }
      // Owner term rules: «ডেড» never «মৃত»/«মরা»; LT/HT/11 kV/kVA in English letters;
      // ON/OFF never অন/অফ; closing an AB is «AB লাগানো», never «AB বন্ধ».
      expect(l, isNot(matches(RegExp('মৃত|মরা'))), reason: '"$l": «ডেড», not «মৃত»');
      expect(l, isNot(matches(RegExp('এলটি|এইচটি|কেভি'))), reason: '"$l": LT / HT / kV in English letters');
      expect(l, isNot(matches(RegExp(r'(?<![ঀ-৿])(অন|অফ)(?![ঀ-৿])'))), reason: '"$l": ON / OFF, not অন / অফ');
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": «AB লাগানো», never «AB বন্ধ»');
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

  test('the lesson\'s rules: wayleave consent, meter place, notice, hook evidence, Sec 126', () {
    // Wayleave: written consent of the landowner (section 1, 'লিখিত সম্মতি').
    expect(_safeIds('wayleave'), {'consent', 'route'});
    expect(_opt('wayleave', 'consent').labelBn, contains('লিখিত সম্মতি'));
    expect(_reject('wayleave', 'nod'), contains('লিখিত সম্মতি বাধ্যতামূলক'));
    expect(_reject('wayleave', 'pit'), contains('আইনি মামলায়'));
    expect(_reject('wayleave', 'shout'), contains('গায়ের জোর'));
    expect(_reject('wayleave', 'diag'), contains('ব্যক্তিগত জমি'));
    // Meter: outside or ground floor, company decides, no move without an order or fee.
    expect(_safeIds('meter'), {'outside', 'slip'});
    expect(_reject('meter', 'bed'), contains('সাপ্লাই কোড বিরোধী'));
    expect(_reject('meter', 'roof'), contains('একতলায়'));
    expect(_reject('meter', 'point'), contains('কোম্পানি ঠিক করে'));
    expect(_reject('meter', 'unscrew'), allOf(contains('ফি'), contains('ফিজিবিলিটি')));
    // Notice: 15 clear days, Sec 56 written notice, reading and seal first.
    expect(_safeIds('notice'), {'notice', 'read'});
    expect(_reject('notice', 'none'), _noticeRule);
    expect(_reject('notice', 'shout'), allOf(contains('সেকশন 56'), contains('15 দিনের লিখিত নোটিশ')));
    expect(_reject('notice', 'recent'), _noticeEarly);
    expect(_reject('notice', 'shut'), allOf(contains('রিডিং'), contains('সীল')));
    expect(_slot('notice').whyChips.any((w) => w.correct && w.textBn.contains('15 দিনের ক্লিয়ার')), isTrue);
    // Hook: the evidence first (pro tip 1); no notice for theft (Sec 135).
    expect(_safeIds('hook'), {'film', 'seize'});
    expect(_reject('hook', 'pull'), contains('প্রথম কাজ প্রমাণ জোগাড়'));
    expect(_reject('hook', 'wall'), contains('পোল থেকে হুকিং তারটা'));
    expect(_reject('hook', 'walk'), allOf(contains('Sec 135'), contains('কোনো নোটিশ লাগে না')));
    // Sec 126: a provisional bill first, a final order only after the hearing; no FIR.
    expect(_safeIds('sec126'), {'card', 'prov'});
    expect(_reject('sec126', 'fir'), allOf(contains('এফআইআর'), contains('Assessment')));
    expect(_reject('sec126', 'final'), allOf(contains('প্রভিশনাল'), contains('শুনানির পর')));
    expect(_reject('sec126', 'shove'), contains('ঝগড়া করবেন না'));
  });

  test('the deadly-class trap: the hook touched before the tester shows 0 V (N4 / X1), its order taught', () {
    final hand = _opt('hook', 'hand');
    expect(hand.correct, isFalse);
    expect(hand.rejectBn, allOf(contains('টেস্টারে 0 V'), contains('ডেড প্রমাণ'), contains('আর্থ'), contains('হুক')));
    // Hook removal is never a trap of its own order alone: the order is shown, not scored twice.
    expect(_slot('hook').cards, 5, reason: 'the deadly trap is in every hand (four traps, one safe card)');
  });

  test('every picture exists (vector scenes from tool/m8_board82_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m8_board82 folder is a card on the board', () {
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

  test('the coworker says the lesson\'s second myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'বিল বাকি থাকলে নোটিশ ছাড়াই লাইন কাটা যায়।');
    expect(m.believeNoIsCorrect, isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('সেকশন 56')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M8Board82Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M8Board82Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 19 trap reasons, 15 right chips
    // (3 a round), 3 myth chips, the closing line — pinned so none is forgotten.
    final g = M8Board82Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    expect(g, contains(_noticeRule));
    expect(g, contains(_noticeEarly));
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

    testWidgets('a clean play: every safe pick and its reason, then the coworker\'s myth — the rung is cleared', (t) async {
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

    testWidgets('three misses in a row offer the lesson again (the board\'s strike-out); a miss on every round fails the board', (t) async {
      final c = await _open(t);
      // Three wrong pictures in a row (a right pick clears the count): the
      // lesson is offered on the third; then the round is played right.
      final first = pack.slots.first;
      for (var i = 0; i < 3; i++) {
        await _tapDealt(t, 'pick', _ids(first.options, correct: false), 'wayleave: a trap, miss ${i + 1}');
      }
      await _pumpUntil(t, () => find.text(LearnCoachLines.threeMisses).evaluate().isNotEmpty, what: 'the three-miss offer');
      await _cleanRound(t, first);
      // Every other round missed once, then played right: below the pass line.
      for (final s in pack.slots.skip(1)) {
        await _tapDealt(t, 'pick', _ids(s.options, correct: false), '${s.id}: a trap');
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await _cleanRound(t, s);
      }
      await _beatTheRival(t);
      await _pumpUntil(t, () => find.byType(LevelFailPanel).evaluate().isNotEmpty, what: 'the fail panel');
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress[_rung], isNot('cleared'));
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the deadly-class trap (the hook touched before the tester) teaches with the lesson\'s order; no reason deck; no fail', (t) async {
      final c = await _open(t);
      // Every round before the hook round, played clean.
      for (final s in pack.slots.takeWhile((s) => s.id != 'hook')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is the order, shown in words.
      final hook = _slot('hook');
      await _settleHand(t, 'pick', {'hand'}, 'hook: the deadly trap (in every hand)');
      await tapBoardCard(t, _dealt('pick', {'hand'}));
      await _pumpUntil(t, () => find.text(_opt('hook', 'hand').rejectBn).evaluate().isNotEmpty, what: 'the order of the hook');
      for (final w in hook.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.2', ladderIndex: 0, pack: pack, muted: true),
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
