// Module 6 lesson 6.2 picture board ("সার্কিট ব্রেকার: চূড়ান্ত রক্ষাকর্তা",
// rung 6.2/learn, pack learn_6_2): its content follows the board's rules and
// the lesson's points (and the Module 6 rulings), every picture exists and no
// colour or backdrop marks the safe card (in any hand the dealer can make),
// the pictures match their cards, the rival's myth is the lesson's own and his
// new lines are listed for recording, a clean play (picks, reasons, the
// rival's myth) clears the rung, a play with a miss on every round fails it,
// a tap only opens a card, the gesture hint sweeps without pressing, and the
// board waits quietly once the first hand is dealt. Boards have no deadly
// freeze (kit design): a deadly-class trap costs the pending ◆ and says its
// lesson text.
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

const pack = learnBoardPack62;
const _artDir = 'assets/game/art/m6_board62';
const _rung = '6.2/learn';

/// Has read lesson 6.2 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_2', '6.2']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.2', ladderIndex: 153, pack: pack, muted: true),
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

  test('the lesson 6.2 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '6.2');
    // Registered in learn_board_models.dart (learnBoardPackFor).
    final registered = learnBoardPackFor('6.2');
    expect(registered, same(learnBoardPack62));
    expect(pack.badgeBn, 'যন্ত্র গুরু', reason: 'the lesson\'s own badge name');
    expect(pack.titleBn, 'সার্কিট ব্রেকার: চূড়ান্ত রক্ষাকর্তা');
    // Five rounds, as the Module 5 boards (ruling M5-11): the spring round
    // overlapped the lamp round and left the board (owner 2026-11-15).
    expect(pack.slots.map((s) => s.id), ['reset', 'vcb', 'lamp', 'rack', 'line']);
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
      // The opened card's name must not give the safe one away by its length.
      expectSameLength('${s.id} card names', [for (final o in s.options) o.labelBn]);
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
      final whys = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal('${s.id}/why', s.whyChips, count: s.whyCards);
        expect(hand.where((p) => p.correct), hasLength(1), reason: '${s.id} why');
        whys.add((hand.map((o) => o.id).toList()..sort()).join(','));
      }
      expect(whys.length, greaterThan(1), reason: '${s.id}: fresh reason deals');
    }
  });

  test('the lesson\'s points: reset vs replace, vacuum vs oil, red ON / green OFF, racking, green is not safe', () {
    // Reset: only a breaker interrupts a fault and is reset; a fuse is
    // replaced; the relay is the brain; an isolator is off-load only (live
    // myth 2 text, ruling X3), never "it breaks normal load".
    expect(_safeIds('reset'), {'vcb', 'ocb'});
    expect(_reject('reset', 'fuse'), contains('বদলে ফেলতে হয়'));
    expect(_reject('reset', 'isolator'), allOf(contains('OFF-লোড'), contains('ফল্ট কারেন্ট')));
    expect(_reject('reset', 'isolator'), isNot(contains('লোড কারেন্ট বন্ধ করতে পারে')),
        reason: 'live lesson: that is a load-break switch; an isolator is off-load only');
    expect(_reject('reset', 'relay'), allOf(contains('মস্তিষ্ক'), contains('পেশী')));
    expect(_reject('reset', 'switch'), contains('প্রচণ্ড আর্ক'));
    // VCB: contacts in vacuum, arc out at once; OCB: oil, gas bubble, old.
    expect(_safeIds('vcb'), {'bottles', 'cutaway'});
    expect(_reject('vcb', 'oiltank'), allOf(contains('OCB'), contains('তেলে')));
    expect(_reject('vcb', 'bubble'), contains('বুদবুদে'));
    // Lamps: red = ON, green = OFF; HEALTHY and SPRING CHARGED are not ON/OFF.
    expect(_safeIds('lamp'), {'green', 'green2'});
    for (final id in ['red', 'healthy', 'spring']) {
      expect(_reject('lamp', id), contains('ON'), reason: 'lamp/$id: red means ON');
    }
    // Racking: hands-on only racked out; SERVICE connected; TEST control live.
    expect(_safeIds('rack'), {'out', 'side'});
    expect(_reject('rack', 'service'), contains('সম্পূর্ণ যুক্ত'));
    expect(_reject('rack', 'test'), allOf(contains('কন্ট্রোল সার্কিট যুক্ত'), contains('সম্পূর্ণ বিচ্ছিন্ন নয়')));
    expect(_reject('rack', 'green'), contains('সার্ভিসে'));
    // Green is not safe: isolators at both ends, proved dead with a tester,
    // then earthed (live pro tip 1; ruling X1 — the tester before the earth).
    expect(_safeIds('line'), {'ends', 'earth'});
    expect(_opt('line', 'earth').labelBn, allOf(contains('টেস্টারে'), contains('আর্থ')));
    expect(_opt('line', 'earth').labelBn.indexOf('টেস্টারে'), lessThan(_opt('line', 'earth').labelBn.indexOf('আর্থ')),
        reason: 'X1: proved dead first, then the earth');
    expect(_reject('line', 'climb'), contains('শুধু ব্রেকার খোলা'));
    expect(_reject('line', 'tie'), contains('ব্যাক-ফিডিং'));
    expect(_reject('line', 'oneend'), allOf(contains('দুই প্রান্তে'), contains('টেস্টারে'), contains('আর্থিং')));
    expect(_reject('line', 'hand'), contains('ইন্ডুসড'));
    expect(_slot('line').whyChips.any((w) => w.correct && w.textBn.contains('টেস্টারে')), isTrue);
    expect(pack.earnedBn, allOf(contains('দুই প্রান্তে'), contains('টেস্টারে'), contains('আর্থিং')));
    // No Module 6 card uses a drop-out fuse (ruling M6-2) or names kV figures.
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect('${o.labelBn} ${o.rejectBn}', isNot(contains('ড্রপ আউট')), reason: '${s.id}/${o.id}');
        expect('${o.labelBn} ${o.rejectBn}', isNot(contains('kV')), reason: '${s.id}/${o.id}: no kV on screen');
      }
    }
  });

  test('every picture exists (vector scenes from tool/m6_board62_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m6_board62 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final files = Directory(_artDir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();
    final onDisk = files.where((n) => n.endsWith('.svg')).map((n) => '$_artDir/$n').toSet();
    expect(onDisk, used, reason: 'no unused art and no missing art');
    expect(files.where((n) => !n.endsWith('.svg')), isEmpty, reason: 'nothing but the cards ships in the folder');
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
  // the safe card's backdrop and colours are on a trap in that hand too, and
  // the other way round: nothing (a colour, the worker's pose
  // class="pose-stand" / "pose-climb", the coiled earth set
  // class="earth-coil") is on every trap of the hand and missing from its
  // safe card. Only what the lesson says through colour is exempt: an OFF
  // breaker's lamps (red = ON, green = OFF), so red lit and green dark are on
  // the lamp round's traps (as in tool/m6_board62_art.py LESSON_STATE).
  test('in every possible hand, the safe card\'s backdrop and colours are on a trap too', () {
    final used = RegExp(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b|class="[\w-]+"');
    const lessonState = {
      'lamp': {'#FF4B3A', '#1E4A2C'},
    };
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
          final onEveryTrap = hand.map((o) => tokens(o.asset)).reduce((a, b) => a.intersection(b));
          expect(onEveryTrap.difference(tokens(safe.asset)).difference(lessonState[s.id] ?? const <String>{}), isEmpty,
              reason: '$ids — on every trap and missing from the safe card');
        }
      }
      expect(hands, greaterThan(0), reason: s.id);
    }
  });

  // The pictures show what their cards say: an OFF breaker's green lamp,
  // the trolley racked out with its lamps dark, both isolators open, and the
  // earths only after the tester (ruling X1); on the traps the earth set lies
  // unused.
  test('the pictures match their cards: lamps, racking, isolators, tester then earth', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const redLit = 'r="9" fill="#FF4B3A"', redDark = 'r="9" fill="#5E2622"';
    const greenLit = 'r="9" fill="#45E06E"', greenDark = 'r="9" fill="#1E4A2C"';
    for (final c in ['lamp_green', 'lamp_green2']) {
      expect(svg(c), allOf(contains(greenLit), contains(redDark)), reason: '$c: OFF = green lit, red dark');
    }
    for (final c in ['lamp_red', 'lamp_healthy', 'lamp_spring']) {
      expect(svg(c), allOf(contains(redLit), contains(greenDark)), reason: '$c: ON = red lit');
    }
    // Racked out: the cubicle's shutters shut, both breaker lamps dark.
    const rackRedLit = 'r="6" fill="#FF4B3A"', rackGreenLit = 'r="6" fill="#45E06E"';
    expect(svg('rack_out'), allOf(isNot(contains(rackRedLit)), isNot(contains(rackGreenLit))),
        reason: 'ISOLATED: power and control both cut, no lamp lit');
    expect(svg('rack_service'), contains(rackRedLit), reason: 'SERVICE: connected and ON');
    expect(svg('rack_test'), contains(rackGreenLit), reason: 'TEST: the control circuit is still live');
    expect(svg('rack_green'), contains(rackGreenLit), reason: 'SERVICE with the green lamp lit');
    // Isolators: an open blade is drawn raised.
    const raised = 'rotate(-72 ';
    expect(raised.allMatches(svg('line_ends')).length, 6, reason: 'both ends open, all three phases');
    expect(raised.allMatches(svg('line_oneend')).length, 3, reason: 'only the near end open');
    expect(raised.allMatches(svg('line_tie')).length, 3, reason: 'the far end closed onto another feeder');
    // Tester then earth: the used tester by the pole and three earth leads on.
    const testerHead = 'fill="#D8402F"';
    const coiled = 'class="earth-coil"'; // the earth set lying coiled, unused
    expect(svg('line_earth'), contains(testerHead), reason: 'line_earth: the tester was used first');
    expect('stroke="#3E9B4F" stroke-width="2.2"'.allMatches(svg('line_earth')).length, 3, reason: 'earths on all three phases');
    expect(svg('line_earth'), isNot(contains(coiled)), reason: 'the earth set is on, not coiled');
    for (final c in ['line_climb', 'line_hand']) {
      expect(svg(c), contains(coiled), reason: '$c: the earth set lies unused on the ground');
    }
    expect(svg('line_ends'), allOf(contains(coiled), contains(testerHead)),
        reason: 'line_ends: isolated, not yet earthed (the tester in hand, the earth set still coiled)');
    // The worker's pose marks no card: on the ground on a safe card and two
    // traps, up the pole on a safe card and two traps.
    const stand = 'class="pose-stand"', climb = 'class="pose-climb"';
    for (final c in ['line_ends', 'line_tie', 'line_oneend']) {
      expect(svg(c), allOf(contains(stand), isNot(contains(climb))), reason: '$c: on the ground');
    }
    for (final c in ['line_earth', 'line_climb', 'line_hand']) {
      expect(svg(c), allOf(contains(climb), isNot(contains(stand))), reason: '$c: up the pole');
    }
    // Both rack safe cards are racked out: the cubicle shut, its lamps dark.
    expect(svg('rack_side'), allOf(isNot(contains(rackRedLit)), isNot(contains(rackGreenLit))),
        reason: 'rack_side: ISOLATED, no lamp lit');
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'সার্কিট ব্রেকার ট্রিপ করেছে মানে লাইনটি সম্পূর্ণ বন্ধ। এতে কোনো ভোল্টেজ নেই।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'back-feed or induced voltage can keep the line dangerous');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('ব্যাক-ফিডিং')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('ইন্ডুসড')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board62Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M6Board62Lines.newRivalLines, M6Board62Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M6Board62Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The sting is the module's recorded line.
    expect(LearnVoice.resolve(m.stingBn), isNotNull, reason: 'recorded guide sting');
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

    testWidgets('a tap only opens the card: ✕ sets it aside and answers nothing', (t) async {
      final c = await _open(t);
      final s = pack.slots.first;
      await _pumpUntil(t, () => _cards.evaluate().length == s.cards, what: 'the first hand');
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final card = _dealt('pick', _ids(s.options, correct: false)).first;
      final id = (t.widget(card).key! as ValueKey<String>).value.split('-').skip(2).join('-');
      await openBoardCard(t, card);
      expect(find.text(_reject(s.id, id)), findsNothing, reason: 'an opened card is not an answer');
      await t.tap(boardReject, warnIfMissed: false);
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(boardConfirm, findsNothing, reason: '✕ closes the preview');
      expect(find.text(_reject(s.id, id)), findsNothing, reason: '✕ answers nothing');
      expect(_cards, findsNWidgets(s.cards), reason: 'the hand stays as dealt');
      expect(c.read(gameSaveProvider).rungProgress[_rung], isNull);
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.2', ladderIndex: 153, pack: pack, muted: true),
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
