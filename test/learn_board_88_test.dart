// Module 8 lesson 8.8 picture board ("নেট মিটারিং (Net Metering) রেগুলেশন:
// সৌরশক্তির নিয়ম", rung 8.8/learn, pack learn_8_8): its content follows the
// board's rules, the live lesson (tool/all_training_chapters_bn.json, read
// here with its precomposed nukta letters normalised) and the Module 8
// rulings (M8-2 climb with a solar fuse in, M8-12 today's numbers, M8-19 the
// WBSEDCL DTR's AB switch and HG fuses, term rules). Every picture exists and
// no colour or backdrop gives the safe card away (in any hand the dealer can
// make). The rival's myth is the lesson's own and every new line is listed
// for recording. A clean play (picks, reasons, the rival's myth) clears the
// rung, a miss on every round fails it (the board's strike-out), a
// deadly-class trap teaches with the lesson's own words (boards have no
// freeze: kit design), the gesture hint sweeps without pressing, and the
// board waits quietly once dealt.
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
import 'package:slm_flutter/features/game/learn_board_pack88.dart';
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

const pack = learnBoardPack88;
const _artDir = 'assets/game/art/m8_board88';
const _rung = '8.8/learn';

/// Live lesson 8.8 pro tip 1 (ruling M8-2 and the M8-19 term rule: switch
/// states read OFF on screen): the climb with a solar house's fuse in.
const _proTipOne = 'শুধু ট্রান্সফরমার OFF করবেন না। পোল থেকে ওই বাড়ির ফিউজও খুলে দিন।';

/// Live lesson 8.8 myth 1's reality, the rival's myth word for word.
const _lessonMyth = 'সোলার বসালে লোড শেডিং-এও আমার বাড়িতে ফ্যান চলবে।';

/// Has read lesson 8.8 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['8_8', '8.8']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.8', ladderIndex: 0, pack: pack, muted: true),
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

/// The lesson's text with its precomposed nukta letters split into base and
/// nukta, as the board writes them (ruling X6 text rule).
String _nfd(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
    SpokenOnce.resetForTest();
  });

  test('the lesson 8.8 board with five rounds', () {
    expect(pack.lessonId, '8.8');
    expect(pack.badgeBn, 'জরুরী রেগুলেশন (WBERC ফোকাস)', reason: 'the lesson\'s own badge');
    expect(pack.titleBn, 'নেট মিটারিং (Net Metering) রেগুলেশন: সৌরশক্তির নিয়ম');
    // Five rounds (ruling M8-21): the same five as the spec's board rounds.
    expect(pack.slots.map((s) => s.id), ['meter', 'shut', 'inv', 'load', 'bill']);
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
    }
    expect(pack.slots.map((s) => s.promptBn).toSet().length, pack.slots.length, reason: 'every round asks its own question');
    expect(pack.introBn, isNotEmpty);
    expect(pack.earnedBn, isNotEmpty);
  });

  test('every round: 4–6 pictures, one safe picture and three traps, each trap says why', () {
    for (final s in pack.slots) {
      expect(s.options.length, inInclusiveRange(4, 6), reason: s.id);
      final safe = s.options.where((o) => o.correct).length;
      final traps = s.options.where((o) => !o.correct).length;
      expect(safe, greaterThanOrEqualTo(2), reason: '${s.id}: two pictures of the safe act, so its look cannot be learnt');
      expect(traps, greaterThanOrEqualTo(s.cards - 1), reason: '${s.id}: enough traps for a hand');
      expect(s.cards, 4, reason: '${s.id}: a hand of four pictures');
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
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp('[০-৯]'))), reason: '"$l": English digits on screen');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        expect(l, isNot(matches(RegExp('(?<![ঀ-৿])$bad'))), reason: '"$l": house word for "$bad"');
      }
    }
  });

  test('term rules: LT/HT/kV in English letters, ON/OFF for states, «AB লাগানো», no «মরা», base + nukta', () {
    for (final l in _allText()) {
      for (final bad in ['এলটি', 'এইচটি', 'কেভি', 'কেভিএ']) {
        expect(l, isNot(contains(bad)), reason: '"$l": $bad is written in English letters');
      }
      // Switch and line states are ON / OFF; a standalone অন / অফ is wrong
      // ('অন-গ্রিড', the lesson's term, is not a state).
      expect(l, isNot(matches(RegExp(r'(?<![ঀ-৿])(অন|অফ)(?![ঀ-৿\-])'))), reason: '"$l": ON / OFF, not অন / অফ');
      expect(l, isNot(contains('AB বন্ধ')), reason: '"$l": closing an AB is «AB লাগানো»');
      expect(l, isNot(contains('মরা')), reason: '"$l": the dead line is «ডেড», not «মরা»');
      expect(l, isNot(matches(RegExp('মৃত(?!্যু)'))), reason: '"$l": «ডেড», never «মৃত» (মৃত্যু is the lesson\'s own word)');
      expect(l, isNot(matches(RegExp('[ড়ঢ়য়]'))), reason: '"$l": য় ড় ঢ় as base + nukta');
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
    final d = LearnDealer(math.Random(8));
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

  test('the lesson\'s points: meter, shutdown, inverter, sanctioned load, the bill', () {
    // Meter: bi-directional, Import and Export read apart (section 1).
    expect(_safeIds('meter'), {'pages', 'arrow'});
    expect(_reject('meter', 'single'), allOf(contains('খরচ হিসেবে'), contains('বিল বেড়ে যাবে')));
    expect(_reject('meter', 'disc'), contains('এক দিকেই মাপে'));
    expect(_reject('meter', 'empty'), allOf(contains('নেট-মিটার'), contains('Import আর Export')));
    expect(_opt('meter', 'pages').labelBn, contains('Import আর Export'));
    // Shutdown in a solar area: the DTR OFF with its AB, and the solar house's
    // fuse pulled before any climb (pro tip 1; ruling M8-2).
    expect(_safeIds('shut'), {'pull', 'fuse'});
    expect(_opt('shut', 'pull').labelBn, allOf(contains('ট্রান্সফরমার OFF'), contains('শাটডাউন ট্যাগ'), contains('ফিউজ খুলছেন')));
    expect(_reject('shut', 'dtr'), _proTipOne);
    expect(_reject('shut', 'wave'), contains('ফিউজ খুলে তবে উঠুন'));
    expect(_reject('shut', 'wrong'), contains('সোলার বাড়িরই'));
    expect(_slot('shut').whyChips.any((w) => w.correct && w.textBn.contains('ব্যাক-ফিড')), isTrue);
    // Inverter: OFF after the line is OFF (anti-islanding, section 2).
    expect(_safeIds('inv'), {'dark', 'wall'});
    expect(_reject('inv', 'lit'), allOf(contains('OFF হতেই হবে'), contains('ব্যাক-ফিড')));
    expect(_reject('inv', 'fan'), allOf(contains('অন-গ্রিডে'), contains('সোলারও OFF হয়')));
    expect(_reject('inv', 'walk'), contains('ইনভার্টারও OFF হয়েছে'));
    // Sanctioned load: solar at most 100 % (section 3, the WBERC rule).
    expect(_safeIds('load'), {'eq3', 'lt5'});
    expect(_opt('load', 'eq3').labelBn, allOf(contains('3 kW'), contains('সোলার 3 kW')));
    expect(_reject('load', 'over5'), contains('100%-এর বেশি'));
    expect(_reject('load', 'over4'), contains('লোডের 100% পর্যন্তই'));
    expect(_reject('load', 'two6'), contains('টেকনিক্যাল লস'));
    // The bill: Import minus Export, the fixed charge, banking (the lesson's last part).
    expect(_safeIds('bill'), {'net', 'winter'});
    expect(_reject('bill', 'zero'), contains('ফিক্সড চার্জ তো দিতেই হবে'));
    expect(_reject('bill', 'full'), contains('তার পার্থক্যের বিল'));
    expect(_reject('bill', 'add'), contains('খরচ নয়'));
    expect(_opt('bill', 'net').labelBn, allOf(contains('180 ইউনিট'), contains('ফিক্সড চার্জ')));
    expect(_opt('bill', 'winter').labelBn, contains('জমা'));
    expect(pack.earnedBn, allOf(contains('অনুমোদিত'), contains('OFF')));
  });

  test('the lesson sources: the pro tip and the myth are the live lesson\'s own words', () {
    final lesson = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as Object;
    final items = lesson is List ? lesson : (lesson as Map)['chapters'] as List;
    final ch = items.cast<Map>().firstWhere((x) => x['id'] == '8.8');
    final text = _nfd(jsonEncode(ch));
    // Switch states read OFF on the board: the lesson's 'অফ' is the same act.
    expect(text, contains(_nfd(_proTipOne.replaceAll('OFF', 'অফ'))), reason: 'pro tip 1, live text');
    expect(text, contains(_nfd('বিশ্বাসে মিলায় বস্তু, কিন্তু সোলারে মিলায় মৃত্যু!')), reason: 'pro tip 1 (last part)');
    expect(text, contains(_nfd(_lessonMyth)), reason: 'the myth, word for word');
    expect(text, contains(_nfd('শীতকালে যখন এসি চলে না')), reason: 'banking, advanced facts');
    expect(text, contains(_nfd('১০০%')), reason: 'the 100 % limit (the live text)');
    expect(pack.myth.rivalLineBn, _lessonMyth);
  });

  test('the Module 8 rulings: the climb with a solar fuse in (M8-2), the DTR AB and HG fuses (M8-19), no DO', () {
    // M8-2: the climb with a solar fuse in is the deadly class; the board
    // teaches it with the lesson's own pro tip (no freeze on a board).
    expect(_slot('shut').options.where((o) => !o.correct).map((o) => o.id), containsAll(['dtr', 'wave']));
    // M8-19: the DTR is drawn with its AB switch and HG fuses; no DO fuse,
    // no drop-out cut-out, no ডিও.
    for (final l in _allText()) {
      for (final no in ['DO ফিউজ', 'ড্রপ আউট', 'ডিও', 'DO fuse', 'DO-ফিউজ']) {
        expect(l, isNot(contains(no)), reason: '"$l": no DO fuse on this board (M8-19)');
      }
    }
    // The AB is named, and its closing word is «লাগানো»; the board never
    // asks the player to close it (the pictures show the DTR OFF).
    for (final l in _allText()) {
      expect(l, isNot(contains('AB বন্ধ')), reason: '"$l": «AB লাগানো» only');
    }
    // M8-12 today's numbers: the 100 % limit only; no 8.3/8.4/8.5 figure from
    // the older text (village 24 h, 6.1 m, 18–19 ft, ₹ amounts).
    for (final l in _allText()) {
      for (final old in ['24 ঘন্টা', '18-19 ft', '6.1 m', '₹', 'ফুট', 'রুপি']) {
        expect(l, isNot(contains(old)), reason: '"$l": not a figure from this lesson');
      }
    }
  });

  test('every url(#id) an SVG draws is defined in that SVG (no missing gradient)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        final svg = File(o.asset).readAsStringSync();
        final defined = RegExp(r'id="(\w+)"').allMatches(svg.split('</defs>').first).map((m) => m.group(1)).toSet();
        final used = RegExp(r'url\(#(\w+)\)').allMatches(svg).map((m) => m.group(1)!).toSet();
        expect(used.difference(defined), isEmpty, reason: '${o.asset}: ids drawn but not defined');
      }
    }
  });

  test('every picture exists (vector scenes from tool/m8_board88_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
  });

  test('every file in the m8_board88 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => '$_artDir/${f.uri.pathSegments.last}')
        .toSet();
    expect(onDisk, used, reason: 'no unused art, no stray files (the APK ships the folder), no missing art');
  });

  test('no words in the art, and no colour or backdrop gives the safe card away', () {
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

  test('the careless coworker says the lesson\'s myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _lessonMyth);
    expect(m.believeNoIsCorrect, isTrue, reason: 'a solar house does not run its fan in a load shed');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('OFF')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M8Board88Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M8Board88Lines.newRivalLines, M8Board88Lines.toRecord, reason: 'ruling M8-14: the drafts are pinned');
    for (final l in M8Board88Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 15 trap reasons, 20 right
    // chips, 4 myth chips, the closing line — pinned so none is forgotten.
    final g = M8Board88Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    expect(g, contains(_proTipOne));
    for (final s in pack.slots) {
      expect(g, contains(s.promptBn));
    }
    expect(g.length, 1 + 5 + 15 + 20 + 4 + 1);
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

    testWidgets('a deadly-class trap (a climb with the solar fuse in) teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      // Every round before the shutdown round, played clean.
      for (final s in pack.slots.takeWhile((s) => s.id != 'shut')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design): the trap costs the round's mark and
      // its reason is the lesson's pro tip, word for word.
      final shut = _slot('shut');
      await _settleHand(t, 'pick', {'dtr'}, 'shut: the climb with the fuses in (all three traps are in every hand)');
      await tapBoardCard(t, _dealt('pick', {'dtr'}));
      await _pumpUntil(t, () => find.text(_proTipOne).evaluate().isNotEmpty, what: 'the lesson\'s pro tip');
      for (final w in shut.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.8', ladderIndex: 0, pack: pack, muted: true),
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
