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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm6_upstream_trace_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_upstream_trace_world.dart' show M6UtDevKind, M6UtDevice, M6UtGeo, M6UtMap, M6UtPlates, M6UtRow, kM6UtWorldW, m6UtBuildMap, m6UtCamForWork;

// Lesson 6.8 "অটো-রিক্লোজার ও সেকশনালাইজার: লাইনের স্মার্ট ব্রেন", কাজ 2
// "তার ধরে সোর্সের দিকে" (pack do_6_8_b, engineType m6_upstream_trace) — the
// module's only finger-trace level. Two jobs, each on its own dealt panorama
// (m6_upstream_trace_world.dart): the work pole on a sub-line behind a cut-out
// fuse, the branch's sectionalizer, forks, the main line and our recloser (just
// outside the substation or at a junction pole — lesson point 1); the
// neighbour feeder runs alongside with its recloser nearest the work pole.
//
//  1. The docket (job + work pole only): a tap reads it.
//  2. Trace: the finger on the wire at the work pole, dragged along it; the
//     chalk follows only on the wire, forks are taken by the drag's direction,
//     a dead end stops the chalk (drag back along it), the camera follows. A
//     drag anywhere else pans the view. The trace is done at our source.
//  3. Flag: a tap on a device hangs the red Non-Reclose flag. Our recloser
//     (upstream, point 2: 'আপস্ট্রিম (অর্থাৎ, সোর্সের দিকের) রিক্লোজারটি
//     খোলে') → ◆ → reason. The sectionalizer, a fuse or the neighbour's
//     recloser = slip (the flag drops). Before the trace is done a tap only
//     brings the guide's 'trace first' (no cost, the same for every device).
//  4. PTT (hold): 'ফিডার-2, R-12: PTW দিন, Non-Reclose চালু করুন।' (point 3's
//     safety protocol). The control room's reply is dealt — full / no
//     Non-Reclose / another recloser / no PTW, all about the same length,
//     uncoloured; at least one job a play starts with an incomplete reply.
//  5. Climb (drag the boot onto the pole step) or ask again (PTT). Full +
//     climb → ◆ → reason; incomplete + ask again → ◆ → reason, then the full
//     reply; full + ask again = slip (a needless stop, R32).
//
// Deadly (module 6 table R3, as do_6_8_a; myth 1 reality): climbing after a
// reply that lacks the Non-Reclose confirmation, names another recloser, or
// gives no PTW. Slips: a flag on the sectionalizer (incl. listening to the
// coworker), on a fuse, on the neighbour's recloser; asking again after a full
// confirmation. Three slips strike out.
//
// The careless coworker (ruling X2/B1: his push is a slip act, so listening is
// a slip): once a play, in his dealt job, at the first of (the trace reaches
// the sectionalizer, any device tap): lesson myth 2 word for word + 'ওটাতেই
// ফ্ল্যাগ দাও, আর এগোনোর দরকার নেই।'. The drag past the sectionalizer and
// every flag wait for him (holdForCoworker).
//
// Gesture hands (how, never what): a tap on the docket (the one way on); a
// short drag nudge on the chalk head (≤ 60 dp, its direction alternating, the
// first one dealt per play); at a fork a sweep over every wire at the pole;
// for the flag a sweep over every device in view (fewer than two in view: a
// pan nudge on the sky); after the right flag a hold ring on PTT; at the
// decision a sweep over the boot and PTT. Decks have their own.

// ============================================================================
// Content
// ============================================================================

/// The control room's reply to the request.
enum M6UtReply { full, noNonReclose, wrongRecloser, noPermit }

/// What a reason asks about.
enum M6UtWhy { thisRecloser, notSectionalizer, wait, climb }

/// The docket's job (staging; the lesson names none).
enum M6UtJobKind { insulator, jumper }

/// What a PTT request did.
enum M6UtAsk { early, first, againRight, needless }

/// One step of the trace.
enum M6UtStep { none, moved, held, done }

/// The lesson point (0-based) for the fail panel.
const int kM6UtLessonPoint = 2;

abstract final class M6UpstreamTraceLines {
  static const title = 'তার ধরে সোর্সের দিকে';
  // DRAFT wording — owner (M6-12); the intro is the spec's.
  static const intro = 'শাখা লাইনে কাজ! আগে খুঁজুন কোন রিক্লোজার লাইন আবার চালু করতে পারে।';

  // The guide's task now (tap him: the same task, a different way).
  static const askDocket = 'ডকেটটা দেখুন — কোন পোলে কাজ, লেখা আছে।';
  static const askTrace = 'পোলের তারে আঙুল রেখে সোর্সের দিকে টেনে চলুন।';
  static const askFlag = 'এবার ঠিক যন্ত্রে Non-Reclose ফ্ল্যাগটা দিন।';
  static const askPtt = 'এবার PTT চেপে ধরে কন্ট্রোল রুমকে বলুন।';
  static const askDecide = 'কন্ট্রোলের উত্তর পড়ুন — এবার উঠবেন, না আবার বলবেন?';
  static const docketFirst = 'আগে ডকেটটা দেখুন।';
  static const traceFirst = 'আগে তার ধরে সোর্স পর্যন্ত যান।';
  static const flagFirst = 'আগে ঠিক করুন, কোন রিক্লোজারে Non-Reclose চাইবেন।';
  static const holdLonger = 'PTT চেপে ধরে রাখুন, তারপর ছাড়ুন।';
  static List<String> get tasks => [askDocket, askTrace, askFlag, askPtt, askDecide];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The docket, the radio and the scene (a worker's own words).
  static const docket = 'ডকেট';
  static String job(M6UtJobKind k) => switch (k) {
        M6UtJobKind.insulator => 'ইনসুলেটর বদল',
        M6UtJobKind.jumper => 'জাম্পার মেরামত',
      };
  static String pole(int n) => enDigits('পোল ${m6UtPolePlate(n)}');
  static const sceneLabel = 'লাইনের ছবি';
  static const pttLabel = 'PTT';
  static const bootLabel = 'বুট';
  static const you = 'আপনি';
  static const control = 'কন্ট্রোল';

  // The crew's isolation after a safe climb (ruling X1: shown, not scored,
  // not spoken). DRAFT wording — owner (M6-12).
  static const crewOpen = 'লাইন খোলা';
  static const crewDead = '0 V · ডেড';
  static const crewEarth = 'আর্থ';

  /// The request (the player's words on the radio; shown, not spoken).
  static String request(int feeder, int recloser) => enDigits('ফিডার-$feeder, ${m6UtPlate(recloser)}: PTW দিন, Non-Reclose চালু করুন।');

  /// The control room's reply (shown, not spoken; uncoloured; one length).
  static String reply(M6UtReply r, M6UtPlates p, int ptw) => enDigits(switch (r) {
        M6UtReply.full => 'ফিডার-${p.feeder}, ${m6UtPlate(p.recloser)}-এ Non-Reclose চালু করা হলো। PTW নং $ptw দিলাম, কাজ ধরুন।',
        M6UtReply.noNonReclose => 'ফিডার-${p.feeder}-এর PTW নং $ptw দিলাম। লাইন বন্ধ আছে, তাড়াতাড়ি কাজ ধরুন।',
        M6UtReply.wrongRecloser => 'ফিডার-${p.nbrFeeder}, ${m6UtPlate(p.nbrRecloser)}-এ Non-Reclose চালু করা হলো। PTW নং $ptw দিলাম, কাজ ধরুন।',
        M6UtReply.noPermit => 'ফিডার-${p.feeder}, ${m6UtPlate(p.recloser)}-এ Non-Reclose চালু করা হলো। PTW-র কাগজ এখনও তৈরি হয়নি।',
      });

  // The reasons: the right ones fit what was done (and what THIS reply
  // lacked); the wrong ones are in [wrongFor], one pool per question.
  static const whyQ = <M6UtWhy, String>{
    M6UtWhy.thisRecloser: 'কেন এই রিক্লোজারেই Non-Reclose চাইলেন?',
    M6UtWhy.notSectionalizer: 'সেকশনালাইজারে থামলেন না কেন?',
    M6UtWhy.wait: 'এখনই উঠলেন না কেন?',
    M6UtWhy.climb: 'এখন উঠতে পারেন কেন?',
  };
  static const whyFlag = <M6UtWhy, List<String>>{
    M6UtWhy.thisRecloser: ['আমার পোলের তার সোর্সের দিকে এখানেই আসে', 'আপস্ট্রিমের এই রিক্লোজারই লাইন চালু করে'],
    M6UtWhy.notSectionalizer: ['সেকশনালাইজার নিজে ফল্ট ধরতে পারে না', 'লাইন আবার চালু করে আপস্ট্রিম রিক্লোজার'],
  };
  static const whyWait = <M6UtReply, List<String>>{
    M6UtReply.noNonReclose: ['কন্ট্রোল Non-Reclose চালুর কথা বলেনি', 'Non-Reclose চালু হলো কি না, নিশ্চিত নয়'],
    M6UtReply.wrongRecloser: ['Non-Reclose চালু হয়েছে অন্য রিক্লোজারে', 'উত্তরে আমার রিক্লোজারের নামই ছিল না'],
    M6UtReply.noPermit: ['কন্ট্রোল বলল PTW এখনও তৈরি হয়নি', 'PTW না নিয়ে রিক্লোজার লাইনে কাজ নয়'],
  };
  static const whyClimb = ['ঠিক রিক্লোজারে Non-Reclose, PTW-ও হাতে', 'PTW, Non-Reclose, তারপর ডেড প্রমাণ ও আর্থ'];

  // The wrong cards: each question has its own pool of plausible but wrong
  // answers to THAT question (a careless worker's words), so the right card
  // never stands out by its topic. DRAFT wording — owner (M6-12).
  static const wrongFor = <M6UtWhy, List<String>>{
    M6UtWhy.thisRecloser: [
      'এটাই আমার পোলের সবচেয়ে কাছের যন্ত্র',
      'এই রিক্লোজারটাই দেখতে সবচেয়ে নতুন',
      'যেকোনো রিক্লোজারে চাইলেই কাজ হয়ে যায়',
      'সাবস্টেশনের কাছের যন্ত্রই সবসময় ঠিক',
      'কন্ট্রোল রুম এই নামটাই আগে বলেছিল',
    ],
    M6UtWhy.notSectionalizer: [
      'সেকশনালাইজারটা অনেক দূরে লাগানো ছিল',
      'সেকশনালাইজারে ফ্ল্যাগ দেওয়া যায় না',
      'সেকশনালাইজার পাশের ফিডারের যন্ত্র',
      'বড় যন্ত্রে ফ্ল্যাগ দিলে বেশি নিরাপদ',
      'সেকশনালাইজার এমনিতেই সবসময় খোলা থাকে',
    ],
    M6UtWhy.wait: [
      'রেডিওতে আওয়াজটা পরিষ্কার ছিল না',
      'কন্ট্রোলের গলাটা চেনা মনে হয়নি',
      'ওঠার আগে একটু জিরিয়ে নিতে চাই',
      'লাইনম্যানের কাজ ধীরে করাই ভালো',
      'বুটের ফিতেটা আগে ভালো করে বাঁধি',
    ],
    M6UtWhy.climb: [
      'লাইন ট্রিপ করে আছে, তাই ভয়ের কিছু নেই',
      'রিক্লোজার নিশ্চয়ই লক-আউট হয়ে গেছে',
      'তাড়াতাড়ি সারলে চালু হওয়ার আগেই নামব',
      'কন্ট্রোল লাইন বন্ধ বলেছে, ওতেই হবে',
      'কাছের রিক্লোজারে Non-Reclose হলেই চলে',
    ],
  };
  static List<String> get allWhyWrong => [for (final l in wrongFor.values) ...l];
  static List<String> get allWhyRight => [
        for (final l in whyFlag.values) ...l,
        for (final l in whyWait.values) ...l,
        ...whyClimb,
      ];

  // The careless coworker: lesson myth 2 word for word + his shortcut.
  // DRAFT wording — owner (M6-12): the shortcut is the spec's.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'সেকশনালাইজার একটি ফিউজের মতোই কাজ করে। ওটাতেই ফ্ল্যাগ দাও, আর এগোনোর দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, সেকশনালাইজার ফিউজের মতো নয়', 'না, তার ধরে রিক্লোজার পর্যন্ত যাব', 'না, Non-Reclose চাই রিক্লোজারেই'],
    wrong: [
      'ঠিক, সেকশনালাইজারেই ফ্ল্যাগ দিই',
      'আচ্ছা, আর এগোনোর দরকার নেই',
      'হ্যাঁ, ফিউজের মতোই তো কাজ করে',
      'ঠিক আছে, এখানেই থামি তাহলে',
      'হ্যাঁ, এতেই লাইন নিরাপদ হবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে সেকশনালাইজারেই ফ্ল্যাগ দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! সেকশনালাইজার নিজে ফল্ট ধরে না — তার ধরে রিক্লোজার পর্যন্ত চলুন।';

  static const allSet = 'দুই কাজেই ঠিক রিক্লোজারে Non-Reclose আর PTW — নিরাপদ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — তার ধরে রিক্লোজার, তারপর পুরো নিশ্চিত হয়ে তবে ওঠা।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtTrace = 'তার ধরে সোর্স পর্যন্ত গেছেন';
  static const caughtFlag = 'ঠিক রিক্লোজারে Non-Reclose চেয়েছেন';
  static const caughtWait = 'অসম্পূর্ণ উত্তরে ওঠেননি';
  static const caughtClimb = 'PTW আর Non-Reclose নিশ্চিত করে উঠেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new line (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  /// The radio lines are shown, never spoken.
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        docketFirst,
        traceFirst,
        flagFirst,
        holdLonger,
        ...whyQ.values,
        ...coworker.asks.where((a) => !_oldAsks.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M6UpstreamTraceMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M6UpstreamTraceMistakes {
  static const _dir = 'assets/game/art/m6_upstream_trace';

  // DRAFT wording — owner (M6-12).
  static const flagSectionalizer = DoMistake(
    key: '6.8/m6_upstream_trace/flag-sectionalizer',
    textBn: 'সেকশনালাইজারের নিজের ফল্ট সনাক্ত করার ক্ষমতা নেই — এটি শুধু ডেড লাইনে খোলে। লাইন আবার চালু করে আপস্ট্রিম রিক্লোজার; Non-Reclose চাই তাতেই।',
    art: '$_dir/flag_sectionalizer.svg',
    lessonPoint: 1,
  );
  static const flagFuse = DoMistake(
    key: '6.8/m6_upstream_trace/flag-fuse',
    textBn: 'ফিউজ ফল্টে গলে যায়, লাইন আবার চালু করে না। আবার চালু করতে পারে আপস্ট্রিম রিক্লোজার — Non-Reclose চাই সেই রিক্লোজারেই।',
    art: '$_dir/flag_fuse.svg',
    lessonPoint: 2,
  );
  static const flagNeighbour = DoMistake(
    key: '6.8/m6_upstream_trace/flag-neighbour',
    textBn: 'এই রিক্লোজার পাশের ফিডারের — আপনার পোলের তার এখানে আসেনি। কাছে আছে বলে নয়; তার ধরে যে রিক্লোজারে পৌঁছান, Non-Reclose তাতেই।',
    art: '$_dir/flag_neighbour.svg',
    lessonPoint: 1,
  );
  static const askAgain = DoMistake(
    key: '6.8/m6_upstream_trace/ask-again',
    textBn: 'কন্ট্রোল পুরো নিশ্চিত করেছে — ঠিক রিক্লোজারে Non-Reclose চালু, PTW দেওয়া। আবার জিজ্ঞেস করে অকারণে কাজ থামাবেন না।',
    art: '$_dir/ask_again.svg',
    lessonPoint: 2,
  );
  static const climbNoNonReclose = DoMistake(
    key: '6.8/m6_upstream_trace/climb-no-nonreclose',
    textBn: 'কন্ট্রোল Non-Reclose চালুর কথা বলেনি! রিক্লোজার কোনো সতর্কবার্তা ছাড়াই লাইন আবার চালু করে দিতে পারে। নিশ্চিত না হলে পোলে নয় — আবার জিজ্ঞেস করুন।',
    art: '$_dir/climb_no_nonreclose.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const climbWrongRecloser = DoMistake(
    key: '6.8/m6_upstream_trace/climb-wrong-recloser',
    textBn: 'কন্ট্রোল Non-Reclose দিয়েছে অন্য রিক্লোজারে — আপনার লাইনের রিক্লোজার এখনও লাইন আবার চালু করতে পারে! ফিডার আর রিক্লোজারের নাম মিলিয়ে তবেই ওঠা।',
    art: '$_dir/climb_wrong_recloser.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const climbNoPermit = DoMistake(
    key: '6.8/m6_upstream_trace/climb-no-ptw',
    textBn: 'PTW হাতে আসেনি! PTW না নিয়ে কোনো রিক্লোজারযুক্ত লাইনকে নিরাপদ ভাবা যাবে না। PTW আর Non-Reclose দুটোই নিশ্চিত করে তবেই ওঠা।',
    art: '$_dir/climb_no_ptw.svg',
    deadly: true,
    lessonPoint: 2,
  );

  /// Listening to him is the act he pushes (X2/B1): a flag on the
  /// sectionalizer, a slip.
  static const push = flagSectionalizer;

  /// A flag on a device that is not our recloser.
  static DoMistake? flag(M6UtDevKind k) => switch (k) {
        M6UtDevKind.recloser => null,
        M6UtDevKind.sectionalizer => flagSectionalizer,
        M6UtDevKind.fuse => flagFuse,
        M6UtDevKind.nbrRecloser => flagNeighbour,
      };

  /// Climbing on a reply (null: the full reply, safe).
  static DoMistake? climb(M6UtReply r) => switch (r) {
        M6UtReply.full => null,
        M6UtReply.noNonReclose => climbNoNonReclose,
        M6UtReply.wrongRecloser => climbWrongRecloser,
        M6UtReply.noPermit => climbNoPermit,
      };

  static const List<DoMistake> all = [
    flagSectionalizer,
    flagFuse,
    flagNeighbour,
    askAgain,
    climbNoNonReclose,
    climbWrongRecloser,
    climbNoPermit,
  ];
}

/// One job: its panorama, plates, docket and dealt reply.
@immutable
class M6UtJob {
  const M6UtJob({required this.map, required this.plates, required this.kind, required this.firstReply, required this.flagWhy, required this.ptw});

  final M6UtMap map;
  final M6UtPlates plates;
  final M6UtJobKind kind;

  /// The control room's first reply (a second ask is always answered full).
  final M6UtReply firstReply;

  /// What the right flag's reason asks.
  final M6UtWhy flagWhy;
  final int ptw;
}

@immutable
class M6UtDeal {
  const M6UtDeal({required this.jobs, required this.coworkerJob, required this.nudgeSign});

  /// The two jobs in order.
  final List<M6UtJob> jobs;

  /// The job the coworker comes in at.
  final int coworkerJob;

  /// The first trace nudge's direction (+1 / −1); it alternates after.
  final double nudgeSign;
}

/// The number of jobs a play.
const kM6UtJobs = 2;

M6UtDeal m6UtDeal(math.Random rng) {
  // Replies: at least one job a play starts with an incomplete one.
  final replies = [for (var i = 0; i < kM6UtJobs; i++) M6UtReply.values[rng.nextInt(M6UtReply.values.length)]];
  if (replies.every((r) => r == M6UtReply.full)) {
    replies[rng.nextInt(kM6UtJobs)] = M6UtReply.values[1 + rng.nextInt(3)];
  }
  final feeders = [for (var i = 1; i <= 9; i++) i]..shuffle(rng);
  final reclosers = [for (var i = 1; i <= 40; i++) i]..shuffle(rng);
  final poles = [for (var i = 11; i <= 89; i++) i]..shuffle(rng);
  final kinds = [...M6UtJobKind.values]..shuffle(rng);
  final mirror0 = rng.nextBool();
  final jobs = <M6UtJob>[
    for (var i = 0; i < kM6UtJobs; i++)
      M6UtJob(
        // The second panorama is the first's mirror side: the two jobs differ.
        map: m6UtBuildMap(
          mirrored: i == 0 ? mirror0 : !mirror0,
          nbrAbove: rng.nextBool(),
          rNearSource: rng.nextBool(),
          junctionAt: 2 + rng.nextInt(2),
          decoySpur: rng.nextInt(4) != 0,
          decoyFuse: rng.nextBool(),
          workFar: rng.nextBool(),
        ),
        plates: M6UtPlates(
          feeder: feeders[2 * i],
          recloser: reclosers[2 * i],
          nbrFeeder: feeders[2 * i + 1],
          nbrRecloser: reclosers[2 * i + 1],
          pole: poles[i],
        ),
        kind: kinds[i % kinds.length],
        firstReply: replies[i],
        flagWhy: rng.nextBool() ? M6UtWhy.thisRecloser : M6UtWhy.notSectionalizer,
        ptw: 100 + rng.nextInt(900),
      ),
  ];
  return M6UtDeal(jobs: jobs, coworkerJob: rng.nextInt(kM6UtJobs), nudgeSign: rng.nextBool() ? 1 : -1);
}

/// How near the wire the finger must stay for the chalk to follow (design px).
const double kM6UtWireTol = 26;

/// How near the chalk head a drag must start to trace (else it pans).
const double kM6UtGrab = 40;

/// The play state (pure logic; the trace takes the scene's geometry).
class M6UtRun {
  M6UtRun(this.deal) {
    _startJob();
  }
  final M6UtDeal deal;

  int index = 0;
  int slips = 0;
  int jobSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  var docketRead = false;

  /// The chalk: the poles passed from the work pole, the span it is on (to
  /// [edgeTo], [f] of the way) — null at a pole.
  List<int> path = [];
  int? edgeTo;
  double f = 0;

  /// The trace reached our source; it passed the sectionalizer.
  var traced = false;
  var sawS = false;

  /// The chalk may not leave this pole forward (the page sets it while the
  /// coworker is due at the sectionalizer).
  int? holdAt;

  /// The right flag is up.
  var flagged = false;

  /// The control room's reply now (null: not asked yet); the incomplete
  /// reply the player rightly asked again on.
  M6UtReply? reply;
  M6UtReply? waitedOn;

  /// Up the pole on the full reply (the job's last move).
  var climbed = false;

  M6UtJob get job => deal.jobs[index.clamp(0, kM6UtJobs - 1)];
  M6UtMap get map => job.map;
  bool get done => index >= kM6UtJobs;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => jobSlips == 0;
  bool get _open => !ended && !climbed;
  bool get canTrace => _open && docketRead && !traced;
  bool get canFlag => _open && docketRead && traced && !flagged;

  void _startJob() {
    docketRead = false;
    path = [map.work];
    edgeTo = null;
    f = 0;
    traced = false;
    sawS = false;
    holdAt = null;
    flagged = false;
    reply = null;
    waitedOn = null;
    climbed = false;
    jobSlips = 0;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    jobSlips++;
    return m;
  }

  void readDocket() {
    if (_open) docketRead = true;
  }

  /// The chalk head (world px).
  Offset head(M6UtGeo g) {
    final a = g.node(map, path.last);
    final to = edgeTo;
    return to == null ? a : M6UtGeo.span(a, g.node(map, to), f);
  }

  /// The chalk's points from the work pole to the head (world px).
  List<Offset> chalk(M6UtGeo g) {
    final pts = <Offset>[g.node(map, path.first)];
    void spanTo(Offset a, Offset b, double upTo) {
      for (var k = 1; k <= 8; k++) {
        final t = upTo * k / 8;
        pts.add(M6UtGeo.span(a, b, t));
      }
    }

    for (var i = 1; i < path.length; i++) {
      spanTo(g.node(map, path[i - 1]), g.node(map, path[i]), 1);
    }
    final to = edgeTo;
    if (to != null && f > 0) spanTo(g.node(map, path.last), g.node(map, to), f);
    return pts;
  }

  /// [p]'s place along the span [a]→[b] (0…1) and its distance from the wire.
  static (double, double) _project(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final t = len2 == 0 ? 0.0 : (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2).clamp(0.0, 1.0);
    return (t, (p - M6UtGeo.span(a, b, t)).distance);
  }

  /// The finger at [p] (world px) while it traces: the chalk follows it along
  /// the wire it is on (only on the wire; back along the chalk it rubs out);
  /// at a pole it takes the wire the finger goes along.
  M6UtStep trace(Offset p, M6UtGeo g) {
    if (!canTrace) return M6UtStep.none;
    final m = map;
    var step = M6UtStep.none;
    for (var guard = 0; guard < 6; guard++) {
      final n = path.last;
      final a = g.node(m, n);
      final to = edgeTo;
      if (to == null) {
        final prev = path.length > 1 ? path[path.length - 2] : null;
        int? best;
        var bestD = kM6UtWireTol;
        var bestT = 0.0;
        for (final c in m.neighbours(n)) {
          final (t, d) = _project(p, a, g.node(m, c));
          if (t < 0.04 || d >= bestD) continue;
          best = c;
          bestD = d;
          bestT = t;
        }
        if (best == null) return step;
        if (best == prev) {
          // Back along the chalk: it rubs out.
          path.removeLast();
          edgeTo = n;
          f = 1 - bestT;
        } else {
          if (holdAt == n) return M6UtStep.held;
          edgeTo = best;
          f = bestT;
        }
        step = M6UtStep.moved;
        if (f < 0.97 && f > 0.03) return step;
        continue;
      }
      final (t, d) = _project(p, a, g.node(m, to));
      if (d >= kM6UtWireTol) return step;
      if ((t - f).abs() > 1e-9) {
        f = t;
        step = M6UtStep.moved;
      }
      if (f >= 0.97) {
        path.add(to);
        edgeTo = null;
        f = 0;
        if (to == m.sNode) sawS = true;
        if (to == m.source) {
          traced = true;
          _tag(M6UpstreamTraceLines.caughtTrace);
          return M6UtStep.done;
        }
        continue;
      }
      if (f <= 0.03) {
        edgeTo = null;
        f = 0;
        continue;
      }
      return step;
    }
    return step;
  }

  /// At a pole with more than one wire on (a fork): the wires there.
  List<int> forkWires() {
    if (edgeTo != null) return const [];
    final n = path.last;
    final prev = path.length > 1 ? path[path.length - 2] : null;
    final all = map.neighbours(n);
    final onward = all.where((c) => c != prev).length;
    return onward >= 2 ? all : const [];
  }

  /// A flag on [d] (the trace done, the flag not yet up): our recloser is
  /// right; anything else a slip (the flag drops).
  DoMistake? flag(M6UtDevice d) {
    if (!canFlag) return null;
    final m = M6UpstreamTraceMistakes.flag(d.kind);
    if (m != null) return _slip(m);
    flagged = true;
    _tag(M6UpstreamTraceLines.caughtFlag);
    return null;
  }

  /// The PTT request.
  M6UtAsk ask() {
    if (!_open || !flagged) return M6UtAsk.early;
    final r = reply;
    if (r == null) {
      reply = job.firstReply;
      return M6UtAsk.first;
    }
    if (r == M6UtReply.full) {
      _slip(M6UpstreamTraceMistakes.askAgain);
      return M6UtAsk.needless;
    }
    waitedOn = r;
    reply = M6UtReply.full;
    _tag(M6UpstreamTraceLines.caughtWait);
    return M6UtAsk.againRight;
  }

  /// The boot on the step: up the pole on the reply standing now.
  DoMistake? climb() {
    final r = reply;
    if (!_open || r == null) return null;
    final m = M6UpstreamTraceMistakes.climb(r);
    if (m != null) return deadly = m;
    climbed = true;
    _tag(M6UpstreamTraceLines.caughtClimb);
    return null;
  }

  /// Listened to him (a slip).
  DoMistake pushSlip() => _slip(M6UpstreamTraceMistakes.push);

  void next() {
    index++;
    if (!done) _startJob();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action, per job: docket 1500, the trace (10–12 spans
/// ≈ 12000), the flag + a reason (≈ 9500), PTT + reading the reply (≈ 5000),
/// on half the jobs ask again + a reason (≈ 9500), the boot + a reason
/// (≈ 9500) ≈ 37500–47000; two jobs + the coworker once (≈ 9600)
/// ≈ 94600 … 103600; 85 % ≈ 85000 → 90 s (a builder's estimate).
const m6UpstreamTraceQuickMs = 90000;

@immutable
class M6UpstreamTracePack {
  const M6UpstreamTracePack({required this.id, required this.titleBn, this.quickMs = m6UpstreamTraceQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6UpstreamTracePack> m6UpstreamTracePacks = {
  'do_6_8_b': M6UpstreamTracePack(id: 'do_6_8_b', titleBn: M6UpstreamTraceLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M6UpstreamTraceProbe {
  static M6UtRun? run;
  static ValueListenable<double>? cam;
  static M6UtGeo? geo;
}

// ============================================================================
// Page
// ============================================================================

class M6UpstreamTracePage extends StatefulWidget {
  const M6UpstreamTracePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6UpstreamTracePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6UpstreamTracePage> createState() => _M6UpstreamTracePageState();
}

class _M6UpstreamTracePageState extends State<M6UpstreamTracePage> {
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
  final M6UpstreamTracePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TraceRunPage> createState() => _TraceRunPageState();
}

/// What the reason being paid was for.
enum _After { flag, wait, climb }

/// What a drag on the scene is doing.
enum _Drag { none, trace, pan, boot }

class _TraceRunPageState extends ConsumerState<_TraceRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6UtRun _run;
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
  int _wake = 0;

  /// The camera (world x at the screen's left edge) and its glide.
  final _cam = ValueNotifier<double>(0);
  late final AnimationController _glide = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
    ..addListener(_onGlide);
  double _glideFrom = 0;
  double _glideTo = 0;

  /// The chalk repaints on this (no page rebuild while tracing).
  final _chalkTick = ValueNotifier<int>(0);

  _Drag _drag = _Drag.none;

  /// The boot while it is dragged (world px; null at home).
  final _boot = ValueNotifier<Offset?>(null);

  /// The PTT hold ring.
  late final AnimationController _ptt = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..addStatusListener(_onPttStatus);
  var _pttDown = false;

  /// The radio log: the request shown, the reply shown (hidden while the
  /// reason for asking again is open).
  String? _requestBn;
  var _replyShown = false;

  /// A dropped flag (a wrong one) and its count (keys its fall).
  Offset? _dropAt;
  int _dropN = 0;

  _After? _after;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _pttKey = GlobalKey();
  final _bootKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M6UtGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6UtRun(m6UtDeal(widget.rng));
    _cam.value = m6UtCamForWork(_run.map);
    M6UpstreamTraceProbe.run = _run;
    M6UpstreamTraceProbe.cam = _cam;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _glide.dispose();
    _ptt.dispose();
    _cam.dispose();
    _chalkTick.dispose();
    _boot.dispose();
    if (identical(M6UpstreamTraceProbe.run, _run)) {
      M6UpstreamTraceProbe.run = null;
      M6UpstreamTraceProbe.cam = null;
      M6UpstreamTraceProbe.geo = null;
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

  M6UtJob get _job => _run.job;
  M6UtMap get _map => _run.map;
  bool get _hisJob => _run.index == _run.deal.coworkerJob;

  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.climbed && !_freeze;

  /// The decision is up: a reply in, shown, the boot not used yet.
  bool get _deciding => _run.reply != null && _replyShown && !_run.climbed;

  String get _task => !_run.docketRead
      ? M6UpstreamTraceLines.askDocket
      : !_run.traced
          ? M6UpstreamTraceLines.askTrace
          : !_run.flagged
              ? M6UpstreamTraceLines.askFlag
              : _run.reply == null
                  ? M6UpstreamTraceLines.askPtt
                  : M6UpstreamTraceLines.askDecide;

  // --- the camera -----------------------------------------------------------------
  void _onGlide() {
    final v = Curves.easeInOut.transform(_glide.value);
    _cam.value = _glideFrom + (_glideTo - _glideFrom) * v;
  }

  void _glideCam(double x) {
    final to = x.clamp(0.0, M6UtGeo.camMax);
    _glide.stop();
    if (_quiet) {
      _cam.value = to;
      return;
    }
    _glideFrom = _cam.value;
    _glideTo = to;
    unawaited(_glide.forward(from: 0));
  }

  void _setCam(double x) {
    _glide.stop();
    _cam.value = x.clamp(0.0, M6UtGeo.camMax);
  }

  // --- the flow -------------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    _startJob();
  }

  void _startJob() {
    _setCam(m6UtCamForWork(_map));
    setState(() {
      _wake++;
      _requestBn = null;
      _replyShown = false;
      _dropAt = null;
      _drag = _Drag.none;
      _boot.value = null;
    });
    _chalkTick.value++;
    unawaited(_sayChain([_task]));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  void _readDocket() {
    if (_run.docketRead) {
      _tick();
      unawaited(_sayChain([_task]));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    _run.readDocket();
    if (_hisJob && !coworkerDone && !coworkerDue) scheduleCoworker();
    _stepDone();
    unawaited(_sayChain([_task]));
  }

  void _needDocket() {
    _tick();
    unawaited(_sayChain([M6UpstreamTraceLines.docketFirst]));
  }

  /// While he is due in this job, the chalk may not leave the sectionalizer.
  void _syncHold() => _run.holdAt = _hisJob && coworkerDue ? _map.sNode : null;

  // --- hands on -----------------------------------------------------------------
  void _tapScene(Offset p, Offset global) {
    if (!_canPlay) return;
    final geo = _geoNow;
    if (geo == null) return;
    if (M6UtGeo.docket.contains(p)) {
      _readDocket();
      return;
    }
    final w = p + Offset(_cam.value, 0);
    for (final d in _map.devices) {
      if (geo.deviceRect(_map, d).contains(w)) {
        _tapDevice(d, global);
        return;
      }
    }
    _hints.missTap();
  }

  void _tapDevice(M6UtDevice d, Offset global) {
    if (!_run.docketRead) {
      _needDocket();
      return;
    }
    // Any device tap brings him (the first of: the sectionalizer, a tap).
    if (_hisJob && holdForCoworker()) return;
    if (!_run.traced) {
      _tick();
      unawaited(_sayChain([M6UpstreamTraceLines.traceFirst]));
      return;
    }
    if (_run.flagged) {
      _tick();
      unawaited(_sayChain([_task]));
      return;
    }
    final m = _run.flag(d);
    if (m != null) {
      _dropFlag(d);
      unawaited(_mistake(m, global));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _stepDone();
    _hush();
    putOnTable(15);
    _after = _After.flag;
    final idx = _run.index;
    final why = _job.flagWhy;
    unawaited(askReason(
      deal: () => dealChoices(M6UpstreamTraceLines.whyFlag[why]!, M6UpstreamTraceLines.wrongFor[why]!, widget.rng),
      question: M6UpstreamTraceLines.whyQ[why]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _dropFlag(M6UtDevice d) {
    final geo = _geoNow;
    if (geo == null) return;
    setState(() {
      _dropAt = geo.flagAt(_map, d);
      _dropN++;
    });
  }

  void _panStart(Offset p) {
    _drag = _Drag.none;
    if (!_canPlay) return;
    final geo = _geoNow;
    if (geo == null) return;
    final w = p + Offset(_cam.value, 0);
    if (_deciding && M6UtGeo.bootRect(geo.bootHome(_map)).contains(w)) {
      _drag = _Drag.boot;
      _boot.value = w;
      setState(() => _wake++);
      return;
    }
    if (!_run.traced && (w - _run.head(geo)).distance <= kM6UtGrab) {
      if (!_run.docketRead) {
        _needDocket();
        return;
      }
      _drag = _Drag.trace;
      return;
    }
    _drag = _Drag.pan;
  }

  void _panUpdate(Offset p, Offset delta) {
    if (_drag == _Drag.none) return;
    if (!_canPlay) {
      _drag = _Drag.none;
      _boot.value = null;
      return;
    }
    final geo = _geoNow;
    if (geo == null) return;
    switch (_drag) {
      case _Drag.pan:
        _setCam(_cam.value - delta.dx);
      case _Drag.boot:
        _boot.value = p + Offset(_cam.value, 0);
      case _Drag.trace:
        _syncHold();
        final step = _run.trace(p + Offset(_cam.value, 0), geo);
        if (step == M6UtStep.held) {
          holdForCoworker();
          _drag = _Drag.none;
          return;
        }
        if (step == M6UtStep.none) return;
        _chalkTick.value++;
        _follow(geo);
        if (step == M6UtStep.done) {
          _drag = _Drag.none;
          _traced();
        }
      case _Drag.none:
        break;
    }
  }

  /// The camera keeps the chalk head in view while tracing.
  void _follow(M6UtGeo geo) {
    final x = _run.head(geo).dx - _cam.value;
    const lo = 90.0, hi = 270.0;
    if (x > hi) _setCam(_cam.value + math.min(14.0, x - hi));
    if (x < lo) _setCam(_cam.value - math.min(14.0, lo - x));
  }

  void _panEnd() {
    final d = _drag;
    _drag = _Drag.none;
    switch (d) {
      case _Drag.boot:
        final at = _boot.value;
        final geo = _geoNow;
        _boot.value = null;
        if (at != null && geo != null && _canPlay && (at - geo.step(_map)).distance <= M6UtGeo.stepReach) {
          _climb();
          return;
        }
        _hints.missTap();
        setState(() => _wake++);
      case _Drag.trace:
        _stepDone();
      case _Drag.pan:
      case _Drag.none:
        break;
    }
  }

  void _traced() {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    _stepDone();
    unawaited(_sayChain([M6UpstreamTraceLines.askFlag]));
  }

  // --- the radio ----------------------------------------------------------------
  void _pttPress() {
    if (!_canPlay || _pttDown) return;
    // The reply is on its way.
    if (_requestBn != null && _run.reply != null && !_replyShown) return;
    if (!_run.flagged) {
      _tick();
      unawaited(_sayChain([M6UpstreamTraceLines.flagFirst]));
      return;
    }
    _pttDown = true;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    unawaited(_ptt.forward(from: 0));
    setState(() {});
  }

  void _pttRelease() {
    if (!_pttDown) return;
    _pttDown = false;
    if (_ptt.status != AnimationStatus.completed) {
      _ptt.reset();
      _tick();
      unawaited(_sayChain([M6UpstreamTraceLines.holdLonger]));
    } else {
      _ptt.reset();
    }
    setState(() {});
  }

  void _onPttStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && _pttDown) _request();
  }

  void _request() {
    if (!_canPlay) return;
    final p = _job.plates;
    final r = _run.ask();
    if (r == M6UtAsk.early) return;
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    setState(() {
      _requestBn = M6UpstreamTraceLines.request(p.feeder, p.recloser);
      _wake++;
    });
    switch (r) {
      case M6UtAsk.first:
        setState(() => _replyShown = false);
        unawaited(_showReply());
      case M6UtAsk.againRight:
        _stepDone();
        _hush();
        setState(() => _replyShown = false);
        putOnTable(15);
        _after = _After.wait;
        final idx = _run.index;
        final on = _run.waitedOn!;
        unawaited(askReason(
          deal: () => dealChoices(M6UpstreamTraceLines.whyWait[on]!, M6UpstreamTraceLines.wrongFor[M6UtWhy.wait]!, widget.rng),
          question: M6UpstreamTraceLines.whyQ[M6UtWhy.wait]!,
          stillValid: () => _run.index == idx && !_ended,
        ));
      case M6UtAsk.needless:
        final size = MediaQuery.sizeOf(context);
        unawaited(_mistake(M6UpstreamTraceMistakes.askAgain, Offset(60, size.height - 80)));
      case M6UtAsk.early:
        break;
    }
  }

  /// The reply comes over the radio after a moment; the camera goes back to
  /// the work pole for the decision.
  Future<void> _showReply() async {
    final idx = _run.index;
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 800));
    if (!mounted || _ended || _run.index != idx) return;
    _cue('sounds/intro/click.ogg', volume: 0.5);
    _glideCam(m6UtCamForWork(_map));
    setState(() {
      _replyShown = true;
      _wake++;
    });
    _steps++;
    unawaited(_sayChain([M6UpstreamTraceLines.askDecide]));
  }

  // --- the climb ----------------------------------------------------------------
  void _climb() {
    final m = _run.climb();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, Offset.zero));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _stepDone();
    _hush();
    putOnTable(15 + (_run.thorough ? 5 : 0));
    _after = _After.climb;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M6UpstreamTraceLines.whyClimb, M6UpstreamTraceLines.wrongFor[M6UtWhy.climb]!, widget.rng),
      question: M6UpstreamTraceLines.whyQ[M6UtWhy.climb]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startJob();
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
    final after = _after;
    _after = null;
    switch (after) {
      case _After.flag:
        _stepDone();
        unawaited(_sayChain([M6UpstreamTraceLines.askPtt]));
      case _After.wait:
        unawaited(_showReply());
      case _After.climb:
        unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
          if (mounted && !_ended && _run.index == idx) _next();
        }));
      case null:
        break;
    }
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6UpstreamTraceLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !_hisJob || _run.flagged) return null;
    if (_intro || _card != null || tableBusy || _freeze || _pttDown || !_run.docketRead) return false;
    return _run.sawS;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    _run.holdAt = null;
    _drag = _Drag.none;
    if (!held) {
      final m = _run.pushSlip();
      final s = _map.deviceAt(_map.sNode);
      if (s != null) _dropFlag(s);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6UpstreamTraceLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6UpstreamTraceLines.callHeld], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6UpstreamTraceLines.tapWhy[_nudgeN++ % M6UpstreamTraceLines.tapWhy.length]
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6trace/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up the pole on an incomplete reply: the scene freezes grey and the line
  /// comes back at the pole top in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    _setCam(m6UtCamForWork(_map));
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
    final speak = await SpokenOnce.first('m6trace/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6UpstreamTraceLines.deadlyWord : M6UpstreamTraceLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same job goes on from where it was.
        _hush();
        setState(() {
          _card = null;
          _dropAt = null;
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
    await _say(!_run.passed ? M6UpstreamTraceLines.fail : (_quickBonus ? M6UpstreamTraceLines.quick : M6UpstreamTraceLines.allSet),
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
    if (_passed) return LinemanMode.cheer;
    if (_pttDown || _requestBn != null && !_replyShown) return LinemanMode.talk;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what (see the header).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    final cam = _cam.value;
    Offset screen(Offset w) => w - Offset(cam, 0);
    bool inView(Offset w) {
      final x = w.dx - cam;
      return x > 24 && x < kM6UtViewW - 24;
    }

    HintSpec panNudge() => HintSpec.drag(Offset(180, geo.height * 0.2), toward: Offset(n.isEven ? 1 : -1, 0), travel: 50, space: HintSpace.scene);

    if (!_run.docketRead) return HintSpec.tap(M6UtGeo.docket.center, space: HintSpace.scene);
    if (!_run.traced) {
      final head = _run.head(geo);
      if (!inView(head)) return panNudge();
      final fork = _run.forkWires();
      if (fork.length >= 2 && n.isOdd) {
        final a = geo.node(_map, _run.path.last);
        return HintSpec.sweep([
          for (final c in fork)
            Rect.fromCenter(center: screen(M6UtGeo.span(a, geo.node(_map, c), math.min(0.5, 38 / (geo.node(_map, c) - a).distance))), width: 34, height: 34),
        ], space: HintSpace.scene);
      }
      final sign = _run.deal.nudgeSign * ((n ~/ 2).isEven ? 1 : -1);
      return HintSpec.drag(screen(head), toward: Offset(sign, 0), travel: 44, space: HintSpace.scene);
    }
    if (!_run.flagged) {
      final rects = [
        for (final d in _map.devices)
          if (inView(geo.deviceRect(_map, d).center)) geo.deviceRect(_map, d).shift(Offset(-cam, 0)),
      ];
      return rects.length >= 2 ? HintSpec.sweep(rects, space: HintSpace.scene) : panNudge();
    }
    if (_run.reply == null) return HintSpec.holdOn(_pttKey);
    if (!inView(geo.bootHome(_map))) return panNudge();
    return HintSpec.sweepOver([_bootKey, _pttKey]);
  }

  /// Ruling X1: on a safe climb the crew's isolation shows at the work
  /// section — the sub-line opened, the tester at 0 V (ডেড), earths on both
  /// sides. Art only: no scoring, no new spoken line.
  List<Widget> _crew(M6UtGeo geo, M6UtMap map, bool quiet) {
    final sp = geo.crew(map);
    Widget tag(String text, Offset at, double delay) => Positioned(
          left: at.dx - 40,
          top: at.dy,
          width: 80,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, child) => Opacity(opacity: ((v * 3) - delay).clamp(0.0, 1.0), child: child),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xE6FFFFFF), borderRadius: BorderRadius.circular(6)),
                  child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1F3A1F))),
                ),
              ),
            ),
          ),
        );
    return [
      Positioned.fill(
        key: ValueKey('crew-${_run.index}'),
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 1500),
            builder: (_, v, _) => CustomPaint(painter: M6UtCrewPainter(spots: sp, groundY: geo.groundY, v: v)),
          ),
        ),
      ),
      tag(M6UpstreamTraceLines.crewOpen, sp.isolate + const Offset(0, -34), 0),
      tag(M6UpstreamTraceLines.crewDead, sp.testerWindow + const Offset(0, 12), 1),
      tag(M6UpstreamTraceLines.crewEarth, Offset(sp.earthBFoot.dx, sp.earthBFoot.dy - 30), 2),
    ];
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6UpstreamTraceProbe.geo = M6UtGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final j = _job;
    final map = _map;
    final r = _run;
    final trainee = geo.trainee(map);
    final up = r.climbed || r.deadly != null;
    final flagDev = r.flagged ? map.deviceAt(map.rNode) : null;
    final home = geo.bootHome(map);
    final world = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          key: ValueKey('world-${r.index}'),
          child: RepaintBoundary(child: CustomPaint(painter: M6UtWorldPainter(geo: geo, map: map, plates: j.plates))),
        ),
        Positioned.fill(
          key: const ValueKey('chalk'),
          child: RepaintBoundary(
            child: CustomPaint(painter: M6UtChalkPainter(points: () => _run.chalk(geo), repaint: _chalkTick)),
          ),
        ),
        if (flagDev != null)
          Positioned(
            key: ValueKey('flag-${r.index}'),
            left: geo.flagAt(map, flagDev).dx,
            top: geo.flagAt(map, flagDev).dy,
            width: 22,
            height: 34,
            child: const IgnorePointer(child: CustomPaint(painter: M6UtFlagPainter())),
          ),
        if (_dropAt != null)
          Positioned(
            key: ValueKey('drop-$_dropN'),
            left: _dropAt!.dx,
            top: _dropAt!.dy,
            width: 22,
            height: 34,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 900),
                builder: (_, v, child) => Opacity(
                  opacity: (1 - v * 0.85).clamp(0.0, 1.0),
                  child: Transform.translate(offset: Offset(6 * v, (geo.groundY - _dropAt!.dy - 30) * v * v), child: Transform.rotate(angle: 1.2 * v, child: child)),
                ),
                child: const CustomPaint(painter: M6UtFlagPainter()),
              ),
            ),
          ),
        if (r.climbed && r.deadly == null) ..._crew(geo, map, quiet),
        AnimatedPositioned(
          key: const ValueKey('trainee'),
          duration: Duration(milliseconds: quiet ? 0 : 700),
          curve: Curves.easeOut,
          left: up ? geo.node(map, map.work).dx - 22 : trainee.left,
          top: up ? geo.node(map, map.work).dy + 6 : trainee.top,
          width: trainee.width,
          height: trainee.height,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
        if (_deciding && !_freeze)
          ValueListenableBuilder<Offset?>(
            key: ValueKey('boot-${r.index}'),
            valueListenable: _boot,
            builder: (_, at, child) {
              final c = at ?? home;
              final b = M6UtGeo.bootRect(c);
              return Positioned.fromRect(rect: b, child: child!);
            },
            child: Semantics(
              label: M6UpstreamTraceLines.bootLabel,
              child: IgnorePointer(
                child: Padding(
                  key: _bootKey,
                  padding: const EdgeInsets.all(5),
                  child: CustomPaint(painter: M6UtBootPainter(flip: map.mirrored)),
                ),
              ),
            ),
          ),
        if (_freeze)
          Positioned.fill(
            key: const ValueKey('flash'),
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                builder: (_, v, _) => CustomPaint(painter: M6UtFlashPainter(at: geo.flashAt(map), v: v)),
              ),
            ),
          ),
      ],
    );
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: ClipRect(
            child: ValueListenableBuilder<double>(
              valueListenable: _cam,
              builder: (_, cam, child) => Transform.translate(offset: Offset(-cam, 0), child: child),
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: kM6UtWorldW,
                maxWidth: kM6UtWorldW,
                child: world,
              ),
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        key: ValueKey('docket-${r.index}'),
        rect: M6UtGeo.docket,
        child: _Docket(kind: j.kind, pole: j.plates.pole, read: r.docketRead, quiet: quiet),
      ),
      if (_requestBn != null)
        Positioned.fromRect(
          key: ValueKey('radio-${r.index}'),
          rect: M6UtGeo.radio,
          child: IgnorePointer(
            child: _RadioLog(
              request: _requestBn!,
              reply: _replyShown && r.reply != null ? M6UpstreamTraceLines.reply(r.reply!, j.plates, j.ptw) : null,
            ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6UpstreamTraceLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition),
            onPanUpdate: (d) => _panUpdate(d.localPosition, d.delta),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: () {
              _drag = _Drag.none;
              _boot.value = null;
            },
          ),
        ),
      ),
      // The next job: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('round-${r.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || r.index == 0 ? 0 : 0.6, end: 0),
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
    final handsOn = playing && !_run.climbed && !deckUp && !coworkerOpen && _card == null;
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
              labels: [for (final j in _run.deal.jobs) M6UpstreamTraceLines.pole(j.plates.pole)],
              done: {for (var i = 0; i < math.min(_run.index, kM6UtJobs); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_pttDown && (_requestBn == null || _replyShown),
            hintKey: '${_run.index}/$_steps/${_run.docketRead}/${_run.traced}/${_run.flagged}/${_run.reply}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn)
                Positioned(
                  key: ValueKey('hud-ptt-${_run.index}'),
                  left: 10,
                  bottom: pad.bottom + 10,
                  child: _Ptt(
                    key: _pttKey,
                    ring: _ptt,
                    down: _pttDown,
                    onDown: _pttPress,
                    onUp: _pttRelease,
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
                  line: M6UpstreamTraceLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: kM6UtLessonPoint, muted: _muted)),
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

/// The docket: folded until read, then the job and the work pole (never the
/// feeder or a device).
class _Docket extends StatelessWidget {
  const _Docket({required this.kind, required this.pole, required this.read, required this.quiet});
  final M6UtJobKind kind;
  final int pole;
  final bool read;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final paper = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(M6UpstreamTraceLines.docket, textAlign: TextAlign.center, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
            const Divider(height: 6, thickness: 1, color: Color(0x668A6A3C)),
            if (read) ...[
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(M6UpstreamTraceLines.job(kind), style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF8A2A16))),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(M6UpstreamTraceLines.pole(pole), style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2A2018))),
              ),
            ] else
              Expanded(child: CustomPaint(painter: _ScribblePainter())),
          ],
        ),
      ),
    );
    return Semantics(
      label: M6UpstreamTraceLines.docket,
      child: quiet
          ? paper
          : TweenAnimationBuilder<double>(
              key: ValueKey(read),
              tween: Tween(begin: 0.92, end: 1),
              duration: const Duration(milliseconds: 260),
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: paper,
            ),
    );
  }
}

/// Unread lines on the folded docket.
class _ScribblePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = const Color(0x553A2A16)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.25 + i * 0.25);
      c.drawLine(Offset(4, y), Offset(size.width - (i.isOdd ? 18 : 6), y), p);
    }
  }

  @override
  bool shouldRepaint(_ScribblePainter old) => false;
}

/// The radio log: the request and the reply in one plain style (the reply is
/// never coloured by what it says).
class _RadioLog extends StatelessWidget {
  const _RadioLog({required this.request, required this.reply});
  final String request;
  final String? reply;

  @override
  Widget build(BuildContext context) {
    final who = bangla(fontSize: 9.5, fontWeight: FontWeight.w900, color: SlmColors.gold300);
    final say = bangla(fontSize: 10, fontWeight: FontWeight.w700, height: 1.25, color: SlmColors.ivory);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE60B1324),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x88FFFFFF), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 236,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [TextSpan(text: '${M6UpstreamTraceLines.you}: ', style: who), TextSpan(text: request, style: say)])),
                const SizedBox(height: 4),
                if (reply != null)
                  Text.rich(TextSpan(children: [TextSpan(text: '${M6UpstreamTraceLines.control}: ', style: who), TextSpan(text: reply, style: say)]))
                else
                  Text('…', style: say),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The walkie's PTT: press and hold (a ring fills), release.
class _Ptt extends StatelessWidget {
  const _Ptt({super.key, required this.ring, required this.down, required this.onDown, required this.onUp});
  final Animation<double> ring;
  final bool down;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M6UpstreamTraceLines.pttLabel,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: CustomPaint(size: const Size(72, 72), painter: _RingPainter(ring)),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: down ? const [Color(0xFF2A3E60), Color(0xFF13203A)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings_input_antenna_rounded, size: 20, color: SlmColors.gold300),
                    Text(M6UpstreamTraceLines.pttLabel, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v) : super(repaint: v);
  final Animation<double> v;

  @override
  void paint(Canvas c, Size size) {
    if (v.value <= 0) return;
    final r = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 3);
    c.drawArc(
      r,
      -math.pi / 2,
      2 * math.pi * v.value,
      false,
      Paint()
        ..color = SlmColors.gold300
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}
