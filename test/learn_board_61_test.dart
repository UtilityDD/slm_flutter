// Module 6 lesson 6.1 picture board ("ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের
// হৃৎপিণ্ড", rung 6.1/learn, pack learn_6_1): its content follows the board's
// rules, the Module 6 rulings (M6-8: one recap round + the new material; X6:
// the live lesson text; M6-4: the lesson's own reject words) and the lesson's
// points, every picture exists and no colour or backdrop marks the safe card
// (in any hand the dealer can make), the rival's myth is the lesson's own and
// his new lines are listed for recording, a clean play (picks, reasons, the
// rival's myth) clears the rung, a play with a miss on every round and a wrong
// reason fails it, the gesture hint sweeps without pressing, and the board
// waits quietly once the first hand is dealt.
//
// Boards have no deadly freeze (kit design, GAME_DEVELOPER_GUIDE §10c): the
// deadly-class traps (the tank opened on the pole, the burnt DTR re-charged)
// cost a ◆ and say the lesson's own words; the test below pins those words.
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

const pack = learnBoardPack61;
const _artDir = 'assets/game/art/m6_board61';
const _rung = '6.1/learn';

/// Has read lesson 6.1 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_1', '6.1']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.1', ladderIndex: 150, pack: pack, muted: true),
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
/// right answer (না to "বিশ্বাস করেন?", হ্যাঁ to "সেটা কি ভুল?") and a reason.
/// The question waits for him: it never shows before his myth is up.
Future<void> _beatTheRival(WidgetTester t, {bool wrongReasonFirst = false}) async {
  final myth = pack.myth;
  bool asked() => find.text('বিশ্বাস করেন?').evaluate().isNotEmpty || find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  await _pumpUntil(t, () => find.text(myth.rivalLineBn).evaluate().isNotEmpty || asked(), what: 'the rival\'s myth');
  expect(find.text(myth.rivalLineBn), findsWidgets, reason: 'the rival speaks before the guide asks');
  await _pumpUntil(t, asked, what: 'the believe question');
  await t.pump(const Duration(milliseconds: 800));
  final flipped = find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  await t.tap(find.text(flipped ? 'হ্যাঁ' : 'না').last);
  await t.pump();
  if (wrongReasonFirst) {
    await _tapDealt(t, 'why', _ids(myth.whyChips, correct: false), 'a wrong myth reason');
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }
  await _tapDealt(t, 'why', _ids(myth.whyChips, correct: true), 'a right myth reason');
}

/// The lesson file writes য় ড় ঢ় as single code points; the app's strings use
/// the letter + nukta. Compare the two in one form.
String _norm(String s) =>
    s.replaceAll('য়', 'য়').replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়');

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '6.1');
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

  test('the lesson 6.1 board: one recap round plus the new material (ruling M6-8)', () {
    expect(pack.lessonId, '6.1');
    // Registered in learn_board_models.dart (learnBoardPackFor).
    final registered = learnBoardPackFor('6.1');
    expect(registered, same(learnBoardPack61));
    final lesson = _lesson();
    expect(pack.badgeBn, _norm(lesson['badge_name'] as String), reason: 'the lesson\'s own badge');
    expect(pack.titleBn, _norm(lesson['title'] as String));
    expect(pack.slots.map((s) => s.id), ['signs', 'inside', 'coil', 'act'], reason: 'M6-8: 4 rounds');
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
      expect(s.promptBn, isNot('সঠিক জিনিস বেছে নিন'), reason: '${s.id}: specific prompt');
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
  });

  test('every round: safe pictures and enough traps, each trap says why', () {
    for (final s in pack.slots) {
      // M6-8 fixes the rounds' contents (spec rounds 3–5 carry 7–8 cards).
      expect(s.options.length, inInclusiveRange(4, 8), reason: s.id);
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
      // After a miss the hand still holds one safe card (a different picture).
      for (var run = 0; run < 12; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        final trap = hand.firstWhere((o) => !o.correct);
        final next = d.afterMiss(hand, trap, s.options, {for (final o in hand) o.id});
        expect(next, hasLength(s.cards), reason: '${s.id}: a full re-deal');
        expect(next.where((o) => o.correct), hasLength(1), reason: '${s.id}: one safe card after a miss');
        expect(next.firstWhere((o) => o.correct).id, isNot(hand.firstWhere((o) => o.correct).id), reason: s.id);
      }
      final whys = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal('${s.id}/why', s.whyChips, count: s.whyCards);
        expect(hand.where((p) => p.correct), hasLength(1), reason: '${s.id} why');
        whys.add((hand.map((o) => o.id).toList()..sort()).join(','));
      }
      expect(whys.length, greaterThan(1), reason: '${s.id}: fresh reason deals');
    }
  });

  test('the lesson\'s points: outside signs, what is inside, the opened coil, the lineman\'s part', () {
    // Recap (M6-8): oil drip + gauge below MIN, pink gel, burnt drain oil;
    // traps: the hum, blue gel, mid-gauge oil (the Buchholz card left the
    // board, owner 2026-11-15).
    expect(_safeIds('signs'), {'drip', 'pink', 'burnt'});
    expect(_trapIds('signs'), {'hum', 'blue', 'midoil'});
    expect(_reject('signs', 'hum'), allOf(contains('গুনগুন'), contains('স্বাভাবিক')));
    expect(_reject('signs', 'blue'), contains('নীল বা কমলা'));
    expect(_reject('signs', 'midoil'), contains('MIN আর MAX'));
    // Inside: core, coils, kraft paper, oil; a static machine, induction, oil not water.
    expect(_safeIds('inside'), {'core', 'coils', 'paper', 'oil'});
    expect(_reject('inside', 'rotor'), contains('স্থির মেশিন'));
    expect(_reject('inside', 'wire'), contains('চৌম্বক আবেশে'));
    expect(_reject('inside', 'water'), contains('খনিজ তেল'));
    // Coil: black paper at the top, melted copper, a displaced coil, burst turns.
    expect(_safeIds('coil'), {'black', 'melt', 'bent', 'burst'});
    expect(_opt('coil', 'black').labelBn, contains('ওপরের দিকে'));
    expect(_reject('coil', 'yellow'), contains('হলুদ-বাদামি'));
    // Act (X6: 'লাইন থেকে বিচ্ছিন্ন করে', 'দ্রুত রিপোর্ট'; never 'অফ-লোড').
    // (The nameplate-photo card left the board, owner 2026-11-15.)
    expect(_safeIds('act'), {'report', 'gel', 'dga'});
    expect(_opt('act', 'dga').labelBn, contains('লাইন থেকে বিচ্ছিন্ন করে'));
    expect(_opt('act', 'report').labelBn, contains('দ্রুত রিপোর্ট'));
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect('${o.labelBn} ${o.rejectBn}', isNot(contains('OFF-লোড')), reason: '${s.id}/${o.id}: X6');
        expect('${o.labelBn} ${o.rejectBn}', isNot(contains('তড়িৎ')), reason: '${s.id}/${o.id}: X6');
      }
    }
    expect(pack.earnedBn, allOf(contains('রিপোর্ট'), contains('শপে')));
    expect(pack.earnedBn, contains('পরীক্ষার অনুরোধ'), reason: 'the lab tests; the lineman asks for them');
  });

  // The runner deals a round's reason chips whatever card was picked
  // (playbook §4: the right reason fits what the player did), so a right
  // chip is a rule for the whole round, never one picture's or one trap's.
  test('right reasons fit every safe pick of their round', () {
    final act = [for (final w in _slot('act').whyChips) if (w.correct) w.textBn];
    for (final t in act) {
      expect(t, isNot(contains('চার্জ')), reason: '"$t": the recharge rule is a trap reject line');
      expect(t, isNot(contains('শপে')), reason: '"$t": the shop rule is a trap reject line');
    }
    final coil = [for (final w in _slot('coil').whyChips) if (w.correct) w.textBn];
    for (final t in coil) {
      expect(t, isNot(contains('টার্ন ফাটা')), reason: '"$t": names one safe card only');
    }
    final signs = [for (final w in _slot('signs').whyChips) if (w.correct) w.textBn];
    for (final t in signs) {
      expect(t, isNot(contains('গোলাপি')), reason: '"$t": names one safe card only');
    }
    // One wording per idea across the decks (one clip each).
    final all = [
      for (final s in pack.slots) for (final w in s.whyChips) w.textBn,
      for (final w in pack.myth.whyChips) w.textBn,
    ];
    expect(all.toSet().length, all.length);
  });

  test('the deadly-class traps say the lesson\'s own words (no freeze on a board)', () {
    final lesson = _lesson();
    final content = lesson['content'] as Map<String, dynamic>;
    final myths = ((content['myth_buster'] as Map<String, dynamic>)['myths'] as List<dynamic>).cast<Map<String, dynamic>>();
    final reality3 = _norm(myths[2]['reality'] as String);
    final tank = _reject('act', 'poletank');
    expect(tank, startsWith('ভুল ও মারাত্মক বিপজ্জনক!'), reason: 'M6-4: the board keeps the lesson\'s own reject words');
    expect(reality3, contains('ভুল ও মারাত্মক বিপজ্জনক!'));
    expect(reality3, contains(tank.substring('ভুল ও মারাত্মক বিপজ্জনক! '.length)));
    expect(reality3, contains(_reject('act', 'dust')));
    final sections = (content['sections'] as List<dynamic>).cast<Map<String, dynamic>>();
    final points = [for (final s in sections) ...(s['points'] as List<dynamic>).cast<Map<String, dynamic>>()];
    final tip8 = _norm(points.firstWhere((p) => (p['item_name'] as String).startsWith('৮.'))['safety_tip'] as String);
    expect(tip8, contains('চার্জ করার ঝুঁকি নেবেন না'));
    expect(_reject('act', 'recharge'), contains('চার্জ করার ঝুঁকি নেবেন না'));
  });

  test('every picture exists (vector scenes from tool/m6_board61_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m6_board61 folder is a card on the board', () {
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

  // Rulings X1 / X3 / M6-4: hands on the DTR only once it is dead and earthed.
  // The platform cards show the AB open (handle down, red tag) and the earth
  // leads on; the recharge trap shows the handle pushed up, the earth set
  // left on the ground. No DO anywhere (M6-2): the AB and HG fuses only.
  test('hands on only when dead and earthed: the platform cards show the isolation', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const tag = 'width="8" height="11" rx="1.5" fill="#D8402F"'; // the red tag on the AB handle
    const earthStripe = 'stroke="#E8C830" stroke-width="2.4" fill="none" stroke-dasharray="4 4"';
    const handleDown = 'l10 8" stroke="#59626A"';
    const handleUp = 'l10 -8" stroke="#59626A"';
    for (final c in ['act_gel', 'act_dga', 'act_poletank']) {
      expect(svg(c), contains(tag), reason: '$c: the AB handle tagged');
      expect(svg(c), contains(handleDown), reason: '$c: the AB open');
      expect(svg(c), contains(earthStripe), reason: '$c: the earth leads on');
    }
    expect(svg('act_recharge'), contains(handleUp), reason: 'recharge: the AB pushed closed');
    expect(svg('act_recharge'), isNot(contains(tag)), reason: 'recharge: the tag gone');
    for (final c in ['act_report', 'act_ignore']) {
      expect(svg(c), contains(handleUp), reason: '$c: the DTR in service, the worker on the ground');
    }
  });

  test('the careless lineman says the lesson\'s third myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    final content = _lesson()['content'] as Map<String, dynamic>;
    final myths = ((content['myth_buster'] as Map<String, dynamic>)['myths'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(m.rivalLineBn, _norm(myths[2]['myth'] as String), reason: 'the lesson\'s own myth 3');
    expect(m.rivalLineBn, 'মাঠে পোলের ওপরে ঝুলন্ত অবস্থাতেই ট্রান্সফরমারের ট্যাঙ্ক খুলে কয়েল ঠিক করে ফেলা যায়।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the tank is opened only in a repair shop or a test lab');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('শপে')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board61Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M6Board61Lines.newRivalLines, M6Board61Lines.toRecord, reason: 'ruling M6-12: the drafts are pinned');
    for (final l in M6Board61Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  test('the guide\'s spoken lines are listed for the owner\'s wording and the voice session', () {
    final spoken = M6Board61Lines.guideSpoken;
    expect(M6Board61Lines.newGuideLines, spoken, reason: 'ruling M6-12: the drafts are pinned');
    // intro + 4 prompts + 13 trap reasons + 4×3 right reasons + sting + 3 myth reasons + earned.
    expect(spoken, hasLength(1 + 4 + 13 + 12 + 1 + 3 + 1));
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

    testWidgets('a miss on every round and a wrong myth reason (the board\'s strike-out): below the pass line', (t) async {
      final c = await _open(t);
      for (final s in pack.slots) {
        await _tapDealt(t, 'pick', _ids(s.options, correct: false), '${s.id}: a trap');
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await _tapDealt(t, 'pick', _ids(s.options, correct: true), '${s.id}: then the safe picture');
        await _tapDealt(t, 'why', _ids(s.whyChips, correct: true), '${s.id}: a right reason');
      }
      await _beatTheRival(t, wrongReasonFirst: true);
      await _pumpUntil(t, () => find.byType(LevelFailPanel).evaluate().isNotEmpty, what: 'the fail panel');
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress[_rung], isNot('cleared'), reason: '5 of 10 clean = 50% < 60%');
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
      final card = _dealt('pick', _ids(s.options, correct: false)).first;
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
        expect(hint().debugOptions, hasLength(pack.slots.first.cards), reason: 'a sweep over all four pictures, never one');
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.1', ladderIndex: 150, pack: pack, muted: true),
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
