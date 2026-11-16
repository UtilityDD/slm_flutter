// Lesson 7.7 (দুর্ঘটনার রিপোর্ট), কাজ 1 "যেমন ছিল, তেমন থাক": the rules (four
// evidence reaches are blocked, two care reaches are let through; the snapped
// wire's ground zone and the coworker's coiling hand are deadly; a late block
// of that hand is a slip; a blocked care hand comes once more so blocking
// everything strikes out), the deal (site, order, side, places, speed, tied
// reach), the band's geometry (every lane clear of the zone and of the
// middle), the libraries and every spoken line; and the level in the shell:
// the guide first, tap-the-guide, a clean play on every site with a reason pick
// and the coworker refused (the tied reach waits for him), a slip's card, three
// slips strike out, the deadly freezes (the zone; the wire hand let through;
// listening to him in the village) and the gesture hand.
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
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_scene_guard.dart';
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
  rungId: '7.7/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m7SceneGuardPacks['do_7_7_a']!;

/// The art folder may be newer than the test bundle: read from disk then.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      if (key == 'AssetManifest.bin') return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

M7SceneDeal _deal(int s) => m7SceneDeal(math.Random(s));

int _seedWhere(bool Function(M7SceneDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(_deal(s)));

/// Plays the pure run: [block] says which reaches the player blocks (at the
/// start of the hand's reach, unless [lateBlock]).
({int slips, DoMistake? deadly, bool done, int reaches}) _simulate(M7SceneDeal d, {required bool Function(M7ReachPlan p) block, bool lateBlock = false}) {
  final r = M7SceneGuardRun(d);
  var n = 0;
  while (!r.done && !r.ended && n < 20) {
    n++;
    r.startReach();
    final plan = r.current;
    if (block(plan)) {
      if (lateBlock) r.tick(r.durMs - 200);
      r.moveTo(r.geo.laneX(plan.item));
    }
    r.tick(r.durMs + 5);
    if (r.ended) break;
    r
      ..advance()
      ..setHome();
  }
  return (slips: r.slips, deadly: r.deadly, done: r.done, reaches: n);
}

bool _isEvidence(M7ReachPlan p) => m7KindOf(p.item) == M7Kind.evidence;

void main() {
  group('rules', () {
    test('kinds: four evidence per site, care things care; every item has a reason; the tied reach per site', () {
      for (final s in M7Site.values) {
        expect(m7EvidenceOf[s], hasLength(4));
        for (final i in m7EvidenceOf[s]!) {
          expect(m7KindOf(i), M7Kind.evidence);
          expect(m7CareOf(i), isNull);
        }
        expect(m7TiedOf[s], isNotNull);
      }
      expect(m7CareOf(M7Item.colleague), M7Care.doctor);
      for (final i in [M7Item.child, M7Item.cart, M7Item.ember]) {
        expect(m7KindOf(i), M7Kind.care);
        expect(m7CareOf(i), M7Care.danger);
      }
      expect(m7WhyOf(M7Item.wire), M7Why.wire);
      expect(m7WhyOf(M7Item.ladder), M7Why.scene);
      expect(m7WhyOf(M7Item.colleague), M7Why.doctor);
      expect(m7WhyOf(M7Item.ember), M7Why.danger);
      expect(M7SceneGuardMistakes.moved.keys.toSet(), {for (final s in M7Site.values) ...m7EvidenceOf[s]!}..remove(M7Item.wire));
    });

    test('deals: 4 evidence + 2 care, the tied reach third or fourth, first hand 4.5 s, the rest 3.0–4.0 s; places differ; plays differ', () {
      final seen = <String>{};
      final sites = <M7Site>{};
      for (var s = 0; s < 200; s++) {
        final d = _deal(s);
        sites.add(d.site);
        expect(d.reaches, hasLength(6));
        expect(d.reaches.where((r) => m7KindOf(r.item) == M7Kind.evidence).length, 4, reason: 'seed $s');
        expect(d.reaches.where((r) => m7KindOf(r.item) == M7Kind.care).length, 2, reason: 'seed $s');
        expect(d.reaches.map((r) => r.item).toSet(), hasLength(6));
        final ti = d.reaches.indexWhere((r) => r.item == d.tied);
        expect(ti, anyOf(2, 3), reason: 'seed $s');
        expect(d.tied, m7TiedOf[d.site]);
        expect(d.reaches.first.durMs, m7FirstReachMs);
        for (final r in d.reaches.skip(1)) {
          expect(r.durMs, inInclusiveRange(3000, 4000));
        }
        expect(d.slotOf.values.toSet(), hasLength(6), reason: 'six different places');
        if (d.site == M7Site.pole) expect(d.reaches.any((r) => r.item == M7Item.colleague), isTrue);
        if (d.site == M7Site.village) {
          expect(d.slotOf[M7Item.wire], 5, reason: 'the wire lies at the band end');
          expect(d.reaches.any((r) => r.item == M7Item.child) && d.reaches.any((r) => r.item == M7Item.cart), isTrue);
        }
        seen.add('${d.site.name}|${d.mirror}|${d.reaches.map((r) => '${r.item.name}${r.fromLeft ? 'L' : 'R'}${r.durMs}').join(',')}|${d.slotOf.values.join()}');
      }
      expect(sites, M7Site.values.toSet());
      expect(seen.length, greaterThan(190));
    });

    test('the band: every lane is clear of the middle and lies on the band; the zone is only in the village', () {
      for (var s = 0; s < 120; s++) {
        final d = _deal(s);
        final g = d.geoFor(700, 0);
        for (final i in d.slotOf.keys) {
          final c = g.laneX(i);
          expect(c, inInclusiveRange(M7SceneGeo.bandMin, M7SceneGeo.bandMax), reason: '$i: the trainee can stand in its lane');
          expect((c - M7SceneGeo.home).abs(), greaterThan(M7SceneGeo.laneHalf + 24), reason: 'seed $s: $i lane clear of his place');
        }
        expect(g.zone != null, d.site == M7Site.village, reason: 'seed $s');
      }
    });

    test('the zone does not reach the middle or any lane (both mirrors)', () {
      for (final mirror in [false, true]) {
        for (var s = 0; s < 40; s++) {
          final d = _deal(s);
          if (d.site != M7Site.village) continue;
          final g = M7SceneGeo.forScene(700, 0, d.site, mirror, d.slotOf);
          final z = g.zone!;
          for (final i in d.slotOf.keys) {
            final c = g.laneX(i);
            final lo = c - M7SceneGeo.laneHalf;
            final hi = c + M7SceneGeo.laneHalf;
            expect(hi < z.a || lo > z.b, isTrue, reason: 'mirror $mirror seed $s $i [$lo,$hi] vs [${z.a},${z.b}]');
          }
          expect(M7SceneGeo.home < z.a || M7SceneGeo.home > z.b, isTrue);
        }
      }
    });

    test('a perfect player (block evidence, let care) passes with no slip, on every deal', () {
      for (var s = 0; s < 200; s++) {
        final r = _simulate(_deal(s), block: _isEvidence);
        expect(r.deadly, isNull, reason: 'seed $s');
        expect(r.slips, 0, reason: 'seed $s');
        expect(r.done, isTrue, reason: 'seed $s');
        expect(r.reaches, 6, reason: 'seed $s');
      }
    });

    test('letting everything go: evidence slips strike out (or the wire hand is deadly); blocking everything: care slips twice each', () {
      for (var s = 0; s < 120; s++) {
        final d = _deal(s);
        final letAll = _simulate(d, block: (_) => false);
        expect(letAll.slips >= 3 || letAll.deadly != null, isTrue, reason: 'seed $s: let-all slips ${letAll.slips}');
        final blockAll = _simulate(d, block: (_) => true);
        expect(blockAll.deadly, isNull);
        expect(blockAll.slips, 4, reason: 'seed $s: two care hands, each blocked twice');
        expect(blockAll.reaches, 8, reason: 'six hands and two care hands again');
      }
    });

    test('evidence: a block is right and tags it; letting it go = that item\'s slip; each evidence item has its own slip', () {
      final d = _deal(_seedWhere((d) => d.site == M7Site.pole));
      for (final item in m7EvidenceOf[M7Site.pole]!) {
        final r = M7SceneGuardRun(d)..index = d.reaches.indexWhere((x) => x.item == item);
        r.startReach();
        final e = r.tick(r.durMs + 1)!;
        expect(e.kind, M7Outcome.letWrong);
        expect(e.mistake, M7SceneGuardMistakes.moved[item]);
        expect(r.slips, 1);
        final b = M7SceneGuardRun(d)..index = d.reaches.indexWhere((x) => x.item == item);
        b.startReach();
        final e2 = b.moveTo(b.geo.laneX(item))!;
        expect(e2.kind, M7Outcome.blockedRight);
        expect(b.slips, 0);
        expect(b.caught, contains(M7SceneGuardLines.caughtEvidence));
      }
    });

    test('care: letting the hand go on is right; blocking it is a slip and it comes once more from the other side', () {
      final d = _deal(_seedWhere((d) => d.site == M7Site.pole));
      final ci = d.reaches.indexWhere((x) => x.item == M7Item.colleague);
      final r = M7SceneGuardRun(d)..index = ci;
      r.startReach();
      expect(r.tick(r.durMs + 1)!.kind, M7Outcome.letRight);
      expect(r.caught, contains(M7SceneGuardLines.caughtDoctor));
      expect(r.slips, 0);

      final b = M7SceneGuardRun(d)..index = ci;
      b.startReach();
      final e = b.moveTo(b.geo.laneX(M7Item.colleague))!;
      expect(e.kind, M7Outcome.blockedWrong);
      expect(e.mistake, M7SceneGuardMistakes.blockDoctor);
      expect(b.slips, 1);
      expect(b.reaches, hasLength(7));
      final again = b.reaches[ci + 1];
      expect(again.item, M7Item.colleague);
      expect(again.retry, isTrue);
      expect(again.fromLeft, isNot(d.reaches[ci].fromLeft));
      // Blocked again: a second slip, no third hand.
      b
        ..advance()
        ..setHome();
      b.startReach();
      expect(b.moveTo(b.geo.laneX(M7Item.colleague))!.kind, M7Outcome.blockedWrong);
      expect(b.reaches, hasLength(7));
      expect(b.slips, 2);
      // A danger-stopping hand has its own slip.
      final dd = _deal(_seedWhere((d) => d.reaches.any((x) => x.item == M7Item.child)));
      final ki = dd.reaches.indexWhere((x) => x.item == M7Item.child);
      final c = M7SceneGuardRun(dd)..index = ki;
      c.startReach();
      expect(c.moveTo(c.geo.laneX(M7Item.child))!.mistake, M7SceneGuardMistakes.blockDanger);
    });

    test('S2: the wire hand — blocked in time is right; late = slip (not deadly); let through = deadly after the whole reach', () {
      final d = _deal(_seedWhere((d) => d.site == M7Site.village));
      final wi = d.reaches.indexWhere((x) => x.item == M7Item.wire);
      final ok = M7SceneGuardRun(d)..index = wi;
      ok.startReach();
      ok.tick(1000);
      final e = ok.moveTo(ok.geo.laneX(M7Item.wire))!;
      expect(e.kind, M7Outcome.blockedRight);
      expect(ok.deadly, isNull);
      expect(ok.caught, containsAll([M7SceneGuardLines.caughtEvidence, M7SceneGuardLines.caughtWire]));

      final late = M7SceneGuardRun(d)..index = wi;
      late.startReach();
      late.tick(late.durMs - 100);
      final l = late.moveTo(late.geo.laneX(M7Item.wire))!;
      expect(l.kind, M7Outcome.wireLate);
      expect(l.mistake, M7SceneGuardMistakes.wireLate);
      expect(late.deadly, isNull);
      expect(late.slips, 1);

      final let = M7SceneGuardRun(d)..index = wi;
      let.startReach();
      expect(let.tick(let.durMs - 10), isNull, reason: 'a clear, timed chance first');
      expect(let.deadly, isNull);
      final dead = let.tick(let.durMs + 1)!;
      expect(dead.kind, M7Outcome.wireDeadly);
      expect(let.deadly, M7SceneGuardMistakes.wireCoil);
      expect(let.ended, isTrue);
    });

    test('S2: dragging the worker into the wire\'s ground zone (even a flick across) is deadly; elsewhere there is no zone', () {
      final d = _deal(_seedWhere((d) => d.site == M7Site.village));
      final g = d.geoFor(700, 0);
      final z = g.zone!;
      final r = M7SceneGuardRun(d);
      expect(r.moveTo((z.a + z.b) / 2 > 180 ? z.a + 1 : z.b - 1)!.kind, M7Outcome.zone);
      expect(r.deadly, M7SceneGuardMistakes.wireZone);
      final flick = M7SceneGuardRun(d);
      final far = z.a > 180 ? 358.0 : 2.0;
      expect(flick.moveTo(far)!.kind, M7Outcome.zone, reason: 'bandMax/bandMin clamp lands in the zone');
      final near = M7SceneGuardRun(d);
      expect(near.moveTo(z.a > 180 ? z.a - 3 : z.b + 3), isNull, reason: 'next to the zone is safe');
      for (final s in [M7Site.pole, M7Site.pillar]) {
        final p = _deal(_seedWhere((d) => d.site == s));
        final run = M7SceneGuardRun(p);
        expect(run.geo.zone, isNull);
        expect(run.moveTo(2), isNull);
        expect(run.moveTo(358), isNull);
      }
    });

    test('listening: a slip in the pole and pillar sites (each its own), the wire\'s deadly in the village', () {
      final pole = M7SceneGuardRun(_deal(_seedWhere((d) => d.site == M7Site.pole)));
      expect(pole.listenSlip(), M7SceneGuardMistakes.listenShock);
      expect(pole.slips, 1);
      final pillar = M7SceneGuardRun(_deal(_seedWhere((d) => d.site == M7Site.pillar)));
      expect(pillar.listenSlip(), M7SceneGuardMistakes.listenFuse);
      final deadly = M7SceneGuardMistakes.all.where((m) => m.deadly).toList();
      expect(deadly, [M7SceneGuardMistakes.wireCoil, M7SceneGuardMistakes.wireZone]);
    });

    test('marks: 100 − 15 per slip; pass at 55 (two slips pass, a struck-out play never gets there)', () {
      final d = _deal(1);
      final r = M7SceneGuardRun(d);
      expect(r.percent, 100);
      r.slips = 2;
      expect(r.percent, 70);
      r.index = 6;
      expect(r.passed, isTrue);
      r.slips = 3;
      expect(r.percent, 55);
    });

    test('English digits only; no পানি/মৃত; every mistake has its picture and lesson point; keys unique; no unused pictures', () {
      final all = <String>[
        M7SceneGuardLines.intro,
        ...M7SceneGuardLines.steps,
        ...M7SceneGuardLines.tasks,
        ...M7SceneGuardLines.allWhyRight,
        ...M7SceneGuardLines.mythsBlock,
        ...M7SceneGuardLines.mythsLet,
        for (final c in M7SceneGuardLines.allCoworkers) ...[...c.recordedLines, ...c.right, ...c.wrong, ...c.asks],
        ...M7SceneGuardLines.callHeld.values,
        for (final m in M7SceneGuardMistakes.all) m.textBn,
        M7SceneGuardLines.allSet,
        M7SceneGuardLines.fail,
        M7SceneGuardLines.vanArrives,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(RegExp('মৃত(?!্যু)').hasMatch(l), isFalse, reason: 'ডেড / পশুর মৃত্যু only: $l');
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('[ऀ-ॣ०-ॿ؀-ۿ]').hasMatch(l), isFalse, reason: 'clean Bangla: $l');
      }
      expect(M7SceneGuardMistakes.all.map((m) => m.key).toSet(), hasLength(M7SceneGuardMistakes.all.length));
      expect(M7SceneGuardMistakes.all, hasLength(18));
      for (final m in M7SceneGuardMistakes.all) {
        expect(m.key, startsWith('7.7/m7_scene_guard/'));
        expect(m.art, startsWith('assets/game/art/m7_scene_guard/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      final art = Directory('assets/game/art/m7_scene_guard').listSync().map((f) => f.path.replaceAll(r'\', '/')).toSet();
      expect(art, M7SceneGuardMistakes.all.map((m) => m.art).toSet(), reason: 'no unused pictures');
      expect(m7SceneGuardPacks.keys, ['do_7_7_a']);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      for (final k in M7Why.values) {
        final right = M7SceneGuardLines.whyRight[k]!;
        final wrong = M7SceneGuardLines.mythsFor(k);
        expectSameLength('why $k', [...right, ...wrong]);
        expectLibrary('why $k', right, wrong);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(M7SceneGuardLines.mythsBlock.toSet().intersection(M7SceneGuardLines.allWhyRight.toSet()), isEmpty);
      expect(M7SceneGuardLines.mythsLet.toSet().intersection(M7SceneGuardLines.allWhyRight.toSet()), isEmpty);
      for (final s in M7Site.values) {
        final c = M7SceneGuardLines.coworkers[s]!;
        expectSameLength('coworker $s', [...c.right, ...c.wrong]);
        expectLibrary('coworker $s', c.right, c.wrong, minRight: 2, minWrong: 5);
        expect(c.asks.length, greaterThanOrEqualTo(2));
        expect(M7SceneGuardLines.callHeld[s], isNotNull);
      }
      expect(M7SceneGuardLines.coworkers[M7Site.pole]!.line, 'এটা তো একটা ছোট শক ছিল, হাসপাতালে যাওয়ার বা রিপোর্ট করার দরকার নেই।', reason: 'lesson myth 2 word for word');
    });

    test('every spoken line is in newGuideLines / newRivalLines; no line twice', () {
      final g = M7SceneGuardLines.newGuideLines;
      expect(g.toSet(), hasLength(g.length));
      expect(
        g,
        containsAll([
          M7SceneGuardLines.intro,
          M7SceneGuardLines.askPos,
          ...M7SceneGuardLines.watch,
          M7SceneGuardLines.whyBlockQ,
          M7SceneGuardLines.whyLetQ,
          M7SceneGuardLines.vanArrives,
          M7SceneGuardLines.allSet,
          M7SceneGuardLines.fail,
          for (final m in M7SceneGuardMistakes.all) m.textBn,
        ]),
      );
      expect(M7SceneGuardLines.newRivalLines, hasLength(3));
      expect(M7SceneGuardLines.newRivalLines.toSet(), hasLength(3));
    });

    test('rival lines: his exit is recorded; his three pushes are the only ones still to record', () {
      final lines = {for (final c in M7SceneGuardLines.allCoworkers) ...c.recordedLines};
      expect(LearnVoice.resolve(M7SceneGuardLines.coworkerExit, rival: true), isNotNull);
      final missing = [for (final l in lines) if (LearnVoice.resolve(l, rival: true) == null) l];
      expect(missing.toSet().difference({for (final c in M7SceneGuardLines.allCoworkers) c.line}), isEmpty);
      for (final l in missing) {
        debugPrint('RIVAL LINE TO RECORD: $l');
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
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    Future<void> pump(WidgetTester t, int ms) async {
      for (var i = 0; i < ms; i += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }

    Future<bool> until(WidgetTester t, bool Function() ok, {int maxMs = 10000}) async {
      for (var ms = 0; ms < maxMs; ms += 50) {
        if (ok()) return true;
        await t.pump(const Duration(milliseconds: 50));
      }
      return ok();
    }

    Finder label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
    List<Finder> onScreen(List<String> texts) => [
          for (final x in texts)
            if (label(x).evaluate().isNotEmpty) label(x),
        ];

    Future<void> pickRight(WidgetTester t, List<String> right) async {
      await waitChoiceDeck(t);
      final r = onScreen(right);
      expect(r, hasLength(1), reason: right.first);
      await t.tap(r.single, warnIfMissed: false);
      await tapReasonProceed(t);
    }

    Future<void> pickWrong(WidgetTester t, List<String> wrong) async {
      await waitChoiceDeck(t);
      final w = onScreen(wrong);
      expect(w, isNotEmpty);
      await t.tap(w.first, warnIfMissed: false);
      await confirmChoice(t);
    }

    Future<ProviderContainer> open(WidgetTester t, int seed, M7SceneGuardProbe probe) async {
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
        builder: (_) => DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: M7SceneGuardPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe),
        ),
      )));
      await pump(t, 1000);
      await waitIntro(t);
      await pump(t, 800);
      return c;
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    /// Drags the worker so that his x on the band is [x].
    Future<void> dragTo(WidgetTester t, M7SceneGuardProbe p, double x) async {
      final from = p.workerGlobal!;
      final by = p.dragTo(x)!;
      await t.dragFrom(from, by);
      await t.pump(const Duration(milliseconds: 50));
    }

    Future<void> takePosition(WidgetTester t, M7SceneGuardProbe p) async {
      expect(p.phase, 'position');
      await dragTo(t, p, 120);
      await pump(t, 300);
      expect(p.phase, anyOf('between', 'reach'));
    }

    Future<void> slipCard(WidgetTester t) async {
      expect(await until(t, () => find.byType(MistakeCard).evaluate().isNotEmpty, maxMs: 6000), isTrue, reason: 'the slip card');
      await t.tap(find.text(MistakeLines.gotIt));
      await pump(t, 300);
    }

    /// The coworker: he comes before the tied reach (which waits); [listen]
    /// picks a way of listening to him.
    Future<void> coworker(WidgetTester t, M7SceneGuardProbe p, {bool listen = false}) async {
      expect(await until(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 9000), isTrue, reason: 'he comes');
      expect(p.run!.isTied, isTrue);
      expect(p.phase, isNot('reach'), reason: 'the tied reach waits for him');
      await until(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await pump(t, 400);
      final script = M7SceneGuardLines.coworkers[p.deal!.site]!;
      if (listen) {
        await pickWrong(t, script.wrong);
      } else {
        await pickRight(t, script.right);
        await pump(t, 600);
        expect(p.phase, isNot('reach'), reason: 'a short pause after him');
      }
    }

    /// Plays one hand: block it or let it go, then its reason when right.
    Future<void> hand(WidgetTester t, M7SceneGuardProbe p, {required bool block, bool reason = true}) async {
      expect(await until(t, () => p.phase == 'reach' && p.run!.active, maxMs: 15000), isTrue, reason: 'a hand reaches');
      final plan = p.run!.current;
      if (block) {
        await pump(t, 400);
        await dragTo(t, p, p.run!.geo.laneX(plan.item));
      }
      expect(await until(t, () => p.run!.resolved || p.run!.ended, maxMs: 9000), isTrue);
      if (reason && p.run!.slips == 0 && p.run!.deadly == null) {
        expect(await until(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue, reason: 'the reason');
        await pump(t, 500);
        await pickRight(t, M7SceneGuardLines.whyRight[m7WhyOf(plan.item)]!);
      }
    }

    /// A whole clean play from the first reach.
    Future<void> clean(WidgetTester t, M7SceneGuardProbe p) async {
      var met = false;
      for (var guard = 0; guard < 400 && !p.run!.done; guard++) {
        if (!met && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
          await coworker(t, p);
          met = true;
          continue;
        }
        if (p.phase == 'reach' && p.run!.active) {
          await hand(t, p, block: m7KindOf(p.run!.current.item) == M7Kind.evidence);
          continue;
        }
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(met, isTrue, reason: 'the coworker came once');
    }

    testWidgets('the guide comes first: a tap does not skip him; then he waits for the trainee to take his place', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M7SceneGuardPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await pump(t, 3000);
      expect(find.byType(GuideIntro), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'no deck: the scene waits for the drag');
      expect(find.byType(MistakeCard), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final p = M7SceneGuardProbe();
      final c = await open(t, 5, p);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M7SceneGuardLines.askPos)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await close(t, c);
    });

    for (final site in M7Site.values) {
      testWidgets('flow (${site.name}): position, six hands, a reason each, the coworker refused, the van, pass', (t) async {
        final seed = _seedWhere((d) => d.site == site);
        final p = M7SceneGuardProbe();
        final c = await open(t, seed, p);
        await takePosition(t, p);
        await clean(t, p);
        expect(await until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 12000), isTrue);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.7/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.7/do/0'], greaterThan(0));
        expect(find.text(M7SceneGuardLines.caughtEvidence), findsOneWidget);
        expect(find.text(M7SceneGuardLines.caughtCoworker), findsOneWidget);
        expect(t.takeException(), isNull);
        await close(t, c);
      });
    }

    testWidgets('a slip: letting an evidence item be moved shows its card; the next hand follows', (t) async {
      final seed = _seedWhere((d) => d.site == M7Site.pole && m7KindOf(d.reaches[0].item) == M7Kind.evidence);
      final p = M7SceneGuardProbe();
      final c = await open(t, seed, p);
      await takePosition(t, p);
      final item = p.deal!.reaches[0].item;
      await hand(t, p, block: false, reason: false);
      await slipCard(t);
      expect(c.read(gameSaveProvider).mistakes.single.key, M7SceneGuardMistakes.moved[item]!.key);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await until(t, () => p.run!.index == 1 && p.phase == 'reach', maxMs: 12000), isTrue, reason: 'the next hand');
      await close(t, c);
    });

    testWidgets('blocking a care hand = slip card; the hand comes again', (t) async {
      final seed = _seedWhere((d) => d.site == M7Site.pole && m7KindOf(d.reaches[0].item) == M7Kind.care);
      final p = M7SceneGuardProbe();
      final c = await open(t, seed, p);
      await takePosition(t, p);
      final item = p.deal!.reaches[0].item;
      await hand(t, p, block: true, reason: false);
      await slipCard(t);
      expect(c.read(gameSaveProvider).mistakes.single.key, M7SceneGuardMistakes.blockCare(m7CareOf(item)!).key);
      expect(await until(t, () => p.run!.index == 1 && p.phase == 'reach', maxMs: 12000), isTrue);
      expect(p.run!.current.item, item);
      expect(p.run!.current.retry, isTrue);
      await close(t, c);
    });

    testWidgets('three slips strike the level out (no freeze)', (t) async {
      // Pillar: the first three hands are evidence; let each go.
      final seed = _seedWhere((d) => d.site == M7Site.pillar && d.reaches.take(3).every((r) => m7KindOf(r.item) == M7Kind.evidence));
      final p = M7SceneGuardProbe();
      final c = await open(t, seed, p);
      await takePosition(t, p);
      var met = false;
      for (var guard = 0; guard < 400 && find.byType(StruckOutCard).evaluate().isEmpty; guard++) {
        if (!met && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
          await coworker(t, p);
          met = true;
          continue;
        }
        if (find.text(MistakeLines.gotIt).evaluate().isNotEmpty) {
          await t.tap(find.text(MistakeLines.gotIt));
          await pump(t, 300);
          continue;
        }
        if (p.phase == 'reach' && p.run!.active) {
          await hand(t, p, block: false, reason: false);
          continue;
        }
        await t.pump(const Duration(milliseconds: 100));
      }
      await pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(p.run!.slips, 3);
      await close(t, c);
    });

    testWidgets('village: dragging into the wire\'s ground zone = deadly: freeze, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) => d.site == M7Site.village);
      final p = M7SceneGuardProbe();
      final c = await open(t, seed, p);
      final z = p.run!.geo.zone!;
      await dragTo(t, p, z.a > 180 ? 340 : 20);
      await pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M7SceneGuardMistakes.wireZone.key);
      expect(s.mistakes.single.deadly, isTrue);
      await close(t, c);
    });

    testWidgets('village: the coworker\'s hand reaching the wire, not blocked = deadly: freeze before contact, then the card', (t) async {
      final seed = _seedWhere((d) => d.site == M7Site.village);
      final p = M7SceneGuardProbe();
      final c = await open(t, seed, p);
      await takePosition(t, p);
      var met = false;
      for (var guard = 0; guard < 400 && p.run!.deadly == null; guard++) {
        if (!met && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
          await coworker(t, p);
          met = true;
          continue;
        }
        if (p.phase == 'reach' && p.run!.active) {
          final wire = p.run!.current.item == M7Item.wire;
          await hand(t, p, block: !wire && m7KindOf(p.run!.current.item) == M7Kind.evidence);
          continue;
        }
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(p.run!.deadly, M7SceneGuardMistakes.wireCoil);
      await pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M7SceneGuardMistakes.wireCoil.key);
      await close(t, c);
    });

    testWidgets('village: listening to him (coil the wire) = deadly: freeze, then the card', (t) async {
      final seed = _seedWhere((d) => d.site == M7Site.village);
      final p = M7SceneGuardProbe();
      final c = await open(t, seed, p);
      await takePosition(t, p);
      for (var guard = 0; guard < 300 && find.byType(CoworkerPeek).evaluate().isEmpty; guard++) {
        if (p.phase == 'reach' && p.run!.active) {
          await hand(t, p, block: m7KindOf(p.run!.current.item) == M7Kind.evidence);
          continue;
        }
        await t.pump(const Duration(milliseconds: 100));
      }
      await coworker(t, p, listen: true);
      await pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M7SceneGuardMistakes.wireCoil.key);
      await close(t, c);
    });

    testWidgets('pole: listening to him (the small shock) = a slip, and his reach still comes', (t) async {
      final seed = _seedWhere((d) => d.site == M7Site.pole);
      final p = M7SceneGuardProbe();
      final c = await open(t, seed, p);
      await takePosition(t, p);
      for (var guard = 0; guard < 300 && find.byType(CoworkerPeek).evaluate().isEmpty; guard++) {
        if (p.phase == 'reach' && p.run!.active) {
          await hand(t, p, block: m7KindOf(p.run!.current.item) == M7Kind.evidence);
          continue;
        }
        await t.pump(const Duration(milliseconds: 100));
      }
      await coworker(t, p, listen: true);
      await slipCard(t);
      expect(c.read(gameSaveProvider).mistakes.single.key, M7SceneGuardMistakes.listenShock.key);
      expect(await until(t, () => p.phase == 'reach' && p.run!.current.item == M7Item.colleague, maxMs: 12000), isTrue, reason: 'the tied reach follows');
      await close(t, c);
    });

    testWidgets('gesture hand: a drag from the trainee while he waits (no sweep, no hold, no pointing); off during the hands', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final p = M7SceneGuardProbe();
      final c = await open(t, 7, p);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'idle while he waits to take his place');
      expect(scene().debugOptions, isEmpty, reason: 'a drag, not a sweep');
      expect(scene().debugFrame?.ring, isNull, reason: 'no hold');
      await dragTo(t, p, 120);
      expect(scene().showing, isFalse);
      expect(await until(t, () => p.phase == 'reach' && p.run!.active, maxMs: 15000), isTrue);
      await pump(t, 3000);
      expect(scene().showing, isFalse, reason: 'no hand while a hand reaches');
      await close(t, c);
    });
  });
}
