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
import 'm2_megger_prep_world.dart';
import 'mistake_kit.dart';
import 'order_steps.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 2.7, কাজ 1: "মেগারের আগে". The pump room's 415V motor needs an
// insulation (IR) test. The megger makes a high DC voltage, so the job is the
// preparation, done with the hands in the room (lesson 2.7, points 1–2):
//  1. the daily check — take the pair of test leads whose insulation is
//     whole (the other pair is split, copper showing);
//  2. cut it off: the main switch OFF, prove it dead with the tester,
//     discharge with the earth lead (live or charged = no megger);
//  3. set the megger: the knob to the test voltage for the equipment
//     (415V system → 500V, the lesson's own example), L on the terminal,
//     E on the body; nobody touching (the helper's hand is on the terminal
//     box: send him back); TEST for the minute and read the MΩ;
//  4. discharge again (the test voltage stays in the motor as charge).
// Once, before the switch is off, the careless coworker (level 1's rival)
// peeps in: "লাইন চালু থাকলেও মেগার দাও, তাড়াতাড়ি হবে".
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// drawn scene, corner guide, ◆ on the table → "কেন …?", the coworker, mistake
// cards, the deadly freeze.
//
// Deadly: a lead or the earth lead on the motor while the switch is ON;
// listening to him (he pushes the megger onto the live motor — the lesson's
// own forbidden act, on the module's deadly list). Slips: the split lead;
// proving before switching off; skipping the prove or the discharge; a wrong
// test voltage; TEST before the voltage and both leads are set (also while the
// switch is ON: with no lead on the motor nothing reaches it, so it stays a
// slip); TEST with the helper's hand on the motor.
// The switch OFF is the decisive control: it waits for him (holdForCoworker).
// A lead or the earth lead on the live motor while he talks is listening to
// him (his deadly), never a refusal.
// Gesture hints: a sweep over the two lead pairs, over everything the hands
// can reach in the room, and over the four knob positions (never the answer).
//
// Voice: the guide's lines use device TTS; the coworker's push is new (silent
// with its caption held until recorded in his voice), his exit line is his
// recorded one.

// ============================================================================
// Content
// ============================================================================

abstract final class MeggerPrepLines {
  static const title = 'মেগারের আগে';
  static const intro = 'পাম্প ঘরের মোটরের ইনসুলেশন মাপতে হবে। মেগার উচ্চ ভোল্টেজ দেয় — তৈরি না হয়ে হাত দেবেন না!';
  static const rounds = ['লিড', 'বিচ্ছিন্ন', 'মেগার'];

  static const askLeads = 'আগে যন্ত্রটা দেখুন — কোন লিড জোড়া নেবেন?';
  static const askIsolate = 'মোটর এখনও চালু লাইনে। আগে কী করবেন?';
  static const askNext = 'এবার পরের ধাপ — কোনটা?';
  static const askMegger = 'মোটর তৈরি। এবার মেগারটা সাজান।';
  static const askAfter = 'রিডিং নোট হলো। এবার শেষ কাজটা।';

  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askLeads, askIsolate, askNext, askMegger, askAfter];

  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Screen-reader labels of what the hands can reach (nothing is written on the scene).
  static const leadsLeftLabel = 'বাঁ দিকের লিড জোড়া';
  static const leadsRightLabel = 'ডান দিকের লিড জোড়া';
  static const switchLabel = 'মেইন সুইচ';
  static const testerLabel = 'টেস্টার';
  static const earthLeadLabel = 'আর্থ লিড';
  static const terminalLabel = 'মোটরের টার্মিনাল';
  static const boltLabel = 'মোটরের বডির আর্থ বোল্ট';
  static const helperLabel = 'সাথী হেল্পার';
  static const knobLabel = 'মেগারের ভোল্টেজ নব';
  static const testLabel = 'মেগারের টেস্ট বোতাম';
  static const knobClose = 'নব ছেড়ে দিন';

  // Short reactions.
  static const leadsIn = 'লিড জোড়া মেগারে লাগল।';
  static const offDone = 'সুইচ OFF।';
  static const deadProved = 'টেস্টারে কিছু জ্বলল না — লাইন মৃত।';
  static const clipped = [FeedbackLine('লিড বসল।'), FeedbackLine('ঠিক জায়গায়।'), FeedbackLine('বেশ।')];
  static const helperBack = 'ঠিক — টেস্টের সময় কেউ ছোঁবে না।';
  static const testing = 'টেস্ট চলছে — পুরো এক মিনিট।';
  static const reading = 'রিডিং এল — খাতায় লিখুন।';
  static const callHeld = 'ঠিক! তাড়ার চেয়ে প্রাণ বড়।';
  static const allSet = 'বিচ্ছিন্ন, প্রমাণ, ডিসচার্জ, ঠিক ভোল্টেজ — দারুণ মেগারিং!';
  static const quick = 'নিখুঁত আর ঝটপট! মাঠে এভাবেই।';
  static const fail = 'আরেকবার — এবার ধাপগুলো মনে রেখে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  static const caughtLeads = 'অক্ষত লিড';
  static const caughtIsolate = 'আগে বিচ্ছিন্ন ও ডিসচার্জ';
  static const caughtVolt = '415V-এ 500V';
  static const caughtClear = 'টেস্টে কেউ ছোঁয়নি';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const caughtAfter = 'পরে আবার ডিসচার্জ';

  // The reasons (lesson 2.7): one right, two wrong, all about the same length.
  static const leadAsk = 'কেন এই লিড জোড়া নিলেন?';
  static const leadRight = [
    'ইনসুলেশন অক্ষত, ফাটা লিড বিপজ্জনক',
    'মেগার উচ্চ ভোল্টেজ দেয়, লিড অক্ষত চাই',
    'ফাটা লিডে তামা খোলা, হাতে শক লাগতে পারে',
  ];
  static const leadWrong = [
    'এই জোড়ার রংটা একটু বেশি উজ্জ্বল দেখায়',
    'যে জোড়াটা হাতের কাছে ছিল, সেটাই নিলাম',
    'লিড অক্ষত হোক বা না হোক, রিডিং একই আসে',
    'ফাটা লিডে টেপ জড়ালেই কাজ চলে যেত',
    'ইনসুলেশন মোটা হলে দূর থেকে মাপা যায়',
    'অক্ষত লিডে মেগারের ব্যাটারি কম খরচ হয়',
  ];

  static const isoAsk = 'কেন লিডের আগে বন্ধ, প্রমাণ আর ডিসচার্জ?';
  static const isoRight = [
    'চালু বা চার্জ থাকা লাইনে মেগার নিষিদ্ধ',
    'বিচ্ছিন্ন আর চার্জমুক্ত হলে তবেই মেগার',
    'বন্ধ, মৃত প্রমাণ, চার্জ নামল — তবেই লিড',
  ];
  static const isoWrong = [
    'মেগার চালু করলে নিজেই লাইনটা বন্ধ হয়',
    'অফিসের খাতায় লেখার জন্যই এই তিন ধাপ',
    'চালু লাইনে মাপলে রিডিং একটু বেশি আসে',
    'বন্ধ করলে মোটরটা আগে ঠান্ডা হয়ে যায়',
    'চার্জ নামালে মেগারের ব্যাটারি বাঁচে',
    'বিচ্ছিন্ন করা শুধু নতুন মোটরেই লাগে',
  ];

  static const voltAsk = 'কেন 500V বাছলেন?';
  static const voltRight = [
    '415V মোটরে 500V টেস্ট ভোল্টেজই ঠিক',
    'অপারেটিং ভোল্টেজ দেখে বাছি, 415V-এ 500V',
    'মোটরের ভোল্টেজ মিলিয়ে, 415V হলে 500V',
  ];
  static const voltWrong = [
    '415V লেখা দেখে নবটা আন্দাজে ঘোরালাম',
    'সব যন্ত্রেই একই টেস্ট ভোল্টেজ, 500V',
    '415V মোটরে 500V দিলে ব্যাটারি বাঁচে',
    '415V লাইন চালু থাকলেও 500V-এ মাপা যায়',
    'নবের ঘরটা 415V-এর কাছে, তাই ওটাই নিলাম',
    'বেশি ভোল্টেজে ঘোরাতে নবটা শক্ত লাগে',
  ];

  static const afterAsk = 'কেন টেস্টের পরে আবার ডিসচার্জ করলেন?';
  static const afterRight = [
    'টেস্টের ভোল্টেজ মোটরে চার্জ হয়ে থাকে',
    'টেস্টের পরে জমা চার্জ নামিয়ে তবেই ছোঁব',
    'মেগার মোটরে চার্জ রেখে যায়, তাই নামাই',
  ];
  static const afterWrong = [
    'ডিসচার্জ করলে রিডিংটা খাতায় থেকে যায়',
    'চার্জ নামানো শুধু নতুন মোটরের নিয়ম',
    'মোটর ঠান্ডা করতে আর্থ লিড ছোঁয়াই',
    'মেগারে চার্জ ফিরলে পরের বার দ্রুত চলে',
    'রিডিং ভালো এলে চার্জ থাকার ভয় নেই',
    'আর্থ লিডটা ঝুলে ছিল, তাই ছুঁইয়ে দিলাম',
  ];

  /// The careless coworker's push (new: silent with its caption held until recorded in his voice).
  static const coworkerLine = 'লাইন চালু থাকলেও মেগার দাও, তাড়াতাড়ি হবে';

  /// His snarl when refused (his recorded clip).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: [
      'না, আগে সুইচ বন্ধ করে বিচ্ছিন্ন করব',
      'চালু লাইনে মেগার নয়, আগে বন্ধ করি',
      'তাড়া থাকুক, লাইভে লিড লাগাব না',
    ],
    wrong: [
      'ঠিক, চালু লাইনেই লিড লাগিয়ে দিই',
      'একবার চালু অবস্থায় মাপলে কিছু হবে না',
      'সুইচ পরে বন্ধ করব, আগে মেপে নিই',
      'ও পুরোনো লোক, ওর কথাই তো ঠিক হবে',
      'তাড়াতাড়ি হলে সবারই ভালো, মেপে দিই',
    ],
    asks: [
      'ও বলছে চালু লাইনেই মেগার দিতে। কী করবেন?',
      'আগে বিচ্ছিন্ন, না এখনই লিড?',
      'কার কথা শুনবেন — ওর, না নিয়মের?',
    ],
  );

  /// Every fixed line of the guide (for recording) and the coworker's.
  static const guideLines = [
    intro, askLeads, askIsolate, askNext, askMegger, askAfter, leadsIn, offDone, deadProved, //
    helperBack, testing, reading, callHeld, allSet, quick, fail, deadlyWord, nearMissWord,
    leadAsk, isoAsk, voltAsk, afterAsk,
  ];
  static const newCoworkerLines = [coworkerLine];
}

abstract final class MeggerPrepMistakes {
  static const _art = 'assets/game/art/m2_megger_prep';

  static const crackedLead = DoMistake(
    key: '2.7/megger/cracked-lead',
    textBn: 'ফাটা লিডে তামা বেরিয়ে আছে — মেগারের উচ্চ ভোল্টেজ হাতে লাগতে পারে। ব্যবহারের আগে দেখুন লিডের ইনসুলেশন অক্ষত।',
    art: '$_art/cracked_lead.svg',
    lessonPoint: 0,
  );
  static const notIsolated = DoMistake(
    key: '2.7/megger/not-isolated',
    textBn: 'সুইচ চালু রেখে মোটরে লিড বা মেগার — লাইভ লাইনে মেগার কঠোরভাবে নিষিদ্ধ। আগে সাপ্লাই থেকে সম্পূর্ণ বিচ্ছিন্ন করুন।',
    art: '$_art/live_megger.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const earthLive = DoMistake(
    key: '2.7/megger/earth-on-live',
    textBn: 'চালু মোটরের টার্মিনালে আর্থ লিড — লাইভ লাইন সরাসরি মাটিতে শর্ট হয়। আগে সুইচ বন্ধ, প্রমাণ, তারপর ডিসচার্জ।',
    art: '$_art/live_megger.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const liveMegger = DoMistake(
    key: '2.7/megger/listened-live',
    textBn: 'তাড়ার চাপে চালু লাইনে মেগার — এটা কঠোরভাবে নিষিদ্ধ। যত তাড়াই থাকুক, আগে বিচ্ছিন্ন আর ডিসচার্জ।',
    art: '$_art/live_megger.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const offFirst = DoMistake(
    key: '2.7/megger/off-first',
    textBn: 'আগে সুইচ বন্ধ করুন — তারপর টেস্টার দিয়ে দেখুন লাইন সত্যিই মৃত।',
    art: '$_art/steps.svg',
    lessonPoint: 1,
  );
  static const proveFirst = DoMistake(
    key: '2.7/megger/prove-first',
    textBn: 'সুইচ বন্ধ মানেই লাইন মৃত নয় — আগে টেস্টার দিয়ে প্রমাণ করুন, তারপর বাকি কাজ।',
    art: '$_art/steps.svg',
    lessonPoint: 1,
  );
  static const noDischarge = DoMistake(
    key: '2.7/megger/no-discharge',
    textBn: 'ডিসচার্জ না করে মেগার কঠোরভাবে নিষিদ্ধ — আগে আর্থ লিড ছুঁইয়ে জমা চার্জ নামান।',
    art: '$_art/steps.svg',
    lessonPoint: 1,
  );
  static const wrongVolt = DoMistake(
    key: '2.7/megger/wrong-volt',
    textBn: 'সরঞ্জামের অপারেটিং ভোল্টেজ অনুযায়ী টেস্ট ভোল্টেজ বাছুন — 415V মোটরে 500V।',
    art: '$_art/volt.svg',
    lessonPoint: 1,
  );
  static const notSet = DoMistake(
    key: '2.7/megger/not-set',
    textBn: 'আগে ঠিক টেস্ট ভোল্টেজ, লাইন লিড টার্মিনালে আর আর্থ লিড বডিতে — তবেই টেস্ট।',
    art: '$_art/volt.svg',
    lessonPoint: 1,
  );
  static const touching = DoMistake(
    key: '2.7/megger/someone-touching',
    textBn: 'মেগার নিজেই উচ্চ ভোল্টেজের উৎস — টেস্টের সময় কেউ যেন খোলা অংশ না ছোঁয়। আগে সবাইকে সরান।',
    art: '$_art/hands_off.svg',
    lessonPoint: 1,
  );
  static const all = [crackedLead, notIsolated, earthLive, liveMegger, offFirst, proveFirst, noDischarge, wrongVolt, notSet, touching];
}

/// Ids of the steps.
abstract final class MeggerIds {
  static const off = 'off';
  static const prove = 'prove';
  static const discharge = 'discharge';
  static const v500 = 'v500';
  static const leadL = 'leadL';
  static const leadE = 'leadE';
  static const test = 'test';
  static const discharge2 = 'discharge2';
  static String volt(int v) => 'v$v';
}

/// The order of the preparation (one board: a later step touched early is
/// the open group's mistake; on a live motor it is deadly).
OrderRoundSpec meggerPrepSpec() => OrderRoundSpec(
      groups: const [
        OrderGroup(
          [MeggerIds.off],
          skipMistake: MeggerPrepMistakes.notIsolated,
          earlyBy: {MeggerIds.prove: MeggerPrepMistakes.offFirst, MeggerIds.discharge: MeggerPrepMistakes.earthLive},
        ),
        OrderGroup([MeggerIds.prove], skipMistake: MeggerPrepMistakes.proveFirst),
        OrderGroup([MeggerIds.discharge], skipMistake: MeggerPrepMistakes.noDischarge),
        OrderGroup([MeggerIds.v500, MeggerIds.leadL, MeggerIds.leadE], skipMistake: MeggerPrepMistakes.notSet),
        OrderGroup([MeggerIds.test], skipMistake: MeggerPrepMistakes.notSet),
        OrderGroup([MeggerIds.discharge2], skipMistake: MeggerPrepMistakes.notSet),
      ],
      traps: {
        for (final v in meggerVolts)
          if (v != 500) MeggerIds.volt(v): MeggerPrepMistakes.wrongVolt,
      },
    );

/// The play's rules, without widgets.
class MeggerPrepRun {
  MeggerPrepRun() : order = OrderRun([meggerPrepSpec()]);

  final OrderRun order;
  var leadsOk = false;
  var helperClear = false;
  var tested = false;
  int _ownSlips = 0;

  int get slips => order.slips + _ownSlips;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  DoMistake? get deadly => order.deadly;
  bool get done => order.done;
  bool get ended => done || deadly != null;
  bool get passed => done && deadly == null && percent >= 55;

  /// 0 = the leads, 1 = cut it off, 2 = set the megger (3 = all done).
  int get stage {
    if (done) return 3;
    if (!leadsOk) return 0;
    return isDone(MeggerIds.discharge) ? 2 : 1;
  }

  /// Steps done so far (kept after the board is finished).
  final Set<String> doneIds = {};

  bool isDone(String id) => doneIds.contains(id);

  /// Ready to press TEST, but for the people round the motor.
  bool get setUp => [MeggerIds.off, MeggerIds.prove, MeggerIds.discharge, MeggerIds.v500, MeggerIds.leadL, MeggerIds.leadE].every(isDone);

  /// A pair of leads: the split one is a slip (choose again).
  DoMistake? pickLeads({required bool whole}) {
    if (leadsOk || ended) return null;
    if (whole) {
      leadsOk = true;
      return null;
    }
    _ownSlips++;
    return MeggerPrepMistakes.crackedLead;
  }

  void clearHelper() {
    if (ended) return;
    helperClear = true;
  }

  /// A step in the room ([MeggerIds]); the earth lead after the test is
  /// [MeggerIds.discharge2].
  OrderTap tap(String id) {
    if (!leadsOk || ended) return const OrderTap(OrderTapKind.ignored);
    if (id == MeggerIds.test && !tested) {
      // TEST with the voltage or a lead not set: nothing reaches the motor (a slip).
      if (!isDone(MeggerIds.v500) || !isDone(MeggerIds.leadL) || !isDone(MeggerIds.leadE)) {
        _ownSlips++;
        return const OrderTap(OrderTapKind.mistake, mistake: MeggerPrepMistakes.notSet);
      }
      if (!helperClear) {
        _ownSlips++;
        return const OrderTap(OrderTapKind.mistake, mistake: MeggerPrepMistakes.touching);
      }
    }
    final t = order.tap(id);
    if (t.kind == OrderTapKind.ok) {
      doneIds.add(id);
      if (id == MeggerIds.test) tested = true;
    }
    return t;
  }

  /// Gave in to him: the leads went on the live motor.
  void listened() {
    if (ended) return;
    order.failDeadly(MeggerPrepMistakes.liveMegger);
  }
}

/// One play's variation.
@immutable
class MeggerPrepDeal {
  const MeggerPrepDeal({required this.crackedLeft, required this.reading});

  /// The split pair lies on the left (the whole one on the right), or the other way.
  final bool crackedLeft;

  /// The healthy motor's reading after the minute (MΩ).
  final int reading;
}

const meggerReadings = [180, 320, 650, 1200];

MeggerPrepDeal dealMeggerPrep(math.Random rng) =>
    MeggerPrepDeal(crackedLeft: rng.nextBool(), reading: meggerReadings[rng.nextInt(meggerReadings.length)]);

@immutable
class M2MeggerPrepPack {
  const M2MeggerPrepPack({required this.id, required this.titleBn, this.quickMs = 80000});
  final String id;
  final String titleBn;

  /// A clean play under this time earns the quick bonus.
  final int quickMs;
}

const m2MeggerPrepPack = M2MeggerPrepPack(id: 'do_2_7_a', titleBn: MeggerPrepLines.title);
const Map<String, M2MeggerPrepPack> m2MeggerPrepPacks = {'do_2_7_a': m2MeggerPrepPack};

// ============================================================================
// Page
// ============================================================================

class M2MeggerPrepPage extends StatefulWidget {
  const M2MeggerPrepPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2MeggerPrepPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2MeggerPrepPage> createState() => _M2MeggerPrepPageState();
}

class _M2MeggerPrepPageState extends State<M2MeggerPrepPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _MeggerRun(
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

class _MeggerRun extends ConsumerStatefulWidget {
  const _MeggerRun({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2MeggerPrepPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_MeggerRun> createState() => _MeggerRunState();
}

/// The helper's look (a white helmet, grey shirt, green vest).
const _helperLook = LinemanLook(
  helmet: Color(0xFFF2F2F2),
  shirt: Color(0xFF6B6F75),
  vest: Color(0xFF3FAE4A),
  pants: Color(0xFF2E3440),
  skin: Color(0xFF9C6440),
  moustache: true,
);

class _MeggerRunState extends ConsumerState<_MeggerRun> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final MeggerPrepDeal _deal = dealMeggerPrep(widget.rng);
  final MeggerPrepRun _run = MeggerPrepRun();
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _clipBag = LineBag(MeggerPrepLines.clipped);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _nudge = TaskNudge();
  final _hints = IdleHintController();
  int _nudgeN = 0;
  int _chain = 0;
  int _runScore = 0;

  var _intro = true;
  var _callHeld = false;

  // What the scene shows.
  int? _volt;
  var _knobOpen = false;

  /// A knob position open big (two steps: its preview, then ✓) and the
  /// positions set aside with ✕ while the close-up is up.
  int? _voltPreview;
  final Set<int> _voltAside = {};
  var _testerOn = false;
  var _earthOn = false;
  var _testing = false;
  int _testTok = 0;
  int? _reading;
  int _sparks = 0;
  Offset? _sparkAt;
  int _pings = 0;
  Offset? _pingAt;
  int _wake = 0;
  var _cheer = false;
  Timer? _showTimer;
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
    _showTimer?.cancel();
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

  String get _task => switch (_run.stage) {
        0 => MeggerPrepLines.askLeads,
        1 => _run.isDone(MeggerIds.off) ? MeggerPrepLines.askNext : MeggerPrepLines.askIsolate,
        _ => _run.tested ? MeggerPrepLines.askAfter : MeggerPrepLines.askMegger,
      };

  Future<void> _start() async {
    _clock.start();
    await _sayChain([MeggerPrepLines.askLeads]);
  }

  /// No scene input now: intro, a card, the praise window or the reason deck
  /// ([tableBusy]), the strike-out, the minute of TEST, the end.
  bool get _blocked => _intro || _busy || _ended || _card != null || tableBusy || struckOut || _testing;

  // ---- the hands --------------------------------------------------------------------

  /// A tap on something in the room ([step] for a step by the motor). Returns
  /// false when it is not the time.
  bool _canTouch(Offset global, {String? step}) {
    if (_blocked || _knobOpen || coworkerChoiceUp) return false;
    _lastGlobal = global;
    if (coworkerOpen) {
      if (step != null && _onLiveMotor(step)) {
        // A lead or the earth lead on the live motor while he talks is doing
        // what he pushes: listening to him (deadly), never a refusal (+10).
        unawaited(answerCoworker(false, global, direct: true));
        return false;
      }
      // Going on with the work while he is still talking refuses him.
      unawaited(answerCoworker(true, global, direct: true));
    }
    return true;
  }

  /// A lead or the earth lead on the motor while the switch is still ON.
  bool _onLiveMotor(String id) =>
      !_run.isDone(MeggerIds.off) && (id == MeggerIds.leadL || id == MeggerIds.leadE || id == MeggerIds.discharge);

  void _pickLeads(bool left, Offset global) {
    if (!_canTouch(global) || _run.stage != 0) return;
    final whole = left != _deal.crackedLeft;
    final m = _run.pickLeads(whole: whole);
    if (m != null) {
      final g = _geo;
      unawaited(_slip(m, g == null ? Offset.zero : (left ? g.leadsLeft.center : g.leadsRight.center)));
      return;
    }
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.ogg', volume: 0.55, muted: false));
    setState(() => _wake++);
    unawaited(_sayChain([MeggerPrepLines.leadsIn], mood: GuideMood.glad));
    _ask(10, MeggerPrepLines.leadRight, MeggerPrepLines.leadWrong, MeggerPrepLines.leadAsk, then: () {
      setState(() {});
      unawaited(_sayChain([MeggerPrepLines.askIsolate]));
      scheduleCoworker();
    });
  }

  void _tapHelper(Offset global) {
    if (!_canTouch(global) || _run.helperClear) return;
    HapticFeedback.selectionClick();
    _run.clearHelper();
    setState(() => _wake++);
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    unawaited(_sayChain([MeggerPrepLines.helperBack], mood: GuideMood.glad));
  }

  void _tapKnob(Offset global) {
    if (!_canTouch(global)) return;
    if (_run.stage < 2 || _run.tested) {
      // Nothing to set on the knob now: a tap on nothing.
      _hints.missTap();
      return;
    }
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    setState(() {
      _knobOpen = true;
      _voltPreview = null;
      _voltAside.clear();
    });
  }

  /// A tap on a knob position opens it big; the knob is not turned yet.
  void _openVolt(int v) {
    if (!_knobOpen || _blocked || _voltPreview != null) return;
    setState(() => _voltPreview = v);
  }

  /// ✓ on the position's preview: the knob is turned (as one tap was before).
  void _confirmVolt() {
    final v = _voltPreview;
    if (v == null) return;
    setState(() {
      _voltPreview = null;
      _voltAside.clear();
    });
    _pickVolt(v);
  }

  /// ✕: that position is set aside (dimmed); the knob stays.
  void _rejectVolt() {
    final v = _voltPreview;
    if (v == null) return;
    setState(() {
      _voltPreview = null;
      _voltAside.add(v);
    });
  }

  void _pickVolt(int v) {
    if (!_knobOpen || _blocked) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.6, muted: false));
    final g = _geo;
    setState(() {
      _knobOpen = false;
      _volt = v;
    });
    _act(MeggerIds.volt(v), g?.knob ?? Offset.zero);
  }

  /// A step by the motor, the switch or the megger.
  void _tapStep(String id, Offset point, Offset global) {
    if (_run.stage == 0 || !_canTouch(global, step: id)) return;
    // The switch OFF ends his moment: while he is due it waits for him (no cost).
    if (id == MeggerIds.off && holdForCoworker()) return;
    if (id == MeggerIds.discharge && _run.tested) id = MeggerIds.discharge2;
    _act(id, point);
  }

  void _act(String id, Offset point) {
    final t = _run.tap(id);
    switch (t.kind) {
      case OrderTapKind.ignored:
        // Nothing to do there now (a step already done): a tap on nothing.
        _hints.missTap();
        return;
      case OrderTapKind.mistake:
        final m = t.mistake!;
        if (id.startsWith('v') && id != MeggerIds.v500) {
          // The knob goes back after the wrong voltage: to 500V when that was
          // already set (TEST then runs at what the knob shows), else to OFF.
          setState(() => _volt = _run.isDone(MeggerIds.v500) ? 500 : null);
        }
        if (m.deadly) {
          setState(() {
            if (id == MeggerIds.discharge) _earthOn = true;
          });
          unawaited(_deadly(m));
        } else {
          unawaited(_slip(m, point));
        }
        return;
      case OrderTapKind.ok:
        unawaited(_stepDone(id, t, point));
    }
  }

  Future<void> _stepDone(String id, OrderTap t, Offset point) async {
    final origin = _lastGlobal;
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.ogg', volume: 0.55, muted: false));
    setState(() => _wake++);
    switch (id) {
      case MeggerIds.off:
        unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
        unawaited(_sayChain([MeggerPrepLines.offDone, MeggerPrepLines.askNext], mood: GuideMood.glad));
      case MeggerIds.prove:
        _show(() => _testerOn = true, () => _testerOn = false, 1100);
        unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
        unawaited(_sayChain([MeggerPrepLines.deadProved], mood: GuideMood.glad));
      case MeggerIds.discharge:
      case MeggerIds.discharge2:
        if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.ogg', volume: 0.8, muted: false));
        final g = _geo;
        setState(() {
          _sparks++;
          _sparkAt = g?.terminals.translate(14, -2) ?? point;
        });
        _show(() => _earthOn = true, () => _earthOn = false, 900);
        if (id == MeggerIds.discharge) {
          _ask(10, MeggerPrepLines.isoRight, MeggerPrepLines.isoWrong, MeggerPrepLines.isoAsk, then: () {
            setState(() {});
            unawaited(_sayChain([MeggerPrepLines.askMegger]));
          });
        } else {
          setState(() => _cheer = true);
          _ask(5, MeggerPrepLines.afterRight, MeggerPrepLines.afterWrong, MeggerPrepLines.afterAsk, then: () => unawaited(_finish()));
        }
      case MeggerIds.v500:
        if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.55, muted: false));
        _ask(10, MeggerPrepLines.voltRight, MeggerPrepLines.voltWrong, MeggerPrepLines.voltAsk, then: () {
          setState(() {});
          unawaited(_sayChain([_nudge.next(_task)]));
        });
      case MeggerIds.leadL:
      case MeggerIds.leadE:
        unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
        unawaited(_sayChain([_clipBag.next().shownBn], mood: GuideMood.glad));
      case MeggerIds.test:
        unawaited(_runTest(origin));
    }
  }

  /// Shows a tool at the motor for a moment ([on] now, [off] after [ms]).
  void _show(VoidCallback on, VoidCallback off, int ms) {
    _showTimer?.cancel();
    setState(on);
    _showTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(off);
    });
  }

  /// TEST held for the minute (sped up), then the reading.
  Future<void> _runTest(Offset origin) async {
    setState(() {
      _testing = true;
      _testTok++;
    });
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.ogg', volume: 0.35, muted: false));
    unawaited(_sayChain([MeggerPrepLines.testing]));
    final quiet = MediaQuery.disableAnimationsOf(context);
    await Future<void>.delayed(Duration(milliseconds: quiet ? 300 : 2400));
    if (!mounted || _ended) return;
    setState(() {
      _testing = false;
      _reading = _deal.reading;
    });
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.55, muted: false));
    unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
    unawaited(_sayChain([MeggerPrepLines.reading, MeggerPrepLines.askAfter], mood: GuideMood.glad));
  }

  /// A milestone: its ◆ wait on the table, then "কেন …?"; [then] once paid.
  void _ask(int amount, List<String> right, List<String> wrong, String question, {required VoidCallback then}) {
    // One reason at a time: the scene is locked while one is pending
    // ([_blocked] has [tableBusy]), so a second step can never replace it.
    assert(_afterPaid == null && !tableBusy, 'a reason is already pending');
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
  CoworkerScript get coworkerScript => MeggerPrepLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("লাইন চালু থাকলেও মেগার দাও") fits only while the switch is ON.
    if (_ended || _run.ended || _run.isDone(MeggerIds.off) || _run.stage > 1) return null;
    if (_run.stage < 1 || tableBusy || _blocked || _knobOpen) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      _run.listened();
      await _deadly(MeggerPrepMistakes.liveMegger);
      return;
    }
    _callHeld = true;
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([MeggerPrepLines.callHeld, _task], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? MeggerPrepLines.tapWhy[_nudgeN++ % MeggerPrepLines.tapWhy.length]
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

  Future<void> _slip(DoMistake m, Offset point) async {
    if (_ended) return;
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.7, muted: false));
    _hush();
    setState(() {
      _pings++;
      _pingAt = point;
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(_levelDelta(-10, _lastGlobal, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('megger/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move: the room freezes grey while the live supply finds its way
  /// in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _knobOpen = false;
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
    final speak = await SpokenOnce.first('megger/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? MeggerPrepLines.deadlyWord : MeggerPrepLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? MeggerPrepLines.fail : (_quickBonus ? MeggerPrepLines.quick : MeggerPrepLines.allSet),
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
        MeggerPrepLines.caughtLeads,
        MeggerPrepLines.caughtIsolate,
        MeggerPrepLines.caughtVolt,
        MeggerPrepLines.caughtClear,
        if (_callHeld) MeggerPrepLines.caughtCall,
        MeggerPrepLines.caughtAfter,
      ];

  // ---- build ------------------------------------------------------------------------

  MeggerGeo? _geo;

  LinemanMode get _mood {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (_cheer) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  /// A see-through tap area over something in the room (labelled for screen readers).
  Widget _spot(String key, Rect r, String label, void Function(Offset global) onTap) => Positioned.fromRect(
        key: ValueKey('spot-$key'),
        rect: r,
        child: Semantics(
          label: label,
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onTap(d.globalPosition),
            child: const SizedBox.expand(),
          ),
        ),
      );

  List<Widget> _scene(SceneMetrics m, bool quiet) {
    final g = _geo = MeggerGeo.forScene(m.height, m.inset);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final switchOn = !_run.isDone(MeggerIds.off);
    final helper = g.helperBox(clear: _run.helperClear);
    final lOn = _run.isDone(MeggerIds.leadL);
    final eOn = _run.isDone(MeggerIds.leadE);
    final stage = _run.stage;
    return [
      Positioned.fill(
        key: const ValueKey('room'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(child: CustomPaint(painter: MeggerRoomPainter(geo: g, switchOn: switchOn))),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('helper'),
        rect: helper,
        child: ColorFiltered(
          colorFilter: grey,
          child: Transform.flip(
            flipX: true,
            child: LinemanFigure(
              look: _helperLook,
              mode: _run.helperClear ? LinemanMode.idle : LinemanMode.point,
              point: 1.1,
              wake: _wake,
              quiet: quiet,
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: g.traineeBox,
        child: ColorFiltered(
          colorFilter: grey,
          child: LinemanFigure(look: LinemanLook.trainee, mode: LinemanMode.hold, mood: _mood, wake: _wake, quiet: quiet),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('gear'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: MeggerGearPainter(
                geo: g,
                leadsTaken: _run.leadsOk,
                crackedLeft: _deal.crackedLeft,
                volt: _volt,
                lClipped: lOn,
                eClipped: eOn,
                testerOn: _testerOn,
                earthOn: _earthOn,
              ),
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('display'),
        rect: g.display,
        child: ColorFiltered(
          colorFilter: grey,
          child: _testing
              ? TweenAnimationBuilder<double>(
                  key: ValueKey('count-$_testTok'),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: quiet ? 1 : 2400),
                  builder: (_, t, _) => CustomPaint(painter: MeggerDisplayPainter(volt: _volt, t: t, reading: _deal.reading)),
                )
              : CustomPaint(painter: MeggerDisplayPainter(volt: _volt, t: null, reading: _reading)),
        ),
      ),
      if (_sparkAt != null && _sparks > 0 && !quiet)
        Positioned(
          key: const ValueKey('spark'),
          left: _sparkAt!.dx - 30,
          top: _sparkAt!.dy - 30,
          width: 60,
          height: 60,
          child: IgnorePointer(child: MeggerOneShot(key: ValueKey('spark-$_sparks'), ms: 520, painter: MeggerSparkPainter.new)),
        ),
      if (_pingAt != null && _pings > 0 && !quiet)
        Positioned(
          key: const ValueKey('ping'),
          left: _pingAt!.dx - 40,
          top: _pingAt!.dy - 40,
          width: 80,
          height: 80,
          child: IgnorePointer(child: MeggerOneShot(key: ValueKey('ping-$_pings'), ms: 560, painter: MeggerPingPainter.new)),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: MeggerOneShot(
              ms: quiet ? 1 : 1400,
              painter: (t) => MeggerZapPainter(t, path: _zapPath(g), figure: g.traineeBox),
            ),
          ),
        ),
      // A tap on nothing (behind the spots) counts toward the gesture hint.
      Positioned.fill(
        key: const ValueKey('miss'),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (_) => _hints.missTap()),
      ),
      // What the hands can reach.
      if (stage == 0) ...[
        _spot('leads-left', g.leadsLeft, MeggerPrepLines.leadsLeftLabel, (p) => _pickLeads(true, p)),
        _spot('leads-right', g.leadsRight, MeggerPrepLines.leadsRightLabel, (p) => _pickLeads(false, p)),
      ],
      if (!_run.helperClear) _spot('helper', helper.deflate(6), MeggerPrepLines.helperLabel, _tapHelper),
      if (stage >= 1) ...[
        _spot('switch', g.switchBox.inflate(6), MeggerPrepLines.switchLabel, (p) => _tapStep(MeggerIds.off, g.switchBox.center, p)),
        _spot('tester', g.tester.inflate(12), MeggerPrepLines.testerLabel, (p) => _tapStep(MeggerIds.prove, g.terminals, p)),
        _spot('earth', Rect.fromCenter(center: g.earthClipRest.translate(-6, -14), width: 64, height: 64), MeggerPrepLines.earthLeadLabel,
            (p) => _tapStep(MeggerIds.discharge, g.terminals, p)),
        _spot('terminal', g.terminalBox.inflate(12), MeggerPrepLines.terminalLabel, (p) => _tapStep(MeggerIds.leadL, g.terminals, p)),
        _spot('bolt', Rect.fromCenter(center: g.earthBolt, width: 44, height: 40), MeggerPrepLines.boltLabel, (p) => _tapStep(MeggerIds.leadE, g.earthBolt, p)),
        _spot('knob', Rect.fromCenter(center: g.knob, width: 56, height: 56), MeggerPrepLines.knobLabel, _tapKnob),
        _spot('test', Rect.fromCenter(center: g.testButton.translate(0, -6), width: 52, height: 52), MeggerPrepLines.testLabel,
            (p) => _tapStep(MeggerIds.test, g.testButton, p)),
      ],
      if (_knobOpen) ..._knobPanel(g),
    ];
  }

  /// The knob close up: four positions, big enough for a thumb.
  List<Widget> _knobPanel(MeggerGeo g) {
    final panel = _knobPanelRect(g);
    return [
      _spot('knob-close', const Rect.fromLTWH(0, 0, 360, 2000), MeggerPrepLines.knobClose, (_) {
        setState(() => _knobOpen = false);
      }),
      Positioned.fromRect(
        key: const ValueKey('knob-panel'),
        rect: panel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xF2D9A417),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2B2B2B), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Stack(
            children: [
              Center(child: SizedBox(width: 64, height: 64, child: CustomPaint(painter: MeggerKnobPainter(volt: _volt)))),
              for (final (i, v) in meggerVolts.indexed)
                Positioned(
                  key: ValueKey('volt-$v'),
                  left: i < 2 ? 10 : null,
                  right: i < 2 ? null : 10,
                  top: i.isEven ? 12 : 70,
                  width: 82,
                  height: 50,
                  child: Semantics(
                    label: meggerVoltLabel(v),
                    button: true,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openVolt(v),
                      child: CardAside(
                        aside: _voltAside.contains(v),
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
                          child: Center(
                            child: Text(meggerVoltLabel(v), style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  static Rect _knobPanelRect(MeggerGeo g) => Rect.fromCenter(center: Offset(180, g.floorY - 60), width: 264, height: 132);

  /// The [i]th knob position's button on the close-up (scene pixels).
  static Rect _voltRect(Rect panel, int i) =>
      Rect.fromLTWH(panel.left + (i < 2 ? 10 : panel.width - 92), panel.top + (i.isEven ? 12 : 70), 82, 50);

  /// The order the hand sweeps over things (shuffled once per play, so it never
  /// walks the procedure's order).
  final _sweepRng = math.Random();
  late final List<int> _roomOrder = List<int>.generate(8, (i) => i)..shuffle(_sweepRng);
  late final List<int> _knobOrder = List<int>.generate(meggerVolts.length, (i) => i)..shuffle(_sweepRng);

  /// The gesture hint (how to play, never what): a sweep over the two lead
  /// pairs, over everything the hands can reach, or over the knob positions.
  HintSpec? _hint() {
    final g = _geo;
    if (g == null) return null;
    if (_knobOpen) {
      final panel = _knobPanelRect(g);
      return HintSpec.sweep([for (final i in _knobOrder) _voltRect(panel, i)], space: HintSpace.scene);
    }
    if (_run.stage == 0) return HintSpec.sweep([g.leadsLeft, g.leadsRight], space: HintSpace.scene);
    final room = [
      g.switchBox,
      g.tester,
      Rect.fromCenter(center: g.earthClipRest.translate(-6, -14), width: 64, height: 64),
      g.terminalBox,
      Rect.fromCenter(center: g.earthBolt, width: 44, height: 40),
      Rect.fromCenter(center: g.knob, width: 56, height: 56),
      Rect.fromCenter(center: g.testButton.translate(0, -6), width: 52, height: 52),
      g.helperBox(clear: false).deflate(6),
    ];
    return HintSpec.sweep([
      for (final i in _roomOrder)
        if (i != 7 || !_run.helperClear) room[i],
    ], space: HintSpace.scene);
  }

  /// The way the live supply goes in the deadly picture.
  List<Offset> _zapPath(MeggerGeo g) {
    final box = g.traineeBox;
    final feet = Offset(box.center.dx, box.bottom - 2);
    return [g.terminals, Offset.lerp(g.terminals, g.hands, 0.5)!, g.hands, box.center, feet];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final stage = _run.stage;
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
              labels: MeggerPrepLines.rounds,
              done: {for (var i = 0; i < math.min(stage, 3); i++) i},
              current: stage >= 3 ? null : stage,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m, quiet),
            hint: _hint,
            hintWaiting: playing && !_blocked && !deckUp && !coworkerOnScreen && _card == null && _voltPreview == null,
            hintKey: '$stage|$_knobOpen|${_run.doneIds.length}|${_run.helperClear}',
            hintController: _hints,
            overlays: [
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
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (playing && _knobOpen && !_blocked && _voltPreview != null)
                Positioned.fill(
                  key: ValueKey('volt-preview-$_voltPreview'),
                  child: CardPreviewOverlay(
                    textBn: meggerVoltLabel(_voltPreview!),
                    icon: Icons.tune_rounded,
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirmVolt,
                    onReject: _rejectVolt,
                  ),
                ),
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
                  line: MeggerPrepLines.intro,
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
