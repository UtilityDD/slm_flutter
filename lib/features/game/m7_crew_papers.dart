import 'dart:async';
import 'dart:math' as math;

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
import 'm7_crew_papers_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm7_crew_papers_world.dart' show M7Look, m7Looks;

// Lesson 7.10 "একজন 'সার্টিফায়েড' লাইনম্যান: লাইসেন্স ও যোগ্যতার গুরুত্ব",
// কাজ 1 "যোগ্য হাতে কাজ" (pack do_7_10_a, engineType m7_crew_papers).
// Morning roll-call in a sub-division store yard. The player is the gang's
// foreman: he flips a worker's papers (a wallet of five sleeves: পরিচয়পত্র with
// the company register line, ITI, ওয়ার্কম্যান পারমিট, প্রশিক্ষণের সার্টিফিকেট,
// লগবুক; a missing paper is an empty sleeve) and staffs the day's job cards.
//
//   • Tap a worker (round 3 also the player's own figure): his wallet opens;
//     swipe the sleeves right to left (a fresh order for every worker every
//     play). A sleeve already seen gets a dog-ear, the same for everyone.
//   • Drag a worker onto a job card (one per card; tap the card to take him
//     back). Drag a job card into the 'আজ নয় — প্রশিক্ষিত লোক চাই' tray to
//     hold it (tap the held card to bring it back).
//   • Every card filled or held: 'শিফট শুরু' rises. Nothing is judged before
//     it. Then the cards are judged in board order: right → the worker walks
//     off, ◆; a right hold → stamped, ◆; a slip → its card and a strike (the
//     card goes back for a new try); deadly → the yard freezes first.
//   • One reason deck per round, on its key decision (the live-line card, else
//     the HV joint, the contractor, the shutdown job or the man left at home).
//   • Round 1: 3 workers, 2 jobs. Round 2: 4 workers, 3 jobs. Round 3: 4 workers
//     and the player's own wallet, 3 jobs; sometimes a job nobody can take. The
//     '11 kV লাইভ লাইন কাজ' card comes in round 2 or 3 (dealt); whether anyone
//     holds the live-line certificate is dealt too.
//   • The careless coworker, once a play, in the live-line round: his myth 2
//     word for word, about a worker without the live-line certificate. He comes
//     at the first of: opening that worker's wallet, touching the live-line
//     card, tapping 'শিফট শুরু'. Listening drops that worker on the live-line
//     card and starts the shift: deadly.
//
// The lesson's rules, and only those (lesson 7.10, tool/all_training_chapters_bn.json):
//   • point 0 (index 0): a competent man has the government's certificate of
//     competency or an electrical work permit, his name on the company
//     register, and enough training and experience.
//   • point 1: the workman permit (State Electrical Licensing Board; ITI,
//     years of work, an exam); many big firms and contractors require it.
//   • point 2: examples of training — live-line work, HV cable jointing
//     certification, first aid and fire safety.
//   • myth 2: 'licences are only for show, experience is what counts'.
//   • sending someone untrained to risky work is a breach of the law.
// No age rule (ruling X3/O2: the live lesson dropped it); the helper is a man
// whose name is not yet on the company register and whose training is still
// going on; the fresh joiner has an empty logbook.
//
// Deadly (M7-5): anyone without the live-line training certificate on the
// '11 kV লাইভ লাইন কাজ' card; listening to the coworker's push onto it (X2/B1).
// Slips: HV joint without the jointing certification; the contractor job
// without a workman permit; any line job to the helper off the register or to
// the fresh joiner with an empty logbook; a needless hold. Three slips strike
// the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the full
// scene, corner guide (tap: the task again, another way), ◆ on the table →
// "কেন …?" (the deck opens at once), the coworker's two beats (the decisive
// controls wait for him: his target's wallet, the live-line card, the shift
// button), deadly freeze. Gesture hands (how, never what): a sweep over every
// gang figure; the wallet swipe right to left; a short nudge up from the last
// worker opened; a sweep over the job cards and the tray together; a tap on
// 'শিফট শুরু'. Voice: guide lines on the device voice until recorded
// (newGuideLines); the coworker's push needs his clip (newRivalLines).

// ============================================================================
// Content
// ============================================================================

/// What a worker is (his papers); the look is dealt apart from it.
enum M7Prof { live, jointer, permit, veteran, fresh, helper, firstAid }

/// The day's jobs.
enum M7Job { shutdown, contractor, joint, live }

/// The five sleeves of a wallet.
enum M7Sleeve { id, iti, permit, training, logbook }

/// The training certificates.
enum M7Cert { live, joint, firstAid }

/// The key decision a round's reason asks about.
enum M7Why {
  shutdownGiven,
  shutdownHeld,
  contractorGiven,
  contractorHeld,
  jointGiven,
  jointHeld,
  liveGiven,
  liveHeld,
  helperLeft,
  freshLeft,
}

abstract final class M7PapersLines {
  static const title = 'যোগ্য হাতে কাজ';
  // DRAFT wording — owner (M6-12 / M7-10). The intro is the spec's line.
  static const intro = 'আজ আপনি দলের ফোরম্যান! কাগজ দেখে ঠিক লোককে ঠিক কাজ দিন।';

  // The guide's task now (tap him: the same task, a different way).
  // DRAFT wording — owner.
  static const askOpen = 'আগে কার কাগজ দেখবেন?';
  static const askPlace = 'কাজের কার্ডে লোক বসান, আজকের নয় এমন কাজ ট্রেতে রাখুন।';
  static const askStart = 'সব কার্ড ভরা — এবার শিফট শুরু করুন।';
  static const tasks = [askOpen, askPlace, askStart];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (not spoken).
  static const yardLabel = 'স্টোরের উঠোন';
  static const board = 'আজকের কাজ';
  static const tray = 'আজ নয় — প্রশিক্ষিত লোক চাই';
  static const shift = 'শিফট শুরু';
  static const walletClose = 'কাগজ বন্ধ';
  static const you = 'আপনি';
  static const empty = 'খালি';
  static String progress(int i) => enDigits('দফা ${i + 1}');
  static String walletOf(String name) => 'কাগজ — $name';

  static const jobText = <M7Job, String>{
    M7Job.shutdown: 'শাটডাউনে লাইন মেরামত',
    M7Job.contractor: 'ঠিকাদারের লাইন রক্ষণাবেক্ষণ — শর্ত: ওয়ার্কম্যান পারমিট',
    M7Job.joint: 'HV কেবিল জয়েন্ট',
    M7Job.live: '11 kV লাইভ লাইন কাজ',
  };

  static const sleeveTitle = <M7Sleeve, String>{
    M7Sleeve.id: 'পরিচয়পত্র',
    M7Sleeve.iti: 'ITI সার্টিফিকেট',
    M7Sleeve.permit: 'ওয়ার্কম্যান পারমিট',
    M7Sleeve.training: 'প্রশিক্ষণের সার্টিফিকেট',
    M7Sleeve.logbook: 'লগবুক',
  };
  static const registerYes = 'কোম্পানির রেজিস্টারে নাম: আছে';
  static const registerNo = 'কোম্পানির রেজিস্টারে নাম: নেই';
  static const itiTrade = 'ট্রেড: ইলেকট্রিশিয়ান';
  static const permitBoard = 'রাজ্য ইলেকট্রিক্যাল লাইসেন্সিং বোর্ড';
  static String permitNo(int n) => enDigits('নম্বর WP-$n');
  static const certName = <M7Cert, String>{
    M7Cert.live: 'লাইভ লাইন প্রশিক্ষণ',
    M7Cert.joint: 'HV কেবিল জয়েন্টিং সার্টিফিকেশন',
    M7Cert.firstAid: 'ফার্স্ট এইড ও ফায়ার সেফটি',
  };
  static const trainingOngoing = 'প্রশিক্ষণ চলছে';
  static String logbookText(int months) {
    if (months <= 0) return empty;
    return enDigits(months < 12 ? 'কাজের অভিজ্ঞতা: $months মাস' : 'কাজের অভিজ্ঞতা: ${months ~/ 12} বছর');
  }

  static const names = [
    'রফিক',
    'অমল',
    'বিকাশ',
    'তাপস',
    'শ্যামল',
    'নির্মল',
    'গৌতম',
    'দীপক',
    'সুমন',
    'প্রদীপ',
    'কার্তিক',
    'আশিস',
  ];

  // The reason decks: a question per key decision, two right phrasings fitting
  // what the player did, and the field myths / excuses as the wrong cards.
  // DRAFT wording — owner. Questions from the spec; the rest new.
  static const whyQ = <M7Why, String>{
    M7Why.liveGiven: 'লাইভ লাইনের কাজ কেন ওঁকে দিলেন?',
    M7Why.liveHeld: "লাইভ লাইনের কাজ কেন আজ 'আজ নয়' ট্রেতে রাখলেন?",
    M7Why.jointGiven: 'HV কেবিল জয়েন্ট কেন ওঁকে দিলেন?',
    M7Why.jointHeld: "HV কেবিল জয়েন্ট কেন আজ 'আজ নয়' ট্রেতে রাখলেন?",
    M7Why.contractorGiven: 'ঠিকাদারের কাজে কেন ওঁকে পাঠালেন?',
    M7Why.contractorHeld: "ঠিকাদারের কাজ কেন আজ 'আজ নয়' ট্রেতে রাখলেন?",
    M7Why.shutdownGiven: 'শাটডাউনের মেরামতে কেন ওঁকে দিলেন?',
    M7Why.shutdownHeld: "শাটডাউনের মেরামত কেন আজ 'আজ নয়' ট্রেতে রাখলেন?",
    M7Why.helperLeft: 'ওই সহকারীকে কেন লাইনের কাজ দিলেন না?',
    M7Why.freshLeft: 'নতুন ছেলেটিকে কেন কাজে পাঠালেন না?',
  };
  static const whyRight = <M7Why, List<String>>{
    M7Why.liveGiven: ['ওঁর লাইভ লাইনের প্রশিক্ষণের কাগজ আছে', 'লাইভ লাইনে প্রশিক্ষিত — সার্টিফিকেটও আছে'],
    M7Why.liveHeld: ['কারও লাইভ লাইনের প্রশিক্ষণের কাগজ নেই', 'প্রশিক্ষণের কাগজ ছাড়া লাইভ লাইনে নয়'],
    M7Why.jointGiven: ['ওঁর HV কেবিল জয়েন্টিং সার্টিফিকেশন আছে', 'জয়েন্টিং-এর সার্টিফিকেট ওঁরই আছে, তাই'],
    M7Why.jointHeld: ['কারও জয়েন্টিং-এর সার্টিফিকেট নেই, তাই', 'জয়েন্টিং-এর কাগজ ছাড়া কাউকে দেওয়া নয়'],
    M7Why.contractorGiven: ['ওঁর ওয়ার্কম্যান পারমিট আছে, শর্ত মিলেছে', 'শর্তের ওয়ার্কম্যান পারমিট ওঁর আছে, তাই'],
    M7Why.contractorHeld: ['কারও ওয়ার্কম্যান পারমিট নেই, মেলেনি শর্ত', 'শর্তের পারমিট কারও নেই, তাই আজ নয়'],
    M7Why.shutdownGiven: ['রেজিস্টারে নাম আছে, লগবুকে কাজও লেখা', 'নাম রেজিস্টারে আছে, অভিজ্ঞতাও লেখা আছে'],
    M7Why.shutdownHeld: ['রেজিস্টার আর লগবুক কারও মেলেনি, তাই', 'কাজের মতো কাগজ কারও নেই, তাই আজ নয়'],
    M7Why.helperLeft: ['ওঁর নাম কোম্পানির রেজিস্টারে এখনও নেই', 'রেজিস্টারে নাম নেই, প্রশিক্ষণ চলছে মাত্র'],
    M7Why.freshLeft: ['ওঁর লগবুক খালি, কাজের অভিজ্ঞতা নেই', 'নতুন লোক, লগবুকে এখনও কোনো কাজ নেই'],
  };
  static const myths = [
    'অভিজ্ঞতাই আসল, কাগজ তো দেখানোর জন্য',
    'ওঁর হাত ভালো, কাগজ না থাকলেও চলে যায়',
    'আজ লোক কম, যাকে পাই তাকেই দিতে হবে',
    'কাজ শেখার জন্যই ওঁকে পাঠানো ভালো',
    'সিনিয়র বলেছেন, তাই কাগজ দেখিনি আর',
    'দেরি হচ্ছে, আজ একবার চালিয়ে নিই তো',
    'কেউ দেখবে না, সুপারভাইজার আসছেন না',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  /// The careless coworker: the lesson's myth 2 word for word (spec
  /// coworkerPushBn). DRAFT wording of the answers — owner (M7-10).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLine = 'লাইসেন্স বা সার্টিফিকেট তো শুধু কাগজে দেখানোর জন্য, আসল তো হলো কাজের অভিজ্ঞতা।';
  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: [
      'না — সার্টিফিকেটই প্রমাণ উনি নিরাপদে করতে প্রশিক্ষিত',
      'না — লাইভ লাইনে প্রশিক্ষণের কাগজ ছাড়া কাউকে নয়',
      'না — কাগজ দেখে তবেই লাইভ লাইনের কাজ দেওয়া হবে',
    ],
    wrong: [
      'হ্যাঁ — 20 বছরের হাত আছে, ওঁর কাগজ লাগে না',
      'হ্যাঁ — অভিজ্ঞতাই আসল, কাগজ পরে হবে, এখন চলুক',
      'হ্যাঁ — ফার্স্ট এইডের কাগজ তো ওঁর আছেই, চলবে',
      'হ্যাঁ — আজ শুধু একবার, কেউ দেখতে পাবে না',
      'হ্যাঁ — উনি নিজেই বলছেন পারবেন, দিয়ে দিন',
    ],
    asks: ['কী করবেন?', 'ও বলছে কাগজ ছাড়াই ওঁকে লাইভ লাইনে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না কাগজ দেখবেন?'],
  );

  static const callHeld = 'ঠিক! কাগজই প্রমাণ — লাইভ লাইনে প্রশিক্ষণ ছাড়া কেউ নয়।';
  static const allSet = 'সবাই ঠিক কাজে — কাগজ দেখে লোক বসানোই আইন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে সবার কাগজ দেখে তবে কাজ দিন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন": which paper fitted which job (not spoken).
  static const caughtLive = 'লাইভ লাইন প্রশিক্ষণ — 11 kV লাইভ লাইনের কাজ';
  static const caughtJoint = 'জয়েন্টিং সার্টিফিকেশন — HV কেবিল জয়েন্ট';
  static const caughtContractor = 'ওয়ার্কম্যান পারমিট — ঠিকাদারের কাজ';
  static const caughtShutdown = 'রেজিস্টারে নাম, লগবুকে কাজ — শাটডাউনের মেরামত';
  static const caughtHold = 'যোগ্য কেউ নেই — কাজ আজ নয়';
  static const caughtCall = '“কাগজ শুধু দেখানোর জন্য” — এই কথায় “না” বলেছেন';
  static String caughtFor(M7Job j) => switch (j) {
        M7Job.live => caughtLive,
        M7Job.joint => caughtJoint,
        M7Job.contractor => caughtContractor,
        M7Job.shutdown => caughtShutdown,
      };

  /// The coworker's push (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworkerLine];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until
  /// then the device voice). The kit's own praise and 'wrong' bags are left
  /// out.
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        ...tapWhy,
        ...whyQ.values,
        ...coworker.asks,
        callHeld,
        allSet,
        quick,
        fail,
        deadlyWord,
        nearMissWord,
        for (final m in M7PapersMistakes.all) m.textBn,
      }.toList();

  /// Every fixed line on screen or spoken (tests: English digits, no পানি).
  static List<String> get allText => [
        ...newGuideLines,
        yardLabel,
        board,
        tray,
        shift,
        walletClose,
        you,
        empty,
        ...jobText.values,
        ...sleeveTitle.values,
        registerYes,
        registerNo,
        itiTrade,
        permitBoard,
        permitNo(4821),
        ...certName.values,
        trainingOngoing,
        logbookText(5),
        logbookText(240),
        ...names,
        ...allWhyRight,
        ...myths,
        ...coworker.recordedLines,
        ...coworker.right,
        ...coworker.wrong,
        caughtLive,
        caughtJoint,
        caughtContractor,
        caughtShutdown,
        caughtHold,
        caughtCall,
      ];
}

abstract final class M7PapersMistakes {
  static const _dir = 'assets/game/art/m7_crew_papers';

  // DRAFT wording — owner (M6-12). Lesson points (0-based, section 1):
  // 0 the competent man, 1 the workman permit, 2 training (live line, HV
  // jointing, first aid). The slip cards say it is still against the law,
  // never that it is allowed (M7-5).
  static const liveUntrained = DoMistake(
    key: '7.10/m7_crew_papers/live-untrained',
    textBn: 'লাইভ লাইনের কাজে প্রশিক্ষণের সার্টিফিকেট ছাড়া কাউকে নয় — অভিজ্ঞতা থাকলেও না।',
    art: '$_dir/live_untrained.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const listenedLive = DoMistake(
    key: '7.10/m7_crew_papers/listened-live',
    textBn: 'অভিজ্ঞতা দরকার, কিন্তু সার্টিফিকেটই প্রমাণ যে উনি নিরাপদে কাজ করতে প্রশিক্ষিত। কাগজ ছাড়া লাইভ লাইনে নয়।',
    art: '$_dir/listened_live.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const joint = DoMistake(
    key: '7.10/m7_crew_papers/joint-uncertified',
    textBn: 'HV কেবিল জয়েন্ট জয়েন্টিং-এর সার্টিফিকেশন থাকা লোকের কাজ। প্রশিক্ষণ ছাড়া ঝুঁকির কাজে পাঠানো আইনের লঙ্ঘন।',
    art: '$_dir/joint.svg',
    lessonPoint: 2,
  );
  static const contractor = DoMistake(
    key: '7.10/m7_crew_papers/contractor-no-permit',
    textBn: 'ঠিকাদারের কাজের শর্ত ওয়ার্কম্যান পারমিট। ITI, কোম্পানির আইডি বা ফার্স্ট এইডের কাগজ তার বদলে চলে না।',
    art: '$_dir/contractor.svg',
    lessonPoint: 1,
  );
  static const helper = DoMistake(
    key: '7.10/m7_crew_papers/helper-line',
    textBn: 'যাঁর নাম কোম্পানির রেজিস্টারে নেই আর প্রশিক্ষণ চলছে, তাঁকে লাইনের কাজে পাঠানো আইনের লঙ্ঘন।',
    art: '$_dir/helper.svg',
    lessonPoint: 0,
  );
  static const fresh = DoMistake(
    key: '7.10/m7_crew_papers/fresh-line',
    textBn: 'নতুন যোগ দিয়েছেন, লগবুক খালি — অভিজ্ঞতা ছাড়া লাইনের কাজে পাঠানো আইনের লঙ্ঘন।',
    art: '$_dir/fresh.svg',
    lessonPoint: 0,
  );
  static const hold = DoMistake(
    key: '7.10/m7_crew_papers/needless-hold',
    textBn: 'এই কাজের মতো যোগ্য লোক হাতেই ছিল — কাজটা অকারণে আজ নয়-তে রাখা ঠিক নয়।',
    art: '$_dir/hold.svg',
    lessonPoint: 0,
  );

  static const all = [liveUntrained, listenedLive, joint, contractor, helper, fresh, hold];

  /// The catalog's deadlyRules (the level's deadly keys).
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];

  /// What is wrong with sending [p] to [j]: null = a fit (the papers the job
  /// needs), the deadly card on the live-line job, else the slip card of what
  /// THIS man lacks (off the register first, then an empty logbook, then the
  /// paper the job asks for).
  static DoMistake? fault(M7Person p, M7Job j) {
    if (j == M7Job.live) return p.certs.contains(M7Cert.live) ? null : liveUntrained;
    if (!p.onRegister) return helper;
    if (p.logMonths <= 0) return fresh;
    return switch (j) {
      M7Job.shutdown => null,
      M7Job.contractor => p.hasPermit ? null : contractor,
      M7Job.joint => p.certs.contains(M7Cert.joint) ? null : joint,
      M7Job.live => liveUntrained,
    };
  }
}

/// One worker (or the player): his papers, his look, his sleeve order.
@immutable
class M7Person {
  const M7Person({
    required this.name,
    required this.prof,
    required this.look,
    required this.certs,
    required this.logMonths,
    required this.sleeves,
    required this.permitNo,
    this.isPlayer = false,
  });

  final String name;
  final M7Prof prof;
  final int look;
  final Set<M7Cert> certs;

  /// Months in the logbook (0 = an empty logbook).
  final int logMonths;
  final List<M7Sleeve> sleeves;
  final int permitNo;
  final bool isPlayer;

  bool get hasIti => prof == M7Prof.live || prof == M7Prof.jointer || prof == M7Prof.permit || prof == M7Prof.fresh;
  bool get hasPermit => prof == M7Prof.live || prof == M7Prof.jointer || prof == M7Prof.permit;
  bool get onRegister => prof != M7Prof.helper;
  bool get trainingOngoing => prof == M7Prof.helper;
}

/// One round: the people, the job cards in board order, the coworker's
/// target (live-line round only), a pick for the reason.
@immutable
class M7Round {
  const M7Round({required this.people, required this.jobs, required this.target, required this.whyPick});
  final List<M7Person> people;
  final List<M7Job> jobs;

  /// Index of the person the coworker points at (null: no live-line card).
  final int? target;
  final int whyPick;

  int get liveJob => jobs.indexOf(M7Job.live);
  bool get hasLive => liveJob >= 0;
}

@immutable
class M7PapersDeal {
  const M7PapersDeal({required this.rounds, required this.liveRound, required this.liveAvailable});
  final List<M7Round> rounds;

  /// The round (1 or 2) that carries the live-line card.
  final int liveRound;

  /// Someone in the live-line round holds the live-line certificate.
  final bool liveAvailable;
}

bool _matchable(List<List<int>> qual, [int k = 0, Set<int>? used]) {
  used ??= {};
  if (k == qual.length) return true;
  if (qual[k].isEmpty) return _matchable(qual, k + 1, used);
  for (final p in qual[k]) {
    if (used.contains(p)) continue;
    used.add(p);
    final ok = _matchable(qual, k + 1, used);
    used.remove(p);
    if (ok) return true;
  }
  return false;
}

M7Person _person(math.Random rng, String name, M7Prof prof, int look, {bool player = false}) {
  Set<M7Cert> certs;
  int months;
  switch (prof) {
    case M7Prof.live:
      certs = {M7Cert.live, if (rng.nextBool()) M7Cert.firstAid};
      months = 60 + rng.nextInt(85);
    case M7Prof.jointer:
      certs = {M7Cert.joint, if (rng.nextBool()) M7Cert.firstAid};
      months = 48 + rng.nextInt(73);
    case M7Prof.permit:
      certs = {if (rng.nextBool()) M7Cert.firstAid};
      months = 36 + rng.nextInt(61);
    case M7Prof.veteran:
      certs = {};
      months = 216 + rng.nextInt(85);
    case M7Prof.fresh:
      certs = {};
      months = 0;
    case M7Prof.helper:
      certs = {};
      months = 2 + rng.nextInt(5);
    case M7Prof.firstAid:
      certs = {M7Cert.firstAid};
      months = 36 + rng.nextInt(37);
  }
  return M7Person(
    name: player ? M7PapersLines.you : name,
    prof: prof,
    look: look,
    certs: certs,
    logMonths: months,
    sleeves: [...M7Sleeve.values]..shuffle(rng),
    permitNo: 1000 + rng.nextInt(9000),
    isPlayer: player,
  );
}

/// Profile weights: the live-line man and the jointer are a little rarer than
/// the men who only look the part.
const _profBag = [
  M7Prof.live,
  M7Prof.live,
  M7Prof.jointer,
  M7Prof.jointer,
  M7Prof.permit,
  M7Prof.permit,
  M7Prof.permit,
  M7Prof.veteran,
  M7Prof.veteran,
  M7Prof.fresh,
  M7Prof.fresh,
  M7Prof.helper,
  M7Prof.helper,
  M7Prof.firstAid,
  M7Prof.firstAid,
];

/// Deals one round: [n] people (the last random slot the player when
/// [player]), the [jobs] cards; [nobody] = how many cards no one in the gang
/// can take (0 or 1); [liveAvailable] (live-line rounds): someone holds the
/// live-line certificate. A full correct roster always exists: every card
/// someone can take is staffed by a different qualified person.
M7Round _dealRound(
  math.Random rng, {
  required int n,
  required List<M7Job> jobs,
  required bool player,
  required int nobody,
  required bool? liveAvailable,
  required List<String> names,
}) {
  for (var tries = 0; tries < 4000; tries++) {
    final profs = [for (var i = 0; i < n; i++) _profBag[rng.nextInt(_profBag.length)]];
    if (profs.toSet().length < 2) continue;
    final looks = [for (var i = 0; i < m7Looks.length; i++) i]..shuffle(rng);
    final playerAt = player ? rng.nextInt(n) : -1;
    final people = [
      for (var i = 0; i < n; i++) _person(rng, names[i], profs[i], looks[i], player: i == playerAt),
    ];
    final hasLive = jobs.contains(M7Job.live);
    if (hasLive) {
      final avail = people.any((p) => p.certs.contains(M7Cert.live));
      if (avail != liveAvailable) continue;
      if (!people.any((p) => !p.certs.contains(M7Cert.live))) continue;
    }
    final qual = [
      for (final j in jobs) [for (var i = 0; i < n; i++) if (M7PapersMistakes.fault(people[i], j) == null) i],
    ];
    if (qual.where((q) => q.isEmpty).length != nobody) continue;
    if (!_matchable(qual)) continue;
    int? target;
    if (hasLive) {
      final cands = [for (var i = 0; i < n; i++) if (!people[i].certs.contains(M7Cert.live)) i];
      target = cands[rng.nextInt(cands.length)];
    }
    return M7Round(people: people, jobs: jobs, target: target, whyPick: rng.nextInt(1000));
  }
  throw StateError('no round dealt');
}

/// Three rounds: 3 workers and 2 jobs; 4 workers and 3 jobs; 4 workers and the
/// player's own wallet and 3 jobs. The live-line card is in round 2 or 3
/// (dealt); whether anyone holds the live-line certificate is dealt; round 3
/// sometimes has a job nobody can take; names, looks, sleeves and board order
/// are shuffled.
M7PapersDeal m7PapersDeal(math.Random rng) {
  final liveRound = 1 + rng.nextInt(2);
  final liveAvail = rng.nextBool();
  final names = [...M7PapersLines.names]..shuffle(rng);
  const plain = [M7Job.shutdown, M7Job.contractor, M7Job.joint];
  List<M7Job> jobs(int count, bool live) {
    final p = [...plain]..shuffle(rng);
    final l = live ? [M7Job.live, ...p.take(count - 1)] : p.take(count).toList();
    return l..shuffle(rng);
  }

  final lateNobody = rng.nextDouble() < 0.4;
  final rounds = <M7Round>[
    _dealRound(rng, n: 3, jobs: jobs(2, false), player: false, nobody: 0, liveAvailable: null, names: names),
    _dealRound(rng,
        n: 4,
        jobs: jobs(3, liveRound == 1),
        player: false,
        nobody: liveRound == 1 && !liveAvail ? 1 : 0,
        liveAvailable: liveRound == 1 ? liveAvail : null,
        names: names.sublist(3)),
    _dealRound(rng,
        n: 5,
        jobs: jobs(3, liveRound == 2),
        player: true,
        nobody: liveRound == 2 ? (liveAvail ? 0 : 1) : (lateNobody ? 1 : 0),
        liveAvailable: liveRound == 2 ? liveAvail : null,
        names: [...names.sublist(7), ...names.sublist(0, 7)]),
  ];
  return M7PapersDeal(rounds: rounds, liveRound: liveRound, liveAvailable: liveAvail);
}

enum M7Result { ok, okHold, slip, deadly }

/// What judging one card said.
@immutable
class M7Verdict {
  const M7Verdict(this.job, this.result, this.mistake, this.person);
  final int job;
  final M7Result result;
  final DoMistake? mistake;

  /// The person on the card (null: a hold).
  final int? person;
}

/// The play state (pure logic).
class M7PapersRun {
  M7PapersRun(this.deal);
  final M7PapersDeal deal;

  int roundIdx = 0;
  final Map<int, int> _assign = {};
  final Set<int> held = {};
  final Set<int> locked = {};
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];
  final Map<String, int> _jobSlips = {};

  M7Round get round => deal.rounds[roundIdx];
  int get roundCount => deal.rounds.length;
  bool get lastRound => roundIdx == roundCount - 1;
  bool get roundDone => locked.length == round.jobs.length;
  bool get finished => lastRound && roundDone && deadly == null;
  bool get ended => finished || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => finished && percent >= 55;

  /// The person on card [j] (null: none, or held).
  int? personOn(int j) => _assign[j];
  bool isHeld(int j) => held.contains(j);
  bool isLocked(int j) => locked.contains(j);
  int get placedCount => _assign.length + held.length;
  Set<int> get _lockedPeople => {for (final j in locked) ?_assign[j]};
  bool personLocked(int p) => _lockedPeople.contains(p);

  /// The card person [p] stands on (null: in the gang).
  int? jobOf(int p) {
    for (final e in _assign.entries) {
      if (e.value == p) return e.key;
    }
    return null;
  }

  /// People still in the yard (not on a card).
  List<int> get free => [for (var i = 0; i < round.people.length; i++) if (jobOf(i) == null) i];

  bool get ready => !ended && [for (var j = 0; j < round.jobs.length; j++) locked.contains(j) || _assign.containsKey(j) || held.contains(j)].every((x) => x);

  bool canPlace(int p, int j) => !ended && !locked.contains(j) && !personLocked(p);

  /// Puts person [p] on card [j] (he leaves his old card; whoever stood there
  /// goes back to the gang; a held card comes off the tray).
  bool place(int p, int j) {
    if (!canPlace(p, j)) return false;
    final old = jobOf(p);
    if (old != null) _assign.remove(old);
    held.remove(j);
    _assign[j] = p;
    return true;
  }

  /// Card [j] into the tray.
  bool hold(int j) {
    if (ended || locked.contains(j)) return false;
    _assign.remove(j);
    held.add(j);
    return true;
  }

  /// Takes the person (or the hold) off card [j].
  bool release(int j) {
    if (ended || locked.contains(j)) return false;
    final had = _assign.remove(j) != null;
    return held.remove(j) || had;
  }

  String _key(int j) => '$roundIdx/$j';
  int jobSlips(int j) => _jobSlips[_key(j)] ?? 0;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// The first card not judged yet, judged now (call only when [ready]).
  /// Null: all done.
  M7Verdict? judgeNext() {
    if (ended) return null;
    int? j;
    for (var i = 0; i < round.jobs.length; i++) {
      if (!locked.contains(i)) {
        j = i;
        break;
      }
    }
    if (j == null) return null;
    final job = round.jobs[j];
    if (held.contains(j)) {
      final taken = _assign.values.toSet();
      final someone = [for (var i = 0; i < round.people.length; i++) if (!taken.contains(i)) i].any((i) => M7PapersMistakes.fault(round.people[i], job) == null);
      if (someone) {
        held.remove(j);
        _slip(j);
        return M7Verdict(j, M7Result.slip, M7PapersMistakes.hold, null);
      }
      locked.add(j);
      if (jobSlips(j) == 0) _tag(M7PapersLines.caughtHold);
      return M7Verdict(j, M7Result.okHold, null, null);
    }
    final p = _assign[j]!;
    final m = M7PapersMistakes.fault(round.people[p], job);
    if (m == null) {
      locked.add(j);
      if (jobSlips(j) == 0) _tag(M7PapersLines.caughtFor(job));
      return M7Verdict(j, M7Result.ok, null, p);
    }
    if (m.deadly) {
      deadly = m;
      return M7Verdict(j, M7Result.deadly, m, p);
    }
    _assign.remove(j);
    _slip(j);
    return M7Verdict(j, M7Result.slip, m, p);
  }

  void _slip(int j) {
    slips++;
    roundSlips++;
    _jobSlips[_key(j)] = jobSlips(j) + 1;
  }

  /// The key decision this round's reason asks about (call when [roundDone]).
  M7Why whyKind() {
    final r = round;
    M7Why? of(M7Job job) {
      final j = r.jobs.indexOf(job);
      if (j < 0) return null;
      final h = held.contains(j);
      return switch (job) {
        M7Job.live => h ? M7Why.liveHeld : M7Why.liveGiven,
        M7Job.joint => h ? M7Why.jointHeld : M7Why.jointGiven,
        M7Job.contractor => h ? M7Why.contractorHeld : M7Why.contractorGiven,
        M7Job.shutdown => h ? M7Why.shutdownHeld : M7Why.shutdownGiven,
      };
    }

    final live = of(M7Job.live);
    if (live != null) return live;
    final taken = _assign.values.toSet();
    final c = <M7Why>[
      ?of(M7Job.shutdown),
      ?of(M7Job.contractor),
      ?of(M7Job.joint),
      if (r.people.indexed.any((e) => e.$2.prof == M7Prof.helper && !e.$2.isPlayer && !taken.contains(e.$1))) M7Why.helperLeft,
      if (r.people.indexed.any((e) => e.$2.prof == M7Prof.fresh && !e.$2.isPlayer && !taken.contains(e.$1))) M7Why.freshLeft,
    ];
    return c[r.whyPick % c.length];
  }

  /// Listened to him: his target goes onto the live-line card and the shift
  /// starts — deadly.
  DoMistake listened() {
    final j = round.liveJob;
    final t = round.target;
    if (j >= 0 && t != null) {
      held.remove(j);
      final old = jobOf(t);
      if (old != null) _assign.remove(old);
      _assign[j] = t;
    }
    deadly = M7PapersMistakes.listenedLive;
    return deadly!;
  }

  /// Refused him.
  void refused() => _tag(M7PapersLines.caughtCall);

  /// The next round (everyone back in the yard).
  void nextRound() {
    if (lastRound) return;
    roundIdx++;
    _assign.clear();
    held.clear();
    locked.clear();
    roundSlips = 0;
  }

  /// A test hook: force the end (a failed play).
  void failDeadly(DoMistake m) => deadly = m;
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   round 1: 3 wallets (open + 4 swipes ≈ 4500) ≈ 13500 + 2 drags 3000 +
///     start 1500 + judging 1500 + reason ~8200 ≈ 27700
///   round 2: 4 wallets ≈ 18000 + 3 drags 4500 + 1500 + 2200 + 8200 ≈ 34400
///   round 3: 5 wallets ≈ 22500 + 4500 + 1500 + 2200 + 8200 ≈ 38900
/// + the coworker once ≈ 9600 + lines ≈ 9000                       ≈ 119600
/// 85 % ≈ 101700 → 100 s.
const m7PapersQuickMs = 100000;

@immutable
class M7CrewPapersPack {
  const M7CrewPapersPack({required this.id, required this.titleBn, this.quickMs = m7PapersQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7CrewPapersPack> m7CrewPapersPacks = {
  'do_7_10_a': M7CrewPapersPack(id: 'do_7_10_a', titleBn: M7PapersLines.title),
};

/// Test hook: the live run (tests only).
abstract final class M7CrewPapersProbe {
  static M7PapersRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7CrewPapersPage extends StatefulWidget {
  const M7CrewPapersPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7CrewPapersPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7CrewPapersPage> createState() => _M7CrewPapersPageState();
}

class _M7CrewPapersPageState extends State<M7CrewPapersPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PapersRunPage(
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

class _PapersRunPage extends ConsumerStatefulWidget {
  const _PapersRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7CrewPapersPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PapersRunPage> createState() => _PapersRunPageState();
}

/// A worker being dragged / a job card being dragged.
@immutable
class _PersonDrag {
  const _PersonDrag(this.index);
  final int index;
}

@immutable
class _JobDrag {
  const _JobDrag(this.index);
  final int index;
}

/// Where the page's pieces stand on screen (logical px).
@immutable
class _Layout {
  const _Layout({required this.board, required this.wallet, required this.gang, required this.shift});
  final Rect board;
  final Rect wallet;
  final Rect gang;
  final Rect shift;

  factory _Layout.of(Size size, EdgeInsets pad) {
    final w = size.width;
    final top = pad.top + 112;
    final bottom = pad.bottom + 6;
    final avail = size.height - top - bottom;
    final boardH = (avail * 0.27).clamp(138.0, 168.0);
    final gangH = (avail * 0.2).clamp(112.0, 132.0);
    final board = Rect.fromLTWH(8, top, w - 16, boardH);
    final gang = Rect.fromLTWH(0, size.height - bottom - gangH, w, gangH + bottom);
    final room = gang.top - board.bottom;
    final wh = (room - 124).clamp(150.0, 230.0);
    return _Layout(
      board: board,
      wallet: Rect.fromLTWH(10, board.bottom + 8, w - 20, wh),
      gang: gang,
      shift: Rect.fromLTWH(12, gang.top - 52, 156, 44),
    );
  }
}

class _PapersRunPageState extends ConsumerState<_PapersRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7PapersRun _run;
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
  var _judging = false;
  var _roundBusy = false;

  /// The reason now on the table (its key decision).
  M7Why? _why;

  /// The wallet: whose, which sleeve, and which sleeves each person showed.
  int? _walletFor;
  int _sleeveAt = 0;
  final Map<String, Set<int>> _seen = {};
  int? _lastOpened;
  double _swipe = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  int _stampTok = 0;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _tileKeys = List.generate(5, (_) => GlobalKey());
  final _jobKeys = List.generate(3, (_) => GlobalKey());
  final _trayKey = GlobalKey();
  final _shiftKey = GlobalKey();
  final _sleeveKey = GlobalKey();

  @override
  LevelContext get deathCtx => widget.ctx;

  @override
  void initState() {
    super.initState();
    // The deal first (a seed's play is the same).
    _run = M7PapersRun(m7PapersDeal(widget.rng));
    M7CrewPapersProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M7Round get _r => _run.round;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M7CrewPapersProbe.run, _run)) M7CrewPapersProbe.run = null;
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !struckOut && !_judging && !_roundBusy && !_freeze && !_run.ended;

  /// He is talking (beat 1: no deck yet).
  bool get _coworkerTalking => coworkerOpen && !coworkerChoiceUp;

  bool get _anySeen => _seen.keys.any((k) => k.startsWith('${_run.roundIdx}/'));
  String _seenKey(int p) => '${_run.roundIdx}/$p';
  Set<int> _seenOf(int p) => _seen[_seenKey(p)] ?? const {};

  String get _task {
    if (_run.ready) return M7PapersLines.askStart;
    if (_run.placedCount == 0 && !_anySeen) return M7PapersLines.askOpen;
    return M7PapersLines.askPlace;
  }

  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([M7PapersLines.askOpen]));
  }

  void _startRoundVoice() {
    if (_run.round.hasLive && !coworkerDone && !coworkerDue) scheduleCoworker();
  }

  // --- hands on -----------------------------------------------------------------
  void _tapPerson(int i) {
    if (!_canPlay) return;
    if (_run.jobOf(i) != null || _run.personLocked(i)) return;
    // His target's wallet: he comes first (the wallet waits).
    if (i == _r.target && holdForCoworker()) return;
    if (_walletFor == i) {
      _tick();
      setState(() => _walletFor = null);
      return;
    }
    _tick('sounds/learn/card_deal_a.ogg', 0.45);
    setState(() {
      _walletFor = i;
      _sleeveAt = 0;
      _lastOpened = i;
      _seen.putIfAbsent(_seenKey(i), () => <int>{}).add(0);
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  void _gotoSleeve(int to) {
    final p = _walletFor;
    if (p == null || to < 0 || to > 4 || to == _sleeveAt) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.35);
    setState(() {
      _sleeveAt = to;
      _seen.putIfAbsent(_seenKey(p), () => <int>{}).add(to);
    });
  }

  void _closeWallet() {
    if (!_canPlay || _walletFor == null) return;
    _tick();
    setState(() => _walletFor = null);
  }

  /// A worker dropped on a card.
  void _dropPerson(int p, int j) {
    if (!_canPlay) return;
    if (_r.jobs[j] == M7Job.live && holdForCoworker()) return;
    if (!_run.place(p, j)) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.5);
    HapticFeedback.lightImpact();
    setState(() {
      if (_walletFor == p) _walletFor = null;
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  /// A card dragged into the tray.
  void _dropJob(int j) {
    if (!_canPlay) return;
    if (_r.jobs[j] == M7Job.live && holdForCoworker()) return;
    if (!_run.hold(j)) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.5);
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  /// A tap on a card: take the worker back / bring the held card back.
  void _tapJob(int j) {
    if (!_canPlay) return;
    if (_r.jobs[j] == M7Job.live && holdForCoworker()) return;
    if (!_run.release(j)) {
      _hints.missTap();
      return;
    }
    _tick();
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  /// A drag began on a live-line card that must wait for him (he comes now),
  /// or on him talking (going on working refuses him).
  void _jobHeld(int j, Offset global) {
    if (_coworkerTalking) {
      // Going on working while he talks refuses him.
      if (!_intro && !_ended && _card == null) unawaited(answerCoworker(true, global, direct: true));
      return;
    }
    if (!_canPlay) return;
    if (_r.jobs[j] == M7Job.live) holdForCoworker();
  }

  Future<void> _startShift() async {
    if (!_canPlay || !_run.ready) return;
    if (holdForCoworker()) return;
    setState(() {
      _judging = true;
      _walletFor = null;
    });
    final size = MediaQuery.sizeOf(context);
    while (mounted && !_ended) {
      final v = _run.judgeNext();
      if (v == null) break;
      final origin = Offset(size.width * (0.2 + 0.25 * v.job), size.height * 0.25);
      switch (v.result) {
        case M7Result.ok:
        case M7Result.okHold:
          _tick('sounds/learn/tag_slap.ogg', 0.6);
          _cue('sounds/quiz_right.ogg', volume: 0.5);
          setState(() {
            _stampTok++;
            _wake++;
          });
          unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
          await Future<void>.delayed(Duration(milliseconds: _quiet ? 250 : 900));
        case M7Result.slip:
          setState(() {
            _judging = false;
            _wake++;
          });
          unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
          await _slip(v.mistake!);
          return;
        case M7Result.deadly:
          setState(() => _judging = false);
          await _deadly(v.mistake!);
          return;
      }
    }
    if (!mounted || _ended) return;
    setState(() => _judging = false);
    if (_run.roundDone) _roundDone();
  }

  void _roundDone() {
    if (_roundBusy) return;
    final why = _run.whyKind();
    final right = M7PapersLines.whyRight[why]!;
    setState(() {
      _roundBusy = true;
      _why = why;
    });
    putOnTable(_run.roundSlips == 0 ? 20 : 15);
    unawaited(askReason(
      deal: () => dealChoices(right, M7PapersLines.myths, widget.rng),
      question: M7PapersLines.whyQ[why]!,
      stillValid: () => !_ended && _why == why,
    ));
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
    final round = _run.roundIdx;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (!mounted || _ended || _run.roundIdx != round) return;
      if (_run.lastRound) {
        unawaited(_finish());
        return;
      }
      _run.nextRound();
      setState(() {
        _why = null;
        _roundBusy = false;
        _walletFor = null;
        _lastOpened = null;
        _wake++;
      });
      _startRoundVoice();
      unawaited(_sayChain([_task]));
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7PapersLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;

  /// He comes only when a decisive control calls him (his target's wallet, the
  /// live-line card, the shift button): "not yet" until then; null when this
  /// round has no live-line card or the play is over.
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended || !_r.hasLive || _run.isLocked(_r.liveJob)) return null;
    return false;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened: his man goes on the live-line card and the shift starts.
      final m = _run.listened();
      setState(() {
        _walletFor = null;
        _wake++;
      });
      await _deadly(m);
      return;
    }
    _run.refused();
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    // Speak only while play is on (no stale task over a card or a deck).
    if (!mounted || _ended || reasonOpen || tableBusy || _card != null) return;
    unawaited(_sayChain([M7PapersLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7PapersLines.tapWhy[_nudgeN++ % M7PapersLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('m7papers/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A man without the live-line certificate on the live-line card: the yard
  /// freezes grey and the flash comes off it in colour; then near-miss or
  /// death.
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
      _walletFor = null;
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
    final speak = await SpokenOnce.first('m7papers/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M7PapersLines.deadlyWord : M7PapersLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The card went back to the board; the same round goes on.
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
    await _say(!_run.passed ? M7PapersLines.fail : (_quickBonus ? M7PapersLines.quick : M7PapersLines.allSet),
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
  /// The yard, nothing placed and no wallet seen: a sweep over every gang
  /// figure. A wallet open: a swipe right to left on its sleeve. A wallet seen
  /// and closed, nothing placed: a short nudge straight up from the last
  /// worker opened. Some placed, not all: a sweep over the job cards and the
  /// tray together. Every card filled or held: a tap on 'শিফট শুরু'.
  HintSpec? _hint() {
    if (_walletFor != null) {
      final r = HintSpec.globalRectOf(_sleeveKey);
      if (r == null) return null;
      return HintSpec.swipe(Offset(r.center.dx + math.min(60, r.width * 0.25), r.center.dy), toward: const Offset(-1, 0), travel: math.min(110, r.width * 0.45));
    }
    if (_run.ready) return HintSpec.tapOn(_shiftKey);
    if (_run.placedCount == 0) {
      final gang = [for (final i in _run.free) if (!_run.personLocked(i)) _tileKeys[i]];
      if (!_anySeen) return HintSpec.sweepOver(gang);
      final last = _lastOpened;
      if (last != null && _run.jobOf(last) == null) return HintSpec.dragFrom(_tileKeys[last], toward: const Offset(0, -1), travel: 80);
      return HintSpec.sweepOver(gang);
    }
    return HintSpec.sweepOver([
      for (var j = 0; j < _r.jobs.length; j++)
        if (!_run.isLocked(j) && !_run.isHeld(j)) _jobKeys[j],
      _trayKey,
    ]);
  }

  // --- the scene ---------------------------------------------------------------
  List<Widget> _scene(SceneMetrics m) {
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: const RepaintBoundary(child: CustomPaint(painter: M7YardPainter())),
        ),
      ),
    ];
  }

  Widget _board(Rect r, bool quiet, bool handsOn) {
    final jobs = _r.jobs;
    return Positioned.fromRect(
      key: const ValueKey('board'),
      rect: r,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF9A6A3A), Color(0xFF6E4622)]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4B3014), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < jobs.length; j++)
                    Expanded(
                      key: ValueKey('slot-${_run.roundIdx}-$j'),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: _jobSlot(j, quiet, handsOn)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(width: 86, child: _tray(quiet)),
          ],
        ),
      ),
    );
  }

  Widget _jobSlot(int j, bool quiet, bool handsOn) {
    final job = _r.jobs[j];
    if (_run.isHeld(j)) {
      // The card is in the tray: a ghost keeps its place on the board.
      return Container(
        key: ValueKey('ghost-$j'),
        decoration: BoxDecoration(
          color: const Color(0x22000000),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
        ),
      );
    }
    final p = _run.personOn(j);
    final locked = _run.isLocked(j);
    final isLive = job == M7Job.live;
    final held = isLive && coworkerDue;
    final canDrag = handsOn && !locked && !held;
    final card = _JobCard(
      key: ValueKey('job-$j'),
      text: M7PapersLines.jobText[job]!,
      person: p == null ? null : _r.people[p],
      locked: locked,
      stamp: locked ? _stampTok : 0,
      quiet: quiet,
    );
    return DragTarget<_PersonDrag>(
      onWillAcceptWithDetails: (d) => handsOn && _run.canPlace(d.data.index, j),
      onAcceptWithDetails: (d) => _dropPerson(d.data.index, j),
      builder: (context, cand, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tapJob(j),
        onPanStart: canDrag ? null : (d) => _jobHeld(j, d.globalPosition),
        child: Draggable<_JobDrag>(
          data: _JobDrag(j),
          maxSimultaneousDrags: canDrag ? 1 : 0,
          onDragStarted: () => _tick('sounds/learn/card_deal_a.ogg', 0.4),
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: 92, height: 110, child: Transform.rotate(angle: -0.05, child: card)),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: KeyedSubtree(
            key: _jobKeys[j],
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: cand.isNotEmpty ? Border.all(color: SlmColors.gold300, width: 3) : null,
              ),
              child: card,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tray(bool quiet) {
    final heldJobs = [for (var j = 0; j < _r.jobs.length; j++) if (_run.isHeld(j)) j];
    return DragTarget<_JobDrag>(
      onWillAcceptWithDetails: (d) => _canPlay && !_run.isLocked(d.data.index),
      onAcceptWithDetails: (d) => _dropJob(d.data.index),
      builder: (context, cand, _) => KeyedSubtree(
        key: _trayKey,
        child: Semantics(
          label: M7PapersLines.tray,
          container: true,
          child: Container(
            key: const ValueKey('tray'),
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: cand.isNotEmpty ? const [Color(0xFFD9A867), Color(0xFFB27A3E)] : const [Color(0xFFB98549), Color(0xFF8E5F2E)],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cand.isNotEmpty ? SlmColors.gold300 : const Color(0xFF5E3D1C), width: cand.isNotEmpty ? 2.4 : 1.4),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF4E3B5), borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0xFFC9A44E), width: 1.5)),
                  child: Text(M7PapersLines.tray,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(fontSize: 9.5, fontWeight: FontWeight.w900, height: 1.15, color: const Color(0xFF2B2111))),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final (k, j) in heldJobs.indexed)
                        Positioned(
                          key: ValueKey('held-$j'),
                          left: 2.0 + k * 3,
                          right: 2.0 - k * 3 < 0 ? 0 : 2.0 - k * 3,
                          top: 2.0 + k * 6,
                          height: 40,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _tapJob(j),
                            child: _HeldCard(text: M7PapersLines.jobText[_r.jobs[j]]!, stamped: _run.isLocked(j), stamp: _run.isLocked(j) ? _stampTok : 0, quiet: quiet),
                          ),
                        ),
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

  Widget _wallet(Rect r, bool quiet) {
    final i = _walletFor;
    if (i == null) return const SizedBox.shrink(key: ValueKey('wallet-none'));
    final p = _r.people[i];
    final sleeve = p.sleeves[_sleeveAt];
    final seen = _seenOf(i);
    return Positioned.fromRect(
      key: ValueKey('wallet-$i'),
      rect: r,
      child: Container(
        key: const ValueKey('wallet'),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A6642), Color(0xFF5E4326)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3C2A16), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 5))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: 26, height: 40, child: CustomPaint(painter: M7WorkerPainter(m7Looks[p.look], clipboard: p.isPlayer))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(M7PapersLines.walletOf(p.name),
                      key: const ValueKey('wallet-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFFFFF4D6))),
                ),
                Semantics(
                  label: M7PapersLines.walletClose,
                  button: true,
                  child: GestureDetector(
                    key: const ValueKey('wallet-close'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeWallet,
                    child: const SizedBox(width: 48, height: 40, child: Icon(Icons.close_rounded, color: Color(0xFFFFF4D6), size: 26)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: KeyedSubtree(
                key: _sleeveKey,
                child: GestureDetector(
                  key: const ValueKey('wallet-sleeve'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) => _swipe = 0,
                  onHorizontalDragUpdate: (d) => _swipe += d.delta.dx,
                  onHorizontalDragEnd: (_) {
                    final dx = _swipe;
                    _swipe = 0;
                    if (dx < -28) {
                      _gotoSleeve(_sleeveAt + 1);
                    } else if (dx > 28) {
                      _gotoSleeve(_sleeveAt - 1);
                    } else {
                      _hints.missTap();
                    }
                  },
                  onTap: () => _hints.missTap(),
                  child: AnimatedSwitcher(
                    duration: quiet ? Duration.zero : const Duration(milliseconds: 240),
                    child: _SleeveCard(key: ValueKey('sleeve-$i-$_sleeveAt'), person: p, sleeve: sleeve, seen: seen.contains(_sleeveAt)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < 5; k++)
                  GestureDetector(
                    key: ValueKey('sleeve-dot-$k'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _gotoSleeve(k),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: k == _sleeveAt ? SlmColors.gold300 : (seen.contains(k) ? const Color(0xFFC9A44E) : const Color(0x55FFF4D6)),
                          border: Border.all(color: const Color(0xFF3C2A16), width: 1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gang(Rect r, bool handsOn) {
    final people = _r.people;
    Widget slot(int i) {
      final p = people[i];
      if (_run.jobOf(i) != null || _run.personLocked(i)) return Expanded(key: ValueKey('gap-${_run.roundIdx}-$i'), child: const SizedBox());
      final canDrag = handsOn;
      final tile = _Tile(person: p, opened: _seenOf(i).isNotEmpty, active: _walletFor == i);
      return Expanded(
        key: ValueKey('slot-${_run.roundIdx}-$i'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapPerson(i),
            // A worker who does not move now: going on working while he talks
            // refuses the coworker.
            onPanStart: canDrag
                ? null
                : (d) {
                    if (_coworkerTalking && !_intro && !_ended && _card == null) unawaited(answerCoworker(true, d.globalPosition, direct: true));
                  },
            child: Draggable<_PersonDrag>(
              key: ValueKey('person-${_run.roundIdx}-$i'),
              data: _PersonDrag(i),
              maxSimultaneousDrags: canDrag ? 1 : 0,
              onDragStarted: () => _tick('sounds/learn/card_deal_a.ogg', 0.4),
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(width: 64, height: 100, child: Transform.rotate(angle: -0.04, child: CustomPaint(painter: M7WorkerPainter(m7Looks[p.look], clipboard: p.isPlayer)))),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: tile),
              child: KeyedSubtree(key: _tileKeys[i], child: tile),
            ),
          ),
        ),
      );
    }

    return Positioned.fromRect(
      key: const ValueKey('gang'),
      rect: r,
      child: Container(
        padding: EdgeInsets.fromLTRB(6, 8, 6, 6 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55000000), Color(0x99000000)]),
          border: Border(top: BorderSide(color: Color(0xFFC89A5E), width: 3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var i = 0; i < people.length; i++) slot(i)]),
      ),
    );
  }

  Widget _shiftButton(Rect r, bool show) {
    if (!show) return const SizedBox.shrink(key: ValueKey('shift-none'));
    return Positioned.fromRect(
      key: const ValueKey('shift-pos'),
      rect: r,
      child: KeyedSubtree(
        key: _shiftKey,
        child: Semantics(
          label: M7PapersLines.shift,
          button: true,
          child: GestureDetector(
            key: const ValueKey('shift-start'),
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(_startShift()),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFD66B), Color(0xFFE5A21C)]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF8A5A00), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: Text(M7PapersLines.shift, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF2B1B00))),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final lay = _Layout.of(size, pad);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.ended && !deckUp && !coworkerOpen && _card == null && !_judging && !_roundBusy && !_freeze;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
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
              labels: [for (var i = 0; i < _run.roundCount; i++) M7PapersLines.progress(i)],
              done: {for (var i = 0; i < _run.roundIdx; i++) i, if (_run.roundDone && !_roundBusy) _run.roundIdx},
              current: _run.roundIdx,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy,
            hintKey: '${_run.roundIdx}/$_walletFor/${_run.placedCount}/${_run.ready}/$_anySeen',
            hintController: _hints,
            overlays: [
              Positioned.fill(
                key: const ValueKey('play'),
                child: ColorFiltered(
                  colorFilter: grey,
                  child: Stack(
                    children: [
                      // Taps on the bare yard (never over the header's close / mute).
                      Positioned(
                        key: const ValueKey('yard-touch'),
                        left: 0,
                        right: 0,
                        bottom: 0,
                        top: pad.top + FullSceneFrame.headerBand,
                        child: Semantics(
                          label: M7PapersLines.yardLabel,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (_canPlay) _hints.missTap();
                            },
                          ),
                        ),
                      ),
                      _board(lay.board, quiet, handsOn),
                      _wallet(lay.wallet, quiet),
                      _gang(lay.gang, handsOn),
                      _shiftButton(lay.shift, playing && _run.ready && !_judging && !_roundBusy && !_run.ended && _card == null),
                    ],
                  ),
                ),
              ),
              ...tableLayers(at: Offset(size.width / 2, lay.board.center.dy), quiet: quiet),
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: ValueKey('why-deck-${_run.roundIdx}-${_why?.name}'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null && !_freeze)
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : size.height - lay.gang.top + 2, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  line: M7PapersLines.intro,
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

/// A worker in the yard: his figure and his name strip. [opened]: his wallet
/// was opened (a dog-ear, the same for everyone); [active]: his wallet is up.
class _Tile extends StatelessWidget {
  const _Tile({required this.person, required this.opened, required this.active});
  final M7Person person;
  final bool opened;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final look = m7Looks[person.look];
    return Semantics(
      label: person.name,
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: active ? const Color(0x33FFD66B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: SlmColors.gold300, width: 2) : null,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: CustomPaint(size: Size.infinite, painter: M7WorkerPainter(look, clipboard: person.isPlayer)))),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFFFBF0), borderRadius: BorderRadius.circular(5), border: Border.all(color: look.shirt, width: 2)),
                  child: Text(person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: bangla(fontSize: 12, fontWeight: FontWeight.w900, height: 1.1, color: const Color(0xFF2B2111))),
                ),
              ],
            ),
            if (opened)
              Positioned(
                key: const ValueKey('dogear'),
                top: 2,
                right: 4,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(color: Color(0xFFFFE08A), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), topRight: Radius.circular(3))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A job card on the notice board: its text, the worker standing on it (a
/// small figure and his name), and — once judged right — a green stamp.
class _JobCard extends StatelessWidget {
  const _JobCard({super.key, required this.text, required this.person, required this.locked, required this.stamp, required this.quiet});
  final String text;
  final M7Person? person;
  final bool locked;
  final int stamp;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final p = person;
    final body = Container(
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFE3F3DC) : const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: locked ? const Color(0xFF3F9B4F) : const Color(0xFFC9A44E), width: locked ? 2.4 : 1.6),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFB91C1C), shape: BoxShape.circle)),
          const SizedBox(height: 2),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 86,
                  child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, height: 1.2, color: const Color(0xFF2B2111))),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: p == null
                ? Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: const Color(0xFFC9A44E), width: 1.2)),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 34, child: CustomPaint(painter: M7WorkerPainter(m7Looks[p.look], clipboard: p.isPlayer))),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2111))),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
    return Semantics(
      label: text,
      container: true,
      child: stamp == 0
          ? body
          : TweenAnimationBuilder<double>(
              key: ValueKey('stamp-$stamp'),
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              builder: (_, v, child) => Transform.scale(scale: 1 + 0.08 * math.sin(v * math.pi), child: child),
              child: Stack(children: [
                Positioned.fill(child: body),
                const Positioned(right: 3, top: 3, child: Icon(Icons.check_circle_rounded, color: Color(0xFF2F8F3F), size: 20)),
              ]),
            ),
    );
  }
}

/// A job card in the tray (small): its text; [stamped] once the hold was
/// judged right.
class _HeldCard extends StatelessWidget {
  const _HeldCard({required this.text, required this.stamped, required this.stamp, required this.quiet});
  final String text;
  final bool stamped;
  final int stamp;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: stamped ? const Color(0xFFE3F3DC) : const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: stamped ? const Color(0xFF3F9B4F) : const Color(0xFFC9A44E), width: stamped ? 2 : 1.2),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w800, height: 1.1, color: const Color(0xFF2B2111))),
          ),
          if (stamped) const Icon(Icons.check_circle_rounded, color: Color(0xFF2F8F3F), size: 14),
        ],
      ),
    );
  }
}

/// One sleeve of a wallet: a paper in a clear pocket (or an empty pocket).
/// [seen]: the dog-ear.
class _SleeveCard extends StatelessWidget {
  const _SleeveCard({super.key, required this.person, required this.sleeve, required this.seen});
  final M7Person person;
  final M7Sleeve sleeve;
  final bool seen;

  List<String>? get _lines {
    final p = person;
    switch (sleeve) {
      case M7Sleeve.id:
        return [p.name, p.onRegister ? M7PapersLines.registerYes : M7PapersLines.registerNo];
      case M7Sleeve.iti:
        return p.hasIti ? [M7PapersLines.itiTrade] : null;
      case M7Sleeve.permit:
        return p.hasPermit ? [M7PapersLines.permitBoard, M7PapersLines.permitNo(p.permitNo)] : null;
      case M7Sleeve.training:
        if (p.trainingOngoing) return [M7PapersLines.trainingOngoing];
        if (p.certs.isEmpty) return null;
        return [for (final c in M7Cert.values) if (p.certs.contains(c)) M7PapersLines.certName[c]!];
      case M7Sleeve.logbook:
        return p.logMonths <= 0 ? null : [M7PapersLines.logbookText(p.logMonths)];
    }
  }

  IconData get _icon => switch (sleeve) {
        M7Sleeve.id => Icons.badge_rounded,
        M7Sleeve.iti => Icons.school_rounded,
        M7Sleeve.permit => Icons.verified_rounded,
        M7Sleeve.training => Icons.workspace_premium_rounded,
        M7Sleeve.logbook => Icons.menu_book_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    const ink = Color(0xFF2B2111);
    return Container(
      key: const ValueKey('sleeve'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: lines == null ? const Color(0xFFE6DDC4) : const Color(0xFFFFFDF6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB9AD8A), width: 2),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Icon(_icon, size: 34, color: lines == null ? const Color(0xFFB9AD8A) : const Color(0xFF8A5A00)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(M7PapersLines.sleeveTitle[sleeve]!,
                        key: const ValueKey('sleeve-title'),
                        style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: ink)),
                    const SizedBox(height: 4),
                    if (lines == null)
                      Text(M7PapersLines.empty, key: const ValueKey('sleeve-empty'), style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF8C8467)))
                    else
                      for (final l in lines) Text(l, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.25, color: ink)),
                  ],
                ),
              ),
            ],
          ),
          if (seen)
            Positioned(
              key: const ValueKey('sleeve-dogear'),
              top: -8,
              right: -10,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Color(0xFFFFE08A), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14))),
              ),
            ),
        ],
      ),
    );
  }
}
