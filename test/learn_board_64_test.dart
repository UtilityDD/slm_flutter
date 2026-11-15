// Module 6 lesson 6.4 picture board ("AB সুইচ ও আইসোলেটর: ট্র্যাফিক কন্ট্রোলার",
// rung 6.4/learn, pack learn_6_4): its content follows the board's rules, the
// lesson's points and the Module 6 rulings (X3 off-load both ways, M6-3 only a
// stalled stroke is wrong), every picture exists and no colour or backdrop
// marks the safe card (in any hand the dealer can make), the breaker lamps are
// never the giveaway, the rival's myth is the lesson's own and his new lines
// are listed for recording, a clean play (picks, reasons, the rival's myth)
// clears the rung, a play with a miss on every round fails it, the gesture
// hint sweeps without pressing, and the board waits quietly once the first
// hand is dealt. Boards are not scored for deadly acts (ruling M6-4), so a
// trap costs the round's mark, never a freeze.
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

const pack = learnBoardPack64;
const _artDir = 'assets/game/art/m6_board64';
const _rung = '6.4/learn';
const _ladder = 159; // m6 starts after 150 rungs; 6.4/learn is orderInModule 9

/// Has read lesson 6.4 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_4', '6.4']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.4', ladderIndex: _ladder, pack: pack, muted: true),
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

/// Lesson 6.4's whole text (read-only source), for word-for-word checks.
String _lessonText() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  final lesson = all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '6.4');
  // The lesson file writes ড় ঢ় য় as single code points; the app's text (as
  // every board pack) uses the base letter + nukta. Compare in one form.
  return jsonEncode(lesson['content'])
      .replaceAll('ড়', 'ড়')
      .replaceAll('ঢ়', 'ঢ়')
      .replaceAll('য়', 'য়');
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

  test('the lesson 6.4 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '6.4');
    // Registered in learn_board_models.dart (learnBoardPackFor).
    expect(learnBoardPackFor('6.4'), same(learnBoardPack64));
    expect(pack.badgeBn, 'যন্ত্র গুরু', reason: 'lesson 6.4 badge_name');
    expect(pack.titleBn, 'AB সুইচ ও আইসোলেটর: ট্র্যাফিক কন্ট্রোলার');
    expect(pack.slots.map((s) => s.id), ['gap', 'open', 'close', 'earth', 'care']);
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

  test('the lesson\'s points: a visible gap, off-load both ways, the reverse order, one stroke, an earthed handle, patrol care', () {
    // Gap: an open isolator shows its gap; a breaker does not; all three phases open.
    expect(_safeIds('gap'), {'tilt', 'lift'});
    expect(_reject('gap', 'closed'), contains('কোনো গ্যাপ নেই'));
    expect(_reject('gap', 'breaker'), allOf(contains('খালি চোখে বোঝা যায় না'), contains('দৃশ্যমান গ্যাপ')));
    expect(_reject('gap', 'stuck'), contains('তিনটি ফেজই'));
    // Open (ruling X3): breaker first, never on load, never to stop a fault.
    expect(_safeIds('open'), {'brkoff', 'phone'});
    expect(_reject('open', 'arc'), allOf(contains('লোডে খুললে'), contains('আর্ক')));
    expect(_reject('open', 'lamp'), allOf(contains('এখনও লোড'), contains('সামান্য লোড কারেন্টও')));
    expect(_reject('open', 'fault'), allOf(contains('ফল্ট কারেন্ট'), contains('সার্কিট ব্রেকারের')));
    expect(_slot('open').whyChips.any((w) => w.correct && w.textBn.contains('আগে ব্রেকার')), isTrue);
    // Close (ruling X3): isolator first, then the breaker ON; a half-seated
    // contact makes a hotspot; only a stalled stroke is wrong (ruling M6-3).
    expect(_safeIds('close'), {'shut', 'seated'});
    expect(_reject('close', 'flash'), contains('প্রথমে আইসোলেটর লাগান, তারপর সার্কিট ব্রেকার ON করুন'));
    expect(_reject('close', 'half'), contains('হটস্পট'));
    expect(_reject('close', 'stall'), allOf(contains('দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত'), contains('মাঝপথে থামবেন না')));
    // Earth: the handle earthed before it is worked; worked from the ground.
    expect(_safeIds('earth'), {'lead', 'ground'});
    expect(_reject('earth', 'cut'), contains('অপারেটরের সুরক্ষা'));
    expect(_reject('earth', 'bolt'), contains('আর্থিং করা আছে'));
    expect(_reject('earth', 'head'), allOf(contains('মাটি থেকে'), contains('মৃত্যু')),
        reason: 'a hand on a live blade is deadly (ruling X7/B4): the reason names it, not only the habit');
    // Care: contacts home, arcing marks, clean insulators, a jammed mechanism lubricated.
    expect(_safeIds('care'), {'clean', 'horns'});
    expect(_reject('care', 'black'), contains('আর্কিং-এর চিহ্ন'));
    expect(_reject('care', 'dirty'), contains('পরিষ্কার'));
    expect(_reject('care', 'jam'), contains('লুব্রিকেট'));
    expect(pack.earnedBn, allOf(contains('আগে ব্রেকার'), contains('উল্টো'), contains('গ্যাপ')));
  });

  test('ruling M6-3: speed is never wrong — no card or chip faults a quick stroke, a slow one is never right', () {
    final fast = RegExp('খুব দ্রুত|তাড়াহুড়ো|জোরে টান');
    for (final s in pack.slots) {
      for (final o in s.options) {
        if (!o.correct) expect(o.rejectBn, isNot(matches(fast)), reason: '${s.id}/${o.id}: no "too fast" trap');
      }
      for (final w in s.whyChips) {
        if (w.correct) expect(w.textBn, isNot(contains('আস্তে')), reason: '${s.id}/${w.id}: a slow stroke is never the rule');
      }
    }
    // The only stroke trap is the stall, and its right chip is the lesson's "one stroke".
    expect(_slot('close').whyChips.where((w) => w.correct && w.textBn.contains('এক টানে')), hasLength(1));
  });

  test('the lesson\'s own words where the board quotes it', () {
    final lesson = _lessonText();
    for (final q in [
      pack.myth.rivalLineBn,
      'প্রথমে আইসোলেটর লাগান, তারপর সার্কিট ব্রেকার ON করুন',
      'দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত',
      'মাঝপথে থামবেন না',
      'অপারেট করার আগে নিশ্চিত করুন যে অপারেটিং হ্যান্ডেলটি সঠিকভাবে আর্থিং করা আছে',
      'AB সুইচ সাধারণত একটি লম্বা অপারেটিং রড বা হ্যান্ডেল দিয়ে মাটি থেকে অপারেট করা হয়',
      'সামান্য লোড কারেন্টও একটি বিপজ্জনক আর্ক তৈরি করার জন্য যথেষ্ট',
      'ফল্ট কারেন্টকে বাধা দেওয়ার ক্ষমতা',
      'হটস্পট তৈরি করবে',
      'যন্ত্র গুরু',
    ]) {
      // The board writes ON/OFF in English letters (owner, 2026-11-15); the lesson says অন/অফ.
      expect(lesson, contains(q.replaceAll('ON', 'অন').replaceAll('OFF', 'অফ')), reason: 'lesson 6.4 says "$q"');
    }
  });

  test('every picture exists (vector scenes from tool/m6_board64_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m6_board64 folder is a card on the board', () {
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

    for (final s in pack.slots) {
      final traps = s.options.where((o) => !o.correct).toList();
      var hands = 0;
      for (final safe in s.options.where((o) => o.correct)) {
        for (final hand in _combos(traps, s.cards - 1)) {
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

  // Rounds 2–3 show the substation breaker's two lamps (red lit = ON, green
  // lit = OFF). Ruling X3 is about the breaker's state, so the lamps are the
  // content — but no lamp colour may mark the safe card, either way round: a
  // safe card shows the red lamp lit too, a trap shows the green lamp lit too,
  // and in every hand each lit lamp on the safe card is lit on a trap.
  test('the breaker lamps are content, never the giveaway', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const redLit = 'r="4.2" fill="#D8402F" opacity="1"';
    const greenLit = 'r="4.2" fill="#2FB45A" opacity="1"';
    // Off-load before opening: the breaker OFF (green), or still ON and the
    // worker keeps off the handle and phones.
    expect(svg('open_brkoff'), contains(greenLit));
    expect(svg('open_phone'), contains(redLit), reason: 'a safe card with the red lamp lit');
    for (final c in ['open_arc', 'open_fault']) {
      expect(svg(c), contains(redLit), reason: '$c: opened with the breaker still ON');
    }
    // The lamp says OFF, yet a house is still lit: load on the line.
    expect(svg('open_lamp'), allOf(contains(greenLit), contains('url(#glow)" opacity="0.85"')),
        reason: 'a trap with the green lamp lit (and a lit window)');
    // Closing: the AB goes in with the breaker OFF; the breaker ON only once
    // all three phases are home.
    expect(svg('close_shut'), contains(greenLit));
    expect(svg('close_seated'), contains(redLit), reason: 'a safe card with the red lamp lit');
    expect(svg('close_flash'), contains(redLit), reason: 'closed with the breaker ON');
    expect(svg('close_half'), contains(redLit), reason: 'the breaker ON on a half-seated blade');
    expect(svg('close_stall'), contains(greenLit), reason: 'a trap with the green lamp lit');
    // In every hand of both lamp rounds, each lamp state lit on the safe card
    // is lit on a trap in that hand, so neither colour picks the card.
    for (final s in ['open', 'close']) {
      final slot = _slot(s);
      String card(LearnBoardOption o) => svg(o.asset.split('/').last.replaceAll('.svg', ''));
      final traps = slot.options.where((o) => !o.correct).toList();
      for (final safe in slot.options.where((o) => o.correct)) {
        for (final hand in _combos(traps, slot.cards - 1)) {
          for (final lit in [redLit, greenLit]) {
            if (!card(safe).contains(lit)) continue;
            expect(hand.any((o) => card(o).contains(lit)), isTrue,
                reason: '$s: ${safe.id} with ${hand.map((o) => o.id).join(', ')} — its lit lamp is on no trap');
          }
        }
      }
    }
    // Every lamp card draws both lamps, one lit and one dim.
    for (final s in ['open', 'close']) {
      for (final o in _slot(s).options) {
        final b = svg(o.asset.split('/').last.replaceAll('.svg', ''));
        expect('fill="#D8402F"'.allMatches(b).length + 'fill="#2FB45A"'.allMatches(b).length, greaterThanOrEqualTo(2), reason: o.asset);
        expect(b.contains(redLit) != b.contains(greenLit), isTrue, reason: '${o.asset}: exactly one lamp lit');
      }
    }
    // Only the on-load cards draw an arc; the safe cards never.
    for (final c in ['open_brkoff', 'open_phone', 'close_shut', 'close_seated']) {
      expect(svg(c), isNot(contains('url(#arc)')), reason: c);
    }
    expect(svg('open_arc'), contains('url(#arc)'));
    expect(svg('close_flash'), contains('url(#arc)'));
    // Nor does the pose: in round 2 a trap's worker is off the handle too
    // (the fault card: reaching for it, not yet on it), like the phone card.
    expect(svg('open_fault'), contains('<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.9">'),
        reason: 'the fault card: hurrying in (motion lines), not gripping');
  });

  // Ruling X7: anyone drawn at height wears a full-body harness.
  test('the climber on the round 4 trap wears a full-body harness', () {
    final head = File('$_artDir/earth_head.svg').readAsStringSync();
    expect(head, contains('#F08A24'), reason: 'harness straps (ruling X7: full-body harness)');
  });

  test('the careless lineman says the lesson\'s first myth, word for word; his new lines are listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'সামান্য লোড থাকলে আইসোলেটর খোলা যায়, কিছু হয় না।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'even a little load current makes a dangerous arc');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('সামান্য লোড')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    for (final h in m.dangerHints) {
      for (final w in m.whyChips.where((w) => w.correct)) {
        expect(w.textBn, isNot(contains(h)), reason: 'a danger tag never repeats a right reason');
      }
    }
    // His parting line is already recorded; the new ones wait for the voice session.
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board64Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M6Board64Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines (drafts for the owner's wording) are pinned.
    expect(M6Board64Lines.newGuideLines, [pack.introBn, pack.earnedBn]);
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.4', ladderIndex: _ladder, pack: pack, muted: true),
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

/// Every [k]-card hand from [xs], in order.
Iterable<List<T>> _combos<T>(List<T> xs, int k) sync* {
  if (k == 0) {
    yield [];
    return;
  }
  for (var i = 0; i <= xs.length - k; i++) {
    for (final rest in _combos(xs.sublist(i + 1), k - 1)) {
      yield [xs[i], ...rest];
    }
  }
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;

Set<String> _safeIds(String slot) => {for (final o in _slot(slot).options) if (o.correct) o.id};
