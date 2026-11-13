// Lesson 1.4, কাজ 1 (তিন মিনিটের পরীক্ষা): harness rules, dated labels, deal
// variety, fair reason libraries that fit what the harness had, the
// coworker's recorded lines, and the level in the shell: guide first, idle
// perf, a full clean play (take each down, the four close looks by hand —
// finger along the webbing, bend the stitches, turn the metal, unfold the
// label — the call, the reason, the coworker refused), a slip that keeps the
// harness on the stand, the 3-slip strike-out, and the deadly freeze. Audit
// 2026-11-11: the coworker comes even on a fast play (the call waits for
// him), no scene input in the praise window, a deadly run never moves on, and
// gesture hints (a sweep over the harnesses / tools, a drag nudge in a look).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/do_parts.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/harness_check.dart';
import 'package:slm_flutter/features/game/harness_store.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
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
  rungId: '1.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.4',
  lessonTitleBn: '',
  ladderStep: 11,
  doIndex: 1,
  doCount: 2,
);

final _today = DateTime(2026, 11, 7);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];
Finder _button(String text) => find.widgetWithText(DoBigButton, text);

/// Taps the one right card on the deck now up (and its proceed, if a reason).
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// A seed whose deal passes [ok].
int _seedWhere(bool Function(HarnessDeal d) ok) {
  var seed = 0;
  while (!ok(dealHarnesses(math.Random(seed), _today))) {
    seed++;
  }
  return seed;
}

final _hand = find.byKey(const ValueKey('gesture-hint'));

/// Opens the page on a navigator and waits for the guide.
Future<ProviderContainer> _open(WidgetTester t, int seed, {Size physical = const Size(784, 1700)}) async {
  t.view.physicalSize = physical;
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => HarnessCheckPage(ctx: _ctx, pack: harnessPack14, muted: true, seed: seed, today: _today),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Takes the harness on hook [peg] down onto the stand.
Future<void> _takeDown(WidgetTester t, int peg) async {
  expect(_label(HarnessLines.pegLabel(peg)), findsOneWidget);
  await t.tap(_label(HarnessLines.pegLabel(peg)), warnIfMissed: false);
  await _pump(t, 700);
  expect(_label(HarnessLines.benchLabel), findsOneWidget);
}

/// One close look, worked by hand, then put down.
Future<void> _look(WidgetTester t, HarnessCheck c) async {
  await t.tap(_label(HarnessLines.checks[c.index]), warnIfMissed: false);
  await _pump(t, 450);
  final lens = _label(HarnessLines.lensLabel(c));
  expect(lens, findsOneWidget, reason: '$c lens');
  final r = t.getRect(lens);
  switch (c) {
    case HarnessCheck.webbing:
      // The finger runs the whole strap.
      await t.dragFrom(Offset(r.left + 16, r.top + r.height * 0.42), Offset(r.width - 32, 0));
    case HarnessCheck.stitch:
      await t.drag(lens, const Offset(0, 160), warnIfMissed: false);
    case HarnessCheck.hardware:
      await t.drag(lens, const Offset(-260, 0), warnIfMissed: false);
    case HarnessCheck.label:
      await t.drag(lens, const Offset(0, -200), warnIfMissed: false);
  }
  await _pump(t, 300);
  await t.tap(_label(HarnessLines.close), warnIfMissed: false);
  await _pump(t, 400);
  expect(lens, findsNothing);
}

/// All four checks; [onCoworker] after the first.
Future<void> _inspect(WidgetTester t, {Future<void> Function()? onCoworker}) async {
  for (final c in HarnessCheck.values) {
    await _look(t, c);
    if (c == HarnessCheck.webbing && onCoworker != null) await onCoworker();
  }
}

void main() {
  group('rules', () {
    test('deals: waist belt, one sound harness, two damaged; expiry dates follow the flaw; he comes on any full body harness', () {
      final seen = <String>{};
      final gaps = <int>{};
      var hisSound = 0, hisBad = 0;
      for (var s = 0; s < 60; s++) {
        final d = dealHarnesses(math.Random(s), _today);
        expect(d.items.length, 4);
        expect(d.items.where((h) => h.kind == HarnessKind.waistBelt).length, 1);
        expect(d.items.where((h) => h.sound).length, 1);
        expect(d.items.map((h) => h.id).toSet().length, 4);
        for (final h in d.items) {
          if (h.flaw == HarnessFlaw.expired) {
            expect(h.expiry.isBefore(_today), isTrue);
          } else {
            expect(h.expiry.isAfter(_today), isTrue);
          }
          // Made before today, 2–6 years before the expiry (no fixed life).
          expect(h.made.isBefore(_today), isTrue);
          final gap = (h.expiry.year - h.made.year) * 12 + h.expiry.month - h.made.month;
          expect(gap, inInclusiveRange(24, 72));
          gaps.add(gap);
        }
        final his = d.items[d.pushIndex];
        expect(his.kind, HarnessKind.fullBody);
        his.sound ? hisSound++ : hisBad++;
        seen.add(d.items.map((h) => '${h.kind.name}${h.flaw.name}${h.tint}').join('|'));
      }
      expect(seen.length, greaterThan(20), reason: 'every play is dealt fresh');
      expect(gaps.length, greaterThan(10), reason: 'the made date is not a fixed time before the expiry');
      // His coming does not give the answer away.
      expect(hisSound, greaterThan(5));
      expect(hisBad, greaterThan(5));
    });

    test('wearing the waist belt or a damaged harness is deadly; an expired label is a slip; rejecting them is right', () {
      var expiredSeen = 0;
      for (var s = 0; s < 12; s++) {
        final d = dealHarnesses(math.Random(s), _today);
        for (var i = 0; i < 4; i++) {
          final h = d.items[i];
          if (h.sound) continue;
          final a = HarnessRun(d)..index = i;
          final m = a.decide(wear: true);
          expect(m, HarnessMistakes.forFlaw(h));
          if (h.flaw == HarnessFlaw.expired) {
            expiredSeen++;
            expect(m!.deadly, isFalse, reason: 'owner 2026-11-08: expired, no visible damage = slip');
            expect(a.slips, 1);
            expect(a.ended, isFalse);
          } else {
            expect(m!.deadly, isTrue);
            expect(a.ended, isTrue);
          }
          final b = HarnessRun(d)..index = i;
          expect(b.decide(wear: false), isNull);
          expect(b.caught, isNotEmpty);
        }
      }
      expect(expiredSeen, greaterThan(0));
    });

    test('(kept) a damaged harness worn ends the run', () {
      final d = dealHarnesses(math.Random(2), _today);
      for (var i = 0; i < 4; i++) {
        final h = d.items[i];
        if (h.sound || h.flaw == HarnessFlaw.expired) continue;
        final a = HarnessRun(d)..index = i;
        final m = a.decide(wear: true);
        expect(m!.deadly, isTrue);
        expect(a.ended, isTrue);
        final b = HarnessRun(d)..index = i;
        expect(b.decide(wear: false), isNull);
        expect(b.caught, isNotEmpty);
      }
    });

    test('a deadly call ends the run: next() and take() do nothing after it', () {
      final d = dealHarnesses(math.Random(3), _today);
      final belt = d.items.indexWhere((h) => h.kind == HarnessKind.waistBelt);
      final run = HarnessRun(d)..index = belt;
      expect(run.decide(wear: true)!.deadly, isTrue);
      run.next();
      expect(run.index, belt, reason: 'the run stays on the deadly harness');
      expect(run.done, isFalse);
      expect(run.take(d.items[(belt + 1) % 4].id), isFalse);
      run.check(HarnessCheck.webbing);
      expect(run.checks, isEmpty);
    });

    test('the sound harness: wear after all four checks; unchecked or pushed is a slip; a reject is a slip and it stays', () {
      final d = dealHarnesses(math.Random(2), _today);
      final ok = d.items.indexWhere((h) => h.sound);
      final a = HarnessRun(d)..index = ok;
      a.check(HarnessCheck.webbing);
      expect(a.decide(wear: true), HarnessMistakes.skipped);
      expect(a.shown, isTrue);
      final b = HarnessRun(d)..index = ok;
      expect(b.decide(wear: false), HarnessMistakes.goodRejected);
      expect(b.shown, isFalse, reason: 'still on the stand');
      expect(b.slips, 1);
      for (final k in HarnessCheck.values) {
        b.check(k);
      }
      expect(b.thorough, isTrue);
      expect(b.decide(wear: true), isNull);
      expect(b.caught, contains(HarnessLines.caughtHabit));
      // Worn on his say-so: the slip, even after every check.
      final e = HarnessRun(d)..index = ok;
      for (final k in HarnessCheck.values) {
        e.check(k);
      }
      expect(e.decide(wear: true, pushed: true), HarnessMistakes.skipped);
      expect(e.slips, 1);
    });

    test('three rejects of the sound harness: three slips, 55%', () {
      final d = dealHarnesses(math.Random(4), _today);
      final run = HarnessRun(d)..index = d.items.indexWhere((h) => h.sound);
      for (var i = 0; i < 3; i++) {
        expect(run.decide(wear: false), HarnessMistakes.goodRejected);
      }
      expect(run.slips, 3);
      expect(run.percent, 55);
    });

    test('take: any harness on the board comes down next; the order follows the hands', () {
      final d = dealHarnesses(math.Random(7), _today);
      final run = HarnessRun(d);
      final last = d.items.last;
      expect(run.take(last.id), isTrue);
      expect(run.current.id, last.id);
      expect(run.onBoard.length, 4);
      expect(run.decide(wear: last.sound), isNull);
      run.next();
      expect(run.onBoard.map((h) => h.id), isNot(contains(last.id)));
      expect(run.take(last.id), isFalse, reason: 'already done');
      expect(run.pushOnHand, run.current.id == d.items[d.pushIndex].id);
    });

    test('the coworker missed his harness (the call came first): he comes on the next full body one', () {
      for (var s = 0; s < 20; s++) {
        final d = dealHarnesses(math.Random(s), _today);
        final run = HarnessRun(d);
        final his = d.items[d.pushIndex];
        expect(run.take(his.id), isTrue);
        expect(run.pushOnHand, isTrue);
        run.decide(wear: false);
        run.next();
        final left = run.onBoard.where((h) => h.kind == HarnessKind.fullBody).toList();
        expect(run.movePush(), left.isNotEmpty);
        if (left.isEmpty) continue;
        expect(run.pushId, left.first.id);
        expect(run.take(run.pushId), isTrue);
        expect(run.pushOnHand, isTrue);
      }
    });

    test('every harness mistake has its picture and a lesson point (0–3 of lesson 1.4)', () {
      for (final m in HarnessMistakes.all) {
        expect(m.art, startsWith('assets/game/art/harness/'));
        expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      expect(HarnessMistakes.waistBelt.lessonPoint, 0);
    });

    test('a tap on the harness asks for the part it hit', () {
      const box = Size(180, 374);
      Offset at(double x, double y) => Offset(x - 100, y - 56);
      expect(HarnessPainter.zoneAt(HarnessShape.fullBody, at(148, 250), box), HarnessCheck.label.index);
      expect(HarnessPainter.zoneAt(HarnessShape.fullBody, at(190, 70), box), HarnessCheck.hardware.index);
      expect(HarnessPainter.zoneAt(HarnessShape.fullBody, at(230, 200), box), HarnessCheck.stitch.index);
      expect(HarnessPainter.zoneAt(HarnessShape.fullBody, at(150, 150), box), HarnessCheck.webbing.index);
      expect(HarnessPainter.zoneAt(HarnessShape.belt, at(180, 300), box), HarnessCheck.hardware.index);
      expect(HarnessPainter.zoneAt(HarnessShape.fullBody, const Offset(2, 2), box), isNull);
    });

    test('reasons: fit what it had, same length, big enough; the coworker: fair cards, his lines recorded', () {
      final all = [...HarnessLines.soundWhy, ...HarnessLines.myths, for (final f in HarnessLines.faults) ...HarnessLines.faultWhy(f)];
      // Tighter than the default 1.3: the right card must not be the long one.
      expectSameLength('why', all, ratio: 1.2);
      expect(all.toSet().length, all.length);
      final d = dealHarnesses(math.Random(1), _today);
      final sound = d.items.firstWhere((h) => h.sound);
      expect(HarnessLines.whyRight(sound), HarnessLines.soundWhy);
      expect(HarnessLines.whyWrong(sound), HarnessLines.myths, reason: 'worn: the myths are the wrong reasons');
      expectLibrary('sound', HarnessLines.whyRight(sound), HarnessLines.whyWrong(sound));
      for (final f in HarnessLines.faults) {
        final h = HarnessItem(
          id: 'x',
          kind: f == 'belt' ? HarnessKind.waistBelt : HarnessKind.fullBody,
          flaw: f == 'belt' ? HarnessFlaw.none : HarnessFlaw.values.byName(f),
          webbingAt: 0.5,
          made: DateTime(2022),
          expiry: DateTime(2027),
        );
        expect(HarnessLines.faultOf(h), f);
        expect(HarnessLines.whyRight(h), HarnessLines.faultWhy(f));
        expectLibrary(f, HarnessLines.whyRight(h), HarnessLines.whyWrong(h));
        expect(HarnessLines.faultBn(h), isNotEmpty);
        for (var s = 0; s < 12; s++) {
          final deal = dealChoices(HarnessLines.whyRight(h), HarnessLines.whyWrong(h), math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
          for (final o in deal.where((o) => !o.correct)) {
            // A wrong card is another fault's reason, never a myth or its own.
            expect(HarnessLines.myths, isNot(contains(o.textBn)));
            expect(HarnessLines.faultWhy(f), isNot(contains(o.textBn)));
          }
        }
      }
      const c = HarnessLines.coworker;
      expectSameLength('choice', [...c.right, ...c.wrong]);
      expectLibrary('choice', c.right, c.wrong);
      for (final l in c.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
    });

    test('dates on screen use English digits', () {
      expect(HarnessLines.expiry(DateTime(2027, 3)), 'মেয়াদ: 03-2027');
      expect(HarnessLines.calendarDay(_today), '07');
      expect(HarnessLines.pegLabel(0), 'হুক 1');
    });

    test('no detail the lesson does not give: no standard number on the label', () {
      expect(HarnessLines.fullBodyName, isNot(contains('IS')));
      expect(HarnessLines.fullBodyName, isNot(matches(RegExp(r'\d'))));
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
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: HarnessCheckPage(ctx: _ctx, pack: harnessPack14, muted: true, seed: 2, today: _today)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
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
        debugPrint('PERF harness ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('waits quietly on the stand, after a close look', (t) async {
      final c = await _open(t, 2);
      await _takeDown(t, 0);
      await _look(t, HarnessCheck.label);
      await _pump(t, 14000);
      if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
        await _pickRight(t, HarnessLines.coworker.right);
        await _pump(t, 14000);
      }
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (t.binding.hasScheduledFrame) frames++;
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(frames, lessThan(12));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: HarnessCheckPage(ctx: _ctx, pack: harnessPack14, muted: true, seed: 2, today: _today)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 600);
      // No tools before a harness is taken down.
      expect(_label(HarnessLines.checks[0]), findsNothing);
      expect(_label(HarnessLines.pegLabel(0)), findsOneWidget);
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
      expect(lines.every((l) => l.contains(HarnessLines.take)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: take each down (last hook first), four looks by hand, refuse him, right call and reason each time → pass', (t) async {
      const seed = 5;
      final deal = dealHarnesses(math.Random(seed), _today);
      final c = await _open(t, seed);
      var met = false;
      // Free order: the last hook first, the first hook last.
      for (final i in const [3, 2, 1, 0]) {
        final h = deal.items[i];
        await _takeDown(t, i);
        await _inspect(
          t,
          onCoworker: i == deal.pushIndex
              ? () async {
                  // He peeps in after the first look; the guide asks; refuse him.
                  await _pump(t, 3500);
                  expect(find.byType(CoworkerPeek), findsOneWidget);
                  await _pickRight(t, HarnessLines.coworker.right);
                  await _pump(t, 2500);
                  met = true;
                }
              : null,
        );
        await t.tap(_button(h.sound ? HarnessLines.wear : HarnessLines.reject));
        await _pump(t, 2500);
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'harness $i');
        expect(find.text(h.sound ? HarnessLines.whyWear : HarnessLines.whyReject), findsWidgets);
        // The deck asks what it had: the fault is not named yet.
        expect(find.text(HarnessLines.faultBn(h)), findsNothing);
        await _pickRight(t, HarnessLines.whyRight(h));
        if (!h.sound) {
          // Named chip shows right after proceed; send-off clears it ~0.7–1.5 s later.
          expect(find.text(HarnessLines.faultBn(h)), findsOneWidget, reason: 'harness $i: named once paid');
        }
        // The next comes by itself: back to the board (or the result).
        await _pump(t, i == 0 ? 6000 : 3000);
      }
      expect(met, isTrue);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.4/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['1.4/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(HarnessLines.caughtCall), findsOneWidget);
      expect(find.text(HarnessLines.caughtHabit), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong reason burns the table; the right one after it still pays 5', (t) async {
      // Not his harness (on his, the call would wait for him).
      final seed = _seedWhere((d) => !d.items.first.sound && d.pushIndex != 0);
      final h = dealHarnesses(math.Random(seed), _today).items.first;
      final c = await _open(t, seed);
      int score() => t.widget<LevelShellBar>(find.byType(LevelShellBar)).levelScore;
      await _takeDown(t, 0);
      // No checks: 15 waits on the table (no +5); not his harness.
      await t.tap(_button(HarnessLines.reject));
      await _pump(t, 2500);
      expect(find.text(HarnessLines.whyReject), findsWidgets);
      expect(score(), 0);
      final wrong = _onScreen(HarnessLines.whyWrong(h));
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(score(), 0, reason: 'burnt, not paid');
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the deck stays for the retry');
      await _pickRight(t, HarnessLines.whyRight(h));
      await _pump(t, 2500);
      expect(score(), 5, reason: 'a right retry pays 5');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a sound harness rejected is a slip with its card; it stays on the stand; three strike out', (t) async {
      final seed = _seedWhere((d) => d.items.first.sound && d.pushIndex != 0);
      final c = await _open(t, seed);
      await _takeDown(t, 0);
      for (var i = 0; i < 3; i++) {
        await t.tap(_button(HarnessLines.reject));
        await _pump(t, 900);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget);
          expect(find.text(MistakeLines.readLesson), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_button(HarnessLines.wear), findsOneWidget, reason: 'still on the stand to judge');
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(LevelPassPanel), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.map((m) => m.key), contains(HarnessMistakes.goodRejected.key));
      expect(s.rungProgress['1.4/do/0'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('the coworker comes even on a fast play: পরব / বাতিল on his harness waits for him', (t) async {
      for (final wantSound in [false, true]) {
        final seed = _seedWhere((d) => d.items[d.pushIndex].sound == wantSound && d.items[d.pushIndex].flaw != HarnessFlaw.expired);
        final deal = dealHarnesses(math.Random(seed), _today);
        final h = deal.items[deal.pushIndex];
        SharedPreferences.setMockInitialValues({});
        final c = await _open(t, seed);
        int score() => t.widget<LevelShellBar>(find.byType(LevelShellBar)).levelScore;
        await _takeDown(t, deal.pushIndex);
        // At once, without a single look: the call.
        await t.tap(_button(h.sound ? HarnessLines.wear : HarnessLines.reject));
        await t.pump();
        expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in (sound: $wantSound)');
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'the call waited');
        expect(find.text(HarnessLines.whyReject), findsNothing);
        expect(find.text(HarnessLines.whyWear), findsNothing);
        await _pickRight(t, HarnessLines.coworker.right);
        await _pump(t, 2500);
        expect(score(), 10, reason: 'refused him');
        // He has gone: the call now works.
        if (h.sound) {
          await _inspect(t);
          await t.tap(_button(HarnessLines.wear));
        } else {
          await t.tap(_button(HarnessLines.reject));
        }
        await _pump(t, 2500);
        expect(find.byType(CoworkerPeek), findsNothing);
        expect(find.text(h.sound ? HarnessLines.whyWear : HarnessLines.whyReject), findsWidgets);
        expect(t.takeException(), isNull);
        await _close(t, c);
      }
    });

    // Regression check of existing behaviour: here a right call sets
    // _run.shown, which already blocks the stand and the board until the item
    // is sent off. The added !tableBusy guard is defence in depth and is not
    // what makes this test pass.
    testWidgets('praise window (regression): a right call keeps the scene locked until the reason deck (no lens, no second take)', (t) async {
      final seed = _seedWhere((d) => !d.items.first.sound && d.pushIndex != 0);
      final h = dealHarnesses(math.Random(seed), _today).items.first;
      final c = await _open(t, seed);
      await _takeDown(t, 0);
      await t.tap(_button(HarnessLines.reject));
      await t.pump(const Duration(milliseconds: 60));
      // In the praise window: tap the harness on the stand and another hook.
      await t.tap(_label(HarnessLines.benchLabel), warnIfMissed: false);
      await t.tap(_label(HarnessLines.pegLabel(1)), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 300));
      for (final k in HarnessCheck.values) {
        expect(_label(HarnessLines.lensLabel(k)), findsNothing);
      }
      await _pump(t, 2200);
      expect(find.text(HarnessLines.whyReject), findsWidgets);
      await _pickRight(t, HarnessLines.whyRight(h));
      await _pump(t, 3000);
      // Back to the board: hook 2 is still there, nothing was taken meanwhile.
      expect(_label(HarnessLines.pegLabel(1)), findsOneWidget);
      expect(_label(HarnessLines.benchLabel), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hints: the hand on the board, on the stand and in a close look', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.pushIndex != 0);
      final c = await _open(t, seed);
      // The board: a sweep over the harnesses.
      expect(_hand, findsNothing);
      await _pump(t, 9000);
      expect(_hand, findsOneWidget, reason: 'board');
      await _takeDown(t, 0);
      expect(_hand, findsNothing, reason: 'a touch hides it');
      // On the stand: a sweep over the tools.
      await _pump(t, 9000);
      expect(_hand, findsOneWidget, reason: 'stand');
      // A close look: a short drag nudge inside the lens.
      await t.tap(_label(HarnessLines.checks[HarnessCheck.stitch.index]), warnIfMissed: false);
      await _pump(t, 450);
      final lens = t.getRect(_label(HarnessLines.lensLabel(HarnessCheck.stitch)));
      await _pump(t, 9000);
      expect(_hand, findsOneWidget, reason: 'lens');
      final tip = t.state<IdleHintState>(find.byType(IdleHint).first).debugFrame?.tip;
      expect(tip, isNotNull);
      expect(lens.inflate(4).contains(tip!), isTrue, reason: 'the nudge stays in the lens: $tip in $lens');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hints: the scene hand stays off while a deck, the coworker or a mistake card is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      // The scene's own hint is the outermost IdleHint (the decks bring theirs).
      bool sceneHand() => t.state<IdleHintState>(find.byType(IdleHint).first).showing;
      final cases = <(String, bool Function(HarnessDeal))>[
        ('reason deck', (d) => !d.items.first.sound && d.pushIndex != 0),
        ('mistake card', (d) => d.items.first.sound && d.pushIndex != 0),
        ('coworker', (d) => d.pushIndex == 0),
      ];
      for (final (what, ok) in cases) {
        SharedPreferences.setMockInitialValues({});
        final c = await _open(t, _seedWhere(ok));
        await _takeDown(t, 0);
        await t.tap(_button(HarnessLines.reject));
        await _pump(t, 2500);
        switch (what) {
          case 'reason deck':
            expect(find.text(HarnessLines.whyReject), findsWidgets);
          case 'mistake card':
            expect(find.byType(MistakeCard), findsOneWidget);
          default:
            expect(find.byType(CoworkerPeek), findsOneWidget);
        }
        for (var i = 0; i < 6; i++) {
          await _pump(t, 1500);
          expect(sceneHand(), isFalse, reason: '$what is up ($i)');
        }
        expect(t.takeException(), isNull);
        await _close(t, c);
      }
    });

    testWidgets('gesture hints: on a 320-wide phone the webbing nudge stops short of the 0.2 band', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, _seedWhere((d) => d.pushIndex != 0), physical: const Size(640, 1700));
      await _takeDown(t, 0);
      await t.tap(_label(HarnessLines.checks[HarnessCheck.webbing.index]), warnIfMissed: false);
      await _pump(t, 450);
      final lens = t.getRect(_label(HarnessLines.lensLabel(HarnessCheck.webbing)));
      expect(lens.width, lessThan(300));
      // Card border 5 + painter side 14; the band starts 0.2 of the strip in.
      final band = lens.left + 5 + 14 + 0.2 * (lens.width - 10 - 28);
      await _pump(t, 9000);
      expect(_hand, findsOneWidget);
      var maxX = double.negativeInfinity;
      for (var i = 0; i < 60; i++) {
        await t.pump(const Duration(milliseconds: 50));
        final tip = t.state<IdleHintState>(find.byType(IdleHint).first).debugFrame?.tip;
        if (tip != null) maxX = math.max(maxX, tip.dx);
      }
      expect(maxX, greaterThan(lens.left), reason: 'the hand was seen');
      expect(maxX, lessThan(band - 6), reason: 'tip $maxX vs band $band');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('wearing the waist belt: the store freezes first, then the card', (t) async {
      const seed = 3;
      final deal = dealHarnesses(math.Random(seed), _today);
      final belt = deal.items.indexWhere((h) => h.kind == HarnessKind.waistBelt);
      final c = await _open(t, seed);
      await _takeDown(t, belt);
      await t.tap(_button(HarnessLines.wear));
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(HarnessFall), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, HarnessMistakes.waistBelt.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him on a damaged harness: worn, the freeze; on the sound one: the slip', (t) async {
      for (final wantSound in [false, true]) {
        var seed = 0;
        while (true) {
          final d = dealHarnesses(math.Random(seed), _today);
          if (d.items[d.pushIndex].sound == wantSound) break;
          seed++;
        }
        final deal = dealHarnesses(math.Random(seed), _today);
        SharedPreferences.setMockInitialValues({});
        final c = await _open(t, seed);
        await _takeDown(t, deal.pushIndex);
        await _look(t, HarnessCheck.label);
        await _pump(t, 3500);
        expect(find.byType(CoworkerPeek), findsOneWidget);
        final wrong = _onScreen(HarnessLines.coworker.wrong);
        expect(wrong, isNotEmpty);
        await t.tap(wrong.first, warnIfMissed: false);
        await confirmChoice(t);
        await _pump(t, 1200);
        final s = c.read(gameSaveProvider);
        if (wantSound) {
          expect(find.byType(FreezeFrame), findsNothing);
          expect(find.text(MistakeLines.slipHead), findsOneWidget);
          expect(s.mistakes.single.key, HarnessMistakes.skipped.key);
        } else {
          expect(find.byType(FreezeFrame), findsOneWidget);
          await _pump(t, 3500);
          expect(find.byType(MistakeCard), findsOneWidget);
          expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
        }
        await _close(t, c);
      }
    });
  });
}
