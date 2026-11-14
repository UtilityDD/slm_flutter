import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm5_sense_walk_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';


// Lesson 5.2 "লাইন পেট্রোলিং-এর সঠিক নিয়ম", কাজ 2 "থামুন, দেখুন, শুনুন"
// (pack do_5_2_b, engineType m5_sense_walk). The verb: hold to walk, let go
// to stop, then use the senses.
//
// The feeder trips and recloses (temporary faults): the trainee patrols the
// section between two FPI poles on foot, from the ground only (Module 5 rule
// R7 / ruling M5-3: nothing is climbed or touched). Hold the ground strip to
// walk (eyes down, forward only), let go to stop. At a stop: swipe up to look
// at the nearest pole's top (swipe down to come back), tap a part to tag it;
// hold the ear chip / the nose chip: the sense is present or absent for the
// nearest pole only (no direction, no meter).
//
// Clues dealt per play (lesson 5.2 point 2): one eye-up (a cracked insulator,
// a kite or a bird caught on the wire, a branch on the wire), one eye-down (a
// vehicle scrape, a damaged base, a slack stay / lifted anchor), one hidden:
// a hiss at a pole whose insulator shows only a dirt layer (myth 2: a fault
// with no outward sign) or a burnt-insulation / oil smell at the DTR. A right
// tag pays; the hidden one goes on the ◆ table → "কেন …?". The hidden tag
// counts only on its evidence (ruling M5-10): the ear / nose must have come
// back positive at that pole first, else a slip. Decoys keep sight from
// telling: a dirt layer on about half the other poles' insulators, and at
// least one DTR (smelling or silent) every play. A sound part tagged = a slip
// (R30). At the far FPI pole "সেকশন শেষ": every clue left
// untagged = a slip with its card (R31).
//
// The fallen wire (point 3 + myth 1), every play: AHEAD (2/3) — lying on dry
// soil or road pitch, no spark, no mark: let go before 10 m. Walking into the
// 10 m zone = deadly (R13). Stopped outside: the guide asks "এবার কী করবেন?",
// drag the rope reel out (the distance shows only while dragging) → a ring
// ≥ 10 m round the wire → ◆ → reason; a ring under 10 m = a slip (R16). DROP
// (1/3) — a conductor falls about 6 m in front of him: short drags (or taps)
// on his feet = feet-together steps, an up-flick = a hop, a long drag = a
// normal stride = deadly (R15). Out beyond 10 m → the rope ring → reason.
// After the ring he walks on up to the rope (he can still check the pole
// there); the next walk takes him round it on the far side of the road.
//
// The careless coworker, once a play, at a gate every play passes (two beats,
// his recorded voice; the next decisive control waits for him): 2/3 at the
// fallen wire after the stop, before the ring — "it isn't sparking, it's dead,
// let's move it" (listening = touching the wire = deadly, R14); 1/3 passing a
// span (never at a clue pole) — "look up as you walk" (listening = a slip:
// he stumbles in a pothole). Looking up while walking (a second finger's
// swipe) also stumbles him at the next pothole = a slip.
//
// Mark = 100 − 15 per slip, pass ≥ 55, three slips strike out; deadly freezes
// the scene grey, the consequence plays in colour, then near-miss / death.
// Gesture hints (how, never what): stopped and idle, the hand cycles walk-hold,
// swipe-up, ear-hold and nose-hold the same way; none on the way to the wire;
// at the rope a short drag in a random direction; in the drop zone a press on
// the feet; at the end pole the "সেকশন শেষ" button joins the cycle.

// ============================================================================
// Content
// ============================================================================

/// Walking speed, metres a second.
const double kSenseWalkSpeed = 4;

/// A feet-together step / a hop, metres.
const double kSenseShuffle = 0.8;
const double kSenseHop = 1.0;

/// A drag on the feet this long (design px) or longer is a normal stride.
const double kSenseStridePx = 56;

/// The three clues of a play.
enum SenseClue { up, down, hidden }

/// What the fallen wire does this play.
enum SenseWireKind { soil, pitch, drop }

/// Where the coworker comes.
enum SenseCall { wire, lookUp }

/// A sense chip.
enum SenseSense { ear, nose }

/// A move in the drop zone.
enum SenseStep { shuffle, hop, stride }

/// The reason beats.
enum SenseWhy { stop, ring, feet, hidden, smell }

/// What a move along the road ran into.
enum SenseEvent { none, drop, stumble, deadly, gate, rope }

abstract final class SenseWalkLines {
  static const title = 'থামুন, দেখুন, শুনুন';
  static const intro = 'লাইন বারবার ট্রিপ করছে! হেঁটে সূত্রটা খুঁজুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askWalk = 'হেঁটে এগোন — থেমে দেখুন, শুনুন।';
  static const askWire = 'এবার কী করবেন?';
  static const askOut = 'এখান থেকে নিরাপদে বেরোন!';
  static const askEnd = 'শেষ পোলে এসেছেন। সব দেখা হলে জানান।';
  static const askRound = 'দড়ির বাইরে দিয়ে ঘুরে এগোন।';
  static const tasks = [askWalk, askWire, askOut, askEnd, askRound];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads / screen-reader labels.
  static const sceneLabel = 'লাইনের পাশের রাস্তা';
  static const walkLabel = 'হাঁটুন';
  static const earLabel = 'কান';
  static const noseLabel = 'নাক';
  static const endLabel = 'সেকশন শেষ';
  static String metres(int m) => enDigits('$m মি');

  // What the senses say (present / absent; the nearest pole only).
  static const earYes = 'হিসহিস্ শব্দ…';
  static const earNo = 'অস্বাভাবিক শব্দ নেই';
  static const noseBurnt = 'পোড়া গন্ধ…';
  static const noseOil = 'তেলের গন্ধ…';
  static const noseNo = 'কোনো গন্ধ নেই';

  // The reasons: the right ones fit what was just done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <SenseWhy, String>{
    SenseWhy.stop: 'তারটা দেখেই কেন থামলেন?',
    SenseWhy.ring: 'এত দূর দিয়ে কেন ঘিরলেন?',
    SenseWhy.feet: 'পা জোড়া করে কেন বেরোলেন?',
    SenseWhy.hidden: 'কিছু ভাঙা না দেখেও কেন এই পোল?',
    SenseWhy.smell: 'গন্ধটা কেন ধরলেন?',
  };
  static const whyRight = <SenseWhy, List<String>>{
    SenseWhy.stop: ['পড়ে থাকা তার লাইভ ধরে নিই, তাই দূরেই থামি', 'তারের 10 মিটারের মধ্যে ঢোকা চলে না, তাই থামি'],
    SenseWhy.ring: ['তারের চারপাশে কমপক্ষে 10 মিটার জুড়ে ঘিরতে হয়', 'কাছের মাটিতেও ভোল্টেজ থাকে, তাই 10 মিটার দূরে'],
    SenseWhy.feet: ['তারের কাছের মাটিতেও ভোল্টেজ, তাই দুই পা একসাথে', 'স্টেপ পটেনশিয়াল — পা জোড়া রেখে ছোট পদক্ষেপে'],
    SenseWhy.hidden: ['ইনসুলেটরে ময়লা জমেও ফল্ট হয়, চিহ্ন থাকে না', 'হিসহিস্ শব্দ করোনা বা ট্র্যাকিং-এর সূত্র দেয়'],
    SenseWhy.smell: ['পোড়া ইনসুলেশন বা তেলের গন্ধ ফল্টের সূত্র দেয়', 'চোখে না দেখা ফল্টও নাকের গন্ধে ধরা পড়ে'],
  };
  static const myths = [
    'স্পার্ক নেই মানে তার ডেড, ভয়ের কিছু নেই',
    'ফল্ট মানেই কিছু ভাঙা, চোখে না দেখলে কিছু নেই',
    'তাড়াতাড়ি সারতে হবে, তাই যেমন খুশি করলাম',
    'দূর থেকে কিছু বোঝা যায় না, কাছে যেতেই হয়',
    'শব্দ-গন্ধ সব লাইনেই থাকে, ওসবের মানে নেই',
    'লাইন তো ট্রিপ করছে, তাই সব তার এখন ডেড',
    'দড়ি তো দেখানোর জন্য, যত কাছে তত সুবিধা',
    'লম্বা পা ফেলে ছুটে বেরোনোই সবচেয়ে নিরাপদ',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  /// The coworker at the fallen wire (the lesson's myth 1, his recorded voice).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const wireCall = CoworkerScript(
    line: 'মাটিতে পড়ে থাকা তারটি স্পার্ক করছে না, তার মানে ওটা ডেড। সরিয়ে দিই, চলো!',
    exitLine: coworkerExit,
    right: ['না — স্পার্ক নেই মানে ডেড নয়, দূরে থাকি', 'না — পড়ে থাকা তার লাইভ ধরে দূরে থাকি', 'না — ছোঁয়া মানেই মৃত্যু, তার ছোঁব না'],
    wrong: [
      'ঠিক, স্পার্ক নেই, তারটা সরিয়ে দিই',
      'আচ্ছা, শুকনো বাঁশ দিয়ে ঠেলে সরাই',
      'হ্যাঁ, ডেড তার, হাতে তুলে পাশে রাখি',
      'ঠিক আছে, পা দিয়ে ঠেলে রাস্তা ছাড়াই',
      'হ্যাঁ, দুই মাথা জুড়ে দিলেই ঝামেলা শেষ',
    ],
    asks: ['ওঁর কথা শুনবেন?', 'স্পার্ক নেই — তাই কি তার ডেড?', 'তারটা সরাবেন, না দূরে থাকবেন?'],
  );

  /// The coworker passing a span: look up as you walk.
  static const lookCall = CoworkerScript(
    line: 'হাঁটতে হাঁটতেই ওপরে দেখো, সময় বাঁচবে!',
    exitLine: coworkerExit,
    right: ['না — থামি, দেখি, তারপর হাঁটি', 'না — হাঁটার সময় চোখ পায়ের দিকে', 'না — ওপরে দেখব থেমে দাঁড়িয়ে'],
    wrong: [
      'ঠিক, হাঁটতে হাঁটতেই ওপরে দেখি',
      'আচ্ছা, থামলে দেরি, চলতে চলতে দেখি',
      'হ্যাঁ, গর্ত-টর্ত পরে দেখা যাবে',
      'ঠিক আছে, ওপরে চোখ রেখে জোরে হাঁটি',
      'হ্যাঁ, পায়ের দিকে তাকানোর কী দরকার',
    ],
    asks: ['ওঁর কথা শুনবেন?', 'হাঁটতে হাঁটতে ওপরে দেখবেন?', 'থামবেন, না চলতে চলতে দেখবেন?'],
  );

  /// His lines that still need his recorded voice (tool/rival_clip.py).
  static List<String> get newRivalLines => [wireCall.line, lookCall.line];

  static const callHeldWire = 'ঠিক! স্পার্ক না থাকলেও তার লাইভ — দূরে থাকুন।';
  static const callHeldLook = 'ঠিক! থামুন, দেখুন, তারপর আবার হাঁটুন।';
  static const allSet = 'চোখ, কান, নাক খাটিয়ে নিরাপদে পুরো সেকশন দেখা হলো।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — থেমে দেখুন, শুনুন; পড়ে থাকা তার থেকে 10 মিটার দূরে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtUp = 'থেমে ওপরে দেখে ক্ষতি ধরেছেন';
  static const caughtDown = 'পোলের গা-গোড়ার ক্ষতি ধরেছেন';
  static const caughtEar = 'কানে শুনে লুকোনো ফল্ট ধরেছেন';
  static const caughtNose = 'গন্ধে লুকোনো ফল্ট ধরেছেন';
  static const caughtStop = 'পড়ে থাকা তার দেখে দূরে থেমেছেন';
  static const caughtRing = 'তার ঘিরেছেন 10 মিটার দূর দিয়ে';
  static const caughtFeet = 'পা জোড়া রেখে বেরিয়েছেন';
  static const caughtCallWire = '“স্পার্ক নেই, ডেড” — শোনেননি';
  static const caughtCallLook = '“হাঁটতে হাঁটতে ওপরে দেখো” — শোনেননি';
}

abstract final class SenseWalkMistakes {
  static const _dir = 'assets/game/art/m5_sense_walk';

  // Deadly (Module 5 table R13–R15; ruling M5-4).
  static const enterZone = DoMistake(
    key: '5.2/m5_sense_walk/enter-zone',
    textBn: 'পড়ে থাকা তার লাইভ ধরে নিন! তার এবং তার ছুঁয়ে থাকা বেড়া/গাছ/গাড়ির চারপাশে কমপক্ষে 10 মিটার দূরে থামুন।',
    art: '$_dir/enter_zone.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const touchWire = DoMistake(
    key: '5.2/m5_sense_walk/touch-wire',
    textBn: 'স্পার্ক নেই মানে ডেড নয় — শুকনো মাটি বা পিচে পড়া লাইভ তার স্পার্ক না-ও করতে পারে। ছোঁয়া মানেই মৃত্যু।',
    art: '$_dir/touch_wire.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const longStride = DoMistake(
    key: '5.2/m5_sense_walk/long-stride',
    textBn: 'লম্বা পা ফেলে নয়! মাটিতেও ভোল্টেজ — দুই পা একসাথে রেখে ছোট ছোট পদক্ষেপে বা লাফিয়ে বেরোন।',
    art: '$_dir/long_stride.svg',
    deadly: true,
    lessonPoint: 2,
  );

  // Slips.
  static const lookWalk = DoMistake(
    key: '5.2/m5_sense_walk/look-walk',
    textBn: 'হাঁটতে হাঁটতে ওপরে তাকালে হোঁচট বা গর্তে পড়া — থামুন, দেখুন, তারপর আবার হাঁটুন।',
    art: '$_dir/look_walk.svg',
    lessonPoint: 2,
  );
  static const falseTag = DoMistake(
    key: '5.2/m5_sense_walk/false-tag',
    textBn: 'এটা তো ঠিকই আছে। ভালো করে দেখে, শুনে তবে ট্যাগ করুন।',
    art: '$_dir/false_tag.svg',
    lessonPoint: 1,
  );
  static const blindTag = DoMistake(
    key: '5.2/m5_sense_walk/blind-tag',
    textBn: 'চোখে কিছু ভাঙা নেই — আগে কান পেতে শুনুন বা গন্ধ নিন, সূত্র মিললে তবে ট্যাগ করুন।',
    art: '$_dir/blind_tag.svg',
    lessonPoint: 1,
  );
  static const shortRing = DoMistake(
    key: '5.2/m5_sense_walk/short-ring',
    textBn: 'দড়ি খুব কাছে! পড়ে থাকা তারের চারপাশে কমপক্ষে 10 মিটার দূর দিয়ে ঘিরে দিন।',
    art: '$_dir/short_ring.svg',
    lessonPoint: 2,
  );
  static const missUp = DoMistake(
    key: '5.2/m5_sense_walk/miss-up',
    textBn: 'ওপরের ক্ষতি বাদ পড়ল — থেমে ওপরে তাকান: ভাঙা ইনসুলেটর, ঘুড়ি, পাখি, গাছের ডাল।',
    art: '$_dir/miss_up.svg',
    lessonPoint: 1,
  );
  static const missDown = DoMistake(
    key: '5.2/m5_sense_walk/miss-down',
    textBn: 'নিচের ক্ষতি বাদ পড়ল — পোলের গায়ে গাড়ির ধাক্কা, গোড়া বা অ্যাঙ্করের ক্ষতি দেখুন।',
    art: '$_dir/miss_down.svg',
    lessonPoint: 1,
  );
  static const missEar = DoMistake(
    key: '5.2/m5_sense_walk/miss-ear',
    textBn: 'হিসহিস্ শব্দের পোল বাদ পড়ল — ময়লা জমা ইনসুলেটরেও ফল্ট হয়, বাইরে চিহ্ন থাকে না।',
    art: '$_dir/miss_ear.svg',
    lessonPoint: 1,
  );
  static const missNose = DoMistake(
    key: '5.2/m5_sense_walk/miss-nose',
    textBn: 'গন্ধের সূত্র বাদ পড়ল — প্রতিবার থেমে পোড়া ইনসুলেশন বা তেলের গন্ধ নিন।',
    art: '$_dir/miss_nose.svg',
    lessonPoint: 1,
  );

  static List<DoMistake> get all =>
      [enterZone, touchWire, longStride, lookWalk, falseTag, blindTag, shortRing, missUp, missDown, missEar, missNose];
}

@immutable
class SenseWalkDeal {
  const SenseWalkDeal({
    required this.layout,
    required this.wire,
    required this.wireAt,
    required this.call,
    required this.gateX,
    required this.askStop,
    required this.reelDir,
  });

  final SenseLayout layout;
  final SenseWireKind wire;

  /// Soil / pitch: the fallen wire's middle (metres). Drop: where he is when
  /// the conductor falls (it lands about 6 m in front of him).
  final double wireAt;
  final SenseCall call;

  /// The look-up coworker is called when he passes here (a span's middle,
  /// never at a clue pole).
  final double gateX;

  /// The ring's reason (soil / pitch): "why did you stop" or "why so far".
  final bool askStop;

  /// The rope hint's drag direction (radians; random, never toward 10 m).
  final double reelDir;

  SenseWhy get wireWhy => wire == SenseWireKind.drop ? SenseWhy.feet : (askStop ? SenseWhy.stop : SenseWhy.ring);
}

SenseWalkDeal senseWalkDeal(math.Random rng) {
  final poles = 5 + rng.nextInt(3);
  final inner = [for (var i = 1; i < poles - 1; i++) i]..shuffle(rng);
  final upPole = inner[0];
  final downPole = inner[1];
  final hiddenPole = inner[2];
  final upKind = SenseUpKind.values[rng.nextInt(SenseUpKind.values.length)];
  var upPart = upKind == SenseUpKind.crack ? senseInsPart(rng.nextInt(3)) : (rng.nextBool() ? SensePart.wireL : SensePart.wireR);
  final downKind = SenseDownKind.values[rng.nextInt(SenseDownKind.values.length)];
  final hidden = rng.nextBool() ? SenseHidden.ear : SenseHidden.nose;
  final dirtyIns = rng.nextInt(3);
  final noseOil = rng.nextBool();
  // At least one DTR every play, the same look smelling or not: ear plays get
  // a silent decoy (sometimes two); nose plays sometimes a silent second one.
  int decoyDtr(Set<int> not) {
    while (true) {
      final i = rng.nextInt(poles);
      if (i != hiddenPole && !not.contains(i)) return i;
    }
  }

  final dtrs = <int>{if (hidden == SenseHidden.nose) hiddenPole else decoyDtr(const {})};
  if (rng.nextBool()) dtrs.add(decoyDtr(dtrs));
  final stays = <int>{
    if (downKind == SenseDownKind.anchor) downPole,
    for (var i = 0; i < poles; i++)
      if (i != downPole && rng.nextDouble() < 0.4) i,
  };
  int other(int not) {
    while (true) {
      final i = rng.nextInt(poles);
      if (i != not) return i;
    }
  }

  final posterPole = other(downPole);
  final int? treePole = rng.nextInt(3) == 0 ? null : other(upPole);
  final treeRight = rng.nextBool();
  final brickPole = other(downPole);
  final endX = sensePoleX(poles - 1);
  final potholes = <double>[];
  for (var x = 9 + rng.nextDouble() * 5; x < endX; x += 7 + rng.nextDouble() * 7) {
    potholes.add((x * 10).roundToDouble() / 10);
  }
  final culvertX = sensePoleX(0) + 8 + rng.nextDouble() * (endX - sensePoleX(0) - 16);
  final ground = rng.nextBool() ? SenseGround.soil : SenseGround.pitch;
  final wire = rng.nextInt(3) == 0 ? SenseWireKind.drop : (ground == SenseGround.soil ? SenseWireKind.soil : SenseWireKind.pitch);
  final wireSpan = 1 + rng.nextInt(poles - 2);
  // A kite / bird / branch never sits on the broken phase's side of the
  // poles beside the fallen wire (that conductor hangs down there).
  if ((upPole == wireSpan && upPart == SensePart.wireR) || (upPole == wireSpan + 1 && upPart == SensePart.wireL)) {
    upPart = upPart == SensePart.wireR ? SensePart.wireL : SensePart.wireR;
  }
  final mid = sensePoleX(wireSpan) + kSenseSpan / 2 + (rng.nextDouble() * 6 - 3);
  final wireAt = wire == SenseWireKind.drop ? mid - 6 - kSenseWireHalf : mid;
  final call = rng.nextInt(3) < 2 ? SenseCall.wire : SenseCall.lookUp;
  final spans = [for (var s = 0; s < poles - 1; s++) if (s != wireSpan) s];
  final gateX = sensePoleX(spans[rng.nextInt(spans.length)]) + kSenseSpan / 2;
  return SenseWalkDeal(
    layout: SenseLayout(
      poles: poles,
      upPole: upPole,
      upKind: upKind,
      upPart: upPart,
      downPole: downPole,
      downKind: downKind,
      hiddenPole: hiddenPole,
      hidden: hidden,
      dirtyIns: dirtyIns,
      noseOil: noseOil,
      dtrPoles: dtrs,
      stays: stays,
      posterPole: posterPole,
      treePole: treePole,
      treeRight: treeRight,
      brickPole: brickPole,
      potholes: potholes,
      culvertX: culvertX,
      ground: ground,
      seed: rng.nextInt(1 << 20),
    ),
    wire: wire,
    wireAt: (wireAt * 10).roundToDouble() / 10,
    call: call,
    gateX: gateX,
    askStop: rng.nextBool(),
    reelDir: rng.nextDouble() * math.pi * 2,
  );
}

/// The play state (pure logic).
class SenseWalkRun {
  SenseWalkRun(this.deal) : wireX = deal.wire == SenseWireKind.drop ? null : deal.wireAt;

  final SenseWalkDeal deal;
  SenseLayout get layout => deal.layout;

  double pos = kSenseStart;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];
  final Set<SenseClue> found = {};
  final Set<int> tags = {};

  /// Poles where the ear / the nose came back positive (the hidden tag's
  /// evidence).
  final Set<int> sensed = {};

  /// The fallen wire's middle (metres); null until it falls (drop).
  double? wireX;

  /// Drop: he is inside the 10 m zone and must get out.
  var wireIn = false;

  /// The rope ring laid (metres from the wire).
  double? cordon;

  /// He has gone round the ring; the wire is behind him.
  var wirePassed = false;

  /// He passed the look-up coworker's gate.
  var gatePassed = false;

  /// "সেকশন শেষ" tapped.
  var done = false;

  var _ringSlip = false;

  double get endX => layout.endX;

  /// Walking stops here (just past the far FPI pole).
  double get stopX => endX + 2;

  /// "সেকশন শেষ" shows from here.
  bool get atEnd => pos >= endX - 6;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => slips == 0;
  int get nearest => layout.nearestPole(pos);

  /// His distance from the fallen wire (metres).
  double get wireDist => distTo(pos);
  double distTo(double x) {
    final w = wireX;
    return w == null ? double.infinity : math.max(0, (x - w).abs() - kSenseWireHalf);
  }

  /// Stopped outside the zone with the wire in view, no ring yet: the rope
  /// can go out.
  bool get wireReady {
    final w = wireX;
    return w != null &&
        !wirePassed &&
        !wireIn &&
        cordon == null &&
        w - pos <= kSenseSeeAhead - kSenseWireHalf &&
        wireDist >= kSenseZone - 1e-6;
  }

  /// The rope ring's near side (metres), or null with no ring / once past it.
  double? get ropeEdge {
    final w = wireX;
    final r = cordon;
    return w == null || r == null || wirePassed ? null : w - kSenseWireHalf - r;
  }

  /// He stands at the rope: the next walk takes him round it.
  bool get atRope {
    final e = ropeEdge;
    return e != null && pos >= e - 1e-6;
  }

  /// The span whose phase 3 lies on the ground, or null (not fallen yet).
  int? get brokenSpan {
    final w = wireX;
    return w == null ? null : layout.nearestSpan(w);
  }

  /// One stretch of walking to [to] (forward only); [eyesUp]: looking up.
  SenseEvent advance(double to, {required bool eyesUp}) {
    if (ended || wireIn) return SenseEvent.none;
    final from = pos;
    var t = math.min(to, stopX);
    if (t <= from) return SenseEvent.none;
    // The rope ring blocks the road: he stops at it.
    final rope = ropeEdge;
    var atRope = false;
    if (rope != null && t > rope - 1e-9) {
      t = math.max(from, rope);
      atRope = true;
      if (t <= from) return SenseEvent.rope;
    }
    if (deal.wire == SenseWireKind.drop && wireX == null && from < deal.wireAt && t >= deal.wireAt) {
      pos = deal.wireAt;
      wireX = pos + 6 + kSenseWireHalf;
      wireIn = true;
      return SenseEvent.drop;
    }
    final w = wireX;
    if (w != null && !wirePassed && cordon == null) {
      final edge = w - kSenseWireHalf - kSenseZone;
      if (from <= edge + 1e-9 && t > edge + 1e-9) {
        pos = t;
        deadly = SenseWalkMistakes.enterZone;
        return SenseEvent.deadly;
      }
    }
    if (eyesUp) {
      for (final h in layout.potholes) {
        if (from < h && t >= h) {
          pos = h;
          slips++;
          return SenseEvent.stumble;
        }
      }
    }
    pos = t;
    if (deal.call == SenseCall.lookUp && !gatePassed && from < deal.gateX && t >= deal.gateX) {
      gatePassed = true;
      return SenseEvent.gate;
    }
    return atRope ? SenseEvent.rope : SenseEvent.none;
  }

  /// The ear / the nose at the nearest pole: present or absent.
  bool sense(SenseSense s) {
    final want = s == SenseSense.ear ? SenseHidden.ear : SenseHidden.nose;
    final yes = layout.hidden == want && nearest == layout.hiddenPole;
    if (yes) sensed.add(nearest);
    return yes;
  }

  SenseClue? clueAt(int pole, SensePart part) {
    final l = layout;
    if (pole == l.upPole && part == l.upPart) return SenseClue.up;
    if (pole == l.downPole && part == l.downPart) return SenseClue.down;
    if (pole == l.hiddenPole && part == l.hiddenPart) return SenseClue.hidden;
    return null;
  }

  /// A part tagged: (the clue found, null) / (null, the slip) / (null, null)
  /// when it is already tagged.
  (SenseClue?, DoMistake?) tag(int pole, SensePart part) {
    if (ended || wireIn) return (null, null);
    final key = senseTagKey(pole, part);
    if (tags.contains(key)) return (null, null);
    final clue = clueAt(pole, part);
    if (clue == null) {
      // The broken phase hanging by the fallen wire is already known: no tag.
      final b = brokenSpan;
      if (b != null && ((pole == b && part == SensePart.wireR) || (pole == b + 1 && part == SensePart.wireL))) return (null, null);
      slips++;
      return (null, SenseWalkMistakes.falseTag);
    }
    if (clue == SenseClue.hidden && !sensed.contains(pole)) {
      // Seen, not heard / smelt: no evidence yet (ruling M5-10).
      slips++;
      return (null, SenseWalkMistakes.blindTag);
    }
    tags.add(key);
    found.add(clue);
    caught.add(switch (clue) {
      SenseClue.up => SenseWalkLines.caughtUp,
      SenseClue.down => SenseWalkLines.caughtDown,
      SenseClue.hidden => layout.hidden == SenseHidden.ear ? SenseWalkLines.caughtEar : SenseWalkLines.caughtNose,
    });
    return (clue, null);
  }

  /// A move in the drop zone; a stride is deadly. Out at 10 m.
  DoMistake? stepOut(SenseStep s) {
    if (!wireIn || ended) return null;
    if (s == SenseStep.stride) return deadly = SenseWalkMistakes.longStride;
    pos = ((pos - (s == SenseStep.hop ? kSenseHop : kSenseShuffle)) * 10).roundToDouble() / 10;
    if (wireDist >= kSenseZone - 1e-6) {
      wireIn = false;
      caught.add(SenseWalkLines.caughtFeet);
    }
    return null;
  }

  /// The rope ring laid [r] metres from the wire (under 10 m = a slip).
  DoMistake? lay(double r) {
    if (!wireReady || ended) return null;
    if (r < kSenseZone) {
      slips++;
      _ringSlip = true;
      return SenseWalkMistakes.shortRing;
    }
    cordon = r;
    if (!_ringSlip) caught.add(SenseWalkLines.caughtRing);
    return null;
  }

  /// Round the ring on the far side of the road: the wire is behind him. He
  /// comes out past the ring, never past the next pole.
  void passWire() {
    final w = wireX;
    final r = cordon;
    if (w == null || r == null || wirePassed) return;
    wirePassed = true;
    pos = math.min(w + kSenseWireHalf + r + 0.5, sensePoleX(layout.nearestSpan(w) + 1));
  }

  /// A slip booked by the page (listening to the look-up push).
  void slip() => slips++;

  /// "সেকশন শেষ": every clue left untagged is a slip.
  List<DoMistake> close() {
    if (ended) return const [];
    done = true;
    final missed = [
      if (!found.contains(SenseClue.up)) SenseWalkMistakes.missUp,
      if (!found.contains(SenseClue.down)) SenseWalkMistakes.missDown,
      if (!found.contains(SenseClue.hidden)) layout.hidden == SenseHidden.ear ? SenseWalkMistakes.missEar : SenseWalkMistakes.missNose,
    ];
    slips += missed.length;
    return missed;
  }

  void failDeadly(DoMistake m) => deadly = m;
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms: walking 120–180 m at 4 m/s ≈ 38000; a look up and back at three
/// poles ≈ 3 × 3000; ear and nose at ~5 poles ≈ 10 × 1500; three tags ≈ 4500;
/// the rope ≈ 3000 (drop steps ≈ 5000); two reasons ≈ 2 × 8200; the
/// coworker ≈ 9600                                               ≈ 96000
/// 85 % ≈ 82000 → 80 s.
const kSenseQuickMs = 80000;

@immutable
class SenseWalkPack {
  const SenseWalkPack({required this.id, required this.titleBn, this.quickMs = kSenseQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, SenseWalkPack> senseWalkPacks = {
  'do_5_2_b': SenseWalkPack(id: 'do_5_2_b', titleBn: SenseWalkLines.title),
};

/// Test hook: the play on screen (tests read where he is and what was dealt).
@visibleForTesting
abstract final class SenseWalkProbe {
  static SenseWalkRun? run;
}

// ============================================================================
// Page
// ============================================================================

class SenseWalkPage extends StatefulWidget {
  const SenseWalkPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final SenseWalkPack pack;
  final bool muted;
  final int? seed;

  @override
  State<SenseWalkPage> createState() => _SenseWalkPageState();
}

class _SenseWalkPageState extends State<SenseWalkPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SenseRunPage(
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

class _SenseRunPage extends ConsumerStatefulWidget {
  const _SenseRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final SenseWalkPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SenseRunPage> createState() => _SenseRunPageState();
}

enum _Drag { swipe, reel, feet }

class _SenseRunPageState extends ConsumerState<_SenseRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final SenseWalkRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _rightBag = LineBag(LearnFeedbackLines.right);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  // Walking.
  final _posN = ValueNotifier<double>(kSenseStart);
  late final Ticker _walkTicker = createTicker(_onWalk);
  Duration? _walkLast;
  var _walking = false;
  int _walkPointers = 0;

  // Eyes up / down.
  late final AnimationController _tilt = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  var _eyesUp = false;
  int _topPole = 0;

  // The wire's fall (drop) and the steps out.
  late final AnimationController _drop = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _step = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
  double _stepFrom = 0;
  double _stepTo = 0;

  // The senses.
  late final AnimationController _senseHold = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  SenseSense? _senseOn;
  String? _senseText;
  var _senseYes = false;
  int _senseTok = 0;
  Timer? _senseTimer;

  // A drag on the scene.
  _Drag? _drag;
  Offset _dragFrom = Offset.zero;
  Offset _dragNow = Offset.zero;
  var _swiped = false;
  int? _dragR;

  int _stumbleTok = 0;
  var _wireAsked = false;
  var _endAsked = false;
  int _detour = 0;
  int _whyTok = 0;
  final List<DoMistake> _missQueue = [];
  SenseHarm _harm = SenseHarm.zone;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // The gesture hand.
  final _hints = IdleHintController();
  final _stripKey = GlobalKey();
  final _earKey = GlobalKey();
  final _noseKey = GlobalKey();
  final _endKey = GlobalKey();
  int _hintN = 0;
  SenseWalkGeo? _geo;
  SenseTopGeo? _topGeo;

  @override
  void initState() {
    super.initState();
    _run = SenseWalkRun(senseWalkDeal(widget.rng));
    SenseWalkProbe.run = _run;
    _step.addListener(() {
      final t = Curves.easeOut.transform(_step.value);
      _posN.value = _stepFrom + (_stepTo - _stepFrom) * t;
    });
    _senseHold.addStatusListener((s) {
      if (s == AnimationStatus.completed) _senseDone();
    });
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  SenseLayout get _layout => _run.layout;

  @override
  void dispose() {
    disposeCoworker();
    _walkTicker.dispose();
    _tilt.dispose();
    _drop.dispose();
    _step.dispose();
    _senseHold.dispose();
    _senseTimer?.cancel();
    _posN.dispose();
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

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _stepping => _step.isAnimating;

  bool get _canPlay =>
      !_intro && !_ended && !_run.ended && _card == null && !tableBusy && !coworkerOpen && !_freeze && _missQueue.isEmpty;

  String get _task {
    if (_run.wireIn) return SenseWalkLines.askOut;
    if (_run.wireReady) return SenseWalkLines.askWire;
    if (_run.atRope) return SenseWalkLines.askRound;
    if (_run.atEnd) return SenseWalkLines.askEnd;
    return SenseWalkLines.askWalk;
  }

  void _start() {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  // --- walking ----------------------------------------------------------------
  void _walkDown() {
    _walkPointers++;
    if (_walking || !_canPlay || _run.wireIn || _stepping || _drag != null || _senseOn != null) return;
    if (holdForCoworker()) return;
    if (_run.pos >= _run.stopX - 0.01) {
      _hints.missTap();
      return;
    }
    if (_run.atRope) _goRound();
    // Walking is eyes down.
    if (_eyesUp) _setEyes(false);
    _walking = true;
    _walkLast = null;
    _walkTicker.start();
    setState(() => _wake++);
  }

  void _walkUp() {
    _walkPointers = math.max(0, _walkPointers - 1);
    if (_walkPointers > 0 || !_walking) return;
    _stopWalk();
    _afterStop();
  }

  void _stopWalk() {
    if (!_walking) return;
    _walkTicker.stop();
    _walking = false;
    if (mounted) setState(() => _wake++);
  }

  void _onWalk(Duration elapsed) {
    final last = _walkLast;
    _walkLast = elapsed;
    if (last == null) return;
    if (!_canPlay || coworkerOpen) {
      _stopWalk();
      return;
    }
    final dt = (elapsed - last).inMicroseconds / 1e6;
    final endBefore = _run.atEnd;
    final ev = _run.advance(_run.pos + kSenseWalkSpeed * dt, eyesUp: _eyesUp);
    _posN.value = _run.pos;
    if (_eyesUp && _run.nearest != _topPole) setState(() => _topPole = _run.nearest);
    switch (ev) {
      case SenseEvent.none:
        if (_run.atEnd != endBefore) setState(() {});
        if (_run.pos >= _run.stopX - 1e-6) {
          _stopWalk();
          _afterStop();
        }
      case SenseEvent.gate:
        scheduleCoworker();
      case SenseEvent.drop:
        _stopWalk();
        _onDrop();
      case SenseEvent.stumble:
        _stopWalk();
        _stumble();
        unawaited(_mistake(SenseWalkMistakes.lookWalk, _manGlobal()));
      case SenseEvent.deadly:
        _stopWalk();
        _harm = SenseHarm.zone;
        unawaited(_deadly(_run.deadly!));
      case SenseEvent.rope:
        // At the rope: he stops; the next walk goes round it.
        _stopWalk();
        setState(() => _wake++);
        unawaited(_sayChain([SenseWalkLines.askRound]));
    }
  }

  /// Round the ring on the far side of the road (a short fade).
  void _goRound() {
    setState(() {
      _run.passWire();
      _posN.value = _run.pos;
      _detour++;
      _wake++;
    });
  }

  void _afterStop() {
    if (!mounted || _run.ended) return;
    if (_run.wireReady && !_wireAsked) {
      _onWireStop();
      return;
    }
    if (_run.atEnd && !_endAsked) {
      _endAsked = true;
      unawaited(_sayChain([SenseWalkLines.askEnd]));
    }
    setState(() {});
  }

  /// Stopped outside the zone with the wire in view (or out of the drop zone).
  void _onWireStop() {
    _wireAsked = true;
    if (_run.deal.wire != SenseWireKind.drop) _run.caught.add(SenseWalkLines.caughtStop);
    if (_run.deal.call == SenseCall.wire && !coworkerDone) scheduleCoworker();
    setState(() => _wake++);
    unawaited(_sayChain([SenseWalkLines.askWire], mood: GuideMood.think));
  }

  void _stumble() {
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/stomp.ogg', volume: 0.7);
    setState(() {
      _stumbleTok++;
      _wake++;
    });
    _setEyes(false);
  }

  void _onDrop() {
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.8);
    if (_eyesUp) _setEyes(false);
    if (_quiet) {
      _drop.value = 1;
    } else {
      _drop.forward(from: 0);
    }
    setState(() => _wake++);
    unawaited(_sayChain([SenseWalkLines.askOut], mood: GuideMood.warn));
  }

  // --- looking ------------------------------------------------------------------
  void _setEyes(bool up) {
    if (_eyesUp == up) return;
    _eyesUp = up;
    if (up) _topPole = _run.nearest;
    if (_quiet) {
      _tilt.value = up ? 1 : 0;
    } else if (up) {
      _tilt.forward();
    } else {
      _tilt.reverse();
    }
    setState(() => _wake++);
  }

  // --- the scene's touch -----------------------------------------------------
  Offset _manGlobal() {
    final s = MediaQuery.sizeOf(context);
    return Offset(s.width * 0.42, s.height * 0.7);
  }

  void _tapScene(Offset p, Offset global) {
    final geo = _geo;
    final top = _topGeo;
    if (geo == null || top == null || !_canPlay || _walking || _stepping) return;
    if (_run.wireIn) {
      if (geo.feet.contains(p)) {
        _stepOut(SenseStep.shuffle, global);
      } else {
        _hints.missTap();
      }
      return;
    }
    if (_eyesUp) {
      for (final part in senseUpParts) {
        if (top.partRect(part).contains(p)) {
          if (holdForCoworker()) return;
          _tag(_topPole, part, global);
          return;
        }
      }
    } else {
      for (var i = 0; i < _layout.poles; i++) {
        final x = geo.sx(sensePoleX(i), _run.pos);
        if (x < -40 || x > 400) continue;
        for (final part in senseDownParts) {
          if (part == SensePart.anchor && !_layout.stays.contains(i)) continue;
          if (part == SensePart.tank && !_layout.dtrPoles.contains(i)) continue;
          if (geo.partRect(part, x).contains(p)) {
            if (holdForCoworker()) return;
            _tag(i, part, global);
            return;
          }
        }
      }
    }
    _hints.missTap();
  }

  void _tag(int pole, SensePart part, Offset global) {
    final (clue, m) = _run.tag(pole, part);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (clue == null) {
      _tick();
      return;
    }
    _hush();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    HapticFeedback.lightImpact();
    setState(() => _wake++);
    if (clue == SenseClue.hidden) {
      _onRight(_layout.hidden == SenseHidden.ear ? SenseWhy.hidden : SenseWhy.smell);
      return;
    }
    _cue('sounds/quiz_right.ogg', volume: 0.55);
    unawaited(_levelDelta(10, global, mood: GuideMood.glad));
    unawaited(_sayChain([_rightBag.next().shownBn], mood: GuideMood.glad));
  }

  void _panStart(DragStartDetails d) {
    final geo = _geo;
    _drag = null;
    _swiped = false;
    if (geo == null || !_canPlay || _stepping) return;
    final p = d.localPosition;
    _dragFrom = p;
    _dragNow = p;
    if (_run.wireIn) {
      if (!_walking && geo.feet.contains(p)) _drag = _Drag.feet;
      return;
    }
    if (!_walking && _run.wireReady && geo.reel.inflate(14).contains(p)) {
      if (holdForCoworker()) return;
      _hush();
      setState(() {
        _drag = _Drag.reel;
        _dragR = null;
      });
      return;
    }
    _drag = _Drag.swipe;
  }

  void _panUpdate(DragUpdateDetails d) {
    _dragNow = d.localPosition;
    switch (_drag) {
      case _Drag.swipe:
        if (_swiped) return;
        final v = _dragNow - _dragFrom;
        if (v.dy.abs() > 36 && v.dy.abs() > v.dx.abs() * 1.2) {
          _swiped = true;
          if (!_canPlay || holdForCoworker()) return;
          _tick('sounds/intro/tick.ogg', 0.3);
          _setEyes(v.dy < 0);
        }
      case _Drag.reel:
        final geo = _geo;
        if (geo == null) return;
        final stake = geo.wx(_dragNow.dx, _run.pos);
        // Whole metres, rounded down: a 9.6 m ring is not 10 m.
        final r = (math.min(_run.distTo(stake), _run.wireDist) + 1e-3).floor();
        if (r != _dragR) setState(() => _dragR = r);
      case _Drag.feet:
      case null:
        break;
    }
  }

  void _panEnd(DragEndDetails d) {
    final kind = _drag;
    _drag = null;
    switch (kind) {
      case _Drag.swipe:
        if (!_swiped) _hints.missTap();
      case _Drag.reel:
        final r = _dragR;
        setState(() => _dragR = null);
        if (r == null) {
          _hints.missTap();
          return;
        }
        _layRing(r, _manGlobal());
      case _Drag.feet:
        final v = _dragNow - _dragFrom;
        final vel = d.velocity.pixelsPerSecond;
        final SenseStep step;
        if (vel.dy < -350 && vel.dy.abs() > vel.dx.abs() && v.dy < 0) {
          step = SenseStep.hop;
        } else if (v.distance >= kSenseStridePx) {
          step = SenseStep.stride;
        } else {
          step = SenseStep.shuffle;
        }
        _stepOut(step, _manGlobal());
      case null:
        break;
    }
  }

  void _stepOut(SenseStep s, Offset global) {
    if (!_canPlay || !_run.wireIn || _stepping) return;
    final from = _run.pos;
    final m = _run.stepOut(s);
    if (m != null) {
      _harm = SenseHarm.stride;
      unawaited(_deadly(m));
      return;
    }
    _tick('sounds/learn/stomp.ogg', 0.45);
    _stepFrom = from;
    _stepTo = _run.pos;
    if (_quiet) {
      _posN.value = _run.pos;
    } else {
      _step.forward(from: 0);
    }
    setState(() => _wake++);
    if (!_run.wireIn) {
      _onWireStop();
    }
  }

  void _layRing(int r, Offset global) {
    if (!_canPlay) return;
    final m = _run.lay(r.toDouble());
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    HapticFeedback.mediumImpact();
    setState(() => _wake++);
    _onRight(_run.deal.wireWhy);
  }

  // --- the senses -----------------------------------------------------------------
  void _senseDown(SenseSense s) {
    if (_senseOn != null || !_canPlay || _walking || _run.wireIn || _stepping || _drag != null) return;
    if (holdForCoworker()) return;
    _tick('sounds/intro/tick.ogg', 0.3);
    setState(() {
      _senseOn = s;
      _senseText = null;
    });
    _senseHold.forward(from: 0);
  }

  void _senseUp(SenseSense s) {
    if (_senseOn != s) return;
    _senseHold.stop();
    _senseHold.value = 0;
    setState(() => _senseOn = null);
  }

  void _senseDone() {
    final s = _senseOn;
    if (s == null || !mounted) return;
    final yes = _run.sense(s);
    _senseTimer?.cancel();
    HapticFeedback.selectionClick();
    if (yes) _cue('sounds/learn/tick.ogg', volume: 0.5);
    setState(() {
      _senseOn = null;
      _senseHold.value = 0;
      _senseYes = yes;
      _senseTok++;
      _senseText = switch (s) {
        SenseSense.ear => yes ? SenseWalkLines.earYes : SenseWalkLines.earNo,
        SenseSense.nose => yes ? (_layout.noseOil ? SenseWalkLines.noseOil : SenseWalkLines.noseBurnt) : SenseWalkLines.noseNo,
      };
    });
    _senseTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _senseText = null);
    });
  }

  // --- the end of the section --------------------------------------------------
  void _endTap() {
    if (!_canPlay || _walking || !_run.atEnd || _stepping) return;
    if (holdForCoworker()) return;
    _hush();
    _tick('sounds/intro/confirm.ogg', 0.6);
    final missed = _run.close();
    if (missed.isEmpty) {
      unawaited(_finish());
      return;
    }
    _missQueue.addAll(missed);
    _nextMiss();
  }

  void _nextMiss() {
    if (_missQueue.isEmpty) {
      unawaited(_finish());
      return;
    }
    final m = _missQueue.removeAt(0);
    unawaited(_levelDelta(-10, _manGlobal(), mood: GuideMood.warn));
    unawaited(_slip(m));
  }

  // --- the shared success beat (ReasonTable) ---------------------------------
  void _onRight(SenseWhy why) {
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final tok = ++_whyTok;
    unawaited(askReason(
      deal: () => dealChoices(SenseWalkLines.whyRight[why]!, SenseWalkLines.myths, widget.rng),
      question: SenseWalkLines.whyQ[why]!,
      stillValid: () => _whyTok == tok && !_ended,
    ));
  }

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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (!mounted || _ended) return;
      // After the ring he walks on to the rope himself (the pole before it
      // can still be checked); the walk from the rope goes round it.
      setState(() => _wake++);
      unawaited(_sayChain([_task]));
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _run.deal.call == SenseCall.wire ? SenseWalkLines.wireCall : SenseWalkLines.lookCall;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended) return null;
    if (_run.deal.call == SenseCall.wire && (_run.wirePassed || _run.cordon != null)) return null;
    if (_intro || _card != null || _freeze || _drag != null || _stepping || _senseOn != null) return false;
    if (_run.deal.call == SenseCall.lookUp) return _run.gatePassed && !_run.wireIn;
    return _run.wireReady && !_walking;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() {
    _hush();
    _stopWalk();
  }

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final wire = _run.deal.call == SenseCall.wire;
    if (!held) {
      if (wire) {
        // Listened to him: the wire is moved by hand / a stick.
        _run.failDeadly(SenseWalkMistakes.touchWire);
        _harm = SenseHarm.touch;
        await _deadly(SenseWalkMistakes.touchWire);
      } else {
        // Listened: he looks up as he walks and stumbles in a pothole.
        _run.slip();
        _stumble();
        await _mistake(SenseWalkMistakes.lookWalk, origin);
      }
      return;
    }
    _run.caught.add(wire ? SenseWalkLines.caughtCallWire : SenseWalkLines.caughtCallLook);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([wire ? SenseWalkLines.callHeldWire : SenseWalkLines.callHeldLook, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? SenseWalkLines.tapWhy[_nudgeN++ % SenseWalkLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _missQueue.clear();
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
    _stopWalk();
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('sensewalk/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The scene freezes grey; the consequence plays in colour; then near-miss
  /// or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _missQueue.clear();
    _clock.stop();
    _hush();
    _stopWalk();
    _senseHold.stop();
    if (_eyesUp) _setEyes(false);
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _senseOn = null;
      _dragR = null;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('sensewalk/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? SenseWalkLines.deadlyWord : SenseWalkLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        if (_run.done) {
          _nextMiss();
          return;
        }
        unawaited(_sayChain([_task]));
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
    await _say(!_run.passed ? SenseWalkLines.fail : (_quickBonus ? SenseWalkLines.quick : SenseWalkLines.allSet),
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
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen || _run.wireIn) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_walking) return LinemanMode.walk;
    return LinemanMode.idle;
  }

  SenseLive get _live => SenseLive(
        tags: {..._run.tags},
        wireX: _run.wireX,
        cordon: _run.cordon,
        dragR: _dragR?.toDouble(),
        dropped: _run.deal.wire == SenseWireKind.drop,
      );

  /// Waiting for the player's input (no walk, drag, card, deck, voice-locked beat).
  bool get _waiting => _canPlay && !_walking && _drag == null && _senseOn == null && !_stepping;

  /// The gesture hand: how to touch, never what. Stopped and idle the hand
  /// cycles walk-hold, swipe, ear-hold, nose-hold (and the end button at the
  /// end pole) the same way whatever the clue; at the rope a short drag in a
  /// random direction; in the drop zone a press on the feet.
  HintSpec? _hint() {
    final geo = _geo;
    if (geo == null) return null;
    if (_run.wireIn) return HintSpec.tap(geo.feet.center, space: HintSpace.scene);
    if (_run.wireReady) {
      final d = _run.deal.reelDir;
      return HintSpec.drag(geo.reel.center, toward: Offset(math.cos(d), math.sin(d)), travel: 40, space: HintSpace.scene);
    }
    final cycle = <HintSpec? Function()>[
      () {
        final r = HintSpec.globalRectOf(_stripKey);
        return r == null ? null : HintSpec.hold(r.center);
      },
      () => HintSpec.swipe(Offset(180, geo.baseY - 150), toward: Offset(0, _eyesUp ? 1 : -1), travel: 90, space: HintSpace.scene),
      () => HintSpec.holdOn(_earKey),
      () => HintSpec.holdOn(_noseKey),
      if (_run.atEnd) () => HintSpec.tapOn(_endKey),
    ];
    return cycle[_hintN++ % cycle.length]();
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = SenseWalkGeo.forScene(m.height, m.inset);
    final top = _topGeo = SenseTopGeo.forScene(m.height);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final live = _live;
    final wx = _run.wireX;
    final reelUp = _run.wireReady && !_walking && !_freeze;
    final ground = Stack(
      children: [
        Positioned.fill(
          key: const ValueKey('road'),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: SenseWalkPainter(
                geo: geo,
                layout: _layout,
                live: live,
                pos: _posN,
                drop: _drop,
                dropSpot: _run.deal.wire == SenseWireKind.drop ? _run.deal.wireAt + 6 + kSenseWireHalf : null,
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: geo.man,
          child: TweenAnimationBuilder<double>(
            key: ValueKey('stumble-$_stumbleTok'),
            tween: Tween(begin: _stumbleTok == 0 || quiet ? 0 : 1, end: 0),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, child) => Transform.rotate(angle: math.sin(v * math.pi) * 0.5, alignment: Alignment.bottomCenter, child: child),
            child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
          ),
        ),
        if (reelUp)
          Positioned.fromRect(
            key: const ValueKey('reel'),
            rect: geo.reel,
            child: const IgnorePointer(child: _RopeReel()),
          ),
      ],
    );
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: AnimatedBuilder(
            animation: _tilt,
            child: ground,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_tilt.value);
              return Stack(
                children: [
                  if (t < 1)
                    Positioned.fill(
                      key: const ValueKey('ground'),
                      child: Transform.translate(offset: Offset(0, t * m.height * 0.5), child: child),
                    ),
                  if (t > 0)
                    Positioned.fill(
                      key: const ValueKey('top'),
                      child: Transform.translate(
                        offset: Offset(0, -(1 - t) * m.height),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: SenseTopPainter(geo: top, layout: _layout, pole: _topPole, tags: live.tags, broken: _run.brokenSpan),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      // The distance, only while the rope is being dragged out.
      if (_dragR != null)
        Positioned(
          key: const ValueKey('readout'),
          left: (_dragNow.dx - 28).clamp(4.0, 300.0),
          top: geo.baseY - 34,
          child: IgnorePointer(child: _Readout(text: SenseWalkLines.metres(_dragR!))),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: SenseWalkLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, d.globalPosition),
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: _panEnd,
          ),
        ),
      ),
      // Round the ring: a short fade.
      if (_detour > 0 && !_freeze)
        Positioned.fill(
          key: ValueKey('detour-$_detour'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 0.85, end: 0),
              duration: const Duration(milliseconds: 700),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
      if (_freeze && wx != null)
        Positioned.fill(
          key: const ValueKey('harm'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: SenseHarmPainter(geo: geo, wireSx: geo.sx(wx, _run.pos), harm: _harm, v: v)),
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
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.ended;
    final endUp = handsOn && _run.atEnd && !_walking && !tableBusy;
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
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && _waiting,
            hintKey: '${_run.found.length}|${(_run.pos / 6).floor()}|${_run.wireIn}|${_run.cordon != null}|$_eyesUp|${_run.atEnd}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn)
                // Right of the corner guide (his sprite takes the touch at
                // its bottom-right, up to 232 dp from the left).
                Positioned(
                  key: const ValueKey('hud-walk'),
                  left: 236,
                  right: 0,
                  bottom: pad.bottom,
                  height: 84,
                  child: Semantics(
                    button: true,
                    label: SenseWalkLines.walkLabel,
                    excludeSemantics: true,
                    child: Listener(
                      key: _stripKey,
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) => _walkDown(),
                      onPointerUp: (_) => _walkUp(),
                      onPointerCancel: (_) => _walkUp(),
                      child: _WalkStrip(on: _walking),
                    ),
                  ),
                ),
              if (handsOn)
                Positioned(
                  key: const ValueKey('hud-senses'),
                  left: 8,
                  top: pad.top + 66,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SenseChip(
                        key: _earKey,
                        icon: Icons.hearing_rounded,
                        label: SenseWalkLines.earLabel,
                        hold: _senseHold,
                        on: _senseOn == SenseSense.ear,
                        onDown: () => _senseDown(SenseSense.ear),
                        onUp: () => _senseUp(SenseSense.ear),
                      ),
                      const SizedBox(width: 8),
                      _SenseChip(
                        key: _noseKey,
                        icon: Icons.air_rounded,
                        label: SenseWalkLines.noseLabel,
                        hold: _senseHold,
                        on: _senseOn == SenseSense.nose,
                        onDown: () => _senseDown(SenseSense.nose),
                        onUp: () => _senseUp(SenseSense.nose),
                      ),
                    ],
                  ),
                ),
              if (handsOn && _senseText != null)
                Positioned(
                  key: ValueKey('sense-$_senseTok'),
                  left: 8,
                  top: pad.top + 146,
                  child: IgnorePointer(child: _SenseBubble(text: _senseText!, yes: _senseYes)),
                ),
              if (endUp)
                Positioned(
                  key: const ValueKey('hud-end'),
                  right: 12,
                  bottom: pad.bottom + 96,
                  child: _EndButton(key: _endKey, label: SenseWalkLines.endLabel, onTap: _endTap),
                ),
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 4), onLeft: !coworkerOnScreen || coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  sound: FailSound.thud,
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
                  line: SenseWalkLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _start();
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

/// The ground strip: hold to walk.
class _WalkStrip extends StatelessWidget {
  const _WalkStrip({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: on ? const [Color(0x2222C55E), Color(0x7722C55E)] : const [Color(0x22101A2B), Color(0x88101A2B)],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, 0.3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk_rounded, size: 30, color: on ? const Color(0xFFE8FFE8) : const Color(0xDDFFFFFF)),
            Text(SenseWalkLines.walkLabel, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xDDFFFFFF))),
          ],
        ),
      ),
    );
  }
}

/// A sense chip: hold it; a ring fills, then the sense answers.
class _SenseChip extends StatelessWidget {
  const _SenseChip({super.key, required this.icon, required this.label, required this.hold, required this.on, required this.onDown, required this.onUp});
  final IconData icon;
  final String label;
  final Animation<double> hold;
  final bool on;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.gold300 : SlmColors.ivory;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                          ),
                          border: Border.all(color: ring.withValues(alpha: 0.85), width: 1.8),
                          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        child: Icon(icon, size: 26, color: ring),
                      ),
                    ),
                    if (on)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: hold,
                          builder: (_, _) => CustomPaint(painter: _HoldRing(hold.value)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoldRing extends CustomPainter {
  _HoldRing(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * v,
      false,
      Paint()
        ..color = SlmColors.gold300
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HoldRing old) => old.v != v;
}

class _SenseBubble extends StatelessWidget {
  const _SenseBubble({required this.text, required this.yes});
  final String text;
  final bool yes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: yes ? SlmColors.gold300 : const Color(0xFF6E7C90), width: 1.6),
      ),
      child: Text(text, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xEE101A2B), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

/// The rope reel at his feet (drag it out).
class _RopeReel extends StatelessWidget {
  const _RopeReel();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ReelPainter());
}

class _ReelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 4);
    canvas.drawCircle(c, 15, Paint()..color = const Color(0xFF6B4A2E));
    canvas.drawCircle(c, 12, Paint()..color = const Color(0xFFF2C230));
    final stripe = Paint()
      ..color = const Color(0xFFD33A2C)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, 8, stripe);
    canvas.drawCircle(c, 3.5, Paint()..color = const Color(0xFF6B4A2E));
  }

  @override
  bool shouldRepaint(_ReelPainter old) => false;
}

class _EndButton extends StatelessWidget {
  const _EndButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xEE13233D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SlmColors.gold300, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_rounded, size: 20, color: SlmColors.gold300),
              const SizedBox(width: 8),
              Text(label, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}
