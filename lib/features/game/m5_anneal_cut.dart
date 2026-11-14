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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm5_anneal_cut_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_anneal_cut_world.dart' show M5AnnealKind, M5AnnealLight;

// Lesson 5.3 "সাধারণ ফল্ট: অপরাধীদের প্যারেড", কাজ 2 "পোড়া জোড়, নরম তার"
// (pack do_5_3_b, engineType m5_anneal_cut). The fault is found; now the
// repair on one section (pole 7 to 9) under the permit. Four rounds:
//
//  ১ কাজের জায়গা: the section. Earth sets are on at both ends, or one end is
//    bare (dealt). A bare end: the tester on R, Y, B (0 V), then the earth set
//    there; then climb. Earth before the tester = a slip (ruling M5-2);
//    climbing with an end bare = deadly (R4 — the deadly is booked at the
//    climb, the moment work on the line begins, so no cut can ever happen
//    unearthed).
//  ২–৪ three repair spots on the workbench (jumper always + two of: an
//    annealed joint sleeve, a sound conductor with a burnt connector, a
//    conductor snapped with melted ends). Each kind is drawn as itself: the
//    jumper hangs off its burnt PG clamp in a U loop; the sleeve is a long,
//    heat-discoloured bolted joint sleeve; the connector is a burnt PG clamp
//    on a straight conductor; the snapped conductor lies in two pieces with
//    melted, drooping ends and no clamp. Each spot: the spanner round the old
//    clamp's or sleeve's nut (a circular drag) → it drops (a snapped spot
//    starts here) → press-hold the conductor anywhere to bend it (sound metal
//    springs back; soft metal stays kinked) → drag up to two red tapes onto
//    the conductor and sweep the cutter across a tape, or tap 'কাটার দরকার
//    নেই — শুধু কানেক্টর'. A cut inside the soft length shows a dark, soft face
//    (a slip; re-cut further out). The repair finishes by itself, ◆ on the
//    table → the reason.
//
// The lesson's rules, and only those (lesson 5.3, point 3 and the advanced
// fact "অ্যানিলিং অফ কন্ডাক্টর"): a hotspot can leave the conductor soft
// (annealed) — check it; aluminium loses its strength and turns soft and
// brittle; repair the connector AND cut out the damaged length; a snapped
// conductor is jointed by the rules; burnt marks and melted metal lead to the
// fault (pro tip 1). Earth at both ends and tester-before-earth come from
// lessons 4.1 / 5.1 and the Module 5 rulings, not 5.3 (no lesson point on
// those cards). Ruling M5-15(a): annealing shows as discolouration and
// softness (the bend), never a precise bend-test claim. Game rules (flagged):
// how far the soft length runs, how far beyond it a cut may go (a jumper cut
// further = too short for a smooth U; a span cut further = good metal wasted).
//
// Deadly: climbing with an earth set missing at either end (R4).
// Slips: earth before the tester (R3), a cut inside the soft length, 'শুধু
// কানেক্টর' on soft metal, jointing over melted ends, a jumper cut too short,
// cutting a sound conductor (R30), listening to the coworker (R29). Three slips
// strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m5_anneal_cut_world.dart), corner guide (tap = the task another way),
// ◆ on the table → "কেন …?" after each round; the careless coworker once a play,
// at the jumper spot the instant the old clamp drops — every next control
// (bend, tape, cut, connector) waits for him (holdForCoworker). Gesture hand
// (how, never what): a sweep over the tools and both ends; a lap round the
// nut (a sweep over four points round it); a hold at one fixed place along
// the conductor; a tape lifted off the tray; a cut sweep across the player's
// own tape. 'কাটার দরকার নেই' is never hinted. Voice: the
// guide by device TTS; the coworker's push needs a recorded clip (his exit line
// has one).

// ============================================================================
// Content
// ============================================================================

/// The tools of the section round.
enum M5AnnealTool { tester, earth, climb }

abstract final class M5AnnealLines {
  static const title = 'পোড়া জোড়, নরম তার';
  static const intro = 'ফল্ট ধরা পড়েছে। এবার মেরামত — পোড়া জোড় সারান, ঠিকঠাক!';
  static const rounds = ['কাজের জায়গা', 'জোড় 1', 'জোড় 2', 'জোড় 3'];

  // The guide's task now (tap him: the same task, a different way).
  static const askSite = 'কাজের জায়গা তৈরি তো? দেখে নিন।';
  static const askUnbolt = 'পুরোনো ক্ল্যাম্পটা খুলুন।';
  static const askJudge = 'তারটা পরখ করে মেরামত করুন।';
  static const tasks = [askSite, askUnbolt, askJudge];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'মেরামতের জায়গা';
  static const tester = 'টেস্টার';
  static const earth = 'আর্থ সেট';
  static const climb = 'উঠুন';
  static const connectorOnly = 'কাটার দরকার নেই — শুধু কানেক্টর';
  static const phases = ['R', 'Y', 'B'];
  static const dead = '0 V';

  static String toolLabel(M5AnnealTool t) => switch (t) {
        M5AnnealTool.tester => tester,
        M5AnnealTool.earth => earth,
        M5AnnealTool.climb => climb,
      };

  // The reasons: the right ones fit what was done this round; the wrong ones
  // are the lesson's myths and field excuses. 37–47 letters.
  static const siteBothQ = 'কাটার আগে কেন দুই দিকের আর্থ দেখলেন?';
  static const siteTestQ = 'কেন আর্থ লাগানোর আগে টেস্টার ছোঁয়ালেন?';
  static const cutQ = 'কেন ঠিক এখানে কাটলেন?';
  static const noCutQ = 'কেন এবার তার কাটলেন না?';
  static const siteBothWhy = ['ট্রিপ হওয়া লাইন যেকোনো সময় আবার চালু হতে পারে', 'দুই দিক থেকে আর্থ থাকলে তবেই লাইনে হাত দেওয়া'];
  static const siteTestWhy = ['আগে টেস্টারে ডেড প্রমাণ, তারপর আর্থ — এটাই ক্রম', 'লাইন সত্যিই ডেড কি না দেখে তবে আর্থ লাগাই'];
  static const sleeveWhy = ['গরমে নরম অংশ শক্তি হারায়, তাই ভালো তারে কাটা', 'নরম অংশটুকু বাদ দিয়ে ভালো ধাতু থেকে কাটা'];
  static const jumperWhy = ['নরম জাম্পারটুকু বাদ, তবু মসৃণ U-র দৈর্ঘ্য রইল', 'শুধু নরম অংশ কেটেছি, জাম্পার বেশি ছোট হয়নি'];
  static const snapWhy = ['গলে যাওয়া মাথা আর নরম অংশ কেটে তবে জয়েন্ট', 'পোড়া মাথার উপর জয়েন্ট টেকে না, তাই কেটে বাদ'];
  static const noCutWhy = ['তার নরম বা বিবর্ণ হয়নি, তাই কাটার দরকার নেই', 'তারের রং আর জোর ঠিক আছে, তাই শুধু কানেক্টর'];

  /// Wrong reasons for the section round: earth and tester excuses only, so
  /// the right card is never the lone earth-themed one.
  static const siteMyths = [
    'আর্থ তো ক্রু দিয়েছে, আমার দেখার দরকার নেই',
    'লাইন তো বন্ধ, টেস্টার ছাড়াই আর্থ দেওয়া যায়',
    'একদিকে আর্থ দিলেই যথেষ্ট, অন্য দিক লাগে না',
    'PTW হাতে আছে, তাই আর্থ দেখার আর দরকার নেই',
    'আগে আর্থ লাগাই, টেস্টার পরে ছোঁয়ালেও চলে',
    'লাইন তো ট্রিপ করেছে, আর নিজে চালু হবে না',
  ];

  /// Wrong reasons for a repair spot: conductor myths only.
  static const spotMyths = [
    'নতুন ক্ল্যাম্প লাগালেই তারের সব দোষ সেরে যায়',
    'তার তো ছেঁড়েনি, তাই পরখ করার কিছু নেই',
    'কালো দাগ ঘষে মুছলেই তার আবার নতুনের মতো',
    'যত বেশি কাটি তত ভালো, মাপের দরকার নেই',
    'তাড়া আছে, তাই যেখানে খুশি সেখানে কেটে দিলাম',
    'গরমে অ্যালুমিনিয়াম তার কখনও নরম হয় না',
  ];
  static List<String> get myths => [...siteMyths, ...spotMyths];

  /// The wrong reasons for a round ([s] null: the section).
  static List<String> mythsFor(M5AnnealSpot? s) => s == null ? siteMyths : spotMyths;
  static List<String> get allWhyRight => [...siteBothWhy, ...siteTestWhy, ...sleeveWhy, ...jumperWhy, ...snapWhy, ...noCutWhy];

  /// The right reasons for the section round ([bare]: an end had to be earthed).
  static List<String> siteWhy(bool bare) => bare ? siteTestWhy : siteBothWhy;
  static String siteQuestion(bool bare) => bare ? siteTestQ : siteBothQ;

  /// The right reasons for a repair spot.
  static List<String> spotWhy(M5AnnealSpot s) => !s.soft
      ? noCutWhy
      : switch (s.kind) {
          M5AnnealKind.jumper => jumperWhy,
          M5AnnealKind.snapped => snapWhy,
          _ => sleeveWhy,
        };
  static String spotQuestion(M5AnnealSpot s) => s.soft ? cutQ : noCutQ;

  /// The careless coworker: a new clamp, no look at the wire.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'নতুন ক্ল্যাম্প লাগিয়ে দাও, তার দেখার দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, আগে দেখি গরমে তার নরম হয়েছে কিনা।', 'না, আগে দেখি তারে পোড়া রং ধরেছে কিনা।', 'না, নরম অংশ থাকলে কেটে বাদ দিতে হবে।'],
    wrong: [
      'হ্যাঁ, নতুন ক্ল্যাম্পেই সব ঠিক হবে।',
      'তার তো ছেঁড়েনি, দেখার কী আছে।',
      'ঠিক, ক্ল্যাম্প বদলালেই কাজ শেষ।',
      'আচ্ছা, তার পরখ করে সময় নষ্ট নয়।',
      'হ্যাঁ, কালো দাগ তো শুধু ময়লা।',
    ],
    asks: ['ওঁর কথা মানবেন?', 'নতুন ক্ল্যাম্প, না আগে তার পরখ?', 'তার না দেখেই ক্ল্যাম্প লাগাবেন?'],
  );

  static const callHeld = 'ঠিক! আগে তার পরখ, তারপর মেরামত।';
  static const allSet = 'নরম তার বাদ, ভালো তারে জোড় — নিরাপদে, ঠিকঠাক!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে দুই দিকের আর্থ, তারপর তার পরখ করে মেরামত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtEarth = 'দুই দিকের আর্থ দেখে তবে উঠেছেন';
  static const caughtTest = 'আগে টেস্টারে ডেড, তারপর আর্থ';
  static const caughtCut = 'নরম অংশ কেটে ভালো তারে জোড়';
  static const caughtU = 'জাম্পারে মসৃণ U-র দৈর্ঘ্য রেখেছেন';
  static const caughtBead = 'গলে যাওয়া মাথা কেটে তবে জয়েন্ট';
  static const caughtSound = 'ভালো তারে শুধু কানেক্টর বদল';
  static const caughtCall = 'তার না দেখে ক্ল্যাম্প লাগাতে “না” বলেছেন';
}

abstract final class M5AnnealMistakes {
  static const _dir = 'assets/game/art/m5_anneal_cut';

  // Earth at both ends and the tester first come from lessons 4.1 / 5.1 and
  // the Module 5 rulings (not 5.3's text): no lesson point.
  static const noEarth = DoMistake(
    key: '5.3/m5_anneal_cut/no-earth',
    textBn: 'দুই দিকে আর্থ ছাড়া লাইনে ওঠা বা কাটা নয়! খালি দিকে আগে টেস্টারে ডেড প্রমাণ, তারপর আর্থ — তবেই কাজ।',
    art: '$_dir/no_earth.svg',
    deadly: true,
  );
  static const testFirst = DoMistake(
    key: '5.3/m5_anneal_cut/test-first',
    textBn: 'আগে টেস্টার দিয়ে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক।',
    art: '$_dir/test_first.svg',
  );
  static const softFace = DoMistake(
    key: '5.3/m5_anneal_cut/soft-face',
    textBn: 'কাটা মুখ কালচে আর নরম — এখনও ক্ষতিগ্রস্ত অংশে কেটেছেন। ভালো ধাতু পর্যন্ত সরে আবার কাটুন।',
    art: '$_dir/soft_face.svg',
    lessonPoint: 2,
  );
  static const connectorOnly = DoMistake(
    key: '5.3/m5_anneal_cut/connector-only',
    textBn: 'গরমে তার নরম (Annealed) হয়ে গেছে। শুধু কানেক্টর নয়, তারের ক্ষতিগ্রস্ত অংশটিও কেটে বাদ দিন।',
    art: '$_dir/connector_only.svg',
    lessonPoint: 2,
  );
  static const beadJoint = DoMistake(
    key: '5.3/m5_anneal_cut/bead-joint',
    textBn: 'গলে যাওয়া মাথার উপর জয়েন্ট নয়! পোড়া অংশ কেটে বাদ দিয়ে ছেঁড়া তার নিয়ম অনুযায়ী জয়েন্ট করুন।',
    art: '$_dir/bead_joint.svg',
    lessonPoint: 2,
  );
  static const shortJumper = DoMistake(
    key: '5.3/m5_anneal_cut/short-jumper',
    textBn: 'জাম্পার বেশি ছোট করে কাটবেন না — মসৃণ U বাঁকের দৈর্ঘ্য রাখুন; শুধু নরম অংশটুকু বাদ দিন।',
    art: '$_dir/short_jumper.svg',
    lessonPoint: 2,
  );
  static const needless = DoMistake(
    key: '5.3/m5_anneal_cut/needless-cut',
    textBn: 'এখানকার তার ভালো — নরম বা বিবর্ণ নয়। ভালো তার কাটবেন না; কাটুন শুধু ক্ষতিগ্রস্ত অংশ।',
    art: '$_dir/needless_cut.svg',
    lessonPoint: 2,
  );
  static const listen = DoMistake(
    key: '5.3/m5_anneal_cut/listen',
    textBn: 'আগে দেখুন হটস্পটে তার নরম হয়েছে কিনা — শুধু নতুন ক্ল্যাম্প লাগালেই মেরামত শেষ নয়।',
    art: '$_dir/listen.svg',
    lessonPoint: 2,
  );

  static List<DoMistake> get all => [noEarth, testFirst, softFace, connectorOnly, beadJoint, shortJumper, needless, listen];
}

/// A cut may go this far (0..1 of the bench) beyond the soft length; further
/// is a jumper too short for its U, or good metal wasted (a game rule).
const double m5AnnealSpare = 0.14;

/// One repair spot of the play.
@immutable
class M5AnnealSpot {
  const M5AnnealSpot({required this.kind, this.lo = 0.5, this.hi = 0.5, this.jumperRight = true});

  final M5AnnealKind kind;

  /// The soft (annealed / melted) length on the bench (lo == hi: none).
  final double lo;
  final double hi;

  /// The jumper's side of the clamp (a jumper spot); the line is on the other.
  final bool jumperRight;

  /// The conductor has to be cut here.
  bool get soft => hi - lo > 0.001;
  bool get softLeft => soft && lo < m5AnnealGapLo;
  bool get softRight => soft && hi > m5AnnealGapHi;
  bool softAt(double u) => soft && u > lo && u < hi;

  @override
  bool operator ==(Object other) => other is M5AnnealSpot && other.kind == kind && other.lo == lo && other.hi == hi && other.jumperRight == jumperRight;

  @override
  int get hashCode => Object.hash(kind, lo, hi, jumperRight);

  @override
  String toString() => 'M5AnnealSpot(${kind.name}, ${lo.toStringAsFixed(2)}–${hi.toStringAsFixed(2)})';
}

@immutable
class M5AnnealDeal {
  const M5AnnealDeal({required this.spots, this.bareLeft = false, this.bareRight = false, this.light = M5AnnealLight.day});

  /// The three repair spots in play order (one is the jumper).
  final List<M5AnnealSpot> spots;

  /// An end of the section with no earth set on it (at most one).
  final bool bareLeft;
  final bool bareRight;
  final M5AnnealLight light;

  bool get bare => bareLeft || bareRight;

  /// The jumper spot (the coworker comes there).
  int get jumperAt => spots.indexWhere((s) => s.kind == M5AnnealKind.jumper);
}

M5AnnealDeal m5AnnealDeal(math.Random rng) {
  double r(double a, double b) => a + rng.nextDouble() * (b - a);
  final earth = rng.nextInt(3); // 0 both on, 1 pole 7 bare, 2 pole 9 bare
  final light = M5AnnealLight.values[rng.nextInt(M5AnnealLight.values.length)];
  final others = [M5AnnealKind.sleeve, M5AnnealKind.connector, M5AnnealKind.snapped]..shuffle(rng);
  final pick = others.take(2).toList();
  // At least one spot needs a cut (sleeve / snapped) and at least one needs
  // none (the connector or a sound jumper): neither "always cut" nor "never".
  var jumperSoft = rng.nextBool();
  if (!pick.contains(M5AnnealKind.connector)) jumperSoft = false;
  M5AnnealSpot spot(M5AnnealKind k) {
    switch (k) {
      case M5AnnealKind.jumper:
        final right = rng.nextBool();
        if (!jumperSoft) return M5AnnealSpot(kind: k, jumperRight: right);
        final b = r(0.10, 0.26);
        return right ? M5AnnealSpot(kind: k, lo: 0.5, hi: m5AnnealGapHi + b) : M5AnnealSpot(kind: k, lo: m5AnnealGapLo - b, hi: 0.5, jumperRight: false);
      case M5AnnealKind.sleeve:
        return M5AnnealSpot(kind: k, lo: m5AnnealGapLo - r(0.08, 0.24), hi: m5AnnealGapHi + r(0.08, 0.24));
      case M5AnnealKind.snapped:
        return M5AnnealSpot(kind: k, lo: m5AnnealGapLo - r(0.05, 0.14), hi: m5AnnealGapHi + r(0.05, 0.14));
      case M5AnnealKind.connector:
        return const M5AnnealSpot(kind: M5AnnealKind.connector);
    }
  }

  final kinds = [M5AnnealKind.jumper, ...pick]..shuffle(rng);
  return M5AnnealDeal(spots: [for (final k in kinds) spot(k)], bareLeft: earth == 1, bareRight: earth == 2, light: light);
}

/// The play state (pure logic). Round 0 = the section, 1–3 = the spots.
class M5AnnealRun {
  M5AnnealRun(this.deal)
      : earthL = !deal.bareLeft,
        earthR = !deal.bareRight;
  final M5AnnealDeal deal;

  static const roundCount = 4;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The round's work is done (its reason comes next).
  var roundDone = false;

  // কাজের জায়গা
  bool earthL;
  bool earthR;
  var testedL = false;
  var testedR = false;
  var aloft = false;

  // a spot
  var clampOff = false;
  var endL = m5AnnealGapLo;
  var endR = m5AnnealGapHi;
  var doneL = false;
  var doneR = false;
  var darkL = false;
  var darkR = false;
  var bent = false;
  var fitted = false;
  final List<double> tapes = [];
  final List<double> kinks = [];

  bool get site => index == 0;
  M5AnnealSpot? get spot => index >= 1 && index <= 3 ? deal.spots[index - 1] : null;
  bool get done => index >= roundCount;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  int get trayLeft => 2 - tapes.length;
  bool get _open => !ended && !roundDone;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  // --- কাজের জায়গা ---------------------------------------------------------------
  /// The tester on R, Y, B at an end (0 V).
  DoMistake? test(bool left) {
    if (!_open || !site) return null;
    if (left) {
      testedL = true;
    } else {
      testedR = true;
    }
    return null;
  }

  /// The earth set on an end (a no-op where it already is).
  DoMistake? earth(bool left) {
    if (!_open || !site) return null;
    if (left ? earthL : earthR) return null;
    if (!(left ? testedL : testedR)) return _slip(M5AnnealMistakes.testFirst);
    if (left) {
      earthL = true;
    } else {
      earthR = true;
    }
    return null;
  }

  /// Up to the work: deadly with an end bare.
  DoMistake? climb() {
    if (!_open || !site) return null;
    if (!earthL || !earthR) return deadly = M5AnnealMistakes.noEarth;
    aloft = true;
    roundDone = true;
    _tag(M5AnnealLines.caughtEarth);
    if (deal.bare && thorough) _tag(M5AnnealLines.caughtTest);
    return null;
  }

  // --- a spot ------------------------------------------------------------------
  /// The old clamp (or sleeve) comes off (the spanner went round its nut).
  void unbolt() {
    if (!_open || spot == null) return;
    clampOff = true;
  }

  /// A cut at [t] took away the conductor between it and the gap: the kinks
  /// there go with it.
  void _dropKinks(double t, bool left) => kinks.removeWhere((k) => left ? (k > t && k < 0.5) : (k < t && k > 0.5));

  /// Conductor metal at [u] (not cut away, between the gloves).
  bool onMetal(double u) => clampOff && u >= m5AnnealMinU && u <= m5AnnealMaxU && (u < endL - 0.004 || u > endR + 0.004);

  /// A bend at [u]: true = it stays kinked (soft), false = springs back, null
  /// = no metal there.
  bool? bend(double u) {
    final s = spot;
    if (!_open || s == null || !onMetal(u)) return null;
    bent = true;
    final stays = s.softAt(u);
    if (stays && !kinks.any((k) => (k - u).abs() < 0.02)) kinks.add(u);
    return stays;
  }

  /// A tape put on the conductor at [u]; false = not there (no tape left, no
  /// metal, or on another tape).
  bool placeTape(double u) {
    if (!_open || spot == null || !onMetal(u) || tapes.length >= 2 || tapes.any((t) => (t - u).abs() < 0.03)) return false;
    tapes.add(u);
    return true;
  }

  /// Takes tape [i] off the conductor (to move it); returns where it was.
  double liftTape(int i) => tapes.removeAt(i);

  /// The cutter swept across tape [i].
  DoMistake? cut(int i) {
    final s = spot;
    if (!_open || s == null || i < 0 || i >= tapes.length) return null;
    final t = tapes.removeAt(i);
    final left = t < 0.5;
    final needs = left ? s.softLeft : s.softRight;
    // Sound metal (or beyond a good cut): the cutter is stopped.
    if (!needs || (left ? doneL : doneR)) return _slip(M5AnnealMistakes.needless);
    final inSoft = left ? t > s.lo : t < s.hi;
    if (inSoft) {
      // The cut goes through soft metal: its face shows dark and soft.
      _dropKinks(t, left);
      if (left) {
        endL = t;
        darkL = true;
      } else {
        endR = t;
        darkR = true;
      }
      return _slip(M5AnnealMistakes.softFace);
    }
    final beyond = left ? s.lo - t : t - s.hi;
    if (beyond > m5AnnealSpare) {
      return _slip(s.kind == M5AnnealKind.jumper ? M5AnnealMistakes.shortJumper : M5AnnealMistakes.needless);
    }
    _dropKinks(t, left);
    if (left) {
      endL = t;
      doneL = true;
      darkL = false;
    } else {
      endR = t;
      doneR = true;
      darkR = false;
    }
    if ((!s.softLeft || doneL) && (!s.softRight || doneR)) {
      fitted = true;
      roundDone = true;
      tapes.clear();
      if (thorough) {
        _tag(switch (s.kind) {
          M5AnnealKind.jumper => M5AnnealLines.caughtU,
          M5AnnealKind.snapped => M5AnnealLines.caughtBead,
          _ => M5AnnealLines.caughtCut,
        });
      }
    }
    return null;
  }

  /// 'কাটার দরকার নেই — শুধু কানেক্টর'.
  DoMistake? connectorOnly() {
    final s = spot;
    if (!_open || s == null || !clampOff) return null;
    if (s.soft) return _slip(s.kind == M5AnnealKind.snapped ? M5AnnealMistakes.beadJoint : M5AnnealMistakes.connectorOnly);
    fitted = true;
    roundDone = true;
    tapes.clear();
    if (thorough) _tag(M5AnnealLines.caughtSound);
    return null;
  }

  /// Listened to the coworker (a slip).
  DoMistake listened() => _slip(M5AnnealMistakes.listen);

  void next() {
    index++;
    roundSlips = 0;
    roundDone = false;
    // A snapped conductor has no clamp to take off: its pieces lie apart.
    clampOff = spot?.kind == M5AnnealKind.snapped;
    endL = m5AnnealGapLo;
    endR = m5AnnealGapHi;
    doneL = doneR = darkL = darkR = false;
    bent = false;
    fitted = false;
    tapes.clear();
    kinks.clear();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   কাজের জায়গা: (bare end) tester ×2, earth ×2, climb ≈ 7500 + reason ~8200
///   a cut spot: spanner ~3000, two bends, two tapes, two cuts ≈ 12000 + reason ~8200
///   a no-cut spot: spanner, a bend, the button ≈ 6000 + reason ~8200
///   (a snapped spot has no spanner: ~3000 less when it is dealt)
///   (2 cut spots + 1 no-cut on average) + the coworker once ≈ 9600  ≈ 82000
/// 85 % ≈ 70000 → 70 s.
const m5AnnealQuickMs = 70000;

/// The spanner's lap for the gesture hand: four points round the nut (top,
/// right, bottom, left) and back to the top (design px).
List<Rect> m5AnnealNutLap(Offset nut, {double r = 30}) => [
      for (final d in const [Offset(0, -1), Offset(1, 0), Offset(0, 1), Offset(-1, 0), Offset(0, -1)]) Rect.fromCenter(center: nut + d * r, width: 18, height: 18),
    ];

/// The section's tool row, shuffled so that it never reads left to right in
/// the working order (no answer in the layout).
List<M5AnnealTool> m5AnnealToolRow(math.Random rng) {
  final tools = [...M5AnnealTool.values];
  do {
    tools.shuffle(rng);
  } while (m5AnnealInWorkOrder(tools));
  return tools;
}

/// True if the row reads tester → earth → climb from left to right.
bool m5AnnealInWorkOrder(List<M5AnnealTool> row) =>
    row.indexOf(M5AnnealTool.tester) < row.indexOf(M5AnnealTool.earth) && row.indexOf(M5AnnealTool.earth) < row.indexOf(M5AnnealTool.climb);

@immutable
class M5AnnealPack {
  const M5AnnealPack({required this.id, required this.titleBn, this.quickMs = m5AnnealQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5AnnealPack> m5AnnealPacks = {
  'do_5_3_b': M5AnnealPack(id: 'do_5_3_b', titleBn: M5AnnealLines.title),
};

/// Test hook (tests only): the run and the scene geometry.
class M5AnnealProbe {
  M5AnnealRun? run;
  M5AnnealGeo? geo;
}

// ============================================================================
// Page
// ============================================================================

class M5AnnealPage extends StatefulWidget {
  const M5AnnealPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M5AnnealPack pack;
  final bool muted;
  final int? seed;
  final M5AnnealProbe? probe;

  @override
  State<M5AnnealPage> createState() => _M5AnnealPageState();
}

class _M5AnnealPageState extends State<M5AnnealPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _AnnealRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        probe: widget.probe,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _AnnealRunPage extends ConsumerStatefulWidget {
  const _AnnealRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final M5AnnealPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M5AnnealProbe? probe;

  @override
  ConsumerState<_AnnealRunPage> createState() => _AnnealRunPageState();
}

/// What a drag on the bench is doing.
enum _Pan { none, turn, newTape, moveTape, cut }

class _AnnealRunPageState extends ConsumerState<_AnnealRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5AnnealRun _run;
  late final List<M5AnnealTool> _tools;
  late final int _seed = _run.deal.spots.fold<int>(7, (a, s) => a * 31 + s.kind.index) + (_run.deal.bareLeft ? 3 : 0);
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

  // The section: the tool in hand, a tool dragged from its button, the
  // tester's reading at an end.
  M5AnnealTool? _held;
  Offset? _toolGhost;
  bool? _testLeft;
  int _testTok = 0;
  Timer? _testTimer;

  // The bench: the spanner's turn, a drag in progress, the bend test, the
  // clamp dropping, the repair fitted.
  double _turn = 0;
  double _lastAngle = 0;
  _Pan _pan = _Pan.none;
  Offset? _panFrom;
  Offset? _panAt;
  Offset? _ghost;
  double _bendAt = 0;
  var _bendStays = false;
  int _bendTok = 0;
  int _dropTok = 0;
  int _dropAt = -1;
  int _fitTok = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final Map<M5AnnealTool, GlobalKey> _toolKeys = {for (final t in M5AnnealTool.values) t: GlobalKey()};
  M5AnnealGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    // The deal first (a seed's play is the same), then the tool row.
    _run = M5AnnealRun(m5AnnealDeal(widget.rng));
    _tools = m5AnnealToolRow(widget.rng);
    widget.probe?.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _testTimer?.cancel();
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

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze;

  String get _task {
    if (_run.site) return M5AnnealLines.askSite;
    return _run.clampOff ? M5AnnealLines.askJudge : M5AnnealLines.askUnbolt;
  }

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() {
      _wake++;
      _turn = 0;
      _held = null;
    });
    unawaited(_sayChain([_task]));
  }

  // --- the section ---------------------------------------------------------------
  void _useTool(M5AnnealTool t, Offset global) {
    if (!_canPlay || !_run.site) return;
    if (t == M5AnnealTool.climb) {
      _tick('sounds/intro/click.ogg', 0.5);
      final m = _run.climb();
      setState(() => _wake++);
      if (m != null) {
        unawaited(_mistake(m, global));
        return;
      }
      if (_run.roundDone) unawaited(_roundDone());
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.45);
    setState(() => _held = _held == t ? null : t);
  }

  void _applyTool(M5AnnealTool t, bool left, Offset global) {
    if (!_canPlay || !_run.site) return;
    switch (t) {
      case M5AnnealTool.tester:
        _run.test(left);
        _tick('sounds/intro/click.ogg', 0.6);
        _testTimer?.cancel();
        setState(() {
          _testLeft = left;
          _testTok++;
          _wake++;
        });
        _testTimer = Timer(const Duration(milliseconds: 2600), () {
          if (mounted) setState(() => _testLeft = null);
        });
      case M5AnnealTool.earth:
        final before = left ? _run.earthL : _run.earthR;
        final m = _run.earth(left);
        setState(() => _wake++);
        if (m != null) {
          unawaited(_mistake(m, global));
        } else if (!before && (left ? _run.earthL : _run.earthR)) {
          _tick('sounds/intro/impact_metal.ogg', 0.55);
        } else {
          _hints.missTap();
        }
      case M5AnnealTool.climb:
        break;
    }
  }

  void _tapSite(Offset p, M5AnnealGeo geo, Offset global) {
    if (!_canPlay) return;
    for (final left in [true, false]) {
      if (geo.endHit(left).contains(p)) {
        final t = _held;
        if (t == null) {
          _hints.missTap();
        } else {
          _applyTool(t, left, global);
        }
        return;
      }
    }
    _hints.missTap();
  }

  /// A tool dragged from its button onto an end.
  void _toolDrag(M5AnnealTool t, Offset global, {required bool end}) {
    if (!_canPlay || !_run.site || t == M5AnnealTool.climb) {
      if (_toolGhost != null) setState(() => _toolGhost = null);
      return;
    }
    if (!end) {
      setState(() {
        _held = t;
        _toolGhost = global;
      });
      return;
    }
    final at = _toolGhost;
    setState(() => _toolGhost = null);
    final box = _touchKey.currentContext?.findRenderObject();
    final geo = _geoNow;
    if (at == null || box is! RenderBox || !box.attached || geo == null) return;
    final p = box.globalToLocal(at);
    for (final left in [true, false]) {
      if (geo.endHit(left).contains(p)) {
        _applyTool(t, left, at);
        return;
      }
    }
    _hints.missTap();
  }

  // --- the bench -----------------------------------------------------------------
  static double _angle(Offset v) => math.atan2(v.dy, v.dx);

  /// The conductor's drawn line at [u] on this spot's bench.
  double _lineY(M5AnnealGeo geo, double u) {
    final s = _run.spot;
    return s == null ? geo.condY : geo.lineY(s.kind, s.jumperRight, u);
  }

  bool _onLine(M5AnnealGeo geo, Offset p) {
    final s = _run.spot;
    return s != null && geo.onLine(p, s.kind, s.jumperRight);
  }

  void _panStart(Offset p) {
    _pan = _Pan.none;
    final geo = _geoNow;
    if (!_canPlay || _run.site || geo == null) return;
    if (!_run.clampOff) {
      if ((p - geo.nut).distance < 72) {
        _pan = _Pan.turn;
        _lastAngle = _angle(p - geo.nut);
      }
      return;
    }
    final dy = (p.dy - _lineY(geo, geo.uOf(p.dx))).abs();
    if (geo.tray.inflate(8).contains(p) && _run.trayLeft > 0) {
      if (holdForCoworker()) return;
      _pan = _Pan.newTape;
      setState(() => _ghost = p);
      return;
    }
    if (dy < 14) {
      final i = _tapeNear(p.dx, geo, 16);
      if (i != null) {
        if (holdForCoworker()) return;
        _pan = _Pan.moveTape;
        setState(() {
          _run.liftTape(i);
          _ghost = p;
        });
        return;
      }
    }
    if (dy >= 14 && dy < 120 && p.dx > M5AnnealGeo.benchL && p.dx < M5AnnealGeo.benchR) {
      if (holdForCoworker()) return;
      _pan = _Pan.cut;
      _panFrom = p;
      _panAt = p;
    }
  }

  int? _tapeNear(double x, M5AnnealGeo geo, double within) {
    int? best;
    var bestD = within;
    for (final (i, u) in _run.tapes.indexed) {
      final d = (geo.xOf(u) - x).abs();
      if (d <= bestD) {
        best = i;
        bestD = d;
      }
    }
    return best;
  }

  void _panUpdate(Offset p) {
    final geo = _geoNow;
    if (geo == null) return;
    switch (_pan) {
      case _Pan.turn:
        if (!_canPlay || _run.clampOff) return;
        final a = _angle(p - geo.nut);
        var d = a - _lastAngle;
        if (d > math.pi) d -= 2 * math.pi;
        if (d < -math.pi) d += 2 * math.pi;
        _lastAngle = a;
        setState(() => _turn += d.abs());
        if (_turn >= 2 * math.pi) _unbolt();
      case _Pan.newTape:
      case _Pan.moveTape:
        setState(() => _ghost = p);
      case _Pan.cut:
        _panAt = p;
      case _Pan.none:
        break;
    }
  }

  void _panEnd() {
    final geo = _geoNow;
    final mode = _pan;
    _pan = _Pan.none;
    if (geo == null) return;
    switch (mode) {
      case _Pan.newTape:
      case _Pan.moveTape:
        final at = _ghost;
        setState(() => _ghost = null);
        if (at != null && _canPlay && _onLine(geo, at) && _run.placeTape(geo.uOf(at.dx))) {
          _tick('sounds/learn/tag_slap.ogg', 0.5);
          setState(() => _wake++);
        } else {
          _hints.missTap();
        }
      case _Pan.cut:
        final a = _panFrom;
        final b = _panAt;
        _panFrom = _panAt = null;
        if (a == null || b == null || !_canPlay) return;
        // Across the drawn line (the jumper's U, a drooping end) where it swept.
        final line = _lineY(geo, geo.uOf((a.dx + b.dx) / 2));
        final ya = a.dy - line;
        final yb = b.dy - line;
        if (ya * yb >= 0 || ya.abs() < 8 || yb.abs() < 8) {
          _hints.missTap();
          return;
        }
        final cx = a.dx + (b.dx - a.dx) * (-ya) / (yb - ya);
        final i = _tapeNear(cx, geo, 22);
        if (i == null) {
          _hints.missTap();
          return;
        }
        _cut(i, _globalOf(Offset(cx, line)));
      case _Pan.turn:
        break;
      case _Pan.none:
        if (!_run.site && _canPlay) _hints.missTap();
    }
  }

  Offset _globalOf(Offset scene) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return scene;
    return box.localToGlobal(scene);
  }

  void _unbolt() {
    _run.unbolt();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    HapticFeedback.mediumImpact();
    setState(() {
      _dropTok++;
      _dropAt = _run.index;
      _wake++;
    });
    // The jumper: the coworker cuts in the instant the old clamp drops; the
    // next control waits for him.
    if (_run.spot?.kind == M5AnnealKind.jumper && !coworkerDone) {
      scheduleCoworker();
      return;
    }
    unawaited(_sayChain([M5AnnealLines.askJudge]));
  }

  void _bend(Offset p) {
    final geo = _geoNow;
    if (!_canPlay || _run.site || geo == null || !_run.clampOff) return;
    if (!_onLine(geo, p)) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    final u = geo.uOf(p.dx);
    final stays = _run.bend(u);
    if (stays == null) {
      _hints.missTap();
      return;
    }
    _tick(stays ? 'sounds/intro/tick.ogg' : 'sounds/intro/click.ogg', 0.5);
    setState(() {
      _bendAt = u;
      _bendStays = stays;
      _bendTok++;
      _wake++;
    });
  }

  void _cut(int i, Offset global) {
    if (!_canPlay) return;
    _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    final m = _run.cut(i);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    HapticFeedback.lightImpact();
    if (_run.roundDone) {
      setState(() => _fitTok++);
      unawaited(_roundDone());
    }
  }

  void _connectorOnly(Offset global) {
    if (!_canPlay || _run.site || !_run.clampOff) return;
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final m = _run.connectorOnly();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.roundDone) {
      setState(() => _fitTok++);
      unawaited(_roundDone());
    }
  }

  void _tapScene(Offset p, M5AnnealGeo geo, Offset global) {
    if (_run.site) {
      _tapSite(p, geo, global);
      return;
    }
    if (_canPlay) _hints.missTap();
  }

  // --- rounds ----------------------------------------------------------------------
  Future<void> _roundDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = _run.index;
    final s = _run.spot;
    final bare = _run.deal.bare;
    unawaited(askReason(
      deal: () => dealChoices(s == null ? M5AnnealLines.siteWhy(bare) : M5AnnealLines.spotWhy(s), M5AnnealLines.mythsFor(s), widget.rng),
      question: s == null ? M5AnnealLines.siteQuestion(bare) : M5AnnealLines.spotQuestion(s),
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
  CoworkerScript get coworkerScript => M5AnnealLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final s = _run.spot;
    if (_ended || s == null || s.kind != M5AnnealKind.jumper || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy || _freeze || !_run.clampOff) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: a slip; the spot goes on.
      await _mistake(_run.listened(), origin);
      return;
    }
    _run.caught.add(M5AnnealLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5AnnealLines.callHeld, M5AnnealLines.askJudge], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5AnnealLines.tapWhy[_nudgeN++ % M5AnnealLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('annealcut/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up the line with an end bare: the scene freezes grey and the flash comes
  /// off the bare end in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _testTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _testLeft = null;
      _held = null;
      _toolGhost = null;
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
    final speak = await SpokenOnce.first('annealcut/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5AnnealLines.deadlyWord : M5AnnealLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same round goes on from where it was.
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
    await _say(!_run.passed ? M5AnnealLines.fail : (_quickBonus ? M5AnnealLines.quick : M5AnnealLines.allSet),
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

  /// A design-px rect of the scene on screen (null before layout).
  Rect? _sceneRect(Rect r) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  /// The gesture hand: how to touch, never what. The section: a sweep over
  /// every tool and both ends. The bench: a lap round the nut (the kit has no
  /// circular hand yet, so a sweep over four points round it, back to the
  /// first); then a hold at one fixed place along the conductor (whatever the
  /// spot); then a tape lifted off the tray (the same on every spot, cut or
  /// not); a cut sweep across the player's own tape. The connector button is
  /// never hinted.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    if (_run.site) {
      final rects = [
        for (final t in _tools) ?HintSpec.globalRectOf(_toolKeys[t]!),
        ?_sceneRect(geo.endHit(true)),
        ?_sceneRect(geo.endHit(false)),
      ];
      return rects.length < 2 ? null : HintSpec.sweep(rects);
    }
    if (!_run.clampOff) return HintSpec.sweep(m5AnnealNutLap(geo.nut), space: HintSpace.scene);
    if (_run.tapes.isNotEmpty) {
      final u = _run.tapes.first;
      return HintSpec.swipe(Offset(geo.xOf(u), _lineY(geo, u) - 44), toward: const Offset(0, 1), travel: 88, space: HintSpace.scene);
    }
    if (!_run.bent) return HintSpec.hold(Offset(geo.xOf(M5AnnealGeo.holdU), _lineY(geo, M5AnnealGeo.holdU)), space: HintSpace.scene);
    return HintSpec.drag(geo.tray.center, toward: const Offset(0, -1), travel: 64, space: HintSpace.scene);
  }

  M5AnnealBench _bench(M5AnnealSpot s, {double flex = 0, bool settled = true}) => M5AnnealBench(
        kind: s.kind,
        lo: s.lo,
        hi: s.hi,
        jumperRight: s.jumperRight,
        clampOff: _run.clampOff,
        turn: _run.clampOff ? 0 : -_turn,
        endL: _run.endL,
        endR: _run.endR,
        darkL: _run.darkL,
        darkR: _run.darkR,
        tapes: List.unmodifiable(_run.tapes),
        trayLeft: _run.trayLeft - (_ghost != null ? 1 : 0),
        kinks: List.unmodifiable(settled ? _run.kinks : _run.kinks.where((k) => k != _bendAt)),
        fitted: _run.fitted,
        flexAt: _bendAt,
        flex: flex,
        ghost: _ghost,
      );

  static const _icons = {
    M5AnnealTool.tester: Icons.flash_on_rounded,
    M5AnnealTool.earth: Icons.cable_rounded,
    M5AnnealTool.climb: Icons.north_rounded,
  };

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5AnnealGeo.forScene(m.height, m.inset);
    widget.probe?.geo = geo;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final s = _run.spot;
    final light = _run.deal.light;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              if (s == null) ...[
                Positioned.fill(
                  key: const ValueKey('site'),
                  child: RepaintBoundary(
                    child: CustomPaint(painter: M5AnnealSitePainter(geo: geo, light: light, earthL: _run.earthL, earthR: _run.earthR, seed: _seed)),
                  ),
                ),
                Positioned.fromRect(
                  key: const ValueKey('trainee'),
                  rect: geo.ground,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ] else
                Positioned.fill(
                  key: ValueKey('bench-${_run.index}'),
                  child: RepaintBoundary(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey('bend-$_bendTok'),
                      tween: Tween(begin: quiet || _bendTok == 0 ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      builder: (_, v, _) {
                        final settled = v >= 1;
                        final flex = settled ? 0.0 : (_bendStays ? (v < 0.5 ? v * 2 : 1 - 0.43 * (v - 0.5) * 2) : math.sin(v * math.pi));
                        return CustomPaint(painter: M5AnnealBenchPainter(geo: geo, light: light, bench: _bench(s, flex: flex, settled: settled)));
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // The old clamp dropping away.
      if (s != null && _dropTok > 0 && _dropAt == _run.index && _run.clampOff && !_freeze)
        Positioned(
          key: ValueKey('drop-$_dropTok'),
          left: geo.nut.dx - (s.kind == M5AnnealKind.sleeve ? m5AnnealSleeveW / 2 : 23),
          top: geo.nut.dy - (s.kind == M5AnnealKind.sleeve ? 9 : 12),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 650),
              builder: (_, v, child) => v >= 1
                  ? const SizedBox.shrink()
                  : Transform.translate(
                      offset: Offset(8 * v, 260 * v * v),
                      child: Transform.rotate(angle: 1.4 * v, child: Opacity(opacity: 1 - v * 0.6, child: child)),
                    ),
              child: s.kind == M5AnnealKind.sleeve
                  ? Container(
                      width: m5AnnealSleeveW,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF9C8F7E), Color(0xFF7A4E2E), Color(0xFF4E4A72), Color(0xFF7A4E2E), Color(0xFF9C8F7E)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )
                  : Container(
                      width: 46,
                      height: 24,
                      decoration: BoxDecoration(color: const Color(0xFF2E2824), borderRadius: BorderRadius.circular(4)),
                    ),
            ),
          ),
        ),
      // The repair fitted: a green glow that fades.
      if (s != null && _fitTok > 0 && _run.fitted && !_freeze)
        Positioned(
          key: ValueKey('fit-$_fitTok'),
          left: geo.xOf(_run.endL) - 18,
          width: geo.xOf(_run.endR) - geo.xOf(_run.endL) + 36,
          top: geo.condY - 22,
          height: 44 + (s.kind == M5AnnealKind.jumper ? m5AnnealUDepth : (s.kind == M5AnnealKind.snapped ? m5AnnealSnapDroop : 0)),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 1100),
              builder: (_, v, _) => v <= 0.001
                  ? const SizedBox.shrink()
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: SlmColors.success.withValues(alpha: v), width: 3),
                      ),
                    ),
            ),
          ),
        ),
      // The tester's reading at an end: R, Y, B in turn, each 0 V.
      if (s == null && _testLeft != null && !_freeze)
        Positioned(
          key: ValueKey('tester-$_testTok'),
          left: geo.testerAt(_testLeft!).dx,
          top: geo.testerAt(_testLeft!).dy,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, _) => _TesterChip(shown: (v * 3).ceil().clamp(1, 3)),
            ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5AnnealLines.sceneLabel,
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onLongPressStart: (d) => _bend(d.localPosition),
            onPanStart: (d) => _panStart(d.localPosition),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: () {
              _pan = _Pan.none;
              if (_ghost != null) setState(() => _ghost = null);
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
              builder: (_, v, _) => CustomPaint(painter: M5AnnealFlashPainter(at: geo.flashAt(_run.deal.bareLeft), v: v)),
            ),
          ),
        ),
      // The next round: a short fade.
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
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final ghost = _toolGhost;
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
              labels: M5AnnealLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, M5AnnealRun.roundCount); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _pan == _Pan.none && _ghost == null && ghost == null && !coworkerDue,
            hintKey: '${_run.index}/${_run.clampOff}/${_run.tapes.length}/${_run.bent}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && _run.site)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in _tools)
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: _icons[t]!,
                          label: M5AnnealLines.toolLabel(t),
                          on: _held == t,
                          onTap: (g) => _useTool(t, g),
                          onDrag: t == M5AnnealTool.climb ? null : (g, {required bool end}) => _toolDrag(t, g, end: end),
                        ),
                    ],
                  ),
                ),
              if (handsOn && !_run.site && _run.clampOff)
                Positioned(
                  key: const ValueKey('hud-connector'),
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + 12,
                  child: Center(
                    child: _ConnectorButton(
                      key: const ValueKey('anneal-connector-only'),
                      label: M5AnnealLines.connectorOnly,
                      onTap: _connectorOnly,
                    ),
                  ),
                ),
              if (ghost != null && _held != null)
                Positioned(
                  key: const ValueKey('tool-ghost'),
                  left: ghost.dx - 22,
                  top: ghost.dy - 22,
                  child: IgnorePointer(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xCC1C2E4A),
                        border: Border.all(color: SlmColors.gold300, width: 2),
                      ),
                      child: Icon(_icons[_held!], color: SlmColors.gold300, size: 22),
                    ),
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
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: !coworkerOnScreen || coworkerFromRight),
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
                  line: M5AnnealLines.intro,
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
}

// ============================================================================
// Pieces
// ============================================================================

/// The tester's reading at an end: R, Y, B in turn ([shown] of them), 0 V.
class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.shown});
  final int shown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Opacity(
              opacity: i < shown ? 1 : 0,
              child: Text('${M5AnnealLines.phases[i]} ${M5AnnealLines.dead}',
                  style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A section tool: a round icon with its name under it; lit while in hand.
/// Tap to take it; or drag it straight onto an end.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap, this.onDrag});
  final IconData icon;
  final String label;
  final bool on;
  final ValueChanged<Offset> onTap;
  final void Function(Offset global, {required bool end})? onDrag;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    Offset? last;
    final drag = onDrag;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onTapUp: (d) => onTap(d.globalPosition),
        onPanStart: drag == null
            ? null
            : (d) {
                last = d.globalPosition;
                drag(d.globalPosition, end: false);
              },
        onPanUpdate: drag == null
            ? null
            : (d) {
                last = d.globalPosition;
                drag(d.globalPosition, end: false);
              },
        onPanEnd: drag == null ? null : (_) => drag(last ?? Offset.zero, end: true),
        child: SizedBox(
          width: 84,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.6 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 26, color: ring),
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
                    style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 'কাটার দরকার নেই — শুধু কানেক্টর': a plain pill (no glow, no hint).
class _ConnectorButton extends StatelessWidget {
  const _ConnectorButton({super.key, required this.label, required this.onTap});
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
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xE60B1324),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.6),
          ),
          child: Text(label, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}
