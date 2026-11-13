// Module 5 lesson 5.9 picture board ("কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা",
// rung 5.9/learn, pack learn_5_9): its content follows the board's rules, the
// lesson's points and the Module 5 rulings, every picture exists and no colour
// or backdrop marks the safe card (in any hand the dealer can make), the
// rival's myth is the lesson's own, the board plays through to a saved clear
// (reasons and the rival included), too many first-try misses fail it, a hand
// shows how to choose when the player is stuck, and it waits quietly.
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
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack59;
const _artDir = 'assets/game/art/m5_board59';
const _rung = '5.9/learn';

/// Has read lesson 5.9 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['5_9', '5.9']));
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

/// The dealt picture cards (`pick-<wave>-<id>`) or reason chips
/// (`why-<wave>-<id>`) on screen whose id is in [ids].
Finder _dealt(String kind, Iterable<String> ids) {
  final set = ids.toSet();
  final re = RegExp('^$kind-\\d+-(\\w+)\$');
  return find.byWidgetPredicate((w) {
    final k = w.key;
    if (k is! ValueKey<String>) return false;
    final m = re.firstMatch(k.value);
    return m != null && set.contains(m.group(1));
  }).hitTestable();
}

Future<void> _pumpFor(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _until(WidgetTester t, bool Function() done, String what, {int seconds = 40}) async {
  for (var i = 0; i < seconds * 10 && !done(); i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(done(), isTrue, reason: 'waited ${seconds}s for $what');
}

Future<void> _open(WidgetTester t, {bool reduce = true}) async {
  t.view.physicalSize = const Size(720, 1600);
  t.view.devicePixelRatio = 2.0;
  t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
  SharedPreferences.setMockInitialValues({});
  await t.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith(_TestAuth.new)],
    child: MaterialApp(
      theme: SlmTheme.night(),
      home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.9', ladderIndex: 228, pack: pack, muted: true),
    ),
  ));
}

Future<void> _close(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  t.platformDispatcher.clearAccessibilityFeaturesTestValue();
  t.view.reset();
}

GameSave _save(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(LearnBoardRunnerPage))).read(gameSaveProvider);

/// Plays every round: optionally one wrong picture first, then the safe one,
/// then a right reason.
Future<void> _playRounds(WidgetTester t, {required bool missFirst}) async {
  for (final s in pack.slots) {
    final safe = [for (final o in s.options) if (o.correct) o.id];
    final traps = [for (final o in s.options) if (!o.correct) o.id];
    await _until(t, () => _dealt('pick', safe).evaluate().isNotEmpty, '${s.id}: the hand');
    await _pumpFor(t, 600);
    expect(find.text(s.promptBn), findsWidgets, reason: '${s.id}: the guide asks the round\'s question');
    if (missFirst) {
      await pickBoardCard(t, _dealt('pick', traps));
      // The wrong card shakes, then the hand is dealt again.
      await _pumpFor(t, 1500);
      await _until(t, () => _dealt('pick', safe).evaluate().isNotEmpty, '${s.id}: the redeal');
    }
    await pickBoardCard(t, _dealt('pick', safe));
    final right = [for (final w in s.whyChips) if (w.correct) w.id];
    await _until(t, () => _dealt('why', right).evaluate().isNotEmpty, '${s.id}: the reason chips');
    await _pumpFor(t, 1200);
    await pickBoardCard(t, _dealt('why', right));
  }
}

/// The rival's two beats: he storms in and says the myth with no question on
/// screen; only after he has gone does the guide ask, and the answer opens.
Future<void> _beatRival(WidgetTester t) async {
  final myth = find.text(M5Board59Lines.rivalMyth, findRichText: true);
  await _until(t, () => myth.evaluate().isNotEmpty, 'the rival\'s myth');
  expect(find.text('হ্যাঁ'), findsNothing, reason: 'no answer while he talks');
  expect(find.text('না'), findsNothing, reason: 'no answer while he talks');
  final plain = find.text('বিশ্বাস করেন?');
  final flipped = find.text('সেটা কি ভুল?');
  await _until(t, () => plain.evaluate().isNotEmpty || flipped.evaluate().isNotEmpty, 'the guide\'s question');
  expect(myth, findsNothing, reason: 'he has left before the question');
  // The myth is false: "বিশ্বাস করেন?" → না; "সেটা কি ভুল?" → হ্যাঁ.
  await t.tap(find.text(plain.evaluate().isNotEmpty ? 'না' : 'হ্যাঁ'));
  await t.pump();
  final right = [for (final w in pack.myth.whyChips) if (w.correct) w.id];
  await _until(t, () => _dealt('why', right).evaluate().isNotEmpty, 'the myth reason chips');
  await _pumpFor(t, 1200);
  await pickBoardCard(t, _dealt('why', right));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
  });
  // The app's Bangla font, so text wraps on screen as it does on a phone
  // (the test font draws every Bangla code point a full em wide).
  setUpAll(() async {
    final loader = FontLoader('Noto Sans Bengali');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/NotoSansBengali-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  });

  test('the lesson 5.9 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '5.9');
    // Registered by the director (learn_board_models.dart); until then null.
    expect(learnBoardPackFor('5.9'), same(learnBoardPack59));
    expect(pack.badgeBn, 'ফল্ট ফাইন্ডার');
    expect(pack.titleBn, 'কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা');
    expect(pack.slots.map((s) => s.id), ['cause', 'short', 'earth', 'route', 'locate']);
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
        expect(l, isNot(contains(bad)), reason: '"$l": house word for "$bad"');
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
      final safeSeen = <String>{};
      for (var run = 0; run < 16; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        expect(hand, hasLength(s.cards), reason: s.id);
        expect(hand.where((p) => p.correct), hasLength(1), reason: s.id);
        safeSeen.add(hand.firstWhere((p) => p.correct).id);
        hands.add(hand.map((o) => o.id).join(','));
      }
      expect(hands.length, greaterThan(1), reason: '${s.id}: fresh deals');
      expect(safeSeen.length, greaterThan(1), reason: '${s.id}: the safe picture changes between plays');
      final why = d.deal('${s.id}/why', s.whyChips, count: s.whyCards);
      expect(why.where((w) => w.correct), hasLength(1), reason: '${s.id}: one right reason per deal');
      expect(why.map((w) => w.id).toSet(), hasLength(s.whyCards), reason: '${s.id}: three different reasons');
    }
  });

  test('the lesson\'s points: causes, fault type by megger, the route walk, locating before digging', () {
    // Causes: digging (the most common), moisture in a joint, rats or termites; never the weather.
    expect(_slot('cause').options.where((o) => o.correct).map((o) => o.id), ['dig', 'joint', 'rat']);
    expect(_reject('cause', 'storm'), contains('আবহাওয়া থেকে সুরক্ষিত'));
    expect(_reject('cause', 'dry'), contains('আর্দ্রতা ঢুকলে'));
    expect(_reject('cause', 'branch'), contains('ওভারহেড'));
    // Short circuit: zero or very low between two cores; core-to-armour = earth; no beep = open.
    expect(_slot('short').options.where((o) => o.correct).map((o) => o.id), ['needle', 'digital']);
    expect(_reject('short', 'inf'), contains("'শূন্য' বা খুব কম"));
    expect(_reject('short', 'armour'), contains('আর্থ ফল্ট'));
    expect(_reject('short', 'open'), contains('ওপেন সার্কিট'));
    // Earth fault: very low between one core and the armour.
    expect(_slot('earth').options.where((o) => o.correct).map((o) => o.id), ['needle', 'digital']);
    expect(_reject('earth', 'yb'), allOf(contains('শর্ট সার্কিট'), contains('আর্মারের মধ্যে')));
    expect(_reject('earth', 'inf'), contains('আর্থ ফল্ট নেই'));
    expect(_reject('earth', 'beep'), contains('কন্টিনিউটি'));
    // Route: on the mapped route, fresh digging / wet or burnt patch; open the joint pits.
    expect(_slot('route').options.where((o) => o.correct).map((o) => o.id), ['dig', 'burn', 'pit']);
    expect(_reject('route', 'off'), contains('রুটের বাইরের'));
    expect(_reject('route', 'shut'), contains('খুলে দেখুন'));
    expect(_reject('route', 'nomap'), contains('অন্ধকারে ঢিল'));
    // Locate: TDR distance, thumper + microphone, ask the underground-service owners first (ruling M5-7).
    expect(_slot('locate').options.where((o) => o.correct).map((o) => o.id), ['tdr', 'thump', 'call']);
    expect(_label('locate', 'call'), contains('ভূগর্ভস্থ লাইনের মালিক'));
    expect(_reject('locate', 'nocall'),
        contains('খোঁড়ার আগে কেবিল রুট রেকর্ড দেখুন এবং অন্য ভূগর্ভস্থ লাইনের (টেলিফোন, জল, গ্যাস) মালিকদের জানান'));
    expect(_reject('locate', 'trench'), contains('অপ্রয়োজনীয় খোঁড়াখুঁড়ি'));
    expect(_reject('locate', 'alone'), contains('আলাদা প্রশিক্ষণ'));
    final all = [
      for (final s in pack.slots) ...[for (final o in s.options) ...[o.labelBn, o.rejectBn], for (final w in s.whyChips) w.textBn],
    ];
    expect(all.where((l) => l.contains('স্থানীয় কর্তৃপক্ষ')), isEmpty, reason: 'ruling M5-7: the owners, not "local authority"');
    expect(pack.earnedBn, allOf(contains('মেগারে'), contains('TDR')));
  });

  test('every picture exists (vector scenes from tool/m5_board59_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m5_board59 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .map((n) => '$_artDir/$n')
        .toSet();
    expect(onDisk, used, reason: 'no unused art, no stray files and no missing art');
  });

  // The step-13 review: a round-wide check misses a hand where the safe card
  // is the only one on its backdrop or the only one with a colour. So go
  // through EVERY hand the dealer can make (one safe card + any cards-1
  // traps; afterMiss hands are of the same shape).
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
        expect(body(safe.asset), isNot(contains('<text')), reason: '${safe.asset}: no words in the art');
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

  test('the careless lineman says the lesson\'s first myth, word for word', () {
    final m = pack.myth;
    final chapters = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync());
    Map<String, dynamic>? lesson;
    void walk(Object? o) {
      if (lesson != null) return;
      if (o is Map<String, dynamic>) {
        if (o['id'] == '5.9' && o['content'] is Map) {
          lesson = o;
          return;
        }
        o.values.forEach(walk);
      } else if (o is List) {
        o.forEach(walk);
      }
    }

    walk(chapters);
    expect(lesson, isNotNull, reason: 'lesson 5.9 in tool/all_training_chapters_bn.json');
    final myths = (lesson!['content']['myth_buster']['myths'] as List).cast<Map<String, dynamic>>();
    expect(m.rivalLineBn, myths.first['myth'], reason: 'the lesson\'s own words');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the lesson says: ভুল');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('আর্দ্রতা')), isTrue);
    expect(m.dangerHints, isNotEmpty);
  });

  test('rival lines: the parting line is recorded, the new ones are listed for the voice session', () {
    final m = pack.myth;
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M5Board59Lines.toRecord, [m.tauntBn, m.rivalLineBn]);
    for (final l in M5Board59Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: 'recorded clip for "$l" exists');
    }
  });

  group('board on screen', () {
    setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('board waits quietly at the first question (${reduce ? 'reduce' : 'anim'})', (tester) async {
        await _open(tester, reduce: reduce);
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final day = lessonDays[pack.lessonId];
        if (day != null) expect(find.text('দিন ${day.day}'), findsOneWidget, reason: 'a first play opens on the day card');
        // The playbook's settle: ~14 s after the guide's last line (the ask
        // ends ~7 s in), so his breath lap is over before measuring.
        for (var i = 0; i < 220; i++) {
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
        await _close(tester);
      });
    }
  });

  testWidgets('a clean play: five rounds with their reasons, the rival beaten, the clear saved', (t) async {
    await _open(t);
    await _playRounds(t, missFirst: false);
    await _beatRival(t);
    await _until(t, () => _save(t).rungProgress[_rung] == 'cleared', 'the clear to be saved');
    // The award finishes: the play's score and time are committed.
    await _until(t, () => _save(t).bestTimeMsByRung.containsKey(_rung), 'the play to be committed');
    await _pumpFor(t, 3000);
    final save = _save(t);
    expect(save.bestMarkByRung[_rung], 100, reason: 'every question right on the first try');
    expect(save.weakByLesson['5.9'] ?? const <String>[], isEmpty, reason: 'no weak spots after a clean play');
    expect(find.byType(LevelFailPanel), findsNothing);
    expect(t.takeException(), isNull);
    await _close(t);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('too many first-try misses fail the board (its strike-out): nothing cleared, the fail panel', (t) async {
    await _open(t);
    // One wrong picture in each of the five rounds: 7 of 12 clean = 58 %, under the 60 % pass line.
    await _playRounds(t, missFirst: true);
    await _beatRival(t);
    await _until(t, () => find.byType(LevelFailPanel).evaluate().isNotEmpty, 'the fail panel');
    final save = _save(t);
    expect(save.rungProgress[_rung], isNot('cleared'));
    expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
    expect(save.weakByLesson['5.9'], containsAll(['cause', 'short', 'earth', 'route', 'locate']),
        reason: 'every missed round is remembered as a weak spot');
    expect(t.takeException(), isNull);
    await _close(t);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('stuck on the pictures: a hand sweeps over the cards (how, never which); a touch hides it', (t) async {
    GestureHints.debugEnableInTests = true;
    addTearDown(() => GestureHints.debugEnableInTests = false);
    const hand = ValueKey('gesture-hint');
    await _open(t);
    final safe = [for (final o in pack.slots.first.options) if (o.correct) o.id];
    await _until(t, () => _dealt('pick', safe).evaluate().isNotEmpty, 'the first hand');
    expect(find.byKey(hand), findsNothing, reason: 'no hand before the player has had time');
    await _until(t, () => find.byKey(hand).evaluate().isNotEmpty, 'the idle hand', seconds: 20);
    final hint = t.state<IdleHintState>(find.ancestor(of: find.byKey(hand), matching: find.byType(IdleHint)).first);
    expect(hint.showing, isTrue);
    for (final o in pack.slots.first.options) {
      expect(find.text(o.labelBn), findsNothing, reason: 'the hand names no card');
    }
    await t.tapAt(const Offset(4, 800));
    await t.pump();
    expect(find.byKey(hand), findsNothing, reason: 'any touch hides it');
    await _close(t);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;

String _label(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).labelBn;
