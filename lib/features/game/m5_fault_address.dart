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
import 'm5_fault_address_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

// Lesson 5.2 "লাইন পেট্রোলিং-এর সঠিক নিয়ম", কাজ 1 "ফল্টের ঠিকানা" (pack
// do_5_2_a, engineType m5_fault_address). Three calls on three feeders:
//
//  • A tripped feeder: the van is dealt at the depot, mid-route or the load
//    end. Drag it along the road; tap an FPI box beside it for the close-up
//    (its LED bright and flashing, or dark); the reading is written on the
//    map card (and chalked on the box). Read from the source end, stop at
//    every T-off, then drag the two bracket flags onto the read FPIs that
//    hold the fault between them.
//  • A long feeder: two teams — drag van 2 to the far end first (its team
//    then radios its readings from the load end); driving off alone = a slip.
//  • An in-service feeder (sectionalizer call, ground only): one stretch
//    stays dark; bracket from the sectionalizer (open) to the next FPI.
//  • About half the plays: a history note on the bracketed section
//    ('এই পোলে আগেও 3 বার ফল্ট') → what now? (repair only = a slip).
//
// The lesson's rules, and only those (lesson 5.2):
//   • point 1: source first ("সাবস্টেশন বা ফিডারের শুরু থেকে … লোডের দিকে"),
//     T-off points first ("ফল্ট হওয়ার সম্ভাবনা বেশি … প্রথমে এই জায়গাগুলো"),
//     a long line split between two teams from both ends, keep in contact;
//   • engineering facts: the FPI lights a bright LED when fault current passes
//     ("যে দুটি FPI-এর মাঝখানে ফল্টটি হয়েছে, তা সহজেই বোঝা যায়"); the
//     sectionalizer cuts off only the faulty section;
//   • myth 2: a fault is not only a broken wire (dirt on an insulator, a bird
//     or a lizard leaves no sign) — the coworker's push;
//   • pro tip 3: the same place faulting again and again → find the root
//     cause; pro tip 4: carry the feeder map (T-offs).
// Module 5 rulings (docs/module_specs/module5_rulings.md, M5-3): on a tripped
// feeder the patrol starts by informing the control room and taking the
// docket — a tap on the radio (রেডিও · কন্ট্রোল রুম) fills in the docket chip;
// driving off, sending van 2 or reading an FPI before it is a slip (once a
// call; the van stays until the docket is in). Ground patrol of an in-service
// line needs no PTW (the sectionalizer call says "ground only", no docket
// step); nobody climbs or touches the line in this level.
//
// Deadly: none (item spec). Slips: patrolling before the docket; first
// reading away from the source end; passing a T-off without reading its
// branch FPI; a long feeder driven alone; listening to the coworker (R29: a
// myth, no immediate danger); a wrong bracket; repair only on the history
// note. Three slips strike the level out. A needless stop (a reading the ones
// in hand already tell) costs the clean-call +5 and draws a guide nudge.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m5_fault_address_world.dart) with a camera that follows the
// van, corner guide, ◆ on the table → "কেন …?" after the right moves, the
// careless coworker once a play on the 2nd reading of one dealt call (the van,
// the next reading and the flags wait for him: holdForCoworker), gesture
// hands (how, never what). Voice: the guide and the second team's radio by
// device TTS; the coworker's new line has no clip yet (silent, caption held
// — the director records it); his exit line is his existing clip.

// ============================================================================
// Content
// ============================================================================

/// Why a ◆ waits on the table.
enum M5FaReason { source, tee, long, bracket, root }

abstract final class M5FaLines {
  static const title = 'ফল্টের ঠিকানা';
  static const intro = 'ফিডার ট্রিপ করেছে! কোথায় ফল্ট, খুঁজে বের করুন।';
  static const callLong = 'লম্বা ফিডার ট্রিপ করেছে! ফল্টটা খুঁজে বের করুন।';
  static const callSect = 'ফিডার চালু, কিন্তু এক অংশ অন্ধকার! ফল্টটা খুঁজুন।';
  static const callTrip = 'আরেকটা ফিডার ট্রিপ! কোথায় ফল্ট, খুঁজুন।';
  static String callLine(M5FaKind k, {required bool first}) => switch (k) {
        M5FaKind.trip => first ? intro : callTrip,
        M5FaKind.long => callLong,
        M5FaKind.sectionalizer => callSect,
      };
  static const kinds = {M5FaKind.trip: 'ট্রিপ', M5FaKind.long: 'লম্বা ফিডার', M5FaKind.sectionalizer: 'চালু ফিডার'};

  // The guide's task now (tap him: the same task, a different way).
  static const askStart = 'কোথা থেকে শুরু করবেন?';
  static const askRead = 'ভ্যান চালিয়ে FPI দেখে দেখে এগোন।';
  static const askLong = 'লাইন অনেক লম্বা। কীভাবে খুঁজবেন?';
  static const askSect = 'চালু লাইন — মাটি থেকেই খুঁজুন।';
  static const askHistory = 'এই অংশে বারবার ফল্ট। কী করবেন?';
  static const tasks = [askStart, askRead, askLong, askSect, askHistory];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const tooFar = 'আগে ভ্যানটা ওই পোলের পাশে নিন।';

  /// Said only after the no-docket slip (the card has taught it by then).
  static const askDocket = 'আগে রেডিওতে কন্ট্রোল রুমকে জানিয়ে ডকেট নিন।';

  /// A needless stop: the bracket is already in hand / the reading was known.
  static const needlessDone = 'ফল্টের দুই পাশ তো পাওয়া গেছে — পতাকা বসান।';
  static const needlessKnown = 'এই FPI-এর খবর তো আগের রিডিং থেকেই জানা।';

  // Labels a worker reads.
  static const sceneLabel = 'ফিডার';
  static const map = 'ম্যাপ';
  static const flags = 'পতাকা';
  static const radio = 'রেডিও · কন্ট্রোল রুম';
  static const lit = 'জ্বলছে';
  static const dark = 'নেভা';
  static const open = 'খোলা';
  static const closeTap = 'বন্ধ করতে ছুঁয়ে দিন';
  static String pole(String p) => 'পোল ${enDigits(p)}';
  static String docket(M5FaCall c) => c.inService
      ? enDigits('ফিডার ${c.feeder} · চালু লাইন · শুধু মাটি থেকে')
      : enDigits('ফিডার ${c.feeder} · ডকেট ${c.docket} · কন্ট্রোল রুম জানে');

  /// The chip before the docket is in (a tripped feeder).
  static String feederOnly(M5FaCall c) => enDigits('ফিডার ${c.feeder}');

  /// The control room's reply on the radio.
  static String control(M5FaCall c) => enDigits('কন্ট্রোল রুম: ফিডার ${c.feeder} জানা গেল — ডকেট ${c.docket}, টহলে যান।');
  static const teamGone = 'দল 2 অন্য মাথার দিকে রওনা হলো।';
  static String team(M5FaNode n, bool on) => enDigits('দল 2: পোল ${n.pole} — ${on ? (n.sectionalizer ? open : lit) : dark}');
  static const historyNote = 'এই পোলে আগেও 3 বার ফল্ট';

  // The reasons (◆ on the table). The right ones fit what was done; the wrong
  // ones are the lesson's myth and field excuses. 42–51 letters.
  static const sourceQ = 'সাবস্টেশন থেকে কেন শুরু করলেন?';
  static const teeQ = 'টি-অফে আগে কেন থামলেন?';
  static const bracketQ = 'কেন এই অংশটাই?';
  static const longQ = 'লম্বা লাইনে দুই দল দুই মাথা থেকে কেন?';
  static const rootQ = 'শুধু মেরামত না করে কেন মূল কারণ খুঁজবেন?';
  static const sourceWhy = ['সোর্স থেকে লোডের দিকে গেলে কোনো অংশ বাদ যায় না', 'সাবস্টেশন থেকে শুরু করে লোডের দিকে এগোনোই নিয়ম'];
  static const teeWhy = ['টি-অফ পয়েন্টে ফল্ট হওয়ার সম্ভাবনা বেশি থাকে', 'শাখা লাইনে ফল্ট কি না, আগে দেখে তবে সামনে এগোই'];
  static const bracketWhy = ['আগের FPI জ্বলছে, পরেরটা নেভা — ফল্ট এই দুইয়ের মাঝে', 'ফল্ট কারেন্ট আগের FPI পেরিয়েছে, পরেরটা পেরোয়নি'];
  static const sectWhy = ['সেকশনালাইজার খুলেছে, পরের FPI নেভা — ফল্ট মাঝে', 'সেকশনালাইজার ফল্টি অংশটাকেই আলাদা করে দিয়েছে'];
  static const longWhy = ['লাইন ভাগ করে দুই দিক থেকে খুঁজলে দ্রুত পাওয়া যায়', 'দুই দল দুই মাথা থেকে, রেডিওতে যোগাযোগ রেখে খুঁজি'];
  static const rootWhy = ['বারবার ফল্ট মানে সেখানে কোনো স্থায়ী সমস্যা আছে', 'ডাল কাছে বা ইনসুলেশন দুর্বল — না সারালে আবার ফল্ট'];
  static const myths = [
    'ভাঙা কিছু চোখে না পড়লে লাইনে কোনো ফল্টই নেই',
    'যেখান থেকে খুশি শুরু করলেই হলো, সব তো একই লাইন',
    'তাড়াতাড়ি সারতে হবে, তাই সবচেয়ে কাছের পোল থেকে',
    'একা খুঁজলেই চলে, রেডিওতে কথা বলা সময় নষ্ট',
    'FPI-এর বাতি দেখে লাভ নেই, পুরো লাইন হাঁটতেই হবে',
    'যে পোলে ভ্যান থামল, ফল্ট নিশ্চয়ই সেখানেই হয়েছে',
    'জোড়া দিয়ে লাইন চালু করলেই কাজ শেষ, কারণ খোঁজা বাড়তি',
  ];
  static List<String> get allWhyRight => [...sourceWhy, ...teeWhy, ...bracketWhy, ...sectWhy, ...longWhy, ...rootWhy];

  static List<String> whyRight(M5FaReason r, M5FaKind k) => switch (r) {
        M5FaReason.source => sourceWhy,
        M5FaReason.tee => teeWhy,
        M5FaReason.bracket => k == M5FaKind.sectionalizer ? sectWhy : bracketWhy,
        M5FaReason.long => longWhy,
        M5FaReason.root => rootWhy,
      };
  static String whyQuestion(M5FaReason r) => switch (r) {
        M5FaReason.source => sourceQ,
        M5FaReason.tee => teeQ,
        M5FaReason.bracket => bracketQ,
        M5FaReason.long => longQ,
        M5FaReason.root => rootQ,
      };

  /// The history note: what now? (pro tip 3).
  static const historyRight = ['শুধু মেরামত নয় — মূল কারণ খুঁজি', 'বারবার কেন হয়, সেই মূল কারণ খুঁজি'];
  static const historyWrong = [
    'আগের মতোই জোড়া দিয়ে কাজ শেষ করি',
    'যেটা ভেঙেছে, শুধু সেটুকুই সারাই',
    'বারবার হয় হোক, আজ মেরামত সারি',
    'কারণ খোঁজা পরে, আগে জুড়ে দিয়ে ফিরি',
    'পুরোনো ফল্ট, তাই এবারও একই মেরামত',
  ];

  /// The careless coworker: nothing is broken — turn back (myth 2).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'ফল্ট মানেই তার ছিঁড়ে যাওয়া বা কিছু ভেঙে যাওয়া। কিছুই তো ভাঙা নেই — ফিরে চলো!',
    exitLine: coworkerExit,
    right: ['না — চিহ্ন ছাড়াও ফল্ট হয়, FPI ধরে এগোই', 'না, ময়লা বা পাখিতেও চিহ্ন ছাড়া ফল্ট হয়', 'না, FPI-এর বাতি ধরেই ফল্টটা খুঁজে বের করি'],
    wrong: [
      'ঠিকই, কিছুই তো ভাঙা নেই — ফিরে চলি',
      'ভাঙা তার না দেখলে লাইনে ফল্ট নেই',
      'হ্যাঁ, চোখে তো কিছু নেই, চলো ফিরে যাই',
      'আচ্ছা, ভাঙা কিছু পেলাম না, এবার ফিরি',
      'হ্যাঁ, FPI-এর বাতি বাদ দিয়ে ফিরে চলি',
    ],
    asks: ['ওঁর কথা শুনবেন?', 'ভাঙা কিছু না দেখলে কি ফল্ট নেই?', 'ফিরে যাবেন, না FPI ধরে এগোবেন?'],
  );

  /// His lines that still need his recorded voice (the director records them).
  static const rivalLinesMissing = [
    'ফল্ট মানেই তার ছিঁড়ে যাওয়া বা কিছু ভেঙে যাওয়া। কিছুই তো ভাঙা নেই — ফিরে চলো!',
  ];

  static const callHeld = 'ঠিক! চিহ্ন না থাকলেও ফল্ট থাকে — FPI ধরে এগোই।';
  static const allSet = 'ফল্টের ঠিকানা মিলেছে! এবার ওই অংশটা হেঁটে দেখার পালা।';
  static const quick = 'নিখুঁত আর ঝটপট! এবার ওই অংশটা হেঁটে দেখার পালা।';
  static const fail = 'আরেকবার — সোর্স থেকে শুরু, টি-অফ আগে, তারপর দুই FPI-এর মাঝে।';

  // "আজ যা ধরলেন".
  static const caughtSource = 'সাবস্টেশন থেকে লোডের দিকে খুঁজেছেন';
  static const caughtTee = 'টি-অফে আগে থেমেছেন';
  static const caughtSplit = 'লম্বা লাইনে দুই দল দুই মাথা থেকে';
  static const caughtBracket = 'দুই FPI-এর মাঝে ফল্ট ঘিরেছেন';
  static const caughtRoot = 'বারবার ফল্টে মূল কারণ খুঁজেছেন';
  static const caughtCall = 'ভাঙা না দেখেও FPI ধরে এগিয়েছেন';
  static const caughtDocket = 'কন্ট্রোলকে জানিয়ে ডকেট নিয়েছেন';
}

abstract final class M5FaMistakes {
  static const _dir = 'assets/game/art/m5_fault_address';

  /// Ruling M5-3 (R6): the card text word for word (as in do_5_7_a). The
  /// lesson has no numbered point for it, so no পাঠে দেখুন.
  static const noDocket = DoMistake(
    key: '5.2/m5_fault_address/no-docket',
    textBn: 'টহলের আগে কন্ট্রোল রুমকে জানিয়ে ফিল্ড মেমো/ডকেট নিন; লাইনে হাত দেওয়া বা ওঠার আগে PTW বাধ্যতামূলক।',
    art: '$_dir/no_docket.svg',
  );

  /// Lesson 5.2 point 1 (index 0): "সোর্স থেকে শুরু".
  static const farStart = DoMistake(
    key: '5.2/m5_fault_address/far-start',
    textBn: 'পেট্রোলিং শুরু সোর্স থেকে — সাবস্টেশনের দিকের প্রথম FPI আগে, তারপর লোডের দিকে এগোন।',
    art: '$_dir/far_start.svg',
    lessonPoint: 0,
  );

  /// Point 1: "টি-অফ পয়েন্টে মনোযোগ".
  static const skipTee = DoMistake(
    key: '5.2/m5_fault_address/skip-tee',
    textBn: 'টি-অফ পেরিয়ে গেলেন! টি-অফে ফল্টের সম্ভাবনা বেশি — শাখার FPI আগে দেখে তবে এগোন।',
    art: '$_dir/skip_tee.svg',
    lessonPoint: 0,
  );

  /// Point 1: "ভাগ করে নিন … দুই দিক থেকে … যোগাযোগ বজায় রাখুন".
  static const alone = DoMistake(
    key: '5.2/m5_fault_address/alone',
    textBn: 'লাইন খুব লম্বা — দল ভাগ করে দুই মাথা থেকে খুঁজুন, রেডিওতে যোগাযোগ রাখুন।',
    art: '$_dir/alone.svg',
    lessonPoint: 0,
  );

  /// Myth 2 (the coworker's push). Point 2 (index 1) opens with "অনেক সময়
  /// ফল্টটি সরাসরি চোখে দেখা যায় না".
  static const listened = DoMistake(
    key: '5.2/m5_fault_address/listened',
    textBn: 'ভাঙা কিছু না থাকলেও ফল্ট হয় — ইনসুলেটরে ময়লা বা পাখি-গিরগিটিও চিহ্ন ছাড়া ফল্ট ঘটায়। FPI ধরে এগোন।',
    art: '$_dir/listened.svg',
    lessonPoint: 1,
  );

  /// The FPI fact (the lesson's engineering facts — not a numbered point).
  static const wrongBracket = DoMistake(
    key: '5.2/m5_fault_address/wrong-bracket',
    textBn: 'ফল্ট সেই দুই FPI-এর মাঝে, যার আগেরটা জ্বলছে আর ঠিক পরেরটা নেভা।',
    art: '$_dir/wrong_bracket.svg',
  );

  /// The sectionalizer fact (engineering facts).
  static const wrongSect = DoMistake(
    key: '5.2/m5_fault_address/wrong-sect',
    textBn: 'সেকশনালাইজার শুধু ফল্টি অংশটা আলাদা করে — সেটা থেকে পরের নেভা FPI পর্যন্ত।',
    art: '$_dir/wrong_bracket.svg',
  );

  /// Pro tip 3 ("ইতিহাস পুনরাবৃত্তি করে").
  static const repairOnly = DoMistake(
    key: '5.2/m5_fault_address/repair-only',
    textBn: 'একই জায়গায় বারবার ফল্ট মানে স্থায়ী সমস্যা (ডাল খুব কাছে, দুর্বল ইনসুলেশন)। শুধু মেরামত নয় — মূল কারণ খুঁজুন।',
    art: '$_dir/repair_only.svg',
  );

  static List<DoMistake> get all => [noDocket, farStart, skipTee, alone, listened, wrongBracket, wrongSect, repairOnly];
}

// ---- the deal --------------------------------------------------------------

/// Route templates: main-line FPIs (fractions of the line) and the gaps that
/// carry a T-off (between main FPI i and i + 1).
const m5FaTemplates = <(List<double>, List<int>)>[
  ([0.10, 0.36, 0.62, 0.92], [1]),
  ([0.09, 0.30, 0.52, 0.74, 0.95], [0, 2]),
  ([0.12, 0.40, 0.68, 0.93], [2]),
  ([0.10, 0.33, 0.56, 0.79, 0.96], [0, 2]),
];
const m5FaLongFracs = [0.06, 0.21, 0.36, 0.51, 0.66, 0.81, 0.96];
const m5FaLength = 980.0;
const m5FaLongLength = 1500.0;

@immutable
class M5FaDeal {
  const M5FaDeal({required this.calls, required this.coworkerCall, required this.historyCall});
  final List<M5FaCall> calls;

  /// He comes on the 2nd reading of this call.
  final int coworkerCall;

  /// The bracketed section of this call has a fault history (or none).
  final int? historyCall;
}

M5FaCall m5FaCall(M5FaKind kind, math.Random rng) {
  final long = kind == M5FaKind.long;
  final length = long ? m5FaLongLength : m5FaLength;
  final template = long ? -1 : rng.nextInt(m5FaTemplates.length);
  final fracs = long ? m5FaLongFracs : m5FaTemplates[template].$1;
  List<int> tees;
  if (long) {
    final gaps = [for (var i = 0; i < fracs.length - 1; i++) i]..shuffle(rng);
    tees = gaps.take(1 + rng.nextInt(2)).toList()..sort();
  } else {
    tees = [...m5FaTemplates[template].$2];
    if (kind == M5FaKind.sectionalizer) tees = rng.nextBool() ? tees.take(1).toList() : const [];
  }
  double jit(double r) => (rng.nextDouble() * 2 - 1) * r;
  final mainS = [for (final f in fracs) f * length + jit(10)];
  final base = 11 + rng.nextInt(30);
  String poleAt(double s) => '${base + (s / 58).round()}';
  final branches = <M5FaBranch>[
    for (final g in tees)
      M5FaBranch(
        s: (mainS[g] + mainS[g + 1]) / 2 + jit(8),
        grove: false,
        lean: jit(0.16),
      ),
  ];
  // One T-off may run under a mango grove (not on the in-service call).
  if (branches.isNotEmpty && kind != M5FaKind.sectionalizer && rng.nextDouble() < 0.45) {
    final k = rng.nextInt(branches.length);
    final b = branches[k];
    branches[k] = M5FaBranch(s: b.s, grove: true, lean: b.lean);
  }
  final sectAt = kind == M5FaKind.sectionalizer ? 1 + rng.nextInt(math.min(2, mainS.length - 2)) : -1;
  final nodes = <M5FaNode>[
    for (final (i, s) in mainS.indexed) M5FaNode(id: i, s: s, order: i, pole: poleAt(s), sectionalizer: i == sectAt),
  ];
  for (final (k, b) in branches.indexed) {
    for (final o in [1, 2]) {
      nodes.add(M5FaNode(id: nodes.length, s: b.s, order: o, pole: '${poleAt(b.s)}/$o', branch: k));
    }
  }
  // The fault: after the sectionalizer; else a main-line gap, or (about a
  // third of the time when there is one) a branch between its two FPIs.
  int after;
  int next;
  if (sectAt >= 0) {
    after = sectAt;
    next = sectAt + 1;
  } else if (branches.isNotEmpty && rng.nextDouble() < 0.35) {
    final k = rng.nextInt(branches.length);
    final bn = [for (final n in nodes) if (n.branch == k) n];
    after = bn[0].id;
    next = bn[1].id;
  } else {
    after = rng.nextInt(mainS.length - 1);
    next = after + 1;
  }
  final start = long ? M5FaStart.depot : M5FaStart.values[rng.nextInt(3)];
  final startS = switch (start) {
    M5FaStart.depot => long ? 24.0 : -36.0,
    M5FaStart.loadEnd => length + 36,
    M5FaStart.mid => _midStop(mainS, branches, length),
  };
  return M5FaCall(
    kind: kind,
    template: template,
    length: length,
    mirrored: rng.nextBool(),
    nodes: nodes,
    branches: branches,
    faultAfter: after,
    faultNext: next,
    start: start,
    startS: startS,
    feeder: 1 + rng.nextInt(12),
    docket: 100 + rng.nextInt(800),
  );
}

/// A mid-route spot that is beside no pole with a device: the middle of the
/// widest gap between stops near the middle of the line.
double _midStop(List<double> mainS, List<M5FaBranch> branches, double length) {
  final stops = [...mainS, for (final b in branches) b.s]..sort();
  var best = length / 2;
  var bestScore = double.infinity;
  for (var i = 0; i < stops.length - 1; i++) {
    final gap = stops[i + 1] - stops[i];
    final c = (stops[i] + stops[i + 1]) / 2;
    if (gap < 2 * M5FaGeo.besideRange + 30) continue;
    final score = (c - length / 2).abs();
    if (score < bestScore) {
      bestScore = score;
      best = c;
    }
  }
  return best;
}

M5FaDeal m5FaDeal(math.Random rng) {
  // Easy → hard: a plain trip first, then the long feeder and the in-service
  // call in either order.
  final rest = [M5FaKind.long, M5FaKind.sectionalizer]..shuffle(rng);
  final kinds = [M5FaKind.trip, ...rest];
  final calls = [for (final k in kinds) m5FaCall(k, rng)];
  return M5FaDeal(
    calls: calls,
    coworkerCall: rng.nextInt(3),
    historyCall: rng.nextBool() ? rng.nextInt(3) : null,
  );
}

// ---- the play state (pure logic) ------------------------------------------

/// What a reading did.
@immutable
class M5FaRead {
  const M5FaRead({required this.lit, this.mistake, this.reason, this.again = false, this.needless = false, this.blocked = false});
  final bool lit;
  final DoMistake? mistake;
  final M5FaReason? reason;

  /// Read before (nothing new).
  final bool again;

  /// The readings in hand already told it (a needless stop).
  final bool needless;

  /// Not read: the docket is not in yet ([mistake] = the slip, once a call).
  final bool blocked;
}

/// What a flag drop did.
@immutable
class M5FaFlag {
  const M5FaFlag({required this.placed, this.judged = false, this.mistake});
  final bool placed;

  /// Both flags are down and were judged ([mistake] null = right).
  final bool judged;
  final DoMistake? mistake;
  bool get right => judged && mistake == null;
}

class M5FaRun {
  M5FaRun(this.deal) {
    _reset();
  }
  final M5FaDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  final List<String> caught = [];

  // Once a play.
  var askedSource = false;
  var askedTee = false;

  // This call.
  /// The control room informed, the docket in (always on the in-service call).
  var docket = false;
  var _docketSlipped = false;

  /// The last drive was turned back (no docket): the van stays.
  var blocked = false;

  /// A needless stop this call (costs the clean-call +5).
  var needless = false;
  final Map<int, bool> reads = {};
  final Set<int> mine = {};
  int myReads = 0;
  final Set<int> teeSlipped = {};
  var alone = false;
  var van2Sent = false;
  double vanS = 0;
  double? van2S;
  final List<int> flags = [];
  var bracketed = false;
  var historyDone = false;
  var _wrongBracket = false;
  List<M5FaNode> _team = const [];
  int _teamAt = 0;
  var _teamDone = false;

  M5FaCall get call => deal.calls[index.clamp(0, deal.calls.length - 1)];
  bool get done => index >= deal.calls.length;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => roundSlips == 0 && !needless;

  /// A tripped feeder whose docket is not in yet.
  bool get docketDue => !done && !call.inService && !docket;

  /// Both ends of the faulty section are read (by either team).
  bool get pairFound => reads.containsKey(call.faultAfter) && reads.containsKey(call.faultNext);
  bool get docketSlipped => _docketSlipped;
  bool get historyDue => deal.historyCall == index && bracketed && !historyDone;
  bool get callDone => bracketed && (deal.historyCall != index || historyDone);
  bool get _open => !done && !bracketed;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  void _reset() {
    docket = false;
    _docketSlipped = false;
    blocked = false;
    needless = false;
    reads.clear();
    mine.clear();
    myReads = 0;
    teeSlipped.clear();
    alone = false;
    van2Sent = false;
    flags.clear();
    bracketed = false;
    historyDone = false;
    _wrongBracket = false;
    _team = const [];
    _teamAt = 0;
    _teamDone = false;
    if (done) return;
    docket = call.inService;
    vanS = call.startS;
    van2S = call.kind == M5FaKind.long ? -40 : null;
  }

  /// The radio call: the control room is informed, the docket is in.
  bool takeDocket() {
    if (!docketDue) return false;
    docket = true;
    if (!_docketSlipped) _tag(M5FaLines.caughtDocket);
    return true;
  }

  /// Patrolling before the docket: a slip, once a call (null after).
  DoMistake? patrolWithoutDocket() {
    if (!docketDue || _docketSlipped) return null;
    _docketSlipped = true;
    return _slip(M5FaMistakes.noDocket);
  }

  /// What device [n] shows is already told by the readings in hand: fault
  /// current lights every device from the source up to the fault, so a dark
  /// one means all past it are dark and a lit one means all before it are lit.
  bool known(M5FaNode n) {
    if (reads.containsKey(n.id) || pairFound) return true;
    final c = call;
    if (n.main) {
      for (final m in c.mains) {
        final r = reads[m.id];
        if ((r == false && m.s < n.s) || (r == true && m.s > n.s)) return true;
      }
      return false;
    }
    final j = c.branches[n.branch!].s;
    for (final m in c.mains) {
      final r = reads[m.id];
      // Dark before the T-off, or lit past it: the fault is not on the branch.
      if ((r == false && m.s < j) || (r == true && m.s > j)) return true;
    }
    final bn = c.branchNodes(n.branch!);
    if (n.order == 2 && reads[bn[0].id] == false) return true;
    if (n.order == 1 && reads[bn[1].id] == true) return true;
    return false;
  }

  bool beside(M5FaNode n) => (vanS - n.s).abs() <= M5FaGeo.besideRange;

  /// The branch device by the junction (order 1) of branch [k].
  M5FaNode _b1(int k) => call.nodes.firstWhere((n) => n.branch == k && n.order == 1);

  /// Van 1 reads device [id] (it stands beside it).
  M5FaRead read(int id) {
    final n = call.nodes[id];
    final lit = call.lit(n);
    if (!_open || mine.contains(id)) return M5FaRead(lit: lit, again: true);
    if (docketDue) return M5FaRead(lit: lit, blocked: true, mistake: patrolWithoutDocket());
    final first = myReads == 0;
    final wasKnown = known(n);
    myReads++;
    mine.add(id);
    DoMistake? m;
    if (call.kind == M5FaKind.long && !van2Sent && !alone) {
      alone = true;
      m = _slip(M5FaMistakes.alone);
    } else if (first && id != call.sourceFirst.id) {
      m = _slip(M5FaMistakes.farStart);
    } else if (wasKnown) {
      // A needless stop (no T-off is booked past a bracket already in hand).
      needless = true;
      reads[id] = lit;
      return M5FaRead(lit: lit, needless: true);
    } else if (n.main) {
      final passed = [
        for (final (k, b) in call.branches.indexed)
          if (b.s < n.s && !reads.containsKey(_b1(k).id) && !teeSlipped.contains(k)) k,
      ];
      if (passed.isNotEmpty) {
        teeSlipped.addAll(passed);
        m = _slip(M5FaMistakes.skipTee);
      }
    }
    reads[id] = lit;
    M5FaReason? reason;
    if (m == null) {
      if (first && id == call.sourceFirst.id && !askedSource) {
        askedSource = true;
        reason = M5FaReason.source;
        _tag(M5FaLines.caughtSource);
      } else if (!n.main && n.order == 1 && !askedTee && !teeSlipped.contains(n.branch)) {
        final b = call.branches[n.branch!];
        final ahead = mine.any((i) => call.nodes[i].main && call.nodes[i].s > b.s);
        if (!ahead) {
          askedTee = true;
          reason = M5FaReason.tee;
          _tag(M5FaLines.caughtTee);
        }
      }
    }
    return M5FaRead(lit: lit, mistake: m, reason: reason);
  }

  /// Van 1 ended a drive at [s]. Before the docket a drive off is turned back
  /// ([blocked]; a slip once a call). On the long call, driving off before
  /// van 2 has gone to the far end is a slip.
  DoMistake? driveEnd(double s) {
    blocked = false;
    vanS = s;
    if (!_open) return null;
    if (docketDue && (s - call.startS).abs() > 30) {
      blocked = true;
      vanS = call.startS;
      return patrolWithoutDocket();
    }
    if (call.kind == M5FaKind.long && !van2Sent && !alone && (s - call.startS).abs() > 30) {
      alone = true;
      return _slip(M5FaMistakes.alone);
    }
    return null;
  }

  /// Van 2 goes to the far end; its team reads from there inward. Returns the
  /// reason to ask (none after driving off alone).
  M5FaReason? sendVan2() {
    if (!_open || call.kind != M5FaKind.long || van2Sent || docketDue) return null;
    van2Sent = true;
    van2S = call.length + 36;
    // The team's walk from the load end: main FPIs down, and at every T-off
    // they pass its branch FPI (the second one only after a lit first).
    final mains = call.mains;
    final order = <M5FaNode>[];
    for (var i = mains.length - 1; i >= 0; i--) {
      order.add(mains[i]);
      if (i == 0) break;
      for (final (k, b) in call.branches.indexed) {
        if (b.s < mains[i].s && b.s > mains[i - 1].s) order.addAll(call.branchNodes(k));
      }
    }
    _team = order;
    if (alone) return null;
    _tag(M5FaLines.caughtSplit);
    return M5FaReason.long;
  }

  /// The second team's next reading (one per reading of van 1), or null.
  M5FaNode? teamReport() {
    if (!van2Sent || _teamDone || !_open) return null;
    while (_teamAt < _team.length) {
      final n = _team[_teamAt++];
      if (reads.containsKey(n.id)) continue;
      if (!n.main && n.order == 2 && reads[_b1(n.branch!).id] != true) continue;
      final lit = call.lit(n);
      reads[n.id] = lit;
      if ((n.main && lit) || (reads.containsKey(call.faultAfter) && reads.containsKey(call.faultNext))) _teamDone = true;
      return n;
    }
    _teamDone = true;
    return null;
  }

  /// A flag dropped on device [id] (only read devices take one). With both
  /// flags down the bracket is judged; a wrong pair stays until [returnFlags].
  M5FaFlag placeFlag(int id) {
    if (!_open || !reads.containsKey(id) || flags.contains(id) || flags.length >= 2) return const M5FaFlag(placed: false);
    flags.add(id);
    if (flags.length < 2) return const M5FaFlag(placed: true);
    if (flags.toSet().containsAll(call.faultPair)) {
      bracketed = true;
      if (!_wrongBracket) _tag(M5FaLines.caughtBracket);
      return const M5FaFlag(placed: true, judged: true);
    }
    _wrongBracket = true;
    return M5FaFlag(placed: true, judged: true, mistake: _slip(call.inService ? M5FaMistakes.wrongSect : M5FaMistakes.wrongBracket));
  }

  void removeFlag(int id) {
    if (_open) flags.remove(id);
  }

  void returnFlags() {
    if (_open) flags.clear();
  }

  /// The history note's answer. Right → the root-cause reason.
  DoMistake? pickHistory(bool right) {
    if (!historyDue) return null;
    if (!right) return _slip(M5FaMistakes.repairOnly);
    historyDone = true;
    _tag(M5FaLines.caughtRoot);
    return null;
  }

  void next() {
    index++;
    roundSlips = 0;
    _reset();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a call: ~4 drives + ~4 readings (tap + close-up 1.6 s) + 2 flags ≈ 24000
///     + the bracket's reason ~8200                         × 3 ≈ 97000
///   source, T-off, long-line (+ root) reasons ≈ 3.5 × 8200     ≈ 28700
///   the coworker once ≈ 9600; the history deck ≈ 3000          ≈ 138300
///   the radio call for the docket (2 tripped calls) ≈ 2 × 1500 ≈ 141300
/// 85 % ≈ 120100 → 120 s.
const m5FaQuickMs = 120000;

@immutable
class M5FaPack {
  const M5FaPack({required this.id, required this.titleBn, this.quickMs = m5FaQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5FaPack> m5FaultAddressPacks = {
  'do_5_2_a': M5FaPack(id: 'do_5_2_a', titleBn: M5FaLines.title),
};

/// Test hook (tests only): the live run, the camera and the scene geometry.
class M5FaultAddressProbe {
  _FaRunPageState? _s;
  M5FaRun? get run => _s?._run;
  double get camera => _s?._cam ?? 0;
  M5FaGeo? get geo => _s?._geoNow;
  bool get closeUp => _s?._closeUp != null;
}

// ============================================================================
// Page
// ============================================================================

class M5FaultAddressPage extends StatefulWidget {
  const M5FaultAddressPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M5FaPack pack;
  final bool muted;
  final int? seed;
  final M5FaultAddressProbe? probe;

  @override
  State<M5FaultAddressPage> createState() => _M5FaultAddressPageState();
}

class _M5FaultAddressPageState extends State<M5FaultAddressPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FaRunPage(
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

class _FaRunPage extends ConsumerStatefulWidget {
  const _FaRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final M5FaPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M5FaultAddressProbe? probe;

  @override
  ConsumerState<_FaRunPage> createState() => _FaRunPageState();
}

/// The close-up on screen.
@immutable
class _CloseUp {
  const _CloseUp(this.node, this.lit, this.tok);
  final M5FaNode node;
  final bool lit;
  final int tok;
}

class _FaRunPageState extends ConsumerState<_FaRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5FaRun _run;
  late final int _seed = widget.rng.nextInt(1 << 20);
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

  /// The camera (world px at the scene's left edge), and the call it was
  /// centred for.
  double _cam = 0;
  int _camFor = -1;

  /// The van being dragged (0 none, 1, 2) and where it started.
  int _dragVan = 0;
  double _dragFrom = 0;

  /// Van 2 driving off to the far end.
  late final AnimationController _drive = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  double? _van2From;

  _CloseUp? _closeUp;
  int _closeTok = 0;
  Timer? _closeTimer;
  VoidCallback? _afterClose;

  var _mapOpen = false;
  String? _radio;

  /// A bracket flag on the way from the tray (global position).
  Offset? _flagDrag;

  /// The history note's deck.
  var _histUp = false;
  List<ChoiceOption> _histOpts = const [];
  final Set<String> _histWrong = {};
  String? _histPicked;

  M5FaReason? _reasonFor;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final _trayKey = GlobalKey();
  final _radioKey = GlobalKey();
  M5FaGeo? _geoNow;
  int _hintFlip = 0;

  @override
  void initState() {
    super.initState();
    _run = M5FaRun(m5FaDeal(widget.rng));
    widget.probe?._s = this;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    if (widget.probe?._s == this) widget.probe?._s = null;
    disposeCoworker();
    _closeTimer?.cancel();
    _drive.dispose();
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
      !_intro &&
      !_ended &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      _closeUp == null &&
      !_mapOpen &&
      !_histUp &&
      !_run.bracketed &&
      !_drive.isAnimating;

  String get _task {
    if (_run.historyDue) return M5FaLines.askHistory;
    final c = _run.call;
    // Only once the card has taught it (no giveaway before).
    if (_run.docketDue && _run.docketSlipped) return M5FaLines.askDocket;
    if (_run.myReads == 0) {
      if (c.kind == M5FaKind.long && !_run.van2Sent) return M5FaLines.askLong;
      if (c.kind == M5FaKind.sectionalizer) return M5FaLines.askSect;
      return M5FaLines.askStart;
    }
    return M5FaLines.askRead;
  }

  Future<void> _start() async {
    _clock.start();
    _startCall(first: true);
  }

  void _startCall({bool first = false}) {
    setState(() => _radio = null);
    unawaited(_sayChain([if (!first) M5FaLines.callLine(_run.call.kind, first: false), _task]));
  }

  // --- hands on -----------------------------------------------------------------
  Offset _world(Offset local) => local + Offset(_cam, 0);

  void _panStart(DragStartDetails d) {
    final geo = _geoNow;
    if (geo == null || !_canPlay) return;
    final p = _world(d.localPosition);
    var which = 0;
    if (geo.vanHit(_run.vanS).contains(p)) {
      which = 1;
    } else if (_run.van2S != null && !_run.van2Sent && geo.vanHit(_run.van2S!).contains(p)) {
      which = 2;
    }
    if (which == 0) return;
    // Driving pauses while the coworker is due.
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.4);
    _dragVan = which;
    _dragFrom = which == 1 ? _run.vanS : _run.van2S!;
  }

  void _panUpdate(DragUpdateDetails d) {
    final geo = _geoNow;
    if (geo == null || _dragVan == 0) return;
    if (!_canPlay) {
      _dragVan = 0;
      return;
    }
    final ds = d.delta.dx * M5FaGeo.dragGain * geo.dir;
    setState(() {
      if (_dragVan == 1) {
        _run.vanS = (_run.vanS + ds).clamp(geo.minS, geo.maxS);
        _cam = geo.follow(_run.vanS, _cam);
      } else {
        _run.van2S = (_run.van2S! + ds).clamp(geo.minS, geo.maxS);
        _cam = geo.follow(_run.van2S!, _cam);
      }
    });
  }

  void _panEnd() {
    final geo = _geoNow;
    final which = _dragVan;
    _dragVan = 0;
    if (geo == null || which == 0) return;
    if (which == 2) {
      _endVan2(geo);
      return;
    }
    // Snap beside the nearest pole with a device you can see, if close.
    final snapped = _nearestStop(_run.vanS);
    final m = _run.driveEnd(snapped);
    setState(() => _cam = geo.follow(_run.vanS, _cam));
    if (m != null) {
      unawaited(_mistake(m, _vanGlobal(geo)));
    } else if (_run.blocked) {
      _tick('sounds/intro/tick.ogg', 0.3);
      unawaited(_sayChain([M5FaLines.askDocket]));
    }
  }

  /// A device under the mango grove (its T-off shows only on the map card).
  bool _hidden(M5FaNode n) => !n.main && _run.call.branches[n.branch!].grove;

  double _nearestStop(double s) {
    var best = s;
    var d = M5FaGeo.snapRange;
    for (final n in _run.call.nodes) {
      // Never snap to a junction under the grove: a snap there would point
      // at a line nobody can see.
      if (_hidden(n)) continue;
      final x = (n.s - s).abs();
      if (x < d) {
        d = x;
        best = n.s;
      }
    }
    return best;
  }

  void _endVan2(M5FaGeo geo) {
    final moved = _run.van2S! - _dragFrom;
    if (moved < 50) {
      // Back to where it was parked.
      setState(() {
        _run.van2S = _dragFrom;
        _cam = geo.follow(_run.vanS, _cam);
      });
      return;
    }
    if (_run.docketDue) {
      // The second team may not set off before the control room knows.
      setState(() {
        _run.van2S = _dragFrom;
        _cam = geo.follow(_run.vanS, _cam);
      });
      final m = _run.patrolWithoutDocket();
      if (m != null) {
        unawaited(_mistake(m, _globalOf(geo.vanAt(_dragFrom)) ?? Offset.zero));
      } else {
        _tick('sounds/intro/tick.ogg', 0.3);
        unawaited(_sayChain([M5FaLines.askDocket]));
      }
      return;
    }
    final from = _run.van2S!;
    final reason = _run.sendVan2();
    _cue('sounds/learn/rush_in.ogg', volume: 0.4);
    setState(() {
      _van2From = from;
      _radio = M5FaLines.teamGone;
      _cam = geo.follow(_run.vanS, _cam);
    });
    if (!_quiet) {
      unawaited(_drive.forward(from: 0).then((_) {
        if (mounted) setState(() {});
      }));
    }
    if (reason != null) {
      _table(reason, 10, _vanGlobal(geo));
    } else {
      unawaited(_sayChain([M5FaLines.teamGone, _task]));
    }
  }

  Offset _vanGlobal(M5FaGeo geo) => _globalOf(geo.vanAt(_run.vanS)) ?? Offset.zero;

  /// A world point on screen (null before layout).
  Offset? _globalOf(Offset world) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(world - Offset(_cam, 0));
  }

  Rect? _globalRect(Rect world) {
    final a = _globalOf(world.topLeft);
    final b = _globalOf(world.bottomRight);
    return a == null || b == null ? null : Rect.fromPoints(a, b);
  }

  void _tapScene(Offset local, Offset global) {
    final geo = _geoNow;
    if (geo == null || !_canPlay) return;
    final p = _world(local);
    final call = _run.call;
    for (final n in call.nodes) {
      if (!geo.nodeHit(n).contains(p)) continue;
      if (_run.flags.contains(n.id)) {
        // A flag back to the tray.
        _tick('sounds/intro/click.ogg', 0.4);
        setState(() => _run.removeFlag(n.id));
        return;
      }
      _tapNode(n, global);
      return;
    }
    _hints.missTap();
  }

  void _tapNode(M5FaNode n, Offset global) {
    if (!_run.beside(n)) {
      _hints.missTap();
      // A tap on the grove is a tap on trees, like any other grove's.
      if (!_hidden(n)) unawaited(_sayChain([M5FaLines.tooFar]));
      return;
    }
    if (!_run.mine.contains(n.id) && holdForCoworker()) return;
    _tick();
    final r = _run.read(n.id);
    if (r.blocked) {
      if (r.mistake != null) {
        unawaited(_mistake(r.mistake!, global));
      } else {
        unawaited(_sayChain([M5FaLines.askDocket]));
      }
      return;
    }
    _hush();
    setState(() => _closeUp = _CloseUp(n, r.lit, ++_closeTok));
    if (r.lit) _cue('sounds/learn/tag_slap.ogg', volume: 0.35);
    _afterClose = r.again ? null : () => _afterRead(r, global);
    _closeTimer?.cancel();
    _closeTimer = Timer(Duration(milliseconds: _quiet ? 900 : 1700), _shutCloseUp);
  }

  void _shutCloseUp() {
    _closeTimer?.cancel();
    if (_closeUp == null || !mounted) return;
    setState(() => _closeUp = null);
    final after = _afterClose;
    _afterClose = null;
    after?.call();
  }

  void _afterRead(M5FaRead r, Offset global) {
    if (_ended) return;
    final c = _run.call;
    // The second team radios its next reading.
    final team = _run.teamReport();
    final teamLine = team == null ? null : M5FaLines.team(team, c.lit(team));
    if (teamLine != null) setState(() => _radio = teamLine);
    // The coworker on the 2nd reading of his call.
    if (_run.index == _run.deal.coworkerCall && _run.myReads >= 2 && !coworkerDone) scheduleCoworker();
    final m = r.mistake;
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    if (r.needless) {
      // A needless stop: no points lost, but the clean-call +5 is gone.
      unawaited(_sayChain([?teamLine, _run.pairFound ? M5FaLines.needlessDone : M5FaLines.needlessKnown], mood: GuideMood.think));
      return;
    }
    if (r.reason != null) {
      _table(r.reason!, 10, global);
      return;
    }
    unawaited(_sayChain([?teamLine, _task]));
  }

  // --- the radio: the control room --------------------------------------------
  void _tapRadio() {
    if (!_canPlay) return;
    if (!_run.takeDocket()) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.45);
    final c = _run.call;
    setState(() => _radio = M5FaLines.control(c));
    unawaited(_sayChain([M5FaLines.control(c), _task]));
  }

  // --- the bracket flags ------------------------------------------------------
  void _flagStart(DragStartDetails d) {
    if (!_canPlay || _run.flags.length >= 2) return;
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.4);
    setState(() => _flagDrag = d.globalPosition);
  }

  void _flagMove(DragUpdateDetails d) {
    if (_flagDrag == null) return;
    setState(() => _flagDrag = d.globalPosition);
  }

  void _flagEnd() {
    final g = _flagDrag;
    final geo = _geoNow;
    setState(() => _flagDrag = null);
    if (g == null || geo == null || !_canPlay) return;
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final p = _world(box.globalToLocal(g));
    for (final n in _run.call.nodes) {
      if (!geo.nodeHit(n).inflate(10).contains(p)) continue;
      final f = _run.placeFlag(n.id);
      if (!f.placed) break;
      _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
      setState(() {});
      if (f.judged) unawaited(_judged(f, g));
      return;
    }
    // Dropped on nothing that takes a flag: back to the tray.
    _tick('sounds/intro/tick.ogg', 0.3);
  }

  Future<void> _judged(M5FaFlag f, Offset origin) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _ended) return;
    if (f.right) {
      _table(M5FaReason.bracket, 15 + (_run.thorough ? 5 : 0), origin);
      return;
    }
    setState(_run.returnFlags);
    unawaited(_mistake(f.mistake!, origin));
  }

  // --- the history note -------------------------------------------------------
  void _openHistory() {
    setState(() {
      _histUp = true;
      _histOpts = dealChoices(M5FaLines.historyRight, M5FaLines.historyWrong, widget.rng);
      _histWrong.clear();
      _histPicked = null;
    });
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayChain([M5FaLines.historyNote, M5FaLines.askHistory], mood: GuideMood.think));
  }

  Future<void> _pickHistory(ChoiceOption o, Offset origin) async {
    if (!_histUp || _card != null || _histPicked != null || _histWrong.contains(o.textBn)) return;
    _hush();
    if (!o.correct) {
      setState(() => _histWrong.add(o.textBn));
      final m = _run.pickHistory(false);
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    setState(() => _histPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    _run.pickHistory(true);
    setState(() {
      _histUp = false;
      _histOpts = const [];
    });
    _table(M5FaReason.root, 10, origin);
  }

  // --- the table and the reasons ---------------------------------------------
  void _table(M5FaReason r, int amount, Offset origin) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    _reasonFor = r;
    putOnTable(amount);
    final idx = _run.index;
    final kind = _run.call.kind;
    unawaited(askReason(
      deal: () => dealChoices(M5FaLines.whyRight(r, kind), M5FaLines.myths, widget.rng),
      question: M5FaLines.whyQuestion(r),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

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
    final r = _reasonFor;
    _reasonFor = null;
    final idx = _run.index;
    if (r == M5FaReason.bracket || r == M5FaReason.root) {
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
        if (!mounted || _ended || _run.index != idx) return;
        if (_run.historyDue) {
          _openHistory();
        } else {
          _nextCall();
        }
      }));
      return;
    }
    unawaited(_sayChain([_task]));
  }

  void _nextCall() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startCall();
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5FaLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerCall || _run.bracketed) return null;
    if (_intro || _card != null || tableBusy || _closeUp != null || _mapOpen || _dragVan != 0 || _flagDrag != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: a slip (a myth, nobody in danger on the spot).
      await _mistake(M5FaMistakes.listened, origin, booked: false);
      return;
    }
    _run.caught.add(M5FaLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5FaLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5FaLines.tapWhy[_nudgeN++ % M5FaLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  /// A slip: −10, its card (the 3rd strikes the level out). [booked]: the run
  /// already counted it (a field move); the coworker's is counted here.
  Future<void> _mistake(DoMistake m, Offset origin, {bool booked = true}) async {
    if (_ended) return;
    if (!booked) {
      _run.slips++;
      _run.roundSlips++;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() => _card = m);
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('faultaddr/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
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

  void _cardGo() {
    _hush();
    setState(() => _card = null);
    if (_histUp) {
      unawaited(_sayChain([M5FaLines.askHistory], mood: GuideMood.think));
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
    await _say(!_run.passed ? M5FaLines.fail : (_quickBonus ? M5FaLines.quick : M5FaLines.allSet),
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

  // --- the gesture hand ---------------------------------------------------------
  /// How to touch, never what: the van nudged a short way back or forth (never
  /// toward an end on purpose — the side alternates), a tap pulse on the
  /// device the van stands beside (a sweep when it stands beside several;
  /// never one hidden under the grove), van 2 wiggled, a flag lifted and
  /// dropped back. The map is never hinted.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null || _run.done) return null;
    final c = _run.call;
    _hintFlip++;
    final side = _hintFlip.isEven ? const Offset(1, 0) : const Offset(-1, 0);
    Offset scene(Offset world) => world - Offset(_cam, 0);
    if (_run.docketDue) {
      // After the no-docket card: the radio (the card has said it). Before:
      // a sweep over the radio and the van(s) — what can be touched, never
      // which comes first.
      if (_run.docketSlipped) return HintSpec.tapOn(_radioKey);
      final rects = [
        ?HintSpec.globalRectOf(_radioKey),
        ?_globalRect(geo.vanHit(_run.vanS)),
        if (c.kind == M5FaKind.long && _run.van2S != null) ?_globalRect(geo.vanHit(_run.van2S!)),
      ];
      if (rects.length >= 2) return HintSpec.sweep(rects);
    }
    if (c.kind == M5FaKind.long && !_run.van2Sent && _run.van2S != null && _hintFlip % 4 >= 2) {
      return HintSpec.drag(scene(geo.vanAt(_run.van2S!)), toward: side, travel: 30, space: HintSpace.scene);
    }
    // Devices under the grove are never pointed at (that T-off shows only on
    // the map card).
    final beside = [
      for (final n in c.nodes)
        if (!_run.reads.containsKey(n.id) && _run.beside(n) && (n.main || !c.branches[n.branch!].grove)) n,
    ];
    if (beside.length == 1) return HintSpec.tap(scene(geo.nodeAt(beside.single)), space: HintSpace.scene);
    if (beside.length > 1) {
      return HintSpec.sweep([for (final n in beside) geo.nodeHit(n).shift(Offset(-_cam, 0))], space: HintSpace.scene);
    }
    if (_run.reads.length >= 2 && _run.flags.length < 2 && _hintFlip % 4 >= 2) {
      final tray = HintSpec.globalRectOf(_trayKey);
      if (tray != null) return HintSpec.drag(tray.center, toward: const Offset(0, -1), travel: 48);
    }
    return HintSpec.drag(scene(geo.vanAt(_run.vanS)), toward: side, travel: 36, space: HintSpace.scene);
  }

  // --- the scene ---------------------------------------------------------------
  List<Widget> _scene(SceneMetrics m) {
    final call = _run.call;
    final geo = _geoNow = M5FaGeo.forScene(m.height, m.inset, call);
    if (_camFor != _run.index) {
      // A new call: the camera on the van.
      _camFor = _run.index;
      _cam = geo.centre(_run.vanS);
    }
    final cam = _cam = _cam.clamp(0.0, geo.maxCamera);
    return [
      Positioned.fill(
        key: ValueKey('world-${_run.index}'),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: M5FaWorldPainter(
              geo: geo,
              cam: cam,
              vanS: _run.vanS,
              van2S: _run.van2S,
              reads: Map.of(_run.reads),
              flags: List.of(_run.flags),
              seed: _seed,
              drive: _drive,
              van2From: _van2From,
              van2To: _run.van2Sent ? _run.van2S : null,
              // Parked beside the grove's junction: its boxes show faintly
              // through the canopy (for the player who read the map).
              peek: {
                for (final (k, b) in call.branches.indexed)
                  if (b.grove && _dragVan != 1 && (_run.vanS - b.s).abs() <= M5FaGeo.besideRange) k,
              },
            ),
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5FaLines.sceneLabel,
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, d.globalPosition),
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      // The next call: a short fade.
      if (!_intro)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: _quiet || _run.index == 0 ? 0 : 0.6, end: 0),
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
    final playing = !_intro && _mark == null && !struckOut && !_run.done;
    final deckUp = reasonOpen || coworkerChoiceUp || (_histUp && playing);
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.bracketed;
    final call = _run.call;
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
              labels: [for (final c in _run.deal.calls) M5FaLines.kinds[c.kind]!],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _closeUp == null && !_mapOpen && _dragVan == 0 && _flagDrag == null && !_drive.isAnimating,
            hintKey: '${_run.index}/${_run.reads.length}/${_run.flags.length}/${_run.van2Sent}/${_run.docket}/${_run.docketSlipped}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 156), quiet: quiet),
              if (playing && !_run.done)
                Positioned(
                  key: ValueKey('docket-${_run.index}-${_run.docket}'),
                  left: 10,
                  top: pad.top + 100,
                  child: IgnorePointer(child: _Chip(text: _run.docket ? M5FaLines.docket(call) : M5FaLines.feederOnly(call), icon: Icons.assignment_rounded)),
                ),
              if (handsOn)
                Positioned(
                  key: ValueKey('dash-${_run.index}'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 8,
                  child: _Dashboard(
                    radio: _radio,
                    radioKey: _radioKey,
                    onRadio: _tapRadio,
                    flagsLeft: 2 - _run.flags.length,
                    trayKey: _trayKey,
                    onMap: () {
                      if (!_canPlay) return;
                      _tick('sounds/intro/click.ogg', 0.4);
                      setState(() => _mapOpen = true);
                    },
                    onFlagStart: _flagStart,
                    onFlagMove: _flagMove,
                    onFlagEnd: _flagEnd,
                  ),
                ),
              if (_histUp && playing && _card == null)
                Positioned(
                  key: const ValueKey('history-note'),
                  left: 0,
                  right: 0,
                  top: pad.top + 132,
                  child: const IgnorePointer(child: Center(child: _Note(text: M5FaLines.historyNote))),
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
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('history-deck-${_run.index}'),
                                options: _histOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _histWrong,
                                picked: _histPicked,
                                onPick: (o, at) => unawaited(_pickHistory(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 80), onLeft: !coworkerOnScreen || coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_closeUp != null)
                Positioned.fill(
                  key: ValueKey('closeup-${_closeUp!.tok}'),
                  child: _CloseUpView(up: _closeUp!, quiet: quiet, onTap: _shutCloseUp),
                ),
              if (_mapOpen)
                Positioned.fill(
                  key: const ValueKey('map'),
                  child: _MapView(
                    call: call,
                    reads: Map.of(_run.reads),
                    vanS: _run.vanS,
                    van2S: _run.van2S,
                    onClose: () => setState(() => _mapOpen = false),
                  ),
                ),
              if (_flagDrag != null)
                Positioned(
                  key: const ValueKey('flag-drag'),
                  left: _flagDrag!.dx - 6,
                  top: _flagDrag!.dy - 46,
                  child: const IgnorePointer(child: _FlagIcon(size: 40)),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
                  line: M5FaLines.intro,
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

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE6F4EDD8),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFB08A3E), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF6B4E1C)),
          const SizedBox(width: 5),
          Text(text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4B8),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Text(text, style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF3A2A10))),
      ),
    );
  }
}

class _FlagIcon extends StatelessWidget {
  const _FlagIcon({this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size * 1.2, child: CustomPaint(painter: _FlagPainter()));
}

class _FlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w * 0.25, h * 0.05), Offset(w * 0.25, h), Paint()
      ..color = const Color(0xFF3A2E22)
      ..strokeWidth = math.max(2, w * 0.07)
      ..strokeCap = StrokeCap.round);
    final cloth = Path()
      ..moveTo(w * 0.27, h * 0.07)
      ..lineTo(w * 0.95, h * 0.24)
      ..lineTo(w * 0.27, h * 0.42)
      ..close();
    canvas.drawPath(cloth, Paint()..color = const Color(0xFFE53935));
  }

  @override
  bool shouldRepaint(_FlagPainter old) => false;
}

/// The dashboard: the folded map card, the radio, the tray with the flags.
class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.radio,
    required this.radioKey,
    required this.onRadio,
    required this.flagsLeft,
    required this.trayKey,
    required this.onMap,
    required this.onFlagStart,
    required this.onFlagMove,
    required this.onFlagEnd,
  });
  final String? radio;
  final GlobalKey radioKey;

  /// A tap on the radio: a call to the control room.
  final VoidCallback onRadio;
  final int flagsLeft;
  final GlobalKey trayKey;
  final VoidCallback onMap;
  final GestureDragStartCallback onFlagStart;
  final GestureDragUpdateCallback onFlagMove;
  final VoidCallback onFlagEnd;

  @override
  Widget build(BuildContext context) {
    final box = BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xEE24303F), Color(0xEE111A26)]),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF5B6B80), width: 1.2),
    );
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: M5FaLines.map,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onMap,
              child: Container(
                width: 66,
                decoration: box,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_rounded, size: 24, color: Color(0xFFF2E3B5)),
                    Text(M5FaLines.map, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              label: radio ?? M5FaLines.radio,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRadio,
                child: Container(
                  key: radioKey,
                  height: 62,
                  decoration: box,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.settings_input_antenna_rounded, size: 20, color: Color(0xFF9FB7D0)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          radio ?? M5FaLines.radio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: bangla(fontSize: 11, fontWeight: FontWeight.w700, height: 1.2, color: radio == null ? const Color(0xFF7F8EA3) : SlmColors.ivory),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            label: M5FaLines.flags,
            child: Container(
              key: trayKey,
              width: 92,
              decoration: box,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: flagsLeft > 0 ? onFlagStart : null,
                onPanUpdate: flagsLeft > 0 ? onFlagMove : null,
                onPanEnd: flagsLeft > 0 ? (_) => onFlagEnd() : null,
                onPanCancel: flagsLeft > 0 ? onFlagEnd : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 2; i++)
                      Opacity(opacity: i < flagsLeft ? 1 : 0.22, child: const _FlagIcon(size: 28)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The device close-up: a big FPI box (its LED) or the sectionalizer, with
/// its pole number. A tap closes it early.
class _CloseUpView extends StatelessWidget {
  const _CloseUpView({required this.up, required this.quiet, required this.onTap});
  final _CloseUp up;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = up.node;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: const Color(0x99050A16),
        child: Center(
          child: Container(
            width: 230,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2433),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF7D8DA3), width: 1.6),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(M5FaLines.pole(n.pole), style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                const SizedBox(height: 8),
                SizedBox(
                  width: 180,
                  height: 160,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: quiet ? 1 : 0, end: 1),
                    duration: const Duration(milliseconds: 1300),
                    builder: (_, v, _) => CustomPaint(painter: M5FaCloseUpPainter(lit: up.lit, sectionalizer: n.sectionalizer, v: v)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(M5FaLines.closeTap, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF9FAEC2))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The folded map card (tap to put it away).
class _MapView extends StatelessWidget {
  const _MapView({required this.call, required this.reads, required this.vanS, required this.van2S, required this.onClose});
  final M5FaCall call;
  final Map<int, bool> reads;
  final double vanS;
  final double? van2S;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: ColoredBox(
        color: const Color(0x88050A16),
        child: Center(
          child: Container(
            width: 320,
            height: 220,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF7EFD8), Color(0xFFEADCB6), Color(0xFFF7EFD8)], stops: [0, 0.5, 1]),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: M5FaMapPainter(call: call, reads: reads, vanS: vanS, van2S: van2S))),
                Positioned(
                  left: 10,
                  top: 8,
                  child: Text(enDigits('ফিডার ${call.feeder}'), style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF2A3A55))),
                ),
                Positioned(
                  right: 10,
                  top: 8,
                  child: Row(
                    children: [
                      Container(width: 9, height: 9, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFC21F))),
                      Text(' ${M5FaLines.lit}   ', style: bangla(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF2A3A55))),
                      Container(width: 9, height: 9, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8E98A4))),
                      Text(' ${M5FaLines.dark}', style: bangla(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF2A3A55))),
                    ],
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
