import 'dart:async';
import 'dart:math' as math;

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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm3_crossarm_pick_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 3.3, কাজ 1: "সঠিক ক্রস-আর্ম, সঠিক ক্ল্যাম্প". In the line store
// before a new pole is dressed: the docket on the wall says the line (LT in
// vertical or horizontal formation, or HT) and the pole (PCC, rail or
// H-beam). For each of its three parts — the cross-arm, the clamp, the nuts
// and bolts — the trainee takes one off the rack (the type shows to the eye:
// a V, an I or a channel cross-arm; a wrap-around band or a bolted clamp;
// with or without the spring washer), runs a hand along it (rust where the
// galvanizing is gone, a bend in the arm, show only where the hand has been
// — the lesson's daily check), then loads it on the trolley or puts it back
// (a part whose fault he found goes into the scrap drum). On one part of the
// three no good one lies on the rack: he must send for a replacement. Once a
// play the careless coworker (level 1's rival) peeps in: "যেকোনো ক্ল্যাম্পেই
// হবে — শক্ত করে টাইট দিলেই চলবে" (the lesson's myth and its torque tip),
// or the lesson's other myth "হালকা মরিচা — ওতে কিছু হয় না". Built on the
// shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full scene, corner
// guide, ◆ on the table → "কেন …?" → the next part by itself.
// He cannot be skipped by playing fast: the take and the replace buttons wait
// for him (holdForCoworker), and so does putting back the last part he could
// push (it would go to the drum); he comes only while something he could push
// is still on the rack. Listening to him loads his part — a slip. A gesture
// hint shows how to touch in every waiting state (a sweep over the rack, a
// short nudge along the part in hand, a sweep over put back / load).
//
// Deadly: none — at the store a wrong or rusty part is a slip (it would fail
// later on the pole; the lesson's "never stand on a rusty cross-arm" belongs
// to the climbing levels). Every fault is a slip; 3 slips fail.
//
// Voice: the guide's lines on device TTS; the coworker's two pushes on device
// TTS too until they are recorded in his voice (his exit line is recorded).
// Art: the store and the parts are drawn in code (m3_crossarm_pick_world.dart
// and the painter below), so types and faults vary each play; the mistake
// cards use assets/game/art/m3_crossarm_pick/.

// ============================================================================
// Content
// ============================================================================

/// The three parts the docket lists.
enum M3CrossarmPickSlot { crossarm, clamp, nuts }

/// What lies on the rack (each belongs to one slot).
enum M3CrossarmPickShape { vArm, iArm, channel, wrapClamp, boltClamp, nutsSpring, nutsBare }

enum M3CrossarmPickFlaw { none, rust, bend }

/// The line on the docket (lesson 3.3 point 1: LT vertical → V, LT
/// horizontal → I, HT → channel).
enum M3CrossarmPickLine { ltVertical, ltHorizontal, ht }

/// The pole on the docket (point 2: PCC → wrap-around, rail / H-beam →
/// bolted clamp).
enum M3CrossarmPickPole { pcc, rail, hBeam }

extension M3CrossarmPickSlotText on M3CrossarmPickSlot {
  String get nameBn => switch (this) {
        M3CrossarmPickSlot.crossarm => 'ক্রস-আর্ম',
        M3CrossarmPickSlot.clamp => 'ক্ল্যাম্প',
        M3CrossarmPickSlot.nuts => 'নাট-বল্টু',
      };
}

extension M3CrossarmPickShapeText on M3CrossarmPickShape {
  M3CrossarmPickSlot get slot => switch (this) {
        M3CrossarmPickShape.vArm || M3CrossarmPickShape.iArm || M3CrossarmPickShape.channel => M3CrossarmPickSlot.crossarm,
        M3CrossarmPickShape.wrapClamp || M3CrossarmPickShape.boltClamp => M3CrossarmPickSlot.clamp,
        _ => M3CrossarmPickSlot.nuts,
      };

  String get nameBn => switch (this) {
        M3CrossarmPickShape.vArm => 'V ক্রস-আর্ম',
        M3CrossarmPickShape.iArm => 'I ক্রস-আর্ম',
        M3CrossarmPickShape.channel => 'চ্যানেল ক্রস-আর্ম',
        M3CrossarmPickShape.wrapClamp => 'র‍্যাপ-অ্যারাউন্ড ক্ল্যাম্প',
        M3CrossarmPickShape.boltClamp => 'নাট-বল্টুর ক্ল্যাম্প',
        M3CrossarmPickShape.nutsSpring => 'নাট-বল্টু, স্প্রিং ওয়াশার',
        M3CrossarmPickShape.nutsBare => 'নাট-বল্টু, ওয়াশার ছাড়া',
      };
}

extension M3CrossarmPickLineText on M3CrossarmPickLine {
  String get nameBn => switch (this) {
        M3CrossarmPickLine.ltVertical || M3CrossarmPickLine.ltHorizontal => 'এলটি লাইন',
        M3CrossarmPickLine.ht => 'এইচটি লাইন',
      };

  /// The formation (LT only).
  String? get formationBn => switch (this) {
        M3CrossarmPickLine.ltVertical => 'ভার্টিকাল ফর্মেশন',
        M3CrossarmPickLine.ltHorizontal => 'হরাইজন্টাল ফর্মেশন',
        M3CrossarmPickLine.ht => null,
      };

  M3CrossarmPickShape get arm => switch (this) {
        M3CrossarmPickLine.ltVertical => M3CrossarmPickShape.vArm,
        M3CrossarmPickLine.ltHorizontal => M3CrossarmPickShape.iArm,
        M3CrossarmPickLine.ht => M3CrossarmPickShape.channel,
      };
}

extension M3CrossarmPickPoleText on M3CrossarmPickPole {
  String get nameBn => switch (this) {
        M3CrossarmPickPole.pcc => 'PCC পোল',
        M3CrossarmPickPole.rail => 'রেল পোল',
        M3CrossarmPickPole.hBeam => 'এইচ-বিম পোল',
      };

  M3CrossarmPickShape get clamp => this == M3CrossarmPickPole.pcc ? M3CrossarmPickShape.wrapClamp : M3CrossarmPickShape.boltClamp;
}

const m3CrossarmPickArms = [M3CrossarmPickShape.vArm, M3CrossarmPickShape.iArm, M3CrossarmPickShape.channel];
const m3CrossarmPickClamps = [M3CrossarmPickShape.wrapClamp, M3CrossarmPickShape.boltClamp];

@immutable
class M3CrossarmPickItem {
  const M3CrossarmPickItem({required this.id, required this.shape, this.flaw = M3CrossarmPickFlaw.none});
  final String id;
  final M3CrossarmPickShape shape;
  final M3CrossarmPickFlaw flaw;
  bool get sound => flaw == M3CrossarmPickFlaw.none;
}

@immutable
class M3CrossarmPickRound {
  const M3CrossarmPickRound({required this.slot, required this.want, required this.items});
  final M3CrossarmPickSlot slot;

  /// The type the docket calls for.
  final M3CrossarmPickShape want;
  final List<M3CrossarmPickItem> items;

  /// No good part of the right type on the rack: send for a replacement.
  bool get noneFits => !items.any((t) => t.shape == want && t.sound);
}

@immutable
class M3CrossarmPickDocket {
  const M3CrossarmPickDocket({required this.line, required this.pole, required this.feederBn, required this.timeBn});
  final M3CrossarmPickLine line;
  final M3CrossarmPickPole pole;
  final String feederBn;
  final String timeBn;

  M3CrossarmPickShape want(M3CrossarmPickSlot s) => switch (s) {
        M3CrossarmPickSlot.crossarm => line.arm,
        M3CrossarmPickSlot.clamp => pole.clamp,
        M3CrossarmPickSlot.nuts => M3CrossarmPickShape.nutsSpring,
      };
}

/// What the careless coworker pushes.
enum M3CrossarmPickPush { anyClamp, rust }

@immutable
class M3CrossarmPickDeal {
  const M3CrossarmPickDeal({required this.docket, required this.rounds, required this.callRound, required this.preferRust});
  final M3CrossarmPickDocket docket;
  final List<M3CrossarmPickRound> rounds;

  /// The part on which he peeps in (or a later one, if nothing he could
  /// push is still on the rack).
  final int callRound;
  final bool preferRust;
}

abstract final class M3CrossarmPickLines {
  static const title = 'সঠিক ক্রস-আর্ম, সঠিক ক্ল্যাম্প';
  static const intro = 'নতুন পোলে ক্রস-আর্ম বসবে! ডকেট মিলিয়ে হার্ডওয়্যার বাছুন।';
  static String ask(M3CrossarmPickSlot s) => '${s.nameBn} — র‍্যাকের কোনটা নেবেন?';
  static const inspectAsk = 'হাত বুলিয়ে মরিচা আর বাঁক দেখুন। নেবেন?';
  static final tasks = [for (final s in M3CrossarmPickSlot.values) ask(s), inspectAsk];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const docket = 'ডকেট';
  static const partsWord = 'মাল:';
  static String shutdown(M3CrossarmPickDocket d) => 'শাটডাউন ${d.timeBn}';
  static const partLabel = 'মাল';
  static const handLabel = 'হাতে নেওয়া মাল';
  static const take = 'ট্রলিতে তুলুন';
  static const putBack = 'ফেরত রাখুন';
  static const hold = 'ঠিকঠাক একটাও নেই — বদলে আনি';
  static const rejected = 'বাতিল';

  // The reasons (lesson 3.3). Every card set stays within 1.3× in length.
  static const packAsk = 'কেন এটা ট্রলিতে তুললেন?';
  static const holdAsk = 'কেন বদলে আনবেন?';
  static List<String> packRight(M3CrossarmPickShape s) => switch (s) {
        M3CrossarmPickShape.vArm => const ['এলটি ভার্টিকাল ফর্মেশন, তাই V ক্রস-আর্ম', 'ফর্মেশন ভার্টিকাল — V, মরিচা-বাঁক নেই'],
        M3CrossarmPickShape.iArm => const ['এলটি হরাইজন্টাল ফর্মেশন, তাই I ক্রস-আর্ম', 'ফর্মেশন হরাইজন্টাল — I, মরিচা-বাঁক নেই'],
        M3CrossarmPickShape.channel => const ['এইচটি লাইন, তাই চ্যানেল ক্রস-আর্ম নিলাম', 'এইচটি-তে চ্যানেল — মরিচা বা বাঁক নেই'],
        M3CrossarmPickShape.wrapClamp => const ['PCC পোল গোল, তাই র‍্যাপ-অ্যারাউন্ড নিলাম', 'PCC পোলে র‍্যাপ-অ্যারাউন্ড, মরিচাও নেই'],
        M3CrossarmPickShape.boltClamp => const ['রেল বা এইচ-বিম পোলে বোল্টের ক্ল্যাম্প', 'এই পোলে নাট-বল্টুর ক্ল্যাম্প, মরিচা নেই'],
        _ => const ['স্প্রিং ওয়াশার আছে, কম্পনে আলগা হবে না', 'গ্যালভানাইজড, মরিচা নেই, ওয়াশারও আছে'],
      };
  static const packWrong = [
    'দেখতে মজবুত লাগল, খুঁটিয়ে দেখার সময় নেই',
    'যেকোনো ক্ল্যাম্প যেকোনো পোলে চলে',
    'হালকা মরিচা তো, ওতে কিছুই হয় না',
    'শক্ত করে টাইট দিলে — সবকিছুই চলে যায়',
    'চোখে তো মরিচা নেই, হাত বোলানোর দরকার নেই',
    'ভারী জিনিস — তাই ভালো হবেই নিশ্চয়ই',
  ];

  static const holdRight = [
    'ডকেটের সাথে মেলে এমন ভালোটা নেই',
    'মেলে এমন সবগুলোতেই খুঁত, বদলে আনি',
  ];
  static const holdWrong = [
    'সময় নেই, তাই বদলে আনতে পাঠালাম',
    'ভারী লাগছিল, তাই এটা নিলাম না',
    'স্টোরকিপার বকবে, তাই কিছু নিইনি',
    'পুরোনো পোলের ভালোটা খুলে লাগাব',
    'এটা ছাড়াও কাজটা ঠিক চলে যাবে',
  ];

  /// The careless coworker. His exit line is already recorded in his voice;
  /// the two pushes go to device TTS until they are recorded.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerClamp = CoworkerScript(
    line: 'আরে, যেকোনো ক্ল্যাম্পেই হবে — শক্ত করে টাইট দিলেই চলবে!',
    exitLine: coworkerExit,
    right: ['পোল মিলিয়ে নেব, যেকোনোটা না', 'ভুল ক্ল্যাম্প টাইটেও পিছলে যাবে', 'বেশি টাইটে বল্টু ছিঁড়বে — চলবে না'],
    wrong: [
      'শক্ত টাইট দিলে — সব কিছুই চলে যায়',
      'যেটা হাতের কাছে আছে সেটাই নেব',
      'জোরে টাইট দিলে আর তো পিছলাবে না',
      'ক্ল্যাম্প তো ক্ল্যাম্পই — এটাই নেব',
      'সবাই তো যেটা পায় সেটাই লাগায়',
    ],
    asks: ['ও বলছে যেকোনো ক্ল্যাম্পেই হবে। আপনি কী করবেন?', 'যেকোনোটা নেবেন, না পোল মিলিয়ে?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerRust = CoworkerScript(
    line: 'হালকা মরিচা — ওতে কিছু হয় না, তুলে নাও!',
    exitLine: coworkerExit,
    right: ['হালকা মরিচাও বাতিল, এটা নেব না', 'মরিচা ভেতরে শক্তি খায় — বাদ দেব', 'গ্যালভানাইজিং নষ্ট, বদলে আনব'],
    wrong: [
      'বাইরের মরিচা — ওতে কিছু হয় না',
      'একটু মরিচা থাকলে কী আর হবে',
      'রং করে দিলেই তো ঠিক চলে যাবে',
      'নতুন খুঁজতে দেরি — এটাই নেব',
      'সবাই তো মরিচা দেখেও লাগায়',
    ],
    asks: ['ও বলছে মরিচায় কিছু হয় না। আপনি কী করবেন?', 'মরিচা ধরাটা নেবেন, না বাতিল?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(M3CrossarmPickPush p) => p == M3CrossarmPickPush.anyClamp ? coworkerClamp : coworkerRust;

  static const callHeld = 'ঠিক! ঠিক ধরন আর ভালো অবস্থা — দুটোই চাই।';
  static const asideFlaw = 'ঠিক — খারাপটা বাতিল।';
  static const holdDone = 'ঠিক! খারাপটা নয় — স্টোর থেকে ভালোটা আসবে।';
  static const allSet = 'হার্ডওয়্যার তৈরি! ধরন আর অবস্থা — দুটোই মিলিয়েছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ডকেট মিলিয়ে, হাত বুলিয়ে দেখুন।';
  static const caughtArm = 'ডকেট মিলিয়ে ক্রস-আর্ম';
  static const caughtClamp = 'পোল মিলিয়ে ক্ল্যাম্প';
  static const caughtNuts = 'স্প্রিং ওয়াশারসহ নাট-বল্টু';
  static const caughtFlaw = 'মরিচা বা বাঁক ধরে বাতিল';
  static const caughtHold = 'ভালো না পেয়ে বদলে আনা';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static String caughtFor(M3CrossarmPickSlot s) => switch (s) {
        M3CrossarmPickSlot.crossarm => caughtArm,
        M3CrossarmPickSlot.clamp => caughtClamp,
        M3CrossarmPickSlot.nuts => caughtNuts,
      };
  static const feeders = ['রামপুর ফিডার', 'হাটখোলা ফিডার', 'নদীপাড় ফিডার', 'স্টেশন রোড ফিডার', 'কলেজপাড়া ফিডার'];
  static const times = ['10:00–14:00', '09:30–13:00', '11:00–15:30', '08:00–12:00'];
}

abstract final class M3CrossarmPickMistakes {
  static const _arm = 'assets/game/art/m3_crossarm_pick/arm_match.svg';
  static const _clamp = 'assets/game/art/m3_crossarm_pick/clamp_match.svg';
  static const _rust = 'assets/game/art/m3_crossarm_pick/rust_bend.svg';
  static const _washer = 'assets/game/art/m3_crossarm_pick/spring_washer.svg';

  /// Every card this level can book, for the mistakes book (`knownMistakes`).
  static List<DoMistake> get all => [
        wrongArm,
        wrongClamp,
        noWasher,
        for (final s in M3CrossarmPickSlot.values) rust(s),
        bend,
        heldWhenRight,
      ];

  static const wrongArm = DoMistake(
    key: '3.3/crossarm_pick/wrong-arm',
    textBn: 'ভুল ক্রস-আর্ম — এলটি লাইনে ভার্টিকাল ফর্মেশনে V, হরাইজন্টাল ফর্মেশনে I, আর এইচটি লাইনে চ্যানেল ক্রস-আর্ম। ডকেট দেখে বাছুন।',
    art: _arm,
    lessonPoint: 0,
  );
  static const wrongClamp = DoMistake(
    key: '3.3/crossarm_pick/wrong-clamp',
    textBn: 'যেকোনো ক্ল্যাম্প যেকোনো পোলে চলে না — PCC পোলে র‍্যাপ-অ্যারাউন্ড, রেল বা এইচ-বিম পোলে নাট-বল্টুর ক্ল্যাম্প। ভুল ক্ল্যাম্প গ্রিপ দেবে না, পিছলে যাবে।',
    art: _clamp,
    lessonPoint: 1,
  );
  static const noWasher = DoMistake(
    key: '3.3/crossarm_pick/no-spring-washer',
    textBn: 'স্প্রিং ওয়াশার নেই — কম্পনে নাট আলগা হয়ে যায়। নাট-বল্টুর সাথে স্প্রিং ওয়াশার নিন।',
    art: _washer,
    lessonPoint: 1,
  );
  static DoMistake rust(M3CrossarmPickSlot s) => switch (s) {
        M3CrossarmPickSlot.crossarm => const DoMistake(
            key: '3.3/crossarm_pick/rust/crossarm',
            textBn: 'ক্রস-আর্মে মরিচা — গ্যালভানাইজিং নষ্ট হলে স্টিলের শক্তি কমে যায়। হালকা মরিচাও অবহেলা নয়, বাতিল করুন।',
            art: _rust,
            lessonPoint: 3,
          ),
        M3CrossarmPickSlot.clamp => const DoMistake(
            key: '3.3/crossarm_pick/rust/clamp',
            textBn: 'ক্ল্যাম্পে মরিচা — মরিচা ধরা হার্ডওয়্যার পুরো স্ট্রাকচারকে দুর্বল করে দেয়। বাতিল করুন।',
            art: _rust,
            lessonPoint: 1,
          ),
        M3CrossarmPickSlot.nuts => const DoMistake(
            key: '3.3/crossarm_pick/rust/nuts',
            textBn: 'নাট-বল্টুতে মরিচা — একটা মরিচা ধরা বা ঢিলা নাট-বল্টুও পুরো সিস্টেম দুর্বল করে। গ্যালভানাইজড, পরিষ্কার নাট-বল্টু নিন।',
            art: _washer,
            lessonPoint: 1,
          ),
      };
  static const bend = DoMistake(
    key: '3.3/crossarm_pick/bent-arm',
    textBn: 'ক্রস-আর্ম বাঁকা — বাঁকা ক্রস-আর্ম ফেজ ক্লিয়ারেন্স কমিয়ে দেয়। বাঁকা বা মোচড়ানো ক্রস-আর্ম বাতিল।',
    art: _rust,
    lessonPoint: 3,
  );
  static const heldWhenRight = DoMistake(
    key: '3.3/crossarm_pick/held-when-right',
    textBn: 'ঠিক মালটা র‍্যাকেই ছিল — ডকেটের সাথে ধরন মিলিয়ে, হাত বুলিয়ে ভালো করে দেখুন।',
    art: _arm,
    lessonPoint: 0,
  );

  /// The card for loading [t] in the round that wants [want] (null: right).
  static DoMistake? forPack(M3CrossarmPickItem t, M3CrossarmPickShape want) {
    if (t.shape != want) {
      return switch (t.shape.slot) {
        M3CrossarmPickSlot.crossarm => wrongArm,
        M3CrossarmPickSlot.clamp => wrongClamp,
        M3CrossarmPickSlot.nuts => noWasher,
      };
    }
    return switch (t.flaw) {
      M3CrossarmPickFlaw.none => null,
      M3CrossarmPickFlaw.rust => rust(t.shape.slot),
      M3CrossarmPickFlaw.bend => bend,
    };
  }
}

/// A fresh store each play: the docket, the order of the first two parts,
/// which part has no good one, the faults, the rack order and the coworker's
/// moment vary.
M3CrossarmPickDeal m3CrossarmPickDeal(math.Random rng) {
  var n = 0;
  M3CrossarmPickItem item(M3CrossarmPickShape s, [M3CrossarmPickFlaw f = M3CrossarmPickFlaw.none]) =>
      M3CrossarmPickItem(id: 'part${n++}', shape: s, flaw: f);
  final docket = M3CrossarmPickDocket(
    line: M3CrossarmPickLine.values[rng.nextInt(M3CrossarmPickLine.values.length)],
    pole: M3CrossarmPickPole.values[rng.nextInt(M3CrossarmPickPole.values.length)],
    feederBn: M3CrossarmPickLines.feeders[rng.nextInt(M3CrossarmPickLines.feeders.length)],
    timeBn: M3CrossarmPickLines.times[rng.nextInt(M3CrossarmPickLines.times.length)],
  );
  final hold = rng.nextBool() ? M3CrossarmPickSlot.crossarm : M3CrossarmPickSlot.clamp;
  final slots = [M3CrossarmPickSlot.crossarm, M3CrossarmPickSlot.clamp]..shuffle(rng);
  slots.add(M3CrossarmPickSlot.nuts);
  final rounds = <M3CrossarmPickRound>[];
  for (final s in slots) {
    final want = docket.want(s);
    final List<M3CrossarmPickItem> items;
    switch (s) {
      case M3CrossarmPickSlot.crossarm:
        final others = [for (final a in m3CrossarmPickArms) if (a != want) a]..shuffle(rng);
        if (s == hold) {
          items = [item(want, M3CrossarmPickFlaw.rust), item(want, M3CrossarmPickFlaw.bend), item(others.first)];
        } else {
          items = [
            item(want),
            item(want, rng.nextBool() ? M3CrossarmPickFlaw.rust : M3CrossarmPickFlaw.bend),
            item(others.first),
            if (rng.nextBool()) item(others.last),
          ];
        }
      case M3CrossarmPickSlot.clamp:
        final other = m3CrossarmPickClamps.firstWhere((c) => c != want);
        items = s == hold
            ? [item(want, M3CrossarmPickFlaw.rust), item(want, M3CrossarmPickFlaw.rust), item(other)]
            : [item(want), item(want, M3CrossarmPickFlaw.rust), item(other), if (rng.nextBool()) item(other, M3CrossarmPickFlaw.rust)];
      case M3CrossarmPickSlot.nuts:
        items = [item(want), item(want, M3CrossarmPickFlaw.rust), item(M3CrossarmPickShape.nutsBare)];
    }
    items.shuffle(rng);
    rounds.add(M3CrossarmPickRound(slot: s, want: want, items: items));
  }
  return M3CrossarmPickDeal(docket: docket, rounds: rounds, callRound: rng.nextInt(2), preferRust: rng.nextBool());
}

/// What the careless coworker can push on round [r] now — only a part still
/// on the rack: a wrong-type clamp ("যেকোনো ক্ল্যাম্পেই হবে") on the clamp
/// round, or a rusty part ("হালকা মরিচা"). The dealt push first, else the
/// other; null when neither is there.
M3CrossarmPickPush? m3CrossarmPickPushFor(M3CrossarmPickRound r, Set<String> rejected, {required bool preferRust}) {
  final clamp = r.slot == M3CrossarmPickSlot.clamp && r.items.any((t) => t.shape != r.want && !rejected.contains(t.id));
  final rust = r.items.any((t) => t.flaw == M3CrossarmPickFlaw.rust && !rejected.contains(t.id));
  if (preferRust && rust) return M3CrossarmPickPush.rust;
  if (clamp) return M3CrossarmPickPush.anyClamp;
  return rust ? M3CrossarmPickPush.rust : null;
}

/// The part he pushes on round [r].
M3CrossarmPickItem? m3CrossarmPickPushed(M3CrossarmPickRound r, M3CrossarmPickPush p, Set<String> rejected) {
  for (final t in r.items) {
    if (rejected.contains(t.id)) continue;
    if (p == M3CrossarmPickPush.anyClamp ? t.shape != r.want : t.flaw == M3CrossarmPickFlaw.rust) return t;
  }
  return null;
}

enum M3CrossarmPickVerdict { right, slip }

@immutable
class M3CrossarmPickOutcome {
  const M3CrossarmPickOutcome(this.verdict, {this.mistake});
  final M3CrossarmPickVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class M3CrossarmPickRun {
  M3CrossarmPickRun(this.deal);
  final M3CrossarmPickDeal deal;
  int round = 0;
  int slips = 0;

  /// This part is decided (loaded, or sent for a replacement): the reason
  /// comes, then [next].
  bool shown = false;

  /// Parts set aside on this round (in the scrap drum).
  final Set<String> rejected = {};

  /// Parts on this round whose fault the player has seen (by hand, or on
  /// the card after loading it).
  final Set<String> spotted = {};

  /// What is on the trolley: well (round) → part; a round sent for a
  /// replacement stays empty.
  final Map<int, M3CrossarmPickItem> packed = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done;
  M3CrossarmPickRound get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Loads [t] onto the trolley.
  M3CrossarmPickOutcome pack(M3CrossarmPickItem t) {
    if (ended || shown || rejected.contains(t.id)) return const M3CrossarmPickOutcome(M3CrossarmPickVerdict.slip);
    final m = M3CrossarmPickMistakes.forPack(t, current.want);
    if (m != null) {
      slips++;
      // A faulty part (now seen) goes to the drum; a wrong type back on the rack.
      if (t.shape == current.want) {
        rejected.add(t.id);
        spotted.add(t.id);
      }
      return M3CrossarmPickOutcome(M3CrossarmPickVerdict.slip, mistake: m);
    }
    _tag(M3CrossarmPickLines.caughtFor(current.slot));
    packed[round] = t;
    shown = true;
    return const M3CrossarmPickOutcome(M3CrossarmPickVerdict.right);
  }

  /// The player's hand found [t]'s fault in the close look.
  void spot(M3CrossarmPickItem t) {
    if (!t.sound) spotted.add(t.id);
  }

  /// Puts [t] back: a part whose fault the player found goes into the drum
  /// (true); anything else goes back on the rack (false) — putting back
  /// never tells which is faulty.
  bool putBack(M3CrossarmPickItem t) {
    if (ended || shown || rejected.contains(t.id)) return false;
    if (!spotted.contains(t.id)) return false;
    rejected.add(t.id);
    _tag(M3CrossarmPickLines.caughtFlaw);
    return true;
  }

  /// "ঠিকঠাক একটাও নেই — বদলে আনি".
  M3CrossarmPickOutcome holdJob() {
    if (ended || shown) return const M3CrossarmPickOutcome(M3CrossarmPickVerdict.slip);
    if (!current.noneFits) {
      slips++;
      return const M3CrossarmPickOutcome(M3CrossarmPickVerdict.slip, mistake: M3CrossarmPickMistakes.heldWhenRight);
    }
    _tag(M3CrossarmPickLines.caughtHold);
    shown = true;
    return const M3CrossarmPickOutcome(M3CrossarmPickVerdict.right);
  }

  /// The next part (after the reason).
  void next() {
    round++;
    rejected.clear();
    spotted.clear();
    shown = false;
  }
}

@immutable
class M3CrossarmPickPack {
  const M3CrossarmPickPack({required this.id, required this.titleBn, this.quickMs = 80000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3CrossarmPickPack33 = M3CrossarmPickPack(id: 'do_3_3_a', titleBn: M3CrossarmPickLines.title);
const Map<String, M3CrossarmPickPack> m3CrossarmPickPacks = {'do_3_3_a': m3CrossarmPickPack33};

// ============================================================================
// Page
// ============================================================================

class M3CrossarmPickPage extends StatefulWidget {
  const M3CrossarmPickPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3CrossarmPickPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3CrossarmPickPage> createState() => _M3CrossarmPickPageState();
}

class _M3CrossarmPickPageState extends State<M3CrossarmPickPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CpRunPage(
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

class _CpRunPage extends ConsumerStatefulWidget {
  const _CpRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3CrossarmPickPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CpRunPage> createState() => _CpRunPageState();
}

class _CpRunPageState extends ConsumerState<_CpRunPage> with DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3CrossarmPickRun _run = M3CrossarmPickRun(m3CrossarmPickDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The part in the trainee's hands (the close look).
  M3CrossarmPickItem? _held;
  var _docketOpen = false;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  M3CrossarmPickPush _push = M3CrossarmPickPush.anyClamp;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how to touch, never what).
  final _hints = IdleHintController();
  final _sceneKey = GlobalKey();
  final _holdKey = GlobalKey();
  final _feelKey = GlobalKey();
  final _putBackKey = GlobalKey();
  final _takeKey = GlobalKey();
  final _zoomKey = GlobalKey();
  M3CrossarmPickStoreGeo? _geo;

  /// The hand has touched the part in hand (the hint moves on to the buttons).
  var _felt = false;

  String get _rungId => widget.ctx.rungId;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice (never holds the player) -------------------------------------------

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

  String get _ask => M3CrossarmPickLines.ask(_run.current.slot);
  String get _task => _held == null ? _ask : M3CrossarmPickLines.inspectAsk;

  // ---- flow -----------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([_ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  bool get _blocked => _intro || _ended || _card != null || tableBusy || _run.shown;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// A part comes off the rack into the trainee's hands.
  void _pick(M3CrossarmPickItem t, Offset origin) {
    // Going on working while he is still talking refuses him too — whichever
    // part is touched (a part that did not respond would point at his).
    if (coworkerOpen && !coworkerChoiceUp && !_ended) unawaited(answerCoworker(true, origin, direct: true));
    if (_blocked || coworkerOpen || _held != null || _docketOpen || _run.rejected.contains(t.id)) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.4, muted: false));
    _hush();
    _felt = false;
    setState(() {
      _held = t;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([_task]));
  }

  /// A fault came into view under the hand. No sound or buzz: the eye must
  /// catch it (a cue only on a fault would judge the part for the player).
  void _found() {
    final t = _held;
    if (t != null) _run.spot(t);
  }

  void _putBack() {
    final t = _held;
    if (t == null || _blocked || coworkerOpen) return;
    // Sending his last push to the drum would leave him nothing to say on
    // this rack (and none at all on the last part): it waits for him like a
    // take. The part goes back on its shelf, not rejected, while he talks.
    if (_takesLastPush(t) && holdForCoworker()) {
      setState(() {
        _held = null;
        _setMode(LinemanMode.idle);
      });
      return;
    }
    final aside = _run.putBack(t);
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (aside) {
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.ogg', volume: 0.6, muted: false));
      unawaited(_sayChain([M3CrossarmPickLines.asideFlaw, _ask], mood: GuideMood.glad));
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
      unawaited(_sayChain([_ask]));
    }
  }

  /// Putting [t] back would send it to the drum and leave nothing he could
  /// push on this rack.
  bool _takesLastPush(M3CrossarmPickItem t) {
    if (!coworkerDue || !_run.spotted.contains(t.id) || _run.rejected.contains(t.id)) return false;
    final r = _run.current;
    final rust = _run.deal.preferRust;
    return m3CrossarmPickPushFor(r, _run.rejected, preferRust: rust) != null &&
        m3CrossarmPickPushFor(r, {..._run.rejected, t.id}, preferRust: rust) == null;
  }

  void _pack(Offset origin) {
    final t = _held;
    if (t == null || _blocked || coworkerOpen) return;
    if (holdForCoworker()) {
      // He cuts in as the part is about to go on the trolley: it goes back
      // on its shelf (nothing judged) while he talks.
      setState(() {
        _held = null;
        _setMode(LinemanMode.idle);
      });
      return;
    }
    setState(() => _held = null);
    _judgePack(t, origin);
  }

  void _judgePack(M3CrossarmPickItem t, Offset origin) {
    final o = _run.pack(t);
    if (o.verdict == M3CrossarmPickVerdict.right) {
      HapticFeedback.lightImpact();
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.6, muted: false));
        unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.5, muted: false));
      }
      setState(() => _setMode(LinemanMode.cheer));
      final s = t.shape;
      _askWhy(15, () => dealChoices(M3CrossarmPickLines.packRight(s), M3CrossarmPickLines.packWrong, widget.rng), M3CrossarmPickLines.packAsk);
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  void _holdJob(Offset origin) {
    if (_blocked || coworkerOpen || _held != null || _docketOpen) return;
    if (holdForCoworker()) return;
    _hush();
    final o = _run.holdJob();
    if (o.verdict == M3CrossarmPickVerdict.right) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.cheer));
      _askWhy(20, () => dealChoices(M3CrossarmPickLines.holdRight, M3CrossarmPickLines.holdWrong, widget.rng), M3CrossarmPickLines.holdAsk);
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  void _askWhy(int points, List<ChoiceOption> Function() deal, String question) {
    putOnTable(points);
    final round = _run.round;
    unawaited(askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended));
  }

  void _nextRound() {
    final held = _run.packed[_run.round] == null;
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() => _setMode(LinemanMode.idle));
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.5, muted: false));
    _armCoworker();
    unawaited(_sayChain([if (held) M3CrossarmPickLines.holdDone, _ask]));
  }

  void _openDocket() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.4, muted: false));
    setState(() => _docketOpen = true);
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
  void onReasonPaid() => _nextRound();

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M3CrossarmPickLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    final push = m3CrossarmPickPushFor(_run.current, _run.rejected, preferRust: _run.deal.preferRust);
    // Nothing he could push is left on this rack (it only shrinks within a
    // part): his line would not fit — he tries again on the next part.
    if (push == null) return null;
    _push = push;
    if (_blocked || _docketOpen || (_held != null && !coworkerHeld)) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Loaded what he pushed: the wrong clamp, or the rusty part.
      final t = m3CrossarmPickPushed(_run.current, _push, _run.rejected);
      if (t != null) _judgePack(t, origin);
      return;
    }
    _run.caught.add(M3CrossarmPickLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([M3CrossarmPickLines.callHeld, _ask], mood: GuideMood.glad);
    }());
  }

  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3CrossarmPickLines.tapWhy[_nudgeN++ % M3CrossarmPickLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- mistakes ---------------------------------------------------------------------

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.7, muted: false));
    _hush();
    setState(() => _card = m);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('crossarm_pick/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _setMode(LinemanMode.idle);
    });
    unawaited(_sayChain([_ask]));
  }

  // ---- score and result ---------------------------------------------------------------

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
    await _say(!_run.passed ? M3CrossarmPickLines.fail : (_quickBonus ? M3CrossarmPickLines.quick : M3CrossarmPickLines.allSet),
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

  // ---- gesture hints ------------------------------------------------------------------

  /// The level waits for a touch on the scene now (not during the intro, a
  /// card, a deck — it has its own sweep —, the praise window, him, results).
  bool get _hintWaiting =>
      !_intro && !_ended && _mark == null && !struckOut && _card == null && !tableBusy && !_run.shown && !coworkerOnScreen;

  /// A rect in the store's design pixels, on screen.
  Rect? _sceneRect(Rect r) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return MatrixUtils.transformRect(box.getTransformTo(null), r);
  }

  HintSpec? _hint() {
    if (_docketOpen) return HintSpec.tapOn(_zoomKey);
    if (_held != null) {
      if (!_felt) {
        // A short nudge along the part from its near end: "run a hand along".
        final r = HintSpec.globalRectOf(_feelKey);
        return r == null ? null : HintSpec.drag(Offset(r.left + r.width * 0.08, r.center.dy), toward: const Offset(1, 0), travel: 80);
      }
      return HintSpec.sweepOver([_putBackKey, _takeKey]);
    }
    final geo = _geo;
    if (geo == null) return null;
    final r = _run.current;
    final rects = <Rect>[
      for (var i = 0; i < r.items.length; i++)
        if (!_run.rejected.contains(r.items[i].id)) ?_sceneRect(geo.slot(i)),
      ?HintSpec.globalRectOf(_holdKey),
    ];
    return rects.length < 2 ? null : HintSpec.sweep(rects);
  }

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = _geo = M3CrossarmPickStoreGeo(m.height);
    final r = _run.current;
    final aside = [for (final x in r.items) if (_run.rejected.contains(x.id)) x];
    final canPick = !_blocked && _held == null && !_docketOpen;
    final done = {for (var i = 0; i < _run.round; i++) i};
    return [
      Positioned.fill(
        key: const ValueKey('store'),
        // A tap on the bare store hits nothing: it counts toward the hint.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hints.missTap,
          child: RepaintBoundary(key: _sceneKey, child: CustomPaint(painter: M3CrossarmPickStorePainter(geo))),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('docket'),
        rect: geo.docket,
        child: _DocketSheet(deal: _run.deal, done: done, quiet: quiet, onTap: _openDocket),
      ),
      // What is loaded lies in its well on the trolley.
      for (final e in _run.packed.entries)
        Positioned.fromRect(
          key: ValueKey('packed-${e.value.id}'),
          rect: geo.well(e.key).deflate(2),
          child: _Loaded(item: e.value, quiet: quiet),
        ),
      // The rack: one shelf row per part (it stays, empty, once taken).
      for (var i = 0; i < r.items.length; i++)
        Positioned.fromRect(
          key: ValueKey('slot-${_run.round}-$i'),
          rect: geo.slot(i),
          child: DoDealIn(
            index: i,
            quiet: quiet,
            muted: true,
            child: _RackPart(
              item: r.items[i],
              gone: _run.rejected.contains(r.items[i].id) || _run.packed[_run.round]?.id == r.items[i].id || _held?.id == r.items[i].id,
              enabled: canPick,
              onTake: (at) => _pick(r.items[i], at),
            ),
          ),
        ),
      for (var i = 0; i < aside.length && i < 3; i++)
        Positioned.fromRect(
          key: ValueKey('aside-${aside[i].id}'),
          rect: geo.aside(i),
          child: _AsidePart(item: aside[i], quiet: quiet),
        ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final holdUp = playing && _held == null && !_docketOpen && _card == null && !deckUp && !_run.shown && !tableBusy && !coworkerOpen;
    final held = _held;
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
              labels: [for (final r in _run.deal.rounds) r.slot.nameBn],
              done: {for (var i = 0; i < math.min(_run.round, _run.deal.rounds.length); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: (_run.round, _held?.id, _docketOpen),
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (holdUp)
                Positioned(
                  key: const ValueKey('hud-hold'),
                  left: 12,
                  right: 128,
                  bottom: pad.bottom + 18,
                  child: _HoldButton(key: _holdKey, onTapUp: (d) => _holdJob(d.globalPosition)),
                ),
              if (held != null && playing)
                _Inspect(
                  key: ValueKey('inspect-${held.id}'),
                  item: held,
                  slot: _run.current.slot,
                  quiet: quiet,
                  feelKey: _feelKey,
                  putBackKey: _putBackKey,
                  takeKey: _takeKey,
                  onFound: _found,
                  onTouch: () => _felt = true,
                  onMiss: _hints.missTap,
                  onTake: _pack,
                  onPutBack: _putBack,
                ),
              if (_docketOpen && playing)
                _DocketZoom(
                  key: const ValueKey('docket-zoom'),
                  cardKey: _zoomKey,
                  deal: _run.deal,
                  done: {for (var i = 0; i < _run.round; i++) i},
                  quiet: quiet,
                  onClose: () => setState(() => _docketOpen = false),
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
              if (playing && _card == null && !_docketOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
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
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M3CrossarmPickLines.intro,
                  alarm: 'sounds/van_arrive.ogg',
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

const _paper = Color(0xFFF7F1E1);
const _ink = Color(0xFF1E2228);
const _brown = Color(0xFF8C6A2A);
const _grey = Color(0xFF5A6478);
const _bench = Color(0xFF26303B);

List<String> _docketLines(M3CrossarmPickDocket d) => [
      d.line.nameBn,
      ?d.line.formationBn,
      d.pole.nameBn,
    ];

/// The docket on its nail: the line, the pole and the three parts, the
/// loaded ones ticked.
class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.deal, required this.done, required this.quiet, required this.onTap});
  final M3CrossarmPickDeal deal;
  final Set<int> done;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform.translate(offset: Offset(0, -30 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 6, 4, 4),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(M3CrossarmPickLines.docket, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: _brown, height: 1.1)),
              Container(height: 0.8, color: const Color(0x55B59B62), margin: const EdgeInsets.symmetric(vertical: 2)),
              for (final l in _docketLines(deal.docket))
                Text(l, maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 7, fontWeight: FontWeight.w900, color: _ink, height: 1.25)),
              const SizedBox(height: 3),
              Text(M3CrossarmPickLines.partsWord, style: bangla(fontSize: 6.5, fontWeight: FontWeight.w800, color: _brown, height: 1.1)),
              for (var i = 0; i < deal.rounds.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 1.5),
                  child: Row(
                    children: [
                      Icon(done.contains(i) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 8, color: done.contains(i) ? const Color(0xFF2E7D32) : _grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(deal.rounds[i].slot.nameBn,
                            maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 6.5, fontWeight: FontWeight.w700, color: _ink, height: 1.15)),
                      ),
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

/// The docket held up close (tap anywhere to hang it back).
class _DocketZoom extends StatelessWidget {
  const _DocketZoom({super.key, required this.cardKey, required this.deal, required this.done, required this.quiet, required this.onClose});
  final GlobalKey cardKey;
  final M3CrossarmPickDeal deal;
  final Set<int> done;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final d = deal.docket;
    final line = [d.line.nameBn, ?d.line.formationBn].join(' · ');
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
              child: Container(
                key: cardKey,
                width: 300,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB59B62), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: _brown, size: 22),
                        const SizedBox(width: 8),
                        Text(M3CrossarmPickLines.docket, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
                      ],
                    ),
                    const Divider(color: Color(0x55B59B62), height: 14),
                    Text(line, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: _ink, height: 1.3)),
                    Text(d.pole.nameBn, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: _ink, height: 1.3)),
                    Text('${d.feederBn} · ${M3CrossarmPickLines.shutdown(d)}', style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: _grey, height: 1.4)),
                    const SizedBox(height: 8),
                    Text(M3CrossarmPickLines.partsWord, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: _brown)),
                    for (var i = 0; i < deal.rounds.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(done.contains(i) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                size: 20, color: done.contains(i) ? const Color(0xFF2E7D32) : _grey),
                            const SizedBox(width: 8),
                            Flexible(child: Text(deal.rounds[i].slot.nameBn, style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: _ink))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A part lying on its shelf row. From a step away its type shows, its
/// faults do not. Tap it to take it in hand.
class _RackPart extends StatelessWidget {
  const _RackPart({required this.item, required this.gone, required this.enabled, required this.onTake});
  final M3CrossarmPickItem item;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  Widget build(BuildContext context) {
    if (gone) return Semantics(label: M3CrossarmPickLines.partLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: M3CrossarmPickLines.partLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? (d) => onTake(d.globalPosition) : null,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AspectRatio(
            aspectRatio: M3CrossarmPickPainter.aspectOf(item.shape),
            child: CustomPaint(painter: M3CrossarmPickPainter(item, seen: const {})),
          ),
        ),
      ),
    );
  }
}

/// A loaded part lying in its well on the trolley.
class _Loaded extends StatelessWidget {
  const _Loaded({required this.item, required this.quiet});
  final M3CrossarmPickItem item;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(0, -50 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Center(child: AspectRatio(aspectRatio: M3CrossarmPickPainter.aspectOf(item.shape), child: CustomPaint(painter: M3CrossarmPickPainter(item)))),
    );
  }
}

/// A part set aside, leaning out of the scrap drum, tagged বাতিল.
class _AsidePart extends StatelessWidget {
  const _AsidePart({required this.item, required this.quiet});
  final M3CrossarmPickItem item;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(-60 * (1 - t), 0), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Transform.rotate(
        angle: -0.35,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Center(
                child: AspectRatio(aspectRatio: M3CrossarmPickPainter.aspectOf(item.shape), child: CustomPaint(painter: M3CrossarmPickPainter(item))),
              ),
            ),
            Positioned(
              top: -4,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
                child: Text(M3CrossarmPickLines.rejected, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1A33),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.85), width: 1.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 18, color: SlmColors.warning),
              const SizedBox(width: 8),
              Flexible(
                child: Text(M3CrossarmPickLines.hold,
                    textAlign: TextAlign.center, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The close look, hands on: the part held up big; run a hand along it —
/// rust where the galvanizing is gone, a bend in the arm, show only where the
/// hand has been. Then load it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.item,
    required this.slot,
    required this.quiet,
    required this.feelKey,
    required this.putBackKey,
    required this.takeKey,
    required this.onFound,
    required this.onTouch,
    required this.onMiss,
    required this.onTake,
    required this.onPutBack,
  });
  final M3CrossarmPickItem item;
  final M3CrossarmPickSlot slot;
  final bool quiet;
  final GlobalKey feelKey;
  final GlobalKey putBackKey;
  final GlobalKey takeKey;
  final VoidCallback onFound;

  /// The hand touched the part (once per close look).
  final VoidCallback onTouch;

  /// A tap on the dim backdrop (nothing there).
  final VoidCallback onMiss;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _seen = {};
  Offset? _hand;
  var _found = false;

  void _touch(Offset p, Size s) {
    if (_seen.isEmpty) widget.onTouch();
    final b = m3CrossarmPickBin(M3CrossarmPickPainter.uAt(s, p.dx));
    final before = _seen.length;
    for (final x in [b - 1, b, b + 1]) {
      if (x >= 0 && x < kM3CrossarmPickBins) _seen.add(x);
    }
    final grew = _seen.length != before;
    if (!_found && M3CrossarmPickPainter.flawSeen(widget.item, _seen)) {
      _found = true;
      widget.onFound();
    }
    if (grew || _hand != p) setState(() => _hand = p);
  }

  Widget _closeUp(M3CrossarmPickItem t) => LayoutBuilder(
        builder: (context, box) {
          final s = Size(box.maxWidth, box.maxHeight);
          return Semantics(
            label: M3CrossarmPickLines.handLabel,
            child: GestureDetector(
              key: widget.feelKey,
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _touch(d.localPosition, s),
              onPanUpdate: (d) => _touch(d.localPosition, s),
              onPanEnd: (_) => setState(() => _hand = null),
              onPanCancel: () => setState(() => _hand = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: CustomPaint(painter: M3CrossarmPickPainter(t, seen: _seen, veil: _bench))),
                  if (_seen.isEmpty) _Puck(at: Offset(M3CrossarmPickPainter.xAt(s, 0.08), s.height * 0.5)),
                  if (_hand != null) _Puck(at: _hand!, live: true),
                ],
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final t = widget.item;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onMiss,
        child: ColoredBox(
          color: const Color(0xC0050A16),
          child: Align(
            alignment: const Alignment(0, -0.42),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.translate(
                offset: Offset(0, 80 * (1 - v)),
                child: Transform.scale(scale: 0.85 + 0.15 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                decoration: BoxDecoration(
                  color: SlmColors.ivory,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                        decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFB59B62))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_rounded, color: _brown, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text('${M3CrossarmPickLines.docket} · ${widget.slot.nameBn}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AspectRatio(
                      aspectRatio: 2.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4654), _bench]),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                          child: Center(child: AspectRatio(aspectRatio: M3CrossarmPickPainter.aspectOf(t.shape), child: _closeUp(t))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: DoBigButton(key: widget.putBackKey, label: M3CrossarmPickLines.putBack, filled: false, onTapUp: (_) => widget.onPutBack())),
                        const SizedBox(width: 12),
                        Expanded(child: DoBigButton(key: widget.takeKey, label: M3CrossarmPickLines.take, filled: true, onTapUp: (d) => widget.onTake(d.globalPosition))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Puck extends StatelessWidget {
  const _Puck({required this.at, this.live = false});
  final Offset at;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 22.0 : 17.0;
    return Positioned(
      left: at.dx - r,
      top: at.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0x55FF851B) : const Color(0x33FF851B),
            border: Border.all(color: const Color(0xFFFF851B), width: live ? 2 : 1.4),
          ),
          child: Icon(Icons.back_hand_rounded, size: r * 1.05, color: const Color(0xFFB4560E)),
        ),
      ),
    );
  }
}

// ============================================================================
// The parts, drawn
// ============================================================================

/// How many stretches a part is looked at in.
const kM3CrossarmPickBins = 20;
int m3CrossarmPickBin(double u) => (u * kM3CrossarmPickBins).floor().clamp(0, kM3CrossarmPickBins - 1);

/// A part drawn lengthwise: a galvanized cross-arm (a shallow V, a straight
/// I angle, or a deeper channel with its flanges, pin holes along it), a
/// clamp (a round wrap-around band with its two ears and bolts, or a flat
/// plate gripped by two long through-bolts) or two bolts with nuts (with or
/// without the split spring washer). Faults show only once their stretch has
/// been looked at ([seen]: stretches of [kM3CrossarmPickBins]; null = all
/// seen); unseen stretches are washed with [veil] when it is set.
class M3CrossarmPickPainter extends CustomPainter {
  M3CrossarmPickPainter(this.item, {this.seen, this.veil});
  final M3CrossarmPickItem item;
  final Set<int>? seen;
  final Color? veil;

  /// The part's own box (width : height).
  static double aspectOf(M3CrossarmPickShape s) => s.slot == M3CrossarmPickSlot.crossarm ? 5.0 : 2.4;

  static double _pad(Size s) => s.height * 0.06;
  static double xAt(Size s, double u) => _pad(s) + u * (s.width - 2 * _pad(s));
  static double uAt(Size s, double x) => ((x - _pad(s)) / (s.width - 2 * _pad(s))).clamp(0.0, 1.0);

  static int _hash(M3CrossarmPickItem t) => t.id.codeUnits.fold(0, (a, b) => a + b);

  /// Where along the part its fault sits (null: sound).
  static double? flawU(M3CrossarmPickItem t) => switch (t.flaw) {
        M3CrossarmPickFlaw.none => null,
        M3CrossarmPickFlaw.bend => 0.3 + (_hash(t) % 3) * 0.2,
        M3CrossarmPickFlaw.rust => t.shape.slot == M3CrossarmPickSlot.crossarm ? 0.18 + (_hash(t) % 5) * 0.14 : 0.25 + (_hash(t) % 3) * 0.22,
      };

  /// The fault is in view: its stretch has been looked at.
  static bool flawSeen(M3CrossarmPickItem t, Set<int>? seen) {
    final u = flawU(t);
    if (u == null) return false;
    return seen == null || seen.contains(m3CrossarmPickBin(u));
  }

  bool _show(double u) => seen == null || seen!.contains(m3CrossarmPickBin(u));

  static const _zinc = [Color(0xFFEFF2F4), Color(0xFFB4BCC3), Color(0xFF7D868E)];
  static const _hole = Color(0xFF39414A);

  Paint _galv(Rect r) => Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _zinc).createShader(r);

  @override
  void paint(Canvas c, Size s) {
    final u = flawU(item);
    final bent = item.flaw == M3CrossarmPickFlaw.bend && u != null && _show(u);
    if (bent) {
      // Straight to the bend, then the rest of the arm kinked down.
      final px = xAt(s, u);
      final py = _barY(s, u);
      c.save();
      c.clipRect(Rect.fromLTRB(-s.width, -s.height, px, s.height * 2));
      _part(c, s);
      c.restore();
      c.save();
      c.clipRect(Rect.fromLTRB(px, -s.height, s.width * 2, s.height * 2));
      c.translate(px, py);
      c.rotate(0.16);
      c.translate(-px, -py);
      _part(c, s);
      c.restore();
      // No ring round the kink: the bend itself is the only sign.
    } else {
      _part(c, s);
    }
    if (item.flaw == M3CrossarmPickFlaw.rust && u != null && _show(u)) _rust(c, s, u);
    final v = veil;
    if (v != null && seen != null) {
      final wash = Paint()..color = v.withValues(alpha: 0.5);
      for (var i = 0; i < kM3CrossarmPickBins; i++) {
        if (seen!.contains(i)) continue;
        final a = xAt(s, i / kM3CrossarmPickBins);
        final b = xAt(s, (i + 1) / kM3CrossarmPickBins);
        c.drawRect(Rect.fromLTRB(a, 0, b + 0.5, s.height), wash);
      }
    }
  }

  void _part(Canvas c, Size s) {
    switch (item.shape) {
      case M3CrossarmPickShape.vArm:
        _vArm(c, s);
      case M3CrossarmPickShape.iArm:
        _straightArm(c, s, channel: false);
      case M3CrossarmPickShape.channel:
        _straightArm(c, s, channel: true);
      case M3CrossarmPickShape.wrapClamp:
        _wrapClamp(c, s);
      case M3CrossarmPickShape.boltClamp:
        _boltClamp(c, s);
      case M3CrossarmPickShape.nutsSpring:
        _nuts(c, s, washer: true);
      case M3CrossarmPickShape.nutsBare:
        _nuts(c, s, washer: false);
    }
  }

  void _holes(Canvas c, Size s, double y, List<double> us, double r) {
    final p = Paint()..color = _hole;
    for (final u in us) {
      c.drawCircle(Offset(xAt(s, u), y), r, p);
    }
  }

  /// A straight angle (I) or a deeper channel section, seen from the front.
  void _straightArm(Canvas c, Size s, {required bool channel}) {
    final h = s.height;
    final cy = h / 2;
    final th = channel ? h * 0.5 : h * 0.3;
    final r = Rect.fromLTRB(xAt(s, 0), cy - th / 2, xAt(s, 1), cy + th / 2);
    c.drawRect(r, _galv(r));
    final edge = Paint()..color = const Color(0xFF6E777F);
    if (channel) {
      // The two flanges (lips) top and bottom.
      c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, th * 0.16), Paint()..color = const Color(0xFFD5DBE0));
      c.drawRect(Rect.fromLTWH(r.left, r.bottom - th * 0.16, r.width, th * 0.16), Paint()..color = const Color(0xFF8D969E));
      c.drawLine(Offset(r.left, r.top + th * 0.16), Offset(r.right, r.top + th * 0.16), edge);
      c.drawLine(Offset(r.left, r.bottom - th * 0.16), Offset(r.right, r.bottom - th * 0.16), edge);
    } else {
      // The angle's top leg catching the light.
      c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, th * 0.4), Paint()..color = const Color(0xFFE5E9EC));
      c.drawLine(Offset(r.left, r.top + th * 0.4), Offset(r.right, r.top + th * 0.4), edge);
    }
    c.drawRect(r, Paint()
      ..color = const Color(0xFF5F676F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    _holes(c, s, cy + (channel ? 0 : th * 0.15), const [0.05, 0.3, 0.7, 0.95], h * 0.045);
    _holes(c, s, cy + (channel ? 0 : th * 0.15), const [0.46, 0.54], h * 0.055);
  }

  /// A shallow V: two arms meeting at the pole plate in the middle.
  void _vArm(Canvas c, Size s) {
    final h = s.height;
    final top = h * 0.24;
    final low = h * 0.72;
    final w = h * 0.24;
    for (final (a, b) in [(Offset(xAt(s, 0.0), top), Offset(xAt(s, 0.5), low)), (Offset(xAt(s, 1.0), top), Offset(xAt(s, 0.5), low))]) {
      final r = Rect.fromPoints(a, b).inflate(w);
      c.drawLine(a, b, _galv(r)
        ..strokeWidth = w
        ..strokeCap = StrokeCap.square);
      c.drawLine(a + Offset(0, -w * 0.3), b + Offset(0, -w * 0.3), Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = w * 0.18);
    }
    // The pole plate where the arms meet.
    final plate = Rect.fromCenter(center: Offset(xAt(s, 0.5), low - h * 0.06), width: h * 0.7, height: h * 0.42);
    c.drawRect(plate, _galv(plate));
    c.drawRect(plate, Paint()
      ..color = const Color(0xFF5F676F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    _holes(c, s, plate.center.dy, const [0.475, 0.525], h * 0.05);
    // Pin holes near both ends.
    final p = Paint()..color = _hole;
    for (final u in [0.05, 0.95]) {
      c.drawCircle(Offset(xAt(s, u), top + (low - top) * 0.1), h * 0.045, p);
    }
  }

  void _hex(Canvas c, Offset at, double r) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3;
      final p = at + Offset(math.cos(a) * r * 0.62, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    c.drawPath(path, _galv(Rect.fromCircle(center: at, radius: r)));
    c.drawPath(path, Paint()
      ..color = const Color(0xFF5F676F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  /// A round band that wraps the PCC pole, with its two ears bolted.
  void _wrapClamp(Canvas c, Size s) {
    final h = s.height;
    final cy = h / 2;
    final ring = Rect.fromCenter(center: Offset(xAt(s, 0.5), cy), width: h * 0.82, height: h * 0.82);
    c.drawOval(ring, Paint()
      ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _zinc).createShader(ring)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.12);
    for (final (a, b) in [(0.12, 0.33), (0.67, 0.88)]) {
      final ear = Rect.fromLTRB(xAt(s, a), cy - h * 0.1, xAt(s, b), cy + h * 0.1);
      c.drawRect(ear, _galv(ear));
      c.drawRect(ear, Paint()
        ..color = const Color(0xFF5F676F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }
    for (final u in [0.2, 0.8]) {
      _hex(c, Offset(xAt(s, u), cy), h * 0.13);
    }
  }

  /// A flat plate gripped by two long through-bolts (for rail / H-beam).
  void _boltClamp(Canvas c, Size s) {
    final h = s.height;
    final cy = h / 2;
    final plate = Rect.fromLTRB(xAt(s, 0.3), cy - h * 0.34, xAt(s, 0.7), cy + h * 0.34);
    c.drawRect(plate, _galv(plate));
    c.drawRect(plate, Paint()
      ..color = const Color(0xFF5F676F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    for (final dy in [-h * 0.2, h * 0.2]) {
      final y = cy + dy;
      final rod = Rect.fromLTRB(xAt(s, 0.04), y - h * 0.045, xAt(s, 0.96), y + h * 0.045);
      c.drawRect(rod, _galv(rod));
      for (final u in [0.08, 0.92]) {
        _hex(c, Offset(xAt(s, u), y), h * 0.11);
      }
    }
  }

  /// Two bolts with their nuts; [washer]: the split spring washer under each nut.
  void _nuts(Canvas c, Size s, {required bool washer}) {
    final h = s.height;
    for (final y in [h * 0.3, h * 0.7]) {
      final shank = Rect.fromLTRB(xAt(s, 0.12), y - h * 0.07, xAt(s, 0.96), y + h * 0.07);
      c.drawRect(shank, _galv(shank));
      final thread = Paint()
        ..color = const Color(0x665F676F)
        ..strokeWidth = 1;
      for (var u = 0.5; u < 0.96; u += 0.03) {
        c.drawLine(Offset(xAt(s, u), y - h * 0.07), Offset(xAt(s, u + 0.015), y + h * 0.07), thread);
      }
      // The bolt head.
      final head = Rect.fromLTRB(xAt(s, 0.02), y - h * 0.16, xAt(s, 0.12), y + h * 0.16);
      c.drawRect(head, _galv(head));
      c.drawRect(head, Paint()
        ..color = const Color(0xFF5F676F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      if (washer) {
        // The spring washer: a split ring, its ends offset.
        final wx = xAt(s, 0.595);
        final ww = h * 0.1;
        final ring = Paint()..color = const Color(0xFF3E464E);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx - ww / 2, y - h * 0.2, ww, h * 0.17), Radius.circular(ww * 0.3)), ring);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx - ww / 2 + ww * 0.3, y + h * 0.03, ww, h * 0.17), Radius.circular(ww * 0.3)), ring);
        // The split: the two ends sprung apart.
        c.drawLine(Offset(wx - ww / 2, y - h * 0.03), Offset(wx + ww * 0.8, y + h * 0.03), Paint()
          ..color = const Color(0xFF3E464E)
          ..strokeWidth = h * 0.05);
      }
      // The nut.
      final nut = Rect.fromLTRB(xAt(s, 0.64), y - h * 0.15, xAt(s, 0.74), y + h * 0.15);
      c.drawRect(nut, _galv(nut));
      c.drawRect(nut, Paint()
        ..color = const Color(0xFF5F676F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      c.drawLine(Offset(nut.center.dx, nut.top), Offset(nut.center.dx, nut.bottom), Paint()
        ..color = const Color(0x445F676F)
        ..strokeWidth = 1);
    }
  }

  /// The bar's centre line at [u] (the V dips to its middle).
  double _barY(Size s, double u) =>
      item.shape == M3CrossarmPickShape.vArm ? s.height * (0.24 + 0.48 * (1 - (u - 0.5).abs() * 2)) : s.height / 2;

  /// Rust where the zinc is gone: orange-brown blotches and pits.
  void _rust(Canvas c, Size s, double u) {
    final h = s.height;
    final px = xAt(s, u);
    final cy = _barY(s, u);
    final rng = math.Random(_hash(item));
    for (var i = 0; i < 7; i++) {
      final o = Offset(px + (rng.nextDouble() - 0.5) * h * 0.5, cy + (rng.nextDouble() - 0.5) * h * 0.26);
      c.drawOval(Rect.fromCenter(center: o, width: h * (0.1 + rng.nextDouble() * 0.12), height: h * (0.07 + rng.nextDouble() * 0.08)),
          Paint()..color = i.isEven ? const Color(0xDDB5541C) : const Color(0xCC7A3410));
    }
    for (var i = 0; i < 4; i++) {
      c.drawCircle(Offset(px + (rng.nextDouble() - 0.5) * h * 0.36, cy + (rng.nextDouble() - 0.5) * h * 0.2), h * 0.018, Paint()..color = const Color(0xFF3A1A08));
    }
  }

  @override
  bool shouldRepaint(M3CrossarmPickPainter old) => old.item != item || old.veil != veil || old.seen?.length != seen?.length;
}
