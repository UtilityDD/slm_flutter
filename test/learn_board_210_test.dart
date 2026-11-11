// The lesson 2.10 picture board ("হাতিয়ারের যত্ন ও রক্ষণাবেক্ষণ"): its
// content follows the board's rules and the lesson's points, every picture
// exists and no colour or backdrop marks the safe card (in any hand the dealer
// can make), the rival's myth is the lesson's own, and the board waits quietly
// once the first hand is dealt.
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
import 'package:slm_flutter/features/game/learn_board_deal.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_board_pack210.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';

const pack = learnBoardPack210;
const _artDir = 'assets/game/art/m2_board210';

/// Has read lesson 2.10 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['2_10', '2.10']));
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(LearnDealer.resetMemory);

  test('the lesson 2.10 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '2.10');
    // Wired by the director (learnBoardPackFor in learn_board_models.dart).
    final wired = learnBoardPackFor('2.10');
    if (wired != null) expect(wired, same(learnBoardPack210), reason: 'the ladder opens this board for 2.10/learn');
    expect(pack.titleBn, 'হাতিয়ারের যত্ন ও রক্ষণাবেক্ষণ');
    expect(pack.badgeBn, 'হাতিয়ারের ওস্তাদ');
    expect(pack.slots.map((s) => s.id), ['daily', 'rust', 'meter', 'retire', 'bag']);
    expect(pack.slots.length, inInclusiveRange(4, 6));
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
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'গ্লাভ্স']) {
        expect(l, isNot(contains(bad)), reason: '"$l": house word for "$bad"');
      }
      // জল, not পানি — as a word: "কোম্পানি" (the lesson's myth) is fine.
      expect(l, isNot(matches(RegExp('(^|[^\u0980-\u09FF])পানি'))), reason: '"$l": house word জল');
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

  test('the lesson\'s points: 5-minute routine, rust, meters, retiring, the tool bag', () {
    // Daily: dry cloth, never wet in the box, inspect insulated handles, a place for each.
    expect(_reject('daily', 'wet'), contains('ভেজা'));
    expect(_reject('daily', 'heap'), contains('নির্দিষ্ট ঘর'));
    expect(_reject('daily', 'greasy'), contains('শুকনো কাপড়ে'));
    expect(_reject('daily', 'unchecked'), contains('ইনসুলেটেড হাতলের'));
    expect(_slot('daily').whyChips.any((w) => w.correct && w.textBn.contains('5 মিনিট')), isTrue);
    // Rust: no oil on insulation, keep dry, a rusted spanner slips, extra grease (the 2nd myth).
    expect(_reject('rust', 'oil_handle'), contains('ইনসুলেশনের ওপর না লাগে'));
    expect(_reject('rust', 'damp'), contains('আর্দ্রতা'));
    expect(_reject('rust', 'slip'), contains('পিছলে'));
    expect(_reject('rust', 'grease'), allOf(contains('ধুলো'), contains('গ্রিপ')));
    // Meters: switch off, coil gently, battery out for long storage; calibration is yearly.
    expect(_reject('meter', 'on'), contains('বন্ধ করুন'));
    expect(_reject('meter', 'tight'), contains('আলতো করে'));
    expect(_reject('meter', 'leak'), contains('ব্যাটারি খুলে'));
    expect(_slot('meter').whyChips.firstWhere((w) => w.textBn.contains('ক্যালিব্রেশন')).correct, isFalse,
        reason: 'calibration "once, when new" is the wrong reason (lesson: at least once a year)');
    // Retire: each of the lesson's signs, and label / make useless.
    expect(_reject('retire', 'tape'), contains('ফাটল'));
    expect(_reject('retire', 'wide_jaw'), contains('চওড়া'));
    expect(_reject('retire', 'bent_tip'), contains('ডগা'));
    expect(_reject('retire', 'hyd_leak'), contains('তেল লিক'));
    expect(_slot('retire').options.firstWhere((o) => o.id == 'tag').labelBn, contains('ব্যবহারের অযোগ্য'));
    expect(_slot('retire').whyChips.any((w) => w.correct && w.textBn.contains('ভুল করে আবার')), isTrue);
    // Pro tip 1: a tool bag on the pole, not a toolbox — tools can fall from above.
    expect(_reject('bag', 'toolbox'), contains('টুলব্যাগ'));
    expect(_reject('bag', 'in_hand'), contains('ক্যানভাস বা চামড়ার'));
    expect(_slot('bag').whyChips.any((w) => w.correct && w.textBn.contains('পড়ার ঝুঁকি')), isTrue);
  });

  test('every picture exists (vector scenes from tool/m2_board210_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/${s.id}_'), reason: 'a card is named after its round');
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the m2_board210 folder is a card on the board', () {
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

  // The playbook (section 4) and the step-10 review: the right option must
  // not stand out. A round shares one backdrop and one stage (the depot bench,
  // or the pole, ladder and harnessed worker). Every gradient and colour
  // drawn on a safe card must also be drawn on at least one trap; only the act
  // may tell them apart.
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

  // The step-13 review: a round-wide check misses a hand where the safe card
  // is the only one on its backdrop or the only one with a colour. So go
  // through EVERY hand the dealer can make (one safe card + any cards-1
  // traps; afterMiss hands are of the same shape).
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

  test('the careless lineman says the lesson\'s myth; new lines are listed for recording', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'ভালো কোম্পানির টুল কিনলে আর যত্ন করার দরকার নেই, ওগুলো সারাজীবন চলে।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'even the dearest tool is ruined by neglect');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('অবহেলায়')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    // The exit is already in his recorded voice; the rest wait for recording.
    final exit = LearnVoice.resolve(m.exitBn, rival: true);
    expect(exit, isNotNull);
    expect(File('assets/$exit').lengthSync(), greaterThan(4000));
    for (final line in [m.tauntBn, m.rivalLineBn]) {
      if (LearnVoice.resolve(line, rival: true) == null) {
        expect(ToolCareBoardLines.toRecord, contains(line), reason: '"$line" is listed for recording');
      }
    }
  });

  group('board on screen', () {
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
            home: const LearnBoardRunnerPage(rungId: '2.10/learn', lessonId: '2.10', ladderIndex: 24, pack: pack, muted: true),
          ),
        ));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // Lesson 2.10 has no day card yet; if one is added, a first play opens on it.
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
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;
