import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'm8_trim_not_fell_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_trim_not_fell_world.dart' show M8Branch, M8BranchKind, M8Piece, M8SeatHit, M8SeatKind, M8TreeDeal, M8TreeKind, M8TrimGeo, m8DealTree, m8HasOwner, m8RowY;

// Lesson 8.9 "পরিবেশগত নিয়মাবলী: রাজ্যের দৃষ্টিকোণ", কাজ 1 "ছাঁটা, কাটা নয়"
// (pack do_8_9_a, rung 8.9/do/0, engineType m8_trim_not_fell). A village lane
// before the monsoon; the 11 kV line is dead and earthed (the earth set is
// drawn on the near pole, the docket on the van; nothing live is offered, no
// shutdown or earth beat is scored here). The trainee works from the ground
// with a long pole pruner past two trees of four kinds:
//
//  A tree with an owner (yard mango, coconut): he stands at his gate in a
//    silent caption bubble; the guide asks "কী বলবেন?" and a 3-card deck
//    follows. The right card (the danger, said kindly) pays ◆ and its reason; a
//    quarrelling or threatening card = a slip (the card stays, dimmed).
//  The work: drag the pruner head (the pole pivots from the trainee's hands, a
//    slight sway, so the head moves in an arc). Let go over a branch or the
//    trunk and the hook seats with a clack (lift it off and move it freely). Then
//    swipe down on the rope to pull: the blade bites and the piece falls on the
//    tarp. No preview of what will fall. Judged on the pull:
//      an endangering branch cut between the line's path and the nest/trunk =
//      right (◆ → "কেন …?"); wood left in the line's path = a slip (the stub can
//      be cut again); cut on the trunk side of a nest = a slip (the nest falls);
//      a harmless branch = a slip; the hook on the trunk and pulled = a slip (the
//      trunk never falls).
//  "ছাঁটা শেষ" is always live; pressed with an endangering branch left = a slip,
//    then the next tree. After the second tree the pass panel.
//
// No deadly mistake (M8-1: lesson 8.9 has none; all slips; the gate's C2 is the
// only live cut and is not here). Three slips strike out. The coworker, once a
// play on tree 1 or 2 after the first or second hook-seat: the lesson's myth 2
// word for word with a chainsaw against the trunk; listening = a slip (the
// chainsaw bites, then the permission card). The rope pull waits for him.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the full
// scene (m8_trim_not_fell_world.dart), corner guide, ReasonTable (the "কেন?"
// cards at once), CoworkerMoment, gesture hands for every waiting state (how,
// never what), MistakeCard, DoStrikeOut, the pass panel with stars. Idle =
// zero frames: every clock (the piece falling, the camera walk) stops by
// itself; the pole follows the finger through a notifier, not a rebuild.

// ============================================================================
// Content
// ============================================================================

/// What a reason asks about.
enum M8TrimWhy { only, nest, fell, monsoon, consumer }

/// What a pull did.
enum M8PullKind { none, right, stub, nestFall, needless, trunk }

abstract final class M8TrimLines {
  static const title = 'ছাঁটা, কাটা নয়';

  // DRAFT wording — owner (M6-12): every guide line below is new text unless noted.
  static const intro = 'বর্ষার আগে লাইনের রাস্তা সাফ — শুধু বিপদের ডাল ছাঁটুন।';
  static const askOwner = 'গ্রাহক রেগে আছেন — কী বলবেন?';
  static const askWork = 'কোন ডাল, কোথায় কাটবেন?';
  static const tasks = [askOwner, askWork];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // On screen (a screen reader only; no text in the scene but the worker's labels).
  static const sceneLabel = 'গাছ আর লাইনের রাস্তা';
  static const done = 'ছাঁটা শেষ';
  static const stages = ['প্রথম গাছ', 'দ্বিতীয় গাছ'];

  /// The owner's caption (silent: a drawn figure with a bubble, M8-10; never voiced).
  static const ownerCaptions = <M8TreeKind, List<String>>{
    M8TreeKind.mango: ['আমার আমগাছ! ওতে হাত দেবেন না।', 'এই আমগাছ আমি নিজের হাতে পুঁতেছি।'],
    M8TreeKind.coconut: ['আমার নারকেল গাছ কাটবেন না!', 'এই গাছের নারকেলেই তো সংসার চলে।'],
  };

  // The consumer deck (a decision deck: a wrong card = a slip, M8-8).
  static const consumerRight = [
    'দাদা, ডাল তারে ঠেকলে কারেন্ট যাবে, গাছে আগুনও লাগতে পারে।',
    'দাদা, ঝড়ে ডাল তারে পড়লে তার ছিঁড়বে, আগুনও লাগতে পারে।',
    'দাদা, শুধু বিপদের ডালটুকু ছাঁটব, গাছটা যেমন আছে থাকবে।',
  ];
  static const consumerWrong = [
    'সরকারি কাজ হচ্ছে, আপনি সরে দাঁড়ান, কথা বাড়াবেন না!',
    'আমাদের কিছু বলার নেই, ডাল আজ কাটতেই হবে, দাদা।',
    'বেশি কথা বললে পুলিশ ডাকব, আমাদের কাজে বাধা দেবেন না।',
    'আপনার গাছ তারে ঠেকেছে, এখন সরে না দাঁড়ালে মামলা হবে।',
    'এটা সরকারি লাইন, আমরা কাটবই, বাধা দিলে দেখে নেব।',
  ];

  // The reasons. The right ones fit what was done (lesson 8.9 points, pro tip
  // 1); the wrong ones are the lesson's myths and field excuses. DRAFT wording — owner.
  static const whyQ = <M8TrimWhy, String>{
    M8TrimWhy.only: 'কেন শুধু এই ডালটা ছাঁটলেন?',
    M8TrimWhy.nest: 'কেন বাসার বাইরের দিকে কাটলেন?',
    M8TrimWhy.fell: 'কেন পুরো গাছটা কাটলেন না?',
    M8TrimWhy.monsoon: 'কেন বর্ষার আগেই এই কাজ?',
    M8TrimWhy.consumer: 'কেন গ্রাহককে এভাবে বললেন?',
  };
  static const whyRight = <M8TrimWhy, List<String>>{
    M8TrimWhy.only: ['এই ডালই লাইনের বিপদ ঘটাচ্ছে, তাই শুধু এটাই ছাঁটা।', 'নিয়মে শুধু লাইনের বিপদ ঘটানো ডালই ছাঁটতে পারি।'],
    M8TrimWhy.nest: ['পাখির বাসা নষ্ট না করে বিপদের ডালটুকু ছাঁটা।', 'বাসার বাইরের দিকে কাটলে পাখির বাসা বেঁচে যায়।'],
    M8TrimWhy.fell: ['পুরো গাছ কাটতে লিখিত অনুমতি লাগে, আমরা শুধু ছাঁটি।', 'পুরো গাছ কাটতে ফরেস্ট বা পঞ্চায়েতের অনুমতি লাগে।'],
    M8TrimWhy.monsoon: ['ঝড়ে ডাল পড়ে তার ছেঁড়া বা আগুন লাগা এড়াতে।', 'ঝড়ের আগে ডাল সরালে তার ছেঁড়ে না, আগুন লাগে না।'],
    M8TrimWhy.consumer: ['ঝগড়া নয়, সচেতনতাই সমাধান — বিপদটা বুঝিয়ে বলা।', 'বিপদটা বুঝিয়ে বললে গ্রাহক নিজেই রাজি হয়ে যান।'],
  };
  static const myths = [
    'বেশি কাটলে আবার আসতে হবে না, তাই বেশিটা কাটলাম।',
    'সরকারি লাইনে গাছ থাকলে কারও অনুমতি লাগে না।',
    'পাখির বাসা তো পাখি আবার নতুন করে বানিয়ে নেবে।',
    'বর্ষায় আমাদের কাজ কম থাকে, তাই এখন সময় পাই।',
    'গ্রাহক রাগ করলেও কাজটা তো আমাদেরই করতে হবে।',
    'ডাল না ছেঁটে গোড়া থেকে কাটলে ঝামেলা একেবারে শেষ।',
    'পুরো গাছ নামিয়ে দিলে আর কোনোদিন তারে ঠেকবে না।',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play): the lesson's myth 2 word for word
  // (M8-14). DRAFT wording — owner; the push and the two sides need recording
  // (tool/rival_clip.py). His exit line is recorded already.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'সরকারি লাইনের ওপর গাছ থাকলে সেটা কাটার জন্য কারোর পারমিশন লাগে না।',
    exitLine: coworkerExit,
    right: [
      'না, শুধু বিপদের ডাল — পুরো গাছে লিখিত অনুমতি লাগে।',
      'আমরা ছাঁটতে পারি, পুরো গাছ কাটার অধিকার নেই।',
      'না, ফরেস্ট বা পঞ্চায়েতের লিখিত অনুমতি ছাড়া কাটব না।',
    ],
    wrong: [
      'ঠিক, সরকারি লাইনের গাছ — গোড়া থেকেই কেটে দাও।',
      'পারমিশন লাগবে না, দেরি না করে পুরোটাই নামাও।',
      'ঠিক, ঝড়ের আগে পুরো গাছটাই সাফ করে দিই।',
      'ঠিক, লাইনের ওপর গাছ থাকলে সবটাই কাটা যায়।',
      'ঠিক, ডাল ছেঁটে কী হবে, গাছটাই নামিয়ে ফেলি।',
    ],
    asks: ['কী করবেন?', 'ও বলছে পুরো গাছ কেটে ফেলতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! পুরো গাছ কাটতে লিখিত অনুমতি লাগে — আমরা শুধু ডাল ছাঁটি।';

  static const allSet = 'গাছ বেঁচে গেল, লাইনও সাফ — শুধু বিপদের ডাল ছাঁটা হয়েছে। দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — শুধু বিপদের ডাল ছাঁটুন, লাইনের পথ সাফ রাখুন, পুরো গাছ নয়।';

  // "আজ যা ধরলেন" (on screen).
  static const caughtCut = 'শুধু বিপদের ডালই ছাঁটলেন';
  static const caughtNest = 'পাখির বাসা বাঁচিয়ে ডাল ছাঁটলেন';
  static const caughtOwner = 'গ্রাহককে বুঝিয়ে বলেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new spoken guide line (DRAFT wording — owner; to be recorded): the
  /// guide's lines, the why-questions and the texts of the mistakes (read aloud
  /// the first time).
  static const newGuideLines = [
    intro,
    askOwner,
    askWork,
    'কেন শুধু এই ডালটা ছাঁটলেন?',
    'কেন বাসার বাইরের দিকে কাটলেন?',
    'কেন পুরো গাছটা কাটলেন না?',
    'কেন বর্ষার আগেই এই কাজ?',
    'কেন গ্রাহককে এভাবে বললেন?',
    callHeld,
    allSet,
    quick,
    fail,
    'ও বলছে পুরো গাছ কেটে ফেলতে। কী করবেন?',
    M8TrimMistakes.needlessBn,
    M8TrimMistakes.stubBn,
    M8TrimMistakes.nestFallBn,
    M8TrimMistakes.trunkBn,
    M8TrimMistakes.leftOverBn,
    M8TrimMistakes.listenSawBn,
    M8TrimMistakes.quarrelBn,
  ];

  /// The coworker's push and the lines he is answered with are spoken by him
  /// (DRAFT wording — owner; to be recorded in his voice). His exit line is
  /// recorded already.
  static const newRivalLines = [
    'সরকারি লাইনের ওপর গাছ থাকলে সেটা কাটার জন্য কারোর পারমিশন লাগে না।',
  ];

  /// Every line the page speaks (the guide's, his, the reasons' questions, the
  /// mistake texts).
  static List<String> get spokenLines => [
        ...newGuideLines,
        ...tapWhy,
        ...coworker.asks,
        ...newRivalLines,
        coworkerExit,
      ];
}

abstract final class M8TrimMistakes {
  static const _dir = 'assets/game/art/m8_trim_not_fell';

  // Lesson 8.9 points (0-based): 0 cut vs trim (only the danger, never the whole
  // tree; permission; nests), 1 RoW (clear the line's path before the monsoon).
  // All slips (M8-1). DRAFT wording — owner (read aloud the first time).
  static const needlessBn = 'শুধু যে ডাল লাইনের বিপদ ঘটাচ্ছে সেটাই ছাঁটা যায়। এই ডাল লাইনের কোনো বিপদ ঘটাচ্ছিল না।';
  static const needless = DoMistake(
    key: '8.9/m8_trim_not_fell/needless',
    textBn: needlessBn,
    art: '$_dir/needless.svg',
    lessonPoint: 0,
  );
  static const stubBn = 'ডাল এখনও লাইনের পথে — লাইনের নিচের জায়গা সাফ রাখতে হয়। গোড়ার দিকে আরেকবার ছাঁটুন।';
  static const stub = DoMistake(
    key: '8.9/m8_trim_not_fell/stub',
    textBn: stubBn,
    art: '$_dir/stub.svg',
    lessonPoint: 1,
  );
  static const nestFallBn = 'পাখির বাসা নষ্ট হয়ে গেল। ডাল ছাঁটার সময় গাছের ক্ষতি কম রাখতে হয়, বাসাটা বাঁচিয়ে কাটুন।';
  static const nestFall = DoMistake(
    key: '8.9/m8_trim_not_fell/nest-fall',
    textBn: nestFallBn,
    art: '$_dir/nest_fall.svg',
    lessonPoint: 0,
  );
  static const trunkBn = 'পুরো গাছ কাটার অধিকার আমাদের নেই — ফরেস্ট ডিপার্টমেন্ট বা পঞ্চায়েত/মিউনিসিপালিটির লিখিত অনুমতি লাগে।';
  static const trunk = DoMistake(
    key: '8.9/m8_trim_not_fell/trunk',
    textBn: trunkBn,
    art: '$_dir/trunk.svg',
    lessonPoint: 0,
  );
  static const leftOverBn = 'বিপদের ডাল রয়ে গেল — বর্ষায় ঝড়ে ডাল পড়ে তার ছিঁড়বে বা আগুন লাগবে।';
  static const leftOver = DoMistake(
    key: '8.9/m8_trim_not_fell/left-over',
    textBn: leftOverBn,
    art: '$_dir/left_over.svg',
    lessonPoint: 1,
  );
  static const listenSawBn = 'পুরো গাছ কাটতে লিখিত অনুমতি লাগে — অনুমতি ছাড়া কাটলে আইনি মামলা হতে পারে। শুধু বিপদের ডাল ছাঁটুন।';
  static const listenSaw = DoMistake(
    key: '8.9/m8_trim_not_fell/listen-saw',
    textBn: listenSawBn,
    art: '$_dir/listen_saw.svg',
    lessonPoint: 0,
  );
  static const quarrelBn = 'ঝগড়া বা ভয় দেখানো নয় — বিপদটা বুঝিয়ে বলুন। ঝগড়া নয়, সচেতনতাই সমাধান।';
  static const quarrel = DoMistake(
    key: '8.9/m8_trim_not_fell/quarrel',
    textBn: quarrelBn,
    art: '$_dir/quarrel.svg',
  );

  static const List<DoMistake> all = [needless, stub, nestFall, trunk, leftOver, listenSaw, quarrel];
}

// ============================================================================
// The rules (pure)
// ============================================================================

/// One play's deal.
@immutable
class M8TrimDeal {
  const M8TrimDeal({
    required this.trees,
    required this.coworkerTree,
    required this.coworkerSeat,
    required this.poleLen,
    required this.sway,
    required this.mirror,
    required this.dusk,
    required this.whyRoll,
    required this.captionRoll,
  });

  /// The two trees, in order.
  final List<M8TreeDeal> trees;

  /// The tree he comes on (0 or 1) and after which hook-seat on it (1 or 2).
  final int coworkerTree;
  final int coworkerSeat;
  final double poleLen;

  /// How far the pole sways while it is moved (design px).
  final double sway;
  final bool mirror;
  final int dusk;
  final int whyRoll;
  final int captionRoll;
}

M8TrimDeal m8TrimDeal(math.Random rng) {
  late List<M8TreeKind> kinds;
  do {
    kinds = [...M8TreeKind.values]..shuffle(rng);
    kinds = kinds.take(2).toList();
  } while (!kinds.any(m8HasOwner));
  return M8TrimDeal(
    trees: [for (final k in kinds) m8DealTree(k, rng)],
    coworkerTree: rng.nextInt(2),
    coworkerSeat: 1 + rng.nextInt(2),
    poleLen: 240 + rng.nextInt(26).toDouble(),
    sway: 3 + rng.nextDouble() * 5,
    mirror: rng.nextBool(),
    dusk: rng.nextInt(3),
    whyRoll: rng.nextInt(1000),
    captionRoll: rng.nextInt(1000),
  );
}

/// What one pull did.
@immutable
class M8PullResult {
  const M8PullResult(this.kind, {this.mistake, this.piece, this.hadNest = false});
  final M8PullKind kind;
  final DoMistake? mistake;

  /// The piece that falls (null = nothing falls).
  final M8Piece? piece;

  /// The branch had a nest and it stayed on the stub.
  final bool hadNest;
}

/// One tree's play state.
class M8TreeState {
  M8TreeState(this.deal)
      : curT = List.filled(deal.branches.length, 1.0),
        done = List.filled(deal.branches.length, false),
        consumerDone = !m8HasOwner(deal.kind);

  final M8TreeDeal deal;
  final List<double> curT;
  final List<bool> done;
  final List<M8Piece> pieces = [];
  bool consumerDone;
  var nestDown = false;
  var seats = 0;
  var finished = false;

  bool get dangerLeft {
    for (var i = 0; i < deal.branches.length; i++) {
      if (deal.branches[i].endangers && !done[i]) return true;
    }
    return false;
  }
}

/// The play state (pure logic).
class M8TrimRun {
  M8TrimRun(this.deal) : states = [for (final t in deal.trees) M8TreeState(t)];

  final M8TrimDeal deal;
  final List<M8TreeState> states;
  int treeIdx = 0;

  /// The hook now seated (null = in the air).
  M8SeatHit? seat;
  int slips = 0;
  int stageSlips = 0;
  var _doneAll = false;
  final List<String> caught = [];
  final Map<M8TrimWhy, int> asked = {};

  M8TreeState get cur => states[treeIdx];
  bool get lastTree => treeIdx == states.length - 1;
  bool get done => _doneAll;
  bool get ended => _doneAll;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => _doneAll && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stageSlips++;
    return m;
  }

  /// A card of the consumer deck: a quarrelling or threatening one is a slip.
  DoMistake? consumerPick(bool right) {
    if (cur.consumerDone) return null;
    if (!right) return _slip(M8TrimMistakes.quarrel);
    cur.consumerDone = true;
    _tag(M8TrimLines.caughtOwner);
    return null;
  }

  /// The hook let go on [hit]: it seats (a trunk or a branch) or hangs in the air.
  bool seatHook(M8SeatHit hit) {
    if (!cur.consumerDone || hit.kind == M8SeatKind.none) {
      seat = null;
      return false;
    }
    seat = hit;
    cur.seats++;
    return true;
  }

  void liftHook() => seat = null;

  /// The rope pulled with the hook seated: judged now. The hook comes off after
  /// any pull; a stub stays standing, a cut piece falls (the page lands it).
  M8PullResult pull() {
    final s = seat;
    if (s == null || s.kind == M8SeatKind.none) return const M8PullResult(M8PullKind.none);
    seat = null;
    if (s.kind == M8SeatKind.trunk) {
      return M8PullResult(M8PullKind.trunk, mistake: _slip(M8TrimMistakes.trunk));
    }
    final i = s.index;
    final b = cur.deal.branches[i];
    final t = math.min(s.t, cur.curT[i]);
    final piece = M8Piece(i, t, cur.curT[i]);
    cur.curT[i] = t;
    if (!b.endangers) {
      cur.done[i] = true;
      final nt = b.nestT;
      if (nt != null && nt > t) cur.nestDown = true;
      return M8PullResult(M8PullKind.needless, mistake: _slip(M8TrimMistakes.needless), piece: piece);
    }
    final nest = b.nestT != null && !cur.nestDown;
    if (nest && t < b.nestSafeT) {
      cur.done[i] = true;
      cur.nestDown = true;
      return M8PullResult(M8PullKind.nestFall, mistake: _slip(M8TrimMistakes.nestFall), piece: piece);
    }
    if (t <= b.lineT) {
      cur.done[i] = true;
      _tag(M8TrimLines.caughtCut);
      if (nest) _tag(M8TrimLines.caughtNest);
      return M8PullResult(M8PullKind.right, piece: piece, hadNest: nest);
    }
    return M8PullResult(M8PullKind.stub, mistake: _slip(M8TrimMistakes.stub), piece: piece);
  }

  /// The piece reached the tarp.
  void land(M8Piece p) => cur.pieces.add(p);

  /// "ছাঁটা শেষ": with an endangering branch left it is a slip; the tree ends
  /// either way.
  DoMistake? finish() {
    if (cur.finished) return null;
    cur.finished = true;
    seat = null;
    if (cur.dangerLeft) return _slip(M8TrimMistakes.leftOver);
    return null;
  }

  /// The camera walks to the next tree, or the work is done.
  void next() {
    stageReset();
    if (lastTree) {
      _doneAll = true;
    } else {
      treeIdx++;
    }
  }

  void stageReset() => stageSlips = 0;

  /// Listened to the coworker: a slip (B1; nothing in 8.9 is deadly).
  DoMistake listen() => _slip(M8TrimMistakes.listenSaw);

  /// The table was paid: the next stage's slips count afresh.
  void tablePaid() => stageSlips = 0;

  /// The reason a right move is asked: the nest one when the nest stayed (once),
  /// else the least asked of the other three, from the dealt start.
  M8TrimWhy whyFor({required bool hadNest}) {
    M8TrimWhy topic;
    if (hadNest && !asked.containsKey(M8TrimWhy.nest)) {
      topic = M8TrimWhy.nest;
    } else {
      const order = [M8TrimWhy.only, M8TrimWhy.fell, M8TrimWhy.monsoon];
      final start = deal.whyRoll % order.length;
      topic = order[start];
      for (var k = 1; k < order.length; k++) {
        final c = order[(start + k) % order.length];
        if ((asked[c] ?? 0) < (asked[topic] ?? 0)) topic = c;
      }
    }
    asked[topic] = (asked[topic] ?? 0) + 1;
    return topic;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   per tree: the pan 1500, drag the head 2000, pull 1500, its reason ~8200,
///   a second branch about half the plays ≈ 6000, "ছাঁটা শেষ" 1500 ≈ 17000
///   an owner on ~1.5 trees: the deck 3000 + its reason ~8200 ≈ 17000
///   the coworker once ≈ 9600
///   ≈ 34000 + 17000 + 9600 + a little slack ≈ 65000; 85 % ≈ 55000.
const m8TrimQuickMs = 55000;

/// Test hook: the play state of the page now on screen (tests only).
abstract final class M8TrimProbe {
  @visibleForTesting
  static M8TrimRun? run;
}

@immutable
class M8TrimPack {
  const M8TrimPack({required this.id, required this.titleBn, this.quickMs = m8TrimQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8TrimPack> m8TrimPacks = {
  'do_8_9_a': M8TrimPack(id: 'do_8_9_a', titleBn: M8TrimLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M8TrimPage extends StatefulWidget {
  const M8TrimPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8TrimPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8TrimPage> createState() => _M8TrimPageState();
}

class _M8TrimPageState extends State<M8TrimPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TrimRunPage(
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

class _TrimRunPage extends ConsumerStatefulWidget {
  const _TrimRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8TrimPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TrimRunPage> createState() => _TrimRunPageState();
}

/// What a pan on the scene is doing.
enum _Pan { none, head, rope }

class _TrimRunPageState extends ConsumerState<_TrimRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8TrimRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  // The pruner head follows the finger through this (no rebuild), the camera
  // walk and the falling piece through their controllers.
  final _head = ValueNotifier<Offset>(Offset.zero);
  late final AnimationController _slideC = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _fallC = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  var _headInit = false;

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
  int _cuts = 0;

  // The camera walk, a piece in the air, the chainsaw biting.
  var _walking = false;
  M8TreeRig? _prevRig;
  M8Piece? _falling;
  var _cutting = false;
  var _felling = false;
  Timer? _fellTimer;
  var _afterCard = false;
  var _coworkerScheduled = false;

  // The consumer deck.
  List<ChoiceOption> _consumerOpts = const [];
  final Set<String> _consumerWrong = {};
  String? _consumerPicked;
  var _consumerBusy = false;

  final _nudge = TaskNudge();
  int _nudgeN = 0;
  final _hints = IdleHintController();
  M8TrimGeo? _geoNow;

  // A pan on the scene.
  _Pan _pan = _Pan.none;
  final _panWatch = Stopwatch();
  Offset _ropeFrom = Offset.zero;
  var _pulled = false;

  @override
  void initState() {
    super.initState();
    _run = M8TrimRun(m8TrimDeal(widget.rng));
    M8TrimProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _fellTimer?.cancel();
    _head.dispose();
    _slideC.dispose();
    _fallC.dispose();
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

  bool get _consumerUp => _consumerOpts.isNotEmpty && !_ended;

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_walking && !_felling && !_cutting && !_consumerUp && !_run.ended;

  String get _task => _consumerUp ? M8TrimLines.askOwner : M8TrimLines.askWork;

  Future<void> _start() async {
    _clock.start();
    _startTree();
  }

  /// A tree stands before the trainee: its owner is asked first (if it has one).
  void _startTree() {
    final st = _run.cur;
    if (!st.consumerDone) {
      setState(() {
        _consumerOpts = dealChoices(M8TrimLines.consumerRight, M8TrimLines.consumerWrong, widget.rng);
        _consumerWrong.clear();
        _consumerPicked = null;
        _wake++;
      });
    } else {
      setState(() => _wake++);
    }
    unawaited(_sayChain([_task]));
  }

  // --- taps and pans ---------------------------------------------------------------------
  void _tapAt() {
    if (!_canPlay) return;
    _hints.missTap();
  }

  void _panStart(Offset p, M8TrimGeo geo) {
    _pan = _Pan.none;
    if (!_canPlay) return;
    final head = _head.value;
    if (geo.headBox(head).contains(p)) {
      // Lift the head: off its seat if it was seated; it follows the finger.
      _pan = _Pan.head;
      if (_run.seat != null) {
        _run.liftHook();
        setState(() => _wake++);
      }
      _panWatch
        ..reset()
        ..start();
      return;
    }
    if (_run.seat != null && geo.ropeHit.contains(p)) {
      _pan = _Pan.rope;
      _ropeFrom = p;
      _pulled = false;
      return;
    }
    _hints.missTap();
  }

  void _panUpdate(Offset p, M8TrimGeo geo) {
    switch (_pan) {
      case _Pan.head:
        _head.value = geo.headFor(p, swayPx: _run.deal.sway, ms: _panWatch.elapsedMilliseconds);
      case _Pan.rope:
        if (!_pulled && p.dy - _ropeFrom.dy >= 40) {
          _pulled = true;
          unawaited(_pull());
        }
      case _Pan.none:
        break;
    }
  }

  void _panEnd() {
    final kind = _pan;
    _pan = _Pan.none;
    final geo = _geoNow;
    if (geo == null) return;
    switch (kind) {
      case _Pan.head:
        if (_canPlay) _hookLet(geo);
        setState(() => _wake++);
      case _Pan.rope:
        if (!_pulled) _hints.missTap();
      case _Pan.none:
        break;
    }
  }

  /// The head let go: it seats on a branch or the trunk (a small clack), or hangs.
  void _hookLet(M8TrimGeo geo) {
    final st = _run.cur;
    final hit = geo.seatAt(st.deal, st.curT, st.done, _head.value);
    if (!_run.seatHook(hit)) {
      _hints.missTap();
      return;
    }
    if (hit.kind == M8SeatKind.branch) {
      _head.value = geo.pointOn(st.deal, st.deal.branches[hit.index], hit.t);
    }
    _tick('sounds/learn/stomp.ogg', 0.5);
    if (_run.treeIdx == _run.deal.coworkerTree && st.seats >= _run.deal.coworkerSeat && !_coworkerScheduled) {
      _coworkerScheduled = true;
      scheduleCoworker();
    }
  }

  // --- the pull ---------------------------------------------------------------------------
  /// A pull of the rope: the control waits for the coworker; then the blade
  /// bites and the piece falls; the judgement comes when it lands.
  Future<void> _pull() async {
    if (!_canPlay) return;
    if (holdForCoworker()) return;
    final geo = _geoNow;
    final res = _run.pull();
    if (res.kind == M8PullKind.none || geo == null) {
      _hints.missTap();
      return;
    }
    final st = _run.cur;
    final tree = st.deal;
    final b = res.piece == null ? null : tree.branches[res.piece!.branch];
    final at = b == null ? geo.origin(tree) + const Offset(0, -60) : geo.pointOn(tree, b, res.piece!.from);
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/ring_steel.ogg', volume: 0.55);
    _cuts++;
    final piece = res.piece;
    if (piece != null) {
      setState(() {
        _cutting = true;
        _falling = piece;
        _wake++;
      });
      if (_quiet) {
        _fallC.value = 1;
      } else {
        await _fallC.forward(from: 0);
      }
      if (!mounted) return;
      _run.land(piece);
      _cue('sounds/intro/drop.ogg', volume: 0.5);
      setState(() {
        _falling = null;
        _cutting = false;
        _wake++;
      });
    } else {
      setState(() => _wake++);
    }
    final m = res.mistake;
    if (m != null) {
      unawaited(_mistake(m, _sceneToGlobal(at)));
      return;
    }
    // A right cut: ◆ on the table, then the reason (it fits what was cut).
    putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
    final topic = _run.whyFor(hadNest: res.hadNest);
    unawaited(askReason(
      deal: () => dealChoices(M8TrimLines.whyRight[topic]!, M8TrimLines.myths, widget.rng),
      question: M8TrimLines.whyQ[topic]!,
      stillValid: () => !_ended,
    ));
  }

  /// A rough global position of a design point (for the flying ◆ only).
  Offset _sceneToGlobal(Offset p) {
    final size = MediaQuery.sizeOf(context);
    final k = size.width / 360;
    return Offset(p.dx * k, p.dy * k);
  }

  // --- "ছাঁটা শেষ" ---------------------------------------------------------------------------
  void _finishPressed() {
    if (!_canPlay) return;
    // He is dealt on this tree: if he has not been called yet, he comes now.
    if (_run.treeIdx == _run.deal.coworkerTree && !_coworkerScheduled) {
      _coworkerScheduled = true;
      scheduleCoworker();
    }
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.55);
    final geo = _geoNow;
    final m = _run.finish();
    if (m != null) {
      _afterCard = true;
      final at = geo == null ? Offset.zero : geo.doneBtn.center;
      unawaited(_mistake(m, _sceneToGlobal(at)));
      return;
    }
    _treeEnded();
  }

  void _treeEnded() {
    _afterCard = false;
    if (_run.lastTree) {
      _run.next();
      setState(() => _wake++);
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (mounted && !_ended) unawaited(_finish());
      }));
      return;
    }
    _prevRig = _treeRig(_run.cur, saw: false);
    _run.next();
    _hush();
    final geo = _geoNow;
    if (geo != null) _head.value = geo.headHome;
    _consumerOpts = const [];
    if (_quiet) {
      setState(() {
        _prevRig = null;
        _wake++;
      });
      _startTree();
      return;
    }
    setState(() {
      _walking = true;
      _wake++;
    });
    unawaited(_slideC.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _walking = false;
        _prevRig = null;
        _wake++;
      });
      _startTree();
    }));
  }

  // --- the consumer deck ----------------------------------------------------------------------
  Future<void> _pickConsumer(ChoiceOption o, Offset origin) async {
    if (!_consumerUp || _consumerBusy || _card != null || _consumerWrong.contains(o.textBn) || _consumerPicked != null) return;
    _hush();
    if (!o.correct) {
      setState(() => _consumerWrong.add(o.textBn));
      final m = _run.consumerPick(false);
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    _consumerBusy = true;
    setState(() => _consumerPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    _run.consumerPick(true);
    _consumerBusy = false;
    setState(() {
      _consumerOpts = const [];
      _wake++;
    });
    putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(M8TrimLines.whyRight[M8TrimWhy.consumer]!, M8TrimLines.myths, widget.rng),
      question: M8TrimLines.whyQ[M8TrimWhy.consumer]!,
      stillValid: () => !_ended,
    ));
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
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
    _run.tablePaid();
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8TrimLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended || _run.treeIdx != _run.deal.coworkerTree) return null;
    if (_intro || _card != null || tableBusy || _walking || _felling || _cutting || _consumerUp || _pan != _Pan.none) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listen();
      // The chainsaw bites the trunk and the scene stops; then the card.
      setState(() {
        _felling = true;
        _wake++;
      });
      final done = Completer<void>();
      _fellTimer?.cancel();
      _fellTimer = Timer(Duration(milliseconds: _quiet ? 500 : 1800), done.complete);
      await done.future;
      if (!mounted) return;
      setState(() {
        _felling = false;
        _wake++;
      });
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8TrimLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8TrimLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8TrimLines.tapWhy[_nudgeN++ % M8TrimLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
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
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8trim/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The play goes on from where it was (or to the next tree after a
    // "ছাঁটা শেষ" slip).
    _hush();
    setState(() {
      _card = null;
      _wake++;
    });
    if (_afterCard) {
      _treeEnded();
      return;
    }
    unawaited(_sayChain([_task]));
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
    await _say(!_run.passed ? M8TrimLines.fail : (_quickBonus ? M8TrimLines.quick : M8TrimLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_card != null || coworkerOpen || _felling) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_pan != _Pan.none || _run.seat != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M8TreeRig _treeRig(M8TreeState st, {required bool saw}) => M8TreeRig(
        deal: st.deal,
        curT: List.of(st.curT),
        done: List.of(st.done),
        nestDown: st.nestDown,
        pieces: List.of(st.pieces),
        ownerAngry: m8HasOwner(st.deal.kind) && !st.consumerDone,
        ownerCalm: m8HasOwner(st.deal.kind) && st.consumerDone,
        saw: saw,
        sawBite: _felling,
      );

  M8TrimRig get _rig => M8TrimRig(
        rev: _wake,
        tree: _treeRig(_run.cur, saw: coworkerOpen || _felling),
        prev: _prevRig,
        showPole: !_walking,
        seated: _run.seat != null,
        falling: _falling,
        dusk: _run.deal.dusk,
      );

  /// The gesture hand: how to touch, never what. Nothing seated: the plain
  /// drag hand lifting the pruner head straight up (never toward a branch).
  /// Hook seated: a sweep over the rope, the pruner head and "ছাঁটা শেষ"
  /// together (pull, move or finish: never the rope alone).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final head = _head.value;
    if (_run.seat == null) {
      return HintSpec.drag(head, toward: const Offset(0, -1), travel: 80, space: HintSpace.scene);
    }
    return HintSpec.sweep([geo.ropeHit, geo.headBox(head), geo.doneBtn], space: HintSpace.scene);
  }

  String? get _caption {
    final k = _run.cur.deal.kind;
    final lines = M8TrimLines.ownerCaptions[k];
    if (lines == null || !_consumerUp) return null;
    return lines[_run.deal.captionRoll % lines.length];
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8TrimGeo.forScene(m.height, m.inset, mirror: _run.deal.mirror, poleLen: _run.deal.poleLen);
    if (!_headInit) {
      _headInit = true;
      _head.value = geo.headHome;
    }
    final quiet = _quiet;
    final cap = _caption;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: Stack(
          children: [
            Positioned.fill(
              key: const ValueKey('lane'),
              child: RepaintBoundary(child: CustomPaint(painter: M8TrimPainter(geo: geo, rig: _rig, head: _head, slide: _slideC, fall: _fallC))),
            ),
            Positioned.fromRect(
              key: const ValueKey('trainee'),
              rect: geo.traineeRect,
              child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
            ),
          ],
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8TrimLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A pan is judged by where the finger went down (the head, the
            // rope), not where it passed the slop.
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (_) => _tapAt(),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      if (!_intro && _mark == null)
        Positioned.fromRect(
          key: const ValueKey('trim-done'),
          rect: geo.doneBtn,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _finishPressed,
            child: Semantics(
              button: true,
              label: M8TrimLines.done,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SlmColors.navy900.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: SlmColors.gold400, width: 2),
                ),
                child: Center(child: Text(M8TrimLines.done, style: bangla(fontSize: 16, fontWeight: FontWeight.w800, color: SlmColors.ivory))),
              ),
            ),
          ),
        ),
      if (cap != null)
        Positioned(
          key: const ValueKey('owner-caption'),
          left: 150,
          right: 8,
          top: geo.ownerRect.top - 74,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(cap, style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF3A1D12))),
              ),
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
    final playing = !_intro && _mark == null && !struckOut;
    final consumerUp = _consumerUp && playing;
    final deckUp = reasonOpen || coworkerChoiceUp || consumerUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_felling && !_run.ended;
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
              labels: M8TrimLines.stages,
              done: {
                for (var i = 0; i < _run.states.length; i++)
                  if (_run.states[i].finished) i,
              },
              current: _run.ended ? null : _run.treeIdx,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _pan == _Pan.none && !_walking && !_cutting && !_consumerUp,
            hintKey: '${_run.treeIdx}/${_run.seat?.index}/${_run.cur.seats}/$_cuts/${_run.slips}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
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
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('consumer-deck-${_run.treeIdx}'),
                                options: _consumerOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _consumerWrong,
                                picked: _consumerPicked,
                                onPick: (o, at) => unawaited(_pickConsumer(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  line: M8TrimLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
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
