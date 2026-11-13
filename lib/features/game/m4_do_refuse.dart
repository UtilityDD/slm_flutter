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
import 'm2_hotstick_operate_world.dart' show HsArcPainter, HsHead, HsRodPainter, HsShieldPainter;
import 'm4_do_refuse_world.dart';
import 'mistake_kit.dart';
import 'order_steps.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode, Carry;
import 'spoken_once.dart';

export 'm4_do_refuse_world.dart' show M4DoRefuseGeo, M4DoRefuseBarrel;

// Lesson 4.4 "ডিও (DO) ফিউজ পরিচালনা করা", কাজ 2 "ফিউজ উড়েছে — কেন?"
// (pack do_4_4_b, engineType m4_do_refuse). A village DTR's DO fuse has
// dropped. Three rounds a play, all on that one call:
//   ক — spot the dropped barrel; choose what comes first (pro tip 2: when a
//       fault blows one fuse, open the other two phases too, clear the fault,
//       then fit all three one by one); open the other two with the rod; the
//       crew walks the line; take the blown barrel down with the rod.
//   খ — the link, on a tarpaulin: choose the link whose rating is on the
//       docket (point 1: the right ampere rating) — a coil of thick wire is
//       on the tray too; then in order (point 2): wipe the barrel and contacts
//       with a dry cloth → seat the link's button in the top contact → wind
//       the flexible tail round the bottom contact, nut tight → check the
//       leader wire is not over the expulsion port → "ব্যারেল তৈরি".
//   গ — put it back (point 3): stand to the side, not under; seat the barrel
//       on the bottom hinge; face aside, one quick push home. Dealt: a small
//       spark that dies once it locks (myth 2 / advanced fact 2: inrush, not a
//       fault — do not reopen; then the other two fuses one by one), or the
//       fuse blows again at once (a fault is still there: stop, no reclosing —
//       inferred from pro tip 2 + myth 2, flagged).
// Deadly: a thick wire in place of the fuse link (point 1 / point 2's
// "fails to drop out on a fault"; the deadly call is flagged). Slips: a sound
// fuse called the dropped one, refit at once, a wrong rating, a link step out
// of order, under the fuse, face not aside, reopening on a normal spark,
// reclosing after a re-blow.
// The careless coworker once a play: at the tray ("মোটা তার দিয়ে বেঁধে দাও" —
// listening is the deadly bodge, on Module 4's deadly list; owner to confirm)
// or at the re-blow ("যতবার উড়বে ততবার লাগাও" — listening = reclosing on the
// fault, a slip). The tray waits for him ([CoworkerMoment.holdForCoworker]).
// His push lines have no recorded clip yet ([M4DoRefuseLines.recordLines]):
// the kit shows them as a held caption until they are recorded.
// Gesture hints (how, never what): a sweep over the fuses / the tray / the
// barrel's parts, a sweep over the ground for the stance, a tap on the hinge,
// an upward swipe for the push (never the face button).

// ============================================================================
// Content
// ============================================================================

/// What happens when the barrel is pushed home.
enum M4DoRefuseOutcome { settles, reblows }

/// Where the careless coworker comes.
enum M4DoRefuseCall { link, reblow }

/// What round খ's reason asks about.
enum M4DoRefuseLinkTopic { rating, port }

/// The steps of the play (rounds ক, খ, গ).
enum M4DoRefusePhase { spot, decide, openOthers, lower, pick, fit, stand, seat, push, watch, closeOthers, done }

/// Fuse link ratings a tray may hold (a matching task: the docket names the
/// one for this DTR; no sizing rule is claimed — flagged).
const m4DoRefuseRatings = ['6A', '8A', '10A', '16A', '20A'];

/// The link steps, in the lesson's order (point 2), then "ready".
const m4DoRefuseSteps = ['clean', 'button', 'wrap', 'port', 'ready'];

@immutable
class M4DoRefuseDeal {
  const M4DoRefuseDeal({
    required this.phase,
    required this.rating,
    required this.tray,
    required this.outcome,
    required this.call,
    required this.portBlocked,
    required this.linkTopic,
  });

  /// The phase whose fuse dropped (0 R, 1 Y, 2 B).
  final int phase;

  /// The rating on the docket.
  final String rating;

  /// The tray, left to right: ratings; null = the coil of thick wire.
  final List<String?> tray;
  final M4DoRefuseOutcome outcome;
  final M4DoRefuseCall call;

  /// The leader wire lies over the port after winding (seen when checked).
  final bool portBlocked;
  final M4DoRefuseLinkTopic linkTopic;
}

M4DoRefuseDeal m4DoRefuseDeal(math.Random rng) {
  final ratings = [...m4DoRefuseRatings]..shuffle(rng);
  final rating = ratings.first;
  final tray = <String?>[rating, ratings[1], ratings[2], null]..shuffle(rng);
  final outcome = rng.nextBool() ? M4DoRefuseOutcome.reblows : M4DoRefuseOutcome.settles;
  final call = outcome == M4DoRefuseOutcome.reblows && rng.nextBool() ? M4DoRefuseCall.reblow : M4DoRefuseCall.link;
  return M4DoRefuseDeal(
    phase: rng.nextInt(3),
    rating: rating,
    tray: tray,
    outcome: outcome,
    call: call,
    portBlocked: rng.nextBool(),
    linkTopic: rng.nextBool() ? M4DoRefuseLinkTopic.rating : M4DoRefuseLinkTopic.port,
  );
}

abstract final class M4DoRefuseLines {
  static const title = 'ফিউজ উড়েছে — কেন?';
  static const intro = 'ট্রান্সফরমারের একটা ডিও ফিউজ উড়েছে! আগে কারণ, তারপর লাগানো।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The task of each step (what the guide says, and repeats when tapped).
  static const askSpot = 'কোন ফেজের ফিউজটা উড়েছে? দেখান।';
  static const askDecide = 'ফিউজ উড়েছে। আগে কী করবেন?';
  static const askOpenOthers = 'বাকি দুই ফেজের ফিউজও রড দিয়ে খুলুন।';
  static const askLower = 'উড়ে যাওয়া ব্যারেলটা রড দিয়ে নামান।';
  static const askPick = 'ব্যারেলে কোনটা লাগাবেন? বেছে নিন।';
  static const askFit = 'এবার লিঙ্কটা নিয়ম মেনে বাঁধুন।';
  static const askStand = 'কোথায় দাঁড়াবেন? মাটিতে জায়গাটা দেখান।';
  static const askSeat = 'ব্যারেলটা নিচের কব্জায় বসান।';
  static const askPush = 'এবার ফিউজটা লাগান — এক ধাক্কায়।';
  static const askSettle = 'লাগানোর সময় একটু স্পার্ক হলো। এখন কী করবেন?';
  static const askReblow = 'লাগাতেই আবার উড়ে গেল! এখন কী করবেন?';
  static const askCloseOthers = 'এবার বাকি দুটো ফিউজ একে একে লাগান।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static String ask(M4DoRefusePhase p, M4DoRefuseOutcome o) => switch (p) {
    M4DoRefusePhase.spot => askSpot,
    M4DoRefusePhase.decide => askDecide,
    M4DoRefusePhase.openOthers => askOpenOthers,
    M4DoRefusePhase.lower => askLower,
    M4DoRefusePhase.pick => askPick,
    M4DoRefusePhase.fit => askFit,
    M4DoRefusePhase.stand => askStand,
    M4DoRefusePhase.seat => askSeat,
    M4DoRefusePhase.push => askPush,
    M4DoRefusePhase.watch => o == M4DoRefuseOutcome.settles ? askSettle : askReblow,
    M4DoRefusePhase.closeOthers || M4DoRefusePhase.done => askCloseOthers,
  };
  static const tasks = [askSpot, askDecide, askOpenOthers, askLower, askPick, askFit, askStand, askSeat, askPush, askSettle, askReblow, askCloseOthers];

  // Said between steps (not a task).
  static const teamBack = 'দল লাইনটা ঘুরে দেখে এল।';

  // Not scored: the guide says it, the step stays.
  static const tooFar = 'এত দূর থেকে রড পৌঁছায় না। আবার জায়গাটা দেখান।';
  static const missSeat = 'ব্যারেলটা নিচের কব্জার ঠিক জায়গায় নিন।';
  static const shortPush = 'আধা ধাক্কা হলো। একটি দ্রুত, আত্মবিশ্বাসী ধাক্কায় — পুরোটা।';
  static const slowPush = 'এত ধীরে নয়। দ্বিধা করলে আর্ক দীর্ঘ হয় — এক ধাক্কায়।';

  // Labels a worker reads (buttons, the docket, the bench).
  static const sceneLabel = 'ট্রান্সফরমারের পোল';
  static const docket = 'ডকেট';
  static String docketBn(String rating) => 'DTR-এর ডিও ফিউজ উড়েছে · লিঙ্ক $rating';
  static const thickWire = 'মোটা তার';
  static const cloth = 'শুকনো কাপড়';
  static const topContact = 'ওপরের কন্টাক্ট';
  static const bottomContact = 'নিচের কন্টাক্ট';
  static const port = 'এক্সপেলশন পোর্ট';
  static const ready = 'ব্যারেল তৈরি';
  static const benchLabel = 'ব্যারেল';
  static const faceAside = 'মুখ ফেরান';
  static const faceAsideOn = 'মুখ ফেরানো';

  // In-play choices (a wrong one is a field mistake: a strike).
  static const decideRight = ['তিন ফেজই খুলে, আগে ফল্ট খুঁজে সারাই', 'বাকি দুটোও খুলি, ফল্ট সারিয়ে তবে লাগাই'];
  static const decideWrong = [
    'উড়ে যাওয়াটা এখনই আবার লাগিয়ে দিই',
    'বাকি দুটো চালু থাক, একটাই লাগাই',
    'মোটা তার দিয়ে সোজা লাগিয়ে দিই',
    'লোকে অন্ধকারে, আগে লাগিয়ে আলো ফেরাই',
    'ফল্ট পরে খুঁজব, আগে এটা লাগিয়ে দিই',
    'বাকি দুটো খুলে রাখি, এটা এখনই লাগাই',
    'ফল্ট পরে সারাব, আগে এটা লাগিয়ে দিই',
  ];
  static const settleRight = ['স্বাভাবিক ইনরাশ স্পার্ক — আর খুলব না', 'লক হয়েছে, স্পার্ক থেমেছে — ঠিক আছে'];
  static const settleWrong = [
    'খুলে আরেকবার লাগিয়ে দেখি, পাকা হোক',
    'স্পার্ক মানেই ফল্ট — খুলে আবার লাগাই',
    'দু-তিনবার খুলে-লাগিয়ে পাকা করে নিই',
    'মোটা লিঙ্ক এনে আবার লাগিয়ে দিই',
    'লক হলেও খুলে দেখি, ইনরাশ না ফল্ট',
  ];
  static const reblowRight = ['আর লাগাব না — ফল্ট এখনও রয়ে গেছে', 'থামি, আগে ফল্টটা খুঁজে সারাতে হবে'];
  static const reblowWrong = [
    'আরেকবার লাগিয়ে দেখি, এবার ধরবে',
    'মোটা তার দিয়ে লাগালে আর উড়বে না',
    'ফল্ট ছোট, আরেকবার লাগালেই ধরবে',
    'বড় রেটিং-এর লিঙ্ক দিয়ে আবার লাগাই',
    'লোকে অপেক্ষায়, যতবার উড়ুক লাগাই',
    'থামার সময় নেই, ফল্ট পরে সারাব',
  ];

  // The reasons: the right ones fit the round just played.
  static const whyOthers = 'কেন বাকি দুই ফেজের ফিউজও খুললেন?';
  static const whyRating = 'কেন ডকেটের রেটিং-এর লিঙ্কটাই নিলেন?';
  static const whyPort = 'কেন শেষে এক্সপেলশন পোর্টটা দেখলেন?';
  static const whySettle = 'কেন স্পার্ক দেখেও ফিউজটা আর খুললেন না?';
  static const whyReblow = 'কেন আবার উড়লে আর লাগালেন না?';
  static String why(int round, M4DoRefuseDeal d) => switch (round) {
    0 => whyOthers,
    1 => d.linkTopic == M4DoRefuseLinkTopic.rating ? whyRating : whyPort,
    _ => d.outcome == M4DoRefuseOutcome.settles ? whySettle : whyReblow,
  };

  static const othersWhy = ['ফল্টে একটা উড়লে তিনটিই খুলে কাজ করা নিয়ম', 'তিন ফেজ খুলে ফল্ট সারিয়ে, তারপর লাগানো'];
  static const ratingWhy = ['ভুল রেটিং-এর লিঙ্ক ফল্টে ড্রপ-আউট নাও হতে পারে', 'সঠিক অ্যাম্পিয়ার রেটিং-এর এলিমেন্টই নিয়ম'];
  static const portWhy = ['লিডার তার পোর্ট বন্ধ করলে গ্যাস বেরোতে পারে না', 'আর্কের গ্যাস বেরোনোর মুখ খোলা রাখতে হয়'];
  static const settleWhy = ['ইনরাশ কারেন্টে লাগানোর সময় স্পার্ক স্বাভাবিক', 'বারবার খোলা-লাগানোয় ফিউজ আর যন্ত্রে চাপ পড়ে'];
  static const reblowWhy = ['আবার উড়ল মানে লাইনে ফল্ট এখনও রয়ে গেছে', 'ফল্ট না সারিয়ে লাগালে আবার আর্ক হবেই'];
  static List<String> whyRight(int round, M4DoRefuseDeal d) => switch (round) {
    0 => othersWhy,
    1 => d.linkTopic == M4DoRefuseLinkTopic.rating ? ratingWhy : portWhy,
    _ => d.outcome == M4DoRefuseOutcome.settles ? settleWhy : reblowWhy,
  };

  /// Wrong reasons (the field's excuses and myths). Some carry the rounds'
  /// own words (ফল্ট, রেটিং, স্পার্ক, পোর্ট, তিন ফেজ, গ্যাস, আবার) so no word
  /// marks the right card.
  static const whyWrong = [
    'মোটা তার দিলে ফিউজ আর কোনো ঝামেলা করে না',
    'লোকে অন্ধকারে, তাড়াতাড়ি আলো ফেরাতে হবে',
    'অভ্যাস আছে, এত নিয়মের দরকার পড়ে না',
    'যতবার উড়ুক, লাগাতে থাকলে একসময় ধরে',
    'সুপারভাইজার দাঁড়িয়ে, তাড়াতাড়ি সারতে হবে',
    'ফিউজ ওড়া রোজকার ব্যাপার, কারণ লাগে না',
    'ফল্ট খোঁজার চেয়ে আলো ফেরানো আগে জরুরি',
    'বড় রেটিং-এর লিঙ্ক বেশিদিন টিকে যায়',
    'স্পার্ক নিয়ে ভাবার সময় নেই, কাজ বাকি',
    'পোর্ট দেখলে সুপারভাইজার খুশি থাকেন, তাই',
    'তিন ফেজ খুলে রাখলে লোকে বোঝে কাজ হচ্ছে',
    'গ্যাস বেরোলেও পোর্ট নিয়ে ভাবার দরকার নেই',
    'আবার উড়লে আরও একবার লাগালেই ধরে যায়',
  ];

  static const coworkerExit = 'হুঁ! যা খুশি করুন।';

  /// The careless coworker at the tray.
  static const coworkerLink = CoworkerScript(
    line: 'মোটা তার দিয়ে বেঁধে দাও, আর উড়বেই না!',
    exitLine: coworkerExit,
    right: ['না, ঠিক রেটিং-এর লিঙ্কই লাগাব', 'না, মোটা তারে ফল্টে ফিউজ কাটবে না', 'তার নয়, ডকেটের রেটিং-এর লিঙ্ক'],
    wrong: [
      'ঠিক, মোটা তারে আর উড়বে না',
      'আচ্ছা, তার দিয়েই বেঁধে দিচ্ছি',
      'লিঙ্কের ঝামেলা না করে তারই দিই',
      'মোটা তারে কাজ পাকা হয়ে যায়',
      'ঠিক আছে, রেটিং-টেটিং লাগে না',
    ],
    asks: ['ও বলছে মোটা তার বাঁধতে। আপনি?', 'লিঙ্ক, না মোটা তার — কী লাগাবেন?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// The careless coworker at the re-blow.
  static const coworkerReblow = CoworkerScript(
    line: 'যতবার উড়বে ততবার লাগাও! একসময় ধরে যাবে।',
    exitLine: coworkerExit,
    right: ['না, আবার উড়ল মানে ফল্ট আছে', 'না, ফল্ট না সারিয়ে আর লাগাব না', 'থামছি, আগে ফল্টটা সারাতে হবে'],
    wrong: [
      'ঠিক, আরেকবার লাগিয়েই দেখি',
      'আচ্ছা, যতক্ষণ না ধরে লাগাই',
      'জোরে ঠেললে এবার ধরে যাবে',
      'তাড়াতাড়ি আবার লাগিয়ে দিচ্ছি',
      'ঠিক আছে, ফল্ট-টল্ট পরে দেখব',
      'ফল্ট পরে সারাব, আগে লাগিয়ে দিই',
    ],
    asks: ['ও বলছে আবার লাগাতে। আপনি?', 'আবার লাগাবেন, না থামবেন?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// His push lines with no recorded clip yet (the director records them).
  static List<String> get recordLines => [coworkerLink.line, coworkerReblow.line];

  static const callHeld = 'ঠিক! চাপে পড়ে নিয়ম ভাঙবেন না।';
  static const allSet = 'আগে কারণ, ঠিক লিঙ্ক, নিয়ম মেনে লাগানো — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে কারণ, তারপর ঠিক লিঙ্ক, তারপর নিয়ম মেনে লাগানো।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtDecide = 'আগে তিন ফেজ খুলে ফল্ট খোঁজা';
  static const caughtRating = 'ডকেটের রেটিং-এর লিঙ্ক, মোটা তার নয়';
  static const caughtLink = 'পরিষ্কার → বোতাম → তার → পোর্ট';
  static const caughtStand = 'ফিউজের নিচে নয়, পাশে দাঁড়ানো';
  static const caughtPush = 'মুখ সরিয়ে এক ধাক্কায়';
  static const caughtSettle = 'ইনরাশের স্পার্কে আর খোলা নয়';
  static const caughtReblow = 'আবার উড়লে — থামা';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M4DoRefuseMistakes {
  static const _dir = 'assets/game/art/m4_do_refuse';

  /// A sound fuse called the dropped one (a wrong flag costs a slip).
  static const wrongFuse = DoMistake(
    key: '4.4/m4_do_refuse/wrong-fuse',
    textBn: 'যে ফিউজটা ঠিকঠাক বসে আছে, সেটাকেই উড়ে যাওয়া বললেন। ডিও ফিউজ উড়লে ব্যারেলটা কব্জায় নিচে ঝুলে পড়ে — ভালো করে দেখে তবে রড তুলুন।',
    art: '$_dir/spot.svg',
  );

  /// Pro tip 2 (not a lesson point).
  static const refitAtOnce = DoMistake(
    key: '4.4/m4_do_refuse/refit-at-once',
    textBn: 'কারণ না খুঁজেই উড়ে যাওয়া ফিউজ আবার লাগাতে চাইলেন। ফল্টে একটা ফিউজ উড়লে বাকি দুই ফেজের ফিউজও খুলুন, ফল্ট সারান, তারপর তিনটি একে একে লাগান।',
    art: '$_dir/refit.svg',
  );
  static const thickWire = DoMistake(
    key: '4.4/m4_do_refuse/thick-wire',
    textBn: 'ফিউজ লিঙ্কের বদলে মোটা তার বাঁধলেন। ওটা আর ফিউজ নয় — ফল্টের সময় ড্রপ-আউট হবে না, ফল্ট চলতেই থাকবে। সবসময় সঠিক অ্যাম্পিয়ার রেটিং-এর ফিউজ এলিমেন্ট।',
    art: '$_dir/thick.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const wrongRating = DoMistake(
    key: '4.4/m4_do_refuse/wrong-rating',
    textBn: 'ডকেটের রেটিং-এর লিঙ্ক নেননি। ফিউজ এলিমেন্ট চাই সঠিক অ্যাম্পিয়ার রেটিং-এর — ডকেটে যা লেখা, ঠিক সেটাই।',
    art: '$_dir/rating.svg',
    lessonPoint: 0,
  );
  static const noClean = DoMistake(
    key: '4.4/m4_do_refuse/not-cleaned',
    textBn: 'পরিষ্কার না করেই লিঙ্ক বসাতে গেলেন। আগে ব্যারেল আর ওপর-নিচের কন্টাক্ট শুকনো কাপড়ে পরিষ্কার, তারপর লিঙ্ক।',
    art: '$_dir/link_steps.svg',
    lessonPoint: 1,
  );
  static const noButton = DoMistake(
    key: '4.4/m4_do_refuse/button-not-seated',
    textBn: 'লিঙ্কের ওপরের বোতাম ব্যারেলের ওপরের কন্টাক্টে না বসিয়েই এগোলেন। আগে বোতাম ঠিক জায়গায়, তারপর নিচের তার।',
    art: '$_dir/link_steps.svg',
    lessonPoint: 1,
  );
  static const noWrap = DoMistake(
    key: '4.4/m4_do_refuse/tail-not-wound',
    textBn: 'নিচের নমনীয় তার কন্টাক্টে পেঁচিয়ে নাট টাইট না দিয়েই এগোলেন। কানেকশন ঢিলা থাকলে গরম হয়ে ব্যারেলটাই নষ্ট হয়।',
    art: '$_dir/link_steps.svg',
    lessonPoint: 1,
  );
  static const portUnchecked = DoMistake(
    key: '4.4/m4_do_refuse/port-not-checked',
    textBn: 'এক্সপেলশন পোর্ট না দেখেই ব্যারেল তৈরি বললেন। লিডার তার যেন গ্যাস বেরোনোর মুখ বন্ধ না করে — শেষ ধাপে এটা দেখা চাই।',
    art: '$_dir/port.svg',
    lessonPoint: 1,
  );
  static const underFuse = DoMistake(
    key: '4.4/m4_do_refuse/under-the-fuse',
    textBn: 'ফিউজের ঠিক নিচে দাঁড়ালেন। লাগানোর সময় আর্ক হতে পারে — ফিউজ থাকবে আপনার পাশে বা কোণাকুণি, মাথার ওপরে নয়।',
    art: '$_dir/stand.svg',
    lessonPoint: 2,
  );
  static const faceIn = DoMistake(
    key: '4.4/m4_do_refuse/face-not-aside',
    textBn: 'মুখ না সরিয়েই ঠেলে লাগালেন। লাগানোর মুহূর্তে ফ্ল্যাশ হতে পারে — মুখ একপাশে রেখে, এক আত্মবিশ্বাসী ধাক্কায়।',
    art: '$_dir/face.svg',
    lessonPoint: 2,
  );

  /// Myth 2 (not a lesson point).
  static const reopen = DoMistake(
    key: '4.4/m4_do_refuse/reopen-on-spark',
    textBn: 'ছোট স্পার্ক দেখে আবার খুলতে চাইলেন। স্থায়ী ফল্ট না থাকলে লাগানোর সময় সামান্য স্পার্ক স্বাভাবিক — বারবার খোলা-বন্ধে যন্ত্র আর ফিউজে চাপ পড়ে।',
    art: '$_dir/spark.svg',
  );

  /// Pro tip 2 + myth 2 (not a lesson point).
  static const reclose = DoMistake(
    key: '4.4/m4_do_refuse/reclose-on-fault',
    textBn: 'লাগাতেই আবার উড়ল, তবু আবার লাগাতে গেলেন। আবার উড়ে যাওয়া মানে লাইনে ফল্ট রয়ে গেছে — ফল্ট না সারিয়ে আর লাগানো নয়।',
    art: '$_dir/reblow.svg',
  );

  static List<DoMistake> get all => [wrongFuse, refitAtOnce, thickWire, wrongRating, noClean, noButton, noWrap, portUnchecked, underFuse, faceIn, reopen, reclose];
}

/// The link steps as an order board (point 2's four steps, then "ready").
OrderRoundSpec m4DoRefuseOrderSpec() => const OrderRoundSpec(
  groups: [
    OrderGroup(['clean'], skipMistake: M4DoRefuseMistakes.noClean),
    OrderGroup(['button'], skipMistake: M4DoRefuseMistakes.noButton),
    OrderGroup(['wrap'], skipMistake: M4DoRefuseMistakes.noWrap),
    OrderGroup(['port'], skipMistake: M4DoRefuseMistakes.portUnchecked),
    OrderGroup(['ready'], skipMistake: M4DoRefuseMistakes.portUnchecked),
  ],
);

/// Where a tap on the ground leaves the trainee, against the fuse.
enum M4DoRefuseStand { under, side, far }

/// |dx| from the fuse (design px): under < 26 ≤ side ≤ 130 < far.
M4DoRefuseStand m4DoRefuseStandOf(double dx) {
  final d = dx.abs();
  if (d < 26) return M4DoRefuseStand.under;
  if (d <= 130) return M4DoRefuseStand.side;
  return M4DoRefuseStand.far;
}

/// What a push came to.
enum M4DoRefusePush { short, slow, done }

/// The push home: one upward drag of ≥ 70 design px within 1.2 s.
const m4DoRefusePushPx = 70.0;
const m4DoRefusePushMaxMs = 1200;

/// The play state (pure logic).
class M4DoRefuseRun {
  M4DoRefuseRun(this.deal);
  final M4DoRefuseDeal deal;
  int round = 0;
  M4DoRefusePhase phase = M4DoRefusePhase.spot;

  /// The other two phases opened (round ক) / closed again (round গ).
  final Set<int> opened = {};
  final Set<int> closed = {};

  /// The link chosen (the docket's, once the guide put a wrong one right).
  String? link;
  final OrderRun order = OrderRun([m4DoRefuseOrderSpec()]);
  var faceAside = false;

  /// He reclosed after the re-blow (a second blow on the barrel).
  var reclosed = false;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => round >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get clean => roundSlips == 0;
  bool get settles => deal.outcome == M4DoRefuseOutcome.settles;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  bool _at(M4DoRefusePhase p) => !ended && phase == p;

  /// ক: a tap on fuse [p]: (true, null) when it is the dropped one; a sound
  /// fuse called dropped is a slip and the step stays.
  (bool, DoMistake?) spot(int p) {
    if (!_at(M4DoRefusePhase.spot)) return (false, null);
    if (p != deal.phase) return (false, _slip(M4DoRefuseMistakes.wrongFuse));
    phase = M4DoRefusePhase.decide;
    return (true, null);
  }

  /// ক: what comes first. A wrong choice is a slip; the guide puts it right.
  DoMistake? decide({required bool right}) {
    if (!_at(M4DoRefusePhase.decide)) return null;
    phase = M4DoRefusePhase.openOthers;
    if (!right) return _slip(M4DoRefuseMistakes.refitAtOnce);
    _tag(M4DoRefuseLines.caughtDecide);
    return null;
  }

  /// ক: open fuse [p] (one of the other two).
  bool openOther(int p) {
    if (!_at(M4DoRefusePhase.openOthers) || p == deal.phase || opened.contains(p)) return false;
    opened.add(p);
    if (opened.length == 2) phase = M4DoRefusePhase.lower;
    return true;
  }

  /// ক: the blown barrel comes down on the rod.
  bool lower(int p) {
    if (!_at(M4DoRefusePhase.lower) || p != deal.phase) return false;
    phase = M4DoRefusePhase.done;
    return true;
  }

  /// খ: a tray item ([item] null = the coil of thick wire).
  DoMistake? pick(String? item) {
    if (!_at(M4DoRefusePhase.pick)) return null;
    if (item == null) return deadly = M4DoRefuseMistakes.thickWire;
    link = deal.rating;
    phase = M4DoRefusePhase.fit;
    if (item != deal.rating) return _slip(M4DoRefuseMistakes.wrongRating);
    _tag(M4DoRefuseLines.caughtRating);
    return null;
  }

  /// খ: a link step ([m4DoRefuseSteps]). Out of order = a slip, the step stays.
  OrderTap fit(String id) {
    if (!_at(M4DoRefusePhase.fit)) return const OrderTap(OrderTapKind.ignored);
    final t = order.tap(id);
    if (t.kind == OrderTapKind.mistake) _slip(t.mistake!);
    if (t.allDone) {
      phase = M4DoRefusePhase.done;
      if (clean) _tag(M4DoRefuseLines.caughtLink);
    }
    return t;
  }

  bool isFitted(String id) => order.done || order.isDone(id);

  /// গ: where he stands ([dx] from the fuse). Too far = not scored, stay.
  (M4DoRefuseStand, DoMistake?) stand(double dx) {
    if (!_at(M4DoRefusePhase.stand)) return (M4DoRefuseStand.far, null);
    final s = m4DoRefuseStandOf(dx);
    if (s == M4DoRefuseStand.far) return (s, null);
    phase = M4DoRefusePhase.seat;
    if (s == M4DoRefuseStand.under) return (s, _slip(M4DoRefuseMistakes.underFuse));
    _tag(M4DoRefuseLines.caughtStand);
    return (s, null);
  }

  bool seat() {
    if (!_at(M4DoRefusePhase.seat)) return false;
    phase = M4DoRefusePhase.push;
    return true;
  }

  void turnFace() {
    if (_at(M4DoRefusePhase.push)) faceAside = true;
  }

  /// গ: the push: [px] upward over [ms].
  (M4DoRefusePush, DoMistake?) push(double px, int ms) {
    if (!_at(M4DoRefusePhase.push)) return (M4DoRefusePush.short, null);
    if (px < m4DoRefusePushPx) return (M4DoRefusePush.short, null);
    if (ms > m4DoRefusePushMaxMs) return (M4DoRefusePush.slow, null);
    phase = M4DoRefusePhase.watch;
    if (!faceAside) return (M4DoRefusePush.done, _slip(M4DoRefuseMistakes.faceIn));
    _tag(M4DoRefuseLines.caughtPush);
    return (M4DoRefusePush.done, null);
  }

  /// গ: after the push — the spark (settles) or the re-blow. [right]: leave
  /// it closed / stop.
  DoMistake? watch({required bool right}) {
    if (!_at(M4DoRefusePhase.watch)) return null;
    phase = settles ? M4DoRefusePhase.closeOthers : M4DoRefusePhase.done;
    if (settles) {
      if (!right) return _slip(M4DoRefuseMistakes.reopen);
      _tag(M4DoRefuseLines.caughtSettle);
      return null;
    }
    if (!right) {
      reclosed = true;
      return _slip(M4DoRefuseMistakes.reclose);
    }
    _tag(M4DoRefuseLines.caughtReblow);
    return null;
  }

  /// গ: close fuse [p] (one of the other two), one by one.
  bool closeOther(int p) {
    if (!_at(M4DoRefusePhase.closeOthers) || p == deal.phase || closed.contains(p)) return false;
    closed.add(p);
    if (closed.length == 2) phase = M4DoRefusePhase.done;
    return true;
  }

  void next() {
    round++;
    roundSlips = 0;
    faceAside = false;
    phase = round == 1 ? M4DoRefusePhase.pick : M4DoRefusePhase.stand;
  }

  /// The barrels on the cross-arm now (R, Y, B).
  List<M4DoRefuseBarrel> get barrels {
    final out = <M4DoRefuseBarrel>[];
    for (var i = 0; i < 3; i++) {
      if (i != deal.phase) {
        final open = opened.contains(i) && !closed.contains(i);
        out.add(open ? M4DoRefuseBarrel.open : M4DoRefuseBarrel.closed);
        continue;
      }
      final r = round.clamp(0, 2);
      if (r == 0) {
        out.add(phase == M4DoRefusePhase.done ? M4DoRefuseBarrel.gone : M4DoRefuseBarrel.open);
      } else if (r == 1) {
        out.add(M4DoRefuseBarrel.gone);
      } else {
        out.add(switch (phase) {
          M4DoRefusePhase.stand || M4DoRefusePhase.seat => M4DoRefuseBarrel.gone,
          M4DoRefusePhase.push => M4DoRefuseBarrel.open,
          _ => settles ? M4DoRefuseBarrel.closed : M4DoRefuseBarrel.open,
        });
      }
    }
    return out;
  }
}

/// The quick bonus (~85 % of a thorough play, rounded). ক: spot 2000 + deck
/// 6000 + two fuses 3000 + the crew 3000 + lower 2000 + reason 8200 = 24200;
/// খ: tray 3000 + five steps 6000 + reason 8200 = 17200; গ: stand 2000 + seat
/// 2000 + face 1000 + push 2000 + spark 1500 + deck 6000 + two fuses 3000 +
/// reason 8200 = 25700; + the coworker ≈ 9000 → 76100; 85 % ≈ 64700 → 65 s.
const m4DoRefuseQuickMs = 65000;

@immutable
class M4DoRefusePack {
  const M4DoRefusePack({required this.id, required this.titleBn, this.quickMs = m4DoRefuseQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4DoRefusePack> m4DoRefusePacks = {'do_4_4_b': M4DoRefusePack(id: 'do_4_4_b', titleBn: M4DoRefuseLines.title)};

/// Where he starts (left of the pole) in rounds ক and গ.
const m4DoRefuseStartX = 52.0;

/// What a fuse tap at [p] hits (the unit with its hanging barrel), or null.
int? m4DoRefuseUnitAt(M4DoRefuseGeo geo, Offset p) {
  for (var i = 0; i < 3; i++) {
    if (geo.unitOf(i).contains(p)) return i;
  }
  return null;
}

// ============================================================================
// Page
// ============================================================================

class M4DoRefusePage extends StatefulWidget {
  const M4DoRefusePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4DoRefusePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4DoRefusePage> createState() => _M4DoRefusePageState();
}

class _M4DoRefusePageState extends State<M4DoRefusePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DrRunPage(
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

class _DrRunPage extends ConsumerStatefulWidget {
  const _DrRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4DoRefusePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DrRunPage> createState() => _DrRunPageState();
}

/// Which in-play choice is on the deck.
enum _Deck { decide, watch }

class _DrRunPageState extends ConsumerState<_DrRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4DoRefuseRun _run = M4DoRefuseRun(m4DoRefuseDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  VoidCallback? _resume;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  double _standX = m4DoRefuseStartX;

  /// Where the rod's head is (design px); [_touch]: on it, not just short.
  Offset? _aim;
  var _touch = false;

  /// The in-play choice deck.
  _Deck? _deck;
  List<ChoiceOption> _deckOpts = const [];
  String? _deckPicked;

  /// A flash at a contact (a one-shot); [_flashBig] for the re-blow.
  int _flashN = 0;
  Offset? _flashAt;
  var _flashBig = false;

  Duration? _panT0;
  Duration _panT1 = Duration.zero;
  Offset _panSum = Offset.zero;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset? _deathAt;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// Gesture hints: the tray tiles, the bench box, the cloth and "ready".
  final _hints = IdleHintController();
  final _trayKeys = List.generate(4, (_) => GlobalKey());
  final _benchKey = GlobalKey();
  final _clothKey = GlobalKey();
  final _readyKey = GlobalKey();

  /// The bench sweep's order, shuffled once a play so the hand never glides
  /// over the link steps in the lesson's order.
  late final List<int> _fitSweep = () {
    // Parts: 0 top contact, 1 bottom nut, 2 port, 3 cloth, 4 ready. The
    // lesson's order is 3-0-1-2-4; the sweep never follows it.
    final o = [0, 1, 2, 3, 4]..shuffle(math.Random(_deal.phase * 31 + _deal.tray.indexOf(null)));
    if (o.join() == '30124') return [2, 4, 0, 3, 1];
    return o;
  }();

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M4DoRefuseDeal get _deal => _run.deal;
  int get _blown => _deal.phase;
  M4DoRefuseGeo _geoNow = M4DoRefuseGeo.forScene(780, 0);

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

  bool get _canPlay => !_intro && !_busy && !_ended && !tableBusy && _card == null && _deck == null && !reasonOpen && !coworkerOpen;

  String get _task => M4DoRefuseLines.ask(_run.phase, _deal.outcome);

  void _start() {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() {
      _standX = m4DoRefuseStartX;
      _aim = null;
      _touch = false;
      _flashAt = null;
      _wake++;
    });
    if (_run.round == 1 && _deal.call == M4DoRefuseCall.link) scheduleCoworker();
    _askStep();
  }

  void _askStep() => unawaited(_sayChain([_task]));

  Offset _toGlobal(Offset design) {
    final size = MediaQuery.sizeOf(context);
    return design * (size.width / 360);
  }

  void _flash(Offset at, {bool big = false}) {
    setState(() {
      _flashAt = at;
      _flashBig = big;
      _flashN++;
    });
  }

  // --- the scene taps ------------------------------------------------------------
  Future<void> _tapScene(Offset p) async {
    if (!_canPlay) return;
    final geo = _geoNow;
    final unit = m4DoRefuseUnitAt(geo, p);
    switch (_run.phase) {
      case M4DoRefusePhase.spot:
        if (unit == null) {
          _hints.missTap();
          return;
        }
        HapticFeedback.selectionClick();
        _cue('sounds/intro/tick.ogg', volume: 0.45);
        final (hit, wrong) = _run.spot(unit);
        if (wrong != null) {
          // A sound fuse called dropped: a slip; the step stays.
          _hush();
          unawaited(_levelDelta(-10, _toGlobal(p), mood: GuideMood.warn));
          await _slip(wrong, resume: _askStep);
          return;
        }
        if (!hit) return;
        setState(() => _wake++);
        _openDeck(_Deck.decide);
      case M4DoRefusePhase.openOthers:
        if (unit == null) _hints.missTap();
        if (unit == null || !_run.openOther(unit)) return;
        _hush();
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.wav', volume: 0.6);
        setState(() {
          _aim = geo.ringOf(unit);
          _touch = true;
          _wake++;
        });
        _flash(geo.ringOf(unit) + const Offset(4, 0));
        if (_run.phase == M4DoRefusePhase.lower) {
          unawaited(_sayChain([M4DoRefuseLines.teamBack, M4DoRefuseLines.askLower]));
        }
      case M4DoRefusePhase.lower:
        if (unit == null) _hints.missTap();
        if (unit != _blown || !_run.lower(unit!)) return;
        _hush();
        HapticFeedback.mediumImpact();
        _cue('sounds/intro/confirm.ogg', volume: 0.5);
        setState(() {
          _aim = geo.ringOpenOf(_blown);
          _touch = false;
          _wake++;
        });
        _roundDone();
      case M4DoRefusePhase.stand:
        if (p.dy < geo.groundY - 30) {
          _hints.missTap();
          return;
        }
        final x = p.dx.clamp(16.0, 344.0);
        final (s, m) = _run.stand(x - M4DoRefuseGeo.phaseX[_blown]);
        HapticFeedback.selectionClick();
        _cue('sounds/intro/tick.ogg', volume: 0.45);
        if (s == M4DoRefuseStand.far) {
          unawaited(_sayChain([M4DoRefuseLines.tooFar]));
          return;
        }
        setState(() {
          _standX = x;
          _wake++;
        });
        if (m != null) {
          unawaited(_levelDelta(-10, _toGlobal(p), mood: GuideMood.warn));
          await _slip(
            m,
            resume: () {
              // Stepped aside, to the fuse's side.
              setState(() => _standX = M4DoRefuseGeo.phaseX[_blown] - 70);
              _askStep();
            },
          );
          return;
        }
        _askStep();
      case M4DoRefusePhase.seat:
        if ((p - geo.hingeOf(_blown)).distance > 34) {
          _hints.missTap();
          HapticFeedback.selectionClick();
          unawaited(_sayChain([M4DoRefuseLines.missSeat]));
          return;
        }
        _run.seat();
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.wav', volume: 0.6);
        setState(() {
          _aim = geo.ringOpenOf(_blown);
          _touch = true;
          _wake++;
        });
        _askStep();
      case M4DoRefusePhase.closeOthers:
        if (unit == null) _hints.missTap();
        if (unit == null || !_run.closeOther(unit)) return;
        _hush();
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.wav', volume: 0.6);
        setState(() {
          _aim = geo.ringOf(unit);
          _touch = true;
          _wake++;
        });
        _flash(geo.ringOf(unit));
        if (_run.phase == M4DoRefusePhase.done) _roundDone();
      case M4DoRefusePhase.decide ||
          M4DoRefusePhase.pick ||
          M4DoRefusePhase.fit ||
          M4DoRefusePhase.push ||
          M4DoRefusePhase.watch ||
          M4DoRefusePhase.done:
        break;
    }
  }

  // --- the in-play choice deck ----------------------------------------------------
  void _openDeck(_Deck d) {
    final (right, wrong) = switch (d) {
      _Deck.decide => (M4DoRefuseLines.decideRight, M4DoRefuseLines.decideWrong),
      _Deck.watch =>
        _run.settles ? (M4DoRefuseLines.settleRight, M4DoRefuseLines.settleWrong) : (M4DoRefuseLines.reblowRight, M4DoRefuseLines.reblowWrong),
    };
    setState(() {
      _deck = d;
      _deckOpts = dealChoices(right, wrong, widget.rng);
      _deckPicked = null;
    });
    _askStep();
  }

  Future<void> _deckPick(ChoiceOption o, Offset origin) async {
    final d = _deck;
    if (d == null || _deckPicked != null) return;
    _hush();
    if (o.correct) {
      HapticFeedback.mediumImpact();
      _cue('sounds/quiz_select.wav', volume: 0.5);
      setState(() => _deckPicked = o.textBn);
      await Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 650));
      if (!mounted) return;
      setState(() => _deck = null);
      if (d == _Deck.decide) {
        _run.decide(right: true);
        _askStep();
      } else {
        _run.watch(right: true);
        _afterWatch();
      }
      return;
    }
    setState(() => _deck = null);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    if (d == _Deck.decide) {
      await _slip(_run.decide(right: false)!, resume: _askStep);
    } else {
      await _watchWrong();
    }
  }

  /// After the spark or the re-blow was answered right.
  void _afterWatch() {
    if (_run.phase == M4DoRefusePhase.closeOthers) {
      _askStep();
    } else {
      _roundDone();
    }
  }

  /// He reopened on the spark / reclosed on the fault.
  Future<void> _watchWrong() async {
    final m = _run.watch(right: false)!;
    if (!_run.settles) {
      // Pushed home again onto the fault: it blows again.
      _cue('sounds/learn/tag_slap.wav', volume: 0.8);
      _flash(_geoNow.ringOf(_blown), big: true);
    }
    await _slip(m, resume: _afterWatch);
  }

  // --- the link bench --------------------------------------------------------------
  Future<void> _pick(String? item, Offset origin) async {
    if (!_canPlay || _run.phase != M4DoRefusePhase.pick) return;
    // He is due at the tray: the pick waits for him (no skipping by speed).
    if (holdForCoworker()) return;
    _hush();
    final m = _run.pick(item);
    if (m != null && m.deadly) {
      await _deadly(m, at: _geoNow.bushingOf(_blown));
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m, resume: _askStep);
      return;
    }
    _askStep();
  }

  Future<void> _fit(String id, Offset origin) async {
    if (!_canPlay || _run.phase != M4DoRefusePhase.fit) return;
    final t = _run.fit(id);
    if (t.kind == OrderTapKind.ignored) return;
    if (origin == Offset.zero) {
      final size = MediaQuery.sizeOf(context);
      origin = Offset(size.width / 2, size.height * 0.4);
    }
    _hush();
    if (t.kind == OrderTapKind.mistake) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(t.mistake!, resume: _askStep);
      return;
    }
    HapticFeedback.selectionClick();
    _cue(id == 'ready' ? 'sounds/intro/confirm.ogg' : 'sounds/intro/click.ogg', volume: 0.5);
    setState(() => _wake++);
    if (t.allDone) _roundDone();
  }

  // --- the push --------------------------------------------------------------------
  void _turnFace() {
    if (!_canPlay || _run.phase != M4DoRefusePhase.push) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    setState(() {
      _run.turnFace();
      _wake++;
    });
  }

  void _panStart(DragStartDetails d) {
    _panT0 = d.sourceTimeStamp ?? Duration.zero;
    _panT1 = _panT0!;
    _panSum = Offset.zero;
  }

  void _panUpdate(DragUpdateDetails d) {
    if (_panT0 == null) return;
    _panSum += d.delta;
    _panT1 = d.sourceTimeStamp ?? _panT1;
  }

  Future<void> _panEnd(DragEndDetails d) async {
    final t0 = _panT0;
    _panT0 = null;
    if (t0 == null || !_canPlay || _run.phase != M4DoRefusePhase.push) return;
    await _push(-_panSum.dy, (_panT1 - t0).inMilliseconds);
  }

  Future<void> _push(double px, int ms) async {
    final (s, m) = _run.push(px, ms);
    switch (s) {
      case M4DoRefusePush.short:
        unawaited(_sayChain([M4DoRefuseLines.shortPush]));
        return;
      case M4DoRefusePush.slow:
        unawaited(_sayChain([M4DoRefuseLines.slowPush]));
        return;
      case M4DoRefusePush.done:
        break;
    }
    _hush();
    final geo = _geoNow;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: _run.settles ? 0.6 : 0.85);
    setState(() {
      _aim = geo.ringOf(_blown);
      _touch = true;
      _wake++;
    });
    _flash(_run.settles ? geo.ringOf(_blown) : geo.ringOf(_blown) + const Offset(4, 0), big: !_run.settles);
    if (m != null) {
      unawaited(_levelDelta(-10, _toGlobal(geo.ringOf(_blown)), mood: GuideMood.warn));
      await _slip(m, resume: _toWatch);
      return;
    }
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 900));
    if (mounted) _toWatch();
  }

  /// The spark died / it blew again: the choice, or the coworker at the re-blow.
  void _toWatch() {
    if (_ended) return;
    if (!_run.settles && _deal.call == M4DoRefuseCall.reblow) {
      scheduleCoworker();
      return;
    }
    _openDeck(_Deck.watch);
  }

  // --- a round done: its ◆ on the table, then "কেন …?" -------------------------
  void _roundDone() {
    final idx = _run.round;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(
      askReason(
        deal: () => dealChoices(M4DoRefuseLines.whyRight(idx, _deal), M4DoRefuseLines.whyWrong, widget.rng),
        question: M4DoRefuseLines.why(idx, _deal),
        stillValid: () => _run.round == idx && !_ended,
      ),
    );
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
    final idx = _run.round;
    unawaited(
      Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (mounted && !_ended && _run.round == idx) _next();
      }),
    );
  }

  // --- the pressure moment ------------------------------------------------------
  @override
  CoworkerScript get coworkerScript => _deal.call == M4DoRefuseCall.link ? M4DoRefuseLines.coworkerLink : M4DoRefuseLines.coworkerReblow;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final at = _deal.call == M4DoRefuseCall.link ? (1, M4DoRefusePhase.pick) : (2, M4DoRefusePhase.watch);
    if (_run.round != at.$1 || _run.phase != at.$2) return null;
    if (_intro || _busy || tableBusy || _card != null || reasonOpen || _deck != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final atLink = _deal.call == M4DoRefuseCall.link;
    if (!held) {
      if (atLink) {
        // His bodge: the coil of thick wire goes into the barrel.
        final m = _run.pick(null)!;
        await _deadly(m, at: _geoNow.bushingOf(_blown));
      } else {
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        await _watchWrong();
      }
      return;
    }
    _run.caught.add(M4DoRefuseLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (atLink) {
      unawaited(_sayChain([M4DoRefuseLines.callHeld, _task]));
    } else {
      _run.watch(right: true);
      // The praise is heard before the round's ◆ go on the table.
      await _sayChain([M4DoRefuseLines.callHeld]);
      if (!mounted || _ended) return;
      _afterWatch();
    }
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
        ? M4DoRefuseLines.tapWhy[_nudgeN++ % M4DoRefuseLines.tapWhy.length]
        : _nudge.next(_task);
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

  /// A slip: the card; on "বুঝেছি" the guide has put it right → [resume].
  Future<void> _slip(DoMistake m, {required VoidCallback resume}) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _resume = resume;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m4dore/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The yard freezes grey; the fault burns on at [at] in colour; then
  /// near-miss or death.
  Future<void> _deadly(DoMistake m, {required Offset at}) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/accident.wav', volume: 0.9);
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
    final speak = await SpokenOnce.first('m4dore/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4DoRefuseLines.deadlyWord : M4DoRefuseLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final go = _resume;
        setState(() {
          _card = null;
          _resume = null;
        });
        (go ?? _askStep)();
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
    await _say(
      !_run.passed ? M4DoRefuseLines.fail : (_quickBonus ? M4DoRefuseLines.quick : M4DoRefuseLines.allSet),
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
  bool get _onBench => !_run.done && _run.round == 1 && !_freeze;

  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_onBench) return LinemanMode.idle;
    return LinemanMode.hold;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M4DoRefuseGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = Rect.fromLTWH(_standX - geo.man / 4, geo.groundY - geo.man + 4, geo.man / 2, geo.man);
    final round = _run.round.clamp(0, 2);
    final rodUp = !_onBench;
    // The rod's head: where it was last used, or resting short of the blown fuse.
    final carrying = round == 2 && (_run.phase == M4DoRefusePhase.stand || _run.phase == M4DoRefusePhase.seat);
    final target = _aim ?? (round == 2 ? geo.hingeOf(_blown) : geo.ringOf(_blown) + const Offset(0, 40));
    final flip = target.dx < _standX;
    final tip0 = LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final hand = tb.topLeft + (flip ? Offset(tb.width - tip0.dx, tip0.dy) : tip0);
    final towards = target - hand;
    final tip = _touch ? target : hand + towards * (carrying ? 0.7 : 0.86);
    final butt = hand - towards / towards.distance * 26;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('yard'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M4DoRefuseWorldPainter(
                      geo: geo,
                      barrels: _run.barrels,
                      blown: round == 0 || (!_run.settles && (_run.phase == M4DoRefusePhase.watch || _run.phase == M4DoRefusePhase.done)) ? _blown : null,
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                key: const ValueKey('trainee'),
                duration: Duration(milliseconds: quiet ? 0 : 600),
                curve: Curves.easeInOut,
                left: tb.left,
                top: tb.top,
                width: tb.width,
                height: tb.height,
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
                            gloves: true,
                          ),
                          mode: _mode,
                          wake: _wake,
                          quiet: quiet,
                        ),
                      ),
                    ),
                    Positioned(
                      key: const ValueKey('shield'),
                      left: flip ? tb.width * 0.28 : tb.width * 0.36,
                      top: tb.height * 0.07,
                      width: tb.width * 0.36,
                      height: tb.height * 0.16,
                      child: const IgnorePointer(child: CustomPaint(painter: HsShieldPainter())),
                    ),
                  ],
                ),
              ),
              if (rodUp)
                Positioned.fill(
                  key: const ValueKey('rod'),
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: HsRodPainter(butt: butt, tip: tip, head: HsHead.puller, locked: true),
                    ),
                  ),
                ),
              if (rodUp && carrying)
                Positioned.fill(
                  key: const ValueKey('carry'),
                  child: IgnorePointer(
                    child: CustomPaint(painter: M4DoRefuseCarryPainter(at: tip, fresh: true)),
                  ),
                ),
              if (_flashAt != null && !_freeze)
                Positioned.fill(
                  key: ValueKey('flash-$_flashN'),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: Duration(milliseconds: _flashBig ? 900 : 600),
                      builder: (_, v, _) => v >= 1
                          ? const SizedBox.shrink()
                          : CustomPaint(
                              painter: HsArcPainter(at: _flashAt!, v: _flashBig ? v : 0.3 + 0.7 * v),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4DoRefuseLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => unawaited(_tapScene(d.localPosition)),
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: (d) => unawaited(_panEnd(d)),
          ),
        ),
      ),
      // The fault the bodge would not clear, in colour over the grey yard.
      if (_freeze && _deathAt != null)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(
                painter: HsArcPainter(at: _deathAt!, v: 0.25 + 0.6 * v, big: true),
              ),
            ),
          ),
        ),
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('round-${_run.round}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.round == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  M4DoRefuseBench get _bench => M4DoRefuseBench(
    link: _run.link,
    cleaned: _run.isFitted('clean'),
    buttonIn: _run.isFitted('button'),
    wrapped: _run.isFitted('wrap'),
    portChecked: _run.isFitted('port'),
    portBlocked: _deal.portBlocked,
  );

  // --- gesture hints (how to interact, never which answer) ----------------------
  /// The ground spots the stance sweep glides over (fixed, not the dealt fuse).
  static const _groundXs = [60.0, 150.0, 240.0, 320.0];

  HintSpec? _hintSpec() {
    final geo = _geoNow;
    HintSpec units() => HintSpec.sweep([for (var i = 0; i < 3; i++) geo.unitOf(i)], space: HintSpace.scene);
    switch (_run.phase) {
      case M4DoRefusePhase.spot || M4DoRefusePhase.openOthers || M4DoRefusePhase.lower || M4DoRefusePhase.closeOthers:
        return units();
      case M4DoRefusePhase.stand:
        return HintSpec.sweep([
          for (final x in _groundXs) Rect.fromCenter(center: Offset(x, geo.groundY + 14), width: 44, height: 28),
        ], space: HintSpace.scene);
      case M4DoRefusePhase.seat:
        return HintSpec.tap(geo.hingeOf(_blown), space: HintSpace.scene);
      case M4DoRefusePhase.push:
        // How to push (an upward swipe); the face button is the player's call.
        return HintSpec.swipe(geo.hingeOf(_blown) + const Offset(0, 40), toward: const Offset(0, -1), travel: 90, space: HintSpace.scene);
      case M4DoRefusePhase.pick:
        return HintSpec.sweepOver(_trayKeys.where((k) => k.currentContext != null));
      case M4DoRefusePhase.fit:
        final box = HintSpec.globalRectOf(_benchKey);
        final cloth = HintSpec.globalRectOf(_clothKey);
        final ready = HintSpec.globalRectOf(_readyKey);
        if (box == null || cloth == null || ready == null) return null;
        final parts = [
          M4DoRefuseBenchPainter.topContact.shift(box.topLeft),
          M4DoRefuseBenchPainter.bottomNut.shift(box.topLeft),
          M4DoRefuseBenchPainter.port.shift(box.topLeft),
          cloth,
          ready,
        ];
        return HintSpec.sweep([for (final i in _fitSweep) parts[i]]);
      case M4DoRefusePhase.decide || M4DoRefusePhase.watch || M4DoRefusePhase.done:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp || _deck != null;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null;
    final phase = _run.phase;
    final hintNow = handsOn && !_ended && !_busy && !tableBusy && !coworkerOnScreen && phase != M4DoRefusePhase.decide && phase != M4DoRefusePhase.watch && phase != M4DoRefusePhase.done;
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
              labels: M4DoRefuseLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hintSpec,
            hintWaiting: hintNow,
            hintKey: '${_run.round}-${phase.name}',
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(text: M4DoRefuseLines.docketBn(_deal.rating))),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && _onBench && _card == null && !reasonOpen && !coworkerOnScreen)
                Positioned(
                  key: const ValueKey('bench'),
                  left: 0,
                  right: 0,
                  top: pad.top + 160,
                  child: Center(
                    child: _Bench(
                      bench: _bench,
                      benchKey: _benchKey,
                      trayKeys: _trayKeys,
                      clothKey: _clothKey,
                      readyKey: _readyKey,
                      tray: phase == M4DoRefusePhase.pick ? _deal.tray : null,
                      fitting: phase == M4DoRefusePhase.fit,
                      enabled: handsOn,
                      quiet: quiet,
                      onPick: (item, at) => unawaited(_pick(item, at)),
                      onFit: (id, at) => unawaited(_fit(id, at)),
                    ),
                  ),
                ),
              if (handsOn && phase == M4DoRefusePhase.push)
                Positioned(
                  key: const ValueKey('hud-face'),
                  left: 12,
                  bottom: pad.bottom + 16,
                  child: _ToolButton(
                    icon: Icons.face_retouching_off_rounded,
                    label: _run.faceAside ? M4DoRefuseLines.faceAsideOn : M4DoRefuseLines.faceAside,
                    on: _run.faceAside,
                    enabled: _canPlay,
                    onTap: _turnFace,
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
                        : _deck != null
                        ? ChoiceDeck(
                            key: ValueKey('play-deck-${_deck!.name}-${_run.round}'),
                            options: _deckOpts,
                            onPick: (o, at) => unawaited(_deckPick(o, at)),
                            quiet: quiet,
                            muted: _muted,
                            picked: _deckPicked,
                          )
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.round}-${_run.slips}'),
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
                  line: M4DoRefuseLines.intro,
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
  const _DocketChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
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
            M4DoRefuseLines.docket,
            style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A)),
          ),
          Text(
            text,
            style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416)),
          ),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit once used.
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
          width: 104,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The link close-up: the barrel on the tarpaulin (tap its parts), the tray
/// of links while choosing, the cloth and "ব্যারেল তৈরি" while fitting.
class _Bench extends StatelessWidget {
  const _Bench({
    required this.bench,
    required this.benchKey,
    required this.trayKeys,
    required this.clothKey,
    required this.readyKey,
    required this.tray,
    required this.fitting,
    required this.enabled,
    required this.quiet,
    required this.onPick,
    required this.onFit,
  });
  final M4DoRefuseBench bench;
  final GlobalKey benchKey;
  final List<GlobalKey> trayKeys;
  final GlobalKey clothKey;
  final GlobalKey readyKey;
  final List<String?>? tray;
  final bool fitting;
  final bool enabled;
  final bool quiet;
  final void Function(String? item, Offset at) onPick;
  final void Function(String id, Offset at) onFit;

  Widget _part(Rect r, String label, String id) => Positioned.fromRect(
    rect: r,
    child: Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled && fitting ? (d) => onFit(id, d.globalPosition) : null,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const box = M4DoRefuseBenchPainter.size;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(
        scale: 0.88 + 0.12 * v,
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        width: 324,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xE60B1324),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.6),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: M4DoRefuseLines.benchLabel,
              child: SizedBox(
                key: benchKey,
                width: box.width,
                height: box.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(child: CustomPaint(painter: M4DoRefuseBenchPainter(bench: bench))),
                    ),
                    _part(M4DoRefuseBenchPainter.topContact, M4DoRefuseLines.topContact, 'button'),
                    _part(M4DoRefuseBenchPainter.bottomNut, M4DoRefuseLines.bottomContact, 'wrap'),
                    _part(M4DoRefuseBenchPainter.port, M4DoRefuseLines.port, 'port'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (tray != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < tray!.length; i++)
                    KeyedSubtree(
                      key: trayKeys[i],
                      child: _TrayTile(item: tray![i], enabled: enabled, onTap: (at) => onPick(tray![i], at)),
                    ),
                ],
              ),
            if (fitting)
              Row(
                children: [
                  _ToolButton(
                    key: clothKey,
                    icon: Icons.cleaning_services_rounded,
                    label: M4DoRefuseLines.cloth,
                    on: bench.cleaned,
                    enabled: enabled,
                    onTap: () => onFit('clean', Offset.zero),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      key: readyKey,
                      button: true,
                      label: M4DoRefuseLines.ready,
                      excludeSemantics: true,
                      child: DoBigButton(label: M4DoRefuseLines.ready, filled: true, onTapUp: (d) {
                        if (enabled) onFit('ready', d.globalPosition);
                      }),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// One tray item: a link with its rating tag, or the coil of thick wire.
class _TrayTile extends StatelessWidget {
  const _TrayTile({required this.item, required this.enabled, required this.onTap});
  final String? item;
  final bool enabled;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final label = item ?? M4DoRefuseLines.thickWire;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? (d) => onTap(d.globalPosition) : null,
        child: Container(
          width: 70,
          height: 84,
          decoration: BoxDecoration(
            color: const Color(0xFF1C2E4A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.6), width: 1.3),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 70,
                height: 52,
                child: CustomPaint(painter: M4DoRefuseTrayPainter(thick: item == null)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF7F1E1), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  label,
                  maxLines: 1,
                  style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
