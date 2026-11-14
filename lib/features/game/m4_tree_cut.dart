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
import 'm4_tree_cut_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_tree_cut_world.dart' show M4TreeCutGeo, M4TreeCutMark, M4TreeCutPiece, M4TreeCutShoot, M4TreeCutSpot;

// Lesson 4.8 "গাছের ডালপালা ছাঁটা", কাজ 2 "ডাল নামাও, লাইন বাঁচিয়ে"
// (pack do_4_8_b, engine m4_tree_cut). The line is shut down (PTW, earth set
// drawn on its dead-end pole; the docket says so) and the work area below is
// roped off. A roadside tree's heavy limb droops out over the conductors; the
// trainee is up the tree (helmet, harness, lanyard round the trunk), his
// ground mate below holds the rope. Five stations a play:
//   ক trim — "ছোট থেকে বড়": the small outer twigs first, then the side branch
//     they grow on; the heavy limb is not cut yet (cutting a bigger piece
//     while a smaller one is left is the slip);
//   খ rope — the heavy limb hangs over the line: tie the rope on it before any
//     saw ("পতনের দিক নিয়ন্ত্রণ … দড়ি দিয়ে বেঁধে"); the saw first is a slip;
//     the careless coworker pushes "দড়ি লাগবে না, কেটে ফেলে দাও";
//   গ spot — before the cut, where to stand: below the limb or out on it is in
//     its fall line (deadly); beside the trunk, above and away, is right;
//   ঘ cut — the lesson's 3-cut method: the under cut, then the top cut a
//     little outside it (the limb comes free onto the rope), lower it slowly
//     on the rope (in to the trunk, clear of the line), then the finish cut
//     at the collar; out of order is a slip, letting the rope go is a slip;
//   ঙ clear — the safe clearance from the conductors ("দেড় থেকে তিন মিটার"):
//     find the one shoot growing at the line and cut it (directional pruning:
//     a shoot growing away is not cut — a slip), then say the clearance is
//     right ("ক্লিয়ারেন্স ঠিক" with the shoot left is a slip).
//
// Deadly (lesson point 2, plan where the branch falls): standing in its fall
// line. Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m4_tree_cut_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next station by itself; the coworker once a play.
// Voice: the guide's lines by device TTS until recorded; the coworker's push
// has no clip yet (silent, caption held — kit rule); his exit line is recorded.
//
// Audit 2026-11-11: no scene control works in a praise window (`tableBusy` in
// `_canPlay`), so a limb tap after the last twig no longer books a false
// "small first" slip; the tool on the limb waits for the coworker
// (`holdForCoworker`) and he no longer comes once the rope is tied (his push
// is "no rope"); the tool tray's order is dealt; the cut places carry no
// chalk ticks (the world draws only kerfs already made); a gesture hint for
// every waiting state (how to touch, never which one).

// ============================================================================
// Content
// ============================================================================

enum M4TreeCutStation { trim, rope, spot, cut, clear }

enum M4TreeCutTool { rope, saw }

abstract final class M4TreeCutLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askTrim, askRope, askSpot, askCut, askLower, askFinish, askClear];

  static const title = 'ডাল নামাও, লাইন বাঁচিয়ে';
  static const intro = 'লাইন বন্ধ, আর্থ লাগানো। লাইনের ওপর ঝোঁকা ডাল ছাঁটুন — লাইনে যেন না পড়ে!';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];

  static const askTrim = 'লাইনের দিকে ঝোঁকা ডালপালা ছাঁটুন।';
  static const askRope = 'এবার লাইনের ওপরের মোটা ডালটা।';
  static const askSpot = 'কাটার আগে — কোথায় থাকবেন?';
  static const askCut = 'মোটা ডালটা কাটুন — ঠিক নিয়মে।';
  static const askLower = 'ডাল দড়িতে ঝুলছে। এবার নামান।';
  static const askFinish = 'ডাল নিচে। এবার গোড়ার শেষ কাট।';
  static const askClear = 'কাজ শেষের আগে লাইনের ক্লিয়ারেন্স দেখুন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'গাছ আর লাইন';
  static const rope = 'দড়ি';
  static const saw = 'চেইনসঅ';
  static const lower = 'ধীরে নামান';
  static const letGo = 'দড়ি ছেড়ে দিন';
  static const clearOk = 'ক্লিয়ারেন্স ঠিক';
  static const docket = 'ডকেট';
  static const job = 'গাছের ডাল ছাঁটা';
  static const permit = 'শাটডাউন · PTW · আর্থ';
  static const stampDone = 'লাইন পরিষ্কার';

  // The reasons (lesson 4.8): the right ones state this station's rule; the
  // wrong ones are field excuses — never a true rule marked wrong.
  static String why(M4TreeCutStation s) => switch (s) {
        M4TreeCutStation.trim => 'কেন এই ক্রমে ছাঁটলেন?',
        M4TreeCutStation.rope => 'কাটার আগে দড়ি কেন?',
        M4TreeCutStation.spot => 'কেন ওখানে দাঁড়ালেন?',
        M4TreeCutStation.cut => 'ডালটা এভাবে কেন কাটলেন?',
        M4TreeCutStation.clear => 'শেষে এটা কেন দেখলেন?',
      };

  static const trimWhy = [
    'ছোট আর বাইরের ডাল আগে, ভেতরের মোটা ডাল পরে',
    'বাইরের দিক থেকে কেটে ভেতরের দিকে আসতে হয়',
    'ওপর বা বাইরের দিক থেকে কাটা শুরু করাই নিয়ম',
  ];
  static const ropeWhy = [
    'দড়ি বাঁধলে ডাল কোন দিকে পড়বে তা ঠিক থাকে',
    'দড়ি ছাড়া ভারী ডাল সোজা লাইনের ওপর পড়ত',
    'পতনের দিক আগে ঠিক করে, দড়িতে নিয়ন্ত্রণ করি',
  ];
  static const spotWhy = [
    'পড়ন্ত ডালের পথে থাকলে ডাল আমাকেই আঘাত করে',
    'আগে দেখি ডাল কোথায় পড়বে, থাকি তার বাইরে',
    'ডালের নিচে বা ওপরে নয়, পতনের পথের পাশে থাকি',
  ];
  static const cutWhy = [
    'আগে নিচে ছোট কাট দিলে ছাল ছিঁড়ে যায় না',
    'থ্রি-কাট: আগে নিচে, তারপর ওপরে, শেষে গোড়ায়',
    'দড়িতে ধীরে নামালে ভারী ডাল লাইনে পড়ে না',
  ];
  static const clearWhy = [
    'লাইন থেকে দেড় থেকে তিন মিটার দূরত্ব চাই',
    'শুধু লাইনের দিকে বাড়া ডালই ছাঁটতে হয়',
    'কাজ শেষে দেখি কোনো ডাল লাইনের কাছে আছে কি',
  ];
  static List<String> whyRight(M4TreeCutStation s) => switch (s) {
        M4TreeCutStation.trim => trimWhy,
        M4TreeCutStation.rope => ropeWhy,
        M4TreeCutStation.spot => spotWhy,
        M4TreeCutStation.cut => cutWhy,
        M4TreeCutStation.clear => clearWhy,
      };

  /// Field excuses (wrong on every deck).
  static const excuses = [
    'তাড়াতাড়ি শেষ হবে, তাই এভাবেই করে ফেললাম',
    'সবাই তো এভাবেই করে, কিছুই হয় না কখনো',
    'লাইন তো বন্ধ, তাই ডাল পড়লেও ক্ষতি নেই',
    'সুপারভাইজার দেখছেন না, এতেই চলে যাবে',
    'গাছের ডাল তো নরম, এতে কোনো বিপদই নেই',
    'অভিজ্ঞ লাইনম্যান আন্দাজেই কাজটা সেরে ফেলে',
  ];

  /// The careless coworker: no rope, just cut it and let it drop.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'দড়ি লাগবে না, কেটে ফেলে দাও! ডাল তো নিচেই পড়বে।',
    exitLine: coworkerExit,
    right: ['না, দড়ি ছাড়া ডাল লাইনের ওপর পড়বে', 'না, দড়ি বেঁধে ধীরে নামিয়ে আনব', 'না, পতনের দিক দড়িতেই ঠিক রাখব'],
    wrong: [
      'ঠিক, কেটে ফেলে দিলেই তাড়াতাড়ি হয়',
      'আচ্ছা, দড়ি রেখে এক কাটেই ফেলি',
      'ডাল তো নিচেই পড়বে, দড়ি লাগে না',
      'লাইন বন্ধ, ডাল পড়লেও কিছু হবে না',
      'ঠিক আছে, এবার দড়ি ছাড়াই কাটি',
    ],
    asks: ['ও বলছে দড়ি লাগবে না। আপনি কী করবেন?', 'দড়ি ছাড়া ফেলবেন, না নিয়ম মানবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );

  static const allSet = 'ডাল নামল, লাইন বাঁচল — ছোট থেকে বড়, দড়িতে বেঁধে, পথের বাইরে থেকে, থ্রি-কাটে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ছোট থেকে বড়, দড়ি আগে, পতনের পথের বাইরে।';
  static const deadlyWord = 'সরে যান!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtOrder = 'ছোট ডাল আগে, মোটা ডাল পরে';
  static const caughtRope = 'দড়ি বেঁধে তবেই কাটা';
  static const caughtSpot = 'ডাল পড়ার পথের বাইরে থেকেছেন';
  static const caughtThreeCut = 'থ্রি-কাট ঠিক ক্রমে';
  static const caughtLower = 'ডাল ধীরে, লাইন থেকে দূরে নামানো';
  static const caughtClear = 'লাইনের দিকে বাড়া ডাল ধরেছেন';
  static const caughtCall = 'চাপে “না” — দড়ি ছাড়া নয়';
}

abstract final class M4TreeCutMistakes {
  static const _dir = 'assets/game/art/m4_tree_cut';

  static const outerFirst = DoMistake(
    key: '4.8/m4_tree_cut/small-to-big',
    textBn: 'ছোট থেকে বড়: গাছের ওপর বা বাইরের দিকের ছোট ডাল আগে কাটুন, তারপর ভেতরের দিকে আসুন — মোটা ডাল সবশেষে।',
    art: '$_dir/order.svg',
    lessonPoint: 2,
  );
  static const noRope = DoMistake(
    key: '4.8/m4_tree_cut/no-rope',
    textBn: 'লাইনের ওপরের ভারী ডাল দড়ি ছাড়া কাটলে সোজা লাইনে পড়ে — তার ছিঁড়ে যেতে পারে। আগে দড়ি বেঁধে পতনের দিক ঠিক করুন।',
    art: '$_dir/rope.svg',
    lessonPoint: 2,
  );
  static const listened = DoMistake(
    key: '4.8/m4_tree_cut/listened-no-rope',
    textBn: 'ওর কথায় দড়ি ছাড়া কাটা মানে ডাল লাইনের ওপর ফেলা। ডাল কোন দিকে পড়বে আগে ঠিক করুন, দড়ি দিয়ে পতন নিয়ন্ত্রণ করুন।',
    art: '$_dir/rope.svg',
    lessonPoint: 2,
  );
  static const fallLine = DoMistake(
    key: '4.8/m4_tree_cut/in-fall-line',
    textBn: 'যে ডাল কাটছেন তার নিচে বা তার ওপরে ছিলেন — পড়ন্ত ডাল আপনাকেই আঘাত করে। কাটার আগে ঠিক করুন ডাল কোথায় পড়বে, আর সেই পথের বাইরে থাকুন।',
    art: '$_dir/fall.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const threeCut = DoMistake(
    key: '4.8/m4_tree_cut/three-cut-order',
    textBn: 'বড় ডালে থ্রি-কাট: আগে ডালের নিচে ছোট কাট, তারপর তার একটু বাইরে ওপর থেকে কাট, শেষে কান্ডের কাছে বাকি অংশ। নইলে ছাল ছিঁড়ে যায়।',
    art: '$_dir/cuts.svg',
    lessonPoint: 2,
  );
  static const letGo = DoMistake(
    key: '4.8/m4_tree_cut/rope-let-go',
    textBn: 'ডাল দড়িতে ঝুলছে — দড়ি ছেড়ে দিলে সোজা লাইনের ওপর পড়ে। দড়ি ধরে ধীরে, লাইন থেকে দূরে নামান।',
    art: '$_dir/lower.svg',
    lessonPoint: 2,
  );
  static const missed = DoMistake(
    key: '4.8/m4_tree_cut/clearance-missed',
    textBn: 'লাইনের দিকে বাড়া একটা ডাল এখনো কন্ডাক্টরের কাছে। কন্ডাক্টর থেকে ডালের নিরাপদ দূরত্ব রাখুন — সাধারণত দেড় থেকে তিন মিটার।',
    art: '$_dir/clear.svg',
    lessonPoint: 2,
  );

  /// Directional pruning is in the lesson's advanced section (not a lesson
  /// point), so "পাঠে দেখুন" opens the lesson from its start.
  static const overCut = DoMistake(
    key: '4.8/m4_tree_cut/cut-away-shoot',
    textBn: 'এই ডাল লাইনের উল্টো দিকে বাড়ছে — এটা কাটার দরকার নেই। ডিরেকশনাল প্রুনিং: শুধু লাইনের দিকে বাড়া ডালই ছাঁটুন।',
    art: '$_dir/prune.svg',
  );

  static List<DoMistake> get all => const [outerFirst, noRope, listened, fallLine, threeCut, letGo, missed, overCut];
}

/// One play: which twigs grow on the limb, which shoot grows at the line,
/// how many lengths of rope let the limb down.
@immutable
class M4TreeCutDeal {
  const M4TreeCutDeal({required this.twigs, required this.toward, required this.notches, this.sawFirst = false});

  /// The small twigs this play (2–3 of tip / twig A / twig B).
  final Set<M4TreeCutPiece> twigs;

  /// The shoot that grows at the conductors (low or mid).
  final M4TreeCutShoot toward;
  final int notches;

  /// The tool tray's order this play (never always the rope first).
  final bool sawFirst;

  List<M4TreeCutTool> get tray => sawFirst ? const [M4TreeCutTool.saw, M4TreeCutTool.rope] : const [M4TreeCutTool.rope, M4TreeCutTool.saw];

  /// Everything trimmed in station ক (the twigs and the side branch).
  Set<M4TreeCutPiece> get trimmed => {...twigs, M4TreeCutPiece.side};
}

M4TreeCutDeal dealM4TreeCut(math.Random rng) {
  const all = [M4TreeCutPiece.tipTwig, M4TreeCutPiece.twigA, M4TreeCutPiece.twigB];
  final drop = rng.nextInt(4); // 0–2: leave that one out; 3: all three
  return M4TreeCutDeal(
    twigs: {for (var i = 0; i < 3; i++) if (i != drop) all[i]},
    toward: rng.nextBool() ? M4TreeCutShoot.low : M4TreeCutShoot.mid,
    notches: 3 + rng.nextInt(2),
    sawFirst: rng.nextBool(),
  );
}

/// The size rank of a piece (ছোট থেকে বড়).
int m4TreeCutRank(M4TreeCutPiece p) => switch (p) {
      M4TreeCutPiece.tipTwig || M4TreeCutPiece.twigA || M4TreeCutPiece.twigB => 0,
      M4TreeCutPiece.side => 1,
      M4TreeCutPiece.limb => 2,
    };

/// The play state (pure logic).
class M4TreeCutRun {
  M4TreeCutRun(this.deal);
  final M4TreeCutDeal deal;

  M4TreeCutStation station = M4TreeCutStation.trim;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// Slips at the current station (a clean station pays +5).
  int stationSlips = 0;

  // trim
  final Set<M4TreeCutPiece> gone = {};

  // rope
  bool roped = false;

  // spot
  M4TreeCutSpot? spot;

  // cut
  final Set<M4TreeCutMark> cuts = {};
  int lengthsDown = 0;
  bool lowered = false;

  // clear
  bool shootCut = false;
  bool cleared = false;

  bool get ended => deadly != null || cleared;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => cleared && deadly == null && percent >= 55;
  bool get clean => stationSlips == 0;
  bool get freed => cuts.contains(M4TreeCutMark.under) && cuts.contains(M4TreeCutMark.top);
  bool get trimDone => gone.containsAll(deal.trimmed);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stationSlips++;
    return m;
  }

  /// The pieces still to trim (and the limb), for the taps.
  Iterable<M4TreeCutPiece> get standing => [...deal.trimmed.where((p) => !gone.contains(p)), M4TreeCutPiece.limb];

  /// Cut [p] in station ক: a bigger piece while a smaller one stands is a slip.
  DoMistake? trim(M4TreeCutPiece p) {
    if (ended || station != M4TreeCutStation.trim || gone.contains(p) || trimDone) return null;
    if (p != M4TreeCutPiece.limb && !deal.trimmed.contains(p)) return null;
    final r = m4TreeCutRank(p);
    final smaller = deal.trimmed.any((q) => !gone.contains(q) && m4TreeCutRank(q) < r);
    if (p == M4TreeCutPiece.limb || smaller) return _slip(M4TreeCutMistakes.outerFirst);
    gone.add(p);
    if (trimDone) _tag(M4TreeCutLines.caughtOrder);
    return null;
  }

  /// A tool on the heavy limb in station খ: the saw before the rope is a slip.
  DoMistake? useOnLimb(M4TreeCutTool t) {
    if (ended || station != M4TreeCutStation.rope || roped) return null;
    if (t == M4TreeCutTool.saw) return _slip(M4TreeCutMistakes.noRope);
    roped = true;
    _tag(M4TreeCutLines.caughtRope);
    return null;
  }

  /// Listened to him: cut it without the rope.
  DoMistake? listen() => ended ? null : _slip(M4TreeCutMistakes.listened);

  /// Where he stands for the big cut: in its fall line is deadly.
  DoMistake? stand(M4TreeCutSpot s) {
    if (ended || station != M4TreeCutStation.spot || spot != null) return null;
    if (s != M4TreeCutSpot.beside) return deadly = M4TreeCutMistakes.fallLine;
    spot = s;
    _tag(M4TreeCutLines.caughtSpot);
    return null;
  }

  /// One of the three cuts. Out of order: a slip (the cut is not made).
  DoMistake? cut(M4TreeCutMark m) {
    if (ended || station != M4TreeCutStation.cut || cuts.contains(m)) return null;
    switch (m) {
      case M4TreeCutMark.under:
        cuts.add(m);
        return null;
      case M4TreeCutMark.top:
        if (!cuts.contains(M4TreeCutMark.under)) return _slip(M4TreeCutMistakes.threeCut);
        cuts.add(m);
        return null;
      case M4TreeCutMark.collar:
        if (!freed) return _slip(M4TreeCutMistakes.threeCut);
        if (!lowered) return null;
        cuts.add(m);
        _tag(M4TreeCutLines.caughtThreeCut);
        return null;
    }
  }

  /// The freed limb on the rope: one length down; true = on the ground.
  bool lowerOne() {
    if (ended || station != M4TreeCutStation.cut || !freed || lowered) return false;
    lengthsDown++;
    if (lengthsDown >= deal.notches) {
      lowered = true;
      _tag(M4TreeCutLines.caughtLower);
      return true;
    }
    return false;
  }

  /// Let the rope go: a slip (the ground mate keeps hold).
  DoMistake? letGo() {
    if (ended || station != M4TreeCutStation.cut || !freed || lowered) return null;
    return _slip(M4TreeCutMistakes.letGo);
  }

  bool get cutDone => cuts.contains(M4TreeCutMark.collar);

  /// Cut a crown shoot: one growing away from the line is a slip.
  DoMistake? cutShoot(M4TreeCutShoot s) {
    if (ended || station != M4TreeCutStation.clear || shootCut) return null;
    if (s != deal.toward) return _slip(M4TreeCutMistakes.overCut);
    shootCut = true;
    return null;
  }

  /// "ক্লিয়ারেন্স ঠিক": with the shoot at the line left, a slip.
  DoMistake? checkClear() {
    if (ended || station != M4TreeCutStation.clear || cleared) return null;
    if (!shootCut) return _slip(M4TreeCutMistakes.missed);
    cleared = true;
    _tag(M4TreeCutLines.caughtClear);
    return null;
  }

  /// On to the next station.
  void next() {
    stationSlips = 0;
    if (station != M4TreeCutStation.clear) station = M4TreeCutStation.values[station.index + 1];
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
///   trim: ~3.5 taps × 1500 + reason ~8200                              13500
///   rope: pick + tap ~3000 + reason ~8200                              11200
///   the coworker: his line ~3500 + deck 910 + pick 3500                 7900
///   spot: one tap ~2500 + reason ~8200                                 10700
///   cut: 3 taps ~4500 + ~3.5 lengths × (700 + 1500) + reason ~8200     20400
///   clear: 2 taps ~3000 + reason ~8200                                 11200
///   ≈ 74900 ms; 85 % ≈ 63700 → 65 s.
const kM4TreeCutQuickMs = 65000;

@immutable
class M4TreeCutPack {
  const M4TreeCutPack({required this.id, required this.titleBn, this.quickMs = kM4TreeCutQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m4TreeCutPacks = {
  'do_4_8_b': M4TreeCutPack(id: 'do_4_8_b', titleBn: M4TreeCutLines.title),
};

/// The ground mate (not the careless coworker): white helmet, green shirt.
const _mateLook = LinemanLook(
  helmet: Color(0xFFF2F2EE),
  shirt: Color(0xFF2E7D4F),
  vest: Color(0xFFFF851B),
  pants: Color(0xFF2E3440),
  skin: Color(0xFF9A6440),
  gloves: true,
);

// ============================================================================
// Page
// ============================================================================

class M4TreeCutPage extends StatefulWidget {
  const M4TreeCutPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M4TreeCutPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4TreeCutPage> createState() => _M4TreeCutPageState();
}

class _M4TreeCutPageState extends State<M4TreeCutPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TreeRunPage(
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

class _TreeRunPage extends ConsumerStatefulWidget {
  const _TreeRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4TreeCutPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TreeRunPage> createState() => _TreeRunPageState();
}

class _TreeRunPageState extends ConsumerState<_TreeRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4TreeCutRun _run = M4TreeCutRun(dealM4TreeCut(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// One length of rope let down while held, 0 → 1.
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _lengthDone();
    });

  /// The trainee moving to his spot.
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Listenable _sceneMotion = Listenable.merge([_hold, _move]);

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
  M4TreeCutTool? _tool;
  var _holding = false;
  var _stamp = false;
  final List<(int, Offset)> _taps = [];
  int _tapN = 0;

  /// Cut pieces dropping into the roped-off area (they stay there as debris).
  final List<(int, Offset, bool)> _drops = [];
  int _dropN = 0;

  /// Where he stood before moving to his spot, and where he goes.
  final M4TreeCutSpot _from = M4TreeCutSpot.below;
  M4TreeCutSpot _to = M4TreeCutSpot.below;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hint (how to touch, never which one).
  final _hints = IdleHintController();
  final _sceneKey = GlobalKey();
  final _lowerKey = GlobalKey();
  final _letGoKey = GlobalKey();
  final _clearKey = GlobalKey();
  final Map<M4TreeCutTool, GlobalKey> _toolKeys = {for (final t in M4TreeCutTool.values) t: GlobalKey()};

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _hold.dispose();
    _move.dispose();
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

  String get _task => switch (_run.station) {
        M4TreeCutStation.trim => M4TreeCutLines.askTrim,
        M4TreeCutStation.rope => M4TreeCutLines.askRope,
        M4TreeCutStation.spot => M4TreeCutLines.askSpot,
        M4TreeCutStation.cut => !_run.freed ? M4TreeCutLines.askCut : (_run.lowered ? M4TreeCutLines.askFinish : M4TreeCutLines.askLower),
        M4TreeCutStation.clear => M4TreeCutLines.askClear,
      };

  void _start() {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  /// The scene takes a move now: never in a right move's praise window
  /// (`tableBusy`: its ◆ waits on the table / its reason is asked), nor while
  /// he talks, a card shows or the scene is frozen.
  bool get _canPlay =>
      !_intro && !_busy && !_ended && !_freeze && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !struckOut && !_move.isAnimating;

  /// The nearest of [rects] whose area holds [p].
  static T? _nearest<T>(Offset p, Map<T, Rect> rects) {
    T? best;
    var d = double.infinity;
    rects.forEach((k, r) {
      if (!r.contains(p)) return;
      final dd = (r.center - p).distanceSquared;
      if (dd < d) {
        d = dd;
        best = k;
      }
    });
    return best;
  }

  // --- taps on the scene ---------------------------------------------------------
  void _tapScene(Offset p, M4TreeCutGeo geo, Offset global) {
    if (!_canPlay) return;
    final r = _run;
    switch (r.station) {
      case M4TreeCutStation.trim:
        final hit = _nearest(p, {for (final q in r.standing) q: geo.pieceRect(q)});
        if (hit != null) {
          final m = r.trim(hit);
          if (m != null) {
            unawaited(_slipOut(m, global));
            return;
          }
          _cutFx(geo.pieceEnd(hit), geo, big: hit == M4TreeCutPiece.side);
          if (r.trimDone) _stationRight(global);
          return;
        }
      case M4TreeCutStation.rope:
        if (_tool != null && geo.limbRect.contains(p)) {
          // His push is about this very step: he comes first (a fast player
          // still meets him); the tool stays in hand.
          if (holdForCoworker()) return;
          final m = r.useOnLimb(_tool!);
          if (m != null) {
            unawaited(_slipOut(m, global));
            return;
          }
          HapticFeedback.mediumImpact();
          _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
          setState(() {
            _tool = null;
            _wake++;
          });
          _stationRight(global);
          return;
        }
      case M4TreeCutStation.spot:
        final s = _nearest(p, {for (final s in M4TreeCutSpot.values) s: geo.spotRect(s)});
        if (s != null) {
          unawaited(_stand(s, global));
          return;
        }
      case M4TreeCutStation.cut:
        if (r.freed && !r.lowered) break;
        final marks = {
          for (final m in M4TreeCutMark.values)
            if (!r.cuts.contains(m) && (!r.freed || m == M4TreeCutMark.collar)) m: geo.markRect(m),
        };
        final hit = _nearest(p, marks);
        if (hit != null) {
          final wasFree = r.freed;
          final m = r.cut(hit);
          if (m != null) {
            unawaited(_slipOut(m, global));
            return;
          }
          _sawFx();
          if (r.cutDone) {
            _stationRight(global);
          } else if (r.freed && !wasFree) {
            _cue('sounds/intro/drop.ogg', volume: 0.5);
            unawaited(_sayChain([M4TreeCutLines.askLower]));
          }
          return;
        }
      case M4TreeCutStation.clear:
        final hit = _nearest(p, {
          for (final s in M4TreeCutShoot.values)
            if (!(_run.shootCut && s == _run.deal.toward)) s: geo.shootRect(s, toward: s == _run.deal.toward),
        });
        if (hit != null) {
          final m = r.cutShoot(hit);
          if (m != null) {
            unawaited(_slipOut(m, global));
            return;
          }
          _cutFx(geo.shootTip(hit, toward: true), geo, big: false);
          return;
        }
    }
    _plainTap(p);
  }

  void _plainTap(Offset p) {
    _hints.missTap();
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.4);
    setState(() {
      _taps.add((_tapN++, p));
      if (_taps.length > 4) _taps.removeAt(0);
    });
  }

  void _sawFx() {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/dull_steel.ogg', volume: 0.6);
    setState(() => _wake++);
  }

  void _cutFx(Offset from, M4TreeCutGeo geo, {required bool big}) {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.55);
    setState(() {
      _drops.add((_dropN++, from, big));
      _wake++;
    });
  }

  void _pickTool(M4TreeCutTool t) {
    if (!_canPlay || _run.station != M4TreeCutStation.rope) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.45);
    setState(() => _tool = _tool == t ? null : t);
  }

  Future<void> _stand(M4TreeCutSpot s, Offset global) async {
    final m = _run.stand(s);
    HapticFeedback.selectionClick();
    setState(() {
      _to = s;
      _wake++;
    });
    if (_quiet) {
      _move.value = 1;
    } else {
      await _move.forward(from: 0);
    }
    if (!mounted) return;
    if (m != null) {
      await _deadly(m);
      return;
    }
    _stationRight(global);
  }

  // --- the rope: let the freed limb down --------------------------------------------
  void _holdStart() {
    if (!_canPlay || _holding || _run.station != M4TreeCutStation.cut || !_run.freed || _run.lowered) return;
    _holding = true;
    HapticFeedback.selectionClick();
    unawaited(_hold.forward(from: _hold.value));
  }

  void _holdEnd() {
    if (!_holding) return;
    _holding = false;
    if (_hold.isAnimating && _hold.value < 1) unawaited(_hold.reverse());
  }

  void _lengthDone() {
    if (!mounted || _ended) return;
    _holding = false;
    _hold.value = 0;
    final down = _run.lowerOne();
    _cue('sounds/intro/tick.ogg', volume: 0.6);
    HapticFeedback.lightImpact();
    setState(() => _wake++);
    if (down) {
      _cue('sounds/learn/knock_hollow.ogg', volume: 0.6);
      unawaited(_sayChain([M4TreeCutLines.askFinish]));
    }
  }

  Future<void> _letGo(Offset origin) async {
    if (!_canPlay || _holding) return;
    final m = _run.letGo();
    if (m != null) await _slipOut(m, origin);
  }

  Future<void> _checkClear(Offset origin) async {
    if (!_canPlay || _run.station != M4TreeCutStation.clear) return;
    final m = _run.checkClear();
    if (m != null) {
      await _slipOut(m, origin);
      return;
    }
    _hush();
    setState(() => _stamp = true);
    _stationRight(origin);
  }

  // --- a station done right: the ◆ and the reason ---------------------------------
  void _stationRight(Offset origin) {
    _hush();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    final station = _run.station;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(M4TreeCutLines.whyRight(station), M4TreeCutLines.excuses, widget.rng),
      question: M4TreeCutLines.why(station),
      stillValid: () => _run.station == station && !_ended,
    ));
  }

  void _nextStation() {
    if (_run.station == M4TreeCutStation.clear) {
      unawaited(_finish());
      return;
    }
    _run.next();
    setState(() {
      _taps.clear();
      _tool = null;
      _wake++;
    });
    if (_run.station == M4TreeCutStation.rope) scheduleCoworker();
    unawaited(_sayChain([_task]));
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
    final st = _run.station;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.station == st) _nextStation();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M4TreeCutLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  /// His push is "no rope, just cut it": only while the rope station waits
  /// for the rope. Once it is tied (or the station is past) it makes no sense
  /// any more — too late for this play.
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.roped || _run.station.index > M4TreeCutStation.rope.index) return null;
    if (_run.station == M4TreeCutStation.trim) return false;
    if (_intro || _busy || _freeze || _card != null || reasonOpen || tableBusy || struckOut || _move.isAnimating) return false;
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
      if (m != null) await _slipOut(m, origin);
      return;
    }
    _run.caught.add(M4TreeCutLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (mounted && !_ended) unawaited(_sayChain([_task]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4TreeCutLines.tapWhy[_nudgeN++ % M4TreeCutLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _slipOut(DoMistake m, Offset origin) async {
    setState(() => _tool = null);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

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
    final speak = await SpokenOnce.first('treecut/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// In the fall line: the tree freezes grey, the heavy limb drops along its
  /// fall line onto him in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/knock_solid.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('treecut/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4TreeCutLines.deadlyWord : M4TreeCutLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
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
    if (_ended && !_run.cleared) return;
    if (_mark != null) return;
    _ended = true;
    _clock.stop();
    setState(() => _wake++);
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
    await _say(!_run.passed ? M4TreeCutLines.fail : (_quickBonus ? M4TreeCutLines.quick : M4TreeCutLines.allSet),
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
    if (_mark != null && _passed) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  Rect _traineeBox(M4TreeCutGeo geo) =>
      Rect.lerp(geo.spotBox(_from), geo.spotBox(_to), Curves.easeInOut.transform(_move.value))!;

  M4TreeCutTree get _treeState {
    final r = _run;
    final live = r.freed && !r.lowered && _holding ? _hold.value : 0.0;
    return M4TreeCutTree(
      present: r.deal.trimmed,
      gone: {...r.gone},
      roped: r.roped,
      cuts: {...r.cuts},
      lower: r.lowered ? 1 : ((r.lengthsDown + live) / r.deal.notches).clamp(0.0, 1.0),
      toward: r.deal.toward,
      shootCut: r.shootCut,
    );
  }

  /// The scene's bottom inset (design px), for the hint's geometry.
  double _inset = 0;

  List<Widget> _scene(SceneMetrics m) {
    _inset = m.inset;
    final geo = M4TreeCutGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = _traineeBox(geo);
    final spotting = _run.station == M4TreeCutStation.spot && _run.spot == null && !_freeze && !_move.isAnimating && !reasonOpen && _card == null;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(child: CustomPaint(painter: M4TreeCutWorldPainter(geo: geo, tree: _treeState))),
              ),
              for (final (id, from, big) in _drops)
                Positioned.fill(
                  key: ValueKey('drop-$id'),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: Duration(milliseconds: quiet ? 1 : 750),
                      builder: (_, v, _) => CustomPaint(
                        painter: M4TreeCutDropPainter(from: from, to: Offset(from.dx.clamp(30.0, 290.0), geo.groundY - 8 - (id % 3) * 3), v: v, big: big),
                      ),
                    ),
                  ),
                ),
              Positioned.fromRect(
                key: const ValueKey('mate'),
                rect: geo.mateBox,
                child: LinemanFigure(look: _mateLook, mode: _run.roped ? LinemanMode.hold : LinemanMode.idle, quiet: true),
              ),
              Positioned.fill(
                key: const ValueKey('strap'),
                child: IgnorePointer(child: CustomPaint(painter: M4TreeCutStrapPainter(box: tb, geo: geo))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (!_freeze)
        for (final (id, p) in _taps)
          Positioned(
            key: ValueKey('tap-$id'),
            left: p.dx - 14,
            top: p.dy - 14,
            width: 28,
            height: 28,
            child: IgnorePointer(child: _Ring(quiet: quiet)),
          ),
      // Where he could stand: three plain rings, the same for each.
      if (spotting)
        for (final s in M4TreeCutSpot.values)
          Positioned.fromRect(
            key: ValueKey('spot-${s.name}'),
            rect: geo.spotRect(s),
            child: IgnorePointer(child: _Ring(quiet: quiet, big: true)),
          ),
      if (_stamp && !_freeze)
        Positioned(
          key: const ValueKey('stamp'),
          left: M4TreeCutGeo.px - 20,
          top: geo.lineY - 110,
          child: IgnorePointer(child: _StampPop(text: M4TreeCutLines.stampDone, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4TreeCutLines.sceneLabel,
          child: GestureDetector(
            key: _sceneKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('fall'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: Duration(milliseconds: quiet ? 1 : 900),
              builder: (_, v, _) => CustomPaint(painter: M4TreeCutFallPainter(geo: geo, at: geo.spotRect(_to).center, v: v)),
            ),
          ),
        ),
    ];
  }

  // --- the gesture hint ----------------------------------------------------------
  /// The level waits for a touch on the scene or its controls (the decks and
  /// the zoomed reason card carry their own hints).
  bool get _hintWaiting {
    if (_intro || _ended || _busy || _freeze || struckOut || _card != null) return false;
    if (reasonOpen || tableBusy || coworkerOnScreen || _move.isAnimating || _holding || _run.ended) return false;
    return !(_run.station == M4TreeCutStation.clear && _stamp);
  }

  /// A scene rect (design px) in global pixels, through the touch layer.
  Rect? _global(Rect r) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  /// A sweep over every open option the same way (left to right on the
  /// scene, then the buttons); a tap only on the one way forward.
  HintSpec? _hint() {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final geo = M4TreeCutGeo.forScene(box.size.height, _inset);
    final r = _run;
    // With animations off the kit rests a still hand between the first two
    // options. That fits a row of buttons, but on this scattered scene it
    // would sit on one answer, so the scene sweeps show no hint then.
    final still = MediaQuery.disableAnimationsOf(context);
    List<Rect> scene(Iterable<Rect> rects) => [for (final x in rects) ?_global(x)]..sort((a, b) => a.center.dx.compareTo(b.center.dx));
    List<Rect> keys(Iterable<GlobalKey> ks) => [for (final k in ks) ?HintSpec.globalRectOf(k)];
    HintSpec? sweep(List<Rect> opts) => opts.length < 2 ? null : HintSpec.sweep(opts);
    HintSpec? sceneSweep(List<Rect> opts) => still ? null : sweep(opts);
    switch (r.station) {
      case M4TreeCutStation.trim:
        return sceneSweep(scene([for (final q in r.standing) geo.pieceRect(q)]));
      case M4TreeCutStation.rope:
        if (_tool == null) return sweep(keys([for (final t in r.deal.tray) _toolKeys[t]!]));
        // A tool in hand: how to use it (tap the limb) — the same for either tool.
        final limb = _global(geo.limbRect);
        return limb == null ? null : HintSpec.tap(limb.center);
      case M4TreeCutStation.spot:
        return sceneSweep(scene([for (final s in M4TreeCutSpot.values) geo.spotRect(s)]));
      case M4TreeCutStation.cut:
        if (r.freed && !r.lowered) return sweep(keys([_lowerKey, _letGoKey]));
        final open = [
          for (final m in M4TreeCutMark.values)
            if (!r.cuts.contains(m) && (!r.freed || m == M4TreeCutMark.collar)) geo.markRect(m),
        ];
        if (open.length == 1) {
          final one = _global(open.single);
          return one == null ? null : HintSpec.tap(one.center);
        }
        // A plain span along the base of the limb, not the hidden cut places.
        return sceneSweep(scene([for (final k in const [0.0, 0.2, 0.4]) Rect.fromCenter(center: geo.limbAt(k), width: 24, height: 24)]));
      case M4TreeCutStation.clear:
        return sceneSweep([
          ...scene([
            for (final s in M4TreeCutShoot.values)
              if (!(r.shootCut && s == r.deal.toward)) geo.shootRect(s, toward: s == r.deal.toward),
          ]),
          ...keys([_clearKey]),
        ]);
    }
  }

  Object get _hintKey =>
      'tc-${_run.station.name}-${_run.gone.length}-${_tool?.name}-${_run.cuts.length}-${_run.lengthsDown}-${_run.shootCut}-${_run.slips}-$coworkerDone';

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.ended;
    final st = _run.station;
    final tray = handsOn && st == M4TreeCutStation.rope && !_run.roped;
    final rope = handsOn && st == M4TreeCutStation.cut && _run.freed && !_run.lowered;
    final clearBtn = handsOn && st == M4TreeCutStation.clear && !_stamp;
    final controls = tray || rope || clearBtn;
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
              labels: M4TreeCutLines.rounds,
              done: {for (var i = 0; i < st.index; i++) i, if (_run.cleared) 4},
              current: _run.cleared ? null : st.index,
              quiet: quiet,
            ),
            animation: _sceneMotion,
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            layers: (context, m) => _scene(m),
            overlays: [
              if (playing && !coworkerOpen)
                Positioned(
                  key: const ValueKey('docket'),
                  right: 12,
                  top: pad.top + 96,
                  child: const IgnorePointer(child: _DocketChip()),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (tray)
                Positioned(
                  key: const ValueKey('hud-tray'),
                  left: 10,
                  bottom: pad.bottom + 14,
                  // The tray's order is dealt (never always the rope first).
                  child: Row(
                    children: [
                      for (final (i, t) in _run.deal.tray.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _ToolChip(
                          key: _toolKeys[t],
                          label: t == M4TreeCutTool.rope ? M4TreeCutLines.rope : M4TreeCutLines.saw,
                          icon: t == M4TreeCutTool.rope ? Icons.gesture_rounded : Icons.carpenter_rounded,
                          selected: _tool == t,
                          onTap: () => _pickTool(t),
                        ),
                      ],
                    ],
                  ),
                ),
              if (rope)
                Positioned(
                  key: const ValueKey('hud-rope'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _HoldButton(key: _lowerKey, label: M4TreeCutLines.lower, progress: _hold, onDown: _holdStart, onUp: _holdEnd),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: DoBigButton(
                          key: _letGoKey,
                          label: M4TreeCutLines.letGo,
                          filled: false,
                          onDark: true,
                          onTapUp: (d) => unawaited(_letGo(d.globalPosition)),
                        ),
                      ),
                    ],
                  ),
                ),
              if (clearBtn)
                Positioned(
                  key: const ValueKey('hud-clear'),
                  left: 12,
                  bottom: pad.bottom + 12,
                  width: math.min(220, size.width * 0.55),
                  child: DoBigButton(
                    key: _clearKey,
                    label: M4TreeCutLines.clearOk,
                    filled: true,
                    onTapUp: (d) => unawaited(_checkClear(d.globalPosition)),
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (controls ? 76 : 12)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${st.name}'),
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
                  line: M4TreeCutLines.intro,
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

/// The docket: the job and that the line is dead (words a worker reads).
class _DocketChip extends StatelessWidget {
  const _DocketChip();

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
          Text(M4TreeCutLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4TreeCutLines.job, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          Text(M4TreeCutLines.permit, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E6B3A))),
        ],
      ),
    );
  }
}

/// A tool from his belt: tap to take it, then tap the limb.
class _ToolChip extends StatelessWidget {
  const _ToolChip({super.key, required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = selected ? SlmColors.gold300 : const Color(0x99FFFFFF);
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 52, minWidth: 112),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xF21C2E4A) : const Color(0xE60B1324),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ring, width: selected ? 2.4 : 1.4),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: ring),
              const SizedBox(width: 6),
              Text(label, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hold to let the rope out: it fills while held (one length).
class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.label, required this.progress, required this.onDown, required this.onUp});
  final String label;
  final Animation<double> progress;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: SlmColors.gold700),
                AnimatedBuilder(
                  animation: progress,
                  builder: (_, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.value.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Color(0x55FFFFFF)),
                  ),
                ),
                Center(child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain white ring (a tap, or a place he could stand).
class _Ring extends StatelessWidget {
  const _Ring({required this.quiet, this.big = false});
  final bool quiet;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (_, v, child) => Transform.scale(scale: 1.4 - 0.4 * v, child: Opacity(opacity: (0.4 + 0.6 * v).clamp(0.0, 1.0), child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: big ? const Color(0x33FFFFFF) : const Color(0x22FFFFFF),
          border: Border.all(color: const Color(0xEEFFFFFF), width: big ? 2.6 : 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3)],
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
