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
import 'm3_dtr_checkup_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_dtr_checkup_world.dart'
    show M3DtrCheckupGeo, M3DtrCheckupGel, M3DtrCheckupLeak, M3DtrCheckupLook, M3DtrCheckupSpot, m3DtrCheckupGelSpent;

// Lesson 3.6 "ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড", কাজ 1
// "ডাক্তারের চোখে DTR" (pack do_3_6_a). Three pole-mounted DTRs a play, live,
// checked from the ground (lesson point 1's daily check: "দূর থেকে দেখুন";
// point 3: the signs are a doctor's stethoscope). Each DTR is dealt fresh:
// one healthy, one that needs a repair docket, one that needs an urgent
// shutdown — in a fresh order, with fresh signs.
// Hands on (inspect + spot): tap the breather (silica gel colour: blue /
// orange good; pink or whitish = change it — the lesson's point 3), the oil
// level gauge on the conservator
// (MIN / MAX), the tank (an oil leak at the bushing gasket, a weld joint or the
// drain valve — point 3), the nameplate (kVA, HV/LV, Dyn11 — pro tip 3), and
// "কান পেতে শুনি" (a soft steady hum is normal; rattling/growling = a serious
// fault inside — point 3, myth 2).
// Then the call (choose): সব ঠিক / মেরামতের ডকেট / জরুরি শাটডাউন.
//   • the full check-up comes first — a call before all five = a slip;
//   • signing a sick DTR off as fine = a slip (the sign that was missed);
//   • a rattle called anything but urgent = a slip;
//   • over-calling (a docket on a healthy DTR, an urgent shutdown for the gel
//     alone) is a slip too (audit 2026-11-11: a needless call costs, and the
//     reply never hints the answer while the DTR is still open); a leak or a
//     low oil level may be called urgent (the film: a leak can burn the
//     transformer).
// The careless coworker comes once a play, one of two pushes (dealt): on the
// leak round after the leak was seen — "একটু তেল চুঁইছে, চলবে!" (listening =
// signing it off: the leak slip); or after a first look on his round — "মাচায়
// উঠে কাছ থেকে দেখো!" (listening = climbing a live DTR: deadly — the act is
// on Module 3's deadly list, MODULE3_LADDER.md row 17). The call buttons wait
// for him (holdForCoworker): a fast call can't skip him.
// Gesture hint (how, never what): a sweep over every part, the listen button
// and the three calls alike, after idle or taps on empty sky.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m3_dtr_checkup_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next DTR by itself. Voice: the guide's lines by device TTS; the
// coworker's pushes are silent with the caption held for a reading time until
// recorded (the kit never gives him the guide's device voice); his exit line
// is recorded.
//
// Flagged to the owner: the three-way call (OK / repair docket / urgent
// shutdown) and which sign goes where are ours — the lesson names the signs
// and says the rattle means a serious fault, not who is called; the kVA
// values on the nameplates (25–250) and the gauge's MIN/MAX marks are ours;
// the lesson's "feel the body by hand for heat" is left out (the film drops
// it too: nobody touches a live DTR in this level); no recorded hum/rattle
// sound yet (the rattle uses a knock cue; the hum is silent).

// ============================================================================
// Content
// ============================================================================

/// The call on a DTR.
enum M3DtrCheckupCall { ok, repair, urgent }

/// What is wrong with a DTR (in the order a slip names them).
enum M3DtrCheckupFinding { rattle, leak, oilLow, gel }

/// The careless coworker's push this play.
enum M3DtrCheckupPush { leak, climb }

@immutable
class M3DtrCheckupCase {
  const M3DtrCheckupCase({required this.id, required this.look});
  final String id;
  final M3DtrCheckupLook look;

  List<M3DtrCheckupFinding> get findings => [
        if (look.rattle) M3DtrCheckupFinding.rattle,
        if (look.leak != M3DtrCheckupLeak.none) M3DtrCheckupFinding.leak,
        if (look.oilLow) M3DtrCheckupFinding.oilLow,
        if (m3DtrCheckupGelSpent(look.gel)) M3DtrCheckupFinding.gel,
      ];

  /// The call the lesson's signs ask for.
  M3DtrCheckupCall get verdict => look.rattle
      ? M3DtrCheckupCall.urgent
      : findings.isEmpty
          ? M3DtrCheckupCall.ok
          : M3DtrCheckupCall.repair;

  /// A leak or low oil may also be called urgent (it can burn the DTR).
  bool accepts(M3DtrCheckupCall c) =>
      c == verdict ||
      (verdict == M3DtrCheckupCall.repair &&
          c == M3DtrCheckupCall.urgent &&
          (findings.contains(M3DtrCheckupFinding.leak) || findings.contains(M3DtrCheckupFinding.oilLow)));
}

abstract final class M3DtrCheckupLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const title = 'ডাক্তারের চোখে DTR';
  static const intro = 'আজ DTR-এর চেকআপ। নিচ থেকে সব লক্ষণ দেখে রায় দিন।';
  static const rounds = ['ক', 'খ', 'গ'];
  static const ask = 'নিচ থেকে DTR-এর সব লক্ষণ দেখে রায় দিন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'DTR';
  static const listen = 'কান পেতে শুনি';
  static const callOk = 'সব ঠিক';
  static const callRepair = 'মেরামতের ডকেট';
  static const callUrgent = 'জরুরি শাটডাউন';
  static String callLabel(M3DtrCheckupCall c) => switch (c) {
        M3DtrCheckupCall.ok => callOk,
        M3DtrCheckupCall.repair => callRepair,
        M3DtrCheckupCall.urgent => callUrgent,
      };

  static String spotName(M3DtrCheckupSpot s) => switch (s) {
        M3DtrCheckupSpot.breather => 'ব্রিদার',
        M3DtrCheckupSpot.gauge => 'তেলের গেজ',
        M3DtrCheckupSpot.tank => 'ট্যাঙ্ক',
        M3DtrCheckupSpot.nameplate => 'নেমপ্লেট',
        M3DtrCheckupSpot.sound => 'শব্দ',
      };

  /// What the ear hears (on the sound close-up).
  static const hum = 'গুনগুন…';
  static const rattle = 'খটখট… গরগর!';

  static String stamp(M3DtrCheckupCall c, int kva) => '${enDigits('$kva')} kVA · ${switch (c) {
        M3DtrCheckupCall.ok => 'সব ঠিক',
        M3DtrCheckupCall.repair => 'মেরামতের ডকেট',
        M3DtrCheckupCall.urgent => 'জরুরি শাটডাউন',
      }}';

  // The reasons: the right ones fit what this DTR showed; the wrong ones are
  // field excuses and myths. 34–42 letters each.
  static String why(M3DtrCheckupCall c) => switch (c) {
        M3DtrCheckupCall.ok => 'কেন সব ঠিক লিখলেন?',
        M3DtrCheckupCall.repair => 'কেন মেরামতের ডকেট?',
        M3DtrCheckupCall.urgent => 'কেন জরুরি শাটডাউন?',
      };
  static const okWhy = [
    'জেলের রং ঠিক, তেল ঠিক, লিক নেই, হামিং মৃদু',
    'সব লক্ষণ দেখেছি — কোথাও কোনো গোলমাল নেই',
    'মৃদু হামিং স্বাভাবিক, জেল আর তেলও ঠিক আছে',
  ];
  static const okWrong = [
    'তাড়া ছিল, তাই না দেখেই সব ঠিক লিখলাম',
    'সাথী বলল ঠিক আছে, তাই আর ভাবিনি কিছু',
    'DTR তো চলছে, তাই নিশ্চয়ই সব ঠিক আছে',
    'বাইরে থেকে নতুন দেখাচ্ছে, তাই ঠিক ধরলাম',
    'গ্রামে আলো জ্বলছে, তাই আর দেখার কিছু নেই',
    'হামিং শুনেছি, তাই জেল-তেল আর দেখিনি',
    'জেলের রং দেখেছি, লিক-শব্দ দেখার দরকার নেই',
  ];
  static const gelPinkWhy = 'নীল জেল গোলাপি হয়েছে — এবার বদলাতে হবে';
  static const gelWhiteWhy = 'জেলের রং সাদাটে হয়েছে — এবার বদলাতে হবে';
  static const gelWhy = 'জেল বাষ্প শুষে রং বদলেছে, বদলানোর সময়';
  static const leakWhy = ['তেল লিক হলে কুলিং আর ইনসুলেশন দুটোই কমে', 'সামান্য লিকও বড় দুর্ঘটনা ডেকে আনতে পারে'];
  static const oilLowWhy = ['তেলের লেভেল কম — DTR অতিরিক্ত গরম হবে', 'গেজে তেল MIN-এর নিচে, এভাবে চালানো ঠিক নয়'];
  static const rattleWhy = ['খটখট-গরগর শব্দ মানে ভেতরে গুরুতর ফল্ট', 'মৃদু হামিং নয়, খটখট — ভেতরে লুজ বা শর্ট'];
  static const faultWrong = [
    'হামিং শব্দ মানেই ভেতরে বড় সমস্যা আছে',
    'কমলা জেল মানেই জেলটা খারাপ হয়ে গেছে',
    'সাথী বলল লিখে দাও, তাই লিখে দিলাম আমি',
    'DTR পুরনো দেখাচ্ছে, তাই রিপোর্ট করলাম',
    'নেমপ্লেটে kVA লেখা আছে, তাই ডকেট লিখলাম',
    'ডকেট লিখলে ছুটি মেলে, তাই লিখে দিলাম',
    'তেলের গেজ দেখিনি, আন্দাজে লিখে দিলাম',
    'লিক বা শব্দ নয়, DTR-এর রং দেখে লিখলাম',
  ];

  static List<String> whyRight(M3DtrCheckupCase c, M3DtrCheckupCall call) {
    if (call == M3DtrCheckupCall.ok) return okWhy;
    final f = c.findings;
    if (f.contains(M3DtrCheckupFinding.rattle)) return rattleWhy;
    return [
      if (f.contains(M3DtrCheckupFinding.leak)) ...leakWhy,
      if (f.contains(M3DtrCheckupFinding.oilLow)) ...oilLowWhy,
      if (f.contains(M3DtrCheckupFinding.gel)) ...[c.look.gel == M3DtrCheckupGel.pink ? gelPinkWhy : gelWhiteWhy, gelWhy],
    ];
  }

  static List<String> whyWrong(M3DtrCheckupCall call) => call == M3DtrCheckupCall.ok ? okWrong : faultWrong;

  static const coworkerExit = 'হুঁ! যা খুশি করুন।';

  /// The careless coworker, push 1: a small leak is fine to him.
  static const coworkerLeak = CoworkerScript(
    line: 'একটু তেল চুঁইছে, চলবে! খাতায় সব ঠিক লিখে দাও।',
    exitLine: coworkerExit,
    right: ['না, লিক ছোট হলেও মেরামতের ডকেট লিখব', 'না, তেল লিক মানে কুলিং-ইনসুলেশন কমছে', 'না, সামান্য লিকও রিপোর্ট করতেই হবে'],
    wrong: [
      'ঠিক, একটু তেলে কিছু হয় না, সব ঠিক লিখি',
      'আচ্ছা, তেল শেষ না হলে চিন্তার কিছু নেই',
      'হ্যাঁ, এত ছোট লিক ডকেটে লেখার কী আছে',
      'ঠিক আছে, পরের মাসে দেখা যাবে খন',
      'হ্যাঁ, গ্রামে আলো তো জ্বলছেই, চলুক',
    ],
    asks: ['ও বলছে লিকটা চলবে। আপনি কী লিখবেন?', 'একটু তেল চুঁইছে — চলবে?', 'সব ঠিক লিখবেন, না ডকেট?'],
  );

  /// Push 2: from the ground you see nothing, he says — climb up.
  static const coworkerClimb = CoworkerScript(
    line: 'নিচ থেকে কী বোঝা যায়? মাচায় উঠে কাছ থেকে দেখো!',
    exitLine: coworkerExit,
    right: ['না, চালু DTR-এ উঠব না, নিচ থেকে দেখব', 'না, লাইন চালু — দূর থেকেই চেকআপ করব', 'না, শাটডাউন ছাড়া মাচায় ওঠা চলবে না'],
    wrong: [
      'ঠিক, একবার উঠে কাছ থেকে দেখে আসি',
      'আচ্ছা, ঝট করে উঠে গেজটা দেখে নামি',
      'হ্যাঁ, বুশিং না ছুঁলে উঠলে ক্ষতি নেই',
      'ঠিক আছে, এক মিনিটেরই তো ব্যাপার',
      'হ্যাঁ, গ্লাভস তো আছে, উঠে পড়ি একবার',
    ],
    asks: ['ও বলছে উঠতে। আপনি কী করবেন?', 'চালু DTR-এর মাচায় উঠবেন?', 'উঠবেন, না নিচ থেকে দেখবেন?'],
  );

  static CoworkerScript coworker(M3DtrCheckupPush p) => p == M3DtrCheckupPush.leak ? coworkerLeak : coworkerClimb;

  /// His new lines (no clip yet: silent, caption held, until recorded).
  static const recordLines = [
    'একটু তেল চুঁইছে, চলবে! খাতায় সব ঠিক লিখে দাও।',
    'নিচ থেকে কী বোঝা যায়? মাচায় উঠে কাছ থেকে দেখো!',
  ];

  static const callHeldLeak = 'ঠিক! সামান্য লিকও রিপোর্ট — চুপ থাকা নয়।';
  static const callHeldClimb = 'ঠিক! চালু DTR-এ কেউ ওঠে না — চেকআপ নিচ থেকে।';
  static const allSet = 'DTR-এর ডাক্তার হয়ে গেছেন — জেল, তেল, লিক, শব্দ, নেমপ্লেট!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — নিচ থেকে পুরো চেকআপ, তারপর রায়।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtFull = 'পুরো চেকআপ নিচ থেকে';
  static const caughtHealthy = 'সুস্থ DTR চিনেছেন';
  static const caughtGel = 'জেলের রং বদল ধরেছেন';
  static const caughtLeak = 'তেল লিক ধরেছেন';
  static const caughtOilLow = 'কম তেল ধরেছেন';
  static const caughtRattle = 'খটখট শব্দে শাটডাউন';
  static const caughtCall = 'চাপে “না” বলেছেন';

  /// Every fixed guide line (for recording).
  static const guideLines = [intro, ask, callHeldLeak, callHeldClimb, allSet, quick, fail];
}

abstract final class M3DtrCheckupMistakes {
  static const _dir = 'assets/game/art/m3_dtr_checkup';

  static const unchecked = DoMistake(
    key: '3.6/m3_dtr_checkup/unchecked',
    textBn: 'পুরো চেকআপ না করেই রায় দিলেন। ব্রিদারের জেল, তেলের গেজ, লিক, শব্দ আর নেমপ্লেট — সব দেখে তবে রায়।',
    art: '$_dir/unchecked.svg',
    lessonPoint: 2,
  );
  static const gelSpent = DoMistake(
    key: '3.6/m3_dtr_checkup/gel-spent',
    textBn: 'জেলের রং বদলে গেছে! ভালো জেল নীল বা কমলা; গোলাপি বা সাদাটে হলে বদলাতে হবে — ডকেট লিখুন।',
    art: '$_dir/gel_spent.svg',
    lessonPoint: 2,
  );
  static const leakIgnored = DoMistake(
    key: '3.6/m3_dtr_checkup/leak-ignored',
    textBn: 'তেল লিক দেখেও সব ঠিক লিখলেন। লিকে তেল কমে, কুলিং আর ইনসুলেশন দুর্বল হয় — সামান্য লিকও রিপোর্ট করুন।',
    art: '$_dir/leak_ignored.svg',
    lessonPoint: 2,
  );
  static const oilLow = DoMistake(
    key: '3.6/m3_dtr_checkup/oil-low',
    textBn: 'গেজে তেলের লেভেল কম ছিল। তেল খুব কমলে ট্রান্সফরমার অতিরিক্ত গরম হয় — রিপোর্ট করুন।',
    art: '$_dir/oil_low.svg',
    lessonPoint: 2,
  );
  static const rattleIgnored = DoMistake(
    key: '3.6/m3_dtr_checkup/rattle-ignored',
    textBn: 'খটখট-গরগর শব্দ ছিল! মৃদু হামিং স্বাভাবিক, কিন্তু এই শব্দ মানে ভেতরে গুরুতর ফল্ট — এখনই রিপোর্ট, শাটডাউন চাই।',
    art: '$_dir/rattle_ignored.svg',
    lessonPoint: 2,
  );
  static const overCall = DoMistake(
    key: '3.6/m3_dtr_checkup/over-call',
    textBn: 'এই DTR সুস্থ ছিল। নীল বা কমলা জেল, MIN-MAX-এর মাঝে তেল, লিক নেই, মৃদু হামিং — সব স্বাভাবিক। লক্ষণ যা বলে, রায় ততটুকুই।',
    art: '$_dir/over_call.svg',
    lessonPoint: 2,
  );
  static const overCallGel = DoMistake(
    key: '3.6/m3_dtr_checkup/over-call-gel',
    textBn: 'শুধু জেলের রং বদলেছিল — জেল বদলানোর মেরামতের ডকেটই যথেষ্ট। জরুরি শাটডাউন খটখট-গরগরের মতো ভেতরের ফল্টের লক্ষণে।',
    art: '$_dir/over_call_gel.svg',
    lessonPoint: 2,
  );
  static const climbLive = DoMistake(
    key: '3.6/m3_dtr_checkup/climb-live',
    textBn: 'চালু DTR-এর মাচায় উঠলেন! এগারো কেভি বুশিং হাতের নাগালে। চেকআপ নিচ থেকে; উঠতে হলে আগে শাটডাউন, PTW, টেস্ট আর আর্থ।',
    art: '$_dir/climb_live.svg',
    deadly: true,
    lessonPoint: 0,
  );

  static List<DoMistake> get all => const [unchecked, gelSpent, leakIgnored, oilLow, rattleIgnored, overCall, overCallGel, climbLive];

  /// The slip for signing off a DTR that has [f].
  static DoMistake forFinding(M3DtrCheckupFinding f) => switch (f) {
        M3DtrCheckupFinding.rattle => rattleIgnored,
        M3DtrCheckupFinding.leak => leakIgnored,
        M3DtrCheckupFinding.oilLow => oilLow,
        M3DtrCheckupFinding.gel => gelSpent,
      };
}

@immutable
class M3DtrCheckupDeal {
  const M3DtrCheckupDeal({required this.cases, required this.callAt, required this.push});
  final List<M3DtrCheckupCase> cases;

  /// The DTR the careless coworker comes at, and what he pushes.
  final int callAt;
  final M3DtrCheckupPush push;
}

/// Three DTRs: one healthy, one for a repair docket, one for an urgent
/// shutdown, in a fresh order; fresh gel colours, leak places, nameplates.
M3DtrCheckupDeal m3DtrCheckupDeal(math.Random rng) {
  T pick<T>(List<T> l) => l[rng.nextInt(l.length)];
  final push = rng.nextBool() ? M3DtrCheckupPush.leak : M3DtrCheckupPush.climb;
  final kinds = [M3DtrCheckupCall.ok, M3DtrCheckupCall.repair, M3DtrCheckupCall.urgent]..shuffle(rng);
  final kvas = [25, 63, 100, 160, 250]..shuffle(rng);
  const f = M3DtrCheckupFinding.values;
  final repairSets = push == M3DtrCheckupPush.leak
      ? const [
          [M3DtrCheckupFinding.leak],
          [M3DtrCheckupFinding.leak, M3DtrCheckupFinding.oilLow],
          [M3DtrCheckupFinding.leak, M3DtrCheckupFinding.gel],
        ]
      : const [
          [M3DtrCheckupFinding.gel],
          [M3DtrCheckupFinding.leak],
          [M3DtrCheckupFinding.oilLow],
          [M3DtrCheckupFinding.leak, M3DtrCheckupFinding.oilLow],
          [M3DtrCheckupFinding.gel, M3DtrCheckupFinding.leak],
        ];
  final cases = <M3DtrCheckupCase>[
    for (var i = 0; i < 3; i++)
      () {
        final fresh = rng.nextBool() ? M3DtrCheckupGel.blue : M3DtrCheckupGel.orange;
        final has = switch (kinds[i]) {
          M3DtrCheckupCall.ok => const <M3DtrCheckupFinding>[],
          M3DtrCheckupCall.repair => pick(repairSets),
          M3DtrCheckupCall.urgent => [f[0], ...pick(const [<M3DtrCheckupFinding>[], [M3DtrCheckupFinding.gel], [M3DtrCheckupFinding.leak]])],
        };
        return M3DtrCheckupCase(
          id: 'd$i',
          look: M3DtrCheckupLook(
            gel: has.contains(M3DtrCheckupFinding.gel) ? (fresh == M3DtrCheckupGel.blue ? M3DtrCheckupGel.pink : M3DtrCheckupGel.white) : fresh,
            oilLow: has.contains(M3DtrCheckupFinding.oilLow),
            leak: has.contains(M3DtrCheckupFinding.leak) ? pick(const [M3DtrCheckupLeak.gasket, M3DtrCheckupLeak.weld, M3DtrCheckupLeak.drain]) : M3DtrCheckupLeak.none,
            rattle: has.contains(M3DtrCheckupFinding.rattle),
            kva: kvas[i],
          ),
        );
      }(),
  ];
  final callAt = push == M3DtrCheckupPush.leak ? kinds.indexOf(M3DtrCheckupCall.repair) : rng.nextInt(3);
  return M3DtrCheckupDeal(cases: cases, callAt: callAt, push: push);
}

/// The play state (pure logic).
class M3DtrCheckupRun {
  M3DtrCheckupRun(this.deal);

  final M3DtrCheckupDeal deal;
  int index = 0;

  /// What was looked at (or listened to) on this DTR.
  final Set<M3DtrCheckupSpot> seen = {};
  M3DtrCheckupCall? called;
  var shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  M3DtrCheckupCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;
  bool get fullCheck => seen.containsAll(M3DtrCheckupSpot.values);

  /// The +5: a DTR with two signs or more, or the urgent one, called right.
  bool get thorough => current.findings.length >= 2 || current.verdict == M3DtrCheckupCall.urgent;

  /// Look at [s] (from the ground). True the first time on this DTR.
  bool look(M3DtrCheckupSpot s) => _open && seen.add(s);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// The call. [pushed]: on the coworker's word (no check-up asked for). An
  /// over-call (more than the signs ask for) is a slip as well.
  DoMistake? decide(M3DtrCheckupCall call, {bool pushed = false}) {
    if (!_open) return null;
    final c = current;
    if (!pushed && !fullCheck) {
      shown = true;
      slips++;
      return M3DtrCheckupMistakes.unchecked;
    }
    if (c.accepts(call)) {
      shown = true;
      called = call;
      _tag(M3DtrCheckupLines.caughtFull);
      if (c.verdict == M3DtrCheckupCall.ok) _tag(M3DtrCheckupLines.caughtHealthy);
      for (final f in c.findings) {
        _tag(switch (f) {
          M3DtrCheckupFinding.rattle => M3DtrCheckupLines.caughtRattle,
          M3DtrCheckupFinding.leak => M3DtrCheckupLines.caughtLeak,
          M3DtrCheckupFinding.oilLow => M3DtrCheckupLines.caughtOilLow,
          M3DtrCheckupFinding.gel => M3DtrCheckupLines.caughtGel,
        });
      }
      return null;
    }
    shown = true;
    slips++;
    if (call.index < c.verdict.index) return M3DtrCheckupMistakes.forFinding(c.findings.first);
    return c.verdict == M3DtrCheckupCall.ok ? M3DtrCheckupMistakes.overCall : M3DtrCheckupMistakes.overCallGel;
  }

  /// Up onto the live DTR's platform (on the coworker's word): deadly.
  DoMistake? climb() {
    if (!_open) return null;
    shown = true;
    return deadly = M3DtrCheckupMistakes.climbLive;
  }

  void next() {
    index++;
    seen.clear();
    called = null;
    shown = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A DTR (ms): five
/// looks × (1500 tap + 1500 read) = 15000; the call 1500; the reason ~8200 ≈
/// 24700 × 3 = 74100; the coworker ~9600: ≈ 83700; 85 % ≈ 71 s.
const kM3DtrCheckupQuickMs = 71000;

@immutable
class M3DtrCheckupPack {
  const M3DtrCheckupPack({required this.id, required this.titleBn, this.quickMs = kM3DtrCheckupQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3DtrCheckupPacks = {
  'do_3_6_a': M3DtrCheckupPack(id: 'do_3_6_a', titleBn: M3DtrCheckupLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3DtrCheckupPage extends StatefulWidget {
  const M3DtrCheckupPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3DtrCheckupPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3DtrCheckupPage> createState() => _M3DtrCheckupPageState();
}

class _M3DtrCheckupPageState extends State<M3DtrCheckupPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DtrRunPage(
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

class _DtrRunPage extends ConsumerStatefulWidget {
  const _DtrRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3DtrCheckupPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DtrRunPage> createState() => _DtrRunPageState();
}

class _DtrRunPageState extends ConsumerState<_DtrRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3DtrCheckupRun _run = M3DtrCheckupRun(m3DtrCheckupDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  /// His timer is set for this play (the level's own once-flag; the kit's
  /// [coworkerDue] says whether he is still to come).
  var _coworkerSet = false;

  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final _listenKey = GlobalKey();
  final _callKeys = {for (final c in M3DtrCheckupCall.values) c: GlobalKey()};
  M3DtrCheckupGeo? _geoNow;

  /// The close-up being looked at, and the order things were seen in.
  M3DtrCheckupSpot? _lens;
  int _lensN = 0;
  final List<M3DtrCheckupSpot> _log = [];
  M3DtrCheckupCall? _stamped;
  var _climbed = false;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

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

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  bool get _canPlay => !_intro && !_busy && !_ended && !_freeze && _card == null && !tableBusy && !coworkerOpen && !_run.shown;

  void _startRound() {
    setState(() {
      _lens = null;
      _log.clear();
      _stamped = null;
      _wake++;
    });
    unawaited(_sayChain([M3DtrCheckupLines.ask]));
  }

  // --- hands on -----------------------------------------------------------------------
  void _tapScene(Offset p, M3DtrCheckupGeo geo) {
    final s = geo.hit(p);
    if (s != null) {
      _look(s);
    } else if (_canPlay) {
      _hints.missTap();
    }
  }

  void _look(M3DtrCheckupSpot s) {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    final first = _run.look(s);
    if (s == M3DtrCheckupSpot.sound) {
      _cue(_run.current.look.rattle ? 'sounds/learn/knock_hollow.ogg' : 'sounds/intro/tick.ogg', volume: _run.current.look.rattle ? 0.9 : 0.4);
    } else {
      _cue('sounds/intro/tick.ogg', volume: 0.5);
    }
    setState(() {
      _lens = s;
      _lensN++;
      if (first) _log.add(s);
      _wake++;
    });
    // His moment: on his DTR — the leak push once the leak was seen, the
    // climb push after a first look.
    if (!_coworkerSet && _run.index == _run.deal.callAt) {
      final leakPush = _run.deal.push == M3DtrCheckupPush.leak;
      if (!leakPush || s == M3DtrCheckupSpot.tank) {
        _coworkerSet = true;
        scheduleCoworker();
      }
    }
  }

  // --- the call ------------------------------------------------------------------------
  Future<void> _decide(M3DtrCheckupCall call, Offset origin) async {
    if (!_canPlay) return;
    // A call on his DTR before any look: the climb push ("নিচ থেকে কী বোঝা
    // যায়?") fits that moment too — set him now so the call can't skip him.
    // (The leak push is set once the leak was seen; every call that is not
    // already the "unchecked" slip has seen it.)
    if (!_coworkerSet && _run.index == _run.deal.callAt && _run.deal.push == M3DtrCheckupPush.climb) {
      _coworkerSet = true;
      scheduleCoworker();
    }
    // A fast call can't skip him: the call waits while he comes in.
    if (holdForCoworker()) return;
    await _commit(call, origin);
  }

  Future<void> _commit(M3DtrCheckupCall call, Offset origin, {bool pushed = false}) async {
    _hush();
    _busy = false;
    final c = _run.current;
    final m = _run.decide(call, pushed: pushed);
    if (m == null && !_run.shown) return;
    HapticFeedback.mediumImpact();
    if (m == null) {
      _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
      _cue('sounds/quiz_right.ogg', volume: 0.6);
      setState(() {
        _stamped = call;
        _lens = null;
        _wake++;
      });
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(M3DtrCheckupLines.whyRight(c, call), M3DtrCheckupLines.whyWrong(call), widget.rng),
        question: M3DtrCheckupLines.why(call),
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    setState(() {});
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M3DtrCheckupLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His pushes fit only while his DTR is still open (before its call).
    if (_ended || _run.index != _run.deal.callAt || _run.shown) return null;
    if (_intro || _busy || _card != null || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      if (_run.deal.push == M3DtrCheckupPush.leak) {
        // Listened to him: the leaking DTR signed off as fine.
        await _commit(M3DtrCheckupCall.ok, origin, pushed: true);
      } else {
        // Listened to him: up onto the live DTR.
        final m = _run.climb();
        if (m != null) await _deadly(m);
      }
      return;
    }
    if (!_run.caught.contains(M3DtrCheckupLines.caughtCall)) _run.caught.add(M3DtrCheckupLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([_run.deal.push == M3DtrCheckupPush.leak ? M3DtrCheckupLines.callHeldLeak : M3DtrCheckupLines.callHeldClimb]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3DtrCheckupLines.tapWhy[_nudgeN++ % M3DtrCheckupLines.tapWhy.length]
            : _nudge.next(M3DtrCheckupLines.ask);
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

  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _lens = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('dtr/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up on the live DTR: the site freezes grey and the flash by the HT
  /// bushing plays in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _climbed = true;
      _lens = null;
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
    final speak = await SpokenOnce.first('dtr/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3DtrCheckupLines.deadlyWord : M3DtrCheckupLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        _next();
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
    await _say(!_run.passed ? M3DtrCheckupLines.fail : (_quickBonus ? M3DtrCheckupLines.quick : M3DtrCheckupLines.allSet),
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
    if (_stamped != null) return LinemanMode.cheer;
    if (_lens != null && _lens != M3DtrCheckupSpot.sound) return LinemanMode.point;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M3DtrCheckupGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final t = geo.tank;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(
                  child: CustomPaint(painter: M3DtrCheckupWorldPainter(geo: geo, look: c.look, lit: _lens)),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: _climbed ? geo.traineeUp : geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _climbed ? LinemanMode.worried : _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (_stamped != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: t.left - 40,
          width: t.width + 80,
          top: t.top + 20,
          child: IgnorePointer(child: _StampPop(text: M3DtrCheckupLines.stamp(_stamped!, c.look.kva), call: _stamped!, quiet: quiet)),
        ),
      // Tap a part of the DTR: the eye goes there (from the ground).
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3DtrCheckupLines.sceneLabel,
          child: GestureDetector(key: _touchKey, behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3DtrCheckupZapPainter(at: geo.zapAt, v: v)),
            ),
          ),
        ),
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  /// The gesture hint (how, never what): one sweep over every part of the
  /// DTR, the listen button and the three calls alike — never one of them.
  HintSpec? _hint() {
    final rects = <Rect>[];
    final box = _touchKey.currentContext?.findRenderObject();
    final geo = _geoNow;
    if (box is RenderBox && box.hasSize && box.attached && geo != null) {
      for (final r in [geo.breatherHit, geo.gaugeHit, geo.nameplateHit, geo.tank]) {
        rects.add(Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight)));
      }
    }
    for (final k in [_listenKey, ..._callKeys.values]) {
      final r = HintSpec.globalRectOf(k);
      if (r != null) rects.add(r);
    }
    return rects.length < 2 ? null : HintSpec.sweep(rects);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null && !tableBusy;
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
              labels: M3DtrCheckupLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && _canPlay && !coworkerOnScreen,
            hintKey: '${_run.index}-$_lensN-$coworkerDone',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && !_run.done && !deckUp && !coworkerOpen && _lens != null)
                Positioned(
                  key: const ValueKey('hud-lens'),
                  left: 10,
                  bottom: pad.bottom + (handsOn ? 136 : 12),
                  child: _LensCard(spot: _lens!, look: _run.current.look, n: _lensN, log: _log, quiet: quiet),
                ),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 10,
                  bottom: pad.bottom + 74,
                  child: _ToolButton(
                      key: _listenKey, icon: Icons.hearing_rounded, label: M3DtrCheckupLines.listen, enabled: _canPlay, onTap: () => _look(M3DtrCheckupSpot.sound)),
                ),
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 10,
                  right: 10,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      for (final (i, call) in M3DtrCheckupCall.values.indexed) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(child: _CallButton(key: _callKeys[call], call: call, onTapUp: (d) => unawaited(_decide(call, d.globalPosition)))),
                      ],
                    ],
                  ),
                ),
              ],
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
                  sound: FailSound.electric,
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
                  line: M3DtrCheckupLines.intro,
                  alarm: 'sounds/learn/heartbeat.ogg',
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

/// The close-up of what he looks at (or hears): the part's name, the drawing,
/// and small chips of what he has seen on this DTR.
class _LensCard extends StatelessWidget {
  const _LensCard({required this.spot, required this.look, required this.n, required this.log, required this.quiet});
  final M3DtrCheckupSpot spot;
  final M3DtrCheckupLook look;
  final int n;
  final List<M3DtrCheckupSpot> log;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final sound = spot == M3DtrCheckupSpot.sound;
    Widget pic = SizedBox(
      width: 180,
      height: 110,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: M3DtrCheckupLensPainter(spot: spot, look: look))),
          if (sound)
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Text(look.rattle ? M3DtrCheckupLines.rattle : M3DtrCheckupLines.hum,
                  key: const ValueKey('lens-sound'),
                  textAlign: TextAlign.center,
                  style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF2B3440))),
            ),
        ],
      ),
    );
    // A rattle shakes the close-up once; everything else pops in.
    pic = TweenAnimationBuilder<double>(
      key: ValueKey('lens-$n'),
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: Duration(milliseconds: sound && look.rattle ? 900 : 260),
      builder: (_, v, child) => sound && look.rattle
          ? Transform.translate(offset: Offset(math.sin(v * 40) * 4 * (1 - v), 0), child: child)
          : Transform.scale(scale: 0.85 + 0.15 * Curves.easeOut.transform(v), child: child),
      child: pic,
    );
    return IgnorePointer(
      child: Container(
        width: 152,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xF20B1324),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.8), width: 1.6),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(sound ? Icons.hearing_rounded : Icons.search_rounded, size: 16, color: SlmColors.gold300),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(M3DtrCheckupLines.spotName(spot),
                      key: const ValueKey('lens-name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Drawn at 180 × 110, shown smaller: the guide's bubble sits right of it.
            SizedBox(height: 82, child: FittedBox(fit: BoxFit.contain, child: pic)),
            if (log.length > 1) ...[
              const SizedBox(height: 5),
              Wrap(
                spacing: 4,
                runSpacing: 3,
                children: [
                  for (final s in log)
                    Container(
                      key: ValueKey('log-${s.name}'),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(5)),
                      child: Text(M3DtrCheckupLines.spotName(s), style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFFFF3C4))),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One of the three calls.
class _CallButton extends StatelessWidget {
  const _CallButton({super.key, required this.call, required this.onTapUp});
  final M3DtrCheckupCall call;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final col = switch (call) {
      M3DtrCheckupCall.ok => const Color(0xFF2E7D4F),
      M3DtrCheckupCall.repair => SlmColors.gold700,
      M3DtrCheckupCall.urgent => const Color(0xFFB0261C),
    };
    return Material(
      color: col,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          height: 54,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(M3DtrCheckupLines.callLabel(call),
              textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, height: 1.15, color: Colors.white)),
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = enabled ? SlmColors.gold300 : const Color(0xFF6B7380);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.call, required this.quiet});
  final String text;
  final M3DtrCheckupCall call;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final col = switch (call) {
      M3DtrCheckupCall.ok => SlmColors.success,
      M3DtrCheckupCall.repair => const Color(0xFFB7791F),
      M3DtrCheckupCall.urgent => const Color(0xFFB0261C),
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.08, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: col)),
      ),
    );
  }
}
