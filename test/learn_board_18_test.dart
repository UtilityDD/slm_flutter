// Ladder step 22 — the lesson 1.8 picture board ("মাঠে আগুন"): its content
// follows the board's rules and the lesson's points, every picture exists and
// no colour or backdrop marks the safe card, the rival's myth is the lesson's
// own and in his recorded voice, and the board waits quietly once the first
// hand is dealt.
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
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';

const pack = learnBoardPack18;
const _artDir = 'assets/game/art/fire_board';

/// Has read lesson 1.8 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['1_8', '1.8']));
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

  test('step 22 is the lesson 1.8 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '1.8');
    expect(learnBoardPackFor('1.8'), same(learnBoardPack18), reason: 'the ladder opens this board for step 22');
    expect(pack.badgeBn, 'সুরক্ষা কবচ');
    expect(pack.slots.map((s) => s.id), ['class', 'water', 'gauge', 'pass', 'stand']);
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
      expect(safe, greaterThanOrEqualTo(1), reason: '${s.id}: a safe picture');
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
      for (final bad in ['ডকেট্', 'ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
        expect(l, isNot(contains(bad)), reason: '"$l": house word for "$bad"');
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
    }
  });

  test('the lesson\'s points: classes, no water on B and C, power off, gauge, PASS, wind and way out', () {
    expect(_reject('class', 'grass'), contains('Class A'));
    expect(_reject('class', 'wood'), contains('Class A'));
    expect(_reject('class', 'panel'), contains('Class C'));
    expect(_slot('class').whyChips.any((w) => w.correct && w.textBn.contains('দাহ্য তরল')), isTrue);
    expect(_reject('water', 'oil_water'), contains('ভাসে'));
    expect(_reject('water', 'panel_water'), contains('পরিবাহী'));
    expect(_reject('water', 'tr_hose'), contains('নিষিদ্ধ'));
    expect(_slot('water').options.firstWhere((o) => o.id == 'panel_off').correct, isTrue, reason: 'power off first');
    expect(_slot('water').options.firstWhere((o) => o.id == 'panel_off').labelBn, contains('Power OFF'));
    expect(_slot('water').whyChips.any((w) => w.correct && w.textBn.contains('নিষিদ্ধ')), isTrue);
    expect(_reject('gauge', 'low'), contains('সবুজ'));
    expect(_reject('gauge', 'high'), contains('সবুজ'));
    expect(_reject('gauge', 'used'), contains('Refill'));
    expect(_reject('pass', 'flame'), contains('গোড়ায়'));
    expect(_reject('pass', 'pin'), contains('Pin'));
    expect(_reject('pass', 'stop'), contains('সম্পূর্ণ'));
    expect(_reject('stand', 'wind_face'), contains('বাতাস পেছনে'));
    expect(_reject('stand', 'cornered'), contains('কোণঠাসা'));
    expect(_reject('stand', 'hero'), contains('Fire Brigade'));
    // Labels a worker reads: ABC on the powder cylinder, ON / OFF at the switch.
    expect(File('$_artDir/water_oil_abc.svg').readAsStringSync(), contains('>ABC<'));
    expect(File('$_artDir/water_panel_off.svg').readAsStringSync(), contains('>OFF<'));
  });

  test('every picture exists (vector scenes from tool/fire_board_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/'));
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test('every SVG in the fire_board folder is a card on the board', () {
    final used = {for (final s in pack.slots) for (final o in s.options) o.asset};
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => '$_artDir/${f.uri.pathSegments.last}')
        .toSet();
    expect(onDisk, used, reason: 'no unused art and no missing art');
  });

  // The playbook (section 4) and the step-10 review: the right option must
  // not stand out. In each round every gradient and colour drawn on a safe
  // card (sky, backdrop, rod, clamp, cable, chain, spark, figure) must also
  // be drawn on at least one trap — only the act may tell them apart, never
  // a colour, a backdrop or a detail only safe cards carry. (The tools not
  // in use stay on the fire point, so the cylinder's ABC blue is on traps too.)
  test('no colour or backdrop gives the safe card away', () {
    final used = RegExp(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b');
    Set<String> tokens(String asset) {
      final svg = File(asset).readAsStringSync();
      return used.allMatches(svg.split('</defs>').last).map((m) => m.group(0)!).toSet();
    }

    for (final s in pack.slots) {
      final safe = <String>{}, traps = <String>{};
      for (final o in s.options) {
        (o.correct ? safe : traps).addAll(tokens(o.asset));
      }
      expect(safe.difference(traps), isEmpty, reason: '${s.id}: drawn only on safe cards');
    }
    // One backdrop for every card of a round.
    final backdrop = RegExp(r'<rect width="200" height="220" fill="(url\(#\w+\))"');
    for (final s in pack.slots) {
      final backs = {for (final o in s.options) backdrop.firstMatch(File(o.asset).readAsStringSync())!.group(1)};
      expect(backs, hasLength(1), reason: '${s.id}: one backdrop for every card');
    }
  });

  // The step-13 review: a round-wide check misses a hand where the safe card
  // is the only one on its backdrop or the only one drawing a colour. So go
  // through EVERY hand the
  // dealer can make (one safe card + any cards-1 traps; afterMiss hands are
  // of the same shape): the safe card's backdrop must be on a trap in that
  // hand, and every colour or gradient it draws must be drawn by a trap in
  // that same hand.
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

  // The step-22 review: in the PASS round only traps drew the tall fire, so
  // "pick a low fire" halved the hand. Where every card shows the same fire
  // (all rounds but the class round, which asks WHICH thing burns, and the
  // gauge close-ups), the safe card's fire sizes (its glow) must be on a trap
  // in every possible hand.
  test('in every possible hand, the safe card\'s fire size is on a trap too', () {
    final glow = RegExp(r'<ellipse cx="[^"]*" cy="[^"]*" rx="([^"]*)" ry="([^"]*)" fill="url\(#glow\)"/>');
    Set<String> sizes(String asset) =>
        glow.allMatches(File(asset).readAsStringSync()).map((m) => '${m.group(1)}x${m.group(2)}').toSet();
    for (final s in pack.slots.where((s) => s.id != 'class' && s.id != 'gauge')) {
      final traps = s.options.where((o) => !o.correct).toList();
      expect(traps.length, s.cards - 1, reason: '${s.id}: every hand holds every trap, so a trap-wide check is per hand');
      final trapSizes = {for (final o in traps) ...sizes(o.asset)};
      for (final safe in s.options.where((o) => o.correct)) {
        expect(sizes(safe.asset), isNotEmpty, reason: '${s.id}/${safe.id}: a fire on the card');
        expect(sizes(safe.asset).difference(trapSizes), isEmpty, reason: '${s.id}/${safe.id}: a fire size only safe cards show');
      }
    }
    // PASS: one safe card and one trap on the tall fire, the rest on the low one.
    final pass = _slot('pass');
    final bySize = <String, Set<bool>>{};
    for (final o in pass.options) {
      for (final z in sizes(o.asset)) {
        (bySize[z] ??= <bool>{}).add(o.correct);
      }
    }
    for (final e in bySize.entries) {
      expect(e.value, {true, false}, reason: 'pass: fire ${e.key} on both a safe card and a trap');
    }
  });

  test('the careless lineman says the lesson\'s myth in his own recorded voice', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'ছোট আগুন, একটু পরেই নিজে থেকে নিভে যাবে।', reason: 'lesson 1.8 myth buster, word for word');
    expect(m.rivalLineBn, isNot(contains('বাঁচিয়ে')), reason: 'the refill myth is step 24\'s coworker push');
    expect(m.believeNoIsCorrect, isTrue, reason: 'a fire grows fast — act while it is small');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('Action')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    for (final line in [m.tauntBn, m.rivalLineBn, m.exitBn, ...FireBoardLines.recorded]) {
      final clip = LearnVoice.resolve(line, rival: true);
      expect(clip, isNotNull, reason: 'rival clip for "$line"');
      expect(File('assets/$clip').lengthSync(), greaterThan(4000), reason: '$clip is a real recording');
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
            home: const LearnBoardRunnerPage(rungId: '1.8/learn', lessonId: '1.8', ladderIndex: 21, pack: pack, muted: true),
          ),
        ));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // Lesson 1.8 has no day card yet; if one is added, a first play opens on it.
        final day = lessonDays[pack.lessonId];
        if (day != null) expect(find.text('দিন ${day.day}'), findsOneWidget, reason: 'a first play opens on the day card');
        // Long enough for the guide's intro and first ask to finish talking
        // (the talk animation rebuilds while he speaks).
        for (var i = 0; i < 260; i++) {
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
