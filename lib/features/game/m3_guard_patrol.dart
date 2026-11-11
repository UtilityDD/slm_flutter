import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'm3_guard_patrol_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_guard_patrol_world.dart'
    show M3GuardPatrolCrossing, M3GuardPatrolFault, M3GuardPatrolGeo, M3GuardPatrolSpot, m3GuardPatrolIsEarth;

// Lesson 3.9 "গার্ড ওয়্যার ও ক্রেডল গার্ডিং", কাজ 1 "জালের পাহারা" (Module 3).
// Line patrol at the crossings (lesson point 1's daily check: at the crossing
// points, is the guard intact — any wire snapped or sagging?). Three
// crossings a play — a road, a railway and a telecom line (lesson point 1), in
// a fresh order — each with an 11 kV-style line over it on two poles, the
// cradle guard under the conductors (point 2: GI net, earthed at every pole).
// Each crossing is dealt 0–2 faults from lesson point 4 and the pro tips:
//   • the earth lead stolen (cut, its pipe empty) — point 4 "দুর্বল আর্থিং";
//   • the earth lead outside its pipe (pro tip 4: run it through a pipe
//     against theft);
//   • rust on the GI wire (points 3–4);
//   • a guard wire snapped, its end hanging down (point 4, myth 2);
//   • the guard sagging (point 4);
//   • the live conductor down too close above the guard (pro tip 1: the
//     vertical clearance).
// Hands on: tap a spot (the earth at either pole, or a third of the span) to
// hang a red tag on it (tap again to take it off), then "রিপোর্ট পাঠাই" — or,
// with no tag, "সব ঠিক আছে". A fault left untagged = a slip. A tag on a
// sound spot is not scored: the guide says one tag is wrong and the round
// stays.
//
// Deadly (the myth): touching the guard bare-handed. The careless coworker
// comes once a play, on the crossing with the snapped wire hanging down:
// "গার্ডের তারে কারেন্ট নেই, হাত দিয়ে টেনে দেখো!" — listening = the trainee
// grabs the hanging wire bare-handed. Always deadly (safety tip of point 4:
// treat the guard as live); the card says so, and when that crossing's earth
// was stolen it says that too.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m3_guard_patrol_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next crossing by itself. Voice: the guide's lines by device TTS; the
// coworker's push by TTS until recorded (his exit line is recorded).
//
// Flagged to the owner: no minimum vertical clearance or ground clearance
// figure is used (the lesson gives the ground clearance 5.8 m LT / 6.1 m HT
// only; it is not measured here); what a patroller does about a hanging guard
// wire beyond reporting it (keeping people away, traffic control) is not in
// the lesson and is left out; the 11 kV look of the line is ours.

// ============================================================================
// Content
// ============================================================================

typedef _Spot = M3GuardPatrolSpot;
typedef _Fault = M3GuardPatrolFault;

@immutable
class M3GuardPatrolCase {
  const M3GuardPatrolCase({required this.id, required this.crossing, required this.faults});

  final String id;
  final M3GuardPatrolCrossing crossing;

  /// Where each fault is (at most one per spot).
  final Map<M3GuardPatrolSpot, M3GuardPatrolFault> faults;

  bool get healthy => faults.isEmpty;
  bool has(M3GuardPatrolFault f) => faults.containsValue(f);

  /// The spot of [f], if this crossing has it.
  M3GuardPatrolSpot? spotOf(M3GuardPatrolFault f) {
    for (final e in faults.entries) {
      if (e.value == f) return e.key;
    }
    return null;
  }
}

abstract final class M3GuardPatrolLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const title = 'জালের পাহারা';
  static const intro = 'ক্রসিং-এর সুরক্ষা জাল ঠিক আছে তো? পাহারায় চলুন!';
  static const rounds = ['ক', 'খ', 'গ'];
  static const ask = 'জাল আর আর্থ দেখুন — কোথাও ত্রুটি?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'ক্রসিং-এর গার্ডিং';
  static const report = 'রিপোর্ট পাঠাই';
  static const allOk = 'সব ঠিক আছে';
  static const stampReport = 'রিপোর্ট গেল';
  static const stampOk = 'ক্রসিং ঠিক আছে';

  static String crossingBn(M3GuardPatrolCrossing c) => switch (c) {
        M3GuardPatrolCrossing.road => 'রাস্তা',
        M3GuardPatrolCrossing.rail => 'রেললাইন',
        M3GuardPatrolCrossing.telecom => 'টেলিকম লাইন',
      };

  // The reasons: the right ones fit what this crossing had; the wrong ones are
  // bad motives (to report) or myths (to pass it as fine). 33–43 letters.
  static const whyReport = 'কেন রিপোর্ট করলেন?';
  static const whyOk = 'কেন সব ঠিক বললেন?';
  static const faultWhy = {
    M3GuardPatrolFault.earthGone: ['আর্থ না থাকলে জালটাই লাইভ হয়ে যেতে পারে', 'আর্থ চুরি গেলে গার্ডিং আর কোনো কাজ করে না'],
    M3GuardPatrolFault.earthBare: ['পাইপের বাইরের আর্থ তার সহজে চুরি হয়ে যায়', 'আর্থ তার পাইপে না থাকলে চোরের হাতে যায়'],
    M3GuardPatrolFault.rust: ['মরিচা ধরা জি আই তার দুর্বল হয়ে ছিঁড়ে যায়', 'গ্যালভানাইজিং নষ্ট হলে জালের তার দুর্বল হয়'],
    M3GuardPatrolFault.broken: ['একটা ছেঁড়া তারেও পুরো জালের শক্তি কমে যায়', 'ছেঁড়া তার ঝুলে পড়ে নিজেই বিপদ ঘটাতে পারে'],
    M3GuardPatrolFault.sag: ['ঝুলে পড়া জাল বাতাসে লাইভ তার ছুঁতে পারে', 'আলগা জাল লাইভ তার আর জালের দূরত্ব কমায়'],
    M3GuardPatrolFault.gap: ['লাইভ তার আর জালের দূরত্ব কমলে আর্ক হতে পারে', 'উল্লম্ব দূরত্ব কম হলে শর্ট সার্কিট হতে পারে'],
  };
  static const reportExcuses = [
    'রিপোর্ট লিখলে ওভারটাইম মেলে, তাই লিখলাম',
    'সুপারভাইজার খুশি হবেন, তাই কিছু লিখে দিলাম',
    'জালটা দেখতে পুরোনো লাগছিল, তাই লিখলাম',
    'রাস্তার লোক দেখছিল, তাই একটা কিছু লিখলাম',
    'খাতায় কিছু না লিখলে বকুনি খাব, তাই লিখলাম',
    'হাতে সময় ছিল, তাই যা মনে এল লিখে দিলাম',
  ];
  static const okWhy = [
    'আর্থ পাইপে, জাল টানটান, দূরত্বও ঠিক আছে',
    'দুই পোলেই আর্থ আছে, জালে মরিচা বা ঝুল নেই',
    'আর্থ, জাল, টান আর দূরত্ব — সবই ঠিক দেখলাম',
  ];
  static const okMyths = [
    'গার্ডে কারেন্ট থাকে না, তাই দেখার কিছু নেই',
    'দু-একটা তার ছিঁড়লেও বাকিগুলো তো আছেই',
    'আর্থ তার না থাকলেও জাল ঠিকই কাজ করে',
    'দূর থেকে এক ঝলক দেখেই সব বুঝে গেছি আমি',
    'গতবার ঠিক ছিল, তাই এবারও নিশ্চয়ই ঠিক আছে',
    'একটু মরিচা থাকলে জালের কিছুই হয় না',
  ];

  static List<String> whyRight(M3GuardPatrolCase c) => c.healthy ? okWhy : [for (final f in c.faults.values) ...faultWhy[f]!];
  static List<String> whyWrong(M3GuardPatrolCase c) => c.healthy ? okMyths : reportExcuses;

  /// A tag on a sound spot: not scored; the round stays.
  static const needless = 'একটা দাগ ভুল জায়গায় — ওখানে ত্রুটি নেই। আবার দেখুন।';

  /// The careless coworker: the guard is dead to him.
  static const coworker = CoworkerScript(
    line: 'গার্ডের তারে কারেন্ট নেই, হাত দিয়ে টেনে দেখো!',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: ['না, গার্ডকে সবসময় লাইভ ধরেই চলব', 'না, খালি হাতে গার্ডের তার ছোঁব না', 'আর্থ ঠিক কিনা কে জানে, হাত দেব না'],
    wrong: [
      'ঠিক, গার্ডে তো কারেন্ট থাকে না, টানি',
      'আচ্ছা, একটু টেনে দেখলে কী আর হবে',
      'হ্যাঁ, ওটা তো শুধু জি আই তারের জাল',
      'ঠিক, আর্থ করা আছে, তাই ভয় নেই',
      'তাড়া আছে, হাত দিয়ে টেনেই দেখি',
    ],
    asks: ['ও বলছে হাত দিয়ে টানতে। আপনি কী করবেন?', 'গার্ডের তার খালি হাতে ধরবেন?', 'টানবেন, না দূরে থেকে রিপোর্ট করবেন?'],
  );

  static const callHeld = 'ঠিক! গার্ডকে সবসময় লাইভ ধরুন।';
  static const allSet = 'জালের পাহারা শিখে গেছেন — আর্থ, মরিচা, ঝুল, ছেঁড়া তার, দূরত্ব।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — দুই পোলের আর্থ আর পুরো জাল ভালো করে দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caught = {
    M3GuardPatrolFault.earthGone: 'চুরি যাওয়া আর্থ ধরেছেন',
    M3GuardPatrolFault.earthBare: 'পাইপের বাইরের আর্থ ধরেছেন',
    M3GuardPatrolFault.rust: 'মরিচা ধরা জাল ধরেছেন',
    M3GuardPatrolFault.broken: 'ছেঁড়া গার্ড তার ধরেছেন',
    M3GuardPatrolFault.sag: 'ঝুলে পড়া জাল ধরেছেন',
    M3GuardPatrolFault.gap: 'কমে যাওয়া দূরত্ব ধরেছেন',
  };
  static const caughtOk = 'ঠিক জালকে ঠিক বলেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M3GuardPatrolMistakes {
  static const _dir = 'assets/game/art/m3_guard_patrol';

  static const missedEarthGone = DoMistake(
    key: '3.9/m3_guard_patrol/missed-earth-gone',
    textBn: 'চুরি যাওয়া আর্থ চোখ এড়াল। আর্থ না থাকলে গার্ডিং কাজ করে না — লাইভ তার পড়লে পুরো জালটাই লাইভ হয়ে যেতে পারে।',
    art: '$_dir/earth_gone.svg',
    lessonPoint: 3,
  );

  /// Pro tip 4 (not a lesson point: "পাঠে দেখুন" opens the lesson start).
  static const missedEarthBare = DoMistake(
    key: '3.9/m3_guard_patrol/missed-earth-bare',
    textBn: 'আর্থ তার পাইপের বাইরে খোলা — চোখ এড়াল। খোলা আর্থ তার সহজে চুরি হয়; পাইপের ভেতর দিয়ে নিলে তবেই সুরক্ষিত।',
    art: '$_dir/earth_bare.svg',
  );
  static const missedRust = DoMistake(
    key: '3.9/m3_guard_patrol/missed-rust',
    textBn: 'মরিচা ধরা জাল চোখ এড়াল। গ্যালভানাইজিং নষ্ট হলে জি আই তারে মরিচা ধরে, তার দুর্বল হয়ে পড়ে।',
    art: '$_dir/rust.svg',
    lessonPoint: 3,
  );
  static const missedBroken = DoMistake(
    key: '3.9/m3_guard_patrol/missed-broken',
    textBn: 'ছেঁড়া গার্ড তার চোখ এড়াল। একটা তার ছিঁড়লেও পুরো জালের শক্তি কমে, আর ঝুলে পড়ে অন্য বিপদ ঘটায়।',
    art: '$_dir/broken.svg',
    lessonPoint: 3,
  );
  static const missedSag = DoMistake(
    key: '3.9/m3_guard_patrol/missed-sag',
    textBn: 'ঝুলে পড়া জাল চোখ এড়াল। ঝুলে থাকা গার্ডিং বাতাসে লাইভ তার ছুঁয়ে শর্ট সার্কিট ঘটাতে পারে।',
    art: '$_dir/sag.svg',
    lessonPoint: 3,
  );

  /// Pro tip 1 (not a lesson point).
  static const missedGap = DoMistake(
    key: '3.9/m3_guard_patrol/missed-gap',
    textBn: 'লাইভ তার জালের খুব কাছে নেমেছে — চোখ এড়াল। উল্লম্ব দূরত্ব কম হলে আর্ক বা শর্ট সার্কিট হতে পারে।',
    art: '$_dir/gap.svg',
  );

  static const touchNoEarth = DoMistake(
    key: '3.9/m3_guard_patrol/touch-no-earth',
    textBn: 'খালি হাতে গার্ডের তার ধরলেন — এই ক্রসিং-এ আর্থই ছিল না! আর্থ নষ্ট হলে পুরো জাল লাইভ হতে পারে। গার্ডকে সবসময় লাইভ ধরুন।',
    art: '$_dir/touch_no_earth.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const touchGuard = DoMistake(
    key: '3.9/m3_guard_patrol/touch-guard',
    textBn: 'খালি হাতে গার্ডের তার ধরলেন! আর্থ দুর্বল থাকলে আর লাইভ তার ছুঁলে পুরো জাল লাইভ হয়ে যায়। গার্ডকে সবসময় লাইভ ধরুন।',
    art: '$_dir/touch_guard.svg',
    deadly: true,
    lessonPoint: 3,
  );

  static DoMistake missed(M3GuardPatrolFault f) => switch (f) {
        M3GuardPatrolFault.earthGone => missedEarthGone,
        M3GuardPatrolFault.earthBare => missedEarthBare,
        M3GuardPatrolFault.rust => missedRust,
        M3GuardPatrolFault.broken => missedBroken,
        M3GuardPatrolFault.sag => missedSag,
        M3GuardPatrolFault.gap => missedGap,
      };

  static List<DoMistake> get all => [
        for (final f in M3GuardPatrolFault.values) missed(f),
        touchNoEarth,
        touchGuard,
      ];
}

@immutable
class M3GuardPatrolDeal {
  const M3GuardPatrolDeal({required this.cases, required this.callAt});
  final List<M3GuardPatrolCase> cases;

  /// The crossing the careless coworker comes on (it has the snapped wire).
  final int callAt;
}

/// Three crossings (road, rail, telecom) in a fresh order. The coworker's
/// crossing has the snapped wire hanging down and one more fault (the stolen
/// earth more often than not); of the other two, one has one or two faults
/// and the other none or one. No fault twice a play; an earth fault every
/// play.
M3GuardPatrolDeal m3GuardPatrolDeal(math.Random rng) {
  final crossings = [...M3GuardPatrolCrossing.values]..shuffle(rng);
  final callAt = rng.nextInt(3);
  final pool = [_Fault.earthGone, _Fault.earthBare, _Fault.rust, _Fault.sag, _Fault.gap]..shuffle(rng);
  final second = rng.nextInt(10) < 6 ? _Fault.earthGone : pool.firstWhere((f) => f != _Fault.earthGone);
  pool.remove(second);
  final counts = [1 + rng.nextInt(2), rng.nextInt(2)]..shuffle(rng);
  final sets = <List<_Fault>>[];
  for (final n in counts) {
    sets.add([for (var k = 0; k < n; k++) pool.removeAt(0)]);
  }
  // An earth fault every play.
  bool earthy(List<_Fault> l) => l.contains(_Fault.earthGone) || l.contains(_Fault.earthBare);
  if (!earthy([second, ...sets[0], ...sets[1]])) {
    final e = pool.firstWhere((f) => f == _Fault.earthGone || f == _Fault.earthBare);
    final into = sets[0].length <= sets[1].length ? 0 : 1;
    if (sets[into].length < 2) {
      sets[into].add(e);
    } else {
      sets[into][0] = e;
    }
  }

  Map<_Spot, _Fault> place(List<_Fault> fs) {
    final out = <_Spot, _Fault>{};
    // The gap is mid-span (the conductors' lowest point): place it first.
    final order = [...fs]..sort((a, b) => (b == _Fault.gap ? 1 : 0) - (a == _Fault.gap ? 1 : 0));
    for (final f in order) {
      final List<_Spot> can = switch (f) {
        _Fault.earthGone || _Fault.earthBare => [_Spot.earthL, _Spot.earthR],
        _Fault.gap => [_Spot.spanM],
        _ => [_Spot.spanL, _Spot.spanM, _Spot.spanR],
      };
      final free = [for (final s in can) if (!out.containsKey(s)) s];
      out[free[rng.nextInt(free.length)]] = f;
    }
    return out;
  }

  var other = 0;
  final cases = <M3GuardPatrolCase>[
    for (var i = 0; i < 3; i++)
      M3GuardPatrolCase(
        id: 'g$i',
        crossing: crossings[i],
        faults: place(i == callAt ? [_Fault.broken, second] : sets[other++]),
      ),
  ];
  return M3GuardPatrolDeal(cases: cases, callAt: callAt);
}

/// The play state (pure logic).
class M3GuardPatrolRun {
  M3GuardPatrolRun(this.deal);

  final M3GuardPatrolDeal deal;
  int index = 0;

  /// The trainee's tags on this crossing.
  final Set<M3GuardPatrolSpot> tags = {};

  /// Reports sent this crossing with a tag on a sound spot.
  int needless = 0;

  var shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  M3GuardPatrolCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;

  /// The +5: two faults caught on the first report.
  bool get thorough => needless == 0 && current.faults.length >= 2;

  /// Tag or untag [s]; true = tagged now.
  bool toggle(M3GuardPatrolSpot s) {
    if (!_open) return tags.contains(s);
    if (tags.remove(s)) return false;
    tags.add(s);
    return true;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Send the report (no tags = "all fine"). A fault left untagged = a slip
  /// (the first one, by spot order); a tag on a sound spot alone = not scored,
  /// the round stays ([needless]).
  DoMistake? report() {
    if (!_open) return null;
    final c = current;
    for (final s in M3GuardPatrolSpot.values) {
      final f = c.faults[s];
      if (f != null && !tags.contains(s)) {
        shown = true;
        slips++;
        return M3GuardPatrolMistakes.missed(f);
      }
    }
    if (tags.any((s) => !c.faults.containsKey(s))) {
      needless++;
      return null;
    }
    shown = true;
    if (c.healthy) {
      _tag(M3GuardPatrolLines.caughtOk);
    } else {
      for (final f in c.faults.values) {
        _tag(M3GuardPatrolLines.caught[f]!);
      }
    }
    return null;
  }

  /// The guard touched bare-handed (he was listened to): always deadly.
  DoMistake? touch() {
    if (!_open) return null;
    shown = true;
    return deadly = current.has(M3GuardPatrolFault.earthGone) ? M3GuardPatrolMistakes.touchNoEarth : M3GuardPatrolMistakes.touchGuard;
  }

  void next() {
    index++;
    tags.clear();
    needless = 0;
    shown = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A crossing (ms):
/// look ~5000, two tags 2 × 1500, report 1500, reason ~8200 ≈ 17700; three ≈
/// 53000, the coworker ~9600: ≈ 62600; 85 % ≈ 53 s.
const kM3GuardPatrolQuickMs = 53000;

@immutable
class M3GuardPatrolPack {
  const M3GuardPatrolPack({required this.id, required this.titleBn, this.quickMs = kM3GuardPatrolQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3GuardPatrolPacks = {
  'do_3_9_a': M3GuardPatrolPack(id: 'do_3_9_a', titleBn: M3GuardPatrolLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3GuardPatrolPage extends StatefulWidget {
  const M3GuardPatrolPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3GuardPatrolPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3GuardPatrolPage> createState() => _M3GuardPatrolPageState();
}

class _M3GuardPatrolPageState extends State<M3GuardPatrolPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PatrolRunPage(
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

class _PatrolRunPage extends ConsumerStatefulWidget {
  const _PatrolRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3GuardPatrolPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PatrolRunPage> createState() => _PatrolRunPageState();
}

class _PatrolRunPageState extends ConsumerState<_PatrolRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3GuardPatrolRun _run = M3GuardPatrolRun(m3GuardPatrolDeal(widget.rng));
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

  /// The stamp after a right report: true = report, false = all fine.
  bool? _stamp;
  var _coworkerArmed = false;
  Timer? _armTimer;

  /// He reached for the hanging wire (walking there, then the freeze).
  var _grab = false;

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
    _armTimer?.cancel();
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
    setState(() {
      _stamp = null;
      _wake++;
    });
    unawaited(_sayChain([M3GuardPatrolLines.ask]));
    // His crossing: he comes once the trainee tags something, or soon anyway.
    if (_run.index == _run.deal.callAt) {
      _armTimer?.cancel();
      _armTimer = Timer(const Duration(milliseconds: 4500), _arm);
    }
  }

  void _arm() {
    if (!mounted || _coworkerArmed || _run.index != _run.deal.callAt) return;
    _coworkerArmed = true;
    _armTimer?.cancel();
    scheduleCoworker();
  }

  // --- hands on -----------------------------------------------------------------------
  void _tapScene(Offset p, M3GuardPatrolGeo geo) {
    if (!_canPlay) return;
    final c = _run.current;
    _Spot? hit;
    final broken = c.spotOf(_Fault.broken);
    if (broken != null && geo.dangleHit(broken).contains(p)) hit = broken;
    if (hit == null) {
      for (final s in M3GuardPatrolSpot.values) {
        if (geo.hit(s).contains(p)) hit = s;
      }
    }
    if (hit == null) return;
    HapticFeedback.selectionClick();
    final on = _run.toggle(hit);
    _cue(on ? 'sounds/learn/tag_slap.wav' : 'sounds/intro/tick.ogg', volume: on ? 0.45 : 0.5);
    setState(() => _wake++);
    if (on && _run.index == _run.deal.callAt) _arm();
  }

  // --- the report ----------------------------------------------------------------
  Future<void> _report(Offset origin) async {
    if (!_canPlay) return;
    _hush();
    final tagged = _run.tags.isNotEmpty;
    final m = _run.report();
    if (m == null && !_run.shown) {
      HapticFeedback.selectionClick();
      _cue('sounds/intro/click.ogg', volume: 0.5);
      setState(() => _wake++);
      unawaited(_sayChain([M3GuardPatrolLines.needless]));
      return;
    }
    HapticFeedback.mediumImpact();
    if (m == null) {
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      setState(() {
        _stamp = tagged;
        _wake++;
      });
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final c = _run.current;
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(M3GuardPatrolLines.whyRight(c), M3GuardPatrolLines.whyWrong(c), widget.rng),
        question: c.healthy ? M3GuardPatrolLines.whyOk : M3GuardPatrolLines.whyReport,
        stillValid: () => _run.index == idx && !_ended,
      ));
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
  CoworkerScript get coworkerScript => M3GuardPatrolLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.shown) return null;
    if (_intro || _busy || _card != null || reasonOpen) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: a bare hand on the hanging guard wire.
      final m = _run.touch();
      if (m != null) await _deadly(m);
      return;
    }
    if (!_run.caught.contains(M3GuardPatrolLines.caughtCall)) _run.caught.add(M3GuardPatrolLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([M3GuardPatrolLines.callHeld]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3GuardPatrolLines.tapWhy[_nudgeN++ % M3GuardPatrolLines.tapWhy.length]
            : _nudge.next(M3GuardPatrolLines.ask);
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
    final speak = await SpokenOnce.first('guard/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A bare hand on the hanging wire: he walks under it and grabs it; the
  /// scene freezes grey and the guard flashes alive in colour; then near-miss
  /// or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    setState(() {
      _grab = true;
      _wake++;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 800));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.wav', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('guard/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3GuardPatrolLines.deadlyWord : M3GuardPatrolLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? M3GuardPatrolLines.fail : (_quickBonus ? M3GuardPatrolLines.quick : M3GuardPatrolLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_grab) return _freeze ? LinemanMode.hold : LinemanMode.walk;
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_stamp != null) return LinemanMode.cheer;
    if (_run.tags.isNotEmpty) return LinemanMode.point;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M3GuardPatrolGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final broken = c.spotOf(_Fault.broken);
    final tb = _grab && broken != null ? geo.traineeAt(broken) : geo.trainee;
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
                    painter: M3GuardPatrolWorldPainter(geo: geo, crossing: c.crossing, faults: c.faults, tags: {..._run.tags}),
                  ),
                ),
              ),
              AnimatedPositioned(
                key: const ValueKey('trainee'),
                duration: Duration(milliseconds: quiet ? 1 : 700),
                curve: Curves.easeInOut,
                left: tb.left,
                top: tb.top,
                width: tb.width,
                height: tb.height,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (_stamp != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 90,
          width: 180,
          top: geo.guardLowY + 70,
          child: IgnorePointer(child: _StampPop(text: _stamp! ? M3GuardPatrolLines.stampReport : M3GuardPatrolLines.stampOk, quiet: quiet)),
        ),
      // Tap a spot: a tag goes on (or comes off).
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3GuardPatrolLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      if (_freeze && broken != null)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3GuardPatrolZapPainter(at: geo.dangle(broken).$2, v: v)),
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
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null && !_grab;
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
              labels: [for (final c in _run.deal.cases) M3GuardPatrolLines.crossingBn(c.crossing)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn)
                Positioned(
                  key: const ValueKey('hud-report'),
                  left: 12,
                  right: 132,
                  bottom: pad.bottom + 12,
                  child: DoBigButton(
                    label: _run.tags.isEmpty ? M3GuardPatrolLines.allOk : M3GuardPatrolLines.report,
                    filled: true,
                    onTapUp: (d) => unawaited(_report(d.globalPosition)),
                  ),
                ),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
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
                  line: M3GuardPatrolLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 3, muted: _muted)),
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
