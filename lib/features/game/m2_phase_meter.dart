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
import 'm2_phase_meter_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm2_phase_meter_world.dart' show PmCables, PmGeo, PmMeter, PmPhase, PmReading;

// Lesson 2.8 "ফেজ সিকোয়েন্স মিটার: সঠিক ঘূর্ণন", কাজ 1 "ঘূর্ণন পড়ুন"
// (Module 2). Three pump houses a play; at each a new three-phase pump motor
// (a new connection, or after a big repair) waits to be started, and the
// trainee checks the phase sequence first (lesson point 1 daily check). Hands
// on, the lesson's four steps (point 3): PPE (the insulated gloves) · check
// the meter's probes and leads (a damaged one: take another meter) · make
// sure the circuit is live (the main switch ON) · clip the meter's R, Y, B
// leads to the R, Y, B phases (the painted tags; the incoming cable colours
// may not follow the rule — pro tip 1) · read the indicator: the disc turning
// clockwise or the FWD LED = right (R-Y-B); anticlockwise or REV = reversed
// (R-B-Y) (point 2) · call it. Reversed: swap any two phases (Y and B; done
// with the main switch OFF), the meter now reads right, the motor is started.
//
// Deadly: clipping a lead onto live terminals bare-handed (point 2 safety tip:
// a live-line test instrument — full PPE, above all insulated gloves). Slips:
// bare-handed on a dead box, a damaged lead used, a good meter swapped for
// another (an over-call on the leads: the slip card, then the same pump goes
// on), a lead on the wrong phase, a call with no reading (circuit off or a
// lead missing), the reading misread (either way), and listening to the
// coworker (starting the motor untested — myth 1; any clip on any phase).
// Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m2_phase_meter_world.dart), corner guide, ◆ on the table → "কেন …?"
// (the reasons fit this meter and this reading; the wrong cards use the same
// words, so no word marks the right one) → the next pump by itself; the
// careless coworker once a play: "মোটর চালিয়ে দাও…" (myth 1) or "রং মিলিয়ে কী
// হবে…". He is due from the start of his pump and the clip and the call wait
// for him (holdForCoworker), so a fast play cannot skip him. His pushes have
// no recorded clip yet (silent, caption held); his exit line is recorded.
// Gesture hints (how, never what): a sweep over the tools, the switch, the
// meter's leads and the two calls; with a lead in hand a sweep over all three
// terminals; on the leads card a sweep over both buttons.

// ============================================================================
// Content
// ============================================================================

/// The job on the docket (both need the test: lesson point 1 daily check).
enum PmJob { newConnection, afterRepair }

/// What the careless coworker pushes.
enum PmPush { skipTest, anyClip }

@immutable
class PmCase {
  const PmCase({
    required this.id,
    required this.fwd,
    required this.meter,
    required this.liveAtStart,
    required this.order,
    required this.cables,
    required this.job,
    this.badLead,
  });
  final String id;

  /// The supply's real sequence at the tags: R-Y-B (true) or R-B-Y.
  final bool fwd;
  final PmMeter meter;

  /// The main switch is ON when he arrives.
  final bool liveAtStart;

  /// The tags left to right in the box.
  final List<PmPhase> order;
  final PmCables cables;
  final PmJob job;

  /// A damaged lead on this meter.
  final PmPhase? badLead;
}

@immutable
class PmDeal {
  const PmDeal({required this.cases, required this.callAt, required this.push});
  final List<PmCase> cases;
  final int callAt;
  final PmPush push;
}

abstract final class PmLines {
  static const tasks = [ask];

  static const title = 'ঘূর্ণন পড়ুন';
  static const intro = 'নতুন পাম্পের থ্রি-ফেজ লাইন! মোটর চালানোর আগে মিটারে ফেজের ক্রম পড়ুন।';
  static const rounds = ['ক', 'খ', 'গ'];
  static const ask = 'মিটার লাগিয়ে ক্রম পড়ুন — ঠিক, না উল্টো?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (buttons, the docket, the inspection card).
  static const sceneLabel = 'পাম্প ঘর';
  static const gloves = 'গ্লাভস';
  static const inspect = 'লিড দেখুন';
  static const leadsHead = 'মিটারের লিড';
  static const leadsOk = 'ঠিক আছে';
  static const leadsSwap = 'অন্য মিটার নিন';
  static const fwd = 'ঠিক · R-Y-B';
  static const rev = 'উল্টো · R-B-Y';
  static const docket = 'ডকেট';
  static String jobBn(PmJob j) => j == PmJob.newConnection ? 'নতুন থ্রি-ফেজ কানেকশন' : 'মোটর মেরামতের পর';

  static const stampFwd = 'ক্রম ঠিক';
  static const stampRev = 'ক্রম উল্টো';
  static const stampSwap = 'Y আর B বদল';
  static const stampRun = 'মোটর চালু';

  /// The fix after a reversed reading (the swap is done with the switch OFF).
  static const fixLine = 'মেইন সুইচ বন্ধ করে Y আর B বদলানো হলো — এবার মিটার দেখুন।';
  static const runLine = 'ক্রম ঠিক — এবার মোটর চালু।';
  static const swapped = 'অন্য মিটার নিলেন — এর লিড ভালো।';

  /// After a slip that leaves the pump open (a good meter swapped).
  static const goOn = 'এবার এই মিটার দিয়েই কাজ চালিয়ে যান।';

  // The reasons (lesson 2.8): the right ones fit this meter and this
  // reading; the wrong ones are the lesson's myths and field guesses (the
  // colours, "run it and see", a cyclic shift) — never a true rule marked
  // wrong. Every card 36–45 letters, so none stands out by its length.
  static const whyFwdQ = 'কেন ক্রম ঠিক বললেন?';
  static const whyRevQ = 'কেন ক্রম উল্টো বললেন?';
  static const fwdDisc = 'ডিস্ক ঘড়ির কাঁটার দিকে ঘুরছে, তাই ক্রম R-Y-B';
  static const fwdDigital = 'মিটারে FWD জ্বলছে, তাই ফেজের ক্রম ঠিক R-Y-B';
  static const fwdMatched = 'R-এ R, Y-তে Y, B-তে B লাগিয়ে ঠিক ক্রম পেলাম';
  static const revDisc = 'ডিস্ক উল্টো দিকে ঘুরছে, তাই ক্রম উল্টো R-B-Y';
  static const revDigital = 'মিটারে REV জ্বলছে, তাই ফেজের ক্রম উল্টো R-B-Y';
  static const revSwap = ['যেকোনো দুটো ফেজ বদলালেই ক্রম ঠিক হয়ে যাবে', 'উল্টো ক্রমে মোটর উল্টো ঘুরবে, পাম্প নষ্ট হবে'];

  /// Wrong reasons for a "right" call: the lesson's myths and guesses (they
  /// name R-Y-B as the right cards do).
  static const fwdMyths = [
    'তারের রং লাল-হলুদ-নীল, তাই ক্রম ঠিক R-Y-B',
    'ছোট মোটর, উল্টো ঘুরলে পরে তার বদলে নেব',
    'আগের বার এই লাইনে R-Y-B ছিল, এবারও তাই হবে',
    'তিনটে বাতি জ্বললেই ক্রম ঠিক R-Y-B ধরা যায়',
    'মোটর একবার চালিয়ে দেখলেই সব বোঝা যেত',
    'নতুন লাইনে ফেজের ক্রম সবসময় R-Y-B-ই থাকে',
  ];

  /// Wrong reasons for a "reversed" call.
  static const revMyths = [
    'তিনটে ফেজই একঘর করে সরালে ক্রম ঠিক হবে',
    'তারের রং মিলছে না, তাই ক্রমটা উল্টো R-B-Y',
    'উল্টো ক্রমে মোটরের কিছু হয় না, শুধু ধীরে চলে',
    'মিটারটা পুরনো, তাই মাঝে মাঝে উল্টো দেখায়',
    'একবার মোটর চালিয়ে দেখি সত্যিই উল্টো কি না',
    'আগের বার এই লাইনে R-B-Y ছিল, এবারও তাই হবে',
  ];

  /// A misreading of this meter's own indicator (so the indicator's word —
  /// ডিস্ক, FWD, REV — is never only on the right card).
  static const fwdDiscMyth = 'ডিস্ক যেদিকেই ঘুরুক, ঘুরলেই ক্রম ঠিক R-Y-B';
  static const fwdDigitalMyth = 'মিটারে FWD বা REV যা-ই জ্বলুক, ক্রম R-Y-B-ই';
  static const revDiscMyth = 'ডিস্ক ধীরে ঘুরছে, তাই ফেজের ক্রম উল্টো R-B-Y';
  static const revDigitalMyth = 'মিটারে REV জ্বলছে মানে কোনো একটা ফেজ নেই';
  static String meterMyth(PmCase c) =>
      c.meter == PmMeter.disc ? (c.fwd ? fwdDiscMyth : revDiscMyth) : (c.fwd ? fwdDigitalMyth : revDigitalMyth);

  static List<String> whyRight(PmCase c) => c.fwd
      ? [c.meter == PmMeter.disc ? fwdDisc : fwdDigital, fwdMatched]
      : [c.meter == PmMeter.disc ? revDisc : revDigital, ...revSwap];
  static List<String> whyWrong(PmCase c) => [meterMyth(c), ...(c.fwd ? fwdMyths : revMyths)];

  /// Words that could mark a card (the indicator, the sequence, "reversed").
  static const tells = ['ডিস্ক', 'FWD', 'REV', 'R-Y-B', 'R-B-Y', 'মিটারে', 'উল্টো'];

  /// The reason deck: one right card, this meter's misreading, and the field
  /// myth that shares most of the right card's [tells] — so no word appears
  /// only on the right card.
  static List<ChoiceOption> dealWhy(PmCase c, math.Random rng) {
    final right = whyRight(c);
    final pick = right[rng.nextInt(right.length)];
    final mine = meterMyth(c);
    final missing = [
      for (final t in tells)
        if (pick.contains(t) && !mine.contains(t)) t,
    ];
    int cover(String x) => missing.where(x.contains).length;
    final rest = [...(c.fwd ? fwdMyths : revMyths)]..shuffle(rng);
    final best = rest.map(cover).fold<int>(0, math.max);
    final other = rest.firstWhere((x) => cover(x) == best);
    return dealChoices([pick], [mine, other], rng);
  }

  /// The careless coworker (his exit line is recorded; his pushes have no
  /// clip yet: silent, the caption held for a reading time).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const skipLine = 'মিটার-টিটার লাগবে না! মোটর চালিয়ে দাও, উল্টো ঘুরলে তার বদলে দেবে।';
  static const clipLine = 'রং মিলিয়ে কী হবে? যেকোনো ক্লিপ যেকোনো তারে লাগাও!';
  static const skipScript = CoworkerScript(
    line: skipLine,
    exitLine: coworkerExit,
    right: ['না, আগে মিটারে ক্রম দেখে তবে চালাব', 'না, এক সেকেন্ড উল্টো ঘুরলেও পাম্প নষ্ট', 'না, নতুন কানেকশনে পরীক্ষা বাধ্যতামূলক'],
    wrong: ['ঠিক, চালিয়েই দেখি কোন দিকে ঘোরে', 'আচ্ছা, উল্টো ঘুরলে পরে তার বদলাব', 'ছোট মোটর তো, এর পরীক্ষা লাগবে না', 'মিটার লাগাতে দেরি হবে, চালিয়ে দিই', 'সবাই তো চালিয়েই দেখে নেয়, চালাই'],
    asks: ['ও বলছে মিটার ছাড়াই চালাতে। আপনি কী করবেন?', 'আগে পরীক্ষা, না আগে মোটর?', 'ওর কথা শুনবেন, না মিটারের?'],
  );
  static const clipScript = CoworkerScript(
    line: clipLine,
    exitLine: coworkerExit,
    right: ['না, R-এ R, Y-তে Y, B-তে B লাগাব', 'না, ভুল ফেজে ক্লিপ দিলে রিডিং ভুল', 'না, ঠিক ফেজে ঠিক ক্লিপ, তবেই রিডিং'],
    wrong: ['ঠিক, যেকোনো ক্লিপ লাগালেই চলবে', 'আচ্ছা, রং না মিলিয়েই লাগিয়ে দিই', 'মিটার তো নিজেই সবকিছু বুঝে নেবে', 'যেভাবে হাতে আসে সেভাবেই লাগিয়ে দিই', 'এক তার আর এক তার, সবই তো একই কথা'],
    asks: ['ও বলছে যেকোনো ক্লিপ লাগাতে। আপনি কী করবেন?', 'ক্লিপ কোথায় লাগাবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript script(PmPush p) => p == PmPush.skipTest ? skipScript : clipScript;

  static const allSet = 'ঘূর্ণন পড়তে শিখে গেছেন — গ্লাভস, লিড, ঠিক ফেজে ক্লিপ, তারপর রিডিং।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — গ্লাভস, লিড, R-Y-B ক্লিপ, তারপর মিটার পড়ুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtFwd = 'ঠিক ক্রম মিটারে নিশ্চিত';
  static const caughtRev = 'উল্টো ক্রম ধরেছেন';
  static const caughtSwap = 'দুটো ফেজ বদলে ক্রম ঠিক';
  static const caughtLead = 'খারাপ লিড বাদ দিয়েছেন';
  static const caughtLive = 'আগে সার্কিট চালু করেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class PmMistakes {
  static const _dir = 'assets/game/art/m2_phase_meter';
  static const _gloves = '$_dir/no_gloves.svg';
  static const _lead = '$_dir/bad_lead.svg';
  static const _clip = '$_dir/wrong_clip.svg';
  static const _read = '$_dir/misread.svg';
  static const _live = '$_dir/not_live.svg';
  static const _untested = '$_dir/untested.svg';

  static const bareLive = DoMistake(
    key: '2.8/phase/bare-hand-live',
    textBn: 'লাইভ টার্মিনালে খালি হাতে ক্লিপ! ফেজ সিকোয়েন্স মিটার লাইভ লাইনের যন্ত্র — লাগানোর আগে পুরো PPE, বিশেষ করে ইনসুলেটেড গ্লাভস।',
    art: _gloves,
    deadly: true,
    lessonPoint: 1,
  );
  static const bareDead = DoMistake(
    key: '2.8/phase/bare-hand',
    textBn: 'গ্লাভস ছাড়াই ক্লিপ ধরলেন। এটা লাইভ লাইনের পরীক্ষা — সুইচ চালু হলেই টার্মিনাল লাইভ। আগে ইনসুলেটেড গ্লাভস।',
    art: _gloves,
    lessonPoint: 1,
  );
  static const badLead = DoMistake(
    key: '2.8/phase/damaged-lead',
    textBn: 'লিডের ইনসুলেশন ফাটা, ভেতরের তামা দেখা যাচ্ছে। ব্যবহারের আগে প্রোব আর তার দেখুন — ক্ষতি থাকলে সেই মিটার ব্যবহার করবেন না।',
    art: _lead,
    lessonPoint: 2,
  );
  static const wrongClip = DoMistake(
    key: '2.8/phase/wrong-clip',
    textBn: 'ক্লিপ ভুল ফেজে। মিটারের R, Y, B ক্লিপ ঠিক R, Y, B ফেজে লাগান — নইলে মিটার যা দেখায় তা এই লাইনের ক্রম নয়।',
    art: _clip,
    lessonPoint: 2,
  );
  static const missedReverse = DoMistake(
    key: '2.8/phase/missed-reverse',
    textBn: 'মিটার উল্টো ক্রম (R-B-Y) দেখাচ্ছিল। ডিস্ক উল্টো দিকে ঘুরলে বা REV জ্বললে ক্রম ভুল — মোটর উল্টো ঘুরবে, পাম্প নষ্ট হতে পারে।',
    art: _read,
    lessonPoint: 1,
  );
  static const falseReverse = DoMistake(
    key: '2.8/phase/false-reverse',
    textBn: 'মিটার ঠিক ক্রম (R-Y-B) দেখাচ্ছিল। ডিস্ক ঘড়ির কাঁটার দিকে ঘুরলে বা FWD জ্বললে ক্রম ঠিক — তার বদলালে উল্টো হয়ে যেত।',
    art: _read,
    lessonPoint: 1,
  );
  static const blank = DoMistake(
    key: '2.8/phase/no-reading',
    textBn: 'মিটারে কোনো রিডিং নেই। আগে নিশ্চিত করুন সার্কিট চালু (লাইভ), তিনটে ক্লিপই লাগান — তারপর ইন্ডিকেটর দেখুন।',
    art: _live,
    lessonPoint: 2,
  );
  static const untested = DoMistake(
    key: '2.8/phase/untested',
    textBn: 'পরীক্ষা ছাড়াই মোটর চালালেন। নতুন থ্রি-ফেজ কানেকশন বা বড় মেরামতের পর ফেজ সিকোয়েন্স পরীক্ষা বাধ্যতামূলক — এক সেকেন্ড উল্টো ঘুরলেও পাম্প চিরতরে নষ্ট হতে পারে।',
    art: _untested,
    lessonPoint: 0,
  );
  static const anyClip = DoMistake(
    key: '2.8/phase/any-clip',
    textBn: 'ওর কথায় যেকোনো ক্লিপ যেকোনো ফেজে! R-এ R, Y-তে Y, B-তে B — নইলে মিটারের রিডিং এই লাইনের ক্রম বলে না।',
    art: _clip,
    lessonPoint: 2,
  );

  /// A good meter put aside (the leads card read wrong the other way).
  static const goodLeadSwapped = DoMistake(
    key: '2.8/phase/good-lead-swapped',
    textBn: 'এই মিটারের লিড ভালো ছিল — ইনসুলেশন ফাটা নয়, তামা দেখা যায় না। ব্যবহারের আগে প্রোব আর তার মন দিয়ে দেখুন; ক্ষতি থাকলে তবেই মিটার বদলান।',
    art: _lead,
    lessonPoint: 2,
  );

  static const all = [bareLive, bareDead, badLead, goodLeadSwapped, wrongClip, missedReverse, falseReverse, blank, untested, anyClip];
}

/// Three pump houses: at least one right (R-Y-B) and one reversed (R-B-Y)
/// supply (always calling one way never wins), both meter types, a damaged
/// lead in about 3 plays in 5, the main switch found OFF in about 3 in 5,
/// the tags sometimes not in R-Y-B order, the incoming cables in the
/// standard colours, all black or mixed (pro tip 1). The coworker comes once.
PmDeal dealPhase(math.Random rng) {
  final fwds = [true, false, rng.nextBool()]..shuffle(rng);
  final meters = [PmMeter.disc, PmMeter.digital, rng.nextBool() ? PmMeter.disc : PmMeter.digital]..shuffle(rng);
  final bad = rng.nextInt(5) < 3 ? rng.nextInt(3) : -1;
  final off = rng.nextInt(5) < 3 ? rng.nextInt(3) : -1;
  final cases = <PmCase>[
    for (var i = 0; i < 3; i++)
      PmCase(
        id: 'p$i',
        fwd: fwds[i],
        meter: meters[i],
        liveAtStart: i != off,
        order: rng.nextInt(5) < 2 ? ([...PmPhase.values]..shuffle(rng)) : PmPhase.values,
        cables: PmCables.values[rng.nextInt(3)],
        job: rng.nextBool() ? PmJob.newConnection : PmJob.afterRepair,
        badLead: i == bad ? PmPhase.values[rng.nextInt(3)] : null,
      ),
  ];
  return PmDeal(cases: cases, callAt: rng.nextInt(3), push: rng.nextBool() ? PmPush.skipTest : PmPush.anyClip);
}

/// What a set of clips reads on a supply: the truth when the leads are on
/// their own phases (or turned round all three — a cyclic shift keeps the
/// order), reversed when two are crossed.
PmReading pmRead({required bool live, required Map<PmPhase, PmPhase> clips, required bool fwd}) {
  if (!live || clips.length < 3 || clips.values.toSet().length < 3) return PmReading.blank;
  final p = [for (final l in PmPhase.values) clips[l]!.index];
  var inv = 0;
  for (var i = 0; i < 3; i++) {
    for (var j = i + 1; j < 3; j++) {
      if (p[i] > p[j]) inv++;
    }
  }
  final shows = inv.isEven ? fwd : !fwd;
  return shows ? PmReading.fwd : PmReading.rev;
}

/// The play state (pure logic).
class PmRun {
  PmRun(this.deal) {
    _reset();
  }
  final PmDeal deal;
  int index = 0;
  var gloves = false;
  var inspected = false;

  /// Took another meter (its leads are good).
  var spare = false;
  var live = true;

  /// The reversed supply was put right (Y and B swapped).
  var fixed = false;
  final Map<PmPhase, PmPhase> clips = {};
  bool shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  PmCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// The damaged lead on the meter in hand now.
  PmPhase? get badNow => spare ? null : current.badLead;

  /// Every lead on its own phase.
  bool get matched => clips.length == 3 && PmPhase.values.every((l) => clips[l] == l);

  PmReading get reading => pmRead(live: live, clips: clips, fwd: fixed || current.fwd);

  /// Checked the leads before clipping (+5).
  bool get thorough => inspected;

  void _reset() {
    gloves = false;
    inspected = false;
    spare = false;
    fixed = false;
    clips.clear();
    shown = false;
    if (!done) live = current.liveAtStart;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  bool get _open => !ended && !shown;

  void putGloves() {
    if (_open) gloves = true;
  }

  /// Looks at the leads; true when one is damaged.
  bool inspect() {
    if (_open) inspected = true;
    return badNow != null;
  }

  /// Another meter (all leads back on it). Putting aside a meter whose leads
  /// were good is an over-call: a slip, but the pump goes on (returned).
  DoMistake? takeSpare() {
    if (!_open) return null;
    final needless = badNow == null;
    if (!needless) _tag(PmLines.caughtLead);
    spare = true;
    clips.clear();
    if (!needless) return null;
    slips++;
    return PmMistakes.goodLeadSwapped;
  }

  void toggleSwitch() {
    if (!_open) return;
    live = !live;
    if (live && !current.liveAtStart) _tag(PmLines.caughtLive);
  }

  /// Clips [lead] onto the terminal tagged [tag] (a lead already there goes
  /// back to the meter). Returns the mistake, if any.
  DoMistake? clip(PmPhase lead, PmPhase tag) {
    if (!_open) return null;
    if (!gloves) {
      shown = true;
      if (live) return deadly = PmMistakes.bareLive;
      slips++;
      return PmMistakes.bareDead;
    }
    if (badNow != null) {
      // A meter with a cracked lead: using it at all is the slip.
      shown = true;
      slips++;
      return PmMistakes.badLead;
    }
    clips.removeWhere((l, t) => t == tag);
    clips[lead] = tag;
    return null;
  }

  void unclip(PmPhase lead) {
    if (_open) clips.remove(lead);
  }

  /// The call: the supply reads right ([fwd]) or reversed.
  DoMistake? decide({required bool fwd}) {
    if (!_open) return null;
    shown = true;
    if (reading == PmReading.blank) {
      slips++;
      return PmMistakes.blank;
    }
    if (!matched) {
      slips++;
      return PmMistakes.wrongClip;
    }
    if (fwd != current.fwd) {
      slips++;
      return fwd ? PmMistakes.missedReverse : PmMistakes.falseReverse;
    }
    _tag(fwd ? PmLines.caughtFwd : PmLines.caughtRev);
    return null;
  }

  /// Listened to the coworker.
  DoMistake? listen(PmPush p) {
    if (!_open) return null;
    shown = true;
    slips++;
    return p == PmPush.skipTest ? PmMistakes.untested : PmMistakes.anyClip;
  }

  /// The reversed supply put right: Y and B swapped (with the switch OFF),
  /// the switch back ON.
  void fix() {
    if (ended || current.fwd) return;
    fixed = true;
    live = true;
    _tag(PmLines.caughtSwap);
  }

  void next() {
    index++;
    _reset();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// A thorough pump house (ms; ~1500 human reaction per action):
///   gloves 1500 · leads card open, look, close 4000 · switch (3 in 5) 900
///   three clips (6 taps) 7500 · read 2000 · call 1500
///   reason: praise ~1500 + 650 + deck 910 + read 2000 + pick 1500
///     + "এই তো আসল কথা" ~1200 + 450                          8210
///   the motor run (and the fix for a reversed one ~1 in 2)  2600
///   = 28210 × 3                                            84630
/// + the coworker once: his line ~3500 + deck 910 + pick 3500 + 420  8330
/// ≈ 92960 ms; 85 % ≈ 79000 → 80 s.
const kPmQuickMs = 80000;

@immutable
class M2PhaseMeterPack {
  const M2PhaseMeterPack({required this.id, required this.titleBn, this.quickMs = kPmQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2PhaseMeterPacks = {
  'do_2_8_a': M2PhaseMeterPack(id: 'do_2_8_a', titleBn: PmLines.title),
};

/// Tap areas (design px).
Rect pmTerminalRect(PmGeo g, int slot) {
  final t = g.terminal(slot);
  return Rect.fromLTRB(t.dx - 28, g.tagAt(slot).dy - 16, t.dx + 28, t.dy + 22);
}

Rect pmParkRect(PmGeo g, PmPhase lead) => Rect.fromCenter(center: g.parked(lead.index), width: 42, height: 44);

// ============================================================================
// Page
// ============================================================================

class M2PhaseMeterPage extends StatefulWidget {
  const M2PhaseMeterPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2PhaseMeterPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2PhaseMeterPage> createState() => _M2PhaseMeterPageState();
}

class _M2PhaseMeterPageState extends State<M2PhaseMeterPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PmRunPage(
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

class _PmRunPage extends ConsumerStatefulWidget {
  const _PmRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2PhaseMeterPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PmRunPage> createState() => _PmRunPageState();
}

class _PmRunPageState extends ConsumerState<_PmRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final PmRun _run = PmRun(dealPhase(widget.rng));
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

  /// The lead in his hand (to clip on).
  PmPhase? _selected;

  /// The leads card is open.
  var _leads = false;

  /// The motor: 0 still, 1 the right way, −1 backwards.
  int _motor = 0;
  String? _stamp;
  int _stamps = 0;

  /// The slip card up now leaves the pump open (a good meter swapped).
  var _cardResume = false;

  /// The two tools' order on the bench (dealt per pump: never the lesson's
  /// order every time).
  var _toolsFlip = false;

  var _freeze = false;
  Offset? _arcAt;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how, never what).
  final _hints = IdleHintController();
  final _sceneKey = GlobalKey();
  PmGeo? _lastGeo;
  final _glovesKey = GlobalKey();
  final _inspectKey = GlobalKey();
  final _fwdKey = GlobalKey();
  final _revKey = GlobalKey();
  final _leadsOkKey = GlobalKey();
  final _leadsSwapKey = GlobalKey();

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  /// This pump is the one he is dealt on.
  bool get _hisPump => _run.index == _run.deal.callAt && !coworkerDone;

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

  Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: _quiet ? (ms ~/ 3) : ms));

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.shown && !_leads;

  // --- a pump house ------------------------------------------------------------------
  void _startMoment() {
    setState(() {
      _selected = null;
      _motor = 0;
      _stamp = null;
      _toolsFlip = widget.rng.nextBool();
      _wake++;
    });
    // He is due from the start of his pump: the clip and the call wait for
    // him (holdForCoworker), so a fast play cannot skip him.
    if (_hisPump) scheduleCoworker();
    unawaited(_sayChain([PmLines.ask]));
  }

  // --- hands on ----------------------------------------------------------------------
  void _putGloves() {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.35);
    _run.putGloves();
    setState(() => _wake++);
  }

  void _openLeads() {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.45);
    _run.inspect();
    setState(() => _leads = true);
  }

  void _closeLeads({required bool swap, Offset? at}) {
    if (!_leads || _ended || tableBusy) return;
    _cue('sounds/intro/click.ogg', volume: 0.4);
    final m = swap ? _run.takeSpare() : null;
    setState(() {
      _leads = false;
      if (swap) _selected = null;
      _wake++;
    });
    if (m != null) {
      // A good meter put aside: the slip, then the same pump goes on.
      final size = MediaQuery.sizeOf(context);
      unawaited(_levelDelta(-10, at ?? Offset(size.width / 2, size.height / 2), mood: GuideMood.warn));
      unawaited(_slip(m, resume: true));
      return;
    }
    if (swap) unawaited(_sayChain([PmLines.swapped]));
  }

  void _tapScene(Offset p, PmGeo geo) {
    if (!_canPlay) return;
    final order = _run.current.order;
    // The main switch.
    if (geo.mainSwitch.inflate(6).contains(p)) {
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
      _run.toggleSwitch();
      setState(() => _wake++);
      return;
    }
    // A lead resting at the meter: pick it up (or put it down).
    for (final lead in PmPhase.values) {
      if (!_run.clips.containsKey(lead) && pmParkRect(geo, lead).contains(p)) {
        HapticFeedback.selectionClick();
        _cue('sounds/intro/tick.ogg', volume: 0.5);
        setState(() {
          _selected = _selected == lead ? null : lead;
          _wake++;
        });
        return;
      }
    }
    // A terminal.
    for (var slot = 0; slot < 3; slot++) {
      if (!pmTerminalRect(geo, slot).contains(p)) continue;
      final tag = order[slot];
      final sel = _selected;
      if (sel != null) {
        // A clip is decisive: on his pump he cuts in first (the lead stays in
        // hand; tap the terminal again after him).
        if (holdForCoworker()) return;
        _tryClip(sel, tag, geo.terminal(slot));
        return;
      }
      final on = _run.clips.entries.where((e) => e.value == tag).map((e) => e.key).firstOrNull;
      if (on != null) {
        // Take it off and hold it (to clip it elsewhere).
        HapticFeedback.selectionClick();
        _cue('sounds/intro/click.ogg', volume: 0.5);
        _run.unclip(on);
        setState(() {
          _selected = on;
          _wake++;
        });
        return;
      }
      _hints.missTap();
      return;
    }
    // The meter: look again (the disc turns a few seconds more).
    if (geo.meter.contains(p)) {
      HapticFeedback.selectionClick();
      setState(() => _wake++);
      return;
    }
    // Nothing there.
    _hints.missTap();
  }

  void _tryClip(PmPhase lead, PmPhase tag, Offset at) {
    final m = _run.clip(lead, tag);
    if (m == null) {
      HapticFeedback.lightImpact();
      _cue('sounds/learn/tag_slap.ogg', volume: 0.55);
      setState(() {
        _selected = null;
        _wake++;
      });
      if (_run.reading != PmReading.blank) _cue('sounds/intro/tick.ogg', volume: 0.6);
      return;
    }
    setState(() => _selected = null);
    if (m.deadly) {
      unawaited(_deadly(m, at));
      return;
    }
    unawaited(_levelDelta(-10, at, mood: GuideMood.warn));
    unawaited(_slip(m));
  }

  // --- the call ------------------------------------------------------------------------
  Future<void> _decide(bool fwd, Offset origin) async {
    if (!_canPlay) return;
    if (holdForCoworker()) return;
    _hush();
    final m = _run.decide(fwd: fwd);
    HapticFeedback.mediumImpact();
    if (m == null) {
      _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
      _cue('sounds/quiz_right.ogg', volume: 0.6);
      _showStamp(fwd ? PmLines.stampFwd : PmLines.stampRev);
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final c = _run.current;
      final idx = _run.index;
      unawaited(askReason(
        deal: () => PmLines.dealWhy(c, widget.rng),
        question: fwd ? PmLines.whyFwdQ : PmLines.whyRevQ,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    // A wrong "right" call: the motor is started — backwards.
    if (m == PmMistakes.missedReverse) setState(() => _motor = -1);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _showStamp(String s) => setState(() {
        _stamp = s;
        _stamps++;
        _wake++;
      });

  /// After the reason: a reversed supply is put right (switch OFF, Y and B swapped,
  /// switch ON — the meter now reads right), then the motor is started.
  Future<void> _runMotor() async {
    final idx = _run.index;
    bool still() => mounted && !_ended && _run.index == idx;
    if (!_run.current.fwd) {
      setState(() => _run.live = false);
      _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
      _showStamp(PmLines.stampSwap);
      unawaited(_sayChain([PmLines.fixLine]));
      await _wait(1400);
      if (!still()) return;
      _run.fix();
      _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
      setState(() => _wake++);
      await _wait(1600);
      if (!still()) return;
    }
    _cue('sounds/quiz_right.ogg', volume: 0.5);
    _showStamp(PmLines.stampRun);
    setState(() => _motor = 1);
    unawaited(_sayChain([PmLines.runLine], mood: GuideMood.glad));
    await _wait(1800);
    if (!still()) return;
    _next();
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startMoment();
  }

  // --- the shared success beat (ReasonTable) -------------------------------------
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
  void onReasonPaid() => unawaited(_runMotor());

  // --- the shared pressure moment (CoworkerMoment) --------------------------------
  @override
  CoworkerScript get coworkerScript => PmLines.script(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.shown) return null;
    // His push must fit the moment: "any clip on any wire" only before the
    // first clip, "no meter, start it" only before the meter is on. (The
    // clip and the call wait for him, so neither has happened yet.)
    if (_run.deal.push == PmPush.anyClip ? _run.clips.isNotEmpty : _run.clips.length == 3) return null;
    if (_intro || _busy || _card != null || tableBusy || _leads) return false;
    // "Any clip": he cuts in as the trainee goes to clip (a lead in hand, or
    // the clip held for him).
    if (_run.deal.push == PmPush.anyClip) return _selected != null;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    setState(() => _wake++);
    if (!held) {
      final m = _run.listen(_run.deal.push);
      if (m == null) return;
      // Listened: the motor started untested (it turns whichever way the
      // supply is), or any clip on any phase.
      if (m == PmMistakes.untested) setState(() => _motor = _run.current.fwd ? 1 : -1);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(PmLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    unawaited(_sayChain([PmLines.ask]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? PmLines.tapWhy[_nudgeN++ % PmLines.tapWhy.length]
            : _nudge.next(PmLines.ask);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes -------------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  /// A slip: its card, then the next pump — or, with [resume], the same pump
  /// goes on (a good meter swapped).
  Future<void> _slip(DoMistake m, {bool resume = false}) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _cardResume = resume;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('phase/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Bare hand on a live terminal: the room freezes grey and the arc at the
  /// terminal plays in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m, Offset at) async {
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
      _arcAt = at;
      _leads = false;
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
    final speak = await SpokenOnce.first('phase/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? PmLines.deadlyWord : PmLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final resume = _cardResume;
        setState(() {
          _card = null;
          _cardResume = false;
          _wake++;
        });
        if (resume) {
          unawaited(_sayChain([PmLines.goOn, PmLines.ask]));
        } else {
          _next();
        }
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
    await _say(!_run.passed ? PmLines.fail : (_quickBonus ? PmLines.quick : PmLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- the scene -------------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerHeld || coworkerOpen) return LinemanMode.worried;
    if (_motor == 1) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  /// The trainee: standing at the panel, under the terminal box.
  static Rect traineeBox(PmGeo g) {
    final h = 236.0 * g.s;
    return Rect.fromLTWH(170, g.floorY - h + 4, h / 2, h);
  }

  PmView _view() {
    final c = _run.current;
    return PmView(
      order: c.order,
      cables: c.cables,
      meter: c.meter,
      live: _run.live,
      clips: Map.of(_run.clips),
      selected: _selected,
      reading: _run.reading,
      badLead: _run.badNow,
      motor: _motor,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _lastGeo = PmGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final tb = traineeBox(geo);
    final hand = tb.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final view = _view();
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: AwakeClock(
            wake: _wake,
            quiet: quiet,
            builder: (context, t) => Stack(
              children: [
                Positioned.fill(
                  key: const ValueKey('room'),
                  child: RepaintBoundary(child: CustomPaint(painter: PmWorldPainter(geo: geo, view: view, t: t))),
                ),
                Positioned.fromRect(
                  key: const ValueKey('trainee'),
                  rect: tb,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
                if (_run.gloves && _mode == LinemanMode.hold)
                  Positioned(
                    key: const ValueKey('gloves'),
                    left: hand.dx - 10,
                    top: hand.dy - 10,
                    width: 20,
                    height: 20,
                    child: const IgnorePointer(child: CustomPaint(painter: _GlovePainter())),
                  ),
              ],
            ),
          ),
        ),
      ),
      if (_stamp != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-$_stamps'),
          left: geo.box.left + 10,
          width: 160,
          top: geo.box.bottom + 8,
          child: IgnorePointer(child: _StampPop(text: _stamp!, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: PmLines.sceneLabel,
          child: GestureDetector(key: _sceneKey, behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      if (_freeze && _arcAt != null)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: PmArcPainter(at: _arcAt!, v: v)),
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

  // --- gesture hints (how, never what) ---------------------------------------------
  /// A scene rect (design px) on the screen (through the frame's fit).
  Rect? _sceneRect(Rect r) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return MatrixUtils.transformRect(box.getTransformTo(null), r);
  }

  /// Leads card: a sweep over both buttons. A lead in hand: a sweep over all
  /// three terminals (never one). Otherwise a sweep over everything he can
  /// touch — the switch, the meter's leads, the two tools, the two calls —
  /// in screen order (top to bottom), pressing none.
  HintSpec? _hint() {
    if (_leads) return HintSpec.sweepOver([_leadsOkKey, _leadsSwapKey]);
    final geo = _lastGeo;
    if (geo == null) return null;
    if (_selected != null) {
      final rects = [for (var s = 0; s < 3; s++) ?_sceneRect(pmTerminalRect(geo, s))];
      return rects.length < 3 ? null : HintSpec.sweep(rects);
    }
    final rects = <Rect>[
      ?_sceneRect(geo.mainSwitch),
      for (final lead in PmPhase.values)
        if (!_run.clips.containsKey(lead)) ?_sceneRect(pmParkRect(geo, lead)),
      for (final k in [_glovesKey, _inspectKey, _fwdKey, _revKey]) ?HintSpec.globalRectOf(k),
    ]..sort((a, b) => a.top != b.top ? a.top.compareTo(b.top) : a.left.compareTo(b.left));
    return rects.length < 2 ? null : HintSpec.sweep(rects);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null && !_leads && !coworkerHeld;
    final leadsUp = _leads && playing && _card == null && !_ended;
    final c = _run.current;
    final tools = [
      _ToolButton(key: _glovesKey, icon: Icons.back_hand_rounded, label: PmLines.gloves, on: _run.gloves, enabled: _canPlay, onTap: _putGloves),
      _ToolButton(key: _inspectKey, icon: Icons.search_rounded, label: PmLines.inspect, on: _run.inspected, enabled: _canPlay, onTap: _openLeads),
    ];
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
              labels: PmLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: ((handsOn && _canPlay) || leadsUp) && !coworkerOnScreen,
            hintKey: '${_run.index}-${_selected != null}-$_leads-${_run.clips.length}',
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  right: 10,
                  top: pad.top + 92,
                  child: IgnorePointer(child: _DocketChip(job: c.job)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 10,
                  bottom: pad.bottom + 72,
                  child: Row(
                    children: [
                      _toolsFlip ? tools[1] : tools[0],
                      const SizedBox(width: 6),
                      _toolsFlip ? tools[0] : tools[1],
                    ],
                  ),
                ),
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      // The same look for both calls (neither stands out).
                      Expanded(child: DoBigButton(key: _fwdKey, label: PmLines.fwd, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
                      const SizedBox(width: 10),
                      Expanded(child: DoBigButton(key: _revKey, label: PmLines.rev, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
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
              if (_leads && playing)
                _LeadsCard(
                  key: const ValueKey('leads'),
                  bad: _run.badNow,
                  quiet: quiet,
                  okKey: _leadsOkKey,
                  swapKey: _leadsSwapKey,
                  onOk: () => _closeLeads(swap: false),
                  onSwap: () => _closeLeads(swap: true),
                ),
              if (playing && _card == null && !_leads) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
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
                  line: PmLines.intro,
                  alarm: 'sounds/learn/spark.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _clock.start();
                    _startMoment();
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

/// An insulated rubber glove on his hand (drawn bigger than the hand so it
/// reads at the figure's size).
class _GlovePainter extends CustomPainter {
  const _GlovePainter();

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..shader = const LinearGradient(colors: [Color(0xFFE5533A), Color(0xFF9E2414)]).createShader(Offset.zero & size);
    final edge = Paint()
      ..color = const Color(0xFF4A0E06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final cuff = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.24, 0, w * 0.52, h * 0.46), Radius.circular(w * 0.08));
    final mitt = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.34, w * 0.6, h * 0.62), Radius.circular(w * 0.28));
    final thumb = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.04, h * 0.42, w * 0.3, h * 0.2), Radius.circular(w * 0.1));
    for (final r in [cuff, thumb, mitt]) {
      c.drawRRect(r, fill);
      c.drawRRect(r, edge);
    }
  }

  @override
  bool shouldRepaint(_GlovePainter old) => false;
}

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.job});
  final PmJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(PmLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(PmLines.jobBn(job), style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit once used.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final bool enabled;
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
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
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

/// The meter's three leads up close: look, then keep it or take another.
class _LeadsCard extends StatelessWidget {
  const _LeadsCard({super.key, required this.bad, required this.quiet, required this.okKey, required this.swapKey, required this.onOk, required this.onSwap});
  final PmPhase? bad;
  final bool quiet;
  final GlobalKey okKey;
  final GlobalKey swapKey;
  final VoidCallback onOk;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    // Both choices look the same (neither is the suggested one).
    Widget button(Key key, String label, bool filled, VoidCallback onTap) => Expanded(
          key: key,
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: Material(
              color: filled ? SlmColors.gold700 : const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: filled ? null : Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.4),
                  ),
                  child: Text(label, textAlign: TextAlign.center, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ),
          ),
        );
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x99050A16),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.translate(offset: Offset(0, 60 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
            child: Container(
              width: 300,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF101A2B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2D3B52), width: 3),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(PmLines.leadsHead, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(color: const Color(0xFFD9D3C3), borderRadius: BorderRadius.circular(10)),
                    child: CustomPaint(painter: PmLeadsPainter(bad: bad), size: const Size(272, 150)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      button(okKey, PmLines.leadsOk, false, onOk),
                      const SizedBox(width: 10),
                      button(swapKey, PmLines.leadsSwap, false, onSwap),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.rotate(angle: -0.1, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xE6FFF8E7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SlmColors.success, width: 3),
          ),
          child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: SlmColors.success)),
        ),
      ),
    );
  }
}
