import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_duty_logbook_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm8_duty_logbook_world.dart' show M8Col, M8Crew, M8Geo, M8PageGeo, kM8ReadZones;

// Lesson 8.10 "রেগুলেশন এবং আপনি: ফিল্ডে প্রয়োগ", কাজ 1 (pack do_8_10_a,
// engineType m8_duty_logbook). One village lane, mid-morning to afternoon;
// the player is today's trainee and keeps the duty logbook.
//
// The core verb is the logbook itself: STAMP THE RUNNING CLOCK INTO IT. The
// dash clock is dragged into a column of the logbook and writes the time it
// shows then; each column keeps only its last stamp. Nothing marks a moment as
// log-worthy and nothing is judged until the player signs.
//
//  1. Field: tap the van (drive to the substation gate for the written permit;
//     a camera pan, a hand passes the permit with its carbon copy, back to the
//     pole) → ◆ → "ফোনে লাইন OFF শুনেও কেন পোলে উঠলেন না?". Tapping the pole
//     before the permit is in hand = deadly (grey freeze, arc, fall). After a
//     dealt delay the phone lights 'লাইন OFF — শুরু করুন'. Coworker variant A
//     (on the first van or pole touch after the phone lit; listening = the
//     deadly climb); if the permit came first he is variant B instead.
//  2. Drag the carbon copy to keep it: the PTW book (right) or a door pocket /
//     toolbox / dashboard (shuffled): elsewhere = slip and the copy is greased
//     (it cannot correct the log later). → ◆ → "কার্বন কপিটা কেন…".
//  3. Tap the pole: the crew's time-lapse (tester live-dead-live, earths, the
//     climb — shown, not scored, M8-17). One dealt public moment pauses it: an
//     angry consumer (reply deck) or a man offering a note and a hook coil or
//     a bypass (flick the note back). Old parts drop into the scrap crate.
//  4. Crew down, earth off, the phone call 'লাইন ক্লিয়ার', tools packed, van
//     ready (plays itself; the player may stamp শাটডাউন ছাড়া in it).
//  5. At the tailgate the page fills the screen: কী কাজ from the crate or the
//     docket card, correction (tap a time to clear; শাটডাউন নেওয়া refilled
//     from the carbon copy if it was kept in the book), read down the page with
//     a finger (a pass must cover every line), hold the সই box. Judged at the
//     sign: before two full passes, a wrong or blank time (±5 game-min of the
//     permit time / the line-clear call), a job missing — at most 2 slips from
//     the sign itself (M8-13). All right → ◆ → "সই করার আগে কেন দুবার পড়লেন?".
//
// The clock is event-driven (it moves with the story: the drive, the work, the
// call), so an idle screen draws nothing. Deadly (module 8 table R1, M8-1):
// climbing on the phone's word before the written permit — by tapping the pole
// or by listening to variant A. Slips: carbon copy not in the book; a rude or
// careless reply; taking the note / touching the coil or meter; signing before
// two read passes; a wrong time; a missing job; listening to variant B (B1).
// Three slips strike out. Gesture hands: a sweep over the pole, the van, the
// phone and the clock; a straight-up nudge on the copy in hand and on the note;
// at the page a sweep over the rows, the কী কাজ column, the crate, the copy and
// the সই box (never a swipe down the page, never a hold on সই) — never the
// answer.

// ============================================================================
// Content
// ============================================================================

/// The jobs a crew may do (the logbook's কী কাজ).
enum M8Job { fuse, jumper, insulator }

/// Where the carbon copy can be put (their slots on screen are dealt).
enum M8Place { book, doorPocket, toolbox, dash }

/// The public moment in the time-lapse.
enum M8Moment { angry, note }

/// What the man offers a note for.
enum M8NoteKind { coil, meter }

/// Where the play is.
enum M8Phase { field, driving, window, returned, copy, ready, lapse, moment, down, tailgate, signed }

/// Which reason a ◆ asks.
enum M8Why { permit, copy, angry, note, sign }

/// The coworker's two pushes (one a play).
enum M8Push { phone, noRead }

/// At most this many slips come from the sign itself (M8-13).
const kM8SignCap = 2;

/// A stamped time counts within this many game minutes (M8-12).
const kM8Tolerance = 5;

/// Read passes before the sign.
const kM8Passes = 2;

abstract final class M8DutyLogbookLines {
  static const title = 'ডিউটির খাতা — লেখা নেই, প্রমাণ নেই';
  // DRAFT wording — owner (M6-12 / M8-14).
  static const intro = 'লেখা নেই মানে প্রমাণ নেই! আজকের ডিউটি নিজের হাতে খাতায় তুলুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askField = 'আজকের কাজ শুরু করুন। সব যেন খাতায় থাকে।';
  static const askPhone = 'ফোন এসেছে। এবার আপনার পালা।';
  static const askCopy = 'কার্বন কপিটা কোথায় রাখবেন?';
  static const askReady = 'পারমিট হাতে। এবার কাজ শুরু হোক।';
  static const askWait = 'কাজ চলছে। খাতা আপনার হাতে।';
  static const askReply = 'গ্রাহকের কথার কী জবাব দেবেন?';
  static const askNote = 'লোকটার হাতের নোটটা — কী করবেন?';
  static const askPage = 'এবার খাতা পূরণ করে সই করুন।';
  static List<String> get tasks => [askField, askPhone, askCopy, askReady, askWait, askReply, askNote, askPage];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // What the figures say (silent caption bubbles, M8-10; not spoken).
  // DRAFT wording — owner.
  static const clerkHands = 'এই নিন, পারমিট — সঙ্গে কার্বন কপি।';
  static const angrySays = 'কারেন্ট নেই কেন? আর কত বসে থাকব?';
  static const noteCoilSays = 'এই কয়েলটা লাগিয়ে দিন, এটা রাখুন। কেউ জানবে না।';
  static const noteMeterSays = 'মিটারটা বাইপাস করে দিন, এটা রাখুন।';
  static const bubbles = [clerkHands, angrySays, noteCoilSays, noteMeterSays];

  // The phone on the dash and the labels a worker reads.
  static const phoneOff = 'লাইন OFF — শুরু করুন';
  static const phoneClear = 'লাইন ক্লিয়ার';
  static const clockLabel = 'ঘড়ি';
  static const phoneLabel = 'ফোন';
  static const sceneLabel = 'ডিউটির খাতা';
  static const logbook = 'লগবুক';
  static const ptwBook = 'PTW বই';
  static const colTaken = 'শাটডাউন নেওয়া';
  static const colReleased = 'শাটডাউন ছাড়া';
  static const colWork = 'কী কাজ';
  static const colSign = 'সই';
  static const carbonCopy = 'কার্বন কপি';
  static const docket = 'ডকেট';
  static const placeBook = 'PTW বই';
  static const placeDoor = 'দরজার পকেট';
  static const placeToolbox = 'টুলবক্স';
  static const placeDash = 'ড্যাশবোর্ড';
  static String place(M8Place p) => switch (p) {
        M8Place.book => placeBook,
        M8Place.doorPocket => placeDoor,
        M8Place.toolbox => placeToolbox,
        M8Place.dash => placeDash,
      };
  static String job(M8Job j) => switch (j) {
        M8Job.fuse => 'ফিউজ বদল',
        M8Job.jumper => 'জাম্পার টাইট',
        M8Job.insulator => 'ইনসুলেটর বদল',
      };
  static String part(M8Job j) => switch (j) {
        M8Job.fuse => 'পুরনো ফিউজ',
        M8Job.jumper => 'পুরনো জাম্পার ক্ল্যাম্প',
        M8Job.insulator => 'ফাটা ইনসুলেটর',
      };
  static const permits = ['পারমিট', 'কপি', 'গ্রাহক', 'খাতা'];

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses (all of one length).
  static const whyQ = <M8Why, String>{
    M8Why.permit: 'ফোনে লাইন OFF শুনেও কেন পোলে উঠলেন না?',
    M8Why.copy: 'কার্বন কপিটা কেন পারমিট বইয়ে রাখলেন?',
    M8Why.angry: 'রাগী গ্রাহকের সাথে কেন শান্ত থাকলেন?',
    M8Why.note: 'টাকাটা কেন ফিরিয়ে দিলেন?',
    M8Why.sign: 'সই করার আগে কেন দুবার পড়লেন?',
  };
  static const whyRight = <M8Why, List<String>>{
    M8Why.permit: [
      'মুখের কথায় নয়, লিখিত পারমিট হাতে নিয়ে তবেই পোলে উঠি',
      'ফোনের কথা প্রমাণ নয়, পারমিট হাতে এলে তবেই উঠব',
      'লিখিত পারমিট আর নিজের আর্থিং ছাড়া পোলে ওঠা নিষেধ',
    ],
    M8Why.copy: [
      'কার্বন কপি প্রমাণ করে আমি আইন মেনেই লাইনে হাত দিয়েছি',
      'দুর্ঘটনা হলে পারমিট বইয়ের কপিই আমার আইনি প্রমাণ',
      'পারমিট বইয়ে কপি থাকলে পরে সময় মিলিয়ে নেওয়া যায়',
    ],
    M8Why.angry: [
      'ইউনিফর্ম পরলে আমি কোম্পানির প্রতিনিধি, তাই শান্ত থাকি',
      'কাজের চাপে মাথা গরম হলেও শান্ত থাকাই নিয়ম',
      'গ্রাহকের সাথে দুর্ব্যবহার করলে লাইসেন্সের শর্ত ভাঙে',
    ],
    M8Why.note: [
      'হুকিং বা বাইপাসে সাহায্য করা নিজের পায়ে কুড়ুল মারা',
      'ধরা পড়লে আইন ছাড়বে না, তাই টাকা ফিরিয়ে দিলাম',
      'টাকার বিনিময়ে অবৈধ কাজ দুর্নীতি, বিপদও ডেকে আনে',
    ],
    M8Why.sign: [
      'সই করলে খাতার সব লেখার দায় আমার, তাই দুবার পড়ে নিই',
      'খাতায় ভুল থাকলে তদন্তে আমিই ফেঁসে যাব, তাই দুবার পড়া',
      'সই করার আগে দুবার পড়ে দেখা ডিউটির নিয়ম, তাই পড়লাম',
    ],
  };
  static const myths = [
    'আইন-কানুন সব বইয়ের পাতায়, মাঠে জুগাড়েই কাজ চলে',
    'আমি নিচু পদের কর্মী, সব দায় তো অফিসারেরই থাকে',
    'অফিসার ফোনে বলেছেন, দায় তো ওনার, আমার তো নয়',
    'কাগজপত্র পরে ঠিক করে নিলেই চলে, কাজটাই আসল',
    'এসব খাতা সুপারভাইজারের মাথাব্যথা, আমার নয় মোটেই',
    'সই তো একটা ফর্মালিটি, না পড়েই করে দিলে চলে যায়',
    'লেখা না থাকলেও সবাই জানে আমি ঠিকই কাজ করেছি',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The reply deck (a field decision: a wrong card is a slip).
  static const replyQ = askReply;
  static const replyRight = [
    'দুঃখিত, ঠিক করতেই এসেছি — একটু সময় দিন, শান্ত হয়ে বসুন',
    'অসুবিধাটা বুঝছি, কাজ শেষ হলেই কারেন্ট আসবে, একটু ধৈর্য ধরুন',
    'শান্ত থাকুন, কাজ চলছে — শেষ হলে আপনাকে জানিয়ে দেব ঠিকই',
  ];
  static const replyWrong = [
    'আমাকে ধমকাবেন না, চেঁচালে আমিও চেঁচাতে জানি, শুনে নিন',
    'কথা বাড়িয়ে লাভ নেই, মুখ ঘুরিয়ে চুপচাপ কাজ করেই যাই',
    'আমার দেখার কথা নয়, অফিসে গিয়ে বলুন, এখানে কেন এলেন',
    'যা পারেন করুন, আপনার রাগে আমার কিছুই যায় আসে না',
    'কাজ চলছে দেখতে পাচ্ছেন না, শুধু শুধু ঝামেলা করছেন কেন',
    'এত চেঁচালে কাজ আরও দেরি হবে, চুপ করে সরে দাঁড়ান',
  ];
  static List<String> get allReply => [...replyRight, ...replyWrong];

  // The careless coworker (one push a play: A before the permit, else B).
  // DRAFT wording — owner (M8-14): his two pushes are the spec's.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _asksPhone = ['কী করবেন?', 'ও বলছে ফোন শুনেই উঠে পড়তে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];
  static const _asksRead = ['কী করবেন?', 'ও বলছে না পড়েই সই করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];
  static const coworkerPhone = CoworkerScript(
    line: 'অফিস ফোনে বলল লাইন OFF আছে — উঠে পড়! দায় তো অফিসারের, আমাদের নয়।',
    exitLine: coworkerExit,
    right: [
      'না — লিখিত পারমিট হাতে না পেলে উঠব না',
      'ফোনের কথায় নয়, পারমিট হাতে এলে তবেই উঠব',
      'পারমিট হাতে না পেলে আমি পোলে উঠছি না',
    ],
    wrong: [
      'ঠিক আছে, ফোনে বলেছে যখন, উঠে পড়ি',
      'দায় তো অফিসারের, আমি উঠে যাই তাহলে',
      'দেরি করে লাভ নেই, ফোনের কথায় উঠে পড়ি',
      'অফিস যখন বলেছে, কাগজ ছাড়াই উঠে পড়ি',
      'আচ্ছা, লাইন OFF শুনলাম, তাহলে উঠেই যাই',
    ],
    asks: _asksPhone,
  );
  static const coworkerRead = CoworkerScript(
    line: 'আইন-কানুন সব বইয়ের পাতায়, মাঠে জুগাড়েই কাজ চলে — না পড়েই সইটা করে দাও।',
    exitLine: coworkerExit,
    right: [
      'না — সইয়ের আগে দুবার পড়ে দেখব',
      'না পড়ে সই নয়, আগে দুবার পড়ে দেখে নিই',
      'সই করার আগে দুবার পড়ব, তারপর সই',
    ],
    wrong: [
      'ঠিক আছে, না পড়েই সই করে চলো যাই',
      'হ্যাঁ, পড়ার কী আছে, সই করেই দিই',
      'সময় নেই, না পড়েই সইটা করে ফেলি',
      'আচ্ছা, জুগাড়েই চলে, সই করে দিচ্ছি',
      'ঠিক বলেছ, পড়া ছাড়াই সই করে দিই',
    ],
    asks: _asksRead,
  );
  static CoworkerScript coworker(M8Push p) => switch (p) {
        M8Push.phone => coworkerPhone,
        M8Push.noRead => coworkerRead,
      };
  static const allCoworkers = [coworkerPhone, coworkerRead];
  static const callHeldPhone = 'ঠিক! ফোনের কথায় নয়, লিখিত পারমিট হাতে নিয়ে তবে পোলে।';
  static const callHeldRead = 'ঠিক! দুবার পড়ে দেখে তবেই সই।';

  static const allSet = 'খাতা পুরো, সই দুবার পড়ে — লেখা থাকলেই প্রমাণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — পারমিট হাতে নিয়ে উঠুন, সব লিখে রাখুন, পড়ে সই করুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtPermit = 'ফোনের কথায় নয়, লিখিত পারমিটে কাজ';
  static const caughtCopy = 'কার্বন কপি পারমিট বইয়ে রাখলেন';
  static const caughtCalm = 'রাগী গ্রাহকের সাথে শান্ত থাকলেন';
  static const caughtNote = 'টাকা ফিরিয়ে দিলেন';
  static const caughtLog = 'সময় আর কাজ ঠিক লিখে, দুবার পড়ে সই';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        ...whyQ.values,
        for (final a in {..._asksPhone, ..._asksRead}) if (!_oldAsks.contains(a)) a,
        callHeldPhone,
        callHeldRead,
        allSet,
        quick,
        fail,
        for (final m in M8DutyLogbookMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M8DutyLogbookMistakes {
  static const _dir = 'assets/game/art/m8_duty_logbook';

  // DRAFT wording — owner (M6-12). Lesson points (0-based): 0 logbook,
  // 1 PTW book, 2 SoP and customer service, 3 ethics.
  static const climbNoPermit = DoMistake(
    key: '8.10/m8_duty_logbook/climb-no-permit',
    textBn: 'ফোনে লাইন OFF শুনেই পোলে উঠলেন! মুখের কথায় কাজ নয় — লিখিত পারমিট হাতে না পাওয়া পর্যন্ত পোলে উঠবেন না।',
    art: '$_dir/climb_no_permit.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const listenedClimb = DoMistake(
    key: '8.10/m8_duty_logbook/listened-climb',
    textBn: 'ওর কথায় ফোনের ভরসায় পোলে উঠতে গেলেন! অফিসার বা যেই হোন — লিখিত পারমিট হাতে না পেলে পোলে উঠবেন না।',
    art: '$_dir/listened_climb.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const copyMisplaced = DoMistake(
    key: '8.10/m8_duty_logbook/copy-misplaced',
    textBn: 'কার্বন কপি পারমিট বইয়ের বাইরে রাখলেন। ওই কপিই প্রমাণ করে আপনি আইন মেনে লাইনে হাত দিয়েছিলেন — পারমিট বইয়ে যত্ন করে রাখুন।',
    art: '$_dir/copy_misplaced.svg',
    lessonPoint: 1,
  );
  static const rudeReply = DoMistake(
    key: '8.10/m8_duty_logbook/rude-reply',
    textBn: 'গ্রাহকের সাথে রূঢ় বা উদাসীন হলেন। ইউনিফর্ম পরলে আপনি কোম্পানির প্রতিনিধি — মাথা গরম হলেও শান্ত থাকুন।',
    art: '$_dir/rude_reply.svg',
    lessonPoint: 2,
  );
  static const tookNote = DoMistake(
    key: '8.10/m8_duty_logbook/took-note',
    textBn: 'টাকা পকেটে নিলেন! হুকিং বা মিটার বাইপাসে সাহায্য করা নিজের পায়ে কুড়ুল মারা — ধরা পড়লে আইন আপনাকে ছাড়বে না।',
    art: '$_dir/took_note.svg',
    lessonPoint: 3,
  );
  static const touchedHook = DoMistake(
    key: '8.10/m8_duty_logbook/touched-hook',
    textBn: 'হুক-কয়েল বা মিটারে হাত দিলেন! টাকার বিনিময়ে হুকিং বা বাইপাস নিষিদ্ধ — ধরা পড়লে আইন আপনাকে ছাড়বে না।',
    art: '$_dir/touched_hook.svg',
    lessonPoint: 3,
  );
  static const signedFast = DoMistake(
    key: '8.10/m8_duty_logbook/signed-fast',
    textBn: 'দুবার পড়ার আগেই সই করলেন। লগবুক সাইন করার আগে দুবার পড়ে দেখুন সব ঠিক আছে কি না।',
    art: '$_dir/signed_fast.svg',
    lessonPoint: 0,
  );
  static const listenedSign = DoMistake(
    key: '8.10/m8_duty_logbook/listened-sign',
    textBn: 'ওর কথায় না পড়েই সই করতে গেলেন! সই করার আগে দুবার পড়ে দেখুন সব ঠিক আছে কি না।',
    art: '$_dir/listened_sign.svg',
    lessonPoint: 0,
  );
  static const takenWrong = DoMistake(
    key: '8.10/m8_duty_logbook/taken-wrong',
    textBn: 'শাটডাউন নেওয়ার সময় ভুল বা ফাঁকা। পারমিটের সময়ের সাথে মিলিয়ে লিখুন — লেখা না থাকলে ধরে নেওয়া হবে আপনি নিয়ম মানেননি।',
    art: '$_dir/taken_wrong.svg',
    lessonPoint: 0,
  );
  static const releaseWrong = DoMistake(
    key: '8.10/m8_duty_logbook/release-wrong',
    textBn: 'শাটডাউন ছাড়ার সময় ভুল বা ফাঁকা। লাইন ক্লিয়ারের ফোনের সময় লিখুন — লেখা না থাকলে ধরে নেওয়া হবে আপনি নিয়ম মানেননি।',
    art: '$_dir/release_wrong.svg',
    lessonPoint: 0,
  );
  static const jobMissing = DoMistake(
    key: '8.10/m8_duty_logbook/job-missing',
    textBn: 'করা কাজ খাতায় বাদ পড়েছে। কী কাজ করলেন সব পুঙ্খানুপুঙ্খভাবে লিখে রাখুন — লেখা নেই মানে প্রমাণ নেই।',
    art: '$_dir/job_missing.svg',
    lessonPoint: 0,
  );

  static const List<DoMistake> all = [
    climbNoPermit,
    listenedClimb,
    copyMisplaced,
    rudeReply,
    tookNote,
    touchedHook,
    signedFast,
    listenedSign,
    takenWrong,
    releaseWrong,
    jobMissing,
  ];
}

typedef _Mk = M8DutyLogbookMistakes;
typedef _L = M8DutyLogbookLines;

/// 'HH:MM' of a game minute (English digits).
String m8Clock(int min) {
  final m = ((min % 1440) + 1440) % 1440;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

/// One play as dealt.
@immutable
class M8Deal {
  const M8Deal({
    required this.startMin,
    required this.phoneDelay,
    required this.goMin,
    required this.backMin,
    required this.workMin,
    required this.gapMin,
    required this.tailMin,
    required this.docket,
    required this.extra,
    required this.moment,
    required this.noteKind,
    required this.house,
    required this.placeOrder,
    required this.earlier,
    required this.phoneMs,
  });

  /// Shift start (game minutes since midnight) and the phone's delay.
  final int startMin;
  final int phoneDelay;

  /// The drive to the gate and back (together 15-30).
  final int goMin;
  final int backMin;

  /// Work 60-150, the gap from work end to the line-clear call 6-15, and from
  /// the call to the van being ready 6-14.
  final int workMin;
  final int gapMin;
  final int tailMin;

  /// The jobs on the docket (1-2) and a job done beyond it (or null).
  final List<M8Job> docket;
  final M8Job? extra;
  final M8Moment moment;
  final M8NoteKind noteKind;
  final int house;

  /// Which place sits in which slot (the book is one of four).
  final List<M8Place> placeOrder;

  /// Two earlier days' rows: (date, taken, released, job).
  final List<(String, int, int, M8Job)> earlier;

  /// Real ms before the phone lights.
  final int phoneMs;

  List<M8Job> get done => [...docket, ?extra];
  int get roundTrip => goMin + backMin;
  M8Why get momentWhy => moment == M8Moment.angry ? M8Why.angry : M8Why.note;
}

M8Deal m8Deal(math.Random rng) {
  final rt = 15 + rng.nextInt(16);
  final go = rt ~/ 2;
  final jobs = [...M8Job.values]..shuffle(rng);
  final docketN = 1 + rng.nextInt(2);
  final docket = jobs.take(docketN).toList();
  final extra = jobs.length > docketN && rng.nextInt(3) == 0 ? jobs[docketN] : null;
  final order = [...M8Place.values]..shuffle(rng);
  final start = 9 * 60 + rng.nextInt(121);
  final earlier = <(String, int, int, M8Job)>[
    for (var i = 2; i >= 1; i--)
      (
        '${(13 - i).toString().padLeft(2, '0')}/11',
        9 * 60 + rng.nextInt(180),
        13 * 60 + rng.nextInt(240),
        M8Job.values[rng.nextInt(3)],
      ),
  ];
  return M8Deal(
    startMin: start,
    phoneDelay: 2 + rng.nextInt(5),
    goMin: go,
    backMin: rt - go,
    workMin: 60 + rng.nextInt(91),
    gapMin: 6 + rng.nextInt(10),
    tailMin: 6 + rng.nextInt(9),
    docket: docket,
    extra: extra,
    moment: M8Moment.values[rng.nextInt(2)],
    noteKind: M8NoteKind.values[rng.nextInt(2)],
    house: rng.nextInt(3),
    placeOrder: order,
    earlier: earlier,
    phoneMs: 7000 + rng.nextInt(3000),
  );
}

/// What a drag in the logbook carries.
enum M8DragKind { clock, part, docket, copyTime }

@immutable
class M8Drag {
  const M8Drag(this.kind, [this.job]);
  final M8DragKind kind;
  final M8Job? job;
}

/// The play state (pure logic).
class M8Run {
  M8Run(this.deal) : now = deal.startMin;
  final M8Deal deal;

  /// The story's clock (game minutes); the screen's dash clock catches up.
  int now;
  var phase = M8Phase.field;
  var phoneLit = false;
  var hasPermit = false;
  int? permitMin;
  int? callMin;
  var keptInBook = false;
  var greased = false;
  M8Place? copyPlace;
  var momentDone = false;
  var signed = false;

  final Map<M8Col, int?> stamps = {M8Col.taken: null, M8Col.released: null};
  final Set<M8Job> onPage = {};
  int passes = 0;
  int slips = 0;
  int signSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];
  int _workStart = 0;

  bool get ended => deadly != null || signed;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => signed && deadly == null && percent >= 55;
  bool get copyUsable => keptInBook && !greased;
  int get phoneAt => deal.startMin + deal.phoneDelay;
  int get midMin => _workStart + deal.workMin ~/ 2;
  int get workEndMin => _workStart + deal.workMin;
  int get callAt => workEndMin + deal.gapMin;
  bool get open => !ended;

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// The phone lights (the clock stands at its time at least).
  void lightPhone() {
    if (phoneLit) return;
    phoneLit = true;
    now = math.max(now, phoneAt);
  }

  /// A tap on the pole before the work starts: climbing without the written
  /// permit is deadly (R1).
  DoMistake? climb() {
    if (!open || phase != M8Phase.field) return null;
    if (!hasPermit) return deadly = _Mk.climbNoPermit;
    return null;
  }

  /// Listening to variant A: the deadly climb on the phone's word.
  DoMistake pushDeadly() => deadly = _Mk.listenedClimb;

  /// Listening to variant B: a slip (B1).
  DoMistake pushSlip() => _slip(_Mk.listenedSign);

  // --- the drive -------------------------------------------------------------
  void toStation() {
    if (!open || phase != M8Phase.field) return;
    now += deal.goMin;
    permitMin = now;
    hasPermit = true;
    phase = M8Phase.window;
  }

  void backFromStation() {
    if (phase != M8Phase.window) return;
    now += deal.backMin;
    phase = M8Phase.returned;
    _tag(_L.caughtPermit);
  }

  void toCopy() {
    if (phase == M8Phase.returned) phase = M8Phase.copy;
  }

  /// The carbon copy put in [p]: the PTW book keeps it; anywhere else is a slip
  /// and the copy is greased (it cannot correct the log later).
  DoMistake? placeCopy(M8Place p) {
    if (!open || phase != M8Phase.copy) return null;
    copyPlace = p;
    phase = M8Phase.ready;
    if (p == M8Place.book) {
      keptInBook = true;
      _tag(_L.caughtCopy);
      return null;
    }
    greased = true;
    return _slip(_Mk.copyMisplaced);
  }

  // --- the stamps ------------------------------------------------------------
  bool get canStamp => open && phase != M8Phase.signed;

  /// The clock dragged into a time column: the time it shows is written;
  /// each column keeps only its last.
  bool stamp(M8Col c, int at) {
    if (!canStamp || (c != M8Col.taken && c != M8Col.released)) return false;
    stamps[c] = at;
    return true;
  }

  /// A time tapped on the open page: cleared.
  bool clearStamp(M8Col c) {
    if (!canStamp || phase != M8Phase.tailgate) return false;
    if (stamps[c] == null) return false;
    stamps[c] = null;
    return true;
  }

  /// The permit time dragged off the carbon copy into শাটডাউন নেওয়া (only
  /// from a copy kept in the book).
  bool refillTaken() {
    if (!canStamp || phase != M8Phase.tailgate || !copyUsable || permitMin == null) return false;
    stamps[M8Col.taken] = permitMin;
    return true;
  }

  bool addJob(M8Job j) {
    if (!canStamp || phase != M8Phase.tailgate) return false;
    return onPage.add(j);
  }

  bool addDocket() {
    if (!canStamp || phase != M8Phase.tailgate) return false;
    var any = false;
    for (final j in deal.docket) {
      any = onPage.add(j) || any;
    }
    return any;
  }

  // --- the time-lapse --------------------------------------------------------
  void beginLapse() {
    if (phase != M8Phase.ready) return;
    phase = M8Phase.lapse;
    now += 6;
    _workStart = now;
  }

  void startMoment() {
    if (phase == M8Phase.lapse) phase = M8Phase.moment;
  }

  /// The angry consumer's reply: calm is right; anything else a slip.
  DoMistake? reply(bool calm) {
    if (!open || phase != M8Phase.moment || deal.moment != M8Moment.angry || momentDone) return null;
    if (!calm) return _slip(_Mk.rudeReply);
    momentDone = true;
    _tag(_L.caughtCalm);
    return null;
  }

  /// The note flicked back at him: right.
  void noteFlick() {
    if (!open || phase != M8Phase.moment || deal.moment != M8Moment.note || momentDone) return;
    momentDone = true;
    _tag(_L.caughtNote);
  }

  DoMistake? notePocket() {
    if (!open || phase != M8Phase.moment || deal.moment != M8Moment.note || momentDone) return null;
    return _slip(_Mk.tookNote);
  }

  DoMistake? touchHook() {
    if (!open || phase != M8Phase.moment || deal.moment != M8Moment.note || momentDone) return null;
    return _slip(_Mk.touchedHook);
  }

  void resumeLapse() {
    if (phase == M8Phase.moment && momentDone) phase = M8Phase.lapse;
  }

  void workDone() {
    if (phase == M8Phase.lapse) phase = M8Phase.down;
  }

  void callClear() {
    callMin = callAt;
    now = callAt;
  }

  void packed() => now = callAt + 2;

  void toTailgate() {
    now = callAt + deal.tailMin;
    phase = M8Phase.tailgate;
  }

  // --- the page --------------------------------------------------------------
  void readPass() {
    if (phase == M8Phase.tailgate && !signed) passes++;
  }

  static bool near(int? a, int? b) => a != null && b != null && (a - b).abs() <= kM8Tolerance;

  /// The sign: judged now, at most [kM8SignCap] slips from it (M8-13).
  List<DoMistake> sign() {
    if (!open || phase != M8Phase.tailgate) return const [];
    signed = true;
    phase = M8Phase.signed;
    final all = <DoMistake>[
      if (passes < kM8Passes) _Mk.signedFast,
      if (!near(stamps[M8Col.taken], permitMin)) _Mk.takenWrong,
      if (!near(stamps[M8Col.released], callMin)) _Mk.releaseWrong,
      if (deal.done.any((j) => !onPage.contains(j))) _Mk.jobMissing,
    ];
    final cut = all.take(kM8SignCap).toList();
    slips += cut.length;
    signSlips = cut.length;
    if (cut.isEmpty) _tag(_L.caughtLog);
    return cut;
  }

  /// The reason that fits the moment's ◆.
  M8Why get momentWhy => deal.momentWhy;
}

/// The quick bonus: a little under a clean play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   the drive, the window and the way back (camera pans and the permit)
///     ≈ 9000, one stamp ≈ 1500, the copy drag ≈ 2000        ≈ 12500
///   + the crew's time-lapse (tester, earths, climb, work) ≈ 11000
///   + the public moment ≈ 4000 (+ a reply or a flick ≈ 3000)  ≈ 18000
///   + the call and the packing ≈ 6500, the stamp ≈ 1500       ≈ 8000
///   + the page: three drags (~1500 each), two read passes (~2500 each),
///     the sign hold ≈ 1500                                  ≈ 11000
///   + four reasons (~8200 each) + the coworker once ≈ 9600  ≈ 42400
///   ≈ 103000, 85 % ≈ 88000 → 90 s (a builder's estimate; the owner may tune).
const m8DutyLogbookQuickMs = 90000;

@immutable
class M8DutyLogbookPack {
  const M8DutyLogbookPack({required this.id, required this.titleBn, this.quickMs = m8DutyLogbookQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8DutyLogbookPack> m8DutyLogbookPacks = {
  'do_8_10_a': M8DutyLogbookPack(id: 'do_8_10_a', titleBn: M8DutyLogbookLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8DutyLogbookProbe {
  static M8Run? run;

  /// The dash clock as shown now.
  static int Function()? shown;
}

// ============================================================================
// Page
// ============================================================================

class M8DutyLogbookPage extends StatefulWidget {
  const M8DutyLogbookPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8DutyLogbookPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8DutyLogbookPage> createState() => _M8DutyLogbookPageState();
}

class _M8DutyLogbookPageState extends State<M8DutyLogbookPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _LogRunPage(
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

class _LogRunPage extends ConsumerStatefulWidget {
  const _LogRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8DutyLogbookPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_LogRunPage> createState() => _LogRunPageState();
}

/// What the next paid reason leads to.
enum _After { permit, copy, moment, sign }

class _LogRunPageState extends ConsumerState<_LogRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8Run _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;

  /// The story plays by itself (the drive, the time-lapse, the call): the
  /// scene's taps wait; the clock can still be stamped.
  var _story = false;
  _After _after = _After.permit;
  final Set<int> _done = {};

  /// The camera (0: the lane, 1: the gate) and the dash clock as shown.
  late final AnimationController _panC = AnimationController(vsync: this);
  late final AnimationController _clockC = AnimationController(vsync: this);
  late final ValueNotifier<int> _clockV = ValueNotifier<int>(0);
  int _clockFrom = 0;
  int _clockTo = 0;

  M8Crew _crew = M8Crew.idle;
  int _parts = 0;
  String? _phoneText;
  Timer? _phoneTimer;

  /// A caption bubble (the clerk's, the man's) and its pop-in key.
  String? _bubble;
  int _bubbleN = 0;

  /// 0: no permit shown, 1: it slides out of the window, 2: held out.
  int _permit = 0;

  /// The carbon copy in hand (its slots shown).
  var _copyUp = false;

  /// The public moment.
  var _momentUp = false;
  var _replyUp = false;
  List<ChoiceOption> _replyOpts = const [];
  final Set<String> _replyWrong = {};
  String? _replyPicked;
  Offset _noteOff = Offset.zero;

  /// The page: the read pass in hand, the hold on the সই box.
  var _pageOpen = false;
  final Set<int> _zones = {};
  double? _passFromY;
  double? _rulerY;
  var _holding = false;
  int _holdN = 0;
  Timer? _signTimer;
  List<DoMistake> _signQueue = [];

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M8Geo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8Run(m8Deal(widget.rng));
    _clockV.value = _run.now;
    _clockFrom = _clockTo = _run.now;
    _clockC.addListener(() {
      final v = Curves.easeInOut.transform(_clockC.value);
      _clockV.value = _clockFrom + ((_clockTo - _clockFrom) * v).round();
    });
    M8DutyLogbookProbe.run = _run;
    M8DutyLogbookProbe.shown = () => _clockV.value;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  bool get _live => mounted && !_ended;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _phoneTimer?.cancel();
    _signTimer?.cancel();
    _panC.dispose();
    _clockC.dispose();
    _clockV.dispose();
    if (identical(M8DutyLogbookProbe.run, _run)) {
      M8DutyLogbookProbe.run = null;
      M8DutyLogbookProbe.shown = null;
    }
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

  Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: _quiet ? math.max(40, ms ~/ 8) : ms));

  /// The dash clock runs to [to] (game minutes) over [ms].
  Future<void> _tweenClock(int to, int ms) async {
    _clockC.stop();
    _clockFrom = _clockV.value;
    _clockTo = to;
    if (_quiet || ms <= 0 || to == _clockFrom) {
      _clockV.value = to;
      return;
    }
    _clockC.duration = Duration(milliseconds: ms);
    await _clockC.forward(from: 0);
  }

  Future<void> _panTo(double v) async {
    if (_quiet) {
      _panC.value = v;
      return;
    }
    await _panC.animateTo(v, duration: const Duration(milliseconds: 1400), curve: Curves.easeInOut);
  }

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && !_story;

  /// The clock may be stamped while the story plays; nothing else is open.
  bool get _canStamp => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && _run.canStamp && !_replyUp;

  String get _task => switch (_run.phase) {
        M8Phase.field => _run.phoneLit ? _L.askPhone : _L.askField,
        M8Phase.driving || M8Phase.window || M8Phase.returned => _L.askWait,
        M8Phase.copy => _L.askCopy,
        M8Phase.ready => _L.askReady,
        M8Phase.lapse || M8Phase.down => _L.askWait,
        M8Phase.moment => _run.deal.moment == M8Moment.angry ? _L.askReply : _L.askNote,
        M8Phase.tailgate || M8Phase.signed => _L.askPage,
      };

  Future<void> _start() async {
    _clock.start();
    _phoneTimer = Timer(Duration(milliseconds: _run.deal.phoneMs), _lightPhone);
    unawaited(_sayChain([_task]));
  }

  void _lightPhone() {
    if (!_live || _run.phoneLit) return;
    _run.lightPhone();
    setState(() => _phoneText = _L.phoneOff);
    _cue('sounds/learn/rush_in.ogg', volume: 0.35);
    unawaited(_tweenClock(_run.now, 500));
    if (_canPlay) unawaited(_sayChain([_task]));
  }

  void _bubbleSet(String? s) => setState(() {
        _bubble = s;
        _bubbleN++;
      });

  void _stepDone() {
    _steps++;
    setState(() {});
  }

  // --- the coworker --------------------------------------------------------
  /// A before the permit (the phone's word), B at the page (the sign).
  M8Push get _push => _run.phase == M8Phase.tailgate ? M8Push.noRead : M8Push.phone;

  /// The phone lit and no permit yet: a touch of the van or the pole lets him in.
  bool get _variantA => _run.phase == M8Phase.field && _run.phoneLit && !_run.hasPermit;

  bool _holdA() {
    if (!_variantA || coworkerDone) return false;
    if (!coworkerDue) scheduleCoworker();
    return holdForCoworker();
  }

  // --- hands on --------------------------------------------------------------
  void _tapScene(Offset p, M8Geo geo) {
    if (!_canPlay) return;
    switch (_run.phase) {
      case M8Phase.field:
        if (geo.van.contains(p)) {
          _tapVan();
        } else if (geo.pole.contains(p)) {
          _tapPole();
        } else {
          _hints.missTap();
        }
      case M8Phase.ready:
        if (geo.pole.contains(p)) {
          unawaited(_startLapse());
        } else {
          _hints.missTap();
        }
      case M8Phase.moment:
        if (_run.deal.moment != M8Moment.note) {
          _hints.missTap();
          return;
        }
        final hook = _run.deal.noteKind == M8NoteKind.coil ? geo.coil : geo.meterBox;
        if (hook.inflate(4).contains(p)) {
          unawaited(_mistake(_run.touchHook()!, p));
        } else {
          _hints.missTap();
        }
      default:
        _hints.missTap();
    }
  }

  void _tapVan() {
    if (_holdA()) return;
    unawaited(_drive());
  }

  void _tapPole() {
    if (_holdA()) return;
    final m = _run.climb();
    if (m != null) unawaited(_deadly(m));
  }

  Future<void> _drive() async {
    if (!_canPlay || _run.phase != M8Phase.field) return;
    _hush();
    final r = _run;
    setState(() => _story = true);
    r.toStation();
    unawaited(_tweenClock(r.permitMin!, 1500));
    await _panTo(1);
    if (!_live) return;
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    _bubbleSet(_L.clerkHands);
    setState(() => _permit = 1);
    await _wait(800);
    if (!_live) return;
    setState(() => _permit = 2);
    // The clock stands at the permit's time: the moment to write it down.
    await _wait(1900);
    if (!_live) return;
    r.backFromStation();
    setState(() {
      _bubble = null;
      _permit = 0;
    });
    unawaited(_tweenClock(r.now, 1500));
    await _panTo(0);
    if (!_live) return;
    setState(() => _story = false);
    _after = _After.permit;
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(_L.whyRight[M8Why.permit]!, _L.myths, widget.rng),
      question: _L.whyQ[M8Why.permit]!,
      stillValid: () => !_ended,
    ));
  }

  void _toCopy() {
    if (!_live) return;
    _run.toCopy();
    setState(() => _copyUp = true);
    _steps++;
    unawaited(_sayChain([_task]));
  }

  void _placeCopy(M8Place p, Offset origin) {
    if (!_canPlay || _run.phase != M8Phase.copy) return;
    final m = _run.placeCopy(p);
    setState(() => _copyUp = false);
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    _after = _After.copy;
    putOnTable(10);
    unawaited(askReason(
      deal: () => dealChoices(_L.whyRight[M8Why.copy]!, _L.myths, widget.rng),
      question: _L.whyQ[M8Why.copy]!,
      stillValid: () => !_ended,
    ));
  }

  // --- the time-lapse ----------------------------------------------------------
  Future<void> _startLapse() async {
    if (!_canPlay || _run.phase != M8Phase.ready) return;
    _hush();
    final r = _run;
    setState(() => _story = true);
    r.beginLapse();
    unawaited(_tweenClock(r.now, 800));
    // The crew proves the tester live-dead-live, earths, then climbs (shown,
    // not scored: M8-17).
    for (final s in [M8Crew.testLive1, M8Crew.testDead, M8Crew.testLive2, M8Crew.earthed]) {
      setState(() => _crew = s);
      _tick('sounds/intro/click.ogg', 0.5);
      await _wait(1000);
      if (!_live) return;
    }
    setState(() => _crew = M8Crew.up);
    unawaited(_tweenClock(r.midMin, 1800));
    await _wait(600);
    if (!_live) return;
    final first = (r.deal.done.length + 1) ~/ 2;
    setState(() => _parts = first);
    _tick('sounds/learn/card_deal_a.ogg', 0.5);
    await _wait(1300);
    if (!_live) return;
    r.startMoment();
    setState(() {
      _story = false;
      _momentUp = true;
    });
    _beginMoment();
  }

  void _beginMoment() {
    final r = _run;
    if (r.deal.moment == M8Moment.angry) {
      _bubbleSet(_L.angrySays);
      setState(() {
        _replyOpts = dealChoices(_L.replyRight, _L.replyWrong, widget.rng);
        _replyWrong.clear();
        _replyPicked = null;
        _replyUp = true;
      });
    } else {
      _bubbleSet(r.deal.noteKind == M8NoteKind.coil ? _L.noteCoilSays : _L.noteMeterSays);
      setState(() => _noteOff = Offset.zero);
    }
    _steps++;
    unawaited(_sayChain([_task]));
  }

  Future<void> _onReply(ChoiceOption o, Offset origin) async {
    if (!_canPlayDeck || _replyPicked != null) return;
    if (!o.correct) {
      final m = _run.reply(false);
      if (m == null) return;
      setState(() => _replyWrong.add(o.textBn));
      await _mistake(m, origin);
      return;
    }
    _run.reply(true);
    setState(() => _replyPicked = o.textBn);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!_live) return;
    await _momentResolved();
  }

  /// A deck may be answered now (no card, praise window or coworker over it).
  bool get _canPlayDeck => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze;

  Future<void> _momentResolved() async {
    if (!_live) return;
    setState(() {
      _replyUp = false;
      _bubble = null;
    });
    _after = _After.moment;
    putOnTable(15);
    final why = _run.momentWhy;
    unawaited(askReason(
      deal: () => dealChoices(_L.whyRight[why]!, _L.myths, widget.rng),
      question: _L.whyQ[why]!,
      stillValid: () => !_ended,
    ));
  }

  Future<void> _resumeLapse() async {
    if (!_live) return;
    final r = _run;
    r.resumeLapse();
    setState(() {
      _story = true;
      _momentUp = false;
    });
    unawaited(_tweenClock(r.workEndMin, 1800));
    final all = r.deal.done.length;
    while (_parts < all) {
      await _wait(600);
      if (!_live) return;
      setState(() => _parts++);
      _tick('sounds/learn/card_deal_a.ogg', 0.5);
    }
    await _wait(900);
    if (!_live) return;
    r.workDone();
    await _downSequence();
  }

  /// Crew down, earth off, the call 'লাইন ক্লিয়ার', tools packed, van ready.
  Future<void> _downSequence() async {
    final r = _run;
    setState(() => _crew = M8Crew.down);
    unawaited(_tweenClock(r.callAt, 1700));
    await _wait(900);
    if (!_live) return;
    setState(() => _crew = M8Crew.earthOff);
    await _wait(900);
    if (!_live) return;
    r.callClear();
    setState(() => _phoneText = _L.phoneClear);
    _cue('sounds/learn/rush_in.ogg', volume: 0.5);
    HapticFeedback.mediumImpact();
    // The clock holds at the call's time: the moment to write it down.
    await _wait(3000);
    if (!_live) return;
    r.packed();
    unawaited(_tweenClock(r.now, 400));
    setState(() => _crew = M8Crew.idle);
    await _wait(1700);
    if (!_live) return;
    r.toTailgate();
    unawaited(_tweenClock(r.now, 500));
    await _wait(700);
    if (!_live) return;
    setState(() {
      _story = false;
      _phoneText = null;
      _pageOpen = true;
    });
    _steps++;
    unawaited(_sayChain([_task]));
    if (!coworkerDone) scheduleCoworker();
  }

  // --- the logbook ---------------------------------------------------------------
  void _stampDrop(M8Col col, M8Drag d) {
    final r = _run;
    var ok = false;
    switch (d.kind) {
      case M8DragKind.clock:
        ok = r.stamp(col, _clockV.value);
      case M8DragKind.copyTime:
        ok = col == M8Col.taken && r.refillTaken();
      case M8DragKind.part:
        ok = col == M8Col.work && d.job != null && r.addJob(d.job!);
      case M8DragKind.docket:
        ok = col == M8Col.work && r.addDocket();
    }
    if (!ok) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    _stepDone();
  }

  bool _accepts(M8Col col, M8Drag d) => switch (d.kind) {
        M8DragKind.clock => col == M8Col.taken || col == M8Col.released,
        M8DragKind.copyTime => col == M8Col.taken,
        M8DragKind.part || M8DragKind.docket => col == M8Col.work,
      };

  void _clearStamp(M8Col col) {
    if (!_canPlay || !_run.clearStamp(col)) return;
    _tick();
    _stepDone();
  }

  // The read pass: a finger down the page from the first line to the last.
  void _passStart(double y) {
    _zones.clear();
    _passFromY = null;
    if (!_canPlay || _run.phase != M8Phase.tailgate) return;
    _passFromY = y;
    final z = M8PageGeo.zoneAt(y);
    if (z != null) _zones.add(z);
    setState(() => _rulerY = y);
  }

  void _passMove(double y, double lastY) {
    if (_passFromY == null) return;
    final lo = math.min(y, lastY), hi = math.max(y, lastY);
    for (var i = 0; i < kM8ReadZones; i++) {
      final z = M8PageGeo.zone(i);
      if (z.top <= hi && z.bottom > lo) _zones.add(i);
    }
    setState(() => _rulerY = y);
  }

  void _passEnd(double y) {
    final from = _passFromY;
    _passFromY = null;
    final full = from != null && _zones.length == kM8ReadZones && y > from;
    _zones.clear();
    setState(() => _rulerY = null);
    if (!_canPlay || _run.phase != M8Phase.tailgate) return;
    if (full) {
      _run.readPass();
      _tick('sounds/intro/tick.ogg', 0.5);
      _stepDone();
    } else {
      _hints.missTap();
    }
  }

  void _holdStart() {
    if (!_canPlay || _run.phase != M8Phase.tailgate) return;
    _signTimer?.cancel();
    setState(() {
      _holding = true;
      _holdN++;
    });
    _signTimer = Timer(const Duration(milliseconds: 1200), () {
      _signTimer = null;
      unawaited(_signNow());
    });
  }

  void _holdEnd() {
    _signTimer?.cancel();
    _signTimer = null;
    if (_holding && mounted) setState(() => _holding = false);
  }

  Future<void> _signNow() async {
    if (mounted) setState(() => _holding = false);
    if (!_canPlay || _run.phase != M8Phase.tailgate) return;
    // The decisive control: variant B holds it.
    if (holdForCoworker()) return;
    final ms = _run.sign();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _hush();
    setState(() {});
    if (ms.isEmpty) {
      _after = _After.sign;
      putOnTable(15 + (_run.slips == 0 ? 5 : 0));
      unawaited(askReason(
        deal: () => dealChoices(_L.whyRight[M8Why.sign]!, _L.myths, widget.rng),
        question: _L.whyQ[M8Why.sign]!,
        stillValid: () => !_ended,
      ));
      return;
    }
    _signQueue = [...ms];
    final size = MediaQuery.sizeOf(context);
    await _mistake(_signQueue.removeAt(0), Offset(size.width / 2, size.height * 0.5));
  }

  // --- the pole's flick ------------------------------------------------------------
  void _noteDrag(Offset delta) {
    if (!_canPlay || _run.phase != M8Phase.moment) return;
    setState(() => _noteOff += delta);
  }

  void _noteDragEnd(M8Geo geo) {
    if (!_canPlay || _run.phase != M8Phase.moment || _run.deal.moment != M8Moment.note) return;
    final at = geo.note.shift(_noteOff).center;
    final off = _noteOff;
    if (geo.pocket.inflate(16).contains(at)) {
      setState(() => _noteOff = Offset.zero);
      final m = _run.notePocket();
      if (m != null) unawaited(_mistake(m, at));
    } else if (off.dx >= 44 && off.dx.abs() > off.dy.abs()) {
      _run.noteFlick();
      setState(() => _noteOff = Offset.zero);
      _tick('sounds/learn/tag_slap.ogg', 0.5);
      unawaited(_momentResolved());
    } else {
      setState(() => _noteOff = Offset.zero);
      _hints.missTap();
    }
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
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
    final after = _after;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (!_live) return;
      switch (after) {
        case _After.permit:
          setState(() => _done.add(0));
          _toCopy();
        case _After.copy:
          setState(() => _done.add(1));
          _steps++;
          unawaited(_sayChain([_task]));
        case _After.moment:
          setState(() => _done.add(2));
          unawaited(_resumeLapse());
        case _After.sign:
          setState(() => _done.add(3));
          unawaited(_finish());
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _L.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final inA = _variantA;
    final inB = _run.phase == M8Phase.tailgate && !_run.signed;
    if (!inA && !inB) return null;
    if (_intro || _card != null || tableBusy || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final push = _push;
    if (!held) {
      if (push == M8Push.phone) {
        // Listening to variant A is the deadly climb on a phone's word.
        unawaited(_deadly(_run.pushDeadly()));
        return;
      }
      final m = _run.pushSlip();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(_L.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!_live) return;
    unawaited(_sayChain([push == M8Push.phone ? _L.callHeldPhone : _L.callHeldRead, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? _L.tapWhy[_nudgeN++ % _L.tapWhy.length]
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
      _cardTone = MistakeTone.slip;
      _holding = false;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8log/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The climb on the phone's word: the lane freezes grey, the lineman at the
  /// cross-arm on a line that was never made dead plays in colour; then
  /// near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _phoneTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m8log/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? _L.deadlyWord : _L.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        if (_signQueue.isNotEmpty) {
          final next = _signQueue.removeAt(0);
          final size = MediaQuery.sizeOf(context);
          unawaited(_mistake(next, Offset(size.width / 2, size.height * 0.5)));
          return;
        }
        if (_run.phase == M8Phase.signed) {
          unawaited(_finish());
          return;
        }
        if (_run.phase == M8Phase.ready) _steps++;
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
    await _say(!_run.passed ? _L.fail : (_quickBonus ? _L.quick : _L.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- the scene ---------------------------------------------------------------

  /// The gesture hand: how to touch, never what.
  HintSpec? _hint() {
    final g = _geoNow;
    if (g == null) return null;
    final n = _hintN++;
    final r = _run;
    switch (r.phase) {
      case M8Phase.field:
      case M8Phase.ready:
        return HintSpec.sweep([g.pole, g.van, g.phone, g.clock], space: HintSpace.scene);
      case M8Phase.copy:
        return HintSpec.drag(g.copyInHand.center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      case M8Phase.moment:
        if (r.deal.moment != M8Moment.note) return null;
        return HintSpec.drag(g.note.center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      case M8Phase.tailgate:
        // The correction: a cleared time and the copy in the strip.
        if (r.stamps[M8Col.taken] == null && r.copyUsable && n.isEven) {
          return HintSpec.drag(g.slot(4).center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
        }
        final jobs = [for (var i = 0; i < M8Job.values.length; i++) if (r.deal.done.contains(M8Job.values[i]) && !r.onPage.contains(M8Job.values[i])) g.slot(i)];
        return HintSpec.sweep([
          M8PageGeo.earlier(0),
          M8PageGeo.earlier(1),
          M8PageGeo.col(M8Col.work),
          ...jobs,
          if (r.copyUsable) g.slot(4),
          M8PageGeo.col(M8Col.sign),
        ], space: HintSpace.scene);
      default:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8Geo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final r = _run;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('lane'),
                child: RepaintBoundary(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _panC,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: 720,
                        maxWidth: 720,
                        child: CustomPaint(
                          size: Size(720, m.height),
                          painter: M8WorldPainter(geo: geo, crew: _crew, house: r.deal.house, parts: _parts, phoneOn: _phoneText != null, signed: r.signed),
                        ),
                      ),
                      builder: (_, c) => Transform.translate(offset: Offset(-360 * _panC.value, 0), child: c),
                    ),
                  ),
                ),
              ),
              if (_permit > 0)
                Positioned.fromRect(
                  key: const ValueKey('permit'),
                  rect: Rect.fromLTWH(96, geo.ground - 58, 168, 82),
                  child: _PermitCard(time: r.permitMin ?? r.now, out: _permit == 2, quiet: quiet),
                ),
              if (_bubble != null && (_permit > 0 || _momentUp))
                Positioned.fromRect(
                  key: ValueKey('bubble-$_bubbleN'),
                  rect: _permit > 0 ? Rect.fromLTWH(92, geo.ground - 156, 176, 48) : geo.bubble,
                  child: _Bubble(text: _bubble!, quiet: quiet),
                ),
              if (_momentUp) ..._momentLayers(geo, quiet),
            ],
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: _L.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
          ),
        ),
      ),
      if (_momentUp && r.deal.moment == M8Moment.note) _noteLayer(geo),
      if (!_pageOpen) ...[
        Positioned.fromRect(
          key: const ValueKey('phone'),
          rect: geo.phone,
          child: _PhoneChip(text: _phoneText, quiet: quiet),
        ),
        Positioned.fromRect(
          key: const ValueKey('clock-chip'),
          rect: geo.clock,
          child: _clockDrag(geo.clock.size),
        ),
        if (_copyUp) ..._copyLayers(geo),
      ],
      _logbookLayer(geo, quiet),
      if (_pageOpen) ..._stripLayers(geo),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('inset'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1800),
              builder: (_, v, _) => CustomPaint(painter: M8InsetPainter(rect: geo.inset0, v: v)),
            ),
          ),
        ),
    ];
  }

  // The man (or the angry consumer) at the house, the note, the coil.
  List<Widget> _momentLayers(M8Geo geo, bool quiet) {
    final angry = _run.deal.moment == M8Moment.angry;
    return [
      Positioned.fromRect(
        key: const ValueKey('man'),
        rect: geo.manBox,
        child: IgnorePointer(child: CustomPaint(painter: M8ManPainter(angry: angry))),
      ),
      if (!angry && _run.deal.noteKind == M8NoteKind.coil)
        Positioned.fromRect(
          key: const ValueKey('coil'),
          rect: geo.coil,
          child: const IgnorePointer(child: CustomPaint(painter: M8CoilPainter())),
        ),
    ];
  }

  // The note in his hand: a layer of its own, above the scene's tap layer.
  Widget _noteLayer(M8Geo geo) => Positioned.fromRect(
        key: const ValueKey('note'),
        rect: geo.note.shift(_noteOff),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onPanUpdate: (d) => _noteDrag(d.delta),
          onPanEnd: (_) => _noteDragEnd(geo),
          onPanCancel: () {
            if (_noteOff != Offset.zero) setState(() => _noteOff = Offset.zero);
          },
          child: Semantics(label: 'নোট', child: const CustomPaint(painter: M8NotePainter())),
        ),
      );

  // The carbon copy in hand and the four places (shuffled).
  List<Widget> _copyLayers(M8Geo geo) {
    return [
      Positioned.fill(
        key: const ValueKey('copy-dim'),
        child: const IgnorePointer(child: ColoredBox(color: Color(0x33000000))),
      ),
      for (var i = 0; i < 4; i++)
        Positioned.fromRect(
          key: ValueKey('place-$i'),
          rect: geo.place(i),
          child: DragTarget<M8Drag>(
            onWillAcceptWithDetails: (d) => d.data.kind == M8DragKind.copyTime && _canPlay,
            onAcceptWithDetails: (d) => _placeCopy(_run.deal.placeOrder[i], d.offset),
            builder: (_, cand, _) => _PlaceTile(place: _run.deal.placeOrder[i], hot: cand.isNotEmpty),
          ),
        ),
      Positioned.fromRect(
        key: const ValueKey('copy-hand'),
        rect: geo.copyInHand,
        child: Draggable<M8Drag>(
          data: const M8Drag(M8DragKind.copyTime),
          maxSimultaneousDrags: _canPlay ? 1 : 0,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _feedback(geo.copyInHand.size, _CopyCard(time: _run.permitMin ?? _run.now, usable: true, label: true)),
          childWhenDragging: Opacity(opacity: 0.35, child: _CopyCard(time: _run.permitMin ?? _run.now, usable: true, label: true)),
          child: _CopyCard(time: _run.permitMin ?? _run.now, usable: true, label: true),
        ),
      ),
    ];
  }

  Widget _feedback(Size size, Widget child) => Material(color: Colors.transparent, child: SizedBox(width: size.width, height: size.height, child: child));

  Widget _clockDrag(Size size) {
    final face = _ClockFace(value: _clockV);
    return Draggable<M8Drag>(
      data: const M8Drag(M8DragKind.clock),
      maxSimultaneousDrags: _canStamp ? 1 : 0,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _feedback(size, face),
      childWhenDragging: Opacity(opacity: 0.35, child: face),
      child: face,
    );
  }

  // The logbook: the compact tray, or the open page at the tailgate.
  Widget _logbookLayer(M8Geo geo, bool quiet) {
    final open = _pageOpen;
    final r = _run;
    Rect head(M8Col c) {
      if (open) return M8PageGeo.headCol(c);
      final t = geo.trayCol(c);
      return Rect.fromLTWH(t.left, geo.tray.top, t.width, 22);
    }

    Rect today(M8Col c) => open ? M8PageGeo.col(c) : geo.trayCol(c);
    final page = open ? M8PageGeo.page : geo.tray;
    final rowH = open ? M8PageGeo.rowH : 28.0;
    final earlierN = open ? 2 : 1;
    final label = bangla(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF5A4A34));
    final value = bangla(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF1A3A8A));
    final small = bangla(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF3A3A44));
    Widget fit(Widget w) => FittedBox(fit: BoxFit.scaleDown, child: w);
    String name(M8Col c) => switch (c) {
          M8Col.taken => _L.colTaken,
          M8Col.released => _L.colReleased,
          M8Col.work => _L.colWork,
          M8Col.sign => _L.colSign,
        };
    BoxDecoration cell({bool hot = false}) => BoxDecoration(
          border: Border.all(color: hot ? const Color(0xFFC48A2E) : const Color(0xFF9C8A6A), width: hot ? 2 : 1),
          color: hot ? const Color(0x33F2C230) : null,
        );
    Widget timeCell(M8Col c) {
      final t = r.stamps[c];
      final body = DragTarget<M8Drag>(
        onWillAcceptWithDetails: (d) => _canStamp && _accepts(c, d.data),
        onAcceptWithDetails: (d) => _stampDrop(c, d.data),
        builder: (_, cand, _) => DecoratedBox(
          decoration: cell(hot: cand.isNotEmpty),
          child: Center(child: t == null ? const SizedBox.shrink() : fit(Text(m8Clock(t), style: value))),
        ),
      );
      if (!open) return body;
      return GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _clearStamp(c), child: body);
    }

    Widget workCell() => DragTarget<M8Drag>(
          onWillAcceptWithDetails: (d) => _canStamp && _accepts(M8Col.work, d.data),
          onAcceptWithDetails: (d) => _stampDrop(M8Col.work, d.data),
          builder: (_, cand, _) => DecoratedBox(
            decoration: cell(hot: cand.isNotEmpty),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final j in M8Job.values)
                    if (r.onPage.contains(j)) fit(Text(_L.job(j), maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1A3A8A)))),
                ],
              ),
            ),
          ),
        );

    Widget signCell() {
      final box = DecoratedBox(
        decoration: cell(),
        child: r.signed
            ? const Padding(padding: EdgeInsets.all(8), child: CustomPaint(painter: M8ScribblePainter(seed: 7)))
            : Stack(
                children: [
                  if (_holding)
                    Positioned.fill(
                      key: ValueKey('hold-$_holdN'),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1200),
                        builder: (_, v, _) => FractionallySizedBox(
                          alignment: Alignment.bottomCenter,
                          heightFactor: v,
                          child: const ColoredBox(color: Color(0x44F2C230)),
                        ),
                      ),
                    ),
                  if (open) Center(child: Icon(Icons.fingerprint_rounded, size: 26, color: const Color(0xFF9C8A6A).withValues(alpha: 0.6))),
                ],
              ),
      );
      if (!open) return box;
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _holdStart(),
        onPointerUp: (_) => _holdEnd(),
        onPointerCancel: (_) => _holdEnd(),
        child: Semantics(label: _L.colSign, child: box),
      );
    }

    final cells = <Widget>[
      Positioned.fromRect(
        key: const ValueKey('log-bg'),
        rect: page.inflate(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF7EC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF5A4A34), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
        ),
      ),
      for (final c in M8Col.values)
        Positioned.fromRect(
          key: ValueKey('head-${c.name}'),
          rect: head(c),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF9C8A6A)), color: const Color(0xFFEDE2C6)),
            child: Center(
              child: c == M8Col.sign && r.passes > 0 && open
                  ? fit(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text(name(c), style: label), for (var i = 0; i < math.min(r.passes, 3); i++) const Icon(Icons.check_rounded, size: 10, color: Color(0xFF2E7D32))],
                    ))
                  : fit(Text(name(c), style: label, textAlign: TextAlign.center)),
            ),
          ),
        ),
      for (var i = 0; i < earlierN; i++)
        for (final c in M8Col.values)
          Positioned.fromRect(
            key: ValueKey('earlier-$i-${c.name}'),
            rect: Rect.fromLTWH(head(c).left, (open ? M8PageGeo.earlier(i).top : geo.tray.top + 22), head(c).width, rowH),
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBBE9E))),
              child: Center(child: _earlierCell(r.deal.earlier[i], c, small)),
            ),
          ),
      for (final c in [M8Col.taken, M8Col.released])
        Positioned.fromRect(key: ValueKey('cell-${c.name}'), rect: today(c), child: timeCell(c)),
      Positioned.fromRect(key: const ValueKey('cell-work'), rect: today(M8Col.work), child: workCell()),
      Positioned.fromRect(key: const ValueKey('cell-sign'), rect: today(M8Col.sign), child: signCell()),
      if (open)
        Positioned.fromRect(
          key: const ValueKey('ruler'),
          rect: M8PageGeo.page.inflate(0),
          child: IgnorePointer(child: CustomPaint(painter: M8RulerPainter(y: _rulerY == null ? null : _rulerY! - M8PageGeo.top, count: _zones.length))),
        ),
      if (!open)
        Positioned.fromRect(
          key: const ValueKey('ptw-book'),
          rect: geo.ptwBook,
          child: _PtwBook(kept: r.keptInBook),
        ),
    ];
    if (!open) return Positioned.fill(key: const ValueKey('logbook-tray'), child: Stack(clipBehavior: Clip.none, children: cells));
    // The page: a finger down it is a read pass (the cells above keep their own taps).
    final reader = Positioned.fromRect(
      key: const ValueKey('reader'),
      rect: M8PageGeo.page,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        dragStartBehavior: DragStartBehavior.down,
        onVerticalDragStart: (d) => _passStart(M8PageGeo.top + d.localPosition.dy),
        onVerticalDragUpdate: (d) => _passMove(M8PageGeo.top + d.localPosition.dy, M8PageGeo.top + d.localPosition.dy - d.delta.dy),
        onVerticalDragEnd: (_) => _passEnd(_rulerY ?? 0),
        onVerticalDragCancel: () {
          _passFromY = null;
          _zones.clear();
          if (_rulerY != null) setState(() => _rulerY = null);
        },
      ),
    );
    return Positioned.fill(
      key: const ValueKey('logbook-open'),
      child: Stack(clipBehavior: Clip.none, children: [Positioned.fill(child: Stack(clipBehavior: Clip.none, children: cells)), reader]),
    );
  }

  Widget _earlierCell((String, int, int, M8Job) e, M8Col c, TextStyle small) {
    Widget fit(Widget w) => FittedBox(fit: BoxFit.scaleDown, child: w);
    return switch (c) {
      M8Col.taken => fit(Text('${enDigits(e.$1)} ${m8Clock(e.$2)}', style: small)),
      M8Col.released => fit(Text(m8Clock(e.$3), style: small)),
      M8Col.work => fit(Text(_L.job(e.$4), style: small)),
      M8Col.sign => const SizedBox(width: 44, height: 16, child: CustomPaint(painter: M8ScribblePainter(seed: 3))),
    };
  }

  // The strip at the tailgate: the crate's old parts, the docket card, the
  // carbon copy and the clock.
  List<Widget> _stripLayers(M8Geo geo) {
    final r = _run;
    Widget drag(int slot, M8Drag d, Widget chip, {bool enabled = true}) {
      return Positioned.fromRect(
        key: ValueKey('slot-$slot'),
        rect: geo.slot(slot),
        child: Draggable<M8Drag>(
          data: d,
          maxSimultaneousDrags: enabled && _canStamp ? 1 : 0,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _feedback(geo.slot(slot).size, chip),
          childWhenDragging: Opacity(opacity: 0.3, child: chip),
          child: chip,
        ),
      );
    }

    return [
      for (var i = 0; i < M8Job.values.length; i++)
        if (r.deal.done.contains(M8Job.values[i]) && !r.onPage.contains(M8Job.values[i]))
          drag(i, M8Drag(M8DragKind.part, M8Job.values[i]), _StripChip(label: _L.part(M8Job.values[i]), icon: Icons.build_circle_outlined)),
      if (!_docketUsed)
        drag(3, const M8Drag(M8DragKind.docket), _StripChip(label: _L.docket, sub: r.deal.docket.map(_L.job).join('\n'), icon: Icons.assignment_outlined)),
      drag(4, const M8Drag(M8DragKind.copyTime), _CopyCard(time: r.permitMin ?? r.now, usable: r.copyUsable, label: false), enabled: r.copyUsable),
      Positioned.fromRect(key: const ValueKey('slot-5'), rect: geo.slot(5), child: _clockDrag(geo.slot(5).size)),
    ];
  }

  bool get _docketUsed => _run.deal.docket.every(_run.onPage.contains);

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final replyDeck = _replyUp && _card == null;
    final deckUp = reasonOpen || coworkerChoiceUp || replyDeck;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_story;
    final phaseWaits = switch (_run.phase) {
      M8Phase.field || M8Phase.ready || M8Phase.copy || M8Phase.tailgate => true,
      M8Phase.moment => _run.deal.moment == M8Moment.note,
      _ => false,
    };
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
              labels: _L.permits,
              done: _done,
              current: _done.length < 4 ? _done.length : null,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && phaseWaits && !tableBusy && !_holding && _passFromY == null && _noteOff == Offset.zero,
            hintKey: '${_run.phase.name}/${_run.phoneLit}/${_run.passes}/$_steps/${_momentUp ? 1 : 0}',
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: const ValueKey('reply-deck'),
                                options: _replyOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _replyWrong,
                                picked: _replyPicked,
                                onPick: (o, at) => unawaited(_onReply(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
                  mistake: _card!,
                  tone: _cardTone,
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
                  line: _L.intro,
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

/// The dash clock: the time as it stands (a chip you can drag into the book).
class _ClockFace extends StatelessWidget {
  const _ClockFace({required this.value});
  final ValueListenable<int> value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _L.clockLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2F3A44), Color(0xFF1C2630)]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC9CED6), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 2))],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFFB8F0C0)),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<int>(
                    valueListenable: value,
                    builder: (_, v, _) => Text(m8Clock(v), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFB8F0C0), decoration: TextDecoration.none)),
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

/// The phone on the dash: dark until it lights; its screen carries only the
/// worker's words.
class _PhoneChip extends StatelessWidget {
  const _PhoneChip({required this.text, required this.quiet});
  final String? text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final on = text != null;
    final chip = Semantics(
      label: _L.phoneLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: on ? const Color(0xFFFFF3C4) : const Color(0xFF26303D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? const Color(0xFFF2C230) : const Color(0xFF55606A), width: 2),
          boxShadow: on ? const [BoxShadow(color: Color(0x88F2C230), blurRadius: 10)] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            children: [
              Icon(Icons.phone_android_rounded, size: 18, color: on ? const Color(0xFF8A4A00) : const Color(0xFF8C97A2)),
              const SizedBox(width: 4),
              Expanded(
                child: on
                    ? Text(text!, maxLines: 2, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A00)))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
    if (quiet || !on) return chip;
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Transform.scale(scale: v, child: c),
      child: chip,
    );
  }
}

/// The permit handed out at the window: the signed sheet with its carbon copy.
class _PermitCard extends StatelessWidget {
  const _PermitCard({required this.time, required this.out, required this.quiet});
  final int time;
  final bool out;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final sheet = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7EC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF9C8A6A), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('PTW', style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF8A2A16))),
                    const SizedBox(height: 2),
                    Text(m8Clock(time), style: bangla(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1A3A8A))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            const SizedBox(width: 48, height: 30, child: CustomPaint(painter: M8ScribblePainter(seed: 11))),
          ],
        ),
      ),
    );
    if (quiet) return sheet;
    return TweenAnimationBuilder<double>(
      key: ValueKey(out),
      tween: Tween(begin: out ? 1 : 0, end: out ? 0 : 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Transform.translate(offset: Offset(0, -26 * (1 - v)), child: Opacity(opacity: 0.4 + 0.6 * v, child: c)),
      child: sheet,
    );
  }
}

/// A figure's speech bubble (text only, no voice, M8-10).
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final b = Align(
      alignment: Alignment.bottomLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5E8DB6), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 5, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(text, maxLines: 3, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1C2A3A))),
        ),
      ),
    );
    if (quiet) return b;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (_, v, c) => Transform.scale(scale: v, alignment: Alignment.bottomLeft, child: c),
      child: b,
    );
  }
}

/// A place the copy may go (a labelled tile; nothing marks the right one).
class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.hot});
  final M8Place place;
  final bool hot;

  IconData get _icon => switch (place) {
        M8Place.book => Icons.menu_book_rounded,
        M8Place.doorPocket => Icons.door_front_door_outlined,
        M8Place.toolbox => Icons.home_repair_service_rounded,
        M8Place.dash => Icons.speed_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _L.place(place),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hot ? const Color(0xFFFFF3C4) : const Color(0xFFEDE2C6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hot ? const Color(0xFFC48A2E) : const Color(0xFF5A4A34), width: hot ? 3 : 2),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 22, color: const Color(0xFF5A4A34)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(_L.place(place), style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A18)))),
          ],
        ),
      ),
    );
  }
}

/// The carbon copy (blue-grey tissue with the permit time).
class _CopyCard extends StatelessWidget {
  const _CopyCard({required this.time, required this.usable, required this.label});
  final int time;
  final bool usable;

  /// The label under the time (the copy in hand) or only the time (the strip).
  final bool label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _L.carbonCopy,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: usable ? const Color(0xFFDCE6F2) : const Color(0xFFC9C2A8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: usable ? const Color(0xFF3A5A8A) : const Color(0xFF7A6A40), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(_L.carbonCopy, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: usable ? const Color(0xFF1A3A6A) : const Color(0xFF5A4A20)))),
            const SizedBox(height: 2),
            Text(usable ? m8Clock(time) : '···', style: bangla(fontSize: label ? 18 : 14, fontWeight: FontWeight.w900, color: usable ? const Color(0xFF1A3A8A) : const Color(0xFF7A6A40))),
          ],
        ),
      ),
    );
  }
}

/// A part from the crate, the docket card: a chip in the strip.
class _StripChip extends StatelessWidget {
  const _StripChip({required this.label, required this.icon, this.sub});
  final String label;
  final String? sub;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFEDE2C6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF5A4A34), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF5A4A34)),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, textAlign: TextAlign.center, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A18))))),
              if (sub != null) Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(sub!, textAlign: TextAlign.center, style: bangla(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF5A4A34))))),
            ],
          ),
        ),
      ),
    );
  }
}

/// The PTW book in the tray (a carbon edge peeks out once the copy is kept).
class _PtwBook extends StatelessWidget {
  const _PtwBook({required this.kept});
  final bool kept;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _L.ptwBook,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF3C5A78),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1F3548), width: 2),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFFE8D9B0)),
                const SizedBox(width: 6),
                Text(_L.ptwBook, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFE8D9B0))),
                if (kept) ...[const SizedBox(width: 6), Container(width: 14, height: 22, color: const Color(0xFFDCE6F2))],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
