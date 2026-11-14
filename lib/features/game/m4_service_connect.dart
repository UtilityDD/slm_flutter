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
import 'm4_service_connect_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 4.3 "নতুন সার্ভিস কানেকশন দেওয়া", কাজ 2 "সংযোগ দাও" (pack do_4_3_b,
// engineType m4_service_connect). Three new houses a play. At each the GI
// bearer wire is already up (that is কাজ 1) and the service cable lies along
// it; the trainee makes the connection itself, pole to meter.
//
// The lesson's rules, and only those:
//   • point 2: strap the service cable to the bearer wire, evenly; at the
//     house make a drip loop and connect to the meter's incoming terminals;
//     at the pole connect to the LT line with an IPC (no stripping);
//   • pro tip 2: tighten the IPC's nut until its shear head breaks off;
//   • pro tip 3: mark phase and neutral and put each on its right terminal;
//   • point 3: check every joint is tight; fit the pole fuse, then measure
//     230-240 V at the meter's incoming terminals with a multimeter; then
//     explain the meter and main switch to the consumer;
//   • pro tip 4: clear the cable offcuts before you leave;
//   • myth 1: no cable without the bearer wire; myth 2: no stripped-and-
//     twisted joint instead of an IPC.
// From the module's safety rules (the brief, NOT lesson 4.3's text — flagged
// in REGISTER.md): helmet + harness for any work on the pole; work on the LT
// line only under shutdown (PTW), proven dead with a tester and earthed; the
// earth off before the line comes back. The order "house end first, the pole
// last" follows the lesson's order of point 2 (and keeps the cable dead while
// it is worked on) — flagged too.
//
// Hands on: স্ট্র্যাপ (tap the span) · the cable at the wall (the drip loop) ·
// the marked cores L / N into the meter's L / N terminals (the meter's
// layout is dealt) · হারনেস (up the pole) · শাটডাউন (take / give back) ·
// টেস্টার · আর্থ · IPC (a core, then its conductor — the LT marks R Y B N are
// dealt top/bottom; then tap the IPC to tighten it till the head shears) ·
// প্লায়ার্স (the trap: strip and twist) · ফিউজ · মাল্টিমিটার (read it) ·
// the offcuts on the ground · বুঝিয়ে দিন.
//
// Deadly: a tool or the earth set on the LT line without the shutdown.
// Slips: no harness, things out of order, no drip loop, phase/neutral on the
// wrong terminal or conductor (also by listening to the coworker), the IPC
// before proving dead or before the earth, a twisted joint, an IPC not
// sheared, the earth left on, a misread multimeter, handing over untested or
// with offcuts lying about. Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_service_connect_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next house by itself; the careless coworker once a play, at
// the meter. Voice: the guide by device TTS; the coworker's new push by
// device TTS until recorded (his exit line is his existing recorded clip).
//
// Audit 2026-11-11: hands off in the praise window (tableBusy); he cuts in on
// the first core at the meter (holdForCoworker) and stays away once a core is
// in (his push no longer fits); the tool bar is dealt out of the job's order;
// each reason is dealt with its own myth; gesture hints sweep over the tools,
// the reading buttons, or the terminals / conductors once a core is picked.

// ============================================================================
// Content
// ============================================================================

/// What the reason question asks about.
enum M4ServiceConnectWhy { strap, drip, pn, dead, ipc, test }

/// The tools held in the hand.
enum M4ServiceConnectTool { none, strap, ipc, pliers }

@immutable
class M4ServiceConnectSite {
  const M4ServiceConnectSite({
    required this.id,
    required this.ltOrder,
    required this.meterLeftIsL,
    required this.volts,
    required this.scraps,
    required this.why,
  });
  final String id;

  /// The LT conductors top → bottom: 0 R, 1 Y, 2 B, 3 N.
  final List<int> ltOrder;

  /// The meter's left incoming terminal is L (else N).
  final bool meterLeftIsL;

  /// What the multimeter reads at the meter once the supply is on (230-240).
  final int volts;

  /// Where the cable offcuts lie (x, design px).
  final List<double> scraps;
  final M4ServiceConnectWhy why;
}

abstract final class M4ServiceConnectLines {
  static const title = 'সংযোগ দাও';
  static const intro = 'নতুন বাড়িতে আলো দিন! পোল থেকে মিটার — নিয়ম মেনে সংযোগ দিন।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askWork = 'নতুন সংযোগ — নিয়ম মেনে জুড়ুন।';
  static const askLive = 'জোড়া শেষ — এবার কী?';
  static const askHand = 'বুঝিয়ে দেওয়ার আগে সব ঠিক?';
  static const askRead = 'মাল্টিমিটার কী বলছে?';
  static const tasks = [askWork, askLive, askHand, askRead];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (tools, the docket, the meter).
  static const sceneLabel = 'নতুন সার্ভিস লাইন';
  static const strap = 'স্ট্র্যাপ';
  static const ipc = 'IPC';
  static const pliers = 'প্লায়ার্স';
  static const harness = 'হারনেস';
  static const shutdown = 'শাটডাউন';
  static const tester = 'টেস্টার';
  static const earth = 'আর্থ';
  static const fuse = 'ফিউজ';
  static const multimeter = 'মাল্টিমিটার';
  static const handover = 'বুঝিয়ে দিন';
  static const sayOk = 'ভোল্টেজ ঠিক আছে';
  static const sayNone = 'ভোল্টেজ আসেনি';
  static const docket = 'ডকেট';
  static const docketJob = 'নতুন সার্ভিস কানেকশন';
  static const docketPtw = 'শাটডাউন · পারমিট (PTW)';
  static const testerLive = 'লাইভ';
  static const testerDead = '0 V';
  static const stampLit = 'আলো জ্বলল';

  // The reasons (lesson 4.3): the right ones fit what was done on every
  // site; the wrong ones are the lesson's myths and field excuses — never a
  // true rule marked wrong. Every card 37–47 letters. Each question deals its
  // own myth(s) (they share its key words — জিআই, মিটারের মুখে/ড্রিপ লুপ,
  // চিহ্ন, আগে/শাটডাউন/আর্থ, IPC/হেড, ভোল্টেজ/V), so no word of the question
  // shows up only on the right card.
  static const whyStrapQ = 'কেন কেবিলটা জিআই তারের সাথে বাঁধলেন?';
  static const whyDripQ = 'কেন মিটারের মুখে ড্রিপ লুপ দিলেন?';
  static const whyPnQ = 'কেন ফেজ-নিউট্রাল চিহ্ন দেখে লাগালেন?';
  static const whyDeadQ = 'কেন আগে শাটডাউন নিয়ে আর্থ দিলেন?';
  static const whyIpcQ = 'কেন পোলে IPC দিয়ে জুড়লেন?';
  static const whyTestQ = 'কেন মিটারে ভোল্টেজ মেপে নিলেন?';
  static const strapWhy = ['সব টান বিয়ারার জিআই তার নেয়, কেবিল নয়', 'জিআই তার ছাড়া কেবিল ঝড়ে ঝুলে বা ছিঁড়ে পড়ে'];
  static const dripWhy = ['ড্রিপ লুপে জল গড়িয়ে নামে, মিটারে ঢোকে না', 'মিটারের মুখে জল আটকাতেই ড্রিপ লুপ দিতে হয়'];
  static const pnWhy = ['ফেজ-নিউট্রাল ভুল টার্মিনালে গেলে বিপদ ঘটে', 'চিহ্ন দেখে L-এ ফেজ, N-এ নিউট্রাল লাগাতে হয়'];
  static const deadWhy = ['চালু এলটি লাইনে হাত দিলে শক, তাই আগে শাটডাউন', 'শাটডাউন, টেস্টারে মৃত, আর্থ — তবেই লাইনে হাত'];
  static const ipcWhy = ['IPC-তে ইনসুলেশন ছিলতে হয় না, জোড় জলরোধী', 'শেয়ার হেড ভেঙে পড়া মানে টর্ক ঠিক হয়েছে'];
  static const testWhy = ['ইনকামিং টার্মিনালে 230-240 V এলে তবেই ঠিক', 'ফিউজ লাগিয়ে ভোল্টেজ মেপে তবে সংযোগ চালু'];
  static const mythStrap = 'কেবিল নিজেই মজবুত, জিআই তারের দরকার নেই';
  static const mythTwist = 'IPC লাগে না, ছিলে পেঁচালেই জোড় পাকা হয়';
  static const mythPn = 'ফেজ-নিউট্রাল যেদিকেই দিন, চিহ্ন দেখা লাগে না';
  static const mythNut = 'IPC-র নাট হাতে টাইট দিলেই হলো, হেড ভাঙা লাগে না';
  static const mythRush = 'গ্রাহক তাড়া দিচ্ছিলেন, তাই ঝটপট সেরে দিলাম';
  static const mythDrip = 'মিটারের মুখে ড্রিপ লুপ শুধু দেখতে সুন্দর বলে';
  static const mythNoTest = 'বাড়িতে আলো জ্বললেই ভোল্টেজ মাপার দরকার নেই';
  static const mythNoShutdown = 'এলটি লাইনে আগে শাটডাউন-আর্থ লাগে না, ধরলেই চলে';
  static const mythLowVolt = 'মিটারে 150 V এলেও চলে, আলো তো জ্বলবেই';
  static const myths = [mythStrap, mythTwist, mythPn, mythNut, mythRush, mythDrip, mythNoTest, mythNoShutdown, mythLowVolt];
  static const allRight = [...strapWhy, ...dripWhy, ...pnWhy, ...deadWhy, ...ipcWhy, ...testWhy];

  /// The myths that answer the same question (always dealt with it).
  static List<String> topicMyths(M4ServiceConnectWhy w) => switch (w) {
        M4ServiceConnectWhy.strap => const [mythStrap],
        M4ServiceConnectWhy.drip => const [mythDrip],
        M4ServiceConnectWhy.pn => const [mythPn],
        M4ServiceConnectWhy.dead => const [mythNoShutdown],
        M4ServiceConnectWhy.ipc => const [mythTwist, mythNut],
        M4ServiceConnectWhy.test => const [mythNoTest, mythLowVolt],
      };

  /// The two wrong cards for [s]'s question: its own myth(s), topped up with
  /// one other myth.
  static List<String> whyWrong(M4ServiceConnectSite s, math.Random rng) {
    final own = topicMyths(s.why);
    if (own.length >= 2) return [...own];
    final rest = [for (final m in myths) if (!own.contains(m)) m]..shuffle(rng);
    return [...own, rest.first];
  }

  static List<String> whyRight(M4ServiceConnectSite s) => switch (s.why) {
        M4ServiceConnectWhy.strap => strapWhy,
        M4ServiceConnectWhy.drip => dripWhy,
        M4ServiceConnectWhy.pn => pnWhy,
        M4ServiceConnectWhy.dead => deadWhy,
        M4ServiceConnectWhy.ipc => ipcWhy,
        M4ServiceConnectWhy.test => testWhy,
      };
  static String whyQuestion(M4ServiceConnectSite s) => switch (s.why) {
        M4ServiceConnectWhy.strap => whyStrapQ,
        M4ServiceConnectWhy.drip => whyDripQ,
        M4ServiceConnectWhy.pn => whyPnQ,
        M4ServiceConnectWhy.dead => whyDeadQ,
        M4ServiceConnectWhy.ipc => whyIpcQ,
        M4ServiceConnectWhy.test => whyTestQ,
      };

  /// The careless coworker: any core on any terminal.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'ফেজ-নিউট্রাল যেকোনোটা যেকোনো দিকে লাগাও! আলো তো জ্বলবেই।',
    exitLine: coworkerExit,
    // Not every refusal opens with "না", and its key words (চিহ্ন, টার্মিনাল,
    // বিপদ, L/N) show up on the listening cards too.
    right: ['না, চিহ্ন দেখে L-এ ফেজ, N-এ নিউট্রাল', 'ভুল টার্মিনালে লাগালে বিপদ, দেখে দেব', 'চিহ্ন মিলিয়ে ঠিক ঘরে ঠিক তার দেব'],
    wrong: [
      'ঠিক, যেকোনো টার্মিনালে যেকোনোটা দিই',
      'আচ্ছা, L-N যা-ই হোক, আলো জ্বলবেই',
      'হ্যাঁ, চিহ্ন দেখার সময় কোথায় এখন',
      'বিপদ কিছু নেই, যেদিক খুশি লাগাই',
      'হ্যাঁ, দুটো তারই তো দেখতে একই',
    ],
    asks: ['ও বলছে যেকোনো দিকে লাগাতে। কী করবেন?', 'ওর কথা শুনবেন, না চিহ্ন?', 'ফেজ-নিউট্রাল যেদিক খুশি দেবেন?'],
  );

  static const callHeld = 'ঠিক! ফেজ-নিউট্রাল সবসময় চিহ্ন দেখে।';
  static const allSet = 'তিন বাড়িতে আলো — নিয়ম মেনে, নিরাপদে!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — বাঁধুন, মিটার, তারপর নিরাপদে পোলে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtStrap = 'কেবিল বিয়ারার তারে বেঁধেছেন';
  static const caughtDrip = 'মিটারের মুখে ড্রিপ লুপ';
  static const caughtPn = 'ফেজ-নিউট্রাল ঠিক টার্মিনালে';
  static const caughtDead = 'শাটডাউন, টেস্টার, আর্থ — তবে লাইনে';
  static const caughtIpc = 'IPC — শেয়ার হেড ভাঙা পর্যন্ত টাইট';
  static const caughtTest = 'মিটারে ভোল্টেজ মেপে চালু';
  static const caughtClean = 'কাজের জায়গা পরিষ্কার';
  static const caughtCall = 'ফেজ-নিউট্রাল নিয়ে “না” বলেছেন';
}

abstract final class M4ServiceConnectMistakes {
  static const _dir = 'assets/game/art/m4_service_connect';
  static const _p = '4.3/m4_service_connect';

  static const liveLine = DoMistake(
    key: '$_p/live-lt',
    textBn: 'চালু এলটি লাইনে হাত বা আর্থ নয়! আগে শাটডাউন, টেস্টারে মৃত প্রমাণ, আর্থ — তবে IPC।',
    art: '$_dir/live_line.svg',
    deadly: true,
  );
  // Harness, shutdown, proving dead and the earth come from the module's
  // safety rules (the brief), not lesson 4.3's text: no lesson point.
  static const noHarness = DoMistake(
    key: '$_p/no-harness',
    textBn: 'পোলে কাজ মানেই হেলমেট আর হারনেস — আগে হারনেস বেঁধে তবে ওপরে।',
    art: '$_dir/harness.svg',
  );
  static const noProve = DoMistake(
    key: '$_p/not-proven-dead',
    textBn: 'শাটডাউন নিলেই হলো না — টেস্টারে দেখুন লাইন সত্যিই মৃত, তবে আর্থ আর কাজ।',
    art: '$_dir/prove_earth.svg',
  );
  static const noEarth = DoMistake(
    key: '$_p/no-earth',
    textBn: 'মৃত প্রমাণের পর লাইনে আর্থ দিন — তবেই IPC লাগানো।',
    art: '$_dir/prove_earth.svg',
  );
  static const earthOn = DoMistake(
    key: '$_p/earth-left-on',
    textBn: 'আর্থ লাগানো রেখে লাইন বা ফিউজ চালু নয় — আগে আর্থ খুলুন।',
    art: '$_dir/prove_earth.svg',
  );
  static const strapFirst = DoMistake(
    key: '$_p/strap-first',
    textBn: 'আগে সার্ভিস কেবিলটা জিআই সাপোর্ট তারের সাথে সমান দূরত্বে বাঁধুন — সব টান ওই তার নেবে।',
    art: '$_dir/order.svg',
    lessonPoint: 2,
  );
  static const poleFirst = DoMistake(
    key: '$_p/pole-before-meter',
    textBn: 'আগে গ্রাহকের মিটারের দিক জুড়ুন — পোলে সংযোগ সবার শেষে।',
    art: '$_dir/order.svg',
    lessonPoint: 2,
  );
  static const noDrip = DoMistake(
    key: '$_p/no-drip-loop',
    textBn: 'মিটারে জোড়ার আগে কেবিলে ড্রিপ লুপ দিন — নইলে কেবিল বেয়ে জল মিটারে ঢুকবে।',
    art: '$_dir/drip_loop.svg',
    lessonPoint: 2,
  );
  static const pnSwap = DoMistake(
    key: '$_p/phase-neutral-swap',
    textBn: 'ফেজ-নিউট্রাল উল্টো! চিহ্ন দেখে L কোর L-এ, N কোর N-এ — ভুল সংযোগ বিপদ ঘটায়।',
    art: '$_dir/phase_neutral.svg',
    lessonPoint: 2,
  );
  static const twistJoint = DoMistake(
    key: '$_p/twisted-joint',
    textBn: 'ইনসুলেশন ছিলে তার পেঁচানো নয় — জলরোধী হয় না, লুজ হয়ে পোড়ে। IPC দিয়ে জুড়ুন।',
    art: '$_dir/ipc.svg',
    lessonPoint: 2,
  );
  static const looseIpc = DoMistake(
    key: '$_p/ipc-not-sheared',
    textBn: 'IPC-র নাট ততক্ষণ টাইট দিন, যতক্ষণ না ওপরের শেয়ার হেড নিজে থেকে ভেঙে পড়ে।',
    art: '$_dir/ipc.svg',
    lessonPoint: 2,
  );
  static const misread = DoMistake(
    key: '$_p/misread',
    textBn: 'মাল্টিমিটার ভুল পড়লেন। সিঙ্গেল-ফেজে 230-240 V এলে ঠিক; 0 V মানে সাপ্লাই আসেনি।',
    art: '$_dir/volt_test.svg',
    lessonPoint: 3,
  );
  static const noTest = DoMistake(
    key: '$_p/untested',
    textBn: 'বুঝিয়ে দেওয়ার আগে ফিউজ লাগিয়ে মিটারের ইনকামিং টার্মিনালে ভোল্টেজ মাপুন।',
    art: '$_dir/volt_test.svg',
    lessonPoint: 3,
  );
  static const mess = DoMistake(
    key: '$_p/offcuts-left',
    textBn: 'কেবিলের টুকরো পড়ে আছে! কাজ শেষে সব কুড়িয়ে জায়গা পরিষ্কার করুন।',
    art: '$_dir/clean_up.svg',
  );

  static const all = [liveLine, noHarness, noProve, noEarth, earthOn, strapFirst, poleFirst, noDrip, pnSwap, twistJoint, looseIpc, misread, noTest, mess];
}

@immutable
class M4ServiceConnectDeal {
  const M4ServiceConnectDeal({required this.sites, required this.callAt});
  final List<M4ServiceConnectSite> sites;

  /// The house the careless coworker comes to.
  final int callAt;
}

/// Three houses: each asks a different reason; the meter's L/N layout, the
/// LT marks (N on top or at the bottom, the phases in any order), the volts
/// and where the offcuts lie are dealt; both meter layouts come up.
M4ServiceConnectDeal m4ServiceConnectDeal(math.Random rng) {
  final whys = [...M4ServiceConnectWhy.values]..shuffle(rng);
  final firstL = rng.nextBool();
  final layouts = [firstL, !firstL, rng.nextBool()]..shuffle(rng);
  final sites = <M4ServiceConnectSite>[
    for (var i = 0; i < 3; i++)
      () {
        final phases = [0, 1, 2]..shuffle(rng);
        final scraps = [...M4ServiceConnectGeo.scrapXs]..shuffle(rng);
        return M4ServiceConnectSite(
          id: 's$i',
          ltOrder: rng.nextBool() ? [3, ...phases] : [...phases, 3],
          meterLeftIsL: layouts[i],
          volts: 230 + rng.nextInt(11),
          scraps: (scraps.take(2).toList()..sort()),
          why: whys[i],
        );
      }(),
  ];
  return M4ServiceConnectDeal(sites: sites, callAt: rng.nextInt(3));
}

/// The play state (pure logic).
class M4ServiceConnectRun {
  M4ServiceConnectRun(this.deal);
  final M4ServiceConnectDeal deal;
  int index = 0;
  int slips = 0;
  int siteSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // --- this house ---
  M4ServiceConnectTool tool = M4ServiceConnectTool.none;
  var strapped = false;
  var drip = false;
  final Set<int> houseIn = {};
  int? selHouse;
  var harness = false;
  var shutdown = false;
  var proved = false;
  var earthed = false;

  /// Per core (0 = L, 1 = N): (conductor row, fit order).
  final Map<int, (int, int)> ipcs = {};
  final Set<int> sheared = {};
  int? selPole;
  var fuseIn = false;
  var readingUp = false;
  int reading = 0;
  var measured = false;
  final List<double> scraps = [];
  var handedOver = false;

  bool get done => index >= deal.sites.length;
  bool get ended => done || deadly != null;
  M4ServiceConnectSite get site => deal.sites[index.clamp(0, deal.sites.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Done this house without a slip (+5 on the table).
  bool get thorough => siteSlips == 0;

  bool get meterDone => houseIn.length == 2;
  bool get poleDone => ipcs.length == 2 && sheared.length == 2;

  /// An IPC on the line whose shear head has not broken off yet.
  bool get loose => ipcs.keys.any((c) => !sheared.contains(c));

  /// The offcuts lie on the ground once the cores are trimmed into the meter.
  List<double> get scrapsShown => meterDone ? scraps : const [];

  /// Whether conductor row [k] is the neutral.
  bool isNeutral(int k) => site.ltOrder[k] == 3;

  /// Whether the meter's terminal [i] (0 left, 1 right) is L.
  bool terminalIsL(int i) => (i == 0) == site.meterLeftIsL;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    siteSlips++;
    return m;
  }

  bool get _open => !ended && !handedOver && !readingUp;

  /// Picks up [t] (or puts it down, if held).
  void hold(M4ServiceConnectTool t) {
    if (!_open) return;
    tool = tool == t ? M4ServiceConnectTool.none : t;
  }

  // --- the span and the house end ---
  /// The span with the strap in hand: the cable is bound to the bearer.
  bool tapSpan() {
    if (!_open || tool != M4ServiceConnectTool.strap || strapped) return false;
    strapped = true;
    tool = M4ServiceConnectTool.none;
    _tag(M4ServiceConnectLines.caughtStrap);
    return true;
  }

  /// The cable where it comes down the wall: makes the drip loop.
  DoMistake? tapEntry() {
    if (!_open || harness || drip) return null;
    if (!strapped) return _slip(M4ServiceConnectMistakes.strapFirst);
    drip = true;
    _tag(M4ServiceConnectLines.caughtDrip);
    return null;
  }

  /// A core's end at the meter (0 = L, 1 = N).
  DoMistake? tapHouseCore(int c) {
    if (!_open || harness || houseIn.contains(c)) return null;
    if (!strapped) return _slip(M4ServiceConnectMistakes.strapFirst);
    if (!drip) return _slip(M4ServiceConnectMistakes.noDrip);
    selHouse = selHouse == c ? null : c;
    return null;
  }

  /// A meter incoming terminal (0 left, 1 right), with a core picked.
  DoMistake? tapTerminal(int i) {
    final c = selHouse;
    if (!_open || harness || c == null) return null;
    selHouse = null;
    if (terminalIsL(i) != (c == 0)) return _slip(M4ServiceConnectMistakes.pnSwap);
    houseIn.add(c);
    if (meterDone) {
      _tag(M4ServiceConnectLines.caughtPn);
      if (scraps.isEmpty) scraps.addAll(site.scraps);
    }
    return null;
  }

  /// Listening to the coworker: a core goes on the wrong terminal.
  DoMistake listen() => _slip(M4ServiceConnectMistakes.pnSwap);

  // --- the pole end ---
  /// Harness on = up the pole; off = down (not with a loose IPC).
  DoMistake? toggleHarness() {
    if (!_open) return null;
    if (!harness) {
      harness = true;
      selHouse = null;
      return null;
    }
    if (loose) return _slip(M4ServiceConnectMistakes.looseIpc);
    harness = false;
    selPole = null;
    return null;
  }

  /// Take the shutdown (PTW) or give it back (not with the earth on or a loose IPC).
  DoMistake? toggleShutdown() {
    if (!_open) return null;
    if (!shutdown) {
      shutdown = true;
      proved = false;
      measured = false;
      return null;
    }
    if (earthed) return _slip(M4ServiceConnectMistakes.earthOn);
    if (loose) return _slip(M4ServiceConnectMistakes.looseIpc);
    shutdown = false;
    proved = false;
    return null;
  }

  /// The tester on the LT line. Returns (mistake, live).
  (DoMistake?, bool) test() {
    if (!_open) return (null, false);
    if (!harness) return (_slip(M4ServiceConnectMistakes.noHarness), false);
    if (shutdown) proved = true;
    return (null, !shutdown);
  }

  /// The earth set on (or off) the LT line.
  DoMistake? toggleEarth() {
    if (!_open) return null;
    if (!harness) return _slip(M4ServiceConnectMistakes.noHarness);
    if (earthed) {
      earthed = false;
      return null;
    }
    if (!shutdown) return deadly = M4ServiceConnectMistakes.liveLine;
    if (!proved) return _slip(M4ServiceConnectMistakes.noProve);
    earthed = true;
    return null;
  }

  /// A core's end at the pole (0 = L, 1 = N).
  DoMistake? tapPoleCore(int c) {
    if (!_open || ipcs.containsKey(c)) return null;
    if (!harness) return _slip(M4ServiceConnectMistakes.noHarness);
    selPole = selPole == c ? null : c;
    return null;
  }

  /// LT conductor row [k] with the tool in hand.
  DoMistake? tapConductor(int k) {
    if (!_open) return null;
    if (tool != M4ServiceConnectTool.ipc && tool != M4ServiceConnectTool.pliers) return null;
    if (!harness) return _slip(M4ServiceConnectMistakes.noHarness);
    if (!shutdown) return deadly = M4ServiceConnectMistakes.liveLine;
    if (!proved) return _slip(M4ServiceConnectMistakes.noProve);
    if (!earthed) return _slip(M4ServiceConnectMistakes.noEarth);
    if (!meterDone) return _slip(M4ServiceConnectMistakes.poleFirst);
    if (tool == M4ServiceConnectTool.pliers) {
      tool = M4ServiceConnectTool.none;
      return _slip(M4ServiceConnectMistakes.twistJoint);
    }
    final c = selPole;
    if (c == null || ipcs.containsKey(c)) return null;
    selPole = null;
    if (isNeutral(k) != (c == 1)) return _slip(M4ServiceConnectMistakes.pnSwap);
    if (ipcs.values.any((v) => v.$1 == k)) return null;
    ipcs[c] = (k, ipcs.length);
    return null;
  }

  /// Tightens the IPC of core [c] till its shear head breaks off.
  bool tighten(int c) {
    if (!_open || !harness || !ipcs.containsKey(c) || sheared.contains(c)) return false;
    sheared.add(c);
    if (poleDone) {
      tool = M4ServiceConnectTool.none;
      _tag(M4ServiceConnectLines.caughtDead);
      _tag(M4ServiceConnectLines.caughtIpc);
    }
    return true;
  }

  /// The service fuse in (or out).
  DoMistake? toggleFuse() {
    if (!_open) return null;
    if (!harness) return _slip(M4ServiceConnectMistakes.noHarness);
    if (fuseIn) {
      fuseIn = false;
      measured = false;
      return null;
    }
    if (earthed) return _slip(M4ServiceConnectMistakes.earthOn);
    if (loose) return _slip(M4ServiceConnectMistakes.looseIpc);
    fuseIn = true;
    return null;
  }

  /// The multimeter at the meter's incoming terminals (he comes down for it).
  DoMistake? measure() {
    if (!_open) return null;
    if (harness) {
      if (loose) return _slip(M4ServiceConnectMistakes.looseIpc);
      harness = false;
      selPole = null;
    }
    tool = M4ServiceConnectTool.none;
    reading = (!shutdown && !earthed && fuseIn && poleDone && meterDone) ? site.volts : 0;
    readingUp = true;
    return null;
  }

  /// Reads the multimeter: [sayOk] = "ভোল্টেজ ঠিক আছে".
  DoMistake? answer(bool sayOk) {
    if (ended || !readingUp) return null;
    if (sayOk != (reading > 0)) return _slip(M4ServiceConnectMistakes.misread);
    readingUp = false;
    if (reading > 0) {
      measured = true;
      _tag(M4ServiceConnectLines.caughtTest);
    }
    return null;
  }

  /// Picks up the offcut at [x].
  bool pickScrap(double x) {
    if (!_open || !scrapsShown.contains(x)) return false;
    scraps.remove(x);
    if (scraps.isEmpty) _tag(M4ServiceConnectLines.caughtClean);
    return true;
  }

  /// Explains the meter and the main switch to the consumer: the house is done.
  DoMistake? handOver() {
    if (!_open) return null;
    if (!measured || shutdown || !fuseIn) return _slip(M4ServiceConnectMistakes.noTest);
    if (scraps.isNotEmpty) return _slip(M4ServiceConnectMistakes.mess);
    handedOver = true;
    harness = false;
    tool = M4ServiceConnectTool.none;
    return null;
  }

  /// Fails the play.
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    siteSlips = 0;
    tool = M4ServiceConnectTool.none;
    strapped = false;
    drip = false;
    houseIn.clear();
    selHouse = null;
    harness = false;
    shutdown = false;
    proved = false;
    earthed = false;
    ipcs.clear();
    sheared.clear();
    selPole = null;
    fuseIn = false;
    readingUp = false;
    reading = 0;
    measured = false;
    scraps.clear();
    handedOver = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action, 23 actions a house ≈ 34500, the reading
/// ~2000, the light ~1500, the reason ~8200 ≈ 46200 × 3 + the coworker once
/// ≈ 9600 → 148200; 85 % ≈ 126000 → 130 s.
const kM4ServiceConnectQuickMs = 130000;

@immutable
class M4ServiceConnectPack {
  const M4ServiceConnectPack({required this.id, required this.titleBn, this.quickMs = kM4ServiceConnectQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4ServiceConnectPack> m4ServiceConnectPacks = {
  'do_4_3_b': M4ServiceConnectPack(id: 'do_4_3_b', titleBn: M4ServiceConnectLines.title),
};

/// The ten buttons of the tool bar.
enum M4ServiceConnectButton { strap, ipc, pliers, harness, shutdown, tester, earth, fuse, multimeter, handover }

/// The order the job uses the buttons in (the pliers are the trap: no place).
const m4ServiceConnectWorkOrder = [
  M4ServiceConnectButton.strap,
  M4ServiceConnectButton.harness,
  M4ServiceConnectButton.shutdown,
  M4ServiceConnectButton.tester,
  M4ServiceConnectButton.earth,
  M4ServiceConnectButton.ipc,
  M4ServiceConnectButton.fuse,
  M4ServiceConnectButton.multimeter,
  M4ServiceConnectButton.handover,
];

/// Whether [row] lays its tools out in the order the job uses them.
bool m4ServiceConnectRowInOrder(List<M4ServiceConnectButton> row) {
  final ranks = [
    for (final b in row)
      if (b != M4ServiceConnectButton.pliers) m4ServiceConnectWorkOrder.indexOf(b),
  ];
  for (var i = 1; i < ranks.length; i++) {
    if (ranks[i] <= ranks[i - 1]) return false;
  }
  return true;
}

/// The tool bar for a play: the ten buttons shuffled into two rows of five
/// (first five, last five); neither row in the job's order (no giveaway).
List<M4ServiceConnectButton> m4ServiceConnectToolBar(math.Random rng) {
  final b = [...M4ServiceConnectButton.values];
  do {
    b.shuffle(rng);
  } while (m4ServiceConnectRowInOrder(b.sublist(0, 5)) || m4ServiceConnectRowInOrder(b.sublist(5)));
  return b;
}

// ============================================================================
// Page
// ============================================================================

class M4ServiceConnectPage extends StatefulWidget {
  const M4ServiceConnectPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4ServiceConnectPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4ServiceConnectPage> createState() => _M4ServiceConnectPageState();
}

class _M4ServiceConnectPageState extends State<M4ServiceConnectPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SvcRunPage(
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

class _SvcRunPage extends ConsumerStatefulWidget {
  const _SvcRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4ServiceConnectPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SvcRunPage> createState() => _SvcRunPageState();
}

class _SvcRunPageState extends ConsumerState<_SvcRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4ServiceConnectRun _run;
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
  var _coworkerScheduled = false;

  /// The tool bar, dealt once a play (after the houses: the deal is the
  /// first draw from the play's rng).
  late final List<M4ServiceConnectButton> _toolBar;
  final _toolKeys = {for (final b in M4ServiceConnectButton.values) b: GlobalKey()};
  final _okKey = GlobalKey();
  final _noneKey = GlobalKey();
  final _hints = IdleHintController();

  /// The tester's lamp, a moment after it touches the line.
  bool? _tester;
  Timer? _testerTimer;

  var _freeze = false;
  Offset _arcAt = Offset.zero;
  M4ServiceConnectGeo? _geo;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void initState() {
    super.initState();
    // Deal the houses first (the tests rebuild the deal from the seed), then
    // the tool bar from the same rng.
    _run = M4ServiceConnectRun(m4ServiceConnectDeal(widget.rng));
    _toolBar = m4ServiceConnectToolBar(widget.rng);
  }

  @override
  void dispose() {
    disposeCoworker();
    _testerTimer?.cancel();
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

  /// Hands on: not in the praise window of a right move ([tableBusy]), the
  /// coworker, a card or the death freeze.
  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.handedOver && !_freeze;

  String get _task {
    if (_run.readingUp) return M4ServiceConnectLines.askRead;
    if (_run.measured) return M4ServiceConnectLines.askHand;
    if (_run.poleDone) return M4ServiceConnectLines.askLive;
    return M4ServiceConnectLines.askWork;
  }

  void _startSite() {
    _testerTimer?.cancel();
    setState(() {
      _tester = null;
      _wake++;
    });
    unawaited(_sayChain([M4ServiceConnectLines.askWork]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  /// Runs a run action that may return a mistake, then shows it.
  void _act(DoMistake? Function() f, Offset origin, {String sound = 'sounds/quiz_select.ogg'}) {
    if (!_canPlay) return;
    _tick(sound);
    final m = f();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    _afterStep();
  }

  /// After a step: the coworker on his house, a new task line when the stage changed.
  String? _lastTask;
  void _afterStep() {
    if (!_coworkerScheduled && _run.index == _run.deal.callAt && _run.drip && _run.houseIn.isEmpty) {
      _coworkerScheduled = true;
      scheduleCoworker();
    }
    final t = _task;
    if (t != _lastTask) {
      _lastTask = t;
      if (t != M4ServiceConnectLines.askWork) unawaited(_sayChain([t]));
    }
  }

  void _hold(M4ServiceConnectTool t) {
    if (!_canPlay || _run.readingUp) return;
    _tick('sounds/quiz_select.ogg');
    setState(() {
      _run.hold(t);
      _wake++;
    });
  }

  void _useTester(Offset origin) {
    if (!_canPlay || _run.readingUp) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final (m, live) = _run.test();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, origin));
      return;
    }
    _testerTimer?.cancel();
    setState(() {
      _tester = live;
      _wake++;
    });
    _testerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tester = null);
    });
  }

  void _toggleEarth(Offset origin) {
    final geo = _geo;
    if (geo != null) _arcAt = Offset(M4ServiceConnectGeo.poleX + 26, geo.conductorY(1));
    _act(_run.toggleEarth, origin, sound: 'sounds/learn/tag_slap.ogg');
  }

  void _tapScene(Offset p, M4ServiceConnectGeo geo, Offset global) {
    if (!_canPlay || _run.readingUp) return;
    // The fitted IPCs (tighten).
    for (final e in _run.ipcs.entries) {
      if (!_run.sheared.contains(e.key) && geo.ipcHit(e.value.$2, e.value.$1).contains(p)) {
        if (_run.tighten(e.key)) {
          _tick('sounds/intro/impact_metal.ogg', 0.6);
          setState(() => _wake++);
          _afterStep();
        }
        return;
      }
    }
    for (var c = 0; c < 2; c++) {
      if (!_run.ipcs.containsKey(c) && geo.poleCoreHit(c).contains(p)) {
        _act(() => _run.tapPoleCore(c), global);
        return;
      }
    }
    for (var k = 0; k < 4; k++) {
      if (geo.conductorHit(k).contains(p)) {
        if (_run.tool == M4ServiceConnectTool.none) {
          _hints.missTap();
          return;
        }
        _arcAt = Offset(p.dx, geo.conductorY(k));
        _act(() => _run.tapConductor(k), global, sound: 'sounds/intro/click.ogg');
        return;
      }
    }
    for (var c = 0; c < 2; c++) {
      if (!_run.houseIn.contains(c) && geo.houseCoreHit(c).contains(p)) {
        // The meter's cores are his item: he has his say before the first goes in.
        if (_atMeter && holdForCoworker()) return;
        _act(() => _run.tapHouseCore(c), global);
        return;
      }
    }
    for (var i = 0; i < 2; i++) {
      if (geo.terminalHit(i).contains(p)) {
        if (_atMeter && holdForCoworker()) return;
        _act(() => _run.tapTerminal(i), global, sound: 'sounds/intro/click.ogg');
        return;
      }
    }
    if (geo.entryHit.contains(p)) {
      _act(_run.tapEntry, global);
      return;
    }
    for (final x in [..._run.scrapsShown]) {
      if (geo.scrapHit(x).contains(p)) {
        if (_run.pickScrap(x)) {
          _tick('sounds/learn/tag_slap.ogg', 0.4);
          setState(() => _wake++);
        }
        return;
      }
    }
    if (geo.spanHit.contains(p) && _run.tapSpan()) {
      _tick('sounds/learn/tag_slap.ogg', 0.5);
      setState(() => _wake++);
      _afterStep();
      return;
    }
    _hints.missTap();
  }

  /// At the meter, ready to put the cores in (the coworker's moment).
  bool get _atMeter => _run.strapped && _run.drip && !_run.harness && _run.houseIn.isEmpty;

  void _answer(bool sayOk, Offset origin) {
    if (_intro || _ended || _freeze || _card != null || tableBusy || coworkerOpen || !_run.readingUp) return;
    _hush();
    final m = _run.answer(sayOk);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.5);
    _lastTask = _task;
    unawaited(_sayChain([_task]));
  }

  void _handOver(Offset origin) {
    if (!_canPlay || _run.readingUp) return;
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.handOver();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
    } else if (_run.handedOver) {
      unawaited(_siteDone());
    }
  }

  Future<void> _siteDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final s = _run.site;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M4ServiceConnectLines.whyRight(s), M4ServiceConnectLines.whyWrong(s, widget.rng), widget.rng),
      question: M4ServiceConnectLines.whyQuestion(s),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    _lastTask = null;
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
  CoworkerScript get coworkerScript => M4ServiceConnectLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("any core on any terminal") fits only while no core is in yet.
    if (_ended || _run.index != _run.deal.callAt || _run.houseIn.isNotEmpty || _run.handedOver) return null;
    if (_intro || _freeze || _card != null || tableBusy || _run.readingUp || _tester != null || _run.harness) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: a core goes on the wrong terminal.
      setState(() => _run.selHouse = null);
      await _mistake(_run.listen(), origin);
      return;
    }
    _run.caught.add(M4ServiceConnectLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4ServiceConnectLines.callHeld], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4ServiceConnectLines.tapWhy[_nudgeN++ % M4ServiceConnectLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('svc/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A tool or the earth set on the live LT line: the lane freezes grey and
  /// the flash comes off the line in colour; then near-miss or death.
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
    final speak = await SpokenOnce.first('svc/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4ServiceConnectLines.deadlyWord : M4ServiceConnectLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same house goes on from where it was.
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
    await _say(!_run.passed ? M4ServiceConnectLines.fail : (_quickBonus ? M4ServiceConnectLines.quick : M4ServiceConnectLines.allSet),
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
    if (_run.handedOver) return LinemanMode.cheer;
    if (_run.harness || _run.tool != M4ServiceConnectTool.none || _run.readingUp) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M4ServiceConnectView get _view => M4ServiceConnectView(
        ltOrder: _run.site.ltOrder,
        meterLeftIsL: _run.site.meterLeftIsL,
        strapped: _run.strapped,
        drip: _run.drip,
        houseIn: {..._run.houseIn},
        ipcs: {..._run.ipcs},
        sheared: {..._run.sheared},
        shutdown: _run.shutdown,
        earthed: _run.earthed,
        harness: _run.harness,
        fuseIn: _run.fuseIn,
        scraps: [..._run.scrapsShown],
        lit: _run.handedOver,
        selHouse: _run.selHouse,
        selPole: _run.selPole,
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M4ServiceConnectGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final view = _view;
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
                  key: const ValueKey('lane'),
                  child: RepaintBoundary(child: CustomPaint(painter: M4ServiceConnectPainter(geo: geo, view: view, t: t, seed: _run.index * 5 + 3))),
                ),
                Positioned.fromRect(
                  key: ValueKey('trainee-${_run.harness}'),
                  rect: _run.harness ? geo.traineePole : geo.traineeGround,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ],
            ),
          ),
        ),
      ),
      // The tester's lamp at the line.
      if (_tester != null && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: 150,
          top: geo.ltTop - 44,
          child: IgnorePointer(child: _TesterChip(live: _tester!, quiet: quiet)),
        ),
      if (_run.handedOver && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 210,
          width: 140,
          top: geo.house.top - 64,
          child: IgnorePointer(child: _StampPop(text: M4ServiceConnectLines.stampLit, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4ServiceConnectLines.sceneLabel,
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
              builder: (_, v, _) => CustomPaint(painter: M4ServiceConnectArcPainter(at: _arcAt, v: v)),
            ),
          ),
        ),
      // The next house: a short fade from the last one.
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

  /// One button of the dealt tool bar.
  Widget _toolButton(M4ServiceConnectButton b) {
    final key = _toolKeys[b]!;
    void act(DoMistake? Function() f, Offset o, String sound) => _act(f, o, sound: sound);
    return switch (b) {
      M4ServiceConnectButton.strap => _ToolButton(
          key: key, icon: Icons.linear_scale_rounded, label: M4ServiceConnectLines.strap, on: _run.tool == M4ServiceConnectTool.strap, onTap: (_) => _hold(M4ServiceConnectTool.strap)),
      M4ServiceConnectButton.ipc => _ToolButton(
          key: key, icon: Icons.memory_rounded, label: M4ServiceConnectLines.ipc, on: _run.tool == M4ServiceConnectTool.ipc, onTap: (_) => _hold(M4ServiceConnectTool.ipc)),
      M4ServiceConnectButton.pliers => _ToolButton(
          key: key,
          icon: Icons.content_cut_rounded,
          label: M4ServiceConnectLines.pliers,
          on: _run.tool == M4ServiceConnectTool.pliers,
          onTap: (_) => _hold(M4ServiceConnectTool.pliers)),
      M4ServiceConnectButton.harness => _ToolButton(
          key: key, icon: Icons.safety_check_rounded, label: M4ServiceConnectLines.harness, on: _run.harness, onTap: (o) => act(_run.toggleHarness, o, 'sounds/learn/tag_slap.ogg')),
      M4ServiceConnectButton.shutdown => _ToolButton(
          key: key, icon: Icons.power_off_rounded, label: M4ServiceConnectLines.shutdown, on: _run.shutdown, onTap: (o) => act(_run.toggleShutdown, o, 'sounds/intro/impact_metal.ogg')),
      M4ServiceConnectButton.tester => _ToolButton(key: key, icon: Icons.flash_on_rounded, label: M4ServiceConnectLines.tester, on: _tester != null, onTap: _useTester),
      M4ServiceConnectButton.earth => _ToolButton(key: key, icon: Icons.vertical_align_bottom_rounded, label: M4ServiceConnectLines.earth, on: _run.earthed, onTap: _toggleEarth),
      M4ServiceConnectButton.fuse => _ToolButton(
          key: key, icon: Icons.electrical_services_rounded, label: M4ServiceConnectLines.fuse, on: _run.fuseIn, onTap: (o) => act(_run.toggleFuse, o, 'sounds/intro/impact_metal.ogg')),
      M4ServiceConnectButton.multimeter => _ToolButton(
          key: key, icon: Icons.speed_rounded, label: M4ServiceConnectLines.multimeter, on: _run.readingUp, onTap: (o) => act(_run.measure, o, 'sounds/intro/click.ogg')),
      M4ServiceConnectButton.handover => _ToolButton(key: key, icon: Icons.handshake_rounded, label: M4ServiceConnectLines.handover, on: false, onTap: _handOver),
    };
  }

  /// The gesture hint (how to interact, never which): the two reading
  /// buttons; with a core picked, both meter terminals or (only while a tool
  /// is held, since a bare tap there does nothing) all four LT conductors;
  /// otherwise every tool of the bar.
  HintSpec? _hint() {
    if (_run.readingUp) return HintSpec.sweepOver([_okKey, _noneKey]);
    final geo = _geo;
    if (geo != null && _run.selHouse != null) return HintSpec.sweep([geo.terminalHit(0), geo.terminalHit(1)], space: HintSpace.scene);
    if (geo != null && _run.selPole != null && _run.tool != M4ServiceConnectTool.none) return HintSpec.sweep([for (var k = 0; k < 4; k++) geo.conductorHit(k)], space: HintSpace.scene);
    return HintSpec.sweepOver([for (final b in _toolBar) _toolKeys[b]!]);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.handedOver && !deckUp && !coworkerOpen && _card == null && !tableBusy;
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
              labels: M4ServiceConnectLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && _tester == null,
            hintKey: '${_run.index}-${_run.readingUp}-${_run.selHouse}-${_run.selPole}-${_run.tool.name}-${_run.houseIn.length}-${_run.ipcs.length}-${_run.sheared.length}',
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  right: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(ptw: _run.shutdown)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && _card == null && _run.readingUp)
                Positioned(
                  key: ValueKey('meter-${_run.reading}'),
                  right: 14,
                  top: pad.top + 170,
                  child: IgnorePointer(child: _MultimeterCard(volts: _run.reading, quiet: quiet)),
                ),
              if (handsOn && _run.readingUp)
                Positioned(
                  key: const ValueKey('hud-read'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(child: KeyedSubtree(key: _okKey, child: DoBigButton(label: M4ServiceConnectLines.sayOk, filled: true, onTapUp: (d) => _answer(true, d.globalPosition)))),
                      const SizedBox(width: 10),
                      Expanded(child: KeyedSubtree(key: _noneKey, child: DoBigButton(label: M4ServiceConnectLines.sayNone, filled: true, onTapUp: (d) => _answer(false, d.globalPosition)))),
                    ],
                  ),
                ),
              if (handsOn && !_run.readingUp)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 2,
                  right: 2,
                  bottom: pad.bottom + 6,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final b in _toolBar.take(5)) _toolButton(b)]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final b in _toolBar.skip(5)) _toolButton(b)]),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 150), onLeft: !coworkerOnScreen || coworkerFromRight),
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
                  line: M4ServiceConnectLines.intro,
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
  const _DocketChip({required this.ptw});
  final bool ptw;

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
          Text(M4ServiceConnectLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4ServiceConnectLines.docketJob, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          if (ptw)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(4)),
              child: Text(M4ServiceConnectLines.docketPtw, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

/// The multimeter in his hand at the meter's incoming terminals.
class _MultimeterCard extends StatelessWidget {
  const _MultimeterCard({required this.volts, required this.quiet});
  final int volts;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 40 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        width: 132,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFC94A), Color(0xFFE09A16)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6B4A0C), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFB8C9A8), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF3A3A3A), width: 2)),
              child: Text('$volts V', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Roboto', fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1B2416))),
            ),
            const SizedBox(height: 8),
            const Text('V~  AC', style: TextStyle(fontFamily: 'Roboto', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF3A2500))),
          ],
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
            Text(live ? M4ServiceConnectLines.testerLive : M4ServiceConnectLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final void Function(Offset global) onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
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
