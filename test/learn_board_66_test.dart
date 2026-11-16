// Module 6 lesson 6.6 picture board ("এবি কেবিল (AB Cable): ঝঞ্ঝাটমুক্ত
// আধুনিক লাইন", rung 6.6/learn, pack learn_6_6): its content follows the
// board's rules, the live lesson and the Module 6 rulings (X6 'treat AB cable
// as live', R23 bare hands, R24 clamp and roller rows, the owner's term
// rules), every picture exists and no colour or backdrop marks the safe card
// (in any hand the dealer can make), the rival's myth is the lesson's own and
// every new line is listed for recording, a clean play (picks, reasons, the
// rival's myth) clears the rung, a miss on every round fails it (the board's
// strike-out), the deadly-class trap (bare hands) teaches with the lesson's
// own words (boards have no freeze: kit design), the gesture hint sweeps
// without pressing, and the board waits quietly once dealt.
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

import 'support/board_pick.dart';
import 'support/option_lengths.dart';

const pack = learnBoardPack66;
const _artDir = 'assets/game/art/m6_board66';
const _rung = '6.6/learn';
const _ladder = 165; // m6 starts at 150; three rungs per lesson, 6.6/learn the 16th

/// Lesson 6.6 myth 1's reality, its last sentence word for word (the
/// bare-hands trap's reason starts with it).
const _pinHole = 'যেকোনো ইনসুলেশনে একটি অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে, যা মারাত্মক শক দেওয়ার জন্য যথেষ্ট।';

/// Has read lesson 6.6 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_6', '6.6']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.6', ladderIndex: _ladder, pack: pack, muted: true),
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

/// Lesson 6.6 from the live lesson file.
Map<String, dynamic> _lesson() {
  final all = File('tool/all_training_chapters_bn.json').readAsStringSync();
  Map<String, dynamic>? hit;
  void walk(Object? o) {
    if (hit != null) return;
    if (o is Map<String, dynamic>) {
      if (o['id'] == '6.6' && o['content'] is Map) {
        hit = o;
        return;
      }
      o.values.forEach(walk);
    } else if (o is List) {
      o.forEach(walk);
    }
  }

  walk(jsonDecode(all));
  return hit!;
}

/// য় ড় ঢ় as base + nukta (the app's form; owner's unicode rule) and Bengali
/// digits as English.
String _norm(String s) {
  var t = s.replaceAll('য়', 'য়').replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়');
  const bn = '০১২৩৪৫৬৭৮৯';
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(bn[i], '$i');
  }
  return t;
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

  test('the lesson 6.6 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '6.6');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 6.6 entry.
    final wired = learnBoardPackFor('6.6');
    if (wired != null) expect(wired, same(learnBoardPack66));
    expect(pack.badgeBn, 'যন্ত্র গুরু', reason: 'the lesson\'s own badge');
    expect(pack.titleBn, _norm(_lesson()['title'] as String));
    // Five rounds (owner, after Wave A): the spec's roller and nick rounds
    // share the 'care' round.
    expect(pack.slots.map((s) => s.id), ['bundle', 'grip', 'pole', 'ipc', 'care']);
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

  test('every on-screen string uses English digits, the house words and the owner\'s term rules', () {
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp('[০-৯]'))), reason: '"$l": English digits on screen');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        expect(l, isNot(matches(RegExp('(?<![ঀ-৿])$bad'))), reason: '"$l": house word for "$bad"');
      }
      // Term rules (owner, after Wave A): ডেড not মৃত; ON / OFF not অন / অফ;
      // LT / HT / kV in English letters; an AB is never 'বন্ধ'.
      expect(l, isNot(contains('মৃত')), reason: '"$l": ডেড, not মৃত');
      expect(l, isNot(matches(RegExp('(?<![ঀ-৿])(অন|অফ)(?![ঀ-৿])'))), reason: '"$l": ON / OFF in English letters');
      for (final bad in ['এলটি', 'এইচটি', 'কেভি']) {
        expect(l, isNot(contains(bad)), reason: '"$l": LT / HT / kV in English letters');
      }
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": "AB বন্ধ" reads as the AB OFF');
      // Unicode: য় ড় ঢ় as base + nukta (the app's form).
      expect(l, isNot(matches(RegExp('[ড়ঢ়য়]'))), reason: '"$l": base + nukta');
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

  test('the lesson\'s points: the bundle, the messenger grip, the clamps, the IPC, rollers and repair', () {
    // Point 1: three insulated cores and a bare or insulated messenger.
    expect(_safeIds('bundle'), {'bare', 'insul'});
    expect(_opt('bundle', 'bare').labelBn, contains('বেয়ার মেসেঞ্জারে'));
    expect(_opt('bundle', 'insul').labelBn, contains('ইনসুলেটেড মেসেঞ্জারে'));
    expect(_reject('bundle', 'nomsg'), contains('টান বা ওজন'));
    expect(_reject('bundle', 'apart'), contains('বান্ডিল'));
    // Pro tips 1-2: every clamp on the messenger; the cores carry ridges.
    expect(_safeIds('grip'), {'bare', 'mark'});
    expect(_opt('grip', 'mark').labelBn, contains('আলাদা মাপের'));
    for (final r in ['r1', 'r3']) {
      expect(_opt('grip', r).labelBn, allOf(contains('রিজ'), contains('ফেজ তার')));
    }
    expect(_reject('grip', 'all'), contains('শুধু মেসেঞ্জার'));
    // Point 2: suspension on a straight run; tension where it ends or turns.
    expect(_safeIds('pole'), {'straight', 'end', 'turn'});
    expect(_opt('pole', 'straight').labelBn, contains('সাসপেনশন'));
    for (final id in ['end', 'turn']) {
      expect(_opt('pole', id).labelBn, contains('টেনশন'));
    }
    for (final id in ['endsus', 'turnsus']) {
      expect(_opt('pole', id).labelBn, contains('সাসপেনশন'));
      expect(_reject('pole', id), contains('টেনশন ক্ল্যাম্প'));
    }
    // Myth 2: an ordinary bare-line clamp cuts the insulation.
    expect(_reject('pole', 'bolt'), allOf(contains('ইনসুলেশন কেটে'), contains('গ্রিপ')));
    // Points 2-3: the IPC's teeth pierce; tightened until the shear head goes.
    expect(_safeIds('ipc'), {'sheared', 'teeth'});
    expect(_reject('ipc', 'twist'), contains('ধারালো দাঁত'));
    expect(_reject('ipc', 'bolt'), contains('বিশেষ ধরনের ফিটিংস'));
    // Point 3 and pro tip 4: rollers; a small nick sealed with tape or heat-shrink.
    expect(_safeIds('care'), {'roller', 'tape', 'shrink'});
    expect(_reject('care', 'drag'), contains('রোলার'));
    expect(_reject('care', 'open'), allOf(contains('জল ঢুকে ফল্ট'), contains('হিট-স্রিঙ্ক')));
    expect(_opt('care', 'tape').labelBn, allOf(contains('গ্লাভস'), contains('ওয়াটারপ্রুফ টেপ')));
    expect(pack.earnedBn, allOf(contains('মেসেঞ্জারে'), contains('শেয়ার-হেড'), contains('লাইভ')));
  });

  test('the lesson\'s own words where the board quotes it; the rulings (X6 live, R23 bare hands)', () {
    final c = _lesson()['content'] as Map<String, dynamic>;
    final all = _norm(jsonEncode(c));
    final myths = ((c['myth_buster'] as Map)['myths'] as List).cast<Map<String, dynamic>>();
    expect(pack.myth.rivalLineBn, _norm(myths[0]['myth'] as String), reason: 'myth 1, word for word');
    expect(_norm(myths[0]['reality'] as String), endsWith(_pinHole));
    // R23 (deadly class): bare hands on AB cable; its reason is myth 1's
    // reality word for word, then 'treat it as live' (X6, safety tip).
    expect(_reject('care', 'bare'), startsWith(_pinHole));
    expect(_reject('care', 'bare'), allOf(contains('লাইভ'), contains('গ্লাভস')));
    expect(all, contains('সবসময় \'লাইভ\' হিসেবেই গণ্য'), reason: 'X6: the live safety tip');
    // Point 3 (IPC) and point 2 (clamp on a phase core), word for word.
    expect(all, contains(_reject('ipc', 'head')));
    expect(all, contains(_reject('grip', 'r1')));
    // Point 2 wording the cards rest on.
    for (final q in ['সাসপেনশন ক্ল্যাম্প', 'টেনশন ক্ল্যাম্প', 'শেয়ার-হেড', 'হিট-স্রিঙ্ক', 'বিশেষ রোলার', 'রিজ']) {
      expect(all, contains(q), reason: 'the lesson says "$q"');
    }
    // No safe card shows or says bare hands; the only bare-hands card is a trap.
    for (final s in pack.slots) {
      for (final o in s.options) {
        if (o.correct) expect(o.labelBn, isNot(contains('খালি হাত')), reason: '${s.id}/${o.id}');
      }
    }
  });

  test('every picture exists (vector scenes from tool/m6_board66_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m6_board66 folder is a card on the board', () {
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

  // The pictures match their names: gloves on every working hand of the safe
  // cards (the cable is live, X6) and bare hands on the 'bare' trap; the
  // roller on its card only; the shear head still on the 'head' trap.
  test('the pictures: gloves or bare hands, the roller, the shear head, the rain', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const glove = '#2A2D33', skin = '#A86E48';
    // Big close-up hands (r 9 of a 200-wide card, about 7 px on a phone),
    // with long gauntlets over the sleeve or a bare brown forearm.
    const handDot = 'r="9" fill=';
    for (final c in ['care_tape', 'care_shrink', 'ipc_sheared']) {
      expect(svg(c), contains('$handDot"$glove"'), reason: '$c: gloved hands');
      expect(svg(c), isNot(contains('$handDot"$skin"')), reason: '$c: no bare hand');
    }
    expect(svg('care_bare'), contains('$handDot"$skin"'), reason: 'care_bare: bare hands on the cable');
    expect(svg('care_bare'), isNot(contains(glove)), reason: 'care_bare: no glove anywhere');
    const roller = 'r="8" fill="url(#steel)"';
    expect(svg('care_roller'), contains(roller), reason: 'care_roller: the roller on the bracket');
    expect(svg('care_drag'), isNot(contains(roller)), reason: 'care_drag: no roller');
    const headOn = 'M180 44';
    expect(svg('ipc_head'), contains(headOn), reason: 'ipc_head: the shear head still on');
    expect(svg('ipc_teeth'), isNot(contains(headOn)), reason: 'ipc_teeth: tightened home');
    expect(svg('ipc_sheared'), contains('rotate(28 141 122)'), reason: 'ipc_sheared: the head broke off and falls');
    expect(svg('care_open'), contains('#5E86B0'), reason: 'care_open: rain on the open nick');
    expect(svg('care_bare'), contains('stroke="#A86E48" stroke-width="10"'), reason: 'care_bare: bare forearms show');
    for (final c in ['care_tape', 'care_shrink']) {
      expect(svg(c), contains('stroke="#2A2D33" stroke-width="15"'), reason: '$c: gauntlets pulled over the sleeve');
    }
  });

  // Review (fixer): at phone size the side view of a twisted bundle cannot
  // show the messenger or count the ridges, so rounds 1 and 2 carry a
  // magnifier on the cable's cut end. These pin the cue in each picture.
  test('the magnifier: the messenger and the ridges can be told apart at card size', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const alu = '#C3C9CE', core = '#262B31', ridge = '#7A848E', lensFill = '#F4F8FA';
    for (final s in ['bundle', 'grip']) {
      for (final o in pack.slots.firstWhere((x) => x.id == s).options) {
        expect(svg('${s}_${o.id}'), contains('fill="$lensFill"'), reason: '${s}_${o.id}: every card in the round has the magnifier');
      }
    }
    // Round 1, end-on at the lens centre: a bare silver messenger, a bigger
    // black insulated one, or nothing (three cores round an empty middle).
    const mid = 'cx="74" cy="146" r=';
    expect(svg('bundle_bare'), contains('$mid"8.9" fill="$alu"'), reason: 'bundle_bare: bare messenger in the middle');
    expect(svg('bundle_insul'), contains('$mid"11.5" fill="$core"'), reason: 'bundle_insul: bigger insulated messenger');
    // (the lens glass itself is centred there too, so it is left out)
    expect(RegExp('${RegExp.escape(mid)}"[0-9.]+" fill="#(?!F4F8FA)').hasMatch(svg('bundle_nomsg')), isFalse,
        reason: 'bundle_nomsg: no messenger in the middle');
    // Round 2, the one conductor in the jaw, end-on: the insulated messenger
    // is clearly bigger (r 22 against the phase cores' r 14) and smooth; the
    // phase cores carry 1 or 3 bold ridge bumps.
    const jaw = 'cx="112" cy="170" r=';
    final bump = RegExp('r="4.2" fill="$ridge"');
    expect(svg('grip_bare'), contains('$jaw"14" fill="$alu"'), reason: 'grip_bare: the bare messenger');
    expect(svg('grip_mark'), contains('$jaw"22" fill="$core"'), reason: 'grip_mark: a bigger insulated messenger');
    expect(svg('grip_r1'), contains('$jaw"14" fill="$core"'));
    expect(svg('grip_r3'), contains('$jaw"14" fill="$core"'));
    expect(bump.allMatches(svg('grip_mark')).length, 0, reason: 'grip_mark: no ridge on the messenger');
    expect(bump.allMatches(svg('grip_bare')).length, 0);
    expect(bump.allMatches(svg('grip_r1')).length, 1, reason: 'grip_r1: one ridge');
    expect(bump.allMatches(svg('grip_r3')).length, 3, reason: 'grip_r3: three ridges');
  });

  test('the careless lineman says the lesson\'s first myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'এবি কেবিল তো সম্পূর্ণ ইনসুলেটেড, তাই এটাতে খালি হাতে কাজ করা যায়।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'a pin-hole is enough for a deadly shock');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('পিন-হোল')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board66Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M6Board66Lines.newRivalLines, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M6Board66Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 15 trap reasons, 15 right
    // chips, 3 myth chips, the closing line — pinned so none is forgotten.
    final g = M6Board66Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    expect(g, contains(M6Board66Lines.bareHandsReject));
    for (final s in pack.slots) {
      expect(g, contains(s.promptBn));
      for (final o in s.options) {
        if (!o.correct) expect(g, contains(o.rejectBn), reason: '${s.id}/${o.id}: its spoken reason is listed');
      }
      for (final w in s.whyChips) {
        if (w.correct) expect(g, contains(w.textBn), reason: '${s.id}/${w.id}: spoken once chosen');
      }
    }
    for (final w in m.whyChips) {
      if (w.correct) expect(g, contains(w.textBn));
    }
    expect(g.length, 1 + 5 + 15 + 15 + 3 + 1);
    expect(g.toSet().length, g.length, reason: 'no line listed twice');
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
      expect(save.rungProgress[_rung], isNot('cleared'), reason: 'a miss on every round is below the pass line');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the deadly-class trap (bare hands on the cable) teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      // Every round before the last one (care), played clean.
      for (final s in pack.slots.takeWhile((s) => s.id != 'care')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is myth 1's reality, word for word.
      final care = _slot('care');
      await _settleHand(t, 'pick', {'bare'}, 'care: the bare-hands trap (all three traps are in every hand)');
      await tapBoardCard(t, _dealt('pick', {'bare'}));
      await _pumpUntil(t, () => find.text(M6Board66Lines.bareHandsReject).evaluate().isNotEmpty, what: 'the lesson\'s pin-hole reality');
      for (final w in care.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.6', ladderIndex: _ladder, pack: pack, muted: true),
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
