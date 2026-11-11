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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_phase_swap_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 2.8 "ফেজ সিকোয়েন্স মিটার: সঠিক ঘূর্ণন", কাজ 2 "উল্টো ঘুরছে পাম্প"
// (pack do_2_8_b, engineType m2_phase_swap). Three farm pump houses a play,
// each just after service work (a new three-phase connection, work on the
// transformer, a new service cable). Before the pump runs, the trainee
// tests the phase sequence at the outgoing terminals of the consumer's main
// switch, and where it is reversed he puts it right — safely.
//
// The lesson's rules, and only those:
//   • point 1: a reversed sequence (R-B-Y) turns a three-phase motor the
//     wrong way; test after every new three-phase connection or big repair
//     (and pro tip 2: after work on a transformer's HT/LT side);
//   • point 2: the meter is a live-line testing tool — full PPE, insulated
//     gloves above all; the disc turns clockwise for the right sequence (the
//     wrong way = wrong), the digital meter lights FWD or REV;
//   • point 3: probes on R, Y, B only — never touching each other or an
//     earthing point; R-Y-B = right; R-B-Y = swap any two phases;
//   • myth 1: one second of reverse running can ruin a pump — test first;
//   • pro tip 1: never trust the wire colours (they look R-Y-B on every
//     site here, reversed or not).
// From the module's safety rules (lesson 1.6 and the brief, NOT lesson 2.8's
// text — flagged in REGISTER.md): the swap is done only after the main switch
// is OFF, locked and tagged, and the terminals are proven dead with a tester;
// and after the swap the sequence is tested again before the pump starts.
//
// Hands on: গ্লাভস · ফেজ মিটার (tap the three terminals to clip it on; the
// earth bar is the trap) · read the meter (ঠিক / উল্টো) · the main switch's
// handle (ON/OFF) · তালা-ট্যাগ · টেস্টার · স্ক্রুড্রাইভার (tap two terminals
// to swap their wires) · START on the starter.
//
// Deadly: a screwdriver on the terminals with the main switch ON (also by
// listening to the coworker, "লাইন চালু রেখেই দুটো তার বদলে দাও!"). Slips:
// clipping the meter without gloves, a probe on the earth bar, misreading the
// meter, starting the pump untested / reversed / not tested again after the
// swap, the swap without the lock and tag or without proving dead, a swap
// without a reading first, swapping a sequence the meter showed right.
// Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m2_phase_swap_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next pump house by itself; the careless coworker once a play, on a
// reversed site, as the fix begins. Voice: the guide by device TTS; the
// coworker's new push by device TTS until recorded (his exit line is his
// existing recorded clip).

// ============================================================================
// Content
// ============================================================================

/// What the supply at the terminals really is.
enum PhaseKind { fwd, rev }

/// Which phase sequence meter the van carries to this site.
enum PhaseMeter { disc, digital }

/// The service work on the docket.
enum PhaseJob { newService, transformer, cable }

/// What the reason question asks about.
enum PhaseWhy { keep, swap, isolate, retest }

/// The hands-on tools.
enum PhaseTool { none, meter, driver }

@immutable
class PhaseSite {
  const PhaseSite({required this.id, required this.kind, required this.meter, required this.job, required this.why});
  final String id;
  final PhaseKind kind;
  final PhaseMeter meter;
  final PhaseJob job;
  final PhaseWhy why;
}

abstract final class PhaseLines {
  static const title = 'উল্টো ঘুরছে পাম্প';
  static const intro = 'নতুন লাইনের পর পাম্প উল্টো ঘুরতে পারে — এক সেকেন্ডেই নষ্ট! চালুর আগে মিটারে দেখুন, দরকার হলে নিরাপদে ঠিক করুন।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askTest = 'পাম্প চালুর আগে ফেজ সিকোয়েন্স দেখুন।';
  static const askRead = 'মিটার কী বলছে?';
  static const askFix = 'সিকোয়েন্স ঠিক করতে হবে — নিরাপদে।';
  static const askNext = 'এবার কী করবেন?';
  static const tasks = [askTest, askRead, askFix, askNext];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (tools, the docket, the meter).
  static const sceneLabel = 'পাম্প ঘর';
  static const gloves = 'গ্লাভস';
  static const meter = 'ফেজ মিটার';
  static const tester = 'টেস্টার';
  static const lock = 'তালা-ট্যাগ';
  static const driver = 'স্ক্রুড্রাইভার';
  static const sayFwd = 'সিকোয়েন্স ঠিক';
  static const sayRev = 'সিকোয়েন্স উল্টো';
  static const docket = 'ডকেট';
  static String jobBn(PhaseJob j) => switch (j) {
        PhaseJob.newService => 'নতুন থ্রি-ফেজ কানেকশন',
        PhaseJob.transformer => 'ট্রান্সফরমারে কাজের পর লাইন চালু',
        PhaseJob.cable => 'সার্ভিস কেবল বদলানো হয়েছে',
      };
  static const testerLive = 'লাইভ';
  static const testerDead = '0 V';
  static const noSupply = '— —';
  static const stampRun = 'জল উঠছে';

  // The reasons (lesson 2.8): the right ones fit this site and what was
  // done; the wrong ones are the lesson's myths and field excuses — never a
  // true rule marked wrong. Every card 38–45 letters.
  static const whyKeepQ = 'কেন কিছু না বদলেই চালালেন?';
  static const whySwapQ = 'কেন দুটো ফেজ বদলালেন?';
  static const whyIsolateQ = 'কেন আগে বন্ধ করে তালা-ট্যাগ দিলেন?';
  static const whyRetestQ = 'কেন চালুর আগে আবার মিটারে দেখলেন?';
  static const keepWhy = ['মিটারে সিকোয়েন্স R-Y-B এল, বদলের দরকার নেই', 'সিকোয়েন্স ঠিক, তার বদলালে উল্টো হয়ে যেত'];
  static const swapWhy = ['যেকোনো দুটো ফেজ বদলালেই সিকোয়েন্স ঠিক হয়', 'উল্টো সিকোয়েন্সে মোটর উল্টো ঘোরে, তাই বদল'];
  static const isolateWhy = ['চালু টার্মিনালে হাত দিলে শক, তাই আগে বন্ধ', 'বন্ধ, তালা-ট্যাগ, টেস্টারে মৃত — তবেই হাত'];
  static const retestWhy = ['বদলের পর সিকোয়েন্স ঠিক হলো কি না দেখা চাই', 'এক সেকেন্ড উল্টো ঘুরলেও পাম্প নষ্ট হতে পারে'];
  static const myths = [
    'লাল-হলুদ-নীল রং দেখেই সিকোয়েন্স বোঝা যায়',
    'ছোট মোটর উল্টো ঘুরলে কোনো ক্ষতি হয় না',
    'ল্যাম্প আর ক্যাপাসিটরেই কাজটা হয়ে যেত',
    'তিনটে তারই এক ঘর করে সরালে তবে ঠিক হয়',
    'সুইচ বন্ধ-চালু করলে শুধু সময় নষ্ট হয়',
    'মিটার যা-ই দেখাক, দুটো তার বদলালেই শেষ',
    'কনজিউমার তাড়া দিচ্ছেন, তাই তাড়াতাড়ি সারলাম',
  ];
  static const allRight = [...keepWhy, ...swapWhy, ...isolateWhy, ...retestWhy];

  static List<String> whyRight(PhaseSite s) => switch (s.why) {
        PhaseWhy.keep => keepWhy,
        PhaseWhy.swap => swapWhy,
        PhaseWhy.isolate => isolateWhy,
        PhaseWhy.retest => retestWhy,
      };
  static String whyQuestion(PhaseSite s) => switch (s.why) {
        PhaseWhy.keep => whyKeepQ,
        PhaseWhy.swap => whySwapQ,
        PhaseWhy.isolate => whyIsolateQ,
        PhaseWhy.retest => whyRetestQ,
      };

  /// The careless coworker: swap them live.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'লাইন চালু রেখেই দুটো তার বদলে দাও! বন্ধ-চালুর ঝামেলা কে করে?',
    exitLine: coworkerExit,
    right: ['না, আগে সুইচ বন্ধ, তালা-ট্যাগ, তবে তার', 'না, চালু টার্মিনালে হাত দেব না', 'না, বন্ধ করে মৃত প্রমাণ করে তবে বদল'],
    wrong: [
      'ঠিক, চালু রেখেই দুটো তার বদলে দিই',
      'আচ্ছা, গ্লাভস তো পরা, চালুতেই সারি',
      'বন্ধ-চালুর ঝামেলা না করে বদলাই',
      'ঠিক আছে, এক মিনিটের কাজ, চালুতেই',
      'হ্যাঁ, সাবধানে চালু লাইনেই বদলাই',
    ],
    asks: ['ও বলছে চালু রেখেই তার বদলাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'চালু টার্মিনালে হাত দেবেন?'],
  );

  static const callHeld = 'ঠিক! চালু টার্মিনালে কখনো হাত নয়।';
  static const allSet = 'পাম্প সোজা ঘুরছে — মিটারে দেখে, নিরাপদে দুটো ফেজ বদলে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে মিটার, তারপর নিরাপদে বদল।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtTest = 'চালুর আগে মিটারে দেখেছেন';
  static const caughtRev = 'উল্টো সিকোয়েন্স ধরেছেন';
  static const caughtSafe = 'বন্ধ, তালা-ট্যাগ, মৃত প্রমাণ — তবে হাত';
  static const caughtSwap = 'দুটো ফেজ বদলে সোজা';
  static const caughtRetest = 'বদলের পর আবার মিটার';
  static const caughtFwd = 'ঠিক থাকলে কিছু বদলাননি';
  static const caughtCall = 'চালু লাইনে “না” বলেছেন';
}

abstract final class PhaseMistakes {
  static const _dir = 'assets/game/art/m2_phase_swap';
  static const _live = '$_dir/swap_live.svg';
  static const _loto = '$_dir/lock_prove.svg';
  static const _gloves = '$_dir/gloves.svg';
  static const _earth = '$_dir/probe_earth.svg';
  static const _read = '$_dir/meter_read.svg';
  static const _run = '$_dir/reverse_run.svg';

  static const swapLive = DoMistake(
    key: '2.8/phase/swap-live',
    textBn: 'চালু লাইনে তার বদল নয়! আগে মেইন সুইচ বন্ধ, তালা-ট্যাগ, টেস্টারে মৃত প্রমাণ — তবে দুটো ফেজ বদল।',
    art: _live,
    deadly: true,
    lessonPoint: 2,
  );
  // Lock-out and proving dead come from the module's rules (lesson 1.6), not
  // lesson 2.8's text: no lesson point here.
  static const noLock = DoMistake(
    key: '2.8/phase/no-lock-tag',
    textBn: 'সুইচ বন্ধ করলেই হলো না — তালা আর ট্যাগ লাগান, যাতে কাজের মাঝে কেউ চালু করে না দেয়।',
    art: _loto,
  );
  static const noProve = DoMistake(
    key: '2.8/phase/not-proven-dead',
    textBn: 'বন্ধ করার পর টেস্টারে দেখে নিন টার্মিনাল সত্যিই মৃত — তবেই হাত দিন।',
    art: _loto,
  );
  static const noGloves = DoMistake(
    key: '2.8/phase/meter-no-gloves',
    textBn: 'ফেজ সিকোয়েন্স মিটার লাইভ লাইনে লাগে — আগে পুরো পিপিই, বিশেষ করে ইনসুলেটেড গ্লাভস।',
    art: _gloves,
    lessonPoint: 1,
  );
  static const probeEarth = DoMistake(
    key: '2.8/phase/probe-on-earth',
    textBn: 'প্রোব শুধু R, Y, B টার্মিনালে। আর্থিং পয়েন্ট বা একে অপরকে ছুঁলে শর্ট সার্কিট হতে পারে।',
    art: _earth,
    lessonPoint: 2,
  );
  static const misread = DoMistake(
    key: '2.8/phase/misread',
    textBn: 'মিটার ভুল পড়লেন। ডিস্ক ঘড়ির কাঁটার দিকে বা FWD = সঠিক R-Y-B; উল্টো দিকে বা REV = ভুল সিকোয়েন্স।',
    art: _read,
    lessonPoint: 1,
  );
  static const untested = DoMistake(
    key: '2.8/phase/run-untested',
    textBn: 'নতুন কানেকশনে আগে মিটারে ফেজ সিকোয়েন্স দেখুন — উল্টো ঘুরলে এক সেকেন্ডেই পাম্প নষ্ট হতে পারে।',
    art: _run,
    lessonPoint: 0,
  );
  static const reverseRun = DoMistake(
    key: '2.8/phase/run-reversed',
    textBn: 'মিটার উল্টো (R-B-Y) দেখিয়েছে — এভাবে চালালে মোটর উল্টো ঘুরবে, পাম্প নষ্ট হবে। আগে দুটো ফেজ বদল।',
    art: _run,
    lessonPoint: 0,
  );
  static const noRetest = DoMistake(
    key: '2.8/phase/no-retest',
    textBn: 'তার বদলের পর আবার মিটারে দেখুন — সিকোয়েন্স ঠিক হলো কি না — তবেই পাম্প চালু।',
    art: _run,
    lessonPoint: 2,
  );
  static const swapUnread = DoMistake(
    key: '2.8/phase/swap-unread',
    textBn: 'মিটার না দেখে তার বদল নয় — আগে ফেজ সিকোয়েন্স মাপুন, উল্টো হলে তবেই দুটো ফেজ বদল।',
    art: _read,
    lessonPoint: 2,
  );
  static const needlessSwap = DoMistake(
    key: '2.8/phase/needless-swap',
    textBn: 'মিটার ঠিক (R-Y-B) দেখিয়েছে — এখন দুটো তার বদলালে সিকোয়েন্সই উল্টে যাবে।',
    art: _read,
    lessonPoint: 2,
  );

  static const all = [swapLive, noLock, noProve, noGloves, probeEarth, misread, untested, reverseRun, noRetest, swapUnread, needlessSwap];
}

@immutable
class PhaseDeal {
  const PhaseDeal({required this.sites, required this.callAt});
  final List<PhaseSite> sites;

  /// The site the careless coworker comes to (a reversed one).
  final int callAt;
}

/// Three pump houses: two reversed, one right (any order), so swapping
/// everywhere cannot win; each reversed site asks a different reason; the
/// meter and the docket vary.
PhaseDeal dealPhase(math.Random rng) {
  final kinds = [PhaseKind.fwd, PhaseKind.rev, PhaseKind.rev]..shuffle(rng);
  final whys = [PhaseWhy.swap, PhaseWhy.isolate, PhaseWhy.retest]..shuffle(rng);
  final jobs = [...PhaseJob.values]..shuffle(rng);
  var w = 0;
  final sites = <PhaseSite>[
    for (final (i, k) in kinds.indexed)
      PhaseSite(
        id: 'p$i',
        kind: k,
        meter: rng.nextBool() ? PhaseMeter.disc : PhaseMeter.digital,
        job: jobs[i],
        why: k == PhaseKind.fwd ? PhaseWhy.keep : whys[w++],
      ),
  ];
  final revs = [
    for (final (i, s) in sites.indexed)
      if (s.kind == PhaseKind.rev) i,
  ];
  return PhaseDeal(sites: sites, callAt: revs[rng.nextInt(revs.length)]);
}

/// The play state (pure logic).
class PhaseRun {
  PhaseRun(this.deal);
  final PhaseDeal deal;
  int index = 0;
  int slips = 0;
  int siteSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // --- this site ---
  var gloves = false;
  var switchOn = true;
  var locked = false;
  var proved = false;
  var pumpOn = false;
  List<int> wires = [0, 1, 2];
  var _odd = false;
  int? lifted;
  final Set<int> probes = {};
  PhaseTool tool = PhaseTool.none;
  var everRead = false;
  var readSinceChange = false;
  var readingUp = false;
  var swapped = false;

  bool get done => index >= deal.sites.length;
  bool get ended => done || deadly != null;
  PhaseSite get site => deal.sites[index.clamp(0, deal.sites.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// The sequence at the terminals now (any swap of two wires flips it).
  bool get forward => (site.kind == PhaseKind.fwd) != _odd;

  /// The meter said reversed and nothing has changed since: the fix is on.
  bool get fixing => readSinceChange && !forward && !pumpOn;

  /// Done this site without a slip (+5 on the table).
  bool get thorough => siteSlips == 0;

  /// The three clips are on with the switch off: the meter shows nothing.
  bool get blank => probes.length == 3 && !switchOn;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    siteSlips++;
    return m;
  }

  bool get _open => !ended && !pumpOn;

  void putGloves() {
    if (_open) gloves = true;
  }

  /// Picks up [t] (or puts it down, if held). Putting the meter down takes its clips off.
  void hold(PhaseTool t) {
    if (!_open || readingUp) return;
    tool = tool == t ? PhaseTool.none : t;
    if (tool != PhaseTool.meter) probes.clear();
    if (tool != PhaseTool.driver) lifted = null;
  }

  /// Taps terminal [i] with the tool in hand. Returns the mistake, if any.
  DoMistake? tapTerminal(int i) {
    if (!_open || readingUp) return null;
    switch (tool) {
      case PhaseTool.none:
        return null;
      case PhaseTool.meter:
        if (!gloves) return _slip(PhaseMistakes.noGloves);
        probes.add(i);
        if (probes.length == 3 && switchOn) readingUp = true;
        return null;
      case PhaseTool.driver:
        if (switchOn) return deadly = PhaseMistakes.swapLive;
        if (!locked) return _slip(PhaseMistakes.noLock);
        if (!proved) return _slip(PhaseMistakes.noProve);
        if (!readSinceChange) return _slip(PhaseMistakes.swapUnread);
        if (forward) return _slip(PhaseMistakes.needlessSwap);
        final a = lifted;
        if (a == null) {
          lifted = i;
        } else if (a == i) {
          lifted = null;
        } else {
          final w = [...wires];
          final x = w[a];
          w[a] = w[i];
          w[i] = x;
          wires = w;
          _odd = !_odd;
          lifted = null;
          readSinceChange = false;
          swapped = true;
          tool = PhaseTool.none;
          _tag(PhaseLines.caughtSafe);
          _tag(PhaseLines.caughtSwap);
        }
        return null;
    }
  }

  /// A probe on the earth bar.
  DoMistake? tapEarth() {
    if (!_open || readingUp || tool != PhaseTool.meter) return null;
    if (!gloves) return _slip(PhaseMistakes.noGloves);
    return _slip(PhaseMistakes.probeEarth);
  }

  /// The clips come off (after a blank meter).
  void clearProbes() {
    if (!readingUp) probes.clear();
  }

  /// Reads the meter: [sayForward] = "সিকোয়েন্স ঠিক".
  DoMistake? answer(bool sayForward) {
    if (!_open || !readingUp) return null;
    if (sayForward != forward) return _slip(PhaseMistakes.misread);
    readingUp = false;
    probes.clear();
    tool = PhaseTool.none;
    everRead = true;
    readSinceChange = true;
    _tag(PhaseLines.caughtTest);
    if (!forward) _tag(PhaseLines.caughtRev);
    if (forward && swapped) _tag(PhaseLines.caughtRetest);
    return null;
  }

  /// The main switch's handle. False = it did not move (locked, a wire out, the pump on).
  bool toggleSwitch() {
    if (!_open || readingUp || locked || lifted != null) return false;
    switchOn = !switchOn;
    if (switchOn) proved = false;
    probes.clear();
    return true;
  }

  /// The lock and tag go on the OFF handle (or come off). False = not now.
  bool toggleLock() {
    if (!_open || readingUp || switchOn || lifted != null) return false;
    locked = !locked;
    return true;
  }

  /// The tester on the terminals: true = live.
  bool test() {
    if (_open && !readingUp && !switchOn) proved = true;
    return switchOn;
  }

  /// START on the starter. Null and [pumpOn] = the pump runs the right way.
  DoMistake? start() {
    if (!_open || readingUp || !switchOn) return null;
    if (!everRead) return _slip(PhaseMistakes.untested);
    if (!readSinceChange) return _slip(PhaseMistakes.noRetest);
    if (!forward) return _slip(PhaseMistakes.reverseRun);
    pumpOn = true;
    tool = PhaseTool.none;
    if (!swapped) _tag(PhaseLines.caughtFwd);
    return null;
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    siteSlips = 0;
    gloves = false;
    switchOn = true;
    locked = false;
    proved = false;
    pumpOn = false;
    wires = [0, 1, 2];
    _odd = false;
    lifted = null;
    probes.clear();
    tool = PhaseTool.none;
    everRead = false;
    readSinceChange = false;
    readingUp = false;
    swapped = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   right site: gloves, meter, 3 clips, read ~2000 + answer, START,
///     the water ~1500, reason ~8200                              ≈ 22700
///   reversed site: the test as above ≈ 11000, OFF, lock, tester ~2500,
///     driver, 2 terminals, unlock, ON, meter + 3 clips, read + answer
///     ≈ 3500, START, the water, reason ~8200                      ≈ 46200 × 2
/// + the coworker once ≈ 9600                                     ≈ 124700
/// 85 % ≈ 106000 → 110 s.
const kPhaseQuickMs = 110000;

@immutable
class M2PhaseSwapPack {
  const M2PhaseSwapPack({required this.id, required this.titleBn, this.quickMs = kPhaseQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M2PhaseSwapPack> m2PhaseSwapPacks = {
  'do_2_8_b': M2PhaseSwapPack(id: 'do_2_8_b', titleBn: PhaseLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M2PhaseSwapPage extends StatefulWidget {
  const M2PhaseSwapPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2PhaseSwapPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2PhaseSwapPage> createState() => _M2PhaseSwapPageState();
}

class _M2PhaseSwapPageState extends State<M2PhaseSwapPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PhaseRunPage(
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

class _PhaseRunPage extends ConsumerStatefulWidget {
  const _PhaseRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2PhaseSwapPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PhaseRunPage> createState() => _PhaseRunPageState();
}

class _PhaseRunPageState extends ConsumerState<_PhaseRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final PhaseRun _run = PhaseRun(dealPhase(widget.rng));
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
  var _coworkerArmed = false;

  /// The tester's lamp, a moment after it touches the terminals.
  bool? _tester;
  Timer? _testerTimer;
  Timer? _blankTimer;

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
    _testerTimer?.cancel();
    _blankTimer?.cancel();
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
    _startSite();
  }

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_run.pumpOn && !_freeze;

  String get _task {
    if (_run.readingUp) return PhaseLines.askRead;
    if (_run.fixing && !_run.swapped) return PhaseLines.askFix;
    if (!_run.everRead) return PhaseLines.askTest;
    return PhaseLines.askNext;
  }

  void _startSite() {
    _testerTimer?.cancel();
    _blankTimer?.cancel();
    setState(() {
      _tester = null;
      _wake++;
    });
    unawaited(_sayChain([PhaseLines.askTest]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _putGloves() {
    if (!_canPlay || _run.gloves) return;
    _tick('sounds/learn/tag_slap.wav', 0.35);
    setState(() {
      _run.putGloves();
      _wake++;
    });
  }

  void _hold(PhaseTool t) {
    if (!_canPlay || _run.readingUp) return;
    _tick('sounds/quiz_select.wav');
    setState(() {
      _run.hold(t);
      _wake++;
    });
  }

  void _useTester() {
    if (!_canPlay || _run.readingUp) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final live = _run.test();
    _testerTimer?.cancel();
    setState(() {
      _tester = live;
      _wake++;
    });
    _testerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tester = null);
    });
  }

  void _toggleLock() {
    if (!_canPlay) return;
    if (_run.toggleLock()) {
      _tick('sounds/learn/tag_slap.wav', 0.5);
    } else {
      _tick('sounds/intro/click.ogg', 0.3);
    }
    setState(() => _wake++);
  }

  void _tapScene(Offset p, PhaseGeo geo, Offset global) {
    if (_intro || _ended || _card != null || reasonOpen || _freeze || _run.pumpOn) return;
    // While he talks, only the main switch answers him (going OFF refuses him).
    if (coworkerOpen) {
      if (coworkerChoiceUp && geo.handleHit.contains(p) && _run.switchOn && _run.toggleSwitch()) {
        _tick('sounds/intro/impact_metal.ogg', 0.6);
        setState(() => _wake++);
        unawaited(answerCoworker(true, global, direct: true));
      }
      return;
    }
    if (geo.handleHit.contains(p)) {
      if (_run.toggleSwitch()) {
        _tick('sounds/intro/impact_metal.ogg', 0.6);
      } else {
        _tick('sounds/intro/click.ogg', 0.3);
      }
      _blankTimer?.cancel();
      setState(() => _wake++);
      return;
    }
    for (var i = 0; i < 3; i++) {
      if (geo.terminalHit(i).contains(p)) {
        _tick();
        final m = _run.tapTerminal(i);
        setState(() => _wake++);
        if (m != null) {
          unawaited(_mistake(m, global));
        } else if (_run.readingUp) {
          _cue('sounds/learn/card_deal_a.wav', volume: 0.5);
          unawaited(_sayChain([PhaseLines.askRead]));
        } else if (_run.blank) {
          // No supply on the clips: the meter stays dark, the clips come off.
          _blankTimer?.cancel();
          _blankTimer = Timer(const Duration(milliseconds: 1600), () {
            if (!mounted) return;
            setState(() {
              _run.clearProbes();
              _wake++;
            });
          });
        } else if (_run.swapped && !_run.readSinceChange && _run.tool == PhaseTool.none && _run.lifted == null) {
          // The two wires are swapped and screwed down.
          _cue('sounds/learn/tag_slap.wav', volume: 0.5);
          unawaited(_sayChain([PhaseLines.askNext]));
        }
        return;
      }
    }
    if (geo.earthHit.contains(p)) {
      final m = _run.tapEarth();
      if (m != null) {
        setState(() => _wake++);
        unawaited(_mistake(m, global));
      }
      return;
    }
    if (geo.startHit.contains(p)) {
      _tick('sounds/intro/click.ogg', 0.6);
      final m = _run.start();
      setState(() => _wake++);
      if (m != null) {
        unawaited(_mistake(m, global));
      } else if (_run.pumpOn) {
        unawaited(_siteDone());
      }
    }
  }

  void _answer(bool sayForward, Offset origin) {
    if (!_canPlay || !_run.readingUp) return;
    _hush();
    final m = _run.answer(sayForward);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.wav', volume: 0.5);
    if (!_coworkerArmed && _run.index == _run.deal.callAt && _run.fixing) {
      _coworkerArmed = true;
      scheduleCoworker();
    }
    unawaited(_sayChain([_task]));
  }

  Future<void> _siteDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final s = _run.site;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(PhaseLines.whyRight(s), PhaseLines.myths, widget.rng),
      question: PhaseLines.whyQuestion(s),
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
  CoworkerScript get coworkerScript => PhaseLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.swapped || _run.pumpOn || !_run.switchOn) return null;
    if (_intro || _card != null || reasonOpen || _run.readingUp || _tester != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: the screwdriver goes on the live terminals.
      _run.failDeadly(PhaseMistakes.swapLive);
      await _deadly(PhaseMistakes.swapLive);
      return;
    }
    _run.caught.add(PhaseLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([PhaseLines.callHeld, PhaseLines.askFix], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? PhaseLines.tapWhy[_nudgeN++ % PhaseLines.tapWhy.length]
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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('phase/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A screwdriver on live terminals: the pump house freezes grey and the
  /// flash comes off the terminals in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _testerTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _tester = null;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('phase/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? PhaseLines.deadlyWord : PhaseLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same pump house goes on from where it was.
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
    await _say(!_run.passed ? PhaseLines.fail : (_quickBonus ? PhaseLines.quick : PhaseLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_run.pumpOn) return LinemanMode.cheer;
    if (_run.tool != PhaseTool.none || _run.readingUp) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  PanelState get _panel => PanelState(
        wires: _run.wires,
        switchOn: _run.switchOn,
        locked: _run.locked,
        probes: {..._run.probes},
        lifted: _run.lifted,
        pumpOn: _run.pumpOn,
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = PhaseGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = geo.trainee;
    final panel = _panel;
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
                  key: const ValueKey('house'),
                  child: RepaintBoundary(child: CustomPaint(painter: PumpHousePainter(geo: geo, panel: panel, t: t, seed: _run.index * 5 + 3))),
                ),
                Positioned.fromRect(
                  key: const ValueKey('trainee'),
                  rect: tb,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ],
            ),
          ),
        ),
      ),
      // The selected wire, ringed (the one lifted for the swap).
      if (_run.lifted != null && !_freeze)
        Positioned.fromRect(
          key: const ValueKey('lifted'),
          rect: Rect.fromCenter(center: geo.terminals[_run.lifted!], width: 26, height: 26),
          child: const IgnorePointer(
            child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Color(0xFFFFE08A), width: 2.4)))),
          ),
        ),
      // The tester's lamp at the terminal block.
      if (_tester != null && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: geo.terminalBlock.left - 6,
          top: geo.terminalBlock.top - 40,
          child: IgnorePointer(child: _TesterChip(live: _tester!, quiet: quiet)),
        ),
      if (_run.pumpOn && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 206,
          width: 140,
          top: geo.groundY - 200,
          child: IgnorePointer(child: _StampPop(text: PhaseLines.stampRun, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: PhaseLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: TerminalArcPainter(geo: geo, v: v)),
            ),
          ),
        ),
      // The next pump house: a short fade from the last one.
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
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.pumpOn && !deckUp && !coworkerOpen && _card == null;
    final s = _run.site;
    final meterUp = playing && _card == null && (_run.readingUp || _run.blank);
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
              labels: PhaseLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(job: s.job)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (meterUp)
                Positioned(
                  key: ValueKey('meter-${s.meter.name}'),
                  right: 14,
                  top: pad.top + 150,
                  width: 150,
                  height: 170,
                  child: IgnorePointer(child: _MeterCard(disc: s.meter == PhaseMeter.disc, forward: _run.blank ? null : _run.forward, wake: _wake, quiet: quiet)),
                ),
              if (handsOn && _run.readingUp)
                Positioned(
                  key: const ValueKey('hud-read'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(child: DoBigButton(label: PhaseLines.sayFwd, filled: true, onTapUp: (d) => _answer(true, d.globalPosition))),
                      const SizedBox(width: 10),
                      Expanded(child: DoBigButton(label: PhaseLines.sayRev, filled: true, onTapUp: (d) => _answer(false, d.globalPosition))),
                    ],
                  ),
                ),
              if (handsOn && !_run.readingUp)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(icon: Icons.back_hand_rounded, label: PhaseLines.gloves, on: _run.gloves, onTap: _putGloves),
                      _ToolButton(icon: Icons.speed_rounded, label: PhaseLines.meter, on: _run.tool == PhaseTool.meter, onTap: () => _hold(PhaseTool.meter)),
                      _ToolButton(icon: Icons.flash_on_rounded, label: PhaseLines.tester, on: _tester != null, onTap: _useTester),
                      _ToolButton(icon: Icons.lock_rounded, label: PhaseLines.lock, on: _run.locked, onTap: _toggleLock),
                      _ToolButton(icon: Icons.construction_rounded, label: PhaseLines.driver, on: _run.tool == PhaseTool.driver, onTap: () => _hold(PhaseTool.driver)),
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
                  line: PhaseLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
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

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.job});
  final PhaseJob job;

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
          Text(PhaseLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(PhaseLines.jobBn(job), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// The meter in his hand, its face big enough to read.
class _MeterCard extends StatelessWidget {
  const _MeterCard({required this.disc, required this.forward, required this.wake, required this.quiet});
  final bool disc;
  final bool? forward;
  final int wake;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 40 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: AwakeClock(
          wake: wake,
          quiet: quiet,
          awake: const Duration(seconds: 6),
          builder: (_, t) => RepaintBoundary(child: CustomPaint(painter: MeterFacePainter(disc: disc, forward: forward, t: t))),
        ),
      ),
    );
  }
}

class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.live, required this.quiet});
  final bool live;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.7 + 0.3 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xEE101A2B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: live ? SlmColors.danger : const Color(0xFF6E7C90), width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: live ? const Color(0xFFFF5A3D) : const Color(0xFF3A3F45),
                boxShadow: live ? const [BoxShadow(color: Color(0xAAFF5A3D), blurRadius: 8, spreadRadius: 1)] : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(live ? PhaseLines.testerLive : PhaseLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
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
          width: 68,
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

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
