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
import 'm4_phase_balance_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 4.10 "এলটি (LT) লাইনের ফেজ ব্যালেন্সিং", কাজ "তিন ফেজে সমান ভার"
// (pack do_4_10_a, engineType m4_phase_balance). One transformer's feeder
// pillar at the evening peak: a phase's fuse keeps blowing, two new service
// connections are on the docket. Three stages:
//   1. মাপা — gloves, the tong tester round each outgoing cable R, Y, B and
//      the neutral; read which phase carries the most;
//   2. ভাগ — the phase chart (the record of which consumer is on which
//      phase): move connections off the heavy phase and give the two new
//      ones a phase, until the three phases are about equal;
//   3. বদল — tell the consumers, shutdown (LT main OFF), PTW, prove dead,
//      earth; move the connections on the bars; earth off, PTW back, ON;
//      measure again; write the record.
//
// The lesson's rules, and only those:
//   • point 0: an overloaded phase blows its fuse and heats the transformer;
//     its consumers get low voltage; unbalance sends current down the
//     neutral; balanced = no neutral current;
//   • point 1: the clamp-on meter / tong tester round each phase (R, Y, B)
//     AND the neutral at the transformer's LT side or the feeder pillar;
//   • point 2: step 1 measure at peak load (e.g. R=120A, Y=70A, B=50A),
//     step 2 plan which service lines of the overloaded phase go to the
//     lighter phases, step 3 change them with the right PTW and safety rules
//     (the film: "শাটডাউন নিয়ে"), step 4 measure again;
//   • pro tips: the neutral current is the proof (bring it near zero); keep
//     a record of which consumer is on which phase; tell the consumer first;
//   • myths: "no voltage on the neutral, so no current"; "balancing is not
//     worth it". The film: random single-phase connections cause unbalance.
// NOT in lesson 4.10's text (flagged in REGISTER.md): rubber gloves for the
// live measurement (lesson 1.1: rubber gloves for live or possibly live
// work); proving dead and earthing before the work, and earth off + PTW back
// before the supply goes on (the module's rules); the "balanced" mark — the
// three phases within 10 A of each other, as the lesson's own after-example
// (85A, 80A, 75A).
//
// Deadly: a spanner on the bars with the LT main ON (changing the service
// connections live — the lesson says PTW, the film says shutdown). Slips:
// clamping without gloves, reading the heavy phase without the neutral,
// misreading, a plan still unbalanced, piling the new connections on the
// heavy phase (listening to the coworker), shutdown without telling the
// consumers, the work without PTW / without earthing (not proven dead),
// supply on with the earth or PTW still on, the record before measuring
// again. Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_phase_balance_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next stage by itself; the careless coworker once a play, at the
// chart ("চার্ট ঠিক আছে" waits for him: holdForCoworker). Voice: the guide by
// device TTS; the coworker's push is silent with its caption held until it is
// recorded (his exit line is his existing recorded clip).
//
// No giveaways: the tool row is in a dealt order (never the job's order),
// the chart's column totals are all the same colour (no red "still heavy"
// mark that would announce a balanced chart). Gesture hints sweep over what
// can be touched now (tools, cables, the switch, chart chips/columns, the
// phase buttons) — never one answer.

// ============================================================================
// Content
// ============================================================================

/// The three stages of the job.
enum M4PhaseBalanceStage { measure, plan, work, done }

/// The hands-on tools.
enum M4PhaseBalanceTool { none, tong, spanner }

/// The buttons of the tool row (every stage shows some of them).
enum M4PhaseBalanceKit { gloves, tong, book, notice, ptw, tester, earth, spanner }

/// The tool row's order for one play: dealt. The work row (notice, PTW,
/// tester, earth, spanner) is never in the job's order; the two- and
/// three-button rows (gloves · tong, + the record book) fall as dealt.
List<M4PhaseBalanceKit> dealM4PhaseBalanceKit(math.Random rng) {
  for (;;) {
    final order = [...M4PhaseBalanceKit.values]..shuffle(rng);
    final work = [for (final k in order) if (k.index >= M4PhaseBalanceKit.notice.index) k];
    if (!_sorted(work)) return order;
  }
}

bool _sorted(List<M4PhaseBalanceKit> ks) {
  for (var i = 1; i < ks.length; i++) {
    if (ks[i].index < ks[i - 1].index) return false;
  }
  return true;
}

/// A service connection on the chart.
@immutable
class M4PhaseBalanceLoad {
  const M4PhaseBalanceLoad({required this.id, required this.no, required this.amps, this.isNew = false});
  final String id;

  /// The consumer's number on the chart.
  final int no;

  /// The load it puts on its phase (A at the peak).
  final int amps;

  /// A new connection still to be given a phase.
  final bool isNew;
}

/// The phase names.
const m4PhaseBalancePhases = ['R', 'Y', 'B'];

/// The three phases are "balanced" when within this many amperes of each
/// other (the lesson's after-example: 85A, 80A, 75A).
const kM4PhaseBalanceSpread = 10;

/// The neutral current of three phase currents at the same power factor
/// (their vector sum; zero when they are equal).
int m4PhaseBalanceNeutral(List<int> a) {
  final r = a[0], y = a[1], b = a[2];
  final v = r * r + y * y + b * b - r * y - y * b - b * r;
  return math.sqrt(math.max(0, v)).round();
}

/// The phase currents of an assignment (load id → phase).
List<int> m4PhaseBalanceAmps(List<M4PhaseBalanceLoad> loads, Map<String, int> on) {
  final a = [0, 0, 0];
  for (final l in loads) {
    final p = on[l.id];
    if (p != null) a[p] += l.amps;
  }
  return a;
}

int _spread(List<int> a) => a.reduce(math.max) - a.reduce(math.min);

abstract final class M4PhaseBalanceLines {
  static const title = 'তিন ফেজে সমান ভার';
  static const intro = 'একটা ফেজের ফিউজ বারবার উড়ছে! মেপে দেখে তিন ফেজে ভার সমান করুন।';
  static const rounds = ['মাপা', 'ভাগ', 'বদল'];

  // The guide's task now (tap him: the same task, a different way).
  static const askMeasure = 'পিক-লোডের সময়। পিলারে প্রতিটা তারের কারেন্ট মাপুন।';
  static const askRead = 'কোন ফেজে ভার সবচেয়ে বেশি?';
  static const askPlan = 'চার্টে কানেকশনগুলো তিন ফেজে ভাগ করুন।';
  static const askWork = 'এবার নিরাপদে কানেকশন বদলান।';
  static const askNext = 'এবার কী করবেন?';
  static const tasks = [askMeasure, askRead, askPlan, askWork, askNext];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (tools, the docket, the chart).
  static const sceneLabel = 'ফিডার পিলার';
  static const gloves = 'গ্লাভস';
  static const tong = 'টং টেস্টার';
  static const notice = 'গ্রাহককে খবর';
  static const ptw = 'PTW';
  static const tester = 'টেস্টার';
  static const earth = 'আর্থ';
  static const spanner = 'স্প্যানার';
  static const book = 'রেকর্ড খাতা';
  static const chart = 'ফেজ চার্ট';
  static const newTray = 'নতুন কানেকশন';
  static const newChip = 'নতুন';
  static const total = 'মোট';
  static const planOk = 'চার্ট ঠিক আছে';
  static const readings = 'রিডিং';
  static String phaseBtn(int p) => '${m4PhaseBalancePhases[p]} ফেজ';
  static const docket = 'ডকেট';
  static const docketJob = 'ফিউজ উড়ছে, লো-ভোল্টেজ · নতুন 2 কানেকশন';
  static const testerLive = 'লাইভ';
  static const testerDead = '0 V';
  static const toldStamp = 'গ্রাহকদের জানানো হলো';
  static const stampDone = 'ভার সমান';

  // The reasons (lesson 4.10): the right ones fit what was just done; the
  // wrong ones are the lesson's myths and field excuses — never a true rule
  // marked wrong. Every card 33–42 letters.
  static const whyMeasureQ = 'কেন নিউট্রালেও টং টেস্টার লাগালেন?';
  static const whyPlanQ = 'কেন ভারী ফেজ থেকে কানেকশন সরালেন?';
  static const whyCheckQ = 'কেন কাজের পর আবার মাপলেন?';
  static const measureWhy = ['নিউট্রালের কারেন্টই আনব্যালেন্সের সরাসরি প্রমাণ', 'আনব্যালেন্স হলে নিউট্রাল দিয়েও কারেন্ট ছোটে'];
  static const planWhy = ['এক ফেজে বেশি ভারে ফিউজ ওড়ে, ট্রান্সফরমার গরম হয়', 'তিন ফেজে সমান ভার হলে নিউট্রালের কারেন্ট কমে'];
  static const checkWhy = ['আবার না মাপলে ব্যালেন্স হলো কি না বোঝা যায় না', 'নিউট্রাল শূন্যের কাছে নামল কি না দেখা চাই'];
  static const myths = [
    'নিউট্রালে ভোল্টেজ নেই, তাই ওতে কারেন্টও নেই',
    'লোড ব্যালেন্সিং-এ খাটুনি বেশি, লাভ কিছু নেই',
    'চোখে দেখেই বোঝা যায় কোন ফেজে ভার বেশি',
    'নতুন কানেকশন কাছের ফেজে দিলেই কাজ সোজা',
    'একবার ব্যালেন্স করলে আর কখনো মাপতে হয় না',
    'ট্রান্সফরমার বড় হলে আনব্যালেন্সে কিছু হয় না',
  ];
  static const allRight = [...measureWhy, ...planWhy, ...checkWhy];

  static List<String> whyRight(M4PhaseBalanceStage s) => switch (s) {
        M4PhaseBalanceStage.measure => measureWhy,
        M4PhaseBalanceStage.plan => planWhy,
        _ => checkWhy,
      };
  static String whyQuestion(M4PhaseBalanceStage s) => switch (s) {
        M4PhaseBalanceStage.measure => whyMeasureQ,
        M4PhaseBalanceStage.plan => whyPlanQ,
        _ => whyCheckQ,
      };

  /// The careless coworker: pile every new connection on one phase — the
  /// heavy one (the film: random single-phase connections cause unbalance).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static CoworkerScript coworker(int heavy) {
    final p = m4PhaseBalancePhases[heavy];
    return CoworkerScript(
      line: 'সব নতুন কানেকশন $p ফেজেই দিয়ে দাও! অত মাপামাপির কী দরকার?',
      exitLine: coworkerExit,
      // No prefix tells: a right card may open without "না", a wrong one with it.
      right: ['না, $p ফেজে আর ভার চাপালে ফিউজ উড়বে', 'আগে মেপে দেখি, কম ভারের ফেজেই দেব', 'তিন ফেজে সমান ভাগ করেই তবে দেব'],
      wrong: [
        'ঠিক, সব নতুন কানেকশন $p ফেজেই দিই',
        'আচ্ছা, মাপামাপি থাক, $p ফেজেই জুড়ি',
        'হ্যাঁ, এক ফেজে দিলেই কাজটা সোজা',
        'না না, মাপার দরকার নেই, $p ফেজেই দিই',
        'হ্যাঁ, পরে কেউ ব্যালেন্স করে নেবে',
      ],
      asks: ['ও বলছে সব নতুন কানেকশন এক ফেজে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না মাপ?', 'সব নতুন কানেকশন এক ফেজে?'],
    );
  }

  /// Every coworker line the level can say (for the recording list and tests).
  static List<CoworkerScript> get allCoworkers => [for (var p = 0; p < 3; p++) coworker(p)];

  static const callHeld = 'ঠিক! মেপে, কম ভারের ফেজে — তবেই ব্যালেন্স।';
  static const allSet = 'তিন ফেজে ভার সমান, নিউট্রাল প্রায় শূন্য — সাবাশ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — মাপুন, ভাগ করুন, নিরাপদে বদলান, আবার মাপুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtMeasure = 'চার তারেই মেপেছেন, নিউট্রালও';
  static const caughtHeavy = 'ভারী ফেজ ধরেছেন';
  static const caughtPlan = 'তিন ফেজে সমান ভাগ';
  static const caughtCall = '“সব এক ফেজে” — না বলেছেন';
  static const caughtNotice = 'গ্রাহকদের আগে জানিয়েছেন';
  static const caughtSafe = 'শাটডাউন, PTW, মৃত প্রমাণ, আর্থ — তবে বদল';
  static const caughtCheck = 'কাজের পর আবার মেপেছেন';
  static const caughtBook = 'রেকর্ড খাতায় লিখেছেন';
}

abstract final class M4PhaseBalanceMistakes {
  static const _dir = 'assets/game/art/m4_phase_balance';
  static const _gloves = '$_dir/clamp_gloves.svg';
  static const _neutral = '$_dir/neutral_too.svg';
  static const _pile = '$_dir/one_phase.svg';
  static const _plan = '$_dir/plan_spread.svg';
  static const _live = '$_dir/shift_live.svg';
  static const _ptw = '$_dir/ptw_earth.svg';
  static const _told = '$_dir/tell_consumer.svg';
  static const _check = '$_dir/measure_again.svg';

  static const shiftLive = DoMistake(
    key: '4.10/m4_phase_balance/shift-live',
    textBn: 'চালু বাসবারে কানেকশন বদল নয়! আগে শাটডাউন, PTW, টেস্টারে মৃত প্রমাণ, আর্থ — তবে বদল।',
    art: _live,
    deadly: true,
    lessonPoint: 2,
  );
  // Rubber gloves for live work come from lesson 1.1, not lesson 4.10.
  static const noGloves = DoMistake(
    key: '4.10/m4_phase_balance/clamp-no-gloves',
    textBn: 'চালু পিলারের তারে টং টেস্টার — আগে রাবার গ্লাভস। লাইভ কাজে গ্লাভসই হাতের ঢাল।',
    art: _gloves,
  );
  static const noNeutral = DoMistake(
    key: '4.10/m4_phase_balance/no-neutral',
    textBn: 'R, Y, B-এর সাথে নিউট্রালেও টং টেস্টার লাগান — নিউট্রালের কারেন্টই আনব্যালেন্সের প্রমাণ।',
    art: _neutral,
    lessonPoint: 1,
  );
  static const misread = DoMistake(
    key: '4.10/m4_phase_balance/misread',
    textBn: 'রিডিং ভুল পড়লেন। যে ফেজে অ্যাম্পিয়ার সবচেয়ে বেশি, সেটাই ওভারলোডেড।',
    art: _neutral,
    lessonPoint: 2,
  );
  static const badPlan = DoMistake(
    key: '4.10/m4_phase_balance/plan-unbalanced',
    textBn: 'চার্টে তিন ফেজ এখনও সমান নয়। ভারী ফেজের কিছু কানেকশন কম ভারের ফেজে দিন।',
    art: _plan,
    lessonPoint: 2,
  );
  static const pileOn = DoMistake(
    key: '4.10/m4_phase_balance/new-on-one-phase',
    textBn: 'সব নতুন কানেকশন এক ফেজে দিলেই আনব্যালেন্স — ফিউজ ওড়ে, লো-ভোল্টেজ, নিউট্রালে কারেন্ট।',
    art: _pile,
    lessonPoint: 0,
  );
  // Telling the consumer is the lesson's pro tip 4 (no lesson point).
  static const noNotice = DoMistake(
    key: '4.10/m4_phase_balance/no-notice',
    textBn: 'শাটডাউনের আগে গ্রাহকদের জানান — সার্ভিস লাইন বদলের আগে আগাম খবর দিয়ে কাজ।',
    art: _told,
  );
  static const noPtw = DoMistake(
    key: '4.10/m4_phase_balance/no-ptw',
    textBn: 'শুধু সুইচ বন্ধ করলেই হলো না — সঠিক PTW নিয়ে তবে কানেকশন বদল।',
    art: _ptw,
    lessonPoint: 2,
  );
  // Proving dead, earthing and the restore order: the module's rules.
  static const noProve = DoMistake(
    key: '4.10/m4_phase_balance/not-proven-dead',
    textBn: 'আর্থ লাগানোর আগে টেস্টারে দেখুন বাসবার সত্যিই মৃত — তবেই আর্থ।',
    art: _ptw,
  );
  static const noEarth = DoMistake(
    key: '4.10/m4_phase_balance/no-earth',
    textBn: 'মৃত প্রমাণের পর বাসবারে আর্থ লাগান — তবেই হাত দিয়ে কানেকশন বদল।',
    art: _ptw,
  );
  static const restoreEarly = DoMistake(
    key: '4.10/m4_phase_balance/on-with-earth-or-ptw',
    textBn: 'লাইন চালুর আগে আর্থ খুলুন, PTW ফেরত দিন — তবেই সুইচ ON।',
    art: _ptw,
  );
  static const noCheck = DoMistake(
    key: '4.10/m4_phase_balance/no-remeasure',
    textBn: 'কাজের পর আবার চার তারেই মাপুন — ব্যালেন্স হলো কি না দেখে তবেই রেকর্ড।',
    art: _check,
    lessonPoint: 2,
  );

  static List<DoMistake> get all =>
      const [shiftLive, noGloves, noNeutral, misread, badPlan, pileOn, noNotice, noPtw, noProve, noEarth, restoreEarly, noCheck];
}

@immutable
class M4PhaseBalanceDeal {
  const M4PhaseBalanceDeal({required this.loads, required this.wired, required this.heavy, required this.balanced});

  /// Every service connection on the chart (the new ones last).
  final List<M4PhaseBalanceLoad> loads;

  /// The phase each existing connection is on now.
  final Map<String, int> wired;

  /// The overloaded phase.
  final int heavy;

  /// One balanced chart (every load, new ones too) — proof a fix exists.
  final Map<String, int> balanced;

  List<M4PhaseBalanceLoad> get newLoads => [for (final l in loads) if (l.isNew) l];
}

/// A balanced street first (every phase the same), the two new connections
/// taken off it, then connections piled on one random phase until it is
/// clearly the heavy one (lesson example R=120A, Y=70A, B=50A).
M4PhaseBalanceDeal dealM4PhaseBalance(math.Random rng) {
  for (var tries = 0;; tries++) {
    final target = 75 + 5 * rng.nextInt(3);
    final numbers = [for (var i = 1; i <= 60; i++) i]..shuffle(rng);
    var n = 0;
    final loads = <M4PhaseBalanceLoad>[];
    final news = <M4PhaseBalanceLoad>[];
    final balanced = <String, int>{};
    final newOn = ([0, 1, 2]..shuffle(rng)).take(2).toSet();
    for (var p = 0; p < 3; p++) {
      var sum = 0;
      if (newOn.contains(p)) {
        final l = M4PhaseBalanceLoad(id: 'n${news.length}', no: numbers[n++], amps: rng.nextBool() ? 5 : 10, isNew: true);
        news.add(l);
        balanced[l.id] = p;
        sum += l.amps;
      }
      while (target - sum > 20) {
        final l = M4PhaseBalanceLoad(id: 'c${loads.length}', no: numbers[n++], amps: const [10, 15, 20][rng.nextInt(3)]);
        loads.add(l);
        balanced[l.id] = p;
        sum += l.amps;
      }
      final last = target - sum;
      if (last > 0) {
        final l = M4PhaseBalanceLoad(id: 'c${loads.length}', no: numbers[n++], amps: last);
        loads.add(l);
        balanced[l.id] = p;
      }
    }
    final heavy = rng.nextInt(3);
    final wired = {for (final l in loads) l.id: balanced[l.id]!};
    final light = [for (var p = 0; p < 3; p++) if (p != heavy) p];
    for (var k = 0; k < 8; k++) {
      final a = m4PhaseBalanceAmps(loads, wired);
      final sorted = [...a]..sort();
      if (a[heavy] - sorted[0] >= 45 && a[heavy] - sorted[1] >= 25) {
        final perPhase = [for (var p = 0; p < 3; p++) wired.values.where((x) => x == p).length];
        if (perPhase.every((c) => c <= 9) && sorted[0] > 0) {
          return M4PhaseBalanceDeal(loads: [...loads, ...news], wired: wired, heavy: heavy, balanced: balanced);
        }
        break;
      }
      // Pile one more connection from a light phase onto the heavy one.
      final from = light[rng.nextInt(2)];
      final pool = [for (final l in loads) if (wired[l.id] == from) l];
      if (pool.length <= 1) continue;
      wired[pool[rng.nextInt(pool.length)].id] = heavy;
    }
    assert(tries < 500, 'no deal');
  }
}

/// The play state (pure logic).
class M4PhaseBalanceRun {
  M4PhaseBalanceRun(this.deal)
      : wired = {...deal.wired},
        plan = {...deal.wired};
  final M4PhaseBalanceDeal deal;
  M4PhaseBalanceStage stage = M4PhaseBalanceStage.measure;
  int slips = 0;
  int stageSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The stage is done and waits for its reason.
  var cleared = false;

  // --- hands on ---
  var gloves = false;
  M4PhaseBalanceTool tool = M4PhaseBalanceTool.none;
  final Map<int, int> readings = {};
  int? clampOn;

  // --- the chart ---
  /// What is connected on the bars now (load id → phase).
  Map<String, int> wired;

  /// The chart being planned (new connections join it).
  Map<String, int> plan;
  String? picked;

  // --- the work ---
  var told = false;
  var switchOn = true;
  var ptw = false;
  var proved = false;
  var earth = false;
  var shifted = false;

  bool get done => stage == M4PhaseBalanceStage.done;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// The stage went without a slip (+5 on the table).
  bool get thorough => stageSlips == 0;

  List<int> get liveAmps => m4PhaseBalanceAmps(deal.loads, wired);
  List<int> get planAmps => m4PhaseBalanceAmps(deal.loads, plan);

  /// The phase carrying the most now.
  int get heavyNow {
    final a = liveAmps;
    var h = 0;
    for (var p = 1; p < 3; p++) {
      if (a[p] > a[h]) h = p;
    }
    return h;
  }

  /// R, Y and B are read: the question is up (the neutral may still be missing).
  bool get readyToRead => stage == M4PhaseBalanceStage.measure && !cleared && [0, 1, 2].every(readings.containsKey);

  /// Every new connection has a phase on the chart.
  bool get planReady => deal.newLoads.every((l) => plan.containsKey(l.id));

  /// After the work, with the supply back: measuring again.
  bool get checking => stage == M4PhaseBalanceStage.work && shifted && switchOn;

  bool get _open => !ended && !cleared;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stageSlips++;
    return m;
  }

  void putGloves() {
    if (_open) gloves = true;
  }

  /// Picks up [t] (or puts it down, if held).
  void hold(M4PhaseBalanceTool t) {
    if (!_open) return;
    tool = tool == t ? M4PhaseBalanceTool.none : t;
    if (tool != M4PhaseBalanceTool.tong) clampOn = null;
  }

  /// The tong tester round outgoing cable [i] (0 R, 1 Y, 2 B, 3 N).
  DoMistake? clamp(int i) {
    if (!_open || tool != M4PhaseBalanceTool.tong) return null;
    if (stage != M4PhaseBalanceStage.measure && !checking) return null;
    if (!gloves) return _slip(M4PhaseBalanceMistakes.noGloves);
    clampOn = i;
    final a = liveAmps;
    readings[i] = !switchOn ? 0 : (i < 3 ? a[i] : m4PhaseBalanceNeutral(a));
    return null;
  }

  /// "[p] ফেজে ভার বেশি".
  DoMistake? answerHeavy(int p) {
    if (!_open || !readyToRead) return null;
    if (!readings.containsKey(3)) return _slip(M4PhaseBalanceMistakes.noNeutral);
    if (p != heavyNow) return _slip(M4PhaseBalanceMistakes.misread);
    cleared = true;
    tool = M4PhaseBalanceTool.none;
    clampOn = null;
    _tag(M4PhaseBalanceLines.caughtMeasure);
    _tag(M4PhaseBalanceLines.caughtHeavy);
    return null;
  }

  /// Taps a chip on the chart: picks it up, puts it down, or (with another
  /// one picked in another column) moves the picked one to this column.
  void tapChip(String id) {
    if (!_open || stage != M4PhaseBalanceStage.plan) return;
    final pk = picked;
    if (pk == null || pk == id) {
      picked = pk == id ? null : id;
      return;
    }
    final to = plan[id];
    if (to != null && to != plan[pk]) {
      moveTo(to);
    } else {
      picked = id;
    }
  }

  /// Moves the picked chip to phase [p].
  void moveTo(int p) {
    if (!_open || stage != M4PhaseBalanceStage.plan) return;
    final pk = picked;
    if (pk == null) return;
    plan = {...plan, pk: p};
    picked = null;
  }

  /// Listened to the coworker: every new connection goes on the heavy phase.
  DoMistake pileOn() {
    plan = {...plan, for (final l in deal.newLoads) l.id: deal.heavy};
    picked = null;
    return _slip(M4PhaseBalanceMistakes.pileOn);
  }

  /// "চার্ট ঠিক আছে". Null and [cleared] = a balanced chart.
  DoMistake? confirmPlan() {
    if (!_open || stage != M4PhaseBalanceStage.plan || !planReady) return null;
    if (_spread(planAmps) > kM4PhaseBalanceSpread) return _slip(M4PhaseBalanceMistakes.badPlan);
    cleared = true;
    picked = null;
    _tag(M4PhaseBalanceLines.caughtPlan);
    return null;
  }

  bool get _working => _open && stage == M4PhaseBalanceStage.work;

  void tell() {
    if (!_working || told) return;
    told = true;
    _tag(M4PhaseBalanceLines.caughtNotice);
  }

  /// The LT main's handle. Returns the mistake, if any; [switchOn] shows if it moved.
  DoMistake? toggleSwitch() {
    if (!_working) return null;
    if (switchOn) {
      if (!told) return _slip(M4PhaseBalanceMistakes.noNotice);
      switchOn = false;
    } else {
      if (earth || ptw) return _slip(M4PhaseBalanceMistakes.restoreEarly);
      switchOn = true;
    }
    proved = false;
    readings.clear();
    clampOn = null;
    return null;
  }

  /// Takes the PTW (switch OFF) or hands it back (earth off). False = not now.
  bool togglePtw() {
    if (!_working) return false;
    if (!ptw) {
      if (switchOn) return false;
      ptw = true;
    } else {
      if (earth) return false;
      ptw = false;
    }
    return true;
  }

  /// The tester on the bars: true = live.
  bool test() {
    if (_working && !switchOn) proved = true;
    return switchOn;
  }

  /// The earthing set on (proven dead first) or off.
  DoMistake? toggleEarth() {
    if (!_working) return null;
    if (earth) {
      earth = false;
      return null;
    }
    if (switchOn || !proved) return _slip(M4PhaseBalanceMistakes.noProve);
    earth = true;
    return null;
  }

  /// The spanner on the bars: the planned connections move.
  DoMistake? workBars() {
    if (!_working || tool != M4PhaseBalanceTool.spanner || shifted) return null;
    if (switchOn) return deadly = M4PhaseBalanceMistakes.shiftLive;
    if (!ptw) return _slip(M4PhaseBalanceMistakes.noPtw);
    if (!earth) return _slip(M4PhaseBalanceMistakes.noEarth);
    wired = {...plan};
    shifted = true;
    tool = M4PhaseBalanceTool.none;
    _tag(M4PhaseBalanceLines.caughtSafe);
    return null;
  }

  /// The record book: after measuring all four again.
  DoMistake? writeBook() {
    if (!_working || !checking) return null;
    if (readings.length < 4) return _slip(M4PhaseBalanceMistakes.noCheck);
    cleared = true;
    tool = M4PhaseBalanceTool.none;
    clampOn = null;
    _tag(M4PhaseBalanceLines.caughtCheck);
    _tag(M4PhaseBalanceLines.caughtBook);
    return null;
  }

  /// Fails the play (a deadly move).
  void failDeadly(DoMistake m) => deadly = m;

  /// On to the next stage (after the reason).
  void next() {
    stage = M4PhaseBalanceStage.values[stage.index + 1];
    stageSlips = 0;
    cleared = false;
    tool = M4PhaseBalanceTool.none;
    clampOn = null;
    picked = null;
    if (stage != M4PhaseBalanceStage.done) readings.clear();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   measure: gloves, tong, 4 clamps, answer ≈ 9000, reason ~8200   ≈ 17200
///   plan: ~5 moves × 2 taps ≈ 15000, confirm, the coworker ≈ 9600,
///     reason ~8200                                                ≈ 34300
///   work: tell, OFF, PTW, tester ~2500, earth, spanner, bars, earth,
///     PTW, ON, tong, 4 clamps, book ≈ 23500, reason ~8200          ≈ 31700
/// total ≈ 83200; 85 % ≈ 70700 → 70 s.
const kM4PhaseBalanceQuickMs = 70000;

@immutable
class M4PhaseBalancePack {
  const M4PhaseBalancePack({required this.id, required this.titleBn, this.quickMs = kM4PhaseBalanceQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4PhaseBalancePack> m4PhaseBalancePacks = {
  'do_4_10_a': M4PhaseBalancePack(id: 'do_4_10_a', titleBn: M4PhaseBalanceLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4PhaseBalancePage extends StatefulWidget {
  const M4PhaseBalancePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4PhaseBalancePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4PhaseBalancePage> createState() => _M4PhaseBalancePageState();
}

class _M4PhaseBalancePageState extends State<M4PhaseBalancePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _BalanceRunPage(
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

class _BalanceRunPage extends ConsumerStatefulWidget {
  const _BalanceRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4PhaseBalancePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_BalanceRunPage> createState() => _BalanceRunPageState();
}

class _BalanceRunPageState extends ConsumerState<_BalanceRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4PhaseBalanceRun _run = M4PhaseBalanceRun(dealM4PhaseBalance(widget.rng));
  late final CoworkerScript _coworker = M4PhaseBalanceLines.coworker(_run.deal.heavy);
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
  int _shiftTok = 0;

  /// The tester's lamp, a moment after it touches the bars.
  bool? _tester;
  Timer? _testerTimer;
  var _toldStamp = false;
  Timer? _toldTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The tool row's order this play (from the deal, so the deal itself stays
  /// the seed's).
  late final List<M4PhaseBalanceKit> _kitOrder =
      dealM4PhaseBalanceKit(math.Random(_run.deal.loads.fold<int>(_run.deal.heavy, (a, l) => (a * 31 + l.no) & 0x3fffffff)));

  // Gesture hints (how to touch, never what).
  final _hints = IdleHintController();
  final _sceneKey = GlobalKey();
  final Map<M4PhaseBalanceKit, GlobalKey> _kitKeys = {for (final k in M4PhaseBalanceKit.values) k: GlobalKey()};
  final List<GlobalKey> _phaseKeys = [for (var p = 0; p < 3; p++) GlobalKey()];
  final List<GlobalKey> _colKeys = [for (var p = 0; p < 3; p++) GlobalKey()];
  final Map<String, GlobalKey> _chipKeys = {};
  final _planOkKey = GlobalKey();
  M4PhaseBalanceGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _testerTimer?.cancel();
    _toldTimer?.cancel();
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
    _startStage();
  }

  /// The scene takes input. Not in the praise window or while the reason
  /// deck is up ([tableBusy]), nor while the coworker is on.
  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.cleared && !_freeze;

  String get _task {
    switch (_run.stage) {
      case M4PhaseBalanceStage.measure:
        return _run.readyToRead ? M4PhaseBalanceLines.askRead : M4PhaseBalanceLines.askMeasure;
      case M4PhaseBalanceStage.plan:
        return M4PhaseBalanceLines.askPlan;
      case M4PhaseBalanceStage.work:
        return _run.shifted ? M4PhaseBalanceLines.askNext : M4PhaseBalanceLines.askWork;
      case M4PhaseBalanceStage.done:
        return M4PhaseBalanceLines.askNext;
    }
  }

  void _startStage() {
    _testerTimer?.cancel();
    setState(() {
      _tester = null;
      _wake++;
    });
    if (_run.stage == M4PhaseBalanceStage.plan) scheduleCoworker();
    unawaited(_sayChain([_task]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _putGloves() {
    if (!_canPlay || _run.gloves) return;
    _tick('sounds/learn/tag_slap.ogg', 0.35);
    setState(() {
      _run.putGloves();
      _wake++;
    });
  }

  void _hold(M4PhaseBalanceTool t) {
    if (!_canPlay) return;
    _tick('sounds/quiz_select.ogg');
    setState(() {
      _run.hold(t);
      _wake++;
    });
  }

  void _tell() {
    if (!_canPlay || _run.told) return;
    _tick('sounds/learn/tag_slap.ogg', 0.4);
    _toldTimer?.cancel();
    setState(() {
      _run.tell();
      _toldStamp = true;
      _wake++;
    });
    _toldTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toldStamp = false);
    });
  }

  void _togglePtw() {
    if (!_canPlay) return;
    if (_run.togglePtw()) {
      _tick('sounds/learn/tag_slap.ogg', 0.5);
    } else {
      _tick('sounds/intro/click.ogg', 0.3);
    }
    setState(() => _wake++);
  }

  void _useTester() {
    if (!_canPlay) return;
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

  void _toggleEarth(Offset global) {
    if (!_canPlay) return;
    final m = _run.toggleEarth();
    _tick('sounds/intro/impact_metal.ogg', 0.4);
    setState(() => _wake++);
    if (m != null) unawaited(_mistake(m, global));
  }

  void _writeBook(Offset global) {
    if (!_canPlay) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    final m = _run.writeBook();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
    } else if (_run.cleared) {
      unawaited(_stageDone());
    }
  }

  void _tapScene(Offset p, M4PhaseBalanceGeo geo, Offset global) {
    if (!_canPlay) return;
    if (geo.handleHit.contains(p)) {
      if (_run.stage != M4PhaseBalanceStage.work) {
        _tick('sounds/intro/click.ogg', 0.3);
        _hints.missTap();
        return;
      }
      final was = _run.switchOn;
      final m = _run.toggleSwitch();
      setState(() => _wake++);
      if (m != null) {
        unawaited(_mistake(m, global));
      } else if (was != _run.switchOn) {
        _tick('sounds/intro/impact_metal.ogg', 0.6);
        if (_run.checking) unawaited(_sayChain([M4PhaseBalanceLines.askNext]));
      }
      return;
    }
    for (var i = 0; i < 4; i++) {
      if (geo.cableHit(i).contains(p)) {
        if (_run.tool != M4PhaseBalanceTool.tong) {
          _hints.missTap();
          return;
        }
        _tick('sounds/intro/click.ogg', 0.5);
        final wasReady = _run.readyToRead;
        final m = _run.clamp(i);
        setState(() => _wake++);
        if (m != null) {
          unawaited(_mistake(m, global));
        } else if (!wasReady && _run.readyToRead) {
          _cue('sounds/learn/card_deal_a.ogg', volume: 0.5);
          unawaited(_sayChain([M4PhaseBalanceLines.askRead]));
        }
        return;
      }
    }
    if (geo.barsHit.contains(p) && _run.tool == M4PhaseBalanceTool.spanner) {
      _tick('sounds/intro/impact_metal.ogg', 0.5);
      final m = _run.workBars();
      setState(() => _wake++);
      if (m != null) {
        unawaited(_mistake(m, global));
      } else if (_run.shifted) {
        _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
        setState(() => _shiftTok++);
        unawaited(_sayChain([M4PhaseBalanceLines.askNext]));
      }
      return;
    }
    // A tap on nothing that works now.
    _hints.missTap();
  }

  void _answer(int p, Offset origin) {
    if (!_canPlay || !_run.readyToRead) return;
    _hush();
    final m = _run.answerHeavy(p);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    unawaited(_stageDone());
  }

  void _tapChip(String id) {
    if (!_canPlay) return;
    _tick('sounds/quiz_select.ogg', 0.4);
    setState(() => _run.tapChip(id));
  }

  void _tapColumn(int p) {
    if (!_canPlay || _run.picked == null) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.4);
    setState(() => _run.moveTo(p));
  }

  void _confirmPlan(Offset origin) {
    if (!_canPlay || !_run.planReady) return;
    // The decisive control: he comes first if he has not yet (a fast chart
    // must not skip him).
    if (holdForCoworker()) return;
    final m = _run.confirmPlan();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
    } else if (_run.cleared) {
      unawaited(_stageDone());
    }
  }

  Future<void> _stageDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final s = _run.stage;
    unawaited(askReason(
      deal: () => dealChoices(M4PhaseBalanceLines.whyRight(s), M4PhaseBalanceLines.myths, widget.rng),
      question: M4PhaseBalanceLines.whyQuestion(s),
      stillValid: () => _run.stage == s && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startStage();
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
    final s = _run.stage;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.stage == s) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _freeze || _run.stage != M4PhaseBalanceStage.plan || _run.cleared) return null;
    if (_intro || _card != null || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: the new connections land on the heavy phase.
      final m = _run.pileOn();
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M4PhaseBalanceLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4PhaseBalanceLines.callHeld, M4PhaseBalanceLines.askPlan], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4PhaseBalanceLines.tapWhy[_nudgeN++ % M4PhaseBalanceLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('m4_phase_balance/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A spanner on live bars: the street freezes grey and the flash comes off
  /// the bars in colour; then near-miss or death.
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
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m4_phase_balance/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4PhaseBalanceLines.deadlyWord : M4PhaseBalanceLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same stage goes on from where it was.
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
        if (_popped) return;
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
    await _say(!_run.passed ? M4PhaseBalanceLines.fail : (_quickBonus ? M4PhaseBalanceLines.quick : M4PhaseBalanceLines.allSet),
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
    if (_run.cleared || _run.done) return LinemanMode.cheer;
    if (_run.tool != M4PhaseBalanceTool.none) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M4PhaseBalanceYard get _yard {
    final lugs = [0, 0, 0];
    for (final p in _run.wired.values) {
      lugs[p]++;
    }
    return M4PhaseBalanceYard(
      lugs: lugs,
      switchOn: _run.switchOn,
      ptw: _run.ptw,
      earthOn: _run.earth,
      clampOn: _run.clampOn,
      shiftTok: _shiftTok,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M4PhaseBalanceGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
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
                  key: const ValueKey('yard'),
                  child: RepaintBoundary(child: CustomPaint(painter: M4PhaseBalancePainter(geo: geo, yard: _yard, t: t, seed: 7))),
                ),
                Positioned.fromRect(
                  key: const ValueKey('trainee'),
                  rect: geo.trainee,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ],
            ),
          ),
        ),
      ),
      // The tester's lamp at the bars.
      if (_tester != null && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: geo.barX(0) - 16,
          top: geo.barTop - 46,
          child: IgnorePointer(child: _TesterChip(live: _tester!, quiet: quiet)),
        ),
      if (_toldStamp && !_freeze)
        Positioned(
          key: const ValueKey('told'),
          left: 40,
          right: 40,
          top: geo.pillar.top - 70,
          child: IgnorePointer(child: Center(child: _StampPop(text: M4PhaseBalanceLines.toldStamp, quiet: quiet, small: true))),
        ),
      if (_run.stage == M4PhaseBalanceStage.work && _run.cleared && !_freeze)
        Positioned(
          key: const ValueKey('stamp-done'),
          left: 100,
          width: 160,
          top: geo.pillar.top - 60,
          child: IgnorePointer(child: _StampPop(text: M4PhaseBalanceLines.stampDone, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4PhaseBalanceLines.sceneLabel,
          child: GestureDetector(key: _sceneKey, behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M4PhaseBalanceArcPainter(geo: geo, v: v)),
            ),
          ),
        ),
    ];
  }

  /// The tool buttons on the row now, in this play's dealt order.
  List<M4PhaseBalanceKit> get _kitNow {
    final r = _run;
    final Set<M4PhaseBalanceKit> on;
    if (r.stage == M4PhaseBalanceStage.measure) {
      on = {M4PhaseBalanceKit.gloves, M4PhaseBalanceKit.tong};
    } else if (r.checking) {
      on = {M4PhaseBalanceKit.gloves, M4PhaseBalanceKit.tong, M4PhaseBalanceKit.book};
    } else {
      on = {M4PhaseBalanceKit.notice, M4PhaseBalanceKit.ptw, M4PhaseBalanceKit.tester, M4PhaseBalanceKit.earth, M4PhaseBalanceKit.spanner};
    }
    return [for (final k in _kitOrder) if (on.contains(k)) k];
  }

  Widget _toolButton(M4PhaseBalanceKit k) {
    final r = _run;
    final key = _kitKeys[k];
    return switch (k) {
      M4PhaseBalanceKit.gloves => _ToolButton(key: key, icon: Icons.back_hand_rounded, label: M4PhaseBalanceLines.gloves, on: r.gloves, onTap: _putGloves),
      M4PhaseBalanceKit.tong =>
        _ToolButton(key: key, icon: Icons.speed_rounded, label: M4PhaseBalanceLines.tong, on: r.tool == M4PhaseBalanceTool.tong, onTap: () => _hold(M4PhaseBalanceTool.tong)),
      M4PhaseBalanceKit.book => _ToolButton(key: key, icon: Icons.menu_book_rounded, label: M4PhaseBalanceLines.book, on: false, onTapUp: _writeBook),
      M4PhaseBalanceKit.notice => _ToolButton(key: key, icon: Icons.campaign_rounded, label: M4PhaseBalanceLines.notice, on: r.told, onTap: _tell),
      M4PhaseBalanceKit.ptw => _ToolButton(key: key, icon: Icons.assignment_rounded, label: M4PhaseBalanceLines.ptw, on: r.ptw, onTap: _togglePtw),
      M4PhaseBalanceKit.tester => _ToolButton(key: key, icon: Icons.flash_on_rounded, label: M4PhaseBalanceLines.tester, on: _tester != null, onTap: _useTester),
      M4PhaseBalanceKit.earth => _ToolButton(key: key, icon: Icons.link_rounded, label: M4PhaseBalanceLines.earth, on: r.earth, onTapUp: _toggleEarth),
      M4PhaseBalanceKit.spanner => _ToolButton(
          key: key, icon: Icons.build_rounded, label: M4PhaseBalanceLines.spanner, on: r.tool == M4PhaseBalanceTool.spanner, onTap: () => _hold(M4PhaseBalanceTool.spanner)),
    };
  }

  Widget _tools() => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final k in _kitNow) _toolButton(k)]);

  // --- gesture hints -------------------------------------------------------------
  /// A scene rect (design px) in global pixels, through the touch layer.
  Rect? _sceneRect(Rect r) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return MatrixUtils.transformRect(box.getTransformTo(null), r);
  }

  /// What the hand sweeps over now: everything that can be touched, never one
  /// answer (a sweep over fewer than two things is no hint).
  HintSpec? _hint() {
    final r = _run;
    final geo = _geo;
    final rects = <Rect>[];
    void key(GlobalKey k) {
      final x = HintSpec.globalRectOf(k);
      if (x != null) rects.add(x);
    }

    void scene(Rect s) {
      final x = _sceneRect(s);
      if (x != null) rects.add(x);
    }

    if (r.stage == M4PhaseBalanceStage.plan) {
      if (r.picked != null) {
        _colKeys.forEach(key);
      } else {
        // The new ones in the tray, and the top chip of every column.
        for (final l in r.deal.newLoads) {
          if (!r.plan.containsKey(l.id)) key(_chipKeys.putIfAbsent(l.id, GlobalKey.new));
        }
        for (var p = 0; p < 3; p++) {
          for (final l in r.deal.loads) {
            if (r.plan[l.id] == p) {
              key(_chipKeys.putIfAbsent(l.id, GlobalKey.new));
              break;
            }
          }
        }
        if (r.planReady) key(_planOkKey);
      }
    } else if (r.readyToRead) {
      _phaseKeys.forEach(key);
      // The tong is still on: all 4 cables still read (N too), so they stay in
      // the sweep — never just the neutral, that would be the answer.
      if (geo != null && r.tool == M4PhaseBalanceTool.tong) {
        for (var i = 0; i < 4; i++) {
          scene(geo.cableHit(i));
        }
      }
    } else {
      for (final k in _kitNow) {
        key(_kitKeys[k]!);
      }
      if (geo != null) {
        if (r.tool == M4PhaseBalanceTool.tong) {
          for (var i = 0; i < 4; i++) {
            scene(geo.cableHit(i));
          }
        }
        if (r.stage == M4PhaseBalanceStage.work) scene(geo.handleHit);
        if (r.tool == M4PhaseBalanceTool.spanner) scene(geo.barsHit);
      }
    }
    return rects.length < 2 ? null : HintSpec.sweep(rects);
  }

  /// A new waiting state (resets the count of hints shown).
  String get _hintKey {
    final r = _run;
    return '${r.stage.index}-${r.readyToRead}-${r.tool.index}-${r.checking}-${r.picked != null}-${r.planReady}';
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.cleared && !deckUp && !coworkerOpen && _card == null;
    final stage = _run.stage;
    final planUp = playing && stage == M4PhaseBalanceStage.plan && !_run.cleared && _card == null;
    final readUp = playing && _card == null && (stage == M4PhaseBalanceStage.measure || _run.checking) && !reasonOpen;
    final guideBottom = pad.bottom + (deckUp ? 236 : (planUp ? 72 : 84));
    final hintWaiting = handsOn && !tableBusy && !_ended;
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
              labels: M4PhaseBalanceLines.rounds,
              done: {for (var i = 0; i < math.min(stage.index, 3); i++) i},
              current: _run.done ? null : stage.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen && !planUp)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 96,
                  child: const IgnorePointer(child: _DocketChip()),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (readUp)
                Positioned(
                  key: const ValueKey('readings'),
                  right: 12,
                  top: pad.top + 96,
                  width: 132,
                  child: IgnorePointer(child: _ReadingsCard(readings: {..._run.readings})),
                ),
              if (handsOn && _run.readyToRead)
                Positioned(
                  key: const ValueKey('hud-read'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      for (var p = 0; p < 3; p++) ...[
                        if (p > 0) const SizedBox(width: 8),
                        Expanded(
                          child: KeyedSubtree(
                            key: _phaseKeys[p],
                            child: DoBigButton(label: M4PhaseBalanceLines.phaseBtn(p), filled: true, onTapUp: (d) => _answer(p, d.globalPosition)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (handsOn && !_run.readyToRead && stage != M4PhaseBalanceStage.plan)
                Positioned(
                  key: ValueKey('hud-tools-${stage.name}-${_run.checking}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: _tools(),
                ),
              if (planUp)
                Positioned(
                  key: const ValueKey('plan'),
                  left: 10,
                  right: 10,
                  top: pad.top + 92,
                  bottom: pad.bottom + 196,
                  child: _PlanBoard(
                    loads: _run.deal.loads,
                    plan: _run.plan,
                    picked: _run.picked,
                    amps: _run.planAmps,
                    onChip: _tapChip,
                    onColumn: _tapColumn,
                    quiet: quiet,
                    chipKeys: _chipKeys,
                    colKeys: _colKeys,
                  ),
                ),
              if (planUp && !deckUp)
                Positioned(
                  key: const ValueKey('hud-plan'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Opacity(
                    key: _planOkKey,
                    opacity: _run.planReady ? 1 : 0.45,
                    child: DoBigButton(label: M4PhaseBalanceLines.planOk, filled: true, onTapUp: (d) => _confirmPlan(d.globalPosition)),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: guideBottom, onLeft: !coworkerOnScreen || coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${stage.index}-$strikes'),
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
                  line: M4PhaseBalanceLines.intro,
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

class _DocketChip extends StatelessWidget {
  const _DocketChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
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
          Text(M4PhaseBalanceLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4PhaseBalanceLines.docketJob, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// The tong tester's readings as he notes them: R, Y, B, N in amperes.
class _ReadingsCard extends StatelessWidget {
  const _ReadingsCard({required this.readings});
  final Map<int, int> readings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFC94A), Color(0xFFE09A16)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B4A0C), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M4PhaseBalanceLines.readings, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2500))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFF9FB89A), borderRadius: BorderRadius.circular(6)),
            child: Column(
              children: [
                for (var i = 0; i < 4; i++)
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: m4PhaseBalanceWireColors[i], shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(m4PhaseBalanceWireNames[i], style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16200F))),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(readings[i] == null ? '—' : '${readings[i]} A',
                              key: ValueKey('reading-$i'),
                              style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF16200F))),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The phase chart: three columns R · Y · B with the consumers on each and
/// the column totals, the new connections in a tray on top. Tap a chip to
/// pick it, then a column (or a chip in it) to move it there.
class _PlanBoard extends StatelessWidget {
  const _PlanBoard({
    required this.loads,
    required this.plan,
    required this.picked,
    required this.amps,
    required this.onChip,
    required this.onColumn,
    required this.quiet,
    required this.chipKeys,
    required this.colKeys,
  });

  final List<M4PhaseBalanceLoad> loads;
  final Map<String, int> plan;
  final String? picked;
  final List<int> amps;
  final ValueChanged<String> onChip;
  final ValueChanged<int> onColumn;
  final bool quiet;

  /// Gesture-hint anchors (the page's).
  final Map<String, GlobalKey> chipKeys;
  final List<GlobalKey> colKeys;

  Widget _chip(M4PhaseBalanceLoad l) {
    final on = picked == l.id;
    return Semantics(
      key: chipKeys.putIfAbsent(l.id, GlobalKey.new),
      button: true,
      label: 'chip-${l.id}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('chip-${l.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onChip(l.id),
        child: AnimatedContainer(
          duration: Duration(milliseconds: quiet ? 0 : 160),
          height: 26,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFFFE08A) : (l.isNew ? const Color(0xFFDDF3DF) : const Color(0xFFF7F3E8)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: on ? const Color(0xFFB07A00) : const Color(0xFF8A7A55), width: on ? 2.2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(l.isNew ? M4PhaseBalanceLines.newChip : '${l.no}',
                    maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF3D3420))),
              ),
              Text('${l.amps}A', style: const TextStyle(fontFamily: 'Roboto', fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF2B2416))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tray = [for (final l in loads) if (l.isNew && !plan.containsKey(l.id)) l];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xF2E9E2CC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6B5B3A), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text(M4PhaseBalanceLines.chart, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          if (tray.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              key: const ValueKey('tray'),
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
              decoration: BoxDecoration(color: const Color(0x3348A858), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Text(M4PhaseBalanceLines.newTray, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E5A2A))),
                  const SizedBox(width: 8),
                  for (final l in tray) ...[SizedBox(width: 74, child: _chip(l)), const SizedBox(width: 6)],
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var p = 0; p < 3; p++) ...[
                  if (p > 0) const SizedBox(width: 6),
                  Expanded(
                    key: colKeys[p],
                    child: GestureDetector(
                      key: ValueKey('col-$p'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onColumn(p),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        decoration: BoxDecoration(
                          color: picked != null && plan[picked] != p ? const Color(0x22FFC233) : const Color(0x14000000),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: m4PhaseBalanceWireColors[p].withValues(alpha: 0.8), width: 1.4),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: m4PhaseBalanceWireColors[p], borderRadius: BorderRadius.circular(5)),
                              child: Text(m4PhaseBalancePhases[p],
                                  style: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w900, color: p == 1 ? const Color(0xFF3A2A00) : Colors.white)),
                            ),
                            const SizedBox(height: 3),
                            // One colour for every total: no "still heavy" mark
                            // that would announce a balanced chart.
                            Text('${M4PhaseBalanceLines.total} ${amps[p]}A',
                                key: ValueKey('total-$p'), style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
                            const SizedBox(height: 4),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(children: [for (final l in loads) if (plan[l.id] == p) _chip(l)]),
                              ),
                            ),
                          ],
                        ),
                      ),
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
            Text(live ? M4PhaseBalanceLines.testerLive : M4PhaseBalanceLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, this.onTap, this.onTapUp});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onTapUp;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          onTap?.call();
          onTapUp?.call(d.globalPosition);
        },
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
  const _StampPop({required this.text, required this.quiet, this.small = false});
  final String text;
  final bool quiet;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.08, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: small ? 15 : 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
