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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_hotstick_operate_world.dart' show HsArcPainter, HsShieldPainter;
import 'm4_do_open_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode, Carry;
import 'spoken_once.dart';

export 'm4_do_open_world.dart' show M4DoOpenGeo, M4DoOpenHead, M4DoOpenRod;

// Lesson 4.4 "ডিও (DO) ফিউজ পরিচালনা করা", কাজ 1 "ডিও খোলো নিয়মে" (pack
// do_4_4_a). The DO set of a DTR on an H-pole; two jobs a play, dealt in a
// fresh order:
//   • a fault blew one fuse — open the other two as well (pro tip 2: "বাকি
//     দুটি ফেজের ফিউজও খুলে, ফল্ট সারিয়ে");
//   • the DTR on heavy load — open all three with the load-break tool on the
//     hot stick (pro tip 1).
// Hands on:
//   0. (once) choose the operating rod at the van: whole, rated, the right
//      length — not the cracked one, not the short one (point 1, সরঞ্জাম);
//   1. get ready: insulated গ্লাভস and the face shield (point 1, PPE), the
//      head on the rod (puller / load-break tool), then the rod goes up;
//   2. where to stand (spot): dry, level ground (point 1, পরিবেশ), the fuses to
//      the side or diagonal, never overhead (point 3, অবস্থান);
//   3. each fuse still in: hook the ring, turn the face aside, one quick firm
//      pull (point 3, ফিউজ খোলা);
//   4. confirm: all three open (pro tip 2) before saying the job is done.
// Deadly: pulling a heavily loaded fuse without the load-break tool — the arc
// is not quenched (pro tip 1; the film: an arc flash blinds or kills).
// Slips: a cracked / short rod, no গ্লাভস, no shield, wet ground, under the
// fuses, the face not aside, "done" with a fuse still in, listening to him.
// Not scored (the guide says the rule, the step stays): no head on the rod,
// standing too far, a miss on the ring, an already-open fuse, a short or slow pull.
// The careless coworker once a play, before the first pull (the pull and
// "সব ফিউজ খোলা" wait for him — holdForCoworker): on the heavy job "লোড
// থাকলেও টেনে দাও", on the fault job "বাকি দুটো খোলার দরকার নেই". Listening
// is a slip (playbook row 8); the guide puts it right and nothing on the rod
// changes, refusing changes nothing either — the head is the player's own pick.

// ============================================================================
// Content
// ============================================================================

/// The job on the docket.
enum M4DoOpenKind { fault, heavy }

/// The steps of a job.
enum M4DoOpenStage { rod, prep, stand, open, done }

/// The get-ready items (they stay on for the next job).
enum M4DoOpenKit { gloves, shield }

/// Where a tap on the ground leaves the trainee.
enum M4DoOpenSpot { under, wet, side, far }

/// What a pull came to.
enum M4DoOpenPull { short, slow, done }

@immutable
class M4DoOpenJob {
  const M4DoOpenJob({required this.kind, required this.blown, required this.puddleLeft});
  final M4DoOpenKind kind;

  /// The phase a fault blew (fault job); -1 on the heavy job.
  final int blown;

  /// The puddle is on the left of the structure (else on the right).
  final bool puddleLeft;
}

@immutable
class M4DoOpenDeal {
  const M4DoOpenDeal({required this.jobs, required this.rods, required this.callAt});
  final List<M4DoOpenJob> jobs;

  /// The rods in the van's rack, left to right.
  final List<M4DoOpenRod> rods;

  /// The job the careless coworker comes on.
  final int callAt;
}

/// Two jobs (a fault, a heavy load) in a fresh order; the blown phase, the
/// puddle's side, the rods' order and his job dealt too.
M4DoOpenDeal m4DoOpenDeal(math.Random rng) {
  final kinds = [M4DoOpenKind.fault, M4DoOpenKind.heavy]..shuffle(rng);
  return M4DoOpenDeal(
    jobs: [
      for (final k in kinds) M4DoOpenJob(kind: k, blown: k == M4DoOpenKind.fault ? rng.nextInt(3) : -1, puddleLeft: rng.nextBool()),
    ],
    rods: [...M4DoOpenRod.values]..shuffle(rng),
    callAt: rng.nextInt(2),
  );
}

/// Where a tap at design x lands, for a job whose puddle is on [puddleLeft].
M4DoOpenSpot m4DoOpenSpotOf(double x, {required bool puddleLeft}) {
  if ((x - M4DoOpenGeo.midX).abs() < M4DoOpenGeo.underHalf) return M4DoOpenSpot.under;
  final (wl, wr) = puddleLeft ? M4DoOpenGeo.wetLeft : M4DoOpenGeo.wetRight;
  if (x >= wl && x <= wr) return M4DoOpenSpot.wet;
  if (x < M4DoOpenGeo.farX) return M4DoOpenSpot.far;
  return M4DoOpenSpot.side;
}

/// A dry spot to the side (where the guide moves him after a slip).
double m4DoOpenDryX({required bool puddleLeft}) => puddleLeft ? 84 : 120;

abstract final class M4DoOpenLines {
  static const title = 'ডিও খোলো নিয়মে';
  static const intro = 'ট্রান্সফরমারের ডিও খুলতে হবে। আগে ঠিক রডটা বাছুন।';
  static const rounds = ['ক', 'খ'];

  // The task of each step (what the guide says and repeats when tapped).
  static const askRod = 'কোন রডটা নেবেন? একটা বাছুন।';
  static const askPrep = 'রড তোলার আগে নিজে তৈরি হোন, রডের মাথা লাগান।';
  static const askStand = 'কোথায় দাঁড়াবেন? মাটিতে জায়গাটা দেখান।';
  static const askHook = 'যে ফিউজ খুলবেন, তার রিং-এ রড আটকান।';
  static const askPull = 'এবার ফিউজটা খুলুন — এক টানে।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static String ask(M4DoOpenStage s, {required bool hooked}) => switch (s) {
    M4DoOpenStage.rod => askRod,
    M4DoOpenStage.prep => askPrep,
    M4DoOpenStage.stand => askStand,
    M4DoOpenStage.open || M4DoOpenStage.done => hooked ? askPull : askHook,
  };
  static const tasks = [askRod, askPrep, askStand, askHook, askPull];

  // Labels a worker reads (buttons, the docket).
  static const sceneLabel = 'ডিও সেট আর মাটি';
  static const rackLabel = 'গাড়ির র‍্যাকে অপারেটিং রড';
  static const gloves = 'ইনসুলেটেড গ্লাভস';
  static const shield = 'ফেস শিল্ড';
  static const puller = 'ফিউজ পুলার';
  static const loadBreak = 'লোড ব্রেক টুল';
  static const raise = 'রড তুলুন';
  static const faceAside = 'মুখ ফেরান';
  static const faceAsideOn = 'মুখ ফেরানো';
  static const allOpen = 'সব ফিউজ খোলা';
  static const docket = 'ডকেট';
  static String jobBn(M4DoOpenJob j) => switch (j.kind) {
    M4DoOpenKind.fault => 'DTR · ফল্টে ফিউজ উড়েছে · ডিও খুলুন',
    M4DoOpenKind.heavy => 'DTR · লোড ভারী · ডিও খুলুন',
  };

  // Not scored: the guide says the rule, the step stays.
  static const noHead = 'রডের মাথায় আগে অ্যাটাচমেন্ট লাগান।';
  static const tooFar = 'এত দূর থেকে রড ঠিকমতো আটকানো যায় না। পাশে থাকুন, তবে কাছে।';
  static const missHook = 'পুলারটা ফিউজের রিং-এ ভালোভাবে আটকান।';
  static const already = 'ওটা আগেই খোলা।';
  static const shortPull = 'আধা টান হলো। একটি দ্রুত, দৃঢ় টানে — পুরোটা।';
  static const slowPull = 'এত ধীরে নয় — ধীরে খুললে আর্ক দীর্ঘস্থায়ী হতে পারে। দ্বিধা না করে এক টানে।';
  static const restOpen = 'আরও ফিউজ লাগানো আছে — সেগুলোও খুলুন।';
  static const handRod = 'এই নিন — অক্ষত, ঠিক দৈর্ঘ্যের রড।';

  // The reasons (lesson 4.4): the right ones fit what was asked; the wrong
  // ones are the lesson's myths and field excuses — never a true rule.
  static const whyRod = 'কেন এই রডটাই নিলেন?';
  static const whyFault = 'কেন তিনটি ফিউজই খুললেন?';
  static const whyHeavy = 'কেন লোড ব্রেক টুল লাগালেন?';
  static String why(M4DoOpenKind k) => k == M4DoOpenKind.fault ? whyFault : whyHeavy;

  static const rodWhy = ['অক্ষত, রেটেড আর ঠিক দৈর্ঘ্যের রড চাই', 'রডের দৈর্ঘ্যই আমাকে নিরাপদ দূরত্ব দেয়'];
  static const faultWhy = ['ফল্টে একটা উড়লে বাকি দুটোও খুলতে হয়', 'তিন ফেজ খুলে ফল্ট সারানোই সেরা অভ্যাস'];
  static const heavyWhy = ['ভারী লোডে এই টুলই আর্ককে নিরাপদে নেভায়', 'বেশি লোডের ফিউজ খুলতে এই টুলই নিয়ম'];
  static List<String> whyRight(M4DoOpenKind k) => k == M4DoOpenKind.fault ? faultWhy : heavyWhy;

  // Wrong reasons (the lesson's myths and field excuses), one pool per deck.
  // Every wrong line carries the deck's key word (রড / লোড + টুল / ফল্ট), so
  // no word from the question shows up on the right card alone.
  static const rodWrong = [
    'গ্লাভস থাকলে রড ছাড়াও ফিউজ খোলা যায়',
    'হাতের কাছে যে রড পাই, সেটাই যথেষ্ট',
    'ফাটা রডে টেপ মেরে দিলেই আবার চলে',
    'ছোট রডে কাজটা দ্রুত আর সহজে হয়',
    'রডের দৈর্ঘ্য নয়, গ্লাভসই আসল রক্ষা',
    'রেটিং লেখা না থাকলেও রড ঠিক থাকে',
  ];
  static const heavyWrong = [
    'লোড কম মনে হলে টুল ছাড়াই খোলা চলে',
    'তাড়া থাকলে লোড ব্রেক টুল বাদ চলে',
    'লোড ব্রেক টুল থাকলে গ্লাভস লাগে না',
    'লোড ব্রেক টুল শুধু সাহেব দেখলে লাগে',
    'পুরোনো লাইনে লোড কম, টুল লাগে না',
    'লোড ব্রেক টুল শুধু বর্ষার দিনে লাগে',
  ];
  static const faultWrong = [
    'ফল্টে একটা উড়লেও বাকিগুলো ঠিকই থাকে',
    'ফল্ট সারাতে একটা ফেজ খুললেই যথেষ্ট',
    'ফল্টের লাইনে আর্ক হয় না, ভয় নেই',
    'ফল্টের তাড়ায় নিয়ম একটু ছাড়া যায়',
    'ফল্টের লাইনে গ্লাভস না হলেও চলে',
    'একটা ফেজ খুললেই ফল্টের লাইন বন্ধ',
  ];
  static List<String> whyWrong(M4DoOpenKind k) => k == M4DoOpenKind.fault ? faultWrong : heavyWrong;

  static const coworkerExit = 'হুঁ! যা খুশি করুন।';

  /// The careless coworker on the heavy job, before the first pull.
  static const coworkerHeavy = CoworkerScript(
    line: 'লোড থাকলেও টেনে দাও! লোড ব্রেক টুল-টুল লাগবে না।',
    exitLine: coworkerExit,
    right: ['না, লোড ব্রেক টুল লাগিয়েই খুলব', 'ভারী লোডে টুল ছাড়া আমি টানব না', 'না, আর্ক নেভানোর টুলটা লাগবেই'],
    wrong: [
      'ঠিক, টুল খুলে এমনিই টেনে দিই',
      'আচ্ছা, পুলারেই কাজ হয়ে যাবে',
      'লোড থাকুক, এক টানে খুলে যাবে',
      'ঠিক আছে, টুল-টুল লাগে না',
      'তাড়াতাড়ি টেনেই কাজটা সারি',
    ],
    asks: ['ও বলছে টুল ছাড়াই টানতে। আপনি?', 'ভারী লোড — ওর কথায় টানবেন, না নিয়মে?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// The careless coworker on the fault job, before the first pull.
  static const coworkerFault = CoworkerScript(
    line: 'একটা তো উড়েই গেছে! ওটাই বদলে দাও, বাকি দুটো খোলার দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, বাকি দুটো ফিউজও খুলব', 'তিনটিই খুলে তবে ফল্ট সারাব', 'না, তিন ফেজই খোলা চাই'],
    wrong: [
      'ঠিক, উড়ে যাওয়াটাই বদলাই',
      'আচ্ছা, বাকি দুটো থাক তবে',
      'একটা খোলা থাকলেই চলবে',
      'ঠিক আছে, শুধু ওটাই সারাই',
      'বাকিগুলো খোলার সময় নেই',
    ],
    asks: ['ও বলছে বাকি দুটো না খুলতে। আপনি?', 'ওর কথায় চলবেন, না তিনটিই খুলবেন?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// New lines for him (silent, caption held for a reading time, until
  /// recorded in his voice with tool/rival_clip.py).
  static List<String> get recordLines => [coworkerHeavy.line, coworkerFault.line];

  static const callHeld = 'ঠিক! চাপে পড়ে নিয়ম ভাঙবেন না।';
  static const heldFault = 'ঠিক! চাপে পড়ে নিয়ম ভাঙবেন না — তিনটিই খুলুন।';
  static const allSet = 'ঠিক রড, পাশে দাঁড়িয়ে, এক টানে — ডিও খোলা শিখলেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — রড, প্রস্তুতি, দাঁড়ানো, তারপর এক টানে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtRod = 'অক্ষত, ঠিক দৈর্ঘ্যের রড';
  static const caughtKit = 'গ্লাভস আর ফেস শিল্ড — রড তোলার আগে';
  static const caughtStand = 'শুকনো মাটিতে, ফিউজের পাশে দাঁড়ানো';
  static const caughtPull = 'মুখ সরিয়ে এক টানে';
  static const caughtAll = 'ফল্টে তিনটি ফিউজই খোলা';
  static const caughtLbt = 'ভারী লোডে লোড ব্রেক টুল';
  static const caughtCall = 'চাপে “না” বলেছেন';

  /// Every fixed guide line (for recording).
  static List<String> get guideLines => [
    intro,
    ...tasks,
    ...tapWhy,
    noHead,
    tooFar,
    missHook,
    already,
    shortPull,
    slowPull,
    restOpen,
    handRod,
    whyRod,
    whyFault,
    whyHeavy,
    for (final s in [coworkerHeavy, coworkerFault]) ...s.asks,
    callHeld,
    heldFault,
    allSet,
    quick,
    fail,
    deadlyWord,
    nearMissWord,
  ];
}

abstract final class M4DoOpenMistakes {
  static const _dir = 'assets/game/art/m4_do_open';

  static const crackedRod = DoMistake(
    key: '4.4/m4_do_open/cracked-rod',
    textBn: 'ফাটা রড বাছলেন। অপারেটিং রড হতে হবে অক্ষত — ফাটল বা আঁশ বেরোনো রডে ইনসুলেশনের ভরসা নেই।',
    art: '$_dir/do_rod.svg',
    lessonPoint: 0,
  );
  static const shortRod = DoMistake(
    key: '4.4/m4_do_open/short-rod',
    textBn: 'ছোট রড বাছলেন। রডের দৈর্ঘ্যই আপনাকে নিরাপদ দূরত্ব দেয় — সঠিক দৈর্ঘ্যের, উপযুক্ত ভোল্টেজ রেটিং-এর রড চাই।',
    art: '$_dir/do_rod.svg',
    lessonPoint: 0,
  );
  static const noGloves = DoMistake(
    key: '4.4/m4_do_open/no-gloves',
    textBn: 'গ্লাভস ছাড়া রড তুললেন। এই কাজে সম্পূর্ণ PPE চাই — হেলমেট, ইনসুলেটেড গ্লাভস আর ফেস শিল্ড।',
    art: '$_dir/do_ppe.svg',
    lessonPoint: 0,
  );
  static const noShield = DoMistake(
    key: '4.4/m4_do_open/no-shield',
    textBn: 'ফেস শিল্ড ছাড়া রড তুললেন। ফিউজ খোলার সময় আর্ক বা স্পার্ক স্বাভাবিক — ফেস শিল্ড মুখ আর চোখকে ফ্ল্যাশ থেকে বাঁচায়।',
    art: '$_dir/do_ppe.svg',
    lessonPoint: 0,
  );
  static const wetGround = DoMistake(
    key: '4.4/m4_do_open/wet-ground',
    textBn: 'জল-কাদায় দাঁড়ালেন। দাঁড়ানোর জায়গা হতে হবে শুকনো আর সমতল — ভেজায় আর্কের বিপদও বাড়ে।',
    art: '$_dir/do_wet.svg',
    lessonPoint: 0,
  );
  static const underFuse = DoMistake(
    key: '4.4/m4_do_open/under-the-fuse',
    textBn: 'ফিউজের ঠিক নিচে দাঁড়ালেন। দাঁড়ান এমনভাবে যাতে ফিউজ আপনার পাশে বা কোণাকুণি থাকে — মাথার ওপরে বা সামনে নয়।',
    art: '$_dir/do_stand.svg',
    lessonPoint: 2,
  );
  static const faceIn = DoMistake(
    key: '4.4/m4_do_open/face-not-aside',
    textBn: 'মুখ না সরিয়েই টানলেন। মুখ একপাশে সরিয়ে, একটি দ্রুত, দৃঢ় আর নিয়ন্ত্রিত টানে ফিউজ খুলুন।',
    art: '$_dir/do_face.svg',
    lessonPoint: 2,
  );

  /// Pro tip 2 (not a lesson point: "পাঠে দেখুন" opens the lesson from its start).
  static const notAllThree = DoMistake(
    key: '4.4/m4_do_open/not-all-three',
    textBn: 'একটা ফিউজ লাগানো রেখেই কাজ শেষ বললেন। ফল্টে একটা উড়ে গেলে বাকি দুটো ফেজের ফিউজও খুলে, তবে ফল্ট সারান।',
    art: '$_dir/do_three.svg',
  );

  /// Listened to him on the fault job (pro tip 2; a slip, playbook row 8).
  static const listenedTwo = DoMistake(
    key: '4.4/m4_do_open/listened-skip-two',
    textBn: 'চাপে পড়ে বাকি দুটো না খুলতে রাজি হলেন। ফল্টে একটা ফিউজ উড়ে গেলে বাকি দুটি ফেজের ফিউজও খুলে, তবে ফল্ট সারান।',
    art: '$_dir/do_three.svg',
  );

  /// Listened to him on the heavy job (pro tip 1; a slip, playbook row 8 —
  /// the pull itself without the tool stays the deadly one).
  static const listenedNoTool = DoMistake(
    key: '4.4/m4_do_open/listened-no-tool',
    textBn: 'চাপে পড়ে টুল ছাড়াই টানতে রাজি হলেন। খুব বেশি লোডের ফিউজ খুলতে হট স্টিকের মাথায় লোড ব্রেক টুল লাগান — এটি আর্ককে নিরাপদে নিভিয়ে দেয়।',
    art: '$_dir/do_lbt.svg',
  );

  /// Pro tip 1 (and the film: an arc flash blinds or kills).
  static const heavyNoTool = DoMistake(
    key: '4.4/m4_do_open/heavy-load-no-tool',
    textBn: 'ভারী লোডের ফিউজ লোড ব্রেক টুল ছাড়া টানলেন। আর্ক নিভল না — আর্ক ফ্ল্যাশে অন্ধত্ব বা প্রাণহানি হয়। ভারী লোডে হট স্টিকে লোড ব্রেক টুল লাগিয়ে খুলুন।',
    art: '$_dir/do_lbt.svg',
    deadly: true,
  );

  static List<DoMistake> get all => const [crackedRod, shortRod, noGloves, noShield, wetGround, underFuse, faceIn, notAllThree, listenedTwo, listenedNoTool, heavyNoTool];
}

/// The DO pull: one drag down of ≥ 70 design px within 1.2 s (quick and firm).
const m4DoOpenPullPx = 70.0;
const m4DoOpenPullMaxMs = 1200;

/// The play state (pure logic).
class M4DoOpenRun {
  M4DoOpenRun(this.deal) {
    _resetFuses();
  }
  final M4DoOpenDeal deal;
  int index = 0;
  M4DoOpenStage stage = M4DoOpenStage.rod;
  final Set<M4DoOpenKit> kit = {};
  M4DoOpenHead head = M4DoOpenHead.none;

  /// Which fuses hang open (by phase).
  List<bool> open = [false, false, false];

  /// The fuse the rod is hooked on.
  int? hooked;
  var faceAside = false;

  /// The all-three slip is booked for this job (once).
  var allBooked = false;
  int slips = 0;
  int jobSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.jobs.length;
  bool get ended => done || deadly != null;
  M4DoOpenJob get job => deal.jobs[index.clamp(0, deal.jobs.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get clean => jobSlips == 0;
  bool get allOpen => open.every((o) => o);

  /// Fuses pulled open this job (the blown one is not counted).
  int pulled = 0;

  void _resetFuses() {
    open = [for (var i = 0; i < 3; i++) i == job.blown];
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    jobSlips++;
    return m;
  }

  /// Rod [i] from the rack. A wrong one is a slip; the guide hands the right one.
  DoMistake? pickRod(int i) {
    if (ended || stage != M4DoOpenStage.rod) return null;
    stage = M4DoOpenStage.prep;
    switch (deal.rods[i]) {
      case M4DoOpenRod.good:
        _tag(M4DoOpenLines.caughtRod);
        return null;
      case M4DoOpenRod.cracked:
        return _slip(M4DoOpenMistakes.crackedRod);
      case M4DoOpenRod.short:
        return _slip(M4DoOpenMistakes.shortRod);
    }
  }

  void wear(M4DoOpenKit k) {
    if (!ended && stage == M4DoOpenStage.prep) kit.add(k);
  }

  /// Fit a head on the rod (the last one fitted counts).
  void fit(M4DoOpenHead h) {
    if (ended || stage != M4DoOpenStage.prep) return;
    head = h;
  }

  /// The rod goes up. No head: not scored (false). Else the most serious
  /// thing missing is the slip (one per raise); the guide puts the rest right.
  (bool, DoMistake?) raise() {
    if (ended || stage != M4DoOpenStage.prep) return (false, null);
    if (head == M4DoOpenHead.none) return (false, null);
    DoMistake? m;
    if (!kit.contains(M4DoOpenKit.gloves)) {
      m = _slip(M4DoOpenMistakes.noGloves);
    } else if (!kit.contains(M4DoOpenKit.shield)) {
      m = _slip(M4DoOpenMistakes.noShield);
    }
    if (m == null) _tag(M4DoOpenLines.caughtKit);
    kit.addAll(M4DoOpenKit.values);
    stage = M4DoOpenStage.stand;
    return (true, m);
  }

  /// Where he stands (design [x]). Too far = not scored, stay.
  (M4DoOpenSpot, DoMistake?) stand(double x) {
    if (ended || stage != M4DoOpenStage.stand) return (M4DoOpenSpot.far, null);
    final s = m4DoOpenSpotOf(x, puddleLeft: job.puddleLeft);
    if (s == M4DoOpenSpot.far) return (s, null);
    stage = M4DoOpenStage.open;
    if (s == M4DoOpenSpot.under) return (s, _slip(M4DoOpenMistakes.underFuse));
    if (s == M4DoOpenSpot.wet) return (s, _slip(M4DoOpenMistakes.wetGround));
    _tag(M4DoOpenLines.caughtStand);
    return (s, null);
  }

  /// Hook the rod on fuse [phase]: false if it is already open (not scored).
  bool hook(int phase) {
    if (ended || stage != M4DoOpenStage.open) return false;
    if (open[phase]) return false;
    hooked = phase;
    faceAside = false;
    return true;
  }

  void turnFace() {
    if (!ended && stage == M4DoOpenStage.open && hooked != null) faceAside = true;
  }

  /// The pull: [px] down along the drag, over [ms]. Heavy load without the
  /// load-break tool comes first (deadly), then the face.
  (M4DoOpenPull, DoMistake?) pull(double px, int ms) {
    final p = hooked;
    if (ended || stage != M4DoOpenStage.open || p == null) return (M4DoOpenPull.short, null);
    if (px < m4DoOpenPullPx) return (M4DoOpenPull.short, null);
    if (ms > m4DoOpenPullMaxMs) return (M4DoOpenPull.slow, null);
    hooked = null;
    if (job.kind == M4DoOpenKind.heavy && head != M4DoOpenHead.loadBreak) {
      return (M4DoOpenPull.done, deadly = M4DoOpenMistakes.heavyNoTool);
    }
    open = [for (var i = 0; i < 3; i++) i == p || open[i]];
    pulled++;
    final face = faceAside;
    faceAside = false;
    if (!face) return (M4DoOpenPull.done, _slip(M4DoOpenMistakes.faceIn));
    _tag(M4DoOpenLines.caughtPull);
    return (M4DoOpenPull.done, null);
  }

  /// He listened on the fault job: a slip (it also stands for the all-three
  /// slip of this job, so "সব ফিউজ খোলা" too early is not booked again).
  DoMistake? listenAll() {
    if (ended || allBooked) return null;
    allBooked = true;
    return _slip(M4DoOpenMistakes.listenedTwo);
  }

  /// He listened on the heavy job: a slip. Nothing on the rod changes (the
  /// guide puts it right); a pull without the tool is still the deadly one.
  DoMistake? listenHeavy() {
    if (ended) return null;
    return _slip(M4DoOpenMistakes.listenedNoTool);
  }

  /// "সব ফিউজ খোলা": the job is done if all three are; else the all-three
  /// slip (once a job; after that the guide just says so).
  (bool, DoMistake?) confirm() {
    if (ended || stage != M4DoOpenStage.open) return (false, null);
    if (!allOpen) {
      if (allBooked) return (false, null);
      allBooked = true;
      return (false, _slip(M4DoOpenMistakes.notAllThree));
    }
    stage = M4DoOpenStage.done;
    _tag(job.kind == M4DoOpenKind.fault ? M4DoOpenLines.caughtAll : M4DoOpenLines.caughtLbt);
    return (true, null);
  }

  void next() {
    index++;
    stage = M4DoOpenStage.prep;
    head = M4DoOpenHead.none;
    hooked = null;
    faceAside = false;
    allBooked = false;
    pulled = 0;
    jobSlips = 0;
    if (!done) _resetFuses();
  }
}

/// The quick bonus (~85 % of a thorough play, rounded to 10 s). The rod 2000
/// + reason 8200; a job: get ready (3 taps + raise; 1 + raise the second time)
/// ≈ 5000, stand 2000, a fuse (hook 2000 + face 1000 + pull 2000 + 1500) ×
/// 2 or 3, confirm 1500, reason 8200 → fault ≈ 29700, heavy ≈ 36200; + the
/// coworker ≈ 9000 → ≈ 85100; 85 % ≈ 72300 → 70 s.
const m4DoOpenQuickMs = 70000;

@immutable
class M4DoOpenPack {
  const M4DoOpenPack({required this.id, required this.titleBn, this.quickMs = m4DoOpenQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4DoOpenPack> m4DoOpenPacks = {'do_4_4_a': M4DoOpenPack(id: 'do_4_4_a', titleBn: M4DoOpenLines.title)};

/// The trainee's box standing with his centre at [x].
Rect m4DoOpenTraineeBox(M4DoOpenGeo geo, double x) {
  final h = geo.man;
  return Rect.fromLTWH(x - h / 4, geo.groundY - h + 4, h / 2, h);
}

/// Where he starts (by the van, left).
const m4DoOpenStartX = 40.0;

/// The ring nearest to [p] within 22 design px: (phase, open?) or null.
(int, bool)? m4DoOpenRingAt(M4DoOpenGeo geo, List<bool> open, Offset p) {
  (int, bool)? best;
  var bestD = 22.0;
  for (var i = 0; i < 3; i++) {
    final r = open[i] ? geo.ringOpenOf(i) : geo.ringOf(i);
    final d = (p - r).distance;
    if (d <= bestD) {
      bestD = d;
      best = (i, open[i]);
    }
  }
  return best;
}

// ============================================================================
// Page
// ============================================================================

class M4DoOpenPage extends StatefulWidget {
  const M4DoOpenPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4DoOpenPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4DoOpenPage> createState() => _M4DoOpenPageState();
}

class _M4DoOpenPageState extends State<M4DoOpenPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DoOpenRunPage(
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

class _DoOpenRunPage extends ConsumerStatefulWidget {
  const _DoOpenRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4DoOpenPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DoOpenRunPage> createState() => _DoOpenRunPageState();
}

class _DoOpenRunPageState extends ConsumerState<_DoOpenRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4DoOpenRun _run = M4DoOpenRun(m4DoOpenDeal(widget.rng));
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

  /// The rod he took from the rack (highlighted while the reason is asked).
  int? _rodPicked;

  /// Where the trainee stands (design x).
  double _standX = m4DoOpenStartX;

  /// The flash at the contact when a fuse opens (a one-shot).
  int _flashN = 0;
  Offset? _flashAt;

  // The pull being drawn.
  Duration? _panT0;
  Duration _panT1 = Duration.zero;
  Offset _panSum = Offset.zero;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset? _deathAt;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how to touch, never what): the rack, the get-ready row,
  // the ground, the rings, the face / confirm buttons, the pull.
  final _hints = IdleHintController();
  final _rackKey = GlobalKey();
  final _raiseKey = GlobalKey();
  final _faceKey = GlobalKey();
  final _confirmKey = GlobalKey();
  // Hint anchors over the three rings (scene widgets, so the hand can sweep
  // rings and HUD buttons in one pass).
  final _ringKeys = List.generate(3, (_) => GlobalKey());
  final Map<_PrepTool, GlobalKey> _toolKeys = {for (final t in _PrepTool.values) t: GlobalKey()};

  /// The get-ready row in a fresh order each play (dealt after the jobs, so
  /// the deal stays the first draw from the play's random).
  late final List<_PrepTool> _toolOrder = _dealTools(_run);

  /// Takes the run so the deal is built (drawn) before the shuffle.
  List<_PrepTool> _dealTools(M4DoOpenRun dealtFirst) => [..._PrepTool.values]..shuffle(widget.rng);

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M4DoOpenJob get _job => _run.job;
  M4DoOpenGeo _geoNow = M4DoOpenGeo.forScene(780, 0);

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

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen;

  String get _ask => M4DoOpenLines.ask(_run.stage, hooked: _run.hooked != null);

  void _start() {
    _clock.start();
    unawaited(_sayChain([M4DoOpenLines.askRod]));
  }

  void _startJob() {
    setState(() {
      _standX = m4DoOpenStartX;
      _flashAt = null;
      _wake++;
    });
    unawaited(_sayChain([M4DoOpenLines.askPrep]));
  }

  // --- 0. the rod ----------------------------------------------------------------
  Future<void> _pickRod(int i, Offset origin) async {
    if (!_canPlay || _run.stage != M4DoOpenStage.rod) return;
    _hush();
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    final m = _run.pickRod(i);
    setState(() {
      _rodPicked = m == null ? i : _run.deal.rods.indexOf(M4DoOpenRod.good);
      _wake++;
    });
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _rodDone();
  }

  void _rodDone() {
    putOnTable(10);
    unawaited(
      askReason(
        deal: () => dealChoices(M4DoOpenLines.rodWhy, M4DoOpenLines.rodWrong, widget.rng),
        question: M4DoOpenLines.whyRod,
        stillValid: () => _run.index == 0 && !_ended,
      ),
    );
  }

  // --- 1. get ready --------------------------------------------------------------
  void _wear(M4DoOpenKit k) {
    if (!_canPlay || _run.stage != M4DoOpenStage.prep) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.45);
    setState(() {
      _run.wear(k);
      _wake++;
    });
  }

  void _fit(M4DoOpenHead h) {
    if (!_canPlay || _run.stage != M4DoOpenStage.prep) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    setState(() {
      _run.fit(h);
      _wake++;
    });
  }

  Future<void> _raise(Offset origin) async {
    if (!_canPlay || _run.stage != M4DoOpenStage.prep) return;
    final (up, m) = _run.raise();
    if (!up) {
      HapticFeedback.selectionClick();
      unawaited(_sayChain([M4DoOpenLines.noHead]));
      return;
    }
    _hush();
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
    if (_run.stage == M4DoOpenStage.open && _run.index == _run.deal.callAt && _run.pulled == 0) scheduleCoworker();
    unawaited(_sayChain([_ask]));
  }

  // --- 2. where to stand / 3. hook -------------------------------------------------
  Future<void> _tapScene(Offset p) async {
    if (!_canPlay) return;
    final geo = _geoNow;
    switch (_run.stage) {
      case M4DoOpenStage.stand:
        if (p.dy < geo.groundY - 30) {
          _hints.missTap();
          return;
        }
        final x = p.dx.clamp(16.0, 344.0);
        final (s, m) = _run.stand(x);
        HapticFeedback.selectionClick();
        _cue('sounds/intro/tick.ogg', volume: 0.45);
        if (s == M4DoOpenSpot.far) {
          unawaited(_sayChain([M4DoOpenLines.tooFar]));
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
      case M4DoOpenStage.open:
        final hit = m4DoOpenRingAt(geo, _run.open, p);
        HapticFeedback.selectionClick();
        if (hit == null) {
          _hints.missTap();
          unawaited(_sayChain([M4DoOpenLines.missHook]));
          return;
        }
        if (hit.$2) {
          unawaited(_sayChain([M4DoOpenLines.already]));
          return;
        }
        _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
        setState(() {
          _run.hook(hit.$1);
          _wake++;
        });
        _askStep();
      case M4DoOpenStage.rod || M4DoOpenStage.prep || M4DoOpenStage.done:
        _hints.missTap();
    }
  }

  Offset _toGlobal(Offset design) {
    final size = MediaQuery.sizeOf(context);
    return design * (size.width / 360);
  }

  // --- 3. the pull ------------------------------------------------------------------
  void _turnFace() {
    if (!_canPlay || _run.hooked == null) return;
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
    if (t0 == null || !_canPlay || _run.stage != M4DoOpenStage.open || _run.hooked == null) return;
    // A fast pull must not skip him: the first pull of his job waits for him.
    if (holdForCoworker()) return;
    await _pull(_panSum.dy, (_panT1 - t0).inMilliseconds);
  }

  Future<void> _pull(double px, int ms) async {
    final phase = _run.hooked!;
    final geo = _geoNow;
    final (s, m) = _run.pull(px, ms);
    switch (s) {
      case M4DoOpenPull.short:
        unawaited(_sayChain([M4DoOpenLines.shortPull]));
        return;
      case M4DoOpenPull.slow:
        unawaited(_sayChain([M4DoOpenLines.slowPull]));
        return;
      case M4DoOpenPull.done:
        break;
    }
    if (m != null && m.deadly) {
      await _deadly(m, at: geo.ringOf(phase));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() {
      _flashAt = geo.ringOf(phase) + const Offset(4, 0);
      _flashN++;
      _wake++;
    });
    if (m != null) {
      unawaited(_levelDelta(-10, _toGlobal(geo.ringOf(phase)), mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _askStep();
  }

  // --- 4. confirm ---------------------------------------------------------------------
  Future<void> _confirm(Offset origin) async {
    if (!_canPlay || _run.stage != M4DoOpenStage.open) return;
    if (holdForCoworker()) return;
    final (ok, m) = _run.confirm();
    HapticFeedback.selectionClick();
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    if (!ok) {
      unawaited(_sayChain([M4DoOpenLines.restOpen]));
      return;
    }
    _hush();
    _cue('sounds/intro/confirm.ogg', volume: 0.6);
    setState(() => _wake++);
    _jobDone();
  }

  /// The job is done: its ◆ on the table, then "কেন …?".
  void _jobDone() {
    final k = _job.kind;
    final idx = _run.index;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(
      askReason(
        deal: () => dealChoices(M4DoOpenLines.whyRight(k), M4DoOpenLines.whyWrong(k), widget.rng),
        question: M4DoOpenLines.why(k),
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
    final rod = _run.stage == M4DoOpenStage.prep && _run.index == 0 && _run.head == M4DoOpenHead.none && _rodPicked != null;
    unawaited(
      Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (!mounted || _ended || _run.index != idx) return;
        if (rod && _run.stage == M4DoOpenStage.prep) {
          setState(() => _rodPicked = null);
          _startJob();
          return;
        }
        _next();
      }),
    );
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript =>
      _run.deal.jobs[_run.deal.callAt].kind == M4DoOpenKind.heavy ? M4DoOpenLines.coworkerHeavy : M4DoOpenLines.coworkerFault;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("pull it anyway" / "leave the other two") fits only before the
    // first pull of his job.
    if (_ended || _run.ended || _run.index != _run.deal.callAt) return null;
    if (_run.stage.index > M4DoOpenStage.open.index || _run.pulled > 0) return null;
    // On the heavy job his "skip the tool" push fits only while the load-break
    // head is on. With the plain puller the head is locked (fit() ends at
    // prep), so neither answer could fit: he does not come, and the pull goes
    // ahead as the player made it ready.
    if (_job.kind == M4DoOpenKind.heavy && _run.stage.index >= M4DoOpenStage.stand.index && _run.head != M4DoOpenHead.loadBreak) {
      return null;
    }
    if (_run.stage != M4DoOpenStage.open) return false;
    if (_intro || _busy || _card != null || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final heavy = _job.kind == M4DoOpenKind.heavy;
    if (!held) {
      // Listening is a slip; the guide puts it right and the job goes on with
      // the rod as the player made it ready.
      final m = heavy ? _run.listenHeavy() : _run.listenAll();
      if (m != null) {
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        await _slip(m);
      } else {
        unawaited(_sayChain([_ask]));
      }
      return;
    }
    _run.caught.add(M4DoOpenLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    // Refusing changes nothing on the rod: the head is the player's own pick.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    unawaited(_sayChain([heavy ? M4DoOpenLines.callHeld : M4DoOpenLines.heldFault, _ask]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
        ? M4DoOpenLines.tapWhy[_nudgeN++ % M4DoOpenLines.tapWhy.length]
        : _nudge.next(_ask);
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
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m4doopen/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The yard freezes grey; the arc flashes at [at] in colour; then
  /// near-miss or death.
  Future<void> _deadly(DoMistake m, {required Offset at}) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/accident.ogg', volume: 0.9);
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
    final speak = await SpokenOnce.first('m4doopen/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4DoOpenLines.deadlyWord : M4DoOpenLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final m = _card;
        setState(() => _card = null);
        // The guide put it right; the job goes on.
        if (m == M4DoOpenMistakes.crackedRod || m == M4DoOpenMistakes.shortRod) {
          unawaited(_sayChain([M4DoOpenLines.handRod]));
          _rodDone();
          return;
        }
        if (m == M4DoOpenMistakes.underFuse || m == M4DoOpenMistakes.wetGround) {
          // Stepped to dry ground, to the side.
          setState(() {
            _standX = m4DoOpenDryX(puddleLeft: _job.puddleLeft);
            _wake++;
          });
        }
        if (m == M4DoOpenMistakes.notAllThree) {
          unawaited(_sayChain([M4DoOpenLines.restOpen]));
          return;
        }
        _askStep();
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
    await _say(
      !_run.passed ? M4DoOpenLines.fail : (_quickBonus ? M4DoOpenLines.quick : M4DoOpenLines.allSet),
      mood: _run.passed ? GuideMood.celebrate : GuideMood.warn,
    );
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
    if (_run.stage.index <= M4DoOpenStage.prep.index) return LinemanMode.idle;
    return LinemanMode.hold;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M4DoOpenGeo.forScene(m.height, m.inset);
    final j = _job;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final gloved = _run.kit.contains(M4DoOpenKit.gloves);
    final up = _run.stage.index >= M4DoOpenStage.stand.index;
    final tb = m4DoOpenTraineeBox(geo, _standX);
    final hooked = _run.hooked;
    // The rod points at the hooked ring, or at the middle fuse.
    final target = hooked != null ? geo.ringOf(hooked) : geo.ringOf(1);
    final flip = target.dx < _standX;
    final tip0 = LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final hand = tb.topLeft + (flip ? Offset(tb.width - tip0.dx, tip0.dy) : tip0);
    final towards = target - hand;
    final tip = hooked != null ? target : hand + towards * (up ? 0.84 : 0.0);
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
                    painter: M4DoOpenWorldPainter(geo: geo, open: _run.open, blown: j.blown, puddleLeft: j.puddleLeft),
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
                    if (_run.kit.contains(M4DoOpenKit.shield))
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
                      painter: M4DoOpenRodPainter(butt: butt, tip: tip, head: _run.head),
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
                      builder: (_, v, _) => v >= 1 ? const SizedBox.shrink() : CustomPaint(painter: HsArcPainter(at: _flashAt!, v: v)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // Invisible hint anchors on the rings (no paint, no touch).
      if (_run.stage == M4DoOpenStage.open)
        for (var i = 0; i < 3; i++)
          Positioned.fromRect(
            key: ValueKey('ring-anchor-$i'),
            rect: Rect.fromCenter(center: _run.open[i] ? geo.ringOpenOf(i) : geo.ringOf(i), width: 30, height: 30),
            child: IgnorePointer(child: SizedBox.expand(key: _ringKeys[i])),
          ),
      // Tap the ground, a ring; draw the pull.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4DoOpenLines.sceneLabel,
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
              builder: (_, v, _) => CustomPaint(painter: HsArcPainter(at: _deathAt!, v: 0.25 + 0.6 * v, big: true)),
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
    Widget b(_PrepTool t, String label, IconData icon, bool on, VoidCallback tap) => KeyedSubtree(
      key: _toolKeys[t],
      child: _ToolButton(icon: icon, label: label, on: on, enabled: _canPlay, onTap: tap),
    );
    Widget tool(_PrepTool t) => switch (t) {
      _PrepTool.gloves => b(t, M4DoOpenLines.gloves, Icons.back_hand_rounded, k.contains(M4DoOpenKit.gloves), () => _wear(M4DoOpenKit.gloves)),
      _PrepTool.shield => b(t, M4DoOpenLines.shield, Icons.masks_rounded, k.contains(M4DoOpenKit.shield), () => _wear(M4DoOpenKit.shield)),
      _PrepTool.puller => b(t, M4DoOpenLines.puller, Icons.hardware_rounded, _run.head == M4DoOpenHead.puller, () => _fit(M4DoOpenHead.puller)),
      _PrepTool.loadBreak => b(
        t,
        M4DoOpenLines.loadBreak,
        Icons.battery_charging_full_rounded,
        _run.head == M4DoOpenHead.loadBreak,
        () => _fit(M4DoOpenHead.loadBreak),
      ),
    };
    return Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 6, children: [for (final t in _toolOrder) tool(t)]);
  }

  /// The hand for the waiting step: how to touch, never what to pick.
  HintSpec? _hint() {
    final geo = _geoNow;
    switch (_run.stage) {
      case M4DoOpenStage.rod:
        // A sweep over the three rods in the rack.
        final r = HintSpec.globalRectOf(_rackKey);
        if (r == null) return null;
        final w = r.width / 3;
        return HintSpec.sweep([for (var i = 0; i < 3; i++) Rect.fromLTWH(r.left + i * w, r.top, w, r.height)]);
      case M4DoOpenStage.prep:
        // A sweep over the get-ready row and the raise button.
        return HintSpec.sweepOver([for (final t in _toolOrder) _toolKeys[t]!, _raiseKey]);
      case M4DoOpenStage.stand:
        // A sweep along the ground, evenly spaced (under, puddle, side, far
        // alike): "tap where you stand".
        return HintSpec.sweep([
          for (var i = 0; i < 6; i++) Rect.fromCenter(center: Offset(36 + 58.0 * i, geo.groundY + 14), width: 40, height: 28),
        ], space: HintSpace.scene);
      case M4DoOpenStage.open:
        final h = _run.hooked;
        // Unhooked: all three rings (open or in) and the confirm button.
        // Hooked: that ring (the pull), face-aside and confirm — the same
        // sweep whether or not the face is aside, so it never shows the order.
        return HintSpec.sweepOver(h == null ? [..._ringKeys, _confirmKey] : [_ringKeys[h], _faceKey, _confirmKey]);
      case M4DoOpenStage.done:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null;
    final stage = _run.stage;
    // The level waits for a touch (not while the rod's reason is still up).
    final hintWaiting = handsOn && _canPlay && !_run.done && (stage != M4DoOpenStage.prep || _rodPicked == null);
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
              labels: M4DoOpenLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 2); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: hintWaiting,
            hintKey: '${_run.index}/${stage.name}/${_run.hooked}/${_run.open}',
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen && stage != M4DoOpenStage.rod)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(text: M4DoOpenLines.jobBn(j))),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && stage == M4DoOpenStage.rod || (_rodPicked != null && _run.index == 0 && stage == M4DoOpenStage.prep && playing))
                _RackCard(
                  key: const ValueKey('rack'),
                  boxKey: _rackKey,
                  rods: _run.deal.rods,
                  picked: _rodPicked,
                  enabled: _canPlay && stage == M4DoOpenStage.rod,
                  quiet: quiet,
                  onPick: (i, at) => unawaited(_pickRod(i, at)),
                ),
              if (handsOn && stage == M4DoOpenStage.prep && _rodPicked == null)
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
                        child: KeyedSubtree(
                          key: _raiseKey,
                          child: DoBigButton(label: M4DoOpenLines.raise, filled: true, onTapUp: (d) => unawaited(_raise(d.globalPosition))),
                        ),
                      ),
                    ],
                  ),
                ),
              if (handsOn && stage == M4DoOpenStage.open && _run.hooked != null)
                Positioned(
                  key: const ValueKey('hud-face'),
                  left: 12,
                  bottom: pad.bottom + 16,
                  child: _ToolButton(
                    key: _faceKey,
                    icon: Icons.face_retouching_off_rounded,
                    label: _run.faceAside ? M4DoOpenLines.faceAsideOn : M4DoOpenLines.faceAside,
                    on: _run.faceAside,
                    enabled: _canPlay,
                    onTap: _turnFace,
                  ),
                ),
              if (handsOn && stage == M4DoOpenStage.open)
                Positioned(
                  key: const ValueKey('hud-confirm'),
                  left: 130,
                  right: 130,
                  bottom: pad.bottom + 22,
                  child: KeyedSubtree(
                    key: _confirmKey,
                    child: DoBigButton(label: M4DoOpenLines.allOpen, filled: false, onDark: true, onTapUp: (d) => unawaited(_confirm(d.globalPosition))),
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : (stage == M4DoOpenStage.prep && handsOn ? 252 : (stage == M4DoOpenStage.open ? 96 : 72))),
                  onLeft: coworkerFromRight,
                ),
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
                  line: M4DoOpenLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 2, muted: _muted)),
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

/// The get-ready row (dealt in a fresh order each play).
enum _PrepTool { gloves, shield, puller, loadBreak }

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
            M4DoOpenLines.docket,
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
        child: Opacity(
          opacity: enabled || on ? 1 : 0.55,
          child: SizedBox(
            width: 84,
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
      ),
    );
  }
}

/// The van's rack: three operating rods; tap one to take it.
class _RackCard extends StatelessWidget {
  const _RackCard({super.key, required this.boxKey, required this.rods, required this.picked, required this.enabled, required this.quiet, required this.onPick});
  final GlobalKey boxKey;
  final List<M4DoOpenRod> rods;
  final int? picked;
  final bool enabled;
  final bool quiet;
  final void Function(int i, Offset globalAt) onPick;

  static const w = 240.0;
  static const h = 300.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.paddingOf(context).top + 170,
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
            width: w,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xE60B1324),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.6),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: Semantics(
              label: M4DoOpenLines.rackLabel,
              child: SizedBox(
                key: boxKey,
                width: w,
                height: h,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: M4DoOpenRackPainter(rods: rods, picked: picked)),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < rods.length; i++)
                          Expanded(
                            child: GestureDetector(
                              key: ValueKey('rack-rod-$i'),
                              behavior: HitTestBehavior.opaque,
                              onTapUp: enabled ? (d) => onPick(i, d.globalPosition) : null,
                              child: const SizedBox.expand(),
                            ),
                          ),
                      ],
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
