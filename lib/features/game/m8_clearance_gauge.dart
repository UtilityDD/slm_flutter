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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_clearance_gauge_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_clearance_gauge_world.dart' show M8GaugeKind, M8GaugeSpan, M8GaugeProfile, M8Traffic, M8Vehicle, kM8GaugeProbes, m8GaugeText, m8GaugeRuleM, m8GaugeSnap;

// Lesson 8.5 "সেফটি কোড (Safety Code): সুরক্ষার স্থানীয় আইন", কাজ 1 "ঝুলে পড়া
// তার — মেপে দেখুন" (pack do_8_5_a, engineType m8_clearance_gauge). A patrol day
// in a small town: five spans — 11 kV road spans seen from the side (the height
// from the LOCAL ground to the wire, so a hump, a raised edge, an embankment or
// unequal poles move the worst point off mid-span; some carry covered
// conductor) and LT house spans seen from above (the horizontal gap from the
// house front or balcony to the line). Lesson 8.5 and the rulings: across a
// road 11 kV needs 6.5 m (A2, M8-12); beside a house LT needs 1.2 m.
//
// NEW CORE ACTION (ruling M8-20 — distinct from do_7_3_a's two-handle tape,
// rule drum and phone): SAMPLE the span. The trainee lays up to four plumb
// probes by tapping along it; each shows one plain number (a dashed line and
// one reading, no colour, no target, the rule never on screen); a tap on a
// probe lifts it. Once there is a reading, two equal stamps (their sides dealt)
// appear on the patrol logbook; a stamp is PRESSED AND HELD to book it. The
// worst point is not marked and a low span is low over a broad stretch (at
// least 30 % of its length), so spread-out probes always find it; the
// judgement is the player's: 'আইন মানছে' or 'আইন ভাঙছে'.
//
//  * right 'ভাঙছে' → a tag ties on the pole, praise → ◆ → 'কেন খাতায় তুললেন?'.
//  * right 'মানছে' → a small ◆; once a play the deck 'কেন ঠিক লিখলেন?'.
//  * wrong stamp = slip: a probe glides to the true worst point and reads it, the
//    MistakeCard follows, the span goes on from where it was.
//
// The careless coworker comes once a play (two beats). Myth script (only when a
// covered 11 kV span is dealt — lesson 8.5 myth 2, word for word) on that span's
// first stamp touch; shortcut script on the first probe touch of his span. The
// control waits for him (holdForCoworker). Listening = a slip (X2/B1: what he
// pushes is not deadly here). No deadly act in this level (M8-1, M8-12): the
// patrol is from the ground and the harm is to the public. Three slips strike
// out. Wrong card in a 'why' deck costs the ◆ only (M8-8).
//
// Gesture hands: before any probe a plain tap on the span (how, never where);
// with a reading a sweep over both stamps; decks have their own.

// ============================================================================
// Content
// ============================================================================

/// What a span's reason asks about (always something the player did).
enum M8GaugeWhy { roadBreach, ltBreach, roadOk, ltOk }

/// Which coworker script is dealt.
enum M8GaugeScript { myth, shortcut }

abstract final class M8ClearanceGaugeLines {
  static const title = 'ঝুলে পড়া তার — মেপে দেখুন';
  // DRAFT wording — owner (M6-12 / M8-14).
  static const intro = 'টহলের দিন! কোন তার আইনের চেয়ে বেশি নিচু বা বাড়ির বেশি কাছে—মেপে খাতায় তুলুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askSpan = 'এই স্প্যানটা মেপে দেখুন।';
  static const askSpanOther = 'তারের গায়ে ছুঁয়ে মাপ ফেলে দেখুন, কোথায় কত।';
  static const askStamp = 'মাপ দেখে রায় দিন — ছাপ চেপে ধরে রাখুন।';
  static const askStampOther = 'আরও মাপ ফেলতে পারেন, তারপর ছাপ চেপে ধরুন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askSpan, askSpanOther, askStamp, askStampOther];

  // On-screen words (a worker's own; not spoken).
  static const sceneLabel = 'টহলের পথ';
  static const logbookLabel = 'টহলের খাতা';
  static const stampOk = 'আইন মানছে';
  static const stampBreach = 'আইন ভাঙছে';
  static String spanName(int n) => enDigits('স্প্যান $n');

  static const whyQ = <M8GaugeWhy, String>{
    M8GaugeWhy.roadBreach: 'কেন এই তারটা খাতায় তুললেন?',
    M8GaugeWhy.ltBreach: 'কেন বারান্দার পাশের তারটা খাতায় তুললেন?',
    M8GaugeWhy.roadOk: 'কেন এটা ঠিক লিখলেন?',
    M8GaugeWhy.ltOk: 'কেন এটা ঠিক লিখলেন?',
  };
  static const whyRight = <M8GaugeWhy, List<String>>{
    M8GaugeWhy.roadBreach: ['রাস্তার ওপর 11 kV তার অন্তত 6.5 মিটার উঁচু থাকবে।', 'ঝুলে পড়া তার টাইট করানো আমার আইনি দায়িত্ব।'],
    M8GaugeWhy.ltBreach: ['LT তার বারান্দা থেকে অনুভূমিক 1.2 মিটার দূরে থাকবে।', 'কাপড় মেলতে গিয়ে কেউ যেন তারে না লেগে যায়।'],
    M8GaugeWhy.roadOk: ['সবচেয়ে নিচু জায়গাতেও তার আইনের মাপের ওপরে।', 'ঝুলেছে ঠিকই, কিন্তু আইনের মাপের নিচে নামেনি।'],
    M8GaugeWhy.ltOk: ['সবচেয়ে কাছের জায়গাতেও ফাঁক আইনের চেয়ে বেশি।', 'বারান্দার কাছেও তারের ফাঁক আইনের মাপের বেশি।'],
  };
  static const whyWrong = <M8GaugeWhy, List<String>>{
    M8GaugeWhy.roadBreach: [
      'তারের নিচ দিয়ে বড় গাড়ি কম যায়, তাই ঝুঁকি কম।',
      'মাঝখানে একটু ঝুলবেই, ওটা স্বাভাবিক ব্যাপার।',
      'ঢাকা তার হলে নিচু থাকলেও চলে, তাই ছেড়ে দিই।',
      'খুঁটির কাছে উঁচু থাকলেই যথেষ্ট, মাঝে না হলেও।',
      'রাতে রাস্তায় লোক কম, তাই নিচু হলেও চলে।',
    ],
    M8GaugeWhy.ltBreach: [
      'LT তারে ভোল্টেজ কম, তাই কাছে থাকলেও চলে।',
      'বাড়ির লোক সাবধানে থাকে, তাই দূরত্ব লাগে না।',
      'তার সামান্য কাছে থাকলে বাড়ির কোনো ক্ষতি নেই।',
      'বারান্দায় রেলিং থাকলে তারের কাছে থাকা চলে।',
      'পুরনো বাড়ির বেলায় আইনের মাপ দেখতে হয় না।',
    ],
    M8GaugeWhy.roadOk: [
      'গাড়ি থেকে দেখে ঠিকই লাগল, তাই ঠিক লিখলাম।',
      'এই রাস্তায় বড় গাড়ি তো যায়ই না, তাই ঠিক।',
      'খুঁটির কাছে ফাঁক বেশি ছিল, ওটাই যথেষ্ট।',
      'আগেরবার কেউ আপত্তি করেনি, তাই ঠিক লিখলাম।',
      'তার সোজাই দেখাচ্ছিল, ঝোলা বোঝা যায়নি।',
    ],
    M8GaugeWhy.ltOk: [
      'গাড়ি থেকে দেখে ঠিকই লাগল, তাই ঠিক লিখলাম।',
      'এই লেনে বড় গাড়ি তো যায়ই না, তাই ঠিক।',
      'খুঁটির কাছে ফাঁক বেশি ছিল, ওটাই যথেষ্ট।',
      'আগেরবার কেউ আপত্তি করেনি, তাই ঠিক লিখলাম।',
      'বাড়ির লোক সাবধানে থাকে, তাই ঠিক লিখলাম।',
    ],
  };
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (once a play). Myth: lesson 8.5 myth 2 word for word
  // ('11 kV' on screen, term rule); shortcut: the other way to skip the measure.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerMyth = CoworkerScript(
    line: '11 kV লাইন ইনসুলেটেড থাকে, ধরলে কিছু হয় না।',
    exitLine: coworkerExit,
    right: ['ঢাকা তারকেও খোলা তার ধরব—মাপের আইন একই।', 'পিন-হোল বা ফাটল থাকতে পারে, তাই মাপব।', 'ঢাকা তারও বেয়ার ধরে নিয়ে মেপে দেখব।'],
    wrong: [
      'ঠিক, ইনসুলেটেড তার—নিচু হলেও চলবে।',
      'ঢাকা তার, তাই খাতায় ঠিক লিখে দিই।',
      'ঢাকা তারে মাপের দরকার নেই, থাক।',
      'ইনসুলেটেড তার নিচু থাকলেও ভয় নেই।',
      'ঢাকা তার ধরলে কিছু হয় না, ছেড়ে দিই।',
    ],
    asks: ['কী করবেন?', 'উনি বলছেন ঢাকা তারে মাপ লাগে না। আপনি কী করবেন?', 'ওর কথা শুনবেন, না আইন মানবেন?'],
  );
  static const coworkerShortcut = CoworkerScript(
    line: 'গাড়ি থেকে দেখেই সব ঠিক লিখে দাও, মাপার দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, তার ঝুলেছে কি না দেখা আমার কাজ।', 'না, মেপে দেখে তবেই খাতায় লিখব।', 'গাড়ি থেকে নয়, নেমে মেপে দেখব।'],
    wrong: [
      'ঠিক আছে, না মেপেই ঠিক লিখে দিই।',
      'গাড়ি থেকে ঠিকই লাগছে, লিখে দিই।',
      'সময় নেই, দেখেই ছাপ দিয়ে দিই।',
      'এত মাপামাপি লাগে না, ঠিক লিখি।',
      'আজ তো সব ঠিকই মনে হচ্ছে, থাক।',
    ],
    asks: ['কী করবেন?', 'উনি বলছেন না মেপেই লিখে দিতে। আপনি কী করবেন?', 'ওর কথা শুনবেন, না মেপে দেখবেন?'],
  );
  static CoworkerScript script(M8GaugeScript s) => s == M8GaugeScript.myth ? coworkerMyth : coworkerShortcut;

  static const heldMyth = 'ঠিক! ঢাকা তার হলেও মাপের আইন একই।';
  static const heldShortcut = 'ঠিক! মেপে দেখাই আসল কাজ।';

  static const allSet = 'পাঁচটা স্প্যানই মেপে দেখেছেন — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কয়েক জায়গায় মেপে দেখে, তারপর রায় দিন।';

  // "আজ যা ধরলেন".
  static const caughtLow = 'নিচু ঝুলে পড়া তার ধরে খাতায় তোলা';
  static const caughtNear = 'বাড়ির বেশি কাছের তার ধরে খাতায় তোলা';
  static const caughtOk = 'আইন মানা লাইন চিনেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// His two pushes (to record in his voice; tool/rival_clip.py). His exit is already recorded.
  static List<String> get newRivalLines => [coworkerMyth.line, coworkerShortcut.line];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until then
  /// the device voice). Only the kit's own praise and 'wrong' bags are left out.
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        ...tapWhy,
        ...whyQ.values,
        ...coworkerMyth.asks,
        ...coworkerShortcut.asks,
        heldMyth,
        heldShortcut,
        allSet,
        quick,
        fail,
        for (final m in M8ClearanceGaugeMistakes.all) m.textBn,
      }.toList();
}

abstract final class M8ClearanceGaugeMistakes {
  static const _dir = 'assets/game/art/m8_clearance_gauge';

  // DRAFT wording — owner (M6-12). Lesson 8.5 points: 2 = ground clearance,
  // 3 = building clearance.
  static const missedRoad = DoMistake(
    key: '8.5/m8_clearance_gauge/missed-road',
    textBn: 'রাস্তা পার হওয়া 11 kV লাইন মাটি থেকে অন্তত 6.5 মিটার উঁচুতে থাকবে। এখানে সবচেয়ে নিচু জায়গায় তার কম — খাতায় তুলতে হবে।',
    art: '$_dir/missed_road.svg',
    lessonPoint: 2,
  );
  static const missedLt = DoMistake(
    key: '8.5/m8_clearance_gauge/missed-lt',
    textBn: 'বাড়ি বা বারান্দা থেকে LT তারের অনুভূমিক দূরত্ব অন্তত 1.2 মিটার। এখানে সবচেয়ে কাছের জায়গায় তার কম — খাতায় তুলতে হবে।',
    art: '$_dir/missed_lt.svg',
    lessonPoint: 3,
  );
  static const falseRoad = DoMistake(
    key: '8.5/m8_clearance_gauge/false-road',
    textBn: 'সবচেয়ে নিচু জায়গাতেও তার 6.5 মিটারের ওপরে — লাইন আইন মেনেই আছে। মেপে না দেখে অকারণে খাতায় তুলবেন না।',
    art: '$_dir/false_road.svg',
    lessonPoint: 2,
  );
  static const falseLt = DoMistake(
    key: '8.5/m8_clearance_gauge/false-lt',
    textBn: 'সবচেয়ে কাছের জায়গাতেও ফাঁক 1.2 মিটারের বেশি — লাইন আইন মেনেই আছে। মেপে না দেখে অকারণে খাতায় তুলবেন না।',
    art: '$_dir/false_lt.svg',
    lessonPoint: 3,
  );
  static const listenMyth = DoMistake(
    key: '8.5/m8_clearance_gauge/listen-myth',
    textBn: 'ঢাকা তারকেও বেয়ার তার ধরে নেওয়ার আইন আছে, কারণ পিন-হোল বা ফাটল থাকতে পারে। নিচু হলে খাতায় তুলতে হবে।',
    art: '$_dir/listen_myth.svg',
    lessonPoint: 2,
  );
  static const listenShortcut = DoMistake(
    key: '8.5/m8_clearance_gauge/listen-shortcut',
    textBn: 'গাড়ি থেকে দেখে মাপ হয় না। ঝুলে পড়া তার টাইট করানো আপনার আইনি দায়িত্ব — আগে মেপে দেখুন।',
    art: '$_dir/listen_shortcut.svg',
    lessonPoint: 2,
  );

  static DoMistake missed(M8GaugeKind k) => k == M8GaugeKind.road ? missedRoad : missedLt;
  static DoMistake falseReport(M8GaugeKind k) => k == M8GaugeKind.road ? falseRoad : falseLt;
  static DoMistake listen(M8GaugeScript s) => s == M8GaugeScript.myth ? listenMyth : listenShortcut;

  static const List<DoMistake> all = [missedRoad, missedLt, falseRoad, falseLt, listenMyth, listenShortcut];
}

/// The reason a span asks about.
M8GaugeWhy m8GaugeWhy(M8GaugeSpan s) => switch ((s.kind, s.breach)) {
      (M8GaugeKind.road, true) => M8GaugeWhy.roadBreach,
      (M8GaugeKind.lt, true) => M8GaugeWhy.ltBreach,
      (M8GaugeKind.road, false) => M8GaugeWhy.roadOk,
      (M8GaugeKind.lt, false) => M8GaugeWhy.ltOk,
    };

@immutable
class M8GaugeDeal {
  const M8GaugeDeal({required this.spans, required this.coworkerSpan, required this.script, required this.stampsSwapped, required this.okReasonSpan});

  final List<M8GaugeSpan> spans;

  /// The span he comes on.
  final int coworkerSpan;
  final M8GaugeScript script;

  /// 'আইন ভাঙছে' stands left of 'আইন মানছে'.
  final bool stampsSwapped;

  /// The one sound span that asks its reason.
  final int okReasonSpan;
}

/// Five spans: 3 road + 2 LT or 2 + 3, shuffled; 2–3 of them breach (never 0 or 5).
M8GaugeDeal m8GaugeDeal(math.Random rng) {
  final roads = rng.nextBool() ? 3 : 2;
  final kinds = [for (var i = 0; i < 5; i++) i < roads ? M8GaugeKind.road : M8GaugeKind.lt]..shuffle(rng);
  final nBreach = 2 + rng.nextInt(2);
  final breach = [for (var i = 0; i < 5; i++) i < nBreach]..shuffle(rng);
  final spans = [
    for (var i = 0; i < 5; i++)
      M8GaugeSpan.deal(rng, kind: kinds[i], breach: breach[i], covered: kinds[i] == M8GaugeKind.road && rng.nextDouble() < 0.45),
  ];
  final covered = [for (var i = 0; i < 5; i++) if (spans[i].covered) i];
  final script = covered.isNotEmpty ? M8GaugeScript.myth : M8GaugeScript.shortcut;
  final span = covered.isNotEmpty ? covered[rng.nextInt(covered.length)] : rng.nextInt(5);
  final sound = [for (var i = 0; i < 5; i++) if (!spans[i].breach) i];
  return M8GaugeDeal(spans: spans, coworkerSpan: span, script: script, stampsSwapped: rng.nextBool(), okReasonSpan: sound[rng.nextInt(sound.length)]);
}

/// The play state (pure logic).
class M8GaugeRun {
  M8GaugeRun(this.deal) {
    _startSpan();
  }
  final M8GaugeDeal deal;

  int index = 0;
  int slips = 0;
  int siteSlips = 0;
  final List<String> caught = [];

  /// The span's last step is in (its reason or the next span comes).
  var roundDone = false;

  /// The probes laid on this span (t, snapped to the grid).
  final List<double> probes = [];

  /// A wrong stamp reveals the true worst point: where the revealing probe sits.
  double? revealT;

  /// A tag is tied on the pole (a breach was booked).
  var booked = false;

  int get count => deal.spans.length;
  M8GaugeSpan get span => deal.spans[index.clamp(0, count - 1)];
  bool get done => index >= count;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => siteSlips == 0;
  bool get _open => !done && !roundDone;
  bool get isCoworkerSpan => !done && index == deal.coworkerSpan;

  /// There is a reading to judge (a probe is down).
  bool get hasReading => probes.isNotEmpty || revealT != null;
  bool get canStamp => _open && hasReading;

  void _startSpan() {
    roundDone = false;
    siteSlips = 0;
    probes.clear();
    revealT = null;
    booked = false;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    siteSlips++;
    return m;
  }

  /// A tap along the span at [t]: lifts a probe near it, or lays a new one (up
  /// to [kM8GaugeProbes]). True when something changed.
  bool tap(double t) {
    if (!_open) return false;
    final i = probes.indexWhere((p) => (p - t).abs() < 0.035);
    if (i >= 0) {
      probes.removeAt(i);
      return true;
    }
    if (probes.length >= kM8GaugeProbes) return false;
    final s = m8GaugeSnap(t);
    if (probes.contains(s)) return false;
    probes.add(s);
    return true;
  }

  /// The smallest reading among the probes (tenths), or null.
  int? get lowestReadingT {
    final all = [...probes, ?revealT];
    if (all.isEmpty) return null;
    return all.map(span.readingT).reduce(math.min);
  }

  /// A stamp pressed through: [breach] = 'আইন ভাঙছে'. A wrong one is a slip
  /// and reveals the worst point.
  DoMistake? stamp({required bool breach}) {
    if (!canStamp) return null;
    if (breach != span.breach) {
      revealT = span.minT;
      return _slip(span.breach ? M8ClearanceGaugeMistakes.missed(span.kind) : M8ClearanceGaugeMistakes.falseReport(span.kind));
    }
    if (breach) {
      booked = true;
      _tag(span.isRoad ? M8ClearanceGaugeLines.caughtLow : M8ClearanceGaugeLines.caughtNear);
    } else {
      _tag(M8ClearanceGaugeLines.caughtOk);
    }
    roundDone = true;
    return null;
  }

  /// Listened to the coworker (a slip).
  DoMistake pushSlip() => _slip(M8ClearanceGaugeMistakes.listen(deal.script));

  void next() {
    index++;
    if (!done) _startSpan();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a span: 3 probes ≈ 4500, the stamp hold ≈ 2000, a reason ≈ 8200 (3–4 spans)
///   5 spans ≈ 32500 + 3.5 × 8200 ≈ 28700 + the coworker ≈ 9600  ≈ 70800; 85 % ≈ 60000
///   → 60 s (a builder's estimate; owner may tune after playtest, M8-15).
const m8ClearanceGaugeQuickMs = 60000;

/// A stamp is pressed this long to book it.
const int kM8GaugeHoldMs = 650;

@immutable
class M8ClearanceGaugePack {
  const M8ClearanceGaugePack({required this.id, required this.titleBn, this.quickMs = m8ClearanceGaugeQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8ClearanceGaugePack> m8ClearanceGaugePacks = {
  'do_8_5_a': M8ClearanceGaugePack(id: 'do_8_5_a', titleBn: M8ClearanceGaugeLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8ClearanceGaugeProbe {
  static M8GaugeRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M8ClearanceGaugePage extends StatefulWidget {
  const M8ClearanceGaugePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8ClearanceGaugePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8ClearanceGaugePage> createState() => _M8ClearanceGaugePageState();
}

class _M8ClearanceGaugePageState extends State<M8ClearanceGaugePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GaugeRunPage(
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

class _GaugeRunPage extends ConsumerStatefulWidget {
  const _GaugeRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8ClearanceGaugePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_GaugeRunPage> createState() => _GaugeRunPageState();
}

class _GaugeRunPageState extends ConsumerState<_GaugeRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8GaugeRun _run;
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

  /// 'ছাপ চেপে ধরুন' was asked for on this span (said once).
  var _askedStamp = false;

  /// The stamp being pressed ('আইন ভাঙছে' = true) and how far.
  bool? _holding;
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: kM8GaugeHoldMs), animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener(_holdStatus);

  /// The revealing probe's glide to the worst point.
  late final AnimationController _glide = AnimationController(vsync: this, duration: const Duration(milliseconds: 700), animationBehavior: AnimationBehavior.preserve);
  double? _glideFrom;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _stampKeys = [GlobalKey(), GlobalKey()];
  int _hintN = 0;
  int _steps = 0;
  M8GaugeGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8GaugeRun(m8GaugeDeal(widget.rng));
    M8ClearanceGaugeProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _hold.dispose();
    _glide.dispose();
    _chain++;
    if (identical(M8ClearanceGaugeProbe.run, _run)) M8ClearanceGaugeProbe.run = null;
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

  M8GaugeSpan get _span => _run.span;
  M8GaugeDeal get _deal => _run.deal;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone;

  String get _task => _run.hasReading ? M8ClearanceGaugeLines.askStamp : M8ClearanceGaugeLines.askSpan;

  Future<void> _start() async {
    _clock.start();
    _startSpan();
  }

  void _startSpan() {
    setState(() {
      _wake++;
      _askedStamp = false;
      _holding = null;
      _hold.value = 0;
      _glide.value = 1;
      _glideFrom = null;
    });
    unawaited(_sayChain([_run.index == 0 ? M8ClearanceGaugeLines.askSpan : M8ClearanceGaugeLines.askSpanOther]));
    // The shortcut script: he is due from the start of his span; the first
    // probe touch waits for him.
    if (_run.isCoworkerSpan && _deal.script == M8GaugeScript.shortcut && !coworkerDone && !coworkerDue) scheduleCoworker();
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- the probes ---------------------------------------------------------------
  void _tapScene(Offset p, M8GaugeGeo geo) {
    if (!_canPlay) return;
    if (!geo.onSpan(p)) {
      _hints.missTap();
      return;
    }
    if (_run.isCoworkerSpan && _deal.script == M8GaugeScript.shortcut && holdForCoworker()) return;
    final lifted = _run.probes.any((q) => (q - geo.tOf(p.dx)).abs() < 0.035);
    if (!_run.tap(geo.tOf(p.dx))) {
      // Four probes are down and this is not on one: nothing changes.
      _hints.missTap();
      return;
    }
    _tick(lifted ? 'sounds/intro/tick.ogg' : 'sounds/intro/click.ogg', lifted ? 0.4 : 0.55);
    _stepDone();
    if (_run.hasReading && !_askedStamp) {
      _askedStamp = true;
      unawaited(_sayChain([M8ClearanceGaugeLines.askStamp]));
    }
    // The myth script: he comes once the first reading is down, on his span.
    if (_run.isCoworkerSpan && _deal.script == M8GaugeScript.myth && _run.hasReading && !coworkerDone && !coworkerDue) scheduleCoworker();
  }

  // --- the stamps (pressed and held) ------------------------------------------------
  void _stampDown(bool breach) {
    if (!_canPlay || !_run.canStamp || _holding != null) return;
    if (_run.isCoworkerSpan && _deal.script == M8GaugeScript.myth && holdForCoworker()) return;
    HapticFeedback.selectionClick();
    setState(() => _holding = breach);
    _hold.forward(from: 0);
  }

  void _stampUp() {
    if (_holding == null) return;
    if (_hold.isCompleted) return;
    _hold
      ..stop()
      ..value = 0;
    setState(() => _holding = null);
  }

  void _holdStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    final breach = _holding;
    setState(() => _holding = null);
    _hold.value = 0;
    if (breach == null || !_canPlay) return;
    _stamp(breach);
  }

  void _stamp(bool breach) {
    final size = MediaQuery.sizeOf(context);
    final at = Offset(size.width / 2, size.height - 120);
    final from = _run.probes.isEmpty ? 0.5 : _run.probes.last;
    final m = _run.stamp(breach: breach);
    if (m != null) {
      // The truth, shown: a probe glides to the worst point and reads it.
      _glideFrom = from;
      if (_quiet) {
        _glide.value = 1;
      } else {
        unawaited(_glide.forward(from: 0));
      }
      setState(() => _wake++);
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.7);
    _stepDone();
    final idx = _run.index;
    if (_run.span.breach || idx == _deal.okReasonSpan) {
      unawaited(_spanDone());
      return;
    }
    // A sound span with no reason this time: a small ◆ and on.
    unawaited(_levelDelta(5, at, mood: GuideMood.glad));
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  Future<void> _spanDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = m8GaugeWhy(_span);
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M8ClearanceGaugeLines.whyRight[topic]!, M8ClearanceGaugeLines.whyWrong[topic]!, widget.rng),
      question: M8ClearanceGaugeLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startSpan();
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
  CoworkerScript get coworkerScript => M8ClearanceGaugeLines.script(_deal.script);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !_run.isCoworkerSpan || _run.roundDone) return null;
    if (_deal.script == M8GaugeScript.myth && !_run.hasReading) return false;
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
    _run.caught.add(M8ClearanceGaugeLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    final line = _deal.script == M8GaugeScript.myth ? M8ClearanceGaugeLines.heldMyth : M8ClearanceGaugeLines.heldShortcut;
    unawaited(_sayChain([line, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8ClearanceGaugeLines.tapWhy[_nudgeN++ % M8ClearanceGaugeLines.tapWhy.length]
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
      _holding = null;
      _hold.value = 0;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8gauge/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same span goes on from where it was.
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
    await _say(!_run.passed ? M8ClearanceGaugeLines.fail : (_quickBonus ? M8ClearanceGaugeLines.quick : M8ClearanceGaugeLines.allSet),
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
    if (_holding != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what (see the header comment).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    if (!_run.hasReading) {
      // A plain tap on the span; the spot is a generic one, never the worst point.
      final t = 0.28 + 0.44 * ((n * 37) % 10) / 10;
      final y = _span.isRoad ? geo.floorY - geo.scaleRoad * 5.5 : geo.yLine0 + geo.scaleLt * 1.2;
      return HintSpec.tap(Offset(geo.x(t), y), space: HintSpace.scene);
    }
    return HintSpec.sweepOver(_stampKeys);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8GaugeGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final span = _span;
    final glideTo = _run.revealT;
    return [
      Positioned.fill(
        key: ValueKey('span-${_run.index}'),
        child: RepaintBoundary(child: CustomPaint(painter: M8GaugeScenePainter(geo: geo, span: span))),
      ),
      Positioned.fill(
        key: ValueKey('traffic-${_run.index}'),
        child: IgnorePointer(
          child: RepaintBoundary(
            child: AwakeClock(
              wake: _wake,
              quiet: quiet,
              builder: (context, t) => CustomPaint(painter: M8TrafficPainter(geo: geo, span: span, clock: t)),
            ),
          ),
        ),
      ),
      if (span.isRoad)
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: geo.trainee(span),
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      Positioned.fill(
        key: const ValueKey('probes'),
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M8ProbePainter(
                geo: geo,
                span: span,
                ts: List.of(_run.probes),
                glideFrom: glideTo == null ? null : _glideFrom,
                glideTo: glideTo,
                glide: _glide,
                booked: _run.booked,
              ),
            ),
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8ClearanceGaugeLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
          ),
        ),
      ),
      // The next span: a short fade.
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

  Widget _logbook() {
    final stamps = [
      (breach: false, label: M8ClearanceGaugeLines.stampOk),
      (breach: true, label: M8ClearanceGaugeLines.stampBreach),
    ];
    if (_deal.stampsSwapped) stamps.setAll(0, [stamps[1], stamps[0]]);
    return Container(
      key: const ValueKey('gauge-logbook'),
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
              Text(M8ClearanceGaugeLines.logbookLabel, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF6A5230))),
              const SizedBox(width: 8),
              Text(M8ClearanceGaugeLines.spanName(_run.index + 1), style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF3A2E1C))),
              const Spacer(),
              // The probes laid (filled) of the four.
              for (var i = 0; i < kM8GaugeProbes; i++)
                Container(
                  key: ValueKey('probe-dot-$i'),
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(left: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _run.probes.length ? const Color(0xFF1C2E4A) : Colors.transparent,
                    border: Border.all(color: const Color(0xFF1C2E4A), width: 1.4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 58,
            child: Row(
              children: [
                for (final (i, s) in stamps.indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _StampButton(
                      key: _stampKeys[i],
                      buttonKey: ValueKey('gauge-stamp-${s.breach ? 'breach' : 'ok'}'),
                      label: s.label,
                      hold: _hold,
                      active: _holding == s.breach,
                      onDown: () => _stampDown(s.breach),
                      onUp: _stampUp,
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
    final logbookUp = handsOn && !tableBusy && _run.hasReading;
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
              labels: [for (var i = 0; i < _run.count; i++) M8ClearanceGaugeLines.spanName(i + 1)],
              done: {for (var i = 0; i < math.min(_run.index, _run.count); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _holding == null && !_hold.isAnimating,
            hintKey: '${_run.index}/$_steps/${_run.hasReading}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (logbookUp)
                Positioned(
                  key: ValueKey('hud-logbook-${_run.index}'),
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + 10,
                  child: _logbook(),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (logbookUp ? 156 : 84)), onLeft: coworkerFromRight),
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
                  line: M8ClearanceGaugeLines.intro,
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

/// A verdict stamp (both alike): press and hold; a ring fills while held.
class _StampButton extends StatelessWidget {
  const _StampButton({super.key, required this.buttonKey, required this.label, required this.hold, required this.active, required this.onDown, required this.onUp});

  final Key buttonKey;
  final String label;
  final Animation<double> hold;
  final bool active;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: Container(
          key: buttonKey,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 3))],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (active)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: hold,
                        builder: (_, _) => Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(widthFactor: hold.value.clamp(0.0, 1.0), heightFactor: 1, child: const ColoredBox(color: Color(0x44F7D046))),
                        ),
                      ),
                    ),
                  ),
                ),
              Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}
