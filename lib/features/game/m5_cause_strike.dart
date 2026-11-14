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
import 'm5_cause_strike_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_cause_strike_world.dart' show M5LeakSource, M5Place;

// Lesson 5.8 "ট্রান্সফরমারের সাধারণ সমস্যা: হৃৎপিণ্ডের রোগ নির্ণয়", কাজ 1
// "লক্ষণ থেকে কারণ" (pack do_5_8_a, engineType m5_cause_strike). A day's
// round of three sick DP transformers (a field edge, a market, a school
// road — dealt), one docket complaint each, in dealt order:
//
//  শব্দ করছে (5.8 point 2): hold the ear button — a steady hum is normal; a
//    loud, irregular noise needs the load check (tong tester on the LT
//    cable: always inside the nameplate mark) → strike 'ওভারলোড' → listen
//    again (the noise has not stopped) → the list closed → 'সুপারভাইজারকে
//    রিপোর্ট'.
//  এক ফেজে বিদ্যুৎ নেই (point 4): meter each phase at the LT box on the
//    transformer as found (the lever stays ON until all three are read; off,
//    every dial reads 0); swipe up to see every DO barrel in → strike 'HT
//    ফিউজ উড়েছে'; switch off (LT lever OFF, hot stick opens each DO), the
//    tester on the LT bushing shows 0 V;
//    the spanner on the dead phase's terminal: loose → 'কানেকশন টাইট করে
//    চালু'; firm → strike 'বুশিং-এর কানেকশন' → 'ট্রান্সফরমার বদলাতে হবে'.
//  তেল পড়ছে (point 3): trace the fresh stain up to its source (gasket line,
//    weld seam, dent — old dry stains are decoys) → strike the two causes that
//    do not match; the oil gauge and a 5 s drip watch → 'নজরে রাখুন' (small,
//    level fine) or 'বন্ধ করে লিক সারান, তেল টপ-আপ' (large).
//
// The loop is elimination on a written suspect list: strike (swipe across) a
// cause only when a test has ruled it out; 'তালিকা শেষ' only with the
// evidence in and every ruled-out cause struck; then the verdict card.
//
// Deadly (module 5 table, rulings M5-2): a spanner on the LT bushing with any
// DO closed or the LT on (R2/3.6b); on it after the DOs are open but before
// the tester shows 0 V (R2, raised from slip); climbing the live platform on
// the coworker's word (R19). Slips: a cause struck that no test ruled out;
// 'তালিকা শেষ' with a ruled-out cause standing; a verdict before its
// evidence (e.g. internal before the load check); a wrong verdict card
// (loud called normal, a steady hum reported…); a DO opened on load (module
// rule, flagged); listening to a slip-line coworker. Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m5_cause_strike_world.dart), corner guide, a right strike puts
// ◆ in at once, a right verdict puts ◆ on the table → "কেন …?" → the next
// case; the careless coworker once a play at a state gate of one case (his
// line fits the moment; the next control waits for him: holdForCoworker).
// Gesture hands: the ear's hold ring, a stroke up from the stains, a swipe
// up the structure, a strike demo on the clipboard's empty line, sweeps over
// every tool / target alike — never the answer; 'তালিকা শেষ' is never hinted.

// ============================================================================
// Content
// ============================================================================

/// The three patients' complaints.
enum M5CaseKind { noise, ltDead, leak }

/// The causes on the suspects lists (lesson 5.8 points 2–4).
enum M5Cause { looseInside, lamination, windingShort, overload, htFuse, ltWinding, bushingConn, gasket, weld, impact }

/// The hands-on tools.
enum M5Tool { ear, tong, meter, hotStick, tester, spanner, watch }

/// The verdicts.
enum M5Verdict { normal, report, tighten, replace, watch, repair }

/// The coworker's push (one per play). [humLate] is never dealt: it stands in
/// for [hum] when the load was checked before the noise was heard (his
/// "it's only hum" no longer fits that moment).
enum M5Push { hum, live, climb, small, humLate }

/// What the case's reason asks about.
enum M5WhyTopic { hum, overload, report, switchOff, tighten, replace, twoStruck, watch, repair }

const m5CaseCauses = <M5CaseKind, List<M5Cause>>{
  M5CaseKind.noise: [M5Cause.looseInside, M5Cause.lamination, M5Cause.windingShort, M5Cause.overload],
  M5CaseKind.ltDead: [M5Cause.htFuse, M5Cause.ltWinding, M5Cause.bushingConn],
  M5CaseKind.leak: [M5Cause.gasket, M5Cause.weld, M5Cause.impact],
};

M5Cause m5CauseOf(M5LeakSource s) => switch (s) {
      M5LeakSource.gasket => M5Cause.gasket,
      M5LeakSource.weld => M5Cause.weld,
      M5LeakSource.dent => M5Cause.impact,
    };

/// The lesson point (0-based) that teaches a case.
int m5LessonPoint(M5CaseKind k) => switch (k) {
      M5CaseKind.noise => 1,
      M5CaseKind.ltDead => 3,
      M5CaseKind.leak => 2,
    };

abstract final class M5CauseStrikeLines {
  static const title = 'লক্ষণ থেকে কারণ';
  static const intro = 'আজ তিনটে অসুস্থ ট্রান্সফরমার! লক্ষণ মিলিয়ে কারণ বের করুন।';
  static const rule = 'যে কারণ পরীক্ষায় বাদ গেছে, শুধু সেটাই কাটুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askNoise = 'অভিযোগ: শব্দ করছে। পরীক্ষা করে কারণ খুঁজুন।';
  static const askLtDead = 'অভিযোগ: এক ফেজে বিদ্যুৎ নেই। পরীক্ষা করে কারণ খুঁজুন।';
  static const askLeak = 'অভিযোগ: তেল পড়ছে। পরীক্ষা করে কারণ খুঁজুন।';
  static const askVerdict = 'এখন কী করবেন?';
  static const tasks = [askNoise, askLtDead, askLeak, askVerdict];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const oldStain = 'এ দাগ শুকনো, পুরনো।';
  static const meterFirst = 'বন্ধ করার আগে চালু অবস্থায় তিন ফেজই মেপে দেখুন।';

  static String ask(M5CaseKind k) => switch (k) {
        M5CaseKind.noise => askNoise,
        M5CaseKind.ltDead => askLtDead,
        M5CaseKind.leak => askLeak,
      };

  // The clipboard (a worker's own words).
  static const clipTitle = 'সন্দেহের তালিকা';
  static const listDone = 'তালিকা শেষ';
  static const sceneLabel = 'ডিপি ট্রান্সফরমার';
  static String complaint(M5CaseKind k) => switch (k) {
        M5CaseKind.noise => 'শব্দ করছে',
        M5CaseKind.ltDead => 'এক ফেজে বিদ্যুৎ নেই',
        M5CaseKind.leak => 'তেল পড়ছে',
      };
  static String round(M5CaseKind k) => switch (k) {
        M5CaseKind.noise => 'শব্দ',
        M5CaseKind.ltDead => 'এক ফেজ',
        M5CaseKind.leak => 'তেল',
      };
  static String cause(M5Cause c) => switch (c) {
        M5Cause.looseInside => 'ভেতরের কানেকশন লুজ',
        M5Cause.lamination => 'কোরের ল্যামিনেশন আলগা',
        M5Cause.windingShort => 'ওয়াইন্ডিং-এ শর্ট শুরু',
        M5Cause.overload => 'ওভারলোড',
        M5Cause.htFuse => 'HT ফিউজ উড়েছে',
        M5Cause.ltWinding => 'এলটি ওয়াইন্ডিং পোড়া/কাটা',
        M5Cause.bushingConn => 'বুশিং-এর কানেকশন খোলা',
        M5Cause.gasket => 'গ্যাসকেট পুরনো',
        M5Cause.weld => 'ওয়েল্ডিং জয়েন্টে ফাটল',
        M5Cause.impact => 'যান্ত্রিক আঘাত',
      };

  // The tools.
  static String tool(M5Tool t) => switch (t) {
        M5Tool.ear => 'কান পাতুন',
        M5Tool.tong => 'টং টেস্টার',
        M5Tool.meter => 'মিটার',
        M5Tool.hotStick => 'হট স্টিক',
        M5Tool.tester => 'টেস্টার',
        M5Tool.spanner => 'স্প্যানার',
        M5Tool.watch => 'ঘড়ি',
      };
  static const testerDead = '0 V';
  static const nutLoose = 'নাট ঢিলা';
  static const nutFirm = 'নাট টাইট';

  // The verdict cards: right per verdict (two ways), wrong per case (the
  // case's other verdict + field shortcuts). 23–29 letters.
  static const verdictRight = <M5Verdict, List<String>>{
    M5Verdict.normal: ['স্বাভাবিক হামিং — চলতে দিন', 'শব্দ স্বাভাবিক, কিছু করার নেই'],
    M5Verdict.report: ['সুপারভাইজারকে রিপোর্ট করুন', 'ভেতরের রোগ — রিপোর্ট করুন'],
    M5Verdict.tighten: ['কানেকশন টাইট করে চালু করুন', 'ঢিলা কানেকশন টাইট দিয়ে চালু'],
    M5Verdict.replace: ['ট্রান্সফরমার বদলাতে হবে', 'ভেতরের ফল্ট — বদলাতে হবে'],
    M5Verdict.watch: ['নজরে রাখুন, নিয়মিত দেখুন', 'পর্যবেক্ষণে রাখুন, চলতে দিন'],
    M5Verdict.repair: ['বন্ধ করে লিক সারান, তেল টপ-আপ', 'বন্ধ করে মেরামত, তেল ভরে দিন'],
  };
  static const _shortcuts = <M5CaseKind, List<String>>{
    M5CaseKind.noise: ['ওভারলোড — লোড কমিয়ে দিন', 'বারবার চার্জ করে দেখে নিন', 'চালু রেখেই নাট টাইট দিন'],
    M5CaseKind.ltDead: ['HT ফিউজ বদলে আবার চালু করুন', 'আবার চার্জ করে দেখে নিন', 'এক ফেজ ছাড়াই চালু রাখুন'],
    M5CaseKind.leak: ['তেল মুছে দিন, ও কিছু না', 'চালু রেখেই ওপরে উঠে সারান', 'লিকের জায়গায় মাটি লেপে দিন'],
  };
  static const _pairs = <M5Verdict, M5Verdict>{
    M5Verdict.normal: M5Verdict.report,
    M5Verdict.report: M5Verdict.normal,
    M5Verdict.tighten: M5Verdict.replace,
    M5Verdict.replace: M5Verdict.tighten,
    M5Verdict.watch: M5Verdict.repair,
    M5Verdict.repair: M5Verdict.watch,
  };
  static M5CaseKind kindOf(M5Verdict v) => switch (v) {
        M5Verdict.normal || M5Verdict.report => M5CaseKind.noise,
        M5Verdict.tighten || M5Verdict.replace => M5CaseKind.ltDead,
        M5Verdict.watch || M5Verdict.repair => M5CaseKind.leak,
      };
  static List<String> verdictWrong(M5Verdict v) => [...verdictRight[_pairs[v]]!, ..._shortcuts[kindOf(v)]!];
  static List<String> get allVerdicts => [for (final l in verdictRight.values) ...l, for (final l in _shortcuts.values) ...l];

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses. 37–46 letters.
  static const whyQ = <M5WhyTopic, String>{
    M5WhyTopic.hum: 'কেন শব্দটাকে স্বাভাবিক বললেন?',
    M5WhyTopic.overload: "কেন 'ওভারলোড' কেটে দিলেন?",
    M5WhyTopic.report: 'কেন সুপারভাইজারকে রিপোর্ট করলেন?',
    M5WhyTopic.switchOff: 'কেন হাত দেওয়ার আগে ট্রান্সফরমার বন্ধ করলেন?',
    M5WhyTopic.tighten: 'কেন কানেকশন টাইট করে চালু করতে বললেন?',
    M5WhyTopic.replace: 'কেন ট্রান্সফরমার বদলাতে বললেন?',
    M5WhyTopic.twoStruck: 'কেন এই দুটো কারণ কেটে দিলেন?',
    M5WhyTopic.watch: 'কেন নজরে রাখতে বললেন?',
    M5WhyTopic.repair: 'কেন বন্ধ করে লিক সারাতে বললেন?',
  };
  static const whyRight = <M5WhyTopic, List<String>>{
    M5WhyTopic.hum: ['একটানা মৃদু হামিং — এটাই স্বাভাবিক ভাষা', 'জোরালো বা অনিয়মিত নয় — এই শব্দ স্বাভাবিক'],
    M5WhyTopic.overload: ['টং টেস্টারে লোড দাগের ভেতরে, তাই ওভারলোড নয়', 'লোড স্বাভাবিক পেলাম, তাই ওভারলোড বাদ গেল'],
    M5WhyTopic.report: ['লোড স্বাভাবিক, তবু শব্দ থামেনি — ভেতরের সমস্যা', 'লোড ঠিক থেকেও জোরালো শব্দ ভেতরের রোগের লক্ষণ'],
    M5WhyTopic.switchOff: ['বন্ধ করে টেস্টারে 0 V দেখে তবেই বুশিং-এ হাত', 'চালু বুশিং-এ স্প্যানার মানেই প্রাণঘাতী শক'],
    M5WhyTopic.tighten: ['মৃত ফেজের বুশিং-এর কানেকশনই ঢিলা পেলাম', 'কানেকশন ঢিলা ছিল — টাইট দিলেই ফেজ ফিরবে'],
    M5WhyTopic.replace: ['বুশিং-এর কানেকশন ঠিক, তাই সমস্যা ভেতরের', 'কানেকশন টাইট থেকেও ফেজ নেই — ভেতরের ফল্ট'],
    M5WhyTopic.twoStruck: ['লিকের উৎস দেখলাম — বাকি দুটো কারণ মেলে না', 'দাগ ধরে উৎসে পৌঁছে বাকি দুটো বাদ দিলাম'],
    M5WhyTopic.watch: ['লিক সামান্য, আর তেলের লেভেলও ঠিক জায়গায়', 'সামান্য লিক, লেভেল ঠিক — তাই পর্যবেক্ষণ'],
    M5WhyTopic.repair: ['লিক বেশি — বন্ধ করে সারিয়ে তেল টপ-আপ চাই', 'বেশি লিকে তেল কমে, ভেতরে আর্দ্রতাও ঢোকে'],
  };
  static const myths = [
    'হামিং তো সব ট্রান্সফরমারই করে, ভাবনা নেই',
    'সামান্য তেল পড়া তো স্বাভাবিক, ও কিছু না',
    'চালু অবস্থাতেই বুশিং-এর নাট টাইট দেওয়া চলে',
    'আন্দাজেই কারণ কাটা যায়, পরীক্ষা লাগে না',
    'তেলের ভেতরে একটু জল ঢুকলে কিছু হয় না',
    'এলটি ফল্টে ট্রান্সফরমারের কিছু হয় না',
    'বারবার চার্জ করলে ফল্ট পুড়ে সরে যায়',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play, at a state gate of one case).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLive = CoworkerScript(
    line: 'চালু অবস্থাতেই বুশিং-এর নাটটা টাইট করে দাও, বন্ধ করার ঝামেলা কে করে?',
    exitLine: coworkerExit,
    right: ['না, আগে বন্ধ করে টেস্টারে 0 V দেখব', 'না, চালু বুশিং-এ স্প্যানার দেব না', 'না, বন্ধ না করে বুশিং-এ হাত নয়'],
    wrong: [
      'ঠিক, চালু রেখেই নাটটা টাইট দিই',
      'আচ্ছা, এক মিনিটের কাজ, চালুতেই সারি',
      'হ্যাঁ, বন্ধ করার ঝামেলা কে করে',
      'ঠিক আছে, গ্লাভস আছে, চালুতেই দিই',
      'হ্যাঁ, এক ফেজ তো মরা, ভয় নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে চালু অবস্থাতেই নাট টাইট দিতে। কী করবেন?', 'চালু ট্রান্সফরমারে স্প্যানার দেবেন?'],
  );
  static const coworkerClimb = CoworkerScript(
    line: 'ওপরে উঠে আঙুল দিয়ে দেখো কোথা দিয়ে পড়ছে, বন্ধ করার দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, চালু ট্রান্সফরমারে উঠব না', 'না, নিচ থেকেই উৎস খুঁজে নেব', 'না, বন্ধ না করে প্ল্যাটফর্মে নয়'],
    wrong: [
      'ঠিক, উঠে আঙুল দিয়ে দেখে নিই',
      'আচ্ছা, একটু উঠে দেখলে ক্ষতি নেই',
      'হ্যাঁ, বন্ধ করার দরকার নেই',
      'ঠিক আছে, তাড়াতাড়ি উঠে দেখি',
      'হ্যাঁ, কাছ থেকে দেখাই ভালো',
    ],
    asks: ['কী করবেন?', 'ও বলছে চালু অবস্থায় উঠে দেখতে। কী করবেন?', 'চালু প্ল্যাটফর্মে উঠবেন?'],
  );
  static const coworkerSmall = CoworkerScript(
    line: 'সামান্য তেল পড়ছে, ও কিছু না — চলতে দাও।',
    exitLine: coworkerExit,
    right: ['না, লিক বেশি — বন্ধ করে সারাতে হবে', 'না, তেল কমছে, এভাবে চলতে দেব না', 'না, বেশি লিক মানে বন্ধ করে মেরামত'],
    wrong: [
      'আচ্ছা, একটু তেল তো পড়েই থাকে',
      'ঠিক, ও কিছু না, চলতে দিই তাহলে',
      'হ্যাঁ, একটু তেল পড়লে কী আর হয়',
      'হ্যাঁ, পরে কোনো দিন দেখা যাবে',
      'ঠিক আছে, মাটি দিয়ে দাগ ঢেকে দিই',
    ],
    asks: ['কী করবেন?', 'ও বলছে লিক ও কিছু না। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerHum = CoworkerScript(
    line: 'হামিং তো সব ট্রান্সফরমারই করে, চলতে দাও।',
    exitLine: coworkerExit,
    right: ['না, আগে টং টেস্টারে লোড দেখব', 'না, এ শব্দ জোরালো, স্বাভাবিক নয়', 'না, অনিয়মিত শব্দ মানে বিপদ'],
    wrong: [
      'ঠিক, হামিং তো সব ট্রান্সফরমার করে',
      'হ্যাঁ, শব্দে আর কী এমন হয়',
      'হ্যাঁ, একটু শব্দ তো সবারই হয়',
      'ঠিক আছে, রিপোর্টের দরকার নেই',
      'আচ্ছা, চলতে দিই, পরে দেখা যাবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে চলতে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  // The load was checked before the noise was heard: he comes after the
  // second listen, when the load is known to be normal.
  static const coworkerHumLate = CoworkerScript(
    line: 'লোড তো ঠিকই আছে, শব্দ-টব্দ চলতে দাও, রিপোর্টের দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, লোড ঠিক, তবু শব্দ — রিপোর্ট করব', 'না, শব্দ থামেনি, এটা ভেতরের রোগ', 'না, ভেতরের সমস্যা, রিপোর্ট করতে হবে'],
    wrong: [
      'ঠিক, লোড তো ঠিক আছে, চলতে দিই',
      'হ্যাঁ, রিপোর্টের ঝামেলা কে করে',
      'আচ্ছা, শব্দ একটু হলে কী আর হয়',
      'ঠিক আছে, পরে কোনো দিন দেখা যাবে',
      'হ্যাঁ, লোড ঠিক মানেই তো সব ঠিক',
    ],
    asks: ['কী করবেন?', 'ও বলছে রিপোর্টের দরকার নেই। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M5Push p) => switch (p) {
        M5Push.hum => coworkerHum,
        M5Push.humLate => coworkerHumLate,
        M5Push.live => coworkerLive,
        M5Push.climb => coworkerClimb,
        M5Push.small => coworkerSmall,
      };
  static const allCoworkers = [coworkerHum, coworkerLive, coworkerClimb, coworkerSmall, coworkerHumLate];

  static String callHeld(M5Push p) => switch (p) {
        M5Push.hum => 'ঠিক! জোরালো শব্দ মানেই আগে লোড পরীক্ষা।',
        M5Push.humLate => 'ঠিক! লোড স্বাভাবিক, তবু শব্দ — রিপোর্ট।',
        M5Push.live => 'ঠিক! আগে বন্ধ, টেস্টারে 0 V — তারপর হাত।',
        M5Push.climb => 'ঠিক! চালু ট্রান্সফরমারে ওঠা নয়।',
        M5Push.small => 'ঠিক! বেশি লিকে বন্ধ করে মেরামত।',
      };

  static const allSet = 'তিন রোগীরই ঠিক রোগ নির্ণয় — পরীক্ষা করে, তবে কাটা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে পরীক্ষা, তারপর কারণ কাটা, তারপর রায়।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtHum = 'স্বাভাবিক হামিং চিনেছেন';
  static const caughtReport = 'লোড স্বাভাবিক, তবু শব্দ — রিপোর্ট';
  static const caughtOff = 'বন্ধ করে 0 V দেখে তবে স্প্যানার';
  static const caughtLeak = 'দাগ ধরে লিকের উৎস ও পরিমাণ';
  static const caughtStrike = 'শুধু পরীক্ষায় বাদ পড়া কারণ কেটেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';
}

abstract final class M5CauseStrikeMistakes {
  static const _dir = 'assets/game/art/m5_cause_strike';

  static const strikeNoise = DoMistake(
    key: '5.8/m5_cause_strike/strike-noise',
    textBn: 'পরীক্ষায় বাদ না গেলে কারণ কাটবেন না। শব্দের বেলায় লোড পরীক্ষাই শুধু ওভারলোডকে বাদ দেয়।',
    art: '$_dir/strike.svg',
    lessonPoint: 1,
  );
  static const strikeLt = DoMistake(
    key: '5.8/m5_cause_strike/strike-lt',
    textBn: 'পরীক্ষায় বাদ না গেলে কারণ কাটবেন না। ডিও দেখে HT ফিউজ, স্প্যানারে বুশিং-এর কানেকশন — তবেই কাটা।',
    art: '$_dir/strike.svg',
    lessonPoint: 3,
  );
  static const strikeLeak = DoMistake(
    key: '5.8/m5_cause_strike/strike-leak',
    textBn: 'পরীক্ষায় বাদ না গেলে কারণ কাটবেন না। আগে দাগ ধরে লিকের উৎস দেখুন, তারপর না মেলা কারণ কাটুন।',
    art: '$_dir/strike.svg',
    lessonPoint: 2,
  );
  static const openNoise = DoMistake(
    key: '5.8/m5_cause_strike/open-noise',
    textBn: 'লোড স্বাভাবিক পেয়েছেন — তবু ওভারলোড তালিকায়! বাদ পড়া কারণ কেটে তবে তালিকা শেষ।',
    art: '$_dir/list_open.svg',
    lessonPoint: 1,
  );
  static const openLt = DoMistake(
    key: '5.8/m5_cause_strike/open-lt',
    textBn: 'পরীক্ষায় বাদ পড়া কারণ এখনও তালিকায়। সেটা কেটে তবে তালিকা শেষ করুন।',
    art: '$_dir/list_open.svg',
    lessonPoint: 3,
  );
  static const openLeak = DoMistake(
    key: '5.8/m5_cause_strike/open-leak',
    textBn: 'লিকের উৎস দেখেছেন — না মেলা দুটো কারণ কেটে তবে তালিকা শেষ করুন।',
    art: '$_dir/list_open.svg',
    lessonPoint: 2,
  );
  static const evidenceNoise = DoMistake(
    key: '5.8/m5_cause_strike/evidence-noise',
    textBn: 'রায়ের আগে পরীক্ষা: কান পেতে শুনুন; জোরালো শব্দ হলে লোড পরীক্ষা, তারপর আবার শুনুন — শব্দ না থামলে তবেই ভেতরের সমস্যা।',
    art: '$_dir/evidence.svg',
    lessonPoint: 1,
  );
  static const evidenceLt = DoMistake(
    key: '5.8/m5_cause_strike/evidence-lt',
    textBn: 'রায়ের আগে পরীক্ষা: প্রতি ফেজে মিটার, ডিও দেখা, তারপর বন্ধ করে মৃত ফেজের বুশিং কানেকশন।',
    art: '$_dir/evidence.svg',
    lessonPoint: 3,
  );
  static const evidenceLeak = DoMistake(
    key: '5.8/m5_cause_strike/evidence-leak',
    textBn: 'রায়ের আগে লিকের উৎস আর পরিমাণ: দাগ ধরে উৎস, তেলের গেজ, আর কতটা পড়ছে দেখা।',
    art: '$_dir/evidence.svg',
    lessonPoint: 2,
  );
  static const verdictLoud = DoMistake(
    key: '5.8/m5_cause_strike/verdict-loud',
    textBn: 'জোরালো, অনিয়মিত শব্দ স্বাভাবিক নয়। লোড স্বাভাবিক থেকেও শব্দ না থামলে — সুপারভাইজারকে রিপোর্ট।',
    art: '$_dir/noise.svg',
    lessonPoint: 1,
  );
  static const verdictHum = DoMistake(
    key: '5.8/m5_cause_strike/verdict-hum',
    textBn: 'একটানা মৃদু হামিং ট্রান্সফরমারের স্বাভাবিক শব্দ — এর জন্য রিপোর্ট বা মেরামত লাগে না।',
    art: '$_dir/noise.svg',
    lessonPoint: 1,
  );
  static const verdictLt = DoMistake(
    key: '5.8/m5_cause_strike/verdict-lt',
    textBn: 'কানেকশন ঢিলা হলে টাইট করে চালু; কানেকশন ঠিক থাকলে সমস্যা ভেতরের — ট্রান্সফরমার বদলাতে হবে।',
    art: '$_dir/lt_verdict.svg',
    lessonPoint: 3,
  );
  static const verdictLeak = DoMistake(
    key: '5.8/m5_cause_strike/verdict-leak',
    textBn: 'লিক সামান্য আর তেলের লেভেল ঠিক — নজরে রাখুন। লিক বেশি — বন্ধ করে লিক সারান, তেল টপ-আপ।',
    art: '$_dir/leak.svg',
    lessonPoint: 2,
  );
  // The module's switching rule (lesson 5.4's "সমস্ত আউটগোয়িং" before the
  // DO; not lesson 5.8's text): no lesson point.
  static const doOnLoad = DoMistake(
    key: '5.8/m5_cause_strike/do-on-load',
    textBn: 'আগে এলটি সুইচ বন্ধ করে লোড নামান, তারপর হট স্টিকে ডিও খুলুন।',
    art: '$_dir/do_on_load.svg',
  );
  static const liveSpanner = DoMistake(
    key: '5.8/m5_cause_strike/live-spanner',
    textBn: 'চালু ট্রান্সফরমারের বুশিং-এ স্প্যানার নয়! আগে এলটি বন্ধ, সব ডিও খোলা, টেস্টারে 0 V — তবেই হাত।',
    art: '$_dir/live_spanner.svg',
    deadly: true,
    lessonPoint: 3,
  );
  // Module 5 table R2 (M1 step 18): no lesson point.
  static const untested = DoMistake(
    key: '5.8/m5_cause_strike/untested',
    textBn: 'ডিও খোলা মানেই মৃত নয়! টেস্টারে 0 V না দেখে বুশিং-এ হাত বা স্প্যানার নয়।',
    art: '$_dir/untested.svg',
    deadly: true,
  );
  // Module 5 table R19 (3.2, 3.6): no lesson point.
  static const climbLive = DoMistake(
    key: '5.8/m5_cause_strike/climb-live',
    textBn: 'চালু ট্রান্সফরমারের প্ল্যাটফর্মে ওঠা নয়! লিকের উৎস নিচ থেকে খুঁজুন; কাছে যেতে হলে আগে বন্ধ, টেস্ট, আর্থ।',
    art: '$_dir/climb_live.svg',
    deadly: true,
  );
  static const pushHum = DoMistake(
    key: '5.8/m5_cause_strike/push-hum',
    textBn: 'জোরালো শব্দকে “হামিং” বলে চালিয়ে দেওয়া নয় — শব্দ হলো ট্রান্সফরমারের ভাষা। আগে লোড পরীক্ষা।',
    art: '$_dir/noise.svg',
    lessonPoint: 1,
  );
  static const pushReport = DoMistake(
    key: '5.8/m5_cause_strike/push-report',
    textBn: 'লোড স্বাভাবিক থেকেও জোরালো শব্দ না থামলে সমস্যা ভেতরের — চলতে না দিয়ে সুপারভাইজারকে রিপোর্ট।',
    art: '$_dir/noise.svg',
    lessonPoint: 1,
  );
  static const pushSmall = DoMistake(
    key: '5.8/m5_cause_strike/push-small',
    textBn: 'বেশি লিক “ও কিছু না” নয় — লিকের পথে আর্দ্রতা ঢোকে। বন্ধ করে লিক সারান, তেল টপ-আপ।',
    art: '$_dir/leak.svg',
    lessonPoint: 2,
  );

  static DoMistake strikeEarly(M5CaseKind k) => switch (k) {
        M5CaseKind.noise => strikeNoise,
        M5CaseKind.ltDead => strikeLt,
        M5CaseKind.leak => strikeLeak,
      };
  static DoMistake listOpen(M5CaseKind k) => switch (k) {
        M5CaseKind.noise => openNoise,
        M5CaseKind.ltDead => openLt,
        M5CaseKind.leak => openLeak,
      };
  static DoMistake evidenceFirst(M5CaseKind k) => switch (k) {
        M5CaseKind.noise => evidenceNoise,
        M5CaseKind.ltDead => evidenceLt,
        M5CaseKind.leak => evidenceLeak,
      };
  static DoMistake wrongVerdict(M5Case c) => switch (c.kind) {
        M5CaseKind.noise => c.loud ? verdictLoud : verdictHum,
        M5CaseKind.ltDead => verdictLt,
        M5CaseKind.leak => verdictLeak,
      };
  static DoMistake push(M5Push p) => switch (p) {
        M5Push.hum => pushHum,
        M5Push.humLate => pushReport,
        M5Push.live => liveSpanner,
        M5Push.climb => climbLive,
        M5Push.small => pushSmall,
      };

  static const List<DoMistake> all = [
    strikeNoise,
    strikeLt,
    strikeLeak,
    openNoise,
    openLt,
    openLeak,
    evidenceNoise,
    evidenceLt,
    evidenceLeak,
    verdictLoud,
    verdictHum,
    verdictLt,
    verdictLeak,
    doOnLoad,
    liveSpanner,
    untested,
    climbLive,
    pushHum,
    pushReport,
    pushSmall,
  ];
}

/// One patient.
@immutable
class M5Case {
  const M5Case({
    required this.kind,
    required this.place,
    required this.suspects,
    this.loud = false,
    this.deadPhase = 0,
    this.loose = false,
    this.source = M5LeakSource.gasket,
    this.freshStain = 0,
    this.large = false,
    this.gaugeLow = false,
  });

  final M5CaseKind kind;
  final M5Place place;

  /// The causes on the clipboard, in dealt order.
  final List<M5Cause> suspects;

  /// শব্দ: loud and irregular (else a steady hum).
  final bool loud;

  /// এক ফেজ নেই: the dead phase (0 R, 1 Y, 2 B); its terminal loose or firm.
  final int deadPhase;
  final bool loose;

  /// তেল: where from, which stain is fresh, how much, the gauge low.
  final M5LeakSource source;
  final int freshStain;
  final bool large;
  final bool gaugeLow;

  M5Verdict get verdict => switch (kind) {
        M5CaseKind.noise => loud ? M5Verdict.report : M5Verdict.normal,
        M5CaseKind.ltDead => loose ? M5Verdict.tighten : M5Verdict.replace,
        M5CaseKind.leak => large ? M5Verdict.repair : M5Verdict.watch,
      };
}

@immutable
class M5CauseDeal {
  const M5CauseDeal({required this.cases, required this.coworkerCase, required this.push, required this.why});

  /// The three patients in visiting order (one of each kind).
  final List<M5Case> cases;

  /// The case the coworker comes in, and his push.
  final int coworkerCase;
  final M5Push push;

  /// What each case's reason asks about (fits the case).
  final List<M5WhyTopic> why;
}

/// The pushes that fit a case (his line must fit the moment).
List<M5Push> m5PushesFor(M5Case c) => switch (c.kind) {
      M5CaseKind.noise => [if (c.loud) M5Push.hum],
      M5CaseKind.ltDead => const [M5Push.live],
      M5CaseKind.leak => [M5Push.climb, if (c.large) M5Push.small],
    };

M5CauseDeal m5CauseDeal(math.Random rng) {
  final kinds = [...M5CaseKind.values]..shuffle(rng);
  final places = [...M5Place.values]..shuffle(rng);
  final cases = <M5Case>[];
  final why = <M5WhyTopic>[];
  for (final (i, k) in kinds.indexed) {
    final suspects = [...m5CaseCauses[k]!]..shuffle(rng);
    switch (k) {
      case M5CaseKind.noise:
        final loud = rng.nextBool();
        cases.add(M5Case(kind: k, place: places[i], suspects: suspects, loud: loud));
        why.add(loud ? (rng.nextBool() ? M5WhyTopic.overload : M5WhyTopic.report) : M5WhyTopic.hum);
      case M5CaseKind.ltDead:
        final loose = rng.nextBool();
        cases.add(M5Case(kind: k, place: places[i], suspects: suspects, deadPhase: rng.nextInt(3), loose: loose));
        why.add(rng.nextBool() ? M5WhyTopic.switchOff : (loose ? M5WhyTopic.tighten : M5WhyTopic.replace));
      case M5CaseKind.leak:
        final large = rng.nextBool();
        cases.add(M5Case(
          kind: k,
          place: places[i],
          suspects: suspects,
          source: M5LeakSource.values[rng.nextInt(3)],
          freshStain: rng.nextInt(3),
          large: large,
          gaugeLow: large && rng.nextBool(),
        ));
        why.add(rng.nextBool() ? M5WhyTopic.twoStruck : (large ? M5WhyTopic.repair : M5WhyTopic.watch));
    }
  }
  final able = [for (var i = 0; i < 3; i++) if (m5PushesFor(cases[i]).isNotEmpty) i];
  final at = able[rng.nextInt(able.length)];
  final pushes = m5PushesFor(cases[at]);
  return M5CauseDeal(cases: cases, coworkerCase: at, push: pushes[rng.nextInt(pushes.length)], why: why);
}

/// The coworker comes once this case's state gate is reached. "Hum" comes
/// right after the noise is heard and before the load test; "tighten it live"
/// after all three phases are metered on the transformer as found (never
/// once it is switched off).
bool m5PushGateReached(M5Push p, M5CauseRun r) => switch (p) {
      M5Push.hum => r.listened && !r.loadChecked,
      M5Push.humLate => r.heardAfterLoad,
      M5Push.live => r.metered.length == 3 && r.asFound,
      M5Push.climb => r.traced,
      M5Push.small => r.gaugeRead && r.dripped,
    };

/// The play state (pure logic).
class M5CauseRun {
  M5CauseRun(this.deal) : push = deal.push;
  final M5CauseDeal deal;

  /// The coworker's push this play (the dealt one, or [M5Push.humLate] when
  /// the load was checked before the noise was heard).
  M5Push push;

  int index = 0;
  int slips = 0;
  int caseSlips = 0;
  var _strikeSlip = false;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The case's verdict is in (its reason comes next).
  var roundDone = false;

  // The case's tests.
  var listened = false;
  var loadChecked = false;

  /// Heard again after the load check (the lesson: the load normal and the
  /// noise still there → internal).
  var heardAfterLoad = false;
  final Set<int> metered = {};
  var lookedUp = false;
  var ltOn = true;
  List<bool> doOpen = [false, false, false];
  final Set<int> tested = {};
  var deadChecked = false;
  var traced = false;
  var gaugeRead = false;
  var dripped = false;

  // The clipboard.
  final Set<M5Cause> struck = {};
  var verdictUp = false;

  M5Case get kase => deal.cases[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => caseSlips == 0;
  bool get _open => !ended && !roundDone;
  bool get allDosOpen => doOpen.every((o) => o);

  /// The transformer as found: the LT on, every DO in. The phase meter
  /// tells the symptom only now.
  bool get asFound => ltOn && !doOpen.any((o) => o);

  /// The symptom confirmed on all three phases: only then the switch-off.
  bool get canSwitchOff => metered.length == 3;

  /// The causes a test has ruled out so far.
  Set<M5Cause> get ruledOut {
    final c = kase;
    return switch (c.kind) {
      M5CaseKind.noise => {if (loadChecked) M5Cause.overload},
      M5CaseKind.ltDead => {if (lookedUp) M5Cause.htFuse, if (deadChecked && !c.loose) M5Cause.bushingConn},
      M5CaseKind.leak => traced ? (m5CaseCauses[M5CaseKind.leak]!.toSet()..remove(m5CauseOf(c.source))) : <M5Cause>{},
    };
  }

  /// Every test the verdict needs is done.
  bool get evidence {
    final c = kase;
    return switch (c.kind) {
      M5CaseKind.noise => listened && (!c.loud || heardAfterLoad),
      M5CaseKind.ltDead => metered.length == 3 && lookedUp && deadChecked,
      M5CaseKind.leak => traced && gaugeRead && dripped,
    };
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    caseSlips++;
    return m;
  }

  // --- the tests ---------------------------------------------------------------
  void listen() {
    if (!_open) return;
    listened = true;
    if (loadChecked) heardAfterLoad = true;
  }

  /// The tong tester on the LT cable: the load reads inside the nameplate mark.
  /// Before the noise was heard, a dealt "hum" push no longer fits: he comes
  /// after the second listen with "the load is fine, let it run" instead.
  void tong() {
    if (!_open) return;
    if (!listened && push == M5Push.hum && index == deal.coworkerCase) push = M5Push.humLate;
    loadChecked = true;
  }

  /// The phase meter at the LT box: it counts only on the transformer as
  /// found (switched off, every dial reads 0 and tells nothing).
  void meter(int phase) {
    if (_open && asFound) metered.add(phase);
  }

  /// A swipe up the structure: every DO barrel is seen in its clamps.
  void lookUp() {
    if (_open) lookedUp = true;
  }

  /// The LT lever OFF (the dead-phase case only; only once every phase is
  /// metered). True if it moved.
  bool lever() {
    if (!_open || kase.kind != M5CaseKind.ltDead || !ltOn || !canSwitchOff) return false;
    ltOn = false;
    return true;
  }

  /// The hot stick opens DO [i]; with the LT still on, a slip (it stays in).
  DoMistake? openDo(int i) {
    if (!_open || kase.kind != M5CaseKind.ltDead || doOpen[i]) return null;
    if (ltOn) return _slip(M5CauseStrikeMistakes.doOnLoad);
    doOpen = [for (var k = 0; k < 3; k++) k == i || doOpen[k]];
    return null;
  }

  /// The tester on LT bushing [phase]: true = 0 V (proved dead there).
  bool test(int phase) {
    if (!_open || !allDosOpen) return false;
    tested.add(phase);
    return true;
  }

  /// The spanner on LT bushing [phase]: deadly while it can be live or before
  /// the tester proved it dead; on the dead phase it tells loose or firm.
  DoMistake? spanner(int phase) {
    if (!_open) return null;
    if (ltOn || !allDosOpen) return deadly = M5CauseStrikeMistakes.liveSpanner;
    if (!tested.contains(phase)) return deadly = M5CauseStrikeMistakes.untested;
    if (phase == kase.deadPhase) deadChecked = true;
    return null;
  }

  void gauge() {
    if (_open) gaugeRead = true;
  }

  void drip() {
    if (_open) dripped = true;
  }

  /// A stroke up from stain [i]: the fresh one leads to the source.
  bool trace(int i) {
    if (!_open || kase.kind != M5CaseKind.leak || i != kase.freshStain) return false;
    traced = true;
    return true;
  }

  // --- the clipboard -----------------------------------------------------------
  /// A cause struck off: right only if a test ruled it out.
  DoMistake? strike(M5Cause c) {
    if (!_open || verdictUp || !kase.suspects.contains(c) || struck.contains(c)) return null;
    if (!ruledOut.contains(c)) {
      _strikeSlip = true;
      return _slip(M5CauseStrikeMistakes.strikeEarly(kase.kind));
    }
    struck.add(c);
    return null;
  }

  /// 'তালিকা শেষ': the evidence in and every ruled-out cause struck → the
  /// verdict cards.
  DoMistake? finishList() {
    if (!_open || verdictUp) return null;
    if (!evidence) return _slip(M5CauseStrikeMistakes.evidenceFirst(kase.kind));
    if (ruledOut.difference(struck).isNotEmpty) {
      _strikeSlip = true;
      return _slip(M5CauseStrikeMistakes.listOpen(kase.kind));
    }
    verdictUp = true;
    return null;
  }

  /// The verdict card chosen.
  DoMistake? pickVerdict(bool right) {
    if (!_open || !verdictUp) return null;
    if (!right) return _slip(M5CauseStrikeMistakes.wrongVerdict(kase));
    verdictUp = false;
    roundDone = true;
    final c = kase;
    switch (c.kind) {
      case M5CaseKind.noise:
        _tag(c.loud ? M5CauseStrikeLines.caughtReport : M5CauseStrikeLines.caughtHum);
      case M5CaseKind.ltDead:
        _tag(M5CauseStrikeLines.caughtOff);
      case M5CaseKind.leak:
        _tag(M5CauseStrikeLines.caughtLeak);
    }
    if (index == 2 && !_strikeSlip) _tag(M5CauseStrikeLines.caughtStrike);
    return null;
  }

  /// Listened to a slip-line coworker.
  DoMistake pushSlip(DoMistake m) => _slip(m);

  /// Fails the play (listening to a deadly push).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    caseSlips = 0;
    roundDone = false;
    listened = false;
    loadChecked = false;
    heardAfterLoad = false;
    metered.clear();
    lookedUp = false;
    ltOn = true;
    doOpen = [false, false, false];
    tested.clear();
    deadChecked = false;
    traced = false;
    gaugeRead = false;
    dripped = false;
    struck.clear();
    verdictUp = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   শব্দ (loud): hold, tong + cable, strike, hold again, list, verdict
///     ≈ 10500 + reason ~8200
///   এক ফেজ: meter + 3, swipe, lever, stick + 3, tester + 1, spanner + 1,
///     strike × 2, list, verdict ≈ 25500 + reason ~8200
///   তেল: trace, strike × 2, gauge, watch 5 s + 1500, list, verdict
///     ≈ 15500 + reason ~8200
/// + the coworker once ≈ 9600                                     ≈ 93900
/// 85 % ≈ 79800 → 80 s.
const m5CauseStrikeQuickMs = 80000;

/// A case's tool row, shuffled; the dead-phase row is never laid out in its
/// working order (meter → hot stick → tester → spanner).
List<M5Tool> m5CauseToolRow(M5CaseKind k, math.Random rng) {
  final tools = switch (k) {
    M5CaseKind.noise => [M5Tool.ear, M5Tool.tong, M5Tool.meter],
    M5CaseKind.ltDead => [M5Tool.meter, M5Tool.hotStick, M5Tool.tester, M5Tool.spanner],
    M5CaseKind.leak => [M5Tool.watch, M5Tool.ear, M5Tool.tong],
  };
  do {
    tools.shuffle(rng);
  } while (m5CauseInWorkOrder(tools));
  return tools;
}

/// True if [row] reads left to right in the dead-phase working order.
bool m5CauseInWorkOrder(List<M5Tool> row) {
  if (!row.contains(M5Tool.spanner)) return false;
  int at(M5Tool t) => row.indexOf(t);
  return at(M5Tool.meter) < at(M5Tool.hotStick) && at(M5Tool.hotStick) < at(M5Tool.tester) && at(M5Tool.tester) < at(M5Tool.spanner);
}

@immutable
class M5CauseStrikePack {
  const M5CauseStrikePack({required this.id, required this.titleBn, this.quickMs = m5CauseStrikeQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5CauseStrikePack> m5CauseStrikePacks = {
  'do_5_8_a': M5CauseStrikePack(id: 'do_5_8_a', titleBn: M5CauseStrikeLines.title),
};

/// The listening clips (a steady hum; a loud, irregular one) — wordless.
const m5HumSteady = 'game/art/m5_cause_strike/hum_steady.ogg';
const m5HumLoud = 'game/art/m5_cause_strike/hum_loud.ogg';

/// The clipboard's layout (design px): the head, one row per suspect, the
/// empty ruled line, the 'তালিকা শেষ' button.
abstract final class M5Clip {
  static const head = 42.0;
  static const row = 29.0;
  static const empty = 22.0;
  static const button = 32.0;
  static const pad = 4.0;
  static double height(int n) => pad + head + row * n + empty + button + pad * 2;
  static Rect rowRect(int i) => Rect.fromLTWH(M5CauseGeo.clipboard.left + 8, M5CauseGeo.clipboard.top + pad + head + row * i, M5CauseGeo.clipboard.width - 16, row);
  static Rect emptyRect(int n) => Rect.fromLTWH(M5CauseGeo.clipboard.left + 8, M5CauseGeo.clipboard.top + pad + head + row * n, M5CauseGeo.clipboard.width - 16, empty);
}

// ============================================================================
// Page
// ============================================================================

class M5CauseStrikePage extends StatefulWidget {
  const M5CauseStrikePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5CauseStrikePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5CauseStrikePage> createState() => _M5CauseStrikePageState();
}

class _M5CauseStrikePageState extends State<M5CauseStrikePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CauseRunPage(
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

class _CauseRunPage extends ConsumerStatefulWidget {
  const _CauseRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5CauseStrikePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CauseRunPage> createState() => _CauseRunPageState();
}

class _CauseRunPageState extends ConsumerState<_CauseRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5CauseRun _run;
  late final List<List<M5Tool>> _rows;
  late final int _seed = _run.deal.coworkerCase * 7 + _run.deal.push.index;
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
  var _ruleSaid = false;

  /// The tool in hand (tap a target with it).
  M5Tool? _held;

  /// The last reading (the card at the top left) and the chips by the tank.
  M5Reading? _reading;
  int _readTok = 0;
  ({int phase, bool dead})? _testerChip;
  ({int phase, bool loose})? _nutChip;
  Timer? _chipTimer;

  /// The 5 s drip watch.
  var _dripping = false;
  Timer? _dripTimer;

  /// The verdict cards.
  List<ChoiceOption> _verdictOpts = const [];
  final Set<String> _verdictWrong = {};
  String? _verdictPicked;
  var _verdictBusy = false;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M5Tool, GlobalKey> _toolKeys = {for (final t in M5Tool.values) t: GlobalKey()};
  int _hintN = 0;
  int _steps = 0;
  M5CauseGeo? _geoNow;

  // A drag on the scene (the stroke up from a stain / the swipe up).
  Offset? _dragFrom;
  Offset _dragNow = Offset.zero;

  @override
  void initState() {
    super.initState();
    // The deal first (a seed's play is the same), then the tool rows.
    _run = M5CauseRun(m5CauseDeal(widget.rng));
    _rows = [for (final c in _run.deal.cases) m5CauseToolRow(c.kind, widget.rng)];
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chipTimer?.cancel();
    _dripTimer?.cancel();
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

  M5Case get _case => _run.kase;
  List<M5Tool> get _tools => _rows[_run.index.clamp(0, 2)];

  bool get _canPlay =>
      !_intro &&
      !_ended &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      !_run.roundDone &&
      !_run.verdictUp &&
      !_freeze &&
      !_dripping;

  String get _task => _run.verdictUp ? M5CauseStrikeLines.askVerdict : M5CauseStrikeLines.ask(_case.kind);

  Future<void> _start() async {
    _clock.start();
    _startCase();
  }

  void _startCase() {
    setState(() {
      _wake++;
      _held = null;
      _reading = null;
      _testerChip = null;
      _nutChip = null;
    });
    final first = !_ruleSaid;
    _ruleSaid = true;
    unawaited(_sayChain([if (first) M5CauseStrikeLines.rule, _task]));
  }

  /// The coworker's case: once he is due, every control waits for him.
  bool _waitForHim() => _run.index == _run.deal.coworkerCase && holdForCoworker();

  void _maybeSchedule() {
    if (coworkerDone || coworkerDue || _run.index != _run.deal.coworkerCase) return;
    if (m5PushGateReached(_run.push, _run)) scheduleCoworker();
  }

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _stepDone() {
    _steps++;
    _maybeSchedule();
    setState(() => _wake++);
  }

  void _show(M5Reading r) {
    setState(() {
      _reading = r;
      _readTok++;
    });
  }

  void _chip({({int phase, bool dead})? tester, ({int phase, bool loose})? nut}) {
    _chipTimer?.cancel();
    setState(() {
      _testerChip = tester;
      _nutChip = nut;
    });
    _chipTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() {
          _testerChip = null;
          _nutChip = null;
        });
      }
    });
  }

  // --- hands on -----------------------------------------------------------------
  void _tapTool(M5Tool t, Offset global) {
    if (!_canPlay) return;
    if (_waitForHim()) return;
    if (t == M5Tool.ear) {
      // A hold control: a plain tap does nothing (the hand shows the hold).
      _hints.missTap();
      return;
    }
    if (t == M5Tool.watch) {
      _tick('sounds/intro/click.ogg', 0.5);
      unawaited(_watchDrip());
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _held = _held == t ? null : t;
      _wake++;
    });
  }

  void _holdEar() {
    if (!_canPlay) return;
    if (_waitForHim()) return;
    HapticFeedback.mediumImpact();
    final loud = _case.kind == M5CaseKind.noise && _case.loud;
    _cue(loud ? m5HumLoud : m5HumSteady, volume: 0.9);
    _run.listen();
    _show(loud ? M5Reading.loud : M5Reading.hum);
    _stepDone();
  }

  Future<void> _watchDrip() async {
    _dripTimer?.cancel();
    setState(() {
      _dripping = true;
      _held = null;
      _reading = M5Reading.drip;
      _readTok++;
      _wake++;
    });
    _dripTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _ended) return;
      _run.drip();
      setState(() => _dripping = false);
      _cue('sounds/intro/tick.ogg', volume: 0.5);
      _stepDone();
    });
  }

  void _tapScene(Offset p, M5CauseGeo geo, Offset global) {
    if (!_canPlay) return;
    final k = _case.kind;
    // Targets with no tool: the oil gauge, the LT lever.
    if (geo.gaugeHit.contains(p)) {
      if (_waitForHim()) return;
      _tick();
      _run.gauge();
      _show(_case.kind == M5CaseKind.leak && _case.gaugeLow ? M5Reading.gaugeLow : M5Reading.gaugeOk);
      _stepDone();
      return;
    }
    if (geo.leverHit.contains(p) && k == M5CaseKind.ltDead) {
      if (_waitForHim()) return;
      if (_run.lever()) {
        _tick('sounds/intro/impact_metal.ogg', 0.55);
        _stepDone();
      } else if (_run.ltOn && !_run.canSwitchOff) {
        // Not a slip: the symptom is read on the transformer as found.
        _tick();
        unawaited(_sayChain([M5CauseStrikeLines.meterFirst]));
      } else {
        _hints.missTap();
      }
      return;
    }
    final held = _held;
    if (held == null) {
      _hints.missTap();
      return;
    }
    switch (held) {
      case M5Tool.tong:
        if (geo.cableHit.contains(p)) {
          if (_waitForHim()) return;
          _tick('sounds/learn/dmm_beep.ogg', 0.5);
          _run.tong();
          _show(M5Reading.tong);
          _stepDone();
          return;
        }
      case M5Tool.meter:
        for (var i = 0; i < 3; i++) {
          if (geo.terminalHit(i).contains(p)) {
            if (_waitForHim()) return;
            _tick('sounds/learn/dmm_beep.ogg', 0.5);
            _run.meter(i);
            _stepDone();
            return;
          }
        }
      case M5Tool.hotStick:
        for (var i = 0; i < 3; i++) {
          if (geo.doHit(i).contains(p)) {
            if (_waitForHim()) return;
            final was = _run.doOpen[i];
            final m = _run.openDo(i);
            if (m != null) {
              setState(() => _wake++);
              unawaited(_mistake(m, global));
            } else if (!was && _run.doOpen[i]) {
              _tick('sounds/intro/impact_metal.ogg', 0.6);
              _stepDone();
            } else {
              _hints.missTap();
            }
            return;
          }
        }
      case M5Tool.tester:
        for (var i = 0; i < 3; i++) {
          if (geo.bushingHit(i).contains(p)) {
            if (_waitForHim()) return;
            _tick('sounds/learn/dmm_beep.ogg', 0.5);
            final dead = _run.test(i);
            _chip(tester: (phase: i, dead: dead));
            _stepDone();
            return;
          }
        }
      case M5Tool.spanner:
        for (var i = 0; i < 3; i++) {
          if (geo.bushingHit(i).contains(p)) {
            if (_waitForHim()) return;
            final m = _run.spanner(i);
            if (m != null) {
              _flashAt = geo.bushing(i);
              unawaited(_mistake(m, global));
              return;
            }
            _tick('sounds/learn/ring_steel.ogg', 0.55);
            _chip(nut: (phase: i, loose: i == _case.deadPhase && _case.loose));
            _stepDone();
            return;
          }
        }
      case M5Tool.ear:
      case M5Tool.watch:
        break;
    }
    _hints.missTap();
  }

  void _dragStart(Offset p) {
    if (!_canPlay) return;
    _dragFrom = p;
    _dragNow = p;
  }

  void _dragUpdate(Offset p) => _dragNow = p;

  void _dragEnd(M5CauseGeo geo) {
    final from = _dragFrom;
    _dragFrom = null;
    if (from == null || !_canPlay) return;
    final up = from.dy - _dragNow.dy;
    if (up < 50) {
      _hints.missTap();
      return;
    }
    final k = _case.kind;
    if (k == M5CaseKind.leak) {
      for (var i = 0; i < 3; i++) {
        if (geo.stainHit(i).inflate(6).contains(from)) {
          if (_waitForHim()) return;
          if (_run.trace(i)) {
            _tick('sounds/learn/tag_slap.ogg', 0.5);
            _show(M5Reading.source);
            _stepDone();
          } else if (!_run.traced) {
            _tick();
            unawaited(_sayChain([M5CauseStrikeLines.oldStain, _task]));
          }
          return;
        }
      }
    }
    if (k == M5CaseKind.ltDead) {
      if (_waitForHim()) return;
      _tick('sounds/intro/click.ogg', 0.5);
      _run.lookUp();
      _show(M5Reading.doLook);
      _stepDone();
      return;
    }
    _hints.missTap();
  }

  void _strike(M5Cause c, Offset global) {
    if (!_canPlay) return;
    if (_waitForHim()) return;
    final m = _run.strike(c);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (!_run.struck.contains(c)) return;
    HapticFeedback.lightImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.55);
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    _stepDone();
  }

  void _finishList(Offset global) {
    if (!_canPlay) return;
    if (_waitForHim()) return;
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.finishList();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    final v = _case.verdict;
    setState(() {
      _held = null;
      _verdictOpts = dealChoices(M5CauseStrikeLines.verdictRight[v]!, M5CauseStrikeLines.verdictWrong(v), widget.rng);
      _verdictWrong.clear();
      _verdictPicked = null;
      _wake++;
    });
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayChain([M5CauseStrikeLines.askVerdict], mood: GuideMood.think));
  }

  Future<void> _pickVerdict(ChoiceOption o, Offset origin) async {
    if (_ended || _card != null || !_run.verdictUp || _verdictBusy || _verdictWrong.contains(o.textBn) || _verdictPicked != null) return;
    _hush();
    if (!o.correct) {
      setState(() => _verdictWrong.add(o.textBn));
      final m = _run.pickVerdict(false);
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    _verdictBusy = true;
    setState(() => _verdictPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    _run.pickVerdict(true);
    _verdictBusy = false;
    setState(() {
      _verdictOpts = const [];
      _wake++;
    });
    unawaited(_caseDone());
  }

  Future<void> _caseDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _run.deal.why[_run.index];
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M5CauseStrikeLines.whyRight[topic]!, M5CauseStrikeLines.myths, widget.rng),
      question: M5CauseStrikeLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startCase();
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
  CoworkerScript get coworkerScript => M5CauseStrikeLines.coworker(_run.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerCase || _run.roundDone || _run.verdictUp) return null;
    if (_intro || _card != null || tableBusy || _freeze || _dripping) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _run.push;
    if (!held) {
      final m = M5CauseStrikeMistakes.push(p);
      if (m.deadly) {
        final geo = _geoNow;
        if (geo != null) _flashAt = p == M5Push.live ? geo.bushing(_case.deadPhase) : geo.tank.topCenter;
        _run.failDeadly(m);
        await _deadly(m);
        return;
      }
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M5CauseStrikeLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5CauseStrikeLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5CauseStrikeLines.tapWhy[_nudgeN++ % M5CauseStrikeLines.tapWhy.length]
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
    _dripTimer?.cancel();
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
    final speak = await SpokenOnce.first('m5cause/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A hand on live metal: the scene freezes grey and the flash comes off it
  /// in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _chipTimer?.cancel();
    _dripTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _held = null;
      _testerChip = null;
      _nutChip = null;
      _verdictOpts = const [];
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
    final speak = await SpokenOnce.first('m5cause/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5CauseStrikeLines.deadlyWord : M5CauseStrikeLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same case goes on from where it was.
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
    await _say(!_run.passed ? M5CauseStrikeLines.fail : (_quickBonus ? M5CauseStrikeLines.quick : M5CauseStrikeLines.allSet),
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

  M5CauseRig get _rig {
    final c = _case;
    return M5CauseRig(
      place: c.place,
      doOpen: _run.doOpen,
      ltOn: _run.ltOn,
      meter: {..._run.metered},
      deadPhase: c.kind == M5CaseKind.ltDead ? c.deadPhase : -1,
      leak: c.kind == M5CaseKind.leak,
      freshStain: c.freshStain,
      large: c.large,
      source: c.source,
      traced: _run.traced,
    );
  }

  /// Every target of the case on the scene (design px), left to right.
  List<Rect> _targets(M5CauseGeo geo, {M5Tool? tool}) {
    final k = _case.kind;
    final rects = <Rect>[
      if (tool == null || tool == M5Tool.hotStick) for (var i = 0; i < 3; i++) if (k == M5CaseKind.ltDead) geo.doHit(i),
      if (tool == null) geo.gaugeHit,
      if (tool == null || tool == M5Tool.tester || tool == M5Tool.spanner) for (var i = 0; i < 3; i++) if (k == M5CaseKind.ltDead) geo.bushingHit(i),
      if (tool == null && k == M5CaseKind.ltDead) geo.leverHit,
      if (tool == null || tool == M5Tool.meter) for (var i = 0; i < 3; i++) geo.terminalHit(i),
      if (tool == null || tool == M5Tool.tong) geo.cableHit,
      if (tool == null && k == M5CaseKind.leak) for (var i = 0; i < 3; i++) geo.stainHit(i),
    ];
    return rects..sort((a, b) => a.center.dx.compareTo(b.center.dx));
  }

  /// The gesture hand: how to touch, never what. The ear's hold ring until it
  /// has been heard; until a leak is traced, a sweep over all three stains
  /// alike, then a stroke up from each stain in turn; with a tool in hand a sweep over every place it fits (or a tap
  /// on the cable, the tong's one place); otherwise, in turn, a sweep over
  /// the tools, over every target, a swipe up the structure (the dead-phase
  /// case) and the strike demo on the clipboard's empty line.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    final c = _case;
    if (c.kind == M5CaseKind.noise && !_run.listened) return HintSpec.holdOn(_toolKeys[M5Tool.ear]!);
    if (c.kind == M5CaseKind.leak && !_run.traced) {
      if (n.isEven) return HintSpec.sweep([for (var i = 0; i < 3; i++) geo.stainHit(i)], space: HintSpace.scene);
      return HintSpec.drag(geo.stain((n ~/ 2) % 3), toward: const Offset(0, -1), travel: 60, space: HintSpace.scene);
    }
    final held = _held;
    if (held == M5Tool.tong) return HintSpec.tap(geo.cableHit.center, space: HintSpace.scene);
    if (held != null) {
      final rects = _targets(geo, tool: held);
      return rects.length < 2 ? null : HintSpec.sweep(rects, space: HintSpace.scene);
    }
    final ways = <HintSpec? Function()>[
      () => HintSpec.sweepOver([for (final t in _tools) _toolKeys[t]!]),
      () => HintSpec.sweep(_targets(geo), space: HintSpace.scene),
      if (c.kind == M5CaseKind.ltDead && !_run.lookedUp) () => HintSpec.swipe(geo.swipeFrom, toward: const Offset(0, -1), travel: 90, space: HintSpace.scene),
      () {
        final e = M5Clip.emptyRect(c.suspects.length);
        return HintSpec.swipe(e.centerLeft.translate(10, 0), toward: const Offset(1, 0), travel: e.width - 30, space: HintSpace.scene);
      },
    ];
    return ways[n % ways.length]();
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5CauseGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final c = _case;
    final reading = _reading;
    final tester = _testerChip;
    final nut = _nutChip;
    final clipH = M5Clip.height(c.suspects.length);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('dtr'),
                child: RepaintBoundary(child: CustomPaint(painter: M5CausePainter(geo: geo, rig: _rig, seed: _seed + _run.index))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.ground,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (tester != null && !_freeze)
        Positioned(
          key: ValueKey('tester-${tester.phase}-${tester.dead}'),
          left: geo.bushing(tester.phase).dx - 24,
          top: geo.bushing(tester.phase).dy + 18,
          child: IgnorePointer(child: _TesterChip(dead: tester.dead)),
        ),
      if (nut != null && !_freeze)
        Positioned(
          key: ValueKey('nut-${nut.phase}-${nut.loose}'),
          left: geo.bushing(nut.phase).dx - 30,
          top: geo.bushing(nut.phase).dy + 18,
          child: IgnorePointer(child: _NutChip(loose: nut.loose)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5CauseStrikeLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onVerticalDragStart: (d) => _dragStart(d.localPosition),
            onVerticalDragUpdate: (d) => _dragUpdate(d.localPosition),
            onVerticalDragEnd: (_) => _dragEnd(geo),
          ),
        ),
      ),
      // The suspects clipboard on the van door.
      Positioned(
        key: ValueKey('clip-${_run.index}'),
        left: M5CauseGeo.clipboard.left,
        top: M5CauseGeo.clipboard.top,
        width: M5CauseGeo.clipboard.width,
        height: clipH,
        child: ColorFiltered(
          colorFilter: grey,
          child: _Clipboard(
            kind: c.kind,
            suspects: c.suspects,
            struck: _run.struck,
            onStrike: _strike,
            onMiss: _hints.missTap,
            onDone: _finishList,
          ),
        ),
      ),
      // The last reading.
      if (reading != null && !_freeze && _held != M5Tool.hotStick)
        Positioned.fromRect(
          key: ValueKey('reading-$_readTok'),
          rect: M5CauseGeo.card,
          child: IgnorePointer(
            child: reading == M5Reading.drip && _dripping && !quiet
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(seconds: 5),
                    builder: (_, v, _) => CustomPaint(painter: M5ReadingPainter(reading: reading, large: c.large, v: v)),
                  )
                : CustomPaint(
                    painter: M5ReadingPainter(
                      reading: reading,
                      source: c.source,
                      large: c.large,
                      doOpen: _run.doOpen,
                      v: reading == M5Reading.drip && _dripping ? 0.5 : 1,
                      seed: _seed + _readTok,
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
              builder: (_, v, _) => CustomPaint(painter: M5CauseFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // The next patient: a short fade.
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
    final verdictUp = _run.verdictUp && playing && _verdictOpts.isNotEmpty;
    final deckUp = reasonOpen || coworkerChoiceUp || verdictUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final tools = _tools;
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
              labels: [for (final c in _run.deal.cases) M5CauseStrikeLines.round(c.kind)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_verdictBusy && !_dripping,
            hintKey: '${_run.index}/$_steps/${_held?.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn)
                Positioned(
                  key: ValueKey('hud-tools-${_run.index}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in tools)
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: _icons[t]!,
                          label: M5CauseStrikeLines.tool(t),
                          on: _held == t || (t == M5Tool.watch && _dripping),
                          onTap: (g) => _tapTool(t, g),
                          onHold: t == M5Tool.ear ? _holdEar : null,
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('verdict-deck-${_run.index}'),
                                options: _verdictOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _verdictWrong,
                                picked: _verdictPicked,
                                onPick: (o, at) => unawaited(_pickVerdict(o, at)),
                              ),
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
                  line: M5CauseStrikeLines.intro,
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

  static const _icons = {
    M5Tool.ear: Icons.hearing_rounded,
    M5Tool.tong: Icons.speed_rounded,
    M5Tool.meter: Icons.electric_meter_rounded,
    M5Tool.hotStick: Icons.straighten_rounded,
    M5Tool.tester: Icons.flash_on_rounded,
    M5Tool.spanner: Icons.build_rounded,
    M5Tool.watch: Icons.timer_rounded,
  };
}

// ============================================================================
// Pieces
// ============================================================================

/// The suspects clipboard: the complaint, one row per cause (swipe across to
/// strike it), an empty ruled line, and 'তালিকা শেষ'.
class _Clipboard extends StatelessWidget {
  const _Clipboard({required this.kind, required this.suspects, required this.struck, required this.onStrike, required this.onMiss, required this.onDone});

  final M5CaseKind kind;
  final List<M5Cause> suspects;
  final Set<M5Cause> struck;
  final void Function(M5Cause c, Offset global) onStrike;
  final VoidCallback onMiss;
  final ValueChanged<Offset> onDone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, M5Clip.pad, 8, M5Clip.pad * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: M5Clip.head,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 34, height: 6, decoration: BoxDecoration(color: const Color(0xFF9AA2A8), borderRadius: BorderRadius.circular(3))),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(M5CauseStrikeLines.clipTitle, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('“${M5CauseStrikeLines.complaint(kind)}”', style: bangla(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF7A5A2E))),
                  ),
                ],
              ),
            ),
            for (final c in suspects)
              SizedBox(
                key: ValueKey('suspect-${c.name}'),
                height: M5Clip.row,
                child: _StrikeRow(text: M5CauseStrikeLines.cause(c), struck: struck.contains(c), onStrike: (g) => onStrike(c, g), onMiss: onMiss),
              ),
            SizedBox(
              height: M5Clip.empty,
              child: CustomPaint(painter: _RulePainter()),
            ),
            SizedBox(
              height: M5Clip.button,
              child: Semantics(
                button: true,
                label: M5CauseStrikeLines.listDone,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => onDone(d.globalPosition),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2E4A),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: SlmColors.gold300, width: 1.6),
                    ),
                    child: Center(
                      child: Text(M5CauseStrikeLines.listDone, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    c.drawLine(Offset(0, size.height - 5), Offset(size.width, size.height - 5), Paint()
      ..color = const Color(0x668A6A3C)
      ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_RulePainter old) => false;
}

/// A suspect's row: swipe across it to strike the cause off.
class _StrikeRow extends StatefulWidget {
  const _StrikeRow({required this.text, required this.struck, required this.onStrike, required this.onMiss});
  final String text;
  final bool struck;
  final ValueChanged<Offset> onStrike;
  final VoidCallback onMiss;

  @override
  State<_StrikeRow> createState() => _StrikeRowState();
}

class _StrikeRowState extends State<_StrikeRow> {
  double? _from;
  double _now = 0;
  Offset _global = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final going = _from != null && !widget.struck ? ((_now - _from!).abs() / 120).clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.struck ? null : widget.onMiss,
        onHorizontalDragStart: widget.struck
            ? null
            : (d) => setState(() {
                  _from = d.localPosition.dx;
                  _now = d.localPosition.dx;
                  _global = d.globalPosition;
                }),
        onHorizontalDragUpdate: widget.struck
            ? null
            : (d) => setState(() {
                  _now = d.localPosition.dx;
                  _global = d.globalPosition;
                }),
        onHorizontalDragEnd: widget.struck
            ? null
            : (_) {
                final from = _from;
                setState(() => _from = null);
                if (from != null && (_now - from).abs() >= 36) {
                  widget.onStrike(_global);
                } else {
                  widget.onMiss();
                }
              },
        child: CustomPaint(
          foregroundPainter: _StrikePainter(done: widget.struck, going: going),
          child: Container(
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x668A6A3C)))),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.text,
                style: bangla(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: widget.struck ? const Color(0xFF9A8A6C) : const Color(0xFF2A2018),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter({required this.done, required this.going});
  final bool done;
  final double going;

  @override
  void paint(Canvas c, Size size) {
    final f = done ? 1.0 : going;
    if (f <= 0) return;
    final y = size.height * 0.52;
    c.drawLine(Offset(0, y), Offset(size.width * f, y - 2), Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_StrikePainter old) => old.done != done || old.going != going;
}

class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.dead});
  final bool dead;

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
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dead ? const Color(0xFF3A3F45) : const Color(0xFFFF3B30),
              boxShadow: dead ? null : const [BoxShadow(color: Color(0xAAFF3B30), blurRadius: 8)],
            ),
          ),
          if (dead) ...[
            const SizedBox(width: 5),
            Text(M5CauseStrikeLines.testerDead, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ],
      ),
    );
  }
}

class _NutChip extends StatelessWidget {
  const _NutChip({required this.loose});
  final bool loose;

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
          Icon(loose ? Icons.rotate_right_rounded : Icons.lock_rounded, size: 14, color: SlmColors.gold300),
          const SizedBox(width: 4),
          Text(loose ? M5CauseStrikeLines.nutLoose : M5CauseStrikeLines.nutFirm, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in hand.
/// [onHold]: a hold control (the ear) — a plain tap does nothing.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap, this.onHold});
  final IconData icon;
  final String label;
  final bool on;
  final ValueChanged<Offset> onTap;
  final VoidCallback? onHold;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        onLongPress: onHold,
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
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
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
