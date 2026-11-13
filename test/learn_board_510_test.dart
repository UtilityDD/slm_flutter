// Module 5 lesson 5.10 picture board ("প্রিভেন্টিভ মেইনটেন্যান্স: গোয়েন্দা থেকে
// ডাক্তার", rung 5.10/learn, pack learn_5_10): its content follows the board's
// rules and the lesson's points, every picture exists and no colour or
// backdrop marks the safe card (in any hand the dealer can make), the rival's
// myth is the lesson's own, the board waits quietly once the first hand is
// dealt, a clean play (every round + its reason + the careless lineman's myth)
// is saved as a pass, and a run of misses brings up the lesson card and too
// many first-try misses fail the board (a Learn board never freezes or falls).
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
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack510;
const _rung = '5.10/learn';
const _artDir = 'assets/game/art/m5_board510';

/// Has read lesson 5.10 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['5_10', '5.10']));
}

void _muteAudio() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> ok(MethodCall _) async => 1;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), ok);
  }
}

/// The source spells য় ড় ঢ় as single letters; the app's text uses letter + nukta.
String _nukta(String s) =>
    s.replaceAll('\u09DF', '\u09AF\u09BC').replaceAll('\u09DC', '\u09A1\u09BC').replaceAll('\u09DD', '\u09A2\u09BC');

/// Lesson 5.10 as stored in the training text (read-only).
Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '5.10');
}

var _rebuilds = 0;

Finder get _cards => find.byWidgetPredicate((w) => w.runtimeType.toString() == '_AnimatedChoiceCard');

/// A dealt picture card whose option id passes [test].
Finder _pick(bool Function(String id) test) => find.byWidgetPredicate((w) {
      final k = w.key;
      return w.runtimeType.toString() == '_AnimatedChoiceCard' &&
          k is ValueKey<String> &&
          k.value.startsWith('pick-') &&
          test(k.value.split('-').skip(2).join('-'));
    });

Future<void> _pumpFor(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps until [finder] finds something (or fails after [maxMs]).
Future<void> _waitFor(WidgetTester t, Finder finder, {int maxMs = 40000, String? what}) async {
  for (var waited = 0; waited < maxMs; waited += 100) {
    if (finder.evaluate().isNotEmpty) return;
    await t.pump(const Duration(milliseconds: 100));
  }
  fail('timed out waiting for ${what ?? finder}');
}

/// Pumps (up to [maxMs]) until the gesture hint shows; false if it never does.
Future<bool> _hintShows(WidgetTester t, IdleHintState Function() hint, {int maxMs = 30000}) async {
  for (var waited = 0; waited < maxMs; waited += 100) {
    if (hint().showing) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return false;
}

Future<ProviderContainer> _open(WidgetTester t, {bool reduce = false}) async {
  t.view.physicalSize = const Size(720, 1600);
  t.view.devicePixelRatio = 2.0;
  t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
  SharedPreferences.setMockInitialValues({});
  LessonMissTally.resetAll();
  final c = ProviderContainer(overrides: [authProvider.overrideWith(_TestAuth.new)]);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      theme: SlmTheme.night(),
      home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.10', ladderIndex: 27, pack: pack, muted: true),
    ),
  ));
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.platformDispatcher.clearAccessibilityFeaturesTestValue();
  t.view.reset();
}

/// Taps a dealt trap of [slot] (any one in the hand).
Future<void> _tapTrap(WidgetTester t, LearnBoardSlot slot) async {
  final traps = {for (final o in slot.options) if (!o.correct) o.id};
  final trap = _pick(traps.contains).hitTestable();
  await _waitFor(t, trap, what: '${slot.id}: a trap in the hand');
  await _pumpFor(t, 1200); // the hand lands
  await pickBoardCard(t, trap);
  await _pumpFor(t, 300); // the redeal
}

/// Plays [slot]: the safe picture, then a right reason.
Future<void> _playRound(WidgetTester t, LearnBoardSlot slot) async {
  final safe = {for (final o in slot.options) if (o.correct) o.id};
  final card = _pick(safe.contains).hitTestable();
  await _waitFor(t, card, what: '${slot.id}: the safe card');
  await _pumpFor(t, 1200); // the hand lands
  await pickBoardCard(t, card);
  final right = find.byWidgetPredicate((w) =>
      w is Text && slot.whyChips.any((c) => c.correct && c.textBn == w.data)).hitTestable();
  await _waitFor(t, right, what: '${slot.id}: a right reason');
  await _pumpFor(t, 1200); // the reason cards slide in
  await pickBoardCard(t, right);
}

/// The careless lineman's myth: his lines play first, the ask waits for him;
/// then the right answer and a right reason.
Future<void> _playMyth(WidgetTester t) async {
  await _waitFor(t, find.text(M5Board510Lines.rivalTaunt), what: 'the rival\'s taunt');
  expect(find.text('হ্যাঁ'), findsNothing, reason: 'the ask waits for the careless lineman');
  expect(find.text('না'), findsNothing);
  await _waitFor(t, find.text(M5Board510Lines.rivalMyth), what: 'the rival\'s myth');
  expect(find.text('না'), findsNothing, reason: 'he cannot be skipped by tapping fast');
  final ask = find.byWidgetPredicate((w) => w is Text && (w.data == 'বিশ্বাস করেন?' || w.data == 'সেটা কি ভুল?'));
  await _waitFor(t, ask, what: 'the belief ask');
  await _waitFor(t, find.text('না').hitTestable());
  await _pumpFor(t, 1200);
  final flipped = find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  // The myth is wrong: "বিশ্বাস করেন?" → না; "সেটা কি ভুল?" → হ্যাঁ.
  await t.tap(find.text(flipped ? 'হ্যাঁ' : 'না'));
  await t.pump();
  final right = find.byWidgetPredicate((w) =>
      w is Text && pack.myth.whyChips.any((c) => c.correct && c.textBn == w.data)).hitTestable();
  await _waitFor(t, right, what: 'a right myth reason');
  await _pumpFor(t, 1200);
  await pickBoardCard(t, right);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(LearnDealer.resetMemory);

  test('the lesson 5.10 board with the lesson\'s rounds', () {
    final lesson = _lesson();
    expect(pack.lessonId, '5.10');
    // Registered by the director (learn_board_models.dart); until then null.
    expect(learnBoardPackFor('5.10'), same(learnBoardPack510));
    expect(pack.titleBn, _nukta(lesson['title'] as String));
    expect(pack.badgeBn, _nukta(lesson['badge_name'] as String));
    expect(pack.slots.map((s) => s.id), ['checklist', 'hidden', 'fixnow', 'record', 'report']);
    expect(pack.slots.length, 5, reason: 'ruling M5-11: boards trimmed to 5 rounds');
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
      expect(s.promptBn, isNot('সঠিক জিনিস বেছে নিন'), reason: '${s.id}: specific prompt');
      expect(s.cards, 4);
      expect(s.whyCards, 3);
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
    expect(pack.introBn, isNotEmpty);
    expect(pack.earnedBn, isNotEmpty);
  });

  test('every round: 4–6 pictures, two or more safe ones, three traps, each trap says why', () {
    final ids = <String>{};
    for (final s in pack.slots) {
      expect(s.options.length, inInclusiveRange(4, 6), reason: s.id);
      final safe = s.options.where((o) => o.correct).length;
      final traps = s.options.where((o) => !o.correct).length;
      expect(safe, greaterThanOrEqualTo(2), reason: '${s.id}: two pictures of the safe act, so its look cannot be learnt');
      expect(traps, s.cards - 1, reason: '${s.id}: every hand holds all three traps (the fairness check relies on it)');
      expect(s.options.map((o) => o.id).toSet().length, s.options.length, reason: '${s.id}: unique ids');
      expect(s.options.map((o) => o.asset).toSet().length, s.options.length, reason: '${s.id}: one picture per card');
      for (final o in s.options) {
        expect(ids.add(o.id), isTrue, reason: '${o.id}: card ids unique across the board');
        expect(o.scene, isTrue, reason: '${s.id}/${o.id}: drawn scene, edge to edge');
        expect(o.labelBn, isNotEmpty, reason: '${s.id}/${o.id}: a name for the tapped card');
        if (!o.correct) expect(o.rejectBn, isNotEmpty, reason: '${s.id}/${o.id}: a trap says why');
        if (o.correct) expect(o.rejectBn, isEmpty, reason: '${s.id}/${o.id}');
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
      // Ruling M5-13: clean Bangla on screen, never the source's stray scripts.
      // (the danda । is shared with Bangla, so it is allowed)
      expect(l, isNot(matches(RegExp('[\u0900-\u0963\u0966-\u097F\u0B80-\u0BFF]'))), reason: '"$l": no Devanagari/Tamil');
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
    expect(m.whyChips.map((w) => w.id).toSet().length, m.whyChips.length);
  });

  test('a dealt hand has exactly one safe picture, and plays differ', () {
    final d = LearnDealer(math.Random(7));
    for (final s in pack.slots) {
      final hands = <String>{};
      final safes = <String>{};
      for (var run = 0; run < 12; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        expect(hand, hasLength(s.cards), reason: s.id);
        expect(hand.where((p) => p.correct), hasLength(1), reason: s.id);
        hands.add(hand.map((o) => o.id).join(','));
        safes.add(hand.firstWhere((o) => o.correct).id);
      }
      expect(hands.length, greaterThan(1), reason: '${s.id}: fresh deals');
      expect(safes.length, greaterThan(1), reason: '${s.id}: the safe act shows in different pictures');
      // After a miss the hand still holds one safe card (a different picture).
      final hand = d.deal(s.id, s.options, count: s.cards);
      final trap = hand.firstWhere((o) => !o.correct);
      final next = d.afterMiss(hand, trap, s.options, {for (final o in hand) o.id});
      expect(next.where((o) => o.correct), hasLength(1), reason: s.id);
      expect(next.firstWhere((o) => o.correct).id, isNot(hand.firstWhere((o) => o.correct).id), reason: s.id);
      final why = d.deal('${s.id}/why', s.whyChips, count: s.whyCards);
      expect(why.where((c) => c.correct), hasLength(1), reason: '${s.id}: one right reason per deal');
      expect(why.map((c) => c.id).toSet(), hasLength(s.whyCards));
    }
  });

  test('the lesson\'s points: checklist, hidden joints, fix now, record, report', () {
    final text = _nukta(jsonEncode(_lesson()));
    // Checklist: visual check, earthing, trimming are the safe acts; cleaning alone is not PM.
    expect(_slot('checklist').options.where((o) => o.correct).map((o) => o.id), ['visual', 'earth', 'trim']);
    expect(_reject('checklist', 'wipe'), contains('পরিষ্কার করা PM-এর একটি অংশ মাত্র'));
    expect(_reject('checklist', 'branch'), contains('ডালপালা ছাঁটা'));
    expect(_reject('checklist', 'earthlead'), contains('আর্থিং কানেকশন পরীক্ষা'));
    expect(text, contains('সমস্ত আর্থিং কানেকশন পরীক্ষা করা'));
    // Hidden: a thermal scan finds loose joints; the hot joint is tightened, not left.
    expect(_slot('hidden').options.where((o) => o.correct).map((o) => o.id), ['scan', 'tighten']);
    expect(_reject('hidden', 'eyes'), contains('বাইরে থেকে বোঝা যায় না'));
    expect(_reject('hidden', 'later'), contains('বড় ব্রেকডাউনের জন্ম দেয়'));
    expect(text, contains('বড় ব্রেকডাউনের জন্ম দেয়'));
    expect(text, contains('থার্মাল ক্যামেরা দিয়ে সমস্ত কানেকশন'));
    // Fix now: pro tip 1 and the torque wrench of pro tip 3.
    expect(_reject('fixnow', 'leave'), contains('তখনই ঠিক করুন'));
    expect(text, contains('সেটিকে তখনই ঠিক করুন'));
    expect(_reject('fixnow', 'pipe'), contains('টর্ক রেঞ্চ'));
    expect(_reject('fixnow', 'half'), contains('দুটোই'));
    // Record: both the work and the abnormalities, in a logbook or an app.
    expect(_slot('record').options.where((o) => o.correct).map((o) => o.id), ['logbook', 'app']);
    expect(_reject('record', 'chat'), allOf(contains('লগবুকে'), contains('অ্যাপে')));
    expect(_reject('record', 'blank'), contains('দুটোই'));
    expect(text, contains('লগবুকে বা ডিজিটাল অ্যাপে'));
    // Report: noticing and reporting deterioration makes the lineman part of CBM.
    expect(_slot('report').promptBn, allOf(contains('তেলের রং'), contains('অস্বাভাবিক শব্দ')));
    expect(_reject('report', 'shrug'), contains('CBM'));
    expect(_reject('report', 'wait'), contains('যখন প্রয়োজন'));
    expect(text, contains('যখন প্রয়োজন, তখনই রক্ষণাবেক্ষণ'));
    expect(pack.earnedBn, contains('থার্মাল'));
  });

  test('every picture exists (vector scenes from tool/m5_board510_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m5_board510 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .map((n) => '$_artDir/$n')
        .toSet();
    expect(onDisk, used, reason: 'no unused art, no stray files and no missing art');
  });

  // The playbook (section 4): the right option must not stand out. A round
  // shares one backdrop and one palette; every gradient and colour drawn on a
  // safe card must also be drawn on at least one trap.
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

  // Every hand the dealer can make (one safe card + cards-1 traps; afterMiss
  // hands are of the same shape): the safe card's backdrop and colours are on
  // a trap in that hand too.
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

  // Review fix: the safe 'nut' card once showed the rusted clamp still on the
  // pole — the very state the 'half' trap punishes. Only the traps that walk
  // away from the clamp (leave, half) may show the rusted pole band.
  test('fix now: only the traps leave the rusted clamp on the pole', () {
    final rustyBand = RegExp(r'<rect x="32" y="142" width="34" height="16" rx="3" fill="#9A5A2A"');
    for (final o in _slot('fixnow').options) {
      final body = File(o.asset).readAsStringSync().split('</defs>').last;
      expect(rustyBand.hasMatch(body), ['leave', 'half'].contains(o.id), reason: '${o.id}: rusted clamp left on the pole');
    }
  });

  test('the careless lineman says the lesson\'s first myth, word for word', () {
    final m = pack.myth;
    final myths = ((_lesson()['content'] as Map)['myth_buster'] as Map)['myths'] as List;
    expect(m.rivalLineBn, _nukta((myths.first as Map)['myth'] as String));
    expect(m.believeNoIsCorrect, isTrue, reason: 'the reality: hidden problems grow; PM finds them');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('বাইরে থেকে বোঝা যায় না')), isTrue);
    expect(m.whyChips.any((w) => !w.correct && w.textBn.contains('পরিষ্কার')), isTrue, reason: 'myth 2 as a wrong reason');
    expect(m.dangerHints, isNotEmpty);
    expect(m.tauntBn, M5Board510Lines.rivalTaunt);
    expect(m.exitBn, M5Board510Lines.rivalExit);
  });

  test('rival lines: the exit has his clip; the new lines are listed for recording', () {
    final m = pack.myth;
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M5Board510Lines.recorded, [m.tauntBn, m.rivalLineBn]);
    // Until the director records them they stay silent (never the device voice);
    // once recorded, the clip must be on disk.
    for (final l in M5Board510Lines.recorded) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  group('board on screen', () {
    setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('board waits quietly at the first question (${reduce ? 'reduce' : 'anim'})', (tester) async {
        final c = await _open(tester, reduce: reduce);
        // The intro, the deal and the ask, then the mascot's last breath lap.
        await _pumpFor(tester, 26000);
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
        await _close(tester, c);
      });
    }
  });

  group('playing the board', () {
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

    testWidgets('a clean play: every round and its reason, then the careless lineman — saved as a pass', (tester) async {
      final c = await _open(tester);
      for (final s in pack.slots) {
        await _playRound(tester, s);
      }
      await _playMyth(tester);
      for (var waited = 0; waited < 30000; waited += 100) {
        if (c.read(gameSaveProvider).rungProgress[_rung] == 'cleared') break;
        await tester.pump(const Duration(milliseconds: 100));
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.bestMarkByRung[_rung], 100, reason: 'every question right on the first try');
      expect(find.byType(LevelFailPanel), findsNothing);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });

    testWidgets('stuck on a pick: a hand sweeps over every card, pressing none', (tester) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(tester);
      // The hint around the cards on screen now (the stage may still hold an outgoing board).
      IdleHintState hint() =>
          tester.state<IdleHintState>(find.ancestor(of: _cards.hitTestable().first, matching: find.byType(IdleHint)).first);
      await _waitFor(tester, _pick((_) => true).hitTestable(), what: 'the first hand');
      expect(await _hintShows(tester, hint), isTrue, reason: 'stuck at the pick: the hand shows');
      expect(hint().debugOptions, hasLength(pack.slots.first.cards), reason: 'a sweep over all four pictures, never one');
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 120));
        final f = hint().debugFrame;
        if (f != null) expect(f.press, 0, reason: 'a sweep never presses a card');
      }
      // (The reason deck's sweep is the kit's; after a right pick it does not arm
      // yet — reported to the director: its `waiting` is read while the beat is
      // still locked and nothing rebuilds when it unlocks.)
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });

    testWidgets('three misses in a row bring up the lesson card; a wrong card never freezes the board', (tester) async {
      final c = await _open(tester);
      final first = pack.slots.first;
      await _tapTrap(tester, first);
      // A wrong card: shake, redeal and the reason — never the "কেন" deck, never a freeze or a fall.
      for (final w in first.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: w.textBn);
      }
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a Learn board has no deadly freeze');
      expect(find.text('এখন না'), findsNothing, reason: 'one miss: no lesson card yet');
      await _tapTrap(tester, first);
      await _tapTrap(tester, first);
      await _waitFor(tester, find.text('এখন না'), maxMs: 20000, what: 'the lesson card after three misses');
      expect(c.read(gameSaveProvider).rungProgress[_rung], isNot('cleared'));
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });

    testWidgets('too many first-try misses fail the board: nothing is cleared', (tester) async {
      final c = await _open(tester);
      // A first-try miss on all five rounds: 7 of 12 questions clean (58 %) < the 60 % pass line.
      for (final s in pack.slots) {
        await _tapTrap(tester, s);
        await _playRound(tester, s);
      }
      await _playMyth(tester);
      await _waitFor(tester, find.byType(LevelFailPanel), maxMs: 30000, what: 'the fail panel');
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress[_rung], isNot('cleared'));
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;
