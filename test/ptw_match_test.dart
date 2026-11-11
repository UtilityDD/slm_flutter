// Lesson 1.6, কাজ 1 (কাগজ মেলাও): permit rules, the phone call, deal variety,
// dates from the device's day, reason libraries that fit the permit, his
// recorded line, and the level in the shell: idle perf, the guide first, a
// full clean play (hold the permit up, the lens on each field, stop or start,
// the reasons, the coworker refused on the phone round), slips (a false stop
// keeps the permit; three strike out), a deadly start and listening to him.
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/ptw_match.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '1.6/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.6',
  lessonTitleBn: '',
  ladderStep: 17,
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

/// Taps the one right card on the deck now up.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await t.pump();
  // Wait for reason zoom (coworker decks have no proceed).
  for (var i = 0; i < 40 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

/// A seed whose deal satisfies [ok].
int _seedWhere(bool Function(List<PtwRound> r) ok, {int from = 0}) {
  var s = from;
  while (!ok(dealPermits(math.Random(s), _today))) {
    s++;
  }
  return s;
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => PtwMatchPage(ctx: _ctx, pack: ptwPack16, muted: true, seed: seed, today: _today),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 800);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Drags the clipboard up beside the pole.
Future<void> _lift(WidgetTester t) async {
  final clip = find.byKey(const ValueKey('sheet-drag'));
  expect(clip, findsOneWidget);
  await t.drag(clip, const Offset(0, -440), warnIfMissed: false);
  await _pump(t, 600);
  expect(find.byKey(const ValueKey('sheet-drag')), findsNothing, reason: 'held up');
  expect(find.text(PtwLines.start), findsOneWidget);
}

/// The lens on [f]: mark it matching, or stop on it.
Future<void> _lens(WidgetTester t, PtwField f, {required bool stop}) async {
  await t.tap(_label(PtwLines.labels[f]!), warnIfMissed: false);
  await _pump(t, 400);
  expect(_label(PtwLines.lensLabel), findsOneWidget, reason: '$f');
  await t.tap(find.text(stop ? PtwLines.stop : PtwLines.matchOk));
  await _pump(t, stop ? 900 : 400);
}

void main() {
  group('rules', () {
    test('deals: one phone call (never first), one valid form, two with one fault each', () {
      final seen = <String>{};
      for (var s = 0; s < 60; s++) {
        final r = dealPermits(math.Random(s), _today);
        expect(r.length, 4);
        expect(r.first.phone, isFalse);
        expect(r.where((x) => x.phone).length, 1);
        final forms = [for (final x in r) if (!x.phone) x.form!];
        expect(forms.where((f) => f.fault == PtwFault.none).length, 1);
        expect(forms.where((f) => f.fault != PtwFault.none).map((f) => f.fault).toSet().length, 2);
        for (final x in r.where((x) => !x.phone)) {
          final f = x.form!;
          expect(f.feederBn == x.site.feederBn, f.fault != PtwFault.feeder);
          expect(f.nameBn == x.site.teamBn, f.fault != PtwFault.name);
          expect(f.nameBn, endsWith(' টিম'), reason: "the permit names a team (pro tip 3), not the trainee");
          expect(x.site.teamBn, isNot(contains(x.site.nameBn)), reason: 'the trainee is not his own team leader');
          expect(f.signed, f.fault != PtwFault.unsigned);
        }
        seen.add(r.map((x) => '${x.form?.fault}${x.site.pole}').join('|'));
      }
      expect(seen.length, greaterThan(50), reason: 'every play is dealt fresh');
    });

    test("dates follow the device's day; English digits only", () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final bnDigit = RegExp('[০-৯]');
      for (var s = 0; s < 40; s++) {
        for (final x in dealPermits(math.Random(s), today)) {
          expect(x.site.nowBn, isNot(matches(bnDigit)));
          final f = x.form;
          if (f == null) continue;
          for (final v in PtwField.values) {
            expect(f.valueOf(v), isNot(matches(bnDigit)), reason: '$v');
          }
          expect(f.dateBn, f.fault == PtwFault.expiredDate ? PtwLines.dateOf(today.subtract(const Duration(days: 1))) : PtwLines.dateOf(today));
          expect(f.numberBn, contains('${today.year}'));
        }
      }
    });

    test('starting: valid is right; wrong feeder / unsigned / expired are deadly; pole or name a slip', () {
      PtwRun runFor(PtwFault f) {
        for (var s = 0; s < 400; s++) {
          final r = dealPermits(math.Random(s), _today);
          final i = r.indexWhere((x) => x.form?.fault == f);
          if (i >= 0) return PtwRun(r)..index = i;
        }
        throw StateError('no $f');
      }

      expect(runFor(PtwFault.none).decide(start: true), isNull);
      for (final f in [PtwFault.feeder, PtwFault.unsigned, PtwFault.expiredDate, PtwFault.expiredTime]) {
        final run = runFor(f);
        expect(run.decide(start: true)!.deadly, isTrue, reason: '$f');
        expect(run.ended, isTrue);
      }
      for (final f in [PtwFault.place, PtwFault.name]) {
        final run = runFor(f);
        expect(run.decide(start: true)!.deadly, isFalse);
        expect(run.slips, 1);
        expect(run.shown, isTrue, reason: 'the play moves on');
      }
    });

    test('stopping: the right field is clean; a matching field is a slip and the permit stays; the phone needs paper', () {
      final r = dealPermits(math.Random(3), _today);
      final bad = r.indexWhere((x) => x.form != null && x.form!.fault != PtwFault.none);
      final a = PtwRun(r)..index = bad;
      expect(a.decide(start: false, flagged: r[bad].form!.fault.field), isNull);
      expect(a.shown, isTrue);
      final b = PtwRun(r)..index = bad;
      final wrong = ptwLensFields.firstWhere((f) => f != r[bad].form!.fault.field);
      expect(b.decide(start: false, flagged: wrong), PtwMistakes.wrongField);
      expect(b.shown, isFalse, reason: 'still to judge');
      expect(b.decide(start: false, flagged: r[bad].form!.fault.field), isNull);
      expect(b.slips, 1);
      final ok = r.indexWhere((x) => x.form?.fault == PtwFault.none);
      final c = PtwRun(r)..index = ok;
      expect(c.decide(start: false, flagged: PtwField.feeder), PtwMistakes.falseStop);
      expect(c.shown, isFalse);
      expect(c.decide(start: true), isNull);
      expect(c.caught, contains(PtwLines.caughtValid));
      final phone = r.indexWhere((x) => x.phone);
      expect((PtwRun(r)..index = phone).answerPhone(held: false), PtwMistakes.verbal);
      expect((PtwRun(r)..index = phone).answerPhone(held: false)!.deadly, isTrue);
      final held = PtwRun(r)..index = phone;
      expect(held.answerPhone(held: true), isNull);
      expect(held.caught, contains(PtwLines.caughtPhone));
    });

    test('three false stops on a valid permit: 3 slips (55 %)', () {
      final r = dealPermits(math.Random(3), _today);
      final run = PtwRun(r)..index = r.indexWhere((x) => x.form?.fault == PtwFault.none);
      for (var i = 0; i < 3; i++) {
        expect(run.decide(start: false, flagged: PtwField.name), PtwMistakes.falseStop);
      }
      expect(run.slips, 3);
      expect(run.percent, 55);
    });

    test('every mistake has its picture and a lesson point (0–2 of lesson 1.6)', () {
      for (final m in PtwMistakes.all) {
        expect(m.art, startsWith('assets/game/art/ptw/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(PtwMistakes.verbal.deadly && PtwMistakes.wrongFeeder.deadly && PtwMistakes.unsigned.deadly && PtwMistakes.expired.deadly, isTrue);
      expect(PtwMistakes.wrongPlace.deadly || PtwMistakes.wrongName.deadly || PtwMistakes.falseStop.deadly || PtwMistakes.wrongField.deadly, isFalse);
    });

    test('reasons fit the permit, are the same length and big enough', () {
      final all = {
        ...PtwLines.whyValid,
        ...PtwLines.mythsStart,
        ...PtwLines.whyVerbal,
        ...PtwLines.phoneExcuses,
        for (final f in PtwFault.values) ...PtwLines.faultWhy(f),
      };
      expectSameLength('reasons', all.toList(), ratio: 1.25);
      // One round of each kind.
      final site = PtwSite(feederBn: 'x', pole: 50, nameBn: 'y', teamBn: 'z', today: _today, nowBn: '11:20');
      PtwRound paper(PtwFault f) => PtwRound(
            site: site,
            form: PtwForm(numberBn: '', feederBn: '', placeBn: '', jobBn: '', nameBn: '', dateBn: '', timeBn: '', signed: true, fault: f),
          );
      final cases = [for (final f in PtwFault.values) paper(f), PtwRound(site: site)];
      for (final r in cases) {
        final name = r.phone ? 'phone' : '${r.form!.fault}';
        final right = PtwLines.whyRight(r);
        final wrong = PtwLines.whyWrong(r);
        expectLibrary(name, right, wrong);
        for (final w in wrong) {
          expect(right, isNot(contains(w)), reason: '$name: $w');
        }
        for (var s = 0; s < 40; s++) {
          final rng = math.Random(s);
          final deal = dealChoices(right, PtwLines.whyWrongDeal(r, rng), rng);
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
          // Never two phrasings of the same fault on one deck.
          final kinds = [
            for (final o in deal.where((o) => !o.correct))
              for (final f in PtwFault.values)
                if (f != PtwFault.none && f != PtwFault.expiredTime && PtwLines.faultWhy(f).contains(o.textBn)) f,
          ];
          expect(kinds.toSet().length, kinds.length, reason: '$name: ${deal.map((o) => o.textBn)}');
        }
        // A stop deck never offers a reason that is the lesson's rule: the
        // phone's reasons ("হাতে স্বাক্ষরিত পারমিট ছাড়া কাজ শুরু নয়") stay off it.
        if (!r.phone) {
          for (final v in PtwLines.whyVerbal) {
            expect(wrong, isNot(contains(v)), reason: '$name: $v');
          }
        }
      }
      // The phone round has no paper: its wrong cards are field excuses, no paper faults.
      final phoneWrong = PtwLines.whyWrong(PtwRound(site: site));
      expect(phoneWrong, PtwLines.phoneExcuses);
      for (final f in PtwFault.values) {
        for (final w in PtwLines.faultWhy(f)) {
          expect(phoneWrong, isNot(contains(w)));
        }
      }
      // An expired date or time is one reason: neither deck offers it as wrong.
      for (final f in [PtwFault.expiredDate, PtwFault.expiredTime]) {
        expect(PtwLines.whyWrong(paper(f)), isNot(containsAll(PtwLines.whyExpired)));
        expect(PtwLines.whyRight(paper(f)), PtwLines.whyExpired);
      }
      expect(PtwLines.whyWrong(paper(PtwFault.none)), PtwLines.mythsStart);
      expect(PtwLines.whyRight(PtwRound(site: site)), PtwLines.whyVerbal);
    });

    test('the coworker: same-length cards, a big enough library, his lines recorded', () {
      const c = PtwLines.coworker;
      expectSameLength('coworker', [...c.right, ...c.wrong]);
      expectLibrary('coworker', c.right, c.wrong);
      for (final l in c.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
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
          child: MaterialApp(home: PtwMatchPage(ctx: _ctx, pack: ptwPack16, muted: true, seed: 2, today: _today)),
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
        debugPrint('PERF ptw ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: PtwMatchPage(ctx: _ctx, pack: ptwPack16, muted: true, seed: 2, today: _today)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.byKey(const ValueKey('hud-guide')), findsNothing);
      await waitIntro(t);
      await _pump(t, 800);
      expect(find.byKey(const ValueKey('sheet-drag')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide says the task again, a different way each time', (t) async {
      final c = await _open(t, 2);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(PtwLines.taskLift)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: hold each permit up, the lens on every field, stop or start, the reasons, refuse him → pass', (t) async {
      const seed = 5;
      final rounds = dealPermits(math.Random(seed), _today);
      final c = await _open(t, seed);
      var met = false;
      for (var i = 0; i < 4; i++) {
        final r = rounds[i];
        if (r.phone) {
          // The phone rings: answer it; he pushes on its word; refuse him.
          expect(find.byKey(const ValueKey('sheet-drag')), findsNothing);
          await t.tap(_label(PtwLines.phoneLabel), warnIfMissed: false);
          await _pump(t, 400);
          expect(find.textContaining(PtwLines.phoneLine), findsOneWidget);
          await _pump(t, 3200);
          expect(find.byType(CoworkerPeek), findsOneWidget);
          await _pickRight(t, PtwLines.coworker.right);
          await _pump(t, 2800);
          expect(find.text(PtwLines.whyPhone), findsWidgets);
          met = true;
        } else {
          await _lift(t);
          final bad = r.form!.fault.field;
          for (final f in ptwLensFields) {
            await _lens(t, f, stop: f == bad);
            if (f == bad) break;
          }
          if (bad == null) {
            await t.tap(find.text(PtwLines.start));
            await _pump(t, 2500);
            expect(find.text(PtwLines.whyStart), findsWidgets);
          } else {
            await _pump(t, 1600);
            expect(find.text(PtwLines.mismatch), findsOneWidget, reason: 'round $i: the field is marked');
            expect(find.text(PtwLines.whyStop), findsWidgets);
          }
        }
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i');
        await _pickRight(t, PtwLines.whyRight(r));
        await _pump(t, i == 3 ? 6000 : 4000);
      }
      expect(met, isTrue);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.6/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['1.6/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(PtwLines.caughtPhone), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a false stop is a slip with its card; the permit stays; three of them strike out', (t) async {
      final seed = _seedWhere((r) => r.first.form!.fault == PtwFault.none);
      final c = await _open(t, seed);
      await _lift(t);
      for (var i = 0; i < 3; i++) {
        await _lens(t, ptwLensFields[i], stop: true);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget);
          expect(find.text(MistakeLines.readLesson), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(find.text(PtwLines.start), findsOneWidget, reason: 'the same permit is still to judge');
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.map((m) => m.key), contains(PtwMistakes.falseStop.key));
      await _close(t, c);
    });

    testWidgets('stopping on the wrong field: a slip, then the right field is still clean', (t) async {
      final seed = _seedWhere((r) => r.first.form!.fault != PtwFault.none);
      final r0 = dealPermits(math.Random(seed), _today).first;
      final c = await _open(t, seed);
      await _lift(t);
      final wrong = ptwLensFields.firstWhere((f) => f != r0.form!.fault.field);
      await _lens(t, wrong, stop: true);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _lens(t, r0.form!.fault.field!, stop: true);
      await _pump(t, 1600);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(find.text(PtwLines.whyStop), findsWidgets);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, PtwMistakes.wrongField.key);
      await _close(t, c);
    });

    testWidgets('starting on a pole or name mismatch: the slip card, then the next job comes', (t) async {
      final seed = _seedWhere((r) => r.first.form!.fault == PtwFault.place || r.first.form!.fault == PtwFault.name);
      final c = await _open(t, seed);
      await _lift(t);
      await t.tap(find.text(PtwLines.start));
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(PtwLines.mismatch), findsOneWidget, reason: 'where it did not match');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2000);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      final next = dealPermits(math.Random(seed), _today)[1];
      expect(find.byKey(const ValueKey('sheet-drag')), next.phone ? findsNothing : findsOneWidget, reason: 'the next job');
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, anyOf(PtwMistakes.wrongPlace.key, PtwMistakes.wrongName.key));
      await _close(t, c);
    });

    testWidgets('starting on a deadly permit: the site freezes first, then the card', (t) async {
      final seed = _seedWhere((r) => const [PtwFault.feeder, PtwFault.unsigned, PtwFault.expiredDate, PtwFault.expiredTime].contains(r.first.form!.fault));
      final c = await _open(t, seed);
      await _lift(t);
      await t.tap(find.text(PtwLines.start));
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him on the phone round: deadly — the freeze, then the card', (t) async {
      final seed = _seedWhere((r) => r[1].phone && r[0].form!.fault == PtwFault.none);
      final c = await _open(t, seed);
      await _lift(t);
      await t.tap(find.text(PtwLines.start));
      await _pump(t, 2500);
      await _pickRight(t, PtwLines.whyValid);
      await _pump(t, 4000);
      await t.tap(_label(PtwLines.phoneLabel), warnIfMissed: false);
      await _pump(t, 3600);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(PtwLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, PtwMistakes.verbal.key);
      await _close(t, c);
    });
  });
}
