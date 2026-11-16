// Module 6 lesson 6.7 picture board ("ক্যাপাসিটর ব্যাংক: পাওয়ার বুস্টার",
// rung 6.7/learn, pack learn_6_7): its content follows the board's rules, the
// live lesson and the Module 6 rulings (M6-5 swollen can, M6-6 the wait and
// the rod, X6 the live 75 V / 10 minute figure, the owner's term rules), every
// picture exists and no colour or backdrop marks the safe card (in any hand
// the dealer can make), the rival's myth is the lesson's own and every new
// line is listed for recording, a clean play (picks, reasons, the rival's
// myth) clears the rung, a miss on every round fails it (the board's
// strike-out), a deadly-class trap teaches with the lesson's own words
// (boards have no freeze: kit design), the gesture hint sweeps without
// pressing, and the board waits quietly once dealt.
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

const pack = learnBoardPack67;
const _artDir = 'assets/game/art/m6_board67';
const _rung = '6.7/learn';
const _ladder = 168; // m6 starts at 150; three rungs per lesson, 6.7/learn the 19th

/// Lesson 6.7 myth 1's reality, its first sentence after 'ভুল।' (the trap
/// 'trust' and the deadly-class flow below say it word for word).
const _myth1Reality = 'ব্যাংক লাইনের ফিউজের পরে লাগানো থাকলে লাইন আর্থ করা সত্ত্বেও ক্যাপাসিটর চার্জড থাকতে পারে।';

/// Has read lesson 6.7 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_7', '6.7']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.7', ladderIndex: _ladder, pack: pack, muted: true),
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

/// Lesson 6.7 from the live lesson file, with য় ড় ঢ় written as base + nukta
/// (the app's form; owner's unicode rule) and Bengali digits as English.
Map<String, dynamic> _lesson() {
  final all = File('tool/all_training_chapters_bn.json').readAsStringSync();
  Map<String, dynamic>? hit;
  void walk(Object? o) {
    if (hit != null) return;
    if (o is Map<String, dynamic>) {
      if (o['id'] == '6.7' && o['content'] is Map) {
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

  test('the lesson 6.7 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '6.7');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 6.7 entry.
    final wired = learnBoardPackFor('6.7');
    if (wired != null) expect(wired, same(learnBoardPack67));
    expect(pack.badgeBn, 'যন্ত্র গুরু', reason: 'the lesson\'s own badge');
    expect(pack.titleBn, 'ক্যাপাসিটর ব্যাংক: পাওয়ার বুস্টার');
    // Five rounds (owner, after Wave A).
    expect(pack.slots.map((s) => s.id), ['pf', 'build', 'wait', 'earthed', 'patrol']);
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

  test('the lesson\'s points: PF, the bank\'s build, the stored charge, the myths, patrol', () {
    // Point 1: same kW, less current; loss and drop fall; room for load.
    expect(_safeIds('pf'), {'amps', 'volt', 'load'});
    expect(_opt('pf', 'amps').labelBn, contains('kW একই'));
    expect(_reject('pf', 'kw'), allOf(contains('kW'), contains('kVA')));
    expect(_reject('pf', 'hot'), contains('I²R'));
    expect(_reject('pf', 'pfdown'), allOf(contains('1.0'), contains('উন্নত')));
    // Point 2 and pro tips 2 and 4: star or delta, its own switch and fuse,
    // not switched often, a special switch, APFC.
    expect(_safeIds('build'), {'star', 'delta', 'apfc'});
    expect(_reject('build', 'direct'), contains('ডেডিকেটেড সুইচ আর ফিউজ'));
    expect(_reject('build', 'hourly'), contains('ঘন ঘন ON-OFF'));
    expect(_reject('build', 'domestic'), contains('সুইচিং সার্জ'));
    // Point 3: the stored charge; the 5-10 minute wait; the rod even after it.
    expect(_safeIds('wait'), {'watch', 'rod'});
    expect(_reject('wait', 'bare'), allOf(contains('ব্যাটারির মতো'), contains('প্রাণঘাতী')));
    expect(_reject('wait', 'early'), contains('5-10 মিনিট'));
    expect(_reject('wait', 'norod'), contains('ডিসচার্জ রডে'));
    expect(_reject('wait', 'load'), contains('শক্তি সঞ্চয়কারী ডিভাইস'));
    // R9: the rod's earth on first, then the hook (lesson 1.5).
    expect(_slot('wait').whyChips.any((w) => w.correct && w.textBn.contains('আর্থ আগে')), isTrue);
    expect(_slot('wait').whyChips.any((w) => !w.correct && w.textBn.contains('হুক আগে')), isTrue);
    // Myths 1 and 2.
    expect(_safeIds('earthed'), {'own', 'small'});
    expect(_reject('earthed', 'smallbare'), contains('আকার দিয়ে বিপদ মাপা যায় না'));
    expect(_reject('earthed', 'lineonly'), contains('আলাদাভাবে এবং সরাসরি ডিসচার্জ'));
    // Point 4 and pro tip 1: a swollen can comes off the line; no refit
    // before the cause; internal fuses blow unseen.
    expect(_safeIds('patrol'), {'sound', 'bulge', 'cause'});
    expect(_reject('patrol', 'leak'), allOf(contains('বিস্ফোরিত'), contains('বিচ্ছিন্ন')));
    expect(_reject('patrol', 'refuse'), contains('কারণ খুঁজে বের না করে'));
    expect(_reject('patrol', 'outer'), contains('ভেতরে গলে যায়'));
    expect(pack.earnedBn, allOf(contains('5-10 মিনিট'), contains('রডে'), contains('ফোলা')));
  });

  test('the rulings: the wait (M6-6), the live 75 V figure (X6), term rules, lesson words', () {
    // M6-6: the board quotes the lesson's 5-10 minutes; nothing says a bank is
    // safe without the rod, nor a shorter wait.
    for (final l in _allText()) {
      expect(l, isNot(contains('50 ভোল্ট')), reason: '"$l": the live lesson says 75 V (X6)');
      expect(l, isNot(matches(RegExp(r'(?<![\d-])[1-4] মিনিট'))), reason: '"$l": no wait under 5 minutes');
    }
    // The lesson's own words, checked against the live lesson file.
    final c = _lesson()['content'] as Map<String, dynamic>;
    final myths = ((c['myth_buster'] as Map)['myths'] as List).cast<Map<String, dynamic>>();
    expect(pack.myth.rivalLineBn, _norm(myths[0]['myth'] as String), reason: 'myth 1, word for word');
    final reality1 = _norm(myths[0]['reality'] as String);
    expect(reality1, contains('লাইন আর্থ করা সত্ত্বেও ক্যাপাসিটরটি চার্জড থাকতে পারে'));
    expect(_reject('earthed', 'trust'), _myth1Reality);
    final reality2 = _norm(myths[1]['reality'] as String);
    expect(reality2, contains('আকার দিয়ে বিপদ মাপা যায় না'));
    final all = _norm(jsonEncode(c));
    expect(all, contains('শক্তি সঞ্চয়কারী ডিভাইস'));
    expect(all, allOf(contains('10 মিনিটের মধ্যে'), contains('75 ভোল্ট')), reason: 'X6: the live figure');
    expect(all, contains('5-10 মিনিট'));
    expect(all, contains('ঘন ঘন অন-অফ'), reason: 'the lesson\'s word; the board writes ON-OFF (term rule)');
  });

  test('every picture exists (vector scenes from tool/m6_board67_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m6_board67 folder is a card on the board', () {
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

  // The pictures say what the labels say: the bank's switch window, the rod
  // and its earth lead, the open fuses, the swollen can.
  test('the pictures: switch states, the rod on the earth first, the open fuses, the swollen can', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const winOn = 'width="9" height="6" rx="1" fill="#D8402F"'; // the bank switch's ON window
    const winOff = 'width="9" height="6" rx="1" fill="#3E9B4F"'; // its OFF window
    const rod = 'stroke="url(#rod)"';
    const lead = 'stroke="#E8C830" stroke-width="1.8" fill="none" stroke-dasharray="4 4"'; // a rod's earth lead
    const bulged = 'Q111 123 118 106'; // can 2's swollen side
    // Round 3: every card with the bank switched OFF; the rod's earth lead on
    // the spike whenever its hook is up; on the 'norod' card the rod lies.
    for (final o in _slot('wait').options) {
      expect(svg('wait_${o.id}'), contains(winOff), reason: 'wait_${o.id}: the bank switch OFF');
    }
    for (final c in ['wait_rod', 'wait_early']) {
      expect(svg(c), allOf(contains(rod), contains(lead)), reason: '$c: the rod with its earth lead clamped');
    }
    expect(svg('wait_norod'), contains('a14 5 0 1 0'), reason: 'wait_norod: the rod\'s lead lies coiled, unused');
    expect(svg('wait_bare'), contains('r="3" fill="#A86E48"'), reason: 'wait_bare: a bare hand');
    expect(svg('wait_norod'), isNot(contains('r="3" fill="#A86E48"')), reason: 'wait_norod: gloved');
    // Round 4: the line earthed on every card, and the bank's fuses open.
    for (final o in _slot('earthed').options) {
      final b = svg('earthed_${o.id}');
      expect(b, contains('M10 9 L18 17'), reason: 'earthed_${o.id}: the line\'s earth set');
      expect('L111 97'.allMatches(b).length + 'L139 97'.allMatches(b).length + 'L167 97'.allMatches(b).length, 3,
          reason: 'earthed_${o.id}: all three bank fuses dropped open');
    }
    // The line's earth spike, plus the rod's own spike where the rod is up.
    const spike = 'height="4" rx="1" fill="#C9A43A"';
    for (final c in ['earthed_own', 'earthed_small', 'earthed_lineonly']) {
      expect(spike.allMatches(svg(c)).length, 2, reason: "$c: the rod's earth clamp on its own spike");
    }
    for (final c in ['earthed_trust', 'earthed_smallbare']) {
      expect(spike.allMatches(svg(c)).length, 1, reason: '$c: no rod up');
    }
    // Round 5: the swollen can — taken off (switch OFF) on the safe card, left
    // ON and leaking on the trap.
    expect(svg('patrol_bulge'), allOf(contains(bulged), contains(winOff)));
    expect(svg('patrol_leak'), allOf(contains(bulged), contains(winOn), contains('#8A6A1E')));
    expect(svg('patrol_sound'), allOf(isNot(contains(bulged)), contains(winOn)));
    // Pro tip 1's cue: on the 'outer' trap one can is cold (frost, no heat)
    // while the sound card shows every can warm — so the two differ by that
    // cue, not only by the pose.
    const heat = 'stroke="#FF8A3D" stroke-width="1.4"';
    const frost = 'stroke="#6EC3F0"';
    expect(heat.allMatches(svg('patrol_sound')).length, 3, reason: 'patrol_sound: every can warm');
    expect(svg('patrol_sound'), isNot(contains(frost)), reason: 'patrol_sound: no cold can');
    expect(heat.allMatches(svg('patrol_outer')).length, 2, reason: 'patrol_outer: one can without heat');
    expect(svg('patrol_outer'), allOf(contains(frost), contains(winOn)), reason: 'patrol_outer: the cold can, bank ON');
    expect(_opt('patrol', 'outer').labelBn, contains('ঠান্ডা'), reason: 'the label names the cue');
    // Ruling M6-6: on the safe 'cause' card no tool comes near a can — the
    // tester lies in the bag, clear of the cans (x 90-166, y 95-142).
    final testers = RegExp(r'<rect x="([\d.]+)" y="([\d.]+)" width="([\d.]+)" height="([\d.]+)" rx="[\d.]+" fill="#F2B630"')
        .allMatches(svg('patrol_cause'))
        .toList();
    expect(testers, isNotEmpty, reason: 'patrol_cause: the tester is in the bag');
    for (final m in testers) {
      final x = double.parse(m[1]!), y = double.parse(m[2]!);
      final w = double.parse(m[3]!), h = double.parse(m[4]!);
      final overCans = x < 166 && x + w > 90 && y < 142 && y + h > 95;
      expect(overCans, isFalse, reason: 'patrol_cause: no tester at a can (rod not on)');
    }
    expect(svg('patrol_cause'), isNot(contains(rod)), reason: 'patrol_cause: no stick up at the bank');
    // Round 1: the bank switched in on every card.
    for (final o in _slot('pf').options) {
      expect(svg('pf_${o.id}'), contains('width="8" height="6" rx="1" fill="#D8402F"'), reason: 'pf_${o.id}: bank ON');
    }
  });

  test('the careless lineman says the lesson\'s first myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'লাইন তো বন্ধ এবং আর্থ করা আছে, তাই ক্যাপাসিটর ব্যাংকে কাজ করতে কোনো ভয় নেই।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'a bank after the fuse stays charged');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('ফিউজের পরের ব্যাংকে')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board67Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M6Board67Lines.newRivalLines, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M6Board67Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 16 trap reasons, 17 right
    // chips, 3 myth chips, the closing line — pinned so none is forgotten.
    final g = M6Board67Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    expect(g, contains(_myth1Reality));
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
    expect(g.length, 1 + 5 + 16 + 17 + 3 + 1);
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
      expect(save.rungProgress[_rung], isNot('cleared'), reason: '7 of 12 clean = 58% < 60%');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a deadly-class trap (hand on a can, the line earthed, no rod) teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      // Every round before 'earthed', played clean.
      for (final s in pack.slots.takeWhile((s) => s.id != 'earthed')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is myth 1's reality, word for word.
      final earthed = _slot('earthed');
      await _settleHand(t, 'pick', {'trust'}, 'earthed: the no-rod trap (all three traps are in every hand)');
      await tapBoardCard(t, _dealt('pick', {'trust'}));
      await _pumpUntil(t, () => find.text(_myth1Reality).evaluate().isNotEmpty, what: 'the lesson\'s myth 1 reality');
      for (final w in earthed.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.7', ladderIndex: _ladder, pack: pack, muted: true),
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

LearnBoardOption _opt(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option);

String _reject(String slot, String option) => _opt(slot, option).rejectBn;

Set<String> _safeIds(String slot) => {for (final o in _slot(slot).options) if (o.correct) o.id};
