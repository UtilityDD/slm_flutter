import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'choice_deck.dart';
import 'content_catalog.dart';
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
import 'm5_gate_case_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

// Module 5 rank gate (rung m5/gate, pack gate_m5, engineType m5_gate_case):
// "অ্যাডভান্সডের ডকেট: এক রাতের কেস" — the trainee runs one fault call as the
// crew in-charge, move by move (lessons 5.1–5.10; rulings
// docs/module_specs/module5_rulings.md, M5-12).
//
// The scene is the van's open back at the feeder's start (night or day): the
// feeder map pinned inside (sections, FPIs where dealt, villages, trees, DTRs
// and a UG crossing on every map), the notes sheet under it where every answer
// and report is written raw, and four fixed, unmarked tools on the tailgate:
// the phone (the control-room menu), the radio with two mate chips and the van
// chip, the PTW clipboard — and the map itself (where a chip is sent).
//
// One case of six is dealt from lesson facts only: (A) storm + earth fault
// (branch or punctured insulator; the chain in half), (B) clear + overcurrent
// (bird with collateral, or melted jumper with an annealed conductor in half),
// (C) wind, recloses then lock-out (clashed span), (D) a conductor fallen in a
// lane, (E) a UG cable fault at the road crossing, (F) a night live-line
// transient (tracking / corona, seen with the lights off). One dispatch engine
// ([M5Run]) applies every module rule to one moving state — no station replays
// a level loop.
//
// 1. GuideIntro with the case's line (no start button, no skip).
// 2. Phone: ask the control room (shuffled, always complete menu); the answer
//    is written raw on the notes sheet; asking costs only story minutes. 'PTW
//    দিন' issues the slip → drag (or tap) it onto the clipboard → ◆.
// 3. Dispatch (core verb): drag (or tap) a mate chip or the van chip onto a map
//    spot → pick an order (shuffled, always complete) → hold the radio to send.
//    The crew goes; a raw report comes back pinned on the map. First patrol ◆
//    (hypothesis); the charge-push coworker comes when the first report
//    returns (the next tailgate touch waits for him: holdForCoworker), the
//    'wait till morning' one as the first patrol is sent (before the van
//    leaves); locate ◆ (with FPIs, the bright one and the next dark one must
//    have been read).
// 4. Make safe (fallen wire: far cordon ◆ — a rope beside the wire is a slip;
//    overhead: tester + earth, only with the PTW; after the line clear the PTW
//    is back and any hands-on move is deadly) → the one close view up the pole: tap the parts, pick a remedy
//    for each, 'হয়ে গেছে' (at most one slip per press) → ◆. UG case instead:
//    isolate both ends → megger → specialist team → underground-service owners'
//    call → peg (◆ on the megger and the call).
// 5. The report (verdict): স্থায়ী / অস্থায়ী, plus 'এবার কী?' when the logbook
//    showed repeats → ◆.
// 6. Line clear: radio 'সবাই নেমে এসো, আর্থ খোলো' → phone 'লাইন ক্লিয়ার' →
//    'চার্জ করুন' → the villages light → ◆ → pass (rank অ্যাডভান্সড,
//    unlockRank(5), badge ফল্ট ফাইন্ডার). Case F ends at its report (the line
//    is in service).
// Scoring as the module's levels: ◆ 15 on the table per reason, coworker
// refused +10, slip −10, pass +20, quick bonus +10. Deadly / slip: the module
// table (rulings M5-1…M5-8). Voice: the guide by device TTS (M5GateLines); the
// coworker in his recorded voice (new lines listed in
// M5GateLines.newRivalLines for the director). Art: m5_gate_case_world.dart;
// mistake pictures in assets/game/art/m5_gate_case/.
//
// Dropped from the item spec (5–7 min budget, M5-12): the aftershock (its
// "right" card would re-fit a DO after an instant blast, which ruling M5-1
// makes deadly) — see the build report.

// ============================================================================
// Content
// ============================================================================

/// The dealt case (A–F).
enum M5Case { storm, clear, wind, fallen, cable, night }

extension M5CaseFacts on M5Case {
  /// The feeder is locked out (A–E); F is in service, tripping and reclosing.
  bool get lockOut => this != M5Case.night;

  /// A pole-top close view follows the find (A–D).
  bool get closeView => this != M5Case.cable && this != M5Case.night;
}

/// The control-room menu.
enum M5Ask { relay, recloser, weather, customers, logbook, ptw, lineClear, charge }

const m5InfoAsks = {M5Ask.relay, M5Ask.recloser, M5Ask.weather, M5Ask.customers, M5Ask.logbook};

/// The radio orders (the same complete set every time; lights-off at night).
/// [rope] is the too-close cordon (R16), [bamboo] the poke at the line (R20).
enum M5Order { look, fpi, people, cordon, rope, earth, climb, bamboo, lightsOff }

/// Orders that put a crew's hands or a tool on the line.
bool m5IsHands(M5Order o) => o == M5Order.earth || o == M5Order.climb || o == M5Order.bamboo;

/// Ground orders that are a patrol (the first one is the hypothesis).
bool m5IsPatrol(M5Order o) => o == M5Order.look || o == M5Order.people || o == M5Order.lightsOff;

/// The chips on the radio: two mates and the van (two people together).
enum M5Chip { mateA, mateB, van }

/// A place on the map: a section (0–3) or an FPI (0–2, between sections).
@immutable
class M5Spot {
  const M5Spot.section(this.i) : fpi = false;
  const M5Spot.fpiAt(this.i) : fpi = true;
  final int i;
  final bool fpi;
  String get id => fpi ? 'f$i' : 's$i';

  @override
  bool operator ==(Object other) => other is M5Spot && other.i == i && other.fpi == fpi;
  @override
  int get hashCode => Object.hash(i, fpi);
  @override
  String toString() => id;
}

/// The close view's parts (the painter's index order).
enum M5Part { insL, insM, insR, arm, jumper, span, lead }

/// Damage on the pole top (lesson 5.3).
enum M5Damage { branch, puncture, carbon, bird, melted, annealed, clash, broken }

/// What a part needs.
enum M5Remedy { removeBranch, replaceIns, removeBird, replaceClamp, cutSoft, fixClash, joinBroken, none }

M5Remedy m5RemedyFor(M5Damage? d) => switch (d) {
      null => M5Remedy.none,
      M5Damage.branch => M5Remedy.removeBranch,
      M5Damage.puncture || M5Damage.carbon => M5Remedy.replaceIns,
      M5Damage.bird => M5Remedy.removeBird,
      M5Damage.melted => M5Remedy.replaceClamp,
      M5Damage.annealed => M5Remedy.cutSoft,
      M5Damage.clash => M5Remedy.fixClash,
      M5Damage.broken => M5Remedy.joinBroken,
    };

/// The remedy deck for a part needing [r]: always one 'ঠিক আছে' card and two
/// remedy cards, for a sound part and a damaged one alike — so the deck never
/// tells which parts are damaged (no free detector by tapping everything).
List<ChoiceOption> m5RemedyDeck(M5Remedy r, math.Random rng) {
  String one(M5Remedy m) {
    final l = M5GateLines.remedy(m);
    return l[rng.nextInt(l.length)];
  }

  final others = [for (final o in M5Remedy.values) if (o != r && o != M5Remedy.none) o]..shuffle(rng);
  final wrong = r == M5Remedy.none ? [others[0], others[1]] : [M5Remedy.none, others[0]];
  return [
    ChoiceOption(one(r), true),
    for (final w in wrong) ChoiceOption(one(w), false),
  ]..shuffle(rng);
}

/// The UG case's steps (lesson 5.9).
enum M5UgStep { isolate, megger, team, owners, peg, guessDig, selfJoint }

/// The coworker's push (dealt by case and time).
enum M5Push { chargeNight, chargeDay, waitMorning }

/// The ◆ questions.
enum M5Reason { ptw, hypothesis, locate, earth, cordon, closeView, permanent, transient, history, lineClear, megger, dig }

/// The verdict sheet's first field.
enum M5Verdict { permanent, transient }

abstract final class M5GateLines {
  static const title = 'অ্যাডভান্সডের ডকেট: এক রাতের কেস';
  static const badge = 'ফল্ট ফাইন্ডার';

  /// The case's opening line (the guide, first).
  static String intro(M5Deal d) {
    if (d.kase == M5Case.night) return enDigits('রাত ${d.hour}টা! ফিডার ${d.feederNo} বারবার ট্রিপ করছে আর ফিরে আসছে। কারণ খুঁজুন!');
    final when = d.night ? 'রাত ${d.hour}টা' : 'দুপুর ${d.hour}টা';
    return enDigits('$when! 11 কেভি ফিডার ${d.feederNo} ট্রিপ করে লক-আউট। আপনি দলের ইনচার্জ — ফল্ট খুঁজে বের করুন!');
  }

  // The tasks (the corner guide repeats the current one, a new way each tap).
  static const taskIdle = 'ফল্টটা খুঁজে বের করুন — যা দরকার, করুন।';
  static const taskChip = 'কোথায় পাঠাবেন? ম্যাপে রাখুন।';
  static const taskSlip = 'PTW-টা কোথায় রাখবেন?';
  static const taskOrder = 'কী করতে বলবেন?';
  static const taskSend = 'রেডিও চেপে ধরে বলুন।';
  static const taskPhone = 'কন্ট্রোল রুমকে কী বলবেন?';
  static const taskView = 'পোলের মাথায় কী কী দেখছেন? ছুঁয়ে দেখুন।';
  static const taskRemedy = 'এটার কী করবেন?';
  static const taskVerdict = 'রিপোর্টটা লিখুন।';
  static const taskUg = 'কেবিলের কাজ — এবার কী?';
  static const tasks = [taskIdle, taskChip, taskSlip, taskOrder, taskSend, taskPhone, taskView, taskRemedy, taskVerdict, taskUg];
  static const tapWhy = ['ঠিক কারণটা কোনটা?', 'কেন করলেন, বেছে নিন।'];

  // Labels a worker reads.
  static const docket = 'ডকেট';
  static const map = 'ফিডার ম্যাপ';
  static const notes = 'নোট';
  static const substation = 'সাবস্টেশন';
  static const control = 'কন্ট্রোল রুম';
  static const ptwSlip = 'PTW';
  static const send = 'চেপে ধরে বলুন';
  static const done = 'হয়ে গেছে';
  static const report = 'রিপোর্ট';
  static const permanent = 'স্থায়ী';
  static const transient = 'অস্থায়ী';
  static const whatNext = 'এবার কী?';
  static const rootCause = 'মূল কারণ খুঁজি';
  static const repairOnly = 'শুধু মেরামত';
  static const submit = 'জমা দিন';
  static const ugTitle = 'কেবিল ফল্ট';
  static const close = 'বন্ধ';
  static String chip(M5Chip c) => switch (c) {
        M5Chip.mateA => 'মেট 1',
        M5Chip.mateB => 'মেট 2',
        M5Chip.van => 'ভ্যান',
      };

  static String ask(M5Ask a) => switch (a) {
        M5Ask.relay => 'রিলে কী দেখাল?',
        M5Ask.recloser => 'রিক্লোজার কতবার চেষ্টা করেছিল?',
        M5Ask.weather => 'ট্রিপের সময় আবহাওয়া?',
        M5Ask.customers => 'গ্রাহকরা কিছু বলেছে?',
        M5Ask.logbook => 'লগবুকে এই ফিডার?',
        M5Ask.ptw => 'PTW দিন',
        M5Ask.lineClear => 'লাইন ক্লিয়ার',
        M5Ask.charge => 'চার্জ করুন',
      };

  static String order(M5Order o, {required bool night}) => switch (o) {
        M5Order.look => night ? 'সার্চলাইটে ধীরে দেখো' : 'বাইনোকুলারে থেমে দেখো',
        M5Order.fpi => 'FPI পড়ো',
        M5Order.people => 'লোকজনকে জিজ্ঞেস করো',
        M5Order.cordon => 'দূর থেকে ঘিরে দাও',
        M5Order.rope => 'তারের পাশেই দড়ি টেনে দাও',
        M5Order.earth => 'টেস্টারে দেখে আর্থ লাগাও',
        M5Order.climb => 'উঠে কাছ থেকে দেখো ও সারাও',
        M5Order.bamboo => 'বাঁশ দিয়ে খুঁচিয়ে দেখো',
        M5Order.lightsOff => 'আলো নিভিয়ে অপেক্ষা করে দেখো',
      };

  static const callDown = 'সবাই নেমে এসো, আর্থ খোলো';

  static String ug(M5UgStep s) => switch (s) {
        M5UgStep.isolate => 'দুই প্রান্ত আইসোলেট করো',
        M5UgStep.megger => 'মেগারে ফল্টের ধরন দেখো',
        M5UgStep.team => 'বিশেষজ্ঞ টিম ডাকো',
        M5UgStep.owners => 'মাটির নিচের লাইনের মালিকদের ফোন',
        M5UgStep.peg => 'খুঁটি পুঁতে জায়গা চিহ্নিত করো',
        M5UgStep.guessDig => 'আন্দাজে খুঁড়ে দেখো',
        M5UgStep.selfJoint => 'নিজেরাই জয়েন্ট করে দাও',
      };

  static const villages = ['হরিপুর', 'কলাবাগান', 'নদীপাড়', 'স্টেশনপাড়া', 'বটতলা', 'দিঘিরপাড়', 'হাটখোলা', 'শিমুলতলা'];

  // --- what the control room says (raw, never a cause word) -------------------
  static String answer(M5Deal d, M5Ask a) {
    final k = d.k;
    final v = d.villages[k];
    return switch (a) {
      M5Ask.relay => switch (d.kase) {
          M5Case.clear || M5Case.wind => 'রিলে: ওভারকারেন্ট, তৎক্ষণাৎ ট্রিপ',
          M5Case.night => 'রিলে: আর্থ ফল্ট, তারপর আবার চালু',
          _ => 'রিলে: আর্থ ফল্ট',
        },
      M5Ask.recloser => switch (d.kase) {
          M5Case.wind => enDigits('প্রতিবার কিছুক্ষণ টিকেছে, ${d.tries} বার পর লক-আউট'),
          M5Case.night => 'ট্রিপ করছে আর নিজেই আবার চালু হচ্ছে',
          _ => enDigits('রিক্লোজার ${d.tries} বার চেষ্টা করে লক-আউট'),
        },
      M5Ask.weather => switch (d.kase) {
          M5Case.storm => 'ঝড় আর বৃষ্টি চলছিল',
          M5Case.clear => 'আকাশ পরিষ্কার, হাওয়া নেই',
          M5Case.wind => 'জোর হাওয়া, বৃষ্টি নেই',
          M5Case.fallen => d.stormy ? 'ঝড় আর বৃষ্টি চলছিল' : 'আকাশ পরিষ্কার, হাওয়া নেই',
          M5Case.cable => 'শুকনো, পরিষ্কার আবহাওয়া',
          M5Case.night => 'ভেজা কুয়াশা পড়ছে',
        },
      M5Ask.customers => d.customersClue
          ? '$v থেকে ফোন: ${switch (d.kase) {
              M5Case.fallen => 'গলিতে তার পড়ে আছে',
              M5Case.cable => 'খোঁড়াখুঁড়ির পর থেকে অন্ধকার',
              M5Case.night => 'পোলের মাথায় হিসহিস শব্দ',
              _ => 'জোর শব্দ আর ঝলকানি',
            }}'
          : 'অনেক ফোন — শুধু “আলো নেই”',
      M5Ask.logbook => d.repeats ? enDigits('$v সেকশনে গত মাসে 2 বার ফল্ট') : 'এই ফিডারে আগে তেমন ফল্ট নেই',
      M5Ask.ptw => d.kase.lockOut ? 'PTW দেওয়া হলো — ফিডার বন্ধ' : 'ফিডার চালু আছে — আগে কারণ খুঁজুন',
      M5Ask.lineClear => 'লাইন ক্লিয়ার নেওয়া হলো, PTW ফেরত',
      M5Ask.charge => 'ফিডার চার্জ হলো',
    };
  }

  static const ptwAgain = 'PTW তো দেওয়াই আছে';
  static const liveAlready = 'ফিডার তো চালুই আছে';
  static const clearAgain = 'লাইন ক্লিয়ার তো দেওয়াই আছে';
  static const clearNotYet = 'কন্ট্রোল রুম: কাজ কি শেষ হয়েছে?';

  // --- what a crew reports (raw) ----------------------------------------------
  static String sighting(M5Deal d) => switch (d.culprit) {
        M5Damage.branch => 'একটা ভাঙা ডাল তারের ওপর পড়ে আছে',
        M5Damage.puncture => 'একটা ইনসুলেটরের গায়ে ফাটল চোখে পড়ছে',
        M5Damage.bird => 'ক্রস-আর্মের নিচে একটা পোড়া পাখি পড়ে',
        M5Damage.melted => 'জাম্পারের জোড়ের কাছটা কালো হয়ে আছে',
        M5Damage.clash => 'দুই পোলের মাঝে তার খুব ঝুলে, কালো দাগ',
        M5Damage.broken => 'গলিতে একটা তার মাটিতে পড়ে, স্পার্ক নেই',
        _ => d.kase == M5Case.cable ? 'রাস্তা নতুন করে খোঁড়া, পাশে পোড়া গন্ধ' : searchlightNothing,
      };
  static const searchlightNothing = 'সার্চলাইটে কিছু ভাঙা চোখে পড়ছে না';
  static const glow = 'আলো নেভাতেই একটা ইনসুলেটরে নীলচে আভা, হিসহিস শব্দ';
  static const nothingGlow = 'আলো নিভিয়ে অপেক্ষা — কিছু দেখা গেল না';
  static const nothingSeen = 'কিছু চোখে পড়েনি, লাইন ঠিক দেখাচ্ছে';
  static String people(M5Deal d) => switch (d.kase) {
        M5Case.fallen => 'গলির দিকে কিছু একটা পড়ার শব্দ হলো',
        M5Case.cable => 'আজ রাস্তায় জলের পাইপের জন্য খোঁড়া হয়েছে',
        M5Case.night => 'রাতে পোলের মাথা থেকে হিসহিস শব্দ আসে',
        _ => 'হঠাৎ জোর শব্দ আর আলোর ঝলকানি দেখেছি',
      };
  static const peopleNothing = 'আমরা কিছু শুনিনি, কিছু দেখিনি';
  static const fpiBright = 'FPI-এর লাল আলো জ্বলছে';
  static const fpiDark = 'FPI-এর আলো নিভে আছে';
  static const noFpiHere = 'এখানে কোনো FPI নেই';
  static const onlyFpi = 'এখানে শুধু FPI-টা আছে';
  static const corded = 'তারের চারপাশে 10 মিটার দূরে দড়ি দেওয়া হলো';
  static const nothingToCord = 'ঘেরার মতো কিছু চোখে পড়েনি';
  static const ropedNear = 'তারের ঠিক পাশেই দড়ি টানা হলো, তার মাটিতে পড়ে';
  static const pokedNothing = 'বাঁশে খুঁচিয়ে কিছু বোঝা গেল না';
  static const earthed = 'টেস্টারে 0 V — আর্থ লাগানো হলো';
  static const upTop = 'পোলের মাথায় উঠেছে';
  static const nothingUp = 'কাছে গিয়েও কিছু পাওয়া গেল না';
  static const cableBelow = 'কেবিল মাটির নিচে — ওঠার কিছু নেই';
  static const cameDown = 'সবাই নেমে এসেছে, আর্থ খোলা হয়েছে';
  static const allDown = 'দল তো নিচেই আছে';
  static const decoys = [
    'পোলের গায়ে নতুন একটা পোস্টার',
    'রাস্তার ধারে পোড়া পাতার স্তূপ',
    'একটা পোলের পাশে গরু বাঁধা',
    'DTR-এর পাশে কয়েকজন আড্ডা দিচ্ছে',
    'তারের ওপর কয়েকটা কাক বসে আছে',
    'পোলের গোড়ায় জল জমে আছে',
  ];
  static String ugNote(M5UgStep s) => switch (s) {
        M5UgStep.isolate => 'কেবিলের দুই প্রান্ত খুলে আলাদা করা হলো',
        M5UgStep.megger => 'মেগার: একটা কোর আর আর্মারে প্রায় শূন্য',
        M5UgStep.team => 'বিশেষজ্ঞ টিম থাম্পার নিয়ে আসছে',
        M5UgStep.owners => 'টেলিফোন, জল, গ্যাস লাইনের মালিকরা জানলেন',
        M5UgStep.peg => 'থাম্পারে “ঠক্” — খুঁটি পোঁতা, টিম জয়েন্ট করল',
        _ => '',
      };

  // --- the close view's remedies (every card 26–34 letters) --------------------
  static List<String> remedy(M5Remedy r) => switch (r) {
        M5Remedy.removeBranch => const ['ডাল সরিয়ে তার আর ইনসুলেটর দেখো', 'আগে ডাল নামাও, তারপর তার পরীক্ষা'],
        M5Remedy.replaceIns => const ['ইনসুলেটর খুলে নতুন একটা লাগাও', 'মুছলে চলবে না, ইনসুলেটর বদলাও'],
        M5Remedy.removeBird => const ['পাখি সরিয়ে আশপাশের ক্ষতি দেখো', 'পোড়া পাখি নামিয়ে বাকিটা পরীক্ষা'],
        M5Remedy.replaceClamp => const ['পোড়া কানেক্টর খুলে নতুন লাগাও', 'গলে যাওয়া PG ক্ল্যাম্প বদলে দাও'],
        M5Remedy.cutSoft => const ['নরম হয়ে যাওয়া অংশটা কেটে বাদ দাও', 'বিবর্ণ অংশ কেটে নতুন তার জোড়ো'],
        M5Remedy.fixClash => const ['পোড়া অংশ সারাও, তারের ঝুল ঠিক করো', 'দাগ-পড়া তার সারাও, ঝোলা তার টানো'],
        M5Remedy.joinBroken => const ['ছেঁড়া তার নিয়ম মেনে জয়েন্ট করো', 'ছেঁড়া দুই মাথা নিয়মমতো জোড়া দাও'],
        M5Remedy.none => const ['এটা ঠিক আছে, এখানে কিছু করার নেই', 'এটা অক্ষত আছে, যেমন আছে থাকুক'],
      };

  /// Wrong cards for a part needing [r]: every other remedy.
  static List<String> remedyWrong(M5Remedy r) => [
        for (final o in M5Remedy.values)
          if (o != r) ...remedy(o),
      ];

  // --- the ◆ questions and their cards (every card 29–36 letters) -------------
  static String question(M5Reason r) => switch (r) {
        M5Reason.ptw => 'লাইনে হাত দেওয়ার আগে PTW কেন?',
        M5Reason.hypothesis => 'প্রথমে ওই সেকশনেই কেন দল পাঠালেন?',
        M5Reason.locate => 'কেন এই অংশেই খুঁজলেন?',
        M5Reason.earth => 'হাত দেওয়ার আগে আর্থ কেন?',
        M5Reason.cordon => 'কেন দূর থেকে ঘিরে দিলেন?',
        M5Reason.closeView => 'সরানোর পরেও আর কী দেখলেন, কেন?',
        M5Reason.permanent => 'কেন একে স্থায়ী ফল্ট বললেন?',
        M5Reason.transient => 'কেন একে অস্থায়ী ফল্ট বললেন?',
        M5Reason.history => 'রিপোর্টে কেন পুরনো ফল্টের কথা?',
        M5Reason.lineClear => 'চার্জের আগে লাইন ক্লিয়ার কেন?',
        M5Reason.megger => 'কেন মেগারে আগে কেবিলের ধরন দেখলেন?',
        M5Reason.dig => 'খোঁড়ার আগে কেন ফোন করলেন?',
      };

  /// Realistic wrong reasons: habit, hurry, orders, a guess.
  static const excuses = [
    'সবাই তো এভাবেই করে, তাই করলাম',
    'তাড়া ছিল, তাই সহজটাই বেছে নিলাম',
    'অফিস বলেছে, তাই চোখ বুজে করলাম',
    'আন্দাজে মনে হলো, তাই এটাই করলাম',
    'আগেরবারও এভাবেই কাজ হয়েছিল তো',
  ];

  /// The right cards. [fpi]: the find was bracketed by FPIs.
  static List<String> whyRight(M5Reason r, {bool fpi = false}) => switch (r) {
        M5Reason.ptw => const ['ট্রিপ মানে ডেড নয়, চালু হতে পারে', 'লাইনে হাত দেওয়ার আগে PTW বাধ্যতামূলক', 'রিক্লোজার যেকোনো সময় চালু করে দেয়'],
        M5Reason.hypothesis => const ['সূত্রগুলো ওই সেকশনের দিকেই দেখাচ্ছিল', 'ভালো অনুমান খোঁজার এলাকা ছোট করে'],
        M5Reason.locate => fpi
            ? const ['জ্বলা আর নেভা FPI-এর মাঝেই এই অংশ', 'FPI-জোড়া বলছে ফল্ট এই দুইয়ের মাঝে']
            : const ['খবর আর রিপোর্ট এই অংশকেই দেখাচ্ছে', 'সূত্র মিলিয়ে এই অংশেই ফল্টের চিহ্ন'],
        M5Reason.earth => const ['ডেড প্রমাণ করে আর্থ দিলে তবে নিরাপদ', 'হঠাৎ চালু হলেও কারেন্ট মাটিতে নামবে'],
        M5Reason.cordon => const ['তার লাইভ ধরে 10 মিটার দূরে থাকতে হয়', 'তারের চারপাশে কমপক্ষে 10 মিটার নিরাপদ'],
        M5Reason.closeView => const ['একটা ফল্ট আরেকটার জন্ম দেয়, তাই সবটা', 'পুরো চিত্র না দেখলে ফল্ট আবার ফিরবে'],
        M5Reason.permanent => const ['লক-আউট মানে নিজে থেকে ঠিক হয়নি', 'মেরামত না করলে ফল্ট নিজে সারত না'],
        M5Reason.transient => const ['ট্রিপ করে আবার চালু — ফল্টটা ক্ষণিকের', 'রিক্লোজার চালু রাখছে, ফল্ট আসে-যায়'],
        M5Reason.history => const ['একই জায়গায় বারবার — মূল কারণ খুঁজতে', 'শুধু মেরামতে চলবে না, কারণটা সারাতে'],
        M5Reason.lineClear => const ['সবাই নেমেছে, আর্থ খোলা — তবেই চার্জ', 'কেউ লাইনে থাকলে চার্জ মানেই মৃত্যু'],
        M5Reason.megger => const ['আগে ধরন জানলে তবে ঠিক খোঁজা যায়', 'শর্ট, আর্থ না ওপেন — আগে মেগারে দেখা'],
        M5Reason.dig => const ['মাটির নিচে জল-গ্যাস-ফোনের লাইন থাকে', 'খোঁড়ার আগে অন্য লাইনের মালিক জানুক'],
      };

  static List<String> whyWrong(M5Reason r) => [
        ...switch (r) {
          M5Reason.ptw => const ['PTW থাকলে আর আর্থ লাগানোর দরকার নেই', 'PTW শুধু অফিসের খাতা ভরানোর জন্য'],
          M5Reason.hypothesis => const ['সাবস্টেশনের সবচেয়ে কাছে, তাই আগে', 'ওই রাস্তাটা ভালো, গাড়ি চলে সহজে'],
          M5Reason.locate => const ['পুরো লাইন হাঁটার সময় ছিল না তাই', 'এই অংশটা গাড়ি থেকে সবচেয়ে কাছে'],
          M5Reason.earth => const ['আর্থ দিলে PTW-র আর দরকার পড়ে না', 'আর্থ লাগালে কাজ তাড়াতাড়ি শেষ হয়'],
          M5Reason.cordon => const ['স্পার্ক নেই, তাই তার আসলে ডেডই আছে', 'দড়ি দিলে লোকে তারটা দেখতে পাবে'],
          M5Reason.closeView => const ['একটা পেলেই হলো, বাকিটা পরে দেখব', 'যত বেশি সারাব, তত বেশি নম্বর পাব'],
          M5Reason.permanent => const ['একটু পরে নিজেই ঠিক হয়ে যেত তো', 'স্থায়ী লিখলে অফিস তাড়াতাড়ি মানে'],
          M5Reason.transient => const ['লাইন চালু আছে, তাই কোনো ফল্টই নেই', 'অস্থায়ী মানে কিছু না করলেও চলবে'],
          M5Reason.history => const ['পুরনো কথা লিখলে রিপোর্ট বড় দেখায়', 'আগের দলের দোষ ধরতে লিখে রাখলাম'],
          M5Reason.lineClear => const ['লাইন ক্লিয়ার শুধু খাতার নিয়ম মাত্র', 'গ্রাহকেরা চেঁচাচ্ছে, তাই তাড়াতাড়ি'],
          M5Reason.megger => const ['মেগার দিয়ে কেবিল নিজেই সেরে যায়', 'মেগার না দেখলে অফিস বকাবকি করে'],
          M5Reason.dig => const ['ফোন করলে খোঁড়ার খরচ কম পড়ে যায়', 'মালিকেরাই এসে খুঁড়ে দেবে, তাই ফোন'],
        },
        ...excuses,
      ];

  /// "আজ যা ধরলেন" — from the player's own moves.
  static String caught(M5Reason r, {bool fpi = false, bool knock = false}) => switch (r) {
        M5Reason.ptw => 'PTW নিয়ে তবে লাইনে হাত',
        M5Reason.hypothesis => 'সূত্র ধরে প্রথম টহল',
        M5Reason.locate => fpi ? 'FPI-জোড়ায় ফল্ট ধরা' : 'সূত্র মিলিয়ে ফল্ট ধরা',
        M5Reason.earth => 'আর্থ দিয়ে তবে হাত',
        M5Reason.cordon => '10 মিটার দূর থেকে ঘেরা',
        M5Reason.closeView => knock ? 'একটার পেছনে আরেকটা ক্ষতি' : 'পুরো পোলের মাথা দেখা',
        M5Reason.permanent => 'স্থায়ী ফল্টের ঠিক রিপোর্ট',
        M5Reason.transient => 'অস্থায়ী ফল্টের ঠিক রিপোর্ট',
        M5Reason.history => 'বারবার ফল্টে মূল কারণ',
        M5Reason.lineClear => 'লাইন ক্লিয়ার করে তবে চার্জ',
        M5Reason.megger => 'আগে মেগারে ফল্টের ধরন',
        M5Reason.dig => 'খোঁড়ার আগে মালিকদের ফোন',
      };
  static const caughtCharge = 'চাপে চার্জ নয়';
  static const caughtNight = 'রাতেই খোঁজ, সকালে নয়';
  static const caughtPair = 'রাতে দুজন একসাথে';

  // The ranks (fallbacks when the catalog is not loaded).
  static const rankFrom = 'স্কিলড';
  static const rankTo = 'অ্যাডভান্সড';
  static const rankUp = 'নতুন র‍্যাঙ্ক!';
  static String promoted(String rank) => 'অভিনন্দন! আপনি এখন $rank লাইনম্যান — ফল্ট ফাইন্ডার।';
  static const fail = 'আরেকবার — আগে তথ্য, তারপর নিরাপদে খোঁজ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const refused = 'ঠিক! চাপে নিয়ম ভাঙা নয়।';
  static const lit = 'আলো ফিরল!';

  // --- the careless coworker (level 1's rival; his recorded voice) -------------
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _chargeRight = ['না, আগে ফল্ট খুঁজে সারাই, তারপর চার্জ', 'না, স্থায়ী ফল্টে চার্জ মানে আগুন-বিপদ', 'না, ফল্টের ওপর চার্জ করা কঠোর নিষেধ'];
  static const _chargeWrong = [
    'ঠিক, একবার চার্জ করে দেখুক তাহলে',
    'টিকে গেলে তো ভালোই, একবার বলেই দেখি',
    'গ্রাহকেরা রেগে আছে, চার্জ করুক বরং',
    'একবার চার্জে কী আর এমন ক্ষতি হবে',
    'ফল্ট নিজেই পুড়ে সরে যাবে, চার্জ হোক',
  ];
  static const _chargeAsks = ['ও বলছে চার্জ করাতে। আপনি কী করবেন?', 'চার্জ করাবেন, না আগে ফল্ট খুঁজবেন?'];
  static const chargeNight = CoworkerScript(
    line: 'রাত দুটো বাজে, গ্রাহকরা ফোনে চেঁচাচ্ছে! কন্ট্রোল রুমকে বলো একবার চার্জ করুক — টিকে গেলে বাড়ি যাই।',
    exitLine: coworkerExit,
    right: _chargeRight,
    wrong: _chargeWrong,
    asks: _chargeAsks,
  );
  static const chargeDay = CoworkerScript(
    line: 'অফিস থেকে বারবার ফোন! একবার চার্জ করিয়ে দাও — টিকে গেলে ঝামেলা শেষ।',
    exitLine: coworkerExit,
    right: _chargeRight,
    wrong: _chargeWrong,
    asks: _chargeAsks,
  );

  /// Lesson 5.7's myth, word for word.
  static const waitMorning = CoworkerScript(
    line: 'রাতে কিছু দেখা যায় না, তাই পেট্রোলিং করে লাভ নেই। সকাল হওয়ার জন্য অপেক্ষা করাই ভালো।',
    exitLine: coworkerExit,
    right: ['না, স্পার্ক-করোনা রাতেই ভালো দেখা যায়', 'না, বিদ্যুৎ ফেরানো জরুরি, এখনই খুঁজি', 'না, অন্ধকারেই নীল আভা ভালো দেখা যায়'],
    wrong: [
      'ঠিক, সকালে এসে দেখা যাবে সবটা বরং',
      'রাতে খুঁজে লাভ নেই, ফিরে যাই চলো',
      'আলো না ফোটা পর্যন্ত গাড়িতেই বসি',
      'দিনের আলোয় খুঁজলেই সহজ হবে সবটা',
      'অন্ধকারে কিছুই দেখা যাবে না, থাক',
    ],
    asks: ['ও বলছে সকাল পর্যন্ত থামতে। কী করবেন?', 'এখনই খুঁজবেন, না সকালের অপেক্ষা?'],
  );

  static CoworkerScript script(M5Push p) => switch (p) {
        M5Push.chargeNight => chargeNight,
        M5Push.chargeDay => chargeDay,
        M5Push.waitMorning => waitMorning,
      };

  /// His lines with no recorded clip yet (the director records them with
  /// tool/rival_clip.py and lists them in the dump test).
  static const newRivalLines = [
    'রাত দুটো বাজে, গ্রাহকরা ফোনে চেঁচাচ্ছে! কন্ট্রোল রুমকে বলো একবার চার্জ করুক — টিকে গেলে বাড়ি যাই।',
    'অফিস থেকে বারবার ফোন! একবার চার্জ করিয়ে দাও — টিকে গেলে ঝামেলা শেষ।',
    'রাতে কিছু দেখা যায় না, তাই পেট্রোলিং করে লাভ নেই। সকাল হওয়ার জন্য অপেক্ষা করাই ভালো।',
  ];

  static const coworkers = [chargeNight, chargeDay, waitMorning];
}

// ============================================================================
// Mistakes (the module's deadly/slip table; rulings M5-1…M5-8)
// ============================================================================

const _art = 'assets/game/art/m5_gate_case';

/// One gate mistake and the lesson that teaches it.
@immutable
class M5Mistake {
  const M5Mistake(this.lessonId, this.m);
  final String lessonId;
  final DoMistake m;
}

abstract final class M5GateMistakes {
  // Deadly.
  static const handsNoPtw = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/hands-no-ptw',
    textBn: 'PTW ক্লিপবোর্ডে ওঠার আগেই লাইনে হাত — ট্রিপ মানে ডেড নয়। PTW আর ব্যক্তিগত আর্থিং ছাড়া ট্রিপ হওয়া লাইন ছোঁয়া যাবে না।',
    art: '$_art/ptw.svg',
    deadly: true,
    lessonPoint: 1,
  ));
  static const climbNoEarth = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/climb-no-earth',
    textBn: 'টেস্টারে 0 V আর আর্থ ছাড়াই পোলে ওঠা — হঠাৎ চালু হলে বাঁচার পথ নেই। আগে টেস্টারে ডেড প্রমাণ, তারপর আর্থ, তবে ওঠা।',
    art: '$_art/earth.svg',
    deadly: true,
    lessonPoint: 1,
  ));
  static const chargeFault = M5Mistake('5.4', DoMistake(
    key: 'm5/gate/charge-fault',
    textBn: 'ফল্ট না সারিয়েই চার্জ — স্থায়ী ফল্টে লাইন আবার চার্জ করা মারাত্মক ভুল। যন্ত্রপাতি আরও পোড়ে, আগুন লাগে। আগে খুঁজে সারান।',
    art: '$_art/charge.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const chargeCrew = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/charge-crew',
    textBn: 'দল লাইনে বা আর্থ লাগানো অবস্থায় চার্জ — লাইন ক্লিয়ার ছাড়া চার্জ মানেই মৃত্যু। সবাই নেমে, আর্থ খুলে, লাইন ক্লিয়ার দিয়ে তবে চার্জ।',
    art: '$_art/clear.svg',
    deadly: true,
    lessonPoint: 1,
  ));
  static const clearCrewUp = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/clear-crew-up',
    textBn: 'দল লাইনে থাকতেই লাইন ক্লিয়ার — কন্ট্রোল রুম এবার চার্জ করবে। আগে সবাইকে নামিয়ে আর্থ খুলুন, তারপর লাইন ক্লিয়ার।',
    art: '$_art/clear.svg',
    deadly: true,
    lessonPoint: 1,
  ));
  static const wireZone = M5Mistake('5.2', DoMistake(
    key: 'm5/gate/wire-zone',
    textBn: 'পড়ে থাকা তারের কাছে দল পাঠানো — স্পার্ক না থাকলেও তার লাইভ ধরে নিন। তার এবং তার ছুঁয়ে থাকা বেড়া/গাছ/গাড়ির চারপাশে কমপক্ষে 10 মিটার দূরে থেকে আগে ঘিরে দিন।',
    art: '$_art/wire.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const climbLive = M5Mistake('5.7', DoMistake(
    key: 'm5/gate/climb-live',
    textBn: 'চালু লাইনে ওঠা বা হাত — চালু লাইনের টহল শুধু মাটি থেকে। আভা দেখা ইনসুলেটর শাটডাউন আর PTW নিয়ে তবেই বদলানো।',
    art: '$_art/glow.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const handsAfterClear = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/hands-after-clear',
    textBn: 'লাইন ক্লিয়ার দিয়ে PTW ফেরতের পর আবার লাইনে হাত — কন্ট্রোল রুম এখন যেকোনো সময় চার্জ করতে পারে। PTW ফেরত মানে আর কেউ লাইনে নয়।',
    art: '$_art/clear.svg',
    deadly: true,
    lessonPoint: 1,
  ));
  static const bamboo = M5Mistake('5.7', DoMistake(
    key: 'm5/gate/bamboo-poke',
    textBn: 'বাঁশ দিয়ে লাইন খোঁচানো — ভেতরের আর্দ্রতা বা ময়লার স্তর থাকলে শুকনো বাঁশও বিদ্যুৎ পরিবহন করে। চালু লাইন শুধু মাটি থেকে চোখে দেখা; টেস্টারে ডেড প্রমাণ আর আর্থ ছাড়া লাইনে কিছুই ছোঁয়ানো নয়।',
    art: '$_art/glow.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const meggerLive = M5Mistake('5.9', DoMistake(
    key: 'm5/gate/megger-live',
    textBn: 'কেবিলের দুই প্রান্ত আলাদা না করেই মেগার — অন্য প্রান্ত লাইভ থাকতে পারে। আগে দুই প্রান্ত আইসোলেট, তারপর মেগার।',
    art: '$_art/cable.svg',
    deadly: true,
    lessonPoint: 1,
  ));

  // Slips.
  static const patrolNoPtw = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/patrol-no-ptw',
    textBn: 'কন্ট্রোল রুমের ডকেট/PTW হাতে না নিয়েই লক-আউট ফিডারে দল পাঠালেন — টহলের আগে কন্ট্রোল রুমকে জানিয়ে ফিল্ড মেমো/ডকেট নিন; লাইনে হাত দেওয়া বা ওঠার আগে PTW বাধ্যতামূলক।',
    art: '$_art/ptw.svg',
    lessonPoint: 1,
  ));
  static const blindStart = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/blind-start',
    textBn: 'কিছু না জেনেই দল পাঠালেন — ফিল্ডে যাওয়ার আগে কন্ট্রোল রুমের অপারেটরের কাছ থেকে যতটা সম্ভব তথ্য নিন।',
    art: '$_art/info.svg',
    lessonPoint: 0,
  ));
  static const blindPatrol = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/blind-patrol',
    textBn: 'কোনো সূত্র ওই সেকশন দেখায়নি — ভালো অনুমান খোঁজার এলাকা ছোট করে দেয় আর সময় বাঁচায়; অন্ধের মতো খোঁজা নয়।',
    art: '$_art/info.svg',
    lessonPoint: 2,
  ));
  static const nightAlone = M5Mistake('5.7', DoMistake(
    key: 'm5/gate/night-alone',
    textBn: 'রাতে একজনকে একা পাঠালেন — রাতে ফল্ট খুঁজতে কখনো একা নয়; একজন গাড়ি চালাবেন, অন্যজন লাইন দেখবেন।',
    art: '$_art/night_pair.svg',
    lessonPoint: 3,
  ));
  static const noFpiPair = M5Mistake('5.2', DoMistake(
    key: 'm5/gate/no-fpi-pair',
    textBn: 'FPI থাকতেও জোড়া না পড়েই খোঁজা — যে দুটি FPI-এর একটা জ্বলছে আর পরেরটা নিভে, ফল্ট ঠিক তার মাঝে। আগে ওই দুটো পড়ুন।',
    art: '$_art/fpi.svg',
    lessonPoint: 0,
  ));
  static const needless = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/needless-order',
    textBn: 'যেখানে দরকার নেই সেখানে হুকুম — দল সময় হারায়, আসল ফল্ট পড়ে থাকে। সূত্র ধরে ঠিক জায়গায় ঠিক কাজ।',
    art: '$_art/info.svg',
    lessonPoint: 2,
  ));
  static const ropeClose = M5Mistake('5.2', DoMistake(
    key: 'm5/gate/rope-close',
    textBn: 'তারের গা ঘেঁষে দড়ি — এত কাছে ঘেরা মানে দল নিজেই বিপদের মধ্যে। তার এবং তার ছুঁয়ে থাকা বেড়া/গাছ/গাড়ির চারপাশে কমপক্ষে 10 মিটার দূরে ঘিরে দিন।',
    art: '$_art/wire.svg',
    lessonPoint: 2,
  ));
  static const handsBeforeFound = M5Mistake('5.2', DoMistake(
    key: 'm5/gate/hands-before-found',
    textBn: 'ফল্ট না খুঁজেই পোলে হাত — আগে মাটি থেকে বাইনোকুলারে খুঁজুন; পোলে না চড়েই অনেক ওপরের ক্ষতি দেখা যায়।',
    art: '$_art/earth.svg',
    lessonPoint: 1,
  ));
  static const cvMissed = M5Mistake('5.3', DoMistake(
    key: 'm5/gate/missed-knock-on',
    textBn: 'আরেকটা ক্ষতি চোখ এড়িয়ে গেল — একটা ফল্ট আরেকটার জন্ম দেয়। পুরো পোলের মাথা খুঁটিয়ে দেখুন।',
    art: '$_art/pole_top.svg',
    lessonPoint: 1,
  ));
  static const cvWrong = M5Mistake('5.3', DoMistake(
    key: 'm5/gate/wrong-remedy',
    textBn: 'ভালো জিনিসকে খারাপ বলা বা ভুল মেরামত — অপরাধীকে ঠিক চিনলে তবেই ঠিক সমাধান।',
    art: '$_art/pole_top.svg',
    lessonPoint: 3,
  ));
  static const verdictWrong = M5Mistake('5.4', DoMistake(
    key: 'm5/gate/wrong-verdict',
    textBn: 'রিপোর্টে ফল্টের ধরন ভুল — নিজে থেকে না সারলে (লক-আউট) স্থায়ী; ট্রিপ করে আবার চালু থাকলে অস্থায়ী।',
    art: '$_art/report.svg',
    lessonPoint: 2,
  ));
  static const repairOnly = M5Mistake('5.2', DoMistake(
    key: 'm5/gate/repair-only',
    textBn: 'একই জায়গায় বারবার ফল্ট — শুধু মেরামত করলে আবার হবে। সমস্যার মূল কারণ খুঁজে বের করুন।',
    art: '$_art/report.svg',
    lessonPoint: 0,
  ));
  static const clearEarly = M5Mistake('5.1', DoMistake(
    key: 'm5/gate/clear-early',
    textBn: 'মেরামতের আগেই লাইন ক্লিয়ার — লাইন ক্লিয়ার মানে কাজ শেষ, লাইন চালু করা যায়। ফল্ট সারিয়ে তবে লাইন ক্লিয়ার।',
    art: '$_art/clear.svg',
    lessonPoint: 1,
  ));
  static const ugTeamFirst = M5Mistake('5.9', DoMistake(
    key: 'm5/gate/ug-team-first',
    textBn: 'ধরন না জেনেই টিম ডাকা — ফিল্ডে যাওয়ার আগে মেগার আর মাল্টিমিটারে ফল্টের ধরন নির্ণয় করুন।',
    art: '$_art/cable.svg',
    lessonPoint: 1,
  ));
  static const ugGuessDig = M5Mistake('5.9', DoMistake(
    key: 'm5/gate/ug-guess-dig',
    textBn: 'আন্দাজে খোঁড়া — বিশেষ যন্ত্র ছাড়া ঠিক জায়গা পাওয়া প্রায় অসম্ভব; বিশেষজ্ঞ টিম থাম্পারে জায়গা বের করবে।',
    art: '$_art/dig.svg',
    lessonPoint: 2,
  ));
  static const ugSelfJoint = M5Mistake('5.9', DoMistake(
    key: 'm5/gate/ug-self-joint',
    textBn: 'নিজেরাই কেবিল জয়েন্ট — ইউজি জয়েন্টিং আলাদা প্রশিক্ষণ আর সার্টিফিকেশনের কাজ; বিশেষজ্ঞ টিমের অধীনে করুন।',
    art: '$_art/dig.svg',
    lessonPoint: 3,
  ));
  static const ugPegFirst = M5Mistake('5.9', DoMistake(
    key: 'm5/gate/ug-peg-first',
    textBn: 'ফোনের আগেই খুঁটি পোঁতা — খোঁড়ার আগে কেবিল রুট রেকর্ড দেখুন এবং অন্য ভূগর্ভস্থ লাইনের (টেলিফোন, জল, গ্যাস) মালিকদের জানান।',
    art: '$_art/dig.svg',
    lessonPoint: 2,
  ));
  static const coworkerWait = M5Mistake('5.7', DoMistake(
    key: 'm5/gate/wait-morning',
    textBn: 'ওর কথায় সকালের অপেক্ষা — স্পার্ক আর করোনা রাতেই সবচেয়ে ভালো দেখা যায়; বিদ্যুৎ ফেরানোও জরুরি।',
    art: '$_art/night_pair.svg',
    lessonPoint: 2,
  ));

  static const values = [
    handsNoPtw, climbNoEarth, chargeFault, chargeCrew, clearCrewUp, wireZone, climbLive, handsAfterClear, bamboo, meggerLive,
    patrolNoPtw, blindStart, blindPatrol, nightAlone, noFpiPair, needless, ropeClose, handsBeforeFound, cvMissed, cvWrong,
    verdictWrong, repairOnly, clearEarly, ugTeamFirst, ugGuessDig, ugSelfJoint, ugPegFirst, coworkerWait,
  ];

  static List<DoMistake> get all => [for (final x in values) x.m];

  /// The lesson that teaches [m] (for the mistakes book and পাঠে দেখুন).
  static String lessonOf(DoMistake m) => values.firstWhere((x) => x.m.key == m.key, orElse: () => const M5Mistake('5.10', DoMistake(key: '', textBn: '', art: ''))).lessonId;
}

// ============================================================================
// The deal
// ============================================================================

@immutable
class M5Deal {
  const M5Deal({
    required this.kase,
    required this.night,
    required this.k,
    required this.hasFpi,
    required this.customersClue,
    required this.repeats,
    required this.stormy,
    required this.villages,
    required this.wooded,
    required this.dtrs,
    required this.ugAt,
    required this.decoys,
    required this.damages,
    required this.culprit,
    required this.worn,
    required this.push,
    required this.menu,
    required this.orders,
    required this.ugSteps,
    required this.hour,
    required this.feederNo,
    required this.tries,
  });

  final M5Case kase;
  final bool night;

  /// The fault's section (0–3, from the substation).
  final int k;
  final bool hasFpi;

  /// A customer's call names the fault's village.
  final bool customersClue;

  /// The logbook shows repeats at the fault's village.
  final bool repeats;

  /// Case D: a storm (else a clear day).
  final bool stormy;
  final List<String> villages;
  final Set<int> wooded;
  final Set<int> dtrs;

  /// The section with the UG road crossing (on every map).
  final int ugAt;

  /// Section → a raw sight that is no fault.
  final Map<int, String> decoys;

  /// The pole top's damage (A–D): the culprit and 0–1 knock-on.
  final Map<M5Part, M5Damage> damages;
  final M5Damage? culprit;

  /// Sound parts drawn worn (look-alikes).
  final Set<M5Part> worn;
  final M5Push push;
  final List<M5Ask> menu;
  final List<M5Order> orders;
  final List<M5UgStep> ugSteps;
  final int hour;
  final int feederNo;
  final int tries;

  /// FPI i (between section i and i + 1) saw the fault current.
  bool fpiBright(int i) => k > i;

  /// The FPIs on either side of the fault's section.
  Set<int> get fpiPair => {if (k - 1 >= 0) k - 1, if (k <= 2) k};

  /// The close view has a knock-on (more than the culprit).
  bool get knockOn => damages.length > 1;

  M5MapPlan get plan => M5MapPlan(night: night, hasFpi: hasFpi, wooded: wooded, dtrs: dtrs, ugAt: ugAt);
}

/// Deals a case from lesson facts only; every play fresh.
M5Deal dealM5(math.Random rng) {
  final kase = M5Case.values[rng.nextInt(M5Case.values.length)];
  final night = kase == M5Case.night || rng.nextBool();
  final ugAt = rng.nextInt(4);
  final k = kase == M5Case.cable ? ugAt : rng.nextInt(4);
  var hasFpi = rng.nextBool();
  var customersClue = rng.nextBool();
  var repeats = rng.nextInt(3) == 0;
  // At least one clue names the fault's place (never conflicting).
  if (!hasFpi && !customersClue && !repeats) {
    switch (rng.nextInt(3)) {
      case 0:
        hasFpi = true;
      case 1:
        customersClue = true;
      default:
        repeats = true;
    }
  }
  final villages = ([...M5GateLines.villages]..shuffle(rng)).take(4).toList();
  final others = [for (var i = 0; i < 4; i++) if (i != k) i]..shuffle(rng);
  final wooded = kase == M5Case.storm ? {k, others.first} : {for (final i in others.take(1 + rng.nextInt(2))) i};
  final dtrs = {for (final i in ([0, 1, 2, 3]..shuffle(rng)).take(2)) i};
  final decoyPool = [...M5GateLines.decoys]..shuffle(rng);
  final decoyAt = ([...others]..shuffle(rng)).take(1 + rng.nextInt(2)).toList();
  final decoys = {for (var j = 0; j < decoyAt.length; j++) decoyAt[j]: decoyPool[j]};
  final ins = [M5Part.insL, M5Part.insM, M5Part.insR][rng.nextInt(3)];
  final half = rng.nextBool();
  final damages = <M5Part, M5Damage>{};
  M5Damage? culprit;
  switch (kase) {
    case M5Case.storm:
      // Branch or punctured insulator; the chain (both) in half the plays.
      final branchFirst = rng.nextBool();
      culprit = branchFirst ? M5Damage.branch : M5Damage.puncture;
      if (branchFirst || half) damages[M5Part.span] = M5Damage.branch;
      if (!branchFirst || half) damages[ins] = M5Damage.puncture;
    case M5Case.clear:
      if (rng.nextBool()) {
        culprit = M5Damage.bird;
        damages[M5Part.arm] = M5Damage.bird;
        if (half) damages[ins] = M5Damage.carbon;
      } else {
        culprit = M5Damage.melted;
        damages[M5Part.jumper] = M5Damage.melted;
        if (half) damages[M5Part.lead] = M5Damage.annealed;
      }
    case M5Case.wind:
      culprit = M5Damage.clash;
      damages[M5Part.span] = M5Damage.clash;
    case M5Case.fallen:
      culprit = M5Damage.broken;
      damages[M5Part.span] = M5Damage.broken;
      if (half) damages[M5Part.jumper] = M5Damage.melted;
    case M5Case.cable || M5Case.night:
      break;
  }
  final sound = [for (final p in M5Part.values) if (!damages.containsKey(p)) p]..shuffle(rng);
  final worn = kase.closeView ? {for (final p in sound.take(1 + rng.nextInt(2))) p} : <M5Part>{};
  final push = kase == M5Case.night
      ? M5Push.waitMorning
      : night
          ? (rng.nextBool() ? M5Push.chargeNight : M5Push.waitMorning)
          : M5Push.chargeDay;
  return M5Deal(
    kase: kase,
    night: night,
    k: k,
    hasFpi: hasFpi,
    customersClue: customersClue,
    repeats: repeats,
    stormy: rng.nextBool(),
    villages: villages,
    wooded: wooded,
    dtrs: dtrs,
    ugAt: ugAt,
    decoys: decoys,
    damages: damages,
    culprit: culprit,
    worn: worn,
    push: push,
    menu: [...M5Ask.values]..shuffle(rng),
    orders: [for (final o in M5Order.values) if (night || o != M5Order.lightsOff) o]..shuffle(rng),
    ugSteps: [...M5UgStep.values]..shuffle(rng),
    // The charge push says 'রাত দুটো' (and case F's intro too): the clock agrees.
    hour: kase == M5Case.night || push == M5Push.chargeNight ? 2 : (night ? 1 + rng.nextInt(2) : 1 + rng.nextInt(3)),
    feederNo: 2 + rng.nextInt(8),
    tries: 2 + rng.nextInt(2),
  );
}

// ============================================================================
// The run (pure rules)
// ============================================================================

/// What a move leads to (the page plays it out in this order).
@immutable
class M5Outcome {
  const M5Outcome({
    this.mistake,
    this.slipAfter = false,
    this.note,
    this.spot,
    this.before,
    this.reason,
    this.travel = false,
    this.firstReport = false,
    this.closeView = false,
    this.ug = false,
    this.verdict = false,
    this.lit = false,
    this.ptwSlip = false,
  });

  /// A deadly move (ends the play) or a slip.
  final DoMistake? mistake;

  /// The slip card comes after the report (a find without its readings).
  final bool slipAfter;

  /// The raw note written down (answer or report) and where it was seen.
  final String? note;
  final M5Spot? spot;

  /// ◆ before the crew goes (the hypothesis).
  final M5Reason? before;

  /// ◆ after the report.
  final M5Reason? reason;
  final bool travel;
  final bool firstReport;
  final bool closeView;
  final bool ug;
  final bool verdict;
  final bool lit;
  final bool ptwSlip;

  bool get deadly => mistake?.deadly ?? false;
}

class M5Run {
  M5Run(this.deal);
  final M5Deal deal;

  final asked = <M5Ask>{};
  var ptwIssued = false;
  var ptwOn = false;
  var dispatched = false;
  var patrolled = false;
  var reported = false;
  final fpiRead = <int>{};
  final peopleAt = <int>{};
  var located = false;
  var cordoned = false;
  final earthed = <int>{};
  var up = false;
  var earthAsked = false;
  var repaired = false;
  var verdictDone = false;
  var lineClear = false;
  var charged = false;
  var ugIsolated = false;
  var ugCrew = false;
  var ugMegger = false;
  var ugTeam = false;
  var ugOwners = false;
  var ugPeg = false;
  final cvTags = <M5Part>{};
  int cvWrongs = 0;
  var pairTagged = false;

  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// No slip all play (the quick bonus needs it too).
  bool quick = true;

  /// Story minutes since the call (asking and sending cost time).
  int minutes = 0;

  M5Case get kase => deal.kase;
  bool get done => kase == M5Case.night ? verdictDone : charged;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Someone is up a pole, an earth is on, or a crew is at the cable ends.
  bool get crewOnLine => up || earthed.isNotEmpty || ugCrew;

  /// The verdict sheet asks 'এবার কী?' (the logbook showed repeats).
  bool get asksRoot => deal.repeats && asked.contains(M5Ask.logbook);

  /// The sections the gathered clues point to (empty: none points anywhere).
  Set<int> supported() {
    var s = {0, 1, 2, 3};
    var any = false;
    void only(Set<int> t) {
      s = s.intersection(t);
      any = true;
    }

    if (asked.contains(M5Ask.customers) && deal.customersClue) only({deal.k});
    if (asked.contains(M5Ask.logbook) && deal.repeats) only({deal.k});
    if (peopleAt.contains(deal.k)) only({deal.k});
    for (final i in fpiRead) {
      only(deal.fpiBright(i) ? {for (var j = i + 1; j < 4; j++) j} : {for (var j = 0; j <= i; j++) j});
    }
    // Lesson 5.1, example 1: storm + earth fault → start where the trees are.
    if (kase == M5Case.storm && asked.contains(M5Ask.weather) && asked.contains(M5Ask.relay)) only(deal.wooded);
    return any ? s : <int>{};
  }

  M5Outcome _slip(M5Mistake x, {String? note, M5Spot? spot}) {
    slips++;
    quick = false;
    return M5Outcome(mistake: x.m, note: note, spot: spot);
  }

  M5Outcome _die(M5Mistake x) {
    deadly = x.m;
    return M5Outcome(mistake: x.m);
  }

  void tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  // --- the phone -------------------------------------------------------------
  M5Outcome ask(M5Ask a) {
    if (ended) return const M5Outcome();
    minutes += 5;
    if (m5InfoAsks.contains(a)) {
      asked.add(a);
      return M5Outcome(note: M5GateLines.answer(deal, a));
    }
    switch (a) {
      case M5Ask.ptw:
        if (!kase.lockOut) return M5Outcome(note: M5GateLines.answer(deal, a));
        if (ptwIssued) return const M5Outcome(note: M5GateLines.ptwAgain);
        ptwIssued = true;
        return M5Outcome(note: M5GateLines.answer(deal, a), ptwSlip: true);
      case M5Ask.lineClear:
        if (!kase.lockOut) return const M5Outcome(note: M5GateLines.liveAlready);
        if (lineClear) return const M5Outcome(note: M5GateLines.clearAgain);
        if (crewOnLine) return _die(M5GateMistakes.clearCrewUp);
        if (!repaired) return _slip(M5GateMistakes.clearEarly, note: M5GateLines.clearNotYet);
        lineClear = true;
        return M5Outcome(note: M5GateLines.answer(deal, a));
      case M5Ask.charge:
        if (!kase.lockOut) return const M5Outcome(note: M5GateLines.liveAlready);
        // Re-energizing a faulted line (R8), then a crew on it (R12).
        if (!repaired) return _die(M5GateMistakes.chargeFault);
        if (crewOnLine || !lineClear) return _die(M5GateMistakes.chargeCrew);
        charged = true;
        return M5Outcome(note: M5GateLines.answer(deal, a), lit: true, reason: M5Reason.lineClear);
      default:
        return const M5Outcome();
    }
  }

  /// The PTW slip goes on the clipboard.
  M5Outcome placePtw() {
    if (ended || !ptwIssued || ptwOn) return const M5Outcome();
    ptwOn = true;
    return const M5Outcome(reason: M5Reason.ptw);
  }

  /// Radio: everybody down, earths off.
  M5Outcome callDown() {
    if (ended) return const M5Outcome();
    if (!crewOnLine) return const M5Outcome(note: M5GateLines.allDown);
    up = false;
    earthed.clear();
    ugCrew = false;
    return const M5Outcome(note: M5GateLines.cameDown);
  }

  // --- the dispatch (one engine for every rule) ------------------------------
  M5Outcome dispatch(M5Chip chip, M5Spot spot, M5Order order) {
    if (ended) return const M5Outcome();
    minutes += 15;
    final s = spot.fpi ? null : spot.i;
    final hands = m5IsHands(order);
    final k = deal.k;
    // Deadly first (hands-on moves on the line — at a section or an FPI's pole).
    if (hands) {
      if (kase == M5Case.night) return _die(order == M5Order.bamboo ? M5GateMistakes.bamboo : M5GateMistakes.climbLive);
      if (!ptwOn) return _die(M5GateMistakes.handsNoPtw);
      // The PTW went back with the line clear: control may charge any moment.
      if (lineClear) return _die(M5GateMistakes.handsAfterClear);
      // Nothing can be earthed at an FPI's pole: a climb or a poke there is
      // never after a test and an earth (R2/R4, R20).
      if (spot.fpi && order == M5Order.climb) return _die(M5GateMistakes.climbNoEarth);
      if (spot.fpi && order == M5Order.bamboo) return _die(M5GateMistakes.bamboo);
    }
    if (hands && s != null) {
      if (kase == M5Case.fallen && s == k && !cordoned) return _die(M5GateMistakes.wireZone);
      if (order == M5Order.climb && !earthed.contains(s)) return _die(M5GateMistakes.climbNoEarth);
      if (order == M5Order.bamboo && !earthed.contains(s)) return _die(M5GateMistakes.bamboo);
    }
    final atWire = s != null && kase == M5Case.fallen && s == k;
    // At most one slip per order.
    M5Mistake? slip;
    if (deal.night && chip != M5Chip.van) {
      slip = M5GateMistakes.nightAlone;
    } else if (kase.lockOut && !ptwOn && !hands) {
      slip = M5GateMistakes.patrolNoPtw;
    } else if (!dispatched && asked.intersection(m5InfoAsks).isEmpty) {
      slip = M5GateMistakes.blindStart;
    } else if (m5IsPatrol(order) && !patrolled && s != null && !supported().contains(s)) {
      slip = M5GateMistakes.blindPatrol;
    } else if (hands && s != null && !located) {
      slip = M5GateMistakes.handsBeforeFound;
    } else if (hands && (s == null || s != k || order == M5Order.bamboo)) {
      // Found already, but not here (or a poke that tells nothing).
      slip = M5GateMistakes.needless;
    } else if (order == M5Order.rope) {
      // A cordon under 10 m (R16, ruling M5-4); anywhere else it is needless.
      slip = atWire ? M5GateMistakes.ropeClose : M5GateMistakes.needless;
    } else if (order == M5Order.cordon && !atWire) {
      slip = M5GateMistakes.needless;
    }
    final first = m5IsPatrol(order) && !patrolled && s != null;
    // A ring at the fallen wire comes back as a report too (it finds the wire).
    final ringsWire = atWire && (order == M5Order.cordon || order == M5Order.rope);
    final firstReport = !reported && (m5IsPatrol(order) || order == M5Order.fpi || (order == M5Order.look && spot.fpi) || ringsWire);
    if (firstReport) reported = true;
    dispatched = true;
    if (first) patrolled = true;
    if (deal.night && chip == M5Chip.van && slip == null) tag(M5GateLines.caughtPair);
    final wasLocated = located;
    final preSlip = slip;
    String note;
    M5Reason? reason;
    var closeView = false;
    if (spot.fpi) {
      if (order == M5Order.fpi || order == M5Order.look) {
        fpiRead.add(spot.i);
        note = deal.fpiBright(spot.i) ? M5GateLines.fpiBright : M5GateLines.fpiDark;
      } else {
        note = M5GateLines.onlyFpi;
      }
    } else {
      final i = s!;
      switch (order) {
        case M5Order.look:
          if (i == k && kase != M5Case.night) {
            located = true;
            note = M5GateLines.sighting(deal);
          } else {
            note = i == k ? M5GateLines.searchlightNothing : (deal.decoys[i] ?? M5GateLines.nothingSeen);
          }
        case M5Order.lightsOff:
          if (i == k && kase == M5Case.night) {
            located = true;
            note = M5GateLines.glow;
          } else {
            note = M5GateLines.nothingGlow;
          }
        case M5Order.people:
          if (i == k) peopleAt.add(k);
          note = i == k ? M5GateLines.people(deal) : M5GateLines.peopleNothing;
        case M5Order.fpi:
          note = M5GateLines.noFpiHere;
        case M5Order.cordon:
          // The far ring at the fallen wire is right whenever it comes (it
          // also finds the wire); a slip of its own costs only the ◆.
          if (atWire) {
            cordoned = true;
            located = true;
            if (slip == null) reason = M5Reason.cordon;
            note = M5GateLines.corded;
          } else {
            note = M5GateLines.nothingToCord;
          }
        case M5Order.rope:
          if (atWire) {
            located = true;
            note = M5GateLines.ropedNear;
          } else {
            note = M5GateLines.nothingToCord;
          }
        case M5Order.bamboo:
          note = M5GateLines.pokedNothing;
        case M5Order.earth:
          earthed.add(i);
          note = M5GateLines.earthed;
          if (slip == null && !earthAsked) {
            earthAsked = true;
            reason = M5Reason.earth;
          }
        case M5Order.climb:
          if (i == k && located && kase.closeView && !repaired) {
            up = true;
            closeView = true;
            note = M5GateLines.upTop;
          } else {
            note = kase == M5Case.cable && i == k ? M5GateLines.cableBelow : M5GateLines.nothingUp;
          }
      }
    }
    var slipAfter = false;
    var ug = false;
    var verdict = false;
    if (!wasLocated && located) {
      if (deal.hasFpi && !fpiRead.containsAll(deal.fpiPair)) {
        if (slip == null) {
          slip = M5GateMistakes.noFpiPair;
          slipAfter = true;
        }
      } else if (slip == null) {
        reason ??= M5Reason.locate;
      }
      ug = kase == M5Case.cable;
      verdict = kase == M5Case.night;
    }
    if (slip != null) {
      slips++;
      quick = false;
    }
    return M5Outcome(
      mistake: slip?.m,
      slipAfter: slipAfter,
      note: note,
      spot: spot,
      before: first && preSlip == null ? M5Reason.hypothesis : null,
      reason: reason,
      travel: true,
      firstReport: firstReport,
      closeView: closeView,
      ug: ug,
      verdict: verdict,
    );
  }

  // --- the close view --------------------------------------------------------
  M5Remedy remedyOf(M5Part p) => m5RemedyFor(deal.damages[p]);

  /// A remedy card picked for [p]: a wrong one counts against the next press.
  void cvPick(M5Part p, {required bool right}) {
    if (right) {
      cvTags.add(p);
    } else {
      cvWrongs++;
    }
  }

  /// 'হয়ে গেছে': at most one slip per press. Null = clean (repaired).
  DoMistake? cvDone() {
    final missed = deal.damages.keys.any((p) => !cvTags.contains(p));
    if (missed) {
      // Wrong picks so far carry over to the next press (one slip per press).
      slips++;
      quick = false;
      return M5GateMistakes.cvMissed.m;
    }
    final wrongs = cvWrongs;
    cvWrongs = 0;
    repaired = true;
    if (wrongs > 0) {
      slips++;
      quick = false;
      return M5GateMistakes.cvWrong.m;
    }
    return null;
  }

  // --- the UG case -------------------------------------------------------------
  M5Outcome ug(M5UgStep step) {
    if (ended) return const M5Outcome();
    minutes += 10;
    switch (step) {
      case M5UgStep.isolate:
        if (kase.lockOut && !ptwOn) return _die(M5GateMistakes.handsNoPtw);
        if (lineClear) return _die(M5GateMistakes.handsAfterClear);
        ugIsolated = true;
        ugCrew = true;
        return M5Outcome(note: M5GateLines.ugNote(step));
      case M5UgStep.megger:
        if (!ugIsolated) return _die(M5GateMistakes.meggerLive);
        final first = !ugMegger;
        ugMegger = true;
        return M5Outcome(note: M5GateLines.ugNote(step), reason: first ? M5Reason.megger : null);
      case M5UgStep.team:
        if (!ugMegger) return _slip(M5GateMistakes.ugTeamFirst);
        ugTeam = true;
        return M5Outcome(note: M5GateLines.ugNote(step));
      case M5UgStep.owners:
        final first = !ugOwners;
        ugOwners = true;
        return M5Outcome(note: M5GateLines.ugNote(step), reason: first ? M5Reason.dig : null);
      case M5UgStep.peg:
        if (!ugOwners) return _slip(M5GateMistakes.ugPegFirst);
        if (!ugTeam) return _slip(M5GateMistakes.ugGuessDig);
        ugPeg = true;
        repaired = true;
        return M5Outcome(note: M5GateLines.ugNote(step), verdict: true);
      case M5UgStep.guessDig:
        return _slip(M5GateMistakes.ugGuessDig);
      case M5UgStep.selfJoint:
        return _slip(M5GateMistakes.ugSelfJoint);
    }
  }

  // --- the report --------------------------------------------------------------
  M5Verdict get rightVerdict => kase == M5Case.night ? M5Verdict.transient : M5Verdict.permanent;

  /// The verdict sheet: null (and the ◆ question) when right.
  ({DoMistake? mistake, M5Reason? reason}) verdict(M5Verdict v, {bool? root}) {
    if (ended || verdictDone) return (mistake: null, reason: null);
    if (v != rightVerdict) {
      slips++;
      quick = false;
      return (mistake: M5GateMistakes.verdictWrong.m, reason: null);
    }
    if (asksRoot && root != true) {
      slips++;
      quick = false;
      return (mistake: M5GateMistakes.repairOnly.m, reason: null);
    }
    verdictDone = true;
    return (mistake: null, reason: asksRoot ? M5Reason.history : (v == M5Verdict.permanent ? M5Reason.permanent : M5Reason.transient));
  }

  /// Listening to the coworker: his push's class (R29).
  DoMistake listened() {
    if (deal.push == M5Push.waitMorning) {
      slips++;
      quick = false;
      return M5GateMistakes.coworkerWait.m;
    }
    deadly = M5GateMistakes.chargeFault.m;
    return deadly!;
  }
}

// ============================================================================
// Pack, probe
// ============================================================================

@immutable
class M5GateCasePack {
  const M5GateCasePack({required this.id, required this.titleBn, this.quickMs = 420000});
  final String id;
  final String titleBn;

  /// The quick bonus: a clean case inside this time (7 min).
  final int quickMs;
}

const m5GateCasePacks = {
  'gate_m5': M5GateCasePack(id: 'gate_m5', titleBn: M5GateLines.title),
};

/// Test hook: what the gate is doing now. Never used by the app.
class M5GateProbe {
  _M5RunPageState? _s;
  M5Deal? get deal => _s?._run.deal;
  M5Run? get run => _s?._run;

  /// intro, idle, phone, chip, slip, orders, send, call, travel, view, remedy,
  /// verdict, ug, card, freeze, done.
  String get phase => _s?._phase.name ?? 'none';

  /// The right cards of the deck now up (reason, remedy or coworker).
  List<String> get rightNow {
    final s = _s;
    if (s == null) return const [];
    if (s.coworkerChoiceUp) return s.coworkerScript.right;
    if (s.reasonOpen) return s._reasonRight;
    if (s._phase == _Phase.remedy) return s._remedyRight;
    return const [];
  }

  bool get coworkerUp => _s?.coworkerOpen ?? false;
  bool get busy => _s?.tableBusy ?? false;

  /// The level score now.
  int get score => _s?._runScore ?? 0;
}

// ============================================================================
// Page
// ============================================================================

class M5GateCasePage extends StatefulWidget {
  const M5GateCasePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M5GateCasePack pack;
  final bool muted;
  final int? seed;
  final M5GateProbe? probe;

  @override
  State<M5GateCasePage> createState() => _M5GateCasePageState();
}

class _M5GateCasePageState extends State<M5GateCasePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _M5RunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        probe: widget.probe,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _M5RunPage extends ConsumerStatefulWidget {
  const _M5RunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final M5GateCasePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M5GateProbe? probe;

  @override
  ConsumerState<_M5RunPage> createState() => _M5RunPageState();
}

enum _Phase { intro, idle, phone, chip, slip, orders, send, call, travel, view, remedy, verdict, ug, card, freeze, done }

/// A written note (answer or report).
@immutable
class _Note {
  const _Note(this.text, {this.radio = false, this.pin});
  final String text;
  final bool radio;
  final int? pin;
}

class _M5RunPageState extends ConsumerState<_M5RunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5Run _run = M5Run(dealM5(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// A crew on its way to a spot (0 → 1).
  late final AnimationController _travel = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  /// The villages lighting up after the charge (0 → 1).
  late final AnimationController _lit = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  /// A deadly move playing out in colour (0 → 1).
  late final AnimationController _harm = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  _Phase _phase = _Phase.intro;
  int _runScore = 0;
  int _chain = 0;
  final List<_Note> _notes = [];
  final Map<String, int> _pins = {};

  // The dispatch being given.
  M5Chip? _chipUp;
  M5Spot? _target;
  M5Order? _orderPicked;
  var _calling = false;
  M5Spot? _going;

  // The close view.
  M5Part? _partOpen;
  List<ChoiceOption> _remedyOpts = const [];
  final Set<String> _remedyWrong = {};
  String? _remedyPicked;
  List<String> _remedyRight = const [];

  // The verdict sheet.
  M5Verdict? _verdict;
  bool? _root;
  int _verdictN = 0;

  // The ◆ question now and what follows its proceed.
  M5Reason? _reasonNow;
  List<String> _reasonRight = const [];
  VoidCallback? _afterReason;

  // Cards.
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  String _cardLesson = '5.10';
  VoidCallback? _afterCard;
  var _freeze = false;
  Completer<void>? _frozen;
  Offset _harmAt = const Offset(180, 300);

  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  String _rankFrom = M5GateLines.rankFrom;
  String _rankTo = M5GateLines.rankTo;

  final _nudge = TaskNudge();
  int _nudgeN = 0;
  final _hints = IdleHintController();
  final Map<String, GlobalKey> _sheetKeys = {};
  final _sendKey = GlobalKey(debugLabel: 'm5-send');
  M5Geo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M5Deal get _deal => _run.deal;

  GlobalKey _sk(String id) => _sheetKeys.putIfAbsent(id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    widget.probe?._s = this;
    _travel.addStatusListener((s) {
      if (s == AnimationStatus.completed) _arrived();
    });
  }

  @override
  void dispose() {
    if (widget.probe?._s == this) widget.probe?._s = null;
    disposeCoworker();
    _travel.dispose();
    _lit.dispose();
    _harm.dispose();
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

  void _cue(String path, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(path, volume: volume, muted: false));
  }

  Offset _centre() {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  // --- the case ----------------------------------------------------------------
  void _start() {
    _clock.start();
    _rankNames();
    setState(() => _phase = _Phase.idle);
    unawaited(_sayChain([M5GateLines.taskIdle]));
  }

  void _rankNames() {
    List<CatalogModule> mods;
    try {
      mods = ref.read(contentCatalogProvider).value?.modules ?? const [];
    } catch (_) {
      mods = const [];
    }
    for (final m in mods) {
      if (m.id == 'm4' && m.rankName.isNotEmpty) _rankFrom = m.rankName;
      if (m.id == 'm5' && m.rankName.isNotEmpty) _rankTo = m.rankName;
    }
  }

  /// The tailgate takes a touch now (no sheet, card, deck or praise window).
  bool get _free => !_ended && _card == null && !tableBusy && !coworkerOpen && _afterCoworker == null;

  /// The dispatch the 'wait till morning' coworker holds up: he cuts in as the
  /// first patrol is sent, before the van leaves (nothing is found yet).
  VoidCallback? _afterCoworker;

  /// Where the case rests between moves: up the pole until repaired, the
  /// cable sheet while it is open, the report once due, else the tailgate.
  _Phase get _restPhase {
    final r = _run;
    if (r.kase.closeView && r.up && !r.repaired) return _Phase.view;
    if (r.kase == M5Case.cable && r.located && !r.ugPeg && _ugOpen) return _Phase.ug;
    if (!r.verdictDone && (r.kase == M5Case.night ? r.located : r.repaired)) return _Phase.verdict;
    return _Phase.idle;
  }

  void _toIdle() {
    if (!mounted || _ended) return;
    setState(() {
      _phase = _restPhase;
      _chipUp = null;
      _target = null;
      _orderPicked = null;
      _calling = false;
    });
  }

  void _note(String? text, {M5Spot? spot, bool radio = false}) {
    if (text == null || text.isEmpty) return;
    int? pin;
    if (spot != null) {
      pin = _pins[spot.id] ??= _pins.length + 1;
    }
    setState(() => _notes.insert(0, _Note(text, radio: radio, pin: pin)));
  }

  // --- tools -------------------------------------------------------------------
  void _tapPhone() {
    if (!_free || _phase == _Phase.travel || _phase == _Phase.view || _phase == _Phase.verdict || _phase == _Phase.ug) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.5);
    setState(() {
      _phase = _Phase.phone;
      _chipUp = null;
    });
    unawaited(_sayChain([M5GateLines.taskPhone]));
  }

  void _tapChip(M5Chip c) {
    if (!_free || !(_phase == _Phase.idle || _phase == _Phase.chip || _phase == _Phase.slip)) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.45);
    setState(() {
      _chipUp = _chipUp == c ? null : c;
      _phase = _chipUp == null ? _Phase.idle : _Phase.chip;
    });
    if (_chipUp != null) unawaited(_sayChain([M5GateLines.taskChip]));
  }

  void _tapRadio() {
    if (!_free || !(_phase == _Phase.idle || _phase == _Phase.chip)) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/dmm_beep.ogg', volume: 0.4);
    setState(() {
      _phase = _Phase.call;
      _chipUp = null;
    });
  }

  void _tapSlip() {
    if (!_free || !_run.ptwIssued || _run.ptwOn || !(_phase == _Phase.idle || _phase == _Phase.chip || _phase == _Phase.slip)) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    setState(() {
      _chipUp = null;
      _phase = _phase == _Phase.slip ? _Phase.idle : _Phase.slip;
    });
    if (_phase == _Phase.slip) unawaited(_sayChain([M5GateLines.taskSlip]));
  }

  void _tapClipboard() {
    if (_phase == _Phase.slip) {
      _placePtw();
      return;
    }
    _hints.missTap();
  }

  void _placePtw() {
    if (!_free || !_run.ptwIssued || _run.ptwOn) return;
    if (holdForCoworker()) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    final o = _run.placePtw();
    _toIdle();
    if (o.reason != null) _reason(o.reason!, then: _toIdle);
  }

  void _tapSpot(M5Spot spot) {
    if (_phase == _Phase.chip && _chipUp != null) {
      _dropChip(_chipUp!, spot);
      return;
    }
    _hints.missTap();
  }

  void _dropChip(M5Chip c, M5Spot spot) {
    if (!_free || !(_phase == _Phase.idle || _phase == _Phase.chip)) return;
    if (holdForCoworker()) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_select.ogg', volume: 0.6);
    setState(() {
      _chipUp = c;
      _target = spot;
      _orderPicked = null;
      _phase = _Phase.orders;
    });
    unawaited(_sayChain([M5GateLines.taskOrder]));
  }

  void _pickOrder(M5Order o) {
    if (_phase != _Phase.orders) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.5);
    setState(() {
      _orderPicked = o;
      _phase = _Phase.send;
    });
    unawaited(_sayChain([M5GateLines.taskSend]));
  }

  void _pickCall() {
    if (_phase != _Phase.call) return;
    HapticFeedback.selectionClick();
    setState(() {
      _calling = true;
      _phase = _Phase.send;
    });
    unawaited(_sayChain([M5GateLines.taskSend]));
  }

  void _cancelSheet() {
    HapticFeedback.selectionClick();
    _hush();
    _toIdle();
  }

  // --- the phone menu --------------------------------------------------------
  void _ask(M5Ask a) {
    if (_phase != _Phase.phone || _ended) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.6);
    _hush();
    final o = _run.ask(a);
    _toIdle();
    if (o.deadly) {
      unawaited(_deadly(o.mistake!, at: _mapCentre()));
      return;
    }
    _note(o.note);
    if (o.lit) {
      _cue('sounds/quiz_complete.ogg', volume: 0.6);
      if (_quiet) {
        _lit.value = 1;
      } else {
        unawaited(_lit.forward(from: 0));
      }
      unawaited(_sayChain([M5GateLines.lit], mood: GuideMood.glad));
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 1000), () {
        if (!mounted || _ended) return;
        _reason(o.reason!, then: () => unawaited(_finish()));
      }));
      return;
    }
    if (o.mistake != null) {
      unawaited(_slip(o.mistake!, then: _toIdle));
      return;
    }
  }

  // --- the radio: send ---------------------------------------------------------
  void _send() {
    if (_phase != _Phase.send || _ended) return;
    if (holdForCoworker()) return;
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/dmm_beep.ogg', volume: 0.55);
    _hush();
    if (_calling) {
      final o = _run.callDown();
      _toIdle();
      _note(o.note, radio: true);
      return;
    }
    final chip = _chipUp!;
    final spot = _target!;
    final order = _orderPicked!;
    // The map shows what is known: the crew's finding appears when they report.
    _held = _mapView;
    final firstPatrol = !_run.patrolled;
    final o = _run.dispatch(chip, spot, order);
    _toIdle();
    if (o.deadly) {
      unawaited(_deadly(o.mistake!, at: _spotCentre(spot)));
      return;
    }
    void go() => _go(spot, o);
    void afterSlip() => o.before != null ? _reason(o.before!, then: go) : go();
    void proceed() {
      if (!mounted || _ended) return;
      if (o.mistake != null && !o.slipAfter) {
        unawaited(_slip(o.mistake!, then: afterSlip));
      } else {
        afterSlip();
      }
    }

    // Lesson 5.7's myth comes as the first patrol is sent — never after a
    // report that already found the fault.
    if (firstPatrol && _run.patrolled && _deal.push == M5Push.waitMorning && !coworkerDone && !coworkerOpen) {
      _afterCoworker = proceed;
      scheduleCoworker();
      if (holdForCoworker()) return;
      _afterCoworker = null;
    }
    proceed();
  }

  M5Outcome? _pending;

  void _go(M5Spot spot, M5Outcome o) {
    if (!mounted || _ended) return;
    _pending = o;
    setState(() {
      _phase = _Phase.travel;
      _going = spot;
    });
    if (_quiet) {
      _travel.value = 1;
      _arrived();
    } else {
      _cue('sounds/van_arrive.ogg', volume: 0.3);
      unawaited(_travel.forward(from: 0));
    }
  }

  void _arrived() {
    final o = _pending;
    if (!mounted || _ended || o == null || _phase != _Phase.travel) return;
    _pending = null;
    setState(() {
      _going = null;
      _held = null;
    });
    _note(o.note, spot: o.spot, radio: true);
    _cue('sounds/learn/dmm_beep.ogg', volume: 0.45);
    // The first report is back: the coworker comes (once a play).
    // (The 'wait till morning' push comes at the first patrol's send instead.)
    if (o.firstReport && !coworkerDone && _deal.push != M5Push.waitMorning) scheduleCoworker();
    void open() => _open(o);
    if (o.mistake != null && o.slipAfter) {
      _toIdle();
      final r = o.reason;
      unawaited(_slip(o.mistake!, then: r == null ? open : () => _reason(r, then: open)));
    } else if (o.reason != null) {
      _toIdle();
      _reason(o.reason!, then: open);
    } else {
      open();
    }
  }

  void _open(M5Outcome o) {
    if (!mounted || _ended) return;
    if (o.closeView) {
      _toView();
    } else if (o.ug) {
      _openUg(tapped: false);
    } else if (o.verdict) {
      _toVerdict();
    } else {
      _toIdle();
    }
  }

  // --- the close view -----------------------------------------------------------
  void _toView() {
    setState(() {
      _phase = _Phase.view;
      _partOpen = null;
    });
    unawaited(_sayChain([M5GateLines.taskView]));
  }

  void _tapPart(M5Part p) {
    if (_phase != _Phase.view || !_free) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    if (_run.cvTags.contains(p)) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.5);
    final r = _run.remedyOf(p);
    setState(() {
      _partOpen = p;
      _remedyRight = M5GateLines.remedy(r);
      _remedyOpts = m5RemedyDeck(r, widget.rng);
      _remedyWrong.clear();
      _remedyPicked = null;
      _phase = _Phase.remedy;
    });
    unawaited(_sayChain([M5GateLines.taskRemedy]));
  }

  Future<void> _pickRemedy(ChoiceOption o) async {
    final p = _partOpen;
    if (_phase != _Phase.remedy || p == null || _remedyPicked != null || _remedyWrong.contains(o.textBn)) return;
    _hush();
    _run.cvPick(p, right: o.correct);
    if (!o.correct) {
      HapticFeedback.mediumImpact();
      _cue('sounds/quiz_wrong.ogg');
      setState(() => _remedyWrong.add(o.textBn));
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.7);
    setState(() => _remedyPicked = o.textBn);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted || _ended || _phase != _Phase.remedy) return;
    setState(() {
      _partOpen = null;
      _phase = _Phase.view;
    });
  }

  void _viewDone() {
    if (_phase != _Phase.view || !_free) return;
    if (holdForCoworker()) return;
    HapticFeedback.mediumImpact();
    final m = _run.cvDone();
    if (m != null) {
      unawaited(_slip(m, then: _run.repaired ? _toVerdict : _toView));
      return;
    }
    _cue('sounds/quiz_right.ogg', volume: 0.7);
    _reason(M5Reason.closeView, then: _toVerdict);
  }

  // --- the UG case ------------------------------------------------------------
  var _ugOpen = false;

  void _openUg({bool tapped = true}) {
    if (!mounted || _ended) return;
    if (tapped && holdForCoworker()) return;
    setState(() {
      _ugOpen = true;
      _phase = _Phase.ug;
      _chipUp = null;
    });
    unawaited(_sayChain([M5GateLines.taskUg]));
  }

  void _closeUg() {
    HapticFeedback.selectionClick();
    _hush();
    setState(() => _ugOpen = false);
    _toIdle();
  }

  void _ugStep(M5UgStep s) {
    if (_phase != _Phase.ug || !_free) return;
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.5);
    final o = _run.ug(s);
    if (o.deadly) {
      unawaited(_deadly(o.mistake!, at: _spotCentre(M5Spot.section(_deal.k))));
      return;
    }
    _note(o.note, radio: true);
    void back() {
      if (!mounted || _ended) return;
      if (o.verdict) {
        _toVerdict();
      } else {
        _toIdle();
      }
    }

    if (o.mistake != null) {
      unawaited(_slip(o.mistake!, then: back));
    } else if (o.reason != null) {
      _reason(o.reason!, then: back);
    } else {
      back();
    }
  }

  // --- the report --------------------------------------------------------------
  void _toVerdict() {
    if (!mounted || _ended) return;
    setState(() {
      _phase = _Phase.verdict;
      _verdict = null;
      _root = null;
      _verdictN++;
    });
    unawaited(_sayChain([M5GateLines.taskVerdict]));
  }

  void _submitVerdict() {
    final v = _verdict;
    if (_phase != _Phase.verdict || !_free || v == null || (_run.asksRoot && _root == null)) return;
    if (holdForCoworker()) return;
    HapticFeedback.mediumImpact();
    final r = _run.verdict(v, root: _root);
    if (r.mistake != null) {
      unawaited(_slip(r.mistake!, then: _toVerdict));
      return;
    }
    _verdict = null;
    _toIdle();
    _reason(r.reason!, then: _run.kase == M5Case.night ? () => unawaited(_finish()) : _toIdle);
  }

  // --- the shared success beat (ReasonTable) ----------------------------------
  void _reason(M5Reason r, {required VoidCallback then}) {
    if (!mounted || _ended) return;
    final fpi = _deal.hasFpi;
    _reasonNow = r;
    _afterReason = then;
    _reasonRight = M5GateLines.whyRight(r, fpi: fpi);
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(_reasonRight, M5GateLines.whyWrong(r), widget.rng),
      question: M5GateLines.question(r),
      stillValid: () => !_ended && _reasonNow == r,
    ));
  }

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
    final r = _reasonNow;
    if (r != null) _run.tag(M5GateLines.caught(r, fpi: _deal.hasFpi, knock: _deal.knockOn));
    _reasonNow = null;
    final then = _afterReason;
    _afterReason = null;
    then?.call();
  }

  // --- the shared pressure moment (CoworkerMoment) -------------------------------
  @override
  CoworkerScript get coworkerScript => M5GateLines.script(_deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    if (_card != null || tableBusy) return false;
    return switch (_phase) {
      _Phase.idle || _Phase.chip || _Phase.slip || _Phase.view || _Phase.verdict || _Phase.ug => true,
      _ => false,
    };
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listened();
      if (m.deadly) {
        // The operator charges the faulted line on his word.
        await _deadly(m, at: _spotCentre(M5Spot.section(_deal.k)));
        return;
      }
      // _slip takes the −10 itself.
      final resume = _afterCoworker;
      _afterCoworker = null;
      await _slip(m, then: resume ?? _toIdle);
      return;
    }
    _run.tag(_deal.push == M5Push.waitMorning ? M5GateLines.caughtNight : M5GateLines.caughtCharge);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    final chain = _chain;
    final resume = _afterCoworker;
    unawaited(() async {
      try {
        await coworkerSnarl();
        if (!mounted || chain != _chain || _ended) return;
        await _sayChain([M5GateLines.refused], mood: GuideMood.glad);
      } finally {
        // The van he tried to stop leaves now.
        if (resume != null && identical(_afterCoworker, resume)) {
          _afterCoworker = null;
          if (mounted && !_ended) resume();
        }
      }
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_phase == _Phase.intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5GateLines.tapWhy[_nudgeN++ % M5GateLines.tapWhy.length]
            : _nudge.next(switch (_phase) {
                _Phase.chip => M5GateLines.taskChip,
                _Phase.slip => M5GateLines.taskSlip,
                _Phase.orders => M5GateLines.taskOrder,
                _Phase.send || _Phase.call => M5GateLines.taskSend,
                _Phase.phone => M5GateLines.taskPhone,
                _Phase.view => M5GateLines.taskView,
                _Phase.remedy => M5GateLines.taskRemedy,
                _Phase.verdict => M5GateLines.taskVerdict,
                _Phase.ug => M5GateLines.taskUg,
                _ => M5GateLines.taskIdle,
              });
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes -----------------------------------------------------------------
  LevelContext _ctxFor(String lessonId) => LevelContext(
        rungId: widget.ctx.rungId,
        kind: widget.ctx.kind,
        lessonId: lessonId,
        lessonTitleBn: widget.ctx.lessonTitleBn,
        ladderStep: widget.ctx.ladderStep,
        doIndex: widget.ctx.doIndex,
        doCount: widget.ctx.doCount,
      );

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, _ctxFor(_cardLesson), m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() => _phase = _Phase.done);
  }

  /// A slip: −10, its card (or the strike-out); [then] after "বুঝেছি".
  Future<void> _slip(DoMistake m, {required VoidCallback then}) async {
    if (_ended) return;
    _cardLesson = M5GateMistakes.lessonOf(m);
    unawaited(_levelDelta(-10, _centre(), mood: GuideMood.warn));
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _phase = _Phase.card;
      _card = m;
      _cardTone = MistakeTone.slip;
      _afterCard = then;
    });
    unawaited(bookMistake(ref, _ctxFor(_cardLesson), m));
    final speak = await SpokenOnce.first('m5gate/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move plays out: the scene freezes grey and the consequence
  /// plays in colour at [at] (scene px); then near-miss or death.
  Future<void> _deadly(DoMistake m, {required Offset at}) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _cardLesson = M5GateMistakes.lessonOf(m);
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _phase = _Phase.freeze;
      _freeze = true;
      _harmAt = at;
    });
    if (_quiet) {
      _harm.value = 1;
    } else {
      unawaited(_harm.forward(from: 0));
    }
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m5gate/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5GateLines.deadlyWord : M5GateLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final then = _afterCard;
        _afterCard = null;
        setState(() => _card = null);
        if (then != null) {
          then();
        } else {
          _toIdle();
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
    setState(() => _phase = _Phase.done);
    final save = ref.read(gameSaveProvider.notifier);
    final centre = _centre();
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    final quick = _run.quick && _clock.elapsedMilliseconds <= widget.pack.quickMs;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      // The rank gate: স্কিলড → অ্যাডভান্সড (Module 5's rank; rulings M5-12).
      await save.unlockRank(5);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && quick) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: quick);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    if (_run.passed) _cue('sounds/quiz_complete.ogg', volume: 0.85);
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(_run.passed ? M5GateLines.promoted(_rankTo) : M5GateLines.fail, mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- geometry helpers ----------------------------------------------------------
  Offset _spotCentre(M5Spot s) {
    final g = _geo ?? const M5Geo(780, 0);
    return s.fpi ? g.fpiAt(s.i) : Offset(g.sectionX(s.i), g.lineY);
  }

  Offset _mapCentre() {
    final g = _geo ?? const M5Geo(780, 0);
    return g.map.center;
  }

  /// The map as it was when the crew left (until their report).
  M5MapView? _held;

  M5MapView get _mapView {
    final g = _geo ?? const M5Geo(780, 0);
    final going = _going;
    final held = _held;
    if (held != null) {
      return M5MapView(
        fpiSeen: held.fpiSeen,
        pins: held.pins,
        tokenFrom: going == null ? null : g.substation,
        tokenTo: going == null ? null : _spotCentre(going),
        tokenT: _travel.value,
        cordonAt: held.cordonAt,
        earthed: held.earthed,
        upAt: held.upAt,
        lit: held.lit,
      );
    }
    return M5MapView(
      fpiSeen: {for (final i in _run.fpiRead) i: _deal.fpiBright(i)},
      pins: Map.of(_pins),
      tokenFrom: going == null ? null : g.substation,
      tokenTo: going == null ? null : _spotCentre(going),
      tokenT: _travel.value,
      cordonAt: _run.cordoned ? _deal.k : null,
      earthed: Set.of(_run.earthed),
      upAt: _run.up ? _deal.k : null,
      lit: _lit.value,
    );
  }

  // --- the scene -------------------------------------------------------------------
  List<Widget> _scene(SceneMetrics m) {
    final g = _geo = M5Geo(m.height, m.inset);
    final viewing = _phase == _Phase.view || _phase == _Phase.remedy;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final world = viewing ? _poleTop(g) : _van(g);
    return [
      Positioned.fill(
        key: ValueKey(viewing ? 'world-view' : 'world-van'),
        child: ColorFiltered(colorFilter: grey, child: Stack(fit: StackFit.expand, children: world)),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('harm'),
          child: IgnorePointer(child: CustomPaint(painter: M5HarmPainter(at: _harmAt, k: _harm.value))),
        ),
    ];
  }

  List<Widget> _van(M5Geo g) {
    final d = _deal;
    final spotsLive = _phase == _Phase.chip;
    return [
      IgnorePointer(key: const ValueKey('backdrop'), child: RepaintBoundary(child: CustomPaint(painter: M5BackdropPainter(geo: g, night: d.night)))),
      IgnorePointer(key: const ValueKey('map'), child: CustomPaint(painter: M5MapPainter(geo: g, plan: d.plan, view: _mapView))),
      // Labels a worker reads on the map.
      Positioned(
        key: const ValueKey('map-title'),
        left: g.map.left + 20,
        top: g.map.top + 2,
        child: Text(enDigits('${M5GateLines.map} · ফিডার ${d.feederNo}'), style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF5A4636))),
      ),
      Positioned(
        key: const ValueKey('map-ss'),
        left: g.substation.dx - 30,
        width: 60,
        top: g.lineY + 16,
        child: Text(M5GateLines.substation, textAlign: TextAlign.center, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF3D4651))),
      ),
      for (var i = 0; i < M5Geo.sections; i++)
        Positioned(
          key: ValueKey('village-$i'),
          left: g.sectionX(i) - 38 + (i == d.ugAt ? 18 : 0),
          width: 76,
          top: g.villageAt(i).dy + 2,
          child: Text(d.villages[i], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF4A3B2C), height: 1.1)),
        ),
      // Where a chip can go: every section and FPI, all alike.
      for (var i = 0; i < M5Geo.sections; i++) _spotTarget(M5Spot.section(i), g.section(i), spotsLive),
      if (d.hasFpi)
        for (var i = 0; i < M5Geo.sections - 1; i++) _spotTarget(M5Spot.fpiAt(i), g.fpi(i), spotsLive),
      // The notes sheet.
      Positioned.fromRect(key: const ValueKey('notes'), rect: g.notes, child: IgnorePointer(child: _NotesSheet(notes: _notes, clock: _storyClock()))),
      // The tools on the tailgate.
      Positioned.fromRect(
        key: const ValueKey('tool-phone'),
        rect: g.phone,
        child: _Tool(key: const ValueKey('m5-tool-phone'), label: 'ফোন', onTap: _tapPhone, child: const _PhoneArt()),
      ),
      Positioned.fromRect(
        key: const ValueKey('tool-radio'),
        rect: g.radio,
        child: _Tool(key: const ValueKey('m5-tool-radio'), label: 'রেডিও', onTap: _tapRadio, child: const _RadioArt()),
      ),
      for (final c in M5Chip.values)
        Positioned.fromRect(
          key: ValueKey('chip-${c.name}'),
          rect: g.chip(c.index),
          child: _ChipToken(
            key: ValueKey('m5-chip-${c.name}'),
            chip: c,
            up: _chipUp == c && _phase == _Phase.chip,
            onTap: () => _tapChip(c),
            onDragStart: () {
              if (_free && (_phase == _Phase.idle || _phase == _Phase.chip) && !holdForCoworker()) {
                setState(() {
                  _chipUp = c;
                  _phase = _Phase.chip;
                });
              }
            },
          ),
        ),
      Positioned.fromRect(
        key: const ValueKey('tool-clip'),
        rect: g.clipboard,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (det) => det.data == 'ptw',
          onAcceptWithDetails: (_) => _placePtw(),
          builder: (context, _, _) => _Tool(
            key: const ValueKey('m5-clipboard'),
            label: 'ক্লিপবোর্ড',
            onTap: _tapClipboard,
            child: _ClipboardArt(ptw: _run.ptwOn && !_run.lineClear),
          ),
        ),
      ),
      if (_run.ptwIssued && !_run.ptwOn)
        Positioned.fromRect(
          key: const ValueKey('ptw-slip'),
          rect: g.slip,
          child: _SlipToken(key: const ValueKey('m5-ptw-slip'), up: _phase == _Phase.slip, onTap: _tapSlip, onDragStart: () {
            if (_free && _phase != _Phase.slip && !holdForCoworker()) setState(() => _phase = _Phase.slip);
          }),
        ),
    ];
  }

  Widget _spotTarget(M5Spot s, Rect r, bool live) => Positioned.fromRect(
        key: ValueKey('spot-${s.id}'),
        rect: r,
        child: DragTarget<M5Chip>(
          onAcceptWithDetails: (det) => _dropChip(det.data, s),
          builder: (context, cand, _) => GestureDetector(
            key: ValueKey('m5-spot-${s.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapSpot(s),
            child: Semantics(
              button: true,
              label: s.fpi ? enDigits('FPI ${s.i + 1}') : _deal.villages[s.i],
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // The same faint frame on every spot while a chip is up.
                  border: live || cand.isNotEmpty ? Border.all(color: const Color(0x667A5C2E), width: cand.isNotEmpty ? 2 : 1) : null,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      );

  List<Widget> _poleTop(M5Geo g) {
    final d = _deal;
    final looks = <int, M5Look>{
      for (final p in M5Part.values)
        p.index: switch (d.damages[p]) {
          M5Damage.branch => M5Look.branch,
          M5Damage.puncture => M5Look.puncture,
          M5Damage.carbon => M5Look.carbon,
          M5Damage.bird => M5Look.bird,
          M5Damage.melted => M5Look.melted,
          M5Damage.annealed => M5Look.annealed,
          M5Damage.clash => M5Look.clash,
          M5Damage.broken => M5Look.broken,
          null => d.worn.contains(p) ? M5Look.worn : M5Look.sound,
        },
    };
    return [
      // A tap on the sky or the pole (nothing there) counts as a miss.
      GestureDetector(key: const ValueKey('pole-sky'), behavior: HitTestBehavior.opaque, onTap: _hints.missTap, child: const SizedBox.expand()),
      IgnorePointer(
        key: const ValueKey('pole-top'),
        child: CustomPaint(painter: M5PoleTopPainter(geo: g, night: d.night, looks: looks, tagged: {for (final p in _run.cvTags) p.index})),
      ),
      for (final p in M5Part.values)
        Positioned.fromRect(
          key: ValueKey('part-${p.name}'),
          rect: g.part(p.index),
          child: GestureDetector(
            key: ValueKey('m5-part-${p.name}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapPart(p),
            child: const SizedBox.expand(),
          ),
        ),
    ];
  }

  String _storyClock() {
    final start = _deal.night ? _deal.hour * 60 : (12 + _deal.hour) * 60;
    final t = start + 4 + _run.minutes;
    final h = (t ~/ 60) % 24;
    final mm = t % 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return enDigits('${_deal.night ? 'রাত' : 'দিন'} $h12:${mm.toString().padLeft(2, '0')}');
  }

  /// How to touch now, never what.
  HintSpec? _hint() {
    final g = _geo;
    if (g == null) return null;
    switch (_phase) {
      case _Phase.chip:
        final c = _chipUp;
        if (c == null) return null;
        // A short nudge up from the chip (never toward a spot).
        return HintSpec.drag(g.chip(c.index).center, toward: const Offset(0, -1), travel: 56, space: HintSpace.scene);
      case _Phase.slip:
        return HintSpec.drag(g.slip.center, toward: const Offset(-1, -0.6), travel: 56, space: HintSpace.scene);
      case _Phase.view:
        return HintSpec.sweep([for (final p in M5Part.values) g.part(p.index)], space: HintSpace.scene);
      default:
        // The tailgate: an even sweep over the four tools, pressing none.
        return HintSpec.sweep(g.tools, space: HintSpace.scene);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final live = _phase != _Phase.intro && _mark == null && !struckOut && !_freeze;
    final scenePhase = _phase == _Phase.idle || _phase == _Phase.chip || _phase == _Phase.slip || _phase == _Phase.view;
    final waiting = live && scenePhase && _card == null && !coworkerOnScreen && !tableBusy;
    final deckUp = reasonOpen || coworkerChoiceUp || (_phase == _Phase.remedy && _remedyOpts.isNotEmpty);
    final sheetUp = live && !deckUp && _card == null && !coworkerOnScreen && !tableBusy;
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
            animation: Listenable.merge([_travel, _lit, _harm]),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_phase.name}-${_chipUp?.name}-${_run.cvTags.length}',
            hintController: _hints,
            hintAutoMiss: true,
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (_phase != _Phase.intro && _mark == null)
                Positioned(
                  key: const ValueKey('docket-chip'),
                  left: 12,
                  top: pad.top + 64,
                  child: IgnorePointer(child: _DocketChip(text: _docketLine(), clock: _storyClock())),
                ),
              if (_phase == _Phase.view && sheetUp)
                Positioned(
                  key: const ValueKey('view-done'),
                  left: 14,
                  bottom: pad.bottom + 16,
                  width: math.min(200.0, size.width * 0.5),
                  child: _BigButton(key: const ValueKey('m5-view-done'), label: M5GateLines.done, icon: Icons.check_rounded, onTap: _viewDone),
                ),
              if (sheetUp && _phase == _Phase.phone)
                _sheetAt(
                  'phone',
                  pad,
                  _MenuSheet(
                    title: M5GateLines.control,
                    icon: Icons.phone_in_talk_rounded,
                    items: [for (final a in _deal.menu) _Item('m5-ask-${a.name}', M5GateLines.ask(a), () => _ask(a))],
                    keyOf: _sk,
                    onClose: _cancelSheet,
                  ),
                ),
              if (sheetUp && _phase == _Phase.orders)
                _sheetAt(
                  'orders',
                  pad,
                  _MenuSheet(
                    title: '${M5GateLines.chip(_chipUp!)} → ${_spotName(_target!)}',
                    icon: Icons.settings_input_antenna_rounded,
                    items: [for (final o in _deal.orders) _Item('m5-order-${o.name}', M5GateLines.order(o, night: _deal.night), () => _pickOrder(o))],
                    keyOf: _sk,
                    onClose: _cancelSheet,
                  ),
                ),
              if (sheetUp && _phase == _Phase.call)
                _sheetAt(
                  'call',
                  pad,
                  _MenuSheet(
                    title: 'রেডিও',
                    icon: Icons.settings_input_antenna_rounded,
                    items: [_Item('m5-call-down', M5GateLines.callDown, _pickCall)],
                    keyOf: _sk,
                    onClose: _cancelSheet,
                  ),
                ),
              if (sheetUp && _phase == _Phase.send)
                _sheetAt(
                  'send',
                  pad,
                  _SendBar(
                    sendKey: _sendKey,
                    what: _calling ? M5GateLines.callDown : '${M5GateLines.chip(_chipUp!)} → ${_spotName(_target!)}: ${M5GateLines.order(_orderPicked!, night: _deal.night)}',
                    quiet: quiet,
                    onSend: _send,
                    onClose: _cancelSheet,
                  ),
                ),
              if (sheetUp && _phase == _Phase.ug)
                _sheetAt(
                  'ug',
                  pad,
                  _MenuSheet(
                    title: M5GateLines.ugTitle,
                    icon: Icons.cable_rounded,
                    items: [
                      for (final s in _deal.ugSteps)
                        _Item('m5-ug-${s.name}', M5GateLines.ug(s), () => _ugStep(s), done: switch (s) {
                          M5UgStep.isolate => _run.ugIsolated,
                          M5UgStep.megger => _run.ugMegger,
                          M5UgStep.team => _run.ugTeam,
                          M5UgStep.owners => _run.ugOwners,
                          _ => false,
                        }),
                    ],
                    keyOf: _sk,
                    onClose: _closeUg,
                  ),
                ),
              if (sheetUp && _phase == _Phase.idle && _run.kase == M5Case.cable && _run.located && !_run.ugPeg)
                Positioned(
                  key: const ValueKey('ug-reopen'),
                  right: 12,
                  top: pad.top + 64,
                  child: _SmallButton(key: const ValueKey('m5-ug-open'), label: M5GateLines.ugTitle, icon: Icons.cable_rounded, onTap: _openUg),
                ),
              if (sheetUp && _phase == _Phase.verdict)
                _sheetAt(
                  'verdict-$_verdictN',
                  pad,
                  _VerdictSheet(
                    verdict: _verdict,
                    root: _root,
                    asksRoot: _run.asksRoot,
                    keyOf: _sk,
                    onVerdict: (v) => setState(() => _verdict = v),
                    onRoot: (r) => setState(() => _root = r),
                    onSubmit: _submitVerdict,
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
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('remedy-deck-${_partOpen?.name}'),
                                options: _remedyOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _remedyWrong,
                                picked: _remedyPicked,
                                onPick: (o, _) => unawaited(_pickRemedy(o)),
                              ),
                  ),
                ),
              if (live && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 300 : (sheetUp && !scenePhase && _phase != _Phase.travel) ? 330 + _extraSheetRows * 86 : 6),
                  onLeft: coworkerFromRight,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
                          _hush();
                          unawaited(openLessonPoint(context, ref, lessonId: _cardLesson, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy!,
                  lessonId: _cardLesson,
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
              if (_phase == _Phase.intro) ...[
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M5GateLines.intro(_deal),
                  alarm: 'sounds/learn/card_deal_a.ogg',
                  muted: _muted,
                  onDone: _start,
                ),
                Positioned(
                  key: const ValueKey('intro-docket'),
                  left: 24,
                  right: 24,
                  top: pad.top + 66,
                  child: IgnorePointer(child: _DocketCard(line: _docketLine(), quiet: quiet)),
                ),
              ],
              if (_mark != null)
                Positioned.fill(
                  key: const ValueKey('result'),
                  child: ColoredBox(
                    color: const Color(0xB3050A16),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _run.passed
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _RankUp(from: _rankFrom, to: _rankTo, quiet: quiet),
                                  const SizedBox(height: 14),
                                  LevelPassPanel(
                                    mark: _mark!,
                                    levelScore: _runScore,
                                    totalDelta: _totalDelta,
                                    ms: _clock.elapsedMilliseconds,
                                    caughtBn: _run.caught,
                                    quickBonus: _quickBonus,
                                    stars: _stars,
                                    onNext: () => _popOnce(true),
                                    onRetry: () => widget.onRetry(_muted),
                                  ),
                                ],
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: _cardLesson, point: 0, muted: _muted)),
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

  String _docketLine() => enDigits('11 kV · ফিডার ${_deal.feederNo}');

  String _spotName(M5Spot s) => s.fpi ? enDigits('FPI ${s.i + 1}') : _deal.villages[s.i];

  /// Rows the sheet up now has beyond the phone menu's four (the night order
  /// sheet has five): the corner guide sits above them, never on a choice.
  int get _extraSheetRows => _phase == _Phase.orders ? math.max(0, (_deal.orders.length + 1) ~/ 2 - 4) : 0;

  Widget _sheetAt(String id, EdgeInsets pad, Widget child) => Positioned(
        key: ValueKey('sheet-$id'),
        left: 0,
        right: 0,
        bottom: 0,
        child: Padding(padding: EdgeInsets.only(bottom: pad.bottom), child: child),
      );
}

// ============================================================================
// Pieces
// ============================================================================

/// The notes sheet: every answer and report, written raw (newest on top).
class _NotesSheet extends StatelessWidget {
  const _NotesSheet({required this.notes, required this.clock});
  final List<_Note> notes;
  final String clock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB08A4A)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(M5GateLines.notes, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F), height: 1.2)),
                const Spacer(),
                Text(clock, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF5A4636), height: 1.2)),
              ],
            ),
            const SizedBox(height: 2),
            Expanded(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final n in notes.take(8))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 5),
                              child: n.pin != null
                                  ? Container(
                                      width: 14,
                                      height: 14,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(color: Color(0xFFB23A2E), shape: BoxShape.circle),
                                      child: Text('${n.pin}', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white)),
                                    )
                                  : Icon(n.radio ? Icons.settings_input_antenna_rounded : Icons.phone_rounded, size: 13, color: const Color(0xFF5A4636)),
                            ),
                            Expanded(
                              child: Text(enDigits(n.text), style: bangla(fontSize: 11.5, fontWeight: FontWeight.w700, color: SlmColors.ink, height: 1.25)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tool on the tailgate (one big touch target, ≥ 48 dp).
class _Tool extends StatelessWidget {
  const _Tool({super.key, required this.label, required this.onTap, required this.child});
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
    );
  }
}

class _PhoneArt extends StatelessWidget {
  const _PhoneArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2F3743), Color(0xFF161B22)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8A939E), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            height: 42,
            decoration: BoxDecoration(color: const Color(0xFF3E6E9E), borderRadius: BorderRadius.circular(4)),
            child: const Center(child: Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 22)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
              child: Column(
                children: [
                  for (var r = 0; r < 3; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var k = 0; k < 3; k++)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(color: const Color(0xFF59626E), borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioArt extends StatelessWidget {
  const _RadioArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B4250), Color(0xFF1E232B)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8A939E), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                for (var r = 0; r < 3; r++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var k = 0; k < 5; k++)
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(2.5),
                              child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF12161C), shape: BoxShape.circle)),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFF6E7884), shape: BoxShape.circle)),
              Container(width: 22, height: 10, decoration: BoxDecoration(color: const Color(0xFF7FE07A), borderRadius: BorderRadius.circular(2))),
              Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFF6E7884), shape: BoxShape.circle)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClipboardArt extends StatelessWidget {
  const _ClipboardArt({required this.ptw});
  final bool ptw;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF8B5E34),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF7F1E1), borderRadius: BorderRadius.circular(2)),
              padding: const EdgeInsets.all(5),
              child: ptw
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(M5GateLines.ptwSlip, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F), height: 1.1)),
                        const SizedBox(height: 4),
                        for (var i = 0; i < 4; i++)
                          Container(margin: const EdgeInsets.only(bottom: 4), height: 2, color: const Color(0x55000000)),
                        const Spacer(),
                        const Align(alignment: Alignment.bottomRight, child: Icon(Icons.draw_rounded, size: 14, color: Color(0xFF1E3A8A))),
                      ],
                    )
                  : Column(
                      children: [for (var i = 0; i < 5; i++) Container(margin: const EdgeInsets.only(bottom: 6, top: 2), height: 1.4, color: const Color(0x22000000))],
                    ),
            ),
          ),
          Positioned(
            top: -12,
            left: 14,
            right: 14,
            child: Container(height: 10, decoration: BoxDecoration(color: const Color(0xFFB8BEC6), borderRadius: BorderRadius.circular(3))),
          ),
        ],
      ),
    );
  }
}

class _ChipToken extends StatelessWidget {
  const _ChipToken({super.key, required this.chip, required this.up, required this.onTap, required this.onDragStart});
  final M5Chip chip;
  final bool up;
  final VoidCallback onTap;
  final VoidCallback onDragStart;

  Widget _face({bool lifted = false}) {
    return Container(
      decoration: BoxDecoration(
        color: lifted ? const Color(0xFFFFE08A) : const Color(0xFFF2B632),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lifted ? Colors.white : const Color(0xFF7A5200), width: lifted ? 2 : 1.2),
        boxShadow: [BoxShadow(color: const Color(0x88000000), blurRadius: lifted ? 10 : 4, offset: Offset(0, lifted ? 5 : 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(chip == M5Chip.van ? Icons.airport_shuttle_rounded : Icons.engineering_rounded, size: 16, color: const Color(0xFF3A2500)),
          Text(M5GateLines.chip(chip), style: bangla(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2500), height: 1.1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M5GateLines.chip(chip),
      child: Draggable<M5Chip>(
        data: chip,
        onDragStarted: onDragStart,
        feedback: SizedBox(width: 40, height: 42, child: Material(type: MaterialType.transparency, child: _face(lifted: true))),
        childWhenDragging: Opacity(opacity: 0.35, child: _face()),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedSlide(
            offset: Offset(0, up ? -0.18 : 0),
            duration: const Duration(milliseconds: 160),
            child: _face(lifted: up),
          ),
        ),
      ),
    );
  }
}

class _SlipToken extends StatelessWidget {
  const _SlipToken({super.key, required this.up, required this.onTap, required this.onDragStart});
  final bool up;
  final VoidCallback onTap;
  final VoidCallback onDragStart;

  Widget _face({bool lifted = false}) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEF),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: lifted ? const Color(0xFF1E88E5) : const Color(0xFFB08A4A), width: lifted ? 2 : 1),
          boxShadow: [BoxShadow(color: const Color(0x88000000), blurRadius: lifted ? 10 : 4, offset: const Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: Text(M5GateLines.ptwSlip, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F), height: 1.1)),
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M5GateLines.ptwSlip,
      child: Draggable<String>(
        data: 'ptw',
        onDragStarted: onDragStart,
        feedback: SizedBox(width: 64, height: 28, child: Material(type: MaterialType.transparency, child: _face(lifted: true))),
        childWhenDragging: const SizedBox.shrink(),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: _face(lifted: up)),
      ),
    );
  }
}

@immutable
class _Item {
  const _Item(this.id, this.label, this.onTap, {this.done = false});
  final String id;
  final String label;
  final VoidCallback onTap;
  final bool done;
}

/// A sheet of choices, all alike (2 across); the hint sweeps over all.
class _MenuSheet extends StatelessWidget {
  const _MenuSheet({required this.title, required this.icon, required this.items, required this.keyOf, this.onClose});
  final String title;
  final IconData icon;
  final List<_Item> items;
  final GlobalKey Function(String id) keyOf;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final ids = [for (final i in items) i.id].join('|');
    return IdleHint(
      waiting: items.length > 1,
      waitKey: ids,
      spec: (_) => items.length < 2 ? null : HintSpec.sweepOver([for (final i in items) keyOf(i.id)]),
      child: _SheetFrame(
        title: title,
        icon: icon,
        onClose: onClose,
        child: LayoutBuilder(
          builder: (context, box) {
            final cols = items.length == 1 ? 1 : 2;
            final w = (box.maxWidth - 8 * (cols - 1)) / cols;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final it in items)
                  SizedBox(
                    key: keyOf(it.id),
                    width: w,
                    child: Material(
                      color: it.done ? const Color(0xFF1F3B2C) : const Color(0xFF1B2A44),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: ValueKey(it.id),
                        borderRadius: BorderRadius.circular(12),
                        onTap: it.onTap,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              if (it.done) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_rounded, size: 16, color: SlmColors.emerald300)),
                              Expanded(
                                child: Text(
                                  enDigits(it.label),
                                  style: bangla(fontSize: 13.5, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.25),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.icon, required this.child, this.onClose});
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SlmColors.navy900.withValues(alpha: 0.96), SlmColors.navy950.withValues(alpha: 0.99)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.45), width: 1.4)),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: SlmColors.gold300),
              const SizedBox(width: 8),
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.gold200, height: 1.2))),
              if (onClose != null)
                Semantics(
                  button: true,
                  label: M5GateLines.close,
                  child: InkWell(
                    key: const ValueKey('m5-sheet-close'),
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(24),
                    child: const SizedBox(width: 48, height: 40, child: Icon(Icons.close_rounded, color: SlmColors.ivory, size: 22)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// The radio: the order, then press and hold to send it.
class _SendBar extends StatefulWidget {
  const _SendBar({required this.sendKey, required this.what, required this.quiet, required this.onSend, required this.onClose});
  final GlobalKey sendKey;
  final String what;
  final bool quiet;
  final VoidCallback onSend;
  final VoidCallback onClose;

  @override
  State<_SendBar> createState() => _SendBarState();
}

class _SendBarState extends State<_SendBar> with SingleTickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(vsync: this, duration: kLongPressTimeout);

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IdleHint(
      waiting: true,
      waitKey: widget.what,
      // The one way forward: press and hold the radio button.
      spec: (_) => HintSpec.holdOn(widget.sendKey),
      child: _SheetFrame(
        title: 'রেডিও',
        icon: Icons.settings_input_antenna_rounded,
        onClose: widget.onClose,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(enDigits(widget.what), style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.3)),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: M5GateLines.send,
              child: GestureDetector(
                key: widget.sendKey,
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) {
                  if (!widget.quiet) unawaited(_fill.forward(from: 0));
                },
                onTapUp: (_) => _fill.reverse(),
                onTapCancel: () => _fill.reverse(),
                onLongPress: () {
                  _fill.value = 1;
                  widget.onSend();
                },
                child: Container(
                  key: const ValueKey('m5-send'),
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _fill,
                          builder: (_, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _fill.value,
                            child: DecoratedBox(decoration: BoxDecoration(color: const Color(0x55FFFFFF), borderRadius: BorderRadius.circular(14))),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(M5GateLines.send, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                    ],
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

/// The report: স্থায়ী / অস্থায়ী (+ 'এবার কী?'), then জমা দিন (never hinted).
class _VerdictSheet extends StatelessWidget {
  const _VerdictSheet({
    required this.verdict,
    required this.root,
    required this.asksRoot,
    required this.keyOf,
    required this.onVerdict,
    required this.onRoot,
    required this.onSubmit,
  });
  final M5Verdict? verdict;
  final bool? root;
  final bool asksRoot;
  final GlobalKey Function(String id) keyOf;
  final ValueChanged<M5Verdict> onVerdict;
  final ValueChanged<bool> onRoot;
  final VoidCallback onSubmit;

  Widget _pill(String id, String label, bool on, VoidCallback onTap) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            key: keyOf(id),
            color: on ? SlmColors.gold400 : const Color(0xFF1B2A44),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: ValueKey(id),
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.5))),
                child: Text(label, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: on ? SlmColors.navy950 : SlmColors.ivory, height: 1.2)),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ready = verdict != null && (!asksRoot || root != null);
    final pills = ['m5-verdict-permanent', 'm5-verdict-transient', if (asksRoot) ...['m5-root-yes', 'm5-root-no']];
    return IdleHint(
      waiting: !ready,
      waitKey: 'verdict-${verdict?.name}-$root',
      spec: (_) => HintSpec.sweepOver([for (final p in pills) keyOf(p)]),
      child: _SheetFrame(
        title: M5GateLines.report,
        icon: Icons.assignment_turned_in_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              _pill('m5-verdict-permanent', M5GateLines.permanent, verdict == M5Verdict.permanent, () => onVerdict(M5Verdict.permanent)),
              _pill('m5-verdict-transient', M5GateLines.transient, verdict == M5Verdict.transient, () => onVerdict(M5Verdict.transient)),
            ]),
            if (asksRoot) ...[
              const SizedBox(height: 10),
              Text(M5GateLines.whatNext, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold200, height: 1.2)),
              const SizedBox(height: 6),
              Row(children: [
                _pill('m5-root-yes', M5GateLines.rootCause, root == true, () => onRoot(true)),
                _pill('m5-root-no', M5GateLines.repairOnly, root == false, () => onRoot(false)),
              ]),
            ],
            const SizedBox(height: 12),
            Opacity(
              opacity: ready ? 1 : 0.45,
              child: _BigButton(key: const ValueKey('m5-verdict-submit'), label: M5GateLines.submit, icon: Icons.send_rounded, onTap: ready ? onSubmit : null),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: SlmColors.emerald500,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: SlmColors.navy950, size: 20),
                const SizedBox(width: 8),
                Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.navy950)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: const Color(0xFF1B2A44),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.6))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: SlmColors.gold300),
                const SizedBox(width: 6),
                Text(label, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The docket on the intro (the call).
class _DocketCard extends StatelessWidget {
  const _DocketCard({required this.line, required this.quiet});
  final String line;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.rotate(
        angle: -0.03 * t,
        child: Transform.translate(offset: Offset(0, -40 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB08A4A), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment_rounded, color: Color(0xFF7A1F1F), size: 22),
            const SizedBox(width: 8),
            Text(M5GateLines.docket, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F))),
            const SizedBox(width: 12),
            Expanded(child: Text(line, style: bangla(fontSize: 16, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.3))),
          ],
        ),
      ),
    );
  }
}

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text, required this.clock});
  final String text;
  final String clock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFBEF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB08A4A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_rounded, color: Color(0xFF7A1F1F), size: 15),
          const SizedBox(width: 5),
          Text('$text · $clock', style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.2)),
        ],
      ),
    );
  }
}

/// The rank-up: স্কিলড → অ্যাডভান্সড, with the module's badge.
class _RankUp extends StatelessWidget {
  const _RankUp({required this.from, required this.to, required this.quiet});
  final String from;
  final String to;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: 0.7 + 0.3 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2B1D05), Color(0xFF4A3208)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SlmColors.gold300, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x88F2B632), blurRadius: 18)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(M5GateLines.rankUp, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.gold200)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    from,
                    style: bangla(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xAAFFFFFF)).copyWith(decoration: TextDecoration.lineThrough),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.arrow_forward_rounded, color: SlmColors.gold300, size: 24)),
                const Icon(Icons.military_tech_rounded, color: SlmColors.gold300, size: 30),
                const SizedBox(width: 4),
                Flexible(child: Text(to, style: bangla(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))),
              ],
            ),
            const SizedBox(height: 6),
            Text(M5GateLines.badge, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
          ],
        ),
      ),
    );
  }
}
