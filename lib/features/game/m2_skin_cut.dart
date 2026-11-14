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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_skin_cut_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm2_skin_cut_world.dart' show SkinFault, SkinGeo, skinFaultRect;

// Lesson 2.6 "কেবিল স্কিনিং-এর শিল্প", কাজ 2 "শরীরের উল্টো দিকে কাটুন".
// At a work bench on a job site the trainee skins two LT cable ends for
// their lugs, then checks three ends a coworker stripped. Hands on:
//   • cut-resistant gloves on (point 2's safety tip);
//   • look at the blade — a blunt one is swapped (point 1's daily check);
//   • the chalk mark at the lug barrel's length (point 2 "মেপে নিন", pro tip 1:
//     not too much, not too little) — a tap on the cable puts it;
//   • the strokes: push the knife along the strip AWAY from the body (point 2:
//     never pull towards yourself), never round the cable (point 2: a ring
//     cut leaves a ring mark on the conductor), a light groove first and then
//     a little more pressure (pro tip 2), never hard (point 1: a nick weakens
//     the conductor and makes a hotspot); the sleeve then comes off;
//   • the bench: each end under the lens — smooth and bright, no deep
//     scratch, black mark or cut strand, the insulation edge smooth and
//     square (point 3); a faulty end is skinned again.
// Every slip on a cut: the end is cut back and skinned again (as the lesson:
// a nicked end is redone). Cutting towards the body is a slip with an injury
// shown (the lesson: "মারাত্মক আঘাত" — a serious injury, not a death), so this
// level has no deadly move. Sending a clean end back is a slip too (a wrong
// call costs; the card explains only after the decision).
// The pressure isn't preset: a stroke away waits until one is picked.
// The careless coworker once a play: on a cut, once he has seen a stroke away
// ("নিজের দিকে টেনে কাটো"), or on the nicked end at the bench (the lesson's
// myth: "সামান্য আঁচড় … ক্রিম্পিং-এ সব ঠিক হয়ে যায়"). The next stroke away /
// the verdict on that end waits for him (holdForCoworker). Listening = a slip.
// Voice: the guide by device TTS; his exit line is his recorded clip; his two
// pushes have no clip yet (silent, caption held — the kit) until recorded.
// +5 thorough bonuses (blade looked at; fault found under the lens) are this
// level's own, kept by the owner's decision.

// ============================================================================
// Content
// ============================================================================

/// How hard the knife is pressed.
enum SkinPress { light, medium, hard }

/// Which way a stroke went (the trainee stands at the cable's left end).
enum SkinStroke { away, toward, across }

/// Where the coworker pushes.
enum SkinPush { cut, bench }

@immutable
class SkinCable {
  const SkinCable({required this.id, required this.barrel, required this.blunt, required this.colour});
  final String id;

  /// The lug barrel's length (design px) = the length to strip.
  final double barrel;

  /// The knife's blade is blunt for this cable (until swapped).
  final bool blunt;
  final int colour;
}

/// The phase colours of the insulation.
const kSkinColours = [Color(0xFFD23A2E), Color(0xFFE8B923), Color(0xFF2D5FB8), Color(0xFF2B2B2E)];

/// The strip length may be this far off the barrel (design px).
const double kSkinMarkTol = 8;

/// Depth of the insulation in strokes: light = 1, medium = 2.
const int kSkinDepth = 3;

abstract final class SkinLines {
  static const title = 'শরীরের উল্টো দিকে কাটুন';
  static const intro = 'দুটো কেবিল ছিলে লাগ লাগাতে হবে, তারপর সহকর্মীর ছিলা প্রান্ত যাচাই। কন্ডাক্টরে একটা আঁচড়ও নয়, হাতেও নয়!';
  static const rounds = ['ক', 'খ', 'গ'];
  static const askCut = 'কেবিলটা লাগের মাপে ছিলুন।';
  static const askBench = 'প্রান্তগুলো দেখুন — কোনটা চলবে?';
  static const tasks = [askCut, askBench];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  /// A stroke with no pressure picked yet (the task again, no answer).
  static const askPress = 'চাপ কতটা দেবেন — আগে বেছে নিন।';

  // Labels a worker reads.
  static const sceneLabel = 'বেঞ্চে কেবিল';
  static const gloves = 'কাটা-রোধী গ্লাভস';
  static const blade = 'ব্লেড দেখি';
  static const newBlade = 'নতুন ব্লেড লাগাই';
  static const keepBlade = 'রেখে দিই';
  static const press = 'চাপ';
  static const light = 'হালকা';
  static const medium = 'মাঝারি';
  static const hard = 'জোরে';
  static String pressBn(SkinPress p) => switch (p) {
        SkinPress.light => light,
        SkinPress.medium => medium,
        SkinPress.hard => hard,
      };
  static const pass = 'চলবে';
  static const redo = 'আবার ছিলতে হবে';
  static const lensClose = 'নামিয়ে রাখি';
  static const lensLabel = 'প্রান্ত কাছ থেকে';
  static const stampDone = 'নিখুঁত';
  static const stampPass = 'ঠিক আছে';
  static const stampRedo = 'আবার';
  static const ouch = 'আহ্!';

  // Reasons (lesson 2.6). Right ones state the lesson's rule; wrong ones are
  // the lesson's myths and field excuses. Every card 40–47 letters.
  static const whyCut = ['কেন এভাবে ছিললেন?', 'এভাবে কাটলেন কেন?'];
  static const cutWhy = [
    'ছুরি পিছলালেও শরীরে লাগবে না, তাই বাইরে ঠেলি',
    'শরীর থেকে বাইরে কাটলে মারাত্মক আঘাত এড়ানো যায়',
    'আগে হালকা খাঁজ, পরে চাপ, তাই কন্ডাক্টরে নিক নেই',
    'পেন্সিল ছোলার মতো কোণে কাটলে কন্ডাক্টর ছোঁয় না',
  ];
  static const cutMyths = [
    'নিজের দিকে টানলে জোর বেশি, তাড়াতাড়ি ছিলা যায়',
    'গোল করে কাটলে খোসাটা সবচেয়ে তাড়াতাড়ি খোলে',
    'একটু আঁচড় লাগলে ক্রিম্পিং-এর পর সব ঠিক হয়',
    'ছোট তার হলে দাঁত দিয়েই ছিলা সবচেয়ে দ্রুত হয়',
    'জোরে এক টানে কাটলেই কাজটা নিখুঁত হয়ে যায়',
    'মাপের দরকার নেই, একটু বেশি ছিললেই চলে যায়',
  ];
  static const whyRedo = 'কেন আবার ছিলতে দিলেন?';
  static const whyPass = 'কেন এটা চলবে বললেন?';
  static const nickWhy = [
    'নিকের জায়গায় তার দুর্বল হয়, হটস্পট তৈরি হয়',
    'আঁচড়ে ক্রস-সেকশন কমে, রেজিস্ট্যান্স বেড়ে যায়',
    'কম্পনে তার ওই দুর্বল জায়গা থেকেই ছিঁড়ে যায়',
  ];
  static const strandWhy = [
    'কাটা স্ট্র্যান্ড থাকলে কন্ডাক্টর কমে, আবার ছিলি',
    'কন্ডাক্টরে কাটা স্ট্র্যান্ড থাকা একদম চলবে না',
  ];
  static const blackWhy = [
    'কন্ডাক্টরে কালো দাগ থাকা চলবে না, আবার ছিলি',
    'পৃষ্ঠ মসৃণ আর উজ্জ্বল হওয়া চাই, কালো দাগ নয়',
  ];
  static const edgeWhy = [
    'ইনসুলেশনের কাটা প্রান্ত মসৃণ, 90-ডিগ্রিতে চাই',
    'ছেঁড়া, অসম প্রান্তে নিখুঁত সংযোগ তৈরি হয় না',
  ];
  static const cleanWhy = [
    'কন্ডাক্টর মসৃণ আর উজ্জ্বল, কোনো আঁচড় নেই',
    'আঁচড়, কালো দাগ, কাটা স্ট্র্যান্ড কিছুই নেই',
    'ইনসুলেশনের প্রান্ত মসৃণ, ঠিক 90-ডিগ্রিতে কাটা',
  ];

  /// Wrong reasons to send an end back: bad motives, never a rule.
  static const redoExcuses = [
    'নতুন করে ছিললে ওভারটাইম একটু বেশি পাওয়া যাবে',
    'সহকর্মীকে শিক্ষা দিতে হবে, তাই ফেরত দিলাম',
    'রংটা ঠিক পছন্দ হয়নি, তাই আবার ছিলতে দিলাম',
    'বেশি কাজ দেখালে সুপারভাইজার খুব খুশি হবেন',
    'কেবিল তো অনেক আছে, একটা নষ্ট হলে কী আসে যায়',
    'ভালো করে দেখার সময় নেই, তাই সবগুলোই ফেরত',
  ];

  /// Wrong reasons to pass an end: the myths and shortcuts.
  static const passMyths = [
    'সহকর্মীর কাজ, ওটা ভালো করে দেখার দরকার নেই',
    'একটু আঁচড় লাগলে ক্রিম্পিং-এর পর সব ঠিক হয়',
    'লাগ লাগালে আঁচড় ঢেকে যায়, কেউ দেখবে না',
    'খুব তাড়া আছে, যেমন আছে তেমনই লাগিয়ে দিই',
    'আগেও কতবার এভাবে লাগিয়েছি, কিছুই হয়নি',
    'দাঁত দিয়ে ছিলা হলেও তার তো দিব্যি ঠিক থাকে',
  ];

  static List<String> faultWhy(SkinFault f) => switch (f) {
        SkinFault.nick => nickWhy,
        SkinFault.strand => strandWhy,
        SkinFault.black => blackWhy,
        SkinFault.edge => edgeWhy,
        SkinFault.none => cleanWhy,
      };

  /// The careless coworker: his exit line is his recorded clip; the two
  /// pushes have no clip yet (silent, caption held) until recorded.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerCut = CoworkerScript(
    line: 'উল্টো দিকে কেন? নিজের দিকে টেনে কাটো, জোর বেশি, কাজ তাড়াতাড়ি!',
    exitLine: coworkerExit,
    right: ['না, শরীর থেকে বাইরের দিকেই কাটব', 'না, নিজের দিকে টানলে হাতে লাগবে', 'না, তাড়ার চেয়ে হাত বাঁচানো বড়'],
    wrong: ['ঠিক, নিজের দিকে টেনেই কাটি', 'আচ্ছা, জোরে টেনে শেষ করে দিই', 'হ্যাঁ, এভাবেই তাড়াতাড়ি হবে', 'সবাই তো নিজের দিকেই টেনে কাটে', 'ঠিক আছে, শুধু এই একবার টানি'],
    asks: ['ও বলছে নিজের দিকে টানতে। আপনি কী করবেন?', 'কোন দিকে কাটবেন?', 'ওর কথা শুনবেন?'],
  );
  static const coworkerBench = CoworkerScript(
    line: 'সামান্য আঁচড়ে কিছু হয় না! ক্রিম্পিং করলেই সব ঠিক হয়ে যায়।',
    exitLine: coworkerExit,
    right: ['না, আঁচড় থাকলে আবার ছিলতে হবে', 'না, ওই আঁচড়েই হটস্পট তৈরি হয়', 'না, নিখুঁত না হলে লাগ লাগাব না'],
    wrong: ['ঠিক, ক্রিম্পিং-এ সব ঠিক হবে', 'আচ্ছা, এটা দিয়েই লাগ লাগাই', 'হ্যাঁ, এটুকু আঁচড়ে কিছু হয় না', 'সবাই তো এভাবেই লাগিয়ে দেয়', 'ঠিক আছে, এবারের মতো চলুক'],
    asks: ['ও বলছে এটাই চলবে। আপনি কী বলবেন?', 'আবার ছিলতে দেবেন, না চালাবেন?', 'ওর কথা শুনবেন?'],
  );

  /// The new lines to record (his pushes, in his voice).
  static const toRecord = [
    'উল্টো দিকে কেন? নিজের দিকে টেনে কাটো, জোর বেশি, কাজ তাড়াতাড়ি!',
    'সামান্য আঁচড়ে কিছু হয় না! ক্রিম্পিং করলেই সব ঠিক হয়ে যায়।',
  ];

  static const allSet = 'হাত বাঁচিয়ে, কন্ডাক্টর অক্ষত রেখে ছিলতে শিখে গেছেন — আর খারাপ প্রান্তও চেনেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — মাপ, গ্লাভস, ধারালো ব্লেড, বাইরের দিকে হালকা হাতে।';
  static const redoLine = 'প্রান্তটা কেটে বাদ দিন — আবার ছিলুন।';

  // "আজ যা ধরলেন".
  static const caughtAway = 'শরীর থেকে বাইরের দিকে কেটেছেন';
  static const caughtGroove = 'আগে হালকা খাঁজ, পরে চাপ';
  static const caughtMark = 'লাগের ব্যারেল মেপে দাগ';
  static const caughtGloves = 'কাটা-রোধী গ্লাভস পরে কাজ';
  static const caughtBlade = 'ভোঁতা ব্লেড বদলে নিয়েছেন';
  static const caughtNick = 'নিক-আঁচড়ের প্রান্ত ফেরত';
  static const caughtStrand = 'কাটা স্ট্র্যান্ড ধরেছেন';
  static const caughtBlack = 'কালো দাগ ধরেছেন';
  static const caughtEdge = 'ছেঁড়া প্রান্ত ধরেছেন';
  static const caughtClean = 'নিখুঁত প্রান্ত চিনেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';

  static String caughtFault(SkinFault f) => switch (f) {
        SkinFault.nick => caughtNick,
        SkinFault.strand => caughtStrand,
        SkinFault.black => caughtBlack,
        SkinFault.edge => caughtEdge,
        SkinFault.none => caughtClean,
      };
}

abstract final class SkinMistakes {
  static const _dir = 'assets/game/art/m2_skin_cut';

  static const towardBody = DoMistake(
    key: '2.6/skin/toward-body',
    textBn: 'কখনো নিজের দিকে টেনে কাটবেন না — ছুরি পিছলালে সোজা হাতে-শরীরে লাগে। বুড়ো আঙুলে ছুরির পিঠে সাপোর্ট দিয়ে শরীর থেকে বাইরের দিকে ঠেলে কাটুন।',
    art: '$_dir/toward_body.svg',
    lessonPoint: 1,
  );
  static const ringCut = DoMistake(
    key: '2.6/skin/ring-cut',
    textBn: 'গোল করে ইনসুলেশন কাটবেন না — কন্ডাক্টরের ওপর রিং-এর মতো দাগ পড়ে। পেন্সিল ছোলার মতো সামান্য কোণে, প্রান্তের দিকে ঠেলে কাটুন।',
    art: '$_dir/ring_cut.svg',
    lessonPoint: 1,
  );
  /// Pro tip 2 (no lesson point: the reader opens the lesson from its start).
  static const noGroove = DoMistake(
    key: '2.6/skin/no-groove',
    textBn: 'প্রথমবারেই পুরো ইনসুলেশন কাটতে গেলে ব্লেড কন্ডাক্টরে বসে যায়। আগে হালকা হাতে একটা খাঁজ, তারপর ধীরে ধীরে চাপ বাড়ান।',
    art: '$_dir/nick.svg',
  );
  static const tooHard = DoMistake(
    key: '2.6/skin/too-hard',
    textBn: 'জোরে চাপে ব্লেড কন্ডাক্টরে নিক ফেলে — ওখানে তারের শক্তি কমে, হটস্পট তৈরি হয়। নিয়ন্ত্রিত চাপে, ধীরে ধীরে কাটুন।',
    art: '$_dir/nick.svg',
    lessonPoint: 0,
  );
  static const noGloves = DoMistake(
    key: '2.6/skin/no-gloves',
    textBn: 'কেবিল ছিলার কাজ সবসময় কাটা-রোধী গ্লাভস পরে করুন — ছুরি পিছলালে হাত বাঁচে।',
    art: '$_dir/gloves.svg',
    lessonPoint: 1,
  );
  static const bluntBlade = DoMistake(
    key: '2.6/skin/blunt-blade',
    textBn: 'ভোঁতা ব্লেডে অতিরিক্ত বল লাগে — পিছলে হাতে বা কন্ডাক্টরে লাগে। কাজের আগে দেখুন ব্লেড ধারালো আর পরিষ্কার কি না।',
    art: '$_dir/blade.svg',
    lessonPoint: 0,
  );
  static const wrongLength = DoMistake(
    key: '2.6/skin/wrong-length',
    textBn: 'আগে মাপুন: লাগের ব্যারেলের দৈর্ঘ্য অনুযায়ী ইনসুলেশন ছিলুন — খুব বেশি বা খুব কম নয়।',
    art: '$_dir/length.svg',
    lessonPoint: 1,
  );
  static const passNick = DoMistake(
    key: '2.6/skin/passed-nick',
    textBn: 'গভীর আঁচড়, কালো দাগ বা কাটা স্ট্র্যান্ড থাকলে লাগ লাগানো যাবে না — আবার ছিলুন। ক্রিম্পিং-এ আঁচড় সারে না, ওখানেই হটস্পট আর ছেঁড়ার ভয়।',
    art: '$_dir/nick.svg',
    lessonPoint: 2,
  );
  static const passEdge = DoMistake(
    key: '2.6/skin/passed-edge',
    textBn: 'ইনসুলেশনের কাটা প্রান্ত মসৃণ আর 90-ডিগ্রি কোণে হওয়া চাই — ছেঁড়া বা অসম নয়। এমন প্রান্ত আবার ছিলুন।',
    art: '$_dir/edge.svg',
    lessonPoint: 2,
  );

  /// A clean end sent back (a wrong call costs a slip).
  static const needlessRedo = DoMistake(
    key: '2.6/skin/needless-redo',
    textBn: 'এই প্রান্তটা নিখুঁত ছিল — কন্ডাক্টর মসৃণ আর উজ্জ্বল, আঁচড়, কালো দাগ বা কাটা স্ট্র্যান্ড নেই, ইনসুলেশনের প্রান্ত 90-ডিগ্রিতে মসৃণ। লেন্সে ভালো করে দেখে তবে সিদ্ধান্ত নিন।',
    art: '$_dir/clean_end.svg',
    lessonPoint: 2,
  );

  static const all = [towardBody, ringCut, noGroove, tooHard, noGloves, bluntBlade, wrongLength, passNick, passEdge, needlessRedo];

  static DoMistake passed(SkinFault f) => f == SkinFault.edge ? passEdge : passNick;
}

@immutable
class SkinDeal {
  const SkinDeal({required this.cables, required this.ends, required this.push, required this.callAt, required this.callEnd});
  final List<SkinCable> cables;

  /// The bench round's three ends.
  final List<SkinFault> ends;
  final SkinPush push;

  /// The round he comes on.
  final int callAt;

  /// On the bench: the faulty end he pushes on (-1 on a cut).
  final int callEnd;

  int get rounds => cables.length + 1;
}

/// Two cables (different lugs; a blunt blade on one of them most plays),
/// then three ends on the bench: one or two faults (never the same twice),
/// the rest clean. He pushes on a cut or on the bench's nicked end (his line
/// is the lesson's scratch myth, so a bench push always deals a nick).
SkinDeal dealSkin(math.Random rng) {
  final barrels = [52.0, 62.0, 72.0]..shuffle(rng);
  final colours = [0, 1, 2, 3]..shuffle(rng);
  final blunt = rng.nextInt(10) < 7 ? rng.nextInt(2) : -1;
  final cables = [
    for (var i = 0; i < 2; i++) SkinCable(id: 'c$i', barrel: barrels[i], blunt: i == blunt, colour: colours[i]),
  ];
  final faults = [SkinFault.nick, SkinFault.strand, SkinFault.black, SkinFault.edge]..shuffle(rng);
  final nFault = 1 + rng.nextInt(2);
  final push = rng.nextBool() ? SkinPush.cut : SkinPush.bench;
  final picked = faults.take(nFault).toList();
  if (push == SkinPush.bench && !picked.contains(SkinFault.nick)) picked[0] = SkinFault.nick;
  final ends = [...picked, for (var i = nFault; i < 3; i++) SkinFault.none]..shuffle(rng);
  return SkinDeal(
    cables: cables,
    ends: ends,
    push: push,
    callAt: push == SkinPush.cut ? rng.nextInt(2) : 2,
    callEnd: push == SkinPush.bench ? ends.indexOf(SkinFault.nick) : -1,
  );
}

/// The play state (pure logic).
class SkinRun {
  SkinRun(this.deal);
  final SkinDeal deal;
  int index = 0;

  /// Cut-resistant gloves on (for the whole play).
  bool gloves = false;
  bool bladeChecked = false;
  bool bladeSwapped = false;

  /// The chalk mark, px from the end.
  double? mark;
  int depth = 0;
  int strokes = 0;
  int slips = 0;

  /// The bench: the verdict per end (true = sent back to skin again).
  final Map<int, bool> verdicts = {};

  /// Ends whose fault he tapped under the lens; taps that found nothing.
  final Set<int> spotted = {};
  int lensMisses = 0;

  /// Clean ends sent back (each a slip).
  int needless = 0;
  final List<String> caught = [];

  bool get done => index >= deal.rounds;
  bool get onBench => index == deal.cables.length;
  SkinCable get cable => deal.cables[index.clamp(0, deal.cables.length - 1)];
  bool get cutDone => depth >= kSkinDepth;
  bool get blunt => cable.blunt && !bladeSwapped;
  bool get benchDone => verdicts.length == deal.ends.length;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  /// A thorough cut (+5): the blade looked at first, and not swapped when it
  /// was sharp (a needless swap loses the bonus, so swapping every time is
  /// not a free play).
  bool get thoroughCut => bladeChecked && !(bladeSwapped && !cable.blunt);

  /// A thorough look at an end (+5): no more than one stray tap, and on a
  /// faulty end its fault tapped (blind tapping all over is not paid).
  bool thoroughEnd(int i) => lensMisses <= 1 && (deal.ends[i] == SkinFault.none || spotted.contains(i));

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  void putGloves() {
    if (!done) gloves = true;
  }

  void checkBlade() {
    if (!done && !onBench) bladeChecked = true;
  }

  void swapBlade() {
    if (done || onBench) return;
    if (cable.blunt && !bladeSwapped) _tag(SkinLines.caughtBlade);
    bladeSwapped = true;
  }

  /// The chalk mark [strip] px from the end (it can move until the first stroke).
  void setMark(double strip) {
    if (done || onBench || strokes > 0 || cutDone) return;
    mark = strip;
  }

  bool get markRight => mark != null && (mark! - cable.barrel).abs() <= kSkinMarkTol;

  /// One stroke of the knife. Returns the mistake, if any.
  DoMistake? stroke(SkinStroke way, SkinPress press) {
    if (done || onBench || cutDone) return null;
    DoMistake slip(DoMistake m) {
      slips++;
      return m;
    }

    if (way == SkinStroke.toward) return slip(SkinMistakes.towardBody);
    if (way == SkinStroke.across) return slip(SkinMistakes.ringCut);
    if (!gloves) return slip(SkinMistakes.noGloves);
    if (!markRight) return slip(SkinMistakes.wrongLength);
    if (blunt) return slip(SkinMistakes.bluntBlade);
    if (press == SkinPress.hard) return slip(SkinMistakes.tooHard);
    if (strokes == 0 && press != SkinPress.light) return slip(SkinMistakes.noGroove);
    strokes++;
    depth = math.min(kSkinDepth, depth + (press == SkinPress.light ? 1 : 2));
    if (cutDone) {
      _tag(SkinLines.caughtAway);
      _tag(SkinLines.caughtGroove);
      _tag(SkinLines.caughtMark);
      _tag(SkinLines.caughtGloves);
    }
    return null;
  }

  /// After a slip on a cut: the end is cut back and skinned again.
  void redoCut() {
    mark = null;
    depth = 0;
    strokes = 0;
    bladeChecked = false;
  }

  /// A tap under the lens on end [i]: [onFault] when it hit the fault.
  void spot(int i, {required bool onFault}) {
    if (!onBench || verdicts.containsKey(i)) return;
    if (onFault && deal.ends[i] != SkinFault.none) {
      spotted.add(i);
    } else {
      lensMisses++;
    }
  }

  /// The verdict on end [i]. Sending a clean end back is a slip (a wrong
  /// call; the end is then skinned again — see [needless]). Passing a faulty
  /// end is a slip (the end is then sent back).
  DoMistake? judge(int i, {required bool redo}) {
    if (!onBench || verdicts.containsKey(i)) return null;
    final f = deal.ends[i];
    if (redo && f == SkinFault.none) {
      needless++;
      slips++;
      verdicts[i] = true;
      return SkinMistakes.needlessRedo;
    }
    verdicts[i] = f != SkinFault.none;
    if (!redo && f != SkinFault.none) {
      slips++;
      return SkinMistakes.passed(f);
    }
    _tag(SkinLines.caughtFault(f));
    return null;
  }

  void next() {
    index++;
    mark = null;
    depth = 0;
    strokes = 0;
    bladeChecked = false;
    bladeSwapped = false;
    lensMisses = 0;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// A thorough cut (ms; ~1500 human reaction per action): gloves (once) 1500,
/// blade: open 1500, look 1500, close 1000; mark 2000; pressure 1500;
/// two strokes 3000; the sleeve 900; reason (praise ~1500 + 650 + deck 910 +
/// read 2000 + pick 1500 + ~1200 + 450) 8210 → ≈ 20500 × 2 = 41000.
/// The bench: per end open 1500, look and tap 2500, verdict 1500, reason
/// 8210 → 13710 × 3 = 41130. The coworker once ≈ 9600. ≈ 91700; 85 % ≈ 78000
/// → 80 s.
const kSkinQuickMs = 80000;

@immutable
class M2SkinCutPack {
  const M2SkinCutPack({required this.id, required this.titleBn, this.quickMs = kSkinQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2SkinCutPacks = {
  'do_2_6_b': M2SkinCutPack(id: 'do_2_6_b', titleBn: SkinLines.title),
};

/// A stroke from [from] to [to] (design px): which way it went, or null when
/// it was too short to be a stroke.
SkinStroke? skinStrokeOf(Offset from, Offset to) {
  final d = to - from;
  if (d.distance < 26) return null;
  if (d.dy.abs() > d.dx.abs()) return SkinStroke.across;
  return d.dx > 0 ? SkinStroke.away : SkinStroke.toward;
}

// ============================================================================
// Page
// ============================================================================

class M2SkinCutPage extends StatefulWidget {
  const M2SkinCutPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2SkinCutPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2SkinCutPage> createState() => _M2SkinCutPageState();
}

class _M2SkinCutPageState extends State<M2SkinCutPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SkinRunPage(
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

class _SkinRunPage extends ConsumerStatefulWidget {
  const _SkinRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2SkinCutPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SkinRunPage> createState() => _SkinRunPageState();
}

class _SkinRunPageState extends ConsumerState<_SkinRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final SkinRun _run = SkinRun(dealSkin(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The cut sleeve sliding off (0 → 1).
  late final AnimationController _peel = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

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
  var _coworkerArmed = false;

  /// Not preset: the player picks it for each cable.
  SkinPress? _press;

  /// Gesture hints (how to touch, never what).
  final _hints = IdleHintController();
  final _glovesKey = GlobalKey(debugLabel: 'skin-gloves');
  final _bladeKey = GlobalKey(debugLabel: 'skin-blade');
  final _pressKeys = [for (final p in SkinPress.values) GlobalKey(debugLabel: 'skin-press-${p.name}')];
  final _cableKey = GlobalKey(debugLabel: 'skin-cable');
  final _endKeys = [for (var i = 0; i < 3; i++) GlobalKey(debugLabel: 'skin-end-$i')];
  final _lensKey = GlobalKey(debugLabel: 'skin-lens');
  final _passKey = GlobalKey(debugLabel: 'skin-pass');
  final _redoKey = GlobalKey(debugLabel: 'skin-redo');
  final _newBladeKey = GlobalKey(debugLabel: 'skin-new-blade');
  final _keepBladeKey = GlobalKey(debugLabel: 'skin-keep-blade');

  /// The knife in the hand while a stroke is drawn (design px), or null.
  Offset? _dragFrom;
  Offset? _dragAt;

  /// The blade close-up is open.
  var _bladeOpen = false;

  /// The bench end under the lens (-1: none); taps in the lens.
  int _lens = -1;
  final List<(int, Offset)> _lensTaps = [];
  int _lensTapN = 0;

  /// The knife slipped towards him: the hurt flash.
  var _hurt = false;
  int _hurtN = 0;

  /// The round a stamp is showing for.
  int _stampFor = -1;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _peel.dispose();
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

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  String get _ask => _run.onBench ? SkinLines.askBench : SkinLines.askCut;

  void _startRound() {
    setState(() {
      _wake++;
      _lens = -1;
      _lensTaps.clear();
      _bladeOpen = false;
      _stampFor = -1;
      _press = null;
    });
    _peel.value = 0;
    if (!_coworkerArmed && _run.index == _run.deal.callAt && _run.deal.push == SkinPush.cut) {
      _coworkerArmed = true;
      scheduleCoworker();
    }
    unawaited(_sayChain([_ask]));
  }

  /// Hands on: not in a praise window or a deck ([tableBusy]), a card, his
  /// moment, the blade close-up, the hurt or the peel.
  bool get _canPlay =>
      !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_bladeOpen && !_hurt && !_peel.isAnimating && !struckOut;

  /// The lens takes taps and verdicts.
  bool get _lensLive => _lens >= 0 && !_ended && _card == null && !tableBusy && !coworkerOpen && !struckOut;

  bool get _cutting => _canPlay && !_run.onBench && !_run.cutDone && !_run.done;

  // --- hands on: the cut ----------------------------------------------------------
  void _putGloves() {
    if (!_cutting || _run.gloves) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.4);
    setState(() {
      _run.putGloves();
      _wake++;
    });
  }

  void _openBlade() {
    if (!_cutting) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.45);
    setState(() {
      _run.checkBlade();
      _bladeOpen = true;
    });
  }

  void _swapBlade() {
    if (!_bladeOpen || _ended) return;
    _cue('sounds/intro/click.ogg', volume: 0.6);
    HapticFeedback.lightImpact();
    setState(() {
      _run.swapBlade();
      _bladeOpen = false;
      _wake++;
    });
  }

  void _closeBlade() {
    if (!_bladeOpen) return;
    _cue('sounds/intro/click.ogg', volume: 0.4);
    setState(() => _bladeOpen = false);
  }

  void _setPress(SkinPress p) {
    if (!_cutting) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.45);
    setState(() => _press = p);
  }

  void _tapScene(Offset p, SkinGeo geo) {
    if (!_canPlay || _run.done) return;
    if (_run.onBench) {
      for (var i = 0; i < _run.deal.ends.length; i++) {
        if (geo.endRect(i).contains(p) && !_run.verdicts.containsKey(i)) {
          _openLens(i);
          return;
        }
      }
      _hints.missTap();
      return;
    }
    if (_run.cutDone) return;
    if (_run.strokes > 0 || !geo.cableRect.contains(p)) {
      _hints.missTap();
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    setState(() {
      _run.setMark((SkinGeo.endX - p.dx).clamp(16.0, 240.0));
      _wake++;
    });
  }

  bool _strokeStarts(Offset p, SkinGeo geo) {
    if (!geo.cableRect.contains(p)) return false;
    final m = _run.mark;
    final left = m == null ? SkinGeo.endX - 170 : SkinGeo.endX - m - 26;
    return p.dx >= left;
  }

  void _panStart(Offset p, SkinGeo geo) {
    if (!_cutting || !_strokeStarts(p, geo)) return;
    setState(() {
      _dragFrom = p;
      _dragAt = p;
    });
  }

  void _panUpdate(Offset p) {
    if (_dragFrom == null) return;
    setState(() => _dragAt = p);
  }

  void _panEnd() {
    final from = _dragFrom;
    final to = _dragAt;
    setState(() {
      _dragFrom = null;
      _dragAt = null;
    });
    if (from == null || to == null || !_cutting) return;
    final way = skinStrokeOf(from, to);
    if (way == null) return;
    if (way == SkinStroke.away) {
      // No pressure picked yet: the knife waits (the task again, no answer).
      if (_press == null) {
        HapticFeedback.selectionClick();
        unawaited(_sayChain([SkinLines.askPress]));
        return;
      }
      // On his cut he has seen a stroke away: the next one waits for him.
      if (_run.strokes > 0 && holdForCoworker()) return;
    }
    unawaited(_commitStroke(way, Offset(SkinGeo.endX, 400)));
  }

  Future<void> _commitStroke(SkinStroke way, Offset origin) async {
    _hush();
    // Direction mistakes come before the pressure (any pressure will do).
    final m = _run.stroke(way, _press ?? SkinPress.light);
    if (m != null) {
      setState(() {});
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      if (m == SkinMistakes.towardBody) await _hurtFlash();
      if (!mounted || _ended) return;
      await _slip(m);
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.45);
    setState(() => _wake++);
    if (!_run.cutDone) return;
    // Through: the sleeve comes off, the copper shines.
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    if (_quiet) {
      _peel.value = 1;
    } else {
      await _peel.forward(from: 0);
    }
    if (!mounted || _ended) return;
    setState(() {
      _stampFor = _run.index;
      _wake++;
    });
    putOnTable(15 + (_run.thoroughCut ? 5 : 0));
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(SkinLines.cutWhy, SkinLines.cutMyths, widget.rng),
      question: SkinLines.whyCut[idx % SkinLines.whyCut.length],
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  Future<void> _hurtFlash() async {
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg', volume: 0.8);
    setState(() {
      _hurt = true;
      _hurtN++;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 1000));
    if (mounted) setState(() => _hurt = false);
  }

  // --- hands on: the bench ----------------------------------------------------------
  void _openLens(int i) {
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.45);
    setState(() {
      _lens = i;
      _lensTaps.clear();
    });
    if (!_coworkerArmed && _run.deal.push == SkinPush.bench && i == _run.deal.callEnd) {
      _coworkerArmed = true;
      scheduleCoworker();
    }
  }

  void _closeLens() {
    if (!_lensLive) return;
    _cue('sounds/intro/click.ogg', volume: 0.4);
    setState(() {
      _lens = -1;
      _lensTaps.clear();
    });
  }

  void _tapLens(Offset p, Size size) {
    if (!_lensLive) return;
    final f = _run.deal.ends[_lens];
    _run.spot(_lens, onFault: f != SkinFault.none && skinFaultRect(f, size).inflate(8).contains(p));
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.45);
    setState(() {
      _lensTaps.add((_lensTapN++, p));
      if (_lensTaps.length > 4) _lensTaps.removeAt(0);
    });
  }

  Future<void> _verdict(bool redo, Offset origin) async {
    if (!_lensLive) return;
    final i = _lens;
    // His end: the verdict (either way) waits for him.
    if (_run.deal.push == SkinPush.bench && i == _run.deal.callEnd && holdForCoworker()) return;
    await _commitVerdict(i, redo, origin);
  }

  Future<void> _commitVerdict(int i, bool redo, Offset origin) async {
    if (_ended || _run.verdicts.containsKey(i)) return;
    _hush();
    final m = _run.judge(i, redo: redo);
    if (m != null) {
      setState(() {
        _lens = -1;
        _lensTaps.clear();
        _run.lensMisses = 0;
      });
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    final f = _run.deal.ends[i];
    putOnTable(10 + (_run.thoroughEnd(i) ? 5 : 0));
    setState(() {
      _lens = -1;
      _lensTaps.clear();
      _run.lensMisses = 0;
      _wake++;
    });
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(SkinLines.faultWhy(f), f == SkinFault.none ? SkinLines.passMyths : SkinLines.redoExcuses, widget.rng),
      question: f == SkinFault.none ? SkinLines.whyPass : SkinLines.whyRedo,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
    if (_run.onBench && !_run.benchDone) {
      unawaited(_sayChain([SkinLines.askBench]));
      return;
    }
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 900), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _run.deal.push == SkinPush.cut ? SkinLines.coworkerCut : SkinLines.coworkerBench;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.done || _run.index != _run.deal.callAt) return null;
    if (_run.deal.push == SkinPush.cut) {
      // "উল্টো দিকে কেন?" fits only mid-cut, after a stroke away.
      if (_run.onBench || _run.cutDone) return null;
      if (_intro || tableBusy || _card != null || _bladeOpen || _hurt || _dragFrom != null || _run.strokes == 0) return false;
      return true;
    }
    // His scratch myth fits only the nicked end, under the lens, undecided.
    if (_run.verdicts.containsKey(_run.deal.callEnd)) return null;
    if (tableBusy || _card != null || _lens != _run.deal.callEnd) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!mounted || _ended) return;
    final cut = _run.deal.push == SkinPush.cut;
    if (!held) {
      if (cut) {
        await _commitStroke(SkinStroke.toward, origin);
      } else {
        await _commitVerdict(_run.deal.callEnd, false, origin);
      }
      return;
    }
    _run.caught.add(SkinLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    if (!cut) await _commitVerdict(_run.deal.callEnd, true, origin);
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? SkinLines.tapWhy[_nudgeN++ % SkinLines.tapWhy.length]
            : _nudge.next(_ask);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
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
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('skin/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    final onBench = _run.onBench;
    setState(() {
      _card = null;
      if (!onBench) _run.redoCut();
      _wake++;
    });
    if (onBench) {
      if (_run.benchDone) {
        _next();
      } else {
        unawaited(_sayChain([SkinLines.askBench]));
      }
    } else {
      unawaited(_sayChain([SkinLines.redoLine]));
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
    await _say(!_run.passed ? SkinLines.fail : (_quickBonus ? SkinLines.quick : SkinLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- gesture hints (how to touch, never what) ---------------------------------
  /// The level waits for the player's hands now (no intro, card, deck, his
  /// moment, hurt, peel, praise window or result).
  bool get _hintWaiting {
    if (_intro || _ended || struckOut || _mark != null || _run.done || _card != null) return false;
    if (tableBusy || coworkerOnScreen || coworkerHeld || _hurt || _peel.isAnimating || _dragFrom != null) return false;
    if (_bladeOpen || _lens >= 0 || _run.onBench) return true;
    return !_run.cutDone;
  }

  Object get _hintKey => (_run.index, _lens, _bladeOpen, _run.verdicts.length);

  /// The blade card's two buttons in a dealt order (keep first when true).
  bool get _bladeFlip => _run.cable.colour >= 2;

  /// The lens card's two verdicts in a dealt order (redo first when true).
  bool get _verdictFlip => (_lens + _run.deal.cables[1].colour).isOdd;

  /// Blade close-up: a sweep over both buttons. Lens: a sweep over the lens
  /// and both verdicts. Bench: a sweep over the ends still to judge (a tap
  /// when one is left: opening it is the one way on, not a verdict). The cut:
  /// a sweep over the tools, the pressure and the cable — no drag nudge, as
  /// any direction on the cable would be an answer.
  HintSpec? _hint() {
    if (_bladeOpen) return HintSpec.sweepOver(_bladeFlip ? [_keepBladeKey, _newBladeKey] : [_newBladeKey, _keepBladeKey]);
    if (_lens >= 0) return HintSpec.sweepOver([_lensKey, if (_verdictFlip) ...[_redoKey, _passKey] else ...[_passKey, _redoKey]]);
    if (_run.onBench) {
      final open = [
        for (var i = 0; i < _run.deal.ends.length; i++)
          if (!_run.verdicts.containsKey(i)) _endKeys[i],
      ];
      if (open.isEmpty) return null;
      return open.length == 1 ? HintSpec.tapOn(open.single) : HintSpec.sweepOver(open);
    }
    final toolsFlip = _run.deal.cables[0].colour.isOdd;
    return HintSpec.sweepOver([
      if (toolsFlip) ...[_bladeKey, _glovesKey] else ...[_glovesKey, _bladeKey],
      ..._pressKeys,
      _cableKey,
    ]);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_hurt || _card != null) return LinemanMode.worried;
    if (coworkerOpen || coworkerHeld) return LinemanMode.worried;
    if (_stampFor == _run.index) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = SkinGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final bench = _run.onBench || _run.done;
    final cable = _run.cable;
    final knifeAt = _dragAt == null ? Offset(SkinGeo.endX - 96, geo.cableY + 26) : Offset(_dragAt!.dx, _dragAt!.dy.clamp(geo.cableY - 40, geo.cableY + 40));
    return [
      Positioned.fill(
        key: const ValueKey('yard'),
        child: RepaintBoundary(child: CustomPaint(painter: SkinYardPainter(geo: geo))),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.traineeBox,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      // His cut-resistant gloves: a grey knit cuff on each hand.
      if (_run.gloves)
        Positioned(
          key: const ValueKey('gloves-on'),
          left: geo.traineeBox.left + geo.traineeBox.width * 0.62,
          top: geo.traineeBox.top + geo.traineeBox.height * 0.44,
          width: 22,
          height: 22,
          child: const IgnorePointer(child: CustomPaint(painter: _KnitGlovePainter())),
        ),
      if (!bench)
        Positioned.fill(
          key: ValueKey('cable-${_run.index}'),
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _peel,
              builder: (_, _) => CustomPaint(
                painter: SkinCablePainter(
                  geo: geo,
                  barrel: cable.barrel,
                  mark: _run.mark,
                  depth: _run.depth,
                  peel: _run.cutDone ? _peel.value : 0,
                  insulation: kSkinColours[cable.colour],
                ),
              ),
            ),
          ),
        ),
      if (!bench && !_run.cutDone)
        Positioned.fill(
          key: const ValueKey('knife'),
          // From afar every blade looks alike: a blunt one shows only in the
          // close-up (no giveaway on the scene).
          child: IgnorePointer(child: CustomPaint(painter: SkinKnifePainter(at: knifeAt, blunt: false, angle: _dragAt == null ? -0.1 : -0.18))),
        ),
      // Hint anchors (no paint, no touch): the cable and the bench ends.
      if (!bench && !_run.cutDone)
        Positioned.fromRect(
          key: const ValueKey('cable-anchor'),
          rect: geo.cableRect,
          child: IgnorePointer(child: SizedBox.expand(key: _cableKey)),
        ),
      if (bench)
        for (var i = 0; i < _run.deal.ends.length; i++)
          Positioned.fromRect(
            key: ValueKey('end-anchor-$i'),
            rect: geo.endRect(i),
            child: IgnorePointer(child: SizedBox.expand(key: _endKeys[i])),
          ),
      if (bench)
        Positioned.fill(
          key: const ValueKey('bench'),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: SkinBenchPainter(geo: geo, faults: _run.deal.ends, colours: [for (final c in [2, 0, 1]) kSkinColours[c]]),
            ),
          ),
        ),
      if (bench)
        for (final e in _run.verdicts.entries)
          Positioned(
            key: ValueKey('end-stamp-${e.key}'),
            left: SkinGeo.endRight - 4,
            top: geo.endRowY(e.key) - 12,
            child: IgnorePointer(child: _MiniStamp(text: e.value ? SkinLines.stampRedo : SkinLines.stampPass, good: !e.value, quiet: quiet)),
          ),
      if (!bench && _stampFor == _run.index)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: SkinGeo.endX - 150,
          top: geo.cableY - 82,
          child: IgnorePointer(child: _MiniStamp(text: SkinLines.stampDone, good: true, quiet: quiet, big: true)),
        ),
      // The hurt: a red flash at his hand and a cry.
      if (_hurt)
        Positioned(
          key: ValueKey('hurt-$_hurtN'),
          left: geo.traineeBox.left + 20,
          top: geo.traineeBox.top + geo.traineeBox.height * 0.3,
          width: 120,
          height: 120,
          child: IgnorePointer(child: _HurtFlash(quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: SkinLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The stroke starts where the finger went down (not after the slop).
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: () => setState(() {
              _dragFrom = null;
              _dragAt = null;
            }),
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
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.done && !_run.onBench && !_run.cutDone && !deckUp && !coworkerOpen && _card == null && !_bladeOpen && !coworkerHeld;
    final lensUp = playing && _lens >= 0 && _card == null;
    final glovesBtn = KeyedSubtree(
      key: _glovesKey,
      child: _ToolButton(icon: Icons.back_hand_rounded, label: SkinLines.gloves, on: _run.gloves, onTap: _putGloves),
    );
    final bladeBtn = KeyedSubtree(
      key: _bladeKey,
      child: _ToolButton(icon: Icons.content_cut_rounded, label: SkinLines.blade, on: _run.bladeChecked, onTap: _openBlade),
    );
    // The two tools in a dealt order (no row in the order of the steps).
    final toolsFlip = _run.deal.cables[0].colour.isOdd;
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
              labels: SkinLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 10,
                  bottom: pad.bottom + 76,
                  child: Row(
                    children: [
                      if (toolsFlip) bladeBtn else glovesBtn,
                      const SizedBox(width: 6),
                      if (toolsFlip) glovesBtn else bladeBtn,
                    ],
                  ),
                ),
                Positioned(
                  key: const ValueKey('hud-press'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: _PressBar(value: _press, onPick: _setPress, keys: _pressKeys),
                ),
              ],
              if (lensUp)
                _LensCard(
                  key: ValueKey('lens-$_lens'),
                  fault: _run.deal.ends[_lens],
                  colour: kSkinColours[const [2, 0, 1][_lens]],
                  taps: _lensTaps,
                  quiet: quiet,
                  enabled: _lensLive,
                  lensKey: _lensKey,
                  passKey: _passKey,
                  redoKey: _redoKey,
                  flip: _verdictFlip,
                  onTap: _tapLens,
                  onPass: (d) => unawaited(_verdict(false, d.globalPosition)),
                  onRedo: (d) => unawaited(_verdict(true, d.globalPosition)),
                  onClose: _closeLens,
                ),
              if (_bladeOpen && playing)
                _BladeCard(
                  key: const ValueKey('blade'),
                  blunt: _run.blunt,
                  quiet: quiet,
                  swapKey: _newBladeKey,
                  keepKey: _keepBladeKey,
                  flip: _bladeFlip,
                  onSwap: _swapBlade,
                  onClose: _closeBlade,
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
              if (playing && _card == null && !_bladeOpen && !lensUp)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 76), onLeft: coworkerFromRight),
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
                  line: SkinLines.intro,
                  alarm: 'sounds/intro/impact_metal.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _clock.start();
                    _startRound();
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
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

/// A grey knit cut-resistant glove on his hand.
class _KnitGlovePainter extends CustomPainter {
  const _KnitGlovePainter();

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final mitt = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.2, w * 0.7, h * 0.7), Radius.circular(w * 0.3));
    c.drawRRect(mitt, Paint()..color = const Color(0xFFB9C0C7));
    c.drawRRect(mitt, Paint()
      ..color = const Color(0xFF59626B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    final knit = Paint()
      ..color = const Color(0x6659626B)
      ..strokeWidth = 0.8;
    for (var i = 1; i < 5; i++) {
      c.drawLine(Offset(w * 0.2, h * (0.2 + i * 0.14)), Offset(w * 0.8, h * (0.2 + i * 0.14)), knit);
    }
    c.drawRect(Rect.fromLTWH(w * 0.22, 0, w * 0.56, h * 0.24), Paint()..color = const Color(0xFF3A4A8A));
  }

  @override
  bool shouldRepaint(_KnitGlovePainter old) => false;
}

/// The pressure lever: হালকা · মাঝারি · জোরে.
class _PressBar extends StatelessWidget {
  const _PressBar({required this.value, required this.onPick, required this.keys});

  /// Null: none picked yet.
  final SkinPress? value;
  final ValueChanged<SkinPress> onPick;

  /// One per segment (gesture-hint anchors).
  final List<GlobalKey> keys;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xE60B1324),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.6), width: 1.4),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(SkinLines.press, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
          ),
          for (final p in SkinPress.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: p == value,
                label: SkinLines.pressBn(p),
                excludeSemantics: true,
                child: GestureDetector(
                  key: keys[p.index],
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPick(p),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p == value ? SlmColors.gold400 : const Color(0x00000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(SkinLines.pressBn(p),
                        style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: p == value ? const Color(0xFF2B1D00) : SlmColors.ivory)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit once used.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sheet that rises over the scene (the blade close-up, the lens).
class _RiseCard extends StatelessWidget {
  const _RiseCard({required this.quiet, required this.child});
  final bool quiet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Transform.translate(offset: Offset(0, 50 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: c)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xF20B1324),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.5), width: 1.4),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: child,
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.filled, required this.onTapUp});
  final String label;
  final bool filled;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) => DoBigButton(label: label, filled: filled, onTapUp: onTapUp, onDark: true);
}

/// The blade close-up: sharp and clean, or blunt; swap it or put it back.
class _BladeCard extends StatelessWidget {
  const _BladeCard({
    super.key,
    required this.blunt,
    required this.quiet,
    required this.swapKey,
    required this.keepKey,
    required this.flip,
    required this.onSwap,
    required this.onClose,
  });
  final bool blunt;
  final bool quiet;
  final GlobalKey swapKey;
  final GlobalKey keepKey;

  /// Keep first (a dealt order; both buttons look the same).
  final bool flip;
  final VoidCallback onSwap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final swap = Expanded(child: KeyedSubtree(key: swapKey, child: _CardButton(label: SkinLines.newBlade, filled: false, onTapUp: (_) => onSwap())));
    final keep = Expanded(child: KeyedSubtree(key: keepKey, child: _CardButton(label: SkinLines.keepBlade, filled: false, onTapUp: (_) => onClose())));
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x66050A16),
        child: Center(
          child: _RiseCard(
            quiet: quiet,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 296, height: 140, child: CustomPaint(painter: SkinBladePainter(blunt: blunt))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (flip) keep else swap,
                    const SizedBox(width: 8),
                    if (flip) swap else keep,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bench end under the lens: tap where you see a fault (every tap the same
/// plain mark), then চলবে or আবার ছিলতে হবে.
class _LensCard extends StatelessWidget {
  const _LensCard({
    super.key,
    required this.fault,
    required this.colour,
    required this.taps,
    required this.quiet,
    required this.enabled,
    required this.lensKey,
    required this.passKey,
    required this.redoKey,
    required this.flip,
    required this.onTap,
    required this.onPass,
    required this.onRedo,
    required this.onClose,
  });

  /// Redo first (a dealt order; both verdicts look the same).
  final bool flip;
  final SkinFault fault;
  final Color colour;
  final List<(int, Offset)> taps;
  final bool quiet;
  final bool enabled;
  final GlobalKey lensKey;
  final GlobalKey passKey;
  final GlobalKey redoKey;
  final void Function(Offset p, Size size) onTap;
  final GestureTapUpCallback onPass;
  final GestureTapUpCallback onRedo;
  final VoidCallback onClose;

  static const lensSize = Size(296, 150);

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final pass = Expanded(child: KeyedSubtree(key: passKey, child: _CardButton(label: SkinLines.pass, filled: false, onTapUp: onPass)));
    final redo = Expanded(child: KeyedSubtree(key: redoKey, child: _CardButton(label: SkinLines.redo, filled: false, onTapUp: onRedo)));
    return Positioned(
      left: 0,
      right: 0,
      top: pad.top + 120,
      child: Center(
        child: _RiseCard(
          quiet: quiet,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: SkinLines.lensLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: enabled ? (d) => onTap(d.localPosition, lensSize) : null,
                  child: SizedBox.fromSize(
                    key: lensKey,
                    size: lensSize,
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: SkinLensPainter(fault: fault, colour: colour))),
                        for (final (id, p) in taps)
                          Positioned(
                            key: ValueKey('lens-tap-$id'),
                            left: p.dx - 14,
                            top: p.dy - 14,
                            width: 28,
                            height: 28,
                            child: const IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0x22FFFFFF),
                                  border: Border.fromBorderSide(BorderSide(color: Color(0xDDFFFFFF), width: 2)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (flip) redo else pass,
                  const SizedBox(width: 8),
                  if (flip) pass else redo,
                ],
              ),
              const SizedBox(height: 4),
              Semantics(
                button: true,
                label: SkinLines.lensClose,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: SizedBox(
                    height: 40,
                    child: Center(child: Text(SkinLines.lensClose, style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: SlmColors.ivory.withValues(alpha: 0.8)))),
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

class _MiniStamp extends StatelessWidget {
  const _MiniStamp({required this.text, required this.good, required this.quiet, this.big = false});
  final String text;
  final bool good;
  final bool quiet;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final col = good ? SlmColors.success : SlmColors.warning;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: big ? 12 : 6, vertical: big ? 6 : 2),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: col, width: big ? 3 : 2),
        ),
        child: Text(text, style: bangla(fontSize: big ? 19 : 12, fontWeight: FontWeight.w900, color: col)),
      ),
    );
  }
}

/// The knife slipped towards him: a red flash at his hand and a cry
/// (non-graphic).
class _HurtFlash extends StatelessWidget {
  const _HurtFlash({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (_, v, _) => Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: (1 - v * 0.6).clamp(0.0, 1.0),
            child: Container(
              width: 60 + 50 * v,
              height: 60 + 50 * v,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0xCCE53935), Color(0x00E53935)]),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(18, -30 - 10 * v),
            child: Text(SkinLines.ouch,
                style: bangla(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)
                    .copyWith(shadows: const [Shadow(color: Color(0xCC8B0000), blurRadius: 6, offset: Offset(0, 2))])),
          ),
        ],
      ),
    );
  }
}
