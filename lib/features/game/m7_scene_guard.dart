import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm7_scene_guard_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_scene_guard_world.dart' show M7Item, M7SceneGeo, M7Site;

// Lesson 7.7 "দুর্ঘটনার রিপোর্ট (Accident Reporting): আপনার দায়িত্ব", কাজ 1
// "যেমন ছিল, তেমন থাক" (pack do_7_7_a, engineType m7_scene_guard). The aftermath
// of an accident at one of three sites (dealt): a roadside LT pole (S1), a
// village road with a snapped service wire (S2), a feeder pillar (S3). The
// supervisor has been told and is coming; until then the place is the
// trainee's. The verb: drag your own worker along the ground band to stand in
// a reaching hand's lane (palm up, the hand withdraws) — or do nothing.
//
//  1 Guide first; take position (a drag; the scene's hand shows how).
//  2 Six reaches, one at a time (4 evidence, 2 care/danger-stopping; order,
//    side and places dealt; 3.0–4.0 s each, the first 4.5 s). Blocking
//    evidence (lesson 7.7 point 4: nothing is moved or changed at the scene)
//    is right; letting a care act go on (medical care after any shock; leading
//    people away from danger / putting out an ember: the lesson's "unless to
//    stop another danger") is right. The worker walks back after every reach.
//  3 Each right resolution: praise + ◆ → the reason deck ('কেন আটকালেন?' /
//    'কেন যেতে দিলেন?') → এগিয়ে যান → the next reach.
//  4 The careless coworker once, before the site's tied reach (S1 myth 2 'ছোট
//    শক', S2 coiling the snapped wire, S3 swapping the blown fuse); the reach
//    waits for him (holdForCoworker). Listening is a slip (S1, S3) and, in
//    S2, the deadly act he pushes (owner rulings M7-3 / X2).
//  5 After six reaches the supervisor's van arrives → the pass panel.
//
// Deadly (rulings M7-2, M7-3): dragging the worker into the snapped wire's
// ground zone (S2, not marked); letting the coworker's hand coil the wire (S2)
// after the timed chance. A late block of that hand = a slip. Slips: letting
// an evidence item be moved, blocking the colleague going to the doctor,
// blocking a danger-stopping act (the hand comes again once, so blocking
// everything strikes out), listening to him in S1/S3. Letting everything go
// strikes out through the evidence slips.
//
// Built on the shared kit (GAME_LEVEL_PLAYBOOK.md): guide first, full scene
// (m7_scene_guard_world.dart), corner guide, decks, ◆ table → "কেন …?",
// coworker two beats, mistake cards, freeze, 3 slips strike out. Gesture hint
// (how, never what): a short drag from the worker while he waits to take his
// place; none during the reaches. Voice: the guide by device TTS; the
// coworker's three pushes need his recorded clips (listed for the director).

// ============================================================================
// Content
// ============================================================================

enum M7Kind { evidence, care }

/// What a care act is: medical care, or stopping another danger.
enum M7Care { doctor, danger }

/// Which reason a resolution asks for.
enum M7Why { scene, wire, doctor, danger }

const Map<M7Site, List<M7Item>> m7EvidenceOf = {
  M7Site.pole: [M7Item.ladder, M7Item.glove, M7Item.pliers, M7Item.scorch],
  M7Site.village: [M7Item.cow, M7Item.insulator, M7Item.rope, M7Item.wire],
  M7Site.pillar: [M7Item.door, M7Item.fuse, M7Item.soot, M7Item.tape],
};

/// The coworker's reach in each site (he comes before it).
const Map<M7Site, M7Item> m7TiedOf = {
  M7Site.pole: M7Item.colleague,
  M7Site.village: M7Item.wire,
  M7Site.pillar: M7Item.fuse,
};

M7Kind m7KindOf(M7Item i) => switch (i) {
      M7Item.colleague || M7Item.child || M7Item.cart || M7Item.ember => M7Kind.care,
      _ => M7Kind.evidence,
    };

M7Care? m7CareOf(M7Item i) => switch (i) {
      M7Item.colleague => M7Care.doctor,
      M7Item.child || M7Item.cart || M7Item.ember => M7Care.danger,
      _ => null,
    };

M7Why m7WhyOf(M7Item i) => switch (i) {
      M7Item.wire => M7Why.wire,
      M7Item.colleague => M7Why.doctor,
      M7Item.child || M7Item.cart || M7Item.ember => M7Why.danger,
      _ => M7Why.scene,
    };

abstract final class M7SceneGuardLines {
  static const title = 'যেমন ছিল, তেমন থাক';
  // DRAFT wording — owner (every new line below; the intro is the item spec's).
  static const intro = 'দুর্ঘটনা ঘটে গেছে! সুপারভাইজারকে খবর দেওয়া হয়েছে, তিনি আসছেন — ততক্ষণ জায়গাটা আপনার দায়িত্বে।';
  static const steps = ['হাত 1', 'হাত 2', 'হাত 3', 'হাত 4', 'হাত 5', 'হাত 6'];

  // The guide's task now (tap him: the same task, a different way).
  static const askPos = 'জায়গাটা আপনার দায়িত্বে — নিজের জায়গা নিন।';
  static const watch = ['চোখ রাখুন — কে কী ধরছে?', 'হাত কোথায় যাচ্ছে, দেখুন।', 'নজর রাখুন — এবার কে এগোচ্ছে?'];
  static const tasks = [askPos, ...watch];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  static const sceneLabel = 'দুর্ঘটনার জায়গা';

  // The why questions (spec).
  static const whyBlockQ = 'কেন আটকালেন?';
  static const whyLetQ = 'কেন যেতে দিলেন?';

  // The reasons: the right ones fit what was done; the wrong ones are field
  // excuses. 36–46 letters, one set per reason.
  static const whyRight = <M7Why, List<String>>{
    M7Why.scene: ['ঘটনাস্থল যেমন আছে তেমন থাকলে তদন্ত ঠিক হয়', 'ঘটনাস্থল বদলে ফেললে তদন্তে বাধা পড়তে পারে', 'প্রমাণ রাখা তদন্তের জন্য অত্যন্ত জরুরি'],
    M7Why.wire: ['ডেড প্রমাণ ছাড়া তার লাইভ, সরানোও চলে না', 'তার না ছুঁয়ে ঘটনাস্থল যেমন আছে রাখতে হয়'],
    M7Why.doctor: ['ভেতরের আঘাত বোঝা যায় না, ডাক্তার জরুরি', 'যেকোনো শকের পর ডাক্তারি পরীক্ষা করানো আবশ্যক'],
    M7Why.danger: ['অন্য বিপদ আটকাতে ঘটনাস্থলে হাত দেওয়া চলে', 'বিপদ আটকানোর জন্য ঘটনাস্থল বদলানো যায়'],
  };
  static const mythsBlock = [
    'জিনিসটা পড়ে থাকলে চলাচলের পথ আটকে থাকত',
    'ছবি তুলে রাখলে তারপর জিনিস সরানো যায়',
    'সুপারভাইজার এসে সব নিজেই গুছিয়ে নেবেন',
    'পোড়া জিনিস তো এমনিই ফেলে দেওয়ার মতো',
    'ঘটনাস্থল গুছিয়ে রাখলে সবার কাছে ভালো দেখায়',
    'হারিয়ে গেলে সেটা আমারই দায় হয়ে যেত',
  ];
  static const mythsLet = [
    'ঘটনাস্থলে যে-ই ঢুকবে, সবাইকে আটকাতে হয়',
    'ওকে আটকালে সুপারভাইজার রাগ করবেন ভেবে',
    'আমার কাজ শুধু জায়গাটা পাহারা দেওয়া, তাই',
    'ওরা নিজেরাই সবকিছু ঠিকঠাক বুঝে নেবে',
    'হাত তোলার মতো সাহস আমার তখন হয়নি, তাই',
    'কিছু হলে দায় ওদের, আমার কোনো দায় নেই',
  ];
  static List<String> mythsFor(M7Why k) => (k == M7Why.doctor || k == M7Why.danger) ? mythsLet : mythsBlock;
  static String whyQ(M7Why k) => (k == M7Why.doctor || k == M7Why.danger) ? whyLetQ : whyBlockQ;
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker, one push per site (his reach comes next). S1's is
  // the lesson's myth 2 word for word; the refusals follow the reality text.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _asks = ['ওর কথা শুনবেন?', 'ও কী বলছে — মানবেন?', 'ওকে কী বলবেন?'];
  static const coworkers = <M7Site, CoworkerScript>{
    M7Site.pole: CoworkerScript(
      line: 'এটা তো একটা ছোট শক ছিল, হাসপাতালে যাওয়ার বা রিপোর্ট করার দরকার নেই।',
      exitLine: coworkerExit,
      right: [
        'না — ভেতরের আঘাত বোঝা যায় না, ডাক্তার দেখাতেই হবে',
        'না — শকের পর ডাক্তার দেখানো আর রিপোর্ট করা আবশ্যক',
        'না — ছোট শকেও ডাক্তার দেখাতে আর রিপোর্ট করতে হয়',
      ],
      wrong: [
        'ঠিক বলেছ, উনি নিজেই বলছেন ঠিক আছেন, থাক তবে',
        'হ্যাঁ, ছোট ব্যাপার, গুছিয়ে নিলেই ঝামেলা শেষ',
        'ঠিক আছে, ডাক্তার ডেকে সবাইকে মিছিমিছি ভয় দেখানো কেন',
        'আচ্ছা, রিপোর্ট করলে শুধু ঝামেলাই বাড়বে, থাক',
        'হ্যাঁ, একটু জিরিয়ে নিলেই ও তো ঠিক হয়ে যাবে',
      ],
      asks: _asks,
    ),
    M7Site.village: CoworkerScript(
      line: 'গরু তো, মানুষ তো নয় — তারটা গুটিয়ে রাস্তা খুলে দিই।',
      exitLine: coworkerExit,
      right: [
        'না — পশুর মৃত্যুও রিপোর্ট করতে হয়, কিছু সরানো চলবে না',
        'না — তার ডেড প্রমাণ নেই, ঘটনাস্থলও যেমন আছে থাক',
        'না — তারে হাত নয়, ঘটনাস্থল যেমন আছে তেমন থাকবে',
      ],
      wrong: [
        'ঠিক বলেছ, গরুর ব্যাপারে আবার রিপোর্ট কীসের',
        'হ্যাঁ, রাস্তা খুলে দিলে সবার উপকার, গুটিয়েই ফেলো',
        'আচ্ছা, তারটা তো মাটিতেই পড়ে, ধরলে কিছু হবে না',
        'ঠিক আছে, পশুর ব্যাপারে এত ঝামেলার কিছু নেই তো',
        'হ্যাঁ, গুটিয়ে একপাশে রাখলে কেউ টেরই পাবে না',
      ],
      asks: _asks,
    ),
    M7Site.pillar: CoworkerScript(
      line: 'আগুন তো নিভেই গেছে — নতুন ফিউজ বসিয়ে দিই, রিপোর্টের ঝামেলা কেন?',
      exitLine: coworkerExit,
      right: [
        'না — আগুন লাগাও রিপোর্ট করতে হয়, ঘটনাস্থল যেমন আছে থাক',
        'না — পোড়া ফিউজ প্রমাণ, বদলালে তদন্ত ব্যাহত হয়',
        'না — আগুন লাগার পরেও রিপোর্ট করা আবশ্যক, কিছু ছোঁব না',
      ],
      wrong: [
        'ঠিক বলেছ, আগুন তো নিভেই গেছে, নতুন ফিউজ বসিয়ে দিই',
        'হ্যাঁ, রিপোর্ট না করলে কাজ অনেক তাড়াতাড়ি এগোবে',
        'আচ্ছা, নতুন ফিউজ লাগিয়ে এখনই লাইন চালু করে দিই',
        'ঠিক আছে, পুরোনো ফিউজ ফেলে দিলেই সব মিটে যায়',
        'হ্যাঁ, কেউ বুঝবেই না, চটপট ফিউজটা বদলে নিয়ে চলো',
      ],
      asks: _asks,
    ),
  };
  static List<CoworkerScript> get allCoworkers => coworkers.values.toList();

  /// The guide after he is refused.
  static const callHeld = <M7Site, String>{
    M7Site.pole: 'ঠিক! ভেতরের আঘাত বাইরে বোঝা যায় না।',
    M7Site.village: 'ঠিক! ঘটনাস্থল যেমন আছে তেমন থাকবে।',
    M7Site.pillar: 'ঠিক! আগুন লাগাও রিপোর্ট করতে হয়।',
  };

  static const vanArrives = 'সুপারভাইজারের গাড়ি এসে গেছে!';
  static const allSet = 'দারুণ! ঘটনাস্থল যেমন ছিল, তেমনই রেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — প্রমাণ যেমন আছে তেমন রাখুন, আর সেবার কাজে বাধা দেবেন না।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtEvidence = 'ঘটনাস্থলের প্রমাণ যেমন ছিল তেমন রেখেছেন';
  static const caughtDoctor = 'আহতকে ডাক্তারের কাছে যেতে দিয়েছেন';
  static const caughtDanger = 'বিপদ আটকানোর কাজে বাধা দেননি';
  static const caughtWire = 'ছেঁড়া তারে কাউকে হাত দিতে দেননি';
  static const caughtCoworker = 'কো-ওয়ার্কারকে “না” বলেছেন';

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        askPos,
        ...watch,
        whyBlockQ,
        whyLetQ,
        ...callHeld.values,
        vanArrives,
        allSet,
        quick,
        fail,
        ..._asks,
        for (final m in M7SceneGuardMistakes.all) m.textBn,
      ];
}

abstract final class M7SceneGuardMistakes {
  static const _art = 'assets/game/art/m7_scene_guard';
  static const _k = '7.7/m7_scene_guard';

  // Lesson 7.7 points (0-based): 0 which accidents must be reported, 1 whose
  // duty to report, 2 what a report holds, 3 keeping the scene as it was
  // (and the myth 2 reality: a doctor after any shock).
  static const ladder = DoMistake(
    key: '$_k/moved-ladder',
    textBn: 'মই যেমন পড়ে ছিল তেমন থাকুক — সরালে কে কীভাবে উঠেছিল, তদন্তে বোঝা যায় না।',
    art: '$_art/moved_ladder.svg',
    lessonPoint: 3,
  );
  static const glove = DoMistake(
    key: '$_k/moved-glove',
    textBn: 'পোড়া গ্লাভস প্রমাণ — সরানো চলবে না, ইন্সপেক্টর বা পুলিশ আসা পর্যন্ত থাক।',
    art: '$_art/moved_glove.svg',
    lessonPoint: 3,
  );
  static const pliers = DoMistake(
    key: '$_k/moved-pliers',
    textBn: 'প্লাস যেখানে পড়েছে সেখানেই থাক — কীসে শর্ট হলো, ওটাই বলে দেয়।',
    art: '$_art/moved_pliers.svg',
    lessonPoint: 3,
  );
  static const scorch = DoMistake(
    key: '$_k/moved-scorch',
    textBn: 'পোড়া দাগ মুছে দিলে কারণ ধরা যায় না — ঘটনাস্থল যেমন আছে তেমন রাখুন।',
    art: '$_art/moved_scorch.svg',
    lessonPoint: 3,
  );
  static const cow = DoMistake(
    key: '$_k/moved-cow',
    textBn: 'পশুর মৃত্যুও রিপোর্ট করতে হয় — গরু টেনে সরালে প্রমাণ নষ্ট হয়।',
    art: '$_art/moved_cow.svg',
    lessonPoint: 0,
  );
  static const insulator = DoMistake(
    key: '$_k/moved-insulator',
    textBn: 'ভাঙা ইনসুলেটরের টুকরো সরাবেন না — ওটাই বলে দেবে কোথায় ভাঙল।',
    art: '$_art/moved_insulator.svg',
    lessonPoint: 3,
  );
  static const rope = DoMistake(
    key: '$_k/moved-rope',
    textBn: 'গরুর দড়ি খুলে নিলে ঘটনার আগের অবস্থা বদলে যায় — যেমন ছিল, তেমন থাক।',
    art: '$_art/moved_rope.svg',
    lessonPoint: 3,
  );
  static const door = DoMistake(
    key: '$_k/moved-door',
    textBn: 'পোড়া দরজা বন্ধ করলে ভেতরের ক্ষতি আর দেখা যায় না — যেমন খোলা ছিল, তেমন থাক।',
    art: '$_art/moved_door.svg',
    lessonPoint: 3,
  );
  static const fuse = DoMistake(
    key: '$_k/moved-fuse',
    textBn: 'পোড়া ফিউজ ক্যারিয়ার বদলালে প্রমাণ চলে যায় — ইন্সপেক্টর আসার আগে নয়।',
    art: '$_art/moved_fuse.svg',
    lessonPoint: 3,
  );
  static const soot = DoMistake(
    key: '$_k/moved-soot',
    textBn: 'কালি মুছলে আগুন কোথা থেকে শুরু হলো বোঝা যায় না — যেমন আছে, তেমন রাখুন।',
    art: '$_art/moved_soot.svg',
    lessonPoint: 3,
  );
  static const tape = DoMistake(
    key: '$_k/moved-tape',
    textBn: 'পোড়া টেপ ফেলে দিলে প্রমাণ হারায় — সরানো বা বদলানো চলবে না।',
    art: '$_art/moved_tape.svg',
    lessonPoint: 3,
  );

  /// S2: the coworker's hand coils the snapped wire (not blocked, or he was
  /// listened to) — deadly (M7-3).
  static const wireCoil = DoMistake(
    key: '$_k/wire-coil',
    textBn: 'ডেড প্রমাণ ছাড়া ছেঁড়া তার লাইভ — গুটাতে গেলে শক খাবেন। ছোঁয়া বা সরানো দুটোই চলবে না।',
    art: '$_art/wire_coil.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const wireLate = DoMistake(
    key: '$_k/wire-late',
    textBn: 'দেরিতে থামালেন — তার ছোঁয়ার অনেক আগেই থামাতে হয়। ডেড প্রমাণ ছাড়া কেউ তার ধরবে না।',
    art: '$_art/wire_late.svg',
    lessonPoint: 3,
  );
  static const wireZone = DoMistake(
    key: '$_k/wire-zone',
    textBn: 'ছেঁড়া তারের কাছে যাওয়াই বিপদ — ডেড প্রমাণ ছাড়া তার লাইভ, নিজে দূরে থাকুন।',
    art: '$_art/wire_zone.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const blockDoctor = DoMistake(
    key: '$_k/block-doctor',
    textBn: 'আহতকে ডাক্তারের কাছে যেতে বাধা নয় — যেকোনো শকের পর ডাক্তার দেখানো আবশ্যক।',
    art: '$_art/block_doctor.svg',
    lessonPoint: 0,
  );
  static const blockDanger = DoMistake(
    key: '$_k/block-danger',
    textBn: 'বিপদ আটকাতে যা করা হচ্ছে, তাতে বাধা নয় — সে কাজে ঘটনাস্থল বদলানো যায়।',
    art: '$_art/block_danger.svg',
    lessonPoint: 3,
  );
  static const listenShock = DoMistake(
    key: '$_k/listen-shock',
    textBn: 'ছোট শক ভেবে চুপ থাকা ভুল — ভেতরের আঘাত বাইরে বোঝা যায় না। ডাক্তার দেখান, রিপোর্ট করুন।',
    art: '$_art/listen_shock.svg',
    lessonPoint: 0,
  );
  static const listenFuse = DoMistake(
    key: '$_k/listen-fuse',
    textBn: 'আগুন লাগাও রিপোর্ট করতে হয় — নতুন ফিউজ বসিয়ে ঘটনাস্থল বদলানো চলে না।',
    art: '$_art/listen_fuse.svg',
    lessonPoint: 0,
  );

  /// The slip for letting an evidence item be moved (one each).
  static const moved = <M7Item, DoMistake>{
    M7Item.ladder: ladder,
    M7Item.glove: glove,
    M7Item.pliers: pliers,
    M7Item.scorch: scorch,
    M7Item.cow: cow,
    M7Item.insulator: insulator,
    M7Item.rope: rope,
    M7Item.door: door,
    M7Item.fuse: fuse,
    M7Item.soot: soot,
    M7Item.tape: tape,
  };

  static DoMistake blockCare(M7Care c) => c == M7Care.doctor ? blockDoctor : blockDanger;

  static List<DoMistake> get all => [
        ...moved.values,
        wireCoil,
        wireLate,
        wireZone,
        blockDoctor,
        blockDanger,
        listenShock,
        listenFuse,
      ];
}

// ============================================================================
// The deal and the rules (pure)
// ============================================================================

/// One reach: a hand toward [item] from one side.
@immutable
class M7ReachPlan {
  const M7ReachPlan({required this.item, required this.fromLeft, required this.durMs, required this.tint, this.retry = false});
  final M7Item item;
  final bool fromLeft;
  final int durMs;
  final int tint;

  /// A care hand coming again after it was blocked.
  final bool retry;
}

@immutable
class M7SceneDeal {
  const M7SceneDeal({required this.site, required this.mirror, required this.slotOf, required this.reaches, required this.tied});
  final M7Site site;
  final bool mirror;
  final Map<M7Item, int> slotOf;

  /// The six reaches in order (the tied one is third or fourth).
  final List<M7ReachPlan> reaches;
  final M7Item tied;

  M7SceneGeo geoFor(double height, double inset) => M7SceneGeo.forScene(height, inset, site, mirror, slotOf);
}

/// The first reach is 4.5 s, the rest 3.0–4.0 s.
const m7FirstReachMs = 4500;

M7SceneDeal m7SceneDeal(math.Random rng) {
  final site = M7Site.values[rng.nextInt(M7Site.values.length)];
  final mirror = rng.nextBool();
  final List<M7Item> care = switch (site) {
    M7Site.pole => [M7Item.colleague, rng.nextBool() ? M7Item.child : M7Item.cart],
    M7Site.village => [M7Item.child, M7Item.cart],
    M7Site.pillar => ([M7Item.colleague, M7Item.ember, M7Item.child]..shuffle(rng)).take(2).toList(),
  };
  final tied = m7TiedOf[site]!;
  final items = [...m7EvidenceOf[site]!, ...care]..shuffle(rng);
  items
    ..remove(tied)
    ..insert(2 + rng.nextInt(2), tied);
  // Places: the wire lies at the band's outer end (its ground zone beyond the
  // other lanes); everything else is dealt over the other slots.
  final slots = site == M7Site.village ? [0, 1, 2, 3, 4] : [0, 1, 2, 3, 4, 5];
  slots.shuffle(rng);
  final slotOf = <M7Item, int>{};
  var k = 0;
  for (final i in items) {
    slotOf[i] = (site == M7Site.village && i == M7Item.wire) ? 5 : slots[k++];
  }
  final reaches = [
    for (final (n, i) in items.indexed)
      M7ReachPlan(item: i, fromLeft: rng.nextBool(), durMs: n == 0 ? m7FirstReachMs : 3000 + rng.nextInt(1001), tint: i == tied && m7KindOf(i) == M7Kind.evidence ? 4 : rng.nextInt(4)),
  ];
  return M7SceneDeal(site: site, mirror: mirror, slotOf: slotOf, reaches: reaches, tied: tied);
}

/// The last stretch of the wire hand's reach in which a block is "late".
const m7LateMs = 600;

enum M7Outcome { blockedRight, blockedWrong, letRight, letWrong, wireDeadly, wireLate, zone }

@immutable
class M7Event {
  const M7Event(this.kind, this.item, this.mistake);
  final M7Outcome kind;
  final M7Item item;
  final DoMistake? mistake;
}

/// The play state (pure logic; the worker's x only).
class M7SceneGuardRun {
  M7SceneGuardRun(this.deal, {this.speed = 1.0}) : reaches = [...deal.reaches] {
    geo = deal.geoFor(700, 0);
    workerX = M7SceneGeo.home;
  }

  final M7SceneDeal deal;

  /// Reach times are scaled by this (1 normally).
  final double speed;
  late final M7SceneGeo geo;
  final List<M7ReachPlan> reaches;

  int index = 0;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];
  late double workerX;

  var active = false;
  var resolved = false;
  double reachMs = 0;

  /// The care hands that came a second time.
  int retries = 0;

  bool get done => index >= reaches.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  M7ReachPlan get current => reaches[index.clamp(0, reaches.length - 1)];
  double get durMs => current.durMs * speed;
  bool get isTied => !done && current.item == deal.tied && !current.retry;

  /// The index of the tied reach (the coworker comes before it).
  int get tiedIndex => reaches.indexWhere((r) => r.item == deal.tied && !r.retry);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// The hand sets off.
  void startReach() {
    if (ended) return;
    active = true;
    resolved = false;
    reachMs = 0;
  }

  /// Slip for listening to the coworker (S1, S3).
  DoMistake listenSlip() => _slip(deal.site == M7Site.pole ? M7SceneGuardMistakes.listenShock : M7SceneGuardMistakes.listenFuse);

  /// Listening to him in S2 (coiling the wire): deadly.
  void failDeadly(DoMistake m) => deadly = m;

  void tagCoworker() => _tag(M7SceneGuardLines.caughtCoworker);

  /// The trainee is dragged to [nx] (his x on the band). A drag that crosses
  /// the wire's ground zone is deadly; one that crosses the active hand's lane
  /// blocks it.
  M7Event? moveTo(double nx) {
    if (ended) return null;
    final prev = workerX;
    final x = nx.clamp(M7SceneGeo.bandMin, M7SceneGeo.bandMax);
    workerX = x;
    final lo = math.min(prev, x);
    final hi = math.max(prev, x);
    final z = geo.zone;
    if (z != null && hi >= z.a && lo <= z.b) {
      deadly = M7SceneGuardMistakes.wireZone;
      active = false;
      return M7Event(M7Outcome.zone, M7Item.wire, deadly);
    }
    if (active && !resolved) {
      final c = geo.laneX(current.item);
      if (hi >= c - M7SceneGeo.laneHalf && lo <= c + M7SceneGeo.laneHalf) return _block();
    }
    return null;
  }

  /// The worker is back home (no zone, no lane test).
  void setHome() => workerX = M7SceneGeo.home;

  M7Event _block() {
    final r = current;
    active = false;
    resolved = true;
    if (m7KindOf(r.item) == M7Kind.care) {
      final m = _slip(M7SceneGuardMistakes.blockCare(m7CareOf(r.item)!));
      if (!r.retry) {
        retries++;
        reaches.insert(
          index + 1,
          M7ReachPlan(item: r.item, fromLeft: !r.fromLeft, durMs: 3500, tint: (r.tint + 1) % 4, retry: true),
        );
      }
      return M7Event(M7Outcome.blockedWrong, r.item, m);
    }
    if (r.item == M7Item.wire && reachMs > durMs - m7LateMs) {
      return M7Event(M7Outcome.wireLate, r.item, _slip(M7SceneGuardMistakes.wireLate));
    }
    _tag(M7SceneGuardLines.caughtEvidence);
    if (r.item == M7Item.wire) _tag(M7SceneGuardLines.caughtWire);
    return M7Event(M7Outcome.blockedRight, r.item, null);
  }

  /// Time moves on to [ms] (since this reach set off). Returns the contact's
  /// result when the hand reaches the thing.
  M7Event? tick(double ms) {
    if (!active || resolved || ended) return null;
    reachMs = ms;
    if (ms < durMs) return null;
    final r = current;
    active = false;
    resolved = true;
    if (m7KindOf(r.item) == M7Kind.care) {
      _tag(m7CareOf(r.item) == M7Care.doctor ? M7SceneGuardLines.caughtDoctor : M7SceneGuardLines.caughtDanger);
      return M7Event(M7Outcome.letRight, r.item, null);
    }
    if (r.item == M7Item.wire) {
      deadly = M7SceneGuardMistakes.wireCoil;
      return M7Event(M7Outcome.wireDeadly, r.item, deadly);
    }
    return M7Event(M7Outcome.letWrong, r.item, _slip(M7SceneGuardMistakes.moved[r.item]!));
  }

  /// The next reach.
  void advance() {
    index++;
    active = false;
    resolved = false;
    reachMs = 0;
  }
}

/// The quick bonus: a little under a clean play (~85 %, rounded to 10 s).
/// ms: take position ~4000; six reaches ~3500 each (21000) + six reasons
/// ~8200 each (49200) (the coworker's moment does not count: the clock stops
/// for him)                                                   ≈ 74000
/// 85 % ≈ 63000 → 60 s.
const m7SceneGuardQuickMs = 60000;

@immutable
class M7SceneGuardPack {
  const M7SceneGuardPack({required this.id, required this.titleBn, this.quickMs = m7SceneGuardQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7SceneGuardPack> m7SceneGuardPacks = {
  'do_7_7_a': M7SceneGuardPack(id: 'do_7_7_a', titleBn: M7SceneGuardLines.title),
};

/// Test hook: the play's state and screen points (tests only).
class M7SceneGuardProbe {
  _GuardRunPageState? _s;
  M7SceneGuardRun? get run => _s?._run;
  M7SceneDeal? get deal => _s?._run.deal;

  /// intro, position, reach, between, done.
  String get phase => _s?._phase.name ?? 'none';

  /// The trainee's body on screen (a drag starts here).
  Offset? get workerGlobal {
    final s = _s;
    final g = s?._geoNow;
    return s == null || g == null ? null : s._toGlobal(g.workerHand(s._run.workerX));
  }

  /// A band x on screen, at the trainee's height.
  Offset? bandGlobal(double x) {
    final s = _s;
    final g = s?._geoNow;
    return s == null || g == null ? null : s._toGlobal(Offset(x, g.groundY - 48));
  }

  /// Screen drag that puts the worker's x at [x].
  Offset? dragTo(double x) {
    final a = workerGlobal;
    final b = bandGlobal(x);
    return a == null || b == null ? null : b - a;
  }
}

// ============================================================================
// Page
// ============================================================================

class M7SceneGuardPage extends StatefulWidget {
  const M7SceneGuardPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M7SceneGuardPack pack;
  final bool muted;
  final int? seed;
  final M7SceneGuardProbe? probe;

  @override
  State<M7SceneGuardPage> createState() => _M7SceneGuardPageState();
}

class _M7SceneGuardPageState extends State<M7SceneGuardPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GuardRunPage(
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

class _GuardRunPage extends ConsumerStatefulWidget {
  const _GuardRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.rng,
    required this.onRetry,
    this.probe,
  });

  final LevelContext ctx;
  final M7SceneGuardPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M7SceneGuardProbe? probe;

  @override
  ConsumerState<_GuardRunPage> createState() => _GuardRunPageState();
}

enum _Phase { intro, position, reach, between, done }

class _GuardRunPageState extends ConsumerState<_GuardRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7SceneGuardRun _run;
  late final int _seed = widget.rng.nextInt(1 << 20);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _phase = _Phase.intro;
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

  // The reach clock (only while a hand moves; still otherwise).
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  double _ms = 0;
  int _lastStep = -1;
  final _frame = ValueNotifier<int>(0);
  final _workerX = ValueNotifier<double>(M7SceneGeo.home);

  /// The hand after its reach: pulling back (from [_retreatP] since [_retreatAt]).
  double? _retreatAt;
  double _retreatP = 0;
  M7Item? _takenItem;
  final Set<M7Item> _gone = {};
  var _blockedNow = false;

  // The van.
  late final AnimationController _van = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  // The trainee's walk home.
  late final AnimationController _homeWalk = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  double _walkFrom = M7SceneGeo.home;
  var _walking = false;

  var _faceLeft = false;
  final List<Timer> _timers = [];
  var _freeze = false;
  Completer<void>? _frozen;
  Offset? _flashAt;
  final _nudge = TaskNudge();
  int _nudgeN = 0;
  int _watchN = 0;
  VoidCallback? _afterCard;

  // The gesture hand and the drag.
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  M7SceneGeo? _geoNow;
  Offset? _panStart;
  double _panWorker = M7SceneGeo.home;
  var _dragging = false;
  var _moved = false;

  @override
  void initState() {
    super.initState();
    _run = M7SceneGuardRun(m7SceneDeal(widget.rng));
    widget.probe?._s = this;
    _homeWalk.addListener(_onWalk);
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _ticker.dispose();
    _van.dispose();
    _homeWalk.dispose();
    for (final t in _timers) {
      t.cancel();
    }
    _frame.dispose();
    _workerX.dispose();
    _chain++;
    if (widget.probe?._s == this) widget.probe?._s = null;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  void _later(int ms, VoidCallback f) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted && !_ended) f();
    }));
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

  /// The guide says [line], then (after a reading time) his bubble goes, so
  /// it never hides part of the band while a hand reaches.
  Future<void> _sayThenClear(String line, {GuideMood mood = GuideMood.talk}) async {
    final chain = ++_chain;
    final clock = Stopwatch()..start();
    await _say(line, mood: mood);
    final rest = MascotSpeechLibrary.readHold(line) - clock.elapsed;
    if (rest > Duration.zero) await Future<void>.delayed(rest);
    if (!mounted || chain != _chain || _ended) return;
    if (_phase == _Phase.reach) ref.read(guideDirectorProvider.notifier).softClearLine();
  }

  void _hush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  bool get _canDrag =>
      !_ended &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      !_freeze &&
      !_walking &&
      (_phase == _Phase.position || (_phase == _Phase.reach && _run.active));

  String get _task => switch (_phase) {
        _Phase.position => M7SceneGuardLines.askPos,
        _ => M7SceneGuardLines.watch[_watchN % M7SceneGuardLines.watch.length],
      };

  Offset? _toGlobal(Offset design) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(design);
  }

  // --- the steps -----------------------------------------------------------------
  void _start() {
    _clock.start();
    setState(() {
      _phase = _Phase.position;
      _wake++;
    });
    unawaited(_sayChain([M7SceneGuardLines.askPos], mood: GuideMood.think));
  }

  /// The trainee has taken his place: the first hand follows.
  void _tookPosition() {
    if (_phase != _Phase.position) return;
    setState(() {
      _phase = _Phase.between;
      _wake++;
    });
    // He walks back to the middle (clear of every lane), then the first hand.
    _later(500, _walkHome);
    _later(1600, _beginReach);
  }

  void _beginReach() {
    if (!mounted || _ended || _phase == _Phase.reach || _run.done || coworkerOpen) return;
    if (holdForCoworker()) return;
    if (_card != null || tableBusy || _freeze) return;
    setState(() {
      _phase = _Phase.reach;
      _run.startReach();
      _ms = 0;
      _lastStep = -1;
      _retreatAt = null;
      _takenItem = null;
      _blockedNow = false;
      _faceLeft = _run.current.fromLeft;
      _wake++;
    });
    _cue('sounds/intro/tick.ogg', volume: 0.4);
    unawaited(_sayThenClear(M7SceneGuardLines.watch[_watchN++ % M7SceneGuardLines.watch.length]));
    _runTicker();
  }

  void _runTicker() {
    if (_ticker.isActive) return;
    _lastTick = Duration.zero;
    unawaited(_ticker.start());
  }

  void _onTick(Duration now) {
    final dt = (now - _lastTick).inMicroseconds / 1000.0;
    _lastTick = now;
    if (_ended || (_phase != _Phase.reach && _retreatAt == null)) {
      _ticker.stop();
      return;
    }
    if (_card != null && _retreatAt == null) return;
    if (_freeze || coworkerOpen) return;
    _ms += dt.clamp(0.0, 64.0);
    final ra = _retreatAt;
    if (ra != null) {
      if (_ms - ra >= _retreatMs + 200) {
        _ticker.stop();
        _retreatAt = null;
        _frame.value++;
        return;
      }
    } else {
      final e = _run.tick(_ms);
      if (e != null) {
        _frame.value++;
        unawaited(_onEvent(e));
        return;
      }
    }
    final step = (_ms / 200).floor();
    if (!_quiet || step != _lastStep) {
      _lastStep = step;
      _frame.value++;
    }
  }

  static const _retreatMs = 700.0;

  // --- the drag -----------------------------------------------------------------
  void _panDown(DragStartDetails d) {
    final geo = _geoNow;
    _dragging = false;
    if (geo == null || !_canDrag) return;
    final r = geo.workerRect(_run.workerX).inflate(26);
    if (!r.contains(d.localPosition)) {
      _hints.missTap();
      return;
    }
    _dragging = true;
    _panStart = d.localPosition;
    _panWorker = _run.workerX;
    _moved = false;
  }

  void _panUpdate(DragUpdateDetails d) {
    final s = _panStart;
    if (!_dragging || s == null || !_canDrag) return;
    final delta = d.localPosition - s;
    final e = _run.moveTo(_panWorker + delta.dx);
    _workerX.value = _run.workerX;
    if (_phase == _Phase.position && !_moved && delta.distance >= 24) {
      _moved = true;
      _tookPosition();
    }
    if (e != null) unawaited(_onEvent(e));
  }

  void _panEnd(DragEndDetails _) {
    _dragging = false;
    _panStart = null;
  }

  // --- what a reach came to --------------------------------------------------------
  Offset _hereFor(M7Item i) => _geoNow?.itemAt(i) ?? Offset.zero;

  Future<void> _onEvent(M7Event e) async {
    switch (e.kind) {
      case M7Outcome.zone:
        _ticker.stop();
        await _deadly(e.mistake!, at: Offset(_run.workerX, (_geoNow?.groundY ?? 600) - 30));
      case M7Outcome.wireDeadly:
        _ticker.stop();
        await _deadly(e.mistake!, at: _hereFor(M7Item.wire) + const Offset(0, -14));
      case M7Outcome.blockedRight:
      case M7Outcome.blockedWrong:
      case M7Outcome.wireLate:
        _startRetreat(blocked: true, item: e.item);
        HapticFeedback.selectionClick();
        _cue('sounds/intro/confirm.ogg', volume: 0.7);
        if (e.kind == M7Outcome.blockedRight) {
          _rightDone(e.item, blocked: true);
        } else {
          await _mistake(e.mistake!, _geoNow?.itemAt(e.item) ?? Offset.zero, then: _walkThenNext);
        }
      case M7Outcome.letRight:
        _startRetreat(blocked: false, item: e.item);
        _rightDone(e.item, blocked: false);
      case M7Outcome.letWrong:
        _startRetreat(blocked: false, item: e.item);
        await _mistake(e.mistake!, _geoNow?.itemAt(e.item) ?? Offset.zero, then: _walkThenNext);
    }
  }

  /// The hand pulls back (a block) or carries the thing off (let through).
  void _startRetreat({required bool blocked, required M7Item item}) {
    _retreatAt = _ms;
    _retreatP = (_ms / _run.durMs).clamp(0.0, 1.0);
    if (!blocked) {
      _retreatP = 1;
      _takenItem = item;
      _gone.add(item);
    }
    _blockedNow = blocked;
    setState(() => _wake++);
    _runTicker();
    _frame.value++;
  }

  /// A right resolution: ◆ on the table, then its reason.
  void _rightDone(M7Item item, {required bool blocked}) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    final idx = _run.index;
    final why = m7WhyOf(item);
    putOnTable(15);
    setState(() => _phase = _Phase.between);
    _walkHomeSoon();
    unawaited(askReason(
      deal: () => dealChoices(M7SceneGuardLines.whyRight[why]!, M7SceneGuardLines.mythsFor(why), widget.rng),
      question: M7SceneGuardLines.whyQ(why),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _walkHomeSoon() => _later(_quiet ? 200 : 650, _walkHome);

  /// He walks back to his place after every reach.
  void _walkHome() {
    if (!mounted || _ended) return;
    if ((_run.workerX - M7SceneGeo.home).abs() < 1) return;
    if (_quiet) {
      _run.setHome();
      _workerX.value = M7SceneGeo.home;
      _frame.value++;
      return;
    }
    _walkFrom = _run.workerX;
    setState(() => _walking = true);
    unawaited(_homeWalk.forward(from: 0));
  }

  void _onWalk() {
    if (!_walking) return;
    final t = Curves.easeInOut.transform(_homeWalk.value);
    final x = _walkFrom + (M7SceneGeo.home - _walkFrom) * t;
    _run.workerX = x;
    _workerX.value = x;
    if (_homeWalk.isCompleted && mounted) {
      _run.setHome();
      _workerX.value = M7SceneGeo.home;
      setState(() => _walking = false);
    }
  }

  void _walkThenNext() {
    _walkHomeSoon();
    _later(_quiet ? 500 : 1500, _next);
  }

  void _next() {
    if (_ended) return;
    setState(() {
      _run.advance();
      _phase = _Phase.between;
      _takenItem = null;
      _retreatAt = null;
      _blockedNow = false;
      _wake++;
    });
    _ticker.stop();
    _homeWalk.stop();
    _frame.value++;
    _run.setHome();
    _workerX.value = M7SceneGeo.home;
    _walking = false;
    if (_run.done) {
      unawaited(_arrive());
      return;
    }
    if (_run.isTied && !coworkerDone) {
      // He comes between the reaches; the tied reach waits for him (if he has
      // not come by now, the reach start pulls him in).
      scheduleCoworker();
      _later(2600, _beginReach);
    } else {
      _later(900, _beginReach);
    }
  }

  /// The supervisor's van pulls in, then the result.
  Future<void> _arrive() async {
    if (_quiet) {
      _van.value = 1;
    } else {
      _cue('sounds/van_arrive.ogg', volume: 0.7);
      unawaited(_van.forward(from: 0));
    }
    unawaited(_sayChain([M7SceneGuardLines.vanArrives], mood: GuideMood.glad));
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 600 : 2300));
    if (!mounted || _ended) return;
    unawaited(_finish());
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
  CoworkerScript get coworkerScript => M7SceneGuardLines.coworkers[_run.deal.site]!;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !_run.isTied || _phase == _Phase.reach) return null;
    if (_card != null || tableBusy || _freeze) return false;
    return true;
  }

  @override
  void coworkerClearGuideBubble() {
    super.coworkerClearGuideBubble();
    // The level's clock stops for him.
    _clock.stop();
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      if (_run.deal.site == M7Site.village) {
        // Listened to him: his hand coils the live wire.
        _run.failDeadly(M7SceneGuardMistakes.wireCoil);
        await _deadly(M7SceneGuardMistakes.wireCoil, at: _hereFor(M7Item.wire) + const Offset(0, -14));
        return;
      }
      _clock.start();
      final m = _run.listenSlip();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _mistake(m, origin, then: () => _later(900, _beginReach));
      return;
    }
    _clock.start();
    _run.tagCoworker();
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7SceneGuardLines.callHeld[_run.deal.site]!], mood: GuideMood.glad));
    _later(1200, _beginReach);
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_phase == _Phase.intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7SceneGuardLines.tapWhy[_nudgeN++ % M7SceneGuardLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(!coworkerOpen && !reasonOpen && _phase == _Phase.reach ? _sayThenClear(line) : _sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _mistake(DoMistake m, Offset origin, {required VoidCallback then}) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    _afterCard = then;
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
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('sceneguard/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move: the scene freezes grey and the flash comes in colour;
  /// then near-miss or death.
  Future<void> _deadly(DoMistake m, {Offset? at}) async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _flashAt = at ?? _hereFor(M7Item.wire);
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
    final speak = await SpokenOnce.first('sceneguard/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M7SceneGuardLines.deadlyWord : M7SceneGuardLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final f = _afterCard;
        _afterCard = null;
        setState(() {
          _card = null;
          _wake++;
        });
        if (f != null) {
          f();
        } else {
          _walkThenNext();
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

  /// Quick: under the pack's time.
  bool get _quick => _clock.elapsedMilliseconds < widget.pack.quickMs;

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _phase = _Phase.done;
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
      if (mark == 100 && _quick) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _quick);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M7SceneGuardLines.fail : (_quickBonus ? M7SceneGuardLines.quick : M7SceneGuardLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_walking) return LinemanMode.walk;
    if (_blockedNow && _retreatAt != null) return LinemanMode.point;
    return LinemanMode.idle;
  }

  /// Everything that moves in the band, as drawn now.
  M7ActionFrame _frameNow() {
    final geo = _geoNow;
    if (geo == null) return const M7ActionFrame();
    final items = <M7ItemView>[];
    final ra = _retreatAt;
    M7HandView? hand;
    Offset? palm;
    if (_phase == _Phase.reach || ra != null) {
      final r = _run.current;
      final from = geo.handFrom(r.fromLeft, r.item);
      final to = geo.handTo(r.item);
      if (ra == null) {
        hand = M7HandView(from: from, to: to, p: (_ms / _run.durMs).clamp(0.0, 1.0), tint: r.tint);
      } else {
        final k = ((_ms - ra) / _retreatMs).clamp(0.0, 1.0);
        final p = _retreatP * (1 - k);
        if (k < 1) hand = M7HandView(from: from, to: to, p: p, tint: r.tint);
        if (_blockedNow && k < 1) palm = Offset(_run.workerX, geo.groundY - 112);
      }
    }
    for (final i in _run.deal.slotOf.keys) {
      final at = geo.itemAt(i);
      if (_gone.contains(i)) {
        if (i == _takenItem && ra != null && hand != null) {
          final k = ((_ms - ra) / _retreatMs).clamp(0.0, 1.0);
          items.add(M7ItemView(item: i, at: hand.tip + const Offset(0, 14), alpha: 1 - k, scale: 0.8));
        }
        continue;
      }
      items.add(M7ItemView(item: i, at: at));
    }
    return M7ActionFrame(items: items, hand: hand, palmAt: palm, van: _van.value);
  }

  /// The gesture hand (how to touch, never what): a short drag from the
  /// trainee while he waits to take his place.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null || _phase != _Phase.position) return null;
    return HintSpec.drag(geo.workerHand(_run.workerX), toward: const Offset(0, -1), travel: 60, space: HintSpace.scene);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = _run.deal.geoFor(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final flash = _flashAt;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('place'),
                child: RepaintBoundary(child: CustomPaint(painter: M7SceneBackPainter(geo: geo, seed: _seed))),
              ),
              Positioned.fill(
                key: const ValueKey('things'),
                child: RepaintBoundary(
                  child: CustomPaint(painter: M7ActionPainter(geo: geo, frame: _frameNow, repaint: Listenable.merge([_frame, _van]))),
                ),
              ),
              ValueListenableBuilder<double>(
                key: const ValueKey('worker'),
                valueListenable: _workerX,
                builder: (_, x, child) => Positioned.fromRect(rect: geo.workerRect(x), child: child!),
                child: Transform.flip(
                  flipX: _faceLeft,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7SceneGuardLines.sceneLabel,
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (_) {
              if (_phase == _Phase.position && _canDrag) _hints.missTap();
            },
            onPanStart: _panDown,
            onPanUpdate: _panUpdate,
            onPanEnd: _panEnd,
          ),
        ),
      ),
      if (_freeze && flash != null)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M7FlashPainter(at: flash, v: v)),
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
    final playing = _phase != _Phase.intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
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
              labels: M7SceneGuardLines.steps,
              done: {for (var i = 0; i < math.min(_run.index, 6); i++) i},
              current: _run.done ? null : math.min(_run.index, 5),
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: playing && _phase == _Phase.position && _canDrag && !deckUp,
            hintKey: _phase.name,
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
                        ? reasonDeck(quiet: quiet, key: ValueKey('why-deck-${_run.index}'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + 236,
                  onLeft: coworkerOnScreen ? coworkerFromRight : _run.deal.mirror,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
              if (_phase == _Phase.intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M7SceneGuardLines.intro,
                  alarm: 'sounds/learn/siren.ogg',
                  muted: _muted,
                  onDone: _start,
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
