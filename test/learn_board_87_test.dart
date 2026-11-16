// Module 8 lesson 8.7 picture board ("ট্যারিফ অর্ডার (Tariff Order): বিদ্যুতের দামের হিসাব",
// rung 8.7/learn, pack learn_8_7): its content follows the board's rules, the
// live lesson 8.7 text and the Module 8 rulings (M8-1 slip-only, M8-10 silent
// figures, M8-11 plain names, M8-14 DRAFT wording, M8-21 five rounds, X3 live
// text, X6 term rules), every picture exists and no colour or backdrop gives
// the safe card away (in any hand the dealer can make), the rival's myth is
// the lesson's own and every new line is listed for recording, a clean play
// (picks, reasons, the rival's myth) clears the rung, a miss on every round
// fails it (the board's strike-out), a wrong picture costs its round only
// (slip: the board goes on), the gesture hint sweeps without pressing, and
// the board waits quietly once dealt.
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
import 'package:slm_flutter/features/game/learn_board_pack87.dart';
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

const pack = learnBoardPack87;
const _artDir = 'assets/game/art/m8_board87';
const _rung = '8.7/learn';

/// Lesson 8.7's first myth, word for word (live text, ruling X3).
const _myth1 = 'ডিজিটাল মিটার বেশি ঘোরে, তাই বিল বেশি আসে।';

/// Has read lesson 8.7 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['8_7', '8.7']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.7', ladderIndex: 0, pack: pack, muted: true),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() {
    LearnDealer.resetMemory();
    LessonMissTally.resetAll();
    SpokenOnce.resetForTest();
  });

  test('the lesson 8.7 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '8.7');
    expect(pack.titleBn, 'ট্যারিফ অর্ডার (Tariff Order): বিদ্যুতের দামের হিসাব');
    // The live lesson's badge (ruling M8-16).
    expect(pack.badgeBn, 'জরুরী রেগুলেশন (WBERC ফোকাস)');
    // Five rounds (ruling M8-21): the factory round left the board; do_8_7_b
    // plays it.
    expect(pack.slots.map((s) => s.id), ['closed', 'slab', 'cat', 'farm', 'extra']);
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
    for (final l in _allText()) {
      expect(l, isNot(matches(RegExp('[০-৯]'))), reason: '"$l": English digits on screen');
      expect(l, isNot(matches(RegExp('[ড়ঢ়য়]'))), reason: '"$l": য় ড় ঢ় as base + nukta');
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        expect(l, isNot(matches(RegExp('(?<![ঀ-৿])$bad'))), reason: '"$l": house word for "$bad"');
      }
    }
  });

  test('the live term rules: kVA and LT in English letters, ডেড not মৃত, AB লাগানো not AB বন্ধ', () {
    for (final l in _allText()) {
      expect(l, isNot(contains('কেভিএ')), reason: '"$l": kVA in English letters');
      expect(l, isNot(contains('এলটি')), reason: '"$l": LT in English letters');
      expect(l, isNot(matches(RegExp('মৃত|মরা'))), reason: '"$l": ডেড, not মৃত/মরা');
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": AB বন্ধ reads as OFF');
    }
  });

  test('no rupee amounts on the board (the live text gives none here)', () {
    for (final l in _allText()) {
      expect(l, isNot(contains('₹')), reason: '"$l": no rupee amount');
      expect(l, isNot(contains('টাকা')), reason: '"$l": no rupee amount');
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

  test('the lesson\'s points: fixed charge, slabs, categories, agriculture, MVCA and rent', () {
    // Closed house: the fixed charge is due with the house shut (section 1).
    expect(_safeIds('closed'), {'fixed', 'load'});
    expect(_reject('closed', 'strike'), contains('বিদ্যুৎ ব্যবহার করুক বা না করুক'));
    expect(_reject('closed', 'meter'), contains('পরিকাঠামো মেইনটেন্যান্সের খরচ'));
    expect(_reject('closed', 'walk'), contains('বাড়ি বন্ধ ছিল তাও বিল এসেছে'));
    // Slabs (pro tip 1): the first 102 units cheap, the upper units dearer.
    expect(_safeIds('slab'), {'stairs', 'bill'});
    expect(_reject('slab', 'flat'), allOf(contains('স্ল্যাব অনুযায়ী'), contains('102 ইউনিট সস্তা')));
    expect(_reject('slab', 'upside'), contains('উপরের দিকের ইউনিটগুলোর দাম বেশি'));
    expect(_reject('slab', 'reader'), contains("WBERC-এর 'ট্যারিফ অর্ডার'-এ লেখা থাকে"));
    // Categories (section 2): a wrong category is Section 126.
    expect(_safeIds('cat'), {'home', 'shop'});
    expect(_reject('cat', 'shop_dom'), allOf(contains('সেকশন 126'), contains('বাড়ির রেট')));
    expect(_reject('cat', 'wire'), contains('আইনত আলাদা'));
    expect(_reject('cat', 'nolook'), contains('Type of Consumer'));
    // Agriculture (section 2): the lowest, subsidised rate; a car wash is a crime.
    expect(_safeIds('farm'), {'paddy', 'veg'});
    expect(_reject('farm', 'carwash'), contains('বড় অপরাধ'));
    expect(_reject('farm', 'shop'), allOf(contains('ভর্তুকি যুক্ত'), contains('সেকশন 126')));
    expect(_reject('farm', 'blind'), contains('Type of Consumer'));
    // MVCA (pro tip 3) and meter rent (myth 2): government rules, not tricks.
    expect(_safeIds('extra'), {'mvca', 'rent'});
    expect(_reject('extra', 'fraud'), allOf(contains('কারচুপি নয়'), contains('সরকারি নিয়ম')));
    expect(_reject('extra', 'price'), contains('রক্ষণাবেক্ষণের খরচ'));
    expect(_reject('extra', 'rentcut'), contains('ভাড়ার লাইন কাটলেও ভাড়া যায় না'));
    expect(_slot('extra').whyChips.any((w) => w.correct && w.textBn.contains('MVCA')), isTrue);
  });

  test('the trap reasons quote the live lesson 8.7 (tool/all_training_chapters_bn.json)', () {
    final live = _norm(jsonEncode(_lesson87()));
    // The key phrases the trap reasons rely on, as the live text writes them.
    const quoted = [
      'লোড বরাদ্দ রাখার জন্য',
      'মেইনটেন্যান্সের খরচ',
      'কোম্পানির পরিকাঠামো',
      'বাড়ি বন্ধ ছিল তাও বিল এসেছে',
      'স্ল্যাব অনুযায়ী বাড়ে',
      'প্রথম 102 ইউনিট সস্তা',
      'উপরের দিকের ইউনিটগুলোর দাম বেশি',
      "WBERC-এর 'ট্যারিফ অর্ডার'-এ লেখা থাকে",
      'বাড়ির রেট দোকানের রেটের চেয়ে কম',
      'সেকশন 126',
      'আইনত আলাদা',
      'Type of Consumer',
      'গাড়ি ধোয়ার গ্যারেজ',
      'বড় অপরাধ',
      'ভর্তুকি যুক্ত',
      'মিটার রিডারের কারচুপি নয়',
      'সরকারি নিয়ম',
      'রক্ষণাবেক্ষণের খরচ ওই ভাড়ার মধ্যেই ধরা থাকে',
    ];
    for (final q in quoted) {
      expect(live, contains(q), reason: 'the live lesson 8.7 says "$q"');
    }
    for (final s in pack.slots) {
      for (final o in s.options.where((o) => !o.correct)) {
        expect(quoted.any(o.rejectBn.contains), isTrue, reason: '${s.id}/${o.id}: "${o.rejectBn}" quotes the live text');
      }
    }
    expect(live, contains(_myth1), reason: 'the lesson\'s first myth, word for word');
    expect(live, contains(pack.myth.rivalLineBn));
  });

  test('the Module 8 rulings: slip-only (M8-1), no factory round (M8-21), silent figures (M8-10)', () {
    // Every trap here is a slip: a wrong picture costs its round only.
    for (final s in pack.slots) {
      expect(s.cards, 4, reason: '${s.id}: a hand of four');
    }
    // Consumers, speakers and bystanders are silent: the only spoken lines are
    // the guide's and the coworker's (no caption figure has a voice line).
    expect(M8Board87Lines.toRecord, isNot(contains(pack.introBn)));
    expect(M8Board87Lines.newGuideLines, isNot(contains(pack.myth.tauntBn)));
    // M8-14: every spoken line is listed; the myth's words are the lesson's.
    expect(pack.myth.rivalLineBn, _myth1);
  });

  test('every picture exists (vector scenes from tool/m8_board87_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every file in the m8_board87 folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'))
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

  test('the careless lineman says the lesson\'s first myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, _myth1);
    expect(m.believeNoIsCorrect, isTrue, reason: 'a correct reading is not a crime');
    expect(m.whyChips.where((w) => w.correct).map((w) => w.textBn),
        everyElement(anyOf(contains('সঠিক মাপে'), contains('মাপা'), contains('রেকর্ড'))));
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M8Board87Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    expect(M8Board87Lines.newRivalLines, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M8Board87Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 15 trap reasons, 15 right
    // chips, 3 myth chips, the closing line — pinned so none is forgotten.
    // The cat and farm 'Type of Consumer' reasons are one line (one clip), so 39.
    final g = M8Board87Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    for (final s in pack.slots) {
      expect(g, contains(s.promptBn));
    }
    expect(g.length, 39);
    expect(g.toSet().length, g.length, reason: 'each line is recorded once');
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

    testWidgets('a wrong picture (the MVCA-as-trick trap) teaches with the lesson\'s words; the board goes on, no reason deck', (t) async {
      final c = await _open(t);
      // Every round before the last one (extra), played clean.
      for (final s in pack.slots.takeWhile((s) => s.id != 'extra')) {
        await _cleanRound(t, s);
      }
      // A slip costs the round's mark only (ruling M8-1): the trap's reason
      // is the lesson's own words, and no reason deck opens for a wrong card.
      final extra = _slot('extra');
      await _settleHand(t, 'pick', {'fraud'}, 'extra: the MVCA-as-trick trap (all three traps are in every hand)');
      await tapBoardCard(t, _dealt('pick', {'fraud'}));
      await _pumpUntil(t, () => find.text(_reject('extra', 'fraud')).evaluate().isNotEmpty, what: 'the lesson\'s MVCA rule');
      for (final w in extra.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.7', ladderIndex: 0, pack: pack, muted: true),
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

/// Lesson 8.7 from the live text file (read-only; ruling X3).
Map<String, dynamic> _lesson87() {
  final raw = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync());
  Map<String, dynamic>? find(Object? o) {
    if (o is Map) {
      if (o['id'] == '8.7') return o.cast<String, dynamic>();
      for (final v in o.values) {
        final r = find(v);
        if (r != null) return r;
      }
    } else if (o is List) {
      for (final v in o) {
        final r = find(v);
        if (r != null) return r;
      }
    }
    return null;
  }

  final lesson = find(raw);
  expect(lesson, isNotNull, reason: 'lesson 8.7 is in the live text');
  return lesson!;
}

/// The lesson file writes য় ড় ঢ় as single code points and Bangla digits;
/// the app uses letter + nukta and English digits. Compare in one form.
String _norm(String s) {
  var out = s
      .replaceAll('য়', 'য়')
      .replaceAll('ড়', 'ড়')
      .replaceAll('ঢ়', 'ঢ়');
  const bn = '০১২৩৪৫৬৭৮৯';
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(bn[i], '$i');
  }
  return out;
}

LearnBoardOption _opt(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option);

String _reject(String slot, String option) => _opt(slot, option).rejectBn;

Set<String> _safeIds(String slot) => {for (final o in _slot(slot).options) if (o.correct) o.id};
