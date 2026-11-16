import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'm7_spill_boom_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_spill_boom_world.dart' show M7Incident, M7RingJudge, M7SlotKind, M7SpillGeo, M7Target, m7JudgeRing;

// Lesson 7.8 "পরিবেশগত আইন: আমাদের দায়িত্ব", কাজ 1 "এক ফোঁটাও মাটিতে নয়"
// (pack do_7_8_a, rung 7.8/do/0, engineType m7_spill_boom). The old
// transformer oil is to be changed at a roadside DTR (drawn as background: the
// AB switch open, locked and tagged, the earth set, the PTW tag; never scored,
// M7-9). The trainee, in গ্লাভস, with a crew mate at the drain valve:
//
//  Set-up: tap the red spill kit open; drag two pads under the valve; draw the
//    boom with a finger round the valve spot and the pallet where a drum stands
//    (no outline; a ring counts only if it closes and encloses both). The ring
//    is judged only when oil gets out (a gap = found when it escapes). The
//    valve turned before the pads and the boom = a slip (the mate shuts it).
//    ◆ → "কেন আগে স্পিল কিট বিছালেন?".
//  Hose: drag its end to a container. The leak-proof drum (or the second drum
//    when it is sound) is right; the drain, the bare soil, the open bucket or the
//    weeping drum = a slip (oil starts to go there, the mate stops it, the hose
//    comes back). ◆ → "পুরনো তেল কেন এই ড্রামে?".
//  Valve: a quarter-turn (an arc on the handle); oil flows. After a dealt wait
//    an incident (coupling drip, bung spurt, knocked sample can, gasket weep)
//    starts a puddle that grows. Held by a good set-up ring; through a gap it
//    escapes (slip), runs on toward the drain (a second ring drawn ahead of the
//    edge stops it; the drain reached = a slip). The coworker comes as the
//    puddle appears; the boom control and the pads wait for him.
//  Soak: hold a pad on the held or contained puddle until it is dark (2–3 pads
//    dealt). Bag the used pads: the red bag is right, the green general bin =
//    a slip. ◆ → "কেন ঘিরে প্যাডে শুষলেন?" / "তেল-মাখা প্যাড কেন আলাদা ব্যাগে?".
//    Then close the valve (arc back) and the bung (tap) → the pass panel.
//
// No deadly mistake (M7-6: lesson 7.8 has none; all slips). Three slips strike
// out. The coworker, once a play: myth 1 or the wash-it-down line; listening =
// a slip (B1/X2) with the ground-slice picture and a bigger puddle (one more pad).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the full
// scene (m7_spill_boom_world.dart), corner guide, ReasonTable (the "কেন?" cards
// at once), CoworkerMoment, gesture hands for every waiting state (how, never
// what; the boom hand is the plain drag hand, M7-12), MistakeCard, DoStrikeOut,
// the pass panel with stars. Idle = zero frames: the puddle's timer redraws
// only while oil is still spreading.

// ============================================================================
// Content
// ============================================================================

/// The coworker's push (one a play, dealt).
enum M7SpillPush { soil, wash }

/// What a reason asks about.
enum M7SpillWhy { kit, drum, soak, bag }

/// Where the play is.
enum M7SpillStage { setup, hose, valve, contain, bag, close, done }

abstract final class M7SpillBoomLines {
  static const title = 'এক ফোঁটাও মাটিতে নয়';

  // DRAFT wording — owner (M6-12): every guide line below is new text.
  static const intro = 'পুরনো ট্রান্সফরমার অয়েল বদলানো হবে — এক ফোঁটাও যেন মাটিতে বা নালায় না যায়!';
  static const askSetup = 'তেল বদলানোর জায়গা তৈরি করুন।';
  static const askHose = 'পাইপের মুখ কোথায় দেবেন?';
  static const askValve = 'এবার ভালভ খুলুন।';
  static const askContain = 'তেল বইছে — নজর রাখুন।';
  static const askPuddle = 'তেল ছড়াচ্ছে — সামলান!';
  static const askBag = 'ব্যবহার-করা প্যাডগুলোর ব্যবস্থা করুন।';
  static const askClose = 'কাজ শেষ — সব বন্ধ করুন।';
  static const tasks = [askSetup, askHose, askValve, askContain, askPuddle, askBag, askClose];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  static String ask(M7SpillStage s, {bool puddle = false}) => switch (s) {
        M7SpillStage.setup => askSetup,
        M7SpillStage.hose => askHose,
        M7SpillStage.valve => askValve,
        M7SpillStage.contain => puddle ? askPuddle : askContain,
        M7SpillStage.bag => askBag,
        M7SpillStage.close || M7SpillStage.done => askClose,
      };

  // On screen (no text in the scene; only the semantics a screen reader reads).
  static const sceneLabel = 'ট্রান্সফরমারের পাশের জায়গা';
  static const stages = ['স্পিল কিট', 'পুরনো তেল', 'ঘিরে শুষুন', 'বন্ধ'];

  // The reasons. The right ones fit what was done (lesson 7.8 points and pro
  // tips 1 and 2); the wrong ones are the lesson's myths and field excuses.
  // DRAFT wording — owner.
  static const whyQ = <M7SpillWhy, String>{
    M7SpillWhy.kit: 'কেন আগে স্পিল কিট বিছালেন?',
    M7SpillWhy.drum: 'পুরনো তেল কেন এই ড্রামে?',
    M7SpillWhy.soak: 'কেন ঘিরে প্যাডে শুষলেন?',
    M7SpillWhy.bag: 'তেল-মাখা প্যাড কেন আলাদা ব্যাগে?',
  };
  static const whyRight = <M7SpillWhy, List<String>>{
    M7SpillWhy.kit: ['তেল পড়ার আগেই প্যাড আর বুমে মাটি বাঁচাতে হয়', 'স্পিল কিট আগে না বিছালে তেল মাটিতে চলে যায়'],
    M7SpillWhy.drum: ['পুরনো তেল রাখতে হয় লিক-প্রুফ ড্রামেই, আর কোথাও নয়', 'আইন বলে পুরনো তেল লিক-প্রুফ ড্রামে জমা করতে হয়'],
    M7SpillWhy.soak: ['ঘিরে প্যাডে শুষলে তেল মাটি বা নালায় যেতে পারে না', 'এক লিটার তেলও লক্ষ লক্ষ লিটার জল নষ্ট করে ফেলে'],
    M7SpillWhy.bag: ['তেল-মাখা প্যাড বিপজ্জনক বর্জ্য, সাধারণ ময়লায় নয়', 'বিপজ্জনক বর্জ্য সাধারণ বর্জ্য থেকে আলাদা রাখতে হয়'],
  };
  static const myths = [
    'একটু তেল মাটিতে পড়লে কিছু হয় না, মাটি তো শুষে নেয়',
    'পরিবেশের আইন শুধু বড় ফ্যাক্টরির জন্য, আমাদের নয়',
    'প্যাড বেশি লাগলে খরচ বাড়ে, তাই কম নিলেই চলে',
    'নালায় ঢেলে জল দিয়ে ধুয়ে দিলেই তেল সরে যায়',
    'এটুকু তেলে কারও কোনো ক্ষতিই হয় না, আসলে',
    'ড্রাম ভারী, কাছের বালতিতে নিলে কাজ সহজ হয়',
    'সব ময়লা এক ডাস্টবিনেই ফেলা যায়, সময়ও বাঁচে',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play). The pushes are the lesson's
  // myth-buster line word for word and the wash-it-down shortcut (M7-10).
  // DRAFT wording — owner; both need recording (tool/rival_clip.py).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerSoil = CoworkerScript(
    line: 'একটু তেল মাটিতে পড়লে কিছু হয় না, মাটি তো শুষে নেয়।',
    exitLine: coworkerExit,
    right: ['না, তেল গভীরে গিয়ে ভূগর্ভস্থ জল দূষিত করে', 'না, মাটিতে পড়া তেল জল নষ্ট করে, আটকাতে হবে', 'না, এক ফোঁটা তেলও মাটিতে যেতে দেব না, আটকাব'],
    wrong: [
      'ঠিক, অল্প তেল মাটি নিজেই শুষে নেবে, চিন্তা কী',
      'ঠিক, এটুকু তেলে কারো কোনো ক্ষতি হয় না',
      'ঠিক, প্যাড বাঁচিয়ে রাখাই ভালো, দামি জিনিস',
      'ঠিক, মাটিতে মিশে গেলে আর দেখা যাবে না',
      'ঠিক, ঘিরে প্যাড দিতে গেলে অনেক দেরি হবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে মাটি তেল শুষে নেয়। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerWash = CoworkerScript(
    line: 'প্যাড-ট্যাড লাগবে না, জল দিয়ে নালায় ধুয়ে দাও।',
    exitLine: coworkerExit,
    right: ['না, তেল নালায় গেলে বহু জল দূষিত হয়, অপরাধ', 'না, নালায় ধোয়া মানে তেল ড্রেনে ফেলা, অপরাধ', 'না, প্যাডে শুষে আলাদা ব্যাগে রাখব, নালায় নয়'],
    wrong: [
      'ঠিক, জল ঢাললেই তেল সরে যাবে, ঝামেলা নেই',
      'ঠিক, নালার জল তো এমনিই নোংরা, কিছু হবে না',
      'ঠিক, ধুয়ে দিলে সব পরিষ্কার হয়ে যাবে তো',
      'ঠিক, প্যাড বাঁচিয়ে রাখাই ভালো, দামি জিনিস',
      'ঠিক, নালায় গেলে কেউ টের পাবে না আসলে',
    ],
    asks: ['কী করবেন?', 'ও বলছে জল দিয়ে নালায় ধুয়ে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M7SpillPush p) => switch (p) {
        M7SpillPush.soil => coworkerSoil,
        M7SpillPush.wash => coworkerWash,
      };
  static const allCoworkers = [coworkerSoil, coworkerWash];

  static String callHeld(M7SpillPush p) => switch (p) {
        M7SpillPush.soil => 'ঠিক! মাটি শুষলেও তেল নিচে গিয়ে ভূগর্ভস্থ জল নষ্ট করে।',
        M7SpillPush.wash => 'ঠিক! তেল নালায় ধোয়া নয় — প্যাডে শুষে আলাদা রাখুন।',
      };

  static const allSet = 'এক ফোঁটাও মাটিতে যায়নি — তেল ড্রামে, প্যাড আলাদা ব্যাগে। দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে স্পিল কিট, তেল লিক-প্রুফ ড্রামে, প্যাড আলাদা ব্যাগে।';

  // "আজ যা ধরলেন" (on screen).
  static const caughtKit = 'আগে স্পিল কিট বিছিয়ে তবে ভালভ খুলেছেন';
  static const caughtDrum = 'পুরনো তেল লিক-প্রুফ ড্রামে নিয়েছেন';
  static const caughtBag = 'তেল-মাখা প্যাড আলাদা ব্যাগে ফেলেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new spoken guide line (DRAFT wording — owner; to be recorded):
  /// the guide's lines, the why-questions and the texts of the mistakes
  /// (read aloud the first time).
  static const newGuideLines = [
    intro,
    askSetup,
    askHose,
    askValve,
    askContain,
    askPuddle,
    askBag,
    askClose,
    'কেন আগে স্পিল কিট বিছালেন?',
    'পুরনো তেল কেন এই ড্রামে?',
    'কেন ঘিরে প্যাডে শুষলেন?',
    'তেল-মাখা প্যাড কেন আলাদা ব্যাগে?',
    'ঠিক! মাটি শুষলেও তেল নিচে গিয়ে ভূগর্ভস্থ জল নষ্ট করে।',
    'ঠিক! তেল নালায় ধোয়া নয় — প্যাডে শুষে আলাদা রাখুন।',
    allSet,
    quick,
    fail,
    'ও বলছে মাটি তেল শুষে নেয়। কী করবেন?',
    'ও বলছে জল দিয়ে নালায় ধুয়ে দিতে। কী করবেন?',
    M7SpillBoomMistakes.openFirstBn,
    M7SpillBoomMistakes.ringGapBn,
    M7SpillBoomMistakes.hoseDrainBn,
    M7SpillBoomMistakes.hoseBucketBn,
    M7SpillBoomMistakes.puddleDrainBn,
    M7SpillBoomMistakes.padGeneralBn,
    M7SpillBoomMistakes.listenSoilBn,
    M7SpillBoomMistakes.listenWashBn,
  ];

  /// The coworker's pushes (DRAFT wording — owner; to be recorded in his
  /// voice). His exit line is recorded already.
  static const newRivalLines = [
    'একটু তেল মাটিতে পড়লে কিছু হয় না, মাটি তো শুষে নেয়।',
    'প্যাড-ট্যাড লাগবে না, জল দিয়ে নালায় ধুয়ে দাও।',
  ];
}

abstract final class M7SpillBoomMistakes {
  static const _dir = 'assets/game/art/m7_spill_boom';

  // Lesson 7.8 points (0-based): 0 the leak-proof drum, 1 Hazardous Waste
  // Management Rules (soil or drain = punishable), 2 one litre pollutes lakhs
  // of litres, 3 the spill kit (pads, boom), 4 separate hazardous waste.
  // All slips (M7-6). DRAFT wording — owner (read aloud the first time).
  static const openFirstBn = 'আগে প্যাড আর বুম বিছিয়ে নিন, তারপর ভালভ। মাটি দূষণ আটকাতে স্পিল কিট আগে লাগে।';
  static const openFirst = DoMistake(
    key: '7.8/m7_spill_boom/open-first',
    textBn: openFirstBn,
    art: '$_dir/open_first.svg',
    lessonPoint: 3,
  );
  static const ringGapBn = 'বুমের ঘেরে ফাঁক ছিল — তেল বেরিয়ে গেল। ভালভের জায়গা আর ড্রামের জায়গা ঘিরে বুম পুরো বন্ধ করুন।';
  static const ringGap = DoMistake(
    key: '7.8/m7_spill_boom/ring-gap',
    textBn: ringGapBn,
    art: '$_dir/ring_gap.svg',
    lessonPoint: 3,
  );
  static const hoseDrainBn = 'তেল মাটিতে বা ড্রেনে ফেলা দণ্ডনীয় অপরাধ — Hazardous Waste Management Rules। পুরনো তেল যাবে ড্রামে।';
  static const hoseDrain = DoMistake(
    key: '7.8/m7_spill_boom/hose-drain',
    textBn: hoseDrainBn,
    art: '$_dir/hose_drain.svg',
    lessonPoint: 1,
  );
  static const hoseBucketBn = 'খোলা বালতিতে বা চুঁইয়ে পড়া ড্রামে নয়। পুরনো তেল সংগ্রহ করতে হবে একটি লিক-প্রুফ ড্রামে।';
  static const hoseBucket = DoMistake(
    key: '7.8/m7_spill_boom/hose-bucket',
    textBn: hoseBucketBn,
    art: '$_dir/hose_bucket.svg',
    lessonPoint: 0,
  );
  static const puddleDrainBn = 'তেল বুম পেরিয়ে নালা পর্যন্ত গেল! এক লিটার তেল লক্ষ লক্ষ লিটার জল দূষিত করে। ছড়ানো তেলের সামনে আরেকটা বুম টানুন।';
  static const puddleDrain = DoMistake(
    key: '7.8/m7_spill_boom/puddle-drain',
    textBn: puddleDrainBn,
    art: '$_dir/puddle_drain.svg',
    lessonPoint: 2,
  );
  static const padGeneralBn = 'তেল-মাখা প্যাড বিপজ্জনক বর্জ্য — সাধারণ বর্জ্যের ডাস্টবিনে নয়, আলাদা করে নির্দিষ্ট ব্যাগে।';
  static const padGeneral = DoMistake(
    key: '7.8/m7_spill_boom/pad-general',
    textBn: padGeneralBn,
    art: '$_dir/pad_general.svg',
    lessonPoint: 4,
  );
  static const listenSoilBn = 'মাটি তেলকে শুষে নিলেও তেল গভীরে গিয়ে ভূগর্ভস্থ জল দূষিত করে — দীর্ঘস্থায়ী ক্ষতি। প্যাড-বুমে আটকান।';
  static const listenSoil = DoMistake(
    key: '7.8/m7_spill_boom/listen-soil',
    textBn: listenSoilBn,
    art: '$_dir/listen_soil.svg',
    lessonPoint: 2,
  );
  static const listenWashBn = 'জল দিয়ে নালায় ধুয়ে দেওয়া মানে তেল ড্রেনে ফেলা — দণ্ডনীয় অপরাধ। তেল প্যাডে শুষে আলাদা রাখুন।';
  static const listenWash = DoMistake(
    key: '7.8/m7_spill_boom/listen-wash',
    textBn: listenWashBn,
    art: '$_dir/listen_wash.svg',
    lessonPoint: 1,
  );

  static DoMistake push(M7SpillPush p) => switch (p) {
        M7SpillPush.soil => listenSoil,
        M7SpillPush.wash => listenWash,
      };

  static const List<DoMistake> all = [openFirst, ringGap, hoseDrain, hoseBucket, puddleDrain, padGeneral, listenSoil, listenWash];
}

// ============================================================================
// The rules (pure)
// ============================================================================

/// Pads that must lie under the valve before the oil may flow.
const int m7SpillPadsToSet = 2;

/// How far the puddle spreads inside a held ring (design px, half-width).
const double m7SpillHoldR = 50;

/// The puddle's first size.
const double m7SpillStartR = 14;

/// Spread speed by band (design px a second).
const List<double> m7SpillRates = [14, 20, 28];

/// One play's deal.
@immutable
class M7SpillDeal {
  const M7SpillDeal({
    required this.drainRight,
    required this.slots,
    required this.weeping,
    required this.incident,
    required this.band,
    required this.delay,
    required this.incT,
    required this.incDy,
    required this.push,
    required this.dusk,
    required this.whyRoll,
  });

  /// The drain's side (the whole yard mirrors).
  final bool drainRight;

  /// What stands in each container slot (a permutation of drum, drumB, bucket).
  final List<M7SlotKind> slots;

  /// The second drum weeps at a seam (false = it is sound too).
  final bool weeping;
  final M7Incident incident;

  /// Spread-speed band 0–2 ([m7SpillRates]).
  final int band;

  /// Seconds of flow before the incident starts.
  final double delay;

  /// Where the incident starts between the valve spot (0) and the pallet (1),
  /// and its small vertical offset.
  final double incT;
  final double incDy;
  final M7SpillPush push;
  final bool dusk;
  final int whyRoll;

  double get rate => m7SpillRates[band];

  /// Pads needed to soak the puddle (faster spreading = a bigger puddle).
  int get padsNeeded => band == 0 ? 2 : 3;

  /// Is the container in slot [i] one the oil may go to.
  bool slotRight(int i) => slots[i] == M7SlotKind.drum || (slots[i] == M7SlotKind.drumB && !weeping);
}

M7SpillDeal m7SpillDeal(math.Random rng) {
  final slots = [...M7SlotKind.values]..shuffle(rng);
  return M7SpillDeal(
    drainRight: rng.nextBool(),
    slots: slots,
    weeping: rng.nextBool(),
    incident: M7Incident.values[rng.nextInt(M7Incident.values.length)],
    band: rng.nextInt(3),
    delay: 1.5 + rng.nextDouble() * 2.0,
    incT: 0.2 + rng.nextDouble() * 0.6,
    incDy: -8 + rng.nextDouble() * 16,
    push: M7SpillPush.values[rng.nextInt(2)],
    dusk: rng.nextInt(4) == 0,
    whyRoll: rng.nextInt(1000),
  );
}

/// The final reason's topic: the soaking or the bagging (both fit what was
/// done).
M7SpillWhy m7SpillFinalWhy(M7SpillDeal d) => d.whyRoll.isEven ? M7SpillWhy.soak : M7SpillWhy.bag;

/// What one tick of the puddle clock did.
@immutable
class M7SpillTick {
  const M7SpillTick({this.changed = false, this.appeared = false, this.slip});
  final bool changed;
  final bool appeared;
  final DoMistake? slip;
}

/// The play state (pure logic).
class M7SpillRun {
  M7SpillRun(this.deal) : padsNeeded = deal.padsNeeded;

  final M7SpillDeal deal;

  // Set-up.
  var kitOpen = false;
  int padsPlaced = 0;
  List<Offset>? ring1;
  M7RingJudge? ring1Judge;
  var setupPaid = false;

  // Hose and valve.
  int? hoseSlot;
  var hoseReasoned = false;
  var valveOpen = false;
  var valveWasOpen = false;
  double flowT = 0;

  // The puddle.
  var puddleOn = false;
  Offset puddleAt = Offset.zero;
  double r = m7SpillStartR;
  var escaped = false;
  double edge = 0;
  Offset edgeDir = Offset.zero;
  double drainDist = 0;
  var contained = false;
  var atDrain = false;
  List<Offset>? ring2;
  int padsNeeded;
  int soaked = 0;
  int usedPads = 0;
  var bagged = false;
  var bungShut = false;

  /// The coworker's push this play (set when he is scheduled).
  M7SpillPush? push;

  int slips = 0;
  int stageSlips = 0;
  final List<String> caught = [];

  bool get setupReady => padsPlaced >= m7SpillPadsToSet && ring1 != null;
  bool get held => ring1Judge == M7RingJudge.ok;
  bool get done => bagged && valveWasOpen && !valveOpen && bungShut;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  /// The oil may be soaked (a ring holds it, or it has run its course).
  bool get sealed => puddleOn && (held || contained || atDrain);
  bool get soakedAll => puddleOn && soaked >= padsNeeded;
  double get left => padsNeeded == 0 ? 1 : (1 - soaked / padsNeeded).clamp(0.0, 1.0);

  M7SpillStage get stage {
    if (done) return M7SpillStage.done;
    if (!setupReady) return M7SpillStage.setup;
    if (hoseSlot == null) return M7SpillStage.hose;
    if (!valveOpen && !valveWasOpen) return M7SpillStage.valve;
    if (!soakedAll) return M7SpillStage.contain;
    if (!bagged) return M7SpillStage.bag;
    return M7SpillStage.close;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stageSlips++;
    return m;
  }

  // --- set-up -----------------------------------------------------------------
  void openKit() => kitOpen = true;

  /// A pad let go at [p]: it lies under the valve only inside the pad zone.
  bool placePad(Offset p, M7SpillGeo geo) {
    if (!kitOpen || valveOpen || padsPlaced >= 3 || !geo.padZone.contains(p)) return false;
    padsPlaced++;
    return true;
  }

  /// A boom line drawn before the oil flows. Stored when it is long enough; a
  /// ring already there is replaced only by a closed one. Judged only when oil
  /// gets out (no feedback here).
  M7RingJudge drawSetupBoom(List<Offset> pts, M7SpillGeo geo) {
    if (!kitOpen || valveOpen) return M7RingJudge.tooShort;
    final j = m7JudgeRing(pts, [geo.spill, geo.pallet]);
    if (j == M7RingJudge.tooShort) return j;
    if (ring1 != null && (j == M7RingJudge.open)) return j;
    ring1 = pts;
    ring1Judge = j;
    return j;
  }

  // --- the hose -------------------------------------------------------------------
  /// The hose end let go on [t] (slot [slot] for a container). A right
  /// container takes it; a wrong place is a slip (the mate stops it, the hose
  /// comes back). Nothing before the set-up is ready.
  DoMistake? hoseTo(M7Target t, int slot, M7SpillGeo geo) {
    if (!setupReady || hoseSlot != null) return null;
    switch (t) {
      case M7Target.none:
        return null;
      case M7Target.drain:
      case M7Target.soil:
        return _slip(M7SpillBoomMistakes.hoseDrain);
      case M7Target.slot:
        if (deal.slotRight(slot)) {
          hoseSlot = slot;
          _tag(M7SpillBoomLines.caughtDrum);
          return null;
        }
        return _slip(M7SpillBoomMistakes.hoseBucket);
    }
  }

  // --- the valve ----------------------------------------------------------------------
  /// The valve turned open. Before the pads and the boom: a slip (the mate
  /// shuts it). Set-up ready but no hose in a container: nothing (it would pour
  /// on the ground; the hand shows the hose). Else the oil flows.
  DoMistake? openValve() {
    if (valveOpen || valveWasOpen) return null;
    if (!setupReady) return _slip(M7SpillBoomMistakes.openFirst);
    if (hoseSlot == null) return null;
    valveOpen = true;
    valveWasOpen = true;
    _tag(M7SpillBoomLines.caughtKit);
    return null;
  }

  /// The valve turned shut: only at the end (after the bagging).
  bool closeValve() {
    if (!valveOpen || !bagged) return false;
    valveOpen = false;
    return true;
  }

  /// The bung pushed home: only at the end, in the container the oil is in.
  bool closeBung() {
    if (!bagged || hoseSlot == null || bungShut) return false;
    bungShut = true;
    return true;
  }

  // --- the puddle -------------------------------------------------------------------------
  /// [dt] playable seconds. The incident starts after the dealt wait; the
  /// puddle grows to the ring (held) or breaks out through a gap (a slip) and
  /// runs on toward the drain (a slip when it gets there) unless a ring ahead
  /// of the edge stops it.
  M7SpillTick tick(double dt, M7SpillGeo geo) {
    if (!valveOpen || done) return const M7SpillTick();
    if (!puddleOn) {
      flowT += dt;
      if (flowT < deal.delay) return const M7SpillTick();
      puddleOn = true;
      puddleAt = geo.incident(deal.incT, deal.incDy);
      final d = geo.drainEdge - puddleAt;
      edgeDir = d / d.distance;
      drainDist = math.max(40.0, d.distance - m7SpillHoldR - 24);
      return const M7SpillTick(changed: true, appeared: true);
    }
    if (soakedAll) return const M7SpillTick();
    final rate = deal.rate;
    if (r < m7SpillHoldR) {
      r = math.min(m7SpillHoldR, r + rate * dt);
      if (r >= m7SpillHoldR && !held && !contained && !escaped) {
        escaped = true;
        return M7SpillTick(changed: true, slip: _slip(M7SpillBoomMistakes.ringGap));
      }
      return const M7SpillTick(changed: true);
    }
    if (escaped && !contained && !atDrain) {
      edge = math.min(drainDist, edge + rate * dt);
      if (edge >= drainDist) {
        atDrain = true;
        return M7SpillTick(changed: true, slip: _slip(M7SpillBoomMistakes.puddleDrain));
      }
      return const M7SpillTick(changed: true);
    }
    return const M7SpillTick();
  }

  /// Where the oil's front is now.
  Offset get head => puddleAt + edgeDir * (math.min(r, m7SpillHoldR) + edge);

  /// A ring drawn once the puddle is out: ok only if it closes and encloses the
  /// puddle and its front. Stops the oil. (Not while it is held, soaked or
  /// already at the drain.)
  M7RingJudge drawContain(List<Offset> pts) {
    if (!puddleOn || held || contained || atDrain || soakedAll) return M7RingJudge.tooShort;
    final j = m7JudgeRing(pts, [puddleAt, head]);
    if (j == M7RingJudge.tooShort) return j;
    ring2 = pts;
    if (j == M7RingJudge.ok) contained = true;
    return j;
  }

  /// One pad held on the puddle until it is dark. Only on oil a ring holds.
  bool soak() {
    if (!sealed || soakedAll) return false;
    soaked++;
    usedPads = soaked;
    return true;
  }

  /// The used pads into the red bag (right) or the green general bin (a slip).
  DoMistake? bin({required bool red}) {
    if (!soakedAll || bagged) return null;
    if (!red) return _slip(M7SpillBoomMistakes.padGeneral);
    bagged = true;
    usedPads = 0;
    _tag(M7SpillBoomLines.caughtBag);
    return null;
  }

  /// Listened to the coworker: a slip (B1; nothing in 7.8 is deadly). The
  /// bigger puddle needs one more pad.
  DoMistake listen(M7SpillPush p) {
    padsNeeded++;
    return _slip(M7SpillBoomMistakes.push(p));
  }

  /// The table was paid: the next stage's slips count afresh.
  void tablePaid() => stageSlips = 0;
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   set-up: kit, two pad drags, the ring ≈ 9000; its reason ~8200
///   hose drag ≈ 2500; its reason ~8200; valve arc ≈ 1800
///   the dealt wait + the coworker once ≈ 3500 + 9600
///   soak 2–3 holds ≈ 4000, bagging ≈ 1500, reason ~8200, valve and bung ≈ 3500
///   ≈ 64000; 85 % ≈ 54500 → 55 s.
const m7SpillBoomQuickMs = 55000;

/// Test hook: the play state of the page now on screen (tests only).
abstract final class M7SpillBoomProbe {
  @visibleForTesting
  static M7SpillRun? run;
}

@immutable
class M7SpillBoomPack {
  const M7SpillBoomPack({required this.id, required this.titleBn, this.quickMs = m7SpillBoomQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7SpillBoomPack> m7SpillBoomPacks = {
  'do_7_8_a': M7SpillBoomPack(id: 'do_7_8_a', titleBn: M7SpillBoomLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M7SpillBoomPage extends StatefulWidget {
  const M7SpillBoomPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7SpillBoomPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7SpillBoomPage> createState() => _M7SpillBoomPageState();
}

class _M7SpillBoomPageState extends State<M7SpillBoomPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SpillRunPage(
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

class _SpillRunPage extends ConsumerStatefulWidget {
  const _SpillRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7SpillBoomPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SpillRunPage> createState() => _SpillRunPageState();
}

/// What a pan on the scene is doing.
enum _Pan { none, pad, hose, valve, boom }

class _SpillRunPageState extends ConsumerState<_SpillRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7SpillRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  Timer? _tickTimer;
  final _stroke = ValueNotifier<List<Offset>>(const []);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  int _steps = 0;

  /// The valve lever's progress now (follows the finger on a pan).
  double _valveP = 0;

  /// The hose end while it is dragged (null = home or in its container).
  Offset? _hoseDrag;
  Offset? _padDrag;
  var _slice = false;
  Timer? _sliceTimer;

  final _nudge = TaskNudge();
  int _nudgeN = 0;
  final _hints = IdleHintController();
  M7SpillGeo? _geoNow;

  // A pan on the scene.
  _Pan _pan = _Pan.none;
  Offset _panNow = Offset.zero;
  final List<Offset> _pts = [];

  @override
  void initState() {
    super.initState();
    _run = M7SpillRun(m7SpillDeal(widget.rng));
    M7SpillBoomProbe.run = _run;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _clockTick());
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _tickTimer?.cancel();
    _sliceTimer?.cancel();
    _stroke.dispose();
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_slice && !_run.ended;

  String get _task => M7SpillBoomLines.ask(_run.stage, puddle: _run.puddleOn && !_run.sealed);

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  // --- the puddle's clock -----------------------------------------------------------
  /// Playable time only: the puddle waits while a card, a deck, the table, the
  /// coworker or the ground slice is up. Redraws only while oil is spreading.
  void _clockTick() {
    if (!mounted || !_run.valveOpen) return;
    if (!_canPlay) return;
    final geo = _geoNow;
    if (geo == null) return;
    final t = _run.tick(0.1, geo);
    if (t.appeared) {
      _run.push = _run.deal.push;
      scheduleCoworker();
      unawaited(_sayChain([_task]));
    }
    if (t.changed) setState(() => _wake++);
    final m = t.slip;
    if (m != null) {
      _hints.missTap();
      unawaited(_mistake(m, _sceneToGlobal(_run.puddleAt)));
    }
  }

  /// A rough global position of a design point (for the flying ◆ only).
  Offset _sceneToGlobal(Offset p) {
    final size = MediaQuery.sizeOf(context);
    final k = size.width / 360;
    return Offset(p.dx * k, p.dy * k);
  }

  // --- taps -------------------------------------------------------------------------------
  void _tapAt(Offset p, M7SpillGeo geo) {
    if (!_canPlay) return;
    if (!_run.kitOpen && geo.kitHit.contains(p)) {
      _tick('sounds/intro/click.ogg', 0.55);
      _run.openKit();
      _stepDone();
      return;
    }
    switch (_run.stage) {
      case M7SpillStage.bag:
        final red = geo.redBin.inflate(4).contains(p);
        if (red || geo.greenBin.inflate(4).contains(p)) {
          unawaited(_binUsed(red, p));
          return;
        }
      case M7SpillStage.close:
        final slot = _run.hoseSlot;
        if (slot != null && !_run.bungShut && geo.bungHit(slot).contains(p)) {
          _tick('sounds/learn/stomp.ogg', 0.5);
          _run.closeBung();
          _stepDone();
          _maybeFinish();
          return;
        }
      case M7SpillStage.setup:
      case M7SpillStage.hose:
      case M7SpillStage.valve:
      case M7SpillStage.contain:
      case M7SpillStage.done:
        break;
    }
    _hints.missTap();
  }

  Future<void> _binUsed(bool red, Offset p) async {
    final m = _run.bin(red: red);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, _sceneToGlobal(p)));
      return;
    }
    _tick('sounds/intro/drop.ogg', 0.6);
    setState(() => _wake++);
    // ◆ on the table, then the reason (it fits what he did).
    putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
    final topic = m7SpillFinalWhy(_run.deal);
    unawaited(askReason(
      deal: () => dealChoices(M7SpillBoomLines.whyRight[topic]!, M7SpillBoomLines.myths, widget.rng),
      question: M7SpillBoomLines.whyQ[topic]!,
      stillValid: () => !_ended,
    ));
  }

  // --- pans -------------------------------------------------------------------------------
  /// A still press that the long press won: the soak (a pad held on the
  /// puddle), else the pan it was going to be.
  void _holdStart(Offset p, M7SpillGeo geo) {
    if (_canPlay && _run.stage == M7SpillStage.contain && _run.puddleOn && geo.puddleHit(_run.puddleAt, _run.r).contains(p)) {
      _pan = _Pan.none;
      _soakOnce();
      return;
    }
    _panStart(p, geo);
  }

  void _soakOnce() {
    if (!_run.sealed) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    if (!_run.soak()) return;
    HapticFeedback.lightImpact();
    _cue('sounds/intro/drop.ogg', volume: 0.6);
    _stepDone();
    if (_run.soakedAll) unawaited(_sayChain([_task]));
  }

  void _panStart(Offset p, M7SpillGeo geo) {
    _pan = _Pan.none;
    if (!_canPlay) return;
    _panNow = p;
    final st = _run.stage;
    if (_run.kitOpen && !_run.valveOpen && _run.padsPlaced < 3 && geo.padStackHit.contains(p)) {
      _pan = _Pan.pad;
      setState(() => _padDrag = p);
      return;
    }
    if (st == M7SpillStage.hose && geo.hoseHit(geo.hoseHome).contains(p)) {
      _pan = _Pan.hose;
      setState(() => _hoseDrag = geo.hoseHome);
      return;
    }
    if (geo.knobHit(_valveP).contains(p)) {
      _pan = _Pan.valve;
      setState(() {});
      return;
    }
    if (!_run.kitOpen) return;
    final boomOk = (st == M7SpillStage.setup || st == M7SpillStage.hose || st == M7SpillStage.valve) && !_run.valveOpen || (st == M7SpillStage.contain && _run.puddleOn);
    if (!boomOk) return;
    if (st == M7SpillStage.contain && holdForCoworker()) return;
    _pan = _Pan.boom;
    _pts
      ..clear()
      ..add(p);
    _stroke.value = List.of(_pts);
  }

  void _panUpdate(Offset p, M7SpillGeo geo) {
    _panNow = p;
    switch (_pan) {
      case _Pan.pad:
        setState(() => _padDrag = p);
      case _Pan.hose:
        setState(() => _hoseDrag = p);
      case _Pan.valve:
        final now = geo.progressAt(p);
        if ((now - _valveP).abs() > 0.01) setState(() => _valveP = now);
        final opening = !_run.valveOpen && !_run.valveWasOpen;
        if (opening && now >= 0.92) _valveTurned(open: true);
        if (!opening && _run.valveOpen && now <= 0.08) _valveTurned(open: false);
      case _Pan.boom:
        if (_pts.isEmpty || (p - _pts.last).distance >= 5) {
          _pts.add(p);
          _stroke.value = List.of(_pts);
        }
      case _Pan.none:
        break;
    }
  }

  void _panEnd() {
    final kind = _pan;
    _pan = _Pan.none;
    final geo = _geoNow;
    if (geo == null) return;
    switch (kind) {
      case _Pan.pad:
        final at = _padDrag;
        setState(() => _padDrag = null);
        if (at != null && _canPlay && _run.placePad(at, geo)) {
          _tick('sounds/intro/drop.ogg', 0.6);
          _stepDone();
          _afterSetupMove();
        } else {
          _hints.missTap();
        }
      case _Pan.hose:
        final at = _hoseDrag ?? _panNow;
        setState(() => _hoseDrag = null);
        if (_canPlay) unawaited(_hoseLet(at, geo));
      case _Pan.valve:
        if (_canPlay) _valveReleased();
      case _Pan.boom:
        final pts = List<Offset>.of(_pts);
        _pts.clear();
        _stroke.value = const [];
        if (_canPlay) _boomDrawn(pts, geo);
      case _Pan.none:
        break;
    }
  }

  void _boomDrawn(List<Offset> pts, M7SpillGeo geo) {
    if (_run.valveOpen) {
      final j = _run.drawContain(pts);
      if (j == M7RingJudge.tooShort) {
        _hints.missTap();
        return;
      }
      _cue('sounds/intro/click.ogg', volume: 0.5);
      _stepDone();
      return;
    }
    final j = _run.drawSetupBoom(pts, geo);
    if (j == M7RingJudge.tooShort || (j == M7RingJudge.open && !identical(_run.ring1, pts))) {
      _hints.missTap();
      return;
    }
    _cue('sounds/intro/click.ogg', volume: 0.5);
    _stepDone();
    _afterSetupMove();
  }

  /// The pads and the boom are both down: ◆ on the table, then the reason (the
  /// ring itself is judged only if oil gets out).
  void _afterSetupMove() {
    if (!_run.setupReady || _run.setupPaid) return;
    _run.setupPaid = true;
    putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(M7SpillBoomLines.whyRight[M7SpillWhy.kit]!, M7SpillBoomLines.myths, widget.rng),
      question: M7SpillBoomLines.whyQ[M7SpillWhy.kit]!,
      stillValid: () => !_ended,
    ));
  }

  Future<void> _hoseLet(Offset at, M7SpillGeo geo) async {
    final (t, slot) = geo.targetAt(at);
    final m = _run.hoseTo(t, slot, geo);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, _sceneToGlobal(at)));
      return;
    }
    if (_run.hoseSlot == null) {
      _hints.missTap();
      setState(() {});
      return;
    }
    _tick('sounds/intro/click.ogg', 0.55);
    setState(() => _wake++);
    if (!_run.hoseReasoned) {
      _run.hoseReasoned = true;
      putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
      unawaited(askReason(
        deal: () => dealChoices(M7SpillBoomLines.whyRight[M7SpillWhy.drum]!, M7SpillBoomLines.myths, widget.rng),
        question: M7SpillBoomLines.whyQ[M7SpillWhy.drum]!,
        stillValid: () => !_ended,
      ));
    }
  }

  /// The lever reached the far end of its quarter turn.
  void _valveTurned({required bool open}) {
    _pan = _Pan.none;
    if (open) {
      final m = _run.openValve();
      if (m != null) {
        setState(() => _valveP = 0);
        unawaited(_mistake(m, _sceneToGlobal(_geoNow?.valvePivot ?? Offset.zero)));
        return;
      }
      if (!_run.valveOpen) {
        // No hose in a container yet: the lever springs back.
        setState(() => _valveP = 0);
        _hints.missTap();
        return;
      }
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/ring_steel.ogg', volume: 0.6);
      setState(() {
        _valveP = 1;
        _wake++;
      });
      unawaited(_sayChain([_task]));
      return;
    }
    if (_run.closeValve()) {
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/ring_steel.ogg', volume: 0.6);
      setState(() {
        _valveP = 0;
        _wake++;
      });
      _maybeFinish();
    }
  }

  void _valveReleased() {
    // Let go short of the end: the lever springs back to where it was.
    setState(() => _valveP = _run.valveOpen ? 1 : 0);
    _hints.missTap();
  }

  void _maybeFinish() {
    if (!_run.done || _ended) return;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 800), () {
      if (mounted && !_ended) unawaited(_finish());
    }));
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
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
    _run.tablePaid();
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7SpillBoomLines.coworker(_run.push ?? _run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended || !_run.puddleOn || _run.push == null || _run.stage != M7SpillStage.contain) return null;
    if (_intro || _card != null || tableBusy || _slice || _pan != _Pan.none) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _run.push ?? _run.deal.push;
    if (!held) {
      final m = _run.listen(p);
      // The ground-slice picture (the myth's reality), then the card.
      setState(() {
        _slice = true;
        _wake++;
      });
      _sliceTimer?.cancel();
      final done = Completer<void>();
      _sliceTimer = Timer(Duration(milliseconds: _quiet ? 500 : 1800), done.complete);
      await done.future;
      if (!mounted) return;
      setState(() => _slice = false);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M7SpillBoomLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7SpillBoomLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7SpillBoomLines.tapWhy[_nudgeN++ % M7SpillBoomLines.tapWhy.length]
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7spill/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The play goes on from where it was (the mate stopped the oil, the hose
    // is back at the valve).
    _hush();
    setState(() {
      _card = null;
      _wake++;
    });
    unawaited(_sayChain([_task]));
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
    await _say(!_run.passed ? M7SpillBoomLines.fail : (_quickBonus ? M7SpillBoomLines.quick : M7SpillBoomLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_pan != _Pan.none) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M7SpillRig get _rig {
    final slot = _run.hoseSlot;
    final geo = _geoNow;
    Offset? end = _hoseDrag;
    if (end == null && slot != null && geo != null) end = geo.slotMouth(slot);
    return M7SpillRig(
      slots: _run.deal.slots,
      weeping: _run.deal.weeping,
      incident: _run.deal.incident,
      dusk: _run.deal.dusk,
      kitOpen: _run.kitOpen,
      pads: _run.padsPlaced,
      ring1: _run.ring1,
      ring2: _run.ring2,
      valve: _valveP,
      hoseEnd: end,
      hoseSlot: slot,
      puddleOn: _run.puddleOn,
      puddleAt: _run.puddleAt,
      puddleR: _run.r,
      held: _run.held,
      edge: _run.edge,
      edgeDir: _run.edgeDir,
      left: _run.left,
      soaked: _run.soaked,
      usedPads: _run.usedPads,
      bagged: _run.bagged,
      bungShut: _run.bungShut,
      dragPad: _padDrag,
    );
  }

  /// The gesture hand: how to touch, never what. Set-up untouched: a sweep
  /// over the kit, the valve, the hose end and the containers alike (never a
  /// tap on the kit). Pads waiting: one pad nudged straight up out of the box.
  /// Boom waiting: the plain drag hand on neutral ground (M7-12, no curved
  /// hint). Hose: a nudge straight out from the valve. Valve (the only way
  /// forward once the hose is in): a drag along the lever's arc. Pad on the
  /// puddle: a hold on it. Used pads: a sweep over both bins alike. The bung:
  /// a tap; with the valve too, a sweep over both.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_run.stage) {
      case M7SpillStage.setup:
        if (!_run.kitOpen) return HintSpec.sweep(geo.setupSweep(), space: HintSpace.scene);
        if (_run.padsPlaced < m7SpillPadsToSet) {
          return HintSpec.drag(geo.padStackHit.center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
        }
        return HintSpec.drag(geo.boomHintAt, toward: const Offset(1, 0), travel: 56, space: HintSpace.scene);
      case M7SpillStage.hose:
        return HintSpec.drag(geo.hoseHome, toward: const Offset(0, 1), travel: 40, space: HintSpace.scene);
      case M7SpillStage.valve:
        final a = geo.knob(0);
        final d = geo.knob(1) - a;
        return HintSpec.drag(a, toward: d / d.distance, travel: 30, space: HintSpace.scene);
      case M7SpillStage.contain:
        if (!_run.puddleOn) return null;
        if (_run.sealed) return HintSpec.hold(_run.puddleAt, space: HintSpace.scene);
        return HintSpec.drag(geo.boomHintAt, toward: const Offset(1, 0), travel: 56, space: HintSpace.scene);
      case M7SpillStage.bag:
        return HintSpec.sweep([geo.redBin, geo.greenBin], space: HintSpace.scene);
      case M7SpillStage.close:
        final slot = _run.hoseSlot;
        final bung = slot == null || _run.bungShut ? null : geo.bungHit(slot);
        if (_run.valveOpen && bung != null) return HintSpec.sweep([geo.valveArea, bung], space: HintSpace.scene);
        if (_run.valveOpen) {
          final a = geo.knob(1);
          final d = geo.knob(0) - a;
          return HintSpec.drag(a, toward: d / d.distance, travel: 30, space: HintSpace.scene);
        }
        return bung == null ? null : HintSpec.tap(bung.center, space: HintSpace.scene);
      case M7SpillStage.done:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7SpillGeo.forScene(m.height, m.inset, drainRight: _run.deal.drainRight);
    final quiet = _quiet;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: Stack(
          children: [
            Positioned.fill(
              key: const ValueKey('yard'),
              child: RepaintBoundary(child: CustomPaint(painter: M7SpillPainter(geo: geo, rig: _rig, stroke: _stroke))),
            ),
            Positioned.fromRect(
              key: const ValueKey('mate'),
              rect: geo.mateRect,
              child: const LinemanFigure(look: _mateLook, mode: LinemanMode.idle, quiet: true, awakeMs: 1),
            ),
            Positioned.fromRect(
              key: const ValueKey('trainee'),
              rect: geo.traineeRect,
              child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
            ),
          ],
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7SpillBoomLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A pan is judged by where the finger went down (the pad stack, the
            // hose end, the lever), not where it passed the slop.
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapAt(d.localPosition, geo),
            // A finger that rests ~0.5 s before it moves goes to the long
            // press, not the pan: on the puddle that is the soak; anything
            // else carries on as the same pan.
            onLongPressStart: (d) => _holdStart(d.localPosition, geo),
            onLongPressMoveUpdate: (d) => _panUpdate(d.localPosition, geo),
            onLongPressEnd: (_) => _panEnd(),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      if (_slice)
        Positioned.fromRect(
          key: const ValueKey('slice'),
          rect: M7SpillGeo.sliceCard,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 360),
              builder: (_, v, child) => Opacity(opacity: v, child: child),
              child: const M7SliceCard(),
            ),
          ),
        ),
    ];
  }

  static const _mateLook = LinemanLook(
    helmet: Color(0xFFF2F2F2),
    shirt: Color(0xFF3F7D4E),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF3A3F46),
    skin: Color(0xFFB57A52),
    moustache: true,
    gloves: true,
  );

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_slice && !_run.ended;
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
              labels: M7SpillBoomLines.stages,
              done: {
                if (_run.setupPaid) 0,
                if (_run.valveWasOpen) 1,
                if (_run.bagged) 2,
                if (_run.done) 3,
              },
              current: _run.done
                  ? null
                  : switch (stage) {
                      M7SpillStage.setup => 0,
                      M7SpillStage.hose || M7SpillStage.valve => 1,
                      M7SpillStage.contain || M7SpillStage.bag => 2,
                      M7SpillStage.close || M7SpillStage.done => 3,
                    },
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _pan == _Pan.none && !(stage == M7SpillStage.contain && !_run.puddleOn),
            hintKey: '${stage.name}/$_steps/${_run.padsPlaced}/${_run.kitOpen}/${_run.soaked}/${_run.escaped}/${_run.contained}/${_run.valveOpen}/${_run.bungShut}/${_run.puddleOn}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
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
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M7SpillBoomLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 3, muted: _muted)),
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
