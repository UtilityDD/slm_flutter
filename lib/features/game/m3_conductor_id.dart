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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm3_conductor_id_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 3.1, কাজ 1: "কোন তার কোনটা". In the store yard before line work: the
// docket on the post lists three jobs, each naming its conductor (ACSR or
// AAAC) and where it goes (the coast's salt air, a factory's smoke, an
// ordinary line). For each job a row of three drums stands on the gravel;
// their tags are weathered blank, and ACSR and AAAC look alike from a step
// away. The trainee walks up to a drum and looks close: rubs the grime off the
// free end's cut face (a steel core in the centre = ACSR; all alloy strands =
// AAAC), touches the magnet to it (sticks to ACSR's steel, not to AAAC —
// the lesson's own check), and runs a hand along the outer wraps (one cut
// strand shows only where the hand has been — lesson: একটা স্ট্র্যান্ড কাটা
// মানে লাইনের শক্তি কমে যাওয়া). Then loads it on the van or puts it back (a
// drum whose cut strand he found is tagged বাতিল). On one job no good drum
// of the right conductor stands in the row: he tells the store instead.
// Once a play the careless coworker (level 1's rival) peeps in: "দুটোই তো তার
// — যেটা হাতের কাছে আছে, ওটাই লাগাও!" (the nearest drum is the other
// conductor, or the other-conductor drum in the trainee's hands), or — only
// when the trainee holds a drum whose cut strand he has just found — "একটা
// সরু তার কাটা তো কী". Loading, setting a found cut drum aside, or telling
// the store waits for him (holdForCoworker), so a fast play never skips him;
// a drum of the docket's conductor (not a found cut) goes back in the row
// first, so his "at hand" line always points at what he pushes. Listening is
// a slip (the drum he pushed is loaded). Reason decks deal each right card
// with its own near miss (same words, wrong fact).
// Gesture hints: a sweep over the drums + the store button, a rub on the cut
// face, a stroke along the wraps, a sweep over put back / load — never which.
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" → the next job by itself.
//
// Deadly: none — the lesson makes these faults (the wrong conductor, a cut
// strand, a guess) a line that rusts, weakens or snaps later, not a death on
// the spot in the yard. Every fault is a slip; 3 slips fail.
// (The joint sleeve — ACSR and AAAC sleeves differ — is কাজ 2's job.)
//
// Voice: the guide's lines on device TTS; the coworker's two pushes are new
// (silent with the caption held until recorded in his voice); his exit line
// is recorded.
// Art: the yard, the drums, the cut face, the wraps and the magnet are drawn
// in code (m3_conductor_id_world.dart); the mistake cards use
// assets/game/art/m3_conductor_id/.

// ============================================================================
// Content
// ============================================================================

/// The two overhead conductors of the lesson.
enum M3ConductorIdKind { acsr, aaac }

extension M3ConductorIdKindText on M3ConductorIdKind {
  /// As a docket and a store write it.
  String get tag => this == M3ConductorIdKind.acsr ? 'ACSR' : 'AAAC';
  M3ConductorIdKind get other => this == M3ConductorIdKind.acsr ? M3ConductorIdKind.aaac : M3ConductorIdKind.acsr;

  /// 0-based point of lesson 3.1 that teaches it.
  int get lessonPoint => this == M3ConductorIdKind.acsr ? 1 : 2;

  /// Only ACSR has steel in it: a magnet sticks to it.
  bool get magnetic => this == M3ConductorIdKind.acsr;
}

/// The strand layouts drawn on a cut face (6/1 and 30/7 ACSR; 7 and 19 strand
/// AAAC) — no counts are printed or scored, the steel centre is what matters.
const m3ConductorIdLayouts = {
  M3ConductorIdKind.acsr: [
    M3ConductorIdLayout(rings: [1, 6], steelRings: 1),
    M3ConductorIdLayout(rings: [1, 6, 12, 18], steelRings: 2),
  ],
  M3ConductorIdKind.aaac: [
    M3ConductorIdLayout(rings: [1, 6], steelRings: 0),
    M3ConductorIdLayout(rings: [1, 6, 12], steelRings: 0),
  ],
};

@immutable
class M3ConductorIdDrum {
  const M3ConductorIdDrum({required this.id, required this.kind, required this.layout, this.cutU});
  final String id;
  final M3ConductorIdKind kind;
  final M3ConductorIdLayout layout;

  /// Where along the outer wraps one strand is cut (0..1); null = sound.
  final double? cutU;
  bool get cut => cutU != null;
}

@immutable
class M3ConductorIdJob {
  const M3ConductorIdJob({required this.need, required this.feederBn, required this.whereBn});
  final M3ConductorIdKind need;
  final String feederBn;
  final String whereBn;
}

@immutable
class M3ConductorIdRound {
  const M3ConductorIdRound({required this.job, required this.drums});
  final M3ConductorIdJob job;
  final List<M3ConductorIdDrum> drums;

  /// No sound drum of the docket's conductor in this row: tell the store.
  bool get noneFits => !drums.any((d) => d.kind == job.need && !d.cut);
}

/// What the careless coworker pushes.
enum M3ConductorIdPush { nearest, strand }

@immutable
class M3ConductorIdDeal {
  const M3ConductorIdDeal({required this.rounds, required this.callRound});
  final List<M3ConductorIdRound> rounds;

  /// The job on which he peeps in (or a later one, if nothing he could push
  /// is still in the row).
  final int callRound;
}

abstract final class M3ConductorIdLines {
  static const title = 'কোন তার কোনটা';
  static const intro = 'ড্রামের লেবেল ঝাপসা! চিনে নিয়ে ডকেটের তার তুলুন।';
  static String ask(M3ConductorIdKind k) => 'ডকেটে ${k.tag} — কোন ড্রামটা তুলবেন?';
  static const inspectAsk = 'কাটা মুখ আর তারের গা দেখে চিনুন। তুলবেন?';
  static final tasks = [for (final k in M3ConductorIdKind.values) ask(k), inspectAsk];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const docket = 'ডকেট';
  static const yardBn = 'স্টোর ইয়ার্ড';
  static const needWord = 'চাই';
  static const drumLabel = 'ড্রাম';
  static const faceLabel = 'কাটা মুখ';
  static const wrapLabel = 'তারের গা';
  static const magnetLabel = 'চুম্বক';
  static const load = 'গাড়িতে তুলুন';
  static const putBack = 'ফেরত রাখুন';
  static const hold = 'ঠিক ড্রাম নেই — স্টোরে জানাই';
  static const rejected = 'বাতিল';

  // The reasons (lesson 3.1). Every card set stays within 1.3× in length.
  static const loadAsk = 'কেন এই ড্রামটা তুললেন?';
  static const holdAsk = 'কেন ড্রাম না তুলে স্টোরে জানালেন?';
  static List<String> loadRight(M3ConductorIdKind k) => switch (k) {
        M3ConductorIdKind.acsr => const ['মাঝে স্টিলের কোর আছে — এটাই ACSR', 'চুম্বক আটকেছে, ভেতরে স্টিল — ACSR'],
        M3ConductorIdKind.aaac => const ['মাঝে স্টিল নেই, পুরোটা অ্যালয় — AAAC', 'চুম্বক আটকায়নি, স্টিল নেই — AAAC'],
      };
  static const loadMyths = [
    'দুটোই তো তার, যেকোনোটা দিলেই চলে',
    'ড্রামটা সবচেয়ে কাছে ছিল, তাই নিলাম',
    'লেবেল ঝাপসা, আন্দাজে এটাই মনে হলো',
    'সব তো অ্যালুমিনিয়ামই, কোনো তফাত নেই',
    'মোটা দেখাচ্ছে, তাই বেশি কারেন্ট নেবে',
    'বাইরে চকচকে, তাই ভালো ধরে নিলাম',
  ];

  /// Near misses, parallel to [loadRight] (index i goes with right card i):
  /// the same words and this docket's name, the fact turned the wrong way —
  /// so no word (চুম্বক, মাঝে, কোর, স্টিল, the tag) is only on the right card.
  static List<String> loadNear(M3ConductorIdKind k) => switch (k) {
        M3ConductorIdKind.acsr => const ['মাঝে স্টিলের কোর নেই — এটাই ACSR', 'চুম্বক আটকায়নি, ভেতরে স্টিল নেই — ACSR'],
        M3ConductorIdKind.aaac => const ['মাঝে স্টিল, পুরোটা অ্যালয় নয় — AAAC', 'চুম্বক আটকেছে, স্টিল আছে — AAAC'],
      };
  static List<String> loadWrong(M3ConductorIdKind k) => [...loadNear(k), ...loadMyths];

  static const holdRight = [
    'ডকেটের তারের ভালো ড্রাম এখানে নেই',
    'স্ট্র্যান্ড কাটা ড্রাম নয়, স্টোরে বলি',
  ];
  /// Near misses, parallel to [holdRight] (index i goes with right card i):
  /// the same words (ডকেট, ভালো, এখানে / স্ট্র্যান্ড, কাটা, স্টোর), a lazy reason.
  static const holdNear = [
    'এখানে ডকেটের ভালো ড্রাম খোঁজা ঝামেলা',
    'স্ট্র্যান্ড কাটা খুঁজব না, স্টোরে বলি',
  ];
  static const holdRest = [
    'দেরি হচ্ছে, তাই পরে এসে দেখে নেব',
    'ড্রামগুলো খুব ভারী, তাই তুলিনি',
    'অন্য তার দিয়েই কাজটা সেরে নেব',
    'কোনটা কী জানি না, তাই ছেড়ে দিলাম',
    'স্টোরকিপার বকবে, তাই রেখে দিলাম',
  ];
  static const holdWrong = [...holdNear, ...holdRest];

  /// The careless coworker. His exit line is already recorded in his voice;
  /// the two pushes are silent (caption held) until they are recorded.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerNearest = CoworkerScript(
    line: 'আরে! দুটোই তো তার — যেটা হাতের কাছে আছে, ওটাই লাগাও!',
    exitLine: coworkerExit,
    right: ['না — ডকেটের তার মিলিয়েই তুলব', 'ACSR আর AAAC আলাদা, মিলিয়ে নেব', 'আন্দাজে নয়, চুম্বকে চিনে তুলব'],
    wrong: [
      'ঠিক, দুটোই তো একই রকম তার',
      'কাছেরটাই তুলি, সময় বাঁচুক',
      'সব তো অ্যালুমিনিয়ামই, চলবে',
      'ডকেট-টকেট পরে মিলিয়ে নেব',
      'সবাই তো যেটা পায় সেটাই নেয়',
    ],
    asks: ['ও বলছে যেটা কাছে সেটাই। আপনি কী করবেন?', 'কাছেরটা নেবেন, না ডকেটেরটা?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerStrand = CoworkerScript(
    line: 'একটা সরু তার কাটা তো কী — বাকিগুলো তো আছে, তুলে নাও!',
    exitLine: coworkerExit,
    right: ['একটা স্ট্র্যান্ড কাটাও চলবে না', 'ওখান থেকেই তার ছিঁড়বে, নেব না', 'কাটা স্ট্র্যান্ডের ড্রাম বাতিল'],
    wrong: [
      'ঠিক, একটা তারে কিছু হয় না',
      'বাকিগুলো তো আছে, তুলে নিই',
      'টেপ জড়িয়ে দিলেই চলে যাবে',
      'নতুন আনতে দেরি, এটাই চলুক',
      'সবাই তো এমনই চালিয়ে নেয়',
    ],
    asks: ['ও বলছে একটা তার কাটা কিছু না। আপনি কী করবেন?', 'কাটা স্ট্র্যান্ডের ড্রাম নেবেন?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(M3ConductorIdPush p) => p == M3ConductorIdPush.nearest ? coworkerNearest : coworkerStrand;

  static const callHeld = 'ঠিক! চিনে নিয়ে, মিলিয়ে তবে তুলবেন।';
  static const asideCut = 'ঠিক — কাটা স্ট্র্যান্ডের ড্রাম বাতিল।';
  static const stuck = 'চুম্বক আটকে গেল!';
  static const fell = 'চুম্বক আটকাল না।';
  static const holdDone = 'ঠিক! আন্দাজে নয় — স্টোর থেকে ঠিক ড্রাম আসবে।';
  static const allSet = 'গাড়ি তৈরি! প্রতিটা তার চিনে, মিলিয়ে তুলেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কাটা মুখ আর চুম্বকে তার চিনে নিন।';
  static const caughtCore = 'কাটা মুখে স্টিল কোর দেখে চেনা';
  static const caughtMagnet = 'চুম্বক ছুঁইয়ে তার চেনা';
  static const caughtLoad = 'ডকেটের তার মিলিয়ে তোলা';
  static const caughtCut = 'কাটা স্ট্র্যান্ডের ড্রাম বাতিল';
  static const caughtHold = 'ঠিক ড্রাম না পেয়ে স্টোরে জানানো';
  static const caughtCall = 'চাপে “না” বলেছেন';

  static const acsrWhere = ['গ্রামের নতুন লাইন', 'মাঠের ওপর দিয়ে লাইন', 'বাজারের পুরনো লাইন বদল'];
  static const aaacWhere = ['উপকূলের গ্রাম — নোনা হাওয়া', 'কারখানার পাশে — ধোঁয়া'];
  static const feeders = ['রামপুর ফিডার', 'হাটখোলা ফিডার', 'নদীপাড় ফিডার', 'স্টেশন রোড ফিডার', 'কলেজপাড়া ফিডার', 'বন্দর ফিডার'];
}

abstract final class M3ConductorIdMistakes {
  static const _kindArt = 'assets/game/art/m3_conductor_id/cond_core.svg';
  static const _strandArt = 'assets/game/art/m3_conductor_id/cond_strand.svg';
  static const _checkArt = 'assets/game/art/m3_conductor_id/cond_check.svg';

  /// Every card this level can book, for the mistakes book (`knownMistakes`).
  static List<DoMistake> get all => [
        for (final k in M3ConductorIdKind.values) wrongKind(k),
        cutStrand,
        unchecked,
        heldWhenRight,
      ];

  /// The other conductor loaded for a job whose docket says [need].
  static DoMistake wrongKind(M3ConductorIdKind need) => DoMistake(
        key: '3.1/m3_conductor_id/wrong-kind/${need.name}',
        textBn: need == M3ConductorIdKind.acsr
            ? 'ডকেটে ACSR — এটা AAAC: মাঝে স্টিল নেই, চুম্বক আটকায় না। ডকেটের তার মিলিয়ে তুলুন; স্টোরে আর সাইটে দুবার চেক।'
            : 'ডকেটে AAAC — এটা ACSR: মাঝে স্টিলের কোর, চুম্বক আটকায়। নোনা হাওয়া বা ধোঁয়ায় ওই স্টিলে জং ধরে, সেখানে AAAC।',
        art: _kindArt,
        lessonPoint: need.lessonPoint,
      );
  static const cutStrand = DoMistake(
    key: '3.1/m3_conductor_id/cut-strand',
    textBn: 'তারের গায়ে একটা স্ট্র্যান্ড কাটা — একটা স্ট্র্যান্ড কাটা মানে লাইনের শক্তি কম, ওখান থেকেই পরে তার ছিঁড়বে। এই ড্রাম বাতিল।',
    art: _strandArt,
    lessonPoint: 3,
  );
  static const unchecked = DoMistake(
    key: '3.1/m3_conductor_id/unchecked',
    textBn: 'না চিনেই তুলছেন — লেবেল ঝাপসা হলে আন্দাজে ঢিল নয়। কাটা মুখে স্টিল কোর দেখুন, চুম্বক ছুঁইয়ে মিলিয়ে নিন।',
    art: _checkArt,
    lessonPoint: 3,
  );
  static const heldWhenRight = DoMistake(
    key: '3.1/m3_conductor_id/held-when-right',
    textBn: 'ডকেটের তারের ভালো ড্রাম সারিতেই ছিল — কাটা মুখ, চুম্বক আর তারের গা ভালো করে দেখুন।',
    art: _checkArt,
    lessonPoint: 3,
  );
}

/// A fresh yard each play: the jobs and their order, the drums in each row,
/// which has a cut strand and where, which job has no good drum, and the
/// coworker's moment vary.
M3ConductorIdDeal m3ConductorIdDeal(math.Random rng) {
  var n = 0;
  M3ConductorIdDrum drum(M3ConductorIdKind k, {bool cut = false}) {
    final ls = m3ConductorIdLayouts[k]!;
    return M3ConductorIdDrum(
      id: 'drum${n++}',
      kind: k,
      layout: ls[rng.nextInt(ls.length)],
      cutU: cut ? 0.12 + rng.nextDouble() * 0.76 : null,
    );
  }

  final needs = [M3ConductorIdKind.acsr, M3ConductorIdKind.aaac, M3ConductorIdKind.values[rng.nextInt(2)]]..shuffle(rng);
  final feeders = [...M3ConductorIdLines.feeders]..shuffle(rng);
  final aaacWhere = [...M3ConductorIdLines.aaacWhere]..shuffle(rng);
  final acsrWhere = [...M3ConductorIdLines.acsrWhere]..shuffle(rng);
  var ai = 0;
  var ci = 0;
  final hold = rng.nextInt(3);
  final rounds = <M3ConductorIdRound>[];
  for (var i = 0; i < 3; i++) {
    final k = needs[i];
    final List<M3ConductorIdDrum> drums;
    if (i == hold) {
      // The docket's conductor only with a cut strand; the rest the other one.
      drums = [drum(k, cut: true), drum(k.other), if (rng.nextBool()) drum(k, cut: true) else drum(k.other)];
    } else if (rng.nextInt(5) < 3) {
      drums = [drum(k), drum(k, cut: true), drum(k.other)];
    } else {
      drums = [drum(k), drum(k.other), drum(k.other)];
    }
    drums.shuffle(rng);
    final where = k == M3ConductorIdKind.aaac ? aaacWhere[ai++ % aaacWhere.length] : acsrWhere[ci++ % acsrWhere.length];
    rounds.add(M3ConductorIdRound(job: M3ConductorIdJob(need: k, feederBn: feeders[i], whereBn: where), drums: drums));
  }
  return M3ConductorIdDeal(rounds: rounds, callRound: rng.nextInt(3));
}

/// What the careless coworker pushes on round [r] now, given the drum in the
/// trainee's hands ([held]; null in the yard). His line fits the moment:
/// holding a drum of the docket's conductor whose cut strand the trainee has
/// found ([spotted]) → strand ("a thin strand cut, so what"); otherwise →
/// nearest ("take whatever is at hand"). He never names a cut the trainee has
/// not seen (that would give it away). Null when nothing fits.
M3ConductorIdPush? m3ConductorIdPushFor(M3ConductorIdRound r, Set<String> rejected, {M3ConductorIdDrum? held, Set<String> spotted = const {}}) {
  if (m3ConductorIdPushed(r, M3ConductorIdPush.strand, rejected, held: held, spotted: spotted) != null) return M3ConductorIdPush.strand;
  if (m3ConductorIdPushed(r, M3ConductorIdPush.nearest, rejected, held: held) != null) return M3ConductorIdPush.nearest;
  return null;
}

/// The drum he pushes on round [r] — the one listening loads. Strand: the
/// found cut drum in the hands. Nearest: the drum in the hands when it is the
/// other conductor ("the one at hand"), else the first other-conductor drum
/// in the row (the one nearest the trainee). A drum of the docket's conductor
/// in the hands that is not a found cut goes back in the row before he comes
/// (the page does that), so "at hand" never points away from the hands.
M3ConductorIdDrum? m3ConductorIdPushed(M3ConductorIdRound r, M3ConductorIdPush p, Set<String> rejected,
    {M3ConductorIdDrum? held, Set<String> spotted = const {}}) {
  final h = held != null && !rejected.contains(held.id) ? held : null;
  if (p == M3ConductorIdPush.strand) {
    return h != null && h.kind == r.job.need && h.cut && spotted.contains(h.id) ? h : null;
  }
  if (h != null && h.kind != r.job.need) return h;
  for (final d in r.drums) {
    if (!rejected.contains(d.id) && d.kind != r.job.need) return d;
  }
  return null;
}

/// A reason deck: one right card, ITS near miss ([near] is parallel to
/// [right]: same words, the fact turned wrong) and one other wrong card,
/// shuffled — no key word is only on the right card.
List<ChoiceOption> m3ConductorIdWhyDeal(List<String> right, List<String> near, List<String> rest, math.Random rng) {
  assert(right.length == near.length, 'near misses are dealt in pairs with the right cards');
  final i = rng.nextInt(right.length);
  final others = [...rest]..shuffle(rng);
  return [
    ChoiceOption(right[i], true),
    ChoiceOption(near[i], false),
    ChoiceOption(others.first, false),
  ]..shuffle(rng);
}

enum M3ConductorIdVerdict { right, slip }

@immutable
class M3ConductorIdOutcome {
  const M3ConductorIdOutcome(this.verdict, {this.mistake});
  final M3ConductorIdVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class M3ConductorIdRun {
  M3ConductorIdRun(this.deal);
  final M3ConductorIdDeal deal;
  int round = 0;
  int slips = 0;

  /// This job is decided (a drum loaded, or the store told): the reason
  /// comes, then [next].
  bool shown = false;

  /// Drums set aside on this row (tagged বাতিল).
  final Set<String> rejected = {};

  /// Drums on this row whose conductor the player has identified (the cut
  /// face cleaned to the core, or the magnet touched) — chalked in the yard.
  final Set<String> checked = {};

  /// Drums on this row whose cut strand the player has found.
  final Set<String> spotted = {};

  /// What is on the van: job (round) → drum; a job told to the store stays empty.
  final Map<int, M3ConductorIdDrum> loaded = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done;
  M3ConductorIdRound get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// The cut face rubbed clean down to the core.
  void sawCore(M3ConductorIdDrum d) {
    checked.add(d.id);
    _tag(M3ConductorIdLines.caughtCore);
  }

  /// The magnet touched to the cut face; true = it sticks (steel: ACSR).
  bool magnet(M3ConductorIdDrum d) {
    checked.add(d.id);
    _tag(M3ConductorIdLines.caughtMagnet);
    return d.kind.magnetic;
  }

  /// The hand found [d]'s cut strand on the wraps.
  void spot(M3ConductorIdDrum d) {
    if (d.cut) spotted.add(d.id);
  }

  /// Loads [d] on the van for the current job.
  M3ConductorIdOutcome load(M3ConductorIdDrum d) {
    if (ended || shown || rejected.contains(d.id)) return const M3ConductorIdOutcome(M3ConductorIdVerdict.slip);
    final need = current.job.need;
    if (d.kind != need) {
      // The card says what it is: it stays in the row, chalked.
      slips++;
      checked.add(d.id);
      return M3ConductorIdOutcome(M3ConductorIdVerdict.slip, mistake: M3ConductorIdMistakes.wrongKind(need));
    }
    if (d.cut) {
      slips++;
      rejected.add(d.id);
      spotted.add(d.id);
      return const M3ConductorIdOutcome(M3ConductorIdVerdict.slip, mistake: M3ConductorIdMistakes.cutStrand);
    }
    if (!checked.contains(d.id)) {
      // The right drum, but by a guess: it goes back in the row.
      slips++;
      return const M3ConductorIdOutcome(M3ConductorIdVerdict.slip, mistake: M3ConductorIdMistakes.unchecked);
    }
    _tag(M3ConductorIdLines.caughtLoad);
    loaded[round] = d;
    shown = true;
    return const M3ConductorIdOutcome(M3ConductorIdVerdict.right);
  }

  /// Puts [d] back: a drum whose cut strand the player found is set aside
  /// (true); anything else goes back in the row (false) — putting back never
  /// tells which drum is damaged.
  bool putBack(M3ConductorIdDrum d) {
    if (ended || shown || rejected.contains(d.id)) return false;
    if (!spotted.contains(d.id)) return false;
    rejected.add(d.id);
    _tag(M3ConductorIdLines.caughtCut);
    return true;
  }

  /// "ঠিক ড্রাম নেই — স্টোরে জানাই".
  M3ConductorIdOutcome holdJob() {
    if (ended || shown) return const M3ConductorIdOutcome(M3ConductorIdVerdict.slip);
    if (!current.noneFits) {
      slips++;
      return const M3ConductorIdOutcome(M3ConductorIdVerdict.slip, mistake: M3ConductorIdMistakes.heldWhenRight);
    }
    _tag(M3ConductorIdLines.caughtHold);
    shown = true;
    return const M3ConductorIdOutcome(M3ConductorIdVerdict.right);
  }

  /// The next job (after the reason).
  void next() {
    round++;
    rejected.clear();
    checked.clear();
    spotted.clear();
    shown = false;
  }
}

@immutable
class M3ConductorIdPack {
  const M3ConductorIdPack({required this.id, required this.titleBn, this.quickMs = 120000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3ConductorIdPack31 = M3ConductorIdPack(id: 'do_3_1_a', titleBn: M3ConductorIdLines.title);
const Map<String, M3ConductorIdPack> m3ConductorIdPacks = {'do_3_1_a': m3ConductorIdPack31};

// ============================================================================
// Page
// ============================================================================

class M3ConductorIdPage extends StatefulWidget {
  const M3ConductorIdPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3ConductorIdPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3ConductorIdPage> createState() => _M3ConductorIdPageState();
}

class _M3ConductorIdPageState extends State<M3ConductorIdPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CidRunPage(
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

class _CidRunPage extends ConsumerStatefulWidget {
  const _CidRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3ConductorIdPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CidRunPage> createState() => _CidRunPageState();
}

class _CidRunPageState extends ConsumerState<_CidRunPage> with DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3ConductorIdRun _run = M3ConductorIdRun(m3ConductorIdDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The drum the trainee is looking at close.
  M3ConductorIdDrum? _held;
  var _docketOpen = false;
  DoMistake? _card;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  M3ConductorIdPush _push = M3ConductorIdPush.nearest;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how to interact, never which drum).
  final _hints = IdleHintController();
  final Map<String, GlobalKey> _drumKeys = {};
  final _holdKey = GlobalKey();
  final _docketKey = GlobalKey();
  final _faceKey = GlobalKey();
  final _wrapKey = GlobalKey();
  final _putBackKey = GlobalKey();
  final _loadKey = GlobalKey();

  /// The hand has run along the held drum's wraps.
  var _wrapTouched = false;

  GlobalKey _drumKey(String id) => _drumKeys.putIfAbsent(id, GlobalKey.new);

  String get _rungId => widget.ctx.rungId;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice (never holds the player) -------------------------------------------

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

  String get _ask => M3ConductorIdLines.ask(_run.current.job.need);
  String get _task => _held == null ? _ask : M3ConductorIdLines.inspectAsk;

  // ---- flow -----------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([_ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || reasonOpen || tableBusy || _run.shown;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// The trainee walks up to a drum for the close look.
  void _pick(M3ConductorIdDrum d, Offset origin) {
    // Going to another drum while he is still talking refuses him too.
    if (coworkerOpen && !coworkerChoiceUp && _pushedDrum?.id != d.id) {
      unawaited(answerCoworker(true, origin, direct: true));
    }
    if (_blocked || coworkerOpen || _held != null || _docketOpen || _run.rejected.contains(d.id)) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.5, muted: false));
    _hush();
    setState(() {
      _held = d;
      _wrapTouched = false;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([M3ConductorIdLines.inspectAsk]));
  }

  void _sawCore() {
    final d = _held;
    if (d == null) return;
    setState(() => _run.sawCore(d));
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.6, muted: false));
  }

  bool _magnet() {
    final d = _held;
    if (d == null) return false;
    late bool stuck;
    setState(() => stuck = _run.magnet(d));
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue(stuck ? 'sounds/intro/impact_metal.ogg' : 'sounds/intro/drop.ogg', volume: 0.6, muted: false));
    unawaited(_sayChain([stuck ? M3ConductorIdLines.stuck : M3ConductorIdLines.fell]));
    return stuck;
  }

  /// A cut strand came into view under the hand.
  void _found() {
    final d = _held;
    if (d != null) _run.spot(d);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.6, muted: false));
  }

  void _putBack() {
    final d = _held;
    if (d == null || _blocked || coworkerOpen) return;
    // Setting a found cut drum aside decides it: he cuts in first if due.
    if (_run.spotted.contains(d.id) && _waitForCoworker()) return;
    final aside = _run.putBack(d);
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (aside) {
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
      unawaited(_sayChain([M3ConductorIdLines.asideCut, _ask], mood: GuideMood.glad));
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
      unawaited(_sayChain([_ask]));
    }
  }

  void _load(Offset origin) {
    final d = _held;
    if (d == null || _blocked || coworkerOpen) return;
    // Loading decides the job: he cuts in first if due (never skipped by a
    // fast play).
    if (_waitForCoworker()) return;
    setState(() => _held = null);
    _judgeLoad(d, origin);
  }

  void _judgeLoad(M3ConductorIdDrum d, Offset origin) {
    final o = _run.load(d);
    if (o.verdict == M3ConductorIdVerdict.right) {
      HapticFeedback.lightImpact();
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
        unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.4, muted: false));
      }
      setState(() => _setMode(LinemanMode.cheer));
      final k = d.kind;
      _askWhy(15, () => m3ConductorIdWhyDeal(M3ConductorIdLines.loadRight(k), M3ConductorIdLines.loadNear(k), M3ConductorIdLines.loadMyths, widget.rng),
          M3ConductorIdLines.loadAsk);
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  void _holdJob(Offset origin) {
    if (_blocked || coworkerOpen || _held != null || _docketOpen) return;
    if (_waitForCoworker()) return;
    _hush();
    final o = _run.holdJob();
    if (o.verdict == M3ConductorIdVerdict.right) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.cheer));
      _askWhy(20, () => m3ConductorIdWhyDeal(M3ConductorIdLines.holdRight, M3ConductorIdLines.holdNear, M3ConductorIdLines.holdRest, widget.rng),
          M3ConductorIdLines.holdAsk);
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  /// A decisive control waits for him ([holdForCoworker]), and his line fits
  /// what is in the hands: a found cut → "a strand cut, so what" (that drum);
  /// the other conductor → "take the one at hand" (that drum). Any other drum
  /// of the docket's conductor goes back in the row first, so "take the one
  /// at hand" plays in the yard and listening loads the nearest drum there.
  bool _waitForCoworker() {
    if (!coworkerDue) return false;
    final d = _held;
    if (d != null && d.kind == _run.current.job.need && !_run.spotted.contains(d.id)) {
      setState(() {
        _held = null;
        _wrapTouched = false;
        _setMode(LinemanMode.idle);
      });
    }
    return holdForCoworker();
  }

  void _askWhy(int points, List<ChoiceOption> Function() deal, String question) {
    putOnTable(points);
    final round = _run.round;
    unawaited(askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended));
  }

  void _nextRound() {
    final held = _run.loaded[_run.round] == null;
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() => _setMode(LinemanMode.idle));
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: false));
    _armCoworker();
    unawaited(_sayChain([if (held) M3ConductorIdLines.holdDone, _ask]));
  }

  void _openDocket() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: false));
    setState(() => _docketOpen = true);
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
  void onReasonPaid() => _nextRound();

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M3ConductorIdLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    // Never into the praise window or the reason deck of a right move.
    if (tableBusy || _run.shown) return false;
    // His push fits the moment: a cut strand only while the trainee holds the
    // drum whose cut he found (setting it aside or loading it); otherwise
    // "take the one at hand" (see [_waitForCoworker]). Chosen before the "not
    // yet" checks, so a decisive control that waits for him gets it too.
    final held = _held;
    final push = m3ConductorIdPushFor(_run.current, _run.rejected, held: held, spotted: _run.spotted);
    if (push == null) return false;
    _push = push;
    if (_blocked || held != null || _docketOpen) return false;
    return true;
  }

  /// The drum he is pushing now (the found cut drum or the other-conductor
  /// drum in the hands, else the nearest other-conductor drum in the row).
  M3ConductorIdDrum? get _pushedDrum => m3ConductorIdPushed(_run.current, _push, _run.rejected, held: _held, spotted: _run.spotted);

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Loaded what he pushed: the drum at hand / nearest, or the found cut
      // one in the hands — a slip (playbook row 8; nothing here is deadly).
      final d = _pushedDrum;
      if (_held != null) {
        setState(() {
          _held = null;
          _setMode(LinemanMode.idle);
        });
      }
      if (d != null) _judgeLoad(d, origin);
      return;
    }
    _run.caught.add(M3ConductorIdLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([M3ConductorIdLines.callHeld, _task], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3ConductorIdLines.tapWhy[_nudgeN++ % M3ConductorIdLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- gesture hints ------------------------------------------------------------------

  /// The on-screen rect of [k] (through the scene's scale).
  static Rect? _rectOf(GlobalKey k) {
    final box = k.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
  }

  /// The level waits for a touch on the scene (decks carry their own hint;
  /// none during a mistake card).
  bool get _hintWaiting =>
      !_intro && !_ended && !_busy && _card == null && _mark == null && !struckOut && !reasonOpen && !tableBusy && !coworkerOnScreen && !_run.shown;

  /// How to interact now — never which drum: a sweep over every drum still in
  /// the row and the store button; in the close look a rub on the cut face, a
  /// stroke along the wraps, then a sweep over put back / load; a tap to hang
  /// the docket back.
  HintSpec? _hint() {
    if (_docketOpen) {
      final r = _rectOf(_docketKey);
      return r == null ? null : HintSpec.tap(r.center);
    }
    final held = _held;
    if (held != null) {
      if (!_run.checked.contains(held.id)) {
        final f = _rectOf(_faceKey);
        return f == null ? null : HintSpec.swipe(Offset(f.left + f.width * 0.25, f.center.dy), travel: f.width * 0.5);
      }
      if (!_wrapTouched) {
        final w = _rectOf(_wrapKey);
        return w == null ? null : HintSpec.swipe(Offset(w.left + 16, w.center.dy), travel: math.min(w.width * 0.6, 160));
      }
      final opts = [?_rectOf(_putBackKey), ?_rectOf(_loadKey)];
      return opts.length < 2 ? null : HintSpec.sweep(opts);
    }
    final r = _run.current;
    final opts = [
      for (final d in r.drums)
        if (!_run.rejected.contains(d.id) && _run.loaded[_run.round]?.id != d.id) ?_rectOf(_drumKey(d.id)),
      ?_rectOf(_holdKey),
    ];
    return opts.length < 2 ? null : HintSpec.sweep(opts);
  }

  /// Which waiting state the hand is for (a new one resets its count).
  Object get _hintState => (_run.round, _held?.id, _docketOpen, _run.slips, _run.rejected.length, _run.checked.length, _wrapTouched);

  // ---- mistakes ---------------------------------------------------------------------

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() => _card = m);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('conductor_id/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _setMode(LinemanMode.idle);
    });
    unawaited(_sayChain([_ask]));
  }

  // ---- score and result ---------------------------------------------------------------

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
    _busy = true;
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
    await _say(!_run.passed ? M3ConductorIdLines.fail : (_quickBonus ? M3ConductorIdLines.quick : M3ConductorIdLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = M3ConductorIdGeo(m.height);
    final r = _run.current;
    final canPick = !_blocked && _held == null && !_docketOpen;
    final done = {for (var i = 0; i < _run.round; i++) i};
    final onVan = _run.loaded.entries.toList();
    return [
      Positioned.fill(
        key: const ValueKey('yard'),
        // A tap on the bare yard counts toward the gesture hint.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hints.missTap,
          child: RepaintBoundary(child: CustomPaint(painter: M3ConductorIdYardPainter(geo))),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('docket'),
        rect: geo.docket,
        child: _DocketSheet(deal: _run.deal, done: done, quiet: quiet, onTap: _openDocket),
      ),
      // What is loaded sits on the van's bed.
      for (var i = 0; i < onVan.length; i++)
        Positioned.fromRect(
          key: ValueKey('van-${onVan[i].value.id}'),
          rect: geo.loaded(i),
          child: _OnVan(quiet: quiet),
        ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      for (var i = 0; i < r.drums.length; i++)
        Positioned.fromRect(
          key: ValueKey('drum-${_run.round}-$i'),
          rect: geo.drum(i),
          child: DoDealIn(
            index: i,
            quiet: quiet,
            muted: true,
            child: _YardDrum(
              key: _drumKey(r.drums[i].id),
              drum: r.drums[i],
              gone: _run.loaded[_run.round]?.id == r.drums[i].id,
              aside: _run.rejected.contains(r.drums[i].id),
              chalk: _run.checked.contains(r.drums[i].id) ? r.drums[i].kind.tag : null,
              enabled: canPick,
              onTake: (at) => _pick(r.drums[i], at),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final holdUp = playing && _held == null && !_docketOpen && _card == null && !deckUp && !_run.shown && !coworkerOpen;
    final held = _held;
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
              labels: [for (final r in _run.deal.rounds) r.job.need.tag],
              done: {for (var i = 0; i < math.min(_run.round, _run.deal.rounds.length); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintState,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (holdUp)
                Positioned(
                  key: const ValueKey('hud-hold'),
                  left: 12,
                  right: 128,
                  bottom: pad.bottom + 18,
                  child: _HoldButton(key: _holdKey, onTapUp: (d) => _holdJob(d.globalPosition)),
                ),
              if (held != null && playing)
                _Inspect(
                  key: ValueKey('inspect-${held.id}'),
                  drum: held,
                  job: _run.current.job,
                  quiet: quiet,
                  onCore: _sawCore,
                  onMagnet: _magnet,
                  onFound: _found,
                  onLoad: _load,
                  onPutBack: _putBack,
                  onWrap: () {
                    if (!_wrapTouched) setState(() => _wrapTouched = true);
                  },
                  onMiss: _hints.missTap,
                  faceKey: _faceKey,
                  wrapKey: _wrapKey,
                  putBackKey: _putBackKey,
                  loadKey: _loadKey,
                ),
              if (_docketOpen && playing)
                _DocketZoom(
                  key: const ValueKey('docket-zoom'),
                  sheetKey: _docketKey,
                  deal: _run.deal,
                  done: {for (var i = 0; i < _run.round; i++) i},
                  quiet: quiet,
                  onClose: () => setState(() => _docketOpen = false),
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
              if (playing && _card == null && !_docketOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
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
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M3ConductorIdLines.intro,
                  alarm: 'sounds/van_arrive.wav',
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

const _paper = Color(0xFFF7F1E1);
const _ink = Color(0xFF1E2228);
const _brown = Color(0xFF8C6A2A);
const _grey = Color(0xFF5A6478);
const _bench = Color(0xFF26303B);

/// "1. AAAC" style numbering in English digits.
String _num(int i) => enDigits('${i + 1}.');

/// The docket on its clipboard: the three jobs and their conductor, the done
/// ones ticked.
class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.deal, required this.done, required this.quiet, required this.onTap});
  final M3ConductorIdDeal deal;
  final Set<int> done;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform.translate(offset: Offset(0, -30 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 6, 4, 4),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(2),
            border: const Border(top: BorderSide(color: Color(0xFF6E5A3A), width: 5)),
            boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(M3ConductorIdLines.docket, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: _brown, height: 1.1)),
              Container(height: 0.8, color: const Color(0x55B59B62), margin: const EdgeInsets.symmetric(vertical: 2)),
              for (var i = 0; i < deal.rounds.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(done.contains(i) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 8, color: done.contains(i) ? const Color(0xFF2E7D32) : _grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text('${_num(i)} ${deal.rounds[i].job.need.tag}',
                            maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: _ink, height: 1.2)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 2),
              for (var i = 0; i < deal.rounds.length; i++)
                Text(deal.rounds[i].job.whereBn,
                    maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 5.5, fontWeight: FontWeight.w700, color: _grey, height: 1.25)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The docket held up close (tap anywhere to hang it back).
class _DocketZoom extends StatelessWidget {
  const _DocketZoom({super.key, required this.sheetKey, required this.deal, required this.done, required this.quiet, required this.onClose});
  final GlobalKey sheetKey;
  final M3ConductorIdDeal deal;
  final Set<int> done;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
              child: Container(
                key: sheetKey,
                width: 300,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB59B62), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: _brown, size: 22),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('${M3ConductorIdLines.docket} · ${M3ConductorIdLines.yardBn}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0x55B59B62), height: 14),
                    for (var i = 0; i < deal.rounds.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(done.contains(i) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                size: 20, color: done.contains(i) ? const Color(0xFF2E7D32) : _grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_num(i)} ${deal.rounds[i].job.feederBn}', style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: _ink, height: 1.3)),
                                  Text(deal.rounds[i].job.whereBn, style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: _grey, height: 1.3)),
                                  Text('${M3ConductorIdLines.needWord}: ${deal.rounds[i].job.need.tag}',
                                      style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: _brown, height: 1.35)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A drum standing in the row. Its tag is weathered blank; once the trainee
/// has identified it, his chalk mark says what it is; one he set aside wears
/// a red বাতিল tag. Tap it to walk up for the close look.
class _YardDrum extends StatelessWidget {
  const _YardDrum({super.key, required this.drum, required this.gone, required this.aside, required this.chalk, required this.enabled, required this.onTake});
  final M3ConductorIdDrum drum;
  final bool gone;
  final bool aside;
  final String? chalk;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  Widget build(BuildContext context) {
    if (gone) return Semantics(label: M3ConductorIdLines.drumLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: M3ConductorIdLines.drumLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled && !aside ? (d) => onTake(d.globalPosition) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: M3ConductorIdDrumPainter(gone: aside))),
            if (chalk != null && !aside)
              Positioned(
                left: 6,
                top: 18,
                child: Transform.rotate(
                  angle: -0.12,
                  child: Text(chalk!,
                      style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xF2FFFFFF), height: 1).copyWith(shadows: const [Shadow(color: Color(0x66000000), blurRadius: 1)])),
                ),
              ),
            if (aside)
              Positioned(
                left: 0,
                right: 0,
                top: 40,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(3)),
                    child: Text(M3ConductorIdLines.rejected, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A loaded drum on the van's bed.
class _OnVan extends StatelessWidget {
  const _OnVan({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(0, -40 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: const CustomPaint(painter: M3ConductorIdDrumPainter()),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1A33),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x66FFB547))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store_rounded, size: 18, color: SlmColors.warning),
              const SizedBox(width: 8),
              Flexible(
                child: Text(M3ConductorIdLines.hold,
                    textAlign: TextAlign.center, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The close look, hands on: the free end's cut face (rub the grime off to
/// see the centre; touch the magnet to it) and the outer wraps (run a hand
/// along them — a cut strand shows only where the hand has been). Then load
/// it on the van or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.drum,
    required this.job,
    required this.quiet,
    required this.onCore,
    required this.onMagnet,
    required this.onFound,
    required this.onLoad,
    required this.onPutBack,
    required this.onWrap,
    required this.onMiss,
    required this.faceKey,
    required this.wrapKey,
    required this.putBackKey,
    required this.loadKey,
  });
  final M3ConductorIdDrum drum;
  final M3ConductorIdJob job;
  final bool quiet;
  final VoidCallback onCore;
  final bool Function() onMagnet;
  final VoidCallback onFound;
  final ValueChanged<Offset> onLoad;
  final VoidCallback onPutBack;

  /// The hand first ran along the wraps.
  final VoidCallback onWrap;

  /// A tap on the dark backdrop (nothing there).
  final VoidCallback onMiss;
  final GlobalKey faceKey;
  final GlobalKey wrapKey;
  final GlobalKey putBackKey;
  final GlobalKey loadKey;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _cleared = {};
  final Set<int> _seen = {};
  Offset? _rub;
  Offset? _hand;
  var _core = false;
  var _found = false;
  bool? _stuck;

  void _rubAt(Offset p, Size s) {
    final cell = M3ConductorIdEndPainter.cellAt(s, p);
    const g = kM3ConductorIdGrid;
    final row = cell ~/ g;
    final col = cell % g;
    final before = _cleared.length;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final r = row + dr;
        final c = col + dc;
        if (r >= 0 && r < g && c >= 0 && c < g) _cleared.add(r * g + c);
      }
    }
    if (!_core && M3ConductorIdEndPainter.coreSeen(_cleared)) {
      _core = true;
      widget.onCore();
    }
    if (_cleared.length != before || _rub != p) setState(() => _rub = p);
  }

  void _touch(Offset p, Size s) {
    final b = m3ConductorIdBin(M3ConductorIdWrapPainter.uAt(s, p.dx));
    if (_seen.isEmpty) widget.onWrap();
    final before = _seen.length;
    for (final x in [b - 1, b, b + 1]) {
      if (x >= 0 && x < kM3ConductorIdBins) _seen.add(x);
    }
    if (!_found && M3ConductorIdWrapPainter.cutSeen(widget.drum.cutU, _seen)) {
      _found = true;
      widget.onFound();
    }
    if (_seen.length != before || _hand != p) setState(() => _hand = p);
  }

  void _magnet() {
    if (_stuck != null) return;
    setState(() => _stuck = widget.onMagnet());
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4, left: 2),
        child: Text(t, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: _ink, height: 1.1)),
      );

  Widget _face() => LayoutBuilder(builder: (context, box) {
        final side = box.maxHeight;
        final s = Size(side, side);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: side,
              height: side,
              child: Semantics(
                key: widget.faceKey,
                label: M3ConductorIdLines.faceLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (d) => _rubAt(d.localPosition, s),
                  onPanUpdate: (d) => _rubAt(d.localPosition, s),
                  onPanEnd: (_) => setState(() => _rub = null),
                  onPanCancel: () => setState(() => _rub = null),
                  child: CustomPaint(painter: M3ConductorIdEndPainter(layout: widget.drum.layout, cleared: _cleared)),
                ),
              ),
            ),
            if (_cleared.isEmpty) _Puck(at: Offset(side * 0.5, side * 0.5)),
            if (_rub != null) _Puck(at: _rub!, live: true),
            // The magnet: at rest on the right; tapped, it goes to the face.
            _MagnetLane(left: side, width: box.maxWidth - side, faceRight: side * 0.96, height: side, stuck: _stuck, quiet: widget.quiet, onTap: _magnet),
          ],
        );
      });

  Widget _wrap() => LayoutBuilder(builder: (context, box) {
        final s = Size(box.maxWidth, box.maxHeight);
        return Semantics(
          key: widget.wrapKey,
          label: M3ConductorIdLines.wrapLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (d) => _touch(d.localPosition, s),
            onPanUpdate: (d) => _touch(d.localPosition, s),
            onPanEnd: (_) => setState(() => _hand = null),
            onPanCancel: () => setState(() => _hand = null),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: CustomPaint(painter: M3ConductorIdWrapPainter(cutU: widget.drum.cutU, seen: _seen))),
                if (_seen.isEmpty) _Puck(at: Offset(M3ConductorIdWrapPainter.xAt(s, 0.06), s.height * 0.5)),
                if (_hand != null) _Puck(at: _hand!, live: true),
              ],
            ),
          ),
        );
      });

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onMiss, child: const ColoredBox(color: Color(0xC0050A16))),
          ),
          Align(
          alignment: const Alignment(0, -0.42),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.translate(
              offset: Offset(0, 80 * (1 - v)),
              child: Transform.scale(scale: 0.85 + 0.15 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                    decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFB59B62))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: _brown, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('${M3ConductorIdLines.docket} · ${M3ConductorIdLines.needWord}: ${j.need.tag}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _label(M3ConductorIdLines.faceLabel),
                  AspectRatio(
                    aspectRatio: 2.1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4654), _bench]),
                      ),
                      child: Padding(padding: const EdgeInsets.all(8), child: _face()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _label(M3ConductorIdLines.wrapLabel),
                  AspectRatio(
                    aspectRatio: 4.4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A6A48), Color(0xFF6B4E33)]),
                      ),
                      child: Padding(padding: const EdgeInsets.fromLTRB(4, 2, 4, 2), child: _wrap()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: KeyedSubtree(
                              key: widget.putBackKey, child: DoBigButton(label: M3ConductorIdLines.putBack, filled: false, onTapUp: (_) => widget.onPutBack()))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: KeyedSubtree(
                              key: widget.loadKey, child: DoBigButton(label: M3ConductorIdLines.load, filled: true, onTapUp: (d) => widget.onLoad(d.globalPosition)))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

/// The magnet's lane beside the cut face: tap it and it slides to the face —
/// it clings to steel (ACSR) or slips off and drops (AAAC).
class _MagnetLane extends StatelessWidget {
  const _MagnetLane({
    required this.left,
    required this.width,
    required this.faceRight,
    required this.height,
    required this.stuck,
    required this.quiet,
    required this.onTap,
  });
  final double left;
  final double width;
  final double faceRight;
  final double height;
  final bool? stuck;
  final bool quiet;
  final VoidCallback onTap;

  static const _mw = 54.0;
  static const _mh = 34.0;

  @override
  Widget build(BuildContext context) {
    final restX = left + width - _mw - 6;
    final restY = height * 0.5 - _mh / 2;
    final touchX = faceRight - 4;
    Widget magnet(double x, double y, double opacity) => Positioned(
          left: x,
          top: y,
          width: _mw,
          height: _mh,
          child: Opacity(opacity: opacity, child: const CustomPaint(painter: M3ConductorIdMagnetPainter())),
        );
    final s = stuck;
    return Positioned(
      left: 0,
      top: 0,
      width: left + width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (s == null)
            Positioned(
              left: left,
              top: 0,
              width: width,
              height: height,
              child: Semantics(
                button: true,
                label: M3ConductorIdLines.magnetLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Align(
                    alignment: const Alignment(0.6, 0.95),
                    child: Text(M3ConductorIdLines.magnetLabel, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                  ),
                ),
              ),
            ),
          if (s == null)
            IgnorePointer(child: Stack(clipBehavior: Clip.none, children: [magnet(restX, restY, 1)]))
          else
            TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 900),
              builder: (_, t, _) {
                final go = Curves.easeIn.transform((t / 0.45).clamp(0.0, 1.0));
                final x = restX + (touchX - restX) * go;
                if (s) return Stack(clipBehavior: Clip.none, children: [magnet(x, restY, 1)]);
                // Slips off the alloy and drops.
                final fall = Curves.easeIn.transform(((t - 0.5) / 0.5).clamp(0.0, 1.0));
                return Stack(clipBehavior: Clip.none, children: [magnet(x + 14 * fall, restY + height * 0.5 * fall, 1 - 0.5 * fall)]);
              },
            ),
        ],
      ),
    );
  }
}

class _Puck extends StatelessWidget {
  const _Puck({required this.at, this.live = false});
  final Offset at;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 22.0 : 17.0;
    return Positioned(
      left: at.dx - r,
      top: at.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0x55FF851B) : const Color(0x33FF851B),
            border: Border.all(color: const Color(0xFFFF851B), width: live ? 2 : 1.4),
          ),
          child: Icon(Icons.back_hand_rounded, size: r * 1.05, color: const Color(0xFFB4560E)),
        ),
      ),
    );
  }
}
