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
import 'm6_ab_gap_log_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_ab_gap_log_world.dart' show M6AbBlade, M6AbBreak, M6AbEarth, M6AbGeo, M6AbPlace, M6EarthView, m6BladeOpen;

// Lesson 6.4 "AB সুইচ ও আইসোলেটর: ট্র্যাফিক কন্ট্রোলার", কাজ 1 "এক টানে তিন
// ফেজ" (pack do_6_4_a, engineType m6_ab_gap_log). Two jobs at two roadside
// 11 kV DP structures with a gang-operated AB switch (horizontal break at one,
// vertical break at the other — dealt order). Per job, in any order the player
// likes:
//
//  Earth look (6.4 point 4 safety tip "অপারেটিং হ্যান্ডেলটি সঠিকভাবে আর্থিং
//    করা আছে"): swipe down the handle's lead to open the close-up; a dealt cut
//    lead (drag the spare lead across it) or loose clamp (hold the spanner on
//    the nut) shows only there.
//  Off-load (point 2 "প্রথমে সার্কিট ব্রেকার খুলে লাইনকে 'অফ-লোড' করুন"):
//    phone the substation; the operator's text gives only the breaker status —
//    at once, or (one job a play) "এক মিনিট — ব্রেকার খুলছি।" and later "ব্রেকার
//    OFF হয়েছে।". The careless coworker comes in that wait with the lesson's
//    myth word for word; the OFF reply and the handle wait for him.
//  Stroke (point 4 "দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত … মাঝপথে থামবেন
//    না"): hold the handle, then drag it along its arc to the OFF stop in one
//    motion.
//  Sight (pro tip 4 "তিনটি ফেজই সম্পূর্ণভাবে খুলেছে … একটি ফেজ আটকে যেতে
//    পারে"; point 1 "খালি চোখে দেখতে পান"): swipe up to tilt the view up to the
//    switch, swipe sideways to pan R → Y → B; in ~40 % of jobs one phase is
//    stuck in its jaw or only just clear of it.
//  Log: tick each phase seen open on the docket, or phone in the stuck phase
//    (its key, then ✓ on the preview). Then ◆ on the table → "কেন …?" → এগিয়ে
//    যান → the next job.
//
// Deadly (module 6 table R4/X3, R39/X2 B1): the handle stroke begun before the
// breaker OFF is confirmed (an isolator opened on load); listening to "সামান্য
// লোড …" in the wait. Slips (R35, M6-1, M6-3, R32): the handle grabbed before
// the earth lead was looked at, or with it cut or loose (the handle then stays
// locked until it is put right); a stalled stroke (speed is never scored);
// ticking a stuck or part-open phase as open; ticking or reporting a phase
// never seen; reporting a clear phase as stuck. Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the full
// scene (m6_ab_gap_log_world.dart), corner guide, the coworker's two beats,
// ReasonTable's success beat, gesture hands (how, never what), mistake cards,
// the deadly freeze, the 3-slip strike-out, idle = zero frames.

// ============================================================================
// Content
// ============================================================================

/// What a job's reason asks about. Dealt up front, then checked against
/// what the player actually did in that job (see [M6AbRun.validWhys]).
enum M6AbWhy { wait, earth, seen, stuck, stroke }

abstract final class M6AbGapLogLines {
  // DRAFT wording — owner (M6-12): every new line in this class.
  static const title = 'এক টানে তিন ফেজ';
  static const intro = 'ফিডারে কাজ হবে — AB সুইচ খুলে লাইন আলাদা করুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askJob = 'এই AB সুইচটা খুলে ডকেটে তিন ফেজের গ্যাপ লিখুন।';
  static const askLog = 'তিন ফেজের গ্যাপ দেখে ডকেটে লিখুন।';
  static const tasks = [askJob, askLog];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  /// After an earth slip the handle stays locked until the lead is put right.
  static const locked = 'আগে হ্যান্ডেলের আর্থের তার দেখে ঠিক করুন।';

  // On screen (a worker's own words).
  static const sceneLabel = 'AB সুইচের স্ট্রাকচার';
  static const handleLabel = 'অপারেটিং হ্যান্ডেল';
  static const docket = 'ডকেট';
  static const gapRow = 'গ্যাপ দেখা';
  static const phone = 'ফোন';
  static const substation = 'সাবস্টেশন';
  static const viewClose = 'ফিরুন';
  static const gapView = 'গ্যাপ দেখার ভিউ';
  static const earthView = 'আর্থের তার';
  static const spareLead = 'বাড়তি তার';
  static const clampNut = 'ক্ল্যাম্পের নাট';
  static const stuckKeys = 'আটকে থাকা ফেজ';
  static const phases = ['R', 'Y', 'B'];
  static String job(int i) => 'কাজ ${i + 1}';
  static String box(int p) => '$gapRow ${phases[p]}';
  static String key(int p) => '$stuckKeys ${phases[p]}';

  // The phone thread (text only; the operator gives only the breaker status).
  static const myCall = 'ফিডার ব্রেকার OFF করে জানান।';
  static const replyNow = ['ফিডার ব্রেকার OFF করা হয়েছে।', 'ফিডারের ব্রেকার এখন OFF।'];
  static const replyWait = 'এক মিনিট — ব্রেকার খুলছি।';
  static const replyOff = 'ব্রেকার OFF হয়েছে।';
  static String reportCard(int p) => '${phases[p]} ফেজ পুরো খোলেনি — জানাই';
  static String reportSent(int p) => '${phases[p]} ফেজ পুরো খোলেনি।';

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses. 42–51 letters.
  static const whyQ = <M6AbWhy, String>{
    M6AbWhy.wait: 'কেন ব্রেকারের খবর আসা পর্যন্ত থামলেন?',
    M6AbWhy.earth: 'কেন হ্যান্ডেলে হাত দেওয়ার আগে আর্থের তার দেখলেন?',
    M6AbWhy.seen: 'কেন তিন ফেজই নিজের চোখে দেখলেন?',
    M6AbWhy.stuck: 'কেন আটকে থাকা ফেজটা খোলা লিখলেন না?',
    M6AbWhy.stroke: 'কেন হ্যান্ডেল এক টানে পুরো ঘোরালেন?',
  };
  static const whyRight = <M6AbWhy, List<String>>{
    M6AbWhy.wait: ['আইসোলেটর OFF-লোড যন্ত্র — লোডে খুললে প্রচণ্ড আর্ক', 'আগে ব্রেকার OFF, তারপর আইসোলেটর — এটাই ঠিক ক্রম'],
    M6AbWhy.earth: ['হ্যান্ডেলের আর্থিং ঠিক থাকলে তবেই অপারেটর নিরাপদ', 'আর্থের তার কাটা বা ঢিলা হলে হ্যান্ডেল নিরাপদ নয়'],
    M6AbWhy.seen: ['একটা ফেজ আটকে যেতে পারে — চোখে দেখাই প্রমাণ', 'গ্যাং সুইচেও কোনো একটা ফেজ আটকে থাকতে পারে'],
    M6AbWhy.stuck: ['আটকে থাকা ফেজে লাইন এখনও বিচ্ছিন্ন হয়নি, গ্যাপ নেই', 'পুরো না খুললে গ্যাপ নেই — খোলা লেখা মানে ভুল খবর'],
    M6AbWhy.stroke: ['এক টানে শেষ পর্যন্ত, মাঝপথে থামা নয় — এটাই নিয়ম', 'হ্যান্ডেল দ্রুত আর দৃঢ়ভাবে, শেষ পর্যন্ত ঘোরানো উচিত'],
  };
  static const myths = [
    'সামান্য লোড থাকলে আইসোলেটর খুললে কিছু হয় না',
    'আইসোলেটর আর সার্কিট ব্রেকার তো একই জিনিস, ভয় নেই',
    'হ্যান্ডেল OFF-এ গেলে তিন ফেজ দেখার দরকার নেই',
    'হ্যান্ডেলে আর্থ না থাকলেও গ্লাভস থাকলেই হয়',
    'আস্তে আস্তে ঘোরালে সুইচ অনেক বেশি নিরাপদ থাকে',
    'ডকেট ভরাতে চোখে দেখা লাগে না, আন্দাজই যথেষ্ট',
    'সুপারভাইজার পরে দেখবে, আমার দেখার দরকার নেই',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (once a play, in the breaker wait). His line is
  // the lesson's myth 1 word for word (not new text, but it needs his clip).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'সামান্য লোড থাকলে আইসোলেটর খোলা যায়, কিছু হয় না।',
    exitLine: coworkerExit,
    right: [
      'না — ব্রেকার OFF-এর খবর না এলে হ্যান্ডেলে হাত নয়',
      'না — সামান্য লোডেও আর্ক হয়, খবর আসা পর্যন্ত থামি',
      'না, আইসোলেটর শুধু OFF-লোডে খোলা যায়, থামছি',
    ],
    wrong: [
      'ঠিক, সামান্য লোডে কিছু হবে না, এখনই খুলে দিই',
      'আচ্ছা, এক মিনিট কে বসে থাকে, হ্যান্ডেল টেনে দিই',
      'হ্যাঁ, লোড তো একেবারে সামান্যই, হ্যান্ডেল টানি',
      'ঠিক আছে, ব্রেকার তো খুলছেই, আগেভাগে খুলে দিই',
      'হ্যাঁ, তাড়াতাড়ি খুলে দিয়ে কাজটা শুরু করে দিই',
    ],
    asks: ['কী করবেন?', 'ও বলছে সামান্য লোডে খোলা যায়। কী করবেন?', 'ওর কথায় কী বলবেন?'],
  );
  static const callHeld = 'ঠিক! লোডে আইসোলেটর নয় — আগে ব্রেকার OFF-এর খবর।';

  static const allSet = 'দুটো সুইচই নিরাপদে খোলা — তিন ফেজ নিজের চোখে দেখা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে ব্রেকার, তারপর এক টানে হ্যান্ডেল, তারপর তিন ফেজ দেখা।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtWait = 'ব্রেকারের খবর আসা পর্যন্ত থেমেছেন';
  static const caughtEarth = 'হ্যান্ডেলের আর্থের তার ঠিক করেছেন';
  static const caughtStuck = 'আটকে থাকা ফেজ ধরে জানিয়েছেন';
  static const caughtSeen = 'তিন ফেজই নিজের চোখে দেখেছেন';
  static const caughtStroke = 'এক টানে পুরো স্ট্রোক';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// New spoken lines for the director (owner wording, then clips).
  static const newRivalLines = ['সামান্য লোড থাকলে আইসোলেটর খোলা যায়, কিছু হয় না।'];
  static const newGuideLines = [intro, askJob, askLog, locked, callHeld, allSet, fail];
}

abstract final class M6AbGapLogMistakes {
  static const _dir = 'assets/game/art/m6_ab_gap_log';

  // Module 6 table R4 (X3): an isolator opened on load.
  static const onLoad = DoMistake(
    key: '6.4/m6_ab_gap_log/on-load',
    textBn: 'ব্রেকার OFF নিশ্চিত করার আগে AB খোলা মানে লোডে খোলা — প্রচণ্ড ও দীর্ঘস্থায়ী আর্ক! আগে ব্রেকার OFF, তারপর আইসোলেটর।',
    art: '$_dir/on_load.svg',
    deadly: true,
    lessonPoint: 1,
  );
  // R39 (X2 B1): listening to "সামান্য লোড" = opening on load in the wait.
  static const pushLoad = DoMistake(
    key: '6.4/m6_ab_gap_log/push-load',
    textBn: 'সামান্য লোড কারেন্টও বিপজ্জনক আর্ক তৈরির জন্য যথেষ্ট। ব্রেকার OFF-এর খবর না পেলে হ্যান্ডেলে হাত নয়।',
    art: '$_dir/on_load.svg',
    deadly: true,
    lessonPoint: 1,
  );
  // R35 / M6-1: the handle's earth.
  static const earthUnchecked = DoMistake(
    key: '6.4/m6_ab_gap_log/earth-unchecked',
    textBn: 'হ্যান্ডেল ধরার আগে দেখুন অপারেটিং হ্যান্ডেলটি ঠিকমতো আর্থিং করা আছে — আর্থের তার মাটি পর্যন্ত দেখে নিন।',
    art: '$_dir/earth_lead.svg',
    lessonPoint: 3,
  );
  static const earthBroken = DoMistake(
    key: '6.4/m6_ab_gap_log/earth-broken',
    textBn: 'আর্থের তার কাটা বা ক্ল্যাম্প ঢিলা থাকলে হ্যান্ডেলে হাত নয়। আগে তার জুড়ে বা ক্ল্যাম্প টাইট করে নিন।',
    art: '$_dir/earth_lead.svg',
    lessonPoint: 3,
  );
  // R35 / M6-3: only a stalled stroke is scored.
  static const stall = DoMistake(
    key: '6.4/m6_ab_gap_log/stall',
    textBn: 'হ্যান্ডেল দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত ঘোরান — মাঝপথে থামবেন না।',
    art: '$_dir/stall.svg',
    lessonPoint: 3,
  );
  static const tickStuck = DoMistake(
    key: '6.4/m6_ab_gap_log/tick-stuck',
    textBn: 'এই ফেজ পুরো খোলেনি! তিনটি ফেজই সম্পূর্ণভাবে খুলেছে কি না দেখুন — আটকে থাকা ফেজ খোলা লিখবেন না, ফোনে জানান।',
    art: '$_dir/stuck_phase.svg',
    lessonPoint: 0,
  );
  static const unseen = DoMistake(
    key: '6.4/m6_ab_gap_log/unseen',
    textBn: 'যে ফেজ নিজের চোখে দেখেননি, তার ঘরে টিক বা খবর নয়। আগে চোখ তুলে গ্যাপটা দেখুন।',
    art: '$_dir/unseen.svg',
    lessonPoint: 0,
  );
  // R32: a needless stuck report.
  static const needless = DoMistake(
    key: '6.4/m6_ab_gap_log/needless',
    textBn: 'এই ফেজের গ্যাপ পরিষ্কার খোলা — মিছিমিছি আটকে থাকার খবর নয়। যা দেখেছেন, তা-ই লিখুন।',
    art: '$_dir/needless.svg',
    lessonPoint: 0,
  );

  static const List<DoMistake> all = [onLoad, pushLoad, earthUnchecked, earthBroken, stall, tickStuck, unseen, needless];
}

/// One job at one AB switch.
@immutable
class M6AbJob {
  const M6AbJob({
    required this.kind,
    required this.place,
    this.earth = M6AbEarth.ok,
    this.stuck = -1,
    this.part = false,
    this.wait = false,
    this.reply = 0,
  });

  final M6AbBreak kind;
  final M6AbPlace place;
  final M6AbEarth earth;

  /// The phase that does not open fully (-1: all three open); [part]: only
  /// just clear of its jaw (else still in it).
  final int stuck;
  final bool part;

  /// The breaker wait ("এক মিনিট") — the coworker's job; [reply]: which
  /// wording the instant OFF reply uses.
  final bool wait;
  final int reply;

  M6AbBlade blade(int p) => p != stuck ? M6AbBlade.open : (part ? M6AbBlade.part : M6AbBlade.stuck);
  List<double> get caps => [for (var p = 0; p < 3; p++) m6BladeOpen(blade(p))];
}

@immutable
class M6AbDeal {
  const M6AbDeal({required this.jobs, required this.waitJob, required this.why});
  final List<M6AbJob> jobs;

  /// The job with the breaker wait (the coworker comes in it).
  final int waitJob;

  /// What each job's reason would ask about with no slips in it (the run
  /// swaps it if a slip made it untrue: [M6AbRun.finishJob]).
  final List<M6AbWhy> why;
}

/// The reasons that fit a job (the wait and the stuck phase only where they
/// happened; those weigh double).
List<M6AbWhy> m6AbWhysFor(M6AbJob j) => [
      M6AbWhy.earth,
      M6AbWhy.seen,
      M6AbWhy.stroke,
      if (j.wait) ...[M6AbWhy.wait, M6AbWhy.wait],
      if (j.stuck >= 0) ...[M6AbWhy.stuck, M6AbWhy.stuck],
    ];

M6AbDeal m6AbDeal(math.Random rng) {
  final kinds = [...M6AbBreak.values]..shuffle(rng);
  final places = [...M6AbPlace.values]..shuffle(rng);
  final waitJob = rng.nextInt(2);
  final jobs = <M6AbJob>[
    for (var i = 0; i < 2; i++)
      M6AbJob(
        kind: kinds[i],
        place: places[i],
        earth: rng.nextDouble() < 0.5 ? M6AbEarth.ok : (rng.nextBool() ? M6AbEarth.cut : M6AbEarth.loose),
        stuck: rng.nextDouble() < 0.4 ? rng.nextInt(3) : -1,
        part: rng.nextBool(),
        wait: i == waitJob,
        reply: rng.nextInt(M6AbGapLogLines.replyNow.length),
      ),
  ];
  final first = m6AbWhysFor(jobs[0]);
  final w0 = first[rng.nextInt(first.length)];
  final second = m6AbWhysFor(jobs[1]).where((w) => w != w0).toList();
  final w1 = second[rng.nextInt(second.length)];
  return M6AbDeal(jobs: jobs, waitJob: waitJob, why: [w0, w1]);
}

/// The coworker comes in the wait job's breaker wait ("এক মিনিট" is in and the
/// OFF has not come yet).
bool m6AbPushGate(M6AbRun r) => r.index == r.deal.waitJob && r.waiting && !r.offConfirmed;

/// The play state (pure logic).
class M6AbRun {
  M6AbRun(this.deal);
  final M6AbDeal deal;

  int index = 0;
  int slips = 0;
  int jobSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];
  var _anyStall = false;
  var _sightSlip = false;

  /// The reason each finished job asked about (fits what was done).
  final List<M6AbWhy> asked = [];

  /// The slips made in this job (they rule out reasons that would be untrue).
  final Set<DoMistake> jobSlipped = {};

  /// The job's log is in (its reason comes next).
  var roundDone = false;

  // The job's state.
  var earthLooked = false;
  var earthFixed = false;
  var _locked = false;
  var called = false;
  var waiting = false;
  var offConfirmed = false;
  var stroked = false;
  final Set<int> viewed = {};
  final Set<int> ticked = {};
  int reported = -1;

  M6AbJob get job => deal.jobs[index.clamp(0, 1)];
  bool get done => index >= 2;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => jobSlips == 0;
  bool get _open => !ended && !roundDone;

  /// The handle's earth is whole (as dealt, or put right).
  bool get earthSafe => job.earth == M6AbEarth.ok || earthFixed;

  /// After an earth slip the handle stays locked until the lead has been
  /// looked at and is whole (M6-1).
  bool get handleLocked => _locked && !(earthLooked && earthSafe);

  /// Every phase on the docket: ticked open, or the stuck one phoned in.
  bool get logged => ticked.length + (reported >= 0 ? 1 : 0) == 3;

  DoMistake _slip(DoMistake m) {
    slips++;
    jobSlips++;
    jobSlipped.add(m);
    return m;
  }

  /// The reasons still true for this job: an earth slip rules out the earth
  /// question, a stall the stroke one, an unseen tick or report the seen and
  /// stuck ones, a stuck phase ticked the stuck and seen ones, a needless
  /// report the stuck one.
  List<M6AbWhy> validWhys() {
    bool any(List<DoMistake> ms) => ms.any(jobSlipped.contains);
    return [
      for (final w in m6AbWhysFor(job))
        if (switch (w) {
          M6AbWhy.earth => !any(const [M6AbGapLogMistakes.earthUnchecked, M6AbGapLogMistakes.earthBroken]),
          M6AbWhy.stroke => !any(const [M6AbGapLogMistakes.stall]),
          M6AbWhy.seen => !any(const [M6AbGapLogMistakes.unseen, M6AbGapLogMistakes.tickStuck]),
          M6AbWhy.stuck => !any(const [M6AbGapLogMistakes.unseen, M6AbGapLogMistakes.tickStuck, M6AbGapLogMistakes.needless]),
          M6AbWhy.wait => true,
        })
          w,
    ];
  }

  /// This job's reason: the dealt one if it is still true and not the one
  /// job 1 already asked, else another true one ([rng] picks), else job 1's
  /// again (true beats new), else the seen question (only after an earth
  /// slip, a stall and a sight slip in one job: every phase was seen by the
  /// time the docket is full).
  M6AbWhy _pickWhy(math.Random? rng) {
    final before = asked.isEmpty ? null : asked.first;
    final dealt = deal.why[index];
    final valid = validWhys();
    if (dealt != before && valid.contains(dealt)) return dealt;
    final rest = valid.where((w) => w != before).toList();
    if (rest.isNotEmpty) return rest[rng?.nextInt(rest.length) ?? 0];
    if (valid.isNotEmpty) return valid.first;
    return M6AbWhy.seen;
  }

  /// The reason for the job just finished (null before its docket is full).
  M6AbWhy? get why => roundDone && index < asked.length ? asked[index] : null;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  // --- the earth lead ------------------------------------------------------
  void lookEarth() {
    if (_open) earthLooked = true;
  }

  /// The fault put right by hand ([how]: the spare lead on a cut, the
  /// spanner on a loose clamp). True if it fixed something.
  bool fixEarth(M6AbEarth how) {
    if (!_open || !earthLooked || earthFixed || how == M6AbEarth.ok || job.earth != how) return false;
    earthFixed = true;
    return true;
  }

  // --- the breaker -----------------------------------------------------------
  void call() {
    if (_open) called = true;
  }

  /// The operator's "এক মিনিট" (the wait job).
  void replyWait() {
    if (_open && called && job.wait && !offConfirmed) waiting = true;
  }

  /// The operator's "ব্রেকার OFF".
  void confirmOff() {
    if (!_open || !called) return;
    offConfirmed = true;
    waiting = false;
  }

  // --- the handle --------------------------------------------------------------
  /// The handle held: before the earth look, or with the lead cut or loose,
  /// a slip (and the handle stays locked until it is put right).
  DoMistake? grab() {
    if (!_open || stroked || handleLocked) return null;
    if (!earthLooked) {
      _locked = true;
      return _slip(M6AbGapLogMistakes.earthUnchecked);
    }
    if (!earthSafe) {
      _locked = true;
      return _slip(M6AbGapLogMistakes.earthBroken);
    }
    return null;
  }

  /// The blades start to part: deadly before the breaker OFF is confirmed.
  DoMistake? beginStroke() {
    if (!_open || stroked) return null;
    if (!offConfirmed) return deadly = M6AbGapLogMistakes.onLoad;
    return null;
  }

  /// The stroke stopped short of the OFF stop (the handle falls back).
  DoMistake? stall() {
    if (!_open || stroked) return null;
    _anyStall = true;
    return _slip(M6AbGapLogMistakes.stall);
  }

  /// The handle reached its OFF stop in one motion.
  void strokeDone() {
    if (_open && offConfirmed) stroked = true;
  }

  // --- sight and log -----------------------------------------------------------
  /// The gap view shows phase [p] (it counts once the switch is opened).
  void view(int p) {
    if (_open && stroked) viewed.add(p);
  }

  /// A tick in phase [p]'s box: right only for a phase seen fully open.
  DoMistake? tick(int p) {
    if (!_open || ticked.contains(p) || reported == p) return null;
    if (!viewed.contains(p)) {
      _sightSlip = true;
      return _slip(M6AbGapLogMistakes.unseen);
    }
    if (job.blade(p) != M6AbBlade.open) {
      _sightSlip = true;
      return _slip(M6AbGapLogMistakes.tickStuck);
    }
    ticked.add(p);
    return null;
  }

  /// Phase [p] phoned in as stuck: right only for the phase seen not fully
  /// open.
  DoMistake? report(int p) {
    if (!_open || !stroked || ticked.contains(p) || reported >= 0) return null;
    if (!viewed.contains(p)) {
      _sightSlip = true;
      return _slip(M6AbGapLogMistakes.unseen);
    }
    if (job.blade(p) == M6AbBlade.open) return _slip(M6AbGapLogMistakes.needless);
    reported = p;
    return null;
  }

  /// The log complete: the job is done (its reason, [why], comes next).
  bool finishJob([math.Random? rng]) {
    if (!_open || !logged) return false;
    roundDone = true;
    asked.add(_pickWhy(rng));
    final j = job;
    if (j.wait) _tag(M6AbGapLogLines.caughtWait);
    if (j.earth != M6AbEarth.ok) _tag(M6AbGapLogLines.caughtEarth);
    if (j.stuck >= 0) _tag(M6AbGapLogLines.caughtStuck);
    if (index == 1) {
      if (!_sightSlip) _tag(M6AbGapLogLines.caughtSeen);
      if (!_anyStall) _tag(M6AbGapLogLines.caughtStroke);
    }
    return true;
  }

  /// Fails the play (listening to the push in the wait).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    jobSlips = 0;
    jobSlipped.clear();
    roundDone = false;
    earthLooked = false;
    earthFixed = false;
    _locked = false;
    called = false;
    waiting = false;
    offConfirmed = false;
    stroked = false;
    viewed.clear();
    ticked.clear();
    reported = -1;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a job: swipe down + look 2500, (a fix 2500), phone + reply 3000, hold
///     and stroke 2500, swipe up 1500, two pans 3000, three log moves 5000
///     (+ a key and ✓ for a stuck phase) ≈ 20000 + reason ~8200
///   two jobs ≈ 56400; the wait job's coworker ≈ 9600 + the OFF 1600
///                                                               ≈ 67600
/// 85 % ≈ 57500 → 60 s.
const m6AbGapLogQuickMs = 60000;

@immutable
class M6AbGapLogPack {
  const M6AbGapLogPack({required this.id, required this.titleBn, this.quickMs = m6AbGapLogQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6AbGapLogPack> m6AbGapLogPacks = {
  'do_6_4_a': M6AbGapLogPack(id: 'do_6_4_a', titleBn: M6AbGapLogLines.title),
};

/// The page's timings (ms).
abstract final class M6AbTiming {
  /// The operator's text comes this long after the call.
  static const reply = 1400;

  /// The wait job's OFF comes no sooner than this after "এক মিনিট" …
  static const wait = 4000;

  /// … and this long after the coworker's deck has closed.
  static const afterHim = 1600;

  /// A stroke that makes no progress this long has stalled.
  static const stall = 700;
}

enum _View { none, gap, earth }

// ============================================================================
// Page
// ============================================================================

class M6AbGapLogPage extends StatefulWidget {
  const M6AbGapLogPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6AbGapLogPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6AbGapLogPage> createState() => _M6AbGapLogPageState();
}

class _M6AbGapLogPageState extends State<M6AbGapLogPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GapLogRunPage(
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

class _GapLogRunPage extends ConsumerStatefulWidget {
  const _GapLogRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6AbGapLogPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_GapLogRunPage> createState() => _GapLogRunPageState();
}

class _GapLogRunPageState extends ConsumerState<_GapLogRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6AbRun _run = M6AbRun(m6AbDeal(widget.rng));
  late final int _seed = _run.deal.waitJob * 5 + _run.deal.jobs[0].kind.index;
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

  /// The handle on its arc (0 ON … 1 OFF): repaints the lever and blades only.
  final _handle = ValueNotifier<double>(0);
  var _grabbing = false;
  var _strokeOn = false;
  double _strokeBest = 0;
  Timer? _stallTimer;

  /// The close-up view, and the phase the gap view shows.
  _View _view = _View.none;
  int _lensPhase = 0;

  /// The phone: the thread of this job, the operator typing, the stuck keys.
  final List<({String text, bool mine})> _thread = [];
  var _calling = false;
  var _keysOpen = false;
  int? _preview;
  final Set<int> _asideKeys = {};
  Timer? _replyTimer;
  Timer? _offTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _phoneKey = GlobalKey();
  final _docketKey = GlobalKey();
  final _handleKey = GlobalKey();
  final List<GlobalKey> _boxKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final List<GlobalKey> _keyKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  int _hintN = 0;
  int _steps = 0;
  M6AbGeo? _geoNow;

  // A vertical swipe on the scene (tilt up / follow the lead down).
  Offset? _dragFrom;
  Offset _dragNow = Offset.zero;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _stallTimer?.cancel();
    _replyTimer?.cancel();
    _offTimer?.cancel();
    _handle.dispose();
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

  M6AbJob get _job => _run.job;

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && _preview == null;

  String get _task => _run.stroked ? M6AbGapLogLines.askLog : M6AbGapLogLines.askJob;

  Future<void> _start() async {
    _clock.start();
    _startJob();
  }

  void _startJob() {
    _stallTimer?.cancel();
    _replyTimer?.cancel();
    _offTimer?.cancel();
    _handle.value = 0;
    setState(() {
      _wake++;
      _view = _View.none;
      _lensPhase = 0;
      _thread.clear();
      _calling = false;
      _keysOpen = false;
      _preview = null;
      _asideKeys.clear();
      _grabbing = false;
      _strokeOn = false;
    });
    unawaited(_sayChain([_task]));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- the views ----------------------------------------------------------------
  void _openGap() {
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _view = _View.gap;
      _lensPhase = 0;
      _keysOpen = false;
    });
    _run.view(0);
    _stepDone();
  }

  void _pan(int dir) {
    if (!_canPlay || _view != _View.gap) return;
    final p = (_lensPhase + dir).clamp(0, 2);
    if (p == _lensPhase) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/tick.ogg', 0.4);
    setState(() => _lensPhase = p);
    _run.view(p);
    _stepDone();
  }

  void _openEarth() {
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _view = _View.earth;
      _keysOpen = false;
    });
    _run.lookEarth();
    _stepDone();
  }

  void _closeView() {
    if (_view == _View.none || _freeze) return;
    _tick('sounds/intro/tick.ogg', 0.4);
    setState(() => _view = _View.none);
    _stepDone();
  }

  void _spareDrop(bool onCut, Offset global) {
    if (!_canPlay) return;
    if (onCut && _run.fixEarth(M6AbEarth.cut)) {
      _tick('sounds/intro/impact_metal.ogg', 0.55);
      unawaited(_levelDelta(5, global, mood: GuideMood.glad));
      _stepDone();
      return;
    }
    _hints.missTap();
  }

  void _nutHold(Offset global) {
    if (!_canPlay) return;
    _tick('sounds/learn/ring_steel.ogg', 0.55);
    if (_run.fixEarth(M6AbEarth.loose)) {
      unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    }
    _stepDone();
  }

  // --- the scene's touches ------------------------------------------------------
  void _tapScene() {
    if (!_canPlay) return;
    _hints.missTap();
  }

  void _dragStart(Offset p) {
    if (!_canPlay) return;
    _dragFrom = p;
    _dragNow = p;
  }

  void _dragUpdate(Offset p) => _dragNow = p;

  void _dragEnd(M6AbGeo geo) {
    final from = _dragFrom;
    _dragFrom = null;
    if (from == null || !_canPlay) return;
    final dy = _dragNow.dy - from.dy;
    if (dy < -50 && geo.structureZone.contains(from)) {
      _openGap();
      return;
    }
    if (dy > 40 && geo.earthZone.contains(from)) {
      _openEarth();
      return;
    }
    _hints.missTap();
  }

  // --- the phone ------------------------------------------------------------------
  void _tapPhone(Offset global) {
    if (!_canPlay) return;
    if (!_run.called) {
      _tick('sounds/intro/click.ogg', 0.55);
      _run.call();
      setState(() {
        _thread.add((text: M6AbGapLogLines.myCall, mine: true));
        _calling = true;
        _view = _View.none;
      });
      _replyTimer = Timer(const Duration(milliseconds: M6AbTiming.reply), _reply);
      _stepDone();
      return;
    }
    if (_run.stroked) {
      _tick('sounds/intro/click.ogg', 0.5);
      setState(() => _keysOpen = !_keysOpen);
      _stepDone();
      return;
    }
    _hints.missTap();
  }

  void _reply() {
    if (!mounted || _ended || _run.roundDone) return;
    _cue('sounds/intro/tick.ogg', volume: 0.55);
    if (_job.wait) {
      _run.replyWait();
      setState(() {
        _calling = false;
        _thread.add((text: M6AbGapLogLines.replyWait, mine: false));
      });
      // The coworker comes in this wait; the OFF waits for him.
      if (m6AbPushGate(_run)) scheduleCoworker();
      _offTimer = Timer(const Duration(milliseconds: M6AbTiming.wait), _offMaybe);
    } else {
      _run.confirmOff();
      setState(() {
        _calling = false;
        _thread.add((text: M6AbGapLogLines.replyNow[_job.reply], mine: false));
      });
    }
    _stepDone();
  }

  /// The wait job's OFF: only once the coworker has been and gone.
  void _offMaybe() {
    if (!mounted || _ended || _run.roundDone || _run.offConfirmed) return;
    if (!coworkerDone) {
      _offTimer = Timer(const Duration(milliseconds: 600), _offMaybe);
      return;
    }
    _cue('sounds/intro/tick.ogg', volume: 0.55);
    _run.confirmOff();
    setState(() => _thread.add((text: M6AbGapLogLines.replyOff, mine: false)));
    _stepDone();
  }

  void _tapKey(int p) {
    if (!_canPlay || !_keysOpen) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _preview = p);
  }

  void _confirmKey(Offset global) {
    final p = _preview;
    if (p == null) return;
    setState(() {
      _preview = null;
      _asideKeys.clear();
      _keysOpen = false;
    });
    final m = _run.report(p);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.reported != p) return;
    _cue('sounds/learn/tag_slap.ogg', volume: 0.55);
    setState(() => _thread.add((text: M6AbGapLogLines.reportSent(p), mine: true)));
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    _stepDone();
    _maybeJobDone();
  }

  void _rejectKey() {
    final p = _preview;
    if (p == null) return;
    setState(() {
      _asideKeys.add(p);
      _preview = null;
    });
  }

  // --- the handle -------------------------------------------------------------------
  void _grabAt(Offset p, M6AbGeo geo, Offset global) {
    if (!_canPlay) return;
    if (!geo.handleHit.contains(p) || _run.stroked) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    if (_run.handleLocked) {
      _tick();
      unawaited(_sayChain([M6AbGapLogLines.locked]));
      return;
    }
    final m = _run.grab();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.55);
    setState(() {
      _grabbing = true;
      _strokeOn = false;
      _strokeBest = 0;
      _view = _View.none;
      _keysOpen = false;
      _wake++;
    });
  }

  void _strokeMove(Offset p, M6AbGeo geo, Offset global) {
    if (!_grabbing || _ended) return;
    final t = geo.progressAt(p);
    if (t == null) return;
    _handle.value = t;
    if (!_strokeOn && t > 0.1) {
      _strokeOn = true;
      final m = _run.beginStroke();
      if (m != null) {
        _grabbing = false;
        _flashAt = geo.abCentre;
        unawaited(_mistake(m, global));
        return;
      }
      _cue('sounds/intro/impact_metal.ogg', volume: 0.45);
    }
    if (t >= 0.97) {
      _strokeDone(global);
      return;
    }
    if (_strokeOn && t > _strokeBest + 0.01) {
      _strokeBest = t;
      _stallTimer?.cancel();
      _stallTimer = Timer(const Duration(milliseconds: M6AbTiming.stall), () => _stall(global));
    }
  }

  void _strokeEnd(Offset global) {
    if (!_grabbing) return;
    if (_strokeOn) {
      _stall(global);
      return;
    }
    // Let go before it moved: nothing happened.
    _grabbing = false;
    _handle.value = 0;
    setState(() => _wake++);
  }

  void _stall(Offset global) {
    _stallTimer?.cancel();
    if (!_grabbing || _ended) return;
    _grabbing = false;
    _strokeOn = false;
    _handle.value = 0;
    final m = _run.stall();
    setState(() => _wake++);
    if (m != null) unawaited(_mistake(m, global));
  }

  void _strokeDone(Offset global) {
    _stallTimer?.cancel();
    _grabbing = false;
    _strokeOn = false;
    _handle.value = 1;
    _run.strokeDone();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.75);
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    _stepDone();
    unawaited(_sayChain([M6AbGapLogLines.askLog]));
  }

  // --- the docket ----------------------------------------------------------------------
  void _tickBox(int p, Offset global) {
    if (!_canPlay) return;
    final m = _run.tick(p);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (!_run.ticked.contains(p)) {
      _hints.missTap();
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    _stepDone();
    _maybeJobDone();
  }

  void _maybeJobDone() {
    if (!_run.finishJob(widget.rng)) return;
    _hush();
    HapticFeedback.mediumImpact();
    setState(() {
      _view = _View.none;
      _keysOpen = false;
      _wake++;
    });
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _run.why!;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M6AbGapLogLines.whyRight[topic]!, M6AbGapLogLines.myths, widget.rng),
      question: M6AbGapLogLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startJob();
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
  CoworkerScript get coworkerScript => M6AbGapLogLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.waitJob || _run.offConfirmed || _run.roundDone) return null;
    if (!_run.waiting) return false;
    if (_intro || _card != null || tableBusy || _freeze || _preview != null || _grabbing) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listening: he opens it in the wait — on load (B1: that deadly).
      const m = M6AbGapLogMistakes.pushLoad;
      final geo = _geoNow;
      if (geo != null) _flashAt = geo.abCentre;
      _handle.value = 0.4;
      _run.failDeadly(m);
      await _deadly(m);
      return;
    }
    _run.caught.add(M6AbGapLogLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    _offTimer?.cancel();
    _offTimer = Timer(const Duration(milliseconds: M6AbTiming.afterHim), _offMaybe);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6AbGapLogLines.callHeld], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6AbGapLogLines.tapWhy[_nudgeN++ % M6AbGapLogLines.tapWhy.length]
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
    _cancelTimers();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  void _cancelTimers() {
    _stallTimer?.cancel();
    _replyTimer?.cancel();
    _offTimer?.cancel();
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
    final speak = await SpokenOnce.first('m6abgap/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The switch opened on load: the scene freezes grey and the arc comes off
  /// it in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _cancelTimers();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _grabbing = false;
      _view = _View.none;
      _keysOpen = false;
      _preview = null;
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
    final speak = await SpokenOnce.first('m6abgap/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6AbGapLogLines.deadlyWord : M6AbGapLogLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same job goes on from where it was.
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
    _cancelTimers();
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
    await _say(!_run.passed ? M6AbGapLogLines.fail : (_quickBonus ? M6AbGapLogLines.quick : M6AbGapLogLines.allSet),
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
    if (_grabbing) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what. In the earth view the drag
  /// on the spare lead and the hold on the nut, in turn (fault or not); in the
  /// gap view a sideways swipe, one way then the other; the stuck keys: a
  /// sweep over all three; before the stroke, in turn: a sweep over the
  /// handle, the phone and the docket, the swipe down the lead and — once the
  /// breaker is OFF — the hold-then-drag on the first part of the arc; after
  /// it: the swipe up and a sweep over the docket's boxes and the phone.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    const v = M6AbGeo.view;
    switch (_view) {
      case _View.earth:
        return n.isEven
            ? HintSpec.drag(v.topLeft + M6EarthView.spareHome, toward: const Offset(1, -0.6), travel: 56, space: HintSpace.scene)
            : HintSpec.hold(v.topLeft + M6EarthView.nut, space: HintSpace.scene);
      case _View.gap:
        return HintSpec.swipe(v.center.translate(n.isEven ? 40 : -40, 0), toward: Offset(n.isEven ? -1 : 1, 0), travel: 80, space: HintSpace.scene);
      case _View.none:
        break;
    }
    if (_keysOpen) return HintSpec.sweepOver(_keyKeys);
    if (!_run.stroked) {
      final ways = <HintSpec? Function()>[
        () => HintSpec.sweepOver([_handleKey, _phoneKey, _docketKey]),
        () => HintSpec.swipe(geo.leadSwipeFrom, toward: const Offset(0, 1), travel: 60, space: HintSpace.scene),
        if (_run.offConfirmed) ...[
          () => HintSpec.hold(geo.grip(0), space: HintSpace.scene),
          () => HintSpec.drag(geo.grip(0), toward: const Offset(1, 0.7), travel: 40, space: HintSpace.scene),
        ],
      ];
      return ways[n % ways.length]();
    }
    final ways = <HintSpec? Function()>[
      () => HintSpec.swipe(geo.swipeFrom, toward: const Offset(0, -1), travel: 90, space: HintSpace.scene),
      () => HintSpec.sweepOver([..._boxKeys, _phoneKey]),
    ];
    return ways[n % ways.length]();
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6AbGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final j = _job;
    final caps = j.caps;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('structure'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M6AbPainter(geo: geo, rig: M6AbRig(place: j.place, kind: j.kind, blades: caps), seed: _seed + _run.index, handle: _handle),
                  ),
                ),
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
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6AbGapLogLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (_) => _tapScene(),
            onVerticalDragStart: (d) => _dragStart(d.localPosition),
            onVerticalDragUpdate: (d) => _dragUpdate(d.localPosition),
            onVerticalDragEnd: (_) => _dragEnd(geo),
            onLongPressStart: (d) => _grabAt(d.localPosition, geo, d.globalPosition),
            onLongPressMoveUpdate: (d) => _strokeMove(d.localPosition, geo, d.globalPosition),
            onLongPressEnd: (d) => _strokeEnd(d.globalPosition),
          ),
        ),
      ),
      // The handle's name for screen readers (and tests); the scene's
      // detector takes its touches.
      Positioned.fromRect(
        key: const ValueKey('handle-label'),
        rect: geo.handleHit,
        child: IgnorePointer(child: Semantics(label: M6AbGapLogLines.handleLabel, child: SizedBox.expand(key: _handleKey))),
      ),
      // The docket on the van door.
      Positioned.fromRect(
        key: const ValueKey('docket'),
        rect: M6AbGeo.docket,
        child: ColorFiltered(
          colorFilter: grey,
          child: _Docket(
            key: _docketKey,
            job: _run.index,
            ticked: _run.ticked,
            reported: _run.reported,
            boxKeys: _boxKeys,
            onTick: _tickBox,
          ),
        ),
      ),
      if (_view == _View.gap && !_freeze)
        Positioned.fromRect(
          key: ValueKey('gap-view-${_run.index}'),
          rect: M6AbGeo.view,
          child: _GapView(
            kind: j.kind,
            phase: _lensPhase,
            open: math.min(_handle.value, caps[_lensPhase]),
            seed: _seed + _run.index,
            onPan: _pan,
            onClose: _closeView,
            onMiss: _hints.missTap,
          ),
        ),
      if (_view == _View.earth && !_freeze)
        Positioned.fromRect(
          key: ValueKey('earth-view-${_run.index}'),
          rect: M6AbGeo.view,
          child: _EarthView(
            state: j.earth,
            fixed: _run.earthFixed,
            onSpareDrop: _spareDrop,
            onNutHold: _nutHold,
            onClose: _closeView,
            onMiss: _hints.missTap,
          ),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6AbFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // The next switch: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('job-${_run.index}'),
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
    final replyPending = _calling || (_run.waiting && !_run.offConfirmed);
    final preview = _preview;
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
              labels: [for (var i = 0; i < 2; i++) M6AbGapLogLines.job(i)],
              done: {for (var i = 0; i < math.min(_run.index, 2); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !replyPending && preview == null && !_grabbing,
            hintKey: '${_run.index}/$_steps/${_view.name}/$_keysOpen',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn)
                Positioned(
                  key: ValueKey('hud-phone-${_run.index}'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 8,
                  child: _PhoneRow(
                    phoneKey: _phoneKey,
                    keyKeys: _keyKeys,
                    thread: _thread,
                    typing: replyPending,
                    keysOpen: _keysOpen,
                    aside: _asideKeys,
                    onPhone: _tapPhone,
                    onKey: _tapKey,
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
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (preview != null && playing && _card == null)
                Positioned.fill(
                  key: ValueKey('key-preview-$preview'),
                  child: CardPreviewOverlay(
                    textBn: M6AbGapLogLines.reportCard(preview),
                    icon: Icons.phone_in_talk_rounded,
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: () => _confirmKey(Offset(size.width / 2, size.height * 0.6)),
                    onReject: _rejectKey,
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
                  line: M6AbGapLogLines.intro,
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

/// The docket: the job, 'গ্যাপ দেখা' and the three blank boxes R · Y · B (tap
/// a box to tick it); a phoned-in phase shows a phone mark.
class _Docket extends StatelessWidget {
  const _Docket({super.key, required this.job, required this.ticked, required this.reported, required this.boxKeys, required this.onTick});

  final int job;
  final Set<int> ticked;
  final int reported;
  final List<GlobalKey> boxKeys;
  final void Function(int p, Offset global) onTick;

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
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 34, height: 6, decoration: BoxDecoration(color: const Color(0xFF9AA2A8), borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('${M6AbGapLogLines.docket} · ${M6AbGapLogLines.job(job)}',
                  style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(M6AbGapLogLines.gapRow, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF7A5A2E))),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  for (var p = 0; p < 3; p++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _Box(key: boxKeys[p], phase: p, ticked: ticked.contains(p), phoned: reported == p, onTap: (g) => onTick(p, g)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({super.key, required this.phase, required this.ticked, required this.phoned, required this.onTap});
  final int phase;
  final bool ticked;
  final bool phoned;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M6AbGapLogLines.box(phase),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Column(
          children: [
            Text(M6AbGapLogLines.phases[phase], style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
            const SizedBox(height: 2),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF5A4A30), width: 1.8),
                ),
                alignment: Alignment.center,
                child: ticked
                    ? const Icon(Icons.check_rounded, size: 30, color: Color(0xFF1F6F3A))
                    : phoned
                        ? const Icon(Icons.phone_in_talk_rounded, size: 24, color: Color(0xFFC0392B))
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The phone, the last texts of this job, and — once the switch is opened
/// and the phone tapped — the three stuck-phase keys.
class _PhoneRow extends StatelessWidget {
  const _PhoneRow({
    required this.phoneKey,
    required this.keyKeys,
    required this.thread,
    required this.typing,
    required this.keysOpen,
    required this.aside,
    required this.onPhone,
    required this.onKey,
  });

  final GlobalKey phoneKey;
  final List<GlobalKey> keyKeys;
  final List<({String text, bool mine})> thread;
  final bool typing;
  final bool keysOpen;
  final Set<int> aside;
  final ValueChanged<Offset> onPhone;
  final ValueChanged<int> onKey;

  @override
  Widget build(BuildContext context) {
    final last = thread.length <= 2 ? thread : thread.sublist(thread.length - 2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Semantics(
          key: phoneKey,
          button: true,
          label: M6AbGapLogLines.phone,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onPhone(d.globalPosition),
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                      border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.8),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    child: const Icon(Icons.phone_rounded, size: 26, color: SlmColors.gold300),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                    child: Text(M6AbGapLogLines.phone, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 236),
            child: keysOpen
                ? _Keys(keyKeys: keyKeys, aside: aside, onKey: onKey)
                : (last.isEmpty && !typing)
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
                        decoration: BoxDecoration(
                          color: const Color(0xEE101A2B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3C5A80), width: 1.4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final m in last)
                              Align(
                                alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    m.mine ? m.text : '${M6AbGapLogLines.substation}: ${m.text}',
                                    style: bangla(fontSize: 11.5, fontWeight: m.mine ? FontWeight.w600 : FontWeight.w800, color: m.mine ? const Color(0xFFB9C7D8) : SlmColors.ivory),
                                  ),
                                ),
                              ),
                            if (typing) Text('${M6AbGapLogLines.substation}: …', style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF8FA3BC))),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}

class _Keys extends StatelessWidget {
  const _Keys({required this.keyKeys, required this.aside, required this.onKey});
  final List<GlobalKey> keyKeys;
  final Set<int> aside;
  final ValueChanged<int> onKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.8), width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M6AbGapLogLines.stuckKeys, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var p = 0; p < 3; p++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: CardAside(
                    aside: aside.contains(p),
                    child: Semantics(
                      key: keyKeys[p],
                      button: true,
                      label: M6AbGapLogLines.key(p),
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onKey(p),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C2E4A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: SlmColors.gold300, width: 1.4),
                          ),
                          child: Text(M6AbGapLogLines.phases[p], style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The tilt-up gap view: one phase at a time; swipe sideways to pan, ⌄ (or a
/// swipe down) to look back down.
class _GapView extends StatefulWidget {
  const _GapView({required this.kind, required this.phase, required this.open, required this.seed, required this.onPan, required this.onClose, required this.onMiss});
  final M6AbBreak kind;
  final int phase;
  final double open;
  final int seed;
  final ValueChanged<int> onPan;
  final VoidCallback onClose;
  final VoidCallback onMiss;

  @override
  State<_GapView> createState() => _GapViewState();
}

class _GapViewState extends State<_GapView> {
  double _dx = 0;
  double _dy = 0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M6AbGapLogLines.gapView,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onMiss,
        onPanStart: (_) {
          _dx = 0;
          _dy = 0;
        },
        onPanUpdate: (d) {
          _dx += d.delta.dx;
          _dy += d.delta.dy;
        },
        onPanEnd: (_) {
          if (_dx.abs() >= 36 && _dx.abs() > _dy.abs()) {
            widget.onPan(_dx < 0 ? 1 : -1);
          } else if (_dy > 50) {
            widget.onClose();
          } else {
            widget.onMiss();
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF0B1324), width: 4),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: M6AbGapViewPainter(kind: widget.kind, open: widget.open, phase: widget.phase, seed: widget.seed)),
                ),
                Positioned(
                  left: 8,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xDD0B1324), borderRadius: BorderRadius.circular(8)),
                    child: Text(M6AbGapLogLines.phases[widget.phase], style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var p = 0; p < 3; p++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: p == widget.phase ? SlmColors.gold300 : const Color(0x880B1324)),
                        ),
                    ],
                  ),
                ),
                Positioned(right: 2, top: 2, child: _CloseButton(onTap: widget.onClose)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The earth-lead close-up: drag the spare lead across a cut, hold the clamp
/// nut to tighten it; ⌄ to look back up.
class _EarthView extends StatefulWidget {
  const _EarthView({required this.state, required this.fixed, required this.onSpareDrop, required this.onNutHold, required this.onClose, required this.onMiss});
  final M6AbEarth state;
  final bool fixed;
  final void Function(bool onCut, Offset global) onSpareDrop;
  final ValueChanged<Offset> onNutHold;
  final VoidCallback onClose;
  final VoidCallback onMiss;

  @override
  State<_EarthView> createState() => _EarthViewState();
}

class _EarthViewState extends State<_EarthView> {
  final _spare = ValueNotifier<Offset>(M6EarthView.spareHome);
  Offset? _grab;

  @override
  void dispose() {
    _spare.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spareGone = widget.state == M6AbEarth.cut && widget.fixed;
    return Semantics(
      label: M6AbGapLogLines.earthView,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onMiss,
        onPanStart: (d) {
          _grab = !spareGone && M6EarthView.spareHit(_spare.value).contains(d.localPosition) ? d.localPosition - _spare.value : null;
        },
        onPanUpdate: (d) {
          final g = _grab;
          if (g != null) _spare.value = d.localPosition - g;
        },
        onPanEnd: (d) {
          final g = _grab;
          _grab = null;
          if (g == null) {
            widget.onMiss();
            return;
          }
          final onCut = (_spare.value - M6EarthView.gap).distance <= M6EarthView.dropRadius;
          _spare.value = M6EarthView.spareHome;
          final box = context.findRenderObject() as RenderBox?;
          widget.onSpareDrop(onCut, box == null ? Offset.zero : box.localToGlobal(M6EarthView.gap));
        },
        onLongPressStart: (d) {
          if (M6EarthView.nutHit.contains(d.localPosition)) {
            widget.onNutHold(d.globalPosition);
          } else {
            widget.onMiss();
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF0B1324), width: 4),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: M6AbEarthViewPainter(state: widget.state, fixed: widget.fixed, spare: _spare))),
                if (!spareGone)
                  ValueListenableBuilder<Offset>(
                    valueListenable: _spare,
                    builder: (_, at, _) => Positioned.fromRect(
                      rect: M6EarthView.spareHit(at),
                      child: IgnorePointer(child: Semantics(label: M6AbGapLogLines.spareLead, child: const SizedBox.expand())),
                    ),
                  ),
                Positioned.fromRect(
                  rect: M6EarthView.nutHit,
                  child: IgnorePointer(child: Semantics(label: M6AbGapLogLines.clampNut, child: const SizedBox.expand())),
                ),
                Positioned(right: 2, top: 2, child: _CloseButton(onTap: widget.onClose)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M6AbGapLogLines.viewClose,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: const Color(0xDD0B1324), shape: BoxShape.circle, border: Border.all(color: SlmColors.gold300, width: 1.4)),
              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: SlmColors.gold300),
            ),
          ),
        ),
      ),
    );
  }
}
