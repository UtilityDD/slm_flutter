import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm5_live_wire_guard_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_live_wire_guard_world.dart' show M5Host, M5Thing, M5WireGeo, M5WireLayout, M5WireRest;

// Lesson 5.6 "শর্ট সার্কিট এবং ওপেন সার্কিট ফল্ট: দুই ভিন্ন শত্রু", কাজ 2
// "ছেঁড়া তার, তবু লাইভ" (pack do_5_6_b, engineType m5_live_wire_guard).
// A lane after a storm: a 415 V LT span has snapped (end A hanging low from
// its pole, end B on the GI fence, the tin shed's roof or the bare road —
// dealt); the crew's rope ring is up. The verb: swipe from the trainee to a
// person to stop them reaching live metal, one at a time.
//
//  1 Opening deck: don't touch it, keep everyone away (lifting it by hand, a
//    foot or a chappal, or pushing it with dry bamboo/a stick = deadly, R14).
//  2 One-time demo toward a grey figure, then 3 waves of people walking to
//    things in the lane. A timely stop of a person headed to live metal is
//    right; a late one (already under the rope or reaching) is a slip (R18);
//    a person who reaches live metal = the scene freezes before contact,
//    deadly (R17, ruling M5-5). Stopping someone headed to something that is
//    not connected is no slip, but it costs: the trainee is busy 1 s after a
//    stop and 2 s after a needless one (the person argues), the wave loses
//    its clean ◆ +5 and the play its quick bonus; from wave 2 one or two
//    such people set off just before a live one, so "stop everyone" can
//    leave him late.
//  3 After each wave a ◆ reason about the subtlest stop (a bicycle leaning on
//    the live fence > the live fence beyond the rope > the fence/shed the wire
//    lies on > the wire itself). The careless coworker after wave 1 or 2:
//    "join the two ends, the lane gets its light back" — listening = deadly
//    (R14; lesson 5.6 myth 2: full system voltage across an open circuit's
//    two ends). The next wave waits for him (holdForCoworker).
//  4 Control room on the phone: "line off, move the wire". Deck: no — written
//    permit, test, earth first (picking it up on a phone "line off" =
//    deadly, R1 / M1 step 17). Then its reason, the pass panel.
//
// Live-ness (lesson 5.6 pro tip 1: a fallen wire may make anything conductive
// it touches live; treat it as live): the wire's two ends; the fence or the
// shed when end B rests on it (all of it, also beyond the rope); a bicycle
// leaning on, or a GI clothesline tied to, a live fence/shed. A visible gap
// = not connected. Keep-away and cordon come from lesson 5.2 (ruling M5-4).
//
// Built on the shared kit (GAME_LEVEL_PLAYBOOK.md): guide first, full scene
// (m5_live_wire_guard_world.dart), corner guide, decks, ◆ table → "কেন …?",
// coworker two beats, mistake cards, freeze, 3 slips strike out. Gesture
// hint (how, never what): in the demo a swipe from the trainee toward the
// grey figure; in a wave a swipe from the trainee in a turning direction that
// points at nobody. Voice: the guide and the control room by device TTS; the
// coworker's push needs his recorded clip (listed for the director).

// ============================================================================
// Content
// ============================================================================

/// The play's steps (one dot each).
enum M5LiveWireStep { opening, wave, call }

/// Which reason a stop asks for (subtlest last).
enum M5WhyKind { opening, wire, near, far, chain, call }

abstract final class M5LiveWireLines {
  static const title = 'ছেঁড়া তার, তবু লাইভ';
  static const intro = 'ঝড়ে গলির তার ছিঁড়ে পড়েছে — কাউকে বিপদে পড়তে দেবেন না!';
  static const steps = ['তার', 'দল 1', 'দল 2', 'দল 3', 'ফোন'];

  // The guide's task now (tap him: the same task, a different way).
  static const askOpen = 'তার ছিঁড়ে পড়ে আছে। প্রথমে কী করবেন?';
  static const askDemo = 'কেউ এগোলে আপনার কাছ থেকে লোকটার দিকে আঙুল টেনে থামান।';
  static const demoDone = 'এভাবেই থামবে। এবার আসল লোকজন আসছে!';
  static const askWave = 'কে কোথায় যাচ্ছে দেখুন — বিপদের দিকে গেলে থামান।';
  static const askWaveNext = 'আবার লোক আসছে — নজর রাখুন।';

  /// A needless stop (he was headed to nothing connected): it cost time.
  static const needless = ['ও তো নিরাপদ দিকে যাচ্ছিল — সময় গেল!', 'ওকে থামানোর দরকার ছিল না — সময় গেল!'];
  static const askCall = 'কন্ট্রোল রুম বলছে লাইন বন্ধ। এখন কী করবেন?';
  static const tasks = [askOpen, askDemo, askWave, askCall];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'গলির ছেঁড়া তার';
  static const callTag = 'কন্ট্রোল রুম';

  /// The control room's call (device TTS), dealt.
  static const calls = [
    'লাইন বন্ধ করা হয়েছে, তারটা সরিয়ে দাও।',
    'ফিডার বন্ধ আছে, তারটা তুলে গলি খালি করো।',
    'লাইন অফ করে দিয়েছি, তারটা সরিয়ে ফেলো।',
  ];

  // The opening deck: the right ones keep away; every wrong one handles the
  // wire (deadly: hand, foot, chappal, dry bamboo or a stick). 33–37 letters.
  static const openRight = ['ছোঁব না — লাইভ ধরে সবাইকে দূরে রাখি', 'তার ছোঁব না, লোকজনকে দূরে সরিয়ে রাখি'];
  static const openHand = [
    'আলো নেই, হাতে তুলে তারটা পাশে রাখি',
    'রাবারের চটি পায়ে তারটা ঠেলে সরাই',
    'লাইন তো মরা, তারটা হাতে গুটিয়ে রাখি',
  ];
  static const openStick = ['শুকনো বাঁশে তুলে তারটা সরিয়ে দিই', 'শুকনো লাঠিতে পেঁচিয়ে তারটা তুলে রাখি'];
  static List<String> get openWrong => [...openHand, ...openStick];

  // The control room deck. 33–38 letters.
  static const callRight = ['না — লিখিত পারমিট, টেস্ট, আর্থ — তারপর', 'আগে লিখিত পারমিট, টেস্ট আর আর্থ, তারপর'];
  static const callWrong = [
    'লাইন তো বন্ধ, এখনই হাতে তুলে সরাই',
    'ফোনেই তো বলল, গ্লাভস পরে তুলে ফেলি',
    'বন্ধ যখন, তারটা গুটিয়ে পোলে বেঁধে দিই',
    'কন্ট্রোল রুম বলেছে, তাই এখনই তুলি',
    'ফোনে বন্ধ শুনেছি, পা দিয়ে সরিয়ে দিই',
  ];

  // The reasons. The right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses. 34–43 letters.
  static const openWhyQ = 'কেন তার ছুঁলেন না?';
  static const callWhyQ = 'লাইন বন্ধের ফোন এল — তবু কেন ধরলেন না?';
  static const why = <M5WhyKind, List<String>>{
    M5WhyKind.opening: ['ছেঁড়া তার মাটিতে পড়লেও লাইভ ধরে নিতে হয়', 'পড়ে থাকা তার যেকোনো মুহূর্তে লাইভ হতে পারে'],
    M5WhyKind.wire: ['মাটিতে পড়া তারও লাইভ, কাছে গেলেই বিপদ', 'ছেঁড়া তারকে সবসময় লাইভ হিসেবেই ধরতে হয়'],
    M5WhyKind.near: ['তার ছুঁয়ে থাকা ধাতুর জিনিসও লাইভ হয়ে যায়', 'পরিবাহী কিছু তার ছুঁলে সেটাও লাইভ হয়ে যায়'],
    M5WhyKind.far: ['তার ছোঁয়া ধাতুর পুরোটাই লাইভ, দড়ির বাইরেও', 'তার ছোঁয়া ধাতুর চারপাশেও দূরে রাখতে হয়'],
    M5WhyKind.chain: ['লাইভ ধাতুতে ঠেকানো জিনিসও লাইভ হয়ে যায়', 'ধাতু ছুঁয়ে ছুঁয়ে কারেন্ট দূরেও চলে আসে'],
    M5WhyKind.call: ['লিখিত পারমিট, টেস্ট আর আর্থ ছাড়া হাত নয়', 'ফোনের কথায় লাইন মরা প্রমাণ হয় না'],
  };
  static const myths = [
    'তার তো মাটিতে পড়ে, কারেন্ট মাটিতে চলে গেছে',
    'আলো নেই মানে লাইনে কারেন্টও তো নেই',
    'দড়ির বাইরের সবকিছু পুরোপুরি নিরাপদ',
    'রাবারের চটি পরা থাকলে কিছুই হয় না',
    'একটু ছুঁয়েই সরে গেলে কোনো শক লাগে না',
    'লাইন তো ট্রিপ করেছে, তাই সবকিছুই মরা',
    'কন্ট্রোল রুম বললেই লাইন মরা ধরে নিই',
  ];
  static List<String> get allWhyRight => [for (final l in why.values) ...l];

  /// The question about the subtlest stop of a wave (it names the thing).
  static String waveWhyQ(M5Thing t) => switch (t) {
        M5Thing.endA || M5Thing.wireB => 'তারের দিকে যাওয়া লোকটাকে কেন থামালেন?',
        M5Thing.fenceNear => 'বেড়াটা তো তার নয় — তবু কেন থামালেন?',
        M5Thing.shedNear => 'টিনের চালাটা তো তার নয় — তবু কেন থামালেন?',
        M5Thing.fenceFar => 'দড়ির বাইরে বেড়ার কাছেও কেন থামালেন?',
        M5Thing.shedFar => 'দড়ির বাইরে চালার কাছেও কেন থামালেন?',
        M5Thing.bicycle => 'সাইকেলটার কাছে কেন যেতে দিলেন না?',
        M5Thing.clothesline => 'কাপড় মেলার তারের কাছে কেন যেতে দিলেন না?',
        _ => 'ওকে কেন থামালেন?',
      };

  /// The careless coworker after wave 1 or 2: join the two ends (his line
  /// is dealt; both need his recorded clip).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _cwRight = [
    'না — দুই মাথার মাঝে ভোল্টেজ, মারাত্মক শক',
    'না — ছেঁড়া দুই মাথার মাঝে পুরো ভোল্টেজ থাকে',
    'না — দুই মাথা ধরলে আমিই সার্কিট পূর্ণ করব',
  ];
  static const _cwWrong = [
    'ঠিক বলেছ, আলো নেই মানে কারেন্টও নেই',
    'একবার জুড়েই দেখি, কিছুই তো হবে না',
    'হ্যাঁ, দুই মাথা পেঁচিয়ে জুড়েই দিই',
    'ঠিক আছে, শুকনো হাতে ধরলে কিছু হয় না',
    'আচ্ছা, চটপট জুড়ে গলিতে আলো ফিরিয়ে দিই',
  ];
  static const _cwAsks = ['ওকে কী বলবেন?', 'ও দুই মাথা জুড়তে চাইছে। কী বলবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];
  static const coworkers = [
    CoworkerScript(
      line: 'আলো তো নেই, লাইন মরা — দুটো মাথা হাতে ধরে জুড়ে দিই, গলিতে আলো ফিরবে!',
      exitLine: coworkerExit,
      right: _cwRight,
      wrong: _cwWrong,
      asks: _cwAsks,
    ),
    CoworkerScript(
      line: 'কারেন্ট তো নেই! ছেঁড়া দুই মাথা পেঁচিয়ে জুড়ে দিই, আলো চলে আসবে!',
      exitLine: coworkerExit,
      right: _cwRight,
      wrong: _cwWrong,
      asks: _cwAsks,
    ),
  ];

  static const callHeld = 'ঠিক! ছেঁড়া তারের দুই মাথার মাঝে পুরো ভোল্টেজ।';
  static const allSet = 'দারুণ! ছেঁড়া তার লাইভ ধরে সবাইকে নিরাপদে দূরে রেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ছেঁড়া তার সবসময় লাইভ; লোকজনকে আগেভাগে থামান।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtDeck = 'ছেঁড়া তার লাইভ ধরেছেন, ছোঁননি';
  static const caughtWaves = 'সবাইকে সময়মতো, দড়ির আগেই থামিয়েছেন';
  static const caughtSubtle = 'তার ছোঁয়া ধাতু দূর থেকেও চিনেছেন';
  static const caughtCall = 'দুই মাথা জোড়ায় “না” বলেছেন';
  static const caughtPhone = 'ফোনের কথায় নয় — পারমিট, টেস্ট, আর্থ';
}

abstract final class M5LiveWireMistakes {
  // Lesson 5.6 points (0-based): 0 short circuit, 1 open circuit ("a broken
  // wire lying on the ground can still touch something and cause a fault"),
  // 2 the comparison (full system voltage across an open circuit's ends).
  static const handLift = DoMistake(
    key: '5.6/m5_live_wire_guard/hand-lift',
    textBn: 'ছেঁড়া তার হাতে, পায়ে বা চটি দিয়ে কখনো নয় — সবসময় লাইভ ধরুন। নিজে দূরে থাকুন, সবাইকে দূরে রাখুন।',
    art: 'assets/game/art/m5_live_wire_guard/hand_lift.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const bambooPush = DoMistake(
    key: '5.6/m5_live_wire_guard/bamboo-push',
    textBn: 'শুকনো বাঁশ বা কাঠও অর্ধ-পরিবাহী — তা দিয়ে লাইভ তার ঠেলা মানেই শক। তার যেখানে আছে থাক, দূরে থাকুন।',
    art: 'assets/game/art/m5_live_wire_guard/bamboo_push.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const joinEnds = DoMistake(
    key: '5.6/m5_live_wire_guard/join-ends',
    textBn: 'ছেঁড়া তারের দুই মাথার মাঝে পুরো সিস্টেম ভোল্টেজ — দুই মাথা ধরলে আপনিই সার্কিট পূর্ণ করে মারাত্মক শক খাবেন।',
    art: 'assets/game/art/m5_live_wire_guard/join_ends.svg',
    deadly: true,
    lessonPoint: 2,
  );
  // Module 1 step 17 (not lesson 5.6's text): no lesson point here.
  static const phoneOff = DoMistake(
    key: '5.6/m5_live_wire_guard/phone-off',
    textBn: 'ফোনে “লাইন বন্ধ” শুনে তারে হাত নয়। লিখিত পারমিট, টেস্টারে মৃত প্রমাণ, আর্থ — তবেই কাজ।',
    art: 'assets/game/art/m5_live_wire_guard/phone_off.svg',
    deadly: true,
  );
  static const bystander = DoMistake(
    key: '5.6/m5_live_wire_guard/bystander',
    textBn: 'লাইভ ধাতুর কাছে মানুষ পৌঁছে গেল! জনসাধারণকে সতর্ক করা ও দূরে রাখা লাইনম্যানের দায়িত্ব — আগেভাগে থামান।',
    art: 'assets/game/art/m5_live_wire_guard/bystander.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const lateStop = DoMistake(
    key: '5.6/m5_live_wire_guard/late-stop',
    textBn: 'দেরিতে থামালেন — লোকটা তখন দড়ির ভেতরে বা হাত বাড়ানোর মুখে। দূরে থাকতেই থামান: জনসাধারণকে দূরে রাখা লাইনম্যানের দায়িত্ব।',
    art: 'assets/game/art/m5_live_wire_guard/late_stop.svg',
    lessonPoint: 1,
  );

  static List<DoMistake> get all => [handLift, bambooPush, joinEnds, phoneOff, bystander, lateStop];
}

/// How subtle a stop was (the reason asks about the subtlest).
M5WhyKind m5WhyKindOf(M5Thing t) => switch (t) {
      M5Thing.endA || M5Thing.wireB => M5WhyKind.wire,
      M5Thing.fenceNear || M5Thing.shedNear => M5WhyKind.near,
      M5Thing.fenceFar || M5Thing.shedFar => M5WhyKind.far,
      M5Thing.bicycle || M5Thing.clothesline => M5WhyKind.chain,
      _ => M5WhyKind.wire,
    };

// ============================================================================
// The deal and the rules (pure)
// ============================================================================

/// One person of a wave: where he is headed and when he sets off.
@immutable
class M5WalkerPlan {
  const M5WalkerPlan({required this.target, required this.startMs, required this.tint, required this.spawnSeed, this.trap = false});
  final M5Thing target;
  final int startMs;
  final int tint;

  /// A live walker right after one or two needless ones (from wave 2): he
  /// takes his tightest way in, so stopping the others first can leave him
  /// late.
  final bool trap;

  /// Picks his way in among the clear ones (see [m5SpawnFor]).
  final int spawnSeed;
}

@immutable
class M5LiveWireDeal {
  const M5LiveWireDeal({required this.layout, required this.waves, required this.coworkerAfter, required this.coworkerLine, required this.callLine});

  final M5WireLayout layout;

  /// Three waves of people (3, 3–4, 4).
  final List<List<M5WalkerPlan>> waves;

  /// The coworker comes after this wave (1 or 2).
  final int coworkerAfter;
  final int coworkerLine;
  final int callLine;
}

const _direct = [M5Thing.endA, M5Thing.wireB];

M5LiveWireDeal m5LiveWireDeal(math.Random rng) {
  final layout = M5WireLayout(
    rest: M5WireRest.values[rng.nextInt(3)],
    mirror: rng.nextBool(),
    bikeHost: rng.nextBool() ? M5Host.fence : M5Host.shed,
    bikeTouch: rng.nextBool(),
    lineHost: rng.nextBool() ? M5Host.fence : M5Host.shed,
    lineTied: rng.nextBool(),
  );
  final live = [for (final t in M5Thing.values) if (layout.live(t)) t];
  final dead = [for (final t in M5Thing.values) if (!layout.live(t)) t];
  final subtle = [for (final t in live) if (!_direct.contains(t)) t];
  final sizes = [3, 3 + rng.nextInt(2), 4];
  final liveN = [1 + rng.nextInt(2), 2, 2];
  final waves = <List<M5WalkerPlan>>[];
  for (var w = 0; w < 3; w++) {
    final lives = <M5Thing>[];
    if (w > 0 && subtle.isNotEmpty) lives.add(subtle[rng.nextInt(subtle.length)]);
    final more = [...live]
      ..removeWhere(lives.contains)
      ..shuffle(rng);
    lives.addAll(more.take(liveN[w] - lives.length));
    final decoys = ([...dead]..shuffle(rng)).take(sizes[w] - lives.length).toList();
    // Wave 1: any order, well apart. From wave 2 the trap: the needless
    // ones set off just before a live one (the subtle one when there is
    // one); the other live one well before or after them.
    final List<M5Thing> order;
    M5Thing? trap;
    if (w == 0) {
      order = [...lives, ...decoys]..shuffle(rng);
    } else {
      trap = lives.first;
      final rest = lives.skip(1).toList();
      order = rest.isNotEmpty && rng.nextBool() ? [...rest, ...decoys, trap] : [...decoys, trap, ...rest];
    }
    var t = rng.nextInt(400);
    final plans = <M5WalkerPlan>[];
    for (final (i, c) in order.indexed) {
      plans.add(M5WalkerPlan(target: c, startMs: t, tint: rng.nextInt(5), spawnSeed: rng.nextInt(7), trap: c == trap));
      final close = trap != null && i + 1 < order.length && decoys.contains(c) && (decoys.contains(order[i + 1]) || order[i + 1] == trap);
      t += close ? 300 + rng.nextInt(300) : 1100 + rng.nextInt(1200);
    }
    waves.add(plans);
  }
  return M5LiveWireDeal(
    layout: layout,
    waves: waves,
    coworkerAfter: 1 + rng.nextInt(2),
    coworkerLine: rng.nextInt(M5LiveWireLines.coworkers.length),
    callLine: rng.nextInt(M5LiveWireLines.calls.length),
  );
}

/// A walk's length in time: about 46 design px a second, 4.2–7 s.
double m5WalkMs(double len) => (len / 46 * 1000).clamp(4200.0, 7000.0);

/// How long after setting off a walker from [from] to [to] becomes "late"
/// (under the rope, or within reach of his target).
double m5LateAfterMs(M5WireGeo geo, Offset from, Offset to, {required bool inRing}) {
  final dur = m5WalkMs((to - from).distance);
  final ring = geo.ring;
  for (var i = 0; i <= 200; i++) {
    final p = i / 200;
    final q = Offset.lerp(from, to, p)!;
    if ((inRing && ring.contains(q)) || (q - to).distance <= M5WireGeo.reach) return p * dur;
  }
  return dur;
}

/// The way in for a walker to [t]: a clear path with time to stop him
/// (≥ 2.2 s before he is late); [seed] picks among those, away from the ways
/// in in [avoid] when it can (people setting off together come in apart).
/// [tight]: the one with the least time (a trap walker).
int m5SpawnFor(M5WireGeo geo, M5Thing t, int seed, {Set<int> avoid = const {}, bool tight = false}) {
  final to = geo.target(t);
  final inRing = geo.layout.inRing(t);
  final spawns = geo.spawns;
  final clear = [
    for (var i = 0; i < spawns.length; i++)
      if (geo.clearPath(spawns[i], to, intoRing: inRing)) i,
  ];
  double window(int i) => m5LateAfterMs(geo, spawns[i], to, inRing: inRing);
  final allGood = [for (final i in clear) if (window(i) >= 2200) i];
  final apart = [for (final i in allGood) if (!avoid.contains(i)) i];
  final good = apart.isNotEmpty ? apart : allGood;
  if (good.isNotEmpty) {
    if (tight) return good.reduce((a, b) => window(a) <= window(b) ? a : b);
    return good[seed % good.length];
  }
  if (clear.isNotEmpty) return clear.reduce((a, b) => window(a) >= window(b) ? a : b);
  return seed % spawns.length;
}

enum M5WalkerState { waiting, walking, stopped, arrived, gone }

enum M5StopKind { ignored, decoy, timely, late }

/// A person in a wave (the run moves him).
class M5Walker {
  M5Walker({
    required this.id,
    required this.plan,
    required this.from,
    required this.to,
    required this.live,
    required this.inRing,
  }) : durMs = m5WalkMs((to - from).distance);

  final int id;
  final M5WalkerPlan plan;
  final Offset from;
  final Offset to;
  final bool live;
  final bool inRing;
  final double durMs;

  var state = M5WalkerState.waiting;
  double? stopMs;
  Offset? stopAt;
  double? arriveMs;
  var late = false;

  double get startMs => plan.startMs.toDouble();
  double get _len => (to - from).distance;

  /// He stands at his target just before touching it.
  double get arriveP => _len <= 8 ? 1 : 1 - 8 / _len;
  double get arriveAtMs => startMs + durMs * arriveP;

  static const standMs = 500.0;
  static const fadeMs = 900.0;
  static const useMs = 900.0;

  Offset posAt(double ms) {
    switch (state) {
      case M5WalkerState.waiting:
      case M5WalkerState.gone:
        return from;
      case M5WalkerState.walking:
        return Offset.lerp(from, to, ((ms - startMs) / durMs).clamp(0.0, arriveP))!;
      case M5WalkerState.stopped:
        return _back(stopAt!, ms - stopMs! - standMs);
      case M5WalkerState.arrived:
        return _back(Offset.lerp(from, to, arriveP)!, ms - arriveMs! - useMs);
    }
  }

  /// Walking back toward where he came from (after [t] ms ≥ 0), 40 px.
  Offset _back(Offset at, double t) {
    if (t <= 0) return at;
    final d = from - at;
    if (d.distance < 1) return at;
    return at + d / d.distance * 40 * (t / fadeMs).clamp(0.0, 1.0);
  }

  double opacityAt(double ms) => switch (state) {
        M5WalkerState.waiting || M5WalkerState.gone => 0,
        M5WalkerState.walking => 1,
        M5WalkerState.stopped => 1 - ((ms - stopMs! - standMs) / fadeMs).clamp(0.0, 1.0),
        M5WalkerState.arrived => 1 - ((ms - arriveMs! - useMs) / fadeMs).clamp(0.0, 1.0),
      };

  /// Walking back (facing where he came from).
  bool turnedAt(double ms) => switch (state) {
        M5WalkerState.stopped => ms - stopMs! > standMs,
        M5WalkerState.arrived => ms - arriveMs! > useMs,
        _ => false,
      };
}

/// The play state (pure logic).
class M5LiveWireRun {
  M5LiveWireRun(this.deal);
  final M5LiveWireDeal deal;

  /// 0 opening deck, 1–3 the waves, 4 the call; 5 = done.
  int index = 0;
  int slips = 0;
  int stepSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The step's work is done (its reason comes next).
  var stepDone = false;

  // The wave.
  final List<M5Walker> walkers = [];
  M5WireGeo? geo;
  double waveMs = 0;
  double busyUntil = 0;
  final List<M5Thing> stoppedLive = [];
  var _anyLate = false;
  var _anySubtle = false;

  /// Needless stops (headed to nothing connected): this wave, this play.
  int stepNeedless = 0;
  int needless = 0;

  /// The trainee is busy this long after a stop (one person at a time)...
  static const busyMs = 1000.0;

  /// ...and this long after a needless one (the person argues back).
  static const needlessBusyMs = 2000.0;

  /// The wave earns its clean ◆ +5: no slip and no needless stop.
  bool get waveClean => stepSlips == 0 && stepNeedless == 0;

  M5LiveWireStep get step => index == 0
      ? M5LiveWireStep.opening
      : index <= 3
          ? M5LiveWireStep.wave
          : M5LiveWireStep.call;
  int get wave => (index - 1).clamp(0, 2);
  bool get done => index >= 5;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !stepDone;
  bool get waveOn => _open && step == M5LiveWireStep.wave && geo != null && walkers.isNotEmpty;
  bool get canStop => waveOn && waveMs >= busyUntil;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stepSlips++;
    return m;
  }

  /// The opening deck's card. Returns the deadly mistake, if any.
  DoMistake? pickOpening(String text) {
    if (!_open || step != M5LiveWireStep.opening) return null;
    if (M5LiveWireLines.openRight.contains(text)) {
      stepDone = true;
      _tag(M5LiveWireLines.caughtDeck);
      return null;
    }
    return deadly = M5LiveWireLines.openStick.contains(text) ? M5LiveWireMistakes.bambooPush : M5LiveWireMistakes.handLift;
  }

  /// The control room deck's card.
  DoMistake? pickCall(String text) {
    if (!_open || step != M5LiveWireStep.call) return null;
    if (M5LiveWireLines.callRight.contains(text)) {
      stepDone = true;
      _tag(M5LiveWireLines.caughtPhone);
      return null;
    }
    return deadly = M5LiveWireMistakes.phoneOff;
  }

  /// Sets the current wave's people walking (their ways in from [g]).
  void startWave(M5WireGeo g) {
    if (!_open || step != M5LiveWireStep.wave) return;
    geo = g;
    walkers.clear();
    stoppedLive.clear();
    waveMs = 0;
    busyUntil = 0;
    final l = deal.layout;
    final plans = deal.waves[wave];
    final used = <int>[];
    for (final (i, p) in plans.indexed) {
      // Away from the ways in of the people who set off just before him.
      final avoid = {
        for (var j = 0; j < i; j++)
          if (p.startMs - plans[j].startMs < 1800) used[j],
      };
      final k = m5SpawnFor(g, p.target, p.spawnSeed, avoid: avoid, tight: p.trap);
      used.add(k);
      walkers.add(M5Walker(id: i, plan: p, from: g.spawns[k], to: g.target(p.target), live: l.live(p.target), inRing: l.inRing(p.target)));
    }
  }

  /// Late: under the rope (target inside it) or within reach of the target.
  bool isLate(M5Walker w, double ms) {
    final g = geo;
    if (g == null) return false;
    final at = w.posAt(ms);
    return (w.inRing && g.ring.contains(at)) || (at - w.to).distance <= M5WireGeo.reach;
  }

  /// Time moves on to [ms]. Returns the walker who reached live metal (the
  /// play ends deadly), if any.
  M5Walker? tick(double ms) {
    if (!waveOn) return null;
    waveMs = ms;
    for (final w in walkers) {
      switch (w.state) {
        case M5WalkerState.waiting:
          if (ms >= w.startMs) w.state = M5WalkerState.walking;
        case M5WalkerState.walking:
          if (ms >= w.arriveAtMs) {
            if (w.live) {
              deadly = M5LiveWireMistakes.bystander;
              return w;
            }
            w.state = M5WalkerState.arrived;
            w.arriveMs = w.arriveAtMs;
          }
        case M5WalkerState.stopped:
          if (ms >= w.stopMs! + M5Walker.standMs + M5Walker.fadeMs) w.state = M5WalkerState.gone;
        case M5WalkerState.arrived:
          if (ms >= w.arriveMs! + M5Walker.useMs + M5Walker.fadeMs) w.state = M5WalkerState.gone;
        case M5WalkerState.gone:
          break;
      }
    }
    if (walkers.every((w) => w.state == M5WalkerState.gone)) {
      stepDone = true;
      if (wave == 2 && !_anyLate) _tag(M5LiveWireLines.caughtWaves);
    }
    return null;
  }

  /// The trainee stops [w] (one at a time).
  ({M5StopKind kind, DoMistake? mistake}) stop(M5Walker w) {
    if (!canStop || w.state != M5WalkerState.walking || waveMs < w.startMs) return (kind: M5StopKind.ignored, mistake: null);
    final late = w.live && isLate(w, waveMs);
    w
      ..stopAt = w.posAt(waveMs)
      ..stopMs = waveMs
      ..state = M5WalkerState.stopped
      ..late = late;
    if (!w.live) {
      busyUntil = waveMs + needlessBusyMs;
      stepNeedless++;
      needless++;
      return (kind: M5StopKind.decoy, mistake: null);
    }
    busyUntil = waveMs + busyMs;
    stoppedLive.add(w.plan.target);
    if (late) {
      _anyLate = true;
      return (kind: M5StopKind.late, mistake: _slip(M5LiveWireMistakes.lateStop));
    }
    if (m5WhyKindOf(w.plan.target).index >= M5WhyKind.far.index) {
      _anySubtle = true;
      _tag(M5LiveWireLines.caughtSubtle);
    }
    return (kind: M5StopKind.timely, mistake: null);
  }

  bool get anySubtle => _anySubtle;

  /// The person a swipe from [trainee] to [to] points at: one within 40 px
  /// of where the finger ended, else the one closest to its direction
  /// (within 26°); null = nobody.
  M5Walker? pick(Offset trainee, Offset to) {
    final open = [for (final w in walkers) if (w.state == M5WalkerState.walking && waveMs >= w.startMs) w];
    if (open.isEmpty) return null;
    M5Walker? near;
    var best = 40.0;
    for (final w in open) {
      final d = (w.posAt(waveMs) - to).distance;
      if (d <= best) {
        best = d;
        near = w;
      }
    }
    if (near != null) return near;
    final dir = to - trainee;
    if (dir.distance < 1) return null;
    M5Walker? aim;
    var bestA = 26 * math.pi / 180;
    for (final w in open) {
      final a = m5AngleBetween(dir, w.posAt(waveMs) - trainee);
      if (a <= bestA) {
        bestA = a;
        aim = w;
      }
    }
    return aim;
  }

  /// The subtlest live stop of this wave (the reason asks about it).
  M5Thing? get subtlest {
    if (stoppedLive.isEmpty) return null;
    return stoppedLive.reduce((a, b) => m5WhyKindOf(b).index > m5WhyKindOf(a).index ? b : a);
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    stepSlips = 0;
    stepNeedless = 0;
    stepDone = false;
    walkers.clear();
    stoppedLive.clear();
  }
}

/// The angle between two directions (radians, 0..π).
double m5AngleBetween(Offset a, Offset b) {
  if (a.distance == 0 || b.distance == 0) return math.pi;
  final c = (a.dx * b.dx + a.dy * b.dy) / (a.distance * b.distance);
  return math.acos(c.clamp(-1.0, 1.0));
}

/// True if a swipe from [from] to [to] points at [target].
bool m5Aims(Offset from, Offset to, Offset target) =>
    (to - target).distance <= 40 || m5AngleBetween(to - from, target - from) <= 30 * math.pi / 180;

/// The gesture hint's direction in a wave: outward from the trainee, turning
/// with [turn], and pointing at nobody ([others] are the people's places).
Offset m5FreeDirection(Offset from, List<Offset> others, int turn) {
  const n = 8;
  final angles = [for (var i = 0; i < n; i++) -math.pi + (i + 0.5) * math.pi / n];
  double clearance(double a) {
    final d = Offset(math.cos(a), math.sin(a));
    var m = math.pi;
    for (final o in others) {
      m = math.min(m, m5AngleBetween(d, o - from));
    }
    return m;
  }

  double? pick;
  for (var k = 0; k < n; k++) {
    final a = angles[(turn * 3 + k) % n];
    if (clearance(a) >= 25 * math.pi / 180) {
      pick = a;
      break;
    }
  }
  pick ??= angles.reduce((a, b) => clearance(a) >= clearance(b) ? a : b);
  return Offset(math.cos(pick), math.sin(pick));
}

/// The quick bonus: a little under a clean play (~85 %, rounded to 10 s).
/// ms: opening deck ~5000 + reason ~8200; demo ~4500; waves 3 × ~11500
/// (fixed walking time) + reasons 3 × ~8200; the call (ring, his line, deck)
/// ~9000 + reason ~8200 (the coworker's moment does not count: the clock
/// stops for him)                                            ≈ 102000
/// 85 % ≈ 87000 → 90 s.
const m5LiveWireQuickMs = 90000;

@immutable
class M5LiveWirePack {
  const M5LiveWirePack({required this.id, required this.titleBn, this.quickMs = m5LiveWireQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5LiveWirePack> m5LiveWirePacks = {
  'do_5_6_b': M5LiveWirePack(id: 'do_5_6_b', titleBn: M5LiveWireLines.title),
};

/// Test hook: the live play's state and screen points (tests only).
class M5LiveWireProbe {
  _GuardRunPageState? _s;
  M5LiveWireRun? get run => _s?._run;
  M5LiveWireDeal? get deal => _s?._run.deal;

  /// intro, opening, demo, wave, between, call, done.
  String get phase => _s?._phase.name ?? 'none';

  /// The trainee's hand on screen (a swipe starts here).
  Offset? get traineeGlobal {
    final s = _s;
    final g = s?._geoNow;
    return s == null || g == null ? null : s._toGlobal(g.traineeHand);
  }

  /// The demo's grey figure on screen.
  Offset? get demoGlobal {
    final s = _s;
    final g = s?._geoNow;
    return s == null || g == null ? null : s._toGlobal(g.demoAt);
  }

  /// Where [w] is on screen now (his chest).
  Offset? walkerGlobal(M5Walker w) {
    final s = _s;
    if (s == null) return null;
    return s._toGlobal(w.posAt(s._run.waveMs) + const Offset(0, -18));
  }
}

// ============================================================================
// Page
// ============================================================================

class M5LiveWireGuardPage extends StatefulWidget {
  const M5LiveWireGuardPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M5LiveWirePack pack;
  final bool muted;
  final int? seed;
  final M5LiveWireProbe? probe;

  @override
  State<M5LiveWireGuardPage> createState() => _M5LiveWireGuardPageState();
}

class _M5LiveWireGuardPageState extends State<M5LiveWireGuardPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GuardRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        probe: widget.probe,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _GuardRunPage extends ConsumerStatefulWidget {
  const _GuardRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.rng,
    required this.onRetry,
    this.probe,
  });

  final LevelContext ctx;
  final M5LiveWirePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M5LiveWireProbe? probe;

  @override
  ConsumerState<_GuardRunPage> createState() => _GuardRunPageState();
}

enum _Phase { intro, opening, demo, wave, between, call, done }

enum _Deck { none, opening, call }

class _GuardRunPageState extends ConsumerState<_GuardRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5LiveWireRun _run;
  late final int _seed = widget.rng.nextInt(1 << 20);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _phase = _Phase.intro;
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

  // The level's own decks (opening, call).
  var _deck = _Deck.none;
  List<ChoiceOption> _deckOpts = const [];
  final Set<String> _deckWrong = {};
  String? _deckPicked;
  var _deckBusy = false;
  var _callShown = false;

  // The wave clock (only while people walk; still otherwise).
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  double _waveMs = 0;
  int _lastStep = -1;
  final _frame = ValueNotifier<int>(0);

  // The demo.
  var _demoShown = false;
  var _demoStopped = false;
  late final AnimationController _demoHand = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _demoHandDone = true);
    });
  var _demoHandDone = false;

  // The trainee's "stop!" (pointing for a moment).
  var _shouting = false;
  var _faceLeft = false;
  Timer? _shoutTimer;
  final List<Timer> _timers = [];

  var _freeze = false;
  Completer<void>? _frozen;
  Offset? _flashAt;
  final _nudge = TaskNudge();
  var _needlessN = 0;
  int _nudgeN = 0;

  // The gesture hand and the swipe.
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  M5WireGeo? _geoNow;
  int _hintTurn = 0;
  Offset? _panFrom;
  Offset? _panTo;

  @override
  void initState() {
    super.initState();
    _run = M5LiveWireRun(m5LiveWireDeal(widget.rng));
    widget.probe?._s = this;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _ticker.dispose();
    _demoHand.dispose();
    _shoutTimer?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    _frame.dispose();
    _chain++;
    if (widget.probe?._s == this) widget.probe?._s = null;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  void _later(int ms, VoidCallback f) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted && !_ended) f();
    }));
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

  /// The guide says [line], then (after a reading time) his bubble goes, so
  /// it never hides part of the lane while people walk.
  Future<void> _sayThenClear(String line, {GuideMood mood = GuideMood.talk}) async {
    final chain = ++_chain;
    final clock = Stopwatch()..start();
    await _say(line, mood: mood);
    final rest = MascotSpeechLibrary.readHold(line) - clock.elapsed;
    if (rest > Duration.zero) await Future<void>.delayed(rest);
    if (!mounted || chain != _chain || _ended) return;
    if (_phase == _Phase.wave || _phase == _Phase.demo) ref.read(guideDirectorProvider.notifier).softClearLine();
  }

  void _hush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  bool get _deckUp => _deck != _Deck.none && _deckOpts.isNotEmpty;

  bool get _canDeck => !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && _deckUp;

  bool get _canSwipe =>
      !_ended &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      !_freeze &&
      ((_phase == _Phase.demo && !_demoStopped) || (_phase == _Phase.wave && !_run.stepDone));

  String get _task => switch (_phase) {
        _Phase.opening => M5LiveWireLines.askOpen,
        _Phase.demo => M5LiveWireLines.askDemo,
        _Phase.call => M5LiveWireLines.askCall,
        _ => _run.index <= 1 ? M5LiveWireLines.askWave : M5LiveWireLines.askWaveNext,
      };

  Offset? _toGlobal(Offset design) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(design);
  }

  // --- the steps -----------------------------------------------------------------
  void _start() {
    _clock.start();
    setState(() {
      _phase = _Phase.opening;
      _deck = _Deck.opening;
      _deckOpts = dealChoices(M5LiveWireLines.openRight, M5LiveWireLines.openWrong, widget.rng);
      _deckWrong.clear();
      _deckPicked = null;
      _wake++;
    });
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayChain([M5LiveWireLines.askOpen], mood: GuideMood.think));
  }

  Future<void> _pickDeck(ChoiceOption o, Offset origin) async {
    if (!_canDeck || _deckBusy || _deckWrong.isNotEmpty || _deckPicked != null) return;
    _hush();
    final kind = _deck;
    if (!o.correct) {
      setState(() => _deckWrong.add(o.textBn));
      final m = kind == _Deck.opening ? _run.pickOpening(o.textBn) : _run.pickCall(o.textBn);
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted || m == null) return;
      await _deadly(m, at: _geoNow?.endB);
      return;
    }
    _deckBusy = true;
    setState(() => _deckPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    if (kind == _Deck.opening) {
      _run.pickOpening(o.textBn);
    } else {
      _run.pickCall(o.textBn);
    }
    _deckBusy = false;
    setState(() {
      _deck = _Deck.none;
      _deckOpts = const [];
      _callShown = false;
      _wake++;
    });
    _stepDone();
  }

  /// The step's work is done: ◆ on the table, then its reason.
  void _stepDone() {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    final idx = _run.index;
    final String q;
    final List<String> right;
    switch (_run.step) {
      case M5LiveWireStep.opening:
        putOnTable(15);
        q = M5LiveWireLines.openWhyQ;
        right = M5LiveWireLines.why[M5WhyKind.opening]!;
      case M5LiveWireStep.call:
        putOnTable(15);
        q = M5LiveWireLines.callWhyQ;
        right = M5LiveWireLines.why[M5WhyKind.call]!;
      case M5LiveWireStep.wave:
        putOnTable(15 + (_run.waveClean ? 5 : 0));
        final t = _run.subtlest ?? M5Thing.endA;
        q = M5LiveWireLines.waveWhyQ(t);
        right = M5LiveWireLines.why[m5WhyKindOf(t)]!;
    }
    unawaited(askReason(
      deal: () => dealChoices(right, M5LiveWireLines.myths, widget.rng),
      question: q,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    switch (_run.index) {
      case 1:
        _startDemo();
      case 2:
      case 3:
        if (_run.index == _run.deal.coworkerAfter + 1) {
          // He comes between the waves; the next wave waits for him (if he
          // has not come by now, the wave start pulls him in; once he has
          // been answered, his answer starts the wave).
          scheduleCoworker();
          _later(2600, () {
            if (!coworkerDone) _beginWave();
          });
        } else {
          _later(900, _beginWave);
        }
      default:
        unawaited(_startCall());
    }
  }

  void _startDemo() {
    setState(() {
      _phase = _Phase.demo;
      _demoShown = true;
      _demoStopped = false;
      _demoHandDone = false;
      _wake++;
    });
    if (!_quiet) unawaited(_demoHand.forward(from: 0));
    unawaited(_sayThenClear(M5LiveWireLines.askDemo));
  }

  void _demoDone() {
    _hush();
    _demoHand.stop();
    _shout(_geoNow?.demoAt);
    setState(() {
      _demoStopped = true;
      _demoHandDone = true;
    });
    unawaited(_sayChain([M5LiveWireLines.demoDone], mood: GuideMood.glad));
    _later(1000, () => setState(() => _demoShown = false));
    _later(2200, _beginWave);
  }

  void _beginWave() {
    if (!mounted || _ended || _phase == _Phase.wave || _run.step != M5LiveWireStep.wave || coworkerOpen) return;
    if (holdForCoworker()) return;
    final geo = _geoNow;
    if (geo == null) return;
    setState(() {
      _phase = _Phase.wave;
      _run.startWave(geo);
      _waveMs = 0;
      _lastStep = -1;
      _wake++;
    });
    unawaited(_sayThenClear(_task));
    _runTicker();
  }

  void _runTicker() {
    if (_ticker.isActive) return;
    _lastTick = Duration.zero;
    unawaited(_ticker.start());
  }

  void _onTick(Duration now) {
    final dt = (now - _lastTick).inMicroseconds / 1000.0;
    _lastTick = now;
    if (_phase != _Phase.wave || _ended) {
      _ticker.stop();
      return;
    }
    if (_card != null || _freeze || coworkerOpen) return;
    _waveMs += dt.clamp(0.0, 64.0);
    final hit = _run.tick(_waveMs);
    if (hit != null) {
      _ticker.stop();
      _frame.value++;
      unawaited(_deadly(M5LiveWireMistakes.bystander, at: hit.to + const Offset(0, -16)));
      return;
    }
    if (_run.stepDone) {
      _ticker.stop();
      _frame.value++;
      setState(() => _phase = _Phase.between);
      _stepDone();
      return;
    }
    final step = (_waveMs / 200).floor();
    if (!_quiet || step != _lastStep) {
      _lastStep = step;
      _frame.value++;
    }
  }

  Future<void> _startCall() async {
    setState(() {
      _phase = _Phase.call;
      _callShown = true;
      _wake++;
    });
    _cue('sounds/learn/dmm_beep.ogg', volume: 0.8);
    await Future<void>.delayed(const Duration(milliseconds: 380));
    _cue('sounds/learn/dmm_beep.ogg', volume: 0.8);
    if (!mounted || _ended) return;
    // The control room on the phone (device TTS); the guide stays quiet.
    final line = M5LiveWireLines.calls[_run.deal.callLine];
    final guide = ref.read(guideDirectorProvider.notifier);
    guide.softClearLine();
    final clock = Stopwatch()..start();
    await MascotSpeechLibrary.speak(line, muted: _muted);
    if (_muted) {
      final rest = MascotSpeechLibrary.readHold(line) - clock.elapsed;
      if (rest > Duration.zero) await Future<void>.delayed(rest);
    }
    if (!mounted || _ended) return;
    setState(() {
      _deck = _Deck.call;
      _deckOpts = dealChoices(M5LiveWireLines.callRight, M5LiveWireLines.callWrong, widget.rng);
      _deckWrong.clear();
      _deckPicked = null;
    });
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayChain([M5LiveWireLines.askCall], mood: GuideMood.think));
  }

  // --- the swipe --------------------------------------------------------------
  void _panStart(DragStartDetails d) {
    _panFrom = d.localPosition;
    _panTo = d.localPosition;
  }

  void _panUpdate(DragUpdateDetails d) => _panTo = d.localPosition;

  void _panEnd(DragEndDetails _) {
    final from = _panFrom;
    final to = _panTo;
    _panFrom = null;
    _panTo = null;
    if (from != null && to != null) _swipe(from, to);
  }

  void _swipe(Offset from, Offset to) {
    final geo = _geoNow;
    if (geo == null || !_canSwipe) return;
    final hand = geo.traineeHand;
    if ((from - hand).distance > 64 || (to - from).distance < 30) {
      _hints.missTap();
      return;
    }
    if (_phase == _Phase.demo) {
      if (m5Aims(hand, to, geo.demoAt)) {
        _demoDone();
      } else {
        _hints.missTap();
      }
      return;
    }
    final w = _run.pick(hand, to);
    if (w == null) {
      _hints.missTap();
      return;
    }
    final r = _run.stop(w);
    if (r.kind == M5StopKind.ignored) return;
    // The pointing pose lasts while he is busy with this person.
    _shout(w.posAt(_run.waveMs), ms: (_run.busyUntil - _run.waveMs).round());
    _frame.value++;
    if (r.kind == M5StopKind.decoy) {
      unawaited(_sayThenClear(M5LiveWireLines.needless[_needlessN++ % M5LiveWireLines.needless.length]));
    }
    final m = r.mistake;
    if (m != null) unawaited(_mistake(m, _toGlobal(w.posAt(_run.waveMs)) ?? Offset.zero));
  }

  /// The trainee points and calls "stop!" at [at].
  void _shout(Offset? at, {int ms = 700}) {
    final geo = _geoNow;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/confirm.ogg', volume: 0.7);
    _shoutTimer?.cancel();
    setState(() {
      _shouting = true;
      _faceLeft = at != null && geo != null && at.dx < geo.traineeHand.dx;
      _wake++;
    });
    _shoutTimer = Timer(Duration(milliseconds: math.max(700, ms)), () {
      if (mounted) setState(() => _shouting = false);
    });
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5LiveWireLines.coworkers[_run.deal.coworkerLine];
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerAfter + 1 || _phase == _Phase.wave) return null;
    if (_card != null || tableBusy || _freeze) return false;
    return true;
  }

  @override
  void coworkerClearGuideBubble() {
    super.coworkerClearGuideBubble();
    // The level's clock stops for him.
    _clock.stop();
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: the two ends in his bare hands.
      _run.failDeadly(M5LiveWireMistakes.joinEnds);
      await _deadly(M5LiveWireMistakes.joinEnds, at: _geoNow?.endA);
      return;
    }
    _clock.start();
    _run.caught.add(M5LiveWireLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5LiveWireLines.callHeld], mood: GuideMood.glad));
    _later(1200, _beginWave);
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_phase == _Phase.intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5LiveWireLines.tapWhy[_nudgeN++ % M5LiveWireLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(!coworkerOpen && !reasonOpen && (_phase == _Phase.wave || _phase == _Phase.demo) ? _sayThenClear(line) : _sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
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
    _hush();
    _ticker.stop();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('livewire/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Someone reached live metal (or the player handled it): the scene freezes
  /// grey and the flash comes off the metal in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m, {Offset? at}) async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
    _clock.stop();
    _hush();
    _demoHand.stop();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _flashAt = at ?? _geoNow?.endB;
      _deck = _Deck.none;
      _deckOpts = const [];
      _callShown = false;
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
    final speak = await SpokenOnce.first('livewire/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5LiveWireLines.deadlyWord : M5LiveWireLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The wave goes on from where it was.
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        if (_phase == _Phase.wave && !_run.stepDone) _runTicker();
        unawaited(_phase == _Phase.wave ? _sayThenClear(_task) : _sayChain([_task]));
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

  /// Quick: under the pack's time, without needless stops (stopping
  /// everyone ends the waves sooner; that must not pay).
  bool get _quick => _clock.elapsedMilliseconds < widget.pack.quickMs && _run.needless == 0;

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _phase = _Phase.done;
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
      if (mark == 100 && _quick) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _quick);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M5LiveWireLines.fail : (_quickBonus ? M5LiveWireLines.quick : M5LiveWireLines.allSet),
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
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_shouting) return LinemanMode.point;
    return LinemanMode.idle;
  }

  /// The people as drawn now (the demo's grey figure first).
  List<M5WalkerView> _views() {
    final geo = _geoNow;
    final out = <M5WalkerView>[];
    if (geo == null) return out;
    if (_demoShown) {
      out.add(M5WalkerView(
        at: geo.demoAt,
        facingLeft: !geo.layout.mirror,
        phase: _demoStopped ? null : 0.25,
        opacity: 0.85,
        tint: 0,
        stopped: _demoStopped,
        grey: true,
      ));
    }
    if (_run.step != M5LiveWireStep.wave) return out;
    final ms = _run.waveMs;
    for (final w in _run.walkers) {
      if (w.state == M5WalkerState.waiting || w.state == M5WalkerState.gone) continue;
      final at = w.posAt(ms);
      final turned = w.turnedAt(ms);
      final walking = w.state == M5WalkerState.walking;
      final reaching = (walking || w.state == M5WalkerState.arrived) && !turned && (at - w.to).distance <= M5WireGeo.reach + 4;
      out.add(M5WalkerView(
        at: at,
        facingLeft: turned ? w.from.dx < at.dx : w.to.dx < w.from.dx,
        phase: walking || turned ? ((ms - w.startMs) / 560) % 1 : null,
        opacity: w.opacityAt(ms),
        tint: w.plan.tint,
        reachTo: reaching ? w.to + const Offset(0, -20) : null,
        stopped: w.state == M5WalkerState.stopped && !turned,
      ));
    }
    return out;
  }

  /// The gesture hand (how to touch, never what): a swipe from the trainee —
  /// toward the demo's grey figure, then in a turning direction that points
  /// at nobody.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final from = geo.traineeHand;
    if (_phase == _Phase.demo) {
      final d = geo.demoAt - from;
      return HintSpec.swipe(from, toward: d / d.distance, travel: math.min(90.0, d.distance * 0.8), space: HintSpace.scene);
    }
    if (_phase == _Phase.wave) {
      final others = [
        for (final w in _run.walkers)
          if (w.state == M5WalkerState.walking) w.posAt(_run.waveMs),
      ];
      return HintSpec.swipe(from, toward: m5FreeDirection(from, others, _hintTurn++), travel: 70, space: HintSpace.scene);
    }
    return null;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5WireGeo.forScene(m.height, m.inset, _run.deal.layout);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final flash = _flashAt;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('lane'),
                child: RepaintBoundary(child: CustomPaint(painter: M5WireLanePainter(geo: geo, seed: _seed))),
              ),
              Positioned.fill(
                key: const ValueKey('people'),
                child: RepaintBoundary(
                  child: CustomPaint(painter: M5WalkersPainter(geo: geo, views: _views, repaint: _frame)),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: Transform.flip(
                  flipX: _faceLeft,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ),
            ],
          ),
        ),
      ),
      // The one-time demo's hand (two laps, then gone; reduced motion: still).
      if (_phase == _Phase.demo && !_demoHandDone && !_freeze)
        Positioned.fill(
          key: const ValueKey('demo-hand'),
          child: IgnorePointer(
            child: quiet
                ? CustomPaint(painter: M5DemoHandPainter(from: geo.traineeHand, to: geo.demoAt, t: 0.7))
                : AnimatedBuilder(
                    animation: _demoHand,
                    builder: (_, _) => CustomPaint(
                      painter: M5DemoHandPainter(from: geo.traineeHand, to: geo.demoAt, t: (_demoHand.value * 2) % 1),
                    ),
                  ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5LiveWireLines.sceneLabel,
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (_) {
              if (_canSwipe) _hints.missTap();
            },
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: _panEnd,
          ),
        ),
      ),
      if (_freeze && flash != null)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M5WireFlashPainter(at: flash, v: v)),
            ),
          ),
        ),
      // The next step: a short fade.
      if (_phase != _Phase.intro && !_freeze)
        Positioned.fill(
          key: ValueKey('step-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.35, end: 0),
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
    final playing = _phase != _Phase.intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp || (_deckUp && playing);
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
              labels: M5LiveWireLines.steps,
              done: {for (var i = 0; i < math.min(_run.index, 5); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: playing && _canSwipe && !deckUp,
            hintKey: '${_phase.name}-${_run.index}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (_callShown && playing)
                Positioned(
                  key: const ValueKey('call-chip'),
                  left: 16,
                  right: 16,
                  top: pad.top + 96,
                  child: _CallChip(line: M5LiveWireLines.calls[_run.deal.callLine], quiet: quiet),
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
                        ? reasonDeck(quiet: quiet, key: ValueKey('why-deck-${_run.index}'))
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('level-deck-${_deck.name}'),
                                options: _deckOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _deckWrong,
                                picked: _deckPicked,
                                onPick: (o, at) => unawaited(_pickDeck(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : 84),
                  onLeft: coworkerOnScreen ? coworkerFromRight : !_run.deal.layout.mirror,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
              if (_phase == _Phase.intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M5LiveWireLines.intro,
                  alarm: 'sounds/learn/wind_gust.ogg',
                  muted: _muted,
                  onDone: _start,
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

/// The control room on the phone: who calls and what he says.
class _CallChip extends StatelessWidget {
  const _CallChip({required this.line, required this.quiet});
  final String line;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xF0101A2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.7), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1F4A33)),
            child: const Icon(Icons.phone_in_talk_rounded, size: 20, color: Color(0xFF9BE3B4)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(M5LiveWireLines.callTag, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
                const SizedBox(height: 2),
                Text(line, style: bangla(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3, color: SlmColors.ivory)),
              ],
            ),
          ),
        ],
      ),
    );
    if (quiet) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, -16 * (1 - v)), child: child)),
      child: card,
    );
  }
}
