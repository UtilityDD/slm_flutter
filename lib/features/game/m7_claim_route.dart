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
import 'm7_claim_route_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm7_claim_route_world.dart' show M7ClaimGeo, M7ClaimMap, M7ClaimNode, M7Slot, m7ClaimLayouts, m7RoadPoint;

// Lesson 7.2 "ওয়ার্কম্যান কম্পেনসেশন অ্যাক্ট: দুর্ঘটনার পর আপনার অধিকার",
// কাজ 2 "দাবির পথ" (pack do_7_2_b, engineType m7_claim_route). The module's
// only town-map route level: an injured worker (arm in a sling) is dragged
// along the roads of a small town; the lesson's four steps (point 4) are the
// stops, never marked:
//
//  জানানো (ধাপ ১): the ambulance carries him on its own (treatment is never
//    delayed); his phone glows — tap it and hold the call button on the
//    supervisor / কর্তৃপক্ষ contact before the ambulance arrives. No call by
//    then = slip (late informing); he calls from bed after the card.
//  ডাক্তারি রিপোর্ট (ধাপ ২): drag him to the সরকারি হাসপাতাল or the
//    কোম্পানির ডিসপেন্সারি; the ওষুধের দোকান = slip; home = slip (no report).
//    After the ride the guide only asks "where now?": the order is the
//    player's own choice.
//  নোটিশ (ধাপ ৩): the written notice into the office's ডাক বাক্স; telling the
//    guard booth = slip; going home with no notice = slip (the calendar will
//    not turn until one is given).
//  The company's answer: at home the calendar turns and a letter comes (swipe
//    up to read): fair (~1/3) or refused (myth 1) or less (bills, the
//    allowance, half). Fair → sign it at home (holding the signature box);
//    going to the commissioner = slip (a needless claim). Refused or less →
//    the লেবার কমিশনারের অফিস (ধাপ ৪; a শ্রমিক ইউনিয়ন stop on the way is always
//    fine); signing = slip. The commissioner before the company has
//    answered (the report, notice or waiting stage) = slip (an early claim).
//  Papers (pro tip 3): the doctor's report and the bill, the notice copy and
//    the company letter slide out at their stops; a swipe down files one in
//    the claim folder, walking on leaves it — never prompted. At the
//    commissioner's desk the player drags them out of the folder one by one
//    (on a fair letter the folder is checked at the signing, so the letter's
//    copy goes in before the signature); any missing = one slip in total. A
//    bill binned on his word is charged once (his slip) but never counts as
//    kept: no "সব কাগজ রাখা", no papers reason.
//
// No deadly anywhere in lesson 7.2 (owner ruling M7-6). The coworker (X2/B1:
// listening = the act he pushes, a slip here): on a bad letter, lesson myth 2
// word for word, held on the first drag (or signature) after reading; on a
// fair letter, "bin the bills", held on the first walk-on drag (or paper
// swipe) at the doctor's stop. Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m7_claim_route_world.dart), corner guide, a right step puts ◆ on
// the table → "কেন …?" → on; the coworker's two beats; gesture hands for how
// (a hold on the call button, a short drag nudge from him along a random
// road, a sweep over the papers, the folder and him alike, a swipe up on the
// folded letter, a nudge up from the folder at the desk) — never what.

// ============================================================================
// Content
// ============================================================================

/// Where the play stands.
enum M7ClaimStage { ride, report, notice, waitLetter, letter, claim, desk, done }

/// The papers of the claim (pro tip 3).
enum M7ClaimPaper { report, bill, notice, letter }

/// The injury (lesson point 2's heads used here).
enum M7ClaimInjury { temporary, permanentPartial }

/// The company's letter: fair, or refused / less (lesson point 4, ধাপ ৪).
enum M7ClaimLetter { fair, refused, billSelf, noAllowance, half }

/// The phone's contact (lesson: 'সুপারভাইজার বা কর্তৃপক্ষ').
enum M7ClaimContact { supervisor, authority }

/// What a step's reason asks about.
enum M7ClaimWhy { call, report, notice, claim, papers }

/// The coworker's push (by the letter dealt).
enum M7ClaimPush { accept, bin }

abstract final class M7ClaimRouteLines {
  static const title = 'দাবির পথ';
  // DRAFT wording — owner (M7-10 / M6-12): every line below.
  static const intro = 'কাজের সময় চোট লেগেছে। চিকিৎসা হবে — কিন্তু আপনার অধিকারও রক্ষা করুন। পথটা ঠিক ধরুন।';

  // The guide's task now (tap him: the same task, a different way).
  static String task(M7ClaimStage s) => switch (s) {
        M7ClaimStage.ride => 'অ্যাম্বুলেন্স চলছে। এই ফাঁকে কী করবেন?',
        M7ClaimStage.report => 'এবার কোথায় যাবেন?',
        M7ClaimStage.notice => 'পরের কাজটা কী? কোথায় যাবেন?',
        M7ClaimStage.waitLetter => 'এবার কোম্পানির উত্তরের অপেক্ষা।',
        M7ClaimStage.letter => 'কোম্পানির চিঠি এসেছে। পড়ে দেখুন।',
        M7ClaimStage.claim => 'চিঠিটা পড়েছেন। এবার কী করবেন?',
        M7ClaimStage.desk || M7ClaimStage.done => 'কমিশনারের টেবিলে ফাইল থেকে কাগজগুলো দিন।',
      };
  static List<String> get tasks => {for (final s in M7ClaimStage.values) task(s)}.toList();
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const notNow = 'এখানে এখন কোনো কাজ নেই।';
  static const readFirst = 'আগে চিঠিটা পড়ুন।';
  static const unionHere = 'ইউনিয়ন পাশে আছে — দরকারে সাহায্য করবে।';

  // The phone (a worker's own words).
  static String contact(M7ClaimContact c) => switch (c) {
        M7ClaimContact.supervisor => 'সুপারভাইজার',
        M7ClaimContact.authority => 'কর্তৃপক্ষ',
      };
  static const callBtn = 'কল';
  static const phoneLabel = 'ফোন';

  // The papers (labels only).
  static String paper(M7ClaimPaper p) => switch (p) {
        M7ClaimPaper.report => 'ডাক্তারি রিপোর্ট',
        M7ClaimPaper.bill => 'চিকিৎসার বিল',
        M7ClaimPaper.notice => 'নোটিশের কপি',
        M7ClaimPaper.letter => 'কোম্পানির চিঠি',
      };
  static String injury(M7ClaimInjury i) => switch (i) {
        M7ClaimInjury.temporary => 'অস্থায়ী অক্ষমতা',
        M7ClaimInjury.permanentPartial => 'স্থায়ী আংশিক অক্ষমতা',
      };
  static const folder = 'ফাইল';
  static const letterGot = 'আপনার দুর্ঘটনার নোটিশ পেয়েছি।';
  static String letterBody(M7ClaimLetter l, M7ClaimInjury i) => switch (l) {
        M7ClaimLetter.fair => i == M7ClaimInjury.temporary
            ? 'চিকিৎসার পুরো খরচ কোম্পানি দেবে। চিকিৎসার দিনগুলোর ভাতাও আইন অনুযায়ী দেওয়া হবে।'
            : 'চিকিৎসার পুরো খরচ কোম্পানি দেবে। স্থায়ী আংশিক অক্ষমতার ক্ষতিপূরণ আইন অনুযায়ী দেওয়া হবে।',
        M7ClaimLetter.refused => 'নিজের ভুলে দুর্ঘটনা, ক্ষতিপূরণ দেওয়া হবে না।',
        M7ClaimLetter.billSelf => 'ক্ষতিপূরণ দেওয়া হবে, কিন্তু চিকিৎসার বিল নিজে দিন।',
        M7ClaimLetter.noAllowance => 'চিকিৎসার খরচ দেওয়া হবে, কিন্তু চিকিৎসার দিনগুলোর ভাতা নেই।',
        M7ClaimLetter.half => 'আইনে যা হয়, তার অর্ধেক ক্ষতিপূরণ দেওয়া হবে।',
      };
  static const signLabel = 'সই';
  static const copyStamp = 'কপি ফাইলে';
  static const sceneLabel = 'শহরের রাস্তা';
  static const workerLabel = 'আহত কর্মী';

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static String whyCall(M7ClaimContact c) => switch (c) {
        M7ClaimContact.supervisor => 'কেন সাথে সাথে সুপারভাইজারকে জানালেন?',
        M7ClaimContact.authority => 'কেন সাথে সাথে কর্তৃপক্ষকে জানালেন?',
      };
  static const whyQ = <M7ClaimWhy, String>{
    M7ClaimWhy.report: 'কেন সরকারি বা কোম্পানির ডাক্তারের রিপোর্ট নিলেন?',
    M7ClaimWhy.notice: 'কেন লিখিত নোটিশ দিলেন?',
    M7ClaimWhy.claim: 'কেন লেবার কমিশনারের কাছে গেলেন?',
    M7ClaimWhy.papers: 'কেন সব কাগজ ফাইলে রাখলেন?',
  };
  static String question(M7ClaimWhy w, M7ClaimContact c) => w == M7ClaimWhy.call ? whyCall(c) : whyQ[w]!;
  static const whyRight = <M7ClaimWhy, List<String>>{
    M7ClaimWhy.call: ['দুর্ঘটনা হলেই সাথে সাথে জানানো প্রথম ধাপ', 'দেরি না করে কর্তৃপক্ষকে জানানোই নিয়ম'],
    M7ClaimWhy.report: ['সরকারি বা কোম্পানির ডাক্তারের রিপোর্ট আইনি নথি', 'আঘাতের পুরো ডাক্তারি রিপোর্ট দাবির বড় প্রমাণ'],
    M7ClaimWhy.notice: ['কোম্পানিকে লিখিত নোটিশ দিতে হতে পারে', 'নির্দিষ্ট সময়ে লিখিত নোটিশ দেওয়াই নিয়ম'],
    M7ClaimWhy.claim: ['না দিলে বা কম দিলে কমিশনারের কাছে যাওয়া যায়', 'ক্ষতিপূরণের পরিমাণ আইনে ঠিক করা, দয়া নয়'],
    M7ClaimWhy.papers: ['রিপোর্ট, বিল আর চিঠির কপিই দাবির প্রমাণ', 'সব কাগজ ঠিক থাকলে ক্ষতিপূরণ পাওয়া সহজ হয়'],
  };
  static const myths = [
    'নিজের ভুলে চোট হলে ক্ষতিপূরণ মেলে না',
    'কোম্পানি যা দেয়, সেটাই মেনে নিতে হয়',
    'ছোট চোটে কাউকে জানানোর কোনো দরকার নেই',
    'যেকোনো দোকানের কাগজেই রিপোর্ট হয়ে যায়',
    'গার্ডকে মুখে বলে দিলেই নোটিশ হয়ে যায়',
    'চিকিৎসার খরচ কর্মীকে নিজেকেই দিতে হয়',
    'কাগজ রাখার দরকার নেই, অফিসেই সব থাকে',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  // Lesson 7.2 myth 2, word for word (M7-10).
  static const coworkerAccept = CoworkerScript(
    line: 'কোম্পানি যা দেবে, সেটাই মেনে নিতে হবে। এর বিরুদ্ধে কিছু করার নেই।',
    exitLine: coworkerExit,
    right: ['না — পরিমাণ আইনে ঠিক করা, মানব না', 'না — কমিশনারের কাছে আবেদন করব', 'না — ক্ষতিপূরণ অধিকার, দয়া নয়'],
    wrong: [
      'ঠিক, সই করে চিঠিটা মেনে নিই',
      'আচ্ছা, কোম্পানি যা দেয় তাই ভালো',
      'হ্যাঁ, কোম্পানির সাথে পারা যায় না',
      'ঠিক আছে, ঝামেলা না করে সই করি',
      'হ্যাঁ, এর বিরুদ্ধে কিছু করার নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে মেনে নিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  // The 7.2b shortcut line (M7-10).
  static const coworkerBin = CoworkerScript(
    line: 'বিল-টিল রেখে কী হবে? ফেলে দাও, কোম্পানি তো দেবেই।',
    exitLine: coworkerExit,
    right: ['না — প্রতিটা কাগজ যত্ন করে রাখব', 'না — বিলই খরচের প্রমাণ, রাখব', 'না — রিপোর্ট আর বিল ফাইলে থাকবে'],
    wrong: [
      'ঠিক, বিল-টিল সব ফেলেই দিই',
      'আচ্ছা, কোম্পানি তো দেবেই',
      'হ্যাঁ, কাগজ রেখে কোনো লাভ নেই',
      'ঠিক আছে, ফাইলের ঝামেলা কে করে',
      'হ্যাঁ, বিলের কোনো দরকার নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে বিল ফেলে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M7ClaimPush p) => switch (p) {
        M7ClaimPush.accept => coworkerAccept,
        M7ClaimPush.bin => coworkerBin,
      };
  static const allCoworkers = [coworkerAccept, coworkerBin];

  static String callHeld(M7ClaimPush p) => switch (p) {
        M7ClaimPush.accept => 'ঠিক! পরিমাণ আইনে ঠিক করা — না দিলে বা কম দিলে কমিশনার আছেন।',
        M7ClaimPush.bin => 'ঠিক! প্রতিটা কাগজই দাবির প্রমাণ।',
      };

  static const allSet = 'জানানো, রিপোর্ট, নোটিশ, দাবি — সব ঠিক পথে!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে জানানো, তারপর রিপোর্ট, নোটিশ, তারপর দাবি।';

  // "আজ যা ধরলেন".
  static const caughtCall = 'সাথে সাথে জানানো';
  static const caughtReport = 'ঠিক ডাক্তারের রিপোর্ট';
  static const caughtNotice = 'লিখিত নোটিশ';
  static const caughtClaim = 'কমিশনারের কাছে দাবি';
  static const caughtFair = 'ন্যায্য চিঠিতে সই';
  static const caughtPapers = 'সব কাগজ রাখা';
  static const caughtUnion = 'ইউনিয়নের সাহায্য';
  static const caughtNo = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        notNow,
        readFirst,
        unionHere,
        for (final c in M7ClaimContact.values) whyCall(c),
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks.where((a) => !_oldAsks.contains(a)),
        for (final p in M7ClaimPush.values) callHeld(p),
        allSet,
        fail,
        for (final m in M7ClaimRouteMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M7ClaimRouteMistakes {
  static const _dir = 'assets/game/art/m7_claim_route';

  // DRAFT wording — owner (M7-10 / M6-12). Lesson 7.2 point 4 = index 3;
  // point 3 (medical costs) = index 2; pro tip 3 has no point (null).
  static const lateCall = DoMistake(
    key: '7.2/m7_claim_route/late-call',
    textBn: 'জানাতে দেরি! দুর্ঘটনা ঘটার সাথে সাথে সুপারভাইজার বা কর্তৃপক্ষকে জানাতে হয় — অ্যাম্বুলেন্সে থাকতেই ফোনটা করা যেত।',
    art: '$_dir/late_call.svg',
    lessonPoint: 3,
  );
  static const shopReport = DoMistake(
    key: '7.2/m7_claim_route/shop-report',
    textBn: 'ওষুধের দোকানের কাগজ ডাক্তারি রিপোর্ট নয়। সরকারি বা কোম্পানির ডাক্তার দিয়ে আঘাতের রিপোর্ট করান — এটা জরুরি আইনি নথি।',
    art: '$_dir/shop_report.svg',
    lessonPoint: 3,
  );
  static const noReport = DoMistake(
    key: '7.2/m7_claim_route/no-report',
    textBn: 'ডাক্তারি রিপোর্ট আর লিখিত নোটিশ ছাড়াই বাড়ি! আগে সরকারি বা কোম্পানির ডাক্তারের রিপোর্ট চাই।',
    art: '$_dir/no_report.svg',
    lessonPoint: 3,
  );
  static const earlyClaim = DoMistake(
    key: '7.2/m7_claim_route/early-claim',
    textBn: 'কোম্পানি এখনও উত্তরই দেয়নি! অস্বীকার করলে বা কম দিলে তবেই লেবার কমিশনারের কাছে আবেদন — আগে রিপোর্ট আর নোটিশ।',
    art: '$_dir/early_claim.svg',
    lessonPoint: 3,
  );
  static const guardNotice = DoMistake(
    key: '7.2/m7_claim_route/guard-notice',
    textBn: 'গেটের গার্ডকে মুখে বললে নোটিশ হয় না। কোম্পানিকে লিখিতভাবে দুর্ঘটনার নোটিশ দিন।',
    art: '$_dir/guard_notice.svg',
    lessonPoint: 3,
  );
  static const noNotice = DoMistake(
    key: '7.2/m7_claim_route/no-notice',
    textBn: 'লিখিত নোটিশ না দিয়েই বাড়ি! নির্দিষ্ট সময়ের মধ্যে কোম্পানিকে লিখিত নোটিশ দিতে হতে পারে — আগে নোটিশ।',
    art: '$_dir/no_notice.svg',
    lessonPoint: 3,
  );
  static const acceptLess = DoMistake(
    key: '7.2/m7_claim_route/accept-less',
    textBn: 'ক্ষতিপূরণের পরিমাণ আইনে ঠিক করা। কোম্পানি অস্বীকার করলে বা কম দিলে সই করবেন না — লেবার কমিশনারের কাছে আবেদন করুন।',
    art: '$_dir/accept_less.svg',
    lessonPoint: 3,
  );
  static const needlessClaim = DoMistake(
    key: '7.2/m7_claim_route/needless-claim',
    textBn: 'কোম্পানি আইন মেনেই পুরো ক্ষতিপূরণ দিচ্ছে। অস্বীকার করলে বা কম দিলে তবেই লেবার কমিশনারের কাছে যেতে হয় — অকারণ দাবি নয়।',
    art: '$_dir/needless_claim.svg',
    lessonPoint: 3,
  );
  static const paperMissing = DoMistake(
    key: '7.2/m7_claim_route/paper-missing',
    textBn: 'কাগজ নেই! ডাক্তারের রিপোর্ট, চিকিৎসার বিল আর কোম্পানির সাথে সব যোগাযোগের কপি যত্ন করে রাখতে হয়।',
    art: '$_dir/paper_missing.svg',
  );
  static const binBill = DoMistake(
    key: '7.2/m7_claim_route/bin-bill',
    textBn: 'বিল ফেলে দিলেন! দুর্ঘটনার চিকিৎসার খরচ পুরোটাই নিয়োগকর্তার দায়িত্ব — তার প্রমাণ এই বিল। প্রতিটা কাগজ যত্ন করে রাখুন।',
    art: '$_dir/bin_bill.svg',
    lessonPoint: 2,
  );

  /// Listening to his push is the act it pushes (X2/B1) — a slip here.
  static DoMistake push(M7ClaimPush p) => switch (p) {
        M7ClaimPush.accept => acceptLess,
        M7ClaimPush.bin => binBill,
      };

  static const List<DoMistake> all = [
    lateCall,
    shopReport,
    noReport,
    guardNotice,
    noNotice,
    earlyClaim,
    acceptLess,
    needlessClaim,
    paperMissing,
    binBill,
  ];
}

@immutable
class M7ClaimDeal {
  const M7ClaimDeal({
    required this.map,
    required this.injury,
    required this.letter,
    required this.contact,
    this.papersWhy = false,
  });

  final M7ClaimMap map;
  final M7ClaimInjury injury;
  final M7ClaimLetter letter;
  final M7ClaimContact contact;

  /// On a bad letter with every paper kept, the final reason asks about the
  /// papers (else about the claim).
  final bool papersWhy;

  bool get fair => letter == M7ClaimLetter.fair;
  M7ClaimPush get push => fair ? M7ClaimPush.bin : M7ClaimPush.accept;
}

/// The bad letters that fit an injury (no allowance only for a temporary
/// disablement: lesson point 3 'বেতন সহ ছুটি').
List<M7ClaimLetter> m7ClaimBadLetters(M7ClaimInjury i) => [
      M7ClaimLetter.refused,
      M7ClaimLetter.billSelf,
      M7ClaimLetter.half,
      if (i == M7ClaimInjury.temporary) M7ClaimLetter.noAllowance,
    ];

M7ClaimDeal m7ClaimDeal(math.Random rng) {
  final map = M7ClaimMap(layout: rng.nextInt(m7ClaimLayouts.length), mirror: rng.nextBool(), swapDesks: rng.nextBool());
  final injury = M7ClaimInjury.values[rng.nextInt(2)];
  final bad = m7ClaimBadLetters(injury);
  final letter = rng.nextInt(3) == 0 ? M7ClaimLetter.fair : bad[rng.nextInt(bad.length)];
  return M7ClaimDeal(
    map: map,
    injury: injury,
    letter: letter,
    contact: M7ClaimContact.values[rng.nextInt(2)],
    papersWhy: rng.nextBool(),
  );
}

/// What a drop on a stop did.
enum M7ArriveKind { stay, back, slip, fine, union, right, home, desk }

@immutable
class M7Arrive {
  const M7Arrive(this.kind, {this.mistake, this.line});
  final M7ArriveKind kind;
  final DoMistake? mistake;
  final String? line;

  /// He walks there and stays (else he goes back where he was).
  bool get moves => kind == M7ArriveKind.fine || kind == M7ArriveKind.union || kind == M7ArriveKind.right || kind == M7ArriveKind.home || kind == M7ArriveKind.desk;
}

/// The play state (pure logic).
class M7ClaimRun {
  M7ClaimRun(this.deal);
  final M7ClaimDeal deal;

  var stage = M7ClaimStage.ride;
  var at = M7ClaimNode.site;
  int slips = 0;
  int stepSlips = 0;
  final List<String> caught = [];

  var called = false;
  var calledLate = false;

  /// A right step is in; its reason comes next.
  var roundDone = false;
  M7ClaimWhy? why;
  final List<M7ClaimPaper> _pending = [];

  /// The papers out at this stop (the letter is drawn at home instead).
  final List<M7ClaimPaper> tray = [];

  /// The papers kept, in the order filed; and those left behind.
  final List<M7ClaimPaper> folder = [];
  final Set<M7ClaimPaper> lost = {};
  final List<M7ClaimPaper> desk = [];

  var letterRead = false;
  var signed = false;
  var checked = false;
  var unionSeen = false;

  /// The paper he made the player throw away (its slip already counted).
  M7ClaimPaper? binned;

  bool get fair => deal.fair;
  bool get done => stage == M7ClaimStage.done;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => stepSlips == 0;
  bool get atDoctor => at == M7ClaimNode.hospital || at == M7ClaimNode.dispensary;
  bool get letterHere => at == M7ClaimNode.home && (stage == M7ClaimStage.letter || stage == M7ClaimStage.claim || (fair && signed));

  /// He can be dragged along the roads now.
  bool get canDrag =>
      !roundDone &&
      (stage == M7ClaimStage.report || stage == M7ClaimStage.notice || stage == M7ClaimStage.waitLetter || stage == M7ClaimStage.claim);

  /// The papers the end checks (pro tip 3: the report, the bills and a copy
  /// of every exchange with the company — on both letters).
  List<M7ClaimPaper> get expected => M7ClaimPaper.values;

  /// The papers charged at the end (a binned bill was charged as his slip).
  List<M7ClaimPaper> get missing => [for (final p in expected) if (!folder.contains(p) && p != binned) p];

  /// Every paper truly kept (a binned bill is not kept: X6, a reason after a
  /// slip describes what this play had).
  bool get allKept => missing.isEmpty && binned == null;

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stepSlips++;
    return m;
  }

  void _right(M7ClaimWhy w, [List<M7ClaimPaper> papers = const []]) {
    roundDone = true;
    why = w;
    _pending
      ..clear()
      ..addAll(papers);
  }

  /// He walks off: the papers still out at this stop stay behind.
  void _leave(M7ClaimNode n) {
    lost.addAll(tray);
    tray.clear();
    at = n;
  }

  /// The call (held on the phone's button) during the ride.
  bool call() {
    if (stage != M7ClaimStage.ride || called || roundDone) return false;
    called = true;
    _tag(M7RouteTags.call);
    _right(M7ClaimWhy.call);
    return true;
  }

  /// The ambulance lets him off at the মোড়: a late call is a slip.
  DoMistake? rideOver() {
    if (stage != M7ClaimStage.ride) return null;
    at = M7ClaimNode.junction;
    stage = M7ClaimStage.report;
    if (called) return null;
    called = calledLate = true;
    return _slip(M7ClaimRouteMistakes.lateCall);
  }

  /// Dropped on a stop.
  M7Arrive arrive(M7ClaimNode n) {
    if (!canDrag) return const M7Arrive(M7ArriveKind.stay);
    if (n == at) return const M7Arrive(M7ArriveKind.stay);
    switch (stage) {
      case M7ClaimStage.report:
        if (n == M7ClaimNode.hospital || n == M7ClaimNode.dispensary) {
          _leave(n);
          stage = M7ClaimStage.notice;
          _tag(M7RouteTags.report);
          _right(M7ClaimWhy.report, const [M7ClaimPaper.report, M7ClaimPaper.bill]);
          return const M7Arrive(M7ArriveKind.right);
        }
        if (n == M7ClaimNode.shop) return M7Arrive(M7ArriveKind.slip, mistake: _slip(M7ClaimRouteMistakes.shopReport));
        if (n == M7ClaimNode.home) return M7Arrive(M7ArriveKind.slip, mistake: _slip(M7ClaimRouteMistakes.noReport));
        if (n == M7ClaimNode.commissioner) return M7Arrive(M7ArriveKind.slip, mistake: _slip(M7ClaimRouteMistakes.earlyClaim));
      case M7ClaimStage.notice:
        if (n == M7ClaimNode.mailbox) {
          _leave(n);
          stage = M7ClaimStage.waitLetter;
          _tag(M7RouteTags.notice);
          _right(M7ClaimWhy.notice, const [M7ClaimPaper.notice]);
          return const M7Arrive(M7ArriveKind.right);
        }
        if (n == M7ClaimNode.guard) return M7Arrive(M7ArriveKind.slip, mistake: _slip(M7ClaimRouteMistakes.guardNotice));
        if (n == M7ClaimNode.home) return M7Arrive(M7ArriveKind.slip, mistake: _slip(M7ClaimRouteMistakes.noNotice));
        if (n == M7ClaimNode.commissioner) return M7Arrive(M7ArriveKind.slip, mistake: _slip(M7ClaimRouteMistakes.earlyClaim));
      case M7ClaimStage.waitLetter:
        if (n == M7ClaimNode.home) {
          _leave(n);
          stage = M7ClaimStage.letter;
          return const M7Arrive(M7ArriveKind.home);
        }
        if (n == M7ClaimNode.commissioner) return M7Arrive(M7ArriveKind.slip, mistake: _slip(M7ClaimRouteMistakes.earlyClaim));
      case M7ClaimStage.claim:
        if (n == M7ClaimNode.commissioner) {
          if (fair) return M7Arrive(M7ArriveKind.slip, mistake: _slip(M7ClaimRouteMistakes.needlessClaim));
          _leave(n);
          stage = M7ClaimStage.desk;
          _tag(M7RouteTags.claim);
          return const M7Arrive(M7ArriveKind.desk);
        }
        if (n == M7ClaimNode.home) {
          _leave(n);
          return const M7Arrive(M7ArriveKind.fine);
        }
      case M7ClaimStage.ride || M7ClaimStage.letter || M7ClaimStage.desk || M7ClaimStage.done:
        break;
    }
    if (n == M7ClaimNode.union) {
      _leave(n);
      if (!unionSeen) {
        unionSeen = true;
        _tag(M7RouteTags.union);
      }
      return const M7Arrive(M7ArriveKind.union, line: M7ClaimRouteLines.unionHere);
    }
    return const M7Arrive(M7ArriveKind.back, line: M7ClaimRouteLines.notNow);
  }

  /// A swipe down on a paper files it (the open letter: a copy goes in).
  bool file(M7ClaimPaper p) {
    if (roundDone || done || stage == M7ClaimStage.desk) return false;
    if (p == M7ClaimPaper.letter) {
      if (!letterHere || !letterRead || folder.contains(p)) return false;
      folder.add(p);
      return true;
    }
    if (!tray.remove(p)) return false;
    folder.add(p);
    return true;
  }

  /// A swipe up on the folded letter opens it.
  bool read() {
    if (stage != M7ClaimStage.letter || at != M7ClaimNode.home || roundDone) return false;
    letterRead = true;
    stage = M7ClaimStage.claim;
    return true;
  }

  /// The signature (a hold on its box): a fair letter accepted (the end);
  /// a refused or reduced one = slip.
  DoMistake? sign() {
    if (stage != M7ClaimStage.claim || at != M7ClaimNode.home || signed || roundDone) return null;
    if (!fair) return _slip(M7ClaimRouteMistakes.acceptLess);
    signed = true;
    _tag(M7RouteTags.fair);
    return null;
  }

  /// The commissioner's desk: the next paper out of the folder. True when
  /// the folder is then empty (time to check); null when nothing can come.
  bool? pull() {
    if (stage != M7ClaimStage.desk || roundDone || checked) return null;
    final left = [for (final p in folder) if (!desk.contains(p)) p];
    if (left.isNotEmpty) desk.add(left.first);
    return desk.length >= folder.length;
  }

  /// Papers still in the folder (not yet on the desk).
  int get inFolder => folder.where((p) => !desk.contains(p)).length;

  /// The end's reason (null: none fits — a fair play with a paper missing
  /// or the bill binned).
  M7ClaimWhy? get finalWhy {
    final ok = allKept;
    if (fair) return ok ? M7ClaimWhy.papers : null;
    return ok && deal.papersWhy ? M7ClaimWhy.papers : M7ClaimWhy.claim;
  }

  /// The end check (the desk, or the signed fair letter): any missing paper
  /// = one slip in total.
  DoMistake? check() {
    if (checked) return null;
    if (!((stage == M7ClaimStage.desk) || (fair && signed))) return null;
    checked = true;
    final miss = missing;
    final w = finalWhy;
    if (allKept) _tag(M7RouteTags.papers);
    if (w == null) {
      stage = M7ClaimStage.done;
    } else {
      roundDone = true;
      why = w;
      _pending.clear();
    }
    return miss.isEmpty ? null : _slip(M7ClaimRouteMistakes.paperMissing);
  }

  /// The reason is paid: the papers of the stop slide out; the end ends.
  void paid() {
    roundDone = false;
    why = null;
    stepSlips = 0;
    tray.addAll(_pending);
    _pending.clear();
    if (checked) stage = M7ClaimStage.done;
  }

  /// Listened to him (a slip): on the bill push the bill goes in the bin.
  DoMistake listen(M7ClaimPush p) {
    if (p == M7ClaimPush.bin) {
      binned = M7ClaimPaper.bill;
      tray.remove(M7ClaimPaper.bill);
      folder.remove(M7ClaimPaper.bill);
    }
    return _slip(M7ClaimRouteMistakes.push(p));
  }
}

/// The "আজ যা ধরলেন" tags (one place, so the run needs no page).
abstract final class M7RouteTags {
  static const call = M7ClaimRouteLines.caughtCall;
  static const report = M7ClaimRouteLines.caughtReport;
  static const notice = M7ClaimRouteLines.caughtNotice;
  static const claim = M7ClaimRouteLines.caughtClaim;
  static const fair = M7ClaimRouteLines.caughtFair;
  static const papers = M7ClaimRouteLines.caughtPapers;
  static const union = M7ClaimRouteLines.caughtUnion;
}

/// The ambulance ride (the time to call), and the calendar's turn at home.
const kM7RideMs = 7000;
const kM7CalendarMs = 1600;

/// The call button's hold, and the signature's.
const kM7HoldMs = 800;

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   the ride (the call inside it) 7000 · drags: doctor, mailbox, home,
///   commissioner ≈ 6000 · paper swipes ×4 ≈ 6000 · the letter (read, the
///   calendar) ≈ 3100 · the desk (4 pulls) ≈ 6000 or a signature ≈ 1500
///   + a reason each (~8200 × 4) + the coworker once ≈ 9600       ≈ 66000–71000
/// 85 % ≈ 58000 → 60 s (a builder's estimate; owner may tune after playtest).
const m7ClaimRouteQuickMs = 60000;

@immutable
class M7ClaimRoutePack {
  const M7ClaimRoutePack({required this.id, required this.titleBn, this.quickMs = m7ClaimRouteQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7ClaimRoutePack> m7ClaimRoutePacks = {
  'do_7_2_b': M7ClaimRoutePack(id: 'do_7_2_b', titleBn: M7ClaimRouteLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7ClaimRouteProbe {
  static M7ClaimRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7ClaimRoutePage extends StatefulWidget {
  const M7ClaimRoutePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7ClaimRoutePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7ClaimRoutePage> createState() => _M7ClaimRoutePageState();
}

class _M7ClaimRoutePageState extends State<M7ClaimRoutePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ClaimRunPage(
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

class _ClaimRunPage extends ConsumerStatefulWidget {
  const _ClaimRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7ClaimRoutePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ClaimRunPage> createState() => _ClaimRunPageState();
}

class _ClaimRunPageState extends ConsumerState<_ClaimRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7ClaimRun _run;
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

  /// The end check's slip: its card leads on to the final reason (or the end).
  var _afterCard = false;

  /// The ride.
  AnimationController? _rideCtl;
  Timer? _rideTimer;
  var _phoneOpen = false;

  /// A hold under way (the call button or the signature) and its count.
  Timer? _holdTimer;
  String? _holding;
  int _holdN = 0;

  /// Dragging him: where his feet are now and the grab's offset.
  Offset? _dragFeet;
  Offset _grabDelta = Offset.zero;

  /// A drag up from the folder at the desk.
  Offset? _deskFrom;
  Offset _deskNow = Offset.zero;

  /// The calendar turning at home (the letter comes after it).
  var _calendarBusy = false;
  int _calTurns = 0;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _callKey = GlobalKey();
  final _figureKey = GlobalKey();
  final _folderKey = GlobalKey();
  final _signKey = GlobalKey();
  final _letterKey = GlobalKey();
  final Map<M7ClaimPaper, GlobalKey> _paperKeys = {for (final p in M7ClaimPaper.values) p: GlobalKey()};
  int _hintN = 0;
  int _steps = 0;
  M7ClaimGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7ClaimRun(m7ClaimDeal(widget.rng));
    M7ClaimRouteProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _rideTimer?.cancel();
    _holdTimer?.cancel();
    _rideCtl?.dispose();
    if (identical(M7ClaimRouteProbe.run, _run)) M7ClaimRouteProbe.run = null;
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone;

  String get _task => M7ClaimRouteLines.task(_run.stage);

  void _stepDone() {
    _steps++;
    setState(() {});
  }

  /// His window: once he is due, the decisive controls wait for him.
  bool _waitForHim() => coworkerDue && holdForCoworker();

  // --- the ride ------------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    if (_quiet) {
      _rideTimer = Timer(const Duration(milliseconds: kM7RideMs), _rideOver);
    } else {
      final c = _rideCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: kM7RideMs));
      c.addStatusListener((s) {
        if (s == AnimationStatus.completed) _rideOver();
      });
      unawaited(c.forward());
    }
    setState(() {});
    unawaited(_sayChain([_task]));
  }

  void _rideOver() {
    if (!mounted || _ended) return;
    _cancelHold();
    final m = _run.rideOver();
    setState(() {
      _phoneOpen = false;
      _steps++;
    });
    _cue('sounds/intro/click.ogg', volume: 0.4);
    if (m != null) {
      unawaited(_mistake(m, _centre));
      return;
    }
    if (!tableBusy) unawaited(_sayChain([_task]));
  }

  Offset get _centre {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  void _openPhone() {
    if (!_canPlay || _run.stage != M7ClaimStage.ride || _run.called) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _phoneOpen = true);
  }

  void _closePhone() {
    _cancelHold();
    setState(() => _phoneOpen = false);
  }

  // --- holds (the call button, the signature) -------------------------------------
  void _holdStart(String what) {
    if (!_canPlay || _holdTimer != null) return;
    if (what == 'call' && (!_phoneOpen || _run.called)) return;
    if (what == 'sign') {
      if (_run.stage != M7ClaimStage.claim || _run.signed) return;
      if (_waitForHim()) return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _holding = what;
      _holdN++;
      _holdTimer = Timer(const Duration(milliseconds: kM7HoldMs), () {
        _holdTimer = null;
        _holding = null;
        if (!mounted) return;
        if (what == 'call') {
          _call();
        } else {
          _sign();
        }
      });
    });
  }

  /// Let go before the hold filled: a tap where a hold is wanted counts as a
  /// miss for the gesture hand (three in a row show the hold).
  void _holdEnd() {
    if (_holdTimer == null) return;
    _cancelHold();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hints.missTap();
    });
  }

  void _cancelHold() {
    if (_holdTimer == null) return;
    _holdTimer?.cancel();
    _holdTimer = null;
    if (mounted) setState(() => _holding = null);
  }

  void _call() {
    if (!_run.call()) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    setState(() => _phoneOpen = false);
    _stepDone();
    _askStep();
  }

  void _sign() {
    if (!_canPlay) return;
    final m = _run.sign();
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, _centre));
      return;
    }
    if (!_run.signed) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _stepDone();
    _finalCheck();
  }

  // --- the map: drag him along the roads ------------------------------------------
  Offset _feetAt(M7ClaimGeo geo) => geo.at(_run.deal.map, _run.at);

  void _panStart(Offset p, M7ClaimGeo geo) {
    _dragFeet = null;
    _deskFrom = null;
    if (!_canPlay) return;
    if (_run.stage == M7ClaimStage.desk && geo.folder.inflate(8).contains(p)) {
      _deskFrom = p;
      _deskNow = p;
      return;
    }
    if (_run.stage == M7ClaimStage.ride) return;
    final feet = _feetAt(geo);
    if ((p - M7ClaimGeo.grab(feet)).distance > M7ClaimGeo.grabR) return;
    if (!_run.canDrag) {
      if (_run.stage == M7ClaimStage.letter && !_calendarBusy) {
        _tick();
        unawaited(_sayChain([M7ClaimRouteLines.readFirst]));
      }
      return;
    }
    if (_waitForHim()) return;
    _grabDelta = feet - p;
    setState(() => _dragFeet = feet);
  }

  void _panUpdate(Offset p) {
    if (_deskFrom != null) {
      _deskNow = p;
      return;
    }
    if (_dragFeet == null) return;
    if (!_canPlay) {
      setState(() => _dragFeet = null);
      return;
    }
    setState(() => _dragFeet = Offset((p + _grabDelta).dx.clamp(8.0, 352.0), (p + _grabDelta).dy.clamp(120.0, (_geoNow?.bottom ?? 800) - 8)));
  }

  void _panEnd(Offset global) {
    final from = _deskFrom;
    if (from != null) {
      _deskFrom = null;
      if (_deskNow.dy - from.dy < -30) {
        _pull();
      } else {
        _hints.missTap();
      }
      return;
    }
    final feet = _dragFeet;
    if (feet == null) return;
    final geo = _geoNow;
    M7ClaimNode? best;
    var bestD = M7ClaimGeo.nodeR;
    if (geo != null) {
      for (final n in M7ClaimNode.values) {
        final d = (geo.at(_run.deal.map, n) - feet).distance;
        if (d <= bestD) {
          bestD = d;
          best = n;
        }
      }
    }
    setState(() => _dragFeet = null);
    if (best == null || !_canPlay) return;
    _arrive(best, global);
  }

  void _arrive(M7ClaimNode n, Offset global) {
    final r = _run.arrive(n);
    if (r.moves) _cue('sounds/intro/click.ogg', volume: 0.45);
    _stepDone();
    switch (r.kind) {
      case M7ArriveKind.stay:
        return;
      case M7ArriveKind.back:
        _tick();
        unawaited(_sayChain([r.line ?? M7ClaimRouteLines.notNow]));
      case M7ArriveKind.slip:
        unawaited(_mistake(r.mistake!, global));
      case M7ArriveKind.fine:
        unawaited(_sayChain([_task]));
      case M7ArriveKind.union:
        unawaited(_sayChain([r.line!, _task]));
      case M7ArriveKind.right:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
        _askStep();
      case M7ArriveKind.home:
        _hush();
        setState(() {
          _calendarBusy = true;
          _calTurns++;
        });
        unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : kM7CalendarMs), () {
          if (!mounted || _ended) return;
          setState(() => _calendarBusy = false);
          _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
          unawaited(_sayChain([_task]));
        }));
      case M7ArriveKind.desk:
        unawaited(_sayChain([_task]));
    }
  }

  // --- the papers ---------------------------------------------------------------
  void _paperSwipe(M7ClaimPaper p, double dy) {
    if (!_canPlay) return;
    if (dy > 28) {
      if (p == M7ClaimPaper.letter && !_run.letterRead) {
        _tick();
        unawaited(_sayChain([M7ClaimRouteLines.readFirst]));
        return;
      }
      if (_waitForHim()) return;
      if (_run.file(p)) {
        _tick('sounds/learn/card_deal_a.ogg', 0.5);
        _stepDone();
      }
      return;
    }
    if (dy < -28 && p == M7ClaimPaper.letter && !_calendarBusy && _run.read()) {
      _tick('sounds/learn/card_deal_a.ogg', 0.5);
      if (!_run.fair && !coworkerDone && !coworkerDue) scheduleCoworker();
      _stepDone();
      unawaited(_sayChain([_task]));
      return;
    }
    _hints.missTap();
  }

  void _pull() {
    if (!_canPlay) return;
    final empty = _run.pull();
    if (empty == null) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.5);
    _stepDone();
    if (empty) _finalCheck();
  }

  void _finalCheck() {
    final m = _run.check();
    if (m != null) {
      _afterCard = true;
      unawaited(_mistake(m, _centre));
      return;
    }
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _askStep();
  }

  // --- the success beat -----------------------------------------------------------
  void _askStep() {
    final w = _run.why;
    if (w == null) return;
    _hush();
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final stage = _run.stage;
    final s = _steps;
    unawaited(askReason(
      deal: () => dealChoices(M7ClaimRouteLines.whyRight[w]!, M7ClaimRouteLines.myths, widget.rng),
      question: M7ClaimRouteLines.question(w, _run.deal.contact),
      stillValid: () => !_ended && _run.stage == stage && _steps == s,
    ));
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
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
    final wasReport = _run.why == M7ClaimWhy.report;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (!mounted || _ended) return;
      setState(_run.paid);
      if (_run.done) {
        unawaited(_finish());
        return;
      }
      // The fair-letter push comes at the doctor's stop, as the papers slide out.
      if (wasReport && _run.fair && !coworkerDone && !coworkerDue) scheduleCoworker();
      if (_run.stage != M7ClaimStage.ride) unawaited(_sayChain([_task]));
    }));
  }

  // --- the pressure moment -------------------------------------------------------
  @override
  CoworkerScript get coworkerScript => M7ClaimRouteLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final r = _run;
    final window = r.fair
        ? r.stage == M7ClaimStage.notice && r.atDoctor && !r.roundDone
        : r.stage == M7ClaimStage.claim && r.at == M7ClaimNode.home && !r.signed && !r.roundDone;
    if (!window) return null;
    if (_intro || _card != null || tableBusy || _calendarBusy || _dragFeet != null || _holdTimer != null) return false;
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
      final m = _run.listen(p);
      setState(() {});
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M7ClaimRouteLines.caughtNo);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7ClaimRouteLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7ClaimRouteLines.tapWhy[_nudgeN++ % M7ClaimRouteLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes -------------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _rideCtl?.stop();
    _rideTimer?.cancel();
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
    _cancelHold();
    setState(() {
      _card = m;
      _phoneOpen = false;
      _dragFeet = null;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7claim/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() => _card = null);
    if (_afterCard) {
      _afterCard = false;
      if (_run.done) {
        unawaited(_finish());
      } else {
        _askStep();
      }
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
    final centre = _centre;
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
    await _say(!_run.passed ? M7ClaimRouteLines.fail : (_quickBonus ? M7ClaimRouteLines.quick : M7ClaimRouteLines.allSet),
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

  // --- the gesture hand -----------------------------------------------------------
  /// How to touch, never what: a hold on the call button (the one way on);
  /// a swipe up on the folded letter (the only way to read it); a nudge up
  /// from the folder at the desk; a sweep over the papers, the folder and
  /// him alike (keeping is never prompted) or over the letter, its signature
  /// box and him alike; otherwise a short drag nudge from him along a random
  /// road leaving his crossing.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    final r = _run;
    if (r.stage == M7ClaimStage.ride) return _phoneOpen ? HintSpec.holdOn(_callKey) : null;
    if (r.stage == M7ClaimStage.letter) {
      final at = M7ClaimGeo.paper(0, 1);
      return HintSpec.swipe(at.center, toward: const Offset(0, -1), travel: 50, space: HintSpace.scene);
    }
    if (r.stage == M7ClaimStage.desk) return HintSpec.drag(geo.folder.center, toward: const Offset(0, -1), travel: 60, space: HintSpace.scene);
    if (r.letterHere && r.stage == M7ClaimStage.claim) return HintSpec.sweepOver([_letterKey, _signKey, _figureKey, _folderKey]);
    if (r.tray.isNotEmpty) return HintSpec.sweepOver([for (final p in r.tray) _paperKeys[p]!, _folderKey, _figureKey]);
    final s = r.deal.map.slotOf(r.at);
    final dirs = <Offset>[
      if (s.col > 0) const Offset(-1, 0),
      if (s.col < 3) const Offset(1, 0),
      if (s.row > 0) const Offset(0, -1),
      if (s.row < 2) const Offset(0, 1),
    ];
    final dir = dirs[(n + widget.rng.nextInt(dirs.length)) % dirs.length];
    return HintSpec.drag(M7ClaimGeo.grab(_feetAt(geo)), toward: dir, travel: 60, space: HintSpace.scene);
  }

  // --- the scene --------------------------------------------------------------------
  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7ClaimGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final map = _run.deal.map;
    final r = _run;
    final riding = r.stage == M7ClaimStage.ride;
    final feet = _dragFeet ?? _feetAt(geo);
    final siteAt = geo.at(map, M7ClaimNode.site), junctionAt = geo.at(map, M7ClaimNode.junction);
    final homeAt = geo.at(map, M7ClaimNode.home);
    final showLetter = r.letterHere && !_calendarBusy;
    final papers = r.stage == M7ClaimStage.desk ? r.desk : r.tray;
    return [
      Positioned.fill(
        key: const ValueKey('map'),
        child: RepaintBoundary(child: CustomPaint(painter: M7ClaimMapPainter(geo: geo, map: map))),
      ),
      Positioned.fromRect(
        key: const ValueKey('calendar'),
        rect: M7ClaimGeo.calendar(homeAt),
        child: _calendarBusy && !quiet
            ? TweenAnimationBuilder<double>(
                key: ValueKey('cal-$_calTurns'),
                tween: Tween(begin: 0, end: 3),
                duration: const Duration(milliseconds: kM7CalendarMs - 100),
                builder: (_, v, _) => CustomPaint(painter: M7CalendarPainter(turn: v >= 3 ? 0 : v)),
              )
            : const CustomPaint(painter: M7CalendarPainter(turn: 0)),
      ),
      if (riding)
        Positioned.fill(
          key: const ValueKey('ambulance'),
          child: RepaintBoundary(
            child: _rideCtl == null
                ? CustomPaint(painter: M7AmbulancePainter(at: siteAt, dir: m7RoadPoint(siteAt, junctionAt, 0).$2, lights: true))
                : AnimatedBuilder(
                    animation: _rideCtl!,
                    builder: (_, _) {
                      final t = Curves.easeInOut.transform(_rideCtl!.value);
                      final (at, dir) = m7RoadPoint(siteAt, junctionAt, t);
                      return CustomPaint(painter: M7AmbulancePainter(at: at, dir: dir, lights: (_rideCtl!.value * 14).floor().isEven));
                    },
                  ),
          ),
        ),
      if (!riding)
        AnimatedPositioned.fromRect(
          key: const ValueKey('worker'),
          rect: M7ClaimGeo.figure(feet),
          duration: _dragFeet != null || quiet ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          child: Semantics(
            label: M7ClaimRouteLines.workerLabel,
            child: RepaintBoundary(key: _figureKey, child: CustomPaint(painter: M7WorkerPainter(lifted: _dragFeet != null))),
          ),
        ),
      Positioned.fromRect(
        key: const ValueKey('folder'),
        rect: geo.folder,
        child: Semantics(
          label: M7ClaimRouteLines.folder,
          child: Column(
            key: _folderKey,
            children: [
              Expanded(child: CustomPaint(size: Size.infinite, painter: M7FolderPainter(papers: r.stage == M7ClaimStage.desk ? r.inFolder : r.folder.length))),
              Text(M7ClaimRouteLines.folder, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
            ],
          ),
        ),
      ),
      if (riding && !r.called)
        Positioned.fromRect(
          key: const ValueKey('phone'),
          rect: geo.phone,
          child: Semantics(
            label: M7ClaimRouteLines.phoneLabel,
            button: true,
            child: _rideCtl == null
                ? const _Phone(glow: 1)
                : AnimatedBuilder(
                    animation: _rideCtl!,
                    builder: (_, _) => _Phone(glow: 0.5 + 0.5 * math.sin(_rideCtl!.value * 2 * math.pi * 6)),
                  ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7ClaimRouteLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) {
              if (riding && geo.phone.inflate(6).contains(d.localPosition)) {
                _openPhone();
                return;
              }
              _hints.missTap();
            },
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (d) => _panEnd(d.globalPosition),
            onPanCancel: () {
              _deskFrom = null;
              if (_dragFeet != null) setState(() => _dragFeet = null);
            },
          ),
        ),
      ),
      // The papers out at this stop (over the touch layer: each takes its own swipe).
      if (!showLetter)
        for (final (i, p) in papers.indexed)
          Positioned.fromRect(
            key: ValueKey('paper-${p.name}-${r.stage == M7ClaimStage.desk}'),
            rect: M7ClaimGeo.paper(i, r.stage == M7ClaimStage.desk ? 4 : papers.length),
            child: _PaperCard(
              key: _paperKeys[p],
              paper: p,
              sub: p == M7ClaimPaper.report ? M7ClaimRouteLines.injury(r.deal.injury) : null,
              small: r.stage == M7ClaimStage.desk,
              quiet: quiet,
              onSwipe: r.stage == M7ClaimStage.desk ? null : (dy) => _paperSwipe(p, dy),
            ),
          ),
      if (showLetter && !r.letterRead)
        Positioned.fromRect(
          key: const ValueKey('letter-folded'),
          rect: M7ClaimGeo.paper(0, 1),
          child: _PaperCard(
            key: _paperKeys[M7ClaimPaper.letter],
            paper: M7ClaimPaper.letter,
            folded: true,
            quiet: quiet,
            onSwipe: (dy) => _paperSwipe(M7ClaimPaper.letter, dy),
          ),
        ),
      if (showLetter && r.letterRead)
        Positioned.fromRect(
          key: const ValueKey('letter-open'),
          rect: M7ClaimGeo.letter,
          child: _LetterPanel(
            key: _letterKey,
            signKey: _signKey,
            body: M7ClaimRouteLines.letterBody(r.deal.letter, r.deal.injury),
            copied: r.folder.contains(M7ClaimPaper.letter),
            signed: r.signed,
            holding: _holding == 'sign',
            holdN: _holdN,
            quiet: quiet,
            onSwipe: (dy) => _paperSwipe(M7ClaimPaper.letter, dy),
            onHoldStart: () => _holdStart('sign'),
            onHoldEnd: _holdEnd,
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
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final waiting = handsOn &&
        !tableBusy &&
        !_calendarBusy &&
        _dragFeet == null &&
        _holdTimer == null &&
        (_run.stage != M7ClaimStage.ride || _phoneOpen);
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
            hintWaiting: waiting,
            hintKey: '${_run.stage.name}/${_run.at.name}/$_steps/$_phoneOpen',
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (handsOn && _phoneOpen)
                Positioned.fill(
                  key: const ValueKey('phone-panel'),
                  child: _PhonePanel(
                    contact: M7ClaimRouteLines.contact(_run.deal.contact),
                    callKey: _callKey,
                    holding: _holding == 'call',
                    holdN: _holdN,
                    quiet: quiet,
                    onClose: _closePhone,
                    onMiss: _hints.missTap,
                    onHoldStart: () => _holdStart('call'),
                    onHoldEnd: _holdEnd,
                  ),
                ),
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
                  line: M7ClaimRouteLines.intro,
                  alarm: 'sounds/learn/siren.ogg',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 3, muted: _muted)),
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

/// His phone (bottom left), glowing during the ride.
class _Phone extends StatelessWidget {
  const _Phone({required this.glow});
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFF1C2430),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF3A4656), width: 2),
          boxShadow: [BoxShadow(color: Color.fromRGBO(120, 220, 255, 0.25 + 0.5 * glow), blurRadius: 6 + 12 * glow, spreadRadius: 1 + 3 * glow)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(const Color(0xFF2B5D86), const Color(0xFF7FD3FF), glow)!, const Color(0xFF16324A)],
              ),
            ),
            child: const Center(child: Icon(Icons.phone_in_talk_rounded, size: 22, color: Color(0xFFE8F6FF))),
          ),
        ),
      ),
    );
  }
}

/// The open phone: the contact and the call button (held to call).
class _PhonePanel extends StatelessWidget {
  const _PhonePanel({
    required this.contact,
    required this.callKey,
    required this.holding,
    required this.holdN,
    required this.quiet,
    required this.onClose,
    required this.onMiss,
    required this.onHoldStart,
    required this.onHoldEnd,
  });
  final String contact;
  final GlobalKey callKey;
  final bool holding;
  final int holdN;
  final bool quiet;
  final VoidCallback onClose;
  final VoidCallback onMiss;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: ColoredBox(
        color: const Color(0x99050A16),
        child: Center(
          child: GestureDetector(
            onTap: onMiss,
            child: Container(
              width: 220,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF16202C),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFF3A4656), width: 3),
                boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: Color(0xFF2B5D86), child: Icon(Icons.person_rounded, size: 36, color: Color(0xFFE8F6FF))),
                  const SizedBox(height: 10),
                  Text(contact, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                  const SizedBox(height: 18),
                  Semantics(
                    button: true,
                    label: M7ClaimRouteLines.callBtn,
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: callKey,
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => onHoldStart(),
                      onTapUp: (_) => onHoldEnd(),
                      onTapCancel: onHoldEnd,
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (holding)
                              SizedBox.expand(
                                child: quiet
                                    ? const CircularProgressIndicator(value: 0.6, strokeWidth: 5, color: Color(0xFF9BE7A9))
                                    : TweenAnimationBuilder<double>(
                                        key: ValueKey('call-$holdN'),
                                        tween: Tween(begin: 0, end: 1),
                                        duration: const Duration(milliseconds: kM7HoldMs),
                                        builder: (_, v, _) => CircularProgressIndicator(value: v, strokeWidth: 5, color: const Color(0xFF9BE7A9)),
                                      ),
                              ),
                            Container(
                              width: 66,
                              height: 66,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4CC46A), Color(0xFF1E8A3C)]),
                              ),
                              child: const Icon(Icons.call_rounded, size: 32, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(M7ClaimRouteLines.callBtn, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A paper slid out at a stop (a swipe down files it; the folded letter
/// opens with a swipe up). At the desk: a small card, no gesture.
class _PaperCard extends StatelessWidget {
  const _PaperCard({super.key, required this.paper, required this.quiet, this.sub, this.small = false, this.folded = false, this.onSwipe});
  final M7ClaimPaper paper;
  final String? sub;
  final bool small;
  final bool folded;
  final bool quiet;
  final ValueChanged<double>? onSwipe;

  @override
  Widget build(BuildContext context) {
    final name = M7ClaimRouteLines.paper(paper);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: folded ? const Color(0xFFF1E3C2) : const Color(0xFFFDFBF4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: EdgeInsets.all(small ? 4 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              folded ? Icons.mark_email_unread_rounded : (paper == M7ClaimPaper.bill ? Icons.receipt_long_rounded : Icons.description_rounded),
              size: small ? 18 : 28,
              color: const Color(0xFF8A6A3C),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(name, style: bangla(fontSize: small ? 10 : 13, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
            ),
            if (sub != null && !small)
              FittedBox(fit: BoxFit.scaleDown, child: Text(sub!, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF6A4A26)))),
            if (!small) Expanded(child: CustomPaint(painter: _LinesPainter(folded: folded))),
          ],
        ),
      ),
    );
    final body = quiet
        ? card
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
            builder: (_, v, child) => Transform.translate(offset: Offset(-40 * v, 0), child: Opacity(opacity: 1 - v, child: child)),
            child: card,
          );
    final swipe = onSwipe;
    return Semantics(
      label: name,
      child: swipe == null ? IgnorePointer(child: body) : _Swipe(onSwipe: swipe, child: body),
    );
  }
}

/// A vertical swipe on its child (the total travel, + = down).
class _Swipe extends StatefulWidget {
  const _Swipe({required this.onSwipe, required this.child});
  final ValueChanged<double> onSwipe;
  final Widget child;

  @override
  State<_Swipe> createState() => _SwipeState();
}

class _SwipeState extends State<_Swipe> {
  double _dy = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onVerticalDragStart: (_) => _dy = 0,
        onVerticalDragUpdate: (d) => _dy += d.delta.dy,
        onVerticalDragEnd: (_) => widget.onSwipe(_dy),
        child: widget.child,
      );
}

/// Ruled lines on a paper (or the flap of the folded letter).
class _LinesPainter extends CustomPainter {
  const _LinesPainter({required this.folded});
  final bool folded;

  @override
  void paint(Canvas c, Size size) {
    if (folded) {
      final p = Paint()
        ..color = const Color(0x668A6A3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      c.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(size.width / 2, size.height * 0.7)
            ..lineTo(size.width, 0),
          p);
      return;
    }
    final p = Paint()
      ..color = const Color(0x443A2A16)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.25 + i * 0.25);
      c.drawLine(Offset(2, y), Offset(size.width - (i.isOdd ? 20 : 4), y), p);
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => old.folded != folded;
}

/// The company letter, open: what the company says, and a signature box.
class _LetterPanel extends StatelessWidget {
  const _LetterPanel({
    super.key,
    required this.signKey,
    required this.body,
    required this.copied,
    required this.signed,
    required this.holding,
    required this.holdN,
    required this.quiet,
    required this.onSwipe,
    required this.onHoldStart,
    required this.onHoldEnd,
  });
  final GlobalKey signKey;
  final String body;
  final bool copied;
  final bool signed;
  final bool holding;
  final int holdN;
  final bool quiet;
  final ValueChanged<double> onSwipe;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final ink = bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF2A2018), height: 1.25);
    return Semantics(
      label: M7ClaimRouteLines.paper(M7ClaimPaper.letter),
      child: _Swipe(
        onSwipe: onSwipe,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF8A6A3C), width: 1.8),
            boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(M7ClaimRouteLines.paper(M7ClaimPaper.letter), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF7A2A16))),
                Text(M7ClaimRouteLines.letterGot, style: ink),
                Expanded(child: Text(body, style: ink, overflow: TextOverflow.fade)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (copied)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2E6B8A), width: 1.4), borderRadius: BorderRadius.circular(4)),
                        child: Text(M7ClaimRouteLines.copyStamp, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF2E6B8A))),
                      ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: M7ClaimRouteLines.signLabel,
                      excludeSemantics: true,
                      child: GestureDetector(
                        key: signKey,
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => onHoldStart(),
                        onTapUp: (_) => onHoldEnd(),
                        onTapCancel: onHoldEnd,
                        child: Container(
                          width: 104,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4ECD6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF8A6A3C), width: 1.2),
                          ),
                          child: Stack(
                            children: [
                              if (holding)
                                Positioned.fill(
                                  child: quiet
                                      ? const ColoredBox(color: Color(0x332E6B8A))
                                      : TweenAnimationBuilder<double>(
                                          key: ValueKey('sign-$holdN'),
                                          tween: Tween(begin: 0, end: 1),
                                          duration: const Duration(milliseconds: kM7HoldMs),
                                          builder: (_, v, _) => FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: v, child: const ColoredBox(color: Color(0x332E6B8A))),
                                        ),
                                ),
                              Positioned(left: 6, top: 2, child: Text(M7ClaimRouteLines.signLabel, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6A4A26)))),
                              Positioned(left: 8, right: 8, bottom: 8, child: Container(height: 1, color: const Color(0xFF8A6A3C))),
                              if (signed) Positioned.fill(child: CustomPaint(painter: _ScrawlPainter())),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// His signature on the letter.
class _ScrawlPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1F3B8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(14, size.height - 12);
    for (var i = 0; i < 6; i++) {
      path.relativeQuadraticBezierTo(5, -12, 12, i.isEven ? 2 : -1);
    }
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ScrawlPainter old) => false;
}
