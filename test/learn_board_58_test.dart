// Module 5 lesson 5.8 picture board ("ট্রান্সফরমারের সাধারণ সমস্যা: হৃৎপিণ্ডের
// রোগ নির্ণয়", rung 5.8/learn, pack learn_5_8): its content follows the
// board's rules, the lesson's points and the Module 5 rulings, every picture
// exists and no colour or backdrop marks the safe card (in any hand the dealer
// can make), the rival's myth is the lesson's own and his new lines are
// listed for recording, the board waits quietly once the first hand is dealt,
// a clean play clears the rung (picks, reasons and the coworker's myth) and a
// careless play fails below the pass mark.
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
import 'package:slm_flutter/features/game/learn_board_deal.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack58;
const _artDir = 'assets/game/art/m5_board58';
const _rung = '5.8/learn';

/// Has read lesson 5.8 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['5_8', '5.8']));
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

/// A dealt card on screen (key `pick-WAVE-ID` / `why-WAVE-ID`) whose id
/// is in [ids].
Finder _dealt(String kind, Set<String> ids) => find.byWidgetPredicate((w) {
      final k = w.key;
      if (w.runtimeType.toString() != '_AnimatedChoiceCard' || k is! ValueKey<String>) return false;
      final parts = k.value.split('-');
      return parts.first == kind && parts.length >= 3 && ids.contains(parts.skip(2).join('-'));
    });

Future<bool> _pumpUntil(WidgetTester t, bool Function() done, {int steps = 600}) async {
  for (var i = 0; i < steps; i++) {
    if (done()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return done();
}

/// Lets a freshly dealt hand land before it is tapped.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 25; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2.0;
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith(_TestAuth.new)],
    child: MaterialApp(
      theme: SlmTheme.night(),
      home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '5.8', ladderIndex: 140, pack: pack, muted: true),
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

GameSave _save(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(LearnBoardRunnerPage))).read(gameSaveProvider);

/// Plays the whole board. [missPicks] = the rounds where a trap is tapped
/// first (the trap's card says why, a fresh hand is dealt, then the safe card).
Future<void> _play(WidgetTester tester, {Set<String> missPicks = const {}}) async {
  for (final s in pack.slots) {
    final safe = {for (final o in s.options) if (o.correct) o.id};
    final traps = {for (final o in s.options) if (!o.correct) o.id};
    expect(await _pumpUntil(tester, () => _dealt('pick', safe).evaluate().isNotEmpty), isTrue, reason: '${s.id}: hand dealt');
    await _pumpUntil(tester, () => find.text(s.promptBn).evaluate().isNotEmpty, steps: 80);
    await _settle(tester);
    if (missPicks.contains(s.id)) {
      final trap = _dealt('pick', traps);
      expect(trap, findsWidgets, reason: '${s.id}: a hand holds traps');
      await pickBoardCard(tester, trap);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (final w in s.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: '${s.id}: a trap never opens the reason deck');
      }
      expect(await _pumpUntil(tester, () => _dealt('pick', safe).evaluate().isNotEmpty), isTrue);
      await _settle(tester);
    }
    await pickBoardCard(tester, _dealt('pick', safe));
    final rightWhy = {for (final w in s.whyChips) if (w.correct) w.id};
    expect(await _pumpUntil(tester, () => _dealt('why', rightWhy).evaluate().isNotEmpty), isTrue, reason: '${s.id}: reason deck');
    await _settle(tester);
    // The deck is one right chip and the rest wrong.
    final allWhy = {for (final w in s.whyChips) w.id};
    expect(_dealt('why', allWhy), findsNWidgets(s.whyCards), reason: '${s.id}: reason hand');
    expect(_dealt('why', rightWhy), findsOneWidget, reason: '${s.id}: one right reason');
    await pickBoardCard(tester, _dealt('why', rightWhy));
    // Wait until this round's reason cards are gone (next round or the myth).
    await _pumpUntil(tester, () => _dealt('why', allWhy).evaluate().isEmpty);
  }

  // The coworker: he storms in, says his line; the ask waits for him.
  final m = pack.myth;
  expect(await _pumpUntil(tester, () => find.text(m.rivalLineBn).evaluate().isNotEmpty), isTrue, reason: 'his myth on screen');
  expect(find.text('হ্যাঁ'), findsNothing, reason: 'no answer while he talks');
  expect(await _pumpUntil(tester, () => find.text('হ্যাঁ').evaluate().isNotEmpty), isTrue, reason: 'the ask after he leaves');
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final flipped = find.text('সেটা কি ভুল?').evaluate().isNotEmpty;
  // "বিশ্বাস করেন?" → না; "সেটা কি ভুল?" → হ্যাঁ.
  await tester.tap(find.text(flipped ? 'হ্যাঁ' : 'না'));
  await tester.pump();
  final mythRight = {for (final w in m.whyChips) if (w.correct) w.id};
  expect(await _pumpUntil(tester, () => _dealt('why', mythRight).evaluate().isNotEmpty), isTrue, reason: 'myth reason deck');
  await _settle(tester);
  await pickBoardCard(tester, _dealt('why', mythRight));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(LearnDealer.resetMemory);
  // The app's Bangla font, so text wraps on screen as it does on a phone (the
  // test font draws every Bangla glyph a full em wide, which overflows the
  // rival's bubble lane with the lesson's long myth line).
  setUpAll(() async {
    final loader = FontLoader('Noto Sans Bengali');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/NotoSansBengali-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  });

  test('the lesson 5.8 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '5.8');
    // Registered by the director (learn_board_models.dart); until then null.
    expect(learnBoardPackFor('5.8'), same(learnBoardPack58));
    expect(pack.badgeBn, 'ফল্ট ফাইন্ডার');
    expect(pack.titleBn, 'ট্রান্সফরমারের সাধারণ সমস্যা: হৃৎপিণ্ডের রোগ নির্ণয়');
    expect(pack.slots.map((s) => s.id), ['htfuse', 'noise', 'leak', 'ltdead', 'proof']);
    expect(pack.slots.length, 5, reason: 'M5-11: boards trimmed to 5 rounds');
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
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স', 'শদিদ', 'شدید']) {
        expect(l, isNot(contains(bad)), reason: '"$l": house word / clean Bangla for "$bad"');
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
      expect(whys.length, greaterThan(1), reason: '${s.id}: fresh reason decks');
    }
  });

  test('the lesson\'s points: HT re-blow, noise, leak, dead LT phase, proof of an inside fault', () {
    // HT fuse blows again: sectionalize first, a faulty DTR to the workshop; never charge again and again.
    expect(_slot('htfuse').options.where((o) => o.correct).map((o) => o.id), ['section', 'workshop']);
    expect(_reject('htfuse', 'third'), allOf(contains('বিস্ফোরিত'), contains('মারাত্মক')));
    expect(_reject('htfuse', 'htonly'), allOf(contains('এলটি'), contains('সেকশনালাইজিং')));
    expect(_reject('htfuse', 'htonly'), isNot(contains('মারাত্মক')), reason: 'the word marks deadly-class cards only');
    expect(_reject('htfuse', 'bushing'), allOf(contains('পাংচার'), contains('ওয়ার্কশপে')));
    // Noise: the load first; normal load and still noisy → the supervisor.
    expect(_slot('noise').options.where((o) => o.correct).map((o) => o.id), ['load', 'report']);
    expect(_reject('noise', 'walkaway'), contains('ভাষা'));
    expect(_reject('noise', 'tickok'), contains('সুপারভাইজারকে'));
    expect(_reject('noise', 'guess'), allOf(contains('ওভারলোডিং'), contains('লোড পরীক্ষা')));
    // Leak: source and amount; small → watch; big → off, repair, top up; it lets moisture in.
    expect(_slot('leak').options.where((o) => o.correct).map((o) => o.id), ['watch', 'fix']);
    expect(_reject('leak', 'driveoff'), allOf(contains('বন্ধ'), contains('টপ-আপ')));
    expect(_reject('leak', 'wipe'), contains('আর্দ্রতা'));
    expect(_reject('leak', 'pour'), allOf(contains('উৎস'), contains('পরিমাণ')));
    // Dead LT phase: off, prove dead (M5-2: a tool before 0 V is deadly), connection; sound → replace.
    expect(_slot('ltdead').options.where((o) => o.correct).map((o) => o.id), ['check', 'swap']);
    expect(_reject('ltdead', 'livespanner'), allOf(contains('মারাত্মক'), contains('ডেড প্রমাণ'), contains('বন্ধ')));
    expect(_reject('ltdead', 'newlink'), contains('এইচটি ফিউজ ঠিক'));
    expect(_reject('ltdead', 'leftrun'), contains('বদলাতে'));
    // Proof (pro tips): IR on an isolated DTR, dark oil, bushing; water (M5-6 card) and records.
    expect(_slot('proof').options.where((o) => o.correct).map((o) => o.id), ['ir', 'oil', 'bushing']);
    expect(_reject('proof', 'livemegger'), allOf(contains('মারাত্মক'), contains('বিচ্ছিন্ন')));
    expect(_reject('proof', 'water'), 'জল তেলের সবচেয়ে বড় শত্রু — ডাই-ইলেকট্রিক স্ট্রেন্থ নাটকীয়ভাবে কমায়।');
    expect(_reject('proof', 'records'), contains('ইতিহাস'));
    expect(pack.earnedBn, allOf(contains('সেকশনালাইজিং'), contains('ডেড প্রমাণ')));
  });

  test('"মারাত্মক" marks exactly the deadly-class cards (R8, R2, R23)', () {
    // On a Learn board the card text is the only deadly signal, so the word
    // means deadly class and nothing else.
    const deadly = {'htfuse/third', 'ltdead/livespanner', 'proof/livemegger'};
    final marked = {
      for (final s in pack.slots)
        for (final o in s.options)
          if (o.rejectBn.contains('মারাত্মক')) '${s.id}/${o.id}',
    };
    expect(marked, deadly);
  });

  test('one script for the line terms: এইচটি / এলটি / ডিও, never HT / LT / DO', () {
    final m = pack.myth;
    final lines = <String>[
      pack.introBn, pack.earnedBn,
      for (final s in pack.slots) ...[
        s.promptBn,
        for (final o in s.options) ...[o.labelBn, o.rejectBn],
        for (final w in s.whyChips) w.textBn,
      ],
      m.tauntBn, m.rivalLineBn, m.stingBn, m.flipStingBn, ...m.dangerHints,
      for (final w in m.whyChips) w.textBn,
    ];
    for (final l in lines) {
      expect(l, isNot(matches(RegExp(r'\b(HT|LT|DO)\b'))), reason: '"$l"');
    }
  });

  test('the myth: a yes/no flip ask, and danger tags that do not hand over the answer', () {
    final m = pack.myth;
    // The turned-round ask must be a yes/no question (the heading reads "সেটা কি ভুল?").
    expect(m.flipStingBn, endsWith('সেটা কি ভুল?'));
    expect(LearnVoice.resolve(m.flipStingBn), isNotNull, reason: 'the guide has a clip for the flip ask');
    // No tag shares a two-word phrase (or the key fact words) with a right myth chip.
    List<String> words(String t) =>
        t.replaceAll(RegExp(r'[—"?,।!…]'), ' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    Set<String> pairs(String t) {
      final w = words(t);
      return {for (var i = 0; i + 1 < w.length; i++) '${w[i]} ${w[i + 1]}'};
    }

    for (final h in m.dangerHints) {
      for (final c in m.whyChips.where((c) => c.correct)) {
        expect(pairs(h).intersection(pairs(c.textBn)), isEmpty, reason: 'tag "$h" restates chip "${c.textBn}"');
      }
      for (final giveaway in ['এইচটি ফিউজ', 'পুড়ে', 'চাপ', 'উড়ে']) {
        expect(h, isNot(contains(giveaway)), reason: 'tag "$h" states the reality ("$giveaway")');
      }
    }
  });

  test('every picture exists (vector scenes from tool/m5_board58_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m5_board58 folder is a card on the board', () {
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

  // The playbook (section 4): the right option must not stand out. Go through
  // EVERY hand the dealer can make (one safe card + any cards-1 traps).
  test('in every possible hand, the safe card\'s backdrop and colours are on a trap too', () {
    final used = RegExp(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b');
    final backdrop = RegExp(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"');
    final svgs = <String, String>{};
    String body(String asset) => svgs.putIfAbsent(asset, () => File(asset).readAsStringSync());
    Set<String> tokens(String asset) {
      expect(body(asset), isNot(contains('<text')), reason: '$asset: no words in the art');
      return used.allMatches(body(asset).split('</defs>').last).map((m) => m.group(0)!).toSet();
    }

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

  // The playbook: the result of a mistake plays only after it is picked, and
  // §4 bans right/wrong marks on cards. So no trap may show a flash the safe
  // card lacks, and no card carries the green tick.
  test('no trap gives itself away with a flash or a right/wrong mark', () {
    String body(String asset) => File(asset).readAsStringSync().split('</defs>').last;
    for (final s in pack.slots) {
      final safeFlash = s.options.where((o) => o.correct).any((o) => body(o.asset).contains('url(#spark)'));
      for (final o in s.options) {
        final b = body(o.asset);
        if (!o.correct && !safeFlash) {
          expect(b, isNot(contains('url(#spark)')), reason: '${s.id}/${o.id}: a flash only on a trap');
        }
        expect(b.toUpperCase(), isNot(contains('#3E9B4F')), reason: '${s.id}/${o.id}: a green tick on a card');
      }
    }
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'ট্রান্সফরমারের এলটি সাইডে ফিউজ থাকে না, তাই এলটি ফল্টে ট্রান্সফরমারের কিছু হয় না।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'a big LT short stresses the DTR and blows its HT fuse');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('এইচটি ফিউজ')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // His parting line is already recorded; the new ones stay silent (caption held) until recorded.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M5Board58Lines.toRecord, containsAll([m.tauntBn, m.rivalLineBn]));
    for (final l in M5Board58Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: 'a registered clip exists: "$l"');
    }
  });

  group('board on screen', () {
    setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('board waits quietly at the first question (${reduce ? 'reduce' : 'anim'})', (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await _open(tester);
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

  testWidgets('a clean play: five safe pictures, their reasons, the coworker refused — the rung is cleared', (tester) async {
    await _open(tester);
    await _play(tester);
    expect(await _pumpUntil(tester, () => _save(tester).rungProgress[_rung] == 'cleared', steps: 400), isTrue,
        reason: 'a clean play clears the rung');
    expect(find.byType(LevelFailPanel), findsNothing);
    // Let the award finish (bonus, score commit, best time) before leaving.
    expect(await _pumpUntil(tester, () => _save(tester).bestTimeMsByRung.containsKey(_rung), steps: 300), isTrue,
        reason: 'the score and time of the play are saved');
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets('a careless play (a trap in every round) ends below the pass mark: the fail panel, nothing cleared',
      (tester) async {
    await _open(tester);
    await _play(tester, missPicks: {for (final s in pack.slots) s.id});
    // 12 questions (5 picks + 5 reasons + believe + myth reason), 5 missed → 58 % < 60.
    expect(await _pumpUntil(tester, () => find.byType(LevelFailPanel).evaluate().isNotEmpty, steps: 400), isTrue,
        reason: 'below the pass mark the board fails');
    expect(_save(tester).rungProgress[_rung], isNot('cleared'));
    expect(tester.takeException(), isNull);
    await _close(tester);
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;
