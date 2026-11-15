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
import 'm6_ug_cable_lay_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm6_ug_cable_lay_world.dart' show M6Bend, M6UgGeo;

// Lesson 6.5 "আন্ডারগ্রাউন্ড (UG) কেবিল: লুকানো নেটওয়ার্ক", কাজ 1
// "বাঁক বুঝে কেবিল পাতা" (pack do_6_5_a, engineType m6_ug_cable_lay). A new
// 11 kV XLPE cable (docket '11 kV · XLPE · A2XFY', the size a placeholder) is
// laid in a town lane trench. Five stations in one play:
//
//  বাঁক × 3 (three of the route's four bends, dealt order: the DTR plinth, the
//    lane corner, under the culvert, up the riser): drag the bend's belly
//    handle to open or tighten the curve (the wall on the inside of the turn
//    stops it), then 'বসান'. The docket's minimum-bending-radius ring has no
//    number: hold the docket and the ring floats under the finger to compare
//    (lesson 6.5 pro tip 2). The start curve is dealt tight or already wide.
//    Not tighter than the ring → ◆; tighter → a slip, the crease cut-away
//    and the ring ghosted in the corner for the retry. One dealt bend asks
//    "কেন বাঁকটা এমন রাখলেন?".
//  আর্মার: both cable ends side by side, alike; drag each end's armour earth
//    lug onto its earth point (pro tip 3: "কেবিলের দুই প্রান্তেই"). The
//    sign-off chip 'পাতার কাজ শেষ' is live from the start: with both ends
//    earthed ◆ → reason; one end = a slip (owner dec 5, IS 1255 cl 13.1);
//    neither end = DEADLY (ruling M6-1, N6: a broken earth path signed off).
//  টার্মিনেশন: a termination-kit box and a phone at the riser's foot, the same
//    size, dealt sides. Phone (the certified jointer) ◆ → reason; fitting the
//    kit himself = a slip (point 3 safety tip; myth 2).
//
// The careless coworker once a play (spec coworkerPushBn, wording DRAFT):
// before 'বসান' on a dealt bend ("টাইট করে বাঁকিয়ে দাও"), at the armour
// station's first lead pick-up or sign-off ("এক দিকে আর্থ করলেই চলবে"), or at
// the termination (lesson myth 2 word for word + "কিটটা তুমিই লাগিয়ে দাও").
// Each pushes a slip-class act, so listening is a slip (ruling X2/B1); the
// decisive control waits for him (holdForCoworker).
//
// Deadly: only the armour signed off with neither end earthed (N6). Slips: a
// bend placed tighter than the ring (tightened from a wide start is its own
// card), armour earthed at one end, the kit fitted himself, and listening to
// him. Three slips strike out. Built on the shared kit (GAME_LEVEL_PLAYBOOK.md).
// Gesture hands: the docket's hold ring and a tiny nudge of the belly handle
// along the bend's own diagonal, wider and tighter by turns (never far enough
// to carry a wide start across the ring); after a drag a sweep over the handle
// and 'বসান'; a sweep over both leads and the chip; an upward drag on a tapped
// lead; a sweep over the kit and the phone — never the answer.
//
// The wall on the inside of a turn stops the handle silently (no clunk), so
// the stop is not a 'safe here' tell. Wider than the ring is never wrong in
// the lesson, so dragging to the wall still places a bend right: the ring is
// the thing taught, not a trap (open question for the director and owner).

// ============================================================================
// Content
// ============================================================================

enum M6UgStage { bend, armour, termination }

/// The two cable sizes on the docket (placeholders): each its own ring.
enum M6CableSize { big, small }

/// The coworker's push (one per play).
enum M6UgPush { bend, armour, myth }

/// What a station's reason asks about.
enum M6UgWhy { bend, armour, termination }

/// The docket's ring radius per cable size (design px; no number on screen).
const m6UgRing = <M6CableSize, double>{M6CableSize.big: 96, M6CableSize.small: 74};

/// A wide start is dealt at least this far over the ring (design px).
const kM6WideMargin = 20.0;

/// The belly handle's hint nudge (scene px along the bend's diagonal). One
/// nudge moves the radius by kM6HintTravel / kM6Belly (≈ 14.5), less than
/// [kM6WideMargin]: copying it never carries a wide start under the ring.
const kM6HintTravel = 6.0;

/// The hint nudge for bend [k] on its [n]th drag showing: along the bend's
/// own diagonal (the only way the handle moves), wider on even showings and
/// tighter on odd ones, so the hand shows how, never which way.
Offset m6UgHandleNudge(M6Bend k, int n) => M6UgGeo.inward(k) * (n.isEven ? kM6HintTravel : -kM6HintTravel);

/// The stations: three bends, the armour ends, the termination.
const m6UgStations = 5;

abstract final class M6UgCableLines {
  static const title = 'বাঁক বুঝে কেবিল পাতা';

  // DRAFT wording — owner (ruling M6-12).
  static const intro = 'নতুন ইউজি কেবিল পাততে হবে — বাঁকে সাবধান, ভেতরের স্তর যেন না ভাঙে!';
  static const rule = 'ডকেট চেপে ধরলে রিংটা আঙুলের নিচে আসে।';
  static const askBend = 'বাঁকটা ঠিক করে কেবিল বসান।';
  static const askArmour = 'আর্মারের আর্থ লিড ঝুলছে। কাজ শেষ করুন।';
  static const askTerm = 'কেবিলের মাথায় টার্মিনেশন লাগবে। কী করবেন?';
  static const tasks = [askBend, askArmour, askTerm];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  static String ask(M6UgStage s) => switch (s) {
        M6UgStage.bend => askBend,
        M6UgStage.armour => askArmour,
        M6UgStage.termination => askTerm,
      };

  // On-screen labels (a worker's own words).
  static const place = 'বসান';
  static const signOff = 'পাতার কাজ শেষ';
  static const docketTitle = 'ডকেট';
  static const docketCable = '11 kV · XLPE · A2XFY';
  // Placeholder sizes (lesson 6.5 gives no sizes; owner dec 13 accepted the
  // ring scales as designed).
  static String docketSize(M6CableSize s) => switch (s) {
        M6CableSize.big => '3C × 240 sq mm',
        M6CableSize.small => '3C × 120 sq mm',
      };
  static const kitLabel = 'টার্মিনেশন কিট';
  static const sceneLabel = 'কেবিলের ট্রেঞ্চ';
  static const docketLabel = 'ডকেট — চেপে ধরুন';
  static const stations = ['বাঁক 1', 'বাঁক 2', 'বাঁক 3', 'আর্মার', 'টার্মিনেশন'];

  // The reasons (DRAFT): the right ones fit what was done; the wrong ones
  // are field excuses and the lesson's myth 2.
  static const whyQ = <M6UgWhy, String>{
    M6UgWhy.bend: 'কেন বাঁকটা এমন রাখলেন?',
    M6UgWhy.armour: 'আর্মার আর্থ কেন দিলেন?',
    M6UgWhy.termination: 'টার্মিনেশন কেন জয়েন্টারের হাতে?',
  };
  static const whyRight = <M6UgWhy, List<String>>{
    M6UgWhy.bend: [
      'রিংয়ের চেয়ে টাইট বাঁকে ইনসুলেশন ক্ষতিগ্রস্ত হয়',
      'টাইট বাঁকে ভেতরের স্ক্রিন ক্ষতিগ্রস্ত হয়',
      'রিংয়ের সমান বা চওড়া বাঁকে ভেতরটা ঠিক থাকে',
    ],
    M6UgWhy.armour: [
      'দুই প্রান্তে আর্থে ফল্ট কারেন্টের নিরাপদ পথ হয়',
      'দুই মাথায় আর্থ থাকলে ফল্ট কারেন্ট নিরাপদে নামে',
    ],
    M6UgWhy.termination: [
      'HT জয়েন্টিং বিশেষ কাজ, সার্টিফিকেশন লাগে',
      'ইউজি টার্মিনেশনে প্রশিক্ষিত, সার্টিফায়েড হাত চাই',
    ],
  };
  static const whyWrong = <M6UgWhy, List<String>>{
    M6UgWhy.bend: [
      'মোটা কেবিল, যত খুশি বাঁকানো যায়, কিছু হয় না',
      'জায়গা কম হলে টাইট বাঁক দিলেও চলে যায়',
      'আর্মার আছে, তাই ভেতরের স্তরে কিছু হবে না',
      'টাইট বাঁকে কেবিল কম লাগে, খরচও বেঁচে যায়',
      'নতুন কেবিল, এখনও চালু হয়নি — তাই ভয় নেই',
      'বাঁকটা দেখতে সুন্দর হলেই কাজটা ঠিক হলো',
    ],
    M6UgWhy.armour: [
      'এক দিকে আর্থ দিলেই আর্মারের কাজ হয়ে যায়',
      'আর্মার শুধু খোঁড়াখুঁড়ি থেকে বাঁচায়, আর কিছু না',
      'নতুন কেবিলে আর্মার আর্থের কোনো দরকার নেই',
      'বাইরে জ্যাকেট তো আছে, আর্থ না দিলেও চলে',
      'আর্থ দিলে কেবিল তাড়াতাড়ি গরম হয়ে যায়',
    ],
    M6UgWhy.termination: [
      'ওভারহেড আর ইউজি কেবিলের জয়েন্টিং তো একই',
      'কিটের গায়ে নিয়ম লেখা থাকে, যে কেউ পারে',
      'একটু ধুলো বা ঘাম লাগলে জয়েন্টের কিছু হয় না',
      'জয়েন্টার ডাকলে শুধু শুধু সময় নষ্ট হয়',
      'টেপ পেঁচিয়ে দিলেই টার্মিনেশনের কাজ চলে',
    ],
  };

  // The careless coworker (one push a play). DRAFT wording — owner; the
  // termination push quotes lesson 6.5 myth 2 word for word.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const myth2 = 'ওভারহেড লাইনের জয়েন্টিং আর ইউজি কেবিলের জয়েন্টিং একই।';
  static const coworkerBend = CoworkerScript(
    line: 'জায়গা কম, এখানে টাইট করে বাঁকিয়ে দাও — মোটা কেবিল, কিছু হবে না!',
    exitLine: coworkerExit,
    right: ['না, রিংয়ের চেয়ে টাইট বাঁকাব না', 'না, টাইট বাঁকে ভেতরের স্তর ভাঙে', 'না, বেন্ডিং রেডিয়াস মেনেই বাঁকাব'],
    wrong: [
      'ঠিক, মোটা কেবিল, কিছু হবে না',
      'আচ্ছা, জায়গা কম, টাইটই করি',
      'হ্যাঁ, এখানে টেনে টাইট করে দিই',
      'ঠিক আছে, তাড়াতাড়ি বাঁকিয়ে দিই',
      'হ্যাঁ, বাঁক টাইট হলে ক্ষতি নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে টাইট করে বাঁকাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerArmour = CoworkerScript(
    line: 'আর্মার এক দিকে আর্থ করলেই চলবে, চলো ফিরি!',
    exitLine: coworkerExit,
    right: ['না, দুই প্রান্তেই আর্থ দেব', 'না, এক দিকে আর্থে কাজ শেষ নয়', 'না, দুই মাথা আর্থ করে তবে ফিরব'],
    wrong: [
      'ঠিক, এক দিকেই যথেষ্ট, চলো',
      'আচ্ছা, এক মাথা দিয়েই ফিরি',
      'হ্যাঁ, অন্য দিকটা পরে হবে',
      'ঠিক আছে, দেরি হয়ে যাচ্ছে',
      'হ্যাঁ, নতুন কেবিল, ভয় নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে এক দিকে আর্থই যথেষ্ট। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerMyth = CoworkerScript(
    line: '$myth2 কিটটা তুমিই লাগিয়ে দাও!',
    exitLine: coworkerExit,
    right: ['না, সার্টিফায়েড জয়েন্টার ডাকব', 'না, ইউজি জয়েন্টিং আলাদা কাজ', 'না, প্রশিক্ষণ ছাড়া কিট লাগাব না'],
    wrong: [
      'ঠিক, দুটো তো একই, আমিই লাগাই',
      'আচ্ছা, কিট খুলে লাগিয়ে দিই',
      'হ্যাঁ, জয়েন্টার ডাকার দরকার নেই',
      'ঠিক আছে, ওভারহেডে তো করেছি',
      'হ্যাঁ, কিটে তো নিয়ম লেখা আছে',
    ],
    asks: ['কী করবেন?', 'ও বলছে কিটটা নিজেই লাগাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6UgPush p) => switch (p) {
        M6UgPush.bend => coworkerBend,
        M6UgPush.armour => coworkerArmour,
        M6UgPush.myth => coworkerMyth,
      };
  static const allCoworkers = [coworkerBend, coworkerArmour, coworkerMyth];

  static String callHeld(M6UgPush p) => switch (p) {
        M6UgPush.bend => 'ঠিক! জায়গা কম বলে টাইট বাঁক নয়।',
        M6UgPush.armour => 'ঠিক! ওর কথায় কাজ ফেলে ফেরা নয়।',
        M6UgPush.myth => 'ঠিক! ইউজি জয়েন্টিং আলাদা, বিশেষ কাজ।',
      };

  static const allSet = 'কেবিল পাতা নিখুঁত — বাঁক, আর্মার, টার্মিনেশন সব ঠিক!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ডকেটের রিং মিলিয়ে, ধাপে ধাপে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtBends = 'কোনো বাঁক রিংয়ের চেয়ে টাইট নয়';
  static const caughtArmour = 'দুই প্রান্তেই আর্মার আর্থ';
  static const caughtJointer = 'টার্মিনেশন সার্টিফায়েড জয়েন্টারের হাতে';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (not recorded yet; the director records them
  /// with tool/rival_clip.py once the owner gives the wording).
  static List<String> get newRivalLines => [coworkerBend.line, coworkerArmour.line, coworkerMyth.line];

  /// The guide's new spoken lines (DRAFT, for the owner's wording and clips).
  static List<String> get newGuideLines => [
        intro,
        rule,
        ...tasks,
        ...whyQ.values,
        for (final p in M6UgPush.values) callHeld(p),
        for (final c in allCoworkers) ...c.asks.where((a) => a != 'কী করবেন?' && a != 'ওর কথা শুনবেন, না নিয়ম?'),
        allSet,
        fail,
      ];
}

abstract final class M6UgCableMistakes {
  static const _dir = 'assets/game/art/m6_ug_cable_lay';

  // DRAFT wording — owner. Lesson points (0-based): 0 = the cable's layers
  // (insulation, screen, armour: what a tight bend or a loose armour harms),
  // 2 = termination and jointing (the specialised work).
  static const bendTight = DoMistake(
    key: '6.5/m6_ug_cable_lay/bend-tight',
    textBn: 'বাঁকটা রিংয়ের চেয়ে টাইট! বেন্ডিং রেডিয়াসের চেয়ে বেশি বাঁকালে কেবিলের ভেতরের ইনসুলেশন বা স্ক্রিন ক্ষতিগ্রস্ত হতে পারে।',
    art: '$_dir/bend_crease.svg',
    lessonPoint: 0,
  );
  static const bendTightened = DoMistake(
    key: '6.5/m6_ug_cable_lay/bend-tightened',
    textBn: 'বাঁকটা আগেই রিংয়ের চেয়ে চওড়া ছিল — টেনে টাইট করে দিলেন! রিংয়ের চেয়ে টাইট বাঁকে ভেতরের ইনসুলেশন বা স্ক্রিন ক্ষতিগ্রস্ত হয়।',
    art: '$_dir/bend_crease.svg',
    lessonPoint: 0,
  );
  static const pushBend = DoMistake(
    key: '6.5/m6_ug_cable_lay/push-bend',
    textBn: 'জায়গা কম বা মোটা কেবিল — কোনো অজুহাতেই রিংয়ের চেয়ে টাইট বাঁক নয়। ভেতরের ইনসুলেশন বা স্ক্রিন ক্ষতিগ্রস্ত হতে পারে।',
    art: '$_dir/bend_crease.svg',
    lessonPoint: 0,
  );
  static const armourOne = DoMistake(
    key: '6.5/m6_ug_cable_lay/armour-one-end',
    textBn: 'আর্মার মাত্র এক প্রান্তে আর্থ! কেবিলের দুই প্রান্তেই আর্মার আর্থ করতে হয় (IS 1255) — এটাই ফল্ট কারেন্টের নিরাপদ পথ।',
    art: '$_dir/armour_one.svg',
    lessonPoint: 0,
  );
  static const pushArmour = DoMistake(
    key: '6.5/m6_ug_cable_lay/push-armour',
    textBn: 'এক দিকে আর্থ করে ফেরা চলে না! আর্মার দুই প্রান্তেই আর্থ করতে হয় (IS 1255) — নইলে ফল্ট কারেন্টের নিরাপদ পথ থাকে না।',
    art: '$_dir/armour_one.svg',
    lessonPoint: 0,
  );
  // Ruling M6-1 (N6): a broken earth path signed off = deadly.
  static const armourNone = DoMistake(
    key: '6.5/m6_ug_cable_lay/armour-none',
    textBn: 'আর্মার কোনো প্রান্তেই আর্থিং করা নেই, তাও সই করে দিলেন! ফল্ট কারেন্টের নিরাপদ পথ না থাকলে পুরো আর্মার ও সংলগ্ন ধাতু প্রাণঘাতী হয়ে ওঠে!',
    art: '$_dir/armour_none.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const selfFit = DoMistake(
    key: '6.5/m6_ug_cable_lay/self-fit',
    textBn: 'টার্মিনেশন নিজে লাগাবেন না! হাই-ভোল্টেজ কেবিল জয়েন্টিং বিশেষায়িত কাজ — আলাদা প্রশিক্ষণ আর সার্টিফিকেশন লাগে। জয়েন্টার ডাকুন।',
    art: '$_dir/jointer.svg',
    lessonPoint: 2,
  );
  static const pushMyth = DoMistake(
    key: '6.5/m6_ug_cable_lay/push-myth',
    textBn: 'ওভারহেড আর ইউজি জয়েন্টিং এক নয়! ইউজি-তে বৈদ্যুতিক ফিল্ড নিয়ন্ত্রণ, আর্দ্রতা প্রতিরোধ আর স্তরের পুনর্গঠন লাগে — জয়েন্টার ডাকুন।',
    art: '$_dir/jointer.svg',
    lessonPoint: 2,
  );

  static DoMistake push(M6UgPush p) => switch (p) {
        M6UgPush.bend => pushBend,
        M6UgPush.armour => pushArmour,
        M6UgPush.myth => pushMyth,
      };

  static const List<DoMistake> all = [bendTight, bendTightened, pushBend, armourOne, pushArmour, armourNone, selfFit, pushMyth];
}

/// One bend of the route.
@immutable
class M6BendDeal {
  const M6BendDeal({required this.kind, required this.rMin, required this.rMax, required this.r0});
  final M6Bend kind;

  /// The docket's ring (the minimum bending radius), the room the wall
  /// leaves, the start curve.
  final double rMin;
  final double rMax;
  final double r0;

  /// The start curve is already at least the ring.
  bool get wide => r0 >= rMin;
}

@immutable
class M6UgDeal {
  const M6UgDeal({required this.size, required this.bends, required this.push, required this.pushBend, required this.whyBend, required this.kitSlot});
  final M6CableSize size;

  /// The three bends in visiting order.
  final List<M6BendDeal> bends;

  /// The coworker's push; on a bend push, the bend (0..2) he comes on.
  final M6UgPush push;
  final int pushBend;

  /// The bend (0..2) whose placing asks the reason.
  final int whyBend;

  /// The slot (0 left, 1 right) the kit box stands in; the phone in the other.
  final int kitSlot;

  double get ring => m6UgRing[size]!;

  /// The station (0..4) the coworker comes at.
  int get coworkerStation => switch (push) {
        M6UgPush.bend => pushBend,
        M6UgPush.armour => 3,
        M6UgPush.myth => 4,
      };
}

M6UgDeal m6UgDeal(math.Random rng) {
  final size = rng.nextBool() ? M6CableSize.big : M6CableSize.small;
  final rMin = m6UgRing[size]!;
  final kinds = ([...M6Bend.values]..shuffle(rng)).take(3).toList();
  // At least one start tight and one already wide each play.
  final wide = [true, false, rng.nextBool()]..shuffle(rng);
  final bends = <M6BendDeal>[
    for (var i = 0; i < 3; i++)
      () {
        final rMax = math.min(150.0, rMin + 28 + rng.nextInt(28));
        final r0 = wide[i]
            ? rMin + kM6WideMargin + rng.nextInt((rMax - rMin - kM6WideMargin - 4).floor() + 1)
            : rMin - 18 - rng.nextInt(20);
        return M6BendDeal(kind: kinds[i], rMin: rMin, rMax: rMax, r0: r0.toDouble());
      }(),
  ];
  return M6UgDeal(
    size: size,
    bends: bends,
    push: M6UgPush.values[rng.nextInt(3)],
    pushBend: rng.nextInt(3),
    whyBend: rng.nextInt(3),
    kitSlot: rng.nextInt(2),
  );
}

/// The play state (pure logic).
class M6UgRun {
  M6UgRun(this.deal) {
    _loadBend();
  }
  final M6UgDeal deal;

  int index = 0;
  int slips = 0;
  int stationSlips = 0;
  int bendSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The station's right move is in (its reason or the next station next).
  var roundDone = false;

  // A bend.
  double r = 0;

  /// The coworker made this bend tight (it no longer started wide).
  var _pushedTight = false;

  /// After a slip: the ring ghosted in the corner; the crease cut-away at the
  /// belly of a bend of this radius until the curve is moved.
  var ghost = false;
  double? creaseAt;

  // The armour ends bonded (0 the plinth, 1 the riser).
  final Set<int> bonded = {};

  M6UgStage get stage => index < 3 ? M6UgStage.bend : (index == 3 ? M6UgStage.armour : M6UgStage.termination);
  M6BendDeal get bend => deal.bends[index.clamp(0, 2)];
  bool get done => index >= m6UgStations;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => stationSlips == 0;
  bool get _open => !ended && !roundDone;

  void _loadBend() {
    if (index < 3) r = bend.r0;
    _pushedTight = false;
    ghost = false;
    creaseAt = null;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stationSlips++;
    return m;
  }

  /// The belly handle asks for radius [v]: clamped between the tightest pull
  /// and the wall. True if the wall stopped it.
  bool setRadius(double v) {
    if (!_open || stage != M6UgStage.bend) return false;
    final b = bend;
    final next = v.clamp(kM6RLow, b.rMax).toDouble();
    if (next != r) creaseAt = null;
    r = next;
    return v >= b.rMax;
  }

  /// 'বসান': not tighter than the ring → right; tighter → a slip (the ring
  /// ghosted for the retry).
  DoMistake? place() {
    if (!_open || stage != M6UgStage.bend) return null;
    final b = bend;
    if (r < b.rMin) {
      bendSlips++;
      ghost = true;
      creaseAt = r;
      return _slip(b.wide && !_pushedTight ? M6UgCableMistakes.bendTightened : M6UgCableMistakes.bendTight);
    }
    roundDone = true;
    if (index == 2 && bendSlips == 0) _tag(M6UgCableLines.caughtBends);
    return null;
  }

  /// End [i]'s armour lug bolted to its earth point.
  void bond(int i) {
    if (_open && stage == M6UgStage.armour) bonded.add(i);
  }

  /// 'পাতার কাজ শেষ': both ends earthed → right; one end a slip; neither
  /// end deadly (M6-1, N6).
  DoMistake? signOff() {
    if (!_open || stage != M6UgStage.armour) return null;
    if (bonded.isEmpty) return deadly = M6UgCableMistakes.armourNone;
    if (bonded.length < 2) return _slip(M6UgCableMistakes.armourOne);
    roundDone = true;
    _tag(M6UgCableLines.caughtArmour);
    return null;
  }

  /// The kit box picked up: fitting the termination himself, a slip.
  DoMistake? fitKit() {
    if (!_open || stage != M6UgStage.termination) return null;
    return _slip(M6UgCableMistakes.selfFit);
  }

  /// The phone: the certified jointer called.
  bool callJointer() {
    if (!_open || stage != M6UgStage.termination) return false;
    roundDone = true;
    _tag(M6UgCableLines.caughtJointer);
    return true;
  }

  /// Listened to him (every push here is slip-class). On a bend he bends it
  /// tight there and then.
  DoMistake listened(M6UgPush p) {
    if (p == M6UgPush.bend && stage == M6UgStage.bend && _open) {
      r = math.max(kM6RLow, bend.rMin - 30);
      _pushedTight = true;
      bendSlips++;
      ghost = true;
      creaseAt = r;
    }
    return _slip(M6UgCableMistakes.push(p));
  }

  void next() {
    index++;
    stationSlips = 0;
    roundDone = false;
    _loadBend();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   bend × 3: hold the docket and compare ~2500, a drag ~1500, 'বসান'
///     ~1500, the advance ~1100                       ≈ 6600 × 3 = 19800
///   one bend reason ~8200
///   armour: two drags, the chip ≈ 4500 + reason ~8200
///   termination: one tap 1500 + reason ~8200
///   the coworker once ≈ 9600                                    ≈ 60000
/// 85 % ≈ 51000 → 50 s. (Owner question: quick-bonus times.)
const m6UgCableQuickMs = 50000;

@immutable
class M6UgCablePack {
  const M6UgCablePack({required this.id, required this.titleBn, this.quickMs = m6UgCableQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6UgCablePack> m6UgCablePacks = {
  'do_6_5_a': M6UgCablePack(id: 'do_6_5_a', titleBn: M6UgCableLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M6UgCablePage extends StatefulWidget {
  const M6UgCablePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6UgCablePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6UgCablePage> createState() => _M6UgCablePageState();
}

class _M6UgCablePageState extends State<M6UgCablePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _UgRunPage(
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

class _UgRunPage extends ConsumerStatefulWidget {
  const _UgRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6UgCablePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_UgRunPage> createState() => _UgRunPageState();
}

class _UgRunPageState extends ConsumerState<_UgRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6UgRun _run;
  late final int _seed = _run.deal.whyBend * 7 + _run.deal.push.index;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _praise = LineBag(LearnFeedbackLines.right);

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
  var _ruleSaid = false;

  /// A right bend with no reason: the short pause before the next station.
  var _advancing = false;

  // The finger on the scene.
  int? _ptr;
  Offset _downAt = Offset.zero;
  double _moved = 0;
  ({Offset from, double r0})? _grab;
  int? _lug;
  Offset? _lugAt;

  /// The bend was moved by the player (the hint changes).
  var _dragged = false;

  /// A lead that was tapped, not dragged (its hint: an upward drag).
  int? _tappedLug;

  /// The docket held: the ring under the finger (scene px).
  Offset? _ringAt;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _docketKey = GlobalKey();
  final _handleKey = GlobalKey();
  final _actKey = GlobalKey();
  final _lugKeys = [GlobalKey(), GlobalKey()];
  int _hintN = 0;
  int _steps = 0;
  M6UgGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6UgRun(m6UgDeal(widget.rng));
  }

  @override
  LevelContext get deathCtx => widget.ctx;
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

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && !_advancing;

  String get _task => M6UgCableLines.ask(_run.stage);

  Future<void> _start() async {
    _clock.start();
    _startStation();
  }

  void _startStation() {
    setState(() {
      _wake++;
      _grab = null;
      _lug = null;
      _lugAt = null;
      _ringAt = null;
      _dragged = false;
      _tappedLug = null;
      _advancing = false;
    });
    final first = !_ruleSaid;
    _ruleSaid = true;
    unawaited(_sayChain([if (first) M6UgCableLines.rule, _task]));
    if (_run.index == _run.deal.coworkerStation) scheduleCoworker();
  }

  // --- hands on -----------------------------------------------------------------
  void _down(PointerDownEvent e) {
    if (_ptr != null) return;
    _ptr = e.pointer;
    _downAt = e.localPosition;
    _moved = 0;
    final geo = _geoNow;
    if (!_canPlay || geo == null) return;
    final p = e.localPosition;
    switch (_run.stage) {
      case M6UgStage.bend:
        if (geo.handleHit(_run.bend.kind, _run.r).contains(p)) {
          HapticFeedback.selectionClick();
          setState(() => _grab = (from: p, r0: _run.r));
        }
      case M6UgStage.armour:
        for (var i = 0; i < 2; i++) {
          if (!_run.bonded.contains(i) && geo.lugHit(i).contains(p)) {
            // His item's decisive control: the first lead pick-up waits for him.
            if (holdForCoworker()) return;
            HapticFeedback.selectionClick();
            setState(() {
              _lug = i;
              _lugAt = geo.lugRest(i);
              _tappedLug = null;
            });
            return;
          }
        }
      case M6UgStage.termination:
        break;
    }
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _ptr) return;
    _moved = math.max(_moved, (e.localPosition - _downAt).distance);
    final geo = _geoNow;
    final g = _grab;
    if (g != null && geo != null && _canPlay) {
      final want = geo.radiusFor(_run.bend.kind, r0: g.r0, from: g.from, p: e.localPosition);
      // The wall stops it silently: no clunk to tell 'safe here'.
      _run.setRadius(want);
      setState(() => _dragged = true);
      return;
    }
    if (_lug != null) setState(() => _lugAt = e.localPosition);
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _ptr) return;
    _ptr = null;
    final p = e.localPosition;
    if (_grab != null) {
      setState(() => _grab = null);
      if (_moved >= 4) {
        _tick('sounds/intro/click.ogg', 0.4);
        _steps++;
        setState(() => _wake++);
      }
      return;
    }
    final lug = _lug;
    if (lug != null) {
      final geo = _geoNow!;
      setState(() {
        _lug = null;
        _lugAt = null;
      });
      if (!_canPlay) return;
      if (geo.earthHit(lug).contains(p)) {
        _run.bond(lug);
        HapticFeedback.lightImpact();
        _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
        unawaited(_levelDelta(5, e.position, mood: GuideMood.glad));
        _steps++;
        setState(() => _wake++);
      } else {
        // Not on its earth point: the lug falls back.
        if (_moved < 10) setState(() => _tappedLug = lug);
        _hints.missTap();
      }
      return;
    }
    if (_moved < 14) _tap(p, e.position);
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer != _ptr) return;
    _ptr = null;
    setState(() {
      _grab = null;
      _lug = null;
      _lugAt = null;
    });
  }

  void _tap(Offset p, Offset global) {
    final geo = _geoNow;
    if (!_canPlay || geo == null) return;
    if (_run.stage == M6UgStage.termination) {
      for (var i = 0; i < 2; i++) {
        if (geo.slot(i).contains(p)) {
          unawaited(_pickItem(i == _run.deal.kitSlot, global));
          return;
        }
      }
    }
    _hints.missTap();
  }

  // The docket: hold it and the ring floats under the finger.
  bool get _canLook => !_intro && !_ended && _card == null && !_freeze && !reasonOpen && !coworkerOpen && _run.stage == M6UgStage.bend;

  void _holdDocket(Offset local) {
    if (!_canLook) return;
    HapticFeedback.selectionClick();
    setState(() => _ringAt = M6UgGeo.docket.topLeft + local);
  }

  void _moveRing(Offset local) {
    if (_ringAt == null) return;
    setState(() => _ringAt = M6UgGeo.docket.topLeft + local);
  }

  void _dropRing() {
    if (_ringAt == null) return;
    setState(() {
      _ringAt = null;
      _wake++;
    });
  }

  /// 'বসান' (the coworker's bend push waits on it).
  void _place(Offset global) {
    if (!_canPlay || _run.stage != M6UgStage.bend) return;
    if (holdForCoworker()) return;
    final m = _run.place();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    if (_run.index == _run.deal.whyBend) {
      _stationDone(M6UgWhy.bend);
      return;
    }
    // A right bend with no reason this play: its ◆ at once, then the next.
    setState(() {
      _advancing = true;
      _wake++;
    });
    unawaited(_levelDelta(10 + (_run.thorough ? 5 : 0), global, mood: GuideMood.glad));
    unawaited(_sayChain([_praise.next().shownBn], mood: GuideMood.glad));
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 600 : 1300), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  /// 'পাতার কাজ শেষ' (the coworker's armour push waits on it too).
  void _signOff(Offset global) {
    if (!_canPlay || _run.stage != M6UgStage.armour) return;
    if (holdForCoworker()) return;
    final m = _run.signOff();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _stationDone(M6UgWhy.armour);
  }

  /// The kit box or the phone (the coworker's termination push waits on it).
  Future<void> _pickItem(bool kit, Offset global) async {
    if (holdForCoworker()) return;
    if (kit) {
      _tick('sounds/intro/click.ogg', 0.5);
      final m = _run.fitKit();
      if (m != null) {
        setState(() => _wake++);
        await _mistake(m, global);
      }
      return;
    }
    if (!_run.callJointer()) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    _stationDone(M6UgWhy.termination);
  }

  void _stationDone(M6UgWhy w) {
    _hush();
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M6UgCableLines.whyRight[w]!, M6UgCableLines.whyWrong[w]!, widget.rng),
      question: M6UgCableLines.whyQ[w]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startStation();
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
  CoworkerScript get coworkerScript => M6UgCableLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final at = _run.deal.coworkerStation;
    if (_ended || _run.index > at || (_run.index == at && _run.roundDone)) return null;
    if (_run.index < at) return false;
    if (_intro || _card != null || tableBusy || _freeze || _advancing || _grab != null || _lug != null || _ringAt != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _run.deal.push;
    if (!held) {
      // Every push in this level is slip-class (ruling X2/B1).
      final m = _run.listened(p);
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6UgCableLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6UgCableLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6UgCableLines.tapWhy[_nudgeN++ % M6UgCableLines.tapWhy.length]
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
      _cardTone = MistakeTone.slip;
      _ringAt = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6ugcable/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The armour signed off with no earth: the scene freezes grey and the
  /// fault flash comes off both glands in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _grab = null;
      _lug = null;
      _ringAt = null;
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
    final speak = await SpokenOnce.first('m6ugcable/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6UgCableLines.deadlyWord : M6UgCableLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same station goes on from where it was.
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
    await _say(!_run.passed ? M6UgCableLines.fail : (_quickBonus ? M6UgCableLines.quick : M6UgCableLines.allSet),
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
  /// The gesture hand: how to touch, never what.
  ///  bend: until the curve is moved, in turn the docket's hold ring and a
  ///    tiny nudge of the belly handle along its diagonal (wider and tighter
  ///    by turns, [m6UgHandleNudge]); after, a sweep over the handle and
  ///    'বসান' alike;
  ///  armour: a sweep over every free lead and the chip; after a lead was
  ///    tapped, an upward drag on that lead;
  ///  termination: a sweep over the kit box and the phone.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    switch (_run.stage) {
      case M6UgStage.bend:
        if (!_dragged) {
          if (n.isEven) return HintSpec.holdOn(_docketKey);
          final k = _run.bend.kind;
          return HintSpec.drag(geo.handleHit(k, _run.r).center, toward: m6UgHandleNudge(k, n ~/ 2), travel: kM6HintTravel, space: HintSpace.scene);
        }
        return HintSpec.sweepOver([_handleKey, _actKey]);
      case M6UgStage.armour:
        final t = _tappedLug;
        if (t != null && !_run.bonded.contains(t)) return HintSpec.dragFrom(_lugKeys[t], toward: const Offset(0, -1), travel: 48);
        return HintSpec.sweepOver([
          for (var i = 0; i < 2; i++)
            if (!_run.bonded.contains(i)) _lugKeys[i],
          _actKey,
        ]);
      case M6UgStage.termination:
        return HintSpec.sweep([geo.slot(0), geo.slot(1)], space: HintSpace.scene);
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6UgGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final stage = _run.stage;
    final b = _run.bend;
    final ring = _ringAt;
    final rMin = _run.deal.ring;
    return [
      Positioned.fill(
        key: ValueKey('world-${stage.name}'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: switch (stage) {
                M6UgStage.bend => M6BendPainter(
                    geo: geo,
                    rig: M6BendRig(kind: b.kind, r: _run.r, rMin: b.rMin, rMax: b.rMax, ghost: _run.ghost, crease: _run.creaseAt, placed: _run.roundDone),
                    seed: _seed + _run.index,
                  ),
                M6UgStage.armour => M6ArmourPainter(geo: geo, rig: M6ArmourRig(bonded: {..._run.bonded}, dragging: _lug, dragAt: _lugAt), seed: _seed),
                M6UgStage.termination => M6TermPainter(geo: geo, kitSlot: _run.deal.kitSlot, kitLabel: M6UgCableLines.kitLabel, seed: _seed),
              },
            ),
          ),
        ),
      ),
      // The belly handle (a look only; the touch layer moves it).
      if (stage == M6UgStage.bend && !_run.roundDone && !_freeze)
        Positioned.fromRect(
          key: ValueKey('handle-${_run.index}'),
          rect: Rect.fromCenter(center: geo.belly(b.kind, _run.r), width: 34, height: 34),
          child: IgnorePointer(child: KeyedSubtree(key: _handleKey, child: _Handle(on: _grab != null))),
        ),
      // The free leads' places (for the hand's sweep; invisible).
      if (stage == M6UgStage.armour)
        for (var i = 0; i < 2; i++)
          if (!_run.bonded.contains(i))
            Positioned.fromRect(
              key: ValueKey('lug-$i'),
              rect: geo.lugHit(i),
              child: IgnorePointer(child: SizedBox.expand(key: _lugKeys[i])),
            ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6UgCableLines.sceneLabel,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerMove: _move,
            onPointerUp: _up,
            onPointerCancel: _cancel,
          ),
        ),
      ),
      // The job docket (hold it: the ring under the finger).
      Positioned.fromRect(
        key: const ValueKey('docket'),
        rect: M6UgGeo.docket,
        child: ColorFiltered(
          colorFilter: grey,
          child: Semantics(
            label: M6UgCableLines.docketLabel,
            excludeSemantics: true,
            child: GestureDetector(
              key: _docketKey,
              behavior: HitTestBehavior.opaque,
              onTap: _hints.missTap,
              onLongPressStart: (d) => _holdDocket(d.localPosition),
              onLongPressMoveUpdate: (d) => _moveRing(d.localPosition),
              onLongPressEnd: (_) => _dropRing(),
              onLongPressCancel: _dropRing,
              child: _Docket(size: _run.deal.size, held: ring != null),
            ),
          ),
        ),
      ),
      if (ring != null && stage == M6UgStage.bend)
        Positioned(
          key: const ValueKey('ring'),
          left: ring.dx - rMin - 4,
          top: ring.dy - rMin - 4,
          width: (rMin + 4) * 2,
          height: (rMin + 4) * 2,
          child: const IgnorePointer(child: CustomPaint(painter: M6RingPainter())),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6FlashPainter(at: [geo.gland(0), geo.gland(1)], v: v)),
            ),
          ),
        ),
      // The next station: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('station-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.6, end: 0),
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
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null && !_advancing;
    final stage = _run.stage;
    final act = handsOn && stage != M6UgStage.termination;
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
              labels: M6UgCableLines.stations,
              done: {for (var i = 0; i < math.min(_run.index, m6UgStations); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _grab == null && _lug == null && _ringAt == null,
            hintKey: '${_run.index}/$_steps/$_dragged/$_tappedLug',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (act)
                Positioned(
                  key: ValueKey('act-${stage.name}'),
                  left: 16,
                  bottom: pad.bottom + 18,
                  child: _ActButton(
                    key: _actKey,
                    label: stage == M6UgStage.bend ? M6UgCableLines.place : M6UgCableLines.signOff,
                    icon: stage == M6UgStage.bend ? Icons.download_done_rounded : Icons.assignment_turned_in_rounded,
                    onTap: stage == M6UgStage.bend ? _place : _signOff,
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
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
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M6UgCableLines.intro,
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

// ============================================================================
// Pieces
// ============================================================================

/// The job docket: the cable and, drawn small, its ring (no number).
class _Docket extends StatelessWidget {
  const _Docket({required this.size, required this.held});
  final M6CableSize size;
  final bool held;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: held ? SlmColors.gold300 : const Color(0xFF8A6A3C), width: held ? 3 : 2.4),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(M6UgCableLines.docketTitle, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(M6UgCableLines.docketCable, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2A2018))),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(M6UgCableLines.docketSize(size), style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF5A4630))),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 44, height: 44, child: CustomPaint(painter: _DocketRing())),
          ],
        ),
      ),
    );
  }
}

class _DocketRing extends CustomPainter {
  const _DocketRing();

  @override
  void paint(Canvas c, Size size) {
    final o = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    c.drawCircle(o, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFFC9A227));
    c.drawCircle(o, 2.2, Paint()..color = const Color(0xFF8A6A3C));
  }

  @override
  bool shouldRepaint(_DocketRing old) => false;
}

/// The bend's belly handle (a grip knob; lit while held).
class _Handle extends StatelessWidget {
  const _Handle({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [Color(0xFF3A4556), Color(0xFF151C27)]),
        border: Border.all(color: on ? SlmColors.gold300 : const Color(0xFFE8E2D0), width: on ? 3 : 2.2),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: const Icon(Icons.open_with_rounded, size: 18, color: Color(0xFFE8E2D0)),
    );
  }
}

/// The station's commit button ('বসান' / 'পাতার কাজ শেষ').
class _ActButton extends StatelessWidget {
  const _ActButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Container(
          constraints: const BoxConstraints(minWidth: 128, minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.gold300, width: 1.8),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: SlmColors.gold300),
              const SizedBox(width: 8),
              Text(label, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}
