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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm6_earth_pit_test_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_earth_pit_test_world.dart'
    show M6Electrode, M6Lid, M6Nut, M6PitGeo, M6Remedy, M6Soil, m6ElectrodeGood, m6SoilHigh;

// Lesson 6.11 "আর্থিং সিস্টেম: অদৃশ্য অভিভাবক", কাজ "মাটির ভেতরে রক্ষক"
// (pack do_6_11_a, engineType m6_earth_pit_test; ruling M6-9: inspect and
// test, one Do level). A new DTR, not yet charged; the crew or a contractor
// dug its two earth pits, one per earth lead (pro tip 1: double earthing).
// Two rounds, one per lead: open the pit, look, put right, test, sign.
//
//  ঢাকনা: drag the chamber lid up to look in; drag it back down before
//    signing. A pit left with no chamber or lid: drag the spare ring and lid
//    from the pallet onto it. Signed with no lid on = slip (point 3).
//  ইলেক্ট্রোড: its record tag and its look tell what it is; GI perforated
//    pipe 2.5–3 m is right (point 2). A plain iron rod, a short pipe or a
//    bent iron bar signed = slip (myth 2); 'ইলেক্ট্রোড বদলাই' has the crew
//    drive a right one. Coworker A (myth 2, word for word) = slip.
//  জোড়: the bottom joint (strip to electrode, in the chamber) and the top
//    joint (strip to the DTR's earth terminal). Tap one, pick a nut packet,
//    then circle the spanner round it until it is snug. An iron nut fitted or
//    left = slip (pro tip 2). A joint with its nut off (the strip off its
//    bolt) breaks the earth path: the tester reads OL, and signing it =
//    DEADLY (ruling M6-1, row N7); coworker B (myth 1, word for word) pushes
//    exactly that, so listening is the same deadly (X2/B1).
//  দুটো পিট: some plays the second lead was bolted into the first pit (no
//    pit dug at its own peg). Signing it = slip (pro tip 1); 'আলাদা পিট
//    খুঁড়ি' has the crew dig a separate pit at the peg, then it is checked.
//  টেস্ট: TEST on the earth tester (label kEarthTesterBn, ruling M6-13) with
//    the chamber open; a bare number. ≤ 5 Ω: sign. > 5 Ω (never 5–8 on
//    screen): 'মান কমানো চাই' opens the remedy tray (always all four): জল
//    fits dry soil (point 4), বেন্টোনাইট or আরেকটা ইলেক্ট্রোড fit rocky or
//    sandy soil (pro tip 3); a remedy that does not fit lowers the number a
//    little, never under 5 (scene behaviour); পাথরের কুচি = slip. Signing a
//    high reading = slip. A wrong electrode reads high whatever is added.
//  A needless replacement, pit or remedy costs no slip, only the round's
//    thoroughness bonus and time (owner question).
//
// Each slip kind counts once per pit; signing again with it still there is
// refused with a guide line, no second slip. Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_earth_pit_test_world.dart), corner guide, a signed pit puts
// ◆ on the table → "কেন …?" → the next lead; the coworker once a play, when
// his pit's chamber is first open (every control in that pit waits for
// him: holdForCoworker). Gesture hands: an upward nudge on a lid, a nudge on
// the lifted lid or the spare set, a sweep over the joints, the tester and
// the actions, a sweep over a tray, a short to-and-fro nudge round a joint
// for the spanner (the arc fallback of ruling M6-11) — never the answer.

// ============================================================================
// Content
// ============================================================================

/// The instrument's name on screen (ruling M6-13; owner 2026-11-15:
/// 'আর্থ টেস্টার'). One constant, to switch if the field word differs.
const kEarthTesterBn = 'আর্থ টেস্টার';

/// The coworker's push (one per play).
enum M6PitPush { anyRod, looseOk }

/// What a round's reason asks about (fits what was done in that pit).
enum M6PitWhy { signed, joint, secondPit, electrode, water, bentonite, extra, iron, lid }

/// The four actions under the scene (always the same four, alike).
enum M6PitAction { replace, dig, remedy, sign }

/// What the player is choosing from a tray.
enum M6PitTray { none, nuts, remedies }

/// What a sign-off did.
enum M6Sign { done, testFirst, slip, again, deadly }

/// Why a control did nothing (the guide says it; no cost).
enum M6PitGuard { lidFirst, testFirst, noPit }

/// Turns of the spanner that make a fitted nut snug.
const kM6PitTurns = 1.25;

/// The reading limit (lesson pro tip 4 'যেমন ৫ ওহম'; ruling M6-13).
const kM6PitLimit = 5.0;

abstract final class M6EarthPitLines {
  static const title = 'মাটির ভেতরে রক্ষক';
  // DRAFT wording — owner (M6-12).
  static const intro = 'নতুন DTR চার্জের আগে দুটো আর্থ পিট দেখে, টেস্ট করে তবে সই।';

  // The guide's task now (tap him: the same task, a different way).
  static const askPit = 'এই লিডের আর্থ পিটটা দেখুন।';
  static const askCheck = 'ইলেক্ট্রোড আর জোড়গুলো দেখে নিন, তারপর টেস্ট করুন।';
  static const askVerdict = 'মানটা দেখে ঠিক করুন — সই, না মান কমানো।';
  static const askTighten = 'স্প্যানার ঘুরিয়ে জোড়টা টাইট করুন।';
  static const askNut = 'কোন নাট-বল্টু লাগাবেন, বেছে নিন।';
  static const askRemedy = 'কী দিয়ে মান কমাবেন, বেছে নিন।';
  static List<String> get tasks => [askPit, askCheck, askVerdict, askTighten, askNut, askRemedy];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Guards (no cost) and what the crew did.
  static const lidFirst = 'ঢাকনা বন্ধ — আগে ঢাকনা তুলে ভেতরটা দেখুন।';
  static const testFirst = 'আগে টেস্ট করে মানটা দেখুন।';
  static const noPit = 'এখানে তো কোনো পিট নেই।';
  static const needless = 'এটার দরকার ছিল না — শুধু সময় গেল।';
  static const retest = 'হয়ে গেল — এবার আবার টেস্ট করুন।';
  static const replaced = 'নতুন ইলেক্ট্রোড বসল — আবার টেস্ট করুন।';
  static const dug = 'আলাদা জায়গায় নতুন পিট হলো, লিডও সেখানে — এবার দেখুন।';
  /// A shared deal, round 0: the right call before its turn (no cost).
  static const digLater = 'ঠিক ধরেছেন — দ্বিতীয় লিডের পালা এলে আলাদা পিট খুঁড়বেন।';
  static const ironAgain = 'লোহা নয় — পিতল বা স্টেইনলেস দিন।';

  /// A sign-off refused again for a fault already scored (no second slip).
  static String again(DoMistake m) => m == M6EarthPitMistakes.noLid
      ? 'আগে চেম্বারে ঢাকনা লাগান, তারপর সই।'
      : m == M6EarthPitMistakes.electrode
          ? 'আগে ইলেক্ট্রোডটা বদলান, তারপর সই।'
          : m == M6EarthPitMistakes.ironNut
              ? 'আগে লোহার নাট বদলে পিতল বা স্টেইনলেস দিন।'
              : m == M6EarthPitMistakes.highSigned
                  ? 'মান 5 ওহমের বেশি — আগে মান কমান।'
                  : 'দ্বিতীয় লিডের জন্য আলাদা পিট চাই।';
  static List<String> get allAgain => [
        for (final m in [M6EarthPitMistakes.noLid, M6EarthPitMistakes.electrode, M6EarthPitMistakes.ironNut, M6EarthPitMistakes.highSigned, M6EarthPitMistakes.samePit]) again(m),
      ];

  // What a worker reads on site.
  static String lead(int n) => enDigits('লিড $n');
  static const sceneLabel = 'আর্থ পিট';
  static const testLabel = 'TEST';
  static const tag = 'ইলেক্ট্রোডের ট্যাগ';
  static String tagOf(M6Electrode e) => switch (e) {
        M6Electrode.gi27 => 'GI ছিদ্রযুক্ত পাইপ\n2.7 m',
        M6Electrode.gi25 => 'GI ছিদ্রযুক্ত পাইপ\n2.5 m',
        M6Electrode.gi30 => 'GI ছিদ্রযুক্ত পাইপ\n3 m',
        M6Electrode.rod => 'লোহার রড\n2.7 m',
        M6Electrode.short => 'GI ছিদ্রযুক্ত পাইপ\n1.2 m',
        M6Electrode.bar => 'লোহার বার\n2.7 m',
      };
  static String reading(double? r) => r == null ? '- - -' : (r.isInfinite ? 'OL' : '${r.toStringAsFixed(1)} Ω');

  /// The four actions: about the same length, the same in every pit.
  static String action(M6PitAction a) => switch (a) {
        M6PitAction.replace => 'ইলেক্ট্রোড বদলাই',
        M6PitAction.dig => 'আলাদা পিট খুঁড়ি',
        M6PitAction.remedy => 'মান কমানো চাই',
        M6PitAction.sign => 'সব ঠিক, সই করি',
      };
  static String nut(M6Nut n) => switch (n) {
        M6Nut.brass => 'পিতলের নাট-বল্টু',
        M6Nut.steel => 'স্টেইনলেস নাট-বল্টু',
        M6Nut.iron => 'লোহার নাট-বল্টু',
        M6Nut.none => '',
      };
  static String remedy(M6Remedy r) => switch (r) {
        M6Remedy.water => 'পিটের মধ্যে জল দিই',
        M6Remedy.bentonite => 'বেন্টোনাইট পাউডার',
        M6Remedy.extra => 'আরেকটা ইলেক্ট্রোড',
        M6Remedy.gravel => 'পাথরের কুচি ঢালি',
      };
  static const trayClose = 'ফিরে যাই';

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses. DRAFT wording — owner (M6-12).
  static const whyQ = <M6PitWhy, String>{
    M6PitWhy.signed: 'কেন এই মানে সই করলেন?',
    M6PitWhy.joint: 'কেন জোড়টা টাইট করে তবে সই করলেন?',
    M6PitWhy.secondPit: 'দ্বিতীয় পিট আলাদা কেন?',
    M6PitWhy.electrode: 'কেন ইলেক্ট্রোডটা বদলাতে বললেন?',
    M6PitWhy.water: 'মান কমাতে এটা কেন করলেন?',
    M6PitWhy.bentonite: 'মান কমাতে এটা কেন করলেন?',
    M6PitWhy.extra: 'মান কমাতে এটা কেন করলেন?',
    M6PitWhy.iron: 'কেন এই নাট-বল্টু?',
    M6PitWhy.lid: 'কেন চেম্বারে ঢাকনা লাগিয়ে তবে সই?',
  };
  static const whyRight = <M6PitWhy, List<String>>{
    M6PitWhy.signed: ['মান 5 ওহমের মধ্যে — আর্থিং সুস্থ আছে', 'টেস্টারে মান 5 ওহমের নিচে, পথ ঠিক আছে'],
    M6PitWhy.joint: ['আলগা জোড়ে ফল্টের সময় ব্রেকার ট্রিপ করবে না', 'কাটা-আলগা আর্থে ফল্ট কারেন্টের পথ থাকে না'],
    M6PitWhy.secondPit: ['একটা পিট ব্যর্থ হলেও অন্যটা সুরক্ষা দেবে', 'DTR-এ দুটি আলাদা পিট থেকে ডাবল আর্থিং'],
    M6PitWhy.electrode: ['ঠিক উপাদান আর দৈর্ঘ্য ছাড়া আর্থিং কাজ করে না', 'GI ছিদ্রযুক্ত পাইপ, 2.5-3 মিটার লম্বা চাই'],
    M6PitWhy.water: ['শুকনো মাটিতে জলে আর্দ্রতা বাড়ে, মান কমে', 'জল দিলে চারপাশের মাটি ভেজে, রেজিস্ট্যান্স কমে'],
    M6PitWhy.bentonite: ['পাথুরে-বালু মাটিতে বেন্টোনাইট মান কমায়', 'পাথুরে-বালু মাটিতে রাসায়নিক ট্রিটমেন্ট চাই'],
    M6PitWhy.extra: ['পাথুরে-বালু মাটিতে একাধিক ইলেক্ট্রোড লাগে', 'বেশি রেজিস্ট্যান্সের মাটিতে বাড়তি ইলেক্ট্রোড'],
    M6PitWhy.iron: ['পিতল বা স্টেইনলেসে সহজে মরিচা ধরে না', 'মরিচা ধরা জোড় আর্থের রেজিস্ট্যান্স বাড়ায়'],
    M6PitWhy.lid: ['চেম্বার আর ঢাকনা পিটটাকে সুরক্ষিত রাখে', 'খোলা পিট সুরক্ষিত নয়, ঢাকনা লাগানো চাই'],
  };
  static const myths = [
    'যেকোনো লোহার রড পুঁতলেই ভালো আর্থিং হয়',
    'আর্থ তার একটু আলগা থাকলেও লাইন ঠিকই চলে',
    'আর্থিং শুধু নিয়ম রক্ষা, কাজের কিছু নয়',
    'মান যা-ই হোক, পিট খোঁড়া হলেই যথেষ্ট',
    'নাট-বল্টু যেকোনো হলেই জোড় একই রকম থাকে',
    'দুটো লিড এক পিটে দিলেও ডাবল আর্থিং হয়',
    'পাথরের কুচি দিলেই আর্থের মান কমে যায়',
    'ঢাকনা থাক বা না থাক, আর্থ একই কাজ করে',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play). His two pushes are lesson 6.11's
  // myths word for word (M6-9).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerRod = CoworkerScript(
    line: 'যেকোনো একটি লোহার রড মাটিতে পুঁতে দিলেই ভালো আর্থিং হয়ে যায়।',
    exitLine: coworkerExit,
    right: ['না, ঠিক দৈর্ঘ্যের GI পাইপ চাই', 'না, এই ইলেক্ট্রোডটা বদলাতে হবে', 'না, ঠিক উপাদান ছাড়া আর্থিং হয় না'],
    wrong: [
      'ঠিক, যেকোনো লোহার রড হলেই চলবে',
      'আচ্ছা, যা পোঁতা আছে তাই থাকুক',
      'হ্যাঁ, বদলানোর ঝামেলা কে করে',
      'ঠিক আছে, পোঁতা রডটাই রেখে দিই',
      'হ্যাঁ, রড পুঁতলেই আর্থ হয়ে যায়',
    ],
    asks: ['কী করবেন?', 'ও বলছে যেকোনো রডেই চলবে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerLoose = CoworkerScript(
    line: 'আর্থিং তারটা তো শুধু সুরক্ষার জন্য, ওটা একটু কাটা বা আলগা থাকলেও লাইন চলতে কোনো অসুবিধা হয় না।',
    exitLine: coworkerExit,
    right: ['না, আগে জোড়টা টাইট করে তবে সই', 'না, আলগা আর্থে ব্রেকার পড়বে না', 'না, ভাঙা আর্থ নিয়ে সই করব না'],
    wrong: [
      'ঠিক, লাইন তো চলবে, সই করে দিই',
      'আচ্ছা, আলগা থাক, পরে দেখা যাবে',
      'হ্যাঁ, আর্থ তো শুধু সুরক্ষার',
      'ঠিক আছে, এভাবেই সই করে দিচ্ছি',
      'হ্যাঁ, একটু আলগায় কিছু হয় না',
    ],
    asks: ['কী করবেন?', 'ও বলছে আলগা আর্থেই সই করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6PitPush p) => switch (p) {
        M6PitPush.anyRod => coworkerRod,
        M6PitPush.looseOk => coworkerLoose,
      };
  static const allCoworkers = [coworkerRod, coworkerLoose];

  static String callHeld(M6PitPush p) => switch (p) {
        M6PitPush.anyRod => 'ঠিক! ঠিক উপাদান আর দৈর্ঘ্য ছাড়া আর্থিং হয় না।',
        M6PitPush.looseOk => 'ঠিক! ভাঙা আর্থে ফল্টের সময় ব্রেকার ট্রিপ করবে না।',
      };

  // DRAFT: the yearly dry-season test is CEA 2023 Reg 43(x) (ruling M6-9).
  static const allSet = 'দুটো পিটই ঠিক — শুকনো মরসুমে বছরে একবার আবার টেস্ট।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে দেখুন, ঠিক করুন, টেস্ট করুন, তবে সই।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtJoint = 'খোলা জোড় টাইট করে তবে সই';
  static const caughtSecond = 'দ্বিতীয় লিডে আলাদা পিট';
  static const caughtElectrode = 'ভুল ইলেক্ট্রোড বদলেছেন';
  static const caughtRemedy = 'বেশি মান কমিয়ে তবে সই';
  static const caughtIron = 'লোহার নাট বদলে পিতল/স্টেইনলেস';
  static const caughtLid = 'চেম্বারে ঢাকনা লাগিয়েছেন';
  static const caughtSign = 'মান 5 ওহমের মধ্যে দেখে সই';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';
  static const caughtAll = [caughtJoint, caughtSecond, caughtElectrode, caughtRemedy, caughtIron, caughtLid, caughtSign, caughtCall];

  /// The coworker's pushes (lesson myths word for word; to record in his
  /// voice with tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        ...tapWhy,
        lidFirst,
        testFirst,
        noPit,
        needless,
        retest,
        replaced,
        dug,
        digLater,
        ironAgain,
        ...allAgain,
        ...{...whyQ.values},
        for (final c in allCoworkers) ...c.asks,
        for (final p in M6PitPush.values) callHeld(p),
        allSet,
        fail,
        for (final m in M6EarthPitMistakes.all) m.textBn,
      }.toList();
}

abstract final class M6EarthPitMistakes {
  static const _dir = 'assets/game/art/m6_earth_pit_test';

  // DRAFT wording — owner (M6-12). Lesson points (0-based): 1 pipe/plate,
  // 2 a healthy earthing system (strip, connections, chamber and lid).
  static const brokenSigned = DoMistake(
    key: '6.11/m6_earth_pit_test/broken-signed',
    textBn: 'আর্থের পথ ভাঙা — টেস্টারে OL! এমন আর্থে সই মানে ফল্টের সময় ব্রেকার ট্রিপ করবে না, বডিতে কারেন্ট থেকে যাবে। আগে জোড় টাইট, আবার টেস্ট, তবে সই।',
    art: '$_dir/broken_signed.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const electrode = DoMistake(
    key: '6.11/m6_earth_pit_test/wrong-electrode',
    textBn: 'এই ইলেক্ট্রোড ঠিক নয় — আর্থিং-এর জন্য ঠিক উপাদান আর দৈর্ঘ্য চাই: GI ছিদ্রযুক্ত পাইপ, 2.5-3 মিটার। বদলাতে বলুন।',
    art: '$_dir/wrong_electrode.svg',
    lessonPoint: 1,
  );
  static const ironNut = DoMistake(
    key: '6.11/m6_earth_pit_test/iron-nut',
    textBn: 'লোহার নাট-বল্টুতে সহজে মরিচা ধরে, জোড় দুর্বল হয়। আর্থিং জোড়ে পিতল বা স্টেইনলেস স্টিলের নাট-বল্টু।',
    art: '$_dir/iron_nut.svg',
    lessonPoint: 2,
  );
  static const noLid = DoMistake(
    key: '6.11/m6_earth_pit_test/no-lid',
    textBn: 'চেম্বার আর ঢাকনা ছাড়া পিট সুরক্ষিত নয়। ঢাকনা ঠিকমতো লাগিয়ে তবে সই।',
    art: '$_dir/no_lid.svg',
    lessonPoint: 2,
  );
  // Pro tip 1 (not a numbered point).
  static const samePit = DoMistake(
    key: '6.11/m6_earth_pit_test/same-pit',
    textBn: 'দুটো আর্থ এক পিটে দিলে ডাবল আর্থিং হয় না — পিটটা ব্যর্থ হলে দুটোই যাবে। দ্বিতীয় লিডের জন্য আলাদা পিট চাই।',
    art: '$_dir/same_pit.svg',
  );
  // Pro tip 4 (not a numbered point).
  static const highSigned = DoMistake(
    key: '6.11/m6_earth_pit_test/high-signed',
    textBn: 'মান 5 ওহমের বেশি — এমন আর্থে সই নয়। মাটি বুঝে মান কমান, তারপর আবার টেস্ট করুন।',
    art: '$_dir/high_signed.svg',
  );
  // The engineering facts (gravel raises the surface resistance).
  static const gravel = DoMistake(
    key: '6.11/m6_earth_pit_test/gravel',
    textBn: 'পাথরের কুচি মাটির রেজিস্ট্যান্স বাড়ায় — সুইচইয়ার্ডে ওটা দেওয়া হয় ওপরের মাটির রেজিস্ট্যান্স বাড়াতেই। মান কমাতে নয়।',
    art: '$_dir/gravel.svg',
  );

  /// Listening to his push is the act it pushes (X2/B1).
  static DoMistake push(M6PitPush p) => switch (p) {
        M6PitPush.anyRod => electrode,
        M6PitPush.looseOk => brokenSigned,
      };

  static const List<DoMistake> all = [brokenSigned, electrode, ironNut, noLid, samePit, highSigned, gravel];
}

/// One pit as the contractor left it (and its readings, dealt).
@immutable
class M6PitSpec {
  const M6PitSpec({
    required this.lidMissing,
    required this.electrode,
    required this.joint1,
    required this.joint2,
    required this.good,
    required this.high,
    required this.fixed,
  });

  final bool lidMissing;
  final M6Electrode electrode;

  /// The bottom joint (in the chamber) and the top joint (the lead's
  /// terminal on the plinth).
  final M6Nut joint1;
  final M6Nut joint2;

  /// The reading on good soil (1.8–3.9), on high soil (12–28) and after a
  /// remedy that fits (2.4–4.6). Never 5–8.
  final double good;
  final double high;
  final double fixed;

  List<M6Nut> get joints => [joint1, joint2];
  bool get hasIron => joint1 == M6Nut.iron || joint2 == M6Nut.iron;
  bool get hasOpen => joint1 == M6Nut.none || joint2 == M6Nut.none;
  int get faults => (lidMissing ? 1 : 0) + (m6ElectrodeGood(electrode) ? 0 : 1) + (hasIron ? 1 : 0) + (hasOpen ? 1 : 0);
}

@immutable
class M6PitDeal {
  const M6PitDeal({
    required this.soil,
    required this.pits,
    required this.shared,
    required this.coworkerPit,
    required this.push,
    required this.nuts,
    required this.remedies,
  });

  final M6Soil soil;

  /// Lead 0's pit and lead 1's pit. With [shared], lead 1 was bolted into
  /// pit 0 and pits[1] is the pit the crew digs at the peg (clean).
  final List<M6PitSpec> pits;
  final bool shared;

  /// The pit (round) the coworker comes in, and his push.
  final int coworkerPit;
  final M6PitPush push;

  /// The trays' order (dealt).
  final List<M6Nut> nuts;
  final List<M6Remedy> remedies;
}

/// The remedies that bring a high reading under the limit on [s] (lesson
/// point 4: water in dry weather; pro tip 3: more electrodes or bentonite
/// on rocky or sandy soil). Gravel never.
Set<M6Remedy> m6PitFits(M6Soil s) => switch (s) {
      M6Soil.loamWet => const {},
      M6Soil.loamDry => const {M6Remedy.water},
      M6Soil.rocky || M6Soil.sandy => const {M6Remedy.bentonite, M6Remedy.extra},
    };

/// The pushes that fit a pit (his line must fit the moment): myth 2 where a
/// wrong electrode stands; myth 1 where a joint's nut is off.
List<M6PitPush> m6PitPushesFor(M6PitSpec p) => [
      if (!m6ElectrodeGood(p.electrode)) M6PitPush.anyRod,
      if (p.hasOpen) M6PitPush.looseOk,
    ];

const _goodElectrodes = [M6Electrode.gi27, M6Electrode.gi25, M6Electrode.gi30];
const _badElectrodes = [M6Electrode.rod, M6Electrode.short, M6Electrode.bar];

M6PitDeal m6PitDeal(math.Random rng) {
  final soil = rng.nextBool() ? M6Soil.loamWet : const [M6Soil.loamDry, M6Soil.rocky, M6Soil.sandy][rng.nextInt(3)];
  final shared = rng.nextInt(10) < 3;
  final push = rng.nextBool() ? M6PitPush.anyRod : M6PitPush.looseOk;
  final cp = shared ? 0 : rng.nextInt(2);
  M6Nut goodNut() => rng.nextBool() ? M6Nut.brass : M6Nut.steel;
  double good() => (18 + rng.nextInt(22)) / 10;
  double high() => (120 + rng.nextInt(161)) / 10;
  double fixed() => (24 + rng.nextInt(23)) / 10;
  // Faults per contractor pit: [lidMissing, electrode, j1, j2].
  final lid = [false, false];
  final elec = [for (var i = 0; i < 2; i++) _goodElectrodes[rng.nextInt(3)]];
  final joints = [
    for (var i = 0; i < 2; i++) [goodNut(), goodNut()],
  ];
  final real = shared ? const [0] : const [0, 1];
  void addFault(int i, int kind) {
    switch (kind) {
      case 0:
        lid[i] = true;
      case 1:
        elec[i] = _badElectrodes[rng.nextInt(3)];
      case 2:
        // An iron nut on a joint that is not off.
        final j = joints[i][0] == M6Nut.none ? 1 : (joints[i][1] == M6Nut.none ? 0 : rng.nextInt(2));
        joints[i][j] = M6Nut.iron;
      case 3:
        final j = joints[i][0] == M6Nut.iron ? 1 : (joints[i][1] == M6Nut.iron ? 0 : rng.nextInt(2));
        joints[i][j] = M6Nut.none;
    }
  }

  for (final i in real) {
    if (rng.nextInt(4) == 0) addFault(i, 0);
    if (rng.nextInt(10) < 3) addFault(i, 1);
    if (rng.nextInt(10) < 3) addFault(i, 2);
    if (rng.nextInt(4) == 0) addFault(i, 3);
  }
  // His pit has what he talks about.
  if (push == M6PitPush.anyRod && m6ElectrodeGood(elec[cp])) addFault(cp, 1);
  if (push == M6PitPush.looseOk && !joints[cp].contains(M6Nut.none)) addFault(cp, 3);
  // One spare chamber set on the pallet: at most one pit without a lid.
  if (lid[0] && lid[1]) lid[1 - cp] = false;
  int count() => (shared ? 1 : 0) + [for (final i in real) (lid[i] ? 1 : 0) + (m6ElectrodeGood(elec[i]) ? 0 : 1) + (joints[i].contains(M6Nut.iron) ? 1 : 0) + (joints[i].contains(M6Nut.none) ? 1 : 0)].fold(0, (a, b) => a + b);
  // At least two things to put right in a play.
  for (var guard = 0; count() < 2 && guard < 20; guard++) {
    final i = real[rng.nextInt(real.length)];
    final kind = rng.nextInt(4);
    if (kind == 0 && (lid[1 - i])) continue;
    if (kind == 2 && joints[i].contains(M6Nut.iron)) continue;
    if (kind == 3 && joints[i].contains(M6Nut.none)) continue;
    if (kind == 2 && joints[i].contains(M6Nut.none) && joints[i].where((n) => n == M6Nut.none).length == 2) continue;
    addFault(i, kind);
  }
  final pits = [
    for (var i = 0; i < 2; i++)
      if (shared && i == 1)
        // The pit the crew digs at the peg: built right.
        M6PitSpec(lidMissing: false, electrode: M6Electrode.gi27, joint1: goodNut(), joint2: goodNut(), good: good(), high: high(), fixed: fixed())
      else
        M6PitSpec(lidMissing: lid[i], electrode: elec[i], joint1: joints[i][0], joint2: joints[i][1], good: good(), high: high(), fixed: fixed()),
  ];
  return M6PitDeal(
    soil: soil,
    pits: pits,
    shared: shared,
    coworkerPit: cp,
    push: push,
    nuts: [M6Nut.brass, M6Nut.steel, M6Nut.iron]..shuffle(rng),
    remedies: [...M6Remedy.values]..shuffle(rng),
  );
}

/// The play state (pure logic).
class M6PitRun {
  M6PitRun(this.deal) {
    _startRound();
  }
  final M6PitDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The pit is signed (its reason comes next).
  var roundDone = false;

  /// A needless replacement, pit or remedy this round (no thoroughness bonus).
  var wasted = false;

  /// The pit now.
  late M6Lid lid;
  late M6Electrode electrode;

  /// [0] the bottom joint, [1] the top joint; a fitted nut is loose until the
  /// spanner has made it snug.
  late List<M6Nut> nuts;
  late List<bool> tight;
  final List<double> _turned = [0, 0];

  /// The last reading (null: not tested since the last change; infinity: OL).
  double? reading;

  /// The chamber has been open this round (his cue); the tester's leads on.
  var opened = false;
  var leadsOn = false;

  /// With [M6PitDeal.shared], round 1: the crew has dug the separate pit.
  var dug = false;

  /// Remedies: one that fits brought it under; the high reading now.
  var remedyFit = false;
  M6Remedy? fitWith;
  late double highNow;
  var wet = false, bentonite = false, extra = false;

  /// The spare chamber set has been used (one a play).
  var spareUsed = false;

  /// What was put right this round (the reason and "আজ যা ধরলেন").
  var replaced = false, ironSwapped = false, jointFixed = false, lidFitted = false;

  /// The slips this pit has had (each kind once a pit).
  final Set<DoMistake> slipped = {};

  /// The mistake behind the last sign-off (slip, again or deadly).
  DoMistake? lastMistake;

  /// Round 0's pit and lead as signed (drawn in round 1).
  M6PitLook? _final0;
  M6Nut _final0Top = M6Nut.brass;

  M6PitSpec get spec => deal.pits[index.clamp(0, 1)];
  bool get done => index >= 2;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0 && !wasted;
  bool get _open => !ended && !roundDone;

  /// There is a pit for this lead (not the bare peg of a shared deal).
  bool get pitExists => !(deal.shared && index == 1 && !dug);
  bool get chamberOpen => pitExists && lid != M6Lid.on;
  bool get broken => nuts.contains(M6Nut.none) || tight.contains(false);

  /// A fitted nut waiting for the spanner (its joint), or null.
  int? get pendingTight {
    for (var j = 0; j < 2; j++) {
      if (nuts[j] != M6Nut.none && !tight[j]) return j;
    }
    return null;
  }

  /// The earth's resistance now (ignoring a broken path).
  double get value {
    if (!m6ElectrodeGood(electrode)) return highNow;
    if (!m6SoilHigh(deal.soil)) return spec.good;
    return remedyFit ? spec.fixed : highNow;
  }

  void _startRound() {
    final s = spec;
    lid = s.lidMissing ? M6Lid.missing : M6Lid.on;
    electrode = s.electrode;
    nuts = [s.joint1, s.joint2];
    tight = [for (final n in nuts) n != M6Nut.none];
    _turned
      ..[0] = 0
      ..[1] = 0;
    reading = null;
    opened = lid == M6Lid.missing && pitExists;
    leadsOn = false;
    dug = false;
    remedyFit = false;
    fitWith = null;
    highNow = s.high;
    wet = bentonite = extra = false;
    replaced = ironSwapped = jointFixed = lidFitted = false;
    slipped.clear();
    lastMistake = null;
    roundDone = false;
    roundSlips = 0;
    wasted = false;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  /// A slip of [m] (once a pit): true when it counts now.
  bool _slipOnce(DoMistake m) {
    lastMistake = m;
    if (slipped.contains(m)) return false;
    slipped.add(m);
    slips++;
    roundSlips++;
    return true;
  }

  // --- the lid ---------------------------------------------------------------
  bool liftLid() {
    if (!_open || !pitExists || lid != M6Lid.on) return false;
    lid = M6Lid.off;
    opened = true;
    return true;
  }

  bool closeLid() {
    if (!_open || lid != M6Lid.off) return false;
    lid = M6Lid.on;
    leadsOn = false;
    return true;
  }

  /// The spare ring and lid onto a pit that had none.
  bool fitSpare() {
    if (!_open || !pitExists || lid != M6Lid.missing || spareUsed) return false;
    lid = M6Lid.on;
    spareUsed = true;
    lidFitted = true;
    leadsOn = false;
    return true;
  }

  // --- the joints --------------------------------------------------------------
  /// Why joint [j] cannot be worked now, or null.
  M6PitGuard? jointGuard(int j) {
    if (!pitExists) return M6PitGuard.noPit;
    if (j == 0 && !chamberOpen) return M6PitGuard.lidFirst;
    return null;
  }

  /// A nut from the tray onto joint [j]: iron = slip (once a pit) and nothing
  /// fitted; brass or stainless goes on loose (the spanner makes it snug).
  DoMistake? fitNut(int j, M6Nut nut) {
    if (!_open || jointGuard(j) != null || nut == M6Nut.none) return null;
    if (nut == M6Nut.iron) return _slipOnce(M6EarthPitMistakes.ironNut) ? M6EarthPitMistakes.ironNut : null;
    nuts[j] = nut;
    tight[j] = false;
    _turned[j] = 0;
    reading = null;
    return null;
  }

  /// The spanner turned round joint [j] by [radians] (clockwise +; the other
  /// way does nothing). True when the nut became snug.
  bool turn(int j, double radians) {
    if (!_open || nuts[j] == M6Nut.none || tight[j]) return false;
    _turned[j] += math.max(0, radians);
    if (_turned[j] < kM6PitTurns * 2 * math.pi) return false;
    tight[j] = true;
    _turned[j] = 0;
    reading = null;
    return true;
  }

  double turned(int j) => _turned[j];

  // --- the tester and the actions ----------------------------------------------
  /// TEST: the reading (OL when the path is broken), or a guard.
  M6PitGuard? test() {
    if (!_open) return null;
    if (!pitExists) return M6PitGuard.noPit;
    if (!chamberOpen) return M6PitGuard.lidFirst;
    reading = broken ? double.infinity : value;
    leadsOn = true;
    return null;
  }

  /// The crew drives a right electrode; the bottom joint's clamp moves to it
  /// as it was (its nut stays the player's job). Returns a guard, or null.
  /// On a right electrode it is needless: nothing changes, [wasted].
  M6PitGuard? replace() {
    if (!_open) return null;
    if (!pitExists) return M6PitGuard.noPit;
    if (!chamberOpen) return M6PitGuard.lidFirst;
    if (m6ElectrodeGood(electrode)) {
      wasted = true;
      return null;
    }
    replaced = true;
    electrode = M6Electrode.gi27;
    reading = null;
    return null;
  }

  /// A shared deal's round 0: lead 2's own pit is the right call, but its
  /// turn comes with lead 2 ([dig] answers it with no cost).
  bool get digTooEarly => deal.shared && index == 0;

  /// The crew digs a separate pit at the peg for lead 1 (a shared deal):
  /// true. Round 0 of a shared deal: not yet, no cost ([digTooEarly]).
  /// Anywhere else needless (false, [wasted]).
  bool dig() {
    if (!_open || digTooEarly) return false;
    if (!deal.shared || index != 1 || dug) {
      wasted = true;
      return false;
    }
    dug = true;
    final s = spec;
    lid = M6Lid.on;
    electrode = s.electrode;
    nuts = [s.joint1, s.joint2];
    tight = [true, true];
    reading = null;
    return true;
  }

  /// A remedy from the tray: gravel = slip (once a pit), nothing done.
  /// One that fits a high reading brings it under the limit; another lowers
  /// it a little (never under) and costs the round's bonus, as does one on a
  /// reading already under, on a wrong electrode or on a broken path.
  DoMistake? remedy(M6Remedy r) {
    if (!_open || !chamberOpen) return null;
    if (r == M6Remedy.gravel) return _slipOnce(M6EarthPitMistakes.gravel) ? M6EarthPitMistakes.gravel : null;
    final needless = !broken && value <= kM6PitLimit;
    final fits = !broken && m6ElectrodeGood(electrode) && m6PitFits(deal.soil).contains(r);
    if (needless || !fits) wasted = true;
    final soilHigh = m6SoilHigh(deal.soil);
    if (m6ElectrodeGood(electrode) && soilHigh && !remedyFit && m6PitFits(deal.soil).contains(r)) {
      remedyFit = true;
      fitWith = r;
    } else if (value > kM6PitLimit) {
      final floor = 9.2 + (highNow * 7).floor() % 6 / 10;
      highNow = math.max(floor, (highNow * 0.8 * 10).roundToDouble() / 10);
    }
    switch (r) {
      case M6Remedy.water:
        wet = true;
      case M6Remedy.bentonite:
        bentonite = true;
      case M6Remedy.extra:
        extra = true;
      case M6Remedy.gravel:
        break;
    }
    reading = null;
    return null;
  }

  /// Sign-off: a guard (test first), a slip (refused), the same fault again
  /// (refused, no second slip), the deadly, or done.
  M6Sign sign() {
    if (!_open) return M6Sign.testFirst;
    if (!pitExists) return _slipOnce(M6EarthPitMistakes.samePit) ? M6Sign.slip : M6Sign.again;
    final r = reading;
    if (r == null) return M6Sign.testFirst;
    if (r.isInfinite) {
      deadly = lastMistake = M6EarthPitMistakes.brokenSigned;
      return M6Sign.deadly;
    }
    for (final (bad, m) in [
      (lid != M6Lid.on, M6EarthPitMistakes.noLid),
      (!m6ElectrodeGood(electrode), M6EarthPitMistakes.electrode),
      (nuts.contains(M6Nut.iron), M6EarthPitMistakes.ironNut),
      (r > kM6PitLimit, M6EarthPitMistakes.highSigned),
    ]) {
      if (bad) return _slipOnce(m) ? M6Sign.slip : M6Sign.again;
    }
    _done();
    return M6Sign.done;
  }

  void _done() {
    roundDone = true;
    final s = spec;
    jointFixed = s.hasOpen && !broken;
    ironSwapped = s.hasIron && !nuts.contains(M6Nut.iron);
    if (jointFixed) _tag(M6EarthPitLines.caughtJoint);
    if (dug) _tag(M6EarthPitLines.caughtSecond);
    if (replaced) _tag(M6EarthPitLines.caughtElectrode);
    if (remedyFit) _tag(M6EarthPitLines.caughtRemedy);
    if (ironSwapped) _tag(M6EarthPitLines.caughtIron);
    if (lidFitted) _tag(M6EarthPitLines.caughtLid);
    _tag(M6EarthPitLines.caughtSign);
  }

  /// The reason this pit asks: what was put right in it (never a fault the
  /// player slipped on first), else why it was signed.
  M6PitWhy get whyTopic {
    if (jointFixed) return M6PitWhy.joint;
    if (dug && !slipped.contains(M6EarthPitMistakes.samePit)) return M6PitWhy.secondPit;
    if (replaced && !slipped.contains(M6EarthPitMistakes.electrode)) return M6PitWhy.electrode;
    if (remedyFit && !slipped.contains(M6EarthPitMistakes.highSigned)) {
      return switch (fitWith) {
        M6Remedy.water => M6PitWhy.water,
        M6Remedy.bentonite => M6PitWhy.bentonite,
        _ => M6PitWhy.extra,
      };
    }
    if (ironSwapped && !slipped.contains(M6EarthPitMistakes.ironNut)) return M6PitWhy.iron;
    if (lidFitted && !slipped.contains(M6EarthPitMistakes.noLid)) return M6PitWhy.lid;
    return M6PitWhy.signed;
  }

  /// Listened to a slip-line coworker (each kind once a pit).
  DoMistake pushSlip(DoMistake m) {
    _slipOnce(m);
    return m;
  }

  /// Fails the play (listening to a deadly push).
  void failDeadly(DoMistake m) => deadly = m;

  /// How pit [i] is drawn now.
  M6PitLook lookOf(int i) {
    if (i == index && !done) {
      return M6PitLook(
        exists: pitExists,
        lid: lid,
        electrode: electrode,
        joint1: nuts[0],
        tight1: tight[0],
        wet: wet,
        bentonite: bentonite,
        extra: extra,
        secondLead: false,
      );
    }
    if (i == 0 && _final0 != null) return _final0!;
    final s = deal.pits[i];
    return M6PitLook(
      exists: !(deal.shared && i == 1 && !(index == 1 && dug)),
      lid: s.lidMissing ? M6Lid.missing : M6Lid.on,
      electrode: s.electrode,
      joint1: s.joint1,
      tight1: s.joint1 != M6Nut.none,
    );
  }

  /// Lead [lead]'s top joint as drawn now.
  (M6Nut, bool) topOf(int lead) {
    if (lead == index && !done) return (nuts[1], tight[1]);
    if (lead == 0 && _final0 != null) return (_final0Top, true);
    final n = deal.pits[lead].joint2;
    return (n, n != M6Nut.none);
  }

  void next() {
    if (index == 0) {
      _final0 = lookOf(0);
      _final0Top = nuts[1];
    }
    index++;
    if (!done) _startRound();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
/// ms, ~1500 per human action, per pit: lid up, look (~3000), one fix
/// (tray, ✓, spanner ≈ 6000) on most pits, TEST, a remedy on half the plays
/// (action, tray, ✓, TEST ≈ 6000), lid down, sign + ✓ ≈ 18000–24000; a
/// reason each (~8200 × 2) and the coworker once (~9600) ≈ 62000–74000.
/// 85 % ≈ 57000 → 65 s (a builder's estimate; owner may tune).
const m6EarthPitQuickMs = 65000;

@immutable
class M6EarthPitPack {
  const M6EarthPitPack({required this.id, required this.titleBn, this.quickMs = m6EarthPitQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6EarthPitPack> m6EarthPitPacks = {
  'do_6_11_a': M6EarthPitPack(id: 'do_6_11_a', titleBn: M6EarthPitLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M6EarthPitProbe {
  static M6PitRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M6EarthPitPage extends StatefulWidget {
  const M6EarthPitPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6EarthPitPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6EarthPitPage> createState() => _M6EarthPitPageState();
}

class _M6EarthPitPageState extends State<M6EarthPitPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PitRunPage(
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

class _PitRunPage extends ConsumerStatefulWidget {
  const _PitRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6EarthPitPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PitRunPage> createState() => _PitRunPageState();
}

/// What a pan is doing.
enum _Pan { none, lift, close, spare, spanner }

class _PitRunPageState extends ConsumerState<_PitRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6PitRun _run;
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

  /// The open tray (nut packets for a joint, or the remedies).
  M6PitTray _tray = M6PitTray.none;
  int _trayJoint = 0;

  /// The open preview (an action, a nut packet or a remedy) and those set
  /// aside (two-step picks).
  Object? _preview;
  Offset _previewAt = Offset.zero;
  final Set<Object> _aside = {};

  /// A pan in progress.
  _Pan _pan = _Pan.none;
  Offset _panFrom = Offset.zero;
  Offset _panNow = Offset.zero;
  double? _spannerAngle;
  double _spannerShown = 0;
  int _ratchet = 0;

  var _freeze = false;
  Completer<void>? _frozen;

  /// "ফল্ট হলে": the short replay before the pass panel (spec flow 8).
  var _replay = false;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M6PitAction, GlobalKey> _actionKeys = {for (final a in M6PitAction.values) a: GlobalKey()};
  final Map<Object, GlobalKey> _trayKeys = {for (final n in M6Nut.values) n: GlobalKey(), for (final r in M6Remedy.values) r: GlobalKey()};
  final _j1Key = GlobalKey();
  final _j2Key = GlobalKey();
  final _testKey = GlobalKey();
  final _spareKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M6PitGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6PitRun(m6PitDeal(widget.rng));
    M6EarthPitProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M6EarthPitProbe.run, _run)) M6EarthPitProbe.run = null;
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

  int get _pit => _run.index.clamp(0, 1);

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze;

  String get _task => switch (_tray) {
        M6PitTray.nuts => M6EarthPitLines.askNut,
        M6PitTray.remedies => M6EarthPitLines.askRemedy,
        M6PitTray.none => !_run.pitExists
            ? M6EarthPitLines.askPit
            : _run.pendingTight != null
                ? M6EarthPitLines.askTighten
                : _run.reading != null
                    ? (_run.reading!.isInfinite ? M6EarthPitLines.askCheck : M6EarthPitLines.askVerdict)
                    : _run.chamberOpen
                        ? M6EarthPitLines.askCheck
                        : M6EarthPitLines.askPit,
      };

  String _guardLine(M6PitGuard g) => switch (g) {
        M6PitGuard.lidFirst => M6EarthPitLines.lidFirst,
        M6PitGuard.testFirst => M6EarthPitLines.testFirst,
        M6PitGuard.noPit => M6EarthPitLines.noPit,
      };

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() {
      _wake++;
      _preview = null;
      _aside.clear();
      _tray = M6PitTray.none;
      _pan = _Pan.none;
      _spannerAngle = null;
    });
    // A pit with no chamber is open from the start: his cue comes now.
    _maybeCallHim();
    unawaited(_sayChain([_task]));
  }

  /// He is due when what he talks about is in front of the player: myth 2
  /// (any rod) once his pit's chamber is open on a wrong electrode; myth 1
  /// (a bit cut or loose) when the tester reads OL in his pit, the sign-off
  /// moment of ruling M6-9.
  void _maybeCallHim() {
    if (_run.index != _run.deal.coworkerPit || coworkerDone || coworkerDue) return;
    if (_pushFits && (_run.deal.push == M6PitPush.anyRod ? _run.opened : _run.reading?.isInfinite == true)) scheduleCoworker();
  }

  /// His line still fits the pit (never once it has been put right).
  bool get _pushFits => switch (_run.deal.push) {
        M6PitPush.anyRod => !m6ElectrodeGood(_run.electrode),
        M6PitPush.looseOk => _run.broken,
      };

  /// His pit: once he is due, every control waits for him.
  bool _waitForHim() => _run.index == _run.deal.coworkerPit && holdForCoworker();

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  void _guard(M6PitGuard g) {
    _tick();
    unawaited(_sayChain([_guardLine(g)]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tapScene(Offset p, M6PitGeo geo, Offset global) {
    if (!_canPlay || _tray != M6PitTray.none) {
      if (_canPlay) _hints.missTap();
      return;
    }
    final i = _pit;
    if (geo.jointHit(geo.joint1(i)).contains(p) && _run.pitExists) {
      _openJoint(0);
      return;
    }
    if (geo.jointHit(geo.joint2(i)).contains(p)) {
      _openJoint(1);
      return;
    }
    if (geo.testHit.contains(p)) {
      _test(global);
      return;
    }
    _hints.missTap();
  }

  void _openJoint(int j) {
    if (_waitForHim()) return;
    final g = _run.jointGuard(j);
    if (g != null) {
      _guard(g);
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _tray = M6PitTray.nuts;
      _trayJoint = j;
      _aside.clear();
    });
    unawaited(_sayChain([_task]));
  }

  void _test(Offset global) {
    if (_waitForHim()) return;
    final g = _run.test();
    if (g != null) {
      _guard(g);
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    _stepDone();
    _maybeCallHim();
    unawaited(_sayChain([_task]));
  }

  static double _wrap(double a) {
    var x = a;
    while (x > math.pi) {
      x -= 2 * math.pi;
    }
    while (x < -math.pi) {
      x += 2 * math.pi;
    }
    return x;
  }

  void _panStart(Offset p, M6PitGeo geo) {
    _pan = _Pan.none;
    _spannerAngle = null;
    if (!_canPlay || _tray != M6PitTray.none) return;
    final i = _pit;
    final pending = _run.pendingTight;
    if (pending != null) {
      final c = pending == 0 ? geo.joint1(i) : geo.joint2(i);
      if ((p - c).distance <= M6PitGeo.spannerReach) {
        if (_waitForHim()) return;
        final d = p - c;
        _spannerAngle = math.atan2(d.dy, d.dx);
        _pan = _Pan.spanner;
        setState(() => _wake++);
        return;
      }
    }
    if (_run.pitExists && _run.lid == M6Lid.on && geo.lidOnHit(i).contains(p)) {
      _pan = _Pan.lift;
    } else if (_run.lid == M6Lid.off && geo.lidOffHit(i).contains(p)) {
      _pan = _Pan.close;
    } else if (!_run.spareUsed && geo.spare.contains(p)) {
      _pan = _Pan.spare;
    } else {
      return;
    }
    _panFrom = p;
    _panNow = p;
  }

  void _panUpdate(Offset p, M6PitGeo geo) {
    if (_pan == _Pan.spanner) {
      final last = _spannerAngle;
      if (last == null || !_canPlay) {
        _pan = _Pan.none;
        return;
      }
      final pending = _run.pendingTight;
      if (pending == null) return;
      final c = pending == 0 ? geo.joint1(_pit) : geo.joint2(_pit);
      final d = p - c;
      if (d.distance < 4) return;
      final a = math.atan2(d.dy, d.dx);
      final da = _wrap(a - last);
      _spannerAngle = a;
      // Clockwise on screen (y down: the angle grows) tightens.
      final snug = _run.turn(pending, da);
      if (da > 0) {
        _spannerShown += da;
        if (++_ratchet % 6 == 0) _cue('sounds/intro/tick.ogg', volume: 0.3);
      }
      if (snug) {
        _pan = _Pan.none;
        _spannerAngle = null;
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.55);
        _stepDone();
        unawaited(_sayChain([_task]));
        return;
      }
      setState(() {});
      return;
    }
    if (_pan != _Pan.none) _panNow = p;
  }

  void _panEnd(M6PitGeo geo) {
    final pan = _pan;
    _pan = _Pan.none;
    if (pan == _Pan.spanner) {
      _spannerAngle = null;
      setState(() => _wake++);
      return;
    }
    if (pan == _Pan.none || !_canPlay) return;
    final dy = _panNow.dy - _panFrom.dy;
    final i = _pit;
    switch (pan) {
      case _Pan.lift:
        if (dy > -20) {
          _hints.missTap();
          return;
        }
        if (_run.liftLid()) {
          _tick('sounds/intro/impact_metal.ogg', 0.45);
          _stepDone();
          _maybeCallHim();
          unawaited(_sayChain([_task]));
        }
      case _Pan.close:
        if (dy < 16 && !geo.chamber(i).inflate(16).contains(_panNow)) {
          _hints.missTap();
          return;
        }
        if (_waitForHim()) return;
        if (_run.closeLid()) {
          _tick('sounds/intro/impact_metal.ogg', 0.5);
          _stepDone();
        }
      case _Pan.spare:
        final onPit = geo.chamber(i).inflate(24).contains(_panNow) || geo.lidOnHit(i).inflate(10).contains(_panNow);
        if (!onPit) {
          _hints.missTap();
          return;
        }
        if (_waitForHim()) return;
        if (_run.fitSpare()) {
          _tick('sounds/intro/impact_metal.ogg', 0.6);
          _stepDone();
        } else {
          _tick();
        }
      case _Pan.none || _Pan.spanner:
        break;
    }
  }

  // --- the actions and the trays (two-step picks) --------------------------------
  void _open(Object o, Offset global) {
    if (!_canPlay || _preview != null) return;
    setState(() {
      _preview = o;
      _previewAt = global;
    });
  }

  void _confirm() {
    final o = _preview;
    if (o == null) return;
    setState(() {
      _preview = null;
      _aside.clear();
    });
    switch (o) {
      case M6PitAction a:
        _act(a, _previewAt);
      case M6Nut n:
        _fitNut(n, _previewAt);
      case M6Remedy r:
        _remedy(r, _previewAt);
    }
  }

  void _reject() {
    final o = _preview;
    if (o == null) return;
    setState(() {
      _preview = null;
      _aside.add(o);
    });
  }

  void _closeTray() {
    if (_tray == M6PitTray.none) return;
    _tick();
    setState(() {
      _tray = M6PitTray.none;
      _aside.clear();
      _preview = null;
    });
  }

  void _act(M6PitAction a, Offset global) {
    if (!_canPlay) return;
    if (_waitForHim()) return;
    switch (a) {
      case M6PitAction.replace:
        final needless = m6ElectrodeGood(_run.electrode);
        final g = _run.replace();
        if (g != null) {
          _guard(g);
          return;
        }
        _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
        _stepDone();
        unawaited(_sayChain([needless ? M6EarthPitLines.needless : M6EarthPitLines.replaced]));
      case M6PitAction.dig:
        final early = _run.digTooEarly;
        final ok = _run.dig();
        _cue(ok ? 'sounds/intro/impact_metal.ogg' : 'sounds/intro/tick.ogg', volume: 0.55);
        _stepDone();
        unawaited(_sayChain([ok ? M6EarthPitLines.dug : (early ? M6EarthPitLines.digLater : M6EarthPitLines.needless)]));
      case M6PitAction.remedy:
        final g = !_run.pitExists
            ? M6PitGuard.noPit
            : !_run.chamberOpen
                ? M6PitGuard.lidFirst
                : _run.reading == null
                    ? M6PitGuard.testFirst
                    : null;
        if (g != null) {
          _guard(g);
          return;
        }
        _tick('sounds/intro/click.ogg', 0.5);
        setState(() {
          _tray = M6PitTray.remedies;
          _aside.clear();
        });
        unawaited(_sayChain([_task]));
      case M6PitAction.sign:
        _sign(global);
    }
  }

  void _fitNut(M6Nut n, Offset global) {
    if (!_canPlay) return;
    if (_waitForHim()) return;
    final j = _trayJoint;
    setState(() => _tray = M6PitTray.none);
    final m = _run.fitNut(j, n);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (n == M6Nut.iron) {
      _tick();
      unawaited(_sayChain([M6EarthPitLines.ironAgain]));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.55);
    _stepDone();
    unawaited(_sayChain([_task]));
  }

  void _remedy(M6Remedy r, Offset global) {
    if (!_canPlay) return;
    if (_waitForHim()) return;
    final under = !_run.broken && _run.value <= kM6PitLimit;
    setState(() => _tray = M6PitTray.none);
    final m = _run.remedy(r);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (r == M6Remedy.gravel) {
      _tick();
      unawaited(_sayChain([_task]));
      return;
    }
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    _stepDone();
    unawaited(_sayChain([under ? M6EarthPitLines.needless : M6EarthPitLines.retest]));
  }

  void _sign(Offset global) {
    final res = _run.sign();
    switch (res) {
      case M6Sign.testFirst:
        _guard(M6PitGuard.testFirst);
      case M6Sign.again:
        _tick();
        unawaited(_sayChain([M6EarthPitLines.again(_run.lastMistake!)]));
      case M6Sign.slip:
        setState(() => _wake++);
        unawaited(_mistake(_run.lastMistake!, global));
      case M6Sign.deadly:
        setState(() => _wake++);
        unawaited(_deadly(_run.lastMistake!));
      case M6Sign.done:
        _stepDone();
        unawaited(_roundDone());
    }
  }

  Future<void> _roundDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _run.whyTopic;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M6EarthPitLines.whyRight[topic]!, M6EarthPitLines.myths, widget.rng),
      question: M6EarthPitLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
  CoworkerScript get coworkerScript => M6EarthPitLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerPit || _run.roundDone || !_pushFits) return null;
    if (_intro || _card != null || tableBusy || _freeze || _preview != null || _tray != M6PitTray.none || !_run.opened) return false;
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
      final m = M6EarthPitMistakes.push(p);
      if (m.deadly) {
        _run.failDeadly(m);
        await _deadly(m);
        return;
      }
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6EarthPitLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6EarthPitLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6EarthPitLines.tapWhy[_nudgeN++ % M6EarthPitLines.tapWhy.length]
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
      _preview = null;
      _tray = M6PitTray.none;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6pit/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A broken earth signed: the scene freezes grey and the fault lights the
  /// DTR's body in colour; then near-miss or death.
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
      _preview = null;
      _tray = M6PitTray.none;
      _pan = _Pan.none;
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
    final speak = await SpokenOnce.first('m6pit/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6EarthPitLines.deadlyWord : M6EarthPitLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same pit goes on from where it was.
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
    if (_run.passed) {
      // A fault on the body now goes down the earth and the breaker trips.
      setState(() => _replay = true);
      await Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1900));
      if (!mounted) return;
    }
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
    await _say(!_run.passed ? M6EarthPitLines.fail : (_quickBonus ? M6EarthPitLines.quick : M6EarthPitLines.allSet),
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
    if (_pan != _Pan.none || _run.pendingTight != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6PitRig get _rig {
    final (t0, k0) = _run.topOf(0);
    final (t1, k1) = _run.topOf(1);
    final look0 = _run.lookOf(0);
    final look1 = _run.lookOf(1);
    // Lead 1 bolted into pit 0 (no pit at its peg): both leads in pit 0.
    final secondIn0 = !look1.exists;
    return M6PitRig(
      soil: _run.deal.soil,
      pits: [
        secondIn0
            ? M6PitLook(
                exists: look0.exists,
                lid: look0.lid,
                electrode: look0.electrode,
                joint1: look0.joint1,
                tight1: look0.tight1,
                wet: look0.wet,
                bentonite: look0.bentonite,
                extra: look0.extra,
                secondLead: true,
              )
            : look0,
        look1,
      ],
      joint2: [t0, t1],
      tight2: [k0, k1],
      current: _pit,
      lead: _pit,
      spareUsed: _run.spareUsed,
      leadsOn: _run.leadsOn && _run.chamberOpen,
    );
  }

  /// The gesture hand: how to touch, never what. A tray: a sweep over it. A
  /// nut waiting for the spanner: a short nudge round the joint, one way
  /// then the other (never a full turn). Otherwise, in turn, a nudge on the
  /// lid (up while it is on; sideways when lifted) or on the spare set, and a
  /// sweep over the joints, the tester and the four actions alike.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    final i = _pit;
    if (_tray == M6PitTray.nuts) return HintSpec.sweepOver([for (final x in _run.deal.nuts) _trayKeys[x]!]);
    if (_tray == M6PitTray.remedies) return HintSpec.sweepOver([for (final x in _run.deal.remedies) _trayKeys[x]!]);
    final pending = _run.pendingTight;
    if (pending != null) {
      final c = pending == 0 ? geo.joint1(i) : geo.joint2(i);
      final from = c + const Offset(0, -30);
      return HintSpec.drag(from, toward: Offset(n.isEven ? 1 : -1, 0.3), travel: 30, space: HintSpace.scene);
    }
    if (n.isEven) {
      if (_run.pitExists && _run.lid == M6Lid.on) return HintSpec.drag(geo.lidOn(i).center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      if (_run.lid == M6Lid.off) return HintSpec.drag(geo.lidOff(i).center, toward: Offset((n ~/ 2).isEven ? 1 : -1, 0), travel: 30, space: HintSpace.scene);
      if (_run.lid == M6Lid.missing && !_run.spareUsed) return HintSpec.drag(geo.spare.center, toward: const Offset(1, 0), travel: 36, space: HintSpace.scene);
    }
    return HintSpec.sweepOver([
      _j2Key,
      if (_run.chamberOpen) _j1Key,
      _testKey,
      for (final a in M6PitAction.values) _actionKeys[a]!,
    ]);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6PitGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final i = _pit;
    final pending = _run.pendingTight;
    final showTag = _run.pitExists && _run.chamberOpen && !_run.done;
    final reading = _run.reading;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('site'),
                child: RepaintBoundary(child: CustomPaint(painter: M6PitWorldPainter(geo: geo, rig: _rig))),
              ),
              if (pending != null)
                Positioned.fill(
                  key: ValueKey('spanner-$i-$pending'),
                  child: RepaintBoundary(
                    child: CustomPaint(painter: M6PitSpannerPainter(at: pending == 0 ? geo.joint1(i) : geo.joint2(i), angle: _spannerShown)),
                  ),
                ),
              // The tester's name and its reading (a bare number).
              Positioned(
                key: const ValueKey('tester-name'),
                left: geo.tester.left,
                width: geo.tester.width,
                top: geo.tester.top + 2,
                child: Text(kEarthTesterBn,
                    textAlign: TextAlign.center, maxLines: 1, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
              ),
              Positioned.fromRect(
                key: const ValueKey('tester-reading'),
                rect: geo.display,
                child: Semantics(
                  label: M6EarthPitLines.reading(reading),
                  excludeSemantics: true,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(M6EarthPitLines.reading(reading),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C2418), fontFeatures: [FontFeature.tabularFigures()])),
                    ),
                  ),
                ),
              ),
              if (showTag)
                Positioned(
                  key: ValueKey('tag-$i-${_run.electrode.name}'),
                  left: geo.chamber(i).left + 2,
                  width: geo.chamber(i).width - 4,
                  top: geo.joint1(i).dy + 12,
                  child: Semantics(
                    label: M6EarthPitLines.tagOf(_run.electrode),
                    excludeSemantics: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1DE),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFF8A6A3C), width: 1),
                      ),
                      child: Text(M6EarthPitLines.tagOf(_run.electrode),
                          textAlign: TextAlign.center, style: bangla(fontSize: 8, fontWeight: FontWeight.w800, height: 1.15, color: const Color(0xFF2A2018))),
                    ),
                  ),
                ),
              Positioned.fromRect(
                key: ValueKey('trainee-$i'),
                rect: geo.trainee(i),
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      // The controls' places, for the sweep (no paint).
      for (final (k, r) in [
        (_j1Key, geo.jointHit(geo.joint1(i))),
        (_j2Key, geo.jointHit(geo.joint2(i))),
        (_testKey, geo.testHit),
        (_spareKey, geo.spare),
      ])
        Positioned.fromRect(
          key: ValueKey('box-${k.hashCode}'),
          rect: r,
          child: IgnorePointer(child: SizedBox.expand(key: k)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6EarthPitLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: () {
              _pan = _Pan.none;
              _spannerAngle = null;
            },
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
              builder: (_, v, _) => CustomPaint(painter: M6PitFlashPainter(at: geo.flashAt, v: v)),
            ),
          ),
        ),
      if (_replay)
        Positioned.fill(
          key: const ValueKey('fault-replay'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1700),
              builder: (_, v, _) => CustomPaint(painter: M6PitTripPainter(geo: geo, v: v)),
            ),
          ),
        ),
      // The next lead: a short fade.
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

  String _previewText(Object o) => switch (o) {
        M6PitAction a => M6EarthPitLines.action(a),
        M6Nut n => M6EarthPitLines.nut(n),
        M6Remedy r => M6EarthPitLines.remedy(r),
        _ => '',
      };

  IconData _iconOf(Object o) => switch (o) {
        M6PitAction a => _actionIcons[a]!,
        M6Nut _ => Icons.hexagon_outlined,
        M6Remedy r => _remedyIcons[r]!,
        _ => Icons.circle_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final List<Object> row = switch (_tray) {
      M6PitTray.none => M6PitAction.values,
      M6PitTray.nuts => _run.deal.nuts,
      M6PitTray.remedies => _run.deal.remedies,
    };
    final slots = row.length + (_tray == M6PitTray.none ? 0 : 1);
    final btnW = math.min(92.0, (size.width - 8) / slots);
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
              labels: [for (var k = 1; k <= 2; k++) M6EarthPitLines.lead(k)],
              done: {for (var k = 0; k < math.min(_run.index, 2); k++) k},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _preview == null,
            hintKey: '${_run.index}/$_steps/${_tray.name}/${_run.lid.name}/${_run.pendingTight}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn)
                Positioned(
                  key: ValueKey('hud-row-${_run.index}-${_tray.name}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final o in row)
                        CardAside(
                          aside: _aside.contains(o),
                          child: _RowButton(
                            key: o is M6PitAction ? _actionKeys[o] : _trayKeys[o],
                            icon: _iconOf(o),
                            tint: o is M6Nut ? _nutTint[o] : null,
                            label: _previewText(o),
                            width: btnW,
                            onTap: (g) => _open(o, g),
                          ),
                        ),
                      if (_tray != M6PitTray.none)
                        _RowButton(
                          key: const ValueKey('tray-close'),
                          icon: Icons.close_rounded,
                          label: M6EarthPitLines.trayClose,
                          width: btnW,
                          onTap: (_) => _closeTray(),
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (handsOn && _preview != null)
                Positioned.fill(
                  key: ValueKey('preview-$_preview'),
                  child: CardPreviewOverlay(
                    textBn: _previewText(_preview!),
                    icon: _iconOf(_preview!),
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirm,
                    onReject: _reject,
                  ),
                ),
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
                  line: M6EarthPitLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 2, muted: _muted)),
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

  static const _actionIcons = {
    M6PitAction.replace: Icons.swap_vert_rounded,
    M6PitAction.dig: Icons.landscape_rounded,
    M6PitAction.remedy: Icons.tune_rounded,
    M6PitAction.sign: Icons.draw_rounded,
  };
  static const _remedyIcons = {
    M6Remedy.water: Icons.water_drop_rounded,
    M6Remedy.bentonite: Icons.inventory_2_rounded,
    M6Remedy.extra: Icons.vertical_align_bottom_rounded,
    M6Remedy.gravel: Icons.grain_rounded,
  };
  static const _nutTint = {
    M6Nut.brass: Color(0xFFF4D27A),
    M6Nut.steel: Color(0xFFE6EBF0),
    M6Nut.iron: Color(0xFFB0805A),
  };
}

// ============================================================================
// Pieces
// ============================================================================

/// One button under the scene: a round icon with its name under it (all
/// alike; a nut packet's icon takes its metal's colour, as a real packet).
class _RowButton extends StatelessWidget {
  const _RowButton({super.key, required this.icon, required this.label, required this.onTap, this.width = 90, this.tint});
  final IconData icon;
  final String label;
  final double width;
  final Color? tint;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: tint ?? SlmColors.gold300),
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
