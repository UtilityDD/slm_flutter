import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'm8_sop_clock_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_sop_clock_world.dart' show M8SopDamage, M8SopGeo, M8SopKind, M8SopZone, kM8SopMapH, kM8SopMapW, kM8SopMinPerUnit, kM8SopOffice, kM8SopTownEdge, m8SopDistance;

// Lesson 8.3 "স্ট্যান্ডার্ডস অফ পারফর্ম্যান্স (SoP): সময়ের মূল্য", কাজ 1
// "ঘড়ি টিক-টিক — সময়ের মধ্যে আলো" (pack do_8_3_a, engineType m8_sop_clock).
// The module's one map-dispatch level: the section map, the crew van and the
// pocket phone, against the lesson's SoP clocks.
//
// A shift runs from 08:00 to 17:00 game time. Complaint pins drop on the map
// (the drop moment is the registration time; the clock starts there, lesson
// point 1). Every pin looks the same: a docket opens on a tap (complaint no.,
// type, area শহর / গ্রাম, the date and time it was registered) and shows no
// limit, no time left. The lesson's limits (live text 2026-11-16):
//   ফিউজ অফ: শহর 3 ঘন্টা · গ্রাম 6 ঘন্টা (জুন–সেপ্টেম্বর 8 ঘন্টা) — the
//     docket's month is the only clue to which village limit applies;
//   LT তার ছিঁড়লে: শহর 4 ঘন্টা · গ্রাম 10 ঘন্টা (বর্ষায় 16 ঘন্টা);
//   DTR: শহর 12 ঘন্টা · গ্রাম 48 ঘন্টা, JE / স্টেশন ম্যানেজারকে সাথে সাথে;
//   মিটার 7 থেকে 15 দিন · লুজ কন্টাক্ট 15 days (long-limit decoys).
// A DTR's and a decoy's own limit runs past the shift: never failed on time.
//
// The loop: drag the van onto a pin (the clock moves by the distance) → the
// close-up opens (a push-in) → HOLD the work button (the ring fills, the clock
// runs fast, the houses light) → on the map the pin looks as before: the
// docket is still open → open the phone, SWIPE the finished docket to close it
// (an unfinished row bounces). A burnt DTR: the phone's contacts (JE ·
// স্টেশন ম্যানেজার · কল সেন্টার · বাড়ি · 'পরে করব'), HOLD one to call: JE or
// the station manager at once is right. One dealt delay event: a store delay
// (a decision deck: LT jumpering or telling the consumers vs waiting silently /
// 'কেউ কেস করবে না') or a storm (the player raises the camera and photographs
// the broken pole and fallen tree before the repair; the JE asks for the
// photos afterwards).
//
// The game clock moves only with the player's moves (the van, the work, a
// call) — an idle screen draws zero frames. When nothing on the map is left to
// do and a call is still to come, it skips to that call.
//
// Slips only (spec: no deadly act; rulings M8-1, R7/R21/R22): a pin passes its
// limit (counted from registration) before its docket is closed (one slip per
// pin; a different card when the work was done but the docket left open); the
// burnt DTR not told to the JE / station manager; the storm with no photos when
// the JE asks; a store delay met by waiting silently; listening to the
// coworker. Three slips strike out. At 17:00 whatever required is still open is
// a slip. A wrong 'why' card costs the ◆ only; a wrong card of the store deck
// is a slip (M8-8).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the full
// scene (m8_sop_clock_world.dart), corner guide, a right move puts ◆ on the
// table → 'কেন …?' (the first docket closed in its limit, the second, the DTR
// call, the storm photos, the store decision), the coworker once a play (the
// rural myth on the first van drag away from yesterday's rural pin, or the
// docket push on the first finished repair; the van drag and the swipe call
// holdForCoworker, with a fallback so he always comes). Gesture hands: a
// sweep over every open pin alike or a short generic nudge on the van; a sweep
// over the phone and the van once a repair is done; a hold ring on the work
// button; a generic swipe across the phone's list header; a sweep over every
// contact and 'পরে করব'; in a storm close-up a sweep over the toolbar, then the
// whole scene (never a tap on the damage). None during the intro, the coworker
// beats, cards, the table, drives or results.

// ============================================================================
// Content
// ============================================================================

/// The one dealt delay event (lesson pro tips 1–3).
enum M8SopEvent { store, storm }

/// The coworker's push (one per play).
enum M8SopPush { rural, docket }

/// What a reason asks about.
enum M8SopWhy { first, docket, dtr, storm, store }

/// The burnt DTR's contacts.
enum M8SopContact { je, manager, callCentre, home }

/// The shift runs 08:00 to 17:00 game time (pacing only).
const double kM8SopShiftEnd = 540;

/// A call to the JE / station manager takes this long (pacing only).
const double kM8SopCallMin = 10;

/// The months with the village's longer limits (জুন–সেপ্টেম্বর).
bool m8SopMonsoon(int month) => month >= 6 && month <= 9;

/// The lesson's limit in game minutes from registration, or null (no limit
/// the game fails on: the storm is force majeure when documented).
double? m8SopLimit(M8SopKind k, M8SopZone z, {required bool monsoon}) => switch (k) {
      M8SopKind.urbanFuse => 180,
      M8SopKind.ruralFuse => monsoon ? 480 : 360,
      M8SopKind.wireBreak => z == M8SopZone.town ? 240 : (monsoon ? 960 : 600),
      M8SopKind.dtr => z == M8SopZone.town ? 720 : 2880,
      M8SopKind.meter => 7 * 1440,
      M8SopKind.loose => 15 * 1440,
      M8SopKind.storm => null,
    };

/// The limits the game fails on (a long limit never fails in a shift).
bool m8SopFailable(M8SopKind k) => k == M8SopKind.urbanFuse || k == M8SopKind.ruralFuse || k == M8SopKind.wireBreak;

/// Work minutes at the pin (a DTR is a phone call instead).
double m8SopWorkMin(M8SopKind k) => switch (k) {
      M8SopKind.urbanFuse => 25,
      M8SopKind.ruralFuse => 30,
      M8SopKind.wireBreak => 120,
      M8SopKind.storm => 120,
      M8SopKind.meter => 60,
      M8SopKind.loose => 45,
      M8SopKind.dtr => 0,
    };

/// 'HH:MM' of a game minute (0 = 08:00).
String m8SopHhmm(double minute) {
  final total = (480 + minute).floor();
  final m = ((total % 1440) + 1440) % 1440;
  return enDigits('${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}');
}

abstract final class M8SopClockLines {
  static const title = 'ঘড়ি টিক-টিক';
  // DRAFT wording — owner (M6-12). Spec: 'কমপ্লেইন ঢুকছে, SoP-এর ঘড়ি চলছে —
  // সময়ের মধ্যে আলো ফেরান!'
  static const intro = 'কমপ্লেইন ঢুকছে, SoP-এর ঘড়ি চলছে — সময়ের মধ্যে আলো ফেরান!';

  // The guide's task now (tap him: the same task, a different way). They only
  // restate the job: no urgency, no order, no deadline.
  static const askMap = 'কমপ্লেইনগুলো সামলান — ভ্যান নিয়ে রওনা দিন।';
  static const askMapOther = 'ভ্যান টেনে যে কমপ্লেইনে যাবেন, সেখানে নিয়ে যান।';
  static const askWork = 'কাজটা সারুন — বোতামটা ধরে রাখুন।';
  static const askDtr = 'ট্রান্সফরমার জ্বলে গেছে — এবার কী করবেন?';
  static const askSheet = 'ফোনে খোলা ডকেটগুলো দেখে নিন।';
  static const askStore = 'ট্রান্সফরমার আসতে দেরি — এখন কী করবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askMap, askMapOther, askWork, askDtr, askSheet, askStore];

  static const dropRing = 'কল সেন্টারে নতুন কমপ্লেইন এল।';
  static const docketBounce = 'এই ডকেট এখনও বন্ধ হবে না — কাজ বাকি।';
  static const jeStore = 'জুনিয়র ইঞ্জিনিয়ার জানালেন — স্টোর থেকে DTR আসতে দেরি হবে।';
  static const jeStormAsk = 'জুনিয়র ইঞ্জিনিয়ার জানতে চাইলেন — ঝড়ের ছবি-নথি আছে?';

  // On-screen words (a worker's own labels; not spoken).
  static const work = 'কাজ করি';
  static const backMap = 'ম্যাপে ফিরি';
  static const phoneTitle = 'খোলা ডকেট';
  static const phoneLabel = 'ফোন';
  static const cameraLabel = 'ক্যামেরা';
  static const mapLabel = 'সেকশনের ম্যাপ';
  static const closeupLabel = 'কমপ্লেইনের জায়গা';
  static const later = 'পরে করব';
  static String contactName(M8SopContact c) => switch (c) {
        M8SopContact.je => 'JE',
        M8SopContact.manager => 'স্টেশন ম্যানেজার',
        M8SopContact.callCentre => 'কল সেন্টার',
        M8SopContact.home => 'বাড়ি',
      };

  static const months = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];

  static String kindName(M8SopKind k) => switch (k) {
        M8SopKind.urbanFuse || M8SopKind.ruralFuse => 'ফিউজ অফ',
        M8SopKind.wireBreak => 'LT তার ছিঁড়ে গেছে',
        M8SopKind.storm => 'ঝড়ে পোল ভাঙা',
        M8SopKind.dtr => 'ট্রান্সফরমার জ্বলে গেছে',
        M8SopKind.meter => 'মিটার পুড়ে গেছে',
        M8SopKind.loose => 'ভোল্টেজ কম (লুজ কন্টাক্ট)',
      };
  static String zoneName(M8SopZone z) => z == M8SopZone.town ? 'শহর' : 'গ্রাম';
  static String docketNo(int n) => enDigits('কমপ্লেইন নং $n');
  static String docketArea(M8SopZone z) => 'এলাকা: ${zoneName(z)}';
  /// 'নথিভুক্ত: 14 জুলাই, 05:10' — the date moves back a day when the pin was
  /// registered before midnight (today's [day] is 2 or later).
  static String docketAt(int day, int month, double reg) {
    final shift = ((480 + reg.floor()) / 1440).floor();
    return enDigits('নথিভুক্ত: ${day + shift} ${months[month - 1]}, ${m8SopHhmm(reg)}');
  }

  /// The reasons (the right ones fit what was done; the wrong ones are the
  /// lesson's myths and field excuses; all about the same length).
  static const whyQ = <M8SopWhy, String>{
    M8SopWhy.first: 'কেন এই কমপ্লেইনটা আগে ধরলেন?',
    M8SopWhy.docket: 'কাজ শেষে সাথে সাথে ডকেট ক্লোজ কেন?',
    M8SopWhy.dtr: 'ট্রান্সফরমার জ্বলেছে দেখে কেন তখনই ফোন করলেন?',
    M8SopWhy.storm: 'ঝড়ের ক্ষতির ছবি কেন তুললেন?',
    M8SopWhy.store: 'দেরি হবে জেনে কেন এই ব্যবস্থা নিলেন?',
  };
  static const whyRight = <M8SopWhy, List<String>>{
    M8SopWhy.first: ['নথিভুক্ত হওয়া থেকেই ঘড়ি চলে, সীমা হিসেব করে এটা আগে ধরলাম', 'ধরনের সীমা আর নথিভুক্তির সময় দেখে এটার সময় আগে ফুরোবে বুঝলাম'],
    M8SopWhy.docket: ['ক্লোজ না করলে খাতায় কাজটাই হয়নি, আর পেনাল্টি বাড়তেই থাকে', 'ডকেট খোলা থাকলে সিস্টেমে কমপ্লেইন চলছেই, ঘড়িও থামে না'],
    M8SopWhy.dtr: ['আগে জানালে JE-র নতুন ট্রান্সফরমারের লজিস্টিক আগে তৈরি হয়', 'সাথে সাথে জানালে নতুন ট্রান্সফরমারের জোগাড় আগে শুরু হয়'],
    M8SopWhy.storm: ['ঝড়ে দেরি হলে পেনাল্টি লাগে না, কিন্তু ছবি আর নথি থাকা চাই', 'ঝড়ের কারণ প্রমাণ করতে সঠিক ডকুমেন্টেশন আর ছবি রাখতে হয়'],
    M8SopWhy.store: ['গ্রাহক জানলে বা আলো পেলে সাধারণত কেস করেন না, পেনাল্টিও বাঁচে', 'কাজ চলছে জানলে গ্রাহক কেস করেন না, কিছু বাড়িতে আলোও থাকে'],
  };
  static const myths = [
    'গ্রামের কমপ্লেইনে কেউ তাড়া দেয় না, তাই শহরেরটা আগে ধরলাম',
    'যেটা ভ্যানের সবচেয়ে কাছে, সেটাই আগে ধরা নিয়ম বলে ধরলাম',
    'কমপ্লেইনের ঘড়ি কাজ শুরু থেকে চলে, তাই যেটা হোক আগে ধরলাম',
    'বড় কাজ আগে সেরে ফেলাই নিয়ম, ছোটগুলো পরে দেখা যাবে বলে',
    'কমপ্লেইন নম্বর যেটার বড়, সেটাই আগে ধরতে হয় বলে ধরলাম',
    'সময়সীমা শুধু শহরের জন্য, তাই গ্রামেরটা পরেই দেখা যায়',
    'জরিমানা কোম্পানি নিজের ইচ্ছামতো দেয়, তাই তাড়ার কিছু নেই',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  /// The store delay's decision deck (a field decision: a wrong card is a slip).
  static const storeRight = ['পাশের ট্রান্সফরমার থেকে LT জাম্পারিং করে কিছু আলো দিই', 'গ্রাহকদের SMS বা মুখে জানাই — ট্রান্সফরমার আসতে দেরি হবে'];
  static const storeWrong = [
    'চুপচাপ অপেক্ষা করি, ট্রান্সফরমার এলে সবাই এমনিই জানবে',
    'গ্রাম তো, কেউ কেস করবে না — কিছু জানানোর দরকার নেই',
    'কেউ ফোন করলে তখন বলব, আগে থেকে জানানোর দরকার কী',
    'আজ বাড়ি যাই, ট্রান্সফরমার এলে কাল আবার আসব আমরা',
    'গ্রাহক বিরক্ত হবেন, তাই কাউকে কিছু না বলাই ভালো',
    'জাম্পারিং না করে নতুন ট্রান্সফরমারের অপেক্ষাই ঠিক হবে',
  ];

  // The careless coworker (once a play). DRAFT wording — owner (M6-12): the
  // rural myth is the lesson's myth word for word; the docket push is new.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerRural = CoworkerScript(
    line: 'গ্রামে কারেন্ট না থাকলে কেউ দেখার নেই, 24 ঘন্টা কোনো ব্যাপার না।',
    exitLine: coworkerExit,
    right: ['না, গ্রামের গ্রাহকও কমপ্লেইন করে, WBERC নজর রাখে', 'না, গ্রামের কমপ্লেইনেও সময়ের সীমা আছে, আমি যাচ্ছি', 'না, গ্রামের ঘড়িও চলে, আগে সময় হিসেব করে যাব'],
    wrong: [
      'ঠিক বলেছ, গ্রামেরটা পরে দেখলেই চলবে, আগে অন্যটা',
      'হ্যাঁ, গ্রামে তো কেউ দেখার নেই, তাই পরে যাই',
      'আচ্ছা, আগে শহরেরটা সেরে নিই, গ্রামেরটা পরে দেখব',
      'ঠিক আছে, গ্রামের গ্রাহক তো কেস করবে না, পরে যাব',
      'হ্যাঁ, 24 ঘন্টা কোনো ব্যাপারই না, গ্রামে পরে যাব',
    ],
    asks: ['কী করবেন?', 'ও বলছে গ্রামেরটা পরে দেখলেও চলবে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerDocket = CoworkerScript(
    line: 'ক্লোজ-টোজ পরে একসাথে করে দেব, আগে পরের কাজে চলো!',
    exitLine: coworkerExit,
    right: ['না, আগে ডকেট ক্লোজ — নইলে খাতায় কাজটাই হয়নি', 'না, কাজ শেষ হলেই ডকেট ক্লোজ করব, দেরি নয়', 'না, ডকেট খোলা রেখে আমি পরের কাজে যাব না'],
    wrong: [
      'ঠিক আছে, সব শেষে একবারেই ডকেট ক্লোজ করব',
      'হ্যাঁ, ক্লোজ পরে হবে, আগে পরের কাজে যাই',
      'আচ্ছা, ডকেট খোলা থাকলে কী আর হবে, চলো',
      'ঠিক আছে, দিনের শেষে সব একসাথে ক্লোজ করব',
      'হ্যাঁ, সিস্টেমে ক্লোজ না করলেও চলে, চলো যাই',
    ],
    asks: ['কী করবেন?', 'ও বলছে ক্লোজ পরে করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M8SopPush p) => p == M8SopPush.rural ? coworkerRural : coworkerDocket;
  static const allCoworkers = [coworkerRural, coworkerDocket];

  static String callHeld(M8SopPush p) => p == M8SopPush.rural ? 'ঠিক! গ্রামের ঘড়িও চলে, WBERC সব দেখে।' : 'ঠিক! কাজ শেষ হলেই ডকেট ক্লোজ।';

  static const allSet = 'সব কমপ্লেইনই সময়ের মধ্যে — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কমপ্লেইন নথিভুক্ত হওয়া থেকেই ঘড়ি চলে।';

  // "আজ যা ধরলেন": one line per docket, then what stayed open (long limits).
  static String limitLabel(M8SopKind k, M8SopZone z, {required bool monsoon}) => switch (k) {
        M8SopKind.urbanFuse => 'শহরে ফিউজ অফ: 3 ঘন্টা',
        M8SopKind.ruralFuse => monsoon ? 'গ্রামে ফিউজ অফ: 8 ঘন্টা (বর্ষা)' : 'গ্রামে ফিউজ অফ: 6 ঘন্টা',
        M8SopKind.wireBreak => z == M8SopZone.town ? 'LT তার, শহরে: 4 ঘন্টা' : (monsoon ? 'LT তার, গ্রামে: 16 ঘন্টা (বর্ষা)' : 'LT তার, গ্রামে: 10 ঘন্টা'),
        M8SopKind.storm => 'ঝড়ে ক্ষতি: ছবি-নথি সহ',
        M8SopKind.dtr => z == M8SopZone.town ? 'DTR শহরে: 12 ঘন্টা' : 'DTR গ্রামে: 48 ঘন্টা',
        M8SopKind.meter => 'মিটার: 7 থেকে 15 দিন',
        M8SopKind.loose => 'লুজ কন্টাক্ট: 15 দিন',
      };
  static String caughtDocket(int no, String limit, double reg, double closed) => enDigits('ডকেট $no — $limit; ${m8SopHhmm(reg)} → ক্লোজ ${m8SopHhmm(closed)}');
  static String caughtInformed(String name) => 'ট্রান্সফরমার জ্বলতেই $name-কে জানানো';
  static String caughtOpen(String limit) => '$limit — খোলা, সময় আছে';
  static const caughtPhotos = 'ঝড়ের ছবি-নথি আগেই তোলা';
  static const caughtStore = 'দেরি হবে জেনে গ্রাহকের কথা ভাবা';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until then
  /// the device voice). The kit's own praise and 'wrong' bags are left out.
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        ...tapWhy,
        dropRing,
        docketBounce,
        jeStore,
        jeStormAsk,
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks,
        for (final p in M8SopPush.values) callHeld(p),
        allSet,
        quick,
        fail,
        for (final m in M8SopClockMistakes.all) m.textBn,
      }.toList();
}

abstract final class M8SopClockMistakes {
  static const _dir = 'assets/game/art/m8_sop_clock';

  // DRAFT wording — owner (M6-12). Lesson point 0 = ফিউজ অফ, 1 = ব্রেকডাউন,
  // 2 = DTR (the live text's point order).
  static const lateUrban = DoMistake(
    key: '8.3/m8_sop_clock/late-urban',
    textBn: 'শহরে ফিউজ অফ — কমপ্লেইন নথিভুক্ত হওয়া থেকেই ঘড়ি চলে, 3 ঘন্টার মধ্যে সারাতে হয়।',
    art: '$_dir/clock.svg',
    lessonPoint: 0,
  );
  static const lateRural = DoMistake(
    key: '8.3/m8_sop_clock/late-rural',
    textBn: 'গ্রামে ফিউজ অফ — 6 ঘন্টার মধ্যে, জুন–সেপ্টেম্বর 8 ঘন্টার মধ্যে। গ্রামের ঘড়িও চলে।',
    art: '$_dir/clock.svg',
    lessonPoint: 0,
  );
  static const lateWire = DoMistake(
    key: '8.3/m8_sop_clock/late-wire',
    textBn: 'LT তার ছিঁড়লে শহরে 4 ঘন্টা, গ্রামে 10 ঘন্টা (বর্ষায় 16 ঘন্টা) — তার মধ্যে সারাতে হয়।',
    art: '$_dir/clock.svg',
    lessonPoint: 1,
  );
  static const lateDocket = DoMistake(
    key: '8.3/m8_sop_clock/late-docket',
    textBn: 'কাজ শেষ হওয়া মাত্রই ডকেট ক্লোজ করুন। না করলে কোম্পানির খাতায় আপনি এখনো কাজ করেননি, আর পেনাল্টি বাড়ছে।',
    art: '$_dir/docket.svg',
    lessonPoint: 0,
  );
  static const dtrNoInform = DoMistake(
    key: '8.3/m8_sop_clock/dtr-no-inform',
    textBn: 'ট্রান্সফরমার জ্বলে গেলে দেরি না করে সাথে সাথে জুনিয়র ইঞ্জিনিয়ার বা স্টেশন ম্যানেজারকে জানান, যাতে লজিস্টিক রেডি করা যায়।',
    art: '$_dir/dtr.svg',
    lessonPoint: 2,
  );
  static const stormNoPhoto = DoMistake(
    key: '8.3/m8_sop_clock/storm-no-photo',
    textBn: 'ঝড়ে সারাতে দেরি হলে SoP-এর পেনাল্টি লাগে না — কিন্তু তার জন্য সঠিক ডকুমেন্টেশন আর ছবি রাখা জরুরি।',
    art: '$_dir/storm.svg',
    lessonPoint: 1,
  );
  static const storeSilent = DoMistake(
    key: '8.3/m8_sop_clock/store-silent',
    textBn: 'ট্রান্সফরমার আসতে দেরি হলে পাশের ট্রান্সফরমার থেকে LT জাম্পারিং করে কিছু গ্রাহককে আলো দিন, আর SMS বা মুখে জানিয়ে দিন — গ্রাহক জানলে সাধারণত কেস করেন না।',
    art: '$_dir/store.svg',
    lessonPoint: 2,
  );
  static const pushRural = DoMistake(
    key: '8.3/m8_sop_clock/push-rural',
    textBn: 'পুরনো দিন শেষ — এখন গ্রামের গ্রাহকরাও স্মার্টফোনে কমপ্লেইন করেন, আর WBERC গ্রামের পারফর্ম্যান্সও কড়া নজরে দেখে।',
    art: '$_dir/rural.svg',
    lessonPoint: 0,
  );
  static const pushDocket = DoMistake(
    key: '8.3/m8_sop_clock/push-docket',
    textBn: 'কাজ শেষ হওয়া মাত্রই ডকেট ক্লোজ করুন। সিস্টেমে ক্লোজ না হলে খাতায় কাজটাই হয়নি।',
    art: '$_dir/docket.svg',
    lessonPoint: 0,
  );

  /// The card for a pin that passed its limit (work done, docket left open:
  /// the daily check's card).
  static DoMistake late(M8SopKind k, {required bool workDone}) {
    if (workDone) return lateDocket;
    return switch (k) {
      M8SopKind.urbanFuse => lateUrban,
      M8SopKind.ruralFuse => lateRural,
      _ => lateWire,
    };
  }

  /// Listening to his push is the act it pushes (X2/B1): a slip.
  static DoMistake push(M8SopPush p) => p == M8SopPush.rural ? pushRural : pushDocket;

  static const List<DoMistake> all = [lateUrban, lateRural, lateWire, lateDocket, dtrNoInform, stormNoPhoto, storeSilent, pushRural, pushDocket];
}

// ============================================================================
// The deal and the rules (pure)
// ============================================================================

/// One complaint of a play's deal.
@immutable
class M8SopPinDeal {
  const M8SopPinDeal({required this.kind, required this.zone, required this.unit, required this.regAt, required this.docketNo});

  final M8SopKind kind;
  final M8SopZone zone;

  /// Map units (320 x 380).
  final Offset unit;

  /// Registration, in game minutes from 08:00 (negative = earlier today).
  /// The pin drops on the map at this moment (at the start when <= 0).
  final double regAt;
  final int docketNo;

  bool get failable => m8SopFailable(kind);

  /// Needed to end the shift early (a meter and a loose contact are long-limit
  /// decoys the shift may leave open).
  bool get required => kind != M8SopKind.meter && kind != M8SopKind.loose;
}

@immutable
class M8SopDeal {
  const M8SopDeal({
    required this.pins,
    required this.nearIdx,
    required this.event,
    required this.push,
    required this.month,
    required this.day,
    required this.vanStart,
    required this.contactOrder,
  });

  /// In drop order: the two at the start first.
  final List<M8SopPinDeal> pins;

  /// Today's rural item registered earlier today with most of its limit spent.
  final int nearIdx;
  final M8SopEvent event;
  final M8SopPush push;
  final int month;
  final int day;
  final Offset vanStart;

  /// The four contacts in the order the phone lists them (fixed for the play).
  final List<M8SopContact> contactOrder;

  bool get monsoon => m8SopMonsoon(month);
  double? limitOf(int i) => m8SopLimit(pins[i].kind, pins[i].zone, monsoon: monsoon);
  int get dtrIdx => pins.indexWhere((p) => p.kind == M8SopKind.dtr);
  int get stormIdx => pins.indexWhere((p) => p.kind == M8SopKind.storm);
}

/// A deterministic walk of the map: used by the deal (a deal must clear with
/// about an hour of slack when worked in limit order, and first-come-first-
/// served must miss one) and by the tests.
abstract final class M8SopSim {
  static double travel(Offset a, Offset b) => m8SopDistance(a, b) * kM8SopMinPerUnit;

  /// Walks [order] (pin indices) from the van's start, working each pin and
  /// closing its docket at once. [slack] = the least (limit − close time) over
  /// the pins the game fails on; [misses] = how many ran past their limit.
  static ({double slack, double end, int misses}) walk(M8SopDeal d, List<int> order) {
    var t = 0.0;
    var pos = d.vanStart;
    var slack = double.infinity;
    var misses = 0;
    for (final i in order) {
      final p = d.pins[i];
      final depart = math.max(t, math.max(0.0, p.regAt));
      t = depart + travel(pos, p.unit) + (p.kind == M8SopKind.dtr ? kM8SopCallMin : m8SopWorkMin(p.kind));
      pos = p.unit;
      if (p.failable) {
        final s = p.regAt + d.limitOf(i)! - t;
        slack = math.min(slack, s);
        if (s < 0) misses++;
      }
    }
    return (slack: slack, end: t, misses: misses);
  }

  static List<int> requiredIdx(M8SopDeal d) => [for (var i = 0; i < d.pins.length; i++) if (d.pins[i].required) i];

  /// The best slack over every order of the required pins that ends by 16:30.
  static double bestSlack(M8SopDeal d) {
    var best = -double.infinity;
    void rec(List<int> left, List<int> order) {
      if (left.isEmpty) {
        final w = walk(d, order);
        if (w.end <= 510 && w.slack > best) best = w.slack;
        return;
      }
      for (var k = 0; k < left.length; k++) {
        rec([...left]..removeAt(k), [...order, left[k]]);
      }
    }

    rec(requiredIdx(d), const []);
    return best;
  }

  /// First-come-first-served: every pin (decoys too) in registration order.
  static int fcfsMisses(M8SopDeal d) {
    final order = [for (var i = 0; i < d.pins.length; i++) i]..sort((a, b) {
        final c = d.pins[a].regAt.compareTo(d.pins[b].regAt);
        return c != 0 ? c : a.compareTo(b);
      });
    return walk(d, order).misses;
  }

  static bool accepts(M8SopDeal d) => bestSlack(d) >= 60 && fcfsMisses(d) >= 1;
}

Offset _m8Place(math.Random rng, M8SopZone zone, List<Offset> taken) {
  for (var k = 0; k < 80; k++) {
    final u = zone == M8SopZone.town ? 18 + rng.nextDouble() * 178 : 238 + rng.nextDouble() * 66;
    final v = 40 + rng.nextDouble() * 290;
    final p = Offset(u, v);
    if (taken.every((q) => m8SopDistance(p, q) >= 50) && m8SopDistance(p, kM8SopOffice) >= 60) return p;
  }
  return Offset(zone == M8SopZone.town ? 40.0 + taken.length * 30 : 270, 60.0 + taken.length * 60);
}

M8SopDeal _m8SopDraft(math.Random rng) {
  final month = 1 + rng.nextInt(12);
  final monsoon = m8SopMonsoon(month);
  final day = 2 + rng.nextInt(24);
  final event = rng.nextBool() ? M8SopEvent.store : M8SopEvent.storm;
  M8SopZone anyZone() => rng.nextBool() ? M8SopZone.town : M8SopZone.rural;
  final nearWire = rng.nextInt(10) < 3;
  final near = (nearWire ? M8SopKind.wireBreak : M8SopKind.ruralFuse, M8SopZone.rural);
  final others = <(M8SopKind, M8SopZone)>[
    (M8SopKind.urbanFuse, M8SopZone.town),
    (rng.nextBool() ? M8SopKind.meter : M8SopKind.loose, anyZone()),
    event == M8SopEvent.store ? (M8SopKind.dtr, anyZone()) : (M8SopKind.storm, anyZone()),
  ];
  final fillers = <(M8SopKind, M8SopZone)>[
    (M8SopKind.wireBreak, M8SopZone.town),
    (M8SopKind.urbanFuse, M8SopZone.town),
    if (event == M8SopEvent.storm) (M8SopKind.dtr, anyZone()),
  ];
  others.add(fillers[rng.nextInt(fillers.length)]);
  others.shuffle(rng);
  // The near item and one more are on the map from the start; the other three
  // drop at about 25, 55 and 85 game minutes.
  final order = [near, ...others];
  final regs = <double>[];
  final nearLimit = m8SopLimit(near.$1, near.$2, monsoon: monsoon)!;
  final remaining = nearWire ? (monsoon ? 380 + rng.nextInt(40) : 230 + rng.nextInt(32)) : (monsoon ? 175 + rng.nextInt(25) : 150 + rng.nextInt(10));
  regs.add(-(nearLimit - remaining));
  // The second start pin: never a fresh urban fuse with an old registration.
  regs.add(order[1].$1 == M8SopKind.urbanFuse ? 0 : -(5 + rng.nextInt(20)).toDouble());
  final drops = [25 + rng.nextInt(17) - 8, 55 + rng.nextInt(17) - 8, 85 + rng.nextInt(17) - 8];
  regs.addAll(drops.map((e) => e.toDouble()));
  final taken = <Offset>[];
  final nos = <int>{};
  final pins = <M8SopPinDeal>[];
  for (var i = 0; i < order.length; i++) {
    final pos = _m8Place(rng, order[i].$2, taken);
    taken.add(pos);
    var no = 10000 + rng.nextInt(89999);
    while (!nos.add(no)) {
      no++;
    }
    pins.add(M8SopPinDeal(kind: order[i].$1, zone: order[i].$2, unit: pos, regAt: regs[i], docketNo: no));
  }
  return M8SopDeal(
    pins: pins,
    nearIdx: 0,
    event: event,
    push: rng.nextBool() ? M8SopPush.rural : M8SopPush.docket,
    month: month,
    day: day,
    vanStart: Offset(95.0 + rng.nextInt(80), 344.0 + rng.nextInt(26)),
    contactOrder: M8SopContact.values.toList()..shuffle(rng),
  );
}

/// A fresh deal: 5 pins from 7 types — always one urban fuse-off, always the
/// rural item registered earlier today with most of its limit spent, always a
/// long-limit decoy (meter or loose contact), one delay event (store delay with
/// a DTR, or a storm). A deal is kept only if the solver clears it with about an
/// hour of slack in limit order and first-come-first-served misses a limit.
M8SopDeal m8SopDeal(math.Random rng) {
  for (var k = 0; k < 600; k++) {
    final d = _m8SopDraft(rng);
    if (M8SopSim.accepts(d)) return d;
  }
  return _m8SopDraft(math.Random(1));
}

/// One pin on the map: where it stands in the play.
class M8SopPin {
  M8SopPin(this.deal, this.index);
  final M8SopPinDeal deal;
  final int index;

  /// The van has been here.
  var visited = false;

  /// The repair is done (the docket is still open).
  var worked = false;
  var closed = false;
  double? closedAt;

  /// A DTR whose JE / station manager has been told.
  var informed = false;

  /// Its limit passed before the docket closed (the slip is counted).
  var late = false;

  /// Photos taken of the damage (the storm).
  final Set<M8SopDamage> shots = {};
}

/// A docket closed.
@immutable
class M8SopClose {
  const M8SopClose({required this.inLimit, required this.order});

  /// Closed within its limit (counted from registration).
  final bool inLimit;

  /// 1 for the first docket closed in its limit, 2 for the second, else 0.
  final int order;
}

/// The play state (pure logic).
class M8SopRun {
  M8SopRun(this.deal)
      : pins = [for (var i = 0; i < deal.pins.length; i++) M8SopPin(deal.pins[i], i)],
        van = deal.vanStart {
    for (var i = 0; i < pins.length; i++) {
      if (visible(i)) _announced.add(i);
    }
  }

  final M8SopDeal deal;
  final List<M8SopPin> pins;

  /// Game minutes since 08:00.
  double now = 0;
  Offset van;

  /// The pin the van stands at with its close-up open.
  int? at;
  int slips = 0;
  final List<String> caught = [];

  /// Limit slips found, waiting to be shown one by one.
  final List<DoMistake> lateQueue = [];
  final Set<int> _announced = {};
  int _inLimit = 0;
  var storeDone = false;
  var shiftEnded = false;

  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => shiftEnded && percent >= 55;
  bool get timeUp => now >= kM8SopShiftEnd;
  bool get monsoon => deal.monsoon;

  bool visible(int i) => deal.pins[i].regAt <= now + 1e-9;

  /// Pins that have dropped since the last call.
  List<int> takeDrops() {
    final r = [for (var i = 0; i < pins.length; i++) if (visible(i) && !_announced.contains(i)) i];
    _announced.addAll(r);
    return r;
  }

  /// A required pin whose job is over.
  bool done(M8SopPin p) {
    if (!p.deal.required) return true;
    if (p.deal.kind == M8SopKind.dtr) return p.informed && (deal.event != M8SopEvent.store || storeDone);
    return p.closed;
  }

  bool get requiredDone => pins.every(done);
  bool get shiftOver => requiredDone || timeUp;

  double travelMinutes(int i) => M8SopSim.travel(van, deal.pins[i].unit);

  /// The van reaches pin [i]: the clock moves by the drive, its close-up opens.
  bool arrive(int i) {
    final p = pins[i];
    if (shiftEnded || !visible(i) || p.closed) return false;
    final m = travelMinutes(i);
    van = p.deal.unit;
    at = i;
    p.visited = true;
    advance(m);
    return true;
  }

  void leave() => at = null;

  /// The clock moves on; any limit it crosses is found.
  void advance(double minutes) {
    now += minutes;
    for (final p in pins) {
      if (!p.deal.failable || p.closed || p.late) continue;
      if (now > p.deal.regAt + deal.limitOf(p.index)!) _flagLate(p);
    }
  }

  void _flagLate(M8SopPin p) {
    p.late = true;
    slips++;
    lateQueue.add(M8SopClockMistakes.late(p.deal.kind, workDone: p.worked));
  }

  /// Whether the close-up's work button does anything now.
  bool get canWork {
    final i = at;
    if (i == null || shiftEnded) return false;
    final p = pins[i];
    return p.deal.kind != M8SopKind.dtr && !p.worked && !p.closed;
  }

  /// The hold completed: the repair is done, the clock ran fast.
  bool workDone() {
    if (!canWork) return false;
    final p = pins[at!];
    advance(m8SopWorkMin(p.deal.kind));
    p.worked = true;
    return true;
  }

  /// A photo in a close-up of the storm: [hit] is the damage under the tap
  /// (null = elsewhere). Photos after the repair show nothing broken.
  void photo(M8SopDamage? hit) {
    final i = at;
    if (i == null) return;
    final p = pins[i];
    if (p.deal.kind != M8SopKind.storm || p.worked || hit == null) return;
    p.shots.add(hit);
  }

  /// The JE asks for the storm's photos once the repair is done.
  DoMistake? stormAsk() {
    final i = at;
    if (i == null) return null;
    final p = pins[i];
    if (p.deal.kind != M8SopKind.storm) return null;
    if (p.shots.length >= M8SopDamage.values.length) {
      _tag(M8SopClockLines.caughtPhotos);
      return null;
    }
    slips++;
    return M8SopClockMistakes.stormNoPhoto;
  }

  /// A call from the burnt DTR's contacts: JE or the station manager at once is
  /// right; the call centre, home or 'পরে করব' (null) is a slip.
  DoMistake? call(M8SopContact? c) {
    final i = at;
    if (i == null || pins[i].deal.kind != M8SopKind.dtr || pins[i].informed || shiftEnded) return null;
    if (c != M8SopContact.je && c != M8SopContact.manager) {
      slips++;
      return M8SopClockMistakes.dtrNoInform;
    }
    final p = pins[i];
    p.informed = true;
    advance(kM8SopCallMin);
    _tag(M8SopClockLines.caughtInformed(M8SopClockLines.contactName(c!)));
    return null;
  }

  /// The store delay's decision.
  DoMistake? storeAnswer({required bool right}) {
    if (storeDone) return null;
    if (!right) {
      slips++;
      return M8SopClockMistakes.storeSilent;
    }
    storeDone = true;
    _tag(M8SopClockLines.caughtStore);
    return null;
  }

  /// The phone: swipe a finished docket closed. Null = it bounces (unfinished,
  /// or a DTR whose own work is beyond this shift).
  M8SopClose? closeDocket(int i) {
    final p = pins[i];
    if (shiftEnded || p.closed || !p.worked) return null;
    p.closed = true;
    p.closedAt = now;
    final inLimit = !p.late && (!p.deal.failable || now <= p.deal.regAt + deal.limitOf(i)!);
    var order = 0;
    if (inLimit) {
      _inLimit++;
      order = _inLimit <= 2 ? _inLimit : 0;
    }
    _tag(M8SopClockLines.caughtDocket(p.deal.docketNo, M8SopClockLines.limitLabel(p.deal.kind, p.deal.zone, monsoon: monsoon), p.deal.regAt, now));
    return M8SopClose(inLimit: inLimit, order: order);
  }

  /// Dockets that can be swiped now: every pin on the map not yet closed.
  List<int> get openDockets => [for (var i = 0; i < pins.length; i++) if (visible(i) && !pins[i].closed) i];

  /// A repaired pin whose docket is still open.
  bool get workedOpen => pins.any((p) => p.worked && !p.closed);

  /// The map has nothing left to do and a call is still to come: the clock
  /// skips to it (a call-centre ring). True when it moved.
  bool idleSkip() {
    if (shiftEnded || shiftOver) return false;
    final live = [for (var i = 0; i < pins.length; i++) if (visible(i) && !done(pins[i])) i];
    if (live.isNotEmpty) return false;
    double? next;
    for (var i = 0; i < pins.length; i++) {
      if (!visible(i) && (next == null || deal.pins[i].regAt < next)) next = deal.pins[i].regAt;
    }
    if (next == null) return false;
    advance(math.max(0.0, next - now));
    return true;
  }

  /// 17:00 (or everything done): whatever required is still open is a slip.
  void finishShift() {
    if (shiftEnded) return;
    for (final p in pins) {
      if (done(p)) continue;
      if (p.deal.failable && !p.late) {
        _flagLate(p);
      } else if (p.deal.kind == M8SopKind.dtr && !p.informed) {
        slips++;
        lateQueue.add(M8SopClockMistakes.dtrNoInform);
      }
    }
    shiftEnded = true;
    for (final p in pins) {
      if (!p.deal.required && !p.closed && p.visited) {
        _tag(M8SopClockLines.caughtOpen(M8SopClockLines.limitLabel(p.deal.kind, p.deal.zone, monsoon: monsoon)));
      }
    }
  }

  /// Listened to the coworker (a slip).
  DoMistake pushSlip(DoMistake m) {
    slips++;
    return m;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  /// Remaining game minutes of a pin's limit (null: it has none the game fails on).
  double? remaining(int i) {
    final p = deal.pins[i];
    if (!p.failable) return null;
    return p.regAt + deal.limitOf(i)! - now;
  }

  /// The rural myth is due: yesterday's rural item still waits unvisited with
  /// under about half of its limit left.
  bool get ruralMythDue {
    final p = pins[deal.nearIdx];
    if (p.visited || p.closed) return false;
    final r = remaining(deal.nearIdx);
    return r != null && r < 0.45 * deal.limitOf(deal.nearIdx)! + 1;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   five pins: a van drag ≈ 2500, the drive 900, the hold 1400 + the houses
///     800, the phone + swipe ≈ 3500                                 ≈ 9100 each
///   → 45500; the DTR call (hold 1100 + two taps) instead of work    ≈ 3000
///   the five reasons (~8200 each)                                   ≈ 41000
///   the store deck ≈ 4000, the storm's two photos ≈ 4000, the coworker ≈ 9600
///   a clean play ≈ 105000–120000; 85 % ≈ 95000 → 95 s (a builder's estimate;
///   owner may tune).
const m8SopClockQuickMs = 95000;

@immutable
class M8SopClockPack {
  const M8SopClockPack({required this.id, required this.titleBn, this.quickMs = m8SopClockQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8SopClockPack> m8SopClockPacks = {
  'do_8_3_a': M8SopClockPack(id: 'do_8_3_a', titleBn: M8SopClockLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8SopClockProbe {
  static M8SopRun? run;
  static bool closeup = false;
  static bool sheet = false;
  static bool camera = false;
  static M8SopPush? push;
}

// ============================================================================
// Page
// ============================================================================

class M8SopClockPage extends StatefulWidget {
  const M8SopClockPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8SopClockPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8SopClockPage> createState() => _M8SopClockPageState();
}

class _M8SopClockPageState extends State<M8SopClockPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SopRunPage(
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

class _SopRunPage extends ConsumerStatefulWidget {
  const _SopRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8SopClockPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SopRunPage> createState() => _SopRunPageState();
}

class _SopRunPageState extends ConsumerState<_SopRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8SopRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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

  /// The coworker's push now (the rural myth falls back to the docket push).
  late M8SopPush _cw = _run.deal.push;
  var _mythMoot = false;

  /// What the view shows: the map, or a pin's close-up (its push-in).
  var _closeup = false;
  var _sheet = false;
  var _camera = false;
  int _shots = 0;
  int? _docketCard;

  /// The drive (van, clock) and the pins' drop-in.
  late final AnimationController _drive = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve)..addStatusListener(_driveStatus);
  late final AnimationController _dropT = AnimationController(vsync: this, duration: const Duration(milliseconds: 650), animationBehavior: AnimationBehavior.preserve);
  late final AnimationController _work = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400), animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener(_workStatus);
  late final AnimationController _callHold = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100), animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener(_callStatus);
  late final AnimationController _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), animationBehavior: AnimationBehavior.preserve);
  late final Listenable _clockAnim = Listenable.merge([_drive, _work]);
  var _driving = false;
  int _driveTo = 0;
  double _driveMins = 0;
  var _holdingWork = false;
  int _callSlot = -1;
  Set<int> _popping = {};
  Offset? _ghost;
  var _dragVan = false;

  /// A decision deck (the store delay).
  List<ChoiceOption> _deck = const [];
  final Set<String> _deckWrong = {};
  String? _deckPicked;
  int _deckN = 0;

  /// What runs after the open card / reason (the close-up's next beat).
  VoidCallback? _afterCard;
  VoidCallback? _afterReason;

  final _nudge = TaskNudge();
  int _nudgeN = 0;
  int _hintN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _listKey = GlobalKey();
  M8SopGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8SopRun(m8SopDeal(widget.rng));
    M8SopClockProbe.run = _run;
    M8SopClockProbe.closeup = false;
    M8SopClockProbe.sheet = false;
    M8SopClockProbe.camera = false;
    M8SopClockProbe.push = _cw;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _drive.dispose();
    _dropT.dispose();
    _work.dispose();
    _callHold.dispose();
    _flash.dispose();
    _chain++;
    if (identical(M8SopClockProbe.run, _run)) M8SopClockProbe.run = null;
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

  M8SopPin? get _here => _run.at == null ? null : _run.pins[_run.at!];
  bool get _atDtr => _closeup && _here?.deal.kind == M8SopKind.dtr;
  bool get _atStorm => _closeup && _here?.deal.kind == M8SopKind.storm;

  bool get _storeDeckUp => _deck.isNotEmpty && _run.deal.event == M8SopEvent.store && !_run.storeDone && _card == null && !reasonOpen && !coworkerOpen;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_driving && !_storeDeckUp;

  /// The shell is still: something may settle (a slip, the shift's end, a skip).
  bool get _atRest => _canPlay && !_holdingWork && _callSlot < 0;

  String get _task {
    if (_storeDeckUp) return M8SopClockLines.askStore;
    if (_atDtr) return M8SopClockLines.askDtr;
    if (_closeup) return M8SopClockLines.askWork;
    if (_sheet) return M8SopClockLines.askSheet;
    return _nudgeN.isEven ? M8SopClockLines.askMap : M8SopClockLines.askMapOther;
  }

  Future<void> _start() async {
    _clock.start();
    // The coworker's first chance: the rural myth waits for the van drag.
    if (_cw == M8SopPush.rural) scheduleCoworker();
    unawaited(_sayChain([M8SopClockLines.askMap]));
  }

  // --- the clock -------------------------------------------------------------
  /// The game minute on the chip now (the drive and the work run it fast).
  double get _shownNow {
    var t = _run.now;
    if (_driving) t += _driveMins * _drive.value;
    if (_holdingWork && _run.at != null) t += m8SopWorkMin(_run.pins[_run.at!].deal.kind) * _work.value;
    return t;
  }

  // --- drops, slips, the shift ---------------------------------------------
  void _announceDrops() {
    final fresh = _run.takeDrops();
    if (fresh.isEmpty) return;
    _popping = fresh.toSet();
    _cue('sounds/learn/ring_steel.ogg', volume: 0.5);
    if (_quiet) {
      _dropT.value = 1;
    } else {
      _dropT.forward(from: 0);
    }
    setState(() => _wake++);
    unawaited(_sayChain([M8SopClockLines.dropRing]));
  }

  /// Called whenever the play is at rest: a limit slip first, then the shift's
  /// end, then a skip to the next call.
  void _settle() {
    if (!mounted || _ended || !_atRest) return;
    if (_run.lateQueue.isNotEmpty) {
      final m = _run.lateQueue.removeAt(0);
      unawaited(_slip(m));
      return;
    }
    if (_run.shiftOver && !_run.shiftEnded) {
      _run.finishShift();
      _settle();
      return;
    }
    if (_run.shiftEnded) {
      unawaited(_finish());
      return;
    }
    if (!_closeup && _run.idleSkip()) {
      setState(() => _wake++);
      _announceDrops();
      _settle();
    }
  }

  // --- the van ----------------------------------------------------------------
  void _startDrive(int i) {
    final mins = _run.at == i || (_run.van == _run.deal.pins[i].unit) ? 0.0 : _run.travelMinutes(i);
    _hush();
    _tick('sounds/learn/rush_out.ogg', 0.4);
    setState(() {
      _driving = true;
      _driveTo = i;
      _driveMins = mins;
      _docketCard = null;
      _wake++;
    });
    _steps++;
    if (_quiet || mins == 0) {
      _drive.value = 1;
      _driveStatus(AnimationStatus.completed);
    } else {
      _drive.duration = const Duration(milliseconds: 900);
      _drive.forward(from: 0);
    }
  }

  void _driveStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !_driving || !mounted) return;
    final i = _driveTo;
    setState(() {
      _driving = false;
      _drive.value = 0;
    });
    if (_run.pins[i].closed || !_run.arrive(i)) {
      setState(() => _wake++);
      return;
    }
    setState(() {
      _closeup = true;
      _camera = false;
      M8SopClockProbe.closeup = true;
      _wake++;
    });
    _announceDrops();
    unawaited(_sayChain([_task]));
    _steps++;
    _settle();
  }

  void _panStart(Offset p, M8SopGeo geo) {
    _dragVan = false;
    if (!_canPlay || _closeup || _sheet) return;
    if (geo.vanHit(_run.van).contains(p)) {
      _dragVan = true;
      setState(() => _ghost = p);
    }
  }

  void _panUpdate(Offset p) {
    if (_dragVan) setState(() => _ghost = p);
  }

  void _panEnd(M8SopGeo geo) {
    if (!_dragVan) return;
    final at = _ghost;
    _dragVan = false;
    setState(() => _ghost = null);
    if (at == null || !_canPlay) return;
    int? best;
    var bestD = double.infinity;
    for (var i = 0; i < _run.pins.length; i++) {
      if (!_run.visible(i) || _run.pins[i].closed) continue;
      final r = geo.pinHit(_run.deal.pins[i].unit);
      if (!r.contains(at)) continue;
      final d = (r.center - at).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best == null) {
      _hints.missTap();
      return;
    }
    // Yesterday's rural item visited first: the myth has nothing to push.
    if (_cw == M8SopPush.rural && !coworkerDone && best == _run.deal.nearIdx) _mythMoot = true;
    if (holdForCoworker()) return;
    _startDrive(best);
  }

  void _panCancel() {
    if (_dragVan) {
      _dragVan = false;
      setState(() => _ghost = null);
    }
  }

  // --- taps on the scene --------------------------------------------------------
  void _tapScene(Offset p, M8SopGeo geo, Offset global) {
    if (_intro || _ended || _card != null) return;
    if (geo.phoneBtn.contains(p)) {
      if (_canPlay || _sheet) _togglePhone();
      return;
    }
    if (geo.camBtn.contains(p)) {
      if (_canPlay || _camera) _toggleCamera();
      return;
    }
    if (!_canPlay) return;
    if (_camera) {
      _shoot(p, geo);
      return;
    }
    if (_closeup) {
      _hints.missTap();
      return;
    }
    if (_sheet) {
      _hints.missTap();
      return;
    }
    for (var i = 0; i < _run.pins.length; i++) {
      if (!_run.visible(i) || _run.pins[i].closed) continue;
      if (geo.pinHit(_run.deal.pins[i].unit).contains(p)) {
        _tick();
        setState(() => _docketCard = i);
        return;
      }
    }
    if (_docketCard != null) {
      setState(() => _docketCard = null);
      return;
    }
    _hints.missTap();
  }

  void _togglePhone() {
    _tick();
    setState(() {
      _sheet = !_sheet;
      M8SopClockProbe.sheet = _sheet;
      _docketCard = null;
      _wake++;
    });
    _steps++;
    if (_sheet) unawaited(_sayChain([M8SopClockLines.askSheet]));
  }

  void _toggleCamera() {
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _camera = !_camera;
      M8SopClockProbe.camera = _camera;
      _wake++;
    });
    _steps++;
  }

  /// A photo: the shutter always works and always looks the same; only the
  /// damage under it counts (the JE asks for the photos later).
  void _shoot(Offset p, M8SopGeo geo) {
    M8SopDamage? hit;
    if (_atStorm) {
      for (final d in M8SopDamage.values) {
        if (geo.damage(d).contains(p)) hit = d;
      }
    }
    _run.photo(hit);
    _shots++;
    _cue('sounds/intro/click.ogg', volume: 0.6);
    HapticFeedback.mediumImpact();
    if (!_quiet) _flash.forward(from: 0);
    setState(() => _wake++);
    _steps++;
  }

  // --- the work -------------------------------------------------------------------
  void _workDown() {
    if (!_canPlay || !_run.canWork || _holdingWork) return;
    _hush();
    setState(() {
      _holdingWork = true;
      _camera = false;
      _docketCard = null;
    });
    _cue('sounds/learn/knock_solid.ogg', volume: 0.35);
    if (_quiet) {
      _work.value = 1;
      _workStatus(AnimationStatus.completed);
    } else {
      _work.forward(from: 0);
    }
  }

  void _workUp() {
    if (!_holdingWork || _work.isCompleted) return;
    _work.reset();
    setState(() => _holdingWork = false);
  }

  void _workStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !_holdingWork || !mounted) return;
    final storm = _atStorm;
    setState(() => _holdingWork = false);
    if (!_run.workDone()) return;
    _work.value = 0;
    _steps++;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() => _wake++);
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 900), () {
      if (!mounted || _ended) return;
      if (storm) {
        unawaited(_stormAsk());
      } else {
        _leaveCloseup();
      }
    }));
  }

  Future<void> _stormAsk() async {
    if (!mounted || _ended) return;
    final m = _run.stormAsk();
    unawaited(_sayChain([M8SopClockLines.jeStormAsk]));
    if (m == null) {
      _afterReason = _leaveCloseup;
      putOnTable(15);
      unawaited(_askWhy(M8SopWhy.storm));
      return;
    }
    _afterCard = _leaveCloseup;
    await _slip(m);
  }

  void _leaveCloseup() {
    if (!mounted || _ended) return;
    final worked = _run.workedOpen;
    setState(() {
      _closeup = false;
      _camera = false;
      _deck = const [];
      M8SopClockProbe.closeup = false;
      M8SopClockProbe.camera = false;
      _run.leave();
      _wake++;
    });
    _steps++;
    // After a repair he comes with the docket push (if that is his push now).
    if (worked && _cw == M8SopPush.docket && !coworkerDone && !coworkerDue) scheduleCoworker();
    unawaited(_sayChain([_task]));
    _settle();
  }

  // --- the DTR's contacts ----------------------------------------------------------
  void _callDown(int slot) {
    if (!_canPlay || !_atDtr || _here!.informed || _callSlot >= 0) return;
    _hush();
    setState(() {
      _callSlot = slot;
      _docketCard = null;
    });
    if (_quiet) {
      _callHold.value = 1;
      _callStatus(AnimationStatus.completed);
    } else {
      _callHold.forward(from: 0);
    }
  }

  void _callUp() {
    if (_callSlot < 0 || _callHold.isCompleted) return;
    _callHold.reset();
    setState(() => _callSlot = -1);
  }

  void _callStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || _callSlot < 0 || !mounted) return;
    final slot = _callSlot;
    _callHold.value = 0;
    setState(() => _callSlot = -1);
    if (!_atDtr) return;
    final c = slot >= 4 ? null : _run.deal.contactOrder[slot];
    _steps++;
    final m = _run.call(c);
    if (m != null) {
      unawaited(_mistake(m, _centre));
      return;
    }
    _tick('sounds/intro/confirm.ogg', 0.6);
    HapticFeedback.mediumImpact();
    setState(() => _wake++);
    _afterReason = () {
      if (_run.deal.event == M8SopEvent.store && !_run.storeDone) {
        _openStore();
      } else {
        _leaveCloseup();
      }
    };
    putOnTable(20);
    unawaited(_askWhy(M8SopWhy.dtr));
  }

  Offset get _centre {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  // --- the store delay's deck -------------------------------------------------------
  void _openStore() {
    setState(() {
      _deckN++;
      _deckWrong.clear();
      _deckPicked = null;
      _deck = dealChoices(M8SopClockLines.storeRight, M8SopClockLines.storeWrong, widget.rng);
      _wake++;
    });
    unawaited(_sayChain([M8SopClockLines.jeStore, M8SopClockLines.askStore]));
  }

  void _pickStore(ChoiceOption o, Offset at) {
    if (!_storeDeckUp || _intro || _ended) return;
    final m = _run.storeAnswer(right: o.correct);
    if (m != null) {
      setState(() {
        _deckWrong.add(o.textBn);
        _wake++;
      });
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    setState(() {
      _deckPicked = o.textBn;
      _steps++;
    });
    _afterReason = _leaveCloseup;
    putOnTable(15);
    unawaited(_askWhy(M8SopWhy.store));
    unawaited(Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _deck = const []);
    }));
  }

  // --- the phone: closing a docket ------------------------------------------------
  /// A swipe on a docket row. False = it bounces back.
  bool _closeRow(int i) {
    if (!_canPlay || _ended) return false;
    if (holdForCoworker()) return false;
    final r = _run.closeDocket(i);
    if (r == null) {
      _tick();
      unawaited(_sayChain([M8SopClockLines.docketBounce]));
      return false;
    }
    _steps++;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/confirm.ogg', volume: 0.7);
    setState(() => _wake++);
    // The phone goes back in the pocket; the map is free for the van again.
    setState(() {
      _sheet = false;
      M8SopClockProbe.sheet = false;
    });
    if (r.order == 1 || r.order == 2) {
      final why = r.order == 1 ? M8SopWhy.first : M8SopWhy.docket;
      putOnTable(r.order == 1 ? 20 : 15);
      unawaited(_askWhy(why));
    } else {
      if (r.inLimit) unawaited(_levelDelta(5, _centre, mood: GuideMood.glad));
      unawaited(Future<void>.delayed(const Duration(milliseconds: 400), _settle));
    }
    return true;
  }

  Future<void> _askWhy(M8SopWhy w) async {
    await askReason(
      deal: () => dealChoices(M8SopClockLines.whyRight[w]!, M8SopClockLines.myths, widget.rng),
      question: M8SopClockLines.whyQ[w]!,
      stillValid: () => !_ended,
    );
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
    final next = _afterReason;
    _afterReason = null;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (!mounted || _ended) return;
      if (next != null) {
        next();
      } else {
        _settle();
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8SopClockLines.coworker(_cw);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    if (_cw == M8SopPush.rural) {
      // Yesterday's rural item was visited before he came, or is closed: the
      // myth has gone — he falls back to the docket push on the next repair.
      if (_mythMoot || !_run.ruralMythDue) {
        _cw = M8SopPush.docket;
        M8SopClockProbe.push = _cw;
        return null;
      }
      return false;
    }
    if (!_run.workedOpen) return null;
    if (_intro || _card != null || _closeup || _driving || _sheet || _docketCard != null || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _cw;
    if (!held) {
      final m = M8SopClockMistakes.push(p);
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8SopClockLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8SopClockLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line;
    if (coworkerOpen) {
      line = nextCoworkerAsk();
    } else if (reasonOpen) {
      line = M8SopClockLines.tapWhy[_nudgeN++ % M8SopClockLines.tapWhy.length];
    } else {
      line = _nudge.next(_task);
      _nudgeN++;
    }
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
    final speak = await SpokenOnce.first('m8sop/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    final next = _afterCard;
    _afterCard = null;
    setState(() {
      _card = null;
      _wake++;
    });
    if (next != null) {
      next();
    } else {
      unawaited(_sayChain([_task]));
      _settle();
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
    _hush();
    _clock.stop();
    final save = ref.read(gameSaveProvider.notifier);
    final centre = _centre;
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
    await _say(!_run.passed ? M8SopClockLines.fail : (_quickBonus ? M8SopClockLines.quick : M8SopClockLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_holdingWork) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M8SopScene get _sceneNow => M8SopScene(kind: _here?.deal.kind ?? M8SopKind.urbanFuse, zone: _here?.deal.zone ?? M8SopZone.town, worked: _here?.worked ?? false, informed: _here?.informed ?? false);

  /// The gesture hand: how to touch, never what (see the header comment).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    if (_sheet) {
      final r = HintSpec.globalRectOf(_listKey);
      if (r == null) return null;
      return HintSpec.swipe(Offset(r.left + 40, r.top + 18), toward: const Offset(1, 0), travel: 110);
    }
    if (_closeup) {
      final here = _here!;
      if (here.deal.kind == M8SopKind.dtr) {
        if (here.informed) return null;
        return HintSpec.sweep([for (var i = 0; i < 5; i++) geo.contact(i)], space: HintSpace.scene);
      }
      if (_camera && _atStorm && !here.worked) return HintSpec.sweep(geo.tiles, space: HintSpace.scene);
      if (here.worked) return null;
      if (_atStorm && n.isEven) return HintSpec.sweep([geo.phoneBtn, geo.camBtn], space: HintSpace.scene);
      return HintSpec.hold(geo.workBtn.center, space: HintSpace.scene);
    }
    final open = [for (var i = 0; i < _run.pins.length; i++) if (_run.visible(i) && !_run.pins[i].closed) i];
    if (_run.workedOpen) return HintSpec.sweep([geo.phoneBtn, geo.vanHit(_run.van)], space: HintSpace.scene);
    if (open.length >= 2 && n.isEven) return HintSpec.sweep([for (final i in open) geo.pinHit(_run.deal.pins[i].unit)], space: HintSpace.scene);
    return HintSpec.drag(geo.mapAt(_run.van), toward: const Offset(0, -1), travel: 70, space: HintSpace.scene);
  }

  List<Widget> _sceneLayers(SceneMetrics m) {
    final geo = _geoNow = M8SopGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final closeup = _closeup && _run.at != null;
    final here = _here;
    return [
      if (!closeup) ...[
        Positioned.fill(key: const ValueKey('map'), child: RepaintBoundary(child: CustomPaint(painter: M8SopMapPainter(geo: geo)))),
        Positioned.fill(
          key: const ValueKey('pins'),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M8SopPinsPainter(
                geo: geo,
                pins: [
                  for (var i = 0; i < _run.pins.length; i++)
                    if (_run.visible(i) && !_run.pins[i].closed) M8SopPinView(unit: _run.deal.pins[i].unit, pop: _popping.contains(i) ? 0 : 1),
                ],
                van: _run.van,
                vanTo: _driving ? _run.deal.pins[_driveTo].unit : null,
                driveT: _driving ? _drive : null,
                ghost: _ghost,
                vanHidden: _ghost != null,
                dropT: _dropT,
                repaint: Listenable.merge([_drive, _dropT]),
              ),
            ),
          ),
        ),
      ] else ...[
        Positioned.fill(
          key: ValueKey('closeup-${_run.at}'),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1.0 : 1.12, end: 1.0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: RepaintBoundary(child: CustomPaint(painter: M8SopCloseupPainter(geo: geo, scene: _sceneNow))),
          ),
        ),
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: geo.trainee(dtr: here?.deal.kind == M8SopKind.dtr),
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      ],
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: closeup ? M8SopClockLines.closeupLabel : M8SopClockLines.mapLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: _panCancel,
          ),
        ),
      ),
      // The toolbar (phone, camera): always there, the same on every screen.
      Positioned.fromRect(
        key: const ValueKey('tool-phone'),
        rect: geo.phoneBtn,
        child: IgnorePointer(child: _ToolButton(icon: Icons.phone_android_rounded, label: M8SopClockLines.phoneLabel, on: _sheet, badge: _intro ? 0 : _run.openDockets.length)),
      ),
      Positioned.fromRect(
        key: const ValueKey('tool-cam'),
        rect: geo.camBtn,
        child: IgnorePointer(child: _ToolButton(icon: Icons.photo_camera_rounded, label: M8SopClockLines.cameraLabel, on: _camera, badge: _shots)),
      ),
      // Hold to work.
      if (closeup && _run.canWork && !_intro)
        Positioned.fromRect(
          key: const ValueKey('work-pad'),
          rect: geo.workBtn,
          child: _HoldPad(label: M8SopClockLines.work, progress: _work, enabled: _canPlay, onDown: _workDown, onUp: _workUp),
        ),
      // The burnt DTR's contacts: hold one to call.
      if (closeup && here != null && here.deal.kind == M8SopKind.dtr && !here.informed && !_intro)
        for (var i = 0; i < 5; i++)
          Positioned.fromRect(
            key: ValueKey('contact-$i'),
            rect: geo.contact(i),
            child: _HoldPad(
              label: i >= 4 ? M8SopClockLines.later : M8SopClockLines.contactName(_run.deal.contactOrder[i]),
              progress: _callSlot == i ? _callHold : const AlwaysStoppedAnimation<double>(0),
              enabled: _canPlay,
              small: true,
              onDown: () => _callDown(i),
              onUp: _callUp,
            ),
          ),
      if (_camera)
        Positioned.fill(key: const ValueKey('viewfinder'), child: IgnorePointer(child: CustomPaint(painter: M8SopViewfinderPainter(area: geo.closeup())))),
      // The shutter's flash.
      Positioned.fill(
        key: const ValueKey('flash'),
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _flash,
            builder: (_, _) => _flash.value <= 0 || _flash.value >= 1 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(255, 255, 255, 0.8 * (1 - _flash.value))),
          ),
        ),
      ),
      // The next screen: a short fade.
      if (!_intro)
        Positioned.fill(
          key: ValueKey('view-$closeup-${_run.at}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 0.4, end: 0),
              duration: const Duration(milliseconds: 380),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final storeDeck = _storeDeckUp && playing;
    final deckUp = reasonOpen || coworkerChoiceUp || storeDeck;
    final here = _here;
    final hintOk = playing && !deckUp && !coworkerOpen && _card == null && !tableBusy && !_driving && !_holdingWork && _callSlot < 0 && _docketCard == null && !_run.shiftEnded;
    final waiting = hintOk &&
        (_sheet
            ? _run.openDockets.isNotEmpty
            : _closeup
                ? here != null && (here.deal.kind == M8SopKind.dtr ? !here.informed : !here.worked)
                : !_dragVan);
    final guideUp = deckUp ? 236.0 : (_sheet ? 290.0 : (_atDtr && !(here?.informed ?? true) ? 330.0 : 84.0));
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
            progress: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: AnimatedBuilder(animation: _clockAnim, builder: (_, _) => _ClockChip(text: m8SopHhmm(_shownNow))),
            ),
            layers: (context, m) => _sceneLayers(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.at}/$_steps/$_closeup/$_sheet/$_camera',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (_closeup && playing && _card == null && !deckUp && !_holdingWork && _callSlot < 0 && !coworkerOpen)
                Positioned(
                  key: const ValueKey('hud-back'),
                  left: 16,
                  top: pad.top + 104,
                  child: _PillButton(label: M8SopClockLines.backMap, small: true, onTap: (_) => _leaveCloseup()),
                ),
              if (_docketCard != null && playing && _card == null)
                Positioned(
                  key: ValueKey('docket-card-$_docketCard'),
                  left: 16,
                  right: 16,
                  top: pad.top + 104,
                  child: _DocketCard(
                    deal: _run.deal,
                    pin: _docketCard!,
                    onClose: () => setState(() => _docketCard = null),
                  ),
                ),
              if (_sheet && playing && !deckUp)
                Positioned(
                  key: const ValueKey('phone-sheet'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _PhoneSheet(
                    listKey: _listKey,
                    pad: pad.bottom,
                    rows: _run.openDockets,
                    deal: _run.deal,
                    onClose: _togglePhone,
                    onSwipe: _closeRow,
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
                                key: ValueKey('store-deck-$_deckN'),
                                options: _deck,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _deckWrong,
                                picked: _deckPicked,
                                onPick: _pickStore,
                              ),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + guideUp, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}-$strikes'),
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
                  line: M8SopClockLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 0, muted: _muted)),
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

/// The game clock under the header.
class _ClockChip extends StatelessWidget {
  const _ClockChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xCC0B1324),
          border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 16, color: SlmColors.gold300),
            const SizedBox(width: 6),
            Text(text, key: const ValueKey('game-clock'), style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
          ],
        ),
      ),
    );
  }
}

/// A toolbar button drawn on the scene (taps go through the scene's detector).
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.on, required this.badge});
  final IconData icon;
  final String label;
  final bool on;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: on ? const [Color(0xFF3A5A8A), Color(0xFF1B2E4D)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                border: Border.all(color: SlmColors.gold300.withValues(alpha: on ? 1 : 0.8), width: on ? 2.2 : 1.5),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Icon(icon, color: SlmColors.ivory, size: 28),
            ),
          ),
          if (badge > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(10), color: const Color(0xFFD7332A)),
                child: Text(enDigits('$badge'), style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A press-and-hold button: a ring fills while the finger stays down.
class _HoldPad extends StatelessWidget {
  const _HoldPad({required this.label, required this.progress, required this.enabled, required this.onDown, required this.onUp, this.small = false});
  final String label;
  final Animation<double> progress;
  final bool enabled;
  final bool small;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          if (enabled) onDown();
        },
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Center(child: Text(label, textAlign: TextAlign.center, style: bangla(fontSize: small ? 13 : 17, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
            ),
            IgnorePointer(child: CustomPaint(painter: M8SopRingPainter(progress: progress, repaint: progress))),
          ],
        ),
      ),
    );
  }
}

/// A worker's button on the screen ('ম্যাপে ফিরি').
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap, this.small = false});
  final String label;
  final ValueChanged<Offset> onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Container(
          constraints: BoxConstraints(minHeight: small ? 48 : 54, minWidth: small ? 96 : 150),
          padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Text(label, style: bangla(fontSize: small ? 13.5 : 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}

/// A tapped pin's docket: number, type, area, when it was registered. Never a
/// limit, never a time left.
class _DocketCard extends StatelessWidget {
  const _DocketCard({required this.deal, required this.pin, required this.onClose});
  final M8SopDeal deal;
  final int pin;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = deal.pins[pin];
    final line = bangla(fontSize: 14.5, fontWeight: FontWeight.w800, color: SlmColors.ivory);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xF20B1324),
        border: Border.all(color: SlmColors.gold300, width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(M8SopClockLines.docketNo(p.docketNo), key: const ValueKey('docket-no'), style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
                const SizedBox(height: 4),
                Text(M8SopClockLines.kindName(p.kind), style: line),
                Text(M8SopClockLines.docketArea(p.zone), style: line),
                Text(M8SopClockLines.docketAt(deal.day, deal.month, p.regAt), style: line),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'বন্ধ করুন',
            child: GestureDetector(
              key: const ValueKey('docket-close'),
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: const SizedBox(width: 48, height: 48, child: Icon(Icons.close_rounded, color: SlmColors.ivory)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pocket phone: the open dockets, every row alike. Swipe a finished one
/// to close it; an unfinished one bounces.
class _PhoneSheet extends StatelessWidget {
  const _PhoneSheet({required this.listKey, required this.pad, required this.rows, required this.deal, required this.onClose, required this.onSwipe});
  final GlobalKey listKey;
  final double pad;
  final List<int> rows;
  final M8SopDeal deal;
  final VoidCallback onClose;
  final bool Function(int) onSwipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 6, 12, pad + 10),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF16233D), Color(0xFF0B1324)]),
        border: Border(top: BorderSide(color: SlmColors.gold300, width: 2)),
        boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 6),
              Expanded(key: listKey, child: Text(M8SopClockLines.phoneTitle, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.gold300))),
              Semantics(
                button: true,
                label: 'ফোন বন্ধ',
                child: GestureDetector(
                  key: const ValueKey('phone-close'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: const SizedBox(width: 48, height: 40, child: Icon(Icons.close_rounded, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
          for (final i in rows)
            _DocketRow(
              key: ValueKey('docket-row-$i'),
              no: deal.pins[i].docketNo,
              kind: deal.pins[i].kind,
              zone: deal.pins[i].zone,
              at: M8SopClockLines.docketAt(deal.day, deal.month, deal.pins[i].regAt),
              onSwipe: () => onSwipe(i),
            ),
        ],
      ),
    );
  }
}

class _DocketRow extends StatefulWidget {
  const _DocketRow({super.key, required this.no, required this.kind, required this.zone, required this.at, required this.onSwipe});
  final int no;
  final M8SopKind kind;
  final M8SopZone zone;
  final String at;
  final bool Function() onSwipe;

  @override
  State<_DocketRow> createState() => _DocketRowState();
}

class _DocketRowState extends State<_DocketRow> {
  double _dx = 0;
  var _dragging = false;

  @override
  Widget build(BuildContext context) {
    final t = bangla(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1B2433));
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => setState(() => _dx = math.max(0, _dx + d.delta.dx)),
        onHorizontalDragEnd: (_) {
          final far = _dx > 90;
          setState(() => _dragging = false);
          if (far && widget.onSwipe()) {
            setState(() => _dx = 520);
          } else {
            setState(() => _dx = 0);
          }
        },
        onHorizontalDragCancel: () => setState(() {
          _dragging = false;
          _dx = 0;
        }),
        child: AnimatedContainer(
          duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(_dx, 0, 0),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: SlmColors.ivory),
          child: Row(
            children: [
              const Icon(Icons.description_rounded, size: 22, color: Color(0xFF3A5A8A)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(enDigits('${widget.no} · ${M8SopClockLines.kindName(widget.kind)}'), style: t.copyWith(fontWeight: FontWeight.w900)),
                    Text('${M8SopClockLines.zoneName(widget.zone)} · ${widget.at}', style: t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
