// Module 5 lesson 5.4 picture board ("ফিউজ বারবার উড়ে যাওয়ার কারণ: অস্থায়ী
// বনাম স্থায়ী ফল্ট", rung 5.4/learn, pack learn_5_4): its content follows the
// board's rules and the lesson's points, every picture exists and no colour or
// backdrop marks the safe card in any hand the dealer can make (counting only
// shapes that can be seen), the rival's myth is the lesson's own, the board waits
// quietly once the first hand is dealt, a stuck player gets a sweeping hand that
// presses no card, a clean play (every reason and the coworker's myth) clears the
// rung, three misses in a row bring the lesson card up, and a play with a miss on
// every round fails below the pass line.
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
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack54;
const _artDir = 'assets/game/art/m5_board54';
const _rung = '5.4/learn';

/// Has read lesson 5.4 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['5_4', '5.4']));
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

/// A dealt card (`pick-<wave>-<id>` / `why-<wave>-<id>`) whose id is in [ids].
Finder _card(String kind, Set<String> ids) => find.byWidgetPredicate((w) {
      final k = w.key;
      if (w.runtimeType.toString() != '_AnimatedChoiceCard' || k is! ValueKey<String>) return false;
      final parts = k.value.split('-');
      return parts.length >= 3 && parts.first == kind && ids.contains(parts.skip(2).join('-'));
    });

Future<void> _open(WidgetTester tester, {bool reduce = false}) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2.0;
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith(_TestAuth.new)],
    child: MaterialApp(
      theme: SlmTheme.night(),
      home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.4', ladderIndex: 0, pack: pack, muted: true),
    ),
  ));
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  tester.view.reset();
}

/// Pumps in 100 ms steps until [done] (fails after [seconds] of game time).
Future<void> _until(WidgetTester tester, bool Function() done, String what, {int seconds = 60}) async {
  for (var i = 0; i < seconds * 10; i++) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('timed out waiting for $what');
}

/// Taps the first card in [f] until [done] (taps while the board is busy are ignored).
Future<void> _tapUntil(WidgetTester tester, Finder f, bool Function() done, String what, {int seconds = 60}) async {
  for (var i = 0; i < seconds * 4; i++) {
    if (done()) return;
    await tryPickBoardCard(tester, f);
    for (var k = 0; k < 3; k++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }
  final keys = [for (final e in _cards.evaluate()) (e.widget.key as ValueKey<String>?)?.value];
  final texts = [for (final e in find.byType(Text).evaluate()) (e.widget as Text).data].whereType<String>().toList();
  fail('timed out tapping for $what; cards $keys; texts $texts');
}

/// Taps a trap until the board takes it (a tap during a scripted beat is
/// ignored) and its reason comes up; one accepted tap = one miss.
Future<void> _missOnce(WidgetTester tester, Finder trap, String reject, String what) async {
  bool shown() => find.textContaining(reject).evaluate().isNotEmpty;
  var taken = false;
  for (var tries = 0; tries < 12 && !taken; tries++) {
    taken = await tryTapBoardCard(tester, trap);
    if (!taken) await tester.pump(const Duration(milliseconds: 300));
  }
  for (var i = 0; i < 60 && !shown(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(shown(), isTrue, reason: "$what: the trap's reason");
  await continueBoard(tester);
}

Set<String> _ids(Iterable<LearnPick> xs, {required bool correct}) => {for (final x in xs) if (x.correct == correct) x.id};

/// Plays round [s]: optionally one trap first (and waits for its reason), then the
/// safe card, then the right reason.
Future<void> _playRound(WidgetTester tester, LearnBoardSlot s, {required bool missFirst, required Finder next}) async {
  final safe = _card('pick', _ids(s.options, correct: true));
  final whyRight = _card('why', _ids(s.whyChips, correct: true));
  final anyWhy = _card('why', {for (final w in s.whyChips) w.id});
  await _until(tester, () => safe.evaluate().isNotEmpty && anyWhy.evaluate().isEmpty && find.text(s.promptBn).evaluate().isNotEmpty,
      '${s.id} hand');
  if (missFirst) {
    final trap = _card('pick', _ids(s.options, correct: false));
    expect(trap, findsAtLeastNWidgets(1), reason: '${s.id}: a hand holds traps');
    final id = ((trap.evaluate().first.widget.key! as ValueKey<String>).value.split('-').skip(2).join('-'));
    final reject = s.options.firstWhere((o) => o.id == id).rejectBn;
    // The mistake teaches: the trap's own reason comes up in the guide's bubble.
    await _missOnce(tester, trap.first, reject, '${s.id}/$id');
    for (final w in s.whyChips) {
      expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the "why" deck');
    }
  }
  await _tapUntil(tester, safe, () => anyWhy.evaluate().isNotEmpty, '${s.id} safe card');
  await _tapUntil(tester, whyRight, () => next.evaluate().isNotEmpty, '${s.id} reason');
}

/// Plays the whole board; [missFirst] taps one trap on every round first.
Future<void> _playBoard(WidgetTester tester, {required bool missFirst}) async {
  for (var i = 0; i < pack.slots.length; i++) {
    final s = pack.slots[i];
    final next = i + 1 < pack.slots.length
        ? _card('pick', {for (final o in pack.slots[i + 1].options) o.id})
        : find.byWidgetPredicate((w) =>
            w is Text && (w.data == M5Board54Lines.rivalTaunt || w.data == M5Board54Lines.rivalMyth));
    await _playRound(tester, s, missFirst: missFirst, next: next);
  }
  // The coworker's myth: he storms in, says it in his own voice, leaves; the
  // question waits for him (no answer before the guide asks), and fast taps
  // where the answer buttons will stand cannot skip him.
  await _until(tester, () => find.text(M5Board54Lines.rivalMyth).evaluate().isNotEmpty, 'the rival\'s myth', seconds: 90);
  expect(find.text('হ্যাঁ'), findsNothing, reason: 'no answer while he is still talking');
  expect(find.text('না'), findsNothing, reason: 'no answer while he is still talking');
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  final mythWhy = _card('why', {for (final w in pack.myth.whyChips) w.id});
  var sawExit = false;
  for (var i = 0; i < 600 && find.text('না').evaluate().isEmpty; i++) {
    if (find.text(M5Board54Lines.rivalMyth).evaluate().isNotEmpty || find.text(M5Board54Lines.rivalExit).evaluate().isNotEmpty) {
      expect(find.text('হ্যাঁ'), findsNothing, reason: 'no answer while he is on stage');
      if (i.isEven) {
        // Where হ্যাঁ / না will stand (bottom row) and the middle of the stage.
        for (final p in [Offset(size.width * 0.27, size.height - 60), Offset(size.width * 0.73, size.height - 60), size.center(Offset.zero)]) {
          await tester.tapAt(p);
        }
      }
    }
    sawExit = sawExit || find.text(M5Board54Lines.rivalExit).evaluate().isNotEmpty;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(sawExit, isTrue, reason: 'he says his parting line before the question comes up');
  expect(find.text('না'), findsOneWidget, reason: 'the believe question');
  expect(mythWhy, findsNothing, reason: 'taps during his lines answered nothing');
  final flipped = find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  final refuse = find.text(flipped ? 'হ্যাঁ' : 'না');
  await _tapUntil(tester, refuse, () => mythWhy.evaluate().isNotEmpty, 'refusing the myth');
  final mythRight = _card('why', _ids(pack.myth.whyChips, correct: true));
  await _tapUntil(tester, mythRight, () => mythWhy.evaluate().isEmpty, 'the myth reason');
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

  test('the lesson 5.4 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '5.4');
    // Registered by the director (learn_board_models.dart); until then null.
    expect(learnBoardPackFor('5.4'), same(learnBoardPack54));
    expect(pack.badgeBn, 'ফল্ট ফাইন্ডার');
    expect(pack.titleBn, 'ফিউজ বারবার উড়ে যাওয়ার কারণ: অস্থায়ী বনাম স্থায়ী ফল্ট');
    expect(pack.slots.map((s) => s.id), ['where', 'transient', 'blast', 'reblow', 'section']);
    expect(pack.slots.length, 5, reason: 'Module 5 boards are trimmed to 5 rounds (ruling M5-11)');
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
      // Clean Bangla only (ruling M5-13): no stray Devanagari (the danda । is shared), Cyrillic, Tamil, Hangul or Arabic.
      expect(l, isNot(matches(RegExp('[ऀ-ॣ०-ॿЀ-ӿ஀-௿가-힯؀-ۿ]'))), reason: '"$l": clean Bangla');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স', 'সেফটি বেল্ট']) {
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
      for (var run = 0; run < 12; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        expect(hand, hasLength(s.cards), reason: s.id);
        expect(hand.where((p) => p.correct), hasLength(1), reason: s.id);
        hands.add((hand.map((o) => o.id).toList()..sort()).join(','));
      }
      expect(hands.length, greaterThan(1), reason: '${s.id}: fresh deals');
    }
  });

  test('the lesson\'s points: where, transient, blast with arc, a later re-blow, sectionalizing', () {
    // Where: HT line before the DTR, inside the DTR, or the LT side — never "HT only" (myth 2).
    expect(_safe('where'), {'htline', 'tank', 'lt'});
    expect(_reject('where', 'htonly'), contains('এলটি শর্ট সার্কিটও'));
    expect(_reject('where', 'thick'), allOf(contains('মোটা তার'), contains('ডায়াগনস্টিক টুল')));
    expect(_reject('where', 'burn'), allOf(contains('Fault Burning'), contains('কঠোরভাবে নিষিদ্ধ')));
    // Transient: lightning, clashing conductors, a bird; snapped wire, broken insulator, DTR inside are permanent.
    expect(_safe('transient'), {'lightning', 'clash', 'bird'});
    for (final id in ['snapped', 'insulator', 'smoke']) {
      expect(_reject('transient', id), contains('স্থায়ী ফল্ট'), reason: id);
    }
    expect(_slot('transient').whyChips.any((w) => w.correct && w.textBn.contains('80-90%')), isTrue);
    // Blast with arc at once: charging again is the lesson's মারাত্মক ভুল (ruling M5-1); patrol and repair.
    expect(_safe('blast'), {'patrol', 'repair'});
    expect(_reject('blast', 'reclose'), contains('মারাত্মক ভুল'));
    expect(_reject('blast', 'wait'), contains('পেট্রোলিং'));
    // A re-blow after hours: history, weather, sagging spans, branches; never re-fit blind.
    expect(_safe('reblow'), {'sag', 'branch', 'log'});
    expect(_reject('reblow', 'refit'), contains('নিশ্চিত না হয়ে'));
    expect(_reject('reblow', 'leave'), allOf(contains('ইতিহাস'), contains('আবহাওয়া')));
    expect(_reject('reblow', 'burn'), contains('Fault Burning'));
    // Sectionalizing: all LT out, HT in, LT back one at a time, megger after; the roar is a danger sign.
    expect(_safe('section'), {'ltout', 'onebyone', 'megger'});
    expect(_reject('section', 'roar'), allOf(contains('সমস্ত আউটগোয়িং'), contains('বিপদের সংকেত')));
    expect(_reject('section', 'allback'), contains('একটি একটি করে'));
    expect(_reject('section', 'guess'), contains('ধৈর্যের কাজ'));
    expect(pack.earnedBn, allOf(contains('স্থায়ী ফল্ট'), contains('সেকশনালাইজিং')));
  });

  test('every picture exists (vector scenes from tool/m5_board54_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, '$_artDir/${s.id}_${o.id}.svg', reason: 'a card is named after its round and id');
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m5_board54 folder is a card on the board', () {
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

  test('the fairness check counts only what can be seen', () {
    const fake = '<svg viewBox="0 0 200 220"><defs><rect width="9" height="9" fill="#ABCDEF"/></defs>'
        '<rect width="0" height="0" fill="#123456"/>'
        '<path d="M0 0 L5 5" stroke="#334455" opacity="0"/>'
        '<g display="none"><rect width="4" height="4" fill="#222222"/></g>'
        '<g transform="translate(10 10) scale(0)"><rect width="40" height="40" fill="#444444"/></g>'
        '<rect x="300" y="10" width="20" height="20" fill="#555555"/>'
        '<g transform="translate(200 0) scale(-1 1)"><rect x="20" y="20" width="4" height="4" fill="#696969"/></g>'
        '<rect width="4" height="4" fill="#778899"/></svg>';
    expect(_visibleTokens(fake), {'#696969', '#778899'}, reason: 'a mirrored figure still counts');
  });

  test('the cards use no paint the fairness check cannot follow', () {
    for (final f in Directory(_artDir).listSync().whereType<File>().where((f) => f.path.endsWith('.svg'))) {
      final svg = f.readAsStringSync();
      final clips = RegExp(r'clip-path="([^"]*)"').allMatches(svg).map((m) => m.group(1)).toSet()..remove('url(#card)');
      expect(clips, isEmpty, reason: '${f.path}: only the card\'s own clip');
      expect(RegExp(r'\b(mask|filter)="|<use\b|<image\b|<foreignObject\b').hasMatch(svg), isFalse,
          reason: '${f.path}: no mask, filter, reused shape or image');
      expect(svg, isNot(contains('<text')), reason: '${f.path}: no words in the art');
      expect(svg, isNot(contains('Glow')), reason: '${f.path}: no highlight glow');
    }
  });

  test('in every possible hand, the safe card\'s backdrop and colours are on a trap too', () {
    final backdrop = RegExp(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"');
    final svgs = <String, String>{};
    String body(String asset) => svgs.putIfAbsent(asset, () => File(asset).readAsStringSync());
    Set<String> tokens(String asset) => _visibleTokens(body(asset));
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

  test('the careless lineman says the lesson\'s first myth, word for word', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'লাইনটা কয়েকবার চার্জ করে দেখলেই ফল্টটা জ্বলে গিয়ে নিজে থেকেই ঠিক হয়ে যাবে।');
    expect(m.believeNoIsCorrect, isTrue, reason: "'Fault Burning' is strictly forbidden");
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('Fault Burning')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded; the new ones are listed for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M5Board54Lines.toRecord, containsAll([m.tauntBn, m.rivalLineBn]));
    for (final line in M5Board54Lines.toRecord) {
      final c = LearnVoice.resolve(line, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: 'a registered clip exists: $c');
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
        await _close(tester);
      });
    }
  });

  testWidgets('stuck on the pick: a hand sweeps over the cards and presses none', (tester) async {
    GestureHints.debugEnableInTests = true;
    addTearDown(() => GestureHints.debugEnableInTests = false);
    await _open(tester);
    final hint = find.byKey(const ValueKey('gesture-hint'));
    await _until(tester, () => find.text(pack.slots.first.promptBn).evaluate().isNotEmpty && _cards.evaluate().length == 4, 'the first hand');
    expect(hint, findsNothing, reason: 'no hand while the player has just been asked');
    await _until(tester, () => hint.evaluate().isNotEmpty, 'the idle hand', seconds: 14);
    // A sweep never picks: nothing was chosen, so the "why" deck has not opened.
    for (final w in pack.slots.first.whyChips) {
      expect(find.text(w.textBn), findsNothing);
    }
    expect(_cards, findsNWidgets(pack.slots.first.cards));
    await _close(tester);
  });

  testWidgets('a clean play — every reason and the coworker\'s myth — clears the rung', (tester) async {
    await _open(tester);
    await _playBoard(tester, missFirst: false);
    final c = ProviderScope.containerOf(tester.element(find.byType(LearnBoardRunnerPage)));
    await _until(tester, () => c.read(gameSaveProvider).rungProgress[_rung] == 'cleared', 'the rung cleared');
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets('three misses in a row bring the lesson card up', (tester) async {
    await _open(tester);
    final s = pack.slots.first;
    final traps = _ids(s.options, correct: false);
    final anyTrap = _card('pick', traps);
    await _until(tester, () => anyTrap.evaluate().isNotEmpty && find.text(s.promptBn).evaluate().isNotEmpty, 'the first hand');
    // A hand of this round holds all its traps, so a redeal keeps the one just
    // missed (its reason still in the bubble): each miss taps a different trap,
    // so every tap counted is seen by its own fresh reason.
    String? lastId;
    String rejectOf(String id) => s.options.firstWhere((o) => o.id == id).rejectBn;
    for (var miss = 0; miss < 3; miss++) {
      // Not the trap just missed, and none whose reason is still on screen.
      final fresh = {
        for (final id in traps)
          if (id != lastId && find.textContaining(rejectOf(id)).evaluate().isEmpty) id,
      };
      expect(fresh, isNotEmpty, reason: 'miss ${miss + 1}: a trap whose reason is not up');
      final trap = _card('pick', fresh);
      await _until(tester, () => trap.evaluate().isNotEmpty, 'a fresh trap in the hand');
      final id = (trap.evaluate().first.widget.key! as ValueKey<String>).value.split('-').skip(2).join('-');
      await _missOnce(tester, trap.first, rejectOf(id), 'miss ${miss + 1}');
      lastId = id;
      await _until(tester, () => anyTrap.evaluate().isNotEmpty, 'the redealt hand');
      await tester.pump(const Duration(milliseconds: 700));
    }
    await _until(tester, () => find.text('এখন না').evaluate().isNotEmpty, 'the lesson card');
    final c = ProviderScope.containerOf(tester.element(find.byType(LearnBoardRunnerPage)));
    expect(c.read(gameSaveProvider).rungProgress[_rung], isNot('cleared'));
    await _close(tester);
  });

  testWidgets('a miss on every round fails below the pass line and clears nothing', (tester) async {
    await _open(tester);
    await _playBoard(tester, missFirst: true);
    await _until(tester, () => find.text('আবার খেলুন').evaluate().isNotEmpty, 'the fail panel');
    final c = ProviderScope.containerOf(tester.element(find.byType(LearnBoardRunnerPage)));
    expect(c.read(gameSaveProvider).rungProgress[_rung], isNot('cleared'));
    expect(tester.takeException(), isNull);
    await _close(tester);
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

Set<String> _safe(String slot) => {for (final o in _slot(slot).options) if (o.correct) o.id};

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;

final _elem = RegExp(r'<(/?)([\w:]+)\b([^>]*?)(/?)>');
final _attr = RegExp(r'([\w:-]+)="([^"]*)"');
final _token = RegExp(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b');
final _numRe = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
final _xform = RegExp(r'(matrix|translate|scale|rotate|skewX|skewY)\s*\(([^)]*)\)');
final _pathTok = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
// Containers paint nothing themselves; definitions are never painted where they stand.
const _noPaint = {'g', 'svg', 'a', 'switch'};
const _defs = {'defs', 'clipPath', 'mask', 'pattern', 'symbol', 'marker', 'linearGradient', 'radialGradient', 'filter'};
const _inherit = ['fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width', 'visibility'];
const _identity = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0];

double _num(String? v, [double fallback = 1]) {
  if (v == null) return fallback;
  final s = v.trim();
  if (s.endsWith('%')) {
    final p = double.tryParse(s.substring(0, s.length - 1));
    return p == null ? fallback : p / 100;
  }
  return double.tryParse(s) ?? fallback;
}

List<double> _nums(String s) => [for (final m in _numRe.allMatches(s)) double.parse(m.group(0)!)];

Map<String, String> _attrs(String raw) {
  final a = {for (final x in _attr.allMatches(raw)) x.group(1)!: x.group(2)!};
  final style = a.remove('style');
  if (style != null) {
    for (final part in style.split(';')) {
      final i = part.indexOf(':');
      if (i > 0) a[part.substring(0, i).trim()] = part.substring(i + 1).trim();
    }
  }
  return a;
}

List<double> _mul(List<double> m, List<double> n) => [
      m[0] * n[0] + m[2] * n[1],
      m[1] * n[0] + m[3] * n[1],
      m[0] * n[2] + m[2] * n[3],
      m[1] * n[2] + m[3] * n[3],
      m[0] * n[4] + m[2] * n[5] + m[4],
      m[1] * n[4] + m[3] * n[5] + m[5],
    ];

List<double> _transform(String? text) {
  var m = _identity;
  for (final f in _xform.allMatches(text ?? '')) {
    final v = _nums(f.group(2)!);
    List<double>? t;
    switch (f.group(1)) {
      case 'matrix' when v.length == 6:
        t = v;
      case 'translate' when v.isNotEmpty:
        t = [1, 0, 0, 1, v[0], v.length > 1 ? v[1] : 0];
      case 'scale' when v.isNotEmpty:
        t = [v[0], 0, 0, v.length > 1 ? v[1] : v[0], 0, 0];
      case 'rotate' when v.isNotEmpty:
        final r = v[0] * math.pi / 180;
        t = [math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0];
        if (v.length >= 3) t = _mul(_mul([1, 0, 0, 1, v[1], v[2]], t), [1, 0, 0, 1, -v[1], -v[2]]);
      case 'skewX' when v.isNotEmpty:
        t = [1, 0, math.tan(v[0] * math.pi / 180), 1, 0, 0];
      case 'skewY' when v.isNotEmpty:
        t = [1, math.tan(v[0] * math.pi / 180), 0, 1, 0, 0];
    }
    if (t != null) m = _mul(m, t);
  }
  return m;
}

/// Points whose box holds the whole path (ends and control points; an arc adds a
/// box of its size around its ends), or null when the path can't be read.
List<(double, double)>? _pathPoints(String d) {
  const arity = {'m': 2, 'l': 2, 'h': 1, 'v': 1, 'c': 6, 's': 4, 'q': 4, 't': 2, 'a': 7, 'z': 0};
  final toks = [for (final m in _pathTok.allMatches(d)) m.group(0)!];
  final pts = <(double, double)>[];
  String? cmd;
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  (double, double)? lastC;
  var i = 0;
  while (i < toks.length) {
    if (RegExp(r'^[A-Za-z]$').hasMatch(toks[i])) {
      cmd = toks[i++];
      if (cmd == 'z' || cmd == 'Z') {
        x = sx;
        y = sy;
        pts.add((x, y));
        lastC = null;
        continue;
      }
    }
    if (cmd == null) return null;
    final c = cmd.toLowerCase();
    final n = arity[c]!;
    if (i + n > toks.length) return null;
    final v = <double>[];
    for (final t in toks.sublist(i, i + n)) {
      final p = double.tryParse(t);
      if (p == null) return null;
      v.add(p);
    }
    i += n;
    final rel = cmd != cmd.toUpperCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    if (c == 'h') {
      x = v[0] + ox;
      pts.add((x, y));
      lastC = null;
    } else if (c == 'v') {
      y = v[0] + oy;
      pts.add((x, y));
      lastC = null;
    } else if (c == 'a') {
      final ex = v[5] + ox, ey = v[6] + oy;
      final r = 2 * [v[0].abs(), v[1].abs(), math.sqrt((ex - x) * (ex - x) + (ey - y) * (ey - y))].reduce(math.max);
      pts.addAll([(x - r, y - r), (x + r, y + r), (ex, ey)]);
      x = ex;
      y = ey;
      lastC = null;
    } else {
      final ctrl = [for (var k = 0; k < n; k += 2) (v[k] + ox, v[k + 1] + oy)];
      if (c == 's' || c == 't') ctrl.insert(0, lastC == null ? (x, y) : (2 * x - lastC.$1, 2 * y - lastC.$2));
      pts.addAll(ctrl);
      lastC = ctrl.length > 1 ? ctrl[ctrl.length - 2] : null;
      (x, y) = ctrl.last;
      if (c == 'm') {
        sx = x;
        sy = y;
        cmd = rel ? 'l' : 'L';
      }
    }
  }
  return pts.isEmpty ? null : pts;
}

List<(double, double)>? _localPoints(String tag, Map<String, String> a) {
  double n(String k) => _num(a[k], 0);
  switch (tag) {
    case 'rect':
      return [(n('x'), n('y')), (n('x') + n('width'), n('y') + n('height'))];
    case 'circle':
      return [(n('cx') - n('r'), n('cy') - n('r')), (n('cx') + n('r'), n('cy') + n('r'))];
    case 'ellipse':
      return [(n('cx') - n('rx'), n('cy') - n('ry')), (n('cx') + n('rx'), n('cy') + n('ry'))];
    case 'line':
      return [(n('x1'), n('y1')), (n('x2'), n('y2'))];
    case 'polygon' || 'polyline':
      final v = _nums(a['points'] ?? '');
      return v.length < 2 ? null : [for (var k = 0; k + 1 < v.length; k += 2) (v[k], v[k + 1])];
    case 'path':
      return _pathPoints(a['d'] ?? '');
  }
  return null; // text and the rest: can't place it, so it counts
}

/// The colours and gradients an SVG card really paints on its 200 x 220 face
/// (mirrors `painted` / `tokens` in tool/scan_board_art.py). Skipped: definitions;
/// anything with display:none, visibility:hidden or opacity 0 on itself or on any
/// ancestor group; a transform that squashes it flat (scale(0)); zero-size shapes;
/// no fill and no stroke; a shape wholly off the card.
Set<String> _visibleTokens(String svg) {
  final vbMatch = RegExp(r'<svg\b[^>]*viewBox="([^"]*)"').firstMatch(svg);
  final vb = vbMatch == null ? <double>[] : _nums(vbMatch.group(1)!);
  final (x0, y0, cw, ch) = vb.length == 4 ? (vb[0], vb[1], vb[2], vb[3]) : (0.0, 0.0, 200.0, 220.0);
  final stack = <(String, bool, bool, Map<String, String>, List<double>)>[('#doc', false, false, {}, _identity)];
  final out = <String>{};
  for (final e in _elem.allMatches(svg)) {
    final tag = e.group(2)!;
    if (e.group(1)!.isNotEmpty) {
      for (var k = stack.length - 1; k > 0; k--) {
        if (stack[k].$1 == tag) {
          stack.removeRange(k, stack.length);
          break;
        }
      }
      continue;
    }
    final (_, pHidden, pDefs, pInh, pM) = stack.last;
    final own = _attrs(e.group(3)!);
    final inh = {...pInh, for (final k in _inherit) if (own.containsKey(k)) k: own[k]!};
    final m = _mul(pM, _transform(own['transform']));
    final inDefs = pDefs || _defs.contains(tag);
    final hidden = pHidden || own['display'] == 'none' || _num(own['opacity']) <= 0 || (m[0] * m[3] - m[1] * m[2]).abs() < 1e-9;
    if (e.group(4)!.isEmpty && !e.group(3)!.trimRight().endsWith('/')) stack.add((tag, hidden, inDefs, inh, m));
    if (inDefs || hidden || _noPaint.contains(tag) || inh['visibility'] == 'hidden' || inh['visibility'] == 'collapse') continue;
    final a = {...own, ...inh};
    var fillOn = a['fill'] != 'none' && _num(a['fill-opacity']) > 0;
    final strokeOn = a['stroke'] != null && a['stroke'] != 'none' && _num(a['stroke-opacity']) > 0 && _num(a['stroke-width']) > 0;
    if (tag == 'line') fillOn = false;
    if (!fillOn && !strokeOn) continue;
    if (tag == 'rect' && (_num(a['width'], 0) <= 0 || _num(a['height'], 0) <= 0)) continue;
    if (tag == 'circle' && _num(a['r'], 0) <= 0) continue;
    if (tag == 'ellipse' && (_num(a['rx'], 0) <= 0 || _num(a['ry'], 0) <= 0)) continue;
    if ((tag == 'path' || tag == 'polygon' || tag == 'polyline') && (a['d'] ?? a['points'] ?? '').isEmpty) continue;
    if (tag == 'line' && a['x1'] == a['x2'] && a['y1'] == a['y2']) continue;
    final pts = _localPoints(tag, a);
    if (pts != null) {
      final pad = strokeOn ? 2 * _num(a['stroke-width']) : 0.0; // miter joins reach 2 x width
      final xs = pts.map((p) => p.$1), ys = pts.map((p) => p.$2);
      final lx = xs.reduce(math.min) - pad, hx = xs.reduce(math.max) + pad;
      final ly = ys.reduce(math.min) - pad, hy = ys.reduce(math.max) + pad;
      final box = [(lx, ly), (hx, ly), (lx, hy), (hx, hy)];
      final tx = [for (final (px, py) in box) m[0] * px + m[2] * py + m[4]];
      final ty = [for (final (px, py) in box) m[1] * px + m[3] * py + m[5]];
      if (tx.reduce(math.max) <= x0 || tx.reduce(math.min) >= x0 + cw || ty.reduce(math.max) <= y0 || ty.reduce(math.min) >= y0 + ch) continue;
    }
    if (fillOn && a['fill'] != null) out.addAll(_token.allMatches(a['fill']!).map((t) => t.group(0)!));
    if (strokeOn) out.addAll(_token.allMatches(a['stroke']!).map((t) => t.group(0)!));
  }
  return out;
}
