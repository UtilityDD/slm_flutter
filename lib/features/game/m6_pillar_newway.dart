import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
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
import 'm6_pillar_newway_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_pillar_newway_world.dart' show M6NwCore, M6NwCoreX, M6NwGeo, kM6NwEarth, kM6NwNLink, kM6NwTerms;

// Lesson 6.9 "এলটি ডিস্ট্রিবিউশন পিলার: শেষ প্রবেশদ্বার", কাজ 2 "নতুন লাইন
// জুড়ুন" (pack do_6_9_b, engineType m6_pillar_newway). A lane-side feeder
// pillar by its DTR: the new lane's 4-core armoured cable goes into the
// spare way. Inside: the R, Y and B busbars (each marked), three copper
// droppers that bend down behind an insulating shroud and may cross, the
// spare way's three fuse units (labels worn off, SFU at ON), the common
// neutral link and the earthing terminal; the cable's cores carry only their
// ferrule tags (R, Y, B, N) and the armour has its braided earth lead.
//
// The core verb: pluck a dropper (a tap — it twangs along its whole length
// and the mark of the bar it meets lights) to learn which bar feeds a fuse
// unit, then land each lug by drag (R/Y/B on the fuse unit fed from that
// bar, N on the neutral link, the armour on the earthing terminal; a wrong
// terminal = a slip, the lug springs back) and hold the insulated spanner on
// its nut until it seats (an early release leaves it loose — no message; a
// loose lug glows hot at switch-on).
//
// The lesson's rules, and only those:
//   • point 2: separate busbars for R, Y, B and neutral; each outgoing
//     feeder's phases through a fuse unit from the busbars (HRC or SFU);
//     all neutrals on one common neutral link; the box body and the cable
//     armour on the earthing terminal; the safety tip: the pillar is as
//     dangerous as a live panel — full PPE and insulated tools; the DTR's LT
//     switch OFF, lock and tag, the tester live-dead-live, never a fuse on a
//     live supply;
//   • point 3: a loose connection sparks and runs hot (a hotspot);
//   • pro tip 1: lock the pillar door after the work (children, the public);
//   • pro tip 2: keep the phase sequence (R-Y-B) on a new connection, else a
//     consumer's three-phase equipment may be damaged;
//   • myth 1 (the coworker's (A), with English digits and LT in English
//     letters — one clip with board 6.9's myth, M6-8) and its
//     reality: 415 V is enough for a deadly shock, and the fault current's
//     arc flash burns in a moment.
// Rulings (docs/module_specs/module6_rulings.md, which win over the item
// spec): X4 — the pillar's terminals are handled only on a dead board: the
// DTR's LT switch OFF → lock + tag → tester live-dead-live 0 V (the spec's
// "SFU OFF" step is replaced; the spare way's SFU stays OFF until the door is
// shut). A hand or tool inside (a pluck, a lug landed, a nut held) with the LT
// ON = DEADLY, whatever PPE and whatever the SFU shows. The LT OFF but no lock
// and tag, not proved dead, or the tester not proved again after the 0 V =
// slip (N4); a 0 V read on a tester not first proved on a live source = slip
// (N9); no PPE after a proven isolation = slip (A5); the LT or the SFU
// switched ON with the pillar door open = slip (N5). M6-1: the armour not
// landed at the pillar = slip (the source end is earthed). X2/B1: listening to
// the coworker is the act he pushes — (A) myth 1 before the isolation, (B)
// 'DTR-এর LT বন্ধের দরকার নেই, SFU নামালেই হবে — 415 ভোল্টই তো।' — both push
// hands into the live pillar: DEADLY. M6-5: a phase on a fuse unit fed from
// another bar, N on a fuse unit or the earth, the armour off the earthing
// terminal, a loose lug, the door left open or unlocked = slips.
// Inferred (open questions): a core landed while the spare way's SFU is still
// ON (after a proven isolation) = slip — the ruling says the SFU stays OFF
// until the door is shut; the SFU's handle is door-mounted (it works with
// the door shut); after a loose lug at switch-on the crew switches it all off
// again (SFU OFF, LT OFF, lock and tag, door open) and the trainee proves
// dead again before re-tightening.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_pillar_newway_world.dart), corner guide; five right moves
// put ◆ on the table → "কেন …?" (the proven isolation; the three phases
// landed; N and armour landed; the lane lit with every nut tight — the
// tightening reason; the door padlocked — the lock reason); the coworker once a play before the
// isolation (the LT handle, the SFU handle, every hand inside and — for (A)
// — the PPE stand wait for him: holdForCoworker). Gesture hands: sweeps over
// the stand, the LT box, the SFU, the tester and the lugs; over the three
// droppers; over every terminal; an upward nudge on a lug; a hold ring on the
// nut just landed; a drag on the open door toward shut; sweeps over the SFU,
// the LT box and the door, and over the van and the hasp — never the answer.

// ============================================================================
// Content
// ============================================================================

/// The coworker's push (one per play, before the isolation).
enum M6NwPush { myth, sfuOnly }

/// What a reason asks about.
enum M6NwWhy { isolate, order, neutral, tighten, door }

/// The five right moves that put ◆ on the table.
enum M6NwStage { isolate, phases, neutral, lit, door }

abstract final class M6PillarNewwayLines {
  static const title = 'নতুন লাইন জুড়ুন';
  // DRAFT wording — owner (M6-12).
  static const intro = 'নতুন গলির কেবিল পিলারে জুড়তে হবে — ফেজ সিকোয়েন্স যেন ঠিক থাকে।';

  // The guide's task now (tap him: the same task, a different way).
  static const askReady = 'নতুন কেবিল স্পেয়ার ওয়েতে যাবে — আগে নিরাপদে কাজের জায়গা তৈরি করুন।';
  static const askLand = 'এবার কোরগুলো ঠিক টার্মিনালে জুড়ে নাট টাইট দিন।';
  static const askFix = 'ঢিলা জোড়াটা নিরাপদে টাইট দিয়ে আবার চালু করুন।';
  static const askSwitch = 'জোড়া শেষ — এবার নতুন গলিতে আলো দিন।';
  static const askFinish = 'গলিতে আলো এসেছে — কাজ গুছিয়ে ফিরুন।';
  static const landFirst = 'আগে সব কোর জুড়ে নিন।';
  static const notLit = 'নতুন গলিতে এখনও আলো আসেনি।';
  static List<String> get tasks => [askReady, askLand, askFix, askSwitch, askFinish];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  static const sceneLabel = 'ফিডার পিলার';
  static String laneTag(int n) => enDigits('গলি $n');

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M6NwWhy, String>{
    M6NwWhy.isolate: 'কাজের আগে কেন LT বন্ধ করে ডেড প্রমাণ করলেন?',
    M6NwWhy.order: 'ফেজ কোরগুলো কেন এভাবে জুড়লেন?',
    M6NwWhy.neutral: 'নিউট্রাল আর আর্মার কেন ওখানে?',
    M6NwWhy.tighten: 'কেন নাট পুরো টাইট দিলেন?',
    M6NwWhy.door: 'কেন দরজায় তালা দিলেন?',
  };
  static const whyRight = <M6NwWhy, List<String>>{
    M6NwWhy.isolate: ['SFU OFF হলেও বাসবার আর ড্রপার লাইভ থাকে', 'পিলারের ভেতরটা লাইভ প্যানেলের মতোই বিপজ্জনক'],
    M6NwWhy.order: ['R-Y-B উল্টালে থ্রি-ফেজ যন্ত্র নষ্ট হতে পারে', 'প্রতিটা ফেজ কোর তার নিজের বাসবারের ফিউজে'],
    M6NwWhy.neutral: ['সব নিউট্রাল যায় একটা কমন নিউট্রাল লিঙ্কে', 'কেবিলের আর্মার আর্থ হয় আর্থিং টার্মিনালে'],
    M6NwWhy.tighten: ['ঢিলা কানেকশনে স্পার্কিং হয়, জায়গা গরম হয়', 'লুজ লাগ পরে হটস্পট হয়ে পুড়ে যেতে পারে'],
    M6NwWhy.door: ['খোলা দরজা বাচ্চা আর পথচারীর জন্য বিপদ', 'তালা থাকলে বাইরের কেউ লাইভ বক্স খোলে না'],
  };
  static const myths = [
    'LT বক্সে তো শুধু 415 ভোল্ট, তেমন ভয় নেই',
    'SFU নামালেই গোটা পিলার নিরাপদ হয়ে যায়',
    'যেকোনো ফেজ যেকোনো ফিউজে দিলেই চলে যায়',
    'নিউট্রাল আর আর্মার একসাথে বাঁধলেই হলো',
    'হাতে যতটুকু টাইট হয়, ততটুকুই যথেষ্ট',
    'দরজা ভেজিয়ে রাখলেই হলো, তালা লাগে না',
    'তাড়াতাড়ি সারলে নিয়মের দরকার পড়ে না',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play, before the isolation).
  // DRAFT wording — owner (M6-12). (A) is lesson 6.9 myth 1 (English digits,
  // LT in English letters), one clip shared with board 6.9's myth (M6-8);
  // (B) is the rulings file's X4 draft.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerMyth = CoworkerScript(
    line: 'LT বক্সের ভেতরে তো শুধু 415 ভোল্ট থাকে, এটা তেমন বিপজ্জনক নয়।',
    exitLine: coworkerExit,
    right: ['না, 415 ভোল্টেও শক আর আর্ক ফ্ল্যাশ হয়', 'না, আগে LT বন্ধ করে ডেড প্রমাণ করব', 'না, লাইভ পিলারে হাত দেব না কিছুতেই'],
    wrong: [
      'ঠিক, 415 ভোল্টে আর কী-ই বা হবে',
      'আচ্ছা, এখনই হাত দিয়ে জুড়ে ফেলি',
      'হ্যাঁ, এতটুকু ভোল্টে ভয়ের কিছু নেই',
      'ঠিক আছে, পিপিই ছাড়াই সেরে নিই',
      'হ্যাঁ, তাড়াতাড়ি হাত লাগিয়ে দিই',
    ],
    asks: ['কী করবেন?', 'ও বলছে এখনই হাত দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerSfu = CoworkerScript(
    line: 'DTR-এর LT বন্ধের দরকার নেই, SFU নামালেই হবে — 415 ভোল্টই তো।',
    exitLine: coworkerExit,
    right: ['না, SFU নামালেও বাসবার লাইভ থাকে', 'না, আগে DTR-এর LT বন্ধ করে নেব', 'না, ডেড প্রমাণ না করে হাত নয়'],
    wrong: [
      'ঠিক, SFU নামিয়েই জুড়ে দিই',
      'আচ্ছা, LT বন্ধের ঝামেলা থাক তবে',
      'হ্যাঁ, 415 ভোল্টে কিছু হবে না',
      'ঠিক আছে, SFU-টুকুই যথেষ্ট হবে',
      'হ্যাঁ, LT চালু রেখেই সেরে ফেলি',
    ],
    asks: ['কী করবেন?', 'ও বলছে শুধু SFU নামাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6NwPush p) => switch (p) {
        M6NwPush.myth => coworkerMyth,
        M6NwPush.sfuOnly => coworkerSfu,
      };
  static const allCoworkers = [coworkerMyth, coworkerSfu];

  static String callHeld(M6NwPush p) => switch (p) {
        M6NwPush.myth => 'ঠিক! 415 ভোল্টও মারাত্মক — আগে LT বন্ধ, তালা-ট্যাগ, ডেড প্রমাণ।',
        M6NwPush.sfuOnly => 'ঠিক! SFU নামালেও বাসবার লাইভ — আগে DTR-এর LT বন্ধ।',
      };

  static const allSet = 'নতুন গলিতে আলো — ফেজ ঠিক, নাট টাইট, দরজায় তালা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে LT বন্ধ, তালা-ট্যাগ, টেস্টারে ডেড প্রমাণ, তারপর কোর জোড়া।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtIsolate = 'LT বন্ধ, তালা-ট্যাগ, ডেড প্রমাণ — তবে হাত';
  static const caughtPhases = 'ড্রপার দেখে R-Y-B মিলিয়ে জোড়া';
  static const caughtNeutral = 'নিউট্রাল লিঙ্কে N, আর্থে আর্মার';
  static const caughtTight = 'প্রতিটা নাট পুরো টাইট';
  static const caughtLock = 'দরজা বন্ধ করে তালা';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        landFirst,
        notLit,
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks.where((a) => !_oldAsks.contains(a)),
        for (final p in M6NwPush.values) callHeld(p),
        allSet,
        fail,
        for (final m in M6PillarNewwayMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M6PillarNewwayMistakes {
  static const _dir = 'assets/game/art/m6_pillar_newway';

  // DRAFT wording — owner (M6-12), except where noted.
  /// A hand or tool inside the pillar with the DTR's LT ON (X4): deadly.
  static const liveHands = DoMistake(
    key: '6.9/m6_pillar_newway/live-hands',
    textBn: 'DTR-এর LT চালু — পিলারের বাসবার আর ড্রপার লাইভ! আগে LT বন্ধ, তালা-ট্যাগ, টেস্টারে ডেড প্রমাণ — তবেই ভেতরে হাত।',
    art: '$_dir/live_hands.svg',
    deadly: true,
    lessonPoint: 1,
  );
  /// Listening to (A), lesson myth 1: its reality.
  static const mythHands = DoMistake(
    key: '6.9/m6_pillar_newway/myth-415',
    textBn: 'ভুল — 415 ভোল্ট মারাত্মক শক দেওয়ার জন্য যথেষ্ট, আর ফল্ট কারেন্টের আর্ক ফ্ল্যাশ মুহূর্তে পুড়িয়ে দেয়। লাইভ পিলারে হাত নয়।',
    art: '$_dir/live_hands.svg',
    deadly: true,
    lessonPoint: 1,
  );
  /// Listening to (B): the way's SFU OFF, the bars still live.
  static const sfuOnly = DoMistake(
    key: '6.9/m6_pillar_newway/sfu-only',
    textBn: 'SFU নামালেও বাসবার আর ড্রপার লাইভ থাকে! DTR-এর LT বন্ধ, তালা-ট্যাগ, টেস্টারে ডেড প্রমাণ — তারপরই জোড়া।',
    art: '$_dir/live_hands.svg',
    deadly: true,
    lessonPoint: 1,
  );
  // The isolation's slips (N4, N9): m3_pillar_fuse's words (lesson 6.9's
  // safety tip now says it: point 2).
  static const noLockTag = DoMistake(
    key: '6.9/m6_pillar_newway/no-lock-tag',
    textBn: 'সুইচ বন্ধ করলেই হলো না — তালা আর ট্যাগ লাগান, যাতে কাজের মাঝে কেউ চালু করে না দেয়।',
    art: '$_dir/lock_prove.svg',
    lessonPoint: 1,
  );
  static const noTest = DoMistake(
    key: '6.9/m6_pillar_newway/no-test',
    textBn: 'বন্ধ জানলেও কাজের আগে টেস্টার দিয়ে যাচাই — ম্যাপ বা কথা নয়, পরীক্ষাই প্রমাণ।',
    art: '$_dir/lock_prove.svg',
    lessonPoint: 1,
  );
  static const testFirst = DoMistake(
    key: '6.9/m6_pillar_newway/test-before-proof',
    textBn: 'আগে জানা লাইভ পয়েন্টে টেস্টার যাচাই করে নিন — খারাপ টেস্টার কিন্তু চালু লাইনকেও ডেড দেখায়!',
    art: '$_dir/lock_prove.svg',
    lessonPoint: 1,
  );
  static const noReprove = DoMistake(
    key: '6.9/m6_pillar_newway/no-reprove',
    textBn: 'ভোল্টেজ মাপার পর আবার জানা লাইভে টেস্টার দেখে নিন — মাঝপথে টেস্টার বিগড়ালে "0 V"-র কোনো ভরসা নেই!',
    art: '$_dir/lock_prove.svg',
    lessonPoint: 1,
  );
  /// No PPE after a proven isolation (A5): m3_pillar_fuse's words.
  static const noPpe = DoMistake(
    key: '6.9/m6_pillar_newway/no-ppe',
    textBn: 'পিপিই ছাড়া পিলারের ভেতরে হাত নয়! এখানে আর্ক ফ্ল্যাশ মুহূর্তে পুড়িয়ে দেয় — আগে পুরো পিপিই, ইনসুলেটেড টুল।',
    art: '$_dir/no_ppe.svg',
    lessonPoint: 1,
  );
  /// A core landed with the spare way's SFU still ON (inferred; owner).
  static const sfuOn = DoMistake(
    key: '6.9/m6_pillar_newway/sfu-on',
    textBn: 'স্পেয়ার ওয়ের SFU এখনও ON — কোর জোড়ার আগে SFU OFF করুন; দরজা বন্ধ না হওয়া পর্যন্ত OFF থাকবে।',
    art: '$_dir/sfu_on.svg',
    lessonPoint: 1,
  );
  static const wrongPhase = DoMistake(
    key: '6.9/m6_pillar_newway/wrong-phase',
    textBn: 'এই টার্মিনালে এই ফেজ নয় — প্রতিটা ফেজ কোর যায় তার নিজের বাসবারের ফিউজ ইউনিটে। R-Y-B উল্টালে গ্রাহকের থ্রি-ফেজ যন্ত্র নষ্ট হতে পারে।',
    art: '$_dir/wrong_phase.svg',
    lessonPoint: 1,
  );
  static const neutralWrong = DoMistake(
    key: '6.9/m6_pillar_newway/neutral-wrong',
    textBn: 'নিউট্রাল কোর ফিউজ ইউনিটে বা আর্থে নয় — সব নিউট্রাল যায় কমন নিউট্রাল লিঙ্কে।',
    art: '$_dir/neutral_wrong.svg',
    lessonPoint: 1,
  );
  static const armourWrong = DoMistake(
    key: '6.9/m6_pillar_newway/armour-wrong',
    textBn: 'আর্মার নিউট্রাল লিঙ্কে বা ফিউজে নয় — বডি আর কেবিলের আর্মার আর্থ হয় আর্থিং টার্মিনালে।',
    art: '$_dir/armour.svg',
    lessonPoint: 1,
  );
  /// The armour left hanging at the door shut (M6-1: one end only = slip).
  static const armourMissing = DoMistake(
    key: '6.9/m6_pillar_newway/armour-missing',
    textBn: 'কেবিলের আর্মার ঝুলে আছে — আর্থিং টার্মিনালে না জুড়ে দরজা বন্ধ নয়।',
    art: '$_dir/armour.svg',
    lessonPoint: 1,
  );
  static const looseLug = DoMistake(
    key: '6.9/m6_pillar_newway/loose-lug',
    textBn: 'একটা লাগ ঢিলা ছিল — চালু হতেই গরম হয়ে হটস্পট! ঢিলা কানেকশনে স্পার্কিং হয়, পুড়ে যায়। নাট পুরো টাইট দিন।',
    art: '$_dir/loose_lug.svg',
    lessonPoint: 2,
  );
  /// The LT or the SFU switched ON with the pillar door open (N5).
  static const onDoorOpen = DoMistake(
    key: '6.9/m6_pillar_newway/on-door-open',
    textBn: 'পিলারের দরজা খোলা রেখে LT বা SFU চালু নয় — আগে দরজা বন্ধ, তারপর চালু!',
    art: '$_dir/door_open.svg',
    lessonPoint: 0,
  );
  // Pro tip 1 (the door): point 1's daily check (the door shut properly);
  // m3_pillar_fuse's words.
  static const doorOpen = DoMistake(
    key: '6.9/m6_pillar_newway/door-open',
    textBn: 'দরজা খোলা রেখে কাজ শেষ নয় — বাচ্চা আর পথচারীর জন্য মারাত্মক বিপদ। বন্ধ করে তালা দিন।',
    art: '$_dir/door_open.svg',
    lessonPoint: 0,
  );
  static const noLock = DoMistake(
    key: '6.9/m6_pillar_newway/no-lock',
    textBn: 'দরজা শুধু ভেজালেই হবে না — তালা দিন, যাতে কেউ লাইভ বক্স খুলতে না পারে।',
    art: '$_dir/door_open.svg',
    lessonPoint: 0,
  );

  /// Listening to his push is the act it pushes (X2/B1): both deadly.
  static DoMistake push(M6NwPush p) => switch (p) {
        M6NwPush.myth => mythHands,
        M6NwPush.sfuOnly => sfuOnly,
      };

  static const List<DoMistake> all = [
    liveHands,
    mythHands,
    sfuOnly,
    noLockTag,
    noTest,
    testFirst,
    noReprove,
    noPpe,
    sfuOn,
    wrongPhase,
    neutralWrong,
    armourWrong,
    armourMissing,
    looseLug,
    onDoorOpen,
    doorOpen,
    noLock,
  ];
}

/// The lesson point (0-based) for the fail panel's "পাঠে দেখুন".
int m6NwLessonPoint(M6NwStage s) => switch (s) {
      M6NwStage.isolate || M6NwStage.phases || M6NwStage.neutral || M6NwStage.lit => 1,
      M6NwStage.door => 0,
    };

@immutable
class M6NwDeal {
  const M6NwDeal({
    required this.perm,
    required this.sigma,
    required this.slots,
    required this.nLeft,
    required this.entryLeft,
    required this.lane,
    required this.push,
  });

  /// Fuse unit i is fed from bar perm[i] (0 R, 1 Y, 2 B).
  final List<int> perm;

  /// Where dropper i comes out over the shroud (column).
  final List<int> sigma;

  /// The lugs' rest slots (slots[k] rests in slot k).
  final List<M6NwCore> slots;

  /// The neutral link on the left (the earthing terminal on the right).
  final bool nLeft;

  /// The cable comes up at the left (else nearer the middle).
  final bool entryLeft;
  final int lane;
  final M6NwPush push;

  /// The fuse unit fed from [phase].
  int fuseOf(int phase) => perm.indexOf(phase);
}

/// The six ways three droppers can feed three fuse units.
const List<List<int>> kM6NwPerms = [
  [0, 1, 2],
  [0, 2, 1],
  [1, 0, 2],
  [1, 2, 0],
  [2, 0, 1],
  [2, 1, 0],
];

M6NwDeal m6NwDeal(math.Random rng) {
  final perm = kM6NwPerms[rng.nextInt(6)];
  // The columns over the shroud never show the feed straight: never the same
  // order as the bars' fuse units (so a straight run gives nothing away).
  List<int> sigma;
  do {
    sigma = [...kM6NwPerms[rng.nextInt(6)]];
  } while (sigma[0] == 0 && sigma[1] == 1 && sigma[2] == 2);
  final slots = [...M6NwCore.values]..shuffle(rng);
  return M6NwDeal(
    perm: perm,
    sigma: sigma,
    slots: slots,
    nLeft: rng.nextBool(),
    entryLeft: rng.nextBool(),
    lane: 2 + rng.nextInt(8),
    push: M6NwPush.values[rng.nextInt(2)],
  );
}

/// The play state (pure logic).
class M6NwRun {
  M6NwRun(this.deal);
  final M6NwDeal deal;

  int slips = 0;
  int stageSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  var ppe = false;

  /// The DTR's LT switch feeding the pillar; [lockTag] = locked and tagged.
  var ltOn = true;
  var lockTag = false;

  /// The tester in hand; proved on a live source before the bar reading,
  /// the 0 V seen on the bars, proved again after it (live-dead-live).
  var tester = false;
  var provedBefore = false;
  var deadSeen = false;
  var provedAfter = false;

  /// The spare way's SFU (at ON as found).
  var sfuOn = true;
  var doorOpen = true;
  var locked = false;

  /// Lugs landed (core → terminal) and nuts seated.
  final Map<M6NwCore, int> landed = {};
  final Set<M6NwCore> tight = {};

  /// The fuse unit whose dropper was plucked last.
  int? plucked;

  /// Loose lugs glowing at switch-on (until the crew isolates again).
  List<M6NwCore> hot = const [];

  /// A loose lug was found: re-tighten (the task says so until lit).
  var refit = false;

  /// The right moves paid so far.
  final Set<M6NwStage> paid = {};
  var finished = false;

  bool get ended => finished || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => finished && deadly == null && percent >= 55;
  bool get thorough => stageSlips == 0;

  bool get _open => !ended && hot.isEmpty;

  /// Safe to work inside (owner ruling A5 / X4): the LT OFF, locked and
  /// tagged, 0 V on a tester proved before and after.
  bool get provenDead => !ltOn && lockTag && deadSeen && provedAfter;

  bool get phasesLanded => [M6NwCore.r, M6NwCore.y, M6NwCore.b].every(landed.containsKey);
  bool get coresLanded => phasesLanded && landed.containsKey(M6NwCore.n);
  bool get allLanded => coresLanded && landed.containsKey(M6NwCore.armour);
  bool get allTight => allLanded && landed.keys.every(tight.contains);

  /// The new lane is fed.
  bool get lit => ltOn && sfuOn && allLanded && hot.isEmpty && allTight;

  /// The phase reason fits a play whose three phases all went on at the first
  /// try (always — a wrong phase springs back).
  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stageSlips++;
    return m;
  }

  void wearPpe() {
    if (_open) ppe = true;
  }

  /// Picks up the tester (or puts it back). False = not now.
  bool holdTester() {
    if (!_open) return false;
    tester = !tester;
    return true;
  }

  /// The DTR's LT switch to [on]. moved = false: it did not move (locked and
  /// tagged, already there; or the slip — ON with the door open, N5).
  (bool, DoMistake?) switchLt(bool on) {
    if (!_open || lockTag || ltOn == on) return (false, null);
    if (on && doorOpen) return (false, _slip(M6PillarNewwayMistakes.onDoorOpen));
    ltOn = on;
    if (on) {
      // Back on: the proof is void.
      provedBefore = false;
      deadSeen = false;
      provedAfter = false;
      return (true, _energize());
    }
    return (true, null);
  }

  /// The spare way's SFU to [on]. ON with the door open = slip (N5).
  (bool, DoMistake?) switchSfu(bool on) {
    if (!_open || sfuOn == on) return (false, null);
    if (on && doorOpen) return (false, _slip(M6PillarNewwayMistakes.onDoorOpen));
    sfuOn = on;
    return (true, on ? _energize() : null);
  }

  /// Both switches ON and every lug on: a loose lug glows (a slip), else the
  /// lane is lit.
  DoMistake? _energize() {
    if (!ltOn || !sfuOn || !allLanded) return null;
    final loose = [for (final c in landed.keys) if (!tight.contains(c)) c];
    if (loose.isEmpty) {
      refit = false;
      _tag(M6PillarNewwayLines.caughtTight);
      return null;
    }
    hot = loose;
    refit = true;
    return _slip(M6PillarNewwayMistakes.looseLug);
  }

  /// After the loose-lug card: the crew switches it all off again (SFU OFF,
  /// LT OFF, lock and tag, the door unlocked and open); the proof is void.
  void crewIsolate() {
    if (hot.isEmpty) return;
    hot = const [];
    sfuOn = false;
    ltOn = false;
    lockTag = true;
    provedBefore = false;
    deadSeen = false;
    provedAfter = false;
    locked = false;
    doorOpen = true;
  }

  /// The padlock and tag on the OFF handle (or off it). False = not now.
  bool toggleLockTag() {
    if (!_open || ltOn) return false;
    lockTag = !lockTag;
    return true;
  }

  /// The tester on the LT switch's supply terminals (always live): it proves
  /// the tester — before the bar reading, or again after it. False = not now.
  bool testLive() {
    if (!_open || !tester) return false;
    if (deadSeen) {
      provedAfter = true;
    } else {
      provedBefore = true;
    }
    return true;
  }

  /// The tester on the bars (the door open): (live, the mistake). A live
  /// reading is never punished (A9) and proves the tester (a known live
  /// source); a 0 V on a tester not yet proved = N9.
  (bool, DoMistake?) testBars() {
    if (!_open || !doorOpen || !tester) return (false, null);
    if (ltOn) {
      // A live reading on the bars proves the tester too (before any 0 V).
      if (!deadSeen) provedBefore = true;
      return (true, null);
    }
    if (!provedBefore) return (false, _slip(M6PillarNewwayMistakes.testFirst));
    deadSeen = true;
    provedAfter = false;
    return (false, null);
  }

  /// Why a hand may not go inside yet: the LT ON is deadly (X4); no lock and
  /// tag, no proof, no proof after (N4), no PPE (A5) = slips.
  DoMistake? handIn() {
    if (ltOn) return deadly = M6PillarNewwayMistakes.liveHands;
    if (!lockTag) return _slip(M6PillarNewwayMistakes.noLockTag);
    if (!deadSeen) return _slip(M6PillarNewwayMistakes.noTest);
    if (!provedAfter) return _slip(M6PillarNewwayMistakes.noReprove);
    if (!ppe) return _slip(M6PillarNewwayMistakes.noPpe);
    return null;
  }

  /// A dropper plucked (a hand inside). Null and [plucked] set = it twangs.
  DoMistake? pluck(int fuse) {
    if (!_open || !doorOpen) return null;
    final m = handIn();
    if (m != null) return m;
    plucked = fuse;
    return null;
  }

  /// The terminal [t] is free.
  bool free(int t) => !landed.containsValue(t);

  /// A lug dropped on terminal [t]. Null and landed = it is on (its nut
  /// finger-tight); null and not landed = nothing (the terminal is taken).
  DoMistake? land(M6NwCore core, int t) {
    if (!_open || !doorOpen || landed.containsKey(core) || !free(t)) return null;
    final m = handIn();
    if (m != null) return m;
    if (sfuOn) return _slip(M6PillarNewwayMistakes.sfuOn);
    final right = switch (core) {
      M6NwCore.n => t == kM6NwNLink,
      M6NwCore.armour => t == kM6NwEarth,
      _ => t < 3 && deal.perm[t] == core.index,
    };
    if (!right) {
      return _slip(switch (core) {
        M6NwCore.n => M6PillarNewwayMistakes.neutralWrong,
        M6NwCore.armour => M6PillarNewwayMistakes.armourWrong,
        _ => M6PillarNewwayMistakes.wrongPhase,
      });
    }
    landed[core] = t;
    plucked = null;
    if (phasesLanded) _tag(M6PillarNewwayLines.caughtPhases);
    if (landed.containsKey(M6NwCore.n) && landed.containsKey(M6NwCore.armour)) _tag(M6PillarNewwayLines.caughtNeutral);
    return null;
  }

  /// The spanner put on a landed nut (a hand inside): the mistake, if any.
  DoMistake? spanner(M6NwCore core) {
    if (!_open || !doorOpen || !landed.containsKey(core)) return null;
    return handIn();
  }

  /// The spanner held until the nut seated.
  void seat(M6NwCore core) {
    if (_open && landed.containsKey(core)) tight.add(core);
  }

  /// The door shut (a drag). False = it stays open: not every core is on yet
  /// (nothing), or the armour hangs (the slip, M6-1).
  (bool, DoMistake?) shutDoor() {
    if (!_open || !doorOpen) return (false, null);
    if (!coresLanded) return (false, null);
    if (!landed.containsKey(M6NwCore.armour)) return (false, _slip(M6PillarNewwayMistakes.armourMissing));
    doorOpen = false;
    return (true, null);
  }

  /// The door opened (a drag). False = locked or open already.
  bool openDoor() {
    if (!_open || doorOpen || locked) return false;
    doorOpen = true;
    return true;
  }

  /// The padlock goes on: only on the shut door of a lit way.
  bool get canLock => _open && !doorOpen && !locked && lit;

  bool lock() {
    if (!canLock) return false;
    locked = true;
    _tag(M6PillarNewwayLines.caughtLock);
    return true;
  }

  /// The trainee heads for the van: before the lane is lit nothing happens
  /// (null, not done); the door open or unlocked = slips.
  DoMistake? leave() {
    if (!_open || !lit) return null;
    if (doorOpen) return _slip(M6PillarNewwayMistakes.doorOpen);
    if (!locked) return _slip(M6PillarNewwayMistakes.noLock);
    return null;
  }

  /// A right move's ◆ go on the table (once each).
  bool pay(M6NwStage s) {
    if (ended || !paid.add(s)) return false;
    if (s == M6NwStage.isolate) _tag(M6PillarNewwayLines.caughtIsolate);
    return true;
  }

  void nextStage() => stageSlips = 0;

  /// The stage whose ◆ are due now (null: none).
  M6NwStage? get due {
    if (ended) return null;
    if (!paid.contains(M6NwStage.isolate) && provenDead) return M6NwStage.isolate;
    if (!paid.contains(M6NwStage.phases) && phasesLanded) return M6NwStage.phases;
    if (!paid.contains(M6NwStage.neutral) && landed.containsKey(M6NwCore.n) && landed.containsKey(M6NwCore.armour)) return M6NwStage.neutral;
    if (!paid.contains(M6NwStage.lit) && lit) return M6NwStage.lit;
    if (!paid.contains(M6NwStage.door) && locked) return M6NwStage.door;
    return null;
  }

  /// The reason for a stage (it fits what was done).
  M6NwWhy why(M6NwStage s) => switch (s) {
        M6NwStage.isolate => M6NwWhy.isolate,
        M6NwStage.phases => M6NwWhy.order,
        M6NwStage.neutral => M6NwWhy.neutral,
        M6NwStage.lit => M6NwWhy.tighten,
        M6NwStage.door => M6NwWhy.door,
      };

  /// Listening to the coworker (deadly).
  void failDeadly(DoMistake m) => deadly ??= m;

  void finish() {
    if (deadly == null) finished = true;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action: PPE, SFU OFF, LT OFF, lock and tag, tester,
/// prove, 0 V, prove again ≈ 12000; three plucks ≈ 4500; five lugs landed and
/// held ≈ 15000; door, lock and tag off, LT ON, SFU ON, padlock ≈ 7500;
/// reasons ≈ 41000 (five); the coworker once ≈ 9600 → ≈ 89600. 85 % ≈ 76200
/// → 80 s
/// (a builder's estimate; the owner may tune).
const m6PillarNewwayQuickMs = 80000;

@immutable
class M6PillarNewwayPack {
  const M6PillarNewwayPack({required this.id, required this.titleBn, this.quickMs = m6PillarNewwayQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6PillarNewwayPack> m6PillarNewwayPacks = {
  'do_6_9_b': M6PillarNewwayPack(id: 'do_6_9_b', titleBn: M6PillarNewwayLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M6PillarNewwayProbe {
  static M6NwRun? run;
}

/// How long the spanner (or the padlock) is held.
const kM6NwHoldMs = 900;

// ============================================================================
// Page
// ============================================================================

class M6PillarNewwayPage extends StatefulWidget {
  const M6PillarNewwayPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6PillarNewwayPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6PillarNewwayPage> createState() => _M6PillarNewwayPageState();
}

class _M6PillarNewwayPageState extends State<M6PillarNewwayPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _NwRunPage(
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

class _NwRunPage extends ConsumerStatefulWidget {
  const _NwRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6PillarNewwayPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_NwRunPage> createState() => _NwRunPageState();
}

/// What a touch took hold of.
/// [done]: a hold completed under the finger (its release does nothing).
enum _Grab { tap, lug, nut, doorShut, hasp, lt, sfu, done }

class _NwRunPageState extends ConsumerState<_NwRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6NwRun _run;
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

  /// The touch in progress.
  int? _ptrId;
  _Grab _grab = _Grab.tap;
  Offset _from = Offset.zero;
  Offset _now = Offset.zero;
  Offset _fromGlobal = Offset.zero;
  M6NwCore? _lug;
  M6NwCore? _nut;

  /// The hold ring (the spanner on a nut, the padlock).
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: kM6NwHoldMs));
  Offset? _ringAt;

  /// The last pluck (its twang replays on every pluck).
  int _plucks = 0;

  /// The tester's last reading.
  Offset? _readAt;
  var _readLive = false;

  /// The loose-lug glance at switch-on.
  var _glance = false;
  Offset _glanceAt = Offset.zero;

  /// The lug landed last (the spanner hint goes there).
  M6NwCore? _lastLanded;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M6NwGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6NwRun(m6NwDeal(widget.rng));
    M6PillarNewwayProbe.run = _run;
    _hold.addStatusListener(_holdStatus);
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _hold.dispose();
    if (identical(M6PillarNewwayProbe.run, _run)) M6PillarNewwayProbe.run = null;
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

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && !_glance && _run.hot.isEmpty;

  String get _task {
    if (!_run.paid.contains(M6NwStage.isolate)) return M6PillarNewwayLines.askReady;
    if (_run.refit) return M6PillarNewwayLines.askFix;
    if (!_run.allLanded) return M6PillarNewwayLines.askLand;
    if (!_run.lit) return M6PillarNewwayLines.askSwitch;
    return M6PillarNewwayLines.askFinish;
  }

  Future<void> _start() async {
    _clock.start();
    scheduleCoworker();
    unawaited(_sayChain([_task]));
  }

  /// Every control that would change what his push fits waits for him.
  bool _waitForHim() => holdForCoworker();

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  void _clearReading() {
    _readAt = null;
  }

  // --- touches ---------------------------------------------------------------------
  void _down(PointerDownEvent e, M6NwGeo geo) {
    if (_ptrId != null) return;
    if (!_canPlay) return;
    final p = e.localPosition;
    _ptrId = e.pointer;
    _from = p;
    _now = p;
    _fromGlobal = e.position;
    _lug = null;
    _nut = null;
    _grab = _grabAt(p, geo);
    switch (_grab) {
      case _Grab.nut:
        _startSpanner(geo);
      case _Grab.hasp:
        if (_run.canLock) _startRing(geo.hasp);
      case _Grab.lug:
      case _Grab.tap:
      case _Grab.doorShut:
      case _Grab.lt:
      case _Grab.sfu:
      case _Grab.done:
        break;
    }
  }

  _Grab _grabAt(Offset p, M6NwGeo geo) {
    final r = _run;
    if (r.doorOpen) {
      if (geo.doorOpenHit.contains(p)) return _Grab.doorShut;
      for (var slot = 0; slot < 5; slot++) {
        final c = r.deal.slots[slot];
        if (!r.landed.containsKey(c) && geo.lugHit(slot).contains(p)) {
          _lug = c;
          return _Grab.lug;
        }
      }
      for (final e in r.landed.entries) {
        if (geo.termHit(e.value, r.deal.nLeft).contains(p)) {
          _nut = e.key;
          return _Grab.nut;
        }
      }
    } else if (geo.haspHit.contains(p)) {
      return _Grab.hasp;
    }
    if (geo.ltHandleHit.contains(p)) return _Grab.lt;
    if (geo.sfuHit.contains(p)) return _Grab.sfu;
    return _Grab.tap;
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _ptrId) return;
    _now = e.localPosition;
    final moved = (_now - _from).distance;
    switch (_grab) {
      case _Grab.lug:
        if (!_canPlay) {
          _cancel();
          return;
        }
        setState(() {});
      case _Grab.nut:
      case _Grab.hasp:
        if (moved > 16 && _ringAt != null) _stopRing();
      case _Grab.tap:
      case _Grab.doorShut:
      case _Grab.lt:
      case _Grab.sfu:
      case _Grab.done:
        break;
    }
  }

  void _up(PointerUpEvent e, M6NwGeo geo) {
    if (e.pointer != _ptrId) return;
    _ptrId = null;
    _now = e.localPosition;
    final d = _now - _from;
    final still = d.distance < 14;
    final grab = _grab;
    _grab = _Grab.tap;
    if (_ringAt != null) _stopRing();
    if (!_canPlay) {
      _lug = null;
      setState(() {});
      return;
    }
    switch (grab) {
      case _Grab.lug:
        final core = _lug!;
        _lug = null;
        if (still) {
          setState(() {});
          _hints.missTap();
          return;
        }
        _drop(core, _now, geo, e.position);
      case _Grab.nut:
        // An early release leaves the nut as it was (no message).
        _nut = null;
      case _Grab.doorShut:
        if (d.dx > 40) {
          _shutDoor(e.position);
        } else if (still) {
          _hints.missTap();
        }
      case _Grab.hasp:
        if (d.dx < -40) {
          _openDoor();
        } else if (still && !_run.canLock) {
          _hints.missTap();
        }
      case _Grab.lt:
        if (d.dy > 22) {
          _switchLt(false, e.position);
        } else if (d.dy < -22) {
          _switchLt(true, e.position);
        } else {
          _hints.missTap();
        }
      case _Grab.sfu:
        if (d.dy > 22) {
          _switchSfu(false, e.position);
        } else if (d.dy < -22) {
          _switchSfu(true, e.position);
        } else {
          _hints.missTap();
        }
      case _Grab.tap:
        if (still) _tap(_from, geo, e.position);
      case _Grab.done:
        break;
    }
  }

  void _cancel() {
    _ptrId = null;
    _grab = _Grab.tap;
    _lug = null;
    _nut = null;
    if (_ringAt != null) _stopRing();
    if (mounted) setState(() {});
  }

  // --- the hold ring ---------------------------------------------------------------
  void _startRing(Offset at) {
    setState(() => _ringAt = at);
    _hold.forward(from: 0);
  }

  void _stopRing() {
    _hold.stop();
    _hold.value = 0;
    setState(() => _ringAt = null);
  }

  void _holdStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    final nut = _nut;
    setState(() => _ringAt = null);
    _hold.value = 0;
    if (!_canPlay) return;
    if (nut != null) {
      _nut = null;
      if (_ptrId != null) _grab = _Grab.done;
      _run.seat(nut);
      HapticFeedback.mediumImpact();
      _cue('sounds/intro/click.ogg', volume: 0.6);
      _stepDone();
      return;
    }
    if (_grab == _Grab.hasp) {
      _grab = _Grab.done;
      if (_run.lock()) {
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
        _stepDone();
        _checkDue();
      }
    }
  }

  void _startSpanner(M6NwGeo geo) {
    final core = _nut!;
    if (_waitForHim()) {
      _nut = null;
      return;
    }
    final m = _run.spanner(core);
    if (m != null) {
      _nut = null;
      _flashAt = geo.term(_run.landed[core]!, _run.deal.nLeft);
      setState(() => _wake++);
      unawaited(_mistake(m, _fromGlobal));
      return;
    }
    _clearReading();
    _startRing(geo.term(_run.landed[core]!, _run.deal.nLeft));
  }

  // --- moves -----------------------------------------------------------------------
  void _tap(Offset p, M6NwGeo geo, Offset global) {
    final r = _run;
    if (geo.ppe.contains(p)) {
      if (r.deal.push == M6NwPush.myth && _waitForHim()) return;
      if (r.ppe) {
        _hints.missTap();
        return;
      }
      _tick('sounds/learn/tag_slap.ogg', 0.5);
      r.wearPpe();
      _stepDone();
      return;
    }
    if (geo.testerHit.contains(p)) {
      if (r.holdTester()) {
        _tick('sounds/intro/click.ogg', 0.55);
        _clearReading();
        _stepDone();
      }
      return;
    }
    if (geo.ltSupply.contains(p)) {
      if (!r.tester) {
        _hints.missTap();
        return;
      }
      r.testLive();
      _tick('sounds/intro/click.ogg', 0.55);
      _readAt = geo.ltSupply.center;
      _readLive = true;
      _stepDone();
      _checkDue();
      return;
    }
    if (geo.ltLockHit.contains(p)) {
      if (r.toggleLockTag()) {
        _tick('sounds/learn/tag_slap.ogg', 0.55);
        _clearReading();
        _stepDone();
        _checkDue();
      } else {
        _hints.missTap();
      }
      return;
    }
    if (geo.van.contains(p)) {
      _leave(global);
      return;
    }
    if (r.doorOpen) {
      if (r.tester && geo.barsHit.contains(p)) {
        final (live, m) = r.testBars();
        _tick('sounds/intro/click.ogg', 0.55);
        if (m != null) {
          setState(() => _wake++);
          unawaited(_mistake(m, global));
          return;
        }
        _readAt = Offset(p.dx.clamp(70.0, 220.0), geo.barY(0));
        _readLive = live;
        _stepDone();
        return;
      }
      for (var i = 0; i < 3; i++) {
        if (geo.pluckHit(i).contains(p)) {
          _pluck(i, geo, global);
          return;
        }
      }
    }
    _hints.missTap();
  }

  void _pluck(int i, M6NwGeo geo, Offset global) {
    if (_waitForHim()) return;
    final m = _run.pluck(i);
    if (m != null) {
      _flashAt = Offset(M6NwGeo.fuseX[i], geo.shroudBot);
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.plucked != i) return;
    _clearReading();
    HapticFeedback.lightImpact();
    _cue('sounds/intro/glass.ogg', volume: 0.5);
    _plucks++;
    _stepDone();
  }

  void _drop(M6NwCore core, Offset at, M6NwGeo geo, Offset global) {
    // The nearest free terminal within reach.
    int? t;
    var best = 34.0;
    for (var k = 0; k < kM6NwTerms; k++) {
      final dd = (geo.term(k, _run.deal.nLeft) - at).distance;
      if (dd < best && _run.free(k)) {
        best = dd;
        t = k;
      }
    }
    if (t == null) {
      // Back to rest, no cost.
      setState(() => _wake++);
      _hints.missTap();
      return;
    }
    if (_waitForHim()) {
      setState(() => _wake++);
      return;
    }
    final m = _run.land(core, t);
    if (m != null) {
      _flashAt = geo.term(t, _run.deal.nLeft);
      HapticFeedback.heavyImpact();
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (!_run.landed.containsKey(core)) {
      setState(() => _wake++);
      return;
    }
    _lastLanded = core;
    _clearReading();
    _tick('sounds/intro/impact_metal.ogg', 0.5);
    _stepDone();
    _checkDue();
  }

  void _switchLt(bool on, Offset global) {
    if (_waitForHim()) return;
    final (moved, m) = _run.switchLt(on);
    _afterSwitch(moved, m, global);
  }

  void _switchSfu(bool on, Offset global) {
    if (_waitForHim()) return;
    final (moved, m) = _run.switchSfu(on);
    _afterSwitch(moved, m, global);
  }

  void _afterSwitch(bool moved, DoMistake? m, Offset global) {
    if (m == M6PillarNewwayMistakes.looseLug) {
      HapticFeedback.mediumImpact();
      _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
      unawaited(_looseGlance(m!, global));
      return;
    }
    if (m != null) {
      HapticFeedback.heavyImpact();
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (!moved) {
      HapticFeedback.heavyImpact();
      _hints.missTap();
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    _clearReading();
    _stepDone();
    // The lane lit (every nut proved tight): its ◆ and the tightening reason.
    if (_run.lit) _checkDue();
  }

  /// A loose lug at switch-on: a one-beat glance at its glow, then the slip.
  Future<void> _looseGlance(DoMistake m, Offset global) async {
    final geo = _geoNow;
    final core = _run.hot.first;
    if (geo != null) _glanceAt = geo.term(_run.landed[core]!, _run.deal.nLeft);
    _hush();
    setState(() {
      _glance = true;
      _wake++;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 1300));
    if (!mounted || _ended) return;
    setState(() => _glance = false);
    unawaited(_mistake(m, global));
  }

  void _shutDoor(Offset global) {
    final (shut, m) = _run.shutDoor();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (!shut) {
      _tick();
      unawaited(_sayChain([M6PillarNewwayLines.landFirst]));
      return;
    }
    _clearReading();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.55);
    _stepDone();
  }

  void _openDoor() {
    if (!_run.openDoor()) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    _stepDone();
  }

  void _leave(Offset global) {
    final m = _run.leave();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    _tick();
    unawaited(_sayChain([_run.lit ? _task : M6PillarNewwayLines.notLit]));
  }

  /// A right move's ◆ on the table, then its reason.
  void _checkDue() {
    final s = _run.due;
    if (s == null || !_run.pay(s)) return;
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    _run.nextStage();
    _stage = s;
    final topic = _run.why(s);
    unawaited(askReason(
      deal: () => dealChoices(M6PillarNewwayLines.whyRight[topic]!, M6PillarNewwayLines.myths, widget.rng),
      question: M6PillarNewwayLines.whyQ[topic]!,
      stillValid: () => !_ended,
    ));
  }

  /// The stage whose reason is up.
  M6NwStage? _stage;

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
    final s = _stage;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (!mounted || _ended) return;
      if (s == M6NwStage.door) {
        _run.finish();
        unawaited(_finish());
        return;
      }
      setState(() => _wake++);
      // Another right move may already be due (none now: one at a time).
      unawaited(_sayChain([_task]));
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6PillarNewwayLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;

  /// His push fits only before the isolation: (A) while the PPE is still on
  /// its stand, (B) while the SFU is still ON.
  bool get _pushFits {
    final r = _run;
    if (!r.ltOn || r.lockTag) return false;
    return switch (r.deal.push) {
      M6NwPush.myth => !r.ppe,
      M6NwPush.sfuOnly => r.sfuOn,
    };
  }

  @override
  bool? coworkerCanCome() {
    if (_ended || !_pushFits) return null;
    if (_intro || _card != null || tableBusy || _freeze || _glance || _ptrId != null) return false;
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
      final m = M6PillarNewwayMistakes.push(p);
      final geo = _geoNow;
      if (geo != null) _flashAt = geo.flashAt;
      _run.failDeadly(m);
      await _deadly(m);
      return;
    }
    _run.caught.add(M6PillarNewwayLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6PillarNewwayLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6PillarNewwayLines.tapWhy[_nudgeN++ % M6PillarNewwayLines.tapWhy.length]
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6nw/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A hand into the live pillar: the scene freezes grey and the arc flash
  /// comes off the copper in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _cancel();
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
    final speak = await SpokenOnce.first('m6nw/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6PillarNewwayLines.deadlyWord : M6PillarNewwayLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The play goes on from where it was (after a loose lug, the crew
        // has switched it all off again).
        _hush();
        setState(() {
          _run.crewIsolate();
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
    await _say(!_run.passed ? M6PillarNewwayLines.fail : (_quickBonus ? M6PillarNewwayLines.quick : M6PillarNewwayLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_lug != null || _ringAt != null || _run.tester) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6NwRig get _rig {
    final r = _run;
    final d = r.deal;
    return M6NwRig(
      perm: d.perm,
      sigma: d.sigma,
      slots: d.slots,
      nLeft: d.nLeft,
      entryLeft: d.entryLeft,
      lane: d.lane,
      ppe: r.ppe,
      ltOn: r.ltOn,
      lockTag: r.lockTag,
      testerInHand: r.tester,
      sfuOn: r.sfuOn,
      doorOpen: r.doorOpen,
      locked: r.locked,
      landed: Map.of(r.landed),
      dragging: _lug != null && _grab == _Grab.lug ? _lug : null,
      plucked: r.plucked,
      lit: r.lit,
      hot: r.hot,
      readAt: _readAt,
      readLive: _readLive,
    );
  }

  /// The gesture hand: how to touch, never what.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final r = _run;
    final n = _hintN++;
    const s = HintSpace.scene;
    final lugs = [for (var k = 0; k < 5; k++) if (!r.landed.containsKey(r.deal.slots[k])) geo.lugHit(k)];
    final terms = [for (var k = 0; k < kM6NwTerms; k++) geo.termHit(k, r.deal.nLeft)];
    if (!r.paid.contains(M6NwStage.isolate) || (r.refit && !r.provenDead)) {
      // Get ready / prove dead again: the stand, the LT box, the SFU, the
      // tester and the cores alike.
      return HintSpec.sweep([geo.ppe, geo.ltBox, geo.sfuHit, geo.testerHit, if (r.doorOpen) ...lugs], space: s);
    }
    if (r.doorOpen && !r.allLanded) {
      final last = _lastLanded;
      if (last != null && r.landed.containsKey(last) && !r.tight.contains(last) && n.isEven) {
        return HintSpec.hold(geo.term(r.landed[last]!, r.deal.nLeft), space: s);
      }
      return switch (n % 3) {
        0 => HintSpec.sweep([for (var i = 0; i < 3; i++) geo.pluckHit(i)], space: s),
        1 when lugs.isNotEmpty => HintSpec.drag(lugs.first.center, toward: const Offset(0, -1), travel: 40, space: s),
        _ => HintSpec.sweep(terms, space: s),
      };
    }
    if (r.doorOpen && r.refit) {
      return HintSpec.sweep(terms, space: s);
    }
    if (r.doorOpen) {
      return n.isEven ? HintSpec.drag(geo.doorOpenHit.center, toward: const Offset(1, 0), travel: 50, space: s) : HintSpec.sweep([geo.sfuHit, geo.ltBox, geo.doorOpenHit], space: s);
    }
    if (!r.lit) return HintSpec.sweep([geo.sfuHit, geo.ltBox, geo.haspHit], space: s);
    return HintSpec.sweep([geo.van, geo.haspHit], space: s);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6NwGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final r = _run;
    final world = Stack(
      children: [
        Positioned.fill(
          key: const ValueKey('world'),
          child: RepaintBoundary(child: CustomPaint(painter: M6NwWorldPainter(geo: geo, rig: _rig))),
        ),
        if (r.plucked != null && r.doorOpen)
          Positioned.fill(
            key: ValueKey('twang-$_plucks'),
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 750),
                builder: (_, v, _) => CustomPaint(painter: M6NwTwangPainter(path: geo.dropper(r.plucked!, r.deal.perm, r.deal.sigma), v: v)),
              ),
            ),
          ),
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: geo.trainee,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      ],
    );
    return [
      Positioned.fill(
        key: const ValueKey('world-layer'),
        child: ColorFiltered(
          colorFilter: grey,
          child: _glance
              ? TweenAnimationBuilder<double>(
                  key: const ValueKey('glance'),
                  tween: Tween(begin: quiet ? 1 : 0, end: 1),
                  duration: const Duration(milliseconds: 1100),
                  builder: (_, v, child) => Transform.scale(
                    scale: 1 + 0.16 * math.sin(math.pi * v),
                    alignment: Alignment.topLeft,
                    origin: _glanceAt,
                    child: child,
                  ),
                  child: world,
                )
              : world,
        ),
      ),
      if (_lug != null && _grab == _Grab.lug)
        Positioned.fill(
          key: const ValueKey('drag'),
          child: IgnorePointer(child: CustomPaint(painter: M6NwDragPainter(core: _lug!, at: _now, gland: geo.gland(r.deal.entryLeft)))),
        ),
      if (_ringAt != null)
        Positioned.fill(
          key: const ValueKey('ring'),
          child: IgnorePointer(child: CustomPaint(painter: M6NwRingPainter(at: _ringAt!, progress: _hold))),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6PillarNewwayLines.sceneLabel,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _down(e, geo),
            onPointerMove: _move,
            onPointerUp: (e) => _up(e, geo),
            onPointerCancel: (_) => _cancel(),
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
              builder: (_, v, _) => CustomPaint(painter: M6NwFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_glance;
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
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _ptrId == null,
            hintKey: '$_steps/${_run.paid.length}/${_run.doorOpen}/${_run.lit}/${_run.refit}',
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
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: ValueKey('why-deck-${_run.paid.length}')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 12), onLeft: coworkerFromRight),
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
                  line: M6PillarNewwayLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: m6NwLessonPoint(_stage ?? M6NwStage.isolate), muted: _muted)),
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
