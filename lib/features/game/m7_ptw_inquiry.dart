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
import 'm7_ptw_inquiry_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm7_ptw_inquiry_world.dart' show M7PtwGeo, M7PtwPhoto, M7PtwRow, M7PtwShot, kM7PtwRowsPerPage, m7PtwClock, m7PtwDate, m7PtwOnPole;

// Lesson 7.4 "পারমিট-টু-ওয়ার্ক (PTW): একটি আইনি চুক্তি", কাজ 2 "বৈধ PTW ছিল
// কি?" (pack do_7_4_b, engineType m7_ptw_inquiry). An accident inquiry at the
// division office (no injury shown): three cases a play, dealt fresh. The
// lesson's first question after any accident — 'বৈধ PTW ছিল কি?' (point 1) —
// answered from the records: the formal logbook of every PTW's issue and
// cancellation time and date (pro tip 3) against the day's time-stamped site
// photos.
//
// Each case: the folder gives the job's date and feeder, and the crew's field
// copy shows its PTW number (or the sleeve is empty: 'ফিল্ড কপি পাওয়া
// যায়নি', also on some cases whose row is in the book).
//  1. Find: swipe the logbook's pages (3 rows a page; decoys: the same feeder
//     on another date, the same date on another feeder, the number's middle
//     digits swapped) and tap the matching row to clip it. A wrong row is an
//     unscored retry ('এই সারি এই পারমিটের নয়।') but it costs the case its
//     clip pay and its thorough bonus. No row for the job → hold the stamp
//     'লগবুকে নেই' (0.8 s).
//  2. Scrub the film strip (6–9 photos, phone time stamps to the minute): the
//     big photo follows the thumb. Compare with the clipped row in your head
//     — nothing on the strip marks the permit window.
//  3. Verdict: hold the big photo to pin 'এখানে PTW ছিল না' (right only when
//     someone is up the pole before the issue time or after the cancellation)
//     or hold the stamp 'সব কাজ PTW-এর মধ্যে'. A time verdict before a row
//     is clipped is a slip on every case (find the permit first; on a no-row
//     case it is the spec's 'time verdict on a no-row case').
//  ◆ on the table → "কেন …?" → এগিয়ে যান → the next case.
//
// Case kinds: work before the issue (the first man up 10–25 min early, 1–2
// photos in the gap), work after the cancellation (the same, after), no row
// and no field copy, and clean (all pole work inside the window; crew photos
// before and after with nobody up). Two of a kind can come; ~2 plays in 3
// hold a clean case.
//
// No deadly act in this level (M7-4 / M7-6: past acts judged at an inquiry
// desk are always slips; the reason and slip cards say the same act in the
// field is deadly). Slips: 'সব কাজ PTW-এর মধ্যে' on a breach; a pin on a
// photo inside the window or with nobody up the pole; 'লগবুকে নেই' when the
// row is there; a time verdict before the row is clipped; listening to the coworker (X2/B1: what he pushes is a slip
// here). Three slips strike out.
//
// The coworker (one of the crew at the table) comes once a play, on a random
// case, at the start of the first verdict hold (pin and both stamps call
// holdForCoworker): the lesson's myth 2 word for word.
//
// Gesture hands (how, never what): a swipe and a sweep over the page's rows
// while finding; a short drag nudge on the scrubber thumb toward later times
// (earlier only at the right end) and a sweep over the photo and both stamps
// once a row is clipped; a hold control the player only tapped gets a hold
// ring on itself. None during the intro, the coworker, the ◆ window, cards or
// results; decks have their own.

// ============================================================================
// Content
// ============================================================================

/// The four case kinds.
enum M7PtwCaseKind { before, after, noRow, clean }

/// Where a case stands: looking for the row, or the row clipped.
enum M7PtwStage { find, scrub }

/// The three hold controls.
enum M7PtwHold { pin, noRow, allIn }

/// What a case's reason asks about (fits what was found).
enum M7PtwWhy { beforeGap, afterGap, clean, noRow, law }

/// The verdict hold (lesson: none; the spec's ~0.8 s).
const int kM7PtwHoldMs = 800;

abstract final class M7PtwInquiryLines {
  static const title = 'বৈধ PTW ছিল কি?';
  // DRAFT wording — owner (M6-12 / M7-10).
  static const intro = 'দুর্ঘটনার তদন্ত। প্রথম প্রশ্ন — বৈধ PTW ছিল কি? রেকর্ড মিলিয়ে বলুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askFind = 'লগবুকে এই পারমিট খুঁজুন।';
  static const askFindOther = 'লগবুকের পাতা উল্টে তারিখ আর ফিডার মিলিয়ে দেখুন।';
  static const askScrub = 'ছবিগুলো সময় ধরে দেখুন, তারপর রায় দিন।';
  static const askScrubOther = 'ফিল্মটা টেনে প্রতিটা ছবির সময় সারির সঙ্গে মেলান।';
  static const nextCase = 'পরের কেস।';
  static const wrongRow = 'এই সারি এই পারমিটের নয়।';
  static const rowOk = 'সারিটা পাওয়া গেছে।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askFind, askFindOther, askScrub, askScrubOther];

  // On-screen words (a worker's own; not spoken).
  static const pin = 'এখানে PTW ছিল না';
  static const noRowStamp = 'লগবুকে নেই';
  static const allInStamp = 'সব কাজ PTW-এর মধ্যে';
  static const deskLabel = 'তদন্তের টেবিল';
  static String caseName(int n) => enDigits('কেস $n');
  static const feeders = ['বাজার', 'স্টেশন রোড', 'হাসপাতাল', 'নদীঘাট', 'কলেজ মোড়', 'মিলপাড়া'];
  static final desk = M7PtwDeskLabels(
    caseFile: 'কেস ফাইল',
    date: 'তারিখ',
    feeder: 'ফিডার',
    fieldCopy: 'ফিল্ড কপি',
    ptwNo: 'PTW নং',
    noFieldCopy: 'ফিল্ড কপি পাওয়া যায়নি',
    logbook: 'PTW লগবুক',
    columns: const ['তারিখ', 'PTW নং', 'ফিডার', 'ইস্যু', 'বাতিল'],
    page: (n, m) => enDigits('পাতা $n/$m'),
  );

  // The reasons: the right ones fit what was found; the wrong ones are the
  // lesson's myths and desk excuses.
  static const whyQ = <M7PtwWhy, String>{
    M7PtwWhy.beforeGap: 'এখানে PTW ছিল না কেন বললেন?',
    M7PtwWhy.afterGap: 'এখানে PTW ছিল না কেন বললেন?',
    M7PtwWhy.clean: 'সব বৈধ বললেন কেন?',
    M7PtwWhy.noRow: 'লগবুকে নেই — এর মানে কী?',
    M7PtwWhy.law: 'এই গাফিলতিতে আইনত কী হতে পারে?',
  };
  // M7-4: the breach cards say the same act in the field is deadly.
  static const whyRight = <M7PtwWhy, List<String>>{
    M7PtwWhy.beforeGap: ['PTW ইস্যুর আগেই পোলে লোক — মাঠে এটা প্রাণঘাতী', 'ইস্যুর সময়ের আগে লাইনে কাজ, তাই বৈধ PTW ছিল না'],
    M7PtwWhy.afterGap: ['PTW বাতিলের পরেও পোলে লোক — মাঠে এটা প্রাণঘাতী', 'বাতিলের পরে লাইনে কাজ, তখন আর PTW ছিল না'],
    M7PtwWhy.clean: ['পোলে ওঠার সব ছবি ইস্যু আর বাতিলের মাঝখানে', 'লাইনের সব কাজ লগবুকের সময়ের মধ্যেই হয়েছে'],
    M7PtwWhy.noRow: ['লগবুকে ইস্যুর রেকর্ড নেই — বৈধ PTW প্রমাণ হয় না', 'লগবুক আইনি নথি — সেখানে নেই মানে PTW ছিল না'],
    M7PtwWhy.law: ['গুরুতর গাফিলতি — ফৌজদারি মামলাও হতে পারে', 'গাফিলতি ধরা হবে — মামলা, বরখাস্ত দুই-ই হতে পারে', 'ফৌজদারি মামলা হতে পারে — মাঠে এ কাজ প্রাণঘাতী'],
  };
  static const myths = [
    'সুপারভাইজার মুখে বলে দিলেই কাগজ লাগে না',
    'PTW শুধু সুপারভাইজারের দায়, বাকিদের কিছু নয়',
    'কাজ শেষে লগবুকে লিখে নিলেই সব ঠিক হয়ে যায়',
    'দশ-পনেরো মিনিট আগে উঠলে কিছু যায় আসে না',
    'কেউ আঘাত না পেলে PTW নিয়ে প্রশ্ন ওঠে না',
    'দায় শুধু কর্তাদের, কর্মীর কিছুই হবে না',
    'ফিল্ড কপি থাকলেই লগবুক দেখার দরকার নেই',
  ];
  static List<String> get allWhyRight => <String>{for (final l in whyRight.values) ...l}.toList();

  // The careless coworker (once a play, at the first verdict hold of his
  // case): the lesson's myth 2 word for word (M7-10).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'PTW তো শুধু সুপারভাইজারের দায়িত্ব, আমার এটা নিয়ে ভাবার দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, টিমের সবার জানা উচিত কোন পারমিটে কাজ', 'না, PTW ছাড়া কাজে অংশ নিলে আমিও দায়ী', 'না, কোন পারমিটে কাজ, সবারই জানা দরকার'],
    wrong: [
      'ঠিকই, ওটা তো সুপারভাইজারের ব্যাপার',
      'আমি কিছু জানতাম না — এটুকু বললেই হবে',
      'হ্যাঁ, পারমিট দেখা তো আমার কাজ নয়',
      'ঠিক, দায় তো শুধু সুপারভাইজারের একার',
      'হ্যাঁ, ওসব তো কর্তাদের মাথাব্যথা',
    ],
    asks: ['কী করবেন?', 'ও বলছে PTW শুধু সুপারভাইজারের দায়। কী বলবেন?', 'ওর কথা মানবেন, না আইন?'],
  );
  static const callHeld = 'ঠিক! কোন পারমিটে কাজ, টিমের সবার জানার কথা।';

  static const allSet = 'তিনটে কেসই রেকর্ড মিলিয়ে বিচার করেছেন — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে লগবুকের সারি, তারপর ছবির সময়।';

  // "আজ যা ধরলেন".
  static const caughtRow = 'লগবুকে পারমিটের সারি মেলানো';
  static const caughtBefore = 'ইস্যুর আগে পোলে লোক — ধরেছেন';
  static const caughtAfter = 'বাতিলের পরে পোলে লোক — ধরেছেন';
  static const caughtNoRow = 'লগবুকে নেই মানে বৈধ PTW নেই';
  static const caughtClean = 'সব কাজ PTW-এর সময়ের মধ্যে — মিলিয়ে দেখা';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new line (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until
  /// then the device voice). Lines the kit shares are listed too, so the
  /// voice pass finds every line this level speaks; only the kit's own
  /// praise and 'wrong' bags are left out.
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        nextCase,
        wrongRow,
        rowOk,
        ...tapWhy,
        ...whyQ.values,
        ...coworker.asks,
        callHeld,
        allSet,
        quick,
        fail,
        for (final m in M7PtwInquiryMistakes.all) m.textBn,
      }.toList();
}

abstract final class M7PtwInquiryMistakes {
  static const _dir = 'assets/game/art/m7_ptw_inquiry';

  // DRAFT wording — owner (M6-12). Lesson 7.4 point 1 (index 0: the first
  // question, the PTW's legal basis) unless noted; point 3 (index 2) = the
  // consequences. M7-4: every breach card says the field act is deadly.
  static const allInBefore = DoMistake(
    key: '7.4/m7_ptw_inquiry/all-in-before',
    textBn: 'ইস্যুর সময়ের আগেই একজন পোলে উঠেছিলেন — তখন বৈধ PTW ছিল না। “সব কাজ PTW-এর মধ্যে” বলা যায় না। মাঠে এই একই কাজ প্রাণঘাতী।',
    art: '$_dir/stamp_gap.svg',
    lessonPoint: 0,
  );
  static const allInAfter = DoMistake(
    key: '7.4/m7_ptw_inquiry/all-in-after',
    textBn: 'PTW বাতিলের পরেও একজন পোলে ছিলেন — তখন আর PTW ছিল না। “সব কাজ PTW-এর মধ্যে” বলা যায় না। মাঠে এই একই কাজ প্রাণঘাতী।',
    art: '$_dir/stamp_gap.svg',
    lessonPoint: 0,
  );
  static const pinValid = DoMistake(
    key: '7.4/m7_ptw_inquiry/pin-valid',
    textBn: 'এই ছবির সময় PTW ইস্যু আর বাতিলের মাঝখানে — তখন কাজ বৈধ PTW-তেই চলছিল। ছবির সময় লগবুকের সারির সঙ্গে মিলিয়ে দেখুন।',
    art: '$_dir/pin_valid.svg',
    lessonPoint: 0,
  );
  static const pinNobody = DoMistake(
    key: '7.4/m7_ptw_inquiry/pin-nobody',
    textBn: 'এই ছবিতে পোলে বা লাইনে কেউ নেই — এটা PTW ভাঙার প্রমাণ নয়। কেউ পোলে আছেন, এমন ছবির সময় দেখুন।',
    art: '$_dir/pin_nobody.svg',
    lessonPoint: 0,
  );
  static const rowExists = DoMistake(
    key: '7.4/m7_ptw_inquiry/row-exists',
    textBn: 'লগবুকে এই পারমিটের সারি আছে। পাতা উল্টে তারিখ, ফিডার আর PTW নং মিলিয়ে দেখুন — লগবুক একটি আইনি নথি।',
    art: '$_dir/row_exists.svg',
    lessonPoint: 0,
  );
  // A pin or 'সব কাজ PTW-এর মধ্যে' before the row is clipped (every case
  // alike, so a hold before the clip tells nothing about the row).
  static const timeFirst = DoMistake(
    key: '7.4/m7_ptw_inquiry/time-before-row',
    textBn: 'ছবির সময় মেলানোর আগে লগবুকে দেখুন বৈধ PTW আদৌ ছিল কি না — আগে পারমিটের সারি, তারপর ছবির সময়।',
    art: '$_dir/time_first.svg',
    lessonPoint: 0,
  );
  static const listened = DoMistake(
    key: '7.4/m7_ptw_inquiry/listened',
    textBn: 'PTW শুধু সুপারভাইজারের দায় নয়। টিমের প্রত্যেকের জানা উচিত কোন পারমিটে কাজ চলছে; বৈধ PTW ছাড়া কাজে অংশ নিলে আপনিও সমান দায়ী।',
    art: '$_dir/listen.svg',
    lessonPoint: 2,
  );

  static const List<DoMistake> all = [allInBefore, allInAfter, pinValid, pinNobody, rowExists, timeFirst, listened];
}

/// One inquiry case.
@immutable
class M7PtwCase {
  const M7PtwCase({
    required this.kind,
    required this.day,
    required this.month,
    required this.feeder,
    required this.ptwNo,
    required this.fieldCopy,
    required this.rows,
    required this.matchId,
    required this.issue,
    required this.cancel,
    required this.photos,
    this.gap = 0,
  });

  final M7PtwCaseKind kind;

  /// The job's date and feeder (the folder).
  final int day;
  final int month;
  final int feeder;

  /// The job's PTW number (on the field copy, if found; on the row, if any).
  final int ptwNo;

  /// The crew's field copy is in the folder.
  final bool fieldCopy;

  /// The logbook, in its written order.
  final List<M7PtwRow> rows;

  /// The job's row, or null (no row for the job).
  final int? matchId;

  /// The permit's window (minutes after midnight; the row's times).
  final int issue;
  final int cancel;

  /// The day's site photos, by time.
  final List<M7PtwPhoto> photos;

  /// A breach: how early (before) or late (after) the first/last man was up.
  final int gap;

  int? get fieldCopyNo => fieldCopy ? ptwNo : null;
  bool get breach => kind == M7PtwCaseKind.before || kind == M7PtwCaseKind.after;
  int get pages => (rows.length / kM7PtwRowsPerPage).ceil();
  List<M7PtwRow> page(int p) => rows.skip(p * kM7PtwRowsPerPage).take(kM7PtwRowsPerPage).toList();
  M7PtwRow? get match => matchId == null ? null : rows.firstWhere((r) => r.id == matchId);

  /// The page the job's row is on (null: no row).
  int? get matchPage {
    final id = matchId;
    if (id == null) return null;
    return rows.indexWhere((r) => r.id == id) ~/ kM7PtwRowsPerPage;
  }

  /// A photo showing someone up the pole outside the permit window.
  bool outside(M7PtwPhoto p) => p.onPole && (p.minute < issue || p.minute > cancel);
}

@immutable
class M7PtwDeal {
  const M7PtwDeal({required this.cases, required this.coworkerCase, required this.why});

  final List<M7PtwCase> cases;

  /// The case the coworker comes in on.
  final int coworkerCase;

  /// What each case's reason asks about.
  final List<M7PtwWhy> why;
}

M7PtwCaseKind _kindOf(math.Random rng) {
  final n = rng.nextInt(20);
  if (n < 6) return M7PtwCaseKind.clean;
  if (n < 11) return M7PtwCaseKind.before;
  if (n < 16) return M7PtwCaseKind.after;
  return M7PtwCaseKind.noRow;
}

/// A 4-digit PTW number whose middle digits differ (so a swapped copy is
/// another number).
int _ptwNo(math.Random rng) {
  while (true) {
    final n = 1000 + rng.nextInt(9000);
    final d = n.toString();
    if (d[1] != d[2]) return n;
  }
}

int _swapMiddle(int n) {
  final d = n.toString().split('');
  final t = d[1];
  d[1] = d[2];
  d[2] = t;
  return int.parse(d.join());
}

List<M7PtwPhoto> _photos(M7PtwCaseKind kind, int issue, int cancel, int g, int variant, math.Random rng) {
  final n = 6 + rng.nextInt(4);
  final gapN = kind == M7PtwCaseKind.before || kind == M7PtwCaseKind.after ? 1 + rng.nextInt(2) : 0;
  final rest = n - gapN;
  var pre = 1 + rng.nextInt(2);
  var post = 1 + rng.nextInt(2);
  if (rest - pre - post < 2) {
    pre = 1;
    post = 1;
  }
  final inside = rest - pre - post;
  final used = <int>{};
  final out = <M7PtwPhoto>[];
  int pick(int lo, int hi) {
    for (var k = 0; k < 400; k++) {
      final m = lo + rng.nextInt(math.max(1, hi - lo + 1));
      if (used.add(m)) return m;
    }
    throw StateError('no free minute in $lo..$hi');
  }

  void add(int m, M7PtwShot s) => out.add(M7PtwPhoto(minute: m, shot: s, variant: variant));
  M7PtwShot pole() => rng.nextBool() ? M7PtwShot.up : M7PtwShot.climb;
  // Before the window: the crew arrives (nobody up).
  final preHi = kind == M7PtwCaseKind.before ? issue - g - 3 : issue - 3;
  for (var i = 0; i < pre; i++) {
    add(pick(preHi - 45, preHi), i == 0 ? M7PtwShot.arrive : M7PtwShot.ground);
  }
  if (kind == M7PtwCaseKind.before) {
    used.add(issue - g);
    add(issue - g, pole());
    if (gapN == 2) add(pick(issue - g + 1, issue - 1), pole());
  }
  // Inside the window: at least two with someone up (anywhere, even near
  // the edges), the rest on the ground.
  final ups = 2 + (inside > 2 ? rng.nextInt(inside - 1) : 0);
  final kinds = [for (var i = 0; i < inside; i++) i < ups ? pole() : M7PtwShot.ground]..shuffle(rng);
  for (final s in kinds) {
    add(pick(issue + 2, cancel - 2), s);
  }
  if (kind == M7PtwCaseKind.after) {
    used.add(cancel + g);
    add(cancel + g, pole());
    if (gapN == 2) add(pick(cancel + 1, cancel + g - 1), pole());
  }
  // After the window: packing up (nobody up).
  final postLo = kind == M7PtwCaseKind.after ? cancel + g + 3 : cancel + 3;
  for (var i = 0; i < post; i++) {
    add(pick(postLo, postLo + 45), i == post - 1 ? M7PtwShot.pack : M7PtwShot.ground);
  }
  out.sort((a, b) => a.minute.compareTo(b.minute));
  return out;
}

M7PtwCase _case(M7PtwCaseKind kind, math.Random rng, {required Set<int> usedDates}) {
  int day, month;
  do {
    day = 5 + rng.nextInt(20);
    month = 1 + rng.nextInt(12);
  } while (!usedDates.add(month * 32 + day));
  final feeder = rng.nextInt(M7PtwInquiryLines.feeders.length);
  final ptw = _ptwNo(rng);
  final issue = 9 * 60 + rng.nextInt(150);
  final cancel = issue + 75 + rng.nextInt(90);
  final g = 10 + rng.nextInt(16);
  final variant = rng.nextInt(3);
  final fieldCopy = kind != M7PtwCaseKind.noRow && rng.nextInt(4) != 0;
  final photos = _photos(kind, issue, cancel, g, variant, rng);
  // The logbook: 3–4 pages around the job's date.
  final total = (3 + rng.nextInt(2)) * kM7PtwRowsPerPage;
  final ids = [for (var i = 0; i < total; i++) i]..shuffle(rng);
  var next = 0;
  final rows = <M7PtwRow>[];
  final numbers = <int>{ptw};
  int freshNo() {
    while (true) {
      final n = _ptwNo(rng);
      if (numbers.add(n)) return n;
    }
  }

  int otherFeeder() => (feeder + 1 + rng.nextInt(M7PtwInquiryLines.feeders.length - 1)) % M7PtwInquiryLines.feeders.length;
  int otherDay() {
    final d = day + (rng.nextBool() ? 1 : -1) * (1 + rng.nextInt(3));
    return d == day ? day + 1 : d;
  }

  M7PtwRow row({required int d, required int f, required int no}) {
    final iss = 8 * 60 + 30 + rng.nextInt(200);
    return M7PtwRow(id: ids[next++], day: d, month: month, ptwNo: no, feeder: f, issue: iss, cancel: iss + 60 + rng.nextInt(120));
  }

  int? matchId;
  if (kind != M7PtwCaseKind.noRow) {
    final m = M7PtwRow(id: ids[next++], day: day, month: month, ptwNo: ptw, feeder: feeder, issue: issue, cancel: cancel);
    matchId = m.id;
    rows.add(m);
  }
  // The decoys.
  final swapped = _swapMiddle(ptw);
  numbers.add(swapped);
  rows.add(row(d: otherDay(), f: feeder, no: rng.nextBool() ? swapped : freshNo()));
  rows.add(row(d: day, f: otherFeeder(), no: freshNo()));
  if (!rows.any((r) => r.ptwNo == swapped)) rows.add(row(d: otherDay(), f: otherFeeder(), no: swapped));
  rows.add(row(d: otherDay(), f: feeder, no: freshNo()));
  while (rows.length < total) {
    final d = day + rng.nextInt(9) - 4;
    var f = rng.nextInt(M7PtwInquiryLines.feeders.length);
    if (d == day && f == feeder) f = otherFeeder();
    rows.add(row(d: d, f: f, no: freshNo()));
  }
  rows.sort((a, b) => a.order.compareTo(b.order));
  return M7PtwCase(
    kind: kind,
    day: day,
    month: month,
    feeder: feeder,
    ptwNo: ptw,
    fieldCopy: fieldCopy,
    rows: rows,
    matchId: matchId,
    issue: issue,
    cancel: cancel,
    photos: photos,
    gap: kind == M7PtwCaseKind.before || kind == M7PtwCaseKind.after ? g : 0,
  );
}

M7PtwDeal m7PtwDeal(math.Random rng) {
  List<M7PtwCaseKind> kinds;
  do {
    kinds = [for (var i = 0; i < 3; i++) _kindOf(rng)];
  } while (kinds.toSet().length == 1);
  final dates = <int>{};
  final cases = [for (final k in kinds) _case(k, rng, usedDates: dates)];
  final why = [
    for (final c in cases)
      switch (c.kind) {
        M7PtwCaseKind.before => rng.nextInt(3) == 0 ? M7PtwWhy.law : M7PtwWhy.beforeGap,
        M7PtwCaseKind.after => rng.nextInt(3) == 0 ? M7PtwWhy.law : M7PtwWhy.afterGap,
        M7PtwCaseKind.noRow => rng.nextInt(3) == 0 ? M7PtwWhy.law : M7PtwWhy.noRow,
        M7PtwCaseKind.clean => M7PtwWhy.clean,
      },
  ];
  return M7PtwDeal(cases: cases, coworkerCase: rng.nextInt(3), why: why);
}

/// The play state (pure logic).
class M7PtwRun {
  M7PtwRun(this.deal) {
    _startCase();
  }
  final M7PtwDeal deal;

  int index = 0;
  int slips = 0;
  int caseSlips = 0;

  /// Rows tapped this case that were not the job's (no slip, but the case
  /// loses its clip pay and its thorough bonus: no free search).
  int wrongRows = 0;
  final List<String> caught = [];

  /// The case's verdict is in (its reason comes next).
  var roundDone = false;
  var stage = M7PtwStage.find;

  /// The clipped row's id.
  int? clipped;

  /// The photo on the board.
  int photo = 0;

  int get count => deal.cases.length;
  M7PtwCase get kase => deal.cases[index.clamp(0, count - 1)];
  bool get done => index >= count;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => caseSlips == 0 && wrongRows == 0;

  /// The pay for clipping the job's row (none after a wrong row).
  int get clipPay => wrongRows == 0 ? 5 : 0;
  bool get _open => !done && !roundDone;
  M7PtwPhoto get shown => kase.photos[photo.clamp(0, kase.photos.length - 1)];

  void _startCase() {
    stage = M7PtwStage.find;
    roundDone = false;
    caseSlips = 0;
    wrongRows = 0;
    clipped = null;
    photo = 0;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    caseSlips++;
    return m;
  }

  /// A row tapped: the job's row is clipped (true); any other row is a
  /// retry with no slip (false) that costs the case its clip pay and its
  /// thorough bonus.
  bool clip(int id) {
    if (!_open || stage != M7PtwStage.find) return false;
    if (id != kase.matchId) {
      wrongRows++;
      return false;
    }
    clipped = id;
    stage = M7PtwStage.scrub;
    _tag(M7PtwInquiryLines.caughtRow);
    return true;
  }

  /// The film strip: the photo on the board.
  bool pick(int i) {
    if (done) return false;
    final n = i.clamp(0, kase.photos.length - 1);
    if (n == photo) return false;
    photo = n;
    return true;
  }

  /// 'লগবুকে নেই' held.
  DoMistake? noRow() {
    if (!_open) return null;
    if (kase.matchId != null) return _slip(M7PtwInquiryMistakes.rowExists);
    _tag(M7PtwInquiryLines.caughtNoRow);
    roundDone = true;
    return null;
  }

  /// 'সব কাজ PTW-এর মধ্যে' held. Before the row is clipped: a slip.
  DoMistake? allIn() {
    if (!_open) return null;
    if (stage == M7PtwStage.find) return _slip(M7PtwInquiryMistakes.timeFirst);
    switch (kase.kind) {
      case M7PtwCaseKind.before:
        return _slip(M7PtwInquiryMistakes.allInBefore);
      case M7PtwCaseKind.after:
        return _slip(M7PtwInquiryMistakes.allInAfter);
      case M7PtwCaseKind.clean || M7PtwCaseKind.noRow:
        _tag(M7PtwInquiryLines.caughtClean);
        roundDone = true;
        return null;
    }
  }

  /// The photo on the board pinned: 'এখানে PTW ছিল না'. Before the row is
  /// clipped: a slip.
  DoMistake? pin() {
    if (!_open) return null;
    if (stage == M7PtwStage.find) return _slip(M7PtwInquiryMistakes.timeFirst);
    final p = shown;
    if (!p.onPole) return _slip(M7PtwInquiryMistakes.pinNobody);
    if (!kase.outside(p)) return _slip(M7PtwInquiryMistakes.pinValid);
    _tag(p.minute < kase.issue ? M7PtwInquiryLines.caughtBefore : M7PtwInquiryLines.caughtAfter);
    roundDone = true;
    return null;
  }

  /// Listened to the coworker (a slip).
  DoMistake pushSlip(DoMistake m) => _slip(m);

  void next() {
    index++;
    if (!done) _startCase();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a case: a page or two swiped + the row tapped ≈ 4500, the strip
///     scrubbed over 6–9 photos ≈ 5000, the verdict hold ≈ 2000,
///     the reason ≈ 8200                                     ≈ 19700
///   three cases ≈ 59100 + the coworker ≈ 9600              ≈ 68700
///   85 % ≈ 58400 → 60 s (a builder's estimate; owner may tune, M7-13).
const m7PtwInquiryQuickMs = 60000;

@immutable
class M7PtwInquiryPack {
  const M7PtwInquiryPack({required this.id, required this.titleBn, this.quickMs = m7PtwInquiryQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7PtwInquiryPack> m7PtwInquiryPacks = {
  'do_7_4_b': M7PtwInquiryPack(id: 'do_7_4_b', titleBn: M7PtwInquiryLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7PtwInquiryProbe {
  static M7PtwRun? run;
  static int page = 0;
}

// ============================================================================
// Page
// ============================================================================

class M7PtwInquiryPage extends StatefulWidget {
  const M7PtwInquiryPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7PtwInquiryPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7PtwInquiryPage> createState() => _M7PtwInquiryPageState();
}

class _M7PtwInquiryPageState extends State<M7PtwInquiryPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _InquiryRunPage(
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

class _InquiryRunPage extends ConsumerStatefulWidget {
  const _InquiryRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7PtwInquiryPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_InquiryRunPage> createState() => _InquiryRunPageState();
}

class _InquiryRunPageState extends ConsumerState<_InquiryRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7PtwRun _run;
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

  /// The logbook page on view, a row just tapped that was not the job's.
  int _page = 0;
  int? _wrongRow;

  /// A drag in hand: the strip's scrubber, or a page swipe.
  var _scrubbing = false;
  double? _swipeFrom;
  double _swipeDx = 0;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _photoKey = GlobalKey();
  final _noRowKey = GlobalKey();
  final _allInKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M7PtwHold? _tapped;
  M7PtwGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7PtwRun(m7PtwDeal(widget.rng));
    M7PtwInquiryProbe.run = _run;
    M7PtwInquiryProbe.page = 0;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M7PtwInquiryProbe.run, _run)) M7PtwInquiryProbe.run = null;
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

  M7PtwCase get _case => _run.kase;
  M7PtwStage get _stage => _run.stage;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone;

  String get _task => _stage == M7PtwStage.find ? M7PtwInquiryLines.askFind : M7PtwInquiryLines.askScrub;

  Future<void> _start() async {
    _clock.start();
    _startCase();
  }

  void _startCase() {
    setState(() {
      _setPage(0);
      _wrongRow = null;
      _tapped = null;
      _scrubbing = false;
      _swipeFrom = null;
    });
    if (_run.index == _run.deal.coworkerCase && !coworkerDone) scheduleCoworker();
    unawaited(_sayChain([if (_run.index > 0) M7PtwInquiryLines.nextCase, _task]));
  }

  void _setPage(int p) {
    _page = p;
    M7PtwInquiryProbe.page = p;
  }

  void _stepDone() {
    _steps++;
    setState(() {});
  }

  // --- the logbook -----------------------------------------------------------
  void _tapRow(int i, Offset global) {
    final rows = _case.page(_page);
    if (i >= rows.length || _stage != M7PtwStage.find) {
      _hints.missTap();
      return;
    }
    final r = rows[i];
    if (_run.clip(r.id)) {
      _tick('sounds/learn/tag_slap.ogg', 0.6);
      setState(() {
        _wrongRow = null;
        _tapped = null;
      });
      _stepDone();
      unawaited(_levelDelta(_run.clipPay, global, mood: GuideMood.glad));
      unawaited(_sayChain([M7PtwInquiryLines.rowOk, _task], mood: GuideMood.glad));
      return;
    }
    // Not this permit's row: no slip, but the case's clip pay and thorough
    // bonus are gone (M7PtwRun.wrongRows).
    _tick('sounds/intro/click.ogg', 0.4);
    setState(() => _wrongRow = r.id);
    unawaited(_sayChain([M7PtwInquiryLines.wrongRow]));
  }

  void _turnPage(int d) {
    final n = (_page + d).clamp(0, _case.pages - 1);
    if (n == _page) return;
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.4);
    setState(() {
      _setPage(n);
      _wrongRow = null;
    });
    _stepDone();
  }

  // --- the strip ---------------------------------------------------------------
  void _scrubTo(double x, M7PtwGeo geo) {
    if (_run.pick(geo.photoAt(x, _case.photos.length))) {
      _cue('sounds/intro/tick.ogg', volume: 0.25);
      setState(() {});
    }
  }

  void _tapScene(Offset p, M7PtwGeo geo, Offset global) {
    if (!_canPlay) return;
    if (geo.stripHit.contains(p)) {
      _scrubTo(p.dx, geo);
      _stepDone();
      return;
    }
    if (geo.book.contains(p)) {
      for (var i = 0; i < kM7PtwRowsPerPage; i++) {
        if (geo.row(i).contains(p)) {
          _tapRow(i, global);
          return;
        }
      }
    }
    _hints.missTap();
  }

  void _panStart(Offset p, M7PtwGeo geo) {
    _scrubbing = false;
    _swipeFrom = null;
    if (!_canPlay) return;
    if (geo.stripHit.contains(p)) {
      _scrubbing = true;
      _scrubTo(p.dx, geo);
      return;
    }
    if (geo.book.contains(p)) {
      _swipeFrom = p.dx;
      _swipeDx = 0;
    }
  }

  void _panUpdate(Offset p, M7PtwGeo geo) {
    if (_scrubbing) {
      if (!_canPlay) {
        _scrubbing = false;
        return;
      }
      _scrubTo(p.dx, geo);
      return;
    }
    final from = _swipeFrom;
    if (from != null) _swipeDx = p.dx - from;
  }

  void _panEnd() {
    if (_scrubbing) {
      _scrubbing = false;
      _stepDone();
      return;
    }
    if (_swipeFrom == null) return;
    _swipeFrom = null;
    if (!_canPlay) return;
    // The clipped row's page stays open.
    if (_stage != M7PtwStage.find) return;
    if (_swipeDx < -30) _turnPage(1);
    if (_swipeDx > 30) _turnPage(-1);
  }

  // --- the verdict holds -------------------------------------------------------
  /// A hold starts: false = it does nothing (the coworker cuts in now).
  bool _holdStart(M7PtwHold h) {
    if (!_canPlay) return false;
    if (_run.index == _run.deal.coworkerCase && holdForCoworker()) return false;
    return true;
  }

  void _holdEarly(M7PtwHold h) {
    if (!_canPlay) return;
    setState(() => _tapped = h);
    _hints.missTap();
  }

  void _holdDone(M7PtwHold h, Offset at) {
    if (!_canPlay) return;
    setState(() => _tapped = null);
    final DoMistake? m = switch (h) {
      M7PtwHold.noRow => _run.noRow(),
      M7PtwHold.allIn => _run.allIn(),
      M7PtwHold.pin => _run.pin(),
    };
    if (m != null) {
      _stepDone();
      unawaited(_mistake(m, at));
      return;
    }
    if (!_run.roundDone) return;
    _tick('sounds/learn/tag_slap.ogg', 0.7);
    _stepDone();
    unawaited(_caseDone());
  }

  Future<void> _caseDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _run.deal.why[_run.index];
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M7PtwInquiryLines.whyRight[topic]!, M7PtwInquiryLines.myths, widget.rng),
      question: M7PtwInquiryLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startCase();
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
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7PtwInquiryLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;

  /// He comes only when a verdict hold calls him (holdForCoworker); his own
  /// timer just keeps waiting.
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.index != _run.deal.coworkerCase || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy) return false;
    return coworkerHeld;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      const m = M7PtwInquiryMistakes.listened;
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M7PtwInquiryLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7PtwInquiryLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7PtwInquiryLines.tapWhy[_nudgeN++ % M7PtwInquiryLines.tapWhy.length]
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
      _tapped = null;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7ptw/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same case goes on from where it was.
    _hush();
    setState(() => _card = null);
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
    await _say(!_run.passed ? M7PtwInquiryLines.fail : (_quickBonus ? M7PtwInquiryLines.quick : M7PtwInquiryLines.allSet),
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
  M7PtwDesk get _desk {
    final c = _case;
    return M7PtwDesk(
      caseLabel: M7PtwInquiryLines.caseName(math.min(_run.index, _run.count - 1) + 1),
      dateLabel: m7PtwDate(c.day, c.month),
      feederLabel: M7PtwInquiryLines.feeders[c.feeder],
      fieldCopyNo: c.fieldCopyNo,
      photos: c.photos,
      photoIndex: _run.photo,
      rows: c.page(_page),
      feederNames: M7PtwInquiryLines.feeders,
      page: _page,
      pages: c.pages,
      clipped: _run.clipped,
      wrongRow: _wrongRow,
      labels: M7PtwInquiryLines.desk,
    );
  }

  GlobalKey _holdKey(M7PtwHold h) => switch (h) {
        M7PtwHold.pin => _photoKey,
        M7PtwHold.noRow => _noRowKey,
        M7PtwHold.allIn => _allInKey,
      };

  /// The gesture hand: how to touch, never what (see the header comment).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final tapped = _tapped;
    if (tapped != null) return HintSpec.holdOn(_holdKey(tapped));
    final n = _hintN++;
    if (_stage == M7PtwStage.find) {
      if (n.isEven) return HintSpec.swipe(Offset(geo.book.right - 70, geo.book.center.dy), toward: const Offset(-1, 0), travel: 90, space: HintSpace.scene);
      final rows = _case.page(_page).length;
      return HintSpec.sweep([for (var i = 0; i < rows; i++) geo.row(i)], space: HintSpace.scene);
    }
    if (n.isEven) {
      final count = _case.photos.length;
      final at = geo.knob(_run.photo, count);
      final later = _run.photo < count - 1;
      return HintSpec.drag(at, toward: Offset(later ? 1 : -1, 0), travel: 56, space: HintSpace.scene);
    }
    return HintSpec.sweepOver([_photoKey, _noRowKey, _allInKey]);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7PtwGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    return [
      Positioned.fill(
        key: const ValueKey('desk'),
        child: RepaintBoundary(child: CustomPaint(painter: M7PtwDeskPainter(geo: geo, desk: _desk))),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7PtwInquiryLines.deskLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: () {
              _scrubbing = false;
              _swipeFrom = null;
            },
          ),
        ),
      ),
      // The big photo: held = the pin 'এখানে PTW ছিল না'.
      Positioned.fromRect(
        key: const ValueKey('photo-pin'),
        rect: geo.photo,
        child: _HoldPad(
          key: _photoKey,
          label: M7PtwInquiryLines.pin,
          ms: kM7PtwHoldMs,
          onStart: () => _holdStart(M7PtwHold.pin),
          onDone: (g) => _holdDone(M7PtwHold.pin, g),
          onEarly: () => _holdEarly(M7PtwHold.pin),
          child: const Align(
            alignment: Alignment.topRight,
            child: Padding(padding: EdgeInsets.all(6), child: _StampFace(label: M7PtwInquiryLines.pin, icon: Icons.push_pin_rounded, small: true)),
          ),
        ),
      ),
      // The next case: a short fade.
      if (!_intro)
        Positioned.fill(
          key: ValueKey('case-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.5, end: 0),
              duration: const Duration(milliseconds: 420),
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
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.roundDone;
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
              labels: [for (var i = 0; i < _run.count; i++) M7PtwInquiryLines.caseName(i + 1)],
              done: {for (var i = 0; i < math.min(_run.index, _run.count); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy,
            hintKey: '${_run.index}/$_steps/${_stage.name}/${_tapped?.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              // The two stamps (equal weight with the pin): bottom left, clear
              // of the guide.
              if (playing && !deckUp)
                Positioned(
                  key: const ValueKey('stamps'),
                  left: 8,
                  bottom: pad.bottom + 14,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 112,
                        height: 60,
                        child: _HoldPad(
                          key: _noRowKey,
                          label: M7PtwInquiryLines.noRowStamp,
                          ms: kM7PtwHoldMs,
                          onStart: () => _holdStart(M7PtwHold.noRow),
                          onDone: (g) => _holdDone(M7PtwHold.noRow, g),
                          onEarly: () => _holdEarly(M7PtwHold.noRow),
                          child: const _StampFace(label: M7PtwInquiryLines.noRowStamp, icon: Icons.menu_book_rounded),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 112,
                        height: 60,
                        child: _HoldPad(
                          key: _allInKey,
                          label: M7PtwInquiryLines.allInStamp,
                          ms: kM7PtwHoldMs,
                          onStart: () => _holdStart(M7PtwHold.allIn),
                          onDone: (g) => _holdDone(M7PtwHold.allIn, g),
                          onEarly: () => _holdEarly(M7PtwHold.allIn),
                          child: const _StampFace(label: M7PtwInquiryLines.allInStamp, icon: Icons.verified_rounded),
                        ),
                      ),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 6), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
                  line: M7PtwInquiryLines.intro,
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

/// A press-and-hold control: a ring fills while held; [onDone] when full,
/// [onEarly] when let go before. [onStart] false = the press does nothing.
/// Draws nothing while not held (idle = no frames).
class _HoldPad extends StatefulWidget {
  const _HoldPad({super.key, required this.label, required this.ms, required this.onStart, required this.onDone, required this.onEarly, required this.child});
  final String label;
  final int ms;
  final bool Function() onStart;
  final ValueChanged<Offset> onDone;
  final VoidCallback onEarly;
  final Widget child;

  @override
  State<_HoldPad> createState() => _HoldPadState();
}

class _HoldPadState extends State<_HoldPad> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && _down) {
        _fired = true;
        widget.onDone(_at);
      }
    });
  var _fired = false;
  var _down = false;
  Offset _at = Offset.zero;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _press(PointerDownEvent e) {
    if (_down || !widget.onStart()) return;
    _down = true;
    _fired = false;
    _at = e.position;
    HapticFeedback.selectionClick();
    unawaited(_c.forward(from: 0));
  }

  void _release() {
    if (!_down || !mounted) return;
    _down = false;
    if (!_fired) {
      _c.stop();
      _c.value = 0;
      widget.onEarly();
    } else {
      _c.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _press,
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: CustomPaint(foregroundPainter: _RingPainter(_c), child: SizedBox.expand(child: widget.child)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v) : super(repaint: v);
  final Animation<double> v;

  @override
  void paint(Canvas canvas, Size size) {
    final t = v.value;
    if (t <= 0) return;
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 3;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0x77FFFFFF));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * t, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = SlmColors.gold300);
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

/// A rubber stamp's face (the pin and both stamps look alike).
class _StampFace extends StatelessWidget {
  const _StampFace({required this.label, required this.icon, this.small = false});
  final String label;
  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: small ? 30 : 56, maxWidth: small ? 150 : 112),
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 6, vertical: small ? 4 : 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 14 : 16, color: SlmColors.gold300),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: bangla(fontSize: small ? 11.5 : 12.5, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}
