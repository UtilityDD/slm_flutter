// Module 5 lesson 5.5 picture board ("'লো-ভোল্টেজ' সমস্যার সমাধান",
// rung 5.5/learn, pack learn_5_5): its content follows the board's rules and
// the lesson's points, every picture exists and no colour or backdrop marks
// the safe card (in any hand the dealer can make), the rival's myth is the
// lesson's own and his new lines are listed for recording, a clean play
// (picks, reasons, the rival's myth) clears the rung, a play with a miss on
// every round fails it, the gesture hint sweeps without pressing, and the
// board waits quietly once the first hand is dealt.
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

const pack = learnBoardPack55;
const _artDir = 'assets/game/art/m5_board55';
const _rung = '5.5/learn';

/// Has read lesson 5.5 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['5_5', '5.5']));
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

/// Waits until a card of [ids] is dealt and has landed, then taps it.
Future<void> _tapDealt(WidgetTester t, String prefix, Set<String> ids, String what) async {
  await _pumpUntil(t, () => _dealt(prefix, ids).evaluate().isNotEmpty, what: what);
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.5', ladderIndex: 132, pack: pack, muted: true),
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

/// The rival scene: he says the lesson's myth, then the guide asks; the
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
    SpokenOnce.resetForTest();
  });

  test('the lesson 5.5 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '5.5');
    // Registered by the director (learn_board_models.dart); until then null.
    expect(learnBoardPackFor('5.5'), same(learnBoardPack55));
    expect(pack.badgeBn, 'ফল্ট ফাইন্ডার');
    expect(pack.titleBn, "'লো-ভোল্টেজ' সমস্যার সমাধান");
    expect(pack.slots.map((s) => s.id), ['call', 'house', 'joint', 'neutral', 'area']);
    expect(pack.slots.length, 5, reason: 'ruling M5-11: boards trimmed to 5 rounds');
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
    final m = pack.myth;
    final lines = <String>[
      pack.titleBn, pack.badgeBn, pack.introBn, pack.earnedBn,
      for (final s in pack.slots) ...[
        s.promptBn,
        for (final o in s.options) ...[o.labelBn, o.rejectBn],
        for (final w in s.whyChips) w.textBn,
      ],
      m.tauntBn, m.rivalLineBn, m.exitBn, m.stingBn, ...m.dangerHints,
      for (final w in m.whyChips) w.textBn,
    ];
    for (final l in lines) {
      expect(l, isNot(matches(RegExp('[০-৯]'))), reason: '"$l": English digits on screen');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        // A whole word only: 'কোম্পানি' (the lesson's word) is not 'পানি'.
        expect(l, isNot(matches(RegExp('(?<![ঀ-৿])$bad'))), reason: '"$l": house word for "$bad"');
      }
    }
  });

  test('reason decks: a library of right and wrong, all about the same length', () {
    for (final s in pack.slots) {
      final right = [for (final w in s.whyChips) if (w.correct) w.textBn];
      final wrong = [for (final w in s.whyChips) if (!w.correct) w.textBn];
      expectLibrary('${s.id} why', right, wrong);
      expectSameLength('${s.id} why', [...right, ...wrong]);
      expect(s.whyChips.map((w) => w.id).toSet().length, s.whyChips.length, reason: '${s.id}: unique chip ids');
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
      // Reason chips: one right per deal, and the deals differ too.
      final whys = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal('${s.id}/why', s.whyChips, count: s.whyCards);
        expect(hand.where((p) => p.correct), hasLength(1), reason: '${s.id} why');
        whys.add((hand.map((o) => o.id).toList()..sort()).join(','));
      }
      expect(whys.length, greaterThan(1), reason: '${s.id}: fresh reason deals');
    }
  });

  test('the lesson\'s points: who has it, measure under load at the meter, every joint, neutral-earth, the DTR first', () {
    // Call: one customer or many first; never blame the company or go to the tap for one house.
    expect(_safeIds('call'), {'ask', 'sketch'});
    expect(_reject('call', 'climb'), contains('একজনের, না অনেকের'));
    expect(_reject('call', 'blame'), contains('নির্দিষ্ট ভোল্টেজ'));
    expect(_reject('call', 'tap'), contains('সার্ভিস কানেকশন'));
    // House: the meter's incoming terminals, with load on.
    expect(_safeIds('house'), {'incoming', 'pump'});
    expect(_reject('house', 'off'), allOf(contains('লোড ছাড়া'), contains('লোড থাকা অবস্থায়')));
    expect(_reject('house', 'dtr'), contains('ইনকামিং টার্মিনালে'));
    expect(_reject('house', 'socket'), contains('বাড়ির ভেতরে'));
    // Joint: every joint, at the pole and at the meter; a too-thin service cable raises the drop.
    expect(_safeIds('joint'), {'pole', 'meter', 'thermal'});
    expect(_reject('joint', 'onlyhot'), allOf(contains('প্রতিটি জয়েন্ট'), contains('পোলে এবং মিটারে')));
    expect(_reject('joint', 'inside'), contains('ভেতরে নয়'));
    expect(_reject('joint', 'thin'), contains('ভোল্টেজ ড্রপ'));
    expect(_slot('joint').whyChips.any((w) => w.correct && w.textBn.contains('হটস্পট')), isTrue);
    // Neutral: neutral-earth too; over 5-10 V points to the neutral.
    expect(_safeIds('neutral'), {'ne', 'note'});
    expect(_reject('neutral', 'shrug'), contains('5-10 ভোল্টের বেশি'));
    expect(_reject('neutral', 'pn'), contains('নিউট্রাল আর আর্থের মধ্যেও'));
    expect(_reject('neutral', 'weak'), contains('কাটা নিউট্রাল'));
    // Area: the DTR — LTDB incoming (ruling M5-15c), load vs nameplate, off-load tap with the DTR off.
    expect(_safeIds('area'), {'ltdb', 'clamp', 'tap'});
    expect(_opt('area', 'ltdb').labelBn, contains('এলটিডিবি'));
    expect(_reject('area', 'houses'), contains('ট্রান্সফরমার বা এলটি নেটওয়ার্কে'));
    expect(_reject('area', 'evening'), contains('পিক-লোডে'));
    expect(_reject('area', 'live'), allOf(contains('অফ-লোড'), contains('বন্ধ করে')));
    expect(pack.earnedBn, allOf(contains('একজনের'), contains('নিউট্রাল-আর্থ')));
  });

  test('every picture exists (vector scenes from tool/m5_board55_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m5_board55 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.svg'))
        .map((n) => '$_artDir/$n')
        .toSet();
    expect(onDisk, used, reason: 'no unused art and no missing art');
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

  // Ruling M5-2: a hand or tool on a DTR or a service joint only once it is
  // proven dead. The safe pictures show it; the live-DTR trap shows it is not.
  test('hands on only when proven dead: the safe pictures show the isolation, the live trap does not', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const openDo = 'transform="rotate(160 '; // a drop-out barrel hanging open
    const earthStripe = '#E8C830'; // the earth set's yellow stripe
    const pulledCutout = 'width="8" height="12" rx="1" fill="#2B3138"'; // the cut-out's empty slot
    final tap = svg('area_tap'), live = svg('area_live');
    expect(openDo.allMatches(tap).length, 3, reason: 'area_tap: all three drop-outs hang open');
    expect(tap, contains(earthStripe), reason: 'area_tap: the earth set is on');
    expect(tap, contains('stroke="#E5B92E" stroke-width="3"'), reason: 'area_tap: the operating rod by the pole');
    expect(tap, isNot(contains('rx="1.6" fill="url(#steel)"/><path')), reason: 'area_tap: no spanner on the tap');
    expect(live, isNot(contains(openDo)), reason: 'area_live: the drop-outs are closed — it is live');
    expect(live, contains('fill="#FFE08A"'), reason: 'area_live: the lane\'s windows are lit');
    for (final c in ['joint_pole', 'joint_meter']) {
      expect(svg(c), contains(pulledCutout), reason: '$c: the cut-out is pulled before the tightening');
    }
    // One house's complaint: the worker heads for the DTR but never touches a live tap.
    expect(svg('call_tap'), contains('stroke="#FFFFFF" stroke-width="1.8"'), reason: 'call_tap: walking to the DTR (motion lines)');
    expect(live, contains('rx="1.6" fill="url(#steel)"/><path'), reason: 'area_live: the spanner on the live tap');
  });

  test('the careless lineman says the lesson\'s second myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'একটু লো-ভোল্টেজ হলে কিছু হয় না, যন্ত্রপাতি তো চলছেই।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'low voltage makes motors draw more current and overheat');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('বেশি কারেন্ট')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('ওয়াইন্ডিং')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M5Board55Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M5Board55Lines.toRecord) {
      // A clip may already exist once the director records it; either way the
      // line is listed for the voice session.
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  group('board on screen', () {
    // The app's Bangla font, so text wraps on screen as it does on a phone
    // (the test font draws every Bangla glyph a full em wide).
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
        await _tapDealt(t, 'pick', _ids(s.options, correct: true), '${s.id}: a safe picture');
        await _tapDealt(t, 'why', _ids(s.whyChips, correct: true), '${s.id}: a right reason');
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
        // The trap's own reason is said while a fresh hand comes in.
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await _tapDealt(t, 'pick', _ids(s.options, correct: true), '${s.id}: then the safe picture');
        await _tapDealt(t, 'why', _ids(s.whyChips, correct: true), '${s.id}: a right reason');
      }
      await _beatTheRival(t);
      await _pumpUntil(t, () => find.byType(LevelFailPanel).evaluate().isNotEmpty, what: 'the fail panel');
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress[_rung], isNot('cleared'), reason: '7 of 12 clean = 58% < 60%');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong pick says the trap\'s own reason and opens no reason deck', (t) async {
      final c = await _open(t);
      final s = pack.slots.first;
      await _pumpUntil(t, () => _cards.evaluate().length == s.cards, what: 'the first hand');
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final trapIds = _ids(s.options, correct: false);
      final card = _dealt('pick', trapIds).first;
      final id = (t.widget(card).key! as ValueKey<String>).value.split('-').skip(2).join('-');
      await tapBoardCard(t, card);
      await _pumpUntil(t, () => find.text(_reject(s.id, id)).evaluate().isNotEmpty, what: 'the reject line');
      for (final w in s.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the "কেন" deck');
      }
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.5', ladderIndex: 132, pack: pack, muted: true),
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
