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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm3_conductor_joint_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 3.1 "কন্ডাক্টর পরিচিতি: ACSR, AAAC", কাজ 2 "জোড় ঠিক তো?" (pack
// do_3_1_b, engineType m3_conductor_joint). Pure rules: the deal, the play
// state, the lines and the mistakes. The scene is m3_conductor_joint_world.dart.
//
// The site: a span under shutdown and earthed (shown in the scene, not a move
// here); one phase broke and both ends lie on a tarp. Two joints to make (one
// ACSR, one AAAC) and one tray of finished joints to judge.
//
// The lesson's rules, and only those (plus the film's corrected wording):
//   • point 2/3/4: a magnet sticks to ACSR (steel core), not to AAAC; check
//     at the site before starting, never guess ("আন্দাজে ঢিল মারবে না");
//   • point 4 + pro tip 3: ACSR and AAAC joint sleeves differ — match the
//     code on the sleeve with the conductor's code; a wrong sleeve → a
//     hotspot in days and the line cut and down. Film line 7: the joint goes
//     loose and hot; the steel core not gripped → the line breaks and falls
//     (NOT the lesson's "galvanic corrosion" — the film's fix);
//   • pro tip 1: code names Dog, Rabbit, Panther (the docket names one);
//   • pro tip 2: not one strand cut — the line weakens and breaks there;
//   • point 2 daily check: at a joint, no rust on the inner steel;
//   • myths: "any connector will do" (film: the diameter and the metal
//     differ); "thicker carries more" (film: ampacity depends on the real
//     aluminium cross-section, the metal and the weather) — wrong reasons.
// From other lessons (flagged in REGISTER.md): brushing the ends clean (2.3's
// "clean the conductor"); the conductor fully into the sleeve (2.3's "insert
// fully"); pumping the compressor until its pressure valve clicks (2.9 pro
// tip 2). Left out: the compression die, how many bites a sleeve takes, the
// two-part ACSR sleeve (steel + aluminium), re-tensioning.
// No deadly move: the line is shut down and earthed; the lesson's harm from a
// bad joint is a hotspot later (shown as the joint glowing under load).

/// What the conductor is (the magnet tells).
enum M3ConductorJointType {
  acsr,
  aaac;

  M3ConductorJointType get other => this == acsr ? aaac : acsr;
}

/// The lesson's code names.
enum M3ConductorJointCode { rabbit, dog, panther }

/// The steps of a joint (the tray, dealt in a fresh order every round).
enum M3ConductorJointStep { magnet, sleeve, brush, insert, press }

/// A finished joint on the inspection tray.
enum M3ConductorJointKind { good, wrongSleeve, cutStrand, halfPress }

/// A joint sleeve as printed on it.
@immutable
class M3ConductorJointSleeve {
  const M3ConductorJointSleeve(this.type, this.code);
  final M3ConductorJointType type;
  final M3ConductorJointCode code;

  @override
  bool operator ==(Object other) => other is M3ConductorJointSleeve && other.type == type && other.code == code;
  @override
  int get hashCode => Object.hash(type, code);
  @override
  String toString() => '${type.name}-${code.name}';
}

/// One joint to make: the broken conductor and the sleeves in the kit.
@immutable
class M3ConductorJointJob {
  const M3ConductorJointJob({required this.type, required this.code, required this.sleeves});
  final M3ConductorJointType type;
  final M3ConductorJointCode code;

  /// Three sleeves: the right one, the other type's of the same code, and
  /// the same type's of another code (in a dealt order).
  final List<M3ConductorJointSleeve> sleeves;

  M3ConductorJointSleeve get right => M3ConductorJointSleeve(type, code);
}

/// A finished joint on the tray: the conductor's tag and how it was made.
@immutable
class M3ConductorJointSample {
  const M3ConductorJointSample(this.kind, this.type, this.code);
  final M3ConductorJointKind kind;
  final M3ConductorJointType type;
  final M3ConductorJointCode code;

  @override
  String toString() => '${kind.name}/${type.name}/${code.name}';
}

/// One round: a joint to make ([job]) or a tray to judge ([samples]).
@immutable
class M3ConductorJointRound {
  const M3ConductorJointRound.make(M3ConductorJointJob this.job) : samples = const [];
  const M3ConductorJointRound.inspect(this.samples) : job = null;
  final M3ConductorJointJob? job;
  final List<M3ConductorJointSample> samples;
  bool get inspect => job == null;
}

@immutable
class M3ConductorJointDeal {
  const M3ConductorJointDeal({required this.rounds, required this.callAt});
  final List<M3ConductorJointRound> rounds;

  /// The make-round where the careless coworker comes (at the press).
  final int callAt;
}

/// The kit for a job: the right sleeve and two near misses, shuffled.
M3ConductorJointJob m3ConductorJointJob(M3ConductorJointType type, M3ConductorJointCode code, math.Random rng) {
  final others = [...M3ConductorJointCode.values.where((c) => c != code)]..shuffle(rng);
  final sleeves = [
    M3ConductorJointSleeve(type, code),
    M3ConductorJointSleeve(type.other, code),
    M3ConductorJointSleeve(type, others.first),
  ]..shuffle(rng);
  return M3ConductorJointJob(type: type, code: code, sleeves: sleeves);
}

/// Three rounds: two joints to make (one ACSR, one AAAC, in either order;
/// different codes), and one tray of four finished joints to judge (the 2nd
/// or the 3rd round): one or two good, the rest bad of different kinds. The
/// coworker comes on one of the two make-rounds.
M3ConductorJointDeal m3ConductorJointDeal(math.Random rng) {
  final types = [...M3ConductorJointType.values]..shuffle(rng);
  final codes = [...M3ConductorJointCode.values]..shuffle(rng);
  final good = 1 + rng.nextInt(2);
  final bad = [M3ConductorJointKind.wrongSleeve, M3ConductorJointKind.cutStrand, M3ConductorJointKind.halfPress]..shuffle(rng);
  final kinds = [for (var i = 0; i < good; i++) M3ConductorJointKind.good, ...bad.take(4 - good)]..shuffle(rng);
  M3ConductorJointSample sample(M3ConductorJointKind k) => M3ConductorJointSample(
        k,
        M3ConductorJointType.values[rng.nextInt(2)],
        M3ConductorJointCode.values[rng.nextInt(3)],
      );
  final rounds = <M3ConductorJointRound>[
    M3ConductorJointRound.make(m3ConductorJointJob(types[0], codes[0], rng)),
    M3ConductorJointRound.make(m3ConductorJointJob(types[1], codes[1], rng)),
  ];
  final at = 1 + rng.nextInt(2);
  rounds.insert(at, M3ConductorJointRound.inspect([for (final k in kinds) sample(k)]));
  final makes = [
    for (final (i, r) in rounds.indexed)
      if (!r.inspect) i,
  ];
  return M3ConductorJointDeal(rounds: rounds, callAt: makes[rng.nextInt(2)]);
}

/// The play state (pure logic).
class M3ConductorJointRun {
  M3ConductorJointRun(this.deal);
  final M3ConductorJointDeal deal;
  int index = 0;
  int slips = 0;
  final List<String> caught = [];

  // A make-round.
  var magnetDone = false;
  M3ConductorJointSleeve? sleeve;
  var brushed = false;

  /// How far both ends are in the sleeve (0–1; 1 = they meet at the centre).
  double inserted = 0;
  var pressed = false;

  /// Slips on this round (a clean round earns the +5).
  int roundSlips = 0;

  // The inspection.
  final Set<int> rejected = {};

  /// The round is over (the reason or the card is up).
  var shown = false;

  bool get done => index >= deal.rounds.length;
  M3ConductorJointRound get current => deal.rounds[index.clamp(0, deal.rounds.length - 1)];
  M3ConductorJointJob get job => current.job!;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get fullyIn => inserted >= 1;
  bool get thorough => roundSlips == 0;
  bool get _open => !done && !shown;
  bool get _make => _open && !current.inspect;

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    if (M3ConductorJointMistakes.ruins.contains(m)) shown = true;
    return m;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// The magnet on the conductor: true = it sticks (ACSR). null = nothing
  /// to do (done already, or not a make-round).
  bool? magnet() {
    if (!_make || magnetDone) return null;
    magnetDone = true;
    return job.type == M3ConductorJointType.acsr;
  }

  /// Open the kit to pick a sleeve: only after the magnet test.
  DoMistake? openKit() {
    if (!_make || inserted > 0) return null;
    if (!magnetDone) return _slip(M3ConductorJointMistakes.guess);
    return null;
  }

  void pickSleeve(M3ConductorJointSleeve s) {
    if (_make && inserted == 0 && magnetDone) sleeve = s;
  }

  /// The wire brush over both ends. true = it brushed now.
  bool brush() {
    if (!_make || brushed || inserted > 0) return false;
    brushed = true;
    return true;
  }

  /// May the ends go in now? null = yes.
  DoMistake? startInsert() {
    if (!_make) return null;
    if (sleeve == null) return _slip(M3ConductorJointMistakes.noSleeve);
    if (!brushed) return _slip(M3ConductorJointMistakes.noClean);
    return null;
  }

  void setInserted(double v) {
    if (_make && sleeve != null && brushed && !pressed) inserted = v.clamp(0.0, 1.0);
  }

  /// May the compressor go on now? null = yes (then [press]).
  DoMistake? startPress() {
    if (!_make || pressed) return null;
    if (sleeve == null) return _slip(M3ConductorJointMistakes.noSleeve);
    if (!fullyIn) return _slip(M3ConductorJointMistakes.notIn);
    return null;
  }

  /// The pumping ends at [reached] of the cycle (1 = the valve clicked).
  /// null = a right joint (the round is [shown]).
  DoMistake? press(double reached) {
    if (!_make || pressed || sleeve == null || !fullyIn) return null;
    if (reached < 1) return _slip(M3ConductorJointMistakes.halfPress);
    final s = sleeve!;
    if (s.type != job.type) return _slip(M3ConductorJointMistakes.wrongType);
    if (s.code != job.code) return _slip(M3ConductorJointMistakes.wrongCode);
    pressed = true;
    shown = true;
    _tag(M3ConductorJointLines.caughtMagnet);
    _tag(M3ConductorJointLines.caughtSleeve);
    _tag(M3ConductorJointLines.caughtPress);
    return null;
  }

  /// Let off half-pressed (listened to the coworker).
  DoMistake loose() => _slip(M3ConductorJointMistakes.loose);

  /// A bad joint was made: cut it out and start this job again (the magnet
  /// result stays known).
  void redo() {
    sleeve = null;
    brushed = pressed = false;
    inserted = 0;
    shown = false;
  }

  // --- the inspection ---------------------------------------------------------
  void toggle(int i) {
    if (!_open || !current.inspect) return;
    if (!rejected.remove(i)) rejected.add(i);
  }

  List<int> get falseRejects => [
        for (final i in rejected)
          if (current.samples[i].kind == M3ConductorJointKind.good) i,
      ]..sort();

  List<int> get missed => [
        for (final (i, s) in current.samples.indexed)
          if (s.kind != M3ConductorJointKind.good && !rejected.contains(i)) i,
      ];

  /// The tray is judged once (no free probes): a bad joint let through or a
  /// good joint thrown out is one slip however many — the card names the
  /// first bad joint let through, else the good one rejected. null = right.
  DoMistake? passTray() {
    if (!_open || !current.inspect) return null;
    shown = true;
    final m = missed;
    if (m.isNotEmpty || falseRejects.isNotEmpty) {
      slips++;
      roundSlips++;
      return m.isNotEmpty ? M3ConductorJointMistakes.passed(current.samples[m.first].kind) : M3ConductorJointMistakes.rejectedGood;
    }
    for (final s in current.samples) {
      if (s.kind != M3ConductorJointKind.good) _tag(M3ConductorJointLines.caughtKind(s.kind));
    }
    return null;
  }

  void next() {
    index++;
    redo();
    magnetDone = false;
    roundSlips = 0;
    rejected.clear();
  }
}

abstract final class M3ConductorJointLines {
  static const title = 'জোড় ঠিক তো?';
  static const intro = 'লাইন শাটডাউন, আর্থ করা। ছেঁড়া তারে জোড় দিন — ঠিক স্লিভ, পুরো চাপ!';
  static const rounds = ['ক', 'খ', 'গ'];
  static const askMake = 'ছেঁড়া তারের দুই মুখ তৈরি। ধাপে ধাপে জোড় দিন।';
  static const askInspect = 'এই জোড়গুলো দেখুন। খারাপগুলো বাতিল করুন।';
  static const askKit = 'কোন স্লিভ লাগাবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askMake, askInspect];

  static String stepBn(M3ConductorJointStep s) => switch (s) {
        M3ConductorJointStep.magnet => 'চুম্বক',
        M3ConductorJointStep.sleeve => 'স্লিভ',
        M3ConductorJointStep.brush => 'ব্রাশ',
        M3ConductorJointStep.insert => 'ঢোকান',
        M3ConductorJointStep.press => 'চাপ দিন',
      };
  static const holdInsert = 'চেপে ঠেলুন';
  static const holdPress = 'পাম্প করুন';
  static const trayDone = 'পরীক্ষা শেষ';
  static const reject = 'বাতিল';
  static const docketHead = 'ডকেট';

  static String typeEn(M3ConductorJointType t) => t == M3ConductorJointType.acsr ? 'ACSR' : 'AAAC';
  static String codeName(M3ConductorJointCode c) => c.name.toUpperCase();
  static String sleevePrint(M3ConductorJointSleeve s) => '${typeEn(s.type)} ${codeName(s.code)}';
  static String tagPrint(M3ConductorJointType t, M3ConductorJointCode c) => '${typeEn(t)} ${codeName(c)}';

  static const stampDone = 'জোড় হলো';
  static const stampTray = 'বাছাই হলো';

  // The reasons (lesson 3.1 + the film): every card 37–46 letters.
  static const whyMake = 'এই জোড় এভাবে কেন দিলেন?';
  static const whyTray = 'কেন এগুলো বাতিল করলেন?';
  static const acsrWhy = [
    'চুম্বকে আটকাল, তাই ACSR — স্লিভও ACSR-এর',
    'ACSR-এর পেটে স্টিল কোর, তাই চুম্বক আটকায়',
  ];
  static const aaacWhy = [
    'চুম্বক আটকাল না, তাই AAAC — স্লিভও AAAC-এর',
    'AAAC-তে স্টিল নেই, তাই চুম্বক আটকায় না',
  ];
  static const makeWhy = [
    'স্লিভের কোড আর তারের কোড মিলিয়েই জোড়',
    'ভুল স্লিভে জোড় ঢিলে হয়ে গরম হয়, লাইন ছেঁড়ে',
    'ACSR আর AAAC-এর জয়েন্ট স্লিভ আলাদা হয়',
  ];
  static const trayWhy = [
    'একটা স্ট্র্যান্ড কাটলেও লাইনের শক্তি কমে যায়',
    'ঢিলে জোড়ে ক\'দিনেই হটস্পট, লাইন কেটে পড়ে',
    'স্লিভের লেখা আর তারের ট্যাগ না মিললে বাতিল',
  ];

  /// Wrong reasons: the lesson's myths and field excuses (never a true rule).
  static const myths = [
    'সব তো অ্যালুমিনিয়ামই, যেকোনো স্লিভেই চলে',
    'তার মোটা দেখালেই বেশি কারেন্ট নেয়, ব্যস',
    'একটু ঢিলে থাকলে কিছু হয় না, কারেন্ট চলবে',
    'একটা স্ট্র্যান্ড কাটলে কিছু যায় আসে না',
    'চুম্বক লাগে না, তার দেখেই বোঝা যায় সব',
    'আন্দাজে স্লিভ নিলেও শেষে ঠিক হয়ে যায়',
    'কোড না মিললেও স্লিভ ঢুকে গেলেই জোড় পাকা',
  ];

  /// Wrong reasons naming the job's own type, each the mirror of the right
  /// card at the same place in [acsrWhy] + [makeWhy] (and [aaacWhy] +
  /// [makeWhy]): it carries that card's key words (চুম্বক, কোড, the type
  /// names), so no word is on the right card alone.
  static const acsrMyths = [
    'চুম্বক আটকালেও ACSR-এ যেকোনো স্লিভই চলে',
    'ACSR-এর ভেতরে স্টিল নেই, চুম্বক আটকায় না',
    'ACSR হলেই হলো, স্লিভের কোড মেলানো লাগে না',
    'ACSR-এ ভুল স্লিভ দিলেও জোড় গরম হয় না, চলে',
    'ACSR-এ AAAC-এর স্লিভ দিলেও জোড় ঠিক ধরে',
  ];
  static const aaacMyths = [
    'চুম্বক না আটকালেও AAAC-এ যেকোনো স্লিভ চলে',
    'AAAC-তেও স্টিল আছে, তাই চুম্বক আটকায়',
    'AAAC হলেই হলো, স্লিভের কোড মেলানো লাগে না',
    'AAAC-এ ভুল স্লিভ দিলেও জোড় গরম হয় না, চলে',
    'AAAC-এ ACSR-এর স্লিভ দিলেও জোড় ঠিক ধরে',
  ];

  /// Wrong reasons for the tray, each the mirror of the [trayWhy] card at the
  /// same place (স্ট্র্যান্ড, হটস্পট, ট্যাগ + বাতিল).
  static const trayMyths = [
    'কাটা স্ট্র্যান্ড স্লিভে ঢেকে গেলে আর ভয় নেই',
    'ঢিলে জোড়েও হটস্পট হয় না, ক\'দিন দিব্যি চলে',
    'স্লিভের লেখা আর ট্যাগ না মিললেও বাতিল নয়',
  ];

  /// Which bad kind each [trayWhy] card names.
  static const trayWhyKinds = [
    M3ConductorJointKind.cutStrand,
    M3ConductorJointKind.halfPress,
    M3ConductorJointKind.wrongSleeve,
  ];

  /// (right card, its mirror) pairs for [r]. The tray's only name the bad
  /// kinds actually on the tray.
  static List<(String, String)> whyPairs(M3ConductorJointRound r) {
    if (r.inspect) {
      final kinds = {for (final s in r.samples) s.kind};
      return [
        for (var i = 0; i < trayWhy.length; i++)
          if (kinds.contains(trayWhyKinds[i])) (trayWhy[i], trayMyths[i]),
      ];
    }
    final acsr = r.job!.type == M3ConductorJointType.acsr;
    final right = [...(acsr ? acsrWhy : aaacWhy), ...makeWhy];
    final own = acsr ? acsrMyths : aaacMyths;
    return [for (var i = 0; i < right.length; i++) (right[i], own[i])];
  }

  static List<String> whyRight(M3ConductorJointRound r) => [for (final p in whyPairs(r)) p.$1];

  /// The round's own wrong reasons (the tray's, or the job's type's).
  static List<String> whyWrongOwn(M3ConductorJointRound r) {
    if (r.inspect) return trayMyths;
    return r.job!.type == M3ConductorJointType.acsr ? acsrMyths : aaacMyths;
  }

  /// The reason deck: one right card, its mirror (a wrong card in the round's
  /// own words with the same key words) and one general myth, shuffled.
  static List<ChoiceOption> dealWhy(M3ConductorJointRound r, math.Random rng) {
    final pairs = whyPairs(r);
    final (right, mirror) = pairs[rng.nextInt(pairs.length)];
    return [
      ChoiceOption(right, true),
      ChoiceOption(mirror, false),
      ChoiceOption(myths[rng.nextInt(myths.length)], false),
    ]..shuffle(rng);
  }

  /// The careless coworker: let it off half-pressed (the seed's "একটু ঢিলে").
  /// He comes once both ends are fully in, as the compressor is next (the
  /// press waits for him). His push has no clip yet (silent, caption held);
  /// his snarl is recorded. No refusal starts with a giveaway word.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'একটু ঢিলে থাকলে কিছু হয় না! অর্ধেক চাপেই ছেড়ে দাও।',
    exitLine: coworkerExit,
    right: ['ভালভ ক্লিক না করা পর্যন্ত চাপ দিয়ে যাব', 'ঢিলে জোড় গরম হয়ে ক\'দিনেই কেটে পড়ে', 'পুরো চাপ না দিলে জোড় ঠিক ধরে না'],
    wrong: ['অর্ধেক চাপেই যথেষ্ট, এখনই ছেড়ে দিই', 'একটু ঢিলে থাকলে কিছু হবে না, ছাড়ি', 'লাইন তো চলবে, এত চাপের দরকার নেই', 'সবাই তো তাড়াতাড়ি ছেড়ে দেয়, আমিও দিই', 'পরে দরকার হলে না হয় আবার চাপ দেব'],
    asks: ['ও বলছে একটু ঢিলেই চলবে। আপনি কী করবেন?', 'পুরো চাপ দেবেন, না ওর কথায় ছেড়ে দেবেন?', 'ওর কথা শুনবেন, না পাঠের?'],
  );

  static const callHeld = 'ঠিক! ঢিলে জোড় মানেই গরম জোড় — পুরো চাপ।';
  static const redo = 'এই জোড় কেটে বাদ দিন। নতুন করে, ধাপে ধাপে।';
  static const allSet = 'জোড় শিখে গেছেন — চুম্বক, কোড মিলিয়ে স্লিভ, পুরো ঢোকানো, পুরো চাপ।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ACSR, AAAC আর তাদের স্লিভ পাঠে দেখে নিন, তারপর জোড়।';

  // "আজ যা ধরলেন".
  static const caughtMagnet = 'চুম্বকে তার চিনেছেন';
  static const caughtSleeve = 'কোড মিলিয়ে ঠিক স্লিভ';
  static const caughtPress = 'পুরো ঢোকানো, পুরো চাপ';
  static const caughtCall = '“একটু ঢিলে”-কে “না” বলেছেন';
  static String caughtKind(M3ConductorJointKind k) => switch (k) {
        M3ConductorJointKind.wrongSleeve => 'ভুল স্লিভের জোড় ধরেছেন',
        M3ConductorJointKind.cutStrand => 'কাটা স্ট্র্যান্ড ধরেছেন',
        M3ConductorJointKind.halfPress => 'আধা চাপের জোড় ধরেছেন',
        M3ConductorJointKind.good => '',
      };

  /// Every fixed guide line (for recording).
  static List<String> get guideLines => [
        intro,
        askMake,
        askInspect,
        askKit,
        ...tapWhy,
        whyMake,
        whyTray,
        ...coworker.asks,
        callHeld,
        redo,
        allSet,
        quick,
        fail,
        for (final m in M3ConductorJointMistakes.all) m.textBn,
      ];
}

abstract final class M3ConductorJointMistakes {
  static const _dir = 'assets/game/art/m3_conductor_joint';
  static const guess = DoMistake(
    key: '3.1/m3_conductor_joint/guess',
    textBn: 'আন্দাজে ঢিল নয়! আগে তারে চুম্বক ছোঁয়ান — আটকালে ACSR, না আটকালে AAAC। তারপর সেই মতো স্লিভ।',
    art: '$_dir/joint_magnet.svg',
    lessonPoint: 3,
  );
  static const noSleeve = DoMistake(
    key: '3.1/m3_conductor_joint/no-sleeve',
    textBn: 'আগে ঠিক স্লিভ বেছে নিন — স্লিভের গায়ে লেখা কোড আর তারের কোড মিলিয়ে।',
    art: '$_dir/joint_code.svg',
    lessonPoint: 3,
  );
  static const noClean = DoMistake(
    key: '3.1/m3_conductor_joint/no-clean',
    textBn: 'ঢোকানোর আগে দুই মুখ ব্রাশে পরিষ্কার করে দেখুন — একটা স্ট্র্যান্ডও যেন কাটা না থাকে, ACSR হলে ভেতরের স্টিলে যেন জং না থাকে।',
    art: '$_dir/joint_clean.svg',
    lessonPoint: 1,
  );
  static const notIn = DoMistake(
    key: '3.1/m3_conductor_joint/not-fully-in',
    textBn: 'তার পুরো ঢোকেনি — জোড় ঢিলে হয়ে গরম হবে; ঠিকমতো ধরা না পড়লে লাইন ছিঁড়ে মাটিতে পড়বে। দুই দিক পুরো ঢোকান।',
    art: '$_dir/joint_not_in.svg',
    lessonPoint: 3,
  );
  static const halfPress = DoMistake(
    key: '3.1/m3_conductor_joint/half-press',
    textBn: 'চাপ অর্ধেক — জোড় ঢিলে থেকে গরম হবে। পাম্প চালিয়ে যান, যতক্ষণ না ভালভ নিজে থেকে ক্লিক করে।',
    art: '$_dir/joint_half.svg',
    lessonPoint: 3,
  );
  static const wrongType = DoMistake(
    key: '3.1/m3_conductor_joint/wrong-type',
    textBn: 'ACSR আর AAAC-এর জয়েন্ট স্লিভ আলাদা! একটার মাল অন্যটায় — জোড় ঢিলে হয়ে গরম হবে, ক\'দিন বাদেই হটস্পট, লাইন কেটে মাটিতে।',
    art: '$_dir/joint_type.svg',
    lessonPoint: 3,
  );
  static const wrongCode = DoMistake(
    key: '3.1/m3_conductor_joint/wrong-code',
    textBn: 'স্লিভের কোড তারের কোডের সাথে মেলেনি — ব্যাস আলাদা, জোড় ঢিলে হয়ে গরম হবে। ডকেটের কোড মিলিয়ে স্লিভ নিন।',
    art: '$_dir/joint_code.svg',
    lessonPoint: 3,
  );
  static const loose = DoMistake(
    key: '3.1/m3_conductor_joint/left-loose',
    textBn: 'একটু ঢিলেই বিপদ — ঢিলে জোড় গরম হয়, ক\'দিন বাদেই হটস্পট, লাইন কেটে মাটিতে পড়ে। ভালভ ক্লিক না করা পর্যন্ত পুরো চাপ।',
    art: '$_dir/joint_half.svg',
    lessonPoint: 3,
  );

  static const passWrongSleeve = DoMistake(
    key: '3.1/m3_conductor_joint/passed-wrong-sleeve',
    textBn: 'তারের ট্যাগ আর স্লিভের লেখা মেলেনি — ACSR আর AAAC-এর স্লিভ আলাদা। এ জোড় ঢিলে হয়ে গরম হবে — বাতিল।',
    art: '$_dir/joint_type.svg',
    lessonPoint: 3,
  );

  /// Pro tip 2 (no lesson point: "পাঠে দেখুন" opens the lesson from its start).
  static const passCutStrand = DoMistake(
    key: '3.1/m3_conductor_joint/passed-cut-strand',
    textBn: 'মুখে একটা স্ট্র্যান্ড কাটা — লাইনের শক্তি কমে গেছে, ওখান থেকেই পরে তার ছিঁড়বে। বাতিল।',
    art: '$_dir/joint_strand.svg',
  );
  static const passHalfPress = DoMistake(
    key: '3.1/m3_conductor_joint/passed-half-press',
    textBn: 'চাপের দাগ একটাই, অগভীর — পুরো চাপ পড়েনি। এ জোড় ঢিলে থেকে গরম হবে — বাতিল।',
    art: '$_dir/joint_half.svg',
    lessonPoint: 3,
  );

  /// A good joint thrown out on the tray (judged once; the card comes only
  /// after the decision).
  static const rejectedGood = DoMistake(
    key: '3.1/m3_conductor_joint/rejected-good',
    textBn: 'ভালো জোড়ও বাতিল হয়েছে — ট্যাগ আর স্লিভের লেখা মিলেছে, চাপের দাগ পুরো, স্ট্র্যান্ড অক্ষত হলে সেই জোড় ভালো। আন্দাজে নয়, প্রতিটা মিলিয়ে দেখে বাতিল।',
    art: '$_dir/joint_code.svg',
    lessonPoint: 3,
  );

  static DoMistake passed(M3ConductorJointKind k) => switch (k) {
        M3ConductorJointKind.wrongSleeve => passWrongSleeve,
        M3ConductorJointKind.cutStrand => passCutStrand,
        M3ConductorJointKind.halfPress || M3ConductorJointKind.good => passHalfPress,
      };

  /// A bad joint was made: it glows under load, then this job starts again.
  static const ruins = {notIn, halfPress, wrongType, wrongCode, loose};

  static const all = [guess, noSleeve, noClean, notIn, halfPress, wrongType, wrongCode, loose, passWrongSleeve, passCutStrand, passHalfPress, rejectedGood];
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// A make-round (ms; ~1500 reaction per action): magnet 1500 + 1100, sleeve
/// 1500 + 2000, brush 1500 + 900, insert 1500 + hold 1400, press 1500 + hold
/// 1800 = 14700; the reason ~8210 → 22910 × 2 = 45820. The tray: look 3000 +
/// taps 4 × 1500 + done 1500 + reason 8210 = 18710. The coworker once 8330.
/// ≈ 72860 ms; 85 % ≈ 61900 → 60 s.
const m3ConductorJointQuickMs = 60000;

@immutable
class M3ConductorJointPack {
  const M3ConductorJointPack({required this.id, required this.titleBn, this.quickMs = m3ConductorJointQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M3ConductorJointPack> m3ConductorJointPacks = {
  'do_3_1_b': M3ConductorJointPack(id: 'do_3_1_b', titleBn: M3ConductorJointLines.title),
};

/// The tray's buttons for a round, in a fresh order.
List<M3ConductorJointStep> m3ConductorJointTray(math.Random rng) => [...M3ConductorJointStep.values]..shuffle(rng);

// ============================================================================
// Page
// ============================================================================

class M3ConductorJointPage extends StatefulWidget {
  const M3ConductorJointPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M3ConductorJointPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3ConductorJointPage> createState() => _PageState();
}

class _PageState extends State<M3ConductorJointPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RunPage(
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

class _RunPage extends ConsumerStatefulWidget {
  const _RunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3ConductorJointPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RunPage> createState() => _RunPageState();
}

/// What the hands are on now.
enum _Mode { idle, kit, insert, press }

class _RunPageState extends ConsumerState<_RunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3ConductorJointRun _run = M3ConductorJointRun(m3ConductorJointDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The magnet test or the brush's sweep (one-shots).
  late final AnimationController _act = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  /// Pushing the ends in (runs only while held).
  late final AnimationController _ins = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _insertDone();
    });

  /// The compressor's cycle (runs only while held; the valve clicks at 1).
  late final AnimationController _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700), reverseDuration: const Duration(milliseconds: 350))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _pressEnd();
    });

  /// The bad joint heating under load (one-shot).
  late final AnimationController _heat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final Listenable _sceneMotion = Listenable.merge([_act, _ins, _press, _heat]);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  _Mode _mode = _Mode.idle;
  List<M3ConductorJointStep> _tray = const [];
  String? _stamp;
  var _magneting = false;
  var _brushing = false;
  var _holding = false;
  M3ConductorJointKind? _bad;
  var _heatOn = false;
  int? _pressCue;

  /// The compressor went on on his round and the press waits for him
  /// ([holdForCoworker]); refused, the pump opens.
  var _pressWaiting = false;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hint (how to touch, never what): a sweep over the steps,
  /// the kit's sleeves or the tray's joints; a hold on the hold pad.
  final _hints = IdleHintController();
  final _stepKeys = {for (final s in M3ConductorJointStep.values) s: GlobalKey()};
  final _padKey = GlobalKey();

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M3ConductorJointRound get _round => _run.current;
  String get _ask => _round.inspect ? M3ConductorJointLines.askInspect : M3ConductorJointLines.askMake;

  @override
  void dispose() {
    disposeCoworker();
    _act.dispose();
    _ins.dispose();
    _press.dispose();
    _heat.dispose();
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

  void _tick() {
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.45);
  }

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.shown && !_heatOn;

  void _startRound() {
    setState(() {
      _mode = _Mode.idle;
      _stamp = null;
      _bad = null;
      _heatOn = false;
      _magneting = false;
      _brushing = false;
      _tray = _round.inspect ? const [] : m3ConductorJointTray(widget.rng);
      _wake++;
    });
    _ins.value = 0;
    _press.value = 0;
    _heat.value = 0;
    _act.value = 0;
    unawaited(_sayChain([_ask]));
  }

  /// A one-shot on [_act] (the magnet or the brush), then [done].
  void _oneShot(VoidCallback done) {
    if (_quiet) {
      _act.value = 0;
      done();
      return;
    }
    unawaited(_act.forward(from: 0).then((_) {
      if (mounted) done();
    }));
  }

  // --- the tray ---------------------------------------------------------------
  void _step(M3ConductorJointStep s, Offset origin) {
    if (!_canPlay || _holding || _magneting || _brushing) return;
    setState(() => _mode = _Mode.idle);
    switch (s) {
      case M3ConductorJointStep.magnet:
        final sticks = _run.magnet();
        if (sticks == null) return _tick();
        _cue('sounds/intro/click.ogg', volume: 0.5);
        setState(() => _magneting = true);
        _oneShot(() {
          HapticFeedback.mediumImpact();
          _cue(sticks ? 'sounds/learn/knock_solid.ogg' : 'sounds/intro/drop.ogg', volume: 0.6);
          setState(() {
            _magneting = false;
            _wake++;
          });
        });
      case M3ConductorJointStep.sleeve:
        if (_run.inserted > 0) return _tick();
        final m = _run.openKit();
        if (m != null) return unawaited(_slip(m, origin));
        _tick();
        setState(() => _mode = _Mode.kit);
        unawaited(_sayChain([M3ConductorJointLines.askKit]));
      case M3ConductorJointStep.brush:
        if (!_run.brush()) return _tick();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.35);
        setState(() => _brushing = true);
        _oneShot(() => setState(() {
              _brushing = false;
              _wake++;
            }));
      case M3ConductorJointStep.insert:
        if (_run.fullyIn || _run.pressed) return _tick();
        final m = _run.startInsert();
        if (m != null) return unawaited(_slip(m, origin));
        _tick();
        _ins.value = _run.inserted;
        setState(() => _mode = _Mode.insert);
      case M3ConductorJointStep.press:
        if (_run.pressed) return _tick();
        final m = _run.startPress();
        if (m != null) {
          return M3ConductorJointMistakes.ruins.contains(m) ? unawaited(_ruin(m, origin)) : unawaited(_slip(m, origin));
        }
        // On his round he cuts in as the compressor goes on: the press waits
        // for him, so a fast play cannot skip him.
        if (_run.index == _run.deal.callAt) _armCoworker();
        if (holdForCoworker()) {
          _press.value = 0;
          setState(() {
            _pressWaiting = true;
            _mode = _Mode.press;
          });
          return;
        }
        _tick();
        _toPress();
    }
  }

  /// He is due on this play once both ends are fully in (his push is about
  /// the pump); never re-armed after he came.
  void _armCoworker() {
    if (!coworkerDone && !coworkerDue && !coworkerOpen) scheduleCoworker();
  }

  void _toPress() {
    _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    _press.value = 0;
    setState(() => _mode = _Mode.press);
  }

  void _pickSleeve(M3ConductorJointSleeve s) {
    if (!_canPlay || _mode != _Mode.kit) return;
    _run.pickSleeve(s);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.55);
    setState(() {
      _mode = _Mode.idle;
      _wake++;
    });
  }

  // --- holds ------------------------------------------------------------------
  void _holdDown() {
    if (!_canPlay || _holding) return;
    if (_mode == _Mode.insert) {
      setState(() => _holding = true);
      unawaited(_ins.forward());
    } else if (_mode == _Mode.press) {
      setState(() => _holding = true);
      _pressCue = 0;
      _press.addListener(_ratchet);
      unawaited(_press.forward());
    }
  }

  /// The pump's strokes as the dies close.
  void _ratchet() {
    final n = (_press.value * 6).floor();
    if (n > (_pressCue ?? 0)) {
      _pressCue = n;
      HapticFeedback.selectionClick();
      _cue('sounds/learn/tick.ogg', volume: 0.5);
    }
  }

  void _holdUp(Offset origin) {
    if (!_holding) return;
    setState(() => _holding = false);
    if (_mode == _Mode.insert) {
      _ins.stop();
      _run.setInserted(_ins.value);
    } else if (_mode == _Mode.press && _press.isAnimating) {
      _press.stop();
      _pressEnd(origin: origin);
    }
  }

  void _insertDone() {
    if (!mounted || _mode != _Mode.insert) return;
    _run.setInserted(1);
    _cue('sounds/intro/click.ogg', volume: 0.6);
    HapticFeedback.mediumImpact();
    setState(() {
      _holding = false;
      _mode = _Mode.idle;
      _wake++;
    });
    if (_run.index == _run.deal.callAt) _armCoworker();
  }

  void _pressEnd({Offset? origin}) {
    if (!mounted || _mode != _Mode.press) return;
    _press.removeListener(_ratchet);
    final reached = _press.value;
    final m = _run.press(reached >= 0.999 ? 1 : reached);
    final o = origin ?? Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height * 0.5);
    setState(() {
      _holding = false;
      _mode = _Mode.idle;
    });
    if (m != null) {
      setState(() => _bad = m == M3ConductorJointMistakes.halfPress ? M3ConductorJointKind.halfPress : M3ConductorJointKind.good);
      _press.value = 0;
      unawaited(_ruin(m, o));
      return;
    }
    // The valve clicks open by itself.
    _cue('sounds/intro/confirm.ogg', volume: 0.6);
    HapticFeedback.heavyImpact();
    _press.value = 0;
    _roundRight(M3ConductorJointLines.stampDone, M3ConductorJointLines.whyMake);
  }

  // --- the tray round ---------------------------------------------------------
  void _toggleSample(int i) {
    if (!_canPlay || !_round.inspect) return;
    _run.toggle(i);
    HapticFeedback.selectionClick();
    _cue(_run.rejected.contains(i) ? 'sounds/learn/tag_slap.ogg' : 'sounds/intro/click.ogg', volume: 0.45);
    setState(() {});
  }

  void _trayDone(Offset origin) {
    if (!_canPlay || !_round.inspect) return;
    // Judged once: a good joint thrown out costs a slip like a bad one let
    // through (no free probing; the guide says nothing before the card).
    final miss = _run.missed;
    final m = _run.passTray();
    if (m != null) {
      if (miss.isEmpty) return unawaited(_slip(m, origin));
      final at = M3ConductorJointGeo.forScene(_sceneH).trayAt(miss.first);
      unawaited(_ruin(m, origin, at: at + const Offset(22, 8), counted: true));
      return;
    }
    _roundRight(M3ConductorJointLines.stampTray, M3ConductorJointLines.whyTray);
  }

  void _roundRight(String stamp, String question) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    setState(() {
      _stamp = stamp;
      _wake++;
    });
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final r = _round;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => M3ConductorJointLines.dealWhy(r, widget.rng),
      question: question,
      stillValid: () => _run.index == idx && !_ended,
    ));
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
  CoworkerScript get coworkerScript => M3ConductorJointLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.index != _run.deal.callAt || _run.pressed) return null;
    // His push ("let it off half-pressed") fits only once both ends are fully
    // in and the pump is next; a bad joint being cut out waits too.
    if (!_run.fullyIn || _run.shown) return false;
    if (_intro || _holding || _card != null || tableBusy || _heatOn) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final waiting = _pressWaiting;
    setState(() => _pressWaiting = false);
    if (!held) {
      // Listened to him: let off half-pressed.
      setState(() {
        _bad = M3ConductorJointKind.halfPress;
        _mode = _Mode.idle;
      });
      _cue('sounds/learn/dull_steel.ogg', volume: 0.7);
      await _ruin(_run.loose(), origin);
      return;
    }
    _run.caught.add(M3ConductorJointLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    if (waiting) {
      _toPress();
    } else {
      unawaited(_sayChain([M3ConductorJointLines.callHeld]));
    }
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3ConductorJointLines.tapWhy[_nudgeN++ % M3ConductorJointLines.tapWhy.length]
            : _nudge.next(_mode == _Mode.kit ? M3ConductorJointLines.askKit : _ask);
    _tick();
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

  Offset? _heatAt;

  /// A bad joint was made (or let through): it heats under load — the glow
  /// and the smoke; then the card. [counted]: the slip is already in the run.
  Future<void> _ruin(DoMistake m, Offset origin, {Offset? at, bool counted = false}) async {
    _hush();
    final geo = M3ConductorJointGeo.forScene(_sceneH);
    setState(() {
      _heatOn = true;
      _mode = _Mode.idle;
      _heatAt = at ?? Offset(M3ConductorJointGeo.jointX, geo.cableY);
      _bad ??= M3ConductorJointKind.good;
      _wake++;
    });
    _cue('sounds/learn/spark.ogg', volume: 0.6);
    if (_quiet) {
      _heat.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 600));
    } else {
      await _heat.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;
    await _slip(m, origin);
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _mode = _Mode.idle;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m3_conductor_joint/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    final m = _card;
    setState(() => _card = null);
    if (_round.inspect && _run.shown) {
      _next();
      return;
    }
    if (m != null && M3ConductorJointMistakes.ruins.contains(m)) {
      // Cut the bad joint out: the job again, from a new sleeve.
      _run.redo();
      _startRound();
      unawaited(_sayChain([M3ConductorJointLines.redo]));
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
    await _say(!_run.passed ? M3ConductorJointLines.fail : (_quickBonus ? M3ConductorJointLines.quick : M3ConductorJointLines.allSet),
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

  // --- the scene ---------------------------------------------------------------
  double _sceneH = 780;

  LinemanMode get _figure {
    if (_card != null || _heatOn || coworkerOpen || _pressWaiting) return LinemanMode.worried;
    if (_stamp != null) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  M3ConductorJointView _view() {
    final r = _round;
    if (r.inspect) return M3ConductorJointView(samples: r.samples, heat: _heatOn ? _heat.value : 0, heatAt: _heatAt);
    return M3ConductorJointView(
      job: r.job,
      magnet: _magneting ? _act.value : 0,
      magnetDone: _run.magnetDone && !_magneting,
      brush: _brushing ? _act.value : 0,
      brushed: _run.brushed && !_brushing,
      sleeve: _run.sleeve,
      inserted: _mode == _Mode.insert || _ins.isAnimating ? _ins.value : _run.inserted,
      press: _press.value,
      pressed: _run.pressed,
      toolOn: _mode == _Mode.press || _press.value > 0 || _run.pressed || (_bad != null && _heatOn),
      showKit: _mode == _Mode.kit,
      heat: _heatOn ? _heat.value : 0,
      heatAt: _heatAt,
      bad: _bad,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    _sceneH = m.height;
    final geo = M3ConductorJointGeo.forScene(m.height);
    final quiet = _quiet;
    final view = _view();
    final job = _round.job;
    final open = _canPlay;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: RepaintBoundary(child: CustomPaint(painter: M3ConductorJointWorldPainter(geo: geo))),
      ),
      Positioned(
        key: const ValueKey('trainee'),
        left: 0,
        top: geo.tarpTop - 92,
        width: 70,
        height: 140,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _figure, wake: _wake, quiet: quiet),
      ),
      Positioned.fill(
        key: const ValueKey('ground'),
        child: CustomPaint(painter: M3ConductorJointGroundPainter(geo: geo, view: view)),
      ),
      // The kit's sleeves.
      if (open && _mode == _Mode.kit && job != null)
        for (final (i, s) in job.sleeves.indexed)
          if (s != _run.sleeve)
            Positioned(
              key: ValueKey('sleeve-$s'),
              left: geo.kitAt(i).dx - M3ConductorJointGeo.kitSize.width / 2,
              top: geo.kitAt(i).dy - M3ConductorJointGeo.kitSize.height / 2,
              width: M3ConductorJointGeo.kitSize.width,
              height: M3ConductorJointGeo.kitSize.height,
              child: Semantics(
                button: true,
                label: M3ConductorJointLines.sleevePrint(s),
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _pickSleeve(s)),
              ),
            ),
      // The tray: tap a joint to set it aside.
      if (_round.inspect)
        for (var i = 0; i < _round.samples.length; i++)
          Positioned(
            key: ValueKey('joint-$i'),
            left: geo.trayAt(i).dx - M3ConductorJointGeo.traySize.width / 2,
            top: geo.trayAt(i).dy - M3ConductorJointGeo.traySize.height / 2,
            width: M3ConductorJointGeo.traySize.width,
            height: M3ConductorJointGeo.traySize.height,
            child: Semantics(
              button: true,
              label: 'joint-$i',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleSample(i),
                child: _run.rejected.contains(i) ? _RejectTag(quiet: quiet) : const SizedBox.expand(),
              ),
            ),
          ),
      if (_stamp != null && !_heatOn)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 110,
          width: 160,
          top: geo.cableY - 70,
          child: IgnorePointer(child: _StampPop(text: _stamp!, quiet: quiet)),
        ),
      if (!_intro)
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

  /// How to touch now (never what): a sweep over all the choices on show —
  /// the tray's joints, the kit's sleeves, or the steps; a hold on the hold
  /// pad (the one way forward while it is up).
  HintSpec? _hint() {
    final geo = M3ConductorJointGeo.forScene(_sceneH);
    final r = _round;
    if (r.inspect) {
      const s = M3ConductorJointGeo.traySize;
      return HintSpec.sweep([
        for (var i = 0; i < r.samples.length; i++) Rect.fromCenter(center: geo.trayAt(i), width: s.width, height: s.height),
      ], space: HintSpace.scene);
    }
    switch (_mode) {
      case _Mode.kit:
        const s = M3ConductorJointGeo.kitSize;
        final rects = [
          for (final (i, k) in r.job!.sleeves.indexed)
            if (k != _run.sleeve) Rect.fromCenter(center: geo.kitAt(i), width: s.width, height: s.height),
        ];
        return rects.length < 2 ? null : HintSpec.sweep(rects, space: HintSpace.scene);
      case _Mode.insert || _Mode.press:
        return HintSpec.holdOn(_padKey);
      case _Mode.idle:
        return HintSpec.sweepOver([for (final s in _tray) _stepKeys[s]!]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !tableBusy && !coworkerOpen && _card == null && !_pressWaiting && !_heatOn;
    final hold = handsOn && (_mode == _Mode.insert || _mode == _Mode.press);
    final waiting = handsOn && _canPlay && !_holding && !_magneting && !_brushing;
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
              labels: M3ConductorJointLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            animation: _sceneMotion,
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: (_run.index, _mode, _run.magnetDone, _run.sleeve, _run.brushed, _run.fullyIn),
            hintController: _hints,
            hintAutoMiss: true,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && !_round.inspect)
                Positioned(
                  key: const ValueKey('hud-tray'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 10,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in _tray)
                        _StepButton(
                          key: ValueKey('step-${s.name}'),
                          boxKey: _stepKeys[s],
                          label: M3ConductorJointLines.stepBn(s),
                          lit: (_mode == _Mode.kit && s == M3ConductorJointStep.sleeve) ||
                              (_mode == _Mode.insert && s == M3ConductorJointStep.insert) ||
                              (_mode == _Mode.press && s == M3ConductorJointStep.press),
                          onTapUp: (d) => _step(s, d.globalPosition),
                        ),
                    ],
                  ),
                ),
              if (handsOn && _round.inspect)
                Positioned(
                  key: const ValueKey('hud-done'),
                  left: 12,
                  right: 130,
                  bottom: pad.bottom + 12,
                  child: DoBigButton(label: M3ConductorJointLines.trayDone, filled: true, onTapUp: (d) => _trayDone(d.globalPosition)),
                ),
              if (hold)
                Positioned(
                  key: ValueKey('hud-hold-${_mode.name}'),
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + 132,
                  child: Center(
                    child: _HoldPad(
                      boxKey: _padKey,
                      label: _mode == _Mode.insert ? M3ConductorJointLines.holdInsert : M3ConductorJointLines.holdPress,
                      progress: _mode == _Mode.insert ? _ins : _press,
                      holding: _holding,
                      onDown: _holdDown,
                      onUp: _holdUp,
                    ),
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
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (_round.inspect ? 72 : 128)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
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
                  sound: FailSound.thud,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M3ConductorJointLines.intro,
                  alarm: 'sounds/intro/impact_metal.ogg',
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

/// A step on the tray (lit while its hands-on part is open).
class _StepButton extends StatelessWidget {
  const _StepButton({super.key, this.boxKey, required this.label, required this.lit, required this.onTapUp});
  final GlobalKey? boxKey;
  final String label;
  final bool lit;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: Container(
          key: boxKey,
          width: 84,
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: lit ? const [Color(0xFF6B5310), Color(0xFF3A2C06)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
            ),
            border: Border.all(color: (lit ? SlmColors.gold300 : SlmColors.gold300.withValues(alpha: 0.55)), width: lit ? 2 : 1.4),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, height: 1.1, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}

/// Press and hold: a ring fills while held (the ends going in, or the pump).
class _HoldPad extends StatelessWidget {
  const _HoldPad({this.boxKey, required this.label, required this.progress, required this.holding, required this.onDown, required this.onUp});
  final GlobalKey? boxKey;
  final String label;
  final Animation<double> progress;
  final bool holding;
  final VoidCallback onDown;
  final ValueChanged<Offset> onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (e) => onUp(e.position),
        onPointerCancel: (e) => onUp(e.position),
        child: SizedBox(
          key: boxKey,
          width: 150,
          height: 76,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: progress,
              builder: (_, child) => CustomPaint(painter: _HoldRing(progress.value, holding), child: child),
              child: Center(
                child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldRing extends CustomPainter {
  const _HoldRing(this.v, this.holding);
  final double v;
  final bool holding;

  @override
  void paint(Canvas c, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(38));
    c.drawRRect(r, Paint()..color = holding ? const Color(0xF0263D5E) : const Color(0xE60B1324));
    final fill = Rect.fromLTWH(0, 0, size.width * v.clamp(0.0, 1.0), size.height);
    c.save();
    c.clipRRect(r);
    c.drawRect(fill, Paint()..color = const Color(0x8854C27A));
    c.restore();
    c.drawRRect(r, Paint()..color = SlmColors.gold300..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_HoldRing old) => old.v != v || old.holding != holding;
}

/// A joint set aside on the tray.
class _RejectTag extends StatelessWidget {
  const _RejectTag({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.7 + 0.3 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SlmColors.danger, width: 2.6),
          color: const Color(0x33C0392B),
        ),
        alignment: Alignment.topRight,
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(6)),
          child: Text(M3ConductorJointLines.reject, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
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
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
