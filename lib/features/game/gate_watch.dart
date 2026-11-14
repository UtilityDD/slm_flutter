import 'dart:async';
import 'dart:math' as math;

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
import 'gate_watch_world.dart';
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'pole_read.dart' show PolePainter;
import 'pole_yard.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';
import 'van_yard.dart';

// Module 1 rank gate (ladder step 30, rung m1/gate, pack gate_m1): "প্রথম
// ডকেট" — a hazard-spotting gate (owner-approved concept, 2026-11-10).
//
// The trainee's first real docket. A crew does the whole job in one drawn
// scene — dressing beside the van, the long tool, the permit at pole 17, the
// rod, the harness, the pole check, the discharge, the anchor, the sky, a
// roadside fire, the line clear — and the player is the safety watcher with
// stop-work authority (lesson 1.9: Stop Work is your right). Nothing tells him
// where to look: this tests SEEING danger, the right exam for a rank-up.
//
// 1. GuideIntro with the dealt docket card (no start button, no skip).
// 2. 10–12 short moments dealt fresh from a library of 38 (24 mistakes from
//    lessons 1.1–1.9 + 14 done right), in the job's order; about half have a
//    mistake, at least 2 of the deadly class, mistakes from 4+ lessons.
// 3. A big "থামান!" button is there while a moment plays. A stop freezes the
//    scene; the player taps WHERE (a zone per moment), the lens shows it close
//    (inspect), "কী ভুল?" (1 right + 2 wrong) → "এখন কী করবেন?" on the ◆
//    table (ReasonTable: the right fix pays, a wrong one burns it) → the crew
//    redoes it right → the job goes on.
// 4. Missed slip-class mistake → its card (a slip). Missed deadly-class
//    mistake → it plays out: freeze grey, the consequence in colour, then
//    near-miss / death (DoDeathGuard; one life). A stop on a moment done right
//    → "সব তো ঠিক ছিল!" (a slip). 3 slips → StruckOutCard.
// 5. Once a play, on a mistake moment once the mistake is in view, the
//    careless coworker (level 1's rival, his recorded voice) says "থামিও না,
//    দেরি হয়ে যাচ্ছে!"; listening = the slip (that mistake's card, even for a
//    deadly-class one). The থামান button waits for him (holdForCoworker).
// 6. Pass: rank-up ট্রেইনি → জুনিয়র (catalog rankName of m1 → m2), stars, "আজ
//    যা ধরলেন". Scoring as the module's levels: ◆ 15 (10 after a wrong tap or a
//    wrong "কী ভুল?") on the table, coworker refused +10, slip −10, pass +20,
//    quick bonus +10 (every catch stopped soon after its cue, no slips).
//
// Deadly vs slip: the Module 1 owner-approved lists (MODULE1_LADDER.md,
// memory 2026-11-08). Voice: the guide by device TTS (GateLines); the coworker
// in his recorded voice (clip r_feab595cb8). Art: the world in
// gate_watch_world.dart; mistake pictures in assets/game/art/gate/.

// ============================================================================
// Content
// ============================================================================

extension GateFaultFacts on GateFault {
  /// The lesson that teaches it (1.1–1.9) and its 0-based point.
  String get lessonId => switch (slot) {
        GateSlot.helmet || GateSlot.shirt || GateSlot.boots || GateSlot.gloves => '1.1',
        GateSlot.kite => '1.2',
        GateSlot.poleCheck => '1.3',
        GateSlot.harness || GateSlot.anchor => '1.4',
        GateSlot.rod || GateSlot.discharge => '1.5',
        GateSlot.permit || GateSlot.clear => '1.6',
        GateSlot.fire => '1.8',
        GateSlot.sky => '1.9',
      };

  /// Deadly class (Module 1's owner-approved lists); the rest are slips.
  bool get deadly => switch (this) {
        GateFault.vented || GateFault.strapOpen || GateFault.sleeves || GateFault.chestHigh || GateFault.skipCheck || GateFault.hive || GateFault.keptPermit => false,
        _ => true,
      };

  DoMistake get mistake => GateMistakes.of(this);
  List<String> get what => GateLines.what(this);
  List<String> get fix => GateLines.fix(this);
}

/// The faults a moment of [slot] can carry.
List<GateFault> gateFaultsOf(GateSlot slot) => [for (final f in GateFault.values) if (f.slot == slot) f];

abstract final class GateLines {
  static const title = 'প্রথম ডকেট';
  static const intro = 'আজ দল কাজ করবে, আপনি নজর রাখবেন — ভুল দেখলেই থামান!';

  // The tasks (the corner guide repeats the current one, a new way each tap).
  static const watch = 'নজর রাখুন — ভুল দেখলেই থামান।';
  static const where = 'কোথায় ভুল? ছুঁয়ে দেখান।';
  static const askWhat = 'কী ভুল?';
  static const askFix = 'এখন কী করবেন?';
  static const tasks = [watch, where, askWhat, askFix];
  static const tapWhy = ['ঠিক কাজটা কোনটা?', 'দল এখন কী করবে, বেছে নিন।'];
  static const notHere = ['এখানে নয় — আবার দেখুন।', 'ওখানে তো ঠিক আছে। আর কোথায়?', 'আরেকবার ভালো করে দেখুন।'];
  static const notThis = 'না, এটা নয় — ছবিটা আবার দেখুন।';
  static const redo = 'দল এবার ঠিকভাবে করছে।';

  // Labels a worker reads (the button, the docket).
  static const stop = 'থামান!';
  static const docket = 'ডকেট';
  static const crewLead = 'দলনেতা';
  static const allFine = 'সব তো ঠিক ছিল!';
  static const jobs = ['জাম্পার পুড়ে গেছে', 'জাম্পার আলগা হয়ে গেছে'];
  static const feeders = ['রামপুর', 'হাটখোলা', 'নদীপাড়', 'স্টেশন রোড', 'কলেজপাড়া', 'বাজার'];
  static String feederName(String f) => '$f ফিডার';
  static String docketLine(GateDocket d) => enDigits('${d.kv} kV · ${feederName(d.feeder)} · পোল ${d.poleNo}');

  // The ranks (fallbacks when the catalog is not loaded).
  static const rankFrom = 'ট্রেইনি';
  static const rankTo = 'জুনিয়র';
  static const rankUp = 'র‍্যাঙ্ক বেড়েছে!';
  static String promoted(String rank) => 'অভিনন্দন! আপনি এখন $rank লাইনম্যান — চোখ খোলা রাখবেন।';
  static const fail = 'আরেকবার — চোখ খোলা রাখুন, ভুল দেখলেই থামান।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const callHeld = 'ঠিক! থামানোর অধিকার আপনার।';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const momentLabel = 'কাজ';

  // "কী ভুল?" — what a watcher saw (every card 28–36 letters).
  static List<String> what(GateFault f) => switch (f) {
        GateFault.vented => const ['হেলমেটে বাতাসের ফুটো, লাইনে চলে না', 'ফুটোওয়ালা ভেন্টেড হেলমেট পরেছে'],
        GateFault.strapOpen => const ['থুতনির ফিতে খোলা, হেলমেট খসে পড়বে', 'চিন স্ট্র্যাপ না বেঁধেই এগোচ্ছে'],
        GateFault.polyester => const ['সিন্থেটিক গেঞ্জি, ফ্ল্যাশে গলে যাবে', 'পলিয়েস্টারের জার্সি পরে কাজে নামছে'],
        GateFault.sleeves => const ['জামার হাতা গুটিয়ে রেখেছে, হাত খোলা', 'হাতা গোটানো, ফ্ল্যাশে হাত পুড়বে'],
        GateFault.nail => const ['জুতোর সোলে একটা পেরেক গেঁথে আছে', 'সোলে পেরেক, কারেন্ট মাটিতে নামবে'],
        GateFault.pinhole => const ['এয়ার টেস্টে গ্লাভসে হাওয়া বেরোচ্ছে', 'গ্লাভসে সূক্ষ্ম ফুটো, হাওয়া লিক'],
        GateFault.cotton => const ['সুতির গ্লাভস পরেছে, শক আটকাবে না', 'রাবার নয়, কাপড়ের গ্লাভস হাতে'],
        GateFault.bamboo => const ['লাইভ লাইনের কাছে বাঁশের লাঠি তুলেছে', 'শুকনো বাঁশ ভেবে লাইনের কাছে নিচ্ছে'],
        GateFault.pvcHook => const ['পিভিসি পাইপে লোহার হুক দিয়ে টানছে', 'জুগাড়ের পাইপ লাইনের কাছে তুলেছে'],
        GateFault.phonePermit => const ['ফোনের কথায় কাজ শুরু, পারমিট নেই', 'হাতে লিখিত পারমিট ছাড়াই শুরু করছে'],
        GateFault.wrongFeeder => const ['পারমিটের ফিডার আর পোলের ফিডার আলাদা', 'অন্য ফিডারের পারমিটে কাজ শুরু'],
        GateFault.wrongRating => const ['33 kV লাইনে 11 kV-র রড নিচ্ছে', 'রডের রেটিং ডকেটের ভোল্টেজের কম'],
        GateFault.jugaadRod => const ['পাইপ কেটে বানানো জুগাড় ডিসচার্জ রড', 'স্টোরের রড নয়, জুগাড় রড হাতে'],
        GateFault.waistBelt => const ['হারনেস নয়, শুধু কোমরের বেল্ট পরেছে', 'কোমর-রশা দিয়েই পোলে উঠতে চলেছে'],
        GateFault.chestHigh => const ['বুকের ফিতে গলার কাছে উঠে আছে', 'চেস্ট স্ট্র্যাপ বুকের মাঝে নেই'],
        GateFault.skipCheck => const ['পোল না ঘুরে, না ঠুকে উঠে পড়ল', 'চারপাশ না দেখেই পোলে উঠে গেল'],
        GateFault.hollow => const ['ঠুকতেই দপ্ দপ্, পোল ভেতরে ফাঁপা', 'ফাঁপা শব্দ শুনেও পোলে উঠে যাচ্ছে'],
        GateFault.hive => const ['ক্রস-আর্মের নিচে মৌমাছির চাক', 'পোলে মৌমাছির চাক, তবু উঠে যাচ্ছে'],
        GateFault.lineFirst => const ['আগে লাইনে হুক, মাটিতে ক্ল্যাম্প পরে', 'আর্থ না করেই রড লাইনে ছোঁয়াল'],
        GateFault.skipDischarge => const ['ডিসচার্জ না করেই পোলে উঠে গেল', 'রড মাটিতে পড়ে, ডিসচার্জ হলো না'],
        GateFault.brokenArm => const ['ভাঙা ক্রস-আর্মে ল্যানিয়ার্ড আটকাল', 'নড়বড়ে ক্রস-আর্মকে অ্যাঙ্কর করেছে'],
        GateFault.lightning => const ['বাজ পড়ছে, তবু পোলের ওপরে কাজ', 'বাজের শব্দ শুনেও পোল থেকে নামছে না'],
        GateFault.waterFire => const ['বৈদ্যুতিক আগুনে বালতির জল ছুঁড়ছে', 'জল দিয়ে কারেন্টের আগুন নেভাচ্ছে'],
        GateFault.keptPermit => const ['পারমিট ফেরত না দিয়েই চলে যাচ্ছে', 'লাইন ক্লিয়ার না করে পারমিট পকেটে'],
      };

  // "এখন কী করবেন?" — the fix (every card 28–36 letters).
  static List<String> fix(GateFault f) => switch (f) {
        GateFault.vented => const ['ফুটোহীন লাইনের হেলমেট এনে পরুক', 'নন-ভেন্টেড ISI হেলমেট বদলে নিক'],
        GateFault.strapOpen => const ['চিন স্ট্র্যাপ বেঁধে লক করে তবে এগোক', 'থুতনির ফিতে বেঁধে লক দেখে নিক'],
        GateFault.polyester => const ['ফুল হাতা সুতির জামা পরে তবে আসুক', 'গেঞ্জি খুলে সুতির কাজের জামা পরুক'],
        GateFault.sleeves => const ['হাতা নামিয়ে বোতাম লাগিয়ে নিক', 'পুরো হাতা নামিয়ে কবজি ঢেকে নিক'],
        GateFault.nail => const ['ওই জুতো বাতিল, ঠিক সোলের জুতো পরুক', 'পেরেকওয়ালা জুতো বদলে তবে আসুক'],
        GateFault.pinhole => const ['লিক করা গ্লাভস বাতিল, নতুন জোড়া নিক', 'ফুটো গ্লাভস সরিয়ে ভালো জোড়া নিক'],
        GateFault.cotton => const ['টেস্ট করা রাবার গ্লাভস পরে নিক', 'এয়ার টেস্ট করে রাবার গ্লাভস পরুক'],
        GateFault.bamboo => const ['বাঁশ নামিয়ে পরীক্ষিত হট স্টিক নিক', 'বাঁশ নয়, ফাইবারগ্লাসের হট স্টিক চাই'],
        GateFault.pvcHook => const ['জুগাড় নামিয়ে পরীক্ষিত হট স্টিক নিক', 'পাইপ ফেলে ফাইবারগ্লাসের হট স্টিক নিক'],
        GateFault.phonePermit => const ['স্বাক্ষরিত পারমিট হাতে এলে তবে শুরু', 'লিখিত পারমিট না আসা পর্যন্ত থামুক'],
        GateFault.wrongFeeder => const ['এই ফিডারের পারমিট না এলে কাজ নয়', 'ফিডার মিলিয়ে ঠিক পারমিট আনুক'],
        GateFault.wrongRating => const ['ডকেট মিলিয়ে 33 kV-র রড আনুক', 'রেটিং মেলানো রড না পেলে কাজ নয়'],
        GateFault.jugaadRod => const ['জুগাড় বাদ, স্টোরের আসল রড আনুক', 'রেটিং লেখা স্টোরের রড নিয়ে আসুক'],
        GateFault.waistBelt => const ['ফুল বডি হারনেস পরে তবেই উঠুক', 'বেল্ট খুলে ফুল বডি হারনেস পরুক'],
        GateFault.chestHigh => const ['বুকের ফিতে মাঝ-বুকে নামিয়ে আঁটুক', 'চেস্ট স্ট্র্যাপ বুকের মাঝে এনে আঁটুক'],
        GateFault.skipCheck => const ['নেমে আগে চারপাশ ঘুরে ঠুকে দেখুক', 'আগে পোল ঘুরে দেখুক, তারপর উঠুক'],
        GateFault.hollow => const ['এই পোলে ওঠা নয়, রিপোর্ট করুক', 'নেমে আসুক, পোলটা রিপোর্ট হোক'],
        GateFault.hive => const ['আগে রিপোর্ট, চাক সরলে তবে উঠুক', 'চাক সরানো না হলে পোলে ওঠা নয়'],
        GateFault.lineFirst => const ['রড সরিয়ে আগে আর্থে ক্ল্যাম্প আঁটুক', 'আগে মাটি, তারপর লাইন — নতুন করে'],
        GateFault.skipDischarge => const ['নেমে আগে মাটি, তারপর তিন তারে রড', 'রড দিয়ে ডিসচার্জ করে তবে কাজ'],
        GateFault.brokenArm => const ['হুক খুলে মজবুত পয়েন্টে লাগাক', 'ভাঙা আর্ম নয়, মজবুত অ্যাঙ্কর চাই'],
        GateFault.lightning => const ['এখনই নেমে নিরাপদ আশ্রয়ে যাক', 'কাজ থামিয়ে নেমে নিরাপদে আশ্রয় নিক'],
        GateFault.waterFire => const ['আগে পাওয়ার বন্ধ, তারপর ABC যন্ত্র', 'জল নয়, পাওয়ার কেটে ABC স্প্রে'],
        GateFault.keptPermit => const ['ফোনে লাইন ক্লিয়ার দিয়ে পারমিট ফেরত', 'সবাইকে গুনে তবে পারমিট ফেরত দিক'],
      };

  /// Realistic wrong "fixes": letting it go (every card 28–36 letters).
  static const excuses = [
    'কিছু বলার দরকার নেই, কাজ চলুক',
    'কাজ শেষ হলে পরে ওকে বুঝিয়ে বলব',
    'একটু সাবধানে করলেই কাজটা চলবে',
    'সুপারভাইজার আছেন, উনিই দেখবেন',
    'আজকে চলুক, কাল থেকে ঠিক করবে',
  ];

  /// "আজ যা ধরলেন" — what was caught.
  static String caught(GateFault f) => switch (f) {
        GateFault.vented => 'ফুটোওয়ালা হেলমেট',
        GateFault.strapOpen => 'খোলা চিন স্ট্র্যাপ',
        GateFault.polyester => 'পলিয়েস্টারের গেঞ্জি',
        GateFault.sleeves => 'গোটানো হাতা',
        GateFault.nail => 'জুতোর সোলে পেরেক',
        GateFault.pinhole => 'লিক করা গ্লাভস',
        GateFault.cotton => 'সুতির গ্লাভস',
        GateFault.bamboo => 'লাইনের কাছে বাঁশ',
        GateFault.pvcHook => 'পিভিসি জুগাড়',
        GateFault.phonePermit => 'ফোনের “পারমিট”',
        GateFault.wrongFeeder => 'ভুল ফিডারের পারমিট',
        GateFault.wrongRating => 'কম রেটিংয়ের রড',
        GateFault.jugaadRod => 'জুগাড় ডিসচার্জ রড',
        GateFault.waistBelt => 'শুধু কোমরের বেল্ট',
        GateFault.chestHigh => 'গলার কাছে বুকের ফিতে',
        GateFault.skipCheck => 'না দেখে পোলে ওঠা',
        GateFault.hollow => 'ফাঁপা পোল',
        GateFault.hive => 'পোলে মৌমাছির চাক',
        GateFault.lineFirst => 'আগে লাইন, পরে মাটি',
        GateFault.skipDischarge => 'ডিসচার্জ বাদ',
        GateFault.brokenArm => 'ভাঙা ক্রস-আর্মে অ্যাঙ্কর',
        GateFault.lightning => 'বাজের মধ্যে পোলে কাজ',
        GateFault.waterFire => 'বৈদ্যুতিক আগুনে জল',
        GateFault.keptPermit => 'পারমিট ফেরত না দেওয়া',
      };

  // The careless coworker (level 1's rival; his recorded voice).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'থামিও না, দেরি হয়ে যাচ্ছে!',
    exitLine: coworkerExit,
    right: ['না, ভুল দেখেছি — কাজ থামাতেই হবে', 'দেরি হোক, ভুল নিয়ে কাজ চলবে না', 'থামাব, আগে ভুলটা ঠিক হোক তারপর'],
    wrong: [
      'ঠিক, দেরি হলে বকুনি খেতে হবে',
      'এবারের মতো চলুক, পরে দেখা যাবে',
      'ওরা অভিজ্ঞ, ভুল করবে না নিশ্চয়ই',
      'থামালে সবাই রাগ করবে, থাক বরং',
      'আচ্ছা, কিছু না বলে দেখে যাই',
    ],
    asks: ['ও বলছে থামাতে না। আপনি কী করবেন?', 'থামাবেন, না চুপ করে দেখবেন?', 'কার কথা শুনবেন — ওর, না নিজের চোখের?'],
  );
}

/// Same-slot pairs whose lines would be true (or near) for each other, and
/// cross-slot look-alikes: never dealt against each other.
bool _clash(GateFault a, GateFault b) {
  if (a == b) return true;
  const look = {GateFault.pvcHook, GateFault.jugaadRod};
  if (look.contains(a) && look.contains(b)) return true;
  return a.slot == b.slot && const {GateSlot.shirt, GateSlot.harness, GateSlot.rod}.contains(a.slot);
}

bool _fixClash(GateFault a, GateFault b) {
  if (a == b || a.slot == b.slot) return true;
  const tools = {GateFault.bamboo, GateFault.pvcHook, GateFault.jugaadRod, GateFault.wrongRating};
  return tools.contains(a) && tools.contains(b);
}

/// Wrong "কী ভুল?" cards for [f]: what the other faults of the same place
/// would look like (all false here). [kv]: the docket's voltage.
List<String> gateWhatWrong(GateFault f, {int kv = 33}) => [
      for (final o in GateFault.values)
        if (o.slot.atVan == f.slot.atVan && !_clash(f, o) && !(kv == 11 && o == GateFault.wrongRating)) ...o.what,
    ];

/// Wrong "এখন কী করবেন?" cards for [f]: letting it go, or another fault's fix.
List<String> gateFixWrong(GateFault f, {int kv = 33}) => [
      ...GateLines.excuses,
      for (final o in GateFault.values)
        if (o.slot.atVan == f.slot.atVan && !_fixClash(f, o) && !(kv == 11 && o == GateFault.wrongRating)) ...o.fix,
    ];

abstract final class GateMistakes {
  static DoMistake of(GateFault f) => switch (f) {
        GateFault.vented => const DoMistake(
            key: 'm1/gate/vented-helmet',
            textBn: 'হেলমেটে বাতাসের ফুটো ছিল — লাইনের কাজে ফুটোহীন (নন-ভেন্টেড), মেটালমুক্ত ISI হেলমেটই চাই।',
            art: 'assets/game/art/gate/helmet.svg',
            lessonPoint: 1),
        GateFault.strapOpen => const DoMistake(
            key: 'm1/gate/chin-strap',
            textBn: 'থুতনির ফিতে খোলা ছিল — পোল ঝাঁকালেই হেলমেট খসে পড়ে। ফিতে বেঁধে লক করে নিন।',
            art: 'assets/game/art/gate/helmet.svg',
            lessonPoint: 1),
        GateFault.polyester => const DoMistake(
            key: 'm1/gate/polyester',
            textBn: 'পলিয়েস্টার/সিন্থেটিক গেঞ্জি স্পার্ক বা ফ্ল্যাশে গলে চামড়ায় সেঁটে যায় — ফুল হাতা সুতির জামা চাই।',
            art: 'assets/game/art/gate/clothes.svg',
            deadly: true,
            lessonPoint: 0),
        GateFault.sleeves => const DoMistake(
            key: 'm1/gate/sleeves',
            textBn: 'জামার হাতা গোটানো ছিল — ফ্ল্যাশের তাপে খোলা হাত সরাসরি পোড়ে। হাতা নামিয়ে বোতাম লাগান।',
            art: 'assets/game/art/gate/sleeves.svg',
            lessonPoint: 0),
        GateFault.nail => const DoMistake(
            key: 'm1/gate/boot-nail',
            textBn: 'জুতোর সোলে পেরেক গাঁথা ছিল — ওটাই কারেন্টের মাটিতে নামার রাস্তা, সাক্ষাৎ মৃত্যুফাঁদ। ওই জুতো বাতিল।',
            art: 'assets/game/art/gate/boot_nail.svg',
            deadly: true,
            lessonPoint: 2),
        GateFault.pinhole => const DoMistake(
            key: 'm1/gate/glove-leak',
            textBn: 'এয়ার টেস্টে গ্লাভস থেকে হাওয়া লিক করছিল — পিনের ডগার মতো ফুটোতেও মৃত্যু নিশ্চিত। ওই গ্লাভস বাতিল।',
            art: 'assets/game/art/gate/gloves.svg',
            deadly: true,
            lessonPoint: 3),
        GateFault.cotton => const DoMistake(
            key: 'm1/gate/cotton-gloves',
            textBn: 'সুতির বা কাপড়ের গ্লাভস শুধু ঘষা আটকায়, শক নয় — টেস্ট করা রাবার গ্লাভসই চাই।',
            art: 'assets/game/art/gate/gloves.svg',
            deadly: true,
            lessonPoint: 3),
        GateFault.bamboo => const DoMistake(
            key: 'm1/gate/bamboo',
            textBn: 'শুকনো বাঁশও ভেতরের আর্দ্রতা আর ময়লায় কারেন্ট টানে — লাইনের কাছে শুধু পরীক্ষিত ফাইবারগ্লাস হট স্টিক।',
            art: 'assets/game/art/gate/long_tool.svg',
            deadly: true,
            lessonPoint: 3),
        GateFault.pvcHook => const DoMistake(
            key: 'm1/gate/pvc-hook',
            textBn: 'পিভিসি পাইপে লোহার হুক — জুগাড় ফাটে, ভেজা-ময়লায় লিক করে। লাইনের কাছে শুধু পরীক্ষিত হট স্টিক।',
            art: 'assets/game/art/gate/long_tool.svg',
            deadly: true,
            lessonPoint: 3),
        GateFault.phonePermit => const DoMistake(
            key: 'm1/gate/phone-permit',
            textBn: 'ফোনে বলা “লাইন বন্ধ” কোনো পারমিট নয় — হাতে স্বাক্ষরিত পারমিট (PTW) ছাড়া কাজ শুরু নয়।',
            art: 'assets/game/art/gate/permit.svg',
            deadly: true,
            lessonPoint: 1),
        GateFault.wrongFeeder => const DoMistake(
            key: 'm1/gate/wrong-feeder',
            textBn: 'পারমিটের ফিডার আর পোলের ফিডার আলাদা ছিল — অন্য লাইন বন্ধ, এই লাইন চালু থাকতে পারে।',
            art: 'assets/game/art/gate/permit.svg',
            deadly: true,
            lessonPoint: 1),
        GateFault.wrongRating => const DoMistake(
            key: 'm1/gate/rod-rating',
            textBn: '33 kV লাইনে 11 kV-র রড — ইনসুলেশন ভেঙে যাওয়ার ঝুঁকি। ডকেটের ভোল্টেজ মিলিয়ে রড নিন।',
            art: 'assets/game/art/gate/rod.svg',
            deadly: true,
            lessonPoint: 3),
        GateFault.jugaadRod => const DoMistake(
            key: 'm1/gate/jugaad-rod',
            textBn: 'পিভিসি পাইপ কেটে বানানো জুগাড় ডিসচার্জ রড নয় — স্টোরের, রেটিং লেখা স্ট্যান্ডার্ড রডই চাই।',
            art: 'assets/game/art/gate/rod.svg',
            deadly: true,
            lessonPoint: 4),
        GateFault.waistBelt => const DoMistake(
            key: 'm1/gate/waist-belt',
            textBn: 'কোমরের বেল্ট শুধু ওয়ার্ক পজিশনিংয়ের জন্য — পড়লে শিরদাঁড়ায় সব চাপ পড়ে। ফুল বডি হারনেস চাই।',
            art: 'assets/game/art/gate/harness.svg',
            deadly: true,
            lessonPoint: 0),
        GateFault.chestHigh => const DoMistake(
            key: 'm1/gate/chest-strap',
            textBn: 'বুকের ফিতে গলার কাছে ছিল — ভুল ফিটিং পড়ার সময় ভুল জায়গায় চাপ দেয়। ফিতে বুকের মাঝে আঁটুন।',
            art: 'assets/game/art/gate/harness.svg',
            lessonPoint: 2),
        GateFault.skipCheck => const DoMistake(
            key: 'm1/gate/skip-pole-check',
            textBn: 'পোলে হাত দেওয়ার আগে চারপাশ ঘুরে দেখা, গোড়া দেখা আর ঠুকে শব্দ শোনা — তবেই ওঠা।',
            art: 'assets/game/art/gate/pole.svg',
            lessonPoint: 0),
        GateFault.hollow => const DoMistake(
            key: 'm1/gate/hollow-pole',
            textBn: 'ঠুকতেই ‘দপ্ দপ্’ — ভেতরের কংক্রিট দুর্বল বা ফাটল। এই পোলে ওঠা নয়, রিপোর্ট।',
            art: 'assets/game/art/gate/pole.svg',
            deadly: true,
            lessonPoint: 1),
        GateFault.hive => const DoMistake(
            key: 'm1/gate/hive',
            textBn: 'পোলে মৌমাছির চাক ছিল — আগে সুপারভাইজারকে রিপোর্ট, চাক সরানো হলে তবেই ওঠা।',
            art: 'assets/game/art/gate/pole.svg',
            lessonPoint: 2),
        GateFault.lineFirst => const DoMistake(
            key: 'm1/gate/line-first',
            textBn: 'আগে লাইনে হুক, পরে আর্থ — জমে থাকা চার্জ শরীর দিয়ে মাটিতে নামে। আগে মাটি, তারপর লাইন।',
            art: 'assets/game/art/gate/discharge.svg',
            deadly: true,
            lessonPoint: 1),
        GateFault.skipDischarge => const DoMistake(
            key: 'm1/gate/skip-discharge',
            textBn: '“5 মিনিট তো বন্ধ” — তবু ক্যাপাসিটিভ চার্জ আর ইন্ডুসড ভোল্টেজ থাকে। ডিসচার্জ বাধ্যতামূলক।',
            art: 'assets/game/art/gate/discharge.svg',
            deadly: true,
            lessonPoint: 0),
        GateFault.brokenArm => const DoMistake(
            key: 'm1/gate/broken-arm-anchor',
            textBn: 'ভাঙা বা নড়বড়ে ক্রস-আর্ম কখনো অ্যাঙ্কর পয়েন্ট নয় — মজবুত পয়েন্টে ল্যানিয়ার্ড লাগান।',
            art: 'assets/game/art/gate/anchor.svg',
            deadly: true,
            lessonPoint: 3),
        GateFault.lightning => const DoMistake(
            key: 'm1/gate/lightning',
            textBn: 'বাজ পড়ছে — কোনো PPE বাঁচায় না। উচ্চতায় কাজ থামিয়ে নেমে নিরাপদ আশ্রয়ে যান।',
            art: 'assets/game/art/gate/lightning.svg',
            deadly: true,
            lessonPoint: 1),
        GateFault.waterFire => const DoMistake(
            key: 'm1/gate/water-fire',
            textBn: 'বৈদ্যুতিক আগুনে জল — জল বিদ্যুৎ পরিবাহী, শক লাগে। আগে পাওয়ার বন্ধ, তারপর ABC যন্ত্র।',
            art: 'assets/game/art/gate/fire_water.svg',
            deadly: true,
            lessonPoint: 1),
        GateFault.keptPermit => const DoMistake(
            key: 'm1/gate/kept-permit',
            textBn: 'পারমিট ফেরত না দিয়ে চলে যাচ্ছিল — কন্ট্রোল রুম ভাববে কাজ চলছে। লাইন ক্লিয়ার দিয়ে ফেরত দিন।',
            art: 'assets/game/art/gate/permit.svg',
            lessonPoint: 2),
      };

  /// A stop on a moment done right.
  static const falseStop = DoMistake(
    key: 'm1/gate/false-stop',
    textBn: 'সব ঠিকঠাক চলছিল — অকারণে থামালে কাজ পিছোয়, দলও ভরসা হারায়। ভালো করে দেখে তবে থামান।',
    art: 'assets/game/art/gate/false_stop.svg',
    // The gate's own lesson (1.10): the 10-second safety scan — what to check
    // before calling a stop (filed under the gate's lesson, not the slot's).
    lessonPoint: 1,
  );

  static List<DoMistake> get all => [for (final f in GateFault.values) of(f), falseStop];
}

/// The docket (dealt): what the crew is sent to do.
@immutable
class GateDocket {
  const GateDocket({required this.kv, required this.feeder, required this.permitFeeder, required this.poleNo, required this.job});
  final int kv;
  final String feeder;

  /// The feeder written on the permit (different only for the wrong-feeder moment).
  final String permitFeeder;
  final int poleNo;
  final String job;
}

/// One moment of the job: a slot, done right ([fault] null) or with a mistake.
@immutable
class GateMoment {
  const GateMoment(this.slot, this.fault);
  final GateSlot slot;
  final GateFault? fault;
  bool get right => fault == null;
  bool get deadly => fault?.deadly ?? false;
}

@immutable
class GateDeal {
  const GateDeal({required this.docket, required this.moments, required this.coworkerAt, required this.swap});
  final GateDocket docket;
  final List<GateMoment> moments;

  /// The moment (a mistake, never the first) on which the coworker pushes.
  final int coworkerAt;

  /// Which lineman does the work (the two looks swap).
  final bool swap;
}

/// Deals a play: 10–12 of the 14 slots in the job's order, about half with a
/// mistake (n/2 ± 1), at least 2 of them deadly, from at least 4 lessons;
/// the coworker on a mistake moment that is not the first.
GateDeal dealGate(math.Random rng) {
  final n = 10 + rng.nextInt(3);
  for (var attempt = 0;; attempt++) {
    final kv = rng.nextBool() ? 11 : 33;
    final slots = ([...GateSlot.values]..shuffle(rng)).take(n).toList()..sort((a, b) => a.index.compareTo(b.index));
    final k = n ~/ 2 + rng.nextInt(3) - 1;
    final picks = ([for (var i = 0; i < n; i++) i]..shuffle(rng)).take(k).toSet();
    final moments = <GateMoment>[
      for (var i = 0; i < n; i++)
        if (picks.contains(i))
          GateMoment(slots[i], () {
            final pool = [for (final f in gateFaultsOf(slots[i])) if (kv == 33 || f != GateFault.wrongRating) f];
            return pool[rng.nextInt(pool.length)];
          }())
        else
          GateMoment(slots[i], null),
    ];
    final faults = [for (final m in moments) ?m.fault];
    final deadly = faults.where((f) => f.deadly).length;
    final lessons = {for (final f in faults) f.lessonId}.length;
    final pushes = [for (var i = 1; i < n; i++) if (!moments[i].right) i];
    // (A deal that misses a rule is dealt again; the rules hold within a few tries.)
    // (The coworker needs a moment to push on: never dealt without one.)
    if (pushes.isEmpty || ((deadly < 2 || lessons < 4) && attempt < 500)) continue;
    final feeder = GateLines.feeders[rng.nextInt(GateLines.feeders.length)];
    final others = [for (final f in GateLines.feeders) if (f != feeder) f];
    final wrongFeeder = faults.contains(GateFault.wrongFeeder);
    return GateDeal(
      docket: GateDocket(
        kv: kv,
        feeder: feeder,
        permitFeeder: wrongFeeder ? others[rng.nextInt(others.length)] : feeder,
        poleNo: 11 + rng.nextInt(30),
        job: GateLines.jobs[rng.nextInt(GateLines.jobs.length)],
      ),
      moments: moments,
      coworkerAt: pushes[rng.nextInt(pushes.length)],
      swap: rng.nextBool(),
    );
  }
}

/// The play state (pure logic).
class GateRun {
  GateRun(this.deal);
  final GateDeal deal;
  int index = 0;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// Every catch stopped soon after its cue and no slips (the quick bonus).
  bool quick = true;

  bool get done => index >= deal.moments.length;
  bool get ended => done || deadly != null;
  GateMoment get current => deal.moments[index.clamp(0, deal.moments.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// The player stopped the work. Null: there was a mistake to catch; else
  /// the stop was needless (a slip).
  DoMistake? stop() {
    if (ended) return null;
    if (!current.right) return null;
    slips++;
    quick = false;
    return GateMistakes.falseStop;
  }

  /// The moment played out with no stop: null when it was done right; else
  /// the missed mistake (a slip, or the deadly one that ends the play).
  /// [pushed]: he listened to the coworker — that is the slip (playbook §1
  /// beat 8, "Listening = the slip"), whatever the mistake's class.
  DoMistake? letPass({bool pushed = false}) {
    if (ended) return null;
    final f = current.fault;
    if (f == null) return null;
    quick = false;
    final m = f.mistake;
    if (m.deadly && !pushed) return deadly = m;
    slips++;
    // Booked as a slip (a deadly-class card here must not use a near-miss).
    return m.deadly ? DoMistake(key: m.key, textBn: m.textBn, art: m.art, lessonPoint: m.lessonPoint) : m;
  }

  void tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  void next() => index++;
}

@immutable
class GateWatchPack {
  const GateWatchPack({required this.id, required this.titleBn});
  final String id;
  final String titleBn;
}

const gateWatchPacks = {
  'gate_m1': GateWatchPack(id: 'gate_m1', titleBn: GateLines.title),
};

/// Test hook: what the gate is doing now (widget tests drive the auto-playing
/// job by it). Never used by the app.
class GateWatchProbe {
  _GateRunPageState? _s;
  GateDeal? get deal => _s?._run.deal;
  int get index => _s?._run.index ?? -1;
  GateMoment? get moment {
    final s = _s;
    return s == null || s._run.done ? null : s._run.current;
  }

  /// The moment's time now (0 → 1).
  double get t => _s?._play.value ?? 0;

  /// intro, travel, play, spot, what, fix, redo, card, freeze, done.
  String get phase => _s?._phase.name ?? 'none';

  /// Where on screen the current mistake can be tapped (null: none).
  Offset? zoneGlobal() => _s?._probePoint(hit: true);

  /// A point on the scene that is not the mistake.
  Offset? missGlobal() => _s?._probePoint(hit: false);
}

// ============================================================================
// Page
// ============================================================================

class GateWatchPage extends StatefulWidget {
  const GateWatchPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final GateWatchPack pack;
  final bool muted;
  final int? seed;
  final GateWatchProbe? probe;

  @override
  State<GateWatchPage> createState() => _GateWatchPageState();
}

class _GateWatchPageState extends State<GateWatchPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GateRunPage(
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

class _GateRunPage extends ConsumerStatefulWidget {
  const _GateRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final GateWatchPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final GateWatchProbe? probe;

  @override
  ConsumerState<_GateRunPage> createState() => _GateRunPageState();
}

enum _Phase { intro, travel, play, spot, what, fix, redo, card, freeze, done }

class _GateRunPageState extends ConsumerState<_GateRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final GateRun _run = GateRun(dealGate(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The moment playing (0 → 1 over its slot's time). Reduced motion shows
  /// a still for the same time (the clock is not shortened).
  late final AnimationController _play = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve)
    ..addListener(_onPlayTick)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _playDone();
    });

  /// The camera moving on to the next moment (0 → 1).
  late final AnimationController _travel = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _startPlay();
    });

  /// A missed deadly mistake playing out in colour (0 → 1).
  late final AnimationController _harm = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  _Phase _phase = _Phase.intro;
  int _runScore = 0;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  String _cardLesson = '1.1';
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  String _rankFrom = GateLines.rankFrom;
  String _rankTo = GateLines.rankTo;

  /// The previous moment (drawn sliding away while the camera travels).
  GateMoment? _prev;
  var _cuePlayed = false;

  /// He listened to the coworker: this moment plays out (it is missed).
  var _listened = false;

  /// The crew lead's "সব তো ঠিক ছিল!" after a needless stop.
  var _leadSays = false;

  /// After a stop: wrong taps / wrong "কী ভুল?" picks (lower the table).
  int _missTaps = 0;
  int _whatWrongs = 0;

  /// Where the mistake was found (scene px): the lens shows it close.
  Offset? _lensAt;
  List<ChoiceOption> _whatOpts = const [];
  final Set<String> _whatWrong = {};
  String? _whatPicked;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;
  int _notHereN = 0;
  final _hints = IdleHintController();
  final _touchKey = GlobalKey(debugLabel: 'gate-touch');
  GateGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  GateDocket get _docket => _run.deal.docket;
  GateMoment get _moment => _run.current;

  @override
  void initState() {
    super.initState();
    widget.probe?._s = this;
  }

  @override
  void dispose() {
    if (widget.probe?._s == this) widget.probe?._s = null;
    disposeCoworker();
    _play.dispose();
    _travel.dispose();
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

  // --- the shot on screen --------------------------------------------------
  GateShot _shot(GateMoment m, double t, {bool asRight = false, bool gone = false}) => GateShot(
        slot: m.slot,
        fault: asRight ? null : m.fault,
        t: t,
        kv: _docket.kv,
        feeder: GateLines.feederName(_docket.feeder),
        permitFeeder: GateLines.feederName(_docket.permitFeeder),
        poleNo: _docket.poleNo,
        swap: _run.deal.swap,
        gone: gone,
      );

  /// What the scene shows now.
  GateShot get _now {
    final m = _moment;
    final quiet = _quiet;
    return switch (_phase) {
      _Phase.intro || _Phase.travel => _shot(m, quiet ? m.slot.stillT : 0),
      _Phase.spot || _Phase.what || _Phase.fix => _shot(m, m.slot.stillT),
      _Phase.redo => _shot(m, quiet ? m.slot.stillT : _play.value, asRight: true),
      _Phase.card when _leadSays => _shot(m, m.slot.stillT),
      // A missed fall: the worker is drawn falling (in colour), not in place.
      _Phase.freeze || _Phase.done when _freeze => _shot(m, quiet ? m.slot.stillT : _play.value, gone: gateHarmOf(m.fault!) == GateHarm.fall),
      _ => _shot(m, quiet ? m.slot.stillT : _play.value),
    };
  }

  GateCam _camOf(GateMoment m, GateGeo g) => gateCamFor(m.slot, g);

  // --- the job: moments one after another -------------------------------------
  void _start() {
    _clock.start();
    _rankNames();
    _beginMoment(first: true);
  }

  void _rankNames() {
    List<CatalogModule> mods;
    try {
      mods = ref.read(contentCatalogProvider).value?.modules ?? const [];
    } catch (_) {
      mods = const [];
    }
    for (final m in mods) {
      if (m.id == 'm1' && m.rankName.isNotEmpty) _rankFrom = m.rankName;
      if (m.id == 'm2' && m.rankName.isNotEmpty) _rankTo = m.rankName;
    }
  }

  void _beginMoment({bool first = false}) {
    if (!mounted || _ended) return;
    final g = _geo;
    final m = _moment;
    final prev = first ? null : _prev;
    setState(() {
      _listened = false;
      _leadSays = false;
      _lensAt = null;
      _missTaps = 0;
      _whatWrongs = 0;
      _whatOpts = const [];
      _whatWrong.clear();
      _whatPicked = null;
      _cuePlayed = false;
      _phase = _Phase.travel;
    });
    final moves = prev != null && g != null && (prev.slot.atVan != m.slot.atVan || _camOf(prev, g) != _camOf(m, g));
    if (first) unawaited(_sayChain([GateLines.watch]));
    if (moves && !_quiet) {
      if (prev.slot.atVan != m.slot.atVan) _cue('sounds/van_arrive.ogg', volume: 0.35);
      unawaited(_travel.forward(from: 0));
    } else {
      _travel.value = 1;
      _startPlay();
    }
  }

  void _startPlay() {
    if (!mounted || _ended || _phase != _Phase.travel) return;
    final m = _moment;
    setState(() => _phase = _Phase.play);
    _play.duration = Duration(milliseconds: m.slot.ms);
    unawaited(_play.forward(from: 0));
    // His moment: he is armed now and comes once the mistake is in view
    // (coworkerCanCome / _onPlayTick).
    if (_run.index == _run.deal.coworkerAt && !coworkerDone) scheduleCoworker();
  }

  /// Sounds of the moment (only the sound — never its meaning). The spark is
  /// heard only on a discharge done right: with no earth (or none at all)
  /// there is no safe spark — its absence is part of the fault (lesson 1.5).
  void _onPlayTick() {
    // His moment: he may come only once the mistake is in view (stillT); if his
    // retry timer has not brought him in by a little after it, he comes now —
    // well before the moment ends.
    if (_phase == _Phase.play && coworkerDue && _run.index == _run.deal.coworkerAt && _play.value >= _moment.slot.stillT + 0.12) {
      holdForCoworker();
    }
    if (_cuePlayed || (_phase != _Phase.play && _phase != _Phase.redo)) return;
    final m = _moment;
    final f = _phase == _Phase.redo ? null : m.fault;
    final t = _play.value;
    switch (m.slot) {
      case GateSlot.poleCheck when f != GateFault.skipCheck && t >= 0.44:
        _cuePlayed = true;
        _cue(f == GateFault.hollow ? 'sounds/learn/knock_hollow.ogg' : 'sounds/learn/knock_solid.ogg', volume: 0.8);
      case GateSlot.sky when t >= 0.42:
        _cuePlayed = true;
        _cue('sounds/learn/thunder_far.ogg', volume: 0.8);
      case GateSlot.discharge when f == null && t >= 0.52:
        _cuePlayed = true;
        _cue('sounds/learn/spark.ogg', volume: 0.35);
      default:
        break;
    }
  }

  void _playDone() {
    if (!mounted || _ended) return;
    if (_phase == _Phase.redo) {
      _next();
      return;
    }
    if (_phase != _Phase.play || coworkerOpen) return;
    // He never came on his moment (it is over): he does not come later.
    final m = _run.letPass(pushed: _listened);
    if (m == null) {
      _prev = _moment;
      _next();
      return;
    }
    if (m.deadly) {
      unawaited(_deadly(m));
      return;
    }
    unawaited(_levelDelta(-10, _centre(), mood: GuideMood.warn));
    unawaited(_slip(m));
  }

  void _next() {
    _prev = _moment;
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _beginMoment();
  }

  Offset _centre() {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  // --- the stop -----------------------------------------------------------------
  bool get _canStop => _phase == _Phase.play && !_listened && !_ended && _card == null && !tableBusy && !coworkerOpen;

  void _stopPressed(Offset origin) {
    if (!_canStop) return;
    // On his moment the stop waits for him (he comes now), however fast it is.
    if (holdForCoworker()) return;
    _doStop();
  }

  void _doStop({bool byCoworker = false}) {
    if (_phase != _Phase.play || _ended) return;
    final t = _play.value;
    _play.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.8);
    final m = _run.stop();
    if (m != null) {
      // Needless: the crew lead shrugs, then the slip card.
      setState(() {
        _phase = _Phase.card;
        _leadSays = true;
      });
      unawaited(() async {
        await Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1400));
        if (!mounted || _ended) return;
        unawaited(_levelDelta(-10, _centre(), mood: GuideMood.warn));
        await _slip(m);
      }());
      return;
    }
    if (!byCoworker && t > _moment.slot.stillT + 0.15) _run.quick = false;
    setState(() => _phase = _Phase.spot);
    if (!byCoworker) unawaited(_sayChain([GateLines.where]));
  }

  /// A tap on the scene (design px): in a stop, is it where the mistake is?
  void _tapScene(Offset p) {
    final g = _geo;
    if (g == null || _phase != _Phase.spot || tableBusy || coworkerOpen || _card != null) {
      if (_phase == _Phase.play || _phase == _Phase.spot) _hints.missTap();
      return;
    }
    final w = _camOf(_moment, g).toWorld(p, g.h);
    final hit = gateZones(_now, g).any((z) => z.contains(w));
    if (!hit) {
      _missTaps++;
      _hints.missTap();
      HapticFeedback.lightImpact();
      _cue('sounds/quiz_wrong.ogg', volume: 0.35);
      unawaited(_sayChain([GateLines.notHere[_notHereN++ % GateLines.notHere.length]], mood: GuideMood.think));
      return;
    }
    final f = _moment.fault!;
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_select.ogg', volume: 0.6);
    setState(() {
      _lensAt = p;
      _phase = _Phase.what;
      _whatOpts = dealChoices(f.what, gateWhatWrong(f, kv: _docket.kv), widget.rng);
      _whatWrong.clear();
      _whatPicked = null;
    });
    unawaited(_sayChain([GateLines.askWhat]));
  }

  Future<void> _pickWhat(ChoiceOption o, Offset at) async {
    if (_phase != _Phase.what || _whatPicked != null || _whatWrong.contains(o.textBn)) return;
    _hush();
    if (!o.correct) {
      HapticFeedback.mediumImpact();
      _cue('sounds/quiz_wrong.ogg');
      setState(() {
        _whatWrong.add(o.textBn);
        _whatWrongs++;
      });
      unawaited(_sayChain([GateLines.notThis], mood: GuideMood.warn));
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.8);
    setState(() => _whatPicked = o.textBn);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended || _phase != _Phase.what) return;
    final f = _moment.fault!;
    final idx = _run.index;
    setState(() => _phase = _Phase.fix);
    // The ◆ wait on the table; the fix pays them (a wrong fix burns them).
    putOnTable(_missTaps == 0 && _whatWrongs == 0 ? 15 : 10);
    unawaited(askReason(
      deal: () => dealChoices(f.fix, gateFixWrong(f, kv: _docket.kv), widget.rng),
      question: GateLines.askFix,
      stillValid: () => _run.index == idx && !_ended,
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
    final f = _moment.fault;
    if (f != null) _run.tag(GateLines.caught(f));
    // The crew redoes it right, then the job goes on by itself.
    setState(() {
      _phase = _Phase.redo;
      _lensAt = null;
      _cuePlayed = false;
    });
    unawaited(_sayChain([GateLines.redo], mood: GuideMood.glad));
    _play.duration = Duration(milliseconds: (_moment.slot.ms * (_quiet ? 0.3 : 0.6)).round());
    unawaited(_play.forward(from: 0));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => GateLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerAt) return null;
    if (_phase == _Phase.travel || _phase == _Phase.intro) return false;
    if (_phase != _Phase.play || _listened) return null;
    // Not before the mistake is in view: his arrival must never be the first
    // sign that this moment is wrong (an early থামান still brings him in at
    // once — holdForCoworker).
    if (_play.value < _moment.slot.stillT) return false;
    return true;
  }

  /// He takes the stage: the job holds still while he talks.
  @override
  void coworkerClearGuideBubble() {
    super.coworkerClearGuideBubble();
    _play.stop();
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened: the mistake plays out (it is missed) — then its card, a
      // slip even on a deadly-class mistake (playbook: listening = the slip).
      setState(() => _listened = true);
      if (!_ended && _phase == _Phase.play) unawaited(_play.forward());
      return;
    }
    _run.tag(GateLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    // Refused: the work stops here (at once) — then show where.
    _doStop(byCoworker: true);
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain || _ended || _phase != _Phase.spot) return;
      await _sayChain([GateLines.callHeld, GateLines.where], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_phase == _Phase.intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? GateLines.tapWhy[_nudgeN++ % GateLines.tapWhy.length]
            : _nudge.next(switch (_phase) {
                _Phase.spot => GateLines.where,
                _Phase.what => GateLines.askWhat,
                _ => GateLines.watch,
              });
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  /// The level's context with the lesson that teaches [m] (the mistakes book
  /// files it under that lesson).
  LevelContext _ctxFor(String lessonId) => LevelContext(
        rungId: widget.ctx.rungId,
        kind: widget.ctx.kind,
        lessonId: lessonId,
        lessonTitleBn: widget.ctx.lessonTitleBn,
        ladderStep: widget.ctx.ladderStep,
        doIndex: widget.ctx.doIndex,
        doCount: widget.ctx.doCount,
      );

  String get _gateLesson => widget.ctx.lessonId.isEmpty ? '1.10' : widget.ctx.lessonId;

  String get _lessonNow => _moment.fault?.lessonId ?? _lessonOfSlot(_moment.slot);

  static String _lessonOfSlot(GateSlot s) => gateFaultsOf(s).first.lessonId;

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _play.stop();
    unawaited(bookMistake(ref, _ctxFor(_cardLesson), m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() => _phase = _Phase.done);
  }

  Future<void> _slip(DoMistake m) async {
    // A needless stop is filed under the gate's own lesson (1.10), never
    // under the lesson of the moment that was done right.
    _cardLesson = m == GateMistakes.falseStop ? _gateLesson : _lessonNow;
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
      _leadSays = false;
    });
    unawaited(bookMistake(ref, _ctxFor(_cardLesson), m));
    final speak = await SpokenOnce.first('gate/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A missed deadly mistake plays out: the scene freezes grey and the
  /// consequence plays in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _cardLesson = _lessonNow;
    HapticFeedback.heavyImpact();
    final harm = gateHarmOf(_moment.fault!);
    _cue(harm == GateHarm.fall ? 'sounds/learn/stomp.ogg' : 'sounds/learn/spark.ogg', volume: 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _phase = _Phase.freeze;
      _freeze = true;
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
    final speak = await SpokenOnce.first('gate/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? GateLines.deadlyWord : GateLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    setState(() => _phase = _Phase.done);
    final save = ref.read(gameSaveProvider.notifier);
    final centre = _centre();
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      // The rank gate: ট্রেইনি → জুনিয়র (Module 2's rank).
      await save.unlockRank(2);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _run.quick) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _run.quick);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    if (_run.passed) _cue('sounds/quiz_complete.ogg', volume: 0.85);
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(_run.passed ? GateLines.promoted(_rankTo) : GateLines.fail, mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- test hook ----------------------------------------------------------------
  Offset? _probePoint({required bool hit}) {
    final g = _geo;
    final box = _touchKey.currentContext?.findRenderObject();
    if (g == null || box is! RenderBox || !box.hasSize || _run.done) return null;
    final cam = _camOf(_moment, g);
    final zones = gateZones(_now, g);
    if (hit) {
      if (zones.isEmpty) return null;
      return box.localToGlobal(cam.toScreen(zones.first.center, g.h));
    }
    for (var y = g.h * 0.3; y < g.h * 0.62; y += 18) {
      for (var x = 24.0; x < 300; x += 18) {
        final w = cam.toWorld(Offset(x, y), g.h);
        if (!zones.any((z) => z.inflate(14).contains(w))) return box.localToGlobal(Offset(x, y));
      }
    }
    return null;
  }

  // --- the scene ---------------------------------------------------------------
  /// One place of the job drawn for [s] through [cam].
  Widget _world(GateShot s, GateGeo g, GateCam cam) {
    if (s.slot.atVan) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: CustomPaint(painter: VanYardPainter())),
          CustomPaint(painter: GateVanPainter(shot: s, geo: g)),
        ],
      );
    }
    return Transform(
      transform: cam.matrix(g.h),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: CustomPaint(painter: PoleYardPainter(geo: g.pole, orbit: 0))),
          CustomPaint(painter: GatePolePainter(shot: s, geo: g, layer: GateLayer.back)),
          CustomPaint(painter: PolePainter(pole: gatePoleFor(s), geo: g.pole, orbit: 0)),
          CustomPaint(painter: GatePolePainter(shot: s, geo: g, layer: GateLayer.front)),
        ],
      ),
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final g = _geo = GateGeo(m.height, m.inset);
    final mo = _moment;
    final s = _now;
    final quiet = _quiet;
    var cam = _camOf(mo, g);
    final prev = _prev;
    final v = Curves.easeInOut.transform(_travel.value);
    final travelling = _phase == _Phase.travel && prev != null && _travel.isAnimating;
    final slide = travelling && prev.slot.atVan != mo.slot.atVan;
    if (travelling && !slide) cam = GateCam.lerp(_camOf(prev, g), cam, v);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final stopped = _phase == _Phase.spot || _phase == _Phase.what || _phase == _Phase.fix;
    final bubble = travelling || _freeze ? null : gateBubble(s, g);
    final lens = _lensAt;
    return [
      if (slide)
        Positioned.fill(
          key: const ValueKey('world-prev'),
          child: Transform.translate(
            offset: Offset(-360 * v, 0),
            child: _world(_shot(prev, 1, asRight: true), g, _camOf(prev, g)),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('world'),
        child: Transform.translate(
          offset: Offset(slide ? 360 * (1 - v) : 0, 0),
          child: ColorFiltered(colorFilter: grey, child: _world(s, g, cam)),
        ),
      ),
      if (bubble != null)
        Positioned(
          key: ValueKey('bubble-${mo.slot.name}'),
          left: (cam.toScreen(bubble.at, g.h).dx - 90).clamp(6.0, 174.0),
          top: math.max(70.0, cam.toScreen(bubble.at, g.h).dy - 52),
          width: 180,
          child: IgnorePointer(child: _SceneBubble(text: bubble.text, sound: bubble.sound)),
        ),
      if (_leadSays)
        Positioned(
          key: const ValueKey('lead-says'),
          left: 40,
          right: 40,
          top: 118,
          child: IgnorePointer(child: _LeadSays(quiet: quiet)),
        ),
      // A stop holds the scene still: a cool frame round it, nothing named.
      if (stopped)
        const Positioned.fill(key: ValueKey('stop-tint'), child: IgnorePointer(child: _StopTint())),
      if (lens != null && stopped)
        _lensLayer(lens, s, g, _camOf(mo, g), quiet),
      // The missed deadly mistake, in colour over the grey scene.
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('harm'),
          child: IgnorePointer(
            child: Transform(
              transform: cam.matrix(g.h),
              child: CustomPaint(
                painter: GateHarmPainter(
                  kind: gateHarmOf(mo.fault!),
                  at: gateHarmAt(s, g),
                  k: _harm.value,
                  ground: g.ground,
                  man: g.man,
                  look: gateActorLook(s),
                ),
              ),
            ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: GestureDetector(
          key: _touchKey,
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _tapScene(d.localPosition),
        ),
      ),
    ];
  }

  /// The lens: the spot the player found, close up (the inspect move).
  Widget _lensLayer(Offset at, GateShot s, GateGeo g, GateCam cam, bool quiet) {
    const r = 76.0;
    // The lens magnifies what is on screen: less where the camera is close.
    final k = cam.scale > 1.5 ? 1.6 : 2.3;
    final cx = at.dx.clamp(r + 8, 360 - r - 8);
    final up = at.dy - r - 46;
    final cy = (up > 150 ? up : at.dy + r + 46).clamp(150.0, g.h - 300);
    return Positioned(
      key: const ValueKey('lens'),
      left: cx - r,
      top: cy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: quiet ? 1 : 0.4, end: 1),
          duration: Duration(milliseconds: quiet ? 1 : 320),
          curve: Curves.easeOutBack,
          builder: (_, t, child) => Transform.scale(scale: t, child: child),
          child: DecoratedBox(
            // The shadow behind the glass, the rim in front of it.
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 4))],
            ),
            position: DecorationPosition.background,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF2F4F6), width: 4),
              ),
              child: ClipOval(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: 360,
                  maxWidth: 360,
                  minHeight: g.h,
                  maxHeight: g.h,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translateByDouble(r, r, 0, 1)
                      ..scaleByDouble(k, k, 1, 1)
                      ..translateByDouble(-at.dx, -at.dy, 0, 1),
                    child: SizedBox(width: 360, height: g.h, child: _world(s, g, cam)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// How to touch now, never what: while the job plays, a sweep over the
  /// whole scene ("watch everything"); in a stop, a sweep over the same
  /// broad areas whatever the mistake (never at it).
  HintSpec? _hint() {
    final g = _geo;
    if (g == null) return null;
    return HintSpec.sweep(gateLookAreas(_moment.slot.spot, g), space: HintSpace.scene);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final live = _phase != _Phase.intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp || (_phase == _Phase.what && _whatOpts.isNotEmpty);
    final watching = live && (_phase == _Phase.play || _phase == _Phase.travel || _phase == _Phase.redo) && !coworkerOnScreen && _card == null;
    final spotting = live && _phase == _Phase.spot && !coworkerOnScreen && _card == null && !tableBusy;
    final showStop = live && _phase == _Phase.play && !_listened && _card == null && !coworkerOnScreen;
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
              labels: [for (var i = 0; i < _run.deal.moments.length; i++) enDigits('${GateLines.momentLabel} ${i + 1}')],
              done: {for (var i = 0; i < math.min(_run.index, _run.deal.moments.length); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            animation: Listenable.merge([if (!quiet) _play, _travel, _harm]),
            hint: _hint,
            hintWaiting: watching || spotting,
            hintKey: spotting ? 'spot-${_run.index}' : 'watch',
            hintController: _hints,
            layers: (context, m) => _scene(m),
            overlays: [
              // Below the docket chip (pad.top + 84), so the ◆ pill is never covered.
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (_phase != _Phase.intro && _mark == null)
                Positioned(
                  key: const ValueKey('docket-chip'),
                  left: 12,
                  top: pad.top + 84,
                  child: IgnorePointer(child: _DocketChip(docket: _docket)),
                ),
              if (showStop)
                Positioned(
                  key: const ValueKey('hud-stop'),
                  left: 14,
                  bottom: pad.bottom + 14,
                  width: math.min(220.0, size.width * 0.56),
                  child: _StopButton(onTapUp: (d) => _stopPressed(d.globalPosition)),
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
                                key: ValueKey('what-deck-${_run.index}'),
                                options: _whatOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _whatWrong,
                                picked: _whatPicked,
                                onPick: (o, at) => unawaited(_pickWhat(o, at)),
                              ),
                  ),
                ),
              if (live && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
                  line: GateLines.intro,
                  alarm: 'sounds/learn/card_deal_a.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _phase = _Phase.travel);
                    _start();
                  },
                ),
                Positioned(
                  key: const ValueKey('intro-docket'),
                  left: 24,
                  right: 24,
                  top: pad.top + 66,
                  child: IgnorePointer(child: _DocketCard(docket: _docket, quiet: quiet)),
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
}

// ============================================================================
// Pieces
// ============================================================================

/// The big stop-work button (≥ 48 dp), red: the watcher's right.
class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: GateLines.stop,
      child: Material(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        shadowColor: const Color(0x99000000),
        child: InkWell(
          key: const ValueKey('gate-stop'),
          borderRadius: BorderRadius.circular(16),
          onTapUp: onTapUp,
          onTap: () {},
          child: Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFCDD2), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.back_hand_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(GateLines.stop, style: bangla(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The docket on the intro: the day's job (dealt).
class _DocketCard extends StatelessWidget {
  const _DocketCard({required this.docket, required this.quiet});
  final GateDocket docket;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_rounded, color: Color(0xFF7A1F1F), size: 22),
                const SizedBox(width: 6),
                Text(GateLines.docket, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F))),
              ],
            ),
            const SizedBox(height: 6),
            Text(GateLines.docketLine(docket), style: bangla(fontSize: 17, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.3)),
            const SizedBox(height: 2),
            Text(docket.job, style: bangla(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF5A4636), height: 1.3)),
          ],
        ),
      ),
    );
  }
}

/// The docket, small, under the header while the job runs (a worker reads it).
class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.docket});
  final GateDocket docket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFBEF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB08A4A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_rounded, color: Color(0xFF7A1F1F), size: 16),
          const SizedBox(width: 5),
          Text(GateLines.docketLine(docket), style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: SlmColors.ink)),
        ],
      ),
    );
  }
}

/// A word said (or a sound heard) in the scene.
class _SceneBubble extends StatelessWidget {
  const _SceneBubble({required this.text, required this.sound});
  final String text;
  final bool sound;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sound ? const Color(0xE61C2433) : const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sound ? const Color(0xFFFFD34E) : const Color(0xFF3A4660), width: 1.2),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Text(
          enDigits(text),
          textAlign: TextAlign.center,
          style: bangla(
            fontSize: sound ? 17 : 13.5,
            fontWeight: FontWeight.w900,
            color: sound ? const Color(0xFFFFE082) : SlmColors.ink,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

/// The crew lead after a needless stop.
class _LeadSays extends StatelessWidget {
  const _LeadSays({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: 0.8 + 0.2 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 9),
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3E6E9E), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFF3E6E9E), borderRadius: BorderRadius.circular(999)),
              child: Text(GateLines.crewLead, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(height: 4),
            Text(GateLines.allFine, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// The scene held still after a stop: a cool frame, nothing pointed at.
class _StopTint extends StatelessWidget {
  const _StopTint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xCCC62828), width: 4),
        gradient: const RadialGradient(colors: [Color(0x00000000), Color(0x40112040)], radius: 1.1),
      ),
    );
  }
}

/// The rank-up: ট্রেইনি → জুনিয়র.
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
            Text(GateLines.rankUp, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.gold200)),
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward_rounded, color: SlmColors.gold300, size: 24),
                ),
                const Icon(Icons.military_tech_rounded, color: SlmColors.gold300, size: 30),
                const SizedBox(width: 4),
                Flexible(child: Text(to, style: bangla(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
