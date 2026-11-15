import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import 'm6_fuse_chain_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_fuse_chain_world.dart' show M6Content, M6ChainGeo;

// Lesson 6.3 "ফিউজ: নীরব প্রহরী ও তারের সঠিক হিসাব", কাজ 2 "কোন প্রহরী
// পড়ল?" (pack do_6_3_b, rung 6.3/do/1, engineType m6_fuse_chain). Three
// calls a play from a village lane fed by one WBSEDCL pole transformer: each
// call names a house where a short was repaired and the light has not come
// back. The guards stand in a chain — the house's kit-kat, the LT box's HRC,
// the transformer's HG fuse — and a healthy chain falls from the bottom up
// (6.3 pro tip 2: "বাড়ির ফিউজ বা MCB সবার আগে উড়বে, তারপর এলটি বক্সের
// ফিউজ, এবং সবশেষে ট্রান্সফরমারের এইচজি ফিউজ").
//
// The core verb (judge, module 6 table): read the guards up the chain with
// the eyes (the HG wires; the LT box door → the HRC indicator dots, pro tip
// 1; the house kit-kat cannot be read without drawing it), then chalk ✗ on
// the docket on every guard that should have fallen first but did not — or
// tick 'ক্রম ঠিক' — and 'দেখতে যাই'. Then the work: every chalked guard and
// the fallen one opened, its contents shown (a melted tinned wire, or a
// jugaad: GI, an aluminium strand, a thick copper wire; behind an HRC a
// copper strip, pro tip 3), the jugaad to the scrap pile, the right spare in
// (meter-board kit-kat 16 A = the 0.50 mm reel, IS 9926 table, ruling X6; the
// HRC base a new HRC with the puller; the HG wire by the nameplate kVA, 6.3
// point 1), and the supply back on only once every suspect is fixed (6.3
// point 6 "কখনই বারবার ফিউজ চার্জ করবেন না").
//
// Safety (rulings X4, M6-2, X3, X1, A5, B1; module 6 table R14–R16, R32, R33,
// N1–N4, N9):
//  • the meter-board kit-kat: that board's main switch OFF (swipe down), then
//    the carrier by the gloved hand; drawn with the switch ON = deadly (R14);
//    without gloves and goggles = deadly (R15; no proven isolation there);
//  • an HRC: the DTR's LT switch OFF → lock + tag → the tester proved on a
//    live point, 0 V on the HRC, proved again → the insulated puller; with
//    the LT ON = deadly (R14/X4); no lock-tag / no 0 V / no re-proof = slip
//    (N4); a 0 V on an unproved tester = slip (N9); no PPE after the proven
//    isolation = slip (A5); pliers or a bare hand = slip (R16, M6-5); a way
//    that needs no work = slip (R32); fuse wire in the HRC base instead of a
//    new HRC = slip (pro tip 3; owner may raise). The tester is proved per
//    voltage: the LT box's supply bar for an HRC, the AB's 11 kV line side
//    for the HG (X1, A9);
//  • the HG (when it fell): the LT OFF, then the AB opened in one firm
//    stroke (a stall = slip, M6-3; on load = deadly, X3/N2), the three blades
//    looked at, the tester live-dead-live on the HG, the earth on (earth on
//    live = deadly; before the 0 V or the re-proof = slip), the new wire of
//    the kVA rating (with the AB closed = deadly N1; before the 0 V = deadly;
//    without the earth = deadly N3; a wrong rating = slip R13), the earth off,
//    the AB closed (on load = deadly; with the earth still on = deadly, as
//    m5_gate_case's charge onto an earth), the LT ON. No mat, no rod, no DO
//    (M6-2). The AB may close while a suspect is left: the LT is OFF then, so
//    nothing reaches it; R33 is scored at the LT switch.
//  • the DTR's LT switched OFF on a call that needs no LT, or the AB opened
//    on a call that needs no HG = slip (R32, needless outage); the switch
//    does not move.
//  • 'ক্রম ঠিক' on a broken chain, or a chalk missed = slip; a needless chalk
//    = slip (R32); the LT on before every suspect is fixed = slip (R33); a
//    wrong reel in the kit-kat = slip (X6).
//  • the LT box door (open to read the dots; a tap on its dropped leaf shuts
//    it): the LT switched back ON with it open, or the light back with it
//    still open = slip (X4, M5 N5; m3_pillar_fuse's door pattern).
// The careless coworker once a play, on one call, as the player first
// touches any guard after the verdict: "মেইন সুইচ নামানোর ঝামেলা কেন? এক
// টানে খুলে নাও!" — listening is drawing that fuse on load = deadly (B1).
// Every guard control and the belt wait for him (holdForCoworker).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_fuse_chain_world.dart), corner guide, ◆ on the table → "কেন
// …?" once a call (at the verdict or when the light is back, by topic), the
// gesture hand (how, never what), mistake cards, the deadly freeze, three
// slips strike out. All new Bangla text here is a DRAFT for the owner's
// wording (ruling M6-12).

// ============================================================================
// Content
// ============================================================================

/// The guards of the chain, from the bottom up.
enum M6Tier { house, lt, hg }

/// The tool belt (shuffled each call).
enum M6Tool { tester, puller, pliers, lockTag, earth }

/// The spares and the scrap pile (the tray when a guard is open).
enum M6Spare { scrap, mm050, mm085, mm150, mm200, hrc, hg3, hg5, hg10 }

/// What a call's reason asks about.
enum M6Why { chalk, chainOk, dot, switchOff, puller, jugaad, hgIsolate }

/// The coworker's push (two wordings, one dealt).
enum M6Push { noBother, glovesOn }

/// Where a call stands.
enum M6Stage { read, work, done }

/// What the tester can touch: the two live proving points; the LT box's HRC
/// side; the HG.
enum M6Target { lt, hg }

enum M6Point { abLine, ltSupply }

/// The tray up now.
enum M6Tray { none, kitkat, hrc, hg }

/// The HG spare that fits a nameplate (6.3 point 1: 25 kVA 2–3 A, 63 kVA 5 A,
/// 100 kVA 8–10 A).
M6Spare m6HgSpareFor(int kva) => switch (kva) {
      25 => M6Spare.hg3,
      63 => M6Spare.hg5,
      _ => M6Spare.hg10,
    };

/// The reason topics that fit a call (the verdict topics first).
List<M6Why> m6WhysFor(M6Tier fallen) => switch (fallen) {
      // No jugaad topic on a house fall: its kit-kat held a right wire that
      // melted, so 'ভুল তার ফল্টে গলে না' would not fit the play.
      M6Tier.house => const [M6Why.chainOk, M6Why.switchOff],
      M6Tier.lt => const [M6Why.chalk, M6Why.dot, M6Why.switchOff, M6Why.puller, M6Why.jugaad],
      M6Tier.hg => const [M6Why.chalk, M6Why.switchOff, M6Why.puller, M6Why.jugaad, M6Why.hgIsolate],
    };

/// The topics asked at the verdict (the rest when the light is back).
bool m6WhyAtVerdict(M6Why w) => w == M6Why.chalk || w == M6Why.chainOk || w == M6Why.dot;

abstract final class M6ChainLines {
  static const title = 'কোন প্রহরী পড়ল?';
  // DRAFT wording — owner (spec flow[0]).
  static const intro = 'একটা বাড়িতে শর্ট হয়েছিল, মিস্ত্রি সারিয়েছেন — কোন প্রহরী পড়েছে পড়ে দেখুন, তারপর লাইন চালু।';

  // The calls (one per house; English digits on screen). DRAFT wording.
  static String call(int house) => '${enDigits('$house')} নম্বর বাড়িতে শর্ট সারানো হয়েছে, আলো নেই।';
  static List<String> get allCalls => [for (var n = 1; n <= 6; n++) call(n)];

  // The guide's task now (tap him: the same task, a different way). DRAFT.
  static const askRead = 'কোন প্রহরী পড়েছে? চোখে দেখে নিন।';
  static const askVerdict = 'ডকেটে দাগ দিন, নয়তো ক্রম ঠিক — তারপর দেখতে যাই।';
  static const askWork = 'এবার প্রহরী সারিয়ে আলো ফেরান।';
  static const tasks = [askRead, askVerdict, askWork];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Nudges (no cost). DRAFT.
  static const readFirst = 'আগে চোখে দেখে নিন — HG আর LT বক্সের ভেতর।';
  static const markFirst = 'দাগ দিন, নয়তো ক্রম ঠিক বেছে নিন।';
  static const workLater = 'আগে দেখে ডকেটে রায় দিন, তারপর হাত।';
  static const scrapFirst = 'আগে পুরনো জিনিসটা ভাঙারিতে ফেলুন।';
  // Lesson 6.3 point 6's own words.
  static const bladesFirst = 'আগে দেখুন AB সুইচের তিনটি ব্লেডই খুলেছে কি না।';
  static const lockedLever = 'তালা-ট্যাগ লাগানো আছে — আগে সেটা খুলুন।';
  static const slotEmpty = 'ফিউজের জায়গা খালি — আগে নতুন ফিউজ বসান।';
  static const verdictRight = 'ঠিক ধরেছেন!';
  static const lightBack = 'আলো ফিরল!';
  static const callHeld = 'ঠিক! আগে মেইন সুইচ বন্ধ, তবেই ফিউজে হাত।';

  // On the scene: labels a worker reads.
  static const docket = 'ডকেট';
  static String docketHouse(int house) => '${enDigits('$house')} নম্বর বাড়ি';
  static const chainOk = 'ক্রম ঠিক';
  static const goLook = 'দেখতে যাই';
  static const chalk = 'চক';
  static const sceneLabel = 'গ্রামের গলি, ট্রান্সফরমার ও বাড়ি';
  static String tier(M6Tier t) => switch (t) {
        M6Tier.house => 'বাড়ি',
        M6Tier.lt => 'LT বক্স',
        M6Tier.hg => 'HG',
      };
  static String tool(M6Tool t) => switch (t) {
        M6Tool.tester => 'টেস্টার',
        M6Tool.puller => 'ফিউজ পুলার',
        M6Tool.pliers => 'প্লায়ার্স',
        M6Tool.lockTag => 'তালা-ট্যাগ',
        M6Tool.earth => 'আর্থ',
      };
  static String spare(M6Spare s) => switch (s) {
        M6Spare.scrap => 'ভাঙারি',
        M6Spare.mm050 => '0.50 mm',
        M6Spare.mm085 => '0.85 mm',
        M6Spare.mm150 => '1.50 mm',
        M6Spare.mm200 => '2.00 mm',
        M6Spare.hrc => 'নতুন HRC',
        M6Spare.hg3 => '3A',
        M6Spare.hg5 => '5A',
        M6Spare.hg10 => '10A',
      };
  static const testerDead = '0 V';
  static const testerLive = 'লাইভ';

  // The reasons (DRAFT). The right ones fit what was done; the wrong ones are
  // the lesson's myths and field excuses. All within 1.3× of each other.
  static const whyQ = <M6Why, String>{
    M6Why.chalk: 'কেন এই প্রহরীগুলোতে দাগ দিলেন?',
    M6Why.chainOk: "কেন 'ক্রম ঠিক' বললেন?",
    M6Why.dot: 'HRC ফিউজ উড়েছে কি না কীভাবে বুঝলেন?',
    M6Why.switchOff: 'কেন আগে মেইন সুইচ বন্ধ করলেন?',
    M6Why.puller: 'কেন ফিউজ পুলার নিলেন?',
    M6Why.jugaad: 'কেন পুরনো তারটা খুলে ফেলে দিলেন?',
    M6Why.hgIsolate: 'কেন AB খুলে, টেস্টারে দেখে, আর্থ দিলেন?',
  };
  static const whyRight = <M6Why, List<String>>{
    M6Why.chalk: ['নিচের প্রহরী আগে পড়ার কথা, পড়েনি — তাই দাগ', 'যে আগে পড়ার কথা অথচ পড়েনি, তার তারই ভুল'],
    M6Why.chainOk: ['বাড়ির ফিউজই আগে পড়েছে — ক্রম একদম ঠিক', 'ওপরের প্রহরীরা ঠিক আছে, পড়েছে শুধু বাড়িরটা'],
    M6Why.dot: ['HRC-র গায়ের লাল ডট উধাও বা কালো হয়ে গেছে', 'ইন্ডিকেটর ডট নেই — মানে ফিউজটা কেটে গেছে'],
    M6Why.switchOff: ['চালু সাপ্লাইয়ে ফিউজ টানলে মারাত্মক আর্ক ফ্ল্যাশ', 'সুইচ বন্ধ না করে টানলে আর্ক ফ্ল্যাশে পুড়ব'],
    M6Why.puller: ['HRC খুলতে-লাগাতে সবসময় ইনসুলেটেড পুলার', 'প্লায়ার্স বা খালি হাতে HRC টানা চলবে না'],
    M6Why.jugaad: ['জুগাড় বা পোড়া তার নয় — নতুন সঠিক তার চাই', 'ভুল তার ফল্টে গলে না, ট্রান্সফরমার পুড়ে যায়'],
    M6Why.hgIsolate: ['AB খুলে তিন ব্লেড দেখা, টেস্টারে ডেড, তবে আর্থ', 'HG-র তার বদলের আগে ডেড প্রমাণ আর আর্থিং চাই'],
  };
  static const myths = [
    'মোটা তার বাঁধলে ফিউজ মজবুত, বারবার ওড়ে না',
    'হাতের কাছে জিআই তার থাকলে সাময়িক চলে যায়',
    'গ্লাভস পরা থাকলে চালু ফিউজও টানা যায়',
    'যে ফিউজ পড়েছে, শুধু সেটা বদলালেই হলো',
    'বারবার ফিউজ চার্জ করলে ফল্ট নিজেই সরে যায়',
    'প্লায়ার্স দিয়েও HRC দিব্যি টেনে খোলা যায়',
    'ডট দেখে কিছু বোঝা যায় না, আন্দাজই ভরসা',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (DRAFT wording — owner; spec coworkerPushBn).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerNoBother = CoworkerScript(
    line: 'মেইন সুইচ নামানোর ঝামেলা কেন? এক টানে খুলে নাও!',
    exitLine: coworkerExit,
    right: ['না, আগে মেইন সুইচ বন্ধ করব', 'না, চালু অবস্থায় ফিউজ টানব না', 'না, আগে সাপ্লাই বন্ধ, তবে ফিউজ'],
    wrong: [
      'ঠিক, এক টানেই ফিউজটা খুলে নিই',
      'আচ্ছা, সুইচ নামানো লাগবে না',
      'হ্যাঁ, চালু রেখেই টেনে নিই',
      'ঠিক আছে, ঝামেলা না করে খুলি',
      'হ্যাঁ, এক সেকেন্ডের তো কাজ',
    ],
    asks: ['কী করবেন?', 'ও বলছে চালু রেখেই টানতে। কী করবেন?', 'মেইন সুইচ না নামিয়ে টানবেন?'],
  );
  static const coworkerGlovesOn = CoworkerScript(
    line: 'লোড থাকলে কী, হাতে গ্লাভস তো আছে — চটপট টেনে নাও!',
    exitLine: coworkerExit,
    right: ['না, গ্লাভস থাকলেও আগে সুইচ বন্ধ', 'না, লোডে টানলে আর্ক ফ্ল্যাশ হবে', 'না, সুইচ বন্ধ না করে টানব না'],
    wrong: [
      'ঠিক, গ্লাভস তো আছেই, টানি',
      'আচ্ছা, লোডে টানলে কিছু হবে না',
      'হ্যাঁ, চটপট টেনে নিই তাহলে',
      'ঠিক আছে, গ্লাভসই যথেষ্ট রক্ষা',
      'হ্যাঁ, সুইচ নামানো বাড়তি কাজ',
    ],
    asks: ['কী করবেন?', 'ও বলছে লোডেই টেনে নিতে। কী করবেন?', 'চালু ফিউজ টানবেন?'],
  );
  static CoworkerScript coworker(M6Push p) => switch (p) {
        M6Push.noBother => coworkerNoBother,
        M6Push.glovesOn => coworkerGlovesOn,
      };
  static const allCoworkers = [coworkerNoBother, coworkerGlovesOn];

  /// The push he makes as he comes: 'হাতে গ্লাভস তো আছে' only when the
  /// gloves are on by then; otherwise the other wording.
  static M6Push pushNow(M6Push dealt, {required bool gloves}) =>
      dealt == M6Push.glovesOn && !gloves ? M6Push.noBother : dealt;

  static const allSet = 'তিনটে কলেই ঠিক প্রহরী ধরেছেন — জুগাড় সরিয়ে, নিয়ম মেনে আলো ফিরিয়েছেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে দেখে ক্রম মেলান, তারপর সুইচ বন্ধ করে কাজ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন" (on screen only).
  static const caughtChain = 'প্রহরীর ক্রম মিলিয়ে দোষী ধরেছেন';
  static const caughtIsolate = 'সুইচ বন্ধ, তালা-ট্যাগ, 0 V — তবে HRC';
  static const caughtPuller = 'HRC খুলেছেন ইনসুলেটেড পুলারে';
  static const caughtReel = 'মিটার বোর্ডে 0.50 mm তার';
  static const caughtJugaad = 'জুগাড়ের তার ভাঙারিতে';
  static const caughtHg = 'AB খুলে, 0 V, আর্থ — তবে HG-র তার';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (DRAFT — owner wording, then recorded with
  /// tool/rival_clip.py; until then silent, caption held).
  static List<String> get newRivalLines => [for (final s in allCoworkers) s.line];

  /// Every new spoken guide line (DRAFT — owner wording, then recorded).
  static List<String> get newGuideLines => <String>{
        intro,
        ...allCalls,
        ...tasks,
        ...tapWhy,
        readFirst,
        markFirst,
        workLater,
        scrapFirst,
        bladesFirst,
        lockedLever,
        slotEmpty,
        verdictRight,
        lightBack,
        callHeld,
        ...whyQ.values,
        for (final s in allCoworkers) ...s.asks,
        allSet,
        fail,
        for (final m in M6ChainMistakes.all) m.textBn,
      }.toList();
}

abstract final class M6ChainMistakes {
  static const _dir = 'assets/game/art/m6_fuse_chain';

  // --- deadly ------------------------------------------------------------------
  /// A fuse drawn with its supply on: the meter-board kit-kat with the board's
  /// main switch ON, or an HRC with the DTR's LT switch ON (R14, X4); also
  /// listening to the coworker (B1). DRAFT wording.
  static const liveDraw = DoMistake(
    key: '6.3/m6_fuse_chain/live-draw',
    textBn: 'চালু সাপ্লাইয়ে ফিউজ টানলে মারাত্মক আর্ক ফ্ল্যাশ হবে! আগে মেইন সুইচ বন্ধ করুন — তবেই ফিউজে হাত দেবেন।',
    art: '$_dir/live_draw.svg',
    deadly: true,
    lessonPoint: 5,
  );
  /// The meter-board kit-kat drawn without gloves and goggles (R15; no proven
  /// isolation at a meter board; as M3 3.7a).
  static const noPpe = DoMistake(
    key: '6.3/m6_fuse_chain/no-ppe',
    textBn: 'ফিউজে হাত দেওয়ার আগে ইনসুলেটেড হ্যান্ড গ্লাভস আর সেফটি গগলস পরুন — আর্ক ফ্ল্যাশে হাত আর চোখ বাঁচে।',
    art: '$_dir/no_ppe.svg',
    deadly: true,
    lessonPoint: 5,
  );
  /// The HG wire touched with the AB closed (N1); after the AB is open but
  /// before the tester's 0 V (N3); after the 0 V without the earth (N3).
  /// The second sentence is lesson 6.3 point 6 word for word.
  static const hgLive = DoMistake(
    key: '6.3/m6_fuse_chain/hg-live',
    textBn: 'AB না খুলেই HG-র তারে হাত — চালু 11 kV! হর্ন গ্যাপ ফিউজের তার বদলানোর আগে AB সুইচ খুলে তিনটি ব্লেডই খুলেছে কি না দেখুন, টেস্টারে ডেড প্রমাণ করুন এবং আর্থিং দিন।',
    art: '$_dir/hg_isolate.svg',
    deadly: true,
    lessonPoint: 5,
  );
  static const hgUntested = DoMistake(
    key: '6.3/m6_fuse_chain/hg-untested',
    textBn: 'AB খোলা মানেই লাইন ডেড নয়! টেস্টারে 0 V না দেখে HG-র তারে হাত নয় — তারপর আর্থিং, তবেই কাজ!',
    art: '$_dir/hg_isolate.svg',
    deadly: true,
    lessonPoint: 5,
  );
  static const hgNoEarth = DoMistake(
    key: '6.3/m6_fuse_chain/hg-no-earth',
    textBn: 'টেস্টারে 0 V পেয়েছেন, তাও আর্থ ছাড়া HG-র তারে হাত দিলেন! আগে নিশ্চিতভাবে আর্থিং করুন, তবেই তার বদল।',
    art: '$_dir/hg_isolate.svg',
    deadly: true,
    lessonPoint: 5,
  );
  /// The earth set on the HG with the AB closed (N3 / R29, B8). m5's words.
  static const earthLive = DoMistake(
    key: '6.3/m6_fuse_chain/earth-live',
    textBn: 'চালু লাইনে আর্থিং লাগানো একদম নয়! আগে AB খুলে, টেস্টারে ডেড প্রমাণ — তবে আর্থিং।',
    art: 'assets/game/art/m3_dtr_tap/earth_live.svg',
    deadly: true,
  );
  /// The AB closed with the earth still on the HG: 11 kV straight into the
  /// earth (m5_gate_case 'আর্থ লাগানো অবস্থায় চার্জ … মানেই মৃত্যু'). DRAFT.
  static const closeEarthed = DoMistake(
    key: '6.3/m6_fuse_chain/close-earthed',
    textBn: 'আর্থ লাগানো রেখে AB লাগালেন — 11 kV সোজা আর্থে, মারাত্মক আর্ক! আগে আর্থ খুলুন, তারপর AB লাগান।',
    art: 'assets/game/art/m3_dtr_tap/earth_live.svg',
    deadly: true,
    lessonPoint: 5,
  );
  /// The AB opened or closed with the LT load on (X3, N2, R5). DRAFT.
  static const abOnLoad = DoMistake(
    key: '6.3/m6_fuse_chain/ab-on-load',
    textBn: 'লোড চালু রেখে AB সুইচ খোলা বা লাগানো মারাত্মক বিপদ — ভয়াবহ আর্ক! আগে DTR-এর LT সুইচ বন্ধ করুন, তারপর AB।',
    art: '$_dir/ab_on_load.svg',
    deadly: true,
  );

  // --- slips -------------------------------------------------------------------
  /// 'ক্রম ঠিক' on a broken chain, or a guard that should have fallen first
  /// left unchalked (pro tip 2). DRAFT.
  static const chainWrong = DoMistake(
    key: '6.3/m6_fuse_chain/chain-wrong',
    textBn: 'বাড়ির ফিউজ সবার আগে উড়বে, তারপর LT বক্স, সবশেষে HG। ওপরের HG উড়লে নিচেরটা স্বাভাবিক ধরা যাবে না — ক্যাসকেডিং নিয়ম উল্টো নয়।',
    art: '$_dir/chain.svg',
    lessonPoint: 4,
  );
  /// A chalk on a guard that needs no work (R32). DRAFT.
  static const needlessChalk = DoMistake(
    key: '6.3/m6_fuse_chain/needless-chalk',
    textBn: 'এই প্রহরী ঠিক কাজ করেছে — এতে দাগ মানে বেকার খোলা আর বেকার লাইন বন্ধ। যে আগে পড়ার কথা অথচ পড়েনি, শুধু তাতেই দাগ।',
    art: '$_dir/chain.svg',
    lessonPoint: 4,
  );
  /// A way that needs no work drawn (R32). m3_pillar_fuse's picture. DRAFT.
  static const needlessOpen = DoMistake(
    key: '6.3/m6_fuse_chain/needless-open',
    textBn: 'এই ফেজের ফিউজে কোনো দোষ নেই — খুললে বেকার অন্য বাড়িও অন্ধকার। বাড়ির ড্রপ কোন ফেজে, দেখে নিন।',
    art: 'assets/game/art/m3_pillar_fuse/wrong_fuse.svg',
    lessonPoint: 1,
  );
  /// The DTR's LT switched OFF on a call that needs no LT, or its AB opened
  /// on a call that needs no HG (R32, needless outage). m3_pillar_fuse's
  /// picture. DRAFT.
  static const needlessOutage = DoMistake(
    key: '6.3/m6_fuse_chain/needless-outage',
    textBn: 'এই কাজে এটা বন্ধের দরকার নেই — বেকার শাটডাউন, গোটা পাড়া অন্ধকার। যে প্রহরী সারাবেন, শুধু তার সাপ্লাই বন্ধ করুন।',
    art: 'assets/game/art/m3_pillar_fuse/wrong_fuse.svg',
    lessonPoint: 4,
  );
  /// Fuse wire tied in the HRC base instead of a new HRC (6.3 pro tip 3:
  /// 'তামার পাত বা মোটা তার দিয়ে ডাইরেক্ট … চরম বিপজ্জনক'). m3_pillar_fuse's
  /// picture. DRAFT; the owner may raise it to deadly.
  static const hrcWired = DoMistake(
    key: '6.3/m6_fuse_chain/hrc-wired',
    textBn: 'HRC-র জায়গায় তার দিয়ে ডাইরেক্ট করা চরম বিপজ্জনক — ট্রান্সফরমারে আগুন লেগে যেতে পারে! কাটা HRC-র বদলে নতুন HRC বসান।',
    art: 'assets/game/art/m3_pillar_fuse/bodge.svg',
  );
  /// The supply back on (the LT ON) before every suspect is fixed
  /// (R33; 6.3 point 6). DRAFT.
  static const refuseEarly = DoMistake(
    key: '6.3/m6_fuse_chain/refuse-early',
    textBn: 'জুগাড় এখনও লাইনে! আসল কারণ না সারিয়ে কখনই বারবার ফিউজ চার্জ করবেন না — আগে সব দাগ দেওয়া প্রহরী সারান।',
    art: '$_dir/refuse_early.svg',
    lessonPoint: 5,
  );
  /// A wrong reel in the meter-board kit-kat (16 A = 0.50 mm, IS 9926, X6).
  static const wrongReel = DoMistake(
    key: '6.3/m6_fuse_chain/wrong-reel',
    textBn: 'মিটার বোর্ডের কিট-ক্যাট 16A — তার চাই 0.50 mm (প্রায় 25 SWG)। মোটা তার দিলে ফল্টে গলবে না।',
    art: '$_dir/reel.svg',
    lessonPoint: 3,
  );
  /// A wrong-rating HG wire for the nameplate (R13, M6-5; 6.3 point 1).
  static const wrongHgWire = DoMistake(
    key: '6.3/m6_fuse_chain/wrong-hg-wire',
    textBn: 'নেমপ্লেট দেখে HG-র তার: 25 kVA-তে 2-3A, 63 kVA-তে 5A, 100 kVA-তে 8-10A। বেশি রেটিংয়ের তার ফল্টে গলবে না, ট্রান্সফরমার পুড়বে।',
    art: '$_dir/reel.svg',
    lessonPoint: 0,
  );
  /// Pliers or a bare (gloved) hand on an HRC after a proven isolation (R16,
  /// M6-5; 6.3 point 6). m3_pillar_fuse's picture.
  static const noPuller = DoMistake(
    key: '6.3/m6_fuse_chain/no-puller',
    textBn: 'HRC খোলা বা লাগানোর জন্য সবসময় ইনসুলেটেড ফিউজ পুলার। সুইচ ON থাকলে প্লায়ার্স বা খালি হাত প্রাণঘাতী।',
    art: 'assets/game/art/m3_pillar_fuse/no_puller.svg',
    lessonPoint: 5,
  );
  /// No PPE at a fuse after a proven isolation (A5: a slip there).
  static const noPpeProven = DoMistake(
    key: '6.3/m6_fuse_chain/no-ppe-proven',
    textBn: 'লাইন ডেড প্রমাণ হলেও ফিউজে হাত দেওয়ার আগে ইনসুলেটেড গ্লাভস আর সেফটি গগলস পরুন।',
    art: '$_dir/no_ppe.svg',
    lessonPoint: 5,
  );
  /// LT made dead incompletely (N4; m3_pillar_fuse precedent and words).
  static const noLockTag = DoMistake(
    key: '6.3/m6_fuse_chain/no-lock-tag',
    textBn: 'সুইচ বন্ধ করলেই হলো না — তালা আর ট্যাগ লাগান, যাতে কাজের মাঝে কেউ চালু করে না দেয়।',
    art: 'assets/game/art/m2_phase_swap/lock_prove.svg',
    lessonPoint: 5,
  );
  static const noTest = DoMistake(
    key: '6.3/m6_fuse_chain/no-test',
    textBn: 'বন্ধ জানলেও ফিউজে হাতের আগে টেস্টারে ডেড প্রমাণ করুন — কথা নয়, পরীক্ষাই প্রমাণ।',
    art: 'assets/game/art/m2_phase_swap/lock_prove.svg',
    lessonPoint: 5,
  );
  /// The tester not proved on a live point before the reading (N9) / not
  /// proved again after the 0 V (N4). m3_pillar_fuse's words.
  static const testFirst = DoMistake(
    key: '6.3/m6_fuse_chain/test-before-proof',
    textBn: 'আগে জানা লাইভ পয়েন্টে টেস্টার যাচাই করে নিন — খারাপ টেস্টার কিন্তু চালু লাইনকেও ডেড দেখায়!',
    art: 'assets/game/art/m2_gate_field/live_dead_live.svg',
  );
  static const noReprove = DoMistake(
    key: '6.3/m6_fuse_chain/no-reprove',
    textBn: 'ভোল্টেজ মাপার পর আবার জানা লাইভে টেস্টার দেখে নিন — মাঝপথে টেস্টার বিগড়ালে "0 V"-র কোনো ভরসা নেই!',
    art: 'assets/game/art/m2_gate_field/live_dead_live.svg',
  );
  /// The earth on the HG before the tester's 0 V (N3: a slip). m5's words.
  static const earthFirst = DoMistake(
    key: '6.3/m6_fuse_chain/earth-first',
    textBn: 'আগে টেস্টার দিয়ে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক।',
    art: 'assets/game/art/m5_pm_thermal_round/test_first.svg',
    lessonPoint: 5,
  );
  /// A slow or stalled AB stroke (M6-3, ruling A3). DRAFT.
  static const abStall = DoMistake(
    key: '6.3/m6_fuse_chain/ab-stall',
    textBn: 'AB-র হাতল দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত — মাঝপথে থামবেন না।',
    art: '$_dir/ab_stall.svg',
  );
  /// The LT box door left open: the LT switched back ON with it open, or the
  /// light back with it still open (ruling X4 / M5 N5: "LT back on with the
  /// door open = slip"; m3_pillar_fuse's door-open / on-door-open pattern
  /// and picture). Lesson 6.3 has no door line, so no "পাঠে দেখুন" target.
  // DRAFT wording — owner
  static const doorOpen = DoMistake(
    key: '6.3/m6_fuse_chain/door-open',
    textBn: 'LT বক্সের দরজা খোলা রেখে LT চালু বা কাজ শেষ নয় — ভেতরের লাইভ অংশ বাচ্চা আর পথচারীর নাগালে। দেখা হলেই দরজা বন্ধ করুন।',
    art: 'assets/game/art/m3_pillar_fuse/door_open.svg',
  );

  static const List<DoMistake> all = [
    liveDraw,
    noPpe,
    hgLive,
    hgUntested,
    hgNoEarth,
    earthLive,
    closeEarthed,
    abOnLoad,
    chainWrong,
    needlessChalk,
    needlessOpen,
    needlessOutage,
    hrcWired,
    refuseEarly,
    wrongReel,
    wrongHgWire,
    noPuller,
    noPpeProven,
    noLockTag,
    noTest,
    testFirst,
    noReprove,
    earthFirst,
    abStall,
    doorOpen,
  ];

  /// The catalog's deadlyRules (the level's deadly keys).
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

/// One call.
@immutable
class M6Call {
  const M6Call({
    required this.house,
    required this.phase,
    required this.fallen,
    required this.kitkat,
    this.hrc,
    this.hgPhase = 0,
    required this.why,
  });

  /// The house (1–6) and the phase its service drop is clamped to (0 R, 1 Y,
  /// 2 B).
  final int house;
  final int phase;

  /// The guard that fell.
  final M6Tier fallen;

  /// What the house's kit-kat holds (melted when it fell; a jugaad when it
  /// should have fallen first).
  final M6Content kitkat;

  /// What the house's HRC way holds when opened (a blown cartridge when it
  /// fell; a hidden bypass when it should have fallen first); null = the way
  /// needs no work.
  final M6Content? hrc;

  /// The HG phase whose wire is gone (an HG call).
  final int hgPhase;
  final M6Why why;

  /// The guards that should have fallen first but did not (the chalk).
  Set<M6Tier> get chalkSet => switch (fallen) {
        M6Tier.house => const {},
        M6Tier.lt => const {M6Tier.house},
        M6Tier.hg => const {M6Tier.house, M6Tier.lt},
      };
  bool get needsLt => fallen != M6Tier.house;
  bool get needsHg => fallen == M6Tier.hg;
  bool get kitkatJugaad => kitkat != M6Content.melted;
}

@immutable
class M6ChainDeal {
  const M6ChainDeal({required this.calls, required this.kva, required this.coworkerCall, required this.push});
  final List<M6Call> calls;

  /// The DTR's nameplate (the same transformer all day).
  final int kva;
  final int coworkerCall;
  final M6Push push;
}

/// A fresh day: three calls; the house tier falls at most once, the HG at
/// most once (so at least two broken chains); houses, phases, the jugaad,
/// the HG phase, the kVA, the reason topics and the coworker are dealt.
M6ChainDeal m6ChainDeal(math.Random rng) {
  final tiers = <M6Tier>[
    if (rng.nextBool()) M6Tier.house,
    if (rng.nextInt(3) > 0) M6Tier.hg,
  ];
  while (tiers.length < 3) {
    tiers.add(M6Tier.lt);
  }
  tiers.shuffle(rng);
  final houses = [for (var n = 1; n <= 6; n++) n]..shuffle(rng);
  const kitkatJugaad = [M6Content.gi, M6Content.aluminium, M6Content.thickCopper];
  const hrcJugaad = [M6Content.strip, M6Content.thickCopper];
  final calls = <M6Call>[
    for (final (i, t) in tiers.indexed)
      M6Call(
        house: houses[i],
        phase: rng.nextInt(3),
        fallen: t,
        kitkat: t == M6Tier.house ? M6Content.melted : kitkatJugaad[rng.nextInt(3)],
        hrc: switch (t) {
          M6Tier.house => null,
          M6Tier.lt => M6Content.blownHrc,
          M6Tier.hg => hrcJugaad[rng.nextInt(2)],
        },
        hgPhase: rng.nextInt(3),
        why: m6WhysFor(t)[rng.nextInt(m6WhysFor(t).length)],
      ),
  ];
  return M6ChainDeal(
    calls: calls,
    kva: const [25, 63, 100][rng.nextInt(3)],
    coworkerCall: rng.nextInt(3),
    push: M6Push.values[rng.nextInt(2)],
  );
}

/// What a move did: [ok] it happened; [m] a mistake; [say] a guide nudge (no
/// cost); [live] a tester reading (true = live, false = 0 V, null = none).
@immutable
class M6Step {
  const M6Step({this.ok = false, this.m, this.say, this.live});
  final bool ok;
  final DoMistake? m;
  final String? say;
  final bool? live;
  static const none = M6Step();
  static const done = M6Step(ok: true);
}

/// The play state (pure logic).
class M6ChainRun {
  M6ChainRun(this.deal);
  final M6ChainDeal deal;

  int index = 0;
  int slips = 0;
  int callSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// PPE worn (kept for the day).
  var gloves = false;
  var goggles = false;
  bool get ppe => gloves && goggles;

  M6Stage stage = M6Stage.read;

  // The reads. The LT box door: open now; opened once this call (the HRC
  // dots read); the door-open slip already given this call (the light back
  // with it open, once a call).
  var lookedHg = false;
  var doorOpen = false;
  var doorRead = false;
  var doorSlipped = false;

  // The docket.
  final Set<M6Tier> marks = {};
  var chainOk = false;
  var verdictRight = false;

  // The house's meter board.
  var mainOn = true;
  var kitkatOut = false;
  var kitkatScrapped = false;
  var kitkatFixed = false;

  // The LT switch and the LT box.
  var ltOn = true;
  var lockTag = false;
  int? hrcOut;
  var hrcScrapped = false;
  var hrcFixed = false;

  // The tester: proved on a live point (before), 0 V seen, proved again.
  final Set<M6Target> proved = {};
  final Set<M6Target> dead = {};
  final Set<M6Target> reproved = {};

  // The AB and the HG.
  var abClosed = true;
  var bladesLooked = false;
  var earthed = false;
  var hgRenewed = false;
  var hgTray = false;

  M6Call get call => deal.calls[index.clamp(0, deal.calls.length - 1)];
  bool get done => index >= deal.calls.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => callSlips == 0;
  bool get _work => !ended && stage == M6Stage.work;

  /// The tray up now (one open guard at a time).
  M6Tray get tray {
    if (!_work) return M6Tray.none;
    if (kitkatOut) return M6Tray.kitkat;
    if (hrcOut != null) return M6Tray.hrc;
    if (hgTray && call.needsHg && !hgRenewed) return M6Tray.hg;
    return M6Tray.none;
  }

  /// A chalked guard (one that should have fallen first) still holds its
  /// jugaad.
  bool get suspectsLeft {
    final s = call.chalkSet;
    return (s.contains(M6Tier.house) && !kitkatFixed) || (s.contains(M6Tier.lt) && !hrcFixed);
  }

  /// The house has its light back: every guard put right, every switch back.
  bool get lightBack =>
      kitkatFixed &&
      (!call.needsLt || hrcFixed) &&
      (!call.needsHg || hgRenewed) &&
      mainOn &&
      ltOn &&
      abClosed &&
      !earthed &&
      !lockTag &&
      hrcOut == null &&
      !kitkatOut;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  M6Step _slip(DoMistake m) {
    slips++;
    callSlips++;
    return M6Step(m: m);
  }

  M6Step _deadly(DoMistake m) {
    deadly = m;
    return M6Step(m: m);
  }

  // --- PPE (any time) ------------------------------------------------------------
  void wear(int item) {
    if (ended) return;
    if (item == 0) {
      gloves = true;
    } else {
      goggles = true;
    }
  }

  // --- the reads -----------------------------------------------------------------
  void lookHg() {
    if (!ended && stage != M6Stage.done) lookedHg = true;
  }

  bool openDoor() {
    if (ended || doorOpen) return false;
    doorOpen = true;
    doorRead = true;
    return true;
  }

  /// The LT box door shut again (not while an HRC is out of its base).
  bool closeDoor() {
    if (ended || !doorOpen || hrcOut != null) return false;
    doorOpen = false;
    return true;
  }

  // --- the docket ----------------------------------------------------------------
  /// A chalk ✗ on a guard (or off it again).
  void chalk(M6Tier t) {
    if (ended || stage != M6Stage.read) return;
    chainOk = false;
    if (!marks.remove(t)) marks.add(t);
  }

  void toggleChainOk() {
    if (ended || stage != M6Stage.read) return;
    chainOk = !chainOk;
    if (chainOk) marks.clear();
  }

  /// 'দেখতে যাই': the verdict. A wrong one is a slip; the docket then shows
  /// the right chalk and the work goes on.
  M6Step commit() {
    if (ended || stage != M6Stage.read) return M6Step.none;
    if (!lookedHg || !doorRead) return const M6Step(say: M6ChainLines.readFirst);
    if (marks.isEmpty && !chainOk) return const M6Step(say: M6ChainLines.markFirst);
    final want = call.chalkSet;
    stage = M6Stage.work;
    final right = chainOk ? want.isEmpty : setEquals(marks, want);
    if (right) {
      verdictRight = true;
      _tag(M6ChainLines.caughtChain);
      return M6Step.done;
    }
    final missed = chainOk ? want.isNotEmpty : want.difference(marks).isNotEmpty;
    marks
      ..clear()
      ..addAll(want);
    chainOk = want.isEmpty;
    return _slip(missed ? M6ChainMistakes.chainWrong : M6ChainMistakes.needlessChalk);
  }

  // --- the house's meter board ---------------------------------------------------
  /// The board's main switch. True = it moved.
  bool mainSwitch(bool on) {
    if (!_work || mainOn == on) return false;
    if (on && kitkatOut) return false;
    mainOn = on;
    return true;
  }

  /// The kit-kat carrier drawn by the gloved hand.
  M6Step drawKitkat() {
    if (!_work || kitkatOut || kitkatFixed) return M6Step.none;
    if (mainOn) return _deadly(M6ChainMistakes.liveDraw);
    if (!ppe) return _deadly(M6ChainMistakes.noPpe);
    kitkatOut = true;
    kitkatScrapped = false;
    return M6Step.done;
  }

  // --- the LT switch -------------------------------------------------------------
  /// The DTR's LT switch, OFF or back ON.
  M6Step ltLever(bool on) {
    if (!_work || ltOn == on) return M6Step.none;
    if (!on) {
      // A call with no LT fuse to touch: switching the lane off is a needless
      // outage (R32); the lever stays up.
      if (!call.needsLt) return _slip(M6ChainMistakes.needlessOutage);
      ltOn = false;
      return M6Step.done;
    }
    if (lockTag) return const M6Step(say: M6ChainLines.lockedLever);
    if (hrcOut != null) return const M6Step(say: M6ChainLines.slotEmpty);
    if (suspectsLeft) return _slip(M6ChainMistakes.refuseEarly);
    // LT back on with the LT box door open (X4 / M5 N5): a slip; the lever
    // stays down (m3_pillar_fuse's on-door-open).
    if (doorOpen) return _slip(M6ChainMistakes.doorOpen);
    ltOn = true;
    // Back on: the proof is void; a new isolation is proved afresh.
    proved.remove(M6Target.lt);
    dead.remove(M6Target.lt);
    reproved.remove(M6Target.lt);
    return M6Step.done;
  }

  /// The padlock and tag on the OFF lever (or off it). False = not now.
  bool toggleLockTag() {
    if (!_work || ltOn) return false;
    lockTag = !lockTag;
    return true;
  }

  // --- the tester ----------------------------------------------------------------
  /// Is this proving point live now? The AB's line side always; the LT box's
  /// supply bar while the AB is closed.
  bool liveAt(M6Point p) => p == M6Point.abLine || abClosed;

  /// What a proving point proves the tester for: the same voltage only (X1,
  /// A9) — the LT box's supply bar (415 V) for an HRC, the AB's 11 kV line
  /// side for the HG.
  static M6Target provesFor(M6Point p) => switch (p) {
        M6Point.ltSupply => M6Target.lt,
        M6Point.abLine => M6Target.hg,
      };

  /// The tester on a proving point: live → it proves the tester for that
  /// voltage (before the reading, or again after a 0 V).
  M6Step testLive(M6Point p) {
    if (!_work) return M6Step.none;
    final live = liveAt(p);
    if (live) {
      final t = provesFor(p);
      proved.add(t);
      if (dead.contains(t)) reproved.add(t);
    }
    return M6Step(ok: true, live: live);
  }

  /// The tester on an HRC ([M6Target.lt]) or the HG. A live reading is never
  /// punished (A9); a 0 V on a tester not yet proved is a slip (N9).
  M6Step testOn(M6Target t) {
    if (!_work) return M6Step.none;
    if (t == M6Target.hg && !abClosed && !bladesLooked) return const M6Step(say: M6ChainLines.bladesFirst);
    final live = t == M6Target.lt ? ltOn : abClosed;
    if (live) return const M6Step(ok: true, live: true);
    if (!proved.contains(t)) return _slip(M6ChainMistakes.testFirst);
    dead.add(t);
    reproved.remove(t);
    return const M6Step(ok: true, live: false);
  }

  /// Why a hand, the puller or a new HRC may not go in yet (A5, X4): the LT
  /// on is deadly; no lock and tag, no 0 V, no re-proof are slips.
  M6Step? _notIsolatedLt() {
    if (ltOn) return _deadly(M6ChainMistakes.liveDraw);
    if (!lockTag) return _slip(M6ChainMistakes.noLockTag);
    if (!dead.contains(M6Target.lt)) return _slip(M6ChainMistakes.noTest);
    if (!reproved.contains(M6Target.lt)) return _slip(M6ChainMistakes.noReprove);
    return null;
  }

  // --- the LT box ----------------------------------------------------------------
  /// An HRC touched with [tool] (null = the hand; the page sends the tester
  /// to [testOn]).
  M6Step hrcTap(int i, M6Tool? tool) {
    if (!_work || !doorOpen || hrcOut != null) return M6Step.none;
    if (hrcFixed && i == call.phase) return M6Step.none;
    final iso = _notIsolatedLt();
    if (iso != null) return iso;
    if (!ppe) return _slip(M6ChainMistakes.noPpeProven);
    if (tool != M6Tool.puller) return _slip(M6ChainMistakes.noPuller);
    if (!call.needsLt || i != call.phase) return _slip(M6ChainMistakes.needlessOpen);
    hrcOut = i;
    hrcScrapped = false;
    _tag(M6ChainLines.caughtIsolate);
    _tag(M6ChainLines.caughtPuller);
    return M6Step.done;
  }

  // --- the AB and the HG ----------------------------------------------------------
  /// A stroke on the AB handle ([progress] 0–1 of the travel; [stalled]: it
  /// stopped mid-arc). Opens a closed AB, closes an open one.
  M6Step abStroke(double progress, {bool stalled = false}) {
    if (!_work || progress < 0.15) return M6Step.none;
    if (abClosed) {
      if (ltOn) return _deadly(M6ChainMistakes.abOnLoad);
      // No HG to renew: opening the DTR is a needless outage (R32).
      if (!call.needsHg) return _slip(M6ChainMistakes.needlessOutage);
      if (stalled || progress < 0.85) return _slip(M6ChainMistakes.abStall);
      abClosed = false;
      bladesLooked = false;
      return M6Step.done;
    }
    // Closing onto the earth = charging an earthed HG (m5_gate_case).
    if (earthed) return _deadly(M6ChainMistakes.closeEarthed);
    if (ltOn) return _deadly(M6ChainMistakes.abOnLoad);
    // A suspect still in is no reason to keep the AB open: the LT is OFF, so
    // nothing reaches it; the LT switch scores R33.
    if (stalled || progress < 0.85) return _slip(M6ChainMistakes.abStall);
    abClosed = true;
    hgTray = false;
    proved.remove(M6Target.hg);
    dead.remove(M6Target.hg);
    reproved.remove(M6Target.hg);
    return M6Step.done;
  }

  /// A look at the AB's blades. True = all three seen open now.
  bool lookBlades() {
    if (ended || abClosed) return false;
    bladesLooked = true;
    return true;
  }

  /// The earth set on the HG (or taken off again).
  M6Step earthTap() {
    if (!_work) return M6Step.none;
    if (earthed) {
      earthed = false;
      return M6Step.done;
    }
    if (abClosed) return _deadly(M6ChainMistakes.earthLive);
    if (!dead.contains(M6Target.hg)) return _slip(M6ChainMistakes.earthFirst);
    if (!reproved.contains(M6Target.hg)) return _slip(M6ChainMistakes.noReprove);
    earthed = true;
    return M6Step.done;
  }

  /// The HG tapped by hand in the work: its spares come up when it fell (the
  /// tray toggles); otherwise it is only a look. True = the tray toggled.
  bool hgTap() {
    if (!_work) return false;
    if (!call.needsHg || hgRenewed) {
      lookedHg = true;
      return false;
    }
    hgTray = !hgTray;
    return true;
  }

  // --- the spares tray ------------------------------------------------------------
  /// A spare (or the scrap pile) picked with [held] in hand.
  M6Step spare(M6Spare s, M6Tool? held) {
    switch (tray) {
      case M6Tray.none:
        return M6Step.none;
      case M6Tray.kitkat:
        if (s == M6Spare.scrap) {
          if (kitkatScrapped) return M6Step.none;
          kitkatScrapped = true;
          if (call.kitkatJugaad) _tag(M6ChainLines.caughtJugaad);
          return M6Step.done;
        }
        if (!const {M6Spare.mm050, M6Spare.mm085, M6Spare.mm150, M6Spare.mm200}.contains(s)) return M6Step.none;
        if (!kitkatScrapped) return const M6Step(say: M6ChainLines.scrapFirst);
        if (s != M6Spare.mm050) return _slip(M6ChainMistakes.wrongReel);
        kitkatOut = false;
        kitkatFixed = true;
        _tag(M6ChainLines.caughtReel);
        return M6Step.done;
      case M6Tray.hrc:
        if (s == M6Spare.scrap) {
          if (hrcScrapped) return M6Step.none;
          hrcScrapped = true;
          if (call.hrc != M6Content.blownHrc) _tag(M6ChainLines.caughtJugaad);
          return M6Step.done;
        }
        if (!const {M6Spare.hrc, M6Spare.mm050, M6Spare.mm200}.contains(s)) return M6Step.none;
        if (!hrcScrapped) return const M6Step(say: M6ChainLines.scrapFirst);
        final iso = _notIsolatedLt();
        if (iso != null) return iso;
        // Fuse wire tied straight across the HRC base (pro tip 3).
        if (s != M6Spare.hrc) return _slip(M6ChainMistakes.hrcWired);
        if (held != M6Tool.puller) return _slip(M6ChainMistakes.noPuller);
        hrcOut = null;
        hrcFixed = true;
        return M6Step.done;
      case M6Tray.hg:
        if (!const {M6Spare.hg3, M6Spare.hg5, M6Spare.hg10}.contains(s)) return M6Step.none;
        if (abClosed) return _deadly(M6ChainMistakes.hgLive);
        if (!dead.contains(M6Target.hg)) return _deadly(M6ChainMistakes.hgUntested);
        if (!earthed) return _deadly(M6ChainMistakes.hgNoEarth);
        if (!ppe) return _slip(M6ChainMistakes.noPpeProven);
        if (s != m6HgSpareFor(deal.kva)) return _slip(M6ChainMistakes.wrongHgWire);
        hgRenewed = true;
        hgTray = false;
        _tag(M6ChainLines.caughtHg);
        return M6Step.done;
    }
  }

  /// The call is done once the light is back (the page checks [lightBack]).
  void finishCall() {
    if (!ended) stage = M6Stage.done;
  }

  /// The light is back: the call ends ([M6Step.done]) — unless the LT box
  /// door is still open (X4 / M5 N5): a slip once a call, and the call ends
  /// once the door is shut.
  M6Step lightCheck() {
    if (!_work || !lightBack) return M6Step.none;
    if (doorOpen) {
      if (doorSlipped) return M6Step.none;
      doorSlipped = true;
      return _slip(M6ChainMistakes.doorOpen);
    }
    finishCall();
    return M6Step.done;
  }

  /// Listened to the coworker: that draw on load (B1).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    callSlips = 0;
    stage = M6Stage.read;
    lookedHg = false;
    doorOpen = false;
    doorRead = false;
    doorSlipped = false;
    marks.clear();
    chainOk = false;
    verdictRight = false;
    mainOn = true;
    kitkatOut = false;
    kitkatScrapped = false;
    kitkatFixed = false;
    ltOn = true;
    lockTag = false;
    hrcOut = null;
    hrcScrapped = false;
    hrcFixed = false;
    proved.clear();
    dead.clear();
    reproved.clear();
    abClosed = true;
    bladesLooked = false;
    earthed = false;
    hgRenewed = false;
    hgTray = false;
  }
}

/// The quick bonus: a little under a clean play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   PPE (2 drags) ≈ 3000
///   reads (HG, door) + chalk + 'দেখতে যাই' ≈ 6000–7500 a call
///   house: switch, draw, scrap, reel, switch ≈ 7500
///   HRC: LT off, lock, belt ×4, proof ×3, puller ×2, scrap, spare, unlock,
///     LT on ≈ 21000
///   HG: AB stroke ×2, blades, earth ×2, tester ×3 (+ belt), tray, reel
///     ≈ 18000
///   a typical day (house, HRC, HG): 7000×3 + 7500 + (7500 + 21000) +
///     (7500 + 21000 + 18000) ≈ 103500, + PPE 3000, + 3 reasons ~8000
///     each, + the coworker ~9600 ≈ 140000
/// 85 % ≈ 119000 → 120 s.
const m6FuseChainQuickMs = 120000;

/// The belt, shuffled; never laid out in its working order (lock-tag →
/// tester → puller → earth).
List<M6Tool> m6BeltRow(math.Random rng) {
  final tools = [...M6Tool.values];
  do {
    tools.shuffle(rng);
  } while (m6BeltInWorkOrder(tools));
  return tools;
}

bool m6BeltInWorkOrder(List<M6Tool> row) {
  final at = [for (final t in const [M6Tool.lockTag, M6Tool.tester, M6Tool.puller, M6Tool.earth]) row.indexOf(t)];
  for (var i = 1; i < at.length; i++) {
    if (at[i - 1] > at[i]) return false;
  }
  return true;
}

/// The tray's spares for an open guard, shuffled (the scrap pile always on
/// the left).
List<M6Spare> m6TrayRow(M6Tray t, math.Random rng) {
  final spares = switch (t) {
    M6Tray.none => <M6Spare>[],
    M6Tray.kitkat => [M6Spare.mm050, M6Spare.mm085, M6Spare.mm150, M6Spare.mm200],
    M6Tray.hrc => [M6Spare.hrc, M6Spare.mm050, M6Spare.mm200],
    M6Tray.hg => [M6Spare.hg3, M6Spare.hg5, M6Spare.hg10],
  }..shuffle(rng);
  return [if (t == M6Tray.kitkat || t == M6Tray.hrc) M6Spare.scrap, ...spares];
}

@immutable
class M6FuseChainPack {
  const M6FuseChainPack({required this.id, required this.titleBn, this.quickMs = m6FuseChainQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6FuseChainPack> m6FuseChainPacks = {
  'do_6_3_b': M6FuseChainPack(id: 'do_6_3_b', titleBn: M6ChainLines.title),
};

/// The docket's layout (design px inside its 130 × 178 box).
abstract final class M6Docket {
  static const Rect head = Rect.fromLTWH(6, 3, 118, 20);
  static Rect tier(M6Tier t) => Rect.fromLTWH(6, switch (t) { M6Tier.hg => 25.0, M6Tier.lt => 57.0, M6Tier.house => 89.0 }, 118, 28);
  static const Rect chalk = Rect.fromLTWH(6, 122, 38, 26);
  static const Rect chainOk = Rect.fromLTWH(48, 122, 76, 26);
  static const Rect go = Rect.fromLTWH(6, 152, 118, 22);
}

// ============================================================================
// Page
// ============================================================================

class M6FuseChainPage extends StatefulWidget {
  const M6FuseChainPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6FuseChainPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6FuseChainPage> createState() => _M6FuseChainPageState();
}

class _M6FuseChainPageState extends State<M6FuseChainPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ChainRunPage(
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

/// Test-only hook into a running play.
@visibleForTesting
abstract final class M6FuseChainProbe {
  static M6ChainRun? run;
}

class _ChainRunPage extends ConsumerStatefulWidget {
  const _ChainRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6FuseChainPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ChainRunPage> createState() => _ChainRunPageState();
}

enum _Drag { none, ppe0, ppe1, ltLever, main, ab }

class _ChainRunPageState extends ConsumerState<_ChainRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6ChainRun _run;
  late final List<List<M6Tool>> _belts;
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

  /// The tool in hand.
  M6Tool? _held;

  /// The reading card and the tester chip.
  M6Card? _shown;
  int _cardTok = 0;
  ({Offset at, bool live})? _testerChip;
  Timer? _chipTimer;

  /// The tray's order (dealt when it opens).
  M6Tray _trayNow = M6Tray.none;
  List<M6Spare> _trayRow = const [];

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;
  var _callBusy = false;

  /// The gesture hand.
  final _hints = IdleHintController();
  final Map<M6Tool, GlobalKey> _toolKeys = {for (final t in M6Tool.values) t: GlobalKey()};
  final Map<M6Spare, GlobalKey> _spareKeys = {for (final s in M6Spare.values) s: GlobalKey()};
  final _chalkKey = GlobalKey();
  final _okKey = GlobalKey();
  final Map<M6Tier, GlobalKey> _tierKeys = {for (final t in M6Tier.values) t: GlobalKey()};
  int _hintN = 0;
  int _steps = 0;

  /// His push, fixed when he first comes (so his words fit that moment).
  M6Push? _pushNow;
  M6ChainGeo? _geoNow;

  // A drag on the scene.
  _Drag _drag = _Drag.none;
  Offset _dragFrom = Offset.zero;
  Offset _dragNow = Offset.zero;
  Duration? _lastMoveAt;
  var _stalled = false;
  double _maxProgress = 0;

  @override
  void initState() {
    super.initState();
    _run = M6ChainRun(m6ChainDeal(widget.rng));
    _belts = [for (var i = 0; i < 3; i++) m6BeltRow(widget.rng)];
    M6FuseChainProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chipTimer?.cancel();
    _chain++;
    if (M6FuseChainProbe.run == _run) M6FuseChainProbe.run = null;
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

  M6Call get _call => _run.call;
  List<M6Tool> get _belt => _belts[_run.index.clamp(0, 2)];
  bool get _working => _run.stage == M6Stage.work;

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && !_callBusy && _run.stage != M6Stage.done;

  String get _task => switch (_run.stage) {
        M6Stage.read => (_run.lookedHg && _run.doorRead) ? M6ChainLines.askVerdict : M6ChainLines.askRead,
        M6Stage.work || M6Stage.done => M6ChainLines.askWork,
      };

  Future<void> _start() async {
    _clock.start();
    _startCall();
  }

  void _startCall() {
    setState(() {
      _wake++;
      _held = null;
      _shown = null;
      _testerChip = null;
    });
    unawaited(_sayChain([M6ChainLines.call(_call.house), M6ChainLines.askRead]));
  }

  /// His call, the work begun: the first touch on any guard (or the belt)
  /// brings him in now and does nothing.
  bool _guard() {
    if (_run.index != _run.deal.coworkerCall || coworkerDone || !_working) return false;
    if (!coworkerDue) scheduleCoworker();
    return holdForCoworker();
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
    _checkLight();
  }

  void _syncTray() {
    final t = _run.tray;
    if (t == _trayNow) return;
    _trayNow = t;
    _trayRow = m6TrayRow(t, widget.rng);
  }

  void _showCard(M6Card c) {
    setState(() {
      _shown = c;
      _cardTok++;
    });
  }

  void _chip(Offset at, bool live) {
    _chipTimer?.cancel();
    setState(() => _testerChip = (at: at, live: live));
    _chipTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _testerChip = null);
    });
  }

  /// Handle a step: a nudge, a mistake (at [origin]; the flash at [flash]),
  /// or done.
  bool _handle(M6Step s, Offset origin, {Offset? flash}) {
    if (s.say != null) {
      _tick();
      unawaited(_sayChain([s.say!]));
      return false;
    }
    final m = s.m;
    if (m != null) {
      if (flash != null) _flashAt = flash;
      setState(() => _wake++);
      unawaited(_mistake(m, origin));
      return false;
    }
    return s.ok;
  }

  // --- the PPE, the reads ------------------------------------------------------------
  void _wear(int item) {
    _tick('sounds/intro/click.ogg', 0.55);
    _run.wear(item);
    _stepDone();
  }

  // --- the scene: taps -----------------------------------------------------------------
  void _tapScene(Offset p, M6ChainGeo geo, Offset global) {
    if (!_canPlay) return;
    final held = _held;
    // The reads (by eye, any time before the work and in it).
    if (held == null && geo.hgHit.contains(p)) {
      if (_working) {
        if (_guard()) return;
        if (_run.hgTap()) {
          _tick('sounds/intro/click.ogg', 0.5);
          _syncTray();
          _stepDone();
          return;
        }
      }
      _tick();
      _run.lookHg();
      _showCard(M6Card.hg);
      _stepDone();
      return;
    }
    if (held == null && geo.ltBox.contains(p) && !_run.doorOpen) {
      if (_working && _guard()) return;
      _tick('sounds/intro/impact_metal.ogg', 0.45);
      _run.openDoor();
      _stepDone();
      return;
    }
    // The open door's leaf: a tap shuts it (any time; not while an HRC is out).
    if (held == null && _run.doorOpen && geo.doorHit.contains(p)) {
      if (_working && _guard()) return;
      if (_run.closeDoor()) {
        _tick('sounds/intro/impact_metal.ogg', 0.45);
        _stepDone();
      } else {
        _hints.missTap();
      }
      return;
    }
    if (held == null && geo.abBladesHit.contains(p)) {
      if (_working && _guard()) return;
      _tick();
      if (_run.lookBlades()) _showCard(M6Card.blades);
      _stepDone();
      return;
    }
    // Everything else is the work.
    final onGuard = geo.kitkatHit.contains(p) ||
        geo.mainHit.contains(p) ||
        geo.ltLeverHit.contains(p) ||
        geo.abHandle.contains(p) ||
        geo.abLineHit.contains(p) ||
        geo.ltSupplyHit.contains(p) ||
        geo.hgHit.contains(p) ||
        [for (var i = 0; i < 3; i++) geo.hrcHit(i)].any((r) => r.contains(p));
    if (!_working) {
      if (onGuard) {
        _tick();
        unawaited(_sayChain([M6ChainLines.workLater]));
      } else {
        _hints.missTap();
      }
      return;
    }
    if (onGuard && _guard()) return;
    if (held == null) {
      if (geo.kitkatHit.contains(p)) {
        final s = _run.drawKitkat();
        if (_handle(s, global, flash: geo.kitkatHit.center)) {
          _tick('sounds/intro/click.ogg', 0.6);
          _syncTray();
          _showCard(M6Card.kitkat);
          _stepDone();
        }
        return;
      }
      for (var i = 0; i < 3; i++) {
        if (_run.doorOpen && geo.hrcHit(i).contains(p)) {
          final s = _run.hrcTap(i, null);
          _handle(s, global, flash: geo.hrcCenter(i));
          return;
        }
      }
      _hints.missTap();
      return;
    }
    switch (held) {
      case M6Tool.tester:
        if (geo.abLineHit.contains(p) || (geo.ltSupplyHit.contains(p) && _run.doorOpen)) {
          final s = _run.testLive(geo.abLineHit.contains(p) ? M6Point.abLine : M6Point.ltSupply);
          _tick('sounds/learn/dmm_beep.ogg', 0.5);
          _chip(p, s.live ?? false);
          _stepDone();
          return;
        }
        for (var i = 0; i < 3; i++) {
          if (_run.doorOpen && geo.hrcHit(i).contains(p)) {
            final s = _run.testOn(M6Target.lt);
            if (_handle(s, global)) {
              _tick('sounds/learn/dmm_beep.ogg', 0.5);
              _chip(geo.hrcCenter(i), s.live ?? false);
              _stepDone();
            }
            return;
          }
        }
        if (geo.hgHit.contains(p)) {
          final s = _run.testOn(M6Target.hg);
          if (_handle(s, global)) {
            _tick('sounds/learn/dmm_beep.ogg', 0.5);
            _chip(geo.hgHit.center, s.live ?? false);
            _stepDone();
          }
          return;
        }
      case M6Tool.puller:
      case M6Tool.pliers:
        for (var i = 0; i < 3; i++) {
          if (_run.doorOpen && geo.hrcHit(i).contains(p)) {
            final s = _run.hrcTap(i, held);
            if (_handle(s, global, flash: geo.hrcCenter(i))) {
              _tick('sounds/intro/impact_metal.ogg', 0.5);
              _syncTray();
              _showCard(M6Card.hrc);
              _stepDone();
            }
            return;
          }
        }
      case M6Tool.lockTag:
        if (geo.ltLeverHit.contains(p)) {
          if (_run.toggleLockTag()) {
            _tick('sounds/learn/tag_slap.ogg', 0.55);
            setState(() => _held = null);
            _stepDone();
          } else {
            _hints.missTap();
          }
          return;
        }
      case M6Tool.earth:
        if (geo.hgHit.contains(p)) {
          final s = _run.earthTap();
          if (_handle(s, global, flash: geo.hgHit.center)) {
            _tick('sounds/intro/impact_metal.ogg', 0.55);
            setState(() => _held = null);
            _stepDone();
          }
          return;
        }
    }
    _hints.missTap();
  }

  // --- the scene: drags (PPE onto the worker, levers, the AB stroke) ---------------------
  void _panStart(DragStartDetails d, M6ChainGeo geo) {
    if (!_canPlay) {
      _drag = _Drag.none;
      return;
    }
    final p = d.localPosition;
    _dragFrom = p;
    _dragNow = p;
    _lastMoveAt = d.sourceTimeStamp;
    _stalled = false;
    _maxProgress = 0;
    if (!_run.gloves && geo.ppeHit(0).contains(p)) {
      _drag = _Drag.ppe0;
    } else if (!_run.goggles && geo.ppeHit(1).contains(p)) {
      _drag = _Drag.ppe1;
    } else if (geo.ltLeverHit.contains(p)) {
      _drag = _Drag.ltLever;
    } else if (geo.mainHit.contains(p)) {
      _drag = _Drag.main;
    } else if (geo.abHandle.inflate(6).contains(p)) {
      _drag = _Drag.ab;
    } else {
      _drag = _Drag.none;
    }
    if (_drag == _Drag.ppe0 || _drag == _Drag.ppe1) setState(() => _wake++);
  }

  void _panUpdate(DragUpdateDetails d, M6ChainGeo geo) {
    if (_drag == _Drag.none) return;
    final was = _dragNow;
    _dragNow = d.localPosition;
    if (_drag == _Drag.ab) {
      final prog = _abProgress(geo);
      // A pause mid-arc is a stall (ruling A3: one firm, continuous stroke).
      final t = d.sourceTimeStamp;
      if (t != null && _lastMoveAt != null && (t - _lastMoveAt!) > const Duration(milliseconds: 600) && prog > 0.15 && prog < 0.85) _stalled = true;
      if ((d.localPosition - was).distance > 0.5) _lastMoveAt = t;
      _maxProgress = math.max(_maxProgress, prog);
    }
    if (_drag == _Drag.ppe0 || _drag == _Drag.ppe1) setState(() {});
  }

  double _abProgress(M6ChainGeo geo) {
    final dy = _dragNow.dy - _dragFrom.dy;
    final along = _run.abClosed ? dy : -dy;
    return (along / geo.abTravel).clamp(0.0, 1.0);
  }

  void _panEnd(M6ChainGeo geo, Offset global) {
    final kind = _drag;
    _drag = _Drag.none;
    if (kind == _Drag.none || !_canPlay) {
      if (kind != _Drag.none) setState(() {});
      return;
    }
    final dy = _dragNow.dy - _dragFrom.dy;
    switch (kind) {
      case _Drag.ppe0:
      case _Drag.ppe1:
        setState(() {});
        if (geo.worker.inflate(18).contains(_dragNow)) {
          _wear(kind == _Drag.ppe0 ? 0 : 1);
        } else {
          _hints.missTap();
        }
      case _Drag.ltLever:
        if (dy.abs() < 24) {
          _hints.missTap();
          return;
        }
        if (!_working) {
          _tick();
          unawaited(_sayChain([M6ChainLines.workLater]));
          return;
        }
        if (_guard()) return;
        final s = _run.ltLever(dy < 0);
        if (_handle(s, global, flash: geo.ltLeverHit.center)) {
          _tick('sounds/intro/impact_metal.ogg', 0.55);
          _stepDone();
        }
      case _Drag.main:
        if (dy.abs() < 18) {
          _hints.missTap();
          return;
        }
        if (!_working) {
          _tick();
          unawaited(_sayChain([M6ChainLines.workLater]));
          return;
        }
        if (_guard()) return;
        if (_run.mainSwitch(dy < 0)) {
          _tick('sounds/intro/click.ogg', 0.6);
          _stepDone();
        } else {
          _hints.missTap();
        }
      case _Drag.ab:
        final prog = math.max(_maxProgress, _abProgress(geo));
        if (prog < 0.15) {
          _hints.missTap();
          return;
        }
        if (!_working) {
          _tick();
          unawaited(_sayChain([M6ChainLines.workLater]));
          return;
        }
        if (_guard()) return;
        final s = _run.abStroke(prog, stalled: _stalled);
        if (_handle(s, global, flash: Offset(M6ChainGeo.phaseX[1], geo.abArmY))) {
          _tick('sounds/intro/impact_metal.ogg', 0.7);
          _stepDone();
        }
      case _Drag.none:
        break;
    }
  }

  // --- the belt and the tray --------------------------------------------------------------
  void _tapTool(M6Tool t) {
    if (!_canPlay || !_working) return;
    if (_guard()) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _held = _held == t ? null : t;
      _wake++;
    });
  }

  void _pickSpare(M6Spare s, Offset global) {
    if (!_canPlay || !_working) return;
    if (_guard()) return;
    final geo = _geoNow;
    final tray = _run.tray;
    final flash = geo == null ? null : (tray == M6Tray.hg ? geo.hgHit.center : geo.hrcCenter(_call.phase));
    final st = _run.spare(s, _held);
    if (_handle(st, global, flash: flash)) {
      _tick(s == M6Spare.scrap ? 'sounds/learn/tag_slap.ogg' : 'sounds/intro/click.ogg', 0.55);
      _syncTray();
      if (_run.tray == M6Tray.none) setState(() => _shown = null);
      _stepDone();
    }
  }

  // --- the docket ---------------------------------------------------------------------------
  void _chalk(M6Tier t) {
    if (!_canPlay || _run.stage != M6Stage.read) return;
    HapticFeedback.lightImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.45);
    _run.chalk(t);
    _stepDone();
  }

  void _toggleOk() {
    if (!_canPlay || _run.stage != M6Stage.read) return;
    _tick('sounds/intro/click.ogg', 0.55);
    _run.toggleChainOk();
    _stepDone();
  }

  void _goLook(Offset global) {
    if (!_canPlay || _run.stage != M6Stage.read) return;
    final s = _run.commit();
    if (s.say != null) {
      _tick();
      unawaited(_sayChain([s.say!]));
      return;
    }
    if (s.m != null) {
      setState(() => _wake++);
      unawaited(_mistake(s.m!, global));
      return;
    }
    if (!s.ok) return;
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    final idx = _run.index;
    if (m6WhyAtVerdict(_call.why)) {
      putOnTable(15);
      unawaited(askReason(
        deal: () => dealChoices(M6ChainLines.whyRight[_call.why]!, M6ChainLines.myths, widget.rng),
        question: M6ChainLines.whyQ[_call.why]!,
        stillValid: () => _run.index == idx && !_ended,
      ));
    } else {
      unawaited(_levelDelta(10, global, mood: GuideMood.glad));
      setState(() => _wake++);
      unawaited(_sayChain([M6ChainLines.verdictRight, M6ChainLines.askWork], mood: GuideMood.glad));
    }
  }

  void _startWork() {
    setState(() => _wake++);
    unawaited(_sayChain([M6ChainLines.askWork]));
  }

  /// The light is back: the call's ◆ (and its reason when the topic is
  /// about the work), then the next call.
  void _checkLight() {
    if (_ended || !_working || !_run.lightBack || _callBusy) return;
    final s = _run.lightCheck();
    if (s.m != null) {
      // The light is back with the LT box door open (X4 / M5 N5).
      final geo = _geoNow;
      if (geo != null) _flashAt = geo.doorHit.center;
      final size = MediaQuery.sizeOf(context);
      setState(() => _wake++);
      unawaited(_mistake(s.m!, Offset(size.width * 0.2, size.height * 0.5)));
      return;
    }
    if (!s.ok) return;
    _callBusy = true;
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() {
      _held = null;
      _shown = null;
      _wake++;
    });
    final idx = _run.index;
    final pay = 15 + (_run.thorough ? 5 : 0);
    if (!m6WhyAtVerdict(_call.why)) {
      _callBusy = false;
      putOnTable(pay);
      unawaited(askReason(
        deal: () => dealChoices(M6ChainLines.whyRight[_call.why]!, M6ChainLines.myths, widget.rng),
        question: M6ChainLines.whyQ[_call.why]!,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    final size = MediaQuery.sizeOf(context);
    unawaited(() async {
      unawaited(_levelDelta(pay - 5, Offset(size.width / 2, size.height * 0.4), mood: GuideMood.glad));
      await _sayChain([M6ChainLines.lightBack], mood: GuideMood.glad);
      await Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900));
      if (!mounted || _ended || _run.index != idx) return;
      _callBusy = false;
      _next();
    }());
  }

  void _next() {
    setState(() {
      _run.next();
      _trayNow = M6Tray.none;
      _trayRow = const [];
    });
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startCall();
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
    final atVerdict = _run.stage == M6Stage.work;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (!mounted || _ended || _run.index != idx) return;
      if (atVerdict) {
        _startWork();
      } else {
        _next();
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6ChainLines.coworker(_pushNow ??= M6ChainLines.pushNow(_run.deal.push, gloves: _run.gloves));
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerCall || _run.stage == M6Stage.done) return null;
    if (_intro || _card != null || tableBusy || _freeze || !_working) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      const m = M6ChainMistakes.liveDraw;
      final geo = _geoNow;
      if (geo != null) _flashAt = _call.needsLt && _run.doorOpen ? geo.hrcCenter(_call.phase) : geo.kitkatHit.center;
      _run.failDeadly(m);
      await _deadly(m);
      return;
    }
    _run.caught.add(M6ChainLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6ChainLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6ChainLines.tapWhy[_nudgeN++ % M6ChainLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('m6chain/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A fuse drawn live, the AB on load, the HG touched live: the scene
  /// freezes grey and the flash comes off it in colour; then near-miss or
  /// death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _chipTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _held = null;
      _testerChip = null;
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
    final speak = await SpokenOnce.first('m6chain/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6ChainLines.deadlyWord : M6ChainLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same call goes on from where it was (after a wrong verdict the
        // docket shows the right chalk and the work begins).
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        _syncTray();
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
    await _say(!_run.passed ? M6ChainLines.fail : (_quickBonus ? M6ChainLines.quick : M6ChainLines.allSet),
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
    if (_held != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6ChainRig get _rig {
    final c = _call;
    return M6ChainRig(
      house: c.house,
      phase: c.phase,
      kva: _run.deal.kva,
      hgBlown: c.needsHg && !_run.hgRenewed ? c.hgPhase : -1,
      abClosed: _run.abClosed,
      earthed: _run.earthed,
      doorOpen: _run.doorOpen,
      hrc: [
        for (var i = 0; i < 3; i++)
          _run.hrcOut == i
              ? M6HrcState.out
              : (c.fallen == M6Tier.lt && i == c.phase && !_run.hrcFixed)
                  ? M6HrcState.blown
                  : M6HrcState.ok,
      ],
      ltOn: _run.ltOn,
      lockTag: _run.lockTag,
      mainOn: _run.mainOn,
      kitkatOut: _run.kitkatOut,
      gloves: _run.gloves,
      goggles: _run.goggles,
      lit: _run.stage == M6Stage.done,
    );
  }

  /// The gesture hand: how to touch, never what.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    final held = _held;
    final ppe = !_run.ppe
        ? HintSpec.sweep([if (!_run.gloves) geo.ppeHit(0), if (!_run.goggles) geo.ppeHit(1), geo.worker], space: HintSpace.scene)
        : null;
    if (_run.stage == M6Stage.read) {
      final reads = HintSpec.sweep([geo.hgHit, geo.ltBox, geo.meterBoard], space: HintSpace.scene);
      if (!(_run.lookedHg && _run.doorRead)) {
        final ways = <HintSpec?>[reads, ?ppe];
        return ways[n % ways.length];
      }
      final ways = <HintSpec? Function()>[
        () => HintSpec.sweepOver([for (final t in M6Tier.values.reversed) _tierKeys[t]!, _okKey]),
        () => HintSpec.dragFrom(_chalkKey, toward: const Offset(0, -1)),
        () => ppe,
      ];
      return ways[n % ways.length]();
    }
    if (_run.tray != M6Tray.none) {
      final keys = [for (final s in _trayRow) _spareKeys[s]!];
      if (n.isEven && keys.length > 1) return HintSpec.sweepOver(keys);
    }
    if (held != null) {
      final rects = <Rect>[
        if (held == M6Tool.tester) ...[geo.abLineHit, if (_run.doorOpen) geo.ltSupplyHit, geo.hgHit],
        if (held == M6Tool.tester || held == M6Tool.puller || held == M6Tool.pliers)
          if (_run.doorOpen) for (var i = 0; i < 3; i++) geo.hrcHit(i),
        if (held == M6Tool.lockTag) ...[geo.ltLeverHit, geo.mainHit],
        if (held == M6Tool.earth) ...[geo.hgHit, geo.abLineHit],
      ];
      return rects.length < 2 ? null : HintSpec.sweep(rects, space: HintSpace.scene);
    }
    final ways = <HintSpec? Function()>[
      () => HintSpec.sweep([geo.mainHit, geo.ltLeverHit, geo.abHandle, if (_run.doorOpen) geo.doorHit], space: HintSpace.scene),
      () => HintSpec.sweepOver([for (final t in _belt) _toolKeys[t]!]),
      () => HintSpec.sweep([geo.kitkatHit, for (var i = 0; i < 3; i++) geo.hrcHit(i), geo.hgHit], space: HintSpace.scene),
      () => ppe,
    ];
    return ways[n % ways.length]();
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6ChainGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final c = _call;
    final shown = _shown;
    final chip = _testerChip;
    final dragging = _drag == _Drag.ppe0 || _drag == _Drag.ppe1;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('lane'),
                child: RepaintBoundary(child: CustomPaint(painter: M6ChainPainter(geo: geo, rig: _rig, seed: _run.index * 7 + c.house))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.worker,
                child: LinemanFigure(look: _run.gloves ? _rubberGloved : LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              if (_run.goggles)
                Positioned.fromRect(
                  key: const ValueKey('goggles'),
                  rect: geo.worker,
                  child: const IgnorePointer(child: CustomPaint(painter: M6GogglesPainter())),
                ),
            ],
          ),
        ),
      ),
      if (chip != null && !_freeze)
        Positioned(
          key: ValueKey('tester-${chip.at}-${chip.live}'),
          left: (chip.at.dx - 24).clamp(2.0, 300.0),
          top: chip.at.dy + 14,
          child: IgnorePointer(child: _TesterChip(live: chip.live)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6ChainLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d, geo),
            onPanUpdate: (d) => _panUpdate(d, geo),
            onPanEnd: (d) => _panEnd(geo, d.globalPosition),
          ),
        ),
      ),
      if (dragging)
        Positioned(
          key: const ValueKey('ppe-drag'),
          left: _dragNow.dx - 14,
          top: _dragNow.dy - 14,
          width: 28,
          height: 28,
          child: IgnorePointer(
            child: Icon(_drag == _Drag.ppe0 ? Icons.back_hand_rounded : Icons.visibility_rounded, color: _drag == _Drag.ppe0 ? const Color(0xFFC62828) : const Color(0xFF29B6F6), size: 26),
          ),
        ),
      // The docket board.
      Positioned.fromRect(
        key: ValueKey('docket-${_run.index}'),
        rect: M6ChainGeo.docket,
        child: ColorFiltered(
          colorFilter: grey,
          child: _DocketBoard(
            house: c.house,
            marks: _run.marks,
            chainOk: _run.chainOk,
            live: _run.stage == M6Stage.read,
            tierKeys: _tierKeys,
            chalkKey: _chalkKey,
            okKey: _okKey,
            onChalk: _chalk,
            onOk: _toggleOk,
            onGo: _goLook,
            onMiss: _hints.missTap,
          ),
        ),
      ),
      if (shown != null && !_freeze)
        Positioned.fromRect(
          key: ValueKey('card-$_cardTok'),
          rect: M6ChainGeo.card,
          child: IgnorePointer(
            child: CustomPaint(
              painter: M6CardPainter(
                card: shown,
                hgBlown: c.needsHg && !_run.hgRenewed ? c.hgPhase : -1,
                content: shown == M6Card.hrc ? (c.hrc ?? M6Content.blownHrc) : c.kitkat,
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
              builder: (_, v, _) => CustomPaint(painter: M6FlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // The next call: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
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
    final handsOn = playing && _run.stage != M6Stage.done && !deckUp && !coworkerOpen && _card == null;
    final beltUp = handsOn && _working;
    final trayUp = beltUp && _run.tray != M6Tray.none && _trayRow.isNotEmpty;
    final belt = _belt;
    final toolW = math.min(80.0, (size.width - 8) / belt.length);
    final trayW = _trayRow.isEmpty ? 60.0 : math.min(72.0, (size.width - 8) / _trayRow.length);
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
              labels: [for (final c in _run.deal.calls) M6ChainLines.docketHouse(c.house)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_callBusy,
            hintKey: '${_run.index}/${_run.stage.name}/$_steps/${_held?.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (trayUp)
                Positioned(
                  key: ValueKey('hud-tray-${_trayNow.name}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 84,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final s in _trayRow)
                        _SpareButton(
                          key: _spareKeys[s],
                          spare: s,
                          label: M6ChainLines.spare(s),
                          width: trayW,
                          onTap: (g) => _pickSpare(s, g),
                        ),
                    ],
                  ),
                ),
              if (beltUp)
                Positioned(
                  key: ValueKey('hud-belt-${_run.index}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in belt)
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: _icons[t]!,
                          label: M6ChainLines.tool(t),
                          width: toolW,
                          on: _held == t,
                          onTap: () => _tapTool(t),
                        ),
                    ],
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (trayUp ? 150 : 84)), onLeft: coworkerFromRight),
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
                  line: M6ChainLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 5, muted: _muted)),
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

  static const _icons = {
    M6Tool.tester: Icons.flash_on_rounded,
    M6Tool.puller: Icons.pan_tool_alt_rounded,
    M6Tool.pliers: Icons.content_cut_rounded,
    M6Tool.lockTag: Icons.lock_rounded,
    M6Tool.earth: Icons.link_rounded,
  };

  /// The trainee in insulating rubber gloves.
  static const _rubberGloved = LinemanLook(
    helmet: Color(0xFFFFD34E),
    shirt: Color(0xFF1F5F8F),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF26303D),
    skin: Color(0xFFA86E48),
    gloves: true,
    gloveColor: LinemanLook.rubberGloves,
  );
}

// ============================================================================
// Pieces
// ============================================================================

/// The docket: the call's house, the three guards from the bottom up (বাড়ি
/// → এলটি বক্স → HG), the chalk (drag it onto a guard; tap a ✗ to rub it
/// out), 'ক্রম ঠিক' and 'দেখতে যাই'.
class _DocketBoard extends StatefulWidget {
  const _DocketBoard({
    required this.house,
    required this.marks,
    required this.chainOk,
    required this.live,
    required this.tierKeys,
    required this.chalkKey,
    required this.okKey,
    required this.onChalk,
    required this.onOk,
    required this.onGo,
    required this.onMiss,
  });

  final int house;
  final Set<M6Tier> marks;
  final bool chainOk;
  final bool live;
  final Map<M6Tier, GlobalKey> tierKeys;
  final GlobalKey chalkKey;
  final GlobalKey okKey;
  final ValueChanged<M6Tier> onChalk;
  final VoidCallback onOk;
  final ValueChanged<Offset> onGo;
  final VoidCallback onMiss;

  @override
  State<_DocketBoard> createState() => _DocketBoardState();
}

class _DocketBoardState extends State<_DocketBoard> {
  Offset? _chalkAt;

  M6Tier? _tierAt(Offset p) {
    for (final t in M6Tier.values) {
      if (M6Docket.tier(t).contains(p)) return t;
    }
    return null;
  }

  void _tap(TapUpDetails d) {
    final p = d.localPosition;
    if (M6Docket.go.contains(p)) {
      widget.onGo(d.globalPosition);
      return;
    }
    if (M6Docket.chainOk.contains(p)) {
      widget.onOk();
      return;
    }
    final t = _tierAt(p);
    if (t != null && widget.marks.contains(t)) {
      // Rub a chalk mark out.
      widget.onChalk(t);
      return;
    }
    widget.onMiss();
  }

  @override
  Widget build(BuildContext context) {
    final at = _chalkAt;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: _tap,
      onPanStart: (d) {
        if (widget.live && M6Docket.chalk.inflate(4).contains(d.localPosition)) setState(() => _chalkAt = d.localPosition);
      },
      onPanUpdate: (d) {
        if (_chalkAt != null) setState(() => _chalkAt = d.localPosition);
      },
      onPanEnd: (_) {
        final p = _chalkAt;
        if (p == null) {
          widget.onMiss();
          return;
        }
        setState(() => _chalkAt = null);
        final t = _tierAt(p);
        if (t != null && !widget.marks.contains(t)) {
          widget.onChalk(t);
        } else {
          widget.onMiss();
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2E3B33),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8A6A3C), width: 3),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: M6Docket.head,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${M6ChainLines.docket} · ${M6ChainLines.docketHouse(widget.house)}',
                    style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFFF2EEDC))),
              ),
            ),
            for (final t in M6Tier.values)
              Positioned.fromRect(
                key: widget.tierKeys[t],
                rect: M6Docket.tier(t),
                child: KeyedSubtree(
                  key: ValueKey('tier-${t.name}'),
                  child: Semantics(
                    label: M6ChainLines.tier(t),
                    excludeSemantics: true,
                    child: _TierRow(tier: t, marked: widget.marks.contains(t)),
                  ),
                ),
              ),
            // The arrows of the fall order (from the bottom up).
            for (final y in const [53.0, 85.0])
              Positioned(left: 58, top: y, child: const IgnorePointer(child: Icon(Icons.arrow_upward_rounded, size: 9, color: Color(0xAAF2EEDC)))),
            Positioned.fromRect(
              key: widget.chalkKey,
              rect: M6Docket.chalk,
              child: Semantics(
                key: const ValueKey('docket-chalk'),
                label: M6ChainLines.chalk,
                excludeSemantics: true,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 11,
                    decoration: BoxDecoration(
                      color: at == null ? const Color(0xFFF7F4EA) : const Color(0x66F7F4EA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              key: widget.okKey,
              rect: M6Docket.chainOk,
              child: Semantics(
                button: true,
                label: M6ChainLines.chainOk,
                excludeSemantics: true,
                child: _DocketButton(text: M6ChainLines.chainOk, on: widget.chainOk, icon: widget.chainOk ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded),
              ),
            ),
            Positioned.fromRect(
              rect: M6Docket.go,
              child: Semantics(
                button: true,
                label: M6ChainLines.goLook,
                excludeSemantics: true,
                child: _DocketButton(text: M6ChainLines.goLook, on: false, filled: widget.live),
              ),
            ),
            if (at != null)
              Positioned(
                left: at.dx - 14,
                top: at.dy - 6,
                child: IgnorePointer(
                  child: Container(width: 28, height: 11, decoration: BoxDecoration(color: const Color(0xFFF7F4EA), borderRadius: BorderRadius.circular(4))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({required this.tier, required this.marked});
  final M6Tier tier;
  final bool marked;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _ChalkCross(marked),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x88F2EEDC), width: 1.2),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Icon(
              switch (tier) {
                M6Tier.house => Icons.home_rounded,
                M6Tier.lt => Icons.view_column_rounded,
                M6Tier.hg => Icons.bolt_rounded,
              },
              size: 15,
              color: const Color(0xFFF2EEDC),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(M6ChainLines.tier(tier), style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFF2EEDC))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChalkCross extends CustomPainter {
  const _ChalkCross(this.on);
  final bool on;

  @override
  void paint(Canvas c, Size size) {
    if (!on) return;
    final p = Paint()
      ..color = const Color(0xFFF7F4EA)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final cx = size.width - 18;
    final cy = size.height / 2;
    c.drawLine(Offset(cx - 9, cy - 9), Offset(cx + 9, cy + 9), p);
    c.drawLine(Offset(cx + 9, cy - 9), Offset(cx - 9, cy + 9), p);
  }

  @override
  bool shouldRepaint(_ChalkCross old) => old.on != on;
}

class _DocketButton extends StatelessWidget {
  const _DocketButton({required this.text, required this.on, this.icon, this.filled = false});
  final String text;
  final bool on;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF1C2E4A) : (on ? const Color(0xFF1F4A33) : const Color(0x22000000)),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: filled ? SlmColors.gold300 : const Color(0x88F2EEDC), width: 1.4),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 13, color: const Color(0xFFF2EEDC)), const SizedBox(width: 3)],
              Text(text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: live ? const Color(0xFFFF3B30) : const Color(0xFF3A3F45),
              boxShadow: live ? const [BoxShadow(color: Color(0xAAFF3B30), blurRadius: 8)] : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(live ? M6ChainLines.testerLive : M6ChainLines.testerDead, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

/// A spare (or the scrap pile) in the tray: a reel, an HRC cartridge, the
/// scrap bin, with its label.
class _SpareButton extends StatelessWidget {
  const _SpareButton({super.key, required this.spare, required this.label, required this.width, required this.onTap});
  final M6Spare spare;
  final String label;
  final double width;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (spare) {
      M6Spare.scrap => Icons.delete_outline_rounded,
      M6Spare.hrc => Icons.battery_full_rounded,
      _ => Icons.radio_button_checked_rounded,
    };
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: math.min(46.0, width - 4),
                height: math.min(46.0, width - 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3A2E22),
                  border: Border.all(color: const Color(0xFFD9B26A), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 22, color: const Color(0xFFE8C98A)),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, softWrap: false, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A belt tool: a round icon with its name; lit while in hand.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap, this.width = 80});
  final IconData icon;
  final String label;
  final double width;
  final bool on;
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
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: math.min(48.0, width - 4),
                height: math.min(48.0, width - 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
