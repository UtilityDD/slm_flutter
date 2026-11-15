// Module 6 lesson 6.5 picture board ("আন্ডারগ্রাউন্ড (UG) কেবিল: লুকানো
// নেটওয়ার্ক", rung 6.5/learn, pack learn_6_5): its content follows the
// board's rules and the lesson's points, every picture exists and no colour
// or backdrop marks the safe card (in any hand the dealer can make), the
// rival's myth is the lesson's own and his new lines are listed for
// recording, a clean play (picks, reasons, the rival's myth) clears the rung,
// a play with a miss on every round fails it (the board's strike-out), the
// gesture hint sweeps without pressing, and the board waits quietly once the
// first hand is dealt.
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

const pack = learnBoardPack65;
const _artDir = 'assets/game/art/m6_board65';
const _rung = '6.5/learn';
const _ladder = 163;

/// Has read lesson 6.5 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_5', '6.5']));
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

/// Waits until a card of [ids] is dealt and has landed, then picks it (✓,
/// then এগিয়ে যান).
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.5', ladderIndex: _ladder, pack: pack, muted: true),
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

  test('the lesson 6.5 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '6.5');
    // Registered in learn_board_models.dart (learnBoardPackFor).
    expect(learnBoardPackFor('6.5'), same(learnBoardPack65));
    expect(pack.badgeBn, 'যন্ত্র গুরু', reason: 'the lesson\'s badge');
    expect(pack.titleBn, 'আন্ডারগ্রাউন্ড (UG) কেবিল: লুকানো নেটওয়ার্ক');
    expect(pack.slots.map((s) => s.id), ['layers', 'kits', 'joint', 'term', 'lay']);
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
      // The names show only on the card chosen (never in the preview), but
      // they stay the same length so none reads as the odd one out.
      expectSameLength('${s.id} labels', [for (final o in s.options) o.labelBn]);
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
      expect(l, isNot(contains('प्रचंड')), reason: 'the lesson typo is never copied');
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

  test('the lesson\'s points: layers, the right kit, clean dry certified jointing, sealed ends, gentle bends, armour earthed both ends', () {
    // Layers: jacket (moisture, chemicals), armour (blows, digging), metallic screen (earth fault path).
    expect(_safeIds('layers'), {'whole', 'stepped'});
    expect(_reject('layers', 'jacket'), allOf(contains('PVC'), contains('আর্দ্রতা আর রাসায়নিক')));
    expect(_reject('layers', 'armour'), contains('খোঁড়াখুঁড়ি'));
    expect(_reject('layers', 'screen'), contains('আর্থ ফল্ট কারেন্টের পথ'));
    // Kits: XLPE and PILC differ; an overhead joint is not a UG joint (myth 2).
    expect(_safeIds('kits'), {'xlpe', 'pilc'});
    expect(_reject('kits', 'xlpe_pilc'), contains('সম্পূর্ণ আলাদা'));
    expect(_reject('kits', 'pilc_xlpe'), contains('সম্পূর্ণ আলাদা'));
    expect(_reject('kits', 'sleeve'), allOf(contains('ওভারহেডের জয়েন্ট'), contains('আর্দ্রতা')));
    // The name shows only after the choice, so it says what the cut end showed:
    // the cable type and the kit beside it (the sleeve sits by an XLPE cable).
    const cables = {'xlpe': 'XLPE', 'pilc': 'PILC', 'xlpe_pilc': 'XLPE', 'pilc_xlpe': 'PILC', 'sleeve': 'XLPE'};
    const kits = {'xlpe': 'XLPE জয়েন্টিং কিট', 'pilc': 'PILC জয়েন্টিং কিট', 'xlpe_pilc': 'PILC জয়েন্টিং কিট', 'pilc_xlpe': 'XLPE জয়েন্টিং কিট', 'sleeve': 'ওভারহেডের স্লিভ'};
    for (final o in _slot('kits').options) {
      expect(o.labelBn, startsWith('${cables[o.id]} কেবিলের পাশে'), reason: '${o.id}: the name says which cable the picture shows');
      expect(o.labelBn, endsWith(kits[o.id]!), reason: '${o.id}: the name says which kit lies beside it');
    }
    // Joint: moisture, dust or sweat spoil it; training and certification (safety tip).
    expect(_safeIds('joint'), {'certified', 'cover'});
    expect(_reject('joint', 'rain'), contains('আর্দ্রতা'));
    expect(_reject('joint', 'dust'), allOf(contains('ধুলো'), contains('ঘাম')));
    expect(_reject('joint', 'helper'), allOf(contains('প্রশিক্ষণ'), contains('সার্টিফিকেশন')));
    // Termination: end termination kit, stress control tubing, 90% of faults.
    expect(_safeIds('term'), {'pole', 'dtr'});
    expect(_reject('term', 'bare'), contains('এন্ড টার্মিনেশন কিট'));
    expect(_reject('term', 'stress'), allOf(contains('পাংচার'), contains('স্ট্রেস কন্ট্রোল টিউবিং')));
    expect(_reject('term', 'cracked'), contains('90%'));
    // Lay: bending radius, armour earthed at both ends (one end = slip, M6-5), the jacket print.
    expect(_safeIds('lay'), {'bend', 'bond', 'print'});
    expect(_reject('lay', 'kink'), contains('বেন্ডিং রেডিয়াস'));
    expect(_reject('lay', 'riser'), contains('তীক্ষ্ণ বাঁক'));
    expect(_reject('lay', 'oneend'), allOf(contains('দুই প্রান্তেই'), contains('ফল্ট কারেন্টের নিরাপদ পথ')));
    expect(_opt('lay', 'print').labelBn, contains('ডকেট'));
    expect(_slot('lay').whyChips.any((w) => w.correct && w.textBn.contains('দুই প্রান্তেই')), isTrue);
    expect(pack.earnedBn, allOf(contains('কিট'), contains('দুই প্রান্তে')));
  });

  test('every picture exists (vector scenes from tool/m6_board65_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m6_board65 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => '$_artDir/${f.uri.pathSegments.last}')
        .toSet();
    expect(onDisk, used, reason: 'no unused art, no placeholder, no missing art');
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

  // What the art must show for the rulings: the jointing pit is shut down
  // (X1: the red tag and a working earth in every joint card, so the traps are about
  // moisture, dirt and skill), the DTR has no drop-out fuse (M6-2), the kit
  // boxes and the jacket print carry no letters, the armour bond shows two
  // earthed ends against one, and no mark points at a trap's fault.
  test('the art follows the rulings: pit shut down, no DO, both earth ends drawn', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const tag = 'width="10" height="15" rx="1.5" fill="#D8402F"'; // the red isolation tag
    const earthClamp = 'width="8" height="12" rx="1.5" fill="#3E9B4F"'; // the working earth on the cable
    for (final o in _slot('joint').options) {
      expect(svg('joint_${o.id}'), contains(tag), reason: 'joint_${o.id}: the cable is shut down (red tag)');
      expect(svg('joint_${o.id}'), contains(earthClamp), reason: 'joint_${o.id}: the cable is proved dead and earthed (working earth)');
    }
    const idCard = 'fill="#3B6EA8"'; // the photo on the jointer's ID card
    expect(svg('joint_certified'), contains(idCard));
    expect(svg('joint_cover'), contains(idCard));
    expect(svg('joint_helper'), isNot(contains(idCard)), reason: 'the helper has no ID card');
    // No drop-out fuse on Module 6 DTRs: no barrel hanging open or closed.
    for (final c in ['term_dtr', 'term_stress']) {
      expect(svg(c), isNot(contains('rotate(160 ')), reason: '$c: no drop-out barrel');
    }
    // Two earthed ends (two clamps, two leads to rods) against one.
    const clamp = 'width="8" height="18" rx="2" fill="url(#steel)"';
    expect(clamp.allMatches(svg('lay_bond')).length, 2, reason: 'lay_bond: armour clamped at both ends');
    expect(clamp.allMatches(svg('lay_oneend')).length, 1, reason: 'lay_oneend: armour clamped at one end only');
    // The gentle bend is a curve, the kinks sharp corners (no ring drawn, no mark on the fault).
    expect(svg('lay_bend'), contains('Q130 74 130 120'));
    expect(svg('lay_bend'), isNot(contains('stroke-linejoin="miter"')));
    expect(svg('lay_kink'), contains('stroke-linejoin="miter"'));
    expect(svg('lay_riser'), contains('stroke-linejoin="miter"'));
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'ইউজি কেবিল তো ইনসুলেটেড এবং আর্মার্ড, তাই এটা লাইভ থাকা অবস্থায় মাটি খোঁড়ার মেশিনের আঘাতে কিছু হবে না।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the lesson: মারাত্মক ভুল');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('আর্ক ফ্ল্যাশ')), isTrue);
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('অপারেটর')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // A danger tag shares no word with a right reason (no keyword echo).
    Set<String> words(String t) => t.split(RegExp(r'[\s,—\-।?!]+')).where((w) => w.length > 2).toSet();
    for (final h in m.dangerHints) {
      for (final w in m.whyChips.where((w) => w.correct)) {
        expect(words(h).intersection(words(w.textBn)), isEmpty, reason: 'danger tag "$h" echoes right reason "${w.textBn}"');
      }
    }
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board65Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M6Board65Lines.newRivalLines, M6Board65Lines.toRecord);
    for (final l in M6Board65Lines.toRecord) {
      // A clip may already exist once the director records it; either way the
      // line is listed for the voice session.
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
  });

  group('board on screen', () {
    // The app's Bangla font, so text wraps on screen as it does on a phone.
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
      await openBoardCard(t, _dealt('pick', _ids(s.options, correct: true)));
      expect(boardPreview, findsOneWidget, reason: 'a tap opens the card big');
      for (final w in s.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: 'nothing is answered by the tap');
      }
      await t.tap(boardReject, warnIfMissed: false);
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(boardConfirm, findsNothing, reason: '✕ closes the preview');
      expect(find.byKey(const ValueKey('board-card-aside')), findsOneWidget, reason: 'the card is set aside, dimmed');
      for (final w in s.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: '✕ answers nothing');
      }
      expect(c.read(gameSaveProvider).rungProgress[_rung], isNot('cleared'));
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.5', ladderIndex: _ladder, pack: pack, muted: true),
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
