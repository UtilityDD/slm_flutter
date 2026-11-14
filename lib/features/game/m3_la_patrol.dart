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
import 'm3_la_patrol_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_la_patrol_world.dart' show M3LaPatrolBody, M3LaPatrolFault, M3LaPatrolGeo, M3LaPatrolPhase, m3LaPatrolPhaseBn;

// Lesson 3.5 "লাইটনিং অ্যারেস্টার (LA)", কাজ 1 "এল এ-র খবর" (Module 3). The
// morning after a storm the trainee patrols four DTRs and checks their
// lightning arresters from the ground (lesson point 1's daily check: is the LA
// there and intact; point 3: a healthy LA — no crack, break or burn mark on
// the housing; the earth lead firmly connected, not cut; a burst LA means a
// big surge came; a disconnector that has blown leaves the earth lead hanging
// — proof the LA has failed, while the line keeps running). Each DTR is dealt
// fresh: one is healthy, one has a blown disconnector (the hanging lead),
// two have one of: a cracked housing, a burn mark, a burst LA, an earth lead
// cut. Porcelain (brown) or polymer (grey, pro tip 4) housings.
//
// Moves: spot (tap the bad LA or its lead — or "সব ঠিক আছে"), choose (what
// now: write it down from a distance and report — not touch, not climb, not
// ignore), say no (the careless coworker on the hanging-lead DTR: "ঝুলন্ত
// তারটা টেনে খুলে নাও"). Then the reason (ReasonTable) and the next DTR by
// itself.
//
// Deadly: a hand on the hanging / cut earth lead (listening to him, or the
// choice); climbing the live structure to fix it. Slips: a failed LA missed or
// the wrong one marked, a healthy DTR reported, a failed LA not reported.
// (Listening is deadly here, not the playbook's slip, because the act he
// pushes is on Module 3's deadly list — MODULE3_LADDER.md row 14; flagged to
// the owner.)
//
// Gesture hint (looking): a sweep over the three LAs and "সব ঠিক আছে" alike —
// how to answer, never which. The decks bring their own sweep.
//
// Flagged to the owner: "never touch a hanging earth lead — the LA above is on
// the line, a failed LA's lead may be live" and "write it down and report"
// are general field rules, not in the lesson or film text (the lesson says a
// hanging lead proves the LA failed; the film: "মাটিতে ঝুলে থাকা তার দেখলেই
// বুঝবেন এল এ খারাপ"). Climbing only after shutdown, permit, test and earth is
// Module 1's rule. The lead routing (each LA's own lead to its own earth rod)
// is drawn for clarity.

// ============================================================================
// Content
// ============================================================================

/// What the trainee does about a failed LA.
enum M3LaPatrolAct { report, touchLead, climb, ignore }

/// Where the round stands.
enum M3LaPatrolStage { look, act, why }

@immutable
class M3LaPatrolCase {
  const M3LaPatrolCase({required this.id, required this.dtrNo, required this.body, required this.fault, this.phase = M3LaPatrolPhase.r});
  final String id;
  final int dtrNo;
  final M3LaPatrolBody body;
  final M3LaPatrolFault fault;

  /// The phase the fault is on (ignored when healthy).
  final M3LaPatrolPhase phase;

  bool get healthy => fault == M3LaPatrolFault.healthy;
}

abstract final class M3LaPatrolLines {
  static const title = 'এল এ-র খবর';
  static const intro = 'ঝড় থেমেছে! চারটে ডিটিআর-এর এল এ নিচ থেকে দেখে আসুন।';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];
  static const ask = 'এই ডিটিআর-এর এল এ কেমন? খারাপটা দেখান, নয়তো সব ঠিক।';

  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];
  static const actAsk = 'দেখেছেন। এবার কী করবেন?';
  static const tapAct = ['এবার কী করবেন, বেছে নিন।', 'খারাপ এল এ পেলেন — এখন কাজ কী?'];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads / buttons.
  static const sceneLabel = 'ডিটিআর আর এল এ';
  static const allOk = 'সব ঠিক আছে';
  static const stampBad = 'এল এ খারাপ — রিপোর্ট';
  static const stampOk = 'এল এ ঠিক আছে';

  // What to do: 36–43 letters each. The right cards' words (লিখে, রিপোর্ট,
  // অফিসে, খাতায়, দূর থেকে …) also appear on wrong ones — no word gives the
  // right card away.
  static const actRight = [
    'দূর থেকে ডিটিআর নম্বর লিখে রিপোর্ট করি',
    'ডিটিআর নম্বর আর ফেজ লিখে অফিসে জানাই',
    'কাছে না গিয়ে খাতায় লিখে রিপোর্ট পাঠাই',
  ];
  static const actWrong = {
    'কাছে গিয়ে তারটা টেনে দেখি, পরে খাতায় লিখি': M3LaPatrolAct.touchLead,
    'তারটা হাতে খুলে কষে জুড়ে, পরে রিপোর্ট করি': M3LaPatrolAct.touchLead,
    'খুঁটিতে উঠে এল এ খুলে, পরে অফিসে জানাই': M3LaPatrolAct.climb,
    'শাটডাউন না করেই উঠে এল এ-টা ঠিক করে দিই': M3LaPatrolAct.climb,
    'লাইন তো চলছে, নম্বর লিখে রাখার দরকার নেই': M3LaPatrolAct.ignore,
    'দূর থেকে সব চালু লাগছে, রিপোর্ট পাঠাই না': M3LaPatrolAct.ignore,
    'এখন থাক, পরের টহলে ফেজ আর ডিটিআর দেখব': M3LaPatrolAct.ignore,
  };

  /// The act a dealt option stands for.
  static M3LaPatrolAct actOf(ChoiceOption o) => o.correct ? M3LaPatrolAct.report : (actWrong[o.textBn] ?? M3LaPatrolAct.ignore);

  // The reasons: the right ones fit what this DTR had; the wrong ones are
  // field excuses and the lesson's myths. 35–46 letters each. No word sits
  // only on a fault's right cards: every word of them (the fault's own words
  // too) is on that fault's wrong cards, and তাই / ধরলাম / খারাপ are on both
  // sides, so neither a word nor punctuation gives the right card away.
  static const whyBad = 'কেন এটাকে খারাপ ধরলেন?';
  static const whyOk = 'কেন সব ঠিক ধরলেন?';
  static const badRight = {
    M3LaPatrolFault.dropped: ['ডিসকানেক্টর ফেটে আর্থ তার ঝুলছে, এল এ খারাপ', 'আর্থ তার ঝুলছে মানে এল এ ভেতরে বিগড়ে গেছে'],
    M3LaPatrolFault.cracked: ['বডিতে ফাটল, এমন এল এ কোনো সুরক্ষা দেয় না', 'পোর্সেলিন ফাটা, তাই এই এল এ খারাপ ধরলাম'],
    M3LaPatrolFault.burnt: ['বডিতে পোড়া দাগ, এই এল এ আর অক্ষত নেই', 'গায়ে পোড়া কালো দাগ, তাই খারাপ ধরলাম'],
    M3LaPatrolFault.burst: ['এল এ ফেটে ভেঙেছে, লাইনে বড় সার্জ এসেছিল', 'এল এ ভেঙে ফেটে আছে, কোনো সুরক্ষা দেয় না'],
    M3LaPatrolFault.leadCut: ['আর্থ তার কাটা, আর্থিং ছাড়া এল এ অকেজো', 'আর্থ তার কাটা, তাই সার্জ মাটিতে যাওয়ার পথ নেই'],
  };

  /// Excuses dealt on every faulty DTR.
  static const badWrong = [
    'ঝড়ে ভিজেছে, তাই এল এ-টাকে খারাপ ধরলাম',
    'রং একটু পুরোনো লাগছে, এমন এল এ আর ভরসার নয়',
    'ঝড়ের পরে সব এল এ এমনিতেই বদলাতে হয়',
    'পাশের ডিটিআর-এ খারাপ ছিল, এটাও একই হবে',
    'এল এ বজ্রপাত আটকায়, ঝড়ে ক্ষয়ে গেছে',
    'সাথী বলল খারাপ, আমিও তাই খারাপ ধরলাম',
    'বডিতে বৃষ্টির জলের দাগ, এল এ আর ভরসার নয়',
    'আর্থ তার ভেজা, এমন এল এ কোনো সুরক্ষা দেয় না',
    'এই এল এ-র গায়ে পাখি বসে, ওতেই নষ্ট হয়',
    'রং ছাড়া আর কিছু দেখিনি, তবু খারাপ ধরলাম',
  ];

  /// Excuses that borrow this fault's own words but give a wrong reason.
  static const badWrongFor = {
    M3LaPatrolFault.dropped: ['ডিসকানেক্টর পুরোনো, রং ফেটে উঠেছে, তাই ধরলাম', 'ঝড়ে ভিজেছে মানে ভেতরে জল ঢুকে বিগড়ে গেছে', 'খুঁটিতে পোস্টার ঝুলছে, এল এ-ও ঢিলে হয়েছে'],
    M3LaPatrolFault.cracked: ['খুঁটির গায়ে ফাটল, এমন এল এ ভরসার নয়', 'পোর্সেলিন তো পুরোনো ধাঁচের, তাই খারাপ ধরলাম', 'ঝড়ে ফাটা ডাল নিচে পড়ে আছে, এল এ-ও গেছে'],
    M3LaPatrolFault.burnt: ['খুঁটির গায়ে কালো আলকাতরা, তাই খারাপ ধরলাম', 'পাশের ঝোপ পোড়া, এই এল এ আর অক্ষত নেই'],
    M3LaPatrolFault.burst: ['পাশের বেড়া ভেঙেছে, লাইনে বড় সার্জ এসেছিল', 'ঝড়ে ডাল ভেঙে পড়েছে, এল এ-ও ফেটে আছে নিশ্চয়ই'],
    M3LaPatrolFault.leadCut: ['পাশের গাছের ডাল কাটা, এল এ-র ক্ষতি হয়েছেই', 'ঝড়ে মাটিতে জল জমেছে, সার্জ যাওয়ার পথ নেই', 'বৃষ্টিতে আর্থিং ভিজেছে, এমন এল এ অকেজো'],
  };
  static const okRight = ['তিনটের বডি অক্ষত, আর্থ তার জোড়া, ঝুলছে না', 'ফাটল বা পোড়া দাগ নেই, আর্থ তার মজবুত জোড়া'];
  static const okWrong = [
    'লাইন তো দিব্যি চলছে, নিশ্চয়ই সব ঠিক আছে',
    'ঝড় থেমেছে, তিনটের দিকে আর দেখার কিছু নেই',
    'এল এ বজ্রপাত আটকায়, ওর নিজের কিছু হয় না',
    'আর্থ তার সামান্য কাটা থাকলেও এল এ চলে',
    'নিচ থেকে বডি ভালো দেখা যায় না, ঠিকই হবে',
    'নতুন লাগানো, ওতে ফাটল বা পোড়া হয় না',
    'আর্থ তার জোড়া দেখেই আর কিছু দেখিনি',
    'আর্থ তার একটু ঝুলছে, তবু লাইন তো চলছে',
    'দূর থেকে অক্ষত লাগছে, দাগ খোঁজার দরকার নেই',
    'খুঁটি মজবুত দাঁড়িয়ে, তাই এল এ ঠিক আছে',
  ];

  static List<String> whyRight(M3LaPatrolCase c) => c.healthy ? okRight : badRight[c.fault]!;
  static List<String> whyWrong(M3LaPatrolCase c) => c.healthy ? okWrong : [...badWrong, ...badWrongFor[c.fault]!];

  /// The careless coworker at the hanging lead.
  static const coworker = CoworkerScript(
    line: 'আরে, ঝুলন্ত তারটা টেনে খুলে নাও! ঝামেলা মিটে যাক।',
    exitLine: 'হুঁ! যা খুশি করুন।',
    // No card opens with "না," and the refusals' words (রিপোর্ট, লিখে, হাত,
    // লাইনে …) appear on the listening cards too.
    right: ['ঝুলন্ত তার ছোঁব না, আগে রিপোর্ট করব', 'ওপরের এল এ লাইনে জোড়া, ওতে হাত দেব না', 'তারে হাত নয়, খাতায় লিখে রিপোর্ট দেব'],
    wrong: [
      'ঠিক, ঝুলন্ত তার টেনে খুলে পরে রিপোর্ট করব',
      'আচ্ছা, ওটা তো আর্থের তার, হাত দেওয়াই যায়',
      'এল এ তো খারাপ, লাইনে আর জোড়া নেই, খুলি',
      'শুকনো হাতে ধরলে কিছু হবে না, খুলে নিই',
      'ঠিক আছে, এক টানে খুলে খাতায় লিখে দেব',
      'তাড়া আছে, তারটা টেনে ফেলে পরেরটায় যাই',
    ],
    asks: ['ও বলছে তারটা টেনে খুলতে। কী করবেন?', 'ঝুলন্ত তারে হাত দেবেন?', 'টেনে খুলবেন, না রিপোর্ট করবেন?'],
  );

  static const callHeld = 'ঠিক! ঝুলন্ত তার কখনো ছোঁবেন না।';
  static const allSet = 'ঝড়ের পরে এল এ-র খবর নেওয়া শিখে গেছেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — বডি দেখুন, আর্থ তার দেখুন, না ছুঁয়ে রিপোর্ট।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caught = {
    M3LaPatrolFault.dropped: 'ঝুলন্ত আর্থ তার',
    M3LaPatrolFault.cracked: 'ফাটা বডি',
    M3LaPatrolFault.burnt: 'পোড়া দাগ',
    M3LaPatrolFault.burst: 'ফেটে যাওয়া এল এ',
    M3LaPatrolFault.leadCut: 'কাটা আর্থ তার',
    M3LaPatrolFault.healthy: 'সুস্থ এল এ চিনেছেন',
  };
  static const caughtReport = 'না ছুঁয়ে রিপোর্ট';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M3LaPatrolMistakes {
  static const _dir = 'assets/game/art/m3_la_patrol';
  static const _k = '3.5/m3_la_patrol';

  static const touchLead = DoMistake(
    key: '$_k/touch-lead',
    textBn: 'এল এ-র আর্থ তারে হাত দিলেন! ওপরের এল এ লাইনের সাথে জোড়া — খারাপ এল এ-র তার লাইভ হতে পারে। দূর থেকে লিখে রিপোর্ট।',
    art: '$_dir/touch_lead.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const climbLive = DoMistake(
    key: '$_k/climb-live',
    textBn: 'চালু লাইনের ডিটিআর-এ উঠে পড়লেন! শাটডাউন, পারমিট, টেস্ট আর আর্থ ছাড়া এল এ-তে হাত নয় — আগে রিপোর্ট।',
    art: '$_dir/climb_live.svg',
    deadly: true,
  );
  static const noReport = DoMistake(
    key: '$_k/no-report',
    textBn: 'খারাপ এল এ দেখেও জানালেন না। লাইন চললেও ট্রান্সফরমার এখন অরক্ষিত — ডিটিআর নম্বর আর ফেজ লিখে রিপোর্ট করুন।',
    art: '$_dir/no_report.svg',
    lessonPoint: 2,
  );
  static const falseAlarm = DoMistake(
    key: '$_k/false-alarm',
    textBn: 'এই ডিটিআর-এর তিনটে এল এ-ই ঠিক ছিল। বডিতে ফাটল, পোড়া দাগ, ঝুলন্ত বা কাটা আর্থ তার — এগুলোই খুঁজুন।',
    art: '$_dir/false_alarm.svg',
    lessonPoint: 2,
  );
  static const missedDropped = DoMistake(
    key: '$_k/missed-dropped',
    textBn: 'ঝুলন্ত আর্থ তার চোখ এড়াল। ডিসকানেক্টর ফেটে তার ঝুললে বুঝবেন — ওই এল এ খারাপ, লাইন চললেও।',
    art: '$_dir/missed_dropped.svg',
    lessonPoint: 2,
  );
  static const missedCracked = DoMistake(
    key: '$_k/missed-cracked',
    textBn: 'এল এ-র বডিতে ফাটল ছিল। ফাটা এল এ সুরক্ষা দেয় না — নিচ থেকে বডিটা ভালো করে দেখুন।',
    art: '$_dir/missed_cracked.svg',
    lessonPoint: 2,
  );
  static const missedBurnt = DoMistake(
    key: '$_k/missed-burnt',
    textBn: 'এল এ-র গায়ে পোড়া দাগ ছিল। পোড়া দাগ মানে এল এ আর অক্ষত নেই — রিপোর্ট করতে হতো।',
    art: '$_dir/missed_burnt.svg',
    lessonPoint: 2,
  );
  static const missedBurst = DoMistake(
    key: '$_k/missed-burst',
    textBn: 'একটা এল এ ফেটে ভেঙে গিয়েছিল। ভাঙা এল এ বলে লাইনে বড় সার্জ এসেছিল — ওর সুরক্ষা আর নেই।',
    art: '$_dir/missed_burst.svg',
    lessonPoint: 2,
  );
  static const missedLeadCut = DoMistake(
    key: '$_k/missed-lead-cut',
    textBn: 'একটা এল এ-র আর্থ তার নিচে কাটা ছিল। আর্থিং ছাড়া এল এ থাকা আর না থাকা সমান।',
    art: '$_dir/missed_lead_cut.svg',
    lessonPoint: 2,
  );

  static DoMistake missed(M3LaPatrolFault f) => switch (f) {
        M3LaPatrolFault.dropped => missedDropped,
        M3LaPatrolFault.cracked => missedCracked,
        M3LaPatrolFault.burnt => missedBurnt,
        M3LaPatrolFault.burst => missedBurst,
        M3LaPatrolFault.leadCut => missedLeadCut,
        M3LaPatrolFault.healthy => falseAlarm,
      };

  static List<DoMistake> get all => [touchLead, climbLive, noReport, falseAlarm, missedDropped, missedCracked, missedBurnt, missedBurst, missedLeadCut];
}

@immutable
class M3LaPatrolDeal {
  const M3LaPatrolDeal({required this.cases, required this.callAt});
  final List<M3LaPatrolCase> cases;

  /// The DTR with the hanging lead: the careless coworker comes there.
  final int callAt;
}

/// Four DTRs in a fresh order: one healthy, one with a blown disconnector
/// (the hanging lead), two with one of a crack, a burn mark, a burst body, a
/// cut earth lead. A crack or a burst only on porcelain (polymer "does not
/// crack easily" — pro tip 4).
M3LaPatrolDeal dealM3LaPatrol(math.Random rng) {
  final others = [M3LaPatrolFault.cracked, M3LaPatrolFault.burnt, M3LaPatrolFault.burst, M3LaPatrolFault.leadCut]..shuffle(rng);
  final faults = [M3LaPatrolFault.healthy, M3LaPatrolFault.dropped, others[0], others[1]]..shuffle(rng);
  final nos = <int>{};
  while (nos.length < 4) {
    nos.add(2 + rng.nextInt(47));
  }
  final noList = nos.toList();
  final cases = [
    for (var i = 0; i < 4; i++)
      M3LaPatrolCase(
        id: 'la$i',
        dtrNo: noList[i],
        body: (faults[i] == M3LaPatrolFault.cracked || faults[i] == M3LaPatrolFault.burst || rng.nextBool()) ? M3LaPatrolBody.porcelain : M3LaPatrolBody.polymer,
        fault: faults[i],
        phase: M3LaPatrolPhase.values[rng.nextInt(3)],
      ),
  ];
  return M3LaPatrolDeal(cases: cases, callAt: faults.indexOf(M3LaPatrolFault.dropped));
}

/// The play state (pure logic).
class M3LaPatrolRun {
  M3LaPatrolRun(this.deal);

  final M3LaPatrolDeal deal;
  int index = 0;
  var stage = M3LaPatrolStage.look;

  /// The round is settled (right, or a slip shown): no more moves on it.
  var shown = false;
  M3LaPatrolPhase? marked;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  M3LaPatrolCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// The trainee points at [p]'s LA (or its lead); null = "সব ঠিক আছে".
  /// Null back = right (the stage moves on); otherwise the slip.
  DoMistake? spot(M3LaPatrolPhase? p) {
    if (ended || shown || stage != M3LaPatrolStage.look) return null;
    final c = current;
    if (c.healthy) {
      if (p == null) {
        stage = M3LaPatrolStage.why;
        shown = true;
        _tag(M3LaPatrolLines.caught[M3LaPatrolFault.healthy]!);
        return null;
      }
      marked = p;
      shown = true;
      slips++;
      return M3LaPatrolMistakes.falseAlarm;
    }
    if (p == c.phase) {
      marked = p;
      stage = M3LaPatrolStage.act;
      _tag(M3LaPatrolLines.caught[c.fault]!);
      return null;
    }
    marked = p;
    shown = true;
    slips++;
    return M3LaPatrolMistakes.missed(c.fault);
  }

  /// What the trainee does about the failed LA he found.
  DoMistake? act(M3LaPatrolAct a) {
    if (ended || stage != M3LaPatrolStage.act) return null;
    shown = true;
    switch (a) {
      case M3LaPatrolAct.report:
        stage = M3LaPatrolStage.why;
        _tag(M3LaPatrolLines.caughtReport);
        return null;
      case M3LaPatrolAct.touchLead:
        return deadly = M3LaPatrolMistakes.touchLead;
      case M3LaPatrolAct.climb:
        return deadly = M3LaPatrolMistakes.climbLive;
      case M3LaPatrolAct.ignore:
        slips++;
        return M3LaPatrolMistakes.noReport;
    }
  }

  void next() {
    index++;
    stage = M3LaPatrolStage.look;
    shown = false;
    marked = null;
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A DTR with a
/// fault (ms): look 6000, tap 1000, the action deck ~6000, the reason ~8200
/// ≈ 21200; the healthy one ≈ 15000; the coworker ~9600: ≈ 88200; 85 % ≈ 75 s.
const kM3LaPatrolQuickMs = 75000;

@immutable
class M3LaPatrolPack {
  const M3LaPatrolPack({required this.id, required this.titleBn, this.quickMs = kM3LaPatrolQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3LaPatrolPacks = {
  'do_3_5_a': M3LaPatrolPack(id: 'do_3_5_a', titleBn: M3LaPatrolLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3LaPatrolPage extends StatefulWidget {
  const M3LaPatrolPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M3LaPatrolPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3LaPatrolPage> createState() => _M3LaPatrolPageState();
}

class _M3LaPatrolPageState extends State<M3LaPatrolPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _LaRunPage(
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

class _LaRunPage extends ConsumerStatefulWidget {
  const _LaRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3LaPatrolPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_LaRunPage> createState() => _LaRunPageState();
}

class _LaRunPageState extends ConsumerState<_LaRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3LaPatrolRun _run = M3LaPatrolRun(dealM3LaPatrol(widget.rng));
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

  /// The stamp on the DTR (true = bad, reported; false = all fine).
  bool? _stamp;

  /// A missed fault shown in amber after the slip.
  var _reveal = false;

  // The action deck (what now?).
  var _actOpen = false;
  List<ChoiceOption> _actOpts = const [];
  String? _actWrong;
  String? _actPicked;
  int _actN = 0;

  var _freeze = false;
  M3LaPatrolAct? _deathBy;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // The gesture hint (looking): the scene layer (to map the LAs to the
  // screen), the "সব ঠিক আছে" button and the geometry last drawn.
  final _hints = IdleHintController();
  final _sceneKey = GlobalKey();
  final _okKey = GlobalKey();
  M3LaPatrolGeo? _geoNow;

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

  bool get _canLook =>
      !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen && !_actOpen && !_run.shown && _run.stage == M3LaPatrolStage.look;

  /// Looking: a sweep over the three LAs and the "সব ঠিক আছে" button, in a
  /// fixed order on every DTR (healthy or not) — never a tap on one of them.
  HintSpec? _hint() {
    final geo = _geoNow;
    final box = _sceneKey.currentContext?.findRenderObject();
    if (geo == null || box is! RenderBox || !box.hasSize || !box.attached) return null;
    Rect toGlobal(Rect r) => Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
    final ok = HintSpec.globalRectOf(_okKey);
    return HintSpec.sweep([
      for (final p in M3LaPatrolPhase.values) toGlobal(geo.laBody(p)),
      ?ok,
    ]);
  }

  void _startRound() {
    setState(() {
      _stamp = null;
      _reveal = false;
      _actOpen = false;
      _wake++;
    });
    unawaited(_sayChain([M3LaPatrolLines.ask]));
  }

  // --- the spot ----------------------------------------------------------------
  void _tapScene(TapUpDetails d, M3LaPatrolGeo geo) {
    if (!_canLook) return;
    final c = _run.current;
    final p = geo.hit(d.localPosition, dropped: c.fault == M3LaPatrolFault.dropped ? c.phase : null);
    if (p == null) {
      _hints.missTap();
      return;
    }
    unawaited(_spot(p, d.globalPosition));
  }

  Future<void> _spot(M3LaPatrolPhase? p, Offset origin) async {
    if (!_canLook) return;
    _hush();
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    final m = _run.spot(p);
    final c = _run.current;
    if (m != null) {
      setState(() {
        _reveal = !c.healthy;
        _wake++;
      });
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    if (_run.stage == M3LaPatrolStage.why) {
      // All fine, rightly.
      _success(origin);
      return;
    }
    // A failed LA found: what now? At the hanging lead the same deck opens
    // and he is armed: he peeps in a moment later, or at once on the first
    // pick (holdForCoworker in _pickAct) — never a gap with nothing to do.
    _cue('sounds/quiz_select.ogg', volume: 0.5);
    setState(() => _wake++);
    if (_run.index == _run.deal.callAt && !coworkerDone) scheduleCoworker();
    _openAct();
  }

  void _openAct() {
    setState(() {
      _actOpts = dealChoices(M3LaPatrolLines.actRight, M3LaPatrolLines.actWrong.keys.toList(), widget.rng);
      _actWrong = null;
      _actPicked = null;
      _actOpen = true;
    });
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayChain([M3LaPatrolLines.actAsk]));
  }

  Future<void> _pickAct(ChoiceOption o, Offset origin) async {
    if (!_actOpen || coworkerOpen || _actWrong != null || _actPicked != null || _ended || _busy || tableBusy) return;
    // The decisive control: at the hanging lead a pick before he has come
    // does nothing but bring him in now (his deck takes this one's place).
    if (holdForCoworker()) return;
    _hush();
    setState(() => o.correct ? _actPicked = o.textBn : _actWrong = o.textBn);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _actOpen = false);
    await _commitAct(M3LaPatrolLines.actOf(o), origin);
  }

  Future<void> _commitAct(M3LaPatrolAct a, Offset origin) async {
    final m = _run.act(a);
    if (m == null) {
      _success(origin);
      return;
    }
    if (m.deadly) {
      await _deadly(m, a);
      return;
    }
    setState(() => _reveal = false);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  /// The DTR is settled rightly: the stamp, the ◆ on the table, the reason.
  void _success(Offset origin) {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    final c = _run.current;
    setState(() {
      _stamp = !c.healthy;
      _wake++;
    });
    putOnTable(15);
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M3LaPatrolLines.whyRight(c), M3LaPatrolLines.whyWrong(c), widget.rng),
      question: c.healthy ? M3LaPatrolLines.whyOk : M3LaPatrolLines.whyBad,
      stillValid: () => _run.index == idx && !_ended,
    ));
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
  CoworkerScript get coworkerScript => M3LaPatrolLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // Only at the hanging lead, after the trainee found it and before he has
    // settled it: his push ("pull the hanging lead off") fits nowhere else.
    // The action deck may be up (he replaces it), but not mid-pick.
    if (_ended || _run.index != _run.deal.callAt || _run.stage != M3LaPatrolStage.act || _run.shown) return null;
    if (_intro || _busy || _card != null || tableBusy || _actWrong != null || _actPicked != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    // His answer settles this DTR's "what now": the action deck under him goes.
    if (_actOpen) setState(() => _actOpen = false);
    if (!held) {
      // Listened to him: a hand on the hanging lead.
      await _commitAct(M3LaPatrolAct.touchLead, origin);
      return;
    }
    if (!_run.caught.contains(M3LaPatrolLines.caughtCall)) _run.caught.add(M3LaPatrolLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    await _sayChain([M3LaPatrolLines.callHeld]);
    if (!mounted || _ended) return;
    await _commitAct(M3LaPatrolAct.report, origin);
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3LaPatrolLines.tapWhy[_nudgeN++ % M3LaPatrolLines.tapWhy.length]
            : (_actOpen || _run.stage == M3LaPatrolStage.act)
                ? M3LaPatrolLines.tapAct[_actN++ % M3LaPatrolLines.tapAct.length]
                : _nudge.next(M3LaPatrolLines.ask);
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('la_patrol/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A hand on the lead (or on the live structure): the scene freezes grey,
  /// the arc flashes in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m, M3LaPatrolAct by) async {
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
      _deathBy = by;
      _actOpen = false;
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
    final speak = await SpokenOnce.first('la_patrol/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3LaPatrolLines.deadlyWord : M3LaPatrolLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? M3LaPatrolLines.fail : (_quickBonus ? M3LaPatrolLines.quick : M3LaPatrolLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_freeze) return LinemanMode.hold;
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_stamp == false) return LinemanMode.cheer;
    if (_run.marked != null && !_run.shown || _stamp == true) return LinemanMode.point;
    return LinemanMode.idle;
  }

  /// Where the arc starts on a deadly move.
  Offset _zapFrom(M3LaPatrolGeo geo) {
    final c = _run.current;
    return switch (c.fault) {
      M3LaPatrolFault.dropped when _deathBy == M3LaPatrolAct.touchLead => geo.dropEnd(c.phase) + const Offset(0, 8),
      M3LaPatrolFault.leadCut when _deathBy == M3LaPatrolAct.touchLead => geo.cutTop(c.phase),
      _ when _deathBy == M3LaPatrolAct.touchLead => Offset(M3LaPatrolGeo.runX(c.phase), geo.groundY - 96),
      _ => Offset(M3LaPatrolGeo.laX(c.phase), geo.laTop),
    };
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M3LaPatrolGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final zapFrom = _freeze ? _zapFrom(geo) : null;
    final touching = _freeze && _deathBy == M3LaPatrolAct.touchLead;
    final tb = touching ? geo.traineeAt(zapFrom!) : geo.trainee;
    final hand = tb.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final markAt = _run.marked == null ? null : (c.healthy || _run.marked != c.phase ? geo.laBody(_run.marked!).center : geo.markAt(c.phase, c.fault));
    final revealAt = _reveal && !c.healthy ? geo.markAt(c.phase, c.fault) : null;
    final target = markAt ?? revealAt;
    // He faces the right; turn him round to point left.
    final flip = target != null && target.dx < tb.center.dx && !touching;
    final up = target == null ? 1.3 : (2.2 + 0.5 * ((tb.top - target.dy) / 300).clamp(0.0, 1.0));
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
                  child: CustomPaint(
                    painter: M3LaPatrolWorldPainter(geo: geo, dtrNo: c.dtrNo, body: c.body, fault: c.fault, phase: c.phase),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: Transform.flip(
                  flipX: flip,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, point: up, wake: _wake, quiet: quiet),
                ),
              ),
            ],
          ),
        ),
      ),
      if ((markAt != null || revealAt != null) && !_freeze)
        Positioned.fill(
          key: ValueKey('marks-${_run.index}-${_run.marked}-$_reveal'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 420),
              builder: (_, v, _) => CustomPaint(painter: M3LaPatrolMarkPainter(mark: markAt, reveal: revealAt, v: v)),
            ),
          ),
        ),
      if (_stamp != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: geo.tank.left - 30,
          width: geo.tank.width + 60,
          top: geo.tank.top + 18,
          child: IgnorePointer(child: _StampPop(text: _stamp! ? M3LaPatrolLines.stampBad : M3LaPatrolLines.stampOk, bad: _stamp!, quiet: quiet)),
        ),
      // Tap an LA or its earth lead: he points at it.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3LaPatrolLines.sceneLabel,
          child: GestureDetector(key: _sceneKey, behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d, geo)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3LaPatrolZapPainter(from: zapFrom!, to: touching ? hand : zapFrom + const Offset(0, 40), v: v)),
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

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    // While he is in, his deck (beat 2) replaces the action deck.
    final deckUp = reasonOpen || coworkerChoiceUp || (_actOpen && !coworkerOpen);
    final looking = playing && _canLook;
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
              labels: M3LaPatrolLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: looking,
            hintKey: _run.index,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (looking)
                Positioned(
                  key: const ValueKey('hud-ok'),
                  left: 12,
                  right: 96,
                  bottom: pad.bottom + 12,
                  child: DoBigButton(key: _okKey, label: M3LaPatrolLines.allOk, filled: false, onDark: true, onTapUp: (d) => unawaited(_spot(null, d.globalPosition))),
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
                        : _actOpen && !coworkerOpen
                            ? ChoiceDeck(
                                key: ValueKey('act-deck-${_run.index}'),
                                options: _actOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: {?_actWrong},
                                picked: _actPicked,
                                onPick: (o, at) => unawaited(_pickAct(o, at)),
                              )
                            : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
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
                  line: M3LaPatrolLines.intro,
                  alarm: 'sounds/learn/thunder_far.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _clock.start();
                    _startRound();
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

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.bad, required this.quiet});
  final String text;
  final bool bad;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final col = bad ? SlmColors.danger : SlmColors.success;
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
