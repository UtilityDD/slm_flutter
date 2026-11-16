import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
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
import 'm7_clearance_survey_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_clearance_survey_world.dart' show M7ClrGeo, M7ClrLayout, M7ClrPlace, M7ClrPoint, M7ClrVolt, m7ClrPlate;

// Lesson 7.3 "ন্যূনতম ক্লিয়ারেন্স: আইনত কতটা দূরত্ব?", কাজ 1 "আইনের মাপজোখ"
// (pack do_7_3_a, engineType m7_clearance_survey). A patrol along a
// semi-urban road: three sites, one of each kind, dealt fresh and shuffled
// (lesson 7.3 sections 1–2; numbers per the live text and rulings X5/M7-7):
//
//  * a span across the road — measure the wire's lowest point (mid-span) to
//    the road: LT 5.8 m, 11 kV and 33 kV 6.5 m;
//  * a house under the line — the চিলেকোঠা top (or the roof, when the house
//    has none) to the wire: LT 2.5 m, HT 3.7 m;
//  * a house beside the line — the balcony's edge (or the wall) to the
//    conductor: LT 1.2 m, 33 kV 2.0 m (side sites are 415 V or 33 kV only,
//    M7-7).
//
// Each site: stretch the two-handled tape — drag one handle onto a point,
// then the other; the handles snap to every feature alike (the wire, the
// poles' crossarms, the road, the kerb, the roof, the চিলেকোঠা top, a window
// sill, the house's foot, the wall, the balcony edge); the tape locks to its
// longer axis and the reading shows only once both are down (one decimal).
// Re-drag freely. 'লিখুন' writes it in the register: the wrong two points =
// slip (the tape goes back to its case). Then the register row: the
// 'আইনের ন্যূনতম' drum (only 1.2 · 2.0 · 2.5 · 3.7 · 5.8 · 6.5, a random start;
// swipe it up or down) and the verdict, a stamp dragged onto the row
// ('আইন মেনে' / 'মাপে কম', equal, their sides swapped per play). The drum is
// checked first (a wrong rule = slip), then the verdict (a missed short gap
// or a needless report = slip). A short gap: hold the phone to call the
// supervisor (lesson 7.3 section 4: reporting is the lineman's duty). An old
// span at 6.1 m is 'below today's 6.5 m rule — report it', never called
// illegal (ruling A2): the verdict stamp says 'মাপে কম'.
//
// The careless coworker comes once a play, on the first short site, after
// the stamp lands and before the phone works (holdForCoworker on the phone):
// myth 2 word for word. Listening = slip (X2/B1: what he pushes, not
// reporting, is a slip); the call still has to be made.
//
// No deadly act in this level (ruling M7-6). Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m7_clearance_survey_world.dart), corner guide, a finished site
// puts ◆ on the table → "কেন …?" → the next site. Gesture hands: a short
// straight nudge of a free handle out of its case (the same at every site),
// a tap on 'লিখুন' (the one way on), a swipe up or down on the drum and a sweep
// over both stamps, a hold on the phone. Decks have their own sweep.

// ============================================================================
// Content
// ============================================================================

/// Where a site stands.
enum M7ClrStage { measure, rule, phone }

/// What a site's reason asks about (always something the player did).
enum M7ClrWhy { lowPoint, roadHt, roadLt, chile, edge, legal, short, report }

/// The drum's only values (tenths of a metre; lesson 7.3, ruling X5).
const List<int> kM7ClrDrum = [12, 20, 25, 37, 58, 65];

/// The legal minimum for a place and voltage (tenths of a metre).
int m7ClrRuleT(M7ClrPlace p, M7ClrVolt v) => switch (p) {
      M7ClrPlace.road => v == M7ClrVolt.lt ? 58 : 65,
      M7ClrPlace.roof => v == M7ClrVolt.lt ? 25 : 37,
      // The live lesson: LT 1.2 m, HT up to 11 kV 1.2 m, above 11 kV to
      // 33 kV 2.0 m. Side sites are dealt on 415 V or 33 kV only (M7-7).
      M7ClrPlace.side => v == M7ClrVolt.kv33 ? 20 : 12,
    };

/// A reading in tenths → '5.9 মি' (English digits).
String m7ClrMetres(int t) => enDigits('${(t / 10).toStringAsFixed(1)} মি');

abstract final class M7ClearanceSurveyLines {
  static const title = 'আইনের মাপজোখ';
  // DRAFT wording — owner (M6-12 / M7-10).
  static const intro = 'টহলে বেরিয়েছেন। লাইন কি আইন মেনে আছে? মেপে দেখুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askSite = 'এখানকার ক্লিয়ারেন্স মাপুন।';
  static const askSiteOther = 'ফিতে টেনে তার আর বাড়ি বা রাস্তার ফাঁকটা মাপুন।';
  static const askWrite = 'মাপ ঠিক জায়গা থেকে হলে রেজিস্টারে লিখুন।';
  static const askRule = 'এখানে আইনের ন্যূনতম কত? চাকা ঘুরিয়ে বসান, তারপর রায়ের ছাপ দিন।';
  static const askPhone = 'মাপে কম — ফোন চেপে ধরে সুপারভাইজারকে জানান।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askSite, askSiteOther, askWrite, askRule, askPhone];

  // On-screen words (a worker's own; not spoken).
  static const write = 'লিখুন';
  static const sceneLabel = 'টহলের পথ';
  static const registerLabel = 'টহল রেজিস্টার';
  static const measured = 'মাপ';
  static const drumLabel = 'আইনের ন্যূনতম';
  static const slotLabel = 'রায়';
  static const stampLegal = 'আইন মেনে';
  static const stampShort = 'মাপে কম';
  static const phone = 'ফোন চেপে ধরুন';
  static String siteName(int n) => enDigits('জায়গা $n');

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M7ClrWhy, String>{
    M7ClrWhy.lowPoint: 'কেন মাঝখানের সবচেয়ে নিচু জায়গায় মাপলেন?',
    M7ClrWhy.roadHt: 'কেন এখানে 6.5 মিটার লাগবে?',
    M7ClrWhy.roadLt: 'কেন এখানে 5.8 মিটার লাগবে?',
    M7ClrWhy.chile: 'কেন চিলেকোঠা থেকে মাপলেন?',
    M7ClrWhy.edge: 'কেন বারান্দার কিনারা থেকে মাপলেন?',
    M7ClrWhy.legal: 'কেন এটা আইন মেনে আছে?',
    M7ClrWhy.short: 'কেন এটা মাপে কম?',
    M7ClrWhy.report: 'কেন সুপারভাইজারকে জানালেন?',
  };
  static const whyRight = <M7ClrWhy, List<String>>{
    M7ClrWhy.lowPoint: ['আইনের মাপ মাটি থেকে তারের সবচেয়ে নিচু জায়গা', 'দুই পোলের মাঝে তার সবচেয়ে বেশি ঝোলে, ফাঁক কম'],
    M7ClrWhy.roadHt: ['HT লাইন রাস্তা পার হলে অন্তত 6.5 মিটার উঁচু', '11 kV, 33 kV লাইন রাস্তা পার হলে 6.5 মিটার'],
    M7ClrWhy.roadLt: ['LT লাইন রাস্তা পার হলে অন্তত 5.8 মিটার উঁচু', 'বাস-ট্রাক নিরাপদে যেতে LT লাইনে 5.8 মিটার'],
    M7ClrWhy.chile: ['তার চিলেকোঠার ওপর দিয়ে, ফাঁক ওখানেই সবচেয়ে কম', 'চিলেকোঠাই তারের সবচেয়ে কাছে, মাপ ওখান থেকে'],
    M7ClrWhy.edge: ['বারান্দার কিনারাই তারের সবচেয়ে কাছের জায়গা', 'বারান্দায় লোক দাঁড়ায়, কিনারা থেকেই ফাঁক মাপি'],
    M7ClrWhy.legal: ['মাপটা আইনের ন্যূনতম মাপের চেয়ে বেশি পেলাম', 'এই জায়গা আর ভোল্টেজের নিয়মের চেয়ে ফাঁক বেশি'],
    M7ClrWhy.short: ['মাপটা আইনের ন্যূনতম মাপের চেয়েও কম পেলাম', 'এই জায়গা আর ভোল্টেজের নিয়মের চেয়ে ফাঁক কম'],
    M7ClrWhy.report: ['নিয়মের কম দেখলে রিপোর্ট করা আমার দায়িত্ব', 'দুর্ঘটনার আগেই ঠিক করাতে সুপারভাইজারকে জানাই'],
  };
  static const myths = [
    'একটু কম হলে কিছু হয় না, কেউ মাপতে আসে না',
    'চোখের আন্দাজে ঠিক লাগলে মেপে দেখার দরকার নেই',
    'পোলের মাথা থেকে মাপলেই সবচেয়ে ঠিক মাপ হয়',
    'শীতে মাপ ঠিক থাকলে গরমকালেও তার একই থাকে',
    'পুরনো লাইন হলে রিপোর্ট করার কোনো দরকার নেই',
    'সব ভোল্টেজের লাইনে একই দূরত্ব রাখলেই চলে',
    'ছাদ থেকে তার দূরে হলে বাঁশ রাখলেও ক্ষতি নেই',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (once a play, on the first short site, after the
  // stamp, before the phone): lesson 7.3 myth 2 word for word (M7-10).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'ক্লিয়ারেন্স একটু কম হলে কিছু হয় না, কেউ তো আর মাপতে আসছে না।',
    exitLine: coworkerExit,
    right: ['মাপ কম — এখনই সুপারভাইজারকে জানাব', 'আইন মানা আমার কর্তব্য — রিপোর্ট করব', 'না, মাপ কম দেখেছি, ফোন করে জানাব'],
    wrong: [
      'একটু কম তো, থাক, রিপোর্ট লিখব না',
      'কেউ তো মাপবে না, ঠিক আছে লিখে দিই',
      'পরে দেখা যাবে, এখন ফোন না করে চলুন',
      'এতটুকু কমে কিছু হয় না, ছেড়ে দিই',
      'রিপোর্ট করলে ঝামেলা বাড়বে, থাক বরং',
    ],
    asks: ['কী করবেন?', 'উনি বলছেন রিপোর্ট লাগবে না। আপনি কী করবেন?', 'ওর কথা শুনবেন, না আইন মানবেন?'],
  );
  static const callHeld = 'ঠিক! মাপ কম দেখলে জানানোই নিয়ম।';

  static const allSet = 'তিন জায়গাই মেপে দেখেছেন — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ঠিক জায়গা থেকে মাপুন, তারপর আইনের মাপ মেলান।';

  // "আজ যা ধরলেন".
  static const caughtLow = 'তারের সবচেয়ে নিচু জায়গা থেকে মাপ';
  static const caughtTop = 'তারের নিচের সবচেয়ে উঁচু জায়গা থেকে মাপ';
  static const caughtNear = 'বাড়ির সবচেয়ে কাছের জায়গা থেকে মাপ';
  static const caughtRule = 'জায়গা আর ভোল্টেজ মিলিয়ে আইনের মাপ';
  static const caughtLegal = 'আইন মেনে থাকা লাইন চিনেছেন';
  static const caughtReport = 'মাপে কম — সুপারভাইজারকে জানানো';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new line (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until
  /// then the device voice). Only the kit's own praise and 'wrong' bags are
  /// left out.
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
        for (final m in M7ClearanceSurveyMistakes.all) m.textBn,
      }.toList();
}

abstract final class M7ClearanceSurveyMistakes {
  static const _dir = 'assets/game/art/m7_clearance_survey';

  // DRAFT wording — owner (M6-12). Lesson 7.3 points: 0 = ground clearance,
  // 1 = building clearance, 3 = the consequences (reporting is the duty).
  static const pointsRoad = DoMistake(
    key: '7.3/m7_clearance_survey/points-road',
    textBn: 'রাস্তার ওপর মাপ হয় তারের সবচেয়ে নিচু জায়গা থেকে — দুই পোলের মাঝখানে — সোজা নিচে রাস্তা পর্যন্ত। পোলের মাথা থেকে নয়।',
    art: '$_dir/points_road.svg',
    lessonPoint: 0,
  );
  static const pointsRoof = DoMistake(
    key: '7.3/m7_clearance_survey/points-roof',
    textBn: 'বাড়ির ওপর দিয়ে গেলে মাপ হয় তারের ঠিক নিচের সবচেয়ে উঁচু জায়গা থেকে — চিলেকোঠা থাকলে তার মাথা, না থাকলে ছাদ।',
    art: '$_dir/points_roof.svg',
    lessonPoint: 1,
  );
  static const pointsSide = DoMistake(
    key: '7.3/m7_clearance_survey/points-side',
    textBn: 'বাড়ির পাশ দিয়ে গেলে মাপ হয় তার থেকে বাড়ির সবচেয়ে কাছের জায়গা পর্যন্ত — বারান্দা থাকলে তার কিনারা, না থাকলে দেওয়াল।',
    art: '$_dir/points_side.svg',
    lessonPoint: 1,
  );
  static const ruleRoad = DoMistake(
    key: '7.3/m7_clearance_survey/rule-road',
    textBn: 'রাস্তা পার হলে: LT লাইন অন্তত 5.8 মিটার, 11 kV আর 33 kV লাইন আজকের নিয়মে 6.5 মিটার। পোলের প্লেটে ভোল্টেজ দেখে নিন।',
    art: '$_dir/rule_table.svg',
    lessonPoint: 0,
  );
  static const ruleRoof = DoMistake(
    key: '7.3/m7_clearance_survey/rule-roof',
    textBn: 'ছাদ বা চিলেকোঠার ওপর দিয়ে গেলে: LT লাইন অন্তত 2.5 মিটার, HT লাইন 3.7 মিটার। পোলের প্লেটে ভোল্টেজ দেখে নিন।',
    art: '$_dir/rule_table.svg',
    lessonPoint: 1,
  );
  static const ruleSide = DoMistake(
    key: '7.3/m7_clearance_survey/rule-side',
    textBn: 'বারান্দা বা দেওয়ালের পাশ দিয়ে গেলে: LT লাইন অন্তত 1.2 মিটার, 33 kV লাইন 2.0 মিটার। পোলের প্লেটে ভোল্টেজ দেখে নিন।',
    art: '$_dir/rule_table.svg',
    lessonPoint: 1,
  );
  static const missed = DoMistake(
    key: '7.3/m7_clearance_survey/missed',
    textBn: 'মাপ আজকের নিয়মের ন্যূনতমের চেয়ে কম — এটা “আইন মেনে” নয়। নিয়মের কম দেখলে রিপোর্ট করা আপনার দায়িত্ব।',
    art: '$_dir/missed.svg',
    lessonPoint: 3,
  );
  static const falseReport = DoMistake(
    key: '7.3/m7_clearance_survey/false-report',
    textBn: 'মাপ আইনের ন্যূনতমের চেয়ে বেশি — লাইন নিয়ম মেনেই আছে। না মেপে, না মিলিয়ে অকারণে রিপোর্ট করবেন না।',
    art: '$_dir/false_report.svg',
    lessonPoint: 3,
  );
  static const listen = DoMistake(
    key: '7.3/m7_clearance_survey/listen',
    textBn: 'কেউ মাপতে না এলেও আইন মানা আপনার কর্তব্য। দুর্ঘটনার পর তদন্তে সব মাপা হয় — মাপ কম দেখলে সুপারভাইজারকে জানান।',
    art: '$_dir/listen.svg',
    lessonPoint: 3,
  );

  static DoMistake points(M7ClrPlace p) => switch (p) {
        M7ClrPlace.road => pointsRoad,
        M7ClrPlace.roof => pointsRoof,
        M7ClrPlace.side => pointsSide,
      };

  static DoMistake rule(M7ClrPlace p) => switch (p) {
        M7ClrPlace.road => ruleRoad,
        M7ClrPlace.roof => ruleRoof,
        M7ClrPlace.side => ruleSide,
      };

  static const List<DoMistake> all = [pointsRoad, pointsRoof, pointsSide, ruleRoad, ruleRoof, ruleSide, missed, falseReport, listen];
}

/// One site of the patrol.
@immutable
class M7ClrSite {
  M7ClrSite({
    required this.place,
    required this.volt,
    required this.readingT,
    required this.why,
    this.sagT = 8,
    this.chile = true,
    this.balcony = true,
    this.mirror = false,
    this.drumStart = 0,
  }) : layout = m7ClrLayout(place: place, readingT: readingT, mirror: mirror, sagT: sagT, chile: chile, balcony: balcony);

  final M7ClrPlace place;
  final M7ClrVolt volt;

  /// The true clearance (tenths of a metre).
  final int readingT;
  final M7ClrWhy why;
  final int sagT;
  final bool chile;
  final bool balcony;
  final bool mirror;

  /// The drum's start (an index into [kM7ClrDrum]).
  final int drumStart;

  /// The drawing (built once: painters compare it by identity).
  final M7ClrLayout layout;

  int get ruleT => m7ClrRuleT(place, volt);
  bool get legal => readingT >= ruleT;
  bool get ht => volt != M7ClrVolt.lt;

  /// The reading lies between the LT and the HT minimum for its place: a
  /// value legal for LT but short for HT.
  bool get crossover => ht ? !legal : legal;

  /// The two points the clearance is measured between.
  Set<M7ClrPoint> get rightPair => switch (place) {
        M7ClrPlace.road => const {M7ClrPoint.wireLow, M7ClrPoint.roadMid},
        M7ClrPlace.roof => chile ? const {M7ClrPoint.wireTop, M7ClrPoint.chileTop} : const {M7ClrPoint.wireTop, M7ClrPoint.roofTop},
        M7ClrPlace.side => balcony ? const {M7ClrPoint.conductor, M7ClrPoint.balconyEdge} : const {M7ClrPoint.conductor, M7ClrPoint.wallFace},
      };
}

@immutable
class M7ClrDeal {
  const M7ClrDeal({required this.sites, required this.coworkerSite, required this.stampsSwapped});

  final List<M7ClrSite> sites;

  /// The site the coworker comes on (the first short one).
  final int coworkerSite;

  /// 'মাপে কম' stands left of 'আইন মেনে'.
  final bool stampsSwapped;
}

M7ClrDeal m7ClrDeal(math.Random rng) {
  final places = [...M7ClrPlace.values]..shuffle(rng);
  late List<M7ClrVolt> volts;
  late List<bool> legal;
  // At least one legal and one short site, and one reading legal for LT but
  // short for HT (an LT site that passes or an HT site that fails).
  for (;;) {
    volts = [
      for (final p in places)
        p == M7ClrPlace.side ? (rng.nextBool() ? M7ClrVolt.lt : M7ClrVolt.kv33) : M7ClrVolt.values[rng.nextInt(3)],
    ];
    legal = [for (var i = 0; i < 3; i++) rng.nextBool()];
    final cross = [for (var i = 0; i < 3; i++) volts[i] == M7ClrVolt.lt ? legal[i] : !legal[i]];
    if (legal.contains(true) && legal.contains(false) && cross.contains(true)) break;
  }
  final sites = <M7ClrSite>[];
  for (var i = 0; i < 3; i++) {
    final p = places[i];
    final v = volts[i];
    final off = 1 + rng.nextInt(6);
    final rule = m7ClrRuleT(p, v);
    final reading = legal[i] ? rule + off : rule - off;
    final chile = rng.nextInt(4) > 0;
    final balcony = rng.nextInt(4) > 0;
    final verdictWhy = legal[i] ? M7ClrWhy.legal : (rng.nextBool() ? M7ClrWhy.short : M7ClrWhy.report);
    final whys = switch (p) {
      M7ClrPlace.road => [M7ClrWhy.lowPoint, v == M7ClrVolt.lt ? M7ClrWhy.roadLt : M7ClrWhy.roadHt, verdictWhy],
      M7ClrPlace.roof => [if (chile) M7ClrWhy.chile, verdictWhy],
      M7ClrPlace.side => [if (balcony) M7ClrWhy.edge, verdictWhy],
    };
    sites.add(M7ClrSite(
      place: p,
      volt: v,
      readingT: reading,
      why: whys[rng.nextInt(whys.length)],
      sagT: 4 + rng.nextInt(9),
      chile: chile,
      balcony: balcony,
      mirror: rng.nextBool(),
      drumStart: rng.nextInt(kM7ClrDrum.length),
    ));
  }
  return M7ClrDeal(sites: sites, coworkerSite: legal.indexOf(false), stampsSwapped: rng.nextBool());
}

/// The play state (pure logic).
class M7ClrRun {
  M7ClrRun(this.deal) {
    _startSite();
  }
  final M7ClrDeal deal;

  int index = 0;
  int slips = 0;
  int siteSlips = 0;
  final List<String> caught = [];

  /// The site's last step is in (its reason comes next).
  var roundDone = false;
  var stage = M7ClrStage.measure;

  /// Where each handle sits (null = in its case).
  final List<M7ClrPoint?> handles = [null, null];

  /// The drum's place now (an index into [kM7ClrDrum]).
  int drum = 0;

  /// The reading written in the register (tenths), once written.
  int? writtenT;

  int get count => deal.sites.length;
  M7ClrSite get site => deal.sites[index.clamp(0, count - 1)];
  bool get done => index >= count;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => siteSlips == 0;
  bool get _open => !done && !roundDone;
  int get drumT => kM7ClrDrum[drum];

  /// The tape's reading (tenths) when both handles are down.
  int? get readingT {
    final a = handles[0], b = handles[1];
    if (a == null || b == null) return null;
    final pts = site.layout.points;
    return M7ClrLayout.readingT(pts[a]!, pts[b]!);
  }

  void _startSite() {
    stage = M7ClrStage.measure;
    roundDone = false;
    siteSlips = 0;
    handles[0] = null;
    handles[1] = null;
    drum = site.drumStart;
    writtenT = null;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    siteSlips++;
    return m;
  }

  /// A handle let go on [p] (the other handle cannot share it).
  bool put(int h, M7ClrPoint p) {
    if (!_open || stage != M7ClrStage.measure) return false;
    if (handles[1 - h] == p || !site.layout.points.containsKey(p)) return false;
    handles[h] = p;
    return true;
  }

  /// A handle picked up (or let go on nothing: back in its case).
  bool lift(int h) {
    if (!_open || stage != M7ClrStage.measure) return false;
    handles[h] = null;
    return true;
  }

  /// 'লিখুন': the wrong two points = slip and the tape goes back.
  DoMistake? write() {
    if (!_open || stage != M7ClrStage.measure || readingT == null) return null;
    final pair = {handles[0]!, handles[1]!};
    if (!setEquals(pair, site.rightPair)) {
      handles[0] = null;
      handles[1] = null;
      return _slip(M7ClearanceSurveyMistakes.points(site.place));
    }
    writtenT = readingT;
    _tag(switch (site.place) {
      M7ClrPlace.road => M7ClearanceSurveyLines.caughtLow,
      M7ClrPlace.roof => M7ClearanceSurveyLines.caughtTop,
      M7ClrPlace.side => M7ClearanceSurveyLines.caughtNear,
    });
    stage = M7ClrStage.rule;
    return null;
  }

  /// The drum turned by [steps] (a drum: it wraps round).
  bool spin(int steps) {
    if (!_open || stage != M7ClrStage.rule || steps == 0) return false;
    drum = (drum + steps) % kM7ClrDrum.length;
    if (drum < 0) drum += kM7ClrDrum.length;
    return true;
  }

  /// A verdict stamp on the row: the drum first, then the verdict.
  DoMistake? stamp({required bool legal}) {
    if (!_open || stage != M7ClrStage.rule) return null;
    if (drumT != site.ruleT) return _slip(M7ClearanceSurveyMistakes.rule(site.place));
    if (legal != site.legal) return _slip(site.legal ? M7ClearanceSurveyMistakes.falseReport : M7ClearanceSurveyMistakes.missed);
    _tag(M7ClearanceSurveyLines.caughtRule);
    if (legal) {
      _tag(M7ClearanceSurveyLines.caughtLegal);
      roundDone = true;
    } else {
      stage = M7ClrStage.phone;
    }
    return null;
  }

  /// The phone held through: the supervisor is told.
  bool call() {
    if (!_open || stage != M7ClrStage.phone) return false;
    _tag(M7ClearanceSurveyLines.caughtReport);
    roundDone = true;
    return true;
  }

  /// Listened to the coworker (a slip).
  DoMistake pushSlip() => _slip(M7ClearanceSurveyMistakes.listen);

  void next() {
    index++;
    if (!done) _startSite();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a site: two handle drags + 'লিখুন' ≈ 5500, the drum (1–3 swipes)
///     ≈ 3000, the stamp ≈ 2000, a reason ≈ 8200                ≈ 18700
///   + the phone on a short site (hold 1.2 s) ≈ 2500 (1–2 sites)
///   + the coworker once ≈ 9600
///   three sites ≈ 56100 + 2500–5000 + 9600 ≈ 68000–71000; 85 % ≈ 59000
///   → 60 s (a builder's estimate; owner may tune after playtest, M7-13).
const m7ClearanceSurveyQuickMs = 60000;

/// The phone is held this long to call.
const int kM7ClrHoldMs = 1200;

@immutable
class M7ClearanceSurveyPack {
  const M7ClearanceSurveyPack({required this.id, required this.titleBn, this.quickMs = m7ClearanceSurveyQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7ClearanceSurveyPack> m7ClearanceSurveyPacks = {
  'do_7_3_a': M7ClearanceSurveyPack(id: 'do_7_3_a', titleBn: M7ClearanceSurveyLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7ClearanceSurveyProbe {
  static M7ClrRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7ClearanceSurveyPage extends StatefulWidget {
  const M7ClearanceSurveyPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7ClearanceSurveyPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7ClearanceSurveyPage> createState() => _M7ClearanceSurveyPageState();
}

class _M7ClearanceSurveyPageState extends State<M7ClearanceSurveyPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ClrRunPage(
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

class _ClrRunPage extends ConsumerStatefulWidget {
  const _ClrRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7ClearanceSurveyPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ClrRunPage> createState() => _ClrRunPageState();
}

class _ClrRunPageState extends ConsumerState<_ClrRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7ClrRun _run;
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

  /// The handle in hand and where it is (design px).
  int? _drag;
  Offset _dragAt = Offset.zero;

  /// 'লিখুন' was asked for on this site (said once).
  var _askedWrite = false;

  /// The phone's hold (forward while held, then still).
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: kM7ClrHoldMs), animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener(_holdStatus);

  /// The drum's swipe so far.
  double _drumDy = 0;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _writeKey = GlobalKey();
  final _drumKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _stampKeys = [GlobalKey(), GlobalKey()];
  int _hintN = 0;
  int _steps = 0;
  M7ClrGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7ClrRun(m7ClrDeal(widget.rng));
    M7ClearanceSurveyProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _hold.dispose();
    _chain++;
    if (identical(M7ClearanceSurveyProbe.run, _run)) M7ClearanceSurveyProbe.run = null;
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
    // At the tape the whole scene is the work: once said, the line leaves the
    // bubble (it would cover the wire and the pole plate). Tap the guide to
    // hear it again.
    if (!mounted || chain != _chain || _stage != M7ClrStage.measure || lines.isEmpty) return;
    await Future<void>.delayed(_muted ? MascotSpeechLibrary.readHold(lines.last) : const Duration(milliseconds: 1500));
    if (mounted && chain == _chain && _stage == M7ClrStage.measure && _canPlay) _clearBubble();
  }

  void _clearBubble() {
    final guide = ref.read(guideDirectorProvider.notifier);
    guide.softClearLine();
    guide.react(GuideMood.idle);
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

  M7ClrSite get _site => _run.site;
  M7ClrStage get _stage => _run.stage;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone;

  String get _task => switch (_stage) {
        M7ClrStage.measure => _run.readingT != null ? M7ClearanceSurveyLines.askWrite : M7ClearanceSurveyLines.askSite,
        M7ClrStage.rule => M7ClearanceSurveyLines.askRule,
        M7ClrStage.phone => M7ClearanceSurveyLines.askPhone,
      };

  Future<void> _start() async {
    _clock.start();
    _startSite();
  }

  void _startSite() {
    setState(() {
      _wake++;
      _drag = null;
      _askedWrite = false;
      _hold.value = 0;
    });
    unawaited(_sayChain([_run.index == 0 ? M7ClearanceSurveyLines.askSite : M7ClearanceSurveyLines.askSiteOther]));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- the tape -----------------------------------------------------------------
  Offset _handleAt(int h, M7ClrGeo geo) {
    if (_drag == h) return _dragAt;
    final p = _run.handles[h];
    return p == null ? geo.park(h) : geo.at(_site.layout.points[p]!);
  }

  void _panStart(Offset p, M7ClrGeo geo) {
    _drag = null;
    if (!_canPlay || _stage != M7ClrStage.measure) {
      if (_canPlay) _hints.missTap();
      return;
    }
    int? best;
    var bd = 24.0;
    for (var h = 0; h < 2; h++) {
      final d = (_handleAt(h, geo) - p).distance;
      if (d <= bd) {
        bd = d;
        best = h;
      }
    }
    if (best == null) {
      _hints.missTap();
      return;
    }
    _run.lift(best);
    _clearBubble();
    setState(() {
      _drag = best;
      _dragAt = p;
    });
  }

  void _panUpdate(Offset p) {
    if (_drag == null) return;
    if (!_canPlay) {
      setState(() => _drag = null);
      return;
    }
    setState(() => _dragAt = p);
  }

  void _panEnd(M7ClrGeo geo) {
    final h = _drag;
    if (h == null) return;
    final other = _run.handles[1 - h];
    final snap = geo.snapTo(_dragAt, _site.layout.points, except: {?other});
    setState(() => _drag = null);
    if (snap != null && _run.put(h, snap)) {
      _tick('sounds/intro/click.ogg', 0.55);
      _stepDone();
      if (_run.readingT != null && !_askedWrite) {
        _askedWrite = true;
        unawaited(_sayChain([M7ClearanceSurveyLines.askWrite]));
      }
      return;
    }
    // Let go on nothing: back in the case.
    _stepDone();
  }

  void _write(Offset at) {
    if (!_canPlay || _stage != M7ClrStage.measure || _run.readingT == null) return;
    final m = _run.write();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.55);
    _stepDone();
    unawaited(_levelDelta(5, at, mood: GuideMood.glad));
    unawaited(_sayChain([_task]));
  }

  // --- the register row -----------------------------------------------------------
  void _drumStart() => _drumDy = 0;

  void _drumUpdate(double dy) => _drumDy += dy;

  void _drumEnd() {
    if (!_canPlay || _stage != M7ClrStage.rule) return;
    var steps = (-_drumDy / 28).round();
    if (steps == 0 && _drumDy.abs() > 10) steps = _drumDy < 0 ? 1 : -1;
    _drumDy = 0;
    if (!_run.spin(steps)) return;
    _tick('sounds/intro/tick.ogg', 0.4);
    _stepDone();
  }

  void _stamp(bool legal, Offset at) {
    if (!_canPlay || _stage != M7ClrStage.rule) return;
    final m = _run.stamp(legal: legal);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.7);
    _stepDone();
    if (_run.roundDone) {
      unawaited(_siteDone());
      return;
    }
    // Short: on to the phone. On the play's first short site the coworker
    // comes now, before the phone works.
    unawaited(_levelDelta(5, at, mood: GuideMood.glad));
    if (_run.index == _run.deal.coworkerSite && !coworkerDone && !coworkerDue) scheduleCoworker();
    unawaited(_sayChain([_task]));
  }

  void _phoneDown() {
    if (!_canPlay || _stage != M7ClrStage.phone) return;
    if (_run.index == _run.deal.coworkerSite && holdForCoworker()) return;
    HapticFeedback.selectionClick();
    _hold.forward(from: 0);
  }

  void _phoneUp() {
    if (_hold.isCompleted || !_hold.isAnimating) return;
    _hold
      ..stop()
      ..value = 0;
  }

  void _holdStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    if (!_canPlay || !_run.call()) {
      _hold.value = 0;
      return;
    }
    _cue('sounds/intro/confirm.ogg', volume: 0.6);
    _stepDone();
    unawaited(_siteDone());
  }

  Future<void> _siteDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _site.why;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M7ClearanceSurveyLines.whyRight[topic]!, M7ClearanceSurveyLines.myths, widget.rng),
      question: M7ClearanceSurveyLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startSite();
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
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7ClearanceSurveyLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerSite || _run.roundDone) return null;
    if (_stage != M7ClrStage.phone) return false;
    if (_intro || _card != null || tableBusy || _hold.isAnimating) return false;
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
    _run.caught.add(M7ClearanceSurveyLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7ClearanceSurveyLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7ClearanceSurveyLines.tapWhy[_nudgeN++ % M7ClearanceSurveyLines.tapWhy.length]
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
    _hold.stop();
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
      _drag = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7clr/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same site goes on from where it was.
    _hush();
    setState(() {
      _card = null;
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
    await _say(!_run.passed ? M7ClearanceSurveyLines.fail : (_quickBonus ? M7ClearanceSurveyLines.quick : M7ClearanceSurveyLines.allSet),
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
    if (_drag != null || _stage == M7ClrStage.phone) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what (see the header comment).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    switch (_stage) {
      case M7ClrStage.measure:
        if (_run.readingT != null) return HintSpec.tapOn(_writeKey);
        final free = _run.handles[0] == null ? 0 : 1;
        // A short straight nudge out of the case, the same at every site.
        return HintSpec.drag(geo.park(free), toward: const Offset(0, 1), travel: 50, space: HintSpace.scene);
      case M7ClrStage.rule:
        if (n.isEven) {
          final r = HintSpec.globalRectOf(_drumKey);
          if (r == null) return null;
          return HintSpec.swipe(r.center, toward: Offset(0, n % 4 == 0 ? -1 : 1), travel: 40);
        }
        return HintSpec.sweepOver(_stampKeys);
      case M7ClrStage.phone:
        return HintSpec.holdOn(_phoneKey);
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7ClrGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final layout = _site.layout;
    final handles = [_handleAt(0, geo), _handleAt(1, geo)];
    final reading = _drag == null ? _run.readingT : null;
    final locked = _drag == null && _run.readingT != null;
    final mid = Offset.lerp(handles[0], handles[1], 0.5)!;
    return [
      Positioned.fill(
        key: ValueKey('site-${_run.index}'),
        child: RepaintBoundary(child: CustomPaint(painter: M7ClrSitePainter(geo: geo, layout: layout, volt: _site.volt))),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      Positioned.fill(
        key: const ValueKey('tape'),
        child: RepaintBoundary(child: CustomPaint(painter: M7ClrTapePainter(geo: geo, handles: handles, locked: locked))),
      ),
      if (reading != null && _stage == M7ClrStage.measure)
        Positioned(
          key: const ValueKey('tape-reading'),
          // Left of the tape: the guide's bubble stands on the right.
          left: (mid.dx - 74).clamp(4.0, 290.0),
          top: mid.dy - 14,
          child: IgnorePointer(child: _ReadingTag(text: m7ClrMetres(reading))),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7ClearanceSurveyLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (_) {
              if (_canPlay) _hints.missTap();
            },
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: () {
              if (_drag != null) setState(() => _drag = null);
            },
          ),
        ),
      ),
      // The next site: a short fade.
      if (!_intro)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.5, end: 0),
              duration: const Duration(milliseconds: 420),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  Widget _register({required bool quiet}) {
    final rule = _stage == M7ClrStage.rule;
    final stamps = [
      (legal: true, label: M7ClearanceSurveyLines.stampLegal),
      (legal: false, label: M7ClearanceSurveyLines.stampShort),
    ];
    if (_run.deal.stampsSwapped) stamps.setAll(0, [stamps[1], stamps[0]]);
    return Container(
      key: const ValueKey('clr-register'),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF8F1DE),
        border: Border.all(color: const Color(0xFF8A6A35), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  M7ClearanceSurveyLines.registerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF6A5230)),
                ),
              ),
              Text('${M7ClearanceSurveyLines.measured}  ', style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF3A2E1C))),
              Text(m7ClrMetres(_run.writtenT ?? 0), style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF1C2E4A))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Drum(
                key: _drumKey,
                valueT: _run.drumT,
                prevT: kM7ClrDrum[(_run.drum + kM7ClrDrum.length - 1) % kM7ClrDrum.length],
                nextT: kM7ClrDrum[(_run.drum + 1) % kM7ClrDrum.length],
                live: rule,
                quiet: quiet,
                onStart: _drumStart,
                onUpdate: _drumUpdate,
                onEnd: _drumEnd,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DragTarget<bool>(
                  onWillAcceptWithDetails: (_) => _canPlay && rule,
                  onAcceptWithDetails: (d) => _stamp(d.data, d.offset + const Offset(40, 20)),
                  builder: (context, cand, _) => Container(
                    key: const ValueKey('clr-slot'),
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: cand.isNotEmpty ? const Color(0x33C48A2E) : const Color(0x11000000),
                      border: Border.all(color: const Color(0xFF8A6A35), width: 1.2),
                    ),
                    child: _stage == M7ClrStage.phone
                        ? Text(M7ClearanceSurveyLines.stampShort, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFFB3261E)))
                        : Text(M7ClearanceSurveyLines.slotLabel, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0x998A6A35))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: _stage == M7ClrStage.phone
                ? Center(child: _PhoneButton(key: _phoneKey, hold: _hold, onDown: _phoneDown, onUp: _phoneUp))
                : Row(
                    children: [
                      for (final (i, s) in stamps.indexed) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: Draggable<bool>(
                            key: ValueKey('clr-stamp-${s.legal ? 'legal' : 'short'}'),
                            data: s.legal,
                            maxSimultaneousDrags: _canPlay && rule ? 1 : 0,
                            dragAnchorStrategy: pointerDragAnchorStrategy,
                            feedback: Material(type: MaterialType.transparency, child: _Stamp(label: s.label, lifted: true)),
                            childWhenDragging: Opacity(opacity: 0.35, child: _Stamp(label: s.label)),
                            child: KeyedSubtree(key: _stampKeys[i], child: _Stamp(label: s.label)),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.roundDone;
    final registerUp = playing && !deckUp && _stage != M7ClrStage.measure && !_run.roundDone;
    final writeUp = handsOn && !tableBusy && _stage == M7ClrStage.measure && _run.readingT != null && _drag == null;
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
              labels: [for (var i = 0; i < _run.count; i++) M7ClearanceSurveyLines.siteName(i + 1)],
              done: {for (var i = 0; i < math.min(_run.index, _run.count); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _drag == null && !_hold.isAnimating,
            hintKey: '${_run.index}/$_steps/${_stage.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (writeUp)
                Positioned(
                  key: ValueKey('hud-write-${_run.index}'),
                  left: 16,
                  bottom: pad.bottom + 14,
                  child: _PillButton(key: _writeKey, label: M7ClearanceSurveyLines.write, onTap: _write),
                ),
              if (registerUp)
                Positioned(
                  key: ValueKey('hud-register-${_run.index}'),
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + 10,
                  child: _register(quiet: quiet),
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp || registerUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
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
                  line: M7ClearanceSurveyLines.intro,
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

/// The tape's reading beside it (shown only once both handles are down).
class _ReadingTag extends StatelessWidget {
  const _ReadingTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2E4A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF7D046), width: 1.4),
      ),
      child: Text(text, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
    );
  }
}

/// The 'আইনের ন্যূনতম' drum: swipe it up or down.
class _Drum extends StatelessWidget {
  const _Drum({
    super.key,
    required this.valueT,
    required this.prevT,
    required this.nextT,
    required this.live,
    required this.quiet,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final int valueT;
  final int prevT;
  final int nextT;
  final bool live;
  final bool quiet;
  final VoidCallback onStart;
  final ValueChanged<double> onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final dim = bangla(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0x886A5230));
    return Semantics(
      label: M7ClearanceSurveyLines.drumLabel,
      value: m7ClrMetres(valueT),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onVerticalDragStart: live ? (_) => onStart() : null,
        onVerticalDragUpdate: live ? (d) => onUpdate(d.delta.dy) : null,
        onVerticalDragEnd: live ? (_) => onEnd() : null,
        child: Container(
          key: const ValueKey('clr-drum'),
          width: 124,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD9CBA6), Color(0xFFFFFBEF), Color(0xFFD9CBA6)],
            ),
            border: Border.all(color: const Color(0xFF8A6A35), width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(M7ClearanceSurveyLines.drumLabel, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6A5230))),
              Text(m7ClrMetres(nextT), style: dim),
              AnimatedSwitcher(
                duration: Duration(milliseconds: quiet ? 0 : 160),
                child: Text(m7ClrMetres(valueT), key: ValueKey(valueT), style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1C2E4A))),
              ),
              Text(m7ClrMetres(prevT), style: dim),
            ],
          ),
        ),
      ),
    );
  }
}

/// A verdict stamp (both alike).
class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, this.lifted = false});
  final String label;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        width: lifted ? 140 : null,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
          border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
          boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 12 : 5, offset: const Offset(0, 3))],
        ),
        child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
      ),
    );
  }
}

/// The phone: hold it to call (a ring fills while held).
class _PhoneButton extends StatelessWidget {
  const _PhoneButton({super.key, required this.hold, required this.onDown, required this.onUp});
  final Animation<double> hold;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M7ClearanceSurveyLines.phone,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: Container(
          key: const ValueKey('clr-phone'),
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: hold,
                        builder: (_, _) => CircularProgressIndicator(
                          value: hold.value,
                          strokeWidth: 3,
                          color: SlmColors.gold300,
                          backgroundColor: const Color(0x33FFFFFF),
                        ),
                      ),
                    ),
                    const Icon(Icons.phone_in_talk_rounded, size: 18, color: SlmColors.ivory),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(M7ClearanceSurveyLines.phone, style: bangla(fontSize: 15.5, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A worker's button on the scene ('লিখুন').
class _PillButton extends StatelessWidget {
  const _PillButton({super.key, required this.label, required this.onTap});
  final String label;
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
        child: Container(
          constraints: const BoxConstraints(minHeight: 54, minWidth: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}
