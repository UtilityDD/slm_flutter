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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_hydraulic_pick_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm2_hydraulic_pick_world.dart' show HydFlaw, HydJob, HydKind;

// Lesson 2.9, কাজ 1: "দানবের যত্ন". In the tool store before a big-cable
// job: read the docket (crimp a lug on a big cable, or cut an armoured
// cable, and its size in sq mm), take a hydraulic tool off the pegboard, look
// it over by hand (run a finger along the body for oil at the seal, give the
// pump arm a stroke — it must move smoothly — and read a battery tool's
// charge), take it or send it to servicing. For a crimp, pick the die from
// the case that matches the cable size (the lesson's die chart); a lost die
// is never replaced by a near size — hold the job. Then do the job: pump until
// the release valve clicks open (letting go early leaves a weak crimp); for a
// cut, close the safety lock first, then pump. Three dockets, a fresh deal
// each play. Once a play the careless coworker (level 1's rival) peeps in
// with the lesson's shortcut: "একটু তেল চুঁইছে, চলবে", the near-size die,
// or letting go before the click. Built on the shared level kit
// (GAME_LEVEL_PLAYBOOK.md): guide first, full scene, corner guide, ◆ on the
// table → "কেন …?" → next docket by itself.
//
// Content (tool/all_training_chapters_bn.json, 2.9 only): daily check — no
// oil leak, smooth pumping; a leak means the seals are gone → servicing at
// once; the die chart, wrong die = weak dangerous crimp (myth); full pressure
// until the release valve opens with a click; the cutter's safety lock before
// pumping; hacksaw = slow, rough cut; battery tools: check the charge; 50 to
// 400/630 sq mm. The lesson gives no kN rating, so none is shown.
//
// Deadly: none. The lesson calls a finger between die and lug a serious
// injury, not a death, and none of its faults kill on the spot — every
// mistake here is a slip (flagged to the owner in REGISTER.md).
//
// Voice: the guide's lines on device TTS; the coworker's three pushes have no
// clip yet (HydLines.recordLines — the kit holds his caption, silent, until
// they are recorded); his exit line is the recorded "হুঁ! যা খুশি করুন।".
//
// The coworker (audit 2026-11-11): the decisive controls (taking a tool that
// is not the leaking one, holding the job, the stroke that would click) wait
// for him while he is due and his push fits now, so a fast play never skips
// him; they never wait on a move his line would give away (the leaking tool,
// a die when the right one is lost). Going on with the right work while he
// talks (pumping on, holding the job, taking a sound tool) refuses him;
// letting go while he says "let go", putting in a die while he says "the near
// one", or taking the leaking tool, is listening. Listening is always a slip.
// Nothing in the scene takes a touch while a right move is being praised
// ([ReasonTable.tableBusy]).

// ============================================================================
// Content
// ============================================================================

/// Cable sizes a die case is labelled with (sq mm).
const kHydSizes = [50, 70, 95, 120, 150, 185, 240, 300, 400];

/// Pump strokes to full pressure (the release valve clicks on the last one).
const kHydStrokes = 6;

@immutable
class HydTool {
  const HydTool({required this.id, required this.kind, this.flaw = HydFlaw.none});
  final String id;
  final HydKind kind;
  final HydFlaw flaw;
}

@immutable
class HydDocket {
  const HydDocket({required this.job, required this.size, required this.feederBn});
  final HydJob job;

  /// The cable size, sq mm.
  final int size;
  final String feederBn;
}

@immutable
class HydRoundDeal {
  const HydRoundDeal({required this.docket, required this.tools, this.slots = const [], this.missing});
  final HydDocket docket;
  final List<HydTool> tools;

  /// The die case's labelled slots (crimp dockets only).
  final List<int> slots;

  /// The slot whose die is lost (null: the case is full).
  final int? missing;

  bool get crimp => docket.job == HydJob.crimp;

  /// The right die for this docket is not in the case: the job must be held.
  bool get dieMissing => crimp && missing == docket.size;

  /// Dies in the case now.
  List<int> get dies => [for (final s in slots) if (s != missing) s];

  /// The tool this docket needs.
  bool fits(HydTool t) => t.kind.hydraulic && (crimp ? t.kind.crimps : t.kind == HydKind.cutter);
}

/// What the careless coworker pushes.
enum HydPush { leak, die, release }

@immutable
class HydDeal {
  const HydDeal({required this.rounds, required this.callRound, required this.push});
  final List<HydRoundDeal> rounds;

  /// The docket on which he peeps in (or a later one, if he could not).
  final int callRound;

  /// The shortcut he prefers to push (another, if that one is not possible).
  final HydPush push;
}

abstract final class HydLines {
  static const title = 'দানবের যত্ন';
  static const intro = 'মোটা কেবিলের কাজ! ডকেট দেখে হাইড্রোলিক টুল আর ডাই বাছুন — আগে যাচাই করে।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];

  // The tasks the guide repeats (a different way each time) when tapped.
  static const ask = 'ডকেট দেখুন। কোন টুলটা নেবেন?';
  static const inspectAsk = 'হাত বুলিয়ে, পাম্প করে দেখুন। নেবেন?';
  static const dieAsk = 'এবার ডাই। কোনটা?';
  static const crimpAsk = 'ল্যাগ বসানো। এবার পাম্প করুন।';
  static const cutAsk = 'কেবিল ব্লেডে বসানো। এবার কাটুন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const docket = 'ডকেট';
  static const jobWord = 'কাজ';
  static String jobBn(HydJob j) => j == HydJob.crimp ? 'ল্যাগ ক্রিম্প' : 'আর্মার্ড কেবিল কাটা';
  static String sizeBn(int s) => '$s স্কয়ার মিমি';
  static String line(HydDocket d) => '$jobWord: ${jobBn(d.job)} · ${sizeBn(d.size)}';
  static const toolLabel = 'টুল';
  static const handLabel = 'টুল হাতে';
  static const dieLabel = 'ডাই';
  static const take = 'এটাই নিন';
  static const putBack = 'ফেরত রাখুন';
  static const pump = 'পাম্প';
  static const trigger = 'ট্রিগার';
  static const release = 'ছেড়ে দিন';
  static const lock = 'সেফটি লক';
  static const hold = 'ঠিক ডাই নেই — কাজ স্থগিত';
  static const click = 'ক্লিক!';
  static const serviceTag = 'সার্ভিসিং';
  static const chargeTag = 'চার্জে';

  // The reasons (lesson 2.9). Every card is about the same length.
  static const crimpAskWhy = 'কেন এই টুল আর এই ডাই?';
  static const cutAskWhy = 'কেন এভাবে কাটলেন?';
  static const holdAskWhy = 'কেন কাজ স্থগিত করলেন?';

  static String dieMatch(int s) => 'ডকেটে $s স্কয়ার মিমি, ডাইও $s-এর';
  static const crimpSound = [
    'লিক নেই, পাম্প মসৃণ; চাপ ক্লিক পর্যন্ত',
    'চার্ট মিলিয়ে ডাই, টুলটাও আগে যাচাই',
  ];
  static const crimpMyths = [
    'কাছাকাছি সাইজের ডাইতেও ক্রিম্প হয়ে যায়',
    'একটু তেল চুঁইলে টুলের কিছুই হয় না',
    'হাতের ক্রিম্পারেও মোটা কেবিল চেপে যায়',
    'ক্লিকের আগে ছাড়লেও ক্রিম্প ঠিক থাকে',
    'যেটা হাতের কাছে ছিল সেটাই তুলে নিলাম',
  ];

  /// The case's other sizes: true of another docket, not this one.
  static List<int> _others(HydRoundDeal r) => [for (final s in r.slots) if (s != r.docket.size) s];

  static List<String> crimpRight(HydRoundDeal r) => [dieMatch(r.docket.size), ...crimpSound];
  static List<String> crimpWrong(HydRoundDeal r) => [for (final s in _others(r).take(2)) dieMatch(s), ...crimpMyths];

  static const cutRight = [
    'আর্মার্ড কেবিলে হাইড্রোলিক কাটার, লিক নেই',
    'সেফটি লক বন্ধ করে পাম্প, তাই পরিষ্কার কাট',
    'টুল যাচাই করা, তাই মসৃণ পরিষ্কার কাট',
  ];
  static const cutWrong = [
    'হ্যাকস দিয়েও এমন পরিষ্কার কাট হয়ে যায়',
    'সেফটি লক না দিলেও কাটার ঠিকই কাটে',
    'একটু তেল চুঁইলে কাটারের কিছু হয় না',
    'যেকোনো টুলেই আর্মার্ড কেবিল কাটা যায়',
    'তাড়া ছিল, তাই যেটা পেলাম সেটাই নিলাম',
  ];

  static String holdMatch(int s) => '$s-এর ডাই নেই, কাছাকাছি সাইজে নয়';
  static const holdSound = [
    'ঠিক ডাই না পেলে ক্রিম্প নয়, আগে জানাই',
    'ভুল ডাইয়ে দুর্বল ক্রিম্প, তাই কাজ নয়',
  ];
  static const holdExcuses = [
    'শাটডাউনের সময় কম, তাই কাজটা বাদ দিলাম',
    'টুলটা ভারী লাগছিল, তাই কাজটা রাখলাম',
    'স্টোরকিপার বকবে, তাই কিছুই নিলাম না',
    'সুপারভাইজার না এলে কাজ শুরু হয় না',
    'রোদ বেশি, দুপুরে কাজ না করাই ভালো',
  ];
  static List<String> holdRight(HydRoundDeal r) => [holdMatch(r.docket.size), ...holdSound];
  static List<String> holdWrong(HydRoundDeal r) => [for (final s in _others(r).take(2)) holdMatch(s), ...holdExcuses];

  /// The careless coworker. His exit line is already recorded in his voice.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLeak = CoworkerScript(
    line: 'একটু তেল চুঁইছে, চলবে! ওটা দিয়েই কাজ সেরে নাও।',
    exitLine: coworkerExit,
    right: ['না — লিক মানে সিল নষ্ট, সার্ভিসিং-এ', 'তেল চুঁইলে টুল নেব না, অন্যটা দেখি', 'লিক করা টুল মাঠে চাপ হারাবে, নেব না'],
    wrong: [
      'ঠিক, একটু তেলে কিছুই হবে না',
      'লিকটা পরে দেখাব, এখন এটাই নিই',
      'তেল মুছে নিলেই টুল ঠিক হয়ে যায়',
      'একবার লিক নিয়েই চালিয়ে নিই',
      'সবাই তো এভাবেই কাজ সেরে নেয়',
    ],
    asks: ['ও বলছে লিকেও চলবে। আপনি কী করবেন?', 'চুঁইয়ে পড়া টুল নেবেন, না সার্ভিসিং-এ?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerDie = CoworkerScript(
    line: 'ঠিক ডাইটা নেই? পাশের সাইজেরটা দিয়েই চেপে দাও, চলবে!',
    exitLine: coworkerExit,
    right: ['ঠিক সাইজের ডাই ছাড়া ক্রিম্প নয়', 'কাছাকাছি ডাইয়ে ক্রিম্প দুর্বল', 'চার্টের ডাই না পেলে কাজ স্থগিত'],
    wrong: [
      'ঠিক, পাশের সাইজেই চেপে দিই',
      'একটু বড় ডাই হলেও চলে যাবে',
      'বেশি করে পাম্প দিলেই মিলে যাবে',
      'একবার অন্য ডাইয়েই চালিয়ে নিই',
      'সবাই তো এভাবেই ক্রিম্প করে',
    ],
    asks: ['ও বলছে পাশের ডাইয়েই চলবে। আপনি কী করবেন?', 'কাছাকাছি ডাই নেবেন, না কাজ স্থগিত?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerRelease = CoworkerScript(
    line: 'অনেক চেপেছ, হয়ে গেছে! ছেড়ে দাও, সময় নেই।',
    exitLine: coworkerExit,
    right: ['ভাল্ভ ক্লিক না করা পর্যন্ত পাম্প', 'পুরো চাপ না হলে ক্রিম্প দুর্বল', 'ক্লিকের শব্দ শুনে তবেই ছাড়ব'],
    wrong: [
      'ঠিক, যথেষ্ট চেপেছি, ছেড়ে দিই',
      'অর্ধেক চাপেই ল্যাগ আটকে যায়',
      'সময় নেই, তাই এখনই ছেড়ে দিই',
      'একবার কম চাপেই চালিয়ে নিই',
      'দেখতে তো চাপা হয়েছে মনে হয়',
    ],
    asks: ['ও বলছে ছেড়ে দিতে। আপনি কী করবেন?', 'এখনই ছাড়বেন, না ক্লিক পর্যন্ত?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(HydPush p) => switch (p) {
        HydPush.leak => coworkerLeak,
        HydPush.die => coworkerDie,
        HydPush.release => coworkerRelease,
      };

  /// His new lines, to be recorded in his voice.
  static List<String> get recordLines => [coworkerLeak.line, coworkerDie.line, coworkerRelease.line];

  static const callHeld = 'ঠিক! চাপে পড়ে নিয়ম ছাড়েননি।';
  static const asideService = 'ঠিক — লিক বা আটকানো টুল সার্ভিসিং-এ।';
  static const asideCharge = 'ঠিক — চার্জ নেই, চার্জে দিন।';
  /// Neutral: said for a sound tool and an unexamined faulty one alike.
  static const putBackLine = 'হুকে রাখলেন। ডকেট মিলিয়ে বাছুন।';
  static const allSet = 'দানবের যত্নে পাকা হাত! টুল, ডাই আর পুরো চাপ — সব ঠিক।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — টুল যাচাই, ঠিক ডাই, পুরো চাপ।';
  static const caughtDie = 'চার্ট মিলিয়ে ঠিক ডাই';
  static const caughtClick = 'ভাল্ভ ক্লিক পর্যন্ত পুরো চাপ';
  static const caughtLock = 'সেফটি লক বন্ধ করে কাট';
  static const caughtHold = 'ডাই না পেয়ে কাজ স্থগিত';
  static const caughtService = 'খারাপ টুল সার্ভিসিং-এ';
  static const caughtCharge = 'চার্জহীন টুল বাদ';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const feeders = ['রামপুর ফিডার', 'হাটখোলা ফিডার', 'নদীপাড় ফিডার', 'স্টেশন রোড ফিডার', 'কলেজপাড়া ফিডার'];
}

abstract final class HydMistakes {
  static const _art = 'assets/game/art/m2_hydraulic_pick';
  static const leak = DoMistake(
    key: '2.9/hyd/oil-leak',
    textBn: 'টুলের গায়ে তেল চুঁইছে — ভেতরের রাবার সিল নষ্ট। এমন টুল মাঠে আপনাকে হতাশ করবে; অবিলম্বে সার্ভিসিং-এ পাঠান।',
    art: '$_art/tool_check.svg',
    lessonPoint: 3,
  );
  static const pump = DoMistake(
    key: '2.9/hyd/stiff-pump',
    textBn: 'পাম্প মসৃণ নয় — হাতল মাঝপথে আটকে যাচ্ছে। ব্যবহারের আগে দেখুন পাম্পিং অ্যাকশন মসৃণ কিনা; না হলে সার্ভিসিং-এ।',
    art: '$_art/tool_check.svg',
    lessonPoint: 0,
  );
  static const battery = DoMistake(
    key: '2.9/hyd/flat-battery',
    textBn: 'ব্যাটারিতে চার্জ নেই — কাজের মাঝপথে টুল থেমে যাবে। ব্যাটারি চালিত টুলের চার্জ আগেই দেখে নিন।',
    art: '$_art/tool_check.svg',
  );
  static const handTool = DoMistake(
    key: '2.9/hyd/hand-crimper',
    textBn: 'ছোট তারের জন্য হাতের শক্তি যথেষ্ট, মোটা কেবিলে নয় — হাইড্রোলিক টুল চারদিক থেকে সমান চাপ দিয়ে নিখুঁত ক্রিম্প করে।',
    art: '$_art/right_tool.svg',
    lessonPoint: 1,
  );
  static const hacksaw = DoMistake(
    key: '2.9/hyd/hacksaw',
    textBn: 'হ্যাকস দিয়ে মোটা কেবিল কাটতে অনেক সময় লাগে, কাট অমসৃণ হয়। জয়েন্টের জন্য হাইড্রোলিক কাটারের পরিষ্কার কাট চাই।',
    art: '$_art/right_tool.svg',
    lessonPoint: 2,
  );
  static const wrongJob = DoMistake(
    key: '2.9/hyd/wrong-job',
    textBn: 'ডকেটের কাজ মিলিয়ে টুল নিন — ল্যাগ চাপতে হাইড্রোলিক ক্রিম্পার, কেবিল কাটতে হাইড্রোলিক কাটার।',
    art: '$_art/right_tool.svg',
    lessonPoint: 1,
  );
  static const wrongDie = DoMistake(
    key: '2.9/hyd/wrong-die',
    textBn: 'ভুল ডাই — প্রতিটি ডাই নির্দিষ্ট সাইজের চাপ আর আকৃতির জন্য। ভুল ডাইয়ে দুর্বল, বিপজ্জনক ক্রিম্প হয়। চার্ট দেখে ডাই নিন।',
    art: '$_art/die_match.svg',
    lessonPoint: 1,
  );
  static const heldWhenDie = DoMistake(
    key: '2.9/hyd/held-when-die',
    textBn: 'ঠিক ডাইটা বাক্সেই ছিল — ডকেটের কেবিল সাইজ আর ডাইয়ের গায়ের সাইজ মিলিয়ে দেখুন।',
    art: '$_art/die_match.svg',
    lessonPoint: 1,
  );
  static const halfCrimp = DoMistake(
    key: '2.9/hyd/half-crimp',
    textBn: 'ভাল্ভ ক্লিক করার আগেই ছেড়ে দিলেন — পুরো চাপ হয়নি, ক্রিম্প দুর্বল। প্রেসার রিলিজ ভাল্ভ নিজে খোলা পর্যন্ত পাম্প করুন।',
    art: '$_art/valve_click.svg',
    lessonPoint: 1,
  );
  static const noLock = DoMistake(
    key: '2.9/hyd/no-safety-lock',
    textBn: 'সেফটি লক বন্ধ না করেই পাম্প — কেবিল ব্লেডে ঠিকমতো বসিয়ে আগে সেফটি লক বন্ধ করুন, তারপর পাম্প।',
    art: '$_art/safety_lock.svg',
    lessonPoint: 2,
  );
  static const all = [leak, pump, battery, handTool, hacksaw, wrongJob, wrongDie, heldWhenDie, halfCrimp, noLock];

  static DoMistake forFlaw(HydFlaw f) => switch (f) {
        HydFlaw.leak => leak,
        HydFlaw.pump => pump,
        _ => battery,
      };
}

/// The die case: the docket's size and its neighbours.
List<int> _slotsAround(int size) {
  final i = kHydSizes.indexOf(size);
  final from = (i - 2).clamp(0, kHydSizes.length - 5);
  return kHydSizes.sublist(from, from + 5);
}

/// A fresh store each play: jobs, sizes, which tool is faulty and how, the
/// pegboard order, a lost die, and the coworker's moment vary.
HydDeal dealHyd(math.Random rng) {
  var n = 0;
  HydTool tool(HydKind k, [HydFlaw f = HydFlaw.none]) => HydTool(id: 'tool${n++}', kind: k, flaw: f);
  String feeder() => HydLines.feeders[rng.nextInt(HydLines.feeders.length)];

  final call = rng.nextInt(3);
  final pushes = [HydPush.leak, if (call != 1) HydPush.release, if (call == 2) HydPush.die];
  final push = pushes[rng.nextInt(pushes.length)];
  final missing = (call == 2 && push == HydPush.die) || rng.nextBool();

  HydFlaw flawFor(int round, HydKind k) {
    if (round == call && push == HydPush.leak) return HydFlaw.leak;
    final opts = k == HydKind.batteryCrimper ? const [HydFlaw.leak, HydFlaw.battery] : const [HydFlaw.leak, HydFlaw.pump];
    return opts[rng.nextInt(2)];
  }

  List<HydTool> crimpTools(int round) {
    final battery = rng.nextBool();
    final right = battery ? HydKind.batteryCrimper : HydKind.crimper;
    final twin = battery ? HydKind.crimper : HydKind.batteryCrimper;
    return [tool(right), tool(twin, flawFor(round, twin)), tool(HydKind.handCrimper), tool(HydKind.cutter)]..shuffle(rng);
  }

  final s1 = const [95, 120, 150, 185][rng.nextInt(4)];
  final s2 = const [300, 400][rng.nextInt(2)];
  final s3 = const [240, 300, 400][rng.nextInt(3)];
  final r1 = HydRoundDeal(
    docket: HydDocket(job: HydJob.crimp, size: s1, feederBn: feeder()),
    tools: crimpTools(0),
    slots: _slotsAround(s1),
  );
  final r2 = HydRoundDeal(
    docket: HydDocket(job: HydJob.cut, size: s2, feederBn: feeder()),
    tools: [tool(HydKind.cutter), tool(HydKind.cutter, flawFor(1, HydKind.cutter)), tool(HydKind.hacksaw), tool(rng.nextBool() ? HydKind.crimper : HydKind.batteryCrimper)]
      ..shuffle(rng),
  );
  final r3 = HydRoundDeal(
    docket: HydDocket(job: HydJob.crimp, size: s3, feederBn: feeder()),
    tools: crimpTools(2),
    slots: _slotsAround(s3),
    missing: missing ? s3 : null,
  );
  return HydDeal(rounds: [r1, r2, r3], callRound: call, push: push);
}

/// Where a docket stands.
enum HydStage { tool, die, work }

enum HydVerdict { right, slip, more }

@immutable
class HydOutcome {
  const HydOutcome(this.verdict, {this.mistake});
  final HydVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class HydRun {
  HydRun(this.deal);
  final HydDeal deal;
  int round = 0;
  int slips = 0;
  HydStage stage = HydStage.tool;

  /// This docket is decided (job done, or held): the reason comes, then [next].
  bool shown = false;

  /// The tool taken for the job.
  HydTool? taken;

  /// The die put in the head.
  int? die;

  /// Pump strokes so far; the release valve clicks at [kHydStrokes].
  int pressure = 0;

  /// The cutter's safety lock is closed.
  bool locked = false;

  /// Tools sent to servicing / charging on this docket.
  final Set<String> rejected = {};

  /// Tools whose fault the player has seen (found by hand, or on a card).
  final Set<String> spotted = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done;
  HydRoundDeal get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get clicked => pressure >= kHydStrokes;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  HydOutcome _slip(DoMistake m) {
    slips++;
    return HydOutcome(HydVerdict.slip, mistake: m);
  }

  /// Takes [t] off the pegboard for the job.
  HydOutcome take(HydTool t) {
    if (done || shown || stage != HydStage.tool || rejected.contains(t.id)) return const HydOutcome(HydVerdict.more);
    final r = current;
    if (!r.fits(t)) {
      if (t.kind == HydKind.handCrimper && r.crimp) return _slip(HydMistakes.handTool);
      if (t.kind == HydKind.hacksaw) return _slip(HydMistakes.hacksaw);
      return _slip(HydMistakes.wrongJob);
    }
    if (t.flaw != HydFlaw.none) {
      rejected.add(t.id);
      spotted.add(t.id);
      return _slip(HydMistakes.forFlaw(t.flaw));
    }
    taken = t;
    stage = r.crimp ? HydStage.die : HydStage.work;
    return const HydOutcome(HydVerdict.right);
  }

  /// The player's hand (or eye) found [t]'s fault in the close look.
  void spot(HydTool t) {
    if (t.flaw != HydFlaw.none) spotted.add(t.id);
  }

  /// Puts [t] back: a tool whose fault was found goes to servicing (or to be
  /// charged) — true; anything else goes back on its hook — false. Never
  /// costs anything, and never tells which tools are faulty.
  bool putBack(HydTool t) {
    if (done || shown || stage != HydStage.tool || rejected.contains(t.id)) return false;
    if (!spotted.contains(t.id)) return false;
    rejected.add(t.id);
    _tag(t.flaw == HydFlaw.battery ? HydLines.caughtCharge : HydLines.caughtService);
    return true;
  }

  /// Puts the [size] die in the head.
  HydOutcome pickDie(int size) {
    if (done || shown || stage != HydStage.die) return const HydOutcome(HydVerdict.more);
    if (size != current.docket.size || !current.dies.contains(size)) return _slip(HydMistakes.wrongDie);
    die = size;
    stage = HydStage.work;
    _tag(HydLines.caughtDie);
    return const HydOutcome(HydVerdict.right);
  }

  /// "ঠিক ডাই নেই — কাজ স্থগিত".
  HydOutcome holdJob() {
    if (done || shown || stage != HydStage.die) return const HydOutcome(HydVerdict.more);
    if (!current.dieMissing) return _slip(HydMistakes.heldWhenDie);
    shown = true;
    _tag(HydLines.caughtHold);
    return const HydOutcome(HydVerdict.right);
  }

  /// Closes (or opens) the cutter's safety lock.
  void toggleLock() {
    if (done || shown || stage != HydStage.work || current.crimp) return;
    locked = !locked;
  }

  /// One stroke of the pump: [HydVerdict.right] when the release valve
  /// clicks (crimp) or the blade cuts through (cut).
  HydOutcome stroke() {
    if (done || shown || stage != HydStage.work) return const HydOutcome(HydVerdict.more);
    if (!current.crimp && !locked) return _slip(HydMistakes.noLock);
    pressure++;
    if (!clicked) return const HydOutcome(HydVerdict.more);
    shown = true;
    _tag(current.crimp ? HydLines.caughtClick : HydLines.caughtLock);
    return const HydOutcome(HydVerdict.right);
  }

  /// Lets go of the pump before the click: a weak crimp; start again.
  HydOutcome release() {
    if (done || shown || stage != HydStage.work || !current.crimp || pressure == 0) return const HydOutcome(HydVerdict.more);
    pressure = 0;
    return _slip(HydMistakes.halfCrimp);
  }

  /// Does what the coworker pushed (the player listened to him): take the
  /// leaking tool, put in the near-size die, or let go before the click.
  /// Listening is always a slip, even if the act itself can no longer be
  /// done (the docket moved on meanwhile).
  HydOutcome follow(HydPush p) {
    final r = current;
    HydOutcome? o;
    switch (p) {
      case HydPush.leak:
        for (final t in r.tools) {
          if (t.flaw == HydFlaw.leak && r.fits(t) && !rejected.contains(t.id)) {
            o = take(t);
            break;
          }
        }
      case HydPush.die:
        if (r.crimp && r.dies.isNotEmpty) o = pickDie(hydNearDie(r));
      case HydPush.release:
        o = release();
    }
    if (o != null && o.verdict == HydVerdict.slip) return o;
    return _slip(switch (p) {
      HydPush.leak => HydMistakes.leak,
      HydPush.die => HydMistakes.wrongDie,
      HydPush.release => HydMistakes.halfCrimp,
    });
  }

  /// The next docket (after the reason).
  void next() {
    round++;
    stage = HydStage.tool;
    shown = false;
    taken = null;
    die = null;
    pressure = 0;
    locked = false;
    rejected.clear();
    spotted.clear();
  }
}

/// What the careless coworker can push now: a leaking tool still on the
/// pegboard (while choosing), the near-size die (when the right die is lost),
/// or letting go mid-crimp. The dealt push first, else another; null: none.
HydPush? hydPushFor(HydRun run, {required HydPush prefer}) {
  if (run.done || run.shown) return null;
  final r = run.current;
  final can = <HydPush>{
    if (run.stage == HydStage.tool && r.tools.any((t) => t.flaw == HydFlaw.leak && r.fits(t) && !run.rejected.contains(t.id))) HydPush.leak,
    if (run.stage == HydStage.die && r.dieMissing) HydPush.die,
    if (run.stage == HydStage.work && r.crimp && run.pressure >= 1 && run.pressure < kHydStrokes) HydPush.release,
  };
  if (can.contains(prefer)) return prefer;
  return can.isEmpty ? null : can.first;
}

/// Could one of his pushes still fit later on this docket? (A crimp: the lost
/// die or letting go mid-pump is still ahead. A cut: only the leaking tool,
/// which fits now or never.)
bool hydPushLater(HydRun run) {
  if (run.done || run.shown || !run.current.crimp) return false;
  return switch (run.stage) {
    HydStage.tool || HydStage.die => true,
    HydStage.work => run.pressure < kHydStrokes,
  };
}

/// The die nearest the docket's size still in the case (what he pushes).
int hydNearDie(HydRoundDeal r) {
  final d = [...r.dies]..sort((a, b) => (a - r.docket.size).abs().compareTo((b - r.docket.size).abs()));
  return d.firstWhere((s) => s != r.docket.size, orElse: () => d.first);
}

@immutable
class M2HydraulicPack {
  const M2HydraulicPack({required this.id, required this.titleBn, this.quickMs = 90000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2HydraulicPack29a = M2HydraulicPack(id: 'do_2_9_a', titleBn: HydLines.title);
const m2HydraulicPacks = {'do_2_9_a': m2HydraulicPack29a};

// ============================================================================
// Page
// ============================================================================

class M2HydraulicPage extends StatefulWidget {
  const M2HydraulicPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2HydraulicPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2HydraulicPage> createState() => _M2HydraulicPageState();
}

class _M2HydraulicPageState extends State<M2HydraulicPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _HydRunPage(
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

class _HydRunPage extends ConsumerStatefulWidget {
  const _HydRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2HydraulicPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_HydRunPage> createState() => _HydRunPageState();
}

class _HydRunPageState extends ConsumerState<_HydRunPage> with DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final HydRun _run = HydRun(dealHyd(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The tool in the trainee's hands (the close look).
  HydTool? _held;
  var _docketOpen = false;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  HydPush _push = HydPush.leak;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how to interact, never which tool / die is right).
  final _hints = IdleHintController();
  final _zoomKey = GlobalKey();
  final _bodyKey = GlobalKey();
  final _tryKey = GlobalKey();
  final _backKey = GlobalKey();
  final _takeKey = GlobalKey();
  final _caseKey = GlobalKey();
  final _holdKey = GlobalKey();
  final _leftKey = GlobalKey();
  final _pumpKey = GlobalKey();

  /// The scene's design height (the pegboard hooks for the sweep hint).
  double _sceneH = 640;

  /// The finger has run along the held tool's body.
  var _felt = false;

  String get _rungId => widget.ctx.rungId;

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

  void _cue(String path, double volume) {
    if (!_muted) unawaited(ZlFx.cue(path, volume: volume, muted: false));
  }

  String get _task {
    if (_held != null) return HydLines.inspectAsk;
    return switch (_run.stage) {
      HydStage.tool => HydLines.ask,
      HydStage.die => HydLines.dieAsk,
      HydStage.work => _run.current.crimp ? HydLines.crimpAsk : HydLines.cutAsk,
    };
  }

  // ---- flow -----------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([HydLines.ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  /// The scene takes no input: intro, a card, the result, a decided docket,
  /// or a right move being praised ([tableBusy] covers the praise window and
  /// the reason deck).
  bool get _blocked => _intro || _ended || _card != null || tableBusy || _run.shown || struckOut;

  /// A decisive control waits for him while he is due and his push fits now
  /// (a fast play never skips him).
  bool _waitForHim() => hydPushFor(_run, prefer: _run.deal.push) != null && holdForCoworker();

  /// He is talking (beat 1, before his deck is up).
  bool get _beatOne => coworkerOpen && !coworkerChoiceUp;

  /// The leaking tool for this docket, still on the board.
  bool _leaking(HydTool t) => t.flaw == HydFlaw.leak && _run.current.fits(t) && !_run.rejected.contains(t.id);

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// Going on with the right work while he is still talking refuses him too.
  void _goOn(Offset at) {
    if (coworkerOpen && !coworkerChoiceUp) unawaited(answerCoworker(true, at, direct: true));
  }

  /// A tool comes off the pegboard into the trainee's hands. While he talks
  /// the pegboard waits, the same for every hook (a different answer on one
  /// hook would mark the leaking tool); his deck follows.
  void _pick(HydTool t, Offset at) {
    if (_blocked || coworkerOpen) return;
    if (_held != null || _docketOpen || _run.stage != HydStage.tool || _run.rejected.contains(t.id)) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/impact_metal.ogg', 0.45);
    _hush();
    setState(() {
      _held = t;
      _felt = false;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([HydLines.inspectAsk]));
  }

  /// A fault came into view in the close look.
  void _found() {
    final t = _held;
    if (t != null) _run.spot(t);
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tock.wav', 0.6);
  }

  void _putBack() {
    final t = _held;
    if (t == null || _blocked || coworkerChoiceUp) return;
    // Sending the leaking tool he pushes to servicing refuses him.
    if (_beatOne && _push == HydPush.leak && _leaking(t) && _run.spotted.contains(t.id)) {
      _goOn(MediaQuery.sizeOf(context).center(Offset.zero));
    }
    final aside = _run.putBack(t);
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (aside) {
      _cue('sounds/learn/tag_slap.wav', 0.6);
      unawaited(_sayChain([t.flaw == HydFlaw.battery ? HydLines.asideCharge : HydLines.asideService, HydLines.ask], mood: GuideMood.glad));
    } else {
      _cue('sounds/intro/drop.ogg', 0.4);
      unawaited(_sayChain([HydLines.putBackLine]));
    }
  }

  void _take(Offset at) {
    final t = _held;
    if (t == null || _blocked || coworkerChoiceUp) return;
    if (_beatOne) {
      if (_push == HydPush.leak && _leaking(t)) {
        // Took the leaking tool while he said "it'll do": listened.
        setState(() => _held = null);
        unawaited(answerCoworker(false, at));
        return;
      }
      _goOn(at);
    }
    // He waits on the take that would finish the tool step. Not on the
    // leaking tool itself: his "it'll do" would name its fault before the
    // player found it — that take slips on its own.
    if (!_leaking(t) && _waitForHim()) return;
    setState(() => _held = null);
    final o = _run.take(t);
    if (o.verdict == HydVerdict.right) {
      HapticFeedback.lightImpact();
      _cue('sounds/intro/confirm.ogg', 0.5);
      setState(() => _setMode(LinemanMode.hold));
      unawaited(_sayChain([_run.stage == HydStage.die ? HydLines.dieAsk : HydLines.cutAsk]));
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, at));
  }

  void _pickDie(int size, Offset at) {
    if (_blocked || coworkerChoiceUp) return;
    if (_beatOne) {
      // A die put in while he says "the near one will do": listened (a slip).
      if (_push == HydPush.die) unawaited(answerCoworker(false, at));
      return;
    }
    // No hold here: with the right die lost every die is wrong, and his "the
    // right die isn't there?" would give that away. He waits on the hold.
    final o = _run.pickDie(size);
    if (o.verdict == HydVerdict.right) {
      HapticFeedback.lightImpact();
      _cue('sounds/intro/impact_metal.ogg', 0.5);
      setState(() {});
      unawaited(_sayChain([HydLines.crimpAsk]));
      return;
    }
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, at));
  }

  void _holdJob(Offset at) {
    if (_blocked) return;
    _goOn(at);
    if (coworkerOpen) return;
    if (_waitForHim()) return;
    _hush();
    final o = _run.holdJob();
    if (o.verdict == HydVerdict.right) {
      HapticFeedback.mediumImpact();
      _cue('sounds/quiz_right.wav', 0.6);
      setState(() => _setMode(LinemanMode.cheer));
      final r = _run.current;
      _ask(20, () => dealChoices(HydLines.holdRight(r), HydLines.holdWrong(r), widget.rng), HydLines.holdAskWhy);
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, at));
  }

  void _toggleLock() {
    if (_blocked || coworkerOpen) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', 0.6);
    setState(_run.toggleLock);
  }

  void _stroke(Offset at) {
    if (_blocked || coworkerChoiceUp) return;
    // Pumping on while he talks refuses him (for "let go" too: pumping to the
    // click is the rule) — he leaves before the stroke, so the reason deck can
    // never open over his deck.
    _goOn(at);
    if (_run.pressure >= kHydStrokes - 1 && _waitForHim()) return;
    final o = _run.stroke();
    switch (o.verdict) {
      case HydVerdict.more:
        HapticFeedback.selectionClick();
        _cue('sounds/learn/tock.wav', 0.45);
        setState(() {});
      case HydVerdict.right:
        HapticFeedback.heavyImpact();
        final crimp = _run.current.crimp;
        _cue(crimp ? 'sounds/intro/click.ogg' : 'sounds/intro/impact_metal.ogg', 0.8);
        _cue('sounds/quiz_right.wav', 0.5);
        setState(() => _setMode(LinemanMode.cheer));
        final r = _run.current;
        _ask(
          15,
          () => crimp ? dealChoices(HydLines.crimpRight(r), HydLines.crimpWrong(r), widget.rng) : dealChoices(HydLines.cutRight, HydLines.cutWrong, widget.rng),
          crimp ? HydLines.crimpAskWhy : HydLines.cutAskWhy,
        );
      case HydVerdict.slip:
        final m = o.mistake;
        if (m != null) unawaited(_slip(m, at));
    }
  }

  void _release(Offset at) {
    if (_blocked || coworkerChoiceUp) return;
    if (_beatOne) {
      // Let go while he says "let go": listened (a slip).
      if (_push == HydPush.release) unawaited(answerCoworker(false, at));
      return;
    }
    final o = _run.release();
    final m = o.mistake;
    if (m != null) {
      setState(() => _setMode(LinemanMode.worried));
      unawaited(_slip(m, at));
    }
  }

  /// A right move: the ◆ wait on the table, then "কেন …?".
  void _ask(int points, List<ChoiceOption> Function() deal, String question) {
    putOnTable(points);
    final round = _run.round;
    unawaited(askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended));
  }

  void _nextRound() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() => _setMode(LinemanMode.idle));
    _cue('sounds/quiz_flip.wav', 0.5);
    _armCoworker();
    unawaited(_sayChain([HydLines.ask]));
  }

  void _openDocket() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_flip.wav', 0.4);
    setState(() => _docketOpen = true);
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
  void onReasonPaid() => _nextRound();

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => HydLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    // His push must fit now; once none can on this docket, he waits for the
    // next one (re-armed in [_nextRound]).
    final p = hydPushFor(_run, prefer: _run.deal.push);
    if (p == null) return hydPushLater(_run) ? false : null;
    if (_blocked || _docketOpen || (_held != null && !coworkerHeld)) return false;
    // The lost die: he comes only through the hold. Arriving on his timer
    // while the player still reads the die case, his "the right die isn't
    // there?" would give the lost die away (he stays armed for the hold).
    if (p == HydPush.die && !coworkerHeld) return false;
    _push = p;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Did what he said: the leaking tool, the near die, or let go early —
      // always a slip.
      final h = _held;
      final o = _run.follow(_push);
      setState(() {
        if (h != null && _run.rejected.contains(h.id)) _held = null;
        _setMode(LinemanMode.worried);
      });
      final m = o.mistake;
      if (m != null) await _slip(m, origin);
      return;
    }
    _run.caught.add(HydLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([HydLines.callHeld, _task], mood: GuideMood.glad);
    }());
  }

  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? HydLines.tapWhy[_nudgeN++ % HydLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // ---- mistakes ---------------------------------------------------------------------

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.wav', 0.7);
    _hush();
    setState(() => _card = m);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('hyd/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _setMode(_run.stage == HydStage.tool ? LinemanMode.idle : LinemanMode.hold);
    });
    unawaited(_sayChain([_task]));
  }

  // ---- score and result ---------------------------------------------------------------

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
    await _say(!_run.passed ? HydLines.fail : (_quickBonus ? HydLines.quick : HydLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    _sceneH = m.height;
    final geo = HydStoreGeo(m.height);
    final r = _run.current;
    final aside = [for (final t in r.tools) if (_run.rejected.contains(t.id)) t];
    final canPick = !_blocked && _held == null && !_docketOpen && _run.stage == HydStage.tool;
    final taken = _run.taken;
    return [
      Positioned.fill(
        key: const ValueKey('store'),
        child: RepaintBoundary(child: CustomPaint(painter: HydStorePainter(geo))),
      ),
      Positioned.fromRect(
        key: ValueKey('docket-${_run.round}'),
        rect: geo.docket,
        child: _DocketSheet(docket: r.docket, quiet: quiet, onTap: _openDocket),
      ),
      for (var i = 0; i < r.tools.length; i++)
        Positioned.fromRect(
          key: ValueKey('hook-${_run.round}-$i'),
          rect: geo.slot(i, r.tools.length),
          child: DoDealIn(
            index: i,
            quiet: quiet,
            muted: true,
            child: _BoardTool(
              tool: r.tools[i],
              gone: _run.rejected.contains(r.tools[i].id) || _held?.id == r.tools[i].id || taken?.id == r.tools[i].id,
              enabled: canPick,
              onTake: (at) => _pick(r.tools[i], at),
            ),
          ),
        ),
      if (r.crimp)
        Positioned.fromRect(
          key: ValueKey('case-${_run.round}'),
          rect: geo.dieCase,
          child: IgnorePointer(child: _DieCase(round: r, small: true, enabled: false, onPick: (_, _) {}, quiet: quiet)),
        ),
      for (var i = 0; i < aside.length && i < 2; i++)
        Positioned.fromRect(
          key: ValueKey('aside-${aside[i].id}'),
          rect: Rect.fromLTWH(geo.crate.left + 4 + i * 50.0, geo.crate.top - 34, 56, 46),
          child: _AsideTool(tool: aside[i], quiet: quiet),
        ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
    ];
  }

  // ---- gesture hints ------------------------------------------------------------

  /// The level waits for the player's hands on the scene (the decks carry
  /// their own sweep hint).
  bool get _hintWaiting =>
      !_intro && _mark == null && !struckOut && !_ended && _card == null && !tableBusy && !coworkerOnScreen && !_run.shown && !_run.done;

  Object get _hintKey => '${_run.round}-${_run.stage.name}-${_held?.id}-$_docketOpen';

  /// How to interact now: a sweep over every choice, a short generic slide
  /// along the held tool, a tap to put the docket back. Never which one.
  HintSpec? _hint() {
    if (_docketOpen) return HintSpec.tapOn(_zoomKey);
    final held = _held;
    if (held != null) {
      final body = HintSpec.globalRectOf(_bodyKey);
      if (held.kind.hydraulic && !_felt && body != null) {
        // From the middle toward the handle end: well clear of the seal
        // (kHydLeakU), so tracing the hint never finds a fault for the player.
        return HintSpec.drag(Offset(body.left + body.width * 0.5, body.top + body.height * 0.6), toward: const Offset(1, 0), travel: math.min(64, body.width * 0.2));
      }
      return HintSpec.sweepOver([if (held.kind.hydraulic) _tryKey, _backKey, _takeKey]);
    }
    final r = _run.current;
    switch (_run.stage) {
      case HydStage.tool:
        final geo = HydStoreGeo(_sceneH);
        final open = [
          for (var i = 0; i < r.tools.length; i++)
            if (!_run.rejected.contains(r.tools[i].id)) geo.slot(i, r.tools.length),
        ];
        return open.isEmpty ? null : HintSpec.sweep(open, space: HintSpace.scene);
      case HydStage.die:
        final box = HintSpec.globalRectOf(_caseKey);
        final hold = HintSpec.globalRectOf(_holdKey);
        if (box == null) return null;
        final inner = box.deflate(16);
        final w = inner.width / r.slots.length;
        return HintSpec.sweep([
          for (var i = 0; i < r.slots.length; i++) Rect.fromLTWH(inner.left + w * i, inner.top, w, inner.height),
          ?hold,
        ]);
      case HydStage.work:
        return HintSpec.sweepOver([_leftKey, _pumpKey]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final held = _held;
    final r = _run.current;
    final taken = _run.taken;
    final panelOk = playing && _card == null && !_docketOpen && held == null;
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
              labels: HydLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            hintAutoMiss: true,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (held != null && playing)
                _Inspect(
                  key: ValueKey('inspect-${held.id}'),
                  tool: held,
                  docket: r.docket,
                  quiet: quiet,
                  muted: _muted,
                  bodyKey: _bodyKey,
                  tryKey: _tryKey,
                  backKey: _backKey,
                  takeKey: _takeKey,
                  onFeel: () => _felt = true,
                  onFound: _found,
                  onTake: _take,
                  onPutBack: _putBack,
                ),
              if (panelOk && _run.stage == HydStage.die && !_run.done)
                _Panel(
                  key: ValueKey('die-${_run.round}'),
                  docket: r.docket,
                  quiet: quiet,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        key: _caseKey,
                        aspectRatio: 1.9,
                        child: _DieCase(round: r, small: false, enabled: !_blocked && !coworkerChoiceUp, onPick: _pickDie, quiet: quiet),
                      ),
                      const SizedBox(height: 10),
                      KeyedSubtree(key: _holdKey, child: _HoldButton(onTapUp: _run.shown ? null : (d) => _holdJob(d.globalPosition))),
                    ],
                  ),
                ),
              if (panelOk && _run.stage == HydStage.work && !_run.done && taken != null)
                _Panel(
                  key: ValueKey('work-${_run.round}'),
                  docket: r.docket,
                  quiet: quiet,
                  child: _Work(
                    job: r.docket.job,
                    battery: taken.kind == HydKind.batteryCrimper,
                    pressure: _run.pressure,
                    done: _run.shown,
                    locked: _run.locked,
                    quiet: quiet,
                    enabled: !_blocked && !coworkerChoiceUp,
                    leftKey: _leftKey,
                    pumpKey: _pumpKey,
                    onStroke: _stroke,
                    onRelease: _release,
                    onLock: _toggleLock,
                  ),
                ),
              if (_docketOpen && playing)
                _DocketZoom(key: const ValueKey('docket-zoom'), cardKey: _zoomKey, docket: r.docket, quiet: quiet, onClose: () => setState(() => _docketOpen = false)),
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
              if (playing && _card == null && !_docketOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
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
                  sound: FailSound.thud,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: HydLines.intro,
                  alarm: 'sounds/van_arrive.wav',
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

const _paper = Color(0xFFF7F1E1);
const _ink = Color(0xFF1E2228);
const _brown = Color(0xFF8C6A2A);
const _bench = Color(0xFF26303B);

/// The docket on its clipboard by the door: the job and the cable size big.
class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.docket, required this.quiet, required this.onTap});
  final HydDocket docket;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const small = Color(0xFF5A6478);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform.translate(offset: Offset(0, -30 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(HydLines.docket, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: _brown, height: 1.1)),
                    Container(height: 0.8, color: const Color(0x55B59B62), margin: const EdgeInsets.symmetric(vertical: 2)),
                    Text(HydLines.jobBn(docket.job), maxLines: 2, style: bangla(fontSize: 7.5, fontWeight: FontWeight.w800, color: _ink, height: 1.15)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('${docket.size}', style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: _ink, height: 1.1)),
                    ),
                    Text('স্কয়ার মিমি', style: bangla(fontSize: 6.5, fontWeight: FontWeight.w700, color: small, height: 1.1)),
                    const SizedBox(height: 2),
                    Text(docket.feederBn, maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 6.5, fontWeight: FontWeight.w700, color: small, height: 1.2)),
                    const Spacer(),
                    for (var i = 0; i < 2; i++) Container(height: 0.8, color: const Color(0x33000000), margin: const EdgeInsets.only(top: 3, right: 10)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 28,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFD9DEE2), Color(0xFF8D969E)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The docket held up close (tap anywhere to put it back).
class _DocketZoom extends StatelessWidget {
  const _DocketZoom({super.key, required this.cardKey, required this.docket, required this.quiet, required this.onClose});
  final GlobalKey cardKey;
  final HydDocket docket;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
              child: Container(
                key: cardKey,
                width: 290,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB59B62), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: _brown, size: 22),
                        const SizedBox(width: 8),
                        Text(HydLines.docket, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
                      ],
                    ),
                    const Divider(color: Color(0x55B59B62), height: 14),
                    Text(HydLines.line(docket), style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: _ink, height: 1.3)),
                    const SizedBox(height: 4),
                    Text(docket.feederBn, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tool on its pegboard hooks. From here a leak or a sticking pump does not
/// show. Tap it, or pull it down off the hooks, to take it in hand.
class _BoardTool extends StatefulWidget {
  const _BoardTool({required this.tool, required this.gone, required this.enabled, required this.onTake});
  final HydTool tool;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  State<_BoardTool> createState() => _BoardToolState();
}

class _BoardToolState extends State<_BoardTool> {
  double _pull = 0;
  Offset _at = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final t = widget.tool;
    final hooks = Positioned(
      top: -8,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (var i = 0; i < 2; i++) Container(width: 4, height: 14, decoration: BoxDecoration(color: const Color(0xFF6B757D), borderRadius: BorderRadius.circular(2)))],
      ),
    );
    if (widget.gone) {
      return Semantics(label: HydLines.toolLabel, child: Stack(clipBehavior: Clip.none, children: [hooks]));
    }
    return Semantics(
      button: true,
      label: HydLines.toolLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.enabled ? (d) => widget.onTake(d.globalPosition) : null,
        onVerticalDragStart: widget.enabled ? (d) => _at = d.globalPosition : null,
        onVerticalDragUpdate: widget.enabled
            ? (d) {
                _at = d.globalPosition;
                setState(() => _pull = (_pull + d.delta.dy).clamp(0.0, 50.0));
              }
            : null,
        onVerticalDragEnd: widget.enabled
            ? (_) {
                final out = _pull > 22;
                setState(() => _pull = 0);
                if (out) widget.onTake(_at);
              }
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            hooks,
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, _pull),
                child: CustomPaint(painter: HydToolPainter(t.kind, t.flaw, seen: const {})),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tool sent to servicing (or to be charged), on the crate, tagged.
class _AsideTool extends StatelessWidget {
  const _AsideTool({required this.tool, required this.quiet});
  final HydTool tool;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(0, -40 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Transform.rotate(angle: -0.18, child: CustomPaint(painter: HydToolPainter(tool.kind, tool.flaw)))),
          Positioned(
            left: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
              child: Text(tool.flaw == HydFlaw.battery ? HydLines.chargeTag : HydLines.serviceTag,
                  style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The die case: labelled slots, each with its pair of hex die halves (or
/// empty, its die lost). [small]: on the bench (no labels to tap).
class _DieCase extends StatelessWidget {
  const _DieCase({required this.round, required this.small, required this.enabled, required this.onPick, required this.quiet});
  final HydRoundDeal round;
  final bool small;
  final bool enabled;
  final void Function(int size, Offset at) onPick;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final slots = round.slots;
    return Container(
      padding: EdgeInsets.all(small ? 4 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFFB8321F),
        borderRadius: BorderRadius.circular(small ? 4 : 12),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF2A2E33), borderRadius: BorderRadius.circular(small ? 2 : 8)),
        padding: EdgeInsets.all(small ? 2 : 6),
        child: Row(
          children: [
            for (final s in slots)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: small ? 1 : 3),
                  child: _DieSlot(
                    size: s,
                    present: s != round.missing,
                    small: small,
                    onTapUp: enabled && s != round.missing ? (d) => onPick(s, d.globalPosition) : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DieSlot extends StatelessWidget {
  const _DieSlot({required this.size, required this.present, required this.small, required this.onTapUp});
  final int size;
  final bool present;
  final bool small;
  final GestureTapUpCallback? onTapUp;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1D21), borderRadius: BorderRadius.circular(small ? 1 : 6)),
      child: Column(
        children: [
          Expanded(child: present ? const CustomPaint(painter: _DiePainter(), child: SizedBox.expand()) : const SizedBox.expand()),
          if (!small)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('$size', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFF2E6C8), height: 1.1)),
            ),
        ],
      ),
    );
    if (small) return body;
    return Semantics(
      button: present,
      label: '${HydLines.dieLabel} $size',
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: onTapUp, child: body),
    );
  }
}

/// A pair of brass hex die halves standing in their slot.
class _DiePainter extends CustomPainter {
  const _DiePainter();

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final brass = Paint()
      ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF0CF7A), Color(0xFFA77A1A)]).createShader(Offset.zero & s);
    for (final top in [true, false]) {
      final y0 = top ? h * 0.1 : h * 0.55;
      final y1 = top ? h * 0.45 : h * 0.9;
      final r = Rect.fromLTRB(w * 0.18, y0, w * 0.82, y1);
      c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(w * 0.06)), brass);
      // The half-hex cut in the die's face.
      final fy = top ? y1 : y0;
      final k = top ? -1.0 : 1.0;
      final hex = Path()
        ..moveTo(w * 0.3, fy)
        ..lineTo(w * 0.4, fy + k * h * 0.12)
        ..lineTo(w * 0.6, fy + k * h * 0.12)
        ..lineTo(w * 0.7, fy)
        ..close();
      c.drawPath(hex, Paint()..color = const Color(0xFF6E5012));
    }
  }

  @override
  bool shouldRepaint(_DiePainter old) => false;
}

/// "ঠিক ডাই নেই — কাজ স্থগিত".
class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.onTapUp});
  final GestureTapUpCallback? onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B1A33),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: onTapUp == null ? null : () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.85), width: 1.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pan_tool_rounded, size: 18, color: SlmColors.warning),
              const SizedBox(width: 8),
              Flexible(
                child: Text(HydLines.hold, textAlign: TextAlign.center, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An ivory panel over the dimmed store, the docket clipped at its top.
class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.docket, required this.quiet, required this.child});
  final HydDocket docket;
  final bool quiet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xA6050A16),
        child: Align(
          alignment: const Alignment(0, -0.5),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, t, c) => Transform.translate(
              offset: Offset(0, 80 * (1 - t)),
              child: Transform.scale(scale: 0.85 + 0.15 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: c)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DocketChip(docket: docket),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.docket});
  final HydDocket docket;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFB59B62))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded, color: _brown, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text('${HydLines.docket} · ${HydLines.line(docket)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The close look, hands on: the tool held up big. Run a finger along the
/// body (oil at the seal shows only where the hand has been), give the pump
/// arm a stroke (or pull the trigger) — then take it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.tool,
    required this.docket,
    required this.quiet,
    required this.muted,
    required this.bodyKey,
    required this.tryKey,
    required this.backKey,
    required this.takeKey,
    required this.onFeel,
    required this.onFound,
    required this.onTake,
    required this.onPutBack,
  });
  final HydTool tool;
  final HydDocket docket;
  final bool quiet;
  final bool muted;
  final GlobalKey bodyKey;
  final GlobalKey tryKey;
  final GlobalKey backKey;
  final GlobalKey takeKey;

  /// The finger ran along the body (the slide hint is done with).
  final VoidCallback onFeel;
  final VoidCallback onFound;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _seen = {};
  Offset? _hand;
  var _found = false;
  var _stroked = false;
  int _strokes = 0;

  @override
  void initState() {
    super.initState();
    // The battery gauge reads at a glance.
    if (widget.tool.flaw == HydFlaw.battery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _report();
      });
    }
  }

  void _report() {
    if (_found) return;
    if (HydToolPainter.flawSeen(widget.tool.flaw, _seen, stroked: _stroked)) {
      _found = true;
      widget.onFound();
    }
  }

  void _touch(Offset p, Size s) {
    widget.onFeel();
    final b = hydBin(p.dx / s.width);
    final before = _seen.length;
    for (final x in [b - 1, b, b + 1]) {
      if (x >= 0 && x < kHydBins) _seen.add(x);
    }
    _report();
    if (_seen.length != before || _hand != p) setState(() => _hand = p);
  }

  void _tryPump() {
    HapticFeedback.selectionClick();
    final t = widget.tool;
    final stuck = t.flaw == HydFlaw.pump || t.flaw == HydFlaw.battery;
    if (!widget.muted) unawaited(ZlFx.cue(stuck ? 'sounds/learn/dull_steel.wav' : 'sounds/learn/tock.wav', volume: 0.6, muted: false));
    setState(() {
      _stroked = true;
      _strokes++;
    });
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tool;
    final hyd = t.kind.hydraulic;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.translate(
              offset: Offset(0, 80 * (1 - v)),
              child: Transform.scale(scale: 0.85 + 0.15 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DocketChip(docket: widget.docket),
                  const SizedBox(height: 6),
                  AspectRatio(
                    aspectRatio: 2.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4654), _bench]),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final s = Size(box.maxWidth, box.maxHeight);
                            return Semantics(
                              key: widget.bodyKey,
                              label: HydLines.handLabel,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanDown: (d) => _touch(d.localPosition, s),
                                onPanUpdate: (d) => _touch(d.localPosition, s),
                                onPanEnd: (_) => setState(() => _hand = null),
                                onPanCancel: () => setState(() => _hand = null),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: TweenAnimationBuilder<double>(
                                        key: ValueKey('stroke-$_strokes'),
                                        tween: Tween(begin: 0, end: _strokes == 0 ? 0 : 1),
                                        duration: Duration(milliseconds: widget.quiet ? 1 : 520),
                                        builder: (_, a, _) {
                                          // Down and back up: a full stroke.
                                          final arm = a < 0.5 ? a * 2 : (1 - a) * 2;
                                          return CustomPaint(
                                            painter: HydToolPainter(t.kind, t.flaw, seen: hyd ? _seen : null, veil: hyd ? _bench : null, stroked: _stroked, arm: arm),
                                          );
                                        },
                                      ),
                                    ),
                                    if (hyd && _seen.isEmpty) _Puck(at: Offset(s.width * 0.12, s.height * 0.8)),
                                    if (_hand != null) _Puck(at: _hand!, live: true),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (hyd) ...[
                    const SizedBox(height: 8),
                    _PumpTry(
                      key: widget.tryKey,
                      label: t.kind == HydKind.batteryCrimper ? HydLines.trigger : HydLines.pump,
                      onTap: _tryPump,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: DoBigButton(key: widget.backKey, label: HydLines.putBack, filled: false, onTapUp: (_) => widget.onPutBack())),
                      const SizedBox(width: 12),
                      Expanded(child: DoBigButton(key: widget.takeKey, label: HydLines.take, filled: true, onTapUp: (d) => widget.onTake(d.globalPosition))),
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

/// The pump arm / trigger to try in the close look.
class _PumpTry extends StatelessWidget {
  const _PumpTry({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF26303B),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.compress_rounded, size: 20, color: SlmColors.gold300),
              const SizedBox(width: 8),
              Text(label, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The job close up: pump (or trigger) until the valve clicks; let go; for a
/// cut, the safety lock first.
class _Work extends StatelessWidget {
  const _Work({
    required this.job,
    required this.battery,
    required this.pressure,
    required this.done,
    required this.locked,
    required this.quiet,
    required this.enabled,
    required this.leftKey,
    required this.pumpKey,
    required this.onStroke,
    required this.onRelease,
    required this.onLock,
  });
  final GlobalKey leftKey;
  final GlobalKey pumpKey;
  final HydJob job;
  final bool battery;
  final int pressure;
  final bool done;
  final bool locked;
  final bool quiet;
  final bool enabled;
  final ValueChanged<Offset> onStroke;
  final ValueChanged<Offset> onRelease;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final crimp = job == HydJob.crimp;
    final p = (pressure / kHydStrokes).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1.9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: p, end: p),
                    duration: Duration(milliseconds: quiet ? 1 : 260),
                    curve: Curves.easeOut,
                    builder: (_, v, _) => CustomPaint(painter: HydWorkPainter(job: job, p: v, done: done, locked: locked)),
                  ),
                ),
                if (crimp && done)
                  Positioned(
                    right: 14,
                    top: 10,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      builder: (_, v, child) => Transform.scale(scale: v, child: child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: SlmColors.gold700, borderRadius: BorderRadius.circular(10)),
                        child: Text(HydLines.click, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              key: leftKey,
              child: crimp
                  ? DoBigButton(label: HydLines.release, filled: false, onTapUp: enabled ? (d) => onRelease(d.globalPosition) : (_) {})
                  : _LockButton(locked: locked, onTap: enabled ? onLock : null),
            ),
            const SizedBox(width: 12),
            Expanded(
              key: pumpKey,
              child: DoBigButton(label: battery ? HydLines.trigger : HydLines.pump, filled: true, onTapUp: enabled ? (d) => onStroke(d.globalPosition) : (_) {}),
            ),
          ],
        ),
      ],
    );
  }
}

class _LockButton extends StatelessWidget {
  const _LockButton({required this.locked, required this.onTap});
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: locked ? const Color(0xFF1F6B4A) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: locked ? null : Border.all(color: const Color(0x553A4660)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(locked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 18, color: locked ? Colors.white : SlmColors.ink),
              const SizedBox(width: 6),
              Text(HydLines.lock, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: locked ? Colors.white : SlmColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A gloved hand's mark: where to slide (still), or under the finger.
class _Puck extends StatelessWidget {
  const _Puck({required this.at, this.live = false});
  final Offset at;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 22.0 : 17.0;
    return Positioned(
      left: at.dx - r,
      top: at.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0x55FF851B) : const Color(0x33FF851B),
            border: Border.all(color: const Color(0xFFFF851B), width: live ? 2 : 1.4),
          ),
          child: Icon(Icons.back_hand_rounded, size: r * 1.05, color: const Color(0xFFB4560E)),
        ),
      ),
    );
  }
}
