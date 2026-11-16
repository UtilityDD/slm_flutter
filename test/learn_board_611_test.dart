// Module 6 lesson 6.11 picture board ("আর্থিং সিস্টেম: অদৃশ্য অভিভাবক",
// rung 6.11/learn, pack learn_6_11): its content follows the board's rules,
// the live lesson and the Module 6 rulings (M6-1 one earth rule, M6-13 the
// earth tester and the 5 ohm band, the owner's term rules), every picture
// exists and no colour or backdrop marks the safe card (in any hand the dealer
// can make), the rival's myth is the lesson's own and every new line is
// listed for recording, a clean play (picks, reasons, the rival's myth) clears
// the rung, a miss on every round fails it (the board's strike-out), a
// deadly-class trap (a pole's earth wire cut, the line running: R27) teaches
// with the lesson's own words (boards have no freeze: kit design), the
// gesture hint sweeps without pressing, and the board waits quietly once
// dealt.
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
import 'package:slm_flutter/features/game/m6_earth_pit_test.dart' show kEarthTesterBn;
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

const pack = learnBoardPack611;
const _artDir = 'assets/game/art/m6_board611';
const _rung = '6.11/learn';
const _ladder = 180; // m6 starts at 150; 6.11/learn is orderInModule 30

/// Lesson 6.11 myth 1's reality, whole, with its danger words (the trap
/// 'cut' and the deadly-class flow below say it word for word: ruling M6-1).
const _myth1Reality = 'মারাত্মক ভুল। লাইন স্বাভাবিক অবস্থায় চলবে, কিন্তু ফল্টের সময় আর্থিং কাজ না করলে সার্কিট ব্রেকার ট্রিপ করবে না এবং একটি ছোট সমস্যা একটি বড় বিপর্যয় বা প্রাণহানির কারণ হয়ে দাঁড়াবে।';

/// Has read lesson 6.11 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['6_11', '6.11']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.11', ladderIndex: _ladder, pack: pack, muted: true),
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

/// Lesson 6.11 from the live lesson file.
Map<String, dynamic> _lesson() {
  final all = File('tool/all_training_chapters_bn.json').readAsStringSync();
  Map<String, dynamic>? hit;
  void walk(Object? o) {
    if (hit != null) return;
    if (o is Map<String, dynamic>) {
      if (o['id'] == '6.11' && o['content'] is Map) {
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
  var t = s.replaceAll('\u09DF', '\u09AF\u09BC').replaceAll('\u09DC', '\u09A1\u09BC').replaceAll('\u09DD', '\u09A2\u09BC');
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

  test('the lesson 6.11 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '6.11');
    // Registered in learn_board_models.dart (learnBoardPackFor) by the
    // director at wiring; until then the lookup has no 6.11 entry.
    final wired = learnBoardPackFor('6.11');
    if (wired != null) expect(wired, same(learnBoardPack611));
    expect(pack.badgeBn, 'যন্ত্র গুরু', reason: 'the lesson\'s own badge');
    expect(pack.titleBn, 'আর্থিং সিস্টেম: অদৃশ্য অভিভাবক');
    // Five rounds (owner, after Wave A): the spec's substation round left.
    expect(pack.slots.map((s) => s.id), ['role', 'type', 'joint', 'pit', 'test']);
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
      expect(l, isNot(contains('মৃত')), reason: '"$l": ডেড, not মৃত');
      expect(l, isNot(matches(RegExp('(?<![ঀ-৿])(অন|অফ)(?![ঀ-৿])'))), reason: '"$l": ON / OFF in English letters');
      for (final bad in ['এলটি', 'এইচটি', 'কেভি']) {
        expect(l, isNot(contains(bad)), reason: '"$l": LT / HT / kV in English letters');
      }
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": "AB বন্ধ" reads as the AB OFF');
      expect(l, isNot(matches(RegExp('[\u09DC\u09DD\u09DF]'))), reason: '"$l": base + nukta');
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

  test('the lesson\'s points: the two roles, pipe and plate, the joint, the pit, soil and the test', () {
    // Section 1 and pro tip 1: equipment and system earthing; double earthing.
    expect(_safeIds('role'), {'body', 'neutral', 'double'});
    expect(_reject('role', 'unearthed'), allOf(contains('লো-রেজিস্ট্যান্স পথ'), contains('ট্রিপ করবে না')));
    expect(_reject('role', 'la'), contains('আর্থিং ছাড়া কোনো সুরক্ষা ডিভাইস (ফিউজ, ব্রেকার, LA)'));
    // Section 2: GI pipe 2.5-3 m upright; the 60 x 60 cm plate.
    expect(_safeIds('type'), {'pipe', 'plate'});
    expect(_opt('type', 'pipe').labelBn, allOf(contains('GI'), contains('2.5-3 মিটার'), contains('খাড়া')));
    expect(_opt('type', 'plate').labelBn, contains('60 x 60'));
    expect(_reject('type', 'rod'), contains('এটা একটা বিজ্ঞান'));
    expect(_reject('type', 'flat'), contains('উল্লম্বভাবে'));
    expect(_reject('type', 'stub'), allOf(contains('বিশাল পৃষ্ঠতলের'), contains('2.5-3 মিটার')));
    // Section 3, pro tip 2, section 4: tight clean joints, brass or
    // stainless, brushed and greased; the strip never cut or torn.
    expect(_safeIds('joint'), {'brass', 'weld', 'grease'});
    expect(_reject('joint', 'iron'), contains('পিতল বা স্টেইনলেস স্টিলের'));
    expect(_reject('joint', 'twist'), contains('বহুগুণ'));
    expect(_reject('joint', 'torn'), contains('কাটা, ছেঁড়া বা অতিরিক্ত মরিচা'));
    // Sections 3 and 4: charcoal and salt, water on a dry day, chamber and lid.
    expect(_safeIds('pit'), {'salt', 'water', 'lid'});
    expect(_reject('pit', 'sand'), contains('কাঠকয়লা ও লবণ'));
    expect(_reject('pit', 'broken'), contains('কংক্রিটের চেম্বারে'));
    expect(_reject('pit', 'dry'), contains('আর্থ রেজিস্ট্যান্স কমে'));
    // Pro tips 3 and 4: rocky or sandy soil; the earth tester within 5 ohm.
    expect(_safeIds('test'), {'ok', 'multi', 'bento'});
    expect(_reject('test', 'one'), contains('একাধিক ইলেক্ট্রোড বা বেন্টোনাইট'));
    expect(_reject('test', 'skip'), contains('স্বাস্থ্য পরীক্ষার সবচেয়ে নির্ভরযোগ্য উপায়'));
    expect(_reject('test', 'high'), contains('5 ওহম'));
    expect(pack.earnedBn, allOf(contains('টাইট জোড়'), contains('5 ওহমের মধ্যে')));
  });

  test('deadly-class traps (M6-1: a broken earth path left in service) say the danger', () {
    // The cut earth wire, the LA with no lead, the unearthed body and the torn
    // strip each name a death, not just "cannot work properly"; the slips
    // (rusty nut, sand-only pit ...) do not.
    const deadly = {'role': ['unearthed', 'cut', 'la'], 'joint': ['torn']};
    deadly.forEach((slot, ids) {
      for (final id in ids) {
        expect(_reject(slot, id), contains('প্রাণহানি'), reason: '$slot/$id: deadly class');
      }
    });
    for (final s in pack.slots) {
      for (final o in s.options) {
        if (o.correct || (deadly[s.id]?.contains(o.id) ?? false)) continue;
        expect(o.rejectBn, isNot(contains('প্রাণহানি')), reason: '${s.id}/${o.id}: a slip, not deadly');
      }
    }
  });

  test('the rulings: the earth tester (M6-13), the 5 ohm band, no substation wording, lesson words', () {
    // M6-13: the instrument's on-screen name is one constant, 'আর্থ টেস্টার';
    // the lesson's 'আর্থ মেগার' never shows.
    expect(M6Board611Lines.earthTester, 'আর্থ টেস্টার');
    // One word for the board and the Do level (do_6_11_a): never two copies.
    expect(M6Board611Lines.earthTester, kEarthTesterBn);
    for (final l in _allText()) {
      expect(l, isNot(contains('মেগার')), reason: '"$l": the tool is ${M6Board611Lines.earthTester} on screen');
      // The plate wording leaves out 'সাবস্টেশনে' (item spec); the
      // substation round left the board.
      expect(l, isNot(contains('সাবস্টেশন')), reason: '"$l": no substation on this board');
    }
    expect(_opt('test', 'ok').labelBn, contains(M6Board611Lines.earthTester));
    expect(_opt('test', 'skip').labelBn, contains(M6Board611Lines.earthTester));
    // Readings: a safe card reads within 5 ohm, a trap above it — never in
    // the 5–8 ohm grey zone (scene deal of do_6_11_a).
    final ohm = RegExp(r'(\d+(?:\.\d+)?) ওহম');
    for (final s in pack.slots) {
      for (final o in s.options) {
        for (final m in ohm.allMatches(o.labelBn)) {
          final v = double.parse(m.group(1)!);
          expect(v > 5 && v < 8, isFalse, reason: '${o.id}: $v ohm is in the grey zone');
          expect(v <= 5, o.correct, reason: '${o.id}: $v ohm and ${o.correct ? 'safe' : 'a trap'}');
        }
      }
    }
    // The lesson's own words, checked against the live lesson file.
    final c = _lesson()['content'] as Map<String, dynamic>;
    final myths = ((c['myth_buster'] as Map)['myths'] as List).cast<Map<String, dynamic>>();
    expect(pack.myth.rivalLineBn, _norm(myths[1]['myth'] as String), reason: 'myth 2, word for word');
    // The reject is the whole reality, word for word.
    expect(_norm(myths[0]['reality'] as String), _myth1Reality);
    expect(_reject('role', 'cut'), _myth1Reality);
    final all = _norm(jsonEncode(c));
    expect(all, contains('সবচেয়ে নির্ভরযোগ্য উপায়'));
    expect(all, contains('পিতল বা স্টেইনলেস স্টিলের নাট-বল্টু'));
    expect(all, contains('60cm x 60cm'));
    expect(all, contains('2.5-3 মিটার'));
    expect(all, contains('কাঠকয়লা এবং লবণের স্তর'));
    expect(all, contains('আর্থ মেগার'), reason: 'the lesson\'s word; the board shows the constant (M6-13)');
  });

  test('every picture exists (vector scenes from tool/m6_board611_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m6_board611 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => '$_artDir/${f.uri.pathSegments.last}')
        .toSet();
    expect(onDisk, used, reason: 'no unused art, no stray files (the APK ships the folder), no missing art');
  });

  test('every card in a round draws its own picture (no two SVG bodies alike)', () {
    for (final s in pack.slots) {
      final seen = <String, String>{};
      for (final o in s.options) {
        final body = File(o.asset).readAsStringSync().split('</defs>').last;
        expect(seen[body], isNull, reason: '${s.id}: ${o.id} draws the same picture as ${seen[body]}');
        seen[body] = o.id;
      }
    }
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

  // The pictures say what the labels say: an earth lead where the label has
  // one and none where it has none, two pits for double earthing, the lid,
  // the layers, the tester's reading.
  test('the pictures: earth leads, the two pits, the pit\'s fill and lid, the tester', () {
    String svg(String card) => File('$_artDir/$card.svg').readAsStringSync().split('</defs>').last;
    const earthLead = 'stroke="#E8C830"';
    const lid = 'fill="#B7B9B4"';
    const charcoal = 'fill="#2A2622"';
    const sand = 'fill="#D8C08A"';
    const lcd = 'fill="url(#lcd)"';
    // Round 1: the lead on the bonded body, the neutral, both pits and the
    // cut pole; none on the new breaker or under the LAs.
    for (final c in ['role_body', 'role_neutral', 'role_double', 'role_cut']) {
      expect(svg(c), contains(earthLead), reason: '$c: an earth lead');
    }
    for (final c in ['role_unearthed', 'role_la']) {
      expect(svg(c), isNot(contains(earthLead)), reason: '$c: no earth at all');
    }
    expect(lid.allMatches(svg('role_double')).length, 2, reason: 'role_double: two separate pits');
    expect(lid.allMatches(svg('role_neutral')).length, 1);
    // The cut pole: the lead stops and starts again (two pieces).
    expect(earthLead.allMatches(svg('role_cut')).length, 2, reason: 'role_cut: the earth wire in two pieces');
    // Round 4: layers of charcoal and salt except on the sand-only pit; the
    // lid on, set aside on the dry day, broken on the trap.
    expect(svg('pit_sand'), allOf(contains(sand), isNot(contains(charcoal))));
    for (final c in ['pit_salt', 'pit_water', 'pit_lid']) {
      expect(svg(c), allOf(contains(charcoal), contains(lid)), reason: '$c: layers and a lid');
    }
    expect(svg('pit_broken'), isNot(contains('rx="1.5" $lid')), reason: 'pit_broken: no whole lid');
    // Round 5: the tester shows a reading on 'ok' and 'high'; shut on 'skip'.
    for (final c in ['test_ok', 'test_high']) {
      expect(svg(c), contains(lcd), reason: '$c: the earth tester reads');
    }
    expect(svg('test_skip'), isNot(contains(lcd)), reason: 'test_skip: the tester shut in its case');
    expect(svg('test_skip'), contains('#B9851A'), reason: 'test_skip: the case is there');
    // Every test card has the remedy sack (bentonite), so its presence tells nothing.
    for (final o in _slot('test').options) {
      expect(svg('test_${o.id}'), contains('fill="#A7A9A0"'), reason: 'test_${o.id}: the bentonite sack');
    }
  });

  test('the careless lineman says the lesson\'s second myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'যেকোনো একটি লোহার রড মাটিতে পুঁতে দিলেই ভালো আর্থিং হয়ে যায়।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'earthing needs the right material, length and method');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('GI বা কপার')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M6Board611Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M6Board611Lines.newRivalLines, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M6Board611Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 15 trap reasons, 17 right
    // chips, 3 myth chips, the closing line — pinned so none is forgotten.
    final g = M6Board611Lines.newGuideLines;
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
    expect(g.length, 1 + 5 + 15 + 17 + 3 + 1);
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

    testWidgets('a deadly-class trap (the pole\'s earth wire cut, the line running) teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is myth 1's reality, word for word (R27, ruling M6-1).
      final role = _slot('role');
      await _settleHand(t, 'pick', {'cut'}, 'role: the cut-wire trap (all three traps are in every hand)');
      await tapBoardCard(t, _dealt('pick', {'cut'}));
      await _pumpUntil(t, () => find.text(_myth1Reality).evaluate().isNotEmpty, what: 'the lesson\'s myth 1 reality');
      for (final w in role.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '6.11', ladderIndex: _ladder, pack: pack, muted: true),
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
