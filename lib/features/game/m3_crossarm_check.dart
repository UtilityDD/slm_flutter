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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm3_crossarm_check_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_crossarm_check_world.dart' show M3CrossarmBoltLook, M3CrossarmFault, M3CrossarmGeo, M3CrossarmPart;

// Lesson 3.3 "ক্রস-আর্ম ও ক্ল্যাম্প: লাইনের কঙ্কাল", কাজ 2 "কঙ্কালের
// স্বাস্থ্য" (pack do_3_3_b). The line is shut down and earthed; three PCC
// poles a play, each dealt fresh. At each pole:
//   1. From the ground (point 1's daily check: "পোলে ওঠার আগে নিচ থেকে দেখুন
//      ক্রস-আর্মটি বেঁকে, মুচড়ে বা হেলে গেছে কিনা। মরিচার পরিমাণ পরীক্ষা
//      করুন।"): tap the arm, the clamp, the brace to look close. The faults
//      are point 4's: a rusty arm, a bent arm, a clamp slipped down the pole,
//      and rust on the clamp (point 2: a rusty nut-bolt weakens the whole
//      structure). In the wind a loose nut chatters (pro tip 1, film S4_04).
//   2. Decide: report (the arm/clamp must be changed — do not climb) or climb.
//   3. Up the pole (close view): tap each bolt to try it with the spanner (a
//      loose one turns), fit a spring washer where it is missing (pro tip 4),
//      tighten with the right torque (pro tip 2: hold the wrench, let go in
//      the band — too much snaps the bolt, too little leaves it loose), then
//      "কাজ শেষ".
//
// Deadly (point 4's safety tip; film S4_03 "মরিচা ধরা বা বাঁকা ক্রস-আর্মে
// কখনো দাঁড়াবেন না বা হারনেস আটকাবেন না"): climbing onto a rusty or bent arm
// — also on the coworker's say-so ("একটু হেলে আছে, চলবে!"). Slips: climbing
// to a slipped or rusty clamp, climbing without looking from below, a bolt
// left untried, a loose nut left, a nut left without a spring washer,
// over-tightening (the bolt snaps), a report on a sound pole (a needless
// stop), a report before arm and clamp were looked at (a guess). A report is
// a decision: a wrong one costs a slip and the pole ends — no free probe, and
// the guide never says before the decision whether the pole is sound. Three
// slips strike out.
//
// The careless coworker comes once a play, on the rusty/bent-arm pole, right
// after the player has looked at the arm; report and climb wait for him
// (holdForCoworker), so a fast player cannot skip him.
//
// Flagged to the owner: the shutdown + earth set on the line is the project's
// line-work rule (BRIEF_M34), not lesson 3.3's text; a slipped or rusty clamp
// is a slip, not deadly (the lesson names only the rusty arm for standing and
// anchoring; the film adds the bent arm); the torque band has no number (the
// lesson gives no torque values); three bolts at the joint (two clamp bolts,
// one brace bolt) is ours.

// ============================================================================
// Content
// ============================================================================

/// A bolt as dealt.
@immutable
class M3CrossarmBoltSpec {
  const M3CrossarmBoltSpec({this.loose = false, this.washer = true});
  final bool loose;
  final bool washer;

  bool get ok => !loose && washer;
}

const _ok = M3CrossarmBoltSpec();
const _loose = M3CrossarmBoltSpec(loose: true);
const _bare = M3CrossarmBoltSpec(washer: false);
const _both = M3CrossarmBoltSpec(loose: true, washer: false);

@immutable
class M3CrossarmPole {
  const M3CrossarmPole({required this.id, required this.fault, this.bolts = const [_ok, _ok, _ok]});
  final String id;
  final M3CrossarmFault fault;

  /// The two clamp bolts and the brace bolt (only reached on a sound pole).
  final List<M3CrossarmBoltSpec> bolts;

  bool get report => fault != M3CrossarmFault.none;

  /// Standing on / anchoring to this arm kills (point 4's safety tip).
  bool get deadly => fault == M3CrossarmFault.rustArm || fault == M3CrossarmFault.bentArm;

  /// The part that shows the fault from the ground.
  M3CrossarmPart? get faultPart => switch (fault) {
        M3CrossarmFault.none => null,
        M3CrossarmFault.rustArm || M3CrossarmFault.bentArm => M3CrossarmPart.arm,
        M3CrossarmFault.slippedClamp || M3CrossarmFault.rustClamp => M3CrossarmPart.clamp,
      };

  /// A loose nut chatters in the wind (pro tip 1); so does a slipping clamp
  /// (film S4_04).
  bool get rattles => fault == M3CrossarmFault.slippedClamp || (!report && bolts.any((b) => b.loose));
}

/// The part the eye must have been on before climbing (point 1's daily check:
/// the arm; point 4: the clamp slipping).
const m3CrossarmMustLook = {M3CrossarmPart.arm, M3CrossarmPart.clamp};

/// The torque band on the wrench's dial (0–1 of the sweep). No number: the
/// lesson gives no torque values.
const kM3CrossarmTorqueLo = 0.58;
const kM3CrossarmTorqueHi = 0.80;

/// A full sweep of the dial while held (ms).
const kM3CrossarmSweepMs = 1800;

enum M3CrossarmTorque { under, right, over }

abstract final class M3CrossarmCheckLines {
  static const title = 'কঙ্কালের স্বাস্থ্য';
  static const intro = 'শাটডাউনে লাইন আর্থ করা। তিনটে পোলের ক্রস-আর্ম আর ক্ল্যাম্প পরীক্ষা করুন!';
  static const rounds = ['ক', 'খ', 'গ'];
  static const askGround = 'ওঠার আগে নিচ থেকে দেখুন — ক্রস-আর্ম আর ক্ল্যাম্প ঠিক আছে?';
  static const askUp = 'প্রতিটা নাট-বল্টু পরখ করুন, দরকারে ঠিক করুন।';

  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askGround, askUp];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'পোল, ক্রস-আর্ম আর ক্ল্যাম্প';
  static const upLabel = 'ক্রস-আর্মের নাট-বল্টু';
  static const report = 'রিপোর্ট — উঠব না';
  static const climb = 'উঠে নাট-বল্টু দেখি';
  static const washer = 'স্প্রিং ওয়াশার';
  static const torque = 'টর্ক রেঞ্চ (চেপে ধরুন)';
  static const done = 'কাজ শেষ — নামি';
  static String partBn(M3CrossarmPart p) => switch (p) {
        M3CrossarmPart.arm => 'ক্রস-আর্ম',
        M3CrossarmPart.clamp => 'ক্ল্যাম্প',
        M3CrossarmPart.brace => 'ব্রেস',
      };

  static const stampReport = 'রিপোর্ট — বদলাতে হবে';
  static const stampDone = 'কঙ্কাল ঠিক আছে';

  // The reasons: the right ones fit what this pole was; the wrong ones are
  // bad motives (to report) or the lesson's myths (to climb).
  static const whyReport = 'কেন রিপোর্ট করলেন?';
  static const whyDone = 'কেন নিশ্চিন্তে নামলেন?';
  static const rustWhy = ['মরিচা ধরা ক্রস-আর্মে দাঁড়ানো বা হারনেস নয়', 'মরিচা ভেতর থেকে আর্মের শক্তি খেয়ে ফেলে'];
  static const bentWhy = ['আর্ম বেঁকে গেছে, ফেজ ক্লিয়ারেন্সও কমে গেছে', 'বাঁকা ক্রস-আর্মে দাঁড়ানো বা হারনেস নয়'];
  static const slipWhy = ['ক্ল্যাম্প পিছলে নেমেছে, আর্ম ঠিক ধরা নেই', 'ক্ল্যাম্প পোল বরাবর নেমে গেছে, আর্ম আলগা'];
  static const rustClampWhy = ['মরিচা ধরা ক্ল্যাম্প পুরো কাঠামো দুর্বল করে', 'ক্ল্যাম্পে মরিচা, আর্ম ধরে রাখার জোর কম'];
  // The wrong ones name the arm, the clamp, rust and the harness too, so the
  // right card is not the only one about the structure.
  static const reportExcuses = [
    'উঠতে ইচ্ছে করছিল না, তাই রিপোর্ট করে দিলাম',
    'রোদ খুব বেশি, তাই আজ না উঠে রিপোর্ট করলাম',
    'মরিচা তো শুধু বাইরের স্তরে, তবু রিপোর্ট দিলাম',
    'ক্ল্যাম্প বদলালে বেশি নম্বর মেলে, তাই রিপোর্ট',
    'ব্রেসের রং পুরোনো, তাই আর্ম বদলাতে বললাম',
    'হারনেস আনিনি, তাই আর্মটা খারাপ বলে দিলাম',
    'সুপারভাইজার নেই, তাই কাজটা ফেলে রাখলাম',
    'পাশের পোলে কাজ বেশি, এটা পরে দেখা যাবে',
  ];
  static const checkedWhy = 'নিচ থেকে দেখে, সব নাট-বল্টু পরখ করে নিলাম';
  static const soundWhy = 'আর্ম সোজা, মরিচা নেই, সব নাট-বল্টু টাইট';
  static const looseWhy = 'ঢিলা নাট সঠিক টর্কে টাইট দিয়েছি, বেশি নয়';
  static const washerWhy = 'স্প্রিং ওয়াশার কম্পনে নাট আলগা হতে দেয় না';
  static const climbMyths = [
    'যত বেশি টাইট দেব, বল্টু তত মজবুত থাকবে',
    'স্প্রিং ওয়াশার না থাকলেও নাট আটকে থাকে',
    'হালকা মরিচা তো বাইরের স্তরে, ক্ষতি নেই',
    'যেকোনো ক্ল্যাম্প যেকোনো পোলে লাগানো চলে',
    'একটা নাট দেখলেই বাকিগুলোও বোঝা যায়',
    'খটখট শব্দ বাতাসের, ওতে ভয়ের কিছু নেই',
  ];

  static List<String> whyRight(M3CrossarmPole p) => switch (p.fault) {
        M3CrossarmFault.rustArm => rustWhy,
        M3CrossarmFault.bentArm => bentWhy,
        M3CrossarmFault.slippedClamp => slipWhy,
        M3CrossarmFault.rustClamp => rustClampWhy,
        M3CrossarmFault.none => [
            checkedWhy,
            if (p.bolts.every((b) => b.ok)) soundWhy,
            if (p.bolts.any((b) => b.loose)) looseWhy,
            if (p.bolts.any((b) => !b.washer)) washerWhy,
          ],
      };
  static List<String> whyWrong(M3CrossarmPole p) => p.report ? reportExcuses : climbMyths;

  /// The careless coworker: the arm is weak, he wants it climbed.
  static const _cwRight = ['না, এই আর্মে উঠব না, আগে রিপোর্ট করব', 'না, দুর্বল আর্মে ভর বা হারনেস নয়', 'উঠব না — এই আর্ম বদলাতে হবে, রিপোর্ট'];
  static const _cwAsks = ['ও বলছে উঠে পড়তে। আপনি কী করবেন?', 'এই ক্রস-আর্মে উঠবেন?', 'উঠবেন, না রিপোর্ট করবেন?'];
  static const coworkerBent = CoworkerScript(
    line: 'একটু হেলে আছে, চলবে! উঠে পড়ো, কাজটা সেরে ফেলি।',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: _cwRight,
    wrong: ['ঠিক, একটু হেলা আর্মে কাজ চলে যাবে', 'আচ্ছা, তাড়াতাড়ি উঠে কাজটা সেরে ফেলি', 'হ্যাঁ, আর্মে হারনেস আটকে উঠে পড়ি', 'ঠিক, এটুকু বাঁকায় কিছুই হবে না তো', 'চলো, রিপোর্ট না হয় পরে করলেও চলবে'],
    asks: _cwAsks,
  );
  static const coworkerRust = CoworkerScript(
    line: 'হালকা মরিচা, ও তো বাইরের স্তরে! উঠে পড়ো, চলবে।',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: _cwRight,
    wrong: ['ঠিক, বাইরের মরিচায় কিছুই হবে না', 'আচ্ছা, তাড়াতাড়ি উঠে কাজটা সেরে ফেলি', 'হ্যাঁ, আর্মে হারনেস আটকে উঠে পড়ি', 'ঠিক, হালকা মরিচায় আর্ম তো ভাঙে না', 'চলো, রিপোর্ট না হয় পরে করলেও চলবে'],
    asks: _cwAsks,
  );

  static const callHeld = 'ঠিক! দুর্বল ক্রস-আর্মে ওঠা নয় — রিপোর্ট।';
  static const allSet = 'লাইনের কঙ্কাল পরীক্ষা শিখে গেছেন — নিচ থেকে দেখা, নাট-বল্টু পরখ, সঠিক টর্ক।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে নিচ থেকে দেখুন, তারপর প্রতিটা নাট-বল্টু।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtLook = 'ওঠার আগে নিচ থেকে দেখা';
  static const caughtArm = 'দুর্বল ক্রস-আর্ম ধরে রিপোর্ট';
  static const caughtClamp = 'খারাপ ক্ল্যাম্প ধরে রিপোর্ট';
  static const caughtTorque = 'ঢিলা নাট সঠিক টর্কে টাইট';
  static const caughtWasher = 'স্প্রিং ওয়াশার লাগানো';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M3CrossarmCheckMistakes {
  static const _dir = 'assets/game/art/m3_crossarm_check';

  static const climbRust = DoMistake(
    key: '3.3/m3_crossarm_check/climb-rusty-arm',
    textBn: 'মরিচা ধরা ক্রস-আর্মে উঠলেন! মরিচা ভেতর থেকে স্টিলের শক্তি খেয়ে ফেলে — ওর ওপর দাঁড়ানো বা হারনেস আটকানো নয়, রিপোর্ট করুন।',
    art: '$_dir/climb_rust.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const climbBent = DoMistake(
    key: '3.3/m3_crossarm_check/climb-bent-arm',
    textBn: 'বাঁকা ক্রস-আর্মে উঠলেন! বেঁকে যাওয়া আর্মে ফেজ ক্লিয়ারেন্স কমে যায় — বাঁকা বা মরিচা ধরা আর্মে দাঁড়ানো বা হারনেস আটকানো নয়, রিপোর্ট করুন।',
    art: '$_dir/climb_bent.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const climbSlipped = DoMistake(
    key: '3.3/m3_crossarm_check/climb-slipped-clamp',
    textBn: 'ক্ল্যাম্প পোল বরাবর পিছলে নেমেছে — আর্ম আর শক্ত করে ধরা নেই। ওঠা নয়, রিপোর্ট করুন।',
    art: '$_dir/climb_slipped.svg',
    lessonPoint: 3,
  );
  static const climbRustClamp = DoMistake(
    key: '3.3/m3_crossarm_check/climb-rusty-clamp',
    textBn: 'ক্ল্যাম্পে মরিচা ধরেছে। মরিচা ধরা হার্ডওয়্যার পুরো কাঠামোকে দুর্বল করে — ওঠার আগে রিপোর্ট করুন।',
    art: '$_dir/climb_rust_clamp.svg',
    lessonPoint: 1,
  );
  static const noLook = DoMistake(
    key: '3.3/m3_crossarm_check/no-ground-look',
    textBn: 'নিচ থেকে না দেখেই উঠলেন। ওঠার আগে দেখুন ক্রস-আর্ম বেঁকে, মুচড়ে বা হেলে গেছে কিনা, মরিচা আর ক্ল্যাম্প কেমন।',
    art: '$_dir/no_look.svg',
    lessonPoint: 0,
  );
  static const missedBolt = DoMistake(
    key: '3.3/m3_crossarm_check/bolt-untried',
    textBn: 'সব নাট-বল্টু পরখ করেননি। কম্পনে নাট ধীরে ধীরে আলগা হয় — কাজের আগে প্রতিটা দেখুন।',
    art: '$_dir/missed_bolt.svg',
    lessonPoint: 1,
  );
  static const looseLeft = DoMistake(
    key: '3.3/m3_crossarm_check/loose-nut-left',
    textBn: 'ঢিলা নাট রেখেই নামলেন। একটা ঢিলা নাট-বল্টু পুরো কাঠামো দুর্বল করে — সঠিক টর্কে টাইট দিন।',
    art: '$_dir/loose_left.svg',
    lessonPoint: 1,
  );

  /// Pro tips (not a lesson point: "পাঠে দেখুন" opens the lesson start).
  static const noWasher = DoMistake(
    key: '3.3/m3_crossarm_check/no-spring-washer',
    textBn: 'স্প্রিং ওয়াশার ছাড়াই নাট রেখে দিলেন। কম্পনে নাট আলগা হওয়া ঠেকায় স্প্রিং ওয়াশার — আগে ওয়াশার, তারপর টাইট।',
    art: '$_dir/no_washer.svg',
  );
  static const overTorque = DoMistake(
    key: '3.3/m3_crossarm_check/over-torque',
    textBn: 'বেশি টাইট দিলেন — বল্টু ছিঁড়ে গেল। সঠিক টর্ক দিন: বেশি টাইটে বল্টু ছেঁড়ে, কম টাইটে আলগা থাকে।',
    art: '$_dir/over_torque.svg',
  );

  /// A report where the arm is straight, rust-free and the clamp in place (a
  /// needless stop). Said only after the decision.
  static const reportSound = DoMistake(
    key: '3.3/m3_crossarm_check/report-sound-pole',
    textBn: 'এই পোলে আর্ম সোজা, মরিচা নেই, ক্ল্যাম্প জায়গায় ছিল। দেখে যা পান তা-ই রিপোর্ট করুন — এমন পোলে উঠে প্রতিটা নাট-বল্টু পরখ করুন।',
    art: '$_dir/report_sound.svg',
    lessonPoint: 0,
  );

  /// A report before arm and clamp were looked at (a guess) — the same words
  /// whatever the pole was.
  static const reportUnseen = DoMistake(
    key: '3.3/m3_crossarm_check/report-unseen',
    textBn: 'নিচ থেকে ভালো করে না দেখেই রিপোর্ট করলেন। আগে দেখুন ক্রস-আর্ম বেঁকে, মুচড়ে বা হেলে গেছে কিনা, মরিচা আর ক্ল্যাম্প কেমন — দেখে তবে সিদ্ধান্ত।',
    art: '$_dir/no_look.svg',
    lessonPoint: 0,
  );

  static List<DoMistake> get all => const [climbRust, climbBent, climbSlipped, climbRustClamp, noLook, reportSound, reportUnseen, missedBolt, looseLeft, noWasher, overTorque];
}

@immutable
class M3CrossarmDeal {
  const M3CrossarmDeal({required this.poles, required this.callAt});
  final List<M3CrossarmPole> poles;

  /// The pole the careless coworker comes on (the rusty/bent arm).
  final int callAt;
}

/// Three poles in a fresh order: one with a rusty or bent arm (his pole); one
/// sound pole with a loose nut and a nut without its spring washer; and one
/// of: a slipped clamp, a rusty clamp, a sound pole with one bad bolt, or a
/// sound pole with nothing wrong.
M3CrossarmDeal m3CrossarmDeal(math.Random rng) {
  T pick<T>(List<T> l) => l[rng.nextInt(l.length)];
  final weak = M3CrossarmPole(id: 'p0', fault: rng.nextBool() ? M3CrossarmFault.rustArm : M3CrossarmFault.bentArm);
  final fix = M3CrossarmPole(id: 'p1', fault: M3CrossarmFault.none, bolts: [_loose, _bare, _ok]..shuffle(rng));
  final third = switch (rng.nextInt(4)) {
    0 => const M3CrossarmPole(id: 'p2', fault: M3CrossarmFault.slippedClamp),
    1 => const M3CrossarmPole(id: 'p2', fault: M3CrossarmFault.rustClamp),
    2 => M3CrossarmPole(id: 'p2', fault: M3CrossarmFault.none, bolts: [pick(const [_loose, _bare, _both]), _ok, _ok]..shuffle(rng)),
    _ => const M3CrossarmPole(id: 'p2', fault: M3CrossarmFault.none),
  };
  final poles = [weak, fix, third]..shuffle(rng);
  return M3CrossarmDeal(poles: poles, callAt: poles.indexOf(weak));
}

/// A bolt as it is now (mutable, in the run).
class M3CrossarmBoltNow {
  M3CrossarmBoltNow(M3CrossarmBoltSpec s)
      : loose = s.loose,
        washer = s.washer;
  bool loose;
  bool washer;
  bool checked = false;

  M3CrossarmBoltLook get look => M3CrossarmBoltLook(loose: loose, washer: washer, checked: checked);
}

/// What a report did: right, a needless stop on a sound pole, or a guess
/// before arm and clamp were looked at (both wrong ones are slips).
enum M3CrossarmReport { done, needlessSound, needlessUnseen }

extension M3CrossarmReportMistake on M3CrossarmReport {
  /// The slip card of a wrong report (null for a right one).
  DoMistake? get mistake => switch (this) {
        M3CrossarmReport.done => null,
        M3CrossarmReport.needlessSound => M3CrossarmCheckMistakes.reportSound,
        M3CrossarmReport.needlessUnseen => M3CrossarmCheckMistakes.reportUnseen,
      };
}

/// The play state (pure logic).
class M3CrossarmCheckRun {
  M3CrossarmCheckRun(this.deal) {
    _startPole();
  }

  final M3CrossarmDeal deal;
  int index = 0;

  /// Up the pole (the close view) on this pole.
  var up = false;
  final Set<M3CrossarmPart> looked = {};
  final List<M3CrossarmBoltNow> bolts = [];
  int? selected;
  int fixes = 0;

  var shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.poles.length;
  bool get ended => done || deadly != null;
  M3CrossarmPole get current => deal.poles[index.clamp(0, deal.poles.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;

  void _startPole() {
    up = false;
    looked.clear();
    bolts
      ..clear()
      ..addAll(current.bolts.map(M3CrossarmBoltNow.new));
    selected = null;
    fixes = 0;
    shown = false;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Look at [p] from the ground. True the first time.
  bool look(M3CrossarmPart p) {
    if (!_open || up) return false;
    return looked.add(p);
  }

  /// Climb the pole. Null = up (the close view).
  DoMistake? climb() {
    if (!_open || up) return null;
    final c = current;
    switch (c.fault) {
      case M3CrossarmFault.rustArm:
        shown = true;
        return deadly = M3CrossarmCheckMistakes.climbRust;
      case M3CrossarmFault.bentArm:
        shown = true;
        return deadly = M3CrossarmCheckMistakes.climbBent;
      case M3CrossarmFault.slippedClamp:
        shown = true;
        slips++;
        return M3CrossarmCheckMistakes.climbSlipped;
      case M3CrossarmFault.rustClamp:
        shown = true;
        slips++;
        return M3CrossarmCheckMistakes.climbRustClamp;
      case M3CrossarmFault.none:
        if (!looked.containsAll(m3CrossarmMustLook)) {
          shown = true;
          slips++;
          return M3CrossarmCheckMistakes.noLook;
        }
        up = true;
        _tag(M3CrossarmCheckLines.caughtLook);
        return null;
    }
  }

  /// Report from the ground — a decision: the pole ends either way. Right
  /// when the faulty part was looked at; a guess (arm and clamp not both
  /// looked at) or a needless stop (a sound pole) is a slip. The guess is
  /// judged first, so its card is the same whatever the pole was.
  M3CrossarmReport? report() {
    if (!_open || up) return null;
    final c = current;
    shown = true;
    if (!c.report || !looked.contains(c.faultPart)) {
      slips++;
      return looked.containsAll(m3CrossarmMustLook) ? M3CrossarmReport.needlessSound : M3CrossarmReport.needlessUnseen;
    }
    _tag(M3CrossarmCheckLines.caughtLook);
    _tag(c.faultPart == M3CrossarmPart.arm ? M3CrossarmCheckLines.caughtArm : M3CrossarmCheckLines.caughtClamp);
    return M3CrossarmReport.done;
  }

  /// Try bolt [i] with the spanner (and take it in hand).
  M3CrossarmBoltNow? check(int i) {
    if (!_open || !up || i < 0 || i >= bolts.length) return null;
    selected = i;
    return bolts[i]..checked = true;
  }

  /// Fit a spring washer on the bolt in hand: the nut comes off and goes back
  /// on finger-tight (it needs the torque again). False if nothing changed.
  bool fitWasher() {
    final i = selected;
    if (!_open || !up || i == null) return false;
    final b = bolts[i];
    if (b.washer) return false;
    b
      ..washer = true
      ..loose = true
      ..checked = true;
    fixes++;
    _tag(M3CrossarmCheckLines.caughtWasher);
    return true;
  }

  /// Let go of the wrench at [v] (0–1 of the dial).
  M3CrossarmTorque? torque(double v) {
    final i = selected;
    if (!_open || !up || i == null) return null;
    final b = bolts[i]..checked = true;
    if (v > kM3CrossarmTorqueHi) {
      // Snapped: a new bolt goes in, finger-tight.
      slips++;
      b.loose = true;
      return M3CrossarmTorque.over;
    }
    if (v < kM3CrossarmTorqueLo) return M3CrossarmTorque.under;
    if (b.loose) {
      b.loose = false;
      fixes++;
      _tag(M3CrossarmCheckLines.caughtTorque);
    }
    return M3CrossarmTorque.right;
  }

  /// Done up the pole. Null = right (the reason follows).
  DoMistake? finish() {
    if (!_open || !up) return null;
    shown = true;
    if (bolts.any((b) => !b.checked)) {
      slips++;
      return M3CrossarmCheckMistakes.missedBolt;
    }
    if (bolts.any((b) => b.loose)) {
      slips++;
      return M3CrossarmCheckMistakes.looseLeft;
    }
    if (bolts.any((b) => !b.washer)) {
      slips++;
      return M3CrossarmCheckMistakes.noWasher;
    }
    return null;
  }

  void next() {
    index++;
    if (!done) _startPole();
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A report pole
/// (ms): look at three parts 4500, report 1500, reason ~8200 ≈ 14200; the fix
/// pole: looks 4500, climb 1500, three bolts 4500, a washer 1500, two torques
/// 2 × 2500, done 1500, reason 8200 ≈ 26700; the third pole ≈ 20000; the
/// coworker ~9600; the guide's lines between ≈ 6000: ≈ 76500; 85 % ≈ 65 s.
const kM3CrossarmQuickMs = 65000;

@immutable
class M3CrossarmCheckPack {
  const M3CrossarmCheckPack({required this.id, required this.titleBn, this.quickMs = kM3CrossarmQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3CrossarmCheckPacks = {
  'do_3_3_b': M3CrossarmCheckPack(id: 'do_3_3_b', titleBn: M3CrossarmCheckLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3CrossarmCheckPage extends StatefulWidget {
  const M3CrossarmCheckPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3CrossarmCheckPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3CrossarmCheckPage> createState() => _M3CrossarmCheckPageState();
}

class _M3CrossarmCheckPageState extends State<M3CrossarmCheckPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CrossarmRunPage(
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

class _CrossarmRunPage extends ConsumerStatefulWidget {
  const _CrossarmRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3CrossarmCheckPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CrossarmRunPage> createState() => _CrossarmRunPageState();
}

class _CrossarmRunPageState extends ConsumerState<_CrossarmRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3CrossarmCheckRun _run = M3CrossarmCheckRun(m3CrossarmDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The torque wrench's dial while held (one sweep, then it stops).
  late final AnimationController _torque = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: kM3CrossarmSweepMs),
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && _holding) _release();
    });
  var _holding = false;

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;

  /// After this slip card the pole goes on (an over-torque), not the next.
  var _cardStays = false;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  bool? _reported;
  var _coworkerArmed = false;

  /// The part in the lens (from the ground).
  M3CrossarmPart? _looking;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// Gesture hints (how to touch, never what): taps on nothing count.
  final _hints = IdleHintController();
  final _reportKey = GlobalKey();
  final _climbKey = GlobalKey();
  final _washerKey = GlobalKey();
  final _torqueKey = GlobalKey();
  final _doneKey = GlobalKey();

  /// The scene's geometry as last laid out (for the hints).
  M3CrossarmGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _torque.dispose();
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

  Future<void> _start() async {
    _clock.start();
    _startPole();
  }

  /// Hands on: not in the praise window of a right move ([tableBusy]), not
  /// while he talks, no card, the pole not decided.
  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.shown;

  void _startPole() {
    _torque.value = 0;
    setState(() {
      _reported = null;
      _looking = null;
      _wake++;
    });
    unawaited(_sayChain([M3CrossarmCheckLines.askGround]));
  }

  // --- hands on: the ground -----------------------------------------------------------
  void _tapGround(Offset p, M3CrossarmGeo geo) {
    if (!_canPlay || _run.up) return;
    final part = geo.partAt(p);
    if (part == null) {
      _hints.missTap();
      return;
    }
    HapticFeedback.selectionClick();
    final first = _run.look(part);
    setState(() {
      _looking = part;
      _wake++;
    });
    final c = _run.current;
    if (part == M3CrossarmPart.clamp && c.rattles) {
      _cue('sounds/learn/wind_gust.wav', volume: 0.45);
      _cue('sounds/learn/knock_hollow.wav', volume: 0.6);
    } else {
      _cue('sounds/intro/tick.ogg', volume: 0.5);
    }
    // His moment: the weak arm has just been seen.
    if (first && part == M3CrossarmPart.arm && !_coworkerArmed && _run.index == _run.deal.callAt) {
      _coworkerArmed = true;
      scheduleCoworker();
    }
  }

  Future<void> _climb(Offset origin) async {
    if (!_canPlay || _run.up) return;
    if (holdForCoworker()) return;
    await _commitClimb(origin);
  }

  Future<void> _commitClimb(Offset origin) async {
    _hush();
    final m = _run.climb();
    if (m == null) {
      if (!_run.up) return;
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/stomp.wav', volume: 0.5);
      setState(() {
        _looking = null;
        _wake++;
      });
      unawaited(_sayChain([M3CrossarmCheckLines.askUp]));
      return;
    }
    HapticFeedback.mediumImpact();
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    setState(() {});
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  Future<void> _report(Offset origin) async {
    if (!_canPlay || _run.up) return;
    if (holdForCoworker()) return;
    _hush();
    final r = _run.report();
    if (r == null) return;
    final m = r.mistake;
    if (m != null) {
      // A needless stop or a guess: a slip, and the pole ends.
      HapticFeedback.mediumImpact();
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    setState(() {
      _reported = true;
      _wake++;
    });
    _success(M3CrossarmCheckLines.whyReport);
  }

  void _success(String question) {
    putOnTable(15 + (_run.fixes > 0 ? 5 : 0));
    final c = _run.current;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M3CrossarmCheckLines.whyRight(c), M3CrossarmCheckLines.whyWrong(c), widget.rng),
      question: question,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  // --- hands on: up the pole ------------------------------------------------------------
  void _tapUp(Offset p, M3CrossarmGeo geo) {
    if (!_canPlay || !_run.up || _holding) return;
    final i = geo.boltAt(p);
    if (i == null) {
      _hints.missTap();
      return;
    }
    final b = _run.check(i);
    if (b == null) return;
    HapticFeedback.selectionClick();
    _cue(b.loose ? 'sounds/learn/knock_hollow.wav' : 'sounds/learn/knock_solid.wav', volume: 0.6);
    _torque.value = 0;
    setState(() => _wake++);
  }

  void _fitWasher() {
    if (!_canPlay || !_run.up || _holding) return;
    if (!_run.fitWasher()) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    _torque.value = 0;
    setState(() => _wake++);
  }

  void _press() {
    if (!_canPlay || !_run.up || _run.selected == null || _holding) return;
    _holding = true;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tick.wav', volume: 0.4);
    _torque.forward(from: 0);
    setState(() {});
  }

  void _release() {
    if (!_holding) return;
    _holding = false;
    _torque.stop();
    final v = _torque.value;
    final r = _run.torque(v);
    setState(() => _wake++);
    switch (r) {
      case M3CrossarmTorque.right:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/ring_steel.wav', volume: 0.6);
      case M3CrossarmTorque.under:
        _cue('sounds/learn/tock.wav', volume: 0.5);
      case M3CrossarmTorque.over:
        HapticFeedback.heavyImpact();
        _cue('sounds/intro/impact_metal.ogg', volume: 0.8);
        _cardStays = true;
        unawaited(_levelDelta(-10, Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height * 0.4), mood: GuideMood.warn));
        unawaited(_slip(M3CrossarmCheckMistakes.overTorque));
      case null:
        break;
    }
  }

  Future<void> _finishPole(Offset origin) async {
    if (!_canPlay || !_run.up || _holding) return;
    _hush();
    final m = _run.finish();
    if (m == null) {
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      setState(() {
        _reported = false;
        _wake++;
      });
      _success(M3CrossarmCheckLines.whyDone);
      return;
    }
    setState(() {});
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startPole();
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript =>
      _run.deal.poles[_run.deal.callAt].fault == M3CrossarmFault.bentArm ? M3CrossarmCheckLines.coworkerBent : M3CrossarmCheckLines.coworkerRust;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("climb this arm") makes sense only on his pole, from the
    // ground, before the pole is decided.
    if (_ended || _run.index != _run.deal.callAt || _run.shown || _run.up) return null;
    if (_intro || _busy || _card != null || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: up onto the weak arm.
      await _commitClimb(origin);
      return;
    }
    if (!_run.caught.contains(M3CrossarmCheckLines.caughtCall)) _run.caught.add(M3CrossarmCheckLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([M3CrossarmCheckLines.callHeld]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3CrossarmCheckLines.tapWhy[_nudgeN++ % M3CrossarmCheckLines.tapWhy.length]
            : _nudge.next(_run.up ? M3CrossarmCheckLines.askUp : M3CrossarmCheckLines.askGround);
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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('crossarm/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up onto the weak arm: the scene freezes grey and the arm gives way in
  /// colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('crossarm/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3CrossarmCheckLines.deadlyWord : M3CrossarmCheckLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final stays = _cardStays;
        _cardStays = false;
        setState(() => _card = null);
        if (stays) {
          _torque.value = 0;
          unawaited(_sayChain([M3CrossarmCheckLines.askUp]));
        } else {
          _next();
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
    await _say(!_run.passed ? M3CrossarmCheckLines.fail : (_quickBonus ? M3CrossarmCheckLines.quick : M3CrossarmCheckLines.allSet),
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
    if (_reported == true) return LinemanMode.cheer;
    if (_looking != null) return LinemanMode.point;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M3CrossarmGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final up = _run.up && !_freeze;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              if (up)
                Positioned.fill(
                  key: const ValueKey('up'),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: M3CrossarmUpPainter(geo: geo, bolts: [for (final b in _run.bolts) b.look], selected: _run.selected),
                    ),
                  ),
                )
              else ...[
                Positioned.fill(
                  key: const ValueKey('land'),
                  child: RepaintBoundary(
                    child: CustomPaint(painter: M3CrossarmGroundPainter(geo: geo, fault: c.fault, looking: _looking)),
                  ),
                ),
                Positioned.fromRect(
                  key: const ValueKey('trainee'),
                  rect: geo.trainee,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ],
            ],
          ),
        ),
      ),
      if (_reported != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: up ? 60 : 150,
          width: up ? 240 : 190,
          top: up ? geo.upArmY - 150 : geo.armY + 90,
          child: IgnorePointer(child: _StampPop(text: _reported! ? M3CrossarmCheckLines.stampReport : M3CrossarmCheckLines.stampDone, quiet: quiet)),
        ),
      // Tap a part (from the ground) or a bolt (up the pole).
      Positioned.fill(
        key: ValueKey('touch-$up'),
        child: Semantics(
          label: up ? M3CrossarmCheckLines.upLabel : M3CrossarmCheckLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => up ? _tapUp(d.localPosition, geo) : _tapGround(d.localPosition, geo)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('break'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3CrossarmBreakPainter(geo: geo, v: v)),
            ),
          ),
        ),
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}-${_run.up}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || (_run.index == 0 && !_run.up) ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  // --- gesture hints (how to touch, never which) -------------------------------
  /// A scene rect (design px) on screen: FullSceneFrame's cover fit of the
  /// 360-wide scene over the whole page.
  Rect _onScreen(Rect r) {
    final size = MediaQuery.sizeOf(context);
    final w = math.max(1.0, size.width);
    final sh = (360 * size.height / w).clamp(560.0, 900.0);
    final scale = math.max(size.width / 360, size.height / sh);
    final dx = (size.width - 360 * scale) / 2;
    final dy = (size.height - sh * scale) / 2;
    return Rect.fromLTWH(dx + r.left * scale, dy + r.top * scale, r.width * scale, r.height * scale);
  }

  /// From the ground: a sweep over the three parts and both decisions (every
  /// choice, in a fixed order). Up the pole: a sweep over the bolts; with a
  /// bolt in hand, over the bolts and every tool — except a nut the spanner
  /// has shown loose that already has its spring washer, where the one way on
  /// is to hold the wrench.
  HintSpec? _hint() {
    final geo = _geo;
    if (geo == null) return null;
    Rect? at(GlobalKey k) => HintSpec.globalRectOf(k);
    if (!_run.up) {
      return HintSpec.sweep([
        for (final p in M3CrossarmPart.values) _onScreen(geo.hit(p)),
        ?at(_reportKey),
        ?at(_climbKey),
      ]);
    }
    final bolts = [for (var i = 0; i < _run.bolts.length; i++) _onScreen(geo.boltHit(i))];
    final s = _run.selected;
    if (s == null) return HintSpec.sweep(bolts);
    final b = _run.bolts[s];
    if (b.checked && b.loose && b.washer) return HintSpec.holdOn(_torqueKey);
    return HintSpec.sweep([...bolts, ?at(_washerKey), ?at(_torqueKey), ?at(_doneKey)]);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.done && !_run.shown && !deckUp && !coworkerOpen && _card == null;
    final up = _run.up;
    final b = _run.selected == null ? null : _run.bolts[_run.selected!];
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
              labels: M3CrossarmCheckLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !_busy && !_holding && !tableBusy && !coworkerOnScreen,
            hintKey: '${_run.index}-$up-${_run.selected}-${_run.looked.length}-${_run.fixes}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && !up && _looking != null && !deckUp && !_run.done)
                Positioned(
                  key: const ValueKey('hud-lens'),
                  left: 10,
                  top: pad.top + 86,
                  child: _Lens(part: _looking!, fault: _run.current.fault, rattle: _looking == M3CrossarmPart.clamp && _run.current.rattles),
                ),
              if (handsOn && up) ...[
                Positioned(
                  key: const ValueKey('hud-gauge'),
                  left: 10,
                  bottom: pad.bottom + 150,
                  child: _TorqueGauge(progress: _torque),
                ),
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 10,
                  right: 12,
                  bottom: pad.bottom + 72,
                  child: Row(
                    children: [
                      _ToolButton(key: _washerKey, icon: Icons.radio_button_unchecked_rounded, label: M3CrossarmCheckLines.washer, enabled: b != null && !_holding, onTap: _fitWasher),
                      const SizedBox(width: 8),
                      Expanded(child: _HoldButton(key: _torqueKey, label: M3CrossarmCheckLines.torque, enabled: b != null, progress: _torque, onDown: _press, onUp: _release)),
                    ],
                  ),
                ),
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: DoBigButton(key: _doneKey, label: M3CrossarmCheckLines.done, filled: true, onTapUp: (d) => unawaited(_finishPole(d.globalPosition))),
                ),
              ],
              if (handsOn && !up)
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(child: DoBigButton(key: _reportKey, label: M3CrossarmCheckLines.report, filled: false, onDark: true, onTapUp: (d) => unawaited(_report(d.globalPosition)))),
                      const SizedBox(width: 10),
                      Expanded(child: DoBigButton(key: _climbKey, label: M3CrossarmCheckLines.climb, filled: true, onTapUp: (d) => unawaited(_climb(d.globalPosition)))),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (up ? 132 : 72)), onLeft: coworkerFromRight),
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
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M3CrossarmCheckLines.intro,
                  alarm: 'sounds/learn/wind_gust.wav',
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

// ============================================================================
// Pieces
// ============================================================================

/// The part close up, as seen from below (what his eyes find), with its name.
class _Lens extends StatelessWidget {
  const _Lens({required this.part, required this.fault, required this.rattle});
  final M3CrossarmPart part;
  final M3CrossarmFault fault;
  final bool rattle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1324),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SlmColors.gold300, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                key: ValueKey('lens-${part.name}'),
                width: 166,
                height: 112,
                child: RepaintBoundary(child: CustomPaint(painter: M3CrossarmLensPainter(part: part, fault: fault, rattle: rattle))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(M3CrossarmCheckLines.partBn(part), style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The torque wrench's dial: the needle sweeps while held; the band is the
/// right torque.
class _TorqueGauge extends StatelessWidget {
  const _TorqueGauge({required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 132,
        height: 82,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4048), Color(0xFF1E2228)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0E1013), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: RepaintBoundary(child: CustomPaint(key: const ValueKey('torque-dial'), painter: _GaugePainter(progress))),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.progress) : super(repaint: progress);
  final Animation<double> progress;

  @override
  void paint(Canvas c, Size size) {
    final centre = Offset(size.width / 2, size.height - 4);
    final r = math.min(size.width / 2, size.height) - 4;
    final rect = Rect.fromCircle(center: centre, radius: r);
    c.drawArc(rect, math.pi, math.pi, false, Paint()
      ..color = const Color(0xFFEDEDE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);
    c.drawArc(rect, math.pi + math.pi * kM3CrossarmTorqueLo, math.pi * (kM3CrossarmTorqueHi - kM3CrossarmTorqueLo), false, Paint()
      ..color = const Color(0xFF2FA35A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);
    c.drawArc(rect, math.pi + math.pi * kM3CrossarmTorqueHi, math.pi * (1 - kM3CrossarmTorqueHi), false, Paint()
      ..color = const Color(0xFFD8473A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);
    final a = math.pi + math.pi * progress.value.clamp(0.0, 1.0);
    c.drawLine(centre, centre + Offset(math.cos(a), math.sin(a)) * (r - 2), Paint()
      ..color = const Color(0xFFFFD34E)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    c.drawCircle(centre, 5, Paint()..color = const Color(0xFFFFD34E));
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}

/// Hold to pull the wrench; let go to stop.
class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.label, required this.enabled, required this.progress, required this.onDown, required this.onUp});
  final String label;
  final bool enabled;
  final Animation<double> progress;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: enabled ? SlmColors.gold700 : const Color(0xFF4A505A)),
                AnimatedBuilder(
                  animation: progress,
                  builder: (_, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.value.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Color(0x55FFFFFF)),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = enabled ? SlmColors.gold300 : const Color(0xFF6B7380);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.7),
                ),
                child: Icon(icon, size: 22, color: ring),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, textAlign: TextAlign.center, maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.08, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
