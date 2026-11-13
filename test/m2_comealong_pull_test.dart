// Lesson 2.4 (কাম-অ্যালং ক্ল্যাম্প), কাজ 2 "নিয়ন্ত্রিত টান": the rules (a
// strong anchor, the lesson's order, standing beside the line of pull, slow
// strokes with the ratchet locked each time, the right sag, no pipe on the
// handle, the load let off slowly), the deal, the reason libraries, and the
// level in the shell: idle perf, the guide first, the guide's tap, a full
// clean play to a pass (with the coworker refused and the pawl seated), a
// slip card, "done" while it sags = a slip, three slips strike out, the
// coworker comes even on a fast pull, listening to him is a slip, a second
// spot tap after the station is won does nothing (audit 2026-11-11), the
// gesture hint, and the deadly freeze (standing in the line of pull).
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_comealong_pull.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '2.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '2.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m2ComealongPullPacks['do_2_4_b']!;

/// The level's new art folder is not in pubspec.yaml yet (the director adds
/// it): serve unbundled assets from the repo so the mistake cards draw.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (f.evaluate().isNotEmpty) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return f.evaluate().isNotEmpty;
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await confirmChoice(t);
  // The reason's zoom + এগিয়ে যান (coworker decks have no proceed).
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
PullGeo get _geo => PullGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _screen(Offset design) => _geo.view(design) * _k;

Widget _app(Widget home, {GlobalKey<NavigatorState>? nav}) =>
    DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(navigatorKey: nav, home: home));

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(const Scaffold(body: SizedBox()), nav: nav)));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M2ComealongPullPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1500);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _reason(WidgetTester t, PullStation s) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: '$s deck');
  await _pump(t, 700);
  await _pickRight(t, PullLines.whyRight(s));
  await _pump(t, 4500);
}

Future<void> _rig(WidgetTester t) async {
  await t.tap(_label(PullLines.comeAlong));
  await _pump(t, 200);
  await t.tapAt(_screen(_geo.anchorRect(PullAnchor.sling).center));
  await _pump(t, 400);
  await t.tap(_label(PullLines.grip));
  await _pump(t, 200);
  await t.tapAt(_screen(_geo.gripRect.center));
  await _pump(t, 400);
  await t.tapAt(_screen(_geo.hookRect(PullAnchor.sling).center));
  await _pump(t, 300);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  await _reason(t, PullStation.rig);
}

Future<void> _hold(WidgetTester t, String label, int ms, {int after = 300}) async {
  final g = await t.startGesture(t.getCenter(find.text(label)));
  await _pump(t, ms);
  await g.up();
  await _pump(t, after);
}

/// Takes the come-along and taps a weak anchor: one slip.
Future<void> _weakAnchor(WidgetTester t, PullAnchor a) async {
  await t.tap(_label(PullLines.comeAlong));
  await _pump(t, 200);
  await t.tapAt(_screen(_geo.anchorRect(a).center));
  await _pump(t, 600);
}

/// Rig, stand beside, the spot's reason: the pull is next.
Future<void> _toPull(WidgetTester t) async {
  await _rig(t);
  await t.tapAt(_screen(_geo.spotRect(PullSpot.side).center));
  await _pump(t, 1000);
  await _reason(t, PullStation.spot);
}

/// Strokes (fast or slow) until he is dealt; seats the pawl when it slips.
Future<void> _strokeToCall(WidgetTester t, PullDeal deal, {required bool fast}) async {
  final mirror = PullRun(deal)..station = PullStation.pull;
  while (mirror.strokes < deal.callAt) {
    await _hold(t, PullLines.pull, fast ? 950 : 1000, after: fast ? 50 : 300);
    expect(mirror.stroke(), isNull);
    if (mirror.slipping) {
      await t.tap(_label(PullLines.ratchet));
      await t.pump(Duration(milliseconds: fast ? 50 : 300));
      mirror.seatPawl();
    }
  }
}

void main() {
  group('rules', () {
    test('deals: 4–6 strokes, the pawl fails once mid-pull, he comes before the right sag, 3–4 notches; fresh every play', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = dealPull(math.Random(s));
        expect(d.need, inInclusiveRange(4, 6));
        expect(d.lostAt, inInclusiveRange(2, d.need - 1));
        expect(d.callAt, inInclusiveRange(1, d.need - 1));
        expect(d.notches, inInclusiveRange(3, 4));
        expect(d.tray.toSet(), PullTool.values.toSet());
        seen.add('${d.need}${d.lostAt}${d.callAt}${d.notches}${d.gripLeft}');
      }
      expect(seen.length, greaterThan(20));
      // The tool tray is not laid out in the lesson's order every play.
      final firsts = {for (var s = 0; s < 40; s++) dealPull(math.Random(s)).tray.first};
      expect(firsts, PullTool.values.toSet());
    });

    PullRun run([PullDeal d = const PullDeal(need: 4, lostAt: 2, callAt: 2, notches: 3)]) => PullRun(d);

    test('rig: a weak anchor is a slip; the grip before the anchor is a slip; anchor → grip → hook', () {
      for (final a in [PullAnchor.insulator, PullAnchor.armTip, PullAnchor.bracket]) {
        final r = run();
        expect(r.placeComeAlong(a), PullMistakes.weakAnchor);
        expect(r.anchor, isNull);
        expect(r.slips, 1);
      }
      final g = run();
      expect(g.placeGrip(), PullMistakes.gripFirst);
      expect(g.grip, isFalse);
      expect(g.hook(), isFalse);
      for (final a in [PullAnchor.sling, PullAnchor.armBase]) {
        final r = run();
        expect(r.placeComeAlong(a), isNull);
        expect(r.hook(), isFalse, reason: 'no grip yet');
        expect(r.placeGrip(), isNull);
        expect(r.hook(), isTrue);
        expect(r.clean, isTrue);
        expect(r.caught, contains(PullLines.caughtAnchor));
      }
    });

    test('spot: in front of or behind the line of pull is deadly; beside it is right', () {
      for (final s in [PullSpot.front, PullSpot.behind]) {
        final r = run()..station = PullStation.spot;
        final m = r.stand(s);
        expect(m, PullMistakes.inLine);
        expect(m!.deadly, isTrue);
        expect(r.ended, isTrue);
      }
      final ok = run()..station = PullStation.spot;
      expect(ok.stand(PullSpot.side), isNull);
      expect(ok.caught, contains(PullLines.caughtSpot));
    });

    test('pull: the lost stroke runs back; a stroke or done with the pawl off is a slip; done while it sags is a slip; past the right sag is a slip', () {
      final r = run()..station = PullStation.pull;
      expect(r.stroke(), isNull);
      expect(r.strokes, 1);
      expect(r.stroke(), isNull, reason: 'the lostAt stroke');
      expect(r.strokes, 1, reason: 'the wheel ran back');
      expect(r.slipping, isTrue);
      expect(r.stroke(), PullMistakes.pawlOpen);
      expect(r.check().$2, PullMistakes.pawlOpen);
      expect(r.slips, 2);
      r.seatPawl();
      expect(r.caught, contains(PullLines.caughtPawl));
      final early = r.check();
      expect(early.$1, PullCheck.slack);
      expect(early.$2, PullMistakes.stoppedSlack, reason: 'a stop before the right sag costs a slip (no free probing)');
      expect(r.slips, 3);
      for (var i = 0; i < 3; i++) {
        expect(r.stroke(), isNull);
      }
      expect(r.strokes, 4);
      expect(r.tension, 1);
      expect(r.stroke(), PullMistakes.overPull);
      expect(r.strokes, 4, reason: 'let back to the right sag');
      expect(r.check(), (PullCheck.ok, null));
      expect(r.caught, contains(PullLines.caughtSag));
      expect(PullGeo.sagAt(1), PullGeo.okSag);
      expect(PullGeo.sagAt(1.25), lessThan(PullGeo.okSag));
    });

    test('release: all at once is a slip (the load stays on); notch by notch lets it off; then the play passes', () {
      final r = run()
        ..next()
        ..next()
        ..next();
      expect(r.station, PullStation.release);
      expect(r.clamped, isTrue);
      expect(r.releaseAtOnce(), PullMistakes.suddenRelease);
      expect(r.released, isFalse);
      expect(r.releaseNotch(), isFalse);
      expect(r.releaseNotch(), isFalse);
      expect(r.releaseNotch(), isTrue);
      expect(r.caught, contains(PullLines.caughtRelease));
      expect(r.percent, 85);
      expect(r.passed, isTrue);
      final p = run()..listenPipe();
      expect(p.slips, 1);
      expect(PullMistakes.pipe.deadly, isFalse, reason: 'listening to him is a slip');
    });

    test('after the deadly every rule is closed (ended guards)', () {
      final r = run()..station = PullStation.spot;
      expect(r.stand(PullSpot.front), PullMistakes.inLine);
      expect(r.stand(PullSpot.side), isNull);
      expect(r.spot, isNull);
      r.station = PullStation.pull;
      expect(r.stroke(), isNull);
      expect(r.check(), (null, null));
      expect(r.strokes, 0);
      expect(r.slips, 0);
    });

    test('English digits only; every mistake has its picture and its lesson point; one deadly', () {
      final all = <String>[
        PullLines.intro,
        ...PullLines.tasks,
        PullLines.stillSlack,
        for (final s in PullStation.values) ...PullLines.whyRight(s),
        ...PullLines.excuses,
        ...PullLines.coworker.recordedLines,
        ...PullLines.coworker.right,
        ...PullLines.coworker.wrong,
        ...PullLines.coworker.asks,
        for (final m in PullMistakes.all) m.textBn,
        PullLines.allSet,
        PullLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
      }
      expect(PullMistakes.all.where((m) => m.deadly), [PullMistakes.inLine]);
      expect(PullMistakes.pipe.lessonPoint, isNull, reason: 'pro tip');
      expect(PullMistakes.stoppedSlack.lessonPoint, isNull, reason: 'the mission briefing');
      for (final m in PullMistakes.all) {
        if (m != PullMistakes.pipe && m != PullMistakes.stoppedSlack) expect(m.lessonPoint, inInclusiveRange(0, 2), reason: m.key);
        expect(m.key, startsWith('2.4/pull/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m2ComealongPullPacks.keys, ['do_2_4_b']);
      expect(_pack.quickMs, kPullQuickMs);
    });

    test('reasons: same length, big enough, one right per deal; his exit line is recorded', () {
      final every = [for (final s in PullStation.values) ...PullLines.whyRight(s), ...PullLines.excuses];
      expectSameLength('why', every);
      for (final s in PullStation.values) {
        expectLibrary('$s', PullLines.whyRight(s), PullLines.excuses);
        for (var i = 0; i < 10; i++) {
          final d = dealChoices(PullLines.whyRight(s), PullLines.excuses, math.Random(i));
          expect(d.where((o) => o.correct).length, 1);
          expect(d.map((o) => o.textBn).toSet().length, 3);
        }
      }
      final cw = PullLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
    });
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: _app(M2ComealongPullPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.textContaining(RegExp('শুরু')), findsNothing);
        await waitIntro(t);
        await _pump(t, 14000);
        rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugPrint('PERF m2_comealong_pull ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; then the tools and the docket', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: _app(M2ComealongPullPage(ctx: _ctx, pack: _pack, muted: true, seed: 1))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.textContaining(RegExp('শুরু')), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(PullLines.comeAlong), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(PullLines.comeAlong), findsOneWidget);
      expect(find.text(PullLines.permit), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 2);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(PullLines.askRig)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: rig, stand beside, pull with the pawl seated, refuse the pipe, release slowly → pass', (t) async {
      const seed = 3;
      final deal = dealPull(math.Random(seed));
      final c = await _open(t, seed);
      await _rig(t);
      // Beside the line of pull.
      await t.tapAt(_screen(_geo.spotRect(PullSpot.side).center));
      await _pump(t, 1000);
      await _reason(t, PullStation.spot);
      // The pull: a mirror of the rules tells the test when the pawl slips and he comes.
      final mirror = PullRun(deal)..station = PullStation.pull;
      var met = false;
      while (mirror.strokes < deal.need) {
        expect(find.text(PullLines.pull), findsOneWidget, reason: 'stroke ${mirror.finished + 1}');
        await _hold(t, PullLines.pull, 1000);
        expect(mirror.stroke(), isNull);
        if (mirror.slipping) {
          await t.tap(_label(PullLines.ratchet));
          await _pump(t, 300);
          mirror.seatPawl();
        }
        if (!met && mirror.strokes >= deal.callAt) {
          met = true;
          expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
          await _pickRight(t, PullLines.coworker.right);
          await _pump(t, 2600);
        }
        expect(find.byType(MistakeCard), findsNothing);
      }
      await t.tap(find.text(PullLines.done));
      await _pump(t, 300);
      await _reason(t, PullStation.pull);
      // The release, notch by notch.
      for (var i = 0; i < deal.notches; i++) {
        await _hold(t, PullLines.slowRelease, 800);
      }
      await _reason(t, PullStation.release);
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.4/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.4/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(PullLines.caughtCall), findsOneWidget);
      expect(find.text(PullLines.caughtPawl), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a weak anchor: the slip card, booked; "done" while it sags is a slip too', (t) async {
      final c = await _open(t, 5);
      await t.tap(_label(PullLines.comeAlong));
      await _pump(t, 200);
      await t.tapAt(_screen(_geo.anchorRect(PullAnchor.insulator).center));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, PullMistakes.weakAnchor.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await _rig(t);
      await t.tapAt(_screen(_geo.spotRect(PullSpot.side).center));
      await _pump(t, 1000);
      await _reason(t, PullStation.spot);
      await t.tap(find.text(PullLines.done));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), contains(PullMistakes.stoppedSlack.key));
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(PullLines.pull), findsOneWidget, reason: 'the pull goes on');
      await _close(t, c);
    });

    testWidgets('three slips strike the level out: the struck-out card, not cleared', (t) async {
      final c = await _open(t, 7);
      for (final a in [PullAnchor.insulator, PullAnchor.armTip]) {
        await _weakAnchor(t, a);
        expect(find.byType(MistakeCard), findsOneWidget);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 600);
      }
      await _weakAnchor(t, PullAnchor.bracket);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.4/do/1'], isNot('cleared'));
      expect(s.mistakes.map((m) => m.key), contains(PullMistakes.weakAnchor.key));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a second spot tap after the station is won does nothing (no walk into the line, no second ◆)', (t) async {
      final c = await _open(t, 8);
      await _rig(t);
      await t.tapAt(_screen(_geo.spotRect(PullSpot.side).center));
      await _pump(t, 1000);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, PullLines.whyRight(PullStation.spot));
      // At once, before the next station starts: the line of pull.
      await t.tapAt(_screen(_geo.spotRect(PullSpot.front).center));
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byKey(const ValueKey('hud-token')), findsNothing, reason: 'no second reward');
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(find.text(PullLines.pull), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the coworker comes even on a fast pull: the next stroke waits for him', (t) async {
      const seed = 11;
      final deal = dealPull(math.Random(seed));
      final c = await _open(t, seed);
      await _toPull(t);
      await _strokeToCall(t, deal, fast: true);
      // He is dealt now (his own timer is 1.2–2.4 s away): pull again at once.
      expect(find.byType(CoworkerPeek), findsNothing);
      final g = await t.startGesture(t.getCenter(find.text(PullLines.pull)));
      await _pump(t, 250);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the stroke waited for him');
      await g.up();
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, PullLines.coworker.right);
      await _pump(t, 2600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(PullLines.pull), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('listening to the coworker is a slip (the pipe card), not deadly', (t) async {
      const seed = 12;
      final deal = dealPull(math.Random(seed));
      final c = await _open(t, seed);
      await _toPull(t);
      await _strokeToCall(t, deal, fast: false);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = _onScreen(PullLines.coworker.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, PullMistakes.pipe.key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('gesture hint: a sweep over both tools (never one), then over every place on the pole', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 9);
      IdleHintState frame() => t.state<IdleHintState>(find.byType(IdleHint).first);
      Future<bool> shows() async {
        for (var ms = 0; ms < 12000; ms += 100) {
          if (frame().showing) return true;
          await t.pump(const Duration(milliseconds: 100));
        }
        return false;
      }

      expect(await shows(), isTrue);
      expect(frame().debugFrame, isNotNull);
      expect(frame().debugOptions, hasLength(2), reason: 'both tools, the same way');
      await t.tap(_label(PullLines.comeAlong));
      await _pump(t, 300);
      expect(await shows(), isTrue);
      expect(frame().debugOptions, hasLength(PullAnchor.values.length + 1), reason: 'every place, the grip spot too');
      await _close(t, c);
    });

    testWidgets('standing in the line of pull: the scene freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, 6);
      await _rig(t);
      await t.tapAt(_screen(_geo.spotRect(PullSpot.behind).center));
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, PullMistakes.inLine.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });
  });
}
