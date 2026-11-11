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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm4_service_plan_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_service_plan_world.dart'
    show
        M4ServicePlanRound,
        M4ServicePlanPaper,
        M4ServicePlanFault,
        M4ServicePlanFaultInfo,
        M4ServicePlanRoute,
        M4ServicePlanItem,
        M4ServicePlanStep,
        M4ServicePlanMap;

// Lesson 4.3 "নতুন সার্ভিস কানেকশন দেওয়া", কাজ 1 "কানেকশনের প্রস্তুতি".
// A new connection order has come in. Before a single wire goes up, the
// trainee plans the job on his clipboard by the pole — four rounds:
//   ক কাগজপত্র (inspect): the approved connection order, the meter details
//     and the permit (lesson point 1, "কাগজপত্র"). Dealt: all three in order,
//     or the order without its approval, or the meter details or the permit
//     missing. All there → start; otherwise tap the gap → have it fetched.
//   খ রুট জরিপ (choose): the survey sketch, pole → meter. The straightest
//     safe route that does not pass over a tree, another house or any
//     obstacle (point 1, "জরিপ"); the long way round means more cable and
//     more voltage drop (advanced fact "ভোল্টেজ ড্রপ").
//   গ মালামাল (choose): from the store shelf, the right-size service cable,
//     the supporting GI wire, the anchoring hardware (rack bolt for the house,
//     clamp for the pole), IPC connectors and straps (point 1, "মালামাল");
//     not the thin cable (voltage drop), not the joint tape (myth 2: a
//     stripped, twisted joint instead of IPC).
//   ঘ কাজের ক্রম (order): the job card — anchors on the house and the pole →
//     the GI wire pulled taut first → the cable strapped to it → the
//     connections and the voltage test (points 2–4).
// The careless coworker comes once a play — on the papers ("কাগজ পরে হবে"),
// the route (over the tree) or the material (no GI wire, myth 1); listening is
// the slip of that shortcut.
//
// No deadly move: this is planning, nothing is touched on the line, and the
// lesson gives no death for a planning mistake — every mistake is a slip.
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_service_plan_world.dart), corner guide, ◆ on the table →
// "কেন …?" (the reasons fit the round) → the next round by itself.
// Voice: the guide's lines by device TTS; the coworker's new lines by device
// TTS until recorded in his voice (M4ServicePlanLines.toRecord); his exit
// line is a recorded one.


// ============================================================================
// Content
// ============================================================================

abstract final class M4ServicePlanLines {
  static const title = 'কানেকশনের প্রস্তুতি';
  static const intro = 'নতুন কানেকশনের অর্ডার এসেছে! কাজে নামার আগে প্রস্তুতিটা ঠিক করুন।';
  static const rounds = ['কাগজপত্র', 'রুট জরিপ', 'মালামাল', 'কাজের ক্রম'];

  /// The round's task, as the guide asks it.
  static String ask(M4ServicePlanRound r) => switch (r) {
        M4ServicePlanRound.papers => 'আগে কাগজপত্র দেখুন। কাজ শুরু করা যায়?',
        M4ServicePlanRound.route => 'জরিপের নকশা দেখুন। কোন পথে কেবিল টানবেন?',
        M4ServicePlanRound.kit => 'মালামাল তুলুন। এই কাজে কী কী লাগবে?',
        M4ServicePlanRound.order => 'কাজের ক্রম সাজান। কোনটা আগে, কোনটা পরে?',
      };
  static String board(M4ServicePlanRound r) => rounds[r.index];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (the job card, the papers, the shelf, the buttons).
  static const jobCard = 'নতুন সার্ভিস কানেকশন';
  static String paper(M4ServicePlanPaper p) => switch (p) {
        M4ServicePlanPaper.order => 'কানেকশন অর্ডার',
        M4ServicePlanPaper.meter => 'মিটারের বিবরণ',
        M4ServicePlanPaper.permit => 'অনুমতিপত্র',
      };
  static const approval = 'অনুমোদন';
  static const approved = 'অনুমোদিত';
  static const missingSheet = 'নেই';
  static const papersGo = 'সব ঠিক, কাজ শুরু';
  static const papersFetch = 'এটা আনিয়ে নিই';
  static const routeGo = 'এই পথেই টানব';
  static const kitGo = 'গাড়িতে তুলি';
  static const mapPole = 'পোল';
  static const mapHouse = 'গ্রাহক';
  static const mapRoad = 'রাস্তা';
  static const stampDone = 'ঠিক আছে';
  static String routeName(int i) => 'রুট ${i + 1}';
  static String item(M4ServicePlanItem i) => switch (i) {
        M4ServicePlanItem.cable => 'কেবিল (মাপমতো)',
        M4ServicePlanItem.thinCable => 'কেবিল (সরু)',
        M4ServicePlanItem.giWire => 'GI সাপোর্ট তার',
        M4ServicePlanItem.rackBolt => 'র‍্যাক বোল্ট',
        M4ServicePlanItem.clamp => 'পোলের ক্ল্যাম্প',
        M4ServicePlanItem.ipc => 'IPC কানেক্টর',
        M4ServicePlanItem.straps => 'স্ট্র্যাপ',
        M4ServicePlanItem.tape => 'জোড়ের টেপ',
      };
  static String step(M4ServicePlanStep s) => switch (s) {
        M4ServicePlanStep.anchor => 'বাড়িতে র‍্যাক বোল্ট, পোলে ক্ল্যাম্প',
        M4ServicePlanStep.giWire => 'GI সাপোর্ট তার টেনে টানটান',
        M4ServicePlanStep.strap => 'কেবিল GI তারে স্ট্র্যাপে বাঁধা',
        M4ServicePlanStep.connect => 'সংযোগ, তারপর ভোল্টেজ পরীক্ষা',
      };

  // The reasons (lesson 4.3): the right ones fit the round just done; the
  // wrong ones are field excuses — never a true rule marked wrong.
  static const why = 'কেন এটা ঠিক?';
  static const papersOkWhy = [
    'অর্ডার, মিটারের বিবরণ, অনুমতি সব হাতে আছে',
    'অনুমোদিত অর্ডার আর অনুমতি ছাড়া কাজ শুরু নয়',
    'কাগজ আগে মিলিয়ে নিলে কাজ মাঝপথে থামে না',
  ];
  static const papersFetchWhy = [
    'অনুমোদিত কাগজ সব হাতে না এলে কাজ শুরু নয়',
    'অর্ডার, মিটারের বিবরণ, অনুমতি, তিনটেই চাই',
    'কাগজ অসম্পূর্ণ হলে আগে সেটা আনিয়ে নিতে হয়',
  ];
  static const routeWhy = [
    'গাছ, অন্য বাড়ি বা বাধার ওপর দিয়ে যায় না',
    'পোল থেকে মিটার, সবচেয়ে সোজা আর নিরাপদ পথ',
    'সোজা পথে কেবিল কম লাগে, ভোল্টেজ ড্রপও কম',
  ];
  static const kitWhy = [
    'কেবিলের সব টান নেবে GI তার, তাই ওটা চাই',
    'পোলে জোড় হবে IPC দিয়ে, তার পেঁচিয়ে নয়',
    'মাপমতো কেবিলে ভোল্টেজ ড্রপ কম থাকে',
    'সব মালামাল সঙ্গে থাকলে কাজ মাঝপথে থামে না',
  ];
  static const orderWhy = [
    'আগে অ্যাঙ্কর আর GI তার, তারপর কেবিল বাঁধা',
    'কেবিলের টান GI তার নেয়, তাই ওটা আগে টানা',
    'সব বাঁধা হলে তবে সংযোগ, শেষে ভোল্টেজ মাপা',
  ];

  /// Wrong reasons (field excuses).
  static const excuses = [
    'গ্রাহক তাড়া দিচ্ছেন, তাই যত তাড়াতাড়ি হয়',
    'আগেও এভাবেই করেছি, কিছু তো হয়নি কখনো',
    'সিনিয়র বলেছেন, তাই চোখ বুজে করে ফেললাম',
    'কাগজ পরে অফিসে গিয়ে মিলিয়ে নিলেই চলবে',
    'যেটা হাতের কাছে ছিল, সেটাই নিয়ে নিলাম',
    'এইটুকু কাজে অত মাপজোখের কোনো দরকার নেই',
  ];

  static List<String> whyRight(M4ServicePlanRound r, {bool fetched = false}) => switch (r) {
        M4ServicePlanRound.papers => fetched ? papersFetchWhy : papersOkWhy,
        M4ServicePlanRound.route => routeWhy,
        M4ServicePlanRound.kit => kitWhy,
        M4ServicePlanRound.order => orderWhy,
      };

  /// The careless coworker: one push per round he can come on.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _asks = ['ও শর্টকাট বলছে। আপনি কী করবেন?', 'ওর কথা শুনবেন, না নিয়মে চলবেন?', 'এখন কোন পথে যাবেন?'];
  static const coworkerPapers = CoworkerScript(
    line: 'আরে, কাগজ পরে হবে! আগে লাইনটা দিয়ে দাও, গ্রাহক বসে আছেন।',
    exitLine: coworkerExit,
    right: ['না, অনুমোদিত কাগজ ছাড়া কাজ নয়', 'না, আগে কাগজ আনিয়ে তারপর কাজ', 'না, কাগজ সব হাতে এলে তবেই শুরু'],
    wrong: ['ঠিক, কাগজ পরে মিলিয়ে নেব', 'আচ্ছা, গ্রাহক তো বসেই আছেন', 'হ্যাঁ, লাইনটা আগে দিয়ে দিই', 'ঠিক আছে, অফিস পরে সামলাবে', 'হ্যাঁ, এইটুকু কাজে কাগজ কী'],
    asks: _asks,
  );
  static const coworkerRoute = CoworkerScript(
    line: 'গাছের ওপর দিয়েই টেনে দাও! ঘুরিয়ে নেওয়ার কী দরকার?',
    exitLine: coworkerExit,
    right: ['না, গাছের ওপর দিয়ে কেবিল নয়', 'না, বাধাহীন সোজা পথেই টানব', 'না, জরিপের নিরাপদ পথই নেব'],
    wrong: ['ঠিক, গাছের ওপর দিয়েই টানি', 'আচ্ছা, ডালে একটু ঘষলে কিছু না', 'হ্যাঁ, এভাবেই তো তাড়াতাড়ি', 'ঠিক আছে, গাছ পরে ছেঁটে নেবে', 'হ্যাঁ, এইটুকু পথে জরিপ কী'],
    asks: _asks,
  );
  static const coworkerKit = CoworkerScript(
    line: 'GI তার লাগবে না! কেবিলটাই পোল থেকে বাড়ি টেনে দাও।',
    exitLine: coworkerExit,
    right: ['না, কেবিলের টান GI তার নেবে', 'না, GI তার ছাড়া কেবিল ঝুলে যায়', 'না, সাপোর্টিং GI তার নেবই'],
    wrong: ['ঠিক, কেবিলটাই যথেষ্ট মজবুত', 'আচ্ছা, GI তার বাদ দিয়ে দিই', 'হ্যাঁ, এইটুকু দূরত্বে চলে যাবে', 'ঠিক আছে, পরে দরকার হলে দেব', 'হ্যাঁ, মালামাল কম হলেই ভালো'],
    asks: _asks,
  );
  static CoworkerScript coworkerFor(M4ServicePlanRound r) => switch (r) {
        M4ServicePlanRound.route => coworkerRoute,
        M4ServicePlanRound.kit => coworkerKit,
        _ => coworkerPapers,
      };

  /// The coworker's new lines (device TTS until recorded in his voice).
  static List<String> get toRecord => [coworkerPapers.line, coworkerRoute.line, coworkerKit.line];

  /// The guide's fixed lines (device TTS until recorded).
  static List<String> get guideLines => [
        intro,
        for (final r in M4ServicePlanRound.values) ask(r),
        ..._asks,
        ...tapWhy,
        why,
        callHeld,
        allSet,
        quick,
        fail,
      ];

  static const callHeld = 'ঠিক! চাপে পড়ে শর্টকাট নয়।';
  static const allSet = 'প্রস্তুতি নিখুঁত — এবার নিশ্চিন্তে কাজে নামুন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কাগজ, রুট, মালামাল, তারপর কাজ।';

  // "আজ যা ধরলেন".
  static const caughtPapers = 'কাগজ মিলিয়ে তবে কাজ';
  static const caughtRoute = 'সোজা, বাধাহীন রুট';
  static const caughtKit = 'GI তার, IPC সহ মালামাল';
  static const caughtOrder = 'আগে অ্যাঙ্কর ও GI, পরে কেবিল';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static String caught(M4ServicePlanRound r) => switch (r) {
        M4ServicePlanRound.papers => caughtPapers,
        M4ServicePlanRound.route => caughtRoute,
        M4ServicePlanRound.kit => caughtKit,
        M4ServicePlanRound.order => caughtOrder,
      };
}

abstract final class M4ServicePlanMistakes {
  static const _dir = 'assets/game/art/m4_service_plan';
  static const _k = '4.3/m4_service_plan';

  static const paperMissing = DoMistake(
    key: '$_k/start-without-papers',
    textBn: 'কাগজ ছাড়া কাজ নয়। অনুমোদিত কানেকশন অর্ডার, মিটারের বিবরণ আর অনুমতিপত্র হাতে না পেলে শুরু করবেন না।',
    art: '$_dir/papers.svg',
    lessonPoint: 0,
  );
  static const paperMisread = DoMistake(
    key: '$_k/paper-misread',
    textBn: 'এই কাগজটা ঠিকই ছিল। তিনটে কাগজই ভালো করে মেলান — অর্ডারে অনুমোদন আছে কি না, কোনটা নেই।',
    art: '$_dir/papers.svg',
    lessonPoint: 0,
  );
  static const routeTree = DoMistake(
    key: '$_k/route-over-tree',
    textBn: 'গাছের ওপর দিয়ে কেবিল নয়। জরিপে এমন পথ বাছুন, যা গাছ, অন্য বাড়ি বা কোনো বাধার ওপর দিয়ে যায় না।',
    art: '$_dir/route_tree.svg',
    lessonPoint: 0,
  );
  static const routeRoof = DoMistake(
    key: '$_k/route-over-house',
    textBn: 'অন্যের বাড়ির ওপর দিয়ে কেবিল নয়। পোল থেকে মিটার পর্যন্ত সবচেয়ে সোজা আর নিরাপদ, বাধাহীন পথ বাছুন।',
    art: '$_dir/route_roof.svg',
    lessonPoint: 0,
  );
  static const routeLong = DoMistake(
    key: '$_k/route-long-way',
    textBn: 'ঘুরপথে কেবিল লম্বা হয় — মালামাল বেশি, ভোল্টেজ ড্রপও বেশি। সবচেয়ে সোজা, নিরাপদ পথটা বাছুন।',
    art: '$_dir/route_long.svg',
    lessonPoint: 0,
  );
  static const thinCable = DoMistake(
    key: '$_k/thin-cable',
    textBn: 'সরু বা ভুল মাপের কেবিলে ভোল্টেজ ড্রপ বাড়ে, গ্রাহক লো-ভোল্টেজ পান। সঠিক সাইজের সার্ভিস কেবিল নিন।',
    art: '$_dir/cable_size.svg',
    lessonPoint: 0,
  );
  static const noGiWire = DoMistake(
    key: '$_k/no-gi-wire',
    textBn: 'সাপোর্টিং GI তার ছাড়া কেবিল নয়। কেবিলের সব টান GI তার নেয় — না থাকলে কেবিল ঝুলে পড়ে, ঝড়ে ছিঁড়ে যায়।',
    art: '$_dir/no_gi.svg',
    lessonPoint: 1,
  );
  static const noIpc = DoMistake(
    key: '$_k/no-ipc',
    textBn: 'তার ছিলে পেঁচিয়ে, টেপ মেরে জোড় নয় — জল ঢোকে, করোশন, লুজ হয়ে হট স্পট। পোলে সংযোগ IPC কানেক্টরে।',
    art: '$_dir/twist_joint.svg',
    lessonPoint: 2,
  );
  static const noAnchor = DoMistake(
    key: '$_k/no-anchor',
    textBn: 'বাড়িতে র‍্যাক বোল্ট আর পোলে ক্ল্যাম্প ছাড়া অ্যাঙ্করিং হবে না — কাজ মাঝপথে থেমে যাবে। অ্যাঙ্করিং হার্ডওয়্যার নিন।',
    art: '$_dir/anchors.svg',
    lessonPoint: 1,
  );
  static const noStraps = DoMistake(
    key: '$_k/no-straps',
    textBn: 'স্ট্র্যাপ ছাড়া কেবিল GI তারে বাঁধবেন কী দিয়ে? মালামাল কম থাকলে কাজ মাঝপথে থেমে যায়।',
    art: '$_dir/straps.svg',
    lessonPoint: 0,
  );
  static const orderWrong = DoMistake(
    key: '$_k/wrong-order',
    textBn: 'ক্রম ভুল। আগে বাড়ি আর পোলে অ্যাঙ্কর, তারপর GI তার টানটান, তারপর কেবিল বাঁধা — শেষে সংযোগ আর পরীক্ষা।',
    art: '$_dir/order.svg',
    lessonPoint: 1,
  );

  static List<DoMistake> get all => [paperMissing, paperMisread, routeTree, routeRoof, routeLong, thinCable, noGiWire, noIpc, noAnchor, noStraps, orderWrong];

  static DoMistake? forRoute(M4ServicePlanRoute r) => switch (r) {
        M4ServicePlanRoute.straight => null,
        M4ServicePlanRoute.tree => routeTree,
        M4ServicePlanRoute.roof => routeRoof,
        M4ServicePlanRoute.detour => routeLong,
      };

  /// What loading [picked] is (null = the right set). The first gap counts.
  static DoMistake? forKit(Set<M4ServicePlanItem> picked) {
    if (picked.contains(M4ServicePlanItem.thinCable) || !picked.contains(M4ServicePlanItem.cable)) return thinCable;
    if (!picked.contains(M4ServicePlanItem.giWire)) return noGiWire;
    if (picked.contains(M4ServicePlanItem.tape) || !picked.contains(M4ServicePlanItem.ipc)) return noIpc;
    if (!picked.contains(M4ServicePlanItem.rackBolt) || !picked.contains(M4ServicePlanItem.clamp)) return noAnchor;
    if (!picked.contains(M4ServicePlanItem.straps)) return noStraps;
    return null;
  }

  /// The coworker's shortcut on [r], if taken.
  static DoMistake pushed(M4ServicePlanRound r) => switch (r) {
        M4ServicePlanRound.route => routeTree,
        M4ServicePlanRound.kit => noGiWire,
        _ => paperMissing,
      };
}

/// The right things to load.
const m4ServicePlanKit = {M4ServicePlanItem.cable, M4ServicePlanItem.giWire, M4ServicePlanItem.rackBolt, M4ServicePlanItem.clamp, M4ServicePlanItem.ipc, M4ServicePlanItem.straps};

@immutable
class M4ServicePlanDeal {
  const M4ServicePlanDeal({required this.fault, required this.routes, required this.mirror, required this.shelf, required this.cards, required this.callAt});

  /// What is wrong with the papers (none: all in order).
  final M4ServicePlanFault fault;

  /// The three routes on the sketch, as numbered 1–3 (one straight).
  final List<M4ServicePlanRoute> routes;

  /// The sketch drawn mirrored (the pole on the right).
  final bool mirror;

  /// The shelf, tile by tile.
  final List<M4ServicePlanItem> shelf;

  /// The work-order cards as shown (never already in order).
  final List<M4ServicePlanStep> cards;

  /// The round the careless coworker comes on (papers, route or kit).
  final int callAt;
}

/// A fresh deal: who pushes on which round, what is wrong with the papers
/// (never all fine when he pushes on them), two of the three wrong routes
/// (the tree one when he pushes over the tree), the sketch side, the shelf
/// and the cards shuffled.
M4ServicePlanDeal dealM4ServicePlan(math.Random rng) {
  final callAt = rng.nextInt(3);
  final fault = callAt == 0 ? M4ServicePlanFault.values[1 + rng.nextInt(3)] : M4ServicePlanFault.values[rng.nextInt(4)];
  final wrong = [M4ServicePlanRoute.tree, M4ServicePlanRoute.roof, M4ServicePlanRoute.detour]..shuffle(rng);
  var two = wrong.take(2).toList();
  if (callAt == 1 && !two.contains(M4ServicePlanRoute.tree)) two = [M4ServicePlanRoute.tree, two.first];
  final routes = [M4ServicePlanRoute.straight, ...two]..shuffle(rng);
  final shelf = [...M4ServicePlanItem.values]..shuffle(rng);
  List<M4ServicePlanStep> cards;
  do {
    cards = [...M4ServicePlanStep.values]..shuffle(rng);
  } while (cards.first == M4ServicePlanStep.anchor && cards[1] == M4ServicePlanStep.giWire);
  return M4ServicePlanDeal(fault: fault, routes: routes, mirror: rng.nextBool(), shelf: shelf, cards: cards, callAt: callAt);
}

/// The play state (pure logic).
class M4ServicePlanRun {
  M4ServicePlanRun(this.deal);
  final M4ServicePlanDeal deal;
  int index = 0;

  /// The round is over (right or a slip) — waiting for its reason or card.
  bool shown = false;
  int slips = 0;
  final List<String> caught = [];

  M4ServicePlanPaper? paper;

  /// The missing / unapproved paper has been fetched.
  bool fetched = false;
  M4ServicePlanRoute? route;
  final Set<M4ServicePlanItem> picked = {};
  final List<M4ServicePlanStep> placed = [];

  bool get done => index >= M4ServicePlanRound.values.length;
  M4ServicePlanRound get round => M4ServicePlanRound.values[index.clamp(0, M4ServicePlanRound.values.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake? _settle(DoMistake? m) {
    shown = true;
    if (m != null) {
      slips++;
      return m;
    }
    _tag(M4ServicePlanLines.caught(round));
    return null;
  }

  bool get _open => !done && !shown;

  // ক — the papers.
  void selectPaper(M4ServicePlanPaper p) {
    if (_open && round == M4ServicePlanRound.papers) paper = paper == p ? null : p;
  }

  /// "All fine, start": right only when nothing is missing.
  DoMistake? papersStart() {
    if (!_open || round != M4ServicePlanRound.papers) return null;
    return _settle(deal.fault == M4ServicePlanFault.none ? null : M4ServicePlanMistakes.paperMissing);
  }

  /// "Have this one fetched" on the selected paper.
  DoMistake? papersFetch() {
    if (!_open || round != M4ServicePlanRound.papers || paper == null) return null;
    if (deal.fault.paper == paper) {
      fetched = true;
      return _settle(null);
    }
    return _settle(M4ServicePlanMistakes.paperMisread);
  }

  // খ — the route.
  void selectRoute(M4ServicePlanRoute r) {
    if (_open && round == M4ServicePlanRound.route) route = r;
  }

  DoMistake? routeGo() {
    if (!_open || round != M4ServicePlanRound.route || route == null) return null;
    return _settle(M4ServicePlanMistakes.forRoute(route!));
  }

  // গ — the material.
  void toggleItem(M4ServicePlanItem i) {
    if (!_open || round != M4ServicePlanRound.kit) return;
    if (!picked.remove(i)) picked.add(i);
  }

  DoMistake? kitLoad() {
    if (!_open || round != M4ServicePlanRound.kit || picked.isEmpty) return null;
    return _settle(M4ServicePlanMistakes.forKit(picked));
  }

  // ঘ — the work order: tap the cards in order.
  DoMistake? tapCard(M4ServicePlanStep s) {
    if (!_open || round != M4ServicePlanRound.order || placed.contains(s)) return null;
    if (s != M4ServicePlanStep.values[placed.length]) return _settle(M4ServicePlanMistakes.orderWrong);
    placed.add(s);
    if (placed.length == M4ServicePlanStep.values.length) return _settle(null);
    return null;
  }

  /// Listened to the coworker: his shortcut, on the current round.
  DoMistake? takeShortcut() {
    if (!_open) return null;
    return _settle(M4ServicePlanMistakes.pushed(round));
  }

  void next() {
    index++;
    shown = false;
    paper = null;
    route = null;
  }
}

/// The quick bonus: a little under a clean play (~85 %, rounded to 5 s). The
/// clock runs from the end of the guide's intro to the last paid reason.
/// A clean round (ms; ~1500 human reaction per action):
///   the guide asks                                           2800
///   papers: look 2500 + (tap a sheet 1500) + a button 1500     5500
///   route: look 2500 + tap 1500 + button 1500                  5500
///   kit: look 2000 + 6 taps × 1000 + button 1500               9500
///   order: read 3000 + 4 taps × 1200                           7800
///   (mean of the four ≈ 7100)
///   reason: praise ~1500 + 650 gap + deck 910 + read 2000
///     + pick 1500 + "এই তো আসল কথা" ~1200 + 450             8210
///   = (2800 + 7100 + 8210) × 4                              72440
/// + the coworker once: his line ~3500 + deck 910 + read and pick 3500 + 420
///                                                            8330
/// ≈ 80770 ms; 85 % ≈ 68650 → 70 s.
const kM4ServicePlanQuickMs = 70000;

@immutable
class M4ServicePlanPack {
  const M4ServicePlanPack({required this.id, required this.titleBn, this.quickMs = kM4ServicePlanQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m4ServicePlanPacks = {
  'do_4_3_a': M4ServicePlanPack(id: 'do_4_3_a', titleBn: M4ServicePlanLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4ServicePlanPage extends StatefulWidget {
  const M4ServicePlanPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4ServicePlanPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4ServicePlanPage> createState() => _M4ServicePlanPageState();
}

class _M4ServicePlanPageState extends State<M4ServicePlanPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SpRunPage(
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

class _SpRunPage extends ConsumerStatefulWidget {
  const _SpRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4ServicePlanPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SpRunPage> createState() => _SpRunPageState();
}

class _SpRunPageState extends ConsumerState<_SpRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4ServicePlanRun _run = M4ServicePlanRun(dealM4ServicePlan(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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
  var _doneStamp = false;

  /// A wrong move: the board shakes once.
  int _shake = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_run.shown && !_run.done;

  // --- a round --------------------------------------------------------------------
  void _startRound() {
    setState(() {
      _doneStamp = false;
      _wake++;
    });
    if (_run.index == _run.deal.callAt) scheduleCoworker();
    unawaited(_sayChain([M4ServicePlanLines.ask(_run.round)]));
  }

  /// A free pick on the board (a sheet, a route, a shelf item).
  void _pick(VoidCallback change) {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.wav', volume: 0.35);
    setState(() {
      change();
      _wake++;
    });
  }

  /// A committing move: [act] settles the round (or, on the job card, places
  /// one card).
  Future<void> _act(Offset origin, DoMistake? Function() act, {bool force = false}) async {
    if (!force && !_canPlay) return;
    final m = act();
    HapticFeedback.mediumImpact();
    if (m == null) {
      if (!_run.shown) {
        // One card placed on the job card; the round goes on.
        _cue('sounds/learn/tag_slap.wav', volume: 0.6);
        setState(() => _wake++);
        return;
      }
      _hush();
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      setState(() {
        _doneStamp = true;
        _wake++;
      });
      putOnTable(15);
      final idx = _run.index;
      final round = _run.round;
      final fetched = _run.fetched;
      unawaited(askReason(
        deal: () => dealChoices(M4ServicePlanLines.whyRight(round, fetched: fetched), M4ServicePlanLines.excuses, widget.rng),
        question: M4ServicePlanLines.why,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    _hush();
    setState(() => _shake++);
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
  CoworkerScript get coworkerScript => M4ServicePlanLines.coworkerFor(M4ServicePlanRound.values[_run.deal.callAt]);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.shown) return null;
    if (_intro || _card != null || reasonOpen) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: does it his way (the slip of that shortcut).
      await _act(origin, _run.takeShortcut, force: true);
      return;
    }
    _run.caught.add(M4ServicePlanLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4ServicePlanLines.callHeld, M4ServicePlanLines.ask(_run.round)], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4ServicePlanLines.tapWhy[_nudgeN++ % M4ServicePlanLines.tapWhy.length]
            : _nudge.next(M4ServicePlanLines.ask(_run.round));
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('service_plan/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() => _card = null);
    _next();
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
    await _say(!_run.passed ? M4ServicePlanLines.fail : (_quickBonus ? M4ServicePlanLines.quick : M4ServicePlanLines.allSet),
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
  LinemanMode get _mode {
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_doneStamp) return LinemanMode.cheer;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M4ServicePlanGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final playing = !_intro && _mark == null && !struckOut && !_run.done;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: RepaintBoundary(child: CustomPaint(painter: M4ServicePlanWorldPainter(geo: geo))),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      Positioned.fill(
        key: const ValueKey('board'),
        child: RepaintBoundary(child: CustomPaint(painter: M4ServicePlanBoardPainter(geo: geo))),
      ),
      Positioned(
        key: const ValueKey('board-title'),
        left: geo.board.left + 14,
        top: geo.board.top + 6,
        child: IgnorePointer(
          child: Text(
            M4ServicePlanLines.board(_run.round),
            style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFFFFF3D6)),
          ),
        ),
      ),
      if (playing)
        Positioned.fromRect(
          key: ValueKey('work-${_run.index}'),
          rect: geo.content,
          child: _Shake(
            key: ValueKey('shake-$_shake'),
            on: _shake > 0 && !quiet,
            child: switch (_run.round) {
              M4ServicePlanRound.papers => _papers(),
              M4ServicePlanRound.route => _routes(),
              M4ServicePlanRound.kit => _kit(geo),
              M4ServicePlanRound.order => _order(geo),
            },
          ),
        ),
      if (playing && !_run.shown && _card == null)
        Positioned.fromRect(
          key: ValueKey('buttons-${_run.index}'),
          rect: geo.buttons,
          child: _buttons(),
        ),
      if (_doneStamp && playing)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: geo.content.center.dx - 70,
          width: 140,
          top: geo.content.center.dy - 20,
          child: IgnorePointer(child: _StampPop(text: M4ServicePlanLines.stampDone, quiet: quiet)),
        ),
    ];
  }

  Widget _papers() {
    final r = _run;
    return Row(
      children: [
        for (final (i, p) in M4ServicePlanPaper.values.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              selected: r.paper == p,
              label: M4ServicePlanLines.paper(p),
              excludeSemantics: true,
              child: GestureDetector(
                key: ValueKey('paper-${p.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _pick(() => r.selectPaper(p)),
                child: _Sheet(
                  paper: p,
                  present: r.fetched || r.deal.fault.paper != p || r.deal.fault == M4ServicePlanFault.orderUnapproved,
                  approved: r.fetched || r.deal.fault != M4ServicePlanFault.orderUnapproved,
                  selected: r.paper == p,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _routes() {
    final r = _run;
    return LayoutBuilder(builder: (context, box) {
      final area = Offset.zero & box.biggest;
      Offset at(Offset n) => M4ServicePlanMap.place(n, area, r.deal.mirror);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: M4ServicePlanMapPainter(routes: r.deal.routes, mirror: r.deal.mirror, picked: r.route)),
            ),
          ),
          for (final (label, n) in [
            (M4ServicePlanLines.mapPole, M4ServicePlanMap.pole + const Offset(0, -0.12)),
            (M4ServicePlanLines.mapHouse, M4ServicePlanMap.house.center + const Offset(0.02, -0.04)),
            (M4ServicePlanLines.mapRoad, Offset(r.deal.mirror ? 0.84 : 0.16, 0.49)),
          ])
            Positioned(
              left: at(n).dx - 30,
              width: 60,
              top: at(n).dy - 9,
              child: IgnorePointer(
                child: Text(label,
                    textAlign: TextAlign.center, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF34404C), height: 1.1)),
              ),
            ),
          for (final (i, route) in r.deal.routes.indexed)
            Positioned(
              key: ValueKey('route-${route.name}'),
              left: at(M4ServicePlanMap.chip(route)).dx - 22,
              top: at(M4ServicePlanMap.chip(route)).dy - 22,
              width: 44,
              height: 44,
              child: Semantics(
                button: true,
                selected: r.route == route,
                label: M4ServicePlanLines.routeName(i),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pick(() => r.selectRoute(route)),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r.route == route ? const Color(0xFFE0A100) : M4ServicePlanMapPainter.routeColors[i],
                        border: Border.all(color: Colors.white, width: 2.4),
                        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 1))],
                      ),
                      child: Text('${i + 1}', style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _kit(M4ServicePlanGeo geo) {
    final r = _run;
    final tiles = geo.shelf(r.deal.shelf);
    final o = geo.content.topLeft;
    return Stack(
      children: [
        for (final MapEntry(key: it, value: rect) in tiles.entries)
          Positioned.fromRect(
            key: ValueKey('item-${it.name}'),
            rect: rect.shift(-o),
            child: Semantics(
              button: true,
              selected: r.picked.contains(it),
              label: M4ServicePlanLines.item(it),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _pick(() => r.toggleItem(it)),
                child: _ItemTile(item: it, picked: r.picked.contains(it)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _order(M4ServicePlanGeo geo) {
    final r = _run;
    final cards = geo.cards(r.deal.cards);
    final o = geo.content.topLeft;
    return Stack(
      children: [
        for (final MapEntry(key: s, value: rect) in cards.entries)
          Positioned.fromRect(
            key: ValueKey('card-${s.name}'),
            rect: rect.shift(-o),
            child: Semantics(
              button: true,
              label: M4ServicePlanLines.step(s),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => unawaited(_act(d.globalPosition, () => r.tapCard(s))),
                child: _StepCard(text: M4ServicePlanLines.step(s), number: r.placed.contains(s) ? r.placed.indexOf(s) + 1 : null),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buttons() {
    final r = _run;
    return switch (r.round) {
      M4ServicePlanRound.papers => Row(
          children: [
            Expanded(
              child: _BoardButton(label: M4ServicePlanLines.papersGo, filled: true, onTapUp: (d) => unawaited(_act(d.globalPosition, r.papersStart))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BoardButton(
                label: M4ServicePlanLines.papersFetch,
                filled: false,
                enabled: r.paper != null,
                onTapUp: (d) => unawaited(_act(d.globalPosition, r.papersFetch)),
              ),
            ),
          ],
        ),
      M4ServicePlanRound.route => _BoardButton(
          label: M4ServicePlanLines.routeGo,
          filled: true,
          enabled: r.route != null,
          onTapUp: (d) => unawaited(_act(d.globalPosition, r.routeGo)),
        ),
      M4ServicePlanRound.kit => _BoardButton(
          label: M4ServicePlanLines.kitGo,
          filled: true,
          enabled: r.picked.isNotEmpty,
          onTapUp: (d) => unawaited(_act(d.globalPosition, r.kitLoad)),
        ),
      M4ServicePlanRound.order => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final k = size.width / 360;
    final boardTop = (300 + 16) * k + pad.bottom;
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
              labels: M4ServicePlanLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              // The job card (hidden while his speech bubble is up, which covers it).
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('job-${_run.index}'),
                  right: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _JobChip(round: _run.round)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : boardTop, onLeft: coworkerFromRight),
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
                  line: M4ServicePlanLines.intro,
                  alarm: 'sounds/learn/tag_slap.wav',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _clock.start();
                    _startRound();
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 0, muted: _muted)),
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

class _JobChip extends StatelessWidget {
  const _JobChip({required this.round});
  final M4ServicePlanRound round;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
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
          Text(M4ServicePlanLines.jobCard, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4ServicePlanLines.board(round), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// One paper on the clipboard (or the empty place where it should be).
class _Sheet extends StatelessWidget {
  const _Sheet({required this.paper, required this.present, required this.approved, required this.selected});
  final M4ServicePlanPaper paper;
  final bool present;
  final bool approved;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFFE0A100) : const Color(0xFFB9AE92);
    if (!present) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0x14000000),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? border : const Color(0xFF9C9179), width: selected ? 3 : 1.6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.attach_file, size: 26, color: Color(0xFF7D735E)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(M4ServicePlanLines.paper(paper),
                  textAlign: TextAlign.center, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF7D735E), height: 1.15)),
            ),
            Text(M4ServicePlanLines.missingSheet, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFB3261E))),
          ],
        ),
      );
    }
    Widget lines(int n) => Column(
          children: [
            for (var i = 0; i < n; i++)
              Container(
                height: 3,
                margin: EdgeInsets.only(top: 6, right: i.isOdd ? 18 : 4),
                color: const Color(0xFFC9C2B0),
              ),
          ],
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 8, 7, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: selected ? 3 : 1.4),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(M4ServicePlanLines.paper(paper),
              textAlign: TextAlign.center, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416), height: 1.15)),
          lines(4),
          const Spacer(),
          if (paper == M4ServicePlanPaper.order) ...[
            Text('${M4ServicePlanLines.approval}:', style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
            SizedBox(
              height: 26,
              child: approved
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Transform.rotate(
                        angle: -0.18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC62828), width: 2), borderRadius: BorderRadius.circular(4)),
                          child: Text(M4ServicePlanLines.approved, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFFC62828))),
                        ),
                      ),
                    )
                  : Container(margin: const EdgeInsets.only(top: 18, left: 4, right: 4), height: 1.4, color: const Color(0xFF9C9179)),
            ),
          ]
          else if (paper == M4ServicePlanPaper.permit)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1565C0), width: 2)),
                child: const Icon(Icons.verified, size: 18, color: Color(0xFF1565C0)),
              ),
            )
          else
            const Align(alignment: Alignment.centerRight, child: Icon(Icons.speed, size: 28, color: Color(0xFF455A64))),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.picked});
  final M4ServicePlanItem item;
  final bool picked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: picked ? const Color(0xFFFFF4D2) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: picked ? const Color(0xFFE0A100) : const Color(0xFFC9C2B0), width: picked ? 3 : 1.2),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(child: CustomPaint(painter: M4ServicePlanItemPainter(item), child: const SizedBox.expand())),
              SizedBox(
                height: 30,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Center(
                    child: Text(M4ServicePlanLines.item(item),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF2B2416), height: 1.1)),
                  ),
                ),
              ),
            ],
          ),
          if (picked)
            const Positioned(
              right: 3,
              top: 3,
              child: Icon(Icons.check_circle, size: 20, color: Color(0xFF2E7D32)),
            ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.text, required this.number});
  final String text;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final on = number != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: on ? const Color(0xFF2E7D32) : const Color(0xFFC9C2B0), width: on ? 2.2 : 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? const Color(0xFF2E7D32) : const Color(0xFFEDE7D6),
              border: Border.all(color: on ? const Color(0xFF2E7D32) : const Color(0xFFB9AE92), width: 1.4),
            ),
            child: Text(on ? '$number' : '', style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, maxLines: 2, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF2B2416), height: 1.15)),
          ),
        ],
      ),
    );
  }
}

class _BoardButton extends StatelessWidget {
  const _BoardButton({required this.label, required this.filled, required this.onTapUp, this.enabled = true});
  final String label;
  final bool filled;
  final bool enabled;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: filled ? SlmColors.gold700 : const Color(0xE60B1324),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTapUp: enabled ? onTapUp : null,
          onTap: enabled ? () {} : null,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: filled ? null : Border.all(color: SlmColors.gold300.withValues(alpha: 0.8), width: 1.6),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: filled ? Colors.white : SlmColors.ivory)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A one-shot side shake (a wrong move on the board).
class _Shake extends StatelessWidget {
  const _Shake({super.key, required this.on, required this.child});
  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, v, child) => Transform.translate(offset: Offset(math.sin(v * math.pi * 6) * 7 * (1 - v), 0), child: child),
      child: child,
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
      builder: (_, v, child) => Transform.rotate(angle: -0.1, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        alignment: Alignment.center,
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
