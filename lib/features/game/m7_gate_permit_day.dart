import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
import 'm7_gate_permit_day_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

// Module 7 rank gate (rung m7/gate, pack gate_m7, engineType
// m7_gate_permit_day): "সুপারভাইজারের ডকেট: সইয়ের দায়" — one shutdown job
// from the permit to its return, one verb: the player is today's permit
// receiver and every step waits for his signature on the field copy of the
// PTW, docked at the bottom edge: swipe UP = এগোন, swipe DOWN = থামান
// (lessons 7.1–7.10; spec docs/module_specs/module7_items/gate_m7.json, rulings
// docs/module_specs/module7_rulings.md — the rulings win; the live lesson text
// wins over the spec's quotes, X3).
//
// The scene is one continuous drawn world with three spots the camera pans
// between: (A) the issuing counter, (B) a para lane with the lane DTR (its AB
// switch opened, all three blades seen, handle locked and tagged, HG fuses —
// never DO, M7-9) and the main-road line fed by a different DTR whose AB switch
// is closed, (C) back at the counter in the late afternoon. Ten steps per
// play: F1 permit first, F12 line return last, eight more from F2–F11/F13/F14
// in day order (each lesson once where it can be), 4–6 of 10 lawful and one or
// two deadly-class unlawful versions. At every step someone stops and looks at
// the player; the guide asks the same 'এগোতে দেবেন?'. Look (free): tap anything
// for a close-up of its real markings. Right 'এগোন' on a lawful step: the act
// plays; only the first right 'এগোন' puts ◆ on the table ('কেন এগোতে
// দিলেন?'). Right 'থামান' on an unlawful step: the crew freezes, the guide asks
// 'কোথায় আইন ভাঙছে?', a tap on the breach puts ◆ on the table and opens the fix
// deck 'আইন মতো এখন কী?' → the lawful fix plays. A needless stop, a tap on a
// compliant object after 'থামান' and a wrong 'এগোন' on a slip-class step are
// slips; a wrong 'এগোন' on a deadly-class step freezes the scene. The
// coworker comes once on a dealt slip-class fork (his myth word for word); the
// first swipe on the field copy waits for him (listening = a slip and the step
// resolves as 'এগোন'). After F12 the closing reason.
//
// Scoring as the module's levels: ◆ 15 per reason, +10 for a right plain
// 'এগোন', the coworker refused +10, slip −10, pass +20, quick bonus +10;
// mark 100 − 15 × slips (pass ≥ 55); 3 slips strike out; a deadly move
// freezes the scene. The quick-bonus time (4 min 45 s) is the builder's
// estimate, about 85 % of a clean play.
//
// Every spoken line is listed in M7GateLines.newGuideLines / newRivalLines /
// newCrewLines (DRAFT wording — owner, M6-12).

// ============================================================================
// Content
// ============================================================================

/// The forks (F1 … F14 of the spec) in the spec's order.
enum M7GFork { permit, climber, kit, door, inside, seal, hook, line, oil, waste, accident, ret, jobSheet, logbook }

/// A version's class.
enum M7GClass { lawful, slip, deadly }

extension M7GForkFacts on M7GFork {
  /// Spec number (F1–F14).
  int get no => index + 1;

  /// The spot the camera shows: 0 = A counter (morning), 1 = B lane, 2 = C counter (late).
  int get spot => switch (this) {
        M7GFork.permit || M7GFork.climber || M7GFork.kit => 0,
        M7GFork.logbook || M7GFork.ret => 2,
        _ => 1,
      };

  /// The lesson that teaches it.
  String get lesson => switch (this) {
        M7GFork.permit || M7GFork.ret || M7GFork.logbook => '7.4',
        M7GFork.climber => '7.10',
        M7GFork.kit => '7.6',
        M7GFork.door || M7GFork.inside || M7GFork.jobSheet => '7.9',
        M7GFork.seal || M7GFork.hook => '7.5',
        M7GFork.line => '7.3',
        M7GFork.oil || M7GFork.waste => '7.8',
        M7GFork.accident => '7.7',
      };

  /// The fix deck's wrong-card group.
  String get group => switch (this) {
        M7GFork.permit => 'g1',
        M7GFork.climber => 'g2',
        M7GFork.kit => 'g3',
        M7GFork.door || M7GFork.inside => 'g45',
        M7GFork.seal || M7GFork.hook => 'g67',
        M7GFork.line => 'g8',
        M7GFork.oil || M7GFork.waste => 'g910',
        M7GFork.accident => 'g11',
        M7GFork.ret || M7GFork.jobSheet || M7GFork.logbook => 'g12',
      };

  /// Day order of the middle forks.
  int get dayOrder => switch (this) {
        M7GFork.permit => 0,
        M7GFork.climber => 1,
        M7GFork.kit => 2,
        M7GFork.door => 3,
        M7GFork.inside => 4,
        M7GFork.seal => 5,
        M7GFork.hook => 6,
        M7GFork.line => 7,
        M7GFork.oil => 8,
        M7GFork.waste => 9,
        M7GFork.accident => 10,
        M7GFork.jobSheet => 11,
        M7GFork.logbook => 12,
        M7GFork.ret => 13,
      };

  /// A slip-class fork type the coworker may come on.
  bool get coworkerFork => const {M7GFork.climber, M7GFork.kit, M7GFork.door, M7GFork.seal, M7GFork.line, M7GFork.oil, M7GFork.accident}.contains(this);

  bool get hasDeadly => const {M7GFork.permit, M7GFork.kit, M7GFork.hook, M7GFork.ret}.contains(this);
}

abstract final class M7GateLines {
  static const title = 'সুপারভাইজারের ডকেট: সইয়ের দায়';

  /// The gate's badge: the 7.x lessons' badge (M7-13).
  // OWNER may rename
  static const badge = 'আইন কি বলে?';

  // The ranks (fallbacks when the catalog is not loaded).
  static const rankFrom = 'সিনিয়র';
  static const rankTo = 'সুপারভাইজার';
  static const rankUp = 'নতুন র‍্যাঙ্ক!';

  /// Spoken on the pass. DRAFT wording — owner.
  static String promoted(String rank) => badge.isEmpty ? 'অভিনন্দন! আপনি এখন $rank।' : 'অভিনন্দন! আপনি এখন $rank। ব্যাজ: $badge';

  // DRAFT wording — owner (M6-12), every line below.
  static const intro = 'আজ একটা পুরো কাজের দায় আপনার সইয়ে — পারমিট নেওয়া থেকে ফেরত দেওয়া পর্যন্ত। প্রতিটা পা আইন মেনে।';
  static const ask = 'এগোতে দেবেন?';
  static const haltAsk = 'কোথায় আইন ভাঙছে?';
  static const lensClose = 'দেখা হলে বন্ধ করুন।';
  static const tapTasks = [
    'আপনার সইয়েই কাজ চলছে — দেখে সিদ্ধান্ত নিন।',
    'কাগজ, লোক, জায়গা — যা দেখার দেখে নিন।',
    'আইন মানা থাকলে এগোন, না থাকলে থামান।',
  ];
  static const tapWhy = ['ঠিক কারণটা কোনটা?', 'কেন করলেন, বেছে নিন।'];

  // The ◆ questions (spoken).
  static const whyGoQ = 'কেন এগোতে দিলেন?';
  static const fixQ = 'আইন মতো এখন কী?';
  static const closeQ = 'আজকের সইয়ে আপনি কী দায় নিয়েছিলেন?';
  static const questions = [whyGoQ, fixQ, closeQ];

  static const refused = 'ঠিক! আমার সইয়ে কাজ, আইন না মেনে নয়।';
  static const fail = 'আরেকবার — আইন মানা আছে কি না দেখে, তবে সই।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerAsk = 'ওঁর কথা শুনবেন?';

  // Labels a worker reads.
  static const fieldCopy = 'ফিল্ড কপি';
  static const controlCopy = 'কন্ট্রোল রুম কপি';
  static const close = 'বন্ধ';
  static const docketTitle = 'ডকেট';
  static String docketCall(int ptw) => enDigits('PTW নং $ptw · 11 kV শাটডাউন · লাইন বন্ধ');
  static const noticeGiven = 'নোটিশ: দেওয়া হয়েছে';
  static const noticeNot = 'নোটিশ: দেওয়া হয়নি';
  static const agencySign = 'অনুমোদিত রিসাইক্লিং এজেন্সি';
  static const gloveCuff = 'IS 4770 · টাইপ 4';
  static const gloveCuffLow = 'IS 4770 · টাইপ 2';
  static const helmetPrint = 'IS 2925';
  static const jobSheetName = 'জব শিট';
  static String ptwNo(int n) => enDigits('PTW নং $n');

  /// What each crew member says as he stops and looks at the player (the same
  /// on a lawful and an unlawful version). DRAFT — owner.
  static String crew(M7GFork f) => switch (f) {
        M7GFork.permit => 'লাইন বন্ধ করা আছে, এই নিন।',
        M7GFork.climber => 'আজ উনি উঠবেন।',
        M7GFork.kit => 'রেজিস্টারে সই করে নিয়ে যান।',
        M7GFork.door => 'ঢুকে পড়ি?',
        M7GFork.inside => 'এই দিকে যাই?',
        M7GFork.seal => 'পুরনোটা খুলে নতুনটা বসাই?',
        M7GFork.hook => 'হুকটা টেনে খুলে দিই?',
        M7GFork.line => 'চলো, পোলের দিকে যাই।',
        M7GFork.oil => 'ভালভ খুলি?',
        M7GFork.waste => 'এগুলো তুলে দিই?',
        M7GFork.accident => 'কাজ চালাই?',
        M7GFork.ret => 'কাজ শেষ — PTW ফেরত দিয়ে লাইন চালু করতে বলি?',
        M7GFork.jobSheet => 'চলুন?',
        M7GFork.logbook => 'ঠিক আছে, লিখে রাখছি।',
      };

  /// Words a worker says in a scene (on the person, not a crew call).
  static const ownerYes = 'আসুন';
  static const ownerNo = 'এখন না';

  /// "আজ যা ধরলেন" — from the player's own moves (on screen only).
  static String caught(M7GFork f) => switch (f) {
        M7GFork.permit => 'সই করা PTW ছাড়া কাজ নয়',
        M7GFork.climber => 'যোগ্য আর অনুমোদিত লোকই লাইনে',
        M7GFork.kit => 'IS 4770 গ্লাভস, IS 2925 হেলমেট',
        M7GFork.door => 'নোটিশ আর সম্মতি ছাড়া ঢোকা নয়',
        M7GFork.inside => 'কন্ডুইটের পথেই, অন্য ঘরে নয়',
        M7GFork.seal => 'সিল-চুম্বক দেখলে জানান',
        M7GFork.hook => 'শাটডাউন, 0 V, আর্থ, তারপর হুক',
        M7GFork.line => 'লাইনের নিচে কাজ নয়',
        M7GFork.oil => 'প্যাড-বুম আর বন্ধ ড্রাম',
        M7GFork.waste => 'অনুমোদিত এজেন্সির গাড়িতে',
        M7GFork.accident => 'সাথে সাথে জানানো, কিছু না সরানো',
        M7GFork.ret => 'সবাই নামলে তবেই PTW ফেরত',
        M7GFork.jobSheet => 'গ্রাহকের সই নিয়ে জব শিট',
        M7GFork.logbook => 'বাঁধানো লগবুকে লেখা',
      };
  static const caughtPush = 'চাপে নিয়ম ভাঙা নয়';
  static const caughtClose = 'সই মানেই দায়';

  // --- the option libraries (generated, then length-checked: every set within 1.3×) --
  /// Habit, hurry, orders, a guess: the wrong cards of every reason deck (and the base of every fix deck's wrong cards).
  static const excuses = [
      'সবাই তো এভাবেই করে, তাই এগিয়ে যাই এখন',
      'তাড়া আছে, তাই সহজটাই বেছে নিয়ে ফেলি',
      'অফিস বলেছে, তাই চোখ বুজে করে ফেলি',
      'আন্দাজে মনে হলো, তাই এটাই করে ফেলি',
      'আগেরবারও এভাবেই চলেছিল, তাই চালাই',
      'কেউ তো দেখছে না, তাই এগিয়ে যাই এবার',
    ];
  /// The right cards of each fix deck ('আইন মতো এখন কী?'), per breach.
  static const fixRight = <String, List<String>>{
    'permit.blank': [
      'ইস্যুকারীকে দিয়ে ফিল্ড কপিতে সই করাই',
      'সই না হওয়া পর্যন্ত কপি ফেরত দিয়ে থামি',
    ],
    'permit.verbal': [
      'মুখের কথায় নয়, সই করা লিখিত PTW চাই',
      'কাগজের PTW না পেলে কাজ শুরুই হবে না',
    ],
    'permit.numbers': [
      'দুই কপির নম্বর মিলিয়ে ঠিক করিয়ে নিই',
      'নম্বর না মেলা অবধি নতুন কপি চেয়ে নিই',
    ],
    'climber': [
      'প্রশিক্ষিত আর অনুমোদিত লোককেই ওঠাই',
      'সব কাগজ ঠিক না হলে ওঁকে নিচে রাখি',
    ],
    'kit.glove': [
      'অটুট IS 4770 টাইপ 4 গ্লাভস বদলে নিই',
      'ছেঁড়া বা কম রেটিংয়ের গ্লাভস ফেরত দিই',
    ],
    'kit.helmet': [
      'IS 2925 ছাপের হেলমেট চেয়ে নিয়ে সই করি',
      'বাজারের হেলমেট ফেরত, স্টোরেরটাই নিই',
    ],
    'door': [
      'আগে নোটিশ আর অনুমতি, তারপরই ঢুকব',
      'গ্রাহকের সম্মতি ছাড়া এক পা-ও নয়',
    ],
    'inside': [
      'কন্ডুইট যেদিকে যায়, শুধু সেদিকেই যাই',
      'যে ঘরে কাজ নেই, সেখানে ঢুকব না',
    ],
    'seal': [
      'মিটার বদল থামিয়ে সুপারভাইজারকে জানাই',
      'সিল-চুম্বকের কথা ভিজিল্যান্সকেও জানাই',
    ],
    'hook.order': [
      'কর্তৃপক্ষের লিখিত আদেশ আগে হাতে নিই',
      'আদেশ ছাড়া হুকে হাত দেবে না কেউ',
    ],
    'hook.owner': [
      'চোরের মুখোমুখি নয়, ভিজিল্যান্সকে কাজ দিই',
      'মালিকের দরজায় নয়, নিয়ম মেনে কাজ করি',
    ],
    'hook.live': [
      'এই লাইন চালু, হুক ছোঁবে না কেউ এখন',
      'আগে শাটডাউন, 0 V, আর্থ — তারপর হুক',
    ],
    'hook.earth': [
      '0 V দেখেছি, আগে আর্থ লাগাই, তারপর হুক',
      'আর্থ ছাড়া হুক নয়, আগে আর্থ সেট করি',
    ],
    'hook.test': [
      'আগে টেস্টারে 0 V দেখাও, তবে হুকে হাত',
      'লাইভ-ডেড-লাইভ টেস্ট না হলে হাত নয়',
    ],
    'line': [
      'কাজ থামিয়ে সরে দাঁড়াতে বলে জানাই',
      'লাইনের নিচে কাজ নয়, সুপারভাইজারকে জানাই',
    ],
    'oil': [
      'শোষক প্যাড-বুম পেতে বন্ধ ড্রামে ঢালি',
      'তেল শুধু লিক-প্রুফ বন্ধ ড্রামেই ধরি',
    ],
    'waste': [
      'অনুমোদিত এজেন্সির গাড়িতেই তুলে দিই',
      'তেলের প্যাড বিপজ্জনক বর্জ্যের বিনে দিই',
    ],
    'accident': [
      'আহতকে ডাক্তারের কাছে, সুপারভাইজারকে জানাই',
      'এখনই সুপারভাইজারকে জানাই, কিছু সরাব না',
    ],
    'ret': [
      'আগে সবাইকে নামিয়ে গুনে নিই, তারপর ফেরত',
      'কেউ ওপরে থাকলে এখন PTW ফেরত দেব না',
    ],
    'jobSheet': [
      'গ্রাহকের সই নিয়ে জব শিট পূর্ণ করাই',
      'সই ছাড়া জব শিট জমা নেওয়া হবে না',
    ],
    'logbook': [
      'ছেঁড়া কাগজ নয়, বাঁধানো লগবুকে লিখি',
      'বাঁধানো লগবুকেই তারিখ আর সময় লিখি',
    ],
  };
  /// The fix decks' own wrong cards per group (the excuses are added).
  static const fixWrong = <String, List<String>>{
    'g1': [
      'উনি সিনিয়র মানুষ, বিশ্বাস করেই নিয়ে নিই',
      'কাজ শুরু হোক, সই পরে করিয়ে নেওয়া যাবে',
      'নম্বর যা-ই হোক, কপি দুটো রেখে দিই শুধু',
    ],
    'g2': [
      'অভিজ্ঞ লোক, কাগজ ছাড়াই ওঠা চলে ওঁর',
      'আজকের মতো উঠুক, কাল কাগজ দেখে নেব',
      'শাটডাউনের কাজ, ওতে কাগজ লাগে না তো',
    ],
    'g3': [
      'হেলমেট তো মাথায় আছে, ছাপ দেখার কী',
      'গ্লাভসে ছোট ছেঁড়া আছে, চালিয়ে নেব',
      'স্টকে নেই বলছে, বাজারেরটাই চলুক আজ',
    ],
    'g45': [
      'কাজ করতে এসেছি, ভেতরে ঢুকে পড়ি তো',
      'বাড়িতে লোক নেই, দেয়াল টপকে যাই না',
      'নোটিশ পরে দেওয়া যাবে, এখন ঢুকে পড়ি',
    ],
    'seal': [
      'সিল কাটা দেখেও মিটার বদলে ফেলি এখনই',
      'মিটার বদলে দিই, জানালে ঝামেলা বাড়বে',
      'সিল-চুম্বক নিয়ে মালিকের সঙ্গে কথা বলি',
    ],
    'hook.order': [
      'লিখিত আদেশ পরে আসবে, আগে হুক খুলে দিই',
      'অফিসের মুখের কথাই যথেষ্ট, হুক খুলি',
      'শাটডাউন তো আছেই, আদেশ ছাড়াই হুক খুলি',
    ],
    'hook.owner': [
      'মালিককে ধরে জিজ্ঞেস করি, কেন কাটা',
      'চোরকে ডেকে সামনেই হুক খুলতে বলি',
      'পুলিশ ডাকার আগে নিজেই মালিককে ধরি',
    ],
    'hook.live': [
      'গ্লাভস আছে, চালু লাইনের হুক খুলে দিই',
      'লাইনে ভোল্টেজ কম, হুক খুলে ফেলি এখনই',
      'আগে হুক খুলি, পরে টেস্টারে দেখে নেব',
    ],
    'hook.earth': [
      '0 V দেখেছি, আর্থ ছাড়াই হুক খুলে দিই',
      'আর্থ লাগাতে সময় লাগে, হুক খুলে ফেলি',
      'টেস্টার ঠিক বলেছে, আর্থ আর লাগাব না',
    ],
    'hook.test': [
      'শাটডাউন হয়েছে, টেস্টার ছাড়াই খুলে দিই',
      'আর্থ লাগিয়েছি, তাই 0 V দেখা লাগবে না',
      'গ্লাভস পরে আন্দাজেই হুক ধরে খুলে ফেলি',
    ],
    'g8': [
      'ক্লিয়ারেন্স কম হলেও কাজ চালিয়ে নিই',
      'তার ছুঁয়ে নেই, এভাবেই থাকুক',
      'কাপড়টা একটু সরালেই হবে, জানানো কেন',
    ],
    'oil': [
      'তেল মাটিতে শুষে যাবে, প্যাড কেন লাগবে',
      'নর্দমায় ঢেলে দিলেই তো সরে যাবে তেল',
      'খোলা বালতিতে ধরি, ড্রাম আনতে দেরি হবে',
    ],
    'waste': [
      'যেকোনো গাড়িতে তুললেই তো সরে যাবে',
      'সাধারণ ডাস্টবিনে ফেলে দিলেই আপদ বিদায়',
      'গাড়ি যার-ই হোক, তুলে দিলেই কাজ শেষ',
    ],
    'g11': [
      'ছোট কাটা, ব্যান্ডেজ করে কাজে লাগাই',
      'রিপোর্ট করলে সবার চাকরি যাবে, চুপ থাকি',
      'আগে জিনিসপত্র গুছিয়ে রাখি, পরে জানাব',
    ],
    'ret': [
      'সবাই নিচে আছে ধরে নিয়ে PTW ফেরত দিই',
      'গুনতে সময় লাগে, তাড়াতাড়ি ফেরত দিয়ে দিই',
      'অন্ধকার হচ্ছে, আগে লাইন চালু করতে বলি',
    ],
    'jobSheet': [
      'সই পরে নেব, এখন জব শিট জমা দিয়ে দিই',
      'গ্রাহক ব্যস্ত, তাই নিজেই জব শিটে সই করি',
      'সই ছাড়াই জব শিট ফাইলে তুলে রেখে দিই',
    ],
    'logbook': [
      'ছেঁড়া কাগজেই লিখে রাখি, পরে তুলে নেব',
      'লগবুক পরে লিখব, এখন মনে রেখে দিই',
      'তারিখ মনে আছে, লগবুকে না লিখলেও চলে',
    ],
  };
  /// Which group's wrong cards a fix key takes.
  static const fixGroup = <String, String>{
    'permit.blank': 'g1',
    'permit.verbal': 'g1',
    'permit.numbers': 'g1',
    'climber': 'g2',
    'kit.glove': 'g3',
    'kit.helmet': 'g3',
    'door': 'g45',
    'inside': 'g45',
    'seal': 'seal',
    'hook.order': 'hook.order',
    'hook.owner': 'hook.owner',
    'hook.live': 'hook.live',
    'hook.earth': 'hook.earth',
    'hook.test': 'hook.test',
    'line': 'g8',
    'oil': 'oil',
    'waste': 'waste',
    'accident': 'g11',
    'ret': 'ret',
    'jobSheet': 'jobSheet',
    'logbook': 'logbook',
  };
  /// The right cards of 'কেন এগোতে দিলেন?' per fork.
  static const whyGoRight = <String, List<String>>{
    'permit': [
      'দুই কপিতেই সই আর নম্বর এক, তাই এগোলাম',
      'লিখিত সই করা PTW হাতে আছে, তাই এগোলাম',
    ],
    'climber': [
      'সার্টিফিকেট, রেজিস্টার, প্রশিক্ষণ সবই ঠিক',
      'যোগ্য আর অনুমোদিত লোক, তাই উঠতে দিলাম',
    ],
    'kit': [
      'গ্লাভস IS 4770 টাইপ 4, হেলমেটে IS 2925',
      'অটুট গ্লাভস আর ছাপ-দেওয়া হেলমেট দেখে সই',
    ],
    'door': [
      'নোটিশ দেওয়া, আইডি দেখানো, সম্মতিও আছে',
      'সম্মতি আর নোটিশ আছে, তাই ঢুকতে দিলাম',
    ],
    'inside': [
      'যেদিকে কন্ডুইট গেছে, শুধু সেদিকেই যাচ্ছে',
      'কাজের পথেই আছে, অন্য ঘরে ঢুকছে না',
    ],
    'seal': [
      'সিল অটুট, মুখে চুম্বক নেই, বদলানো চলে',
      'সিল আর মিটারের মুখ ঠিক দেখে এগোতে দিলাম',
    ],
    'hook': [
      'শাটডাউন, 0 V, আর্থ, আদেশ আর PPE সব আছে',
      'এই লাইন ডেড প্রমাণ হয়েছে, আদেশও আছে',
    ],
    'line': [
      'ছাদের কাছে কোনো লাইন নেই, কাজ চলতে পারে',
      'ওপরে কোনো তার নেই দেখে এগোতে দিলাম',
    ],
    'oil': [
      'প্যাড, বুম আর বন্ধ ড্রাম আছে, তাই এগোলাম',
      'শোষক প্যাড আর বন্ধ ড্রাম দেখেই এগোলাম',
    ],
    'waste': [
      'অনুমোদিত এজেন্সির গাড়ি, আলাদা বিনে প্যাড',
      'এজেন্সির বোর্ড, বিনের লেবেল দেখে এগোলাম',
    ],
    'accident': [
      'আহত ডাক্তারের কাছে যাচ্ছে, জানানো হচ্ছে',
      'ঘটনা জানানো আর লেখা হচ্ছে, তাই এগোলাম',
    ],
    'ret': [
      'সবাই নেমেছে, তাই PTW ফেরত দিতে দিলাম',
      'সবাইকে নিচে দেখে তবেই ফেরত দিতে দিলাম',
    ],
    'jobSheet': [
      'গ্রাহক জব শিটে সই করেছেন, কাজ আইন মতো',
      'জব শিটে সই আছে, তাই এগোতে দিলাম',
    ],
    'logbook': [
      'বাঁধানো লগবুকে তারিখ আর সময় লেখা আছে',
      'লগবুকে লেখা দেখে তবেই এগোতে দিলাম',
    ],
  };
  static const closingRight = [
      'প্রতিটা ধাপ আইন মেনে সই করেছি, দায় আমার',
      'আমার সই মানেই দায়, তাই দেখে-বুঝে সই',
    ];
  static const cwRight = [
      'না — নিজে দেখে, আইন মেনে তবেই এগোতে দেব',
      'না — আমার সইয়ে কাজ, আইন না মেনে নয়',
    ];
  static const cwWrong = [
      'ঠিকই বলছ, এত দেখার দরকার নেই আর',
      'চলো, দেরি হয়ে যাচ্ছে, সই করে দিয়ে দিই',
      'আইন তো কাগজেই থাকে, মাঠে কে মানে বলো',
      'সবাই তো এভাবেই করে, তুমি ঠিকই বলছ',
      'কেউ তো দেখছে না, এভাবেই এগিয়ে যাই',
    ];

  /// The fix deck's wrong cards for [fixKey]'s group (its own and the excuses).
  static List<String> fixWrongOf(String fixKey) => [...?fixWrong[fixGroup[fixKey]], ...excuses];

  /// Past-tense habit, hurry, orders, a guess: the base of every 'কেন এগোতে দিলেন?' deck.
  static const whyExcuses = [
    'সবাই তো এভাবেই করে, তাই এগোতে দিলাম',
    'তাড়া ছিল, তাই সহজটাই বেছে নিলাম',
    'অফিস বলেছিল, তাই চোখ বুজে এগোলাম',
    'আন্দাজে ঠিকই মনে হলো, তাই এগোলাম',
    'আগেরবারও এভাবেই চলেছিল, তাই দিলাম',
    'কেউ দেখছিল না, তাই এগিয়ে যেতে দিলাম',
  ];
  /// Plausible wrong reasons per fork (and 'closing'), past tense, on topic.
  static const whyGoWrong = <String, List<String>>{
    'permit': [
      'ক্রুর লোক বলল লাইন বন্ধ, তাই এগোলাম',
      'শুধু কন্ট্রোল রুমের কপি দেখে এগোলাম',
      'নম্বর আছে দেখে, সই না দেখেই এগোলাম',
    ],
    'climber': [
      'অভিজ্ঞ লোক, কাগজ না দেখলেও চলে ভাবলাম',
      'বয়স দেখে ঠিক মনে হলো, তাই উঠতে দিলাম',
      'শুধু নাম রেজিস্টারে দেখে উঠতে দিলাম',
    ],
    'kit': [
      'নতুন দেখতে গ্লাভস, তাই আর ছাপ দেখিনি',
      'হেলমেট মাথায় আছে, ছাপ না দেখলেও চলে',
      'দোকানের জিনিসও ভালো, তাই সই করে দিলাম',
    ],
    'door': [
      'কাজে এসেছি, তাই ঢুকতে দিলাম গেট খুলে',
      'নোটিশ পরে দেওয়া যাবে ভেবে ঢুকতে দিলাম',
      'আইডি কার্ড গলায় আছে, তাই এগোতে দিলাম',
    ],
    'inside': [
      'ঘরে কেউ নেই, তাই যে ঘরে খুশি চলবে',
      'ভেতরের ঘরও কাছে, তাই যেতে দিলাম',
      'পর্দা সরালেই সোজা পথ, তাই যেতে দিলাম',
    ],
    'seal': [
      'সিল একটু ঢিলা, তবু বদলানো চলে ভাবলাম',
      'মিটারের মুখে কিছু আছে, কাউকে বলিনি',
      'বদলে দিলেই তো সমস্যা মিটে যায়, তাই',
    ],
    'hook': [
      'শাটডাউন আছে, তাই টেস্টার ছাড়াই এগোলাম',
      '0 V দেখলাম, আর্থ না লাগালেও চলে ভাবলাম',
      'হুকের লাইন চালু, তবে গ্লাভস ছিল, তাই',
    ],
    'line': [
      'নিচে লাইন আছে, তবু উঁচুতে নয় বলে এগোলাম',
      'তার একটু দূরে, তাই কাজ চলতে দিলাম',
      'ছাদে লাইন ছিল, তবু সাবধানে করবে ভাবলাম',
    ],
    'oil': [
      'একটু তেল পড়েছে, মাটি শুষে নেবে ভাবলাম',
      'নর্দমায় ঢেলে দিলেই তো সরে যায়, তাই',
      'বালতিতে ঢাকনা ছাড়া ঢাললেও চলে ভাবলাম',
    ],
    'waste': [
      'যেকোনো গাড়িতে তুললেই হয় ভেবে এগোলাম',
      'সাধারণ বিনে ফেললেও চলে ভেবে এগোলাম',
      'গাড়ি এসেছে, কার গাড়ি দেখিনি আর',
    ],
    'accident': [
      'ছোট চোট, ব্যান্ডেজ করে কাজ চালালাম',
      'কাজ পিছিয়ে যাবে, তাই জানাতে বারণ করলাম',
      'রিপোর্টে সবার চাকরি যেত, তাই চুপ থাকলাম',
    ],
    'ret': [
      'সবাই নিচেই আছে ধরে নিয়ে ফেরত দিলাম',
      'গুনতে সময় লাগে, তাই গুনে দেখিনি আর',
      'অন্ধকার হয়ে আসছিল, তাই তাড়াতাড়ি ফেরত',
    ],
    'jobSheet': [
      'গ্রাহক ভালো মানুষ, সই পরে নেওয়া যাবে',
      'কাজ ঠিক হয়েছে, সইয়ের আর দরকার নেই',
      'জব শিট পূরণ হয়েছে, সই না হলেও চলে',
    ],
    'logbook': [
      'ছেঁড়া কাগজেই লেখা আছে, এতেই চলে ভাবলাম',
      'তারিখ মনে আছে, লগবুকে পরে লিখব ভাবলাম',
      'কাজ হয়ে গেছে, লগবুক না লিখলেও চলে',
    ],
    'closing': [
      'আমার দায় শুধু কাগজে সই করে দেওয়া',
      'দায় আমার নয়, যে ওঠে সে নিজেই দেখবে',
      'সই করলে দায় অফিসের, আমার তো নয়',
      'আমার দায় কাজ তাড়াতাড়ি শেষ করানো',
    ],
  };

  /// The wrong cards of a reason deck ([key]: a fork name or 'closing').
  static List<String> whyWrongOf(String key) => [...?whyGoWrong[key], ...whyExcuses];

  // --- the careless coworker (his recorded voice) --------------------------------
  static const _asks = [coworkerAsk];

  static CoworkerScript _cw(String line) => CoworkerScript(line: line, exitLine: coworkerExit, right: cwRight, wrong: cwWrong, asks: _asks);

  /// F2: lesson 7.10 myth 2, word for word.
  static final pushClimber = _cw('লাইসেন্স বা সার্টিফিকেট তো শুধু কাগজে দেখানোর জন্য, আসল তো হলো কাজের অভিজ্ঞতা।');

  /// F3: lesson 7.6 myth 1.
  static final pushKit = _cw('কোম্পানি ভালো PPE দেয় না, তাই আমি বাজার থেকে সস্তার একটা কিনে ব্যবহার করি।');

  /// F4: lesson 7.9 myth 1.
  static final pushDoor = _cw('গ্রাহকের বাড়িতে কাজ করতে এসেছি, তার মানে আমি যেকোনো জায়গায় যেতে পারি এবং যেকোনো কিছু করতে পারি।');

  /// F6: lesson 7.5 myth 2.
  static final pushSeal = _cw('বিদ্যুৎ চোরকে ধরা আমার কাজ নয়, ওটা পুলিশের কাজ।');

  /// F8: lesson 7.3 myth 2.
  static final pushLine = _cw('ক্লিয়ারেন্স একটু কম হলে কিছু হয় না, কেউ তো আর মাপতে আসছে না।');

  /// F9: lesson 7.8 myth 1.
  static final pushOil = _cw('একটু তেল মাটিতে পড়লে কিছু হয় না, মাটি তো শুষে নেয়।');

  /// F11: lesson 7.7 myth 1.
  static final pushAccident = _cw('দুর্ঘটনা রিপোর্ট করলে আমার বা আমার সুপারভাইজারের চাকরি চলে যেতে পারে, তাই চুপ করে থাকাই ভালো।');

  static CoworkerScript script(M7GFork f) => switch (f) {
        M7GFork.climber => pushClimber,
        M7GFork.kit => pushKit,
        M7GFork.door => pushDoor,
        M7GFork.seal => pushSeal,
        M7GFork.line => pushLine,
        M7GFork.oil => pushOil,
        M7GFork.accident => pushAccident,
        _ => pushClimber,
      };

  static final coworkers = [pushClimber, pushKit, pushDoor, pushSeal, pushLine, pushOil, pushAccident];

  /// His pushes (the director records the ones with no clip yet with
  /// tool/rival_clip.py; until then silent, caption held).
  static List<String> get newRivalLines => [for (final s in coworkers) s.line];

  /// What the crew say at each step (shown as his words; listed for the voice pass).
  static List<String> get newCrewLines => <String>{for (final f in M7GFork.values) crew(f), ownerYes, ownerNo}.toList();

  /// Every spoken guide line (DRAFT — owner wording, then recorded). The
  /// close-ups, the crew's words and the cards' texts are shown, not spoken.
  static List<String> get newGuideLines => <String>{
        intro,
        ask,
        haltAsk,
        lensClose,
        ...tapTasks,
        ...tapWhy,
        ...questions,
        refused,
        fail,
        deadlyWord,
        nearMissWord,
        coworkerAsk,
        promoted(rankTo),
        for (final m in M7GMistakes.all) m.textBn,
      }.toList();
}

// ============================================================================
// Mistakes (the module table, after the rulings)
// ============================================================================

const _art = 'assets/game/art/m7_gate_permit_day';

/// One gate mistake and the lesson that teaches it.
@immutable
class M7GMistake {
  const M7GMistake(this.lessonId, this.m);
  final String lessonId;
  final DoMistake m;
}

abstract final class M7GMistakes {
  // --- deadly (DRAFT wording — owner) -----------------------------------------
  static const ptwBlank = M7GMistake('7.4', DoMistake(
    key: 'm7/gate/ptw-blank',
    textBn: 'মাঠের কপিতে ইস্যুকারীর সই নেই — কেউ লাইন বন্ধ নিশ্চিত করেনি। সই করা PTW হাতে নিয়েই তবে কাজ, নইলে প্রাণ যেতে পারে।',
    art: '$_art/ptw.svg',
    deadly: true,
    lessonPoint: 1,
  ));
  static const ptwVerbal = M7GMistake('7.4', DoMistake(
    key: 'm7/gate/ptw-verbal',
    textBn: 'শুধু মুখের কথায় "লাইন বন্ধ" — লিখিত, সই করা PTW ছাড়া কাজ শুরু করা মানেই আইন আর সুরক্ষা, দুটোই ভাঙা।',
    art: '$_art/ptw.svg',
    deadly: true,
    lessonPoint: 0,
  ));
  static const gloveBad = M7GMistake('7.6', DoMistake(
    key: 'm7/gate/glove-bad',
    textBn: 'ছেঁড়া বা কম রেটিংয়ের গ্লাভস নিয়ে 11 kV কাজে যাওয়া — প্রাণঘাতী। অটুট, IS 4770 · টাইপ 4 গ্লাভস দেখে তবে সই।',
    art: '$_art/glove.svg',
    deadly: true,
    lessonPoint: 0,
  ));
  static const hookLive = M7GMistake('7.5', DoMistake(
    key: 'm7/gate/hook-live',
    textBn: 'চালু লাইনের হুক খুলতে দেওয়া — ওই লাইনের AB লাগানো, ভোল্টেজ আছে। আগে শাটডাউন, টেস্টারে 0 V, আর্থ, তারপর হুক।',
    art: '$_art/hook.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const hookNoTest = M7GMistake('7.5', DoMistake(
    key: 'm7/gate/hook-no-test',
    textBn: 'টেস্টারে 0 V না দেখেই হুকে হাত — শাটডাউনের পরেও লাইন চালু থাকতে পারে। লাইভ-ডেড-লাইভ টেস্ট আগে।',
    art: '$_art/hook.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const hookNoEarth = M7GMistake('7.5', DoMistake(
    key: 'm7/gate/hook-no-earth',
    textBn: '0 V দেখার পরেও আর্থ না লাগিয়ে হুক খোলা — হঠাৎ ভোল্টেজ এলে বাঁচার পথ নেই। টেস্টার, তারপর আর্থ, তারপর হুক।',
    art: '$_art/hook.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const headCount = M7GMistake('7.4', DoMistake(
    key: 'm7/gate/head-count',
    textBn: 'কেউ পোলে থাকতেই PTW ফেরত আর লাইন চালু — প্রাণ যাবে। আগে সবাইকে নামিয়ে গুনে নিন, তারপর ফেরত।',
    art: '$_art/count.svg',
    deadly: true,
    lessonPoint: 1,
  ));

  // --- slips --------------------------------------------------------------------
  static const ptwNumbers = M7GMistake('7.4', DoMistake(
    key: 'm7/gate/ptw-numbers',
    textBn: 'দুই কপির PTW নম্বর আলাদা — এ কাগজ কোন কাজের, কেউ জানে না। সইয়ের আগে নম্বর মিলিয়ে নিন।',
    art: '$_art/ptw.svg',
    lessonPoint: 1,
  ));
  static const climberUnfit = M7GMistake('7.10', DoMistake(
    key: 'm7/gate/climber-unfit',
    textBn: 'সার্টিফিকেট বা ওয়ার্ক পারমিট, রেজিস্টারে নাম, প্রশিক্ষণ আর অনুমোদন — একটাও বাকি থাকলে লাইনে ওঠা আইন ভাঙা, শাটডাউনেও।',
    art: '$_art/id.svg',
    lessonPoint: 0,
  ));
  static const helmetBad = M7GMistake('7.6', DoMistake(
    key: 'm7/gate/helmet-bad',
    textBn: 'IS 2925 ছাপ ছাড়া বা বাজারের হেলমেট চলবে না — কাজের ঝুঁকি অনুযায়ী মাননির্দিষ্ট PPE চেয়ে নিন।',
    art: '$_art/ppe.svg',
    lessonPoint: 2,
  ));
  static const noConsent = M7GMistake('7.9', DoMistake(
    key: 'm7/gate/no-consent',
    textBn: 'গ্রাহকের অনুমতি আর আগাম নোটিশ ছাড়া তার বাড়িতে ঢোকা যায় না — দেয়াল টপকানো তো নয়ই। আইডি দেখিয়ে সম্মতি নিন।',
    art: '$_art/door.svg',
    lessonPoint: 1,
  ));
  static const wrongRoom = M7GMistake('7.9', DoMistake(
    key: 'm7/gate/wrong-room',
    textBn: 'মিটার বোর্ড আর ওয়্যারিংয়ের রুটের বাইরে যাওয়া যায় না — যে ঘরে কাজ নেই, সেখানে ঢুকবেন না।',
    art: '$_art/door.svg',
    lessonPoint: 1,
  ));
  static const sealCut = M7GMistake('7.5', DoMistake(
    key: 'm7/gate/seal-cut',
    textBn: 'সিল কাটা বা মিটারে চুম্বক দেখলে মিটার বদল নয় — যেমন আছে তেমন রেখে সুপারভাইজার আর ভিজিল্যান্সকে জানান।',
    art: '$_art/meter.svg',
    lessonPoint: 2,
  ));
  static const hookNoOrder = M7GMistake('7.5', DoMistake(
    key: 'm7/gate/hook-no-order',
    textBn: 'কর্তৃপক্ষের আদেশ ছাড়া চুরির হুক খোলা যায় না — আগে আদেশ হাতে নিন, তারপর কাজ।',
    art: '$_art/hook.svg',
    lessonPoint: 2,
  ));
  static const hookConfront = M7GMistake('7.5', DoMistake(
    key: 'm7/gate/hook-confront',
    textBn: 'চোরের মুখোমুখি হওয়া আপনার কাজ নয় — তথ্য আর প্রমাণ নিয়ে ভিজিল্যান্সকে জানান।',
    art: '$_art/hook.svg',
    lessonPoint: 2,
  ));
  static const lineUnder = M7GMistake('7.3', DoMistake(
    key: 'm7/gate/line-under',
    textBn: 'লাইনের নিচে বা খুব কাছে নির্মাণ বা ভেজা কাপড় — বিপজ্জনক। কাজ থামিয়ে সবাইকে সতর্ক করুন আর সুপারভাইজারকে জানান।',
    art: '$_art/line.svg',
    lessonPoint: 3,
  ));
  static const oilSpill = M7GMistake('7.8', DoMistake(
    key: 'm7/gate/oil-spill',
    textBn: 'ট্রান্সফরমারের তেল মাটিতে, ড্রেনে বা খোলা বালতিতে নয় — এটা দণ্ডনীয় অপরাধ। প্যাড-বুম পেতে বন্ধ লিক-প্রুফ ড্রামে ধরুন।',
    art: '$_art/oil.svg',
    lessonPoint: 0,
  ));
  static const wasteWrong = M7GMistake('7.8', DoMistake(
    key: 'm7/gate/waste-wrong',
    textBn: 'তেলের বর্জ্য শুধু অনুমোদিত রিসাইক্লিং এজেন্সির গাড়িতে, বিপজ্জনক বর্জ্যের আলাদা বিনে — সাধারণ বিনে বা যেকোনো গাড়িতে নয়।',
    art: '$_art/oil.svg',
    lessonPoint: 0,
  ));
  static const accHidden = M7GMistake('7.7', DoMistake(
    key: 'm7/gate/acc-hidden',
    textBn: 'আহতকে কাজে ফেরানো বা ঘটনা চেপে যাওয়া — যেকোনো চোট বা বিপদের ঘটনা সাথে সাথে সুপারভাইজারকে জানাতে হয়।',
    art: '$_art/accident.svg',
    lessonPoint: 1,
  ));
  static const accTidied = M7GMistake('7.7', DoMistake(
    key: 'm7/gate/acc-tidied',
    textBn: 'ঘটনাস্থল থেকে কিছু সরানো বা গুছিয়ে ফেলা চলবে না — সুপারভাইজার আসা পর্যন্ত যেমন আছে তেমন রাখুন।',
    art: '$_art/accident.svg',
    lessonPoint: 3,
  ));
  static const noSignature = M7GMistake('7.9', DoMistake(
    key: 'm7/gate/no-signature',
    textBn: 'কাজ শেষে গ্রাহকের সই ছাড়া জব শিট জমা নয় — গ্রাহকের সই কাজের প্রমাণ।',
    art: '$_art/door.svg',
    lessonPoint: 2,
  ));
  static const logChit = M7GMistake('7.4', DoMistake(
    key: 'm7/gate/log-chit',
    textBn: 'বাতিলের তারিখ আর সময় বাঁধানো লগবুকে লিখুন — ছেঁড়া কাগজের চিরকুটে নয়।',
    art: '$_art/ptw.svg',
    lessonPoint: 0,
  ));

  // --- per fork: the needless stop, a compliant tap, listening -----------------------
  static final needless = {
    for (final f in M7GFork.values)
      f: M7GMistake(f.lesson, DoMistake(
        key: 'm7/gate/needless-${f.name}',
        textBn: 'সব তো ঠিক আছে, দেখেছেন? আইন মানা থাকলে অকারণে থামালে কাজ আটকে যায়।',
        art: '$_art/stop.svg',
        lessonPoint: 0,
      )),
  };
  static final compliant = {
    for (final f in M7GFork.values)
      f: M7GMistake(f.lesson, DoMistake(
        key: 'm7/gate/compliant-${f.name}',
        textBn: 'এখানে তো আইন মানা আছে। ভাঙাটা অন্য জায়গায় — আবার ভালো করে দেখুন।',
        art: '$_art/stop.svg',
        lessonPoint: 0,
      )),
  };
  static final listened = {
    for (final f in M7GFork.values)
      f: M7GMistake(f.lesson, DoMistake(
        key: 'm7/gate/listened-${f.name}',
        textBn: 'সহকর্মীর কথায় চোখ বুজে সই — সইটা আপনার, দায়ও আপনার। আইন মানার আগে এগোবেন না।',
        art: '$_art/ear.svg',
        lessonPoint: 0,
      )),
  };

  static const values = [
    ptwBlank, ptwVerbal, gloveBad, hookLive, hookNoTest, hookNoEarth, headCount,
    ptwNumbers, climberUnfit, helmetBad, noConsent, wrongRoom, sealCut, hookNoOrder, hookConfront, lineUnder,
    oilSpill, wasteWrong, accHidden, accTidied, noSignature, logChit,
  ];

  static List<M7GMistake> get allWithLesson => [
        ...values,
        ...needless.values,
        ...compliant.values,
        ...listened.values,
      ];

  static List<DoMistake> get all => [for (final x in allWithLesson) x.m];

  /// The lesson that teaches [m] (for the mistakes book and পাঠে দেখুন).
  static String lessonOf(DoMistake m) => allWithLesson.firstWhere((x) => x.m.key == m.key, orElse: () => const M7GMistake('7.4', DoMistake(key: '', textBn: '', art: ''))).lessonId;
}

// ============================================================================
// Versions of each fork
// ============================================================================

@immutable
class M7GVer {
  const M7GVer(this.id, this.cls, {this.breach = const {}, this.mistake, this.fix});
  final String id;
  final M7GClass cls;

  /// The objects that are the breach after 'থামান'.
  final Set<String> breach;

  /// What a wrong 'এগোন' costs.
  final M7GMistake? mistake;

  /// The fix deck's key in [M7GateLines.fixRight].
  final String? fix;

  bool get lawful => cls == M7GClass.lawful;
  bool get deadly => cls == M7GClass.deadly;
}

const _law = M7GVer('lawful', M7GClass.lawful);

/// A fork's versions (the lawful one first).
List<M7GVer> m7gVersions(M7GFork f) => switch (f) {
      M7GFork.permit => const [
          _law,
          M7GVer('blank', M7GClass.deadly, breach: {'field'}, mistake: M7GMistakes.ptwBlank, fix: 'permit.blank'),
          M7GVer('verbal', M7GClass.deadly, breach: {'issuer', 'field'}, mistake: M7GMistakes.ptwVerbal, fix: 'permit.verbal'),
          M7GVer('numbers', M7GClass.slip, breach: {'field', 'ctl'}, mistake: M7GMistakes.ptwNumbers, fix: 'permit.numbers'),
        ],
      M7GFork.climber => const [
          _law,
          M7GVer('training', M7GClass.slip, breach: {'card_climber'}, mistake: M7GMistakes.climberUnfit, fix: 'climber'),
          M7GVer('auth', M7GClass.slip, breach: {'card_climber'}, mistake: M7GMistakes.climberUnfit, fix: 'climber'),
          M7GVer('cert', M7GClass.slip, breach: {'card_climber'}, mistake: M7GMistakes.climberUnfit, fix: 'climber'),
          M7GVer('reg', M7GClass.slip, breach: {'card_climber'}, mistake: M7GMistakes.climberUnfit, fix: 'climber'),
        ],
      M7GFork.kit => const [
          _law,
          M7GVer('torn', M7GClass.deadly, breach: {'gloves'}, mistake: M7GMistakes.gloveBad, fix: 'kit.glove'),
          M7GVer('unrated', M7GClass.deadly, breach: {'gloves'}, mistake: M7GMistakes.gloveBad, fix: 'kit.glove'),
          M7GVer('helmet', M7GClass.slip, breach: {'helmet'}, mistake: M7GMistakes.helmetBad, fix: 'kit.helmet'),
          M7GVer('stock', M7GClass.slip, breach: {'bag'}, mistake: M7GMistakes.helmetBad, fix: 'kit.helmet'),
        ],
      M7GFork.door => const [
          _law,
          M7GVer('ownerNo', M7GClass.slip, breach: {'owner'}, mistake: M7GMistakes.noConsent, fix: 'door'),
          M7GVer('nobody', M7GClass.slip, breach: {'wall'}, mistake: M7GMistakes.noConsent, fix: 'door'),
          M7GVer('noNotice', M7GClass.slip, breach: {'notice'}, mistake: M7GMistakes.noConsent, fix: 'door'),
        ],
      M7GFork.inside => const [
          _law,
          M7GVer('curtain', M7GClass.slip, breach: {'curtain'}, mistake: M7GMistakes.wrongRoom, fix: 'inside'),
        ],
      M7GFork.seal => const [
          _law,
          M7GVer('cut', M7GClass.slip, breach: {'seal'}, mistake: M7GMistakes.sealCut, fix: 'seal'),
          M7GVer('magnet', M7GClass.slip, breach: {'face'}, mistake: M7GMistakes.sealCut, fix: 'seal'),
        ],
      M7GFork.hook => const [
          _law,
          M7GVer('noOrder', M7GClass.slip, breach: {'officer'}, mistake: M7GMistakes.hookNoOrder, fix: 'hook.order'),
          M7GVer('toOwner', M7GClass.slip, breach: {'man'}, mistake: M7GMistakes.hookConfront, fix: 'hook.owner'),
          M7GVer('live', M7GClass.deadly, breach: {'hook'}, mistake: M7GMistakes.hookLive, fix: 'hook.live'),
          M7GVer('noEarth', M7GClass.deadly, breach: {'earth'}, mistake: M7GMistakes.hookNoEarth, fix: 'hook.earth'),
          M7GVer('noTest', M7GClass.deadly, breach: {'tester'}, mistake: M7GMistakes.hookNoTest, fix: 'hook.test'),
        ],
      M7GFork.line => const [
          _law,
          M7GVer('floor', M7GClass.slip, breach: {'masons'}, mistake: M7GMistakes.lineUnder, fix: 'line'),
          M7GVer('clothes', M7GClass.slip, breach: {'clothes'}, mistake: M7GMistakes.lineUnder, fix: 'line'),
        ],
      M7GFork.oil => const [
          _law,
          M7GVer('noKit', M7GClass.slip, breach: {'pads'}, mistake: M7GMistakes.oilSpill, fix: 'oil'),
          M7GVer('drain', M7GClass.slip, breach: {'hose', 'drain'}, mistake: M7GMistakes.oilSpill, fix: 'oil'),
          M7GVer('bucket', M7GClass.slip, breach: {'hose', 'bucket'}, mistake: M7GMistakes.oilSpill, fix: 'oil'),
        ],
      M7GFork.waste => const [
          _law,
          M7GVer('van', M7GClass.slip, breach: {'truck'}, mistake: M7GMistakes.wasteWrong, fix: 'waste'),
          M7GVer('bin', M7GClass.slip, breach: {'bin'}, mistake: M7GMistakes.wasteWrong, fix: 'waste'),
        ],
      M7GFork.accident => const [
          _law,
          M7GVer('back', M7GClass.slip, breach: {'hurt', 'leader'}, mistake: M7GMistakes.accHidden, fix: 'accident'),
          M7GVer('silent', M7GClass.slip, breach: {'leader'}, mistake: M7GMistakes.accHidden, fix: 'accident'),
          M7GVer('tidy', M7GClass.slip, breach: {'mate', 'tool', 'ladder'}, mistake: M7GMistakes.accTidied, fix: 'accident'),
        ],
      M7GFork.ret => const [
          _law,
          M7GVer('up', M7GClass.deadly, breach: {'hid'}, mistake: M7GMistakes.headCount, fix: 'ret'),
        ],
      M7GFork.jobSheet => const [
          _law,
          M7GVer('noSign', M7GClass.slip, breach: {'sheet'}, mistake: M7GMistakes.noSignature, fix: 'jobSheet'),
        ],
      M7GFork.logbook => const [
          _law,
          M7GVer('chit', M7GClass.slip, breach: {'chit'}, mistake: M7GMistakes.logChit, fix: 'logbook'),
        ],
    };

// ============================================================================
// The deal
// ============================================================================

/// The crew pool (~10 men; names, shirts).
const m7gMen = ['রতন', 'সুমন', 'বিকাশ', 'মানিক', 'তাপস', 'কার্তিক', 'অমল', 'সুজিত', 'শঙ্কর', 'বাবলু'];
const m7gShirts = [
  Color(0xFF3F7EA6), Color(0xFFC0523A), Color(0xFF5E9A4A), Color(0xFFB07A2E), Color(0xFF7A5AA6),
  Color(0xFF2E8E8A), Color(0xFFC25A8A), Color(0xFF8A8A3A), Color(0xFF5A6A8A), Color(0xFFA64A4A),
];

@immutable
class M7GStep {
  const M7GStep({required this.fork, required this.ver, required this.flip, required this.cw});
  final M7GFork fork;
  final M7GVer ver;

  /// The scene's side (mirrored layout).
  final bool flip;

  /// The coworker comes on this step (at the first swipe on the field copy).
  final bool cw;

  int get spot => fork.spot;
}

@immutable
class M7GDeal {
  const M7GDeal({
    required this.steps,
    required this.crew,
    required this.climberPos,
    required this.upPos,
    required this.ptwNo,
    required this.altNo,
    required this.laneLeft,
    required this.light,
    required this.hideTree,
    required this.parkVan,
    required this.parkDecoy,
    required this.incidentCut,
    required this.gloveLow,
    required this.cardNos,
    required this.houseCol,
  });

  final List<M7GStep> steps;

  /// Indices into [m7gMen] of the morning line-up (3–4 men).
  final List<int> crew;

  /// Which of them climbs (F2), and who is still up the pole in a deadly F12.
  final int climberPos;
  final int upPos;
  final int ptwNo;

  /// The other copy's number in a 'numbers' F1.
  final int altNo;

  /// The lane DTR stands on the left of the lane scene.
  final bool laneLeft;

  /// Light per spot (0–2).
  final List<int> light;

  /// Where a man could hide at F12: behind the tree (else behind the DTR pole).
  final bool hideTree;

  /// A lawful F12 parks a van (else a cart) where a man could hide.
  final bool parkVan;
  final bool parkDecoy;

  /// F11: a hand cut (else a near miss).
  final bool incidentCut;

  /// F3 unrated glove: a lower type on the cuff (else no marking).
  final bool gloveLow;

  /// Each crew man's ID number.
  final List<int> cardNos;
  final int houseCol;

  List<M7GFork> get forks => [for (final s in steps) s.fork];
  int get lawfulCount => steps.where((s) => s.ver.lawful).length;
  int get deadlyCount => steps.where((s) => s.ver.deadly).length;
  int get coworkerStep => steps.indexWhere((s) => s.cw);

  /// How many men stand in the line-up.
  int get n => crew.length;
}

/// Deals one play: F1 first, F12 last, eight more from F2–F11/F13/F14 in day
/// order (every lesson group once where it can be), 4–6 of 10 lawful, 1–2
/// deadly-class unlawful versions.
M7GDeal dealM7G(math.Random rng) {
  const groups = [
    [M7GFork.climber],
    [M7GFork.kit],
    [M7GFork.door, M7GFork.inside, M7GFork.jobSheet],
    [M7GFork.seal, M7GFork.hook],
    [M7GFork.line],
    [M7GFork.oil, M7GFork.waste],
    [M7GFork.accident],
  ];
  final chosen = <M7GFork>{for (final g in groups) g[rng.nextInt(g.length)]};
  final pool = [
    for (final f in M7GFork.values)
      if (f != M7GFork.permit && f != M7GFork.ret && !chosen.contains(f)) f,
  ];
  chosen.add(pool[rng.nextInt(pool.length)]);
  final mid = chosen.toList()..sort((a, b) => a.dayOrder.compareTo(b.dayOrder));
  final forks = [M7GFork.permit, ...mid, M7GFork.ret];

  final lawfulN = 4 + rng.nextInt(3);
  final deadlyN = 1 + rng.nextInt(2);
  final deadlyCap = [for (final f in forks) if (f.hasDeadly) f]..shuffle(rng);
  final deadlySet = deadlyCap.take(deadlyN).toSet();
  final slipN = forks.length - lawfulN - deadlySet.length;
  final slipCap = [for (final f in forks) if (f != M7GFork.ret && !deadlySet.contains(f)) f]..shuffle(rng);
  final slipSet = slipCap.take(math.max(0, slipN)).toSet();

  final laneLeft = rng.nextBool();
  final vers = <M7GFork, M7GVer>{};
  for (final f in forks) {
    final all = m7gVersions(f);
    if (deadlySet.contains(f)) {
      final d = [for (final v in all) if (v.deadly) v];
      vers[f] = d[rng.nextInt(d.length)];
    } else if (slipSet.contains(f)) {
      final s = [for (final v in all) if (v.cls == M7GClass.slip) v];
      vers[f] = s[rng.nextInt(s.length)];
    } else {
      vers[f] = all.first;
    }
  }
  final cwCands = [for (final f in forks) if (f.coworkerFork && !vers[f]!.deadly) f];
  final cwFork = cwCands[rng.nextInt(cwCands.length)];

  final steps = [
    for (final f in forks)
      M7GStep(
        fork: f,
        ver: vers[f]!,
        flip: f == M7GFork.hook ? !laneLeft : (f.spot == 1 ? rng.nextBool() : false),
        cw: f == cwFork,
      ),
  ];

  final n = 3 + rng.nextInt(2);
  final men = (List<int>.generate(m7gMen.length, (i) => i)..shuffle(rng)).take(n).toList();
  final no = 100 + rng.nextInt(900);
  var alt = 100 + rng.nextInt(900);
  if (alt == no) alt = alt == 999 ? 100 : alt + 1;
  return M7GDeal(
    steps: steps,
    crew: men,
    climberPos: rng.nextInt(n),
    upPos: rng.nextInt(n),
    ptwNo: no,
    altNo: alt,
    laneLeft: laneLeft,
    light: [rng.nextInt(3), rng.nextInt(3), rng.nextInt(3)],
    hideTree: rng.nextBool(),
    parkVan: rng.nextBool(),
    parkDecoy: rng.nextBool(),
    incidentCut: rng.nextBool(),
    gloveLow: rng.nextBool(),
    cardNos: [for (var i = 0; i < n; i++) 1000 + rng.nextInt(9000)],
    houseCol: rng.nextInt(3),
  );
}

// ============================================================================
// The objects of a step (what is drawn, what a tap shows)
// ============================================================================

Rect _r(double x, double y, double w, double h, {bool flip = false}) => flip ? Rect.fromLTWH(1 - x - w, y, w, h) : Rect.fromLTWH(x, y, w, h);

String _cert(M7GDeal d, int k) => 'C-${(d.cardNos[k] * 7) % 9000 + 1000}';

/// An ID card's rows (the same rows on every card; [defect]: training, auth,
/// cert, reg).
List<String> m7gCardLines(M7GDeal d, int k, String defect) => [
      'নাম: ${m7gMen[d.crew[k]]}',
      'ID: ${d.cardNos[k]}',
      defect == 'cert' ? 'সার্টিফিকেট/ওয়ার্ক পারমিট নং: —' : 'সার্টিফিকেট/ওয়ার্ক পারমিট নং: ${_cert(d, k)}',
      defect == 'reg' ? 'কোম্পানি রেজিস্টারে নাম: নেই' : 'কোম্পানি রেজিস্টারে নাম: আছে',
      defect == 'training' ? 'প্রশিক্ষণ: চলছে' : 'প্রশিক্ষণ: সম্পূর্ণ',
      defect == 'auth' ? 'অনুমোদন: ফাঁকা' : 'অনুমোদন: সই ও সিল',
    ];

/// The lines of a PTW copy.
List<String> _copyLines(int no, {required bool issuer, required bool receiver, bool control = false}) => [
      control ? M7GateLines.controlCopy : M7GateLines.fieldCopy,
      M7GateLines.ptwNo(no),
      'কাজ: 11 kV শাটডাউন',
      issuer ? 'ইস্যুকারীর ঘর: সই করা' : 'ইস্যুকারীর ঘর: ফাঁকা',
      receiver ? 'গ্রহণকারীর ঘর: সই করা' : 'গ্রহণকারীর ঘর: ফাঁকা',
    ];

const _helmCols = [Color(0xFFFFFFFF), Color(0xFFF2B632), Color(0xFFE05A3A)];

M7GObj _man(String id, Rect r, M7GDeal d, int k, {int pose = 0, String txt = '', bool hit = true, List<String> lines = const [], String title = ''}) => M7GObj(
      id: id,
      kind: M7GKind.person,
      r: r,
      a: pose,
      col: m7gShirts[d.crew[k % d.n]],
      col2: _helmCols[k % 3],
      txt: txt,
      hit: hit,
      title: title.isEmpty ? m7gMen[d.crew[k % d.n]] : title,
      lines: lines,
    );

/// The objects the step [idx] shows. [fixed]: the lawful fix has played (the
/// lawful version is drawn).
List<M7GObj> m7gObjects(M7GDeal d, int idx, {bool fixed = false}) {
  final objs = _forkObjects(d, idx, fixed: fixed);
  if (d.steps[idx].spot != 1) return objs;
  // Both DTRs' AB switches can always be looked at (the lane's is open, locked
  // and tagged; the main road's is closed — drawn at the same size).
  final lx = d.laneLeft ? 18 / 360 : 196 / 360;
  final mx = d.laneLeft ? 196 / 360 : 18 / 360;
  return [
    ...objs,
    M7GObj(
      id: 'abJob',
      kind: M7GKind.none,
      r: Rect.fromLTWH(lx + .09, .09, .22, .13),
      title: 'গলির DTR-এর AB',
      lines: ['AB: তিনটে ব্লেডই খোলা, ফাঁক স্পষ্ট', 'হাতলে তালা আর ট্যাগ', 'পাশে HG ফিউজ'],
    ),
    M7GObj(
      id: 'abMain',
      kind: M7GKind.none,
      r: Rect.fromLTWH(mx + .09, .09, .22, .13),
      title: 'বড় রাস্তার DTR-এর AB',
      lines: ['AB: তিনটে ব্লেডই লাগানো', 'হাতল আগের মতোই', 'পাশে HG ফিউজ'],
    ),
  ];
}

List<M7GObj> _forkObjects(M7GDeal d, int idx, {required bool fixed}) {
  final s = d.steps[idx];
  final v = fixed ? 'lawful' : s.ver.id;
  final fl = s.flip;
  Rect r(double x, double y, double w, double h) => _r(x, y, w, h, flip: fl);
  switch (s.fork) {
    case M7GFork.permit:
      final verbal = v == 'verbal';
      return [
        M7GObj(
          id: 'issuer',
          kind: M7GKind.person,
          r: _r(.38, .10, .24, .46),
          col: const Color(0xFFD8D4C4),
          col2: const Color(0xFFFFFFFF),
          title: 'কাউন্টারের লোক',
          lines: verbal ? ['কাউন্টারে বসে আছেন', 'হাতে কোনো কাগজ নেই'] : ['কাউন্টারে বসে আছেন', 'হাতে PTW কপি দুটো'],
        ),
        if (!verbal)
          M7GObj(
            id: 'ctl',
            kind: M7GKind.copy,
            r: _r(.04, .60, .30, .32),
            a: 1,
            title: M7GateLines.controlCopy,
            txt: M7GateLines.ptwNo(d.ptwNo),
            lines: _copyLines(d.ptwNo, issuer: true, receiver: false, control: true),
          ),
        M7GObj(
          id: 'book',
          kind: M7GKind.book,
          r: _r(.64, .66, .24, .24),
          title: 'PTW বই',
          lines: verbal ? ['কার্বন বই বন্ধ, কাউন্টারের কোণে'] : ['কার্বন কপির বই', 'আজকের পাতা কাটা'],
        ),
      ];
    case M7GFork.climber:
      final defect = switch (v) {
        'training' => 'training',
        'auth' => 'auth',
        'cert' => 'cert',
        'reg' => 'reg',
        _ => '',
      };
      final n = d.n;
      final w = .9 / n - .02;
      return [
        for (var k = 0; k < n; k++) ...[
          _man('man$k', _r(.05 + k * (.9 / n), .12, w, .44), d, k, pose: k == d.climberPos ? 1 : 0, hit: false),
          M7GObj(
            id: k == d.climberPos ? 'card_climber' : 'card$k',
            kind: M7GKind.idCard,
            r: _r(.05 + k * (.9 / n) + w * .1, .60, w * .8, .20),
            title: 'আইডি কার্ড',
            lines: m7gCardLines(d, k, k == d.climberPos ? defect : ''),
          ),
        ],
      ];
    case M7GFork.kit:
      final torn = v == 'torn';
      final low = v == 'unrated';
      final noMark = v == 'helmet';
      final stock = v == 'stock';
      return [
        M7GObj(id: 'keeper', kind: M7GKind.person, r: _r(.04, .10, .20, .42), col: const Color(0xFF8A7A5A), col2: const Color(0xFFE05A3A), title: 'স্টোরের লোক', hit: false),
        M7GObj(
          id: 'gloves',
          kind: M7GKind.glove,
          r: _r(.30, .58, .30, .24),
          a: torn ? 1 : 0,
          txt: low ? (d.gloveLow ? M7GateLines.gloveCuffLow : '') : M7GateLines.gloveCuff,
          title: 'গ্লাভস',
          lines: [
            'কাফের লেখা: ${low ? (d.gloveLow ? M7GateLines.gloveCuffLow : 'কিছু লেখা নেই') : M7GateLines.gloveCuff}',
            'পামের অবস্থা: ${torn ? 'ছেঁড়া, ফুটো' : 'অটুট'}',
          ],
        ),
        if (!stock)
          M7GObj(
            id: 'helmet',
            kind: M7GKind.helmet,
            r: _r(.64, .56, .26, .26),
            txt: noMark ? '' : M7GateLines.helmetPrint,
            col: const Color(0xFFF2D24A),
            title: 'হেলমেট',
            lines: ['গায়ে ছাপ: ${noMark ? 'কিছু নেই' : M7GateLines.helmetPrint}', 'ফাটল: নেই', 'চিনস্ট্র্যাপ: আছে'],
          )
        else
          M7GObj(
            id: 'bag',
            kind: M7GKind.bag,
            r: _r(.64, .54, .26, .30),
            title: 'দোকানের ব্যাগ',
            lines: ['দোকানের ব্যাগে হেলমেট', 'গায়ে ছাপ: কিছু নেই', 'স্টোরের তাক: ফাঁকা'],
          ),
        M7GObj(id: 'register', kind: M7GKind.paper, r: _r(.08, .66, .16, .22), title: 'ইস্যু রেজিস্টার', lines: ['ইস্যু রেজিস্টার', 'আজকের ঘর: সই বাকি']),
      ];
    case M7GFork.door:
      final given = v != 'noNotice';
      final nobody = v == 'nobody';
      return [
        M7GObj(
          id: 'notice',
          kind: M7GKind.gate,
          r: r(.04, .44, .32, .32),
          txt: given ? M7GateLines.noticeGiven : M7GateLines.noticeNot,
          title: 'গেটের নোটিশ',
          lines: [given ? M7GateLines.noticeGiven : M7GateLines.noticeNot, 'তারিখ: আজকের'],
        ),
        if (nobody)
          M7GObj(id: 'owner', kind: M7GKind.door, r: r(.40, .44, .18, .42), a: 1, title: 'বাড়ির দরজা', lines: ['দরজায় তালা', 'ভেতরে কারও সাড়া নেই'])
        else
          M7GObj(
            id: 'owner',
            kind: M7GKind.person,
            r: r(.40, .42, .18, .46),
            col: const Color(0xFFB07A58),
            col2: const Color(0xFFEFE6D0),
            txt: v == 'ownerNo' ? M7GateLines.ownerNo : M7GateLines.ownerYes,
            title: 'বাড়ির মালিক',
            lines: ['দরজায় দাঁড়িয়ে আছেন', 'মুখে: ${v == 'ownerNo' ? M7GateLines.ownerNo : M7GateLines.ownerYes}'],
          ),
        M7GObj(id: 'wall', kind: M7GKind.wall, r: r(.62, .66, .34, .16), a: nobody ? 1 : 0, title: 'উঠোনের পাঁচিল', lines: ['উঠোনের পাঁচিল', nobody ? 'পাঁচিলের ওপর একজনের পা' : 'গেটের পাশে']),
        _man('man', r(.62, .38, .17, .34), d, 1, pose: 0, title: 'ক্রুর লোক', lines: ['গলায় আইডি কার্ড ঝোলানো', 'নাম: ${m7gMen[d.crew[1 % d.n]]}']),
      ];
    case M7GFork.inside:
      final curtain = v == 'curtain';
      return [
        M7GObj(id: 'curtain', kind: M7GKind.curtain, r: r(.04, .42, .24, .46), title: 'ভেতরের ঘরের পর্দা', lines: ['ভেতরের ঘরের দরজায় পর্দা', 'এদিকে কোনো কন্ডুইট ঢোকেনি']),
        M7GObj(id: 'conduit', kind: M7GKind.conduit, r: r(.32, .56, .36, .12), title: 'কন্ডুইট', lines: ['দেয়াল বেয়ে মিটার বোর্ডের দিকে গেছে']),
        M7GObj(id: 'board', kind: M7GKind.meter, r: r(.72, .42, .22, .34), title: 'বারান্দার মিটার বোর্ড', lines: ['বারান্দার মিটার বোর্ড', 'সিল আছে']),
        _man('man', curtain ? r(.20, .40, .17, .46) : r(.40, .18, .17, .34), d, 0, pose: curtain ? 5 : 0, title: 'ক্রুর লোক', lines: ['ক্রুর লোক', 'ঘরের ভেতরে']),
      ];
    case M7GFork.seal:
      final cut = v == 'cut';
      final mag = v == 'magnet';
      return [
        M7GObj(id: 'meter', kind: M7GKind.meter, r: r(.28, .34, .36, .44), a: (cut ? 1 : 0) | (mag ? 2 : 0), hit: false),
        M7GObj(id: 'face', kind: M7GKind.none, r: r(.34, .36, .24, .16), title: 'মিটারের মুখ', lines: ['ডিসপ্লে চলছে', mag ? 'পাশে একটা কালো চুম্বক লাগানো' : 'পাশে কিছু লাগানো নেই']),
        M7GObj(id: 'seal', kind: M7GKind.none, r: r(.30, .62, .32, .14), title: 'মিটারের সিল', lines: ['দুটো সিল', cut ? 'একটা সিল কাটা, তার জোড়া' : 'দুটোই অটুট, নম্বর মেলে']),
        _man('man', r(.70, .38, .18, .46), d, 2, pose: 0, title: 'ক্রুর লোক', lines: ['হাতে নতুন মিটার', 'পুরনোটা খোলার সরঞ্জাম']),
      ];
    case M7GFork.hook:
      final hookMain = s.ver.id == 'live'; // the hook stays where it hangs after the fix
      final noTest = v == 'noTest';
      final noEarth = v == 'noEarth';
      final noOrder = v == 'noOrder';
      final owner = v == 'toOwner';
      return [
        M7GObj(
          id: 'hook',
          kind: M7GKind.hook,
          r: _r(hookMain ? .58 : .12, .27, .26, .16, flip: fl),
          title: 'তারের হুক',
          lines: ['তারে ঝোলানো খালি তামার তার', 'নিচে একটা বাড়ির দিকে নেমেছে'],
        ),
        M7GObj(
          id: 'tester',
          kind: M7GKind.tester,
          r: _r(.06, .46, .20, .15, flip: fl),
          txt: noTest ? '' : '0 V',
          title: 'টেস্টার',
          lines: ['টেস্টারের ডিসপ্লে: ${noTest ? 'কোনো রিডিং নেই' : '0 V'}', noTest ? 'ব্যাগের পাশে রাখা' : 'ঠিক আছে কি না: চালু উৎসে মিলেছে'],
        ),
        M7GObj(
          id: 'earth',
          kind: M7GKind.earth,
          r: _r(.30, .42, .12, .22, flip: fl),
          a: noEarth ? 1 : 0,
          title: 'আর্থ সেট',
          lines: [noEarth ? 'স্প্যানে আর্থ সেট: নেই' : 'স্প্যানে আর্থ সেট: লাগানো', noEarth ? 'আর্থ রড মাটিতে পড়ে' : 'আর্থ রডে ক্ল্যাম্প আঁটা'],
        ),
        M7GObj(
          id: 'officer',
          kind: M7GKind.person,
          r: _r(.46, .44, .17, .50, flip: fl),
          col: const Color(0xFF3A5A7A),
          col2: const Color(0xFFFFFFFF),
          title: 'ভিজিল্যান্স অফিসার',
          lines: ['ভিজিল্যান্স অফিসার', noOrder ? 'হাতে কোনো কাগজ নেই' : 'হাতে কর্তৃপক্ষের আদেশের কাগজ'],
        ),
        M7GObj(
          id: 'man',
          kind: M7GKind.person,
          r: _r(.68, .44, .17, .50, flip: fl),
          a: owner ? 3 : 0,
          col: m7gShirts[d.crew[0]],
          col2: _helmCols[0],
          title: 'ক্রুর লোক',
          lines: ['ক্রুর লোক', 'গ্লাভস, হেলমেট, গগলস পরা', owner ? 'পা বাড়ির দরজার দিকে ঘোরানো' : 'মুখ লাইনের দিকে'],
        ),
      ];
    case M7GFork.line:
      final floor = v == 'floor';
      final clothes = v == 'clothes';
      return [
        M7GObj(id: 'wire', kind: M7GKind.conduit, r: r(.02, floor || clothes ? .30 : .26, .96, .10), a: 1, title: 'LT লাইন', lines: ['LT লাইন, বাড়িগুলোর ওপর দিয়ে গেছে']),
        M7GObj(id: 'masons', kind: M7GKind.roof, r: r(.06, floor ? .40 : .56, .40, .30), title: 'ছাদে রাজমিস্ত্রি', lines: ['রাজমিস্ত্রিরা ছাদে কাজ করছে', 'ছাদের ধারে বাঁশের মাচা']),
        M7GObj(
          id: 'clothes',
          kind: M7GKind.clothes,
          r: r(.54, clothes ? .38 : .66, .38, .20),
          title: 'কাপড়ের দড়ি',
          lines: ['দড়িতে কাপড় ঝোলানো', clothes ? 'কাপড় ভেজা' : 'কাপড় শুকনো'],
        ),
      ];
    case M7GFork.oil:
      final noKit = v == 'noKit';
      final drain = v == 'drain';
      final bucket = v == 'bucket';
      // The hose runs from the valve to where it ends.
      final end = drain ? const Offset(.24, .70) : (bucket ? const Offset(.50, .70) : const Offset(.81, .48));
      const start = Offset(.46, .40);
      final left = math.min(start.dx, end.dx);
      final right = math.max(start.dx, end.dx);
      final hoseR = Rect.fromLTRB(left, start.dy, right, start.dy + 2 * (end.dy - start.dy));
      final mirrored = end.dx < start.dx;
      return [
        M7GObj(id: 'pads', kind: M7GKind.pads, r: r(.05, .46, .30, .20), a: noKit ? 1 : 0, title: 'ট্যাঙ্কের নিচের মাটি', lines: noKit ? ['মাটি ফাঁকা, কোনো প্যাড বা বুম নেই'] : ['শোষক প্যাড পাতা', 'বুম রিং ট্যাঙ্কের চারপাশে বন্ধ']),
        M7GObj(id: 'hose_v', kind: M7GKind.hose, r: _r(hoseR.left, hoseR.top, hoseR.width, hoseR.height, flip: fl), a: (mirrored ? 1 : 0) ^ (fl ? 1 : 0), hit: false),
        M7GObj(id: 'hose', kind: M7GKind.none, r: _r(end.dx - .08, end.dy - .06, .16, .11, flip: fl), title: 'ভালভের পাইপ', lines: ['ভালভ থেকে পাইপ নেমেছে', drain ? 'মুখ ড্রেনের দিকে' : (bucket ? 'মুখ বালতির ভেতর' : 'মুখ ড্রামের ভেতর')]),
        M7GObj(id: 'drum', kind: M7GKind.drum, r: r(.72, .50, .18, .40), title: 'ড্রাম', lines: ['লিক-প্রুফ ড্রাম', 'ঢাকনা আঁটা', 'সিমে ফাঁক নেই']),
        M7GObj(id: 'bucket', kind: M7GKind.bucket, r: r(.44, .72, .14, .16), title: 'বালতি', lines: ['খোলা বালতি', 'মুখ খোলা']),
        M7GObj(id: 'drain', kind: M7GKind.drain, r: r(.06, .78, .28, .10), title: 'রাস্তার ড্রেন', lines: ['রাস্তার ধারের ড্রেন', 'জালি দেওয়া']),
      ];
    case M7GFork.waste:
      final van = v == 'van';
      final bin = v == 'bin';
      return [
        M7GObj(
          id: 'truck',
          kind: M7GKind.truck,
          r: r(.48, .40, .46, .30),
          col: const Color(0xFF4A6A8A),
          txt: van ? '' : M7GateLines.agencySign,
          title: 'গাড়ি',
          lines: ['গাড়ির গায়ে লেখা: ${van ? 'কিছু নেই' : M7GateLines.agencySign}', 'গাড়ি এসে দাঁড়িয়েছে'],
        ),
        M7GObj(
          id: 'bin',
          kind: M7GKind.bin,
          r: r(.10, .60, .16, .28),
          col: bin ? const Color(0xFF3E8E4A) : const Color(0xFFC0392B),
          col2: bin ? const Color(0xFF2E6A38) : const Color(0xFF8E2A20),
          title: 'বর্জ্যের পাত্র',
          lines: ['বিনের লেবেল: ${bin ? 'সাধারণ বর্জ্য' : 'বিপজ্জনক বর্জ্য'}', 'ভেতরে তেলমাখা প্যাড'],
        ),
        M7GObj(id: 'pads', kind: M7GKind.pads, r: r(.30, .74, .20, .12), a: 1, title: 'তেলমাখা প্যাড', lines: ['তেলমাখা প্যাডের স্তূপ']),
      ];
    case M7GFork.accident:
      final back = v == 'back';
      final tidy = v == 'tidy';
      final lawful = v == 'lawful';
      final cut = d.incidentCut || back;
      return [
        _man(
          'hurt',
          back ? r(.66, .44, .17, .46) : r(.06, .44, .17, .46),
          d,
          0,
          pose: cut ? 2 : 0,
          title: cut ? 'আহত লোক' : 'পাশের লোক',
          lines: cut
              ? ['হাতে ব্যান্ডেজ', back ? 'মইয়ের দিকে ফিরে যাচ্ছেন' : (lawful ? 'গেটের দিকে হাঁটছেন' : 'দাঁড়িয়ে আছেন')]
              : ['গায়ে লাগেনি', 'পাশেই স্প্যানার পড়ে আছে'],
        ),
        _man('leader', r(.34, .42, .17, .48), d, 1, pose: lawful ? 1 : 0, title: 'দলনেতা', lines: lawful ? ['কানে ফোন', 'সুপারভাইজারকে ফোন করছেন'] : ['হাতে কিছু নেই', 'কাজের দিকে তাকিয়ে']),
        _man('mate', tidy ? r(.50, .56, .15, .38) : r(.50, .44, .15, .46), d, 2, pose: tidy ? 5 : 0, title: 'সহকর্মী', lines: tidy ? ['পড়ে থাকা সরঞ্জাম তুলছেন', 'মই সরাচ্ছেন'] : ['দাঁড়িয়ে আছেন']),
        M7GObj(id: 'tool', kind: M7GKind.tool, r: r(.64, .90, .16, .10), hit: true, title: 'পড়ে থাকা সরঞ্জাম', lines: [tidy ? 'জায়গা বদলানো সরঞ্জাম' : 'যেখানে পড়েছে সেখানেই']),
        M7GObj(id: 'ladder', kind: M7GKind.ladder, r: r(.78, .40, .16, .50), title: 'মই', lines: ['খুঁটিতে লাগানো মই', tidy ? 'জায়গা থেকে সরানো' : 'যেমন ছিল']),
      ];
    case M7GFork.jobSheet:
      final signed = v == 'lawful';
      return [
        _man('man', r(.06, .42, .18, .48), d, 0, pose: 0, title: 'ক্রুর লোক', lines: ['কাজ শেষ করে দাঁড়িয়ে আছেন']),
        M7GObj(
          id: 'sheet',
          kind: M7GKind.sheet,
          r: r(.32, .44, .26, .34),
          a: signed ? 1 : 0,
          txt: M7GateLines.jobSheetName,
          title: M7GateLines.jobSheetName,
          lines: [M7GateLines.jobSheetName, 'কাজ: মিটার বদল সম্পূর্ণ', signed ? 'গ্রাহকের সই: সই করা' : 'গ্রাহকের সই: ফাঁকা'],
        ),
        M7GObj(id: 'customer', kind: M7GKind.person, r: r(.64, .42, .18, .48), col: const Color(0xFFB07A58), col2: const Color(0xFFEFE6D0), title: 'গ্রাহক', lines: ['গ্রাহক, দরজার পাশে']),
      ];
    case M7GFork.logbook:
      final chit = v == 'chit';
      return [
        M7GObj(id: 'issuer', kind: M7GKind.person, r: _r(.40, .10, .22, .46), col: const Color(0xFFD8D4C4), col2: const Color(0xFFFFFFFF), title: 'কাউন্টারের লোক', lines: ['কাউন্টারে বসে', 'হাতে কলম']),
        M7GObj(
          id: 'logbook',
          kind: M7GKind.logbook,
          r: _r(.12, .60, .30, .26),
          a: chit ? 0 : 1,
          title: 'বাঁধানো লগবুক',
          lines: ['বাঁধানো লগবুক', chit ? 'আজকের ঘর: ফাঁকা' : 'আজকের ঘরে তারিখ ও সময় লেখা'],
        ),
        M7GObj(id: 'chit', kind: M7GKind.chit, r: _r(.54, .62, .18, .16), a: chit ? 1 : 0, title: 'ছেঁড়া কাগজ', lines: ['ছেঁড়া কাগজের টুকরো', chit ? 'তারিখ ও সময় লেখা' : 'ফাঁকা']),
      ];
    case M7GFork.ret:
      final up = v == 'up';
      final n = d.n;
      // The men on the ground (every man; one less when one is still up).
      final ground = [for (var k = 0; k < n; k++) if (!(up && k == d.upPos)) k];
      final out = <M7GObj>[
        if (up)
          M7GObj(
            id: 'hid',
            kind: M7GKind.person,
            r: d.hideTree ? _r(.21, .10, .09, .24) : _r(.48, .10, .09, .24),
            a: 4,
            col: m7gShirts[d.crew[d.upPos]],
            col2: _helmCols[d.upPos % 3],
            title: 'খুঁটির লোক',
            lines: ['খুঁটিতে ওপরে কেউ', d.hideTree ? 'ডালপালার আড়ালে আধখানা' : 'DTR-এর আড়ালে আধখানা'],
          ),
        M7GObj(id: 'tree', kind: M7GKind.tree, r: _r(.06, .02, .20, .50), title: 'গাছ', lines: ['ঘন ডালপালার গাছ']),
        M7GObj(id: 'dtr', kind: M7GKind.drum, r: _r(.36, .16, .17, .36), a: 2, title: 'DTR', lines: ['DTR, প্লিন্থের ওপর', 'AB হাতলে তালা-ট্যাগ']),
        for (var i = 0; i < ground.length; i++)
          _man('g${ground[i]}', _r(.62 + i * .09, .22, .092, .30), d, ground[i], title: m7gMen[d.crew[ground[i]]], lines: ['মাটিতে দাঁড়িয়ে', 'নাম: ${m7gMen[d.crew[ground[i]]]}', 'ID: ${d.cardNos[ground[i]]}']),
      ];
      if (!up && d.parkDecoy) {
        out.add(M7GObj(
          id: 'park',
          kind: d.parkVan ? M7GKind.van : M7GKind.cart,
          r: d.hideTree ? _r(.04, .46, .26, .16) : _r(.34, .52, .22, .16),
          title: d.parkVan ? 'ক্রুর ভ্যান' : 'ঠেলাগাড়ি',
          lines: [d.parkVan ? 'ক্রুর ভ্যান দাঁড়িয়ে' : 'ঠেলাগাড়ি দাঁড়িয়ে'],
        ));
      }
      return out;
  }
}

/// The scene rects the gesture hint sweeps over (never what: on the head-count
/// step they are fixed anchors, the same on a lawful and an 'up' version).
List<Rect> m7gHintRects(M7GDeal d, int idx, {bool fixed = false}) {
  final step = d.steps[idx];
  if (step.fork == M7GFork.ret) {
    return [_r(.06, .02, .20, .50), _r(.36, .16, .17, .36), _r(.62, .22, .09 * (d.n - 1) + .092, .30)];
  }
  return [for (final o in m7gObjects(d, idx, fixed: fixed)) if (o.hit) o.r];
}

/// Every object that takes a tap in step [idx] (the field copy is the
/// clipboard, not in this list).
Set<String> m7gObjectIds(M7GDeal d, int idx, {bool fixed = false}) => {for (final o in m7gObjects(d, idx, fixed: fixed)) if (o.hit) o.id};

// ============================================================================
// The run (pure rules)
// ============================================================================

/// What a move leads to (the page plays it out in this order).
enum M7GReasonKind { none, whyGo, fix, closing }

@immutable
class M7GOutcome {
  const M7GOutcome({this.mistake, this.reason = M7GReasonKind.none, this.pay = 0, this.resolved = false, this.halted = false});

  /// A deadly move (ends the play) or a slip.
  final DoMistake? mistake;

  /// ◆ after the move.
  final M7GReasonKind reason;

  /// Points without a reason.
  final int pay;

  /// The step is judged and the job moves on (after the reason, if any).
  final bool resolved;

  /// The crew froze: tap the breach.
  final bool halted;

  bool get deadly => mistake?.deadly ?? false;
}

class M7GRun {
  M7GRun(this.deal);
  final M7GDeal deal;

  int i = 0;
  var halted = false;
  var fixed = false;
  var firstGoDone = false;
  var finished = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];
  bool quick = true;

  /// F1 settled lawfully (a lawful step or the fix played): the field copy is whole.
  var fieldFixed = false;

  M7GStep get step => deal.steps[i];
  M7GFork get fork => step.fork;
  bool get isLast => i == deal.steps.length - 1;
  bool get ended => finished || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => finished && deadly == null && percent >= 55;

  void tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  M7GOutcome _slip(M7GMistake m, {bool resolved = false}) {
    slips++;
    quick = false;
    return M7GOutcome(mistake: m.m, resolved: resolved);
  }

  M7GOutcome _die(M7GMistake m) {
    deadly = m.m;
    return M7GOutcome(mistake: m.m);
  }

  /// Swipe up: 'এগোন'.
  M7GOutcome go() {
    if (ended || halted) return const M7GOutcome();
    final v = step.ver;
    if (v.lawful) {
      if (fork == M7GFork.permit) fieldFixed = true;
      tag(M7GateLines.caught(fork));
      if (!firstGoDone) {
        firstGoDone = true;
        return const M7GOutcome(reason: M7GReasonKind.whyGo, resolved: true);
      }
      return const M7GOutcome(pay: 10, resolved: true);
    }
    if (v.deadly) return _die(v.mistake!);
    return _slip(v.mistake!, resolved: true);
  }

  /// Swipe down: 'থামান'.
  M7GOutcome halt() {
    if (ended || halted) return const M7GOutcome();
    if (step.ver.lawful) return _slip(M7GMistakes.needless[fork]!);
    halted = true;
    return const M7GOutcome(halted: true);
  }

  /// A tap after 'থামান': the breach (◆ and the fix deck) or a compliant
  /// object (a slip).
  M7GOutcome tapObject(String id) {
    if (ended || !halted) return const M7GOutcome();
    if (step.ver.breach.contains(id)) return const M7GOutcome(reason: M7GReasonKind.fix);
    return _slip(M7GMistakes.compliant[fork]!);
  }

  /// The right fix was paid: the lawful fix plays.
  void fixPlays() {
    fixed = true;
    halted = false;
    if (fork == M7GFork.permit) fieldFixed = true;
    tag(M7GateLines.caught(fork));
  }

  /// Listening to the coworker: one slip, and the step resolves as 'এগোন'.
  M7GOutcome listened() {
    if (ended) return const M7GOutcome();
    if (fork == M7GFork.permit && step.ver.lawful) fieldFixed = true;
    return _slip(M7GMistakes.listened[fork]!, resolved: true);
  }

  /// The job moves on to the next step.
  void advance() {
    if (i < deal.steps.length - 1) i++;
    halted = false;
    fixed = false;
  }

  void finish() {
    if (!ended) finished = true;
  }

  // --- the field copy on the clipboard ---------------------------------------
  /// The PTW number the field copy shows.
  int get fieldNo => (step.fork == M7GFork.permit && i == 0 && step.ver.id == 'numbers' && !fieldFixed) ? deal.altNo : deal.ptwNo;

  /// The issuer's box signed.
  bool get fieldIssuer => i > 0 || fieldFixed || step.ver.id == 'numbers' || step.ver.lawful;

  /// No paper at all (the issuer's word only).
  bool get fieldBlank => i == 0 && step.ver.id == 'verbal' && !fieldFixed;

  /// The player's own signature box (after the first step is judged).
  bool get fieldReceiver => i > 0;

  List<String> get fieldLines => fieldBlank
      ? const ['ফিল্ড কপি', 'কোনো কাগজ নেই']
      : _copyLines(fieldNo, issuer: fieldIssuer, receiver: fieldReceiver);
}

// ============================================================================
// Pack, probe
// ============================================================================

@immutable
class M7GatePack {
  const M7GatePack({required this.id, required this.titleBn, this.quickMs = 285000});
  final String id;
  final String titleBn;

  /// The quick bonus: a clean play inside this time (4 min 45 s, ~85 % of a
  /// clean play — the builder's estimate).
  final int quickMs;
}

const m7GatePacks = {
  'gate_m7': M7GatePack(id: 'gate_m7', titleBn: M7GateLines.title),
};

/// Test hook: what the gate is doing now. Never used by the app.
class M7GateProbe {
  _M7GRunPageState? _s;
  M7GDeal? get deal => _s?._run.deal;
  M7GRun? get run => _s?._run;

  /// intro, pan, wait, closeup, act, halted, fix, closing, freeze, done.
  String get phase => _s?._phase.name ?? 'none';

  /// The right cards of the deck now up (reason, fix deck or coworker).
  List<String> get rightNow {
    final s = _s;
    if (s == null) return const [];
    if (s.coworkerChoiceUp) return s.coworkerScript.right;
    if (s.reasonOpen) return s._reasonRight;
    return const [];
  }

  /// The ids that take a tap now (objects only).
  Set<String> get objectIds {
    final s = _s;
    return s == null ? const {} : m7gObjectIds(s._run.deal, s._run.i, fixed: s._run.fixed);
  }

  bool get coworkerUp => _s?.coworkerOpen ?? false;
  bool get busy => _s?.tableBusy ?? false;
  int get score => _s?._runScore ?? 0;
  int get step => _s?._run.i ?? 0;
}

// ============================================================================
// Page
// ============================================================================

class M7GatePermitDayPage extends StatefulWidget {
  const M7GatePermitDayPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M7GatePack pack;
  final bool muted;
  final int? seed;
  final M7GateProbe? probe;

  @override
  State<M7GatePermitDayPage> createState() => _M7GatePermitDayPageState();
}

class _M7GatePermitDayPageState extends State<M7GatePermitDayPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _M7GRunPage(
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

class _M7GRunPage extends ConsumerStatefulWidget {
  const _M7GRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.rng,
    required this.onRetry,
    this.probe,
  });

  final LevelContext ctx;
  final M7GatePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M7GateProbe? probe;

  @override
  ConsumerState<_M7GRunPage> createState() => _M7GRunPageState();
}

enum _Phase { intro, pan, wait, closeup, act, halted, fix, closing, freeze, done }

class _M7GRunPageState extends ConsumerState<_M7GRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7GRun _run = M7GRun(dealM7G(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _rightBag = LineBag(LearnFeedbackLines.right);

  /// The camera between the three spots (0 → 1 over one pan).
  late final AnimationController _panC = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  /// A deadly move playing out in colour (0 → 1).
  late final AnimationController _harm = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  _Phase _phase = _Phase.intro;
  int _runScore = 0;
  int _chain = 0;
  double _spotFrom = 0;
  double _spotTo = 0;
  String? _obj;

  // The ◆ question now and what follows its proceed.
  M7GReasonKind _reasonKind = M7GReasonKind.none;
  List<String> _reasonRight = const [];
  VoidCallback? _afterReason;

  // Cards.
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  String _cardLesson = '7.4';
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
  String _rankFrom = M7GateLines.rankFrom;
  String _rankTo = M7GateLines.rankTo;

  final _nudge = TaskNudge();
  int _nudgeN = 0;
  int _hintN = 0;
  final _hints = IdleHintController();
  final _closeKey = GlobalKey(debugLabel: 'm7g-close');
  final _clipKey = GlobalKey(debugLabel: 'm7g-clip');
  M7GGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M7GDeal get _deal => _run.deal;
  M7GStep get _step => _run.step;
  double get _pan => _spotFrom + (_spotTo - _spotFrom) * Curves.easeInOut.transform(_panC.value);

  @override
  void initState() {
    super.initState();
    widget.probe?._s = this;
    _spotFrom = _spotTo = _deal.steps.first.spot.toDouble();
  }

  @override
  void dispose() {
    if (widget.probe?._s == this) widget.probe?._s = null;
    disposeCoworker();
    _panC.dispose();
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

  /// The centre of the stage in scene px (the harm painter's space).
  Offset _stageCentre() {
    final g = _geo;
    return g == null ? const Offset(180, 300) : g.stage.center;
  }

  // --- the play ---------------------------------------------------------------
  void _start() {
    _clock.start();
    _rankNames();
    _beginStep();
  }

  void _rankNames() {
    List<CatalogModule> mods;
    try {
      mods = ref.read(contentCatalogProvider).value?.modules ?? const [];
    } catch (_) {
      mods = const [];
    }
    for (final m in mods) {
      if (m.id == 'm6' && m.rankName.isNotEmpty) _rankFrom = m.rankName;
      if (m.id == 'm7' && m.rankName.isNotEmpty) _rankTo = m.rankName;
    }
  }

  /// A new step: the camera pans if the spot changes; then someone stops and
  /// looks at the player and the guide asks.
  void _beginStep() {
    if (!mounted || _ended) return;
    final want = _step.spot.toDouble();
    _hintN = 0;
    if ((want - _spotTo).abs() < 0.01) {
      _arrive();
      return;
    }
    _spotFrom = _spotTo;
    _spotTo = want;
    if (_quiet) {
      _panC.value = 1;
      _arrive();
      return;
    }
    setState(() => _phase = _Phase.pan);
    unawaited(_panC.forward(from: 0).whenComplete(() {
      if (mounted && !_ended && _phase == _Phase.pan) _arrive();
    }));
  }

  void _arrive() {
    if (!mounted || _ended) return;
    setState(() {
      _phase = _Phase.wait;
      _obj = null;
    });
    unawaited(_sayChain([M7GateLines.ask]));
  }

  /// The scene takes a touch now (no card, deck or praise window).
  bool get _free => !_ended && _card == null && !tableBusy && !coworkerOpen;

  void _toWait() {
    if (!mounted || _ended) return;
    setState(() {
      _phase = _Phase.wait;
      _obj = null;
    });
  }

  // --- look and judge -----------------------------------------------------------
  M7GObj? _objById(String id) {
    for (final o in m7gObjects(_deal, _run.i, fixed: _run.fixed)) {
      if (o.id == id) return o;
    }
    return null;
  }

  void _tapObj(String id) {
    if (!_free) {
      _hints.missTap();
      return;
    }
    if (_phase == _Phase.wait) {
      HapticFeedback.selectionClick();
      _cue('sounds/quiz_select.ogg', volume: 0.45);
      setState(() {
        _phase = _Phase.closeup;
        _obj = id;
      });
      unawaited(_sayChain([M7GateLines.lensClose]));
      return;
    }
    if (_phase == _Phase.halted) _judge(id);
  }

  void _closeLens() {
    if (_phase != _Phase.closeup) return;
    HapticFeedback.selectionClick();
    _hush();
    _toWait();
  }

  /// A tap after 'থামান'.
  void _judge(String id) {
    if (!_free || _phase != _Phase.halted) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    _hush();
    final o = _run.tapObject(id);
    if (o.mistake != null) {
      unawaited(_slip(o.mistake!, then: () {
        if (mounted && !_ended) {
          setState(() => _phase = _Phase.halted);
          unawaited(_sayChain([M7GateLines.haltAsk]));
        }
      }));
      return;
    }
    if (o.reason == M7GReasonKind.fix) _askFix();
  }

  void _askFix() {
    final key = _step.ver.fix!;
    setState(() => _phase = _Phase.fix);
    _reasonKind = M7GReasonKind.fix;
    _reasonRight = M7GateLines.fixRight[key]!;
    _afterReason = () {
      _run.fixPlays();
      setState(() {});
      unawaited(_actThen(_afterStep));
    };
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(_reasonRight, M7GateLines.fixWrongOf(key), widget.rng),
      question: M7GateLines.fixQ,
      stillValid: () => !_ended && _reasonKind == M7GReasonKind.fix,
    ));
  }

  // --- the decision: swipe up = এগোন, swipe down = থামান -----------------------------------
  /// [go] true: swipe up.
  void _decide(bool go) {
    if (_phase != _Phase.wait || !_free) return;
    // The first touch on the field copy waits for the coworker (once a play).
    if (_step.cw && !coworkerDone) {
      if (!coworkerDue) scheduleCoworker();
      if (holdForCoworker()) {
        setState(() {});
        return;
      }
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_select.ogg', volume: 0.6);
    _hush();
    if (go) {
      unawaited(_go());
    } else {
      _halt();
    }
  }

  Future<void> _go() async {
    final o = _run.go();
    if (o.deadly) {
      await _deadly(o.mistake!, at: _stageCentre());
      return;
    }
    await _actThen(() async {
      if (!mounted || _ended) return;
      void next() {
        if (o.reason == M7GReasonKind.whyGo) {
          _askWhyGo();
        } else {
          if (o.pay > 0) {
            unawaited(_levelDelta(o.pay, _centre(), mood: GuideMood.glad));
            unawaited(_sayChain([_rightBag.next().shownBn], mood: GuideMood.glad));
          }
          _afterStep();
        }
      }

      if (o.mistake != null) {
        await _slip(o.mistake!, then: next);
        return;
      }
      next();
    });
  }

  void _halt() {
    final o = _run.halt();
    if (o.mistake != null) {
      unawaited(_slip(o.mistake!, then: () {
        if (mounted && !_ended) _toWait();
      }));
      return;
    }
    if (o.halted) {
      setState(() {
        _phase = _Phase.halted;
        _obj = null;
      });
      unawaited(_sayChain([M7GateLines.haltAsk]));
    }
  }

  /// The act plays out (a short beat), then [then].
  Future<void> _actThen(FutureOr<void> Function() then) async {
    if (!mounted || _ended) return;
    setState(() => _phase = _Phase.act);
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 60 : 650));
    if (!mounted || _ended) return;
    await then();
  }

  void _askWhyGo() {
    final key = _whyKey(_step.fork);
    setState(() => _phase = _Phase.fix);
    _reasonKind = M7GReasonKind.whyGo;
    _reasonRight = M7GateLines.whyGoRight[key]!;
    _afterReason = _afterStep;
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(_reasonRight, M7GateLines.whyWrongOf(key), widget.rng),
      question: M7GateLines.whyGoQ,
      stillValid: () => !_ended && _reasonKind == M7GReasonKind.whyGo,
    ));
  }

  String _whyKey(M7GFork f) => switch (f) {
        M7GFork.permit => 'permit',
        M7GFork.climber => 'climber',
        M7GFork.kit => 'kit',
        M7GFork.door => 'door',
        M7GFork.inside => 'inside',
        M7GFork.seal => 'seal',
        M7GFork.hook => 'hook',
        M7GFork.line => 'line',
        M7GFork.oil => 'oil',
        M7GFork.waste => 'waste',
        M7GFork.accident => 'accident',
        M7GFork.ret => 'ret',
        M7GFork.jobSheet => 'jobSheet',
        M7GFork.logbook => 'logbook',
      };

  /// After a judged step: the closing reason after F12, else the next step.
  void _afterStep() {
    if (!mounted || _ended) return;
    if (_run.isLast) {
      _askClosing();
      return;
    }
    _run.advance();
    _beginStep();
  }

  void _askClosing() {
    setState(() => _phase = _Phase.closing);
    _reasonKind = M7GReasonKind.closing;
    _reasonRight = M7GateLines.closingRight;
    _afterReason = () => unawaited(_finish());
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(_reasonRight, M7GateLines.whyWrongOf('closing'), widget.rng),
      question: M7GateLines.closeQ,
      stillValid: () => !_ended && _reasonKind == M7GReasonKind.closing,
    ));
  }

  // --- the shared success beat (ReasonTable) ----------------------------------
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
    if (_reasonKind == M7GReasonKind.closing) _run.tag(M7GateLines.caughtClose);
    _reasonKind = M7GReasonKind.none;
    final then = _afterReason;
    _afterReason = null;
    then?.call();
  }

  // --- the shared pressure moment (CoworkerMoment) -------------------------------
  @override
  CoworkerScript get coworkerScript => M7GateLines.script(_step.fork);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    if (_card != null || tableBusy) return false;
    return _phase == _Phase.wait;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listening: one slip, and the step resolves as 'এগোন'.
      final o = _run.listened();
      await _slip(o.mistake!, then: () => unawaited(_actThen(_afterStep)));
      return;
    }
    _run.tag(M7GateLines.caughtPush);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain || _ended) return;
      await _sayChain([M7GateLines.refused], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_phase == _Phase.intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7GateLines.tapWhy[_nudgeN++ % M7GateLines.tapWhy.length]
            : _nudge.next(switch (_phase) {
                _Phase.closeup => M7GateLines.lensClose,
                _Phase.halted => M7GateLines.haltAsk,
                _ => M7GateLines.tapTasks[_nudgeN++ % M7GateLines.tapTasks.length],
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
    _cardLesson = M7GMistakes.lessonOf(m);
    unawaited(_levelDelta(-10, _centre(), mood: GuideMood.warn));
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _afterCard = then;
    });
    unawaited(bookMistake(ref, _ctxFor(_cardLesson), m));
    final speak = await SpokenOnce.first('m7gate/${m.key}');
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
    _cardLesson = M7GMistakes.lessonOf(m);
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
    final speak = await SpokenOnce.first('m7gate/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M7GateLines.deadlyWord : M7GateLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
          _toWait();
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
    _run.finish();
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
      // The rank gate: সিনিয়র → সুপারভাইজার (Module 7's rank; M7-13).
      await save.unlockRank(7);
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
    await _say(_run.passed ? M7GateLines.promoted(_rankTo) : M7GateLines.fail, mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
  M7GView get _view => M7GView(
        pan: _pan,
        light: _deal.light,
        props: _phase == _Phase.intro ? const [] : m7gObjects(_deal, _run.i, fixed: _run.fixed),
        laneLeft: _deal.laneLeft,
        crewCols: [for (final k in _deal.crew) m7gShirts[k]],
        key: '${_run.i}-${_run.fixed}-${_phase == _Phase.intro}',
        fixed: _run.fixed,
        propSpot: _step.spot,
        vista: _step.fork == M7GFork.ret,
      );

  /// The step's objects take taps while it waits or after 'থামান'.
  bool get _objectsLive => _phase == _Phase.wait || _phase == _Phase.halted || _phase == _Phase.closeup;

  List<Widget> _scene(SceneMetrics m) {
    final g = _geo = M7GGeo(m.height, m.inset);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final objs = _phase == _Phase.intro ? const <M7GObj>[] : m7gObjects(_deal, _run.i, fixed: _run.fixed);
    final showBubble = _phase == _Phase.wait || _phase == _Phase.closeup || _phase == _Phase.halted;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                key: const ValueKey('world-paint'),
                child: RepaintBoundary(child: CustomPaint(painter: M7GWorldPainter(geo: g, view: _view))),
              ),
              // The stage: tap anything for a close-up (all alike); empty scene is ignored.
              Positioned.fromRect(
                key: const ValueKey('stage'),
                rect: g.stage,
                child: GestureDetector(key: const ValueKey('m7g-stage'), behavior: HitTestBehavior.opaque, onTap: _hints.missTap),
              ),
              if (_objectsLive)
                for (final o in [...objs.where((o) => o.id != 'hid'), ...objs.where((o) => o.id == 'hid')])
                  if (o.hit)
                    Positioned.fromRect(
                      key: ValueKey('obj-${_run.i}-${o.id}'),
                      rect: g.fr(o.r),
                      child: GestureDetector(
                        key: ValueKey('m7g-obj-${o.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _tapObj(o.id),
                        child: Semantics(button: true, label: o.title.isEmpty ? o.id : o.title, child: const SizedBox.expand()),
                      ),
                    ),
              if (showBubble && _phase != _Phase.intro)
                Positioned.fromRect(
                  key: const ValueKey('crew-bubble'),
                  rect: g.bubble,
                  child: IgnorePointer(child: _CrewBubble(text: M7GateLines.crew(_step.fork), frozen: _phase == _Phase.halted)),
                ),
              Positioned.fromRect(
                key: const ValueKey('clip'),
                rect: g.clip,
                child: _Clipboard(
                  key: _clipKey,
                  no: _run.fieldNo,
                  issuer: _run.fieldIssuer,
                  receiver: _run.fieldReceiver,
                  blank: _run.fieldBlank,
                  live: _phase == _Phase.wait && _free,
                  onTap: () => _tapObj('field'),
                  onSwipe: _decide,
                ),
              ),
            ],
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('harm'),
          child: IgnorePointer(child: CustomPaint(painter: M7GHarmPainter(at: _harmAt, k: _harm.value))),
        ),
    ];
  }

  /// How to touch now, never what.
  HintSpec? _hint() {
    final g = _geo;
    if (g == null) return null;
    final all = [...m7gHintRects(_deal, _run.i, fixed: _run.fixed).map(g.fr), g.clip];
    switch (_phase) {
      case _Phase.wait:
        final n = _hintN++ % 3;
        if (n == 0 && all.length > 1) return HintSpec.sweep(all, space: HintSpace.scene);
        // A short swipe up, then a short swipe down, on the field copy.
        return HintSpec.swipe(g.clip.center, toward: Offset(0, n == 2 ? 1 : -1), travel: 40, space: HintSpace.scene);
      case _Phase.halted:
        return all.length > 1 ? HintSpec.sweep(all, space: HintSpace.scene) : null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final scale = size.width / 360;
    final live = _phase != _Phase.intro && _mark == null && !struckOut && !_freeze;
    final waiting = live && (_phase == _Phase.wait || _phase == _Phase.halted) && _card == null && !coworkerOnScreen && !tableBusy;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final lensUp = live && _phase == _Phase.closeup && !deckUp && _card == null && !coworkerOnScreen && !tableBusy;
    final g = _geo;
    final clipH = g == null ? 118.0 : g.clip.height * scale + 10;
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
            animation: Listenable.merge([_panC, _harm]),
            progress: DoProgress(
              labels: [for (var k = 1; k <= _run.deal.steps.length; k++) enDigits('ধাপ $k')],
              done: {for (var k = 0; k < _run.i; k++) k, if (_run.finished) _run.i},
              current: _run.finished ? null : _run.i,
              quiet: quiet,
            ),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.i}-${_phase.name}-${_run.halted}',
            hintController: _hints,
            hintAutoMiss: true,
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (lensUp && _obj != null) _lens(pad),
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
              if (live && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp || lensUp ? 300 : clipH),
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
                  line: M7GateLines.intro,
                  alarm: 'sounds/learn/card_deal_a.ogg',
                  muted: _muted,
                  onDone: _start,
                ),
                Positioned(
                  key: const ValueKey('intro-docket'),
                  left: 24,
                  right: 24,
                  top: pad.top + 66,
                  child: IgnorePointer(child: _DocketCard(line: M7GateLines.docketCall(_deal.ptwNo), quiet: quiet)),
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

  /// The close-up of the object tapped: its real markings, then বন্ধ.
  Widget _lens(EdgeInsets pad) {
    final id = _obj!;
    final o = _objById(id);
    final title = id == 'field' ? M7GateLines.fieldCopy : (o?.title ?? '');
    final lines = id == 'field' ? _run.fieldLines : (o?.lines ?? const <String>[]);
    return Positioned(
      key: const ValueKey('sheet-lens'),
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: EdgeInsets.only(bottom: pad.bottom),
        child: _LensSheet(title: title, lines: lines, closeKey: _closeKey, onClose: _closeLens),
      ),
    );
  }
}

// ============================================================================
// Pieces
// ============================================================================

/// The crew's words as he stops and looks at the player.
class _CrewBubble extends StatelessWidget {
  const _CrewBubble({required this.text, required this.frozen});
  final String text;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: frozen ? const Color(0xFF8A8A8A) : const Color(0xFF1C2126), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Text(enDigits(text), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.2)),
    );
  }
}

/// The field copy of the PTW on its clipboard, docked at the bottom edge:
/// swipe UP toward the scene = এগোন, swipe DOWN into the pocket = থামান; a
/// tap looks at it.
class _Clipboard extends StatefulWidget {
  const _Clipboard({super.key, required this.no, required this.issuer, required this.receiver, required this.blank, required this.live, required this.onTap, required this.onSwipe});
  final int no;
  final bool issuer;
  final bool receiver;
  final bool blank;
  final bool live;
  final VoidCallback onTap;
  final void Function(bool up) onSwipe;

  @override
  State<_Clipboard> createState() => _ClipboardState();
}

class _ClipboardState extends State<_Clipboard> {
  double _dy = 0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: M7GateLines.fieldCopy,
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'এগোন'): () => widget.onSwipe(true),
        const CustomSemanticsAction(label: 'থামান'): () => widget.onSwipe(false),
      },
      child: GestureDetector(
        key: const ValueKey('m7g-clip'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onVerticalDragUpdate: (d) {
          if (!widget.live) return;
          setState(() => _dy = (_dy + d.delta.dy).clamp(-34.0, 34.0));
        },
        onVerticalDragEnd: (d) {
          final dy = _dy;
          final v = d.primaryVelocity ?? 0;
          setState(() => _dy = 0);
          if (!widget.live) return;
          if (dy < -14 || v < -500) {
            widget.onSwipe(true);
          } else if (dy > 14 || v > 500) {
            widget.onSwipe(false);
          }
        },
        onVerticalDragCancel: () => setState(() => _dy = 0),
        child: Transform.translate(
          offset: Offset(0, _dy),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6A4A2A),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, -2))],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEF), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFB08A4A))),
              child: widget.blank
                  ? Center(child: Text(M7GateLines.fieldCopy, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ink.withValues(alpha: 0.5))))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.assignment_rounded, color: Color(0xFF7A1F1F), size: 13),
                          const SizedBox(width: 4),
                          Text(M7GateLines.fieldCopy, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F), height: 1.1)),
                          const Spacer(),
                          Text(M7GateLines.ptwNo(widget.no), style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.1)),
                        ]),
                        const SizedBox(height: 2),
                        Text('কাজ: 11 kV শাটডাউন', style: bangla(fontSize: 10, fontWeight: FontWeight.w700, color: SlmColors.ink, height: 1.15)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Expanded(child: _SignBox(label: 'ইস্যুকারী', signed: widget.issuer)),
                          const SizedBox(width: 6),
                          Expanded(child: _SignBox(label: 'গ্রহণকারী', signed: widget.receiver)),
                        ]),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignBox extends StatelessWidget {
  const _SignBox({required this.label, required this.signed});
  final String label;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.fromLTRB(4, 1, 4, 1),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF7A5C2E), width: 0.9)),
      child: Stack(
        children: [
          Text(label, style: bangla(fontSize: 8, fontWeight: FontWeight.w700, color: SlmColors.ink.withValues(alpha: 0.7), height: 1.1)),
          if (signed) Positioned(left: 6, right: 6, bottom: 2, child: CustomPaint(size: const Size(40, 12), painter: _ScribblePainter())),
        ],
      ),
    );
  }
}

class _ScribblePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Path()
      ..moveTo(0, s.height * 0.8)
      ..quadraticBezierTo(s.width * 0.25, -s.height * 0.2, s.width * 0.45, s.height * 0.7)
      ..quadraticBezierTo(s.width * 0.7, s.height * 0.1, s.width, s.height * 0.5);
    c.drawPath(p, Paint()
      ..color = const Color(0xFF244A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(_ScribblePainter old) => false;
}

/// The close-up: what the thing shows, line by line (raw markings), then বন্ধ.
class _LensSheet extends StatelessWidget {
  const _LensSheet({required this.title, required this.lines, required this.closeKey, required this.onClose});
  final String title;
  final List<String> lines;
  final GlobalKey closeKey;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return IdleHint(
      waiting: true,
      waitKey: '$title|${lines.join('|')}',
      // The one way forward: close the close-up.
      spec: (_) => HintSpec.tapOn(closeKey),
      child: Container(
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
                const Icon(Icons.visibility_rounded, size: 18, color: SlmColors.gold300),
                const SizedBox(width: 8),
                Expanded(child: Text(enDigits(title), maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.gold200, height: 1.2))),
              ],
            ),
            const SizedBox(height: 8),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 6, right: 8), child: Icon(Icons.circle, size: 6, color: SlmColors.gold300)),
                    Expanded(child: Text(enDigits(l), style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ivory, height: 1.3))),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: M7GateLines.close,
              child: Material(
                key: closeKey,
                color: const Color(0xFF1B2A44),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: const ValueKey('m7g-lens-close'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: onClose,
                  child: SizedBox(
                    height: 48,
                    child: Center(child: Text(M7GateLines.close, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
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
            Text(M7GateLines.docketTitle, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F))),
            const SizedBox(width: 12),
            Expanded(child: Text(line, style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.3))),
          ],
        ),
      ),
    );
  }
}

/// The rank-up: সিনিয়র → সুপারভাইজার, with the module's badge.
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
            Text(M7GateLines.rankUp, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.gold200)),
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
            if (M7GateLines.badge.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(M7GateLines.badge, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
            ],
          ],
        ),
      ),
    );
  }
}
