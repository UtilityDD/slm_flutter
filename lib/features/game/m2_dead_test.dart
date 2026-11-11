import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'choice_deck.dart';
import 'coworker_moment.dart';
import 'do_parts.dart';
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_dead_test_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm2_dead_test_world.dart' show DeadGeo, DeadPoint, DeadSite, deadPointBn;

// Lesson 2.2 "মাল্টিমিটারের জাদু", কাজ 2 "লাইভ-ডেড-লাইভ" (Module 2). The LT
// supply is switched OFF for a job; before a hand goes on it the trainee
// proves it dead with the multimeter (dial on V~ — lesson point 2): prove the
// meter on the known live source (the proving unit), test every combination
// on the circuit (phase-to-phase and phase-to-neutral — lesson point 2), then
// prove the meter again on the known source. Only then: dead — earth it and
// work. Three rounds a play (an LT distribution box R Y B N, twice, and a
// house service board P N, once), each dealt fresh:
//   • the meter: fine, a lead cut inside from the start (lesson point 1's
//     daily check: a damaged lead), or a lead that breaks during the test —
//     either way it then reads 0.0 everywhere, and only the proofs catch it;
//     the fix is the other meter (and the proof again);
//   • the circuit: really dead; dead with a ghost voltage on one pair (pro tip
//     4: induced from a live line nearby, not real — with a load it goes to
//     zero; the reading never settles, pro tip 3); or not dead at all (a
//     phase still has voltage) — stop, report.
// Hands on: tap two terminals (red probe, black probe) or the proving unit;
// the display settles and reads; "লোড দিয়ে দেখি" re-tests the last pair with
// a load; "অন্য মিটার" swaps the meter.
//
// Deadly (Module 2 ladder row): touching a line that has voltage; touching on
// the word of an unproven meter (no successful proof before the tests, or the
// proof after them failed). Slips: a pair left untested, no proof after the
// tests, a ghost reading never checked with a load. Three slips strike out.
// Stopping on a dead line is not scored (stopping is always allowed): the
// guide says the lesson's rule and the round stays (as sky_read).
//
// The careless coworker comes once a play, right after the first 0.0 on his
// round: "মিটারে শূন্য দেখাচ্ছে, হাত দাও!" — listening = touching now.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m2_dead_test_world.dart), corner guide, ◆ on the table → "কেন …?" →
// the next round by itself. Voice: the guide's lines by device TTS; the
// coworker's push by TTS until recorded (his exit line is recorded).
//
// Flagged to the owner: "live-dead-live" (prove → test → prove) is from the
// standards (HSE GS38; NFPA 70E 120.5), not the lesson text; the proving unit
// as the known live source, and 230 V on the LT circuit, are ours (IS 12360
// for 230 V); the lesson does not name the earthing step before work (the
// 2.2 film does: "আর্থিং না করে লাইন ছোঁবেন না").

// ============================================================================
// Content
// ============================================================================

/// What is wrong with the meter this round.
enum DeadFault { none, cutLead, breaksMid }

/// What the circuit really is.
enum DeadLine { dead, ghost, live }

/// Two terminals the probes were on (order does not matter).
@immutable
class DeadPair {
  const DeadPair(this.a, this.b);
  final DeadPoint a;
  final DeadPoint b;

  bool has(DeadPoint p) => a == p || b == p;

  String get bn => '${deadPointBn(a)}–${deadPointBn(b)}';

  @override
  bool operator ==(Object other) => other is DeadPair && ((other.a == a && other.b == b) || (other.a == b && other.b == a));

  @override
  int get hashCode => a.index < b.index ? Object.hash(a, b) : Object.hash(b, a);

  @override
  String toString() => bn;
}

/// Every combination the lesson measures: phase-to-phase and phase-to-neutral.
List<DeadPair> deadPairs(DeadSite s) => s == DeadSite.threePhase
    ? const [
        DeadPair(DeadPoint.r, DeadPoint.y),
        DeadPair(DeadPoint.y, DeadPoint.b),
        DeadPair(DeadPoint.b, DeadPoint.r),
        DeadPair(DeadPoint.r, DeadPoint.n),
        DeadPair(DeadPoint.y, DeadPoint.n),
        DeadPair(DeadPoint.b, DeadPoint.n),
      ]
    : const [DeadPair(DeadPoint.p, DeadPoint.n)];

/// The known live source reads this on a good meter (V~).
const kProverVolts = 230;

/// A phase still alive reads this (V~).
const kLiveVolts = 230;

@immutable
class DeadCase {
  const DeadCase({
    required this.id,
    required this.site,
    required this.fault,
    required this.line,
    this.livePoint,
    this.ghostPair,
    this.ghostVolts = 0,
    this.breakAfter = 2,
  });

  final String id;
  final DeadSite site;
  final DeadFault fault;
  final DeadLine line;

  /// The phase that still has voltage ([DeadLine.live]).
  final DeadPoint? livePoint;

  /// The pair that shows the ghost voltage ([DeadLine.ghost]).
  final DeadPair? ghostPair;
  final int ghostVolts;

  /// [DeadFault.breaksMid]: the lead breaks after this many circuit tests.
  final int breakAfter;

  List<DeadPair> get pairs => deadPairs(site);
  bool get live => line == DeadLine.live;

  /// What a good meter reads across [p] (no load).
  int truth(DeadPair p) {
    if (live && p.has(livePoint!)) return kLiveVolts;
    if (line == DeadLine.ghost && p == ghostPair) return ghostVolts;
    return 0;
  }

  /// With a load: the ghost goes to zero, a real voltage stays.
  int truthLoaded(DeadPair p) => live && p.has(livePoint!) ? kLiveVolts : 0;
}

abstract final class DeadLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const title = 'লাইভ-ডেড-লাইভ';
  static const intro = 'সুইচ বন্ধ, কাজ শুরু হবে। কিন্তু হাত দেওয়ার আগে মিটারে প্রমাণ — লাইন সত্যিই ডেড তো?';
  static const rounds = ['ক', 'খ', 'গ'];
  static const ask = 'লাইনটা কি সত্যিই ডেড? মিটারে প্রমাণ করুন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'বক্স আর মিটার';
  static const swap = 'অন্য মিটার';
  static const load = 'লোড দিয়ে দেখি';
  static const stop = 'কাজ বন্ধ — রিপোর্ট';
  static const touch = 'ডেড — আর্থ দিয়ে কাজ';
  static const prover = 'PROVING UNIT';
  static const proverShort = 'প্রুভিং';
  static const unit = 'V~';
  static const settling = '- - -';
  static const withLoad = 'লোড';
  static String volts(int v) => enDigits(v == 0 ? '0.0' : '$v');

  static const stampTouch = 'আর্থ দিয়ে কাজ শুরু';
  static const stampStop = 'কাজ বন্ধ, রিপোর্ট';

  // The reasons: the right ones fit what this round was; the wrong ones are
  // field excuses and myths (to touch) or bad motives (to stop). 35–42
  // letters each.
  static const whyTouch = 'কেন লাইন ডেড ধরলেন?';
  static const whyStop = 'কেন কাজ বন্ধ করলেন?';
  static const deadWhy = ['আগে-পরে মিটার প্রমাণিত, সব জোড়ায় শূন্য', 'প্রমাণ, সব জোড়ায় টেস্ট, আবার প্রমাণ হলো'];
  static const ghostWhy = 'ভূতুড়ে ভোল্টেজ লোড দিতেই শূন্য হয়ে গেল';
  static const touchMyths = [
    'সুইচ তো বন্ধ করা আছে, তাই লাইন ডেড হবেই',
    'একবার শূন্য দেখেছি, ওতেই বোঝা গেছে সব',
    'মিটার নতুন কেনা, ওটা কখনো ভুল দেখায় না',
    'সাথী বলল লাইন বন্ধ, তাই আর কিছু ভাবিনি',
    'তাড়া আছে, তাই একটা জোড়া দেখেই নিলাম',
    'অল্প ভোল্টেজ দেখালে ও সবসময় ভূতুড়েই হয়',
  ];
  static const liveWhy = ['প্রমাণিত মিটারে ভোল্টেজ, লোডেও কমেনি', 'সুইচ বন্ধ হলেও মিটার বলছে লাইনে ভোল্টেজ', 'ভোল্টেজ স্থির, লোডেও শূন্য হলো না — আসল'];
  static const stopExcuses = [
    'মিটারের ব্যাটারি বাঁচাতে কাজ থামিয়ে দিলাম',
    'আজ মন ভালো নেই, তাই কাজটা বন্ধ রাখলাম',
    'সুপারভাইজার আসেননি, তাই কাজ থামালাম',
    'রিডিং দেখার আগেই বুঝেছিলাম, তাই থামলাম',
    'চা খাওয়ার সময় হয়ে গেছে, তাই থামালাম',
  ];

  static List<String> whyRight(DeadCase c) => c.live ? liveWhy : (c.line == DeadLine.ghost ? [...deadWhy, ghostWhy] : deadWhy);
  static List<String> whyWrong(DeadCase c) => c.live ? stopExcuses : touchMyths;

  /// A stop on a dead line: not scored (stopping is always allowed); the
  /// guide says the lesson's rule and the round stays.
  static const needlessDead = 'থামা আপনার অধিকার। তবে প্রমাণিত মিটারে সব জোড়ায় শূন্য — তবেই লাইন ডেড।';
  static const needlessGhost = 'থামা আপনার অধিকার। তবে ভূতুড়ে ভোল্টেজ আসল নয় — লোড দিলে শূন্য হয়ে যায়।';

  /// The careless coworker: one zero is enough for him.
  static const coworker = CoworkerScript(
    line: 'মিটারে শূন্য দেখাচ্ছে, হাত দাও! আর মাপার কী আছে?',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: ['না, সব জোড়া মেপে আবার প্রমাণ করব', 'না, আগে-পরে প্রমাণ ছাড়া শূন্য মানি না', 'একটা শূন্যে হবে না, পুরো টেস্ট আগে'],
    wrong: ['ঠিক, শূন্য মানেই লাইন ডেড, হাত দিই', 'আচ্ছা, বাকি জোড়া মাপার দরকার নেই', 'ঠিক আছে, মিটার তো ঠিকই আছে নিশ্চয়ই', 'হ্যাঁ, সুইচ বন্ধ, তাই আর ভয় নেই', 'তাড়া আছে, এখনই কাজ শুরু করে দিই'],
    asks: ['ও বলছে হাত দিতে। আপনি কী করবেন?', 'একটা শূন্যে ভরসা করবেন?', 'হাত দেবেন, না টেস্ট শেষ করবেন?'],
  );

  static const callHeld = 'ঠিক! একটা শূন্যে ভরসা নয় — পুরো টেস্ট।';
  static const allSet = 'লাইভ-ডেড-লাইভ শিখে গেছেন — প্রমাণ, সব জোড়ায় টেস্ট, আবার প্রমাণ।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — মিটার প্রমাণ, সব জোড়া, আবার প্রমাণ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtProve = 'আগে-পরে মিটার প্রমাণ';
  static const caughtPairs = 'সব জোড়ায় টেস্ট';
  static const caughtBadMeter = 'খারাপ মিটার ধরে বদলেছেন';
  static const caughtGhost = 'ভূতুড়ে ভোল্টেজ লোডে যাচাই';
  static const caughtLive = 'ভোল্টেজ দেখে কাজ বন্ধ';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class DeadMistakes {
  static const _dir = 'assets/game/art/m2_dead_test';

  static const touchLive = DoMistake(
    key: '2.2/dead/touch-live',
    textBn: 'লাইনে ভোল্টেজ ছিল! সুইচ বন্ধ মানেই লাইন ডেড নয় — প্রমাণিত মিটারে সব জোড়ায় শূন্য না পেলে হাত নয়।',
    art: '$_dir/touch_live.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const unproven = DoMistake(
    key: '2.2/dead/unproven-meter',
    textBn: 'প্রমাণ না করা মিটারের শূন্যে হাত দিলেন। কাটা লিড বা বিগড়ানো মিটারও শূন্য দেখায় — আগে জানা লাইভ উৎসে প্রমাণ, তারপর টেস্ট, শেষে আবার প্রমাণ।',
    art: '$_dir/unproven.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const missedPair = DoMistake(
    key: '2.2/dead/missed-pair',
    textBn: 'সব জোড়া মাপা হয়নি। ফেজ-ফেজ আর ফেজ-নিউট্রাল — প্রতিটা জোড়ায় শূন্য দেখে তবেই লাইন ডেড।',
    art: '$_dir/missed_pair.svg',
    lessonPoint: 1,
  );
  static const noReprove = DoMistake(
    key: '2.2/dead/no-reprove',
    textBn: 'টেস্টের পরে মিটার আবার প্রমাণ করেননি। মাঝপথে লিড ছিঁড়লে শূন্যটা মিথ্যে — শেষে আবার জানা লাইভ উৎসে দেখুন।',
    art: '$_dir/no_reprove.svg',
    lessonPoint: 0,
  );

  /// Pro tips 3–4 (not a lesson point: "পাঠে দেখুন" opens the lesson start).
  static const ghostUnchecked = DoMistake(
    key: '2.2/dead/ghost-unchecked',
    textBn: 'রিডিং স্থির হয়নি, অথচ যাচাই না করেই হাত দিলেন। ভূতুড়ে ভোল্টেজ লোড দিলে শূন্য হয়ে যায় — না হলে ওটা আসল ভোল্টেজ।',
    art: '$_dir/ghost.svg',
  );

  static const all = [touchLive, unproven, missedPair, noReprove, ghostUnchecked];
}

@immutable
class DeadDeal {
  const DeadDeal({required this.cases, required this.callAt});
  final List<DeadCase> cases;

  /// The round the careless coworker comes on (one that can read 0.0).
  final int callAt;
}

/// Three rounds: two LT boxes and one house board in a fresh order; one is
/// dead, one has a ghost voltage, one still has voltage; one meter has a cut
/// lead from the start, and (half the plays) another meter's lead breaks
/// during the test.
DeadDeal dealDead(math.Random rng) {
  T pick<T>(List<T> l) => l[rng.nextInt(l.length)];
  final sites = [DeadSite.threePhase, DeadSite.threePhase, DeadSite.single]..shuffle(rng);
  final lines = [DeadLine.dead, DeadLine.ghost, DeadLine.live]..shuffle(rng);
  final faults = [DeadFault.cutLead, rng.nextBool() ? DeadFault.breaksMid : DeadFault.none, DeadFault.none]..shuffle(rng);
  final cases = <DeadCase>[
    for (var i = 0; i < 3; i++)
      () {
        final s = sites[i];
        final three = s == DeadSite.threePhase;
        final phase = three ? pick(const [DeadPoint.r, DeadPoint.y, DeadPoint.b]) : DeadPoint.p;
        return DeadCase(
          id: 'd$i',
          site: s,
          fault: faults[i],
          line: lines[i],
          livePoint: lines[i] == DeadLine.live ? phase : null,
          ghostPair: lines[i] == DeadLine.ghost ? DeadPair(phase, DeadPoint.n) : null,
          ghostVolts: lines[i] == DeadLine.ghost ? pick(const [18, 24, 31, 38, 44]) : 0,
          breakAfter: three ? 2 + rng.nextInt(3) : 1,
        );
      }(),
  ];
  // He needs a 0.0 on the circuit: never the house board that is live.
  final can = [
    for (final (i, c) in cases.indexed)
      if (!(c.site == DeadSite.single && c.live)) i,
  ];
  return DeadDeal(cases: cases, callAt: can[rng.nextInt(can.length)]);
}

/// What the meter said, for the display and the log.
@immutable
class DeadReading {
  const DeadReading({required this.whereBn, required this.volts, this.unsteady = false, this.loaded = false});
  final String whereBn;
  final int volts;

  /// A ghost: the digits never settle.
  final bool unsteady;
  final bool loaded;
}

/// The play state (pure logic).
class DeadRun {
  DeadRun(this.deal) {
    _startRound();
  }

  final DeadDeal deal;
  int index = 0;

  /// The meter in hand reads true.
  var meterOk = true;
  var swapped = false;

  /// A good proof on the known source since the meter was taken (or since a
  /// failed one).
  var proven = false;

  /// A proof failed and the meter was not swapped since (the cut shows).
  var meterSuspect = false;

  /// Circuit pairs tested after a good proof (with this meter).
  final Set<DeadPair> valid = {};

  /// Proven again after the last circuit test, with every pair tested.
  var reproven = false;
  var ghostSeen = false;
  var ghostChecked = false;
  var loadUsed = false;
  int _circuitTests = 0;
  DeadPair? lastPair;

  var shown = false;
  int slips = 0;
  int needless = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  DeadCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;

  /// The +5: a bad meter caught and swapped, or a reading checked with a load.
  bool get thorough => (swapped && current.fault != DeadFault.none) || ghostChecked || (current.live && loadUsed);

  void _startRound() {
    meterOk = current.fault != DeadFault.cutLead;
    swapped = false;
    proven = false;
    meterSuspect = false;
    valid.clear();
    reproven = false;
    ghostSeen = false;
    ghostChecked = false;
    loadUsed = false;
    _circuitTests = 0;
    lastPair = null;
    shown = false;
  }

  /// The probes on the known live source.
  DeadReading? prove() {
    if (!_open) return null;
    if (meterOk) {
      proven = true;
      meterSuspect = false;
      if (valid.containsAll(current.pairs)) reproven = true;
      return const DeadReading(whereBn: DeadLines.prover, volts: kProverVolts);
    }
    // The meter lies: everything it said since is worth nothing.
    proven = false;
    meterSuspect = true;
    valid.clear();
    reproven = false;
    return const DeadReading(whereBn: DeadLines.prover, volts: 0);
  }

  /// The probes across [p] on the circuit.
  DeadReading? test(DeadPair p) {
    if (!_open) return null;
    final c = current;
    final v = meterOk ? c.truth(p) : 0;
    if (proven) valid.add(p);
    reproven = false;
    lastPair = p;
    final ghost = meterOk && c.line == DeadLine.ghost && p == c.ghostPair;
    if (ghost) ghostSeen = true;
    _circuitTests++;
    if (c.fault == DeadFault.breaksMid && !swapped && meterOk && _circuitTests >= c.breakAfter) meterOk = false;
    return DeadReading(whereBn: p.bn, volts: v, unsteady: ghost);
  }

  /// The last pair again, with a load across it.
  DeadReading? loadTest() {
    final p = lastPair;
    if (!_open || p == null) return null;
    loadUsed = true;
    final c = current;
    if (meterOk && c.line == DeadLine.ghost && p == c.ghostPair) ghostChecked = true;
    return DeadReading(whereBn: p.bn, volts: meterOk ? c.truthLoaded(p) : 0, loaded: true);
  }

  /// The other meter from the bag (good): it has to be proven again.
  void swap() {
    if (!_open) return;
    swapped = true;
    meterOk = true;
    proven = false;
    meterSuspect = false;
    valid.clear();
    reproven = false;
    lastPair = null;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Touch (dead — earth it and work) or stop and report. A stop on a dead
  /// line is not scored: no mistake, [shown] stays false (see [needless]).
  DoMistake? decide({required bool touch}) {
    if (!_open) return null;
    final c = current;
    if (!touch) {
      if (!c.live) {
        needless++;
        return null;
      }
      shown = true;
      _tag(DeadLines.caughtLive);
      return null;
    }
    shown = true;
    if (c.live) return deadly = DeadMistakes.touchLive;
    if (!proven || valid.isEmpty) return deadly = DeadMistakes.unproven;
    if (!valid.containsAll(c.pairs)) {
      slips++;
      return DeadMistakes.missedPair;
    }
    if (!reproven) {
      slips++;
      return DeadMistakes.noReprove;
    }
    if (c.line == DeadLine.ghost && !ghostChecked) {
      slips++;
      return DeadMistakes.ghostUnchecked;
    }
    _tag(DeadLines.caughtProve);
    _tag(DeadLines.caughtPairs);
    if (swapped && c.fault != DeadFault.none) _tag(DeadLines.caughtBadMeter);
    if (c.line == DeadLine.ghost) _tag(DeadLines.caughtGhost);
    return null;
  }

  void next() {
    index++;
    if (!done) _startRound();
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A thorough LT
/// round (ms): prove 1500 tap + 800 settle + 1500 read; six pairs × (2 taps
/// 3000 + 800 + 1000 read); prove again 3800; decide 1500; reason ~8200 ≈
/// 45600. The house board ≈ 21000. A bad meter (prove, swap, prove) +5000, the
/// ghost's load test +3000, the coworker ~9600: ≈ 129800; 85 % ≈ 110 s.
const kDeadQuickMs = 110000;

@immutable
class M2DeadTestPack {
  const M2DeadTestPack({required this.id, required this.titleBn, this.quickMs = kDeadQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2DeadTestPacks = {
  'do_2_2_b': M2DeadTestPack(id: 'do_2_2_b', titleBn: DeadLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M2DeadTestPage extends StatefulWidget {
  const M2DeadTestPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2DeadTestPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2DeadTestPage> createState() => _M2DeadTestPageState();
}

class _M2DeadTestPageState extends State<M2DeadTestPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DeadRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _DeadRunPage extends ConsumerStatefulWidget {
  const _DeadRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2DeadTestPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DeadRunPage> createState() => _DeadRunPageState();
}

class _DeadRunPageState extends ConsumerState<_DeadRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final DeadRun _run = DeadRun(dealDead(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  bool? _touched;
  var _coworkerArmed = false;

  // The probes: on terminals (red first, then black) or on the proving unit.
  DeadPoint? _red;
  DeadPoint? _black;
  var _onProver = false;

  /// The display: settling ("- - -") or the last reading.
  var _settling = false;
  DeadReading? _reading;
  int _readN = 0;
  final List<DeadReading> _log = [];
  Timer? _settleTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _settleTimer?.cancel();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk}) async {
    if (line.trim().isEmpty || !mounted) return;
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted);
  }

  Future<void> _sayChain(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    final chain = ++_chain;
    for (final l in lines) {
      if (!mounted || chain != _chain) return;
      await _say(l, mood: mood);
    }
  }

  void _hush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_run.shown;

  void _startRound() {
    _settleTimer?.cancel();
    setState(() {
      _touched = null;
      _red = null;
      _black = null;
      _onProver = false;
      _settling = false;
      _reading = null;
      _log.clear();
      _wake++;
    });
    unawaited(_sayChain([DeadLines.ask]));
  }

  // --- hands on -----------------------------------------------------------------------
  void _tapScene(Offset p, DeadGeo geo) {
    if (!_canPlay || _settling) return;
    final site = _run.current.site;
    if (geo.proverHit.contains(p)) {
      HapticFeedback.selectionClick();
      _cue('sounds/intro/tick.ogg', volume: 0.5);
      setState(() {
        _red = null;
        _black = null;
        _onProver = true;
        _wake++;
      });
      _settle(() => _run.prove());
      return;
    }
    DeadPoint? hit;
    for (final t in geo.points(site)) {
      if (geo.terminalHit(site, t).contains(p)) hit = t;
    }
    if (hit == null) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    final first = _red;
    if (_onProver || first == null || _black != null) {
      // A new test: the red probe goes on first.
      setState(() {
        _onProver = false;
        _red = hit;
        _black = null;
        _reading = null;
        _wake++;
      });
      return;
    }
    if (first == hit) {
      setState(() => _red = null);
      return;
    }
    setState(() {
      _black = hit;
      _wake++;
    });
    final pair = DeadPair(first, hit);
    _settle(() => _run.test(pair));
  }

  /// The display settles for a moment, then reads.
  void _settle(DeadReading? Function() read) {
    _settleTimer?.cancel();
    setState(() {
      _settling = true;
      _reading = null;
    });
    _settleTimer = Timer(Duration(milliseconds: _quiet ? 300 : 800), () {
      if (!mounted) return;
      final r = read();
      setState(() {
        _settling = false;
        if (r == null) return;
        _reading = r;
        _readN++;
        _log.insert(0, r);
        if (_log.length > 7) _log.removeLast();
        _wake++;
      });
      if (r == null) return;
      _cue('sounds/quiz_select.wav', volume: 0.35);
      // His moment: the first 0.0 on the circuit on his round.
      if (!_coworkerArmed && _run.index == _run.deal.callAt && r.volts == 0 && r.whereBn != DeadLines.prover) {
        _coworkerArmed = true;
        scheduleCoworker();
      }
    });
  }

  void _loadTest() {
    if (!_canPlay || _settling || _run.lastPair == null) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.wav', volume: 0.35);
    final p = _run.lastPair!;
    setState(() {
      _onProver = false;
      _red = p.a;
      _black = p.b;
    });
    _settle(() => _run.loadTest());
  }

  void _swap() {
    if (!_canPlay || _settling) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    _run.swap();
    setState(() {
      _red = null;
      _black = null;
      _onProver = false;
      _reading = null;
      _log.clear();
      _wake++;
    });
  }

  // --- the decision ----------------------------------------------------------------
  Future<void> _decide(bool touch, Offset origin) async {
    if (!_canPlay || _settling) return;
    await _commit(touch, origin);
  }

  Future<void> _commit(bool touch, Offset origin) async {
    _hush();
    _busy = false;
    _settleTimer?.cancel();
    _settling = false;
    final m = _run.decide(touch: touch);
    if (m == null && !_run.shown) {
      HapticFeedback.selectionClick();
      _cue('sounds/intro/click.ogg', volume: 0.5);
      setState(() => _wake++);
      unawaited(_sayChain([_run.ghostSeen ? DeadLines.needlessGhost : DeadLines.needlessDead]));
      return;
    }
    HapticFeedback.mediumImpact();
    if (m == null) {
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      setState(() {
        _touched = touch;
        _wake++;
      });
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final c = _run.current;
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(DeadLines.whyRight(c), DeadLines.whyWrong(c), widget.rng),
        question: touch ? DeadLines.whyTouch : DeadLines.whyStop,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    setState(() {});
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
  }

  // --- the shared success beat (ReasonTable) ---------------------------------
  @override
  bool get reasonMuted => _muted;
  @override
  bool get reasonEnded => _ended;
  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void reasonHush() => _hush();
  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) => _levelDelta(delta, origin, mood: mood);
  @override
  void onReasonPaid() {
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => DeadLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.shown) return null;
    if (_intro || _busy || _card != null || reasonOpen || _settling) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: a hand on the line now.
      await _commit(true, origin);
      return;
    }
    if (!_run.caught.contains(DeadLines.caughtCall)) _run.caught.add(DeadLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([DeadLines.callHeld]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? DeadLines.tapWhy[_nudgeN++ % DeadLines.tapWhy.length]
            : _nudge.next(DeadLines.ask);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('dead/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A hand on the box: the site freezes grey and the arc flashes at the
  /// terminals in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.wav', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _touched = true;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('dead/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? DeadLines.deadlyWord : DeadLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        _next();
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood}) async {
    final next = math.max(0, _runScore + delta);
    final real = next - _runScore;
    if (real == 0 || !mounted) return;
    setState(() => _runScore = next);
    await BeatFx.levelDelta(ref, real, mood: mood, originGlobal: origin, muted: _muted);
  }

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    final save = ref.read(gameSaveProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final centre = Offset(size.width / 2, size.height * 0.45);
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? DeadLines.fail : (_quickBonus ? DeadLines.quick : DeadLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (deathPending) {
      if (_popped) return;
      _popped = true;
      await dieAndLeave();
      return;
    }
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_touched == false) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  Offset _zapAt(DeadGeo geo) {
    final c = _run.current;
    if (c.live) return geo.terminal(c.site, c.livePoint!);
    final pts = geo.points(c.site);
    return geo.terminal(c.site, pts[pts.length ~/ 2 - (pts.length > 2 ? 1 : 0)]);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = DeadGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final tb = geo.trainee;
    final hand = tb.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final red = _onProver ? geo.proverSockets[0] : (_red == null ? null : geo.terminal(c.site, _red!));
    final black = _onProver ? geo.proverSockets[1] : (_black == null ? null : geo.terminal(c.site, _black!));
    final box = geo.box(c.site);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: DeadWorldPainter(
                      geo: geo,
                      site: c.site,
                      lit: {?_red, ?_black},
                      proverLit: _onProver,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              Positioned.fill(
                key: const ValueKey('leads'),
                child: IgnorePointer(
                  child: CustomPaint(painter: DeadLeadsPainter(hand: hand, red: red, black: black, broken: _run.meterSuspect)),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_touched != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: box.left + 10,
          width: box.width - 20,
          top: box.top + 6,
          child: IgnorePointer(child: _StampPop(text: _touched! ? DeadLines.stampTouch : DeadLines.stampStop, quiet: quiet)),
        ),
      // Tap a terminal or the proving unit: the probes go there.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: DeadLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: DeadZapPainter(at: _zapAt(geo), v: v)),
            ),
          ),
        ),
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: ScoreFlyHost(
          scoreKey: _scoreKey,
          child: FullSceneFrame(
            ctx: widget.ctx,
            titleBn: widget.pack.titleBn,
            scoreKey: _scoreKey,
            levelScore: _runScore,
            muted: _muted,
            onClose: () => unawaited(_leave()),
            onToggleMute: () {
              unawaited(MascotSpeechLibrary.stop());
              setState(() => _muted = !_muted);
            },
            progress: DoProgress(
              labels: DeadLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && !_run.done && !deckUp)
                Positioned(
                  key: const ValueKey('hud-meter'),
                  left: 10,
                  bottom: pad.bottom + (handsOn ? 150 : 12),
                  child: _MeterCard(
                    reading: _reading,
                    readN: _readN,
                    settling: _settling,
                    log: _log,
                    quiet: quiet,
                  ),
                ),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 10,
                  bottom: pad.bottom + 72,
                  child: Row(
                    children: [
                      _ToolButton(icon: Icons.swap_horiz_rounded, label: DeadLines.swap, enabled: _canPlay && !_settling, onTap: _swap),
                      const SizedBox(width: 6),
                      _ToolButton(icon: Icons.lightbulb_outline_rounded, label: DeadLines.load, enabled: _canPlay && !_settling && _run.lastPair != null, onTap: _loadTest),
                    ],
                  ),
                ),
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(child: DoBigButton(label: DeadLines.stop, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
                      const SizedBox(width: 10),
                      Expanded(child: DoBigButton(label: DeadLines.touch, filled: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
                    ],
                  ),
                ),
              ],
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: () {
                    _hush();
                    unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
                  },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.electric,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_freeze && _card == null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: MediaQuery.disableAnimationsOf(context) ? 300 : 2400,
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: DeadLines.intro,
                  alarm: 'sounds/learn/spark.wav',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),
              if (_mark != null)
                Positioned.fill(
                  key: const ValueKey('result'),
                  child: ColoredBox(
                    color: const Color(0xB3050A16),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _run.passed
                            ? LevelPassPanel(
                                mark: _mark!,
                                levelScore: _runScore,
                                totalDelta: _totalDelta,
                                ms: _clock.elapsedMilliseconds,
                                caughtBn: _run.caught,
                                quickBonus: _quickBonus,
                                stars: _stars,
                                onNext: () => _popOnce(true),
                                onRetry: () => widget.onRetry(_muted),
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Pieces
// ============================================================================

/// The multimeter in his hand, close up: the display (dial on V~), where the
/// probes are, and his last readings.
class _MeterCard extends StatelessWidget {
  const _MeterCard({required this.reading, required this.readN, required this.settling, required this.log, required this.quiet});
  final DeadReading? reading;
  final int readN;
  final bool settling;
  final List<DeadReading> log;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final where = settling ? '' : (r == null ? '' : (r.loaded ? '${r.whereBn} · ${DeadLines.withLoad}' : r.whereBn));
    return IgnorePointer(
      child: Container(
        width: 176,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2B21B), Color(0xFFD08A0E)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A2500), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: const Color(0xFFB9C8A6), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF2B2416), width: 1.5)),
              child: Row(
                children: [
                  // Where the probes are, small in the display's corner.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 62),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(where, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
                    ),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: settling
                        ? const Text(DeadLines.settling, textAlign: TextAlign.right, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E2A1A)))
                        : r == null
                            ? const SizedBox.shrink()
                            : r.unsteady
                                ? _GhostDigits(key: ValueKey('ghost-$readN'), volts: r.volts, quiet: quiet)
                                : Text(DeadLines.volts(r.volts),
                                    key: const ValueKey('meter-value'),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1E2A1A))),
                  ),
                  ),
                  const SizedBox(width: 4),
                  const Text(DeadLines.unit, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E2A1A))),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                // The dial, on V~.
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22262B)),
                  alignment: Alignment.topCenter,
                  child: Container(width: 3, height: 9, color: const Color(0xFFF2F0E8)),
                ),
                const SizedBox(width: 6),
                const Text(DeadLines.unit, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF2B2416))),
              ],
            ),
            if (log.length > 1) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 3,
                children: [
                  for (final (i, l) in log.indexed.skip(1).take(6))
                    Container(
                      key: ValueKey('log-$i'),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0x552B2416), borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        '${l.whereBn == DeadLines.prover ? DeadLines.proverShort : l.whereBn} ${l.unsteady ? '~' : ''}${DeadLines.volts(l.volts)}',
                        style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFFFF3C4)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A ghost voltage on the display: the digits wander for a few seconds and
/// never settle (pro tip 3–4), then hold (an idle screen draws nothing).
class _GhostDigits extends StatefulWidget {
  const _GhostDigits({super.key, required this.volts, required this.quiet});
  final int volts;
  final bool quiet;

  @override
  State<_GhostDigits> createState() => _GhostDigitsState();
}

class _GhostDigitsState extends State<_GhostDigits> {
  Timer? _timer;
  int _n = 0;
  late int _v = widget.volts;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    if (widget.quiet) return;
    _timer = Timer.periodic(const Duration(milliseconds: 380), (t) {
      if (!mounted || ++_n > 12) {
        t.cancel();
        return;
      }
      setState(() => _v = math.max(3, widget.volts + _rng.nextInt(9) - 4));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(DeadLines.volts(_v),
      key: const ValueKey('meter-value'), textAlign: TextAlign.right, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1E2A1A)));
}

/// A hands-on tool: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = enabled ? SlmColors.gold300 : const Color(0xFF6B7380);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.08, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
