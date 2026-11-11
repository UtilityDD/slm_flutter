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
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode, Carry;
import 'm2_hotstick_operate_world.dart';
import 'spoken_once.dart';

export 'm2_hotstick_operate_world.dart' show HsGeo, HsGripPainter;

// Lesson 2.5 "অপারেটিং রড (হট স্টিক): দূরত্বের সুরক্ষা", কাজ 2 "দূর থেকে
// চালাও" (pack do_2_5_b). Three jobs a play on a roadside 11 kV pole, dealt
// fresh: open a DO fuse, close (লাগানো) a DO fuse, switch an AB switch OFF.
// Hands on, each job:
//   1. get ready (order: all before the rod goes up, any order among them):
//      insulated গ্লাভস, face shield (safety tip, point 2), lock the
//      telescopic sections (pro tip 4), fit the right head — fuse puller for a
//      DO fuse, spline/socket for a big switch (points 1, 3; pro tip 3) — and
//      call for the breaker to be opened: off-load (point 3; advanced fact 2
//      says a DO fuse is opened off-load too);
//   2. DO only — where to stand (spot): tap the ground; the fuse must be to
//      the side or a little diagonal, never straight overhead (point 2, step 1);
//   3. the grip (spot): place both hands on the rod (pro tip 2) below the red
//      hand guard (the guard: IEC 60832 insulating sticks; not in the lesson
//      text — flagged);
//   4. hook the ring / the handle's eye (point 2 step 2, point 3);
//   5. operate: DO — turn the face aside, one quick, controlled stroke (step 3,
//      pro tip 1); AB — turn the handle slowly, no hurry (point 3).
// Deadly: raising the rod to a live fuse without insulated গ্লাভস (the
// seed's candidate; the lesson: always গ্লাভস + face shield); turning the AB
// switch on-load (point 3: the huge arc). Slips: no face shield, sections not
// locked, no / wrong head, the DO fuse on-load, standing under the fuse, a
// hand above the guard, the face not turned aside, rushing the AB handle.
// Retries that are not scored: standing too far to reach, a stroke too short or
// too slow (the guide says the lesson's rule and the step stays).
// Shared kit: guide first, full scene, corner guide, ◆ on the table → "কেন …?"
// → the next job by itself; the careless coworker once a play: on a DO job at
// the grip ("রডের মাথার দিকে ধরো" — listening puts a hand above the guard, a
// slip) or on the AB job before the call ("ব্রেকারের খবর লাগবে না" — listening
// means turning it on-load: deadly). His new lines go by device TTS until
// recorded (listed in [HsLines.recordLines]).

// ============================================================================
// Content
// ============================================================================

/// The job on the docket.
enum HsKind { doOpen, doClose, abOff }

/// The get-ready items.
enum HsKit { gloves, shield, lock, offload }

/// The steps of a job.
enum HsPhase { prep, stand, grip, hook, operate, done }

/// What a reason card asks about.
enum HsTopic { stand, stroke, offload, turn }

@immutable
class HsJob {
  const HsJob({required this.kind, required this.phase, required this.topic});
  final HsKind kind;

  /// The DO fuse's phase (0 R, 1 Y, 2 B); the AB switch is gang operated.
  final int phase;
  final HsTopic topic;

  bool get isDo => kind != HsKind.abOff;
  HsHead get head => isDo ? HsHead.puller : HsHead.socket;
}

@immutable
class HsDeal {
  const HsDeal({required this.jobs, required this.callAt});
  final List<HsJob> jobs;

  /// The job the careless coworker comes on.
  final int callAt;
}

/// Three jobs: a DO open, the AB switch, and one more DO (open or close),
/// in a fresh order; the phases and the reason topics dealt too.
HsDeal dealHotstick(math.Random rng) {
  final kinds = [HsKind.doOpen, HsKind.abOff, rng.nextBool() ? HsKind.doClose : HsKind.doOpen]..shuffle(rng);
  final jobs = [
    for (final k in kinds)
      HsJob(
        kind: k,
        phase: rng.nextInt(3),
        topic: k == HsKind.abOff ? (rng.nextBool() ? HsTopic.offload : HsTopic.turn) : (rng.nextBool() ? HsTopic.stand : HsTopic.stroke),
      ),
  ];
  return HsDeal(jobs: jobs, callAt: rng.nextInt(3));
}

abstract final class HsLines {
  static const title = 'দূর থেকে চালাও';
  static const intro = 'আজ রড দিয়ে ফিউজ আর সুইচ চালাবেন — লাইনের কাছে না গিয়ে, দূর থেকে। আগে নিজেকে আর রডকে তৈরি করুন।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The task of each step (what the guide says and repeats when tapped).
  static const askPrep = 'রড তোলার আগে নিজেকে আর রডকে তৈরি করুন।';
  static const askStand = 'কোথায় দাঁড়াবেন? মাটিতে জায়গাটা দেখান।';
  static const askGrip = 'রডটা কোথায় ধরবেন? হাত বসান।';
  static const askHook = 'রডের মাথা ঠিক জায়গায় আটকান।';
  static const askStrokeDo = 'এবার ফিউজটা চালান — এক টানে।';
  static const askTurnAb = 'এবার হ্যান্ডেলটা ঘোরান।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static String ask(HsPhase p, HsJob j) => switch (p) {
    HsPhase.prep => askPrep,
    HsPhase.stand => askStand,
    HsPhase.grip => askGrip,
    HsPhase.hook => askHook,
    HsPhase.operate || HsPhase.done => j.isDo ? askStrokeDo : askTurnAb,
  };
  static const tasks = [askPrep, askStand, askGrip, askHook, askStrokeDo, askTurnAb];

  // Labels a worker reads (buttons, the docket).
  static const sceneLabel = 'পোল আর মাটি';
  static const gripLabel = 'রডের হাতল';
  static const gloves = 'ইনসুলেটেড গ্লাভস';
  static const shield = 'ফেস শিল্ড';
  static const lock = 'সেকশন লক';
  static const puller = 'ফিউজ পুলার';
  static const socket = 'স্প্লাইন সকেট';
  static const offload = 'ব্রেকার খোলাও';
  static const offloadDone = 'ব্রেকার খোলা';
  static const raise = 'রড তুলুন';
  static const faceAside = 'মুখ ফেরান';
  static const faceAsideOn = 'মুখ ফেরানো';
  static const docket = 'ডকেট';
  static const phaseBn = ['R', 'Y', 'B'];
  static String jobBn(HsJob j) => switch (j.kind) {
    HsKind.doOpen => 'ডিও ফিউজ খুলুন · ${phaseBn[j.phase]} ফেজ',
    HsKind.doClose => 'ডিও ফিউজ লাগান · ${phaseBn[j.phase]} ফেজ',
    HsKind.abOff => 'AB সুইচ বন্ধ (OFF)',
  };

  // Not scored: the guide says the rule, the step stays.
  static const tooFar = 'এত দূর থেকে রড ঠিকমতো আটকানো যায় না। পাশে থাকুন, তবে কাছে।';
  static const missHook = 'রিং-এ দৃঢ়ভাবে আটকান — রডের মাথা ঠিক জায়গায় নিন।';
  static const missHandle = 'সকেটটা হ্যান্ডেলের সাথে ঠিকমতো লাগান।';
  static const shortStroke = 'আধা টান হলো। একটি দ্রুত আর নিয়ন্ত্রিত টানে — পুরোটা।';
  static const slowStroke = 'এত ধীরে নয়। ফিউজ খোলে একটি দ্রুত, নিয়ন্ত্রিত টানে।';
  static const shortTurn = 'হ্যান্ডেলটা পুরো ঘোরান — ধীরে, নিয়ন্ত্রিতভাবে।';
  static const oneHand = 'আরেক হাত — হট স্টিক দুই হাতে ধরুন।';

  // The reasons (lesson 2.5): the right ones fit the step asked; the wrong
  // ones are the lesson's myths and field excuses — never a true rule.
  static const whyStand = 'কেন ফিউজের ঠিক নিচে দাঁড়ালেন না?';
  static const whyStroke = 'কেন মুখ সরিয়ে, এক টানে খুললেন?';
  static const whyStrokeClose = 'কেন মুখ সরিয়ে, এক ঠেলায় লাগালেন?';
  static const whyOffload = 'কেন আগে ব্রেকার খোলালেন?';
  static const whyTurn = 'কেন হ্যান্ডেলটা ধীরে ঘোরালেন?';
  static String why(HsJob j) => switch (j.topic) {
    HsTopic.stand => whyStand,
    HsTopic.stroke => j.kind == HsKind.doClose ? whyStrokeClose : whyStroke,
    HsTopic.offload => whyOffload,
    HsTopic.turn => whyTurn,
  };

  static const standWhy = ['ফ্ল্যাশে গরম গ্যাস-ধাতু মুখে পড়তে পারে', 'ফিউজ পাশে বা কোণাকুণি রাখাই সঠিক অবস্থান'];
  static const strokeWhy = ['চালানোর সময় ফ্ল্যাশ হতে পারে, তাই মুখ সরাই', 'দ্রুত আর নিয়ন্ত্রিত এক টানে চালানোই নিয়ম'];
  static const offloadWhy = ['আইসোলেটরে আর্ক নেভানোর কোনো ব্যবস্থা নেই', 'অন-লোডে ঘোরালে বিশাল আর্ক তৈরি হতে পারে'];
  static const turnWhy = ['বড় সুইচ ধীরে, নিয়ন্ত্রিতভাবে ঘোরানোর নিয়ম', 'তাড়াহুড়ো নয়, সকেট হ্যান্ডেলে বসিয়ে ঘোরাই'];
  static List<String> whyRight(HsJob j) => switch (j.topic) {
    HsTopic.stand => standWhy,
    HsTopic.stroke => strokeWhy,
    HsTopic.offload => offloadWhy,
    HsTopic.turn => turnWhy,
  };

  /// Wrong reasons (the lesson's myths and field excuses).
  static const whyWrong = [
    'শুকনো বাঁশের লাঠিতেও একই কাজ হয়ে যায়',
    'জোরে ঝাঁকুনি দিলে কাজটা তাড়াতাড়ি হয়',
    'সুপারভাইজার দাঁড়িয়ে, তাড়াতাড়ি সারতে হবে',
    'রডে সামান্য আঁচড় থাকলেও কিছু হয় না',
    'অভ্যাস আছে, এত নিয়মের দরকার পড়ে না',
    'রড তো লম্বা, কোথায় দাঁড়ালাম তাতে কী',
  ];

  /// The careless coworker on a DO job, at the grip.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerDo = CoworkerScript(
    line: 'রডের মাথার দিকে ধরো, জোর বেশি পাবে! নিচে ধরে কী হবে?',
    exitLine: coworkerExit,
    right: ['না, দুই হাতে গার্ডের নিচেই ধরব', 'না, জোর নয়, মসৃণ টানই আসল কথা', 'গার্ডের ওপরে হাত নয়, নিচেই ধরছি'],
    wrong: [
      'ঠিক, মাথার দিকে ধরলে জোর বেশি',
      'আচ্ছা, ওপরের দিকে ধরেই টানছি',
      'এক হাতে মাথার কাছে ধরলেই হবে',
      'জোরে ঝাঁকুনি দিলেই খুলে যাবে',
      'ঠিক আছে, গার্ড-টার্ড লাগে না',
    ],
    asks: ['ও বলছে মাথার দিকে ধরতে। আপনি?', 'কোথায় ধরবেন — ওর কথায়, না নিয়মে?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// The careless coworker on the AB job, before the call.
  static const coworkerAb = CoworkerScript(
    line: 'ব্রেকারের খবর নিতে হবে না, সোজা ঘুরিয়ে দাও!',
    exitLine: coworkerExit,
    right: ['না, আগে ব্রেকার খোলা নিশ্চিত করব', 'না, অফ-লোড না করে আমি ঘোরাব না', 'আগে ফোন করে ব্রেকার খোলাচ্ছি'],
    wrong: [
      'ঠিক, সোজা ঘুরিয়েই দিচ্ছি',
      'আচ্ছা, ফোনের কোনো দরকার নেই',
      'লোড থাকলেও সুইচটা খুলে যাবে',
      'তাড়াতাড়ি ঘুরিয়ে কাজ সারি',
      'ঠিক আছে, খবর পরে নিয়ে নেব',
    ],
    asks: ['ও বলছে ব্রেকারের খবর ছাড়াই ঘোরাতে। আপনি?', 'ওর কথায় ঘোরাবেন, না আগে ব্রেকার?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// New lines for him (device TTS until recorded in his voice).
  static List<String> get recordLines => [coworkerDo.line, coworkerAb.line];

  static const callHeld = 'ঠিক! চাপে পড়ে নিয়ম ভাঙবেন না।';
  static const allSet = 'দূর থেকে, নিয়ম মেনে — ফিউজ আর সুইচ, দুটোই চালাতে শিখলেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — তৈরি হওয়া, দাঁড়ানো, ধরা, তারপর এক টানে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtKit = 'গ্লাভস, ফেস শিল্ড, লক — রড তোলার আগে';
  static const caughtStand = 'ফিউজের নিচে নয়, পাশে দাঁড়ানো';
  static const caughtGrip = 'দুই হাতে, গার্ডের নিচে ধরা';
  static const caughtStroke = 'মুখ সরিয়ে এক টানে';
  static const caughtOffload = 'AB সুইচ — আগে ব্রেকার খোলা';
  static const caughtTurn = 'হ্যান্ডেল ধীরে ঘোরানো';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class HsMistakes {
  static const _dir = 'assets/game/art/m2_hotstick_operate';

  static const noGloves = DoMistake(
    key: '2.5/hotstick-op/no-gloves',
    textBn: 'গ্লাভস ছাড়া লাইভ ফিউজে রড তুললেন। রড ভেজা বা নোংরা হলে ইনসুলেশন কমে যায় — সবসময় ইনসুলেটেড গ্লাভস আর ফেস শিল্ড পরে তবেই কাজ।',
    art: '$_dir/hs_gloves.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const noShield = DoMistake(
    key: '2.5/hotstick-op/no-shield',
    textBn: 'ফেস শিল্ড বা সেফটি গগলস ছাড়া রড তুললেন। ফিউজ চালানোর সময় আর্ক বা ফ্ল্যাশ হতে পারে — গরম গ্যাস বা গলিত ধাতু মুখে লাগে।',
    art: '$_dir/hs_shield.svg',
    lessonPoint: 1,
  );

  /// Pro tip 4 (not a lesson point: "পাঠে দেখুন" opens the lesson from its start).
  static const unlocked = DoMistake(
    key: '2.5/hotstick-op/sections-unlocked',
    textBn: 'টেলিস্কোপিক রডের সেকশন লক না করেই তুললেন। ব্যবহারের আগে প্রতিটি সেকশন ঠিকমতো লক করা আছে কি না দেখুন।',
    art: '$_dir/hs_lock.svg',
  );
  static const badHead = DoMistake(
    key: '2.5/hotstick-op/wrong-attachment',
    textBn: 'ডিও ফিউজে ফিউজ পুলার, বড় সুইচে স্প্লাইন বা সকেট — রডের মাথায় ঠিক অ্যাটাচমেন্ট, শক্ত করে লাগানো চাই। ঢিলা অ্যাটাচমেন্ট ওপর থেকে পড়ে বিপদ ঘটায়।',
    art: '$_dir/hs_head.svg',
    lessonPoint: 0,
  );
  static const onLoadAb = DoMistake(
    key: '2.5/hotstick-op/ab-on-load',
    textBn: 'ব্রেকার খোলা নিশ্চিত না করেই AB সুইচ ঘোরালেন। অন-লোডে বিশাল আর্ক তৈরি হয় — সুইচ আর মানুষ, দুজনেই শেষ। আগে ব্রেকার খুলে লাইন অফ-লোড।',
    art: '$_dir/hs_offload.svg',
    deadly: true,
    lessonPoint: 2,
  );

  /// Advanced fact 2 (a DO fuse cannot quench an arc either): no lesson point.
  static const onLoadDo = DoMistake(
    key: '2.5/hotstick-op/do-on-load',
    textBn: 'লাইন অফ-লোড না করেই ডিও ফিউজ চালালেন। ডিও ফিউজে আর্ক নেভানোর ব্যবস্থা নেই — তাই অফ-লোড অবস্থায় চালানোর নিয়ম।',
    art: '$_dir/hs_offload.svg',
  );
  static const underFuse = DoMistake(
    key: '2.5/hotstick-op/under-the-fuse',
    textBn: 'ফিউজের ঠিক নিচে দাঁড়ালেন। ফ্ল্যাশ হলে গরম গ্যাস বা গলিত ধাতু মুখে-শরীরে পড়ে — ফিউজ থাকবে আপনার পাশে বা সামান্য কোণাকুণি।',
    art: '$_dir/hs_stand.svg',
    lessonPoint: 1,
  );
  static const aboveGuard = DoMistake(
    key: '2.5/hotstick-op/above-the-guard',
    textBn: 'হাত গার্ডের ওপরে উঠে গেল। হট স্টিক ধরুন দুই হাতে, লাল হ্যান্ড গার্ডের নিচে — ওপরে হাত মানে লাইন আর হাতের মাঝে ইনসুলেশন কমে যাওয়া।',
    art: '$_dir/hs_grip.svg',
    lessonPoint: 0,
  );
  static const faceIn = DoMistake(
    key: '2.5/hotstick-op/face-not-aside',
    textBn: 'মুখ না সরিয়েই টানলেন। চালানোর মুহূর্তে আর্ক বা ফ্ল্যাশ হতে পারে — মুখ আর শরীর একপাশে সরিয়ে রাখুন।',
    art: '$_dir/hs_stand.svg',
    lessonPoint: 1,
  );
  static const rushAb = DoMistake(
    key: '2.5/hotstick-op/ab-rushed',
    textBn: 'হ্যান্ডেলটা ঝটকায় ঘোরালেন। বড় সুইচ ঘোরাতে হয় ধীরে ধীরে, নিয়ন্ত্রিতভাবে — তাড়াহুড়ো করবেন না।',
    art: '$_dir/hs_offload.svg',
    lessonPoint: 2,
  );

  static const all = [noGloves, noShield, unlocked, badHead, onLoadAb, onLoadDo, underFuse, aboveGuard, faceIn, rushAb];
}

/// Where a tap on the ground leaves the trainee, against the fuse.
enum HsStand { under, side, far }

/// |dx| from the fuse (design px): under < 26 ≤ side ≤ 130 < far.
HsStand hsStandOf(double dx) {
  final d = dx.abs();
  if (d < 26) return HsStand.under;
  if (d <= 130) return HsStand.side;
  return HsStand.far;
}

/// What a stroke / turn came to.
enum HsStroke { short, slow, done }

/// The DO stroke: one drag of ≥ 70 design px within 1.2 s (quick and
/// controlled); the AB turn: ≥ 110 px, and under 0.9 s is a rush.
const kHsStrokePx = 70.0;
const kHsStrokeMaxMs = 1200;
const kHsTurnPx = 110.0;
const kHsTurnMinMs = 900;

/// The play state (pure logic).
class HsRun {
  HsRun(this.deal);
  final HsDeal deal;
  int index = 0;
  HsPhase phase = HsPhase.prep;
  final Set<HsKit> kit = {};
  HsHead head = HsHead.none;
  var faceAside = false;

  /// Listened to him on the AB job: the call was never made.
  var skippedCall = false;
  int slips = 0;
  int jobSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.jobs.length;
  bool get ended => done || deadly != null;
  HsJob get job => deal.jobs[index.clamp(0, deal.jobs.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get clean => jobSlips == 0;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    jobSlips++;
    return m;
  }

  /// Put on / do a get-ready item (only before the rod goes up).
  void wear(HsKit k) {
    if (ended || phase != HsPhase.prep) return;
    if (k == HsKit.offload && skippedCall) return;
    kit.add(k);
  }

  /// Fit a head on the rod (the last one fitted counts).
  void fit(HsHead h) {
    if (ended || phase != HsPhase.prep) return;
    head = h;
  }

  /// The rod goes up: the most serious thing missing is the mistake (one
  /// per raise); the guide then puts the rest right and the job goes on.
  DoMistake? raise() {
    if (ended || phase != HsPhase.prep) return null;
    final j = job;
    DoMistake? m;
    if (!kit.contains(HsKit.gloves)) {
      return deadly = HsMistakes.noGloves;
    } else if (head != j.head) {
      m = _slip(HsMistakes.badHead);
    } else if (!kit.contains(HsKit.lock)) {
      m = _slip(HsMistakes.unlocked);
    } else if (!kit.contains(HsKit.shield)) {
      m = _slip(HsMistakes.noShield);
    }
    if (m == null) _tag(HsLines.caughtKit);
    kit.addAll(const [HsKit.gloves, HsKit.shield, HsKit.lock]);
    head = j.head;
    phase = j.isDo ? HsPhase.stand : HsPhase.grip;
    return m;
  }

  /// DO: where he stands ([dx] from the fuse). Too far = not scored, stay.
  (HsStand, DoMistake?) stand(double dx) {
    if (ended || phase != HsPhase.stand) return (HsStand.far, null);
    final s = hsStandOf(dx);
    if (s == HsStand.far) return (s, null);
    phase = HsPhase.grip;
    if (s == HsStand.under) return (s, _slip(HsMistakes.underFuse));
    _tag(HsLines.caughtStand);
    return (s, null);
  }

  /// Both hands on the rod: [above] = a hand above the guard.
  DoMistake? grip({required bool above}) {
    if (ended || phase != HsPhase.grip) return null;
    phase = HsPhase.hook;
    if (above) return _slip(HsMistakes.aboveGuard);
    _tag(HsLines.caughtGrip);
    return null;
  }

  void hook() {
    if (!ended && phase == HsPhase.hook) phase = HsPhase.operate;
  }

  void turnFace() {
    if (!ended && phase == HsPhase.operate && job.isDo) faceAside = true;
  }

  /// The stroke (DO) or the turn (AB): [px] along the gesture, over [ms].
  /// Returns what it came to and the mistake, if any. On-load comes first.
  (HsStroke, DoMistake?) operate(double px, int ms) {
    if (ended || phase != HsPhase.operate) return (HsStroke.short, null);
    final j = job;
    if (j.isDo) {
      if (px < kHsStrokePx) return (HsStroke.short, null);
      if (ms > kHsStrokeMaxMs) return (HsStroke.slow, null);
    } else if (px < kHsTurnPx) {
      return (HsStroke.short, null);
    }
    phase = HsPhase.done;
    final off = kit.contains(HsKit.offload) && !skippedCall;
    if (!j.isDo) {
      if (!off) return (HsStroke.done, deadly = HsMistakes.onLoadAb);
      _tag(HsLines.caughtOffload);
      if (ms < kHsTurnMinMs) return (HsStroke.done, _slip(HsMistakes.rushAb));
      _tag(HsLines.caughtTurn);
      return (HsStroke.done, null);
    }
    if (!off) return (HsStroke.done, _slip(HsMistakes.onLoadDo));
    if (!faceAside) return (HsStroke.done, _slip(HsMistakes.faceIn));
    _tag(HsLines.caughtStroke);
    return (HsStroke.done, null);
  }

  void next() {
    index++;
    phase = HsPhase.prep;
    kit.clear();
    head = HsHead.none;
    faceAside = false;
    skippedCall = false;
    jobSlips = 0;
  }
}

/// The quick bonus (~85 % of a thorough play, rounded to 10 s). A job:
/// get ready 5 taps × 1500 + raise 1500 + stand 2000 + grip 3000 + hook 2000
/// + stroke 2000 + the fuse moving 1500 + reason 8200 ≈ 27700 × 3 = 83100,
/// + the coworker once ≈ 9000 → 92100; 85 % ≈ 78300 → 80 s.
const kHsQuickMs = 80000;

@immutable
class M2HotstickOperatePack {
  const M2HotstickOperatePack({required this.id, required this.titleBn, this.quickMs = kHsQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M2HotstickOperatePack> m2HotstickOperatePacks = {'do_2_5_b': M2HotstickOperatePack(id: 'do_2_5_b', titleBn: HsLines.title)};

/// Where the rod's head must go for [j] (design px).
Offset hsTargetOf(HsGeo geo, HsJob j, {required bool open}) => j.isDo ? (open ? geo.ringOpenOf(j.phase) : geo.ringOf(j.phase)) : geo.handle;

/// The trainee's box standing with his centre at [x].
Rect hsTraineeBox(HsGeo geo, double x) {
  final h = geo.man;
  return Rect.fromLTWH(x - h / 4, geo.groundY - h + 4, h / 2, h);
}

/// Where he starts (left, by the van) and where he stands for the AB switch.
const kHsStartX = 52.0;
const kHsAbX = 96.0;

// ============================================================================
// Page
// ============================================================================

class M2HotstickOperatePage extends StatefulWidget {
  const M2HotstickOperatePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2HotstickOperatePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2HotstickOperatePage> createState() => _M2HotstickOperatePageState();
}

class _M2HotstickOperatePageState extends State<M2HotstickOperatePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _HsRunPage(
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

class _HsRunPage extends ConsumerStatefulWidget {
  const _HsRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2HotstickOperatePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_HsRunPage> createState() => _HsRunPageState();
}

class _HsRunPageState extends ConsumerState<_HsRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final HsRun _run = HsRun(dealHotstick(widget.rng));
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

  /// Where the trainee stands (design x).
  double _standX = kHsStartX;

  /// The hands on the grip close-up (fractions from the butt).
  final List<double> _hands = [];

  /// Which DO fuses hang open; the AB switch is OFF.
  List<bool> _open = const [false, false, false];
  var _abOff = false;

  /// The flash at the contact when the fuse moves (a one-shot).
  int _flashN = 0;
  Offset? _flashAt;

  // The stroke being drawn.
  Duration? _panT0;
  Duration _panT1 = Duration.zero;
  Offset _panSum = Offset.zero;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  HsJob get _job => _run.job;

  @override
  void dispose() {
    disposeCoworker();
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

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen;

  void _start() {
    _clock.start();
    _startJob();
  }

  void _startJob() {
    final j = _job;
    setState(() {
      _standX = j.isDo ? kHsStartX : kHsAbX;
      _hands.clear();
      _flashAt = null;
      _open = [for (var i = 0; i < 3; i++) j.kind == HsKind.doClose];
      _abOff = false;
      _wake++;
    });
    if (_run.index == _run.deal.callAt && !j.isDo) scheduleCoworker();
    unawaited(_sayChain([HsLines.askPrep]));
  }

  // --- 1. get ready --------------------------------------------------------------
  void _wear(HsKit k) {
    if (!_canPlay || _run.phase != HsPhase.prep) return;
    if (k == HsKit.offload && _run.skippedCall) return;
    HapticFeedback.selectionClick();
    _cue(k == HsKit.offload ? 'sounds/quiz_select.wav' : 'sounds/learn/tag_slap.wav', volume: 0.45);
    setState(() {
      _run.wear(k);
      _wake++;
    });
  }

  void _fit(HsHead h) {
    if (!_canPlay || _run.phase != HsPhase.prep) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    setState(() {
      _run.fit(h);
      _wake++;
    });
  }

  Future<void> _raise(Offset origin) async {
    if (!_canPlay || _run.phase != HsPhase.prep) return;
    _hush();
    final m = _run.raise();
    if (m != null && m.deadly) {
      await _deadly(m, at: hsTargetOf(_geoNow, _job, open: _open[_job.phase]));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/confirm.ogg', volume: 0.5);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _askStep();
  }

  void _askStep() {
    if (_run.phase == HsPhase.grip && _run.index == _run.deal.callAt && _job.isDo) scheduleCoworker();
    unawaited(_sayChain([HsLines.ask(_run.phase, _job)]));
  }

  // --- 2. where to stand ----------------------------------------------------------
  HsGeo _geoNow = HsGeo.forScene(780, 0);

  Future<void> _tapScene(Offset p) async {
    if (!_canPlay) return;
    final geo = _geoNow;
    final j = _job;
    switch (_run.phase) {
      case HsPhase.stand:
        if (p.dy < geo.groundY - 30) return;
        final x = p.dx.clamp(16.0, 344.0);
        final (s, m) = _run.stand(x - HsGeo.phaseX[j.phase]);
        HapticFeedback.selectionClick();
        _cue('sounds/intro/tick.ogg', volume: 0.45);
        if (s == HsStand.far) {
          unawaited(_sayChain([HsLines.tooFar]));
          return;
        }
        setState(() {
          _standX = x;
          _wake++;
        });
        if (m != null) {
          unawaited(_levelDelta(-10, _toGlobal(p), mood: GuideMood.warn));
          await _slip(m);
          return;
        }
        _askStep();
      case HsPhase.hook:
        final target = hsTargetOf(geo, j, open: _open[j.phase]);
        if ((p - target).distance > 30) {
          HapticFeedback.selectionClick();
          unawaited(_sayChain([j.isDo ? HsLines.missHook : HsLines.missHandle]));
          return;
        }
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.wav', volume: 0.6);
        setState(() {
          _run.hook();
          _wake++;
        });
        _askStep();
      case HsPhase.prep || HsPhase.grip || HsPhase.operate || HsPhase.done:
        break;
    }
  }

  Offset _toGlobal(Offset design) {
    final size = MediaQuery.sizeOf(context);
    return design * (size.width / 360);
  }

  // --- 3. the grip ----------------------------------------------------------------
  Future<void> _placeHand(double frac) async {
    if (!_canPlay || _run.phase != HsPhase.grip || _hands.length >= 2) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    setState(() => _hands.add(frac.clamp(0.04, 0.96)));
    if (_hands.length < 2) {
      unawaited(_sayChain([HsLines.oneHand]));
      return;
    }
    await _gripDone(_hands.any((f) => f > HsGripPainter.guardFrac), _toGlobal(Offset(180, _geoNow.groundY - 120)));
  }

  Future<void> _gripDone(bool above, Offset origin) async {
    _hush();
    final m = _run.grip(above: above);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _wake++);
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _askStep();
  }

  // --- 5. the stroke / the turn ----------------------------------------------------
  void _turnFace() {
    if (!_canPlay || _run.phase != HsPhase.operate) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    setState(() {
      _run.turnFace();
      _wake++;
    });
  }

  void _panStart(DragStartDetails d) {
    _panT0 = d.sourceTimeStamp ?? Duration.zero;
    _panT1 = _panT0!;
    _panSum = Offset.zero;
  }

  void _panUpdate(DragUpdateDetails d) {
    if (_panT0 == null) return;
    _panSum += d.delta;
    _panT1 = d.sourceTimeStamp ?? _panT1;
  }

  Future<void> _panEnd(DragEndDetails d) async {
    final t0 = _panT0;
    _panT0 = null;
    if (t0 == null || !_canPlay || _run.phase != HsPhase.operate) return;
    final j = _job;
    final ms = (_panT1 - t0).inMilliseconds;
    // DO open: pull down; DO close: push up; AB: across.
    final px = switch (j.kind) {
      HsKind.doOpen => _panSum.dy,
      HsKind.doClose => -_panSum.dy,
      HsKind.abOff => _panSum.dx.abs(),
    };
    await _operate(px, ms);
  }

  Future<void> _operate(double px, int ms) async {
    final j = _job;
    final (s, m) = _run.operate(px, ms);
    switch (s) {
      case HsStroke.short:
        unawaited(_sayChain([j.isDo ? HsLines.shortStroke : HsLines.shortTurn]));
        return;
      case HsStroke.slow:
        unawaited(_sayChain([HsLines.slowStroke]));
        return;
      case HsStroke.done:
        break;
    }
    final geo = _geoNow;
    final at = hsTargetOf(geo, j, open: _open[j.phase]);
    if (m != null && m.deadly) {
      await _deadly(m, at: at);
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue(j.isDo ? 'sounds/learn/tag_slap.wav' : 'sounds/intro/confirm.ogg', volume: 0.7);
    setState(() {
      if (j.isDo) {
        _open = [for (var i = 0; i < 3; i++) i == j.phase ? j.kind == HsKind.doOpen : _open[i]];
        _flashAt = j.kind == HsKind.doOpen ? geo.ringOf(j.phase) + const Offset(4, 0) : geo.ringOf(j.phase);
        _flashN++;
      } else {
        _abOff = true;
      }
      _wake++;
    });
    if (m != null) {
      unawaited(_levelDelta(-10, _toGlobal(at), mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _jobDone();
  }

  /// The job is done: its ◆ on the table, then "কেন …?".
  void _jobDone() {
    final j = _job;
    final idx = _run.index;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(
      askReason(
        deal: () => dealChoices(HsLines.whyRight(j), HsLines.whyWrong, widget.rng),
        question: HsLines.why(j),
        stillValid: () => _run.index == idx && !_ended,
      ),
    );
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startJob();
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
    unawaited(
      Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (mounted && !_ended && _run.index == idx) _next();
      }),
    );
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _run.deal.jobs[_run.deal.callAt].isDo ? HsLines.coworkerDo : HsLines.coworkerAb;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt) return null;
    final j = _job;
    if (j.isDo) {
      if (_run.phase != HsPhase.grip || _hands.length >= 2) return _run.phase.index > HsPhase.grip.index ? null : false;
    } else {
      if (_run.phase != HsPhase.prep || _run.kit.contains(HsKit.offload)) return null;
    }
    if (_intro || _busy || _card != null || reasonOpen) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final j = _job;
    if (!held) {
      if (j.isDo) {
        // His grip: both hands up by the head, above the guard.
        setState(() {
          _hands
            ..clear()
            ..addAll(const [0.7, 0.86]);
        });
        await _gripDone(true, origin);
      } else {
        // No call: the breaker stays closed; the turn will come on-load.
        setState(() => _run.skippedCall = true);
        unawaited(_sayChain([HsLines.askPrep]));
      }
      return;
    }
    _run.caught.add(HsLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    if (!j.isDo) setState(() => _run.wear(HsKit.offload));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    unawaited(_sayChain([HsLines.callHeld, HsLines.ask(_run.phase, j)]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
        ? HsLines.tapWhy[_nudgeN++ % HsLines.tapWhy.length]
        : _nudge.next(HsLines.ask(_run.phase, _job));
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
    final speak = await SpokenOnce.first('hsop/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The yard freezes grey; the arc flashes at [at] in colour; then
  /// near-miss or death.
  Offset? _deathAt;
  Future<void> _deadly(DoMistake m, {required Offset at}) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/accident.wav', volume: 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _deathAt = at;
    });
    await frozen.future;
    if (!mounted) return;
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('hsop/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? HsLines.deadlyWord : HsLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        // The guide put it right; the job goes on (or is done).
        if (_run.phase == HsPhase.done) {
          _jobDone();
        } else {
          if (_run.phase == HsPhase.grip || _run.phase == HsPhase.hook) {
            if (_standX != kHsAbX && _job.isDo && hsStandOf(_standX - HsGeo.phaseX[_job.phase]) == HsStand.under) {
              // Stepped aside, to the fuse's side.
              setState(() => _standX = HsGeo.phaseX[_job.phase] - 70);
            }
          }
          if (_run.phase == HsPhase.hook) {
            setState(() {
              _hands
                ..clear()
                ..addAll(const [0.12, 0.3]);
            });
          }
          _askStep();
        }
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
    await _say(!_run.passed ? HsLines.fail : (_quickBonus ? HsLines.quick : HsLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_run.phase == HsPhase.prep) return LinemanMode.idle;
    return LinemanMode.hold;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = HsGeo.forScene(m.height, m.inset);
    final j = _job;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final gloved = _run.kit.contains(HsKit.gloves);
    final up = _run.phase.index >= HsPhase.stand.index;
    final tb = hsTraineeBox(geo, _standX);
    final target = hsTargetOf(geo, j, open: _open[j.phase]);
    // He faces the pole: mirrored when the target is on his left.
    final flip = target.dx < _standX;
    final tip0 = LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final hand = tb.topLeft + (flip ? Offset(tb.width - tip0.dx, tip0.dy) : tip0);
    final hooked = _run.phase.index >= HsPhase.operate.index;
    // The rod: from below his hands up to the target (hooked) or just short of it.
    final towards = target - hand;
    final tip = hooked ? target : hand + towards * (up ? 0.86 : 0.0);
    final butt = hand - towards / towards.distance * 26;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('yard'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: HsWorldPainter(geo: geo, gear: j.isDo ? HsGear.doFuse : HsGear.abSwitch, open: _open, abOff: _abOff),
                  ),
                ),
              ),
              AnimatedPositioned(
                key: const ValueKey('trainee'),
                duration: Duration(milliseconds: quiet ? 0 : 600),
                curve: Curves.easeInOut,
                left: tb.left,
                top: tb.top,
                width: tb.width,
                height: tb.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Transform.flip(
                        flipX: flip,
                        child: LinemanFigure(
                          look: LinemanLook(
                            helmet: LinemanLook.trainee.helmet,
                            shirt: LinemanLook.trainee.shirt,
                            vest: LinemanLook.trainee.vest,
                            pants: LinemanLook.trainee.pants,
                            skin: LinemanLook.trainee.skin,
                            gloves: gloved,
                          ),
                          mode: _mode,
                          wake: _wake,
                          quiet: quiet,
                        ),
                      ),
                    ),
                    if (_run.kit.contains(HsKit.shield))
                      Positioned(
                        key: const ValueKey('shield'),
                        left: flip ? tb.width * 0.28 : tb.width * 0.36,
                        top: tb.height * 0.07,
                        width: tb.width * 0.36,
                        height: tb.height * 0.16,
                        child: const IgnorePointer(child: CustomPaint(painter: HsShieldPainter())),
                      ),
                  ],
                ),
              ),
              if (up)
                Positioned.fill(
                  key: const ValueKey('rod'),
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: HsRodPainter(butt: butt, tip: tip, head: _run.head, locked: _run.kit.contains(HsKit.lock)),
                    ),
                  ),
                ),
              if (_flashAt != null && !_freeze)
                Positioned.fill(
                  key: ValueKey('flash-$_flashN'),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      builder: (_, v, _) => v >= 1
                          ? const SizedBox.shrink()
                          : CustomPaint(
                              painter: HsArcPainter(at: _flashAt!, v: v),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // Tap the ground, the ring; draw the stroke.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: HsLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => unawaited(_tapScene(d.localPosition)),
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: (d) => unawaited(_panEnd(d)),
          ),
        ),
      ),
      // The arc, in colour over the grey yard.
      if (_freeze && _deathAt != null)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(
                painter: HsArcPainter(at: _deathAt!, v: 0.25 + 0.6 * v, big: true),
              ),
            ),
          ),
        ),
      // The next job: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('job-${_run.index}'),
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

  Widget _prepTools() {
    final k = _run.kit;
    Widget b(String label, IconData icon, bool on, VoidCallback tap, {Key? key}) =>
        _ToolButton(key: key, icon: icon, label: label, on: on, enabled: _canPlay, onTap: tap);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 6,
      children: [
        b(HsLines.gloves, Icons.back_hand_rounded, k.contains(HsKit.gloves), () => _wear(HsKit.gloves)),
        b(HsLines.shield, Icons.masks_rounded, k.contains(HsKit.shield), () => _wear(HsKit.shield)),
        b(HsLines.lock, Icons.lock_rounded, k.contains(HsKit.lock), () => _wear(HsKit.lock)),
        b(HsLines.puller, Icons.hardware_rounded, _run.head == HsHead.puller, () => _fit(HsHead.puller)),
        b(HsLines.socket, Icons.settings_rounded, _run.head == HsHead.socket, () => _fit(HsHead.socket)),
        b(
          k.contains(HsKit.offload) ? HsLines.offloadDone : HsLines.offload,
          Icons.phone_in_talk_rounded,
          k.contains(HsKit.offload),
          () => _wear(HsKit.offload),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null;
    final phase = _run.phase;
    final j = _job;
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
              labels: HsLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(text: HsLines.jobBn(j))),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && phase == HsPhase.prep)
                Positioned(
                  key: const ValueKey('hud-prep'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _prepTools(),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: DoBigButton(label: HsLines.raise, filled: true, onTapUp: (d) => unawaited(_raise(d.globalPosition))),
                      ),
                    ],
                  ),
                ),
              if (handsOn && phase == HsPhase.operate && j.isDo)
                Positioned(
                  key: const ValueKey('hud-face'),
                  left: 12,
                  bottom: pad.bottom + 16,
                  child: _ToolButton(
                    icon: Icons.face_retouching_off_rounded,
                    label: _run.faceAside ? HsLines.faceAsideOn : HsLines.faceAside,
                    on: _run.faceAside,
                    enabled: _canPlay,
                    onTap: _turnFace,
                  ),
                ),
              if (playing && phase == HsPhase.grip && _card == null && !reasonOpen && !coworkerOnScreen)
                _GripCard(
                  key: const ValueKey('grip'),
                  hands: _hands,
                  locked: _run.kit.contains(HsKit.lock),
                  quiet: quiet,
                  onTap: (f) => unawaited(_placeHand(f)),
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
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (phase == HsPhase.prep && handsOn ? 252 : 72)), onLeft: coworkerFromRight),
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
                  line: HsLines.intro,
                  alarm: null,
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

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            HsLines.docket,
            style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A)),
          ),
          Text(
            text,
            style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416)),
          ),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit once used.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 104,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The grip: the rod's lower part close up (butt at the bottom, the red hand
/// guard); tap to put a hand on it, two hands.
class _GripCard extends StatelessWidget {
  const _GripCard({super.key, required this.hands, required this.locked, required this.quiet, required this.onTap});
  final List<double> hands;
  final bool locked;
  final bool quiet;
  final ValueChanged<double> onTap;

  static const rodH = 300.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.paddingOf(context).top + 150,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: quiet ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(
            scale: 0.85 + 0.15 * v,
            child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
          ),
          child: Container(
            width: 150,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xE60B1324),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.6),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: Semantics(
              label: HsLines.gripLabel,
              child: GestureDetector(
                key: const ValueKey('grip-rod'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => onTap(1 - (d.localPosition.dy - 6) / (rodH - 12)),
                child: SizedBox(
                  width: 150,
                  height: rodH,
                  child: CustomPaint(
                    painter: HsGripPainter(hands: List.of(hands), locked: locked),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
