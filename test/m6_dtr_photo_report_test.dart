// Lesson 6.1 (ডিস্ট্রিবিউশন ট্রান্সফরমার), কাজ 1 "দু'মিনিটের ছবি-রিপোর্ট": the
// rules (the shutter judges the part asked for at a readable zoom; below it
// always "too far"; a close-up of another part = a slip; the sound written as
// heard; the report only once every slot is in), the deal (the nameplate
// always, the sound's place, 1–3 faults, healthy only on patrol, his push
// fits), the libraries, the coworker's lines, and the level in the shell:
// the guide first, full clean plays (a reason pick every slot, the coworker
// refused — the climb push and the hum push), the shutter waits for him, he
// never comes before the player frames his subject, a far shot costs time
// only, a wrong-part slip card that keeps the slot, three slips, the deadly
// freeze (listening to the climb), a slip for listening to the myth, real
// drags (the frame and the zoom rail), the gesture hand, and the layout on
// 16:9 and tall phones (every part clear of the phone's controls; the
// guide's bubble clears once the request is read).
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
import 'package:slm_flutter/features/game/m6_dtr_photo_report.dart';
import 'package:slm_flutter/features/game/m6_dtr_photo_report_world.dart';
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
  rungId: '6.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6PhotoPacks['do_6_1_a']!;
typedef L = M6PhotoLines;
typedef Mk = M6PhotoMistakes;

/// The new art is not in the bundle in tests until the director wires it:
/// tests read it from disk when the bundle does not have it.
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
  await tapReasonProceed(t);
}

M6PhotoProbe get _probe => M6PhotoProbe.current!;

Future<ProviderContainer> _open(WidgetTester t, int seed, {Size size = const Size(392, 850), double top = 0}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2.0;
  t.view.padding = FakeViewPadding(top: top * 2);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6DtrPhotoReportPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1200);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// A scene rect (design px) on the screen: the scene covers the screen.
Rect _toScreen(Rect r, Size size) {
  final sh = (360 * size.height / size.width).clamp(560.0, 900.0);
  final s = math.max(size.width / 360, size.height / sh);
  final dx = (size.width - 360 * s) / 2;
  final dy = (size.height - sh * s) / 2;
  return Rect.fromLTWH(dx + r.left * s, dy + r.top * s, r.width * s, r.height * s);
}

/// Some frame at [p]'s readable zoom (or up to 0.5x more) is accepted.
bool _canShoot(M6Part p, M6PhotoGeo g) {
  final r = g.part(p);
  for (final z in [m6MinZoom[p]!, m6MinZoom[p]! + 0.25, m6MinZoom[p]! + 0.5]) {
    if (z > m6ZoomMax) continue;
    for (var dx = -40.0; dx <= 40; dx += 2) {
      for (var dy = -40.0; dy <= 40; dy += 2) {
        final cam = M6Cam(r.center.translate(dx, dy), z);
        if (g.clampCam(cam) != cam) continue;
        if (m6Judge(p, cam.frame, z, g).result == M6ShotResult.accepted) return true;
      }
    }
  }
  return false;
}

int _seedWhere(bool Function(M6PhotoDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6PhotoDeal(math.Random(s))));

/// The coworker comes: refuse him.
Future<void> _refuse(WidgetTester t, M6Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// He comes: listen to him (a wrong card, ✓).
Future<void> _listen(WidgetTester t, M6Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await waitChoiceDeck(t);
  final wrong = _onScreen(L.coworker(p).wrong);
  expect(wrong, isNotEmpty);
  await t.tap(wrong.first, warnIfMissed: false);
  await confirmChoice(t);
  await _pump(t, 800);
}

Future<void> _shoot(WidgetTester t) async {
  await t.tap(_label(L.shutter));
  await _pump(t, 400);
}

/// One slot played right (the coworker refused if he is dealt on it).
Future<void> _playSlot(WidgetTester t, M6PhotoDeal d, int i) async {
  final r = d.requests[i];
  final him = d.pushAt == i ? d.push : null;
  if (r.isSound) {
    await t.longPress(_label(L.listen));
    await _pump(t, 2400);
    if (him == M6Push.hum) await _refuse(t, him!);
    await waitChoiceDeck(t);
    final right = _label(L.readings[d.state.sound]!);
    expect(right, findsOneWidget);
    await t.tap(right, warnIfMissed: false);
    await confirmChoice(t);
    await _pump(t, 900);
  } else {
    _probe.aim(r.part!, m6MinZoom[r.part]!);
    await _pump(t, 300);
    if (him != null) await _refuse(t, him);
    await _shoot(t);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'slot $i ${r.part}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (slot $i)');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[d.why[i]]!);
  await _pump(t, 2000);
}

M6PhotoGeo get _geo780 => M6PhotoGeo.forScene(360 * 850 / 392, 0);

M6PhotoDeal _dealOf(List<M6Request> requests, {M6DtrState state = const M6DtrState(), M6Push push = M6Push.climb}) =>
    M6PhotoDeal(trigger: M6Trigger.trip, requests: requests, state: state, push: push, why: [for (final _ in requests) M6WhyTopic.plate]);

const _std = [M6Request(M6Part.stain, 0), M6Request(M6Part.ht, 0), M6Request.sound(0), M6Request(M6Part.lt, 1), M6Request(M6Part.plate, 0)];

void main() {
  group('rules', () {
    test('deals: five slots (the nameplate always, the sound once at a dealt place), 1–3 faults (healthy only on patrol), one bushing side, his push fits; plays differ', () {
      final seen = <String>{};
      final pushes = <M6Push>{};
      final soundAt = <int>{};
      final whys = <M6WhyTopic>{};
      final triggers = <M6Trigger>{};
      var patrols = 0, healthy = 0;
      final parts = <M6Part>{};
      for (var s = 0; s < 400; s++) {
        final d = m6PhotoDeal(math.Random(s));
        expect(d.requests, hasLength(5));
        expect(d.requests.where((r) => r.isSound), hasLength(1));
        final photos = [for (final r in d.requests) if (!r.isSound) r.part!];
        expect(photos.toSet(), hasLength(4));
        expect(photos, contains(M6Part.plate));
        parts.addAll(photos);
        soundAt.add(d.requests.indexWhere((r) => r.isSound));
        expect(d.faults, lessThanOrEqualTo(3));
        if (d.trigger == M6Trigger.patrol) {
          patrols++;
          if (d.faults == 0) healthy++;
        } else {
          expect(d.faults, greaterThanOrEqualTo(1), reason: 'only a patrol finds a fully healthy DTR');
        }
        // Faults only where they are asked for (or the sound).
        final st = d.state;
        if (st.wet) expect(photos, contains(M6Part.stain));
        if (st.gaugeLow) expect(photos, contains(M6Part.gauge));
        if (st.gelWet) expect(photos, contains(M6Part.gel));
        if (st.bush == M6Bush.ht) expect(photos, contains(M6Part.ht));
        if (st.bush == M6Bush.lt) expect(photos, contains(M6Part.lt));
        expect(m6PushesFor(st, d.requests), contains(d.push));
        expect(m6PushesFor(st, d.requests).length, greaterThanOrEqualTo(2), reason: 'a wet stain asked for or a normal hum, always');
        expect(d.pushAt, greaterThanOrEqualTo(0));
        final at = d.requests[d.pushAt];
        switch (d.push) {
          case M6Push.leak:
            expect(at.part, M6Part.stain);
            expect(st.wet, isTrue);
          case M6Push.hum:
            expect(at.isSound, isTrue);
            expect(st.sound, M6Sound.hum);
          case M6Push.climb:
            expect(at.part, M6Part.plate);
        }
        for (final (i, w) in d.why.indexed) {
          final r = d.requests[i];
          final fits = switch (r.part) {
            null => {switch (st.sound) { M6Sound.hum => M6WhyTopic.hum, M6Sound.rattle => M6WhyTopic.rattle, M6Sound.crackle => M6WhyTopic.crackle }},
            M6Part.stain => {st.wet ? M6WhyTopic.stainWet : M6WhyTopic.stainDry},
            M6Part.gauge => {st.gaugeLow ? M6WhyTopic.gaugeLow : M6WhyTopic.gaugeOk},
            M6Part.gel => {st.gelWet ? M6WhyTopic.gelWet : M6WhyTopic.gelDry},
            M6Part.ht => {M6WhyTopic.htId, st.bush == M6Bush.ht ? M6WhyTopic.bushFault : M6WhyTopic.bushClean},
            M6Part.lt => {M6WhyTopic.ltId, st.bush == M6Bush.lt ? M6WhyTopic.bushFault : M6WhyTopic.bushClean},
            M6Part.fins => {M6WhyTopic.fins},
            M6Part.drum => {M6WhyTopic.drum},
            M6Part.plate => {M6WhyTopic.plate},
          };
          expect(fits, contains(w), reason: '${r.part} $w');
        }
        pushes.add(d.push);
        whys.addAll(d.why);
        triggers.add(d.trigger);
        seen.add('${d.trigger.name}|${d.requests.map((r) => '${r.part?.name ?? 'snd'}${r.phrasing}').join()}|${st.wet}${st.leakAt.name}${st.gaugeLow}${st.gel.name}${st.bush.name}${st.sound.name}${st.light.name}|${d.push.name}');
      }
      expect(seen.length, greaterThan(350));
      expect(pushes, M6Push.values.toSet());
      expect(triggers, M6Trigger.values.toSet());
      expect(soundAt, {0, 1, 2, 3, 4});
      expect(parts, M6Part.values.toSet());
      expect(whys, M6WhyTopic.values.toSet());
      expect(healthy, greaterThan(0));
      expect(healthy / patrols, lessThanOrEqualTo(0.25), reason: 'healthy on at most 1 patrol in 4');
    });

    test('every part can be shot alone at its readable zoom (centred on a 16:9 or taller phone); the parts never overlap; clear of the phone controls', () {
      for (var h = 560.0; h <= 900; h += 20) {
        for (final top in [0.0, 24.0]) {
          final g = M6PhotoGeo.forScene(h, 0, topInset: top);
          final rects = {for (final p in M6Part.values) p: g.part(p)};
          for (final p in M6Part.values) {
            final r = rects[p]!;
            expect(_canShoot(p, g), isTrue, reason: 'h $h top $top $p: some frame holds it alone');
            // Centred on it at its readable zoom: alone from a 16:9 phone up.
            if (h >= 640 || (top == 0 && h >= 600)) {
              final cam = g.clampCam(M6Cam(r.center, m6MinZoom[p]!));
              expect(m6Judge(p, cam.frame, cam.zoom, g).result, M6ShotResult.accepted, reason: 'h $h top $top $p');
            }
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(240), reason: 'left of the live view and the zoom rail');
            expect(r.top, greaterThanOrEqualTo(M6PhotoGeo.partsTop + top - 0.01), reason: 'under the JE chat');
            expect(r.bottom, lessThan(h - 150), reason: 'above the shutter row and the tray');
            for (final q in M6Part.values) {
              if (q.index > p.index) expect(r.overlaps(rects[q]!), isFalse, reason: 'h $h $p / $q');
            }
          }
          expect(g.h, lessThanOrEqualTo(470.01));
          expect(g.groundY, h - M6PhotoGeo.floorUp, reason: 'the ground stays above the guide standing on the tray');
        }
      }
    });

    test('the shutter: below the readable zoom always "too far"; a close-up of another part is wrong; the sky is empty; the gauge and the plate whole', () {
      final g = _geo780;
      final plate = g.part(M6Part.plate);
      expect(m6Judge(M6Part.plate, M6Cam(plate.center, 2.4).frame, 2.4, g).result, M6ShotResult.far);
      expect(m6Judge(M6Part.plate, M6Cam(plate.center, 1).frame, 1, g).result, M6ShotResult.far, reason: 'a wide shot tells nothing');
      // A wide shot of nothing is "too far" too (no probing by shooting wide).
      expect(m6Judge(M6Part.stain, M6Cam(const Offset(300, 200), 1).frame, 1, g).result, M6ShotResult.far);
      final drum = g.part(M6Part.drum);
      final j = m6Judge(M6Part.plate, M6Cam(drum.center, 3).frame, 3, g);
      expect(j.result, M6ShotResult.wrong);
      expect(j.subject, M6Part.drum);
      expect(m6Judge(M6Part.plate, M6Cam(const Offset(300, 200), 3).frame, 3, g).result, M6ShotResult.empty);
      // The plate a little off: most of it, not every row.
      // The frame's left edge cuts the plate 20 % in (a 2.5x frame is 80 wide).
      final off = M6Cam(plate.center.translate(40 - plate.width * 0.3, 0), 2.5);
      expect(m6Coverage(plate, off.frame), greaterThanOrEqualTo(0.7));
      expect(m6Judge(M6Part.plate, off.frame, off.zoom, g).result, M6ShotResult.partial);
      // The LT bushings need 3x (so the HT ones cannot share the frame).
      final lt = g.part(M6Part.lt);
      expect(m6Judge(M6Part.lt, M6Cam(lt.center, 2.5).frame, 2.5, g).result, M6ShotResult.far);
      expect(m6Judge(M6Part.lt, M6Cam(lt.center, 3).frame, 3, g).result, M6ShotResult.accepted);
      expect(m6Coverage(g.part(M6Part.ht), M6Cam(lt.center, 3).frame), lessThan(0.7));
    });

    test('no hedging: the HT and the LT bushings in one frame are a slip (not accepted), at every height and aim', () {
      // The review's frame: centred at x 170 on the HT row at 2x holds all
      // the HT and most of the LT bushings.
      final g = _geo780;
      final ht = g.part(M6Part.ht);
      final both = M6Cam(Offset(170, ht.center.dy), 2);
      expect(m6Coverage(ht, both.frame), 1);
      expect(m6Coverage(g.part(M6Part.lt), both.frame), greaterThanOrEqualTo(0.7));
      final j = m6Judge(M6Part.ht, both.frame, 2, g);
      expect(j.result, M6ShotResult.both);
      expect(j.subject, M6Part.lt);
      final r = M6PhotoRun(_dealOf([const M6Request(M6Part.ht, 0), ..._std.skip(1)]));
      final shot = r.shoot(both.frame, 2, g)!;
      expect(shot.result, M6ShotResult.both);
      expect(shot.mistake, Mk.bushBoth);
      expect(r.slips, 1);
      expect(r.roundDone, isFalse);
      // Any aim, any height: a bushing photo with the other set half in is
      // never accepted.
      for (var h = 560.0; h <= 900; h += 40) {
        final gh = M6PhotoGeo.forScene(h, 0);
        for (final want in [M6Part.ht, M6Part.lt]) {
          final other = gh.part(m6PairOf(want)!);
          for (final z in [2.0, 2.5, 3.0, 3.5, 4.0]) {
            for (var x = 100.0; x <= 230; x += 4) {
              for (var y = gh.y(0.35); y <= gh.y(0.6); y += 4) {
                final f = M6Cam(Offset(x, y), z).frame;
                if (m6Coverage(other, f) < m6PairLimit) continue;
                expect(m6Judge(want, f, z, gh).result, isNot(M6ShotResult.accepted), reason: 'h $h $want z $z ($x, $y)');
              }
            }
          }
        }
      }
    });

    test('another part whole in the frame too: the JE asks for only his (time only); too close to hold the part whole: zoom out (time only)', () {
      final g = _geo780;
      // The fins and the nameplate in one 2x frame.
      final crowd = M6Cam(Offset(191, g.y(0.65)), 2);
      expect(m6Coverage(g.part(M6Part.fins), crowd.frame), greaterThanOrEqualTo(0.7));
      expect(m6Coverage(g.part(M6Part.plate), crowd.frame), greaterThanOrEqualTo(0.9));
      final j = m6Judge(M6Part.fins, crowd.frame, 2, g);
      expect(j.result, M6ShotResult.crowded);
      expect(j.subject, M6Part.plate);
      // Too close: a 4x frame filled with the stain (it is 80 wide) or the HT
      // bushings is "zoom out", not "nothing".
      for (final p in [M6Part.stain, M6Part.ht, M6Part.fins]) {
        final cam = g.clampCam(M6Cam(g.part(p).center, 4));
        expect(m6Judge(p, cam.frame, 4, g).result, M6ShotResult.close, reason: '$p');
      }
      final r = M6PhotoRun(_dealOf(_std));
      final stain = g.clampCam(M6Cam(g.part(M6Part.stain).center, 4));
      expect(r.shoot(stain.frame, 4, g)!.result, M6ShotResult.close);
      expect(r.slips, 0);
      expect(r.roundDone, isFalse);
    });

    test('a run: right photo closes the slot; a wrong part is a slip; far / partial / empty cost nothing; the sound written as heard; the report only at the end', () {
      final g = _geo780;
      final r = M6PhotoRun(_dealOf(_std, state: const M6DtrState(wet: true, bush: M6Bush.ht, sound: M6Sound.rattle)));
      final stain = g.part(M6Part.stain);
      expect(r.shoot(M6Cam(stain.center, 1).frame, 1, g)!.result, M6ShotResult.far);
      expect(r.slips, 0);
      final d = r.shoot(M6Cam(g.part(M6Part.drum).center, 3).frame, 3, g)!;
      expect(d.result, M6ShotResult.wrong);
      expect(d.mistake, Mk.wrongStain);
      expect(r.slips, 1);
      expect(r.sendReport(), isFalse);
      final cam = g.clampCam(M6Cam(stain.center, 2));
      expect(r.shoot(cam.frame, cam.zoom, g)!.result, M6ShotResult.accepted);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtFault));
      expect(r.shoot(cam.frame, cam.zoom, g), isNull, reason: 'nothing due until the reason is paid');
      r.advance();
      final ht = g.part(M6Part.ht);
      expect(r.shoot(M6Cam(ht.center, 2).frame, 2, g)!.result, M6ShotResult.accepted);
      expect(r.caught, contains(L.caughtHtLt));
      r.advance();
      // The sound: nothing written before it is heard; the photo shutter does nothing.
      expect(r.request.isSound, isTrue);
      expect(r.shoot(M6Cam(ht.center, 2).frame, 2, g), isNull);
      expect(r.pickSound(M6Sound.rattle), isNull);
      expect(r.roundDone, isFalse);
      r.hear();
      expect(r.pickSound(M6Sound.hum), Mk.soundMissed);
      expect(r.pickSound(M6Sound.crackle), Mk.soundMixed);
      expect(r.pickSound(M6Sound.rattle), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtSound));
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.advance();
      r.advance();
      expect(r.allShot, isFalse);
      r.advance();
      expect(r.allShot, isTrue);
      expect(r.sendReport(), isTrue);
      expect(r.done, isTrue);
      expect(r.passed, isTrue, reason: 'three slips leave 55 (the page strikes out at the third)');
      expect(Mk.sound(M6Sound.hum, M6Sound.crackle), Mk.soundHum);
      expect(Mk.sound(M6Sound.crackle, M6Sound.hum), Mk.soundMissed);
    });

    test('the coworker: (a) and (b) are slips, (c) the climb is deadly (M6-4, X2); his slot is his subject\'s', () {
      expect(Mk.push(M6Push.leak).deadly, isFalse);
      expect(Mk.push(M6Push.hum).deadly, isFalse);
      expect(Mk.push(M6Push.climb), Mk.climbLive);
      expect(Mk.climbLive.deadly, isTrue);
      expect(_dealOf(_std, push: M6Push.climb).pushAt, 4);
      expect(_dealOf(_std, push: M6Push.leak).pushAt, 0);
      expect(_dealOf(_std, push: M6Push.hum).pushAt, 2);
      expect(m6PushesFor(const M6DtrState(sound: M6Sound.crackle), _std), [M6Push.climb]);
      expect(m6PushesFor(const M6DtrState(wet: true), _std), [M6Push.leak, M6Push.hum, M6Push.climb]);
      expect(m6PushesFor(const M6DtrState(wet: true, sound: M6Sound.rattle), _std.where((r) => r.part != M6Part.stain).toList()), [M6Push.climb],
          reason: 'myth 1 only when the stain is asked for and wet');
      final r = M6PhotoRun(_dealOf(_std));
      r.failDeadly(Mk.climbLive);
      expect(r.ended, isTrue);
      expect(r.passed, isFalse);
    });

    test('English digits only; jol not pani; every mistake has its picture; the deadly set; keys unique; lesson points; the art folder all used', () {
      final all = <String>[
        L.introTrip,
        L.introComplaint,
        L.introPatrol,
        L.start,
        for (final l in L.requests.values) ...l,
        ...L.soundAsks,
        L.jeFar,
        L.jePartial,
        L.jeEmpty,
        L.jeClose,
        L.jeOnly,
        L.jeGot,
        L.soundAsk,
        L.sendNow,
        ...L.tapWhy,
        L.jeName,
        L.send,
        L.shutter,
        L.listen,
        L.zoom,
        ...L.readings.values,
        for (final s in M6Sound.values) L.soundShort(s),
        for (final t in M6WhyTopic.values) L.whyQ(t),
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6Push.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.caughtPlate,
        L.caughtHtLt,
        L.caughtFault,
        L.caughtSound,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.climbLive});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.1/m6_dtr_photo_report/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 7), reason: m.key);
      }
      for (final p in M6Part.values) {
        expect(Mk.wrong(p).key, endsWith('wrong-${p == M6Part.plate ? 'plate' : p.name}'));
      }
      for (final f in m6SoundClips.values) {
        expect(File('assets/$f').existsSync(), isTrue, reason: f);
      }
      const dir = 'assets/game/art/m6_dtr_photo_report/';
      final used = {
        for (final m in Mk.all) m.art.replaceFirst(dir, ''),
        for (final f in m6SoundClips.values) f.split('/').last,
      };
      final files = Directory('assets/game/art/m6_dtr_photo_report').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6PhotoPacks.keys, ['do_6_1_a']);
      expect(m6PhotoQuickMs, 120000);
    });

    test('libraries: same length, big enough, never a rule marked wrong; the readings alike', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6WhyTopic.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.wrongFor(w));
        expect(L.myths, containsAll(L.wrongFor(w)));
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.wrongFor(w), math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
      // Each topic's wrong cards hold a myth about its own part, not another's.
      expect(L.wrongFor(M6WhyTopic.gelWet), contains('জেলের রং দেখে কিছুই বোঝা যায় না'));
      expect(L.wrongFor(M6WhyTopic.gelWet), isNot(contains('বড়-ছোট সব বুশিং একই, কোনো তফাত নেই')));
      expect(L.wrongFor(M6WhyTopic.plate), isNot(contains('জেলের রং দেখে কিছুই বোঝা যায় না')));
      expect(L.wrongFor(M6WhyTopic.hum), contains('গুনগুন শব্দ হলেই ভেতরে বড় গোলমাল'));
      expectSameLength('readings', L.readings.values.toList());
      expect(L.readings.values.toSet(), hasLength(3));
      for (final s in M6Sound.values) {
        expect(L.soundOf(L.readings[s]!), s);
      }
      for (final p in M6Part.values) {
        expect(L.requests[p], hasLength(greaterThanOrEqualTo(2)), reason: '$p: two wordings');
      }
      expect(L.soundAsks, hasLength(2));
    });

    test('rival lines: his exit is recorded; myths 1 and 2 word for word in his pushes; his three new lines and the guide\'s are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      // Myth 1 with the owner's spelling «চুঁইয়ে» (2026-11-15).
      expect(L.coworkerLeak.line, startsWith('ট্রান্সফরমার থেকে সামান্য তেল চুঁইয়ে পড়লে কিছু যায় আসে না, যতক্ষণ না পুরো তেল ফুরিয়ে যাচ্ছে।'));
      expect(L.coworkerHum.line, startsWith('ট্রান্সফরমার থেকে গুনগুন (হামিং) শব্দ হলেই বুঝতে হবে ভেতরে বড় কোনো গোলমাল হয়েছে।'));
      expect(L.coworkerClimb.line, 'মাচায় উঠে নেমপ্লেটটা মুছে ছবি তোলো!');
      expect(L.newRivalLines, [L.coworkerLeak.line, L.coworkerHum.line, L.coworkerClimb.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length));
      // 38 + the two new JE replies + his three new asks + 15 mistake texts.
      expect(L.newGuideLines, hasLength(58));
      expect(L.newGuideLines, containsAll([for (final m in Mk.all) m.textBn]));
      expect(L.newGuideLines, containsAll([L.askLeak, L.askHum, L.askClimb, L.jeClose, L.jeOnly]));
      for (final cw in L.allCoworkers) {
        // Every ask he makes the guide say is new here or shared with the
        // levels that already use it (M2–M5).
        for (final a in cw.asks) {
          expect(L.newGuideLines.contains(a) || const {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'চালু ট্রান্সফরমারে উঠবেন?'}.contains(a), isTrue, reason: a);
        }
      }
      for (final l in L.newRivalLines) {
        // Not recorded yet (the director records them with tool/rival_clip.py):
        // until then the line is silent and its caption held.
        debugPrint('RIVAL m6_dtr_photo_report: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
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

    testWidgets('the guide comes first: a tap does not skip him; then the JE\'s first request, the tray and the phone', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6DtrPhotoReportPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      final d = m6PhotoDeal(math.Random(3));
      expect(find.text(L.request(d.requests.first)), findsWidgets);
      expect(find.text(L.jeName), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(ValueKey('slot-$i')), findsOneWidget);
      }
      expect(_label(d.requests.first.isSound ? L.listen : L.shutter), findsOneWidget);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the request, a different way each time', (t) async {
      final c = await _open(t, 5);
      final d = m6PhotoDeal(math.Random(5));
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.request(d.requests.first))), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play with the deadly-class push (refused), one with the hum push.
    final flowSeeds = [
      _seedWhere((d) => d.push == M6Push.climb && d.requests.any((r) => r.part == M6Part.lt)),
      _seedWhere((d) => d.push == M6Push.hum && d.requests.any((r) => r.part == M6Part.gauge)),
      _seedWhere((d) => d.push == M6Push.leak),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): five slots, a reason each, he is refused, the report sent → pass', (t) async {
        final d = m6PhotoDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 5; i++) {
          await _playSlot(t, d, i);
        }
        expect(await _pumpUntil(t, _label(L.send)), isTrue);
        await t.tap(_label(L.send));
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.1/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.1/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtPlate), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final plateFirst = _seedWhere((d) => d.push == M6Push.climb && d.requests.first.part == M6Part.plate);
    testWidgets('he never comes before the player frames his subject: the start view holding the nameplate does not call him; a zoom to it does', (t) async {
      final c = await _open(t, plateFirst);
      final g = _probe.geo!;
      expect(m6Coverage(g.part(M6Part.plate), _probe.cam.frame), greaterThanOrEqualTo(0.7), reason: 'the wide start view holds the plate');
      await _pump(t, 5000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'nothing framed yet');
      _probe.aim(M6Part.plate, 2.5);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue, reason: 'framed: he comes');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, L.coworkerClimb.right);
      await _pump(t, 2600);
      await _close(t, c);
    });

    testWidgets('the shutter waits for him: the nameplate framed and shot at once — he cuts in, no photo is taken', (t) async {
      final c = await _open(t, plateFirst);
      _probe.aim(M6Part.plate, 2.5);
      await t.pump(const Duration(milliseconds: 60));
      await t.tap(_label(L.shutter));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_probe.run.roundDone, isFalse, reason: 'the shot waited');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, L.coworkerClimb.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _shoot(t);
      expect(_probe.run.roundDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('listening to the climb push = deadly: the scene freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, plateFirst);
      _probe.aim(M6Part.plate, 2.5);
      await _listen(t, M6Push.climb);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.climbLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final stainFirst = _seedWhere((d) => d.push == M6Push.leak && d.requests.first.part == M6Part.stain);
    testWidgets('listening to myth 1 at the stain is a slip: its card, and the slot goes on', (t) async {
      final c = await _open(t, stainFirst);
      _probe.aim(M6Part.stain, 2);
      await _listen(t, M6Push.leak);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.pushLeak.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _shoot(t);
      expect(_probe.run.roundDone, isTrue, reason: 'the stain photo still goes in');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.pushLeak.key);
      await _close(t, c);
    });

    final photoAlone = _seedWhere((d) => !d.requests.first.isSound && d.pushAt != 0);
    testWidgets('a far shot costs time only (the JE asks again); a close-up of another part is a slip card; the slot goes on', (t) async {
      final d = m6PhotoDeal(math.Random(photoAlone));
      final want = d.requests.first.part!;
      final c = await _open(t, photoAlone);
      final g = _probe.geo!;
      _probe.aimAt(g.part(want).center, 1);
      await _pump(t, 200);
      await _shoot(t);
      expect(find.text(L.jeFar), findsWidgets);
      expect(find.byType(MistakeCard), findsNothing);
      final other = want == M6Part.drum ? M6Part.plate : M6Part.drum;
      _probe.aim(other, 3);
      await _pump(t, 200);
      await _shoot(t);
      expect(find.text(Mk.wrong(want).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_probe.run.index, 0, reason: 'the same slot');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.wrong(want).key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final d = m6PhotoDeal(math.Random(photoAlone));
      final want = d.requests.first.part!;
      final c = await _open(t, photoAlone);
      final other = want == M6Part.drum ? M6Part.plate : M6Part.drum;
      for (var i = 0; i < 3; i++) {
        _probe.aim(other, 3);
        await _pump(t, 200);
        await _shoot(t);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('real touches: a drag on the scene moves the frame by the drag; a drag up the rail zooms in', (t) async {
      final c = await _open(t, photoAlone);
      const k = 392 / 360;
      final before = _probe.cam;
      await t.dragFrom(const Offset(150, 470), const Offset(-40, -30));
      await _pump(t, 200);
      final moved = _probe.cam.center - before.center;
      expect(moved.dx, closeTo(-40 / k, 0.6));
      expect(moved.dy, closeTo(-30 / k, 0.6));
      final z0 = _probe.cam.zoom;
      await t.drag(_label(L.zoom), const Offset(0, -80));
      await _pump(t, 200);
      expect(_probe.cam.zoom, closeTo(z0 + 80 / (196 - 36) * 3, 0.05));
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle at a photo, a drag nudge (no sweep, no tap); none while a reason deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final d = m6PhotoDeal(math.Random(photoAlone));
      final c = await _open(t, photoAlone);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      // The request is read out first (muted: its reading time), then idle.
      await _pump(t, 14000);
      expect(scene().showing, isTrue, reason: 'idle: the frame not moved yet');
      expect(scene().debugOptions, isEmpty, reason: 'a drag, not a pick');
      expect(scene().debugFrame?.ripple, isNull, reason: 'no tap on anything');
      final want = d.requests.first.part!;
      _probe.aim(want, m6MinZoom[want]!);
      await _pump(t, 300);
      await _shoot(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own hand');
      await _close(t, c);
    });

    testWidgets('layout on 16:9 and tall phones: every part clear of the JE chat (its longest line), the live view, the zoom rail, the shutter and the guide; his bubble clears once the request is read', (t) async {
      for (final size in const [Size(360, 560), Size(360, 600), Size(360, 640), Size(360, 700), Size(392, 850)]) {
        final c = await _open(t, photoAlone, size: size, top: 24);
        final g = _probe.geo!;
        expect(c.read(guideDirectorProvider).line, isNotEmpty, reason: 'he reads the request');
        // The JE's longest line on the chat (its tallest: two lines; maxLines 3).
        final longest = [...L.requests.values.expand((l) => l), ...L.soundAsks, L.jeFar, L.jePartial, L.jeEmpty, L.jeClose, L.jeOnly, L.jeGot, L.sendNow]
            .reduce((a, b) => a.length >= b.length ? a : b);
        _probe.jeSay(longest);
        await _pump(t, 400);
        final chat = t.getRect(find.byKey(const ValueKey('je-chat')));
        final live = t.getRect(find.byKey(const ValueKey('live-view')));
        final rail = t.getRect(find.byKey(const ValueKey('zoom-rail-0')));
        final shutter = t.getRect(find.byKey(const ValueKey('shutter')));
        final guide = t.getRect(find.byKey(const ValueKey('hud-guide')));
        final sprite = Rect.fromLTRB(guide.right - 116, guide.bottom - 116, guide.right, guide.bottom);
        expect(rail.bottom, lessThanOrEqualTo(sprite.top), reason: '$size: the rail above the guide');
        expect(live.top, greaterThanOrEqualTo(chat.bottom), reason: '$size: the live view under the chat');
        for (final p in M6Part.values) {
          final r = _toScreen(g.part(p), size);
          for (final (name, box) in [('chat', chat), ('live view', live), ('zoom rail', rail), ('shutter', shutter), ('guide', sprite)]) {
            expect(r.overlaps(box), isFalse, reason: '$size $p under the $name');
          }
        }
        await _pump(t, 6000);
        expect(c.read(guideDirectorProvider).line, isEmpty, reason: '$size: read, the bubble clears (the words stay on the chat)');
        expect(find.text(longest), findsOneWidget, reason: 'on the chat');
        await _close(t, c);
      }
    });
  });
}
