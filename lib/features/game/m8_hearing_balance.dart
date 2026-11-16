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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_hearing_balance_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_hearing_balance_world.dart' show M8Geo, M8Look, M8Pose, M8Side, kM8HomeLooks, kM8OfficeLooks;

// Lesson 8.1 "WBERC পরিচিতি: রাজ্যের পাওয়ার বস" (pack do_8_1_b, engineType
// m8_hearing_balance, verb: pass the hearing mic to balance both sides).
// A public-hearing hall in a district town (game premise: the office has sent
// the trainee to help at the hearing as the mic runner).
//   1. A company officer brings the proposal file. Two equal drop targets are
//      always on screen: the commission bench and the company table's own
//      stamp pad. Bench = right (◆, then a reason); the stamp pad = a slip
//      (myth 1: the company only proposes) and the file walks itself over.
//   2. The hearing: hands rise on both sides at dealt times. The player drags
//      the mic to a raised hand; that speaker talks (a silent caption) and
//      every finished sentence drops a small weight (a home or an office icon,
//      no verdict) into his side's pan; the beam and a free pointer move.
//      Taking the mic away mid-sentence drops nothing. One side always raises
//      more hands, so serving the hands in the order they rise tilts the
//      balance; the hearing time is too short to hear everyone, so the player
//      must give the quieter side its turn.
//   3. Once, at a dealt time, a company officer leaves his seat with a 'নতুন
//      রেট' sheet toward his own table's stamp pad: dragging the sheet from
//      his hand onto the bench within 5 s is right; if he reaches the pad it
//      is a slip. No hint is shown for this moment (it would point at the
//      answer).
//   4. The ruling: when the hearing time ends the bench rules only if both
//      pans hold weight and the pointer rests near the centre. Tilted = a slip
//      and 30 s more hearing with fresh hands on the lighter side (no second
//      slip for the same tilt).
//   5. The appeal: an unhappy party waves the order; a 3-card deck asks where
//      to go. Wrong = a slip (a field decision deck, M8-8).
//
// Deadly: none (owner M8-1: 8.1 is slip-only). Slips: the file on the company
// pad, an officer who stamps a rate himself, a ruling with one side hardly
// heard, a wrong place for an appeal, listening to the coworker (X2/B1: the
// act he pushes is a slip here). Three slips strike out.
//
// Built on the shared level kit: guide first, the full scene
// (m8_hearing_balance_world.dart), corner guide; every right move puts its ◆
// on the table → the reason deck at once; the coworker once a play, dealt to
// the file drag or to the first mic drag (that control waits for him:
// holdForCoworker). Gesture hands (how, never what): on the file a nudge up,
// then a sweep over the bench and the stamp pad; at the mic a nudge up, then a
// sweep over every raised hand on both sides alike. None at the foul moment.

// ============================================================================
// Content
// ============================================================================

/// What a reason asks about.
enum M8Why { proposal, bothSides, foul }

/// Where the coworker is dealt (the control that waits for him).
enum M8CwOn { file, mic }

/// The fixed timing of the hearing (ms).
abstract final class M8Timing {
  /// One finished sentence (a caption held for a reading time).
  static const sentenceMs = 2800;

  /// The foul officer's walk to his pad.
  static const foulWindowMs = 5000;

  /// More hearing after a tilted ruling.
  static const extendMs = 30000;

  /// The mic lies in the aisle this long after listening to the coworker.
  static const micLockMs = 10000;

  /// The hearing bar is drawn in this many cells.
  static const barCells = 12;

  /// The beam may differ by this many weights and still count as level.
  static const tolerance = 1;
}

abstract final class M8HearingLines {
  static const title = 'জনশুনানির দাঁড়িপাল্লা';
  // DRAFT wording — owner (M6-12).
  static const intro = 'নতুন রেটের জনশুনানি — দুই পক্ষের কথাই যেন শোনা হয়।';

  // The guide's task now (tap him: the same task, a different way).
  static const askFile = 'কোম্পানির প্রস্তাবের ফাইল এসেছে — ফাইলটা ঠিক জায়গায় দিন।';
  static const askHear = 'শুনানি চলছে — হাত তোলা লোকের কাছে মাইক নিয়ে যান।';
  static const askAppeal = 'কোথায় যেতে বলবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askFile, askHear, askAppeal];

  // The guide's lines at the beats.
  static const rulingAnnounced = 'ভারসাম্য ঠিক — কমিশন নতুন ট্যারিফ অর্ডার ঘোষণা করল।';
  static const moreHearing = 'শুনানি আরও কিছুক্ষণ চলবে — পাল্লা সমান করুন।';
  static const hearingEnds = 'শুনানি শেষ হলো, তবে পাল্লা সমান হয়নি।';

  // What a worker reads on the scene.
  static const bannerLabel = 'WBERC · জনশুনানি';
  static const fileLabel = 'নতুন রেটের প্রস্তাব';
  static const sheetLabel = 'নতুন রেট';
  static const benchLabel = 'কমিশনের টেবিল';
  static const padLabel = 'কোম্পানির সিল-প্যাড';
  static const micLabel = 'মাইক';
  static const sceneLabel = 'জনশুনানির হল';
  static const orderLabel = 'নতুন ট্যারিফ অর্ডার';
  static const protest = 'এই রায় মানি না!';
  static String hand(int n) => 'হাত তোলা, $n';

  /// What the silent figures say, per side (captions only, never voiced).
  static const officeSays = <String>[
    'কয়লার দাম অনেক বেড়েছে।',
    'পোল আর তার বদলাতে খরচ বাড়ছে।',
    'কর্মীদের মজুরিও বেড়েছে।',
    'পুরনো রেটে খরচ উঠছে না।',
    'নতুন সাবস্টেশন বানাতে হচ্ছে।',
    'লাইনের লোকসান কমাতে খরচ লাগছে।',
    'কোম্পানি চালু রাখতে আয় দরকার।',
    'ট্রান্সফরমার মেরামতে টাকা লাগে।',
    'ঝড়ে লাইনের ক্ষতি সারাতে খরচ হয়েছে।',
    'বিদ্যুৎ কিনতে আমাদের বেশি দিতে হচ্ছে।',
    'ধার শোধ করতে হবে, তাই প্রস্তাব।',
    'মিটার আর ফিউজের দামও বেড়েছে।',
    'গ্রামে লাইন টানার খরচ অনেক।',
    'সেবা ভালো রাখতে টাকা চাই।',
  ];
  static const homeSays = <String>[
    'প্রতি মাসে বিল বেড়েই চলেছে।',
    'আমার আয় তো বাড়েনি।',
    'রেট বাড়লে সংসার চালাব কীভাবে?',
    'ছোট দোকানদারের অবস্থা খারাপ।',
    'কারেন্ট গেলে তো কেউ শোনে না।',
    'আগে সেবা ভালো করুন, তারপর রেট।',
    'বিল দেখে আমরা হিসেব পাই না।',
    'চাষের জল তুলতে খরচ বেড়ে যাবে।',
    'ছেলেমেয়েদের পড়ার খরচ আছে।',
    'গরিব পরিবারের কথাটাও ভাবুন।',
    'বিলের হিসেবটা সহজ করে বুঝিয়ে দিন।',
    'অল্প ইউনিটেও বিল অনেক আসে।',
    'ভোল্টেজ কম, তবু বিল বেশি।',
    'আমাদের কথাটাও শুনুন।',
  ];
  static List<String> says(M8Side s) => s == M8Side.office ? officeSays : homeSays;

  // The appeal deck: where to take an unhappy view of the order.
  static const appealRight = ['APTEL-এ যান — বিদ্যুতের মামলার বিশেষ আদালত', 'রায়ে খুশি না হলে আপিল করুন APTEL-এ'];
  static const appealWrong = [
    'কোম্পানির অফিসে গিয়ে রায় বদলে নিন',
    'সোজা সুপ্রিম কোর্টে গিয়ে মামলা করুন',
    'লাইনম্যানকে বলুন যেন রেট কমিয়ে দেয়',
    'থানায় গিয়ে রায়ের নামে অভিযোগ করুন',
    'নোটিশ বোর্ডে নিজের আপত্তি লিখে দিন',
  ];

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses (each question's cards about one length).
  static const whyQ = <M8Why, String>{
    M8Why.proposal: 'প্রস্তাবটা কমিশনের টেবিলে কেন দিলেন?',
    M8Why.bothSides: 'কেন দুই পক্ষকেই মাইক দিলেন?',
    M8Why.foul: 'কোম্পানির অফিসারকে রেটে সিল মারতে দিলেন না কেন?',
  };
  static const whyRight = <M8Why, List<String>>{
    M8Why.proposal: ['কোম্পানি শুধু প্রস্তাব দেয়, রেট ঘোষণা করে WBERC', 'খরচ বাড়লে কোম্পানি কমিশনে প্রস্তাব জমা দেয়'],
    M8Why.bothSides: ['দুই পক্ষের কথা দেখে WBERC — গ্রাহকের, কোম্পানিরও', 'সব দিক ভালো করে বিচার করেই রেট ঠিক হয়'],
    M8Why.foul: ['নতুন রেট ঘোষণা করে কমিশন, কোম্পানি নয়', 'কোম্পানি চাইলেই যা খুশি করতে পারে না'],
  };
  static const whyWrong = <M8Why, List<String>>{
    M8Why.proposal: [
      'কোম্পানি নিজের ইচ্ছামতো রেট ঠিক করে ফেলে',
      'অফিসাররা সিল মারলেই নতুন রেট চালু হয়ে যায়',
      'প্রস্তাব রাখার জন্য ওই টেবিলটাই খালি ছিল',
      'কমিশন শুধু ফাইল জমা রাখার একটা অফিস মাত্র',
      'রেট ঠিক করে দেন এলাকার লাইনম্যানরাই সব',
    ],
    M8Why.bothSides: [
      'যে আগে হাত তুলবে, তারই কথা শোনা হবে আগে',
      'কোম্পানির কথাই আসল, গ্রাহকের কথা শুধু বাড়তি',
      'গ্রাহকের কথা শুনলেই শুনানি যথেষ্ট হয়ে যায়',
      'যে জোরে চেঁচায়, তার কথাই ঠিক বলে ধরা হয়',
      'শুনানি শুধু নিয়ম রক্ষার একটা আনুষ্ঠানিকতা',
    ],
    M8Why.foul: [
      'সিলটা পুরনো হয়ে গিয়েছিল, তাই আটকালাম',
      'অফিসার ভুল টেবিলের দিকে হেঁটে যাচ্ছিলেন',
      'শুনানির সময় হলে হাঁটা একদম বারণ থাকে',
      'সিল মারার কাজ তো লাইনম্যানেরই থাকে',
      'কাগজটার রং অন্য রকমের মনে হচ্ছিল',
    ],
  };
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => [for (final l in whyWrong.values) ...l];

  // The careless coworker (one push a play, dealt to the file drag or the first
  // mic drag). His line is lesson myth 2 word for word + his shortcut (M8-14).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerMyth = CoworkerScript(
    line: 'WBERC শুধুমাত্র বড় অফিসারদের ব্যাপার, লাইনম্যানদের এতে কোনো ভূমিকা নেই — চলো, চা খেয়ে আসি।',
    exitLine: coworkerExit,
    right: ['না — সাপ্লাই কোড আর CEA-র সেফটি রেগুলেশন মেনেই কাজ করি', 'না — আইন না জানলে নিজের অজান্তেই অপরাধ করে ফেলতে পারি'],
    wrong: [
      'ঠিক বলেছ, এসব শুধু বড় অফিসারদের ব্যাপার, চলো চা খাই',
      'চলো, শুনানি অফিসাররাই সামলাবে, আমরা চা খেয়ে আসি',
      'রেট নিয়ে আমার কী যায় আসে, চলো চা খেয়ে আসি',
      'লাইনম্যানের এখানে কোনো কাজ নেই, মাইকটা রেখে চলো',
      'আইন নিয়ে মাথা ঘামানো আমাদের কাজ নয়, চলো যাই',
    ],
    asks: ['কী করবেন?', 'সাথীর কথা শুনবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const allCoworkers = [coworkerMyth];
  static const callHeld = 'ঠিক! আইন আর নিয়ম জানা লাইনম্যানের কাজেরই অংশ।';

  static const allSet = 'প্রস্তাব কমিশনে, দুই পক্ষের কথা শোনা, আপত্তির ঠিকানা APTEL — সব ঠিক!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — দুই পক্ষের কথাই শুনুন, রেট ঘোষণা করে WBERC।';

  // "আজ যা ধরলেন".
  static const caughtFile = 'প্রস্তাব যায় কমিশনে';
  static const caughtBoth = 'দুই পক্ষের কথা শুনেছেন';
  static const caughtRate = 'রেট ঘোষণা করে WBERC';
  static const caughtAppeal = 'আপত্তি হলে APTEL-এ';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new push (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        rulingAnnounced,
        moreHearing,
        hearingEnds,
        ...tapWhy,
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks.where((a) => !_oldAsks.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M8HearingMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M8HearingMistakes {
  static const _dir = 'assets/game/art/m8_hearing_balance';

  // DRAFT wording — owner (M6-12). No deadly mistake in 8.1 (M8-1).
  static const fileOnPad = DoMistake(
    key: '8.1/m8_hearing_balance/file-on-pad',
    textBn: 'কোম্পানি শুধু প্রস্তাব দেয়। জনশুনানি করে, সব দিক বিচার করে নতুন রেট ঘোষণা করে WBERC।',
    art: '$_dir/file_on_pad.svg',
    lessonPoint: 2,
  );
  static const officerStamp = DoMistake(
    key: '8.1/m8_hearing_balance/officer-stamp',
    textBn: 'কোম্পানি শুধু প্রস্তাব দেয় — নতুন রেট ঘোষণা করে WBERC।',
    art: '$_dir/officer_stamp.svg',
    lessonPoint: 2,
  );
  static const tilt = DoMistake(
    key: '8.1/m8_hearing_balance/tilt',
    textBn: 'একদিকে গ্রাহকের স্বার্থ, অন্যদিকে কোম্পানির স্থায়িত্ব — দুটোই মাপে WBERC।',
    art: '$_dir/tilt.svg',
    lessonPoint: 1,
  );
  static const wrongAppeal = DoMistake(
    key: '8.1/m8_hearing_balance/wrong-appeal',
    textBn: 'WBERC-এর রায়ে খুশি না হলে যেতে হয় APTEL-এ — বিদ্যুতের মামলার জন্য বিশেষ আদালত।',
    art: '$_dir/wrong_appeal.svg',
  );
  // Lesson 8.1 myth 2 and its reality (not a numbered point).
  static const listenMyth = DoMistake(
    key: '8.1/m8_hearing_balance/listen-myth',
    textBn: 'লাইনম্যানেরও WBERC জানা দরকার। সাপ্লাই কোড আর CEA-র সেফটি রেগুলেশন মেনেই রোজ কাজ করতে হয়।',
    art: '$_dir/listen_myth.svg',
  );

  static const List<DoMistake> all = [fileOnPad, officerStamp, tilt, wrongAppeal, listenMyth];
}

/// One person who raises a hand.
@immutable
class M8Hand {
  const M8Hand({required this.id, required this.side, required this.riseMs, required this.lines, required this.look, required this.seat, this.late = false});
  final int id;
  final M8Side side;

  /// When the hand goes up (hearing clock, ms).
  final int riseMs;

  /// What he says, one sentence at a time (a weight drops after each).
  final List<String> lines;
  final int look;
  final int seat;

  /// A fresh hand that comes only after a tilted ruling (drawn from its rise).
  final bool late;

  int get sentences => lines.length;
}

/// One dealt hearing.
@immutable
class M8Deal {
  const M8Deal({
    required this.hands,
    required this.loud,
    required this.hearingMs,
    required this.foulAtMs,
    required this.foulLook,
    required this.coworkerOn,
    required this.proposalLook,
    required this.appealSide,
    required this.appealLook,
    required this.appealRight,
  });
  final List<M8Hand> hands;

  /// The side that raises more hands (and speaks in shorter turns).
  final M8Side loud;
  final int hearingMs;
  final int foulAtMs;
  final int foulLook;
  final M8CwOn coworkerOn;
  final int proposalLook;

  /// Who is unhappy with the order, and how he looks.
  final M8Side appealSide;
  final int appealLook;

  /// Which of the two right phrasings the deck holds.
  final int appealRight;

  M8Side get quiet => loud == M8Side.office ? M8Side.home : M8Side.office;
  int sentencesOf(M8Side s) => hands.where((h) => h.side == s).fold(0, (a, h) => a + h.sentences);
}

/// A dealt hearing: the louder side (dealt) raises 7 hands of 1–2 sentences,
/// the quieter side 3–4 hands of 2–3. The louder side has at least 5 more
/// sentences, and the hearing time (~52–70 s) is too short to hear everyone,
/// so only a deliberate turn for the quiet side balances the pans.
M8Deal m8Deal(math.Random rng) {
  final loud = rng.nextBool() ? M8Side.office : M8Side.home;
  final quiet = loud == M8Side.office ? M8Side.home : M8Side.office;
  late List<int> qs;
  var q = 0;
  do {
    final n = 3 + rng.nextInt(2);
    qs = [for (var i = 0; i < n; i++) 2 + rng.nextInt(2)];
    q = qs.fold(0, (a, b) => a + b);
  } while (q > 9);
  final ls = List<int>.filled(7, 2);
  final cut = rng.nextInt(math.max(0, 14 - (q + 5)) + 1);
  final order = [for (var i = 0; i < 7; i++) i]..shuffle(rng);
  for (var i = 0; i < cut; i++) {
    ls[order[i]] = 1;
  }
  const s = M8Timing.sentenceMs;
  final hearingMs = ((2 * q * s * 1.12 + 14000) / 100).round() * 100;
  // Rise times: the loud side early and dense (the first three are always its),
  // the quiet side later and sparser.
  final loudTimes = <int>[
    for (var i = 0; i < 7; i++)
      i < 3 ? 400 + i * 1600 + rng.nextInt(600) : 5000 + ((i - 3) * hearingMs * 0.4 / 4).round() + rng.nextInt(1200),
  ];
  final quietTimes = <int>[
    for (var i = 0; i < qs.length; i++) (hearingMs * 0.2).round() + (i * hearingMs * 0.36 / qs.length).round() + rng.nextInt(1500),
  ];
  final seatsL = [for (var i = 0; i < M8Geo.seatsPerSide; i++) i]..shuffle(rng);
  final seatsQ = [for (var i = 0; i < M8Geo.seatsPerSide; i++) i]..shuffle(rng);
  final libL = [...M8HearingLines.says(loud)]..shuffle(rng);
  final libQ = [...M8HearingLines.says(quiet)]..shuffle(rng);
  var il = 0, iq = 0;
  final looksL = [for (var i = 0; i < (loud == M8Side.office ? kM8OfficeLooks : kM8HomeLooks).length; i++) i]..shuffle(rng);
  final looksQ = [for (var i = 0; i < (quiet == M8Side.office ? kM8OfficeLooks : kM8HomeLooks).length; i++) i]..shuffle(rng);
  final raw = <M8Hand>[];
  for (var i = 0; i < 7; i++) {
    raw.add(M8Hand(id: 0, side: loud, riseMs: loudTimes[i], lines: [for (var k = 0; k < ls[i]; k++) libL[il++ % libL.length]], look: looksL[i % looksL.length], seat: seatsL[i]));
  }
  for (var i = 0; i < qs.length; i++) {
    raw.add(M8Hand(id: 0, side: quiet, riseMs: quietTimes[i], lines: [for (var k = 0; k < qs[i]; k++) libQ[iq++ % libQ.length]], look: looksQ[i % looksQ.length], seat: seatsQ[i]));
  }
  raw.sort((a, b) => a.riseMs.compareTo(b.riseMs));
  final hands = [
    for (final (i, h) in raw.indexed) M8Hand(id: i, side: h.side, riseMs: h.riseMs, lines: h.lines, look: h.look, seat: h.seat),
  ];
  final appealSide = rng.nextBool() ? M8Side.office : M8Side.home;
  return M8Deal(
    hands: hands,
    loud: loud,
    hearingMs: hearingMs,
    foulAtMs: (hearingMs * (0.3 + rng.nextDouble() * 0.25)).round(),
    foulLook: rng.nextInt(kM8OfficeLooks.length),
    coworkerOn: rng.nextBool() ? M8CwOn.file : M8CwOn.mic,
    proposalLook: rng.nextInt(kM8OfficeLooks.length),
    appealSide: appealSide,
    appealLook: rng.nextInt(appealSide == M8Side.office ? kM8OfficeLooks.length : kM8HomeLooks.length),
    appealRight: rng.nextInt(M8HearingLines.appealRight.length),
  );
}

/// Where a drop of the file or the sheet went.
enum M8Target { bench, pad }

/// Where the play stands.
enum M8Phase { proposal, hearing, ruling, appeal, done }

/// The foul officer's moment.
enum M8Foul { none, walking, caught, stamped }

/// What the bench decided.
@immutable
class M8Ruling {
  const M8Ruling({required this.levelled, this.mistake});

  /// Both pans hold weight and the pointer rests near the centre.
  final bool levelled;

  /// The tilt slip (the first time only).
  final DoMistake? mistake;
}

/// The play state (pure logic; [advance] moves the hearing clock).
class M8HearingRun {
  M8HearingRun(this.deal, {math.Random? rng})
      : _rng = rng ?? math.Random(1),
        hands = [...deal.hands],
        hearingMs = deal.hearingMs;
  final M8Deal deal;
  final math.Random _rng;

  /// The hands (the dealt ones, and the fresh ones after a tilted ruling).
  final List<M8Hand> hands;

  M8Phase phase = M8Phase.proposal;
  int slips = 0;
  final List<String> caught = [];

  // The proposal.
  var fileDone = false;
  var fileRight = false;

  // The hearing.
  int hearingMs;
  int clockMs = 0;
  final Map<int, int> heard = {};
  int office = 0;
  int home = 0;
  int? speaking;
  var micAway = false;
  int sentenceMs = 0;
  int micLockMs = 0;
  int served = 0;
  var tiltSlipped = false;
  var extended = false;

  // The foul moment.
  M8Foul foul = M8Foul.none;
  int foulWalkMs = 0;

  /// A slip the clock itself caused (the officer reached his pad): the page
  /// shows its card and clears this.
  DoMistake? pendingSlip;

  // The appeal.
  var appealRight = false;

  bool get done => phase == M8Phase.done;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => slips == 0;
  bool get foulResolved => foul == M8Foul.caught || foul == M8Foul.stamped;

  int weightsOf(M8Side s) => s == M8Side.office ? office : home;

  /// Both pans hold weight and the beam is level (within one weight).
  bool get balanced => office >= 2 && home >= 2 && (office - home).abs() <= M8Timing.tolerance;

  /// The beam's tilt, radians (positive = the home pan lower).
  double get angle => ((home - office) * 0.1).clamp(-0.42, 0.42);

  /// The step of the hearing bar (0..barCells).
  int get step => (clockMs * M8Timing.barCells / math.max(1, hearingMs)).floor().clamp(0, M8Timing.barCells);

  M8Hand handById(int id) => hands.firstWhere((h) => h.id == id);
  int heardOf(M8Hand h) => heard[h.id] ?? 0;

  /// A hand is up: it has risen and still has something to say.
  bool raised(M8Hand h) => h.riseMs <= clockMs && heardOf(h) < h.sentences;
  List<M8Hand> get raisedHands => [for (final h in hands) if (raised(h)) h];

  /// Hands that are drawn (the dealt ones always; fresh ones from their rise).
  bool shown(M8Hand h) => !h.late || h.riseMs <= clockMs;

  bool get allHeard => hands.every((h) => heardOf(h) >= h.sentences);

  /// The mic is in a speaker's hand now (and was not taken away).
  bool get talking => speaking != null && !micAway;

  /// The hearing is over and the bench may rule.
  bool get ruleReady =>
      phase == M8Phase.hearing && foulResolved && speaking == null && (clockMs >= hearingMs || allHeard);

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  // --- the proposal ---------------------------------------------------------------
  /// The file dropped on the bench (right) or the company's own pad (a slip;
  /// the file then walks itself to the bench). Null when it is not the time.
  ({bool ready, DoMistake? mistake}) fileDrop(M8Target t) {
    if (phase != M8Phase.proposal || fileDone) return (ready: false, mistake: null);
    fileDone = true;
    if (t == M8Target.bench) {
      fileRight = true;
      _tag(M8HearingLines.caughtFile);
      return (ready: true, mistake: null);
    }
    return (ready: true, mistake: _slip(M8HearingMistakes.fileOnPad));
  }

  void startHearing() {
    if (phase == M8Phase.proposal && fileDone) phase = M8Phase.hearing;
  }

  // --- the hearing ----------------------------------------------------------------
  /// The mic dropped on a raised hand: he speaks (the sentence starts afresh).
  bool serve(int id) {
    if (phase != M8Phase.hearing || micLockMs > 0) return false;
    final h = handById(id);
    if (!raised(h)) return false;
    speaking = id;
    micAway = false;
    sentenceMs = 0;
    served++;
    return true;
  }

  /// The mic is lifted off while he talks: the sentence in progress is lost.
  void pullMic() {
    if (speaking == null) return;
    micAway = true;
    sentenceMs = 0;
  }

  /// The mic let go anywhere but on a raised hand: he stops, the mic is back.
  void dropAway() {
    if (micAway) {
      speaking = null;
      micAway = false;
    }
    sentenceMs = 0;
  }

  void _finishSentence() {
    final id = speaking!;
    final h = handById(id);
    heard[id] = heardOf(h) + 1;
    if (h.side == M8Side.office) {
      office++;
    } else {
      home++;
    }
    if (heardOf(h) >= h.sentences) speaking = null;
  }

  /// Moves the hearing on by [dt] ms (the page calls this only while nothing
  /// blocks the clock: no card, deck or coworker). True when something visible
  /// changed (a hand rose, a sentence ended, the bar stepped, the foul moved).
  bool advance(int dt) {
    if (phase != M8Phase.hearing) return false;
    var changed = false;
    if (micLockMs > 0) {
      micLockMs = math.max(0, micLockMs - dt);
      if (micLockMs == 0) changed = true;
    }
    if (speaking != null && !micAway) {
      sentenceMs += dt;
      while (speaking != null && sentenceMs >= M8Timing.sentenceMs) {
        sentenceMs -= M8Timing.sentenceMs;
        _finishSentence();
        changed = true;
      }
    }
    if (clockMs < hearingMs) {
      final prev = clockMs;
      final prevStep = step;
      clockMs = math.min(hearingMs, clockMs + dt);
      for (final h in hands) {
        if (h.riseMs > prev && h.riseMs <= clockMs) changed = true;
      }
      if (step != prevStep) changed = true;
      if (foul == M8Foul.none && clockMs >= deal.foulAtMs) {
        foul = M8Foul.walking;
        foulWalkMs = 0;
        changed = true;
      }
    }
    if (foul == M8Foul.walking) {
      foulWalkMs += dt;
      if (foulWalkMs >= M8Timing.foulWindowMs) {
        foul = M8Foul.stamped;
        pendingSlip = _slip(M8HearingMistakes.officerStamp);
      }
      changed = true;
    }
    return changed;
  }

  /// The sheet taken from the officer's hand and dropped: on the bench (right)
  /// or on the pad (he stamps: a slip). Null when no officer is walking.
  ({bool ready, DoMistake? mistake}) sheetDrop(M8Target t) {
    if (phase != M8Phase.hearing || foul != M8Foul.walking) return (ready: false, mistake: null);
    if (t == M8Target.bench) {
      foul = M8Foul.caught;
      _tag(M8HearingLines.caughtRate);
      return (ready: true, mistake: null);
    }
    foul = M8Foul.stamped;
    return (ready: true, mistake: _slip(M8HearingMistakes.officerStamp));
  }

  // --- the ruling -----------------------------------------------------------------
  /// The bench rules: level = the order is announced; tilted the first time =
  /// a slip and 30 s more with fresh hands on the lighter side; tilted again =
  /// no second slip, the order is announced without the praise.
  M8Ruling rule() {
    if (!ruleReady) return const M8Ruling(levelled: false);
    if (balanced) {
      phase = M8Phase.ruling;
      _tag(M8HearingLines.caughtBoth);
      _tag(M8HearingLines.caughtRate);
      return const M8Ruling(levelled: true);
    }
    if (!tiltSlipped) {
      tiltSlipped = true;
      extended = true;
      final m = _slip(M8HearingMistakes.tilt);
      _addFreshHands();
      hearingMs += M8Timing.extendMs;
      return M8Ruling(levelled: false, mistake: m);
    }
    phase = M8Phase.ruling;
    return const M8Ruling(levelled: false);
  }

  /// Fresh hands for the side(s) that fell short, enough to level the pans.
  void _addFreshHands() {
    final target = math.max(math.max(office, home), 2);
    final lighter = home < office ? M8Side.home : (office < home ? M8Side.office : deal.quiet);
    for (final side in M8Side.values) {
      final count = weightsOf(side);
      var gain = target - count;
      if (side == lighter) gain += 1;
      if (gain <= 0) continue;
      final used = {for (final h in hands) if (h.side == side) h.seat};
      final free = [for (var i = 0; i < M8Geo.seatsPerSide; i++) if (!used.contains(i)) i];
      final lib = M8HearingLines.says(side);
      var at = clockMs + 1500;
      var n = 0;
      while (gain > 0 && free.isNotEmpty) {
        final k = math.min(gain, 3);
        gain -= k;
        final looks = side == M8Side.office ? kM8OfficeLooks.length : kM8HomeLooks.length;
        hands.add(M8Hand(
          id: hands.length,
          side: side,
          riseMs: at,
          lines: [for (var j = 0; j < k; j++) lib[_rng.nextInt(lib.length)]],
          look: _rng.nextInt(looks),
          seat: free.removeAt(0),
          late: true,
        ));
        at += 2500;
        n++;
      }
      if (n == 0) continue;
    }
  }

  // --- the appeal -----------------------------------------------------------------
  void startAppeal() {
    if (phase == M8Phase.ruling) phase = M8Phase.appeal;
  }

  /// A card of the where-to-go deck: right = the order stands and the play is
  /// done; wrong = a slip (a field decision, M8-8).
  DoMistake? appealPick({required bool right}) {
    if (phase != M8Phase.appeal) return null;
    if (right) {
      appealRight = true;
      phase = M8Phase.done;
      _tag(M8HearingLines.caughtAppeal);
      return null;
    }
    return _slip(M8HearingMistakes.wrongAppeal);
  }

  /// Listened to the coworker (his myth-2 line: a slip here, never deadly). The
  /// mic then lies in the aisle for 10 s of hearing.
  DoMistake pushSlip() {
    micLockMs = M8Timing.micLockMs;
    return _slip(M8HearingMistakes.listenMyth);
  }
}

/// The quick bonus: a little under a clean play (~85 %, rounded to 10 s).
/// ms (a clean play; the intro is not counted):
///   the file + its reason ≈ 12000, the hearing ≈ 52000–70000 (its clock only
///   runs while nothing blocks it), the foul reason ≈ 8000, the ruling and its
///   reason ≈ 9000, the appeal ≈ 7000, the coworker once ≈ 10000
///                                                              ≈ 105000
/// 85 % ≈ 90000 (a builder's estimate; owner may tune).
const m8HearingBalanceQuickMs = 90000;

@immutable
class M8HearingBalancePack {
  const M8HearingBalancePack({required this.id, required this.titleBn, this.quickMs = m8HearingBalanceQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8HearingBalancePack> m8HearingBalancePacks = {
  'do_8_1_b': M8HearingBalancePack(id: 'do_8_1_b', titleBn: M8HearingLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8HearingProbe {
  static M8HearingRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M8HearingBalancePage extends StatefulWidget {
  const M8HearingBalancePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8HearingBalancePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8HearingBalancePage> createState() => _M8HearingBalancePageState();
}

class _M8HearingBalancePageState extends State<M8HearingBalancePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _HearingRunPage(
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

/// What follows the reason that is open now.
enum _After { none, proposal, foul, ruling }

class _HearingRunPage extends ConsumerStatefulWidget {
  const _HearingRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8HearingBalancePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_HearingRunPage> createState() => _HearingRunPageState();
}

class _HearingRunPageState extends ConsumerState<_HearingRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8HearingRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  VoidCallback? _afterCard;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  var _dragging = false;
  Timer? _ticker;
  _After _after = _After.none;

  /// The order is announced (a caption at the bench) / the appeal beat's deck.
  var _announced = false;
  List<ChoiceOption> _deck = const [];
  final Set<String> _deckWrong = {};
  String? _deckPicked;
  int _deckN = 0;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _fileKey = GlobalKey();
  final _benchKey = GlobalKey();
  final _padKey = GlobalKey();
  final _micKey = GlobalKey();
  final Map<int, GlobalKey> _handKeys = {};
  int _hintN = 0;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _run = M8HearingRun(m8Deal(widget.rng), rng: widget.rng);
    M8HearingProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  GlobalKey _handKey(int id) => _handKeys.putIfAbsent(id, GlobalKey.new);

  @override
  void dispose() {
    disposeCoworker();
    _ticker?.cancel();
    _chain++;
    if (identical(M8HearingProbe.run, _run)) M8HearingProbe.run = null;
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

  bool get _blocked => _intro || _card != null || coworkerOpen || reasonOpen || tableBusy || _ended || _ownDeckUp;
  bool get _canPlay => !_blocked;

  bool get _ownDeckUp => _deck.isNotEmpty && _run.phase == M8Phase.appeal && _card == null && !_ended;

  String get _task => switch (_run.phase) {
        M8Phase.proposal => M8HearingLines.askFile,
        M8Phase.hearing => M8HearingLines.askHear,
        _ => M8HearingLines.askAppeal,
      };

  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([M8HearingLines.askFile]));
    if (_run.deal.coworkerOn == M8CwOn.file) scheduleCoworker();
  }

  // --- the hearing clock -------------------------------------------------------
  void _beginHearing() {
    if (!mounted || _ended) return;
    setState(() {
      _run.startHearing();
      _wake++;
      _steps++;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _onTick());
    unawaited(_sayChain([M8HearingLines.askHear]));
    if (_run.deal.coworkerOn == M8CwOn.mic && !coworkerDone && !coworkerDue) scheduleCoworker();
  }

  void _onTick() {
    if (!mounted || _ended || _blocked || _run.phase != M8Phase.hearing) return;
    final up = _run.raisedHands.length;
    final weights = _run.office + _run.home;
    final changed = _run.advance(100);
    if (changed || _run.foul == M8Foul.walking) {
      setState(() => _wake++);
      if (_run.office + _run.home > weights) {
        _cue('sounds/intro/click.ogg', volume: 0.4);
      } else if (_run.raisedHands.length > up) {
        _cue('sounds/intro/tick.ogg', volume: 0.3);
      }
    }
    final slip = _run.pendingSlip;
    if (slip != null) {
      _run.pendingSlip = null;
      unawaited(_mistake(slip, Offset(MediaQuery.sizeOf(context).width / 2, 200)));
      return;
    }
    if (_run.ruleReady) unawaited(_ruling());
  }

  /// The coworker's moment: the file drag or the first mic drag waits for him.
  bool _waitForHim(M8CwOn on) => _run.deal.coworkerOn == on && holdForCoworker();

  // --- the proposal --------------------------------------------------------------
  void _fileDrop(M8Target t, Offset at) {
    _dragging = false;
    if (!_canPlay || _run.phase != M8Phase.proposal || _run.fileDone) return;
    if (_waitForHim(M8CwOn.file)) return;
    final r = _run.fileDrop(t);
    if (!r.ready) return;
    setState(() {
      _steps++;
      _wake++;
    });
    if (r.mistake != null) {
      _afterCard = _beginHearing;
      unawaited(_mistake(r.mistake!, at));
      return;
    }
    unawaited(_proposalRight());
  }

  Future<void> _proposalRight() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _after = _After.proposal;
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(M8HearingLines.whyRight[M8Why.proposal]!, M8HearingLines.whyWrong[M8Why.proposal]!, widget.rng),
      question: M8HearingLines.whyQ[M8Why.proposal]!,
      stillValid: () => !_ended,
    ));
  }

  // --- the hearing: the mic --------------------------------------------------------
  void _micPicked() {
    _dragging = true;
    if (_run.talking) {
      setState(() {
        _run.pullMic();
        _wake++;
      });
    }
  }

  void _micLetGo(bool accepted) {
    _dragging = false;
    if (accepted) return;
    if (_run.speaking != null) {
      setState(() {
        _run.dropAway();
        _wake++;
      });
    }
  }

  void _serve(M8Hand h) {
    _dragging = false;
    if (!_canPlay || _run.phase != M8Phase.hearing) return;
    if (_run.served == 0 && _waitForHim(M8CwOn.mic)) {
      // He cuts in first; the mic goes back (the sentence was not started).
      setState(() {
        _run.dropAway();
        _wake++;
      });
      return;
    }
    if (!_run.serve(h.id)) {
      setState(() {
        _run.dropAway();
        _wake++;
      });
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _steps++;
      _wake++;
    });
  }

  // --- the foul moment -------------------------------------------------------------
  void _sheetDrop(M8Target t, Offset at) {
    _dragging = false;
    if (!_canPlay) return;
    final r = _run.sheetDrop(t);
    if (!r.ready) return;
    setState(() {
      _steps++;
      _wake++;
    });
    if (r.mistake != null) {
      unawaited(_mistake(r.mistake!, at));
      return;
    }
    unawaited(_foulRight());
  }

  Future<void> _foulRight() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _after = _After.foul;
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(M8HearingLines.whyRight[M8Why.foul]!, M8HearingLines.whyWrong[M8Why.foul]!, widget.rng),
      question: M8HearingLines.whyQ[M8Why.foul]!,
      stillValid: () => !_ended,
    ));
  }

  // --- the ruling ---------------------------------------------------------------------
  Future<void> _ruling() async {
    if (!_run.ruleReady || !mounted || _ended) return;
    final r = _run.rule();
    setState(() {
      _wake++;
      _steps++;
    });
    if (r.mistake != null) {
      _afterCard = () {
        setState(() => _wake++);
        unawaited(_sayChain([M8HearingLines.moreHearing, _task]));
      };
      unawaited(_mistake(r.mistake!, Offset(MediaQuery.sizeOf(context).width / 2, 300)));
      return;
    }
    if (!r.levelled) {
      // Tilted again: no second slip; the order comes without the praise.
      setState(() => _announced = true);
      unawaited(_sayChain([M8HearingLines.hearingEnds]));
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 600 : 2200), () {
        if (mounted && !_ended) _startAppeal();
      }));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() => _announced = true);
    _after = _After.ruling;
    putOnTable(20);
    unawaited(askReason(
      deal: () => dealChoices(M8HearingLines.whyRight[M8Why.bothSides]!, M8HearingLines.whyWrong[M8Why.bothSides]!, widget.rng),
      question: M8HearingLines.whyQ[M8Why.bothSides]!,
      stillValid: () => !_ended,
    ));
  }

  // --- the appeal ------------------------------------------------------------------------
  void _startAppeal() {
    if (!mounted || _ended) return;
    setState(() {
      _run.startAppeal();
      _deckN++;
      _deckWrong.clear();
      _deckPicked = null;
      _deck = dealChoices([M8HearingLines.appealRight[_run.deal.appealRight]], M8HearingLines.appealWrong, widget.rng);
      _wake++;
      _steps++;
    });
    unawaited(_sayChain([M8HearingLines.askAppeal]));
  }

  void _pickAppeal(ChoiceOption o, Offset at) {
    if (!_ownDeckUp || _deckPicked != null) return;
    final m = _run.appealPick(right: o.correct);
    if (m != null) {
      setState(() {
        _deckWrong.add(o.textBn);
        _wake++;
      });
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    setState(() => _deckPicked = o.textBn);
    unawaited(_levelDelta(10, at, mood: GuideMood.glad));
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 600 : 1300), () {
      if (mounted && !_ended) unawaited(_finish());
    }));
  }

  // --- the shared success beat (ReasonTable) --------------------------------------------
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
    _after = _After.none;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (!mounted || _ended) return;
      switch (after) {
        case _After.proposal:
          _beginHearing();
        case _After.foul:
          setState(() {
            _wake++;
            _steps++;
          });
          unawaited(_sayChain([_task]));
        case _After.ruling:
          _startAppeal();
        case _After.none:
          break;
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------------------
  @override
  CoworkerScript get coworkerScript => M8HearingLines.coworkerMyth;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final on = _run.deal.coworkerOn;
    if (on == M8CwOn.file) {
      if (_run.phase != M8Phase.proposal || _run.fileDone) return null;
    } else {
      if (_run.phase.index > M8Phase.hearing.index || _run.served > 0) return null;
      if (_run.phase != M8Phase.hearing) return false;
    }
    if (_intro || _card != null || tableBusy || _dragging || _run.talking) return false;
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
    _run.caught.add(M8HearingLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8HearingLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8HearingLines.tapWhy[_nudgeN++ % M8HearingLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  void _tapScene() {
    if (!_canPlay) return;
    _hints.missTap();
  }

  // --- mistakes -------------------------------------------------------------------------------
  Future<void> _mistake(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _ticker?.cancel();
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
    final speak = await SpokenOnce.first('m8hearing/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    final then = _afterCard;
    _afterCard = null;
    setState(() {
      _card = null;
      _wake++;
    });
    if (then != null) {
      then();
    } else {
      unawaited(_sayChain([_task]));
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
    _ticker?.cancel();
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
    await _say(!_run.passed ? M8HearingLines.fail : (_quickBonus ? M8HearingLines.quick : M8HearingLines.allSet),
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

  // --- the scene ----------------------------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what. The file in hand: a nudge
  /// straight up on the file, next idle a sweep over the bench and the stamp
  /// pad alike. Hands waiting with the mic idle: a nudge straight up on the
  /// mic, next idle a sweep over every raised hand on both sides alike. None
  /// at the foul moment (it would point at the answer).
  HintSpec? _hint() {
    final n = _hintN++;
    switch (_run.phase) {
      case M8Phase.proposal:
        if (n.isEven) return HintSpec.dragFrom(_fileKey, toward: const Offset(0, -1), travel: 56);
        return HintSpec.sweepOver([_benchKey, _padKey]);
      case M8Phase.hearing:
        final up = _run.raisedHands;
        if (up.length < 2 || n.isEven) return HintSpec.dragFrom(_micKey, toward: const Offset(0, -1), travel: 64);
        return HintSpec.sweepOver([for (final h in up) _handKey(h.id)]);
      default:
        return null;
    }
  }

  M8Look _lookOf(M8Hand h) => (h.side == M8Side.office ? kM8OfficeLooks : kM8HomeLooks)[h.look];

  M8Pose _poseOf(M8Hand h) {
    if (_run.speaking == h.id && !_run.micAway) return M8Pose.speaking;
    if (_run.raised(h)) return M8Pose.raised;
    return M8Pose.seated;
  }

  /// What the caption bubble shows now, and where its tail points.
  ({String text, double x})? _caption(M8Geo geo) {
    if (_intro) return null;
    if (_run.phase == M8Phase.appeal) {
      return (text: M8HearingLines.protest, x: geo.protester.center.dx);
    }
    if (_announced && (_run.phase == M8Phase.ruling)) {
      return (text: M8HearingLines.orderLabel, x: geo.bench.center.dx);
    }
    final id = _run.speaking;
    if (id != null && !_run.micAway && _run.phase == M8Phase.hearing) {
      final h = _run.handById(id);
      final i = math.min(_run.heardOf(h), h.sentences - 1);
      return (text: h.lines[i], x: geo.seat(h.side, h.seat).center.dx);
    }
    return null;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M8Geo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final proposal = _run.phase == M8Phase.proposal && !_run.fileDone;
    final hearing = _run.phase == M8Phase.hearing;
    final walking = hearing && _run.foul == M8Foul.walking;
    final fileLive = proposal && _canPlay;
    final sheetLive = walking && _canPlay;
    final cap = _caption(geo);
    final handsLive = hearing && _canPlay;
    final micLocked = hearing && _run.micLockMs > 0;
    final micRect = _run.speaking != null && hearing ? geo.micAt(geo.seat(_run.handById(_run.speaking!).side, _run.handById(_run.speaking!).seat)) : geo.micHome;
    final foulT = (_run.foulWalkMs / M8Timing.foulWindowMs).clamp(0.0, 1.0);
    final foulRect = Rect.lerp(geo.foulStart, geo.foulEnd, foulT)!;
    final showMic = hearing || proposal;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: RepaintBoundary(child: CustomPaint(painter: M8HallPainter(geo: geo))),
      ),
      Positioned.fromRect(
        key: const ValueKey('balance'),
        rect: geo.balance,
        child: IgnorePointer(child: _Balance(angle: _run.angle, office: _run.office, home: _run.home, quiet: quiet)),
      ),
      Positioned.fromRect(
        key: const ValueKey('time-bar'),
        rect: geo.timeBar,
        child: IgnorePointer(child: _TimeBar(step: _run.phase == M8Phase.proposal ? 0 : _run.step)),
      ),
      // A tap on the hall that is nothing (a miss, for the hint).
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8HearingLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tapScene),
        ),
      ),
      // The commission bench and the company's own stamp pad: always there, equal.
      Positioned.fromRect(
        key: const ValueKey('bench-target'),
        rect: geo.bench,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (d) => (d.data == 'file' && fileLive) || (d.data == 'sheet' && sheetLive),
          onAcceptWithDetails: (d) => d.data == 'file' ? _fileDrop(M8Target.bench, d.offset) : _sheetDrop(M8Target.bench, d.offset),
          builder: (_, cand, _) => Semantics(
            key: _benchKey,
            label: M8HearingLines.benchLabel,
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: cand.isNotEmpty ? Border.all(color: SlmColors.gold300, width: 2.2) : null),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('pad-target'),
        rect: geo.padTarget,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (d) => (d.data == 'file' && fileLive) || (d.data == 'sheet' && sheetLive),
          onAcceptWithDetails: (d) => d.data == 'file' ? _fileDrop(M8Target.pad, d.offset) : _sheetDrop(M8Target.pad, d.offset),
          builder: (_, cand, _) => Semantics(
            key: _padKey,
            label: M8HearingLines.padLabel,
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: cand.isNotEmpty ? Border.all(color: SlmColors.gold300, width: 2.2) : null),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
      // The speakers: seated until a hand goes up (the same figures all play).
      for (final h in _run.hands)
        if (_run.shown(h))
          Positioned.fromRect(
            key: ValueKey('hand-${h.id}'),
            rect: geo.seat(h.side, h.seat),
            child: DragTarget<String>(
              onWillAcceptWithDetails: (d) => d.data == 'mic' && handsLive && _run.raised(h),
              onAcceptWithDetails: (_) => _serve(h),
              builder: (_, cand, _) => Semantics(
                key: _handKey(h.id),
                label: _run.raised(h) ? M8HearingLines.hand(h.id + 1) : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: cand.isNotEmpty && _run.raised(h) ? Border.all(color: SlmColors.gold300, width: 2) : null),
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: M8PersonPainter(look: _lookOf(h), pose: _poseOf(h), faceLeft: h.side == M8Side.home), size: Size.infinite),
                    ),
                  ),
                ),
              ),
            ),
          ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      // The officer who brings the proposal.
      if (proposal)
        Positioned.fromRect(
          key: const ValueKey('proposal-officer'),
          rect: geo.proposalOfficer,
          child: IgnorePointer(child: CustomPaint(painter: M8PersonPainter(look: kM8OfficeLooks[_run.deal.proposalLook], pose: M8Pose.standing))),
        ),
      if (proposal)
        Positioned.fromRect(
          key: const ValueKey('file-box'),
          rect: geo.fileHome,
          child: Draggable<String>(
            key: _fileKey,
            data: 'file',
            maxSimultaneousDrags: fileLive ? 1 : 0,
            onDragStarted: () => _dragging = true,
            onDragEnd: (_) => _dragging = false,
            feedback: Material(color: Colors.transparent, child: SizedBox(width: 46, height: 50, child: _Paper(label: 'প্রস্তাব', lifted: true))),
            childWhenDragging: const Opacity(opacity: 0.3, child: _Paper(label: 'প্রস্তাব')),
            child: Semantics(label: M8HearingLines.fileLabel, button: true, child: const _Paper(label: 'প্রস্তাব')),
          ),
        ),
      // The foul officer walking to his own pad, the sheet in his hand.
      if (walking)
        AnimatedPositioned(
          key: const ValueKey('foul-officer'),
          duration: const Duration(milliseconds: 100),
          left: foulRect.left,
          top: foulRect.top,
          width: foulRect.width,
          height: foulRect.height,
          child: IgnorePointer(child: CustomPaint(painter: M8PersonPainter(look: kM8OfficeLooks[_run.deal.foulLook], pose: M8Pose.walking, faceLeft: true, holding: true))),
        ),
      if (walking)
        AnimatedPositioned(
          key: const ValueKey('foul-sheet'),
          duration: const Duration(milliseconds: 100),
          left: foulRect.left - 12,
          top: foulRect.top + 18,
          width: 44,
          height: 44,
          child: Draggable<String>(
            data: 'sheet',
            maxSimultaneousDrags: sheetLive ? 1 : 0,
            onDragStarted: () => _dragging = true,
            onDragEnd: (_) => _dragging = false,
            feedback: Material(color: Colors.transparent, child: SizedBox(width: 46, height: 50, child: _Paper(label: M8HearingLines.sheetLabel, lifted: true))),
            childWhenDragging: const SizedBox.shrink(),
            child: Semantics(label: M8HearingLines.sheetLabel, button: true, child: const SizedBox.expand()),
          ),
        ),
      // The unhappy party who waves the order.
      if (_run.phase == M8Phase.appeal)
        Positioned.fromRect(
          key: const ValueKey('protester'),
          rect: geo.protester,
          child: IgnorePointer(
            child: CustomPaint(
                painter: M8PersonPainter(
              look: (_run.deal.appealSide == M8Side.office ? kM8OfficeLooks : kM8HomeLooks)[_run.deal.appealLook],
              pose: M8Pose.raised,
              faceLeft: true,
            )),
          ),
        ),
      // The mic: at the trainee's side, or held up at the speaker; lying in the
      // aisle (out of reach) while the hearing waits for a trainee who walked out.
      if (showMic)
        Positioned.fromRect(
          key: const ValueKey('mic'),
          rect: micLocked ? geo.micHome.shift(const Offset(-6, 18)) : micRect,
          child: micLocked
              ? Transform.rotate(angle: 1.3, child: Semantics(label: M8HearingLines.micLabel, child: const CustomPaint(painter: M8MicPainter(ghost: true), size: Size.infinite)))
              : Draggable<String>(
                  key: _micKey,
                  data: 'mic',
                  maxSimultaneousDrags: hearing && handsLive ? 1 : 0,
                  onDragStarted: _micPicked,
                  onDragCompleted: () => _micLetGo(true),
                  onDraggableCanceled: (_, _) => _micLetGo(false),
                  feedback: const Material(color: Colors.transparent, child: SizedBox(width: 44, height: 44, child: CustomPaint(painter: M8MicPainter()))),
                  childWhenDragging: const CustomPaint(painter: M8MicPainter(ghost: true), size: Size.infinite),
                  child: Semantics(label: M8HearingLines.micLabel, button: true, child: const CustomPaint(painter: M8MicPainter(), size: Size.infinite)),
                ),
        ),
      if (cap != null)
        Positioned.fromRect(
          key: const ValueKey('bubble-box'),
          rect: geo.bubble,
          child: IgnorePointer(child: _CaptionBubble(key: ValueKey('bubble-${cap.text}-${_run.heard.length}'), text: cap.text, quiet: quiet, tailX: (cap.x - geo.bubble.left).clamp(24.0, 320.0))),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp || _ownDeckUp;
    final hearing = _run.phase == M8Phase.hearing;
    final handsOn = playing && _card == null && !deckUp && !coworkerOpen && !tableBusy;
    final hintOn = handsOn &&
        ((_run.phase == M8Phase.proposal && !_run.fileDone) ||
            (hearing && _run.foul != M8Foul.walking && !_run.talking && _run.micLockMs == 0 && _run.raisedHands.isNotEmpty));
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
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: hintOn,
            hintKey: '${_run.phase.name}/$_steps/${_run.served}',
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
                                key: ValueKey('appeal-deck-$_deckN'),
                                options: _deck,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _deckWrong,
                                picked: _deckPicked,
                                onPick: _pickAppeal,
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : 4),
                  onLeft: coworkerFromRight,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  line: M8HearingLines.intro,
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

/// The balance: the beam and the pointer move on a new weight, then hold still.
class _Balance extends StatelessWidget {
  const _Balance({required this.angle, required this.office, required this.home, required this.quiet});
  final double angle;
  final int office;
  final int home;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    Widget paint(double a, double p) => RepaintBoundary(child: CustomPaint(painter: M8BalancePainter(angle: a, pointer: p, office: office, home: home), size: Size.infinite));
    if (quiet) return paint(angle, angle * 1.6);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: angle, end: angle),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (_, a, _) => TweenAnimationBuilder<double>(
        tween: Tween(begin: angle * 1.6, end: angle * 1.6),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.elasticOut,
        builder: (_, p, _) => paint(a, p),
      ),
    );
  }
}

/// The hearing time left, as cells inlaid in the bench front.
class _TimeBar extends StatelessWidget {
  const _TimeBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TimeBarPainter(step));
  }
}

class _TimeBarPainter extends CustomPainter {
  const _TimeBarPainter(this.step);
  final int step;

  @override
  void paint(Canvas c, Size s) {
    final n = M8Timing.barCells;
    final w = (s.width - (n - 1) * 2) / n;
    for (var i = 0; i < n; i++) {
      final left = i >= step;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * (w + 2), 0, w, s.height), const Radius.circular(2)), Paint()..color = left ? const Color(0xFFF2D58A) : const Color(0xFF4A3220));
    }
  }

  @override
  bool shouldRepaint(_TimeBarPainter old) => old.step != step;
}

/// A speaker's words, as a caption bubble with a tail toward him.
class _CaptionBubble extends StatelessWidget {
  const _CaptionBubble({super.key, required this.text, required this.quiet, required this.tailX});
  final String text;
  final bool quiet;
  final double tailX;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
          ),
          child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, height: 1.3, color: const Color(0xFF2A2018))),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(padding: EdgeInsets.only(left: tailX - 8), child: const CustomPaint(size: Size(16, 9), painter: _TailPainter())),
        ),
      ],
    );
    return Semantics(
      label: text,
      child: Align(
        alignment: Alignment.topCenter,
        child: quiet
            ? body
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.scale(scale: v, alignment: Alignment.topCenter, child: child),
                child: body,
              ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Path()
      ..moveTo(0, -2)
      ..lineTo(s.width, -2)
      ..lineTo(s.width / 2, s.height)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFFFFFBF0));
    final line = Paint()
      ..color = const Color(0xFF8A6A3C)
      ..strokeWidth = 2;
    c.drawLine(const Offset(0, 0), Offset(s.width / 2, s.height), line);
    c.drawLine(Offset(s.width, 0), Offset(s.width / 2, s.height), line);
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}

/// A paper: the proposal file or the officer's rate sheet.
class _Paper extends StatelessWidget {
  const _Paper({required this.label, this.lifted = false});
  final String label;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
        boxShadow: [BoxShadow(color: const Color(0x55000000), blurRadius: lifted ? 9 : 4, offset: Offset(0, lifted ? 6 : 2))],
      ),
      child: Column(
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16)))),
          const Divider(height: 5, thickness: 1, color: Color(0x668A6A3C)),
          for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(top: 3), child: Container(height: 2, color: const Color(0x553A2A16))),
        ],
      ),
    );
  }
}
