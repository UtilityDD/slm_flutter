// Lesson 5.6 (শর্ট সার্কিট ও ওপেন সার্কিট), কাজ 2 "ছেঁড়া তার, তবু লাইভ": the
// rules (what is live: the wire, a fence/shed it rests on — all of it — and
// anything conductive touching those; a visible gap is not connected), the
// deal (varied, every wave has a live and a decoy target, a subtle live one
// from wave 2 when the lane has one), the lane's geometry (targets in/out of
// the rope ring, clear ways in with time to stop each person), the stop rules
// (timely / late = slip / decoy = no slip / unstopped live = deadly / one at a
// time), the swipe's pick, the hint's direction (points at nobody), the
// libraries; and the level in the shell: the guide first, tap-the-guide, a
// full clean play with the coworker refused (the next wave waits for him), a
// late stop's card, three late stops strike out, the deadly freezes (a
// bystander reaches live metal; a wrong opening card; listening to him), and
// the gesture hand in the demo.
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
import 'package:slm_flutter/features/game/m5_live_wire_guard.dart';
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
  rungId: '5.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m5LiveWirePacks['do_5_6_b']!;

/// The art folder may be newer than the test bundle: read from disk then.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      // Other agents' test runs rebuild the shared test bundle: without its
      // manifest, images resolve to their plain key (read from disk).
      if (key == 'AssetManifest.bin') return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

const _heights = [560.0, 700.0, 780.0, 900.0];

List<M5WireLayout> get _layouts => [
      for (final rest in M5WireRest.values)
        for (final mirror in [false, true])
          for (final bh in M5Host.values)
            for (final bt in [false, true])
              for (final lh in M5Host.values)
                for (final lt in [false, true])
                  M5WireLayout(rest: rest, mirror: mirror, bikeHost: bh, bikeTouch: bt, lineHost: lh, lineTied: lt),
    ];

/// The scene's design height on the 392 × 850 test screen.
const _testH = 360 * 850 / 392;

/// Plays the pure run with a perfect player: each live walker stopped
/// [after] ms after he sets off (or as soon as he is late, if [late]). With
/// [everyone] the player stops every person (live or not) [after] ms after
/// he sets off, first come first stopped, as soon as he is free.
({int lates, bool contact, int done, int clean, int needless}) _simulate(M5LiveWireDeal d, double h,
    {double after = 300, bool late = false, int maxLates = 99, bool everyone = false}) {
  final g = M5WireGeo.forScene(h, 0, d.layout);
  final r = M5LiveWireRun(d);
  r.pickOpening(M5LiveWireLines.openRight.first);
  r.next();
  var lates = 0;
  var clean = 0;
  for (var w = 0; w < 3; w++) {
    r.startWave(g);
    for (var ms = 0.0; ms < 60000 && !r.stepDone; ms += 50) {
      if (r.tick(ms) != null) return (lates: lates, contact: true, done: w, clean: clean, needless: r.needless);
      final order = [...r.walkers]..sort((a, b) => a.startMs.compareTo(b.startMs));
      for (final x in order) {
        if (x.state != M5WalkerState.walking || (!x.live && !everyone) || !r.canStop) continue;
        final ready = late && lates < maxLates ? r.isLate(x, ms) : ms - x.startMs >= after;
        if (ready) {
          final s = r.stop(x);
          if (s.kind == M5StopKind.late) lates++;
          break;
        }
      }
    }
    if (!r.stepDone) return (lates: lates, contact: false, done: w, clean: clean, needless: r.needless);
    if (r.waveClean) clean++;
    r.next();
  }
  return (lates: lates, contact: false, done: 3, clean: clean, needless: r.needless);
}

void main() {
  group('rules', () {
    test('live-ness: the wire; the fence/shed end B rests on; a bicycle/clothesline touching a live host; gaps are dead', () {
      for (final l in _layouts) {
        expect(l.live(M5Thing.endA), isTrue);
        expect(l.live(M5Thing.wireB), isTrue);
        expect(l.live(M5Thing.fenceNear), l.rest == M5WireRest.fence);
        expect(l.live(M5Thing.fenceFar), l.rest == M5WireRest.fence, reason: 'all of the fence, beyond the rope too');
        expect(l.live(M5Thing.shedFar), l.rest == M5WireRest.shed);
        final bikeHostLive = l.bikeHost == M5Host.fence ? l.rest == M5WireRest.fence : l.rest == M5WireRest.shed;
        expect(l.live(M5Thing.bicycle), l.bikeTouch && bikeHostLive);
        final lineHostLive = l.lineHost == M5Host.fence ? l.rest == M5WireRest.fence : l.rest == M5WireRest.shed;
        expect(l.live(M5Thing.clothesline), l.lineTied && lineHostLive);
        for (final t in [M5Thing.tree, M5Thing.bench, M5Thing.drum]) {
          expect(l.live(t), isFalse);
        }
        for (final t in M5Thing.values) {
          if (l.inRing(t)) expect(l.live(t), isTrue, reason: 'only live things inside the ring');
        }
      }
    });

    test('deals: 3 waves (3, 3–4, 4), each with a live and a decoy target, all different; a subtle one from wave 2; plays differ', () {
      final seen = <String>{};
      final rests = <M5WireRest>{};
      var fenceDead = 0;
      for (var s = 0; s < 120; s++) {
        final d = m5LiveWireDeal(math.Random(s));
        rests.add(d.layout.rest);
        if (!d.layout.live(M5Thing.fenceFar)) fenceDead++;
        expect(d.waves.map((w) => w.length).toList(), [3, anyOf(3, 4), 4]);
        expect(d.coworkerAfter, inInclusiveRange(1, 2));
        final subtle = [for (final t in M5Thing.values) if (d.layout.live(t) && t != M5Thing.endA && t != M5Thing.wireB) t];
        for (final (i, w) in d.waves.indexed) {
          final targets = w.map((p) => p.target).toList();
          expect(targets.toSet(), hasLength(targets.length), reason: 'seed $s wave $i: one person per thing');
          expect(targets.where(d.layout.live), isNotEmpty, reason: 'seed $s wave $i: someone heads to live metal');
          expect(targets.where((t) => !d.layout.live(t)), isNotEmpty, reason: 'seed $s wave $i: a decoy');
          if (i > 0 && subtle.isNotEmpty) expect(targets.any(subtle.contains), isTrue, reason: 'seed $s wave $i: subtle');
          for (var k = 1; k < w.length; k++) {
            // Close (the trap, from wave 2): a needless one, then another or the live one.
            final close = i > 0 && !d.layout.live(w[k - 1].target) && (!d.layout.live(w[k].target) || w[k].trap);
            expect(w[k].startMs - w[k - 1].startMs, close ? inInclusiveRange(300, 600) : inInclusiveRange(1100, 2300), reason: 'seed $s wave $i');
          }
        }
        seen.add('${d.layout.hashCode}|${d.waves.map((w) => w.map((p) => p.target.name).join(',')).join('/')}|${d.coworkerAfter}');
      }
      expect(seen.length, greaterThan(100));
      expect(rests, M5WireRest.values.toSet(), reason: 'end B rests on the fence, the shed or the road');
      expect(fenceDead, greaterThan(40), reason: 'the fence is not always live');
    });

    test('the lane: in-ring targets inside the rope, the rest outside; trainee, demo figure and ways in outside; on screen', () {
      for (final h in _heights) {
        for (final l in _layouts) {
          final g = M5WireGeo.forScene(h, 0, l);
          final ring = g.ring;
          for (final t in M5Thing.values) {
            final p = g.target(t);
            expect(p.dx, inInclusiveRange(4, 356), reason: '$h $t');
            expect(p.dy, inInclusiveRange(g.top, g.bottom), reason: '$h $t');
            expect(ring.contains(p), l.inRing(t), reason: 'h $h ${l.rest} mirror ${l.mirror}: $t');
            if (!l.inRing(t)) expect(ring.inflate(6).contains(p), isFalse, reason: 'h $h ${l.rest}: $t too close to the rope');
          }
          expect(ring.overlaps(g.trainee), isFalse, reason: 'the trainee stays outside the ring');
          expect(ring.inflate(10).contains(g.demoAt), isFalse);
          for (final s in g.spawns) {
            expect(ring.contains(s), isFalse);
          }
          expect(g.trainee.top, greaterThan(g.y(0.62)), reason: 'clear of the things above him');
        }
      }
    });

    test('every target has a clear way in with ≥ 2.2 s before the walker is late', () {
      for (final h in _heights) {
        for (final l in _layouts) {
          final g = M5WireGeo.forScene(h, 0, l);
          for (final t in M5Thing.values) {
            for (var seed = 0; seed < 7; seed++) {
              final s = g.spawns[m5SpawnFor(g, t, seed)];
              final to = g.target(t);
              expect(g.clearPath(s, to, intoRing: l.inRing(t)), isTrue, reason: 'h $h ${l.rest} m${l.mirror}: $t from $s');
              if (l.live(t)) {
                expect(m5LateAfterMs(g, s, to, inRing: l.inRing(t)), greaterThanOrEqualTo(2200), reason: 'h $h ${l.rest}: $t');
              }
            }
          }
        }
      }
    });

    test('a perfect player can stop every live walker in time (one at a time), on every height', () {
      for (var s = 0; s < 60; s++) {
        final d = m5LiveWireDeal(math.Random(s));
        for (final h in [560.0, _testH, 900.0]) {
          final r = _simulate(d, h);
          expect(r.contact, isFalse, reason: 'seed $s h $h');
          expect(r.lates, 0, reason: 'seed $s h $h');
          expect(r.done, 3, reason: 'seed $s h $h');
          expect(r.clean, 3, reason: 'seed $s h $h: every wave earns its +5');
          expect(r.needless, 0, reason: 'seed $s h $h');
        }
      }
    });

    test('from wave 2 needless people set off just before a live one (the trap), from other ways in', () {
      for (var s = 0; s < 200; s++) {
        final d = m5LiveWireDeal(math.Random(s));
        expect(d.waves[0].where((p) => p.trap), isEmpty, reason: 'seed $s: wave 1 has no trap');
        for (var w = 1; w < 3; w++) {
          final plans = d.waves[w];
          final traps = [for (final (i, p) in plans.indexed) if (p.trap) i];
          expect(traps, hasLength(1), reason: 'seed $s wave $w');
          final i = traps.single;
          expect(d.layout.live(plans[i].target), isTrue);
          expect(i, greaterThan(0), reason: 'seed $s wave $w: a needless one comes first');
          expect(d.layout.live(plans[i - 1].target), isFalse, reason: 'seed $s wave $w');
          expect(plans[i].startMs - plans[i - 1].startMs, lessThan(M5LiveWireRun.needlessBusyMs), reason: 'seed $s wave $w');
          for (final h in [560.0, _testH, 900.0]) {
            final g = M5WireGeo.forScene(h, 0, d.layout);
            final r = M5LiveWireRun(d)..index = w + 1;
            r.startWave(g);
            expect(r.walkers[i].from, isNot(r.walkers[i - 1].from), reason: 'seed $s wave $w h $h: they come in apart');
          }
        }
      }
    });

    test('stopping everyone does not pay: every wave loses its +5, no quick bonus, and often a late stop', () {
      var plays = 0;
      var hurt = 0;
      for (var s = 0; s < 60; s++) {
        final d = m5LiveWireDeal(math.Random(s));
        for (final h in [560.0, _testH, 900.0]) {
          final r = _simulate(d, h, everyone: true);
          plays++;
          expect(r.needless, greaterThanOrEqualTo(r.done), reason: 'seed $s h $h: a needless stop in every wave played');
          expect(r.clean, 0, reason: 'seed $s h $h: no clean ◆ +5');
          if (r.lates > 0 || r.contact) hurt++;
        }
      }
      // ignore: avoid_print
      print('stop-everyone: $hurt / $plays plays with a late stop or contact');
      expect(hurt, greaterThan(plays * 0.5), reason: 'the trap leaves the live one late in most plays');
    });

    test('opening deck: keep away is right; by hand/foot/chappal = deadly (hand); dry bamboo/stick = deadly (bamboo)', () {
      final d = m5LiveWireDeal(math.Random(1));
      final a = M5LiveWireRun(d);
      expect(a.pickOpening(M5LiveWireLines.openRight.last), isNull);
      expect(a.stepDone, isTrue);
      expect(a.caught, contains(M5LiveWireLines.caughtDeck));
      for (final w in M5LiveWireLines.openHand) {
        final r = M5LiveWireRun(d);
        expect(r.pickOpening(w), M5LiveWireMistakes.handLift);
        expect(r.ended, isTrue);
      }
      for (final w in M5LiveWireLines.openStick) {
        expect(M5LiveWireRun(d).pickOpening(w), M5LiveWireMistakes.bambooPush);
      }
    });

    test('a wave: timely stop is right; late = slip; decoy = no slip; one at a time; unstopped live = deadly; unstopped decoy arrives', () {
      final d = m5LiveWireDeal(math.Random(3));
      final g = M5WireGeo.forScene(_testH, 0, d.layout);
      final r = M5LiveWireRun(d)..pickOpening(M5LiveWireLines.openRight.first);
      r.next();
      expect(r.step, M5LiveWireStep.wave);
      r.startWave(g);
      expect(r.walkers, hasLength(d.waves[0].length));
      r.tick(5000);
      final walking = [for (final w in r.walkers) if (w.state == M5WalkerState.walking) w];
      expect(walking, isNotEmpty);
      final w = walking.first;
      expect(r.pick(g.traineeHand, w.posAt(r.waveMs)), w, reason: 'the finger ends on him');
      final dir = w.posAt(r.waveMs) - g.traineeHand;
      expect(r.pick(g.traineeHand, g.traineeHand + dir / dir.distance * 50), isNotNull, reason: 'a short swipe toward him');
      final first = r.stop(w);
      expect(first.kind, isNot(M5StopKind.ignored));
      expect(r.busyUntil - r.waveMs, w.live ? M5LiveWireRun.busyMs : M5LiveWireRun.needlessBusyMs, reason: 'a needless stop keeps him busy longer');
      // Busy: a second stop at once does nothing.
      final other = r.walkers.firstWhere((x) => x != w && x.state != M5WalkerState.gone, orElse: () => w);
      if (other != w) {
        other.state = M5WalkerState.walking;
        expect(r.stop(other).kind, M5StopKind.ignored);
      }

      // Late and contact, on a fresh wave.
      final r2 = M5LiveWireRun(d)..pickOpening(M5LiveWireLines.openRight.first);
      r2.next();
      r2.startWave(g);
      final live = r2.walkers.firstWhere((x) => x.live);
      final lateAt = live.startMs + m5LateAfterMs(g, live.from, live.to, inRing: live.inRing) + 60;
      for (var ms = 0.0; ms <= lateAt; ms += 20) {
        expect(r2.tick(ms), isNull, reason: 'before he is late nobody else reaches live metal');
      }
      expect(r2.isLate(live, r2.waveMs), isTrue);
      final s = r2.stop(live);
      expect(s.kind, M5StopKind.late);
      expect(s.mistake, M5LiveWireMistakes.lateStop);
      expect(r2.slips, 1);

      final r3 = M5LiveWireRun(d)..pickOpening(M5LiveWireLines.openRight.first);
      r3.next();
      r3.startWave(g);
      M5Walker? hit;
      for (var ms = 0.0; ms < 20000 && hit == null; ms += 20) {
        hit = r3.tick(ms);
      }
      expect(hit, isNotNull);
      expect(hit!.live, isTrue);
      expect(r3.deadly, M5LiveWireMistakes.bystander);
      // Decoys reached before him are no mistake.
      expect(r3.slips, 0);
    });

    test('a decoy stop is no slip but costs (longer busy, the clean +5); the reason asks about the subtlest live stop', () {
      final d = [for (var s = 0; s < 400; s++) m5LiveWireDeal(math.Random(s))].firstWhere(
        (d) => d.waves[1].any((p) => m5WhyKindOf(p.target) == M5WhyKind.chain) && d.waves[1].any((p) => !d.layout.live(p.target)),
      );
      final g = M5WireGeo.forScene(_testH, 0, d.layout);
      final r = M5LiveWireRun(d)..pickOpening(M5LiveWireLines.openRight.first);
      r.next();
      r.startWave(g);
      for (var ms = 0.0; ms < 60000 && !r.stepDone; ms += 50) {
        expect(r.tick(ms), isNull);
        for (final x in r.walkers) {
          if (x.state == M5WalkerState.walking && x.live && r.canStop && ms - x.startMs >= 300) r.stop(x);
        }
      }
      r.next();
      r.startWave(g);
      var decoyStopped = false;
      for (var ms = 0.0; ms < 60000 && !r.stepDone; ms += 50) {
        expect(r.tick(ms), isNull);
        for (final x in r.walkers) {
          if (x.state != M5WalkerState.walking || !r.canStop || ms - x.startMs < 300) continue;
          if (x.live || !decoyStopped) {
            final k = r.stop(x).kind;
            if (!x.live) {
              expect(k, M5StopKind.decoy);
              decoyStopped = true;
            }
            break;
          }
        }
      }
      expect(r.stepDone, isTrue);
      expect(r.slips, 0, reason: 'a decoy stop is no slip');
      expect(decoyStopped, isTrue);
      expect(r.stepNeedless, 1);
      expect(r.needless, 1);
      expect(r.waveClean, isFalse, reason: 'a needless stop loses the wave its clean ◆ +5');
      expect(m5WhyKindOf(r.subtlest!), M5WhyKind.chain);
      expect(M5LiveWireLines.waveWhyQ(r.subtlest!), anyOf(M5LiveWireLines.waveWhyQ(M5Thing.bicycle), M5LiveWireLines.waveWhyQ(M5Thing.clothesline)));
      expect(r.caught, contains(M5LiveWireLines.caughtSubtle));
    });

    test('the call: written permit, test, earth first; any hands-on on a phone "line off" = deadly', () {
      final d = m5LiveWireDeal(math.Random(2));
      for (final w in M5LiveWireLines.callWrong) {
        final r = M5LiveWireRun(d)..index = 4;
        expect(r.step, M5LiveWireStep.call);
        expect(r.pickCall(w), M5LiveWireMistakes.phoneOff);
        expect(r.ended, isTrue);
      }
      final r = M5LiveWireRun(d)..index = 4;
      expect(r.pickCall(M5LiveWireLines.callRight.first), isNull);
      expect(r.caught, contains(M5LiveWireLines.caughtPhone));
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
    });

    test('the hint points outward from the trainee at nobody, and turns', () {
      const from = Offset(262, 600);
      final others = [const Offset(100, 300), const Offset(262, 250), const Offset(330, 420)];
      final dirs = <String>{};
      for (var turn = 0; turn < 8; turn++) {
        final d = m5FreeDirection(from, others, turn);
        expect(d.dy, lessThan(0.01), reason: 'outward, up the lane');
        for (final o in others) {
          expect(m5AngleBetween(d, o - from), greaterThanOrEqualTo(25 * math.pi / 180 - 1e-9), reason: 'turn $turn points at $o');
        }
        dirs.add('${d.dx.toStringAsFixed(2)},${d.dy.toStringAsFixed(2)}');
      }
      expect(dirs.length, greaterThan(2), reason: 'it turns');
    });

    test('English digits only; no পানি; every mistake has its picture; the deadly set; keys unique', () {
      final all = <String>[
        M5LiveWireLines.intro,
        ...M5LiveWireLines.steps,
        ...M5LiveWireLines.tasks,
        M5LiveWireLines.demoDone,
        ...M5LiveWireLines.calls,
        ...M5LiveWireLines.openRight,
        ...M5LiveWireLines.openWrong,
        ...M5LiveWireLines.callRight,
        ...M5LiveWireLines.callWrong,
        ...M5LiveWireLines.allWhyRight,
        ...M5LiveWireLines.myths,
        for (final t in M5Thing.values) M5LiveWireLines.waveWhyQ(t),
        for (final c in M5LiveWireLines.coworkers) ...[...c.recordedLines, ...c.right, ...c.wrong, ...c.asks],
        for (final m in M5LiveWireMistakes.all) m.textBn,
        M5LiveWireLines.allSet,
        M5LiveWireLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(RegExp('[ऀ-ॣ०-ॿ؀-ۿ]').hasMatch(l), isFalse, reason: 'clean Bangla: $l');
      }
      expect(M5LiveWireMistakes.all.where((m) => !m.deadly), [M5LiveWireMistakes.lateStop]);
      expect(M5LiveWireMistakes.all.map((m) => m.key).toSet(), hasLength(M5LiveWireMistakes.all.length));
      for (final m in M5LiveWireMistakes.all) {
        expect(m.key, startsWith('5.6/m5_live_wire_guard/'));
        expect(m.art, startsWith('assets/game/art/m5_live_wire_guard/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      final art = Directory('assets/game/art/m5_live_wire_guard').listSync().map((f) => f.path.replaceAll(r'\', '/')).toSet();
      expect(art, M5LiveWireMistakes.all.map((m) => m.art).toSet(), reason: 'no unused pictures');
      expect(m5LiveWirePacks.keys, ['do_5_6_b']);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...M5LiveWireLines.allWhyRight, ...M5LiveWireLines.myths]);
      expect(M5LiveWireLines.myths.toSet().intersection(M5LiveWireLines.allWhyRight.toSet()), isEmpty);
      for (final k in M5WhyKind.values) {
        final right = M5LiveWireLines.why[k]!;
        expectLibrary('why $k', right, M5LiveWireLines.myths);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, M5LiveWireLines.myths, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('open', [...M5LiveWireLines.openRight, ...M5LiveWireLines.openWrong]);
      expectLibrary('open', M5LiveWireLines.openRight, M5LiveWireLines.openWrong);
      expectSameLength('call', [...M5LiveWireLines.callRight, ...M5LiveWireLines.callWrong]);
      expectLibrary('call', M5LiveWireLines.callRight, M5LiveWireLines.callWrong);
      for (final c in M5LiveWireLines.coworkers) {
        expectSameLength('coworker', [...c.right, ...c.wrong]);
        expectLibrary('coworker', c.right, c.wrong);
        expect(c.asks.length, greaterThanOrEqualTo(2));
      }
    });

    test('rival lines: his exit is recorded; his two pushes are the only ones still to record', () {
      final lines = {for (final c in M5LiveWireLines.coworkers) ...c.recordedLines};
      expect(LearnVoice.resolve(M5LiveWireLines.coworkerExit, rival: true), isNotNull);
      final missing = [for (final l in lines) if (LearnVoice.resolve(l, rival: true) == null) l];
      expect(missing.toSet().difference({for (final c in M5LiveWireLines.coworkers) c.line}), isEmpty);
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
      for (var ms = 0; ms < maxMs; ms += 100) {
        if (ok()) return true;
        await t.pump(const Duration(milliseconds: 100));
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

    Future<ProviderContainer> open(WidgetTester t, int seed, M5LiveWireProbe probe) async {
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
          child: M5LiveWireGuardPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: probe),
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

    Future<void> swipe(WidgetTester t, Offset from, Offset to) async {
      await t.dragFrom(from, to - from);
      await t.pump(const Duration(milliseconds: 50));
    }

    /// The opening deck (right) and its reason.
    Future<void> opening(WidgetTester t) async {
      await pickRight(t, M5LiveWireLines.openRight);
      expect(await until(t, () => find.byKey(const ValueKey('why-deck-0')).evaluate().isNotEmpty), isTrue);
      await pump(t, 600);
      await pickRight(t, M5LiveWireLines.why[M5WhyKind.opening]!);
    }

    Future<void> demo(WidgetTester t, M5LiveWireProbe p) async {
      expect(await until(t, () => p.phase == 'demo'), isTrue, reason: 'the demo');
      await pump(t, 600);
      await swipe(t, p.traineeGlobal!, p.demoGlobal!);
      await pump(t, 400);
      expect(p.phase, 'demo', reason: 'the wave waits a moment');
    }

    /// One wave: every live walker stopped (in time, or once he is late while
    /// [lates] > 0); returns the late stops made.
    Future<int> wave(WidgetTester t, M5LiveWireProbe p, {int lates = 0}) async {
      expect(await until(t, () => p.phase == 'wave', maxMs: 15000), isTrue, reason: 'a wave starts');
      final stopped = <int>{};
      var made = 0;
      for (var ms = 0; ms < 40000 && p.phase == 'wave'; ms += 50) {
        if (find.byType(StruckOutCard).evaluate().isNotEmpty || find.byType(FreezeFrame).evaluate().isNotEmpty) break;
        if (find.text(MistakeLines.gotIt).evaluate().isNotEmpty) {
          await t.tap(find.text(MistakeLines.gotIt));
          await pump(t, 500);
          continue;
        }
        final r = p.run!;
        for (final w in r.walkers) {
          if (w.state != M5WalkerState.walking || !w.live || stopped.contains(w.id) || !r.canStop) continue;
          final ready = made < lates ? r.isLate(w, r.waveMs) : r.waveMs - w.startMs >= 300;
          if (!ready) continue;
          stopped.add(w.id);
          if (made < lates) made++;
          await swipe(t, p.traineeGlobal!, p.walkerGlobal(w)!);
          break;
        }
        await t.pump(const Duration(milliseconds: 50));
      }
      return made;
    }

    Future<void> waveReason(WidgetTester t) async {
      expect(await until(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue, reason: 'the wave reason');
      await pump(t, 600);
      await pickRight(t, M5LiveWireLines.allWhyRight);
    }

    Future<void> coworker(WidgetTester t, M5LiveWireProbe p) async {
      expect(await until(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 6000), isTrue, reason: 'he comes');
      expect(p.phase, 'between', reason: 'the next wave waits for him');
      expect(p.run!.walkers, isEmpty);
      await until(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await pump(t, 400);
      await pickRight(t, M5LiveWireLines.coworkers[p.deal!.coworkerLine].right);
      await pump(t, 600);
      expect(p.phase, isNot('wave'), reason: 'a short pause after him');
    }

    testWidgets('the guide comes first: a tap does not skip him; then the opening deck', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M5LiveWireGuardPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing);
      await waitIntro(t);
      await pump(t, 1200);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      await waitChoiceDeck(t);
      expect(onScreen(M5LiveWireLines.openRight), hasLength(1));
      expect(onScreen(M5LiveWireLines.openWrong), hasLength(2));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final p = M5LiveWireProbe();
      final c = await open(t, 5, p);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M5LiveWireLines.askOpen)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await close(t, c);
    });

    for (final after in [1, 2]) {
      testWidgets('flow (coworker after wave $after): deck, demo, 3 waves, refuse him, the call; right reasons → pass', (t) async {
        final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => m5LiveWireDeal(math.Random(s)).coworkerAfter == after);
        final p = M5LiveWireProbe();
        final c = await open(t, seed, p);
        await opening(t);
        await demo(t, p);
        for (var w = 1; w <= 3; w++) {
          expect(await wave(t, p), 0);
          expect(find.byType(MistakeCard), findsNothing, reason: 'wave $w clean');
          await waveReason(t);
          if (w == after) await coworker(t, p);
        }
        // The control room.
        expect(await until(t, () => p.phase == 'call'), isTrue);
        expect(find.byKey(const ValueKey('call-chip')), findsOneWidget);
        expect(await until(t, () => onScreen(M5LiveWireLines.callRight).isNotEmpty, maxMs: 12000), isTrue);
        await pickRight(t, M5LiveWireLines.callRight);
        expect(await until(t, () => find.byKey(const ValueKey('why-deck-4')).evaluate().isNotEmpty), isTrue);
        await pump(t, 600);
        await pickRight(t, M5LiveWireLines.why[M5WhyKind.call]!);
        expect(await until(t, () => find.byType(LevelPassPanel).evaluate().isNotEmpty, maxMs: 8000), isTrue);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.6/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.6/do/1'], greaterThan(0));
        expect(find.text(M5LiveWireLines.caughtCall), findsOneWidget);
        expect(find.text(M5LiveWireLines.caughtPhone), findsOneWidget);
        expect(t.takeException(), isNull);
        await close(t, c);
      });
    }

    testWidgets('a late stop is a slip: its card, then the same wave goes on', (t) async {
      const seed = 4;
      final p = M5LiveWireProbe();
      final c = await open(t, seed, p);
      await opening(t);
      await demo(t, p);
      expect(await until(t, () => p.phase == 'wave', maxMs: 15000), isTrue);
      final r = p.run!;
      final live = r.walkers.firstWhere((w) => w.live);
      expect(await until(t, () => r.isLate(live, r.waveMs) && r.canStop, maxMs: 15000), isTrue);
      await swipe(t, p.traineeGlobal!, p.walkerGlobal(live)!);
      await pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5LiveWireMistakes.lateStop.textBn), findsOneWidget);
      final frozenAt = r.waveMs;
      await pump(t, 1500);
      expect(r.waveMs, frozenAt, reason: 'the wave waits while the card is up');
      await t.tap(find.text(MistakeLines.gotIt));
      await pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(p.phase, 'wave');
      await wave(t, p);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5LiveWireMistakes.lateStop.key);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three late stops strike the level out', (t) async {
      // A deal where stopping every live walker only once he is late never
      // lets one through before the third.
      final seed = [for (var s = 0; s < 300; s++) s].firstWhere((s) {
        final r = _simulate(m5LiveWireDeal(math.Random(s)), _testH, late: true, maxLates: 3);
        return !r.contact && r.lates >= 3;
      });
      final d = m5LiveWireDeal(math.Random(seed));
      final p = M5LiveWireProbe();
      final c = await open(t, seed, p);
      await opening(t);
      await demo(t, p);
      var lates = 0;
      for (var w = 1; w <= 3 && lates < 3; w++) {
        lates += await wave(t, p, lates: 3 - lates);
        if (lates >= 3) break;
        await waveReason(t);
        if (w == d.coworkerAfter) await coworker(t, p);
      }
      await pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await close(t, c);
    });

    testWidgets('nobody stops a person headed to live metal: the scene freezes before contact, then the card (near-miss)', (t) async {
      final p = M5LiveWireProbe();
      final c = await open(t, 6, p);
      await opening(t);
      await demo(t, p);
      expect(await until(t, () => p.phase == 'wave', maxMs: 15000), isTrue);
      expect(await until(t, () => find.byType(FreezeFrame).evaluate().isNotEmpty, maxMs: 20000), isTrue);
      expect(find.byType(MistakeCard), findsNothing);
      expect(p.run!.deadly, M5LiveWireMistakes.bystander);
      await pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5LiveWireMistakes.bystander.key);
      expect(s.mistakes.single.deadly, isTrue);
      await close(t, c);
    });

    testWidgets('a wrong opening card (handling the wire) = deadly: freeze, then the card', (t) async {
      final p = M5LiveWireProbe();
      final c = await open(t, 2, p);
      await pickWrong(t, M5LiveWireLines.openWrong);
      await pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final key = c.read(gameSaveProvider).mistakes.single.key;
      expect(key, anyOf(M5LiveWireMistakes.handLift.key, M5LiveWireMistakes.bambooPush.key));
      await close(t, c);
    });

    testWidgets('listening to him (join the ends) = deadly: freeze, then the card', (t) async {
      final seed = [for (var s = 0; s < 200; s++) s].firstWhere((s) => m5LiveWireDeal(math.Random(s)).coworkerAfter == 1);
      final p = M5LiveWireProbe();
      final c = await open(t, seed, p);
      await opening(t);
      await demo(t, p);
      await wave(t, p);
      await waveReason(t);
      expect(await until(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 6000), isTrue);
      await until(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await pump(t, 400);
      await pickWrong(t, M5LiveWireLines.coworkers[p.deal!.coworkerLine].wrong);
      await pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5LiveWireMistakes.joinEnds.key);
      await close(t, c);
    });

    testWidgets('gesture hand: in the demo a swipe from the trainee (no sweep, no tap); three missed taps in a wave show it', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final p = M5LiveWireProbe();
      final c = await open(t, 7, p);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      // The opening deck has its own sweep; the scene's hand stays away.
      await pump(t, 9000);
      expect(scene().showing, isFalse);
      await opening(t);
      expect(await until(t, () => p.phase == 'demo'), isTrue);
      await pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the demo');
      expect(scene().debugOptions, isEmpty, reason: 'a swipe, not a sweep');
      expect(scene().debugFrame?.ripple, isNull, reason: 'no tap');
      await swipe(t, p.traineeGlobal!, p.demoGlobal!);
      expect(scene().showing, isFalse);
      expect(await until(t, () => p.phase == 'wave', maxMs: 15000), isTrue);
      // Three taps on nothing: the hand at once.
      final empty = p.traineeGlobal! + const Offset(-120, -40);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 150));
      }
      await t.pump(const Duration(milliseconds: 200));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(find.byType(MistakeCard), findsNothing);
      await close(t, c);
    });
  });
}
