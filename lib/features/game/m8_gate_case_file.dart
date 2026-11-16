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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_gate_case_file_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

// Module 8 rank gate (rung m8/gate, pack gate_m8, engineType
// m8_gate_case_file): "আইনের ডকেট: আলো ফেরান, প্রমাণ রাখুন" — one snapped LT
// wire in a town lane (lessons 8.1–8.10; spec docs/module_specs/module8_items/
// gate_m8.json, rulings docs/module_specs/module8_rulings.md — the rulings win;
// the live lesson text wins over the spec's quotes, X3).
//
// ACT 1 (মাঠ): the lane is a ~1230-px strip panned by swipe — the van (phone,
// PTW book, file clip), the DTR (AB switch + HG fuses, never DO fuses, M8-19),
// four poles, six houses (service cables, meter boxes, roofs), a tree by the
// span, a tea stall; the snapped wire hangs clear of the ground and the crew's
// cordon is up (M8-22). Eleven same-size tokens in one fixed order that has no
// relation to any right order (পারমিট · ফিউজ খোলা · আর্থ রড · পোলে ওঠা ·
// ক্যামেরা · তার খোলা · ছাঁটা · জব্দ তালিকা · পুলিশে অভিযোগ · অফিসে রিপোর্ট
// · টেস্টার, M8-17): the player picks the next act from an open set and drops
// a token on a place (van, pole, house, service cable, branch, trunk). A drop
// where the act cannot physically happen slides back with no cost and no
// verdict. Physical acts are judged on the spot; paper acts (পারমিট, ক্যামেরা,
// জব্দ তালিকা, পুলিশে অভিযোগ, অফিসে রিপোর্ট) drop a record into the file and
// are judged at the hearing. The climb (পোলে ওঠা, or তার খোলা on the hook —
// a climb) is judged on the written PTW, the tester's 0 V, the earth rods at
// pole 1 AND pole 4 and every solar house's fuse out: any missing = deadly
// (M8-1/2/7/17). A rod before the permit lands on a live line = deadly (B8,
// M8-7); after the permit but before 0 V = slip (N2). Trimming the branch that
// rests on the span before the permit = deadly (M8-3). The coworker comes once
// (two-beat), held by the next decisive control: M1 on any token touch once the
// phone has said "লাইন OFF — উঠে পড়" and the PTW is not in the file (listening
// = the climb at once = deadly); M2 at the first touch of অফিসে রিপোর্ট or
// বাড়ি চলুন (listening = slip, the docket stays open). After the repair the
// crew comes down, the earths come off and the line is restored by itself.
//
// ACT 2 (শুনানি): the CGRF bench asks 1–4 questions from the deal and the
// player's own acts; for each the player drops one record of his file on the
// bench table. Silent drawn figures with caption bubbles (M8-10).
//
// Scoring as the module's levels: ◆ 15 per reason, a right plain act +10, the
// coworker refused +10, slip −10, pass +20, quick bonus +10; mark
// 100 − 15 × slips (pass ≥ 55); 3 slips strike out; a deadly move freezes the
// scene. The quick-bonus time (5 min 30 s) is the builder's estimate, about
// 85 % of a clean play (M8-15). Rank: সুপারভাইজার → স্পেশালিস্ট, unlockRank(8).
//
// Every spoken line is listed in M8GateLines.newGuideLines / newRivalLines
// (DRAFT wording — owner, M6-12).

// ============================================================================
// Content
// ============================================================================

/// The tokens, in their fixed screen order (unrelated to any right order).
enum M8GTok { permit, fuse, rod, climb, camera, hook, trim, seize, police, report, tester }

/// The ◆ questions: the field ones, then one per record kind at the hearing.
enum M8GReason { solar, climb, video, docket, hookVideo, seizure, police, photo }

/// Who he pushes: the phone's "line OFF" (M1) or "go home without the report" (M2).
enum M8GPush { phone, report }

/// The time limit for an LT wire break in a town (lesson 8.3, live text).
const kM8GLimitMin = 240;

abstract final class M8GateLines {
  static const title = 'আইনের ডকেট: আলো ফেরান, প্রমাণ রাখুন';

  /// The module's badge (M8-16: the 8.x lessons' badge_name).
  static const badge = 'জরুরী রেগুলেশন (WBERC ফোকাস)'; // OWNER may rename

  // The ranks (fallbacks when the catalog is not loaded).
  static const rankFrom = 'সুপারভাইজার';
  static const rankTo = 'স্পেশালিস্ট';
  static const rankUp = 'নতুন র‍্যাঙ্ক!';

  /// Spoken on the pass. DRAFT wording — owner.
  static String promoted(String rank) => badge.isEmpty ? 'অভিনন্দন! আপনি এখন $rank লাইনম্যান।' : 'অভিনন্দন! আপনি এখন $rank লাইনম্যান — $badge।';

  // DRAFT wording — owner (M6-12), every spoken line below.
  static const intro = 'লাইন ছিঁড়েছে, ঘড়ি চলছে — আইন মেনে আলো ফেরান!';
  static const hearIntro = 'শুনানির দিন — আপনার ফাইলই আপনার হয়ে কথা বলবে।';

  // The guide's tap pool (never names an act).
  static const taskA = 'এবার কোন কাজ?';
  static const taskB = 'পরের পা কী?';
  static const taskC = 'যা করবেন, তার প্রমাণ থাকবে তো?';
  static const taskD = 'ঘড়ির দিকে নজর।';
  static const taskLifted = 'কোথায় লাগাবেন? জায়গাটা বেছে ছাড়ুন।';
  static const taskRoof = 'ছাদে কী আছে, দেখে নিন।';
  static const taskHear = 'প্রশ্নের জবাবে একটা কাগজ টেবিলে রাখুন।';
  static const tapHearA = 'প্রশ্নটা কী, আবার শুনুন।';
  static const tapHearB = 'ফাইলে কী আছে, দেখুন।';
  static const tapWhyA = 'ঠিক কারণটা কোনটা?';
  static const tapWhyB = 'কেন করলেন, বেছে নিন।';
  static const fieldTasks = [taskA, taskB, taskC, taskD];
  static const hearTasks = [tapHearA, tapHearB];
  static const tapWhy = [tapWhyA, tapWhyB];
  static const tasks = [taskA, taskB, taskC, taskD, taskLifted, taskRoof, taskHear, tapHearA, tapHearB];

  static const lit = 'আলো ফিরল!';
  static const refused = 'ঠিক! চাপে নিয়ম ভাঙা নয়।';
  static const fixRight = 'ঠিক কাজ!';
  static const fail = 'আরেকবার — আগে PTW, টেস্টারে 0 V, দুই প্রান্তে আর্থ, তারপর ওঠা; আর প্রমাণ রাখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // Shown, never spoken: notes, labels, captions.
  static const docketWord = 'ডকেট';
  static String docketLine(int regMin) => 'লাইন ছিঁড়েছে · নথিভুক্ত আজ ${hm(regMin)}';
  static String clockLine(int min) => 'এখন ${hm(min)}';
  static const home = 'বাড়ি চলুন';
  static const phoneMsg = 'ফোন: "লাইন OFF — উঠে পড়"';
  static const consumerSays = 'গ্রাহক: আমার বাড়িতে এখনও কারেন্ট আসেনি!';
  static const nothingThere = 'ওখানে এটা হয় না।';
  static const permitCut = 'ভ্যান গেল… ফিরল।';
  static const permitDone = 'PTW হাতে, ট্রান্সফরমার OFF — AB খোলা, হ্যান্ডেলে তালা-ট্যাগ।';
  static const permitAgain = 'PTW তো আগেই এসেছে।';
  static const testerLive = 'টেস্টার: চালু উৎসে ঠিক → লাইনে ভোল্টেজ আছে!';
  static const testerDead = 'টেস্টার: চালু উৎসে ঠিক → লাইনে 0 V → আবার চালু উৎসে ঠিক';
  static String rodOn(int pole) => enDigits('আর্থ রড লাগানো — পোল ${pole + 1}');
  static String fuseOut(int house) => enDigits('পোল থেকে ফিউজ খোলা — বাড়ি ${house + 1}');
  static const fuseAgain = 'এই ফিউজ আগেই খোলা।';
  static const repairCut = 'ক্রু উঠল, তার জোড়া হলো, নেমে এল…';
  static const repaired = 'আর্থ খুলে নেওয়া হলো, লাইন চালু।';
  static const repairedAgain = 'কাজ আগেই হয়ে গেছে।';
  static const hookOff = 'হুকিং-এর তার খোলা হলো।';
  static const hookAgain = 'ওই তার আগেই খোলা।';
  static const trimmed = 'ডাল ছাঁটা হলো — গুঁড়ি অক্ষত।';
  static const trimAgain = 'ডালটা আগেই ছাঁটা।';
  static const filed = 'ফাইলে রাখা হলো';
  static const reportedNote = 'অফিসে রিপোর্ট গেল — ডকেট স্লিপ ফাইলে।';
  static const alreadyReported = 'রিপোর্ট আগেই হয়েছে।';
  static const policeNote = 'থানায় অভিযোগ গেল — ফাইলে।';
  static const policeAgain = 'অভিযোগ আগেই গেছে।';
  static const roofPanel = 'ছাদে সোলার প্যানেল।';
  static const roofParapet = 'পাঁচিলের ওপারে সোলার প্যানেল।';
  static const roofTarp = 'ছাদে নীল ত্রিপল।';
  static const roofTank = 'ছাদে পানির ট্যাঙ্ক।';
  static const roofNone = 'ছাদে কিছু নেই।';
  static const close = 'বন্ধ';

  // The hearing (silent captions, M8-10).
  static const benchWord = 'বেঞ্চ';
  static const consumerWord = 'গ্রাহক';
  static const nod = 'বেঞ্চ মাথা নাড়ল।';
  static const notThis = 'এটা এর প্রমাণ নয়।';
  static const noProof = 'এর কোনো প্রমাণ নেই — বেঞ্চ গ্রাহকের পক্ষে রায় দিল।';
  static const noRecord = 'ফাইলে নেই';
  static const docketHeld = 'ডকেট খোলা রেখে এসেছেন — আগেই ধরা হয়েছে।';
  static const benchTable = 'বেঞ্চের টেবিল';

  static String hm(int minOfDay) {
    final t = minOfDay % 1440;
    return '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}';
  }

  static String tok(M8GTok t) => switch (t) {
        M8GTok.permit => 'পারমিট',
        M8GTok.fuse => 'ফিউজ খোলা',
        M8GTok.rod => 'আর্থ রড',
        M8GTok.climb => 'পোলে ওঠা',
        M8GTok.camera => 'ক্যামেরা',
        M8GTok.hook => 'তার খোলা',
        M8GTok.trim => 'ছাঁটা',
        M8GTok.seize => 'জব্দ তালিকা',
        M8GTok.police => 'পুলিশে অভিযোগ',
        M8GTok.report => 'অফিসে রিপোর্ট',
        M8GTok.tester => 'টেস্টার',
      };

  static String tgt(M8GTgt t) => switch (t.kind) {
        M8GTgtKind.van => 'ভ্যান',
        M8GTgtKind.dtr => 'ট্রান্সফরমার',
        M8GTgtKind.pole => enDigits('পোল ${t.i + 1}'),
        M8GTgtKind.house => enDigits('বাড়ি ${t.i + 1}'),
        M8GTgtKind.wire => enDigits('সার্ভিস কেবিল ${t.i + 1}'),
        M8GTgtKind.branch => 'গাছের ডাল',
        M8GTgtKind.trunk => 'গাছের গুঁড়ি',
      };

  // --- the hearing's questions (caption bubbles, never the record's name) -------
  static String ask(M8GQKind k) => switch (k) {
        M8GQKind.delay => 'ডকেট নিয়ে প্রশ্ন: তার ছিঁড়ল, কিন্তু সময়মতো রিপোর্ট হয়নি বলে অভিযোগ — কখন রিপোর্ট হলো, কোন কাগজে আছে?',
        M8GQKind.noCause => 'আমার লাইন কেন কাটা হলো? বিনা কারণে কেটে দিয়েছে!',
        M8GQKind.seizure => 'রেইডে কী পাওয়া গেল, তার হিসাব কোথায়?',
        M8GQKind.police => 'থানায় জানানো হয়েছে? কখন, কার মাধ্যমে?',
        M8GQKind.claim => 'লাইনম্যান আমার বাড়ি দেখেননি — আমার সাপ্লাই আসেনি!',
        M8GQKind.needlessSeize => 'হুকিং ছাড়া এই বাড়ির জিনিস জব্দ হলো কেন?',
        M8GQKind.falseClose => 'মেরামত শেষ হওয়ার আগেই ডকেট বন্ধ হলো কেন?',
      };

  static String who(M8GQKind k) => switch (k) {
        M8GQKind.noCause || M8GQKind.claim => consumerWord,
        _ => benchWord,
      };

  // --- the ◆ questions and their cards (each set within 1.3x) -------------------
  static String question(M8GReason r) => switch (r) {
        M8GReason.solar => 'এই বাড়ির ফিউজ কেন খুললেন?',
        M8GReason.climb => 'ওঠার আগে কী কী নিশ্চিত করলেন?',
        M8GReason.video => 'তার খোলার আগে কেন ভিডিও করলেন?',
        _ => 'এই কাগজটাই কেন দেখালেন?',
      };

  static const _hearWrong = [
    'পারমিটের কপিতেই সব প্রমাণ থাকে, তাই এটা দেখালাম',
    'মুখে বললেই বিচারক সব মেনে নেন, তাই এটা দেখালাম',
    'যত বেশি কাগজ দেখাব, তত ভালো — তাই এটা দেখালাম',
    'কোম্পানির নামে কেস টেকে না, তাই যা পেলাম দেখালাম',
    'ছবি তো সব কেসেই একরকম, তাই একটা ছবি দেখালাম',
  ];

  static List<String> whyRight(M8GReason r) => switch (r) {
        M8GReason.solar => const ['গ্রিড বন্ধেও সোলার চললে ব্যাক-ফিডে লাইন সজীব থাকে', 'শুধু ট্রান্সফরমার নয়, সোলার বাড়ির ফিউজও খুলতে হয়'],
        M8GReason.climb => const ['পারমিট, 0 V, দুই প্রান্তে আর্থ, সোলারের ফিউজ — তবেই উঠি', 'ফোনের কথায় নয়: পারমিট, 0 V আর দুই প্রান্তে আর্থ'],
        M8GReason.video => const ['চুরিতে আগে প্রমাণ জোগাড়, তারপর লাইন বিচ্ছিন্ন', 'পোল থেকে হুকিং তার দেখা যায় এমন ভিডিও চাই'],
        M8GReason.docket => const ['রিপোর্ট করলে তবেই ডকেট ক্লোজ — সময়টা ওতেই লেখা', 'ডকেটে রিপোর্টের সময় লেখা থাকে, তাই এটাই প্রমাণ'],
        M8GReason.hookVideo => const ['পোল থেকে হুকিং তার দেখা যায় — এটাই শুনানির প্রমাণ', 'হুক আর পোল এক ফ্রেমে — তার কাটার আগের প্রমাণ'],
        M8GReason.seizure => const ['রেইডে জব্দ তালিকা করতেই হয় — এটাই সঠিক হিসাব', 'জব্দ তালিকাতেই লেখা, রেইডে কী পাওয়া গেল'],
        M8GReason.police => const ['থানায় 24 ঘন্টার মধ্যে অফিসারের মাধ্যমে জানানো হয়েছে', 'থানায় অভিযোগ গেছে অফিসারের মাধ্যমে, সময়সহ লেখা'],
        M8GReason.photo => const ['সমস্যা নেই দেখে ছবি তুলেছি — শুনানিতে এটাই প্রমাণ', 'বাড়িতে সাপ্লাই আছে — পাখা চলার ছবিই আমার প্রমাণ'],
      };

  static List<String> whyWrong(M8GReason r) => switch (r) {
        M8GReason.solar => const [
            'ফিউজ খুললে মিটার বন্ধ থাকে, তাই ফিউজ খুললাম',
            'ফিউজ খুললে বিল কম আসে, সেই ভেবে ফিউজ খুললাম',
            'সব বাড়ির ফিউজ খোলাই নিয়ম, তাই ফিউজ খুললাম আমি',
            'প্যানেল দেখে আন্দাজে মনে হলো, তাই ফিউজ খুলে দিলাম',
            'ইনভার্টার নিজেই বন্ধ হয়, নিয়মের জন্য খুললাম',
            'গ্রাহক বলল, তাই তার কথা রাখতে ফিউজ খুললাম',
          ],
        M8GReason.climb => const [
            'ফোনে লাইন OFF বললেই লাইন ডেড, আর কিছু লাগে না তো',
            'ট্রান্সফরমার OFF হলে আর কিছু লাগে না, তাই উঠলাম',
            'এক দিকে আর্থ দিলেই যথেষ্ট, অন্য দিকে লাগে না তো',
            'দায় তো অফিসারের, আমার নয় — তাই উঠে পড়লাম',
            'ইনভার্টার নিজেই বন্ধ হয়, ফিউজ খোলা লাগে না তো',
            'টেস্টার দেখলে দেরি হয়, তাই না দেখেই উঠে পড়লাম',
          ],
        M8GReason.video => const [
            'ভিডিও করলে গ্রাহক ভয়ে বিল মিটিয়ে দেয় তো',
            'ভিডিও থাকলে তার খুলতে তাড়াতাড়ি লাগে তো',
            'অফিস বলেছে সব তারের আগে ভিডিও তুলতেই হয়',
            'ভিডিও করে রাখলে পরে পুরস্কার পাওয়া যায় তো',
            'হুকটা ছোট ছিল, তাই শখ করে ভিডিও তুললাম',
          ],
        _ => _hearWrong,
      };

  /// "আজ যা ধরলেন" — from the player's own moves (on screen only).
  static String caught(M8GReason r) => switch (r) {
        M8GReason.solar => 'সোলার বাড়ির ফিউজ, ব্যাক-ফিড ঠেকানো',
        M8GReason.climb => 'পারমিট, 0 V, দুই প্রান্তে আর্থ, তবেই ওঠা',
        M8GReason.video => 'আগে ভিডিও প্রমাণ, তারপর হুক খোলা',
        M8GReason.docket => 'রিপোর্টের সময়ে ডকেট ক্লোজ',
        M8GReason.hookVideo => 'পোল থেকে হুকিং-এর ভিডিও',
        M8GReason.seizure => 'রেইডে জব্দ তালিকা',
        M8GReason.police => '24 ঘন্টায় অফিসারের মাধ্যমে থানায়',
        M8GReason.photo => 'মিথ্যা অভিযোগে সাপ্লাইয়ের ছবি',
      };
  static const caughtPush = 'চাপে নিয়ম ভাঙা নয়';
  static const caughtTrim = 'শাটডাউনের পর শুধু বিপদের ডাল ছাঁটা';

  // --- the careless coworker (his recorded voice; DRAFT wording — owner) -------
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _asks = ['ও যা বলছে, করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];

  /// M1: the phone said "line OFF", the PTW is not in the file.
  static const pushPhone = CoworkerScript(
    line: 'আইন-কানুন সব বইয়ের পাতায়, মাঠে জুগাড়েই কাজ চলে — ফোনে লাইন OFF বলেছে, উঠে পড়!',
    exitLine: coworkerExit,
    right: ['না — লিখিত পারমিট না পেলে পোলে উঠব না', 'না — ফোনের কথায় নয়, পারমিট আর আর্থ চাই'],
    wrong: [
      'ঠিক, ফোনে বলেছে, তাহলে এখনই উঠে পড়ি',
      'ঠিক, দায় তো অফিসারের, তাই আমি উঠে পড়ি',
      'ঠিক, পারমিট পরে দেখা যাবে, আগে উঠে পড়ি',
      'মাঠে জুগাড়েই চলে, তাহলে চলো উঠে পড়ি',
      'কাগজ পরে দেখা যাবে, আগে পোলে উঠে পড়ি',
    ],
    asks: _asks,
  );

  /// M2: the report and the way home.
  static const pushReport = CoworkerScript(
    line: 'আইন-কানুন সব বইয়ের পাতায়, মাঠে জুগাড়েই কাজ চলে — রিপোর্ট-টিপোর্ট কাল হবে, চলো বাড়ি!',
    exitLine: coworkerExit,
    right: ['না — অফিসে রিপোর্ট না করলে ডকেট খোলাই থাকে', 'না — জুগাড় নয়, রিপোর্ট করে ডকেট ক্লোজ করব'],
    wrong: [
      'ঠিক, রিপোর্ট কাল দিলেই হবে, চলো বাড়ি',
      'ঠিক, ডকেট খোলা থাকলেই বা কী, চলো বাড়ি',
      'মাঠে জুগাড়েই চলে, তাহলে চলো বাড়ি যাই',
      'কাগজ পরে দেখা যাবে, আজ চলো বাড়ি যাই',
      'ঠিক, রিপোর্ট-টিপোর্টের দরকার নেই, চলো বাড়ি',
    ],
    asks: _asks,
  );

  static CoworkerScript script(M8GPush p) => p == M8GPush.phone ? pushPhone : pushReport;
  static const coworkers = [pushPhone, pushReport];

  /// His pushes (the director records them with tool/rival_clip.py; until then
  /// silent, caption held).
  static List<String> get newRivalLines => [for (final s in coworkers) s.line];

  /// Every spoken guide line (DRAFT — owner wording, then recorded). The notes,
  /// labels and captions are shown, never spoken.
  static List<String> get newGuideLines => <String>{
        intro,
        hearIntro,
        ...tasks,
        ...tapWhy,
        lit,
        refused,
        fixRight,
        fail,
        deadlyWord,
        nearMissWord,
        for (final r in {M8GReason.solar, M8GReason.climb, M8GReason.video, M8GReason.docket}) question(r),
        for (final s in coworkers) ...s.asks,
        promoted(rankTo),
        for (final m in M8GMistakes.all) m.textBn,
      }.toList();
}

// ============================================================================
// Mistakes (the module table, after the rulings)
// ============================================================================

const _art = 'assets/game/art/m8_gate_case_file';

/// One gate mistake and the lesson that teaches it.
@immutable
class M8GMistake {
  const M8GMistake(this.lessonId, this.m);
  final String lessonId;
  final DoMistake m;
}

abstract final class M8GMistakes {
  // --- deadly (DRAFT wording — owner) ------------------------------------------
  static const noPtw = M8GMistake('8.5', DoMistake(
    key: 'm8/gate/no-ptw',
    textBn: 'লিখিত PTW হাতে না নিয়ে পোলে ওঠা — ফোনে "লাইন OFF" শুনে নয়। লিখিত পারমিট হাতে না পেলে পোল-এ উঠবেন না।',
    art: '$_art/ptw.svg',
    deadly: true,
    lessonPoint: 0,
  ));
  static const noTester = M8GMistake('8.5', DoMistake(
    key: 'm8/gate/no-tester',
    textBn: 'টেস্টারে 0 V না দেখে পোলে ওঠা — শাটডাউন মানেই ডেড নয়। আগে টেস্টারে ডেড প্রমাণ, তারপর আর্থ, তারপর ওঠা।',
    art: '$_art/tester.svg',
    deadly: true,
    lessonPoint: 5,
  ));
  static const noEarth = M8GMistake('8.5', DoMistake(
    key: 'm8/gate/no-earth',
    textBn: 'কাজের জায়গার আগে ও পরে, দুই প্রান্তে আর্থ ছাড়া পোলে ওঠা — দুই প্রান্তে অস্থায়ী আর্থিং বাধ্যতামূলক।',
    art: '$_art/earth.svg',
    deadly: true,
    lessonPoint: 4,
  ));
  static const solarIn = M8GMistake('8.8', DoMistake(
    key: 'm8/gate/solar-in',
    textBn: 'সোলার বাড়ির ফিউজ লাগানো রেখে ওঠা — গ্রিড বন্ধেও ইনভার্টার চললে ব্যাক-ফিডে লাইন সজীব। শুধু ট্রান্সফরমার নয়, পোল থেকে ওই বাড়ির ফিউজও খুলুন।',
    art: '$_art/solar.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const rodLive = M8GMistake('8.5', DoMistake(
    key: 'm8/gate/rod-live',
    textBn: 'শাটডাউনের আগে আর্থ রড — লাইন তখনও চালু, রড পড়তেই আর্ক। আগে লিখিত পারমিট আর শাটডাউন, তারপর টেস্টারে 0 V, তারপর আর্থ।',
    art: '$_art/earth.svg',
    deadly: true,
    lessonPoint: 4,
  ));
  static const liveTrim = M8GMistake('8.9', DoMistake(
    key: 'm8/gate/live-trim',
    textBn: 'শাটডাউন ছাড়া লাইন-ছোঁয়া ডাল ছাঁটা — চালু লাইনে ডাল কাটলে বিদ্যুৎ নেমে আসে। শাটডাউন নিয়ে তবেই ডাল ছাঁটুন।',
    art: '$_art/trim.svg',
    deadly: true,
    lessonPoint: 0,
  ));

  // --- slips ---------------------------------------------------------------------
  static const rodNoTester = M8GMistake('8.5', DoMistake(
    key: 'm8/gate/rod-no-tester',
    textBn: 'আগে টেস্টারে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক।',
    art: '$_art/earth.svg',
    lessonPoint: 4,
  ));
  static const needlessFuse = M8GMistake('8.8', DoMistake(
    key: 'm8/gate/needless-fuse',
    textBn: 'সোলার নেই এমন বাড়ির ফিউজ খোলা — অকারণে সাপ্লাই বন্ধ। ছাদের প্যানেল, সবুজ স্টিকার আর নেট মিটারের Import/Export দেখে সোলার বাড়ি চিনুন।',
    art: '$_art/solar.svg',
    lessonPoint: 2,
  ));
  static const removeNoVideo = M8GMistake('8.2', DoMistake(
    key: 'm8/gate/remove-no-video',
    textBn: 'প্রমাণ ছাড়াই হুকিং-এর তার খোলা — চুরিতে প্রথম কাজ প্রমাণ জোগাড় (ভিডিও/ছবি), তারপর লাইন বিচ্ছিন্ন। পোল থেকে হুকিং তার দেখা যাওয়া ভিডিও চাই।',
    art: '$_art/hook.svg',
    lessonPoint: 4,
  ));
  static const badCable = M8GMistake('8.2', DoMistake(
    key: 'm8/gate/bad-cable',
    textBn: 'হুকিং নেই এমন বৈধ সংযোগের তার খোলা — চুরি ছাড়া বিচ্ছিন্ন করতে 15 দিনের লিখিত নোটিশ বাধ্যতামূলক।',
    art: '$_art/hook.svg',
    lessonPoint: 4,
  ));
  static const trimHarmless = M8GMistake('8.9', DoMistake(
    key: 'm8/gate/trim-harmless',
    textBn: 'যে ডাল লাইনের বিপদ ঘটাচ্ছে না তা ছাঁটা, বা গুঁড়িতে কোপ — আমরা শুধু বিপদের ডাল ছাঁটতে পারি, পুরো গাছ কাটার অধিকার নেই।',
    art: '$_art/trim.svg',
    lessonPoint: 0,
  ));
  static const listenReport = M8GMistake('8.6', DoMistake(
    key: 'm8/gate/listen-report',
    textBn: 'রিপোর্ট না করেই ফেরা — কাজ শেষ করে অফিসে রিপোর্ট না করা পর্যন্ত ডকেট ক্লোজ হয় না, আর ডকেট খোলা থাকলে SoP-এর জরিমানা বাড়তে থাকে।',
    art: '$_art/docket.svg',
    lessonPoint: 1,
  ));
  static const docketLate = M8GMistake('8.3', DoMistake(
    key: 'm8/gate/docket-late',
    textBn: 'ডকেট দেরিতে ক্লোজ — LT তার ছিঁড়লে শহরে সাধারণত 4 ঘন্টার মধ্যে সাপ্লাই ফেরাতে হয়। কাজ শেষ হওয়া মাত্রই ডকেট ক্লোজ করুন।',
    art: '$_art/docket.svg',
    lessonPoint: 1,
  ));
  static const docketOpen = M8GMistake('8.6', DoMistake(
    key: 'm8/gate/docket-open',
    textBn: 'রিপোর্ট না করায় ডকেট খোলা — কাজ শেষ করে অফিসে রিপোর্ট না করা পর্যন্ত ডকেট ক্লোজ হয় না।',
    art: '$_art/docket.svg',
    lessonPoint: 1,
  ));
  static const reportEarly = M8GMistake('8.6', DoMistake(
    key: 'm8/gate/report-early',
    textBn: 'মেরামতের আগেই রিপোর্ট দিয়ে ডকেট বন্ধ — এটা মিথ্যা ক্লোজ। কাজ শেষ করার পরই অফিসে রিপোর্ট।',
    art: '$_art/docket.svg',
    lessonPoint: 1,
  ));
  static const noSeizure = M8GMistake('8.2', DoMistake(
    key: 'm8/gate/no-seizure',
    textBn: 'হুকিং ধরেও জব্দ তালিকা নেই — রেইড বা চেকিং-এর সময় জব্দ তালিকা (Seizure List) তৈরি করতে ভুলবেন না।',
    art: '$_art/hook.svg',
    lessonPoint: 4,
  ));
  static const noPolice = M8GMistake('8.2', DoMistake(
    key: 'm8/gate/no-police',
    textBn: 'হুকিং ধরেও অফিসারের মাধ্যমে অভিযোগ নেই — 24 ঘন্টার মধ্যে থানায় বা পুলিশে অভিযোগ জানাতে হয় (অফিসারের মাধ্যমে)।',
    art: '$_art/hook.svg',
    lessonPoint: 4,
  ));
  static const noPhoto = M8GMistake('8.6', DoMistake(
    key: 'm8/gate/no-photo',
    textBn: 'গ্রাহকের মিথ্যে অভিযোগে ছবি বা ভিডিও নেই — লাইনে সমস্যা নেই দেখে ছবি তুলে রাখুন, শুনানির সময় এটাই প্রমাণ হবে।',
    art: '$_art/photo.svg',
    lessonPoint: 1,
  ));
  static const needlessSeize = M8GMistake('8.2', DoMistake(
    key: 'm8/gate/needless-seize',
    textBn: 'হুকিং ছাড়া বাড়ির জিনিস জব্দ — জব্দ তালিকা রেইডে চুরি ধরা পড়লে হয়, অকারণে নয়।',
    art: '$_art/hook.svg',
    lessonPoint: 4,
  ));
  static const wrongRecord = M8GMistake('8.10', DoMistake(
    key: 'm8/gate/wrong-record',
    textBn: 'ভুল কাগজ দেখানো — লগবুক আর PTW কপির মতোই প্রতিটা রেকর্ডের কাজ আলাদা: লেখা নেই = প্রমাণ নেই, আর প্রশ্নের প্রমাণই চাই।',
    art: '$_art/record.svg',
    lessonPoint: 0,
  ));

  static const values = [
    noPtw, noTester, noEarth, solarIn, rodLive, liveTrim,
    rodNoTester, needlessFuse, removeNoVideo, badCable, trimHarmless, listenReport, docketLate, docketOpen,
    reportEarly, noSeizure, noPolice, noPhoto, needlessSeize, wrongRecord,
  ];

  static List<DoMistake> get all => [for (final x in values) x.m];

  /// The lesson that teaches [m] (for the mistakes book and পাঠে দেখুন).
  static String lessonOf(DoMistake m) => values.firstWhere((x) => x.m.key == m.key, orElse: () => const M8GMistake('8.10', DoMistake(key: '', textBn: '', art: ''))).lessonId;
}

// ============================================================================
// The deal
// ============================================================================

/// One house: whether it is a solar house, and what its wall and roof show.
@immutable
class M8GHouse {
  const M8GHouse({required this.solar, required this.art});
  final bool solar;
  final M8GHouseArt art;
}

/// One dealt play: the lane, the clues, two of the three complications, the
/// times (all in game minutes; the clock is shown, never a deadline).
@immutable
class M8GDeal {
  const M8GDeal({
    required this.mirror,
    required this.regMin,
    required this.arriveOff,
    required this.permitTrip,
    required this.repairMin,
    required this.phoneAt,
    required this.houses,
    required this.c1,
    required this.c2,
    required this.c3,
    required this.hookHouse,
    required this.touching,
    required this.c3House,
    required this.combo,
  });

  final bool mirror;

  /// The docket's registration time (minutes of the day, 17:00–18:30).
  final int regMin;

  /// Minutes between the registration and the crew's arrival.
  final int arriveOff;
  final int permitTrip;
  final int repairMin;

  /// The phone says "line OFF" once this many game minutes have passed.
  final int phoneAt;
  final List<M8GHouse> houses;
  final bool c1;
  final bool c2;
  final bool c3;

  /// C1: the hooking house (0 = the lane's first house, at pole 2; 1 = at pole 3) or -1.
  final int hookHouse;

  /// C2: the branch resting on the span or -1.
  final int touching;

  /// C3: the consumer who says his supply has not come back, or -1.
  final int c3House;

  /// Which two of the three complications (0 C1+C2, 1 C1+C3, 2 C2+C3).
  final int combo;

  List<int> get solarHouses => [for (var i = 0; i < houses.length; i++) if (houses[i].solar) i];
  int get solarCount => solarHouses.length;
  int get startMin => regMin + arriveOff;

  /// Minutes left of the docket's time on arrival.
  int get remaining => kM8GLimitMin - arriveOff;

  /// The shortest lawful plan up to the report: permit, solar fuses, the tester,
  /// two rods, the hook (video + removal) if dealt, the repair, the report.
  int get minimalToReport => permitTrip + 6 * solarCount + 3 + 16 + (c1 ? 12 : 0) + repairMin + 5;

  /// Every act at every place (the "do everything everywhere" plan).
  int get everythingMin => permitTrip + 6 * 6 + 4 * 3 + 4 * 8 + repairMin + 10 + 10 + 3 * 8 + 22 * 2 + 6 * 10 + 5 + 5;

  M8GPlan get plan => M8GPlan(houses: [for (final h in houses) h.art], mirror: mirror, hookHouse: hookHouse, touching: touching, c3House: c3House, nHouses: houses.length);
}

M8GDeal dealM8G(math.Random rng, {int? avoidCombo}) {
  while (true) {
    final r = rng.nextInt(100);
    final solarN = r < 25 ? 0 : (r < 70 ? 1 : 2);
    var combo = rng.nextInt(3);
    if (avoidCombo != null && combo == avoidCombo) combo = (combo + 1 + rng.nextInt(2)) % 3;
    final c1 = combo != 2;
    final c2 = combo != 1;
    final c3 = combo != 0;
    final hookHouse = c1 ? rng.nextInt(2) : -1;
    final touching = c2 ? rng.nextInt(3) : -1;
    final trip = 20 + rng.nextInt(16);
    final repair = 50 + rng.nextInt(26);
    final minimal = trip + 6 * solarN + 3 + 16 + (c1 ? 12 : 0) + repair + 5;
    final maxOff = math.min(60, kM8GLimitMin - 30 - minimal);
    if (maxOff < 20) continue;
    final arrive = 20 + rng.nextInt(maxOff - 20 + 1);

    final others = [for (var i = 0; i < 6; i++) if (i != hookHouse) i]..shuffle(rng);
    final solar = others.take(solarN).toSet();
    final plain = [for (final i in others) if (!solar.contains(i)) i];
    final c3House = c3 ? plain[rng.nextInt(plain.length)] : -1;
    // Clue mixes: every solar house at least one; at least one non-roof clue overall.
    var nonRoofGiven = false;
    final houses = <M8GHouse>[];
    for (var i = 0; i < 6; i++) {
      if (solar.contains(i)) {
        var panel = rng.nextBool();
        var parapet = !panel && rng.nextInt(3) > 0;
        var sticker = rng.nextInt(3) == 0;
        var net = rng.nextInt(3) == 0;
        if (!nonRoofGiven) {
          if (rng.nextBool()) {
            sticker = true;
          } else {
            net = true;
          }
        }
        if (!(panel || parapet || sticker || net)) panel = true;
        if (sticker || net) nonRoofGiven = true;
        if (panel) parapet = false;
        houses.add(M8GHouse(
          solar: true,
          art: M8GHouseArt(panel: panel, parapet: parapet, sticker: sticker, net: net, flat: parapet || (!panel && rng.nextBool()), deco: rng.nextInt(3) == 0 ? 2 : 0),
        ));
      } else {
        houses.add(M8GHouse(solar: false, art: M8GHouseArt(flat: rng.nextBool(), deco: rng.nextInt(3))));
      }
    }
    return M8GDeal(
      mirror: rng.nextBool(),
      regMin: 17 * 60 + rng.nextInt(91),
      arriveOff: arrive,
      permitTrip: trip,
      repairMin: repair,
      phoneAt: 2 + rng.nextInt(5),
      houses: houses,
      c1: c1,
      c2: c2,
      c3: c3,
      hookHouse: hookHouse,
      touching: touching,
      c3House: c3House,
      combo: combo,
    );
  }
}

// ============================================================================
// The engine: one state, every rule
// ============================================================================

enum M8GRecKind { ptw, docket, hookVideo, hookWall, seizure, police, litPhoto, photo, none }

/// One record in the player's file.
class M8GRec {
  M8GRec(this.id, this.kind, this.labelBn, {this.house = -1, this.ok = true, this.video = false});
  final String id;
  final M8GRecKind kind;
  final String labelBn;
  final int house;

  /// A docket slip: reported on time; a seizure: on the hooking house; a lit-house photo: after the restore.
  final bool ok;
  final bool video;
}

/// The hearing's questions.
enum M8GQKind { delay, noCause, seizure, police, claim, needlessSeize, falseClose }

class M8GQ {
  M8GQ(this.kind, {this.consequence = false, this.free = false});
  final M8GQKind kind;

  /// Plays as a consequence with no drop (a needless or false act).
  final bool consequence;

  /// The consequence costs no second slip (the docket was left open by listening).
  final bool free;

  /// One slip per question: a wrong drop already cost it.
  bool slipped = false;
}

/// What one move did.
class M8GOut {
  const M8GOut({this.mistake, this.note, this.reason, this.pay = 0, this.bounce = false, this.paper = false, this.cut, this.restored = false, this.at, this.endsQ = false, this.crew});

  /// A deadly move (ends the play) or a slip.
  final DoMistake? mistake;

  /// The raw note (what the act did).
  final String? note;

  /// ◆ after the move.
  final M8GReason? reason;

  /// Points without a reason (a right plain act).
  final int pay;

  /// The drop slides back: nothing happened.
  final bool bounce;

  /// A paper act (the paper sound).
  final bool paper;

  /// A short cut-scene before the verdict (the permit trip, the repair).
  final String? cut;

  /// The line came back (the crew is down, the earths are off).
  final bool restored;

  /// Where a deadly move happened.
  final M8GTgt? at;

  /// The hearing question ends with this move.
  final bool endsQ;

  /// The crew goes up this pole during the cut-scene.
  final int? crew;

  bool get deadly => mistake?.deadly ?? false;
}

class M8GRun {
  M8GRun(this.deal);
  final M8GDeal deal;

  int minutes = 0;
  bool permit = false;
  bool tested = false;
  bool repaired = false;
  bool restored = false;
  bool hookVideo = false;
  bool hookRemoved = false;
  bool hookRemovedNoVideo = false;
  bool branchCut = false;
  bool reported = false;
  bool reportedProper = false;
  bool reportOnTime = false;
  bool reportFalse = false;
  bool docketLeft = false;
  bool needlessSeize = false;
  bool hasPolice = false;
  bool solarReasonDone = false;
  final Set<int> rods = {};
  final Set<int> fusesOut = {};
  final List<M8GRec> records = [];
  int slips = 0;
  bool ended = false;
  M8GPush? push;
  M8GTgt? lastTgt;
  final List<String> caught = [];
  int _recN = 0;

  /// Game clock (minutes of the day).
  int get clock => deal.startMin + minutes;
  bool get permitActive => permit && !restored;

  /// The phone has said "line OFF — go up" (it keeps saying it).
  bool get phoneUp => minutes >= deal.phoneAt;
  bool get solarIn => deal.solarHouses.any((h) => !fusesOut.contains(h));
  bool get bothEarths => rods.contains(0) && rods.contains(3);
  bool get hookFound => hookVideo || hookRemoved;

  void tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  /// Mark: 100 − 15 × slips; pass at 55 or more.
  int get percent => math.max(0, 100 - 15 * slips);
  bool get passed => percent >= 55;
  bool get quick => slips == 0;
  void finish() => ended = true;

  M8GOut _die(M8GMistake m, M8GTgt at) {
    ended = true;
    return M8GOut(mistake: m.m, at: at);
  }

  M8GOut _slip(M8GMistake m, {String? note, bool endsQ = false}) {
    slips++;
    return M8GOut(mistake: m.m, note: note, endsQ: endsQ);
  }

  M8GRec _add(M8GRecKind k, String label, {int house = -1, bool ok = true, bool video = false}) {
    final r = M8GRec('r${++_recN}', k, label, house: house, ok: ok, video: video);
    records.add(r);
    return r;
  }

  /// Can this act physically happen here? (No: it slides back, no cost, no verdict.)
  bool fits(M8GTok t, M8GTgt g) => switch (t) {
        M8GTok.permit || M8GTok.police || M8GTok.report => g.kind == M8GTgtKind.van,
        M8GTok.fuse || M8GTok.seize => g.kind == M8GTgtKind.house,
        M8GTok.rod || M8GTok.tester => g.kind == M8GTgtKind.pole,
        M8GTok.climb => g.kind == M8GTgtKind.pole && (g.i == 1 || g.i == 2),
        M8GTok.camera => true,
        M8GTok.hook => g.kind == M8GTgtKind.wire,
        M8GTok.trim => g.kind == M8GTgtKind.branch || g.kind == M8GTgtKind.trunk,
      };

  /// The coworker's moment, if this move is the one he is dealt on: M1 at any
  /// touch once the phone has spoken and the PTW is not in the file, M2 at the
  /// report or the way home.
  M8GPush? pushFor(M8GTok? t, M8GTgt? g, {bool home = false}) {
    if (ended) return null;
    if (home) return M8GPush.report;
    if (t == null || g == null || !fits(t, g)) return null;
    if (phoneUp && !permit) return M8GPush.phone;
    if (t == M8GTok.report) return M8GPush.report;
    return null;
  }

  /// He was listened to: the climb at once without the PTW (deadly), or the
  /// report left for tomorrow (a slip; the docket stays open).
  M8GOut listened() {
    if ((push ?? M8GPush.phone) == M8GPush.phone) return _die(M8GMistakes.noPtw, lastTgt ?? M8GTgt.pole(1));
    docketLeft = true;
    return _slip(M8GMistakes.listenReport);
  }

  /// Why a climb cannot start (deadly), or null: the written PTW, the tester's
  /// 0 V, earth rods at poles 1 and 4, every solar fuse out.
  M8GMistake? _climbCheck() {
    if (!permitActive) return M8GMistakes.noPtw;
    if (!tested) return M8GMistakes.noTester;
    if (!bothEarths) return M8GMistakes.noEarth;
    if (solarIn) return M8GMistakes.solarIn;
    return null;
  }

  M8GOut drop(M8GTok t, M8GTgt g) {
    if (ended) return const M8GOut(bounce: true);
    lastTgt = g;
    if (!fits(t, g)) return const M8GOut(bounce: true, note: M8GateLines.nothingThere);
    switch (t) {
      case M8GTok.permit:
        if (permit) return const M8GOut(note: M8GateLines.permitAgain);
        minutes += deal.permitTrip;
        permit = true;
        _add(M8GRecKind.ptw, 'PTW · কার্বন কপি · ${M8GateLines.hm(clock)}');
        tag('লিখিত PTW, তবেই কাজ');
        return const M8GOut(note: M8GateLines.permitDone, paper: true, cut: M8GateLines.permitCut);
      case M8GTok.tester:
        minutes += 3;
        if (!permitActive) return const M8GOut(note: M8GateLines.testerLive);
        tested = true;
        tag('টেস্টারে 0 V');
        return const M8GOut(note: M8GateLines.testerDead);
      case M8GTok.rod:
        if (!permitActive) return _die(M8GMistakes.rodLive, g);
        minutes += 8;
        rods.add(g.i);
        if (!tested) return _slip(M8GMistakes.rodNoTester, note: M8GateLines.rodOn(g.i));
        if (bothEarths) tag('দুই প্রান্তে আর্থ');
        return M8GOut(note: M8GateLines.rodOn(g.i));
      case M8GTok.fuse:
        if (fusesOut.contains(g.i)) return const M8GOut(note: M8GateLines.fuseAgain);
        minutes += 6;
        fusesOut.add(g.i);
        if (!deal.houses[g.i].solar) return _slip(M8GMistakes.needlessFuse, note: M8GateLines.fuseOut(g.i));
        if (!solarReasonDone) {
          solarReasonDone = true;
          return M8GOut(note: M8GateLines.fuseOut(g.i), reason: M8GReason.solar);
        }
        return M8GOut(note: M8GateLines.fuseOut(g.i), pay: 10);
      case M8GTok.climb:
        final m = _climbCheck();
        if (m != null) return _die(m, g);
        if (repaired) return const M8GOut(note: M8GateLines.repairedAgain);
        minutes += deal.repairMin;
        repaired = true;
        restored = true;
        rods.clear();
        return M8GOut(note: M8GateLines.repaired, cut: M8GateLines.repairCut, restored: true, reason: M8GReason.climb, crew: g.i);
      case M8GTok.hook:
        final m = _climbCheck();
        if (m != null) return _die(m, g);
        if (!(deal.c1 && g.i == deal.hookHouse)) return _slip(M8GMistakes.badCable);
        if (hookRemoved) return const M8GOut(note: M8GateLines.hookAgain);
        minutes += 10;
        hookRemoved = true;
        if (!hookVideo) {
          hookRemovedNoVideo = true;
          return _slip(M8GMistakes.removeNoVideo, note: M8GateLines.hookOff);
        }
        return M8GOut(note: M8GateLines.hookOff, reason: M8GReason.video, crew: g.i);
      case M8GTok.camera:
        minutes += 2;
        final r = _shot(g);
        return M8GOut(note: '${M8GateLines.filed} — ${r.labelBn}', paper: true);
      case M8GTok.trim:
        minutes += 8;
        if (g.kind == M8GTgtKind.trunk || g.i != deal.touching) return _slip(M8GMistakes.trimHarmless);
        if (branchCut) return const M8GOut(note: M8GateLines.trimAgain);
        if (!permitActive) return _die(M8GMistakes.liveTrim, g);
        branchCut = true;
        tag(M8GateLines.caughtTrim);
        return const M8GOut(note: M8GateLines.trimmed, pay: 10);
      case M8GTok.seize:
        minutes += 10;
        final ok = deal.c1 && g.i == deal.hookHouse;
        if (!ok) needlessSeize = true;
        final r = _add(M8GRecKind.seizure, 'জব্দ তালিকা · ${M8GateLines.tgt(g)} · ${M8GateLines.hm(clock)}', house: g.i, ok: ok);
        return M8GOut(note: '${M8GateLines.filed} — ${r.labelBn}', paper: true);
      case M8GTok.police:
        if (hasPolice) return const M8GOut(note: M8GateLines.policeAgain);
        minutes += 5;
        hasPolice = true;
        _add(M8GRecKind.police, 'অভিযোগ · অফিসারের মাধ্যমে · ${M8GateLines.hm(clock)}');
        return const M8GOut(note: M8GateLines.policeNote, paper: true);
      case M8GTok.report:
        if (reportedProper || (reported && !repaired)) return const M8GOut(note: M8GateLines.alreadyReported);
        minutes += 5;
        reported = true;
        final onTime = clock - deal.regMin <= kM8GLimitMin;
        if (!repaired) {
          reportFalse = true;
          _add(M8GRecKind.docket, 'ডকেট স্লিপ · নথিভুক্ত ${M8GateLines.hm(deal.regMin)} · রিপোর্ট ${M8GateLines.hm(clock)}', ok: false);
        } else {
          reportedProper = true;
          reportOnTime = onTime;
          _add(M8GRecKind.docket, 'ডকেট স্লিপ · নথিভুক্ত ${M8GateLines.hm(deal.regMin)} · রিপোর্ট ${M8GateLines.hm(clock)}', ok: onTime);
        }
        return const M8GOut(note: M8GateLines.reportedNote, paper: true);
    }
  }

  /// A camera shot: the record only says where it was taken.
  M8GRec _shot(M8GTgt g) {
    final t = M8GateLines.hm(clock);
    switch (g.kind) {
      case M8GTgtKind.wire:
        final hook = deal.c1 && g.i == deal.hookHouse && !hookRemoved;
        if (hook) hookVideo = true;
        return _add(hook ? M8GRecKind.hookVideo : M8GRecKind.photo, enDigits('ভিডিও · পোল ও সার্ভিস কেবিল ${g.i + 1} · $t'), house: g.i, video: true);
      case M8GTgtKind.house:
        if (deal.c1 && g.i == deal.hookHouse) return _add(M8GRecKind.hookWall, 'ছবি · ${M8GateLines.tgt(g)} · $t', house: g.i);
        if (deal.c3 && g.i == deal.c3House && restored) return _add(M8GRecKind.litPhoto, 'ছবি · ${M8GateLines.tgt(g)} · $t', house: g.i);
        return _add(M8GRecKind.photo, 'ছবি · ${M8GateLines.tgt(g)} · $t', house: g.i);
      default:
        return _add(M8GRecKind.photo, 'ছবি · ${M8GateLines.tgt(g)} · $t');
    }
  }

  // --- the hearing ----------------------------------------------------------------
  /// The questions the deal and the player's own acts made relevant (1–4, plus
  /// every consequence).
  List<M8GQ> buildHearing(math.Random rng) {
    final must = <M8GQ>[
      M8GQ(M8GQKind.delay, consequence: docketLeft, free: docketLeft),
      if (needlessSeize) M8GQ(M8GQKind.needlessSeize, consequence: true),
      if (reportFalse) M8GQ(M8GQKind.falseClose, consequence: true),
    ];
    final opt = <M8GQ>[
      if (deal.c1 && hookVideo && hookRemoved) M8GQ(M8GQKind.noCause),
      if (deal.c1 && hookFound) M8GQ(M8GQKind.seizure),
      if (deal.c1 && hookFound) M8GQ(M8GQKind.police),
      if (deal.c3 && restored) M8GQ(M8GQKind.claim),
    ]..shuffle(rng);
    final room = math.max(0, 4 - must.length);
    return [...must, ...opt.take(room)]..shuffle(rng);
  }

  bool isRight(M8GQKind k, M8GRec r) => switch (k) {
        M8GQKind.delay => r.kind == M8GRecKind.docket && r.ok,
        M8GQKind.noCause => r.kind == M8GRecKind.hookVideo,
        M8GQKind.seizure => r.kind == M8GRecKind.seizure && r.ok,
        M8GQKind.police => r.kind == M8GRecKind.police,
        M8GQKind.claim => r.kind == M8GRecKind.litPhoto,
        _ => false,
      };

  /// Is there a right record in the file for [k]?
  bool hasRight(M8GQKind k) => records.any((r) => isRight(k, r));

  static M8GReason reasonOf(M8GQKind k) => switch (k) {
        M8GQKind.delay => M8GReason.docket,
        M8GQKind.noCause => M8GReason.hookVideo,
        M8GQKind.seizure => M8GReason.seizure,
        M8GQKind.police => M8GReason.police,
        _ => M8GReason.photo,
      };

  M8GMistake _missing(M8GQKind k) => switch (k) {
        M8GQKind.delay => reported ? M8GMistakes.docketLate : M8GMistakes.docketOpen,
        M8GQKind.noCause => M8GMistakes.noSeizure,
        M8GQKind.seizure => M8GMistakes.noSeizure,
        M8GQKind.police => M8GMistakes.noPolice,
        _ => M8GMistakes.noPhoto,
      };

  /// A consequence question (no drop): the slip (or, left by listening, no
  /// second slip).
  M8GOut consequence(M8GQ q) {
    if (q.kind == M8GQKind.needlessSeize) return _slip(M8GMistakes.needlessSeize, endsQ: true);
    if (q.kind == M8GQKind.falseClose) return _slip(M8GMistakes.reportEarly, endsQ: true);
    return const M8GOut(note: M8GateLines.docketHeld, endsQ: true);
  }

  /// A record dropped on the bench ([rec] null = the card "ফাইলে নেই").
  M8GOut answer(M8GQ q, M8GRec? rec) {
    final right = hasRight(q.kind);
    if (right) {
      if (rec != null && isRight(q.kind, rec)) {
        return M8GOut(note: M8GateLines.nod, reason: reasonOf(q.kind), endsQ: true);
      }
      if (q.slipped) return const M8GOut(note: M8GateLines.notThis);
      q.slipped = true;
      return _slip(M8GMistakes.wrongRecord, note: M8GateLines.notThis);
    }
    // The right record is missing: any drop gets "no proof" and one slip.
    return _slip(_missing(q.kind), note: M8GateLines.noProof, endsQ: true);
  }
}

// ============================================================================
// Pack, probe
// ============================================================================

@immutable
class M8GatePack {
  const M8GatePack({required this.id, required this.titleBn, this.quickMs = 330000});
  final String id;
  final String titleBn;

  /// The quick bonus: a clean play inside this time (5 min 30 s, ~85 % of a
  /// clean play — the builder's estimate, M8-15).
  final int quickMs;
}

const m8GatePacks = {
  'gate_m8': M8GatePack(id: 'gate_m8', titleBn: M8GateLines.title),
};

/// Test hook: what the gate is doing now. Never used by the app.
class M8GateProbe {
  _M8GRunPageState? _s;
  M8GDeal? get deal => _s?._run.deal;
  M8GRun? get run => _s?._run;

  /// intro, idle, lifted, roof, cut, hear, hearLifted, freeze, done.
  String get phase => _s?._phase.name ?? 'none';

  /// field or hearing.
  String get stage => _s?._stage.name ?? 'none';

  /// The right cards of the deck now up (reason or coworker).
  List<String> get rightNow {
    final s = _s;
    if (s == null) return const [];
    if (s.coworkerChoiceUp) return s.coworkerScript.right;
    if (s.reasonOpen) return s._reasonRight;
    return const [];
  }

  bool get coworkerUp => _s?.coworkerOpen ?? false;
  bool get busy => _s?.tableBusy ?? false;
  int get score => _s?._runScore ?? 0;
  double get pan => _s?._pan ?? 0;

  /// The hearing's questions and the one now up.
  List<M8GQ> get questions => _s?._qs ?? const [];
  M8GQ? get question => _s == null || _s!._qs.isEmpty || _s!._hq >= _s!._qs.length ? null : _s!._qs[_s!._hq];

  /// Pans the lane so [t] is in the middle (tests only).
  void panTo(M8GTgt t) => _s?._panTo(t);
}

// ============================================================================
// Page
// ============================================================================

class M8GateCaseFilePage extends StatefulWidget {
  const M8GateCaseFilePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M8GatePack pack;
  final bool muted;
  final int? seed;
  final M8GateProbe? probe;

  @override
  State<M8GateCaseFilePage> createState() => _M8GateCaseFilePageState();
}

class _M8GateCaseFilePageState extends State<M8GateCaseFilePage> {
  int _round = 0;
  late bool _muted = widget.muted;
  int? _last;

  @override
  Widget build(BuildContext context) => _M8GRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        probe: widget.probe,
        avoid: _last,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onDealt: (c) => _last = c,
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _M8GRunPage extends ConsumerStatefulWidget {
  const _M8GRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.rng,
    required this.onRetry,
    required this.onDealt,
    this.avoid,
    this.probe,
  });

  final LevelContext ctx;
  final M8GatePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final ValueChanged<int> onDealt;
  final int? avoid;
  final M8GateProbe? probe;

  @override
  ConsumerState<_M8GRunPage> createState() => _M8GRunPageState();
}

enum _Stage { field, hearing }

enum _Phase { intro, idle, lifted, roof, cut, hear, hearLifted, freeze, done }

class _M8GRunPageState extends ConsumerState<_M8GRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8GRun _run = M8GRun(dealM8G(widget.rng, avoidCombo: widget.avoid));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The windows lighting up after the restore (0 → 1).
  late final AnimationController _lit = AnimationController(vsync: this, duration: const Duration(milliseconds: 900), value: 1);

  /// A deadly move playing out in colour (0 → 1).
  late final AnimationController _harm = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  _Stage _stage = _Stage.field;
  _Phase _phase = _Phase.intro;
  int _runScore = 0;
  int _chain = 0;
  late double _pan = _run.deal.mirror ? M8GGeo.maxPan : 0;
  String? _note;

  // The move being made.
  M8GTok? _lifted;
  String _roofText = '';
  String? _cutText;
  int? _crewAt;
  bool _phoneShown = false;

  // The hearing.
  List<M8GQ> _qs = const [];
  int _hq = 0;
  List<M8GRec> _fan = const [];
  M8GRec? _hLifted;
  bool _qOpen = false;

  // The ◆ question now and what follows its proceed.
  M8GReason? _reasonNow;
  List<String> _reasonRight = const [];
  VoidCallback? _afterReason;

  // Cards.
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  String _cardLesson = '8.10';
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
  String _rankFrom = M8GateLines.rankFrom;
  String _rankTo = M8GateLines.rankTo;

  final _nudge = TaskNudge();
  int _nudgeN = 0;
  final _hints = IdleHintController();
  var _hintFlip = false;
  M8GGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M8GDeal get _deal => _run.deal;

  @override
  void initState() {
    super.initState();
    widget.probe?._s = this;
    widget.onDealt(_deal.combo);
  }

  @override
  void dispose() {
    if (widget.probe?._s == this) widget.probe?._s = null;
    disposeCoworker();
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

  /// A target's centre on screen (global px) for the score fly.
  Offset _tgtGlobal(M8GTgt t) {
    final g = _geo;
    if (g == null) return _centre();
    final size = MediaQuery.sizeOf(context);
    final r = g.at(t, _pan);
    final k = size.width / 360;
    return Offset(r.center.dx.clamp(0.0, 360.0) * k, r.center.dy * k);
  }

  /// A target's centre in scene px (the harm painter's space).
  Offset _tgtScene(M8GTgt t) {
    final g = _geo;
    if (g == null) return const Offset(180, 300);
    final r = g.at(t, _pan);
    return Offset(r.center.dx.clamp(0.0, 360.0), r.center.dy);
  }

  void _panTo(M8GTgt t) {
    if (!mounted) return;
    final g = _geo;
    if (g == null) return;
    setState(() => _pan = g.panFor(t));
  }

  // --- the play ---------------------------------------------------------------
  void _start() {
    _clock.start();
    _rankNames();
    setState(() => _phase = _Phase.idle);
    unawaited(_sayChain([M8GateLines.taskA]));
  }

  void _rankNames() {
    List<CatalogModule> mods;
    try {
      mods = ref.read(contentCatalogProvider).value?.modules ?? const [];
    } catch (_) {
      mods = const [];
    }
    for (final m in mods) {
      if (m.id == 'm7' && m.rankName.isNotEmpty) _rankFrom = m.rankName;
      if (m.id == 'm8' && m.rankName.isNotEmpty) _rankTo = m.rankName;
    }
  }

  /// The scene takes a touch now (no card, deck, praise window or cut-scene).
  bool get _free => !_ended && _card == null && !tableBusy && !coworkerOpen && _phase != _Phase.cut;

  bool get _fieldScene => _stage == _Stage.field && (_phase == _Phase.idle || _phase == _Phase.lifted);
  bool get _hearScene => _stage == _Stage.hearing && (_phase == _Phase.hear || _phase == _Phase.hearLifted);

  void _toIdle() {
    if (!mounted || _ended) return;
    setState(() {
      _phase = _stage == _Stage.field ? _Phase.idle : _Phase.hear;
      _lifted = null;
      _hLifted = null;
    });
    if (_stage == _Stage.field && _run.phoneUp && !_run.permit && !_phoneShown) {
      setState(() => _phoneShown = true);
      _cue('sounds/intro/tick.ogg', volume: 0.5);
    }
  }

  void _setNote(String? n) {
    if (n == null || n.isEmpty || !mounted) return;
    setState(() => _note = n);
  }

  // --- the belt -----------------------------------------------------------------
  void _tapToken(M8GTok t) {
    if (!_free || !_fieldScene) {
      _hints.missTap();
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.45);
    setState(() {
      _lifted = _lifted == t ? null : t;
      _phase = _lifted == null ? _Phase.idle : _Phase.lifted;
    });
    if (_lifted != null) unawaited(_sayChain([M8GateLines.taskLifted]));
  }

  void _tapTgt(M8GTgt t) {
    final k = _lifted;
    if (_phase == _Phase.lifted && k != null) {
      _drop(k, t);
      return;
    }
    _hints.missTap();
  }

  /// A long press on a house with nothing in hand: what is on its roof.
  void _roofHold(M8GTgt t) {
    if (!_free || _phase != _Phase.idle || t.kind != M8GTgtKind.house) return;
    HapticFeedback.mediumImpact();
    final art = _deal.houses[t.i].art;
    setState(() {
      _roofText = art.panel
          ? M8GateLines.roofPanel
          : art.parapet
              ? M8GateLines.roofParapet
              : switch (art.deco) {
                  1 => M8GateLines.roofTarp,
                  2 => M8GateLines.roofTank,
                  _ => M8GateLines.roofNone,
                };
      _phase = _Phase.roof;
    });
    unawaited(_sayChain([M8GateLines.taskRoof]));
  }

  void _closeRoof() {
    HapticFeedback.selectionClick();
    _hush();
    _toIdle();
  }

  /// A token dropped on a place: one move.
  void _drop(M8GTok t, M8GTgt g) {
    if (!_free) return;
    final run = _run;
    if (!run.fits(t, g)) {
      HapticFeedback.selectionClick();
      _setNote(M8GateLines.nothingThere);
      _toIdle();
      return;
    }
    // The decisive control waits for the coworker (once a play).
    final p = run.pushFor(t, g);
    if (!coworkerDone && p != null) {
      run.push = p;
      if (!coworkerDue) scheduleCoworker();
      if (holdForCoworker()) {
        setState(() {
          _lifted = null;
          _phase = _Phase.idle;
        });
        return;
      }
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_select.ogg', volume: 0.6);
    _hush();
    setState(() => _lifted = null);
    final o = run.drop(t, g);
    _toIdle();
    unawaited(_apply(o, g));
  }

  /// Plays a move's outcome out: deadly → freeze; else the note, the cut-scene,
  /// the slip card (if any), then the reason / points, then back to the scene.
  Future<void> _apply(M8GOut o, M8GTgt at) async {
    if (!mounted || _ended) return;
    if (o.bounce) {
      _setNote(o.note);
      return;
    }
    if (o.deadly) {
      await _deadly(o.mistake!, at: _tgtScene(o.at ?? at));
      return;
    }
    _setNote(o.note);
    if (o.paper) _cue('sounds/learn/card_deal_a.ogg', volume: 0.4);
    if (o.cut != null) {
      if (o.crew != null) setState(() => _crewAt = o.crew);
      await _cut(o.cut!);
      if (!mounted || _ended) return;
      setState(() => _crewAt = null);
    }
    if (o.restored) _lightUp();
    void next() {
      if (!mounted || _ended) return;
      if (o.reason != null) {
        _reason(o.reason!, then: _toIdle);
        return;
      }
      if (o.pay > 0) {
        unawaited(_levelDelta(o.pay, _tgtGlobal(at), mood: GuideMood.glad));
        unawaited(_sayChain([M8GateLines.fixRight], mood: GuideMood.glad));
      }
      _toIdle();
    }

    if (o.mistake != null) {
      await _slip(o.mistake!, then: next);
      return;
    }
    next();
  }

  Future<void> _cut(String text) async {
    setState(() {
      _cutText = text;
      _phase = _Phase.cut;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 80 : 1100));
    if (!mounted) return;
    setState(() {
      _cutText = null;
      _phase = _stage == _Stage.field ? _Phase.idle : _Phase.hear;
    });
  }

  void _lightUp() {
    _cue('sounds/quiz_complete.ogg', volume: 0.6);
    if (_quiet) {
      _lit.value = 1;
    } else {
      unawaited(_lit.forward(from: 0));
    }
    unawaited(_sayChain([M8GateLines.lit], mood: GuideMood.glad));
  }

  /// "বাড়ি চলুন": ends ACT 1 whenever pressed (the coworker's M2 waits here too).
  void _tapHome() {
    if (!_free || _stage != _Stage.field || !(_phase == _Phase.idle || _phase == _Phase.lifted)) {
      _hints.missTap();
      return;
    }
    if (!coworkerDone) {
      _run.push = M8GPush.report;
      if (!coworkerDue) scheduleCoworker();
      if (holdForCoworker()) {
        setState(() {
          _lifted = null;
          _phase = _Phase.idle;
        });
        return;
      }
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_select.ogg', volume: 0.6);
    _toHearing();
  }

  // --- ACT 2 --------------------------------------------------------------------
  void _toHearing() {
    if (!mounted || _ended) return;
    _hush();
    _qs = _run.buildHearing(widget.rng);
    _hq = 0;
    _fan = [..._run.records]..shuffle(widget.rng);
    setState(() {
      _stage = _Stage.hearing;
      _phase = _Phase.hear;
      _lifted = null;
      _hLifted = null;
      _note = null;
      _qOpen = false;
    });
    unawaited(() async {
      await _sayChain([M8GateLines.hearIntro]);
      if (!mounted || _ended) return;
      _openQuestion();
    }());
  }

  void _openQuestion() {
    if (!mounted || _ended) return;
    if (_hq >= _qs.length) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _qOpen = true;
      _phase = _Phase.hear;
      _hLifted = null;
    });
    final q = _qs[_hq];
    if (q.consequence) {
      unawaited(() async {
        await Future<void>.delayed(Duration(milliseconds: _quiet ? 80 : 1500));
        if (!mounted || _ended || _qs[_hq] != q) return;
        final o = _run.consequence(q);
        _setNote(o.note);
        if (o.mistake != null) {
          await _slip(o.mistake!, then: _nextQuestion);
        } else {
          await Future<void>.delayed(Duration(milliseconds: _quiet ? 80 : 900));
          _nextQuestion();
        }
      }());
    }
  }

  void _nextQuestion() {
    if (!mounted || _ended) return;
    _hq++;
    _openQuestion();
  }

  void _tapRec(M8GRec? rec) {
    if (!_free || !_hearScene || _qs.isEmpty || _hq >= _qs.length || _qs[_hq].consequence) {
      _hints.missTap();
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.45);
    setState(() {
      if (rec == null) {
        _blankUp = !_blankUp;
        _hLifted = null;
      } else {
        _hLifted = _hLifted == rec ? null : rec;
        _blankUp = false;
      }
      _phase = (_hLifted != null || _blankUp) ? _Phase.hearLifted : _Phase.hear;
    });
  }

  bool _blankUp = false;

  void _tapBench() {
    if (_phase != _Phase.hearLifted) {
      _hints.missTap();
      return;
    }
    _dropRec(_blankUp ? null : _hLifted);
  }

  void _dropRec(M8GRec? rec) {
    if (!_free || !_hearScene || _qs.isEmpty || _hq >= _qs.length || _qs[_hq].consequence) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_select.ogg', volume: 0.6);
    _hush();
    final q = _qs[_hq];
    final o = _run.answer(q, rec);
    setState(() {
      _hLifted = null;
      _blankUp = false;
      _phase = _Phase.hear;
    });
    _setNote(o.note);
    if (o.reason != null) {
      _reason(o.reason!, then: _nextQuestion);
      return;
    }
    if (o.mistake != null) {
      unawaited(_slip(o.mistake!, then: o.endsQ ? _nextQuestion : _toIdle));
      return;
    }
  }

  // --- the shared success beat (ReasonTable) ----------------------------------
  void _reason(M8GReason r, {required VoidCallback then}) {
    if (!mounted || _ended) return;
    _reasonNow = r;
    _afterReason = then;
    _reasonRight = M8GateLines.whyRight(r);
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(_reasonRight, M8GateLines.whyWrong(r), widget.rng),
      question: M8GateLines.question(r),
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
    if (r != null) _run.tag(M8GateLines.caught(r));
    _reasonNow = null;
    final then = _afterReason;
    _afterReason = null;
    then?.call();
  }

  // --- the shared pressure moment (CoworkerMoment) -------------------------------
  @override
  CoworkerScript get coworkerScript => M8GateLines.script(_run.push ?? M8GPush.phone);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    if (_card != null || tableBusy || _phase == _Phase.cut) return false;
    return _stage == _Stage.field && (_phase == _Phase.idle || _phase == _Phase.lifted);
  }

  @override
  bool get coworkerMuted => _muted;
  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final o = _run.listened();
      if (o.deadly) {
        await _deadly(o.mistake!, at: _tgtScene(o.at ?? M8GTgt.pole(1)));
        return;
      }
      // M2: the docket stays open; ACT 1 ends after the card.
      await _slip(o.mistake!, then: _toHearing);
      return;
    }
    _run.tag(M8GateLines.caughtPush);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain || _ended) return;
      await _sayChain([M8GateLines.refused], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_phase == _Phase.intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8GateLines.tapWhy[_nudgeN++ % M8GateLines.tapWhy.length]
            : _stage == _Stage.hearing
                ? M8GateLines.hearTasks[_nudgeN++ % M8GateLines.hearTasks.length]
                : _nudge.next(switch (_phase) {
                    _Phase.lifted => M8GateLines.taskLifted,
                    _Phase.roof => M8GateLines.taskRoof,
                    _ => M8GateLines.fieldTasks[_nudgeN++ % M8GateLines.fieldTasks.length],
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
    _cardLesson = M8GMistakes.lessonOf(m);
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
    final speak = await SpokenOnce.first('m8gate/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move plays out: the scene freezes grey and the consequence plays
  /// in colour at [at] (scene px); then near-miss or death.
  Future<void> _deadly(DoMistake m, {required Offset at}) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _cardLesson = M8GMistakes.lessonOf(m);
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
    final speak = await SpokenOnce.first('m8gate/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M8GateLines.deadlyWord : M8GateLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
      // The rank gate: সুপারভাইজার → স্পেশালিস্ট (Module 8's rank; ruling M8-16).
      await save.unlockRank(8);
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
    await _say(_run.passed ? M8GateLines.promoted(_rankTo) : M8GateLines.fail, mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
  M8GView get _view => M8GView(
        pan: _pan,
        permit: _run.permitActive,
        rods: {..._run.rods},
        fusesOut: {..._run.fusesOut},
        crewAt: _crewAt,
        restored: _run.restored,
        hookGone: _run.hookRemoved,
        branchCut: _run.branchCut,
        c3Says: _run.restored && _deal.c3 && _stage == _Stage.field,
        lit: _lit.value,
      );

  List<Widget> _scene(SceneMetrics m) {
    final g = _geo = M8GGeo(m.height, m.inset, mirror: _deal.mirror);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(colorFilter: grey, child: Stack(fit: StackFit.expand, children: _stage == _Stage.field ? _lane(g) : _hall(g))),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('harm'),
          child: IgnorePointer(child: CustomPaint(painter: M8GHarmPainter(at: _harmAt, k: _harm.value))),
        ),
    ];
  }

  List<Widget> _lane(M8GGeo g) {
    final live = _phase == _Phase.lifted;
    return [
      IgnorePointer(key: const ValueKey('lane-paint'), child: RepaintBoundary(child: CustomPaint(painter: M8GWorldPainter(geo: g, plan: _deal.plan, view: _view)))),
      // The lane: swipe to pan; every place a drop target, all alike.
      Positioned.fromRect(
        key: const ValueKey('pano'),
        rect: g.pano,
        child: GestureDetector(
          key: const ValueKey('m8g-pano'),
          behavior: HitTestBehavior.opaque,
          onTap: _hints.missTap,
          onHorizontalDragUpdate: (det) {
            if (_phase == _Phase.intro || _freeze) return;
            setState(() => _pan = (_pan - det.delta.dx).clamp(0.0, M8GGeo.maxPan));
          },
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (final t in M8GTgt.all)
                if (g.at(t, _pan).right > 0 && g.at(t, _pan).left < 360) _target(g, t, live),
            ],
          ),
        ),
      ),
      // The docket on the van door and the clock.
      Positioned.fromRect(key: const ValueKey('docket'), rect: g.docket, child: IgnorePointer(child: _DocketBand(line: M8GateLines.docketLine(_deal.regMin)))),
      Positioned.fromRect(key: const ValueKey('clock'), rect: g.clock, child: IgnorePointer(child: _ClockChip(text: M8GateLines.clockLine(_run.clock)))),
      if (_phoneShown && !_run.permit)
        Positioned(
          key: const ValueKey('phone'),
          left: 10,
          top: g.panoTop + 4,
          child: const IgnorePointer(child: _PhoneChip(text: M8GateLines.phoneMsg)),
        ),
      if (_run.restored && _deal.c3)
        Positioned(
          key: const ValueKey('consumer'),
          left: 10,
          right: 10,
          top: g.panoTop + (_phoneShown && !_run.permit ? 34 : 4),
          child: const IgnorePointer(child: _CaptionChip(text: M8GateLines.consumerSays)),
        ),
      if (_note != null)
        Positioned(
          key: const ValueKey('note'),
          left: 10,
          right: 10,
          top: g.panoTop + 62,
          child: IgnorePointer(child: _NoteStrip(text: _note!)),
        ),
      Positioned.fromRect(
        key: const ValueKey('home'),
        rect: g.home,
        child: GestureDetector(
          key: const ValueKey('m8g-home'),
          behavior: HitTestBehavior.opaque,
          onTap: _tapHome,
          child: const _HomeChip(),
        ),
      ),
      // The belt.
      Positioned.fromRect(
        key: const ValueKey('belt'),
        rect: Rect.fromLTRB(0, g.beltTop, 360, g.h),
        child: const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF3A2A1A)))),
      ),
      for (final t in M8GTok.values)
        Positioned.fromRect(
          key: ValueKey('tok-${t.name}'),
          rect: g.tok(t.index),
          child: _TokenChip(
            key: ValueKey('m8g-tok-${t.name}'),
            tok: t,
            up: _lifted == t && _phase == _Phase.lifted,
            onTap: () => _tapToken(t),
            onDragStart: () {
              if (_free && _fieldScene) {
                setState(() {
                  _lifted = t;
                  _phase = _Phase.lifted;
                });
              }
            },
          ),
        ),
    ];
  }

  Widget _target(M8GGeo g, M8GTgt t, bool live) {
    final r = g.at(t, _pan).shift(Offset(0, -g.panoTop));
    return Positioned.fromRect(
      key: ValueKey('tgt-${t.key}'),
      rect: r,
      child: DragTarget<M8GTok>(
        onAcceptWithDetails: (det) => _drop(det.data, t),
        builder: (context, cand, _) => GestureDetector(
          key: ValueKey('m8g-tgt-${t.key}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _tapTgt(t),
          onLongPress: t.kind == M8GTgtKind.house ? () => _roofHold(t) : null,
          child: Semantics(
            button: true,
            label: M8GateLines.tgt(t),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // The same faint frame on every place while a token is up.
                border: live || cand.isNotEmpty ? Border.all(color: const Color(0x88F2D27A), width: cand.isNotEmpty ? 2 : 1) : null,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _hall(M8GGeo g) {
    final q = _hq < _qs.length ? _qs[_hq] : null;
    return [
      IgnorePointer(key: const ValueKey('hall-paint'), child: RepaintBoundary(child: CustomPaint(painter: M8GHearPainter(geo: g)))),
      if (q != null && _qOpen)
        Positioned.fromRect(
          key: ValueKey('ask-$_hq'),
          rect: g.ask,
          child: IgnorePointer(child: _AskBubble(who: M8GateLines.who(q.kind), text: M8GateLines.ask(q.kind))),
        ),
      Positioned.fromRect(
        key: const ValueKey('bench'),
        rect: g.bench,
        child: DragTarget<M8GRec>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (det) => _dropRec(det.data.kind == M8GRecKind.none ? null : det.data),
          builder: (context, cand, _) => GestureDetector(
            key: const ValueKey('m8g-bench'),
            behavior: HitTestBehavior.opaque,
            onTap: _tapBench,
            child: Semantics(
              button: true,
              label: M8GateLines.benchTable,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: _phase == _Phase.hearLifted || cand.isNotEmpty ? Border.all(color: const Color(0x88F2D27A), width: cand.isNotEmpty ? 2 : 1) : null,
                ),
                child: Text(M8GateLines.benchTable, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0x99F4E7C8))),
              ),
            ),
          ),
        ),
      ),
      if (_note != null)
        Positioned(
          key: const ValueKey('note'),
          left: 10,
          right: 10,
          top: g.panoTop + 80,
          child: IgnorePointer(child: _NoteStrip(text: _note!)),
        ),
      Positioned.fromRect(
        key: const ValueKey('belt'),
        rect: Rect.fromLTRB(0, g.beltTop, 360, g.h),
        child: const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF3A2A1A)))),
      ),
      Positioned.fromRect(
        key: const ValueKey('fan'),
        rect: g.fan,
        child: ListView.separated(
          key: const ValueKey('m8g-fan'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          itemCount: _fan.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: M8GGeo.cardGap),
          itemBuilder: (context, i) {
            final rec = i < _fan.length ? _fan[i] : null;
            return _RecCard(
              key: ValueKey('m8g-rec-${rec?.id ?? 'none'}'),
              rec: rec,
              up: rec == null ? _blankUp : _hLifted == rec,
              onTap: () => _tapRec(rec),
              onDragStart: () {
                if (_free && _hearScene) {
                  setState(() {
                    _hLifted = rec;
                    _blankUp = rec == null;
                    _phase = _Phase.hearLifted;
                  });
                }
              },
            );
          },
        ),
      ),
    ];
  }

  /// How to touch now, never what.
  HintSpec? _hint() {
    final g = _geo;
    if (g == null) return null;
    _hintFlip = !_hintFlip;
    if (_stage == _Stage.hearing) {
      final n = math.min(_fan.length + 1, 3);
      if (_hintFlip && n >= 2) return HintSpec.sweep(g.cards(n), space: HintSpace.scene);
      return HintSpec.drag(Offset(180, g.fan.center.dy), toward: const Offset(0, -1), travel: 60, space: HintSpace.scene);
    }
    if (_phase == _Phase.lifted) {
      // A swipe across the lane (the same on every deal).
      return HintSpec.swipe(Offset(90, g.pano.center.dy), toward: const Offset(1, 0), travel: 180, space: HintSpace.scene);
    }
    if (_hintFlip) return HintSpec.sweep(g.tokens, space: HintSpace.scene);
    return HintSpec.drag(Offset(180, g.beltTop + 70), toward: const Offset(0, -1), travel: 80, space: HintSpace.scene);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final scale = size.width / 360;
    final live = _phase != _Phase.intro && _mark == null && !struckOut && !_freeze;
    final scenePhase = _fieldScene || _hearScene;
    final consequenceQ = _stage == _Stage.hearing && _hq < _qs.length && _qs[_hq].consequence;
    final waiting = live && scenePhase && _card == null && !coworkerOnScreen && !tableBusy && !consequenceQ && (_stage == _Stage.field || _qOpen);
    final deckUp = reasonOpen || coworkerChoiceUp;
    final sheetUp = live && !deckUp && _card == null && !coworkerOnScreen && !tableBusy;
    final g = _geo;
    final beltH = g == null ? 150.0 * scale : (g.h - g.beltTop) * scale;
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
            animation: Listenable.merge([_lit, _harm]),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_stage.name}-${_stage == _Stage.field ? _run.minutes : _hq}-${_phase.name}-${_lifted?.name}',
            hintController: _hints,
            hintAutoMiss: true,
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (sheetUp && _phase == _Phase.roof)
                Positioned(
                  key: const ValueKey('sheet-roof'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(padding: EdgeInsets.only(bottom: pad.bottom), child: _RoofSheet(text: _roofText, onClose: _closeRoof)),
                ),
              if (_cutText != null)
                Positioned.fill(
                  key: const ValueKey('cut'),
                  child: IgnorePointer(child: Center(child: _CutBanner(text: _cutText!))),
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
              if (live && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 300 : (_phase == _Phase.roof) ? 160 : beltH + 4),
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
                  line: M8GateLines.intro,
                  alarm: 'sounds/learn/card_deal_a.ogg',
                  muted: _muted,
                  onDone: _start,
                ),
                Positioned(
                  key: const ValueKey('intro-docket'),
                  left: 24,
                  right: 24,
                  top: pad.top + 66,
                  child: IgnorePointer(child: _DocketCard(line: M8GateLines.docketLine(_deal.regMin), quiet: quiet)),
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

/// The docket on the van door: when the line was registered (never a deadline).
class _DocketBand extends StatelessWidget {
  const _DocketBand({required this.line});
  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFBEF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB08A4A)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.assignment_rounded, color: Color(0xFF7A1F1F), size: 13),
          const SizedBox(width: 3),
          Text(M8GateLines.docketWord, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F), height: 1.2)),
          const SizedBox(width: 5),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 80),
              child: Text(enDigits(line), maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w700, color: SlmColors.ink, height: 1.2)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The game clock (shown, never counted down).
class _ClockChip extends StatelessWidget {
  const _ClockChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1E252D),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF9AA4AE), width: 1.4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.watch_later_outlined, size: 11, color: Color(0xFFBFE3FF)),
            const SizedBox(width: 3),
            Text(enDigits(text), style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFFBFE3FF), height: 1.1)),
          ],
        ),
      ),
    );
  }
}

class _PhoneChip extends StatelessWidget {
  const _PhoneChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xE61E252D), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF7FE07A))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phone_android_rounded, size: 13, color: Color(0xFF7FE07A)),
          const SizedBox(width: 4),
          Text(text, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
        ],
      ),
    );
  }
}

/// A silent figure's words (a caption bubble, M8-10).
class _CaptionChip extends StatelessWidget {
  const _CaptionChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xE6FFF4D6), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFB08A4A))),
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.25)),
    );
  }
}

class _AskBubble extends StatelessWidget {
  const _AskBubble({required this.who, required this.text});
  final String who;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFBEF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB08A4A), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(who, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F), height: 1.1)),
          const SizedBox(height: 2),
          Flexible(child: Text(enDigits(text), maxLines: 3, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w700, color: SlmColors.ink, height: 1.25))),
        ],
      ),
    );
  }
}

class _HomeChip extends StatelessWidget {
  const _HomeChip();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M8GateLines.home,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xE61E252D),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFF9AA4AE), width: 1.2),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_shipping_rounded, size: 12, color: Color(0xFFE9E5DA)),
                const SizedBox(width: 3),
                Text(M8GateLines.home, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w900, color: const Color(0xFFE9E5DA), height: 1.1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The last raw note (what the act did).
class _NoteStrip extends StatelessWidget {
  const _NoteStrip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xE6FFFBEF), borderRadius: BorderRadius.circular(5), border: Border.all(color: const Color(0xFFB08A4A))),
      child: Text(enDigits(text), maxLines: 3, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w700, color: SlmColors.ink, height: 1.25)),
    );
  }
}

class _CutBanner extends StatelessWidget {
  const _CutBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xE6101826), borderRadius: BorderRadius.circular(14), border: Border.all(color: SlmColors.gold300, width: 1.4)),
      child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.gold200, height: 1.25)),
    );
  }
}

/// A belt token (all eleven the same size; drag it or tap it up).
class _TokenChip extends StatelessWidget {
  const _TokenChip({super.key, required this.tok, required this.up, required this.onTap, required this.onDragStart});
  final M8GTok tok;
  final bool up;
  final VoidCallback onTap;
  final VoidCallback onDragStart;

  static IconData _icon(M8GTok t) => switch (t) {
        M8GTok.permit => Icons.description_rounded,
        M8GTok.fuse => Icons.flash_off_rounded,
        M8GTok.rod => Icons.vertical_align_bottom_rounded,
        M8GTok.climb => Icons.engineering_rounded,
        M8GTok.camera => Icons.photo_camera_rounded,
        M8GTok.hook => Icons.link_off_rounded,
        M8GTok.trim => Icons.content_cut_rounded,
        M8GTok.seize => Icons.list_alt_rounded,
        M8GTok.police => Icons.local_police_rounded,
        M8GTok.report => Icons.outbox_rounded,
        M8GTok.tester => Icons.electric_bolt_rounded,
      };

  Widget _face({bool lifted = false}) => Container(
        decoration: BoxDecoration(
          color: lifted ? const Color(0xFFFFE08A) : const Color(0xFFF2B632),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: lifted ? Colors.white : const Color(0xFF7A5200), width: lifted ? 2 : 1.2),
          boxShadow: [BoxShadow(color: const Color(0x88000000), blurRadius: lifted ? 10 : 4, offset: Offset(0, lifted ? 5 : 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon(tok), size: 20, color: const Color(0xFF3A2500)),
            const SizedBox(height: 2),
            Text(
              M8GateLines.tok(tok),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: bangla(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2500), height: 1.05),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M8GateLines.tok(tok),
      child: Draggable<M8GTok>(
        data: tok,
        onDragStarted: onDragStart,
        feedback: SizedBox(width: 50, height: 62, child: Material(type: MaterialType.transparency, child: _face(lifted: true))),
        childWhenDragging: Opacity(opacity: 0.35, child: _face()),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedSlide(offset: Offset(0, up ? -0.12 : 0), duration: const Duration(milliseconds: 160), child: _face(lifted: up)),
        ),
      ),
    );
  }
}

/// One record card of the file (a long press lifts it; a tap opens it for the bench).
class _RecCard extends StatelessWidget {
  const _RecCard({super.key, required this.rec, required this.up, required this.onTap, required this.onDragStart});
  final M8GRec? rec;
  final bool up;
  final VoidCallback onTap;
  final VoidCallback onDragStart;

  String get _label => rec?.labelBn ?? M8GateLines.noRecord;

  IconData get _icon => switch (rec?.kind) {
        null || M8GRecKind.none => Icons.block_rounded,
        M8GRecKind.ptw => Icons.description_rounded,
        M8GRecKind.docket => Icons.assignment_turned_in_rounded,
        M8GRecKind.seizure => Icons.list_alt_rounded,
        M8GRecKind.police => Icons.local_police_rounded,
        _ => rec!.video ? Icons.videocam_rounded : Icons.photo_rounded,
      };

  Widget _face({bool lifted = false}) => Container(
        width: M8GGeo.cardW,
        height: M8GGeo.cardH,
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        decoration: BoxDecoration(
          color: lifted ? const Color(0xFFFFFBEF) : const Color(0xFFF4EEDC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: lifted ? const Color(0xFF1E88E5) : const Color(0xFF9C8E77), width: lifted ? 2 : 1.2),
          boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 8 : 3, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, size: 15, color: const Color(0xFF5A4636)),
            const SizedBox(height: 2),
            Expanded(
              child: Text(enDigits(_label), maxLines: 4, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF3D3022), height: 1.15)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final data = rec ?? M8GRec('none', M8GRecKind.none, M8GateLines.noRecord);
    return Semantics(
      button: true,
      label: _label,
      child: LongPressDraggable<M8GRec>(
        data: data,
        delay: const Duration(milliseconds: 180),
        onDragStarted: onDragStart,
        feedback: SizedBox(width: M8GGeo.cardW, height: M8GGeo.cardH, child: Material(type: MaterialType.transparency, child: _face(lifted: true))),
        childWhenDragging: Opacity(opacity: 0.35, child: _face()),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedSlide(offset: Offset(0, up ? -0.1 : 0), duration: const Duration(milliseconds: 160), child: _face(lifted: up)),
        ),
      ),
    );
  }
}

class _RoofSheet extends StatelessWidget {
  const _RoofSheet({required this.text, required this.onClose});
  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xF2101826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold300, width: 1.4),
      ),
      child: Row(
        children: [
          const Icon(Icons.roofing_rounded, color: SlmColors.gold200, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25))),
          GestureDetector(
            key: const ValueKey('m8g-roof-close'),
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: SlmColors.gold300, borderRadius: BorderRadius.circular(12)),
              child: Text(M8GateLines.close, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ink)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The docket on the intro: the call only (a registration time, never a deadline).
class _DocketCard extends StatelessWidget {
  const _DocketCard({required this.line, required this.quiet});
  final String line;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB08A4A), width: 1.6),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment_rounded, color: Color(0xFF7A1F1F), size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(enDigits(line), style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.25))),
          ],
        ),
      ),
    );
  }
}

/// The rank-up: সুপারভাইজার → স্পেশালিস্ট, with the module's badge.
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
            Text(M8GateLines.rankUp, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.gold200)),
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
            if (M8GateLines.badge.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(M8GateLines.badge, textAlign: TextAlign.center, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
            ],
          ],
        ),
      ),
    );
  }
}
