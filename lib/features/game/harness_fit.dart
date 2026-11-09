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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'pole_yard.dart' show PoleGeo, PoleYardPainter;
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

// Lesson 1.4, কাজ 2: "ফিটিং আর অ্যাঙ্কর". Three climbs on a village roadside.
// First the fit, with the hands: the trainee stands at the pole in his full
// body harness — drag the chest strap's buckle to mid-chest, pull the leg
// strap's tail to tighten it, run a finger down a twisted shoulder strap to
// straighten it, turn him round and drag the back D-ring up between the
// shoulders; slide the hand under the leg strap to feel the fit (four
// fingers, or the whole hand). Then "ঠিক আছে — উঠি". Up the pole: tap a point
// on the drawn pole top, the lens shows its state, clip the lanyard there —
// only the sling round the pole body is a strong point (it sits at a dealt
// height, its ring on a dealt side, so the spot is never learnt by heart).
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" (the reasons fit what this
// climb had) → up the pole / the next climb by itself; the careless coworker
// once a play, with one of three lesson shortcuts (dealt).
//
// Deadly (owner-approved list: weak anchor): a broken cross-arm, an insulator
// pin or a loose bracket as the anchor (also by listening to him about the
// pin); climbing on without tying off (listening to "হারনেস লাগে না").
// Slips: a fit fault left; a strap moved from right to wrong; letting him
// loosen the straps "for comfort". Three slips strike the level out.
//
// Voice: the guide's lines by device TTS; the coworker in his recorded voice.
// Art: the roadside is pole_yard.dart's; the trainee, the harness, the pole
// top and the lens close-ups are drawn in code; mistake pictures in
// assets/game/art/harness/.

// ============================================================================
// Content
// ============================================================================

enum FitFault { twisted, chestHigh, loose, dRingLow }

enum FitZone { shoulder, chest, leg, dRing }

extension FitFaultZone on FitFault {
  FitZone get zone => switch (this) {
        FitFault.twisted => FitZone.shoulder,
        FitFault.chestHigh => FitZone.chest,
        FitFault.loose => FitZone.leg,
        FitFault.dRingLow => FitZone.dRing,
      };
}

enum AnchorPoint { sling, crackedArm, insulatorPin, looseBracket }

/// The shortcut the careless coworker pushes (one a play).
enum FitPush { looseStraps, pinClip, twentyYears }

@immutable
class ClimbRound {
  const ClimbRound({required this.faults, required this.anchors, this.slingAt = 1, this.slingLeft = false});
  final Set<FitFault> faults;

  /// Anchor points offered (the sling always; 2–3 weak ones).
  final List<AnchorPoint> anchors;

  /// Where the sling sits on the pole body this climb (0 high … 2 low), and
  /// on which side its ring hangs — dealt, so it is never "the same spot".
  final int slingAt;
  final bool slingLeft;
}

@immutable
class ClimbDeal {
  const ClimbDeal({required this.rounds, required this.pushRound, required this.push});
  final List<ClimbRound> rounds;

  /// The climb on which he turns up, and what he pushes.
  final int pushRound;
  final FitPush push;
}

abstract final class FitLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askFit, askAnchor];

  static const title = 'ফিটিং আর অ্যাঙ্কর';
  static const intro = 'লাইনে জরুরি কাজ! কিন্তু হারনেস যদি ঢিলেঢালা বা ফিতে পেঁচানো থাকে, ওপর থেকে পা হড়কালে ঝাঁকুনিতে শরীর ফালাফালা হয়ে যাবে। আগে গায়ে টানটান ফিটিং করুন, তারপর পোলে মজবুত জায়গায় অ্যাঙ্কর লাগান।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const askFit = 'হারনেসের ফিটিং দেখুন — ঠিক করে তবে উঠুন।';
  static const askAnchor = 'ল্যানিয়ার্ড কোথায় লাগাবেন? মজবুত জায়গা বেছে নিন।';

  // Controls (labels a worker reads, and the touch zones' names).
  static const turn = 'ঘোরান';
  static const climb = 'ঠিক আছে — উঠি';
  static const hand = 'হাত';
  static const man = 'লাইনম্যান';
  static const chestBuckle = 'বুকের বাকল';
  static const dRing = 'ডি-রিং';
  static const tail = 'ফিতের মাথা';
  static const straps = 'কাঁধের ফিতে';
  static const anchorLabel = 'অ্যাঙ্কর';
  static const lensLabel = 'লেন্স';
  static const clipHere = 'এখানে লাগাই';
  static const lensClose = 'বন্ধ';

  /// What the hand under the leg strap feels.
  static const fourFingers = '4 আঙুল';
  static const wholeHand = 'পুরো হাত ঢোকে';
  static const fixedChip = 'ঠিক করা';
  static String faultBn(FitFault f) => switch (f) {
        FitFault.twisted => 'ফিতে পেঁচানো',
        FitFault.chestHigh => 'বুকের ফিতে গলার কাছে',
        FitFault.loose => 'পায়ের ফিতে ঢিলে',
        FitFault.dRingLow => 'ডি-রিং নিচে',
      };

  // The reasons (lesson 1.4 points 3 and 4): one right, two wrong, all about
  // the same length; the right ones fit what this climb had.
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static String fitAsk(FitFault? f) => switch (f) {
        null => 'কেন কিছু না বদলেই উঠছেন?',
        FitFault.twisted => 'কেন ফিতের প্যাঁচ খুললেন?',
        FitFault.chestHigh => 'কেন বুকের ফিতে নামালেন?',
        FitFault.loose => 'কেন পায়ের ফিতে টাইট করলেন?',
        FitFault.dRingLow => 'কেন ডি-রিং ওপরে তুললেন?',
      };
  static List<String> fitWhy(FitFault? f) => switch (f) {
        null => const ['চার আঙুল, বুকের মাঝ, কাঁধের মাঝে ডি-রিং', 'সব মিলিয়ে দেখেছি, কোথাও ভুল ছিল না'],
        FitFault.twisted => const ['পরার সময় কোনো ফিতে পেঁচিয়ে থাকবে না', 'নিয়ম বলে: ফিতে পেঁচিয়ে রাখা চলবে না'],
        FitFault.chestHigh => const ['বুকের ফিতে থাকবে বুকের মাঝ বরাবর', 'বুকের ফিতের জায়গা বুকের ঠিক মাঝখানে'],
        FitFault.loose => const ['ঢিলে হারনেস পড়ার সময় খুলে যেতে পারে', 'খুব ঢিলে নয় — সাধারণত চার আঙুল ঢোকে'],
        FitFault.dRingLow => const ['পেছনের ডি-রিং থাকবে দুই কাঁধের মাঝে', 'ডি-রিংয়ের জায়গা দুই কাঁধের ঠিক মাঝখানে'],
      };

  /// The wrong reasons, on the question's own strap (a clean climb gets the
  /// general ones), so the strap's name never gives the right card away.
  static List<String> fitMyths(FitFault? f) => switch (f) {
        null => const [
            'অভিজ্ঞ হলে ফিটিং মিলিয়ে দেখতে হয় না',
            'তাড়া আছে, ফিটিং পরে দেখলেও চলবে',
            'হারনেস গায়ে আছে, এটুকুই যথেষ্ট',
            'কাল ঠিক ছিল, তাই আজও ঠিকই থাকবে',
            'একটু এদিক-ওদিক হলে কিছুই হয় না',
            'পেছনটা তো কেউ দেখে না, ওটা চলে যায়',
          ],
        FitFault.twisted => const [
            'পেঁচানো ফিতেও সোজা ফিতের মতোই কাজ করে',
            'প্যাঁচটা দেখতে খারাপ লাগছিল, তাই',
            'এমনি খুললাম, প্যাঁচে কিছু যায় আসে না',
            'অভ্যাসে খুললাম, প্যাঁচ কোনো ব্যাপার নয়',
            'প্যাঁচ খুললে হারনেস দেখতে নতুন লাগে',
          ],
        FitFault.chestHigh => const [
            'গলার কাছে বুকের ফিতে বেশি শক্ত ধরে',
            'বুকের ফিতে যেখানে খুশি থাকলেই হলো',
            'বুকের ফিতে আটকানো থাকলেই যথেষ্ট',
            'নিচে নামালে দেখতে ভালো লাগে, তাই',
            'বুকের ফিতের জায়গা কোনো ব্যাপার নয়',
          ],
        FitFault.loose => const [
            'ঢিলে থাকলে আরাম, তাই একটু ঢিলেই ভালো',
            'ফিতে যত ঢিলে, নড়াচড়া তত সহজ হয়',
            'পতনের সময় পায়ের ফিতে কখনো খোলে না',
            'পায়ের ফিতে ঢিলে থাকলেও দিব্যি চলে',
            'যত টাইট তত ভালো, তাই টেনে দিলাম',
          ],
        FitFault.dRingLow => const [
            'ডি-রিং যেখানেই থাক, ল্যানিয়ার্ড তো লাগবে',
            'পেছনটা তো কেউ দেখে না, ওটা চলে যায়',
            'ডি-রিং কোমরের কাছে থাকাই আসল নিয়ম',
            'ওপরে তুললে দেখতে বেশ ভালো লাগে, তাই',
            'ডি-রিংয়ের জায়গা কোনো ব্যাপার নয়',
          ],
      };

  /// Which fixed fault the reason asks about (the back check first).
  static FitFault? reasonFault(Set<FitFault> owed) {
    for (final f in const [FitFault.dRingLow, FitFault.loose, FitFault.chestHigh, FitFault.twisted]) {
      if (owed.contains(f)) return f;
    }
    return null;
  }

  static const anchorAsk = 'কেন এখানে ল্যানিয়ার্ড লাগালেন?';
  static const anchorWhyAll = ['অ্যাঙ্কর হবে ওজনের বহু গুণ ভার সইবার মতো', 'দুর্বল অ্যাঙ্করে পুরো ব্যবস্থাই ব্যর্থ'];
  static const anchorWhyArm = 'ভাঙা ক্রস-আর্ম কখনো ভালো অ্যাঙ্কর নয়';
  static const anchorWhyPin = 'দুর্বল ইনসুলেটর পিন কখনো অ্যাঙ্কর নয়';

  /// The right reasons for a tie-off on this pole top (the weak points it had).
  static List<String> anchorWhy(List<AnchorPoint> offered) => [
        ...anchorWhyAll,
        if (offered.contains(AnchorPoint.crackedArm)) anchorWhyArm,
        if (offered.contains(AnchorPoint.insulatorPin)) anchorWhyPin,
      ];
  static const anchorMyths = [
    'যেটা হাতের কাছে পাই, তাতেই লাগালে চলে',
    'ইনসুলেটর পিন তো লোহার, ওতেই দিব্যি চলে',
    'অল্প সময়ের কাজে অ্যাঙ্কর না হলেও চলে',
    'ক্রস-আর্ম একটু ফাটা হলেও ভার ঠিকই নেয়',
    'জায়গা নয়, ল্যানিয়ার্ড লাগানোটাই আসল',
    'ব্র্যাকেট একটু নড়বড়ে হলেও কিছু হয় না',
  ];

  // The careless coworker (his recorded voice): one of three shortcuts.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const pushLoose = 'এত টাইট কেন? ফিতে একটু ঢিলে রাখো, সারাদিন আরামে কাজ করবে!';
  static const pushPin = 'এত খোঁজাখুঁজি কেন? হাতের কাছেই ইনসুলেটর পিন — ওতেই ক্লিপ করে দাও!';

  /// The lesson's own myth (already recorded in his voice for the Learn board).
  static const pushYears = 'আমি 20 বছর ধরে কাজ করছি, খুব সাবধানে থাকি। আমার কখনো হারনেস লাগে না।';
  static const askChoice = 'কার কথা শুনবেন — ওর, না নিয়মের?';
  static const coworkerLoose = CoworkerScript(
    line: pushLoose,
    exitLine: coworkerExit,
    right: ['না — খুব ঢিলে নয়, চার আঙুল', 'আরামে নড়ি, কিন্তু ঢিলে নয়', 'ঢিলে হারনেস খুলে যেতে পারে'],
    wrong: ['ঠিক, ফিতে একটু ঢিলেই রাখি', 'আরামটাই আগে, ঢিলে করে দিই', 'সারাদিনের কাজ, ঢিলেই ভালো', 'পায়ের ফিতেটা একটু ছেড়ে দিই', 'সবাই তো ঢিলে করেই হারনেস পরে'],
    asks: ['ও বলছে ফিতে ঢিলে রাখতে। আপনি কী করবেন?', 'ঢিলে রাখবেন, না ঠিক ফিটিং?', askChoice],
  );
  static const coworkerPin = CoworkerScript(
    line: pushPin,
    exitLine: coworkerExit,
    right: ['না — পিন নয়, মজবুত অ্যাঙ্কর', 'দুর্বল পিনে নয়, মজবুত জায়গায়', 'ইনসুলেটর পিন অ্যাঙ্কর নয়, না'],
    wrong: ['ঠিক, পিনেই ক্লিপ করে দিই', 'হাতের কাছে পিন, ওতেই চলবে', 'একটুখানি কাজ, পিনেই লাগাই', 'পিনটা তো লোহার, ওতেই হবে', 'সবাই তো পিনেই লাগায়, দিই'],
    asks: ['ও বলছে পিনেই ক্লিপ করতে। আপনি কী করবেন?', 'পিনে লাগাবেন, না মজবুত জায়গায়?', askChoice],
  );
  static const coworkerYears = CoworkerScript(
    line: pushYears,
    exitLine: coworkerExit,
    right: ['না — আগে অ্যাঙ্কর, তারপর কাজ', 'অভিজ্ঞতা নয়, অ্যাঙ্করই বাঁচায়', 'মাধ্যাকর্ষণ অভিজ্ঞতা মানে না'],
    wrong: ['ঠিক, অ্যাঙ্কর ছাড়াই কাজ সারি', 'উনি 20 বছর পারলে আমিও পারব', 'সাবধানে থাকলেই চলবে, থাক', 'অল্প কাজ, অ্যাঙ্কর লাগবে না', 'ঠিক, সোজা উঠে কাজটা সেরে ফেলি'],
    asks: ['ও বলছে হারনেস লাগে না। আপনি কী করবেন?', 'অ্যাঙ্কর করবেন, না ওর কথায় চলবেন?', askChoice],
  );
  static CoworkerScript coworker(FitPush p) => switch (p) {
        FitPush.looseStraps => coworkerLoose,
        FitPush.pinClip => coworkerPin,
        FitPush.twentyYears => coworkerYears,
      };
  static const all = [coworkerLoose, coworkerPin, coworkerYears];
  static String callHeld(FitPush p) => switch (p) {
        FitPush.looseStraps => 'ঠিক! ঢিলে হারনেস খুলে যেতে পারে।',
        FitPush.pinClip => 'ঠিক! দুর্বল পিন কখনো অ্যাঙ্কর নয়।',
        FitPush.twentyYears => 'ঠিক! মাধ্যাকর্ষণ অভিজ্ঞতা মানে না।',
      };

  static const allSet = 'ঠিক ফিটিং, মজবুত অ্যাঙ্কর — হারনেস এবার সত্যিই প্যারাশুট।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — চার আঙুল, বুকের মাঝ, কাঁধের মাঝ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtFit = 'ফিটিংয়ের ভুল ধরেছেন';
  static const caughtBack = 'পেছন ঘুরে ডি-রিং দেখেছেন';
  static const caughtFingers = 'চার আঙুলে মেপে দেখেছেন';
  static const caughtAnchor = 'মজবুত জায়গায় অ্যাঙ্কর';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class FitMistakes {
  static DoMistake missed(FitFault f) => switch (f) {
        FitFault.twisted => const DoMistake(
            key: '1.4/fit/twisted',
            textBn: 'কাঁধের ফিতে পেঁচানো ছিল — পরার সময় কোনো ফিতে পেঁচিয়ে থাকবে না। সোজা করে তবে উঠুন।',
            art: 'assets/game/art/harness/fit_check.svg',
            lessonPoint: 2),
        FitFault.chestHigh => const DoMistake(
            key: '1.4/fit/chest-high',
            textBn: 'বুকের ফিতে গলার কাছে ছিল — বুকের ফিতে থাকবে বুকের মাঝ বরাবর।',
            art: 'assets/game/art/harness/fit_check.svg',
            lessonPoint: 2),
        FitFault.loose => const DoMistake(
            key: '1.4/fit/loose',
            textBn: 'পায়ের ফিতে খুব ঢিলে — পুরো হাত ঢুকছে। ঢিলে হারনেস পড়ার সময় শরীর থেকে খুলে যেতে পারে।',
            art: 'assets/game/art/harness/fit_check.svg',
            lessonPoint: 2),
        FitFault.dRingLow => const DoMistake(
            key: '1.4/fit/d-ring-low',
            textBn: 'পিঠের ডি-রিং নিচে নেমে ছিল — থাকবে দুই কাঁধের মাঝখানে। পেছনটাও ঘুরিয়ে দেখুন।',
            art: 'assets/game/art/harness/fit_check.svg',
            lessonPoint: 2),
      };
  static const falseMark = DoMistake(
    key: '1.4/fit/false-mark',
    textBn: 'এটা ঠিকই ছিল, আপনি ভুল জায়গায় সরালেন — বুকের মাঝ, চার আঙুল, কাঁধের মাঝে ডি-রিং।',
    art: 'assets/game/art/harness/fit_check.svg',
    lessonPoint: 2,
  );
  static const pushedLoose = DoMistake(
    key: '1.4/fit/pushed-loose',
    textBn: 'আরামের জন্য ফিতে ঢিলে করলেন — ঢিলে হারনেস পড়ার সময় খুলে যেতে পারে। আরামে নড়তে পারবেন, কিন্তু খুব ঢিলে নয় — সাধারণত চার আঙুল ঢোকে।',
    art: 'assets/game/art/harness/fit_check.svg',
    lessonPoint: 2,
  );
  static DoMistake anchor(AnchorPoint a) => switch (a) {
        AnchorPoint.crackedArm => const DoMistake(
            key: '1.4/anchor/cracked-arm',
            textBn: 'ভাঙা ক্রস-আর্ম কখনো অ্যাঙ্কর নয় — অ্যাঙ্কর দুর্বল হলে হারনেস যত ভালোই হোক, পুরো ব্যবস্থাটাই ব্যর্থ।',
            art: 'assets/game/art/harness/anchor_strong.svg',
            deadly: true,
            lessonPoint: 3),
        AnchorPoint.insulatorPin => const DoMistake(
            key: '1.4/anchor/insulator-pin',
            textBn: 'দুর্বল ইনসুলেটর পিন অ্যাঙ্কর নয় — অ্যাঙ্কর হবে আপনার ওজনের অনেক গুণ ভার সইবার মতো মজবুত।',
            art: 'assets/game/art/harness/anchor_strong.svg',
            deadly: true,
            lessonPoint: 3),
        AnchorPoint.looseBracket => const DoMistake(
            key: '1.4/anchor/loose-bracket',
            textBn: 'নড়বড়ে ব্র্যাকেট অ্যাঙ্কর নয় — অ্যাঙ্কর হবে আপনার ওজনের অনেক গুণ ভার সইবার মতো মজবুত।',
            art: 'assets/game/art/harness/anchor_strong.svg',
            deadly: true,
            lessonPoint: 3),
        AnchorPoint.sling => noTieOff,
      };
  static const noTieOff = DoMistake(
    key: '1.4/anchor/no-tie-off',
    textBn: 'অ্যাঙ্কর ছাড়া কাজ ধরলেন — একটা পিছলে যাওয়াই যথেষ্ট। অভিজ্ঞতা নয়, হারনেসই একমাত্র দ্বিতীয় সুযোগ।',
    art: 'assets/game/art/harness/no_tie_off.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static List<DoMistake> get all => [
        for (final f in FitFault.values) missed(f),
        falseMark,
        pushedLoose,
        for (final a in AnchorPoint.values.skip(1)) anchor(a),
        noTieOff,
      ];
}

/// Three climbs: fit faults vary (one climb is clean; the D-ring fault shows
/// up once), the weak anchors vary; he comes once, with a dealt shortcut (the
/// pin is on his pole top when he pushes the pin); the sling sits at a
/// different height on each climb.
ClimbDeal dealClimbs(math.Random rng) {
  final clean = rng.nextInt(3);
  final slings = [0, 1, 2]..shuffle(rng);
  final dRing = (clean + 1 + rng.nextInt(2)) % 3;
  final push = FitPush.values[rng.nextInt(FitPush.values.length)];
  final pushRound = rng.nextInt(3);
  final rounds = <ClimbRound>[];
  for (var i = 0; i < 3; i++) {
    final faults = <FitFault>{};
    if (i != clean) {
      if (i == dRing) faults.add(FitFault.dRingLow);
      final others = [FitFault.twisted, FitFault.chestHigh, FitFault.loose]..shuffle(rng);
      faults.add(others.first);
      if (faults.length < 2 && rng.nextBool()) faults.add(others[1]);
    }
    final weak = [AnchorPoint.crackedArm, AnchorPoint.insulatorPin, AnchorPoint.looseBracket]..shuffle(rng);
    final take = weak.take(2 + rng.nextInt(2)).toList();
    if (push == FitPush.pinClip && i == pushRound && !take.contains(AnchorPoint.insulatorPin)) {
      take[take.length - 1] = AnchorPoint.insulatorPin;
    }
    rounds.add(ClimbRound(faults: faults, anchors: [AnchorPoint.sling, ...take], slingAt: slings[i], slingLeft: rng.nextBool()));
  }
  return ClimbDeal(rounds: rounds, pushRound: pushRound, push: push);
}

enum ClimbPhase { fit, fitShown, anchor, anchored }

@immutable
class FitCheck {
  const FitCheck({required this.missed, required this.falseMarks});
  final List<FitFault> missed;
  final List<FitZone> falseMarks;
  bool get clean => missed.isEmpty && falseMarks.isEmpty;
}

/// How the harness sits now (what the hands have done to it).
class FitState {
  FitState.dealt(Set<FitFault> faults)
      : twisted = faults.contains(FitFault.twisted),
        chestHigh = faults.contains(FitFault.chestHigh),
        loose = faults.contains(FitFault.loose),
        dRingLow = faults.contains(FitFault.dRingLow);

  bool twisted;
  bool chestHigh;
  bool loose;
  bool dRingLow;

  bool isWrong(FitFault f) => switch (f) {
        FitFault.twisted => twisted,
        FitFault.chestHigh => chestHigh,
        FitFault.loose => loose,
        FitFault.dRingLow => dRingLow,
      };

  Set<FitFault> get wrong => {for (final f in FitFault.values) if (isWrong(f)) f};

  void fixAll() {
    twisted = false;
    chestHigh = false;
    loose = false;
    dRingLow = false;
  }
}

/// The play state (pure logic).
class ClimbRun {
  ClimbRun(this.deal);
  final ClimbDeal deal;
  int round = 0;
  ClimbPhase phase = ClimbPhase.fit;
  int slips = 0;
  DoMistake? deadly;
  bool sawBack = false;
  final List<String> caught = [];

  /// The harness now, and the faults to put right this climb (the dealt ones,
  /// and the straps he talked the player into loosening).
  late FitState fit = FitState.dealt(current.faults);
  late Set<FitFault> owed = {...current.faults};

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  ClimbRound get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get fitting => phase == ClimbPhase.fit && !ended;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// A finger down the shoulder strap: true when it was twisted.
  bool straighten() {
    if (!fitting || !fit.twisted) return false;
    fit.twisted = false;
    return true;
  }

  /// A pull on the leg strap's tail: true when it was loose.
  bool tighten() {
    if (!fitting || !fit.loose) return false;
    fit.loose = false;
    return true;
  }

  void setChest({required bool high}) {
    if (fitting) fit.chestHigh = high;
  }

  void setDRing({required bool low}) {
    if (fitting) fit.dRingLow = low;
  }

  void lookBack() {
    if (fitting) sawBack = true;
  }

  /// The hand slid under the leg strap: true = the whole hand goes in (loose).
  bool feelLeg() {
    final l = fit.loose;
    if (l && fitting) _tag(FitLines.caughtFingers);
    return l;
  }

  /// Listened to "ঢিলে রাখো": a slip, and the leg strap is loose now.
  void pushLoose() {
    if (!fitting) return;
    slips++;
    fit.loose = true;
    owed.add(FitFault.loose);
  }

  /// "ঠিক আছে — উঠি": what is still wrong is a slip each — a fault left
  /// ([FitCheck.missed]) or a strap moved from right to wrong
  /// ([FitCheck.falseMarks]).
  FitCheck checkFit() {
    if (!fitting) return const FitCheck(missed: [], falseMarks: []);
    phase = ClimbPhase.fitShown;
    final wrong = fit.wrong;
    final missed = [for (final f in FitFault.values) if (owed.contains(f) && wrong.contains(f)) f];
    final falseMarks = [for (final f in FitFault.values) if (!owed.contains(f) && wrong.contains(f)) f.zone];
    slips += missed.length + falseMarks.length;
    if (owed.isNotEmpty && missed.isEmpty) _tag(FitLines.caughtFit);
    if (owed.contains(FitFault.dRingLow) && !missed.contains(FitFault.dRingLow)) _tag(FitLines.caughtBack);
    return FitCheck(missed: missed, falseMarks: falseMarks);
  }

  /// The faults put right (for the points).
  int get fixedCount => owed.where((f) => !fit.isWrong(f)).length;

  void toAnchor() {
    if (phase == ClimbPhase.fitShown) phase = ClimbPhase.anchor;
  }

  /// Ties off at [a]; null = strong point, else the deadly mistake.
  DoMistake? tieOff(AnchorPoint a) {
    if (phase != ClimbPhase.anchor || ended) return null;
    if (a != AnchorPoint.sling) return deadly = FitMistakes.anchor(a);
    phase = ClimbPhase.anchored;
    _tag(FitLines.caughtAnchor);
    return null;
  }

  /// Gave in to "হারনেস লাগে না".
  DoMistake noTieOff() => deadly = FitMistakes.noTieOff;

  void next() {
    round++;
    phase = ClimbPhase.fit;
    sawBack = false;
    fit = FitState.dealt(current.faults);
    owed = {...current.faults};
  }
}

@immutable
class FitPack {
  const FitPack({required this.id, required this.titleBn, this.quickMs = 90000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const fitPack14 = FitPack(id: 'do_1_4_b', titleBn: FitLines.title);
const fitPacks = {'do_1_4_b': fitPack14};

// ============================================================================
// Page
// ============================================================================

class HarnessFitPage extends StatefulWidget {
  const HarnessFitPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final FitPack pack;
  final bool muted;
  final int? seed;

  @override
  State<HarnessFitPage> createState() => _HarnessFitPageState();
}

class _HarnessFitPageState extends State<HarnessFitPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FitRunPage(
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

class _FitRunPage extends ConsumerStatefulWidget {
  const _FitRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final FitPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_FitRunPage> createState() => _FitRunPageState();
}

/// What the finger holds on the harness.
enum _Grab { chest, dRing, tail, strap }

class _FitRunPageState extends ConsumerState<_FitRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final ClimbRun _run = ClimbRun(dealClimbs(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;

  // --- the fit ---
  var _back = false;
  int _turns = 0;
  _Grab? _grab;
  double _grabY = 0;
  double _grabMoved = 0;
  Offset? _hand;
  double _swipe = 0;

  /// The hand under the leg strap: true = the whole hand, false = 4 fingers.
  bool? _felt;
  FitCheck? _shown;
  var _moved = false;

  // --- the pole top ---
  AnchorPoint? _lens;
  AnchorPoint? _clip;

  /// The camera goes up the pole (true) or down to the next climb.
  var _up = true;

  /// A deadly tie-off: the scene freezes grey while the fall plays in colour.
  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
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

  String get _task => _run.phase == ClimbPhase.anchor ? FitLines.askAnchor : FitLines.askFit;

  /// After the guide's intro: the clock runs and he gives the first task.
  Future<void> _start() async {
    _clock.start();
    await _sayChain([FitLines.askFit]);
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || reasonOpen || coworkerOpen;

  /// His climb and his moment: the fit (loose straps) or the pole top.
  bool get _hisTurn =>
      !coworkerDone &&
      !_ended &&
      _run.round == _run.deal.pushRound &&
      (_run.deal.push == FitPush.looseStraps ? _run.phase == ClimbPhase.fit : _run.phase == ClimbPhase.anchor);

  bool get _canFit => !_blocked && _run.fitting;

  /// A first move on the harness: on his climb (loose straps) he comes soon.
  void _touched() {
    if (_moved) return;
    _moved = true;
    if (_hisTurn) scheduleCoworker();
  }

  // --- the fit: turn him, the buckles, the tail, the strap, the hand ---------
  void _turn() {
    if (!_canFit) return;
    _touched();
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.3, muted: false));
    setState(() {
      _back = !_back;
      _turns++;
      _hand = null;
      if (_back) _run.lookBack();
    });
  }

  void _grabStart(_Grab g) {
    if (!_canFit) return;
    _touched();
    HapticFeedback.selectionClick();
    setState(() {
      _grab = g;
      _grabMoved = 0;
      _grabY = switch (g) {
        _Grab.chest => _run.fit.chestHigh ? _FitGeo.chestHighY : _FitGeo.chestMidY,
        _Grab.dRing => _run.fit.dRingLow ? _FitGeo.dRingLowY : _FitGeo.dRingHighY,
        _ => 0,
      };
    });
  }

  void _grabMove(double dyUnit) {
    final g = _grab;
    if (g == null) return;
    _grabMoved += dyUnit;
    switch (g) {
      case _Grab.chest:
        setState(() => _grabY = (_grabY + dyUnit).clamp(_FitGeo.chestHighY - 6, _FitGeo.chestMidY + 22));
      case _Grab.dRing:
        setState(() => _grabY = (_grabY + dyUnit).clamp(_FitGeo.dRingHighY - 8, _FitGeo.dRingLowY + 8));
      case _Grab.tail:
        if (_grabMoved > 14 && _run.tighten()) {
          HapticFeedback.mediumImpact();
          if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.55, muted: false));
          setState(() => _felt = null);
        }
      case _Grab.strap:
        if (_grabMoved.abs() > 16 && _run.straighten()) {
          HapticFeedback.lightImpact();
          if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.wav', volume: 0.4, muted: false));
          setState(() {});
        }
    }
  }

  void _grabEnd() {
    final g = _grab;
    if (g == null) return;
    switch (g) {
      case _Grab.chest:
        final high = (_grabY - _FitGeo.chestHighY).abs() < (_grabY - _FitGeo.chestMidY).abs();
        _run.setChest(high: high);
        _clickBuckle();
      case _Grab.dRing:
        final low = (_grabY - _FitGeo.dRingLowY).abs() < (_grabY - _FitGeo.dRingHighY).abs();
        _run.setDRing(low: low);
        _clickBuckle();
      case _Grab.tail:
      case _Grab.strap:
        break;
    }
    setState(() => _grab = null);
  }

  void _clickBuckle() {
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tick.wav', volume: 0.6, muted: false));
  }

  void _handMove(Offset p) {
    if (!_canFit || _back) return;
    if (_hand == null) {
      _touched();
      HapticFeedback.selectionClick();
    }
    setState(() => _hand = p);
  }

  /// The hand let go: under the leg strap it feels the fit; elsewhere it goes home.
  void _handEnd(_FitGeo geo) {
    final h = _hand;
    if (h == null) return;
    if (_canFit && geo.r(_FitGeo.legZone).inflate(10).contains(h)) {
      final loose = _run.feelLeg();
      HapticFeedback.lightImpact();
      // One sound for both readings: the player judges the fit, not the cue.
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.5, muted: false));
      setState(() {
        _felt = loose;
        _hand = null;
      });
      return;
    }
    setState(() => _hand = null);
  }

  // --- "ঠিক আছে — উঠি" -----------------------------------------------------------
  Future<void> _checkFit(Offset origin) async {
    if (!_canFit) return;
    if (_hisTurn) {
      // He is about to come in (his climb): he catches the trainee first.
      _moved = true;
      HapticFeedback.selectionClick();
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tick.wav', volume: 0.4, muted: false));
      scheduleCoworker();
      return;
    }
    _hush();
    final owedN = _run.owed.length;
    final fixed = _run.fixedCount;
    final owed = {..._run.owed};
    final c = _run.checkFit();
    HapticFeedback.mediumImpact();
    setState(() {
      _shown = c;
      _hand = null;
      _grab = null;
      _felt = null;
    });
    if (c.clean) {
      // Right: the ◆ wait on the table, then "কেন …?" about what he fixed.
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      }
      putOnTable(10 * owedN + 10);
      final f = FitLines.reasonFault(owed);
      final round = _run.round;
      unawaited(askReason(
        deal: () => dealChoices(FitLines.fitWhy(f), FitLines.fitMyths(f), widget.rng),
        question: FitLines.fitAsk(f),
        stillValid: () => _run.round == round && !_ended,
      ));
      return;
    }
    final gain = 10 * fixed - 10 * (c.missed.length + c.falseMarks.length);
    if (gain != 0) unawaited(_levelDelta(gain, origin, mood: gain > 0 ? GuideMood.glad : GuideMood.warn));
    _busy = true;
    await Future<void>.delayed(_quiet ? Duration.zero : const Duration(milliseconds: 900));
    _busy = false;
    if (!mounted) return;
    await _slip(c.missed.isNotEmpty ? FitMistakes.missed(c.missed.first) : FitMistakes.falseMark);
  }

  /// Up the pole (after the fit's reason, or its slip card).
  void _climb() {
    if (_ended) return;
    _run.fit.fixAll();
    _run.toAnchor();
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.35, muted: false));
    setState(() {
      _up = true;
      _shown = null;
      _hand = null;
      _felt = null;
      _back = false;
      _lens = null;
      _clip = null;
    });
    if (_hisTurn) scheduleCoworker();
    unawaited(_sayChain([FitLines.askAnchor]));
  }

  // --- the pole top: the lens, the tie-off ------------------------------------
  bool get _canAnchor => !_blocked && _run.phase == ClimbPhase.anchor && !_freeze;

  void _openLens(AnchorPoint a) {
    if (!_canAnchor || _lens != null) return;
    if (_hisTurn) return; // he is about to call out
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.45, muted: false));
    setState(() => _lens = a);
  }

  void _closeLens() {
    if (_lens == null) return;
    setState(() => _lens = null);
  }

  Future<void> _tieOff(Offset origin) async {
    final a = _lens;
    if (a == null || !_canAnchor) return;
    _hush();
    final m = _run.tieOff(a);
    setState(() {
      _lens = null;
      _clip = a;
    });
    if (m != null) {
      await _deadly(m);
      return;
    }
    HapticFeedback.mediumImpact();
    if (!_muted) {
      unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.7, muted: false));
      unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
    }
    putOnTable(15);
    final r = _run.current;
    final round = _run.round;
    unawaited(askReason(
      deal: () => dealChoices(FitLines.anchorWhy(r.anchors), FitLines.anchorMyths, widget.rng),
      question: FitLines.anchorAsk,
      stillValid: () => _run.round == round && !_ended,
    ));
  }

  /// The next climb (or the result) — by itself, after the anchor's reason.
  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _up = false;
      _clip = null;
      _lens = null;
      _back = false;
      _felt = null;
      _shown = null;
      _moved = false;
    });
    unawaited(_sayChain([FitLines.askFit]));
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
    if (_run.phase == ClimbPhase.fitShown) {
      _climb();
    } else {
      _next();
    }
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => FitLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (!_hisTurn) return null;
    if (_blocked || _lens != null || _grab != null || _hand != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final push = _run.deal.push;
    if (!held) {
      switch (push) {
        case FitPush.looseStraps:
          // He loosens the leg strap "for comfort": a slip; it is loose now.
          _run.pushLoose();
          setState(() => _felt = null);
          unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
          await _slip(FitMistakes.pushedLoose);
        case FitPush.pinClip:
          // Clipped to the insulator pin.
          setState(() => _clip = AnchorPoint.insulatorPin);
          await _deadly(_run.tieOff(AnchorPoint.insulatorPin) ?? FitMistakes.anchor(AnchorPoint.insulatorPin));
        case FitPush.twentyYears:
          await _deadly(_run.noTieOff());
      }
      return;
    }
    _run.caught.add(FitLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([FitLines.callHeld(push), _task], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? FitLines.tapWhy[_nudgeN++ % FitLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  /// The third small mistake: the level fails and the lesson card insists.
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
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('fit/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly tie-off: the pole top freezes grey, the fall plays in colour,
  /// then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _lens = null;
    });
    await frozen.future;
    if (!mounted) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('fit/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? FitLines.deadlyWord : FitLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        if (_run.phase == ClimbPhase.fitShown) {
          // The fault is shown put right; then up the pole by itself.
          final round = _run.round;
          setState(() => _run.fit.fixAll());
          unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 900), () {
            if (mounted && !_ended && _run.round == round && _run.phase == ClimbPhase.fitShown) _climb();
          }));
        } else {
          unawaited(_sayChain([_task]));
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
    await _say(!_run.passed ? FitLines.fail : (_quickBonus ? FitLines.quick : FitLines.allSet),
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
  List<Widget> _scene(SceneMetrics m) {
    final quiet = _quiet;
    final fitting = _run.phase == ClimbPhase.fit || _run.phase == ClimbPhase.fitShown;
    final stageKey = ValueKey('${fitting ? 'fit' : 'top'}-${_run.round}');
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final up = _up;
    return [
      Positioned.fill(
        key: const ValueKey('stage'),
        child: ColorFiltered(
          colorFilter: grey,
          child: AnimatedSwitcher(
            duration: quiet ? Duration.zero : const Duration(milliseconds: 900),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
            transitionBuilder: (child, anim) {
              // Up the pole: the roadside drops away and the pole top comes
              // down into view (and the other way at the next climb).
              final incoming = child.key == stageKey;
              final from = incoming ? Offset(0, up ? -1 : 1) : Offset(0, up ? 1 : -1);
              return SlideTransition(position: Tween(begin: from, end: Offset.zero).animate(anim), child: child);
            },
            child: KeyedSubtree(key: stageKey, child: Stack(fit: StackFit.expand, children: fitting ? _fitStage(m) : _topStage(m, still: _freeze))),
          ),
        ),
      ),
      // The deadly fall, in colour over the grey pole top.
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('fall'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: quiet ? 1 : 1900),
              curve: Curves.easeIn,
              builder: (_, f, _) => CustomPaint(
                painter: _TopPainter(geo: _topGeo(m), anchors: _run.current.anchors, clip: _clip, tie: 1, fall: f, part: _TopPart.moving),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _fitStage(SceneMetrics m) {
    final geo = _FitGeo.of(m.height, m.inset);
    final quiet = _quiet;
    final fit = _run.fit;
    final s = _shown;
    final handOn = !_back && _canFit;
    final chestY = _grab == _Grab.chest ? _grabY : (fit.chestHigh ? _FitGeo.chestHighY : _FitGeo.chestMidY);
    final dRingY = _grab == _Grab.dRing ? _grabY : (fit.dRingLow ? _FitGeo.dRingLowY : _FitGeo.dRingHighY);
    Widget handle(String key, String label, Rect unit, _Grab g) => Positioned.fromRect(
          key: ValueKey(key),
          rect: geo.r(unit),
          child: Semantics(
            label: label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => _grabStart(g),
              onVerticalDragUpdate: (d) => _grabMove(d.delta.dy / geo.k),
              onVerticalDragEnd: (_) => _grabEnd(),
              onVerticalDragCancel: _grabEnd,
            ),
          ),
        );
    return [
      Positioned.fill(
        key: const ValueKey('road'),
        child: RepaintBoundary(child: CustomPaint(painter: _RoadPainter(geo: geo))),
      ),
      // The trainee in his harness (he turns round with a squash).
      Positioned.fill(
        key: const ValueKey('trainee'),
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('turn-$_turns'),
            tween: Tween(begin: _turns == 0 || quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOut,
            builder: (_, t, _) => TweenAnimationBuilder<double>(
              tween: Tween(end: fit.twisted ? 1 : 0),
              duration: quiet ? Duration.zero : const Duration(milliseconds: 380),
              builder: (_, tw, _) => TweenAnimationBuilder<double>(
                tween: Tween(end: fit.loose ? 1 : 0),
                duration: quiet ? Duration.zero : const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                builder: (_, slack, _) => CustomPaint(
                  painter: _TraineePainter(
                    geo: geo,
                    back: t < 0.5 ? !_back : _back,
                    squash: math.max(0.04, (math.cos(math.pi * t)).abs()),
                    twist: tw,
                    slack: slack,
                    chestY: chestY,
                    dRingY: dRingY,
                    tucked: _felt != null && !_back,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // Swipe across him to turn him round.
      Positioned.fromRect(
        key: const ValueKey('h-man'),
        rect: geo.r(_FitGeo.bodyZone),
        child: Semantics(
          label: FitLines.man,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => _swipe = 0,
            onHorizontalDragUpdate: (d) => _swipe += d.delta.dx,
            onHorizontalDragEnd: (_) {
              if (_swipe.abs() > 30) _turn();
            },
          ),
        ),
      ),
      if (!_back) handle('h-tail', FitLines.tail, _FitGeo.tailZone, _Grab.tail),
      if (!_back) handle('h-chest', FitLines.chestBuckle, _FitGeo.handleAt(chestY, width: 40), _Grab.chest),
      // Over the buckle's right edge: a finger on the twist takes the strap.
      if (!_back) handle('h-strap', FitLines.straps, _FitGeo.strapZone, _Grab.strap),
      if (_back) handle('h-dring', FitLines.dRing, _FitGeo.handleAt(dRingY), _Grab.dRing),
      // Where the hand goes under the leg strap (tests find it; no touch).
      Positioned.fromRect(key: const ValueKey('z-leg'), rect: geo.r(_FitGeo.legZone), child: const IgnorePointer(child: SizedBox.expand())),
      // What the hand felt under the leg strap.
      if (_felt != null && !_back && s == null)
        Positioned(
          key: const ValueKey('felt'),
          left: geo.p(150, 250).dx,
          top: geo.p(150, 250).dy,
          // A neutral reading (no red / green): judging it is the player's job.
          child: IgnorePointer(child: _Chip(text: _felt! ? FitLines.wholeHand : FitLines.fourFingers, quiet: quiet)),
        ),
      // After "উঠি": each strap that mattered, put right or not.
      if (s != null)
        for (final (z, text, ok) in _verdicts(s))
          Positioned(
            key: ValueKey('verdict-${z.name}'),
            // Left of him: the guide's corner rises with the reason deck.
            right: 360 - geo.p(52, 0).dx,
            top: geo.p(0, _FitGeo.zoneY(z, chestY, dRingY)).dy - 12,
            child: IgnorePointer(child: _Chip(text: text, bad: !ok, verdict: true, quiet: quiet)),
          ),
      // The hand: drag it under a strap to feel the fit.
      if (handOn || _hand != null)
        Positioned(
          key: const ValueKey('h-hand'),
          left: (_hand ?? geo.handHome).dx - 28,
          top: (_hand ?? geo.handHome).dy - 28,
          width: 56,
          height: 56,
          child: Semantics(
            label: FitLines.hand,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => _handMove((_hand ?? geo.handHome) + d.localPosition - const Offset(28, 28)),
              onPanUpdate: (d) => _handMove((_hand ?? geo.handHome) + d.delta),
              onPanEnd: (_) => _handEnd(geo),
              onPanCancel: () => _handEnd(geo),
              child: const _HandToken(),
            ),
          ),
        ),
    ];
  }

  /// The chips after the fit check: (zone, text, put right?).
  List<(FitZone, String, bool)> _verdicts(FitCheck c) => [
        for (final f in FitFault.values)
          if (_run.owed.contains(f)) (f.zone, c.missed.contains(f) ? FitLines.faultBn(f) : FitLines.fixedChip, !c.missed.contains(f)),
        for (final z in c.falseMarks) (z, FitLines.faultBn(FitFault.values.firstWhere((f) => f.zone == z)), false),
      ];

  _TopGeo _topGeo(SceneMetrics m) => _TopGeo(m.height, slingAt: _run.current.slingAt, slingLeft: _run.current.slingLeft);

  List<Widget> _topStage(SceneMetrics m, {required bool still}) {
    final geo = _topGeo(m);
    final quiet = _quiet;
    final r = _run.current;
    return [
      Positioned.fill(
        key: const ValueKey('top'),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _clip == null ? 0.0 : 1.0),
          duration: quiet || still ? Duration.zero : const Duration(milliseconds: 650),
          curve: Curves.easeOutBack,
          builder: (_, tie, _) => CustomPaint(
            painter: _TopPainter(geo: geo, anchors: r.anchors, clip: _clip, tie: tie, fall: 0, part: still ? _TopPart.still : _TopPart.all),
          ),
        ),
      ),
      if (_run.phase == ClimbPhase.anchor && _clip == null)
        for (final a in r.anchors)
          Positioned.fromRect(
            key: ValueKey('spot-${a.name}'),
            rect: geo.spot(a),
            child: Semantics(
              button: true,
              label: FitLines.anchorLabel,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _openLens(a)),
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
    final fitUp = playing && _run.phase == ClimbPhase.fit && !deckUp && _card == null && !coworkerOpen;
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
              labels: FitLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (fitUp) ...[
                Positioned(
                  key: const ValueKey('hud-turn'),
                  left: 10,
                  bottom: pad.bottom + 84,
                  child: _ToolButton(icon: Icons.threesixty_rounded, label: FitLines.turn, onTap: _turn),
                ),
                Positioned(
                  key: const ValueKey('hud-climb'),
                  left: 16,
                  right: 136,
                  bottom: pad.bottom + 22,
                  child: DoBigButton(label: FitLines.climb, filled: true, onTapUp: (d) => unawaited(_checkFit(d.globalPosition))),
                ),
              ],
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
              if (_lens != null && playing)
                _Lens(
                  key: const ValueKey('lens'),
                  point: _lens!,
                  quiet: quiet,
                  onClip: (o) => unawaited(_tieOff(o)),
                  onClose: _closeLens,
                ),
              if (playing && _card == null && _lens == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.round}'),
                  mistake: _card!,
                  tone: _cardTone,
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
                  line: FitLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 2, muted: _muted)),
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

/// A hands-on tool: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 74,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.6),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: SlmColors.gold300),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trainee's gloved hand, ready to slide under a strap.
class _HandToken extends StatelessWidget {
  const _HandToken();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xE6122036),
            border: Border.all(color: SlmColors.gold300, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: const Icon(Icons.back_hand_rounded, size: 26, color: Color(0xFFD9A066)),
        ),
      );
}

/// A small chip on the scene: what the hand felt (neutral, like a tool's
/// label), or a strap's verdict after "উঠি" (red / green).
class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.bad = false, this.verdict = false, required this.quiet});
  final String text;
  final bool bad;
  final bool verdict;
  final bool quiet;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, alignment: Alignment.centerLeft, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: !verdict ? const Color(0xE60B1324) : (bad ? SlmColors.danger : const Color(0xFF2E8B45)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: verdict ? Colors.white : SlmColors.ivory.withValues(alpha: 0.85), width: 1.2),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Text(text, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: verdict ? Colors.white : SlmColors.ivory)),
        ),
      );
}

// ============================================================================
// The fit: the roadside, the trainee in his harness
// ============================================================================

/// Where the trainee stands (design px, 360 wide). His drawing is a 200 × 400
/// unit box, feet at the bottom, scaled to the scene.
@immutable
class _FitGeo {
  const _FitGeo(this.pole, this.feet, this.height);

  factory _FitGeo.of(double h, double inset) {
    final pole = PoleGeo.forScene(h, inset);
    final feet = pole.groundY + 24;
    return _FitGeo(pole, feet, (feet - 160).clamp(300.0, 440.0));
  }

  final PoleGeo pole;
  final double feet;
  final double height;

  static const cx = 198.0;
  double get k => height / 400;
  double get top => feet - height;
  double get ox => cx - 100 * k;

  Offset p(double x, double y) => Offset(ox + x * k, top + y * k);
  Rect r(Rect u) => Rect.fromLTRB(ox + u.left * k, top + u.top * k, ox + u.right * k, top + u.bottom * k);

  /// Where the hand waits (left of him, at the leg straps' height).
  Offset get handHome => Offset(math.max(44.0, ox - 34), top + 262 * k);

  // Unit positions.
  static const chestHighY = 92.0;
  static const chestMidY = 142.0;
  static const dRingHighY = 112.0;
  static const dRingLowY = 198.0;
  static const legY = 256.0;
  static const bodyZone = Rect.fromLTRB(22, 4, 178, 396);
  /// The right shoulder strap (the one that twists), clear of the buckle's middle.
  static const strapZone = Rect.fromLTRB(104, 76, 148, 136);
  static const tailZone = Rect.fromLTRB(128, 248, 172, 306);
  static const legZone = Rect.fromLTRB(60, 236, 146, 286);
  static Rect handleAt(double y, {double width = 70}) => Rect.fromCenter(center: Offset(100, y), width: width, height: 42);

  static double zoneY(FitZone z, double chestY, double dRingY) => switch (z) {
        FitZone.shoulder => 112,
        FitZone.chest => chestY,
        FitZone.leg => legY + 6,
        FitZone.dRing => dRingY,
      };
}

/// The village roadside (pole_yard's) with the pole he will climb.
class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.geo});
  final _FitGeo geo;

  @override
  void paint(Canvas c, Size s) {
    PoleYardPainter(geo: geo.pole, orbit: 0.12).paint(c, s);
    final g = geo.pole.groundY;
    // The PCC pole behind him, left (its top out of the picture).
    const x = 58.0;
    final pole = Path()
      ..moveTo(x - 15, g + 4)
      ..lineTo(x - 10, -10)
      ..lineTo(x + 10, -10)
      ..lineTo(x + 15, g + 4)
      ..close();
    c.drawPath(
      pole,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF9C9A93), Color(0xFFD8D5CC), Color(0xFFA9A69E)], stops: [0, 0.45, 1])
            .createShader(Rect.fromLTRB(x - 15, 0, x + 15, g)),
    );
    // Step bolts.
    final bolt = Paint()
      ..color = const Color(0xFF6B6F74)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var y = g - 60; y > 40; y -= 46) {
      final left = ((g - y) / 46).round().isEven;
      c.drawLine(Offset(x + (left ? -12 : 12), y), Offset(x + (left ? -24 : 24), y - 2), bolt);
    }
    // Its foot in the soil, and the tool bag and coiled lanyard beside it.
    c.drawOval(Rect.fromCenter(center: Offset(x, g + 5), width: 44, height: 10), Paint()..color = const Color(0x55402A14));
    final bag = RRect.fromRectAndRadius(Rect.fromLTWH(x + 18, g - 6, 40, 24), const Radius.circular(6));
    c.drawRRect(bag, Paint()..color = const Color(0xFF5B4A33));
    c.drawLine(Offset(x + 22, g - 6), Offset(x + 54, g - 6), Paint()
      ..color = const Color(0xFF3A2E20)
      ..strokeWidth = 3);
    c.drawArc(Rect.fromLTWH(x + 28, g - 18, 20, 18), math.pi, math.pi, false, Paint()
      ..color = const Color(0xFF3A2E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    final coil = Paint()
      ..color = const Color(0xFF3B6EA8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    for (var i = 0; i < 3; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(x + 80, g + 12 - i * 2.0), width: 30 - i * 3.0, height: 10), coil);
    }
    // His shadow on the shoulder.
    c.drawOval(Rect.fromCenter(center: Offset(_FitGeo.cx, geo.feet - 2), width: 120 * geo.k, height: 16 * geo.k), Paint()..color = const Color(0x44301E0C));
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.geo.height != geo.height || old.geo.feet != geo.feet;
}

/// The trainee (front or back) in a full body harness, with its fit now.
class _TraineePainter extends CustomPainter {
  _TraineePainter({
    required this.geo,
    required this.back,
    required this.squash,
    required this.twist,
    required this.slack,
    required this.chestY,
    required this.dRingY,
    required this.tucked,
  });
  final _FitGeo geo;
  final bool back;

  /// 1 = facing; → 0 mid-turn.
  final double squash;
  final double twist;
  final double slack;
  final double chestY;
  final double dRingY;

  /// The hand is under the leg strap.
  final bool tucked;

  static const _web = Color(0xFFF06A1D);
  static const _webDark = Color(0xFFA8410C);
  static const _metal = Color(0xFF9AA3AB);
  static const _shirt = Color(0xFF1F5F8F);
  static const _shirtDark = Color(0xFF184A70);
  static const _pants = Color(0xFF26303D);
  static const _skin = Color(0xFFA86E48);
  static const _glove = Color(0xFF8B5A2B);
  static const _helmet = Color(0xFFFFD34E);

  void _line(Canvas c, Offset a, Offset b, double w, Color col) => c.drawLine(
        a,
        b,
        Paint()
          ..color = col
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );

  void _strap(Canvas c, Offset a, Offset b) {
    _line(c, a, b, 11, _webDark);
    _line(c, a, b, 8.5, _web);
  }

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(geo.ox, geo.top);
    c.scale(geo.k);
    // The turn squashes him about his middle.
    c.translate(100, 0);
    c.scale(squash, 1);
    c.translate(-100, 0);

    // Legs and boots.
    _line(c, const Offset(82, 226), const Offset(78, 312), 32, _pants);
    _line(c, const Offset(78, 312), const Offset(76, 384), 28, _pants);
    _line(c, const Offset(118, 226), const Offset(122, 312), 32, _pants);
    _line(c, const Offset(122, 312), const Offset(124, 384), 28, _pants);
    final boot = Paint()..color = const Color(0xFF2A1F17);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(58, 378, 92, 398), const Radius.circular(7)), boot);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(108, 378, 142, 398), const Radius.circular(7)), boot);

    // Arms behind the body's edge, then the torso.
    _line(c, const Offset(60, 86), const Offset(44, 152), 20, _shirtDark);
    _line(c, const Offset(44, 152), const Offset(40, 206), 18, _shirtDark);
    _line(c, const Offset(140, 86), const Offset(156, 152), 20, _shirtDark);
    _line(c, const Offset(156, 152), const Offset(160, 206), 18, _shirtDark);
    final hand = Paint()..color = _glove;
    c.drawCircle(const Offset(40, 214), 10, hand);
    c.drawCircle(const Offset(160, 214), 10, hand);
    final torso = RRect.fromRectAndRadius(const Rect.fromLTRB(58, 72, 142, 234), const Radius.circular(24));
    c.drawRRect(
      torso,
      Paint()
        ..shader = const LinearGradient(colors: [_shirtDark, _shirt, _shirtDark], stops: [0, 0.5, 1]).createShader(torso.outerRect),
    );
    // Neck and head.
    c.drawRect(const Rect.fromLTRB(92, 58, 108, 76), Paint()..color = _skin);
    if (back) {
      c.drawCircle(const Offset(100, 42), 22, Paint()..color = const Color(0xFF2B211A));
    } else {
      c.drawCircle(const Offset(100, 44), 21, Paint()..color = _skin);
      final eye = Paint()..color = const Color(0xFF1E1A16);
      c.drawCircle(const Offset(92, 46), 2.2, eye);
      c.drawCircle(const Offset(108, 46), 2.2, eye);
      c.drawArc(Rect.fromCenter(center: const Offset(100, 54), width: 12, height: 6), 0.2, math.pi - 0.4, false, Paint()
        ..color = const Color(0xFF5A3422)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
      // Chin strap.
      c.drawArc(Rect.fromCenter(center: const Offset(100, 46), width: 44, height: 40), 0.15, math.pi - 0.3, false, Paint()
        ..color = const Color(0xFF3A3A3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
    }
    // Helmet: dome and brim.
    c.drawArc(Rect.fromCenter(center: const Offset(100, 40), width: 52, height: 48), math.pi, math.pi, true, Paint()..color = _helmet);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(72, 37, 128, 43), const Radius.circular(3)), Paint()..color = const Color(0xFFE5B92E));

    // --- the harness ---
    if (!back) {
      // Shoulder straps.
      _strap(c, const Offset(80, 74), const Offset(84, 226));
      _strap(c, const Offset(120, 74), const Offset(116, 226));
      if (twist > 0.01) {
        // A half turn in the right strap: it narrows and shows its dark back.
        final w = 5.0 * twist;
        c.drawPath(
          Path()
            ..moveTo(119 - w, 96)
            ..lineTo(119 + w, 96)
            ..lineTo(118.5 - w, 116)
            ..lineTo(118 + w, 134)
            ..lineTo(118 - w, 134)
            ..lineTo(118.5 + w, 116)
            ..close(),
          Paint()..color = Color.lerp(_web, const Color(0xFF6E2A08), twist)!,
        );
        _line(c, Offset(119 - 6 * twist, 100), Offset(118 + 6 * twist, 130), 1.4, _webDark);
      }
      // Waist band and the straps down to the leg loops.
      _strap(c, const Offset(62, 224), const Offset(138, 224));
      _strap(c, const Offset(84, 226), const Offset(80, 250));
      _strap(c, const Offset(116, 226), const Offset(120, 250));
      // Leg loops round the thighs; the right one sags when loose.
      final legL = Path()
        ..moveTo(64, 256)
        ..quadraticBezierTo(80, 262, 96, 250);
      final sag = 12 * slack;
      final legR = Path()
        ..moveTo(104, 250)
        ..quadraticBezierTo(120, 262 + sag, 138, 256 + sag * 0.6);
      if (slack > 0.05) {
        // The gap between the strap and the thigh.
        c.drawPath(
          Path()
            ..moveTo(106, 252)
            ..quadraticBezierTo(120, 258, 136, 254)
            ..lineTo(136, 254 + sag * 0.6)
            ..quadraticBezierTo(120, 262 + sag, 106, 252)
            ..close(),
          Paint()..color = const Color(0x88101418),
        );
      }
      for (final p in [legL, legR]) {
        c.drawPath(p, Paint()
          ..color = _webDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round);
        c.drawPath(p, Paint()
          ..color = _web
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.5
          ..strokeCap = StrokeCap.round);
      }
      // The right loop's buckle and its tail (longer once pulled tight).
      final bk = Offset(138, 256 + sag * 0.6);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: bk, width: 12, height: 14), const Radius.circular(2)), Paint()..color = _metal);
      _strap(c, bk + const Offset(3, 6), bk + Offset(6, 18 + 18 * (1 - slack)));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(64, 256), width: 12, height: 14), const Radius.circular(2)), Paint()..color = _metal);
      // Chest strap with its buckle.
      _strap(c, Offset(80, chestY), Offset(120, chestY));
      final buckle = Rect.fromCenter(center: Offset(100, chestY), width: 22, height: 13);
      c.drawRRect(RRect.fromRectAndRadius(buckle, const Radius.circular(3)), Paint()..color = const Color(0xFF2B2F35));
      c.drawRRect(RRect.fromRectAndRadius(buckle.deflate(3), const Radius.circular(2)), Paint()..color = _metal);
      // The hand under the leg strap.
      if (tucked) {
        final skin = Paint()..color = _glove;
        final deep = slack > 0.5;
        for (var i = 0; i < 4; i++) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(108 + i * 6.5, 244, 5.6, deep ? 26 : 16), const Radius.circular(3)), skin);
        }
        if (deep) c.drawOval(Rect.fromLTWH(106, 258, 30, 14), skin);
      }
    } else {
      // From behind: the straps cross at the D-ring plate.
      final plate = Offset(100, dRingY);
      _strap(c, const Offset(80, 76), plate);
      _strap(c, const Offset(120, 76), plate);
      _strap(c, plate, const Offset(84, 226));
      _strap(c, plate, const Offset(116, 226));
      _strap(c, const Offset(62, 224), const Offset(138, 224));
      _strap(c, const Offset(84, 226), const Offset(80, 250));
      _strap(c, const Offset(116, 226), const Offset(120, 250));
      _strap(c, const Offset(64, 254), const Offset(96, 252));
      _strap(c, const Offset(104, 252), const Offset(136, 254));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: plate, width: 20, height: 14), const Radius.circular(3)), Paint()..color = const Color(0xFF2B2F35));
      c.drawPath(
        Path()
          ..moveTo(91, plate.dy - 4)
          ..quadraticBezierTo(91, plate.dy - 22, 100, plate.dy - 22)
          ..quadraticBezierTo(109, plate.dy - 22, 109, plate.dy - 4),
        Paint()
          ..color = _metal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_TraineePainter old) =>
      old.back != back ||
      old.squash != squash ||
      old.twist != twist ||
      old.slack != slack ||
      old.chestY != chestY ||
      old.dRingY != dRingY ||
      old.tucked != tucked ||
      old.geo.height != geo.height ||
      old.geo.feet != geo.feet;
}

// ============================================================================
// The pole top: anchor points, the climber, the lens
// ============================================================================

/// Where things are on the pole top (design px, 360 wide).
@immutable
class _TopGeo {
  const _TopGeo(this.h, {this.slingAt = 1, this.slingLeft = false});
  final double h;
  final int slingAt;
  final bool slingLeft;

  static const cx = 150.0;
  double get top => math.max(150.0, h * 0.22);
  double get arm => top + 56;
  double get wire => arm - 44;
  double get bracket => arm + 74;
  double get sling => arm + 132 + 24.0 * slingAt;
  double get horizon => h * 0.80;

  /// Which side the sling's ring hangs (+1 right, −1 left).
  double get side => slingLeft ? -1 : 1;

  /// He hugs the pole just under the sling, his back to us.
  Offset get head => Offset(cx - 20, sling + 96);
  Offset get dRing => head + const Offset(0, 40);

  /// The snap hook in his raised hand.
  Offset get hand => Offset(cx - 64, sling + 44);
  static const pinX = 66.0;
  static const farPinX = 296.0;

  /// The pole's half width at [y] (it tapers up).
  double halfAt(double y) => 13 + 6 * ((y - top) / math.max(1.0, h - top)).clamp(0.0, 1.0);

  /// His boots: the left on a step bolt, the right on the bolt above it.
  double get footL => head.dy + 168;
  double get footR => footL - 26;

  /// The step bolts below the sling: (y, on the left?).
  List<(double, bool)> get bolts => [
        for (var i = -12; i < 12; i++)
          if (footL - 26 * i > sling + 40 && footL - 26 * i < h + 10) (footL - 26 * i, i.isEven),
      ];

  /// Where the hook clips at [a].
  Offset ring(AnchorPoint a) => switch (a) {
        AnchorPoint.sling => Offset(cx + 30 * side, sling + 20),
        AnchorPoint.crackedArm => Offset(cx + 110, arm + 8),
        AnchorPoint.insulatorPin => Offset(pinX, arm - 12),
        AnchorPoint.looseBracket => Offset(cx + 46, bracket + 10),
      };

  /// The touch zone of [a].
  Rect spot(AnchorPoint a) => switch (a) {
        AnchorPoint.sling => Rect.fromCenter(center: Offset(cx + 8 * side, sling + 6), width: 104, height: 62),
        AnchorPoint.crackedArm => Rect.fromLTRB(cx + 60, arm - 30, 336, arm + 34),
        AnchorPoint.insulatorPin => Rect.fromCenter(center: Offset(pinX, arm - 22), width: 72, height: 72),
        AnchorPoint.looseBracket => Rect.fromCenter(center: Offset(cx + 42, bracket + 4), width: 78, height: 58),
      };
}

/// What a layer of the pole top draws: everything; the still part (grey under
/// a fall); or only what falls (in colour).
enum _TopPart { all, still, moving }

class _TopPainter extends CustomPainter {
  _TopPainter({required this.geo, required this.anchors, required this.clip, required this.tie, required this.fall, required this.part});
  final _TopGeo geo;
  final List<AnchorPoint> anchors;
  final AnchorPoint? clip;
  final double tie;
  final double fall;
  final _TopPart part;

  bool get _still => part != _TopPart.moving;
  bool get _moving => part != _TopPart.still;

  /// The weak point that gives way (and falls with him).
  AnchorPoint? get _breaks => part == _TopPart.all || clip == AnchorPoint.sling ? null : clip;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    const cx = _TopGeo.cx;
    final arm = geo.arm;
    final cracked = anchors.contains(AnchorPoint.crackedArm);
    final bracket = anchors.contains(AnchorPoint.looseBracket);
    if (_still) {
      // Sky, clouds, the land far below.
      final hz = geo.horizon;
      final sky = Rect.fromLTWH(0, 0, w, hz);
      c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4F8FC9), Color(0xFF94C1E4), Color(0xFFE6E3D0)],
            stops: [0, 0.66, 1],
          ).createShader(sky),
      );
      final cloud = Paint()..color = const Color(0xD9FFFFFF);
      for (final (x, y, r) in const [(54.0, 0.20, 20.0), (250.0, 0.13, 26.0), (330.0, 0.42, 16.0), (120.0, 0.55, 14.0)]) {
        final cy = hz * y + 30;
        c.drawOval(Rect.fromCenter(center: Offset(x, cy), width: r * 4.2, height: r * 1.3), cloud);
        c.drawCircle(Offset(x - r * 0.6, cy - r * 0.35), r * 0.8, cloud);
        c.drawCircle(Offset(x + r * 0.5, cy - r * 0.5), r, cloud);
      }
      // Far tree line and tiny roofs, then the fields below.
      final far = Path()..moveTo(0, hz);
      for (var x = 0.0; x <= w; x += 14) {
        final b = 8 + 5 * math.sin(x * 0.07) + 3 * math.sin(x * 0.19 + 1);
        far.quadraticBezierTo(x + 7, hz - b - 6, x + 14, hz - b * 0.5);
      }
      far
        ..lineTo(w, hz)
        ..close();
      c.drawPath(far, Paint()..color = const Color(0xFF7A9A6C));
      for (final (x, wd) in const [(30.0, 18.0), (210.0, 22.0), (300.0, 16.0)]) {
        c.drawRect(Rect.fromLTWH(x, hz - 8, wd, 8), Paint()..color = const Color(0xFFE2D6BA));
        c.drawPath(
          Path()
            ..moveTo(x - 2, hz - 7)
            ..lineTo(x + wd / 2, hz - 13)
            ..lineTo(x + wd + 2, hz - 7)
            ..close(),
          Paint()..color = const Color(0xFF8A96A0),
        );
      }
      final land = Rect.fromLTWH(0, hz, w, s.height - hz);
      c.drawRect(
        land,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9DBB6A), Color(0xFF6F9448)]).createShader(land),
      );
      // The road far below.
      c.drawPath(
        Path()
          ..moveTo(w * 0.55, hz)
          ..lineTo(w * 0.62, hz)
          ..lineTo(w, s.height * 0.98)
          ..lineTo(w * 0.78, s.height)
          ..close(),
        Paint()..color = const Color(0xFF7D7B76),
      );

      // Wires (behind the pole).
      final wire = Paint()
        ..color = const Color(0xFF262A30)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (final dx in const [0.0, 230.0]) {
        c.drawPath(
          Path()
            ..moveTo(-10, geo.wire + 10)
            ..quadraticBezierTo(dx > 0 ? 200 : 30, geo.wire - 6, dx > 0 ? w + 10 : _TopGeo.pinX, geo.wire + (dx > 0 ? 8 : 0)),
          wire,
        );
      }
      c.drawLine(Offset(_TopGeo.pinX, geo.wire), Offset(_TopGeo.farPinX, geo.wire + 2), wire);

      // The pole (tapering up), its cap.
      final pole = Path()
        ..moveTo(cx - 13, geo.top)
        ..lineTo(cx + 13, geo.top)
        ..lineTo(cx + 19, s.height + 4)
        ..lineTo(cx - 19, s.height + 4)
        ..close();
      c.drawPath(
        pole,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF9C9A93), Color(0xFFDAD7CE), Color(0xFFA5A29A)], stops: [0, 0.45, 1])
              .createShader(Rect.fromLTRB(cx - 19, geo.top, cx + 19, s.height)),
      );
      c.drawRect(Rect.fromLTRB(cx - 15, geo.top - 6, cx + 15, geo.top), Paint()..color = const Color(0xFF7E7B74));
      // Step bolts down the pole, left and right in turn.
      final bolt = Paint()
        ..color = const Color(0xFF6B6F74)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round;
      for (final (y, left) in geo.bolts) {
        final e = geo.halfAt(y) - 1;
        final sd = left ? -1.0 : 1.0;
        c.drawLine(Offset(cx + e * sd, y), Offset(cx + (e + 15) * sd, y - 2), bolt);
      }

      // The cross-arm (an MS channel), cracked and sagging on the right if dealt.
      final ch = Paint()
        ..color = const Color(0xFF5F676F)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.butt;
      c.drawLine(Offset(40, arm), Offset(cx + 14, arm), ch);
      if (!cracked || _breaks != AnchorPoint.crackedArm) _rightArm(c, cracked);
      // The clamp holding the arm to the pole.
      c.drawRect(Rect.fromLTRB(cx - 16, arm - 9, cx + 16, arm + 9), Paint()..color = const Color(0xFF4A5057));
      // Insulators on their pins.
      if (_breaks != AnchorPoint.insulatorPin) _insulator(c, Offset(_TopGeo.pinX, arm), weak: anchors.contains(AnchorPoint.insulatorPin));
      if (!cracked || _breaks != AnchorPoint.crackedArm) _insulator(c, _farPinBase(cracked), weak: false);
      // A bracket on the pole (loose when dealt).
      if (bracket && _breaks != AnchorPoint.looseBracket) _bracket(c, 0);
      // The sling round the pole body with its D-ring.
      final sy = geo.sling;
      final band = Rect.fromLTRB(cx - 20, sy - 9, cx + 20, sy + 9);
      c.drawRRect(RRect.fromRectAndRadius(band, const Radius.circular(4)), Paint()..color = const Color(0xFFE67E22));
      for (var x = cx - 14; x < cx + 14; x += 6) {
        c.drawLine(Offset(x, sy - 6), Offset(x + 3, sy + 6), Paint()
          ..color = const Color(0xFFA8540F)
          ..strokeWidth = 1.2);
      }
      final sx = geo.side;
      c.drawPath(
        Path()
          ..moveTo(cx + 18 * sx, sy - 4)
          ..quadraticBezierTo(cx + 40 * sx, sy - 2, cx + 38 * sx, sy + 16)
          ..quadraticBezierTo(cx + 34 * sx, sy + 30, cx + 22 * sx, sy + 20),
        Paint()
          ..color = const Color(0xFF8D949B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5,
      );
    }

    if (_moving) {
      final f = fall;
      // The part that gives way.
      switch (_breaks) {
        case AnchorPoint.crackedArm:
          c.save();
          final pivot = Offset(cx + 70, arm + 2);
          c.translate(0, 340 * f * f);
          c.translate(pivot.dx, pivot.dy);
          c.rotate(1.1 * f);
          c.translate(-pivot.dx, -pivot.dy);
          _rightArm(c, true);
          _insulator(c, _farPinBase(true), weak: false);
          c.restore();
        case AnchorPoint.insulatorPin:
          c.save();
          final base = Offset(_TopGeo.pinX, arm - 6);
          c.translate(0, 320 * f * f);
          c.translate(base.dx, base.dy);
          c.rotate(-1.6 * math.min(1.0, f * 2));
          c.translate(-base.dx, -base.dy);
          _insulator(c, Offset(_TopGeo.pinX, arm), weak: true);
          c.restore();
        case AnchorPoint.looseBracket:
          _bracket(c, f);
        default:
          break;
      }
      // The climber, the lanyard and its hook.
      final drop = part == _TopPart.moving ? 300 * f * f : 0.0;
      final hook = _hookAt(f);
      c.save();
      c.translate(0, drop);
      _climber(c, s, hook - Offset(0, drop), reachUp: part == _TopPart.moving ? f < 0.15 : (clip == null || tie < 0.6), falling: part == _TopPart.moving);
      c.restore();
    }
  }

  /// Where the hook is now.
  Offset _hookAt(double f) {
    final a = clip;
    if (a == null) {
      // In his hand (falling with him).
      return geo.hand + Offset(0, part == _TopPart.moving ? 300 * f * f : 0);
    }
    final to = geo.ring(a);
    if (part != _TopPart.moving) return Offset.lerp(geo.hand, to, tie)!;
    // Clipped to a weak point: it goes with the falling part.
    return switch (a) {
      AnchorPoint.sling => to,
      AnchorPoint.crackedArm => to + Offset(-20 * f, 340 * f * f + 40 * f),
      AnchorPoint.insulatorPin => to + Offset(20 * f, 320 * f * f),
      AnchorPoint.looseBracket => to + Offset(30 * f, 300 * f * f),
    };
  }

  Offset _farPinBase(bool cracked) => Offset(_TopGeo.farPinX, geo.arm + (cracked ? 22 : 0));

  void _rightArm(Canvas c, bool cracked) {
    const cx = _TopGeo.cx;
    final arm = geo.arm;
    final ch = Paint()
      ..color = const Color(0xFF5F676F)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;
    if (!cracked) {
      c.drawLine(Offset(cx + 14, arm), Offset(320, arm), ch);
      return;
    }
    c.drawLine(Offset(cx + 14, arm), Offset(cx + 70, arm + 2), ch);
    c.drawLine(Offset(cx + 72, arm + 3), Offset(320, arm + 26), ch);
    // The crack: a jagged split with rust.
    c.drawPath(
      Path()
        ..moveTo(cx + 66, arm - 7)
        ..lineTo(cx + 72, arm - 1)
        ..lineTo(cx + 67, arm + 3)
        ..lineTo(cx + 74, arm + 9),
      Paint()
        ..color = const Color(0xFF1E2024)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    c.drawCircle(Offset(cx + 76, arm + 6), 5, Paint()..color = const Color(0x998A4A1E));
  }

  void _insulator(Canvas c, Offset base, {required bool weak}) {
    // The pin: thin and leaning when weak.
    final lean = weak ? 4.0 : 0.0;
    c.drawLine(base + const Offset(0, -6), base + Offset(lean, -18), Paint()
      ..color = weak ? const Color(0xFF8A5A3A) : const Color(0xFF8D949B)
      ..strokeWidth = weak ? 2.6 : 4);
    final top = base + Offset(lean, -18);
    final porcelain = Paint()..color = const Color(0xFFEDEAE2);
    final edge = Paint()
      ..color = const Color(0xFFB4AFA4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 3; i++) {
      final r = Rect.fromCenter(center: top + Offset(lean * 0.3, -4.0 - i * 7), width: 24.0 - i * 4, height: 7);
      c.drawOval(r, porcelain);
      c.drawOval(r, edge);
    }
    c.drawRect(Rect.fromCenter(center: top + Offset(lean * 0.3, -24), width: 10, height: 6), porcelain);
  }

  /// The loose bracket on the pole's right; [f] swings it away.
  void _bracket(Canvas c, double f) {
    const cx = _TopGeo.cx;
    final y = geo.bracket;
    c.save();
    final pivot = Offset(cx + 18, y - 10);
    c.translate(0, 300 * f * f);
    c.translate(pivot.dx, pivot.dy);
    c.rotate(0.18 + 1.2 * f);
    c.translate(-pivot.dx, -pivot.dy);
    final steel = Paint()..color = const Color(0xFF6B747C);
    c.drawRect(Rect.fromLTRB(cx + 20, y - 12, cx + 26, y + 16), steel);
    c.drawRect(Rect.fromLTRB(cx + 20, y + 8, cx + 58, y + 14), steel);
    c.drawCircle(Offset(cx + 23, y - 6), 2.4, Paint()..color = const Color(0xFF2B2F35));
    c.restore();
  }

  void _climber(Canvas c, Size s, Offset hook, {required bool reachUp, required bool falling}) {
    const cx = _TopGeo.cx;
    final head = geo.head;
    const shirt = Color(0xFF1F5F8F);
    const shirtDark = Color(0xFF184A70);
    const pants = Color(0xFF26303D);
    const glove = Color(0xFF8B5A2B);
    void limb(Offset a, Offset b, double w, Color col) => c.drawLine(
          a,
          b,
          Paint()
            ..color = col
            ..strokeWidth = w
            ..strokeCap = StrokeCap.round,
        );
    void boot(Offset at, bool left) => c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: at + Offset(left ? -2 : 2, -5), width: 24, height: 12), const Radius.circular(5)),
          Paint()..color = const Color(0xFF2A1F17),
        );
    // Legs straddle the pole, the boots on two step bolts (kicked loose in a fall).
    final hipL = head + const Offset(-12, 104);
    final hipR = head + const Offset(12, 104);
    final bootL = falling ? hipL + const Offset(-30, 56) : Offset(cx - geo.halfAt(geo.footL) - 9, geo.footL);
    final bootR = falling ? hipR + const Offset(26, 60) : Offset(cx + geo.halfAt(geo.footR) + 9, geo.footR);
    final kneeL = falling ? hipL + const Offset(-22, 30) : Offset(cx - 52, head.dy + 136);
    final kneeR = falling ? hipR + const Offset(20, 30) : Offset(cx + 26, head.dy + 126);
    limb(hipL, kneeL, 21, pants);
    limb(kneeL, bootL, 19, pants);
    limb(hipR, kneeR, 21, pants);
    limb(kneeR, bootR, 19, pants);
    boot(bootL, true);
    boot(bootR, false);
    // The body from behind, over the pole.
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: head + const Offset(0, 62), width: 58, height: 96), const Radius.circular(20));
    c.drawRRect(body, Paint()..color = shirt);
    // The right arm hugs the pole round its right edge.
    final gripR = falling ? head + const Offset(50, 30) : Offset(cx + geo.halfAt(head.dy) + 2, head.dy + 16);
    limb(head + const Offset(24, 28), gripR, 14, shirtDark);
    c.drawCircle(gripR, 7, Paint()..color = glove);
    // The left holds the hook up; once clipped, it grips the pole above his
    // helmet; falling, it is flung out.
    final reach = reachUp
        ? geo.hand + const Offset(4, 10)
        : (falling ? head + const Offset(-54, 34) : Offset(cx - geo.halfAt(head.dy - 32) - 1, head.dy - 32));
    limb(head + const Offset(-24, 28), reach, 14, shirtDark);
    c.drawCircle(reach, 7, Paint()..color = glove);
    // Harness on his back: straps to the D-ring between the shoulders.
    final web = Paint()
      ..color = const Color(0xFFF06A1D)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final d = geo.dRing;
    c.drawLine(head + const Offset(-17, 18), d, web);
    c.drawLine(head + const Offset(17, 18), d, web);
    c.drawLine(d, head + const Offset(-15, 106), web);
    c.drawLine(d, head + const Offset(15, 106), web);
    c.drawLine(head + const Offset(-26, 100), head + const Offset(26, 100), web);
    c.drawCircle(d, 5, Paint()..color = const Color(0xFF8D949B));
    // Helmet from behind.
    c.drawCircle(head, 17, Paint()..color = const Color(0xFF2B211A));
    c.drawArc(Rect.fromCenter(center: head + const Offset(0, -2), width: 42, height: 40), math.pi, math.pi, true, Paint()..color = const Color(0xFFFFD34E));
    // The lanyard from the D-ring to the hook.
    c.drawPath(
      Path()
        ..moveTo(d.dx, d.dy)
        ..quadraticBezierTo(d.dx - 30, (d.dy + hook.dy) / 2 + 20, hook.dx, hook.dy),
      Paint()
        ..color = const Color(0xFF3B6EA8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );
    // The snap hook.
    c.drawPath(
      Path()
        ..moveTo(hook.dx - 4, hook.dy + 6)
        ..quadraticBezierTo(hook.dx - 9, hook.dy - 10, hook.dx, hook.dy - 11)
        ..quadraticBezierTo(hook.dx + 9, hook.dy - 10, hook.dx + 5, hook.dy + 4),
      Paint()
        ..color = const Color(0xFF6E767E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6,
    );
  }

  @override
  bool shouldRepaint(_TopPainter old) =>
      old.tie != tie ||
      old.fall != fall ||
      old.clip != clip ||
      old.part != part ||
      old.anchors != anchors ||
      old.geo.h != geo.h ||
      old.geo.slingAt != geo.slingAt ||
      old.geo.slingLeft != geo.slingLeft;
}

/// A close look at one anchor point: a big lens over the dimmed scene, with
/// "এখানে লাগাই" and "বন্ধ".
class _Lens extends StatelessWidget {
  const _Lens({super.key, required this.point, required this.quiet, required this.onClip, required this.onClose});
  final AnchorPoint point;
  final bool quiet;
  final ValueChanged<Offset> onClip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final d = math.min(300.0, size.width - 72);
    final cy = size.height * 0.40;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xC4050A16),
          child: Stack(
            children: [
              Positioned(
                left: (size.width - d) / 2,
                top: cy - d / 2,
                width: d,
                height: d,
                child: Semantics(
                  label: FitLines.lensLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      builder: (_, t, child) => Transform.scale(scale: 0.7 + 0.3 * t, child: child),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: SlmColors.gold300, width: 6),
                          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 20)],
                        ),
                        child: ClipOval(child: CustomPaint(painter: _CloseUpPainter(point), size: Size.infinite)),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: cy + d / 2 + 22,
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: FitLines.lensClose,
                        excludeSemantics: true,
                        child: DoBigButton(label: FitLines.lensClose, filled: false, onDark: true, onTapUp: (_) => onClose()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DoBigButton(label: FitLines.clipHere, filled: true, onTapUp: (dt) => onClip(dt.globalPosition)),
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

/// The anchor point seen close (a 200 × 200 drawing): the sling's webbing
/// round the solid pole; the cross-arm's split; the thin bent pin under the
/// insulator; the bracket standing off the pole with a nut half off.
class _CloseUpPainter extends CustomPainter {
  _CloseUpPainter(this.point);
  final AnchorPoint point;

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 200, s.height / 200);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 200, 200),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DBBE0), Color(0xFFD8E6EE)]).createShader(const Rect.fromLTWH(0, 0, 200, 200)),
    );
    final concrete = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF9C9A93), Color(0xFFDAD7CE), Color(0xFFA5A29A)], stops: [0, 0.45, 1]).createShader(const Rect.fromLTWH(0, 0, 200, 200));
    final speck = Paint()..color = const Color(0x557A776F);
    switch (point) {
      case AnchorPoint.sling:
        c.drawRect(const Rect.fromLTRB(58, 0, 142, 200), Paint()..shader = const LinearGradient(colors: [Color(0xFF9C9A93), Color(0xFFDAD7CE), Color(0xFFA5A29A)], stops: [0, 0.45, 1]).createShader(const Rect.fromLTRB(58, 0, 142, 200)));
        for (final (x, y) in const [(70.0, 20.0), (120.0, 44.0), (90.0, 150.0), (128.0, 176.0), (76.0, 120.0)]) {
          c.drawCircle(Offset(x, y), 1.6, speck);
        }
        // The webbing wraps the pole: a band with stitched bar-tacks.
        final band = Path()
          ..moveTo(54, 78)
          ..quadraticBezierTo(100, 86, 146, 78)
          ..lineTo(146, 112)
          ..quadraticBezierTo(100, 120, 54, 112)
          ..close();
        c.drawPath(band, Paint()..color = const Color(0xFFE67E22));
        c.drawPath(band, Paint()
          ..color = const Color(0xFFA8540F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
        final stitch = Paint()
          ..color = const Color(0xFF6B3108)
          ..strokeWidth = 1.4;
        for (var x = 64.0; x < 140; x += 7) {
          c.drawLine(Offset(x, 88), Offset(x + 4, 104), stitch);
        }
        // The loop and the big steel D-ring.
        c.drawPath(
          Path()
            ..moveTo(146, 84)
            ..quadraticBezierTo(170, 90, 168, 118),
          Paint()
            ..color = const Color(0xFFE67E22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12,
        );
        c.drawPath(
          Path()
            ..moveTo(150, 116)
            ..lineTo(186, 116)
            ..quadraticBezierTo(190, 160, 168, 164)
            ..quadraticBezierTo(146, 160, 150, 116),
          Paint()
            ..color = const Color(0xFF8D949B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7,
        );
      case AnchorPoint.crackedArm:
        // The channel, split open and bent down past the crack.
        final ch = Paint()..color = const Color(0xFF5F676F);
        final lip = Paint()..color = const Color(0xFF7D868E);
        c.drawRect(const Rect.fromLTRB(0, 84, 96, 120), ch);
        c.drawRect(const Rect.fromLTRB(0, 84, 96, 90), lip);
        c.save();
        c.translate(104, 92);
        c.rotate(0.28);
        c.drawRect(const Rect.fromLTRB(0, -8, 120, 28), ch);
        c.drawRect(const Rect.fromLTRB(0, -8, 120, -2), lip);
        c.restore();
        c.drawPath(
          Path()
            ..moveTo(92, 80)
            ..lineTo(104, 92)
            ..lineTo(94, 102)
            ..lineTo(108, 112)
            ..lineTo(98, 124),
          Paint()
            ..color = const Color(0xFF15171A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        c.drawCircle(const Offset(110, 108), 12, Paint()..color = const Color(0x888A4A1E));
        c.drawCircle(const Offset(84, 116), 8, Paint()..color = const Color(0x668A4A1E));
        // Chips falling from the split.
        for (final (x, y) in const [(104.0, 140.0), (112.0, 158.0), (98.0, 176.0)]) {
          c.drawRect(Rect.fromCenter(center: Offset(x, y), width: 5, height: 4), ch);
        }
      case AnchorPoint.insulatorPin:
        // The arm below, the thin rusty pin bent over, the insulator leaning.
        c.drawRect(const Rect.fromLTRB(0, 150, 200, 176), Paint()..color = const Color(0xFF5F676F));
        c.drawPath(
          Path()
            ..moveTo(98, 152)
            ..quadraticBezierTo(98, 120, 114, 100),
          Paint()
            ..color = const Color(0xFF8A5A3A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7,
        );
        c.drawCircle(const Offset(102, 132), 5, Paint()..color = const Color(0xAA6B3A1E));
        c.save();
        c.translate(118, 96);
        c.rotate(0.42);
        final porcelain = Paint()..color = const Color(0xFFEDEAE2);
        final edge = Paint()
          ..color = const Color(0xFFB4AFA4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (var i = 0; i < 3; i++) {
          final r = Rect.fromCenter(center: Offset(0, -6.0 - i * 18), width: 70.0 - i * 12, height: 20);
          c.drawOval(r, porcelain);
          c.drawOval(r, edge);
        }
        c.drawRect(Rect.fromCenter(center: const Offset(0, -62), width: 26, height: 16), porcelain);
        c.restore();
      case AnchorPoint.looseBracket:
        // The pole on the left; the bracket stands off it with a gap, one
        // bolt gone and a nut half off its thread.
        c.drawRect(const Rect.fromLTRB(0, 0, 80, 200), concrete);
        for (final (x, y) in const [(20.0, 30.0), (60.0, 90.0), (34.0, 160.0)]) {
          c.drawCircle(Offset(x, y), 1.8, speck);
        }
        c.save();
        c.translate(92, 50);
        c.rotate(0.14);
        final steel = Paint()..color = const Color(0xFF6B747C);
        c.drawRect(const Rect.fromLTRB(0, 0, 14, 110), steel);
        c.drawRect(const Rect.fromLTRB(0, 82, 100, 96), steel);
        // The empty bolt hole and the loose bolt.
        c.drawCircle(const Offset(7, 18), 5, Paint()..color = const Color(0xFF1E2024));
        c.drawLine(const Offset(-14, 66), const Offset(22, 66), Paint()
          ..color = const Color(0xFFB0B5BA)
          ..strokeWidth = 5);
        for (var x = 10.0; x < 22; x += 3) {
          c.drawLine(Offset(x, 63), Offset(x + 1.5, 69), Paint()
            ..color = const Color(0xFF7A7F84)
            ..strokeWidth = 1);
        }
        c.drawRect(const Rect.fromLTRB(22, 58, 32, 74), Paint()..color = const Color(0xFF9AA3AB));
        c.restore();
        // The dark gap between pole and bracket.
        c.drawPath(
          Path()
            ..moveTo(80, 48)
            ..lineTo(92, 50)
            ..lineTo(78, 160)
            ..lineTo(80, 160)
            ..close(),
          Paint()..color = const Color(0xAA15171A),
        );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_CloseUpPainter old) => old.point != point;
}
