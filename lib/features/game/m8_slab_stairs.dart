import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'm8_slab_stairs_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_slab_stairs_world.dart' show M8BoardView, M8Kind, M8Look, M8Part, M8StairsGeo, M8Tile, M8TileKind, M8Zone, kM8Skies, kM8Step1Cap;

// Lesson 8.7 "ট্যারিফ অর্ডার: বিদ্যুতের দামের হিসাব", কাজ "বিলের সিঁড়ি"
// (pack do_8_7_a, rung 8.7/do/0, engineType m8_slab_stairs).
// A village verandah at dusk, three doorsteps dealt from three kinds (a closed
// house with 0 units, a slab jump, an MVCA month), never the same kind twice
// in a row and at least one slab. The customer holds his bill out; the trainee
// explains it on an "explain board" (the lineman's own sketch on the bill's
// back) and a tray of tiles: the fixed charge, 2-4 unit blocks that add up to
// this month's units, the MVCA tile when billed, and on 1-2 doorsteps a
// 'PF পেনাল্টি' trap tile.
//
// The core verb: stack unit blocks up a slab staircase (drag a tile onto the
// board). Rules (lesson 8.7 points 1 and 2):
//  fixed charge -> the floor (even at 0 units);
//  a block -> step 1 while room remains in its 102 units; a block that would
//    pass 102 is dragged onto the cutter and cut where step 1 fills to exactly
//    102 (the cut point is never marked; a live readout shows the lower
//    piece); the lower piece stays on step 1, the upper piece goes to step 2;
//  once step 1 is full every block goes to step 2;
//  MVCA -> the band along the top, its own band.
//  A block on step 2 while step 1 has room, a whole straddling block on
//  step 1, a cut at the wrong unit (or a cut that was not needed), the PF
//  tile on the bill = slips. The PF tile may stay in the tray or go to the bin.
//
// The tower done, the customer pushes (closed house: cut the fixed charge;
// MVCA: remove that band; slab: why double the units, triple the bill?). The
// answer is press-and-hold on the part that explains (floor / step 2 / MVCA
// band): the right part shows the lesson's line (and, on a slab doorstep, last
// month's tower as a dotted outline on step 1), then the reason. Dragging a
// part to the bin or holding the wrong part = a slip.
//
// No deadly in lesson 8.7 (ruling M8-1): everything is billing, nothing live
// is touched; every mistake is a slip, three slips strike out.
//
// The coworker (lesson myth 1 inside his shortcut, M8-14) comes once a play on
// doorstep 2 or 3 (dealt), right after the customer's push; both the hold and
// the bin call holdForCoworker(). Listening = slip (X2/B1).
//
// Gesture hands (how, never what): tray idle: a sweep over all tiles, then a
// straight-up 48 dp lift nudge on the tray's centre tile; a block on the
// cutter: a 40 dp nudge from the strip's left end; the upper piece waiting:
// the lift nudge; the push: a sweep over all tower parts and the bin (never
// a hold ring). Off during the intro, the move between doorsteps, the praise
// window, the coworker, cards and results.

// ============================================================================
// Content
// ============================================================================

abstract final class M8SlabStairsLines {
  static const title = 'বিলের সিঁড়ি';
  // DRAFT wording — owner (M6-12 / M8-14): every line below until the owner
  // gives the natural wording.
  static const intro = 'গ্রাহক বিল হাতে দাঁড়িয়ে — এত বিল কেন? সিঁড়ি এঁকে বুঝিয়ে দিন!';

  // The guide's task (tap him: the next of the pool, from the start).
  static const askBuild = 'বিলটা সাজিয়ে দেখান।';
  static const tapBuild1 = 'টাইলগুলো বোর্ডে তুলুন।';
  static const tapBuild2 = 'বিলের অংশগুলো সিঁড়িতে বসান।';
  static const askPush = 'ওকে বোঝান — যে অংশটা উত্তর দেয়, সেটা চেপে ধরুন।';
  static const tapPush1 = 'বোর্ডের কোন অংশে ওর প্রশ্নের উত্তর আছে?';
  static const buildTasks = [askBuild, tapBuild1, tapBuild2];
  static const pushTasks = [askPush, tapPush1];
  static const tasks = [...buildTasks, ...pushTasks];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The tiles and the bill (a worker's own words; English digits).
  static const fixedTile = 'ফিক্সড চার্জ';
  static const fixedUnit = 'টাকা/kVA/মাস';
  static String blockTile(int units) => enDigits('$units ইউনিট');
  static const mvcaTile = 'MVCA';
  static const pfTile = 'PF পেনাল্টি';
  static String thisMonth(int n) => enDigits('এ মাসে: $n ইউনিট');
  static String lastMonth(int n) => enDigits('আগের মাসে: $n ইউনিট');
  static final String step1Label = enDigits('প্রথম $kM8Step1Cap ইউনিট');
  static const step2Label = 'পরের ইউনিট';
  static const cutBack = 'ফেরত';
  static String readout(int lower, int upper) => enDigits('নিচে $lower · ওপরে $upper ইউনিট');
  static const sceneLabel = 'বিলের দাওয়া';
  static const boardLabel = 'বোঝানোর বোর্ড';

  static String doorName(M8Kind k) => switch (k) {
        M8Kind.closed => 'বন্ধ বাড়ি',
        M8Kind.slab => 'ইউনিট লাফ',
        M8Kind.mvca => 'MVCA-র মাস',
      };

  // The customer's words (silent captions, M8-10): the complaint at the door,
  // then his push when the tower is done.
  static const complaintClosed = 'বাড়ি তো বন্ধ ছিল, তাও বিল এসেছে কেন?';
  static String complaintSlab(int last, int now) => enDigits('গত মাসে $last ইউনিট পুড়েছে, এ মাসে $now — বিল তিনগুণ কেন?');
  static const complaintMvca = 'বিলে এই বাড়তি চার্জ কীসের?';
  static const pushClosed = 'ফিক্সড চার্জটা কেটে দিন!';
  static const pushSlab = 'ইউনিট দ্বিগুণ, বিল তিনগুণ কেন?';
  static const pushMvca = 'এই বাড়তি চার্জ রিডারের কারচুপি — সরিয়ে দিন!';

  static String complaint(M8Kind k, int last, int now) => switch (k) {
        M8Kind.closed => complaintClosed,
        M8Kind.slab => complaintSlab(last, now),
        M8Kind.mvca => complaintMvca,
      };
  static String push(M8Kind k) => switch (k) {
        M8Kind.closed => pushClosed,
        M8Kind.slab => pushSlab,
        M8Kind.mvca => pushMvca,
      };

  /// What the right part says (lesson 8.7, the live lines; a caption).
  static String explain(M8Kind k) => switch (k) {
        M8Kind.closed => 'বাড়ি বন্ধ থাকলেও লোড বরাদ্দ রাখার জন্য এই টাকা দিতে হয়।',
        M8Kind.slab => enDigits('প্রথম $kM8Step1Cap ইউনিট সস্তা, পরের ইউনিটগুলো দামী।'),
        M8Kind.mvca => 'কয়লার দাম বাড়লে MVCA যোগ হয় — এটা সরকারি নিয়ম।',
      };

  // The reasons (the right ones state the lesson's rule for the part just
  // shown; the wrong ones are myths and field excuses).
  static String whyQ(M8Kind k) => switch (k) {
        M8Kind.closed => 'ফিক্সড চার্জ কেন কাটলেন না?',
        M8Kind.slab => 'এই ইউনিটগুলো কেন উপরের ধাপে গেল?',
        M8Kind.mvca => 'MVCA কেন রেখে দিলেন?',
      };
  static const _whyRightClosed = ['বাড়ি বন্ধ থাকলেও লোড বরাদ্দ রাখার টাকা দিতে হয়', 'ব্যবহার না করলেও কোম্পানির পরিকাঠামোর খরচ ওঠে এতে'];
  static final _whyRightSlab = [enDigits('প্রথম $kM8Step1Cap ইউনিটের পরের ইউনিটগুলোর দাম বেশি হয়'), 'ওপরের ধাপের ইউনিট বেশি দামী, তাই ওপরে বসেছে'];
  static const _whyRightMvca = ['কয়লার দাম বাড়লে MVCA যোগ হয়, এটা সরকারি নিয়ম', 'MVCA রিডারের কারচুপি নয়, নিয়মমাফিক চার্জ'];
  static List<String> whyRight(M8Kind k) => switch (k) {
        M8Kind.closed => _whyRightClosed,
        M8Kind.slab => _whyRightSlab,
        M8Kind.mvca => _whyRightMvca,
      };
  static const _whyWrongClosed = [
    'বাড়ি বন্ধ থাকলে কোনো রকম বিলই আসা উচিত নয় তো',
    'ফিক্সড চার্জ রিডার নিজের ইচ্ছেমতো বসিয়ে দেয় বিলে',
    'ফিক্সড চার্জ শুধু কারখানার বিলেই বসে, বাড়ির বিলে নয়',
    'ইউনিট না পুড়লে ফিক্সড চার্জও মকুব হয়ে যায়',
    'গ্রাহক বললে ফিক্সড চার্জ কেটে দেওয়া যেতে পারে',
  ];
  static const _whyWrongSlab = [
    'বিল বেশি দেখাতে রিডার ইউনিট ওপরে তুলে দিয়েছে',
    'ডিজিটাল মিটার ইউনিট বেশি গুনে ফেলেছে বলেই এমন',
    'সব ইউনিটের দাম একই, ধাপ শুধু দেখানোর জন্য আঁকা',
    'আগের মাসের বাকি ইউনিট ওপরে জমা হয়ে গেছে বলে',
    'পুরনো মিটারে ইউনিট কম ধরা হত, তাই এমন মনে হয়',
  ];
  static const _whyWrongMvca = [
    'রিডার ইচ্ছেমতো বাড়তি চার্জ ধরিয়ে দিয়েছে বিলে',
    'MVCA শুধু কারখানার বিলেই বসে থাকে, বাড়ির বিলে নয়',
    'গ্রাহক চাইলেই MVCA সরিয়ে দিতে হয় বিল থেকে',
    'MVCA মানে মিটারের মাসিক ভাড়ার বাড়তি টাকা',
    'MVCA ইউনিটের দাম কমিয়ে দেয়, তাই বিল কমে',
  ];
  static List<String> whyWrong(M8Kind k) => switch (k) {
        M8Kind.closed => _whyWrongClosed,
        M8Kind.slab => _whyWrongSlab,
        M8Kind.mvca => _whyWrongMvca,
      };
  static List<String> get allWhyRight => [for (final k in M8Kind.values) ...whyRight(k)];
  static List<String> get allWhyWrong => [for (final k in M8Kind.values) ...whyWrong(k)];

  // The careless coworker: his shortcut carries lesson myth 1 (M8-14).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  // DRAFT wording — owner: his push and the cards.
  static const coworker = CoworkerScript(
    line: 'বলে দাও ডিজিটাল মিটার বেশি ঘোরে, তাই বিল বেশি আসে — ঝামেলা মিটে যাবে।',
    exitLine: coworkerExit,
    right: [
      'না — ডিজিটাল মিটার সঠিক মাপে, সঠিক মাপাটা অপরাধ নয়',
      'না, পুরনো মিটারই স্লো হয়ে যেত, নতুনটা ঠিক মাপে',
      'না, মোবাইলে চার্জ দিলেও ডিজিটাল মিটার ঠিক রেকর্ড করে',
    ],
    wrong: [
      'হ্যাঁ, ডিজিটাল মিটারই গ্রাহকের বিল বাড়িয়ে দেয়',
      'হ্যাঁ, পুরনো মিটারেই ঠিক মাপ হত, নতুনে নয়, ওকে তাই বলো',
      'ঠিক বলেছ, নতুন মিটার একটু বেশিই ঘুরে যায়',
      'বলে দিই, মিটার বদলে ফেললেই বিল কমে যাবে',
      'হ্যাঁ, রিডারই বিলে কারচুপি করে, ওকে তাই বলো',
      'ঠিক, ঝামেলা না বাড়িয়ে ওটাই বলে দিই গ্রাহককে',
    ],
    asks: ['ওকে কী বলবেন?', 'কী করবেন?', askHim],
  );
  static const askHim = 'ওর কথা বলবেন?';
  static const callHeld = 'ঠিক! ডিজিটাল মিটার সঠিক মাপে — সঠিক মাপাটা অপরাধ নয়।';

  static const allSet = 'তিন বাড়ির বিল বুঝিয়ে দিলেন — গ্রাহকরা খুশি!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — বিলের হিসাব ধাপে ধাপে বুঝিয়ে দেখান।';

  // "আজ যা ধরলেন".
  static String caught(M8Kind k) => switch (k) {
        M8Kind.closed => 'বাড়ি বন্ধ হলেও ফিক্সড চার্জ লাগে',
        M8Kind.slab => 'স্ল্যাব: প্রথম ধাপ সস্তা, পরের ধাপ দামী',
        M8Kind.mvca => 'MVCA সরকারি নিয়ম, কারচুপি নয়',
      };
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip (the exit, two old asks, the
  /// quick-pass line).
  static const reused = {coworkerExit, 'ওকে কী বলবেন?', 'কী করবেন?', quick};

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        ...tapWhy.where((l) => !_oldWhyTaps.contains(l)),
        for (final k in M8Kind.values) whyQ(k),
        ...coworker.asks.where((a) => !reused.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M8SlabStairsMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused, ...tapWhy];
  static const _oldWhyTaps = {'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'};
}

abstract final class M8SlabStairsMistakes {
  static const _dir = 'assets/game/art/m8_slab_stairs';

  // DRAFT wording — owner (M6-12). Lesson 8.7 point 1 (0-based 0) is the
  // fixed charge, point 2 (1) the energy charge by slab; the PF line and the
  // MVCA line are pro tips (no numbered point).
  static const step2Early = DoMistake(
    key: '8.7/m8_slab_stairs/step-2-early',
    textBn: 'ধাপ 1-এ এখনও জায়গা আছে — প্রথম 102 ইউনিট সস্তা, তাই আগে ওখানে ভরতে হয়।',
    art: '$_dir/steps.svg',
    lessonPoint: 1,
  );
  static const wholeOnStep1 = DoMistake(
    key: '8.7/m8_slab_stairs/whole-on-step-1',
    textBn: 'এই ব্লক পুরোটা ধাপ 1-এ ধরে না — 102 ইউনিটে কেটে নিচের অংশ ধাপ 1-এ, ওপরের অংশ ধাপ 2-এ।',
    art: '$_dir/steps.svg',
    lessonPoint: 1,
  );
  static const step1Full = DoMistake(
    key: '8.7/m8_slab_stairs/step-1-full',
    textBn: 'ধাপ 1 ভরে গেছে — বাকি ইউনিট এবার ধাপ 2-এ।',
    art: '$_dir/steps.svg',
    lessonPoint: 1,
  );
  static const wrongCut = DoMistake(
    key: '8.7/m8_slab_stairs/wrong-cut',
    textBn: 'কাটাটা ঠিক জায়গায় হয়নি — ধাপ 1 যেখানে ঠিক 102 ইউনিটে ভরে, সেখানেই কাটতে হয়।',
    art: '$_dir/cut.svg',
    lessonPoint: 1,
  );
  static const cutNotNeeded = DoMistake(
    key: '8.7/m8_slab_stairs/cut-not-needed',
    textBn: 'এখানে কাটার দরকার নেই — ব্লকটা পুরোটাই একটা ধাপে ধরে যায়।',
    art: '$_dir/cut.svg',
    lessonPoint: 1,
  );
  static const pfOnBill = DoMistake(
    key: '8.7/m8_slab_stairs/pf-on-house-bill',
    textBn: 'বাড়ির বিলে PF পেনাল্টি বসে না — ওটা পাওয়ার ফ্যাক্টর কম থাকা ইন্ডাস্ট্রিয়াল গ্রাহকের জন্য।',
    art: '$_dir/pf.svg',
  );
  static const fixedToBin = DoMistake(
    key: '8.7/m8_slab_stairs/fixed-to-bin',
    textBn: 'ফিক্সড চার্জ কাটা যায় না — বাড়ি বন্ধ থাকলেও লোড বরাদ্দ রাখার জন্য এই টাকা দিতে হয়।',
    art: '$_dir/fixed.svg',
    lessonPoint: 0,
  );
  static const mvcaToBin = DoMistake(
    key: '8.7/m8_slab_stairs/mvca-to-bin',
    textBn: 'MVCA ফেলে দেওয়ার নয় — কয়লার দাম বাড়লে এটা যোগ হয়, মিটার রিডারের কারচুপি নয়, সরকারি নিয়ম।',
    art: '$_dir/mvca.svg',
  );
  static const unitsToBin = DoMistake(
    key: '8.7/m8_slab_stairs/units-to-bin',
    textBn: 'ইউনিটগুলো আসল ব্যবহার, ফেলা যায় না — প্রথম 102 ইউনিট সস্তা, পরেরগুলো দামী।',
    art: '$_dir/bin.svg',
    lessonPoint: 1,
  );
  // Never fires (a closed house shows only the floor part); not in `all`.
  static const wrongPartClosed = DoMistake(
    key: '8.7/m8_slab_stairs/wrong-part-closed',
    textBn: 'এই অংশ নয় — বাড়ি বন্ধ থাকলেও যে টাকা আসে, সেই ফিক্সড চার্জটা মেঝেতে।',
    art: '$_dir/fixed.svg',
    lessonPoint: 0,
  );
  static const wrongPartSlab = DoMistake(
    key: '8.7/m8_slab_stairs/wrong-part-slab',
    textBn: 'এই অংশ নয় — বিল তিনগুণ হওয়ার কারণ ওপরের ধাপ, যেখানে ইউনিটের দাম বেশি।',
    art: '$_dir/steps.svg',
    lessonPoint: 1,
  );
  static const wrongPartMvca = DoMistake(
    key: '8.7/m8_slab_stairs/wrong-part-mvca',
    textBn: 'এই অংশ নয় — বাড়তি চার্জটা ওপরের MVCA ব্যান্ডে, ওটাই ওকে বোঝাতে হবে।',
    art: '$_dir/mvca.svg',
  );

  // Listening to the coworker (lesson myth 1 and its reality; X2/B1).
  static const pushListen = DoMistake(
    key: '8.7/m8_slab_stairs/push-listen',
    textBn: 'একেবারেই নয়। পুরনো মিটার বয়সে স্লো হয়ে যেত — ডিজিটাল মিটার সঠিক মাপে, সঠিক মাপাটা অপরাধ নয়।',
    art: '$_dir/meter.svg',
  );

  static DoMistake wrongPart(M8Kind k) => switch (k) {
        M8Kind.closed => wrongPartClosed,
        M8Kind.slab => wrongPartSlab,
        M8Kind.mvca => wrongPartMvca,
      };

  static DoMistake toBin(M8Part p) => switch (p) {
        M8Part.floor => fixedToBin,
        M8Part.top => mvcaToBin,
        M8Part.step1 || M8Part.step2 => unitsToBin,
      };

  static const List<DoMistake> all = [
    step2Early,
    wholeOnStep1,
    step1Full,
    wrongCut,
    cutNotNeeded,
    pfOnBill,
    fixedToBin,
    mvcaToBin,
    unitsToBin,
    wrongPartSlab,
    wrongPartMvca,
    pushListen,
  ];
}

// ============================================================================
// Deal and rules
// ============================================================================

/// One doorstep: its kind, this month's units, last month's (slab), the
/// customer's look, and the 8 tray slots.
@immutable
class M8Doorstep {
  const M8Doorstep({required this.kind, required this.units, required this.last, required this.tiles, required this.look});

  final M8Kind kind;
  final int units;

  /// Last month's units (slab only).
  final int? last;

  /// The tray's 8 slots (null = empty), tiles in dealt places.
  final List<M8Tile?> tiles;
  final M8Look look;

  List<M8Tile> get blocks => [for (final t in tiles) if (t != null && t.kind == M8TileKind.block) t];
  bool get hasMvca => tiles.any((t) => t?.kind == M8TileKind.mvca);
  bool get hasPf => tiles.any((t) => t?.kind == M8TileKind.pf);

  /// The part that explains the customer's push.
  M8Part get answer => switch (kind) {
        M8Kind.closed => M8Part.floor,
        M8Kind.slab => M8Part.step2,
        M8Kind.mvca => M8Part.top,
      };
}

@immutable
class M8StairsDeal {
  const M8StairsDeal({required this.doorsteps, required this.coworkerStep});
  final List<M8Doorstep> doorsteps;

  /// The doorstep he comes at (2nd or 3rd; index 1 or 2).
  final int coworkerStep;
}

/// No subset of [parts] lands within 5 units of 102 (so every cut falls at
/// least 5 units from both ends of its block, in any order the blocks go on).
bool m8ClearOf102(List<int> parts) {
  for (var mask = 1; mask < (1 << parts.length); mask++) {
    var s = 0;
    for (var i = 0; i < parts.length; i++) {
      if (mask & (1 << i) != 0) s += parts[i];
    }
    if ((s - kM8Step1Cap).abs() < 5) return false;
  }
  return true;
}

List<int> _partition(int n, int k, math.Random rng) {
  for (var tries = 0; tries < 400; tries++) {
    final rest = n - 14 * k;
    final cuts = [for (var i = 0; i < k - 1; i++) rng.nextInt(rest + 1)]..sort();
    final parts = <int>[];
    var prev = 0;
    for (final c in [...cuts, rest]) {
      parts.add(14 + c - prev);
      prev = c;
    }
    parts.shuffle(rng);
    if (parts.every((x) => x <= 110) && m8ClearOf102(parts)) return parts;
  }
  // Never reached for the dealt ranges; a fixed good split keeps the rule.
  final base = n ~/ k;
  final parts = [for (var i = 0; i < k; i++) base + (i == 0 ? n - base * k : 0)];
  return parts;
}

M8Look _dealLook(math.Random rng) => M8Look(
      skin: rng.nextInt(kM8Skins.length),
      shirt: rng.nextInt(kM8Shirts.length),
      hair: rng.nextInt(2),
      elder: rng.nextInt(4) == 0,
      light: rng.nextInt(kM8Skies.length),
    );

M8Doorstep m8DealDoorstep(M8Kind kind, {required bool pf, required math.Random rng, M8Look? look}) {
  var units = 0;
  int? last;
  List<int> blocks = const [];
  var mvca = false;
  switch (kind) {
    case M8Kind.closed:
      break;
    case M8Kind.slab:
      last = const [80, 90, 100][rng.nextInt(3)];
      final lo = math.max(136, (1.7 * last).round());
      final hi = math.min(240, (2.4 * last).round());
      units = lo + rng.nextInt(hi - lo + 1);
      blocks = _partition(units, 3 + rng.nextInt(2), rng);
    case M8Kind.mvca:
      mvca = true;
      if (rng.nextBool()) {
        // At or under the step-1 cap: every block fits step 1.
        units = 45 + rng.nextInt(51);
        blocks = _partition(units, 2 + rng.nextInt(2), rng);
      } else {
        units = 125 + rng.nextInt(76);
        blocks = _partition(units, 3 + rng.nextInt(2), rng);
      }
  }
  final all = <M8Tile>[
    const M8Tile(M8TileKind.fixed),
    for (final b in blocks) M8Tile(M8TileKind.block, units: b),
    if (mvca) const M8Tile(M8TileKind.mvca),
    if (pf) const M8Tile(M8TileKind.pf),
  ];
  final slots = [for (var i = 0; i < 8; i++) i]..shuffle(rng);
  final tiles = List<M8Tile?>.filled(8, null);
  for (var i = 0; i < all.length; i++) {
    tiles[slots[i]] = all[i];
  }
  return M8Doorstep(kind: kind, units: units, last: last, tiles: tiles, look: look ?? _dealLook(rng));
}

/// Three kinds, never the same twice in a row, at least one slab.
List<List<M8Kind>> m8KindOrders() => [
      for (final a in M8Kind.values)
        for (final b in M8Kind.values)
          for (final c in M8Kind.values)
            if (a != b && b != c && [a, b, c].contains(M8Kind.slab)) [a, b, c],
    ];

/// His doorstep is 1 or 2, never a closed house (his line is about the meter).
int _coworkerStep(List<M8Kind> kinds, math.Random rng) {
  final ok = [for (final i in const [1, 2]) if (kinds[i] != M8Kind.closed) i];
  return ok[rng.nextInt(ok.length)];
}

M8StairsDeal m8StairsDeal(math.Random rng) {
  final orders = m8KindOrders();
  final kinds = orders[rng.nextInt(orders.length)];
  // The PF trap sits on 1-2 of the 3 doorsteps.
  final want = 1 + rng.nextInt(2);
  final pfAt = ([0, 1, 2]..shuffle(rng)).take(want).toSet();
  // A fresh customer and dusk light for each doorstep.
  return M8StairsDeal(
    doorsteps: [for (var i = 0; i < 3; i++) m8DealDoorstep(kinds[i], pf: pfAt.contains(i), rng: rng)],
    coworkerStep: _coworkerStep(kinds, rng),
  );
}

/// What a dropped tile did.
enum M8Drop { placed, sprang, loaded, discarded, slip }

/// What a cut did.
enum M8Cut { none, cut, slip }

/// What a hold or a bin drop did in the push.
enum M8Push { none, right, slip }

/// The play state (pure logic).
class M8StairsRun {
  M8StairsRun(this.deal) {
    _load();
  }

  final M8StairsDeal deal;

  int index = 0;
  int slips = 0;

  /// The tray's slots, the block on the cutter, its slot.
  late List<M8Tile?> tray;
  M8Tile? cutter;
  int cutterSlot = -1;

  bool floorOn = false;
  bool topOn = false;
  final List<int> step1 = [];
  final List<int> step2 = [];

  /// The customer has pushed (the tower is done) / the right part was held.
  bool pushing = false;
  bool answered = false;
  final List<String> caught = [];

  M8Doorstep get door => deal.doorsteps[index.clamp(0, deal.doorsteps.length - 1)];
  bool get done => index >= deal.doorsteps.length;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  int get fill1 => step1.fold(0, (a, b) => a + b);
  int get units2 => step2.fold(0, (a, b) => a + b);

  /// The slot holding the upper piece waiting for step 2 (or -1).
  int get upperSlot => tray.indexWhere((t) => t != null && t.upper);

  /// Every slot that still holds a tile.
  List<int> get trayIndexes => [for (var i = 0; i < tray.length; i++) if (tray[i] != null) i];

  /// All tiles are placed: the PF trap may stay in the tray (or be binned).
  bool get buildDone =>
      !done &&
      cutter == null &&
      floorOn &&
      (!door.hasMvca || topOn) &&
      tray.every((t) => t == null || t.kind == M8TileKind.pf);

  void _load() {
    if (done) return;
    tray = [...door.tiles];
    cutter = null;
    cutterSlot = -1;
    floorOn = false;
    topOn = false;
    step1.clear();
    step2.clear();
    pushing = false;
    answered = false;
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// The tile in [slot] dropped on [zone].
  (M8Drop, DoMistake?) dropTile(int slot, M8Zone zone) {
    final t = slot >= 0 && slot < tray.length ? tray[slot] : null;
    if (done || pushing || cutter != null || t == null) return (M8Drop.sprang, null);
    switch (t.kind) {
      case M8TileKind.fixed:
        if (zone == M8Zone.bin) return (M8Drop.slip, _slip(M8SlabStairsMistakes.fixedToBin));
        if (zone != M8Zone.floor) return (M8Drop.sprang, null);
        floorOn = true;
        tray[slot] = null;
        return (M8Drop.placed, null);
      case M8TileKind.mvca:
        if (zone == M8Zone.bin) return (M8Drop.slip, _slip(M8SlabStairsMistakes.mvcaToBin));
        if (zone != M8Zone.top) return (M8Drop.sprang, null);
        topOn = true;
        tray[slot] = null;
        return (M8Drop.placed, null);
      case M8TileKind.pf:
        if (zone == M8Zone.none) return (M8Drop.sprang, null);
        tray[slot] = null;
        if (zone == M8Zone.bin) return (M8Drop.discarded, null);
        return (M8Drop.slip, _slip(M8SlabStairsMistakes.pfOnBill));
      case M8TileKind.block:
        switch (zone) {
          case M8Zone.step1:
            if (fill1 + t.units > kM8Step1Cap) {
              return (M8Drop.slip, _slip(fill1 >= kM8Step1Cap ? M8SlabStairsMistakes.step1Full : M8SlabStairsMistakes.wholeOnStep1));
            }
            step1.add(t.units);
            tray[slot] = null;
            return (M8Drop.placed, null);
          case M8Zone.step2:
            if (!t.upper && fill1 < kM8Step1Cap) return (M8Drop.slip, _slip(M8SlabStairsMistakes.step2Early));
            step2.add(t.units);
            tray[slot] = null;
            return (M8Drop.placed, null);
          case M8Zone.cutter:
            if (t.upper) return (M8Drop.sprang, null);
            cutter = t;
            cutterSlot = slot;
            tray[slot] = null;
            return (M8Drop.loaded, null);
          case M8Zone.bin:
            return (M8Drop.slip, _slip(M8SlabStairsMistakes.unitsToBin));
          default:
            return (M8Drop.sprang, null);
        }
    }
  }

  /// The block on the cutter cut so that [lower] units are on the lower piece.
  (M8Cut, DoMistake?) cut(int lower) {
    final b = cutter;
    if (b == null) return (M8Cut.none, null);
    if (lower < 1 || lower >= b.units) return (M8Cut.none, null);
    final need = kM8Step1Cap - fill1;
    final straddles = fill1 < kM8Step1Cap && fill1 + b.units > kM8Step1Cap;
    cutter = null;
    if (straddles && (lower - need).abs() <= 1) {
      step1.add(need);
      tray[cutterSlot] = M8Tile(M8TileKind.block, units: b.units - need, upper: true);
      return (M8Cut.cut, null);
    }
    // The whole block goes back to its slot.
    tray[cutterSlot] = b;
    return (M8Cut.slip, _slip(straddles ? M8SlabStairsMistakes.wrongCut : M8SlabStairsMistakes.cutNotNeeded));
  }

  /// Take the block off the cutter (no cost).
  void cutBack() {
    final b = cutter;
    if (b == null) return;
    tray[cutterSlot] = b;
    cutter = null;
  }

  /// The tower is done: the customer pushes; the PF tile, if left, is cleared.
  void startPush() {
    for (var i = 0; i < tray.length; i++) {
      if (tray[i]?.kind == M8TileKind.pf) tray[i] = null;
    }
    pushing = true;
  }

  /// The parts of the tower that exist now.
  List<M8Part> get parts => [
        if (floorOn) M8Part.floor,
        if (step1.isNotEmpty) M8Part.step1,
        if (step2.isNotEmpty) M8Part.step2,
        if (topOn) M8Part.top,
      ];

  /// A part pressed and held: the answer to the push.
  (M8Push, DoMistake?) hold(M8Part p) {
    if (!pushing || answered || !parts.contains(p)) return (M8Push.none, null);
    if (p == door.answer) {
      answered = true;
      caught.add(M8SlabStairsLines.caught(door.kind));
      return (M8Push.right, null);
    }
    return (M8Push.slip, _slip(M8SlabStairsMistakes.wrongPart(door.kind)));
  }

  /// A part dragged to the bin.
  (M8Push, DoMistake?) toBin(M8Part p) {
    if (!pushing || answered || !parts.contains(p)) return (M8Push.none, null);
    return (M8Push.slip, _slip(M8SlabStairsMistakes.toBin(p)));
  }

  /// Listened to the coworker.
  DoMistake pushSlip() => _slip(M8SlabStairsMistakes.pushListen);

  void next() {
    index++;
    _load();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   closed doorstep: 1 drag 2200 + push 3000 + reason 8200            ≈ 14000
///   slab doorstep: 4-5 drags 11000 + cut 3500 + upper 2200 + push + reason ≈ 28000
///   MVCA doorstep: 3-5 drags 9000 + cut half the time 1800 + push + reason ≈ 22000
///   a mix of three (~64 s) + the coworker once 9600 + 3 changes 3000   ≈ 77000
/// 85 % ≈ 65500 → 70 s (a builder's estimate; owner may tune after playtest).
const m8SlabStairsQuickMs = 70000;

@immutable
class M8SlabStairsPack {
  const M8SlabStairsPack({required this.id, required this.titleBn, this.quickMs = m8SlabStairsQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8SlabStairsPack> m8SlabStairsPacks = {
  'do_8_7_a': M8SlabStairsPack(id: 'do_8_7_a', titleBn: M8SlabStairsLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8SlabStairsProbe {
  static M8StairsRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M8SlabStairsPage extends StatefulWidget {
  const M8SlabStairsPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8SlabStairsPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8SlabStairsPage> createState() => _M8SlabStairsPageState();
}

class _M8SlabStairsPageState extends State<M8SlabStairsPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _StairsRunPage(
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

class _StairsRunPage extends ConsumerStatefulWidget {
  const _StairsRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8SlabStairsPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_StairsRunPage> createState() => _StairsRunPageState();
}

class _StairsRunPageState extends ConsumerState<_StairsRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8StairsRun _run;
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
  int _buildTaskN = 0;
  int _pushTaskN = 0;
  int _whyN = 0;

  /// The move from one doorstep to the next.
  var _between = false;

  /// What the customer (or, after the right part, the lineman's note) says.
  String _caption = '';
  var _note = false;
  var _ghost = false;

  /// A tile in hand (its slot, the tile centre in design px).
  int? _dragSlot;
  Offset _dragAt = Offset.zero;

  /// A tower part carried toward the bin.
  M8Part? _dragPart;

  /// The cutter's handle (design x) while it is dragged.
  var _cutDrag = false;
  double _cutX = 0;

  /// The part under a held finger.
  M8Part? _held;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M8StairsGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8StairsRun(m8StairsDeal(widget.rng));
    M8SlabStairsProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M8SlabStairsProbe.run, _run)) M8SlabStairsProbe.run = null;
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

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_between && !_run.done && !struckOut;

  bool get _atHisDoor => _run.index == _run.deal.coworkerStep;

  Future<void> _start() async {
    _clock.start();
    _startDoor();
  }

  void _startDoor() {
    final d = _run.door;
    setState(() {
      _wake++;
      _hintN = 0;
      _dragSlot = null;
      _dragPart = null;
      _cutDrag = false;
      _held = null;
      _ghost = false;
      _note = false;
      _caption = M8SlabStairsLines.complaint(d.kind, d.last ?? 0, d.units);
    });
    unawaited(_sayChain([M8SlabStairsLines.askBuild]));
    // A doorstep with nothing to build (never dealt) would push at once.
    _checkBuildDone();
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  /// The tower is done: the customer pushes.
  void _checkBuildDone() {
    if (!_run.buildDone || _run.pushing) return;
    _run.startPush();
    final d = _run.door;
    setState(() {
      _caption = M8SlabStairsLines.push(d.kind);
      _note = false;
      _wake++;
    });
    unawaited(Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _ended || _run.done || !_run.pushing || _run.answered || _card != null || coworkerOpen) return;
      unawaited(_sayChain([M8SlabStairsLines.askPush]));
    }));
    if (_atHisDoor && !coworkerDone && !coworkerDue) scheduleCoworker();
  }

  // --- hands on -----------------------------------------------------------------
  int? _tileAt(Offset p, M8StairsGeo geo) {
    for (final i in _run.trayIndexes) {
      if (geo.slot(i).inflate(3).contains(p)) return i;
    }
    return null;
  }

  M8Part? _partAt(Offset p, M8StairsGeo geo) {
    for (final part in const [M8Part.top, M8Part.floor, M8Part.step2, M8Part.step1]) {
      if (_run.parts.contains(part) && geo.partRect(part).inflate(2).contains(p)) return part;
    }
    return null;
  }

  double _lowerAt(double x, M8StairsGeo geo) {
    final u = _run.cutter?.units ?? 0;
    return ((x.clamp(geo.ruler.left, geo.ruler.right) - geo.ruler.left) / geo.ruler.width * u);
  }

  void _tapScene(Offset p, M8StairsGeo geo) {
    if (!_canPlay) return;
    if (_run.cutter != null && geo.back.inflate(6).contains(p)) {
      _tick();
      setState(() {
        _run.cutBack();
        _cutDrag = false;
        _wake++;
      });
      return;
    }
    // A tile or a part only answers a drag or a hold; a tap is a miss.
    _hints.missTap();
  }

  void _panStart(Offset p, M8StairsGeo geo) {
    _dragSlot = null;
    _dragPart = null;
    _cutDrag = false;
    if (!_canPlay) return;
    if (_run.cutter != null) {
      if (geo.handle(_cutX == 0 ? geo.ruler.left : _cutX).inflate(14).contains(p)) {
        setState(() {
          _cutDrag = true;
          _cutX = p.dx.clamp(geo.ruler.left, geo.ruler.right);
        });
      }
      return;
    }
    if (_run.pushing) {
      final part = _partAt(p, geo);
      if (part != null) {
        _tick('sounds/intro/click.ogg', 0.4);
        setState(() {
          _dragPart = part;
          _dragAt = p;
          _held = null;
        });
      }
      return;
    }
    final slot = _tileAt(p, geo);
    if (slot != null) {
      _tick('sounds/intro/click.ogg', 0.4);
      setState(() {
        _dragSlot = slot;
        _dragAt = p.translate(0, -M8StairsGeo.lift);
        _held = null;
      });
    }
  }

  void _panUpdate(Offset p, M8StairsGeo geo) {
    if (_cutDrag) {
      if (!_canPlay) {
        setState(() => _cutDrag = false);
        return;
      }
      setState(() => _cutX = p.dx.clamp(geo.ruler.left, geo.ruler.right));
      return;
    }
    if (_dragSlot != null) {
      if (!_canPlay) {
        setState(() => _dragSlot = null);
        return;
      }
      setState(() => _dragAt = p.translate(0, -M8StairsGeo.lift));
      return;
    }
    if (_dragPart != null) {
      if (!_canPlay) {
        setState(() => _dragPart = null);
        return;
      }
      setState(() => _dragAt = p);
    }
  }

  void _panEnd(Offset global) {
    final geo = _geoNow;
    if (geo == null) return;
    if (_cutDrag) {
      final x = _cutX;
      setState(() => _cutDrag = false);
      _doCut(x, geo, global);
      return;
    }
    final slot = _dragSlot;
    if (slot != null) {
      final at = _dragAt;
      setState(() => _dragSlot = null);
      _dropTile(slot, at, geo, global);
      return;
    }
    final part = _dragPart;
    if (part != null) {
      final at = _dragAt;
      setState(() => _dragPart = null);
      _dropPart(part, at, geo, global);
    }
  }

  void _cancelDrags() {
    if (_dragSlot != null || _dragPart != null || _cutDrag) {
      setState(() {
        _dragSlot = null;
        _dragPart = null;
        _cutDrag = false;
      });
    }
  }

  void _dropTile(int slot, Offset at, M8StairsGeo geo, Offset global) {
    if (!_canPlay) return;
    final zone = geo.zoneAt(at);
    if (zone == M8Zone.none) {
      // Empty ground: the tile springs back (a missed tap for the hand).
      _hints.missTap();
      return;
    }
    final tile = _run.tray[slot];
    final (res, m) = _run.dropTile(slot, zone);
    switch (res) {
      case M8Drop.sprang:
        _tick();
        _hints.missTap();
      case M8Drop.loaded:
        _tick('sounds/intro/drop.ogg', 0.5);
        setState(() {
          _cutX = geo.ruler.left;
          _wake++;
        });
        _stepDone();
      case M8Drop.discarded:
        _tick('sounds/intro/drop.ogg', 0.4);
        _stepDone();
        _checkBuildDone();
      case M8Drop.slip:
        setState(() => _wake++);
        unawaited(_levelDelta(-10, global, mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M8Drop.placed:
        HapticFeedback.mediumImpact();
        // A block on step 2 lands heavier.
        _cue(zone == M8Zone.step2 ? 'sounds/learn/ring_steel.ogg' : 'sounds/learn/dull_steel.ogg', volume: 0.6);
        _stepDone();
        if (tile?.kind != M8TileKind.pf) unawaited(_levelDelta(5, global, mood: GuideMood.glad));
        _checkBuildDone();
    }
  }

  void _doCut(double x, M8StairsGeo geo, Offset global) {
    if (!_canPlay || _run.cutter == null) return;
    final lower = _lowerAt(x, geo).round();
    final (res, m) = _run.cut(lower);
    switch (res) {
      case M8Cut.none:
        // Let go at an end: nothing is cut; the handle springs back.
        setState(() => _cutX = geo.ruler.left);
        _hints.missTap();
      case M8Cut.cut:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/ring_steel.ogg', volume: 0.6);
        setState(() => _cutX = 0);
        _stepDone();
        unawaited(_levelDelta(5, global, mood: GuideMood.glad));
      case M8Cut.slip:
        setState(() {
          _cutX = 0;
          _wake++;
        });
        unawaited(_levelDelta(-10, global, mood: GuideMood.warn));
        unawaited(_slip(m!));
    }
  }

  void _dropPart(M8Part part, Offset at, M8StairsGeo geo, Offset global) {
    if (!_canPlay) return;
    if (geo.zoneAt(at) != M8Zone.bin) {
      _hints.missTap();
      return;
    }
    // His doorstep: the bin waits for him too.
    if (_atHisDoor && holdForCoworker()) return;
    final (res, m) = _run.toBin(part);
    if (res != M8Push.slip) return;
    setState(() => _wake++);
    unawaited(_levelDelta(-10, global, mood: GuideMood.warn));
    unawaited(_slip(m!));
  }

  void _longStart(Offset p, Offset global, M8StairsGeo geo) {
    if (!_canPlay || _dragSlot != null || _dragPart != null || _cutDrag) return;
    if (!_run.pushing || _run.answered) {
      _hints.missTap();
      return;
    }
    final part = _partAt(p, geo);
    if (part == null) {
      _hints.missTap();
      return;
    }
    // His doorstep: the hold waits for him.
    if (_atHisDoor && holdForCoworker()) return;
    _tick();
    setState(() => _held = part);
    final (res, m) = _run.hold(part);
    switch (res) {
      case M8Push.none:
        break;
      case M8Push.slip:
        unawaited(_levelDelta(-10, global, mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M8Push.right:
        _rightAnswer();
    }
  }

  void _longEnd() {
    if (_held == null) return;
    setState(() => _held = null);
  }

  /// The right part held: its lesson line, last month's ghost on a slab, then
  /// the reason.
  void _rightAnswer() {
    _hush();
    final d = _run.door;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/ring_steel.ogg', volume: 0.7);
    setState(() {
      _caption = M8SlabStairsLines.explain(d.kind);
      _note = true;
      _ghost = d.kind == M8Kind.slab;
      _wake++;
    });
    _stepDone();
    putOnTable(15);
    final idx = _run.index;
    final kind = d.kind;
    unawaited(askReason(
      deal: () => dealChoices(M8SlabStairsLines.whyRight(kind), M8SlabStairsLines.whyWrong(kind), widget.rng),
      question: M8SlabStairsLines.whyQ(kind),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  Future<void> _goNext() async {
    if (_ended) return;
    setState(() => _between = true);
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 100 : 450));
    if (!mounted || _ended) return;
    setState(() {
      _run.next();
      _held = null;
      _ghost = false;
    });
    if (_run.done) {
      setState(() => _between = false);
      unawaited(_finish());
      return;
    }
    _startDoor();
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 100 : 400));
    if (mounted) setState(() => _between = false);
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
    if (mounted) unawaited(_goNext());
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8SlabStairsLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.done || _run.index > _run.deal.coworkerStep) return null;
    if (_run.index == _run.deal.coworkerStep && _run.answered) return null;
    if (!_atHisDoor || !_run.pushing || _intro || _card != null || tableBusy || _between || _dragSlot != null || _dragPart != null || _cutDrag || _held != null) {
      return false;
    }
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.pushSlip();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8SlabStairsLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8SlabStairsLines.callHeld, M8SlabStairsLines.askPush], mood: GuideMood.glad));
  }

  /// Tap the guide: the next task line of the phase's pool.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line;
    if (coworkerOpen) {
      line = nextCoworkerAsk();
    } else if (reasonOpen) {
      line = M8SlabStairsLines.tapWhy[_whyN++ % M8SlabStairsLines.tapWhy.length];
    } else if (_run.pushing) {
      line = M8SlabStairsLines.pushTasks[++_pushTaskN % M8SlabStairsLines.pushTasks.length];
    } else {
      line = M8SlabStairsLines.buildTasks[++_buildTaskN % M8SlabStairsLines.buildTasks.length];
    }
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
      _dragSlot = null;
      _dragPart = null;
      _cutDrag = false;
      _held = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8slab/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _wake++;
    });
    unawaited(_sayChain([_run.pushing ? M8SlabStairsLines.askPush : M8SlabStairsLines.askBuild]));
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
    await _say(!_run.passed ? M8SlabStairsLines.fail : (_quickBonus ? M8SlabStairsLines.quick : M8SlabStairsLines.allSet),
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
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_dragSlot != null || _dragPart != null || _cutDrag || _held != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    // The push: a sweep over every part of the tower and the bin, no ring.
    if (_run.pushing) {
      final rects = [for (final p in _run.parts) geo.partRect(p), geo.bin];
      return HintSpec.sweep(rects, space: HintSpace.scene);
    }
    // A block on the cutter: a short nudge from the strip's left end (never
    // from the cut point).
    if (_run.cutter != null) {
      return HintSpec.drag(Offset(geo.ruler.left + 8, geo.ruler.center.dy), toward: const Offset(1, 0), travel: 40, space: HintSpace.scene);
    }
    final up = _run.upperSlot;
    if (up >= 0) return HintSpec.drag(geo.slot(up).center, toward: const Offset(0, -1), travel: 48, space: HintSpace.scene);
    final idx = _run.trayIndexes;
    if (idx.isEmpty) return null;
    final centre = Offset(180, geo.trayTop + 52);
    final mid = ([...idx]..sort((a, b) => (geo.slot(a).center - centre).distance.compareTo((geo.slot(b).center - centre).distance))).first;
    if (idx.length >= 2 && n.isEven) {
      return HintSpec.sweep([for (final i in idx) geo.slot(i)], space: HintSpace.scene);
    }
    return HintSpec.drag(geo.slot(mid).center, toward: const Offset(0, -1), travel: 48, space: HintSpace.scene);
  }

  M8BoardView get _view => M8BoardView(
        floorOn: _run.floorOn,
        step1: List.unmodifiable(_run.step1),
        step2: List.unmodifiable(_run.step2),
        topOn: _run.topOn,
        ghost: _ghost ? _run.door.last : null,
        held: _held,
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8StairsGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final idx = math.min(_run.index, _run.deal.doorsteps.length - 1);
    final d = _run.door;
    final look = d.look;
    final loaded = _run.cutter;
    return [
      Positioned.fill(
        key: ValueKey('back-$idx'),
        child: RepaintBoundary(child: CustomPaint(painter: M8StairsBackPainter(geo: geo, light: look.light, closed: d.kind == M8Kind.closed))),
      ),
      Positioned.fill(
        key: ValueKey('customer-$idx'),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: M8CustomerPainter(geo: geo, look: look),
            foregroundPainter: M8BillPainter(
              geo: geo,
              units: d.units,
              last: d.last,
              mvca: d.hasMvca,
              thisMonth: M8SlabStairsLines.thisMonth(d.units),
              lastMonth: M8SlabStairsLines.lastMonth(d.last ?? 0),
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        key: ValueKey('caption-$idx'),
        rect: geo.caption,
        child: IgnorePointer(child: _Caption(text: _caption, note: _note)),
      ),
      Positioned.fill(
        key: ValueKey('board-$idx'),
        child: Semantics(
          label: M8SlabStairsLines.boardLabel,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M8BoardPainter(geo: geo, view: _view, fixedLabel: M8SlabStairsLines.fixedTile, step1Label: M8SlabStairsLines.step1Label, step2Label: M8SlabStairsLines.step2Label),
            ),
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('pad'),
        child: RepaintBoundary(child: CustomPaint(painter: M8CutterPadPainter(geo: geo, loaded: loaded != null))),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      // The tray: the tiles, or the cutter's ruler when a block is on it.
      Positioned.fromRect(
        key: const ValueKey('tray'),
        rect: geo.tray,
        child: const IgnorePointer(child: _TrayBed()),
      ),
      if (loaded == null)
        for (final i in _run.trayIndexes)
          Positioned.fromRect(
            key: ValueKey('tile-$idx-$i'),
            rect: geo.slot(i),
            child: Opacity(opacity: _dragSlot == i ? 0.3 : 1, child: IgnorePointer(child: _TileFace(tile: _run.tray[i]!))),
          )
      else
        Positioned.fill(
          key: const ValueKey('cutter'),
          child: IgnorePointer(child: _CutterUi(geo: geo, tile: loaded, cutX: _cutX == 0 ? geo.ruler.left : _cutX, lower: _lowerAt(_cutX == 0 ? geo.ruler.left : _cutX, geo).round())),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8SlabStairsLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (d) => _panEnd(d.globalPosition),
            onPanCancel: _cancelDrags,
            onLongPressStart: _run.pushing && !_run.answered ? (d) => _longStart(d.localPosition, d.globalPosition, geo) : null,
            onLongPressEnd: _run.pushing && !_run.answered ? (_) => _longEnd() : null,
            onLongPressCancel: _run.pushing && !_run.answered ? _longEnd : null,
          ),
        ),
      ),
      // The tile in hand, or the part carried toward the bin.
      if (_dragSlot != null && _run.tray[_dragSlot!] != null)
        Positioned(
          key: const ValueKey('drag-tile'),
          left: _dragAt.dx - 40,
          top: _dragAt.dy - 21,
          width: 80,
          height: 42,
          child: IgnorePointer(child: _TileFace(tile: _run.tray[_dragSlot!]!, lifted: true)),
        ),
      if (_dragPart != null)
        Positioned(
          key: const ValueKey('drag-part'),
          left: _dragAt.dx - 30,
          top: _dragAt.dy - 14,
          width: 60,
          height: 28,
          child: IgnorePointer(child: _PartChip(part: _dragPart!)),
        ),
      // The next doorstep: a short dip to dark.
      if (_between)
        Positioned.fill(
          key: ValueKey('fade-$idx'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 0.55),
              duration: Duration(milliseconds: quiet ? 80 : 300),
              builder: (_, v, _) => ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
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
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_between && !deckUp && !coworkerOpen && _card == null && !_run.done;
    // The guide stands just above the tile tray (screen px).
    final guideBottom = M8StairsGeo.trayH * size.width / 360 + pad.bottom * 0.6 + 2;
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
              labels: [for (final s in _run.deal.doorsteps) M8SlabStairsLines.doorName(s.kind)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _dragSlot == null && _dragPart == null && !_cutDrag && _held == null,
            hintKey: '${_run.index}/${_run.pushing}/${_run.cutter != null}/$_steps/${_run.slips}',
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
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : guideBottom, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
                  sound: FailSound.thud,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M8SlabStairsLines.intro,
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

/// The customer's words, or (after the right part) the lineman's note.
class _Caption extends StatelessWidget {
  const _Caption({required this.text, required this.note});
  final String text;
  final bool note;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: note ? const Color(0xF2FFF6DA) : const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: note ? SlmColors.gold300 : const Color(0xFF9AA2A8), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Center(
          child: Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF26303D), height: 1.25),
          ),
        ),
      ),
    );
  }
}

/// The tray's wooden bed.
class _TrayBed extends StatelessWidget {
  const _TrayBed();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF233A5E), Color(0xFF142540)]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
    );
  }
}

/// A tile: the fixed charge, a unit block, MVCA or the PF penalty.
class _TileFace extends StatelessWidget {
  const _TileFace({required this.tile, this.lifted = false});
  final M8Tile tile;
  final bool lifted;

  String get _label => switch (tile.kind) {
        M8TileKind.fixed => '${M8SlabStairsLines.fixedTile} · ${M8SlabStairsLines.fixedUnit}',
        M8TileKind.block => M8SlabStairsLines.blockTile(tile.units),
        M8TileKind.mvca => M8SlabStairsLines.mvcaTile,
        M8TileKind.pf => M8SlabStairsLines.pfTile,
      };

  Color get _color => switch (tile.kind) {
        M8TileKind.fixed => const Color(0xFF7FB3D5),
        M8TileKind.block => const Color(0xFFE9B949),
        M8TileKind.mvca => const Color(0xFF8E6BBF),
        M8TileKind.pf => const Color(0xFFF1A3B0),
      };

  Color get _ink => switch (tile.kind) {
        M8TileKind.fixed => const Color(0xFF12324A),
        M8TileKind.block => const Color(0xFF3A2A06),
        M8TileKind.mvca => Colors.white,
        M8TileKind.pf => const Color(0xFF5A1426),
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3A2A16), width: 1.4),
          boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 9 : 3, offset: Offset(0, lifted ? 5 : 1))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Center(
            child: tile.kind == M8TileKind.fixed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(fit: BoxFit.scaleDown, child: Text(M8SlabStairsLines.fixedTile, maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: _ink, height: 1.1))),
                      FittedBox(fit: BoxFit.scaleDown, child: Text(M8SlabStairsLines.fixedUnit, maxLines: 1, style: bangla(fontSize: 9, fontWeight: FontWeight.w700, color: _ink, height: 1.1))),
                    ],
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_label, maxLines: 1, style: bangla(fontSize: tile.kind == M8TileKind.block ? 13 : 11.5, fontWeight: FontWeight.w900, color: _ink, height: 1.1)),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A tower part carried toward the bin (a small chip, all alike).
class _PartChip extends StatelessWidget {
  const _PartChip({required this.part});
  final M8Part part;

  @override
  Widget build(BuildContext context) {
    final color = switch (part) {
      M8Part.floor => const Color(0xFF7FB3D5),
      M8Part.step1 => const Color(0xFFE9B949),
      M8Part.step2 => const Color(0xFFD9822B),
      M8Part.top => const Color(0xFF8E6BBF),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3A2A16), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
    );
  }
}

/// The cutter's ruler in the tray: the block's unit strip, its cut line and
/// scissors handle, the live readout, and the back button.
class _CutterUi extends StatelessWidget {
  const _CutterUi({required this.geo, required this.tile, required this.cutX, required this.lower});
  final M8StairsGeo geo;
  final M8Tile tile;
  final double cutX;
  final int lower;

  @override
  Widget build(BuildContext context) {
    final u = tile.units;
    final r = geo.readout;
    final b = geo.back;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRect(
          rect: r,
          child: Center(
            child: Text(M8SlabStairsLines.readout(lower, u - lower), maxLines: 1, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _RulerPainter(ruler: geo.ruler, units: u, cutX: cutX))),
        Positioned.fromRect(
          rect: geo.handle(cutX),
          child: Semantics(
            label: 'কাটার কাঁচি',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F1DE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A2018), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.content_cut_rounded, size: 20, color: Color(0xFF2A2018)),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: b,
          child: Semantics(
            label: M8SlabStairsLines.cutBack,
            button: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF3A4A66),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.8), width: 1.2),
              ),
              child: Center(child: Text(M8SlabStairsLines.cutBack, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory))),
            ),
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  const _RulerPainter({required this.ruler, required this.units, required this.cutX});
  final Rect ruler;
  final int units;
  final double cutX;

  @override
  void paint(Canvas c, Size size) {
    final cx = cutX.clamp(ruler.left, ruler.right);
    final lowerR = Rect.fromLTRB(ruler.left, ruler.top, cx, ruler.bottom);
    final upperR = Rect.fromLTRB(cx, ruler.top, ruler.right, ruler.bottom);
    c.drawRect(lowerR, Paint()..color = const Color(0xFFE9B949));
    c.drawRect(upperR, Paint()..color = const Color(0xFFD9822B));
    c.drawRect(
      ruler,
      Paint()
        ..color = const Color(0xFF3A2A16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    final tick = Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 1.2;
    for (var u = 10; u < units; u += 10) {
      final x = ruler.left + ruler.width * u / units;
      c.drawLine(Offset(x, ruler.bottom), Offset(x, ruler.bottom - (u % 20 == 0 ? 12 : 7)), tick);
      if (u % 20 == 0) {
        final tp = TextPainter(
          text: TextSpan(text: '$u', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF3A2A06))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(x - tp.width / 2, ruler.top + 3));
      }
    }
    // The cut line.
    c.drawLine(
      Offset(cx, ruler.top - 4),
      Offset(cx, ruler.bottom + 4),
      Paint()
        ..color = const Color(0xFFC62828)
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.cutX != cutX || old.units != units || old.ruler != ruler;
}
