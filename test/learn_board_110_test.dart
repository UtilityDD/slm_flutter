// Ladder step 28 — the lesson 1.10 picture board ("১০ সেকেন্ডের মেন্টাল চেকলিস্ট"):
// its content follows the board's rules and the lesson's points (lessons 1.1–1.10
// only), every picture exists and no colour or backdrop marks the safe card in any
// hand the dealer can make — counting only shapes that can be seen, so invisible
// "tokens" can never pass the check — the rival's myth is the lesson's own and in his
// recorded voice, the board waits quietly once the first hand is dealt, and a wrong
// card redeals without a zoom.
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
import 'package:slm_flutter/features/game/ten_sec_scan.dart' show TenSecChecks, TenSecMistakes;
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/option_lengths.dart';
import 'support/board_pick.dart';

const pack = learnBoardPack110;
const _artDir = 'assets/game/art/scan_board';

/// Has read lesson 1.10 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['1_10', '1.10']));
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

  test('step 28 is the lesson 1.10 board with the lesson\'s rounds', () {
    expect(pack.lessonId, '1.10');
    expect(learnBoardPackFor('1.10'), same(learnBoardPack110), reason: 'the ladder opens this board for step 28');
    expect(pack.badgeBn, 'সুরক্ষা কবচ');
    expect(pack.slots.map((s) => s.id), ['ppe', 'harness_tool', 'ptw_mind', 'pole_distance', 'hazard_rescue']);
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
      for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স']) {
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

  test('the lesson\'s points: PPE kit, harness fit, permit & mind, pole & লক্ষ্মণ রেখা, surroundings & rescue', () {
    // PPE (lesson 1.1): crack, nail, pinhole, synthetic.
    expect(_reject('ppe', 'helmet_crack'), contains('ফাটল'));
    expect(_reject('ppe', 'nail_sole'), contains('পেরেক'));
    expect(_reject('ppe', 'glove_leak'), contains('ফুটো'));
    expect(_reject('ppe', 'polyester'), contains('সিন্থেটিক'));
    // Harness (lesson 1.4): four fingers, chest strap mid-chest, not twisted, no cuts.
    expect(_reject('harness_tool', 'harness_loose_chest'), contains('ঢিলেঢালা'));
    expect(_reject('harness_tool', 'harness_chest_high'), contains('মাঝ বরাবর'));
    expect(_reject('harness_tool', 'harness_twisted'), contains('পেঁচিয়ে'));
    expect(_reject('harness_tool', 'harness_frayed'), contains('50%'));
    expect(_slot('harness_tool').whyChips.any((w) => w.correct && w.textBn.contains('4 আঙুল')), isTrue);
    // Permit & mind (lessons 1.6, 1.10).
    expect(_reject('ptw_mind', 'ptw_verbal_phone'), contains('লিখিত পারমিট'));
    expect(_reject('ptw_mind', 'mind_rushed'), contains('তাড়াহুড়ো'));
    expect(_reject('ptw_mind', 'mind_tired'), contains('ক্লান্ত'));
    expect(_reject('ptw_mind', 'ptw_no_read'), contains('শর্ত'));
    // Pole (lesson 1.3) and the লক্ষ্মণ রেখা (lesson 1.2).
    expect(_reject('pole_distance', 'pole_lean'), contains('হেলে'));
    expect(_reject('pole_distance', 'clearance_inside'), contains('টুলের ডগা'));
    expect(_reject('pole_distance', 'pole_rusted_base'), contains('মরিচা'));
    expect(_slot('pole_distance').whyChips.any((w) => w.correct && w.textBn.contains('সাউন্ড টেস্ট')), isTrue);
    // Surroundings, weather, escape route (lessons 1.3, 1.9, 1.10).
    expect(_reject('hazard_rescue', 'hazard_beehive'), contains('মৌমাছি'));
    expect(_reject('hazard_rescue', 'hazard_traffic'), contains('ট্র্যাফিক'));
    expect(_reject('hazard_rescue', 'hazard_storm_sky'), contains('রেড লাইন'));
    expect(_reject('hazard_rescue', 'hazard_water'), contains('জল'));
    expect(_slot('hazard_rescue').whyChips.any((w) => w.correct && w.textBn.contains('রেসকিউ প্ল্যান')), isTrue);
  });

  test('nothing from outside lessons 1.1–1.10 (the 2026-11-11 audit)', () {
    final m = pack.myth;
    final text = [
      for (final s in pack.slots) ...[
        s.promptBn,
        for (final o in s.options) ...[o.labelBn, o.rejectBn],
        for (final w in s.whyChips) w.textBn,
      ],
      ...m.dangerHints,
      for (final w in m.whyChips) w.textBn,
    ].join('\n');
    for (final off in ['তিন বিন্দু', '3-পয়েন্ট', 'রাগ', 'মই', 'কাঁটাতার', 'কোণ', 'ব্যারিকেড', 'দড়ি', 'রশি', 'গাই তার', 'ব্রিফিং', 'ফার্স্ট এইড']) {
      expect(text, isNot(contains(off)), reason: '"$off" is not in lessons 1.1–1.10');
    }
  });

  test('every picture exists (vector scenes from tool/scan_board_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(o.asset, startsWith('$_artDir/'));
        expect(o.asset, endsWith('.svg'));
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
      }
    }
    expect(File(pack.myth.bodyAsset).existsSync(), isTrue);
  });

  test("every SVG in the scan_board folder is a card on the board", () {
    // Step 29 (ten_sec_scan.dart) draws its checks from the same generator.
    final used = {
      for (final s in pack.slots) for (final o in s.options) o.asset,
      for (final c in TenSecChecks.all) c.art,
      for (final m in TenSecMistakes.all) m.art,
    };
    final onDisk = Directory(_artDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.svg'))
        .map((n) => '$_artDir/$n')
        .toSet();
    expect(onDisk, used, reason: 'no unused art and no missing art');
  });

  test('the fairness check counts only what can be seen', () {
    const fake = '<svg viewBox="0 0 200 220"><defs><rect width="9" height="9" fill="#ABCDEF"/></defs>'
        '<rect width="0" height="0" fill="#123456"/>'
        '<circle cx="1" cy="1" r="0" fill="#223344"/>'
        '<path d="M0 0 L5 5" stroke="#334455" opacity="0"/>'
        '<rect width="4" height="4" fill="#445566" fill-opacity="0"/>'
        '<ellipse cx="1" cy="1" rx="2" ry="2" fill="#556677" display="none"/>'
        '<rect width="4" height="4" style="opacity:0" fill="#686868"/>'
        '<rect width="4" height="4" fill="#778899"/></svg>';
    expect(_visibleTokens(fake), {'#778899'});
  });

  test('the fairness check skips shapes hidden by their group or placed off the card', () {
    const fake = '<svg viewBox="0 0 200 220"><defs></defs>'
        '<g opacity="0"><rect width="4" height="4" fill="#111111"/><g><circle cx="5" cy="5" r="3" fill="#121212"/></g></g>'
        '<g display="none"><rect width="4" height="4" fill="#222222"/></g>'
        '<g visibility="hidden"><rect width="4" height="4" fill="#333333"/></g>'
        '<g transform="translate(10 10) scale(0)"><rect width="40" height="40" fill="#444444"/></g>'
        '<g transform="scale(1 0)"><rect width="40" height="40" fill="#454545"/></g>'
        '<rect x="300" y="10" width="20" height="20" fill="#555555"/>'
        '<g transform="translate(400 0)"><circle cx="10" cy="10" r="5" fill="#666666"/></g>'
        '<path d="M-50 -50 l10 10 h5 v5 z" stroke="#676767" stroke-width="2"/>'
        // still painted: a group's fill on its child, a shape half on the card
        '<g fill="#696969"><rect x="20" y="20" width="4" height="4"/></g>'
        '<rect x="190" y="200" width="40" height="40" fill="#787878"/>'
        '<g opacity="0.5"><rect width="4" height="4" fill="#778899"/></g></svg>';
    expect(_visibleTokens(fake), {'#696969', '#787878', '#778899'});
  });

  test('the cards use no paint the fairness check cannot follow', () {
    for (final f in Directory(_artDir).listSync().whereType<File>().where((f) => f.path.endsWith('.svg'))) {
      final svg = f.readAsStringSync();
      final clips = RegExp(r'clip-path="([^"]*)"').allMatches(svg).map((m) => m.group(1)).toSet()..remove('url(#card)');
      expect(clips, isEmpty, reason: '${f.path}: only the card\'s own clip');
      expect(RegExp(r'\b(mask|filter)="|<use\b|<image\b|<foreignObject\b').hasMatch(svg), isFalse,
          reason: '${f.path}: no mask, filter, reused shape or image');
    }
  });

  test('no glow or warning mark: no colour or backdrop gives the safe card away', () {
    Set<String> tokens(String asset) {
      final svg = File(asset).readAsStringSync();
      expect(svg, isNot(contains('<text')), reason: '$asset: no words in the art');
      expect(svg, isNot(contains('Glow')), reason: '$asset: no highlight glow');
      return _visibleTokens(svg);
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
    final backdrop = RegExp(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"');
    final svgs = <String, String>{};
    String body(String asset) => svgs.putIfAbsent(asset, () => File(asset).readAsStringSync());
    Set<String> tokens(String asset) => _visibleTokens(body(asset));
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

  test('the careless lineman says the lesson\'s myth in his own recorded voice', () {
    final m = pack.myth;
    expect(m.rivalLineBn, 'আমি 20 বছর ধরে এই কাজ করছি, আমার এসব চেকলিস্টের দরকার নেই। সবকিছু আমার মাথায় আছে।');
    expect(m.believeNoIsCorrect, isTrue, reason: 'experience never replaces the checklist');
    expect(m.whyChips.any((w) => w.correct && w.textBn.contains('চেকলিস্ট')), isTrue);
    expect(m.dangerHints, isNotEmpty);
    for (final line in [m.tauntBn, m.rivalLineBn, m.exitBn, ...ScanBoardLines.recorded]) {
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
            home: const LearnBoardRunnerPage(rungId: '1.10/learn', lessonId: '1.10', ladderIndex: 27, pack: pack, muted: true),
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

    // Design 2026-11-11: wrong picks shake + redeal + speak reject — no inspect zoom modal.
    testWidgets('tapping a wrong card redeals without an inspect zoom modal', (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: [authProvider.overrideWith(_TestAuth.new)],
        child: MaterialApp(
          theme: SlmTheme.night(),
          home: const LearnBoardRunnerPage(rungId: '1.10/learn', lessonId: '1.10', ladderIndex: 27, pack: pack, muted: true),
        ),
      ));
      for (var i = 0; i < 165; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(_cards, findsNWidgets(pack.slots.first.cards));
      final traps = {for (final o in pack.slots.first.options) if (!o.correct) o.id};
      final trap = find.byWidgetPredicate((w) {
        final k = w.key;
        return w.runtimeType.toString() == '_AnimatedChoiceCard' &&
            k is ValueKey<String> &&
            k.value.startsWith('pick-') &&
            traps.contains(k.value.split('-').skip(2).join('-'));
      });
      expect(trap, findsAtLeastNWidgets(1), reason: 'a dealt hand holds traps');
      await tapBoardCard(tester, trap);
      await tester.pump(const Duration(milliseconds: 700));

      // No inspect zoom sheet (wrong = redeal + speak; right = celebrate / why).
      expect(find.text('বুঝেছি, আবার চেষ্টা করি'), findsNothing);
      expect(find.text('ভুল নির্বাচন · বিপদের ঝুঁকি'), findsNothing);
      expect(find.text('সঠিক নির্বাচন! · নিরাপদ পদক্ষেপ'), findsNothing);
      // A wrong card never opens the "কেন" deck.
      for (final w in pack.slots.first.whyChips) {
        expect(find.text(w.textBn), findsNothing, reason: w.textBn);
      }
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      tester.view.reset();
    });
  });
}

LearnBoardSlot _slot(String id) => pack.slots.firstWhere((s) => s.id == id);

String _reject(String slot, String option) => _slot(slot).options.firstWhere((o) => o.id == option).rejectBn;

final _elem = RegExp(r'<(/?)([\w:]+)\b([^>]*?)(/?)>');
final _attr = RegExp(r'([\w:-]+)="([^"]*)"');
final _token = RegExp(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b');
final _numRe = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
final _xform = RegExp(r'(matrix|translate|scale|rotate|skewX|skewY)\s*\(([^)]*)\)');
final _pathTok = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
// Containers paint nothing themselves; definitions are never painted where they stand.
const _noPaint = {'g', 'svg', 'a', 'switch'};
const _defs = {'defs', 'clipPath', 'mask', 'pattern', 'symbol', 'marker', 'linearGradient', 'radialGradient', 'filter'};
const _inherit = ['fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width', 'visibility'];
const _identity = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0];

double _num(String? v, [double fallback = 1]) {
  if (v == null) return fallback;
  final s = v.trim();
  if (s.endsWith('%')) {
    final p = double.tryParse(s.substring(0, s.length - 1));
    return p == null ? fallback : p / 100;
  }
  return double.tryParse(s) ?? fallback;
}

List<double> _nums(String s) => [for (final m in _numRe.allMatches(s)) double.parse(m.group(0)!)];

Map<String, String> _attrs(String raw) {
  final a = {for (final x in _attr.allMatches(raw)) x.group(1)!: x.group(2)!};
  final style = a.remove('style');
  if (style != null) {
    for (final part in style.split(';')) {
      final i = part.indexOf(':');
      if (i > 0) a[part.substring(0, i).trim()] = part.substring(i + 1).trim();
    }
  }
  return a;
}

List<double> _mul(List<double> m, List<double> n) => [
      m[0] * n[0] + m[2] * n[1],
      m[1] * n[0] + m[3] * n[1],
      m[0] * n[2] + m[2] * n[3],
      m[1] * n[2] + m[3] * n[3],
      m[0] * n[4] + m[2] * n[5] + m[4],
      m[1] * n[4] + m[3] * n[5] + m[5],
    ];

List<double> _transform(String? text) {
  var m = _identity;
  for (final f in _xform.allMatches(text ?? '')) {
    final v = _nums(f.group(2)!);
    List<double>? t;
    switch (f.group(1)) {
      case 'matrix' when v.length == 6:
        t = v;
      case 'translate' when v.isNotEmpty:
        t = [1, 0, 0, 1, v[0], v.length > 1 ? v[1] : 0];
      case 'scale' when v.isNotEmpty:
        t = [v[0], 0, 0, v.length > 1 ? v[1] : v[0], 0, 0];
      case 'rotate' when v.isNotEmpty:
        final r = v[0] * math.pi / 180;
        t = [math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0];
        if (v.length >= 3) t = _mul(_mul([1, 0, 0, 1, v[1], v[2]], t), [1, 0, 0, 1, -v[1], -v[2]]);
      case 'skewX' when v.isNotEmpty:
        t = [1, 0, math.tan(v[0] * math.pi / 180), 1, 0, 0];
      case 'skewY' when v.isNotEmpty:
        t = [1, math.tan(v[0] * math.pi / 180), 0, 1, 0, 0];
    }
    if (t != null) m = _mul(m, t);
  }
  return m;
}

/// Points whose box holds the whole path (ends and control points; an arc adds a
/// box of its size around its ends), or null when the path can't be read.
List<(double, double)>? _pathPoints(String d) {
  const arity = {'m': 2, 'l': 2, 'h': 1, 'v': 1, 'c': 6, 's': 4, 'q': 4, 't': 2, 'a': 7, 'z': 0};
  final toks = [for (final m in _pathTok.allMatches(d)) m.group(0)!];
  final pts = <(double, double)>[];
  String? cmd;
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  (double, double)? lastC;
  var i = 0;
  while (i < toks.length) {
    if (RegExp(r'^[A-Za-z]$').hasMatch(toks[i])) {
      cmd = toks[i++];
      if (cmd == 'z' || cmd == 'Z') {
        x = sx;
        y = sy;
        pts.add((x, y));
        lastC = null;
        continue;
      }
    }
    if (cmd == null) return null;
    final c = cmd.toLowerCase();
    final n = arity[c]!;
    if (i + n > toks.length) return null;
    final v = <double>[];
    for (final t in toks.sublist(i, i + n)) {
      final p = double.tryParse(t);
      if (p == null) return null;
      v.add(p);
    }
    i += n;
    final rel = cmd != cmd.toUpperCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    if (c == 'h') {
      x = v[0] + ox;
      pts.add((x, y));
      lastC = null;
    } else if (c == 'v') {
      y = v[0] + oy;
      pts.add((x, y));
      lastC = null;
    } else if (c == 'a') {
      final ex = v[5] + ox, ey = v[6] + oy;
      final r = 2 * [v[0].abs(), v[1].abs(), math.sqrt((ex - x) * (ex - x) + (ey - y) * (ey - y))].reduce(math.max);
      pts.addAll([(x - r, y - r), (x + r, y + r), (ex, ey)]);
      x = ex;
      y = ey;
      lastC = null;
    } else {
      final ctrl = [for (var k = 0; k < n; k += 2) (v[k] + ox, v[k + 1] + oy)];
      if (c == 's' || c == 't') ctrl.insert(0, lastC == null ? (x, y) : (2 * x - lastC.$1, 2 * y - lastC.$2));
      pts.addAll(ctrl);
      lastC = ctrl.length > 1 ? ctrl[ctrl.length - 2] : null;
      (x, y) = ctrl.last;
      if (c == 'm') {
        sx = x;
        sy = y;
        cmd = rel ? 'l' : 'L';
      }
    }
  }
  return pts.isEmpty ? null : pts;
}

List<(double, double)>? _localPoints(String tag, Map<String, String> a) {
  double n(String k) => _num(a[k], 0);
  switch (tag) {
    case 'rect':
      return [(n('x'), n('y')), (n('x') + n('width'), n('y') + n('height'))];
    case 'circle':
      return [(n('cx') - n('r'), n('cy') - n('r')), (n('cx') + n('r'), n('cy') + n('r'))];
    case 'ellipse':
      return [(n('cx') - n('rx'), n('cy') - n('ry')), (n('cx') + n('rx'), n('cy') + n('ry'))];
    case 'line':
      return [(n('x1'), n('y1')), (n('x2'), n('y2'))];
    case 'polygon' || 'polyline':
      final v = _nums(a['points'] ?? '');
      return v.length < 2 ? null : [for (var k = 0; k + 1 < v.length; k += 2) (v[k], v[k + 1])];
    case 'path':
      return _pathPoints(a['d'] ?? '');
  }
  return null; // text and the rest: can't place it, so it counts
}

/// The colours and gradients an SVG card really paints on its 200 x 220 face
/// (mirrors `painted` / `tokens` in tool/scan_board_art.py). Skipped: definitions;
/// anything with display:none, visibility:hidden or opacity 0 on itself or on any
/// ancestor group; a transform that squashes it flat (scale(0)); zero-size shapes;
/// no fill and no stroke; a shape wholly off the card.
Set<String> _visibleTokens(String svg) {
  final vbMatch = RegExp(r'<svg\b[^>]*viewBox="([^"]*)"').firstMatch(svg);
  final vb = vbMatch == null ? <double>[] : _nums(vbMatch.group(1)!);
  final (x0, y0, cw, ch) = vb.length == 4 ? (vb[0], vb[1], vb[2], vb[3]) : (0.0, 0.0, 200.0, 220.0);
  final stack = <(String, bool, bool, Map<String, String>, List<double>)>[('#doc', false, false, {}, _identity)];
  final out = <String>{};
  for (final e in _elem.allMatches(svg)) {
    final tag = e.group(2)!;
    if (e.group(1)!.isNotEmpty) {
      for (var k = stack.length - 1; k > 0; k--) {
        if (stack[k].$1 == tag) {
          stack.removeRange(k, stack.length);
          break;
        }
      }
      continue;
    }
    final (_, pHidden, pDefs, pInh, pM) = stack.last;
    final own = _attrs(e.group(3)!);
    final inh = {...pInh, for (final k in _inherit) if (own.containsKey(k)) k: own[k]!};
    final m = _mul(pM, _transform(own['transform']));
    final inDefs = pDefs || _defs.contains(tag);
    final hidden = pHidden || own['display'] == 'none' || _num(own['opacity']) <= 0 || (m[0] * m[3] - m[1] * m[2]).abs() < 1e-9;
    if (e.group(4)!.isEmpty && !e.group(3)!.trimRight().endsWith('/')) stack.add((tag, hidden, inDefs, inh, m));
    if (inDefs || hidden || _noPaint.contains(tag) || inh['visibility'] == 'hidden' || inh['visibility'] == 'collapse') continue;
    final a = {...own, ...inh};
    var fillOn = a['fill'] != 'none' && _num(a['fill-opacity']) > 0;
    final strokeOn = a['stroke'] != null && a['stroke'] != 'none' && _num(a['stroke-opacity']) > 0 && _num(a['stroke-width']) > 0;
    if (tag == 'line') fillOn = false;
    if (!fillOn && !strokeOn) continue;
    if (tag == 'rect' && (_num(a['width'], 0) <= 0 || _num(a['height'], 0) <= 0)) continue;
    if (tag == 'circle' && _num(a['r'], 0) <= 0) continue;
    if (tag == 'ellipse' && (_num(a['rx'], 0) <= 0 || _num(a['ry'], 0) <= 0)) continue;
    if ((tag == 'path' || tag == 'polygon' || tag == 'polyline') && (a['d'] ?? a['points'] ?? '').isEmpty) continue;
    if (tag == 'line' && a['x1'] == a['x2'] && a['y1'] == a['y2']) continue;
    final pts = _localPoints(tag, a);
    if (pts != null) {
      final pad = strokeOn ? 2 * _num(a['stroke-width']) : 0.0; // miter joins reach 2 x width
      final xs = pts.map((p) => p.$1), ys = pts.map((p) => p.$2);
      final lx = xs.reduce(math.min) - pad, hx = xs.reduce(math.max) + pad;
      final ly = ys.reduce(math.min) - pad, hy = ys.reduce(math.max) + pad;
      final box = [(lx, ly), (hx, ly), (lx, hy), (hx, hy)];
      final tx = [for (final (px, py) in box) m[0] * px + m[2] * py + m[4]];
      final ty = [for (final (px, py) in box) m[1] * px + m[3] * py + m[5]];
      if (tx.reduce(math.max) <= x0 || tx.reduce(math.min) >= x0 + cw || ty.reduce(math.max) <= y0 || ty.reduce(math.min) >= y0 + ch) continue;
    }
    if (fillOn && a['fill'] != null) out.addAll(_token.allMatches(a['fill']!).map((t) => t.group(0)!));
    if (strokeOn) out.addAll(_token.allMatches(a['stroke']!).map((t) => t.group(0)!));
  }
  return out;
}
