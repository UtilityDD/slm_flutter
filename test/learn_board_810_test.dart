// Module 8 lesson 8.10 picture board ("রেগুলেশন এবং আপনি: ফিল্ডে প্রয়োগ",
// rung 8.10/learn, pack learn_8_10): its content follows the live lesson text
// (pro tip 1 says AND; myth 2's reality), the Module 8 rulings (M8-17 tester
// before the earth, M8-21 five rounds, M8-6 bribe = slip, M8-8 reason cards),
// every picture exists and no colour or backdrop marks the safe card (in any
// hand the dealer can make), the coworker's myth is the lesson's own and every
// new line is listed for recording, a clean play (picks, reasons, the rival's
// myth) clears the rung, a miss on every round fails it (the board's
// strike-out), the climb trap teaches with the lesson's words (boards have no
// freeze: kit design, as board 6.3), the gesture hint sweeps without pressing,
// and the board waits quietly once dealt.
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
import 'package:slm_flutter/features/game/learn_board_pack810.dart';
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

const pack = learnBoardPack810;
const _artDir = 'assets/game/art/m8_board810';
const _rung = '8.10/learn';

/// Live lesson 8.10 pro tip 1, word for word (AND, not OR; rulings M8-17, X1).
const _permitAndEarth = 'লিখিত পারমিট হাতে না পাওয়া এবং নিজের হাতে আর্থিং না করা পর্যন্ত পোল-এ উঠবেন না।';

/// Live lesson 8.10 myth 2's reality, word for word (ruling X3).
const _myth2Reality = "সুরক্ষার নিয়ম মানার দায় শুধু অফিসারের নয়—যে নিজের হাতে কাজটি করছে (আপনি), তারও। আপনি 'না' বলতে পারেন যদি কাজটা নিরাপদ না মনে হয়।";

/// Has read lesson 8.10 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['8_10', '8.10']));
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
    builder: (_) => const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.10', ladderIndex: 0, pack: pack, muted: true),
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

  test('the lesson 8.10 board with the live rounds, trimmed to five (ruling M8-21)', () {
    expect(pack.lessonId, '8.10');
    // The lesson's own badge (WBERC focus), as the 8.x lessons name it.
    expect(pack.badgeBn, 'জরুরী রেগুলেশন (WBERC ফোকাস)');
    expect(pack.titleBn, 'রেগুলেশন এবং আপনি: ফিল্ডে প্রয়োগ');
    // rounds[1] (the PTW carbon copy) left the board; the rest keep their order.
    expect(pack.slots.map((s) => s.id), ['log', 'climb', 'customer', 'bribe', 'circular']);
    for (final s in pack.slots) {
      expect(s.promptBn, isNotEmpty, reason: '${s.id}: a round says its own situation');
      expect(s.promptBn, isNot(contains('কার্বন')), reason: '${s.id}: the dropped carbon-copy round is gone');
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
      // «ডেড», never «মৃত» or «মরা».
      expect(l, isNot(matches(RegExp('মৃত|মরা'))), reason: '"$l": «ডেড», not «মৃত»');
      // LT, HT, 11 kV and kVA stay in English letters.
      expect(l, isNot(matches(RegExp('এলটি|এইচটি|কেভি'))), reason: '"$l": LT / HT / kV in English');
      // Switch and line states are ON / OFF; the words অন / অফ never stand alone.
      expect(l, isNot(matches(RegExp('(?<![ঀ-৿])(অন|অফ)(?![ঀ-৿])'))), reason: '"$l": ON / OFF, not অন / অফ');
      // «AB লাগানো», never «AB বন্ধ».
      expect(l, isNot(matches(RegExp(r'AB (সুইচ )?বন্ধ'))), reason: '"$l": closing an AB is «AB লাগানো»');
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

  test('the lesson\'s points: logbook times and the read-twice, the PTW and the earth, the customer, the bribe, the circular', () {
    LearnBoardOption opt(String slot, String id) => pack.slots.firstWhere((s) => s.id == slot).options.firstWhere((o) => o.id == id);
    Set<String> safeIds(String slot) => {for (final o in pack.slots.firstWhere((s) => s.id == slot).options) if (o.correct) o.id};

    // Logbook: no page with only a signature; the times and the work written.
    expect(safeIds('log'), {'full', 'reread'});
    expect(opt('log', 'blank').rejectBn, contains('প্রমাণ নেই'));
    expect(opt('log', 'notimes').rejectBn, contains('শাটডাউন নিলেন, কখন ছাড়লেন, কী কাজ করলেন'));
    expect(opt('log', 'rush').rejectBn, contains('দুবার পড়ে দেখুন'));

    // Climb: the permit and the own earth (AND); the phone 'line OFF' is no permit.
    expect(safeIds('climb'), {'ptw', 'earth'});
    expect(pack.slots.firstWhere((s) => s.id == 'climb').promptBn, contains('লাইন OFF আছে'));
    expect(opt('climb', 'earth').labelBn, allOf(contains('0 দেখে'), contains('আর্থিং')), reason: 'the tester 0 V before the earth (M8-17)');
    expect(opt('climb', 'phone').rejectBn, allOf(contains("ফোনে 'লাইন OFF আছে' বললেই"), contains('বিশ্বাস করবেন না')));
    expect(opt('climb', 'mate').rejectBn, _permitAndEarth, reason: 'live pro tip 1 says AND (ruling X3)');
    expect(opt('climb', 'mate').rejectBn, isNot(contains('বা নিজের')), reason: 'never the old OR');
    expect(opt('climb', 'shrug').rejectBn, _myth2Reality, reason: 'live myth 2 reality, word for word');

    // Customer: the uniform is the company's face; the SoP covers manner.
    expect(safeIds('customer'), {'explain', 'listen'});
    expect(opt('customer', 'shout').rejectBn, contains('ইউনিফর্ম পরা অবস্থায় আপনি কোম্পানির প্রতিনিধি'));
    expect(opt('customer', 'away').rejectBn, contains('ব্যবহারের কথাও বলে'));
    expect(opt('customer', 'hot').rejectBn, contains('মুখে হাসি বা শান্ত ভাব'));

    // Bribe: cash for a hook or a bypass is never help (slip, ruling M8-6).
    expect(safeIds('bribe'), {'palm', 'walk'});
    expect(opt('bribe', 'takehook').rejectBn, allOf(contains('শুধু দুর্নীতি নয়'), contains('নিজের পায়ে কুড়ুল')));
    expect(opt('bribe', 'bypass').rejectBn, allOf(contains('বাইপাস করে দেওয়া দুর্নীতি'), contains('আইন আপনাকে ছাড়বে না')));
    expect(opt('bribe', 'pliers').rejectBn, contains('অবৈধ কাজে কোনোভাবেই সাহায্য নয়'));

    // Circular: the notice board and the training meeting keep the rules current.
    expect(safeIds('circular'), {'board', 'meeting'});
    expect(opt('circular', 'pastby').rejectBn, contains('অফিসের নোটিশ বোর্ড থেকে'));
    expect(opt('circular', 'oldpaper').rejectBn, contains('ট্রেনিং বা ইউনিয়ন মিটিং'));
    expect(opt('circular', 'jugaad').rejectBn, contains('জেলে পাঠাবে'));
  });

  test('the careless coworker says the lesson\'s first myth, word for word; every new line is listed', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'আইন-কানুন সব বইয়ের পাতায়, মাঠে \'জুগাড়\' (Jugaad) দিয়েই কাজ চলে।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'the jugaad myth is wrong: the standard way is the safe way');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('লগবুক আর PTW')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    final clip = LearnVoice.resolve(m.exitBn, rival: true);
    expect(clip, isNotNull, reason: 'rival clip for "${m.exitBn}"');
    expect(File('assets/$clip').lengthSync(), greaterThan(4000));
    expect(M8Board810Lines.toRecord, unorderedEquals([m.tauntBn, m.rivalLineBn]));
    for (final l in M8Board810Lines.toRecord) {
      final c = LearnVoice.resolve(l, rival: true);
      if (c != null) expect(File('assets/$c').existsSync(), isTrue, reason: l);
    }
    // The guide's new lines: intro, 5 prompts, 15 trap reasons, 15 right
    // chips, 3 myth chips, the closing line — pinned so none is forgotten.
    final g = M8Board810Lines.newGuideLines;
    expect(g, contains(pack.introBn));
    expect(g, contains(pack.earnedBn));
    expect(g, contains(_permitAndEarth));
    for (final s in pack.slots) {
      expect(g, contains(s.promptBn));
    }
    expect(g.length, 1 + 5 + 15 + 15 + 3 + 1);
  });

  test('every picture exists (vector scenes from tool/m8_board810_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
  });

  test('every file in the m8_board810 folder is a card on the board', () {
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

  test('the climb pictures: every card has the crew\'s tester and earth lead; only the earth card clamps', () {
    String svg(String card) => File('$_artDir/climb_$card.svg').readAsStringSync().split('</defs>').last;
    const testerWindow = 'width="10" height="6" rx="1" fill="#F4F1E6"';
    const earthLead = 'stroke="#3E9B4F"';
    for (final c in ['ptw', 'earth', 'phone', 'mate', 'shrug']) {
      expect(svg(c), contains(testerWindow), reason: 'climb_$c: the tester lies at the pole foot');
      expect(svg(c), contains(earthLead), reason: 'climb_$c: the earth lead lies on the ground');
    }
    expect(svg('earth'), contains('<g id="clamp">'), reason: 'the earth is clamped to the pole (after the tester 0 V)');
    for (final c in ['ptw', 'phone', 'mate', 'shrug']) {
      expect(svg(c), isNot(contains('<g id="clamp">')), reason: 'climb_$c: no earth clamped');
    }
  });

  test('the pictures show the logbook times on the safe cards and their absence on the traps', () {
    String svg(String card) => File('$_artDir/log_$card.svg').readAsStringSync().split('</defs>').last;
    const timeMark = 'x1="108" y1="124" x2="122" y2="124"'; // the first time entry on the right page
    expect(svg('full'), contains(timeMark), reason: 'log_full: times written');
    expect(svg('reread'), contains(timeMark), reason: 'log_reread: times written');
    expect(svg('blank'), isNot(contains(timeMark)), reason: 'log_blank: no times');
    expect(svg('notimes'), isNot(contains(timeMark)), reason: 'log_notimes: the time columns are empty');
  });

  test('the Module 8 rulings: no DO, no mat, rod or carbon-copy round; the climb\'s right pictures are the permit and the own earth', () {
    for (final l in _allText()) {
      for (final no in ['ড্রপ আউট', 'ডিও', 'DO ফিউজ', 'ম্যাট', 'অপারেটিং রড', 'কার্বন কপি']) {
        expect(l, isNot(contains(no)), reason: '"$l": no DO, mat, rod or carbon-copy round on this board');
      }
    }
    // Every wrong picture on the climb round is a deadly-class act (R1): none
    // of them is a way to go up; the permit and the own earth are the only ones.
    final climb = pack.slots.firstWhere((s) => s.id == 'climb');
    expect(climb.options.where((o) => o.correct).map((o) => o.id).toSet(), {'ptw', 'earth'});
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
      expect(save.rungProgress[_rung], isNot('cleared'), reason: 'a miss on every round is below the pass mark');
      expect(save.bestMarkByRung[_rung], lessThan(kLessonPassMark));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the deadly-class climb trap (a phone \'line OFF\') teaches with the lesson\'s words; no reason deck', (t) async {
      final c = await _open(t);
      // The logbook round played clean.
      await _cleanRound(t, pack.slots.first);
      // Boards have no freeze (kit design): the trap costs the round's ◆ and
      // its reason is the live lesson's own words.
      final climb = pack.slots.firstWhere((s) => s.id == 'climb');
      final phone = climb.options.firstWhere((o) => o.id == 'phone');
      await _settleHand(t, 'pick', {'phone'}, 'climb: the phone trap (all three traps are in every hand)');
      await tapBoardCard(t, _dealt('pick', {'phone'}));
      await _pumpUntil(t, () => find.text(phone.rejectBn).evaluate().isNotEmpty, what: 'the lesson\'s words for the phone trap');
      for (final w in climb.whyChips) {
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
              home: const LearnBoardRunnerPage(rungId: _rung, lessonId: '8.10', ladderIndex: 0, pack: pack, muted: true),
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
