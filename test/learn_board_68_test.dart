// Module 6 lesson 6.8 picture board ("অটো-রিক্লোজার ও সেকশনালাইজার: লাইনের
// স্মার্ট ব্রেন", rung 6.8/learn, pack learn_6_8): its content follows the
// board's rules, the live lesson and the Module 6 rulings (X1 PTW → tester →
// earth before the climb, the owner's term rules), every picture exists and
// no colour or backdrop marks the safe card (in any hand the dealer can make),
// the rival's myth is the lesson's own and every new line is listed for
// recording, a clean play (picks, reasons, the rival's myth) clears the rung,
// a miss on every round fails it (the board's strike-out), a deadly-class
// trap (climbing a recloser line with no PTW and no Non-Reclose) teaches with
// the lesson's own words (boards have no freeze: kit design), the gesture
// hint sweeps without pressing, and the board waits quietly once dealt.
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

const pack = learnBoardPack68;
const _artDir = 'assets/game/art/m6_board68';
const _rung = '6.8/learn';
const _ladder = 171; // m6 starts at 150; three rungs per lesson, 6.8/learn the 22nd

/// Lesson 6.8 myth 1's reality, its last sentence (the trap 'handle' and the
/// deadly-class flow below say it word for word).
const _myth1Reality = '\'Non-Reclose\' মোড নিশ্চিত না করে এবং PTW না নিয়ে কোনো রিক্লোজারযুক্ত লাইনকে নিরাপদ ভাবা যাবে না।';

/// Has read lesson 6.8 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_8', '6.8']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.8', ladderIndex: _ladder, pack: pack, muted: true),
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

/// Lesson 6.8 from the live lesson file, with য় ড় ঢ় written as base + nukta
/// (the app's form; owner's unicode rule) and Bengali digits as English.
Map<String, dynamic> _lesson() {
  final all = File('tool/all_training_chapters_bn.json').readAsStringSync();
  Map<String, dynamic>? hit;
  void walk(Object? o) {
    if (hit != null) return;
    if (o is Map<String, dynamic>) {
      if (o['id'] == '6.8' && o['content'] is Map) {
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

  test('the lesson 6.8 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '6.8');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 6.8 entry.
    final wired = learnBoardPackFor('6.8');
    if (wired != null) expect(wired, same(learnBoardPack68));
    expect(pack.badgeBn, 'যন্ত্র গুরু', reason: 'the lesson\'s own badge');
    expect(pack.titleBn, 'অটো-রিক্লোজার ও সেকশনালাইজার: লাইনের স্মার্ট ব্রেন');
    // Five rounds (owner, after Wave A).
    expect(pack.slots.map((s) => s.id), ['temp', 'perm', 'count', 'nonrec', 'pro']);
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

  test('the lesson\'s points: temporary and permanent faults, the count, Non-Reclose, the pro tips', () {
    // Point 1: a temporary fault — trip, wait, reclose; no needless patrol;
    // 3-4 tries before lock-out on a permanent one.
    expect(_safeIds('temp'), {'trip', 'wind'});
    expect(_reject('temp', 'patrol'), contains('অপ্রয়োজনীয় পেট্রোলিং'));
    expect(_reject('temp', 'lock1'), contains('3-4 বার'));
    expect(_reject('temp', 'sopen'), contains('লক-আউট হওয়ার ঠিক আগে'));
    // Point 2: the faulty branch cut off; the healthy ones lit on the last close.
    expect(_safeIds('perm'), {'s1', 's3'});
    expect(_reject('perm', 'endless'), contains('3-4 বার'));
    expect(_reject('perm', 'wrongs'), contains('ফল্টি শাখাটিকেই'));
    expect(_reject('perm', 'alldark'), contains('সুস্থ শাখাগুলো বিদ্যুৎ পায়'));
    // Point 2 and myth 2: counts only while the recloser is open, stays as it
    // was, opens on a dead line before lock-out; never breaks fault current,
    // never melts.
    expect(_safeIds('count'), {'one', 'dead'});
    expect(_opt('count', 'one').labelBn, allOf(contains('রিক্লোজার OFF'), contains('লাগানো')));
    expect(_opt('count', 'dead').labelBn, allOf(contains('ডেড'), contains('আর্ক ছাড়াই')));
    expect(_reject('count', 'arc'), contains('ফল্ট কারেন্টকে বাধা দেয় না'));
    expect(_reject('count', 'self'), contains('নিজের ফল্ট সনাক্ত করার ক্ষমতা নেই'));
    expect(_reject('count', 'first'), contains('আগের মতোই থাকে'));
    expect(_reject('count', 'melt'), contains('লোড ব্রেক'));
    // Point 3 and the safety protocol: Non-Reclose asked for with the PTW and
    // confirmed; the switch / Hot Line Tag; then tester and earths (X1).
    expect(_safeIds('nonrec'), {'radio', 'switch', 'earth'});
    expect(_opt('nonrec', 'radio').labelBn, allOf(contains('PTW'), contains('Non-Reclose')));
    expect(_opt('nonrec', 'switch').labelBn, allOf(contains('ON'), contains('Hot Line Tag')));
    expect(_opt('nonrec', 'earth').labelBn, allOf(contains('নিশ্চিত'), contains('টেস্টারে 0'), contains('আর্থ')));
    expect(_reject('nonrec', 'dark'), contains('চেষ্টার মাঝখানে'));
    expect(_reject('nonrec', 'auto'), contains('সতর্কবার্তা ছাড়াই'));
    // Pro tips 1-3 and point 3: the counter, the hanging handle, the setting;
    // the manual handle only on a dead line.
    expect(_safeIds('pro'), {'counter', 'handle', 'setting'});
    expect(_reject('pro', 'manual'), allOf(contains('\'ডেড\' লাইনে'), contains('লাগানো')));
    // Owner term rule: closing is «লাগানো»; «বন্ধ» on a switch reads as OFF.
    for (final l in _allText()) {
      expect(l, isNot(contains('খোলা-বন্ধ')), reason: '"$l": closing is লাগানো');
    }
    // The handle shows lock-out, but never stands in for PTW + Non-Reclose.
    expect(pack.earnedBn, contains('তবু PTW আর Non-Reclose ছাড়া ওঠা নয়'));
    expect(_reject('pro', 'deadonly'), contains('হ্যান্ডেল সাধারণত নিচে ঝোলে'));
    expect(_reject('pro', 'wait'), contains('ফল্ট ব্রেকিং ডিভাইস নয়'));
    expect(_slot('pro').whyChips.any((w) => w.correct && w.textBn.contains('কাউন্টার')), isTrue);
    expect(_slot('pro').whyChips.any((w) => w.correct && w.textBn.contains('কতবার চেষ্টা')), isTrue);
    expect(pack.earnedBn, allOf(contains('PTW'), contains('Non-Reclose'), contains('হ্যান্ডেল')));
  });

  test('the rulings and the lesson\'s words, checked against the live lesson file', () {
    final c = _lesson()['content'] as Map<String, dynamic>;
    final myths = ((c['myth_buster'] as Map)['myths'] as List).cast<Map<String, dynamic>>();
    expect(pack.myth.rivalLineBn, _norm(myths[0]['myth'] as String), reason: 'myth 1, word for word');
    expect(_norm(myths[0]['reality'] as String), endsWith(_myth1Reality));
    expect(_reject('nonrec', 'handle'), _myth1Reality);
    final reality2 = _norm(myths[1]['reality'] as String);
    expect(reality2, allOf(contains('ফল্ট কারেন্টকে বাধা দেয় না'), contains('লোড ব্রেক'), contains('ফল্ট ব্রেকিং ডিভাইস নয়')));
    final all = _norm(jsonEncode(c));
    for (final fact in [
      '3-4 বার চেষ্টা',
      'অপ্রয়োজনীয় পেট্রোলিং',
      'নিজের কোনো ফল্ট সনাক্ত করার ক্ষমতা নেই',
      'আগের মতোই থাকে',
      'লক-আউট হওয়ার ঠিক আগের মুহূর্তে',
      'নিচের দিকে ঝুলে থাকে',
      'অপারেশন কাউন্টার',
      'কতবার চেষ্টা করবে',
      'অবশ্যই \'ডেড\' লাইনে করতে হবে',
      'Hot Line Tag',
      'PTW নেওয়ার সময়',
    ]) {
      expect(all, contains(fact), reason: 'the board\'s fact "$fact" is in the live lesson');
    }
    // X1 (6.8a/b climb after Non-Reclose + PTW): the climb card shows the
    // tester and the earths too; X7: nothing says 'safety belt'.
    for (final l in _allText()) {
      expect(l, isNot(contains('সেফটি বেল্ট')), reason: '"$l": full-body harness, never a belt (X7)');
      expect(l, isNot(contains('মারাত্মক')), reason: '"$l": boards teach without the lesson\'s alarm word');
    }
    // No wait time in seconds: the lesson gives none (spec unsupported[0]).
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp(r'\d+ সেকেন্ড'))), reason: '"$l": no invented wait time');
    }
  });

  test('every picture exists (vector scenes from tool/m6_board68_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m6_board68 folder is a card on the board', () {
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

  // The pictures say what the labels say: lit and dark windows, the
  // recloser's ON / OFF flag, the Hot Line Tag, the coiled earth set.
  test('the pictures: lit or dark houses, the recloser flag, the tag, the earths', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const lit = 'width="10" height="9" fill="#FFE08A"';
    const dark = 'width="10" height="9" fill="#2E3A46"';
    const flagOff = 'rx="1.5" fill="#3E9B4F"';
    const flagOn = 'rx="1.5" fill="#D8402F"'; // also the Hot Line Tag
    const coil = 'a12 4.5 0 1 0';
    // Round 1: the lights stay on after a temporary fault.
    for (final c in ['temp_trip', 'temp_wind']) {
      expect(svg(c), allOf(contains(lit), isNot(contains(dark))), reason: '$c: every window lit');
    }
    for (final c in ['temp_patrol', 'temp_lock1']) {
      expect(svg(c), allOf(contains(dark), isNot(contains(lit))), reason: '$c: everything dark');
    }
    expect(svg('temp_sopen'), allOf(contains(lit), contains(dark)), reason: 'temp_sopen: one branch dark');
    // Round 2: one branch dark and the rest lit on the safe cards.
    for (final c in ['perm_s1', 'perm_s3']) {
      expect(dark.allMatches(svg(c)).length, 1, reason: '$c: only the faulty branch dark');
      expect(lit.allMatches(svg(c)).length, 2, reason: '$c: two healthy branches lit');
    }
    for (final c in ['perm_wrongs', 'perm_alldark']) {
      expect(svg(c), isNot(contains(lit)), reason: '$c: everything dark');
    }
    // Round 3: the recloser's flag reads OFF while the sectionalizer counts.
    for (final c in ['count_one', 'count_dead', 'count_first', 'count_melt']) {
      expect(svg(c), contains(flagOff), reason: '$c: the recloser OFF');
    }
    for (final c in ['count_arc', 'count_self']) {
      expect(svg(c), allOf(contains(flagOn), isNot(contains(flagOff))), reason: '$c: the recloser ON');
    }
    // Round 4: the Hot Line Tag on the ON switch; no tag at auto; the earths
    // set on the climb card, the set lying coiled on the 'dark' card.
    expect(svg('nonrec_switch'), contains(flagOn), reason: 'nonrec_switch: the Hot Line Tag');
    expect(svg('nonrec_auto'), isNot(contains(flagOn)), reason: 'nonrec_auto: no tag');
    expect(svg('nonrec_dark'), contains(coil), reason: 'nonrec_dark: the earth set unused');
    expect(svg('nonrec_earth'), isNot(contains(coil)), reason: 'nonrec_earth: the earths are on');
    // Round 5: lock-out read by the hanging handle; the 'deadonly' card has
    // the houses dark and the handle up.
    expect(svg('pro_handle'), contains(dark));
    expect(svg('pro_deadonly'), contains(dark));
    expect(svg('pro_counter'), contains(lit));
  });

  test('the careless lineman says the lesson\'s first myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'লাইনটা তো ট্রিপ করে আছে, রিক্লোজার নিশ্চয়ই লক-আউট হয়ে গেছে। কাজ করতে কোনো ভয় নেই।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the recloser may be mid-cycle');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('চেষ্টার মাঝখানে')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board68Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M6Board68Lines.newRivalLines, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M6Board68Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 16 trap reasons, 16 right
    // chips, 3 myth chips, the closing line — pinned so none is forgotten.
    final g = M6Board68Lines.newGuideLines;
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
    expect(g.length, 1 + 5 + 16 + 16 + 3 + 1);
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

    testWidgets('a deadly-class trap (climbing with no PTW and no Non-Reclose) teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      // Every round before 'nonrec', played clean.
      for (final s in pack.slots.takeWhile((s) => s.id != 'nonrec')) {
        await _cleanRound(t, s);
      }
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is myth 1's reality, word for word.
      final nonrec = _slot('nonrec');
      await _settleHand(t, 'pick', {'handle'}, 'nonrec: the handle-down climb (all three traps are in every hand)');
      await tapBoardCard(t, _dealt('pick', {'handle'}));
      await _pumpUntil(t, () => find.text(_myth1Reality).evaluate().isNotEmpty, what: 'the lesson\'s myth 1 reality');
      for (final w in nonrec.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.8', ladderIndex: _ladder, pack: pack, muted: true),
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
