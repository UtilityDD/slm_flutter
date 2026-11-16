import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'm8_chain_throw_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_chain_throw_world.dart'
    show M8ChainAt, M8ChainKind, M8EndGeo, M8EndSpec, M8Geo, M8Held, M8Key, M8Station, M8Throw, M8ThrowKind, M8TrayItem, m8ChainGood, m8FlickFor, m8ThrowOf;

// Lesson 8.5 "সেফটি কোড (Safety Code): সুরক্ষার স্থানীয় আইন", কাজ "দুই প্রান্তে
// কবচ — রড, তারপর চেইন" (pack do_8_5_b, engineType m8_chain_throw; rulings
// M8-1, M8-5, M8-8, M8-14, M8-15, M8-17, X1, X2, X6, X7). A shut-down 11 kV
// village span; the player builds his own protection, from the lock to the
// chain, and takes it down again when the crew gives clearance.
//
// Core verb (the lesson's 'বল-চেইন ছোড়া'): FLICK-THROW a ball-chain up over
// the three phases. The flick's length is the strength, its angle the aim:
// too short and it falls back, too strong and it slides off the far side;
// near the edges of the range or aimed off it lies on one or two phases;
// right in the middle, aimed over the pole, it drapes all three (a free
// retry every time it misses).
//
// The substation. The breaker handle stands at OFF. Drag the padlock from the
// bench onto the handle and the 'কাজ চলছে' board onto it; the key pops out:
// drag it to your own shirt pocket (the key-hook board and the operator's
// open hand are on screen too: R11 slip). Leaving with no padlock or no
// board = slip (R12), once each.
//
// The span (walk with the arrows, left and right). At each end, in any order:
//  * the tester (until the line is proved; M8-17, X1): touch the proving unit
//    (LIVE), the line (0 V), the proving unit again (LIVE). The line read
//    without the proof first = slip (N3, once); an earth (the rod) before
//    0 V = slip (N2, once; the rod comes back); before the second proof =
//    slip (N3b).
//  * the rod set: drag the earth clamp onto the spike; drag the rod up to the
//    line and hold until it has drained (a ring fills). The hook to the line
//    before the clamp is on the spike = DEADLY (R5).
//  * the chain bag: pull the chain out hand over hand (three upward drags);
//    rust, a broken link, a bent hook or grey iron show as the links pass the
//    fist. The bad one goes in the বাতিল crate (the van's spare comes) or it
//    is thrown: a rusty / broken / bent / iron chain thrown after the rod =
//    slip (R13). The chain thrown at an end before that end's rod has drained
//    = DEADLY (R4; the coworker's myth 3 pushes exactly that, so listening is
//    the same deadly: X2/B1). A chain on one or two phases is tugged down
//    (a downward drag on its tail) and thrown again, free.
//  * 'উঠি' at the work pole is live from the start: with the tester not
//    shown 0 V = DEADLY (N1); with the rod missing at either end = DEADLY
//    (R3); a chain on one or two phases (walking on from the end, or the
//    climb) or skipped at an end = slip (R14), once each per end.
//  * The close: the job cutaway (~3 s), then the mate comes down; at his wave
//    (clearance) tug each chain down. Tugging before clearance = slip (R15,
//    once; the chain goes back up); the early-removal coworker pushes exactly
//    that (listening = that slip).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the full
// scene (m8_chain_throw_world.dart), corner guide, ◆ on the table → "কেন …?"
// for the key, the tester, a swapped chain, the first finished end (rod then
// chain) and the second (both ends); the coworker once a play with two beats,
// his control held (the first kit touch at his end; or the chain tails);
// gesture hands that show how, never what.

// ============================================================================
// Content
// ============================================================================

/// The coworker's push (one per play): myth 3 of lesson 8.5 at one end, or
/// the early removal in the close.
enum M8Push { myth, early }

/// What a reason asks about (fits what the player just did).
enum M8Why { key, tester, order, both, swap }

/// What the open phase of the play is.
enum M8Phase { sub, field, job, close, done }

/// Where the tester touches.
enum M8TestAt { prover, line }

/// What leaving the substation did.
enum M8Leave { done, keyFirst, slip, again }

/// What a try at the rod's hook did.
enum M8Hook { hooked, deadly, slip, again }

/// What a throw did.
enum M8ThrowRes { none, deadly, slip, again, short, over, beside, partial, full }

/// What the climb did.
enum M8Climb { ok, deadly, slip, again }

/// What walking from an end did.
enum M8Walk { ok, slip, again }

/// What a tug on a chain tail did.
enum M8Tug { back, down, slip, again, none }

/// What a drag from the bench onto the handle did.
enum M8Drop { padlock, board, needless, none }

/// What a chain thrown in the crate was.
enum M8Discard { right, needless, none }

abstract final class M8ChainLines {
  static const title = 'দুই প্রান্তে কবচ';
  // DRAFT wording — owner (M6-12 / M8-14): every line below until the owner
  // words it. The opening is the spec's.
  static const intro = 'শাটডাউন পেয়েছেন। আইন মেনে নিজের কবচ নিজে বানান—তালা থেকে চেইন পর্যন্ত।';

  // The guide's task now (tap him: the same task, a different way).
  static const askLock = 'ব্রেকারের হ্যান্ডেলে নিজের তালা আর বোর্ড লাগান।';
  static const askKey = 'চাবিটা কোথায় রাখবেন, ঠিক করুন।';
  static const askLeave = 'এবার কাজের পোলের দিকে চলুন।';
  static const askWalk = 'কোন প্রান্তে আগে যাবেন, ঠিক করুন।';
  static const askEnd = 'এই প্রান্তে নিজের কবচ বানান।';
  static const askClimb = 'দুই প্রান্ত তৈরি কি না, দেখে নিন।';
  static const askClose = 'কাজ শেষ। এবার কী করবেন?';
  static List<String> get tasks => [askLock, askKey, askLeave, askWalk, askEnd, askClimb, askClose];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Guards (no cost) and what happened.
  static const decoy = 'ওটা এখানে লাগে না।';
  static const keyFirst = 'আগে চাবিটা সরিয়ে রাখুন।';
  static const fellShort = 'চেইন নিচে পড়ে গেল।';
  static const slidOff = 'চেইন ওপারে গড়িয়ে গেল।';
  static const beside = 'চেইন তারে পড়ল না।';
  static const van = 'ভ্যান থেকে নতুন চেইন এল।';
  static const needlessDiscard = 'চেইনটা ঠিকই ছিল — শুধু সময় গেল।';

  /// A slip refused again (already scored once): no second slip.
  static String again(DoMistake m) => switch (m.key) {
        _ when m == M8ChainMistakes.noPadlock => 'আগে হ্যান্ডেলে তালা লাগান।',
        _ when m == M8ChainMistakes.noBoard => 'আগে কাজ চলছে বোর্ডটা ঝোলান।',
        _ when m == M8ChainMistakes.keyNotPocket => 'চাবি আগে নিজের পকেটে রাখুন।',
        _ when m == M8ChainMistakes.rodEarly => 'আগে টেস্টারে লাইন দেখুন, তারপর রড।',
        _ when m == M8ChainMistakes.testerUnproved => 'আগে টেস্টার প্রুভিং ইউনিটে ছোঁয়ান।',
        _ when m == M8ChainMistakes.testerNotRechecked => 'রডের আগে টেস্টার আবার প্রুভিং ইউনিটে ছোঁয়ান।',
        _ when m == M8ChainMistakes.chainPartial => 'চেইনটা তিন ফেজেই ফেলতে হবে।',
        _ when m == M8ChainMistakes.chainSkipped => 'এক প্রান্তে চেইন বাকি আছে।',
        _ => 'ক্লিয়ারেন্স না পাওয়া পর্যন্ত চেইন রাখুন।',
      };
  static List<String> get allAgain => [
        for (final m in [
          M8ChainMistakes.noPadlock,
          M8ChainMistakes.noBoard,
          M8ChainMistakes.keyNotPocket,
          M8ChainMistakes.rodEarly,
          M8ChainMistakes.testerUnproved,
          M8ChainMistakes.testerNotRechecked,
          M8ChainMistakes.chainPartial,
          M8ChainMistakes.chainSkipped,
          M8ChainMistakes.tugEarly,
        ])
          again(m),
      ];

  // What a worker reads on site (not spoken).
  static const sceneLabel = 'সেফটি কোড';
  static const boardText = 'কাজ চলছে';
  static const docket = 'কাজের পোল';
  static const crate = 'বাতিল';
  static const feeder = 'ফিডার ব্রেকার';
  static const leave = 'পোলের দিকে চলুন';
  static const walkLeft = 'বাঁ প্রান্ত';
  static const walkRight = 'ডান প্রান্ত';
  static const walkBack = 'কাজের পোলে ফিরি';
  static const climb = 'উঠি';
  static const progressLabels = ['তালা-চাবি', 'বাঁ প্রান্ত', 'ডান প্রান্ত', 'নামানো'];
  static const live = 'LIVE';
  static const zero = '0 V';
  static const none = '- - -';

  // The reasons: the spec's four questions and one new (the tester). DRAFT.
  static const whyQ = <M8Why, String>{
    M8Why.key: 'চাবি কেন নিজের পকেটে?',
    M8Why.tester: 'টেস্টার আগে আর পরে লাইভে কেন ছোঁয়ালেন?',
    M8Why.order: 'কেন আগে রড, পরে চেইন?',
    M8Why.both: 'কেন দুই প্রান্তেই আর্থ দিলেন?',
    M8Why.swap: 'কেন চেইনটা বদলালেন?',
  };
  static const whyRight = <M8Why, List<String>>{
    M8Why.key: ['ভুল করে কেউ যেন ব্রেকার ON করে না দেয়', 'নিজের তালা, নিজের চাবি—জীবন আমার পকেটে'],
    M8Why.tester: ['টেস্টার ঠিক আছে কি না, আগে-পরে যাচাই', 'খারাপ টেস্টারও চালু লাইনকে ডেড দেখায়'],
    M8Why.order: ['চেইন ফেজ শর্ট করে, রড চার্জ নামায়', 'শর্ট সার্কিট আর আর্থিং এক জিনিস নয়'],
    M8Why.both: ['কাজের জায়গার আগে ও পরে আর্থিং আইনে বাধ্যতামূলক', 'ব্যাক-ফিডিং বা ইন্ডাকশন থেকে বাঁচতে দুদিকেই আর্থ'],
    M8Why.swap: ['মরিচা, ভাঙা বা লোহার জুগাড় চেইন বারণ', 'বল, লিঙ্ক বা হুকে সন্দেহ হলে ওঠার আগেই বদলাই'],
  };
  static const whyWrong = <M8Why, List<String>>{
    M8Why.key: [
      'অপারেটর পাশেই থাকে, চাবি ওর হাতেই নিরাপদ',
      'হুকে ঝুলিয়ে রাখলে চাবি কখনো হারায় না',
      'তালা লাগানো থাকলে চাবি কোথায়, কিছু আসে যায় না',
      'চাবি পকেটে রাখাটা একটা পুরনো অভ্যাস মাত্র',
      'ডিউটি শেষে চাবি বোর্ডে ফেরত রাখাই নিয়ম',
    ],
    M8Why.tester: [
      'লাইন বন্ধ বলেছে মানেই ডেড, টেস্ট বাড়তি',
      'টেস্টার একবার ছোঁয়ালেই সবটা বোঝা যায়',
      'লাইভে ছোঁয়ালে টেস্টারের ব্যাটারি ক্ষয় হয়',
      'অভিজ্ঞ লাইনম্যান টেস্টার ছাড়াই ডেড বোঝে',
      'আগে-পরে ছোঁয়ালে শুধু সময় নষ্ট হয়',
    ],
    M8Why.order: [
      'চেইন ছুঁড়লে রডের কাজও হয়ে যায়',
      'রড ভারী বলে তাকে পরে লাগালেও চলে',
      'চেইন আগে দিলে স্পার্ক অনেক কম হয়',
      'লাইন তো বন্ধ, ক্রম নিয়ে চিন্তা নেই',
      'অভিজ্ঞ লাইনম্যানরা চেইনই আগে দেয়',
    ],
    M8Why.both: [
      'এক প্রান্তে আর্থ দিলেই পুরো লাইন আর্থ হয়ে যায়',
      'দুই প্রান্তে দিলে ব্রেকার কখনো ON হতে পারে না',
      'দুই দিকে না দিলে সুপারভাইজার বকবে, তাই দিলাম',
      'লাইন ডেড বলেছে, বাড়তি আর্থ শুধু নিয়ম রক্ষা',
      'আর্থ রড হাতে ছিল, তাই দুদিকেই লাগিয়ে দিলাম',
    ],
    M8Why.swap: [
      'নতুন চেইন সব সময় বেশি জোরে ছোঁড়া যায়',
      'মরিচা ধরা চেইনও চলে, শুধু একটু ভারী হয়',
      'লোহার চেইনে স্পার্ক বেশি হয় না, সস্তাও',
      'ভাঙা লিঙ্ক থাকলেও চেইন শুধু ঝুলে থাকে',
      'ভ্যান থেকে বদলে আনলে একটু বিশ্রাম মেলে',
    ],
  };
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play). Myth 3 of lesson 8.5 word for
  // word (M8-14); the early removal is his DRAFT line.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerMyth = CoworkerScript(
    line: 'চেইন ছুঁড়লেই আর্থিং হয়ে গেল—ডিসচার্জ রডের দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, আগে রড—শর্ট আর আর্থিং এক নয়।', 'রড চার্জ নামায়, চেইন ফেজ শর্ট করে।', 'না, রডের বদলি নেই—আগে রড, পরে চেইন।'],
    wrong: [
      'ঠিক আছে, চেইনটাই ছুঁড়ে দিচ্ছি।',
      'চেইন ছুঁড়লেই তো হবে, রড থাক গে।',
      'আচ্ছা, তাহলে রড ছাড়াই চেইন দিই।',
      'হ্যাঁ, চেইনেই আর্থিং হয়ে যায়।',
      'ঠিক আছে, রডের ঝামেলা বাদ দিলাম।',
    ],
    asks: ['কী করবেন?', 'ও বলছে চেইনেই চলবে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerEarly = CoworkerScript(
    line: 'কাজ তো শেষ, চেইনগুলো টেনে নামাও—দাঁড়িয়ে আছ কেন?',
    exitLine: coworkerExit,
    right: ['না, ক্লিয়ারেন্স না পেলে চেইন থাকবে।', 'ক্লিয়ারেন্স না পেলে চেইন নামবে না।', 'না, সাথী নামুক, তারপর চেইন নামাব।'],
    wrong: [
      'ঠিক আছে, এখনই টেনে নামিয়ে দিই।',
      'হ্যাঁ, কাজ শেষ, চেইন নামিয়ে ফেলি।',
      'আচ্ছা, আর দেরি না করে টেনে নামাই।',
      'ঠিক বলেছ, চেইনের আর দরকার নেই।',
      'হ্যাঁ, এখনই চেইনগুলো সব খুলে ফেলি।',
    ],
    asks: ['কী করবেন?', 'ও বলছে এখনই নামাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M8Push p) => p == M8Push.myth ? coworkerMyth : coworkerEarly;
  static const allCoworkers = [coworkerMyth, coworkerEarly];

  static String callHeld(M8Push p) => p == M8Push.myth ? 'ঠিক! শর্ট সার্কিট আর আর্থিং এক নয়—আগে রড।' : 'ঠিক! ক্লিয়ারেন্স না পাওয়া পর্যন্ত চেইন থাকবে।';

  static const allSet = 'দুই প্রান্তে কবচ, চাবি নিজের পকেটে—নিয়ম মেনে কাজ।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে লাইন যাচাই, রড, তারপর চেইন, দুই প্রান্তেই।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtLock = 'তালা আর বোর্ড লাগিয়েছেন';
  static const caughtKey = 'চাবি নিজের পকেটে';
  static const caughtTester = 'টেস্টারে লাইভ-ডেড-লাইভ';
  static const caughtRod = 'দুই প্রান্তে আগে রড';
  static const caughtChain = 'চেইন তিন ফেজেই';
  static const caughtSwap = 'খারাপ চেইন বদলেছেন';
  static const caughtWait = 'ক্লিয়ারেন্সের পরে চেইন নামিয়েছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';
  static const caughtAll = [caughtLock, caughtKey, caughtTester, caughtRod, caughtChain, caughtSwap, caughtWait, caughtCall];

  /// The coworker's pushes (myth 3 word for word; to record in his voice with
  /// tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        ...tapWhy,
        decoy,
        keyFirst,
        fellShort,
        slidOff,
        beside,
        van,
        needlessDiscard,
        ...allAgain,
        ...{...whyQ.values},
        for (final c in allCoworkers) ...c.asks,
        for (final p in M8Push.values) callHeld(p),
        allSet,
        quick,
        fail,
        deadlyWord,
        nearMissWord,
        for (final m in M8ChainMistakes.all) m.textBn,
      }.toList();
}

abstract final class M8ChainMistakes {
  static const _dir = 'assets/game/art/m8_chain_throw';
  static const _k = '8.5/m8_chain_throw';

  // DRAFT wording — owner (M6-12). Lesson points (0-based, flattened): 1 LOTO,
  // 4 chain / temporary earthing, 5 the brass/copper chain's do and don't.

  // --- deadly ---------------------------------------------------------------
  static const chainFirst = DoMistake(
    key: '$_k/chain-first',
    textBn: 'রডের আগে চেইন ছোঁড়া! চেইন শুধু ফেজ শর্ট করে, চার্জ নামায় না। আগে ডিসচার্জ রড, তারপর চেইন।',
    art: '$_dir/chain_first.svg',
    deadly: true,
    lessonPoint: 4,
  );
  static const pushChain = DoMistake(
    key: '$_k/push-chain',
    textBn: 'ওর কথায় রড ছাড়াই চেইন ছুঁড়লেন! শর্ট সার্কিট ≠ আর্থিং—চেইন রডের বদলি নয়।',
    art: '$_dir/chain_first.svg',
    deadly: true,
    lessonPoint: 4,
  );
  static const climbNoRod = DoMistake(
    key: '$_k/climb-no-rod',
    textBn: 'এক প্রান্তে রড আর্থ নেই, তবু পোলে উঠলেন! কাজের জায়গার আগে ও পরে—দুই প্রান্তেই আর্থ চাই।',
    art: '$_dir/climb_no_rod.svg',
    deadly: true,
    lessonPoint: 4,
  );
  static const climbNoZero = DoMistake(
    key: '$_k/climb-no-zero',
    textBn: 'টেস্টারে 0 V না দেখেই পোলে উঠলেন! Dead লাইনকেও Live মনে করুন—আগে টেস্টার, তারপর আর্থ, তারপর পোল।',
    art: '$_dir/climb_no_zero.svg',
    deadly: true,
    lessonPoint: 4,
  );
  static const hookFirst = DoMistake(
    key: '$_k/hook-first',
    textBn: 'আর্থ ক্ল্যাম্প স্পাইকে না লাগিয়ে রডের হুক লাইনে তুললেন! চার্জ নামার পথ না থাকলে রডেই কারেন্ট। আগে ক্ল্যাম্প, তারপর হুক।',
    art: '$_dir/hook_first.svg',
    deadly: true,
    lessonPoint: 4,
  );

  // --- slips ----------------------------------------------------------------
  static const keyNotPocket = DoMistake(
    key: '$_k/key-not-pocket',
    textBn: 'চাবি নিজের পকেটে নয়! নিজের তালা, নিজের চাবি—আপনার জীবন আপনার পকেটে।',
    art: '$_dir/key_pocket.svg',
    lessonPoint: 1,
  );
  static const noPadlock = DoMistake(
    key: '$_k/no-padlock',
    textBn: 'হ্যান্ডেলে তালা ছাড়াই চলে এলেন! ব্রেকার OFF করে তালা লাগানো বাধ্যতামূলক।',
    art: '$_dir/no_padlock.svg',
    lessonPoint: 1,
  );
  static const noBoard = DoMistake(
    key: '$_k/no-board',
    textBn: 'হ্যান্ডেলে কাজ চলছে বোর্ড ঝোলাননি! তালার সঙ্গে বোর্ডও চাই।',
    art: '$_dir/no_board.svg',
    lessonPoint: 1,
  );
  static const badChain = DoMistake(
    key: '$_k/bad-chain',
    textBn: 'এই চেইন চলবে না—মরিচা, ভাঙা লিঙ্ক, বাঁকা হুক বা লোহার জুগাড় চেইন বারণ। ছোঁড়ার আগে বল, লিঙ্ক আর হুক দেখুন।',
    art: '$_dir/bad_chain.svg',
    lessonPoint: 5,
  );
  static const chainPartial = DoMistake(
    key: '$_k/chain-partial',
    textBn: 'চেইন মাত্র একটা বা দুটো ফেজে পড়েছে! তিন ফেজেই না থাকলে ফেজ শর্ট হয় না। টেনে নামিয়ে আবার ছুঁড়ুন।',
    art: '$_dir/chain_partial.svg',
    lessonPoint: 4,
  );
  static const chainSkipped = DoMistake(
    key: '$_k/chain-skipped',
    textBn: 'এক প্রান্তে চেইন ছোঁড়া বাকি! এই কাজে ডকেটে রডের সঙ্গে চেইনও লেখা—দুই প্রান্তেই।',
    art: '$_dir/chain_skipped.svg',
    lessonPoint: 4,
  );
  static const tugEarly = DoMistake(
    key: '$_k/tug-early',
    textBn: 'ক্লিয়ারেন্স পাওয়ার আগে চেইন নামালেন! সাথী এখনও পোলে—ক্লিয়ারেন্স না পাওয়া পর্যন্ত চেইন রাখুন।',
    art: '$_dir/tug_early.svg',
    lessonPoint: 5,
  );
  static const rodEarly = DoMistake(
    key: '$_k/rod-early',
    textBn: 'আগে টেস্টারে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক।',
    art: '$_dir/rod_early.svg',
    lessonPoint: 4,
  );
  static const testerUnproved = DoMistake(
    key: '$_k/tester-unproved',
    textBn: 'টেস্টার আগে জানা লাইভ পয়েন্টে যাচাই করেননি! খারাপ টেস্টারও চালু লাইনকে ডেড দেখায়।',
    art: '$_dir/tester.svg',
    lessonPoint: 5,
  );
  static const testerNotRechecked = DoMistake(
    key: '$_k/tester-not-rechecked',
    textBn: 'টেস্টের পরে টেস্টার আবার লাইভে দেখেননি। মাঝপথে বিগড়ালে 0 V-র কোনো ভরসা নেই।',
    art: '$_dir/tester.svg',
    lessonPoint: 5,
  );

  /// Listening to his push is the act he pushes (X2/B1).
  static DoMistake push(M8Push p) => p == M8Push.myth ? pushChain : tugEarly;

  static const List<DoMistake> all = [
    chainFirst,
    pushChain,
    climbNoRod,
    climbNoZero,
    hookFirst,
    keyNotPocket,
    noPadlock,
    noBoard,
    badChain,
    chainPartial,
    chainSkipped,
    tugEarly,
    rodEarly,
    testerUnproved,
    testerNotRechecked,
  ];

  /// The catalog's deadlyRules for do_8_5_b.
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

// ============================================================================
// The deal
// ============================================================================

/// One end as dealt: its geometry, the chain in its bag and where the defect is.
@immutable
class M8EndDeal {
  const M8EndDeal({required this.spec, required this.chain, required this.defectSeg});
  final M8EndSpec spec;
  final M8ChainKind chain;
  final int defectSeg;
}

@immutable
class M8Deal {
  const M8Deal({
    required this.ends,
    required this.tray,
    required this.push,
    required this.coworkerEnd,
    required this.mateMs,
    required this.spare,
  });

  final List<M8EndDeal> ends;

  /// The bench tray's four slots (padlock, board, two decoys).
  final List<M8TrayItem> tray;
  final M8Push push;

  /// The end the myth's coworker is dealt to (0 left, 1 right).
  final int coworkerEnd;

  /// How long the mate takes to come down (ms).
  final int mateMs;

  /// The van's spare chain (always good).
  final M8ChainKind spare;
}

const _badKinds = [M8ChainKind.rusty, M8ChainKind.broken, M8ChainKind.bentHook, M8ChainKind.iron];

M8Deal m8ChainDeal(math.Random rng) {
  final bad = rng.nextInt(2);
  M8ChainKind good() => rng.nextBool() ? M8ChainKind.brass : M8ChainKind.copper;
  M8EndDeal end(int i) {
    final kind = i == bad ? _badKinds[rng.nextInt(_badKinds.length)] : good();
    return M8EndDeal(
      spec: M8EndSpec(
        mirrored: rng.nextBool(),
        standDx: (40 + rng.nextInt(41)).toDouble(),
        condF: (6 + rng.nextInt(13)) / 100,
        spread: (24 + rng.nextInt(13)).toDouble(),
        raise: rng.nextInt(3) == 0 ? 14 : 0,
      ),
      chain: kind,
      defectSeg: kind == M8ChainKind.bentHook ? 2 : rng.nextInt(3),
    );
  }

  final decoys = [M8TrayItem.torch, M8TrayItem.tape, M8TrayItem.fuse, M8TrayItem.rag]..shuffle(rng);
  return M8Deal(
    ends: [end(0), end(1)],
    tray: [M8TrayItem.padlock, M8TrayItem.board, decoys[0], decoys[1]]..shuffle(rng),
    push: rng.nextInt(3) < 2 ? M8Push.myth : M8Push.early,
    coworkerEnd: rng.nextInt(2),
    mateMs: 5000 + rng.nextInt(3501),
    spare: good(),
  );
}

// ============================================================================
// The play (pure logic)
// ============================================================================

class M8EndState {
  M8EndState(this.deal) : chain = deal.chain;
  final M8EndDeal deal;

  var clamped = false;
  double? hookX;
  var drained = false;
  int pulled = 0;
  M8ChainKind chain;
  var at = M8ChainAt.bag;
  int lo = 0;
  int hi = 2;
  M8ChainKind? crate;
  var swapped = false;
  var wasted = false;
  var touched = false;
  var finished = false;

  /// Slips at this end (its thorough bonus).
  int slips = 0;

  bool get chainFull => at == M8ChainAt.line && hi - lo == 2;
  bool get done => drained && chainFull;
  bool get thorough => slips == 0 && !wasted;
}

class M8ChainRun {
  M8ChainRun(this.deal) {
    tray = [for (final t in deal.tray) t];
    ends = [for (final e in deal.ends) M8EndState(e)];
  }
  final M8Deal deal;
  late final List<M8TrayItem?> tray;
  late final List<M8EndState> ends;

  var station = M8Station.sub;
  var phase = M8Phase.sub;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // The substation.
  var padlock = false;
  var board = false;
  var key = M8Key.inLock;

  // The tester (live, dead, live).
  var liveBefore = false;
  var zero = false;
  var liveAfter = false;
  String reading = M8ChainLines.none;

  /// Reasons already asked (each deck once a play) and the order of finished ends.
  final Set<M8Why> asked = {};
  int finishedEnds = 0;

  // The close.
  var cleared = false;

  /// The slips scored (a kind once per place).
  final Set<String> _once = {};

  bool get proofDone => zero && liveAfter;
  bool get ended => phase == M8Phase.done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => phase == M8Phase.done && deadly == null && percent >= 55;
  bool get atEnd => station == M8Station.endA || station == M8Station.endB;
  int get endIndex => station == M8Station.endB ? 1 : 0;

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  /// A slip of [m] (once per [place]: null = the play, else an end): true when it counts now.
  bool slipOnce(DoMistake m, {int? place}) {
    final k = '${m.key}/${place ?? -1}';
    if (_once.contains(k)) return false;
    _once.add(k);
    slips++;
    if (place != null && place >= 0) ends[place].slips++;
    return true;
  }

  bool slipped(DoMistake m, {int? place}) => _once.contains('${m.key}/${place ?? -1}');

  // --- the substation ---------------------------------------------------------
  /// The tray item in [slot] dragged onto the handle.
  M8Drop dropItem(int slot) {
    if (ended || phase != M8Phase.sub || slot < 0 || slot > 3) return M8Drop.none;
    final it = tray[slot];
    if (it == null) return M8Drop.none;
    switch (it) {
      case M8TrayItem.padlock:
        padlock = true;
        key = M8Key.popped;
        tray[slot] = null;
        return M8Drop.padlock;
      case M8TrayItem.board:
        board = true;
        tray[slot] = null;
        return M8Drop.board;
      default:
        return M8Drop.needless;
    }
  }

  /// The key put in [where] (pocket, hook board or the operator's hand). The
  /// pocket is right; the others are a slip (once) and the key stays out.
  ({bool ok, DoMistake? slip, bool again}) placeKey(M8Key where) {
    if (ended || key != M8Key.popped || where == M8Key.popped || where == M8Key.inLock) return (ok: false, slip: null, again: false);
    if (where == M8Key.pocket) {
      key = M8Key.pocket;
      _tag(M8ChainLines.caughtKey);
      return (ok: true, slip: null, again: false);
    }
    if (slipOnce(M8ChainMistakes.keyNotPocket)) return (ok: false, slip: M8ChainMistakes.keyNotPocket, again: false);
    return (ok: false, slip: null, again: true);
  }

  /// Leave for the span: the key out of the lock first (a guard), a missing
  /// padlock or board a slip (each once), then off to the work pole.
  ({M8Leave res, DoMistake? slip}) leave() {
    if (ended || phase != M8Phase.sub) return (res: M8Leave.done, slip: null);
    if (key == M8Key.popped) return (res: M8Leave.keyFirst, slip: null);
    for (final (missing, m) in [(!padlock, M8ChainMistakes.noPadlock), (!board, M8ChainMistakes.noBoard)]) {
      if (missing) {
        return slipOnce(m) ? (res: M8Leave.slip, slip: m) : (res: M8Leave.again, slip: m);
      }
    }
    _tag(M8ChainLines.caughtLock);
    phase = M8Phase.field;
    station = M8Station.work;
    return (res: M8Leave.done, slip: null);
  }

  // --- walking ----------------------------------------------------------------
  /// Walk to [to] (work ↔ an end). Leaving an end with its rod on and its chain
  /// on one or two phases is a slip (once an end): the player stays.
  ({M8Walk res, DoMistake? slip}) go(M8Station to) {
    if (ended || phase == M8Phase.sub || phase == M8Phase.job || to == M8Station.sub) return (res: M8Walk.ok, slip: null);
    if (atEnd) {
      final e = ends[endIndex];
      if (e.drained && e.at == M8ChainAt.line && !e.chainFull && phase == M8Phase.field) {
        final m = M8ChainMistakes.chainPartial;
        return slipOnce(m, place: endIndex) ? (res: M8Walk.slip, slip: m) : (res: M8Walk.again, slip: m);
      }
      if (to != M8Station.work) return (res: M8Walk.ok, slip: null);
    } else if (to == M8Station.work) {
      return (res: M8Walk.ok, slip: null);
    }
    station = to;
    return (res: M8Walk.ok, slip: null);
  }

  /// A walk that [go] allowed is done: the station changes.
  void arrive(M8Station to) => station = to;

  // --- the tester ---------------------------------------------------------------
  /// The tester on [at]: its reading, a slip (the line read without the proof
  /// first; once), and whether this touch completed live → 0 V → live.
  ({String reading, DoMistake? mistake, bool again, bool provenNow}) test(M8TestAt at) {
    if (ended || phase != M8Phase.field || proofDone) return (reading: reading, mistake: null, again: false, provenNow: false);
    if (at == M8TestAt.prover) {
      if (zero && !liveAfter) {
        liveAfter = true;
        reading = M8ChainLines.live;
        _tag(M8ChainLines.caughtTester);
        return (reading: reading, mistake: null, again: false, provenNow: true);
      }
      if (!zero) liveBefore = true;
      reading = M8ChainLines.live;
      return (reading: reading, mistake: null, again: false, provenNow: false);
    }
    reading = M8ChainLines.zero;
    if (zero) return (reading: reading, mistake: null, again: false, provenNow: false);
    if (!liveBefore) {
      final first = slipOnce(M8ChainMistakes.testerUnproved);
      return (reading: reading, mistake: first ? M8ChainMistakes.testerUnproved : null, again: !first, provenNow: false);
    }
    zero = true;
    return (reading: reading, mistake: null, again: false, provenNow: false);
  }

  // --- the rod ------------------------------------------------------------------
  bool setClamp(int e) {
    if (ended || phase != M8Phase.field || ends[e].clamped) return false;
    ends[e].clamped = true;
    ends[e].touched = true;
    return true;
  }

  /// The rod's hook reaches the line at [x]: before the clamp = deadly (R5);
  /// before 0 V (N2) or before the second proof (N3b) = a slip (once; the rod
  /// comes back); else it is on the line and has to drain.
  ({M8Hook res, DoMistake? mistake}) hookRod(int e, double x) {
    final s = ends[e];
    if (ended || phase != M8Phase.field || s.hookX != null) return (res: M8Hook.again, mistake: null);
    s.touched = true;
    if (!s.clamped) {
      deadly = M8ChainMistakes.hookFirst;
      return (res: M8Hook.deadly, mistake: M8ChainMistakes.hookFirst);
    }
    final m = !zero ? M8ChainMistakes.rodEarly : (!liveAfter ? M8ChainMistakes.testerNotRechecked : null);
    if (m != null) return slipOnce(m, place: e) ? (res: M8Hook.slip, mistake: m) : (res: M8Hook.again, mistake: m);
    s.hookX = x;
    return (res: M8Hook.hooked, mistake: null);
  }

  /// The ring has filled: the line is drained and earthed at end [e].
  void drainDone(int e) {
    final s = ends[e];
    if (ended || s.hookX == null || s.drained) return;
    s.drained = true;
    _tag(M8ChainLines.caughtRod);
  }

  /// The finger left the rod before the ring filled: it slips off the line.
  void unhook(int e) {
    final s = ends[e];
    if (s.hookX != null && !s.drained) s.hookX = null;
  }

  // --- the chain ------------------------------------------------------------------
  /// One upward drag on the bag: another stretch of chain out (three to coil it).
  bool pull(int e) {
    final s = ends[e];
    if (ended || phase != M8Phase.field || s.at != M8ChainAt.bag || s.pulled >= 3) return false;
    s.touched = true;
    s.pulled++;
    if (s.pulled >= 3) s.at = M8ChainAt.coil;
    return true;
  }

  /// The coiled chain into the বাতিল crate; the van's spare takes its place.
  /// A good chain thrown out is needless (the bonus only).
  M8Discard discard(int e) {
    final s = ends[e];
    if (ended || phase != M8Phase.field || s.at != M8ChainAt.coil) return M8Discard.none;
    final bad = !m8ChainGood(s.chain);
    s.crate = s.chain;
    s.chain = deal.spare;
    s.pulled = 0;
    s.at = M8ChainAt.bag;
    s.touched = true;
    if (bad) {
      s.swapped = true;
      _tag(M8ChainLines.caughtSwap);
      return M8Discard.right;
    }
    s.wasted = true;
    return M8Discard.needless;
  }

  /// A flick [flick] (design px, from the coil) at end [e]. Before the end's
  /// rod has drained = DEADLY (R4); a bad chain after it = slip (R13, once;
  /// the van's spare comes); else where it lands.
  ({M8ThrowRes res, DoMistake? mistake, M8Throw? t}) throwChain(int e, Offset flick, M8EndGeo geo) {
    final s = ends[e];
    if (ended || phase != M8Phase.field || s.at != M8ChainAt.coil) return (res: M8ThrowRes.none, mistake: null, t: null);
    // Not a throw: too short a stroke, downward or sideways.
    if (flick.distance < 50 || flick.dy >= 0 || math.atan2(flick.dx.abs(), -flick.dy) > 0.95) return (res: M8ThrowRes.none, mistake: null, t: null);
    s.touched = true;
    if (!s.drained) {
      deadly = M8ChainMistakes.chainFirst;
      return (res: M8ThrowRes.deadly, mistake: M8ChainMistakes.chainFirst, t: null);
    }
    if (!m8ChainGood(s.chain)) {
      final first = slipOnce(M8ChainMistakes.badChain, place: e);
      s.crate = s.chain;
      s.chain = deal.spare;
      s.pulled = 0;
      s.at = M8ChainAt.bag;
      return (res: first ? M8ThrowRes.slip : M8ThrowRes.again, mistake: M8ChainMistakes.badChain, t: null);
    }
    final t = m8ThrowOf(flick, geo);
    switch (t.kind) {
      case M8ThrowKind.short:
        return (res: M8ThrowRes.short, mistake: null, t: t);
      case M8ThrowKind.over:
        return (res: M8ThrowRes.over, mistake: null, t: t);
      case M8ThrowKind.beside:
        return (res: M8ThrowRes.beside, mistake: null, t: t);
      case M8ThrowKind.partial || M8ThrowKind.full:
        s.at = M8ChainAt.line;
        s.lo = t.lo;
        s.hi = t.hi;
        if (t.kind == M8ThrowKind.full) {
          _tag(M8ChainLines.caughtChain);
          return (res: M8ThrowRes.full, mistake: null, t: t);
        }
        return (res: M8ThrowRes.partial, mistake: null, t: t);
    }
  }

  /// The end is finished (rod drained, chain on all three): true once, with
  /// its place in order (1 = the first).
  int? finishEnd(int e) {
    final s = ends[e];
    if (!s.done || s.finished) return null;
    s.finished = true;
    return ++finishedEnds;
  }

  // --- the tail ---------------------------------------------------------------------
  /// A downward drag on a chain's tail. Before the job it only brings the
  /// chain back to the hand (free); in the close, before clearance it is a
  /// slip (R15, once; the chain goes back up); after it the chain comes down.
  ({M8Tug res, DoMistake? slip}) tug(int e) {
    final s = ends[e];
    if (ended || s.at != M8ChainAt.line) return (res: M8Tug.none, slip: null);
    if (phase == M8Phase.field) {
      s.at = M8ChainAt.coil;
      s.pulled = 3;
      s.finished = false;
      return (res: M8Tug.back, slip: null);
    }
    if (phase != M8Phase.close) return (res: M8Tug.none, slip: null);
    if (!cleared) {
      final m = M8ChainMistakes.tugEarly;
      return slipOnce(m) ? (res: M8Tug.slip, slip: m) : (res: M8Tug.again, slip: m);
    }
    s.at = M8ChainAt.down;
    if (ends.every((x) => x.at == M8ChainAt.down)) {
      _tag(M8ChainLines.caughtWait);
      phase = M8Phase.done;
    }
    return (res: M8Tug.down, slip: null);
  }

  // --- the climb ----------------------------------------------------------------------
  /// 'উঠি': the tester not shown 0 V = DEADLY (N1); a rod missing at an end =
  /// DEADLY (R3); then a chain not on all three phases, or skipped = slip
  /// (R14, once an end, the player stays).
  ({M8Climb res, DoMistake? mistake}) climb() {
    if (ended || phase != M8Phase.field) return (res: M8Climb.ok, mistake: null);
    if (!zero) {
      deadly = M8ChainMistakes.climbNoZero;
      return (res: M8Climb.deadly, mistake: M8ChainMistakes.climbNoZero);
    }
    if (ends.any((x) => !x.drained)) {
      deadly = M8ChainMistakes.climbNoRod;
      return (res: M8Climb.deadly, mistake: M8ChainMistakes.climbNoRod);
    }
    var anyAgain = false;
    DoMistake? again;
    for (var e = 0; e < 2; e++) {
      final s = ends[e];
      if (s.chainFull) continue;
      final m = s.at == M8ChainAt.line ? M8ChainMistakes.chainPartial : M8ChainMistakes.chainSkipped;
      if (slipOnce(m, place: e)) return (res: M8Climb.slip, mistake: m);
      anyAgain = true;
      again = m;
    }
    if (anyAgain) return (res: M8Climb.again, mistake: again);
    phase = M8Phase.job;
    station = M8Station.work;
    return (res: M8Climb.ok, mistake: null);
  }

  void startClose() {
    if (phase == M8Phase.job) phase = M8Phase.close;
  }

  void clear() {
    if (phase == M8Phase.close) cleared = true;
  }

  /// Which reason follows a key put in the pocket: only if no slip came first.
  bool get keyAsk => !slipped(M8ChainMistakes.keyNotPocket) && !asked.contains(M8Why.key);

  /// Listened to the early-removal coworker (a slip once).
  bool pushSlip(DoMistake m) => slipOnce(m);

  /// Fails the play (listening to a deadly push).
  void failDeadly(DoMistake m) => deadly = m;
}

/// The quick bonus: the builder's estimate (~85 % of a clean play, ruling
/// M8-15; quickMs after playtest). ms, ~1500 per human action: the padlock,
/// the board, the key (~7 s) and its reason (~8 s); to the first end (~2 s):
/// the tester three touches (~8 s) and its reason (~8 s); clamp, rod and hold
/// (~6 s), three pulls (~4 s), the throw with a retry (~4 s), the order reason
/// (~8 s); across to the other end (~3 s) the same without the tester (~18 s)
/// and the both-ends reason (~8 s); the bad chain's swap and its reason on
/// most plays (~12 s); the climb (~4 s) and the job (~3 s); the mate's wait
/// (~7 s) and the two tugs with the walk (~9 s); the coworker once (~10 s)
/// ≈ 150 s. 85 % ≈ 128 s.
const m8ChainQuickMs = 128000;

@immutable
class M8ChainThrowPack {
  const M8ChainThrowPack({required this.id, required this.titleBn, this.quickMs = m8ChainQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8ChainThrowPack> m8ChainThrowPacks = {
  'do_8_5_b': M8ChainThrowPack(id: 'do_8_5_b', titleBn: M8ChainLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8ChainThrowProbe {
  static M8ChainRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M8ChainThrowPage extends StatefulWidget {
  const M8ChainThrowPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8ChainThrowPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8ChainThrowPage> createState() => _M8ChainThrowPageState();
}

class _M8ChainThrowPageState extends State<M8ChainThrowPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ChainRunPage(
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

class _ChainRunPage extends ConsumerStatefulWidget {
  const _ChainRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8ChainThrowPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ChainRunPage> createState() => _ChainRunPageState();
}

/// The one commit behind the two-step preview.
enum _Act { climb }

class _FlightInfo {
  _FlightInfo(this.id, this.end, this.from, this.to, this.kind, this.chain, this.back);
  final int id;
  final int end;
  final Offset from;
  final Offset to;
  final M8ThrowKind kind;
  final M8ChainKind chain;
  final bool back;
}

class _ChainRunPageState extends ConsumerState<_ChainRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8ChainRun _run;
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
  int _wake = 0;
  int _steps = 0;

  /// The open preview (the climb) and what was set aside.
  _Act? _preview;
  Offset _previewAt = Offset.zero;
  final Set<_Act> _aside = {};

  /// A thing in the hand.
  M8Held _held = M8Held.none;
  int _heldSlot = -1;
  Offset _dragStart = Offset.zero;
  Offset _dragNow = Offset.zero;
  final ValueNotifier<M8DragView?> _dragView = ValueNotifier(null);

  /// The rod's drain: a ring that fills while the finger holds.
  late final AnimationController _drainC;
  final ValueNotifier<double> _ring = ValueNotifier(0);
  var _draining = false;

  /// A chain in flight (input waits for it).
  _FlightInfo? _flight;
  int _flightId = 0;
  Timer? _flightTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;

  /// The job cutaway and the mate.
  var _jobUp = false;
  M8Mate _mate = M8Mate.idle;
  Timer? _mateTimer;
  Timer? _jobTimer;
  int _mateId = 0;

  /// A short dark fade on every walk.
  int _fade = 0;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final List<GlobalKey> _slotKeys = [for (var i = 0; i < 4; i++) GlobalKey()];
  final _keyKey = GlobalKey();
  final _leaveKey = GlobalKey();
  final _climbKey = GlobalKey();
  final _arrowLKey = GlobalKey();
  final _arrowRKey = GlobalKey();
  final _backKey = GlobalKey();
  final _rodKey = GlobalKey();
  final _clampKey = GlobalKey();
  final _bagKey = GlobalKey();
  final _testerKey = GlobalKey();
  final _proverKey = GlobalKey();
  final _tailKey = GlobalKey();
  int _hintN = 0;
  M8Geo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8ChainRun(m8ChainDeal(widget.rng));
    _drainC = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _drainC.addListener(() => _ring.value = _drainC.value);
    _drainC.addStatusListener((s) {
      if (s == AnimationStatus.completed) _drained();
    });
    M8ChainThrowProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _mateId++;
    _flightTimer?.cancel();
    _mateTimer?.cancel();
    _jobTimer?.cancel();
    _drainC.dispose();
    _ring.dispose();
    _dragView.dispose();
    if (identical(M8ChainThrowProbe.run, _run)) M8ChainThrowProbe.run = null;
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

  bool get _busy => _flight != null || _jobUp || _freeze;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_busy && _run.phase != M8Phase.done;

  M8EndSpec _spec(int e) => _run.deal.ends[e].spec;
  M8EndGeo _eg(M8Geo g, int e) => M8EndGeo(g, _spec(e));

  String get _task {
    switch (_run.phase) {
      case M8Phase.sub:
        if (_run.key == M8Key.popped) return M8ChainLines.askKey;
        return _run.padlock && _run.board ? M8ChainLines.askLeave : M8ChainLines.askLock;
      case M8Phase.field:
        if (_run.station == M8Station.work) return _run.ends.any((e) => e.touched) ? M8ChainLines.askClimb : M8ChainLines.askWalk;
        return M8ChainLines.askEnd;
      case M8Phase.job || M8Phase.close || M8Phase.done:
        return M8ChainLines.askClose;
    }
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  // --- the coworker's cue -------------------------------------------------------
  /// Myth: scheduled when the player reaches his end; the first kit touch there
  /// waits for him. Early removal: scheduled when the close starts.
  void _maybeCallHim() {
    if (coworkerDone || coworkerDue || _ended) return;
    final d = _run.deal;
    if (d.push == M8Push.myth && _run.atEnd && _run.endIndex == d.coworkerEnd && !_run.ends[d.coworkerEnd].drained) scheduleCoworker();
    if (d.push == M8Push.early && _run.phase == M8Phase.close && !_run.cleared) scheduleCoworker();
  }

  /// His end: the first kit touch waits for him. The tails in the close do too.
  bool _hold({required bool kit}) {
    final d = _run.deal;
    if (d.push == M8Push.myth && kit && _run.atEnd && _run.endIndex == d.coworkerEnd) return holdForCoworker();
    if (d.push == M8Push.early && !kit && _run.phase == M8Phase.close) return holdForCoworker();
    return false;
  }

  // --- walking ----------------------------------------------------------------------
  void _walk(M8Station to) {
    if (!_canPlay || _held != M8Held.none) return;
    final r = _run.go(to);
    switch (r.res) {
      case M8Walk.slip:
        setState(() => _wake++);
        unawaited(_mistake(r.slip!, Offset.zero));
        return;
      case M8Walk.again:
        _tick();
        unawaited(_sayChain([M8ChainLines.again(r.slip!)]));
        return;
      case M8Walk.ok:
        break;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _fade++;
      _preview = null;
      _wake++;
    });
    _stepDone();
    _maybeCallHim();
    unawaited(_sayChain([_task]));
  }

  void _leave() {
    if (!_canPlay) return;
    final r = _run.leave();
    switch (r.res) {
      case M8Leave.keyFirst:
        _tick();
        unawaited(_sayChain([M8ChainLines.keyFirst]));
      case M8Leave.slip:
        setState(() => _wake++);
        unawaited(_mistake(r.slip!, Offset.zero));
      case M8Leave.again:
        _tick();
        unawaited(_sayChain([M8ChainLines.again(r.slip!)]));
      case M8Leave.done:
        _tick('sounds/intro/click.ogg', 0.5);
        setState(() {
          _fade++;
          _wake++;
        });
        _stepDone();
        unawaited(_sayChain([_task]));
    }
  }

  // --- hands on -----------------------------------------------------------------------
  void _tapScene(Offset p) {
    if (_canPlay) _hints.missTap();
  }

  void _panStart(Offset p, M8Geo geo) {
    _held = M8Held.none;
    _heldSlot = -1;
    if (!_canPlay || _preview != null) return;
    switch (_run.station) {
      case M8Station.sub:
        if (_run.key == M8Key.popped && geo.keyHit.contains(p)) {
          _begin(M8Held.key, p);
          return;
        }
        for (var i = 0; i < 4; i++) {
          if (_run.tray[i] != null && geo.slot(i).inflate(4).contains(p)) {
            _heldSlot = i;
            _begin(M8Held.item, p);
            return;
          }
        }
      case M8Station.endA || M8Station.endB:
        final e = _run.endIndex;
        final s = _run.ends[e];
        final eg = _eg(geo, e);
        if (s.at == M8ChainAt.line && eg.tailHit(s.lo, s.hi).contains(p)) {
          if (_hold(kit: false)) return;
          _begin(M8Held.tail, p);
          return;
        }
        if (s.hookX != null && !s.drained && eg.rodHeadHit(s.hookX!).contains(p)) {
          if (_hold(kit: true)) return;
          _held = M8Held.rod;
          _dragStart = p;
          _dragNow = p;
          _startDrain();
          return;
        }
        if (!_run.proofDone && eg.testerHit.contains(p)) {
          if (_hold(kit: true)) return;
          _begin(M8Held.tester, p);
          return;
        }
        if (!s.clamped && eg.clampHit.contains(p)) {
          if (_hold(kit: true)) return;
          _begin(M8Held.clamp, p);
          return;
        }
        if (s.hookX == null && eg.rodHit.contains(p)) {
          if (_hold(kit: true)) return;
          _begin(M8Held.rod, p);
          return;
        }
        if (s.at == M8ChainAt.bag && eg.bagHit.contains(p)) {
          if (_hold(kit: true)) return;
          _begin(M8Held.bag, p);
          return;
        }
        if (s.at == M8ChainAt.coil && eg.coilHit.contains(p)) {
          if (_hold(kit: true)) return;
          _begin(M8Held.coil, p);
          return;
        }
      case M8Station.work:
        break;
    }
  }

  void _begin(M8Held h, Offset p) {
    _held = h;
    _dragStart = p;
    _dragNow = p;
    _publish();
    // The thing in hand is hidden at its place while it moves.
    setState(() {});
  }

  void _publish() {
    final geo = _geoNow;
    if (geo == null || _held == M8Held.none) {
      _dragView.value = null;
      return;
    }
    Offset? cable;
    Offset? base;
    M8ChainKind chain = M8ChainKind.brass;
    M8TrayItem? item;
    if (_run.atEnd) {
      final e = _run.endIndex;
      final eg = _eg(geo, e);
      final s = _run.ends[e];
      cable = s.clamped ? eg.spike.translate(0, 2) : eg.clampRest;
      base = eg.rodHandle();
      chain = s.chain;
      if (_held == M8Held.clamp) cable = eg.rodBase;
    }
    if (_held == M8Held.item && _heldSlot >= 0) item = _run.tray[_heldSlot];
    _dragView.value = M8DragView(held: _held, start: _dragStart, at: _dragNow, item: item, chain: chain, cable: cable, base: base);
  }

  void _panUpdate(Offset p, M8Geo geo) {
    if (_held == M8Held.none) return;
    _dragNow = p;
    if (_draining) {
      // The finger has to stay with the hook.
      final e = _run.endIndex;
      final hx = _run.ends[e].hookX;
      if (hx != null) {
        final head = Offset(hx, _eg(geo, e).armY);
        if ((p - head).distance > 80) _stopDrain();
      }
      return;
    }
    if (_held == M8Held.rod && _run.atEnd) {
      final e = _run.endIndex;
      final eg = _eg(geo, e);
      if (_run.ends[e].hookX == null && eg.lineBand.contains(p)) {
        _tryHook(e, eg.hookXFor(p.dx), eg);
        return;
      }
    }
    _publish();
  }

  void _tryHook(int e, double x, M8EndGeo eg) {
    final r = _run.hookRod(e, x);
    switch (r.res) {
      case M8Hook.deadly:
        _clearHand();
        setState(() => _wake++);
        unawaited(_deadly(r.mistake!, eg.flashAt()));
      case M8Hook.slip:
        _clearHand();
        setState(() => _wake++);
        unawaited(_mistake(r.mistake!, Offset.zero));
      case M8Hook.again:
        _clearHand();
        _tick();
        if (r.mistake != null) unawaited(_sayChain([M8ChainLines.again(r.mistake!)]));
      case M8Hook.hooked:
        _tick('sounds/intro/impact_metal.ogg', 0.5);
        _dragView.value = null;
        _held = M8Held.rod;
        _startDrain();
        setState(() => _wake++);
    }
  }

  void _clearHand() {
    _held = M8Held.none;
    _heldSlot = -1;
    _dragView.value = null;
  }

  void _startDrain() {
    _draining = true;
    _ring.value = 0;
    _dragView.value = null;
    _drainC.forward(from: 0);
  }

  void _stopDrain() {
    if (!_draining) return;
    _draining = false;
    _drainC.stop();
    _drainC.value = 0;
    _ring.value = 0;
    _clearHand();
    setState(() => _wake++);
  }

  void _drained() {
    if (!_draining || !mounted) return;
    _draining = false;
    final e = _run.endIndex;
    _run.drainDone(e);
    _clearHand();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/spark.ogg', volume: 0.55);
    _stepDone();
    unawaited(Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_draining) _ring.value = 0;
    }));
    unawaited(_sayChain([_task]));
  }

  void _panEnd(M8Geo geo) {
    final h = _held;
    if (h == M8Held.none) return;
    if (_draining) {
      // Lifted early: the ring empties; the hook stays on the line.
      _stopDrain();
      return;
    }
    final at = _dragNow;
    final dy = at.dy - _dragStart.dy;
    final slot = _heldSlot;
    _clearHand();
    switch (h) {
      case M8Held.item:
        if (geo.handleHit.contains(at)) {
          _dropItem(slot);
        } else {
          setState(() {});
        }
      case M8Held.key:
        M8Key? where;
        if (geo.pocketHit.contains(at)) {
          where = M8Key.pocket;
        } else if (geo.hookBoardHit.contains(at)) {
          where = M8Key.hook;
        } else if (geo.operatorHit.contains(at)) {
          where = M8Key.operator;
        }
        if (where == null) {
          setState(() {});
        } else {
          _placeKey(where);
        }
      case M8Held.clamp:
        final eg = _eg(geo, _run.endIndex);
        if (eg.spikeHit.contains(at)) {
          if (_run.setClamp(_run.endIndex)) {
            _tick('sounds/intro/impact_metal.ogg', 0.55);
            _stepDone();
            return;
          }
        }
        setState(() {});
      case M8Held.rod:
        // Never reached the line: back on the tarp.
        setState(() {});
      case M8Held.tester:
        final eg = _eg(geo, _run.endIndex);
        if (eg.proverHit.inflate(10).contains(at)) {
          _testerOn(M8TestAt.prover);
        } else if (eg.lineBand.contains(at)) {
          _testerOn(M8TestAt.line);
        } else {
          setState(() {});
        }
      case M8Held.bag:
        if (dy <= -50) {
          if (_run.pull(_run.endIndex)) {
            _tick('sounds/learn/tag_slap.ogg', 0.4);
            _stepDone();
            return;
          }
        }
        _hints.missTap();
        setState(() {});
      case M8Held.coil:
        final eg = _eg(geo, _run.endIndex);
        if (eg.crate.inflate(10).contains(at)) {
          _discard();
        } else {
          _doThrow(at - _dragStart, eg);
        }
      case M8Held.tail:
        if (dy >= 56) {
          _tug();
        } else {
          _hints.missTap();
          setState(() {});
        }
      case M8Held.none:
        break;
    }
  }

  // --- the substation ---------------------------------------------------------------
  void _dropItem(int slot) {
    final r = _run.dropItem(slot);
    switch (r) {
      case M8Drop.padlock:
        _cue('sounds/intro/impact_metal.ogg', volume: 0.65);
        _stepDone();
        unawaited(_sayChain([_task]));
      case M8Drop.board:
        _tick('sounds/learn/tag_slap.ogg', 0.5);
        _stepDone();
        unawaited(_sayChain([_task]));
      case M8Drop.needless:
        _tick();
        setState(() {});
        unawaited(_sayChain([M8ChainLines.decoy]));
      case M8Drop.none:
        setState(() {});
    }
  }

  void _placeKey(M8Key where) {
    final r = _run.placeKey(where);
    if (r.ok) {
      _tick('sounds/learn/tag_slap.ogg', 0.5);
      _stepDone();
      if (_run.keyAsk) {
        _run.asked.add(M8Why.key);
        unawaited(_table(M8Why.key, 5));
      } else {
        unawaited(_sayChain([_task]));
      }
      return;
    }
    if (r.slip != null) {
      setState(() => _wake++);
      unawaited(_mistake(r.slip!, Offset.zero));
      return;
    }
    _tick();
    setState(() {});
    if (r.again) unawaited(_sayChain([M8ChainLines.again(M8ChainMistakes.keyNotPocket)]));
  }

  // --- the tester -----------------------------------------------------------------------
  void _testerOn(M8TestAt at) {
    final r = _run.test(at);
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    setState(() => _wake++);
    if (r.mistake != null) {
      unawaited(_mistake(r.mistake!, Offset.zero));
      return;
    }
    if (r.again) {
      unawaited(_sayChain([M8ChainLines.again(M8ChainMistakes.testerUnproved)]));
      return;
    }
    _stepDone();
    if (r.provenNow) {
      final clean = !_run.slipped(M8ChainMistakes.testerUnproved) && !_run.slipped(M8ChainMistakes.testerNotRechecked) && !_run.slipped(M8ChainMistakes.rodEarly, place: 0) && !_run.slipped(M8ChainMistakes.rodEarly, place: 1);
      if (clean && !_run.asked.contains(M8Why.tester)) {
        _run.asked.add(M8Why.tester);
        unawaited(_table(M8Why.tester, 5));
        return;
      }
    }
    unawaited(_sayChain([_task]));
  }

  // --- the chain ------------------------------------------------------------------------
  void _discard() {
    final e = _run.endIndex;
    final r = _run.discard(e);
    if (r == M8Discard.none) {
      setState(() {});
      return;
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    _stepDone();
    if (r == M8Discard.right) {
      if (!_run.asked.contains(M8Why.swap)) {
        _run.asked.add(M8Why.swap);
        unawaited(_table(M8Why.swap, 5));
        return;
      }
      unawaited(_sayChain([M8ChainLines.van]));
      return;
    }
    unawaited(_sayChain([M8ChainLines.needlessDiscard]));
  }

  void _doThrow(Offset flick, M8EndGeo eg) {
    final e = _run.endIndex;
    final r = _run.throwChain(e, flick, eg);
    if (r.res == M8ThrowRes.none) {
      _hints.missTap();
      setState(() {});
      return;
    }
    if (r.res == M8ThrowRes.deadly) {
      setState(() => _wake++);
      unawaited(_deadly(r.mistake!, eg.flashAt()));
      return;
    }
    // A flight, then what happened.
    final t = r.t;
    final badSlip = r.res == M8ThrowRes.slip || r.res == M8ThrowRes.again;
    final land = t == null ? eg.pins[1].translate(0, -6) : Offset(t.landX.clamp(10.0, 350.0), eg.armY - 6);
    final kind = t?.kind ?? M8ThrowKind.partial;
    final chain = badSlip ? (_run.ends[e].crate ?? _run.ends[e].chain) : _run.ends[e].chain;
    final id = ++_flightId;
    _cue('sounds/learn/rush_out.ogg', volume: 0.5);
    setState(() {
      _flight = _FlightInfo(id, e, eg.coil, land, kind, chain, badSlip);
    });
    _flightTimer?.cancel();
    _flightTimer = Timer(Duration(milliseconds: _quiet ? 60 : 620), () {
      if (!mounted || _flight?.id != id) return;
      setState(() => _flight = null);
      _afterThrow(e, r.res, r.mistake);
    });
  }

  void _afterThrow(int e, M8ThrowRes res, DoMistake? m) {
    switch (res) {
      case M8ThrowRes.slip:
        unawaited(_mistake(m!, Offset.zero));
      case M8ThrowRes.again:
        _tick();
        unawaited(_sayChain([M8ChainLines.again(m!)]));
      case M8ThrowRes.short:
        _cue('sounds/intro/tick.ogg', volume: 0.5);
        unawaited(_sayChain([M8ChainLines.fellShort]));
      case M8ThrowRes.over:
        _cue('sounds/intro/tick.ogg', volume: 0.5);
        unawaited(_sayChain([M8ChainLines.slidOff]));
      case M8ThrowRes.beside:
        _cue('sounds/intro/tick.ogg', volume: 0.5);
        unawaited(_sayChain([M8ChainLines.beside]));
      case M8ThrowRes.partial:
        _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
        _stepDone();
        unawaited(_sayChain([_task]));
      case M8ThrowRes.full:
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        _stepDone();
        unawaited(_endDone(e));
      case M8ThrowRes.none || M8ThrowRes.deadly:
        break;
    }
  }

  Future<void> _endDone(int e) async {
    final place = _run.finishEnd(e);
    if (place == null) return;
    HapticFeedback.mediumImpact();
    final why = place == 1 ? M8Why.order : M8Why.both;
    _run.asked.add(why);
    unawaited(_table(why, 15 + (_run.ends[e].thorough ? 5 : 0)));
  }

  void _tug() {
    final e = _run.endIndex;
    final r = _run.tug(e);
    switch (r.res) {
      case M8Tug.none:
        setState(() {});
      case M8Tug.back:
        _tick('sounds/intro/tick.ogg', 0.5);
        _stepDone();
      case M8Tug.slip:
        setState(() => _wake++);
        unawaited(_mistake(r.slip!, Offset.zero));
      case M8Tug.again:
        _tick();
        setState(() {});
        unawaited(_sayChain([M8ChainLines.again(r.slip!)]));
      case M8Tug.down:
        _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
        _stepDone();
        if (_run.phase == M8Phase.done) {
          unawaited(_finish());
        } else {
          unawaited(_sayChain([_task]));
        }
    }
  }

  // --- the climb (two steps), the job and the close ------------------------------------
  void _openClimb(Offset global) {
    if (!_canPlay || _preview != null || _run.phase != M8Phase.field) return;
    setState(() {
      _preview = _Act.climb;
      _previewAt = global;
    });
  }

  void _confirm() {
    final p = _preview;
    if (p == null) return;
    setState(() {
      _preview = null;
      _aside.clear();
    });
    if (p == _Act.climb) _climb(_previewAt);
  }

  void _reject() {
    final p = _preview;
    if (p == null) return;
    setState(() {
      _preview = null;
      _aside.add(p);
    });
  }

  void _climb(Offset global) {
    if (!_canPlay) return;
    final r = _run.climb();
    switch (r.res) {
      case M8Climb.deadly:
        setState(() => _wake++);
        unawaited(_deadly(r.mistake!, Offset(180, _geoNow?.workArmY ?? 200)));
      case M8Climb.slip:
        setState(() => _wake++);
        unawaited(_mistake(r.mistake!, global));
      case M8Climb.again:
        _tick();
        unawaited(_sayChain([M8ChainLines.again(r.mistake!)]));
      case M8Climb.ok:
        unawaited(_job());
    }
  }

  /// The job cutaway (~3 s), then the mate comes down and the close begins.
  Future<void> _job() async {
    _hush();
    _cue('sounds/intro/confirm.ogg', volume: 0.6);
    setState(() {
      _jobUp = true;
      _mate = M8Mate.job;
      _fade++;
      _wake++;
    });
    _jobTimer?.cancel();
    _jobTimer = Timer(Duration(milliseconds: _quiet ? 400 : 3000), () {
      if (!mounted || _ended) return;
      _run.startClose();
      final id = ++_mateId;
      setState(() {
        _jobUp = false;
        _mate = M8Mate.descend;
        _wake++;
      });
      _maybeCallHim();
      unawaited(_sayChain([_task]));
      _mateTimer?.cancel();
      _mateTimer = Timer(Duration(milliseconds: _run.deal.mateMs), () {
        if (!mounted || id != _mateId || _ended) return;
        _run.clear();
        _cue('sounds/intro/confirm.ogg', volume: 0.6);
        setState(() {
          _mate = M8Mate.cleared;
          _wake++;
        });
      });
    });
  }

  // --- the reasons (ReasonTable) ----------------------------------------------------------
  Future<void> _table(M8Why why, int amount) async {
    _hush();
    putOnTable(amount);
    unawaited(askReason(
      deal: () => dealChoices(M8ChainLines.whyRight[why]!, M8ChainLines.whyWrong[why]!, widget.rng),
      question: M8ChainLines.whyQ[why]!,
      stillValid: () => !_ended,
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (!mounted || _ended) return;
      setState(() => _wake++);
      _maybeCallHim();
      unawaited(_sayChain([_task]));
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) -----------------------------------------
  @override
  CoworkerScript get coworkerScript => M8ChainLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final d = _run.deal;
    if (_ended) return null;
    final blocked = _intro || _card != null || tableBusy || _freeze || _preview != null || _busy || _held != M8Held.none;
    if (d.push == M8Push.myth) {
      final s = _run.ends[d.coworkerEnd];
      if (s.drained || s.at == M8ChainAt.line) return null;
      if (blocked || !_run.atEnd || _run.endIndex != d.coworkerEnd) return false;
      return true;
    }
    if (_run.cleared || _run.phase == M8Phase.done) return null;
    if (_run.phase != M8Phase.close || blocked) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _run.deal.push;
    if (!held) {
      final m = M8ChainMistakes.push(p);
      if (m.deadly) {
        _run.failDeadly(m);
        final geo = _geoNow;
        final at = geo == null ? Offset.zero : _eg(geo, _run.deal.coworkerEnd).flashAt();
        await _deadly(m, at);
        return;
      }
      if (_run.pushSlip(m)) {
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        await _slip(m);
      } else {
        unawaited(_sayChain([_task]));
      }
      return;
    }
    _run.caught.add(M8ChainLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8ChainLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8ChainLines.tapWhy[_nudgeN++ % M8ChainLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes -----------------------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _mateTimer?.cancel();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m, _flashAt);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    _clearHand();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _preview = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8chain/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly act: the scene freezes grey and the flash shows at [at] in
  /// colour; then near-miss or death.
  Future<void> _deadly(DoMistake m, Offset at) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _mateTimer?.cancel();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    _clearHand();
    _stopDrainQuiet();
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _flashAt = at;
      _preview = null;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m8chain/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M8ChainLines.deadlyWord : M8ChainLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _stopDrainQuiet() {
    _draining = false;
    _drainC.stop();
    _drainC.value = 0;
    _ring.value = 0;
  }

  void _cardGo() {
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
    await _say(!_run.passed ? M8ChainLines.fail : (_quickBonus ? M8ChainLines.quick : M8ChainLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leaveLevel() async {
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

  // --- the scene ---------------------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_flight != null) return LinemanMode.throwIt;
    if (_held != M8Held.none || _jobUp) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M8EndLook _look(int e) {
    final s = _run.ends[e];
    final fl = _flight;
    final flying = fl != null && fl.end == e;
    return M8EndLook(
      clamped: s.clamped,
      hookX: s.hookX,
      drained: s.drained,
      pulled: s.pulled,
      chain: s.chain,
      defectSeg: s.deal.defectSeg,
      // While a chain flies, the coil is hidden (and the line shows nothing yet).
      at: flying ? M8ChainAt.coil : s.at,
      lo: s.lo,
      hi: s.hi,
      tester: !_run.proofDone,
      reading: _run.reading,
      crate: s.crate,
    );
  }

  M8Rig get _rig => M8Rig(
        station: _run.station,
        sub: M8SubLook(tray: [..._run.tray], padlock: _run.padlock, board: _run.board, key: _run.key),
        ends: [_look(0), _look(1)],
        specs: [_spec(0), _spec(1)],
        held: _flight != null ? M8Held.coil : _held,
        heldSlot: _heldSlot,
      );

  /// The gesture hand: how to touch, never what. At the bench a sweep over the
  /// tray (a straight-up nudge on the key once it is out); at an end, before
  /// anything is used, a sweep over the rod, clamp, bag and tester alike;
  /// after, in turn, a generic nudge on each thing that can still be moved
  /// (the clamp, the rod, the bag, the coil, the tester), a hold on a rod at
  /// the line; once a chain has landed (full or partial alike) a sweep over its
  /// tail and the walk arrow; at the work pole a sweep over the arrows and 'উঠি'.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    switch (_run.station) {
      case M8Station.sub:
        final keyOut = _run.key == M8Key.popped;
        if (keyOut && n.isEven) return HintSpec.drag(geo.keyAt, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
        final keys = [for (var i = 0; i < 4; i++) if (_run.tray[i] != null) _slotKeys[i]];
        if (!keyOut && _run.padlock && _run.board) return HintSpec.tapOn(_leaveKey);
        if (keys.length < 2) return HintSpec.tapOn(_leaveKey);
        return HintSpec.sweepOver(keys);
      case M8Station.endA || M8Station.endB:
        final e = _run.endIndex;
        final s = _run.ends[e];
        final eg = _eg(geo, e);
        if (s.at == M8ChainAt.line) return HintSpec.sweepOver([_tailKey, _backKey]);
        if (s.at == M8ChainAt.down) return HintSpec.sweepOver([_backKey]);
        if (!s.touched) {
          return HintSpec.sweepOver([_rodKey, _clampKey, _bagKey, if (!_run.proofDone) ..._testerKeys]);
        }
        final cand = <HintSpec>[
          if (!s.clamped) HintSpec.drag(eg.clampRest, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene),
          if (s.hookX == null) HintSpec.drag(eg.rodRest, toward: const Offset(0, -1), travel: 44, space: HintSpace.scene),
          if (s.hookX != null && !s.drained) HintSpec.hold(Offset(s.hookX!, eg.armY), space: HintSpace.scene),
          if (s.at == M8ChainAt.bag) HintSpec.swipe(eg.bag, toward: const Offset(0, -1), travel: 70, space: HintSpace.scene),
          if (s.at == M8ChainAt.coil) HintSpec.swipe(eg.coil, toward: const Offset(0, -1), travel: 90, space: HintSpace.scene),
          if (!_run.proofDone) HintSpec.drag(eg.tester, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene),
        ];
        if (cand.isEmpty) return HintSpec.sweepOver([_backKey]);
        return cand[n % cand.length];
      case M8Station.work:
        return HintSpec.sweepOver([_arrowLKey, _arrowRKey, if (_run.phase == M8Phase.field) _climbKey]);
    }
  }

  List<GlobalKey> get _testerKeys => [_testerKey, _proverKey];

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8Geo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final st = _run.station;
    final e = _run.endIndex;
    final eg = _run.atEnd ? _eg(geo, e) : null;
    final look = _run.atEnd ? _run.ends[e] : null;
    final trainee = switch (st) {
      M8Station.sub => geo.subTrainee,
      M8Station.work => geo.workTrainee,
      _ => eg!.trainee,
    };
    final boxes = <(GlobalKey, Rect)>[
      if (st == M8Station.sub) for (var i = 0; i < 4; i++) (_slotKeys[i], geo.slot(i)),
      if (st == M8Station.sub) (_keyKey, geo.keyHit),
      if (eg != null) ...[
        (_rodKey, eg.rodHit),
        (_clampKey, eg.clampHit),
        (_bagKey, eg.bagHit),
        (_testerKey, eg.testerHit),
        (_proverKey, eg.proverHit),
        if (look!.at == M8ChainAt.line) (_tailKey, eg.tailHit(look.lo, look.hi)),
      ],
    ];
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: ValueKey('site-${st.name}'),
                child: RepaintBoundary(child: CustomPaint(painter: M8WorldPainter(geo: geo, rig: _rig))),
              ),
              if (st == M8Station.work)
                Positioned.fill(
                  key: ValueKey('mate-${_mate.name}-$_mateId'),
                  child: RepaintBoundary(
                    child: _mate == M8Mate.descend
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: quiet ? 1 : 0, end: 1),
                            duration: Duration(milliseconds: _run.deal.mateMs),
                            builder: (_, v, _) => CustomPaint(painter: M8MatePainter(geo: geo, mode: M8Mate.descend, t: v)),
                          )
                        : _mate == M8Mate.cleared
                            ? TweenAnimationBuilder<double>(
                                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                                duration: const Duration(milliseconds: 1400),
                                builder: (_, v, _) => CustomPaint(painter: M8MatePainter(geo: geo, mode: M8Mate.cleared, t: 1, wave: v)),
                              )
                            : CustomPaint(painter: M8MatePainter(geo: geo, mode: _mate, t: 0)),
                  ),
                ),
              // The words a worker reads.
              if (st == M8Station.sub) ...[
                Positioned.fromRect(
                  key: const ValueKey('feeder-label'),
                  rect: Rect.fromLTWH(geo.panel.left, geo.panel.top + 40, 70, 14),
                  child: _label(M8ChainLines.feeder, 8),
                ),
                if (_run.board)
                  Positioned.fromRect(
                    key: const ValueKey('board-label'),
                    rect: geo.boardOn,
                    child: Semantics(label: M8ChainLines.boardText, excludeSemantics: true, child: _white(M8ChainLines.boardText, 7.5)),
                  ),
                for (var i = 0; i < 4; i++)
                  if (_run.tray[i] == M8TrayItem.board && !(_held == M8Held.item && _heldSlot == i))
                    Positioned.fromRect(
                      key: ValueKey('tray-board-$i'),
                      rect: geo.slot(i).deflate(2),
                      child: IgnorePointer(child: Semantics(label: M8ChainLines.boardText, excludeSemantics: true, child: _white(M8ChainLines.boardText, 6.5))),
                    ),
              ],
              if (st == M8Station.work)
                Positioned.fromRect(
                  key: const ValueKey('docket-label'),
                  rect: geo.docket,
                  child: Semantics(label: M8ChainLines.docket, excludeSemantics: true, child: _label(M8ChainLines.docket, 8.5)),
                ),
              if (eg != null)
                Positioned.fromRect(
                  key: ValueKey('crate-label-$e'),
                  rect: eg.crate,
                  child: IgnorePointer(child: Semantics(label: M8ChainLines.crate, excludeSemantics: true, child: _white(M8ChainLines.crate, 8))),
                ),
              Positioned.fromRect(
                key: ValueKey('trainee-${st.name}'),
                rect: trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      // The controls' places, for the sweep (no paint).
      for (final (k, r) in boxes)
        Positioned.fromRect(
          key: ValueKey('box-${k.hashCode}'),
          rect: r,
          child: IgnorePointer(child: SizedBox.expand(key: k)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8ChainLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: () {
              if (_draining) {
                _stopDrain();
              } else {
                _clearHand();
                setState(() {});
              }
            },
          ),
        ),
      ),
      // The thing in the hand follows the finger (its own small painter).
      Positioned.fill(
        key: const ValueKey('hand'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M8DragPainter(view: _dragView, geo: geo)))),
      ),
      if (eg != null && look!.hookX != null && !look.drained)
        Positioned.fill(
          key: ValueKey('ring-$e'),
          child: IgnorePointer(child: CustomPaint(painter: M8RingPainter(at: Offset(look.hookX!, eg.armY - 4), v: _ring))),
        ),
      if (_flight case final fl?)
        Positioned.fill(
          key: ValueKey('flight-${fl.id}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (_, v, _) => CustomPaint(painter: M8FlightPainter(from: fl.from, to: fl.to, v: v, kind: fl.kind, chain: fl.chain, back: fl.back)),
            ),
          ),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M8FlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // A walk, or the job cutaway: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('fade-$_fade'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _fade == 0 ? 0 : 0.6, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  Widget _label(String t, double size) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(t, maxLines: 1, style: bangla(fontSize: size, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
        ),
      );

  Widget _white(String t, double size) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(t, maxLines: 1, style: bangla(fontSize: size, fontWeight: FontWeight.w900, color: const Color(0xFFFFFFFF))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && _run.phase != M8Phase.done && !deckUp && !coworkerOpen && _card == null && !_busy && _held == M8Held.none;
    final st = _run.station;
    final btnW = math.min(92.0, (size.width - 8) / 3);
    final buttons = <Widget>[
      if (handsOn && st == M8Station.sub)
        _RowButton(key: _leaveKey, icon: Icons.directions_walk_rounded, label: M8ChainLines.leave, width: btnW, onTap: (_) => _leave()),
      if (handsOn && st == M8Station.work) ...[
        _RowButton(key: _arrowLKey, icon: Icons.arrow_back_rounded, label: M8ChainLines.walkLeft, width: btnW, onTap: (_) => _walk(M8Station.endA)),
        if (_run.phase == M8Phase.field)
          CardAside(
            aside: _aside.contains(_Act.climb),
            child: _RowButton(key: _climbKey, icon: Icons.north_rounded, label: M8ChainLines.climb, width: btnW, onTap: _openClimb),
          ),
        _RowButton(key: _arrowRKey, icon: Icons.arrow_forward_rounded, label: M8ChainLines.walkRight, width: btnW, onTap: (_) => _walk(M8Station.endB)),
      ],
      if (handsOn && (st == M8Station.endA || st == M8Station.endB))
        _RowButton(
          key: _backKey,
          icon: st == M8Station.endA ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
          label: M8ChainLines.walkBack,
          width: btnW,
          onTap: (_) => _walk(M8Station.work),
        ),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leaveLevel());
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
            onClose: () => unawaited(_leaveLevel()),
            onToggleMute: () {
              unawaited(MascotSpeechLibrary.stop());
              setState(() => _muted = !_muted);
            },
            progress: DoProgress(
              labels: M8ChainLines.progressLabels,
              done: {
                if (_run.padlock && _run.board && _run.key == M8Key.pocket) 0,
                if (_run.ends[0].finished) 1,
                if (_run.ends[1].finished) 2,
                if (_run.phase == M8Phase.done) 3,
              },
              current: _run.phase == M8Phase.sub ? 0 : (_run.phase == M8Phase.close || _run.phase == M8Phase.job ? 3 : (_run.atEnd ? 1 + _run.endIndex : null)),
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _preview == null,
            hintKey: '${st.name}/$_steps/${_run.phase.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (buttons.isNotEmpty)
                Positioned(
                  key: ValueKey('hud-row-${st.name}-${_run.phase.name}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: buttons),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (handsOn && _preview != null)
                Positioned.fill(
                  key: ValueKey('preview-$_preview'),
                  child: CardPreviewOverlay(
                    textBn: M8ChainLines.climb,
                    icon: Icons.north_rounded,
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirm,
                    onReject: _reject,
                  ),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.phase.name}-$strikes'),
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
                  line: M8ChainLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 4, muted: _muted)),
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

/// One button under the scene: a round icon with its name under it (all alike).
class _RowButton extends StatelessWidget {
  const _RowButton({super.key, required this.icon, required this.label, required this.onTap, this.width = 90});
  final IconData icon;
  final String label;
  final double width;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: SlmColors.gold300),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
