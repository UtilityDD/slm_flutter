// Ladder step 7 — the lesson 1.3 picture board ("পোলের ভাষা"): its content
// follows the board's rules and the lesson's points, every picture exists and
// is used, the rival's myth is the lesson's own and in his recorded voice, and
// the board (played straight from the pack) waits quietly at the first question.
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
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';

const _pack = learnBoardPack13;
const _artDir = 'assets/game/art/pole_board/';

/// Has read lesson 1.3 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['1_3', '1.3']));
}

void _muteAudio() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> ok(MethodCall _) async => 1;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), ok);
  }
}

Finder get _cards => find.byWidgetPredicate((w) => w.runtimeType.toString() == '_AnimatedChoiceCard');

var _rebuilds = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(LearnDealer.resetMemory);

  group('content', () {
    test('step 7 is the lesson 1.3 board', () {
    expect(learnBoardPackFor('1.3'), same(learnBoardPack13), reason: 'the ladder opens this board for step 7');
      expect(_pack.lessonId, '1.3');
      expect(_pack.titleBn, contains('পোলের'));
      expect(_pack.slots.length, inInclusiveRange(4, 6));
      expect(_pack.slots.map((s) => s.id).toSet().length, _pack.slots.length);
      expect(_pack.introBn, isNotEmpty);
      expect(_pack.earnedBn, isNotEmpty);
    });

    test('every round: 4–6 scene pictures, safe ones and enough traps, each trap says why', () {
      for (final s in _pack.slots) {
        final safe = s.options.where((o) => o.correct).length;
        final traps = s.options.where((o) => !o.correct).length;
        expect(s.options.length, inInclusiveRange(4, 6), reason: '${s.id}: 4–6 pictures');
        expect(safe, greaterThanOrEqualTo(1), reason: '${s.id}: a safe picture');
        expect(traps, greaterThanOrEqualTo(s.cards - 1), reason: '${s.id}: enough traps for a hand');
        expect(s.options.map((o) => o.id).toSet().length, s.options.length, reason: '${s.id}: unique ids');
        expect(s.promptBn, isNotEmpty, reason: '${s.id}: its own situation');
        for (final o in s.options) {
          expect(o.scene, isTrue, reason: '${s.id}/${o.id}: a whole scene, edge to edge');
          expect(o.labelBn, isNotEmpty, reason: '${s.id}/${o.id}');
        }
        for (final o in s.options.where((o) => !o.correct)) {
          expect(o.rejectBn, isNotEmpty, reason: '${s.id}/${o.id}: a trap says why');
          expect(o.rejectBn.split('\n'), hasLength(1), reason: '${s.id}/${o.id}: one line');
        }
      }
    });

    test('a dealt hand has exactly one safe picture, and plays differ', () {
      final d = LearnDealer(math.Random(7));
      for (final s in _pack.slots) {
        final hands = <String>{};
        for (var run = 0; run < 10; run++) {
          final hand = d.deal(s.id, s.options, count: s.cards);
          expect(hand.where((p) => p.correct), hasLength(1), reason: s.id);
          expect(hand.map((p) => p.id).toSet(), hasLength(s.cards), reason: '${s.id}: different cards');
          hands.add((hand.map((p) => p.id).toList()..sort()).join(','));
        }
        expect(hands.length, greaterThan(1), reason: '${s.id}: a fresh deal each play');
      }
    });

    test('reason libraries: >= 2 right, >= 5 wrong, all about the same length', () {
      for (final s in _pack.slots) {
        expectLibrary(s.id, [for (final w in s.whyChips.where((w) => w.correct)) w.textBn],
            [for (final w in s.whyChips.where((w) => !w.correct)) w.textBn]);
        expectSameLength(s.id, [for (final w in s.whyChips) w.textBn]);
        expect(s.whyChips.map((w) => w.id).toSet().length, s.whyChips.length, reason: '${s.id}: unique ids');
      }
      final m = _pack.myth.whyChips;
      expectLibrary('myth', [for (final w in m.where((w) => w.correct)) w.textBn], [for (final w in m.where((w) => !w.correct)) w.textBn]);
      expectSameLength('myth', [for (final w in m) w.textBn]);
    });

    test("the lesson's points: walk round first, base, sound test, scan, hardware", () {
      final ids = _pack.slots.map((s) => s.id).toList();
      expect(ids.first, 'walk', reason: 'the 360° walk comes first');
      expect(ids, containsAll(['walk', 'base', 'sound', 'scan', 'hardware']));
      LearnBoardSlot slot(String id) => _pack.slots.firstWhere((s) => s.id == id);
      // Sound test: PCC solid vs hollow, steel clear vs dull.
      final sound = slot('sound');
      expect(sound.options.firstWhere((o) => o.id == 'pcc_solid').correct, isTrue);
      expect(sound.options.firstWhere((o) => o.id == 'steel_ring').correct, isTrue);
      expect(sound.options.firstWhere((o) => o.id == 'pcc_hollow').correct, isFalse);
      expect(sound.options.firstWhere((o) => o.id == 'steel_dull').correct, isFalse);
      // Scan: a hairline crack is a warning, not "normal".
      expect(slot('scan').options.firstWhere((o) => o.id == 'hairline').correct, isFalse);
      // Scan: the right reasons fit both safe cards (clean PCC, clean steel),
      // so none names one pole type or one type's fault (playbook §4).
      for (final w in slot('scan').whyChips.where((w) => w.correct)) {
        for (final only in ['PCC', 'স্টিল', 'রড', 'চুলের']) {
          expect(w.textBn, isNot(contains(only)), reason: 'scan reason "${w.textBn}" fits one pole type only');
        }
      }
      // Base: standing water — only the lesson's wording (wet, slippery; report it).
      expect(slot('base').options.firstWhere((o) => o.id == 'water').rejectBn, isNot(contains('ভিত')));
      // Base: a lean can break under the body's weight (lesson 1.3 §1).
      expect(slot('base').options.firstWhere((o) => o.id == 'lean').rejectBn, contains('ভার'));
    });

    test('every picture exists, is a vector scene, and every card in the folder is used', () {
      final used = <String>{};
      for (final s in _pack.slots) {
        for (final o in s.options) {
          expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
          expect(o.asset, startsWith(_artDir));
          expect(o.asset, endsWith('.svg'));
          used.add(o.asset);
        }
      }
      final onDisk = Directory(_artDir).listSync().whereType<File>().map((f) => '$_artDir${f.uri.pathSegments.last}').toSet();
      expect(onDisk, used, reason: 'no unused files in $_artDir (tool/pole_board_art.py writes exactly these)');
      expect(File(_pack.myth.bodyAsset).existsSync(), isTrue);
    });

    test("the rival's myth is the lesson's, and false", () {
      expect(_pack.myth.rivalLineBn, contains('স্টিলের পোল'));
      expect(_pack.myth.rivalLineBn, contains('ভাঙে না'));
      expect(_pack.myth.believeNoIsCorrect, isTrue, reason: 'rust at ground level breaks a steel pole');
      expect(_pack.myth.dangerHints, isNotEmpty);
    });

    test('the careless lineman says every line in his own recorded voice', () {
      for (final line in [_pack.myth.tauntBn, _pack.myth.rivalLineBn, _pack.myth.exitBn, ...PoleBoardLines.recorded]) {
        final clip = LearnVoice.resolve(line, rival: true);
        expect(clip, isNotNull, reason: 'not recorded: $line');
        expect(File('assets/$clip').existsSync(), isTrue, reason: clip);
      }
    });
  });

  group('board', () {
    setUpAll(() {
      _muteAudio();
      ZlFx.setMuted(true);
    });
    setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the first question (${reduce ? 'reduce' : 'anim'})', (tester) async {
        tester.view.physicalSize = const Size(720, 1600);
        tester.view.devicePixelRatio = 2.0;
        tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(ProviderScope(
          overrides: [authProvider.overrideWith(_TestAuth.new)],
          child: MaterialApp(
            theme: SlmTheme.night(),
            home: const LearnBoardRunnerPage(rungId: '1.3/learn', lessonId: '1.3', ladderIndex: 6, pack: _pack, muted: true),
          ),
        ));
        // Day card, intro line, deal, first ask (muted lines still hold for their reading time).
        for (var i = 0; i < 165; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        expect(_cards, findsNWidgets(_pack.slots.first.cards), reason: 'the first hand is dealt');
        expect(find.text(_pack.slots.first.promptBn), findsWidgets, reason: 'the guide asks the round\'s own question');

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
        debugPrint('PERF learn board 1.3 ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames in an idle second');
        expect(perSec, lessThan(20), reason: 'nothing may rebuild every frame while the player thinks');
        expect(frames, lessThan(12), reason: 'no 60 fps loop while waiting for an answer');
        // The picture must carry the cue: no names until a card is tapped.
        for (final o in _pack.slots.first.options) {
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
