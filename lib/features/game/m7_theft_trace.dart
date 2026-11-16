import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
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
import 'm7_theft_trace_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_theft_trace_world.dart'
    show
        M7TtCond,
        M7TtGeo,
        M7TtLane,
        M7TtMeter,
        M7TtMeterCase,
        M7TtSketch,
        M7TtSpot,
        M7TtWire,
        M7TtWireKind,
        kM7TtTheftSpots,
        m7TtMeterSpots,
        m7TtStationAt,
        m7TtWireSpots;

// Lesson 7.5 "বিদ্যুৎ চুরি: একটি অপরাধ এবং তার বিপদ", কাজ 1 "তারের পিছু পিছু"
// (pack do_7_5_a, rung 7.5/do/0, engineType m7_theft_trace).
//
// The lane's DTR keeps overloading though it has few consumers (lesson 7.5
// pro tip 1). Three rounds and a report:
//  1. Lane 1 (bare conductors or AB cable, dealt): 4–5 service wires drop
//     from the line to 3–4 houses, crossing, partly hidden by a branch and a
//     shop sign. The player puts a finger on a wire where it leaves the line
//     and drags along it; the chalk follows only while the finger stays on
//     that wire (sliding off onto a crossing wire stops it, no cost; the
//     chalk stays where it stopped). At the wire's end the notebook sketches
//     the path: drag the red pin onto the exact theft point (a hook on the
//     line, a joint before the meter, a loop round the meter — section 1/2
//     of the lesson), or 'ঠিক আছে' (a two-step preview) for a proper metered
//     wire. Right → ◆ (the first of each kind on the table → a reason);
//     a pin on a legal wire = slip (a false report); 'ঠিক আছে' on a theft =
//     slip; a pin on the right wire but the wrong point bounces, no strike.
//  2. Lane 2: the other conductor, a fresh tangle, 1–2 thefts.
//  3. A meter change (pro tip 2): trace the incoming cable through the
//     meter's terminals and out; a bypass jumper leads the finger past the
//     meter. Dealt: intact (~25 %), cut seal, magnet, bypass (section 2).
//     Pin or 'ঠিক আছে' as before.
//  4. The report (section 3): tick both সুপারভাইজার and ভিজিল্যান্স, then
//     রিপোর্ট পাঠান; with one missing = slip.
//
// No deadly in this level (ruling M7-6). Slips (R16, R29, R30): a false pin,
// 'ঠিক আছে' on a theft wire or meter, sending without both, listening to the
// coworker. Three slips strike out.
//
// The coworker (lesson 7.5 myth 2 word for word, M7-10; X2/B1: listening is a
// slip) comes once a play, dealt: after the first right pin's reason (the next
// trace start waits for him) or at রিপোর্ট পাঠান (the send waits for him).
//
// Gesture hands (how, never what): a lane round's start — a sweep over every
// wire root still to trace, alike; a finger lifted mid-trace — a short drag
// nudge from the chalk head along its wire; the close-up — a drag nudge down
// from the incoming cable (the only start); the notebook — a sweep over the
// pin and 'ঠিক আছে'; the report — a sweep over both recipients, a tap on
// রিপোর্ট পাঠান once both are ticked. None during the intro, the praise
// window, cards, the pin drag, the coworker and the result.

// ============================================================================
// Content
// ============================================================================

/// A theft a pin catches.
enum M7TtTheft { hook, upstream, loop, sealCut, magnet, bypass }

/// The report's two recipients.
enum M7TtWho { supervisor, vigilance }

/// What a reason asks about.
enum M7TtWhy { theft, symptom, legal, meterBad, meterOk, report }

/// One step of the trace.
enum M7TtStep { none, moved, off, done }

/// What a verdict did.
enum M7TtOutcome { none, right, bounce, slip }

/// The lesson point (0-based) for the fail panel: section 3 (what to do).
const int kM7TtLessonPoint = 2;

M7TtTheft? m7TtWireTheft(M7TtWireKind k) => switch (k) {
      M7TtWireKind.legal => null,
      M7TtWireKind.hook => M7TtTheft.hook,
      M7TtWireKind.upstream => M7TtTheft.upstream,
      M7TtWireKind.loop => M7TtTheft.loop,
    };

M7TtTheft? m7TtMeterTheft(M7TtMeterCase k) => switch (k) {
      M7TtMeterCase.intact => null,
      M7TtMeterCase.sealCut => M7TtTheft.sealCut,
      M7TtMeterCase.magnet => M7TtTheft.magnet,
      M7TtMeterCase.bypass => M7TtTheft.bypass,
    };

abstract final class M7TheftTraceLines {
  static const title = 'তারের পিছু পিছু';
  // DRAFT wording — owner (M6-12 / M7-10): every line below until the owner
  // gives the natural wording. The intro is the spec's.
  static const intro = 'এই ট্রান্সফরমার বারবার ওভারলোড, অথচ গ্রাহক কম! তার ধরে খুঁজুন, চুরি কোথায়।';

  // The guide's task now (tap him: the same task, a different way).
  static const askTrace = 'লাইন থেকে যেখানে তার নেমেছে, সেখানে আঙুল রেখে তার ধরে টানুন।';
  static const askVerdict = 'নকশাটা দেখুন — চুরি হলে লাল পিন ঠিক জায়গায় দিন, নইলে ঠিক আছে।';
  static const askMeter = 'মিটার বদলের আগে — ঢোকার তারে আঙুল রেখে মিটার হয়ে টানুন।';
  static const askReport = 'এবার রিপোর্ট — কাকে পাঠাবেন, বেছে নিয়ে পাঠান।';
  static const tasks = [askTrace, askVerdict, askMeter, askReport];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const bounce = 'পিনটা কোথায় দেবেন, নকশাটা আবার ভালো করে দেখুন।';

  // On screen (a worker's own words; shown, not spoken).
  static const sceneLabel = 'গলির তার';
  static const notebook = 'নোটবুক';
  static const okLabel = 'ঠিক আছে';
  static const pinLabel = 'লাল পিন';
  static const okPreviewWire = 'ঠিক আছে — এই তারে চুরি নেই';
  static const okPreviewMeter = 'ঠিক আছে — এই মিটারে গোলমাল নেই';
  static const lineEnd = 'লাইন';
  static const houseEnd = 'বাড়ি';
  static const meterJob = 'মিটার বদল';
  static String house(int slot) => enDigits('বাড়ি ${slot + 1}');
  static String lane(int i) => enDigits('গলি ${i + 1}');
  static const meterRound = 'মিটার';
  static const reportRound = 'রিপোর্ট';
  static const reportTitle = 'চুরির রিপোর্ট';
  static const reportTo = 'কাকে পাঠাবেন:';
  static const send = 'রিপোর্ট পাঠান';
  static String who(M7TtWho w) => switch (w) {
        M7TtWho.supervisor => 'সুপারভাইজার',
        M7TtWho.vigilance => 'ভিজিল্যান্স',
      };

  /// The report's list (what was found, in the player's words).
  static String found(M7TtTheft t) => switch (t) {
        M7TtTheft.hook => 'লাইনে হুকিং',
        M7TtTheft.upstream => 'মিটারের আগে থেকে সংযোগ',
        M7TtTheft.loop => 'মিটার বোর্ডে বাইপাস',
        M7TtTheft.sealCut => 'মিটারের সিল কাটা',
        M7TtTheft.magnet => 'মিটারে চুম্বক',
        M7TtTheft.bypass => 'মিটার বাইপাস জাম্পার',
      };

  // The reasons: the right ones fit what THIS wire or meter had; each
  // question has its own pool of plausible wrong answers.
  static const whyQ = <M7TtWhy, String>{
    M7TtWhy.theft: 'এটা চুরি কেন?',
    M7TtWhy.symptom: 'লক্ষণ দেখে চুরি সন্দেহ কেন?',
    M7TtWhy.legal: 'এই তারটা ঠিক কেন?',
    M7TtWhy.meterBad: 'মিটারের এই গোলমাল রিপোর্ট কেন?',
    M7TtWhy.meterOk: 'এই মিটারটা ঠিক কেন?',
    M7TtWhy.report: 'রিপোর্টটা কাকে, কেন পাঠালেন?',
  };
  static const whyTheft = <M7TtTheft, List<String>>{
    M7TtTheft.hook: ['হুক লাগিয়ে মিটার ছাড়াই বিদ্যুৎ নেওয়া', 'হুকিং করে লাইন থেকে সরাসরি বিদ্যুৎ নেওয়া'],
    M7TtTheft.upstream: ['মিটারের আগে থেকেই আলাদা সংযোগ নেওয়া', 'জোড়টা মিটারের আগে, তাই বিদ্যুৎ মাপা হয় না'],
    M7TtTheft.loop: ['তার ঘুরিয়ে মিটারকে বাইপাস করা হয়েছে', 'বিদ্যুৎ মিটারে না ঢুকে পাশ কাটিয়ে যাচ্ছে'],
    M7TtTheft.sealCut: ['সিল ভেঙে মিটারের ভেতরে কারচুপির লক্ষণ', 'মিটারের সিল কাটা — ভেতরে হাত পড়েছে'],
    M7TtTheft.magnet: ['চুম্বক লাগিয়ে মিটারের রিডিং প্রভাবিত করা', 'মিটারের গায়ে চুম্বক — এটা ট্যাম্পারিং'],
    M7TtTheft.bypass: ['জাম্পার দিয়ে মিটারকে বাইপাস করা হয়েছে', 'বিদ্যুৎ মিটারে না ঢুকেই বাড়িতে যাচ্ছে'],
  };
  static const whySymptom = ['গ্রাহক কম, তবু ট্রান্সফরমার বারবার ওভারলোড', 'লোড বেশি অথচ গ্রাহক কম — চুরির লক্ষণ'];
  static const whyLegal = ['ক্ল্যাম্পে লাগানো, মিটার হয়েই বাড়িতে', 'মিটারের আগে কোনো আলাদা সংযোগ নেই'];
  static const whyMeterOk = ['সিল অটুট, চুম্বক নেই, তার মিটার হয়ে', 'সিল ঠিক, তার সোজা মিটারের ভেতর দিয়ে'];
  static const whyReport = ['রিপোর্ট দেখেই ভিজিল্যান্স অভিযান চালায়', 'সুপারভাইজার ও ভিজিল্যান্সকে জানানোই নিয়ম'];

  static const wrongFor = <M7TtWhy, List<String>>{
    M7TtWhy.theft: [
      'তারটা পুরোনো আর জায়গায় জায়গায় টেপ মারা',
      'বাড়িটা দেখে বেশ বড়লোকের বাড়ি মনে হয়',
      'তারটা অন্য তারগুলোর ওপর দিয়ে গেছে',
      'গাছের ডালের আড়ালে তারটা লুকোনো ছিল',
      'এই বাড়ির বিল সবসময় দেরিতে জমা পড়ে',
    ],
    M7TtWhy.symptom: [
      'সন্ধ্যায় সব বাড়িতে আলো জ্বলছিল বলে',
      'গলিটা সরু আর তারগুলো জট পাকানো বলে',
      'ট্রান্সফরমারটা দেখতে বেশ পুরোনো বলে',
      'পাড়ার লোকেরা ঠিক করে কথা বলেনি বলে',
      'রাস্তায় আলো কম, তাই মনে সন্দেহ হলো',
    ],
    M7TtWhy.legal: [
      'তারটা দেখতে নতুন আর বেশ চকচকে লাগছে',
      'বাড়ির লোক ভালো, চুরি করার লোক নয়',
      'টেপ মারা থাকলেও তো দিব্যি আলো জ্বলছে',
      'এই বাড়ি নিয়ে কেউ কখনো নালিশ করেনি',
      'তারটা অন্য তারগুলোর চেয়ে বেশ মোটা',
    ],
    M7TtWhy.meterBad: [
      'মিটারটা পুরোনো, এমনিতেই বদলাতে হতো',
      'মিটারের কাচে অনেক ধুলো জমে আছে বলে',
      'বাড়ির মালিক বাড়িতে ছিলেন না বলে',
      'মিটার বোর্ডটা দেয়ালে একটু হেলে আছে বলে',
      'নতুন মিটারে রিডিং অনেক বেশি উঠবে বলে',
    ],
    M7TtWhy.meterOk: [
      'স্টিকার লাগানো মিটার সবসময় ঠিক থাকে',
      'পুরোনো মিটারে কেউ আর হাত দেয় না',
      'বাড়ির লোক বলল সব ঠিক আছে, তাই',
      'মিটার তো বদলাচ্ছি, দেখার দরকার নেই',
      'রিডিং চলছে মানেই মিটার ঠিক আছে',
    ],
    M7TtWhy.report: [
      'চোরকে নিজেই গিয়ে একটু ধমকে দিলেই চলত',
      'পুলিশ জানলেই হবে, আমাদের কিছু করার নয়',
      'পাড়ার লোককে জানালে ওরাই সব সামলাবে',
      'বাড়ির মালিককে বললেই তার খুলে নেবে',
      'রিপোর্ট দিলে পাড়ায় আমারই নাম খারাপ হবে',
    ],
  };

  /// The right cards for a question about [t] (null: the legal or intact one).
  static List<String> rightFor(M7TtWhy why, M7TtTheft? t) => switch (why) {
        M7TtWhy.theft || M7TtWhy.meterBad => whyTheft[t]!,
        M7TtWhy.symptom => whySymptom,
        M7TtWhy.legal => whyLegal,
        M7TtWhy.meterOk => whyMeterOk,
        M7TtWhy.report => whyReport,
      };
  static List<String> get allWhyRight => [for (final l in whyTheft.values) ...l, ...whySymptom, ...whyLegal, ...whyMeterOk, ...whyReport];
  static List<String> get allWhyWrong => [for (final l in wrongFor.values) ...l];

  // The careless coworker: lesson 7.5 myth 2, word for word (M7-10).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'বিদ্যুৎ চোরকে ধরা আমার কাজ নয়, ওটা পুলিশের কাজ।',
    exitLine: coworkerExit,
    right: [
      'না, চুরি ধরিয়ে দেওয়া আমাদেরই দায়িত্ব',
      'চুরি শনাক্ত করা কোম্পানির কর্মীরই কাজ',
      'না, রিপোর্ট করার দায়িত্ব আমাদেরই',
    ],
    wrong: [
      'ঠিক, পুলিশই বুঝুক, আমরা চুপ থাকি',
      'হ্যাঁ, রিপোর্ট না দিলেও কিছু হবে না',
      'আচ্ছা, তার দেখা থাক, চলো ফিরে যাই',
      'ঠিক, চোর ধরা আমাদের কাজের মধ্যে নেই',
      'হ্যাঁ, পুলিশ এলে তখন দেখা যাবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে চুরি ধরা পুলিশের কাজ। কী বলবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! চুরি শনাক্ত করে রিপোর্ট করা আমাদেরই দায়িত্ব।';

  static const allSet = 'চুরি ধরেছেন, রিপোর্টও ঠিক জায়গায় গেছে — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — প্রতিটা তার শেষ পর্যন্ত ধরে, নকশা মিলিয়ে দেখুন।';

  // "আজ যা ধরলেন": the theft types found.
  static String caught(M7TtTheft t) => switch (t) {
        M7TtTheft.hook => 'লাইনে হুকিং ধরেছেন',
        M7TtTheft.upstream => 'মিটারের আগে থেকে সংযোগ ধরেছেন',
        M7TtTheft.loop => 'মিটার বোর্ডে বাইপাস ধরেছেন',
        M7TtTheft.sealCut => 'মিটারের কাটা সিল ধরেছেন',
        M7TtTheft.magnet => 'মিটারে চুম্বক ধরেছেন',
        M7TtTheft.bypass => 'মিটার বাইপাস জাম্পার ধরেছেন',
      };
  static const caughtReport = 'রিপোর্ট দুজনকেই পাঠিয়েছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip (the exit, the old asks, the
  /// old reason taps, the quick-pass line).
  static const reused = {coworkerExit, 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', quick, 'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'};

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        bounce,
        ...whyQ.values,
        ...coworker.asks.where((a) => !reused.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M7TheftTraceMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused];
}

abstract final class M7TheftTraceMistakes {
  static const _dir = 'assets/game/art/m7_theft_trace';

  // DRAFT wording — owner (M6-12). Lesson 7.5 points (0-based): 0 the law
  // (section 135 list), 1 the methods (hooking, tampering), 2 what to do.

  // A pin where there is no theft (a false report; R16 / R29).
  static const falsePin = DoMistake(
    key: '7.5/m7_theft_trace/false-pin',
    textBn: 'এই তারটা ঠিক ছিল — ক্ল্যাম্পে লাগানো, মিটার হয়ে বাড়িতে। পুরোনো টেপ মানেই চুরি নয়; রিপোর্ট নির্ভুল হওয়া চাই।',
    art: '$_dir/false_pin.svg',
    lessonPoint: 2,
  );
  static const falseMeter = DoMistake(
    key: '7.5/m7_theft_trace/false-meter',
    textBn: 'এই মিটারে গোলমাল ছিল না — সিল অটুট, চুম্বক নেই, তার মিটারের ভেতর দিয়েই। রিপোর্ট নির্ভুল হওয়া চাই।',
    art: '$_dir/false_meter.svg',
    lessonPoint: 2,
  );

  // 'ঠিক আছে' on a theft (a missed theft; R16).
  static const okHook = DoMistake(
    key: '7.5/m7_theft_trace/ok-hook',
    textBn: 'এটা চুরি! তারটা লাইনে হুক দিয়ে লাগানো, মিটার ছাড়াই বাড়িতে ঢুকেছে — সরাসরি হুকিং।',
    art: '$_dir/ok_hook.svg',
    lessonPoint: 1,
  );
  static const okUpstream = DoMistake(
    key: '7.5/m7_theft_trace/ok-upstream',
    textBn: 'এটা চুরি! মিটারের আগেই জোড় দিয়ে আলাদা তার বাড়িতে ঢুকেছে — মিটারের আগে থেকে (Upstream) সংযোগ।',
    art: '$_dir/ok_upstream.svg',
    lessonPoint: 0,
  );
  static const okLoop = DoMistake(
    key: '7.5/m7_theft_trace/ok-loop',
    textBn: 'এটা চুরি! মিটার বোর্ডে তার ঘুরিয়ে মিটারকে বাইপাস করা হয়েছে — এটা মিটার ট্যাম্পারিং।',
    art: '$_dir/ok_loop.svg',
    lessonPoint: 1,
  );
  static const missSeal = DoMistake(
    key: '7.5/m7_theft_trace/miss-seal',
    textBn: 'মিটারের সিল কাটা ছিল! সিল ভেঙে ভেতরে কারচুপি হয় — মিটার বদলের সময় সিল ভালো করে দেখে রিপোর্ট করুন।',
    art: '$_dir/miss_seal.svg',
    lessonPoint: 1,
  );
  static const missMagnet = DoMistake(
    key: '7.5/m7_theft_trace/miss-magnet',
    textBn: 'মিটারের গায়ে চুম্বক লাগানো ছিল! এতে মিটারের রিডিং প্রভাবিত হয় — এটা মিটার ট্যাম্পারিং, রিপোর্ট করুন।',
    art: '$_dir/miss_magnet.svg',
    lessonPoint: 1,
  );
  static const missBypass = DoMistake(
    key: '7.5/m7_theft_trace/miss-bypass',
    textBn: 'তার মিটারে না ঢুকে জাম্পার দিয়ে পাশ কাটিয়ে গেছে — মিটার বাইপাস! এটা মিটার ট্যাম্পারিং, রিপোর্ট করুন।',
    art: '$_dir/miss_bypass.svg',
    lessonPoint: 1,
  );

  // The report without both recipients (R16).
  static const sendBoth = DoMistake(
    key: '7.5/m7_theft_trace/send-both',
    textBn: 'রিপোর্ট যাবে দুজনের কাছেই — আপনার সুপারভাইজার এবং কোম্পানির ভিজিল্যান্স বিভাগ। কাউকে বাদ দেবেন না।',
    art: '$_dir/send_both.svg',
    lessonPoint: 2,
  );

  // Listening to the coworker (lesson 7.5 myth 2 and its reality; R30, X2/B1).
  static const pushListen = DoMistake(
    key: '7.5/m7_theft_trace/push-listen',
    textBn: 'ভুল। পুলিশ আইন-শৃঙ্খলা রক্ষায় সাহায্য করে, কিন্তু চুরি শনাক্ত করা আর রিপোর্ট করার প্রধান দায়িত্ব কোম্পানির কর্মীদের — আপনারও।',
    art: '$_dir/push_listen.svg',
    lessonPoint: 2,
  );

  /// 'ঠিক আছে' on [t].
  static DoMistake okOn(M7TtTheft t) => switch (t) {
        M7TtTheft.hook => okHook,
        M7TtTheft.upstream => okUpstream,
        M7TtTheft.loop => okLoop,
        M7TtTheft.sealCut => missSeal,
        M7TtTheft.magnet => missMagnet,
        M7TtTheft.bypass => missBypass,
      };

  static const List<DoMistake> all = [falsePin, falseMeter, okHook, okUpstream, okLoop, missSeal, missMagnet, missBypass, sendBoth, pushListen];
}

/// One play's deal.
@immutable
class M7TtDeal {
  const M7TtDeal({required this.lanes, required this.meter, required this.coworkerAtSend, required this.symptomFirst});

  /// The two lanes (the second has the other conductor).
  final List<M7TtLane> lanes;
  final M7TtMeter meter;

  /// The coworker comes at the send (else after the first right pin's reason).
  final bool coworkerAtSend;

  /// The first right pin's reason asks about the symptoms.
  final bool symptomFirst;
}

/// The lanes a play.
const kM7TtLanes = 2;

/// Rounds: two lanes, the meter, the report.
const kM7TtRounds = 4;

M7TtLane m7TtLane(math.Random rng, M7TtCond cond) {
  // 1–2 thefts, different kinds in one lane.
  final kinds = [M7TtWireKind.hook, M7TtWireKind.upstream, M7TtWireKind.loop]..shuffle(rng);
  final thefts = kinds.take(1 + rng.nextInt(2)).toList();
  final hook = thefts.contains(M7TtWireKind.hook);
  final nHouses = hook && rng.nextBool() ? 3 : 4;
  final houses = ([0, 1, 2, 3]..shuffle(rng)).take(nHouses).toList()..sort();
  // One service wire per house; the upstream / loop thefts on some of them.
  final service = {for (final h in houses) h: M7TtWireKind.legal};
  final order = [...houses]..shuffle(rng);
  var k = 0;
  for (final t in thefts) {
    if (t == M7TtWireKind.hook) continue;
    service[order[k++]] = t;
  }
  final sides = {for (final h in houses) h: rng.nextBool() ? 1.0 : -1.0};
  // The hook goes into a house whose service is not tapped before its meter
  // (the stub would share its wall entry), on the other side of the house.
  final specs = <(int, M7TtWireKind, double)>[for (final h in houses) (h, service[h]!, sides[h]!)];
  if (hook) {
    final can = houses.where((h) => service[h] != M7TtWireKind.upstream).toList();
    final h = can[rng.nextInt(can.length)];
    specs.add((h, M7TtWireKind.hook, -sides[h]!));
  }
  // Roots on the line: dealt slots, never in the houses' order.
  final n = specs.length;
  final slots = ([...M7TtGeo.rootXs]..shuffle(rng)).take(n).toList()..sort();
  List<int> perm;
  do {
    perm = [for (var i = 0; i < n; i++) i]..shuffle(rng);
  } while (_inversions(perm) < 2);
  // Specs sorted by where they end (left to right), so the shuffle crosses them.
  specs.sort((a, b) => (M7TtGeo.houseXs[a.$1] + a.$3).compareTo(M7TtGeo.houseXs[b.$1] + b.$3));
  final wires = <M7TtWire>[
    for (var i = 0; i < n; i++)
      M7TtWire(
        id: i,
        house: specs[i].$1,
        kind: specs[i].$2,
        // Any wire may carry an old patch (an upstream one too: its patch sits
        // half way, its joint further on — the joint stays the theft point).
        patched: rng.nextInt(100) < 40,
        rootX: slots[perm[i]],
        j1: -24 + rng.nextDouble() * 48,
        j2: -24 + rng.nextDouble() * 48,
        side: specs[i].$3,
      ),
  ];
  // At least one legal wire carries an old patch (theft is not "old tape").
  if (!wires.any((w) => w.kind == M7TtWireKind.legal && w.patched)) {
    final legal = wires.where((w) => w.kind == M7TtWireKind.legal).toList();
    final w = legal[rng.nextInt(legal.length)];
    wires[w.id] = M7TtWire(id: w.id, house: w.house, kind: w.kind, patched: true, rootX: w.rootX, j1: w.j1, j2: w.j2, side: w.side);
  }
  final branchLeft = rng.nextBool();
  return M7TtLane(
    cond: cond,
    houses: houses,
    wires: wires,
    branchX: branchLeft ? 96 : 264,
    signX: branchLeft ? 250 : 110,
    dtrRight: rng.nextBool(),
  );
}

int _inversions(List<int> p) {
  var n = 0;
  for (var i = 0; i < p.length; i++) {
    for (var j = i + 1; j < p.length; j++) {
      if (p[i] > p[j]) n++;
    }
  }
  return n;
}

M7TtDeal m7TtDeal(math.Random rng) {
  final first = rng.nextBool() ? M7TtCond.bare : M7TtCond.ab;
  final second = first == M7TtCond.bare ? M7TtCond.ab : M7TtCond.bare;
  final lanes = [m7TtLane(rng, first), m7TtLane(rng, second)];
  final meter = M7TtMeter(
    kase: M7TtMeterCase.values[rng.nextInt(M7TtMeterCase.values.length)],
    patched: rng.nextBool(),
    sticker: rng.nextBool(),
    houseNo: 10 + rng.nextInt(90),
  );
  return M7TtDeal(lanes: lanes, meter: meter, coworkerAtSend: rng.nextBool(), symptomFirst: rng.nextBool());
}

/// How near the wire the finger must stay for the chalk to follow (design px).
const double kM7TtWireTol = 20;

/// How near a root (or the chalk head) a drag must start to trace.
const double kM7TtGrab = 24;

/// The play state (pure logic; the trace takes the scene's geometry).
class M7TtRun {
  M7TtRun(this.deal);
  final M7TtDeal deal;

  /// 0, 1 the lanes; 2 the meter; 3 the report; 4 done.
  int round = 0;
  int slips = 0;
  final List<String> caught = [];

  /// The lane's wires judged right.
  final Set<int> judged = {};

  /// The wire being traced (0 on the meter) and how far (design px along).
  int? active;
  double s = 0;

  /// The active wire is traced to its end (its verdict is due).
  var traced = false;
  var meterDone = false;

  var supervisor = false;
  var vigilance = false;
  var sent = false;

  /// The thefts found, in order (the report's list).
  final List<M7TtTheft> found = [];

  final Set<M7TtTheft> _asked = {};
  var _okAsked = false;
  var pinsRight = 0;

  bool get onLane => round < kM7TtLanes;
  bool get onMeter => round == kM7TtLanes;
  bool get onReport => round == kM7TtLanes + 1;
  bool get done => round >= kM7TtRounds;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  M7TtLane get lane => deal.lanes[round.clamp(0, kM7TtLanes - 1)];
  M7TtMeter get meter => deal.meter;

  bool get canTrace => (onLane || (onMeter && !meterDone)) && !traced;
  bool get laneDone => onLane && judged.length == lane.wires.length;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// The path of wire [id] (the meter's on the close-up).
  List<Offset> pathOf(int id, M7TtGeo g) => onMeter ? g.meterPoints(meter) : g.wirePoints(lane.wire(id));

  static List<double> _cum(List<Offset> pts) {
    final c = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      c.add(c.last + (pts[i] - pts[i - 1]).distance);
    }
    return c;
  }

  static Offset _at(List<Offset> pts, List<double> cum, double s) {
    if (s <= 0) return pts.first;
    for (var i = 1; i < pts.length; i++) {
      if (cum[i] >= s) {
        final seg = cum[i] - cum[i - 1];
        return Offset.lerp(pts[i - 1], pts[i], seg == 0 ? 0 : (s - cum[i - 1]) / seg)!;
      }
    }
    return pts.last;
  }

  /// The chalk head (design px).
  Offset? head(M7TtGeo g) {
    final a = active;
    if (a == null) return null;
    final pts = pathOf(a, g);
    return _at(pts, _cum(pts), s);
  }

  /// A point [d] design px further along the active wire than the head.
  Offset? ahead(M7TtGeo g, double d) {
    final a = active;
    if (a == null) return null;
    final pts = pathOf(a, g);
    return _at(pts, _cum(pts), s + d);
  }

  /// The chalk from the root to the head.
  List<Offset> chalk(M7TtGeo g) {
    final a = active;
    if (a == null) return const [];
    final pts = pathOf(a, g);
    final cum = _cum(pts);
    return [
      for (var i = 0; i < pts.length && cum[i] < s; i++) pts[i],
      _at(pts, cum, s),
    ];
  }

  /// The roots still to trace (lane) or the close-up's start.
  List<Offset> starts(M7TtGeo g) => onMeter
      ? (meterDone ? const [] : [g.cableStart])
      : [
          for (final w in lane.wires)
            if (!judged.contains(w.id)) g.root(w),
        ];

  /// A drag starting at [p]: the wire it takes (the active head, a root still
  /// to trace, the close-up's start), or null.
  int? grab(Offset p, M7TtGeo g) {
    if (!canTrace) return null;
    final h = head(g);
    if (h != null && s > 0 && (p - h).distance <= kM7TtGrab) return active;
    if (onMeter) return (p - g.cableStart).distance <= kM7TtGrab ? 0 : null;
    int? best;
    var bestD = kM7TtGrab;
    for (final w in lane.wires) {
      if (judged.contains(w.id)) continue;
      final d = (p - g.root(w)).distance;
      if (d <= bestD) {
        best = w.id;
        bestD = d;
      }
    }
    return best;
  }

  /// Start (or go on) tracing wire [id]; another wire's chalk is dropped.
  void begin(int id) {
    if (!canTrace) return;
    if (active != id) {
      active = id;
      s = 0;
    }
  }

  /// The finger at [p] while it traces: the chalk follows it along the wire
  /// (only on the wire, near the head; back along it rubs out). Off the wire
  /// the trace stops ([M7TtStep.off]).
  M7TtStep trace(Offset p, M7TtGeo g) {
    final a = active;
    if (a == null || !canTrace) return M7TtStep.none;
    final pts = pathOf(a, g);
    final cum = _cum(pts);
    final total = cum.last;
    var bestD = double.infinity;
    var bestS = s;
    for (var i = 1; i < pts.length; i++) {
      if (cum[i] < s - 40 || cum[i - 1] > s + 52) continue;
      final aa = pts[i - 1];
      final ab = pts[i] - aa;
      final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
      final t = len2 == 0 ? 0.0 : (((p.dx - aa.dx) * ab.dx + (p.dy - aa.dy) * ab.dy) / len2).clamp(0.0, 1.0);
      final q = aa + ab * t;
      final d = (p - q).distance;
      if (d < bestD) {
        bestD = d;
        bestS = cum[i - 1] + (cum[i] - cum[i - 1]) * t;
      }
    }
    if (bestD > kM7TtWireTol) return M7TtStep.off;
    if ((bestS - s).abs() < 1e-6) return M7TtStep.none;
    s = bestS.clamp(0.0, total);
    if (s >= total - 5) {
      s = total;
      traced = true;
      return M7TtStep.done;
    }
    return M7TtStep.moved;
  }

  /// The points of the item whose verdict is due (null: none).
  List<M7TtSpot>? get spots {
    final a = active;
    if (!traced || a == null) return null;
    return onMeter ? m7TtMeterSpots(meter) : m7TtWireSpots(lane.wire(a));
  }

  /// The theft of the item whose verdict is due (null: legal / intact).
  M7TtTheft? get theft {
    final a = active;
    if (a == null) return null;
    return onMeter ? m7TtMeterTheft(meter.kase) : m7TtWireTheft(lane.wire(a).kind);
  }

  /// The red pin on point [i] of the sketch.
  (M7TtOutcome, DoMistake?) pin(int i) {
    final sp = spots;
    if (sp == null || i < 0 || i >= sp.length) return (M7TtOutcome.none, null);
    final t = theft;
    if (t == null) return (M7TtOutcome.slip, _slip(onMeter ? M7TheftTraceMistakes.falseMeter : M7TheftTraceMistakes.falsePin));
    if (!kM7TtTheftSpots.contains(sp[i])) return (M7TtOutcome.bounce, null);
    _judge();
    found.add(t);
    pinsRight++;
    _tag(M7TheftTraceLines.caught(t));
    return (M7TtOutcome.right, null);
  }

  /// 'ঠিক আছে' on the item whose verdict is due.
  (M7TtOutcome, DoMistake?) ok() {
    if (spots == null) return (M7TtOutcome.none, null);
    final t = theft;
    if (t != null) return (M7TtOutcome.slip, _slip(M7TheftTraceMistakes.okOn(t)));
    _judge();
    return (M7TtOutcome.right, null);
  }

  /// The item just judged (for the scene's pin): the wire id (lane).
  int? lastJudged;

  void _judge() {
    lastJudged = active;
    if (onLane) {
      judged.add(active!);
    } else {
      meterDone = true;
    }
    active = null;
    s = 0;
    traced = false;
  }

  /// A reason for this right verdict? (The first of each theft kind, the
  /// first lane 'ঠিক আছে' of the whole play — not one per lane — and every
  /// meter verdict.)
  bool wantsWhy(M7TtTheft? t) {
    if (onMeter) return true;
    if (t == null) {
      if (_okAsked) return false;
      _okAsked = true;
      return true;
    }
    return _asked.add(t);
  }

  void nextRound() {
    if (done) return;
    round++;
    judged.clear();
    active = null;
    s = 0;
    traced = false;
    lastJudged = null;
  }

  void toggle(M7TtWho w) {
    if (!onReport || sent) return;
    switch (w) {
      case M7TtWho.supervisor:
        supervisor = !supervisor;
      case M7TtWho.vigilance:
        vigilance = !vigilance;
    }
  }

  /// রিপোর্ট পাঠান: both ticked → right; else a slip (it stays open).
  (M7TtOutcome, DoMistake?) send() {
    if (!onReport || sent) return (M7TtOutcome.none, null);
    if (!supervisor || !vigilance) return (M7TtOutcome.slip, _slip(M7TheftTraceMistakes.sendBoth));
    sent = true;
    _tag(M7TheftTraceLines.caughtReport);
    return (M7TtOutcome.right, null);
  }

  /// Listened to him (a slip, X2/B1).
  DoMistake pushSlip() => _slip(M7TheftTraceMistakes.pushListen);
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action: lanes 9–10 wires × (trace ≈ 3500 + verdict
/// ≈ 2500, an ঠিক আছে with its preview ≈ 3000) ≈ 58000; reasons (first of
/// each theft kind, the first ঠিক আছে, the meter, the report: 5–6 ≈ 7000)
/// ≈ 38500; the meter trace and verdict ≈ 7000; the report ≈ 5000; the
/// coworker ≈ 9600; round changes ≈ 4500 → ≈ 122600; 85 % ≈ 104000 →
/// 110 s (a builder's estimate until playtest).
const m7TheftTraceQuickMs = 110000;

@immutable
class M7TheftTracePack {
  const M7TheftTracePack({required this.id, required this.titleBn, this.quickMs = m7TheftTraceQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7TheftTracePack> m7TheftTracePacks = {
  'do_7_5_a': M7TheftTracePack(id: 'do_7_5_a', titleBn: M7TheftTraceLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7TheftTraceProbe {
  static M7TtRun? run;
  static M7TtGeo? geo;
}

// ============================================================================
// Page
// ============================================================================

class M7TheftTracePage extends StatefulWidget {
  const M7TheftTracePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7TheftTracePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7TheftTracePage> createState() => _M7TheftTracePageState();
}

class _M7TheftTracePageState extends State<M7TheftTracePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TraceRunPage(
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

class _TraceRunPage extends ConsumerStatefulWidget {
  const _TraceRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7TheftTracePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TraceRunPage> createState() => _TraceRunPageState();
}

/// What the reason being paid was for.
enum _After { verdict, report }

class _TraceRunPageState extends ConsumerState<_TraceRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7TtRun _run;
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

  /// The chalk repaints on this (no page rebuild while tracing).
  final _chalkTick = ValueNotifier<int>(0);
  var _tracing = false;

  /// The red pin while it is dragged (notebook-local px; null at home).
  final _pinAt = ValueNotifier<Offset?>(null);
  var _pinDrag = false;

  /// The 'ঠিক আছে' preview is open; it was set aside for this item.
  var _okPreview = false;
  var _okAside = false;

  /// Pins left on the scene this round (design px).
  final List<Offset> _pins = [];

  _After? _after;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _okKey = GlobalKey();
  final _pinKey = GlobalKey();
  final _supKey = GlobalKey();
  final _vigKey = GlobalKey();
  final _sendKey = GlobalKey();
  int _steps = 0;
  M7TtGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7TtRun(m7TtDeal(widget.rng));
    M7TheftTraceProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _chalkTick.dispose();
    _pinAt.dispose();
    if (identical(M7TheftTraceProbe.run, _run)) {
      M7TheftTraceProbe.run = null;
      M7TheftTraceProbe.geo = null;
    }
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

  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_okPreview;

  String get _task => _run.onReport
      ? M7TheftTraceLines.askReport
      : _run.traced
          ? M7TheftTraceLines.askVerdict
          : _run.onMeter
              ? M7TheftTraceLines.askMeter
              : M7TheftTraceLines.askTrace;

  // --- the flow -------------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() {
      _wake++;
      _pins.clear();
      _okAside = false;
      _tracing = false;
      _pinAt.value = null;
    });
    _chalkTick.value++;
    if (_run.onReport && !coworkerDone && !coworkerDue) scheduleCoworker();
    unawaited(_sayChain([_task]));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- the trace ------------------------------------------------------------------
  void _panStart(Offset p) {
    _tracing = false;
    if (!_canPlay) return;
    final geo = _geoNow;
    if (geo == null || !_run.canTrace) return;
    final id = _run.grab(p, geo);
    if (id == null) return;
    // After the first right pin's reason he is due: the next trace waits.
    if (holdForCoworker()) return;
    _run.begin(id);
    _tracing = true;
    _chalkTick.value++;
  }

  void _panUpdate(Offset p) {
    if (!_tracing) return;
    final geo = _geoNow;
    if (!_canPlay || geo == null) {
      _tracing = false;
      return;
    }
    final step = _run.trace(p, geo);
    switch (step) {
      case M7TtStep.none:
        break;
      case M7TtStep.moved:
        _chalkTick.value++;
      case M7TtStep.off:
        // Slid off onto another wire (or the sky): the chalk stays, no cost.
        _tracing = false;
        _stepDone();
      case M7TtStep.done:
        _tracing = false;
        _chalkTick.value++;
        _traced();
    }
  }

  void _panEnd() {
    if (_tracing) {
      _tracing = false;
      _stepDone();
    }
  }

  void _tapScene() {
    if (!_canPlay) return;
    _hints.missTap();
  }

  void _traced() {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    setState(() {
      _okAside = false;
      _pinAt.value = null;
    });
    _stepDone();
    unawaited(_sayChain([M7TheftTraceLines.askVerdict]));
  }

  // --- the verdict ----------------------------------------------------------------
  void _pinStart(Offset local) {
    if (!_canPlay || !_run.traced) return;
    if ((local - M7TtSketch.pinHome).distance > 30) return;
    _pinDrag = true;
    _pinAt.value = local;
    setState(() => _wake++);
  }

  void _pinMove(Offset local) {
    if (!_pinDrag) return;
    if (!_canPlay) {
      _pinDrag = false;
      _pinAt.value = null;
      return;
    }
    _pinAt.value = local;
  }

  void _pinEnd(Offset global) {
    if (!_pinDrag) return;
    _pinDrag = false;
    final at = _pinAt.value;
    _pinAt.value = null;
    setState(() => _wake++);
    final sp = _run.spots;
    if (at == null || sp == null || !_canPlay) return;
    int? hit;
    var best = M7TtSketch.reach;
    for (var i = 0; i < sp.length; i++) {
      final d = (at - m7TtStationAt(sp, i)).distance;
      if (d <= best) {
        hit = i;
        best = d;
      }
    }
    if (hit == null) {
      // Dropped on the page: the pin springs back.
      _hints.missTap();
      return;
    }
    _pin(hit, global);
  }

  void _pin(int i, Offset global) {
    final t = _run.theft;
    final wire = _run.onLane ? _run.lane.wire(_run.active!) : null;
    final (out, m) = _run.pin(i);
    switch (out) {
      case M7TtOutcome.right:
        final geo = _geoNow;
        if (geo != null) _pins.add(wire != null ? geo.theftAt(wire) : geo.meterTheftAt(_run.meter));
        _right(t, global);
      case M7TtOutcome.bounce:
        _tick();
        unawaited(_sayChain([M7TheftTraceLines.bounce]));
      case M7TtOutcome.slip:
        unawaited(_mistake(m!, global));
      case M7TtOutcome.none:
        break;
    }
  }

  void _okTap() {
    if (!_canPlay || !_run.traced) return;
    _tick();
    setState(() => _okPreview = true);
  }

  void _okConfirm() {
    setState(() => _okPreview = false);
    if (!_canPlay) return;
    final t = _run.theft;
    final size = MediaQuery.sizeOf(context);
    final origin = Offset(size.width * 0.7, size.height * 0.5);
    final (out, m) = _run.ok();
    switch (out) {
      case M7TtOutcome.right:
        _right(t, origin);
      case M7TtOutcome.slip:
        unawaited(_mistake(m!, origin));
      case M7TtOutcome.bounce:
      case M7TtOutcome.none:
        break;
    }
  }

  void _okReject() => setState(() {
        _okPreview = false;
        _okAside = true;
      });

  /// A right verdict on [t] (null: a legal wire or an intact meter).
  void _right(M7TtTheft? t, Offset origin) {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _okAside = false;
    _stepDone();
    _chalkTick.value++;
    final meter = _run.onMeter;
    if (!_run.wantsWhy(t)) {
      unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
      _afterVerdict();
      return;
    }
    _hush();
    putOnTable(15);
    _after = _After.verdict;
    final why = meter
        ? (t == null ? M7TtWhy.meterOk : M7TtWhy.meterBad)
        : t == null
            ? M7TtWhy.legal
            : (_run.pinsRight == 1 && _run.deal.symptomFirst ? M7TtWhy.symptom : M7TtWhy.theft);
    final round = _run.round;
    unawaited(askReason(
      deal: () => dealChoices(M7TheftTraceLines.rightFor(why, t), M7TheftTraceLines.wrongFor[why]!, widget.rng),
      question: M7TheftTraceLines.whyQ[why]!,
      stillValid: () => _run.round == round && !_ended,
    ));
  }

  void _afterVerdict() {
    if (_run.laneDone || (_run.onMeter && _run.meterDone)) {
      _advanceLater(_run.round, _quiet ? 400 : 900);
      return;
    }
    unawaited(_sayChain([_task]));
  }

  /// The round is done: the next one after a moment (not under a card or the
  /// coworker).
  void _advanceLater(int round, int ms) {
    unawaited(Future<void>.delayed(Duration(milliseconds: ms), () {
      if (!mounted || _ended || _run.round != round) return;
      if (_card != null || coworkerOpen || tableBusy) {
        _advanceLater(round, 600);
        return;
      }
      _nextRound();
    }));
  }

  void _nextRound() {
    setState(_run.nextRound);
    _startRound();
  }

  // --- the report -------------------------------------------------------------
  void _toggle(M7TtWho w) {
    if (!_canPlay || !_run.onReport) return;
    _tick('sounds/learn/tag_slap.ogg', 0.4);
    setState(() {
      _run.toggle(w);
      _wake++;
    });
    _steps++;
  }

  void _send() {
    if (!_canPlay || !_run.onReport) return;
    // He is dealt at the send (or was not met yet): the send waits for him.
    if (holdForCoworker()) return;
    final size = MediaQuery.sizeOf(context);
    final origin = Offset(size.width / 2, size.height * 0.6);
    final (out, m) = _run.send();
    switch (out) {
      case M7TtOutcome.right:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        _stepDone();
        _hush();
        putOnTable(15);
        _after = _After.report;
        unawaited(askReason(
          deal: () => dealChoices(M7TheftTraceLines.whyReport, M7TheftTraceLines.wrongFor[M7TtWhy.report]!, widget.rng),
          question: M7TheftTraceLines.whyQ[M7TtWhy.report]!,
          stillValid: () => !_ended,
        ));
      case M7TtOutcome.slip:
        unawaited(_mistake(m!, origin));
      case M7TtOutcome.bounce:
      case M7TtOutcome.none:
        break;
    }
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
    final after = _after;
    _after = null;
    switch (after) {
      case _After.verdict:
        // He is dealt after the first right pin's reason: he comes now (the
        // next trace start waits for him).
        if (!_run.deal.coworkerAtSend && _run.pinsRight >= 1 && !coworkerDone && !coworkerDue) scheduleCoworker();
        _afterVerdict();
      case _After.report:
        unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
          if (!mounted || _ended) return;
          setState(_run.nextRound);
          unawaited(_finish());
        }));
      case null:
        break;
    }
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7TheftTraceLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.sent) return null;
    if (_intro || _card != null || tableBusy || _okPreview || _pinDrag || _tracing) return false;
    // At the report he waits for the send (held).
    if (_run.onReport) return false;
    if (_run.deal.coworkerAtSend) return false;
    // After the first right pin: when no verdict is open.
    return _run.pinsRight >= 1 && !_run.traced;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    _tracing = false;
    if (!held) {
      final m = _run.pushSlip();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M7TheftTraceLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7TheftTraceLines.callHeld], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7TheftTraceLines.tapWhy[_nudgeN++ % M7TheftTraceLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('m7theft/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same item goes on from where it was.
    _hush();
    setState(() {
      _card = null;
      _okAside = false;
      _wake++;
    });
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
    await _say(!_run.passed ? M7TheftTraceLines.fail : (_quickBonus ? M7TheftTraceLines.quick : M7TheftTraceLines.allSet),
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
    if (_passed) return LinemanMode.cheer;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what (see the header).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    if (_run.onReport) {
      if (_run.supervisor && _run.vigilance) return HintSpec.tapOn(_sendKey);
      return HintSpec.sweepOver([_supKey, _vigKey]);
    }
    if (_run.traced) return HintSpec.sweepOver([_pinKey, _okKey]);
    final head = _run.head(geo);
    if (head != null && _run.s > 0) {
      // Along the wire from the head (its next stretch), a short nudge.
      final dir = (_run.ahead(geo, 16) ?? head) - head;
      return HintSpec.drag(head, toward: dir.distance == 0 ? const Offset(0, 1) : dir / dir.distance, travel: 44, space: HintSpace.scene);
    }
    if (_run.onMeter) return HintSpec.drag(geo.cableStart, toward: const Offset(0, 1), travel: 44, space: HintSpace.scene);
    final roots = _run.starts(geo);
    if (roots.length < 2) {
      return roots.isEmpty ? null : HintSpec.drag(roots.single, toward: const Offset(0, 1), travel: 40, space: HintSpace.scene);
    }
    return HintSpec.sweep([for (final r in roots) Rect.fromCenter(center: r, width: 26, height: 26)], space: HintSpace.scene);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7TheftTraceProbe.geo = M7TtGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final r = _run;
    final onMeterScene = r.onMeter || r.onReport;
    final lane = r.lane;
    final trainee = geo.trainee();
    return [
      Positioned.fill(
        key: ValueKey('world-${onMeterScene ? 'meter' : 'lane-${r.round}'}'),
        child: RepaintBoundary(
          child: CustomPaint(painter: onMeterScene ? M7TtMeterPainter(geo: geo, meter: r.meter) : M7TtLanePainter(geo: geo, lane: lane)),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('chalk'),
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M7TtChalkPainter(
                points: () => _run.chalk(geo),
                done: () => [
                  if (_run.onLane)
                    for (final id in _run.judged) geo.wirePoints(_run.lane.wire(id))
                  else if (_run.meterDone)
                    geo.meterPoints(_run.meter),
                ],
                repaint: _chalkTick,
              ),
            ),
          ),
        ),
      ),
      for (final (i, p) in _pins.indexed)
        Positioned(
          key: ValueKey('scene-pin-${r.round}-$i'),
          left: p.dx - 9,
          top: p.dy - 26,
          width: 18,
          height: 26,
          child: const IgnorePointer(child: CustomPaint(painter: M7TtPinPainter())),
        ),
      if (!onMeterScene)
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: trainee,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7TheftTraceLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (_) => _tapScene(),
            onPanStart: (d) => _panStart(d.localPosition),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: () => _tracing = false,
          ),
        ),
      ),
      if (r.traced && r.spots != null)
        Positioned.fromRect(
          key: ValueKey('notebook-${r.round}-${r.active}'),
          rect: geo.notebook,
          child: _Notebook(
            title: r.onMeter ? M7TheftTraceLines.meterJob : M7TheftTraceLines.house(r.lane.wire(r.active!).house),
            spots: r.spots!,
            meter: r.onMeter,
            pinAt: _pinAt,
            okAside: _okAside,
            quiet: quiet,
            okKey: _okKey,
            pinKey: _pinKey,
            onPinStart: _pinStart,
            onPinMove: _pinMove,
            onPinEnd: _pinEnd,
            onOk: _okTap,
          ),
        ),
      if (r.onReport)
        Positioned.fromRect(
          key: const ValueKey('report'),
          rect: geo.report,
          child: _ReportSheet(
            found: r.found,
            supervisor: r.supervisor,
            vigilance: r.vigilance,
            supKey: _supKey,
            vigKey: _vigKey,
            sendKey: _sendKey,
            onToggle: _toggle,
            onSend: _send,
          ),
        ),
      // The next round: a short fade.
      if (!_intro)
        Positioned.fill(
          key: ValueKey('round-${r.round}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || r.round == 0 ? 0 : 0.6, end: 0),
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
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.done;
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
              labels: [M7TheftTraceLines.lane(0), M7TheftTraceLines.lane(1), M7TheftTraceLines.meterRound, M7TheftTraceLines.reportRound],
              done: {for (var i = 0; i < math.min(_run.round, kM7TtRounds); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_okPreview && !_pinDrag && !_tracing,
            hintKey: '${_run.round}/$_steps/${_run.traced}/${_run.active}/${_run.judged.length}/${_run.supervisor}/${_run.vigilance}',
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_okPreview)
                Positioned.fill(
                  key: const ValueKey('ok-preview'),
                  child: CardPreviewOverlay(
                    textBn: _run.onMeter ? M7TheftTraceLines.okPreviewMeter : M7TheftTraceLines.okPreviewWire,
                    icon: Icons.check_circle_outline_rounded,
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _okConfirm,
                    onReject: _okReject,
                  ),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.round}-$strikes'),
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
                  line: M7TheftTraceLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: kM7TtLessonPoint, muted: _muted)),
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

/// The notebook: the traced path sketched (its points in a row), the red pin
/// to drag onto a point, and 'ঠিক আছে'.
class _Notebook extends StatelessWidget {
  const _Notebook({
    required this.title,
    required this.spots,
    required this.meter,
    required this.pinAt,
    required this.okAside,
    required this.quiet,
    required this.okKey,
    required this.pinKey,
    required this.onPinStart,
    required this.onPinMove,
    required this.onPinEnd,
    required this.onOk,
  });

  final String title;
  final List<M7TtSpot> spots;
  final bool meter;
  final ValueListenable<Offset?> pinAt;
  final bool okAside;
  final bool quiet;
  final GlobalKey okKey;
  final GlobalKey pinKey;
  final ValueChanged<Offset> onPinStart;
  final ValueChanged<Offset> onPinMove;
  final ValueChanged<Offset> onPinEnd;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final ink = bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2A3A6A));
    final n = spots.length;
    return Semantics(
      label: M7TheftTraceLines.notebook,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ruled lines.
            const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _RulePainter()))),
            Positioned(
              left: 12,
              top: 8,
              right: 12,
              child: Row(
                children: [
                  Text(M7TheftTraceLines.notebook, style: ink.copyWith(color: const Color(0xFF8A2A16))),
                  const Spacer(),
                  Text(title, style: ink),
                ],
              ),
            ),
            if (!meter) ...[
              Positioned(left: M7TtSketch.left - 30, top: M7TtSketch.y + 22, width: 60, child: Text(M7TheftTraceLines.lineEnd, textAlign: TextAlign.center, style: ink.copyWith(fontSize: 10))),
              Positioned(left: M7TtSketch.right - 30, top: M7TtSketch.y + 22, width: 60, child: Text(M7TheftTraceLines.houseEnd, textAlign: TextAlign.center, style: ink.copyWith(fontSize: 10))),
            ],
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: quiet ? 1 : 0, end: 1),
                  duration: Duration(milliseconds: 160 * n),
                  builder: (_, v, _) => CustomPaint(painter: M7TtSketchPainter(spots: spots, v: v)),
                ),
              ),
            ),
            // The pin's dish and 'ঠিক আছে'.
            Positioned(
              left: M7TtSketch.pinHome.dx - 26,
              top: M7TtSketch.pinHome.dy - 22,
              width: 52,
              height: 40,
              child: IgnorePointer(
                child: DecoratedBox(
                  key: pinKey,
                  decoration: BoxDecoration(color: const Color(0x1A8A2A16), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x558A2A16))),
                ),
              ),
            ),
            Positioned(
              left: M7TtSketch.pinHome.dx + 30,
              top: M7TtSketch.pinHome.dy - 8,
              child: IgnorePointer(child: Text(M7TheftTraceLines.pinLabel, style: ink.copyWith(fontSize: 10, color: const Color(0xFF8A2A16)))),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: (d) => onPinStart(d.localPosition),
                onPanUpdate: (d) => onPinMove(d.localPosition),
                onPanEnd: (d) => onPinEnd(d.globalPosition),
              ),
            ),
            Positioned.fromRect(
              rect: M7TtSketch.okBox,
              child: CardAside(
                aside: okAside,
                child: Semantics(
                  button: true,
                  label: M7TheftTraceLines.okLabel,
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: okKey,
                    behavior: HitTestBehavior.opaque,
                    onTap: onOk,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2E4A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SlmColors.gold300, width: 1.5),
                      ),
                      child: Center(child: Text(M7TheftTraceLines.okLabel, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
                    ),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<Offset?>(
              valueListenable: pinAt,
              builder: (_, at, _) {
                final c = at ?? M7TtSketch.pinHome;
                return Positioned(
                  left: c.dx - 10,
                  top: c.dy - 28,
                  width: 20,
                  height: 30,
                  child: const IgnorePointer(child: CustomPaint(painter: M7TtPinPainter())),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RulePainter extends CustomPainter {
  const _RulePainter();

  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = const Color(0x22305A9A)
      ..strokeWidth = 1;
    for (var y = 34.0; y < size.height; y += 18) {
      c.drawLine(Offset(6, y), Offset(size.width - 6, y), p);
    }
    c.drawLine(const Offset(30, 0), Offset(30, size.height), Paint()
      ..color = const Color(0x22B03030)
      ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_RulePainter old) => false;
}

/// The report: what was found, the two recipients to tick, and send.
class _ReportSheet extends StatelessWidget {
  const _ReportSheet({
    required this.found,
    required this.supervisor,
    required this.vigilance,
    required this.supKey,
    required this.vigKey,
    required this.sendKey,
    required this.onToggle,
    required this.onSend,
  });

  final List<M7TtTheft> found;
  final bool supervisor;
  final bool vigilance;
  final GlobalKey supKey;
  final GlobalKey vigKey;
  final GlobalKey sendKey;
  final ValueChanged<M7TtWho> onToggle;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final ink = bangla(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF2A2018));
    Widget chip(M7TtWho w, bool on, GlobalKey k) => Expanded(
          child: Semantics(
            button: true,
            toggled: on,
            label: M7TheftTraceLines.who(w),
            excludeSemantics: true,
            child: GestureDetector(
              key: k,
              behavior: HitTestBehavior.opaque,
              onTap: () => onToggle(w),
              child: Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: on ? const Color(0xFF2E5A3A) : const Color(0xFFF1EAD4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8A6A3C), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 18, color: on ? SlmColors.ivory : const Color(0xFF6A5A40)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(M7TheftTraceLines.who(w), style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: on ? SlmColors.ivory : const Color(0xFF2A2018))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(M7TheftTraceLines.reportTitle, textAlign: TextAlign.center, style: ink.copyWith(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF8A2A16))),
            const SizedBox(height: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final t in found) Text('• ${M7TheftTraceLines.found(t)}', style: ink),
                  ],
                ),
              ),
            ),
            Text(M7TheftTraceLines.reportTo, style: ink.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Row(children: [chip(M7TtWho.supervisor, supervisor, supKey), chip(M7TtWho.vigilance, vigilance, vigKey)]),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: M7TheftTraceLines.send,
              excludeSemantics: true,
              child: GestureDetector(
                key: sendKey,
                behavior: HitTestBehavior.opaque,
                onTap: onSend,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2E4A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SlmColors.gold300, width: 1.5),
                  ),
                  child: Center(child: Text(M7TheftTraceLines.send, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
