// Lesson 3.4 (ডিও ফিউজ ও হর্ন গ্যাপ ফিউজ), কাজ 2 "হর্ন গ্যাপ ঠিক করো": the rules
// (শাটডাউন → PTW → টেস্ট → আর্থ before a hand goes on the sets; spot every
// fault on the three sets; the plate's rating, tied taut; once the line is
// back on: it holds, or it blows again → keep it off and find the fault),
// the deal, the reason libraries, and the level in the shell: idle perf, the
// guide first, full clean plays (the coworker refused), a slip card, a
// flagged sound part costs a slip, the 3-slip strike-out, the coworker comes
// even on a fast play (ক and ঘ), and the deadly freeze (listening to "লাইন
// চালু থাকতেই ফিউজটা বদলে দাও" — the ladder's climb-live deadly).
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
import 'package:slm_flutter/features/game/m3_horngap_set.dart';
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
  rungId: '3.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '3.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m3HorngapSetPacks['do_3_4_b']!;
typedef _L = M3HorngapSetLines;
typedef _M = M3HorngapSetMistakes;
typedef _S = M3HorngapSetStep;
typedef _F = M3HorngapSetFault;
typedef _P = M3HorngapSetPart;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_horngap_set/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(b.buffer);
    }
    return rootBundle.load(key);
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
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3HorngapSetGeo get _geo => M3HorngapSetGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _tapPart(WidgetTester t, int phase, M3HorngapSetPart part) async {
  await t.tapAt(_geo.partAt(phase, part) * _k);
  await _pump(t, 300);
}

/// A run that has played the stations before [i] right (for the reason
/// libraries of station i).
M3HorngapSetRun _runAt(M3HorngapSetDeal d, int i) => M3HorngapSetRun(d)..index = i;

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M3HorngapSetPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 300);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _refuseHim(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 5000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, _L.coworker.right);
  await _pump(t, 1500);
}

Future<void> _why(WidgetTester t, M3HorngapSetDeal d, int i) async {
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'station $i');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'station $i');
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(_runAt(d, i)));
  await _pump(t, 3000);
}

/// A whole play, right. [fast]: the decisive control is tapped before he
/// comes (শাটডাউন in ক, the act in ঘ) — it must wait for him.
Future<void> _playRight(WidgetTester t, M3HorngapSetDeal d, {bool fast = false}) async {
  // ক
  if (d.callAt == 0) {
    if (fast) {
      await t.tap(_label(_L.step(_S.shutdown)));
      await t.pump();
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the শাটডাউন waits for him');
    }
    await _refuseHim(t);
  }
  for (final s in _S.values) {
    await t.tap(_label(_L.step(s)));
    await _pump(t, 250);
  }
  await t.tap(find.text(_L.climb));
  await _pump(t, 800);
  await _why(t, d, 0);
  // খ
  for (final f in d.faults) {
    await _tapPart(t, f.phase, f.part);
  }
  await t.tap(find.text(_L.spotDone));
  await _pump(t, 800);
  await _why(t, d, 1);
  // গ
  for (final f in d.faults) {
    await _tapPart(t, f.phase, f.part);
    if (f.part == _P.wire) {
      await t.tap(_label(_L.fuseWire(d.plateAmps)));
      await _pump(t, 300);
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text(_L.pull));
        await _pump(t, 200);
      }
      await t.tap(find.text(_L.tieDone));
      await _pump(t, 300);
    }
  }
  await _pump(t, 500);
  await _why(t, d, 2);
  // ঘ
  expect(await _pumpUntil(t, find.text(_L.actStop), maxMs: 6000), isTrue);
  if (d.callAt == 3) {
    if (fast) {
      await t.tap(find.text(_L.actStop));
      await t.pump();
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the act waits for him');
    }
    await _refuseHim(t);
  }
  await t.tap(find.text(d.blowsAgain ? _L.actStop : _L.actOk));
  await _pump(t, 800);
  await _why(t, d, 3);
}

M3HorngapSetDeal _seedWhere(bool Function(M3HorngapSetDeal d) ok, [int from = 0]) {
  var s = from;
  while (!ok(m3HorngapSetDeal(math.Random(s)))) {
    s++;
  }
  return m3HorngapSetDeal(math.Random(s));
}

int _seedOf(bool Function(M3HorngapSetDeal d) ok) {
  var s = 0;
  while (!ok(m3HorngapSetDeal(math.Random(s)))) {
    s++;
  }
  return s;
}

void main() {
  group('rules', () {
    test('deals: a blown wire and one or two more faults, never two on one part; tokens and reels shuffled; his moment', () {
      final seen = <String>{};
      final calls = <int>{};
      final extras = <M3HorngapSetFault>{};
      final acts = <String>{};
      var again = 0;
      for (var s = 0; s < 120; s++) {
        final d = m3HorngapSetDeal(math.Random(s));
        expect(d.faults.first.fault, _F.blown);
        expect(d.faults.length, inInclusiveRange(2, 3));
        expect(d.faults.skip(1).where((f) => f.fault == _F.blown), isEmpty);
        final parts = {for (final f in d.faults) '${f.phase}${f.part}'};
        expect(parts.length, d.faults.length, reason: 'one fault per part');
        for (final f in d.faults.skip(1)) {
          extras.add(f.fault);
          if (f.fault == _F.thick) expect(f.phase, isNot(d.blownPhase));
        }
        expect(d.tokens.toSet(), _S.values.toSet());
        expect(d.reels.toSet(), M3HorngapSetReel.values.toSet());
        expect(d.acts.toSet(), M3HorngapSetAct.values.toSet());
        acts.add(d.acts.join());
        expect([10, 25], contains(d.plateAmps));
        expect(d.otherAmps, isNot(d.plateAmps));
        if (d.callAt == 3) expect(d.blowsAgain, isTrue);
        calls.add(d.callAt);
        if (d.blowsAgain) again++;
        seen.add('${d.faults}${d.tokens}${d.reels}${d.plateAmps}${d.blowsAgain}${d.callAt}');
      }
      expect(seen.length, greaterThan(100), reason: 'every play is dealt fresh');
      expect(calls, {0, 3});
      expect(extras, {_F.thick, _F.bent, _F.carbon});
      expect(again, inInclusiveRange(30, 90));
      expect(acts.length, greaterThan(12), reason: 'the acts in ঘ lie in a fresh order (no fixed spot for the right one)');
    });

    const d0 = M3HorngapSetDeal(
      faults: [M3HorngapSetFaultAt(1, _F.blown), M3HorngapSetFaultAt(2, _F.thick), M3HorngapSetFaultAt(0, _F.bent), M3HorngapSetFaultAt(1, _F.carbon)],
      plateAmps: 10,
      tokens: [_S.earth, _S.shutdown, _S.test, _S.ptw],
      reels: M3HorngapSetReel.values,
      blowsAgain: false,
      callAt: 0,
    );

    test('ক: শাটডাউন → পারমিট (PTW) → টেস্ট → আর্থ, then climb; out of order = slip (not done)', () {
      final r = M3HorngapSetRun(d0);
      expect(r.tapStep(_S.ptw), _M.wrongOrder);
      expect(r.steps, isEmpty);
      for (final s in _S.values) {
        expect(r.tapStep(s), isNull);
      }
      expect(r.earthed, isTrue);
      expect(r.climb(), isNull);
      expect(r.shown, isTrue);
      expect(r.slips, 1);
      expect(r.thorough, isFalse);
      expect(r.caught, contains(_L.caughtSafe));
    });

    test('ক: climbing live is deadly; after the shutdown but untested and unearthed is a slip', () {
      final a = M3HorngapSetRun(d0);
      expect(a.climb(), _M.liveClimb);
      expect(a.ended, isTrue);
      final b = M3HorngapSetRun(d0)..tapStep(_S.shutdown);
      expect(b.climb(), _M.notReady);
      expect(b.shown, isFalse);
      final c = M3HorngapSetRun(d0);
      expect(c.listened(), _M.liveClimb);
    });

    test('খ: every fault found; a sound part flagged is a slip (once a part); a miss is a slip and shown', () {
      final r = M3HorngapSetRun(d0)..index = 1;
      expect(r.up, isTrue);
      expect(r.spot(0, _P.wire), _M.falseFlag, reason: 'a guess costs');
      expect(r.slips, 1);
      expect(r.spot(0, _P.wire), isNull, reason: 'booked once a part');
      expect(r.slips, 1);
      expect(r.found, isEmpty);
      expect(r.spot(1, _P.wire), isNull);
      expect(r.found.length, 1);
      expect(r.spot(1, _P.wire), isNull);
      expect(r.spot(2, _P.wire), isNull);
      expect(r.found.length, 2);
      expect(r.spotDone(), _M.missedFault);
      expect(r.slips, 2);
      expect(r.found.length, 4, reason: 'the missed ones are shown');
      expect(r.spotDone(), isNull);
      expect(r.shown, isTrue);
      expect(r.thorough, isFalse);
      // Sweep-tapping all nine parts no longer finds everything for free.
      final sweep = M3HorngapSetRun(d0)..index = 1;
      for (var ph = 0; ph < 3; ph++) {
        for (final part in _P.values) {
          sweep.spot(ph, part);
        }
      }
      expect(sweep.slips, 9 - d0.faults.length);
      final clean = M3HorngapSetRun(d0)..index = 1;
      for (final f in d0.faults) {
        clean.spot(f.phase, f.part);
      }
      expect(clean.spotDone(), isNull);
      expect(clean.thorough, isTrue);
      expect(clean.caught, contains(_L.caughtSeen));
    });

    test('গ: clean, set the horn, the plate rating tied taut; other wires and a loose tie are slips', () {
      final r = M3HorngapSetRun(d0)..index = 2;
      expect(r.tapFix(1, _P.terminal), M3HorngapSetFix.cleaned);
      expect(r.tapFix(0, _P.horns), M3HorngapSetFix.set);
      expect(r.tapFix(0, _P.terminal), M3HorngapSetFix.none, reason: 'nothing wrong there');
      expect(r.tapFix(1, _P.wire), M3HorngapSetFix.reel);
      expect(r.look(1).wire, M3HorngapSetWire.gone);
      expect(r.pickReel(M3HorngapSetReel.other), _M.thickWire, reason: '25A on a 10A plate');
      expect(r.pickReel(M3HorngapSetReel.plain), _M.plainWire);
      expect(r.pickReel(M3HorngapSetReel.rated), isNull);
      expect(r.look(1).wire, M3HorngapSetWire.slack);
      expect(r.tieDone(), _M.loose);
      expect(r.tieDone(), isNull, reason: 'booked once a set');
      expect(r.tying, 1);
      r
        ..pull()
        ..pull()
        ..pull()
        ..pull();
      expect(r.slack, 0);
      expect(r.tieDone(), isNull);
      expect(r.look(1).wire, M3HorngapSetWire.ok);
      expect(r.shown, isFalse);
      expect(r.tapFix(2, _P.wire), M3HorngapSetFix.reel);
      r.pickReel(M3HorngapSetReel.rated);
      for (var i = 0; i < 3; i++) {
        r.pull();
      }
      expect(r.tieDone(), isNull);
      expect(r.allFixed, isTrue);
      expect(r.shown, isTrue);
      expect(r.slips, 3);
      const thin = M3HorngapSetDeal(
          faults: [M3HorngapSetFaultAt(0, _F.blown), M3HorngapSetFaultAt(1, _F.bent)],
          plateAmps: 25,
          tokens: _S.values,
          reels: M3HorngapSetReel.values,
          blowsAgain: false,
          callAt: 0);
      final t = M3HorngapSetRun(thin)..index = 2;
      t.tapFix(0, _P.wire);
      expect(t.pickReel(M3HorngapSetReel.other), _M.thinWire);
    });

    test('ঘ held: "ঠিক আছে" is right; a needless stop is a slip; a thick wire is a slip; climbing is deadly', () {
      final r = M3HorngapSetRun(d0)..index = 3;
      expect(r.act(M3HorngapSetAct.ok), isNull, reason: 'not before it shows');
      expect(r.shown, isFalse);
      r.reveal();
      expect(r.lit, isTrue);
      expect(r.act(M3HorngapSetAct.stopFind), _M.needlessStop, reason: 'a needless stop costs');
      expect(r.shown, isFalse);
      expect(r.slips, 1);
      expect(r.act(M3HorngapSetAct.thickWire), _M.thickMyth);
      expect(r.act(M3HorngapSetAct.ok), isNull);
      expect(r.shown, isTrue);
      expect(r.caught, contains(_L.caughtHeld));
      final c = M3HorngapSetRun(d0)
        ..index = 3
        ..reveal();
      expect(c.act(M3HorngapSetAct.climbNow), _M.liveRetie);
      expect(c.ended, isTrue);
    });

    test('ঘ blew again: walking away is a slip; keep it off and find the fault; the set shows blown', () {
      const d = M3HorngapSetDeal(
          faults: [M3HorngapSetFaultAt(2, _F.blown), M3HorngapSetFaultAt(0, _F.carbon)],
          plateAmps: 10,
          tokens: _S.values,
          reels: M3HorngapSetReel.values,
          blowsAgain: true,
          callAt: 3);
      final r = M3HorngapSetRun(d)..index = 3;
      expect(r.look(2).wire, M3HorngapSetWire.ok);
      r.reveal();
      expect(r.look(2).wire, M3HorngapSetWire.blown);
      expect(r.lit, isFalse);
      expect(r.act(M3HorngapSetAct.ok), _M.ignoredBlow);
      expect(r.act(M3HorngapSetAct.stopFind), isNull);
      expect(r.shown, isTrue);
      expect(r.caught, contains(_L.caughtFault));
      final l = M3HorngapSetRun(d)..index = 3;
      expect(l.listened(), _M.liveRetie);
    });

    test('after a deadly the rules take nothing more (the line does not even come on)', () {
      final r = M3HorngapSetRun(d0)..climb();
      expect(r.ended, isTrue);
      expect(r.tapStep(_S.shutdown), isNull);
      expect(r.listened(), isNull);
      r.index = 3;
      r.reveal();
      expect(r.revealed, isFalse);
      expect(r.act(M3HorngapSetAct.ok), isNull);
    });

    test('three slips: 55 %', () {
      final r = M3HorngapSetRun(d0);
      for (final s in [_S.ptw, _S.test, _S.earth]) {
        r.tapStep(s);
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded; the art', () {
      for (final again in [false, true]) {
        for (final extra in [_F.thick, _F.bent, _F.carbon]) {
          final d = M3HorngapSetDeal(
              faults: [const M3HorngapSetFaultAt(0, _F.blown), M3HorngapSetFaultAt(1, extra)],
              plateAmps: 10,
              tokens: _S.values,
              reels: M3HorngapSetReel.values,
              blowsAgain: again,
              callAt: 0);
          for (var i = 0; i < 4; i++) {
            final run = _runAt(d, i);
            final right = _L.whyRight(run);
            final wrong = _L.whyWrong(run);
            expectLibrary('why $i $again $extra', right, wrong);
            expectSameLength('why $i $again $extra', [...right, ...wrong]);
            for (var s = 0; s < 10; s++) {
              final deal = dealChoices(right, wrong, math.Random(s));
              expect(deal.where((o) => o.correct).length, 1);
              expect(deal.map((o) => o.textBn).toSet().length, 3);
            }
          }
        }
      }
      final cw = _L.coworker;
      expect(cw.line, contains('লাইন চালু থাকতেই ফিউজটা বদলে দাও'));
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      final keys = <String>{};
      for (final m in _M.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.key, startsWith('3.4/m3_horngap_set/'));
        expect(keys.add(m.key), isTrue, reason: m.key);
      }
      expect(m3HorngapSetPacks.keys, ['do_3_4_b']);
      for (final l in [_L.intro, ..._L.tasks]) {
        expect(l.contains('পানি'), isFalse);
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
        // No coworker in station ক on this seed (he comes only if the fuse blows again).
        final seed = _seedOf((d) => d.callAt == 3);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M3HorngapSetPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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
        debugPrint('PERF m3_horngap_set ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3HorngapSetPage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(_L.climb), findsNothing);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.text(_L.climb), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, _seedOf((d) => d.callAt == 3));
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(_L.askSafe)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final (name, ok) in <(String, bool Function(M3HorngapSetDeal))>[
      ('the fuse holds, he comes in ক', (d) => d.callAt == 0 && !d.blowsAgain && d.faults.length == 3),
      ('the fuse blows again, he comes in ঘ', (d) => d.callAt == 3 && d.faults.any((f) => f.fault == _F.thick)),
    ]) {
      testWidgets('flow ($name): safe, inspect, fix, back on — every reason right → pass', (t) async {
        final seed = _seedOf(ok);
        final deal = _seedWhere(ok);
        final c = await _open(t, seed);
        await _playRight(t, deal);
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['3.4/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['3.4/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(_L.caughtCall), findsOneWidget, reason: 'he came and was refused');
        expect(find.text(deal.blowsAgain ? _L.caughtFault : _L.caughtHeld), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a step out of order: the slip card; the station stays', (t) async {
      final seed = _seedOf((d) => d.callAt == 3);
      final c = await _open(t, seed);
      await t.tap(_label(_L.stepEarth));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.wrongOrder.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(_L.climb), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('gesture hint: after idle a hand shows how (a sweep), hidden on touch and while a card is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, _seedOf((d) => d.callAt == 3));
      IdleHintState hint() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(hint().showing, isTrue, reason: 'ক waits: the hand sweeps over the tokens and the climb');
      await t.tap(_label(_L.stepEarth));
      await _pump(t, 800);
      expect(hint().showing, isFalse);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await _pump(t, 9000);
      expect(hint().showing, isFalse, reason: 'no hand while the slip card is up');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 9500);
      expect(hint().showing, isTrue);
      await _close(t, c);
    });

    testWidgets('three slips strike out: the struck-out card, no pass', (t) async {
      final c = await _open(t, _seedOf((d) => d.callAt == 3));
      for (var i = 0; i < 3; i++) {
        await t.tap(_label(_L.stepEarth));
        await _pump(t, 800);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 1200);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(LevelPassPanel), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.4/do/1'], isNot('cleared'));
      expect(s.mistakes.map((m) => m.key), contains(_M.wrongOrder.key));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the coworker comes even on a fast play: শাটডাউন tapped at once waits for him', (t) async {
      final c = await _open(t, _seedOf((d) => d.callAt == 0));
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not yet');
      await t.tap(_label(_L.step(_S.shutdown)));
      await t.pump();
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the decisive control brings him in now');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      // The held tap did nothing: the শাটডাউন is still to do, then works.
      await t.tap(_label(_L.step(_S.shutdown)));
      await _pump(t, 400);
      await t.tap(_label(_L.step(_S.ptw)));
      await _pump(t, 400);
      expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'শাটডাউন then পারমিট (PTW) is in order');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('fast play (the fuse blows again): the act in ঘ waits for him; then pass', (t) async {
      bool ok(M3HorngapSetDeal d) => d.callAt == 3;
      final c = await _open(t, _seedOf(ok));
      await _playRight(t, _seedWhere(ok), fast: true);
      await _pump(t, 3000);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('খ: a sound part flagged costs a slip with the card (no free "it is fine" reply)', (t) async {
      bool ok(M3HorngapSetDeal d) => d.callAt == 3;
      final d = _seedWhere(ok);
      final c = await _open(t, _seedOf(ok));
      for (final s in _S.values) {
        await t.tap(_label(_L.step(s)));
        await _pump(t, 250);
      }
      await t.tap(find.text(_L.climb));
      await _pump(t, 800);
      await _why(t, d, 0);
      final sound = [
        for (var ph = 0; ph < 3; ph++)
          for (final part in _P.values)
            if (d.at(ph, part) == null) (ph, part),
      ].first;
      await _tapPart(t, sound.$1, sound.$2);
      await _pump(t, 500);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.falseFlag.key);
      expect(c.read(guideDirectorProvider).line, isNot(contains('ঠিক আছে')));
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1200);
      expect(find.text(_L.spotDone), findsOneWidget, reason: 'the station stays');
      await _close(t, c);
    });

    testWidgets('listening to "লাইন চালু থাকতেই…" is deadly — freeze first, then the card', (t) async {
      final c = await _open(t, _seedOf((d) => d.callAt == 0));
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 5000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.liveClimb.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
