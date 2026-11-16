import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm7_ptw_sign_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm7_ptw_sign_world.dart' show M7PtwBox, M7PtwCopy, M7PtwGeo, M7PtwSheetGeo;

// Lesson 7.4 "পারমিট-টু-ওয়ার্ক (PTW): একটি আইনি চুক্তি", কাজ 1 "সইয়ের আগে"
// (pack do_7_4_a, engineType m7_ptw_sign). The issuing counter of a 33/11 kV
// substation; the player is today's receiver. Three permits a play (সকালের,
// দুপুরের, বিকেলের কাজ), each a two-sheet carbon book: 'কন্ট্রোল রুম কপি'
// and 'ফিল্ড কপি' (which one is on top is dealt), boxes PTW নং, ফিডার,
// তারিখ, ইস্যুর সময়, ইস্যুকারীর সই, two শর্ত lines (lesson phrases) and
// গ্রহণকারীর সই.
//
// The core verb is the carbon book: peel the top sheet up by its corner to see
// the copy beneath (free, unlimited; nothing side by side, nothing ringed);
// tap a condition line to have the issuer explain it (a smudged line becomes
// clear; a clear one 'যেমন লেখা আছে, তেমনই' at no cost); then decide:
//  · sign — pick up the pen and trace the receiver's dotted line (≥ 80 %);
//  · send back — swipe the book's top edge up to the issuer; he asks 'কোথায়
//    ভুল?'; tap the faulty box (a right box = fixed, then sign; a correct box
//    = slip; a clean permit sent back = slip, R29).
// A fault seen only after signing can still go back the same way, as long as
// nothing is torn off; the corrected permit is then signed afresh. The
// post-sign task line names the check, never the tear itself.
// After signing: if the carbon slipped the copy beneath has no signature —
// peel, check and sign it too (tearing without = slip). Then tear the 'ফিল্ড
// কপি' off along its perforated stub (the control-room copy = slip).
//
// Dealt per play: one clean permit and two different faults out of: the
// issuer's signature missing on the FIELD copy (≤ once, ~1 play in 3: the
// deadly case), missing on the control-room copy only, a blank date or time on
// one copy, different PTW numbers, a smudged condition (unreadable on every
// copy), a carbon slip. Every permit is dated today.
//
// Deadly (module 7 table R1, ruling M7-2): tearing off and leaving with a
// field copy whose issuer box is blank — the counter freezes grey, the inset
// in colour shows the crew on a line nobody certified, then the fall. Slips
// (R3, R29, R30): signing when the copies differ / a box is blank / only the
// control-room copy lacks the issuer's signature; signing a smudged condition
// without asking; tearing with the lower signature missing; tearing the
// control-room copy; a needless send-back or a correct box tapped; listening
// to the coworker (B1: he pushes a slip-class act here). Three slips strike
// out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m7_ptw_sign_world.dart), corner guide, each permit done puts ◆
// on the table → "কেন …?" (fits what was done) → এগিয়ে যান → the next
// permit; the coworker once a play on a random permit (clean or faulty) — the
// pen, the send-back swipe and a condition line wait for him
// (holdForCoworker). Gesture hands: a short nudge up on the book's corner
// (every permit), a sweep over the pen, the top edge and the condition lines,
// a drag from the dotted line's start once the pen is up, a sweep over every
// box when the issuer asks 'কোথায় ভুল?', a sweep over both stubs (a touched
// stub gets a swipe on that same stub) — never the answer.

// ============================================================================
// Content
// ============================================================================

/// What is wrong with a permit as it comes over the counter.
enum M7PtwFault { clean, fieldNoIssuer, controlNoIssuer, blankBox, numberDiff, smudged, carbonSlip }

/// Where a permit is in its life.
enum M7PtwPhase { deciding, boxPick, signed, done }

/// The coworker's push (one a play).
enum M7PtwPush { lowerNobody, noRead }

/// What a permit's reason asks about (fits what was done).
enum M7PtwWhy { sentBack, asked, duty, noIssuer, lowerToo }

/// What the issuer says when a condition line is asked about.
enum M7PtwAsk { cleared, asIs }

/// The faults other than the deadly one (two of them, or one with it).
const m7PtwSlipFaults = [M7PtwFault.controlNoIssuer, M7PtwFault.blankBox, M7PtwFault.numberDiff, M7PtwFault.smudged, M7PtwFault.carbonSlip];

abstract final class M7PtwSignLines {
  static const title = 'সইয়ের আগে';
  // DRAFT wording — owner (M6-12 / M7-10).
  static const intro = 'আজ পারমিট নেবেন আপনি। সব কপি দেখে, বুঝে, তবেই সই।';

  // The guide's task now (tap him: the same task, a different way).
  static const askCheck = 'কপিগুলো মিলিয়ে নিন।';
  static const askWhere = 'কোথায় ভুল? ঘরটা দেখিয়ে দিন।';
  static const askSign = 'কলম হাতে — দাগের ওপর সই করুন।';
  // After signing: names the check, never the act (a fault may still be in
  // it: the field copy without the issuer's signature, or a carbon slip).
  static const askTear = 'সব কপি দেখে নিয়ে তবে আপনার কপিটা ছিঁড়ুন।';
  static const fixedGo = 'ঠিক হলো। এবার দেখে নিয়ে সই করুন।';
  static List<String> get tasks => [askCheck, askWhere, askSign, askTear, fixedGo];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The issuer behind the counter (his bubble; not spoken).
  // DRAFT wording — owner.
  static const issuerAsIs = 'যেমন লেখা আছে, তেমনই।';
  static const issuerClear = 'এই যে, পরিষ্কার করে লিখে দিলাম।';
  static const issuerWhere = 'কোথায় ভুল?';
  static const issuerFixed = 'ঠিক করে দিলাম।';
  static const issuerAllOk = 'সব তো ঠিকই আছে!';
  static const issuerBubbles = [issuerAsIs, issuerClear, issuerWhere, issuerFixed, issuerAllOk];

  // The sheet (the labels a worker reads on a PTW book).
  static String copy(M7PtwCopy c) => switch (c) {
        M7PtwCopy.control => 'কন্ট্রোল রুম কপি',
        M7PtwCopy.field => 'ফিল্ড কপি',
      };
  static const ptw = 'পারমিট-টু-ওয়ার্ক (PTW)';
  static const number = 'PTW নং';
  static const feeder = 'ফিডার';
  static const date = 'তারিখ';
  static const time = 'ইস্যুর সময়';
  static const issuer = 'ইস্যুকারীর সই';
  static const conditions = 'শর্ত';
  static const receiver = 'গ্রহণকারীর সই';
  static const sendBack = 'ফেরত';
  static const sceneLabel = 'PTW কার্বন বই';
  static const penLabel = 'কলম';

  /// The three permits of a play.
  static const permits = ['সকালের কাজ', 'দুপুরের কাজ', 'বিকেলের কাজ'];

  /// Feeder names (game device) on 11 kV.
  static const feeders = ['11 kV মিলপাড়া', '11 kV স্টেশন রোড', '11 kV হাটতলা', '11 kV কলেজপাড়া', '11 kV নদীঘাট', '11 kV বাজার'];

  /// Condition lines: only lesson 7.4's own phrases (section 1, section 2,
  /// the LOTO fact, myth 2's reality), short.
  static const conditionLines = [
    'লাইন বিচ্ছিন্ন, ডেড ও আর্থ করা',
    'সুইচগিয়ারে তালা ও ট্যাগ লাগানো',
    'টিমের সুরক্ষা গ্রহণকারীর দায়িত্ব',
    'কাজ শেষে লাইন নিরাপদে ফেরত',
    'টিমের সবাই জানবে কোন PTW চলছে',
  ];

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M7PtwWhy, String>{
    M7PtwWhy.sentBack: 'কপি ফেরত দিলেন কেন?',
    M7PtwWhy.asked: 'সই করার আগে কেন জিজ্ঞাসা করলেন?',
    M7PtwWhy.duty: 'এই সইয়ে আপনি কী দায়িত্ব নিলেন?',
    M7PtwWhy.noIssuer: 'ইস্যুকারীর সই নেই — কেন নিলেন না?',
    M7PtwWhy.lowerToo: 'নিচের কপিতেও কেন সই করলেন?',
  };
  static const whyRight = <M7PtwWhy, List<String>>{
    M7PtwWhy.sentBack: ['প্রতিটি কপি ঠিকভাবে পূরণ না হলে সই নয়', 'কপিতে ভুল রেখে সই করলে দায় আমার ঘাড়ে', 'সব কপি মিলে গেলে তবেই সেটা বৈধ PTW'],
    M7PtwWhy.asked: ['না বোঝা শর্তে সই চলে না, আগে বুঝে নিই', 'শর্ত না বুঝে সই মানে না জেনে দায় নেওয়া'],
    M7PtwWhy.duty: ['কাজের বিপদ জেনে টিমকে নিরাপদ রাখার দায়', 'কাজ শেষে লাইন নিরাপদে ফেরত দেওয়ার দায়', 'টিমের সুরক্ষা নিশ্চিত করার আইনি দায়িত্ব'],
    M7PtwWhy.noIssuer: ['ইস্যুকারীর সই-ই বলে লাইন বিচ্ছিন্ন ও লক', 'ইস্যুকারীর সই নেই, লাইন নিরাপদ কেউ বলেনি'],
    M7PtwWhy.lowerToo: ['প্রতিটি কপিতেই আমার সই থাকা চাই, নিচেরটাতেও', 'নিচের কপিতে সই না উঠলে সেটা অসম্পূর্ণ'],
  };
  static const myths = [
    'সই তো শুধু একটা সাধারণ ফর্মালিটি মাত্র',
    'ওপরের কপি ঠিক থাকলে বাকিগুলোও ঠিক থাকে',
    'অপারেটর মুখে বলেছেন, সেটাই তো যথেষ্ট',
    'PTW তো শুধু সুপারভাইজারের মাথাব্যথা',
    'দেরি হলে কাগজ পরে ঠিক করে নেওয়া যায়',
    'শর্ত সব পারমিটেই এক, পড়ার দরকার নেই',
    'নিজের সই থাকলেই পারমিট পুরোপুরি বৈধ',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play, on a random permit).
  // DRAFT wording — owner (M7-10): his two shortcut lines are the spec's.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _asksLower = ['কী করবেন?', 'ও বলছে নিচের কপি না দেখেই সই করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];
  static const _asksRead = ['কী করবেন?', 'ও বলছে না পড়েই সই করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];
  static const coworkerLower = CoworkerScript(
    line: 'ওপরের কপিতে সই করলেই হলো, নিচেরটা কে দেখে? চলো, দেরি হচ্ছে!',
    exitLine: coworkerExit,
    right: ['সব কপি দেখে, বুঝে তবেই সই করব', 'প্রতিটি কপি ঠিক না দেখে সই নয়', 'না, নিচের কপিও দেখে তবেই সই'],
    wrong: [
      'ঠিক আছে, ওপরেরটায় সই করে চলি',
      'অপারেটর দেখে দিয়েছেন, সই করে দিই',
      'হ্যাঁ, দেরি করে লাভ নেই, সই করি',
      'ঠিক, নিচের কপি তো কেউ দেখে না',
      'আচ্ছা, ওপরেরটাই যথেষ্ট, সই দিই',
    ],
    asks: _asksLower,
  );
  static const coworkerRead = CoworkerScript(
    line: 'পড়ার কী আছে? সই করে দাও, গাড়ি দাঁড়িয়ে আছে!',
    exitLine: coworkerExit,
    right: ['সব কপি দেখে, বুঝে তবেই সই করব', 'প্রতিটি কপি ঠিক না দেখে সই নয়', 'না, শর্ত না বুঝে আমি সই করব না'],
    wrong: [
      'ঠিক আছে, না পড়েই সই করে চলি',
      'অপারেটর দেখে দিয়েছেন, সই করে দিই',
      'হ্যাঁ, দেরি করে লাভ নেই, সই করি',
      'ঠিক, পড়ার কিছু নেই, সই দিই',
      'আচ্ছা, গাড়ি দাঁড়িয়ে, সই করে দিই',
    ],
    asks: _asksRead,
  );
  static CoworkerScript coworker(M7PtwPush p) => switch (p) {
        M7PtwPush.lowerNobody => coworkerLower,
        M7PtwPush.noRead => coworkerRead,
      };
  static const allCoworkers = [coworkerLower, coworkerRead];
  static const callHeld = 'ঠিক! সব কপি দেখে, বুঝে তবেই সই।';

  static const allSet = 'তিনটে পারমিটই দেখে, বুঝে সই — দায়িত্ব নিয়ে কাজ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — সব কপি মিলিয়ে, শর্ত বুঝে, তবেই সই।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtBack = 'ভুল কপি ফেরত দিয়ে ঠিক করালেন';
  static const caughtAsked = 'না বোঝা শর্ত বুঝে তবে সই';
  static const caughtLower = 'নিচের কপিতেও সই';
  static const caughtNoIssuer = 'ইস্যুকারীর সই ছাড়া পারমিট নয়';
  static const caughtField = 'শুধু ফিল্ড কপি নিলেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        askCheck,
        askWhere,
        askSign,
        askTear,
        fixedGo,
        ...whyQ.values,
        for (final a in {..._asksLower, ..._asksRead}) if (!_oldAsks.contains(a)) a,
        callHeld,
        allSet,
        fail,
        for (final m in M7PtwSignMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M7PtwSignMistakes {
  static const _dir = 'assets/game/art/m7_ptw_sign';

  // DRAFT wording — owner (M6-12). Lesson points (0-based): 0 the legal
  // basis, 1 the signature, 2 the consequences.
  static const fieldBlank = DoMistake(
    key: '7.4/m7_ptw_sign/field-no-issuer',
    textBn: 'ফিল্ড কপিতে ইস্যুকারীর সই নেই — কেউ লিখে নিশ্চিত করেননি যে লাইন বিচ্ছিন্ন আর লক করা। এই কাগজ নিয়ে টিম লাইনে উঠলে সেটা বিনা PTW-এর কাজ। ফেরত দিন, সই করিয়ে তবেই নিন।',
    art: '$_dir/field_no_issuer.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const controlBlank = DoMistake(
    key: '7.4/m7_ptw_sign/control-no-issuer',
    textBn: 'কন্ট্রোল রুম কপিতে ইস্যুকারীর সই নেই। প্রতিটি কপি ঠিকভাবে পূরণ আর সই হয়েছে কি না দেখে তবেই সই করুন — না হলে ফেরত দিন।',
    art: '$_dir/control_no_issuer.svg',
    lessonPoint: 1,
  );
  static const copiesDiffer = DoMistake(
    key: '7.4/m7_ptw_sign/copies-differ',
    textBn: 'দুই কপির PTW নং আলাদা। প্রতিটি কপি মিলিয়ে দেখুন; না মিললে সই নয়, ফেরত দিন।',
    art: '$_dir/copies_differ.svg',
    lessonPoint: 1,
  );
  static const blankBox = DoMistake(
    key: '7.4/m7_ptw_sign/blank-box',
    textBn: 'একটা কপিতে তারিখ বা সময়ের ঘর ফাঁকা। প্রতিটি কপি পুরো পূরণ হয়েছে কি না দেখে তবেই সই — না হলে ফেরত দিন।',
    art: '$_dir/blank_box.svg',
    lessonPoint: 1,
  );
  static const notUnderstood = DoMistake(
    key: '7.4/m7_ptw_sign/not-understood',
    textBn: 'একটা শর্ত পড়াই যাচ্ছিল না। যে শর্ত বোঝেননি, সই করার আগে জিজ্ঞাসা করে বুঝে নিন — “আমি ভেবেছিলাম” বলার জায়গা নেই।',
    art: '$_dir/not_understood.svg',
    lessonPoint: 1,
  );
  static const carbonMissed = DoMistake(
    key: '7.4/m7_ptw_sign/carbon-missed',
    textBn: 'নিচের কপিতে আপনার সই ওঠেনি। প্রতিটি কপিতে সই হয়েছে কি না দেখে নিন; না উঠলে সেখানেও সই করুন।',
    art: '$_dir/carbon_missed.svg',
    lessonPoint: 1,
  );
  static const wrongTear = DoMistake(
    key: '7.4/m7_ptw_sign/wrong-tear',
    textBn: 'কন্ট্রোল রুম কপি কন্ট্রোল রুমেই থাকে। আপনি নেবেন শুধু ফিল্ড কপি — সেটাই টিমের সঙ্গে কাজে যায়।',
    art: '$_dir/wrong_tear.svg',
    lessonPoint: 1,
  );
  static const needlessBack = DoMistake(
    key: '7.4/m7_ptw_sign/needless-back',
    textBn: 'এই পারমিটের সব কপি ঠিক ছিল। অকারণে ফেরত দিয়ে কাজ আটকাবেন না — দেখে, বুঝে সই করুন।',
    art: '$_dir/needless_back.svg',
    lessonPoint: 1,
  );
  static const wrongBox = DoMistake(
    key: '7.4/m7_ptw_sign/wrong-box',
    textBn: 'এই ঘরটা ঠিকই আছে। কোন ঘরে গোলমাল, দুই কপি মিলিয়ে দেখে তবে দেখান।',
    art: '$_dir/wrong_box.svg',
    lessonPoint: 1,
  );
  static const listened = DoMistake(
    key: '7.4/m7_ptw_sign/listened',
    textBn: 'ওর কথায় না দেখেই সই করতে যাচ্ছিলেন! PTW-এর প্রতিটি সই আইনি দায়িত্বের প্রমাণ — সব কপি দেখে, বুঝে তবেই সই।',
    art: '$_dir/listened.svg',
    lessonPoint: 1,
  );

  /// Signing a permit with this fault still in it (null: no slip at the
  /// signature; the field copy without the issuer's signature is judged when
  /// it is torn off and taken).
  static DoMistake? signing(M7PtwFault f) => switch (f) {
        M7PtwFault.controlNoIssuer => controlBlank,
        M7PtwFault.blankBox => blankBox,
        M7PtwFault.numberDiff => copiesDiffer,
        M7PtwFault.smudged => notUnderstood,
        M7PtwFault.clean || M7PtwFault.fieldNoIssuer || M7PtwFault.carbonSlip => null,
      };

  static const List<DoMistake> all = [
    fieldBlank,
    controlBlank,
    copiesDiffer,
    blankBox,
    notUnderstood,
    carbonMissed,
    wrongTear,
    needlessBack,
    wrongBox,
    listened,
  ];
}

/// One permit as dealt.
@immutable
class M7PtwPermit {
  const M7PtwPermit({
    required this.fault,
    required this.fieldOnTop,
    required this.number,
    required this.oddNumber,
    required this.feeder,
    required this.date,
    required this.time,
    required this.conditions,
    required this.oddCopy,
    this.blankKind = M7PtwBox.date,
    this.smudgeLine = 0,
  });

  final M7PtwFault fault;

  /// The field copy is the top sheet (else the control-room copy is).
  final bool fieldOnTop;

  /// The PTW number; [oddNumber] is the near miss on [oddCopy] (numberDiff).
  final int number;
  final int oddNumber;
  final String feeder;
  final String date;
  final String time;

  /// The two condition lines (indexes into [M7PtwSignLines.conditionLines]).
  final List<int> conditions;

  /// The copy the fault is on (the issuer's blank box: its own copy; a
  /// smudge: the top sheet, carried through to the copy beneath).
  final M7PtwCopy oddCopy;

  /// blankBox: the date or the time.
  final M7PtwBox blankKind;

  /// smudged: which condition line.
  final int smudgeLine;

  M7PtwCopy get topCopy => fieldOnTop ? M7PtwCopy.field : M7PtwCopy.control;
  M7PtwCopy get lowerCopy => fieldOnTop ? M7PtwCopy.control : M7PtwCopy.field;

  /// The box a send-back must point at (null: nothing to send back for).
  M7PtwBox? get faultBox => switch (fault) {
        M7PtwFault.fieldNoIssuer || M7PtwFault.controlNoIssuer => M7PtwBox.issuer,
        M7PtwFault.blankBox => blankKind,
        M7PtwFault.numberDiff => M7PtwBox.number,
        M7PtwFault.smudged => M7PtwBox.condition,
        M7PtwFault.clean || M7PtwFault.carbonSlip => null,
      };
}

@immutable
class M7PtwDeal {
  const M7PtwDeal({required this.permits, required this.coworkerPermit, required this.push});
  final List<M7PtwPermit> permits;

  /// The permit the coworker comes in at, and his push.
  final int coworkerPermit;
  final M7PtwPush push;
}

/// A near-miss PTW number: two neighbouring digits swapped, or one digit off
/// by one (always 4 digits, always different).
int m7PtwNearMiss(int n, math.Random rng) {
  final d = '$n'.split('');
  if (rng.nextBool()) {
    for (var tries = 0; tries < 6; tries++) {
      final i = rng.nextInt(3);
      if (d[i] != d[i + 1] && !(i == 0 && d[i + 1] == '0')) {
        final x = d[i];
        d[i] = d[i + 1];
        d[i + 1] = x;
        return int.parse(d.join());
      }
    }
  }
  final i = 1 + rng.nextInt(3);
  final v = int.parse(d[i]);
  d[i] = '${v == 9 ? 8 : v + 1}';
  return int.parse(d.join());
}

String _two(int n) => n.toString().padLeft(2, '0');

/// [today] is the day the permits are issued (the device's date by default):
/// a permit's date is always today's.
M7PtwDeal m7PtwDeal(math.Random rng, {DateTime? today}) {
  final others = [...m7PtwSlipFaults]..shuffle(rng);
  // The deadly case on about one play in three, at most once.
  final faults = rng.nextInt(3) == 0 ? [M7PtwFault.fieldNoIssuer, others[0]] : [others[0], others[1]];
  final kinds = [M7PtwFault.clean, ...faults]..shuffle(rng);
  final feeders = [...M7PtwSignLines.feeders]..shuffle(rng);
  final d = today ?? DateTime.now();
  final date = '${_two(d.day)}/${_two(d.month)}/${d.year}';
  const hours = [(8, 10), (12, 13), (15, 16)];
  final permits = <M7PtwPermit>[];
  for (final (i, f) in kinds.indexed) {
    final number = 2000 + rng.nextInt(7900);
    final conds = [for (var k = 0; k < M7PtwSignLines.conditionLines.length; k++) k]..shuffle(rng);
    final (h0, h1) = hours[i];
    final hour = h0 + rng.nextInt(h1 - h0 + 1);
    final fieldOnTop = rng.nextBool();
    permits.add(M7PtwPermit(
      fault: f,
      fieldOnTop: fieldOnTop,
      number: number,
      oddNumber: m7PtwNearMiss(number, rng),
      feeder: feeders[i],
      date: date,
      time: '${_two(hour)}:${_two(5 * rng.nextInt(12))}',
      conditions: conds.take(2).toList(),
      oddCopy: switch (f) {
        M7PtwFault.fieldNoIssuer => M7PtwCopy.field,
        M7PtwFault.controlNoIssuer => M7PtwCopy.control,
        // The issuer's smudged hand is on the sheet he wrote, the top one;
        // the carbon carries the same smudge (the sheet shows it on both).
        M7PtwFault.smudged => fieldOnTop ? M7PtwCopy.field : M7PtwCopy.control,
        _ => M7PtwCopy.values[rng.nextInt(2)],
      },
      blankKind: rng.nextBool() ? M7PtwBox.date : M7PtwBox.time,
      smudgeLine: rng.nextInt(2),
    ));
  }
  return M7PtwDeal(permits: permits, coworkerPermit: rng.nextInt(3), push: M7PtwPush.values[rng.nextInt(2)]);
}

/// What one sheet shows now.
@immutable
class M7PtwSheet {
  const M7PtwSheet({
    required this.copy,
    required this.number,
    required this.feeder,
    required this.date,
    required this.time,
    required this.issuerSigned,
    required this.conditions,
    required this.smudged,
    required this.receiverSigned,
  });
  final M7PtwCopy copy;
  final int number;
  final String feeder;

  /// Null: the box is blank.
  final String? date;
  final String? time;
  final bool issuerSigned;
  final List<String> conditions;

  /// The condition line that cannot be read (null: all clear).
  final int? smudged;
  final bool receiverSigned;
}

/// The share of the dotted line a signature must cover.
const kM7PtwSignCover = 0.8;

/// The play state (pure logic).
class M7PtwRun {
  M7PtwRun(this.deal) {
    _start();
  }
  final M7PtwDeal deal;

  int index = 0;
  int slips = 0;
  int permitSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  var phase = M7PtwPhase.deciding;

  /// The top sheet is folded up (the copy beneath shows); it was, this permit.
  var peeled = false;
  var peeked = false;

  /// The fault was put right (sent back and fixed, or the smudge explained).
  var fixed = false;
  var penUp = false;
  var topSigned = false;
  var lowerSigned = false;

  /// How the permit went (for the reason and "আজ যা ধরলেন").
  var sentBack = false;
  var askedSmudge = false;
  var signedFaulty = false;
  var resignedLower = false;

  M7PtwPermit get permit => deal.permits[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => permitSlips == 0;
  bool get roundDone => phase == M7PtwPhase.done;
  bool get _open => !ended && !roundDone;

  /// The fault as it stands (put right: none).
  M7PtwFault get live => fixed ? M7PtwFault.clean : permit.fault;

  /// The copy on show (the top sheet, or the one beneath while peeled).
  M7PtwCopy get shown => peeled ? permit.lowerCopy : permit.topCopy;

  void _start() {
    phase = M7PtwPhase.deciding;
    peeled = false;
    peeked = false;
    fixed = false;
    penUp = false;
    topSigned = false;
    lowerSigned = false;
    sentBack = false;
    askedSmudge = false;
    signedFaulty = false;
    resignedLower = false;
    permitSlips = 0;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    permitSlips++;
    return m;
  }

  /// What sheet [c] shows now.
  M7PtwSheet sheet(M7PtwCopy c) {
    final p = permit;
    final f = live;
    final odd = c == p.oddCopy;
    return M7PtwSheet(
      copy: c,
      number: f == M7PtwFault.numberDiff && odd ? p.oddNumber : p.number,
      feeder: p.feeder,
      date: f == M7PtwFault.blankBox && odd && p.blankKind == M7PtwBox.date ? null : p.date,
      time: f == M7PtwFault.blankBox && odd && p.blankKind == M7PtwBox.time ? null : p.time,
      issuerSigned: !((f == M7PtwFault.fieldNoIssuer || f == M7PtwFault.controlNoIssuer) && odd),
      conditions: [for (final i in p.conditions) M7PtwSignLines.conditionLines[i]],
      // A smudged line is unreadable on every copy (the carbon copies it):
      // the receiver cannot understand it from any sheet (lesson pro tip 4).
      smudged: f == M7PtwFault.smudged ? p.smudgeLine : null,
      receiverSigned: c == p.topCopy ? topSigned : lowerSigned,
    );
  }

  /// Peel the top sheet up (or lay it back). Free, any time in the permit.
  bool togglePeel() {
    if (!_open) return false;
    peeled = !peeled;
    if (peeled) peeked = true;
    return true;
  }

  /// A condition line asked about (on the sheet on show): the smudged one is
  /// explained (and put right); any other 'as it is written' — no cost.
  M7PtwAsk? ask(int line) {
    if (!_open || phase == M7PtwPhase.boxPick) return null;
    final s = sheet(shown);
    if (s.smudged == line) {
      fixed = true;
      if (!topSigned) askedSmudge = true;
      return M7PtwAsk.cleared;
    }
    return M7PtwAsk.asIs;
  }

  /// The pen picked up (to sign the top sheet, or the one beneath after).
  bool pickPen() {
    if (!_open || penUp || phase == M7PtwPhase.boxPick) return false;
    penUp = true;
    return true;
  }

  /// The pen traces the dotted line on the sheet on show. The top sheet's
  /// signature is the decision: a fault still in the permit is a slip (the
  /// field copy without the issuer's signature is judged when it is taken).
  /// Returns (signed, slip).
  (bool, DoMistake?) trace(double cover) {
    if (!_open || !penUp || cover < kM7PtwSignCover) return (false, null);
    if (phase == M7PtwPhase.deciding && !peeled) {
      topSigned = true;
      lowerSigned = permit.fault != M7PtwFault.carbonSlip;
      phase = M7PtwPhase.signed;
      final m = M7PtwSignMistakes.signing(live);
      if (m != null) {
        signedFaulty = true;
        return (true, _slip(m));
      }
      return (true, null);
    }
    if (phase == M7PtwPhase.signed && peeled && !lowerSigned) {
      lowerSigned = true;
      resignedLower = true;
      _tag(M7PtwSignLines.caughtLower);
      return (true, null);
    }
    return (false, null);
  }

  /// The book swiped back to the issuer, before signing or after it as long
  /// as nothing is torn off yet (a fault seen late can still go back): on a
  /// sound permit a needless stop (R29); else he asks which box is wrong.
  DoMistake? sendBack() {
    if (!_open || (phase != M7PtwPhase.deciding && phase != M7PtwPhase.signed)) return null;
    if (permit.faultBox == null || fixed) return _slip(M7PtwSignMistakes.needlessBack);
    phase = M7PtwPhase.boxPick;
    penUp = false;
    return null;
  }

  /// The box on the copy on show is the faulty one. A fault on one copy only
  /// (the issuer's blank box, a blank date or time) is pointed at on that
  /// copy; different numbers or a smudge show on both.
  bool _isFault(M7PtwBox b) {
    if (b != permit.faultBox) return false;
    return switch (permit.fault) {
      M7PtwFault.fieldNoIssuer || M7PtwFault.controlNoIssuer || M7PtwFault.blankBox => shown == permit.oddCopy,
      _ => true,
    };
  }

  /// A box shown to the issuer ('কোথায় ভুল?', on the copy on show): the
  /// faulty one is put right. A signature already on the book goes with the
  /// old sheets: the corrected permit is signed afresh.
  DoMistake? pickBox(M7PtwBox b) {
    if (!_open || phase != M7PtwPhase.boxPick) return null;
    if (!_isFault(b)) return _slip(M7PtwSignMistakes.wrongBox);
    fixed = true;
    sentBack = true;
    topSigned = false;
    lowerSigned = false;
    resignedLower = false;
    phase = M7PtwPhase.deciding;
    _tag(permit.fault == M7PtwFault.fieldNoIssuer ? M7PtwSignLines.caughtNoIssuer : M7PtwSignLines.caughtBack);
    return null;
  }

  /// A copy torn off along its stub (after signing): every copy must carry
  /// the receiver's signature first; the control-room copy stays; the field
  /// copy is taken — deadly if its issuer box is blank.
  DoMistake? tear(M7PtwCopy c) {
    if (!_open || phase != M7PtwPhase.signed) return null;
    if (!lowerSigned) return _slip(M7PtwSignMistakes.carbonMissed);
    if (c == M7PtwCopy.control) return _slip(M7PtwSignMistakes.wrongTear);
    if (live == M7PtwFault.fieldNoIssuer) return deadly = M7PtwSignMistakes.fieldBlank;
    phase = M7PtwPhase.done;
    penUp = false;
    peeled = false;
    if (askedSmudge && !signedFaulty) _tag(M7PtwSignLines.caughtAsked);
    if (permitSlips == 0) _tag(M7PtwSignLines.caughtField);
    return null;
  }

  /// The reason that fits what was done on this permit.
  M7PtwWhy get why {
    if (sentBack && permit.fault == M7PtwFault.fieldNoIssuer) return M7PtwWhy.noIssuer;
    if (permit.fault == M7PtwFault.smudged && (askedSmudge || sentBack) && !signedFaulty) return M7PtwWhy.asked;
    if (sentBack) return M7PtwWhy.sentBack;
    if (resignedLower) return M7PtwWhy.lowerToo;
    return M7PtwWhy.duty;
  }

  /// Listened to the coworker (B1: a slip here).
  DoMistake pushSlip() => _slip(M7PtwSignMistakes.listened);

  void next() {
    index++;
    if (!done) _start();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a permit: peel and lay back ≈ 3000, pen ≈ 1500, the trace ≈ 2000, the
///     tear ≈ 2000 → 8500 (+ a fault: send-back and the box ≈ 3000, an ask
///     ≈ 1500, the lower copy ≈ 4000) ≈ 9000–12500 each   ≈ 31000
///   + a reason each (~8200 × 3) + the coworker once ≈ 9600 ≈ 34200
///   + the book sliding in × 3 ≈ 1800                       ≈ 67000
/// 85 % ≈ 57000 → 60 s (a builder's estimate; owner may tune).
const m7PtwSignQuickMs = 60000;

@immutable
class M7PtwSignPack {
  const M7PtwSignPack({required this.id, required this.titleBn, this.quickMs = m7PtwSignQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7PtwSignPack> m7PtwSignPacks = {
  'do_7_4_a': M7PtwSignPack(id: 'do_7_4_a', titleBn: M7PtwSignLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7PtwSignProbe {
  static M7PtwRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7PtwSignPage extends StatefulWidget {
  const M7PtwSignPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7PtwSignPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7PtwSignPage> createState() => _M7PtwSignPageState();
}

class _M7PtwSignPageState extends State<M7PtwSignPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PtwRunPage(
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

class _PtwRunPage extends ConsumerStatefulWidget {
  const _PtwRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7PtwSignPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PtwRunPage> createState() => _PtwRunPageState();
}

enum _Drag { none, corner, edge, trace, tab }

class _PtwRunPageState extends ConsumerState<_PtwRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7PtwRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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

  /// The issuer's bubble (null: none) and a counter that keys its pop-in.
  String? _bubble;
  int _bubbleN = 0;

  /// The book's nudge toward the issuer on a send-back (keys its tween).
  int _backN = 0;

  /// The drag in hand.
  _Drag _drag = _Drag.none;
  Offset _dragFrom = Offset.zero;
  Offset _dragNow = Offset.zero;
  int _dragTab = 0;

  /// The strokes being traced and the signatures made (sheet units).
  List<Offset> _ink = [];
  List<Offset> _sigTop = const [];
  List<Offset> _sigLower = const [];

  /// The stub the player touched (it gets a swipe hint).
  int? _touchedTab;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M7PtwGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7PtwRun(m7PtwDeal(widget.rng));
    M7PtwSignProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M7PtwSignProbe.run, _run)) M7PtwSignProbe.run = null;
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze;

  String get _task => switch (_run.phase) {
        M7PtwPhase.boxPick => M7PtwSignLines.askWhere,
        M7PtwPhase.signed => M7PtwSignLines.askTear,
        _ => _run.penUp
            ? M7PtwSignLines.askSign
            : _run.sentBack
                ? M7PtwSignLines.fixedGo
                : M7PtwSignLines.askCheck,
      };

  Future<void> _start() async {
    _clock.start();
    _startPermit();
  }

  void _startPermit() {
    setState(() {
      _bubble = null;
      _ink = [];
      _sigTop = const [];
      _sigLower = const [];
      _touchedTab = null;
      _drag = _Drag.none;
    });
    if (_run.index == _run.deal.coworkerPermit && !coworkerDone && !coworkerDue) scheduleCoworker();
    unawaited(_sayChain([_task]));
  }

  /// The coworker's permit: once he is due, the pen, the send-back and the
  /// condition lines wait for him.
  bool _waitForHim() => _run.index == _run.deal.coworkerPermit && holdForCoworker();

  void _stepDone() {
    _steps++;
    setState(() {});
  }

  void _say1(String issuerLine) => setState(() {
        _bubble = issuerLine;
        _bubbleN++;
      });

  // --- hands on -----------------------------------------------------------------
  void _tapScene(Offset p, M7PtwGeo geo, Offset global) {
    if (!_canPlay) return;
    final phase = _run.phase;
    // The stubs (after signing): a tap only shows how they tear.
    if (phase == M7PtwPhase.signed) {
      for (var i = 0; i < 2; i++) {
        if (geo.tab(i).contains(p)) {
          _tick();
          setState(() => _touchedTab = i);
          _hints.missTap();
          return;
        }
      }
    }
    if (geo.pen.contains(p)) {
      _pickPen();
      return;
    }
    if (!geo.onBook(p)) {
      _hints.missTap();
      return;
    }
    final q = geo.toSheet(p);
    // The corner (lay the sheet up) or the folded sheet (lay it back): a tap
    // does what the drag does.
    if ((!_run.peeled && M7PtwSheetGeo.corner.contains(q)) || (_run.peeled && M7PtwSheetGeo.spine.contains(q))) {
      _peel();
      return;
    }
    final box = M7PtwSheetGeo.boxAt(q);
    if (box == null) {
      _hints.missTap();
      return;
    }
    final (b, line) = box;
    if (phase == M7PtwPhase.boxPick) {
      _pickBox(b, global);
      return;
    }
    if (b == M7PtwBox.condition) {
      _ask(line);
      return;
    }
    _hints.missTap();
  }

  void _peel() {
    if (!_run.togglePeel()) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.5);
    _stepDone();
  }

  void _pickPen() {
    if (_run.penUp || _run.phase == M7PtwPhase.boxPick) {
      _hints.missTap();
      return;
    }
    if (_run.phase == M7PtwPhase.deciding && _waitForHim()) return;
    if (!_run.pickPen()) return;
    _tick('sounds/intro/click.ogg', 0.55);
    _stepDone();
    unawaited(_sayChain([_task]));
  }

  void _ask(int line) {
    if (_run.phase == M7PtwPhase.deciding && _waitForHim()) return;
    final a = _run.ask(line);
    if (a == null) return;
    _tick();
    _say1(a == M7PtwAsk.cleared ? M7PtwSignLines.issuerClear : M7PtwSignLines.issuerAsIs);
    _stepDone();
  }

  void _sendBack(Offset global) {
    if (_run.phase == M7PtwPhase.deciding && _waitForHim()) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.6);
    setState(() => _backN++);
    final m = _run.sendBack();
    if (m != null) {
      _say1(M7PtwSignLines.issuerAllOk);
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.phase != M7PtwPhase.boxPick) return;
    _say1(M7PtwSignLines.issuerWhere);
    _stepDone();
    unawaited(_sayChain([_task]));
  }

  void _pickBox(M7PtwBox b, Offset global) {
    final m = _run.pickBox(b);
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, global));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    _say1(M7PtwSignLines.issuerFixed);
    // Sent back after signing: the corrected permit is signed afresh.
    if (!_run.topSigned) {
      _sigTop = const [];
      _sigLower = const [];
      _touchedTab = null;
    }
    _stepDone();
    unawaited(_sayChain([_task]));
  }

  void _signed(List<Offset> stroke, Offset global) {
    final top = !_run.peeled;
    final (ok, m) = _run.trace(M7PtwSheetGeo.coverage(stroke));
    if (!ok) {
      _hints.missTap();
      setState(() => _ink = []);
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    setState(() {
      if (top) {
        _sigTop = stroke;
      } else {
        _sigLower = stroke;
      }
      _ink = [];
      _bubble = null;
    });
    _steps++;
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    unawaited(_sayChain([_task]));
  }

  void _tear(int tab, Offset global) {
    final copy = tab == 0 ? _run.permit.topCopy : _run.permit.lowerCopy;
    final m = _run.tear(copy);
    _tick('sounds/learn/card_deal_a.ogg', 0.7);
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.roundDone) {
      _stepDone();
      unawaited(_permitDone());
    }
  }

  void _panStart(Offset p, M7PtwGeo geo) {
    _drag = _Drag.none;
    if (!_canPlay) return;
    _dragFrom = p;
    _dragNow = p;
    if (_run.phase == M7PtwPhase.signed) {
      for (var i = 0; i < 2; i++) {
        if (geo.tab(i).contains(p)) {
          _drag = _Drag.tab;
          _dragTab = i;
          return;
        }
      }
    }
    if (!geo.onBook(p)) return;
    final q = geo.toSheet(p);
    if (M7PtwSheetGeo.spine.contains(q)) {
      _drag = _Drag.edge;
      return;
    }
    if (!_run.peeled && M7PtwSheetGeo.corner.contains(q)) {
      _drag = _Drag.corner;
      return;
    }
    if (M7PtwSheetGeo.receiver.inflate(6).contains(q)) {
      // The copy beneath is signed only after the top sheet: lay it back
      // first (the hand shows how).
      if (!_run.penUp || (_run.phase == M7PtwPhase.deciding && _run.peeled)) {
        _hints.missTap();
        return;
      }
      _drag = _Drag.trace;
      setState(() => _ink = [q]);
    }
  }

  void _panUpdate(Offset p, M7PtwGeo geo) {
    if (_drag == _Drag.none) return;
    if (!_canPlay) {
      _drag = _Drag.none;
      return;
    }
    _dragNow = p;
    if (_drag == _Drag.trace) {
      final q = geo.toSheet(p);
      setState(() => _ink = [..._ink, q]);
    }
  }

  void _panEnd(Offset global) {
    final d = _drag;
    _drag = _Drag.none;
    if (d == _Drag.none || !_canPlay) return;
    final move = _dragNow - _dragFrom;
    switch (d) {
      case _Drag.corner:
        if (move.dy < -20) {
          _peel();
        } else {
          _hints.missTap();
        }
      case _Drag.edge:
        if (move.dy < -34 && move.dy.abs() > move.dx.abs()) {
          _sendBack(global);
        } else if (_run.peeled && move.dy > 18) {
          _peel();
        } else {
          _hints.missTap();
        }
      case _Drag.trace:
        _signed(_ink, global);
      case _Drag.tab:
        if (move.dx.abs() >= 60 && move.dy.abs() < 40) {
          _tear(_dragTab, global);
        } else {
          setState(() => _touchedTab = _dragTab);
          _hints.missTap();
        }
      case _Drag.none:
        break;
    }
  }

  Future<void> _permitDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _run.why;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M7PtwSignLines.whyRight[topic]!, M7PtwSignLines.myths, widget.rng),
      question: M7PtwSignLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startPermit();
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
  CoworkerScript get coworkerScript => M7PtwSignLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerPermit || _run.phase != M7PtwPhase.deciding) return null;
    if (_intro || _card != null || tableBusy || _freeze) return false;
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
    _run.caught.add(M7PtwSignLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7PtwSignLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7PtwSignLines.tapWhy[_nudgeN++ % M7PtwSignLines.tapWhy.length]
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
      _drag = _Drag.none;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7ptw/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The field copy without the issuer's signature taken to the line: the
  /// counter freezes grey, the crew on a line nobody certified plays in
  /// colour; then near-miss or death.
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
      _drag = _Drag.none;
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
    final speak = await SpokenOnce.first('m7ptw/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M7PtwSignLines.deadlyWord : M7PtwSignLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same permit goes on from where it was.
        _hush();
        setState(() => _card = null);
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
    await _say(!_run.passed ? M7PtwSignLines.fail : (_quickBonus ? M7PtwSignLines.quick : M7PtwSignLines.allSet),
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
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    HintSpec peelNudge() => _run.peeled
        ? HintSpec.drag(geo.spine.center, toward: const Offset(0, 1), travel: 30, space: HintSpace.scene)
        : HintSpec.drag(geo.corner.center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
    switch (_run.phase) {
      case M7PtwPhase.boxPick:
        return HintSpec.sweep(geo.boxes, space: HintSpace.scene);
      case M7PtwPhase.signed:
        final t = _touchedTab;
        if (t != null) return HintSpec.swipe(geo.tab(t).centerLeft.translate(14, 0), toward: const Offset(1, 0), travel: 90, space: HintSpace.scene);
        return n.isEven ? peelNudge() : HintSpec.sweep([geo.spine, geo.tab(0), geo.tab(1)], space: HintSpace.scene);
      case M7PtwPhase.deciding:
        // Pen up on the folded-up sheet: lay it back first.
        if (_run.penUp && _run.peeled) return peelNudge();
        if (_run.penUp) return HintSpec.drag(geo.lineStart, toward: const Offset(1, 0), travel: 90, space: HintSpace.scene);
        if (!_run.peeked || n.isEven) return peelNudge();
        return HintSpec.sweep([geo.pen, geo.spine, geo.cond(0), geo.cond(1)], space: HintSpace.scene);
      case M7PtwPhase.done:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7PtwGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final p = _run.permit;
    final topSheet = _run.sheet(p.topCopy);
    final lowerSheet = _run.sheet(p.lowerCopy);
    final tracingTop = _drag == _Drag.trace && !_run.peeled;
    final tracingLower = _drag == _Drag.trace && _run.peeled;
    final book = Positioned.fromRect(
      key: ValueKey('book-${_run.index}'),
      rect: geo.book,
      child: _BookSlide(
        index: _run.index,
        backN: _backN,
        quiet: quiet,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox.fromSize(
            size: M7PtwSheetGeo.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_run.peeled) ...[
                  Positioned.fill(
                    key: const ValueKey('lower'),
                    child: _SheetView(
                      sheet: lowerSheet,
                      sig: lowerSheet.receiverSigned ? (_sigLower.isNotEmpty ? _sigLower : _sigTop) : const [],
                      carbon: _sigLower.isEmpty,
                      ink: tracingLower ? _ink : const [],
                      top: false,
                    ),
                  ),
                  const Positioned(key: ValueKey('flap'), left: 0, top: 0, right: 0, height: 26, child: _Flap()),
                ] else
                  Positioned.fill(
                    key: const ValueKey('top'),
                    child: _SheetView(
                      sheet: topSheet,
                      sig: topSheet.receiverSigned ? _sigTop : const [],
                      carbon: false,
                      ink: tracingTop ? _ink : const [],
                      top: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('room'),
                child: RepaintBoundary(child: CustomPaint(painter: M7PtwRoomPainter(geo: geo))),
              ),
              book,
              Positioned.fromRect(
                key: const ValueKey('pen'),
                rect: geo.pen,
                child: _Pen(up: _run.penUp, quiet: quiet),
              ),
              if (_run.phase == M7PtwPhase.signed)
                for (var i = 0; i < 2; i++)
                  Positioned.fromRect(
                    key: ValueKey('tab-$i-${_run.index}'),
                    rect: geo.tab(i),
                    child: _Stub(label: M7PtwSignLines.copy(i == 0 ? p.topCopy : p.lowerCopy)),
                  ),
              if (_bubble != null)
                Positioned.fromRect(
                  key: ValueKey('bubble-$_bubbleN'),
                  rect: geo.bubble,
                  child: _IssuerBubble(text: _bubble!, quiet: quiet),
                ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7PtwSignLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height * 0.5)),
            onPanCancel: () {
              _drag = _Drag.none;
              if (_ink.isNotEmpty) setState(() => _ink = []);
            },
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('inset'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1800),
              builder: (_, v, _) => CustomPaint(painter: M7PtwInsetPainter(rect: geo.inset, v: v)),
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
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
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
              labels: M7PtwSignLines.permits,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _drag == _Drag.none,
            hintKey: '${_run.index}/${_run.phase.name}/${_run.peeled}/${_run.penUp}/$_touchedTab/$_steps',
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
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
                  line: M7PtwSignLines.intro,
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

/// The book sliding over the counter at a new permit, and its short push
/// toward the issuer on a send-back (both end still).
class _BookSlide extends StatelessWidget {
  const _BookSlide({required this.index, required this.backN, required this.quiet, required this.child});
  final int index;
  final int backN;
  final bool quiet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (quiet) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey('in-$index'),
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Transform.translate(offset: Offset(0, -60 * v), child: Opacity(opacity: 1 - v * 0.8, child: c)),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('back-$backN'),
        tween: Tween(begin: backN == 0 ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 420),
        builder: (_, v, c) => Transform.translate(offset: Offset(0, -26 * math.sin(v * math.pi)), child: c),
        child: child,
      ),
    );
  }
}

/// One sheet of the carbon book (300 × 250 units).
class _SheetView extends StatelessWidget {
  const _SheetView({required this.sheet, required this.sig, required this.carbon, required this.ink, required this.top});
  final M7PtwSheet sheet;

  /// The receiver's signature (empty: none), in carbon blue when it came
  /// through from the top sheet.
  final List<Offset> sig;
  final bool carbon;

  /// The stroke being traced on this sheet now.
  final List<Offset> ink;
  final bool top;

  static const _ink = Color(0xFF2A2018);

  @override
  Widget build(BuildContext context) {
    final label = bangla(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF6A5A44));
    final value = bangla(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1A3A8A));
    Widget box(Rect r, String name, Widget? v) => Positioned.fromRect(
          rect: r,
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF9C8A6A), width: 1)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(name, style: label))),
                  const SizedBox(width: 4),
                  Expanded(child: Align(alignment: Alignment.centerRight, child: v ?? const SizedBox.shrink())),
                ],
              ),
            ),
          ),
        );
    Widget text(String s) => FittedBox(fit: BoxFit.scaleDown, child: Text(s, maxLines: 1, style: value));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: top ? const Color(0xFFFBF7EC) : const Color(0xFFF3ECDA),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The spine strip (the book's top edge, swiped up = sent back).
          Positioned.fromRect(
            rect: M7PtwSheetGeo.spine,
            child: ColoredBox(
              color: const Color(0xFF3C5A78),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.keyboard_double_arrow_up_rounded, size: 16, color: Color(0xFFE8D9B0)),
                  const SizedBox(width: 3),
                  Text(M7PtwSignLines.sendBack, style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFE8D9B0))),
                ],
              ),
            ),
          ),
          Positioned.fromRect(
            rect: M7PtwSheetGeo.label,
            child: Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(M7PtwSignLines.ptw, style: bangla(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF6A5A44))),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(M7PtwSignLines.copy(sheet.copy), style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF8A2A16))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          box(M7PtwSheetGeo.number, M7PtwSignLines.number, text(enDigits('${sheet.number}'))),
          box(M7PtwSheetGeo.feeder, M7PtwSignLines.feeder, text(enDigits(sheet.feeder))),
          box(M7PtwSheetGeo.date, M7PtwSignLines.date, sheet.date == null ? null : text(enDigits(sheet.date!))),
          box(M7PtwSheetGeo.time, M7PtwSignLines.time, sheet.time == null ? null : text(enDigits(sheet.time!))),
          box(
            M7PtwSheetGeo.issuer,
            M7PtwSignLines.issuer,
            sheet.issuerSigned
                ? SizedBox(width: 120, height: 28, child: CustomPaint(painter: M7PtwScribblePainter(seed: sheet.number % 97 + 3, color: carbon || !top ? const Color(0xFF3A4A9A) : const Color(0xFF1A3A8A))))
                : null,
          ),
          Positioned.fromRect(rect: M7PtwSheetGeo.condLabel, child: Text(M7PtwSignLines.conditions, style: label)),
          for (var i = 0; i < 2; i++)
            Positioned.fromRect(
              rect: M7PtwSheetGeo.cond(i),
              child: DecoratedBox(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFCBBE9E), width: 1))),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: sheet.smudged == i
                        ? Stack(
                            children: [
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 2.6, sigmaY: 1.8),
                                child: Text('${i + 1}. ${sheet.conditions[i]}', maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF55607A))),
                              ),
                              Positioned.fill(child: CustomPaint(painter: _SmudgePainter(seed: i))),
                            ],
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(enDigits('${i + 1}. ${sheet.conditions[i]}'), maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: _ink)),
                          ),
                  ),
                ),
              ),
            ),
          // The receiver's box: the dotted line to trace.
          Positioned.fromRect(
            rect: M7PtwSheetGeo.receiver,
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF9C8A6A), width: 1)),
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Align(alignment: Alignment.topLeft, child: Text(M7PtwSignLines.receiver, style: label)),
              ),
            ),
          ),
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _DottedLinePainter()))),
          if (sig.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: M7PtwInkPainter(points: sig, count: sig.length, color: carbon ? const Color(0xFF3A4A9A) : const Color(0xFF1A3A8A)))),
            ),
          if (ink.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: M7PtwInkPainter(points: ink, count: ink.length, color: const Color(0xFF1A3A8A)))),
            ),
          // The dog-eared corner (only the top sheet is peeled by it).
          if (top) const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _CornerPainter()))),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter();

  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = const Color(0xFF7A6A50)
      ..strokeWidth = 1.2;
    for (var x = M7PtwSheetGeo.lineX0; x < M7PtwSheetGeo.lineX1; x += 6) {
      c.drawLine(Offset(x, M7PtwSheetGeo.lineY), Offset(math.min(x + 3, M7PtwSheetGeo.lineX1), M7PtwSheetGeo.lineY), p);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) => false;
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    final fold = Path()
      ..moveTo(w - 26, h)
      ..lineTo(w, h - 26)
      ..lineTo(w - 22, h - 22)
      ..close();
    c.drawPath(fold, Paint()..color = const Color(0xFFE2D6B8));
    c.drawPath(fold, Paint()
      ..color = const Color(0xFF9C8A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

class _SmudgePainter extends CustomPainter {
  const _SmudgePainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final r = math.Random(seed + 11);
    final p = Paint()..color = const Color(0x88505A70);
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.1 + r.nextDouble() * 0.6);
      c.drawOval(Rect.fromCenter(center: Offset(x, size.height * 0.5), width: 22 + r.nextDouble() * 26, height: 9 + r.nextDouble() * 5), p);
    }
  }

  @override
  bool shouldRepaint(_SmudgePainter old) => old.seed != seed;
}

/// The top sheet folded up over the spine while the copy beneath shows.
class _Flap extends StatelessWidget {
  const _Flap();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9E1CC), Color(0xFFCFC3A4)]),
        boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 4))],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      child: Center(child: Icon(Icons.keyboard_double_arrow_down_rounded, size: 16, color: const Color(0xFF8C7C5E).withValues(alpha: 0.9))),
    );
  }
}

/// The pen on the counter; picked up, it lifts and tilts.
class _Pen extends StatelessWidget {
  const _Pen({required this.up, required this.quiet});
  final bool up;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final pen = CustomPaint(painter: _PenPainter(up: up));
    return Semantics(
      label: M7PtwSignLines.penLabel,
      child: quiet
          ? pen
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: up ? 1 : 0),
              duration: const Duration(milliseconds: 240),
              builder: (_, v, c) => Transform.translate(offset: Offset(0, -8 * v), child: Transform.rotate(angle: -0.25 * v, child: c)),
              child: pen,
            ),
    );
  }
}

class _PenPainter extends CustomPainter {
  _PenPainter({required this.up});
  final bool up;

  @override
  void paint(Canvas c, Size size) {
    final h = size.height, w = size.width;
    final y = h * 0.5;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, y + (up ? 10 : 4), w - 20, 6), const Radius.circular(3)), Paint()..color = Color(up ? 0x22000000 : 0x44000000));
    final body = Rect.fromLTWH(14, y - 5, w - 40, 10);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(5)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3F6FC4), Color(0xFF1C3D7A)]).createShader(body));
    final tip = Path()
      ..moveTo(body.right, body.top + 1)
      ..lineTo(body.right + 16, y)
      ..lineTo(body.right, body.bottom - 1)
      ..close();
    c.drawPath(tip, Paint()..color = const Color(0xFFD9C9A0));
    c.drawCircle(Offset(body.right + 15, y), 1.6, Paint()..color = const Color(0xFF1A3A8A));
    c.drawRect(Rect.fromLTWH(body.left + 8, body.top - 2, 26, 3), Paint()..color = const Color(0xFFC9CED6));
  }

  @override
  bool shouldRepaint(_PenPainter old) => old.up != up;
}

/// A perforated stub of one copy (swiped along to tear it off).
class _Stub extends StatelessWidget {
  const _Stub({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PerforationPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 3, 6, 0),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF8A2A16)))),
          ),
        ],
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter();

  @override
  void paint(Canvas c, Size size) {
    final p = Paint()..color = const Color(0xFF7A6A50);
    final y = size.height * 0.72;
    for (var x = 6.0; x < size.width - 4; x += 7) {
      c.drawCircle(Offset(x, y), 1.4, p);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => false;
}

/// The issuer's speech bubble (text only, no voice).
class _IssuerBubble extends StatelessWidget {
  const _IssuerBubble({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final b = Align(
      alignment: Alignment.topLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5E8DB6), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 5, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(text, maxLines: 2, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF1C2A3A))),
        ),
      ),
    );
    if (quiet) return b;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (_, v, c) => Transform.scale(scale: v, alignment: Alignment.centerLeft, child: c),
      child: b,
    );
  }
}
