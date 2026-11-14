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
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'm4_tree_plan_world.dart';
import 'spoken_once.dart';

export 'm4_tree_plan_world.dart' show M4TreePlanGeo, M4TreePlanBranch, M4TreePlanWire;

// Lesson 4.8 "গাছের ডালপালা ছাঁটা", কাজ 1 "কাটার আগে পরিকল্পনা" (pack
// do_4_8_a). Three trees a play along a roadside line, dealt fresh: an 11 kV
// line or an LT এবি কেবিল, a tree whose branches have grown up into the wires
// (2–3 of them, thin or thick), the rest of the crown well below.
// Each tree, hands on:
//   1. survey (spot): tap every branch that has grown into the line's
//      clearance (point 3: keep 1.5–3 m; advanced fact 1 + the film:
//      directional pruning — only the branches growing toward the line, never
//      topping the tree); "জরিপ শেষ" with one missed = a slip; tapping a
//      branch well clear of the line = a slip;
//   2. the drop zone (spot): tap the ground where the branches will come down
//      — the cordon goes round it (point 2: rope or tape off the area so cut
//      branches do not fall on people or traffic); on the road = a slip; on
//      the verge away from the tree = a slip (the branches would land outside
//      the cordon); a tap off the ground (sky, wires) is a miss, not scored;
//   3. the plan (choose, all before the first cut, any order among them):
//      শাটডাউন · PTW (point 2: branches very close to the line → PTW and the
//      line de-energised before work; the film: "লাইনের কাছে কাজের আগে
//      শাটডাউন নিন"), a helper below for traffic (pro tip 1: never alone),
//      শক্ত গ্লাভস + গগলস (point 2), a rope for a heavy branch (point 3:
//      control the fall), and the tool: insulated pruner or saw for thin
//      branches, chainsaw for thick (point 2; pro tip 2: fibreglass handles
//      near the line); a plain saw = a slip. The plan buttons are dealt in a
//      fresh order per tree (never the plan's order).
// Deadly: starting the cut with the line live (no শাটডাউন).
// The careless coworker ("লাইন চালু থাক …") comes once a play, before the
// শাটডাউন is taken; taking it and "কাটা শুরু" wait for him
// (holdForCoworker). Listening to him = a slip (playbook row 8, audit
// 2026-11-11); the শাটডাউন stays on offer — cutting without it is still
// the deadly.
// Kit 2026-11-11: no control works in a praise window (tableBusy); gesture
// hints sweep over all the branches + "জরিপ শেষ", the ground (verge and road)
// or the plan buttons + "কাটা শুরু" — never one answer.
// The test-and-earth after the shutdown is drawn (earth leads on the pole)
// from the Module rule; lesson 4.8 itself says only PTW + de-energise (flagged).
// Shared kit: guide first, full scene, corner guide, ◆ on the table → "কেন …?"
// → the next tree by itself. His new line goes by device TTS until recorded
// ([M4TreePlanLines.recordLines]).

// ============================================================================
// Content
// ============================================================================

/// The branches grown into the line: thin (pruner / saw) or thick (chainsaw).
enum M4TreePlanSize { small, big }

/// The plan items besides the tool.
enum M4TreePlanKit { shutdown, helper, ppe, rope }

/// The tool picked (one at a time).
enum M4TreePlanTool { none, pruner, saw, chainsaw, plain }

/// The steps at a tree.
enum M4TreePlanPhase { survey, drop, plan, cut, done }

/// What a reason card asks about.
enum M4TreePlanTopic { shutdown, cordon, tool, directional, abCable }

/// Where a tap puts the drop zone: under the tree, on the road, on the verge
/// away from the tree, or off the ground (a miss).
enum M4TreePlanDrop { zone, road, away, far }

/// A button on the plan rack (dealt in a fresh order per tree).
enum M4TreePlanItem { shutdown, helper, ppe, rope, pruner, saw, chainsaw, plain }

@immutable
class M4TreePlanTree {
  const M4TreePlanTree({
    required this.wire,
    required this.size,
    required this.treeX,
    required this.branches,
    required this.topic,
    required this.walkerX,
    this.rack = M4TreePlanItem.values,
  });
  final M4TreePlanWire wire;
  final M4TreePlanSize size;
  final double treeX;
  final List<M4TreePlanBranch> branches;
  final M4TreePlanTopic topic;
  final double walkerX;

  /// The plan buttons in their dealt order.
  final List<M4TreePlanItem> rack;

  bool get big => size == M4TreePlanSize.big;
  List<int> get toward => [
    for (var i = 0; i < branches.length; i++)
      if (branches[i].toward) i,
  ];
}

@immutable
class M4TreePlanDeal {
  const M4TreePlanDeal({required this.trees, required this.callAt});
  final List<M4TreePlanTree> trees;

  /// The tree the careless coworker comes at.
  final int callAt;
}

// Branch shapes (relative to the fork): up into the line / out and down.
const _towardSlots = [
  M4TreePlanBranch(dx: -92, dy: 0, baseDy: 6, bend: 0.12, toward: true),
  M4TreePlanBranch(dx: -36, dy: 0, baseDy: -6, bend: -0.1, toward: true),
  M4TreePlanBranch(dx: 42, dy: 0, baseDy: -4, bend: 0.1, toward: true),
  M4TreePlanBranch(dx: 96, dy: 0, baseDy: 8, bend: -0.12, toward: true),
];
const _clearSlots = [
  M4TreePlanBranch(dx: -112, dy: 16, baseDy: 18, bend: 0.15, toward: false),
  M4TreePlanBranch(dx: 108, dy: 6, baseDy: 14, bend: -0.15, toward: false),
  M4TreePlanBranch(dx: -70, dy: 54, baseDy: 34, bend: 0.1, toward: false),
  M4TreePlanBranch(dx: 74, dy: 50, baseDy: 30, bend: -0.1, toward: false),
];

/// Three trees: an 11 kV line and an এবি কেবিল at least once each, thin and
/// thick branches at least once each; the branches, the topics, his tree dealt.
M4TreePlanDeal m4TreePlanDeal(math.Random rng) {
  final wires = [M4TreePlanWire.hv11, M4TreePlanWire.abLt, rng.nextBool() ? M4TreePlanWire.hv11 : M4TreePlanWire.abLt]..shuffle(rng);
  final sizes = [M4TreePlanSize.big, M4TreePlanSize.small, rng.nextBool() ? M4TreePlanSize.big : M4TreePlanSize.small]..shuffle(rng);
  final pool = [M4TreePlanTopic.shutdown, M4TreePlanTopic.cordon, M4TreePlanTopic.tool, M4TreePlanTopic.directional]..shuffle(rng);
  final used = <M4TreePlanTopic>{};
  final trees = <M4TreePlanTree>[];
  for (var i = 0; i < 3; i++) {
    final mirror = rng.nextBool();
    final nIn = 2 + rng.nextInt(2);
    final ins = (List.of(_towardSlots)..shuffle(rng)).take(nIn);
    final outs = (List.of(_clearSlots)..shuffle(rng)).take(3);
    final bs = [for (final b in [...ins, ...outs]) mirror ? b.mirrored() : b]..shuffle(rng);
    M4TreePlanTopic topic;
    if (wires[i] == M4TreePlanWire.abLt && !used.contains(M4TreePlanTopic.abCable) && rng.nextBool()) {
      topic = M4TreePlanTopic.abCable;
    } else {
      topic = pool.firstWhere((t) => !used.contains(t));
    }
    used.add(topic);
    final treeX = 150.0 + rng.nextInt(60);
    // The rack never in the plan's own order (nor the enum's).
    final rack = List.of(M4TreePlanItem.values)..shuffle(rng);
    while (_sameOrder(rack, M4TreePlanItem.values)) {
      rack.shuffle(rng);
    }
    trees.add(
      M4TreePlanTree(
        wire: wires[i],
        size: sizes[i],
        treeX: treeX,
        branches: List.unmodifiable(bs),
        topic: topic,
        walkerX: rng.nextBool() ? 60.0 + rng.nextInt(50) : 250.0 + rng.nextInt(50),
        rack: List.unmodifiable(rack),
      ),
    );
  }
  return M4TreePlanDeal(trees: trees, callAt: rng.nextInt(3));
}

bool _sameOrder(List<M4TreePlanItem> a, List<M4TreePlanItem> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

abstract final class M4TreePlanLines {
  static const title = 'কাটার আগে পরিকল্পনা';
  static const intro = 'গাছের ডাল লাইনে উঠেছে। কাটার আগে পরিকল্পনা — চলুন।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The task of each step (what the guide says and repeats when tapped).
  static const askSurvey = 'কোন কোন ডাল লাইনের কাছে? ট্যাপ করে চিহ্নিত করুন।';
  static const askDrop = 'কাটা ডাল কোথায় নামবে? নিচে জায়গাটা দেখান।';
  static const askPlan = 'প্রথম কাটের আগে পুরো পরিকল্পনা সেরে নিন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static String ask(M4TreePlanPhase p) => switch (p) {
    M4TreePlanPhase.survey => askSurvey,
    M4TreePlanPhase.drop => askDrop,
    M4TreePlanPhase.plan || M4TreePlanPhase.cut || M4TreePlanPhase.done => askPlan,
  };
  static const tasks = [askSurvey, askDrop, askPlan];

  // Labels a worker reads (buttons, the docket).
  static const sceneLabel = 'গাছ, লাইন আর রাস্তা';
  static const surveyDone = 'জরিপ শেষ';
  static const shutdown = 'শাটডাউন · পারমিট (PTW)';
  static const shutdownOn = 'পারমিট (PTW) হাতে';
  static const helper = 'নিচে সহকর্মী';
  static const ppe = 'গ্লাভস · গগলস';
  static const rope = 'দড়ি';
  static const pruner = 'ইনসুলেটেড প্রুনার';
  static const saw = "ইনসুলেটেড স'";
  static const chainsaw = 'চেইনসঅ';
  static const plain = 'সাধারণ করাত';
  static const start = 'কাটা শুরু';
  static const docket = 'ডকেট';
  static String treeBn(M4TreePlanTree t) => t.wire == M4TreePlanWire.hv11 ? '11 kV লাইনে ডাল উঠেছে' : 'LT এবি কেবিলে ডাল ঘষছে';

  // Not scored (a tap off the ground): the task again, neutral — never where.
  static const dropFar = 'মাটিতে ছুঁয়ে দেখান — কাটা ডাল কোথায় নামবে?';
  static const noTool = 'কী দিয়ে কাটবেন? টুলটা আগে বেছে নিন।';
  static const marked = 'চিহ্ন দেওয়া হয়েছে।';

  // The reasons (lesson 4.8 and its film): the right ones fit the tree's
  // topic; the wrong ones are the lesson's myths and field excuses.
  static const whyShutdown = 'কেন আগে শাটডাউন আর পারমিট (PTW) নিলেন?';
  static const whyCordon = 'কেন রাস্তা ছেড়ে গাছের নিচে ঘিরলেন?';
  static const whyToolSmall = "কেন ইনসুলেটেড প্রুনার বা স' নিলেন?";
  static const whyToolBig = 'কেন চেইনসঅ আর দড়ি নিলেন?';
  static const whyDirectional = 'কেন শুধু এই ডালগুলোতেই চিহ্ন দিলেন?';
  static const whyAb = 'এবি কেবিল তো ঢাকা — তবু কেন ছাঁটলেন?';
  static String why(M4TreePlanTree t) => switch (t.topic) {
    M4TreePlanTopic.shutdown => whyShutdown,
    M4TreePlanTopic.cordon => whyCordon,
    M4TreePlanTopic.tool => t.big ? whyToolBig : whyToolSmall,
    M4TreePlanTopic.directional => whyDirectional,
    M4TreePlanTopic.abCable => whyAb,
  };

  static const shutdownWhy = ['ডাল লাইনের খুব কাছে, তাই আগে লাইন বন্ধ চাই', 'লাইনের কাছে কাটার আগে পারমিট নিয়ে লাইন বন্ধ করি'];
  static const cordonWhy = ['কাটা ডাল যেন পথচারী বা গাড়ির ওপর না পড়ে', 'নিচে ঘেরা থাকলে ডাল পড়ার জায়গায় কেউ ঢোকে না'];
  static const toolSmallWhy = ["ছোট ডালে লম্বা ইনসুলেটেড প্রুনার বা স' চলে", 'লাইনের কাছে ইনসুলেটেড হাতল বাড়তি সুরক্ষা দেয়'];
  static const toolBigWhy = ['বড় ভারী ডালে চেইনসঅ, আর দড়িতে পতন নিয়ন্ত্রণ', 'দড়িতে বাঁধা থাকলে ভারী ডাল ঠিক দিকেই নামে'];
  static const directionalWhy = ['যে ডাল লাইনের দিকে ঝুঁকছে, শুধু সেটাই ছাঁটা হয়', 'গোটা গাছের মাথা নয়, শুধু লাইনের দিকের ডাল'];
  static const abWhy = ['ক্রমাগত ঘষায় এবি কেবিলের ইনসুলেশনও নষ্ট হয়', 'ঝড়ে ডালের আঘাতে এবি কেবিলও ক্ষতিগ্রস্ত হয়'];
  static List<String> whyRight(M4TreePlanTree t) => switch (t.topic) {
    M4TreePlanTopic.shutdown => shutdownWhy,
    M4TreePlanTopic.cordon => cordonWhy,
    M4TreePlanTopic.tool => t.big ? toolBigWhy : toolSmallWhy,
    M4TreePlanTopic.directional => directionalWhy,
    M4TreePlanTopic.abCable => abWhy,
  };

  /// Wrong reasons (the lesson's myths and field excuses).
  static const whyWrong = [
    'শুকনো ডাল তো বিদ্যুৎ টানে না, থাকলেও চলে',
    'কেবিল তো ইনসুলেটেড, ডাল ছুঁয়ে থাকলে কিছু নয়',
    'পুরো গাছের মাথা কেটে দিলেই ঝামেলা শেষ',
    'অভ্যাস আছে, এত পরিকল্পনার দরকার পড়ে না',
    'তাড়াতাড়ি সারতে হবে, নিচে ঘেরার সময় নেই',
    'সাবধানে কাটলে চালু লাইনেও কিছু হয় না',
  ];

  /// Wrong reasons that use the tree's own words (so no word appears only on
  /// the right card): field excuses and myths about the same act.
  static const shutdownWrong = ['পারমিট নিলে পরে কেউ আমাকে দোষ দিতে পারে না', 'শাটডাউন নিলে সুপারভাইজার খুশি হন, তাই নিলাম'];
  static const cordonWrong = ['নিচে ঘেরা থাকলে ডালগুলো পরে কুড়াতে সুবিধা', 'রাস্তায় ঘিরলে গাড়ি থামাতে বড় ঝামেলা হয়'];
  static const toolSmallWrong = ['ইনসুলেটেড হাতলে ধরলে চালু লাইনেও কাটা যায়', "ইনসুলেটেড প্রুনার বা স' হালকা, হাত কম ব্যথা"];
  static const toolBigWrong = ['চেইনসঅ থাকলে দড়ি বা ঘেরার দরকার পড়ে না', 'দড়ি বাঁধা থাকলে ডাল ধরে উঠতে সুবিধা হয়'];
  static const directionalWrong = ['শুধু বড় ডালগুলোই ছাঁটা হয়, ছোটগুলো নয়', 'লাইনের দিকের ডাল কাটলে কাঠ বেশি পাওয়া যায়'];
  static const abWrong = ['এবি কেবিল তো খোলা তার, তাই ছাঁটতে হয়', 'এবি কেবিলে ডাল লাগলে গ্রাহক নালিশ করেন'];
  static List<String> topicWrong(M4TreePlanTree t) => switch (t.topic) {
    M4TreePlanTopic.shutdown => shutdownWrong,
    M4TreePlanTopic.cordon => cordonWrong,
    M4TreePlanTopic.tool => t.big ? toolBigWrong : toolSmallWrong,
    M4TreePlanTopic.directional => directionalWrong,
    M4TreePlanTopic.abCable => abWrong,
  };

  /// The wrong library for [t]: its own excuses + the general myths.
  static List<String> whyWrongFor(M4TreePlanTree t) => [...topicWrong(t), ...whyWrong];

  /// One right, one wrong in the tree's own words, one general myth.
  static List<ChoiceOption> dealWhy(M4TreePlanTree t, math.Random rng) {
    final own = topicWrong(t);
    return dealChoices(whyRight(t), [own[rng.nextInt(own.length)], whyWrong[rng.nextInt(whyWrong.length)]], rng);
  }

  /// The careless coworker, before the plan: keep the line on.
  static const coworkerExit = 'হুঁ! যা খুশি করো।';
  static const coworker = CoworkerScript(
    line: 'লাইন চালু থাক! শাটডাউনের ঝামেলা কে করবে? উঠে কেটে দাও।',
    exitLine: coworkerExit,
    right: ['না, আগে শাটডাউন আর পারমিট নেব', 'না, লাইন চালু রেখে ডাল কাটব না', 'ডাল লাইনের গায়ে, আগে লাইন বন্ধ'],
    wrong: [
      'ঠিক, চালু লাইনেই কেটে দিচ্ছি',
      'আচ্ছা, শাটডাউনের দরকার নেই',
      'সাবধানে কাটলে তারে লাগবে না',
      'শুকনো ডাল, কারেন্ট আসবে না',
      'ঠিক আছে, তাড়াতাড়ি সেরে ফেলি',
    ],
    asks: ['ও বলছে লাইন চালু রেখেই কাটতে। আপনি?', 'লাইন চালু রেখে, না শাটডাউন নিয়ে?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// New lines for him (device TTS until recorded in his voice).
  static List<String> get recordLines => [coworker.line, coworker.exitLine];

  static const callHeld = 'ঠিক! চাপে পড়ে নিয়ম ভাঙবেন না।';
  static const allSet = 'ডাল দেখা, জায়গা ঘেরা, লাইন বন্ধ, ঠিক টুল — পরিকল্পনা পাকা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — জরিপ, ঘেরা, শাটডাউন, তারপর টুল।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtSurvey = 'শুধু লাইনের দিকের ডালে চিহ্ন';
  static const caughtDrop = 'রাস্তা ছেড়ে নিচে জায়গা ঘেরা';
  static const caughtShutdown = 'কাটার আগে শাটডাউন · পারমিট (PTW)';
  static const caughtTool = 'ডালের মাপে ইনসুলেটেড টুল';
  static const caughtCrew = 'একা নয় — নিচে সহকর্মী, PPE';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M4TreePlanMistakes {
  static const _dir = 'assets/game/art/m4_tree_plan';

  static const liveLine = DoMistake(
    key: '4.8/m4_tree_plan/cut-with-line-live',
    textBn: 'লাইন চালু রেখে ডাল কাটবেন না! ডাল লাইনের কাছে থাকলে আগে পারমিট নিয়ে লাইন বন্ধ করুন।',
    art: '$_dir/tp_live.svg',
    deadly: true,
    lessonPoint: 1,
  );

  /// Advanced fact 1 (directional pruning) and the film (no topping): not a
  /// lesson point, "পাঠে দেখুন" opens the lesson from its start.
  static const wrongBranch = DoMistake(
    key: '4.8/m4_tree_plan/branch-not-toward-line',
    textBn: 'এই ডাল লাইনের দিকে নয়। শুধু যে ডাল লাইনের দিকে ঝুঁকছে, সেটাই ছাঁটা হয় — গোটা গাছের মাথা গোল করে কাটা নিষিদ্ধ।',
    art: '$_dir/tp_branch.svg',
  );
  static const missedBranch = DoMistake(
    key: '4.8/m4_tree_plan/branch-missed',
    textBn: 'লাইনের গায়ে উঠে আসা একটি ডাল বাদ পড়ল। কন্ডাক্টর থেকে ডালের নিরাপদ দূরত্ব (সাধারণত 1.5 থেকে 3 মিটার) রাখতেই হবে।',
    art: '$_dir/tp_branch.svg',
    lessonPoint: 2,
  );
  static const roadDrop = DoMistake(
    key: '4.8/m4_tree_plan/drop-on-road',
    textBn: 'ডাল নামানোর জায়গা রাস্তায় রাখলেন। কাটা ডাল পথচারী বা গাড়ির ওপর পড়তে পারে — রাস্তা ছেড়ে নিচে দড়ি বা টেপে জায়গাটা ঘিরে দিন।',
    art: '$_dir/tp_drop.svg',
    lessonPoint: 1,
  );
  static const awayDrop = DoMistake(
    key: '4.8/m4_tree_plan/drop-away-from-tree',
    textBn: 'ঘেরা দিলেন গাছ থেকে দূরে — কাটা ডাল নামবে ঘেরার বাইরে, যেখানে লোক চলে। ডাল যেখানে পড়বে, গাছের নিচে সেই জায়গাটাই দড়ি বা টেপে ঘিরুন।',
    art: '$_dir/tp_drop.svg',
    lessonPoint: 1,
  );

  /// Listening to the careless coworker (playbook row 8: a slip).
  static const listened = DoMistake(
    key: '4.8/m4_tree_plan/listened-line-on',
    textBn: 'লাইন চালু রেখে ডাল কাটা যাবে না! আগে পারমিট নিয়ে লাইন বন্ধ করুন, কারও কথায় নিয়ম ভাঙবেন না।',
    art: '$_dir/tp_live.svg',
    lessonPoint: 1,
  );
  static const plainTool = DoMistake(
    key: '4.8/m4_tree_plan/plain-saw-near-line',
    textBn: "লাইনের কাছে সাধারণ করাত নিলেন। ফাইবারগ্লাসের হাতলযুক্ত ইনসুলেটেড প্রুনার বা স' নিন — এটি বাড়তি সুরক্ষা দেয়।",
    art: '$_dir/tp_tool.svg',
    lessonPoint: 1,
  );
  static const smallTool = DoMistake(
    key: '4.8/m4_tree_plan/pruner-on-thick-branch',
    textBn: "মোটা ভারী ডালে প্রুনার বা স' নিলেন। বড় ডালের জন্য চেইনসঅ — দুই হাতে ধরে, কিকব্যাক নিয়ে সজাগ থেকে।",
    art: '$_dir/tp_tool.svg',
    lessonPoint: 1,
  );
  static const bigTool = DoMistake(
    key: '4.8/m4_tree_plan/chainsaw-on-thin-branch',
    textBn: "সরু ডালে চেইনসঅ নিলেন। ছোট ডালের জন্য লম্বা ইনসুলেটেড প্রুনার বা স' — চেইনসঅ অত্যন্ত বিপজ্জনক যন্ত্র।",
    art: '$_dir/tp_tool.svg',
    lessonPoint: 1,
  );

  /// Pro tip 1 (not a lesson point).
  static const alone = DoMistake(
    key: '4.8/m4_tree_plan/working-alone',
    textBn: 'নিচে কেউ নেই — একা কাজ শুরু করলেন। ট্রি ট্রিমিং কখনো একা নয়: একজন সহকর্মী নিচে ট্র্যাফিক সামলাবেন, বিপদে সতর্ক করবেন।',
    art: '$_dir/tp_alone.svg',
  );
  static const noPpe = DoMistake(
    key: '4.8/m4_tree_plan/no-gloves-goggles',
    textBn: 'শক্ত গ্লাভস আর গগলস ছাড়াই কাজে নামলেন। এই কাজে স্ট্যান্ডার্ড PPE-র সঙ্গে শক্ত গ্লাভস আর চোখের জন্য গগলস অপরিহার্য।',
    art: '$_dir/tp_ppe.svg',
    lessonPoint: 1,
  );
  static const noRope = DoMistake(
    key: '4.8/m4_tree_plan/heavy-branch-no-rope',
    textBn: 'ভারী ডাল দড়ি ছাড়া কাটতে গেলেন। ডাল কোন দিকে পড়বে আগে ঠিক করুন — দড়ি দিয়ে বেঁধে পতন নিয়ন্ত্রণ করুন।',
    art: '$_dir/tp_rope.svg',
    lessonPoint: 2,
  );

  static List<DoMistake> get all => [liveLine, listened, wrongBranch, missedBranch, roadDrop, awayDrop, plainTool, smallTool, bigTool, alone, noPpe, noRope];
}

/// The play state (pure logic).
class M4TreePlanRun {
  M4TreePlanRun(this.deal);
  final M4TreePlanDeal deal;
  int index = 0;
  M4TreePlanPhase phase = M4TreePlanPhase.survey;
  final Set<int> marked = {};
  final Set<int> wrongTapped = {};
  double? dropX;
  final Set<M4TreePlanKit> kit = {};
  M4TreePlanTool tool = M4TreePlanTool.none;
  int slips = 0;
  int treeSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.trees.length;
  bool get ended => done || deadly != null;
  M4TreePlanTree get tree => deal.trees[index.clamp(0, deal.trees.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get clean => treeSlips == 0;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    treeSlips++;
    return m;
  }

  /// Survey: tap branch [i]. A branch well clear of the line is a slip (once
  /// per branch); a second tap on a marked one does nothing.
  DoMistake? tap(int i) {
    if (ended || phase != M4TreePlanPhase.survey || marked.contains(i)) return null;
    if (!tree.branches[i].toward) {
      if (!wrongTapped.add(i)) return null;
      return _slip(M4TreePlanMistakes.wrongBranch);
    }
    marked.add(i);
    return null;
  }

  /// "জরিপ শেষ": a branch in the line left unmarked is a slip (the guide
  /// marks it).
  DoMistake? surveyDone() {
    if (ended || phase != M4TreePlanPhase.survey) return null;
    phase = M4TreePlanPhase.drop;
    final missed = tree.toward.where((i) => !marked.contains(i)).toList();
    marked.addAll(missed);
    if (missed.isNotEmpty) return _slip(M4TreePlanMistakes.missedBranch);
    if (wrongTapped.isEmpty) _tag(M4TreePlanLines.caughtSurvey);
    return null;
  }

  /// The drop zone at design x [x]: off the ground = not scored, stay; the
  /// road or the verge away from the tree = a slip (the guide moves it under
  /// the tree).
  DoMistake? drop(M4TreePlanDrop d, double x) {
    if (ended || phase != M4TreePlanPhase.drop || d == M4TreePlanDrop.far) return null;
    phase = M4TreePlanPhase.plan;
    if (d == M4TreePlanDrop.road || d == M4TreePlanDrop.away) {
      dropX = tree.treeX;
      return _slip(d == M4TreePlanDrop.road ? M4TreePlanMistakes.roadDrop : M4TreePlanMistakes.awayDrop);
    }
    dropX = x.clamp(tree.treeX - 60, tree.treeX + 60);
    _tag(M4TreePlanLines.caughtDrop);
    return null;
  }

  void wear(M4TreePlanKit k) {
    if (ended || phase != M4TreePlanPhase.plan) return;
    if (!kit.add(k)) kit.remove(k);
  }

  /// Agreed with the careless coworker to keep the line on: a slip. The
  /// শাটডাউন stays on offer (cutting without it is the deadly).
  DoMistake? listen() {
    if (ended) return null;
    return _slip(M4TreePlanMistakes.listened);
  }

  void pick(M4TreePlanTool t) {
    if (ended || phase != M4TreePlanPhase.plan) return;
    tool = tool == t ? M4TreePlanTool.none : t;
  }

  M4TreePlanTool get rightTool => tree.big ? M4TreePlanTool.chainsaw : M4TreePlanTool.pruner;

  /// "কাটা শুরু": (started, the mistake). No tool = not started, not scored.
  /// The line live is deadly; otherwise the most serious gap is the slip, the
  /// guide puts the rest right and the cut goes on.
  (bool, DoMistake?) start() {
    if (ended || phase != M4TreePlanPhase.plan) return (false, null);
    if (tool == M4TreePlanTool.none) return (false, null);
    if (!kit.contains(M4TreePlanKit.shutdown)) {
      phase = M4TreePlanPhase.cut;
      return (true, deadly = M4TreePlanMistakes.liveLine);
    }
    final t = tree;
    final thin = tool == M4TreePlanTool.pruner || tool == M4TreePlanTool.saw;
    DoMistake? m;
    if (tool == M4TreePlanTool.plain) {
      m = _slip(M4TreePlanMistakes.plainTool);
    } else if (t.big && thin) {
      m = _slip(M4TreePlanMistakes.smallTool);
    } else if (!t.big && tool == M4TreePlanTool.chainsaw) {
      m = _slip(M4TreePlanMistakes.bigTool);
    } else if (!kit.contains(M4TreePlanKit.helper)) {
      m = _slip(M4TreePlanMistakes.alone);
    } else if (!kit.contains(M4TreePlanKit.ppe)) {
      m = _slip(M4TreePlanMistakes.noPpe);
    } else if (t.big && !kit.contains(M4TreePlanKit.rope)) {
      m = _slip(M4TreePlanMistakes.noRope);
    }
    _tag(M4TreePlanLines.caughtShutdown);
    if (m == null) {
      _tag(M4TreePlanLines.caughtTool);
      _tag(M4TreePlanLines.caughtCrew);
    }
    kit.addAll([M4TreePlanKit.helper, M4TreePlanKit.ppe, if (t.big) M4TreePlanKit.rope]);
    if (m != null && (tool == M4TreePlanTool.plain || m == M4TreePlanMistakes.smallTool || m == M4TreePlanMistakes.bigTool)) tool = rightTool;
    phase = M4TreePlanPhase.cut;
    return (true, m);
  }

  void cutDone() {
    if (!ended && phase == M4TreePlanPhase.cut) phase = M4TreePlanPhase.done;
  }

  void next() {
    index++;
    phase = M4TreePlanPhase.survey;
    marked.clear();
    wrongTapped.clear();
    dropX = null;
    kit.clear();
    tool = M4TreePlanTool.none;
    treeSlips = 0;
  }
}

/// Classify a ground tap at design ([x], [y]) for [tree].
M4TreePlanDrop m4TreePlanDropOf(M4TreePlanGeo geo, M4TreePlanTree tree, double x, double y) {
  if (y >= geo.roadTop - 2 && y <= geo.roadBottom) return M4TreePlanDrop.road;
  if (y >= geo.groundY - 6 && y < geo.roadTop - 2) return (x - tree.treeX).abs() <= 90 ? M4TreePlanDrop.zone : M4TreePlanDrop.away;
  return M4TreePlanDrop.far;
}

/// The quick bonus (~85 % of a thorough play, rounded to 10 s). A tree:
/// survey 3 taps × 1500 + done 1500 + drop 2000 + plan 5 taps × 1500 + start
/// 1500 + the cut 2500 + reason 8200 ≈ 27700 × 3 = 83100, + the coworker once
/// ≈ 9000 → 92100; 85 % ≈ 78300 → 80 s.
const m4TreePlanQuickMs = 80000;

@immutable
class M4TreePlanPack {
  const M4TreePlanPack({required this.id, required this.titleBn, this.quickMs = m4TreePlanQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4TreePlanPack> m4TreePlanPacks = {'do_4_8_a': M4TreePlanPack(id: 'do_4_8_a', titleBn: M4TreePlanLines.title)};

/// The trainee's box standing with his centre at [x].
Rect m4TreePlanManBox(M4TreePlanGeo geo, double x, {double? feetY}) {
  final h = geo.man;
  final y = feetY ?? geo.groundY + 4;
  return Rect.fromLTWH(x - h / 4, y - h, h / 2, h);
}

// ============================================================================
// Page
// ============================================================================

class M4TreePlanPage extends StatefulWidget {
  const M4TreePlanPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4TreePlanPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4TreePlanPage> createState() => _M4TreePlanPageState();
}

class _M4TreePlanPageState extends State<M4TreePlanPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TpRunPage(
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

class _TpRunPage extends ConsumerStatefulWidget {
  const _TpRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4TreePlanPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TpRunPage> createState() => _TpRunPageState();
}

class _TpRunPageState extends ConsumerState<_TpRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4TreePlanRun _run = M4TreePlanRun(m4TreePlanDeal(widget.rng));
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

  /// The cut: the branches coming down (a one-shot), then lying.
  var _cutting = false;
  int _cutN = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset? _deathAt;
  final _nudge = TaskNudge();
  int _nudgeN = 0;
  M4TreePlanGeo _geoNow = M4TreePlanGeo.forScene(780, 0);
  final _hints = IdleHintController();
  final _rackKeys = {for (final i in M4TreePlanItem.values) i: GlobalKey()};
  final _surveyKey = GlobalKey();
  final _startKey = GlobalKey();

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M4TreePlanTree get _tree => _run.tree;

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

  /// The scene takes a move now: never in a right move's praise window
  /// (`tableBusy`), a card, a deck, the coworker or the death freeze.
  bool get _canPlay => !_intro && !_busy && !_ended && !_freeze && _card == null && !reasonOpen && !coworkerOpen && !tableBusy;

  void _start() {
    _clock.start();
    _startTree();
  }

  void _startTree() {
    setState(() {
      _cutting = false;
      _wake++;
    });
    if (_run.index == _run.deal.callAt) scheduleCoworker();
    unawaited(_sayChain([M4TreePlanLines.askSurvey]));
  }

  void _askStep() => unawaited(_sayChain([M4TreePlanLines.ask(_run.phase)]));

  Offset _toGlobal(Offset design) {
    final size = MediaQuery.sizeOf(context);
    return design * (size.width / 360);
  }

  // --- 1. the survey + 2. the drop zone: taps on the scene ----------------------
  Future<void> _tapScene(Offset p) async {
    if (!_canPlay) return;
    final geo = _geoNow;
    final t = _tree;
    switch (_run.phase) {
      case M4TreePlanPhase.survey:
        final i = geo.branchAt(p, t.branches, t.treeX, t.wire);
        if (i == null) {
          _hints.missTap();
          return;
        }
        if (_run.marked.contains(i)) {
          HapticFeedback.selectionClick();
          return;
        }
        final m = _run.tap(i);
        HapticFeedback.selectionClick();
        if (m != null) {
          unawaited(_levelDelta(-10, _toGlobal(p), mood: GuideMood.warn));
          await _slip(m);
          return;
        }
        if (!_run.marked.contains(i)) return;
        _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
        setState(() => _wake++);
      case M4TreePlanPhase.drop:
        final d = m4TreePlanDropOf(geo, t, p.dx, p.dy);
        HapticFeedback.selectionClick();
        _cue('sounds/intro/tick.ogg', volume: 0.45);
        if (d == M4TreePlanDrop.far) {
          // Off the ground: a miss, not a choice — the task again, neutral.
          _hints.missTap();
          unawaited(_sayChain([M4TreePlanLines.dropFar]));
          return;
        }
        final m = _run.drop(d, p.dx);
        setState(() => _wake++);
        if (m != null) {
          unawaited(_levelDelta(-10, _toGlobal(p), mood: GuideMood.warn));
          await _slip(m);
          return;
        }
        _cue('sounds/learn/tag_slap.ogg', volume: 0.55);
        _askStep();
      case M4TreePlanPhase.plan:
        _hints.missTap();
      case M4TreePlanPhase.cut || M4TreePlanPhase.done:
        break;
    }
  }

  Future<void> _surveyDone(Offset origin) async {
    if (!_canPlay || _run.phase != M4TreePlanPhase.survey) return;
    _hush();
    final m = _run.surveyDone();
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

  // --- 3. the plan -----------------------------------------------------------------
  void _wear(M4TreePlanKit k) {
    if (!_canPlay || _run.phase != M4TreePlanPhase.plan) return;
    // Taking the শাটডাউন ends his moment: he has his say first.
    if (k == M4TreePlanKit.shutdown && !_run.kit.contains(k) && holdForCoworker()) return;
    HapticFeedback.selectionClick();
    _cue(k == M4TreePlanKit.shutdown ? 'sounds/quiz_select.ogg' : 'sounds/learn/tag_slap.ogg', volume: 0.45);
    setState(() {
      _run.wear(k);
      _wake++;
    });
  }

  void _pick(M4TreePlanTool t) {
    if (!_canPlay || _run.phase != M4TreePlanPhase.plan) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    setState(() {
      _run.pick(t);
      _wake++;
    });
  }

  Future<void> _go(Offset origin) async {
    if (!_canPlay || _run.phase != M4TreePlanPhase.plan) return;
    // The decisive control of his tree: he comes before the cut, however fast.
    if (holdForCoworker()) return;
    final (started, m) = _run.start();
    if (!started) {
      HapticFeedback.selectionClick();
      unawaited(_sayChain([M4TreePlanLines.noTool]));
      return;
    }
    _hush();
    final t = _tree;
    if (m != null && m.deadly) {
      final b = t.branches[t.toward.first];
      final (_, _, tip) = _geoNow.branchOf(b, t.treeX, t.wire);
      await _deadly(m, at: tip);
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
    await _cut();
  }

  /// The branches come down into the cordon; then the ◆ and "কেন …?".
  Future<void> _cut() async {
    _busy = true;
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() {
      _cutting = true;
      _cutN++;
      _wake++;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 1500));
    if (!mounted || _ended) return;
    _busy = false;
    setState(() => _run.cutDone());
    _treeDone();
  }

  void _treeDone() {
    final t = _tree;
    final idx = _run.index;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(
      askReason(
        deal: () => M4TreePlanLines.dealWhy(t, widget.rng),
        question: M4TreePlanLines.why(t),
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
    _startTree();
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
  CoworkerScript get coworkerScript => M4TreePlanLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt) return null;
    final ph = _run.phase;
    // His push ("keep the line on") makes no sense once the শাটডাউন is taken.
    if (ph.index > M4TreePlanPhase.plan.index || _run.kit.contains(M4TreePlanKit.shutdown)) return null;
    if (_intro || _busy || _freeze || _card != null || reasonOpen || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listening = a slip (playbook row 8); the শাটডাউন stays on offer.
      final m = _run.listen();
      if (m == null) return;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M4TreePlanLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4TreePlanLines.callHeld, M4TreePlanLines.ask(_run.phase)]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
        ? M4TreePlanLines.tapWhy[_nudgeN++ % M4TreePlanLines.tapWhy.length]
        : _nudge.next(M4TreePlanLines.ask(_run.phase));
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
    final speak = await SpokenOnce.first('m4tp/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The stretch freezes grey; the flash at the branch on the live wire in
  /// colour; then near-miss or death.
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
    final speak = await SpokenOnce.first('m4tp/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4TreePlanLines.deadlyWord : M4TreePlanLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        // The guide put it right; the tree goes on.
        if (_run.phase == M4TreePlanPhase.cut) {
          unawaited(_cut());
        } else {
          _askStep();
        }
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        if (_popped) return;
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
      !_run.passed ? M4TreePlanLines.fail : (_quickBonus ? M4TreePlanLines.quick : M4TreePlanLines.allSet),
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
    if (_run.phase == M4TreePlanPhase.survey || _run.phase == M4TreePlanPhase.drop) return LinemanMode.point;
    if (_cutting) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M4TreePlanGeo.forScene(m.height, m.inset);
    final t = _tree;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final kit = _run.kit;
    final down = _cutting || _run.phase == M4TreePlanPhase.done;
    final cut = t.toward;
    // He stands on the verge beside the tree, on the side with more room.
    final manX = t.treeX > 180 ? t.treeX - 84 : t.treeX + 84;
    final mb = m4TreePlanManBox(geo, manX);
    final flip = t.treeX < manX;
    final helperX = (t.treeX > 180 ? t.treeX - 140 : t.treeX + 140).clamp(40.0, 320.0);
    final hb = m4TreePlanManBox(geo, helperX, feetY: geo.roadTop + 4);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('stretch'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M4TreePlanWorldPainter(
                      geo: geo,
                      wire: t.wire,
                      walkerX: t.walkerX,
                      cordonX: _run.dropX,
                      earthed: kit.contains(M4TreePlanKit.shutdown),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                key: ValueKey('tree-${_run.index}'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M4TreePlanTreePainter(
                      geo: geo,
                      wire: t.wire,
                      treeX: t.treeX,
                      branches: t.branches,
                      big: t.big,
                      marked: Set.of(_run.marked),
                      gone: down ? cut.toSet() : const {},
                    ),
                  ),
                ),
              ),
              if (down && _run.dropX != null)
                Positioned.fill(
                  key: ValueKey('fall-$_cutN'),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 1100),
                      builder: (_, v, _) => CustomPaint(
                        painter: M4TreePlanFallPainter(
                          geo: geo,
                          wire: t.wire,
                          treeX: t.treeX,
                          branches: t.branches,
                          cut: cut,
                          dropX: _run.dropX!,
                          big: t.big,
                          v: v,
                        ),
                      ),
                    ),
                  ),
                ),
              if (kit.contains(M4TreePlanKit.helper))
                Positioned(
                  key: const ValueKey('helper'),
                  left: hb.left,
                  top: hb.top,
                  width: hb.width,
                  height: hb.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: LinemanFigure(
                          look: const LinemanLook(helmet: Color(0xFFF5F5F5), shirt: Color(0xFF2E7D32), vest: Color(0xFFFF851B), pants: Color(0xFF26303D), gloves: true),
                          mode: LinemanMode.idle,
                          wake: _wake,
                          quiet: quiet,
                        ),
                      ),
                      Positioned(
                        left: hb.width * 0.62,
                        top: hb.height * 0.06,
                        width: hb.width * 0.5,
                        height: hb.height * 0.5,
                        child: const IgnorePointer(child: CustomPaint(painter: M4TreePlanFlagPainter())),
                      ),
                    ],
                  ),
                ),
              Positioned(
                key: const ValueKey('trainee'),
                left: mb.left,
                top: mb.top,
                width: mb.width,
                height: mb.height,
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
                            gloves: kit.contains(M4TreePlanKit.ppe),
                          ),
                          mode: _mode,
                          wake: _wake,
                          quiet: quiet,
                        ),
                      ),
                    ),
                    if (kit.contains(M4TreePlanKit.ppe))
                      Positioned(
                        key: const ValueKey('goggles'),
                        left: flip ? mb.width * 0.3 : mb.width * 0.36,
                        top: mb.height * 0.1,
                        width: mb.width * 0.34,
                        height: mb.height * 0.08,
                        child: const IgnorePointer(child: CustomPaint(painter: M4TreePlanGogglesPainter())),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Tap the branches, the ground.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4TreePlanLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => unawaited(_tapScene(d.localPosition))),
        ),
      ),
      // The flash, in colour over the grey stretch.
      if (_freeze && _deathAt != null)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(
                painter: M4TreePlanArcPainter(at: _deathAt!, v: 0.25 + 0.6 * v),
              ),
            ),
          ),
        ),
      // The next tree: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('tree-fade-${_run.index}'),
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

  Widget _planTools() {
    final k = _run.kit;
    Widget b(M4TreePlanItem item) {
      final (String label, IconData icon, bool on, VoidCallback tap) = switch (item) {
        M4TreePlanItem.shutdown => (
          k.contains(M4TreePlanKit.shutdown) ? M4TreePlanLines.shutdownOn : M4TreePlanLines.shutdown,
          Icons.power_off_rounded,
          k.contains(M4TreePlanKit.shutdown),
          () => _wear(M4TreePlanKit.shutdown),
        ),
        M4TreePlanItem.helper => (M4TreePlanLines.helper, Icons.traffic_rounded, k.contains(M4TreePlanKit.helper), () => _wear(M4TreePlanKit.helper)),
        M4TreePlanItem.ppe => (M4TreePlanLines.ppe, Icons.back_hand_rounded, k.contains(M4TreePlanKit.ppe), () => _wear(M4TreePlanKit.ppe)),
        M4TreePlanItem.rope => (M4TreePlanLines.rope, Icons.gesture_rounded, k.contains(M4TreePlanKit.rope), () => _wear(M4TreePlanKit.rope)),
        M4TreePlanItem.pruner => (M4TreePlanLines.pruner, Icons.content_cut_rounded, _run.tool == M4TreePlanTool.pruner, () => _pick(M4TreePlanTool.pruner)),
        M4TreePlanItem.saw => (M4TreePlanLines.saw, Icons.carpenter_rounded, _run.tool == M4TreePlanTool.saw, () => _pick(M4TreePlanTool.saw)),
        M4TreePlanItem.chainsaw => (M4TreePlanLines.chainsaw, Icons.handyman_rounded, _run.tool == M4TreePlanTool.chainsaw, () => _pick(M4TreePlanTool.chainsaw)),
        M4TreePlanItem.plain => (M4TreePlanLines.plain, Icons.hardware_rounded, _run.tool == M4TreePlanTool.plain, () => _pick(M4TreePlanTool.plain)),
      };
      return _ToolButton(key: _rackKeys[item], icon: icon, label: label, on: on, enabled: _canPlay, onTap: tap);
    }

    // The rack in the tree's dealt order (never the plan's order).
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      runSpacing: 6,
      children: [for (final item in _tree.rack) b(item)],
    );
  }

  // --- gesture hints (how to touch, never what) ----------------------------------
  /// The level waits for a move on the scene or the rack.
  bool get _hintWaiting => _canPlay && !_cutting && !coworkerOnScreen && _mark == null && !struckOut && _run.phase.index <= M4TreePlanPhase.plan.index;

  Object get _hintKey => ('tp', _run.index, _run.phase, strikes);

  /// Survey: a sweep over every branch (marked or not, in the line or not —
  /// the set never narrows to the ones left) and then the "জরিপ শেষ" button;
  /// the drop: over the verge and the road alike; the plan: over every rack
  /// button and "কাটা শুরু". Never a tap on one answer.
  HintSpec? _hint() {
    final t = _tree;
    final g = _geoNow;
    switch (_run.phase) {
      case M4TreePlanPhase.survey:
        final pts = <Offset>[for (var i = 0; i < t.branches.length; i++) _branchPoint(g, t, i)]..sort((a, b) => a.dx.compareTo(b.dx));
        final done = HintSpec.globalRectOf(_surveyKey);
        return HintSpec.sweep([
          for (final p in pts) Rect.fromCenter(center: _sceneToGlobal(p), width: 30, height: 30),
          ?done,
        ]);
      case M4TreePlanPhase.drop:
        final verge = g.groundY + 30;
        final road = (g.roadTop + g.roadBottom) / 2;
        return HintSpec.sweep([
          for (final (x, y) in [(60.0, verge), (120.0, road), (180.0, verge), (240.0, road), (300.0, verge)]) Rect.fromCenter(center: Offset(x, y), width: 40, height: 30),
        ], space: HintSpace.scene);
      case M4TreePlanPhase.plan:
        return HintSpec.sweepOver([for (final i in t.rack) _rackKeys[i]!, _startKey]);
      case M4TreePlanPhase.cut || M4TreePlanPhase.done:
        return null;
    }
  }

  /// A scene point (design px) on screen — [FullSceneFrame]'s cover fit of the
  /// full-screen body.
  Offset _sceneToGlobal(Offset p) {
    final size = MediaQuery.sizeOf(context);
    final w = math.max(1.0, size.width);
    final sh = (360 * size.height / w).clamp(560.0, 900.0);
    final scale = math.max(size.width / 360, size.height / sh);
    return Offset((size.width - 360 * scale) / 2 + p.dx * scale, (size.height - sh * scale) / 2 + p.dy * scale);
  }

  static Offset _branchPoint(M4TreePlanGeo g, M4TreePlanTree t, int i) {
    final (a, c, tip) = g.branchOf(t.branches[i], t.treeX, t.wire);
    const s = 0.7;
    return a * ((1 - s) * (1 - s)) + c * (2 * s * (1 - s)) + tip * (s * s);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_busy;
    final phase = _run.phase;
    final t = _tree;
    final planUp = handsOn && phase == M4TreePlanPhase.plan;
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
              labels: M4TreePlanLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: playing && !deckUp && _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(
                    child: _DocketChip(text: M4TreePlanLines.treeBn(t), ptw: _run.kit.contains(M4TreePlanKit.shutdown)),
                  ),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && phase == M4TreePlanPhase.survey)
                Positioned(
                  key: const ValueKey('hud-survey'),
                  left: 80,
                  right: 80,
                  bottom: pad.bottom + 14,
                  child: DoBigButton(key: _surveyKey, label: M4TreePlanLines.surveyDone, filled: true, onTapUp: (d) => unawaited(_surveyDone(d.globalPosition))),
                ),
              if (planUp)
                Positioned(
                  key: const ValueKey('hud-plan'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _planTools(),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: DoBigButton(key: _startKey, label: M4TreePlanLines.start, filled: true, onTapUp: (d) => unawaited(_go(d.globalPosition))),
                      ),
                    ],
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
                  bottom: pad.bottom + (deckUp ? 236 : (planUp ? 248 : 72)),
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
                  line: M4TreePlanLines.intro,
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
  const _DocketChip({required this.text, required this.ptw});
  final String text;
  final bool ptw;

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
            M4TreePlanLines.docket,
            style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A)),
          ),
          Text(
            text,
            style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416)),
          ),
          if (ptw)
            Text(
              M4TreePlanLines.shutdownOn,
              style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF1F6B3A)),
            ),
        ],
      ),
    );
  }
}

/// A plan button: a round icon with its name under it; lit once chosen.
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
          width: 86,
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
