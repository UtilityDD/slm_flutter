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
import 'm3_la_earth_world.dart';
import 'mistake_kit.dart';
import 'order_steps.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_la_earth_world.dart' show M3LaEarthGeo, M3LaEarthSpot, M3LaEarthFault, M3LaEarthKit, m3LaEarthJoint;

// Lesson 3.5 "লাইটনিং অ্যারেস্টার (LA): বজ্রপাতের কবচ", কাজ 2 "কবচের মাটি"
// (pack do_3_5_b, engine m3_la_earth). A roadside 11 kV DP transformer
// structure, one LA per phase (pro tip 3). Three rounds:
//  1. read (patrol, point 1 daily check): one LA's earth lead hangs from a
//     burst disconnector — tap the bad LA (point 3: "একটি ঝুলে থাকা আর্থিং
//     তার প্রমাণ করে যে LA-টি খারাপ"); a healthy one is a slip;
//  2. inspect the earth path from the LAs' bottom terminals down the pole to
//     the earth rod (point 3: firmly connected, not cut or torn anywhere;
//     film: "বডি ও আর্থিং রড নিয়মিত চোখে পরখ করুন"): tag the two faults
//     dealt — one cut lead piece, one loose joint. A tag on a sound spot is a
//     slip (once per spot) and the reply comes only on the mistake card. The
//     careless coworker pushes the lesson's own myth once the cut is tagged
//     (never before: his words would name it): "একটু কাটা তো কী, বাকিটা ঠিক
//     আছে" — listening is a slip (myth 2: a small cut raises the resistance
//     many times; the surge goes through the transformer — damage to
//     equipment, so not deadly). If the last fault is tagged before he came,
//     the round's reason waits for him (holdForCoworker);
//  3. order the repair: ডকেট/শাটডাউন → prove dead (HT tester) → earth the
//     line → the work (replace the bad LA, mend each tagged fault, any
//     order); helmet + harness before any work up the pole (the rod clamp is
//     at the ground). The kit lies on the tarp in a dealt order.
// Deadly: hands on the LA (replacing it) before the shutdown — it sits on the
// 11 kV line (point 2: "স্বাভাবিক সিস্টেম ভোল্টেজে (যেমন ১১ কেভি)"). The
// shutdown → test → earth order is the house safety rule, not in lesson 3.5
// (flagged). Not in the sources, left out (flagged): a target earth
// resistance value, earth-tester use, a separate LA earth pit, lead routing.
// Shared kit: guide first, full scene, corner guide, ◆ on the table → "কেন …?"
// → the next round by itself (no scene input in the praise window: tableBusy);
// mistake cards; the deadly freeze; gesture hints (a sweep over what the hands
// can reach, a tap only when one control is left).

// ============================================================================
// Content
// ============================================================================

abstract final class M3LaEarthLines {
  static const title = 'কবচের মাটি';
  static const intro = 'বাজের মরসুম! ট্রান্সফরমারের এল এ আর তার আর্থ পথ পরখ করুন।';
  static const rounds = ['এল এ', 'আর্থ পথ', 'মেরামত'];

  static const askLa = 'তিনটে এল এ — কোনটা খারাপ হয়েছে?';
  static const askPath = 'এবার আর্থ তার ধরে রড পর্যন্ত দেখুন — ত্রুটি কোথায়?';
  static const askFix = 'এল এ বদলাতে আর আর্থ সারাতে হবে। প্রথমে কী?';
  static const askNext = 'বেশ। এবার পরের ধাপ কোনটা?';
  static const askWork = 'লাইন মৃত, আর্থ লাগানো। এবার মেরামত করুন।';

  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askLa, askPath, askFix, askNext, askWork];

  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Screen-reader labels of what the hands can reach (nothing is written on the scene).
  static String laLabel(int i) => 'এল এ ${const ['R', 'Y', 'B'][i]}';
  static String spotLabel(M3LaEarthSpot s) => switch (s) {
        M3LaEarthSpot.joint0 => 'এল এ R-এর আর্থ জোড়',
        M3LaEarthSpot.joint1 => 'এল এ Y-এর আর্থ জোড়',
        M3LaEarthSpot.joint2 => 'এল এ B-এর আর্থ জোড়',
        M3LaEarthSpot.leadUpper => 'খুঁটির ওপরের আর্থ তার',
        M3LaEarthSpot.leadLower => 'খুঁটির নিচের আর্থ তার',
        M3LaEarthSpot.rodClamp => 'আর্থ রডের ক্ল্যাম্প',
      };
  static const docketLabel = 'ডকেট';
  static const testerLabel = 'এইচটি টেস্টার';
  static const earthSetLabel = 'আর্থিং সেট';
  static const harnessLabel = 'হেলমেট আর হারনেস';

  static const docket = 'ডকেট';
  static const docketJob = 'LA বদল · আর্থ মেরামত';
  static const docketTaken = 'শাটডাউন · PTW';

  // Short reactions.
  static const laFound = 'ঠিক! ডিসকানেক্টর ফেটে তার ঝুলছে।';
  static const looseFound = 'আলগা জোড় — লাল ট্যাগ দিলাম।';
  static const cutFound = 'তার কাটা, তামা বেরিয়ে — ট্যাগ দিলাম।';
  static const docketIn = 'ডকেট হাতে, শাটডাউন — ডিও খোলা।';
  static const proved = 'টেস্টারে সাড়া নেই — লাইন মৃত।';
  static const earthed = 'তিন ফেজে আর্থ লাগল।';
  static const harnessOn = 'হেলমেট আর হারনেস পরা — এবার ওঠা যায়।';
  static const laNew = 'নতুন এল এ বসল, আর্থ তার শক্ত করে জোড়া।';
  static const mendLoose = 'জোড় শক্ত করে আঁটা হলো।';
  static const mendCut = 'কাটা টুকরো বদলে নতুন আর্থ তার।';
  static const callHeld = 'ঠিক! সামান্য কাটাও চলবে না।';
  static const allSet = 'এল এ সুস্থ, আর্থ পথ মজবুত — বাজ এলে সার্জ এবার সোজা মাটিতে!';
  static const quick = 'নিখুঁত আর ঝটপট! মাঠে এভাবেই।';
  static const fail = 'আরেকবার — এবার আর্থ পথ মন দিয়ে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  static const caughtLa = 'ঝুলে থাকা তার চিনেছেন';
  static const caughtPath = 'আর্থ পথের সব ত্রুটি';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const caughtSafe = 'শাটডাউন · টেস্ট · আর্থ আগে';
  static const caughtFix = 'এল এ বদল, আর্থ মজবুত';

  // The reasons (lesson 3.5): one right, two wrong, all about the same length.
  static const laAsk = 'কেন এই এল এ-কে খারাপ বললেন?';
  static const laRight = [
    'ঝুলে থাকা আর্থ তার মানে এল এ-টি খারাপ',
    'ডিসকানেক্টর ফেটে আর্থ খুলেছে, এল এ বাতিল',
    'ভেতরে শর্ট হলে ডিসকানেক্টর আর্থ খুলে দেয়',
  ];
  static const laWrong = [
    'ওটার রং বাকি দুটোর চেয়ে একটু ফিকে',
    'মাঝের এল এ সবসময় সবার আগে খারাপ হয়',
    'ঝুলন্ত আর্থ তারটা বেঁধে দিলেই এল এ ঠিক হবে',
    'বাজ না পড়লে এল এ কখনো খারাপ হয় না',
    'আর্থ তার ঝুলে থাকলে সার্জ সহজে নামে',
    'ডিসকানেক্টর খুললে এল এ আবার নিজেই জোড়ে',
  ];

  static const pathAsk = 'কেন ছোট ত্রুটিগুলোও ধরলেন?';
  static const pathRight = [
    'এল এ-র কাজ পুরোটাই তার আর্থিং-এর ওপর',
    'কাটা-আলগা জোড়ে রেজিস্ট্যান্স বহুগুণ বাড়ে',
    'আর্থ দুর্বল হলে সার্জ ট্রান্সফরমারে ঢোকে',
  ];
  static const pathWrong = [
    'বেশিরভাগ তার ভালো থাকলেই আর্থ ঠিক থাকে',
    'আর্থ তার শুধু খুঁটিটা দেখতে ভালো রাখার জন্য',
    'এল এ নিজেই বাজ আটকায়, আর্থ তো বাড়তি',
    'ট্যাগ বেশি দিলে অফিসে কাজ বেশি দেখায়',
    'আলগা জোড়ে সার্জ আরও তাড়াতাড়ি নামে',
    'কাটা তারে একটু টেপ জড়ালেই আগের মতোই চলে',
  ];

  static const fixAsk = 'কেন হাত দেওয়ার আগে শাটডাউন, টেস্ট আর আর্থ?';
  static const fixRight = [
    'এল এ 11 কেভি লাইনে জোড়া, আগে লাইন মৃত চাই',
    'শাটডাউন, টেস্ট আর আর্থ ছাড়া লাইনে হাত নয়',
    'ফিরতি কারেন্ট এলেও লাগানো আর্থই বাঁচায়',
  ];
  static const fixWrong = [
    'এল এ তো ইনসুলেটর, চালু লাইনে ছোঁয়া যায়',
    'বাজ না পড়লে এল এ-তে কোনো ভোল্টেজ থাকে না',
    'ডকেট আর টেস্ট শুধু অফিসের খাতা মেলানোর জন্য',
    'আর্থ লাগালে নতুন এল এ ভালো করে বসে যায়',
    'টেস্টার দিয়ে আসলে শুধু ব্যাটারি দেখা হয়',
    'শাটডাউন হলেই লাইন মৃত, আলাদা টেস্ট বাড়তি',
  ];

  /// The careless coworker's push, once the cut is tagged (no clip yet: silent
  /// with his caption held until it is recorded in his voice).
  static const coworkerLine = 'আর্থ তারটা একটু কাটা তো কী, বাকিটা ঠিক আছে — চলবে!';

  /// His snarl when refused (his recorded clip).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: [
      'না, একটু কাটাতেও আর্থ দুর্বল হয়',
      'কাটা তার চলবে না, বদলে নতুন দেব',
      'না, তাহলে সার্জ ট্রান্সফরমারে ঢুকবে',
    ],
    wrong: [
      'ঠিক বলেছে, তারের বেশিরভাগটাই তো ভালো',
      'একটু টেপ জড়িয়ে দিলেই চলে যাবে',
      'কাটাটা ছোট, না বদলালেও চলে যাবে',
      'ও পুরোনো লোক, ওর কথাই তো ঠিক হবে',
      'বাজ তো রোজ পড়ে না, পরে দেখা যাবে',
    ],
    asks: [
      'ও বলছে একটু কাটা আর্থ তার চলবে। কী করবেন?',
      'সামান্য কাটা — ছেড়ে দেবেন, না সারাবেন?',
      'কার কথা শুনবেন — ওর, না পাঠের?',
    ],
  );

  /// Every fixed line of the guide (for recording) and the coworker's.
  static const guideLines = [
    intro, askLa, askPath, askFix, askNext, askWork, laFound, looseFound, cutFound, //
    docketIn, proved, earthed, harnessOn, laNew, mendLoose, mendCut, callHeld, allSet, quick, fail,
    deadlyWord, nearMissWord, laAsk, pathAsk, fixAsk,
  ];
  static const newCoworkerLines = [coworkerLine];
}

abstract final class M3LaEarthMistakes {
  static const _art = 'assets/game/art/m3_la_earth';

  static const wrongLa = DoMistake(
    key: '3.5/m3_la_earth/wrong-la',
    textBn: 'ঝুলে থাকা আর্থ তারই খারাপ এল এ-র চিহ্ন — ভেতরে শর্ট হলে ডিসকানেক্টর আর্থ খুলে দেয়। এটার তার তো জোড়া আছে।',
    art: '$_art/hanging_lead.svg',
    lessonPoint: 2,
  );
  static const smallCut = DoMistake(
    key: '3.5/m3_la_earth/small-cut',
    textBn: 'সামান্য কাটা বা লুজ কানেকশনেও আর্থিং-এর রেজিস্ট্যান্স বহুগুণ বাড়ে — সার্জ তখন মাটিতে না গিয়ে ট্রান্সফরমার দিয়ে যায়।',
    art: '$_art/small_cut.svg',
    lessonPoint: 2,
  );
  static const liveLa = DoMistake(
    key: '3.5/m3_la_earth/live-la',
    textBn: 'এল এ 11 কেভি লাইনে জোড়া — শাটডাউন না নিয়ে এল এ-তে হাত মানে চালু লাইনে হাত। আগে ডকেট, টেস্ট, আর্থ।',
    art: '$_art/live_la.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const noShutdown = DoMistake(
    key: '3.5/m3_la_earth/no-shutdown',
    textBn: 'আগে ডকেট নিয়ে শাটডাউন — তারপর টেস্ট, আর্থ আর কাজ।',
    art: '$_art/steps.svg',
  );
  static const noTest = DoMistake(
    key: '3.5/m3_la_earth/no-test',
    textBn: 'শাটডাউন মানেই লাইন মৃত নয় — আগে টেস্টার দিয়ে প্রমাণ করুন, তারপর আর্থ।',
    art: '$_art/steps.svg',
  );
  static const noEarth = DoMistake(
    key: '3.5/m3_la_earth/no-earth',
    textBn: 'মৃত প্রমাণের পরে তিন ফেজে আর্থ লাগান — আর্থ ছাড়া লাইনে কাজ নয়।',
    art: '$_art/steps.svg',
  );
  static const noHarness = DoMistake(
    key: '3.5/m3_la_earth/no-harness',
    textBn: 'খুঁটিতে উঠতে হলে আগে হেলমেট আর হারনেস — তারপর ওপরের কাজ।',
    art: '$_art/harness.svg',
  );
  static const soundSpot = DoMistake(
    key: '3.5/m3_la_earth/sound-spot',
    textBn: 'এই জায়গাটা মজবুত ছিল — ট্যাগ শুধু ত্রুটিতে। আর্থ তার কোথাও কাটা-ছেঁড়া বা জোড় আলগা কিনা খুঁটিয়ে দেখুন।',
    art: '$_art/sound_spot.svg',
    lessonPoint: 2,
  );
  static const all = [wrongLa, smallCut, soundSpot, liveLa, noShutdown, noTest, noEarth, noHarness];
}

/// Ids of the repair steps.
abstract final class M3LaEarthIds {
  static const docket = 'docket';
  static const test = 'test';
  static const earth = 'earth';
  static const replace = 'replace';
  static String mend(M3LaEarthSpot s) => 'mend-${s.name}';
}

/// One play's variation.
@immutable
class M3LaEarthDeal {
  const M3LaEarthDeal({
    required this.badLa,
    required this.loose,
    required this.cut,
    this.kit = const [M3LaEarthKit.harness, M3LaEarthKit.earthSet, M3LaEarthKit.tester],
  });

  /// The LA whose disconnector has gone (0 R, 1 Y, 2 B).
  final int badLa;

  /// The loose joint: a healthy LA's bottom joint or the rod clamp.
  final M3LaEarthSpot loose;

  /// The cut lead piece on the pole.
  final M3LaEarthSpot cut;

  /// The tarp's layout, left to right (never the order of use).
  final List<M3LaEarthKit> kit;

  Map<M3LaEarthSpot, M3LaEarthFault> get faults => {loose: M3LaEarthFault.loose, cut: M3LaEarthFault.cut};

  /// The spots to look at in the inspect round (not the bad LA's own joint).
  List<M3LaEarthSpot> get spots => [
        for (var i = 0; i < 3; i++)
          if (i != badLa) m3LaEarthJoint(i),
        M3LaEarthSpot.leadUpper,
        M3LaEarthSpot.leadLower,
        M3LaEarthSpot.rodClamp,
      ];
}

M3LaEarthDeal m3LaEarthDealFor(math.Random rng) {
  final bad = rng.nextInt(3);
  final looseFrom = [
    for (var i = 0; i < 3; i++)
      if (i != bad) m3LaEarthJoint(i),
    M3LaEarthSpot.rodClamp,
  ];
  final loose = looseFrom[rng.nextInt(looseFrom.length)];
  final cut = rng.nextBool() ? M3LaEarthSpot.leadUpper : M3LaEarthSpot.leadLower;
  final kit = [...M3LaEarthKit.values];
  do {
    kit.shuffle(rng);
  } while (_inUseOrder(kit));
  return M3LaEarthDeal(badLa: bad, loose: loose, cut: cut, kit: List.unmodifiable(kit));
}

/// The kit laid out exactly in the order of use (tester, earth set, harness).
bool _inUseOrder(List<M3LaEarthKit> kit) {
  for (var i = 0; i < kit.length; i++) {
    if (kit[i] != M3LaEarthKit.values[i]) return false;
  }
  return true;
}

/// The order of the repair (one board).
OrderRoundSpec m3LaEarthSpec(M3LaEarthDeal d) => OrderRoundSpec(
      groups: [
        const OrderGroup(
          [M3LaEarthIds.docket],
          skipMistake: M3LaEarthMistakes.noShutdown,
          earlyBy: {M3LaEarthIds.replace: M3LaEarthMistakes.liveLa},
        ),
        const OrderGroup([M3LaEarthIds.test], skipMistake: M3LaEarthMistakes.noTest),
        const OrderGroup([M3LaEarthIds.earth], skipMistake: M3LaEarthMistakes.noEarth),
        OrderGroup(
          [M3LaEarthIds.replace, for (final s in d.faults.keys) M3LaEarthIds.mend(s)],
          skipMistake: M3LaEarthMistakes.noEarth,
        ),
      ],
    );

/// The play's rules, without widgets.
class M3LaEarthRun {
  M3LaEarthRun(this.deal) : order = OrderRun([m3LaEarthSpec(deal)]);

  final M3LaEarthDeal deal;
  final OrderRun order;
  var laFound = false;
  final Set<M3LaEarthSpot> flagged = {};

  /// Sound spots wrongly tagged (each costs once).
  final Set<M3LaEarthSpot> wrongTags = {};
  var harnessOn = false;
  int _ownSlips = 0;

  int get slips => order.slips + _ownSlips;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  DoMistake? get deadly => order.deadly;
  bool get done => order.done;
  bool get ended => done || deadly != null;
  bool get passed => done && deadly == null && percent >= 55;
  bool get pathDone => flagged.length == deal.faults.length;

  /// 0 = which LA, 1 = the earth path, 2 = the repair (3 = all done).
  int get stage {
    if (done) return 3;
    if (!laFound) return 0;
    return pathDone ? 2 : 1;
  }

  final Set<String> doneIds = {};
  bool isDone(String id) => doneIds.contains(id);

  /// Round 1: which LA is bad. A healthy one is a slip (look again).
  DoMistake? pickLa(int i) {
    if (laFound || ended) return null;
    if (i == deal.badLa) {
      laFound = true;
      return null;
    }
    _ownSlips++;
    return M3LaEarthMistakes.wrongLa;
  }

  /// Round 2: a tag on a spot: the fault newly tagged, or the slip of a tag
  /// on a sound spot (once per spot); both null when it is not the time or
  /// the spot was already tagged.
  ({M3LaEarthFault? fault, DoMistake? mistake}) tag(M3LaEarthSpot s) {
    if (stage != 1 || ended || !deal.spots.contains(s)) return (fault: null, mistake: null);
    final f = deal.faults[s];
    if (f == null) {
      if (!wrongTags.add(s)) return (fault: null, mistake: null);
      _ownSlips++;
      return (fault: null, mistake: M3LaEarthMistakes.soundSpot);
    }
    if (!flagged.add(s)) return (fault: null, mistake: null);
    return (fault: f, mistake: null);
  }

  /// [tag]'s fault only.
  M3LaEarthFault? look(M3LaEarthSpot s) => tag(s).fault;

  /// Gave in to him: "a little cut is fine" (null once the play has ended).
  DoMistake? listened() {
    if (ended) return null;
    _ownSlips++;
    return M3LaEarthMistakes.smallCut;
  }

  /// Helmet and harness on (any time in the repair).
  void wearHarness() => harnessOn = true;

  /// Whether a step is done up the pole (the rod clamp is at the ground).
  static bool upPole(String id) => id != M3LaEarthIds.mend(M3LaEarthSpot.rodClamp) && (id == M3LaEarthIds.replace || id.startsWith('mend-'));

  /// Round 3: a repair step ([M3LaEarthIds]).
  OrderTap tap(String id) {
    if (stage != 2 || ended) return const OrderTap(OrderTapKind.ignored);
    final safe = [M3LaEarthIds.docket, M3LaEarthIds.test, M3LaEarthIds.earth].every(order.isDone);
    if (safe && upPole(id) && !harnessOn && !order.isDone(id)) {
      _ownSlips++;
      return const OrderTap(OrderTapKind.mistake, mistake: M3LaEarthMistakes.noHarness);
    }
    final t = order.tap(id);
    if (t.kind == OrderTapKind.ok) doneIds.add(id);
    return t;
  }
}

@immutable
class M3LaEarthPack {
  const M3LaEarthPack({required this.id, required this.titleBn, this.quickMs = 100000});
  final String id;
  final String titleBn;

  /// A clean play under this time earns the quick bonus.
  final int quickMs;
}

const Map<String, M3LaEarthPack> m3LaEarthPacks = {
  'do_3_5_b': M3LaEarthPack(id: 'do_3_5_b', titleBn: M3LaEarthLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3LaEarthPage extends StatefulWidget {
  const M3LaEarthPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3LaEarthPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3LaEarthPage> createState() => _M3LaEarthPageState();
}

class _M3LaEarthPageState extends State<M3LaEarthPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _LaRun(
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

class _LaRun extends ConsumerStatefulWidget {
  const _LaRun({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3LaEarthPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_LaRun> createState() => _LaRunState();
}

class _LaRunState extends ConsumerState<_LaRun> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3LaEarthDeal _deal = m3LaEarthDealFor(widget.rng);
  late final M3LaEarthRun _run = M3LaEarthRun(_deal);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _nudge = TaskNudge();
  int _nudgeN = 0;
  int _chain = 0;
  int _runScore = 0;

  var _intro = true;
  var _callHeld = false;

  /// Both faults are tagged and the round's reason waits for the coworker.
  var _pathWaiting = false;
  final _hints = IdleHintController();

  /// Gesture-hint anchors of what the hands can reach now (set in the build).
  final _hintKeys = <String, GlobalKey>{};
  final List<String> _live = [];
  GlobalKey _hk(String id) => _hintKeys.putIfAbsent(id, GlobalKey.new);
  var _climbed = false;

  int _oks = 0;
  Offset? _okAt;
  int _pings = 0;
  Offset? _pingAt;
  int _wake = 0;
  var _cheer = false;
  Offset _lastGlobal = Offset.zero;

  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  var _freeze = false;
  Completer<void>? _frozen;
  VoidCallback? _afterPaid;
  int? _mark;
  int _stars = 0;
  int _totalDelta = 0;

  String get _rungId => widget.ctx.rungId;

  @override
  LevelContext get deathCtx => widget.ctx;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice (never holds the player) -------------------------------------------

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

  /// The round on screen: the earth path until its reason is asked.
  int get _stage => _pathWaiting ? 1 : _run.stage;

  String get _task => switch (_stage) {
        0 => M3LaEarthLines.askLa,
        1 => M3LaEarthLines.askPath,
        _ => !_run.isDone(M3LaEarthIds.docket)
            ? M3LaEarthLines.askFix
            : _run.isDone(M3LaEarthIds.earth)
                ? M3LaEarthLines.askWork
                : M3LaEarthLines.askNext,
      };

  Future<void> _start() async {
    _clock.start();
    await _sayChain([M3LaEarthLines.askLa]);
  }

  bool get _blocked => _intro || _busy || _ended || _freeze || _card != null || tableBusy || struckOut;

  // ---- the hands --------------------------------------------------------------------

  /// A tap on something in the yard. Returns false when it is not the time.
  bool _canTouch(Offset global) {
    if (_blocked || coworkerChoiceUp) return false;
    _lastGlobal = global;
    // Going on with the work while he is still talking refuses him.
    if (coworkerOpen) unawaited(answerCoworker(true, global, direct: true));
    return true;
  }

  void _ok(Offset at) {
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.ogg', volume: 0.55, muted: false));
    setState(() {
      _oks++;
      _okAt = at;
      _wake++;
    });
  }

  void _pickLa(int i, Offset global) {
    if (_stage != 0 || !_canTouch(global)) return;
    final g = _geo;
    final at = g == null ? Offset.zero : g.laBox(i).center;
    final m = _run.pickLa(i);
    if (m != null) {
      unawaited(_slip(m, at));
      return;
    }
    _ok(at);
    unawaited(_sayChain([M3LaEarthLines.laFound], mood: GuideMood.glad));
    _ask(10, M3LaEarthLines.laRight, M3LaEarthLines.laWrong, M3LaEarthLines.laAsk, then: () {
      setState(() {});
      unawaited(_sayChain([M3LaEarthLines.askPath]));
      scheduleCoworker();
    });
  }

  void _look(M3LaEarthSpot s, Offset global) {
    if (_stage != 1 || _pathWaiting) return;
    if (!_canTouch(global)) return;
    final g = _geo;
    final at = g == null ? Offset.zero : g.spotAt(s);
    final r = _run.tag(s);
    if (r.mistake != null) {
      // A tag on a sound spot: a slip; the card says why (after the call).
      unawaited(_slip(r.mistake!, at));
      return;
    }
    final f = r.fault;
    if (f == null) {
      _hints.missTap();
      return;
    }
    _ok(at);
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    final line = f == M3LaEarthFault.cut ? M3LaEarthLines.cutFound : M3LaEarthLines.looseFound;
    unawaited(_sayChain([line], mood: GuideMood.glad));
    if (!_run.pathDone) {
      setState(() {});
      return;
    }
    // The last fault: the round's reason waits for him if he has not come
    // (his push fits now — the cut is tagged).
    _pathWaiting = true;
    if (holdForCoworker()) {
      setState(() {});
      return;
    }
    _pathWaiting = false;
    _askPath();
  }

  void _askPath() {
    _ask(10, M3LaEarthLines.pathRight, M3LaEarthLines.pathWrong, M3LaEarthLines.pathAsk, then: () {
      setState(() {});
      unawaited(_sayChain([M3LaEarthLines.askFix]));
    });
  }

  /// He has gone: the earth path's reason now.
  void _resumePath() {
    if (!mounted || _ended || !_pathWaiting) return;
    setState(() => _pathWaiting = false);
    _askPath();
  }

  void _wearHarness(Offset global) {
    if (_stage != 2 || _run.harnessOn || !_canTouch(global)) return;
    _run.wearHarness();
    final g = _geo;
    _ok(g?.kitBox(M3LaEarthKit.harness, _deal.kit).center ?? Offset.zero);
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    unawaited(_sayChain([M3LaEarthLines.harnessOn], mood: GuideMood.glad));
  }

  void _step(String id, Offset at, Offset global) {
    if (_stage != 2 || !_canTouch(global)) return;
    final t = _run.tap(id);
    switch (t.kind) {
      case OrderTapKind.ignored:
        return;
      case OrderTapKind.mistake:
        final m = t.mistake!;
        if (m.deadly) {
          setState(() => _climbed = true);
          unawaited(_deadly(m));
        } else {
          unawaited(_slip(m, at));
        }
        return;
      case OrderTapKind.ok:
        _ok(at);
        if (M3LaEarthRun.upPole(id) && id != M3LaEarthIds.mend(M3LaEarthSpot.rodClamp)) _climbed = true;
        final line = switch (id) {
          M3LaEarthIds.docket => M3LaEarthLines.docketIn,
          M3LaEarthIds.test => M3LaEarthLines.proved,
          M3LaEarthIds.earth => M3LaEarthLines.earthed,
          M3LaEarthIds.replace => M3LaEarthLines.laNew,
          _ => _deal.faults.entries.firstWhere((e) => M3LaEarthIds.mend(e.key) == id).value == M3LaEarthFault.cut
              ? M3LaEarthLines.mendCut
              : M3LaEarthLines.mendLoose,
        };
        if (t.allDone) {
          setState(() => _cheer = true);
          unawaited(_sayChain([line], mood: GuideMood.glad));
          _ask(10, M3LaEarthLines.fixRight, M3LaEarthLines.fixWrong, M3LaEarthLines.fixAsk, then: () => unawaited(_finish()));
          return;
        }
        unawaited(_levelDelta(5, global, mood: GuideMood.glad));
        final next = id == M3LaEarthIds.docket || id == M3LaEarthIds.test ? M3LaEarthLines.askNext : (id == M3LaEarthIds.earth ? M3LaEarthLines.askWork : null);
        unawaited(_sayChain([line, ?next], mood: GuideMood.glad));
    }
  }

  /// A milestone: its ◆ wait on the table, then "কেন …?"; [then] once paid.
  void _ask(int amount, List<String> right, List<String> wrong, String question, {required VoidCallback then}) {
    _afterPaid = then;
    putOnTable(amount);
    unawaited(askReason(
      deal: () => dealChoices(right, wrong, widget.rng),
      question: question,
      stillValid: () => !_ended,
    ));
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
    final then = _afterPaid;
    _afterPaid = null;
    then?.call();
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M3LaEarthLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended) return null;
    // The round's reason waits for him.
    if (_pathWaiting) return true;
    if (_run.stage > 1) return null;
    // His push names the cut: not before the player has tagged it, and never
    // in a praise window or over a card.
    if (_run.stage < 1 || _blocked || !_run.flagged.contains(_deal.cut)) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listening is a slip; the card's "got it" resumes the round.
      final m = _run.listened();
      if (m != null) await _slip(m, origin, own: true);
      return;
    }
    _callHeld = true;
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted) return;
      if (_pathWaiting) {
        await _sayChain([M3LaEarthLines.callHeld], mood: GuideMood.glad);
        _resumePath();
        return;
      }
      if (chain != _chain) return;
      await _sayChain([M3LaEarthLines.callHeld, _task], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3LaEarthLines.tapWhy[_nudgeN++ % M3LaEarthLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- mistakes -------------------------------------------------------------------

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset point, {bool own = false}) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.7, muted: false));
    _hush();
    final g = _geo;
    setState(() {
      _pings++;
      _pingAt = own && g != null ? g.spotAt(_deal.cut) : point;
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(_levelDelta(-10, _lastGlobal, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m3_la_earth/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move: the yard freezes grey while 11 kV finds its way in colour;
  /// then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.ogg', volume: 1, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.ogg', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m3_la_earth/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3LaEarthLines.deadlyWord : M3LaEarthLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    final m = _card;
    if (m == null) return;
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        if (_pathWaiting && !coworkerOpen) {
          _resumePath();
          return;
        }
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
    await _say(!_run.passed ? M3LaEarthLines.fail : (_quickBonus ? M3LaEarthLines.quick : M3LaEarthLines.allSet),
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

  List<String> get _caught => [
        M3LaEarthLines.caughtLa,
        M3LaEarthLines.caughtPath,
        if (_callHeld) M3LaEarthLines.caughtCall,
        M3LaEarthLines.caughtSafe,
        M3LaEarthLines.caughtFix,
      ];

  // ---- build ------------------------------------------------------------------------

  M3LaEarthGeo? _geo;

  /// The R-phase LA is reached from the left pole.
  bool get _leftPole => _deal.badLa == 0;

  LinemanMode get _mood {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (_cheer) return LinemanMode.cheer;
    return _stage < 2 ? LinemanMode.point : LinemanMode.hold;
  }

  /// A see-through tap area over something in the yard (labelled for screen readers).
  /// Each is a gesture-hint anchor while it is on screen.
  Widget _spot(String key, Rect r, String label, void Function(Offset global) onTap) {
    _live.add(key);
    return Positioned.fromRect(
      key: ValueKey('spot-$key'),
      rect: r,
      child: Semantics(
        label: label,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onTap(d.globalPosition),
          child: SizedBox.expand(key: _hk(key)),
        ),
      ),
    );
  }

  /// How to touch now (never what): a sweep over everything the hands can
  /// reach, in screen order (the layout itself is dealt); a tap only when a
  /// single control is the one way forward.
  HintSpec? _hint() {
    final rects = [
      for (final id in _live) ?HintSpec.globalRectOf(_hk(id)),
    ]..sort((a, b) => a.top != b.top ? a.top.compareTo(b.top) : a.left.compareTo(b.left));
    if (rects.isEmpty) return null;
    if (rects.length == 1) return HintSpec.tap(rects.single.center);
    return HintSpec.sweep(rects);
  }

  List<Widget> _scene(SceneMetrics m, bool quiet) {
    final g = _geo = M3LaEarthGeo.forScene(m.height, m.inset);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final stage = _pathWaiting ? -1 : _stage;
    final kit = _deal.kit;
    _live.removeWhere((id) => id != 'docket');
    final mended = {
      for (final s in _deal.faults.keys)
        if (_run.isDone(M3LaEarthIds.mend(s))) s,
    };
    final up = _climbed;
    return [
      Positioned.fill(
        key: const ValueKey('yard'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(child: CustomPaint(painter: M3LaEarthYardPainter(geo: g))),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('gear'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M3LaEarthGearPainter(
                geo: g,
                badLa: _deal.badLa,
                laReplaced: _run.isDone(M3LaEarthIds.replace),
                faults: _deal.faults,
                flagged: Set.of(_run.flagged),
                mended: mended,
                doOpen: _run.isDone(M3LaEarthIds.docket),
                proved: _run.isDone(M3LaEarthIds.test),
                earthed: _run.isDone(M3LaEarthIds.earth),
                harnessOn: _run.harnessOn,
                kit: kit,
              ),
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: g.traineeBox(up: up, left: _leftPole),
        child: ColorFiltered(
          colorFilter: grey,
          child: Transform.flip(
            flipX: !(up && _leftPole),
            child: LinemanFigure(look: LinemanLook.trainee, mode: _mood, point: 1.0, mood: _mood, wake: _wake, quiet: quiet),
          ),
        ),
      ),
      if (_okAt != null && _oks > 0 && !quiet)
        Positioned(
          key: const ValueKey('ok'),
          left: _okAt!.dx - 34,
          top: _okAt!.dy - 34,
          width: 68,
          height: 68,
          child: IgnorePointer(child: M3LaEarthOneShot(key: ValueKey('ok-$_oks'), ms: 520, painter: M3LaEarthOkPainter.new)),
        ),
      if (_pingAt != null && _pings > 0 && !quiet)
        Positioned(
          key: const ValueKey('ping'),
          left: _pingAt!.dx - 40,
          top: _pingAt!.dy - 40,
          width: 80,
          height: 80,
          child: IgnorePointer(child: M3LaEarthOneShot(key: ValueKey('ping-$_pings'), ms: 560, painter: M3LaEarthPingPainter.new)),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: M3LaEarthOneShot(
              ms: quiet ? 1 : 1400,
              painter: (t) => M3LaEarthZapPainter(t, path: _zapPath(g), figure: g.traineeBox(up: true, left: _leftPole)),
            ),
          ),
        ),
      // What the hands can reach.
      if (stage == 0)
        for (var i = 0; i < 3; i++)
          _spot('la-$i', Rect.fromLTWH(g.phaseX(i) - 22, g.laTop - 6, 44, 84), M3LaEarthLines.laLabel(i), (p) => _pickLa(i, p)),
      if (stage == 1)
        for (final s in _deal.spots) _spot('look-${s.name}', g.spotBox(s), M3LaEarthLines.spotLabel(s), (p) => _look(s, p)),
      if (stage == 2) ...[
        if (!_run.isDone(M3LaEarthIds.test))
          _spot('tester', g.kitBox(M3LaEarthKit.tester, kit), M3LaEarthLines.testerLabel, (p) => _step(M3LaEarthIds.test, Offset(g.phaseX(1), g.topY), p)),
        if (!_run.isDone(M3LaEarthIds.earth))
          _spot('earthset', g.kitBox(M3LaEarthKit.earthSet, kit), M3LaEarthLines.earthSetLabel, (p) => _step(M3LaEarthIds.earth, Offset(g.phaseX(1), g.topY), p)),
        if (!_run.harnessOn) _spot('harness', g.kitBox(M3LaEarthKit.harness, kit), M3LaEarthLines.harnessLabel, _wearHarness),
        if (!_run.isDone(M3LaEarthIds.replace))
          _spot('replace', Rect.fromLTWH(g.phaseX(_deal.badLa) - 22, g.laTop - 6, 44, 84), M3LaEarthLines.laLabel(_deal.badLa),
              (p) => _step(M3LaEarthIds.replace, g.laBox(_deal.badLa).center, p)),
        for (final s in _deal.faults.keys)
          if (!mended.contains(s)) _spot('mend-${s.name}', g.spotBox(s), M3LaEarthLines.spotLabel(s), (p) => _step(M3LaEarthIds.mend(s), g.spotAt(s), p)),
      ],
    ];
  }

  /// The way 11 kV goes in the deadly picture: the bad LA's line terminal,
  /// the hands, the body, the pole.
  List<Offset> _zapPath(M3LaEarthGeo g) {
    final box = g.traineeBox(up: true, left: _leftPole);
    return [
      g.laBox(_deal.badLa).topCenter,
      g.hands(up: true, left: _leftPole),
      box.center,
      Offset(_leftPole ? g.leftPoleX : g.rightPoleX, box.bottom),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final stage = _stage;
    final docketOpen = stage == 2 && !_pathWaiting && !_run.isDone(M3LaEarthIds.docket);
    final docketUp = playing && !coworkerOpen;
    _live.remove('docket');
    if (docketUp && docketOpen) _live.add('docket');
    final waiting = playing && !deckUp && !coworkerOnScreen && _card == null && !tableBusy && !_busy && !_ended && !_pathWaiting;
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
              labels: M3LaEarthLines.rounds,
              done: {for (var i = 0; i < math.min(stage, 3); i++) i},
              current: stage >= 3 ? null : stage,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m, quiet),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: 'la-$stage-${_run.flagged.length}-${_run.wrongTags.length}-${_run.doneIds.length}-${_run.harnessOn}',
            hintController: _hints,
            hintAutoMiss: true,
            overlays: [
              if (docketUp)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  bottom: pad.bottom + 10,
                  child: Semantics(
                    label: M3LaEarthLines.docketLabel,
                    button: docketOpen,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: docketOpen ? (d) => _step(M3LaEarthIds.docket, d.globalPosition, d.globalPosition) : null,
                      child: KeyedSubtree(key: _hk('docket'), child: _DocketChip(taken: _run.isDone(M3LaEarthIds.docket))),
                    ),
                  ),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$_pings'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
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
                  line: M3LaEarthLines.intro,
                  alarm: 'sounds/learn/spark.ogg',
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
                                caughtBn: _caught,
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

/// The job's docket: what a worker reads (and, in the repair, takes for the shutdown).
class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.taken});
  final bool taken;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 96),
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: taken ? const Color(0xFF2E7D32) : const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M3LaEarthLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M3LaEarthLines.docketJob, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          if (taken)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(M3LaEarthLines.docketTaken, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF2E7D32))),
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
              ],
            ),
        ],
      ),
    );
  }
}
